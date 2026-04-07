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
