import SceneKit

struct Schema {
    let arties: [String: ARtySchema]
    let animationRepeatCounts: [String: Float]
    let walkAnimations: [String]
    let fallAnimations: [String]

    // init from json/file path

    func scale(_ model: String) throws -> SCNVector3 {
        let scale = try arty(model).scale
        return SCNVector3(scale, scale, scale)
    }

    func positionAdjustment(_ model: String) throws -> SCNVector3 {
        let adjustment = Float(try arty(model).positionAdjustment)
        return SCNVector3(0, adjustment, adjustment)
    }

    func animations(_ model: String) throws -> [String: CAAnimation] {
        var animations = [String: CAAnimation]()
        try self.animationNames(model).forEach {
            animations[$0] = try Schema.animation(model, animation: $0)
        }
        return animations
    }

    func pickableAnimations(_ model: String) throws -> [String] {
        return try animationNames(model).filter {
            return !$0.isWalkAnimation && !$0.isFallAnimation
        }
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

    func passiveAnimation(_ model: String, animation: String) throws -> String {
        if try isValidAnimation(model, animation: animation) {
            return animation
        }
        return try defaultPassiveAnimation(model)
    }

    func pokeAnimation(_ model: String, animation: String) throws -> String {
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

    func animationNames(_ model: String) throws -> [String] {
        return try arty(model).animations
    }

    func isValidAnimation(_ model: String, animation: String) throws -> Bool {
        let animations = try self.animationNames(model)
        return animations.contains(animation)
    }

    static func animation(_ model: String, animation: String) throws -> CAAnimation {
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
        caAnimation.repeatCount = animation.animationRepeatCount
        caAnimation.fadeInDuration = 1
        caAnimation.fadeOutDuration = 0.5
        return caAnimation
    }

    func idleAnimation(_ model: String) throws -> String {
        return try arty(model).idleAnimation
    }

    func defaultPassiveAnimation(_ model: String) throws -> String {
        return try arty(model).passiveAnimation
    }

    func defaultPokeAnimation(_ model: String) throws -> String {
        return try arty(model).pokeAnimation
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

    var animationRepeatCount: Float {
        if isWalkAnimation {
            return .infinity
        }
        return schema.animationRepeatCounts[self] ?? 1
    }
}
