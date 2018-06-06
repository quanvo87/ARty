import UIKit

// todo
protocol AppStateObserverDelegate: class {
    func appDidBecomeActive()
    func appDidEnterBackground()
}

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
