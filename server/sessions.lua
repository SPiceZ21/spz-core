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
--
-- The deferral is the one place where a player can be held before they exist in
-- the session, so it is the only correct place to load their profile: fail here
-- and they get a real reason on the connection screen instead of joining and
-- discovering there is no profile behind them.
--
-- This used to call deferrals.done() immediately with a comment saying the DB
-- lookup was still to be written, while spz-identity did the lookup afterwards
-- against a `deferrals` argument it was never actually passed. So nothing gated
-- the connection, and a slow database meant the player joined before their
-- profile existed — the "No profile found" path that left them in the menu
-- request loop forever.
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

    -- spz-identity owns player data; spz-core does not depend on it existing.
    -- If it is not running, let the player in — a server without identity is a
    -- degraded server, not a closed one.
    if GetResourceState('spz-identity') ~= 'started' then
        deferrals.done()
        return
    end

    deferrals.update("Loading your driver profile...")

    local ok, result = pcall(function()
        return exports['spz-identity']:PrepareProfile(identifier)
    end)

    if not ok then
        print(("^1[spz-core] Profile preparation errored for %s: %s^7"):format(tostring(name), tostring(result)))
        deferrals.done("Could not load your driver profile. Please try again.")
        return
    end

    if not result or not result.ok then
        deferrals.done((result and result.reason) or "Could not load your driver profile. Please try again.")
        return
    end

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
