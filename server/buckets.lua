SPZ = SPZ or {}

local BucketRegistry = {
    [0] = {
        id        = 0,
        label     = "freeroam",
        players   = {},
        createdAt = os.time()
    }
}
local NextBucketId = 1

-- Utility to remove value from array
local function arrayRemove(t, val)
    for i, v in ipairs(t) do
        if v == val then
            table.remove(t, i)
            return true
        end
    end
    return false
end

-- 6.1 Bucket Registry
exports("GetBucketRegistry", function()
    return BucketRegistry
end)

-- 6.2 CreateBucket
exports("CreateBucket", function(label, populationEnabled)
    local id = NextBucketId
    NextBucketId = NextBucketId + 1

    -- Apply strict entity lockdown so freeroam entities don't bleed into the race
    SetRoutingBucketEntityLockdownMode(id, "strict")
    
    -- Population control: false by default for race/TT isolation unless explicitly configured
    local npcConfig = Config and Config.NPCs or {}
    local enablePop = populationEnabled
    if enablePop == nil then
        enablePop = (npcConfig.enabled ~= false and npcConfig.race_population == true)
    end
    SetRoutingBucketPopulationEnabled(id, enablePop)
    
    BucketRegistry[id] = {
        id        = id,
        label     = label or string.format("race_%03d", id),
        players   = {},
        createdAt = os.time()
    }
    
    return id
end)

-- 6.5 DeleteBucket
local function DeleteBucket(bucketId)
    bucketId = tonumber(bucketId)
    if bucketId == 0 then return false end
    
    local bucket = BucketRegistry[bucketId]
    if not bucket then return false end
    
    -- Gracefully handle remaining players rather than throwing a hard error and crashing calling scripts
    if #bucket.players > 0 then
        print(string.format("^3[spz-core] Warning: Players still inside bucket %d (%s) during deletion. Moving them to freeroam.^0", bucketId, bucket.label))
        local tempPlayers = {}
        for _, playerSrc in ipairs(bucket.players) do
            table.insert(tempPlayers, playerSrc)
        end
        for _, playerSrc in ipairs(tempPlayers) do
            local session = SPZ.GetSessionRef(playerSrc)
            if session then
                exports["spz-core"]:AssignPlayerToBucket(playerSrc, 0)
            else
                arrayRemove(bucket.players, playerSrc)
            end
        end
    end
    
    local activeTime = os.time() - bucket.createdAt
    print(string.format("^3[spz-core] Deleted bucket %d (%s). Active for %d seconds.^0", bucketId, bucket.label, activeTime))
    
    BucketRegistry[bucketId] = nil
    return true
end
exports("DeleteBucket", DeleteBucket)

-- 6.3 AssignPlayerToBucket
exports("AssignPlayerToBucket", function(source, bucketId)
    source = tonumber(source)
    bucketId = tonumber(bucketId)
    
    if not BucketRegistry[bucketId] then
        print(string.format("^1[spz-core] ERROR: Attempted to assign player %d to non-existent bucket %d^0", source, bucketId))
        return false
    end
    
    local session = SPZ.GetSessionRef(source)
    if not session then return false end

    local oldBucket = session.bucket

    -- The ENGINE is the source of truth, not session.bucket. Anything that calls
    -- SetPlayerRoutingBucket directly (spz-spectate does, deliberately) leaves
    -- the two out of sync; trusting the cached value then made this a no-op and
    -- the player stayed stranded in someone else's bucket.
    local realBucket = GetPlayerRoutingBucket(source)
    local inSync     = (oldBucket == bucketId) and (realBucket == bucketId)

    -- Registry membership is repaired even when the buckets already match, so a
    -- player can never be routed correctly yet missing from players[] (which is
    -- what left buckets looking "occupied" and blocked their cleanup).
    local listed = false
    for _, v in ipairs(BucketRegistry[bucketId].players) do
        if v == source then listed = true break end
    end

    if inSync and listed then return true end

    -- Remove from every other bucket's list, not just the cached one — drift
    -- means the stale entry is not always where session.bucket says it is.
    for id, b in pairs(BucketRegistry) do
        if id ~= bucketId then arrayRemove(b.players, source) end
    end

    -- Moving FiveM routing bucket (Ped and Player)
    SetPlayerRoutingBucket(source, bucketId)
    local ped = GetPlayerPed(source)
    if ped > 0 then
        SetEntityRoutingBucket(ped, bucketId)
    end

    if not listed then
        table.insert(BucketRegistry[bucketId].players, source)
    end
    session.bucket = bucketId

    if oldBucket ~= bucketId then
        TriggerEvent(SPZ.Events.BUCKET_CHANGED, source, oldBucket, bucketId)
    end
    return true
end)

-- 6.4 RemovePlayerFromBucket
local function RemovePlayerFromBucket(source)
    source = tonumber(source)
    local session = SPZ.GetSessionRef(source)
    if not session then
        -- Sweep registry as fallback to prevent disconnected players from lingering
        for id, b in pairs(BucketRegistry) do
            arrayRemove(b.players, source)
        end
        return true
    end
    
    local oldBucket = session.bucket

    -- Same trap as AssignPlayerToBucket: session.bucket can claim freeroam while
    -- the engine still has them elsewhere, so check the real bucket too before
    -- deciding there is nothing to do.
    if oldBucket == 0 and GetPlayerRoutingBucket(source) == 0 then return true end

    -- Assign to Bucket 0 (freeroam)
    exports["spz-core"]:AssignPlayerToBucket(source, 0)
    
    -- Auto-cleanup check: If the bucket is now empty, delete it
    local bucket = BucketRegistry[oldBucket]
    if bucket and #bucket.players == 0 then
        DeleteBucket(oldBucket)
    end
    
    return true
end
exports("RemovePlayerFromBucket", RemovePlayerFromBucket)

-- 6.6 GetBucketPlayers
exports("GetBucketPlayers", function(bucketId)
    bucketId = tonumber(bucketId)
    if not BucketRegistry[bucketId] then return {} end
    return BucketRegistry[bucketId].players
end)

-- Used by exports per the documentation
exports("GetPlayerBucket", function(source)
    local session = SPZ.GetSessionRef(source)
    if not session then return 0 end
    return session.bucket
end)

-- Catch disconnects and auto-remove from buckets
AddEventHandler("SPZ:playerDisconnected", function(source)
    RemovePlayerFromBucket(source)
    
    -- As a fallback if for any reason they weren't fully cleared out of bucket 0
    arrayRemove(BucketRegistry[0].players, tonumber(source))
end)

-- ── Reconciliation ───────────────────────────────────────────────────────────
-- Buckets are written from several resources (races, TT, minigames, spectate),
-- and any raw SetPlayerRoutingBucket call drifts from this registry. Rather than
-- trusting every caller, sweep periodically: the ENGINE is authoritative for
-- where a player is, and the registry is repaired to match.
--
-- This is what stops a player being "spawned in a different bucket" — a stale
-- entry can no longer survive longer than one sweep.
CreateThread(function()
    while true do
        Wait(15000)

        for _, sid in ipairs(GetPlayers()) do
            local src     = tonumber(sid)
            local session = SPZ.GetSessionRef(src)

            if session then
                local real = GetPlayerRoutingBucket(src)

                -- Routed into a bucket this registry does not know about (its
                -- owner deleted it, or it was set raw): send them home.
                if not BucketRegistry[real] then
                    print(("^3[spz-core] Player %d in unknown bucket %d — returning to freeroam.^0")
                        :format(src, real))
                    exports["spz-core"]:AssignPlayerToBucket(src, 0)
                elseif session.bucket ~= real then
                    print(("^3[spz-core] Bucket drift for player %d: session=%s engine=%d — resyncing.^0")
                        :format(src, tostring(session.bucket), real))
                    session.bucket = real
                    for id, b in pairs(BucketRegistry) do
                        if id ~= real then arrayRemove(b.players, src) end
                    end
                    local listed = false
                    for _, v in ipairs(BucketRegistry[real].players) do
                        if v == src then listed = true break end
                    end
                    if not listed then table.insert(BucketRegistry[real].players, src) end
                end
            end
        end

        -- Drop players from bucket lists who are no longer connected, so empty
        -- race buckets stop reporting occupants and can actually be deleted.
        for _, b in pairs(BucketRegistry) do
            for i = #b.players, 1, -1 do
                if GetPlayerName(b.players[i]) == nil then table.remove(b.players, i) end
            end
        end
    end
end)

-- Where is everyone, according to both the registry and the engine?
RegisterCommand("spzbuckets", function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, "spz.admin") then return end
    print("^2[spz-core] Bucket registry:^0")
    for id, b in pairs(BucketRegistry) do
        print(("  [%d] %-16s players=%d"):format(id, b.label, #b.players))
        for _, p in ipairs(b.players) do
            local engine = GetPlayerName(p) and GetPlayerRoutingBucket(p) or -1
            print(("      %-4s %-20s engine=%s%s"):format(p, GetPlayerName(p) or "(gone)",
                engine, engine ~= id and "  <-- DRIFT" or ""))
        end
    end
end, false)
