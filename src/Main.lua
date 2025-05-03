local addonName, PAS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon namespace
PAS = PAS or {}
PAS.name = addonName
PAS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Icon names for reference
local iconNames = {
	[1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
	[5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull"
}

-- Function to find and mark the tank
function MarkTank()
	if not IsInGroup() then
		Utils.Debug(PAS, "Not in group")
		return
	end

	if IsInRaid() then
		Utils.Debug(PAS, "In raid - disabled")
		return
	end

	local numMembers = GetNumGroupMembers()
	for i = 1, numMembers do
		local unit = i < numMembers and "party" .. i or "player"
		if UnitGroupRolesAssigned(unit) == "TANK" then
			local name = UnitName(unit)
			local currentMark = GetRaidTargetIndex(unit)
			if currentMark ~= PAS.Config.iconId then
				SetRaidTarget(unit, PAS.Config.iconId)
				Utils.Debug(PAS, "Marked " .. name .. " with " .. iconNames[PAS.Config.iconId])
			end
			return
		end
	end

	Utils.Debug(PAS, "No tank found")
end

-- Make the function globally accessible
_G.MarkTank = MarkTank

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pas", {
	default = function()
		Utils.Print(PAS, "Manual check performed")
		MarkTank()
	end,
	debug = function()
		PAS.Config.debugMode = not PAS.Config.debugMode
		PAS.Config.DEBUG_ENABLED = PAS.Config.debugMode
		PAS.Config:Save()
		Utils.Print(PAS, "Debug mode " .. (PAS.Config.debugMode and "enabled" or "disabled"))
	end,
	icon = function(rest)
		local iconId = tonumber(rest)
		if iconId and iconId >= 1 and iconId <= 8 then
			PAS.Config.iconId = iconId
			PAS.Config:Save()
			Utils.Print(PAS, "Using icon: " .. iconNames[iconId])
		else
			Utils.Print(PAS, "Invalid icon (use 1-8)")
		end
	end,
	help = function()
		Utils.Print(PAS, "Commands:")
		print("  /pas - Manual check")
		print("  /pas icon N - Set icon (1-8)")
		print("  /pas debug - Toggle debug mode")
		print("  /pas config - Open settings")
	end
})

-- Initialize the addon
PeaversCommons.Events:Init(addonName, function()
	-- Initialize configuration
	PAS.Config:Initialize()

	-- Initialize configuration UI
	if PAS.ConfigUI and PAS.ConfigUI.Initialize then
		PAS.ConfigUI:Initialize()
	end

	-- Initialize support UI
	if PAS.SupportUI and PAS.SupportUI.Initialize then
		PAS.SupportUI:Initialize()
	end

	-- Register events
	PeaversCommons.Events:RegisterEvent("GROUP_ROSTER_UPDATE", function()
		MarkTank()
	end)

	PeaversCommons.Events:RegisterEvent("READY_CHECK", function()
		MarkTank()
	end)

	PeaversCommons.Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		MarkTank()
	end)

	-- Set up periodic checking
	PeaversCommons.Events:RegisterOnUpdate(PAS.Config.checkFrequency, function()
		if PAS.Config.enabled then
			MarkTank()
		end
	end, "PAS_TankMarker")

	-- DIRECT REGISTRATION APPROACH
	-- This ensures the addon appears in Options > Addons regardless of PeaversCommons logic
	C_Timer.After(0.5, function()
		-- Create the main panel (Support UI as landing page)
		local mainPanel = CreateFrame("Frame")
		mainPanel.name = "PeaversAlwaysSquare"

		-- Required callbacks
		mainPanel.OnRefresh = function()
		end
		mainPanel.OnCommit = function()
		end
		mainPanel.OnDefault = function()
		end

		-- Get addon version
		local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

		-- Add background image
		local ICON_ALPHA = 0.1
		local iconPath = "Interface\\AddOns\\PeaversCommons\\src\\Media\\Icon"
		local largeIcon = mainPanel:CreateTexture(nil, "BACKGROUND")
		largeIcon:SetTexture(iconPath)
		largeIcon:SetPoint("TOPLEFT", mainPanel, "TOPLEFT", 0, 0)
		largeIcon:SetPoint("BOTTOMRIGHT", mainPanel, "BOTTOMRIGHT", 0, 0)
		largeIcon:SetAlpha(ICON_ALPHA)

		-- Create header and description
		local titleText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		titleText:SetPoint("TOPLEFT", 16, -16)
		titleText:SetText("Peavers Always Square")
		titleText:SetTextColor(1, 0.84, 0)  -- Gold color for title

		-- Version information
		local versionText = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		versionText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
		versionText:SetText("Version: " .. version)

		-- Support information
		local supportInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		supportInfo:SetPoint("TOPLEFT", 16, -70)
		supportInfo:SetPoint("TOPRIGHT", -16, -70)
		supportInfo:SetJustifyH("LEFT")
		supportInfo:SetText("Automatically marks tank with the target marker of your choice. If you enjoy this addon and would like to support its development, or if you need help, stop by the website.")
		supportInfo:SetSpacing(2)

		-- Website URL
		local websiteLabel = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		websiteLabel:SetPoint("TOPLEFT", 16, -120)
		websiteLabel:SetText("Website:")

		local websiteURL = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		websiteURL:SetPoint("TOPLEFT", websiteLabel, "TOPLEFT", 70, 0)
		websiteURL:SetText("https://peavers.io")
		websiteURL:SetTextColor(0.3, 0.6, 1.0)

		-- Additional info
		local additionalInfo = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		additionalInfo:SetPoint("BOTTOMRIGHT", -16, 16)
		additionalInfo:SetJustifyH("RIGHT")
		additionalInfo:SetText("Thank you for using Peavers Addons!")

		-- Now create/prepare the settings panel
		local settingsPanel

		if PAS.ConfigUI and PAS.ConfigUI.panel then
			-- Use existing ConfigUI panel
			settingsPanel = PAS.ConfigUI.panel
		else
			-- Create a simple settings panel with commands
			settingsPanel = CreateFrame("Frame")
			settingsPanel.name = "Settings"

			-- Required callbacks
			settingsPanel.OnRefresh = function()
			end
			settingsPanel.OnCommit = function()
			end
			settingsPanel.OnDefault = function()
			end

			-- Add content
			local settingsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			settingsTitle:SetPoint("TOPLEFT", 16, -16)
			settingsTitle:SetText("Settings")

			-- Add commands section
			local commandsTitle = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			commandsTitle:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -16)
			commandsTitle:SetText("Available Commands:")

			local commandsList = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			commandsList:SetPoint("TOPLEFT", commandsTitle, "BOTTOMLEFT", 10, -8)
			commandsList:SetJustifyH("LEFT")
			commandsList:SetText(
				"/pas - Manual check\n" ..
					"/pas icon N - Set icon (1-8)\n" ..
					"/pas debug - Toggle debug mode\n" ..
					"/pas config - Open settings"
			)
		end

		-- Register with the Settings API
		if Settings then
			-- Register main category
			local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)

			-- This is the CRITICAL line to make it appear in Options > Addons
			Settings.RegisterAddOnCategory(category)

			-- Store the category
			PAS.directCategory = category
			PAS.directPanel = mainPanel

			-- Register settings panel as subcategory
			local settingsCategory = Settings.RegisterCanvasLayoutSubcategory(category, settingsPanel, settingsPanel.name)
			PAS.directSettingsCategory = settingsCategory

			-- Debug output
			if Utils and Utils.Debug then
				Utils.Debug(PAS, "Direct registration complete")
			end
		end
	end)
end, {
	-- Standardized announcement message
	announceMessage = "Use |cff3abdf7/pas config|r to get started"
})
