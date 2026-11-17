-- Joining, leaving and autosave

local usedLicenses = {} ---@type table<string, integer> identifier -> owning source

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    local license = RNV.GetIdentifier(src)
    deferrals.defer()
    Wait(0)

    if not license then
        return deferrals.done('No valid identifier found. Restart your game.')
    end
    if Config.CheckDuplicateLicense and usedLicenses[license] then
        return deferrals.done('This license is already connected.')
    end
    if not RNV.Ready then
        return deferrals.done('Server is still starting, try again in a moment.')
    end

    deferrals.update(('Loading account for %s...'):format(name))
    local ok, err = pcall(RNV.EnsureUser, src, name)
    if not ok then
        lib.print.error('EnsureUser failed:', err)
        return deferrals.done('Account could not be loaded. Try again.')
    end
    deferrals.done()
end)

AddEventHandler('playerJoining', function()
    local src = source
    local license = RNV.GetIdentifier(src)
    if not license or not Config.CheckDuplicateLicense then return end
    if usedLicenses[license] then
        Wait(0)
        DropPlayer(tostring(src), 'This license is already connected.')
    else
        usedLicenses[license] = tonumber(src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local license = RNV.GetIdentifier(src)
    -- only the real owner frees the license, not a kicked duplicate
    if license and usedLicenses[license] == tonumber(src) then usedLicenses[license] = nil end
    RNV.Logout(src)
end)

-- refill the license list if the resource restarts while people are online
CreateThread(function()
    for _, src in ipairs(GetPlayers()) do
        local license = RNV.GetIdentifier(src)
        if license then usedLicenses[license] = tonumber(src) end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(RNV.Players) do RNV.Save(src) end
end)

CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 60000)
        for src in pairs(RNV.Players) do RNV.Save(src) end
    end
end)
