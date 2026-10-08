-- server/migrations.lua
-- Single source of truth for the database schema.
--
-- Every migration is applied once, in the order listed below, and recorded in
-- `spz_migrations` by its NAME. Re-running is a no-op, so this is safe on both
-- fresh and long-lived servers.
--
-- Files live in topic folders under spz-core/migrations/ (see the README
-- there). The folder is only where the file sits on disk: the ledger key is
-- the bare file name, which is why moving a file between folders never
-- re-runs it. Rules:
--   * Never rename, renumber or edit a shipped migration; the name is its
--     identity in every server's ledger.
--   * New migration: next number, put it in the folder that fits, append it
--     at the BOTTOM of this list (order is global, not per folder).

local MIGRATIONS = {
    -- number + name (ledger key)          folder
    { "001_core_schema.sql",             "core" },
    { "002_race_columns.sql",            "races" },
    { "003_module_tables.sql",           "core" },
    { "004_identity_columns.sql",        "players" },
    { "005_track_sectors.sql",           "races" },
    { "006_racelines.sql",               "races" },
    { "007_nation_racenumber.sql",       "players" },
    { "008_rivals.sql",                  "rivals" },
    { "009_duels.sql",                   "rivals" },
    { "010_leaderboard_indexes.sql",     "races" },
    { "011_crew_image.sql",              "crews" },
    { "012_crew_settings.sql",           "crews" },
    { "013_crew_invites.sql",            "crews" },
    { "014_crew_rivals.sql",             "crews" },
    { "015_rival_events.sql",            "rivals" },
    { "016_race_number_range.sql",       "players" },
    { "017_player_plate.sql",            "players" },
    { "018_grafana_poll_history.sql",    "analytics" },
    { "019_race_incidents.sql",          "analytics" },
    { "020_player_discord.sql",          "players" },
    { "021_race_replays.sql",            "races" },
    { "022_player_sessions.sql",         "analytics" },
    { "023_player_activity.sql",         "analytics" },
    { "024_race_queue_events.sql",       "analytics" },
    { "025_race_laps.sql",               "analytics" },
    { "026_server_snapshots.sql",        "analytics" },
    { "027_vehicle_usage.sql",           "analytics" },
    { "028_feature_usage.sql",           "analytics" },
    { "029_daily_player_stats.sql",      "analytics" },
    { "030_race_entries.sql",            "analytics" },
    { "031_race_engine_events.sql",      "analytics" },
    { "032_player_rating_history.sql",   "analytics" },
    { "033_connection_attempts.sql",     "analytics" },
    { "034_server_events.sql",           "analytics" },
    { "035_snapshot_entities.sql",       "analytics" },
    { "036_admin_actions.sql",           "analytics" },
    { "037_daily_credit_balances.sql",   "analytics" },
    { "038_rank_points.sql",             "progression" },
    { "039_poll_reroll_votes.sql",       "analytics" },
}

SPZ = SPZ or {}
SPZ.MigrationsReady = false
SPZ.MigrationsFailed = false

-- Anything that queries a SPZ table on boot must wait behind this, or it races
-- the very migration that creates the table it reads.
local function WaitForMigrations(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 60000)
    while not SPZ.MigrationsReady do
        if SPZ.MigrationsFailed then return false end
        if GetGameTimer() > deadline then return false end
        Wait(50)
    end
    return true
end

SPZ.WaitForMigrations = WaitForMigrations
exports("WaitForMigrations", WaitForMigrations)

-- Split a file into individual statements (oxmysql runs one per query).
-- Strips line comments and blank statements.
local function splitStatements(sql)
    local out = {}
    for stmt in (sql .. "\n"):gmatch("(.-);%s*\n") do
        local clean = stmt:gsub("%-%-[^\n]*", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then out[#out + 1] = clean end
    end
    return out
end

local function applyMigration(name, folder)
    local res = GetCurrentResourceName()
    -- Topic folder first; the flat layout is still read so an old copy of the
    -- folder (or a half-finished upload) never blocks a boot.
    local sql = LoadResourceFile(res, ("migrations/%s/%s"):format(folder, name))
             or LoadResourceFile(res, "migrations/" .. name)
    if not sql then
        print(("^1[spz-core] Migration file missing: migrations/%s/%s^0"):format(folder, name))
        return false
    end

    for _, stmt in ipairs(splitStatements(sql)) do
        local ok, err = pcall(function()
            MySQL.query.await(stmt)
        end)
        if not ok then
            -- ADD COLUMN IF NOT EXISTS is unsupported on some MySQL builds;
            -- a duplicate-column error there just means it is already applied.
            local msg = tostring(err)
            if msg:find("Duplicate column") or msg:find("already exists") then
                -- benign, keep going
            else
                print(("^1[spz-core] Migration %s failed: %s^0"):format(name, msg))
                print(("^1[spz-core] Statement: %s^0"):format(stmt:sub(1, 120)))
                return false
            end
        end
    end
    return true
end

CreateThread(function()
    -- Ledger table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `spz_migrations` (
            `name`       VARCHAR(128) NOT NULL PRIMARY KEY,
            `applied_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    local rows = MySQL.query.await("SELECT name FROM spz_migrations") or {}
    local applied = {}
    for _, r in ipairs(rows) do applied[r.name] = true end

    local ran = 0
    for _, m in ipairs(MIGRATIONS) do
        local name, folder = m[1], m[2]
        if not applied[name] then
            print(("^3[spz-core] Applying migration: %s/%s^0"):format(folder, name))
            if applyMigration(name, folder) then
                MySQL.insert.await("INSERT INTO spz_migrations (name) VALUES (?)", { name })
                ran = ran + 1
            else
                SPZ.MigrationsFailed = true
                print("^1[spz-core] Migration run aborted — fix the error above and restart.^0")
                return
            end
        end
    end

    SPZ.MigrationsReady = true
    TriggerEvent("SPZ:migrationsReady")
    if ran > 0 then
        print(("^2[spz-core] Database up to date (%d migration(s) applied).^0"):format(ran))
    else
        print("^2[spz-core] Database up to date (no new migrations).^0")
    end
end)
