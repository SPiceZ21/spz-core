-- server/appearance/crew_outfit.lua — appearance: crew_outfit.
-- Moved from spz-appearance/server/crew_outfit.lua when it was merged into spz-core.

-- spz-appearance/server/crew_outfit.lua

function PropagateCrewOutfit(crewId, outfit)
    MySQL.update.await(
        "UPDATE crews SET crew_outfit = ? WHERE id = ?",
        { json.encode(outfit), crewId }
    )
    local members = exports["spz-core"]:GetOnlineCrewMembers(crewId)
    for _, memberSource in ipairs(members) do
        -- Each member keeps their own face / hair colours under the clothes.
        TriggerClientEvent("SPZ:applyCrewOutfit", memberSource, outfit, GetSavedOutfit(memberSource))
    end
end

function GetCrewOutfit(crewId)
    local result = MySQL.query.await(
        "SELECT crew_outfit FROM crews WHERE id = ? LIMIT 1",
        { crewId }
    )
    if result and result[1] and result[1].crew_outfit then
        return json.decode(result[1].crew_outfit)
    end
    return nil
end

