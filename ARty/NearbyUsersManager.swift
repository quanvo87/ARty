import Foundation

protocol NearbyUsersManagerDelegate: class {
    func processUser(_ user: User)
    func removeStaleUsers(_ user: [User])
}

class NearbyUsersManager {
    private var isPolling = false
    private weak var delegate: NearbyUsersManagerDelegate?

    init(delegate: NearbyUsersManagerDelegate) {
        self.delegate = delegate
    }

    // add location when rdy
    func startPollingNearbyUsers(uid: String, rate: TimeInterval = 5) {
        nearbyUsers(uid: uid, rate: rate)
        isPolling = true
    }

    func stopPollingNearbyUsers() {
        isPolling = false
    }

    private func nearbyUsers(uid: String, rate: TimeInterval) {
        Database.nearbyUsers(uid: uid) { [weak self] result in
            switch result {
            case .fail(let error):
                print(error)
            case .success(let users):
                users.forEach {
                    self?.delegate?.processUser($0)
                }
                self?.delegate?.removeStaleUsers(users)
            }
            // do it again if app in foreground
            // when app returns to foreground, restart process if appropriate
        }
    }
}
