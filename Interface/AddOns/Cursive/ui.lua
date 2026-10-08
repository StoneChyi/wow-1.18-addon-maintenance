if not Cursive.nampower then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local utils = Cursive.utils
local filter = Cursive.filter

-- 新增：获取单位距离，用于按距离排序 by 武藤纯子酱 2026.9.10
local function GetUnitDistance(guid)
	if pcall(UnitXP, "nop", "nop") then
		local distance = UnitXP("distanceBetween", "player", guid)
		if distance then
			return distance
		end
		return 999999
	end

	if CheckInteractDistance(guid, 3) then -- 9.9码（决斗）
		return 9.9
	elseif CheckInteractDistance(guid, 2) then -- 11.11码（交易）
		return 11.11
	elseif CheckInteractDistance(guid, 4) or CheckInteractDistance(guid, 1) then -- 28码（跟随和查看）
		return 28
	end
	return 999999
end

-- 新增：检测单位 buff/debuff 位是否全满（无空槽） by 武藤纯子酱 2026.9.10
local function HasFullBuffDebuffSlots(guid)
	local auras = GetUnitField(guid, "aura")
	if not auras then
		return false
	end

	local count = 0
	for _, spellID in pairs(auras) do
		count = count + 1
		if not spellID or spellID <= 0 then
			return false
		end
	end

	return count > 0
end

-- 新增：buff/debuff 位满时的强调显示（边框/血条/淡化） by 武藤纯子酱 2026.9.10
local function ApplyFullSlotsEmphasis(unitFrame, full)
	local style = Cursive.db.profile.fullslotstyle

	if style == L["Border"] then
		if unitFrame.healthBar and unitFrame.healthBar.border then
			if full then
				unitFrame.healthBar.border:SetBackdropBorderColor(1, 0.2, 1, 1)
			elseif unitFrame.hover then
				unitFrame.healthBar.border:SetBackdropBorderColor(1, 1, 1, 1)
			elseif UnitAffectingCombat(unitFrame.guid) then
				unitFrame.healthBar.border:SetBackdropBorderColor(.8, .2, .2, 1)
			else
				unitFrame.healthBar.border:SetBackdropBorderColor(.2, .2, .2, 1)
			end
		end
	elseif style == L["Health Bar"] then
		if unitFrame.healthBar then
			if full then
				unitFrame.healthBar:SetStatusBarColor(1, 0.2, 1, 1)
			elseif UnitIsUnit("target", unitFrame.guid) then
				unitFrame.healthBar:SetStatusBarColor(0.0, 1.0, 0.59, 1)
			else
				local hex, r, g, b, a = utils.GetUnitColor(unitFrame.guid)
				unitFrame.healthBar:SetStatusBarColor(r, g, b, a)
			end
		end
	elseif style == L["Fade"] then
		if full then
			unitFrame:SetAlpha(0.45)
		else
			unitFrame:SetAlpha(1)
		end
	end
end

local ui = CreateFrame("Frame", "CursiveUI", UIParent)

ui.border = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.background = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

-- 新增：目标名字背景样式（灰色半透明背景+黑色边框） by 武藤纯子酱 2026.9.3
ui.targetNameBg = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.rootBarFrame = nil
ui.targetIndicatorSize = 8
ui.padding = 2

ui.row = 1
ui.col = 1
ui.maxBarsDisplayed = false
ui.numDisplayed = 0

local function GetBarFirstSectionWidth()
	local config = Cursive.db.profile

	local size = 1
	if config.showraidicons then
		size = size + config.raidiconsize
	end
	if config.showtargetindicator then
		size = size + ui.targetIndicatorSize
	end
	if size > 0 then
		size = size + ui.padding
	end
	
	-- 新增：目标名字栏宽度 by 武藤纯子酱 2025.12.9
	if config.showtargetname then
		size = size + config.targetnamewidth + ui.padding
	end

	return size
end

local function GetBarSecondSectionWidth()
	local config = Cursive.db.profile

	if config.showhealthbar == false and config.showunitname == false then
		return 1
	end

	return config.healthwidth + ui.padding
end

local function GetBarThirdSectionWidth()
	local config = Cursive.db.profile

	return config.maxcurses * (config.curseiconsize + ui.padding)
end

local function GetBarWidth()
	return GetBarFirstSectionWidth() +
			GetBarSecondSectionWidth() +
			GetBarThirdSectionWidth()
end

local function UpdateRootBarFrame()
	local config = Cursive.db.profile

	if config.showbackdrop then
		ui.rootBarFrame:SetBackdrop(ui.background)
	else
		ui.rootBarFrame:SetBackdrop(nil)
	end

	ui.rootBarFrame:EnableMouse(not config.clickthrough)

	ui.rootBarFrame.pos = config.anchor .. config.x .. config.y .. config.scale
	ui.rootBarFrame:ClearAllPoints()
	ui.rootBarFrame:SetPoint(config.anchor, config.x, config.y)

	ui.rootBarFrame:SetScale(config.scale)

	ui.rootBarFrame.caption:SetFont(STANDARD_TEXT_FONT, Cursive.db.profile.textsize, "THINOUTLINE")
	ui.rootBarFrame.caption:SetText(Cursive.db.profile.caption)
	if Cursive.db.profile.showtitle then
		ui.rootBarFrame.caption:Show()
	else
		ui.rootBarFrame.caption:Hide()
	end

	ui.rootBarFrame:SetWidth(config.maxcol * GetBarWidth())
	-- Calculate height: title area + all rows + extra spacing
	local title_size = 12 + config.spacing
	local total_height = title_size + (config.maxrow * (config.height + config.spacing)) + config.spacing
	ui.rootBarFrame:SetHeight(total_height)
end

local function CreateRoot()
	local frame = CreateFrame("Frame", Cursive.db.profile.caption, UIParent)
	ui.rootBarFrame = frame

	frame.id = Cursive.db.profile.caption

	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)

	frame:SetScript("OnDragStart", function()
		this.lock = true
		this:StartMoving()
	end)

	frame:SetScript("OnDragStop", function()
		-- convert to best anchor depending on position
		local new_anchor = utils.GetBestAnchor(this)
		local anchor, x, y = utils.ConvertFrameAnchor(this, new_anchor)
		this:ClearAllPoints()
		this:SetPoint(anchor, UIParent, anchor, x, y)

		-- save new position
		anchor, _, _, x, y = this:GetPoint()
		Cursive.db.profile.anchor, Cursive.db.profile.x, Cursive.db.profile.y = anchor, x, y

		-- stop drag
		this:StopMovingOrSizing()
		this.lock = false

		this:ClearAllPoints()
		this:SetPoint(anchor, x, y)
	end)

	-- create title text
	frame.caption = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
	frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -2)
	frame.caption:SetTextColor(1, 1, 1, 1)

	UpdateRootBarFrame()

	frame:Show()

	return frame
end

ui.unitFrames = {} -- holds all unitFrames for all columns/rows

Cursive.UpdateFramesFromConfig = function()
	for col, rows in pairs(ui.unitFrames) do
		for row, unitFrame in pairs(rows) do
			if unitFrame and unitFrame:IsShown() then
				unitFrame:Hide()
			end
		end
	end

	if ui.rootBarFrame then
		UpdateRootBarFrame()
	end

	-- after 3 seconds reset the unit frames so all changes are applied
	Cursive:ScheduleEvent("resetUnitFrames", Cursive.ResetUnitFrames, 3)
end

Cursive.ResetUnitFrames = function()
	-- hide all existing unit frames
	for col, rows in pairs(ui.unitFrames) do
		for row, unitFrame in pairs(rows) do
			if unitFrame and unitFrame:IsShown() then
				unitFrame:Hide()
			end
		end
	end
	-- clear cached frames so they are recreated
	ui.unitFrames = {}
end

ui.BarEnter = function()
	if this.parent.healthBar then
		this.parent.healthBar.border:SetBackdropBorderColor(1, 1, 1, 1)
	end
	this.parent.hover = true

  SetMouseoverUnit(this.parent.guid)
	GameTooltip_SetDefaultAnchor(GameTooltip, this)
	GameTooltip:SetUnit(this.parent.guid)
	GameTooltip:Show()
end

ui.BarLeave = function()
	this.parent.hover = false
  SetMouseoverUnit()
	GameTooltip:Hide()
end

ui.BarUpdate = function()
	if not this.guid or this.guid == 0 then
		this:Hide()
		return
	end

	if (this.tick or 1) > GetTime() then
		return
	else
		this.tick = GetTime() + 0.05
	end

	-- update statusbar values if it exists
	if this.healthBar then
		this.healthBar:SetMinMaxValues(0, UnitHealthMax(this.guid))
		this.healthBar:SetValue(UnitHealth(this.guid))

		-- update health bar color
		local hex, r, g, b, a = utils.GetUnitColor(this.guid)
		this.healthBar:SetStatusBarColor(r, g, b, a)

		-- update health bar border
		if this.healthBar.border then
			if this.hover then
				this.healthBar.border:SetBackdropBorderColor(1, 1, 1, 1)
			elseif UnitAffectingCombat(this.guid) then
				this.healthBar.border:SetBackdropBorderColor(.8, .2, .2, 1)
			else
				this.healthBar.border:SetBackdropBorderColor(.2, .2, .2, 1)
			end
		end
	end
	
	-- 新增：更新目标名字 by 武藤纯子酱 2025.12.9
	if this.targetNameText then
		local targetGuid = this.guid .. "target"
		local targetExists = UnitExists(targetGuid)

		-- 修复：怪的目标更换时重置血量/背景缓存（避免沿用上一目标缓存） by 武藤纯子酱 2026.9.3
		local currentTargetGuid
		if targetExists then
			currentTargetGuid = GetUnitGUID(targetGuid) or targetGuid
		end
		if this.targetNameTargetGuid ~= currentTargetGuid then
			this.targetNameTargetGuid = currentTargetGuid
			this.targetNameHp = nil
			this.targetNameMaxHp = nil
			this.targetNameBgShown = nil

			-- 修复：目标在悬停中消失/切换时，tooltip同步隐藏或刷新 by 武藤纯子酱 2026.9.3
			if this.targetNameHovered then
				if targetExists then
					GameTooltip_SetDefaultAnchor(GameTooltip, this.targetNameFrame)
					GameTooltip:SetUnit(targetGuid)
					GameTooltip:Show()
				else
					this.targetNameHovered = false
					GameTooltip:Hide()
				end
			end
		end

		local hasTarget = false
		if targetExists then
			local targetName = UnitName(targetGuid)
			if targetName then
				hasTarget = true
				-- 如果目标是玩家自己，显示特殊标记
				if UnitIsUnit(targetGuid, "player") then
					this.targetNameText:SetText("|cFFFF0000【你】!!!|r")  -- 红色显示【YOU】!!!
					this.targetNameText:SetTextColor(1, 0, 0, 1)
				else
					-- 截断过长的名字
					if string.len(targetName) > 12 then
						targetName = string.sub(targetName, 1, 11) .. "."
					end
					this.targetNameText:SetText(targetName)

					-- 根据目标类型设置颜色
					if UnitIsPlayer(targetGuid) then
						local _, class = UnitClass(targetGuid)
						if RAID_CLASS_COLORS[class] then
							local color = RAID_CLASS_COLORS[class]
							this.targetNameText:SetTextColor(color.r, color.g, color.b, 0.8)
						else
							this.targetNameText:SetTextColor(1, 1, 1, 0.8)
						end
					else
						this.targetNameText:SetTextColor(0.8, 0.8, 0.8, 0.8)  -- NPC灰色
					end
				end
			else
				this.targetNameText:SetText("")
			end
		else
			this.targetNameText:SetText("")
		end

		-- 新增：有目标才显示背景+血量，无目标隐藏 by 武藤纯子酱 2026.9.3
		if this.targetNameOverlay then
			local shouldShowBg = hasTarget and Cursive.db.profile.showtargetnamebg
			if this.targetNameBgShown ~= shouldShowBg then
				this.targetNameBgShown = shouldShowBg
				if shouldShowBg then
					this.targetNameOverlay:Show()
				else
					this.targetNameOverlay:Hide()
				end
			end

			-- 复用现有tick刷新血量（无HP文本，仅填充比例）
			if shouldShowBg and this.targetNameHealth and targetExists then
				local maxHp = UnitHealthMax(targetGuid)
				local hp = UnitHealth(targetGuid)
				if maxHp and maxHp > 0 then
					if this.targetNameMaxHp ~= maxHp then
						this.targetNameMaxHp = maxHp
						this.targetNameHealth:SetMinMaxValues(0, maxHp)
					end
					if this.targetNameHp ~= hp then
						this.targetNameHp = hp
						this.targetNameHealth:SetValue(hp)
					end
				end
			end
		end
	end

	-- update caption text  修改 by 武藤纯子酱 2025.8.28
	local name = UnitName(this.guid)
	if name and this.nameText then
		local distance
		
		if Cursive.db.profile.showunitdistance and this.distanceText then 
			if pcall(UnitXP, "nop", "nop") then
				if not UnitXP("distanceBetween", "player", this.guid) then
					distance = "∞"
				else
					distance = string.format("%.1f", UnitXP("distanceBetween", "player", this.guid))
				end
			elseif CheckInteractDistance(this.guid, 3) then -- 9.9码（决斗）
				distance = "<9.9"
			elseif CheckInteractDistance(this.guid, 2) then -- 11.11码（交易）
				distance = "<11"
			elseif CheckInteractDistance(this.guid, 4) or CheckInteractDistance(this.guid, 1) then -- 28码（跟随和查看）
				distance = "≤28"
			else
				distance = ">28"
			end
			
			if distance then			
				this.distanceText:SetText(distance)		
			else
				this.distanceText:SetText("")					
			end
		end

		this.nameText:SetText(name)			
	end

	if this.hpText then
		local hp = UnitHealth(this.guid)
		if GetLocale() == "zhCN" then
			if hp then
				if hp >= 10000 then
					hp = math.floor(hp / 1000) / 10 .. "万"
					-- elseif hp >= 1000 then
					--	 hp = math.floor(hp / 100) / 10 .. "k"
				end
			end
		else
			-- convert hp to k if > 1000
			if hp then
				if hp >= 1000000 then
					hp = math.floor(hp / 100000) / 10 .. "m"
				elseif hp >= 1000 then
					hp = math.floor(hp / 100) / 10 .. "k"
				end
			end
		end

		-- 修改 by 武藤纯子酱 2025.8.28
		if hp and Cursive.db.profile.showunithealthpercent then
			this.hpText:SetText(string.format("%.1f%%", UnitHealth(this.guid)/UnitHealthMax(this.guid) * 100).." "..hp)
		elseif hp then
			this.hpText:SetText(hp)
		end
	end

	-- show raid icon if existing
	if this.icon then
		if GetRaidTargetIndex(this.guid) and Cursive.filter.alive(this.guid) then
			SetRaidTargetIconTexture(this.icon, GetRaidTargetIndex(this.guid))
			this.icon:Show()
		else
			this.icon:Hide()
		end
	end

	-- update target indicator
	if this.target_left then
		if UnitIsUnit("target", this.guid) then
			this.target_left:Show()
		else
			this.target_left:Hide()
		end
	end

	-- 检查是否是当前目标，如果是则设置为武僧绿 by 武藤纯子酱 2025.12.9
	if UnitIsUnit("target", this.guid) and this.healthBar then
		-- update health bar color
		local hex, r, g, b, a = utils.GetUnitColor(this.guid)
		r, g, b, a = 0.0, 1.0, 0.59, 1
		this.healthBar:SetStatusBarColor(r, g, b, a)
	end

	-- 新增：buff/debuff 位满强调（覆盖上面的颜色/边框） by 武藤纯子酱 2026.9.10
	if this.guid then
		local full = Cursive.db.profile.emphasizefullslots and HasFullBuffDebuffSlots(this.guid)
		ApplyFullSlotsEmphasis(this, full)
	end
end

ui.BarClick = function()
	if arg1 == "LeftButton" then
		TargetUnit(this.parent.guid)
	elseif arg1 == "RightButton" then
		TargetUnit(this.parent.guid)
		if (not PlayerFrame.inCombat) then
			AttackTarget()
		end
	end
end

-- 新增：目标名字点击处理，选中该单位的目标 by 武藤纯子酱 2026.9.3
ui.TargetNameClick = function()
	local unitFrame = this.unitFrame
	if not unitFrame or not unitFrame.guid then
		return
	end

	-- 使用Nampower扩展单位token解析：GUID.."target"后缀 by 武藤纯子酱 2026.9.3
	local targetGuid = unitFrame.guid .. "target"
	if not UnitExists(targetGuid) then
		return
	end

	if arg1 == "LeftButton" then
		TargetUnit(targetGuid)
	elseif arg1 == "RightButton" then
		TargetUnit(targetGuid)
		if (not PlayerFrame.inCombat) then
			AttackTarget()
		end
	end
end

-- 新增：目标名字悬停显示该单位目标的提示 by 武藤纯子酱 2026.9.3
ui.TargetNameEnter = function()
	local unitFrame = this.unitFrame
	if not unitFrame or not unitFrame.guid then
		return
	end

	local targetGuid = unitFrame.guid .. "target"
	if not UnitExists(targetGuid) then
		return
	end

	-- 修复：记录悬停状态，目标消失时由BarUpdate隐藏tooltip by 武藤纯子酱 2026.9.3
	unitFrame.targetNameHovered = true

	GameTooltip_SetDefaultAnchor(GameTooltip, this)
	GameTooltip:SetUnit(targetGuid)
	GameTooltip:Show()
end

-- 新增：离开目标名字时隐藏提示 by 武藤纯子酱 2026.9.3
ui.TargetNameLeave = function()
	if this.unitFrame then
		this.unitFrame.targetNameHovered = false
	end
	GameTooltip:Hide()
end

local function CreateBarFirstSection(unitFrame, guid)
	local config = Cursive.db.profile
	local firstSection = CreateFrame("Frame", "Cursive1stSection", unitFrame)

	if config.invertbars then
		-- When inverted, position relative to second section (rightmost)
		firstSection:SetPoint("LEFT", unitFrame.secondSection, "RIGHT", 0, 0)
	else
		-- Normal positioning (leftmost)
		firstSection:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
	end
	
	firstSection:SetWidth(GetBarFirstSectionWidth())
	firstSection:SetHeight(config.height)
	firstSection:EnableMouse(false)
	unitFrame.firstSection = firstSection
	
	if config.showtargetname then -- 新增：目标名字显示 by 武藤纯子酱 2025.12.9
		-- 修改：目标名字栏改为Button，点击可选中该单位的目标 by 武藤纯子酱 2026.9.3
		local targetNameFrame = CreateFrame("Button", "CursiveTargetNameFrame", firstSection)
		targetNameFrame:SetWidth(config.targetnamewidth)
		targetNameFrame:SetHeight(config.height)
		targetNameFrame.unitFrame = unitFrame
		
		if config.invertbars then
			targetNameFrame:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
		else
			targetNameFrame:SetPoint("LEFT", firstSection, "LEFT", 0, 0)
		end
		
		-- 新增：注册鼠标事件，点击选中/悬停提示 by 武藤纯子酱 2026.9.3
		targetNameFrame:EnableMouse(true)
		targetNameFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		targetNameFrame:SetScript("OnClick", ui.TargetNameClick)
		targetNameFrame:SetScript("OnEnter", ui.TargetNameEnter)
		targetNameFrame:SetScript("OnLeave", ui.TargetNameLeave)
		unitFrame.targetNameFrame = targetNameFrame
		unitFrame.targetNameBgShown = nil -- 新增：背景显示状态缓存 by 武藤纯子酱 2026.9.3

		-- 新增：背景层（灰色半透明底+黑色边框），血量填充叠在其上 by 武藤纯子酱 2026.9.3
		local targetNameOverlay = CreateFrame("Frame", nil, targetNameFrame)
		targetNameOverlay:SetAllPoints(targetNameFrame)
		targetNameOverlay:EnableMouse(false)
		targetNameOverlay:SetFrameLevel(targetNameFrame:GetFrameLevel() + 1)
		targetNameOverlay:SetBackdrop(ui.targetNameBg)
		targetNameOverlay:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
		targetNameOverlay:SetBackdropBorderColor(0, 0, 0, 1)
		targetNameOverlay:Hide()
		unitFrame.targetNameOverlay = targetNameOverlay

		-- 新增：绿色血量填充条（固定绿，叠在灰色半透明底上呈灰绿色） by 武藤纯子酱 2026.9.3
		local targetNameHealth = CreateFrame("StatusBar", nil, targetNameOverlay)
		-- 内缩与背景边框insets一致（2px），不覆盖黑色边框，与背景填充同高 by 武藤纯子酱 2026.9.3
		targetNameHealth:SetPoint("TOPLEFT", targetNameOverlay, "TOPLEFT", ui.targetNameBg.insets.left, -ui.targetNameBg.insets.top)
		targetNameHealth:SetPoint("BOTTOMRIGHT", targetNameOverlay, "BOTTOMRIGHT", -ui.targetNameBg.insets.right, ui.targetNameBg.insets.bottom)
		targetNameHealth:EnableMouse(false)
		targetNameHealth:SetStatusBarTexture(config.bartexture)
		targetNameHealth:SetStatusBarColor(0.15, 0.85, 0.15, 1)
		targetNameHealth:SetMinMaxValues(0, 100)
		targetNameHealth:SetValue(100)
		unitFrame.targetNameHealth = targetNameHealth

		-- 名字放独立子frame，并显式提高frame level以盖在背景/血条之上
		local targetNameTextFrame = CreateFrame("Frame", nil, targetNameFrame)
		targetNameTextFrame:SetAllPoints(targetNameFrame)
		targetNameTextFrame:EnableMouse(false)
		targetNameTextFrame:SetFrameLevel(targetNameOverlay:GetFrameLevel() + 2)
		unitFrame.targetNameTextFrame = targetNameTextFrame

		local targetNameText = targetNameTextFrame:CreateFontString(nil, "HIGH", "GameFontWhite")
		targetNameText:SetPoint("CENTER", targetNameTextFrame, "CENTER", 0, 0)
		targetNameText:SetWidth(config.targetnamewidth - 4)
		targetNameText:SetHeight(config.height - 4)
		targetNameText:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
		targetNameText:SetJustifyH("CENTER")
		targetNameText:SetTextColor(1, 1, 1, 0.8)  -- 半透明白色
		unitFrame.targetNameText = targetNameText
	end

	-- create target indicator
	if config.showtargetindicator then
		local targetLeft = firstSection:CreateTexture(nil, "OVERLAY")
		targetLeft:SetWidth(ui.targetIndicatorSize)
		targetLeft:SetHeight(8)
		if config.invertbars then
			targetLeft:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
			if config.showtargetname then -- 新增：目标名字显示 by 武藤纯子酱 2025.12.9
				targetLeft:SetPoint("RIGHT", unitFrame.targetNameText, "LEFT", -ui.padding, 0)
			else
				targetLeft:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
			end
			targetLeft:SetTexture("Interface\\AddOns\\Cursive\\img\\target-right")
		else
			--targetLeft:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
			if config.showtargetname then -- 新增：目标名字显示 by 武藤纯子酱 2025.12.9
				targetLeft:SetPoint("LEFT", unitFrame.targetNameText, "RIGHT", ui.padding, 0)
			else
				targetLeft:SetPoint("LEFT", firstSection, "LEFT", 0, 0)
			end
			targetLeft:SetTexture("Interface\\AddOns\\Cursive\\img\\target-left")
		end
		targetLeft:Hide()
		unitFrame.target_left = targetLeft
	end
	
	-- create raid icon textures
	if config.showraidicons then
		local icon = firstSection:CreateTexture(nil, "OVERLAY")
		icon:SetWidth(config.raidiconsize)
		icon:SetHeight(config.raidiconsize)
		if config.invertbars then
			icon:SetPoint("LEFT", firstSection, "LEFT", 0, 0)
		else
			icon:SetPoint("RIGHT", firstSection, "RIGHT", 0, 0)
		end
		icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		icon:Hide()
		unitFrame.icon = icon
	end

end

local function CreateBarSecondSection(unitFrame, guid)
	local config = Cursive.db.profile
	local secondSection = CreateFrame("Button", "Cursive2ndSection", unitFrame)

	if config.invertbars then
		-- When inverted, position relative to third section (which is created first)
		secondSection:SetPoint("LEFT", unitFrame.thirdSection, "RIGHT", 0, 0)
	else
		-- Normal positioning relative to first section
		secondSection:SetPoint("LEFT", unitFrame.firstSection, "RIGHT", 0, 0)
	end
	
	secondSection:SetWidth(GetBarSecondSectionWidth())
	secondSection:SetHeight(config.height)
	unitFrame.secondSection = secondSection
	secondSection.parent = unitFrame

	secondSection:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	secondSection:SetScript("OnClick", ui.BarClick)
	secondSection:SetScript("OnEnter", ui.BarEnter)
	secondSection:SetScript("OnLeave", ui.BarLeave)

	-- create health bar
	if config.showhealthbar then
		local healthBar = CreateFrame("StatusBar", "CursiveHealthBar", secondSection)
		healthBar:SetStatusBarTexture(config.bartexture)
		healthBar:SetStatusBarColor(1, .8, .2, 1)
		healthBar:SetMinMaxValues(0, 100)
		healthBar:SetValue(20)
		healthBar:SetPoint("LEFT", secondSection, "LEFT", ui.padding, 0)
		healthBar:SetWidth(config.healthwidth)
		healthBar:SetHeight(config.height)
		unitFrame.healthBar = healthBar

		local hp = healthBar:CreateFontString(nil, "HIGH", "GameFontWhite")
		hp:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", -2, -2)
		if Cursive.db.profile.showunithealthpercent then -- 修改 by 武藤纯子酱 2025.8.28
			hp:SetWidth(100)
		else
			hp:SetWidth(40)
		end
		hp:SetHeight(config.height - 4)
		hp:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
		hp:SetJustifyH("RIGHT")
		unitFrame.hpText = hp

		-- 单独设置距离框体 by 武藤纯子酱 2025.12.9
		if config.showunitdistance then
			local distanceBar = healthBar:CreateFontString(nil, "HIGH", "GameFontWhite")
			distanceBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 2, -2)
			distanceBar:SetPoint("BOTTOMRIGHT", hp, "BOTTOMLEFT", 2, 0)
			distanceBar:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
			distanceBar:SetJustifyH("LEFT")
			unitFrame.distanceText = distanceBar
		end

		if config.showunitname then
			local TargetPadding = 2; -- 在姓名版左侧显示距离 by 武藤纯子酱 2025.12.9
			if Cursive.db.profile.showunitdistance then -- 在姓名版左侧显示距离 by 武藤纯子酱 2025.12.9
				TargetPadding = 30
			end
		
			local name = healthBar:CreateFontString(nil, "HIGH", "GameFontWhite")
			name:SetPoint("TOPLEFT", healthBar, "TOPLEFT", TargetPadding, -2) -- 在姓名版左侧显示距离 by 武藤纯子酱 2025.12.9
			name:SetPoint("BOTTOMRIGHT", hp, "BOTTOMLEFT", 2, 0)
			name:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
			name:SetJustifyH("LEFT")
			unitFrame.nameText = name
		end

		-- create health bar backdrops
		if pfUI and pfUI.uf then
			pfUI.api.CreateBackdrop(healthBar)
			healthBar.border = healthBar.backdrop
		else
			healthBar:SetBackdrop(ui.background)
			healthBar:SetBackdropColor(0, 0, 0, 1)

			local border = CreateFrame("Frame", "CursiveBorder", healthBar.bar)
			border:SetBackdrop(ui.border)
			border:SetBackdropColor(.2, .2, .2, 1)
			border:SetPoint("TOPLEFT", healthBar.bar, "TOPLEFT", -2, 2)
			border:SetPoint("BOTTOMRIGHT", healthBar.bar, "BOTTOMRIGHT", 2, -2)
			healthBar.border = border
		end
	else
		if config.showunitname then
			local name = secondSection:CreateFontString(nil, "HIGH", "GameFontWhite")
			name:SetPoint("TOPLEFT", secondSection, "TOPLEFT", 2, -2)
			name:SetPoint("BOTTOMRIGHT", secondSection, "BOTTOMRIGHT", 2, 0)
			name:SetFont(STANDARD_TEXT_FONT, config.textsize, "THINOUTLINE")
			name:SetWidth(config.healthwidth)
			name:SetHeight(config.height - 4)
			name:SetJustifyH("LEFT")
			unitFrame.nameText = name
		end
	end
end

local function CreateBarThirdSection(unitFrame, guid)
	local config = Cursive.db.profile

	local thirdSection = CreateFrame("Frame", "Cursive3rdSection", unitFrame)

	if config.invertbars then
		-- When inverted, this is positioned first (leftmost)
		thirdSection:SetPoint("LEFT", unitFrame, "LEFT", 0, 0)
	else
		-- Normal positioning relative to second section
		thirdSection:SetPoint("LEFT", unitFrame.secondSection, "RIGHT", 0, 0)
	end
	
	thirdSection:SetWidth(GetBarThirdSectionWidth())
	thirdSection:SetHeight(config.height)
	thirdSection:EnableMouse(false)
	unitFrame.thirdSection = thirdSection

	-- display up to maxcurses curses
	for i = 1, config.maxcurses do
		local curse = thirdSection:CreateTexture(nil, "OVERLAY")
		curse:SetWidth(config.curseiconsize)
		curse:SetHeight(config.curseiconsize)

		if config.invertbars then
			-- When inverted, position from right to left
			local rightOffset = i * ui.padding + ((i - 1) * config.curseiconsize)
			curse:SetPoint("RIGHT", thirdSection, "RIGHT", -rightOffset, 0)
		else
			-- Normal positioning from left to right
			curse:SetPoint("LEFT", thirdSection, "LEFT", i * ui.padding + ((i - 1) * config.curseiconsize), 0)
		end

		curse.timer = thirdSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		curse.timer:SetFontObject(GameFontHighlight)
		curse.timer:SetFont(STANDARD_TEXT_FONT, config.cursetimersize, "OUTLINE")
		curse.timer:SetTextColor(1, 1, 1)
		curse.timer:SetAllPoints(curse)

		curse.timer:Hide()
		curse:Hide()
		unitFrame["curse" .. i] = curse
	end
end

local function CreateBar(row, col, guid)
	local unitFrame = CreateFrame("Frame", "CursiveUnitFrame", ui.rootBarFrame)
	unitFrame.guid = guid

	unitFrame:SetScript("OnUpdate", ui.BarUpdate)

	local config = Cursive.db.profile
	local width = GetBarWidth()
	unitFrame:SetWidth(width)
	unitFrame:SetHeight(config.height)

	local config = Cursive.db.profile
	if config.invertbars then
		-- Create sections in reverse order: 3 -> 2 -> 1
		CreateBarThirdSection(unitFrame, guid)
		CreateBarSecondSection(unitFrame, guid)
		CreateBarFirstSection(unitFrame, guid)
	else
		-- Normal order: 1 -> 2 -> 3
		CreateBarFirstSection(unitFrame, guid)
		CreateBarSecondSection(unitFrame, guid)
		CreateBarThirdSection(unitFrame, guid)
	end

	ui.unitFrames[col][row] = unitFrame
	return unitFrame
end

local function GetBarCords(row, col)
	local config = Cursive.db.profile
	local x = (col - 1) * GetBarWidth()
	local y
	if config.expandupwards then
		-- For upward expansion: start from bottom with spacing, then go up
		y = config.spacing + ((row - 1) * (config.height + config.spacing))
	else
		-- For downward expansion: use original logic (don't subtract 1 to account for header)
		y = -(row * (config.height + config.spacing))
	end
	return x, y
end

local function hasAnySpellId(guid, spellIds)
	local auras = GetUnitField(guid, "aura")
	for i, spellId in pairs(auras) do
		if spellIds[spellId] then
			return spellId
		end
	end
	return nil
end

local function GetSortedCurses(guidCurses)
	-- Collect keys
	local curseNames = {}
	for key in pairs(guidCurses) do
		table.insert(curseNames, key)
	end

	if Cursive.db.profile.curseordering == L["Order applied"] then
		table.sort(curseNames, function(a, b)
			return guidCurses[a].start < guidCurses[b].start
		end)
	elseif Cursive.db.profile.curseordering == L["Expiring soonest -> latest"] then
		table.sort(curseNames, function(a, b)
			return Cursive.curses:TimeRemaining(guidCurses[a]) < Cursive.curses:TimeRemaining(guidCurses[b])
		end)
	elseif Cursive.db.profile.curseordering == L["Expiring latest -> soonest"] then
		table.sort(curseNames, function(a, b)
			return Cursive.curses:TimeRemaining(guidCurses[a]) > Cursive.curses:TimeRemaining(guidCurses[b])
		end)
	end

	local i = 0
	return function()
		i = i + 1
		local key = curseNames[i]
		if key then
			return key, guidCurses[key]
		end
	end
end

local function DisplayGuid(guid)
	if not ui.unitFrames[ui.col] then
		ui.unitFrames[ui.col] = {}
	end

	local unitFrame
	if ui.unitFrames[ui.col][ui.row] then
		unitFrame = ui.unitFrames[ui.col][ui.row]
		unitFrame.guid = guid
		-- 新增：目标栏状态缓存重置（复用bar分配新guid时） by 武藤纯子酱 2026.9.3
		unitFrame.targetNameHp = nil
		unitFrame.targetNameMaxHp = nil
		unitFrame.targetNameBgShown = nil
		unitFrame.targetNameTargetGuid = nil
	else
		unitFrame = CreateBar(ui.row, ui.col, guid)
		ui.unitFrames[ui.col][ui.row] = unitFrame
	end

	local x, y = GetBarCords(ui.row, ui.col)

	-- update position if required
	local config = Cursive.db.profile
	if not unitFrame.pos or unitFrame.pos ~= x .. y then
		unitFrame:ClearAllPoints()
		if config.expandupwards then
			unitFrame:SetPoint("BOTTOMLEFT", ui.rootBarFrame, "BOTTOMLEFT", x, y)
		else
			unitFrame:SetPoint("TOPLEFT", ui.rootBarFrame, "TOPLEFT", x, y)
		end
		unitFrame.pos = x .. y
	end

	-- check for shared debuffs
	for sharedDebuffKey, guids in pairs(Cursive.curses.sharedDebuffGuids) do
		if guids[guid] then
			local sharedDebuffSpellIds = Cursive.curses.sharedDebuffs[sharedDebuffKey]
			local spellId = hasAnySpellId(guid, sharedDebuffSpellIds)
			if spellId ~= nil then
				-- add curse to curses
				Cursive.curses:ApplySharedCurse(sharedDebuffKey, spellId, guid, GetTime())
				-- remove guid
				Cursive.curses.sharedDebuffGuids[sharedDebuffKey][guid] = nil
			end
		end
	end

	-- update curses
	local curseNumber = 1

	-- make sure old curses are hidden
	for i = 1, Cursive.db.profile.maxcurses do
		local curse = unitFrame["curse" .. i]
		curse:Hide()
		curse.timer:Hide()
	end

	local guidCurses = Cursive.curses.guids[guid]
	if guidCurses then
		for curseName, curseData in GetSortedCurses(guidCurses) do
			if curseNumber > Cursive.db.profile.maxcurses then
				break
			end

			local remaining = Cursive.curses:TimeRemaining(curseData)
			local curse = unitFrame["curse" .. curseNumber]
			if remaining >= 0 then
				local texture = nil -- 修改，对于共享debuff支持图标显示 by 武藤纯子酱 2026.6.4
				if curseData.currentPlayer == false then
					local spellIconID = GetSpellRecField(curseData.spellID, "spellIconID")
					if spellIconID then
						texture = GetSpellIconTexture(spellIconID)
					end
				else
					if Cursive.curses.trackedCurseIds[curseData.spellID] then
						texture = Cursive.curses.trackedCurseIds[curseData.spellID].texture
					end
				end
				if texture then
					curse:SetTexture(texture)
				end

				if curseData["currentPlayer"] == false then
					curse:SetDesaturated(true); -- desaturate if not applied by current player
				else
					curse:SetDesaturated(false); -- saturate if applied by current player
				end

				-- curse:SetTexCoord(.078, .92, .079, .937) rounded icons
				curse.timer:SetText(remaining)
				curse.timer:Show()
				curse:Show()

				if remaining < 1 then
					if Cursive.curses:ShouldPlayExpiringSound(curseName, guid) then
						PlaySoundFile("Interface\\AddOns\\Cursive\\sounds\\expiring.mp3")
					end
				elseif Cursive.curses:HasRequestedExpiringSound(curseName, guid) then
					Cursive.curses:EnableExpiringSound(curseName, guid)
				end
				curseNumber = curseNumber + 1
			end
		end
	end

	unitFrame:Show()
	ui.numDisplayed = ui.numDisplayed + 1

	local config = Cursive.db.profile

	-- update row/col
	ui.row = ui.row + 1
	if ui.row > config.maxrow then
		ui.row = 1
		ui.col = ui.col + 1
		if ui.col > config.maxcol then
			ui.maxBarsDisplayed = true
		end
	end
end

local function CheckForCleanup(guid, time)
	local active = UnitExists(guid) and Cursive.filter.alive(guid)
	if active then
		local old = GetTime() - time >= 900 -- >= 15 minutes old
		if old and not UnitIsVisible(guid) then
			active = false
		end
	end

	if not active then
		-- remove from core
		Cursive.core.remove(guid)
		-- remove from curses
		Cursive.curses:RemoveGuid(guid)

		-- remove from sharedDebuffGuids
		for sharedDebuffKey, guids in pairs(Cursive.curses.sharedDebuffGuids) do
			if guids[guid] then
				Cursive.curses.sharedDebuffGuids[sharedDebuffKey][guid] = nil
			end
		end
	end
end

local shouldDisplayGuids = {};
local displayedGuids = {};

ui:SetAllPoints()
ui:SetScript("OnUpdate", function()
	local config = Cursive.db.profile

	if not config.enabled then
		return
	end

	if (this.tick or 1) > GetTime() then
		return
	else
		this.tick = GetTime() + 0.1
	end

	if not ui.rootBarFrame then
		ui.rootBarFrame = CreateRoot()
	end

	-- skip if locked (due to moving)
	if ui.rootBarFrame.lock then
		return
	end

	-- reset display data
	ui.row = 1
	ui.col = 1
	ui.maxBarsDisplayed = false
	ui.numDisplayed = 0

	-- clear shouldDisplayGuids
	for guid, _ in pairs(shouldDisplayGuids) do
		shouldDisplayGuids[guid] = nil
	end

	-- clear displayedGuids
	for guid, _ in pairs(displayedGuids) do
		displayedGuids[guid] = nil
	end

	-- run through all guids and fill with bars
	local title_size = 12 + config.spacing

	local topMaxHp = 0
	local secondMaxHp = 0
	local thirdMaxHp = 0

	local topMaxGuid = 0
	local secondMaxGuid = 0
	local thirdMaxGuid = 0

	local numDisplayable = 0

	local averageMaxHp = 0

	local currentTargetGuid = GetUnitGUID("target")

	if config.sortbydistance then
		-- 新增：全部单位（含团队标记）统一按距离近→远排序 by 武藤纯子酱 2026.9.10
		local ordered = {}
		local handled = {}

		-- consider raid marks
		for i = 8, 1, -1 do
			local guid = GetUnitGUID("mark" .. i)
			if guid and not handled[guid] then
				handled[guid] = true
				if Cursive:ShouldDisplayGuid(guid) then
					ordered[table.getn(ordered) + 1] = guid
				end
				-- don't try to display this guid again
				shouldDisplayGuids[guid] = false
			end
		end

		-- consider tracked guids
		for guid, time in pairs(Cursive.core.guids) do
			if not handled[guid] then
				handled[guid] = true
				if Cursive:ShouldDisplayGuid(guid) then
					shouldDisplayGuids[guid] = true
					ordered[table.getn(ordered) + 1] = guid
				else
					shouldDisplayGuids[guid] = false
					CheckForCleanup(guid, time)
				end
			end
		end

		-- sort by distance：支持近→远 / 远→近两种方向 by 武藤纯子酱 2026.9.10
		if Cursive.db.profile.sortdistancemode == L["Farthest -> Nearest"] then
			table.sort(ordered, function(a, b)
				return GetUnitDistance(a) > GetUnitDistance(b)
			end)
		else
			table.sort(ordered, function(a, b)
				return GetUnitDistance(a) < GetUnitDistance(b)
			end)
		end

		for _, guid in ipairs(ordered) do
			if ui.maxBarsDisplayed then
				break
			end

			if not displayedGuids[guid] then
				displayedGuids[guid] = true
				DisplayGuid(guid)
			end
		end
	else
		-- first consider raid marks
		for i = 8, 1, -1 do
			local guid = GetUnitGUID("mark" .. i)
			if guid then
				if Cursive:ShouldDisplayGuid(guid) then
					numDisplayable = numDisplayable + 1

					-- display guid
					displayedGuids[guid] = true
					DisplayGuid(guid)
					if ui.maxBarsDisplayed then
						break
					end
				end
				-- don't try to display this guid again
				shouldDisplayGuids[guid] = false
			end
		end

		for guid, time in pairs(Cursive.core.guids) do
			-- calculate shouldDisplay
			local shouldDisplay = false
			if shouldDisplayGuids[guid] == nil then
				shouldDisplay = Cursive:ShouldDisplayGuid(guid)
				shouldDisplayGuids[guid] = shouldDisplay

				if shouldDisplay then
					numDisplayable = numDisplayable + 1
				end
			else
				shouldDisplay = shouldDisplayGuids[guid]
			end

			-- calculate top 3 max hps
			if shouldDisplay then
				local maxHp = UnitHealthMax(guid)
				if maxHp > topMaxHp then
					thirdMaxHp = secondMaxHp
					thirdMaxGuid = secondMaxGuid
					secondMaxHp = topMaxHp
					secondMaxGuid = topMaxGuid
					topMaxHp = maxHp
					topMaxGuid = guid
				elseif maxHp > secondMaxHp then
					thirdMaxHp = secondMaxHp
					thirdMaxGuid = secondMaxGuid
					secondMaxHp = maxHp
					secondMaxGuid = guid
				elseif maxHp > thirdMaxHp then
					thirdMaxHp = maxHp
					thirdMaxGuid = guid
				end
			else
				CheckForCleanup(guid, time)
			end
		end

		-- top max hp
		if not ui.maxBarsDisplayed and numDisplayable > ui.numDisplayed and not displayedGuids[topMaxGuid] then
			displayedGuids[topMaxGuid] = true
			DisplayGuid(topMaxGuid)
		end

		-- second max hp
		if not ui.maxBarsDisplayed and numDisplayable > ui.numDisplayed and not displayedGuids[secondMaxGuid] then
			displayedGuids[secondMaxGuid] = true
			DisplayGuid(secondMaxGuid)
		end

		-- third max hp
		if not ui.maxBarsDisplayed and numDisplayable > ui.numDisplayed and not displayedGuids[thirdMaxGuid] then
			displayedGuids[thirdMaxGuid] = true

			DisplayGuid(thirdMaxGuid)
		end

		-- fill in remaining slots
		for guid, time in pairs(Cursive.core.guids) do
			if ui.maxBarsDisplayed or numDisplayable <= ui.numDisplayed then
				break
			end

			if not displayedGuids[guid] and shouldDisplayGuids[guid] == true then
				displayedGuids[guid] = true
				DisplayGuid(guid)
			end
		end

		-- if current target not yet displayed, show it at maxrow/maxcol
		if currentTargetGuid and
				shouldDisplayGuids[currentTargetGuid] and
				not displayedGuids[currentTargetGuid] and
				Cursive.db.profile.alwaysshowcurrenttarget then
			-- replace the last displayed guid with the current target
			displayedGuids[currentTargetGuid] = true
			ui.col = config.maxcol
			ui.row = config.maxrow
			DisplayGuid(currentTargetGuid)
		end
	end

	-- hide any remaining unit frames
	for col, rows in pairs(ui.unitFrames) do
		for row, unitFrame in pairs(rows) do
			if unitFrame:IsShown() then
				if not displayedGuids[unitFrame.guid] then
					unitFrame:Hide()
				else
					displayedGuids[unitFrame.guid] = nil -- avoid displaying duplicate rows
				end
			end
		end
	end

end)

Cursive.ui = ui
