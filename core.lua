local E, L, V, P, G = unpack(ElvUI)
local RGL = E:NewModule("RaidGroupLabel", "AceEvent-3.0", "AceHook-3.0")
local UF = E:GetModule("UnitFrames")

local DEFAULT_PADDING = 6

P.rgl = {
	enabled = true,
	textFormat = "NUMBER", -- NUMBER, SHORT, FULL
	fontSize = 12,
	showWhenSolo = true,
	point = "BOTTOMLEFT",
	relativePoint = "TOPLEFT",
	xOffset = 0,
	yOffset = 2,
	bgColor = { r = 0, g = 0, b = 0, a = 0.5 },
	borderColor = { r = 0, g = 0, b = 0, a = 1 },
	useCustomColors = false,
}

local function GetPlayerRaidGroup()
	local index = UnitInRaid("player")
	if not index then
		return nil
	end

	local _, _, subgroup = GetRaidRosterInfo(index)
	return subgroup
end

function RGL:GetPlayerFrame()
	local globalFrame = _G and _G.ElvUF_Player
	if self:IsFrame(globalFrame) then
		return globalFrame
	end

	local playerFrame = UF and UF.units and UF.units.player
	if self:IsFrame(playerFrame) then
		return playerFrame
	end

	if playerFrame and type(playerFrame) == "table" then
		if self:IsFrame(playerFrame.frame) then
			return playerFrame.frame
		end
		if self:IsFrame(playerFrame.unitframe) then
			return playerFrame.unitframe
		end
	end

	return nil
end

function RGL:IsFrame(obj)
	local objType = type(obj)
	return obj and (objType == "userdata" or objType == "table") and obj.GetObjectType
end

function RGL:GetAnchorTarget()
	local playerFrame = self:GetPlayerFrame()
	if playerFrame then
		return playerFrame
	end

	return UIParent
end

function RGL:ApplyFrameLayering()
	if not self.holder then
		return
	end

	local playerFrame = self:GetPlayerFrame()
	if playerFrame and playerFrame.GetFrameStrata then
		self.holder:SetFrameStrata(playerFrame:GetFrameStrata())
		self.holder:SetFrameLevel(200)
	else
		self.holder:SetFrameStrata("LOW")
		self.holder:SetFrameLevel(200)
	end
end

function RGL:FormatText(group)
	local style = E.db.rgl.textFormat

	if style == "FULL" then
		return ("Group %d"):format(group)
	end
	if style == "SHORT" then
		return ("G%d"):format(group)
	end

	return tostring(group)
end

function RGL:UpdateLabel()
	if not self.holder or not E.db.rgl.enabled then
		return
	end

	local inRaid = IsInRaid()
	local isMoverActive = E.configMode
	local group = inRaid and GetPlayerRaidGroup() or nil

	if not inRaid then
		if isMoverActive or E.db.rgl.showWhenSolo then
			group = 0
		end
	end

	if not group then
		self.holder:Hide()
		return
	end

	local text = self:FormatText(group)
	self.holder.text:SetText(text)

	local textW = self.holder.text:GetStringWidth() or 0
	local textH = self.holder.text:GetStringHeight() or 0
	self.holder:SetSize(textW + DEFAULT_PADDING * 2, textH + DEFAULT_PADDING * 2)
	self.holder:Show()
end

function RGL:ApplyFont()
	if not self.holder then
		return
	end

	local size = E.db.rgl.fontSize
	local font = (E.media and E.media.normFont) or STANDARD_TEXT_FONT
	if E.FontTemplate then
		E:FontTemplate(self.holder.text, font, size)
	else
		self.holder.text:SetFont(font, size)
		self.holder.text:SetShadowOffset(1, -1)
		self.holder.text:SetTextColor(1, 1, 1)
	end
	self:UpdateLabel()
end

function RGL:ApplyBackdrop()
	if not self.holder then
		return
	end

	local db = E.db.rgl
	local template = "Transparent"

	if self.holder.backdrop and self.holder.backdrop.SetTemplate then
		self.holder.backdrop:SetTemplate(template)
	elseif self.holder.SetTemplate then
		self.holder:SetTemplate(template)
	else
		self.holder:CreateBackdrop(template)
	end

	local bg, border
	if db.useCustomColors then
		bg = db.bgColor
		border = db.borderColor
	else
		local mediaBG = (E.media and (E.media.backdropfadecolor or E.media.backdropcolor)) or { 0, 0, 0, 0.35 }
		local mediaBorder = (E.media and E.media.bordercolor) or { 0, 0, 0, 1 }
		bg = {
			r = mediaBG[1] or 0,
			g = mediaBG[2] or 0,
			b = mediaBG[3] or 0,
			a = mediaBG[4] or 0.35,
		}
		border = {
			r = mediaBorder[1] or 0,
			g = mediaBorder[2] or 0,
			b = mediaBorder[3] or 0,
			a = mediaBorder[4] or 1,
		}
	end

	local function ApplyColors(frame)
		if not frame then
			return
		end
		if frame.SetBackdropColor then
			frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
		end
	end

	-- ElvUI templates may expose color methods on either the frame or frame.backdrop.
	ApplyColors(self.holder)
	ApplyColors(self.holder.backdrop)
end

function RGL:GetPositionSettings()
	local db = E.db.rgl
	local defaults = P.rgl
	local validPoints = {
		TOPLEFT = true,
		TOP = true,
		TOPRIGHT = true,
		LEFT = true,
		CENTER = true,
		RIGHT = true,
		BOTTOMLEFT = true,
		BOTTOM = true,
		BOTTOMRIGHT = true,
	}

	local point = db.point or defaults.point
	local relativePoint = db.relativePoint or defaults.relativePoint
	local xOffset = tonumber(db.xOffset)
	local yOffset = tonumber(db.yOffset)

	if not validPoints[point] then
		point = defaults.point
	end
	if not validPoints[relativePoint] then
		relativePoint = defaults.relativePoint
	end

	if xOffset == nil then
		xOffset = defaults.xOffset
	end
	if yOffset == nil then
		yOffset = defaults.yOffset
	end

	-- Keep DB sane so mover code never receives invalid SetPoint arguments.
	db.point = point
	db.relativePoint = relativePoint
	db.xOffset = xOffset
	db.yOffset = yOffset

	return point, relativePoint, xOffset, yOffset
end

function RGL:ApplyPosition(force)
	if not self.holder then
		return
	end

	self:ApplyFrameLayering()

	local anchorTarget = self:GetAnchorTarget()

	local point, relativePoint, xOffset, yOffset = self:GetPositionSettings()
	local moverHolder = E.CreatedMovers and E.CreatedMovers.RGL_PlayerMover
	if moverHolder and moverHolder.mover then
		local hasMoverPosition = E.db and E.db.movers and E.db.movers.RGL_PlayerMover

		if force and E.db and E.db.movers then
			E.db.movers.RGL_PlayerMover = nil
			hasMoverPosition = nil
		end

		if force or not hasMoverPosition then
			moverHolder.mover:ClearAllPoints()
			moverHolder.mover:SetPoint(point, anchorTarget, relativePoint, xOffset, yOffset)
			moverHolder.originPoint = { moverHolder.mover:GetPoint() }
		end

		if hasMoverPosition and E.SetMoverPoints then
			E:SetMoverPoints("RGL_PlayerMover", self.holder)
		end

		self.holder:ClearAllPoints()
		self.holder:SetPoint(point, moverHolder.mover, point, 0, 0)
		return
	end

	self.holder:ClearAllPoints()
	self.holder:SetPoint(point, anchorTarget, relativePoint, xOffset, yOffset)
end

function RGL:ResetPosition()
	if E.db and E.db.movers then
		E.db.movers.RGL_PlayerMover = nil
	end
	self:ApplyPosition(true)
	if E.ResetMover then
		E:ResetMover("RGL_PlayerMover")
	end
end

function RGL:CreateLabel()
	if self.holder then
		return
	end

	local parent = UIParent
	local holder = CreateFrame("Frame", "RGL_PlayerGroupLabel", parent)
	holder:EnableMouse(false)
	holder:CreateBackdrop("Transparent")
	holder:SetSize(40, 20)

	holder.text = holder:CreateFontString(nil, "OVERLAY")
	holder.text:SetPoint("CENTER")

	self.holder = holder

	self:ApplyFrameLayering()
	self:ApplyFont()
	self:ApplyBackdrop()

	local point, relativePoint, xOffset, yOffset = self:GetPositionSettings()
	holder:ClearAllPoints()
	holder:SetPoint(point, self:GetAnchorTarget(), relativePoint, xOffset, yOffset)

	E:CreateMover(holder, "RGL_PlayerMover", "Player Group Label", nil, nil, nil, "ALL,GENERAL", nil, "unitframe,individualUnits,player,rgl")

	self:ApplyPosition(false)

	self:UpdateLabel()
end

function RGL:OnPlayerFrameCreated()
	if not E.db.rgl.enabled then
		return
	end

	if self.holder then
		self:ApplyPosition(false)
		self:UpdateLabel()
	else
		self:CreateLabel()
	end
end

function RGL:TryCreate()
	if not E.db.rgl.enabled then
		return
	end

	if InCombatLockdown and InCombatLockdown() then
		self.needsPostCombatRefresh = true
		return
	end

	if self.holder then
		self:ApplyFont()
		self:ApplyBackdrop()
		self:ApplyPosition(false)
		self:UpdateLabel()
		return
	end

	self:CreateLabel()
end

function RGL:OnRegenEnabled()
	if not self.needsPostCombatRefresh then
		return
	end

	self.needsPostCombatRefresh = nil
	self:TryCreate()
end

function RGL:Initialize()
	if not E.db.rgl then
		return
	end

	if UF and UF.CreatePlayerFrame and type(UF.CreatePlayerFrame) == "function" then
		self:SecureHook(UF, "CreatePlayerFrame", "OnPlayerFrameCreated")
	end

	self:TryCreate()

	self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateLabel")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateLabel")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "TryCreate")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled")
end

E:RegisterModule(RGL:GetName())
