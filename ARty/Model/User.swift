import FirebaseFirestore

struct User {
    let uid: String
    let model: String
    let passiveAnimations: [String: String]
    let pokeAnimations: [String: String]
    let pokeTimestamp: Date

    init(_ snapshot: DocumentSnapshot?) throws {
        guard let unwrappedSnapshot = snapshot,
            let data = unwrappedSnapshot.data(),
            let uid = data["uid"] as? String else {
                throw ARtyError.invalidDataFromServer(snapshot?.data())
        }
        self.uid = uid
        model = data["model"] as? String ?? ""
        passiveAnimations = data["passiveAnimations"] as? [String: String] ?? [:]
        pokeAnimations = data["pokeAnimations"] as? [String: String] ?? [:]
        pokeTimestamp = (data["pokeTimestamp"] as? Timestamp)?.dateValue() ?? Date()
    }

    func passiveAnimation(for model: String) throws -> String {
        return try passiveAnimations[model] ?? schema.defaultPassiveAnimation(for: model)
    }

    func pokeAnimation(for model: String) throws -> String {
        return try pokeAnimations[model] ?? schema.defaultPokeAnimation(for: model)
    }
}
