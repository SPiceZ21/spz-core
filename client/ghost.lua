-- client/ghost.lua
-- No collision between players. Always. Everywhere. No conditions, no state.
-- World collision (roads, buildings, props, NPC traffic) is untouched.
--
-- CRITICAL: SetEntityNoCollisionEntity(a, b, disableCollision) — the 3rd arg
-- must be FALSE. false = collision disabled PERMANENTLY. true = disabled only
-- until the two entities next separate, at which point it snaps back ON. With
-- the "true" bug two overlapping cars stay ghosted but a third that briefly
-- separates re-collides — the "2 players fine, 3rd collides" symptom.

local LastPed, LastVeh = 0, 0
local LastSig = nil       -- signature of the last processed entity set

CreateThread(function()
    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        local myId  = PlayerId()

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

        -- Collect every player's ped + vehicle once.
        local ents = {}
        for _, plr in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(plr)
            if ped ~= 0 and DoesEntityExist(ped) then
                ents[#ents + 1] = { ped = ped, veh = GetVehiclePedIsIn(ped, false) }
            end
        end

        -- Disable collision between EVERY PAIR, not just me-vs-others. Otherwise
        -- on my screen two OTHER players still crash into each other (and the same
        -- on their screens). All pairs = everyone phases through everyone locally.
        -- SetEntityNoCollisionEntity(a, b, false) is permanent + world collision
        -- stays intact (never SetEntityCollision(remote,false) — that sinks cars).
        local n = #ents
        for i = 1, n do
            local a = ents[i]
            for j = i + 1, n do
                local b = ents[j]
                SetEntityNoCollisionEntity(a.ped, b.ped, false)
                SetEntityNoCollisionEntity(b.ped, a.ped, false)
                if a.veh ~= 0 then
                    SetEntityNoCollisionEntity(a.veh, b.ped, false)
                    SetEntityNoCollisionEntity(b.ped, a.veh, false)
                end
                if b.veh ~= 0 then
                    SetEntityNoCollisionEntity(a.ped, b.veh, false)
                    SetEntityNoCollisionEntity(b.veh, a.ped, false)
                end
                if a.veh ~= 0 and b.veh ~= 0 then
                    SetEntityNoCollisionEntity(a.veh, b.veh, false)
                    SetEntityNoCollisionEntity(b.veh, a.veh, false)
                end
            end
        end

        -- The flag is permanent per pair, so a steady field needs no re-work.
        -- The one moment it DOES matter is the frame a car streams in: until
        -- this pass runs, that pair still collides. A flat 200 ms window is ~11
        -- metres of travel at racing speed — enough for one real hit on
        -- stream-in, which reads as "ghosting randomly failed". So: when the
        -- entity set changed (someone streamed in, swapped car, respawned),
        -- come straight back round instead of sleeping the full interval.
        local sig = table.concat({ n, ents[1] and ents[1].ped or 0, ents[n] and ents[n].ped or 0 }, ":")
        for i = 1, n do sig = sig .. "," .. ents[i].ped .. "." .. ents[i].veh end

        if sig ~= LastSig then
            LastSig = sig
            Wait(0)      -- set changed: re-assert immediately on the next frame
        else
            Wait(200)    -- steady state: cheap even at 16 players (120 pairs)
        end
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
-- entity (race ghost-bots, duel/raceline ghosts, checkpoint gate props) for
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
--     whose seat has not synced, race ghost-bots, duel and raceline ghosts,
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
