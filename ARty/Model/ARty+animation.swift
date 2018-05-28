//
//  ARty+animations.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

extension ARty {
    func makeAnimations() throws -> [String: CAAnimation] {
        var animationsDictionary = [String: CAAnimation]()
        try animationNames.forEach {
            animationsDictionary[$0.rawValue] = try makeAnimation($0)
        }
        return animationsDictionary
    }
}

private extension ARty {
    func makeAnimation(_ animation: Animation) throws -> CAAnimation {
        let resourcePath = modelName.asResourcePath + "/" + animation.rawValue
        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: "dae") else {
            throw ARtyError.resourceNotFound(resourcePath + ".dae")
        }
        let sceneSource = SCNSceneSource(url: url)
        guard let caAnimation = sceneSource?.entryWithIdentifier(
            animation.identifier,
            withClass: CAAnimation.self) else {
                throw ARtyError.animationIdentifierNotFound(animation.identifier)
        }
        caAnimation.repeatCount = animation.repeatCount
        caAnimation.fadeInDuration = 1
        caAnimation.fadeOutDuration = 0.5
        return caAnimation
    }

    var animationNames: [Animation] {
        switch modelName {
        case .elvira:
            return [
                .elvira_dance_twerk,
                .elvira_taunt_buttslap,
                .elvira_walk_0,
                .elvira_wave_0
            ]
        }
    }
}
