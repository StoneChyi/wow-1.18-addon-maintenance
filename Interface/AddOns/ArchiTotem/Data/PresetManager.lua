-- ArchiTotem 图腾组合管理模块
-- 包含图腾组合管理界面的逻辑

local L = ArchiTotemLocale

-- ===================== 滚动支持 =====================
-- 配置
local ARCHITOTEM_PRESET_BUTTON_HEIGHT = 30  -- 统一高度+间距
local ARCHITOTEM_PRESET_MAX_BUTTONS = 100   -- 允许的最大按钮数
local presetScrollOffset = 0               -- 当前滚动偏移(像素)
local presetScaleInternalUpdate = false    -- 防止滑块回写时触发递归

-- 重新锚定缩放滑块，避免锚点失效导致看不见
local function ArchiTotem_ReanchorScaleSlider()
	local slider = _G["ArchiTotemPresetScaleSlider"]
	local list = _G["ArchiTotemPresetScrollFrame"]
	if not slider or not list then return end
	slider:ClearAllPoints()
	-- 贴在列表右侧，留出间距
	slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 32, 0)
	slider:Show()
end

-- 防止缩放后界面跑出屏幕
local function ArchiTotem_ClampPresetFrameToScreen()
	local frame = _G["ArchiTotemPresetFrame"]
	if not frame or not UIParent then return end
	frame:SetClampedToScreen(true)
	frame:SetClampRectInsets(0, 0, 0, 0)
	local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
	if not (l and r and t and b and pw and ph) then return end
	if l < 0 or r > pw or t > ph or b < 0 then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
	end
end

-- ===================== 缩放滑块 =====================
local function ArchiTotem_PresetScale_UpdateValueText(val)
	local valueText = _G["ArchiTotemPresetScaleValue"]
	if valueText then
		valueText:SetText(string.format("%.2f", val))
	end
end

function ArchiTotem_PresetScaleSync()
	local slider = _G["ArchiTotemPresetScaleSlider"]
	if not slider or not ArchiTotem_Options or not ArchiTotem_Options["Apperance"] then return end
	ArchiTotem_ReanchorScaleSlider()
	local current = ArchiTotem_Options["Apperance"].scale or 1
	if current < 0.3 then current = 0.3 end
	if current > 3 then current = 3 end

	presetScaleInternalUpdate = true
	slider:SetValue(current)
	presetScaleInternalUpdate = false
	ArchiTotem_PresetScale_UpdateValueText(current)
end

function ArchiTotem_PresetScale_OnValueChanged(val)
	if presetScaleInternalUpdate then return end
	local slider = _G["ArchiTotemPresetScaleSlider"]
	-- 某些情况下 OnValueChanged 会先抛出 0/空值, 退回到滑块当前值防止被误判为 0
	if (val == nil or val == 0) and slider and slider.GetValue then
		val = slider:GetValue()
	end

	local v = tonumber(val) or 1
	local minV, maxV = 0.3, 3
	if slider and slider.GetMinMaxValues then
		local mn, mx = slider:GetMinMaxValues()
		if mn then minV = mn end
		if mx then maxV = mx end
	end
	if v < minV then v = minV end
	if v > maxV then v = maxV end

	-- 低于 1 的区间按 0.01 步长量化，确保 1→0.3 有 70 个等分
	if v < 1 then
		local step = 0.01
		v = minV + math.floor((v - minV) / step + 0.5) * step
		if v < minV then v = minV end
	end

	ArchiTotem_PresetScale_UpdateValueText(v)
	if ArchiTotem_Options and ArchiTotem_Options["Apperance"] then
		ArchiTotem_Options["Apperance"].scale = v
	end
	if ArchiTotem_SetScale then
		ArchiTotem_SetScale(v)
	end
end

local function ArchiTotem_PresetScroll_Set(offset)
	local scrollFrame = _G["ArchiTotemPresetScrollFrame"]
	local child = _G["ArchiTotemPresetScrollChild"]
	if not scrollFrame or not child then return end
	local visible = scrollFrame:GetHeight() or 1
	local total = child:GetHeight() or 0
	local maxOffset = 0
	if total > visible then maxOffset = total - visible end
	if offset < 0 then offset = 0 end
	if offset > maxOffset then offset = maxOffset end
	presetScrollOffset = offset
	scrollFrame:SetVerticalScroll(offset)

	-- 按钮状态
	local up = _G["ArchiTotemPresetScrollUp"]
	local down = _G["ArchiTotemPresetScrollDown"]
	if up then if offset <= 0 then up:Disable() else up:Enable() end end
	if down then if offset >= maxOffset then down:Disable() else down:Enable() end end
end

function ArchiTotem_PresetScroll(delta)
	-- 鼠标滚轮: delta >0 向上 -> offset 减少
	local step = ARCHITOTEM_PRESET_BUTTON_HEIGHT
	local dir = delta > 0 and -step or step
	ArchiTotem_PresetScroll_Set(presetScrollOffset + dir)
end

function ArchiTotem_ResetPresetScroll()
	presetScrollOffset = 0
	ArchiTotem_PresetScroll_Set(0)
end

-- 应用预设
function ArchiTotem_ApplyPreset(presetName)
	-- 检查预设是否存在
	if not presetName or not ArchiTotem_Options["Presets"][presetName] then
		ArchiTotem_Print("预设不存在: " .. (presetName or "nil"), "error")
		return
	end
	
	-- 检查必要的数据结构
	if not ArchiTotem_TotemData then
		ArchiTotem_Print("图腾数据未初始化", "error")
		return
	end
	
	-- 检查图腾元素数组
	if not ArchiTotem_TotemElements then
		ArchiTotem_Print("图腾元素数组未初始化", "error")
		return
	end
	
	ArchiTotem_SetPreset(presetName)
	
	-- 获取预设的显示名称
	local displayName = ArchiTotem_GetPresetDisplayName(presetName)
	ArchiTotem_Print("已切换到预设: " .. displayName)
	
	-- 可选：自动关闭管理界面
	if ArchiTotem_Options["Apperance"] and ArchiTotem_Options["Apperance"].autoClosePresetManager then
		local frame = _G["ArchiTotemPresetFrame"]
		if frame then
			frame:Hide()
		end
	end
end

-- 召唤预设图腾
function ArchiTotem_CastPresetFromManager(presetName)
	-- 检查预设是否存在
	if not presetName or not ArchiTotem_Options["Presets"][presetName] then
		ArchiTotem_Print("预设不存在: " .. (presetName or "nil"), "error")
		return
	end
	
	-- 检查是否是萨满
	if not ArchiTotem_IsShaman() then
		ArchiTotem_Print("只有萨满祭司才能召唤图腾", "error")
		return
	end
	
	ArchiTotem_CastPresetTotems(presetName)
	
	-- 获取预设的显示名称
	local displayName = ArchiTotem_GetPresetDisplayName(presetName)
	ArchiTotem_Print("召唤预设: " .. displayName)
	
	-- 自动关闭管理界面
	local frame = _G["ArchiTotemPresetFrame"]
	if frame then
		frame:Hide()
	end
end

-- 保存当前配置为新预设
function ArchiTotem_SaveCurrentAsPreset()
	-- 显示输入框让用户输入预设名称
	StaticPopup_Show("ARCHITOTEM_SAVE_PRESET")
end

-- 删除预设
function ArchiTotem_DeletePreset(presetName)
	-- 不允许删除默认预设
	if presetName == "pve" or presetName == "pvp" or presetName == "resist" or presetName == "custom" then
		ArchiTotem_Print("无法删除默认预设", "error")
		return
	end
	
	ArchiTotem_Options["Presets"][presetName] = nil
	ArchiTotem_Print("预设 '" .. presetName .. "' 已删除")
	
	-- 立即刷新UI
	ArchiTotem_RefreshPresetManagerUI()
	
	-- 重新注册按键绑定
	ArchiTotem_RegisterCustomPresetBindings()
end

-- 获取预设显示名称
function ArchiTotem_GetPresetDisplayName(presetName)
	if presetName == "pve" then
		return "PVE组合"
	elseif presetName == "pvp" then
		return "PVP组合"
	elseif presetName == "resist" then
		return "抗性组合"
	elseif presetName == "custom" then
		return "自定义组合"
	else
		return presetName
	end
end

-- 刷新预设管理界面
function ArchiTotem_RefreshPresetManagerUI()
	-- 重新创建预设按钮
	ArchiTotem_CreatePresetButtons()
	ArchiTotem_UpdateCurrentTotemDisplay()
	ArchiTotem_PresetScaleSync()
end

-- 创建预设按钮
function ArchiTotem_CreatePresetButtons()
	local scrollChild = _G["ArchiTotemPresetScrollChild"]
	local hasScroll = true
	if not scrollChild then
		-- 兼容: 未添加滚动框架时仍回退旧逻辑
		hasScroll = false
		scrollChild = _G["ArchiTotemPresetFrame"]
	end

	-- 清除旧按钮
	for i = 1, ARCHITOTEM_PRESET_MAX_BUTTONS do
		local b = _G["ArchiTotemPresetButton" .. i]
		if b then b:Hide() end
		local d = _G["ArchiTotemPresetButton" .. i .. "_Delete"]
		if d then d:Hide() end
	end

	local index = 1
	local function addPreset(name)
		ArchiTotem_CreatePresetButton(index, name, scrollChild)
		index = index + 1
	end

	-- 默认预设顺序
	for _, p in ipairs({"pve","pvp","resist","custom"}) do addPreset(p) end

	-- 自定义预设（非默认）
	for presetName, _ in pairs(ArchiTotem_Options["Presets"]) do
		if presetName ~= "pve" and presetName ~= "pvp" and presetName ~= "resist" and presetName ~= "custom" then
			addPreset(presetName)
		end
	end

	if hasScroll then
		local totalHeight = (index - 1) * ARCHITOTEM_PRESET_BUTTON_HEIGHT
		if totalHeight < 1 then totalHeight = 1 end
		scrollChild:SetHeight(totalHeight)
		-- 保持宽度
		if (scrollChild:GetWidth() or 0) < 200 then
			scrollChild:SetWidth(200)
		end
		-- 重置滚动(保留相对位置, 若总高度变小则Clamp)
		ArchiTotem_PresetScroll_Set(presetScrollOffset)
	else
		-- 没有滚动框架: 回退高度自适应
		local frame = _G["ArchiTotemPresetFrame"]
		if frame then
			local frameHeight = math.max(400, 260 + (index - 1) * ARCHITOTEM_PRESET_BUTTON_HEIGHT + 40)
			frame:SetHeight(frameHeight)
		end
	end
end

-- 创建单个预设按钮
function ArchiTotem_CreatePresetButton(index, presetName, parentFrame)
	local parent = parentFrame or _G["ArchiTotemPresetFrame"]
	local buttonName = "ArchiTotemPresetButton" .. index
	local button = _G[buttonName]
	if not button then
		button = CreateFrame("Button", buttonName, parent, "UIPanelButtonTemplate")
		button:SetWidth(160)
		button:SetHeight(24)
	else
		if button:GetParent() ~= parent then button:SetParent(parent) end
	end
	-- 位置: 按索引堆叠
	button:ClearAllPoints()
	local y = - (index - 1) * ARCHITOTEM_PRESET_BUTTON_HEIGHT
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
	button:SetText(ArchiTotem_GetPresetDisplayName(presetName))
	button:Show(); button:Enable()
	
	-- 存储预设名称
	button.presetName = presetName
	
	-- 清除所有脚本和事件
	button:SetScript("OnClick", nil)
	button:SetScript("OnEnter", nil)
	button:SetScript("OnLeave", nil)
	button:UnregisterAllEvents()
	
	-- 重新注册点击事件
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
	-- 设置点击事件 - 使用更安全的逻辑
	button:SetScript("OnClick", function()
		-- 防止重复点击
		if this.lastClickTime and GetTime() - this.lastClickTime < 0.5 then
			return
		end
		this.lastClickTime = GetTime()
		
		local currentPresetName = this.presetName
		if not currentPresetName then 
			ArchiTotem_Print("预设名称为空", "error")
			return 
		end
		
		-- 检查预设是否存在
		if not ArchiTotem_Options["Presets"][currentPresetName] then
			ArchiTotem_Print("预设不存在: " .. currentPresetName, "error")
			return
		end
		
		-- 确保必要的数据结构已初始化
		if not ArchiTotem_TotemData then
			ArchiTotem_Print("图腾数据未初始化", "error")
			return
		end
		
		if arg1 == "RightButton" and IsControlKeyDown() and 
		   currentPresetName ~= "pve" and currentPresetName ~= "pvp" and 
		   currentPresetName ~= "resist" and currentPresetName ~= "custom" then
			-- Ctrl+右键删除自定义预设
			ArchiTotem_DeletePreset(currentPresetName)
		elseif arg1 == "LeftButton" then
			if IsShiftKeyDown() then
				-- Shift+左键召唤预设
				ArchiTotem_CastPresetFromManager(currentPresetName)
			else
				-- 普通左键应用预设
				ArchiTotem_ApplyPreset(currentPresetName)
			end
		end
	end)
	
	-- 设置工具提示
	button:SetScript("OnEnter", function()
		local currentPresetName = this.presetName
		if not currentPresetName then return end
		
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(ArchiTotem_GetPresetDisplayName(currentPresetName), 1, 1, 1)
		GameTooltip:AddLine("左键: 切换到此预设", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Shift+左键: 召唤此预设", 0.8, 0.8, 0.8)
		if currentPresetName ~= "pve" and currentPresetName ~= "pvp" and currentPresetName ~= "resist" and currentPresetName ~= "custom" then
			GameTooltip:AddLine("Ctrl+右键: 删除此预设", 1, 0.5, 0.5)
		end
		GameTooltip:Show()
	end)
	
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- 处理删除按钮
	local deleteButtonName = buttonName .. "_Delete"
	local deleteButton = _G[deleteButtonName]

	local parentName = parent and parent.GetName and parent:GetName() or ""
	local isInScroll = parentName == "ArchiTotemPresetScrollChild"
	local isCustom = (presetName ~= "pve" and presetName ~= "pvp" and presetName ~= "resist" and presetName ~= "custom")

	if isCustom and isInScroll then
		-- 创建 / 复用删除按钮（仅滚动区域内的自定义预设）
		if not deleteButton then
			deleteButton = CreateFrame("Button", deleteButtonName, parent)
			deleteButton:SetWidth(20)
			deleteButton:SetHeight(20)
			deleteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
			deleteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
			deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		else
			if deleteButton:GetParent() ~= parent then deleteButton:SetParent(parent) end
		end

		deleteButton:ClearAllPoints()
		deleteButton:SetPoint("LEFT", button, "RIGHT", 2, 0)
		deleteButton:Show(); deleteButton:Enable()
		deleteButton.presetName = presetName

		-- 绑定脚本
		deleteButton:SetScript("OnClick", function()
			if this.lastClickTime and GetTime() - this.lastClickTime < 0.5 then return end
			this.lastClickTime = GetTime()
			if this.presetName then ArchiTotem_DeletePreset(this.presetName) end
		end)
		deleteButton:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("删除预设", 1, 0.5, 0.5)
			GameTooltip:Show()
		end)
		deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	else
		if deleteButton then deleteButton:Hide() end
	end
end

-- 更新图腾组合管理界面
function ArchiTotem_UpdatePresetManagerUI()
	-- 清除所有现有按钮，确保完全重建
	for i = 1, 20 do
	-- 上面循环用于旧逻辑, 现已被新的滚动创建逻辑替代, 如需彻底移除可清理。
		local button = _G["ArchiTotemPresetButton" .. i]
		if button then
			button:Hide()
			button:SetScript("OnClick", nil)
			button:SetScript("OnEnter", nil)
			button:SetScript("OnLeave", nil)
		end
		
		local deleteButton = _G["ArchiTotemPresetButton" .. i .. "_Delete"]
		if deleteButton then
			deleteButton:Hide()
			deleteButton:SetScript("OnClick", nil)
			deleteButton:SetScript("OnEnter", nil)
			deleteButton:SetScript("OnLeave", nil)
		end
	end
	
	-- 重新创建所有按钮
	ArchiTotem_CreatePresetButtons()
	
	-- 显示当前图腾配置
	ArchiTotem_UpdateCurrentTotemDisplay()

	-- 同步缩放滑块
	ArchiTotem_PresetScaleSync()
end

-- 初始化预设管理器
function ArchiTotem_InitPresetManager()
	-- 确保选项存在
	if not ArchiTotem_Options["Apperance"] then
		ArchiTotem_Options["Apperance"] = {}
	end
	
	if ArchiTotem_Options["Apperance"].autoClosePresetManager == nil then
		ArchiTotem_Options["Apperance"].autoClosePresetManager = false
	end
	if ArchiTotem_Options["Apperance"].scale == nil then
		ArchiTotem_Options["Apperance"].scale = 1
	end
	
	-- 确保组合按钮显示选项存在
	if ArchiTotem_Options["Apperance"].showpresetmanagerbutton == nil then
		ArchiTotem_Options["Apperance"].showpresetmanagerbutton = true
	end
	
	-- 设置预设管理框架的背景色
	local frame = _G["ArchiTotemPresetFrame"]
	if frame then
		-- 强制设置为黑色背景
		frame:SetBackdropColor(0, 0, 0, 0.9)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

		-- 同步并重锚缩放滑块
		ArchiTotem_PresetScaleSync()
		
		-- 设置当前图腾显示区域背景
		local currentFrame = _G["ArchiTotemCurrentFrame"]
		if currentFrame then
			-- 创建一个纯色背景纹理
			if not currentFrame.bgTexture then
				currentFrame.bgTexture = currentFrame:CreateTexture(nil, "BACKGROUND")
				currentFrame.bgTexture:SetAllPoints(currentFrame)
				currentFrame.bgTexture:SetTexture(0.05, 0.05, 0.05, 0.8)
			end
		end
	end
	
	-- 创建静态弹出窗口用于保存预设
	StaticPopupDialogs["ARCHITOTEM_SAVE_PRESET"] = {
		text = "请输入预设名称:",
		button1 = "保存",
		button2 = "取消",
		hasEditBox = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		OnShow = function()
			local editBox = getglobal(this:GetName().."EditBox")
			if editBox then
				editBox:SetText("")
				editBox:SetFocus()
			end
		end,
		OnAccept = function()
			local editBox = getglobal(this:GetParent():GetName().."EditBox")
			if editBox then
				local presetName = editBox:GetText()
				if presetName and presetName ~= "" then
					-- 检查名称是否已存在
					if ArchiTotem_Options["Presets"][presetName] then
						ArchiTotem_Print("预设名称已存在，将覆盖原预设")
					end
					ArchiTotem_SavePreset(presetName)
					ArchiTotem_RefreshPresetManagerUI()
				end
			end
		end,
		EditBoxOnEnterPressed = function()
			local editBox = getglobal(this:GetParent():GetName().."EditBox")
			if editBox then
				local presetName = editBox:GetText()
				if presetName and presetName ~= "" then
					if ArchiTotem_Options["Presets"][presetName] then
						ArchiTotem_Print("预设名称已存在，将覆盖原预设")
					end
					ArchiTotem_SavePreset(presetName)
					ArchiTotem_RefreshPresetManagerUI()
				end
			end
			this:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function()
			this:GetParent():Hide()
		end,
	}
end
