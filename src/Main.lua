local addonName, PAS = ...

-- Access the PeaversCommons library
local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- Initialize addon namespace
PAS = PAS or {}
PAS.name = addonName
PAS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

_G.PeaversAlwaysSquare = PAS

-- Key Bindings > AddOns. The binding itself is the CLICK in Bindings.xml: the
-- press has to land on the secure button, since no addon function may mark.
_G.BINDING_HEADER_PEAVERSALWAYSSQUARE = "Peavers Always Square"
_G["BINDING_NAME_CLICK PeaversAlwaysSquareMarkButton:LeftButton"] = "Mark the tank"

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pas", {
	default = function()
		-- A slash command runs as addon code, so it cannot place the mark itself
		PAS.MarkButton:Refresh()
		Utils.Print(PAS, "Click the marker button or press your key binding to mark the tank.")
		print("  Or add this line to a macro you already press, and the tank gets marked along the way:")
		print("  /click PeaversAlwaysSquareMarkButton")
	end,
	debug = function()
		PAS.Config.debugMode = not PAS.Config.debugMode
		PAS.Config.DEBUG_ENABLED = PAS.Config.debugMode
		PAS.Config:Save()
		Utils.Print(PAS, "Debug mode " .. (PAS.Config.debugMode and "enabled" or "disabled"))
	end,
	reset = function()
		PAS.MarkButton:ResetPosition()
	end,
	help = function()
		Utils.Print(PAS, "Commands:")
		print("  /pas - How to mark the tank")
		print("  /pas reset - Put the marker button back where it started")
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

	PAS.MarkButton:Create()

	-- Everything that can change who the tank is, whether they are marked, or
	-- whether the button may be touched again. No polling: there is nothing
	-- left for a timer to fix, only a button to keep pointed the right way.
	local function refresh()
		PAS.MarkButton:Refresh()
	end
	for _, event in ipairs({
		"GROUP_ROSTER_UPDATE",
		"PLAYER_ROLES_ASSIGNED",
		"ROLE_CHANGED_INFORM",
		"PLAYER_ENTERING_WORLD",
		"RAID_TARGET_UPDATE",
		"PLAYER_REGEN_ENABLED",
	}) do
		PeaversCommons.Events:RegisterEvent(event, refresh)
	end

	PeaversCommons.Events:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		PAS.MarkButton:OnCombatStart()
	end)

	refresh()

	-- Use the centralized SettingsUI system from PeaversCommons
	C_Timer.After(0.5, function()
		PeaversCommons.SettingsUI:CreateRedirectPage(PAS, "PeaversAlwaysSquare", "Peavers Always Square")
	end)

	-- Register with PeaversConfig registry
	if PeaversCommons.ConfigRegistry then
		PeaversCommons.ConfigRegistry:Register({
			name = "PeaversAlwaysSquare",
			displayName = "Always Square",
			description = "Automatic tank marker assignment",
			addonRef = PAS,
			config = PAS.Config,
			pages = PAS.ConfigUI:GetPages(),
			order = 10,
		})
	end
end, {
	suppressAnnouncement = true
})
