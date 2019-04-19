import FirebaseFirestore
import CoreLocation

struct Database {
    private static let database = Firestore.firestore()

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

    static func setLocation(_ location: CLLocation, for uid: String, completion: @escaping (Error?) -> Void) {
        database.collection("locations").document(uid).setData(location.dictionary) { error in
            if let error = error {
                completion(error)
                return
            }
            LocationDatabase.setLocation(
                uid: uid,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude) { error in
                    completion(error)
            }
        }
    }

    static func setStatus(_ status: String, for uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData([
            "status": status
        ]) { error in
            completion(error)
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

    static func locationListener(uid: String, callback: @escaping (CLLocation) -> Void) -> ListenerRegistration {
        return database.collection("locations").document(uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            do {
                callback(try .init(snapshot))
            } catch {
                print(error)
            }
        }
    }

    static func updateModel(myARty: MyARty, completion: @escaping (Error?) -> Void) {
        usersCollection.document(myARty.uid).updateData([
            "model": myARty.model
        ]) { error in
            completion(error)
        }
    }

    static func updatePassiveEmote(to emote: String,
                                   for myARty: MyARty,
                                   completion: @escaping (Error?) -> Void) {
        usersCollection.document(myARty.uid).updateData([
            "passiveEmotes.\(myARty.model)": emote
        ]) { error in
            completion(error)
        }
    }

    static func updatePokeEmote(to emote: String,
                                for myARty: MyARty,
                                completion: @escaping (Error?) -> Void) {
        usersCollection.document(myARty.uid).updateData([
            "pokeEmotes.\(myARty.model)": emote
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
