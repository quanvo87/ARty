import FirebaseFirestore

struct Database {
    private static let database: Firestore = {
        let database = Firestore.firestore()
        let settings = database.settings
        settings.areTimestampsInSnapshotsEnabled = true
        database.settings = settings
        return database
    }()

    private static let usersCollection = database.collection("users")

    private init() {}

    static func setUid(_ uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).setData([
            "uid": uid
        ], merge: true) { error in
            if let error = error {
                completion(error)
                return
            }
            LocationDatabase.setUid(uid) { error in
                completion(error)
            }
        }
    }

    // todo: add course and heading
    static func setLocation(uid: String, latitude: Double, longitude: Double, completion: @escaping (Error?) -> Void) {
        database.collection("locations").document(uid).setData([
            "latitude": latitude,
            "longitude": longitude
        ]) { error in
            if let error = error {
                completion(error)
                return
            }
            LocationDatabase.setLocation(uid: uid, latitude: latitude, longitude: longitude) { error in
                completion(error)
            }
        }
    }

    static func user(_ uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        usersCollection.document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.fail(error))
            } else {
                do {
                    completion(.success(try .init(snapshot)))
                } catch {
                    completion(.fail(error))
                }
            }
        }
    }

    static func userListener(_ uid: String, callback: @escaping (User) -> Void) -> ListenerRegistration {
        return usersCollection.document(uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            do {
                callback(try .init(snapshot))
            } catch {
                print(ARtyError.invalidDataFromServer(snapshot?.data()))
            }
        }
    }

    static func locationListener(uid: String, callback: @escaping (Double, Double) -> Void) -> ListenerRegistration {
        return database.collection("locations").document(uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            guard let data = snapshot?.data(),
                let latitude = data["latitude"] as? Double,
                let longitude = data["longitude"] as? Double else {
                    print(ARtyError.invalidDataFromServer(snapshot?.data()))
                    return
            }
            callback(latitude, longitude)
        }
    }

    static func updateModel(arty: ARty, completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).updateData([
            "model": arty.model
        ]) { error in
            completion(error)
        }
    }

    static func updatePassiveEmote(to emote: String,
                                   for arty: ARty,
                                   completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).updateData([
            "passiveEmotes.\(arty.model)": emote
        ]) { error in
            completion(error)
        }
    }

    static func updatePokeEmote(to emote: String,
                                for arty: ARty,
                                completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).updateData([
            "pokeEmotes.\(arty.model)": emote
        ]) { error in
            completion(error)
        }
    }

    static func updatePokeTimestamp(for uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "pokeTimestamp": Date()
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

private extension Optional where Wrapped == QuerySnapshot {
    func users() throws -> [User] {
        guard let `self` = self else {
            throw ARtyError.invalidDataFromServer(nil)
        }
        return try self.documents.map {
            return try .init($0)
        }
    }
}
