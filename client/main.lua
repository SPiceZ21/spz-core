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

-- ── Disable Ambient NPCs & Traffic ─────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Must run every frame to override NPC generation multipliers
        
        if Config.disable_npcs then
            -- Disable NPC vehicles/traffic
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            
            -- Disable NPC pedestrians
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0)
            
            -- Disable dispatch / random cops
            SetCreateRandomCops(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetCreateRandomCopsOnScenarios(false)
            CancelCurrentPoliceReport()
            
            -- Disable garbage trucks and random boats
            SetGarbageTrucks(false)
            SetRandomBoats(false)
        end
    end
end)

