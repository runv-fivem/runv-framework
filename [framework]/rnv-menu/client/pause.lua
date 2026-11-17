-- Pause menu on ESC (replaces the GTA pause menu; P still opens the GTA map)

local isOpen = false

local function canOpen()
    return LocalPlayer.state['rnv:spawned'] == true
        and not LocalPlayer.state.invOpen
        and not IsNuiFocused()
        and not IsPauseMenuActive()
end

local function closePause()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'pause:close' })
end

function OpenPause()
    if LocalPlayer.state.invOpen then return end
    local data = exports['rnv-core']:GetPlayerData()
    isOpen = true
    SendNUIMessage({
        action = 'pause:open',
        name = data.name,
        uid = data.userId,
        party = GetResourceState('rnv-party') == 'started',
        clan = GetResourceState('rnv-clans') == 'started',
        discord = Config.DiscordUrl ~= '',
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('pause:close', function(_, cb)
    cb(1)
    closePause()
end)

RegisterNUICallback('pause:party', function(_, cb)
    cb(1)
    closePause()
    exports['rnv-party']:OpenParty()
end)

RegisterNUICallback('pause:clan', function(_, cb)
    cb(1)
    closePause()
    exports['rnv-clans']:Open()
end)

RegisterNUICallback('pause:settings', function(_, cb)
    cb(1)
    isOpen = false
    SendNUIMessage({ action = 'pause:close' })
    OpenSettings(true)
end)

RegisterNUICallback('pause:discord', function(_, cb)
    cb(1)
    SendNUIMessage({ action = 'pause:url', url = Config.DiscordUrl })
end)

RegisterNUICallback('pause:exit', function(_, cb)
    cb(1)
    ExecuteCommand('quit')
end)

-- ESC (control 200) is disabled every frame so the GTA pause menu never opens on it
-- The ESC that closes another UI (e.g. rnv-inventory) must not open this menu too
CreateThread(function()
    local otherUiAt = 0
    while true do
        Wait(0)
        DisableControlAction(0, 200, true)
        if LocalPlayer.state.invOpen or IsNuiFocused() then otherUiAt = GetGameTimer() end
        if IsDisabledControlJustPressed(0, 200) and not isOpen and canOpen() and GetGameTimer() - otherUiAt > 500 then
            OpenPause()
        end
        -- The GTA SETTINGS tab (P map -> tabs) is replaced by the RNV settings screen
        if not GtaDriving and IsGtaSettingsTab() then
            SetPauseMenuActive(false)
            OpenSettings(false)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then closePause() end
end)

exports('OpenPause', OpenPause)
