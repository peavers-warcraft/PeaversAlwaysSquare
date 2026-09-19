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
local ICON_PATH = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local BUTTON_SIZE = 40

local button
local dragging = false

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
	return mark ~= PAS.Config.iconId
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
	GameTooltip:AddLine("Mark the tank")
	GameTooltip:AddLine("Click to give the tank the " .. PAS.iconNames[PAS.Config.iconId] .. ".", 1, 1, 1, true)
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

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.6)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("TOPLEFT", 5, -5)
	button.icon:SetPoint("BOTTOMRIGHT", -5, 5)

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.15)

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOP", button, "BOTTOM", 0, -2)
	label:SetText("Mark tank")

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

-- Points the secure action at the current tank and decides whether the button
-- shows. Attributes and visibility of a secure frame are locked in combat, so a
-- refresh asked for mid-fight waits for PLAYER_REGEN_ENABLED; until then the
-- button and binding keep pointing at the tank they already had.
function MarkButton:Refresh()
	if not button or InCombatLockdown() then
		return
	end

	local unit
	if PAS.Config.enabled and IsInGroup() and not IsInRaid() then
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
	button:SetAttribute("marker", PAS.Config.iconId)
	button.icon:SetTexture(ICON_PATH .. PAS.Config.iconId)

	local show = (unit ~= nil and PAS.Config.showButton and NeedsMark(unit)) or false
	button:SetShown(show)
	if show then
		AnnounceOnce()
	end

	Utils.Debug(PAS, "Tank unit: " .. (unit or "none") .. ", button " .. (show and "shown" or "hidden"))
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
