SPZ = SPZ or {}

local IS_SERVER = IsDuplicityVersion()
local DebugMode = false -- Handled/overridden by server/debug.lua or config later

-- 3.2 Typed Emitter Wrappers
function SPZ.Emit(event, targetOrPayload, ...)
    local args = {...}
    
    if DebugMode then
        print(string.format("[%s] [DEBUG] SPZ.Emit: %s | Payload: %s", os.date("%X"), event, json.encode({targetOrPayload, table.unpack(args)})))
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
        print(string.format("[%s] [DEBUG] SPZ.EmitAll: %s | Payload: %s", os.date("%X"), event, json.encode(args)))
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
        print(string.format("[%s] [DEBUG] SPZ.EmitLocal: %s | Payload: %s", os.date("%X"), event, json.encode({...})))
    end
    TriggerEvent(event, ...)
end
