import ARKit
import CoreLocation

extension CLLocationDirection {
    var toRadians: CGFloat {
        let adjusted = Float((450 - self).remainder(dividingBy: 360)) + 90
        return CGFloat(GLKMathDegreesToRadians(adjusted))
    }
}
