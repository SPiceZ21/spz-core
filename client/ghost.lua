-- client/ghost.lua
-- Phasing: players never collide with players. World collision (roads,
-- buildings, props, NPC traffic) is untouched, always.
--
-- ── THE MODEL ────────────────────────────────────────────────────────────────
--
-- Read this before changing anything here, because the obvious mental model is
-- wrong and produces a bug that looks like the script randomly failing.
--
-- Collision between two entities is resolved by exactly ONE machine: the
-- network OWNER of the entities involved. Every other client is shown the
-- result. So a flag I set locally only changes what happens on my screen for
-- pairs I actually simulate — and which pairs those are is NOT fixed. Ownership
-- migrates: it follows proximity and focus, it moves without warning, and a car
-- I have never touched can become mine for a few seconds because its driver
-- looked away.
--
-- That is the whole explanation for the report this file was rewritten for:
--
--     SPZ, STEVE and DRAKEN are racing. On SPZ's screen SPZ passes cleanly
--     through both of them — but STEVE and DRAKEN collide with each other.
--     On STEVE's screen it is SPZ and DRAKEN who collide.
--
-- Nobody's client is broken. Each client was asserting "me against everyone"
-- every frame and "everyone against everyone" only every 400 ms. The instant
-- SPZ's machine took ownership of Steve's or Draken's car — which happens
-- constantly in a pack — SPZ became the machine resolving THAT pair, holding a
-- flag that could be up to 400 ms stale. 400 ms is ~11 metres of closing at
-- racing speed: one real hit, seen only by the client that happened to own it,
-- which is exactly why each driver sees a different crash.
--
-- The fix is not a shorter sleep. It is to stop treating "my entities" and
-- "everyone else's" as the two categories, and use the one that actually
-- decides the outcome:
--
--   TIER 1, every frame — every pair I OWN a side of.
--     Mine by definition (my ped, my car), plus anything ownership has migrated
--     to me. These are the pairs my machine resolves, so a stale flag here is a
--     collision somebody sees. Ownership is re-read every frame because that is
--     how fast it changes.
--
--   TIER 2, throttled — every remaining pair.
--     Pairs another machine is resolving. My flags do not change what I am shown
--     for these, so they cost a sweep rather than a frame. They are still
--     asserted, and asserting them is what makes the handover seamless: when
--     ownership arrives, the flag is already in place instead of being applied
--     a frame later.
--
-- The bound on all of this is worth stating plainly: phasing is only ever as
-- good as the owning client. A client that is not running this file will show
-- ITS owner-side contacts to everyone. Nothing here can fix that from outside.
--
-- ── THE FLAG ─────────────────────────────────────────────────────────────────
--
-- SetEntityNoCollisionEntity(a, b, thisFrameOnly) — the 3rd argument must be
-- FALSE. false = the exclusion persists. true = it lapses almost immediately,
-- which gives the classic "two cars are fine until a third arrives" symptom.
--
-- It is not permanent even so. The exclusion is dropped when an entity is
-- re-created (stream out and back in), when ownership migrates, and whenever
-- anything calls SetEntityCollision on either side — which spz-spawn does after
-- every spawn and spz-appearance after every outfit change. None of those change
-- the entity HANDLE, so no cheap check can detect them; re-assertion on a
-- cadence is the only reliable answer, which is why both tiers re-assert
-- unconditionally rather than trying to be clever about it.

local FULL_SWEEP_MS = 150    -- tier 2 cadence
local LastPed, LastVeh = 0, 0

--- Both directions of every entity pairing between two players. Both directions
--- because the flag is stored per entity, not per pair: setting it on A only
--- leaves B's own resolution untouched.
local function Unlink(aPed, aVeh, bPed, bVeh)
    SetEntityNoCollisionEntity(aPed, bPed, false)
    SetEntityNoCollisionEntity(bPed, aPed, false)
    if aVeh ~= 0 then
        SetEntityNoCollisionEntity(aVeh, bPed, false)
        SetEntityNoCollisionEntity(bPed, aVeh, false)
    end
    if bVeh ~= 0 then
        SetEntityNoCollisionEntity(aPed, bVeh, false)
        SetEntityNoCollisionEntity(bVeh, aPed, false)
    end
    if aVeh ~= 0 and bVeh ~= 0 then
        SetEntityNoCollisionEntity(aVeh, bVeh, false)
        SetEntityNoCollisionEntity(bVeh, aVeh, false)
    end
end

--- Every player as { ped, veh, mine }, where `mine` means THIS machine resolves
--- contact for that player's entities right now.
---
--- Ownership is asked of the vehicle first and the ped second: in a race the car
--- is what touches, and a ped sitting in a car can report a different owner from
--- the car around it while a seat change is still syncing. Either side being
--- mine makes the pair mine, because either is enough to make my simulation the
--- one that decides.
local function Snapshot()
    local myId  = PlayerId()
    local out   = {}

    for _, plr in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(plr)
        if ped ~= 0 and DoesEntityExist(ped) then
            local veh  = GetVehiclePedIsIn(ped, false)
            local mine = plr == myId

            if not mine then
                if veh ~= 0 and NetworkGetEntityOwner(veh) == myId then
                    mine = true
                elseif NetworkGetEntityOwner(ped) == myId then
                    mine = true
                end
            end

            out[#out + 1] = { ped = ped, veh = veh, mine = mine }
        end
    end

    return out
end

-- ── Tier 1: every pair this machine resolves, every frame ────────────────────

CreateThread(function()
    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)

        -- Restore fully opaque rendering. NOTE: never use SetEntityAlpha(e,255)
        -- here — setting an explicit alpha (even 255) flags the entity as
        -- alpha-blended and moves it into GTA's TRANSPARENT render pass, where
        -- it stops writing depth. Result: you see NPC headlight coronas and
        -- other cars straight through the bodywork. ResetEntityAlpha clears the
        -- override and puts the entity back in the opaque pass.
        -- Only fired when the entity changes: calling it every frame is waste.
        if myPed ~= LastPed then
            ResetEntityAlpha(myPed)
            LastPed = myPed
        end
        if myVeh ~= LastVeh then
            if myVeh ~= 0 then ResetEntityAlpha(myVeh) end
            LastVeh = myVeh
        end

        -- Every pair with at least one owned side. That is my own entities
        -- against everybody, AND any remote pair whose ownership has migrated
        -- here — the case the old "me against everyone" pass could not see, and
        -- the one that made three drivers watch three different crashes.
        local ents = Snapshot()
        local n = #ents
        for i = 1, n do
            local a = ents[i]
            for j = i + 1, n do
                local b = ents[j]
                if a.mine or b.mine then
                    Unlink(a.ped, a.veh, b.ped, b.veh)
                end
            end
        end

        Wait(0)
    end
end)

-- ── Tier 2: everything else, throttled ───────────────────────────────────────
--
-- Pairs another machine is currently resolving. Asserted anyway, so the flag is
-- already in place the moment ownership moves here rather than arriving a frame
-- after the contact it was needed for.

CreateThread(function()
    while true do
        local ents = Snapshot()
        local n = #ents
        for i = 1, n do
            local a = ents[i]
            for j = i + 1, n do
                local b = ents[j]
                -- Tier 1 has these covered every frame already.
                if not (a.mine or b.mine) then
                    Unlink(a.ped, a.veh, b.ped, b.veh)
                end
            end
        end

        Wait(FULL_SWEEP_MS)
    end
end)

-- ── Seeing what it is doing ──────────────────────────────────────────────────
-- /phasing prints, for every player in range, who owns their entities and which
-- tier this machine is enforcing them at.
--
-- This exists because the failure it was written for is invisible from one
-- screen: everybody's own phasing looks perfect while two other cars bounce off
-- each other. Run it on each machine during the same pass and the owner column
-- is what tells you whose simulation produced the contact.
RegisterCommand("phasing", function()
    local myId = PlayerId()
    print(("^2[phasing] me = player %d^7"):format(myId))

    for _, plr in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(plr)
        if ped ~= 0 and DoesEntityExist(ped) then
            local veh = GetVehiclePedIsIn(ped, false)
            local pedOwner = NetworkGetEntityOwner(ped)
            local vehOwner = veh ~= 0 and NetworkGetEntityOwner(veh) or -1
            local mine = (plr == myId) or pedOwner == myId or vehOwner == myId

            print(("  %-18s ped owner %-3d  veh owner %-3s  -> tier %d%s"):format(
                GetPlayerName(plr),
                pedOwner,
                veh ~= 0 and tostring(vehOwner) or "-",
                mine and 1 or 2,
                plr == myId and "  (me)" or ""))
        end
    end
end, false)

-- ── Dedicated camera-collision guard ─────────────────────────────────────────
-- Physics collision and CAMERA collision are separate systems.
-- SetEntityNoCollisionEntity stops the cars touching; the chase camera still
-- sweeps against the other car's bounds and gets shoved into/under your own
-- vehicle as you pass through — the "camera drops when I go through someone"
-- symptom. DisableCamCollisionForObject is the fix, but the flag lasts exactly
-- one frame, so it must be re-asserted every frame for every entity.
--
-- Enumerating by PLAYER missed two cases that happen precisely when you are
-- overlapping someone at speed:
--
--   1. GetVehiclePedIsIn(remotePed) returns 0 whenever the remote ped's seat
--      state has not synced yet — mid-stream-in, or right after they enter a
--      car. The ped got the flag, the two-tonne car around it did not.
--   2. A ghosted vehicle with no player in it — driver disconnected, or a car
--      left behind mid-race — is not any player's vehicle, so it was never
--      covered at all.
--
-- Sweeping the vehicle pool catches both, and picks up every other ghosted
-- entity (duel and raceline ghosts, checkpoint gate props) for
-- free via GetEntityCollisionDisabled, because they all switch collision off.
--
-- Two passes, because they have different freshness requirements:
--
--   • PLAYERS are enumerated every frame. GetActivePlayers is bounded and cheap,
--     and the handles are always current. This matters most in a RACE: cars
--     close on each other and stream in at speed, and a cached list is stale by
--     up to its rescan interval — 250 ms is ~14 m of closing at racing pace,
--     which is exactly the pass-through where the camera drops. Caching this
--     pass was a regression on the case the guard exists for.
--
--   • The POOL SWEEP is throttled. It exists for the entities player
--     enumeration cannot see — a ghosted car with nobody in it, a remote ped
--     whose seat has not synced, duel and raceline ghosts,
--     checkpoint gate props (all of which switch collision off, so
--     GetEntityCollisionDisabled finds them). None of those appear and close in
--     under a tenth of a second.
local CamGhostRange   = 45.0    -- metres; comfortably past chase-cam reach
local CamRescanMs     = 150

local CamTargets = {}

local function RebuildCamTargets()
    local myPed = PlayerPedId()
    local myVeh = GetVehiclePedIsIn(myPed, false)
    local myPos = GetEntityCoords(myPed)
    local out   = {}

    -- Vehicles: any nearby car that is either player-driven or already ghosted.
    -- NPC traffic is deliberately excluded — those cars really do collide, so
    -- the camera should collide with them too.
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if veh ~= myVeh and DoesEntityExist(veh)
        and #(myPos - GetEntityCoords(veh)) < CamGhostRange then
            local ghosted = GetEntityCollisionDisabled(veh)
            if not ghosted then
                -- Any seat, not just the driver: a passenger still makes this a
                -- player car, and the driver seat may not have synced yet.
                for seat = -1, 3 do
                    local ped = GetPedInVehicleSeat(veh, seat)
                    if ped ~= 0 and IsPedAPlayer(ped) then ghosted = true break end
                end
            end
            if ghosted then out[#out + 1] = veh end
        end
    end

    CamTargets = out
end

CreateThread(function()
    while true do
        RebuildCamTargets()
        Wait(CamRescanMs)
    end
end)

CreateThread(function()
    while true do
        local myId  = PlayerId()
        local myPed = PlayerPedId()
        local myPos = GetEntityCoords(myPed)

        -- Pass 1 — every remote player, resolved fresh this frame. A racer who
        -- streamed in since the last sweep is covered on the frame they appear,
        -- not up to a sweep later.
        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local ped = GetPlayerPed(plr)
                if ped ~= 0 and DoesEntityExist(ped)
                and #(myPos - GetEntityCoords(ped)) < CamGhostRange then
                    DisableCamCollisionForObject(ped)
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then DisableCamCollisionForObject(veh) end
                end
            end
        end

        -- Pass 2 — the throttled sweep's findings: ghosted entities and cars
        -- whose occupancy the frame above could not resolve.
        local targets = CamTargets
        for i = 1, #targets do
            local e = targets[i]
            if DoesEntityExist(e) then
                DisableCamCollisionForObject(e)
            end
        end

        Wait(0)
    end
end)
