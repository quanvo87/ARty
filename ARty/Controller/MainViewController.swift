import ARKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var holdPositionButton: UIButton!
    @IBOutlet weak var leftArrow: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    @IBOutlet weak var label: UILabel!

    private var uid: String?
    private var myARty: MyARty?
    private var friendlyARties = [String: ARty]()
    private var isHoldingPosition = false
    private lazy var appStateObserver = AppStateObserver(delegate: self)
    private lazy var authManager = AuthManager(delegate: self)
    private lazy var locationManager = LocationManager(delegate: self)
    private lazy var arSessionManager = ARSessionManager(session: sceneView.session, delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        holdPositionButton.layer.cornerRadius = 5

        leftArrow.isHidden = true
        rightArrow.isHidden = true

        let scene = SCNScene()
        sceneView.scene = scene
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
        if let uid = (hitTest.first?.node.parent?.parent as? ARty)?.uid {
            if let myARty = myARty, uid == myARty.uid {
                myARty.turnToCamera()
                try? myARty.playAnimation(myARty.pokeEmote)
                Database.updatePokeTimestamp(for: uid) { error in
                    if let error = error {
                        print(error)
                    }
                }
            } else if let friendlyARty = friendlyARties[uid] {
                friendlyARty.turnToCamera()
                try? friendlyARty.playAnimation(friendlyARty.pokeEmote)
            }
        } else {
            myARty?.setBasePosition()
            myARty?.turnToCamera()
            leftArrow.isHidden = true
            rightArrow.isHidden = true
        }
    }
}

extension MainViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard
            let myARty = myARty,
            let currentPosition = sceneView.pointOfView?.position else {
                return
        }
        showArrowToMyARty(myARty)
        if !isHoldingPosition {
            myARty.position = myARty.basePosition + currentPosition
        }
    }

    private func showArrowToMyARty(_ myARty: MyARty) {
        let width = Float(sceneView.frame.width)
        let position = sceneView.projectPoint(myARty.position)

        if position.z < 1 {
            if position.x > width {
                leftArrow.isHidden = true
                rightArrow.isHidden = false
            } else if position.x < 0 {
                leftArrow.isHidden = false
                rightArrow.isHidden = true
            } else {
                leftArrow.isHidden = true
                rightArrow.isHidden = true
            }
        } else if position.x < 0 {
            leftArrow.isHidden = true
            rightArrow.isHidden = false
        } else {
            leftArrow.isHidden = false
            rightArrow.isHidden = true
        }
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
            if myARty != nil {
                locationManager.setLocationInDatabase(to: newLocation, for: uid)
            }
            if appStateObserver.appIsActive {
                if !isHoldingPosition {
                    myARty?.turnToDirection(newLocation.course)
                    try? myARty?.walk(location: newLocation)
                }
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
        LocationDatabase.shared.nearbyUsers(uid: uid, latitude: latitude, longitude: longitude) { [weak self] result in
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
        guard let pointOfView = sceneView.pointOfView else {
            return
        }
        if !friendlyARties.keys.contains(uid) {
            FriendlyARty.make(uid: uid, pointOfView: pointOfView, delegate: self) { [weak self] result in
                switch result {
                case .fail(let error):
                    print(error)
                case .success(let friendlyARty):
                    self?.friendlyARties[friendlyARty.uid] = friendlyARty
                }
            }
        }
    }

    private func removeStaleUsers(_ uids: [String]) {
        friendlyARties.keys
            .filter {
                return !uids.contains($0)
            }
            .forEach {
                sceneView.scene.rootNode.childNode(withName: $0, recursively: false)?.removeFromParentNode()
                friendlyARties.removeValue(forKey: $0)
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
        myARty = nil
        friendlyARties.removeAll()
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
                        guard let pointOfView = self?.sceneView.pointOfView else {
                            return
                        }
                        do {
                            let myARty = try MyARty.makeFromUser(user, pointOfView: pointOfView)
                            self?.addMyARtyToScene(myARty)
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
        friendlyARties.values.forEach {
            guard let location = $0.location else {
                return
            }
            $0.position = .init(location: location, worldOrigin: worldOrigin)
        }
    }
}

extension MainViewController: FriendlyARtyDelegate {
    func friendlyARty(_ friendlyARty: FriendlyARty, userChangedModel user: User) {
        guard let pointOfView = sceneView.pointOfView else {
            return
        }
        sceneView.scene.rootNode.childNode(withName: user.uid, recursively: false)?.removeFromParentNode()
        do {
            let friendlyARty = try FriendlyARty(user: user, pointOfView: pointOfView, delegate: self)
            friendlyARties[friendlyARty.uid] = friendlyARty
        } catch {
            print(error)
        }
    }

    func friendlyARty(_ friendlyARty: FriendlyARty, didUpdateLocation location: CLLocation) {
        guard let worldOrigin = arSessionManager.worldOrigin else {
            return
        }
        let position = SCNVector3(location: location, worldOrigin: worldOrigin)
        if sceneView.scene.rootNode.childNode(withName: friendlyARty.uid, recursively: false) == nil {
            friendlyARty.position = position
            DispatchQueue.main.async { [weak self] in
                self?.sceneView.scene.rootNode.addChildNode(friendlyARty)
            }
        } else {
            friendlyARty.turnToDirection(location.course)
            try? friendlyARty.walk(to: position)
        }
    }
}

extension MainViewController: ChooseARtyViewControllerDelegate {
    func chooseARtyViewController(_ controller: ChooseARtyViewController, didChooseARty model: String) {
        guard let uid = uid, let pointOfView = sceneView.pointOfView else {
            return
        }
        if model != myARty?.model {
            do {
                var newMyARty: MyARty
                if let myARty = myARty {
                    newMyARty = try MyARty.makeFromModelChange(
                        uid: uid,
                        model: model,
                        status: myARty.status,
                        pointOfView: pointOfView,
                        basePosition: myARty.basePosition
                    )
                } else {
                    newMyARty = try MyARty.makeNew(uid: uid, model: model, pointOfView: pointOfView)
                }
                addMyARtyToScene(newMyARty)
                setRecentEmotes(for: newMyARty)
                Database.updateModel(myARty: newMyARty) { error in
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
                do {
                    try arty.setPassiveEmote(to: user.passiveEmote(for: user.model))
                    try arty.setPokeEmote(to: user.pokeEmote(for: user.model))
                } catch {
                    print(error)
                }
            case .fail(let error):
                print(error)
            }
        }
    }
}

private extension MainViewController {
    @IBAction func didTapHoldPositionButton(_ sender: Any) {
        if isHoldingPosition {
            isHoldingPosition = false
            holdPositionButton.backgroundColor = .clear
        } else {
            isHoldingPosition = true
            holdPositionButton.backgroundColor = .white
        }
    }

    @IBAction func didTapChooseEmotesButton(_ sender: Any) {
        guard let myARty = myARty else {
            return
        }
        let controller = ChooseEmotesViewController.make(myARty: myARty)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    @IBAction func didTapChooseARtyButton(_ sender: Any) {
        showChooseARtyViewController()
    }

    @IBAction func didTapEditStatusButton(_ sender: Any) {
        guard let myARty = myARty else {
            return
        }
        let alert = UIAlertController(
            title: "What's on your mind?",
            message: "Max 10 chars",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.text = myARty.status
            textField.placeholder = "Enter a status"
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            guard let status = alert?.textFields?[0].text else {
                return
            }
            myARty.status = status
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
        let controller = ChooseARtyViewController(currentARty: myARty?.model ?? "", delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    func addMyARtyToScene(_ myARty: MyARty) {
        self.myARty = myARty
        sceneView.scene.rootNode.childNode(withName: myARty.uid, recursively: false)?.removeFromParentNode()
        DispatchQueue.main.async { [weak self] in
            self?.sceneView.scene.rootNode.addChildNode(myARty)
            myARty.turnToCamera()
        }
    }
}
