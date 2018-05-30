//
//  ARty+Name.swift
//  ARty
//
//  Created by Quan Vo on 5/28/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

extension ARty {
    enum ModelName: String {
        case elvira
        case mutant

        private static let artFolder = "art.scnassets"

        var asResourcePath: String {
            return ARty.ModelName.artFolder + "/" + rawValue
        }

        init(_ name: String) throws {
            switch name {
            case "elvira":
                self = .elvira
            case "mutant":
                self = .mutant
            default:
                throw ARtyError.invalidModelName(name)
            }
        }
    }
}
