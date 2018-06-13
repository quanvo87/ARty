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
        sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        return scene
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        // todo: turn to face user
        try? arty.playAnimation(arty.pokeEmote)
        updatePokeTimestamp(uid)
    }

    private func updatePokeTimestamp(_ uid: String) {
        if uid == self.uid {
            Database.updatePokeTimestamp(for: uid) { error in
                if let error = error {
                    print(error)
                }
            }
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
            locationManager.startUpdatingHeading()
        } else {
            // todo: show alert
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let uid = uid, let newLocation = manager.location else {
            return
        }
        if locationManager.isValidLocation(newLocation) {
            try? arty?.walk(location: newLocation)

            arSessionManager.setWorldOrigin(newLocation)

            locationManager.setLocationInDatabase(uid: uid)

            nearbyUsers(
                uid: uid,
                latitude: newLocation.coordinate.latitude,
                longitude: newLocation.coordinate.longitude
            )
        }
    }
}

extension MainViewController: AuthManagerDelegate {
    func authManager(_ manager: AuthManager, userDidLogIn uid: String) {
        UIApplication.shared.isIdleTimerDisabled = true
        self.uid = uid
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        arSessionManager.start()
        loadUser(uid)
    }

    func authManagerUserDidLogOut(_ manager: AuthManager) {
        UIApplication.shared.isIdleTimerDisabled = false
        uid = nil
        arties.removeAll()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
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
            sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
            arties[arty.uid] = arty
        } catch {
            print(error)
        }
    }

    func arty(_ arty: ARty, didUpdateLocation location: Location) {
        if sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false) == nil {
            sceneView.scene.rootNode.addChildNode(arty)
            arSessionManager.positionARty(arty, location: location)
        } else {
            arSessionManager.moveARty(arty, location: location)
        }
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
                setRecentEmotes(for: arty)
                Database.updateModel(arty: arty) { error in
                    if let error = error {
                        print(error)
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    private func setRecentEmotes(for arty: ARty) {
        Database.user(arty.uid) { result in
            switch result {
            case .success(let user):
                if let passiveEmote = user.passiveEmotes[arty.model] {
                    try? arty.setPassiveEmote(to: passiveEmote)
                }
                if let pokeEmote = user.pokeEmotes[arty.model] {
                    try? arty.setPokeEmote(to: pokeEmote)
                }
            case .fail(let error):
                print(error)
            }
        }
    }
}

private extension MainViewController {
    @IBAction func didTapHoldPositionButton(_ sender: Any) {
    }

    @IBAction func didTapChooseEmotesButton(_ sender: Any) {
        guard let arty = arty else {
            return
        }
        let controller = ChooseEmotesViewController.make(arty: arty)
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
        let controller = ChooseARtyViewController(currentARty: arty?.model ?? "", delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    // todo: only use this for your arty. other artys will be added by their location observer
    func addARtyToScene(_ arty: ARty, position: SCNVector3) {
        arty.position = arty.positionAdjustment + position
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
    }

    func nearbyUsers(uid: String, latitude: Double, longitude: Double) {
        LocationDatabase.nearbyUsers(uid: uid, latitude: latitude, longitude: longitude) { [weak self] result in
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
                    self?.arties[arty.uid] = arty
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
