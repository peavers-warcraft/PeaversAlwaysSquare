local _, PAS = ...

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

-- 12.0 took raid markers away from addon code. SetRaidTarget is protected, and
-- GetRaidTargetIndex hands back a secret number that cannot be compared, so the
-- old loop - read the mark, fix it if wrong - can no longer run at all. What is
-- left is Blizzard's own "raidtarget" secure action, which sets the marker from
-- secure code but only in answer to a hardware event. The mark is therefore one
-- press - this button, its key binding, or /click - rather than automatic.
local MarkButton = {}
PAS.MarkButton = MarkButton

local BUTTON_NAME = "PeaversAlwaysSquareMarkButton"
local SQUARE = 6
local ICON_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. SQUARE
local BUTTON_SIZE = 40

local button
local dragging = false

-- Test mode aims the button at the player, so the whole path - click, key
-- binding, /click - can be tried solo. Held in memory only: it must never
-- survive a reload and leave someone marking themselves in a real group.
local testMode = false
local testMarked = nil

local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

-- Roles turn secret while unit identity is restricted. A secret cannot be
-- compared, so nil here means "cannot tell", which is not the same as "no".
local function IsTank(unit)
	local role = UnitGroupRolesAssigned(unit)
	if IsSecret(role) then
		return nil
	end
	return role == "TANK"
end

--- @return string|nil unit  the tank's unit token
--- @return boolean unknown  true when a role was unreadable, so nil is not "no tank"
local function FindTankUnit()
	local unknown = false

	local function check(unit)
		if not UnitExists(unit) then
			return false
		end
		local isTank = IsTank(unit)
		if isTank == nil then
			unknown = true
		end
		return isTank == true
	end

	if check("player") then
		return "player", false
	end
	for i = 1, GetNumSubgroupMembers() do
		local unit = "party" .. i
		if check(unit) then
			return unit, false
		end
	end

	return nil, unknown
end

-- An unmarked unit still reads as plain nil; any marker at all comes back
-- secret. So "needs a mark" is knowable, "has the wrong mark" is not - and a
-- secret may be truth-tested but never compared, hence `not mark` over `== nil`.
local function NeedsMark(unit)
	local mark = GetRaidTargetIndex(unit)
	if not mark then
		return true
	end
	if IsSecret(mark) then
		return false
	end
	return mark ~= SQUARE
end

-- Said once, the first time the button appears: people upgrading from the
-- automatic version otherwise just see their tank stop getting marked.
local function AnnounceOnce()
	if PAS.Config.secureNoticeShown then
		return
	end
	PAS.Config.secureNoticeShown = true
	PAS.Config:Save()

	Utils.Print(PAS, "Blizzard no longer lets addons place raid markers on their own, so marking the tank now takes one press.")
	Utils.Print(PAS, "Click the marker button, or bind a key under Key Bindings > AddOns > Peavers Always Square. Shift-drag moves the button.")
end

local function ApplyPosition()
	button:ClearAllPoints()
	button:SetPoint(PAS.Config.framePoint, UIParent, PAS.Config.framePoint, PAS.Config.frameX, PAS.Config.frameY)
end

local function StopDragging()
	if not dragging then
		return
	end
	dragging = false
	button:StopMovingOrSizing()

	local point, _, _, x, y = button:GetPoint()
	PAS.Config.framePoint = point
	PAS.Config.frameX = x
	PAS.Config.frameY = y
	PAS.Config:Save()
end

local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if testMode then
		GameTooltip:AddLine("Test mode")
		GameTooltip:AddLine("Left-click, your key binding or the /click macro puts the square on you. " ..
			"Right-click takes it off again.", 1, 1, 1, true)
		GameTooltip:AddLine("Switch test mode off in the settings when you are done.", 0.7, 0.7, 0.7, true)
		GameTooltip:AddLine("Shift-drag to move.", 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
		return
	end
	GameTooltip:AddLine("Mark the tank")
	GameTooltip:AddLine("Click to give the tank the square.", 1, 1, 1, true)
	GameTooltip:AddLine("Addons can no longer place markers by themselves, so this takes one press. " ..
		"A key binding is under Key Bindings > AddOns.", 0.7, 0.7, 0.7, true)
	GameTooltip:AddLine("Shift-drag to move.", 0.7, 0.7, 0.7, true)
	GameTooltip:Show()
end

function MarkButton:Create()
	if button then
		return
	end

	button = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:Hide()

	-- Pinned to key-up rather than following the ActionButtonUseKeyDown CVar:
	-- with that CVar on, a bare "/click PeaversAlwaysSquareMarkButton" arrives
	-- as an up-click and the template would ignore it.
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("useOnKeyDown", false)
	button:SetAttribute("action", "set")
	button:SetAttribute("marker", SQUARE)

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.6)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("TOPLEFT", 5, -5)
	button.icon:SetPoint("BOTTOMRIGHT", -5, 5)
	button.icon:SetTexture(ICON_TEXTURE)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.15)

	button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.label:SetPoint("TOP", button, "BOTTOM", 0, -2)
	button.label:SetText("Mark tank")

	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(frame)
		-- Moving a protected frame is itself blocked in combat
		if IsShiftKeyDown() and not InCombatLockdown() then
			dragging = true
			frame:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", StopDragging)
	button:SetScript("OnEnter", ShowTooltip)
	button:SetScript("OnLeave", GameTooltip_Hide)

	ApplyPosition()
end

-- Says in chat when the player's marker appears or goes, which is the proof the
-- press worked. Reading and printing are not protected, so unlike the rest of
-- Refresh this also runs in combat.
local function ReportTestState()
	if not testMode then
		return
	end
	local marked = not NeedsMark("player")
	if marked == testMarked then
		return
	end
	if marked then
		Utils.Print(PAS, "Test: you are marked, so the button works. Right-click it to clear the marker.")
	elseif testMarked ~= nil then
		Utils.Print(PAS, "Test: your marker is cleared.")
	end
	testMarked = marked
end

-- Points the secure action at the current tank and decides whether the button
-- shows. Attributes and visibility of a secure frame are locked in combat, so a
-- refresh asked for mid-fight waits for PLAYER_REGEN_ENABLED; until then the
-- button and binding keep pointing at the tank they already had.
function MarkButton:Refresh()
	if not button then
		return
	end
	ReportTestState()
	if InCombatLockdown() then
		return
	end

	local unit
	if testMode then
		unit = "player"
	elseif PAS.Config.enabled and IsInGroup() and not IsInRaid() then
		local found, unknown = FindTankUnit()
		unit = found or (unknown and button:GetAttribute("unit")) or nil
		if unit and not UnitExists(unit) then
			unit = nil
		end
	end

	-- With no unit the raidtarget action falls back to "target", and the key
	-- binding would mark whatever is targeted. No tank means no action at all.
	button:SetAttribute("type", unit and "raidtarget" or nil)
	button:SetAttribute("unit", unit)

	-- Right-click clears, in test mode only: a test needs to be repeatable, and
	-- nobody should be one stray click from unmarking a real tank.
	button:SetAttribute("type2", testMode and "raidtarget" or nil)
	button:SetAttribute("action2", testMode and "clear" or nil)
	button.label:SetText(testMode and "Test: mark me" or "Mark tank")

	-- Always on screen while testing, whatever the marker or the show setting
	local show = testMode or (unit ~= nil and PAS.Config.showButton and NeedsMark(unit)) or false
	button:SetShown(show)
	if show and not testMode then
		AnnounceOnce()
	end

	Utils.Debug(PAS, "Tank unit: " .. (unit or "none") .. ", button " .. (show and "shown" or "hidden"))
end

function MarkButton:IsTestMode()
	return testMode
end

function MarkButton:SetTestMode(on)
	testMode = on and true or false
	testMarked = nil
	if testMode then
		Utils.Print(PAS, "Test mode on. The marker button now points at you: left-click it, press your key binding " ..
			"or run /click PeaversAlwaysSquareMarkButton, and the square should appear over your head.")
	else
		Utils.Print(PAS, "Test mode off. The button is back to marking your party's tank.")
	end
	if InCombatLockdown() then
		Utils.Print(PAS, "You are in combat, so the button switches over when the fight ends.")
	end
	self:Refresh()
end

-- PLAYER_REGEN_DISABLED still runs before lockdown: last chance to let go of a
-- drag, which could not be stopped once combat has started.
function MarkButton:OnCombatStart()
	StopDragging()
end

function MarkButton:ResetPosition()
	if InCombatLockdown() then
		Utils.Print(PAS, "The button cannot be moved in combat")
		return
	end
	PAS.Config.framePoint = PAS.Config.defaults.framePoint
	PAS.Config.frameX = PAS.Config.defaults.frameX
	PAS.Config.frameY = PAS.Config.defaults.frameY
	PAS.Config:Save()
	ApplyPosition()
end

return MarkButton
