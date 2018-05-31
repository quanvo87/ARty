var metaData = MetaData(
    arties: [
        elvira.model: elvira,
        mutant.model: mutant
    ],
    animationRepeatCounts: animationRepeatCounts,
    walkAnimations: walkAnimations
)

let elvira = ARtyMetaData(
    model: "elvira",
    scale: 0.075,
    positionAdjustment: -2,
    animations: [
        "elvira_twerk",
        "elvira_buttslap",
        "elvira_walk",
        "elvira_wave"
    ],
    idleAnimation: "elvira_idle",
    walkAnimation: "elvira_walk",
    passiveAnimation: "elvira_wave",
    pokeAnimation: "elvira_buttslap"
)

let mutant = ARtyMetaData(
    model: "mutant",
    scale: 0.065,
    positionAdjustment: -10,
    animations: [
        "mutant_battlecry",
        "mutant_chestthump",
        "mutant_fall",
        "mutant_thriller",
        "mutant_walk",
        "mutant_wave"
    ],
    idleAnimation: "mutant_idle",
    walkAnimation: "mutant_walk",
    passiveAnimation: "mutant_chestthump",
    pokeAnimation: "mutant_battlecry"
)

let animationRepeatCounts: [String: Float] = [
    "elvira_wave": 4
]

let walkAnimations = [
    "elvira_walk",
    "mutant_walk"
]
