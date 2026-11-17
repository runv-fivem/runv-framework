
local GameEntity = require 'Rnv.Game.Entity'
local isServer = lib.context == 'server'


Vehicle = Class('Vehicle', GameEntity)
Vehicle.type = Vehicle.__name

function Vehicle.create(model, x, y, z, heading, isNetworked, netMissionEntity)
    heading = heading or 0
    isNetworked = isServer or isNetworked or false
    netMissionEntity = isServer or netMissionEntity or false
    local hash = isServer and model or lib.requestModel(model)
    local handle = CreateVehicle(hash, x, y, z, heading, isNetworked, netMissionEntity)


    if not isServer then SetModelAsNoLongerNeeded(hash) end

    return Vehicle:new(handle)
end

function Vehicle:constructor(handle)
    self:super()
    self:setHandle(handle)
end

function Vehicle:__index(index)
    if index == 'handle' then
        return self.private.handle
    end

    return Vehicle[index]
end

function Vehicle:getType()
    return GetVehicleType(self.handle)
end

function Vehicle:getPlate()
    return GetVehicleNumberPlateText(self.handle)
end

function Vehicle:setPlate(plate)
    SetVehicleNumberPlateText(self.handle, plate)
end

function Vehicle:setOnGround()
    if isServer then
        return self:setr('rnv_entity_setonground', true)
    end

    return SetVehicleOnGroundProperly(self.handle)
end

return Vehicle
