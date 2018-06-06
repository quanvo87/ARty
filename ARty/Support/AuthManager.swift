import FirebaseAuth

protocol AuthManagerDelegate: class {
    func authManager(_ manager: AuthManager, userLoggedIn uid: String)
    func authManagerUserLoggedOut(_ manager: AuthManager)
}

class AuthManager {
    private var handle: AuthStateDidChangeListenerHandle?
    private weak var delegate: AuthManagerDelegate?

    init(delegate: AuthManagerDelegate) {
        self.delegate = delegate
    }

    func listenForAuthState() {
        stopListening()
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
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
        try? Auth.auth().signOut()
    }

    private func stopListening() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    deinit {
        stopListening()
    }
}
