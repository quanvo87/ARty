import ARKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private var uid: String?
    private var arty: ARty?
    private var arties = [String: ARty]()
    private let locationDatabase = LocationDatabase()
    private lazy var appStateObserver = AppStateObserver(delegate: self)
    private lazy var authManager = AuthManager(delegate: self)
    private lazy var locationManager = LocationManager(delegate: self)
    private lazy var arSessionManager = ARSessionManager(session: sceneView.session, delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = SCNScene()
        sceneView.scene = scene
//        sceneView.autoenablesDefaultLighting = true
//        sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
//        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.delegate = self
        sceneView.session.run(ARWorldTrackingConfiguration())
        authManager.listenForAuthState()
        arSessionManager.load()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: sceneView) else {
            return
        }
        let hitTest = sceneView.hitTest(location)
        guard let uid = (hitTest.first?.node.parent?.parent as? ARty)?.uid else {
            return
        }
        if let arty = arty, uid == arty.uid {
            arty.turnToCamera()
            try? arty.playAnimation(arty.pokeEmote)
            Database.updatePokeTimestamp(for: uid) { error in
                if let error = error {
                    print(error)
                }
            }
        } else if let arty = arties[uid] {
            arty.turnToCamera()
            try? arty.playAnimation(arty.pokeEmote)
        }
    }
}

extension MainViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arty = arty,
            let basePosition = arty.basePosition,
            let currentPosition = sceneView.pointOfView?.position else {
                return
        }
        arty.position = basePosition + currentPosition
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let uid = uid, let newLocation = manager.location else {
            return
        }
        if locationManager.isValidLocation(newLocation) {
            locationManager.lastLocation = newLocation

            if let arty = arty {
                locationManager.setLocationInDatabase(uid: arty.uid)
            }

            if appStateObserver.appIsActive {
                arty?.turnToDirection(newLocation.course)
                try? arty?.walk(location: newLocation)

                arSessionManager.setWorldOrigin(newLocation)

                nearbyUsers(
                    uid: uid,
                    latitude: newLocation.coordinate.latitude,
                    longitude: newLocation.coordinate.longitude
                )
            }
        }
    }

    private func nearbyUsers(uid: String, latitude: Double, longitude: Double) {
        locationDatabase.nearbyUsers(uid: uid, latitude: latitude, longitude: longitude) { [weak self] result in
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

    private func observeUser(_ uid: String) {
        if uid != self.uid && !arties.keys.contains(uid) {
            ARty.make(uid: uid, pointOfView: sceneView.pointOfView, delegate: self) { [weak self] result in
                switch result {
                case .fail(let error):
                    print(error)
                case .success(let arty):
                    self?.arties[arty.uid] = arty
                }
            }
        }
    }

    private func removeStaleUsers(_ uids: [String]) {
        arties.keys
            .filter {
                return !uids.contains($0)
            }
            .forEach {
                sceneView.scene.rootNode.childNode(withName: $0, recursively: false)?.removeFromParentNode()
                arties.removeValue(forKey: $0)
        }
    }
}

extension MainViewController: AppStateObserverDelegate {
    func appStateObserverAppDidBecomeActive(_ observer: AppStateObserver) {}

    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver) {
        arSessionManager.pause()
    }
}

extension MainViewController: AuthManagerDelegate {
    func authManager(_ manager: AuthManager, userDidLogIn uid: String) {
        UIApplication.shared.isIdleTimerDisabled = true
        self.uid = uid
        appStateObserver.start()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        loadUser(uid)
    }

    func authManagerUserDidLogOut(_ manager: AuthManager) {
        UIApplication.shared.isIdleTimerDisabled = false
        uid = nil
        arty = nil
        arties.removeAll()
        removeNodes()
        appStateObserver.stop()
        locationManager.stopUpdatingLocation()
        arSessionManager.pause()
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
                            let arty = try ARty(user: user, pointOfView: self?.sceneView.pointOfView, delegate: nil)
                            self?.addARtyToScene(arty)
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

    private func removeNodes() {
        sceneView.scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }
    }

    private func showLoginViewController() {
        let loginViewController = UIStoryboard.main.instantiateViewController(
            withIdentifier: String(describing: LoginViewController.self)
        )
        let navigationController = UINavigationController(rootViewController: loginViewController)
        present(navigationController, animated: true)
    }
}

extension MainViewController: ARSessionManagerDelegate {
    func arSessionManager(_ manager: ARSessionManager, didUpdateWorldOrigin worldOrigin: CLLocation) {
        arties.values.forEach {
            guard let location = $0.location else {
                return
            }
            $0.position = PositionCalculator.position(location: location, worldOrigin: worldOrigin)
        }
    }
}

extension MainViewController: ARtyDelegate {
    func arty(_ arty: ARty, userChangedModel user: User) {
        do {
            let arty = try ARty(user: user, pointOfView: sceneView.pointOfView, delegate: self)
            sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
            arties[arty.uid] = arty
        } catch {
            print(error)
        }
    }

    func arty(_ arty: ARty, didUpdateLocation location: CLLocation) {
        guard let worldOrigin = arSessionManager.worldOrigin else {
            return
        }
        let position = PositionCalculator.position(location: location, worldOrigin: worldOrigin)
        if sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false) == nil {
            arty.position = position
            arty.eulerAngles.y = Float(Double(arc4random_uniform(360)).radians)
            DispatchQueue.main.async { [weak self] in
                self?.sceneView.scene.rootNode.addChildNode(arty)
            }
        } else {
            arty.turnToDirection(location.course)
            try? arty.walk(to: position)
        }
    }
}

extension MainViewController: ChooseARtyViewControllerDelegate {
    func chooseARtyViewController(_ controller: ChooseARtyViewController, didChooseARty model: String) {
        guard let uid = uid else {
            return
        }
        if model != arty?.model {
            do {
                let arty = try ARty(
                    uid: uid,
                    model: model,
                    status: self.arty?.status ?? "Hello :)",
                    pointOfView: sceneView.pointOfView,
                    delegate: nil
                )
                addARtyToScene(arty)
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

    @IBAction func didTapEditStatusButton(_ sender: Any) {
        guard let arty = arty else {
            return
        }
        let alert = UIAlertController(
            title: "What's on your mind?",
            message: "Max 10 chars",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = arty.status
            textField.placeholder = "Enter a status"
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            guard let status = alert?.textFields?[0].text else {
                return
            }
            arty.status = status
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func didTapReloadButton(_ sender: Any) {
        arSessionManager.pause()
    }

    @IBAction func didTapLogOutButton(_ sender: Any) {
        authManager.logout()
    }

    func showChooseARtyViewController() {
        let controller = ChooseARtyViewController(currentARty: arty?.model ?? "", delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    func addARtyToScene(_ arty: ARty) {
        self.arty = arty
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        DispatchQueue.main.async { [weak self] in
            self?.sceneView.scene.rootNode.addChildNode(arty)
            arty.setBasePosition()
            arty.turnToCamera()
        }
    }
}
