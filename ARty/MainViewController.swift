import ARKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private let locationManager = CLLocationManager()
    private var isLoaded = false
    private var startDate = Date()
    private var lastLocation = CLLocation()
    private var uid: String?
    private var arties = [String: ARty]()
    private lazy var authManager = AuthManager(delegate: self)
    private lazy var nearbyUsersManager = NearbyUsersManager(delegate: self)

    private var arty: ARty? {
        guard let uid = uid else {
            return nil
        }
        return arties[uid]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        authManager.listenForAuthState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // only need to do this when app minimized (not every time user is on another screen within app)
        // but also add button to manually do this
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: sceneView) else {
            return
        }
        let hitTest = sceneView.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: true])
        guard let uid = (hitTest.first?.node.parent as? ARty)?.uid,
            let arty = arties[uid] else {
                return
        }
        try? arty.playPokeAnimation()
    }
}

extension MainViewController: ARSCNViewDelegate {
}

extension MainViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arty = arty,
            let currentPosition = sceneView.pointOfView?.position else {
                return
        }
        arty.position = currentPosition + arty.positionAdjustment
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdatingLocation() // if they only authorized when in use, ask again one more time
        } else {
            // show alert
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        if newLocation.isValid(oldLocation: lastLocation, startDate: startDate) {
            try? arty?.playWalkAnimation(location: newLocation)
            arty?.turn(location: newLocation)
        }
        lastLocation = newLocation
    }
}

extension MainViewController: AuthManagerDelegate {
    func userLoggedIn(_ uid: String) {
        load()
        self.uid = uid
        loadRecentModel(for: uid)
        nearbyUsersManager.startPollingNearbyUsers(uid: uid)
    }

    func userLoggedOut() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: String(describing: LoginViewController.self))
        let navigationController = UINavigationController(rootViewController: loginViewController)
        present(navigationController, animated: true)
    }

    private func load() {
        guard !isLoaded else {
            return
        }
        UIApplication.shared.isIdleTimerDisabled = true
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        startUpdatingLocation()
        isLoaded = true
    }

    private func loadRecentModel(for uid: String) {
        Database.user(uid) { [weak self] result in
            switch result {
            case .success(let user):
                if user.model != "" {
                    self?.addARtyToScene(user: user)
                } else {
                    self?.showEditARtyViewController()
                }
            case .fail(let error):
                print(error)
            }
        }
    }
}

extension MainViewController: NearbyUsersManagerDelegate {
    func processUser(_ user: User) {
        if !arties.keys.contains(user.uid) {
            observeUser(user)
        } else {
            updateUser(user)
        }
    }

    private func observeUser(_ user: User) {
        addARtyToScene(user: user, position: .random)
    }

    // don't need to update, this will be handled when we observe user
    private func updateUser(_ user: User) {
        guard let arty = arties[user.uid] else {
            return
        }
        if user.model != arty.model {
            addARtyToScene(user: user, position: .random)
        } else {
            try? arty.setPassiveAnimation(user.passiveAnimation)
            try? arty.setPokeAnimation(user.pokeAnimation)
            // check poke animation timestamp
            // check new location
        }
    }

    func removeStaleUsers(_ users: [User]) {
        users
            .filter {
                return !arties.keys.contains($0.uid)
            }
            .forEach {
                sceneView.scene.rootNode.childNode(withName: $0.uid, recursively: false)?.removeFromParentNode()
                arties.removeValue(forKey: $0.uid)
        }
    }
}

extension MainViewController: EditARtyViewControllerDelegate {
    func didChangeARty(to arty: String) {
        guard let uid = uid else {
            return
        }
        if arty != self.arty?.model {
            do {
                let arty = try ARty(uid: uid, model: arty)
                addARtyToScene(arty)
                setAnimationsFromBackend(for: arty)
            } catch {
                print(error)
            }
        }
    }

    private func setAnimationsFromBackend(for arty: ARty) {
        Database.user(arty.uid) { result in
            switch result {
            case .success(let user):
                if let passiveAnimation = user.recentPassiveAnimations[arty.model] {
                    try? arty.setPassiveAnimation(passiveAnimation)
                }
                if let pokeAnimation = user.recentPokeAnimations[arty.model] {
                    try? arty.setPokeAnimation(pokeAnimation)
                }
            case .fail(let error):
                print(error)
            }
            Database.setARty(arty) { _ in }
        }
    }
}

extension MainViewController: EditAnimationsViewControllerDelegate {
    func setPassiveAnimation(to animation: String, for arty: ARty) {
        try? arty.setPassiveAnimation(animation)
        Database.setPassiveAnimation(to: animation, for: arty) { _ in }
    }

    func setPokeAnimation(to animation: String, for arty: ARty) {
        try? arty.setPokeAnimation(animation)
        Database.setPokeAnimation(to: animation, for: arty) { _ in }
    }
}

private extension MainViewController {
    @IBAction func didTapHoldPositionButton(_ sender: Any) {
    }

    @IBAction func didTapEditAnimationsButton(_ sender: Any) {
        guard let arty = arty else {
            return
        }
        let viewController = EditAnimationsViewController.make(arty: arty, delegate: self)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    @IBAction func didTapEditARtyButton(_ sender: Any) {
        showEditARtyViewController()
    }

    @IBAction func didTapLogOutButton(_ sender: Any) {
        authManager.logout()
    }

    func showEditARtyViewController() {
        let viewController = EditARtyViewController(delegate: self)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        startDate = Date()
    }

    func addARtyToScene(_ arty: ARty, position: SCNVector3 = .init(0, 0, 0)) {
        arty.position = arty.positionAdjustment + position
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
    }

    func addARtyToScene(user: User, position: SCNVector3 = .init(0, 0, 0)) {
        do {
            let arty = try ARty(
                uid: user.uid,
                model: user.model,
                passiveAnimation: user.passiveAnimation,
                pokeAnimation: user.pokeAnimation
            )
            addARtyToScene(arty, position: position)
        } catch {
            print(error)
        }
    }
}
