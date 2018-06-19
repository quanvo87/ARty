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

    private(set) var location: Location?

    private let animations: [String: CAAnimation]

    private let walkAnimation: String

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

        defer {
            status = "Hello :)" // todo: add to init, default to random greeting
        }
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

    var status: String = "" {
        didSet {
            // todo: language filter
            let trimmed = status.prefix(10)
            addStatusNode(String(trimmed))
            status = String(trimmed)
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
            guard let lastLocation = self.location else {
                self.location = Location(location: location, heading: nil)
                return
            }
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if isIdle {
                    try playAnimation(walkAnimation)
                }
                self.location = Location(location: location, heading: nil)
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

    func setStatusConstraint(target: SCNNode?) {
        guard let target = target, let node = childNode(withName: "status", recursively: false) else {
            return
        }
        let constraint = SCNLookAtConstraint(target: target)
        constraint.isGimbalLockEnabled = true
        constraint.localFront = .init(0, 0, 1)
        node.constraints = [constraint]
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
            // todo: add status to user. check if it needs to be updated.
        }
        locationListener = Database.locationListener(uid: uid) { [weak self] location in
            guard let `self` = self else {
                return
            }
            self.delegate?.arty(self, didUpdateLocation: location)
            self.location = location
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

    func addStatusNode(_ status: String) {
        childNode(withName: "status", recursively: false)?.removeFromParentNode()

        let text = SCNText(string: status, extrusionDepth: 1)

        let material = SCNMaterial()

        material.diffuse.contents = delegate == nil ? UIColor.green : UIColor.white

        text.materials = [material]

        let node = SCNNode()

        node.name = "status"

        node.position = .init(x: 0, y: 200, z: 0)  // todo: add y to schema

        node.scale = .init(x: 5, y: 5, z: 5)

        node.geometry = text

        let (min, max) = node.boundingBox

        // swiftlint:disable identifier_name
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        // swiftlint:enable identifier_name

        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

        addChildNode(node)
    }
}
