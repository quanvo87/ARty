import SceneKit
import CoreLocation

class ARty: SCNNode {
    let ownerId: String
    let model: String
    let positionAdjustment: Float
    let animations: [String: CAAnimation]

    private(set) var passiveAnimation = ""
    private(set) var pokeAnimation = ""

    private let walkAnimation: String

    private var currentAnimation = ""
    private var lastLocation = CLLocation()

    weak var label: UILabel?

    init(ownerId: String,
         model: String,
         passiveAnimation: String = "",
         pokeAnimation: String = "") throws {
        self.ownerId = ownerId
        self.model = model
        positionAdjustment = try schema.positionAdjustment(model)
        animations = try schema.animations(model)
        walkAnimation = try schema.walkAnimation(model)

        super.init()

        name = ownerId
        scale = try schema.scale(model)
        try loadIdleScene()
        try setPassiveAnimation(passiveAnimation)
        try setPokeAnimation(pokeAnimation)
        loopPassiveAnimation()
    }

    func setPassiveAnimation(_ animation: String) throws {
        passiveAnimation = try schema.passiveAnimation(model, animation: animation)
    }

    func setPokeAnimation(_ animation: String) throws {
        pokeAnimation = try schema.pokeAnimation(model, animation: animation)
    }

    func playAnimation(_ animation: String) throws {
        stopAnimation(currentAnimation)
        let caAnimation = try self.animation(animation)
        addAnimation(caAnimation, forKey: animation)
        caAnimation.delegate = self
        currentAnimation = animation
    }

    func stopAnimation(_ animation: String) {
        removeAnimation(forKey: animation, blendOutDuration: 0.5)
        if currentAnimation.isWalkAnimation {
            faceCamera()
        }
        currentAnimation = ""
    }

    func playWalkAnimation(location: CLLocation) throws {
        let speed = location.speed
        if speed > 0 {
            if speed < 0.5 {
                stopAnimation(walkAnimation)
            } else if currentAnimation == "" {
                try playAnimation(walkAnimation)
            }
        } else {
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if currentAnimation == "" {
                    try playAnimation(walkAnimation)
                }
                lastLocation = location
            } else {
                stopAnimation(walkAnimation)
            }
        }
    }

    func turn(location: CLLocation) {
        guard currentAnimation.isWalkAnimation, location.course > -1 else {
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
        let scene = try schema.idleScene(model)
        scene.rootNode.childNodes.forEach {
            addChildNode($0)
        }
    }

    func animation(_ animation: String) throws -> CAAnimation {
        guard let caAnimation = animations[animation] else {
            throw ARtyError.invalidAnimationName(animation)
        }
        return caAnimation
    }

    func loopPassiveAnimation() {
        let random = Double(arc4random_uniform(10) + 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + random) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.currentAnimation == "" {
                try? self.playAnimation(self.passiveAnimation)
            }
            self.loopPassiveAnimation()
        }
    }

    func faceCamera() {
        let rotateAction = SCNAction.rotateTo(
            x: 0,
            y: 0,
            z: 0,
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(rotateAction)
    }
}

extension ARty: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        currentAnimation = ""
    }
}
