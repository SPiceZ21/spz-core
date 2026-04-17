-- client/spawn_manager.lua

local isDead = false

-- Prevent GTA V base spawning systems
if GetResourceState("spawnmanager") == "started" then
    AddEventHandler("onClientMapStart", function()
        exports.spawnmanager:setAutoSpawn(false)
    end)
end

RegisterNetEvent("SPZ:spawnPlayerTarget", function(data)
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(500)

    -- Force model
    local modelHash = data.gender == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)
    
    local newPed = PlayerPedId()

    -- Resurrect natively
    local coords = Config.SafeZone.coords
    local heading = Config.SafeZone.heading
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true)
    
    -- Cleanup visual flags
    SetEntityVisible(newPed, true, false)
    SetEntityInvincible(newPed, false)
    ClearPedBloodDamage(newPed)
    RemoveAllPedWeapons(newPed, true)
    
    -- Sync final state back to identity locally
    exports["spz-identity"]:SetPlayerState("FREEROAM")

    isDead = false

    -- Signal appearance to apply outfit now ped is ready
    TriggerEvent("SPZ:applyOutfit")

    DoScreenFadeIn(1000)
end)

-- Simple Death Monitor 
Citizen.CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        
        if IsEntityDead(ped) and not isDead then
            isDead = true
            
            -- Wait 5 seconds on the death screen before auto-respawn
            Wait(5000)
            
            TriggerServerEvent("SPZ:requestRespawn")
        end
    end
end)
