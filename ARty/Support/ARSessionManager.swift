import ARKit
import CoreLocation

class ARSessionManager {
    private let session: ARSession
    private lazy var appStateObserver = AppStateObserver(delegate: self)

    init(session: ARSession) {
        self.session = session
    }

    private var worldOrigin: CLLocation? {
        didSet {
            restartARSession()
        }
    }

    func start() {
        appStateObserver.start()
    }

    func stop() {
        appStateObserver.stop()
        clearARSession()
    }

    func restartARSession() {
        if worldOrigin == nil {
            return
        }
        worldOrigin = nil
        runARSession()
    }

    func setWorldOrigin(_ location: CLLocation) {
        guard let worldOrigin = worldOrigin else {
            self.worldOrigin = location
            return
        }
        if location.horizontalAccuracy < worldOrigin.horizontalAccuracy {
            self.worldOrigin = location
        }
    }

    func positionFromWorldOrigin(to location: CLLocation) -> SCNVector3? {
//        guard let worldOrigin = worldOrigin else {
//            return nil
//        }
        return .init()
    }

    private func runARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        session.run(configuration, options: [.resetTracking])
    }

    private func clearARSession() {
        worldOrigin = nil
        session.pause()
    }
}

extension ARSessionManager: AppStateObserverDelegate {
    func appStateObserverAppBecameActive(_ observer: AppStateObserver) {}

    func appStateObserverAppEnteredBackground(_ observer: AppStateObserver) {
        clearARSession()
    }
}
