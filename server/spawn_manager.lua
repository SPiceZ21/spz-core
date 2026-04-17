-- server/spawn_manager.lua

local function SpawnPlayer(source, profile)
    if not profile then return end

    local data = {
        gender = profile.gender
    }

    -- Tell client to execute physical spawning logic
    TriggerClientEvent("SPZ:spawnPlayerTarget", source, data)
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
