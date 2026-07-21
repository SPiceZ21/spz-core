-- client/ghost.lua
-- No collision between players. Always. Everywhere. No conditions, no config,
-- no state — if this resource runs, you pass through every other player and
-- their vehicle, anywhere, at any time.
--
-- World collision (roads, buildings, props, NPC traffic) is untouched.
--
-- Uses the engine's native ghost-mode system (SetLocalPlayerAsGhost /
-- SetNetworkVehicleAsGhost) which properly excludes player-to-player
-- collision while preserving ground and world physics. The old approach of
-- SetEntityCollision(remote, false, false) killed ALL collision on the remote
-- copy — including ground — causing other players' cars to visually sink
-- through the road and pop back up.
--
-- Belt-and-braces: SetEntityNoCollisionEntity is still applied pairwise as a
-- safety net, and DisableCamCollisionForObject keeps the gameplay camera from
-- shoving against ghosted cars.

CreateThread(function()
    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        local myId  = PlayerId()

        -- ── Engine ghost mode ────────────────────────────────────────────
        -- These natives tell the engine to skip player-vs-player collision
        -- at the physics level, without touching world/ground collision.
        -- Must be called every frame (flag resets).
        SetLocalPlayerAsGhost(true)
        if myVeh ~= 0 then
            SetNetworkVehicleAsGhost(myVeh, true)
        end

        -- ── Per-player safety net ────────────────────────────────────────
        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)

                if tPed ~= 0 and DoesEntityExist(tPed) then
                    local tVeh = GetVehiclePedIsIn(tPed, false)

                    -- Pairwise no-collision (both directions) as a fallback.
                    -- Unlike SetEntityCollision(false), this only disables
                    -- collision between the two specific entities — ground
                    -- and world collision stay intact.
                    SetEntityNoCollisionEntity(myPed, tPed, true)
                    SetEntityNoCollisionEntity(tPed, myPed, true)

                    if myVeh ~= 0 then
                        SetEntityNoCollisionEntity(myVeh, tPed, true)
                        SetEntityNoCollisionEntity(tPed, myVeh, true)
                    end

                    if tVeh ~= 0 then
                        SetEntityNoCollisionEntity(myPed, tVeh, true)
                        SetEntityNoCollisionEntity(tVeh, myPed, true)

                        if myVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, tVeh, true)
                            SetEntityNoCollisionEntity(tVeh, myVeh, true)
                        end
                    end

                    -- ── Camera ignores them too ──────────────────────────
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
