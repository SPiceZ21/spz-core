# spz-core

> Framework bootstrap, sessions, routing buckets, config and schema · `v2.0.0`

## Overview

`spz-core` boots the framework and owns everything the other modules share: player
sessions, the routing-bucket manager, the server config, permissions and — importantly —
the **database schema**. Every `.sql` file in `migrations/` is applied once on boot and
recorded in the `spz_migrations` table, so no other module ships SQL.

`SPZ:coreReady` fires only after migrations finish, so nothing ever queries a half-built
database.

## Structure

| Side | File | Purpose |
|---|---|---|
| Shared | `config.lua` | Framework configuration |
| Shared | `shared/version.lua` | Version constant and compatibility check |
| Shared | `shared/events.lua` | Shared event name constants |
| Shared | `shared/emitter.lua` | Event emitter utility |
| Shared | `shared/logger.lua` | Core-scoped logger |
| Server | `server/migrations.lua` | Schema owner — applies `migrations/*.sql` before anything else |
| Server | `server/main.lua` | Entry point and startup sequence |
| Server | `server/bootstrap.lua` | Dependency validation, module registration |
| Server | `server/config.lua` | Server-side config resolution |
| Server | `server/sessions.lua` | Player session lifecycle |
| Server | `server/cache.lua` | In-memory server cache |
| Server | `server/buckets.lua` | Routing bucket creation and assignment |
| Server | `server/permissions.lua` | Permission and admin checks |
| Server | `server/registry.lua` | Module registry |
| Server | `server/middleware.lua` | Request middleware pipeline |
| Server | `server/cleanup.lua` | Disconnect and shutdown cleanup |
| Server | `server/player_context.lua` | Per-player context object |
| Server | `server/environment_sync.lua` | Server-authoritative time and weather baseline |
| Server | `server/debug.lua` | Debug commands and diagnostics |
| Client | `client/main.lua` | Client init |
| Client | `client/config_sync.lua` | Pulls server config to the client |
| Client | `client/error_relay.lua` | Relays client errors to the server log |
| Client | `client/environment.lua` | Local time and weather application |
| Client | `client/ghost.lua` | Global player/vehicle no-collision |
| Client | `client/fade.lua` | Screen fade helpers |
| Client | `client/commands.lua` | Client commands |

## Migrations

`migrations/` is the single source of truth for the schema:

| File | Adds |
|---|---|
| `001_core_schema.sql` | Base tables |
| `002_race_columns.sql` | Race session and result columns |
| `003_module_tables.sql` | Per-module tables |
| `004_identity_columns.sql` | Identity profile columns |
| `005_track_sectors.sql` | Sector timing |
| `006_racelines.sql` | `racelines` table |
| `007_nation_racenumber.sql` | Nation flag and race number |
| `008_rivals.sql` | Rivals |
| `009_duels.sql` | Duels |

Add schema changes as a new numbered file. Never edit an applied one.

## Exports

| Group | Exports |
|---|---|
| Sessions | `CreateSession` · `GetPlayerSession` · `GetAllSessions` · `CleanupPlayer` |
| Buckets | `CreateBucket` · `DeleteBucket` · `AssignPlayerToBucket` · `RemovePlayerFromBucket` · `GetPlayerBucket` · `GetBucketPlayers` · `GetBucketRegistry` · `SetContextBucket` |
| State | `SetPlayerMode` · `IsPlayerInMode` · `GetPlayerContext` |
| Modules | `RegisterModule` · `RequireModule` · `GetRegisteredModules` · `IsCoreReady` · `WaitForMigrations` · `GetVersion` |
| Config / cache | `GetConfig` · `GetCache` · `SetCache` |
| Permissions | `HasPermission` · `IsAdmin` |
| Environment | `SetSyncedTime` · `SetSyncedWeather` |
| Fade (client) | `FadeIn` · `FadeOut` · `FadeHold` · `FadeTransition` |
| Misc | `RegisterSPZCommand` · `RelayError` |

```lua
local session = exports['spz-core']:GetPlayerSession(source)
exports['spz-core']:AssignPlayerToBucket(source, bucketId)
```

## Events

| Event | Meaning |
|---|---|
| `SPZ:coreReady` | Core initialised and migrations applied |
| `SPZ:playerConnected` | Session created for a cleared player |
| `SPZ:playerDisconnected` | Session teardown |

## Commands

`/spz` · `/status` · `/fix` · `/tpm` · `/time` · `/weather` · `/synctime` · `/syncweather`

## Dependencies

`oxmysql` · `ox_lib`

---

Part of [SPiceZ-Core](../README.md) · GPL-3.0
