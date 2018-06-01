import FirebaseAuth

class AuthListener {
    private static let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?

    func listen(completion: @escaping (FirebaseAuth.User?) -> Void) {
        stopListening()
        handle = AuthListener.auth.addStateDidChangeListener { (_, user) in
            completion(user)
        }
    }

    private func stopListening() {
        if let handle = handle {
            AuthListener.auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopListening()
    }
}
