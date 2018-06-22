import SceneKit

extension SCNVector3 {
    var yAdjusted: SCNVector3 {
        return .init(x, -0.1, z)
    }

    var zAdjusted: SCNVector3 {
        return .init(x, 0, z - 1)
    }
}
