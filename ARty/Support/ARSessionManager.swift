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
            runARSession()
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
        guard worldOrigin != nil else {
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

    func positionARty(_ arty: ARty, location: Location) {
        guard let worldOrigin = worldOrigin else {
            return
        }
        LocationCalculator.position(arty, location: location, worldOrigin: worldOrigin)
    }

    func moveARty(_ arty: ARty, location: Location) {
        guard let worldOrigin = worldOrigin else {
            return
        }
        LocationCalculator.move(arty, location: location, worldOrigin: worldOrigin)
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
