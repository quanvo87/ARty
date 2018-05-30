//
//  ARty+pokeAnimations.swift
//  ARty
//
//  Created by Quan Vo on 5/28/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

extension ARty {
    var defaultPokeAnimaton: Animation {
        switch modelName {
        case .elvira:
            return .elvira_taunt_buttslap
        case .mutant:
            return .mutant_taunt_battlecry
        }
    }
}
