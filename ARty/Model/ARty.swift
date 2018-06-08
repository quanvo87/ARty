import SceneKit
import CoreLocation
import FirebaseFirestore

protocol ARtyDelegate: class {
    func arty(_ arty: ARty, updateUser user: User)
    func arty(_ arty: ARty, latitude: Double, longitude: Double)
}

class ARty: SCNNode {
    let uid: String
    let model: String
    let positionAdjustment: SCNVector3
    let pickableAnimations: [String]
    var pokeTimestamp: Date?
    private(set) var passiveAnimation = ""
    private(set) var pokeAnimation = ""
    private let animations: [String: CAAnimation]
    private let walkAnimation: String
    private var currentAnimation = ""
    private var lastLocation = CLLocation()
    private var userListener: ListenerRegistration?
    private var locationListener: ListenerRegistration?
    private weak var delegate: ARtyDelegate?

    init(uid: String,
         model: String,
         passiveAnimation: String = "",
         pokeAnimation: String = "",
         delegate: ARtyDelegate?) throws {
        self.uid = uid
        self.model = model
        positionAdjustment = try schema.positionAdjustment(model)
        pickableAnimations = try schema.pickableAnimations(model)
        animations = try schema.animations(model)
        walkAnimation = try schema.walkAnimation(model)

        super.init()

        name = uid
        scale = try schema.scale(model)
        try loadIdleScene()
        try setPassiveAnimation(passiveAnimation)
        try setPokeAnimation(pokeAnimation)
        loopPassiveAnimation()
        setupListeners(delegate: delegate)
    }

    convenience init(user: User, delegate: ARtyDelegate?) throws {
        try self.init(
            uid: user.uid,
            model: user.model,
            passiveAnimation: user.passiveAnimation,
            pokeAnimation: user.pokeAnimation,
            delegate: delegate
        )
    }

    var dictionary: [String: String] {
        return [
            "model": model,
            "passiveAnimation": passiveAnimation,
            "pokeAnimation": pokeAnimation
        ]
    }

    func update(from user: User) {
        try? setPassiveAnimation(user.passiveAnimation)
        try? setPokeAnimation(user.pokeAnimation)
        setPokeTimestamp(user.pokeTimestamp)
    }

    func setPassiveAnimation(_ animation: String) throws {
        passiveAnimation = try schema.passiveAnimation(model, animation: animation)
    }

    func setPokeAnimation(_ animation: String) throws {
        pokeAnimation = try schema.pokeAnimation(model, animation: animation)
    }

    func playPokeAnimation() throws {
        try playAnimation(pokeAnimation)
    }

    func walk(to location: CLLocation) throws {
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
        turn(to: location.course)
    }

    func walk(to position: SCNVector3) throws {
        if currentAnimation == "" {
            try playAnimation(walkAnimation)
        }

        let turnAction = SCNAction.rotateTo(
            x: CGFloat(position.x),
            y: CGFloat(position.y),
            z: CGFloat(position.z),
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(turnAction)

        let moveAction = SCNAction.move(to: position, duration: 5)
        runAction(moveAction) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.stopAnimation(self.walkAnimation)
        }
    }

    deinit {
        userListener?.remove()
        locationListener?.remove()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ARty: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        currentAnimation = ""
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

    func setupListeners(delegate: ARtyDelegate?) {
        guard let delegate = delegate else {
            return
        }
        self.delegate = delegate

        userListener = Database.userListener(uid) { [weak self] user in
            guard let `self` = self else {
                return
            }
            self.delegate?.arty(self, updateUser: user)
        }

        locationListener = Database.locationListener(uid: uid) { [weak self] (latitude, longitude) in
            guard let `self` = self else {
                return
            }
            self.delegate?.arty(self, latitude: latitude, longitude: longitude)
        }
    }

    func setPokeTimestamp(_ pokeTimestamp: Date) {
        if self.pokeTimestamp != pokeTimestamp {
            try? playPokeAnimation()
        }
        self.pokeTimestamp = pokeTimestamp
    }

    func turn(to direction: CLLocationDirection) {
        guard currentAnimation.isWalkAnimation, direction > -1 else {
            return
        }
        let rotateAction = SCNAction.rotateTo(
            x: 0,
            y: direction.radians,
            z: 0,
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(rotateAction)
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

private extension CLLocationDirection {
    var radians: CGFloat {
        let adjusted = Float((450 - self).remainder(dividingBy: 360)) + 90  // todo: reduce
        return CGFloat(GLKMathDegreesToRadians(adjusted))
    }
}
