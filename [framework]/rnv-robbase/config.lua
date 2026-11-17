-- rnv-robbase data: models, scene data and world spots
-- Robbery scripts read it with exports['rnv-robbase']:GetData() or GetModel(name)
Config = {}

Config.Debug = false

-- Every object model the scenarios use, by short name
Config.Models = {
    -- bags
    bag            = 'hei_p_m_bag_var22_arm_s',
    bag_grinder    = 'ch_p_m_bag_var02_arm_s',
    -- shop till
    till_world     = 'prop_till_01',
    till_scene     = 'p_till_01_s',
    till_bag       = 'p_poly_bag_01_s',
    -- safes / lockboxes
    safe           = 'h4_prop_h4_safe_01a',
    lockbox_world  = 'ch_prop_ch_sec_cabinet_01j',
    lockbox_scene  = 'ch_prop_ch_sec_cabinet_01b',
    lockbox_drill  = 'ch_prop_vault_drill_01a',
    lockbox_reward = 'ch_prop_ch_moneybag_01a',
    -- table stacks
    stack_cash     = 'h4_prop_h4_cash_stack_01a',
    stack_gold     = 'h4_prop_h4_gold_stack_01a',
    -- trolleys + what is grabbed from them
    trolley_cash    = 'hei_prop_hei_cash_trolly_01',
    trolley_cash2   = 'ch_prop_ch_cash_trolly_01b',
    trolley_gold    = 'ch_prop_gold_trolly_01a',
    trolley_diamond = 'ch_prop_diamond_trolly_01c',
    trolley_coke    = 'imp_prop_impexp_coke_trolly',
    trolley_empty   = 'hei_prop_hei_cash_trolly_03',
    grab_cash      = 'hei_prop_heist_cash_pile',
    grab_gold      = 'ch_prop_gold_bar_01a',
    grab_diamond   = 'ch_prop_vault_dimaondbox_01a',
    grab_coke      = 'prop_coke_block_half_a',
    -- drills
    drill          = 'hei_prop_heist_drill',
    laser_drill    = 'ch_prop_laserdrill_01a',
    -- explosives
    thermite       = 'hei_prop_heist_thermite',
    bomb           = 'prop_bomb_01',
    -- hacking
    laptop         = 'hei_prop_hst_laptop',
    hack_card      = 'hei_prop_heist_card_hack_02',
    security_panel = 'hei_prop_hei_securitypanel',
    usb            = 'ch_prop_ch_usb_drive01x',
    phone          = 'prop_phone_ing',
    fingerprint    = 'ch_prop_fingerprint_scanner_01e',
    casino_keypad  = 'ch_prop_casino_keypad_01',
    keycard        = 'ch_prop_swipe_card_01a',
    keycard2       = 'ch_prop_swipe_card_01d',
    laptop_desk    = 'p_laptop_02_s',
    -- glass display
    glass_display  = 'h4_prop_h4_glass_disp_01a',
    glass_cut      = 'h4_prop_h4_glass_disp_01b',
    glass_cutter   = 'h4_prop_h4_cutter_01a',
    -- paintings
    knife          = 'w_me_switchblade',
    painting_e     = 'ch_prop_vault_painting_01e',
    painting_f     = 'ch_prop_vault_painting_01f',
    painting_g     = 'ch_prop_vault_painting_01g',
    painting_h     = 'ch_prop_vault_painting_01h',
    painting_i     = 'ch_prop_vault_painting_01i',
    painting_j     = 'ch_prop_vault_painting_01j',
    h4_painting_e  = 'h4_prop_h4_painting_01e',
    h4_painting_f  = 'h4_prop_h4_painting_01f',
    -- display loot (pacific / vangelico glass case)
    loot_diamond      = 'h4_prop_h4_diamond_01a',
    loot_diamond_disp = 'h4_prop_h4_diamond_disp_01a',
    loot_necklace     = 'h4_prop_h4_necklace_01a',
    loot_necklace_disp= 'h4_prop_h4_neck_disp_01a',
    loot_panther      = 'h4_prop_h4_art_pant_01a',
    loot_bottle       = 'h4_prop_h4_t_bottle_02b',
    loot_pogo         = 'vw_prop_vw_pogo_gold_01a',
    -- jewel cases (model swap start -> end)
    jewel_cab      = 'des_jewel_cab_start',
    jewel_cab2     = 'des_jewel_cab2_start',
    jewel_cab3     = 'des_jewel_cab3_start',
    jewel_cab4     = 'des_jewel_cab4_start',
    -- train container
    container      = 'tr_prop_tr_container_01a',
    container_lock = 'tr_prop_tr_lock_01a',
    grinder        = 'tr_prop_tr_grinder_01a',
    container_desk = 'xm_prop_lab_desk_02',
    -- humane labs
    grill          = 'prop_chem_grill',
    grill_bit      = 'prop_chem_grill_bit',
    gas_cutter     = 'prop_cs_gascutter_1',
    vial_tube      = 'prop_cs_vial_01',
    vial           = 'p_chem_vial_02b_s',
    -- rappel
    rope_hook      = 'prop_rope_hook_01',
    -- kidnapping
    head_bag       = 'prop_money_bag_01',
    torture_chair  = 'prop_torture_ch_01',
    wrench         = 'prop_cs_wrench',
    jerrycan       = 'w_am_jerrycan',
    rag            = 'p_loose_rag_01_s',
    pliers         = 'prop_pliers_01',
    -- vault / bank doors
    fleeca_gate    = 'v_ilev_gb_teldr',
    fleeca_vault   = 'v_ilev_gb_vauldr',
    fleeca_vault2  = 'hei_prop_heist_sec_door',
    pacific_vault  = 'v_ilev_bk_vaultdoor',
    casino_vault   = 'ch_prop_ch_vaultdoor01x',
    gate_pris      = 'hei_v_ilev_bk_gate_pris',
    gate_molten    = 'hei_v_ilev_bk_gate_molten',
    gate2_pris     = 'hei_v_ilev_bk_gate2_pris',
    gate2_molten   = 'hei_v_ilev_bk_gate2_molten',
    safegate_pris  = 'hei_v_ilev_bk_safegate_pris',
    safegate_molten= 'hei_v_ilev_bk_safegate_molten',
}

-- Trolley model -> prop shown in the hand while grabbing
Config.TrolleyGrab = {
    hei_prop_hei_cash_trolly_01 = 'hei_prop_heist_cash_pile',
    ch_prop_ch_cash_trolly_01b  = 'hei_prop_heist_cash_pile',
    ch_prop_gold_trolly_01a     = 'ch_prop_gold_bar_01a',
    ch_prop_diamond_trolly_01c  = 'ch_prop_vault_dimaondbox_01a',
    imp_prop_impexp_coke_trolly = 'prop_coke_block_half_a',
}

-- Jewel case model swaps (start -> end)
Config.JewelSwap = {
    des_jewel_cab_start  = 'des_jewel_cab_end',
    des_jewel_cab2_start = 'des_jewel_cab2_end',
    des_jewel_cab3_start = 'des_jewel_cab3_end',
    des_jewel_cab4_start = 'des_jewel_cab4_end',
}

-- Scene data (dict + clips + timings)
-- speed = default scene rate; ms = how long a step waits at that rate
Config.Scenes = {
    till = { dict = 'mp_am_hold_up', ped = 'holdup_victim_20s', till = 'holdup_victim_20s_till', bag = 'holdup_victim_20s_bag', ms = 21566 },
    safe = {
        dict = 'anim@scripted@heist@ig15_safe_crack@male@',
        steps = {
            { 'idle_player', 'idle_safe', 'idle_bag', 'idle_cam', 10000 },
            { 'door_open_player', 'door_open_safe', 'door_open_bag', 'door_open_cam', 2533 },
            { 'success_with_stack_bonds_player', 'success_with_stack_bonds_safe', 'success_with_stack_bonds_bag', 'success_with_stack_bonds_cam', 1799 },
            { 'exit_player', 'exit_safe', 'exit_bag', 'exit_cam', 666 },
        },
    },
    terminal = { dict = 'anim@heists@prison_heiststation@cop_reactions', clip = 'cop_b_idle' },
    teller = { dict = 'mp_missheist_ruralbank', clip = 'heist_ruralbank_male', speed = 1.3 },
    handsup = { dict = 'missminuteman_1ig_2', clip = 'handsup_enter' },
    grabCash = { dict = 'anim@scripted@heist@ig1_table_grab@cash@male@', stack = 'grab_cash', speed = 1.3 },
    grabGold = { dict = 'anim@scripted@heist@ig1_table_grab@gold@male@', stack = 'grab_gold', speed = 1.3 },
    trolley = { dict = 'anim@heists@ornate_bank@grab_cash', speed = 1.3, intro = 1750, grab = 37000, exit = 2000 },
    drill = {
        dict = 'anim_heist@hs3f@ig9_vault_drill@laser_drill@', speed = 1.3,
        intro = { 'intro', 'bag_intro', 'intro_drill_bit', 'intro_cam' },
        start = { 'drill_straight_start', 'bag_drill_straight_start', 'drill_straight_start_drill_bit', 'drill_straight_start_cam' },
        idle  = { 'drill_straight_end_idle', 'bag_drill_straight_idle', 'drill_straight_idle_drill_bit', 'drill_straight_idle_cam' },
        fail  = { 'drill_straight_fail', 'bag_drill_straight_fail', 'drill_straight_fail_drill_bit', 'drill_straight_fail_cam' },
        stop  = { 'drill_straight_end', 'bag_drill_straight_end', 'drill_straight_end_drill_bit', 'drill_straight_end_cam' },
        exit  = { 'exit', 'bag_exit', 'exit_drill_bit', 'exit_cam' },
        sound = { name = 'Drill', set = 'DLC_HEIST_FLEECA_SOUNDSET', banks = { 'DLC_HEIST_FLEECA_SOUNDSET', 'DLC_MPHEIST\\HEIST_FLEECA_DRILL', 'DLC_MPHEIST\\HEIST_FLEECA_DRILL_2' } },
    },
    thermite = {
        dict = 'anim@heists@ornate_bank@thermal_charge', clip = 'thermal_charge', bag = 'bag_thermal_charge', speed = 1.3,
        bone = 28422, attachRot = vector3(0.0, 0.0, 200.0),
        ptfxAsset = 'scr_ornate_heist', ptfx = 'scr_heist_ornate_thermal_burn', burn = 13000,
    },
    fob = { dict = 'anim@mp_player_intmenu@key_fob@', clip = 'fob_click_fp' },
    laptop = {
        dict = 'anim@heists@ornate_bank@hack', speed = 1.3,
        steps = {
            { 'hack_enter', 'hack_enter_bag', 'hack_enter_laptop', 'hack_enter_card', 6300 },
            { 'hack_loop', 'hack_loop_bag', 'hack_loop_laptop', 'hack_loop_card', 2000 },
            { 'hack_exit', 'hack_exit_bag', 'hack_exit_laptop', 'hack_exit_card', 4600 },
        },
    },
    keypad = {
        dict = 'anim_heist@hs3f@ig1_hack_keypad@arcade@male@', speed = 1.3,
        action  = { 'action_var_01', 'action_var_01_ch_prop_ch_usb_drive01x', 'action_var_01_prop_phone_ing', 4000 },
        loop    = { 'hack_loop_var_01', 'hack_loop_var_01_ch_prop_ch_usb_drive01x', 'hack_loop_var_01_prop_phone_ing', 2000 },
        success = { 'success_react_exit_var_01', 'success_react_exit_var_01_ch_prop_ch_usb_drive01x', 'success_react_exit_var_01_prop_phone_ing', 4000 },
        fail    = { 'fail_react', 'fail_react_ch_prop_ch_usb_drive01x', 'fail_react_prop_phone_ing', 4000 },
        retry   = { 'reattempt', 'reattempt_ch_prop_ch_usb_drive01x', 'reattempt_prop_phone_ing', 1800 },
    },
    card = { dict = 'anim_heist@hs3f@ig3_cardswipe@male@', clip = 'success_var01', card = 'success_var01_card', speed = 1.3, ms = 3000 },
    glass = {
        dict = 'anim@scripted@heist@ig16_glass_cut@male@', speed = 1.3,
        steps = {
            { 'enter', 'enter_bag', 'enter_cutter', 'enter_glass_display', 'enter_cam' },
            { 'idle', 'idle_bag', 'idle_cutter', 'idle_glass_display', 'idle_cam' },
            { 'cutting_loop', 'cutting_loop_bag', 'cutting_loop_cutter', 'cutting_loop_glass_display', 'cutting_loop_cam' },
            { 'overheat_react_01', 'overheat_react_01_bag', 'overheat_react_01_cutter', 'overheat_react_01_glass_display', 'overheat_react_01_cam' },
            { 'success', 'success_bag', 'success_cutter', 'success_glass_display_cut', 'success_cam' },
        },
        audioBank = 'DLC_HEI4/DLCHEI4_GENERIC_01', soundSet = 'DLC_H4_anims_glass_cutter_Sounds',
        ptfxAsset = 'scr_ih_fin', ptfxCut = 'scr_ih_fin_glass_cutter_cut', ptfxHeat = 'scr_ih_fin_glass_cutter_overheat',
    },
    painting = {
        dict = 'anim_heist@hs3f@ig11_steal_painting@male@',
        -- ped clip, painting clip, bag clip, knife clip, cam clip, ms (how long each step waits)
        steps = {
            { 'top_left_enter', 'ver_01_top_left_enter_cam_ble', 3000 },
            { 'cutting_top_left_idle', 'ver_01_cutting_top_left_idle_cam', 1500 },
            { 'cutting_top_left_to_right', 'ver_01_cutting_top_left_to_right_cam', 3000 },
            { 'cutting_top_right_idle', 'ver_01_cutting_top_right_idle_cam', 1500 },
            { 'cutting_right_top_to_bottom', 'ver_01_cutting_right_top_to_bottom_cam', 3000 },
            { 'cutting_bottom_right_idle', 'ver_01_cutting_bottom_right_idle_cam', 1500 },
            { 'cutting_bottom_right_to_left', 'ver_01_cutting_bottom_right_to_left_cam', 4500 },
            { 'cutting_left_top_to_bottom', 'ver_01_cutting_left_top_to_bottom_cam', 1500 },
            { 'with_painting_exit', nil, 7500 },
        },
    },
    smash = {
        dict = 'missheist_jewel', speed = 1.3,
        clips = { 'smash_case_necklace', 'smash_case_d', 'smash_case_e', 'smash_case_f' },
        skull = 'smash_case_necklace_skull',
        ptfxAsset = 'scr_jewelheist', ptfx = 'scr_jewel_cab_smash', sound = 'Glass_Smash',
        gas = 'scr_jewel_fog_volume',
    },
    mask = { dict = 'mp_masks@standard_car@ds@', clip = 'put_on_mask', ms = 800 },
    lockbox = {
        dicts = {
            'anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_01@male@',
            'anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_02@male@',
            'anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_03@male@',
            'anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_04@male@',
        },
        speed = 1.3, chance = 60,
        -- step = ped clip; props: cabinet, drill, bag, moneybag (reward only)
        props = { 'ch_prop_ch_sec_cabinet_01abc', 'ch_prop_vault_drill_01a', 'p_m_bag_var22_arm_s', 'ch_prop_ch_moneybag_01a' },
    },
    rappel = { dict = 'missrappel', idle = 'rappel_idle', walk = 'rappel_walk', slide = 'rope_slide' },
    blowtorch = {
        def = 'mini@biotech@blowtorch_def', str = 'mini@biotech@blowtorch_str', network = 'minigame_BLOWTORCH',
        introCam = 'cam_blowtorch_intro', outro = 'blowtorch_success_outro', outroGrill = 'prop_grill_BLOWTORCH_SUCCESS_OUTRO', outroCam = 'cam_blowtorch_success_outro',
        ptfxAsset = 'scr_fbi5a', ptfxCut = 'scr_bio_grille_cutting', ptfxBreak = 'scr_bio_grille_break',
        -- cut points: x/y move network signals + break ptfx offset on the grill bit (humane labs minigameTable)
        points = {
            { 0.215, 0.92, vector3(-0.645, -0.03, 0.90), 'h' }, { 0.355, 0.92, vector3(-0.375, -0.03, 0.90), 'h' },
            { 0.465, 0.92, vector3(-0.125, -0.03, 0.90), 'h' }, { 0.59, 0.92, vector3(0.125, -0.03, 0.90), 'h' },
            { 0.715, 0.92, vector3(0.375, -0.03, 0.90), 'h' }, { 0.83, 0.92, vector3(0.625, -0.03, 0.90), 'h' },
            { 0.145, 0.88, vector3(-0.775, -0.03, 0.77), 'v' }, { 0.145, 0.74, vector3(-0.775, -0.03, 0.52), 'v' },
            { 0.145, 0.62, vector3(-0.775, -0.03, 0.27), 'v' },
        },
    },
    takeChemical = { dict = 'missfbi5ig_22', ped = 'take_chemical_player0', tube = 'take_chemical_tube', vial = 'take_chemical_vial', cam = 'take_chemical_cam', z = 1.0 },
    putChemical  = { dict = 'missfbi5ig_33', ped = 'put_in_vial_player0', tube = 'put_in_vial_tube', vial = 'put_in_vial_vial', cam = 'put_in_vial_cam', z = 1.35, cut = 2000 },
    bagHead = { dict = 'random@shop_robbery', clip = 'robbery_action_b', bone = 12844, offset = vector3(0.2, 0.04, 0.0), rot = vector3(0.0, 270.0, 60.0), ms = 2000 },
    knockout = { dict = 'misschinese1leadinoutchinese_1_int', player = 'husb_leadin_action', victim = 'russ_leadin_action', ms = 6000 },
    interrogate = {
        wrench = { dict = 'missfbi3_wrench', prop = 'prop_cs_wrench', steps = {
            { 'wrench_idle', 1500 }, { 'wrench_attack_left', 5000 }, { 'wrench_attack_mid', 5000 }, { 'wrench_attack_right', 5000 } } },
        waterboard = { dict = 'missfbi3_waterboard', props = { 'w_am_jerrycan', 'p_loose_rag_01_s' }, steps = {
            { 'waterboard_idle', 1500 }, { 'waterboard_kick', 15000 }, { 'waterboard_loop', 7500 }, { 'waterboard_outro', 5000 } } },
        toothpull = { dict = 'missfbi3_toothpull', prop = 'prop_pliers_01', x = 0.25, steps = {
            { 'pull_tooth_intro', 2000 }, { 'pull_tooth_idle', 5000 }, { 'pull_tooth_loop', 7500 }, { 'pull_tooth_outro_b', 10000 } } },
    },
    laptopDesk = { dict = 'switch@franklin@on_laptop', steps = {
        { '001927_01_fras_v2_4_on_laptop_idle', '001927_01_fras_v2_4_on_laptop_idle_laptop', 5000 },
        { '001927_01_fras_v2_4_on_laptop_exit', '001927_01_fras_v2_4_on_laptop_exit_laptop', 5000 } } },
    container = {
        dict = 'anim@scripted@player@mission@tunf_train_ig1_container_p1@male@',
        ped = 'action', container = 'action_container', lock = 'action_lock', grinder = 'action_angle_grinder', bag = 'action_bag',
        ptfxAsset = 'scr_tn_tr', ptfx = 'scr_tn_tr_angle_grinder_sparks', sparkAt = 4000, sparkFor = 1000,
    },
}

-- Cutscenes (PlayCutscene name)
Config.Cutscenes = {
    buyer = 'hs3f_all_drp3', rappelTop = 'hs3f_mul_rp1', rappelBottom = 'hs3f_mul_rp2', casinoVault = 'hs3f_mul_vlt', jewelStart = 'JH_2A_MCS_1',
}

-- World spots for robbery scripts and tests
Config.Spots = {
    -- 24/7 + LTD shops: clerk ped, safe (heading - 180 when spawned)
    shops = {
        { ped = vec4(2676.61, 3280.18, 54.24, 328.88), safe = vec4(2674.7, 3288.57, 54.24, 154.33) },
        { ped = vec4(-2966.25, 391.53, 15.04, 86.9), safe = vec4(-2959.03, 387.61, 13.04, 0.58) },
        { ped = vec4(1959.43, 3741.15, 32.34, 300.68), safe = vec4(1961.91, 3749.47, 31.34, 119.41) },
        { ped = vec4(1697.53, 4923.12, 42.06, 325.96), safe = vec4(1707.32, 4919.07, 41.06, 57.39) },
        { ped = vec4(372.85, 327.87, 103.57, 247.13), safe = vec4(380.37, 332.08, 102.57, 77.41) },
        { ped = vec4(1134.15, -983.28, 46.42, 277.94), safe = vec4(1126.24, -980.77, 44.42, 184.81) },
        { ped = vec4(1164.93, -323.53, 69.21, 103.01), safe = vec4(1160.77, -313.69, 68.21, 192.51) },
        { ped = vec4(-706.09, -914.6, 19.22, 91.94), safe = vec4(-708.58, -904.25, 18.22, 181.12) },
        { ped = vec4(-1221.29, -908.03, 12.33, 34.85), safe = vec4(-1220.04, -916.32, 10.33, 302.49) },
        { ped = vec4(-1486.7, -377.5, 40.16, 138.08), safe = vec4(-1479.06, -374.17, 38.16, 50.64) },
        { ped = vec4(-47.17, -1758.37, 29.42, 50.71), safe = vec4(-42.26, -1749.3, 28.42, 138.63) },
        { ped = vec4(24.14, -1345.66, 28.5, 272.08), safe = vec4(30.96, -1339.91, 28.5, 89.05) },
    },
    -- Fleeca banks (index 6 = Legion Square)
    fleeca = {
        { teller = vector3(-2958.695, 478.2697, 14.7), tellerRot = vector3(0.0, 0.0, -92.24812), doorHeading = 300.0, grab = vec4(-2954.2, 484.377, 15.525, 270.0),
          drills = { { vector3(-2952.2, 484.135, 15.9253), 265.0 }, { vector3(-2954.0, 486.676, 15.9253), 355.0 }, { vector3(-2954.2, 482.120, 15.9253), 185.0 } },
          trolleys = { vec4(-2957.3, 485.690, 14.6753, 178.0), vec4(-2958.4, 484.099, 14.6753, 268.0) } },
        { teller = vector3(-1214.835, -336.3697, 36.78), tellerRot = vector3(0.0, 0.0, -152.9346), doorHeading = 240.0, grab = vec4(-1207.6, -337.40, 37.6093, 210.0),
          drills = { { vector3(-1205.1, -336.54, 37.9593), -60.0 }, { vector3(-1206.4, -339.10, 37.9593), 200.0 }, { vector3(-1209.1, -338.87, 37.9593), 120.0 } },
          trolleys = { vec4(-1207.6, -333.89, 36.7592, 118.0), vec4(-1209.4, -333.79, 36.7592, 208.0) } },
        { teller = vector3(-356.5303, -52.26782, 48.05), tellerRot = vector3(0.0, 0.0, -198.9691), doorHeading = 200.0, grab = vec4(-352.23, -58.215, 48.848, 160.0),
          drills = { { vector3(-354.15, -57.592, 49.3147), 75.0 }, { vector3(-352.81, -60.155, 49.3147), 160.0 }, { vector3(-349.70, -59.020, 49.3147), 260.0 } },
          trolleys = { vec4(-349.86, -55.756, 48.0148, 70.0), vec4(-351.02, -54.136, 48.0148, 162.0) } },
        { teller = vector3(308.598, -281.3508, 53.16), tellerRot = vector3(0.0, 0.0, -200.1235), doorHeading = 200.0, grab = vec4(312.756, -287.41, 54.0, 160.0),
          drills = { { vector3(310.867, -286.82, 54.4430), 75.0 }, { vector3(312.411, -289.41, 54.4430), 160.0 }, { vector3(315.230, -288.20, 54.4430), 260.0 } },
          trolleys = { vec4(315.230, -284.93, 53.1430, 70.0), vec4(314.184, -283.42, 53.1430, 160.0) } },
        { teller = vector3(1179.56, 2710.876, 37.09), tellerRot = vector3(0.0, 0.0, 0.2100044), doorHeading = 40.0, grab = vec4(1173.45, 2715.08, 37.9162, 360.0),
          drills = { { vector3(1173.34, 2717.16, 38.3363), 0.0 }, { vector3(1175.52, 2715.16, 38.3363), 275.0 }, { vector3(1170.95, 2715.26, 38.3363), 90.0 } },
          trolleys = { vec4(1172.02, 2712.01, 37.0662, 270.0), vec4(1173.69, 2710.93, 37.0662, 0.0) } },
        { teller = vector3(144.2593, -1042.969, 28.37), tellerRot = vector3(0.0, 0.0, -200.384), doorHeading = 200.0, grab = vec4(148.431, -1049.1, 29.19, 160.0),
          drills = { { vector3(146.459, -1048.4, 29.6162), 70.0 }, { vector3(148.095, -1051.1, 29.6162), 170.0 }, { vector3(150.969, -1049.8, 29.6162), 250.0 } },
          trolleys = { vec4(151.036, -1046.6, 28.3462, 70.0), vec4(149.887, -1045.1, 28.3462, 160.0) } },
    },
    -- Pacific Standard
    pacific = {
        thermite = {
            { scene = vector3(257.40, 220.20, 106.35), rot = vector3(0.0, 0.0, 336.48), ptfx = vector3(257.39, 221.20, 106.29), door = vector3(257.10, 220.30, 106.28), from = 'hei_v_ilev_bk_gate_pris', to = 'hei_v_ilev_bk_gate_molten' },
            { scene = vector3(261.75, 221.420, 106.35), rot = vector3(0.0, 0.0, 255.48), ptfx = vector3(261.80, 222.470, 106.283), door = vector3(262.35, 223.00, 107.05), from = 'hei_v_ilev_bk_gate2_pris', to = 'hei_v_ilev_bk_gate2_molten' },
            { scene = vector3(252.95, 220.70, 101.76), rot = vector3(0.0, 0.0, 160.0), ptfx = vector3(252.985, 221.70, 101.72), door = vector3(252.72, 220.95, 101.68), from = 'hei_v_ilev_bk_safegate_pris', to = 'hei_v_ilev_bk_safegate_molten' },
            { scene = vector3(261.65, 215.60, 101.76), rot = vector3(0.0, 0.0, 252.0), ptfx = vector3(261.68, 216.63, 101.75), door = vector3(261.01, 215.01, 101.68), from = 'hei_v_ilev_bk_safegate_pris', to = 'hei_v_ilev_bk_safegate_molten' },
        },
        vault = { model = 'v_ilev_bk_vaultdoor', coords = vector3(253.92, 224.56, 101.88), open = 75.0, step = -0.15 },
        laserVault = { scene = vector3(257.35, 240.312, 102.0), rot = vector3(0.0, 0.0, 340.0), model = 'ch_prop_ch_vaultdoor01x', coords = vector3(256.518, 240.101, 101.701), open = 250.0, step = 0.15 },
        mainStack = vec4(264.265, 213.735, 101.531, 250.0),
        drills = { { vector3(258.267, 213.848, 101.883), 160.0 }, { vector3(259.682, 218.327, 101.883), 350.0 } },
        trolleys = {
            { 'ch_prop_ch_cash_trolly_01b', vec4(266.351, 215.192, 100.683, 115.0) }, { 'ch_prop_gold_trolly_01a', vec4(265.107, 211.960, 100.683, 35.0) },
            { 'imp_prop_impexp_coke_trolly', vec4(261.623, 213.510, 100.683, 300.0) }, { 'ch_prop_diamond_trolly_01c', vec4(262.819, 216.429, 100.683, 200.0) },
        },
        bombs = {
            { vector3(260.399, 242.955, 101.801), 250.0 }, { vector3(262.399, 248.455, 101.801), 250.0 }, { vector3(264.409, 254.055, 101.801), 250.0 },
            { vector3(255.205, 244.726, 101.801), 70.0 }, { vector3(257.205, 250.276, 101.801), 70.0 }, { vector3(259.225, 255.886, 101.801), 70.0 },
        },
        glass = { display = vec4(263.925, 260.656, 100.633, 340.0), loot = vector3(263.925, 260.656, 101.6721) },
        paintings = {
            { scene = vector3(266.575, 259.565, 101.663), rot = 250.0, model = 'h4_prop_h4_painting_01e', coords = vec4(267.025, 259.545, 101.853, 250.0) },
            { scene = vector3(261.302, 261.792, 101.663), rot = 70.0, model = 'h4_prop_h4_painting_01f', coords = vec4(260.842, 261.932, 101.853, 70.85) },
        },
    },
    -- Vangelico (scene = where the ped stands, case = the glass case)
    vangelico = {
        glass = { display = vec4(-617.4622, -227.4347, 37.057, -53.06), loot = vector3(-617.4622, -227.4347, 38.0861) },
        paintings = {
            { scene = vector3(-626.70, -228.3, 38.06), rot = 90.0, model = 'ch_prop_vault_painting_01g', coords = vec4(-627.20, -228.31, 38.06, 94.75) },
        },
        gas = vector3(-622.0, -231.0, 38.0),
        cases = {
            { case = vector3(-627.735, -234.439, 37.875), scene = vector3(-628.187, -233.538, 37.0946), rot = -144.0, model = 'des_jewel_cab_start' },
            { case = vector3(-626.716, -233.685, 37.8583), scene = vector3(-627.136, -232.775, 37.0946), rot = -144.0, model = 'des_jewel_cab_start' },
            { case = vector3(-627.35, -234.947, 37.8531), scene = vector3(-626.62, -235.725, 37.0946), rot = 36.0, model = 'des_jewel_cab3_start' },
            { case = vector3(-626.298, -234.193, 37.8492), scene = vector3(-625.57, -234.962, 37.0946), rot = 36.0, model = 'des_jewel_cab4_start', skull = true },
            { case = vector3(-626.399, -239.132, 37.8616), scene = vector3(-626.894, -238.2, 37.0856), rot = -144.0, model = 'des_jewel_cab2_start' },
            { case = vector3(-625.376, -238.358, 37.8687), scene = vector3(-625.867, -237.458, 37.0946), rot = -144.0, model = 'des_jewel_cab3_start' },
            { case = vector3(-625.517, -227.421, 37.86), scene = vector3(-624.738, -228.2, 37.0946), rot = 36.0, model = 'des_jewel_cab3_start' },
            { case = vector3(-624.467, -226.653, 37.861), scene = vector3(-623.688, -227.437, 37.0946), rot = 36.0, model = 'des_jewel_cab4_start', skull = true },
            { case = vector3(-623.8118, -228.6336, 37.8522), scene = vector3(-624.293, -227.831, 37.0946), rot = -143.511, model = 'des_jewel_cab2_start' },
            { case = vector3(-624.1267, -230.7476, 37.8618), scene = vector3(-624.939, -231.247, 37.0946), rot = -54.13, model = 'des_jewel_cab4_start', skull = true },
            { case = vector3(-621.7181, -228.9636, 37.8425), scene = vector3(-620.864, -228.481, 37.0946), rot = 126.925, model = 'des_jewel_cab3_start' },
            { case = vector3(-622.7541, -232.614, 37.8638), scene = vector3(-623.3596, -233.2296, 37.0946), rot = -52.984, model = 'des_jewel_cab_start' },
            { case = vector3(-620.3262, -230.829, 37.8578), scene = vector3(-619.408, -230.1969, 37.0946), rot = 126.352, model = 'des_jewel_cab_start' },
            { case = vector3(-620.6465, -232.9308, 37.8407), scene = vector3(-620.184, -233.729, 37.0946), rot = 36.398, model = 'des_jewel_cab4_start', skull = true },
            { case = vector3(-619.978, -234.93, 37.8537), scene = vector3(-620.44, -234.084, 37.0946), rot = -144.0, model = 'des_jewel_cab_start' },
            { case = vector3(-618.937, -234.16, 37.8425), scene = vector3(-619.39, -233.32, 37.0946), rot = -144.0, model = 'des_jewel_cab3_start' },
            { case = vector3(-620.163, -226.212, 37.8266), scene = vector3(-620.797, -226.79, 37.0946), rot = -54.0, model = 'des_jewel_cab_start' },
            { case = vector3(-619.384, -227.259, 37.8342), scene = vector3(-620.055, -227.817, 37.0856), rot = -54.0, model = 'des_jewel_cab2_start' },
            { case = vector3(-618.019, -229.115, 37.8302), scene = vector3(-618.679, -229.704, 37.0946), rot = -54.0, model = 'des_jewel_cab3_start' },
            { case = vector3(-617.249, -230.156, 37.8201), scene = vector3(-617.937, -230.731, 37.0856), rot = -54.0, model = 'des_jewel_cab2_start' },
        },
    },
    -- Humane Labs
    humane = {
        grill = { coords = vector3(3832.85, 3665.67, -23.0), rot = 150.0, ped = vec4(3832.896, 3665.742, -23.9975, 150.0), scene = vector3(3832.8, 3665.63, -24.14) },
        takeChemical = vec4(3558.898, 3677.85, 27.125, 170.0),
    },
}
