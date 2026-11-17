
local GameEntity = require 'Rnv.Game.Entity'
local isServer = lib.context == 'server'

Prop = Class('Prop', GameEntity)
Prop.type = Prop.__name

if isServer then
    function Prop.create(model, x, y, z, heading, dynamic)
        local handle = CreateObjectNoOffset(model, x, y, z, true, true, dynamic or false)
        local prop = Prop:new(handle)

        if heading then prop:setHeading(heading) end

        return prop
    end
else
    function Prop.create(model, x, y, z, heading, isNetworked, netMissionEntity, dynamic)
        local hash = lib.requestModel(model)
        local handle = CreateObject(hash, x, y, z, isNetworked or false, netMissionEntity or false, dynamic or false)
        local prop = Prop:new(handle)

        SetModelAsNoLongerNeeded(hash)

        if heading then prop:setHeading(heading) end

        return prop
    end
end

function Prop:constructor(handle)
    self:super()
    self:setHandle(handle)
end

function Prop:__index(index)
    if index == 'handle' then
        return self.private.handle
    end

    return Prop[index]
end

function Prop:setOnGround()
    if isServer then
        return self:setr('rnv_entity_setonground', true)
    end

    return PlaceObjectOnGroundProperly(self.handle)
end

return Prop
