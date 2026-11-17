function lib.getClosestPlayer(coords, maxDistance, includePlayer)
	local players = GetActivePlayers()
	local closestId, closestPed, closestCoords, closestVehicle
	maxDistance = maxDistance or 2.0

	for i = 1, #players do
		local playerId = players[i]

		if playerId ~= cache.playerId or includePlayer then
			local playerPed = GetPlayerPed(playerId)
			local playerCoords = GetEntityCoords(playerPed)

            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local playerCoords = vehicle == 0 and GetEntityCoords(playerPed) or GetWorldPositionOfEntityBone(playerPed, 0)
            
			local distance = #(coords - playerCoords)

			if distance < maxDistance then
				maxDistance = distance
				closestId = playerId
				closestPed = playerPed
				closestCoords = playerCoords
                closestVehicle = vehicle
			end
		end
	end

	return closestId, closestPed, closestCoords, closestVehicle
end

return lib.getClosestPlayer
