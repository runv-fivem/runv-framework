Config = {}

-- Flags read by game/util.lua
Config.AutomaticFade = false
Config.RCoreTattoosCompatibility = false
Config.Peds = { pedConfig = { { peds = { 'mp_m_freemode_01', 'mp_f_freemode_01' } } } }

Config.Models = { male = 'mp_m_freemode_01', female = 'mp_f_freemode_01' }

-- Clothes every new player gets. Players can't pick clothes in the creator
-- { component_id, drawable, texture }
Config.DefaultClothes = {
    male = {
        { component_id = 1, drawable = 0, texture = 0 },   -- mask
        { component_id = 3, drawable = 15, texture = 0 },  -- arms (bare)
        { component_id = 4, drawable = 61, texture = 0 },  -- legs
        { component_id = 5, drawable = 0, texture = 0 },   -- bag
        { component_id = 6, drawable = 34, texture = 0 },  -- shoes (barefoot)
        { component_id = 7, drawable = 0, texture = 0 },   -- accessory
        { component_id = 8, drawable = 15, texture = 0 },  -- undershirt (none)
        { component_id = 9, drawable = 0, texture = 0 },   -- armor
        { component_id = 10, drawable = 0, texture = 0 },  -- decals
        { component_id = 11, drawable = 15, texture = 0 }, -- top (none)
    },
    female = {
        { component_id = 1, drawable = 0, texture = 0 },
        { component_id = 3, drawable = 15, texture = 0 },
        { component_id = 4, drawable = 15, texture = 0 },
        { component_id = 5, drawable = 0, texture = 0 },
        { component_id = 6, drawable = 35, texture = 0 },
        { component_id = 7, drawable = 0, texture = 0 },
        { component_id = 8, drawable = 14, texture = 0 },
        { component_id = 9, drawable = 0, texture = 0 },
        { component_id = 10, drawable = 0, texture = 0 },
        { component_id = 11, drawable = 15, texture = 0 },
    },
}

-- Creator options (FACE tab). Faces = head blend parent ids
Config.Faces = {
    male = { 0, 1, 2, 3, 4, 5, 6, 7 },
    female = { 21, 22, 23, 24, 25, 26, 27, 28 },
}

-- Skin swatch color -> skin parent id
Config.SkinTones = {
    { hex = '#f4dbc1', id = 21 },
    { hex = '#e9c6a2', id = 0 },
    { hex = '#cea480', id = 6 },
    { hex = '#b58666', id = 3 },
    { hex = '#9d755a', id = 14 },
    { hex = '#916a53', id = 1 },
}

-- Eye swatch color -> GTA eye color index (constants.EYE_COLORS, 0-based)
Config.EyeColors = {
    { hex = '#4b2f1c', id = 5 },
    { hex = '#714929', id = 4 },
    { hex = '#816535', id = 6 },
    { hex = '#536a4c', id = 0 },
    { hex = '#526877', id = 3 },
    { hex = '#8a8d87', id = 8 },
}

-- Hair / eyebrow / beard palette. The client maps each swatch
-- to the nearest GTA hair color index with GetPedHairRgbColor
Config.HairPalette = {
    '#e7e2d5', '#c9c3bb', '#a49e94', '#807871', '#564f4a', '#222626',
    '#af9471', '#c5a968', '#aa8853', '#a77840', '#7a5738', '#5c402d',
    '#8b6046', '#704733', '#5a3426', '#422a22', '#32221d', '#292322',
    '#b3693a', '#9c4f35', '#7f3d35', '#6c3239', '#593546', '#483d52',
    '#5b7b63', '#4f6a68', '#4a5f73', '#59608a', '#6a5a79', '#6e4964',
}

-- HAIR tab: hair drawables (component 2)
Config.Hair = {
    male = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
    female = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
}

-- BEARD tab (male only): head overlay 1 styles, -1 = none
Config.Beards = { -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

-- SCARS tab: head overlay 0 (blemishes) styles, -1 = none
Config.Scars = { -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
