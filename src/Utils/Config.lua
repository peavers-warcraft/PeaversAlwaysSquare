local addonName, PAS = ...
local Config = {}
PAS.Config = Config

-- Default settings
local defaults = {
    enabled = true,
    debugMode = false,
    iconId = 6, -- Square
    checkFrequency = 1.0,
    DEBUG_ENABLED = false
}

-- Initialize configuration
function Config:Initialize()
    -- Load saved variables
    PeaversAlwaysSquareDB = PeaversAlwaysSquareDB or {}

    -- Merge with defaults
    for k, v in pairs(defaults) do
        if PeaversAlwaysSquareDB[k] == nil then
            PeaversAlwaysSquareDB[k] = v
        end
    end

    -- Copy to the current config
    for k, v in pairs(PeaversAlwaysSquareDB) do
        self[k] = v
    end

    return self
end

-- Save configuration
function Config:Save()
    for k, v in pairs(defaults) do
        if self[k] ~= nil then
            PeaversAlwaysSquareDB[k] = self[k]
        end
    end
end

return Config
