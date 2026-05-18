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
