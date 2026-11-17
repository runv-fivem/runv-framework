-- Clean sky, no fog or dust : CLEAR weather every 500 ms + a
-- timecycle modifier with less haze. RNV: no clouds or rain either. /rnv_clearsky toggles it on this client to compare
local WEATHER = 'CLEAR'
local TIMECYCLE = 'CS1_railwayB_tunnel'
local enabled = true

CreateThread(function()
    while true do
        if enabled then
            SetWeatherTypePersist(WEATHER)
            SetWeatherTypeNowPersist(WEATHER)
            SetWeatherTypeNow(WEATHER)
            SetOverrideWeather(WEATHER)
            SetTimecycleModifier(TIMECYCLE)
            ClearCloudHat()
            SetCloudsAlpha(0.0)
            SetRainLevel(0.0)
        end
        Wait(500)
    end
end)

RegisterCommand('rnv_clearsky', function()
    enabled = not enabled
    if not enabled then
        ClearOverrideWeather()
        ClearTimecycleModifier()
        SetCloudsAlpha(1.0)
        SetRainLevel(-1.0)
    end
    print('[rnv-utils] clear sky ' .. (enabled and 'on' or 'off'))
end, false)
