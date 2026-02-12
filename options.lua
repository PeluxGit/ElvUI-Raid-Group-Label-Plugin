local E, L, V, P, G = unpack(ElvUI)
local RGL = E:GetModule("RaidGroupLabel")
local EP = LibStub and LibStub("LibElvUIPlugin-1.0", true)

local function BuildOptions()
	local anchorPoints = {
		TOPLEFT = "TOPLEFT",
		TOP = "TOP",
		TOPRIGHT = "TOPRIGHT",
		LEFT = "LEFT",
		CENTER = "CENTER",
		RIGHT = "RIGHT",
		BOTTOMLEFT = "BOTTOMLEFT",
		BOTTOM = "BOTTOM",
		BOTTOMRIGHT = "BOTTOMRIGHT",
	}

	local function GetAnchorValues()
		return (E and E.AnchorPoints) or anchorPoints
	end

	local options = {
		type = "group",
		name = "Raid Group Label",
		order = 90,
		get = function(info) return E.db.rgl[info[#info]] end,
		set = function(info, value)
			local key = info[#info]
			E.db.rgl[key] = value

			if key == "fontSize" then
				RGL:ApplyFont()
				return
			end

			if key == "point" or key == "relativePoint" or key == "xOffset" or key == "yOffset" then
				RGL:ApplyPosition(true)
				return
			end

			RGL:UpdateLabel()
		end,
		args = {
			enabled = {
				type = "toggle",
				name = "Enable",
				order = 1,
				set = function(info, value)
					E.db.rgl[info[#info]] = value
					if value then
						RGL:TryCreate()
					else
						if RGL.holder then
							RGL.holder:Hide()
						end
					end
				end,
			},
			textFormat = {
				type = "select",
				name = "Text Format",
				order = 2,
				values = {
					NUMBER = "#",
					SHORT = "G#",
					FULL = "Group #",
				},
			},
			fontSize = {
				type = "range",
				name = "Font Size",
				order = 3,
				min = 8,
				max = 32,
				step = 1,
			},
			showWhenSolo = {
				type = "toggle",
				name = "Show When Solo",
				order = 3.5,
				desc = "Show the label (as group 0) when not in a raid.",
			},
			style = {
				type = "group",
				name = "Style",
				order = 3.7,
				inline = true,
				args = {
					useCustomColors = {
						type = "toggle",
						name = "Use Custom Colors",
						order = 1,
						desc = "When disabled, uses ElvUI's native backdrop and border colors.",
						set = function(info, value)
							E.db.rgl[info[#info]] = value
							RGL:ApplyBackdrop()
						end,
					},
					bgColor = {
						type = "color",
						name = "Background Color",
						order = 2,
						hasAlpha = true,
						disabled = function() return not E.db.rgl.useCustomColors end,
						get = function()
							local c = E.db.rgl.bgColor
							return c.r, c.g, c.b, c.a
						end,
						set = function(_, r, g, b, a)
							local c = E.db.rgl.bgColor
							c.r, c.g, c.b, c.a = r, g, b, a
							E.db.rgl.useCustomColors = true
							RGL:ApplyBackdrop()
						end,
					},
					borderColor = {
						type = "color",
						name = "Border Color",
						order = 3,
						hasAlpha = true,
						disabled = function() return not E.db.rgl.useCustomColors end,
						get = function()
							local c = E.db.rgl.borderColor
							return c.r, c.g, c.b, c.a
						end,
						set = function(_, r, g, b, a)
							local c = E.db.rgl.borderColor
							c.r, c.g, c.b, c.a = r, g, b, a
							E.db.rgl.useCustomColors = true
							RGL:ApplyBackdrop()
						end,
					},
				},
			},
			position = {
				type = "group",
				name = "Position",
				order = 4,
				inline = true,
				args = {
					point = {
						type = "select",
						name = "Label Point",
						order = 1,
						values = GetAnchorValues,
						desc = "Which point on the label to attach.",
					},
					relativePoint = {
						type = "select",
						name = "Player Point",
						order = 2,
						values = GetAnchorValues,
						desc = "Which point on the player frame to attach to.",
					},
					xOffset = {
						type = "range",
						name = "X Offset",
						order = 3,
						min = -200,
						max = 200,
						step = 1,
					},
					yOffset = {
						type = "range",
						name = "Y Offset",
						order = 4,
						min = -200,
						max = 200,
						step = 1,
					},
					reset = {
						type = "execute",
						name = "Reset Position",
						order = 5,
						func = function()
							E.db.rgl.point = P.rgl.point
							E.db.rgl.relativePoint = P.rgl.relativePoint
							E.db.rgl.xOffset = P.rgl.xOffset
							E.db.rgl.yOffset = P.rgl.yOffset
							RGL:ResetPosition()
						end,
					},
				},
			},
			movers = {
				type = "description",
				name = "You can also reposition this label with ElvUI Movers.",
				order = 5,
			},
		},
	}

	local uf = E.Options.args.unitframe
	local individual = uf and uf.args and uf.args.individualUnits
	local player = individual and individual.args and individual.args.player

	player.args.rgl = options
end

if EP then
	EP:RegisterPlugin("ElvUI_RaidGroupLabel", BuildOptions)
else
	E:RegisterModule("RaidGroupLabelOptions", BuildOptions)
end
