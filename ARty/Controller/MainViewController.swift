import ARKit
import CoreLocation

class MainViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private let locationManager = LocationManager()
    private var uid: String?
    private var arties = [String: ARty]()
    private lazy var appStateObserver = AppStateObserver(delegate: self)
    private lazy var authManager = AuthManager(delegate: self)
    private lazy var nearbyUsersPoller = NearbyUsersPoller(delegate: self)

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
        locationManager.delegate = self
        runARSession()
        appStateObserver.start()
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
        try? arty.playPokeAnimation()   // todo: turn to face user, turn to original spot after poke animation
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
        guard let newLocation = manager.location else {
            return
        }
        if locationManager.isValidLocation(newLocation) {
            try? arty?.playWalkAnimation(location: newLocation)
            arty?.turn(location: newLocation)
            nearbyUsersPoller.coordinates = (newLocation.coordinate.latitude, newLocation.coordinate.longitude)
        }
        locationManager.lastLocation = newLocation
    }
}

extension MainViewController: AppStateObserverDelegate {
    func appStateObserverAppBecameActive(_ observer: AppStateObserver) {
        runARSession()
    }

    func appStateObserverAppEnteredBackground(_ observer: AppStateObserver) {
        pauseARSession()
    }
}

extension MainViewController: AuthManagerDelegate {
    func authManager(_ manager: AuthManager, userLoggedIn uid: String) {
        self.uid = uid
        runARSession()
        appStateObserver.start()
        loadUser(uid)
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        nearbyUsersPoller.start()
    }

    func authManagerUserLoggedOut(_ manager: AuthManager) {
        uid = nil
        arties.removeAll()
        sceneView.scene = scene
        pauseARSession()
        appStateObserver.stop()
        locationManager.stopUpdatingLocation()
        nearbyUsersPoller.stop()
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
                        self?.showEditARtyViewController()
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

extension MainViewController: NearbyUsersPollerDelegate {
    func nearbyUsersPoller(_ poller: NearbyUsersPoller, observeUser user: User) {
        if user.uid != uid && !arties.keys.contains(user.uid) {
            do {
                let arty = try ARty(user: user, delegate: self)
                addARtyToScene(arty, position: .random)
            } catch {
                print(error)
            }
        }
    }

    func nearbyUsersPoller(_ poller: NearbyUsersPoller, removeStaleUsers users: [User]) {
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
    func arty(_ arty: ARty, updateUser user: User) {
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
            // todo: move to ARty?
            try? arty.setPassiveAnimation(user.passiveAnimation)
            try? arty.setPokeAnimation(user.pokeAnimation)
            setPokeTimestamp(arty: arty, user: user)
            // todo: walk to new location if necessary
        }
    }

    private func setPokeTimestamp(arty: ARty, user: User) {
        if arty.pokeTimestamp != user.pokeTimestamp {
            try? arty.playPokeAnimation()
        }
        arty.pokeTimestamp = user.pokeTimestamp
    }
}

extension MainViewController: EditARtyViewControllerDelegate {
    func editARtyViewController(_ controller: EditARtyViewController, changeARtyTo model: String) {
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
    func editAnimationsViewController(_ controller: EditAnimationsViewController,
                                      setPassiveAnimationTo animation: String,
                                      for arty: ARty) {
        try? arty.setPassiveAnimation(animation)
        Database.updatePassiveAnimation(to: animation, for: arty) { _ in }
    }

    func editAnimationsViewController(_ controller: EditAnimationsViewController,
                                      setPokeAnimationTo animation: String,
                                      for arty: ARty) {
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

    @IBAction func didTapReloadButton(_ sender: Any) {
        runARSession()
    }

    @IBAction func didTapLogOutButton(_ sender: Any) {
        authManager.logout()
    }

    func runARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking])
    }

    func pauseARSession() {
        sceneView.session.pause()
    }

    func showEditARtyViewController() {
        let viewController = EditARtyViewController(delegate: self)
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    func addARtyToScene(_ arty: ARty, position: SCNVector3) {
        arty.position = arty.positionAdjustment + position  // todo: user anchors
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
    }
}

private extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
}
