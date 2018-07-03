import SceneKit
import CoreLocation

class ARty: SCNNode {
    let uid: String
    let model: String
    let emotes: [String]
    let walkAnimation: String
    var location: CLLocation?
    private(set) var passiveEmote: String
    private(set) var pokeEmote: String
    private let animations: [String: CAAnimation]
    private let pointOfView: SCNNode

    init(uid: String,
         model: String,
         passiveEmote: String,
         pokeEmote: String,
         status: String,
         pointOfView: SCNNode) throws {
        self.uid = uid
        self.model = model
        self.emotes = try schema.emotes(for: model)
        self.walkAnimation = try schema.walkAnimation(for: model)
        self.passiveEmote = try schema.setPassiveEmote(for: model, to: passiveEmote)
        self.pokeEmote = try schema.setPokeEmote(for: model, to: pokeEmote)
        self.animations = try schema.animations(for: model)
        self.pointOfView = pointOfView

        super.init()

        name = uid
        constraints = []
        try addIdleScene()
        loopPassiveEmote()
        centerPivot()

        defer {
            self.status = status
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

    var isIdle: Bool {
        return animationKeys.isEmpty
    }

    func setPassiveEmote(to emote: String) throws {
        passiveEmote = try schema.setPassiveEmote(for: model, to: emote)
    }

    func setPokeEmote(to emote: String) throws {
        pokeEmote = try schema.setPokeEmote(for: model, to: emote)
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

    func turnToDirection(_ direction: Double) {
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

    func playAnimation(_ animation: String) throws {
        let caAnimation = try self.animation(animation)
        addAnimation(caAnimation, forKey: animation)
    }

    private lazy var billboardConstraint: SCNBillboardConstraint = {
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.Y]
        return constraint
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ARty {
    var isTurningToCamera: Bool {
        if let constraints = constraints {
            return constraints.contains(billboardConstraint)
        } else {
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

    func addStatusNode(_ status: String) {
        childNode(withName: "status", recursively: false)?.removeFromParentNode()

        let material = SCNMaterial()
        material.diffuse.contents = type(of: self) == MyARty.self ? UIColor.green : UIColor.white

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
