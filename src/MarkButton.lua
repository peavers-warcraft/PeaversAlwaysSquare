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
local testState = nil

-- Whether the player still owes the current tank a press. It is the only thing
-- that can decide visibility where markers cannot be read - see ReadMark.
local prompting = false
local dismissed = false
local lastUnit, lastGUID

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

-- What can be learned about a unit's marker: "none", "square", "other", or
-- "unknown". Out in the world the index reads normally. Inside restricted
-- content - instances, keys, encounters - it comes back secret, and it does so
-- even for an unmarked unit, so a secret says nothing at all: not "marked", not
-- "unmarked". Secrets may be tested for secrecy but never compared.
local function ReadMark(unit)
	local mark = GetRaidTargetIndex(unit)
	if IsSecret(mark) then
		return "unknown"
	end
	if not mark then
		return "none"
	end
	return mark == SQUARE and "square" or "other"
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
	GameTooltip:AddLine("Right-click to dismiss. Shift-drag to move.", 0.7, 0.7, 0.7, true)
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

	-- Any press settles the debt: a click, the key binding and /click all land
	-- here, and so does the right-click that dismisses without marking. In
	-- combat the button cannot be hidden, so it dims until the fight ends.
	button:HookScript("PostClick", function(frame, mouseButton)
		if testMode then
			return
		end
		prompting = false
		dismissed = mouseButton == "RightButton"
		if InCombatLockdown() then
			frame:SetAlpha(0.3)
		else
			MarkButton:Refresh()
		end
	end)
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
	local state = ReadMark("player")
	if state == testState then
		return
	end
	if state == "square" then
		Utils.Print(PAS, "Test: you are marked, so the button works. Right-click it to clear the marker.")
	elseif state == "unknown" then
		Utils.Print(PAS, "Test: the game hides markers from addons in here, so look above your head for the square instead.")
	elseif testState == "square" then
		Utils.Print(PAS, "Test: your marker is cleared.")
	end
	testState = state
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
	-- Outside test mode "dismiss" names no secure action, so a right-click does
	-- nothing but reach PostClick, which puts the button away unmarked.
	button:SetAttribute("type2", testMode and "raidtarget" or "dismiss")
	button:SetAttribute("action2", testMode and "clear" or nil)
	button.label:SetText(testMode and "Test: mark me" or "Mark tank")
	button:SetAlpha(1)

	-- A tank not seen before is owed a press. The GUID catches a new player
	-- landing on the same unit token; it turns secret along with everything
	-- else, and then the token alone has to do.
	local mark = "unknown"
	if unit and not testMode then
		local guid = UnitGUID(unit)
		if IsSecret(guid) then
			guid = nil
		end
		if unit ~= lastUnit or (guid and lastGUID and guid ~= lastGUID) then
			prompting, dismissed = true, false
		end
		lastUnit, lastGUID = unit, guid or lastGUID

		mark = ReadMark(unit)
		if mark == "square" then
			prompting, dismissed = false, false
		end
	elseif not testMode then
		lastUnit, lastGUID, prompting, dismissed = nil, nil, false, false
	end

	-- Where the marker can be read it decides outright, which is what keeps the
	-- square on after someone removes it. Where it cannot, the prompt does.
	-- Test mode is always on screen, whatever the marker or the show setting.
	-- A dismissal holds until there is a new tank, a ready check or a square.
	local wanted = not dismissed
		and (mark == "none" or mark == "other" or (mark == "unknown" and prompting))
	local show = testMode or (unit ~= nil and PAS.Config.showButton and wanted) or false
	button:SetShown(show)
	if show and not testMode then
		AnnounceOnce()
	end

	Utils.Debug(PAS, "Tank unit: " .. (unit or "none") .. ", marker " .. mark .. ", prompting " .. tostring(prompting)
		.. ", dismissed " .. tostring(dismissed) .. ", button " .. (show and "shown" or "hidden"))
end

-- Asks for a press again. A ready check is the last calm moment before a key,
-- and inside the instance the addon cannot see whether the square survived.
function MarkButton:Prompt()
	prompting, dismissed = true, false
	self:Refresh()
end

function MarkButton:IsTestMode()
	return testMode
end

function MarkButton:SetTestMode(on)
	testMode = on and true or false
	testState = nil
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
