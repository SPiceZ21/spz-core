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
exports("CreateBucket", function(label)
    local id = NextBucketId
    NextBucketId = NextBucketId + 1

    -- Apply strict entity lockdown so freeroam entities don't bleed into the race
    SetRoutingBucketEntityLockdownMode(id, "strict")
    
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
    
    -- Prevent deletion if players are still active inside
    if #bucket.players > 0 then
        error(string.format("^1[spz-core] Cannot delete bucket %d (%s) - players are still inside!^0", bucketId, bucket.label))
        return false
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
    
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return false end
    
    local oldBucket = session.bucket
    if oldBucket == bucketId then return true end -- Already in this bucket
    
    -- Remove from old bucket's player list
    if BucketRegistry[oldBucket] then
        arrayRemove(BucketRegistry[oldBucket].players, source)
    end
    
    -- Moving FiveM routing bucket (Ped and Player)
    SetPlayerRoutingBucket(source, bucketId)
    local ped = GetPlayerPed(source)
    if ped > 0 then
        SetEntityRoutingBucket(ped, bucketId)
    end
    
    -- Register to new bucket
    table.insert(BucketRegistry[bucketId].players, source)
    session.bucket = bucketId
    
    TriggerEvent(SPZ.Events.BUCKET_CHANGED, source, oldBucket, bucketId)
    return true
end)

-- 6.4 RemovePlayerFromBucket
local function RemovePlayerFromBucket(source)
    source = tonumber(source)
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return false end
    
    local oldBucket = session.bucket
    if oldBucket == 0 then return true end -- Already in freeroam bucket
    
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
    local session = exports["spz-core"]:GetPlayerSession(source)
    if not session then return 0 end
    return session.bucket
end)

-- Catch disconnects and auto-remove from buckets
AddEventHandler("SPZ:playerDisconnected", function(source)
    RemovePlayerFromBucket(source)
    
    -- As a fallback if for any reason they weren't fully cleared out of bucket 0
    arrayRemove(BucketRegistry[0].players, tonumber(source))
end)
