//
//  ResourcePathFactory.swift
//  ARty
//
//  Created by Quan Vo on 5/24/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

struct ResourcePathFactory {
    private static let artFolder = "art.scnassets"

    static func make(artyName: ARty.Name, animationName: AnimationName) -> String {
        return artFolder + "/" +
            artyName.rawValue + "/" +
            animationName.makeFullName(artyName: artyName)
    }
}
