//
//  Extension+CLLocation.swift
//  ARty
//
//  Created by Quan Vo on 5/26/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

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
