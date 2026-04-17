-- server/spawn_manager.lua

local function SpawnPlayer(source, profile)
    if not profile then return end

    -- Map database gender back to model hash
    local spawnModel = "mp_m_freemode_01"
    if profile.gender == 1 then
        spawnModel = "mp_f_freemode_01"
    end

    -- Tell client to execute physical spawning logic
    TriggerClientEvent("SPZ:spawnPlayerTarget", source, spawnModel)
end

-- Catch returning players skipping character creation
AddEventHandler("SPZ:playerReady", function(source, profile)
    SpawnPlayer(source, profile)
end)

-- Catch first-time players who just finished character creation
AddEventHandler("SPZ:characterReady", function(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    SpawnPlayer(source, profile)
end)

-- Catch death listener and force a network respawn
RegisterNetEvent("SPZ:requestRespawn", function()
    local source = source
    local profile = exports["spz-identity"]:GetProfile(source)
    
    if not profile then return end

    -- Re-trigger the same drop logic
    SpawnPlayer(source, profile)
end)
