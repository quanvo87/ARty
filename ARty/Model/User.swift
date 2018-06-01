import FirebaseFirestore

struct User {
    let uid: String
    let model: String
    let passiveAnimation: String
    let pokeAnimation: String
    let latitude: Double
    let longitude: Double

    init(uid: String,
         model: String,
         passiveAnimation: String,
         pokeAnimation: String,
         latitude: Double,
         longitude: Double) {
        self.uid = uid
        self.model = model
        self.passiveAnimation = passiveAnimation
        self.pokeAnimation = pokeAnimation
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ data: [String: Any]?) throws {
        guard let uid = data?["uid"] as? String,
            let model = data?["model"] as? String,
            let passiveAnimation = data?["passiveAnimation"] as? String,
            let pokeAnimation = data?["pokeAnimation"] as? String,
            let location = data?["location"] as? GeoPoint else {
                throw ARtyError.invalidDataFromServer(data)
        }
        self.uid = uid
        self.model = model
        self.passiveAnimation = passiveAnimation
        self.pokeAnimation = pokeAnimation
        self.latitude = location.latitude
        self.longitude = location.longitude
    }

    var dictionary: [String: Any] {
        return [
            "uid": uid,
            "model": model,
            "passiveAnimation": passiveAnimation,
            "pokeAnimation": pokeAnimation,
            "latitude": latitude,
            "longitude": longitude
        ]
    }
}
