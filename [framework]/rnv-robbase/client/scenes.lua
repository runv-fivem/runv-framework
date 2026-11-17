-- Object scenarios: tills, safes, stacks, trolleys, drills, explosives, hacking, glass, paintings,
-- jewel cases, lockboxes, containers, grill, chemicals
local S = Config.Scenes

-- Loop one step until ms passed (for loop clips shorter than the wanted duration)
local function loopStep(run, ms, stepMs, start)
    local endAt = GetGameTimer() + ms
    while GetGameTimer() < endAt do
        start()
        if not RB.Wait(run, math.min(stepMs, endAt - GetGameTimer())) then return false end
    end
    return true
end

-- The clerk empties the till into a bag. opts.ped = clerk (required)
-- opts.till = till entity, or opts.coords near a prop_till_01. Returns ok, bagCoords
local function robTill(opts)
    opts = opts or {}
    local clerk = opts.ped
    if not clerk or not DoesEntityExist(clerk) then return false end
    local till = opts.till or (opts.coords and RB.Find('till_world', opts.coords, 1.0))
    if not till then return false end
    local d = S.till
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, d.ms + 3000, 1.0, clerk)
    if not run then return false end

    local tc = GetOffsetFromEntityInWorldCoords(till, 0.0, 0.0, -0.12)
    local tr = GetEntityRotation(till, 2)
    local movePos = GetOffsetFromEntityInWorldCoords(till, 0.0, -1.0, 0.0)
    FreezeEntityPosition(clerk, false)
    TaskGoStraightToCoord(clerk, movePos.x, movePos.y, movePos.z, 1.0, 3000, GetEntityHeading(till), 0.0)
    local timeout = GetGameTimer() + 3000
    while #(GetEntityCoords(clerk) - movePos) > 0.3 and GetGameTimer() < timeout do Wait(100) end

    -- swap the world till for the scene version
    CreateModelSwap(tc.x, tc.y, tc.z, 0.5, RB.Hash('till_world'), RB.Hash('till_scene'), true)
    local sceneTill = RB.Prop(run, 'till_scene', tc)
    local bag = RB.Prop(run, 'till_bag', tc)
    RB.Scene(run, d.dict, tc, vector3(tr.x, tr.y, tr.z - 180.0), d.ped, { { sceneTill, d.till }, { bag, d.bag } }, 'a')
    local ok = RB.Wait(run, RB.Ms(run, opts.duration or d.ms))
    local bagCoords = GetEntityCoords(bag)

    CreateModelSwap(tc.x, tc.y, tc.z, 0.5, RB.Hash('till_scene'), RB.Hash('till_world'), true)
    ok = RB.Finish(run, ok)
    FreezeEntityPosition(clerk, true)
    CreateThread(function()
        Wait(1000)
        RemoveModelSwap(tc.x, tc.y, tc.z, 0.5, RB.Hash('till_world'), RB.Hash('till_scene'), true)
        RemoveModelSwap(tc.x, tc.y, tc.z, 0.5, RB.Hash('till_scene'), RB.Hash('till_world'), true)
    end)
    return ok, bagCoords
end

-- Holds a safe door open (end of door_open_safe). Also for other clients / after a restart
local function showSafeOpen(safe)
    local d = S.safe
    if not safe or not DoesEntityExist(safe) or not RB.LoadDict(d.dict) then return false end
    PlayEntityAnim(safe, 'door_open_safe', d.dict, 1000.0, false, true, false, 0.0, 0)
    Wait(100)
    SetEntityAnimCurrentTime(safe, d.dict, 'door_open_safe', 0.99)
    return true
end

-- Open a safe (h4_prop_h4_safe_01a). opts.entity = safe, or
-- opts.coords (vec4) spawns one (at heading - 180). duration = idle part (10000)
-- Returns ok, safe
local function crackSafe(opts)
    opts = opts or {}
    local safe = opts.entity
    if not safe and opts.coords then
        safe = RB.Spawn('safe', opts.coords, (opts.heading or opts.coords.w or 0.0) - 180.0)
    end
    if not safe then return false end
    local d = S.safe
    if not RB.LoadDict(d.dict) then return false end
    local idle = opts.duration or d.steps[1][5]
    local run = RB.Begin(opts, idle + 5000, 1.0)
    if not run then return false end
    RB.Control(safe)
    local pos, rot = GetEntityCoords(safe), GetEntityRotation(safe, 2)
    local bag = RB.Prop(run, 'bag', pos)
    RB.CamOn(run, false)

    local ok = true
    for i, st in ipairs(d.steps) do
        if i == 4 and DoesEntityExist(bag) then DeleteEntity(bag) end
        local function start()
            -- exit_safe swings the door shut: leave the safe out of the exit step so it stays open
            local safeClip = i < 4 and st[2] or nil
            RB.Scene(run, d.dict, pos, rot, st[1], { { safeClip and safe, safeClip }, { bag, st[3] } }, 'a')
            RB.CamAnim(run, st[4], d.dict, pos, rot)
        end
        if i == 1 then
            ok = loopStep(run, idle, RB.Dur(d.dict, st[1], run.speed), start)
        else
            start()
            ok = RB.Wait(run, RB.Ms(run, st[5]))
        end
        if not ok then break end
    end
    ok = RB.Finish(run, ok)
    if ok and opts.keepOpen ~= false then showSafeOpen(safe) end
    return ok, safe
end

-- Type on a terminal (cop_b_idle, flag 50). duration default 5000
local function hackTerminal(opts)
    opts = opts or {}
    local d = S.terminal
    if not RB.LoadDict(d.dict) then return false end
    local ms = opts.duration or 5000
    local run = RB.Begin(opts, ms, 1.0)
    if not run then return false end
    TaskPlayAnim(run.ped, d.dict, d.clip, 2.0, 2.0, -1, 50, 0, false, false, false)
    return RB.Finish(run, RB.Wait(run, ms))
end

-- Grab a table stack (h4_prop_h4_cash_stack_01a / gold_stack_01a)
-- opts.entity = stack. The stack is deleted after the grab unless opts.keep
local function grabStack(opts)
    opts = opts or {}
    local stack = opts.entity
    if not stack or not DoesEntityExist(stack) then return false end
    local gold = opts.gold or GetEntityModel(stack) == RB.Hash('stack_gold')
    local d = gold and S.grabGold or S.grabCash
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, 16000, d.speed)
    if not run then return false end
    RB.Control(stack)
    local pos, rot = GetEntityCoords(stack), GetEntityRotation(stack, 2)
    local bag = RB.Prop(run, 'bag', GetEntityCoords(run.ped))

    RB.Scene(run, d.dict, pos, rot, 'enter', { { bag, 'enter_bag' } }, 'b')
    local ok = RB.Wait(run, RB.Dur(d.dict, 'enter', run.speed))
    if ok then
        RB.Scene(run, d.dict, pos, rot, 'grab', { { bag, 'grab_bag' }, { stack, d.stack } }, 'b')
        ok = RB.Wait(run, RB.Dur(d.dict, 'grab', run.speed))
    end
    if ok then
        if not opts.keep and DoesEntityExist(stack) then DeleteEntity(stack) end
        RB.Scene(run, d.dict, pos, rot, 'exit', { { bag, 'exit_bag' } }, 'b')
        ok = RB.Wait(run, RB.Dur(d.dict, 'exit', run.speed))
    end
    return RB.Finish(run, ok)
end

-- Grab a trolley. opts.entity = trolley. onPile(n) runs on every
-- pile that goes into the bag (anim event RELEASE_CASH_DESTROY). duration = grab part (37000)
-- The full trolley is swapped for an empty one unless opts.keep. Returns ok, piles, emptyTrolley
local function grabTrolley(opts)
    opts = opts or {}
    local trolley = opts.entity
    if not trolley or not DoesEntityExist(trolley) then return false end
    local d = S.trolley
    if not RB.LoadDict(d.dict) then return false end
    local grabMs = opts.duration or d.grab
    local run = RB.Begin(opts, d.intro + grabMs + d.exit, d.speed)
    if not run then return false end
    RB.Control(trolley)
    local pos, rot = GetEntityCoords(trolley), GetEntityRotation(trolley, 2)
    local model = GetEntityModel(trolley)
    local grabModel = opts.grabModel or 'hei_prop_heist_cash_pile'
    for name, prop in pairs(Config.TrolleyGrab) do
        if GetHashKey(name) == model then grabModel = prop end
    end
    local bag = RB.Prop(run, 'bag', GetEntityCoords(run.ped))
    local piles = 0

    RB.Scene(run, d.dict, pos, rot, 'intro', { { bag, 'bag_intro' } }, 'a')
    local ok = RB.Wait(run, RB.Ms(run, d.intro))
    if ok then
        local pile = RB.Prop(run, grabModel)
        FreezeEntityPosition(pile, true)
        SetEntityVisible(pile, false, false)
        AttachEntityToEntity(pile, run.ped, GetPedBoneIndex(run.ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        RB.Scene(run, d.dict, pos, rot, 'grab', { { bag, 'bag_grab' }, { trolley, 'cart_cash_dissapear' } }, 'a')
        local endAt = GetGameTimer() + RB.Ms(run, grabMs)
        while GetGameTimer() < endAt and not run.cancelled do
            if HasAnimEventFired(run.ped, GetHashKey('CASH_APPEAR')) and not IsEntityVisible(pile) then
                SetEntityVisible(pile, true, false)
            end
            if HasAnimEventFired(run.ped, GetHashKey('RELEASE_CASH_DESTROY')) and IsEntityVisible(pile) then
                SetEntityVisible(pile, false, false)
                piles = piles + 1
                if opts.onPile then opts.onPile(piles) end
            end
            Wait(0)
        end
        ok = not run.cancelled
    end
    if ok then
        RB.Scene(run, d.dict, pos, rot, 'exit', { { bag, 'bag_exit' } }, 'a')
        ok = RB.Wait(run, RB.Ms(run, d.exit))
    end
    local empty
    if ok and not opts.keep then
        empty = RB.Spawn('trolley_empty', pos, nil)
        SetEntityRotation(empty, 0.0, 0.0, GetEntityHeading(trolley), 1, false)
        DeleteEntity(trolley)
    end
    return RB.Finish(run, ok), piles, empty
end

-- Drill a deposit box or vault door
-- opts.coords + opts.rot/heading = scene point, opts.laser = laser drill (ch_prop_laserdrill_01a),
-- duration = drilling part (5000), opts.fail = play the fail end. Camera on by default
local function drill(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.drill
    if not RB.LoadDict(d.dict) then return false end
    local ms = opts.duration or 5000
    local run = RB.Begin(opts, 16000 + ms, d.speed)
    if not run then return false end
    local bag = RB.Prop(run, 'bag', GetEntityCoords(run.ped))
    local bit = RB.Prop(run, opts.laser and 'laser_drill' or 'drill', GetEntityCoords(run.ped))
    if not opts.laser then
        for _, bank in ipairs(d.sound.banks) do RequestAmbientAudioBank(bank, false) end
    end
    RB.CamOn(run, true)

    local function step(st)
        RB.Scene(run, d.dict, pos, rot, st[1], { { bag, st[2] }, { bit, st[3] } }, 'b')
        RB.CamAnim(run, st[4], d.dict, pos, rot)
        return RB.Dur(d.dict, st[1], run.speed)
    end
    local ok = RB.Wait(run, step(d.intro))
    if ok then ok = RB.Wait(run, step(d.start)) end
    if ok then
        if not opts.laser then RB.Sound(run, d.sound.name, bit, d.sound.set) end
        ok = loopStep(run, ms, RB.Dur(d.dict, d.idle[1], run.speed), function() step(d.idle) end)
        RB.StopSounds(run)
    end
    if ok and opts.fail then
        RB.Wait(run, step(d.fail) - 1500)
        return RB.Finish(run, false)
    end
    if ok then ok = RB.Wait(run, step(d.stop)) end
    if ok then ok = RB.Wait(run, step(d.exit)) end
    return RB.Finish(run, ok)
end

-- Shared start for thermite and C4
local function plantStart(run, d, pos, rot, model)
    local bag = RB.Prop(run, 'bag', GetEntityCoords(run.ped))
    RB.Scene(run, d.dict, pos, rot, d.clip, { { bag, d.bag } }, 'a')
    if not RB.Wait(run, RB.Ms(run, 1500)) then return nil, bag end
    local charge = RB.Spawn(model, GetEntityCoords(run.ped), nil, true)
    SetEntityCollision(charge, false, true)
    AttachEntityToEntity(charge, run.ped, GetPedBoneIndex(run.ped, d.bone), 0.0, 0.0, 0.0, d.attachRot.x, d.attachRot.y, d.attachRot.z, true, true, false, true, 1, true)
    return charge, bag
end

-- Thermite on a door/gate. opts.coords + rot/heading = scene point (Config.Spots.pacific.thermite),
-- opts.ptfx = burn point (default: where the charge sticks), opts.gate = { coords, from, to } model swap
-- to the molten gate, opts.waitBurn = false returns right after the player steps back
local function plantThermite(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.thermite
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, opts.waitBurn == false and 9500 or 18500, d.speed)
    if not run then return false end
    local charge, bag = plantStart(run, d, pos, rot, 'thermite')
    if not charge then return RB.Finish(run, false) end
    run.props[#run.props + 1] = charge
    local ok = RB.Wait(run, RB.Ms(run, 4000))
    if DoesEntityExist(bag) then DeleteEntity(bag) end
    DetachEntity(charge, true, true)
    FreezeEntityPosition(charge, true)
    if not ok then return RB.Finish(run, false) end

    local burn = opts.ptfx or GetEntityCoords(charge)
    RB.LoadPtfx(d.ptfxAsset)
    UseParticleFxAsset(d.ptfxAsset)
    local fx = StartParticleFxLoopedAtCoord(d.ptfx, burn.x, burn.y, burn.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    CreateThread(function()
        Wait(d.burn)
        StopParticleFxLooped(fx, false)
    end)
    NetworkStopSynchronisedScene(run.scene)
    run.scene = nil
    TaskPlayAnim(run.ped, d.dict, 'cover_eyes_intro', 8.0, 8.0, 1000, 36, 1, false, false, false)
    TaskPlayAnim(run.ped, d.dict, 'cover_eyes_loop', 8.0, 8.0, 3000, 49, 1, false, false, false)
    ok = RB.Wait(run, 2000)
    ClearPedTasks(run.ped)
    if ok then ok = RB.Wait(run, 2000) end
    if DoesEntityExist(charge) then DeleteEntity(charge) end
    if ok and opts.waitBurn ~= false then ok = RB.Wait(run, 9000) end
    if opts.gate then
        local g = opts.gate
        CreateModelSwap(g.coords.x, g.coords.y, g.coords.z, 5.0, RB.Hash(g.from), RB.Hash(g.to), false)
    end
    return RB.Finish(run, ok)
end

-- C4 (prop_bomb_01) on a wall/cell gate. Returns ok, bomb (stays until Detonate)
local function plantBomb(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.thermite
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, 4500, d.speed)
    if not run then return false end
    local bomb, bag = plantStart(run, d, pos, rot, 'bomb')
    if not bomb then return RB.Finish(run, false) end
    local ok = RB.Wait(run, RB.Ms(run, 3000))
    if DoesEntityExist(bag) then DeleteEntity(bag) end
    DetachEntity(bomb, true, true)
    FreezeEntityPosition(bomb, true)
    if not ok then DeleteEntity(bomb) bomb = nil end
    return RB.Finish(run, ok), bomb
end

-- Key fob click, then every bomb explodes (AddExplosion type 2)
local function detonate(bombs, opts)
    opts = opts or {}
    if type(bombs) ~= 'table' then bombs = { bombs } end
    local d = S.fob
    RB.LoadDict(d.dict)
    local ped = PlayerPedId()
    TaskPlayAnim(ped, d.dict, d.clip, 8.0, 8.0, -1, 48, 1, false, false, false)
    Wait(500)
    for _, b in ipairs(bombs) do
        if DoesEntityExist(b) then
            local c = GetEntityCoords(b)
            DeleteEntity(b)
            AddExplosion(c.x, c.y, c.z, opts.type or 2, 300.0, true, false, 1.0)
        end
    end
    return true
end

-- Laptop hack: bag + laptop + card on a security panel (hei_prop_hei_securitypanel)
-- opts.entity = panel (or coords/rot). duration = hacking part (5000)
local function hackLaptop(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.laptop
    if not RB.LoadDict(d.dict) then return false end
    local ms = opts.duration or 5000
    local run = RB.Begin(opts, 10900 + ms, d.speed)
    if not run then return false end
    local here = GetEntityCoords(run.ped)
    local bag, laptop, card = RB.Prop(run, 'bag', here), RB.Prop(run, 'laptop', here), RB.Prop(run, 'hack_card', here)
    local function start(st)
        RB.Scene(run, d.dict, pos, rot, st[1], { { bag, st[2] }, { laptop, st[3] }, { card, st[4] } }, 'a')
    end
    start(d.steps[1])
    local ok = RB.Wait(run, RB.Ms(run, d.steps[1][5]))
    if ok then ok = loopStep(run, ms, RB.Dur(d.dict, d.steps[2][1], run.speed), function() start(d.steps[2]) end) end
    if ok then
        start(d.steps[3])
        ok = RB.Wait(run, RB.Ms(run, d.steps[3][5]))
    end
    return RB.Finish(run, ok)
end

-- Keypad hack: USB + phone on a keypad / fingerprint scanner
-- opts.entity = keypad. duration = hacking part (7000). opts.fail = fail reaction (returns false)
local function hackKeypad(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.keypad
    if not RB.LoadDict(d.dict) then return false end
    local ms = opts.duration or 7000
    local run = RB.Begin(opts, 8000 + ms, d.speed)
    if not run then return false end
    local here = GetEntityCoords(run.ped)
    local usb, phone = RB.Prop(run, 'usb', here), RB.Prop(run, 'phone', here)
    local function start(st)
        RB.Scene(run, d.dict, pos, rot, st[1], { { usb, st[2] }, { phone, st[3] } }, 'b')
    end
    start(d.action)
    local ok = RB.Wait(run, RB.Ms(run, d.action[4]))
    if ok then ok = loopStep(run, ms, RB.Dur(d.dict, d.loop[1], run.speed), function() start(d.loop) end) end
    if ok then
        local last = opts.fail and d.fail or d.success
        start(last)
        ok = RB.Wait(run, RB.Ms(run, last[4]))
        if opts.fail then ok = false end
    end
    return RB.Finish(run, ok)
end

-- Swipe a keycard on a reader. opts.entity = reader (or coords/rot),
-- opts.card = card model (default ch_prop_swipe_card_01a)
local function swipeCard(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.card
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, d.ms, d.speed)
    if not run then return false end
    local card = RB.Prop(run, opts.card or 'keycard', GetEntityCoords(run.ped))
    RB.Scene(run, d.dict, pos, rot, d.clip, { { card, d.card } }, 'a')
    return RB.Finish(run, RB.Wait(run, RB.Ms(run, d.ms)))
end

-- Cut a glass display (h4_prop_h4_glass_disp_01a)
-- opts.entity = display (or opts.coords vec4 spawns one), opts.loot = entity inside (deleted at the
-- grab), opts.overheat = false skips the overheat react. Returns ok, cutDisplay (stays)
local function cutGlass(opts)
    opts = opts or {}
    local display = opts.entity
    if not display and opts.coords then display = RB.Spawn('glass_display', opts.coords, opts.heading or opts.coords.w) end
    if not display then return false end
    local d = S.glass
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, 25000, d.speed)
    if not run then return false end
    RB.Control(display)
    local pos, rot = GetEntityCoords(display), GetEntityRotation(display, 2)
    local here = GetEntityCoords(run.ped)
    local bag, cutter = RB.Prop(run, 'bag', here), RB.Prop(run, 'glass_cutter', here)
    RequestScriptAudioBank(d.audioBank, false)
    RB.LoadPtfx(d.ptfxAsset)
    RB.CamOn(run, true)

    local function step(st, glass)
        RB.Scene(run, d.dict, pos, rot, st[1], { { bag, st[2] }, { cutter, st[3] }, { glass, st[4] } }, 'b')
        RB.CamAnim(run, st[5], d.dict, pos, rot)
        return RB.Dur(d.dict, st[1], run.speed)
    end
    local ok = RB.Wait(run, step(d.steps[1], display))
    if ok then ok = RB.Wait(run, step(d.steps[2], display)) end
    if ok then
        local ms = step(d.steps[3], display)
        RB.Sound(run, 'StartCutting', cutter, d.soundSet)
        UseParticleFxAsset(d.ptfxAsset)
        run.fx[#run.fx + 1] = StartParticleFxLoopedOnEntity(d.ptfxCut, cutter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        ok = RB.Wait(run, ms)
        RB.StopSounds(run)
        RB.StopFx(run)
    end
    if ok and opts.overheat ~= false then
        local ms = step(d.steps[4], display)
        RB.Sound(run, 'Overheated', cutter, d.soundSet)
        UseParticleFxAsset(d.ptfxAsset)
        run.fx[#run.fx + 1] = StartParticleFxLoopedOnEntity(d.ptfxHeat, cutter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        ok = RB.Wait(run, ms)
        RB.StopSounds(run)
        RB.StopFx(run)
    end
    local cut
    if ok then
        cut = RB.Spawn('glass_cut', pos, GetEntityHeading(display))
        DeleteEntity(display)
        local ms = step(d.steps[5], cut)
        ok = RB.Wait(run, 2000)
        if opts.loot and DoesEntityExist(opts.loot) then DeleteEntity(opts.loot) end
        if ok then ok = RB.Wait(run, math.max(0, ms - 2000)) end
    end
    return RB.Finish(run, ok), cut
end

-- Cut a painting out of its frame with a knife
-- opts.coords + rot/heading = scene point (Config.Spots ... paintings[].scene), opts.entity = painting
-- (deleted at the end unless opts.keep). Every step is timed
local function stealPainting(opts)
    opts = opts or {}
    if not opts.coords then return false end
    local pos = vector3(opts.coords.x, opts.coords.y, opts.coords.z - 1.0)
    local rot = opts.rot or vector3(0.0, 0.0, opts.heading or opts.coords.w or 0.0)
    local d = S.painting
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, 27000, 1.0)
    if not run then return false end
    local painting = opts.entity
    if painting then RB.Control(painting) end
    local here = GetEntityCoords(run.ped)
    local bag, knife = RB.Prop(run, 'bag', here), RB.Prop(run, 'knife', here)
    RB.CamOn(run, true)

    local ok = true
    for _, st in ipairs(d.steps) do
        local n = 'ver_01_' .. st[1]
        RB.Scene(run, d.dict, pos, rot, n, {
            { painting, n .. '_ch_prop_vault_painting_01a' }, { bag, n .. '_hei_p_m_bag_var22_arm_s' }, { knife, n .. '_w_me_switchblade' },
        }, 'b')
        if st[2] then RB.CamAnim(run, st[2], d.dict, pos, rot) else RB.CamOff(run) end
        ok = RB.Wait(run, RB.Ms(run, st[3]))
        if not ok then break end
    end
    if ok and painting and not opts.keep and DoesEntityExist(painting) then DeleteEntity(painting) end
    return RB.Finish(run, ok)
end

local lastSmash
-- Smash a jewel case with a rifle butt. opts.coords + rot/heading =
-- scene point, opts.case = case coords (ptfx, sound, model swap), opts.model = case start model
-- (des_jewel_cab*_start, found near opts.case when not given), opts.clip / opts.skull
local function smashCase(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.smash
    if not RB.LoadDict(d.dict) then return false end
    local clip = opts.clip
    if not clip and opts.skull then clip = d.skull end
    while not clip or (clip == lastSmash and not opts.clip) do
        clip = d.clips[math.random(1, #d.clips)]
    end
    lastSmash = clip
    local run = RB.Begin(opts, RB.Dur(d.dict, clip, d.speed), d.speed)
    if not run then return false end
    local case = opts.case or pos
    RB.LoadPtfx(d.ptfxAsset)
    SetEntityCoords(run.ped, pos.x, pos.y, pos.z, false, false, false, false)
    local want = run.opts.camera
    if want == nil or want then
        run.cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
        SetCamActive(run.cam, true)
        RenderScriptCams(true, false, 0, false, false)
    end
    local s = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2, true, false, 1.0, 0.0, run.speed)
    NetworkAddPedToSynchronisedScene(run.ped, s, d.dict, clip, 2.0, 4.0, 1, 0, 1000.0, 0)
    NetworkStartSynchronisedScene(s)
    run.scene = s
    RB.CamAnim(run, 'cam_' .. clip, d.dict, pos, rot)

    local ok = RB.Wait(run, 300)
    if ok then
        local model = opts.model
        if not model then
            for start in pairs(Config.JewelSwap) do
                if RB.Find(start, case, 0.5) then model = start end
            end
        end
        if model and Config.JewelSwap[model] then
            CreateModelSwap(case.x, case.y, case.z, 0.3, RB.Hash(model), RB.Hash(Config.JewelSwap[model]), true)
        end
        for _ = 1, 5 do PlaySoundFromCoord(-1, d.sound, case.x, case.y, case.z, '', false, 0, false) end
        UseParticleFxAsset(d.ptfxAsset)
        StartNetworkedParticleFxNonLoopedAtCoord(d.ptfx, case.x, case.y, case.z, 0.0, 0.0, 0.0, 2.0, false, false, false)
        ok = RB.Wait(run, RB.Dur(d.dict, clip, run.speed) - 300)
    end
    return RB.Finish(run, ok)
end

-- Restore smashed jewel cases (after a reset)
local function resetCase(case, model)
    CreateModelSwap(case.x, case.y, case.z, 0.3, RB.Hash(Config.JewelSwap[model]), RB.Hash(model), true)
end

-- Drill the 4 boxes of a deposit cabinet. opts.entity = cabinet in the
-- world (hidden, a ch_prop_ch_sec_cabinet_01b takes its place and stays). opts.boxes (1-4, default 4),
-- opts.chance = % a box has loot (60), onReward(box) per looted box. Returns ok, rewards, cabinet
local function drillLockbox(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.lockbox
    for _, dict in ipairs(d.dicts) do RB.LoadDict(dict) end
    local boxes = math.min(opts.boxes or 4, 4)
    local run = RB.Begin(opts, 3000 + boxes * 10500, d.speed)
    if not run then return false end
    if opts.entity then
        RB.Control(opts.entity)
        SetEntityVisible(opts.entity, false, false)
        SetEntityCollision(opts.entity, false, false)
    end
    local cab = RB.Spawn('lockbox_scene', pos, rot.z)
    FreezeEntityPosition(cab, true)
    local here = GetEntityCoords(run.ped)
    local drillObj, bag = RB.Prop(run, 'lockbox_drill', here), RB.Prop(run, 'bag', here)
    local money = RB.Prop(run, 'lockbox_reward', vector3(pos.x, pos.y, pos.z - 5.0))
    RB.CamOn(run, true)

    local function step(dict, name, withMoney)
        local ents = { { cab, name .. '_' .. d.props[1] }, { drillObj, name .. '_' .. d.props[2] }, { bag, name .. '_' .. d.props[3] } }
        if withMoney then ents[4] = { money, name .. '_' .. d.props[4] } end
        RB.Scene(run, dict, pos, rot, name, ents, 'b')
        RB.CamAnim(run, name .. '_cam', dict, pos, rot)
        return RB.Dur(dict, name, run.speed)
    end
    local rewards = 0
    local ok = RB.Wait(run, step(d.dicts[1], 'enter'))
    for i = 1, boxes do
        if not ok then break end
        ok = RB.Wait(run, step(d.dicts[i], 'action') - 1000)
        if not ok then break end
        if math.random(1, 100) <= (opts.chance or d.chance) then
            ok = RB.Wait(run, step(d.dicts[i], 'reward', true))
            rewards = rewards + 1
            if ok and opts.onReward then opts.onReward(i) end
        else
            ok = RB.Wait(run, step(d.dicts[i], 'no_reward'))
        end
    end
    if not ok then
        DeleteEntity(cab)
        cab = nil
        if opts.entity then
            SetEntityVisible(opts.entity, true, false)
            SetEntityCollision(opts.entity, true, true)
        end
    end
    return RB.Finish(run, ok), rewards, cab
end

-- A local (this client only) opened container + cut lock at pos/rot
-- Call it on every client that should see the open container. Returns container, lock
local function showContainerOpen(pos, rot)
    local d = S.container
    RB.LoadDict(d.dict)
    local container = RB.Spawn('container', pos, nil, false)
    local lock = RB.Spawn('container_lock', pos, nil, false)
    local s = CreateSynchronizedScene(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 2)
    PlaySynchronizedEntityAnim(container, s, d.container, d.dict, 1.0, -1.0, 0, 1000.0)
    ForceEntityAiAndAnimationUpdate(container)
    PlaySynchronizedEntityAnim(lock, s, d.lock, d.dict, 1.0, -1.0, 0, 1000.0)
    ForceEntityAiAndAnimationUpdate(lock)
    SetSynchronizedScenePhase(s, 0.99)
    SetSynchronizedSceneHoldLastFrame(s, true)
    SetEntityCollision(container, false, true)
    FreezeEntityPosition(container, true)
    return container, lock
end

-- Angle grinder on a container lock (tr_prop_tr_container_01a +
-- tr_prop_tr_lock_01a). opts.entity = container (or opts.coords vec4 spawns both), opts.lock =
-- lock entity (found near the container). On success both are replaced by a local opened copy
-- (send pos/rot to the other clients for ShowContainerOpen). Returns ok, container, lock, pos, rot
local function cutContainer(opts)
    opts = opts or {}
    local container, lock = opts.entity, opts.lock
    if not container and opts.coords then
        container = RB.Spawn('container', opts.coords, opts.heading or opts.coords.w)
        FreezeEntityPosition(container, true)
        lock = RB.Spawn('container_lock', opts.coords, opts.heading or opts.coords.w)
    end
    if not container then return false end
    lock = lock or RB.Find('container_lock', GetEntityCoords(container), 2.5)
    local d = S.container
    if not RB.LoadDict(d.dict) then return false end
    local total = RB.Dur(d.dict, d.ped, 1.0)
    local run = RB.Begin(opts, total, 1.0)
    if not run then return false end
    RB.Control(container)
    RB.Control(lock)
    RB.LoadPtfx(d.ptfxAsset)
    local pos, rot = GetEntityCoords(container), GetEntityRotation(container, 2)
    local here = GetEntityCoords(run.ped)
    local grinder, bag = RB.Prop(run, 'grinder', here), RB.Prop(run, 'bag_grinder', here)
    SetEntityCoords(run.ped, pos.x, pos.y, pos.z, false, false, false, false)
    RB.Scene(run, d.dict, pos, rot, d.ped, { { container, d.container }, { lock, d.lock }, { grinder, d.grinder }, { bag, d.bag } }, 'b')
    local ok = RB.Wait(run, RB.Ms(run, d.sparkAt))
    if ok then
        UseParticleFxAsset(d.ptfxAsset)
        run.fx[#run.fx + 1] = StartParticleFxLoopedOnEntity(d.ptfx, grinder, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        ok = RB.Wait(run, RB.Ms(run, d.sparkFor))
        RB.StopFx(run)
    end
    if ok then ok = RB.Wait(run, RB.Dur(d.dict, d.ped, run.speed) - RB.Ms(run, d.sparkAt + d.sparkFor)) end
    local result = RB.Finish(run, ok)
    if not result then return false, container, lock end
    -- the networked container + lock go, a local opened copy takes their place
    DeleteEntity(container)
    if lock and DoesEntityExist(lock) then DeleteEntity(lock) end
    container, lock = showContainerOpen(pos, rot)
    return true, container, lock, pos, rot
end

-- Blowtorch a grill open. The cutting is played
-- automatically (the cut points one after another). opts.entity = grill bit
-- (prop_chem_grill_bit), or opts.coords + heading spawns grill + bit. opts.cutTime per point (900)
-- Returns ok, grill, grillBit
local function blowtorch(opts)
    opts = opts or {}
    local d = S.blowtorch
    local grill, bit = opts.grill, opts.entity
    if not bit and opts.coords then
        local h = opts.heading or opts.coords.w or 0.0
        grill = RB.Spawn('grill', opts.coords, nil)
        bit = RB.Spawn('grill_bit', opts.coords, nil)
        SetEntityCoordsNoOffset(grill, opts.coords.x, opts.coords.y, opts.coords.z, false, false, false)
        SetEntityCoordsNoOffset(bit, opts.coords.x, opts.coords.y, opts.coords.z, false, false, false)
        SetEntityRotation(grill, 0.0, 0.0, h, 2, true)
        SetEntityRotation(bit, 0.0, 0.0, h, 2, true)
        FreezeEntityPosition(grill, true)
        FreezeEntityPosition(bit, true)
    end
    if not bit then return false end
    RB.LoadDict(d.def)
    RB.LoadDict(d.str)
    RB.LoadDict('missheistchem2')
    RB.LoadPtfx(d.ptfxAsset)
    local cutTime = opts.cutTime or 900
    local run = RB.Begin(opts, 6000 + #d.points * (cutTime + 400) + 10500, 1.3)
    if not run then return false end
    RB.Control(bit)
    local h = GetEntityHeading(bit)
    local pedPos = GetOffsetFromEntityInWorldCoords(bit, -0.076, -0.085, -0.9975)
    local scenePos = GetOffsetFromEntityInWorldCoords(bit, 0.023, 0.060, -1.14)
    local sceneRot = vector3(0.0, 0.0, h)
    local ped = run.ped

    SetEntityCoordsNoOffset(ped, pedPos.x, pedPos.y, pedPos.z, false, false, false)
    SetEntityHeading(ped, h)
    SetPedResetFlag(ped, 197, true)
    SetPedCanLegIk(ped, false)
    SetPedCanHeadIk(ped, false)
    TaskMoveNetworkAdvancedByName(ped, d.network, pedPos.x, pedPos.y, pedPos.z, 0.0, 0.0, h, 2, 0.0, false, nil, 0)
    ForcePedAiAndAnimationUpdate(ped, false, false)
    local cutter = RB.Prop(run, 'gas_cutter', pedPos)
    AttachEntityToEntity(cutter, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    RB.CamOn(run, true)
    RB.CamAnim(run, d.introCam, d.def, scenePos, sceneRot)
    local ok = RB.Wait(run, 6000)
    RB.CamOff(run)

    local timeout = GetGameTimer() + 3000
    local ready = false
    while ok and not ready and GetGameTimer() < timeout do
        if IsTaskMoveNetworkActive(ped) and IsTaskMoveNetworkReadyForTransition(ped) then
            ready = RequestTaskMoveNetworkStateTransition(ped, 'Cutting')
        end
        Wait(0)
    end
    local x, y = 0.15, 0.8
    local breaks = {}
    for _, p in ipairs(d.points) do
        if not ok then break end
        -- move the torch to the point
        local sx, sy, t0 = x, y, GetGameTimer()
        while GetGameTimer() - t0 < 400 do
            local f = (GetGameTimer() - t0) / 400
            SetTaskMoveNetworkSignalFloat(ped, 'x_axis', sx + (p[1] - sx) * f)
            SetTaskMoveNetworkSignalFloat(ped, 'y_axis', sy + (p[2] - sy) * f)
            Wait(0)
        end
        x, y = p[1], p[2]
        SetTaskMoveNetworkSignalFloat(ped, 'x_axis', x)
        SetTaskMoveNetworkSignalFloat(ped, 'y_axis', y)
        UseParticleFxAsset(d.ptfxAsset)
        local fx = StartParticleFxLoopedOnEntity(d.ptfxCut, cutter, -0.344, 0.0, 0.093, 0.0, 0.0, 0.0, 1.0, false, false, false)
        ok = RB.Wait(run, cutTime)
        StopParticleFxLooped(fx, false)
        UseParticleFxAsset(d.ptfxAsset)
        local ry = p[4] == 'h' and 90.0 or 0.0
        breaks[#breaks + 1] = StartParticleFxLoopedOnEntity(d.ptfxBreak, bit, p[3].x, p[3].y, p[3].z, 0.0, ry, 0.0, 1.2, false, false, false)
    end
    if ok then
        RB.CamOn(run, true)
        RB.Scene(run, d.str, scenePos, sceneRot, d.outro, { { bit, d.outroGrill } }, 'b')
        RB.CamAnim(run, d.outroCam, d.str, scenePos, sceneRot)
        ok = RB.Wait(run, RB.Dur(d.str, d.outro, run.speed) - 4000)
    end
    for _, fx in ipairs(breaks) do StopParticleFxLooped(fx, false) end
    SetPedCanLegIk(ped, true)
    SetPedCanHeadIk(ped, true)
    return RB.Finish(run, ok), grill, bit
end

-- Chemical vial scenes where the ped stands
-- opts.coords (vec4) = where the ped stands (default: current spot)
local function chemical(d, opts)
    opts = opts or {}
    if not RB.LoadDict(d.dict) then return false end
    local total = RB.Dur(d.dict, d.ped, 1.1) - (d.cut or 0)
    local run = RB.Begin(opts, total, 1.1)
    if not run then return false end
    if opts.coords then
        SetEntityCoords(run.ped, opts.coords.x, opts.coords.y, opts.coords.z, false, false, false, false)
        SetEntityHeading(run.ped, opts.heading or opts.coords.w or GetEntityHeading(run.ped))
    end
    local p, r = GetEntityCoords(run.ped), GetEntityRotation(run.ped, 2)
    local pos = vector3(p.x, p.y, p.z - d.z)
    local tube, vial = RB.Prop(run, 'vial_tube', p), RB.Prop(run, 'vial', p)
    RB.CamOn(run, true)
    RB.Scene(run, d.dict, pos, r, d.ped, { { tube, d.tube }, { vial, d.vial } }, 'b')
    RB.CamAnim(run, d.cam, d.dict, pos, r)
    return RB.Finish(run, RB.Wait(run, RB.Dur(d.dict, d.ped, run.speed) - (d.cut or 0)))
end

-- Sit at a laptop (switch@franklin@on_laptop). opts.coords + heading
local function useLaptop(opts)
    opts = opts or {}
    local pos, rot = RB.Where(opts)
    if not pos then return false end
    local d = S.laptopDesk
    if not RB.LoadDict(d.dict) then return false end
    local run = RB.Begin(opts, 10000, 1.0)
    if not run then return false end
    pos = vector3(pos.x, pos.y, pos.z - 0.05)
    local laptop = RB.Prop(run, 'laptop_desk', GetEntityCoords(run.ped))
    local ok = true
    for _, st in ipairs(d.steps) do
        RB.Scene(run, d.dict, pos, rot, st[1], { { laptop, st[2] } }, 'b')
        ok = RB.Wait(run, RB.Ms(run, opts.duration and st == d.steps[1] and opts.duration or st[3]))
        if not ok then break end
    end
    return RB.Finish(run, ok)
end

exports('RobTill', robTill)
exports('CrackSafe', crackSafe)
exports('ShowSafeOpen', showSafeOpen)
exports('HackTerminal', hackTerminal)
exports('GrabStack', grabStack)
exports('GrabTrolley', grabTrolley)
exports('Drill', drill)
exports('PlantThermite', plantThermite)
exports('PlantBomb', plantBomb)
exports('Detonate', detonate)
exports('HackLaptop', hackLaptop)
exports('HackKeypad', hackKeypad)
exports('SwipeCard', swipeCard)
exports('CutGlass', cutGlass)
exports('StealPainting', stealPainting)
exports('SmashCase', smashCase)
exports('ResetCase', resetCase)
exports('DrillLockbox', drillLockbox)
exports('CutContainer', cutContainer)
exports('ShowContainerOpen', showContainerOpen)
exports('Blowtorch', blowtorch)
exports('TakeChemical', function(opts) return chemical(S.takeChemical, opts) end)
exports('PutChemical', function(opts) return chemical(S.putChemical, opts) end)
exports('UseLaptop', useLaptop)
