-- 3.4 Debug Event Logger
-- SPZ.Emit wrapper outputs are hooked locally if debug toggles on.

SPZ = SPZ or {}

-- Temporary boolean to handle the toggle command
local DebugActive = exports["spz-core"]:GetConfig("debug") or false

-- Command to toggle at runtime
RegisterCommand("spz", function(source, args)
    if args[1] == "debug" then
        -- Ideally check `spz.dev` or `spz.admin` via permissions system
        -- This basic permission check validates them until the full ACE wrapper operates
        if source ~= 0 and not IsPlayerAceAllowed(source, "spz.dev") and not IsPlayerAceAllowed(source, "spz.admin") then
            print("^1[spz-core] Access Denied.^0")
            return
        end
        
        DebugActive = not DebugActive
        print(string.format("^3[spz-core] Debug Mode toggled to: %s^0", tostring(DebugActive)))
        
        -- We will notify connected modules and update the shared config
        -- Set an internal global switch for `shared/emitter.lua` compatibility
        _G.DebugMode = DebugActive 
    end
end, true)
