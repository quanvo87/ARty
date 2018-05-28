//
//  Animation.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

enum Animation: String {
    case elvira_dance_twerk
    case elvira_idle_0
    case elvira_taunt_buttslap
    case elvira_walk_0
    case elvira_wave_0

    case none
    
    var identifier: String {
        return rawValue + "-1"
    }
    
    var repeatCount: Float {
        switch self {
        case .elvira_walk_0:
            return .infinity
        case .elvira_wave_0:
            return 4
        default:
            return 1
        }
    }

    var isWalk: Bool {
        switch self {
        case .elvira_walk_0:
            return true
        default:
            return false
        }
    }

    init(_ name: String) throws {
        switch name {
        case "elvira_dance_twerk":
            self = .elvira_dance_twerk
        case "elvira_idle_0":
            self = .elvira_idle_0
        case "elvira_taunt_buttslap":
            self = .elvira_taunt_buttslap
        case "elvira_walk_0":
            self = .elvira_walk_0
        case "elvira_wave_0":
            self = .elvira_wave_0
        default:
            throw ARtyError.invalidAnimationName(name)
        }
    }
}
