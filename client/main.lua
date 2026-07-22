-- spz-core/client/main.lua

-- ── Resource Cleanup ──────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Mandatory client-side cleanup goes here
end)

-- ── Infinite Health & Invincibility ───────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local playerId = PlayerId()
        
        -- Enforce invincibility
        if GetPlayerInvincible(playerId) == false then
            SetPlayerInvincible(playerId, true)
        end
        if GetEntityCanBeDamaged(ped) then
            SetEntityInvincible(ped, true)
            SetEntityCanBeDamaged(ped, false)
        end
        
        -- Restore health to max continuously
        local maxHealth = GetEntityMaxHealth(ped)
        if GetEntityHealth(ped) < maxHealth then
            SetEntityHealth(ped, maxHealth)
        end
        
        Citizen.Wait(100) -- Check every 100ms for high efficiency
    end
end)

-- ── Disable Default GTA V HUD Elements ────────────────────────────────────
Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do
        Citizen.Wait(100)
    end
    
    while true do
        Citizen.Wait(0) -- Must run every frame to override default HUD rendering
        
        -- 1. Hide default HUD component IDs (1 to 22)
        -- This covers cash, weapon selection, wanted stars, street/area names, etc.
        for i = 1, 22 do
            HideHudComponentThisFrame(i)
        end
        
        -- 2. Hide default health & armor bars below the minimap
        -- We achieve this cleanly via the Scaleform override (Golf Mode logic)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3) -- 3 hides health & armor bars completely
        EndScaleformMovieMethod()
    end
end)

-- ── Ambient NPCs & Traffic Density Control ──────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Must run every frame to set NPC generation multipliers

        if Config.disable_npcs then
            -- Legacy hard-disable override
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            SetAmbientVehicleRangeMultiplierThisFrame(0.0)
            SetAmbientPedRangeMultiplierThisFrame(0.0)
            SetCreateRandomCops(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetCreateRandomCopsOnScenarios(false)
            CancelCurrentPoliceReport()
            SetGarbageTrucks(false)
            SetRandomBoats(false)
        else
            local npc = Config.NPCs or {}

            if npc.enabled == false then
                -- Disabled via Config.NPCs.enabled
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetPedDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetAmbientVehicleRangeMultiplierThisFrame(0.0)
                SetAmbientPedRangeMultiplierThisFrame(0.0)
            else
                -- Apply configurable density multipliers (defaults to low density)
                local vehDensity    = npc.vehicle_density or 0.2
                local randDensity   = npc.random_vehicle_density or 0.2
                local parkedDensity = npc.parked_vehicle_density or 0.2
                local pedDensity    = npc.ped_density or 0.1
                local scenPed       = npc.scenario_ped_density or 0.1
                local vehRange      = npc.ambient_vehicle_range or 0.5
                local pedRange      = npc.ambient_ped_range or 0.5

                SetVehicleDensityMultiplierThisFrame(vehDensity)
                SetRandomVehicleDensityMultiplierThisFrame(randDensity)
                SetParkedVehicleDensityMultiplierThisFrame(parkedDensity)
                SetPedDensityMultiplierThisFrame(pedDensity)
                SetScenarioPedDensityMultiplierThisFrame(scenPed, scenPed)
                SetAmbientVehicleRangeMultiplierThisFrame(vehRange)
                SetAmbientPedRangeMultiplierThisFrame(pedRange)
            end

            -- Cops and Police reports
            if npc.disable_cops ~= false then
                SetCreateRandomCops(false)
                SetCreateRandomCopsNotOnScenarios(false)
                SetCreateRandomCopsOnScenarios(false)
                CancelCurrentPoliceReport()
            end

            -- Dispatch Services
            if npc.disable_dispatch ~= false then
                for i = 1, 15 do
                    EnableDispatchService(i, false)
                end
            end

            -- Special ambient vehicles
            if npc.disable_garbage_trucks ~= false then
                SetGarbageTrucks(false)
            end

            if npc.disable_random_boats ~= false then
                SetRandomBoats(false)
            end
        end
    end
end)

