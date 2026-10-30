-- client/commands.lua
-- Utility commands: /fix (repair vehicle), /tpm (teleport to waypoint or player)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function Notify(msg, type)
    lib.notify({
        description = msg,
        type        = type or "info",
    })
end

-- ── /fix — repair current vehicle ─────────────────────────────────────────────
-- Fully repairs body, engine, and visual damage on the vehicle you're driving.

RegisterCommand("fix", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        Notify("You are not in a vehicle.", "error")
        return
    end

    SetVehicleFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)
    SetVehicleEngineOn(veh, true, true, false)

    Notify("Vehicle repaired.", "success")
end, false)

-- ── /tpm — teleport ───────────────────────────────────────────────────────────
-- No args:      teleport to your map waypoint
-- With player ID: teleport to that player

RegisterCommand("tpm", function(_, args)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = veh ~= 0 and veh or ped

    -- ── Teleport to player ────────────────────────────────────────────────
    if args[1] then
        local targetId = tonumber(args[1])
        if not targetId then
            Notify("Usage: /tpm [player ID]", "error")
            return
        end

        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        if targetPed == 0 or not DoesEntityExist(targetPed) then
            Notify("Player not found or not nearby.", "error")
            return
        end

        local coords = GetEntityCoords(targetPed)
        SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, true)
        Notify(("Teleported to player %d."):format(targetId), "success")
        return
    end

    -- ── Teleport to waypoint ──────────────────────────────────────────────
    if not IsWaypointActive() then
        Notify("Set a waypoint on the map first, or use /tpm [player ID].", "error")
        return
    end

    local waypoint = GetFirstBlipInfoId(8)  -- 8 = waypoint blip sprite
    if not DoesBlipExist(waypoint) then
        Notify("Could not find waypoint.", "error")
        return
    end

    local coord = GetBlipInfoIdCoord(waypoint)
    local x, y = coord.x, coord.y

    -- Find the ground Z at the waypoint. Try progressively higher Z values
    -- because GetGroundZFor_3dCoord only returns hits near the probe point.
    local z = 0.0
    local found = false
    for probe = 0.0, 1000.0, 25.0 do
        SetEntityCoordsNoOffset(entity, x, y, probe, false, false, false)
        Wait(50)
        local ok, gz = GetGroundZFor_3dCoord(x, y, probe + 5.0, false)
        if ok then
            z = gz
            found = true
            break
        end
    end

    if not found then z = 200.0 end  -- fallback: drop from a safe height

    SetEntityCoordsNoOffset(entity, x, y, z + 1.0, false, false, false)
    Notify("Teleported to waypoint.", "success")
end, false)

-- ── Rockstar Editor ───────────────────────────────────────────────────────────
-- /record      start recording a clip (again: stop and save it)
-- /stoprecord  stop and save the clip
-- /discardclip stop without saving
-- /editor      open the Rockstar Editor (clips are under Clip Management)

RegisterCommand("record", function()
    if IsRecording() then
        StopRecordingAndSaveClip()
        Notify("Clip saved — open it with /editor.", "success")
        return
    end
    StartRecording(1)
    Notify("Recording… /record or /stoprecord to save, /discardclip to throw it away.", "info")
end, false)

RegisterCommand("stoprecord", function()
    if not IsRecording() then return Notify("You are not recording.", "error") end
    StopRecordingAndSaveClip()
    Notify("Clip saved — open it with /editor.", "success")
end, false)

RegisterCommand("discardclip", function()
    if not IsRecording() then return Notify("You are not recording.", "error") end
    StopRecordingAndDiscardClip()
    Notify("Recording discarded.", "info")
end, false)

RegisterCommand("editor", function()
    if LocalPlayer.state.inRace or LocalPlayer.state.inMinigame then
        return Notify("Leave the race or minigame first — the editor takes you out of the session view.", "error")
    end
    if IsRecording() then StopRecordingAndSaveClip() end
    ActivateRockstarEditor()
end, false)

TriggerEvent("chat:addSuggestion", "/record", "Start / stop-and-save a Rockstar Editor clip")
TriggerEvent("chat:addSuggestion", "/stoprecord", "Stop recording and save the clip")
TriggerEvent("chat:addSuggestion", "/discardclip", "Stop recording without saving")
TriggerEvent("chat:addSuggestion", "/editor", "Open the Rockstar Editor")
