import ARKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!

    private let locationManager = CLLocationManager()
    private var lastLocation = CLLocation()
    private var startDate = Date()

    private let uid = UUID().uuidString

    private var arties = [String: ARty]()

    private var arty: ARty? {
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

        // get value from user defaults
        // load
        // then check network for latest user config
        // load updated model if necessary
        // update user defaults
        do {
            addARtyToScene(try ARty(uid: uid, model: "mutant"))
        } catch {
            print(error)
        }

        nearbyUsers(uid: uid)
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

    @IBAction func didTapHoldPositionButton(_ sender: Any) {
    }

    @IBAction func didTapEditAnimationsButton(_ sender: Any) {
    }
    
    @IBAction func didTapEditARtyButton(_ sender: Any) {
        let controller = EditARtyViewController(delegate: self)
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }
}

private extension ViewController {
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        startDate = Date()
    }

    func nearbyUsers(uid: String) {
        ViewController.mockNetworkNearbyUsers(uid: uid) { [weak self] users in
            self?.processNearbyUsers(users)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // check if app in foreground
                self?.nearbyUsers(uid: uid)
            }
        }
    }

    static func mockNetworkNearbyUsers(uid: String, completion: ([User]) -> Void) {
        // get json from backend
        // use codable to make array of users
    }

    func processNearbyUsers(_ users: [User]) {
        users.forEach {
            if arties[$0.uid] != nil {
                updateARty(for: $0)
            } else {
                do {
                    let arty =  try ARty(
                        uid: $0.uid,
                        model: $0.model,
                        passiveAnimation: $0.passiveAnimation,
                        pokeAnimation: $0.pokeAnimation
                    )
                    addARtyToScene(arty)
                } catch {
                    print(error)
                }
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

    func addARtyToScene(_ arty: ARty) {
        arty.position = SCNVector3(0, arty.positionAdjustment, arty.positionAdjustment) // extract
        sceneView.scene.rootNode.childNode(withName: arty.uid, recursively: false)?.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(arty)
        arties[arty.uid] = arty
        arty.label = label
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
}

extension ViewController: ARSCNViewDelegate {
}

extension ViewController: ARSessionDelegate {
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

extension ViewController: CLLocationManagerDelegate {
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

extension ViewController: EditARtyViewControllerDelegate {
    func didChangeARty(to arty: String) {
        if arty != self.arty?.model {
            do {
                let arty = try ARty(uid: uid, model: arty)
                addARtyToScene(arty)
                // get saved recent animations from UD for model and set them
                // update in user defaults
                // update in database
            } catch {
                print(error)
            }
        }
    }
}
