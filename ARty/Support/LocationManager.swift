import CoreLocation

class LocationManager: CLLocationManager {
    private let startDate = Date()
    private var lastLocation: CLLocation?

    init(delegate: CLLocationManagerDelegate) {
        super.init()
        self.delegate = delegate
        desiredAccuracy = kCLLocationAccuracyBest
    }

    func isValidLocation(_ location: CLLocation) -> Bool {
        if location.timestamp.timeIntervalSince(startDate) < 0 {
            return false
        }
        if location.horizontalAccuracy < 0 {
            return false
        }
        if let lastLocation = lastLocation {
            if location.timestamp.timeIntervalSince(lastLocation.timestamp) < 0 {
                return false
            } else {
                self.lastLocation = location
                return true
            }
        } else {
            lastLocation = location
            return true
        }
    }
}
