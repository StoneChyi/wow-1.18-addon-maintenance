-- TianYan UI and time-weighted combat statistics; discovery lives in Tracker.lua.
local tracker = TianYanTracker
local bar, lines, values = nil, {}, {}
local SCAN_INTERVAL = 0.3
local lastCount, lastGroups, lastUncertain = 0, {}, 0
local isExcluded = tracker.IsExcluded
local function scanForSummons()
    lastCount, lastGroups, lastUncertain = tracker.Scan()
    return lastCount, lastGroups, lastUncertain
end
-- ========== Per-combat time-weighted averages ==========
local currentCombat = nil

local function copyGroups(groups)
    local result = {}
    for name, count in pairs(groups) do result[name] = count end
    return result
end

local function beginCombat(now, count, groups, partial, uncertain)
    if currentCombat then return end
    currentCombat = {
        started = now, sampled = now, area = 0, areas = {},
        count = count, groups = copyGroups(groups), partial = partial or false,
        uncertain = uncertain or 0, uncertainTime = 0,
    }
end

local function advanceCombat(now)
    if not currentCombat then return end
    local elapsed = math.max(0, now - currentCombat.sampled)
    currentCombat.area = currentCombat.area + currentCombat.count * elapsed
    if currentCombat.uncertain > 0 then
        currentCombat.uncertainTime = currentCombat.uncertainTime + elapsed
    end
    for name, count in pairs(currentCombat.groups) do
        currentCombat.areas[name] = (currentCombat.areas[name] or 0) + count * elapsed
    end
    currentCombat.sampled = now
end

local function combatStats(now)
    if not currentCombat then return TY_DB and TY_DB.lastCombat end
    local duration = math.max(0, now - currentCombat.started)
    local elapsed = math.max(0, now - currentCombat.sampled)
    local area = currentCombat.area + currentCombat.count * elapsed
    local averages = {}
    for name, amount in pairs(currentCombat.areas) do
        averages[name] = duration > 0 and amount / duration or 0
    end
    for name, count in pairs(currentCombat.groups) do
        averages[name] = (averages[name] or 0) + (duration > 0 and count * elapsed / duration or 0)
    end
    return {
        duration = duration, average = duration > 0 and area / duration or 0,
        averages = averages, partial = currentCombat.partial,
        uncertainTime = currentCombat.uncertainTime + (currentCombat.uncertain > 0 and elapsed or 0),
    }
end

local function finishCombat(now)
    if not currentCombat then return end
    advanceCombat(now)
    local result = combatStats(now)
    if not TY_DB then TY_DB = {} end
    TY_DB.lastCombat = result
    currentCombat = nil
end

local function recordSample(now, count, groups, uncertain)
    if UnitAffectingCombat("player") then
        if not currentCombat then
            -- Reloading during combat starts a partial record, not a full fight.
            beginCombat(now, count, groups, true, uncertain)
        else
            advanceCombat(now)
            currentCombat.count = count
            currentCombat.groups = copyGroups(groups)
            currentCombat.uncertain = uncertain or 0
        end
    elseif currentCombat then
        finishCombat(now)
    end
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

local function refreshDisplay(count, groups, uncertain)
    if not bar then return end
    local now = GetTime()
    if count == nil then count, groups, uncertain = scanForSummons() end
    lastCount, lastGroups, lastUncertain = count, groups, uncertain
    recordSample(now, count, groups, uncertain)
    updateHistory(groups)
    local stats = combatStats(now)

    lines[1]:SetText("天眼 (" .. count .. ((uncertain or 0) > 0 and "~" or "") .. ")")
    lines[1]:SetTextColor(COL_TITLE.r, COL_TITLE.g, COL_TITLE.b)
    if stats then
        local label = currentCombat and "本次均值" or "上次均值"
        local partial = (stats.partial and " *" or "") .. ((stats.uncertainTime or 0) > 0 and " ~" or "")
        lines[2]:SetText(string.format("%s: %.2f  |  %.1f秒%s", label, stats.average, stats.duration, partial))
    else
        lines[2]:SetText("战斗均值: 等待战斗")
    end
    lines[2]:SetTextColor(1.0, 0.8, 0.0)
    lines[2]:Show()

    local names = {}
    for name, _ in pairs(groups) do names[name] = true end
    if stats and stats.averages then
        for name, _ in pairs(stats.averages) do names[name] = true end
    end
    local sortedNames = {}
    for name, _ in pairs(names) do table.insert(sortedNames, name) end
    table.sort(sortedNames, function(a, b)
        local ga = (TY_DB.history and TY_DB.history[a]) or 0
        local gb = (TY_DB.history and TY_DB.history[b]) or 0
        if ga ~= gb then return ga > gb end
        return a < b
    end)

    local lineIdx = 3
    local shown = math.min(table.getn(sortedNames), MAX_LINES - 2)
    for i = 1, shown do
        local name = sortedNames[i]
        local cur = groups[name] or 0
        local hist = (TY_DB.history and TY_DB.history[name]) or 0
        lines[lineIdx]:SetText(name)
        if stats then
            local average = (stats.averages and stats.averages[name]) or 0
            values[lineIdx]:SetText(string.format("%d/%d  均%.2f", cur, hist, average))
        elseif UnitAffectingCombat("player") then
            values[lineIdx]:SetText(cur .. "/" .. hist)
        else
            values[lineIdx]:SetText(tostring(cur))
        end
        local color = cur > 0 and COL_CUR or COL_GRAY
        lines[lineIdx]:SetTextColor(color.r, color.g, color.b)
        values[lineIdx]:SetTextColor(color.r, color.g, color.b)
        lines[lineIdx]:Show()
        values[lineIdx]:Show()
        lineIdx = lineIdx + 1
    end
    for i = lineIdx, MAX_LINES do
        if lines[i] then lines[i]:Hide() end
        if values[i] then values[i]:Hide() end
    end
    bar:SetHeight(8 + (2 + shown) * 14 + 4)
end

function TY_CreateBar()
	if bar then return end

	bar = CreateFrame("Frame", "TYBar", UIParent)
	bar:SetWidth(220)
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

    lines[1]:SetWidth(118)
    lines[1]:SetHeight(14)
    lines[1]:SetJustifyH("LEFT")

	for i = 2, MAX_LINES do
		lines[i] = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lines[i]:SetPoint("TOPLEFT", lines[i-1], "BOTTOMLEFT", 0, 0)
        lines[i]:SetHeight(14)
        lines[i]:SetJustifyH("LEFT")
        if i == 2 then
            lines[i]:SetWidth(208)
        else
            lines[i]:SetWidth(100)
            values[i] = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            values[i]:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -6, -4 - (i - 1) * 14)
            values[i]:SetWidth(100)
            values[i]:SetHeight(14)
            values[i]:SetJustifyH("RIGHT")
            values[i]:SetText("")
            values[i]:Hide()
        end
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

    local resetBtn = CreateFrame("Button", "TYResetHistoryButton", bar)
    resetBtn:SetWidth(56)
    resetBtn:SetHeight(14)
    resetBtn:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -21, -3)
    resetBtn:SetBackdrop(backdrop_bar)
    resetBtn:SetBackdropColor(0.12, 0.16, 0.2, 0.9)
    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    local font = resetText:GetFont()
    if font then resetText:SetFont(font, 9) end
    resetText:SetText("清空历史")
    resetText:SetTextColor(1, 0.8, 0)
    resetBtn:SetScript("OnClick", function()
        SlashCmdList["RETY"]("")
    end)
    resetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(resetBtn, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("清空历史最高记录", 1, 0.8, 0)
        GameTooltip:AddLine("与 /rety 相同，重新开始记录历史最高数量", 1, 1, 1)
        GameTooltip:AddLine("当前存活的召唤物会立即成为新的记录", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("本次及上次战斗均值继续保留", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	bar:SetScript("OnDragStart", function() bar:StartMoving() end)
	bar:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		local p, _, rp, x, y = bar:GetPoint()
		TY_DB.pos = { point = p, relPoint = rp, x = x, y = y }
	end)

    bar:SetScript("OnEnter", function()
        GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")
        GameTooltip:SetText("天眼 - 本人召唤物", COL_TITLE.r, COL_TITLE.g, COL_TITLE.b)
        GameTooltip:AddLine("类型行：当前 / 历史最高；均 = 战斗平均数量", 1, 1, 1)
        local stats = combatStats(GetTime())
        if lastUncertain > 0 then
            GameTooltip:AddLine("当前含 " .. lastUncertain .. " 个估计记录 (~)", 1, 0.6, 0.3)
        end
        if stats then
            if (stats.uncertainTime or 0) > 0 then
                GameTooltip:AddLine(string.format("~ 有 %.1f 秒包含估计记录", stats.uncertainTime), 1, 0.6, 0.3)
            end
            if stats.partial then
                GameTooltip:AddLine("* 中途开始记录，仅统计已记录时段", 1, 0.6, 0.3)
            end
            for name, average in pairs(stats.averages or {}) do
                GameTooltip:AddLine(name .. "：平均 " .. string.format("%.2f", average), 0.8, 1, 0.8)
            end
        end
        GameTooltip:AddLine("左键拖动窗口；右键打印历史最高", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("作者：小老板娘", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
local nextUpdate = 0
updateFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now < nextUpdate then return end
    nextUpdate = now + SCAN_INTERVAL
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
		miniBtn:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
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
		refreshDisplay()
        local count = lastCount
		GameTooltip:SetText("天眼 - 召唤物统计", 0.53, 0.8, 1.0)
		GameTooltip:AddLine("当前召唤物: " .. count .. " 个", 1, 1, 0)
        local stats = combatStats(GetTime())
        if stats then
            local label = currentCombat and "本次战斗" or "上次战斗"
            GameTooltip:AddLine(string.format("%s平均: %.2f 个 (%.1f秒)", label, stats.average, stats.duration), 1, 0.8, 0)
            if stats.partial then GameTooltip:AddLine("中途开始记录，仅统计已记录时段", 1, 0.6, 0.3) end
        end
        if lastUncertain > 0 then GameTooltip:AddLine("当前含估计记录 (~)：" .. lastUncertain, 1, 0.6, 0.3) end
        if stats and (stats.uncertainTime or 0) > 0 then
            GameTooltip:AddLine(string.format("~ 有 %.1f 秒包含估计记录", stats.uncertainTime), 1, 0.6, 0.3)
        end
        GameTooltip:AddLine("平均数量包含没有召唤物的时段", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("类型行: 当前 / 历史最高，均值按战斗时长计算", 0.8, 0.8, 0.8)
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
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

tracker.Register(eventFrame)
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

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
		TY_Print("TianYan 2.1.0 loaded!")

    elseif event == "PLAYER_ENTERING_WORLD" then
        tracker.Reset()
        if currentCombat then currentCombat.partial = true end
        nextUpdate = 0
        if bar then refreshDisplay() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        local count, groups, uncertain = scanForSummons()
        beginCombat(GetTime(), count, groups, false, uncertain)
        refreshDisplay(count, groups, uncertain)
    elseif event == "PLAYER_REGEN_ENABLED" then
        finishCombat(GetTime())
        refreshDisplay()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then
        refreshDisplay()
    elseif tracker.Event(event, arg1, arg2, arg3) then
        -- Integrate immediately; the scheduled UI refresh avoids per-event scans/redraws.
        local count, groups, uncertain = tracker.Totals()
        recordSample(GetTime(), count, groups, uncertain)
        updateHistory(groups)
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


-- On-demand diagnostics only: no per-frame chat or log writes.
SLASH_TYDEBUG1 = "/tydebug"
SlashCmdList["TYDEBUG"] = function()
    refreshDisplay()
    TY_Print("TianYan 2.1.0")
    if type(GetNampowerVersion) == "function" then
        local ok, major, minor, patch = pcall(GetNampowerVersion)
        if ok then TY_Print("Nampower: " .. tostring(major) .. "." .. tostring(minor) .. "." .. tostring(patch)) end
    end
    local d, counts, registered, cache, temporary = tracker.Diagnostics()
    TY_Print("当前 " .. lastCount .. "，估计 " .. lastUncertain .. "；扫描 " .. d.scans ..
        "，事件更新 " .. d.events .. "，发现 " .. d.discovered .. "，重试 " .. d.retry)
    for name, ok in pairs(registered) do
        TY_Print(name .. ": " .. (ok and "已注册" or "不可用") .. "，收到 " .. (counts[name] or 0))
    end
    for guid, info in pairs(cache) do TY_Print(info.name .. " | " .. guid .. " | " .. info.state) end
    for _, info in pairs(temporary) do TY_Print(info.name .. " | 姓名板估计") end
end
