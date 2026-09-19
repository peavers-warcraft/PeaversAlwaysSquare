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
    showButton = true,
    secureNoticeShown = false,
    DEBUG_ENABLED = false,
    -- The marker button: below centre, clear of the character and the cast bar
    framePoint = "CENTER",
    frameX = 0,
    frameY = -180,
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
