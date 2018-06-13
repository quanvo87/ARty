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

    func moveARty(_ arty: ARty, location: CLLocation, heading: CLHeading) {
        guard let worldOrigin = worldOrigin else {
            return
        }
        ARtyMover.move(
            arty,
            location: location,
            heading: heading,
            worldOrigin: worldOrigin
        )
    }
}

extension ARSessionManager: AppStateObserverDelegate {
    func appStateObserverAppDidBecomeActive(_ observer: AppStateObserver) {}

    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver) {
        clearARSession()
    }
}

private extension ARSessionManager {
    func runARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        session.run(configuration, options: [.resetTracking])
    }

    func clearARSession() {
        worldOrigin = nil
        session.pause()
    }
}
