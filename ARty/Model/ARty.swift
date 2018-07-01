import SceneKit
import CoreLocation
import FirebaseFirestore

protocol ARtyDelegate: class {
    func arty(_ arty: ARty, userChangedModel user: User)
    func arty(_ arty: ARty, didUpdateLocation location: CLLocation)
}

class ARty: SCNNode {
    let uid: String

    let model: String

    let emotes: [String]

    var basePosition: SCNVector3?

    private(set) var passiveEmote = ""

    private(set) var pokeEmote = ""

    private(set) var location: CLLocation?

    private let animations: [String: CAAnimation]

    private let walkAnimation: String

    private let pointOfView: SCNNode?

    private var pokeTimestamp: Date?

    private var userListener: ListenerRegistration?

    private var locationListener: ListenerRegistration?

    private weak var delegate: ARtyDelegate?

    init(uid: String,
         model: String,
         passiveEmote: String = "",
         pokeEmote: String = "",
         status: String,
         pointOfView: SCNNode?,
         delegate: ARtyDelegate?) throws {
        self.uid = uid
        self.model = model
        self.pointOfView = pointOfView
        emotes = try schema.emotes(for: model)
        animations = try schema.animations(for: model)
        walkAnimation = try schema.walkAnimation(for: model)

        super.init()

        name = uid
        try addIdleScene()
        try setPassiveEmote(to: passiveEmote)
        try setPokeEmote(to: pokeEmote)
        loopPassiveEmote()
        centerPivot()

        if delegate != nil {
            self.delegate = delegate
            makeListeners()
        }

        defer {
            self.status = status
        }
    }

    convenience init(user: User, pointOfView: SCNNode?, delegate: ARtyDelegate?) throws {
        try self.init(
            uid: user.uid,
            model: user.model,
            passiveEmote: user.passiveEmote(for: user.model),
            pokeEmote: user.pokeEmote(for: user.model),
            status: user.status,
            pointOfView: pointOfView,
            delegate: delegate
        )
    }

    static func make(uid: String,
                     pointOfView: SCNNode?,
                     delegate: ARtyDelegate,
                     completion: @escaping (Database.Result<ARty, Error>) -> Void) {
        Database.user(uid) { result in
            switch result {
            case .fail(let error):
                completion(.fail(error))
            case .success(let user):
                do {
                    completion(.success(try .init(user: user, pointOfView: pointOfView, delegate: delegate)))
                } catch {
                    completion(.fail(error))
                }
            }
        }
    }

    var status: String = "" {
        didSet {
            let trimmed = status.trimmingCharacters(in: .init(charactersIn: " "))
            let truncated = String(trimmed.prefix(10))
            status = truncated
            addStatusNode(truncated)
            Database.setStatus(truncated, for: uid) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }

    func setPassiveEmote(to emote: String) throws {
        passiveEmote = try schema.setPassiveEmote(for: model, to: emote)
    }

    func setPokeEmote(to emote: String) throws {
        pokeEmote = try schema.setPokeEmote(for: model, to: emote)
    }

    func setBasePosition() {
        guard let pointOfView = pointOfView else {
            return
        }
        let zAdjustment = SCNVector3(0, 0, -1)
        var basePosition = pointOfView.convertPosition(zAdjustment, to: nil)
        basePosition.y = -0.75
        self.basePosition = basePosition
        position = basePosition
    }

    func turnToCamera() {
        guard !isTurningToCamera else {
            return
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        SCNTransaction.completionBlock = { [weak self] in
            guard let `self` = self else {
                return
            }
            if let index = self.constraints?.index(of: self.billboardConstraint) {
                self.constraints?.remove(at: index)
            }
        }
        constraints?.append(billboardConstraint)
        SCNTransaction.commit()
    }

    func turnToDirection(_ direction: CLLocationDirection) {
        guard direction != -1, !isTurningToCamera else {
            return
        }
        let adjustedDirection = -1 * (direction - 180)
        let radians = adjustedDirection.radians
        let rotateAction = SCNAction.rotateTo(
            x: 0,
            y: CGFloat(radians),
            z: 0,
            duration: 1,
            usesShortestUnitArc: true
        )
        runAction(rotateAction)
    }

    func walk(location: CLLocation) throws {
        let speed = location.speed
        if speed != -1 {
            if speed < 0.5 {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                turnToCamera()
            } else if isIdle {
                try playAnimation(walkAnimation)
            }
        } else {
            guard let lastLocation = self.location else {
                self.location = location
                return
            }
            let distance = lastLocation.distance(from: location)
            if distance > 5 {
                if isIdle {
                    try playAnimation(walkAnimation)
                }
                self.location = location
            } else {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                turnToCamera()
            }
        }
    }

    func walk(to position: SCNVector3) throws {
        if isIdle {
            try playAnimation(walkAnimation)
        }
        let moveAction = SCNAction.move(to: position, duration: 5)
        runAction(moveAction) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.removeAnimation(forKey: self.walkAnimation, blendOutDuration: 0.5)
        }
    }

    func playAnimation(_ animation: String) throws {
        let caAnimation = try self.animation(animation)
        addAnimation(caAnimation, forKey: animation)
    }

    private lazy var billboardConstraint: SCNBillboardConstraint = {
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.Y]
        return constraint
    }()

    deinit {
        userListener?.remove()
        locationListener?.remove()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ARty {
    var isIdle: Bool {
        return animationKeys.isEmpty
    }

    var isTurningToCamera: Bool {
        if let constraints = constraints {
            return constraints.contains(billboardConstraint)
        } else {
            constraints = []
            return false
        }
    }

    var lookAtConstraint: SCNLookAtConstraint {
        let constraint = SCNLookAtConstraint(target: pointOfView)
        constraint.isGimbalLockEnabled = true
        constraint.localFront = .init(0, 0, 1)
        return constraint
    }

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
        pivot = SCNMatrix4MakeTranslation(0, (maxBox.y - minBox.y) / 2, 0)
    }

    func makeListeners() {
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
            self.location = location
        }
    }

    func update(from user: User) {
        try? setPassiveEmote(to: user.passiveEmote(for: user.model))
        try? setPokeEmote(to: user.pokeEmote(for: user.model))
        setPokeTimestamp(to: user.pokeTimestamp)
        if user.status != status {
            status = user.status
        }
    }

    func setPokeTimestamp(to date: Date) {
        if pokeTimestamp != date {
            try? playAnimation(pokeEmote)
        }
        pokeTimestamp = date
    }

    func addStatusNode(_ status: String) {
        childNode(withName: "status", recursively: false)?.removeFromParentNode()

        let material = SCNMaterial()
        material.diffuse.contents = delegate == nil ? UIColor.green : UIColor.white

        let text = SCNText(string: status, extrusionDepth: 1)
        text.materials = [material]

        let node = SCNNode()
        node.name = "status"
        node.position.y = 0.8
        node.scale = .init(0.01, 0.01, 0.01)
        node.geometry = text

        let (min, max) = node.boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

        node.constraints = [lookAtConstraint]

        addChildNode(node)
    }

    func animation(_ animation: String) throws -> CAAnimation {
        guard let caAnimation = animations[animation] else {
            throw ARtyError.invalidAnimationName(animation)
        }
        return caAnimation
    }
}
