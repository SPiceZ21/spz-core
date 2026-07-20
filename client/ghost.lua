-- client/ghost.lua
-- No collision between players. Always. Everywhere. No conditions, no config,
-- no state — if this resource runs, you pass through every other player and
-- their vehicle, anywhere, at any time.
--
-- World collision (roads, buildings, props, NPC traffic) is untouched.
--
-- Two things happen per frame, and both must be per frame:
--   1. SetEntityNoCollisionEntity  — dropped whenever an entity re-streams
--      into scope, so a one-shot pass silently decays.
--   2. DisableCamCollisionForObject — without this the gameplay camera still
--      collides with the cars you are driving through: it gets shoved, snaps
--      in tight, or clips inside their bodywork. Disabling cam collision on
--      the same entities makes the camera ignore them exactly like the car
--      does. This is the "no-collision cam bug".

CreateThread(function()
    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        local myId  = PlayerId()

        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)

                if tPed ~= 0 and DoesEntityExist(tPed) then
                    local tVeh = GetVehiclePedIsIn(tPed, false)

                    -- ── Kill collision on the remote entities outright ──
                    -- Pairwise no-collision alone can still let an impulse
                    -- through: the entity's network OWNER runs its physics,
                    -- and our local pair flag doesn't bind their side. Turning
                    -- collision fully off on the remote copy removes it for
                    -- good. Safe because remote entities are position-synced
                    -- from their owner — they keep driving normally, they just
                    -- stop interacting with anything on OUR client.
                    SetEntityCollision(tPed, false, false)
                    -- ...unless it is the car WE are sitting in: that vehicle
                    -- is our own ride, and stripping its collision locally
                    -- would drop it through the world on our screen.
                    if tVeh ~= 0 and tVeh ~= myVeh then
                        SetEntityCollision(tVeh, false, false)
                    end

                    -- ── Pairwise, both directions (belt and braces) ─────
                    SetEntityNoCollisionEntity(myPed, tPed, false)
                    SetEntityNoCollisionEntity(tPed, myPed, false)

                    if myVeh ~= 0 then
                        SetEntityNoCollisionEntity(myVeh, tPed, false)
                        SetEntityNoCollisionEntity(tPed, myVeh, false)
                    end

                    if tVeh ~= 0 then
                        SetEntityNoCollisionEntity(myPed, tVeh, false)
                        SetEntityNoCollisionEntity(tVeh, myPed, false)

                        if myVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, tVeh, false)
                            SetEntityNoCollisionEntity(tVeh, myVeh, false)
                        end
                    end

                    -- ── Camera ignores them too ─────────────────────────
                    DisableCamCollisionForObject(tPed)
                    if tVeh ~= 0 then
                        DisableCamCollisionForObject(tVeh)
                    end
                end
            end
        end

        Wait(0)
    end
end)
