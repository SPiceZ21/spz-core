local LocalConfig = {}

-- 2.4 Client Config Sync
-- Listens for Safe Subset pushed from server
RegisterNetEvent("SPZ:clientConfig", function(configSubset)
    -- Store locally
    for k, v in pairs(configSubset) do
        LocalConfig[k] = v
    end
end)

-- Read-only export for other client modules
exports("GetConfig", function(key)
    if key then return LocalConfig[key] end
    return LocalConfig
end)
