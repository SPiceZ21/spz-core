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

        -- KEEP NO COLLISIONS ONLY
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local tp = GetPlayerPed(player)
                SetEntityNoCollisionEntity(ped, tp, true)

                if veh ~= 0 then
                    local tv = GetVehiclePedIsIn(tp, false)
                    if tv ~= 0 then
                        SetEntityNoCollisionEntity(veh, tv, true)
                    end
                end
            end
        end
    end
end)