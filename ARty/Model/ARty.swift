import SceneKit
import CoreLocation
import FirebaseFirestore

protocol ARtyDelegate: class {
    func arty(_ arty: ARty, userChangedModel user: User)
    func arty(_ arty: ARty, didUpdateLocation location: Location)
}

class ARty: SCNNode {
    static let zAdjustment = SCNVector3(0, 0, -1)

    let uid: String

    let model: String

    let emotes: [String]

    private(set) var passiveEmote = ""

    private(set) var pokeEmote = ""

    private let animations: [String: CAAnimation]

    private let walkAnimation: String

    private var lastLocation = CLLocation()

    private var pokeTimestamp: Date?

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

    func playAnimation(_ animation: String) throws {
        let caAnimation = try self.animation(animation)
        addAnimation(caAnimation, forKey: animation)
    }

    func faceWalkingDirection(course: CLLocationDirection, heading: CLLocationDirection?) {
        var angle: Double
        if course >= 0 {
            angle = course.angle
        } else if let heading = heading, heading >= 0 {
            angle = heading.angle
        } else {
            return
        }
        let rotateAction = SCNAction.rotateTo(
            x: 0,
            y: CGFloat(angle),
            z: 0,
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(rotateAction)
    }

    func walk(location: CLLocation) throws {
        let speed = location.speed
        if speed > 0 {
            if speed < 0.5 {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                faceCamera()
            } else if isIdle {
                try playAnimation(walkAnimation)
            }
        } else {
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if isIdle {
                    try playAnimation(walkAnimation)
                }
                lastLocation = location
            } else {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                faceCamera()
            }
        }
    }

    func walk(to position: SCNVector3) throws {
        if isIdle {
            try playAnimation(walkAnimation)
        }
        // todo: make duration a function of distance
        let moveAction = SCNAction.move(to: position, duration: 5)
        runAction(moveAction) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.removeAnimation(forKey: self.walkAnimation, blendOutDuration: 0.5)
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
        locationListener = Database.locationListener(uid: uid) { [weak self] location in
            guard let `self` = self else {
                return
            }
            self.delegate?.arty(self, didUpdateLocation: location)
        }
    }

    func update(from user: User) {
        try? setPassiveEmote(to: user.passiveEmote(for: user.model))
        try? setPokeEmote(to: user.pokeEmote(for: user.model))
        setPokeTimestamp(to: user.pokeTimestamp)
    }

    func setPokeTimestamp(to date: Date) {
        if self.pokeTimestamp != date {
            try? playAnimation(pokeEmote)
        }
        self.pokeTimestamp = date
    }

    func animation(_ animation: String) throws -> CAAnimation {
        guard let caAnimation = animations[animation] else {
            throw ARtyError.invalidAnimationName(animation)
        }
        return caAnimation
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
