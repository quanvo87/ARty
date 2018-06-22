// swiftlint:disable identifier_name
var schema = Schema(
    arties: [
        elvira.model: elvira,
        mutant.model: mutant,
        paladin.model: paladin,
        gunship_soldier.model: gunship_soldier
    ]
)

// todo: make arties bigger, maybe lower
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

let gunship_soldier = ARtySchema(
    model: "gunship_soldier",
    scale: 0.1,
    emotes: [
        "gunship_soldier_backflip_uppercut",
        "gunship_soldier_bboy_hip_hop_dance",
        "gunship_soldier_fighting_stance",
        "gunship_soldier_wave"
    ],
    idleAnimation: "gunship_soldier_idle",
    walkAnimation: "gunship_soldier_walk",
    fallAnimation: "",
    defaultPassiveEmote: "gunship_soldier_fighting_stance",
    defaultPokeEmote: "gunship_soldier_backflip_uppercut",
    animationRepeatCounts: [
        "gunship_soldier_bboy_hip_hop_dance": 2,
        "gunship_soldier_fighting_stance": 2,
        "gunship_soldier_wave": 4
    ],
    statusHeight: 6.5,
    statusScale: 0.15
)
// swiftlint:enable identifier_name
