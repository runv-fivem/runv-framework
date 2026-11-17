-- Login: returning player -> sitting scene + PLAY. New player -> nickname -> creator

local cam = nil

local function startCamera(ped, offset, look, fov)
    local from = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z)
    local to = GetOffsetFromEntityInWorldCoords(ped, look.x, look.y, look.z)
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', from.x, from.y, from.z, 0.0, 0.0, 0.0, fov, true, 2)
    PointCamAtCoord(cam, to.x, to.y, to.z)
    RenderScriptCams(true, false, 0, true, true)
end

local function stopCamera()
    RenderScriptCams(false, false, 0, true, true)
    if cam then DestroyCam(cam, false) end
    cam = nil
end

-- First spawn of the session (autospawn is off in rnv-core)
local function spawnAt(coords, model)
    local p = promise.new()
    exports.spawnmanager:spawnPlayer({ x = coords.x, y = coords.y, z = coords.z, heading = coords.w, model = model }, function()
        p:resolve()
    end)
    Citizen.Await(p)
    ShutdownLoadingScreenNui()
    return PlayerPedId()
end

local function enterWorld()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    stopCamera()
    TriggerScreenblurFadeOut(0)

    -- Players who haven't escaped prison yet start there
    -- Unescaped players start in prison, everyone else at the Motel (rnv-world)
    local dest = Config.Spawn
    if GetResourceState('rnv-world') == 'started' then
        dest = exports['rnv-world']:GetMotelArrival()
    end
    if GetResourceState('rnv-prison') == 'started' then
        dest = exports['rnv-prison']:Admit() or dest
    end

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCoords(ped, dest.x, dest.y, dest.z, false, false, false, false)
    SetEntityHeading(ped, dest.w)
    DisplayRadar(true)
    LocalPlayer.state:set('rnv:spawned', true, false)

    DoScreenFadeIn(500)
end

local function showPlay(skin)
    local s = Config.Scene
    local ped = spawnAt(s.coords, skin.model)
    exports['rnv-appearance']:setPlayerAppearance(skin)
    ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    TaskStartScenarioAtPosition(ped, s.scenario, s.coords.x, s.coords.y, s.coords.z, s.coords.w, 0, true, true)
    startCamera(ped, s.camOffset, s.camLook, s.fov)
    SendNUIMessage({ action = 'play' })
    SetNuiFocus(true, true)
end

local function showNickname()
    local c = Config.Creator
    spawnAt(c.coords, 'mp_m_freemode_01')
    exports['rnv-appearance']:ApplyDefaults('male')
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    startCamera(ped, c.camOffset, c.camLook, c.fov)
    TriggerScreenblurFadeIn(0)
    SendNUIMessage({ action = 'nickname' })
    SetNuiFocus(true, true)
end

local function start()
    DisplayRadar(false)
    local skin = lib.callback.await('rnv-appearance:getSkin', false)
    if skin then showPlay(skin) else showNickname() end
end

RegisterNUICallback('play', function(_, cb)
    cb(1)
    enterWorld()
end)

local function submitNickname(name)
    local ok, err = lib.callback.await('rnv-login:setNickname', false, name)
    if not ok then
        return exports['rnv-interface']:Notify({ text = err == 'taken' and 'Nickname is taken' or '3-16 letters, numbers or _', type = 'error' })
    end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    TriggerScreenblurFadeOut(0)
    stopCamera()
    exports['rnv-appearance']:OpenCreator(function()
        enterWorld()
    end)
    return true
end

RegisterNUICallback('nickname', function(data, cb)
    cb({ ok = submitNickname(data.name) == true })
end)

exports('SubmitNickname', submitNickname) -- tests

AddEventHandler('rnv:client:onPlayerLoaded', function()
    if LocalPlayer.state['rnv:spawned'] then return end
    CreateThread(start)
end)

-- Dev: restarting this resource mid-login starts the flow again
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if exports['rnv-core']:IsLoggedIn() and not LocalPlayer.state['rnv:spawned'] then
        CreateThread(start)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    stopCamera()
    TriggerScreenblurFadeOut(0)
end)
