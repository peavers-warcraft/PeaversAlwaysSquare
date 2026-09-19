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
    local toggle
    toggle, y = W:CreateCheckbox(parentFrame, "Enable tank marking", {
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
    _, y = W:CreateCheckbox(parentFrame, "Show the marker button when a tank needs marking", {
        checked = PAS.Config.showButton ~= false,
        width = width,
        x = indent, y = y,
        onChange = function(checked)
            PAS.Config.showButton = checked
            PAS.Config:Save()
            PAS.MarkButton:Refresh()
        end,
    })

    _, newY = W:CreateSectionHeader(parentFrame, "Testing", indent, y)
    y = newY - 8

    -- Not saved: test mode lives for the session only, so a reload can never
    -- leave the button pointed at the player in a real group.
    _, y = W:CreateCheckbox(parentFrame, "Test mode: point the marker button at me", {
        checked = PAS.MarkButton:IsTestMode(),
        width = width,
        x = indent, y = y,
        onChange = function(checked)
            PAS.MarkButton:SetTestMode(checked)
        end,
    })

    local note = W:CreateLabel(parentFrame,
        "Try the addon without a group. While this is on, the marker button stays on screen and marks you " ..
            "instead of a tank: left-click it, press your key binding or run the /click macro, and the square " ..
            "should appear over your head. Right-click the button to clear it and go again. " ..
            "Test mode switches itself off when you reload or log out.",
        { width = width, wrap = true })
    note:SetPoint("TOPLEFT", indent, y)
    local noteHeight = note:GetStringHeight() or 0
    if noteHeight <= 0 then
        noteHeight = 56
    end
    y = y - noteHeight - 12

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Always Square", {
        "Marks the tank in your party with the square, in a single press.",
        { command = "/pas", desc = "bring the marker button back, and the macro to mark with" },
        { command = "/pas reset", desc = "put the marker button back where it started" },

        { header = "How marking works" },
        "Since patch 12.0 the game no longer lets addons place raid markers on " ..
            "their own, or read which marker a player has. Always Square used " ..
            "to mark the tank by itself; it now needs one press from you.",
        "A small button appears when a tank joins your party, and again on " ..
            "every ready check. Click it and the tank is marked; right-click " ..
            "puts it away unmarked. Shift-drag moves it.",
        "Out in the world the addon can still see an unmarked tank, so the " ..
            "button also comes back if someone removes the square. Inside " ..
            "instances the game hides markers from addons, which is why it " ..
            "asks on ready checks rather than guessing.",
        "Or skip the button: bind a key under Key Bindings > AddOns > Peavers " ..
            "Always Square. Both the binding and the macro line below work in " ..
            "combat and with the button hidden.",

        "The addon watches role assignments, so the press always goes to " ..
            "whoever is flagged as the tank. It stays out of the way in raids.",

        { header = "As close to automatic as it gets" },
        "Add /click PeaversAlwaysSquareMarkButton as a line in a macro you " ..
            "already press - your mount, or an opening ability. Every press " ..
            "then makes sure the tank has the square. It does nothing if they " ..
            "already have it, so it is safe to spam.",

        { header = "Trying it without a group" },
        "The General tab has a test mode that points the button at you, so " ..
            "you can check the button, key binding and macro on your own.",
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
