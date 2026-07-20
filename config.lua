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
Config.disable_npcs = true                  -- Set to true to disable all ambient NPCs, traffic, and random cops

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

