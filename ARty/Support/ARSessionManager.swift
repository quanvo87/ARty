import ARKit
import CoreLocation

protocol ARSessionManagerDelegate: class {
    func arSessionManager(_ manager: ARSessionManager, didUpdateWorldOrigin worldOrigin: CLLocation)
}

// todo: reset every once in a while?
class ARSessionManager {
    private let session: ARSession
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

    func load() {}

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
