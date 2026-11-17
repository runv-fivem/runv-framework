-- Player login, logout, metadata, role and life state

local loading = {} ---@type table<integer, true>

function RNV.GetIdentifier(src)
    for _, idType in ipairs(Config.Identifiers) do
        local id = GetPlayerIdentifierByType(tostring(src), idType)
        if id then return id end
    end
end
local getLicense = RNV.GetIdentifier

-- what the player's own client gets to see
local function clientData(player)
    return {
        userId = player.userId,
        citizenid = player.citizenid,
        name = player.name,
        metadata = player.metadata,
        role = player.role,
        lifeState = player.lifeState,
    }
end

local function syncClient(player)
    TriggerClientEvent('rnv:client:setPlayerData', player.source, clientData(player))
end

function RNV.EnsureUser(src, name)
    local identifier = RNV.GetIdentifier(src)
    local userId = MySQL.scalar.await('SELECT userId FROM users WHERE identifier = ?', { identifier })
    if userId then return userId end
    local src_ = tostring(src)
    return MySQL.insert.await(
        'INSERT INTO users (username, identifier, license, license2, fivem, discord) VALUES (?, ?, ?, ?, ?, ?)', {
            name or GetPlayerName(src_), identifier,
            GetPlayerIdentifierByType(src_, 'license'),
            GetPlayerIdentifierByType(src_, 'license2'),
            GetPlayerIdentifierByType(src_, 'fivem'),
            GetPlayerIdentifierByType(src_, 'discord'),
        })
end

local function newCitizenId()
    while true do
        local id = lib.string.random('AAA11111')
        if not MySQL.scalar.await('SELECT 1 FROM players WHERE citizenid = ?', { id }) then
            return id
        end
    end
end

function RNV.Login(src)
    src = tonumber(src)
    if RNV.Players[src] or loading[src] then return false end
    if not getLicense(src) then return false end
    loading[src] = true

    while not RNV.Ready do Wait(100) end

    local name = GetPlayerName(tostring(src))
    local userId = RNV.EnsureUser(src, name)
    local row = MySQL.single.await('SELECT citizenid, name, metadata FROM players WHERE userId = ?', { userId })

    if not row then
        row = { citizenid = newCitizenId(), name = name, metadata = json.encode(Config.DefaultMetadata) }
        MySQL.insert.await('INSERT INTO players (citizenid, userId, name, metadata) VALUES (?, ?, ?, ?)', {
            row.citizenid, userId, row.name, row.metadata,
        })
    end

    -- they might have left while we waited on the database
    if not DoesPlayerExist(tostring(src)) then
        loading[src] = nil
        return false
    end

    local player = {
        source = src,
        userId = userId,
        citizenid = row.citizenid,
        identifier = getLicense(src),
        name = row.name,
        metadata = json.decode(row.metadata) or {},
        role = Config.DefaultRole, -- role and lifeState are not saved
        lifeState = Config.DefaultLifeState,
    }

    RNV.Players[src] = player
    RNV.ByCitizenId[player.citizenid] = src
    loading[src] = nil

    local state = Player(src).state
    state:set('rnv:citizenid', player.citizenid, true)
    state:set('rnv:role', player.role, true)
    state:set('rnv:lifeState', player.lifeState, true)
    state:set('isLoggedIn', true, true)

    RNV.Debug(('%s logged in as %s'):format(name, player.citizenid))
    TriggerEvent('rnv:server:playerLoaded', src, player)
    TriggerClientEvent('rnv:client:playerLoaded', src, clientData(player))
    return true
end

function RNV.Save(src)
    local player = RNV.Players[tonumber(src)]
    if not player then return false end
    -- no await here because this also runs when the resource stops
    MySQL.update('UPDATE players SET name = ?, metadata = ? WHERE citizenid = ?', {
        player.name, json.encode(player.metadata), player.citizenid,
    })
    return true
end

function RNV.Logout(src)
    src = tonumber(src)
    local player = RNV.Players[src]
    if not player then return false end

    RNV.Save(src)
    MySQL.update('UPDATE players SET last_logged_out = NOW() WHERE citizenid = ?', { player.citizenid })

    RNV.Players[src] = nil
    RNV.ByCitizenId[player.citizenid] = nil

    if DoesPlayerExist(tostring(src)) then
        Player(src).state:set('isLoggedIn', false, true)
        TriggerClientEvent('rnv:client:playerUnloaded', src)
    end
    TriggerEvent('rnv:server:playerUnloaded', src, player.citizenid)
    return true
end

function RNV.GetPlayer(src) return RNV.Players[tonumber(src)] end

function RNV.GetPlayerByCitizenId(citizenid)
    local src = RNV.ByCitizenId[citizenid]
    return src and RNV.Players[src]
end

-- Metadata

function RNV.GetMetadata(src, key)
    local player = RNV.Players[tonumber(src)]
    if not player then return end
    if key then return player.metadata[key] end
    return player.metadata
end

function RNV.SetMetadata(src, key, value)
    local player = RNV.Players[tonumber(src)]
    if not player or type(key) ~= 'string' then return false end
    local old = player.metadata[key]
    player.metadata[key] = value
    TriggerEvent('rnv:server:metadataChanged', player.source, key, value, old)
    syncClient(player)
    return true
end

-- nickname: 3-16 letters, digits or _, and nobody else can have it
function RNV.SetName(src, name)
    local player = RNV.Players[tonumber(src)]
    if not player or type(name) ~= 'string' or not name:match('^[%w_]+$') or #name < 3 or #name > 16 then
        return false, 'invalid'
    end
    if MySQL.scalar.await('SELECT 1 FROM players WHERE name = ? AND citizenid <> ?', { name, player.citizenid }) then
        return false, 'taken'
    end
    MySQL.update.await('UPDATE players SET name = ? WHERE citizenid = ?', { name, player.citizenid })
    player.name = name
    syncClient(player)
    return true
end

-- Role and life state, core only stores them

local function setState(field, valid, src, value, reason)
    local player = RNV.Players[tonumber(src)]
    if not player or not valid[value] then return false end
    local old = player[field]
    if old == value then return true end
    player[field] = value
    Player(player.source).state:set('rnv:' .. field, value, true)
    RNV.Debug(('%s %s: %s -> %s (%s)'):format(player.citizenid, field, old, value, reason or '-'))
    TriggerEvent(('rnv:server:%sChanged'):format(field), player.source, value, old, reason)
    syncClient(player)
    return true
end

function RNV.SetRole(src, role, reason) return setState('role', Config.Roles, src, role, reason) end
function RNV.SetLifeState(src, state, reason) return setState('lifeState', Config.LifeStates, src, state, reason) end

RegisterNetEvent('rnv:server:login', function()
    RNV.Login(source)
end)

exports('Login', RNV.Login)
exports('Logout', RNV.Logout)
exports('Save', RNV.Save)
exports('GetPlayer', RNV.GetPlayer)
exports('GetPlayerByCitizenId', RNV.GetPlayerByCitizenId)
exports('GetPlayers', function() return RNV.Players end)
exports('IsLoaded', function(src) return RNV.Players[tonumber(src)] ~= nil end)
exports('SetName', RNV.SetName)
exports('GetMetadata', RNV.GetMetadata)
exports('SetMetadata', RNV.SetMetadata)
exports('GetRole', function(src) local p = RNV.Players[tonumber(src)] return p and p.role end)
exports('SetRole', RNV.SetRole)
exports('GetLifeState', function(src) local p = RNV.Players[tonumber(src)] return p and p.lifeState end)
exports('SetLifeState', RNV.SetLifeState)
