-- server/spawn_manager.lua

--- Execute the physical spawn on the client.
local function SpawnPlayer(source, profile)
    if not profile then return end
    TriggerClientEvent("SPZ:spawnPlayerTarget", source, { gender = profile.gender or 0 })
end

--- Show the play menu (welcome screen) instead of spawning immediately.
--- The client will call SPZ:requestSpawn when the player clicks ENTER.
local function ShowPlayMenu(source, profile)
    if not profile then return end
    TriggerClientEvent("SPZ:showPlayMenu", source, {
        name   = profile.username or GetPlayerName(source),
        rank   = profile.rank_name or "Rookie",
        tier   = profile.license_tier or 0,
        gender = profile.gender or 0,
    })
end

-- ── Returning players ─────────────────────────────────────────────────────
AddEventHandler("SPZ:playerReady", function(source, profile)
    ShowPlayMenu(source, profile)
end)

-- ── New players (just finished character creation) ────────────────────────
AddEventHandler("SPZ:characterReady", function(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    ShowPlayMenu(source, profile)
end)

-- ── Player clicked ENTER in play menu ─────────────────────────────────────
RegisterNetEvent("SPZ:requestSpawn")
AddEventHandler("SPZ:requestSpawn", function()
    local source  = source
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return end
    SpawnPlayer(source, profile)
end)

-- ── Respawn after death ────────────────────────────────────────────────────
RegisterNetEvent("SPZ:requestRespawn")
AddEventHandler("SPZ:requestRespawn", function()
    local source  = source
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return end
    SpawnPlayer(source, profile)
end)
