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

local function CreateSession(source, name, identifier)
    -- 4.1 Session Object
    ActiveSessions[source] = {
        source     = source,
        identifier = identifier,
        name       = name,
        state      = SPZ.State.IDLE, 
        bucket     = 0,
        vehicle    = 0,
        joinedAt   = os.time(),
        lastSeen   = os.time()
    }
    
    -- Register to bucket 0
    if exports["spz-core"].AssignPlayerToBucket then
        exports["spz-core"]:AssignPlayerToBucket(source, 0)
    end
    
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
    -- local dbPlayer = exports.oxmysql:singleSync("SELECT * FROM spz_players WHERE identifier = ?", {identifier})
    -- For now, continue assuming DB resolve succeeds:
    
    CreateSession(source, name, identifier)

    deferrals.done()
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
