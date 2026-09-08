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

-- ── WHY THE PAIR FLAG IS NOT ENOUGH ──────────────────────────────────────────
--
-- Everything above describes making SetEntityNoCollisionEntity as timely as it
-- can be. It is worth doing and it is still not sufficient, because the flag
-- itself is the wrong shape for this problem:
--
--   * it is a property of a PAIR, so N racers need N(N-1)/2 of them held
--     correctly on the right machines, continuously, forever;
--   * it is dropped by things this script cannot observe — re-creation on
--     stream-in, ownership migration, any SetEntityCollision call from another
--     resource;
--   * and it only binds the machine that holds it, which is why three drivers
--     could each watch a different crash.
--
-- The engine has a purpose-built mechanism for exactly this, and it is the one
-- GTA Online itself uses for passive mode: GHOSTING. A ghosted entity is a
-- property of the ENTITY, not of a pair. It does not care how many other
-- players are nearby, there is nothing to re-assert per opponent, and the state
-- is network-synced rather than held independently on every machine.
--
-- So ghosting is the PRIMARY mechanism now, and the pair flags below stay as a
-- backstop for anything it does not reach.
--
-- This is not a guess: cw-racingapp phases racers with exactly these two calls
-- and no pair flags at all (client/main.lua, ghostPlayer/unGhostPlayer). Where
-- this file differs from that reference, the difference is deliberate and the
-- reason is written next to it.
--
-- SetGhostedEntityAlpha(255) is what keeps bodywork solid-looking: the ghost
-- system renders ghosted entities translucent by default, which is right for
-- passive mode in Los Santos and wrong for a race where every car is ghosted.
-- (This is NOT the same call as SetEntityAlpha, which must never be used here
-- for the depth-buffer reason documented further down.)

local ENGINE_GHOST = true

-- Opaque. NOT 255.
--
-- 255: fully opaque, no trace of the ghost system's translucency.
--
-- cw-racingapp uses 254 for both its ghosted and un-ghosted state, on the
-- reasoning that the very top of a 0-255 override range is where "fully opaque"
-- and "no override at all" can blur together. The two are visually identical,
-- so if ghosted cars ever render see-through, 254 is the first thing to try —
-- but 255 is what is asked for here and it says exactly what it means.
local GHOST_ALPHA = 255

-- Native availability is checked rather than assumed: these are GTA Online
-- natives and their presence depends on the game build. If they are missing the
-- pair flags below still run, and the log line says which mode is live so a
-- silent downgrade cannot be mistaken for a working one.
local HasGhostNatives =
    type(SetLocalPlayerAsGhost) == "function" and
    type(SetGhostedEntityAlpha) == "function"

CreateThread(function()
    Wait(1000)
    if not ENGINE_GHOST then
        print("^3[phasing] engine ghosting disabled by config — pair flags only^7")
    elseif HasGhostNatives then
        print("^2[phasing] engine ghosting active (+ pair flags as backstop)^7")
    else
        print("^1[phasing] engine ghosting natives unavailable — pair flags only^7")
    end
end)

-- One call covers the player AND the car they are driving. There is deliberately
-- no SetNetworkVehicleAsGhost here: ghosting the local player already carries
-- the vehicle, which is why the reference implementations only ever make this
-- one call and simply stop making it when the player is not the driver.
--
-- A PASSENGER is un-ghosted for that reason. The car belongs to whoever is in
-- the driver's seat and they are already ghosting it; a passenger asserting a
-- second, independent ghost state over the same vehicle is two writers on one
-- value, and the resulting flicker looks exactly like ghosting failing at random.
CreateThread(function()
    local ghosted = nil     -- nil = never set, so the first pass always writes

    while true do
        if ENGINE_GHOST and HasGhostNatives then
            local ped  = PlayerPedId()
            local veh  = GetVehiclePedIsIn(ped, false)
            local want = (veh == 0) or (GetPedInVehicleSeat(veh, -1) == ped)

            -- Re-asserted every pass rather than only on change: the alpha is a
            -- global other resources also write, and the ghost flag is dropped
            -- by respawns and model changes without anything telling us.
            if want then
                SetLocalPlayerAsGhost(true)
                SetGhostedEntityAlpha(GHOST_ALPHA)
            elseif ghosted ~= false then
                SetLocalPlayerAsGhost(false)
                SetGhostedEntityAlpha(GHOST_ALPHA)
            end

            ghosted = want
        end

        Wait(200)
    end
end)

-- Leave nobody stuck as a ghost if this resource stops mid-session.
AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if HasGhostNatives then SetLocalPlayerAsGhost(false) end
end)

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
    print(("^2[phasing] engine ghosting: %s^7"):format(
        (not ENGINE_GHOST) and "off (config)"
        or (HasGhostNatives and "ON" or "UNAVAILABLE - natives missing")))

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
-- symptom.
--
-- There are TWO natives for this and the wrong one was being called. The code
-- used DisableCamCollisionForObject on peds and vehicles — an OBJECT, in GTA's
-- vocabulary, is a prop, and a car is not one. DisableCamCollisionForEntity is
-- the variant that takes any entity, and it is the one that has to be called for
-- a player's ped and their vehicle. Both are called below: the entity variant
-- because it is correct, the object variant because it costs one native and
-- covers the prop case for the gate models the sweep also picks up.
--
-- The flag is per frame either way, so it is re-asserted every frame for every
-- entity.
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
-- Both variants, guarded. Which one a given build exposes is not something to
-- assume, and a missing native here fails silently — which is precisely how a
-- camera guard ends up looking like it works while doing nothing at all.
local HasCamEntity = type(DisableCamCollisionForEntity) == "function"
local HasCamObject = type(DisableCamCollisionForObject) == "function"

local function NoCamCollision(e)
    if HasCamEntity then DisableCamCollisionForEntity(e) end
    if HasCamObject then DisableCamCollisionForObject(e) end
end

CreateThread(function()
    Wait(1000)
    if not (HasCamEntity or HasCamObject) then
        print("^1[phasing] no cam-collision native available — the chase camera WILL catch on other cars^7")
    elseif not HasCamEntity then
        print("^3[phasing] cam collision: object variant only (entity variant missing)^7")
    end
end)

local HasGhostQuery = type(NetworkIsEntityGhostedToLocalPlayer) == "function"

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
            -- Engine-ghosted entities do NOT report collision as disabled:
            -- ghosting and SetEntityCollision are different systems, and now
            -- that ghosting is the primary mechanism this sweep lost the signal
            -- it used to find player cars by. Ask the ghost system directly
            -- as well.
            local ghosted = GetEntityCollisionDisabled(veh)
            if not ghosted and HasGhostQuery then
                ghosted = NetworkIsEntityGhostedToLocalPlayer(veh)
            end
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
                    NoCamCollision(ped)
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then NoCamCollision(veh) end
                end
            end
        end

        -- Pass 2 — the throttled sweep's findings: ghosted entities and cars
        -- whose occupancy the frame above could not resolve.
        local targets = CamTargets
        for i = 1, #targets do
            local e = targets[i]
            if DoesEntityExist(e) then
                NoCamCollision(e)
            end
        end

        Wait(0)
    end
end)
