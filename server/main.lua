-- spz-core/server/main.lua

-- 1.0 Framework Initialization
-- Most systems are initialized via bootstrap.lua to ensure order.
-- main.lua acts as the primary event bus for top-level core events.

AddEventHandler("SPZ:coreReady", function()
    -- Sync existing players if the resource was restarted
    print("^2[spz-core] Server-side framework initialized. Syncing state...^0")
    
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local source = tonumber(src)
        local session = exports["spz-core"]:GetPlayerSession(source)
        
        if session then
            -- Push config and initial states to the late-joined client
            TriggerClientEvent("SPZ:clientConfig", source, exports["spz-core"]:GetConfig())
            print(string.format("[spz-core] Resynced session for %s (%s)", session.name, source))
        end
    end
end)

-- 1.1 Config Persistence
-- Listen for config changes and broadcast to clients
AddEventHandler("SPZ:configUpdated", function()
    local config = exports["spz-core"]:GetConfig()
    TriggerClientEvent("SPZ:clientConfig", -1, config)
end)

-- 1.2 Exported helper for core status
exports("IsCoreReady", function()
    -- This would be more complex in a production environment
    -- involving checking db status and other modules.
    return true
end)
