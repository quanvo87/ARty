import ARKit
import CoreLocation
import FirebaseAuth

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var label: UILabel!

    private var isLoaded = false

    private let authListener = AuthListener()

    private let locationManager = CLLocationManager()

    private var startDate = Date()

    private var lastLocation = CLLocation()

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
        authListener.listen { [weak self] user in
            if let user = user {
                self?.load()
                self?.uid = user.uid
                self?.loadRecentModel(for: user.uid)
                // query nearby users
            } else {
                self?.showLoginViewController()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // only need to do this when app minimized (not every time user is on another screen within app)
        // also add button to manually do this
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

extension MainViewController: EditARtyViewControllerDelegate {
    func didChangeARty(to arty: String) {
        guard let uid = uid else {
            return
        }
        if arty != self.arty?.model {
            let arty = try! ARty(uid: uid, model: arty)
            addARtyToScene(arty)
            setAnimationsFromBackend(for: arty)
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

    func load() {
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

    func loadRecentModel(for uid: String) {
        Database.user(uid) { [weak self] result in
            switch result {
            case .success(let user):
                if user.model != "" {
                    let arty = try! ARty(
                        uid: user.uid,
                        model: user.model,
                        passiveAnimation: user.passiveAnimation,
                        pokeAnimation: user.pokeAnimation
                    )
                    self?.addARtyToScene(arty)
                } else {
                    self?.showEditARtyViewController()
                }
            case .fail(let error):
                print(error)
            }
        }
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

    func addARtyToScene(_ arty: ARty) {
        arty.position = SCNVector3(0, arty.positionAdjustment, arty.positionAdjustment) // extract
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
        arty.label = label
    }

    func setAnimationsFromBackend(for arty: ARty) {
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
