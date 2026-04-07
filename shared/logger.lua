SPZ = SPZ or {}

-- 8.1 Log Levels
local LevelWeights = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4
}

-- Minimum level (should ideally integrate directly with config, defaulting to INFO)
local MinLevel = "INFO" 

-- Formatting colors for console
local Colors = {
    DEBUG = "^5", -- Light Blue
    INFO  = "^2", -- Green
    WARN  = "^3", -- Yellow
    ERROR = "^1"  -- Red
}

-- Master internal log sink
function SPZ.Log(level, module, message, ...)
    -- Filter out if the current level weight is lower than minimum configured weight
    -- Exceptions: if _G.DebugMode is enabled globally, we force DEBUG logs out
    if LevelWeights[level] < LevelWeights[MinLevel] and not (level == "DEBUG" and _G.DebugMode) then
        return
    end

    local color = Colors[level] or "^0"
    local formattedMsg = string.format(...) and string.format(message, ...) or message
    local outStr = string.format("%s[%s] [%s]: %s^0", color, module, level, formattedMsg)
    
    print(outStr)
end

-- 8.2 Module Logger Factory
function SPZ.Logger(moduleName)
    return {
        debug = function(msg, ...) SPZ.Log("DEBUG", moduleName, msg, ...) end,
        info  = function(msg, ...) SPZ.Log("INFO",  moduleName, msg, ...) end,
        warn  = function(msg, ...) SPZ.Log("WARN",  moduleName, msg, ...) end,
        error = function(msg, ...) SPZ.Log("ERROR", moduleName, msg, ...) end
    }
end

-- Set up the core's default logger
SPZ.CoreLogger = SPZ.Logger("spz-core")
