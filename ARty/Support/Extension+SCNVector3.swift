import SceneKit
import CoreLocation

extension SCNVector3 {
    init(location: CLLocation, worldOrigin: CLLocation) {
        let bearing = location.bearing(from: worldOrigin)
        let rotationAroundY = simd_float4x4.rotationAroundY(radians: Float(bearing)).inverse
        let distance = location.distance(from: worldOrigin)
        let positionTranslation = simd_float4(0, 0, Float(-distance), 0)
        let translationMatrix = simd_float4x4.translationMatrix(translation: positionTranslation)
        let newTransform = simd_mul(rotationAroundY, translationMatrix)
        let transformFromOrigin = simd_mul(matrix_identity_float4x4, newTransform)
        self.init(transform: transformFromOrigin)
        applyMin(1)
        applyMax(3)
        y = -1
    }

    init(transform: simd_float4x4) {
        self.init(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return .init(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return .init(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return .init(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }

    // swiftlint:disable shorthand_operator
    static func *= (vector: inout SCNVector3, scalar: Float) {
        vector = vector * scalar
    }
    // swiftlint:enable shorthand_operator

    var length: Float {
        return sqrt(x * x + y * y + z * z)
    }

    func distance(to vector: SCNVector3) -> Float {
        return (self - vector).length
    }

    mutating func applyMin(_ min: Float) {
        if length < min {
            let multiplier = min / length
            self *= multiplier
        }
    }

    mutating func applyMax(_ max: Float) {
        if length > max {
            let multiplier = max / length
            self *= multiplier
        }
    }
}
