import SceneKit
import CoreLocation

extension SCNVector3 {
    static func make(location: CLLocation, worldOrigin: CLLocation) -> SCNVector3 {
        let bearing = location.bearing(from: worldOrigin)

        let rotationAroundY = simd_float4x4.rotationAroundY(radians: Float(bearing)).inverse

        let distance = location.distance(from: worldOrigin)

        let positionTranslation = simd_float4(0, 0, Float(-distance), 0)

        let translationMatrix = simd_float4x4.translationMatrix(translation: positionTranslation)

        let newTransform = simd_mul(rotationAroundY, translationMatrix)

        let transformFromOrigin = simd_mul(matrix_identity_float4x4, newTransform)

        var position = make(transform: transformFromOrigin).minApplied(1).maxApplied(3)
        position.y = -1

        return position
    }

    static func make(transform: simd_float4x4) -> SCNVector3 {
        return .init(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }

    static func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
    }

    var length: Float {
        return sqrt(x * x + y * y + z * z)
    }

    var normalized: SCNVector3 {
        return self / length
    }

    func distance(to vector: SCNVector3) -> Float {
        return (self - vector).length
    }

    func minApplied(_ min: Float) -> SCNVector3 {
        if length < min {
            let multiplier = min / length
            return self * multiplier
        }
        return self
    }

    func maxApplied(_ max: Float) -> SCNVector3 {
        if length > max {
            let multiplier = max / length
            return self * multiplier
        }
        return self
    }
}
