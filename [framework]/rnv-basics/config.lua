Config = {}

-- GTA dispatch services (EnableDispatchService): true = on
Config.MaxWantedLevel = 0
Config.EnabledServices = {
    [1] = false,  -- PoliceAutomobile
    [2] = false,  -- PoliceHelicopter
    [3] = false,  -- FireDepartment
    [4] = false,  -- SwatAutomobile
    [5] = false,  -- AmbulanceDepartment
    [6] = false,  -- PoliceRiders
    [7] = false,  -- PoliceVehicleRequest
    [8] = true,   -- PoliceRoadBlock
    [9] = false,  -- PoliceAutomobileWaitPulledOver
    [10] = false, -- PoliceAutomobileWaitCruising
    [11] = false, -- Gangs
    [12] = false, -- SwatHelicopter
    [13] = false, -- PoliceBoat
    [14] = false, -- ArmyVehicle
    [15] = false, -- BikerBackup
}

Config.DisableIdleCamera = true
Config.DisableAmbience = true -- distant sirens, car alarms

Config.BlacklistedScenarioTypes = {
    'WORLD_VEHICLE_AMBULANCE',
    'WORLD_VEHICLE_FIRE_TRUCK',
    'WORLD_VEHICLE_POLICE_BIKE',
    'WORLD_VEHICLE_POLICE_CAR',
    'WORLD_VEHICLE_POLICE',
    'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
    'WORLD_VEHICLE_SECURITY_CAR',
    'WORLD_VEHICLE_HELI_LIFEGUARD',
    'WORLD_VEHICLE_MILITARY_PLANES_BIG',
    'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
}

Config.SuppressedModels = {
    'SHAMAL', 'LUXOR', 'LUXOR2', 'JET', 'LAZER', 'TITAN',
    'CRUSADER', 'RHINO', 'AIRTUG', 'RIPLEY', 'BLIMP',
}

Config.BlacklistedScenarioGroups = {
    'LSA_Planes',
    'SANDY_PLANES',
    'GRAPESEED_PLANES',
    'ng_planes',
}

-- HUD parts hidden every frame (HideHudComponentThisFrame ids)
Config.HiddenHudComponents = { 1, 2, 3, 4, 7, 9, 13, 19, 20, 21, 22 }
-- Controls turned off every frame (control ids)
Config.DisabledControls = { 37 } -- weapon wheel (TAB)
Config.HideReticle = true

-- 0.0 = none, 1.0 = GTA Online rates
Config.Density = {
    parked = 0.8,
    vehicle = 0.8,
    randomvehicles = 0.8,
    peds = 0.8,
    scenario = 0.8,
}
