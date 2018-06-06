import CoreLocation

class LocationManager: CLLocationManager {
    private let startDate = Date()
    var lastLocation = CLLocation()

    override init() {
        super.init()
        desiredAccuracy = kCLLocationAccuracyBest
    }

    func isValidLocation(_ location: CLLocation) -> Bool {
        if location.horizontalAccuracy < 0 {
            return false
        }
        if location.timestamp.timeIntervalSince(lastLocation.timestamp) < 0 {
            return false
        }
        if location.timestamp.timeIntervalSince(startDate) < 0 {
            return false
        }
        return true
    }
}
