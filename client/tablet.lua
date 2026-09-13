-- client/tablet.lua
-- The "reading a tablet" pose players hold while a dashboard is open —
-- leaderboard, crew — so a player staring at a menu reads as one to everyone
-- around them instead of standing frozen.
--
-- One shared implementation, owned here, used by any resource:
--
--   exports['spz-core']:StartTablet()   -- when your menu opens
--   exports['spz-core']:StopTablet()    -- when it closes
--
-- Claims are counted per calling resource, so two menus that overlap (the crew
-- dashboard opened from the leaderboard) never tear the tablet out of the other
-- one's hands. A resource that stops while holding a claim has it released for
-- it — a menu that crashes must not leave the player holding a tablet forever.

local ANIM_DICT = 'amb@world_human_tourist_map@male@base'
local ANIM_CLIP = 'base'
local PROP      = `prop_cs_tablet`
local BONE      = 28422   -- SKEL_R_Hand PH_R_Hand

-- Offset and rotation that seat the tablet in both hands for this clip
-- (same placement dpemotes ships for its "tablet" emote).
local POS = vector3(0.0, -0.03, 0.0)
local ROT = vector3(20.0, -90.0, 0.0)

-- 1 loop + 16 upper body + 32 secondary: the arms hold the tablet while the
-- legs stay free, so nothing snaps if the player is nudged or the menu opens
-- mid-step.
local ANIM_FLAGS = 49

local claims = {}     -- [resourceName] = true
local prop   = nil

local function anyClaim() return next(claims) ~= nil end

local function loadDict()
    RequestAnimDict(ANIM_DICT)
    local deadline = GetGameTimer() + 2000
    while not HasAnimDictLoaded(ANIM_DICT) and GetGameTimer() < deadline do Wait(0) end
    return HasAnimDictLoaded(ANIM_DICT)
end

local function loadModel()
    RequestModel(PROP)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(PROP) and GetGameTimer() < deadline do Wait(0) end
    return HasModelLoaded(PROP)
end

-- Only on foot and in control of the character. In a car the clip clips
-- through the wheel; ragdolled, swimming or dead it fights the game.
local function canHold(ped)
    return not IsPedInAnyVehicle(ped, true)
       and not IsPedRagdoll(ped)
       and not IsPedSwimming(ped)
       and not IsPedFalling(ped)
       and not IsEntityDead(ped)
       and not IsPedCuffed(ped)
end

local function removeProp()
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, false)
        DeleteEntity(prop)
    end
    prop = nil
end

local function stopPose()
    local ped = PlayerPedId()
    if IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_CLIP, 3) then
        StopAnimTask(ped, ANIM_DICT, ANIM_CLIP, 2.0)
    end
    removeProp()
end

local function startPose()
    local ped = PlayerPedId()
    if not canHold(ped) then return end
    if not loadDict() or not loadModel() then return end
    -- The claim may have been dropped while the assets streamed in.
    if not anyClaim() then return end

    if not IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_CLIP, 3) then
        TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, 3.0, 3.0, -1, ANIM_FLAGS, 0.0, false, false, false)
    end

    if not (prop and DoesEntityExist(prop)) then
        local c = GetEntityCoords(ped)
        -- Networked, so everyone nearby sees the tablet, not just this player.
        prop = CreateObject(PROP, c.x, c.y, c.z + 0.2, true, true, false)
        SetEntityCollision(prop, false, false)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, BONE),
            POS.x, POS.y, POS.z, ROT.x, ROT.y, ROT.z,
            true, true, false, true, 1, true)
    end
    SetModelAsNoLongerNeeded(PROP)
end

-- While claimed, keep the pose honest: something else (a vehicle entry, a
-- ragdoll, another resource's TaskPlayAnim) can knock it off, and the tablet
-- must not be left floating in the hand of a player who is no longer holding it.
local watching = false
local function watch()
    if watching then return end
    watching = true
    CreateThread(function()
        while anyClaim() do
            local ped = PlayerPedId()
            if not canHold(ped) then
                stopPose()
            elseif not IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_CLIP, 3)
                or not (prop and DoesEntityExist(prop)) then
                startPose()
            end
            Wait(500)
        end
        stopPose()
        watching = false
    end)
end

exports('StartTablet', function()
    local owner = GetInvokingResource() or GetCurrentResourceName()
    claims[owner] = true
    CreateThread(startPose)
    watch()
end)

exports('StopTablet', function()
    local owner = GetInvokingResource() or GetCurrentResourceName()
    claims[owner] = nil
    if not anyClaim() then stopPose() end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        claims = {}
        stopPose()
    elseif claims[resource] then
        claims[resource] = nil
        if not anyClaim() then stopPose() end
    end
end)
