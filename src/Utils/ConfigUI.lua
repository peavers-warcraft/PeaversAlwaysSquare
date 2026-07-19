local addonName, PAS = ...

local ConfigUI = {}
PAS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found.")
    return
end

local W = PeaversCommons.Widgets

local function ResolveWidth(parentFrame, indent)
    local parentWidth = parentFrame:GetWidth() or 0
    if parentWidth > 100 then
        return parentWidth - (indent * 2) - 10
    end
    return 360
end

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10
    local indent = 25
    local width = ResolveWidth(parentFrame, indent)

    local _, newY = W:CreateSectionHeader(parentFrame, "General Settings", indent, y)
    y = newY - 8

    local toggle = W:CreateCheckbox(parentFrame, "Enable automatic tank marking", {
        checked = PAS.Config.enabled ~= false,
        width = width,
        onChange = function(checked)
            PAS.Config.enabled = checked
            PAS.Config:Save()
        end,
    })
    toggle:SetPoint("TOPLEFT", indent, y)
    y = y - 30

    _, newY = W:CreateSectionHeader(parentFrame, "Marker Settings", indent, y)
    y = newY - 8

    local iconOptions = {
        { value = 1, label = "Star" },
        { value = 2, label = "Circle" },
        { value = 3, label = "Diamond" },
        { value = 4, label = "Triangle" },
        { value = 5, label = "Moon" },
        { value = 6, label = "Square" },
        { value = 7, label = "Cross" },
        { value = 8, label = "Skull" },
    }

    local iconDropdown = W:CreateDropdown(parentFrame, "Target Marker Icon", {
        options = iconOptions,
        selected = PAS.Config.iconId or 6,
        width = width,
        onChange = function(value)
            PAS.Config.iconId = value
            PAS.Config:Save()
        end,
    })
    iconDropdown:SetPoint("TOPLEFT", indent, y)
    y = y - 58

    local freqSlider = W:CreateSlider(parentFrame, "Check Frequency (seconds)", {
        min = 0.5, max = 5.0, step = 0.5,
        value = PAS.Config.checkFrequency or 1.0,
        width = width,
        onChange = function(value)
            PAS.Config.checkFrequency = value
            PAS.Config:Save()
        end,
    })
    freqSlider:SetPoint("TOPLEFT", indent, y)
    y = y - 52

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Always Square", {
        "Automatically marks the tank in your party or raid with a raid target " ..
            "icon - the square by default - and keeps it there.",
        { command = "/pas", desc = "force a re-mark of all tanks right now" },
        { command = "/pas icon N", desc = "use a different icon (1-8)" },

        { header = "How marking works" },
        "The addon watches role assignments, so anyone flagged as a tank gets " ..
            "the icon as soon as they join or swap roles. If someone else " ..
            "changes or removes the mark mid-run, it is quietly reapplied.",
        "Marking requires the usual game permissions: in a raid you need to be " ..
            "leader or assistant. In five-player groups anyone can mark, so it " ..
            "just works in Mythic+.",
    })
end

function ConfigUI:GetPages()
    return {
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildGeneralPage(parentFrame)
    return parentFrame
end

function ConfigUI:OpenOptions()
    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversAlwaysSquare")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PAS.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PAS.directSettingsCategoryID)
            if success then return end
        end
        if PAS.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PAS.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        SettingsPanel:Open()
    end
end

function ConfigUI:Initialize()
end

return ConfigUI
