-- square minimap top-left

local function placeMinimap()
    RequestStreamedTextureDict('squaremap', false)
    while not HasStreamedTextureDictLoaded('squaremap') do Wait(0) end
    SetMinimapClipType(0)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    SetMinimapComponentPosition('minimap', 'L', 'T', 0.0174, 0.0295, 0.1106, 0.167)
    SetMinimapComponentPosition('minimap_mask', 'L', 'T', 0.0174, 0.0595, 0.0864, 0.1826)
    SetMinimapComponentPosition('minimap_blur', 'L', 'T', 0.0107, -0.0155, 0.1769, 0.274)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    -- toggling the bigmap applies the new positions
    SetBigmapActive(true, false)
    Wait(50)
    SetBigmapActive(false, false)
end

CreateThread(function()
    placeMinimap()
    local minimap = RequestScaleformMovie('minimap')
    while not HasScaleformMovieLoaded(minimap) do Wait(0) end
    while true do
        -- 3 = hide GTA's health/armor bars under the map
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        Wait(500)
    end
end)
