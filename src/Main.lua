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
	
	-- Initialize patrons support
	if PAS.Patrons and PAS.Patrons.Initialize then
		PAS.Patrons:Initialize()
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

	-- Use the centralized SettingsUI system from PeaversCommons
	C_Timer.After(0.5, function()
		-- Create standardized settings pages
		PeaversCommons.SettingsUI:CreateSettingsPages(
			PAS,                         -- Addon reference
			"PeaversAlwaysSquare",       -- Addon name
			"Peavers Always Square",     -- Display title
			"Automatically marks tank with the target marker of your choice.", -- Description
			{   -- Slash commands
				"/pas - Manual check",
				"/pas icon N - Set icon (1-8)",
				"/pas debug - Toggle debug mode",
				"/pas config - Open settings"
			}
		)
	end)
end, {
	-- Standardized announcement message
	announceMessage = "Use |cff3abdf7/pas config|r to get started"
})
