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
    let artyName: Name
    let yPosition: Float
    let animations: [String: CAAnimation]

    var passiveAnimation: AnimationName
    var pokeAnimation: AnimationName
    var walkAnimation: AnimationName

    var xPosition: Float = 0

    private var state: State = .idle

    private var lastLocation = CLLocation()

    init(ownerId: String,
         name: ARty.Name,
         scale: Float = 1,
         yPosition: Float = 0,
         animationNames: [AnimationName],
         passiveAnimation: AnimationName,
         pokeAnimation: AnimationName,
         walkAnimation: AnimationName) throws {
        self.ownerId = ownerId
        self.artyName = name
        self.yPosition = yPosition
        self.animations = try AnimationFactory.make(artyName: name, animationNames: animationNames)
        self.passiveAnimation = passiveAnimation
        self.pokeAnimation = pokeAnimation
        self.walkAnimation = walkAnimation

        super.init()

        self.name = ownerId

        let idleScene = try SceneFactory.makeIdleScene(artyName: name)

        idleScene.rootNode.childNodes.forEach {
            addChildNode($0)
        }

        self.scale = SCNVector3(scale, scale, scale)

        playPassiveAnimation()
    }

    func setPosition(x: Float, z: Float) {
        position = SCNVector3(x, yPosition, z)
    }

    func playPokeAnimation() throws {
        try playAnimation(named: pokeAnimation)
    }

    func playWalkAnimation(location: CLLocation) throws {
        let speed = location.speed
        if speed > 0 {
            if speed < 0.5 {
                stopAnimation(named: walkAnimation)
            } else if state == .idle {
                try playAnimation(named: walkAnimation, walkAnimation: true)
            }
        } else {
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                try playAnimation(named: walkAnimation, walkAnimation: true)
                lastLocation = location
            } else {
                stopAnimation(named: walkAnimation)
            }
        }
    }

    func turn(location: CLLocation) {
        guard state == .walking, location.course > -1 else {
            return
        }
        let course = Float((450 - location.course).remainder(dividingBy: 360)) + 90
        let radians = CGFloat(GLKMathDegreesToRadians(course))
        let rotateAction = SCNAction.rotateTo(x: 0, y: radians, z: 0, duration: 1, usesShortestUnitArc: true)
        runAction(rotateAction)
    }

    func playAnimation(named name: String) throws {
        let animationName = try AnimationName(name)
        try playAnimation(named: animationName)
    }

    func playAnimation(named name: AnimationName, walkAnimation: Bool = false) throws {
        let animation = try getAnimation(named: name)
        let key = AnimationFactory.makeKey(arty: self, animationName: name)
        parent?.childNode(withName: ownerId, recursively: false)?.addAnimation(animation, forKey: key)
        state = walkAnimation ? .walking : .emoting
        animation.delegate = self
    }

    func stopAnimation(named name: String) throws {
        let animationName = try AnimationName(name)
        stopAnimation(named: animationName)
    }

    func stopAnimation(named name: AnimationName) {
        let key = AnimationFactory.makeKey(arty: self, animationName: name)
        parent?.childNode(withName: ownerId, recursively: false)?.removeAnimation(
            forKey: key,
            blendOutDuration: 0.5
        )
        state = .idle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ARty {
    func getAnimation(named name: AnimationName) throws -> CAAnimation {
        guard let animation = animations[name.rawValue] else {
            throw ARtyError.animationNotSupported(self, name)
        }
        return animation
    }

    func playPassiveAnimation() {
        let random = Double(arc4random_uniform(10) + 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + random) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.state == .idle {
                try? self.playAnimation(named: self.passiveAnimation)
            }
            self.playPassiveAnimation()
        }
    }
}

extension ARty: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if state == .walking {
            // todo: turn arty back to face camera/user
        }
        state = .idle
    }
}

extension ARty {
    enum State {
        case idle
        case walking
        case emoting
    }
}

extension ARty {
    enum Name: String {
        case elvira
        
        init(name: String) throws {
            switch name {
            case "elvira":
                self = .elvira
            default:
                throw ARtyError.invalidARtyName(name)
            }
        }
    }
}
