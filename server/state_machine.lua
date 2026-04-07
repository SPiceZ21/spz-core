SPZ = SPZ or {}

local StateHistory = {}
local MAX_HISTORY = 5

-- 5.2 Transition Validator
local ValidTransitions = {
    [SPZ.State.IDLE]       = { [SPZ.State.FREEROAM] = true, [SPZ.State.QUEUED]     = true },
    [SPZ.State.FREEROAM]   = { [SPZ.State.IDLE]     = true, [SPZ.State.QUEUED]     = true },
    [SPZ.State.QUEUED]     = { [SPZ.State.RACING]   = true, [SPZ.State.IDLE]       = true },
    [SPZ.State.RACING]     = { [SPZ.State.IDLE]     = true },
    [SPZ.State.SPECTATING] = { [SPZ.State.IDLE]     = true }
}

local function CanTransition(source, toState)
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return false end
    
    local currentState = session.state
    if ValidTransitions[currentState] and ValidTransitions[currentState][toState] then
        return true
    end
    
    print(string.format("^3[spz-core] WARN: Rejected illegal state transition for %s ( %s -> %s ).^0", source, currentState, toState))
    return false
end

-- 5.3 SetPlayerState Export
exports("SetPlayerState", function(source, newState)
    source = tonumber(source)
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return false end
    
    local oldState = session.state
    
    -- Skip if trying to set to the current state
    if oldState == newState then return true end
    
    if not CanTransition(source, newState) then return false end
    
    -- Record history before updating
    if not StateHistory[source] then StateHistory[source] = {} end
    table.insert(StateHistory[source], 1, { state = newState, timestamp = os.time() })
    if #StateHistory[source] > MAX_HISTORY then
        table.remove(StateHistory[source])
    end
    
    -- Update session object
    session.state = newState
    
    -- Fire 5.5 State Change Event
    TriggerEvent(SPZ.Events.STATE_CHANGED, source, oldState, newState)
    -- Also sync to the client natively using our wrapper (conceptually identical to Emit here)
    if SPZ.Emit then
        SPZ.Emit(SPZ.Events.STATE_CHANGED, source, oldState, newState)
    else
        TriggerClientEvent(SPZ.Events.STATE_CHANGED, source, oldState, newState)
    end
    
    return true
end)

-- 5.4 GetPlayerState Export
exports("GetPlayerState", function(source)
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return nil end
    return session.state
end)

-- 5.6 State History
exports("GetStateHistory", function(source)
    return StateHistory[tonumber(source)] or {}
end)

-- Cleanup history heavily on dropped
AddEventHandler("SPZ:playerDisconnected", function(source)
    StateHistory[tonumber(source)] = nil
end)
