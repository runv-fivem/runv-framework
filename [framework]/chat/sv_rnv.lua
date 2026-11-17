-- RNV additions: nickname as author, Party channel, real clock for timestamps

local function nickname(src)
    local player = GetResourceState('rnv-core') == 'started' and exports['rnv-core']:GetPlayer(src)
    return player and player.name
end

-- Player messages use the RNV nickname instead of the FiveM name
exports.chat:registerMessageHook(function(source, outMessage, hook)
    local name = source > 0 and nickname(source)
    if name and #outMessage.args > 1 then
        hook.updateMessage({ args = { name, outMessage.args[#outMessage.args] } })
    end
end)

-- Party channel (Tab in the chat input switches All / Party)
exports.chat:registerMode({
    name = 'party',
    displayName = 'Party',
    color = '#76ff46',
    isChannel = true,
    cb = function(source, outMessage, hook)
        local members = { source }
        if GetResourceState('rnv-party') == 'started' then
            members = exports['rnv-party']:GetPartyMembers(source)
        end
        hook.setRouting(members)
    end,
})

local function secondsOfDay()
    local t = os.date('*t')
    return t.hour * 3600 + t.min * 60 + t.sec
end

AddEventHandler('chat:init', function()
    TriggerClientEvent('rnv-chat:clock', source, secondsOfDay())
end)
