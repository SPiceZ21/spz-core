-- config_spawn.lua — spawn points, safe zone, preview location.
-- Moved from spz-spawn/config.lua when it was merged into spz-core. Read as Config.Spawn.<option>.

-- config.lua
-- Falls back to spz-core's own Config for anything not set here, as it did
-- when spz-spawn loaded spz-core's config.lua before this file.
Config.Spawn = setmetatable({}, { __index = Config })
local Config = Config.Spawn
-- Spawn locations
Config.Spawns = {
    {
        label = 'Legion Square',
        coords = vec4(195.17, -933.77, 29.7, 144.5)
    },
    {
        label = 'Paleto Bay',
        coords = vec4(80.35, 6424.12, 31.67, 45.5),
    },
    {
        label = 'Motels',
        coords = vec4(327.56, -205.08, 53.08, 163.5),
    },
}

-- Default fallback if no selection is made (SafeZone)
Config.SafeZone = {
    coords = vec3(195.17, -933.77, 29.7),
    heading = 144.5
}

-- Fixed showcase location for the play-menu / character-creation preview.
-- The ped is placed here (frozen) and the cinematic camera orbits it, so the
-- menu backdrop is always the same scene instead of wherever the ped happens
-- to be. North Chumash coastline — ocean + cliffs behind the character.
Config.PreviewLocation = {
    coords  = vec3(-2168.49, 5187.63, 16.07),
    heading = 200.71,
}
