//
//  ARty+animations.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

extension ARty {
    var animationNames: [Animation] {
        switch modelName {
        case .elvira:
            return [
                .elvira_dance_twerk,
                .elvira_taunt_buttslap,
                .elvira_walk_0,
                .elvira_wave_0
            ]
        }
    }
}
