fx_version 'cerulean'
game 'gta5'

name 'spz-core'
description 'SPiceZ-Core — Framework bootstrap, sessions, state machine, routing buckets'
version '1.6.2'
author 'SPiceZ-Core'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/version.lua',
  'shared/events.lua',
  'shared/emitter.lua',
  'shared/logger.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config.lua',
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
}

client_scripts {
  'client/main.lua',
  'client/config_sync.lua',
  'client/theme_sync.lua',
  'client/environment.lua',
  'client/ghost.lua',
  'client/fade.lua',
  'client/commands.lua',
  'client/radial.lua',
  'client/nui_guard.lua',
  'client/tablet.lua',
}

dependencies {
  'oxmysql',
  'ox_lib',
}
