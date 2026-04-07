local ActiveConfig = {}
local StructuralKeys = { max_players_per_race = true }

local DefaultConfig = {
    debug = false,
    intermission_time = 30,
    max_players_per_race = 12,
    poll_duration = 60,
    allowed_classes = { "Compacts", "Coupes", "Muscle", "Sports Classics", "Sports", "Super" },
    hud = { locale = "en", display_units = "mph" }
}

-- 2.2 Schema Validator
local function ValidateConfig(cfg)
    -- Check types & ranges, fallback to defaults and log ERROR if missing/wrong
    if type(cfg.intermission_time) ~= "number" or cfg.intermission_time < 0 then
        print("^1[spz-core] ERROR: Validation failed for 'intermission_time'. Falling back to default.^0")
        cfg.intermission_time = DefaultConfig.intermission_time
    end
    
    if type(cfg.max_players_per_race) ~= "number" or cfg.max_players_per_race < 1 then
        print("^1[spz-core] ERROR: Validation failed for 'max_players_per_race'. Falling back to default.^0")
        cfg.max_players_per_race = DefaultConfig.max_players_per_race
    end

    if type(cfg.poll_duration) ~= "number" or cfg.poll_duration < 10 then
        print("^1[spz-core] ERROR: Validation failed for 'poll_duration'. Falling back to default.^0")
        cfg.poll_duration = DefaultConfig.poll_duration
    end

    if type(cfg.allowed_classes) ~= "table" then
        print("^1[spz-core] ERROR: Validation failed for 'allowed_classes'. Falling back to default.^0")
        cfg.allowed_classes = DefaultConfig.allowed_classes
    end
    
    if type(cfg.hud) ~= "table" then
        cfg.hud = DefaultConfig.hud
    end

    return cfg
end

-- 2.1 config.lua Loader
local function LoadAndMergeConfig(isReload)
    -- If using shared_script, the global 'Config' will update on restart.
    -- To hot reload without restarting the resource, we use load() / loadfile()
    local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
    if configFile then
        local configFn, err = load(configFile)
        if configFn then
            -- Create a sandboxed environment to just grab the Config table safely
            local env = { Config = {} }
            setfenv(configFn, env)
            pcall(configFn)
            
            local freshConfig = ValidateConfig(env.Config)
            
            if isReload then
                -- Only update non-structural keys
                for k, v in pairs(freshConfig) do
                    if not StructuralKeys[k] then
                        ActiveConfig[k] = v
                    end
                end
            else
                ActiveConfig = freshConfig
            end
        else
            print("^1[spz-core] ERROR parsing config.lua: " .. tostring(err) .. "^0")
        end
    else
        print("^1[spz-core] ERROR missing config.lua. Using default config.^0")
        ActiveConfig = ValidateConfig(DefaultConfig)
    end
end

-- Run on initial load
LoadAndMergeConfig(false)
-- TODO: Connect this to step 1 string in bootstrap (`InitializeSystems` -> config)

-- Public Export
exports("GetConfig", function(key)
    if key then return ActiveConfig[key] end
    return ActiveConfig
end)

-- 2.4 Client Config Sync
local function SyncConfigToClient(target)
    local safeSubset = {
        hud = ActiveConfig.hud,
        poll_duration = ActiveConfig.poll_duration
    }
    
    if target == -1 then
        TriggerClientEvent("SPZ:clientConfig", -1, safeSubset)
    else
        TriggerClientEvent("SPZ:clientConfig", target, safeSubset)
    end
end

-- Send subset to new connecting clients
AddEventHandler("SPZ:playerConnected", function(source)
    SyncConfigToClient(source)
end)

-- 2.3 Hot-Reload
RegisterCommand("spz", function(source, args)
    if args[1] == "reloadconfig" then
        -- Permission check mock (integrate with 7. Permissions fully later)
        if source ~= 0 and not IsPlayerAceAllowed(source, "spz.admin") then
            print("^1[spz-core] Access Denied.^0")
            return
        end
        
        LoadAndMergeConfig(true)
        SyncConfigToClient(-1) -- Resync to all connected clients
        print("^2[spz-core] Config dynamically reloaded (structural keys ignored).^0")
    end
end, true)
