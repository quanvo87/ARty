import SceneKit

struct Schema {
    let arties: [String: ARtySchema]
    private let animationCache = NSCache<NSString, CAAnimation>()

    func emotes(for model: String) throws -> [String] {
        return try arty(model).emotes
    }

    func animations(for model: String) throws -> [String: CAAnimation] {
        var animations = [String: CAAnimation]()
        try animationNames(for: model).forEach {
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

    func setPassiveEmote(for model: String, to emote: String) throws -> String {
        return try isValidEmote(model: model, emote: emote) ?
            emote :
            defaultPassiveEmote(for: model)
    }

    func setPokeEmote(for model: String, to emote: String) throws -> String {
        return try isValidEmote(model: model, emote: emote) ?
            emote :
            defaultPokeEmote(for: model)
    }

    func defaultPassiveEmote(for model: String) throws -> String {
        return try arty(model).defaultPassiveEmote
    }

    func defaultPokeEmote(for model: String) throws -> String {
        return try arty(model).defaultPokeEmote
    }
}

private extension Schema {
    func arty(_ model: String) throws -> ARtySchema {
        guard let arty = arties[model] else {
            throw ARtyError.invalidModelName(model)
        }
        return arty
    }

    func animationNames(for model: String) throws -> [String] {
        var names = try emotes(for: model)
        names.append(try walkAnimation(for: model))
        return names
    }

    func animation(model: String, animation: String) throws -> CAAnimation {
        if let caAnimation = animationCache.object(forKey: animation as NSString) {
            return caAnimation
        }
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
        animationCache.setObject(caAnimation, forKey: animation as NSString)
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

    func isValidEmote(model: String, emote: String) throws -> Bool {
        let emotes = try self.emotes(for: model)
        return emotes.contains(emote)
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
