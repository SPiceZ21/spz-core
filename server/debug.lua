-- 3.4 Debug Event Logger
-- SPZ.Emit wrapper outputs are hooked locally if debug toggles on.

SPZ = SPZ or {}

-- Temporary boolean to handle the toggle command
local DebugActive = exports["spz-core"]:GetConfig("debug") or false

-- Single "/spz <subcommand>" dispatcher. RegisterCommand only keeps the
-- LAST registration for a given name — a second RegisterCommand("spz", ...)
-- elsewhere would silently replace this whole handler, not add to it — so
-- every "/spz ..." subcommand lives here, dispatching out to exports from
-- the resource that actually owns that behaviour (config.lua, theme.lua).
local function isAdmin(source)
    return source == 0
        or IsPlayerAceAllowed(source, "spz.dev")
        or IsPlayerAceAllowed(source, "spz.admin")
end

local Subcommands = {}

Subcommands["debug"] = function(source)
    if not isAdmin(source) then print("^1[spz-core] Access Denied.^0"); return end
    DebugActive = not DebugActive
    print(string.format("^3[spz-core] Debug Mode toggled to: %s^0", tostring(DebugActive)))
    -- Set an internal global switch for `shared/emitter.lua` compatibility
    _G.DebugMode = DebugActive
end

Subcommands["reloadconfig"] = function(source)
    if not isAdmin(source) then print("^1[spz-core] Access Denied.^0"); return end
    exports["spz-core"]:ReloadConfig()
    print("^2[spz-core] Config dynamically reloaded (structural keys ignored).^0")
end

Subcommands["reloadtheme"] = function(source)
    if not isAdmin(source) then print("^1[spz-core] Access Denied.^0"); return end
    exports["spz-core"]:ReloadTheme()
    print("^2[spz-core] Theme reloaded from spz_theme_* convars and pushed to all clients.^0")
end

RegisterCommand("spz", function(source, args)
    local sub = args[1]
    local handler = sub and Subcommands[sub]
    if handler then
        handler(source)
    else
        local names = {}
        for name in pairs(Subcommands) do names[#names + 1] = name end
        table.sort(names)
        print("^3[spz-core] Usage: /spz <" .. table.concat(names, "|") .. ">^0")
    end
end, true)

-- 8.3 Client Error Relay (Server Receiver)
AddEventHandler("SPZ:clientError", function(message, trace)
    local source = source
    local session = exports["spz-core"]:GetPlayerSession(source)
    local identity = session and session.name or "Unknown ("..source..")"
    
    print(string.format("^1[CLIENT ERROR] Player: %s | Source: %s^0", identity, source))
    print(string.format("^1[Message]^0 %s", tostring(message)))
    if trace then
        print(string.format("^3[Trace]^0\n%s", tostring(trace)))
    end
end)

