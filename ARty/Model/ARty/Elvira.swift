//
//  Elvira.swift
//  ARty
//
//  Created by Quan Vo on 5/23/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import ARKit

// todo: create static default animationNames
class Elvira: ARty {
    init(ownerId: String,
         passiveAnimation: AnimationName = .wave,
         pokeAnimation: AnimationName = .taunt_buttslap,
         walkAnimation: AnimationName = .walk_badbitch) throws {
        try super.init(
            ownerId: ownerId,
            name: .elvira,
            scale: 0.06,
            yPosition: -1.5,
            animationNames: [
                .dance_twerk,
                .taunt_buttslap,
                .walk_badbitch,
                .wave
            ],
            passiveAnimation: passiveAnimation,
            pokeAnimation: pokeAnimation,
            walkAnimation: walkAnimation
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
