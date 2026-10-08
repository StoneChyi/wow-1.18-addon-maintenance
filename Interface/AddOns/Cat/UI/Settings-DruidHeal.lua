
-- 定义插件名称
local ADDON_NAME = "Settings-DruidHeal"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPDruidHealSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsDruidHealWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 620, "|cFFFF7D0A设置 - 奶德|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsDruidHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 生命之树形态
local checkButton_Shapeshift = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 生命之树形态")


-- 创建单选框 - 优先治疗目标
local checkButton_TargetFirst = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标")
MPBindConfigCheckButton(checkButton_TargetFirst, GetCurrentSaved, "TargetFirst")



postion_y = postion_y-30

-- 创建单选框 - 愈合
local checkButton_Regrowth = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 愈合 (主技能，谨慎关闭)")
MPBindConfigCheckButton(checkButton_Regrowth, GetCurrentSaved, "Regrowth")

-- 创建单选框 - 优先治疗目标 的 目标
local checkButton_TargetTarget = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标 的 目标")
MPBindConfigCheckButton(checkButton_TargetTarget, GetCurrentSaved, "TargetTarget")




postion_y = postion_y-30

-- 创建单选框 - 治疗之触
local checkButton_HealingTouch = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 治疗之触 (优先级>愈合)")
checkButton_HealingTouch:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].HealingTouch = 1
        MPDruidHealSaved[ConfigCurrent].Shapeshift = 0
    else
        MPDruidHealSaved[ConfigCurrent].HealingTouch = 0
    end
    checkButton_Shapeshift:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Shapeshift))
    checkButton_HealingTouch:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].HealingTouch))

end)

-- 形态点击事件
checkButton_Shapeshift:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].Shapeshift = 1
        MPDruidHealSaved[ConfigCurrent].HealingTouch = 0
    else
        MPDruidHealSaved[ConfigCurrent].Shapeshift = 0
    end
    checkButton_Shapeshift:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Shapeshift))
    checkButton_HealingTouch:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].HealingTouch))
end)

-- 创建单选框 - 优先治疗自己
local checkButton_SelfFirst = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 自己 (谨慎开启)")
MPBindConfigCheckButton(checkButton_SelfFirst, GetCurrentSaved, "SelfFirst")




postion_y = postion_y-30


-- 创建单选框 - 迅捷治愈
local checkButton_Swiftmend = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 迅捷治愈")
MPBindConfigCheckButton(checkButton_Swiftmend, GetCurrentSaved, "Swiftmend")


-- 创建单选框 - 优先治疗小队
local checkButton_PartyFirst = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 小队")
MPBindConfigCheckButton(checkButton_PartyFirst, GetCurrentSaved, "PartyFirst")



postion_y = postion_y-30

-- 创建单选框 - 移动回春
local checkButton_MoveRejuvenation = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 回春术 (移动时)")
MPBindConfigCheckButton(checkButton_MoveRejuvenation, GetCurrentSaved, "MoveRejuvenation")


-- 创建单选框 - 治疗大团
local checkButton_ScanTeam = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "治疗大团")
MPBindConfigCheckButton(checkButton_ScanTeam, GetCurrentSaved, "ScanTeam")

local checkButton_ScanTeam_Low = MPCreateCheckButtonSmall(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 460, postion_y, "血量最低")
local checkButton_ScanTeam_Rand = MPCreateCheckButtonSmall(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 560, postion_y, "随机")

checkButton_ScanTeam_Low:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Low = 1
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand = 0
    else
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Low = 0
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand))
end)
checkButton_ScanTeam_Rand:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand = 1
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Low = 0
    else
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand = 0
        MPDruidHealSaved[ConfigCurrent].ScanTeam_Low = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand))
end)

-- 创建单选框 - Tip
local checkButton_Tip = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 提示信息")
checkButton_Tip:Hide()
MPBindConfigCheckButton(checkButton_Tip, GetCurrentSaved, "Tip")



postion_y = postion_y-30

-- 创建单选框 - 重叠愈合
local checkButton_RegrowthAgain = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 百花齐放 (树形态)")
MPBindConfigCheckButton(checkButton_RegrowthAgain, GetCurrentSaved, "RegrowthAgain")


postion_y = postion_y - 50

--起始治疗
local slider_Begin_Value = MPCreateConfigSlider(ADDON_NAME.."SliderBegin_Value", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 80, 100, 0.5, 0)

-- 值变化时的回调函数
slider_Begin_Value:SetScript("OnValueChanged", function()
    _G[slider_Begin_Value:GetName().."Text"]:SetText("起始治疗 血线："..arg1.."%")
    MPDruidHealSaved[ConfigCurrent].Begin_Value = arg1
end)




-- 高级



postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsDruidHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100


-- 创建单选框 - 溢出治疗
local checkButton_Overflow = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用 溢出治疗时打断施法")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overflow, GetCurrentSaved, "Overflow")




-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPDruidHealSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPDruidHealSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40





-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidHealSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPDruidHealSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsDruidHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidHealSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPDruidHealSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y+30+40

-- 百花齐放 血线
local slider_RegrowthAgain_Value = MPCreateConfigSlider(ADDON_NAME.."SliderRegrowthAgain_Value", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_RegrowthAgain_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_RegrowthAgain_Value:GetName().."Text"]:SetText("百花齐放 血线："..arg1.."%")
    MPDruidHealSaved[ConfigCurrent].RegrowthAgain_Value = arg1
end)



postion_y = postion_y-40

-- 迅捷治愈 血线
local slider_Swiftmend_Value = MPCreateConfigSlider(ADDON_NAME.."SliderSwiftmend_Value", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_Swiftmend_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_Swiftmend_Value:GetName().."Text"]:SetText("迅捷治愈 血线："..arg1.."%")
    MPDruidHealSaved[ConfigCurrent].Swiftmend_Value = arg1
end)


postion_y = postion_y-40

-- 回春最低等级
local slider_RejuvenationMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRejuvenationMinLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 105, 16, 1, 11, 1, 100)

-- 值变化时的回调函数
slider_RejuvenationMinLevel:SetScript("OnValueChanged", function()
    _G[slider_RejuvenationMinLevel:GetName().."Text"]:SetText("回春最低"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].RejuvenationMinLevel = arg1
end)

-- 回春最高等级
local slider_RejuvenationMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRejuvenationMaxLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 135, postion_y+40, 105, 16, 1, 11, 1, 0)

-- 值变化时的回调函数
slider_RejuvenationMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_RejuvenationMaxLevel:GetName().."Text"]:SetText("回春最高"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].RejuvenationMaxLevel = arg1
end)



postion_y = postion_y-40

-- 愈合最高等级
local slider_RegrowthMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRegrowthMinLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 105, 16, 1, 9, 1, 100)

-- 值变化时的回调函数
slider_RegrowthMinLevel:SetScript("OnValueChanged", function()
    _G[slider_RegrowthMinLevel:GetName().."Text"]:SetText("愈合最低"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].RegrowthMinLevel = arg1
end)

-- 愈合最高等级
local slider_RegrowthMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRegrowthMaxLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 135, postion_y+40, 105, 16, 1, 9, 1, 0)

-- 值变化时的回调函数
slider_RegrowthMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_RegrowthMaxLevel:GetName().."Text"]:SetText("愈合最高"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].RegrowthMaxLevel = arg1
end)


postion_y = postion_y-40

-- 治疗之触最低等级
local slider_TouchMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderTouchMinLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 20, postion_y+40, 105, 16, 1, 11, 1, 100)

-- 值变化时的回调函数
slider_TouchMinLevel:SetScript("OnValueChanged", function()
    _G[slider_TouchMinLevel:GetName().."Text"]:SetText("触最低"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].TouchMinLevel = arg1
end)

-- 治疗之触最高等级
local slider_TouchMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderTouchMaxLevel", CatUISettingsDruidHealWindow, "TOPLEFT", CatUISettingsDruidHealWindow, "TOPLEFT", 135, postion_y+40, 105, 16, 1, 11, 1, 0)

-- 值变化时的回调函数
slider_TouchMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_TouchMaxLevel:GetName().."Text"]:SetText("触最高"..arg1.."级")
    MPDruidHealSaved[ConfigCurrent].TouchMaxLevel = arg1
end)




local myButton = MPCreateButton(CatUISettingsDruidHealWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetDruidHealSettings(ConfigCurrent)
    MPInitDruidHealSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsDruidHealWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitDruidHealSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsDruidHealWindow, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsDruidHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsDruidHealWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFF7D0A/dheal|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local DruidHealSettingsUIVersion = 21

function MPResetDruidHealSettings(config)

    MPDruidHealSaved.Version = DruidHealSettingsUIVersion

    -- 基本配置

    MPDruidHealSaved[config].Shapeshift = 1
    MPDruidHealSaved[config].MoveRejuvenation = 1
    MPDruidHealSaved[config].Regrowth = 1
    MPDruidHealSaved[config].HealingTouch = 0
    MPDruidHealSaved[config].Swiftmend = 1
    MPDruidHealSaved[config].Tip = 1
    MPDruidHealSaved[config].TargetFirst = 1
    MPDruidHealSaved[config].TargetTarget = 1
    MPDruidHealSaved[config].SelfFirst = 0
    MPDruidHealSaved[config].PartyFirst = 0
    MPDruidHealSaved[config].ScanTeam = 1
    MPDruidHealSaved[config].ScanTeam_Low = 1
    MPDruidHealSaved[config].ScanTeam_Rand = 0
    MPDruidHealSaved[config].RegrowthAgain = 1
    MPDruidHealSaved[config].Overflow = 0

    MPDruidHealSaved[config].Begin_Value = 99.5

    -- 高级配置

    -- 治疗石、糖水茶
    MPDruidHealSaved[config].HealthStone = 1
    MPDruidHealSaved[config].HealthStone_Value = 30
    MPDruidHealSaved[config].HerbalTea = 1
    MPDruidHealSaved[config].HerbalTea_Value = 20
    MPDruidHealSaved[config].HerbalTeaMana = 0
    MPDruidHealSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPDruidHealSaved[config].SuperWoW = 1
    MPDruidHealSaved[config].UnitXP = 1

    MPDruidHealSaved[config].Regrowth_Value = 99
    MPDruidHealSaved[config].Rejuvenation_Value = 99
    MPDruidHealSaved[config].Swiftmend_Value = 50
    MPDruidHealSaved[config].RegrowthAgain_Value = 70

    MPDruidHealSaved[config].RejuvenationMinLevel = 1
    MPDruidHealSaved[config].RejuvenationMaxLevel = 11
    MPDruidHealSaved[config].RegrowthMinLevel = 1
    MPDruidHealSaved[config].RegrowthMaxLevel = 9
    MPDruidHealSaved[config].TouchMinLevel = 1
    MPDruidHealSaved[config].TouchMaxLevel = 11

    -- 通用
    MPDruidHealSaved[config].Power = 0
    MPDruidHealSaved[config].Pick = 0
end


function MPInitDruidHealSettingsPart1()
    checkButton_Shapeshift:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Shapeshift))
    checkButton_MoveRejuvenation:SetChecked( MPToBoolean(MPDruidHealSaved[ConfigCurrent].MoveRejuvenation) )
    checkButton_Regrowth:SetChecked( MPToBoolean(MPDruidHealSaved[ConfigCurrent].Regrowth) )
    checkButton_HealingTouch:SetChecked( MPToBoolean(MPDruidHealSaved[ConfigCurrent].HealingTouch) )
    checkButton_Swiftmend:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Swiftmend))
    checkButton_RegrowthAgain:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].RegrowthAgain))

    checkButton_TargetFirst:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].TargetFirst))
    checkButton_TargetTarget:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].TargetTarget))
    checkButton_SelfFirst:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].SelfFirst))
    checkButton_PartyFirst:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].PartyFirst))
    checkButton_ScanTeam:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam))
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].ScanTeam_Rand))
    checkButton_Tip:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Tip))

    checkButton_Overflow:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Overflow))

    checkButton_Power:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].Pick))
end

function MPInitDruidHealSettings()
    if not MPDruidHealSaved then
        MPDruidHealSaved = {}

        -- 第一套配置
        if not MPDruidHealSaved[1] then
            MPDruidHealSaved[1] = {}
            MPResetDruidHealSettings(1)
        end

        -- 第二套配置
        if not MPDruidHealSaved[2] then
            MPDruidHealSaved[2] = {}
            MPResetDruidHealSettings(2)
        end

        -- 第三套配置
        if not MPDruidHealSaved[3] then
            MPDruidHealSaved[3] = {}
            MPResetDruidHealSettings(3)
        end
    end

    if MPDruidHealSaved.Version ~= DruidHealSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[奶德宏]当前配置，这是新版插件正常数据更新！|r")
        MPDruidHealSaved[1] = {}
        MPDruidHealSaved[2] = {}
        MPDruidHealSaved[3] = {}
        MPResetDruidHealSettings(1)
        MPResetDruidHealSettings(2)
        MPResetDruidHealSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)


    MPInitDruidHealSettingsPart1()


    checkButton_HealthStone:SetChecked(MPToBoolean(MPDruidHealSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPDruidHealSaved[ConfigCurrent].HealthStone_Value)
    if MPDruidHealSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidHealSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPDruidHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPDruidHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPDruidHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPDruidHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPDruidHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPDruidHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPDruidHealSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPDruidHealSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    --slider_Regrowth_Value:SetValue(MPDruidHealSaved[ConfigCurrent].Regrowth_Value)
    --slider_Rejuvenation_Value:SetValue(MPDruidHealSaved[ConfigCurrent].Rejuvenation_Value)
    slider_RegrowthAgain_Value:SetValue(MPDruidHealSaved[ConfigCurrent].RegrowthAgain_Value)
    slider_Swiftmend_Value:SetValue(MPDruidHealSaved[ConfigCurrent].Swiftmend_Value)

    slider_Begin_Value:SetValue(MPDruidHealSaved[ConfigCurrent].Begin_Value)

    slider_RejuvenationMinLevel:SetValue(MPDruidHealSaved[ConfigCurrent].RejuvenationMinLevel)
    slider_RejuvenationMaxLevel:SetValue(MPDruidHealSaved[ConfigCurrent].RejuvenationMaxLevel)
    slider_RegrowthMinLevel:SetValue(MPDruidHealSaved[ConfigCurrent].RegrowthMinLevel)
    slider_RegrowthMaxLevel:SetValue(MPDruidHealSaved[ConfigCurrent].RegrowthMaxLevel)
    slider_TouchMinLevel:SetValue(MPDruidHealSaved[ConfigCurrent].TouchMinLevel)
    slider_TouchMaxLevel:SetValue(MPDruidHealSaved[ConfigCurrent].TouchMaxLevel)

end

