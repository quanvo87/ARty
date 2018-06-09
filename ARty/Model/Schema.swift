import SceneKit

struct Schema {
    let arties: [String: ARtySchema]
    let animationRepeatCounts: [String: Float]  // todo: move to ARtySchema

    func scale(_ model: String) throws -> SCNVector3 {
        let scale = try arty(model).scale
        return SCNVector3(scale, scale, scale)
    }

    func positionAdjustment(_ model: String) throws -> SCNVector3 {
        let adjustment = Float(try arty(model).positionAdjustment)
        return SCNVector3(0, adjustment, adjustment)
    }

    func animationNames(_ model: String, onlyPickableAnimations: Bool) throws -> [String] {
        var animations = try arty(model).pickableAnimationNames
        if onlyPickableAnimations {
            return animations
        }

        let walkAnimation = try self.walkAnimation(model)
        if walkAnimation != "" {
            animations.append(walkAnimation)
        }

        let fallAnimation = try self.fallAnimation(model)
        if fallAnimation != "" {
            animations.append(fallAnimation)
        }

        return animations
    }

    func animations(_ model: String) throws -> [String: CAAnimation] {
        var animations = [String: CAAnimation]()
        try self.animationNames(model, onlyPickableAnimations: false).forEach {
            animations[$0] = try animation(model, animation: $0)
        }
        return animations
    }

    func idleScene(_ model: String) throws -> SCNScene {
        let idleAnimation = try self.idleAnimation(model)
        let resourcePath = model.asResourcePath + "/" + idleAnimation
        guard let scene = SCNScene(named: resourcePath) else {
            throw ARtyError.resourceNotFound(resourcePath)
        }
        return scene
    }

    func walkAnimation(_ model: String) throws -> String {
        return try arty(model).walkAnimation
    }

    func fallAnimation(_ model: String) throws -> String {
        return try arty(model).fallAnimation
    }

    func setPassiveAnimation(_ model: String, animation: String) throws -> String {
        if try isValidAnimation(model, animation: animation) {
            return animation
        }
        return try defaultPassiveAnimation(model)
    }

    func setPokeAnimation(_ model: String, animation: String) throws -> String {
        if try isValidAnimation(model, animation: animation) {
            return animation
        }
        return try defaultPokeAnimation(model)
    }
}

private extension Schema {
    func arty(_ model: String) throws -> ARtySchema {
        guard let arty = arties[model] else {
            throw ARtyError.invalidModelName(model)
        }
        return arty
    }

    func animation(_ model: String, animation: String) throws -> CAAnimation {
        let resourcePath = model.asResourcePath + "/" + animation
        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: "dae") else {
            throw ARtyError.resourceNotFound(resourcePath + ".dae")
        }
        let sceneSource = SCNSceneSource(url: url)
        guard let caAnimation = sceneSource?.entryWithIdentifier(
            animation.withAnimationIdentifier,
            withClass: CAAnimation.self) else {
                throw ARtyError.animationIdentifierNotFound(animation.withAnimationIdentifier)
        }
        caAnimation.repeatCount = try animationRepeatCount(model, animation: animation)
        caAnimation.fadeInDuration = 1
        caAnimation.fadeOutDuration = 0.5
        return caAnimation
    }

    func animationRepeatCount(_ model: String, animation: String) throws -> Float {
        if try walkAnimation(model) == animation {
            return .infinity
        }
        return schema.animationRepeatCounts[animation] ?? 1
    }

    func idleAnimation(_ model: String) throws -> String {
        return try arty(model).idleAnimation
    }

    func isValidAnimation(_ model: String, animation: String) throws -> Bool {
        let animations = try self.animationNames(model, onlyPickableAnimations: true)
        return animations.contains(animation)
    }

    func defaultPassiveAnimation(_ model: String) throws -> String {
        return try arty(model).defaultPassiveAnimation
    }

    func defaultPokeAnimation(_ model: String) throws -> String {
        return try arty(model).defaultPokeAnimation
    }
}

private extension String {
    static let artFolder = "art.scnassets"

    var asResourcePath: String {
        return String.artFolder + "/" + self
    }

    var withAnimationIdentifier: String {
        return self + "-1"
    }
}
