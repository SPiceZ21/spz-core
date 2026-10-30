# spz-core

> Framework bootstrap: sessions, routing buckets, permissions, theme and the database schema.

![version](https://img.shields.io/badge/version-1.14.0-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

The foundation every other module builds on. It owns player sessions, the routing-bucket manager, permissions, the shared UI theme, the radial menu and the **database schema** — every `.sql` file in `migrations/` is applied once on boot and recorded in `spz_migrations`, so no other module ships SQL. `SPZ:coreReady` fires only after migrations finish.

## Features

- Automatic schema migrations on boot (`migrations/`)
- Routing-bucket registry used by races, minigames and spectate
- Server-authoritative time and weather
- Global player phasing (ghosting) outside contact modes
- Radial menu (`Z`) built from whichever modules are running
- Theme convars (`spz_theme_*`) shared by every SPiceZ UI
- Rockstar Editor recording shortcuts

## Requirements

| Resource | Type |
|---|---|
| `oxmysql` | third-party |
| `ox_lib` | third-party |

## Installation

Included in the [txAdmin recipe](https://github.com/SPiceZ21/spz-txrecipe). Manual install:

1. Download `spz-core` from GitHub (latest release, or the repository) into your `resources` folder.
2. Add to `server.cfg`, after its requirements:

```cfg
ensure spz-core
```

## Configuration

- `client/config_sync.lua`
- `config.lua`
- `server/config.lua`

See the file for every option.

## Commands

| Command | Who | Description |
|---|---|---|
| `/discardclip` | player | Stop recording without saving |
| `/editor` | player | Open the Rockstar Editor |
| `/fix` | player | Repair the vehicle you are in |
| `/menu` | player | Open the radial menu |
| `/record` | player | Start recording a Rockstar Editor clip (again: stop and save) |
| `/stoprecord` | player | Stop and save the clip |
| `/time` | player | Local time preview |
| `/weather` | player | Local weather preview |
| `/freezetime` | admin | Freeze / unfreeze server time |
| `/spz` | admin | `/spz <sub>` — framework diagnostics and hot reload |
| `/spzbuckets` | admin | List routing buckets and who is in them |
| `/synctime` | admin | Set server time |
| `/syncweather` | admin | Set server weather |
| `/tpm` | admin | Teleport to your waypoint, or to a player id |
| `/keydebug` | dev | Show what GTA reports for a key binding |
| `/phasing` | dev | Print collision/phasing state |

## Exports

| Export | Side |
|---|---|
| `AssignPlayerToBucket` | server |
| `CreateBucket` | server |
| `CreateSession` | server |
| `DeleteBucket` | server |
| `FadeHold` | client |
| `FadeIn` | client |
| `FadeOut` | client |
| `FadeTransition` | client |
| `GetAllSessions` | server |
| `GetBucketPlayers` | server |
| `GetBucketRegistry` | server |
| `GetConfig` | client / server |
| `GetPlayerBucket` | server |
| `GetPlayerSession` | server |
| `GetTheme` | client / server |
| `GetVersion` | shared |
| `HasPermission` | server |
| `IsAdmin` | server |
| `KeyFor` | client |
| `KeyForControl` | client |
| `PadLabel` | client |
| `RefreshRadial` | client |
| `RegisterBucket` | server |
| `ReloadConfig` | server |
| `ReloadTheme` | server |
| `RemovePlayerFromBucket` | server |
| `SetSyncedTime` | server |
| `SetSyncedWeather` | server |
| `StartTablet` | client |
| `StopTablet` | client |
| `UsingPad` | client |
| `WaitForMigrations` | server |

```lua
exports["spz-core"]:AssignPlayerToBucket(...)
```

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
