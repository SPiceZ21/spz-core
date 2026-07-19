-- client/environment.lua
-- Personal, client-side time & weather. Affects only the local player, usable
-- by everyone (no server, no permissions). Reverts to server-synced defaults
-- when cleared.

local myWeather = nil          -- nil = follow server/default
local myHour, myMinute = nil, nil

-- ── Apply loop ────────────────────────────────────────────────────────────────
-- Personal override wins; otherwise everyone renders the server-synced
-- baseline from GlobalState (set by spz-core/server/environment_sync.lua),
-- so all clients see the same world.

-- Weather is applied ONLY when it changes. Calling SetWeatherTypeNow /
-- SetOverrideWeather on a timer restarts the weather transition on every call,
-- which reads as a flickering / pulsing sky — the classic cause of "weather
-- flickers" even with no other script involved.
local appliedWeather = nil

local function applyWeather(w)
    if not w or w == appliedWeather then return end
    appliedWeather = w
    SetWeatherTypePersist(w)
    SetWeatherTypeNowPersist(w)
    SetWeatherTypeNow(w)
    SetOverrideWeather(w)
end

-- Let an external reset (ClearOverrideWeather) re-apply next tick.
function _invalidateWeatherCache()
    appliedWeather = nil
end

-- The clock is re-asserted every frame. GTA's clock keeps ticking between
-- calls, so a 1s interval let it drift ~1 in-game minute and snap back —
-- visible as lighting/shadow flicker. One native per frame is cheap.
CreateThread(function()
    while true do
        local h, m = myHour, myMinute or 0
        if not h then
            local t = GlobalState.envTime
            if t then h, m = t.h, t.m end
        end
        if h then
            NetworkOverrideClockTime(h, m, 0)
        end
        Wait(0)
    end
end)

-- Weather only needs checking occasionally — it changes rarely.
CreateThread(function()
    while true do
        applyWeather(myWeather or GlobalState.envWeather)
        Wait(2000)
    end
end)

-- ── /weather — ox_lib dropdown ────────────────────────────────────────────────

local WEATHER_OPTIONS = {
    { value = "__reset",    label = "↺ Reset (server default)" },
    { value = "EXTRASUNNY", label = "Extra Sunny" },
    { value = "CLEAR",      label = "Clear" },
    { value = "CLOUDS",     label = "Cloudy" },
    { value = "OVERCAST",   label = "Overcast" },
    { value = "SMOG",       label = "Smog" },
    { value = "FOGGY",      label = "Foggy" },
    { value = "CLEARING",   label = "Clearing" },
    { value = "RAIN",       label = "Rain" },
    { value = "THUNDER",    label = "Thunder" },
    { value = "SNOW",       label = "Snow" },
    { value = "SNOWLIGHT",  label = "Light Snow" },
    { value = "BLIZZARD",   label = "Blizzard" },
    { value = "XMAS",       label = "Christmas" },
    { value = "HALLOWEEN",  label = "Halloween" },
    { value = "NEUTRAL",    label = "Neutral" },
}

RegisterCommand("weather", function()
    local input = lib.inputDialog("My Weather", {
        {
            type     = "select",
            label    = "Weather",
            options  = WEATHER_OPTIONS,
            default  = myWeather or "__reset",
            required = true,
        },
    })
    if not input or not input[1] then return end

    if input[1] == "__reset" then
        myWeather = nil
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        _invalidateWeatherCache()   -- let the synced default re-apply
        lib.notify({ description = "Weather reset to server default", type = "info" })
        return
    end

    myWeather = input[1]
    applyWeather()
    lib.notify({ description = "Weather → " .. myWeather, type = "success" })
end, false)

-- ── /time — args ──────────────────────────────────────────────────────────────
--   /time morning|noon|evening|night|midnight|dawn|dusk
--   /time <hour> [minute]     e.g.  /time 18 30
--   /time reset               back to server clock

local TIME_PRESETS = {
    dawn     = { 6,  0 },
    morning  = { 8,  0 },
    noon     = { 12, 0 },
    midday   = { 12, 0 },
    evening  = { 18, 0 },
    dusk     = { 20, 0 },
    night    = { 22, 0 },
    midnight = { 0,  0 },
}

RegisterCommand("time", function(_, args)
    if not args[1] then
        lib.notify({ description = "Usage: /time <morning|evening|night|...> | <hour> [min] | reset", type = "inform" })
        return
    end

    local a = args[1]:lower()

    if a == "reset" then
        myHour, myMinute = nil, nil
        NetworkClearClockTimeOverride()
        lib.notify({ description = "Time reset to server clock", type = "info" })
        return
    end

    local preset = TIME_PRESETS[a]
    if preset then
        myHour, myMinute = preset[1], preset[2]
    else
        local hour = tonumber(args[1])
        if not hour then
            lib.notify({ description = "Unknown time. Try: morning, noon, evening, night, or 0-23", type = "error" })
            return
        end
        myHour   = math.floor(hour) % 24
        myMinute = (math.floor(tonumber(args[2]) or 0)) % 60
    end

    NetworkOverrideClockTime(myHour, myMinute, 0)
    lib.notify({ description = ("Time → %02d:%02d"):format(myHour, myMinute), type = "success" })
end, false)
