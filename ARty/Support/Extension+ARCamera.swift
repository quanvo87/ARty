import ARKit

extension ARCamera.TrackingState {
    static func == (lhs: ARCamera.TrackingState, rhs: ARCamera.TrackingState) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailable, .notAvailable):
            return true
        case (.limited, .limited):
            return true
        case (.normal, .normal):
            return true
        default:
            return false
        }
    }
}
