cooline_theme = {
	vertical = false,
	reverse = false,
	width = 200,
	height = 18,
	statusbar = [[Interface\TargetingFrame\UI-StatusBar]],
	bgcolor = { 0, 0, 0, 0.5 },
	border = [[Interface\DialogFrame\UI-DialogBox-Border]],
	bordersize = 16,
	borderinset = 4,
	bordercolor = { 1, 1, 1, 1 },
	iconoutset = 2,
	font = [[Fonts\FZXHLJW.TTF]],
	fontsize = 10,
	fontcolor = { 1, 1, 1, 0.8 },
	spellcolor = { 0.8, 0.4, 0, 1 },
	nospellcolor = { 0, 0, 0, 1 },
	inactivealpha = 0,
	activealpha = 0.8,
	treshold = 3.0,
}

cooline_ignore_list = {
	'hearthstone',
	'炉石'
}

-- ============================================================
-- /cl 配置面板（冷却条 + 走马灯）
-- ============================================================

local cl_frame = nil
local cl_uid = 0

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
	cb:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, y)
	cb:SetScript("OnClick", function()
		set(this:GetChecked() and true or false)
	end)
	local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lbl:SetText(label)
	lbl:SetPoint("RIGHT", cb, "LEFT", -8, 0)
	cb:SetChecked(get() and 1 or nil)
	CL_SkinCheckbox(cb)
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
		local v = this:GetValue()
		val:SetText(string.format("%." .. decimals .. "f", v))
		set(v)
	end)
	val:SetText(string.format("%." .. decimals .. "f", get()))
	CL_SkinSlider(s)
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

local function CL_CreatePanel()
	cl_frame = CreateFrame("Frame", "CoolineConfigPanel", UIParent)
	tinsert(UISpecialFrames, "CoolineConfigPanel")
	cl_frame:SetWidth(380)
	cl_frame:SetHeight(490)
	cl_frame:SetPoint("CENTER", 0, 0)
	cl_frame:SetClampedToScreen(true)
	cl_frame:SetMovable(true)
	cl_frame:EnableMouse(true)
	cl_frame:RegisterForDrag("LeftButton")
	cl_frame:SetFrameStrata("DIALOG")
	cl_frame:SetScript("OnDragStart", function() this:StartMoving() end)
	cl_frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	cl_frame:Hide()

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
		cooline_theme.vertical = v
		cooline.apply_theme()
	end, "反向排列", function() return cooline_theme.reverse end, function(v)
		cooline_theme.reverse = v
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -146, "宽度", 50, 400, 1, 0, function() return cooline_theme.width end, function(v)
		cooline_theme.width = v
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -172, "高度", 8, 60, 1, 0, function() return cooline_theme.height end, function(v)
		cooline_theme.height = v
		cooline.apply_theme()
	end)
	CL_Slider(cl_frame, -198, "提醒阈值(秒)", 0, 10, 0.1, 1, function() return cooline_theme.treshold end, function(v)
		cooline_theme.treshold = v
	end)

	-- ===== 走马灯 =====
	CL_Section(cl_frame, -234, "走马灯（施法序列）")
	CL_Divider(cl_frame, -248)

	CL_Check2(cl_frame, -262, "启用走马灯", function() return CoolineZMDDB.enabled end, function(v)
		CoolineZMDDB.enabled = v
		ZMD_ApplyEnabled()
	end, "显示技能名", function() return CoolineZMDDB.name end, function(v)
		CoolineZMDDB.name = v
		ZMD_ApplyName()
	end)

	local btnLeft = CL_Button(cl_frame, "向左", "TOPLEFT", cl_frame, "TOPLEFT", 150, -288, 70, 22)
	local btnRight = CL_Button(cl_frame, "向右", "LEFT", btnLeft, "RIGHT", 8, 0, 70, 22)
	btnLeft:SetScript("OnClick", function() CoolineZMDDB.dir = "left" end)
	btnRight:SetScript("OnClick", function() CoolineZMDDB.dir = "right" end)
	local dirLabel = cl_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	dirLabel:SetText("滚动方向")
	dirLabel:SetPoint("RIGHT", btnLeft, "LEFT", -10, 0)

	local btnStageStart = CL_Button(cl_frame, "读条时", "TOPLEFT", cl_frame, "TOPLEFT", 150, -318, 70, 22)
	local btnStageFinish = CL_Button(cl_frame, "读条后", "LEFT", btnStageStart, "RIGHT", 8, 0, 70, 22)
	local stageLabel = cl_frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	stageLabel:SetText("出现时机：" .. (CoolineZMDDB.castStage == "finish" and "读条后" or "读条时"))
	stageLabel:SetPoint("RIGHT", btnStageStart, "LEFT", -10, 0)
	btnStageStart:SetScript("OnClick", function()
		CoolineZMDDB.castStage = "start"
		stageLabel:SetText("出现时机：读条时")
	end)
	btnStageFinish:SetScript("OnClick", function()
		CoolineZMDDB.castStage = "finish"
		stageLabel:SetText("出现时机：读条后")
	end)

	CL_Slider(cl_frame, -362, "滚动速度", 20, 200, 1, 0, function() return CoolineZMDDB.speed end, function(v)
		CoolineZMDDB.speed = v
	end)
	CL_Slider(cl_frame, -388, "存活时间(秒)", 2, 15, 0.5, 1, function() return CoolineZMDDB.life end, function(v)
		CoolineZMDDB.life = v
	end)
	CL_Slider(cl_frame, -414, "同名冷却(秒)", 0, 10, 0.5, 1, function() return CoolineZMDDB.sameCD end, function(v)
		CoolineZMDDB.sameCD = v
	end)

	CL_Divider(cl_frame, -450)

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
	if not cl_frame then CL_CreatePanel() end
	if cl_frame:IsVisible() then
		cl_frame:Hide()
	else
		cl_frame:Show()
	end
end
