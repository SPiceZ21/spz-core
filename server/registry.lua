local Log = SPZ.Logger("Registry")

local RegisteredModules = {
    ["spz-core"] = {
        version = exports["spz-core"]:GetVersion(),
        status = "ready",
        registeredAt = os.time()
    }
}

--- Registers a new module into the core registry
--- @param name string The resource name of the module
--- @param version string The version string of the module
local function RegisterModule(name, version)
    RegisteredModules[name] = {
        version = version or "unknown",
        status = "ready",
        registeredAt = os.time()
    }
    Log.info(("Module registered: %s (v%s)"):format(name, RegisteredModules[name].version))
end

--- Returns the current registry of all loaded modules
--- @return table
local function GetRegisteredModules()
    return RegisteredModules
end

--- Blocks execution until a required module has been registered
--- @param name string The resource name to wait for
--- @return boolean success
local function RequireModule(name)
    local maxRetries = 100 -- 10 seconds total (100 * 100ms)
    local attempts = 0
    
    while not RegisteredModules[name] and attempts < maxRetries do
        Wait(100)
        attempts = attempts + 1
    end

    if not RegisteredModules[name] then
        Log.error(("Dependency timeout: Failed to resolve required module '%s'"):format(name))
        return false
    end

    return true
end

-- Export APIs
exports("RegisterModule", RegisterModule)
exports("GetRegisteredModules", GetRegisteredModules)
exports("RequireModule", RequireModule)

-- Setup /spz status developer command (using the permission wrapper if available)
CreateThread(function()
    Wait(100) -- Wait for permissions to finish loading
    if type(RegisterSPZCommand) == "function" then
        RegisterSPZCommand("status", "spz.dev", function(source, args)
            local targetConsole = source == 0 and "Console" or GetPlayerName(source)
            Log.info(("--- SPiceZ Framework Status requested by %s ---"):format(targetConsole))
            
            for modName, data in pairs(RegisteredModules) do
                local statusIcon = data.status == "ready" and "^2✓^7" or "^1✗^7"
                Log.info(("%s %s \t v%s \t %s"):format(statusIcon, modName, data.version, data.status))
            end
        end)
    end
end)
