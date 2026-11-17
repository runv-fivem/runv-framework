-- Parties live in memory (a party ends when everyone leaves or the server restarts)

local parties = {}  -- id -> { id, leader = src, members = { src, ... } }
local partyOf = {}  -- src -> party id
local invites = {}  -- target src -> { from = src, expires = os.time() }
local nextId = 1

local function getPlayer(src)
    return exports['rnv-core']:GetPlayer(src)
end

local function notify(src, text, kind)
    exports['rnv-interface']:Notify(src, { text = text, type = kind or 'inform' })
end

local function findByUserId(userId)
    for src, player in pairs(exports['rnv-core']:GetPlayers()) do
        if player.userId == userId then return tonumber(src) end
    end
end

-- Party colours (purple, orange, teal); a member keeps the colour while in the party
local COLORS = { '#d36ee8', '#f4912c', '#5fe3c0' }

local function colorOf(party, src)
    party.colors = party.colors or {}
    if party.colors[src] then return party.colors[src] end
    for _, color in ipairs(COLORS) do
        local used = false
        for member, c in pairs(party.colors) do
            if c == color and partyOf[member] == party.id then used = true end
        end
        if not used then party.colors[src] = color return color end
    end
    return COLORS[1]
end

local function sync(party)
    local list = {}
    for _, src in ipairs(party.members) do
        local p = getPlayer(src)
        list[#list + 1] = { id = src, uid = p and p.userId, name = p and p.name or '?', leader = src == party.leader, color = colorOf(party, src) }
    end
    for _, src in ipairs(party.members) do
        TriggerClientEvent('rnv-party:client:update', src, { members = list, leader = src == party.leader })
    end
end

local function createParty(leader)
    local party = { id = nextId, leader = leader, members = { leader } }
    nextId = nextId + 1
    parties[party.id] = party
    partyOf[leader] = party.id
    return party
end

local function leave(src)
    local party = parties[partyOf[src]]
    if not party then return end
    partyOf[src] = nil
    if party.colors then party.colors[src] = nil end
    for i, member in ipairs(party.members) do
        if member == src then table.remove(party.members, i) break end
    end
    TriggerClientEvent('rnv-party:client:update', src, nil)

    if #party.members <= 1 then
        -- One player left: the party is over
        for _, member in ipairs(party.members) do
            partyOf[member] = nil
            TriggerClientEvent('rnv-party:client:update', member, nil)
        end
        parties[party.id] = nil
        return
    end
    if party.leader == src then party.leader = party.members[1] end
    sync(party)
end

lib.callback.register('rnv-party:invite', function(src, userId)
    userId = tonumber(userId)
    local target = userId and findByUserId(userId)
    if not target then return false, 'Player not found' end
    if target == src then return false, 'You cannot invite yourself' end
    if partyOf[target] then return false, 'Player is already in a party' end

    local party = parties[partyOf[src]]
    if party and party.leader ~= src then return false, 'Only the party leader can invite' end
    if party and #party.members >= Config.MaxMembers then return false, 'Your party is full' end
    if invites[target] and invites[target].expires > os.time() then return false, 'Player already has an invite' end

    invites[target] = { from = src, expires = os.time() + Config.InviteTime }
    TriggerClientEvent('rnv-party:client:invite', target, getPlayer(src).name, Config.InviteTime)
    return true
end)

RegisterNetEvent('rnv-party:server:answer', function(accept)
    local src = source
    local invite = invites[src]
    invites[src] = nil
    if not invite or invite.expires < os.time() or not getPlayer(invite.from) then return end

    local me = getPlayer(src)
    if not accept then
        return notify(invite.from, ('[[%s]] declined your party invite'):format(me.name))
    end
    if partyOf[src] then return end

    local party = parties[partyOf[invite.from]] or createParty(invite.from)
    if #party.members >= Config.MaxMembers then
        return notify(src, 'The party is full', 'error')
    end
    party.members[#party.members + 1] = src
    partyOf[src] = party.id
    sync(party)
    notify(invite.from, ('[[%s]] joined your party'):format(me.name), 'success')
end)

RegisterNetEvent('rnv-party:server:leave', function()
    leave(source)
end)

RegisterNetEvent('rnv-party:server:kick', function(userId)
    local src = source
    local party = parties[partyOf[src]]
    local target = findByUserId(tonumber(userId))
    if not party or party.leader ~= src or not target or partyOf[target] ~= party.id or target == src then return end
    leave(target)
    notify(target, 'You were removed from the party', 'error')
end)

AddEventHandler('playerDropped', function()
    invites[source] = nil
    leave(source)
end)

exports('GetPartyMembers', function(src)
    local party = parties[partyOf[tonumber(src)]]
    return party and party.members or { tonumber(src) }
end)

-- PARTY VOTE ("<name> suggests becoming Criminals" with N DECLINE / Y ACCEPT)
-- AskParty(src, text, seconds, cb): every other member answers Y / N. cb(true, members) once all said yes,
-- cb(false) on a no or when time runs out. Solo players get cb(true, { src }) at once
local votes = {} -- party id -> { from, waiting = { [src] = true }, cb }

exports('AskParty', function(src, text, seconds, cb)
    src = tonumber(src)
    local party = parties[partyOf[src]]
    if not party or #party.members < 2 then return cb(true, { src }) end
    if votes[party.id] then
        notify(src, 'Your party is already answering a request', 'error')
        return cb(false)
    end
    local vote = { from = src, waiting = {}, cb = cb, members = {} }
    for i, member in ipairs(party.members) do
        vote.members[i] = member
        if member ~= src then
            vote.waiting[member] = true
            TriggerClientEvent('rnv-party:client:vote', member, text, seconds)
        end
    end
    votes[party.id] = vote
    notify(src, 'Waiting for your party to answer...')
    SetTimeout(seconds * 1000, function()
        if votes[party.id] ~= vote then return end
        votes[party.id] = nil
        notify(src, 'Not everyone in the party answered', 'error')
        cb(false)
    end)
end)

RegisterNetEvent('rnv-party:server:vote', function(yes)
    local src = source
    local party = parties[partyOf[src]]
    local vote = party and votes[party.id]
    if not vote or not vote.waiting[src] then return end
    if not yes then
        votes[party.id] = nil
        local p = getPlayer(src)
        notify(vote.from, ('[[%s]] declined'):format(p and p.name or '?'), 'error')
        return vote.cb(false)
    end
    vote.waiting[src] = nil
    if next(vote.waiting) == nil then
        votes[party.id] = nil
        vote.cb(true, vote.members)
    end
end)
