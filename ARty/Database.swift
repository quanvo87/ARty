import Firebase

struct Database {
    private static let db: Firestore = {
        let db = Firestore.firestore()
        db.settings.areTimestampsInSnapshotsEnabled = true
        return db
    }()

    private static let usersCollection = db.collection("users")

    private init() {}

    static func setUser(_ uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).setData([
            "uid": uid
        ], merge: true) { error in
            completion(error)
        }
    }

    static func setARty(_ arty: ARty, completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).updateData([
            "model": arty.model,
            "passiveAnimation": arty.passiveAnimation,
            "pokeAnimation": arty.pokeAnimation
        ]) { error in
            completion(error)
        }
    }

    static func setPassiveAnimation(_ passiveAnimation: String,
                                    for uid: String,
                                    completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "passiveAnimation" : passiveAnimation
        ]) { error in
            completion(error)
        }
    }

    static func setPokeAnimation(_ pokeAnimation: String,
                                 for uid: String,
                                 completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "pokeAnimaton" : pokeAnimation
        ]) { error in
            completion(error)
        }
    }

    static func setLocation(latitude: Double,
                            longitude: Double,
                            uid: String,
                            completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "location" : GeoPoint(latitude: latitude, longitude: longitude)
        ]) { error in
            completion(error)
        }
    }
}
