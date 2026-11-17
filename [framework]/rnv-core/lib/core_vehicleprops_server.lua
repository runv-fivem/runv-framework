function lib.setVehicleProperties(vehicle, props)
    Entity(vehicle).state:set('rnv-lib:setVehicleProperties', props, true)
end
