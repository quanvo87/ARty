//
//  AnimationFactory.swift
//  ARty
//
//  Created by Quan Vo on 5/24/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

struct AnimationFactory {
    static func make(artyName: ARty.Name, animationNames: [AnimationName]) throws -> [String: CAAnimation] {
        var animations = [String: CAAnimation]()
        try animationNames.forEach {
            animations[$0.rawValue] = try make(artyName: artyName, animationName: $0)
        }
        return animations
    }

    static func make(artyName: ARty.Name, animationName: AnimationName) throws -> CAAnimation {
        let resourcePath = ResourcePathFactory.make(artyName: artyName, animationName: animationName)

        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: "dae") else {
            throw ARtyError.resourceNotFound(resourcePath + ".dae")
        }

        let sceneSource = SCNSceneSource(url: url)

        let animationIdentifier = makeIdentifier(
            artyName: artyName,
            animationName: animationName
        )

        guard let animation = sceneSource?.entryWithIdentifier(
            animationIdentifier,
            withClass: CAAnimation.self) else {
                throw ARtyError.animationNotFound(animationIdentifier)
        }

        animation.repeatCount = animationName.repeatCount
        animation.fadeInDuration = 1
        animation.fadeOutDuration = 0.5

        return animation
    }

    static func makeKey(arty: ARty, animationName: AnimationName) -> String {
        return arty.ownerId + "_" + animationName.makeFullName(artyName: arty.artyName)
    }
}

private extension AnimationFactory {
    static func makeIdentifier(artyName: ARty.Name,
                               animationName: AnimationName) -> String {
        return animationName.makeFullName(artyName: artyName) + "-1"
    }
}
