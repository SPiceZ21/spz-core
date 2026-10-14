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
