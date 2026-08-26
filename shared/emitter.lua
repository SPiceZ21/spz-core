SPZ = SPZ or {}

local IS_SERVER = IsDuplicityVersion()
local DebugMode = false -- Handled/overridden by server/debug.lua or config later

-- This file is a shared_script, so it runs client-side too — and FiveM's
-- client Lua sandbox has no `os` library at all. The debug prints below used
-- os.date() unguarded, which meant turning debug mode on crashed every
-- SPZ.Emit call on the client ("attempt to index a nil value (global 'os')").
-- Feature-detect rather than branch on IS_SERVER so this stays correct if the
-- sandbox ever changes. Same HH:MM:SS shape on both sides.
local function timestamp()
    if os then return os.date("%X") end
    local _, _, _, hour, minute, second = GetLocalTime()
    return string.format("%02d:%02d:%02d", hour, minute, second)
end

-- 3.2 Typed Emitter Wrappers
function SPZ.Emit(event, targetOrPayload, ...)
    local args = {...}
    
    if DebugMode then
        print(string.format("[%s] [DEBUG] SPZ.Emit: %s | Payload: %s", timestamp(), event, json.encode({targetOrPayload, table.unpack(args)})))
    end

    if IS_SERVER then
        local target = targetOrPayload
        if not target then
            print(string.format("^3[spz-core] WARN: SPZ.Emit called for '%s' without a target.^0", event))
            return
        end
        TriggerClientEvent(event, target, table.unpack(args))
    else
        -- Client ignores target conceptually, emits directly to server payload
        TriggerServerEvent(event, targetOrPayload, table.unpack(args))
    end
end

function SPZ.EmitAll(event, ...)
    local args = {...}
    
    if DebugMode then
        print(string.format("[%s] [DEBUG] SPZ.EmitAll: %s | Payload: %s", timestamp(), event, json.encode(args)))
    end

    if IS_SERVER then
        TriggerClientEvent(event, -1, table.unpack(args))
    else
        print("^1[spz-core] ERROR: SPZ.EmitAll cannot be called from the client.^0")
    end
end

-- Server-to-server / Client-to-client internal routing
function SPZ.EmitLocal(event, ...)
    if DebugMode then
        print(string.format("[%s] [DEBUG] SPZ.EmitLocal: %s | Payload: %s", timestamp(), event, json.encode({...})))
    end
    TriggerEvent(event, ...)
end
