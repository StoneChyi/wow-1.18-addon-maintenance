-- ========== TianYan: Summon tracker with history records ==========

local TY = {}
TY.summonCache = {}
local bar = nil
local lines = {}

local scanTip = nil
local function initScanTip()
	if not scanTip then
		scanTip = CreateFrame("GameTooltip", "TYScanTip", UIParent, "GameTooltipTemplate")
		scanTip:SetOwner(UIParent, "ANCHOR_NONE")
	end
end

local EXCLUDE_NAMES = {
	"疲倦的骡子",
	"修理机器人75B型",
	"拍卖师德雷兹比特",
	"车队科多兽",
	"机械拍卖师",
}

local function isExcluded(unitName)
	if not unitName then return false end
	for _, excl in ipairs(EXCLUDE_NAMES) do
		if string.find(unitName, excl) then return true end
	end
	return false
end

local function isMySummon(unit)
	if not unit or not UnitExists(unit) then return false end
	if UnitIsDead(unit) then return false end
	if UnitCanAttack("player", unit) then return false end
	if UnitIsUnit(unit, "player") then return false end

	local unitName = UnitName(unit)
	if isExcluded(unitName) then return false end

	initScanTip()
	scanTip:ClearLines()
	scanTip:SetUnit(unit)

	local playerName = UnitName("player")
	if not playerName or playerName == "" then return false end

	local i = 1
	while true do
		local leftText = getglobal("TYScanTipTextLeft" .. i)
		if not leftText then break end
		local text = leftText:GetText()
		if text and string.find(text, playerName) then
			return true
		end
		local rightText = getglobal("TYScanTipTextRight" .. i)
		if rightText then
			local rtext = rightText:GetText()
			if rtext and string.find(rtext, playerName) then
				return true
			end
		end
		i = i + 1
	end
	return false
end

local function nameplateHasMyName(frame)
	local playerName = UnitName("player")
	if not playerName or playerName == "" then return false end
	if not frame or not frame.GetNumRegions then return false end
	local numRegions = frame:GetNumRegions()
	if not numRegions then return false end
	for j = 1, numRegions do
		local region = select(j, frame:GetRegions())
		if region then
			local ok, objType = pcall(function()
				if region.GetObjectType then return region:GetObjectType() end
				return ""
			end)
			if ok and objType == "FontString" then
				local ok2, text = pcall(region.GetText, region)
				if ok2 and text and string.find(text, playerName) then
					return true
				end
			end
		end
	end
	return false
end

local function getUnitNameSafe(unit)
	if not unit or not UnitExists(unit) then return nil end
	local n = UnitName(unit)
	if n and n ~= "" then return n end
	return nil
end

local function getNameFromNameplate(frame)
	if not frame or not frame.GetNumRegions then return nil end
	local numRegions = frame:GetNumRegions()
	if not numRegions then return nil end
	for j = 1, numRegions do
		local region = select(j, frame:GetRegions())
		if region then
			local ok, objType = pcall(function()
				if region.GetObjectType then return region:GetObjectType() end
				return ""
			end)
			if ok and objType == "FontString" then
				local ok2, text = pcall(region.GetText, region)
				if ok2 and text and text ~= "" and string.len(text) > 1 then
					local playerName = UnitName("player")
					if not string.find(text, playerName) then
						return text
					end
				end
			end
		end
	end
	return nil
end

local function scanForSummons()
	local now = GetTime()
	for guid, info in pairs(TY.summonCache) do
		if now - info.time > 30 then
			TY.summonCache[guid] = nil
		elseif string.sub(guid, 1, 6) ~= "mysum_" then
			if not UnitExists(guid) or UnitIsDead(guid) then
				TY.summonCache[guid] = nil
			end
		end
	end

	local units = { "target", "mouseover" }
	for _, u in ipairs(units) do
		if isMySummon(u) then
			local g = GetUnitGUID(u)
			local n = getUnitNameSafe(u)
			if g and n then
				TY.summonCache[g] = { name = n, time = now }
			end
		end
	end

	for i = 1, 40 do
		local unit = "nameplate" .. i
		local ok, exists = pcall(UnitExists, unit)
		if ok and exists then
			if isMySummon(unit) then
				local g = GetUnitGUID(unit)
				local n = getUnitNameSafe(unit)
				if g and n then
					TY.summonCache[g] = { name = n, time = now }
				end
			end
		end
	end

	if WorldFrame and WorldFrame.GetNumChildren then
		local numChildren = WorldFrame:GetNumChildren()
		for i = 1, numChildren do
			local frame = select(i, WorldFrame:GetChildren())
			if frame and frame:IsShown() then
				if nameplateHasMyName(frame) then
					local unit = frame.unit
					if not unit then unit = "nameplate" .. i end
					local g = nil
					local n = nil
					if unit then
						local ok, exists = pcall(UnitExists, unit)
						if ok and exists then
							g = GetUnitGUID(unit)
							n = getUnitNameSafe(unit)
						end
					end
					if not n then
						n = getNameFromNameplate(frame) or "未知召唤物"
					end
					if g and n then
						TY.summonCache[g] = { name = n, time = now }
					else
						local fakeGuid = "mysum_" .. i
						TY.summonCache[fakeGuid] = { name = n or "未知召唤物", time = now }
					end
				end
			end
		end
	end

	local totalCount = 0
	local nameGroups = {}
	for guid, info in pairs(TY.summonCache) do
		local alive = false
		if string.sub(guid, 1, 5) == "mysum" then
			if now - info.time < 30 then
				alive = true
			else
				TY.summonCache[guid] = nil
			end
		elseif UnitExists(guid) and not UnitIsDead(guid) then
			alive = true
		else
			TY.summonCache[guid] = nil
		end
		if alive then
			totalCount = totalCount + 1
			local name = info.name or "未知"
			if not nameGroups[name] then
				nameGroups[name] = 0
			end
			nameGroups[name] = nameGroups[name] + 1
		end
	end
	return totalCount, nameGroups
end

-- ========== UI ==========

local backdrop_bar = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 8, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local COL_BG     = { r = 0.06, g = 0.06, b = 0.06, a = 0.88 }
local COL_BORDER = { r = 0.3,  g = 0.3,  b = 0.3,  a = 0.8 }
local COL_GREEN  = { r = 0.0,  g = 0.8,  b = 0.0 }
local COL_GRAY   = { r = 0.4,  g = 0.4,  b = 0.4 }
local COL_TITLE  = { r = 0.53, g = 0.8,  b = 1.0 }
local COL_CUR    = { r = 0.8,  g = 1.0,  b = 0.8 }

local MAX_LINES = 20

local function TY_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[天眼]|r " .. msg)
end

local function updateHistory(nameGroups)
	if not TY_DB then TY_DB = {} end
	if not TY_DB.history then TY_DB.history = {} end
	for name, num in pairs(nameGroups) do
		if not TY_DB.history[name] or num > TY_DB.history[name] then
			TY_DB.history[name] = num
		end
	end
end

local function refreshDisplay()
	if not bar then return end
	local count, groups = scanForSummons()
	updateHistory(groups)

	local inCombat = UnitAffectingCombat("player")

	lines[1]:SetText("天眼 (" .. count .. ")")
	lines[1]:SetTextColor(COL_TITLE.r, COL_TITLE.g, COL_TITLE.b)

	local sortedNames = {}
	for name, _ in pairs(groups) do
		table.insert(sortedNames, name)
	end
	table.sort(sortedNames, function(a, b)
		local ga = (TY_DB.history and TY_DB.history[a]) or 0
		local gb = (TY_DB.history and TY_DB.history[b]) or 0
		if ga ~= gb then return ga > gb end
		return a < b
	end)

	local lineIdx = 2
	local shown = math.min(table.getn(sortedNames), MAX_LINES - 1)
	for i = 1, shown do
		local name = sortedNames[i]
		local cur = groups[name] or 0
		local hist = (TY_DB.history and TY_DB.history[name]) or 0
		if inCombat then
			lines[lineIdx]:SetText(name .. "  " .. cur .. " / " .. hist)
			if cur > 0 then
				lines[lineIdx]:SetTextColor(COL_CUR.r, COL_CUR.g, COL_CUR.b)
			else
				lines[lineIdx]:SetTextColor(COL_GRAY.r, COL_GRAY.g, COL_GRAY.b)
			end
		else
			lines[lineIdx]:SetText(name .. "  " .. cur)
			lines[lineIdx]:SetTextColor(COL_CUR.r, COL_CUR.g, COL_CUR.b)
		end
		lines[lineIdx]:Show()
		lineIdx = lineIdx + 1
	end
	for i = lineIdx, MAX_LINES do
		if lines[i] then lines[i]:Hide() end
	end

	local shownLines = 1 + shown
	bar:SetHeight(8 + shownLines * 14 + 4)
end

function TY_CreateBar()
	if bar then return end

	bar = CreateFrame("Frame", "TYBar", UIParent)
	bar:SetWidth(160)
	bar:SetHeight(26)
	bar:SetPoint("CENTER", UIParent, "CENTER", 200, 200)
	bar:SetBackdrop(backdrop_bar)
	bar:SetBackdropColor(COL_BG.r, COL_BG.g, COL_BG.b, COL_BG.a)
	bar:SetBackdropBorderColor(COL_BORDER.r, COL_BORDER.g, COL_BORDER.b, COL_BORDER.a)
	bar:EnableMouse(true)
	bar:SetMovable(true)
	bar:RegisterForDrag("LeftButton")

	lines[1] = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lines[1]:SetPoint("TOPLEFT", bar, "TOPLEFT", 6, -4)
	lines[1]:SetText("天眼 (0)")
	lines[1]:SetTextColor(COL_TITLE.r, COL_TITLE.g, COL_TITLE.b)

	local subTitle = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	subTitle:SetPoint("LEFT", lines[1], "RIGHT", 2, 0)
	subTitle:SetText("|cffffcc00.By.小老板娘|r")
	subTitle:SetTextColor(1.0, 0.8, 0.0)
	local f, h, fpath = subTitle:GetFont()
	if f then subTitle:SetFont(f, 9) end
	bar.subTitle = subTitle

	for i = 2, MAX_LINES do
		lines[i] = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lines[i]:SetPoint("TOPLEFT", lines[i-1], "BOTTOMLEFT", 0, 0)
		lines[i]:SetText("")
		lines[i]:Hide()
	end

	local closeBtn = CreateFrame("Button", nil, bar)
	closeBtn:SetWidth(14)
	closeBtn:SetHeight(14)
	closeBtn:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -3, -3)
	closeBtn:SetBackdrop(backdrop_bar)
	closeBtn:SetBackdropColor(0.6, 0.1, 0.1, 0.6)
	local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	closeTxt:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
	closeTxt:SetText("X")
	closeTxt:SetTextColor(1, 1, 1)
	closeBtn:SetScript("OnClick", function()
		bar:Hide()
		TY_DB.shown = false
	end)

	bar:SetScript("OnDragStart", function() bar:StartMoving() end)
	bar:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		local p, _, rp, x, y = bar:GetPoint()
		TY_DB.pos = { point = p, relPoint = rp, x = x, y = y }
	end)

	bar:SetScript("OnEnter", nil)
	bar:SetScript("OnLeave", nil)

	bar:SetScript("OnMouseUp", function()
		if arg1 == "RightButton" then
			if TY_DB and TY_DB.history then
				TY_Print("=== 历史最高记录 ===")
				local any = false
				for name, num in pairs(TY_DB.history) do
					if not isExcluded(name) then
						TY_Print(name .. ": " .. num)
						any = true
					end
				end
				if not any then
					TY_Print("暂无记录")
				end
			end
		end
	end)

	bar:Show()
	refreshDisplay()
end

local updateFrame = CreateFrame("Frame")
local updateTimer = 0
updateFrame:SetScript("OnUpdate", function()
	updateTimer = updateTimer + arg1
	if updateTimer < 0.3 then return end
	updateTimer = 0
	refreshDisplay()
end)

-- ========== Minimap button ==========
local miniBtn = nil

function TY_CreateMiniBtn()
	if miniBtn then return end
	miniBtn = CreateFrame("Button", "TYMiniBtn", Minimap)
	miniBtn:SetWidth(32)
	miniBtn:SetHeight(32)
	miniBtn:SetFrameLevel(8)
	miniBtn:SetFrameStrata("MEDIUM")
	miniBtn:SetNormalTexture("Interface\\Minimap\\Tracking\\None")
	miniBtn:SetPushedTexture("Interface\\Minimap\\UI-Minimap-ZoomInButton-Down")
	miniBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local icon = miniBtn:CreateTexture(nil, "OVERLAY")
	icon:SetTexture("Interface\\Icons\\Spell_Nature_EyeOfTheStorm")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("CENTER", miniBtn, "CENTER", 0, 0)
	miniBtn.icon = icon

	miniBtn:SetMovable(true)
	miniBtn:RegisterForDrag("LeftButton")
	miniBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local angle = TY_DB and TY_DB.miniAngle or -1.2
	local x = math.cos(angle) * 80
	local y = math.sin(angle) * 80
	miniBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)

	miniBtn:SetScript("OnDragStart", function()
		this:LockPoint()
		miniBtn:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = this:GetCenter()
			local a = math.atan2(cy - my, cx - mx)
			local dist = 80
			this:ClearAllPoints()
			this:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * dist, math.sin(a) * dist)
			TY_DB.miniAngle = a
		end)
	end)
	miniBtn:SetScript("OnDragStop", function()
		miniBtn:SetScript("OnUpdate", nil)
	end)

	miniBtn:SetScript("OnClick", function()
		if arg1 == "LeftButton" then
			if TYBar:IsShown() then
				TYBar:Hide()
				TY_DB.shown = false
			else
				TYBar:Show()
				TY_DB.shown = true
			end
		elseif arg1 == "RightButton" then
			if TY_DB and TY_DB.history then
				TY_Print("=== 历史最高记录 ===")
				local any = false
				for name, num in pairs(TY_DB.history) do
					if not isExcluded(name) then
						TY_Print(name .. ": " .. num)
						any = true
					end
				end
				if not any then
					TY_Print("暂无记录")
				end
			end
		end
	end)

	miniBtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
		local count = scanForSummons()
		GameTooltip:SetText("天眼 - 召唤物统计", 0.53, 0.8, 1.0)
		GameTooltip:AddLine("当前召唤物: " .. count .. " 个", 1, 1, 0)
		GameTooltip:AddLine(" ", 1, 1, 1)
		GameTooltip:AddLine("左键: 显示/隐藏", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("右键: 打印历史最高", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("拖动: 移动按钮位置", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("/rety: 重置历史最高", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	miniBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- ========== Events ==========
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

pcall(function()
	eventFrame:RegisterEvent("UNIT_COMBAT_GUID")
	eventFrame:RegisterEvent("UNIT_MODEL_CHANGED_GUID")
end)

eventFrame:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		if not TY_DB then TY_DB = {} end
		if not TY_DB.history then TY_DB.history = {} end
		TY_CreateBar()
		TY_CreateMiniBtn()
		if TY_DB.pos and TY_DB.pos.point then
			TYBar:ClearAllPoints()
			TYBar:SetPoint(TY_DB.pos.point, UIParent, TY_DB.pos.relPoint, TY_DB.pos.x, TY_DB.pos.y)
		end
		if TY_DB.shown == false then
			TYBar:Hide()
		end
		pcall(function()
			SetCVar("nameplateShowFriends", 1)
		end)
		pcall(function()
			if GetCVar("NP_EnableUnitEventsGuid") ~= "1" then
				SetCVar("NP_EnableUnitEventsGuid", 1)
			end
		end)
		TY_Print("TianYan loaded!")

	elseif event == "PLAYER_TARGET_CHANGED" then
		if isMySummon("target") then
			local g = GetUnitGUID("target")
			local n = getUnitNameSafe("target")
			if g and n then
				TY.summonCache[g] = { name = n, time = GetTime() }
			end
		end
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		if isMySummon("mouseover") then
			local g = GetUnitGUID("mouseover")
			local n = getUnitNameSafe("mouseover")
			if g and n then
				TY.summonCache[g] = { name = n, time = GetTime() }
			end
		end
	elseif event == "UNIT_COMBAT_GUID" or event == "UNIT_MODEL_CHANGED_GUID" then
		if arg1 and UnitExists(arg1) and not UnitCanAttack("player", arg1) then
			if isMySummon(arg1) then
				local n = getUnitNameSafe(arg1)
				if n then
					TY.summonCache[arg1] = { name = n, time = GetTime() }
				end
			end
		end
	end
end)

-- ========== Slash commands ==========
SLASH_TYAN1 = "/tyan"
SlashCmdList["TYAN"] = function(msg)
	if TYBar:IsShown() then
		TYBar:Hide()
		TY_DB.shown = false
		TY_Print("hidden")
	else
		TYBar:Show()
		TY_DB.shown = true
		TY_Print("shown")
	end
end

SLASH_RETY1 = "/rety"
SlashCmdList["RETY"] = function(msg)
	if TY_DB and TY_DB.history then
		TY_DB.history = {}
	end
	TY_Print("history reset")
	refreshDisplay()
end
