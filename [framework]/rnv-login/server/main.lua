lib.callback.register('rnv-login:setNickname', function(src, name)
    return exports['rnv-core']:SetName(src, name)
end)
