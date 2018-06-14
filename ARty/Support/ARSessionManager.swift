import ARKit
import CoreLocation

class ARSessionManager {
    private let session: ARSession
    private lazy var appStateObserver = AppStateObserver(delegate: self)

    private(set) var worldOrigin: CLLocation? {
        didSet {
            let configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            session.run(configuration, options: [.resetTracking])
        }
    }

    init(session: ARSession) {
        self.session = session
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
    }

    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver) {
        pause()
    }
}
