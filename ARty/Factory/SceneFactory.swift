//
//  SceneFactory.swift
//  ARty
//
//  Created by Quan Vo on 5/24/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

struct SceneFactory {
    static func makeIdleScene(artyName: ARty.Name) throws -> SCNScene {
        let resourcePath = ResourcePathFactory.make(artyName: artyName, animationName: .idle)

        guard let scene = SCNScene(named: resourcePath + ".dae") else {
            throw ARtyError.resourceNotFound(resourcePath)
        }

        return scene
    }
}
