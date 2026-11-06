-- client/fade.lua
-- Common screen-fade helpers. Every teleport in the framework goes through
-- these so the player never sees the world snap — fade to black, move, fade
-- back in.
--
-- Exported so any module can use the same timing and never fight another
-- module's fade:
--     exports["spz-core"]:FadeOut(400)        -- blocks until fully black
--     exports["spz-core"]:FadeOut(400, "Heading back")   -- with a status line
--     exports["spz-core"]:FadeIn(600)         -- blocks until fully visible
--     exports["spz-core"]:FadeHold()          -- is the screen black right now?
--
-- With spz-hud running, "black" is the SPiceZ transition cover (the spawn
-- screen's slice wipe) instead of GTA's plain fade: the cover closes, the game
-- fades to black underneath it (so IsScreenFadedOut stays true for everyone
-- that checks it), and on FadeIn the game comes back and the cover sweeps open.

local DEFAULT_OUT = 400
local DEFAULT_IN  = 600

-- Guards against overlapping fades: a second FadeOut while one is running
-- must not fade back in halfway through the first one's teleport.
local fadeDepth = 0
local COVER = 'spz-core:fade'

local function hud()
    return GetResourceState('spz-hud') == 'started'
end

local function FadeOut(ms, status)
    ms = ms or DEFAULT_OUT
    fadeDepth = fadeDepth + 1

    if hud() then
        local ok = pcall(function() exports['spz-hud']:CoverShowWait(COVER, status or 'Loading') end)
        if ok then
            if not IsScreenFadedOut() then DoScreenFadeOut(0) end
            return
        end
    end

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

    local okCov, covered = false, false
    if hud() then okCov, covered = pcall(function() return exports['spz-hud']:IsCovered() end) end
    if okCov and covered then
        DoScreenFadeIn(0)
        pcall(function() exports['spz-hud']:CoverHide(COVER) end)
        Wait(250)   -- the sweep carries on by itself; the world is already visible behind it
        return
    end

    if not IsScreenFadedIn() then
        DoScreenFadeIn(ms)
        local deadline = GetGameTimer() + ms + 500
        while not IsScreenFadedIn() and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

-- Fade out, run `fn`, fade back in. `fn` may yield.
local function FadeTransition(fn, outMs, holdMs, inMs, status)
    FadeOut(outMs, status)
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
                if hud() then pcall(function() exports['spz-hud']:CoverHide(COVER) end) end
                blackSince = nil
            end
        else
            blackSince = nil
        end
    end
end)
