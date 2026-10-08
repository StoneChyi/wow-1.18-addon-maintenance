-- ArchiTotem 按键绑定模块
-- 包含所有按键绑定相关的功能

-- 基础按键绑定函数
function ArchiTotem_KeyBinding_CastAll()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastAllTotems()
	end
end

function ArchiTotem_KeyBinding_Recall()
	if ArchiTotem_IsShaman() then
		ArchiTotem_RecallTotems()
	end
end

function ArchiTotem_KeyBinding_CastEarth()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastElementTotem("Earth")
	end
end

function ArchiTotem_KeyBinding_CastFire()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastElementTotem("Fire")
	end
end

function ArchiTotem_KeyBinding_CastWater()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastElementTotem("Water")
	end
end

function ArchiTotem_KeyBinding_CastAir()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastElementTotem("Air")
	end
end

function ArchiTotem_KeyBinding_ToggleSkipEarth()
	if ArchiTotem_IsShaman() then
		ArchiTotem_ToggleSkipElement("Earth")
	end
end

function ArchiTotem_KeyBinding_ToggleSkipFire()
	if ArchiTotem_IsShaman() then
		ArchiTotem_ToggleSkipElement("Fire")
	end
end

function ArchiTotem_KeyBinding_ToggleSkipWater()
	if ArchiTotem_IsShaman() then
		ArchiTotem_ToggleSkipElement("Water")
	end
end

function ArchiTotem_KeyBinding_ToggleSkipAir()
	if ArchiTotem_IsShaman() then
		ArchiTotem_ToggleSkipElement("Air")
	end
end

-- 预设按键绑定函数
function ArchiTotem_KeyBinding_PresetPVE()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastPresetTotems("pve")
	end
end

function ArchiTotem_KeyBinding_PresetPVP()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastPresetTotems("pvp")
	end
end

function ArchiTotem_KeyBinding_PresetResist()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastPresetTotems("resist")
	end
end

function ArchiTotem_KeyBinding_PresetCustom()
	if ArchiTotem_IsShaman() then
		ArchiTotem_CastPresetTotems("custom")
	end
end

-- 动态注册自定义预设的按键绑定
function ArchiTotem_RegisterCustomPresetBindings()
	if not ArchiTotem_IsShaman() then
		return
	end
	
	-- 遍历所有预设，为自定义预设创建按键绑定函数
	for presetName, presetData in pairs(ArchiTotem_Options["Presets"]) do
		-- 跳过默认的四个预设
		if presetName ~= "pve" and presetName ~= "pvp" and presetName ~= "resist" and presetName ~= "custom" then
			local functionName = "ArchiTotem_KeyBinding_Preset_" .. presetName
			
			-- 动态创建按键绑定函数
			_G[functionName] = function()
				if ArchiTotem_IsShaman() then
					ArchiTotem_CastPresetTotems(presetName)
				end
			end
			
			if ArchiTotem_Options["Debug"] then
				ArchiTotem_Print("注册自定义预设按键绑定: " .. presetName, "debug")
			end
		end
	end
end
