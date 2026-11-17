-- RUN V bridge (copied from the qbx bridge). Cash is the 'money' item: Core has no cash balance, so no account sync
local Inventory = require 'server.inventory'

local function setupPlayer(player)
    server.setPlayerInventory({
        source = player.source,
        identifier = player.citizenid,
        name = player.name,
        groups = {},
    })
end

AddEventHandler('rnv:server:playerLoaded', function(_, player)
    setupPlayer(player)
end)

AddEventHandler('rnv:server:playerUnloaded', function(source)
    server.playerDropped(source)
end)

SetTimeout(500, function()
    for _, player in pairs(exports['rnv-core']:GetPlayers()) do
        setupPlayer(player)
    end
end)

function server.UseItem() end

function server.setPlayerData(player)
    return { source = player.source, name = player.name, groups = player.groups or {} }
end

function server.syncInventory() end

function server.hasLicense() return false end

function server.isPlayerBoss() return false end

function server.getOwnedVehicleId(entityId)
    return Entity(entityId).state.vehicleid
end
