//
//  ARty.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit
import CoreLocation

class ARty: SCNNode {
    let ownerId: String

    private(set) var modelName: ModelName
    private(set) var yPosition: Float = 0
    private(set) var animations: [String: CAAnimation] = [:]
    private(set) var passiveAnimation: Animation = .none
    private(set) var pokeAnimation: Animation = .none
    private(set) var walkAnimation: Animation = .none

    private var currentAnimation: Animation = .none
    private var lastLocation = CLLocation()

    init(ownerId: String,
         modelName: ModelName,
         passiveAnimation: Animation = .none,
         pokeAnimation: Animation = .none,
         walkAnimation: Animation = .none) throws {
        self.ownerId = ownerId
        self.modelName = modelName

        super.init()
        
        name = ownerId
        try loadModel(modelName)
        setPassiveAnimation(passiveAnimation)
        setPokeAnimation(pokeAnimation)
        setWalkAnimation(walkAnimation)
        playPassiveAnimation()
    }

    func loadModel(_ modelName: ModelName) throws {
        self.modelName = modelName
        try loadIdleScene()
        scale = defaultScale
        yPosition = defaultYPosition
        animations = try makeAnimations()
    }

    func setPassiveAnimation(_ animation: Animation) {
        passiveAnimation = animation == .none ? defaultPassiveAnimation : animation
    }

    func setPokeAnimation(_ animation: Animation) {
        pokeAnimation = animation == .none ? defaultPokeAnimaton : animation
    }

    func setWalkAnimation(_ animation: Animation) {
        walkAnimation = animation == .none ? defaultWalkAnimation : animation
    }

    func playAnimation(_ animation: Animation) throws {
        let caAnimation = try getAnimation(animation)
        addAnimation(caAnimation, forKey: animation.rawValue)
        caAnimation.delegate = self
        currentAnimation = animation
    }

    func stopAnimation(_ animation: Animation) throws {
        removeAnimation(forKey: animation.rawValue, blendOutDuration: 0.5)
        currentAnimation = .none
    }

    func playWalkAnimation(location: CLLocation) throws {
        let speed = location.speed
        if speed > 0 {
            if speed < 0.5 {
                try stopAnimation(walkAnimation)
            } else if currentAnimation == .none {
                try playAnimation(walkAnimation)
            }
        } else {
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if currentAnimation == .none {
                    try playAnimation(walkAnimation)
                }
                lastLocation = location
            } else {
                try stopAnimation(walkAnimation)
            }
        }
    }

    func turn(location: CLLocation) {
        guard currentAnimation.isWalk, location.course > -1 else {
            return
        }
        let rotateAction = SCNAction.rotateTo(
            x: 0,
            y: location.course.toRadians,
            z: 0,
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(rotateAction)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ARty {
    func loadIdleScene() throws {
        childNodes.forEach {
            $0.removeFromParentNode()
        }
        let resourcePath = modelName.asResourcePath + "/" + defaultIdleAnimation.rawValue
        guard let scene = SCNScene(named: resourcePath) else {
            throw ARtyError.resourceNotFound(resourcePath)
        }
        scene.rootNode.childNodes.forEach {
            addChildNode($0)
        }
    }

    func getAnimation(_ animation: Animation) throws -> CAAnimation {
        guard let caAnimation = animations[animation.rawValue] else {
            throw ARtyError.invalidAnimationName(animation.rawValue)
        }
        return caAnimation
    }

    func playPassiveAnimation() {
        let random = Double(arc4random_uniform(10) + 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + random) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.currentAnimation == .none {
                try? self.playAnimation(self.passiveAnimation)
            }
            self.playPassiveAnimation()
        }
    }
}

extension ARty: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if currentAnimation.isWalk {
            // todo: turn arty to camera
        }
        currentAnimation = .none
    }
}
