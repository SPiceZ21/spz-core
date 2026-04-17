-- spz-core/client/main.lua

-- 1.0 Loading Screen Management
-- FiveM requires a manual shutdown for loading screens.
-- We hook into the spawnmanager's 'playerSpawned' event to ensure
-- we only shut it down once the player is actually in the world.

local hasSpawned = false

AddEventHandler('playerSpawned', function()
    if not hasSpawned then
        hasSpawned = true
        
        -- Delay slightly to ensure world geometry and textures have loaded behind the UI
        Citizen.SetTimeout(1500, function()
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            
            print("^2[spz-core] Player spawned and world ready. Loading screen shut down.^0")
            
            -- Trigger internal core ready for client modules
            TriggerEvent("SPZ:clientReady")
        end)
    end
end)

-- 1.1 State Consistency Check
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        -- Placeholder for future heartbeat or state verification
    end
end)

-- 1.2 Resource Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Perform any mandatory client-side cleanup here
end)
