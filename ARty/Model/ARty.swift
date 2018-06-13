import SceneKit
import CoreLocation
import FirebaseFirestore

protocol ARtyDelegate: class {
    func arty(_ arty: ARty, userChangedModel user: User)
    func arty(_ arty: ARty, latitude: Double, longitude: Double)
}

class ARty: SCNNode {
    let uid: String
    let model: String
    let positionAdjustment: SCNVector3  // todo: change to only a y adjustment
    let emotes: [String]
    var pokeTimestamp: Date?
    private(set) var passiveEmote = ""
    private(set) var pokeEmote = ""
    private let animations: [String: CAAnimation]
    private let walkAnimation: String
    private var lastLocation = CLLocation()
    private var userListener: ListenerRegistration?
    private var locationListener: ListenerRegistration?
    private weak var delegate: ARtyDelegate?

    init(uid: String,
         model: String,
         passiveEmote: String = "",
         pokeEmote: String = "",
         delegate: ARtyDelegate?) throws {
        self.uid = uid
        self.model = model
        positionAdjustment = try schema.positionAdjustment(for: model)
        emotes = try schema.emotes(for: model)
        animations = try schema.animations(for: model)
        walkAnimation = try schema.walkAnimation(for: model)

        super.init()

        name = uid
        scale = try schema.scale(for: model)
        try addIdleScene()
        try setPassiveEmote(to: passiveEmote)
        try setPokeEmote(to: pokeEmote)
        loopPassiveEmote()
        centerPivot()
        makeListeners(delegate: delegate)
    }

    convenience init(user: User, delegate: ARtyDelegate?) throws {
        try self.init(
            uid: user.uid,
            model: user.model,
            passiveEmote: user.passiveEmote(for: user.model),
            pokeEmote: user.pokeEmote(for: user.model),
            delegate: delegate
        )
    }

    static func make(uid: String,
                     delegate: ARtyDelegate,
                     completion: @escaping (Database.Result<ARty, Error>) -> Void) {
        Database.user(uid) { result in
            switch result {
            case .fail(let error):
                completion(.fail(error))
            case .success(let user):
                do {
                    completion(.success(try .init(user: user, delegate: delegate)))
                } catch {
                    completion(.fail(error))
                }
            }
        }
    }

    var isIdle: Bool {
        return animationKeys.isEmpty
    }

    func setPassiveEmote(to emote: String) throws {
        passiveEmote = try schema.setPassiveEmote(for: model, to: emote)
    }

    func setPokeEmote(to emote: String) throws {
        pokeEmote = try schema.setPokeEmote(for: model, to: emote)
    }

    func playPokeEmote() throws {
        try playAnimation(pokeEmote)
    }

    func playWalkAnimation() throws {
        guard isIdle else {
            return
        }
        try playAnimation(walkAnimation)
    }

    func stopWalkAnimation() {
        removeAnimation(forKey: walkAnimation)
    }

    // todo: rename
    func walk(to location: CLLocation) throws {
        let speed = location.speed
        if speed > 0 {
            if speed < 0.5 {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                faceCamera()
            } else if isIdle {
                turn(to: location.course)
                try playAnimation(walkAnimation)
            }
        } else {
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if isIdle {
                    turn(to: location.course)
                    try playAnimation(walkAnimation)
                }
                lastLocation = location
            } else {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                faceCamera()
            }
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

private extension ARty {
    func addIdleScene() throws {
        let scene = try schema.idleScene(for: model)
        scene.rootNode.childNodes.forEach {
            addChildNode($0)
        }
    }

    func loopPassiveEmote() {
        let random = Double(arc4random_uniform(10) + 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + random) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.isIdle {
                try? self.playAnimation(self.passiveEmote)
            }
            self.loopPassiveEmote()
        }
    }

    func centerPivot() {
        let (minBox, maxBox) = boundingBox
        pivot = SCNMatrix4MakeTranslation(0, (maxBox.y - minBox.y)/2, 0)
    }

    func makeListeners(delegate: ARtyDelegate?) {
        guard let delegate = delegate else {
            return
        }
        self.delegate = delegate

        userListener = Database.userListener(uid) { [weak self] user in
            guard let `self` = self else {
                return
            }
            if user.model == self.model {
                self.update(from: user)
            } else {
                self.delegate?.arty(self, userChangedModel: user)
            }
        }

        locationListener = Database.locationListener(uid: uid) { [weak self] (latitude, longitude) in
            guard let `self` = self else {
                return
            }
            self.delegate?.arty(self, latitude: latitude, longitude: longitude)
        }
    }

    func update(from user: User) {
        try? setPassiveEmote(to: user.passiveEmote(for: user.model))
        try? setPokeEmote(to: user.pokeEmote(for: user.model))
        setPokeTimestamp(to: user.pokeTimestamp)
    }

    func setPokeTimestamp(to date: Date) {
        if self.pokeTimestamp != date {
            try? playPokeEmote()
        }
        self.pokeTimestamp = date
    }

    func animation(_ animation: String) throws -> CAAnimation {
        guard let caAnimation = animations[animation] else {
            throw ARtyError.invalidAnimationName(animation)
        }
        return caAnimation
    }

    func playAnimation(_ animation: String) throws {
        removeAllAnimations()
        let caAnimation = try self.animation(animation)
        addAnimation(caAnimation, forKey: animation)
    }

    // todo: use ARtyMover rotate()?
    // todo: use heading if course not avail
    func turn(to direction: CLLocationDirection) {
        guard direction > -1 else {
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
