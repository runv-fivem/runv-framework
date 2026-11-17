-- Character creator (limited: face, hair, beard, scars). Uses the game/util.lua functions

local state = nil
local cam = nil
local onDone = nil

local function hexToRgb(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

-- Palette swatch -> nearest GTA hair color index
local function hairColorIndex(hex)
    local r, g, b = hexToRgb(hex)
    local best, bestDist = 0, math.huge
    for i = 0, GetNumHairColors() - 1 do
        local hr, hg, hb = GetPedHairRgbColor(i)
        local d = (hr - r) ^ 2 + (hg - g) ^ 2 + (hb - b) ^ 2
        if d < bestDist then best, bestDist = i, d end
    end
    return best
end

local function newState(gender)
    return { gender = gender, face = 1, skin = 1, eye = 1, brow = 6, hair = 1, hairColor = 6, beard = 1, beardColor = 6, scar = 1 }
end

local function applyDefaults(gender)
    client.setPlayerModel(Config.Models[gender])
    local ped = PlayerPedId()
    client.setPedComponents(ped, Config.DefaultClothes[gender])
    ClearAllPedProps(ped)
end

local function overlay(ped, index, style, color)
    if style < 0 then
        SetPedHeadOverlay(ped, index, 255, 0.0)
    else
        SetPedHeadOverlay(ped, index, style, 1.0)
        if color then SetPedHeadOverlayColor(ped, index, 1, color, color) end
    end
end

local function applyState()
    local ped = PlayerPedId()
    local s = state
    local face = Config.Faces[s.gender][s.face]
    local skin = Config.SkinTones[s.skin].id
    client.setPedHeadBlend(ped, {
        shapeFirst = face, shapeSecond = face, shapeThird = 0,
        skinFirst = skin, skinSecond = skin, skinThird = 0,
        shapeMix = 0.0, skinMix = 0.0, thirdMix = 0.0,
    })
    local hairColor = hairColorIndex(Config.HairPalette[s.hairColor])
    client.setPedHair(ped, { style = Config.Hair[s.gender][s.hair], texture = 0, color = hairColor, highlight = hairColor })
    SetPedEyeColor(ped, Config.EyeColors[s.eye].id)
    overlay(ped, 2, 0, hairColorIndex(Config.HairPalette[s.brow]))
    overlay(ped, 0, Config.Scars[s.scar])
    if s.gender == 'male' then
        overlay(ped, 1, Config.Beards[s.beard], hairColorIndex(Config.HairPalette[s.beardColor]))
    else
        overlay(ped, 1, -1)
    end
end

local function startCamera()
    local ped = PlayerPedId()
    local from = GetOffsetFromEntityInWorldCoords(ped, 0.45, 1.6, 0.45)
    local to = GetOffsetFromEntityInWorldCoords(ped, 0.45, 0.0, 0.45)
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', from.x, from.y, from.z, 0.0, 0.0, 0.0, 40.0, true, 2)
    PointCamAtCoord(cam, to.x, to.y, to.z)
    RenderScriptCams(true, false, 0, true, true)
end

local function stopCamera()
    RenderScriptCams(false, false, 0, true, true)
    if cam then DestroyCam(cam, false) end
    cam = nil
end

local function sendOptions()
    SendNUIMessage({
        action = 'creator:open',
        gender = state.gender,
        state = state,
        counts = {
            face = #Config.Faces[state.gender],
            hair = #Config.Hair[state.gender],
            beard = #Config.Beards,
            scar = #Config.Scars,
        },
        skin = Config.SkinTones,
        eye = Config.EyeColors,
        palette = Config.HairPalette,
    })
end

local function close()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'creator:close' })
    stopCamera()
end

---Opens the creator on the current ped. cb(appearance) runs after the skin is saved
local function openCreator(cb)
    onDone = cb
    state = newState(GetEntityModel(PlayerPedId()) == joaat(Config.Models.female) and 'female' or 'male')
    applyDefaults(state.gender)
    applyState()
    startCamera()
    sendOptions()
    SetNuiFocus(true, true)
end

RegisterNUICallback('creator:select', function(data, cb)
    if state and state[data.key] ~= nil and type(data.index) == 'number' then
        state[data.key] = data.index
        applyState()
    end
    cb(1)
end)

RegisterNUICallback('creator:gender', function(data, cb)
    if state and Config.Models[data.gender] and data.gender ~= state.gender then
        state = newState(data.gender)
        applyDefaults(state.gender)
        applyState()
        sendOptions()
    end
    cb(1)
end)

local function confirm()
    if not state then return end
    local appearance = client.getPedAppearance(PlayerPedId())
    if not lib.callback.await('rnv-appearance:saveSkin', false, appearance) then
        return exports['rnv-interface']:Notify({ text = 'Could not save appearance', type = 'error' })
    end
    close()
    state = nil
    local done = onDone
    onDone = nil
    if done then done(appearance) end
end

RegisterNUICallback('creator:confirm', function(_, cb)
    cb(1)
    confirm()
end)

RegisterNUICallback('creator:quit', function(_, cb)
    cb(1)
    ExecuteCommand('quit')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if state then close() end
end)

exports('OpenCreator', openCreator)
exports('ApplyDefaults', applyDefaults)
exports('ConfirmCreator', confirm) -- tests
