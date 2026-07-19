-- client/ghost.lua
-- Global no-collision. Players and their vehicles NEVER collide with each
-- other, anywhere, always — freeroam, warmup, race, time trial. World
-- collision (buildings, props, terrain) is untouched.
--
-- No server, no statebags, no sessions: collision is a purely local render
-- concern, so the simplest correct implementation is a client loop. Nothing
-- can desync because there is no state to desync.
--
-- Re-asserted every frame on purpose: SetEntityNoCollisionEntity is silently
-- dropped whenever an entity re-streams into scope, so a one-shot pass decays
-- the moment someone drives out of range and back.

if Config and Config.GlobalNoCollision == false then return end

CreateThread(function()
    local myId = PlayerId()

    while true do
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)

        -- GetActivePlayers() only returns players streamed in around us, so
        -- this stays small (a handful) even on a full server.
        for _, plr in ipairs(GetActivePlayers()) do
            if plr ~= myId then
                local tPed = GetPlayerPed(plr)

                if tPed ~= 0 and DoesEntityExist(tPed) then
                    local tVeh = GetVehiclePedIsIn(tPed, false)

                    -- ped <-> ped
                    SetEntityNoCollisionEntity(myPed, tPed, false)
                    SetEntityNoCollisionEntity(tPed, myPed, false)

                    -- my vehicle <-> their ped / their vehicle
                    if myVeh ~= 0 then
                        SetEntityNoCollisionEntity(myVeh, tPed, false)
                        SetEntityNoCollisionEntity(tPed, myVeh, false)

                        if tVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, tVeh, false)
                            SetEntityNoCollisionEntity(tVeh, myVeh, false)
                        end
                    end

                    -- my ped <-> their vehicle (on foot near traffic)
                    if tVeh ~= 0 then
                        SetEntityNoCollisionEntity(myPed, tVeh, false)
                        SetEntityNoCollisionEntity(tVeh, myPed, false)
                    end
                end
            end
        end

        Wait(0)
    end
end)
