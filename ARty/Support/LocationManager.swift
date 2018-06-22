import CoreLocation

class LocationManager: CLLocationManager {
    var lastLocation: CLLocation?
    private let startDate = Date()

    init(delegate: CLLocationManagerDelegate) {
        super.init()
        self.delegate = delegate
        desiredAccuracy = kCLLocationAccuracyBest
        allowsBackgroundLocationUpdates = true
        pausesLocationUpdatesAutomatically = false
    }

    func isValidLocation(_ location: CLLocation) -> Bool {
        if location.timestamp.timeIntervalSince(startDate) < 0 {
            return false
        }
        if location.horizontalAccuracy < 0 {
            return false
        }
        if let lastLocation = lastLocation {
            return location.timestamp.timeIntervalSince(lastLocation.timestamp) < 0 ? false : true
        } else {
            return true
        }
    }

    func setLocationInDatabase(uid: String) {
        guard let lastLocation = lastLocation else {
            return
        }
        Database.setLocation(lastLocation, for: uid) { error in
            if let error = error {
                print(error)
            }
        }
    }
}
