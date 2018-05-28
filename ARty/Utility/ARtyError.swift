//
//  ARtyError.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

enum ARtyError: LocalizedError {
    case animationIdentifierNotFound(String)
    case invalidAnimationName(String)
    case invalidModelName(String)
    case resourceNotFound(String)

    var localizedDescription: String {
        switch self {
        case .animationIdentifierNotFound(let identifier):
            return "animation identifier not found: " + identifier
        case .invalidAnimationName(let animationName):
            return "invalid animation name: " + animationName
        case .invalidModelName(let artyName):
            return "invalid model name: " + artyName
        case .resourceNotFound(let path):
            return "could not find resource at path: " + path
        }
    }

    init() {
        self.init()
        print(localizedDescription)
    }
}
