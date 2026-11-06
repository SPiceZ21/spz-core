fx_version 'cerulean'
game 'gta5'

name 'spz-core'
description 'SPiceZ-Core — Framework: bootstrap, sessions, buckets, player profiles, appearance, spawning, analytics'
version '2.0.0'
author 'SPiceZ-Core'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/version.lua',
  'shared/events.lua',
  'shared/emitter.lua',
  'shared/logger.lua',
  -- Merged in from spz-identity, spz-spawn and spz-analytics. Each has its
  -- options under Config.<Name> (Config.Identity is server-only, below).
  'shared/identity_licenses.lua',
  'shared/identity_ranks.lua',
  'config_spawn.lua',
  'config_analytics.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  -- config.lua is NOT listed again here: it is already a shared script, and a
  -- second run (Config = {}) wiped Config.Spawn / Config.Analytics on the server.
  'server/migrations.lua',   -- schema owner: runs before anything touches the DB
  'server/bootstrap.lua',
  'server/config.lua',
  'server/theme.lua',
  'server/sessions.lua',
  'server/buckets.lua',
  'server/permissions.lua',
  'server/cleanup.lua',
  'server/debug.lua',
  'server/environment_sync.lua',

  -- Player profiles, licences, crews (merged from spz-identity)
  'config_identity.lua',
  'server/identity/main.lua',
  'server/identity/connect.lua',
  'server/identity/citizen_id.lua',
  'server/identity/username.lua',
  'server/identity/profile.lua',
  'server/identity/plates.lua',
  'server/identity/licenses.lua',
  'server/identity/ranks.lua',
  'server/identity/crews.lua',
  'server/identity/discord.lua',

  -- Freemode ped and outfits (merged from spz-appearance)
  'server/appearance/main.lua',
  'server/appearance/outfits.lua',
  'server/appearance/crew_outfit.lua',

  -- Spawning (merged from spz-spawn)
  'server/spawn.lua',

  -- Analytics collector (merged from spz-analytics)
  'server/analytics/db.lua',
  'server/analytics/main.lua',
  'server/analytics/race.lua',
  'server/analytics/server.lua',
}

client_scripts {
  'client/main.lua',
  'client/config_sync.lua',
  'client/theme_sync.lua',
  'client/keys.lua',
  'client/environment.lua',
  'client/ghost.lua',
  'client/fade.lua',
  'client/commands.lua',
  'client/radial.lua',
  'client/nui_guard.lua',
  'client/tablet.lua',

  -- Merged in from spz-identity, spz-appearance, spz-spawn and spz-analytics.
  -- The spawn screen is the spz-spawn app in spz-hud; app.lua binds its file to
  -- it. spz-hud is NOT a dependency (it depends on spz-core): app.lua queues
  -- anything sent before spz-hud has started.
  'client/identity/main.lua',
  'client/identity/sync.lua',
  'client/identity/character_creation.lua',
  'client/appearance/outfits.lua',
  'client/appearance/main.lua',
  'client/appearance/commands.lua',
  '@spz-hud/app.lua',
  'client/spawn.lua',
  'client/analytics.lua',
}

dependencies {
  'oxmysql',
  'ox_lib',
  'fivem-appearance',   -- appearance
  'spawnmanager',       -- spawning
}
