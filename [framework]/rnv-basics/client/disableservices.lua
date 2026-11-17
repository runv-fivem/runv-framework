CreateThread(function()
    SetMaxWantedLevel(Config.MaxWantedLevel)
    for service, enabled in ipairs(Config.EnabledServices) do
        EnableDispatchService(service, enabled)
    end
end)
