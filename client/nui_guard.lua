-- client/nui_guard.lua
-- Whenever ANY resource holds NUI focus (a menu open with SetNuiFocus), GTA still
-- processes the weapon-wheel and radio-wheel controls, so their blurred overlays
-- render behind the menu. Suppress them globally here — one guard covers every
-- SPiceZ NUI (crew, betting, spectate, appearance, …) instead of each fixing it.

CreateThread(function()
    while true do
        if IsNuiFocused() then
            BlockWeaponWheelThisFrame()
            HudWeaponWheelIgnoreSelection()
            DisableControlAction(0, 37, true)  -- INPUT_SELECT_WEAPON (weapon wheel)
            DisableControlAction(0, 85, true)  -- INPUT_VEH_RADIO_WHEEL (radio wheel)
            Wait(0)
        else
            Wait(250)
        end
    end
end)
