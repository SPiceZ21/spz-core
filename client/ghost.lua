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

        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)

                if tPed ~= 0 and DoesEntityExist(tPed) then
                    local tVeh = GetVehiclePedIsIn(tPed, false)

                    -- Pairwise no-collision ONLY. Never SetEntityCollision(remote,
                    -- false) — that strips the entity's WORLD collision too, so
                    -- their car sinks through the ground on our screen.
                    -- SetEntityNoCollisionEntity disables collision only between
                    -- the two entities, both directions, permanently (arg = false).
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
                end
            end
        end

        Wait(0)
    end
end)

-- ── Dedicated camera-collision guard ─────────────────────────────────────────
-- The gameplay camera still SWEEPS against other players' peds/cars even though
-- bodies pass through — so it zooms/jerks when someone overlaps you. This runs
-- in its own tight per-frame loop (never starved by the no-collision work above)
-- and tells the camera to ignore every nearby remote player ped + vehicle. Must
-- be re-asserted every frame; the flag only lasts one frame.
CreateThread(function()
    while true do
        local myId  = PlayerId()
        local myPos = GetEntityCoords(PlayerPedId())

        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)
                if tPed ~= 0 and DoesEntityExist(tPed) then
                    -- Only bother with players close enough to affect the camera.
                    if #(myPos - GetEntityCoords(tPed)) < 30.0 then
                        DisableCamCollisionForObject(tPed)
                        local tVeh = GetVehiclePedIsIn(tPed, false)
                        if tVeh ~= 0 then DisableCamCollisionForObject(tVeh) end
                    end
                end
            end
        end

        Wait(0)
    end
end)
