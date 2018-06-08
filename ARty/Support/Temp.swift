import SceneKit

// remove when we use actual locations

extension SCNVector3 {
    static var random: SCNVector3 {
        return .init(20.random, 0, 20.random)
    }
}

private extension Double {
    var random: Double {
        return Double(arc4random_uniform(UInt32(self))) - (self / 2)
    }
}
