cooline_theme = {
	vertical = false,
	reverse = false,
	width = 200,
	height = 18,
	statusbar = [[Interface\Buttons\WHITE8X8]],
	bgcolor = { 87 / 255, 112 / 255, 122 / 255, 0.45 },
	border = [[Interface\DialogFrame\UI-DialogBox-Border]],
	bordersize = 16,
	borderinset = 4,
	bordercolor = { 1, 1, 1, 1 },
	iconoutset = 2,
	font = [[Fonts\FZXHLJW.TTF]],
	fontsize = 10,
	fontcolor = { 216 / 255, 222 / 255, 223 / 255, 1 },
	tickcolor = { 154 / 255, 181 / 255, 187 / 255, 0.7 },
	spellcolor = { 0.8, 0.4, 0, 1 },
	nospellcolor = { 0, 0, 0, 1 },
	inactivealpha = 0,
	activealpha = 1,
	treshold = 3.0,
	max_time = 600,
	icon_size = 22,
	layout = 'lanes',
	max_rows = 3,
	show_countdown = false,
}

-- Only user-adjustable theme fields belong to character SavedVariables.
local CL_ThemeKeys = {'vertical', 'reverse', 'width', 'height', 'treshold', 'max_time', 'icon_size', 'layout', 'max_rows', 'show_countdown'}
local CL_DefaultTheme = {}
for _, key in ipairs(CL_ThemeKeys) do CL_DefaultTheme[key] = cooline_theme[key] end
local function CL_Number(value, fallback, low, high)
	if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then return fallback end
	return math.max(low, math.min(high, value))
end
function Cooline_LoadSettings()
	if type(cooline_settings) ~= 'table' then cooline_settings = {} end
	local db = cooline_settings
	if type(db.show_cooline) ~= 'boolean' then db.show_cooline = true end
	if type(db.flash_enabled) ~= 'boolean' then db.flash_enabled = true end
	db.x = CL_Number(db.x, 0, -10000, 10000)
	db.y = CL_Number(db.y, -240, -10000, 10000)
	local saved = type(db.theme) == 'table' and db.theme or {}
	for _, key in ipairs(CL_ThemeKeys) do
		cooline_theme[key] = saved[key] == nil and CL_DefaultTheme[key] or saved[key]
	end
	if type(cooline_theme.vertical) ~= 'boolean' then cooline_theme.vertical = false end
	if type(cooline_theme.reverse) ~= 'boolean' then cooline_theme.reverse = false end
	if type(cooline_theme.show_countdown) ~= 'boolean' then cooline_theme.show_countdown = false end
	local vertical = cooline_theme.vertical
	cooline_theme.width = CL_Number(cooline_theme.width, vertical and 18 or 200, vertical and 8 or 50, vertical and 60 or 400)
	cooline_theme.height = CL_Number(cooline_theme.height, vertical and 200 or 18, vertical and 50 or 8, vertical and 400 or 60)
	cooline_theme.treshold = CL_Number(cooline_theme.treshold, 3, 0, 10)
	cooline_theme.icon_size = math.floor(CL_Number(cooline_theme.icon_size, 22, 12, 40) + 0.5)
	cooline_theme.max_rows = math.floor(CL_Number(cooline_theme.max_rows, 3, 1, 3) + 0.5)
	local allowed = {[60]=true, [180]=true, [300]=true, [600]=true, [900]=true, [1800]=true}
	if not allowed[cooline_theme.max_time] then cooline_theme.max_time = 600 end
	if cooline_theme.layout ~= 'lanes' and cooline_theme.layout ~= 'overlap' and cooline_theme.layout ~= 'compact' then cooline_theme.layout = 'lanes' end
end
function Cooline_SaveTheme()
	cooline_settings.theme = {}
	for _, key in ipairs(CL_ThemeKeys) do cooline_settings.theme[key] = cooline_theme[key] end
end

cooline_ignore_list = {
	'hearthstone',
	'炉石'
}

-- ============================================================
-- /cl 配置面板（冷却条 + 走马灯）
-- ============================================================

local cl_frame = nil
local cl_uid = 0
local cl_refresh = {}
local function CL_RefreshPanel()
	for _, update in ipairs(cl_refresh) do update() end
end

-- ============================================================
-- PFUI 皮肤（参考 Automaton 的 pfUI 支持写法，仅外观、不动逻辑）
-- ============================================================
local noop = function() end
local CL_pfuiEnv = nil

local function CL_GetEnv()
	if CL_pfuiEnv then return CL_pfuiEnv end
	if pfUI and type(pfUI.GetEnvironment) == "function" then
		CL_pfuiEnv = pfUI:GetEnvironment()
		return CL_pfuiEnv
	end
	return nil
end

-- 未安装 pfUI 时的扁平暗色兜底背景
local CL_FALLBACK = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 8, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- 窗口：去原生纹理后换 pfUI 扁平背景
local function CL_SkinWindow(frame)
	local penv = CL_GetEnv()
	if penv then
		penv.StripTextures(frame)
		penv.CreateBackdrop(frame, nil, true, 0.9)
	else
		frame:SetBackdrop(CL_FALLBACK)
		frame:SetBackdropColor(0.07, 0.07, 0.07, 0.9)
		frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	end
end

-- 标准按钮（UIPanelButtonTemplate）
local function CL_SkinButton(btn)
	if not btn or btn.pfUISkinned then return end
	local penv = CL_GetEnv()
	if not penv then return end
	btn.pfUISkinned = true
	penv.StripTextures(btn)
	if btn.Left then btn.Left:SetTexture(""); btn.Left.SetTexture = noop end
	if btn.Middle then btn.Middle:SetTexture(""); btn.Middle.SetTexture = noop end
	if btn.Right then btn.Right:SetTexture(""); btn.Right.SetTexture = noop end
	penv.SkinButton(btn)
end

-- 复选框
local function CL_SkinCheckbox(cb)
	if not cb or cb.pfUISkinned then return end
	local penv = CL_GetEnv()
	if not penv then return end
	cb.pfUISkinned = true
	penv.SkinCheckbox(cb, 18)
end

-- 滑块
local function CL_SkinSlider(slider)
	if not slider or slider.pfUISkinned then return end
	local penv = CL_GetEnv()
	if not penv then return end
	slider.pfUISkinned = true
	if penv.SkinSlider then
		penv.SkinSlider(slider)
	end
end

local function CL_NewName(base)
	cl_uid = cl_uid + 1
	return "CoolineConfig" .. base .. cl_uid
end

local function CL_Section(parent, y, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetText(text)
	fs:SetTextColor(1, 0.82, 0)
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 26, y)
	return fs
end

local function CL_Label(parent, y, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetText(text)
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y)
	return fs
end

local function CL_Divider(parent, y)
	local div = parent:CreateTexture(nil, "ARTWORK")
	div:SetTexture("Interface\\Buttons\\WHITE8X8")
	div:SetHeight(1)
	div:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
	div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -24, y)
	div:SetVertexColor(0.45, 0.45, 0.45, 0.5)
	return div
end

local function CL_Check(parent, y, label, get, set)
	local cb = CreateFrame("CheckButton", CL_NewName("Check"), parent, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y)
	cb:SetScript("OnClick", function() set(this:GetChecked() and true or false) end)
	local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lbl:SetText(label)
	lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
	cb:SetChecked(get() and 1 or nil)
	CL_SkinCheckbox(cb)
	tinsert(cl_refresh, function() cb:SetChecked(get() and 1 or nil) end)
	return cb
end

local function CL_Check2(parent, y, l1, g1, s1, l2, g2, s2)
	local cb1 = CreateFrame("CheckButton", CL_NewName("Check"), parent, "UICheckButtonTemplate")
	cb1:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y)
	cb1:SetScript("OnClick", function() s1(this:GetChecked() and true or false) end)
	local lbl1 = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lbl1:SetText(l1)
	lbl1:SetPoint("LEFT", cb1, "RIGHT", 6, 0)
	cb1:SetChecked(g1() and 1 or nil)
	CL_SkinCheckbox(cb1)

	local cb2 = CreateFrame("CheckButton", CL_NewName("Check"), parent, "UICheckButtonTemplate")
	cb2:SetPoint("TOPLEFT", parent, "TOPLEFT", 210, y)
	cb2:SetScript("OnClick", function() s2(this:GetChecked() and true or false) end)
	local lbl2 = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lbl2:SetText(l2)
	lbl2:SetPoint("LEFT", cb2, "RIGHT", 6, 0)
	cb2:SetChecked(g2() and 1 or nil)
	CL_SkinCheckbox(cb2)
	tinsert(cl_refresh, function()
		cb1:SetChecked(g1() and 1 or nil)
		cb2:SetChecked(g2() and 1 or nil)
	end)
end

local function CL_Slider(parent, y, label, minV, maxV, step, decimals, get, set)
	local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lbl:SetText(label)
	lbl:SetPoint("LEFT", parent, "TOPLEFT", 34, y)
	local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	val:SetPoint("RIGHT", parent, "TOPRIGHT", -30, y)
	local s = CreateFrame("Slider", CL_NewName("Slider"), parent, "OptionsSliderTemplate")
	s:SetPoint("LEFT", parent, "TOPLEFT", 150, y)
	s:SetWidth(150)
	s:SetMinMaxValues(minV, maxV)
	s:SetValueStep(step)
	s:SetValue(get())
	s:SetScript("OnValueChanged", function()
		if s.refreshing then return end
		local v = math.floor(this:GetValue() / step + 0.5) * step
		s.refreshing = true
		s:SetValue(v)
		s.refreshing = nil
		val:SetText(string.format("%." .. decimals .. "f", v))
		set(v)
	end)
	val:SetText(string.format("%." .. decimals .. "f", get()))
	CL_SkinSlider(s)
	tinsert(cl_refresh, function()
		s.refreshing = true
		s:SetValue(get())
		s.refreshing = nil
		val:SetText(string.format("%." .. decimals .. "f", get()))
	end)
	return s
end

local function CL_Button(parent, text, point, relTo, relPoint, x, y, w, h)
	local b = CreateFrame("Button", CL_NewName("Button"), parent, "UIPanelButtonTemplate")
	b:SetText(text)
	b:SetPoint(point, relTo, relPoint, x, y)
	b:SetWidth(w or 70)
	b:SetHeight(h or 22)
	CL_SkinButton(b)
	return b
end

local function CL_Choice(parent, y, label, values, labels, get, set)
	local button = CL_Button(parent, '', 'LEFT', parent, 'TOPLEFT', 150, y, 150, 22)
	local caption = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	caption:SetText(label)
	caption:SetPoint('LEFT', parent, 'TOPLEFT', 34, y)
	local function refresh()
		for i, value in ipairs(values) do
			if value == get() then button:SetText(labels[i] .. ' >'); return end
		end
	end
	button:SetScript('OnClick', function()
		for i, value in ipairs(values) do
			if value == get() then set(values[math.mod(i, table.getn(values)) + 1]); break end
		end
		refresh()
	end)
	button:SetScript('OnEnter', function()
		GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
		GameTooltip:SetText('点击切换：' .. table.concat(labels, ' / '))
		GameTooltip:Show()
	end)
	button:SetScript('OnLeave', function() GameTooltip:Hide() end)
	tinsert(cl_refresh, refresh)
	refresh()
	return button
end

local function CL_CreatePanel()
	cl_frame = CreateFrame("Frame", "CoolineConfigPanel", UIParent)
	tinsert(UISpecialFrames, "CoolineConfigPanel")
	cl_frame:SetWidth(380)
	cl_frame:SetHeight(624)
	cl_frame:SetPoint("CENTER", 0, 0)
	cl_frame:SetClampedToScreen(true)
	cl_frame:SetMovable(true)
	cl_frame:EnableMouse(true)
	cl_frame:RegisterForDrag("LeftButton")
	cl_frame:SetFrameStrata("DIALOG")
	cl_frame:SetScript("OnDragStart", function() this:StartMoving() end)
	cl_frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	cl_frame:Hide()
	cl_frame:SetScript('OnShow', function()
		CL_RefreshPanel()
		cooline.begin_preview()
	end)
	cl_frame:SetScript('OnHide', function() cooline.end_preview() end)

	CL_SkinWindow(cl_frame)

	local title = cl_frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetText("Cooline 配置")
	title:SetTextColor(1, 0.82, 0)
	title:SetPoint("TOP", 0, -16)
	CL_Divider(cl_frame, -36)

	-- ===== 冷却条 =====
	CL_Section(cl_frame, -50, "冷却条")
	CL_Divider(cl_frame, -64)

	CL_Check2(cl_frame, -78, "显示冷却条", function() return cooline_settings.show_cooline end, function(v)
		cooline_settings.show_cooline = v
		cooline.set_shown(v)
	end, "冷却结束闪烁提示", function() return cooline_settings.flash_enabled end, function(v)
		cooline_settings.flash_enabled = v
		if not v then cooline.flash:Hide() end
	end)
	CL_Check2(cl_frame, -104, "垂直方向", function() return cooline_theme.vertical end, function(v)
		if cooline_theme.vertical ~= v then
			cooline_theme.width, cooline_theme.height = cooline_theme.height, cooline_theme.width
			cooline_theme.vertical = v
		end
		cooline.apply_theme()
		CL_RefreshPanel()
	end, "反向排列", function() return cooline_theme.reverse end, function(v)
		cooline_theme.reverse = v
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -146, "长度", 50, 400, 1, 0, function() return cooline_theme.vertical and cooline_theme.height or cooline_theme.width end, function(v)
		if cooline_theme.vertical then cooline_theme.height = v else cooline_theme.width = v end
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -172, "厚度", 8, 60, 1, 0, function() return cooline_theme.vertical and cooline_theme.width or cooline_theme.height end, function(v)
		if cooline_theme.vertical then cooline_theme.width = v else cooline_theme.height = v end
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -198, "提醒阈值(秒)", 0, 10, 0.1, 1, function() return cooline_theme.treshold end, function(v)
		cooline_theme.treshold = v
		Cooline_SaveTheme()
	end)

	CL_Choice(cl_frame, -224, '最长显示时间', {60,180,300,600,900,1800},
		{'1 分钟','3 分钟','5 分钟','10 分钟','15 分钟','30 分钟'},
		function() return cooline_theme.max_time end, function(v)
			cooline_theme.max_time = v; cooline.apply_theme()
		end)
	CL_Slider(cl_frame, -250, '图标大小', 12, 40, 1, 0, function() return cooline_theme.icon_size end, function(v)
		cooline_theme.icon_size = v; cooline.apply_theme()
	end)
	CL_Choice(cl_frame, -276, '图标排列', {'lanes','overlap','compact'}, {'居中分行','单行重叠','紧凑分组'},
		function() return cooline_theme.layout end, function(v)
			cooline_theme.layout = v; cooline.apply_theme()
		end)
	CL_Slider(cl_frame, -302, '最多行数', 1, 3, 1, 0, function() return cooline_theme.max_rows end, function(v)
		cooline_theme.max_rows = v; cooline.apply_theme()
	end)

	CL_Check(cl_frame, -326, '最后10秒图标倒计时', function() return cooline_theme.show_countdown end, function(v)
		cooline_theme.show_countdown = v
		cooline.apply_theme()
	end)

	-- ===== 走马灯 =====
	CL_Section(cl_frame, -368, "走马灯（施法序列）")
	CL_Divider(cl_frame, -382)

	CL_Check2(cl_frame, -396, "启用走马灯", function() return CoolineZMDDB.enabled end, function(v)
		CoolineZMDDB.enabled = v
		ZMD_ApplyEnabled()
	end, "显示技能名", function() return CoolineZMDDB.name end, function(v)
		CoolineZMDDB.name = v
		ZMD_ApplyName()
	end)

	local btnLeft = CL_Button(cl_frame, "向左", "TOPLEFT", cl_frame, "TOPLEFT", 150, -422, 70, 22)
	local btnRight = CL_Button(cl_frame, "向右", "LEFT", btnLeft, "RIGHT", 8, 0, 70, 22)
	btnLeft:SetScript("OnClick", function() CoolineZMDDB.dir = "left" end)
	btnRight:SetScript("OnClick", function() CoolineZMDDB.dir = "right" end)
	local dirLabel = cl_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	dirLabel:SetText("滚动方向")
	dirLabel:SetPoint("RIGHT", btnLeft, "LEFT", -10, 0)

	local btnStageStart = CL_Button(cl_frame, "读条时", "TOPLEFT", cl_frame, "TOPLEFT", 150, -452, 70, 22)
	local btnStageFinish = CL_Button(cl_frame, "读条后", "LEFT", btnStageStart, "RIGHT", 8, 0, 70, 22)
	local stageLabel = cl_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	stageLabel:SetText("出现时机：" .. (CoolineZMDDB.castStage == "finish" and "读条后" or "读条时"))
	stageLabel:SetPoint("RIGHT", btnStageStart, "LEFT", -10, 0)
	tinsert(cl_refresh, function()
		stageLabel:SetText("出现时机：" .. (CoolineZMDDB.castStage == "finish" and "读条后" or "读条时"))
	end)
	btnStageStart:SetScript("OnClick", function()
		CoolineZMDDB.castStage = "start"
		stageLabel:SetText("出现时机：读条时")
	end)
	btnStageFinish:SetScript("OnClick", function()
		CoolineZMDDB.castStage = "finish"
		stageLabel:SetText("出现时机：读条后")
	end)

	CL_Slider(cl_frame, -496, "滚动速度", 20, 200, 1, 0, function() return CoolineZMDDB.speed end, function(v)
		CoolineZMDDB.speed = v
	end)
	CL_Slider(cl_frame, -522, "存活时间(秒)", 2, 15, 0.5, 1, function() return CoolineZMDDB.life end, function(v)
		CoolineZMDDB.life = v
	end)
	CL_Slider(cl_frame, -548, "同名冷却(秒)", 0, 10, 0.5, 1, function() return CoolineZMDDB.sameCD end, function(v)
		CoolineZMDDB.sameCD = v
	end)

	CL_Divider(cl_frame, -584)

	local btnClose = CreateFrame("Button", "CoolineConfigCloseButton", cl_frame, "UIPanelCloseButton")
	-- 原始锚点保留作为回退（无 pfUI 时），有 pfUI 时 SkinCloseButton 会按 backdrop 重新定位
	btnClose:SetPoint("TOPRIGHT", cl_frame, "TOPRIGHT", -4, -4)
	btnClose:SetScript("OnClick", function() cl_frame:Hide() end)

	-- pfUI 风格关闭按钮（与项目其余皮肤一致）；无 pfUI 时保持原生 UIPanelCloseButton 样式
	local penv = CL_GetEnv()
	if penv and penv.SkinCloseButton then
		penv.SkinCloseButton(btnClose, cl_frame.backdrop, -6, -6)
	end
end

SLASH_COOLINECONFIG1 = "/cl"
SLASH_COOLINECONFIG2 = "/cooline"
SlashCmdList["COOLINECONFIG"] = function()
	if not CoolineZMDDB then CoolineZMDDB = {} end
	if CoolineZMDDB.enabled == nil then CoolineZMDDB.enabled = true end
	if CoolineZMDDB.speed == nil then CoolineZMDDB.speed = 60 end
	if CoolineZMDDB.life == nil then CoolineZMDDB.life = 3 end
	if CoolineZMDDB.dir == nil then CoolineZMDDB.dir = "left" end
	if CoolineZMDDB.name == nil then CoolineZMDDB.name = false end
	if CoolineZMDDB.castStage == nil then CoolineZMDDB.castStage = "finish" end
	if CoolineZMDDB.sameCD == nil then CoolineZMDDB.sameCD = 1.5 end
	if not cl_frame then CL_CreatePanel() end
	if cl_frame:IsVisible() then
		cl_frame:Hide()
	else
		cl_frame:Show()
	end
end
