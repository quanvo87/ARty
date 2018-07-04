import SceneKit
import CoreLocation
import FirebaseFirestore

protocol FriendlyARtyDelegate: class {
    func friendlyARty(_ friendlyARty: FriendlyARty, userChangedModel user: User)
    func friendlyARty(_ friendlyARty: FriendlyARty, didUpdateLocation location: CLLocation)
}

class FriendlyARty: ARty {
    private var pokeTimestamp: Date?
    private var userListener: ListenerRegistration?
    private var locationListener: ListenerRegistration?
    private weak var delegate: FriendlyARtyDelegate?

    init(user: User, pointOfView: SCNNode, delegate: FriendlyARtyDelegate) throws {
        self.delegate = delegate
        try super.init(
            uid: user.uid,
            model: user.model,
            pointOfView: pointOfView,
            passiveEmote: user.passiveEmote(for: user.model),
            pokeEmote: user.pokeEmote(for: user.model),
            status: user.status
        )
        makeListeners()
        eulerAngles.y = Float(Double(arc4random_uniform(360)).radians)
    }

    static func make(uid: String,
                     pointOfView: SCNNode,
                     delegate: FriendlyARtyDelegate,
                     completion: @escaping (Database.Result<FriendlyARty, Error>) -> Void) {
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

    func walk(to position: SCNVector3) throws {
        if isIdle {
            try playAnimation(walkAnimation)
        }
        let duration = TimeInterval(self.position.distance(to: position))
        let moveAction = SCNAction.move(to: position, duration: duration)
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

private extension FriendlyARty {
    func makeListeners() {
        userListener = Database.userListener(uid) { [weak self] user in
            guard let `self` = self else {
                return
            }
            if user.model == self.model {
                self.update(from: user)
            } else {
                self.delegate?.friendlyARty(self, userChangedModel: user)
            }
        }
        locationListener = Database.locationListener(uid: uid) { [weak self] location in
            guard let `self` = self else {
                return
            }
            self.delegate?.friendlyARty(self, didUpdateLocation: location)
            self.location = location
        }
    }

    func update(from user: User) {
        try? setPassiveEmote(to: user.passiveEmote(for: user.model))
        try? setPokeEmote(to: user.pokeEmote(for: user.model))
        if pokeTimestamp == nil || pokeTimestamp != user.pokeTimestamp {
            try? playAnimation(pokeEmote)
            pokeTimestamp = user.pokeTimestamp
        }
        if user.status != status {
            status = user.status
        }
    }
}
