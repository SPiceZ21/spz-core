-- server/environment_sync.lua
-- Server-authoritative time & weather baseline, published via GlobalState.
-- Every client renders the same world unless they set a personal /time or
-- /weather override (client/environment.lua — personal always wins locally).

local env = Config.Environment or {}

GlobalState:set("envWeather", env.weather or "EXTRASUNNY", true)
GlobalState:set("envTime", { h = env.hour or 19, m = env.minute or 30 }, true)

-- ── Admin control (ACE: command.syncweather / command.synctime) ──────────────

RegisterCommand("syncweather", function(source, args)
    local w = args[1] and args[1]:upper()
    if not w then return end
    GlobalState:set("envWeather", w, true)
    print(("[spz-core] Synced weather set to %s"):format(w))
end, true)

RegisterCommand("synctime", function(source, args)
    local h, m = tonumber(args[1]), tonumber(args[2]) or 0
    if not h or h < 0 or h > 23 then return end
    GlobalState:set("envTime", { h = math.floor(h), m = math.floor(m) % 60 }, true)
    print(("[spz-core] Synced time set to %02d:%02d"):format(h, m))
end, true)

-- ── Exports (e.g. future per-track weather from spz-races) ───────────────────

exports("SetSyncedWeather", function(w)
    if type(w) == "string" then GlobalState:set("envWeather", w:upper(), true) end
end)

exports("SetSyncedTime", function(h, m)
    h, m = tonumber(h), tonumber(m) or 0
    if h then GlobalState:set("envTime", { h = math.floor(h) % 24, m = math.floor(m) % 60 }, true) end
end)
