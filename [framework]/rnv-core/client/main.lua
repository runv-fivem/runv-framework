-- Client copy of the player data, the server has the real one
-- Spawning is done by rnv-login

RNV = {}
RNV.PlayerData = {}
RNV.IsLoggedIn = false

RegisterNetEvent('rnv:client:playerLoaded', function(data)
    RNV.PlayerData = data
    RNV.IsLoggedIn = true
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
    TriggerEvent('rnv:client:onPlayerLoaded', data)
end)

RegisterNetEvent('rnv:client:setPlayerData', function(data)
    RNV.PlayerData = data
    TriggerEvent('rnv:client:onPlayerDataChanged', data)
end)

RegisterNetEvent('rnv:client:playerUnloaded', function()
    RNV.PlayerData = {}
    RNV.IsLoggedIn = false
    TriggerEvent('rnv:client:onPlayerUnloaded')
end)

-- ask the server to log us in once the session is up
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(100) end
    exports.spawnmanager:setAutoSpawn(false)
    TriggerServerEvent('rnv:server:login')
end)

exports('GetPlayerData', function() return RNV.PlayerData end)
exports('IsLoggedIn', function() return RNV.IsLoggedIn end)
