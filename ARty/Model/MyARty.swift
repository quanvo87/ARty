import SceneKit
import CoreLocation

class MyARty: ARty {
    var basePosition: SCNVector3

    private init(uid: String,
                 model: String,
                 pointOfView: SCNNode,
                 passiveEmote: String,
                 pokeEmote: String,
                 status: String,
                 basePosition: SCNVector3) throws {
        self.basePosition = basePosition
        try super.init(
            uid: uid,
            model: model,
            pointOfView: pointOfView,
            passiveEmote: passiveEmote,
            pokeEmote: pokeEmote,
            status: status
        )
    }

    static func makeNew(uid: String, model: String, pointOfView: SCNNode) throws -> MyARty {
        return try MyARty(
            uid: uid,
            model: model,
            pointOfView: pointOfView,
            passiveEmote: "",
            pokeEmote: "",
            status: "Hello :)",
            basePosition: MyARty.basePosition(simdWorldFront: pointOfView.simdWorldFront)
        )
    }

    static func makeFromUser(_ user: User, pointOfView: SCNNode) throws -> MyARty {
        return try MyARty(
            uid: user.uid,
            model: user.model,
            pointOfView: pointOfView,
            passiveEmote: user.passiveEmote(for: user.model),
            pokeEmote: user.pokeEmote(for: user.model),
            status: user.status,
            basePosition: MyARty.basePosition(simdWorldFront: pointOfView.simdWorldFront)
        )
    }

    static func makeFromModelChange(uid: String,
                                    model: String,
                                    status: String,
                                    pointOfView: SCNNode,
                                    basePosition: SCNVector3) throws -> MyARty {
        return try MyARty(
            uid: uid,
            model: model,
            pointOfView: pointOfView,
            passiveEmote: "",
            pokeEmote: "",
            status: status,
            basePosition: basePosition
        )
    }

    func setBasePosition() {
        basePosition = MyARty.basePosition(simdWorldFront: pointOfView.simdWorldFront)
    }

    func walk(location: CLLocation) throws {
        let speed = location.speed
        if speed != -1 {
            if speed < 0.5 {
                removeAnimation(forKey: walkAnimation, blendOutDuration: 0.5)
                turnToCamera(force: false)
            } else if isIdle {
                try playAnimation(walkAnimation)
            }
            self.location = location
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
                turnToCamera(force: false)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MyARty {
    static func basePosition(simdWorldFront: float3) -> SCNVector3 {
        return .init(simdWorldFront.x, -0.75, simdWorldFront.z)
    }
}
