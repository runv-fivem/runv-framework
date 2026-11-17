Config = {}

-- Where the player enters the world after PLAY / creator (until prison/motel exist)
Config.Spawn = vec4(-540.58, -212.02, 37.65, 208.88)

-- Returning player: sits here while the PLAY button shows
Config.Scene = {
    coords = vec4(-534.79, -306.00, 34.88, 23.5), -- prop_bench_09 near city hall
    scenario = 'PROP_HUMAN_SEAT_BENCH',
    camOffset = vec3(0.9, 3.4, 0.55), -- from the ped (x right, y forward, z up)
    camLook = vec3(0.9, 0.0, 0.1),
    fov = 45.0,
}

-- New player: stands here for the nickname screen and the creator
Config.Creator = {
    coords = vec4(1757.93, 2492.51, 45.74, 210.0),
    camOffset = vec3(0.45, 1.6, 0.45),
    camLook = vec3(0.45, 0.0, 0.45),
    fov = 40.0,
}
