-- ============================================================
-- Cooline - 冷却计时条 + 走马灯（独立显隐控制）
-- ============================================================
cooline = CreateFrame('Button', nil, UIParent)
cooline:SetScript('OnEvent', function()
	this[event]()
end)
cooline:RegisterEvent('VARIABLES_LOADED')
cooline:EnableMouse(true)

cooline_settings = { x = 0, y = -240, flash_enabled = true, show_cooline = true }   -- 新增 show_cooline

local frame_pool = {}
local cooldowns = {}

function cooline.set_shown(shown)
	if shown then
		cooline:Show()
	else
		cooline:Hide()
	end
end

function cooline.hyperlink_name(hyperlink)
    local _, _, name = strfind(hyperlink, '|Hitem:%d+:%d+:%d+:%d+|h[[]([^]]+)[]]|h')
    return name
end

function cooline.start_cooldown(name, texture, start_time, duration, is_spell)
	for _, ignored_name in cooline_ignore_list do
		if strupper(name) == strupper(ignored_name) then
			return
		end
	end

	local end_time = start_time + duration

	-- 已按 name 作 key 去重（cooldowns[name]），去掉原先 O(N²) 的 end_time 浮点相等遍历
	cooldowns[name] = cooldowns[name] or tremove(frame_pool) or cooline.cooldown_frame()
	local frame = cooldowns[name]
	frame:SetWidth(cooline.icon_size)
	frame:SetHeight(cooline.icon_size)
	frame.icon:SetTexture(texture)
	if is_spell then
		frame:SetBackdropColor(unpack(cooline_theme.spellcolor))
	else
		frame:SetBackdropColor(unpack(cooline_theme.nospellcolor))
	end
	frame:SetAlpha(1)
	frame.end_time = end_time
	frame:Show()
end

-- 只扫描背包 + 装备槽（响应 BAG_UPDATE_COOLDOWN）
function cooline.detect_item_cooldowns()
    for bag = 0,4 do
        if GetBagName(bag) then
            for slot = 1, GetContainerNumSlots(bag) do
				local start_time, duration, enabled = GetContainerItemCooldown(bag, slot)
				if enabled == 1 then
					local name = cooline.hyperlink_name(GetContainerItemLink(bag, slot))
					if duration > 3 and duration < 3601 then
						cooline.start_cooldown(
							name,
							GetContainerItemInfo(bag, slot),
							start_time,
							duration,
							false
						)
					elseif duration == 0 then
						cooline.clear_cooldown(name)
					end
				end
            end
        end
    end

	for slot=0,19 do
		local start_time, duration, enabled = GetInventoryItemCooldown('player', slot)
		if enabled == 1 then
			local name = cooline.hyperlink_name(GetInventoryItemLink('player', slot))
			if duration > 3 and duration < 3601 then
				cooline.start_cooldown(
					name,
					GetInventoryItemTexture('player', slot),
					start_time,
					duration,
					false
				)
			elseif duration == 0 then
				cooline.clear_cooldown(name)
			end
		end
	end
end

-- 只扫描技能书（响应 SPELL_UPDATE_COOLDOWN）
function cooline.detect_spell_cooldowns()
	local _, _, offset, spell_count = GetSpellTabInfo(GetNumSpellTabs())
	local total_spells = offset + spell_count
	for id=1,total_spells do
		local start_time, duration, enabled = GetSpellCooldown(id, BOOKTYPE_SPELL)
		local name = GetSpellName(id, BOOKTYPE_SPELL)
		if enabled == 1 and duration > 2.5 then
			cooline.start_cooldown(
				name,
				GetSpellTexture(id, BOOKTYPE_SPELL),
				start_time,
				duration,
				true
			)
		elseif duration == 0 then
			cooline.clear_cooldown(name)
		end
	end
end

function cooline.detect_cooldowns()
	cooline.detect_item_cooldowns()
	cooline.detect_spell_cooldowns()
	cooline.on_update(true)
end

-- ============================================================
-- 冷却重扫防抖：战斗中 SPELL_UPDATE_COOLDOWN / BAG_UPDATE_COOLDOWN 常一帧连发多次，
-- 把 0.1s 内的连发事件合并成一次扫描，消除 CPU 尖峰
-- ============================================================
local cooline_pending_spell, cooline_pending_item = false, false
local cooline_pending_spell_at, cooline_pending_item_at = 0, 0

cooline.rescan_timer = CreateFrame('Frame')
cooline.rescan_timer:Hide()
cooline.rescan_timer:SetScript('OnUpdate', function()
	local now = GetTime()
	local did = false
	if cooline_pending_spell and now - cooline_pending_spell_at >= 0.1 then
		cooline_pending_spell = false
		cooline.detect_spell_cooldowns()
		did = true
	end
	if cooline_pending_item and now - cooline_pending_item_at >= 0.1 then
		cooline_pending_item = false
		cooline.detect_item_cooldowns()
		did = true
	end
	if did then
		cooline.on_update(true)
	end
	if not cooline_pending_spell and not cooline_pending_item then
		this:Hide()
	end
end)

function cooline.request_spell_rescan()
	cooline_pending_spell = true
	cooline_pending_spell_at = GetTime()
	cooline.rescan_timer:Show()
end

function cooline.request_item_rescan()
	cooline_pending_item = true
	cooline_pending_item_at = GetTime()
	cooline.rescan_timer:Show()
end

function cooline.cooldown_frame()
	local frame = CreateFrame('Frame', nil, cooline.border)
	frame:SetBackdrop({ bgFile=[[Interface\AddOns\cooline\backdrop.tga]] })
	frame.icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	frame.icon:SetPoint('TOPLEFT', 1, -1)
	frame.icon:SetPoint('BOTTOMRIGHT', -1, 1)
	return frame
end

local function place_H(this, offset, just)
	this:SetPoint(just or 'CENTER', cooline, 'LEFT', offset, 0)
end
local function place_HR(this, offset, just)
	this:SetPoint(just or 'CENTER', cooline, 'LEFT', cooline_theme.width - offset, 0)
end
local function place_V(this, offset, just)
	this:SetPoint(just or 'CENTER', cooline, 'BOTTOM', 0, offset)
end
local function place_VR(this, offset, just)
	this:SetPoint(just or 'CENTER', cooline, 'BOTTOM', 0, cooline_theme.height - offset)
end

function cooline.clear_cooldown(name)
	if cooldowns[name] then
		cooldowns[name]:Hide()
		tinsert(frame_pool, cooldowns[name])
		cooldowns[name] = nil
	end
end

local relevel, throt = false, 0

function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)

	return keys
end

function cooline.update_cooldown(name, frame, position, tthrot, relevel, levelMap)
	throt = min(throt, tthrot)
	frame:SetFrameStrata("LOW")
	
	if frame.end_time - GetTime() < cooline_theme.treshold then
		frame:SetFrameLevel((levelMap and levelMap[name]) or 2)
	else
		if relevel then
			frame:SetFrameLevel(random(1,5) + 2)
		end
	end
	
	cooline.place(frame, position)
end

do
	local last_update, last_relevel = GetTime(), GetTime()
	
	function cooline.show_flash(texture)
		if not cooline_settings.flash_enabled then return end
		if cooline.flash:IsVisible() and cooline.flash:GetScript('OnUpdate') then return end
		
		cooline.flash.texture:SetTexture(texture)
		cooline.flash:SetAlpha(0.75)
		cooline.flash:Show()
		
		local startTime = GetTime()
		cooline.flash:SetScript('OnUpdate', function()
			local elapsed = GetTime() - startTime
			if elapsed > 0.8 then
				this:Hide()
				this:SetScript('OnUpdate', nil)
			else
				this:SetAlpha(0.75 * (1 - elapsed / 0.8))
			end
		end)
	end
	
	function cooline.on_update(force)
		if GetTime() - last_update < throt and not force then return end
		last_update = GetTime()
		
		relevel = false
		if GetTime() - last_relevel > 0.4 then
			relevel, last_relevel = true, GetTime()
		end
		
		isactive, throt = false, 1.5

		-- 每帧只排一次序，供临近结束的冷却定位层级（替代原先每个冷却都全表排序）
		local sorted = getKeysSortedByValue(cooldowns, function(a, b) return a.end_time > b.end_time end)
		local levelMap = {}
		for i, k in ipairs(sorted) do
			levelMap[k] = i + 2
		end

		for name, frame in pairs(cooldowns) do
			local time_left = frame.end_time - GetTime()
			isactive = isactive or time_left < 60

			if time_left > 60 then
				frame:Hide()
			else
				frame:Show()
			end

			if time_left < -1 then
				throt = min(throt, 0.2)
				isactive = true
				cooline.clear_cooldown(name)
			elseif time_left < 0 then
				cooline.update_cooldown(name, frame, 0, 0, relevel, levelMap)
				local alpha = 1 + time_left
				frame:SetAlpha(alpha)
				if cooline_settings.flash_enabled and not cooline.flash:IsVisible() and time_left > -0.2 then
					cooline.show_flash(frame.icon:GetTexture())
				end
			elseif time_left < 1 then
				cooline.update_cooldown(name, frame, cooline.section * time_left, 0, relevel, levelMap)
			elseif time_left < 3 then
				cooline.update_cooldown(name, frame, cooline.section * (time_left + 1) * 0.5, 0.02, relevel, levelMap)
			elseif time_left < 10 then
				cooline.update_cooldown(name, frame, cooline.section * (time_left + 11) * 0.14286, time_left > 4 and 0.05 or 0.02, relevel, levelMap)
			elseif time_left < 30 then
				cooline.update_cooldown(name, frame, cooline.section * (time_left + 50) * 0.05, 0.06, relevel, levelMap)
			elseif time_left < 120 then
				cooline.update_cooldown(name, frame, cooline.section * (time_left + 330) * 0.011111, 0.18, relevel, levelMap)
			elseif time_left < 360 then
				cooline.update_cooldown(name, frame, cooline.section * (time_left + 1080) * 0.0041667, 1.2, relevel, levelMap)
				frame:SetAlpha(cooline_theme.activealpha)
			else
				cooline.update_cooldown(name, frame, 6 * cooline.section, 2, relevel, levelMap)
			end
		end
		cooline:SetAlpha(isactive and cooline_theme.activealpha or cooline_theme.inactivealpha)
	end
end

function cooline.style_label(fs, text, offset, just)
	fs:SetFont(cooline_theme.font, cooline_theme.fontsize)
	fs:SetTextColor(unpack(cooline_theme.fontcolor))
	fs:SetText(text)
	fs:SetWidth(cooline_theme.fontsize * 3)
	fs:SetHeight(cooline_theme.fontsize + 2)
	fs:SetShadowColor(unpack(cooline_theme.bgcolor))
	fs:SetShadowOffset(1, -1)
	fs:ClearAllPoints()
	if just then
		if cooline_theme.vertical then
			fs:SetJustifyH('CENTER')
			just = cooline_theme.reverse and ((just == 'LEFT' and 'TOP') or 'BOTTOM') or ((just == 'LEFT' and 'BOTTOM') or 'TOP')
		elseif cooline_theme.reverse then
			just = (just == 'LEFT' and 'RIGHT') or 'LEFT'
			offset = offset + ((just == 'LEFT' and 1) or -1)
			fs:SetJustifyH(just)
		else
			offset = offset + ((just == 'LEFT' and 1) or -1)
			fs:SetJustifyH(just)
		end
	else
		fs:SetJustifyH('CENTER')
	end
	cooline.place(fs, offset, just)
end

function cooline.label(text, offset, just)
	local fs = cooline.overlay:CreateFontString(nil, 'OVERLAY')
	cooline.style_label(fs, text, offset, just)
	return fs
end

-- 重新应用主题设置（宽度/高度/方向/字号等），使配置面板改动即时生效
function cooline.apply_theme()
	cooline:SetWidth(cooline_theme.width)
	cooline:SetHeight(cooline_theme.height)
	cooline.section = (cooline_theme.vertical and cooline_theme.height or cooline_theme.width) / 6
	cooline.icon_size = (cooline_theme.vertical and cooline_theme.width or cooline_theme.height) + cooline_theme.iconoutset * 2
	cooline.place = cooline_theme.vertical and (cooline_theme.reverse and place_VR or place_V) or (cooline_theme.reverse and place_HR or place_H)

	if cooline.bg then
		cooline.bg:SetTexture(cooline_theme.statusbar)
		cooline.bg:SetVertexColor(unpack(cooline_theme.bgcolor))
		if cooline_theme.vertical then
			cooline.bg:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
		else
			cooline.bg:SetTexCoord(0, 1, 0, 1)
		end
	end

	if cooline.ticks then
		local ticks = {
			{ '0', 0, 'LEFT' },
			{ '1', cooline.section, nil },
			{ '3', cooline.section * 2, nil },
			{ '5', cooline.section * 3, nil },
			{ '10', cooline.section * 4, nil },
			{ '30', cooline.section * 5, nil },
			{ '1m', cooline.section * 6, 'RIGHT' },
		}
		for i, t in ipairs(ticks) do
			if cooline.ticks[i] then
				cooline.style_label(cooline.ticks[i], t[1], t[2], t[3])
			end
		end
	end

	if ZMD_ApplyDimensions then
		ZMD_ApplyDimensions()
	end
end

function cooline.VARIABLES_LOADED()
	if type(cooline_settings) ~= 'table' then cooline_settings = {} end
	if cooline_settings.show_cooline == nil then cooline_settings.show_cooline = true end
	if cooline_settings.flash_enabled == nil then cooline_settings.flash_enabled = true end
	if cooline_settings.x == nil then cooline_settings.x = 0 end
	if cooline_settings.y == nil then cooline_settings.y = -240 end

    cooline.flash = CreateFrame('Frame', nil, UIParent)
    cooline.flash:SetWidth(64)
    cooline.flash:SetHeight(64)
    cooline.flash:SetPoint('CENTER', UIParent, 'CENTER', 0, -16)
    cooline.flash:Hide()
    
    cooline.flash.texture = cooline.flash:CreateTexture(nil, 'ARTWORK')
    cooline.flash.texture:SetAllPoints(cooline.flash)
    cooline.flash.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	cooline:SetClampedToScreen(true)
	cooline:SetMovable(true)
	cooline:RegisterForDrag('LeftButton')
	
	-- 右键点击：切换闪烁提示（普通右键），Shift+右键切换走马灯
	cooline:RegisterForClicks("RightButtonUp")
	cooline:SetScript("OnClick", function()
		if arg1 == "RightButton" then
			if IsShiftKeyDown() then
				-- 切换走马灯启用状态
				if CoolineZMDDB then
					CoolineZMDDB.enabled = not CoolineZMDDB.enabled
					if ZMD_ApplyEnabled then
						ZMD_ApplyEnabled()
					end
					if CoolineZMDDB.enabled then
						DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00走马灯: 已启用")
					else
						DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00走马灯: 已禁用")
					end
				end
			else
				-- 切换 Cooline 闪烁提示
				cooline_settings.flash_enabled = not cooline_settings.flash_enabled
				if cooline_settings.flash_enabled then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Cooline: 技能冷却闪烁提示已启用")
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Cooline: 技能冷却闪烁提示已禁用")
					cooline.flash:Hide()
				end
			end
		end
	end)
	
	function cooline:on_drag_stop()
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = UIParent:GetCenter()
		cooline_settings.x, cooline_settings.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
		this.dragging = false
	end
	
	cooline:SetScript('OnDragStart', function()
		this.dragging = true
		this:StartMoving()
	end)
	cooline:SetScript('OnDragStop', function()
		this:on_drag_stop()
	end)
	cooline:SetScript('OnUpdate', function()
		if not IsShiftKeyDown() and this.dragging then
			this:on_drag_stop()
		end
		cooline.on_update()
	end)

	cooline:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	cooline:SetWidth(cooline_theme.width)
	cooline:SetHeight(cooline_theme.height)
	cooline:SetPoint('CENTER', cooline_settings.x, cooline_settings.y)
	
	-- ★ 新增：根据设置显示/隐藏冷却条
	cooline.set_shown(cooline_settings.show_cooline)
	
	cooline.bg = cooline:CreateTexture(nil, 'ARTWORK')
	cooline.bg:SetTexture(cooline_theme.statusbar)
	cooline.bg:SetVertexColor(unpack(cooline_theme.bgcolor))
	cooline.bg:SetAllPoints(cooline)
	if cooline_theme.vertical then
		cooline.bg:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
	else
		cooline.bg:SetTexCoord(0, 1, 0, 1)
	end

	cooline.overlay = CreateFrame('Frame', nil, cooline)

	cooline.section = (cooline_theme.vertical and cooline_theme.height or cooline_theme.width) / 6
	cooline.icon_size = (cooline_theme.vertical and cooline_theme.width or cooline_theme.height) + cooline_theme.iconoutset * 2
	cooline.place = cooline_theme.vertical and (cooline_theme.reverse and place_VR or place_V) or (cooline_theme.reverse and place_HR or place_H)

	cooline.tick0 = cooline.label('0', 0, 'LEFT')
	cooline.tick1 = cooline.label('1', cooline.section)
	cooline.tick3 = cooline.label('3', cooline.section * 2)
	cooline.tick10 = cooline.label('5', cooline.section * 3)
	cooline.tick30 = cooline.label('10', cooline.section * 4)
	cooline.tick120 = cooline.label('30', cooline.section * 5)
	cooline.tick300 = cooline.label('1m', cooline.section * 6, 'RIGHT')
	
	cooline:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	cooline:RegisterEvent('BAG_UPDATE_COOLDOWN')
	cooline:SetFrameStrata("LOW")
	
	cooline.detect_cooldowns()
end

function cooline.BAG_UPDATE_COOLDOWN()
	cooline.request_item_rescan()
end

function cooline.SPELL_UPDATE_COOLDOWN()
	cooline.request_spell_rescan()
end

-- ============================================================
-- 走马灯（施法序列滚动显示）- 独立于冷却条
-- ============================================================

local ZMD_CONFIRM_WINDOW = 3.5
local ZMD_FRESH_EPS = 0.1
local ZMD_FADE_TIME = 1.0
local ZMD_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local ZMD_DEFAULTS = {
  enabled = true,
  speed = 60,
  life = 3,
  dir = "left",
  name = false,
  relativeOffX = 0,
  relativeOffY = nil,
  sameCD = 1.5,
  castStage = "finish",   -- "start"=读条/引导开始时就出现；"finish"=读条后/施法完成后出现
}

local ZMD_SPECIAL_INSTANT_SPELLS = {
  ["审判"] = true,
}

local ZMD_spellByName = {}
local ZMD_active = {}
local ZMD_pool = {}
local ZMD_allIcons = {}
local ZMD_pending = nil
local ZMD_lastSpellTime = {}
local ZMD_lastSpawnName = nil
local ZMD_lastSpawnAt = 0

-- ★ 走马灯施法检测优化（参考 Cat2 ViewMyCasts / ViewMyCastsDetailed）
--   优先使用 SuperWoW 的 UNIT_CASTEVENT：自带 sourceGuid / castState / spellId，
--   无需再钩 CastSpell / UseAction 并扫描 tooltip，也不用靠“冷却出现”来确认一次施法。
--   无 SuperWoW 时回退到原有钩子方案（ZMD_TryInstant 等）。

local ZMD_HAS_SUPERWOW = type(GetSpellNameAndRankForId) == "function"
local ZMD_spellCache = {}
local ZMD_recentCastId = nil
local ZMD_recentCastAt = 0

local function ZMD_GetPlayerGuid()
  local exists, playerGuid = UnitExists("player")
  return playerGuid
end

local function ZMD_BaseName(name)
  if not name then return nil end
  local p1 = string.find(name, "(", 1, true)
  local p2 = string.find(name, "（", 1, true)
  local cut = p1
  if p2 and (not cut or p2 < cut) then cut = p2 end
  if not cut then return name end
  return string.gsub(string.sub(name, 1, cut - 1), "%s+$", "")
end

-- 由 spellId 取得 名称 + 图标（参考 Cat2 的 GetSpellNameAndRankForId / SpellInfo 回退）
local function ZMD_GetSpellById(spellId)
  if not spellId then return nil, nil end
  if ZMD_spellCache[spellId] then
    return ZMD_spellCache[spellId].name, ZMD_spellCache[spellId].texture
  end
  local name
  if type(GetSpellNameAndRankForId) == "function" then
    name = GetSpellNameAndRankForId(spellId)
  end
  if not name and type(SpellInfo) == "function" then
    name = SpellInfo(spellId)
  end
  if not name then return nil, nil end

  local texture = ZMD_DEFAULT_ICON
  local base = ZMD_BaseName(name)
  local info = ZMD_spellByName[base]
  if info and info.texture then
    texture = info.texture
  elseif type(GetSpellRecField) == "function" and type(GetSpellIconTexture) == "function" then
    local ok, iconId = pcall(GetSpellRecField, spellId, "spellIconID")
    if ok and iconId then
      local ok2, tex = pcall(GetSpellIconTexture, iconId)
      if ok2 and tex then texture = tex end
    end
  end
  ZMD_spellCache[spellId] = { name = name, texture = texture }
  return name, texture
end

-- 仅显示玩家主动施法（过滤被动 / 触发效果），参考 ViewMyCasts.IsPlayerActiveSpell
local function ZMD_IsPlayerActiveSpell(spellId)
  local name = ZMD_GetSpellById(spellId)
  if not name then return false end
  local info = ZMD_spellByName[ZMD_BaseName(name)]
  if info and info.index and type(IsPassiveSpell) == "function" then
    local ok, isPassive = pcall(IsPassiveSpell, info.index, BOOKTYPE_SPELL)
    if ok and isPassive then return false end
  end
  return true
end

local function ZMD_Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffff00走马灯|r：" .. msg)
end

local function ZMD_Debug(msg)
  if CoolineZMDDB and CoolineZMDDB.debug then
    ZMD_Print("|cffff8080调试|r " .. msg)
  end
end

local function ZMD_InitDB()
  if not CoolineZMDDB then CoolineZMDDB = {} end
  CoolineZMDDB.locked = nil
  for k, v in pairs(ZMD_DEFAULTS) do
    if CoolineZMDDB[k] == nil then
      CoolineZMDDB[k] = v
    end
  end
  if CoolineZMDDB.relativeOffY == nil then
    local height = cooline_theme and cooline_theme.height or 18
    CoolineZMDDB.relativeOffY = -height - 2
  end
end

local function ZMD_ScanSpellbook()
  ZMD_spellByName = {}
  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end
    if not ZMD_spellByName[name] then
      ZMD_spellByName[name] = {
        index = i,
        texture = GetSpellTexture(i, BOOKTYPE_SPELL),
      }
    end
    i = i + 1
  end
end

local function ZMD_FindSpell(query)
  if not query then return nil end
  if ZMD_spellByName[query] then return ZMD_spellByName[query], query end
  local p1 = string.find(query, "(", 1, true)
  local p2 = string.find(query, "（", 1, true)
  local cut = p1
  if p2 and (not cut or p2 < cut) then cut = p2 end
  if not cut then return nil end
  local base = string.gsub(string.sub(query, 1, cut - 1), "%s+$", "")
  if ZMD_spellByName[base] then return ZMD_spellByName[base], base end
  return nil
end

local function ZMD_GetIconSize()
  local height = cooline_theme and cooline_theme.height or 18
  return math.max(height, 16)
end

-- ★ 走马灯父级改为 UIParent，独立于冷却条
ZMD_anchor = CreateFrame("Frame", "CoolineZMD_Frame", UIParent)
ZMD_anchor:SetMovable(true)
ZMD_anchor:RegisterForDrag("LeftButton")
ZMD_anchor:SetFrameStrata("MEDIUM")
ZMD_anchor:EnableMouse(true)

ZMD_anchor:SetScript("OnDragStart", function()
  this:StartMoving()
end)
ZMD_anchor:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local point, _, relPoint, xOff, yOff = this:GetPoint()
  if CoolineZMDDB then
    CoolineZMDDB.relativeOffX = xOff
    CoolineZMDDB.relativeOffY = yOff
  end
end)

-- 全局启用/禁用函数
function ZMD_ApplyEnabled()
  if not ZMD_anchor then return end
  if CoolineZMDDB and CoolineZMDDB.enabled then
    ZMD_anchor:Show()
  else
    ZMD_anchor:Hide()
  end
end

-- 图标框体
local function ZMD_CreateIconFrame()
  local frame = CreateFrame("Frame", nil, ZMD_anchor)
  local size = ZMD_GetIconSize()
  frame:SetWidth(size)
  frame:SetHeight(size)
  frame.tex = frame:CreateTexture(nil, "ARTWORK")
  frame.tex:SetAllPoints(frame)
  frame.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  frame.nameText = frame:CreateFontString(nil, "OVERLAY")
  frame.nameText:SetFontObject(GameFontHighlightSmall)
  frame.nameText:SetTextColor(1, 1, 0)
  frame.nameText:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  table.insert(ZMD_allIcons, frame)
  return frame
end

local function ZMD_AcquireIcon()
  local frame = table.remove(ZMD_pool)
  if not frame then
    frame = ZMD_CreateIconFrame()
  end
  local size = ZMD_GetIconSize()
  frame:SetWidth(size)
  frame:SetHeight(size)
  frame:SetAlpha(1)
  frame:Show()
  return frame
end

local function ZMD_ReleaseIcon(frame)
  frame:Hide()
  frame:SetAlpha(1)
  frame.nameText:SetText("")
  table.insert(ZMD_pool, frame)
end

local function ZMD_MaxX()
  local width = ZMD_anchor:GetWidth()
  if width == 0 then width = 200 end
  return width - ZMD_GetIconSize()
end

local function ZMD_SpawnX()
  if CoolineZMDDB.dir == "left" then
    return ZMD_MaxX()
  end
  return 0
end

local function ZMD_PositionIcon(entry)
  entry.frame:ClearAllPoints()
  entry.frame:SetPoint("LEFT", ZMD_anchor, "LEFT", entry.x, 0)
end

local function ZMD_RemoveEntry(index)
  local entry = ZMD_active[index]
  table.remove(ZMD_active, index)
  ZMD_ReleaseIcon(entry.frame)
end

local function ZMD_SpawnIcon(name, texture)
  if not name then return end
  local cd = CoolineZMDDB.sameCD
  if cd and cd > 0 then
    local last = ZMD_lastSpellTime[name]
    local now = GetTime()
    if last and (now - last) < cd then
      ZMD_Debug("同名技能冷却中，忽略生成: " .. tostring(name))
      return
    end
    ZMD_lastSpellTime[name] = now
  end

  local frame = ZMD_AcquireIcon()
  frame.tex:SetTexture(texture or ZMD_DEFAULT_ICON)
  frame.nameText:SetText(name)
  if CoolineZMDDB.name then
    frame.nameText:Show()
  else
    frame.nameText:Hide()
  end

  local entry = {
    frame = frame,
    x = ZMD_SpawnX(),
    dieAt = GetTime() + CoolineZMDDB.life - ZMD_FADE_TIME,
    fading = false,
  }
  ZMD_PositionIcon(entry)
  table.insert(ZMD_active, entry)

  ZMD_lastSpawnName = name
  ZMD_lastSpawnAt = GetTime()
  ZMD_Debug("生成图标: " .. tostring(name))
end

local function ZMD_JustSpawned(name)
  return name == ZMD_lastSpawnName and (GetTime() - ZMD_lastSpawnAt) < 0.5
end

local function ZMD_SpawnByName(name)
  if not name then return end
  local info = ZMD_FindSpell(name)
  ZMD_SpawnIcon(name, info and info.texture or ZMD_DEFAULT_ICON)
end

local function ZMD_TryInstant(query)
  local info, name = ZMD_FindSpell(query)
  if not info then return end

  local now = GetTime()
  local start, duration = GetSpellCooldown(info.index, BOOKTYPE_SPELL)
  ZMD_Debug("按下: " .. tostring(name) .. " start=" .. tostring(start) .. " duration=" .. tostring(duration))

  if ZMD_SPECIAL_INSTANT_SPELLS[name] then
    ZMD_Debug("特殊技能（白名单）: " .. tostring(name) .. " 跳过冷却判定")
    ZMD_pending = {
      name = name,
      texture = info.texture,
      index = info.index,
      pressedAt = now,
      isSpecial = true,
    }
    return
  end

  if duration and duration > 0 and start and start >= now - ZMD_FRESH_EPS then
    ZMD_SpawnIcon(name, info.texture)
    ZMD_pending = nil
  else
    ZMD_pending = {
      name = name,
      texture = info.texture,
      index = info.index,
      pressedAt = now,
      isSpecial = false,
    }
  end
end

if not ZMD_HAS_SUPERWOW then
  -- 旧方案（无 SuperWoW 回退）：钩住施法函数并通过 Action 扫描法术名来检测施法
  hooksecurefunc("CastSpell", function(id, bookType)
    if bookType == BOOKTYPE_SPELL then
      ZMD_TryInstant(GetSpellName(id, BOOKTYPE_SPELL))
    end
  end)

  hooksecurefunc("CastSpellByName", function(name, onSelf)
    ZMD_TryInstant(name)
  end)

  if type(QueueSpellByName) == "function" then
    hooksecurefunc("QueueSpellByName", function(name)
      ZMD_TryInstant(name)
    end)
  end

  local ZMD_scanTip = CreateFrame("GameTooltip", "CoolineZMD_ScanTip", UIParent, "GameTooltipTemplate")

  -- 槽位 -> 法术名 缓存：避免每次点击动作条都做一次 tooltip 扫描（SetAction 较重）
  local ZMD_actionNameCache = {}

  local function ZMD_ScanActionName(slot)
    ZMD_scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    ZMD_scanTip:SetAction(slot)
    local name = CoolineZMD_ScanTipTextLeft1:GetText()
    ZMD_scanTip:Hide()
    return name
  end

  local function ZMD_GetActionSpellName(slot)
    local cached = ZMD_actionNameCache[slot]
    if cached ~= nil then
      return cached  -- false 表示“无名称/非技能”，直接返回，不再扫描
    end
    local name = ZMD_ScanActionName(slot)
    ZMD_actionNameCache[slot] = name or false
    return name
  end

  hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
    if GetActionText(slot) then return end
    local name = ZMD_GetActionSpellName(slot)
    if name then
      ZMD_TryInstant(name)
    end
  end)

  -- 动作条内容/分页变化、进服时清空缓存，下次点击按需重扫（而非每次点击都扫）
  local ZMD_cacheFrame = CreateFrame("Frame")
  ZMD_cacheFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  ZMD_cacheFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  ZMD_cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  ZMD_cacheFrame:SetScript("OnEvent", function()
    ZMD_actionNameCache = {}
  end)
end

local function ZMD_OnUpdate()
  local dt = arg1
  local db = CoolineZMDDB
  if not db then return end

  if ZMD_pending then
    local now = GetTime()
    if ZMD_pending.isSpecial then
      ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
      ZMD_pending = nil
    else
      local start, duration = GetSpellCooldown(ZMD_pending.index, BOOKTYPE_SPELL)
      if duration and duration > 0 and start and start >= ZMD_pending.pressedAt - ZMD_FRESH_EPS then
        ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
        ZMD_pending = nil
      elseif now - ZMD_pending.pressedAt > ZMD_CONFIRM_WINDOW then
        ZMD_pending = nil
      end
    end
  end

  local now = GetTime()
  local move = db.speed * dt
  if db.dir == "left" then move = -move end

  local i = 1
  while i <= table.getn(ZMD_active) do
    local entry = ZMD_active[i]
    if entry.fading then
      local a = 1 - (now - entry.fadeStart) / ZMD_FADE_TIME
      if a <= 0 then
        ZMD_RemoveEntry(i)
      else
        entry.frame:SetAlpha(a)
        i = i + 1
      end
    else
      entry.x = entry.x + move
      if entry.x < 0 then entry.x = 0 end
      local maxX = ZMD_MaxX()
      if entry.x > maxX then entry.x = maxX end
      ZMD_PositionIcon(entry)

      if now >= entry.dieAt then
        entry.fading = true
        entry.fadeStart = now
      end
      i = i + 1
    end
  end
end

function ZMD_ApplyDimensions()
  local width = cooline_theme and cooline_theme.width or 200
  local height = cooline_theme and cooline_theme.height or 18
  ZMD_anchor:SetWidth(width)
  ZMD_anchor:SetHeight(height)
  local size = ZMD_GetIconSize()
  for _, frame in ipairs(ZMD_allIcons) do
    frame:SetWidth(size)
    frame:SetHeight(size)
  end
  local maxX = ZMD_MaxX()
  for _, entry in ipairs(ZMD_active) do
    if entry.x > maxX then
      entry.x = maxX
      ZMD_PositionIcon(entry)
    end
  end
  local showName = CoolineZMDDB.name
  for _, frame in ipairs(ZMD_allIcons) do
    if showName then frame.nameText:Show() else frame.nameText:Hide() end
  end
end

-- ★ 走马灯位置独立于冷却条，相对于屏幕中心
local function ZMD_ApplyRelativeOffset()
  if CoolineZMDDB.relativeOffX == nil or CoolineZMDDB.relativeOffY == nil then
    local height = cooline_theme and cooline_theme.height or 18
    CoolineZMDDB.relativeOffX = 0
    CoolineZMDDB.relativeOffY = -height - 2
  end
  ZMD_anchor:ClearAllPoints()
  ZMD_anchor:SetPoint("CENTER", UIParent, "CENTER", CoolineZMDDB.relativeOffX, CoolineZMDDB.relativeOffY)
end

function ZMD_ApplyName()
  local showName = CoolineZMDDB.name
  for _, frame in ipairs(ZMD_allIcons) do
    if showName then frame.nameText:Show() else frame.nameText:Hide() end
  end
end

ZMD_anchor:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    ZMD_InitDB()
    -- ★ 如果是旧版本升级，将之前的相对偏移（相对于冷却条）转换为相对于屏幕中心
    if not CoolineZMDDB.converted_to_ui then
      local cx, cy = cooline:GetCenter()
      local sx, sy = UIParent:GetCenter()
      if cx and cy then
        local offX = CoolineZMDDB.relativeOffX or 0
        local offY = CoolineZMDDB.relativeOffY or 0
        CoolineZMDDB.relativeOffX = (cx - sx) + offX
        CoolineZMDDB.relativeOffY = (cy - sy) + offY
        CoolineZMDDB.converted_to_ui = true
      end
    end
    ZMD_ApplyDimensions()
    ZMD_ApplyRelativeOffset()
    ZMD_ApplyName()
    ZMD_ApplyEnabled()
    ZMD_ScanSpellbook()
    ZMD_anchor:SetScript("OnUpdate", ZMD_OnUpdate)
    ZMD_Print("走马灯已加载（独立于冷却条），输入 /cl 打开配置面板")
  elseif event == "SPELLS_CHANGED" then
    ZMD_ScanSpellbook()
  elseif event == "UNIT_CASTEVENT" then
    -- ★ 主检测路径（SuperWoW）：GUID 精准、自带 spellId 与 castState
    if not CoolineZMDDB or not CoolineZMDDB.enabled then return end
    local sourceGuid = arg1
    local castState = arg3
    local spellId = arg4
    if sourceGuid ~= ZMD_GetPlayerGuid() then return end
    local stage = CoolineZMDDB.castStage == "finish" and "finish" or "start"

    if castState == "START" or castState == "CHANNEL" then
      if not ZMD_IsPlayerActiveSpell(spellId) then return end
      -- 记录这一次施法，供 CAST 阶段去重 / 延迟生成
      ZMD_recentCastId = spellId
      ZMD_recentCastAt = GetTime()
      if stage == "start" then
        -- 读条/引导开始时就出现
        local name, texture = ZMD_GetSpellById(spellId)
        if name then
          ZMD_SpawnIcon(name, texture)
          ZMD_recentCastId = nil
          ZMD_recentCastAt = 0
        end
      end
      -- stage == "finish"：此时不生成，等 CAST（施法完成）再出现
    elseif castState == "CAST" then
      -- 本次施法是否已在 START/CHANNEL 阶段登记过（读条技能；瞬发往往直接发 CAST）
      local matched = (ZMD_recentCastId == spellId and GetTime() - ZMD_recentCastAt <= 60)
      if matched and stage == "start" then
        -- start 模式已在 START/CHANNEL 生成过，抑制这次 CAST 的重复生成
        ZMD_recentCastId = nil
        ZMD_recentCastAt = 0
        return
      end
      if not ZMD_IsPlayerActiveSpell(spellId) then return end
      local name, texture = ZMD_GetSpellById(spellId)
      if name then
        ZMD_SpawnIcon(name, texture)
        ZMD_recentCastId = nil
        ZMD_recentCastAt = 0
      end
    elseif castState == "FAIL" then
      ZMD_recentCastId = nil
      ZMD_recentCastAt = 0
    end
  elseif not ZMD_HAS_SUPERWOW and (event == "SPELLCAST_START" or event == "SPELLCAST_CHANNEL_START") then
    -- 旧方案（无 SuperWoW 回退）：依赖 SPELLCAST_* 事件
    if not CoolineZMDDB or not CoolineZMDDB.enabled then return end
    ZMD_Debug(event .. " arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))
    if ZMD_pending then
      ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
      ZMD_pending = nil
    else
      local evName = arg1
      if event == "SPELLCAST_CHANNEL_START" then evName = arg2 end
      if evName and ZMD_FindSpell(evName) and not ZMD_JustSpawned(evName) then
        ZMD_SpawnByName(evName)
      end
    end
  end
end)
ZMD_anchor:RegisterEvent("PLAYER_LOGIN")
ZMD_anchor:RegisterEvent("SPELLS_CHANGED")
ZMD_anchor:RegisterEvent("UNIT_CASTEVENT")
ZMD_anchor:RegisterEvent("SPELLCAST_START")
ZMD_anchor:RegisterEvent("SPELLCAST_CHANNEL_START")

-- ============================================================
-- 走马灯集成结束
-- ============================================================
