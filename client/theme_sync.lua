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
