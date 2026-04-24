-- spz-core/server/player_context.lua
-- Authoritative per-player context: current mode + bucket.
-- Every module should call GetPlayerContext() before applying mode-specific logic
-- (e.g. activating NOS, applying physics overrides, showing race UI).

local Contexts = {}

local VALID_MODES = {
    FREEROAM  = true,
    RACE      = true,
    PVP       = true,
    DM        = true,
    SPECTATE  = true,
    IDLE      = true,
}

local function GetContext(source)
    return Contexts[tonumber(source)]
end

local function SetMode(source, mode)
    source = tonumber(source)
    if not VALID_MODES[mode] then
        print(string.format("^3[spz-core:context] Unknown mode '%s' for %d — ignoring^7", tostring(mode), source))
        return false
    end

    if not Contexts[source] then
        Contexts[source] = { mode = "IDLE", bucket = 0 }
    end

    local old = Contexts[source].mode
    Contexts[source].mode = mode

    -- Sync mode to state bag so client scripts can read it
    Player(source).state:set("spz:mode", mode, true)

    TriggerEvent("SPZ:playerModeChanged", source, old, mode)
    return true
end

local function SetBucket(source, bucket)
    source = tonumber(source)
    if not Contexts[source] then
        Contexts[source] = { mode = "IDLE", bucket = 0 }
    end
    Contexts[source].bucket = bucket
end

local function IsInMode(source, mode)
    local ctx = GetContext(source)
    return ctx and ctx.mode == mode
end

-- Create context on player connect
AddEventHandler(SPZ.Events.PLAYER_CONNECTED, function(source)
    Contexts[tonumber(source)] = { mode = "IDLE", bucket = 0 }
    Player(source).state:set("spz:mode", "IDLE", true)
end)

-- Remove context on cleanup
AddEventHandler("SPZ:playerCleanup", function(source)
    Contexts[tonumber(source)] = nil
end)

exports("GetPlayerContext", GetContext)
exports("SetPlayerMode",    SetMode)
exports("SetContextBucket", SetBucket)
exports("IsPlayerInMode",   IsInMode)
