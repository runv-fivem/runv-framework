-- World helpers: vault doors, cutscenes, jewel store gas, spawning/finding props, data lookups

-- Swing a vault door to a heading
-- opts.entity, or opts.model + opts.coords (radius 50). opts.heading = open heading, opts.step =
-- degrees per tick (sign = direction; fleeca -0.5, pacific -0.15 / +0.15, casino +0.25), opts.async
local function openVaultDoor(opts)
    opts = opts or {}
    local door = opts.entity or (opts.model and opts.coords and RB.Find(opts.model, opts.coords, opts.radius or 50.0))
    if not door or not opts.heading then return false end
    local step = opts.step or -0.5
    local function swing()
        RB.Control(door)
        FreezeEntityPosition(door, true)
        local timeout = GetGameTimer() + 60000
        repeat
            SetEntityHeading(door, GetEntityHeading(door) + step)
            Wait(opts.interval or 10)
            local hd = GetEntityHeading(door)
            local done = (step < 0 and hd <= opts.heading) or (step > 0 and hd >= opts.heading)
        until done or GetGameTimer() > timeout
    end
    if opts.async then CreateThread(swing) else swing() end
    return true, door
end

-- Sets a door straight to a heading and freezes it (fix or reset a door)
local function setDoor(model, coords, heading)
    local door = RB.Find(model, coords, 5.0)
    if not door then return false end
    SetEntityHeading(door, heading)
    FreezeEntityPosition(door, true)
    return true, door
end

-- Plays a cutscene with the player in it. The player plays MP_1 (MP_2 with swap = true)
local function playCutscene(name, coords, swap)
    RequestCutscene(name, 8)
    local timeout = GetGameTimer() + 10000
    while not HasThisCutsceneLoaded(name) and GetGameTimer() < timeout do Wait(0) end
    if not HasThisCutsceneLoaded(name) then return false end
    local ped = PlayerPedId()
    -- the cutscene dresses the player in its own outfit: a hidden copy gives the look back afterwards
    local look = ClonePed(ped, false, false, true)
    SetEntityVisible(look, false, false)
    SetEntityCollision(look, false, false)
    FreezeEntityPosition(look, true)
    local clones = {}
    for i = 1, 4 do
        clones[i] = ClonePed(ped, false, false, true)
        SetEntityVisible(clones[i], false, false)
        SetEntityCollision(clones[i], false, false)
        FreezeEntityPosition(clones[i], true)
    end
    local slots = swap and { 'MP_2', 'MP_1', 'MP_3', 'MP_4', 'MP_5' } or { 'MP_1', 'MP_2', 'MP_3', 'MP_4', 'MP_5' }
    SetCutsceneEntityStreamingFlags(slots[1], 0, 1)
    RegisterEntityForCutscene(ped, slots[1], 0, GetEntityModel(ped), 64)
    for i = 2, 5 do
        SetCutsceneEntityStreamingFlags(slots[i], 0, 1)
        RegisterEntityForCutscene(clones[i - 1], slots[i], 0, GetEntityModel(clones[i - 1]), 64)
    end
    Wait(10)
    if coords then StartCutsceneAtCoords(coords.x, coords.y, coords.z, 0) else StartCutscene(0) end
    Wait(10)
    for _, c in ipairs(clones) do DeleteEntity(c) end
    Wait(50)
    DoScreenFadeIn(250)
    local faded = false
    repeat
        Wait(0)
        if GetCutsceneTotalDuration() - GetCutsceneTime() <= 250 and not faded then
            DoScreenFadeOut(250)
            faded = true
        end
    until not IsCutscenePlaying()
    if not faded then
        DoScreenFadeOut(100)
        Wait(150)
    end
    RemoveCutscene()
    ClonePedToTarget(look, ped)
    DeleteEntity(look)
    DoScreenFadeIn(500)
    return true
end

-- Knock-out gas cloud. Returns the ptfx handle (StopEffect)
local function jewelGas(coords, scale)
    local d = Config.Scenes.smash
    RB.LoadPtfx(d.ptfxAsset)
    UseParticleFxAsset(d.ptfxAsset)
    return StartParticleFxLoopedAtCoord(d.gas, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale or 0.5, false, false, false, false)
end

local function stopEffect(handle)
    StopParticleFxLooped(handle, false)
    return true
end

-- Spawns a networked prop by short name (Config.Models) or model name. rot (vector3) wins over heading
local function spawnProp(model, coords, heading, rot, networked)
    local obj = RB.Spawn(model, coords, heading, networked)
    if rot then SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true) end
    FreezeEntityPosition(obj, true)
    return obj
end

exports('OpenVaultDoor', openVaultDoor)
exports('SetDoor', setDoor)
exports('PlayCutscene', playCutscene)
exports('JewelGas', jewelGas)
exports('StopEffect', stopEffect)
exports('SpawnProp', spawnProp)
exports('FindProp', function(model, coords, radius) return RB.Find(model, coords, radius) end)
exports('GetModel', function(name) return Config.Models[name] end)
exports('GetData', function() return Config end)
