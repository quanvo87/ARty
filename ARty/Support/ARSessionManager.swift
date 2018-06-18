import ARKit
import CoreLocation

protocol ARSessionManagerDelegate: class {
    func arSessionManager(_ manager: ARSessionManager, didUpdateWorldOrigin worldOrigin: CLLocation)
}

class ARSessionManager {
    private let session: ARSession
    private var appIsActive = true
    private lazy var appStateObserver = AppStateObserver(delegate: self)
    private weak var delegate: ARSessionManagerDelegate?

    init(session: ARSession, delegate: ARSessionManagerDelegate) {
        self.session = session
        self.delegate = delegate
    }

    private(set) var worldOrigin: CLLocation? {
        didSet {
            guard let worldOrigin = worldOrigin else {
                return
            }
            let configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            session.run(configuration, options: [.resetTracking])
            delegate?.arSessionManager(self, didUpdateWorldOrigin: worldOrigin)
        }
    }

    func start() {
        appStateObserver.start()
    }

    func stop() {
        appStateObserver.stop()
        pause()
    }

    func pause() {
        worldOrigin = nil
        session.pause()
    }

    func setWorldOrigin(_ location: CLLocation) {
        guard appIsActive else {
            return
        }
        guard let worldOrigin = worldOrigin else {
            self.worldOrigin = location
            return
        }
        if location.horizontalAccuracy < worldOrigin.horizontalAccuracy {
            self.worldOrigin = location
        }
    }
}

extension ARSessionManager: AppStateObserverDelegate {
    func appStateObserverAppDidBecomeActive(_ observer: AppStateObserver) {
        appIsActive = true
    }

    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver) {
        appIsActive = false
        pause()
    }
}
