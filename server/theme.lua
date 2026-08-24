-- server/theme.lua — Base UI theme, set from server.cfg convars.
-- Same pattern as spz_discord_token: `set spz_theme_accent "#ff6200"` in
-- server.cfg, no resource restart needed — /spz reloadtheme re-reads the
-- convars and re-pushes to every connected client. Every SPiceZ NUI reads
-- this via exports("spz-core", "GetTheme") and applies it as CSS variables
-- at runtime, so one config line re-skins every UI at once.

local DEFAULTS = {
    accent  = '#ff6200',   -- primary brand accent
    accent2 = '#ff9142',   -- lighter accent (hover/secondary emphasis)
    bg      = '#060608',   -- base background
    bg2     = '#0a0b0f',   -- secondary background (cards/panels)
    danger  = '#ff4d5e',   -- errors, destructive actions
    gold    = '#f59e0b',   -- highlights, system/warning text
}

local function loadTheme()
    local theme = {}
    for key, default in pairs(DEFAULTS) do
        local v = GetConvar('spz_theme_' .. key, default)
        theme[key] = (v ~= '') and v or default   -- `set spz_theme_x ""` = unset, keep default
    end
    return theme
end

local ActiveTheme = loadTheme()

local function broadcastTheme(target)
    TriggerClientEvent('SPZ:theme', target or -1, ActiveTheme)
end

exports('GetTheme', function() return ActiveTheme end)

exports('ReloadTheme', function()
    ActiveTheme = loadTheme()
    broadcastTheme(-1)
    return ActiveTheme
end)

-- Send to newly connecting clients.
AddEventHandler('SPZ:playerConnected', function(source)
    broadcastTheme(source)
end)

-- Re-read the convars and push to everyone ALREADY connected whenever this
-- resource (re)starts — covers a full server restart and a bare
-- `restart spz-core` alike, no manual /spz reloadtheme needed either way.
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    ActiveTheme = loadTheme()
    broadcastTheme(-1)
end)
