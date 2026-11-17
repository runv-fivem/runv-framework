local settings = require 'lib.core_settings'

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key))
        or LoadResourceFile(cache.resource, 'locales/en.json')

    return file and json.decode(file) or {}
end

function lib.getLocaleKey() return settings.locale end

function lib.setLocale(key)
    TriggerEvent('rnv-lib:setLocale', key)
    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(key)
    })
end

RegisterNUICallback('init', function(_, cb)
    cb(1)

    SendNUIMessage({
        action = 'setLocale',
        data = loadLocaleFile(settings.locale)
    })
end)

lib.locale(settings.locale)
