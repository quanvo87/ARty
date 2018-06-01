import ARKit
import CoreLocation
import FirebaseAuth

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var label: UILabel!

    private let authListener = AuthListener()

    private let defaults = UserDefaults.standard

    private let locationManager = CLLocationManager()

    private var lastLocation = CLLocation()

    private var startDate = Date()

    private var uid: String?

    private var arties = [String: ARty]()

    private var arty: ARty? {
        guard let uid = uid else {
            return nil
        }
        return arties[uid]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true

        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        startUpdatingLocation()

        authListener.listen { [weak self] user in
            if let user = user {
                let uid = user.uid
                self?.uid = uid
                self?.loadUserDefaults(uid: uid)
                self?.nearbyUsers(uid: uid)
            } else {
                self?.showLoginViewController()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // maybe only need to do this when app minimized (not every time user is on another screen within app)
        // add button to manually do this, in case things go weird, which they often do in AR
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
        try? arty.playAnimation(arty.pokeAnimation)
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
        let adjustment = SCNVector3(0, arty.positionAdjustment, arty.positionAdjustment)
        let newVector = currentPosition + adjustment
        arty.position = newVector
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdatingLocation()
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

extension MainViewController: EditARtyViewControllerDelegate {
    func didChangeARty(to arty: String) {
        guard let uid = uid else {
            return
        }
        if arty != self.arty?.model {
            let arty = try! ARty(uid: uid, model: arty)
            addARtyToScene(arty)
            setRecentAnimations(arty: arty)
        }
    }
}

private extension MainViewController {
    @IBAction func didTapHoldPositionButton(_ sender: Any) {
    }

    @IBAction func didTapEditAnimationsButton(_ sender: Any) {
    }

    @IBAction func didTapEditARtyButton(_ sender: Any) {
        showEditARtyViewController()
    }

    @IBAction func didTapLogOutButton(_ sender: Any) {
        try? Auth.auth().signOut()
    }

    func loadUserDefaults(uid: String) {
        if let savedARty = defaults.object(forKey: "arty") as? [String: String],
            let model = savedARty["model"],
            let passiveAnimation = savedARty["passiveAnimation"],
            let pokeAnimation = savedARty["pokeAnimation"] {
            let arty = try! ARty(
                uid: uid,
                model: model,
                passiveAnimation: passiveAnimation,
                pokeAnimation: pokeAnimation
            )
            addARtyToScene(arty)
        } else {
            showEditARtyViewController()
        }
    }

    func addARtyToScene(_ arty: ARty) {
        arty.position = SCNVector3(0, arty.positionAdjustment, arty.positionAdjustment) // extract
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
        arty.label = label
    }
    
    func showLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: String(describing: LoginViewController.self))
        let navigationController = UINavigationController(rootViewController: loginViewController)
        present(navigationController, animated: true)
    }

    func showEditARtyViewController() {
        let controller = EditARtyViewController(delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        startDate = Date()
    }

    func nearbyUsers(uid: String) {
        MainViewController.mockNetworkNearbyUsers(uid: uid) { [weak self] users in
            self?.processNearbyUsers(users)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // check if app in foreground
                self?.nearbyUsers(uid: uid)
            }
        }
    }

    static func mockNetworkNearbyUsers(uid: String, completion: ([User]) -> Void) {
        // get json from backend
        // convert to array of users
    }

    func processNearbyUsers(_ users: [User]) {
        users.forEach {
            if arties[$0.uid] != nil {
                updateARty(for: $0)
            } else {
                let arty = try! ARty(
                    uid: $0.uid,
                    model: $0.model,
                    passiveAnimation: $0.passiveAnimation,
                    pokeAnimation: $0.pokeAnimation
                )
                addARtyToScene(arty)
            }
        }
        removeStaleUsers(users)
    }

    func updateARty(for user: User) {
        // if model != arty.model,
        // make new arty
        // add to scene
        // else update mutable properties
        // animate movement to x, z
    }

    func removeStaleUsers(_ users: [User]) {
        let uids = users.map { return $0.uid }
        arties.keys
            .filter { return !uids.contains($0) }
            .forEach {
                sceneView.scene.rootNode.childNode(withName: $0, recursively: false)?.removeFromParentNode()
                self.arties.removeValue(forKey: $0)
        }
    }

    func setRecentAnimations(arty: ARty) {
        Database.user(arty.uid) { [weak self] result in
            switch result {
            case .success(let user):
                if let passiveAnimation = user.recentPassiveAnimations[arty.model] {
                    self?.setPassiveAnimation(passiveAnimation)
                    try? arty.setPassiveAnimation(passiveAnimation)
                }
                if let pokeAnimation = user.recentPokeAnimations[arty.model] {
                    self?.setPokeAnimation(pokeAnimation)
                    try? arty.setPokeAnimation(pokeAnimation)
                }
            case .fail(let error):
                print(error)
            }
            self?.defaults.set(arty.dictionary, forKey: "arty")
            Database.setARty(arty) { _ in }
        }
    }

    func setPassiveAnimation(_ passiveAnimation: String) {
        guard let uid = uid else {
            return
        }
        try? arty?.setPassiveAnimation(passiveAnimation)
        Database.setPassiveAnimation(passiveAnimation, for: uid) { _ in }
    }

    func setPokeAnimation(_ pokeAnimation: String) {
        guard let uid = uid else {
            return
        }
        try? arty?.setPokeAnimation(pokeAnimation)
        Database.setPokeAnimation(pokeAnimation, for: uid) { _ in }
    }
}
