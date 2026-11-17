-- HUD data -> NUI, only once the player is in the world

local last = {}

local function send(data)
    data.action = 'hud'
    SendNUIMessage(data)
end

local function visible()
    return LocalPlayer.state['rnv:spawned'] == true and not IsPauseMenuActive() and not LocalPlayer.state['rnv:map'] and not LocalPlayer.state['rnv:screen']
end

local function playerName()
    local data = exports['rnv-core']:GetPlayerData()
    return data and data.name or GetPlayerName(PlayerId())
end

-- compass heading
CreateThread(function()
    while true do
        if visible() then
            local heading = math.floor((360.0 - GetGameplayCamRot(2).z) % 360.0)
            if heading ~= last.heading then
                last.heading = heading
                send({ heading = heading })
            end
            Wait(30)
        else
            Wait(250)
        end
    end
end)

-- visibility, health/armor, voice
CreateThread(function()
    while true do
        Wait(250)
        local show = visible()
        if show ~= last.show then
            last.show = show
            send({ show = show, name = playerName() })
        end
        if show then
            local ped = PlayerPedId()
            local maxHealth = GetEntityMaxHealth(ped) - 100
            local health = math.max(0, GetEntityHealth(ped) - 100)
            local vest = GetResourceState('rnv-inventory') == 'started' and exports['rnv-inventory']:GetVest()
            send({
                health = maxHealth > 0 and math.floor(health / maxHealth * 100) or 0,
                armor = GetPedArmour(ped),
                armorMax = vest and vest.max or 0,
                talking = NetworkIsPlayerTalking(PlayerId()),
            })
        end
    end
end)

-- FPS, averaged per second
CreateThread(function()
    local frames, elapsed = 0, 0.0
    while true do
        Wait(0)
        frames = frames + 1
        elapsed = elapsed + GetFrameTime()
        if elapsed >= 1.0 then
            SendNUIMessage({ action = 'hud', fps = math.floor(frames / elapsed + 0.5) })
            frames, elapsed = 0, 0.0
        end
    end
end)

-- ping from the server every 2 s
CreateThread(function()
    while true do
        Wait(2000)
        if visible() then
            send({ ping = lib.callback.await('rnv-interface:ping', false) })
        end
    end
end)

AddEventHandler('rnv:client:onPlayerDataChanged', function(data)
    send({ name = data.name })
end)

-- rnv-menu settings: metrics and key markers
local function applySettings(s)
    local custom = s.metrics == 'Custom'
    send({
        showFps = s.metrics == 'Default' or (custom and s.showFps),
        showPing = s.metrics == 'Default' or (custom and s.showPing),
        keys = s.keyMarkers,
    })
end

AddEventHandler('rnv-menu:client:settingsChanged', applySettings)

CreateThread(function()
    Wait(1000)
    if GetResourceState('rnv-menu') ~= 'started' then return end
    local menu = exports['rnv-menu']
    applySettings({
        metrics = menu:GetSetting('metrics'),
        showFps = menu:GetSetting('showFps'),
        showPing = menu:GetSetting('showPing'),
        keyMarkers = menu:GetSetting('keyMarkers'),
    })
end)

-- party: SOLO chip -> PARTY, other members' cards above ours
local party = nil

local function mateHealth(id)
    local player = GetPlayerFromServerId(id)
    if player == -1 then return nil end
    local ped = GetPlayerPed(player)
    local maxHealth = GetEntityMaxHealth(ped) - 100
    return maxHealth > 0 and math.floor(math.max(0, GetEntityHealth(ped) - 100) / maxHealth * 100) or 0
end

local function sendParty()
    local me, mates = GetPlayerServerId(PlayerId()), {}
    local myColor, myLeader = false, false
    for _, m in ipairs(party and party.members or {}) do
        if m.id == me then
            myColor, myLeader = m.color, m.leader
        else
            mates[#mates + 1] = { name = m.name, color = m.color, leader = m.leader, health = mateHealth(m.id) or 100 }
        end
    end
    send({ mates = mates, myColor = myColor, myLeader = myLeader })
end

CreateThread(function()
    while true do
        Wait(1000)
        if party then sendParty() end
    end
end)

AddEventHandler('rnv-party:client:updated', function(data)
    party = data
    sendParty()
    send({ party = party and #party.members or 0 })
end)

-- hotbar 1/2 = weapon slots 55/56, 3-6 = pouch cells 60-63
local weaponSlots = { 55, 56, 60, 61, 62, 63 }

local function weaponInfo(item)
    if not item then return nil end
    local info = { image = 'nui://rnv-inventory/web/images/' .. item.name .. '.png', ammo = '' }
    local data = exports['rnv-inventory']:Items(item.name)
    local hash = data and data.hash or joaat(item.name) -- guns use a GTA weapon model
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) == hash then
        local _, clip = GetAmmoInClip(ped, hash)
        info.equipped = true
        info.ammo = ('%d|%d'):format(clip, GetAmmoInPedWeapon(ped, hash) - clip)
    elseif item.metadata and item.metadata.ammo then
        info.ammo = tostring(item.metadata.ammo)
    elseif item.count and item.count > 1 then
        info.ammo = tostring(item.count)
    end
    return info
end

CreateThread(function()
    while true do
        Wait(300)
        if visible() and GetResourceState('rnv-inventory') == 'started' then
            local items = exports['rnv-inventory']:GetPlayerItems() or {}
            local slots = {}
            for i, slot in ipairs(weaponSlots) do
                slots[i] = weaponInfo(items[slot]) or false
            end
            local encoded = json.encode(slots)
            if encoded ~= last.slots then
                last.slots = encoded
                send({ weapons = slots })
            end
        end
    end
end)

-- notoriety chips (rnv:notoriety state bag)
AddStateBagChangeHandler('rnv:notoriety', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    send({ notoriety = value or false })
end)

CreateThread(function()
    Wait(1500)
    send({ notoriety = LocalPlayer.state['rnv:notoriety'] or false })
end)

-- criminal indicator (rnv:role state bag)
AddStateBagChangeHandler('rnv:role', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    send({ role = value or 'civilian' })
end)

CreateThread(function()
    Wait(1500)
    send({ role = LocalPlayer.state['rnv:role'] or 'civilian' })
end)

-- damage number at a world point
exports('DamageNumber', function(coords, amount)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SendNUIMessage({ action = 'damage', x = x * 100, y = y * 100, amount = math.floor(amount) })
end)

-- pickup feed card ("+ $10.000" / "+ Item")
local RARITY = { [1] = '#f0f0f0', [2] = '#69f938', [4] = '#b06ef3', [5] = '#ffcb3d', [6] = '#e8453c' }
exports('Pickup', function(data)
    local text
    if data.name == 'money' then
        text = '+ $' .. tostring(math.floor(data.count)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    else
        text = '+ ' .. data.label .. (data.count > 1 and (' x' .. data.count) or '')
    end
    SendNUIMessage({ action = 'pickup', text = text, image = 'nui://rnv-inventory/web/images/' .. data.name .. '.png', color = RARITY[data.rarity] or (data.name == 'money' and RARITY[2]) or RARITY[1] })
end)
