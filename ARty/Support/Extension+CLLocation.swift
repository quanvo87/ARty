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
        guard let unwrappedSnapshot = snapshot,
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
}
