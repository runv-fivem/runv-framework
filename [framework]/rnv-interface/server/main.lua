lib.callback.register('rnv-interface:ping', function(src)
    return GetPlayerPing(src)
end)

-- server notify: Notify(src, data)
exports('Notify', function(src, data)
    TriggerClientEvent('rnv-interface:notify', src, data)
end)
