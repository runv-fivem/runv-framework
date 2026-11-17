

local function filter(hook, payload)
    if hook.key and payload.key ~= hook.key then return false end

    return true
end

local Vehicle = require 'Rnv.Game.Vehicle'
local setPlayerState = lib.hook:new('setPlayerState', filter)
local setEntityState = lib.hook:new('setEntityState', filter)

lib.callback.register('rnv-lib:requestSetStateBag', function(playerId, bag, key, value, mode)
    local targetType, target = string.strsplit(':', bag, 2)
    local targetId = tonumber(target, 10)
    local pipeline = (targetType == 'entity' and setEntityState) or (targetType == 'player' and setPlayerState)

    if not pipeline or (targetType == 'player' and targetId ~= playerId) or #pipeline.hooks == 0 then
        return false
    end

    local hook <close> = pipeline:dispatch({
        playerId = playerId,
        targetId = targetId,
        entityId = NetworkGetEntityFromNetworkId(targetId),
        type = targetType,
        bag = bag,
        key = key,
        value = value,
        mode = mode,
    })

    if not hook.ok or hook.size == 0 then return false end

    local packed = msgpack.pack(value)

    SetStateBagValue(bag, key, packed, #packed, mode == 1)

    return true
end)

setEntityState:registerHook(function(payload)
    if payload.value then return false end

    local vehicle = Vehicle:new(payload.entityId)
    local props = vehicle:get(payload.key) ---@type VehicleProperties?

    if not props then return false end

    local plate = vehicle:getPlate()

    if plate == '' or (props.plate and props.plate:strtrim() ~= plate:strtrim()) then return false end

    -- we pray
    return true
end, { key = 'rnv-lib:setVehicleProperties' })


setEntityState:registerHook(function(payload)
    return payload.value == true or not payload.value
end, { key = 'rnv_entity_setonground'})
