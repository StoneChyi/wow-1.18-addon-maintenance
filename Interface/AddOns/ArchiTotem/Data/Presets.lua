-- ArchiTotem 预设模块
-- 包含图腾预设组合的管理功能

local L = ArchiTotemLocale

-- 一键召唤所有图腾
function ArchiTotem_CastAllTotems()
    -- 固定顺序: 空气 -> 水 -> 火焰 -> 大地
    local order = { "Air", "Water", "Fire", "Earth" }
    local castCount = 0
    
    for _, element in ipairs(order) do
        local threeLetterElement = string.sub(element, 1, 3)
        if not ArchiTotem_Options[threeLetterElement].skip then
            local buttonName = "ArchiTotemButton_" .. element .. "1"
            local totemData = ArchiTotem_TotemData[buttonName]
            if totemData then
                local localizeSpell = L[totemData.name]
                if localizeSpell then
                    CastSpellByName(localizeSpell)
                end
            end
        end
    end
end

-- 召回所有图腾
function ArchiTotem_RecallTotems()
	local localizeSpell = L["Totemic Recall"]
	if localizeSpell then
		CastSpellByName(localizeSpell)
	end
end

-- 设置预设图腾组合
function ArchiTotem_SetPreset(presetName)
	local preset = ArchiTotem_Options["Presets"][presetName]
	if not preset then
		ArchiTotem_Print("未找到预设: " .. presetName, "error")
		return
	end
	
	-- 检查必要的数据结构
	if not ArchiTotem_TotemData then
		ArchiTotem_Print("图腾数据未初始化", "error")
		return
	end
	
	if not ArchiTotem_Options then
		ArchiTotem_Print("选项数据未初始化", "error")
		return
	end

	if ArchiTotem_Options["Debug"] then
		ArchiTotem_Print("开始设置预设: " .. presetName, "debug")
	end

	-- 遍历四个元素，找到对应的图腾并移动到第一个位置
	for elementName, totemName in pairs(preset) do
		local threeLetterElement = string.sub(elementName, 1, 3)
		
		-- 检查元素选项是否存在
		if not ArchiTotem_Options[threeLetterElement] then
			ArchiTotem_Print("元素选项不存在: " .. threeLetterElement, "error")
			return
		end
		
		local maxTotems = ArchiTotem_Options[threeLetterElement].max

		if ArchiTotem_Options["Debug"] then
			ArchiTotem_Print("处理元素: " .. elementName .. ", 目标图腾: " .. totemName, "debug")
		end

		-- 查找图腾在哪个位置
		local targetPosition = nil
		for i = 1, maxTotems do
			local buttonName = "ArchiTotemButton_" .. elementName .. i
			if ArchiTotem_TotemData[buttonName] and ArchiTotem_TotemData[buttonName].name == totemName then
				targetPosition = i
				break
			end
		end

		if targetPosition then
			if ArchiTotem_Options["Debug"] then
				ArchiTotem_Print("找到图腾在位置: " .. targetPosition, "debug")
			end

			if targetPosition > 1 then
				local firstButton = "ArchiTotemButton_" .. elementName .. "1"
				local targetButton = "ArchiTotemButton_" .. elementName .. targetPosition

				if ArchiTotem_Options["Debug"] then
					ArchiTotem_Print("交换按钮: " .. firstButton .. " <-> " .. targetButton, "debug")
				end

				-- 在交换前确保数据完整性
				if ArchiTotem_TotemData[firstButton] and ArchiTotem_TotemData[targetButton] then
					-- 确保 casted 字段存在
					if ArchiTotem_TotemData[firstButton].casted == nil then
						ArchiTotem_TotemData[firstButton].casted = GetTime() - (ArchiTotem_TotemData[firstButton].cooldown or 0)
					end
					if ArchiTotem_TotemData[targetButton].casted == nil then
						ArchiTotem_TotemData[targetButton].casted = GetTime() - (ArchiTotem_TotemData[targetButton].cooldown or 0)
					end
					
					ArchiTotem_Switch(firstButton, targetButton)
				else
					if ArchiTotem_Options["Debug"] then
						ArchiTotem_Print("按钮数据不完整: " .. firstButton .. " 或 " .. targetButton, "debug")
					end
				end
			end
		else
			if ArchiTotem_Options["Debug"] then
				ArchiTotem_Print("未找到图腾: " .. totemName, "debug")
			end
		end
	end

	-- 获取预设的中文名称
	local presetDisplayName = presetName
	if presetName == "pve" then
		presetDisplayName = "PVE"
	elseif presetName == "pvp" then
		presetDisplayName = "PVP"
	elseif presetName == "resist" then
		presetDisplayName = "抗性"
	elseif presetName == "custom" then
		presetDisplayName = "自定义"
	end

	ArchiTotem_ForceRefreshUI()
	
	-- 实时更新图腾组合管理界面
	ArchiTotem_UpdatePresetManagerDisplay()
    -- 更新保存的当前图腾配置
    ArchiTotem_UpdateCurrentTotemsOption()	
	ArchiTotem_Print("预设 '" .. presetDisplayName .. "' 已设置")
end

-- 保存当前图腾为预设
function ArchiTotem_SavePreset(presetName)
	local preset = {}
	for k, v in ArchiTotem_TotemElements do
		local buttonName = "ArchiTotemButton_" .. v .. "1"
		preset[v] = ArchiTotem_TotemData[buttonName].name
	end

	ArchiTotem_Options["Presets"][presetName] = preset
	ArchiTotem_Print("预设 '" .. presetName .. "' 已保存")
	
	-- 重新注册按键绑定以包含新的自定义预设
	ArchiTotem_RegisterCustomPresetBindings()
end

-- 列出所有预设
function ArchiTotem_ListPresets()
	ArchiTotem_Print("可用预设:")
	ArchiTotem_Print("pve - PVE组合: 大地之力, 火舌, 法力之泉, 风怒")
	ArchiTotem_Print("pvp - PVP组合: 战栗, 灼热, 治疗之泉, 根基")
	ArchiTotem_Print("resist - 抗性组合: 石肤, 抗寒, 抗火, 自然抗性")
	ArchiTotem_Print("custom - 自定义组合: 大地之力, 灼热, 法力之泉, 宁静之风")
	ArchiTotem_Print("使用 /at preset <预设名称> 来设置预设")
end

-- 召唤指定元素的图腾
function ArchiTotem_CastElementTotem(element)
	local threeLetterElement = string.sub(element, 1, 3)
	
	if ArchiTotem_Options[threeLetterElement].skip then
		ArchiTotem_Print("已跳过 " .. element .. " 图腾")
		return
	end
	
	local buttonName = "ArchiTotemButton_" .. element .. "1"
	local totemData = ArchiTotem_TotemData[buttonName]
	if totemData then
		local localizeSpell = L[totemData.name]
		if localizeSpell then
			CastSpellByName(localizeSpell)
			ArchiTotemActiveTotem[element] = totemData
			ArchiTotemActiveTotem[element].casted = GetTime()
			ArchiTotem_TotemData[buttonName].cooldownstarted = GetTime()
			ArchiTotem_Print("召唤 " .. element .. " 图腾: " .. totemData.name)
		end
	end
end

-- 切换指定元素的跳过状态
function ArchiTotem_ToggleSkipElement(element)
	local threeLetterElement = string.sub(element, 1, 3)
	ArchiTotem_Options[threeLetterElement].skip = not ArchiTotem_Options[threeLetterElement].skip
	
	local statusKey = element .. " totems skip: " .. (ArchiTotem_Options[threeLetterElement].skip and "ON" or "OFF")
	ArchiTotem_Print(L[statusKey])
	
	ArchiTotem_UpdateTextures()
end

-- 通用预设召唤函数
function ArchiTotem_CastPresetTotems(presetName)
	local preset = ArchiTotem_Options["Presets"][presetName]
	if not preset then
		ArchiTotem_Print("未找到预设: " .. presetName, "error")
		return
	end

	ArchiTotem_SetPreset(presetName)
	ArchiTotem_CastAllTotems()
	
	local presetDisplayName = presetName
	if presetName == "pve" then
		presetDisplayName = "PVE"
	elseif presetName == "pvp" then
		presetDisplayName = "PVP"
	elseif presetName == "resist" then
		presetDisplayName = "抗性"
	elseif presetName == "custom" then
		presetDisplayName = "自定义"
	end
	
	ArchiTotem_Print("召唤预设: " .. presetDisplayName)
end
