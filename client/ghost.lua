-- client/ghost.lua
-- No collision between players. Always. Everywhere. No conditions, no state.
-- World collision (roads, buildings, props, NPC traffic) is untouched.
--
-- CRITICAL: SetEntityNoCollisionEntity(a, b, disableCollision) — the 3rd arg
-- must be FALSE. false = collision disabled PERMANENTLY. true = disabled only
-- until the two entities next separate, at which point it snaps back ON. With
-- the "true" bug two overlapping cars stay ghosted but a third that briefly
-- separates re-collides — the "2 players fine, 3rd collides" symptom.

--
-- ── Cadence ──────────────────────────────────────────────────────────────────
--
-- The flag is nominally permanent per pair, and the previous version leaned on
-- that: assert everything, then sleep 200 ms. It does not hold. The exclusion
-- is dropped whenever an entity is re-created (stream out and back in), when
-- network ownership migrates, and whenever anything calls SetEntityCollision on
-- one of the pair — which spz-spawn does after every spawn and spz-appearance
-- after every outfit change. None of those alter the entity HANDLE, so the old
-- signature check could not see them; it only shortened the sleep when a handle
-- appeared or disappeared.
--
-- A 200 ms hole is ~11 metres of closing at racing speed. That is one real hit,
-- and it reads exactly as "ghosting randomly failed".
--
-- So the work is split by who actually needs it, the same way the camera guard
-- below is split:
--
--   NEAR PASS, every frame — my ped and my car against every nearby player.
--     This is the only set whose physics I simulate, so it is the only set
--     where a missing flag can throw ME. It is 2 x 2n calls: trivial.
--
--   FULL PASS, throttled — every remaining pair, including remote-vs-remote.
--     Worth doing, but not per frame, because I do not simulate contact between
--     two cars someone else owns; I replay the positions their owner sends me.
--     If their clients ghosted correctly they never touch, and if one did not,
--     no flag of mine changes what I am shown. This pass is here for the cases
--     where I DO own something — an orphaned car, a vehicle I created — and as
--     cover while a remote client is still starting up.
--
-- That second point is worth stating plainly, because it bounds what this file
-- can fix: collision is resolved by the network OWNER. Ghosting is only ever as
-- good as the worst-behaved client in the lobby.

local NEAR_RANGE   = 70.0    -- metres; past any plausible contact this frame
local FULL_SWEEP_MS = 400

local LastPed, LastVeh = 0, 0

--- Both directions of every entity pairing between two players.
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

-- ── Near pass: me against everyone close, every frame ────────────────────────

CreateThread(function()
    while true do
        local myId  = PlayerId()
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        local myPos = GetEntityCoords(myPed)

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

        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local ped = GetPlayerPed(plr)
                if ped ~= 0 and DoesEntityExist(ped)
                and #(myPos - GetEntityCoords(ped)) < NEAR_RANGE then
                    Unlink(myPed, myVeh, ped, GetVehiclePedIsIn(ped, false))
                end
            end
        end

        Wait(0)
    end
end)

-- ── Full pass: every pair, throttled ─────────────────────────────────────────

CreateThread(function()
    while true do
        local ents = {}
        for _, plr in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(plr)
            if ped ~= 0 and DoesEntityExist(ped) then
                ents[#ents + 1] = { ped = ped, veh = GetVehiclePedIsIn(ped, false) }
            end
        end

        -- World collision stays intact throughout: never SetEntityCollision on
        -- a remote entity, that sinks cars through the road.
        local n = #ents
        for i = 1, n do
            for j = i + 1, n do
                local a, b = ents[i], ents[j]
                Unlink(a.ped, a.veh, b.ped, b.veh)
            end
        end

        Wait(FULL_SWEEP_MS)
    end
end)

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
