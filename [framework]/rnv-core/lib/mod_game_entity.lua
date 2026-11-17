
local isServer = lib.context == 'server'
local allowStateBagReplication = isServer or not GetConvarBool('sv_stateBagStrictMode', false)

local GameEntity = Class('GameEntity')

function GameEntity:constructor(handle)
    self.private.handle = handle or 0
end

function GameEntity:__index(index)
    if index == 'handle' then
        return self.private.handle
    end

    return GameEntity[index]
end


function GameEntity:set(key, value, mode)
    if mode and self.netId == 0 then mode = nil end

    if (mode == 1 and not allowStateBagReplication) or mode == 2 then
        if mode == 2 and self.type ~= 'Player' then
            error('Setting synced-states is not supported for non-player entities.')
        end

        if not isServer then
            local ok = lib.callback.await('rnv-lib:requestSetStateBag', nil, self.statebag, key, value, mode)

            return ok and self:set(key, value) or false
        end

        TriggerClientEvent('rnv-lib:setStateBagValue', self.netId, key, value)
    end

    local packed = msgpack.pack(value)
    SetStateBagValue(self.statebag, key, packed, #packed, mode == 1)

    return true
end

function GameEntity:setr(key, value)
    return self:set(key, value, 1)
end

function GameEntity:sets(key, value)
    return self:set(key, value, 2)
end

function GameEntity:get(key)
    return GetStateBagValue(self.statebag, key)
end

function GameEntity:has(key)
    return StateBagHasKey(self.statebag, key)
end

function GameEntity:keys()
    return GetStateBagKeys(self.statebag)
end

function GameEntity:setHandle(handle)
    local isPlayer = self.type == 'Player'
    local playerId = isPlayer and self.playerId

    self.private.handle = handle
    self.netId = playerId and (isServer and playerId or GetPlayerServerId(playerId)) or NetworkGetNetworkIdFromEntity(handle)
    self.statebag = self.netId == 0 and ('localEntity:%s'):format(handle) or (isPlayer and 'player:%s' or 'entity:%s'):format(self.netId)

    if self.netId == 0 or (isServer and not isPlayer) then
        EnsureEntityStateBag(handle)
    end
end

function GameEntity:getCoords()
    return GetEntityCoords(self.handle)
end

function GameEntity:setCoords(x, y, z, deadFlag, ragdollFlag, clearArea)
    SetEntityCoords(self.handle, x, y, z, true, deadFlag or false, ragdollFlag or false, clearArea or false)
end

function GameEntity:getModel()
    return GetEntityModel(self.handle)
end

function GameEntity:getHeading()
    return GetEntityHeading(self.handle)
end

function GameEntity:setHeading(heading)
    SetEntityHeading(self.handle, heading)
end

function GameEntity:getRoutingBucket()
    return isServer and GetEntityRoutingBucket(self.handle) or self:get('bucket') or 0
end

function GameEntity:setRoutingBucket(bucket)
    if not isServer then return end
    SetEntityRoutingBucket(self.handle, bucket)
    self:set('bucket', bucket, 1)
end

return GameEntity
