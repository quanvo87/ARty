import CoreLocation
import SceneKit

// todo: make functions return values, do the animations in the artys
struct LocationCalculator {
    static func position(_ arty: ARty, location: Location, worldOrigin: CLLocation) {
        let bearing = self.bearing(origin: worldOrigin, location: location)

        let rotationMatrix = self.rotationMatrix(bearing: Float(bearing))

        let distance = self.distance(location: location, worldOrigin: worldOrigin)

        let position = vector_float4(0, 0, Float(-distance), 0)

        let translationMatrix = self.translationMatrix(translation: position)

        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)

        let locationTransform = simd_mul(matrix_identity_float4x4, transformMatrix)

        let positionFromTransform = self.positionFromTransform(locationTransform)

        arty.position = positionFromTransform
    }

    static func move(_ arty: ARty,
                     location: Location,
                     worldOrigin: CLLocation) {
        rotate(arty, location: location)
        position(arty, location: location, worldOrigin: worldOrigin)
        // todo: scale
    }
}

private extension LocationCalculator {
    static func rotate(_ arty: ARty, location: Location) {
        var angle: Float

        if location.course >= 0 {
            angle = Float(location.course.angle)
        } else if location.heading >= 0 {
            angle = Float(location.heading.angle)
        } else {
            return
        }

        let rotation = SCNMatrix4MakeRotation(angle, 0, 1, 0)

        let newTransform = SCNMatrix4Mult(arty.transform, rotation)

        arty.transform = newTransform
    }

    static func bearing(origin: CLLocation, location: Location) -> Double {
        let lat1 = origin.coordinate.latitude.radians
        let long1 = origin.coordinate.longitude.radians

        let lat2 = location.latitude.radians
        let long2 = location.longitude.radians

        let longDiff = long2 - long1

        // swiftlint:disable identifier_name
        let y = sin(longDiff) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longDiff)
        // swiftlint:enable identifier_name

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

    static func distance(location: Location, worldOrigin: CLLocation) -> Double {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return clLocation.distance(from: worldOrigin)
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
