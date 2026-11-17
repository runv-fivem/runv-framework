-- NPC groups stay neutral to players
local neutralGroups = {
    'AMBIENT_GANG_HILLBILLY', 'AMBIENT_GANG_BALLAS', 'AMBIENT_GANG_MEXICAN', 'AMBIENT_GANG_FAMILY',
    'AMBIENT_GANG_MARABUNTE', 'AMBIENT_GANG_SALVA', 'AMBIENT_GANG_LOST',
    'GANG_1', 'GANG_2', 'GANG_9', 'GANG_10', 'FIREMAN', 'MEDIC', 'COP', 'PRISONER',
}
for _, group in ipairs(neutralGroups) do
    SetRelationshipBetweenGroups(1, joaat(group), joaat('PLAYER'))
end

CreateThread(function()
    local d = Config.Density
    while true do
        SetParkedVehicleDensityMultiplierThisFrame(d.parked)
        SetVehicleDensityMultiplierThisFrame(d.vehicle)
        SetRandomVehicleDensityMultiplierThisFrame(d.randomvehicles)
        SetPedDensityMultiplierThisFrame(d.peds)
        SetScenarioPedDensityMultiplierThisFrame(d.scenario, d.scenario)
        Wait(0)
    end
end)
