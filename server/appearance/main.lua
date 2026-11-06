-- server/appearance/main.lua — appearance: main.
-- Moved from spz-appearance/server/main.lua when it was merged into spz-core.

-- server/main.lua

function GetOutfitForPlayer(source)
  local profile = Player(source).state.profile
  if not profile then return nil, nil end

  -- Priority 1: crew outfit
  if profile.crew_id then
    local crewOutfit = GetCrewOutfit(profile.crew_id)
    if crewOutfit then
      return crewOutfit, "crew"
    end
  end

  -- Priority 2: personal saved outfit
  local savedOutfit = GetSavedOutfit(source)
  if savedOutfit then
    return savedOutfit, "personal"
  end

  -- No predefined uniform — keep whatever the player is wearing
  return nil, nil
end

print("^2[spz-appearance] Server script loading...^7")

-- Schema (player_outfits, crews.crew_outfit) is owned by
-- spz-core/migrations/core/001_core_schema.sql.

lib.callback.register("spz-appearance:getMyOutfit", function(source)
  local outfit, source_type = GetOutfitForPlayer(source)
  -- Crew outfits are clothing only. Send the member's own saved look too, so
  -- their face / hair / eye / makeup colours are painted under the crew
  -- clothes -- without it every crew member spawned with default colours.
  local personal = source_type == "crew" and GetSavedOutfit(source) or nil
  return { outfit = outfit, source_type = source_type, personal = personal }
end)

AddEventHandler("SPZ:crewChanged", function(source, oldCrewId, newCrewId)
  if newCrewId then
    -- Joined a crew — check for crew outfit
    local crewOutfit = GetCrewOutfit(newCrewId)
    if crewOutfit then
      TriggerClientEvent("SPZ:applyCrewOutfit", source, crewOutfit, GetSavedOutfit(source))
      return
    end
  end
  -- Left crew or crew has no outfit — re-apply normally
  TriggerClientEvent("SPZ:applyOutfit", source)
end)

-- Reactive outfit re-application on statebag change.
-- Statebags fire on every WRITE, even when the value is identical, so this must
-- compare against the last seen value — otherwise a redundant crewId write
-- re-applies the outfit, and the outfit callback's own profile read writes it
-- again: a self-feeding loop that hammered the database.
local LastCrewId = {}

AddStateBagChangeHandler("crewId", nil, function(bagName, key, value)
  local source = tonumber(bagName:match("player:(%d+)"))
  if not source then return end

  if LastCrewId[source] == value then return end   -- unchanged: nothing to do
  LastCrewId[source] = value

  -- Brief wait to ensure identity has finished all profile updates
  Citizen.SetTimeout(500, function()
    TriggerClientEvent("SPZ:applyOutfit", source)
  end)
end)

AddEventHandler("playerDropped", function()
  LastCrewId[source] = nil
end)

