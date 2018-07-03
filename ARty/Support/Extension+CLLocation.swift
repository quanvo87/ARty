import CoreLocation
import FirebaseFirestore

extension CLLocation {
    convenience init(latitude: Double, longitude: Double, course: Double) {
        self.init(
            coordinate: .init(latitude: latitude, longitude: longitude),
            altitude: .init(),
            horizontalAccuracy: .init(),
            verticalAccuracy: .init(),
            course: course,
            speed: .init(),
            timestamp: .init()
        )
    }

    convenience init(_ snapshot: DocumentSnapshot?) throws {
        guard
            let unwrappedSnapshot = snapshot,
            let data = unwrappedSnapshot.data(),
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double,
            let course = data["course"] as? Double else {
                throw ARtyError.invalidDataFromServer(snapshot?.data())
        }
        self.init(latitude: latitude, longitude: longitude, course: course)
    }

    var dictionary: [String: Double] {
        return [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "course": course
        ]
    }

    func bearing(from origin: CLLocation) -> Double {
        let lat1 = origin.coordinate.latitude.radians
        let long1 = origin.coordinate.longitude.radians

        let lat2 = coordinate.latitude.radians
        let long2 = coordinate.longitude.radians

        let longDiff = long2 - long1

        let y = sin(longDiff) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longDiff)

        return atan2(y, x)
    }
}
