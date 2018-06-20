var schema = Schema(
    arties: [
        elvira.model: elvira,
        mutant.model: mutant,
        paladin.model: paladin
    ]
)

let elvira = ARtySchema(
    model: "elvira",
    scale: 0.02,
    emotes: [
        "elvira_twerk",
        "elvira_buttslap",
        "elvira_wave"
    ],
    idleAnimation: "elvira_idle",
    walkAnimation: "elvira_walk",
    fallAnimation: "",
    defaultPassiveEmote: "elvira_wave",
    defaultPokeEmote: "elvira_buttslap",
    animationRepeatCounts: ["elvira_wave": 4],
    statusHeight: 35,
    statusScale: 1
)

let mutant = ARtySchema(
    model: "mutant",
    scale: 0.0035,
    emotes: [
        "mutant_battlecry",
        "mutant_chestthump",
        "mutant_thriller",
        "mutant_wave"
    ],
    idleAnimation: "mutant_idle",
    walkAnimation: "mutant_walk",
    fallAnimation: "mutant_fall",
    defaultPassiveEmote: "mutant_chestthump",
    defaultPokeEmote: "mutant_battlecry",
    animationRepeatCounts: [:],
    statusHeight: 200,
    statusScale: 5
)

let paladin = ARtySchema(
    model: "paladin",
    scale: 0.003,
    emotes: [
        "paladin_fierce_attack",
        "paladin_slide_dance",
        "paladin_sword_combo",
        "paladin_wave"
    ],
    idleAnimation: "paladin_idle",
    walkAnimation: "paladin_walk",
    fallAnimation: "paladin_fall",
    defaultPassiveEmote: "paladin_wave",
    defaultPokeEmote: "paladin_fierce_attack",
    animationRepeatCounts: ["paladin_wave": 4],
    statusHeight: 200,
    statusScale: 5
)
