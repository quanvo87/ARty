//
//  ARty+scale.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

extension ARty {
    var defaultScale: SCNVector3 {
        var scale: Float
        switch modelName {
        case .elvira:
            scale = 0.075
        case .mutant:
            scale = 0.06
        }
        return SCNVector3(scale, scale, scale)
    }
}
