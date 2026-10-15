-- server/environment_sync.lua
-- Server-authoritative time & weather baseline, published via GlobalState.
-- Every client renders the same world unless they set a personal /time or
-- /weather override (client/environment.lua — personal always wins locally).

local env = Config.Environment or {}

GlobalState:set("envWeather", env.weather or "EXTRASUNNY", true)
GlobalState:set("envTime", { h = env.hour or 19, m = env.minute or 30 }, true)

-- ── Dynamic clock ────────────────────────────────────────────────────────────
-- The server advances the time and publishes it once per game minute.
-- envTimeRate (real seconds per game minute, 0 = frozen) lets clients fill in
-- the seconds in between, so the sun moves smoothly rather than in steps.
local frozen = env.dynamic == false
local rate = tonumber(env.minuteSeconds) or 2.0

local function publishRate()
    GlobalState:set("envTimeRate", frozen and 0 or rate, true)
end
publishRate()

CreateThread(function()
    while true do
        Wait(math.floor(rate * 1000))
        if not frozen then
            local t = GlobalState.envTime or { h = 12, m = 0 }
            local m = (t.m or 0) + 1
            local h = t.h or 12
            if m >= 60 then m = 0; h = (h + 1) % 24 end
            GlobalState:set("envTime", { h = h, m = m }, true)
        end
    end
end)

RegisterCommand("freezetime", function(source, args)
    if args[1] == "on" then frozen = true
    elseif args[1] == "off" then frozen = false
    else frozen = not frozen end
    publishRate()
    print(("[spz-core] Synced clock %s"):format(frozen and "frozen" or "running"))
end, true)

-- ── Admin control (ACE: command.syncweather / command.synctime / command.freezetime)

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
