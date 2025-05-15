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

-- Track last mark time to prevent spam
local lastMarkTime = 0
local markCooldown = 0.1 -- Allow marking every 0.1 seconds
local cachedTankUnit = nil -- Cache the tank unit for faster checks

-- Function to find the tank unit
local function FindTankUnit()
	if not IsInGroup() then
		return nil
	end

	local numMembers = GetNumGroupMembers()
	local tanks = {}

	-- Collect all tanks first
	for i = 1, numMembers do
		local unit = i < numMembers and "party" .. i or "player"
		if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
			table.insert(tanks, unit)
		end
	end

	-- If only one tank, return it
	if #tanks == 1 then
		cachedTankUnit = tanks[1]
		return tanks[1]
	elseif #tanks > 1 then
		-- If multiple tanks, prefer the one already marked with square
		for _, unit in ipairs(tanks) do
			if GetRaidTargetIndex(unit) == PAS.Config.iconId then
				cachedTankUnit = unit
				return unit
			end
		end
		-- Otherwise return the first tank
		cachedTankUnit = tanks[1]
		return tanks[1]
	end

	cachedTankUnit = nil
	return nil
end

-- Function to find and mark the tank with immediate retries
function MarkTank(force)
	if not IsInGroup() then
		Utils.Debug(PAS, "Not in group")
		cachedTankUnit = nil
		return
	end

	if IsInRaid() then
		Utils.Debug(PAS, "In raid - disabled")
		cachedTankUnit = nil
		return
	end

	-- Respect cooldown unless forced
	local currentTime = GetTime()
	if not force and (currentTime - lastMarkTime) < markCooldown then
		return
	end

	-- Use cached tank unit if valid, otherwise find it
	local tankUnit = cachedTankUnit
	if not tankUnit or not UnitExists(tankUnit) or UnitGroupRolesAssigned(tankUnit) ~= "TANK" then
		tankUnit = FindTankUnit()
		if not tankUnit then
			Utils.Debug(PAS, "No tank found")
			return
		end
	end

	local name = UnitName(tankUnit)
	local currentMark = GetRaidTargetIndex(tankUnit)

	-- Always try to set the mark if it's different
	if currentMark ~= PAS.Config.iconId then
		SetRaidTarget(tankUnit, PAS.Config.iconId)
		lastMarkTime = currentTime
		Utils.Debug(PAS, "Marked " .. name .. " with " .. iconNames[PAS.Config.iconId])

		-- Schedule a verification check
		C_Timer.After(0.1, function()
			if UnitExists(tankUnit) and GetRaidTargetIndex(tankUnit) ~= PAS.Config.iconId then
				MarkTank(true) -- Force immediate retry
			end
		end)
	end
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

	PeaversCommons.Events:RegisterEvent("GROUP_ROSTER_UPDATE", function()
		MarkTank()
	end)

	PeaversCommons.Events:RegisterEvent("READY_CHECK", function()
		MarkTank()
	end)

	PeaversCommons.Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		MarkTank()
	end)

	PeaversCommons.Events:RegisterEvent("ROLE_CHANGED_INFORM", function()
		MarkTank()
	end)

	-- Register for raid target icon changes with immediate response
	PeaversCommons.Events:RegisterEvent("RAID_TARGET_UPDATE", function()
		-- Clear the cache to force a fresh check
		cachedTankUnit = nil
		-- Force immediate check when someone changes a raid target
		MarkTank(true)
		-- Schedule another check slightly later to catch any rapid changes
		C_Timer.After(0.05, function()
			MarkTank(true)
		end)
	end)

	-- Set up periodic checking with more aggressive frequency
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
