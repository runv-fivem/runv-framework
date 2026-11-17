function lib.getNearbyPlayers(coords, maxDistance, includePlayer)
    local players = GetActivePlayers()
    local nearby = {}
    local count = 0
    maxDistance = maxDistance or 2.0

    for i = 1, #players do
        local playerId = players[i]

        if playerId ~= cache.playerId or includePlayer then
            local playerPed = GetPlayerPed(playerId)
            
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local playerCoords = vehicle == 0 and GetEntityCoords(playerPed) or GetWorldPositionOfEntityBone(playerPed, 0)
            
            local distance = #(coords - playerCoords)

            if distance < maxDistance then
                count = count + 1
                nearby[count] = {
                    id = playerId,
                    ped = playerPed,
                    coords = playerCoords,
                    vehicle = vehicle
                }
            end
        end
    end

    return nearby
end

return lib.getNearbyPlayers
