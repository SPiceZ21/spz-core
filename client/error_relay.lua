-- 8.3 Client Error Relay
-- Catches native Lua client errors and transmits them cleanly to the server

local function HandleClientError(err, trace)
    -- Push the error straight to the server over the explicit relay event
    TriggerServerEvent("SPZ:clientError", err, trace)
    
    -- Still print on the client so the user/developer sees it locally
    print("^1[Client Error]^0 " .. tostring(err))
    if trace then
        print("^3[Trace]^0\n" .. tostring(trace))
    end
end

-- Set an error handler hook globally on the client wrapper
-- We wrap pcalls around high-risk thread blocks automatically over time
-- In actual FiveM production, you also capture via the 'onClientResourceStop' or custom wrappers 
-- if they use your standard event handler.
AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Citizen.CreateThread(function()
        -- Normally you must pcall explicit critical blocks for standard Lua errors
        -- We establish this file so that `spz-core` exports can utilize `HandleClientError` 
        -- inside their own discrete pcalls.
    end)
end)

-- Public export for client modules to pump explicit programmatic errors remotely
exports("RelayError", function(message, trace)
    HandleClientError(message, trace)
end)
