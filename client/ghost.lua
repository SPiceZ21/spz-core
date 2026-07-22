Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- REMOVE GHOST MODE (makes player transparent)
        -- SetLocalPlayerAsGhost(ped, true)
        -- if veh ~= 0 then
        --     SetNetworkVehicleAsGhost(veh, true)
        -- end

        -- FORCE FULL VISIBILITY (100%)
        SetEntityAlpha(ped, 255, false)
        if veh ~= 0 then
            SetEntityAlpha(veh, 255, false)
        end

        -- KEEP NO COLLISIONS ONLY (all player ped/vehicle combinations)
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local tp = GetPlayerPed(player)
                if DoesEntityExist(tp) then
                    -- 1. Local Ped vs Remote Ped
                    SetEntityNoCollisionEntity(ped, tp, true)

                    local tv = GetVehiclePedIsIn(tp, false)
                    -- 2. Local Ped vs Remote Vehicle
                    if DoesEntityExist(tv) and tv ~= 0 then
                        SetEntityNoCollisionEntity(ped, tv, true)
                    end

                    if DoesEntityExist(veh) and veh ~= 0 then
                        -- 3. Local Vehicle vs Remote Ped (free ped)
                        SetEntityNoCollisionEntity(veh, tp, true)

                        -- 4. Local Vehicle vs Remote Vehicle
                        if DoesEntityExist(tv) and tv ~= 0 then
                            SetEntityNoCollisionEntity(veh, tv, true)
                        end
                    end
                end
            end
        end
    end
end)