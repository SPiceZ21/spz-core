<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-core
> Framework bootstrap, sessions, state machine, routing buckets · `v1.2.4`

## Scripts

### Shared

| Side   | File                  | Purpose                                        |
| ------ | --------------------- | ---------------------------------------------- |
| Shared | `@spz-lib shared utils` | spz-lib shared utility imports               |
| Shared | `config.lua`          | Core framework configuration                   |
| Shared | `shared/version.lua`  | Version constant and compatibility checks      |
| Shared | `states.lua`          | Global framework state definitions             |
| Shared | `events.lua`          | Shared event name constants                    |
| Shared | `emitter.lua`         | Event emitter utility                          |
| Shared | `logger.lua`          | Core-scoped logger setup                       |

### Server

| Side   | File                    | Purpose                                        |
| ------ | ----------------------- | ---------------------------------------------- |
| Server | `@oxmysql`              | oxmysql database library import                |
| Server | `config.lua`            | Server-side configuration                      |
| Server | `server/main.lua`       | Server entry point and startup sequence        |
| Server | `bootstrap.lua`         | Framework bootstrap and dependency validation  |
| Server | `sessions.lua`          | Player session lifecycle management            |
| Server | `cache.lua`             | Server-side in-memory cache                    |
| Server | `state_machine.lua`     | Framework-level state machine                  |
| Server | `buckets.lua`           | Routing bucket assignment and management       |
| Server | `permissions.lua`       | Permission checks and role management          |
| Server | `registry.lua`          | Resource and player registry                   |
| Server | `middleware.lua`        | Request middleware pipeline                    |
| Server | `cleanup.lua`           | Graceful shutdown and resource cleanup         |
| Server | `player_context.lua`    | Per-player context object                      |
| Server | `debug.lua`             | Debug commands and diagnostics                 |

### Client

| Side   | File                  | Purpose                                        |
| ------ | --------------------- | ---------------------------------------------- |
| Client | `client/main.lua`     | Client entry point, framework initialization   |
| Client | `config_sync.lua`     | Sync server config to client                   |
| Client | `error_relay.lua`     | Relay client errors to server for logging      |

## Dependencies
- spz-lib
- oxmysql
- ox_lib

## CI
Built and released via `.github/workflows/release.yml` on push to `main`.
