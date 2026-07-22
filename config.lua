-- spz-core Operator Configuration

Config = {}

-- General
Config.debug = false

-- Race Settings
Config.intermission_time = 30           -- Time in seconds between races
Config.max_players_per_race = 12        -- Maximum racers per routing bucket
Config.poll_duration = 60               -- How long track voting lasts (seconds)
Config.allowed_classes = {              -- Valid vehicle classes
    "Compacts", "Coupes", "Muscle",
    "Sports Classics", "Sports", "Super"
}

-- Client Display Sync Settings
Config.hud = {
    locale = "en",                      -- Language
    display_units = "mph"               -- "mph" or "kmh"
}

-- Environment Control
Config.disable_npcs = false                 -- Legacy flag: set to true to force completely 0 density for all NPCs

-- NPC & Traffic Density Control (Configurable for all types of ambient peds and vehicles)
Config.NPCs = {
    enabled                = true,          -- Master switch for ambient NPCs and traffic
    
    -- Density Multipliers (0.0 = none, 0.1 - 0.3 = low density, 0.5 = medium, 1.0 = full GTA default)
    vehicle_density        = 0.4,          -- Ambient driving traffic density multiplier
    random_vehicle_density = 0.4,          -- Random spawned traffic density multiplier
    parked_vehicle_density = 0.4,          -- Parked cars along roads and parking lots density multiplier
    ped_density            = 0.3,          -- Walking pedestrians density multiplier
    scenario_ped_density   = 0.3,          -- Sitting / standing scenario peds density multiplier
    ambient_vehicle_range  = 1.5,          -- Spawning range for ambient vehicles multiplier (stable long-distance stream)
    ambient_ped_range      = 1.5,          -- Spawning range for ambient peds multiplier (stable long-distance stream)

    -- Cops, Dispatch & Special Vehicles
    disable_cops           = true,         -- Disable random ambient cop spawns and police calls
    disable_dispatch       = true,         -- Disable GTA emergency dispatch services
    disable_garbage_trucks = true,         -- Disable ambient garbage truck spawns
    disable_random_boats   = true,         -- Disable ambient random boat spawns

    -- Race & Time Trial Bucket Population
    race_population        = false,        -- Set to true to enable low-density ambient population inside race/TT routing buckets
}

-- Engine Anchors
Config.SafeZone = { coords = vector3(-899.6, -2039.5, 9.4), heading = 45.0 }


-- Synced Environment (server-authoritative defaults)
-- Everyone sees the same time & weather unless they set a personal override
-- with /time or /weather (which always wins locally until reset).
Config.Environment = {
    weather = "EXTRASUNNY",   -- canonical weather for the whole server
    hour    = 19,             -- canonical clock (locked golden-hour evening)
    minute  = 30,
}
