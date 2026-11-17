constants = {}
constants.PED_COMPONENTS_IDS = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
constants.PED_PROPS_IDS = {0, 1, 2, 6, 7}

constants.FACE_FEATURES = {
    "noseWidth",
    "nosePeakHigh",
    "nosePeakSize",
    "noseBoneHigh",
    "nosePeakLowering",
    "noseBoneTwist",
    "eyeBrownHigh",
    "eyeBrownForward",
    "cheeksBoneHigh",
    "cheeksBoneWidth",
    "cheeksWidth",
    "eyesOpening",
    "lipsThickness",
    "jawBoneWidth",
    "jawBoneBackSize",
    "chinBoneLowering",
    "chinBoneLenght",
    "chinBoneSize",
    "chinHole",
    "neckThickness",
}

constants.HEAD_OVERLAYS = {
    "blemishes",
    "beard",
    "eyebrows",
    "ageing",
    "makeUp",
    "blush",
    "complexion",
    "sunDamage",
    "lipstick",
    "moleAndFreckles",
    "chestHair",
    "bodyBlemishes",
}

-- Thanks to rootcause for the eye colors names and hair decorations hashes
constants.EYE_COLORS = {
    "Green",
    "Emerald",
    "Light Blue",
    "Ocean Blue",
    "Light Brown",
    "Dark Brown",
    "Hazel",
    "Dark Gray",
    "Light Gray",
    "Pink",
    "Yellow",
    "Purple",
    "Blackout",
    "Shades of Gray",
    "Tequila Sunrise",
    "Atomic",
    "Warp",
    "ECola",
    "Space Ranger",
    "Ying Yang",
    "Bullseye",
    "Lizard",
    "Dragon",
    "Extra Terrestrial",
    "Goat",
    "Smiley",
    "Possessed",
    "Demon",
    "Infected",
    "Alien",
    "Undead",
    "Zombie",
}

constants.HAIR_DECORATIONS = {
    male = {
        [0] = { joaat('mpbeach_overlays'), joaat('FM_Hair_Fuzz') },
        [1] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_001') },
        [2] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_002') },
        [3] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_003') },
        [4] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_004') },
        [5] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_005') },
        [6] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_006') },
        [7] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_007') },
        [8] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_008') },
        [9] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_009') },
        [10] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_013') },
        [11] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_002') },
        [12] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_011') },
        [13] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_012') },
        [14] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_014') },
        [15] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_015') },
        [16] = { joaat('multiplayer_overlays'), joaat('NGBea_M_Hair_000') },
        [17] = { joaat('multiplayer_overlays'), joaat('NGBea_M_Hair_001') },
        [18] = { joaat('multiplayer_overlays'), joaat('NGBus_M_Hair_000') },
        [19] = { joaat('multiplayer_overlays'), joaat('NGBus_M_Hair_001') },
        [20] = { joaat('multiplayer_overlays'), joaat('NGHip_M_Hair_000') },
        [21] = { joaat('multiplayer_overlays'), joaat('NGHip_M_Hair_001') },
        [22] = { joaat('multiplayer_overlays'), joaat('NGInd_M_Hair_000') },
        [24] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_000') },
        [25] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_001') },
        [26] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_002') },
        [27] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_003') },
        [28] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_004') },
        [29] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_005') },
        [30] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_006') },
        [31] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_000_M') },
        [32] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_001_M') },
        [33] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_002_M') },
        [34] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_003_M') },
        [35] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_004_M') },
        [36] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_005_M') },
        [37] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_001') },
        [38] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_002') },
        [39] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_003') },
        [40] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_004') },
        [41] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_005') },
        [42] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_006') },
        [43] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_007') },
        [44] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_008') },
        [45] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_009') },
        [46] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_013') },
        [47] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_002') },
        [48] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_011') },
        [49] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_012') },
        [50] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_014') },
        [51] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_015') },
        [52] = { joaat('multiplayer_overlays'), joaat('NGBea_M_Hair_000') },
        [53] = { joaat('multiplayer_overlays'), joaat('NGBea_M_Hair_001') },
        [54] = { joaat('multiplayer_overlays'), joaat('NGBus_M_Hair_000') },
        [55] = { joaat('multiplayer_overlays'), joaat('NGBus_M_Hair_001') },
        [56] = { joaat('multiplayer_overlays'), joaat('NGHip_M_Hair_000') },
        [57] = { joaat('multiplayer_overlays'), joaat('NGHip_M_Hair_001') },
        [58] = { joaat('multiplayer_overlays'), joaat('NGInd_M_Hair_000') },
        [59] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_000') },
        [60] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_001') },
        [61] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_002') },
        [62] = { joaat('mplowrider_overlays'), joaat('LR_M_Hair_003') },
        [63] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_004') },
        [64] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_005') },
        [65] = { joaat('mplowrider2_overlays'), joaat('LR_M_Hair_006') },
        [66] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_000_M') },
        [67] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_001_M') },
        [68] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_002_M') },
        [69] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_003_M') },
        [70] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_004_M') },
        [71] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_005_M') },
        [72] = { joaat('mpgunrunning_overlays'), joaat('MP_Gunrunning_Hair_M_000_M') },
        [73] = { joaat('mpgunrunning_overlays'), joaat('MP_Gunrunning_Hair_M_001_M') },
        [74] = { joaat('mpVinewood_overlays'), joaat('MP_Vinewood_Hair_M_000_M') },
        [75] = { joaat('mptuner_overlays'), joaat('MP_Tuner_Hair_001_M') },
        [76] = { joaat('mpsecurity_overlays'), joaat('MP_Security_Hair_001_M') },
    },

    female = {
        [0] = { joaat('mpbeach_overlays'), joaat('FM_Hair_Fuzz') },
        [1] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_001') },
        [2] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_002') },
        [3] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_003') },
        [4] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_004') },
        [5] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_005') },
        [6] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_006') },
        [7] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_007') },
        [8] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_008') },
        [9] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_009') },
        [10] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_010') },
        [11] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_011') },
        [12] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_012') },
        [13] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_013') },
        [14] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_014') },
        [15] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_015') },
        [16] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_000') },
        [17] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_001') },
        [18] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_007') },
        [19] = { joaat('multiplayer_overlays'), joaat('NGBus_F_Hair_000') },
        [20] = { joaat('multiplayer_overlays'), joaat('NGBus_F_Hair_001') },
        [21] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_001') },
        [22] = { joaat('multiplayer_overlays'), joaat('NGHip_F_Hair_000') },
        [23] = { joaat('multiplayer_overlays'), joaat('NGInd_F_Hair_000') },
        [25] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_000') },
        [26] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_001') },
        [27] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_002') },
        [28] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_003') },
        [29] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_003') },
        [30] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_004') },
        [31] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_006') },
        [32] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_000_F') },
        [33] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_001_F') },
        [34] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_002_F') },
        [35] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_003_F') },
        [36] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_003') },
        [37] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_006_F') },
        [38] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_004_F') },
        [39] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_001') },
        [40] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_002') },
        [41] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_003') },
        [42] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_004') },
        [43] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_005') },
        [44] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_006') },
        [45] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_007') },
        [46] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_008') },
        [47] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_009') },
        [48] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_010') },
        [49] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_011') },
        [50] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_012') },
        [51] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_013') },
        [52] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_014') },
        [53] = { joaat('multiplayer_overlays'), joaat('NG_M_Hair_015') },
        [54] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_000') },
        [55] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_001') },
        [56] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_007') },
        [57] = { joaat('multiplayer_overlays'), joaat('NGBus_F_Hair_000') },
        [58] = { joaat('multiplayer_overlays'), joaat('NGBus_F_Hair_001') },
        [59] = { joaat('multiplayer_overlays'), joaat('NGBea_F_Hair_001') },
        [60] = { joaat('multiplayer_overlays'), joaat('NGHip_F_Hair_000') },
        [61] = { joaat('multiplayer_overlays'), joaat('NGInd_F_Hair_000') },
        [62] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_000') },
        [63] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_001') },
        [64] = { joaat('mplowrider_overlays'), joaat('LR_F_Hair_002') },
        [65] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_003') },
        [66] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_003') },
        [67] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_004') },
        [68] = { joaat('mplowrider2_overlays'), joaat('LR_F_Hair_006') },
        [69] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_000_F') },
        [70] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_001_F') },
        [71] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_002_F') },
        [72] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_003_F') },
        [73] = { joaat('multiplayer_overlays'), joaat('NG_F_Hair_003') },
        [74] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_006_F') },
        [75] = { joaat('mpbiker_overlays'), joaat('MP_Biker_Hair_004_F') },
        [76] = { joaat('mpgunrunning_overlays'), joaat('MP_Gunrunning_Hair_F_000_F') },
        [77] = { joaat('mpgunrunning_overlays'), joaat('MP_Gunrunning_Hair_F_001_F') },
        [78] = { joaat('mpVinewood_overlays'), joaat('MP_Vinewood_Hair_F_000_F') },
        [79] = { joaat('mptuner_overlays'), joaat('MP_Tuner_Hair_000_F') },
        [80] = { joaat('mpsecurity_overlays'), joaat('MP_Security_Hair_000_F') },
    },
}

constants.DATA_CLOTHES = {
    head = {
        animations = {
            on = {
                dict = "mp_masks@standard_car@ds@",
                anim = "put_on_mask",
                move = 51,
                duration = 600
            },
            off = {
                dict = "missheist_agency2ahelmet",
                anim = "take_off_helmet_stand",
                move = 51,
                duration = 1200
            }
        },
        components = {
            male = {
                {1, 0}
            },
            female = {
                {1, 0}
            }
        },
        props = {
            male = {
                {0, -1}
            },
            female = {}
        }
    },
    body = {
        animations = {
            on = {
                dict = "clothingtie",
                anim = "try_tie_negative_a",
                move = 51,
                duration = 1200
            },
            off = {
                dict = "clothingtie",
                anim = "try_tie_negative_a",
                move = 51,
                duration = 1200
            }
        },
        components = {
            male = {
                {11, 252},
                {3, 15},
                {8, 15},
                {10, 0},
                {5, 0}
            },
            female = {
                {11, 15},
                {8, 14},
                {3, 15},
                {10, 0},
                {5, 0}
            }
        },
        props = {
            male = {},
            female = {}
        }
    },
    bottom = {
        animations = {
            on = {
                dict = "re@construction",
                anim = "out_of_breath",
                move = 51,
                duration = 1300
            },
            off = {
                dict = "re@construction",
                anim = "out_of_breath",
                move = 51,
                duration = 1300
            }
        },
        components = {
            male = {
                {4, 61},
                {6, 34}
            },
            female = {
                {4, 15},
                {6, 35}
            }
        },
        props = {
            male = {},
            female = {}
        }
    }
}

constants.CAMERAS = {
    default = {
        vec3(0, 2.2, 0.2),
        vec3(0, 0, -0.05),
    },
    head = {
        vec3(0, 0.9, 0.65),
        vec3(0, 0, 0.6),
    },
    body = {
        vec3(0, 1.2, 0.2),
        vec3(0, 0, 0.2),
    },
    bottom = {
        vec3(0, 0.98, -0.7),
        vec3(0, 0, -0.9),
    },
}

constants.OFFSETS = {
    default = vec2(1.5, -1),
    head = vec2(0.7, -0.45),
    body = vec2(1.2, -0.45),
    bottom = vec2(0.7, -0.45),
}
