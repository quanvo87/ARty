import FirebaseAuth

protocol AuthManagerDelegate: class {
    func authManager(_ manager: AuthManager, userLoggedIn uid: String)
    func authManagerUserLoggedOut(_ manager: AuthManager)
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
            guard let `self` = self else {
                return
            }
            if let uid = user?.uid {
                self.delegate?.authManager(self, userLoggedIn: uid)
            } else {
                self.delegate?.authManagerUserLoggedOut(self)
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
