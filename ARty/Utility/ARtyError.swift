//
//  ARtyError.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

enum ARtyError: LocalizedError {
    case animationNotFound(String)
    case animationNotSupported(ARty, AnimationName)
    case invalidAnimationName(String)
    case invalidARtyName(String)
    case resourceNotFound(String)

    var localizedDescription: String {
        switch self {
        case .animationNotFound(let identifier):
            return "animation not found with identifier: " + identifier
        case .animationNotSupported(let arty, let animationName):
            return "arty " + arty.artyName.rawValue + " doesn't support animation " + animationName.rawValue
        case .invalidAnimationName(let animationName):
            return "invalid animation name: " + animationName
        case .invalidARtyName(let artyName):
            return "invalid ARty name: " + artyName
        case .resourceNotFound(let path):
            return "could not find resource at path: " + path
        }
    }

    init() {
        self.init()
        print(localizedDescription)
    }
}
