import FirebaseFirestore

struct Location {
    let latitude: Double
    let longitude: Double
    let course: Double
    let heading: Double

    init(latitude: Double,
         longitude: Double,
         course: Double,
         heading: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.course = course
        self.heading = heading
    }

    init(_ snapshot: DocumentSnapshot?) throws {
        guard let unwrappedSnapshot = snapshot,
            let data = unwrappedSnapshot.data(),
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double,
            let course = data["course"] as? Double,
            let heading = data["heading"] as? Double else {
                throw ARtyError.invalidDataFromServer(snapshot?.data())
        }
        self.latitude = latitude
        self.longitude = longitude
        self.course = course
        self.heading = heading
    }

    var dictionary: [String: Double] {
        return [
            "latitude": latitude,
            "longitude": longitude,
            "course": course,
            "heading": heading
        ]
    }
}
