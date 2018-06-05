import UIKit

protocol AppStateObserverDelegate: class {
    func appDidBecomeActive()
    func appDidEnterBackground()
}

// todo: instead of delegate, make this send notifications, since multiple classes need this info
class AppStateObserver {
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var appDidEnterBackgroundObserver: NSObjectProtocol?
    private weak var delegate: AppStateObserverDelegate?

    init(delegate: AppStateObserverDelegate) {
        self.delegate = delegate

        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.delegate?.appDidBecomeActive()
        }

        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidEnterBackground,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.delegate?.appDidEnterBackground()
        }
    }

    func load() {}

    deinit {
        if let appDidBecomeActiveObserver = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
        }
        if let appDidEnterBackgroundObserver = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(appDidEnterBackgroundObserver)
        }
    }
}
