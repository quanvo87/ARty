import FirebaseFirestore

struct User {
    let uid: String
    let model: String
    let passiveAnimation: String
    let pokeAnimation: String
    let recentPassiveAnimations: [String: String]
    let recentPokeAnimations: [String: String]
    let latitude: Double
    let longitude: Double

    init(_ data: [String: Any]?) throws {
        guard let uid = data?["uid"] as? String else {
            throw ARtyError.invalidDataFromServer(data)
        }
        self.uid = uid
        model = data?["model"] as? String ?? ""
        passiveAnimation = data?["passiveAnimation"] as? String ?? ""
        pokeAnimation = data?["pokeAnimation"] as? String ?? ""
        recentPassiveAnimations = data?["recentPassiveAnimations"] as? [String: String] ?? [:]
        recentPokeAnimations = data?["recentPokeAnimations"] as? [String: String] ?? [:]
        if let location = data?["location"] as? GeoPoint {
            latitude = location.latitude
            longitude = location.longitude
        } else {
            latitude = .leastNormalMagnitude
            longitude = .leastNormalMagnitude
        }
    }
}
