local ActiveConfig = {}
local StructuralKeys = {}   -- keys a hot-reload must not change (none today)

local DefaultConfig = {
    debug = false,
}

-- 2.2 Schema Validator
local function ValidateConfig(cfg)
    if type(cfg.debug) ~= "boolean" then cfg.debug = DefaultConfig.debug end
    return cfg
end

-- 2.1 Config Validation & Merge
local function LoadAndMergeConfig(isReload)
    -- In FiveM Lua 5.4, we list 'config.lua' in fxmanifest shared_scripts.
    -- This makes the global 'Config' table available automatically.
    
    if not Config then
        print("^1[spz-core] ERROR: 'Config' global is nil. Ensure 'config.lua' is loaded in fxmanifest.^0")
        ActiveConfig = ValidateConfig(DefaultConfig)
        return
    end

    local freshConfig = ValidateConfig(Config)
    
    if isReload then
        -- Only update non-structural keys during hot-reload
        for k, v in pairs(freshConfig) do
            if not StructuralKeys[k] then
                ActiveConfig[k] = v
            end
        end
    else
        ActiveConfig = freshConfig
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
    -- Nothing in spz-core's config is needed client-side today; the event is
    -- kept so GetConfig() on the client keeps working if a key is added.
    local safeSubset = {}

    if target == -1 then
        TriggerClientEvent("SPZ:clientConfig", -1, safeSubset)
    else
        TriggerClientEvent("SPZ:clientConfig", target, safeSubset)
    end
end

exports("ReloadConfig", function()
    LoadAndMergeConfig(true)
    SyncConfigToClient(-1)
end)

-- Send subset to new connecting clients
AddEventHandler("SPZ:playerConnected", function(source)
    SyncConfigToClient(source)
end)

-- 2.3 Hot-Reload — dispatched from the single "/spz" command in
-- server/debug.lua (which loads after this file). Registering a second
-- RegisterCommand("spz", ...) here would silently overwrite that one
-- instead of adding to it, so this is exported and called from there.
