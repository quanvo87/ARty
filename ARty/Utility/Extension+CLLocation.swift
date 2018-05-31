import CoreLocation

extension CLLocation {
    func isValid(oldLocation: CLLocation, startDate: Date) -> Bool {
        if horizontalAccuracy < 0 {
            return false
        }
        if timestamp.timeIntervalSince(oldLocation.timestamp) < 0 {
            return false
        }
        if timestamp.timeIntervalSince(startDate) < 0 {
            return false
        }
        return true
    }
}
