//
//  ARty+passiveAnimations.swift
//  ARty
//
//  Created by Quan Vo on 5/28/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

extension ARty {
    var defaultPassiveAnimation: Animation {
        switch modelName {
        case .elvira:
            return .elvira_wave_0
        case .mutant:
            return .mutant_chestthump
        }
    }
}
