# spz-core migrations

The whole database schema. `server/migrations.lua` runs these on boot, once
each, in the order its `MIGRATIONS` list gives, and records every one in the
`spz_migrations` table by **file name**.

| Folder       | What lives there                                        | Files |
|--------------|---------------------------------------------------------|-------|
| `core/`      | Base schema and shared module tables                    | 001, 003 |
| `players/`   | Columns on `players`: identity, nation, number, plate, Discord | 004, 007, 016, 017, 020 |
| `races/`     | Results, sectors, racelines, leaderboard indexes, replays | 002, 005, 006, 010, 021 |
| `crews/`     | Crew image, settings, invites, crew rivals              | 011, 012, 013, 014 |
| `rivals/`    | Rivals, duels, rival events                             | 008, 009, 015 |
| `analytics/` | Grafana data: poll history, race incidents, sessions, activity, race funnel, laps, server snapshots, vehicle usage, feature usage, daily player stats, race entries (car / ping / FPS), race engine events, rating history, connection attempts, server events, entity counts, admin actions, daily credit balances (written by spz-analytics) | 018, 019, 022-037 |

## Rules

- **Never rename, renumber or edit a shipped file.** Its name is its identity
  in every server's ledger; a renamed file is "new" and runs again.
- Moving a file to another folder is safe: the folder is not part of the name.
  (Update its folder in the `MIGRATIONS` list when you do.)
- **Adding one:** take the next number (`022_...`), put it in the folder that
  fits (or a new one), and add `{ "022_....sql", "folder" }` at the **bottom**
  of the list. Order is global, not per folder.
- Write it so it can run on a database that already has it:
  `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`,
  `ADD INDEX IF NOT EXISTS`.
