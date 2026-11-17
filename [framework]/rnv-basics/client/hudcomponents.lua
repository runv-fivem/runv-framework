CreateThread(function()
    for _, component in ipairs(Config.HiddenHudComponents) do
        SetHudComponentSize(component, 0.0, 0.0)
    end
    while true do
        for _, control in ipairs(Config.DisabledControls) do
            DisableControlAction(2, control, true)
        end
        Wait(0)
    end
end)

if Config.HideReticle then
    lib.onCache('weapon', function(weapon)
        if not weapon then return end
        CreateThread(function()
            while cache.weapon ~= weapon do Wait(1) end
            while cache.weapon == weapon do
                if not IsFirstPersonAimCamActive() then
                    HideHudComponentThisFrame(14)
                end
                Wait(0)
            end
        end)
    end)
end
