
local Ped = require 'Rnv.Game.Ped'
local isServer = lib.context == 'server'

local Player = Class('Player', Ped)
Player.type = Player.__name

local players = setmetatable({}, {
    __mode = 'v',
    __index = function(self, key)
        self[key] = Player:new(key)
        return self[key]
    end
})

local stateChangeHandlers = {}

local function triggerStateChangeHandlers(bag, key, value)
    if not bag:find('^player:') then return end

    local playerId = GetPlayerFromStateBagName(bag)
    local handlers = playerId ~= 0 and stateChangeHandlers[key]

    if not handlers then return end

    local player = players[playerId]

    for i = 1, #handlers do
        local handler = handlers[i]
        handler.cb(player, key, value, GetStateBagValue(bag, key))
    end
end

function Player.on(key, handler)
    local handlers = stateChangeHandlers[key]

    if not handlers then
        handlers = lib.array:new()
        stateChangeHandlers[key] = handlers
    end

    handlers:push({
        cb = handler,
        cookie = AddStateBagChangeHandler(key, '', triggerStateChangeHandlers),
    })
end

function Player:constructor(netId)
    if netId == -1 then netId = isServer and tonumber(GetPlayerFromIndex(0)) or cache.serverId end

    local playerId = isServer and netId or GetPlayerFromServerId(netId)

    self:super(0)
    self.playerId = playerId
    self:setHandle(GetPlayerPed(playerId))
end

function Player:__index(index)
    if index == 'handle' then
        return isServer and self.private.handle or GetPlayerPed(self.playerId)
    end

    return Player[index]
end

function Player:setModel(model)
    SetPlayerModel(self.playerId, model)
end

function Player:getRoutingBucket()
    return isServer and GetPlayerRoutingBucket(self.playerId) or self:get('bucket') or 0
end

function Player:setRoutingBucket(bucket)
    if not isServer then return end

    SetPlayerRoutingBucket(self.playerId, bucket)
    self:set('bucket', bucket, 1)
end

if not isServer then
    Player.Local = Player:new(-1)
end

return Player
