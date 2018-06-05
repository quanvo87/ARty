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
    private lazy var nearbyUsersPoller = NearbyUsersPoller(delegate: self)

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
        updatePokeTimestamp(uid)
    }

    private func updatePokeTimestamp(_ uid: String) {
        if uid == self.uid {
            Database.updatePokeTimestamp(for: uid) { _ in }
        }
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
            nearbyUsersPoller.coordinates = (newLocation.coordinate.latitude, newLocation.coordinate.longitude)
        }
        lastLocation = newLocation
    }
}

extension MainViewController: AuthManagerDelegate {
    func userLoggedIn(_ uid: String) {
        load()
        self.uid = uid
        loadRecentModel(for: uid)
        nearbyUsersPoller.poll()
    }

    func userLoggedOut() {
        nearbyUsersPoller.stop()
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
        // todo: move to account creation
        Database.updateUid(uid) { [weak self] error in
            if let error = error {
                print(error)
                return
            }
            Database.user(uid) { result in
                switch result {
                case .success(let user):
                    if user.model != "" {
                        do {
                            let arty = try ARty(user: user, delegate: nil)
                            self?.addARtyToScene(arty, position: .init())
                        } catch {
                            print(error)
                        }
                    } else {
                        self?.showEditARtyViewController()
                    }
                case .fail(let error):
                    print(error)
                }
            }
        }
    }
}

extension MainViewController: NearbyUsersPollerDelegate {
    func observeUser(_ user: User) {
        if user.uid != uid && !arties.keys.contains(user.uid) {
            do {
                let arty = try ARty(user: user, delegate: self)
                addARtyToScene(arty, position: .random)
            } catch {
                print(error)
            }
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

extension MainViewController: ARtyDelegate {
    func updateUser(_ user: User) {
        guard let arty = arties[user.uid] else {
            return
        }
        if user.model != arty.model {
            do {
                let arty = try ARty(user: user, delegate: self)
                addARtyToScene(arty, position: .random)
            } catch {
                print(error)
            }
        } else {
            try? arty.setPassiveAnimation(user.passiveAnimation)
            try? arty.setPokeAnimation(user.pokeAnimation)
            checkPokeTimestamp(arty: arty, user: user)
            // check new location
        }
    }

    // todo: test
    private func checkPokeTimestamp(arty: ARty, user: User) {
        if arty.pokeTimestamp != user.pokeTimestamp {
            try? arty.playPokeAnimation()
        }
        arty.pokeTimestamp = user.pokeTimestamp
    }
}

extension MainViewController: EditARtyViewControllerDelegate {
    func didChangeARty(to model: String) {
        guard let uid = uid else {
            return
        }
        if model != self.arty?.model {
            do {
                let arty = try ARty(uid: uid, model: model, delegate: nil)
                addARtyToScene(arty, position: .init())
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
            Database.updateARty(arty) { _ in }
        }
    }
}

extension MainViewController: EditAnimationsViewControllerDelegate {
    func setPassiveAnimation(to animation: String, for arty: ARty) {
        try? arty.setPassiveAnimation(animation)
        Database.updatePassiveAnimation(to: animation, for: arty) { _ in }
    }

    func setPokeAnimation(to animation: String, for arty: ARty) {
        try? arty.setPokeAnimation(animation)
        Database.updatePokeAnimation(to: animation, for: arty) { _ in }
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

    func addARtyToScene(_ arty: ARty, position: SCNVector3) {
        arty.position = arty.positionAdjustment + position
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
    }
}
