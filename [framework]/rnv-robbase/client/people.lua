-- Ped scenarios: bank teller, hands up, mask, hostage (bag, knockout, interrogation), rappel
local S = Config.Scenes

-- The bank teller walks to the vault and opens it (heist_ruralbank_male),
-- then hands up and walks to opts.walkTo. opts.ped = teller, opts.coords + rot/heading = scene point
-- (Config.Spots.fleeca[].teller / tellerRot). Open the gate about 8 s in and the vault 11.5 s later
local function tellerScene(opts)
    opts = opts or {}
    local teller = opts.ped
    local pos, rot = RB.Where(opts)
    if not teller or not pos then return false end
    local d = S.teller
    if not RB.LoadDict(d.dict) or not RB.LoadDict(S.handsup.dict) then return false end
    local ms = RB.Dur(d.dict, d.clip, opts.speed or d.speed) - 2000
    local run = RB.Begin(opts, ms, d.speed, teller)
    if not run then return false end
    SetBlockingOfNonTemporaryEvents(teller, true)
    RB.Scene(run, d.dict, pos, rot, d.clip, nil, 'b')
    local ok = RB.Finish(run, RB.Wait(run, ms))
    TaskPlayAnim(teller, S.handsup.dict, S.handsup.clip, 8.0, 8.0, -1, 50, 0, false, false, false)
    if opts.walkTo then
        TaskGoToCoordAnyMeans(teller, opts.walkTo.x, opts.walkTo.y, opts.walkTo.z, 1.0, 0, false, 786603, -1.0)
    end
    return ok
end

-- missminuteman_1ig_2 handsup_enter (flag 50), used for clerks, scientists and hostages
local function handsUp(ped, ms)
    local d = S.handsup
    RB.LoadDict(d.dict)
    TaskPlayAnim(ped or PlayerPedId(), d.dict, d.clip, 8.0, 8.0, ms or -1, 50, 0, false, false, false)
    return true
end

-- Mask: put_on_mask (800 ms) + mask drawable. opts.drawable (0 = off), opts.texture
local function putOnMask(opts)
    opts = opts or {}
    local d = S.mask
    RB.LoadDict(d.dict)
    local ped = PlayerPedId()
    TaskPlayAnim(ped, d.dict, d.clip, 8.0, 8.0, d.ms, 16, 0, false, false, false)
    if opts.drawable then SetPedComponentVariation(ped, 1, opts.drawable, opts.texture or 0, 1) end
    Wait(d.ms)
    return true
end

-- Pulls a bag over the victim's head. opts.ped = victim. Returns ok, bag
local function bagHead(opts)
    opts = opts or {}
    local victim = opts.ped
    if not victim or not DoesEntityExist(victim) then return false end
    local d = S.bagHead
    RB.LoadDict(d.dict)
    local run = RB.Begin(opts, d.ms, 1.0)
    if not run then return false end
    TaskPlayAnim(run.ped, d.dict, d.clip, 8.0, -8.0, -1, 16, 0, false, false, false)
    local bag = RB.Spawn('head_bag', GetEntityCoords(victim), nil, true)
    AttachEntityToEntity(bag, victim, GetPedBoneIndex(victim, d.bone), d.offset.x, d.offset.y, d.offset.z, d.rot.x, d.rot.y, d.rot.z, true, true, false, true, 1, true)
    local ok = RB.Wait(run, d.ms)
    if not ok then DeleteEntity(bag) bag = nil end
    return RB.Finish(run, ok), bag
end

-- Knockout: lead-in punch, then the victim ragdolls for 30 s. opts.ped = victim
local function knockout(opts)
    opts = opts or {}
    local victim = opts.ped
    if not victim or not DoesEntityExist(victim) then return false end
    local d = S.knockout
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, d.ms, 1.0)
    if not run then return false end
    local p = GetEntityCoords(run.ped)
    RB.Scene(run, d.dict, vector3(p.x, p.y, p.z - 1.0), vector3(0.0, 0.0, opts.heading or 0.0), d.player, { { victim, d.victim, 'ped' } }, 'b')
    local ok = RB.Wait(run, d.ms)
    ok = RB.Finish(run, ok)
    ClearPedTasks(victim)
    if ok then SetPedToRagdoll(victim, 30000, 30000, 0, false, false, false) end
    return ok
end

-- Interrogation chair (prop_torture_ch_01)
-- opts.ped = victim, opts.coords + rot/heading = chair scene point, opts.stages = list of
-- 'wrench', 'waterboard', 'toothpull' (default all three, in that order). Returns ok, chair
local function interrogate(opts)
    opts = opts or {}
    local victim = opts.ped
    local pos, rot = RB.Where(opts)
    if not victim or not pos then return false end
    local stages = opts.stages or { 'wrench', 'waterboard', 'toothpull' }
    local total = 0
    for _, name in ipairs(stages) do
        local st = S.interrogate[name]
        RB.LoadDict(st.dict)
        for _, step in ipairs(st.steps) do total = total + step[2] end
    end
    local run = RB.Begin(opts, total, 1.0)
    if not run then return false end
    local chair = RB.Spawn('torture_chair', GetEntityCoords(run.ped), nil, true)
    ClearPedTasksImmediately(victim)

    local ok = true
    for _, name in ipairs(stages) do
        local st = S.interrogate[name]
        local base = vector3(pos.x + (st.x or 0.0), pos.y, pos.z - 0.60)
        local tools = {}
        if st.prop then tools[1] = RB.Prop(run, st.prop) end
        if st.props then
            for i, m in ipairs(st.props) do tools[i] = RB.Prop(run, m) end
        end
        for i, step in ipairs(st.steps) do
            local n = step[1]
            local ents = { { victim, n .. '_victim', 'ped' } }
            if name ~= 'toothpull' then ents[#ents + 1] = { chair, n .. '_chair' } end
            if name == 'wrench' then ents[#ents + 1] = { tools[1], n .. '_wrench' } end
            if name == 'waterboard' then
                ents[#ents + 1] = { tools[1], n .. '_jerrycan' }
                ents[#ents + 1] = { tools[2], n .. '_rag' }
            end
            if name == 'toothpull' then ents[#ents + 1] = { tools[1], n .. '_pliers' } end
            local looped = name == 'wrench' or i == 3
            RB.Scene(run, st.dict, base, rot, n .. '_player', ents, 'b', looped)
            ok = RB.Wait(run, step[2])
            if not ok then break end
        end
        for _, t in ipairs(tools) do
            if DoesEntityExist(t) then DeleteEntity(t) end
        end
        if not ok then break end
    end
    ok = RB.Finish(run, ok)
    ClearPedTasks(victim)
    if not opts.keepChair then
        DeleteEntity(chair)
        chair = nil
    end
    return ok, chair
end

-- Rappel down a wall, played automatically
-- The rope (client/rope.lua): hook -> right hand, the rest hanging below
-- opts.coords (vec4) = top point at the wall edge, ped faces the wall (heading) and hangs 1.5 m out
-- over the drop. opts.bottom = floor z (default: the ground below), opts.rate = metres a second (1.5)
-- Returns ok
local function rappel(opts)
    opts = opts or {}
    if not opts.coords then return false end
    local d = S.rappel
    if not RB.LoadDict(d.dict) then return false end
    local top = opts.coords
    local h = opts.heading or top.w or GetEntityHeading(PlayerPedId())
    local rad = math.rad(h)
    local fwd = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local start = vector3(top.x, top.y, top.z) - fwd * 1.5
    local bottom = opts.bottom
    if not bottom then
        local found, gz = GetGroundZFor_3dCoord(start.x, start.y, start.z - 2.0, false)
        bottom = found and gz or top.z - 10.0
    end
    local rate = opts.rate or 1.5
    local run = RB.Begin(opts, math.floor((top.z - bottom) / rate * 1000) + 1000, 1.0)
    if not run then return false end
    local ped = run.ped

    -- hook on the edge, 0.43 m from the top point, turned like it
    local hookPos = vector3(top.x, top.y, top.z) - fwd * 0.43 - vector3(0.0, 0.0, 0.46)
    local hook = RB.Spawn('rope_hook', hookPos, nil, false)
    SetEntityRotation(hook, -90.0, 0.0, h, 1, true)
    FreezeEntityPosition(hook, true)
    run.props[#run.props + 1] = hook
    local anchor = GetEntityCoords(hook)

    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, start.x, start.y, start.z, false, false, false)
    SetEntityHeading(ped, h)
    local rope = RB.RopeNew(anchor, (anchor.z - bottom) + 1.0)
    RB.RopePin(rope, 1, anchor)
    TaskPlayAnim(ped, d.dict, d.idle, 1.0, -1.0, -1, 1, 0.0, false, false, false)

    local z = start.z
    local held = nil
    local ok = true
    local last = GetGameTimer()
    local idleUntil = GetGameTimer() + 800
    while true do
        if run.cancelled then ok = false break end
        local now = GetGameTimer()
        local dt = math.min((now - last) / 1000.0, 0.05)
        last = now
        if now > idleUntil then
            if not IsEntityPlayingAnim(ped, d.dict, d.walk, 3) then
                TaskPlayAnim(ped, d.dict, d.walk, 4.0, 1.0, -1, 1, 0.0, false, false, false)
            end
            z = z - rate * dt
            SetEntityCoordsNoOffset(ped, start.x, start.y, z, false, false, false)
            SetEntityHeading(ped, h)
        end
        -- the rope runs through the right hand: pin the node at the hand's distance along the rope
        local hand = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, 57005))
        local i = math.min(math.floor(#(hand - anchor) / RB.RopeLink) + 2, #rope.nodes)
        if held and held ~= i then RB.RopeUnpin(rope, held) end
        held = i
        RB.RopePin(rope, i, hand)
        RB.RopeStep(rope, dt > 0 and dt or 0.016, bottom)
        RB.RopeDraw(rope)
        if z - 1.0 <= bottom then break end
        Wait(0)
    end

    -- let go: the rope drops and stays a moment, then goes
    FreezeEntityPosition(ped, false)
    if ok then SetEntityCoordsNoOffset(ped, start.x, start.y, bottom + 1.0, false, false, false) end
    if held then RB.RopeUnpin(rope, held) end
    ok = RB.Finish(run, ok)
    CreateThread(function()
        local endAt = GetGameTimer() + (opts.ropeTime or 5000)
        local t = GetGameTimer()
        while GetGameTimer() < endAt do
            local now = GetGameTimer()
            RB.RopeStep(rope, math.min((now - t) / 1000.0, 0.05) + 0.001, bottom)
            t = now
            RB.RopeDraw(rope)
            Wait(0)
        end
        RB.RopeDelete(rope)
    end)
    return ok
end

exports('TellerScene', tellerScene)
exports('HandsUp', handsUp)
exports('PutOnMask', putOnMask)
exports('BagHead', bagHead)
exports('Knockout', knockout)
exports('Interrogate', interrogate)
exports('Rappel', rappel)
