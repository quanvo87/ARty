//
//  ARty.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

enum AnimationName: String {
    case dance_twerk
    case idle
    case taunt_buttslap
    case walk_badbitch
    case wave

    var repeatCount: Float {
        switch self {
        case .walk_badbitch:
            return .infinity
        case .wave:
            return 4
        default:
            return 1
        }
    }

    init(_ name: String) throws {
        switch name {
        case "dance_twerk":
            self = .dance_twerk
        case "idle":
            self = .idle
        case "taunt_buttslap":
            self = .taunt_buttslap
        case "walk_badbitch":
            self = .walk_badbitch
        case "wave":
            self = .wave
        default:
            throw ARtyError.invalidAnimationName(name)
        }
    }

    func makeFullName(artyName: ARty.Name) -> String {
        return artyName.rawValue + "_" + rawValue
    }
}
