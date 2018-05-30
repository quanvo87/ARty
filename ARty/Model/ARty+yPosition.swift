//
//  ARty+yPosition.swift
//  ARty
//
//  Created by Quan Vo on 5/27/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import Foundation

extension ARty {
    var defaultYPosition: Float {
        switch modelName {
        case .elvira:
            return -2
        case .mutant:
            return -10
        }
    }
}
