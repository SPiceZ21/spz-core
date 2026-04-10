local function CheckHardDependencies()
    local hardDeps = { "spz-lib", "oxmysql" }
    for _, name in ipairs(hardDeps) do
        if GetResourceState(name) ~= "started" then
            error(string.format("^1[spz-core] FATAL ERROR: Hard dependency '%s' is missing or not running. Startup halted.^0", name))
        end
    end

    -- Explicit API check as per 1.1 referenced in documentation 
    if exports["spz-lib"] and exports["spz-lib"].isReady then
        if not exports["spz-lib"]:isReady() then
            error("^1[spz-core] FATAL ERROR: spz-lib reports it is not ready. Startup halted.^0")
        end
    end
end

local function CheckDependency(name, minVersion)
    if GetResourceState(name) ~= "started" and GetResourceState(name) ~= "starting" then
        print(string.format("^3[spz-core] WARN: Dependency '%s' is not running.^0", name))
        return false
    end

    local currentVersion = GetResourceMetadata(name, "version", 0)
    if currentVersion and minVersion then
        -- This is a basic string comparison fallback for semver
        if currentVersion < minVersion then
            print(string.format("^3[spz-core] WARN: Dependency '%s' version (%s) is lower than recommended (%s).^0", name, currentVersion, minVersion))
        end
    end

    return true
end

local function InitializeSystems()
    local p = promise.new()
    
    Citizen.CreateThread(function()
        local success, err = pcall(function()
            -- 1. config (Already loaded via server_scripts)
            print("[spz-core] Config loaded.")
            
            -- 2. DB ping
            print("[spz-core] Connecting and pinging database...")
            local dbReady = exports.oxmysql:executeSync("SELECT 1")
            if not dbReady then error("Database ping failed") end
            
            -- 3. session manager - Handle players already on server
            print("[spz-core] Initializing player sessions for online players...")
            local players = GetPlayers()
            for _, src in ipairs(players) do
                local source = tonumber(src)
                -- Get identifiers for existing player
                local identifier
                for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                    local id = GetPlayerIdentifier(source, i)
                    if string.sub(id, 1, string.len("license:")) == "license:" then
                        identifier = id
                        break
                    end
                end
                
                if identifier then
                    exports["spz-core"]:CreateSession(source, GetPlayerName(source), identifier)
                end
            end
            
            -- 4. state machine & others (Initialized via file load)
            print("[spz-core] State machine and routing systems online.")
        end)

        if not success then
            p:reject(err)
        else
            p:resolve(true)
        end
    end)

    return p
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CheckHardDependencies()

    -- 1.2 Verify dependency manifest
    CheckDependency("ox_lib", "3.0.0")
    CheckDependency("oxmysql", "2.7.0")
    CheckDependency("screenshot-basic", "1.0.0")

    -- 1.3 Ordered Startup Sequence
    local startupPromise = InitializeSystems()

    Citizen.Await(startupPromise)

    -- Resolve any errors unhandled in the promise
    if startupPromise.state == "rejected" then
        print(string.format("^1[spz-core] STARTUP FAILED: %s^0", startupPromise.value))
        return
    end

    TriggerEvent("SPZ:coreReady")
    print("^2[spz-core] Startup complete. Emitted SPZ:coreReady.^0")
end)
