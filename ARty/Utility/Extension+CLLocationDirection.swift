//
//  Extension+CLLocationDirection.swift
//  ARty
//
//  Created by Quan Vo on 5/28/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit
import CoreLocation

extension CLLocationDirection {
    var toRadians: CGFloat {
        let adjustment = Float((450 - self).remainder(dividingBy: 360)) + 90
        return CGFloat(GLKMathDegreesToRadians(adjustment))
    }
}
