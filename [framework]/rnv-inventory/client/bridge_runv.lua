-- RUN V bridge (copied from the qbx bridge). No groups or hunger/thirst yet
AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_, _, value)
    if not value then client.onLogout() end
end)

function client.setPlayerStatus() end
