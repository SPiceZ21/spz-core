-- client/theme_sync.lua — Caches the server-pushed theme and re-broadcasts
-- it locally so any resource's NUI can pick it up without a direct export
-- call. Client-side TriggerEvent/AddEventHandler are global across all
-- resources on this client, so 'SPZ:themeUpdated' reaches every listener.

local LocalTheme = {}

RegisterNetEvent("SPZ:theme", function(theme)
    LocalTheme = theme or {}
    TriggerEvent("SPZ:themeUpdated", LocalTheme)
end)

exports("GetTheme", function() return LocalTheme end)

-- The server's push on (re)start can land before this script is listening
-- (restart spz-core, or a slow join), leaving every UI on default colours.
-- Ask for it ourselves until it arrives.
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(250) end
    for _ = 1, 10 do
        if next(LocalTheme) then return end
        TriggerServerEvent("SPZ:requestTheme")
        Wait(3000)
    end
end)

-- ── Re-broadcast so no UI is ever left on its default colours ────────────────
-- A NUI page only receives SendNUIMessage once it has LOADED. Every SPiceZ UI
-- forwards 'SPZ:themeUpdated' to its page, but a single broadcast usually lands
-- before some pages finish loading (a fresh join, a resource restart), so they
-- stayed orange. Applying a theme is idempotent and cheap, so it is simply
-- re-broadcast at the moments a page could have missed it:
--   * a few seconds after ANY resource starts (its page has loaded by then)
--   * every 15 s for the first 2 minutes after joining, then every 60 s
local function rebroadcast()
    if next(LocalTheme) then TriggerEvent("SPZ:themeUpdated", LocalTheme) end
end

AddEventHandler("onClientResourceStart", function()
    for _, ms in ipairs({ 2000, 5000, 10000 }) do SetTimeout(ms, rebroadcast) end
end)

CreateThread(function()
    local started = GetGameTimer()
    while true do
        Wait(GetGameTimer() - started < 120000 and 15000 or 60000)
        rebroadcast()
    end
end)
