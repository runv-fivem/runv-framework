-- Party panel (J / pause menu) and incoming invites (Y accept, N decline)

local party = nil      -- { members = { { uid, name, leader } }, leader = bool } or nil when solo
local isOpen = false
local pendingInvite = false

local function notify(text, kind)
    exports['rnv-interface']:Notify({ text = text, type = kind or 'inform' })
end

local function sendPanel()
    SendNUIMessage({ action = 'party:update', party = party, max = Config.MaxMembers })
end

local function openParty()
    if isOpen or not LocalPlayer.state['rnv:spawned'] or LocalPlayer.state.invOpen or IsNuiFocused() then return end
    isOpen = true
    SendNUIMessage({ action = 'party:open', myId = exports['rnv-core']:GetPlayerData().userId })
    sendPanel()
    SetNuiFocus(true, true)
end

local function closeParty()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'party:close' })
end

local function answer(accept)
    if not pendingInvite then return end
    pendingInvite = false
    exports['rnv-interface']:RemoveNotify('party-invite')
    TriggerServerEvent('rnv-party:server:answer', accept)
end

RegisterNUICallback('party:close', function(_, cb)
    cb(1)
    closeParty()
end)

RegisterNUICallback('party:invite', function(data, cb)
    local ok, err = lib.callback.await('rnv-party:invite', false, data.id)
    notify(ok and 'Party invite sent' or err, ok and 'success' or 'error')
    cb(1)
end)

RegisterNUICallback('party:leave', function(_, cb)
    cb(1)
    TriggerServerEvent('rnv-party:server:leave')
end)

RegisterNUICallback('party:kick', function(data, cb)
    cb(1)
    TriggerServerEvent('rnv-party:server:kick', data.uid)
end)

RegisterNetEvent('rnv-party:client:update', function(data)
    party = data
    sendPanel()
    TriggerEvent('rnv-party:client:updated', party)
end)

RegisterNetEvent('rnv-party:client:invite', function(fromName, seconds)
    local setting = GetResourceState('rnv-menu') == 'started' and exports['rnv-menu']:GetSetting('partyInvites')
    if setting == 'Nobody' then
        return TriggerServerEvent('rnv-party:server:answer', false)
    end
    pendingInvite = true
    exports['rnv-interface']:Notify({
        id = 'party-invite',
        text = ('[[%s]] invited you to a party'):format(fromName),
        duration = seconds * 1000,
        keys = { { key = 'Y', label = 'ACCEPT' }, { key = 'N', label = 'DECLINE' } },
    })
    SetTimeout(seconds * 1000, function() pendingInvite = false end)
end)

-- A party vote (become Criminals / join the Police together) uses the same Y / N keys as an invite
local pendingVote = false

RegisterNetEvent('rnv-party:client:vote', function(text, seconds)
    pendingVote = true
    exports['rnv-interface']:Notify({
        id = 'party-vote', text = text, duration = seconds * 1000,
        keys = { { key = 'N', label = 'DECLINE' }, { key = 'Y', label = 'ACCEPT' } },
    })
    SetTimeout(seconds * 1000, function() pendingVote = false end)
end)

local function answerAny(yes)
    if pendingVote then
        pendingVote = false
        exports['rnv-interface']:RemoveNotify('party-vote')
        return TriggerServerEvent('rnv-party:server:vote', yes)
    end
    answer(yes)
end

RegisterCommand('party', openParty, false)
RegisterCommand('party_accept', function() answerAny(true) end, false)
RegisterCommand('party_decline', function() answerAny(false) end, false)
RegisterKeyMapping('party', 'Party management', 'keyboard', 'J')
RegisterKeyMapping('party_accept', 'Accept party invite', 'keyboard', 'Y')
RegisterKeyMapping('party_decline', 'Decline party invite', 'keyboard', 'N')

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then closeParty() end
end)

exports('OpenParty', openParty)
exports('GetParty', function() return party end)
