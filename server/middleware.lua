SPZ = SPZ or {}

local BeforeHooks = {}
local AfterHooks = {}

-- 3.3 Event Middleware
function SPZ.OnBefore(event, fn)
    if not BeforeHooks[event] then BeforeHooks[event] = {} end
    table.insert(BeforeHooks[event], fn)
end

function SPZ.OnAfter(event, fn)
    if not AfterHooks[event] then AfterHooks[event] = {} end
    table.insert(AfterHooks[event], fn)
end

-- Main function to handle hooking around events framework-wide
function SPZ.RegisterEvent(event, handler)
    AddEventHandler(event, function(...)
        local args = {...}
        
        -- Run OnBefore hooks
        if BeforeHooks[event] then
            for _, hook in ipairs(BeforeHooks[event]) do
                local pass = hook(table.unpack(args))
                -- If any hook explicitly returns false, halt execution
                if pass == false then return end 
            end
        end

        handler(table.unpack(args))

        -- Run OnAfter hooks
        if AfterHooks[event] then
            for _, hook in ipairs(AfterHooks[event]) do
                hook(table.unpack(args))
            end
        end
    end)
end
