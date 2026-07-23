-- client/ghost.lua
-- No collision between players. Always. Everywhere. No conditions, no state.
-- World collision (roads, buildings, props, NPC traffic) is untouched.
--
-- CRITICAL: SetEntityNoCollisionEntity(a, b, disableCollision) — the 3rd arg
-- must be FALSE. false = collision disabled PERMANENTLY. true = disabled only
-- until the two entities next separate, at which point it snaps back ON. With
-- the "true" bug two overlapping cars stay ghosted but a third that briefly
-- separates re-collides — the "2 players fine, 3rd collides" symptom.

CreateThread(function()
    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        local myId  = PlayerId()

        -- keep everyone fully opaque (no accidental ghost transparency)
        SetEntityAlpha(myPed, 255, false)
        if myVeh ~= 0 then SetEntityAlpha(myVeh, 255, false) end

        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)

                if tPed ~= 0 and DoesEntityExist(tPed) then
                    local tVeh = GetVehiclePedIsIn(tPed, false)

                    -- ── Kill collision on the remote entities outright ──
                    -- Pairwise flags don't bind the entity OWNER's physics;
                    -- turning collision fully off on the remote copy removes
                    -- every impulse locally. Skip the car WE ride in (would
                    -- drop through the world on our screen).
                    SetEntityCollision(tPed, false, false)
                    if tVeh ~= 0 and tVeh ~= myVeh then
                        SetEntityCollision(tVeh, false, false)
                    end

                    -- ── Pairwise, both directions, PERMANENT (3rd arg false) ──
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

                    -- ── Camera ignores them too (no cam shove/clip) ─────
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
