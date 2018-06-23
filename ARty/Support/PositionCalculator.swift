import CoreLocation
import SceneKit

struct PositionCalculator {
    static func position(location: CLLocation, worldOrigin: CLLocation) -> SCNVector3 {
        let bearing = self.bearing(origin: worldOrigin, location: location)

        let rotationMatrix = self.rotationMatrix(bearing: Float(bearing))

        let distance = location.distance(from: worldOrigin)

        let position = vector_float4(0, 0, Float(-distance), 0)

        let translationMatrix = self.translationMatrix(translation: position)

        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)

        let locationTransform = simd_mul(matrix_identity_float4x4, transformMatrix)

        let positionFromTransform = self.positionFromTransform(locationTransform)

        return positionFromTransform.minApplied.maxApplied.yAdjusted
    }
}

private extension PositionCalculator {
    static func bearing(origin: CLLocation, location: CLLocation) -> Double {
        let lat1 = origin.coordinate.latitude.radians
        let long1 = origin.coordinate.longitude.radians

        let lat2 = location.coordinate.latitude.radians
        let long2 = location.coordinate.longitude.radians

        let longDiff = long2 - long1

        let y = sin(longDiff) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longDiff)

        return atan2(y, x)
    }

    static func rotationMatrix(bearing: Float) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4

        matrix.columns.0.x = cos(bearing)
        matrix.columns.0.z = -sin(bearing)

        matrix.columns.2.x = sin(bearing)
        matrix.columns.2.z = cos(bearing)

        return matrix.inverse
    }

    static func translationMatrix(translation: vector_float4) -> simd_float4x4 {
        var matrix = matrix_identity_float4x4
        matrix.columns.3 = translation
        return matrix
    }

    static func positionFromTransform(_ transform: simd_float4x4) -> SCNVector3 {
        return .init(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}

private extension SCNVector3 {
    var minApplied: SCNVector3 {
        if length < 1 {
            let multiplier = 1 / length
            return multiplied(by: multiplier)
        }
        return self
    }

    var maxApplied: SCNVector3 {
        if length > 5 {
            let multiplier = 5 / length
            return multiplied(by: multiplier)
        }
        return self
    }

    var length: Float {
        return sqrt((x * x + y * y + z * z))
    }

    func multiplied(by scalar: Float) -> SCNVector3 {
        return .init(x * scalar, y * scalar, z * scalar)
    }
}
