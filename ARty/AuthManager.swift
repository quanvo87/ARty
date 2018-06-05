import FirebaseAuth

protocol AuthManagerDelegate: class {
    func userLoggedIn(_ uid: String)
    func userLoggedOut()
}

class AuthManager {
    private static let auth = Auth.auth()
    private var handle: AuthStateDidChangeListenerHandle?
    private weak var delegate: AuthManagerDelegate?

    init(delegate: AuthManagerDelegate) {
        self.delegate = delegate
    }

    func listenForAuthState() {
        stopListening()
        handle = AuthManager.auth.addStateDidChangeListener { [weak self] _, user in
            if let uid = user?.uid {
                self?.delegate?.userLoggedIn(uid)
            } else {
                self?.delegate?.userLoggedOut()
            }
        }
    }

    func logout() {
        try? AuthManager.auth.signOut()
    }

    private func stopListening() {
        if let handle = handle {
            AuthManager.auth.removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopListening()
    }
}
