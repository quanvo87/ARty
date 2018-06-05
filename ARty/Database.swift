import FirebaseFirestore

// todo: make these all use update instead of set
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

    static func nearbyUsers(latitude: Double,
                            longitude: Double,
                            completion: @escaping (Result<[User], Error>) -> Void) {
        usersCollection.getDocuments { snapshot, error in
            if let error = error {
                completion(.fail(error))
            } else {
                do {
                    completion(.success(try snapshot.users()))
                } catch {
                    completion(.fail(ARtyError.invalidDataFromServer(snapshot?.documents)))
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

    static func setUid(_ uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "uid" : uid
        ]) { error in
            completion(error)
        }
    }

    static func setARty(_ arty: ARty, completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).updateData([
            "model" : arty.model,
            "passiveAnimation" : arty.passiveAnimation,
            "pokeAnimation" : arty.pokeAnimation
        ]) { error in
            completion(error)
        }
    }

    static func setPassiveAnimation(to animation: String,
                                    for arty: ARty,
                                    completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).setData([
            "passiveAnimation" : animation,
            "recentPassiveAnimations" : [arty.model: animation]
        ], merge: true) { error in
            completion(error)
        }
    }

    static func setPokeAnimation(to animation: String,
                                 for arty: ARty,
                                 completion: @escaping (Error?) -> Void) {
        usersCollection.document(arty.uid).setData([
            "pokeAnimation" : animation,
            "recentPokeAnimations" : [arty.model: animation]
        ], merge: true) { error in
            completion(error)
        }
    }

    static func updatePokeTimestamp(for uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "pokeTimestamp" : Date()
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
