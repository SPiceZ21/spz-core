fx_version 'cerulean'
game 'gta5'

name 'spz-core'
description 'SPiceZ-Core — Framework bootstrap, sessions, state machine, routing buckets'
version '1.0.0'
author 'SPiceZ-Core'

shared_scripts {
  '@spz-lib/shared/main.lua',
  '@spz-lib/shared/callbacks.lua',
  '@spz-lib/shared/notify.lua',
  '@spz-lib/shared/timer.lua',
  '@spz-lib/shared/logger.lua',
  '@spz-lib/shared/math.lua',
  '@spz-lib/shared/table.lua',
  '@spz-lib/shared/string.lua',
  'config.lua',
  'shared/version.lua',
  'shared/states.lua',
  'shared/events.lua',
  'shared/emitter.lua',
  'shared/logger.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config.lua',
  'server/main.lua',
  'server/bootstrap.lua',
  'server/config.lua',
  'server/sessions.lua',
  'server/cache.lua',
  'server/state_machine.lua',
  'server/buckets.lua',
  'server/permissions.lua',
  'server/registry.lua',
  'server/middleware.lua',
  'server/debug.lua',
  'server/spawn_manager.lua',
}

client_scripts {
  'client/main.lua',
  'client/config_sync.lua',
  'client/error_relay.lua',
  'client/spawn_manager.lua',
}

dependencies {
  'spz-lib',
  'oxmysql',
  'ox_lib',
}
