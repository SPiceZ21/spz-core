local ActiveSessions = {}

-- Retrieve License helper
local function GetLicense(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.sub(id, 1, string.len("license:")) == "license:" then
            return id
        end
    end
    return nil
end

-- 4.4 Session Cache Export
exports("GetPlayerSession", function(source)
    return ActiveSessions[tonumber(source)]
end)

-- Direct, in-process accessor for the other spz-core server files.
--
-- Exports are serialised across the resource boundary — even for a resource
-- calling itself — so the export above hands back a COPY. Writing to it (as the
-- bucket registry does with session.bucket) silently changed nothing, which is
-- why bucket state never persisted and the reconciler resynced the same player
-- forever. Same Lua environment here, so this is the real table.
SPZ = SPZ or {}
function SPZ.GetSessionRef(source)
    return ActiveSessions[tonumber(source)]
end

local function CreateSession(source, name, identifier)
    -- 4.1 Session Object
    ActiveSessions[source] = {
        source     = source,
        identifier = identifier,
        name       = name,
        bucket     = 0,
        vehicle    = 0,
        joinedAt   = os.time(),
        lastSeen   = os.time()
    }
    
    -- Register to bucket 0.
    --
    -- The session is created with bucket = 0, so this used to hit the "already
    -- in this bucket" early-out and do nothing at all: the player was never
    -- explicitly routed and never entered BucketRegistry[0].players. A source id
    -- reused from someone who had been in a race bucket then kept that bucket,
    -- which is how players ended up spawning into an empty race world.
    SetPlayerRoutingBucket(source, 0)
    if exports["spz-core"].AssignPlayerToBucket then
        exports["spz-core"]:AssignPlayerToBucket(source, 0)
    end
    
    print("^2[spz-core] DEBUG: Firing SPZ:playerConnected for source " .. tostring(source) .. "^7")
    TriggerEvent(SPZ.Events.PLAYER_CONNECTED, source)
    return ActiveSessions[source]
end

exports("CreateSession", CreateSession)

exports("GetAllSessions", function()
    return ActiveSessions
end)

-- 4.2 Connect Handler
-- Uses FiveM deferrals to hold the connection until the DB resolves
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()

    Wait(0)
    deferrals.update("Checking SPiceZ-Core player data...")

    local identifier = GetLicense(source)
    if not identifier then
        deferrals.done("You must have a valid Rockstar License to join.")
        return
    end

    -- Pseudo-DB lookup: Insert or retrieve player records... 
    -- For now, continue assuming DB resolve succeeds:

    deferrals.done()
end)

AddEventHandler("playerJoining", function()
    local source = source
    local name = GetPlayerName(source)
    local identifier = GetLicense(source)
    if identifier then
        print("^2[spz-core] Player " .. tostring(name) .. " joining with real Server ID: " .. tostring(source) .. "^7")
        CreateSession(source, name, identifier)
    end
end)

-- 4.3 Disconnect Handler
AddEventHandler("playerDropped", function(reason)
    local source = source
    local session = ActiveSessions[source]
    
    if session then
        -- Routing bucket release and cleanups are hooked into SPZ:playerDisconnected 
        -- by other modules (e.g. buckets manager, state machine)
        TriggerEvent(SPZ.Events.PLAYER_DISCONNECTED, source, reason)
        
        ActiveSessions[source] = nil
    end
end)
