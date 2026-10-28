-- client/keys.lua — live key labels for key hints.
--
-- Every SPiceZ key is a RegisterKeyMapping command, and players can rebind
-- them in Settings → Key Bindings → FiveM. Hints used to print the DEFAULT
-- key, so after a rebind the HUD lied. GTA can report the key currently bound
-- to a mapped command (the same call ox_lib's keybinds use), so:
--
--   exports["spz-core"]:KeyFor("+cr_jump", "E")      --> "E", or the player's rebind
--   exports["spz-core"]:KeyFor("spz_flip_car", "K")  --> commands without +/- work too
--   exports["spz-core"]:KeyForControl(22, "SPACE")   --> a plain GTA control id
--
-- CONTROLLER: pass the gamepad button as a third argument (the same name used
-- in RegisterKeyMapping(cmd, desc, "PAD_DIGITALBUTTON", "<button>")):
--
--   exports["spz-core"]:KeyFor("+cr_jump", "E", "L1_INDEX")   --> "E" or "LB"
--
-- While the player is using a gamepad (IsUsingKeyboard false) the controller
-- label is returned, so every hint switches the moment they pick up a pad.
-- exports["spz-core"]:PadLabel("RDOWN_INDEX") --> "A" for your own UIs, and
-- exports["spz-core"]:UsingPad() tells you which one is active.
--
-- The default is returned when the key can't be read (not registered yet, or a
-- special key GTA only reports as an icon we don't have a name for), so a hint
-- is never blank and never wrong. Results are cached for 1 s — cheap to call
-- every frame from a HUD loop, and a rebind still shows up almost at once.

-- GTA reports most keys as text ("t_E", "t_F6", "t_PAGEUP") and a few as an
-- icon id ("b_2000"). Only icon ids we are sure of are named here.
local ICON = {
    ["2000"] = "SPACE",
}

local PRETTY = {
    RETURN = "ENTER", BACK = "BKSP", ESCAPE = "ESC", DELETE = "DEL", INSERT = "INS",
    PAGEUP = "PG UP", PAGEDOWN = "PG DN", LCONTROL = "CTRL", RCONTROL = "CTRL",
    LSHIFT = "SHIFT", RSHIFT = "SHIFT", LMENU = "ALT", RMENU = "ALT",
    UP = "↑", DOWN = "↓", LEFT = "←", RIGHT = "→", EQUALS = "=", MINUS = "-",
    CAPITAL = "CAPS", NUMPADENTER = "NUM ENTER",
}

local function label(raw, default)
    if type(raw) ~= "string" or #raw < 3 then return default end
    local kind, rest = raw:sub(1, 2), raw:sub(3)
    if kind == "t_" and rest ~= "" then
        return PRETTY[rest:upper()] or rest:upper()
    elseif kind == "b_" then
        return ICON[rest] or default
    end
    return default
end

-- Gamepad buttons (RegisterKeyMapping "PAD_DIGITALBUTTON" names) -> Xbox
-- labels, the layout GTA itself prompts with.
local PAD = {
    -- Face buttons carry a "PAD " prefix so a UI never mistakes them for the
    -- keyboard letters A / B / X / Y (KeyGlyph draws only "PAD x" as a pad button).
    RDOWN_INDEX = "PAD A", RRIGHT_INDEX = "PAD B", RLEFT_INDEX = "PAD X", RUP_INDEX = "PAD Y",
    L1_INDEX = "LB", R1_INDEX = "RB", L2_INDEX = "LT", R2_INDEX = "RT",
    L3_INDEX = "LS", R3_INDEX = "RS",
    LUP_INDEX = "D-PAD ↑", LDOWN_INDEX = "D-PAD ↓", LLEFT_INDEX = "D-PAD ←", LRIGHT_INDEX = "D-PAD →",
    START_INDEX = "MENU", SELECT_INDEX = "VIEW",
}
local function PadLabel(button) return PAD[button] or button end
local function UsingPad() return not IsUsingKeyboard(0) end

local cache = {}   -- [key] = { value, at }

-- A key-mapped command's control hash: joaat(name) with the top bit set, as an
-- unsigned 32-bit value (GetHashKey returns it signed).
local function mappingHash(name)
    return (GetHashKey(name) | 0x80000000) & 0xFFFFFFFF
end

local function cached(key, compute)
    local c, now = cache[key], GetGameTimer()
    if c and now - c.at < 1000 then return c.value end
    local v = compute()
    cache[key] = { value = v, at = now }
    return v
end

local function KeyFor(command, default, pad)
    default = default or "?"
    if pad and UsingPad() then return PadLabel(pad) end
    if type(command) ~= "string" or command == "" then return default end
    return cached("c:" .. command, function()
        -- The command as given first, then its +/- twin: a hint may name either
        -- half of a +cmd / -cmd pair, but only the one RegisterKeyMapping was
        -- given has a binding. Group 0 first, then FRONTEND (2) as a fallback.
        local names = { command }
        if command:sub(1, 1) == "+" or command:sub(1, 1) == "-" then
            names[2] = "+" .. command:sub(2)
        else
            names[2] = "+" .. command
        end
        for _, name in ipairs(names) do
            for _, group in ipairs({ 0, 2 }) do
                local ok, raw = pcall(GetControlInstructionalButton, group, mappingHash(name), true)
                local l = ok and label(raw, nil)
                if l then return l end
            end
        end
        return default
    end)
end

local function KeyForControl(control, default, pad)
    default = default or "?"
    if pad and UsingPad() then return PadLabel(pad) end
    return cached("k:" .. tostring(control), function()
        local ok, raw = pcall(GetControlInstructionalButton, 0, tonumber(control) or 0, true)
        return ok and label(raw, default) or default
    end)
end

-- /keydebug <command> — what GTA reports for a command's binding.
RegisterCommand("keydebug", function(_, args)
    local cmd = args[1]
    if not cmd then print("usage: /keydebug <command>") return end
    for _, name in ipairs({ cmd, "+" .. cmd:gsub("^[+-]", "") }) do
        for _, group in ipairs({ 0, 2 }) do
            local ok, raw = pcall(GetControlInstructionalButton, group, mappingHash(name), true)
            print(("[keys] %s group %d -> %s"):format(name, group, ok and tostring(raw) or "error"))
        end
    end
    cache["c:" .. cmd] = nil
    print(("[keys] KeyFor(%s) = %s, using pad: %s"):format(cmd, KeyFor(cmd, "?"), tostring(UsingPad())))
end, false)

exports("KeyFor", KeyFor)
exports("KeyForControl", KeyForControl)
exports("PadLabel", PadLabel)
exports("UsingPad", UsingPad)
