-- ArchiTotem UI模块
-- 包含UI显示、交互和布局相关功能

local _G = getfenv()
local L = ArchiTotemLocale

-- 拖拽处理
function ArchiTotem_OnDragStart()
	if IsControlKeyDown() then
		ArchiTotemFrame:StartMoving()
	end
end

function ArchiTotem_OnDragStop()
	ArchiTotemFrame:StopMovingOrSizing()
end

-- 鼠标进入事件
function ArchiTotem_OnEnter()
	-- 检查是否是一键召唤或召回按钮
	if this:GetName() == "ArchiTotemButton_AllTotems" or this:GetName() == "ArchiTotemButton_Recall" then
		if ArchiTotem_Options["Apperance"].showtooltips == true then
			GameTooltip_SetDefaultAnchor(GameTooltip, this)
			if this:GetName() == "ArchiTotemButton_AllTotems" then
				GameTooltip:SetText("一键召唤所有图腾", 1, 1, 1)
			else
				GameTooltip:SetText("召回所有图腾", 1, 1, 1)
			end
		end
		return
	end

	-- 检查是否是图腾组合管理按钮
	if this:GetName() == "ArchiTotemButton_PresetManager" then
		if ArchiTotem_Options["Apperance"].showtooltips == true then
			GameTooltip_SetDefaultAnchor(GameTooltip, this)
			GameTooltip:SetText("图腾组合管理", 1, 1, 1)
			GameTooltip:AddLine("左键: 打开/关闭组合管理", 0.5, 0.5, 0.5)
			GameTooltip:Show()
		end
		return
	end

	-- 显示图腾
	if ArchiTotem_Options["Apperance"].allonmouseover == true then
		for k, v in ArchiTotem_TotemElements do
			local threeLetterElement = string.sub(v, 1, 3)
			for i = 1, ArchiTotem_Options[threeLetterElement].max do
				_G["ArchiTotemButton_" .. v .. i]:Show()
			end
		end
	else
		local totemElement = string.sub(this:GetName(), 1, -2)
		local maxOfElement = string.sub(this:GetName(), 18, 20)
		for i = 2, ArchiTotem_Options[maxOfElement].max do
			local button = _G[totemElement .. i]
			if button then
				button:Show()
			end
		end
	end

	-- 显示工具提示
	if ArchiTotem_Options["Apperance"].showtooltips == true then
		local tooltipspellID = ArchiTotem_GetSpellId(ArchiTotem_TotemData[this:GetName()].name)
		if tooltipspellID > 0 then
			local spellName = GetSpellName(tooltipspellID, BOOKTYPE_SPELL)
			GameTooltip_SetDefaultAnchor(GameTooltip, this)
			GameTooltip:SetSpell(tooltipspellID, SpellBookFrame.bookType)

			-- 添加右键点击提示
			local elementName = string.sub(this:GetName(), 18, -2)
			local threeLetterElement = string.sub(elementName, 1, 3)
			local skipStatus = ArchiTotem_Options[threeLetterElement].skip and 
				L[elementName .. " totems skip: ON"] or L[elementName .. " totems skip: OFF"]
			GameTooltip:AddLine(" ", 1, 1, 1)
			GameTooltip:AddLine(L["右键点击切换跳过状态"], 0.5, 0.5, 0.5)
			GameTooltip:AddLine(skipStatus, 1, 1, 0)
			GameTooltip:Show()
		end
	end
end

-- 鼠标离开事件
function ArchiTotem_OnLeave()
	ArchiTotem_UpdateShown()
end

-- 鼠标点击事件
function ArchiTotem_OnClick(button)
	-- 检查是否是一键召唤按钮
	if this:GetName() == "ArchiTotemButton_AllTotems" then
		if button == "RightButton" then
			ArchiTotem_Options["Apperance"].showrecallbutton = true
			ArchiTotem_Options["Apperance"].showpresetmanagerbutton = true
			ArchiTotem_Print(L["Recall button shown"])
			ArchiTotem_Print(L["Preset manager button shown"])
			ArchiTotem_UpdateShown()
			return
		else
			ArchiTotem_CastAllTotems()
			return
		end
	end

	-- 检查是否是召回按钮
	if this:GetName() == "ArchiTotemButton_Recall" then
		if button == "RightButton" then
			ArchiTotem_Options["Apperance"].showrecallbutton = false
			ArchiTotem_Print(L["Recall button hidden"])
			ArchiTotem_UpdateShown()
			return
		else
			ArchiTotem_RecallTotems()
			return
		end
	end

	-- 检查是否是图腾组合管理按钮
	if this:GetName() == "ArchiTotemButton_PresetManager" then
		if button == "RightButton" then
			ArchiTotem_Options["Apperance"].showpresetmanagerbutton = false
			ArchiTotem_Print(L["Preset manager button hidden"])
			ArchiTotem_UpdateShown()
			return
		else
			ArchiTotem_TogglePresetManager()
			return
		end
	end

	-- 右键点击切换跳过状态
	if button == "RightButton" then
		local elementName = string.sub(this:GetName(), 18, -2)
		local threeLetterElement = string.sub(elementName, 1, 3)

		ArchiTotem_Options[threeLetterElement].skip = not ArchiTotem_Options[threeLetterElement].skip

		local statusKey = elementName .. " totems skip: " .. 
			(ArchiTotem_Options[threeLetterElement].skip and "ON" or "OFF")
		ArchiTotem_Print(L[statusKey])

		ArchiTotem_UpdateTextures()
		return
	end

	-- 处理移动图腾位置
	if IsAltKeyDown() then
		local underTotemNumber = string.sub(this:GetName(), -1, -1) - 1
		local underTotem = string.sub(this:GetName(), 1, -2) .. underTotemNumber
		if underTotemNumber > 0 then
			ArchiTotem_Switch(this:GetName(), underTotem)
			-- 实时更新图腾组合管理界面
			ArchiTotem_UpdatePresetManagerDisplay()
		end
	elseif IsControlKeyDown() then
		local overTotemNumber = string.sub(this:GetName(), -1, -1) + 1
		local overTotem = string.sub(this:GetName(), 1, -2) .. overTotemNumber
		local maxOfElement = string.sub(this:GetName(), 18, 20)
		if overTotemNumber < ArchiTotem_Options[maxOfElement].max + 1 then
			ArchiTotem_Switch(this:GetName(), overTotem)
			-- 实时更新图腾组合管理界面
			ArchiTotem_UpdatePresetManagerDisplay()
		end
	else
		ArchiTotem_CastTotem()
	end
end

-- 切换图腾组合管理界面
function ArchiTotem_TogglePresetManager()
	local frame = _G["ArchiTotemPresetFrame"]
	if frame then
		if frame:IsVisible() then
			frame:Hide()
			-- 隐藏时清除可能残留的工具提示
			GameTooltip:Hide()
		else
			-- 显示前强制刷新界面
			ArchiTotem_UpdatePresetManagerUI()
			
			-- 强制设置黑色背景
			frame:SetBackdropColor(0, 0, 0, 0.9)
			frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
			
			frame:Show()
		end
	end
end

-- 更新图腾组合管理界面
-- 注意: 该函数与 PresetManager.lua 中实现重复, 这里改为调用主实现避免维护两份
function ArchiTotem_UpdatePresetManagerUI()
	if ArchiTotem_CreatePresetButtons then
		ArchiTotem_CreatePresetButtons()
	end
	if ArchiTotem_UpdateCurrentTotemDisplay then
		ArchiTotem_UpdateCurrentTotemDisplay()
	end
end

-- 更新当前图腾显示
function ArchiTotem_UpdateCurrentTotemDisplay()
	for k, v in ArchiTotem_TotemElements do
		local buttonName = "ArchiTotemButton_" .. v .. "1"
		local totemData = ArchiTotem_TotemData[buttonName]
		if totemData then
			local displayFrame = _G["ArchiTotemCurrent_" .. v]
			if displayFrame then
				local texture = _G["ArchiTotemCurrent_" .. v .. "Texture"]
				local text = _G["ArchiTotemCurrent_" .. v .. "Text"]
				if texture and text then
					texture:SetTexture(totemData.icon)
					-- 确保字体已设置后再设置文本
					if not text:GetFont() then
						text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
					end
					local totemName = L[totemData.name] or totemData.name
					-- 截断过长的图腾名称
					if string.len(totemName) > 8 then
						totemName = string.sub(totemName, 1, 6) .. ".."
					end
					text:SetText(totemName)
				end
			end
		end
	end
end

-- 更新纹理
function ArchiTotem_UpdateTextures()
	for k, v in ArchiTotem_TotemElements do
		local threeLetterElement = string.sub(v, 1, 3)
		for i = 1, ArchiTotem_Options[threeLetterElement].max do
			local buttonName = "ArchiTotemButton_" .. v .. i
			_G[buttonName .. "Texture"]:SetTexture(ArchiTotem_TotemData[buttonName].icon)

			-- 设置跳过状态的视觉效果
			if ArchiTotem_Options[threeLetterElement].skip then
				_G[buttonName .. "Texture"]:SetAlpha(0.4)
				_G[buttonName .. "Texture"]:SetVertexColor(1, 0.3, 0.3)
			else
				_G[buttonName .. "Texture"]:SetAlpha(1.0)
				_G[buttonName .. "Texture"]:SetVertexColor(1, 1, 1)
			end
		end
	end

	-- 设置特殊按钮图标
	local allTotemsTexture = _G["ArchiTotemButton_AllTotemsTexture"]
	if allTotemsTexture then
		allTotemsTexture:SetTexture("Interface\\Icons\\Spell_Totem_WardOfDraining")
	end

	local recallTexture = _G["ArchiTotemButton_RecallTexture"]
	if recallTexture then
		recallTexture:SetTexture("Interface\\Icons\\Spell_Shaman_TotemRecall")
	end

	-- 设置图腾组合管理按钮图标
	local presetManagerTexture = _G["ArchiTotemButton_PresetManagerTexture"]
	if presetManagerTexture then
		presetManagerTexture:SetTexture("Interface\\Icons\\Spell_Nature_CallStorm")
	end
end

-- 更新显示状态
function ArchiTotem_UpdateShown()
	for k, v in ArchiTotem_TotemElements do
		local threeLetterElement = string.sub(v, 1, 3)
		for i = 1, ArchiTotem_Options[threeLetterElement].max do
			if i <= ArchiTotem_Options[threeLetterElement].shown then
				_G["ArchiTotemButton_" .. v .. i]:Show()
			else
				_G["ArchiTotemButton_" .. v .. i]:Hide()
			end
		end
	end

	ArchiTotem_PositionSpecialButtons()
	ArchiTotem_RecalculateWidth()
end

-- 设置方向
function ArchiTotem_SetDirection(dir)
    ArchiTotem_Options["Apperance"].direction = dir
    local anchor1, anchor2

    if dir == "down" then
        anchor1 = "TOPLEFT"
        anchor2 = "BOTTOMLEFT"
    elseif dir == "up" then
        anchor1 = "BOTTOMLEFT"
        anchor2 = "TOPLEFT"
    end

    EarthDurationText:SetPoint("CENTER", ArchiTotemButton_Earth1, "CENTER", 0, -26)
    FireDurationText:SetPoint("CENTER", ArchiTotemButton_Fire1, "CENTER", 0, -26)
    WaterDurationText:SetPoint("CENTER", ArchiTotemButton_Water1, "CENTER", 0, -26)
    AirDurationText:SetPoint("CENTER", ArchiTotemButton_Air1, "CENTER", 0, -26)

    for k, v in ArchiTotem_TotemElements do
        local threeLetterElement = string.sub(v, 1, 3)
        for i = 2, ArchiTotem_Options[threeLetterElement].max do
            local relativeTotem = _G["ArchiTotemButton_" .. v .. (i - 1)]
            _G["ArchiTotemButton_" .. v .. i]:ClearAllPoints()
            _G["ArchiTotemButton_" .. v .. i]:SetPoint(anchor1, relativeTotem, anchor2)
        end
    end
end

-- 设置排序
function ArchiTotem_Order(first, second, third, forth)
	if first == nil or second == nil or third == nil or forth == nil then
		return ArchiTotem_Print(L["Elements must be written in english!"] .. " <Earth, Fire, Water, Air>", "error")
	end
	local firstButton = "ArchiTotemButton_" .. strupper(string.sub(first, 1, 1)) .. string.sub(first, 2) .. "1"
	local secondButton = "ArchiTotemButton_" .. strupper(string.sub(second, 1, 1)) .. string.sub(second, 2) .. "1"
	local thirdButton = "ArchiTotemButton_" .. strupper(string.sub(third, 1, 1)) .. string.sub(third, 2) .. "1"
	local forthButton = "ArchiTotemButton_" .. strupper(string.sub(forth, 1, 1)) .. string.sub(forth, 2) .. "1"
	ArchiTotem_Options["Order"].first = strupper(string.sub(first, 1, 1)) .. string.sub(first, 2)
	ArchiTotem_Options["Order"].second = strupper(string.sub(second, 1, 1)) .. string.sub(second, 2)
	ArchiTotem_Options["Order"].third = strupper(string.sub(third, 1, 1)) .. string.sub(third, 2)
	ArchiTotem_Options["Order"].forth = strupper(string.sub(forth, 1, 1)) .. string.sub(forth, 2)
	local frame = _G["ArchiTotemFrame"]
	_G[firstButton]:ClearAllPoints(); if frame then _G[firstButton]:SetPoint("LEFT", frame, "LEFT", 0, 0) end
	_G[secondButton]:ClearAllPoints(); _G[secondButton]:SetPoint("LEFT", firstButton, "RIGHT", 0, 0)
	_G[thirdButton]:ClearAllPoints(); _G[thirdButton]:SetPoint("LEFT", secondButton, "RIGHT", 0, 0)
	_G[forthButton]:ClearAllPoints(); _G[forthButton]:SetPoint("LEFT", thirdButton, "RIGHT", 0, 0)
	ArchiTotem_RecalculateWidth()
end

-- 设置缩放
function ArchiTotem_SetScale(scale)
	ArchiTotem_Options["Apperance"].scale = scale
	for k, v in ArchiTotem_TotemElements do
		local threeLetterElement = string.sub(v, 1, 3)
		for i = 1, ArchiTotem_Options[threeLetterElement].max do
			_G["ArchiTotemButton_" .. v .. i]:SetScale(scale)
		end
	end
	local allTotemsButton = _G["ArchiTotemButton_AllTotems"]; if allTotemsButton then allTotemsButton:SetScale(scale) end
	local recallButton = _G["ArchiTotemButton_Recall"]; if recallButton then recallButton:SetScale(scale) end
	local presetManagerButton = _G["ArchiTotemButton_PresetManager"]; if presetManagerButton then presetManagerButton:SetScale(scale) end
	local presetFrame = _G["ArchiTotemPresetFrame"]; if presetFrame then presetFrame:SetScale(1) end
	ArchiTotem_RecalculateWidth()
end

-- 强制刷新UI
function ArchiTotem_ForceRefreshUI()
	ArchiTotem_UpdateTextures()
	ArchiTotem_UpdateShown()

	-- 确保所有按钮都正确显示
	for k, v in ArchiTotem_TotemElements do
		local threeLetterElement = string.sub(v, 1, 3)
		for i = 1, ArchiTotem_Options[threeLetterElement].max do
			local buttonName = "ArchiTotemButton_" .. v .. i
			local button = _G[buttonName]
			if button then
				local texture = _G[buttonName .. "Texture"]
				if texture and ArchiTotem_TotemData[buttonName] then
					texture:SetTexture(ArchiTotem_TotemData[buttonName].icon)

					if ArchiTotem_Options[threeLetterElement].skip then
						texture:SetAlpha(0.4)
						texture:SetVertexColor(1, 0.3, 0.3)
					else
						texture:SetAlpha(1.0)
						texture:SetVertexColor(1, 1, 1)
					end
				end
			end
		end
	end
end

-- 实时更新图腾组合管理界面显示
function ArchiTotem_UpdatePresetManagerDisplay()
	-- 只有当预设管理界面打开时才更新
	local frame = _G["ArchiTotemPresetFrame"]
	if frame and frame:IsVisible() then
		ArchiTotem_UpdateCurrentTotemDisplay()
	end
end

function ArchiTotem_RecalculateWidth()
	if not ArchiTotem_Options or not ArchiTotem_Options["Apperance"] then return end
	local scale = ArchiTotem_Options["Apperance"].scale or 1
	local per = 40 * scale
	local width = 0
	for _, v in ArchiTotem_TotemElements do
		local b = _G["ArchiTotemButton_" .. v .. "1"]
		if b and b:IsShown() then width = width + per end
	end
	local bAll = _G["ArchiTotemButton_AllTotems"]; if bAll and bAll:IsShown() then width = width + per end
	local bRecall = _G["ArchiTotemButton_Recall"]; if bRecall and bRecall:IsShown() then width = width + per end
	local bPreset = _G["ArchiTotemButton_PresetManager"]; if bPreset and bPreset:IsShown() then width = width + per end
	if width > 0 then local frame = _G["ArchiTotemFrame"]; if frame then frame:SetWidth(width) end end
end

-- 定位拖拽小球和特殊按钮：第4元素 -> 拖拽 -> 一键 -> 召回(可选) -> 组合(可选)
function ArchiTotem_PositionSpecialButtons()
	local order = ArchiTotem_Options and ArchiTotem_Options["Order"] or {}
	local forth = order.forth or "Air"
	local lastAnchor = _G["ArchiTotemButton_" .. forth .. "1"]
	local drag = _G["ArchiTotemDragHandle"]
	local allBtn = _G["ArchiTotemButton_AllTotems"]
	local recallBtn = _G["ArchiTotemButton_Recall"]
	local presetBtn = _G["ArchiTotemButton_PresetManager"]
	if lastAnchor and drag and allBtn then
		drag:ClearAllPoints(); drag:SetPoint("LEFT", lastAnchor, "RIGHT", 0, 0)
		allBtn:ClearAllPoints(); allBtn:SetPoint("LEFT", drag, "RIGHT", 0, 0); allBtn:Show()
	end
	if recallBtn then
		recallBtn:ClearAllPoints()
		if ArchiTotem_Options["Apperance"].showrecallbutton then
			recallBtn:SetPoint("LEFT", allBtn, "RIGHT", 0, 0); recallBtn:Show()
		else
			recallBtn:Hide()
		end
	end
	if presetBtn then
		presetBtn:ClearAllPoints()
		if ArchiTotem_Options["Apperance"].showpresetmanagerbutton then
			local anchor = (recallBtn and recallBtn:IsShown()) and recallBtn or allBtn
			if anchor then presetBtn:SetPoint("LEFT", anchor, "RIGHT", 0, 0) end
			presetBtn:Show()
		else
			presetBtn:Hide()
		end
	end
end
