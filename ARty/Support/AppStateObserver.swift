import UIKit

protocol AppStateObserverDelegate: class {
    func appStateObserverAppBecameActive(_ observer: AppStateObserver)
    func appStateObserverAppEnteredBackground(_ observer: AppStateObserver)
}

class AppStateObserver {
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var appDidEnterBackgroundObserver: NSObjectProtocol?
    private weak var delegate: AppStateObserverDelegate?

    init(delegate: AppStateObserverDelegate) {
        self.delegate = delegate
    }

    func start() {
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.delegate?.appStateObserverAppBecameActive(self)
        }

        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidEnterBackground,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.delegate?.appStateObserverAppEnteredBackground(self)
        }
    }

    func stop() {
        if let appDidBecomeActiveObserver = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appDidBecomeActiveObserver)
        }
        if let appDidEnterBackgroundObserver = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(appDidEnterBackgroundObserver)
        }
    }

    deinit {
        stop()
    }
}