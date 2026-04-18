-- client/spawn_manager.lua

-- ── Disable spawnmanager as early as possible ────────────────────────────
-- setAutoSpawn must be called immediately when the resource starts AND again
-- on onClientMapStart (spawnmanager re-enables itself on every map start).
local function DisableSpawnManager()
    if GetResourceState("spawnmanager") == "started" then
        exports.spawnmanager:setAutoSpawn(false)
    end
end

DisableSpawnManager()
AddEventHandler("onClientMapStart", DisableSpawnManager)

-- ── Loading screen ────────────────────────────────────────────────────────
-- Shut it down when the server confirms the player is ready for the play menu.
-- We do NOT rely on playerSpawned because we never let spawnmanager spawn.
RegisterNetEvent("SPZ:showPlayMenu")
AddEventHandler("SPZ:showPlayMenu", function()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)

-- ── Physical spawn ─────────────────────────────────────────────────────────
local isDead = false

RegisterNetEvent("SPZ:spawnPlayerTarget", function(data)
    local modelHash = data.gender == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`

    DoScreenFadeOut(500)
    Wait(500)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)

    local newPed = PlayerPedId()
    local coords  = Config.SafeZone.coords
    local heading = Config.SafeZone.heading

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true)

    SetEntityVisible(newPed, true, false)
    SetEntityInvincible(newPed, false)
    ClearPedBloodDamage(newPed)
    RemoveAllPedWeapons(newPed, true)

    exports["spz-identity"]:SetPlayerState("FREEROAM")
    isDead = false

    TriggerEvent("SPZ:applyOutfit")
    DoScreenFadeIn(1000)
end)

-- ── Safe-zone teleport (called by cleanup after a race) ───────────────────
RegisterNetEvent("SPZ:tpToSafeZone")
AddEventHandler("SPZ:tpToSafeZone", function()
    local ped     = PlayerPedId()
    local coords  = Config.SafeZone.coords
    local heading = Config.SafeZone.heading
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, heading)
end)

-- ── Death monitor ─────────────────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsEntityDead(ped) and not isDead then
            isDead = true
            Wait(5000)
            TriggerServerEvent("SPZ:requestRespawn")
        end
    end
end)
