var schema = Schema(
    arties: [
        elvira.model: elvira,
        mutant.model: mutant,
        paladin.model: paladin
    ],
    animationRepeatCounts: animationRepeatCounts,
    walkAnimations: walkAnimations,
    fallAnimations: fallAnimations
)

let elvira = ARtySchema(
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

let mutant = ARtySchema(
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

let paladin = ARtySchema(
    model: "paladin",
    scale: 0.03,
    positionAdjustment: -4,
    animations: [
        "paladin_fall",
        "paladin_fierce_attack",
        "paladin_slide_dance",
        "paladin_sword_combo",
        "paladin_walk",
        "paladin_wave"
    ],
    idleAnimation: "paladin_idle",
    walkAnimation: "paladin_walk",
    passiveAnimation: "paladin_wave",
    pokeAnimation: "paladin_fierce_attack"
)

let animationRepeatCounts: [String: Float] = [
    "elvira_wave": 4,
    "paladin_wave": 4
]

let walkAnimations = [
    "elvira_walk",
    "mutant_walk",
    "paladin_walk"
]

let fallAnimations = [
    "mutant_fall",
    "paladin_fall"
]
