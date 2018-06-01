import Firebase

struct Database {
    private static let db: Firestore = {
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        return db
    }()

    private static let usersCollection = db.collection("users")

    private init() {}

    static func user(_ uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        usersCollection.document(uid).getDocument { document, error in
            if let error = error {
                completion(.fail(error))
            } else {
                do {
                    let user = try User(document?.data())
                    completion(.success(user))
                } catch {
                    completion(.fail(error))
                }
            }
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

extension Database {
    enum Result<T, Error> {
        case success(T)
        case fail(Error)
    }
}
