

local settings = require 'lib.core_settings'

function lib.notify(data)
    local sound = settings.notification_audio and data.sound
    local payload = table.clone(data)
    payload.sound = nil
    payload.position = payload.position or settings.notification_position

    SendNUIMessage({
        action = 'notify',
        data = payload
    })

    if not sound then return end

    if sound.bank then lib.requestAudioBank(sound.bank) end

    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, sound.name, sound.set, true)
    ReleaseSoundId(soundId)

    if sound.bank then ReleaseNamedScriptAudioBank(sound.bank) end
end


function lib.defaultNotify(data)
    -- Backwards compat for v3
    data.type = data.status
    if data.type == 'inform' then data.type = 'info' end
    return lib.notify(data)
end

RegisterNetEvent('rnv-lib:notify', lib.notify)
RegisterNetEvent('rnv-lib:defaultNotify', lib.defaultNotify)
