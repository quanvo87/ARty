import ARKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private var uid: String?
    private var arties = [String: ARty]()
    private lazy var authManager = AuthManager(delegate: self)
    private lazy var locationManager = LocationManager(delegate: self)
    private lazy var arSessionManager = ARSessionManager(session: sceneView.session)

    private var arty: ARty? {
        guard let uid = uid else {
            return nil
        }
        return arties[uid]
    }

    private var scene: SCNScene {
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = true
        return scene
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.scene = scene
        sceneView.session.run(ARWorldTrackingConfiguration())
        authManager.listenForAuthState()
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
        // todo: turn to face user, turn to original spot after poke animation
        try? arty.playAnimation(arty.pokeAnimation)
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
            // todo: if they only authorized when in use, ask again one more time
            locationManager.startUpdatingLocation()
        } else {
            // todo: show alert
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let uid = uid, let newLocation = manager.location else {
            return
        }
        if locationManager.isValidLocation(newLocation) {
            try? arty?.walk(to: newLocation)

            arSessionManager.setWorldOrigin(newLocation)

            let coordinate = newLocation.coordinate

            Database.setLocation(
                uid: uid,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ) { _ in }

            nearbyUsers(
                uid: uid,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    }
}

extension MainViewController: AuthManagerDelegate {
    func authManager(_ manager: AuthManager, userLoggedIn uid: String) {
        self.uid = uid
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        arSessionManager.start()
        loadUser(uid)
    }

    func authManagerUserLoggedOut(_ manager: AuthManager) {
        uid = nil
        arties.removeAll()
        locationManager.stopUpdatingLocation()
        sceneView.scene = scene
        arSessionManager.stop()
        showLoginViewController()
    }

    private func loadUser(_ uid: String) {
        Database.setUid(uid) { [weak self] error in
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
                        self?.showChooseARtyViewController()
                    }
                case .fail(let error):
                    print(error)
                }
            }
        }
    }

    private func showLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(
            withIdentifier: String(describing: LoginViewController.self)
        )
        let navigationController = UINavigationController(rootViewController: loginViewController)
        present(navigationController, animated: true)
    }
}

extension MainViewController: ARtyDelegate {
    func arty(_ arty: ARty, userChangedModel user: User) {
        do {
            let arty = try ARty(user: user, delegate: self)
            addARtyToScene(arty, position: .random)
        } catch {
            print(error)
        }
    }

    func arty(_ arty: ARty, latitude: Double, longitude: Double) {
//        let location = CLLocation(latitude: latitude, longitude: longitude)
//        guard let position = arSessionManager.positionFromWorldOrigin(to: location) else {
//            return
//        }
//        try? arty.walk(to: position)
    }
}

extension MainViewController: ChooseARtyViewControllerDelegate {
    func chooseARtyViewController(_ controller: ChooseARtyViewController, didChooseARty model: String) {
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

// todo: rethink this
extension MainViewController: ChooseAnimationsViewControllerDelegate {
    func chooseAnimationsViewController(_ controller: ChooseAnimationsViewController,
                                        didChoosePassiveAnimation animation: String,
                                        for arty: ARty) {
        try? arty.setPassiveAnimation(animation)
        Database.updatePassiveAnimation(to: animation, for: arty) { _ in }
    }

    func chooseAnimationsViewController(_ controller: ChooseAnimationsViewController,
                                        didChoosePokeAnimation animation: String,
                                        for arty: ARty) {
        try? arty.setPokeAnimation(animation)
        Database.updatePokeAnimation(to: animation, for: arty) { _ in }
    }
}

private extension MainViewController {
    @IBAction func didTapHoldPositionButton(_ sender: Any) {
    }

    @IBAction func didTapChooseAnimationsButton(_ sender: Any) {
        guard let arty = arty else {
            return
        }
        let controller = ChooseAnimationsViewController.make(arty: arty, delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    @IBAction func didTapChooseARtyButton(_ sender: Any) {
        showChooseARtyViewController()
    }

    @IBAction func didTapReloadButton(_ sender: Any) {
        arSessionManager.restartARSession()
    }

    @IBAction func didTapLogOutButton(_ sender: Any) {
        authManager.logout()
    }

    func showChooseARtyViewController() {
        let controller = ChooseARtyViewController(delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    func addARtyToScene(_ arty: ARty, position: SCNVector3) {
        arty.position = arty.positionAdjustment + position  // todo: use anchors?
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
    }

    func nearbyUsers(uid: String, latitude: Double, longitude: Double) {
        Database.nearbyUsers(uid: uid, latitude: latitude, longitude: longitude) { [weak self] result in
            switch result {
            case .fail(let error):
                print(error)
            case .success(let uids):
                uids.forEach {
                    self?.observeUser($0)
                }
                self?.removeStaleUsers(uids)
            }
        }
    }

    func observeUser(_ uid: String) {
        if uid != self.uid && !arties.keys.contains(uid) {
            ARty.make(uid: uid, delegate: self) { [weak self] result in
                switch result {
                case .fail(let error):
                    print(error)
                case .success(let arty):
                    self?.addARtyToScene(arty, position: .random)
                }
            }
        }
    }

    func removeStaleUsers(_ uids: [String]) {
        uids
            .filter {
                return !arties.keys.contains($0)
            }
            .forEach {
                sceneView.scene.rootNode.childNode(withName: $0, recursively: false)?.removeFromParentNode()
                arties.removeValue(forKey: $0)
        }
    }
}

private extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
}
