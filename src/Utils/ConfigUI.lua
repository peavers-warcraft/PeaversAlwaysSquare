local addonName, PAS = ...

local ConfigUI = {}
PAS.ConfigUI = ConfigUI

-- Create the options panel for this addon
function ConfigUI:InitializeOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Settings"
    
    -- Required callbacks
    panel.OnRefresh = function() end
    panel.OnCommit = function() end
    panel.OnDefault = function() end
    
    -- Add content
    local settingsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    settingsTitle:SetPoint("TOPLEFT", 16, -16)
    settingsTitle:SetText("Settings")
    
    -- Add commands section
    local commandsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    commandsTitle:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -16)
    commandsTitle:SetText("Available Commands:")
    
    local commandsList = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commandsList:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 10, -8)
    commandsList:SetJustifyH("LEFT")
    commandsList:SetText(
        "/pas - Manual check\n" ..
        "/pas icon N - Set icon (1-8)\n" ..
        "/pas debug - Toggle debug mode\n" ..
        "/pas config - Open settings"
    )
    
    return panel
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end
