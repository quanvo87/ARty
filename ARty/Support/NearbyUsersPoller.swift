import Foundation

protocol NearbyUsersPollerDelegate: class {
    func nearbyUsersPoller(_ poller: NearbyUsersPoller, observeUser user: User)
    func nearbyUsersPoller(_ poller: NearbyUsersPoller, removeStaleUsers users: [User])
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
        timer = .scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            guard let coordinates = self?.coordinates else {
                return
            }
            Database.nearbyUsers(latitude: coordinates.latitude, longitude: coordinates.longitude) { result in
                guard let `self` = self else {
                    return
                }
                switch result {
                case .fail(let error):
                    print(error)
                case .success(let users):
                    users.forEach {
                        self.delegate?.nearbyUsersPoller(self, observeUser: $0)
                    }
                    self.delegate?.nearbyUsersPoller(self, removeStaleUsers: users)
                }
            }
        }
        timer?.fire()
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
    func appStateObserverAppBecameActive(_ observer: AppStateObserver) {
        if shouldPoll {
            poll()
        }
    }

    func appStateObserverAppEnteredBackground(_ observer: AppStateObserver) {
        stopTimer()
    }
}
