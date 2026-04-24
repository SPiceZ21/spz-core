-- spz-core/server/cleanup.lua
-- Central garbage collector for per-player state.
-- Every module that owns per-player state should listen to SPZ:playerCleanup
-- and nil out its own tables, rather than duplicating disconnect logic.

local function CleanupPlayer(source)
    source = tonumber(source)
    if not source then return end

    -- Release routing bucket so the player isn't stuck in a race instance
    local session = exports["spz-core"]:GetPlayerSession(source)
    if session and session.bucket and session.bucket ~= 0 then
        exports["spz-core"]:AssignPlayerToBucket(source, 0)
    end

    -- Despawn race/freeroam vehicle if one is registered
    if GetResourceState("spz-vehicles") == "started" then
        local ok, err = pcall(function()
            exports["spz-vehicles"]:DespawnVehicle(source)
        end)
        if not ok then
            print(string.format("^3[spz-core:cleanup] DespawnVehicle failed for %d: %s^7", source, tostring(err)))
        end
    end

    -- Remove from any live race session
    if GetResourceState("spz-races") == "started" then
        local ok, err = pcall(function()
            exports["spz-races"]:HandlePlayerDisconnect(source)
        end)
        if not ok then
            print(string.format("^3[spz-core:cleanup] Race disconnect handler failed for %d: %s^7", source, tostring(err)))
        end
    end

    -- Broadcast to all modules that want to clean their own tables
    TriggerEvent("SPZ:playerCleanup", source)

    print(string.format("^2[spz-core:cleanup] Cleaned up player %d^7", source))
end

-- Hook into the drop event fired by sessions.lua
AddEventHandler(SPZ.Events.PLAYER_DISCONNECTED, function(source)
    CleanupPlayer(source)
end)

-- Also handle resource restart edge-case: clean up everyone still online
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local sessions = exports["spz-core"]:GetAllSessions()
    if not sessions then return end
    for src, _ in pairs(sessions) do
        CleanupPlayer(src)
    end
end)

exports("CleanupPlayer", CleanupPlayer)
