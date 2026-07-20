-- client/fade.lua
-- Common screen-fade helpers. Every teleport in the framework goes through
-- these so the player never sees the world snap — fade to black, move, fade
-- back in.
--
-- Exported so any module can use the same timing and never fight another
-- module's fade:
--     exports["spz-core"]:FadeOut(400)        -- blocks until fully black
--     exports["spz-core"]:FadeIn(600)         -- blocks until fully visible
--     exports["spz-core"]:FadeHold()          -- is the screen black right now?

local DEFAULT_OUT = 400
local DEFAULT_IN  = 600

-- Guards against overlapping fades: a second FadeOut while one is running
-- must not fade back in halfway through the first one's teleport.
local fadeDepth = 0

local function FadeOut(ms)
    ms = ms or DEFAULT_OUT
    fadeDepth = fadeDepth + 1

    if not IsScreenFadedOut() then
        DoScreenFadeOut(ms)
        local deadline = GetGameTimer() + ms + 500   -- hard ceiling
        while not IsScreenFadedOut() and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

local function FadeIn(ms)
    ms = ms or DEFAULT_IN

    fadeDepth = math.max(0, fadeDepth - 1)
    if fadeDepth > 0 then return end   -- another transition still holding

    if not IsScreenFadedIn() then
        DoScreenFadeIn(ms)
        local deadline = GetGameTimer() + ms + 500
        while not IsScreenFadedIn() and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

-- Fade out, run `fn`, fade back in. `fn` may yield.
local function FadeTransition(fn, outMs, holdMs, inMs)
    FadeOut(outMs)
    if fn then pcall(fn) end
    if holdMs and holdMs > 0 then Wait(holdMs) end
    FadeIn(inMs)
end

exports("FadeOut", FadeOut)
exports("FadeIn", FadeIn)
exports("FadeTransition", FadeTransition)
exports("FadeHold", function() return IsScreenFadedOut() end)

-- Safety net: never leave a player stuck on a black screen if a transition
-- errored out or the resource restarted mid-fade.
CreateThread(function()
    local blackSince = nil
    while true do
        Wait(1000)
        if IsScreenFadedOut() then
            blackSince = blackSince or GetGameTimer()
            if GetGameTimer() - blackSince > 15000 then
                print("[spz-core] Screen stuck black for 15s — forcing fade in.")
                fadeDepth = 0
                DoScreenFadeIn(500)
                blackSince = nil
            end
        else
            blackSince = nil
        end
    end
end)
