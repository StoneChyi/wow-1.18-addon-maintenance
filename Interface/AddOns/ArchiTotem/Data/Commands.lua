-- ArchiTotem 命令模块
-- 包含所有斜杠命令的处理逻辑

local L = ArchiTotemLocale

function ArchiTotem_Command(cmd)
	-- 只有萨满祭司才能使用命令
	if not ArchiTotem_IsShaman() then
		DEFAULT_CHAT_FRAME:AddMessage("|CFF20B2AA[ArchiTotem]|r 此插件仅适用于萨满祭司。")
		return
	end

	local command = string.lower(cmd)
	local i = 1
	local arg = {}
	-- 使用非空白分词，避免小数点被拆成两个数字（如 0.8 被拆成 0 和 8）
	for token in string.gfind(command, "%S+") do
		arg[i] = token
		i = i + 1
	end

	if arg[1] == "set" then
		ArchiTotem_HandleSetCommand(arg)
	elseif arg[1] == "direction" then
		ArchiTotem_HandleDirectionCommand(arg)
	elseif arg[1] == "order" then
		ArchiTotem_HandleOrderCommand(arg)
	elseif arg[1] == "scale" then
		ArchiTotem_HandleScaleCommand(arg)
	elseif arg[1] == "showall" then
		ArchiTotem_HandleShowAllCommand()
	elseif arg[1] == "bottomcast" then
		ArchiTotem_HandleBottomCastCommand()
	elseif arg[1] == "timers" then
		ArchiTotem_HandleTimersCommand()
	elseif arg[1] == "tooltip" then
		ArchiTotem_HandleTooltipCommand()
	elseif arg[1] == "debug" then
		ArchiTotem_HandleDebugCommand()
	elseif arg[1] == "skip" then
		ArchiTotem_HandleSkipCommand(arg)
	elseif arg[1] == "preset" then
		ArchiTotem_HandlePresetCommand(arg)
	elseif arg[1] == "refresh" then
		ArchiTotem_ForceRefreshUI()
		ArchiTotem_Print("UI已刷新")
	elseif arg[1] == "cast" then
		if arg[2] then
			local presetName = string.lower(arg[2])
			if ArchiTotem_Options["Presets"][presetName] then
				ArchiTotem_CastPresetTotems(presetName)
			else
				ArchiTotem_Print("未找到预设: " .. arg[2], "error")
			end
		else
			ArchiTotem_CastAllTotems()
			ArchiTotem_Print("一键召唤所有图腾")
		end
	elseif arg[1] == "recall" then
		ArchiTotem_RecallTotems()
		ArchiTotem_Print("召回所有图腾")
	elseif arg[1] == "lock" then
		ArchiTotem_ToggleLock()
	elseif arg[1] == "reset" then
		ArchiTotem_ResetFramePosition()
	elseif arg[1] == "test" then
		ArchiTotem_TestDragHandle()
	elseif arg[1] == "testrecall" then
		-- 测试图腾召回检测
		if ArchiTotem_TotemData["ArchiTotemButton_Recall"] then
			ArchiTotem_TotemData["ArchiTotemButton_Recall"].cooldownstarted = GetTime()
			ArchiTotem_TotemData["ArchiTotemButton_Recall"].cooldown = 6
			ArchiTotem_Print("测试：触发召回按钮冷却（6秒）")
		else
			ArchiTotem_Print("错误：找不到召回按钮数据")
		end
	elseif arg[1] == "bind" then
		ArchiTotem_ShowBindingHelp()
	elseif arg[1] == "talent" then
		ArchiTotem_HandleTalentCommand(arg)
	elseif arg[1] == "coverage" or arg[1] == "cover" then
		ArchiTotem_ToggleCoverageWindow()
	else
		ArchiTotem_ShowCommandHelp()
	end
end

-- 处理 set 命令
function ArchiTotem_HandleSetCommand(arg)
	if arg[2] == "earth" then
		if tonumber(arg[3]) and tonumber(arg[3]) > 0 and tonumber(arg[3]) <= 5 then
			ArchiTotem_Options["Ear"].shown = tonumber(arg[3])
			ArchiTotem_UpdateShown()
			ArchiTotem_Print(L["Earth totems shown: "] .. arg[3])
		end
	elseif arg[2] == "fire" then
		if tonumber(arg[3]) and tonumber(arg[3]) > 0 and tonumber(arg[3]) <= 5 then
			ArchiTotem_Options["Fir"].shown = tonumber(arg[3])
			ArchiTotem_UpdateShown()
			ArchiTotem_Print(L["Fire totems shown: "] .. arg[3])
		end
	elseif arg[2] == "water" then
		if tonumber(arg[3]) and tonumber(arg[3]) > 0 and tonumber(arg[3]) <= 5 then
			ArchiTotem_Options["Wat"].shown = tonumber(arg[3])
			ArchiTotem_UpdateShown()
			ArchiTotem_Print(L["Water totems shown: "] .. arg[3])
		end
	elseif arg[2] == "air" then
		if tonumber(arg[3]) and tonumber(arg[3]) > 0 and tonumber(arg[3]) <= 7 then
			ArchiTotem_Options["Air"].shown = tonumber(arg[3])
			ArchiTotem_UpdateShown()
			ArchiTotem_Print(L["Air totems shown: "] .. arg[3])
		end
	else
		ArchiTotem_Print(L["Elements must be written in english!"] .. " <Earth, Fire, Water, Air>", "error")
	end
end

-- 处理 direction 命令
function ArchiTotem_HandleDirectionCommand(arg)
	if arg[2] == "down" then
		ArchiTotem_SetDirection("down")
		ArchiTotem_Print(L["Direction set to: Down"])
	elseif arg[2] == "up" then
		ArchiTotem_SetDirection("up")
		ArchiTotem_Print(L["Direction set to: Up"])
	else
		ArchiTotem_Print(L["Direction must be down or up!"], "error")
	end
end

-- 处理 order 命令
function ArchiTotem_HandleOrderCommand(arg)
	ArchiTotem_Order(arg[2], arg[3], arg[4], arg[5])
	if arg[2] and arg[3] and arg[4] and arg[5] then
		ArchiTotem_Print(L["Order set to: "] .. arg[2] .. ", " .. arg[3] .. ", " .. arg[4] .. ", " .. arg[5])
	end
end

-- 处理 scale 命令
function ArchiTotem_HandleScaleCommand(arg)
	if not arg[2] then
		return ArchiTotem_Print(L["Specify scale"], "error")
	elseif type(tonumber(arg[2])) ~= "number" then
		return ArchiTotem_Print(L["Scale must be a number!"], "error")
	end
	-- 新比例规则: 输入1表示1.0倍; 输入100表示3.0倍; 线性映射
	-- 公式: scale = 1.0 + (clampedInput - 1) * ( (3.0 - 1.0) / (100 - 1) )
	-- 额外支持小屏幕: 输入 < 1 时直接作为实际比例，最低 0.30 以避免过小
	local raw = tonumber(arg[2]) or 1
	local clamped = raw
	if clamped < 0.3 then clamped = 0.3 end
	if clamped > 100 then clamped = 100 end

	local mapped
	if clamped < 1 then
		-- 直接使用较小比例，方便笔记本玩家缩到 0.3~1 之间
		mapped = clamped
	else
		mapped = 1 + (clamped - 1) * (2 / 99) -- 2/99 ≈ 0.020202...
	end

	local display = string.format("%.2f", mapped)
	ArchiTotem_SetScale(mapped)
	ArchiTotem_Print("缩放已设置: 输入=" .. string.format("%.2f", raw) .. " => 实际比例=" .. display)
end

-- 处理 showall 命令
function ArchiTotem_HandleShowAllCommand()
	if ArchiTotem_Options["Apperance"].allonmouseover == false then
		ArchiTotem_Options["Apperance"].allonmouseover = true
		ArchiTotem_Print(L["Showing all totems on mouseover"])
	else
		ArchiTotem_Options["Apperance"].allonmouseover = false
		ArchiTotem_Print(L["Showing only one element on mouseover"])
	end
end

-- 处理 bottomcast 命令
function ArchiTotem_HandleBottomCastCommand()
	if ArchiTotem_Options["Apperance"].bottomoncast == false then
		ArchiTotem_Options["Apperance"].bottomoncast = true
		ArchiTotem_Print(L["Totems will move the the bottom line when cast"])
	else
		ArchiTotem_Options["Apperance"].bottomoncast = false
		ArchiTotem_Print(L["Totems will stay where they are when cast"])
	end
end

-- 处理 timers 命令
function ArchiTotem_HandleTimersCommand()
	if ArchiTotem_Options["Apperance"].shownumericcooldowns == false then
		ArchiTotem_Options["Apperance"].shownumericcooldowns = true
		ArchiTotem_Print(L["Timers are now turned on"])
	else
		ArchiTotem_Options["Apperance"].shownumericcooldowns = false
		ArchiTotem_Print(L["Timers are now turned off"])
		for k, v in ArchiTotem_TotemData do
			_G[k .. "CooldownText"]:Hide()
			_G[k .. "CooldownBg"]:Hide()
			v.cooldownstarted = nil
		end
		for k, v in ArchiTotemActiveTotem do
			_G[k .. "DurationText"]:Hide()
		end
	end
end

-- 处理 tooltip 命令
function ArchiTotem_HandleTooltipCommand()
	if ArchiTotem_Options["Apperance"].showtooltips == false then
		ArchiTotem_Options["Apperance"].showtooltips = true
		ArchiTotem_Print(L["Tooltips are now turned on"])
	else
		ArchiTotem_Options["Apperance"].showtooltips = false
		ArchiTotem_Print(L["Tooltips are now turned off"])
	end
end

-- 处理 debug 命令
function ArchiTotem_HandleDebugCommand()
	if ArchiTotem_Options["Debug"] == false then
		ArchiTotem_Options["Debug"] = true
		ArchiTotem_Print(L["Debuging are now turned on"])
	else
		ArchiTotem_Options["Debug"] = false
		ArchiTotem_Print(L["Debuging are now turned off"])
	end
end

-- 处理 skip 命令
function ArchiTotem_HandleSkipCommand(arg)
	if arg[2] == "earth" then
		ArchiTotem_Options["Ear"].skip = not ArchiTotem_Options["Ear"].skip
		ArchiTotem_Print(L[ArchiTotem_Options["Ear"].skip and "Earth totems skip: ON" or "Earth totems skip: OFF"])
	elseif arg[2] == "fire" then
		ArchiTotem_Options["Fir"].skip = not ArchiTotem_Options["Fir"].skip
		ArchiTotem_Print(L[ArchiTotem_Options["Fir"].skip and "Fire totems skip: ON" or "Fire totems skip: OFF"])
	elseif arg[2] == "water" then
		ArchiTotem_Options["Wat"].skip = not ArchiTotem_Options["Wat"].skip
		ArchiTotem_Print(L[ArchiTotem_Options["Wat"].skip and "Water totems skip: ON" or "Water totems skip: OFF"])
	elseif arg[2] == "air" then
		ArchiTotem_Options["Air"].skip = not ArchiTotem_Options["Air"].skip
		ArchiTotem_Print(L[ArchiTotem_Options["Air"].skip and "Air totems skip: ON" or "Air totems skip: OFF"])
	else
		ArchiTotem_Print(L["Elements must be written in english!"] .. " <earth, fire, water, air>", "error")
	end
	ArchiTotem_UpdateTextures()
end

-- 处理 preset 命令
function ArchiTotem_HandlePresetCommand(arg)
    if not ArchiTotem_Options["Presets"] then
		ArchiTotem_CheckCompatibility()
	end

	if arg[2] == "list" then
		ArchiTotem_ListPresets()
	elseif arg[2] == "save" then
		if arg[3] then
			ArchiTotem_SavePreset(arg[3])
		else
			ArchiTotem_Print("请指定预设名称: /at preset save <名称>", "error")
		end
	elseif arg[2] then
		ArchiTotem_SetPreset(arg[2])
	else
		ArchiTotem_Print("用法: /at preset <预设名称> 或 /at preset list 或 /at preset save <名称>", "error")
	end
end

-- 显示按键绑定帮助
function ArchiTotem_ShowBindingHelp()
	ArchiTotem_Print("按键绑定功能:")
	ArchiTotem_Print("请在游戏设置 -> 按键设置 -> ArchiTotem 图腾大师 中设置快捷键")
	ArchiTotem_Print("可绑定的功能:")
	ArchiTotem_Print("- 一键召唤所有图腾")
	ArchiTotem_Print("- 召回所有图腾")
	ArchiTotem_Print("- 召唤各系图腾 (土/火/水/风)")
	ArchiTotem_Print("- 切换跳过各系图腾")
	ArchiTotem_Print("- 召唤PVE预设图腾")
	ArchiTotem_Print("- 召唤PVP预设图腾")
	ArchiTotem_Print("- 召唤抗性预设图腾")
	ArchiTotem_Print("- 召唤自定义预设图腾")
	
	local customPresetCount = 0
	for presetName, _ in pairs(ArchiTotem_Options["Presets"]) do
		if presetName ~= "pve" and presetName ~= "pvp" and presetName ~= "resist" and presetName ~= "custom" then
			if customPresetCount == 0 then
				ArchiTotem_Print("- 自定义预设:")
			end
			ArchiTotem_Print("  * 召唤" .. presetName .. "预设图腾")
			customPresetCount = customPresetCount + 1
		end
	end
	
	if customPresetCount == 0 then
		ArchiTotem_Print("注意: 使用 /at preset save <名称> 保存自定义预设后，")
		ArchiTotem_Print("相应的按键绑定会自动创建。")
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("\n")
	ArchiTotem_Print(L["Moving the bar:"])
	ArchiTotem_Print(L["Ctrl-RightClick and Drag any of the main buttons"])
	ArchiTotem_Print(L["Ordering totems of same element:"])
	ArchiTotem_Print(L["Ctrl-LeftClick any of the buttons"])
	ArchiTotem_Print(L["右键点击切换跳过状态"])
end

-- 显示命令帮助
function ArchiTotem_ShowCommandHelp()
	ArchiTotem_Print("ArchiTotem 图腾大师 V" .. (GetAddOnMetadata("ArchiTotem", "Version") or "1.7"))
	ArchiTotem_Print("可用命令:")
	ArchiTotem_Print("/at set <earth/fire/water/air> <数量> - 设置显示的图腾数量")
	ArchiTotem_Print("/at direction <up/down> - 设置图腾弹出方向")
	ArchiTotem_Print("/at order <元素1> <元素2> <元素3> <元素4> - 设置元素排列顺序")
	ArchiTotem_Print("/at scale <数值> - 设置界面缩放比例")
	ArchiTotem_Print("/at showall - 切换鼠标悬停显示所有/单一元素图腾")
	ArchiTotem_Print("/at bottomcast - 切换图腾施放后是否移到底部")
	ArchiTotem_Print("/at timers - 切换冷却时间数字显示")
	ArchiTotem_Print("/at tooltip - 切换工具提示显示")
	ArchiTotem_Print("/at debug - 切换调试模式")
	ArchiTotem_Print("/at skip <earth/fire/water/air> - 切换跳过指定元素")
	ArchiTotem_Print("/at preset <预设名称> - 设置图腾预设")
	ArchiTotem_Print("/at preset list - 列出所有预设")
	ArchiTotem_Print("/at preset save <名称> - 保存当前配置为预设")
	ArchiTotem_Print("/at cast [预设名] - 一键召唤所有图腾或指定预设组合")
	ArchiTotem_Print("/at recall - 召回所有图腾")
	ArchiTotem_Print("/at reset - 重置界面位置到屏幕中央")
	ArchiTotem_Print("/at test - 测试拖拽手柄状态 (调试用)")
	ArchiTotem_Print("/at testrecall - 测试召回按钮冷却效果")
	ArchiTotem_Print("/at refresh - 刷新UI显示")
	ArchiTotem_Print("/at bind - 显示按键绑定帮助")
	ArchiTotem_Print("/at talent scan - 扫描天赋，输出 [tab:index] 名称 rank")
	ArchiTotem_Print("/at talent status - 显示当前是否启用‘图腾掌握’")
	ArchiTotem_Print("/at talent set <tab> <index> - 指定‘图腾掌握’所在天赋位置")
	ArchiTotem_Print("/at talent clear - 清除手动索引，恢复自动检测")
	ArchiTotem_Print("/at talent on|off|auto - 强制开启/关闭/自动‘图腾掌握’判定")
	ArchiTotem_Print("/at coverage/cover - 打开/关闭图腾覆盖详情窗口")
	ArchiTotem_Print("使用说明:")
	ArchiTotem_Print("- 拖拽一键图腾按钮左侧的小球移动整个界面")
	ArchiTotem_Print("- 右键小球切换锁定状态")
	ArchiTotem_Print("- Shift+左键小球重置位置")
	ArchiTotem_Print("- Ctrl+右键拖拽移动界面 (旧方式仍可用)")
	ArchiTotem_Print("- 左键点击图腾施放，右键查看菜单")
	ArchiTotem_Print("- Ctrl+左键调整同元素图腾顺序")
	ArchiTotem_Print("- 右键点击切换跳过状态")
end

-- 处理 talent 命令（对齐 Cat 的按索引判定思路）
function ArchiTotem_HandleTalentCommand(arg)
	local sub = arg[2]
	if sub == "scan" then
		local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0
		if numTabs == 0 then
			ArchiTotem_Print("无法获取天赋页签（可能需在进世界后重试）", "error")
			return
		end
		for tab = 1, numTabs do
			local numTalents = GetNumTalents(tab) or 0
			for i = 1, numTalents do
				local name, _, _, _, rank = GetTalentInfo(tab, i)
				ArchiTotem_Print(string.format("[talent %d:%d] %s (rank=%d)", tab, i, tostring(name or "?"), rank or 0))
			end
		end
		return
	elseif sub == "status" then
		if ArchiTotem_UpdateTalents then
			ArchiTotem_UpdateTalents()
		end
		if ArchiTotem_PrintTotemicMasteryStatus then
			ArchiTotem_PrintTotemicMasteryStatus()
		else
			ArchiTotem_Print("状态函数不可用", "error")
		end
		return
	elseif sub == "set" then
		local tab = tonumber(arg[3])
		local index = tonumber(arg[4])
		if not tab or not index then
			ArchiTotem_Print("用法: /at talent set <tab> <index>", "error")
			return
		end
		ArchiTotem_Options["TotemicMasteryTab"] = tab
		ArchiTotem_Options["TotemicMasteryIndex"] = index
		ArchiTotem_Options["ForceTotemicMastery"] = nil -- 使用索引判定
		ArchiTotem_Print(string.format("已设置图腾掌握索引: tab=%d index=%d", tab, index))
		if ArchiTotem_UpdateTalents then ArchiTotem_UpdateTalents() end
		return
	elseif sub == "clear" then
		ArchiTotem_Options["TotemicMasteryTab"] = nil
		ArchiTotem_Options["TotemicMasteryIndex"] = nil
		ArchiTotem_Print("已清除图腾掌握索引设置，恢复自动检测")
		if ArchiTotem_UpdateTalents then ArchiTotem_UpdateTalents() end
		return
	elseif sub == "on" or sub == "off" or sub == "auto" then
		if sub == "auto" then
			ArchiTotem_Options["ForceTotemicMastery"] = nil
			ArchiTotem_Print("图腾掌握判定：自动模式")
		elseif sub == "on" then
			ArchiTotem_Options["ForceTotemicMastery"] = true
			ArchiTotem_Print("图腾掌握判定：强制开启 (+20%)")
		else
			ArchiTotem_Options["ForceTotemicMastery"] = false
			ArchiTotem_Print("图腾掌握判定：强制关闭")
		end
		if ArchiTotem_UpdateTalents then ArchiTotem_UpdateTalents() end
		return
	else
		ArchiTotem_Print("用法:")
		ArchiTotem_Print("/at talent scan - 扫描天赋，输出 [tab:index] 名称 rank")
		ArchiTotem_Print("/at talent set <tab> <index> - 指定‘图腾掌握’所在天赋位置")
		ArchiTotem_Print("/at talent clear - 清除手动索引，恢复自动检测")
		ArchiTotem_Print("/at talent on|off|auto - 强制开启/关闭/自动‘图腾掌握’判定")
	end
end
