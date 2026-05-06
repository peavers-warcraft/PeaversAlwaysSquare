--------------------------------------------------------------------------------
-- PeaversAlwaysSquare Configuration
-- Uses PeaversCommons.ConfigManager with AceDB-3.0 for profile management
--------------------------------------------------------------------------------

local addonName, PAS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

local PAS_DEFAULTS = {
    enabled = true,
    debugMode = false,
    iconId = 6,
    checkFrequency = 1.0,
    DEBUG_ENABLED = false,
}

-- Create the AceDB-backed config
PAS.Config = ConfigManager:NewWithAceDB(
    PAS,
    PAS_DEFAULTS,
    {
        savedVariablesName = "PeaversAlwaysSquareDB",
        profileType = "shared",
    }
)

return PAS.Config
