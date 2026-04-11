<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-core

### Framework Bootstrap & Foundation

*The single source of truth for every `spz-*` module. No module writes to sessions, states, or routing buckets without going through here.*

<br/>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-orange.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=flat-square)](https://fivem.net)
[![Lua](https://img.shields.io/badge/Lua-5.4-blue?style=flat-square&logo=lua)](https://lua.org)
[![Status](https://img.shields.io/badge/Status-In%20Development-green?style=flat-square)]()

</div>

---

## Overview

`spz-core` is the monolithic foundation of the SPiceZ racing ecosystem. It boots first, initializes all shared infrastructure, and gates every other module behind a reliable startup chain. If `spz-core` isn't ready, nothing else runs.

Every player state transition, routing bucket operation, permission check, and inter-module communication passes through the exports and events registered here — ensuring a predictable, server-authoritative runtime with no race conditions between modules.

---

## Features

- **Ordered Bootstrap** — Config loader → schema validator → DB ping → session manager → state machine → bucket manager → module registry → `SPZ:coreReady`
- **Config System** — Unified `config.lua` with hot-reload for non-structural keys (`/spz reloadconfig`). Client-safe subset synced on connect.
- **Player State Machine** — Strict finite states: `IDLE` → `FREEROAM` → `QUEUED` → `RACING` → `SPECTATING`. Illegal transitions are rejected server-side.
- **Player Sessions** — In-RAM session cache with batched DB saves every 60s and on disconnect.
- **Routing Bucket Manager** — Creates and recycles ephemeral FiveM routing buckets for race world isolation. Entity lockdown set to `strict` on creation.
- **Event Bus** — Typed `SPZ.Emit` wrappers and middleware interception for all cross-module events.
- **ACE Permissions** — Server-side only. `spz.admin` / `spz.moderator` / `spz.spectate` / `spz.dev` roles with `RegisterSPZCommand` guard.
- **Structured Logging** — Per-module bound loggers with leveled output and a client-side error relay to the server console.
- **Module Registry** — Promise-based dependency gating. Modules call `RequireModule` and block until the dependency registers.

---

## Dependencies

| Resource | Version | Role |
|---|---|---|
| `oxmysql` | 2.0.0+ | Database operations |
| `ox_lib` | Latest | Shared utilities |
| `spz-lib` | 1.0.0+ | SPZ utility layer |
| `screenshot-basic` | — | Optional — client error screenshots |

---

## Installation

Load order is enforced. `spz-core` must come after `spz-lib`:

```cfg
ensure oxmysql
ensure ox_lib
ensure screenshot-basic   # optional

ensure spz-lib
ensure spz-core

# all other spz-* modules follow here
```

---

## Player States

| State | Description |
|---|---|
| `IDLE` | Connected, no mode selected |
| `FREEROAM` | Spawned car, free driving in bucket 0 |
| `QUEUED` | Waiting in race queue |
| `RACING` | Inside an active race routing bucket |
| `SPECTATING` | Admin observer — no vehicle, no collision |

Legal transitions:
```
IDLE       → FREEROAM, QUEUED
FREEROAM   → IDLE, QUEUED
QUEUED     → RACING, IDLE
RACING     → IDLE
SPECTATING → IDLE
```

---

## Exports Reference

```lua
-- Config
exports["spz-core"]:GetVersion()
exports["spz-core"]:GetConfig(key)

-- Sessions
exports["spz-core"]:GetPlayerSession(source)
exports["spz-core"]:GetAllSessions()
exports["spz-core"]:GetCache(source, key)
exports["spz-core"]:SetCache(source, key, value)

-- State machine
exports["spz-core"]:GetPlayerState(source)
exports["spz-core"]:SetPlayerState(source, state)
exports["spz-core"]:GetStateHistory(source)

-- Routing buckets
exports["spz-core"]:CreateBucket(label)             -- returns bucketId
exports["spz-core"]:DeleteBucket(id)                -- errors if players remain
exports["spz-core"]:AssignPlayerToBucket(source, id)
exports["spz-core"]:RemovePlayerFromBucket(source)  -- returns player to bucket 0
exports["spz-core"]:GetBucketPlayers(id)
exports["spz-core"]:GetBucketRegistry()

-- Permissions
exports["spz-core"]:IsAdmin(source)
exports["spz-core"]:HasPermission(source, ace)

-- Module registry
exports["spz-core"]:RegisterModule(name, version)
exports["spz-core"]:RequireModule(name)
exports["spz-core"]:GetRegisteredModules()
```

---

## Key Events

| Event | Direction | Payload |
|---|---|---|
| `SPZ:coreReady` | Server | — |
| `SPZ:playerConnected` | Server | `source` |
| `SPZ:playerDisconnected` | Server | `source, reason` |
| `SPZ:stateChanged` | Server + Client | `source, oldState, newState` |
| `SPZ:bucketChanged` | Server | `source, oldBucket, newBucket` |
| `SPZ:clientConfig` | Client | `configSubset` |

---

## Admin Commands

```
/spz status          -- show all registered modules and health
/spz info [source]   -- show player session, state, and state history
/spz reloadconfig    -- hot-reload non-structural config keys
/spz debug           -- toggle debug logging
```

---

## ACE Roles

| ACE | Role |
|---|---|
| `spz.admin` | Full access |
| `spz.moderator` | Kick, spectate, view stats |
| `spz.spectate` | Observer mode only |
| `spz.dev` | Debug commands, hot-reload |

---

<div align="center">

*Part of the [SPiceZ-Core](https://github.com/SPiceZ-Core) ecosystem*

**[Docs](https://github.com/SPiceZ-Core/spz-docs) · [Discord](https://discord.gg/) · [Issues](https://github.com/SPiceZ-Core/spz-core/issues)**

</div>
