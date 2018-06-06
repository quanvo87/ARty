import UIKit

protocol AppStateObserverDelegate: class {
    func appStateObserverAppDidBecomeActive(_ observer: AppStateObserver)
    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver)
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
                guard let `self` = self else {
                    return
                }
                self.delegate?.appStateObserverAppDidBecomeActive(self)
        }

        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidEnterBackground,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.delegate?.appStateObserverAppDidEnterBackground(self)
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
