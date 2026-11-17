local Vehicle = require 'Rnv.Game.Vehicle'

lib.vehicle = Class('Vehicle', Vehicle)

if lib.context == 'server' then
    function lib.vehicle.create(model, type, x, y, z, heading)
        heading = heading or 0
        local handle = CreateVehicleServerSetter
            and CreateVehicleServerSetter(model, type, x, y, z, heading)
            or CreateVehicle(model, x, y, z, heading, true, true)

        return Vehicle:new(handle)
    end
else
    function lib.vehicle.create(model, x, y, z, heading, isNetworked, netMissionEntity)
        local hash = lib.requestModel(model)
        local handle = CreateVehicle(hash, x, y, z, heading or 0, isNetworked or false, netMissionEntity or false)

        SetModelAsNoLongerNeeded(hash)

        return Vehicle:new(handle)
    end
end

return lib.vehicle
