SPZ = SPZ or {}

-- 7.1 IsAdmin
exports("IsAdmin", function(source)
    source = tonumber(source)
    
    -- Console is always admin
    if source == 0 then return true end
    
    if IsPlayerAceAllowed(source, "spz.admin") then
        return true
    end
    return false
end)

-- 7.2 HasPermission
exports("HasPermission", function(source, ace)
    source = tonumber(source)
    
    -- Console automatically passes all permissions
    if source == 0 then return true end
    
    -- Full admins intrinsically have all permissions within the hierarchy
    if IsPlayerAceAllowed(source, "spz.admin") then
        return true
    end
    
    -- Check specific granular permission
    if IsPlayerAceAllowed(source, ace) then
        return true
    end
    
    return false
end)

-- 7.3 Command Guard Wrapper
-- Wrapper replacing standard `RegisterCommand` to automatically authorize execution.
function SPZ.RegisterCommand(name, aceRequired, handler)
    RegisterCommand(name, function(source, args, rawCommand)
        -- Validate permission
        if not exports["spz-core"]:HasPermission(source, aceRequired) then
            -- Fallback print/notify. In practice this could tie into the event system 
            -- or notify the client with a specific UI event.
            if source == 0 then
                print(string.format("^1[spz-core] Access Denied for command /%s.^0", name))
            else
                TriggerClientEvent("chat:addMessage", source, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"System", "You do not have permission to execute this command."}
                })
            end
            return
        end
        
        -- Execute wrapped handler
        handler(source, args, rawCommand)
    end, false) -- Always set `restricted` false since we're handling ACL internally
end

-- Export the wrapper globally if other resources do not load `shared` functions manually.
exports("RegisterSPZCommand", SPZ.RegisterCommand)
