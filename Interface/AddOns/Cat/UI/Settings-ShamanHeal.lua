
-- 定义插件名称
local ADDON_NAME = "Settings-ShamanHeal"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPShamanHealSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsShamanHealWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 690, "|cFF0070DE设置 - 奶萨|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsShamanHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)



local postion_y = postion_y-40

-- 创建单选框 - 治疗波
local checkButton_Wave = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 治疗波")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Wave, GetCurrentSaved, "Wave")


-- 创建单选框 - 优先治疗目标
local checkButton_TargetFirst = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetFirst, GetCurrentSaved, "TargetFirst")




postion_y = postion_y-30

-- 创建单选框 - 次级治疗波
local checkButton_SecondaryWave = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 次级治疗波")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SecondaryWave, GetCurrentSaved, "SecondaryWave")

-- 创建单选框 - 优先治疗目标 的 目标
local checkButton_TargetTarget = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标 的 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetTarget, GetCurrentSaved, "TargetTarget")




postion_y = postion_y-30

-- 创建单选框 - 治疗链
local checkButton_Chain = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 治疗链 (自动扫描)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Chain, GetCurrentSaved, "Chain")


-- 创建单选框 - 优先治疗自己
local checkButton_SelfFirst = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 自己 (谨慎开启)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SelfFirst, GetCurrentSaved, "SelfFirst")




postion_y = postion_y-30

-- 创建单选框 - 水之护盾
local checkButton_WaterShield = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 水之护盾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WaterShield, GetCurrentSaved, "WaterShield")


-- 创建单选框 - 治疗大团
local checkButton_ScanTeam = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "治疗大团")
MPBindConfigCheckButton(checkButton_ScanTeam, GetCurrentSaved, "ScanTeam")

local checkButton_ScanTeam_Low = MPCreateCheckButtonSmall(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 460, postion_y, "血量最低")
local checkButton_ScanTeam_Rand = MPCreateCheckButtonSmall(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 560, postion_y, "随机")

checkButton_ScanTeam_Low:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Low = 1
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand = 0
    else
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Low = 0
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand))
end)
checkButton_ScanTeam_Rand:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand = 1
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Low = 0
    else
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand = 0
        MPShamanHealSaved[ConfigCurrent].ScanTeam_Low = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand))
end)



postion_y = postion_y - 30

-- 创建单选框 - Tip
local checkButton_Tip = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 提示信息")
checkButton_Tip:Hide()
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Tip, GetCurrentSaved, "Tip")



postion_y = postion_y - 50 + 30

--起始治疗
local slider_Begin_Value = MPCreateConfigSlider(ADDON_NAME.."SliderBegin_Value", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 80, 100, 0.5, 0)

-- 值变化时的回调函数
slider_Begin_Value:SetScript("OnValueChanged", function()
    _G[slider_Begin_Value:GetName().."Text"]:SetText("起始治疗 血线："..arg1.."%")
    MPShamanHealSaved[ConfigCurrent].Begin_Value = arg1
end)








-- 图腾

postion_y = postion_y+10

-- 添加提示内容区域
local TipText2 = CatUISettingsShamanHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText2:SetPoint("TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y)
TipText2:SetWidth(250)
TipText2:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText2:SetTextColor(1, 0.8, 0)
TipText2:SetJustifyH("LEFT")
TipText2:SetText("图腾配置")

postion_y = postion_y-80



-- 大地图腾
local checkButton_EarthTotem = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "大地图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_EarthTotem, GetCurrentSaved, "EarthTotem")

-- 定义选项（带固定索引的表）
local modes_EarthTotem = {
    [1] = {text = "大地之力图腾", value = 1},
    [2] = {text = "石肤图腾", value = 2},
    [3] = {text = "石爪图腾", value = 3},
    [4] = {text = "战栗图腾",   value = 4},
    [5] = {text = "地缚图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_EarthTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_EarthTotem", checkButton_EarthTotem, "UIDropDownMenuTemplate")
dropdown_EarthTotem:SetPoint("TOPLEFT", checkButton_EarthTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_EarthTotem()
    for idx, data in pairs(modes_EarthTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, index)
                MPShamanHealSaved[ConfigCurrent].EarthTotem_Value = modes_EarthTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_EarthTotem, Dropdown_Init_EarthTotem)
UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, 1) -- 默认选中第一项








-- 火焰图腾
local checkButton_FireTotem = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 175, postion_y, "火焰图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FireTotem, GetCurrentSaved, "FireTotem")

-- 定义选项（带固定索引的表）
local modes_FireTotem = {
    [1] = {text = "火焰新星图腾", value = 1},
    [2] = {text = "灼热图腾", value = 2},
    [3] = {text = "熔岩图腾", value = 3},
    [4] = {text = "抗寒图腾",   value = 4},
    [5] = {text = "火舌图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_FireTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_FireTotem", checkButton_FireTotem, "UIDropDownMenuTemplate")
dropdown_FireTotem:SetPoint("TOPLEFT", checkButton_FireTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_FireTotem()
    for idx, data in pairs(modes_FireTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_FireTotem, index)
                MPShamanHealSaved[ConfigCurrent].FireTotem_Value = modes_FireTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_FireTotem, Dropdown_Init_FireTotem)
UIDropDownMenu_SetSelectedID(dropdown_FireTotem, 1) -- 默认选中第一项







-- 水之图腾
local checkButton_WaterTotem = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 330, postion_y, "水之图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WaterTotem, GetCurrentSaved, "WaterTotem")

-- 定义选项（带固定索引的表）
local modes_WaterTotem = {
    [1] = {text = "抗火图腾", value = 1},
    [2] = {text = "治疗之泉图腾", value = 2},
    [3] = {text = "法力之泉图腾", value = 3},
    [4] = {text = "清毒图腾",   value = 4},
    [5] = {text = "祛病图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_WaterTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_WaterTotem", checkButton_WaterTotem, "UIDropDownMenuTemplate")
dropdown_WaterTotem:SetPoint("TOPLEFT", checkButton_WaterTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_WaterTotem()
    for idx, data in pairs(modes_WaterTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, index)
                MPShamanHealSaved[ConfigCurrent].WaterTotem_Value = modes_WaterTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_WaterTotem, Dropdown_Init_WaterTotem)
UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, 1) -- 默认选中第一项





-- 空气图腾
local checkButton_AirTotem = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 485, postion_y, "空气图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_AirTotem, GetCurrentSaved, "AirTotem")

-- 定义选项（带固定索引的表）
local modes_AirTotem = {
    [1] = {text = "根基图腾", value = 1},
    [2] = {text = "自然抗性图腾", value = 2},
    [3] = {text = "风之优雅图腾", value = 3},
    [4] = {text = "风墙图腾",   value = 4},
    [5] = {text = "风怒图腾",   value = 5},
    [6] = {text = "宁静之风图腾",   value = 6},
    -- 这里剔除了 岗哨图腾
}

-- 创建下拉菜单
local dropdown_AirTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_AirTotem", checkButton_AirTotem, "UIDropDownMenuTemplate")
dropdown_AirTotem:SetPoint("TOPLEFT", checkButton_AirTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_AirTotem()
    for idx, data in pairs(modes_AirTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_AirTotem, index)
                MPShamanHealSaved[ConfigCurrent].AirTotem_Value = modes_AirTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_AirTotem, Dropdown_Init_AirTotem)
UIDropDownMenu_SetSelectedID(dropdown_AirTotem, 1) -- 默认选中第一项




postion_y = postion_y-80

--[[
-- 创建单选框 - 图腾召回
local checkButton_RecallTotems = CreateFrame("CheckButton", ADDON_NAME.."CheckButton_RecallTotems", CatUISettingsShamanHealWindow, "UICheckButtonTemplate")
checkButton_RecallTotems:SetPoint("TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y)
checkButton_RecallTotems:SetScale(0.8)

-- 添加文字标签
local checkText_RecallTotems = checkButton_RecallTotems:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
checkText_RecallTotems:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
checkText_RecallTotems:SetTextColor(1, 1, 1)
checkText_RecallTotems:SetPoint("LEFT", checkButton_RecallTotems, "LEFT", 34, 1)
checkText_RecallTotems:SetText("自动 图腾召回")


local slider_RecallTotems = MPCreateConfigSlider(ADDON_NAME.."Slider_RecallTotems", checkButton_RecallTotems, "RIGHT", checkButton_RecallTotems, "RIGHT", 260, -2, 150, 16, 15, 100, 1, 30)

local color_RecallTotems = "|cFFFFD100"

-- 值变化时的回调函数
slider_RecallTotems:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPShamanHealSaved[ConfigCurrent].RecallTotems_Value = arg1
    _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanHealSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
end)

-- 设置点击事件
checkButton_RecallTotems:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].RecallTotems = 1
        color_RecallTotems = "|cFFFFD100"
        _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanHealSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    else
        MPShamanHealSaved[ConfigCurrent].RecallTotems = 0
        color_RecallTotems = "|cFF888888"
        _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanHealSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    end
end)
]]


-- 创建单选框 - 强制图腾
local checkButton_ForceTotem = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 强制图腾配置")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ForceTotem, GetCurrentSaved, "ForceTotem")




-- 高级



postion_y = postion_y+50

-- 添加提示内容区域
local TipText1 = CatUISettingsShamanHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-110


-- 创建单选框 - 溢出治疗
local checkButton_Overflow = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用 溢出治疗时打断施法")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overflow, GetCurrentSaved, "Overflow")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPShamanHealSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPShamanHealSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 水之护盾 级
local checkButton_WaterShieldLevel = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 水之护盾层级 (自动识别)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WaterShieldLevel, GetCurrentSaved, "WaterShieldLevel")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPShamanHealSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPShamanHealSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y - 40



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsShamanHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanHealSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPShamanHealSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)

postion_y = postion_y+40+40


-- 治疗波 血线
local slider_Wave_Value = MPCreateConfigSlider(ADDON_NAME.."SliderWave_Value", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y, 220, 16, 10, 99, 1, 60)

-- 值变化时的回调函数
slider_Wave_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_Wave_Value:GetName().."Text"]:SetText("治疗波启动 血线："..arg1.."%")
    MPShamanHealSaved[ConfigCurrent].Wave_Value = arg1
end)


postion_y = postion_y-40

-- 次级治疗波 血线
local slider_SecondaryWave_Value = MPCreateConfigSlider(ADDON_NAME.."SliderSecondaryWave_Value", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y, 220, 16, 10, 99, 1, 60)

-- 值变化时的回调函数
slider_SecondaryWave_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_SecondaryWave_Value:GetName().."Text"]:SetText("次级治疗波启动 血线："..arg1.."%")
    MPShamanHealSaved[ConfigCurrent].SecondaryWave_Value = arg1
end)



postion_y = postion_y-40

-- 治疗链最低等级
local slider_ChainMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderChainMinLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 3, 1, 100)

slider_ChainMinLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].ChainMinLevel = arg1
    _G[slider_ChainMinLevel:GetName().."Text"]:SetText("治疗链最低"..arg1.."级")
end)
-- 治疗链最高等级
local slider_ChainMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderChainMaxLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 3, 1, 0)

slider_ChainMaxLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].ChainMaxLevel = arg1
    _G[slider_ChainMaxLevel:GetName().."Text"]:SetText("治疗链最高"..arg1.."级")
end)


postion_y = postion_y-40

-- 次级治疗波最低等级
local slider_SecondaryWaveMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderSecondaryWaveMinLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 6, 1, 100)

slider_SecondaryWaveMinLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].SecondaryWaveMinLevel = arg1
    _G[slider_SecondaryWaveMinLevel:GetName().."Text"]:SetText("次级波最低"..arg1.."级")
end)
-- 次级治疗波最高等级
local slider_SecondaryWaveMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderSecondaryWaveMaxLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 6, 1, 0)

slider_SecondaryWaveMaxLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].SecondaryWaveMaxLevel = arg1
    _G[slider_SecondaryWaveMaxLevel:GetName().."Text"]:SetText("次级波最高"..arg1.."级")
end)


postion_y = postion_y-40

-- 治疗波最低等级
local slider_WaveMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderWaveMinLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 10, 1, 100)

slider_WaveMinLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].WaveMinLevel = arg1
    _G[slider_WaveMinLevel:GetName().."Text"]:SetText("治疗波最低"..arg1.."级")
end)
-- 治疗波最高等级
local slider_WaveMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderWaveMaxLevel", CatUISettingsShamanHealWindow, "TOPLEFT", CatUISettingsShamanHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 10, 1, 0)

slider_WaveMaxLevel:SetScript("OnValueChanged", function()
    MPShamanHealSaved[ConfigCurrent].WaveMaxLevel = arg1
    _G[slider_WaveMaxLevel:GetName().."Text"]:SetText("治疗波最高"..arg1.."级")
end)




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsShamanHealWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetShamanHealSettings(ConfigCurrent)
    MPInitShamanHealSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsShamanHealWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitShamanHealSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsShamanHealWindow, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsShamanHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsShamanHealWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF0070DE/sheal|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local ShamanHealSettingsUIVersion = 25

function MPResetShamanHealSettings(config)

    MPShamanHealSaved.Version = ShamanHealSettingsUIVersion

    -- 基本配置

    MPShamanHealSaved[config].Wave = 0
    MPShamanHealSaved[config].SecondaryWave = 0
    MPShamanHealSaved[config].Chain = 1
    MPShamanHealSaved[config].WaterShield = 1

    MPShamanHealSaved[config].Tip = 1
    MPShamanHealSaved[config].TargetFirst = 1
    MPShamanHealSaved[config].TargetTarget = 1
    MPShamanHealSaved[config].SelfFirst = 0
    MPShamanHealSaved[config].ScanTeam = 1
    MPShamanHealSaved[config].ScanTeam_Low = 1
    MPShamanHealSaved[config].ScanTeam_Rand = 0

    MPShamanHealSaved[config].Begin_Value = 99.5

    MPShamanHealSaved[config].EarthTotem = 1
    MPShamanHealSaved[config].EarthTotem_Value = "大地之力图腾"
    MPShamanHealSaved[config].FireTotem = 1
    MPShamanHealSaved[config].FireTotem_Value = "火舌图腾"
    MPShamanHealSaved[config].WaterTotem = 1
    MPShamanHealSaved[config].WaterTotem_Value = "法力之泉图腾"
    MPShamanHealSaved[config].AirTotem = 1
    MPShamanHealSaved[config].AirTotem_Value = "风怒图腾"

    MPShamanHealSaved[config].RecallTotems = 1
    MPShamanHealSaved[config].RecallTotems_Value = 40

    MPShamanHealSaved[config].ForceTotem = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPShamanHealSaved[config].HealthStone = 1
    MPShamanHealSaved[config].HealthStone_Value = 30
    MPShamanHealSaved[config].HerbalTea = 1
    MPShamanHealSaved[config].HerbalTea_Value = 20
    MPShamanHealSaved[config].HerbalTeaMana = 0
    MPShamanHealSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPShamanHealSaved[config].SuperWoW = 1
    MPShamanHealSaved[config].UnitXP = 1

    MPShamanHealSaved[config].Overflow = 0

    MPShamanHealSaved[config].Wave_Value = 60
    MPShamanHealSaved[config].SecondaryWave_Value = 90
    MPShamanHealSaved[config].WaterShieldLevel = 0

    MPShamanHealSaved[config].ChainMinLevel = 1
    MPShamanHealSaved[config].ChainMaxLevel = 3
    MPShamanHealSaved[config].SecondaryWaveMinLevel = 1
    MPShamanHealSaved[config].SecondaryWaveMaxLevel = 6
    MPShamanHealSaved[config].WaveMinLevel = 1
    MPShamanHealSaved[config].WaveMaxLevel = 10

    -- 通用
    MPShamanHealSaved[config].Power = 0
    MPShamanHealSaved[config].Pick = 0

end


function InitShamanHealSettingsPart1()
    checkButton_Wave:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].Wave))
    checkButton_SecondaryWave:SetChecked( MPToBoolean(MPShamanHealSaved[ConfigCurrent].SecondaryWave) )
    checkButton_Chain:SetChecked( MPToBoolean(MPShamanHealSaved[ConfigCurrent].Chain) )
    checkButton_WaterShield:SetChecked( MPToBoolean(MPShamanHealSaved[ConfigCurrent].WaterShield) )

    checkButton_TargetFirst:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].TargetFirst))
    checkButton_TargetTarget:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].TargetTarget))
    checkButton_SelfFirst:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].SelfFirst))
    checkButton_ScanTeam:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam))
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ScanTeam_Rand))
    checkButton_Tip:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].Tip))

    checkButton_Overflow:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].Overflow))
    checkButton_WaterShieldLevel:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].WaterShieldLevel))

    checkButton_Power:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].Pick))

    slider_ChainMinLevel:SetValue(MPShamanHealSaved[ConfigCurrent].ChainMinLevel)
    slider_ChainMaxLevel:SetValue(MPShamanHealSaved[ConfigCurrent].ChainMaxLevel)
    slider_SecondaryWaveMinLevel:SetValue(MPShamanHealSaved[ConfigCurrent].SecondaryWaveMinLevel)
    slider_SecondaryWaveMaxLevel:SetValue(MPShamanHealSaved[ConfigCurrent].SecondaryWaveMaxLevel)
    slider_WaveMinLevel:SetValue(MPShamanHealSaved[ConfigCurrent].WaveMinLevel)
    slider_WaveMaxLevel:SetValue(MPShamanHealSaved[ConfigCurrent].WaveMaxLevel)
end

function MPInitShamanHealSettings()
    if not MPShamanHealSaved then
        MPShamanHealSaved = {}

        -- 第一套配置
        if not MPShamanHealSaved[1] then
            MPShamanHealSaved[1] = {}
            MPResetShamanHealSettings(1)
        end

        -- 第二套配置
        if not MPShamanHealSaved[2] then
            MPShamanHealSaved[2] = {}
            MPResetShamanHealSettings(2)
        end

        -- 第三套配置
        if not MPShamanHealSaved[3] then
            MPShamanHealSaved[3] = {}
            MPResetShamanHealSettings(3)
        end
    end

    if MPShamanHealSaved.Version ~= ShamanHealSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[奶萨宏]当前配置，这是新版插件正常数据更新！|r")
        MPShamanHealSaved[1] = {}
        MPShamanHealSaved[2] = {}
        MPShamanHealSaved[3] = {}
        MPResetShamanHealSettings(1)
        MPResetShamanHealSettings(2)
        MPResetShamanHealSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitShamanHealSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPShamanHealSaved[ConfigCurrent].HealthStone_Value)
    if MPShamanHealSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanHealSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPShamanHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPShamanHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPShamanHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPShamanHealSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPShamanHealSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")



    slider_Wave_Value:SetValue(MPShamanHealSaved[ConfigCurrent].Wave_Value)
    slider_SecondaryWave_Value:SetValue(MPShamanHealSaved[ConfigCurrent].SecondaryWave_Value)


    checkButton_EarthTotem:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].EarthTotem))
    for idx_EarthTotem, data_EarthTotem in pairs(modes_EarthTotem) do
        if string.find(data_EarthTotem.text, MPShamanHealSaved[ConfigCurrent].EarthTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, data_EarthTotem.value)
            _G[dropdown_EarthTotem:GetName().."Text"]:SetText(data_EarthTotem.text)
        end
    end

    checkButton_FireTotem:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].FireTotem))
    for idx_FireTotem, data_FireTotem in pairs(modes_FireTotem) do
        if string.find(data_FireTotem.text, MPShamanHealSaved[ConfigCurrent].FireTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_FireTotem, data_FireTotem.value)
            _G[dropdown_FireTotem:GetName().."Text"]:SetText(data_FireTotem.text)
        end
    end

    checkButton_WaterTotem:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].WaterTotem))
    for idx_WaterTotem, data_WaterTotem in pairs(modes_WaterTotem) do
        if string.find(data_WaterTotem.text, MPShamanHealSaved[ConfigCurrent].WaterTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, data_WaterTotem.value)
            _G[dropdown_WaterTotem:GetName().."Text"]:SetText(data_WaterTotem.text)
        end
    end

    checkButton_AirTotem:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].AirTotem))
    for idx_AirTotem, data_AirTotem in pairs(modes_AirTotem) do
        if string.find(data_AirTotem.text, MPShamanHealSaved[ConfigCurrent].AirTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_AirTotem, data_AirTotem.value)
            _G[dropdown_AirTotem:GetName().."Text"]:SetText(data_AirTotem.text)
        end
    end


    --[[
    checkButton_RecallTotems:SetChecked(MPShamanHealSaved[ConfigCurrent].RecallTotems)
    slider_RecallTotems:SetValue(MPShamanHealSaved[ConfigCurrent].RecallTotems_Value)
    if MPShamanHealSaved[ConfigCurrent].RecallTotems==1 then
        color_RecallTotems = "|cFFFFD100"
    else
        color_RecallTotems = "|cFF888888"
    end
    _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." ".. MPShamanHealSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    ]]

    checkButton_ForceTotem:SetChecked(MPToBoolean(MPShamanHealSaved[ConfigCurrent].ForceTotem))

    slider_Begin_Value:SetValue(MPShamanHealSaved[ConfigCurrent].Begin_Value)


end

