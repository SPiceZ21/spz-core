-- spz-core/client/radial.lua
--
-- Quick-access radial menu (default key: Z, remappable via FiveM keybinds).
--
-- One entry point for everything a player does between races: join/leave, time
-- trial, minigames, vehicle spawn/delete/tune, appearance, leaderboard, crew.
-- Before this, each of those lived behind a command the player had to remember
-- and type — /joinrace, /quittt, /customs, /raceresults, /crewradio. The command
-- is still the canonical entry point; this is a discoverable surface on top of
-- it, and it deliberately drives the SAME commands rather than reaching into
-- each resource's internals, so nothing here can drift out of sync with the
-- resource that owns the behaviour.
--
-- Two rules the menu enforces:
--
--  1. An option only exists if the resource that answers it is actually
--     running. A dead option that fails silently is worse than no option.
--  2. An option only exists if it is valid RIGHT NOW. "Join Race" and "Leave
--     Race" are the same slot; you never see both, and you never see the one
--     you cannot use.
--
-- Rule 2 means the menu has to be rebuilt when race state changes. That is
-- driven by statebag handlers and the time-trial begin/end events — no polling.

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function Has(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

-- Commands registered on the SERVER (joinrace, timetrail, car, dv, ...) are
-- reached the same way typing them in chat would: the client command context
-- forwards anything it cannot resolve locally. Client commands (fix, tune,
-- appearance, ...) resolve locally and never leave the client.
local function Run(command)
    return function() ExecuteCommand(command) end
end

local function Confirm(header, content, command)
    return function()
        local ok = lib.alertDialog({
            header      = header,
            content     = content,
            centered    = true,
            cancel      = true,
            labels      = { confirm = 'Confirm', cancel = 'Cancel' },
        })
        if ok == 'confirm' then ExecuteCommand(command) end
    end
end

-- ── Live state ────────────────────────────────────────────────────────────────

local function InRace()  return LocalPlayer.state.inRace == true end
local function InQueue() return LocalPlayer.state.inQueue == true end

-- spz-races only exposes time-trial state through this export; it returns the
-- current checkpoint index while a trial is running and nil otherwise.
local function InTimeTrial()
    if not Has('spz-races') then return false end
    local ok, idx = pcall(function() return exports['spz-races']:GetTTCpIndex() end)
    return ok and idx ~= nil
end

-- ── Submenu builders ──────────────────────────────────────────────────────────
--
-- Each returns an item array. They are rebuilt in full rather than patched:
-- these are six-item lists, and a rebuild that cannot leave a stale entry
-- behind is worth more than the handful of table allocations it costs.

local function RaceItems()
    local items = {}
    local racing, queued, trial = InRace(), InQueue(), InTimeTrial()

    if not Has('spz-races') then return items end

    -- Join / leave occupy one slot. Leaving a race in progress forfeits it, so
    -- that one asks first; leaving a queue costs nothing, so it does not.
    if racing then
        items[#items + 1] = {
            id = 'race_leave', icon = 'right-from-bracket', label = 'Leave Race',
            onSelect = Confirm('Leave Race', 'You will forfeit this race. Continue?', 'leaverace'),
        }
    elseif queued then
        items[#items + 1] = {
            id = 'race_unqueue', icon = 'right-from-bracket', label = 'Leave Queue',
            onSelect = Run('leaverace'),
        }
    else
        items[#items + 1] = {
            id = 'race_join', icon = 'flag-checkered', label = 'Join Race',
            onSelect = Run('joinrace'),
        }
    end

    if trial then
        items[#items + 1] = {
            id = 'tt_restart', icon = 'rotate-left', label = 'Restart Lap',
            onSelect = Run('tt_restart'),
        }
        items[#items + 1] = {
            id = 'tt_quit', icon = 'stopwatch', label = 'Quit Time Trial',
            onSelect = Run('quittt'),
        }
    elseif not racing and not queued then
        items[#items + 1] = {
            id = 'tt_start', icon = 'stopwatch', label = 'Time Trial',
            onSelect = Run('timetrail'),
        }
    end

    -- Recovery and the standings list only mean anything while driving a route.
    if racing or trial then
        items[#items + 1] = {
            id = 'race_cp', icon = 'location-crosshairs', label = 'Last Checkpoint',
            onSelect = Run('spz_respawn_cp'),
        }
        items[#items + 1] = {
            id = 'race_flip', icon = 'car-burst', label = 'Flip Car',
            onSelect = Run('spz_flip_car'),
        }
        if Has('spz-raceUI') then
            items[#items + 1] = {
                id = 'race_standings', icon = 'list-ol', label = 'Standings',
                onSelect = Run('standingstoggle'),
            }
        end
    end

    -- Raceline is a driving aid, not a minigame, and it is not a toggle: it owns
    -- a ring of its own (line, ghost, ghost mode, settings) registered by
    -- spz-raceline/client/panel.lua as `spz_rl_radial`.
    --
    -- It has to be pointed at from HERE. Rebuild() below calls
    -- lib.clearRadialItems(), which drops every ROOT item in ox_lib — including
    -- the one spz-raceline adds for itself — so a resource that adds its own
    -- root entry loses it the next time race state changes. Submenus registered
    -- with lib.registerRadial survive; only root items are cleared. So the
    -- submenu stays theirs and the root entry lives in this list.
    if Has('spz-raceline') then
        items[#items + 1] = {
            id = 'race_raceline', icon = 'route', label = 'Raceline',
            menu = 'spz_rl_radial',
        }
    end

    if Has('spz-spectate') then
        if not racing and not trial then
            items[#items + 1] = {
                id = 'race_spectate', icon = 'eye', label = 'Spectate',
                onSelect = Run('spectate'),
            }
        end
        items[#items + 1] = {
            id = 'race_board', icon = 'table-list', label = 'Race Board',
            onSelect = Run('raceboard'),
        }
    end

    return items
end

local function MinigameItems()
    local items = {}

    if Has('spz-hideseek') then
        items[#items + 1] = {
            id = 'mg_hideseek', icon = 'user-secret', label = 'Hide & Seek',
            onSelect = Run('hideseekmenu'),
        }
    end

    if Has('spz-pursuit') then
        items[#items + 1] = {
            id = 'mg_pursuit', icon = 'car-on', label = 'Pursuit',
            onSelect = Run('pursuitmenu'),
        }
    end

    -- A duel needs a target, and the command takes it as an argument. Asking
    -- here keeps the player out of the chat box.
    if Has('spz-races') then
        items[#items + 1] = {
            id = 'mg_duel', icon = 'user-group', label = 'Duel Player',
            onSelect = function()
                local input = lib.inputDialog('Duel', {
                    { type = 'number', label = 'Player ID', required = true, min = 1 },
                })
                if not input or not input[1] then return end
                ExecuteCommand(('duel %d'):format(math.floor(input[1])))
            end,
        }
    end

    return items
end

local function VehicleItems()
    local items = {}
    local busy = InRace() or InTimeTrial()

    if Has('spz-carspawner') then
        -- Spawning or deleting mid-race would desync the racer from the field,
        -- so both drop out of the menu while a route is running.
        if not busy then
            items[#items + 1] = {
                id = 'veh_spawn', icon = 'car-side', label = 'Spawn Vehicle',
                onSelect = Run('car'),
            }
            items[#items + 1] = {
                id = 'veh_delete', icon = 'trash', label = 'Delete Vehicle',
                onSelect = Confirm('Delete Vehicle', 'Despawn your current vehicle?', 'dv'),
            }
        end
    end

    items[#items + 1] = {
        id = 'veh_fix', icon = 'wrench', label = 'Repair',
        onSelect = Run('fix'),
    }

    if Has('spz-tunners') and not busy then
        items[#items + 1] = {
            id = 'veh_tune', icon = 'gauge-high', label = 'Tune',
            onSelect = Run('tune'),
        }
        items[#items + 1] = {
            id = 'veh_customs', icon = 'paint-roller', label = 'Customs',
            onSelect = Run('customs'),
        }
    end

    if Has('spz-vehicles') and not busy then
        items[#items + 1] = {
            id = 'veh_save', icon = 'floppy-disk', label = 'Save Build',
            onSelect = Run('savecustom'),
        }
    end

    if Has('spz-vehfunc') then
        items[#items + 1] = {
            id = 'veh_idlecam', icon = 'video', label = 'Idle Cam',
            onSelect = Run('idlecam'),
        }
    end

    return items
end

local function AppearanceItems()
    if not Has('spz-appearance') then return {} end

    return {
        { id = 'app_edit',  icon = 'shirt',        label = 'Character',    onSelect = Run('appearance') },
        { id = 'app_save',  icon = 'floppy-disk',  label = 'Save Outfit',  onSelect = Run('saveoutfit') },
        { id = 'app_reset', icon = 'rotate-left',  label = 'Reset Outfit', onSelect = Run('resetoutfit') },
    }
end

local function LeaderboardItems()
    if not Has('spz-leaderboard') then return {} end

    return {
        { id = 'lb_open',    icon = 'ranking-star', label = 'Leaderboard',  onSelect = Run('leaderboard') },
        { id = 'lb_results', icon = 'trophy',       label = 'Last Results', onSelect = Run('raceresults') },
    }
end

local function CrewItems()
    if not Has('spz-crew') then return {} end

    return {
        { id = 'crew_dash',  icon = 'users',   label = 'Crew Dashboard', onSelect = Run('crew') },
        { id = 'crew_radio', icon = 'headset', label = 'Crew Radio',     onSelect = Run('crewradio') },
    }
end

-- ── Assembly ──────────────────────────────────────────────────────────────────

local SUBMENUS = {
    { id = 'spz_race',        icon = 'flag-checkered', label = 'Racing',      build = RaceItems },
    { id = 'spz_minigames',   icon = 'gamepad',        label = 'Minigames',   build = MinigameItems },
    { id = 'spz_vehicle',     icon = 'car',            label = 'Vehicle',     build = VehicleItems },
    { id = 'spz_appearance',  icon = 'user-pen',       label = 'Appearance',  build = AppearanceItems },
    { id = 'spz_leaderboard', icon = 'ranking-star',   label = 'Leaderboard', build = LeaderboardItems },
    { id = 'spz_crew',        icon = 'users',          label = 'Crew',        build = CrewItems },
}

local function Rebuild()
    local root = {}

    for i = 1, #SUBMENUS do
        local def   = SUBMENUS[i]
        local items = def.build()

        -- registerRadial refreshes the menu in place if the player happens to
        -- have it open, which is what makes "Join Race" flip to "Leave Race"
        -- under the cursor the moment the race starts.
        lib.registerRadial({ id = def.id, items = items })

        -- An empty category is a dead end. Drop it from the root rather than
        -- letting the player open a ring with nothing in it.
        if #items > 0 then
            root[#root + 1] = { id = def.id, icon = def.icon, label = def.label, menu = def.id }
        end
    end

    lib.clearRadialItems()
    if #root > 0 then lib.addRadialItem(root) end
end

-- ── Triggers ──────────────────────────────────────────────────────────────────
--
-- Every event that can invalidate rule 2 above. The Wait(0) defers the rebuild
-- past the handler so the state that fired it has actually landed.

local function Schedule()
    CreateThread(function()
        Wait(0)
        Rebuild()
    end)
end

for _, key in ipairs({ 'inRace', 'inQueue', 'pendingRace' }) do
    AddStateBagChangeHandler(key, ('player:%s'):format(GetPlayerServerId(PlayerId())), Schedule)
end

RegisterNetEvent('SPZ:tt:Begin', Schedule)
RegisterNetEvent('SPZ:tt:End', Schedule)

-- Resources coming up after this one change which options are valid.
AddEventHandler('onClientResourceStart', function(resource)
    if resource:find('^spz%-') then Schedule() end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource:find('^spz%-') then Schedule() end
end)

CreateThread(function()
    -- Give the other spz resources a moment to register before deciding which
    -- of them exist; GetResourceState is only meaningful once they are up.
    Wait(2000)
    Rebuild()
end)

-- ── Manual entry point ────────────────────────────────────────────────────────
-- The keybind lives in ox_lib (default Z). This is for players who would rather
-- type it, and for other resources that want to open the menu.

RegisterCommand('menu', function()
    Rebuild()
    -- No argument opens the GLOBAL ring (the six categories), not a submenu.
    lib.showRadialMenu()
end, false)

exports('RefreshRadial', Rebuild)
