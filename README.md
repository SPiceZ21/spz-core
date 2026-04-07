![SPiceZ-Core Banner](https://github.com/SPiceZ21/spz-core-media-kit/blob/main/Banner/Banner%232.png?raw=true)

# SPiceZ-Core (`spz-core`)

> **Framework bootstrap and foundation module**  
> Every other `spz-*` module depends on this. No module writes to sessions, states, or buckets without going through `spz-core` exports.

## Overview
`spz-core` acts as the monolith foundation for the FiveM SPiceZ racing ecosystem. It provides the essential glue logic, ensuring that player state, routing buckets, and module initializations occur synchronously and predictably.

## Core Features
1. **Bootstrap & Startup**: Ensures dependencies like `oxmysql` and `spz-lib` load before initializing the SPiceZ systems.
2. **Config System**: Unified operator configurations synced safely to the client.
3. **Event Bus**: Centralized event registry, typed wrappers (`SPZ.Emit`), and middleware interception.
4. **Player Sessions**: In-RAM session cache with batched background DB saving.
5. **State Machine**: Strict finite state handling (`IDLE`, `FREEROAM`, `QUEUED`, `RACING`, `SPECTATING`).
6. **Routing Bucket Manager**: Creates and recycles ephemeral isolation worlds for active races.
7. **Permissions**: Server-side ACE checking and secure command generation (`RegisterSPZCommand`).
8. **Logging**: Leveled output factory and built-in relay for capturing client-side errors to the server console.
9. **Module Registry**: Promise-based dependency gating allowing other `spz-*` modules to await systems before booting.

## Dependencies
- `oxmysql`
- `ox_lib`
- `spz-lib`
- `screenshot-basic` (optional)

## Documentation
Please reference the architecture standard `dotfile` for the complete Table of Contents, full API/Export references, and Event summary.
