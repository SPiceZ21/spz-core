-- server/migrations.lua
-- Single source of truth for the database schema.
--
-- Every .sql in spz-core/migrations/ is applied once, in order, and recorded in
-- `spz_migrations`. Re-running is a no-op, so this is safe on both fresh and
-- long-lived servers. Add a new numbered file + list it below; never edit an
-- already-shipped migration.

local MIGRATIONS = {
    "001_core_schema.sql",
    "002_race_columns.sql",
    "003_module_tables.sql",
    "004_identity_columns.sql",
    "005_track_sectors.sql",
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

local function applyMigration(name)
    local sql = LoadResourceFile(GetCurrentResourceName(), "migrations/" .. name)
    if not sql then
        print(("^1[spz-core] Migration file missing: %s^0"):format(name))
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
    for _, name in ipairs(MIGRATIONS) do
        if not applied[name] then
            print(("^3[spz-core] Applying migration: %s^0"):format(name))
            if applyMigration(name) then
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
