
local GameEntity = require 'Rnv.Game.Entity'
local isServer = lib.context == 'server'

local Ped = Class('Ped', GameEntity)
Ped.type = Ped.__name

function Ped.create(model, x, y, z, heading, isNetworked, bScriptHostPed)
    isNetworked = isServer or isNetworked or false
    bScriptHostPed = isServer or bScriptHostPed or false
    local hash = isServer and model or lib.requestModel(model)
    local handle = CreatePed(0, hash, x, y, z, heading or 0, isNetworked, bScriptHostPed)

    if not isServer then SetModelAsNoLongerNeeded(hash) end

    return Ped:new(handle)
end

function Ped:constructor(handle)
    self:super()

    if handle > 0 then
        self:setHandle(handle)
    end
end

function Ped:__index(index)
    if index == 'handle' then
        return self.private.handle
    end

    return Ped[index]
end

function Ped:getArmour()
    return GetPedArmour(self.handle)
end

function Ped:setArmour(amount)
    SetPedArmour(self.handle, amount)
end

return Ped
