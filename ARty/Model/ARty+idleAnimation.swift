//
//  ARty+idleAnimation.swift
//  ARty
//
//  Created by Quan Vo on 5/28/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

extension ARty {
    var defaultIdleAnimation: Animation {
        switch modelName {
        case .elvira:
            return .elvira_idle_0
        case .mutant:
            return .mutant_idle_0
        }
    }
}
