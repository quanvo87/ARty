//
//  Extension+SCNVector3.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

extension SCNVector3 {
    static func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
}
