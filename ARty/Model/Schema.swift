import SceneKit

struct Schema {
    let arties: [String: ARtySchema]

    func scale(for model: String) throws -> SCNVector3 {
        let scale = try arty(model).scale
        return SCNVector3(scale, scale, scale)
    }

    func positionAdjustment(for model: String) throws -> SCNVector3 {
        let adjustment = Float(try arty(model).positionAdjustment)
        return SCNVector3(0, adjustment, adjustment)
    }

    func animationNames(for model: String, onlyPickableAnimations: Bool) throws -> [String] {
        var animations = try arty(model).pickableAnimationNames
        if onlyPickableAnimations {
            return animations
        }

        let walkAnimation = try self.walkAnimation(for: model)
        if walkAnimation != "" {
            animations.append(walkAnimation)
        }

        let fallAnimation = try self.fallAnimation(for: model)
        if fallAnimation != "" {
            animations.append(fallAnimation)
        }

        return animations
    }

    func animations(for model: String) throws -> [String: CAAnimation] {
        var animations = [String: CAAnimation]()
        try self.animationNames(for: model, onlyPickableAnimations: false).forEach {
            animations[$0] = try animation(model: model, animation: $0)
        }
        return animations
    }

    func idleScene(for model: String) throws -> SCNScene {
        let idleAnimation = try self.idleAnimation(for: model)
        let resourcePath = model.resourcePath + "/" + idleAnimation
        guard let scene = SCNScene(named: resourcePath) else {
            throw ARtyError.resourceNotFound(resourcePath)
        }
        return scene
    }

    func walkAnimation(for model: String) throws -> String {
        return try arty(model).walkAnimation
    }

    func fallAnimation(for model: String) throws -> String {
        return try arty(model).fallAnimation
    }

    func setPassiveAnimation(for model: String, to animation: String) throws -> String {
        if try isValidAnimation(model: model, animation: animation) {
            return animation
        }
        return try defaultPassiveAnimation(for: model)
    }

    func setPokeAnimation(for model: String, to animation: String) throws -> String {
        if try isValidAnimation(model: model, animation: animation) {
            return animation
        }
        return try defaultPokeAnimation(for: model)
    }

    func defaultPassiveAnimation(for model: String) throws -> String {
        return try arty(model).defaultPassiveAnimation
    }

    func defaultPokeAnimation(for model: String) throws -> String {
        return try arty(model).defaultPokeAnimation
    }
}

private extension Schema {
    func arty(_ model: String) throws -> ARtySchema {
        guard let arty = arties[model] else {
            throw ARtyError.invalidModelName(model)
        }
        return arty
    }

    func animation(model: String, animation: String) throws -> CAAnimation {
        let resourcePath = model.resourcePath + "/" + animation
        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: "dae") else {
            throw ARtyError.resourceNotFound(resourcePath + ".dae")
        }
        let sceneSource = SCNSceneSource(url: url)
        guard let caAnimation = sceneSource?.entryWithIdentifier(
            animation.withAnimationIdentifier,
            withClass: CAAnimation.self) else {
                throw ARtyError.animationIdentifierNotFound(animation.withAnimationIdentifier)
        }
        caAnimation.repeatCount = try animationRepeatCount(model: model, animation: animation)
        caAnimation.fadeInDuration = 1
        caAnimation.fadeOutDuration = 0.5
        return caAnimation
    }

    func animationRepeatCount(model: String, animation: String) throws -> Float {
        if try animation == walkAnimation(for: model) {
            return .infinity
        }
        return try arty(model).animationRepeatCounts[animation] ?? 1
    }

    func idleAnimation(for model: String) throws -> String {
        return try arty(model).idleAnimation
    }

    func isValidAnimation(model: String, animation: String) throws -> Bool {
        let animationNames = try self.animationNames(for: model, onlyPickableAnimations: true)
        return animationNames.contains(animation)
    }
}

private extension String {
    static let artFolder = "art.scnassets"

    var resourcePath: String {
        return String.artFolder + "/" + self
    }

    var withAnimationIdentifier: String {
        return self + "-1"
    }
}
