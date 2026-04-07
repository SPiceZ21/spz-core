local PlayerCache = {}
local DirtyCache = {}

-- 4.5 Per-Player KV Cache Exports
exports("GetCache", function(source, key)
    source = tonumber(source)
    if not PlayerCache[source] then return nil end
    return PlayerCache[source][key]
end)

exports("SetCache", function(source, key, value)
    source = tonumber(source)
    if not PlayerCache[source] then PlayerCache[source] = {} end
    if not DirtyCache[source] then DirtyCache[source] = {} end
    
    PlayerCache[source][key] = value
    DirtyCache[source][key]  = true
end)

local function FlushCacheToDB(source)
    if not DirtyCache[source] then return end
    
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return end

    -- Pseudo-DB batch write representation
    for key, _ in pairs(DirtyCache[source]) do
        local value = PlayerCache[source][key]
        -- Example sync operation saving cache JSON to database:
        -- exports.oxmysql:insert('INSERT INTO spz_cache (identifier, key, value) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = ?', {session.identifier, key, json.encode(value), json.encode(value)})
    end
    
    DirtyCache[source] = nil
end

-- Batched write every 60 seconds
Citizen.CreateThread(function()
    while true do
        Wait(60000)
        for source, _ in pairs(DirtyCache) do
            FlushCacheToDB(source)
        end
    end
end)

-- Immediate write on disconnect
AddEventHandler("playerDropped", function(reason)
    local source = source
    if PlayerCache[source] then
        FlushCacheToDB(source)
        PlayerCache[source] = nil
        DirtyCache[source] = nil
    end
end)
