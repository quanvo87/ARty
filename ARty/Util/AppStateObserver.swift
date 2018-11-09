import UIKit

protocol AppStateObserverDelegate: class {
    func appStateObserverAppDidBecomeActive(_ observer: AppStateObserver)
    func appStateObserverAppDidEnterBackground(_ observer: AppStateObserver)
}

class AppStateObserver {
    var appIsActive = true
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    private var appDidEnterBackgroundObserver: NSObjectProtocol?
    private weak var delegate: AppStateObserverDelegate?

    init(delegate: AppStateObserverDelegate) {
        self.delegate = delegate
    }

    func start() {
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.appIsActive = true
                self.delegate?.appStateObserverAppDidBecomeActive(self)
        }

        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.appIsActive = false
                self.delegate?.appStateObserverAppDidEnterBackground(self)
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
