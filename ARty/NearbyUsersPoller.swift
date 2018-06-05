import Foundation

protocol NearbyUsersPollerDelegate: class {
    func processUser(_ user: User)
    func removeStaleUsers(_ user: [User])
}

class NearbyUsersPoller {
    private let timeInterval: TimeInterval
    private var shouldPoll = false
    private var timer: Timer?
    private lazy var appStateObserver = AppStateObserver(delegate: self)
    private weak var delegate: NearbyUsersPollerDelegate?

    init(timeInterval: TimeInterval = 5, delegate: NearbyUsersPollerDelegate) {
        self.timeInterval = timeInterval
        self.delegate = delegate
        appStateObserver.load()
    }

    var coordinates: (latitude: Double, longitude: Double)? {
        didSet {
            if shouldPoll {
                poll()
            }
        }
    }

    func poll() {
        shouldPoll = true
        guard coordinates != nil, timer == nil else {
            return
        }
        timer = .init(timeInterval: timeInterval, repeats: true) { [weak self] _ in
            guard let coordinates = self?.coordinates else {
                return
            }
            Database.nearbyUsers(latitude: coordinates.latitude, longitude: coordinates.longitude) { result in
                switch result {
                case .fail(let error):
                    print(error)
                case .success(let users):
                    users.forEach {
                        self?.delegate?.processUser($0)
                    }
                    self?.delegate?.removeStaleUsers(users)
                }
            }
        }
    }

    func stop() {
        shouldPoll = false
        stopTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension NearbyUsersPoller: AppStateObserverDelegate {
    func appDidBecomeActive() {
        if shouldPoll {
            poll()
        }
    }

    func appDidEnterBackground() {
        stopTimer()
    }
}
