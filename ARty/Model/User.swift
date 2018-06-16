import FirebaseFirestore

struct User {
    let uid: String
    let model: String
    let passiveEmotes: [String: String]
    let pokeEmotes: [String: String]
    let pokeTimestamp: Date

    init(_ snapshot: DocumentSnapshot?) throws {
        guard let unwrappedSnapshot = snapshot,
            let data = unwrappedSnapshot.data(),
            let uid = data["uid"] as? String else {
                throw ARtyError.invalidDataFromServer(snapshot?.data())
        }
        self.uid = uid
        model = data["model"] as? String ?? ""
        passiveEmotes = data["passiveEmotes"] as? [String: String] ?? [:]
        pokeEmotes = data["pokeEmotes"] as? [String: String] ?? [:]
        pokeTimestamp = (data["pokeTimestamp"] as? Timestamp)?.dateValue() ?? Date()
    }

    func passiveEmote(for model: String) throws -> String {
        return try passiveEmotes[model] ?? schema.defaultPassiveEmote(for: model)
    }

    func pokeEmote(for model: String) throws -> String {
        return try pokeEmotes[model] ?? schema.defaultPokeEmote(for: model)
    }
}
