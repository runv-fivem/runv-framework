-- Notify({ text = 'Hi [[world]]', type, duration, countdown, keys, id }); [[ ]] highlights

local function notify(data)
    if type(data) == 'string' then data = { text = data } end
    SendNUIMessage({
        action = 'notify',
        id = data.id,
        text = tostring(data.text or ''),
        color = Config.NotifyColors[data.type or 'inform'] or Config.NotifyColors.inform,
        duration = data.duration or Config.NotifyDuration,
        countdown = data.countdown,
        keys = data.keys,
    })
end

local function removeNotify(id)
    SendNUIMessage({ action = 'notify:remove', id = id })
end

RegisterNetEvent('rnv-interface:notify', notify)
exports('Notify', notify)
exports('RemoveNotify', removeNotify)
