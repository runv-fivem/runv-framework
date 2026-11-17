-- rnv-robbase: robbery animation library. One export per scenario; it plays the full scene
-- (ped placed on the object, props spawned/attached, camera, ptfx, sound) and cleans up
-- It never gives items or money: the robbery script does that after `ok`
--
--   local rb = exports['rnv-robbase']
--   local ok = rb:GrabTrolley({ entity = trolley, label = 'GRABBING...', canCancel = true,
--       onPile = function(n) TriggerServerEvent('myrob:pile', n) end })
--   if ok then TriggerServerEvent('myrob:done') end
--
-- Common options (every player scene): label (rnv-interface Progress), canCancel (X),
-- camera (true/false, default = the scene's own), freeze, speed (scene rate),
-- duration (length of the loop part: drill, hack, trolley, safe), onDone(), onCancel()
-- Returns true on success, false on cancel/fail. Every export is listed above its function

RB = {}

local busy = false

function RB.Hash(model)
    if type(model) == 'number' then return model end
    return GetHashKey(Config.Models[model] or model)
end

function RB.LoadDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

function RB.LoadModel(model)
    local hash = RB.Hash(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    return hash
end

function RB.LoadPtfx(asset)
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 5000
    while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < timeout do Wait(0) end
end

-- Seconds of a clip -> ms at the given scene speed
function RB.Dur(dict, clip, speed)
    return math.floor(GetAnimDuration(dict, clip) * 1000 / (speed or 1.0))
end

function RB.Spawn(model, coords, heading, networked)
    local hash = RB.LoadModel(model)
    if networked == nil then networked = true end
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, networked, true, false)
    if heading then SetEntityHeading(obj, heading) end
    SetModelAsNoLongerNeeded(hash)
    return obj
end

function RB.Find(model, coords, radius)
    local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius or 2.0, RB.Hash(model), false, false, false)
    if obj ~= 0 then return obj end
    return nil
end

function RB.Control(entity)
    if not entity or not DoesEntityExist(entity) then return end
    local timeout = GetGameTimer() + 1000
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
end

-- opts.entity -> its coords/rotation, else opts.coords + opts.rot / opts.heading
function RB.Where(opts)
    if opts.entity and DoesEntityExist(opts.entity) then
        return GetEntityCoords(opts.entity), GetEntityRotation(opts.entity, 2)
    end
    if not opts.coords then return nil end
    return vector3(opts.coords.x, opts.coords.y, opts.coords.z), opts.rot or vector3(0.0, 0.0, opts.heading or opts.coords.w or 0.0)
end

-- Starts a scenario. est = expected total ms (progress bar). defSpeed = default scene rate
function RB.Begin(opts, est, defSpeed, actor)
    if busy then return nil end
    busy = true
    opts = opts or {}
    local run = {
        opts = opts, ped = actor or PlayerPedId(), props = {}, fx = {}, sounds = {},
        cancelled = false, finished = false, speed = opts.speed or defSpeed or 1.0,
    }
    run.k = (defSpeed or 1.0) / run.speed
    if not actor then SetCurrentPedWeapon(run.ped, GetHashKey('WEAPON_UNARMED'), true) end
    if opts.freeze then FreezeEntityPosition(run.ped, true) end

    if opts.label then
        CreateThread(function()
            local ok = exports['rnv-interface']:Progress({
                label = opts.label, duration = math.floor((est or 5000) * run.k), canCancel = opts.canCancel,
                cancel = function() return run.finished end,
            })
            if not ok and not run.finished then run.cancelled = true end
        end)
    elseif opts.canCancel then
        CreateThread(function()
            while not run.finished do
                if IsControlJustPressed(0, 73) then run.cancelled = true end
                Wait(0)
            end
        end)
    end
    return run
end

-- A step wait (ms at the default speed) scaled to the chosen speed
function RB.Ms(run, ms)
    return math.floor(ms * run.k)
end

-- Waits ms; false if the player cancelled
function RB.Wait(run, ms)
    local endAt = GetGameTimer() + ms
    while GetGameTimer() < endAt do
        if run.cancelled then return false end
        Wait(0)
    end
    return not run.cancelled
end

-- Spawns a prop that is deleted when the scenario ends
function RB.Prop(run, model, coords)
    local obj = RB.Spawn(model, coords or GetEntityCoords(run.ped), nil, true)
    SetEntityCollision(obj, false, true)
    run.props[#run.props + 1] = obj
    return obj
end

-- One synced scene step. ents = { { entity, clip }, { ped, clip, 'ped' } }
-- style 'a' = (1.5, -4.0, 1, 16) ped / (4.0, -8.0, 1) props; 'b' = (4.0, -4.0, 1033, 0) ped / (1.0, -1.0, 1148846080) props
function RB.Scene(run, dict, pos, rot, pedClip, ents, style, looped)
    local s = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2, true, looped or false, 1.0, 0.0, run.speed)
    if pedClip then
        if style == 'a' then
            NetworkAddPedToSynchronisedScene(run.ped, s, dict, pedClip, 1.5, -4.0, 1, 16, 1000.0, 0)
        else
            NetworkAddPedToSynchronisedScene(run.ped, s, dict, pedClip, 4.0, -4.0, 1033, 0, 1000.0, 0)
        end
    end
    for _, e in ipairs(ents or {}) do
        if e[1] and DoesEntityExist(e[1]) then
            if e[3] == 'ped' then
                NetworkAddPedToSynchronisedScene(e[1], s, dict, e[2], 4.0, -4.0, 1033, 0, 1000.0, 0)
            elseif style == 'a' then
                NetworkAddEntityToSynchronisedScene(e[1], s, dict, e[2], 4.0, -8.0, 1)
            else
                NetworkAddEntityToSynchronisedScene(e[1], s, dict, e[2], 1.0, -1.0, 1148846080)
            end
        end
    end
    NetworkStartSynchronisedScene(s)
    run.scene = s
    return s
end

-- Scripted camera. def = default when opts.camera is not set
function RB.CamOn(run, def)
    local want = run.opts.camera
    if want == nil then want = def end
    if not want then return end
    run.cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
    SetCamActive(run.cam, true)
    RenderScriptCams(true, false, 3000, true, false)
end

function RB.CamAnim(run, clip, dict, pos, rot)
    if not run.cam or not clip then return end
    PlayCamAnim(run.cam, clip, dict, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, false, 2)
end

function RB.CamOff(run)
    if not run.cam then return end
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(run.cam, false)
    run.cam = nil
end

function RB.Sound(run, name, entity, set)
    local id = GetSoundId()
    PlaySoundFromEntity(id, name, entity, set, true, 0)
    run.sounds[#run.sounds + 1] = id
    return id
end

function RB.StopSounds(run)
    for _, id in ipairs(run.sounds) do
        StopSound(id)
        ReleaseSoundId(id)
    end
    run.sounds = {}
end

function RB.StopFx(run)
    for _, h in ipairs(run.fx) do StopParticleFxLooped(h, false) end
    run.fx = {}
end

-- Ends a scenario: stops everything, deletes the props, runs the callbacks
function RB.Finish(run, ok)
    run.finished = true
    if run.cancelled then ok = false end
    RB.StopSounds(run)
    RB.StopFx(run)
    if run.scene then NetworkStopSynchronisedScene(run.scene) end
    for _, obj in ipairs(run.props) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    RB.CamOff(run)
    ClearPedTasks(run.ped)
    if run.opts.freeze then FreezeEntityPosition(run.ped, false) end
    busy = false
    if ok and run.opts.onDone then run.opts.onDone() end
    if not ok and run.opts.onCancel then run.opts.onCancel() end
    return ok
end

exports('IsBusy', function() return busy end)
