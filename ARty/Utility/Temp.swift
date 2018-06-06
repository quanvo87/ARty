import SceneKit

// remove when we use actual locations

extension SCNVector3 {
    static var random: SCNVector3 {
        return .init(10.random, 0, 10.random)
    }
}

private extension Double {
    var random: Double {
        return Double(arc4random_uniform(UInt32(self))) - (self / 2)
    }
}
