-- client/appearance/outfits.lua — appearance: outfits.
-- Moved from spz-appearance/client/outfits.lua when it was merged into spz-core.

-- client/outfits.lua
-- All outfit data uses fivem-appearance format:
--   components = { { component_id, drawable, texture }, ... }
--   props      = { { prop_id, drawable, texture }, ... }
--   + model, headBlend, faceFeatures, headOverlays, hair, tattoos, eyeColor

-- Apply clothing components + props only (crew / default outfit).
-- Preserves each player's face, hair, tattoos.
function ApplyOutfitToLocalPed(outfit)
    local ped = PlayerPedId()
    if outfit.components then
        exports['fivem-appearance']:setPedComponents(ped, outfit.components)
    end
    if outfit.props then
        exports['fivem-appearance']:setPedProps(ped, outfit.props)
    end
end

-- Restore normal player control — belt-and-braces after any appearance apply,
-- which can leave the ped ghosted / frozen if a model swap was involved.
local function RestoreControl()
    local ped = PlayerPedId()
    SetLocalPlayerAsGhost(false)
    SetEntityNoCollisionEntity(ped, ped, true)   -- no-op safeguard
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
    SetPlayerInvincible(PlayerId(), false)
end

-- Paint a full appearance onto an EXISTING ped, without any model swap.
--
-- `setPedAppearance` only exists in our fork of fivem-appearance; upstream
-- (1.3.0) does not export it, which threw "No such export" on every apply.
-- So: use it when present, otherwise apply the same thing piece by piece with
-- the per-part exports upstream has always shipped. Either way we never touch
-- setPlayerAppearance here — that does a SetPlayerModel swap which respawns the
-- ped at the world origin and drops the player through the map.
function PaintAppearance(ped, a)
    local fa = exports['fivem-appearance']

    local ok = pcall(function() fa:setPedAppearance(ped, a) end)
    if ok then return end

    if a.headBlend     then pcall(function() fa:setPedHeadBlend(ped, a.headBlend) end) end
    if a.faceFeatures  then pcall(function() fa:setPedFaceFeatures(ped, a.faceFeatures) end) end
    if a.headOverlays  then pcall(function() fa:setPedHeadOverlays(ped, a.headOverlays) end) end
    if a.hair          then pcall(function() fa:setPedHair(ped, a.hair) end) end
    if a.eyeColor      then pcall(function() fa:setPedEyeColor(ped, a.eyeColor) end) end
    if a.components    then pcall(function() fa:setPedComponents(ped, a.components) end) end
    if a.props         then pcall(function() fa:setPedProps(ped, a.props) end) end
    if a.tattoos       then pcall(function() fa:setPedTattoos(ped, a.tattoos) end) end
end

-- Apply full appearance including face/hair/tattoos (personal outfit).
-- Avoid setPlayerAppearance when the model already matches — that path does a
-- full SetPlayerModel swap (new ped handle) which is what left players ghosted
-- and unable to move after spawn.
function ApplyFullAppearance(appearance)
    local ped      = PlayerPedId()
    local curModel = GetEntityModel(ped)

    -- If the ped is ALREADY a freemode model (always true after spawn), paint the
    -- appearance onto the existing ped. NEVER go through setPlayerAppearance here —
    -- that calls SetPlayerModel, which respawns the ped at the world origin (0,0,0)
    -- and drops the player through the map ("spawns fine, then TPs to a random
    -- place and falls"). setPlayerModel is only needed to change the base model,
    -- which spawn already did.
    local isFreemode = curModel == GetHashKey('mp_m_freemode_01')
        or curModel == GetHashKey('mp_f_freemode_01')

    if isFreemode then
        PaintAppearance(ped, appearance)
    else
        exports['fivem-appearance']:setPlayerAppearance(appearance)
    end

    Citizen.SetTimeout(300, RestoreControl)
end

-- Capture complete current appearance via fivem-appearance.
function CaptureCurrentOutfit()
    return exports['fivem-appearance']:getPedAppearance(PlayerPedId())
end

