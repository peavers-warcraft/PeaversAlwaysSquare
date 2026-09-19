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

    -- Each control anchors itself and hands back where the next one goes, so
    -- this page no longer has to know how tall a checkbox, a dropdown or a
    -- slider happens to be. The numbers that used to live here - 30, 58, 52 -
    -- were a copy of Widgets' metrics kept by hand, and they drifted: the same
    -- 22px checkbox was advanced past by seven different values across the
    -- collection.
    _, y = W:CreateCheckbox(parentFrame, "Enable tank marking", {
        checked = PAS.Config.enabled ~= false,
        width = width,
        x = indent, y = y,
        onChange = function(checked)
            PAS.Config.enabled = checked
            PAS.Config:Save()
            PAS.MarkButton:Refresh()
        end,
    })

    -- Off leaves the key binding and /click working; only the prompt goes away.
    _, y = W:CreateCheckbox(parentFrame, "Show the marker button while the tank is unmarked", {
        checked = PAS.Config.showButton ~= false,
        width = width,
        x = indent, y = y,
        onChange = function(checked)
            PAS.Config.showButton = checked
            PAS.Config:Save()
            PAS.MarkButton:Refresh()
        end,
    })

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Always Square", {
        "Marks the tank in your party with the square, in a single press.",
        { command = "/pas", desc = "how to mark, and the macro to do it" },
        { command = "/pas reset", desc = "put the marker button back where it started" },

        { header = "How marking works" },
        "Since patch 12.0 the game no longer lets addons place raid markers on " ..
            "their own, or read which marker a player has. Always Square used " ..
            "to mark the tank by itself; it now needs one press from you.",
        "When your party's tank has no marker, a small button appears. Click " ..
            "it and the tank is marked. Shift-drag moves it.",
        "Or skip the button: bind a key under Key Bindings > AddOns > Peavers " ..
            "Always Square. Both the binding and the macro line below work in " ..
            "combat and with the button hidden.",

        { header = "As close to automatic as it gets" },
        "Add /click PeaversAlwaysSquareMarkButton as a line in a macro you " ..
            "already press - your mount, or an opening ability. Every press " ..
            "then makes sure the tank has the square. It does nothing if they " ..
            "already have it, so it is safe to spam.",
        "The addon watches role assignments, so the press always goes to " ..
            "whoever is flagged as the tank. It stays out of the way in raids.",
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
