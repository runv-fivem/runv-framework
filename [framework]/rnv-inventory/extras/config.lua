-- Extras for the redesigned inventory UI. Nothing here changes rnv-inventory itself
Extras = {
    -- Dev helpers. Keep false on a live server
    Dev = true,

    -- Vests for armour slot 57: item = level. Max armour = level x 25 (one bar per armour plate). 'armour' = old item
    -- Body armour bars: Light 1, Medium 2, Assault 3, Heavy 4, Bastion 4
    -- Cash: at most this much money in one slot. More money opens another slot; split works as usual
    MoneyStack = 25000,

    Vests = { light_body_armor = 1, medium_body_armor = 2, assault_body_armor = 3, heavy_body_armor = 4, bastion_body_armor = 4 },

    -- Player layout (RUN V grid): slots 1-54 = BAG grid (6 x 9), 55/56 = weapons, 57 = armor, 58 = worn bag,
    -- 59 = pouch item, 60-63 = pouch cells (1x1 items only)
    --   kind = 'back'  : worn in slot 58. joaat('rows') = open grid rows while worn. joaat('back') = clothing on the character (component 5)
    --   kind = 'pouch' : worn in slot 59. joaat('cells') = open pouch cells
    Bag = {
        enabled = true,
        baseRows = 2, -- open grid rows with no bag
        items = {
            -- Sports Bag rows 2/4/6, added to the base rows; Versatile Pouch cells 1-4
            sports_bag_2 = { kind = 'back', rows = 4, back = { male = { 81, 0 }, female = { 81, 0 } } },
            sports_bag_3 = { kind = 'back', rows = 6, back = { male = { 81, 0 }, female = { 81, 0 } } },
            sports_bag_4 = { kind = 'back', rows = 8, back = { male = { 81, 0 }, female = { 81, 0 } } },
            versatile_pouch_1 = { kind = 'pouch', cells = 1 },
            versatile_pouch_2 = { kind = 'pouch', cells = 2 },
            versatile_pouch_3 = { kind = 'pouch', cells = 3 },
            versatile_pouch_4 = { kind = 'pouch', cells = 4 },
        },
    },


    -- Wardrobe icons left of the character: a click takes that piece off, another click puts it back
    -- joaat('prop') pieces are simply removed. Component pieces are swapped for the "nothing worn" drawables in joaat('off')
    -- (male / female online character); joaat('main') is the component that tells whether something is worn
    -- joaat('anim') = { dictionary, clip, milliseconds }
    Wear = {
        enabled = true,
        pieces = {
            { id = 'hat', label = 'Hat', prop = 0, anim = { 'mp_masks@standard_car@ds@', 'put_on_mask', 600 } },
            { id = 'glasses', label = 'Glasses', prop = 1, anim = { 'clothingspecs', 'take_off', 1400 } },
            { id = 'mask', label = 'Mask', main = 1, off = { male = { [1] = 0 }, female = { [1] = 0 } }, anim = { 'mp_masks@standard_car@ds@', 'put_on_mask', 800 } },
            { id = 'ear', label = 'Earrings', prop = 2, anim = { 'mp_cp_stolen_tut', 'b_think', 900 } },
            { id = 'top', label = 'Top', main = 11, off = { male = { [11] = 15, [8] = 15, [3] = 15, [10] = 0 }, female = { [11] = 15, [8] = 15, [3] = 15, [10] = 0 } }, anim = { 'clothingtie', 'try_tie_negative_a', 1200 } },
            { id = 'vest', label = 'Vest', main = 9, off = { male = { [9] = 0 }, female = { [9] = 0 } }, anim = { 'clothingtie', 'try_tie_negative_a', 1200 } },
            { id = 'neck', label = 'Necklace', main = 7, off = { male = { [7] = 0 }, female = { [7] = 0 } }, anim = { 'clothingtie', 'try_tie_positive_a', 2100 } },
            { id = 'bag', label = 'Bag', main = 5, off = { male = { [5] = 0 }, female = { [5] = 0 } }, anim = { 'anim@heists@ornate_bank@grab_cash', 'intro', 1600 } },
            { id = 'watch', label = 'Watch', prop = 6, anim = { 'nmt_3_rcm-10', 'cs_nigel_dual-10', 1200 } },
            { id = 'bracelet', label = 'Bracelet', prop = 7, anim = { 'nmt_3_rcm-10', 'cs_nigel_dual-10', 1200 } },
            { id = 'pants', label = 'Pants', main = 4, off = { male = { [4] = 21 }, female = { [4] = 15 } }, anim = { 're@construction', 'out_of_breath', 1300 } },
            { id = 'shoes', label = 'Shoes', main = 6, off = { male = { [6] = 34 }, female = { [6] = 35 } }, anim = { 'random@domestic', 'pickup_low', 1200 } },
        },
    },

    -- Weapon attachments view (right click a weapon > Attachments). One slot per component type from data/weapons.lua;
    -- joaat('bones') are the attachment points of the weapon model, the first one the model has is used. joaat('row') is where the slot sits
    Attach = {
        fill = 0.36, -- how much of the screen width the weapon takes at zoom 1
        light = 6.0, -- brightness of the lamp on the weapon
        slots = {
            { type = 'sight', label = 'Sight', row = 'top', bones = { 'WAPScop', 'WAPScop_2' } },
            { type = 'barrel', label = 'Barrel', row = 'top', bones = { 'WAPBarrel' } },
            { type = 'muzzle', label = 'Muzzle', row = 'top', bones = { 'WAPSupp', 'WAPSupp_2', 'Gun_Muzzle' } },
            { type = 'skin', label = 'Skin', row = 'top', bones = { 'Gun_GripR' } },
            { type = 'magazine', label = 'Magazine', row = 'bottom', bones = { 'WAPClip', 'WAPClip_2' } },
            { type = 'grip', label = 'Grip', row = 'bottom', bones = { 'WAPGrip', 'WAPGrip_2' } },
            { type = 'flashlight', label = 'Flashlight', row = 'bottom', bones = { 'WAPFlshLasr', 'WAPFlshLasr_2', 'WAPFlsh', 'WAPFlsh_2' } },
        },
    },

    -- Keys for hotbar slots 6 and up (rnv-inventory itself only binds 1 to 5)
    HotbarKeys = {}, -- keys 1-6 are bound in client.lua (weapons 55/56, pouch cells 60-63)
}

testIds = { 'TBX-123321' }