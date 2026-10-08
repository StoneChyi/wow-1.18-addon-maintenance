
-- 定义插件名称
local ADDON_NAME = "Settings-PriestHeal"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPPriestHealSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsPriestHealWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 680, "|cFFFFFFFF设置 - 神牧|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPriestHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)




local postion_y = postion_y-40

-- 治疗祷言
local checkButton_PrayerHealing = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 治疗祷言")
MPBindConfigCheckButton(checkButton_PrayerHealing, GetCurrentSaved, "PrayerHealing")



-- 创建单选框 - 优先治疗目标
local checkButton_TargetFirst = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetFirst, GetCurrentSaved, "TargetFirst")




postion_y = postion_y-30

-- 创建单选框 - 强效治疗术
local checkButton_GreaterHeal = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 强效治疗术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_GreaterHeal, GetCurrentSaved, "GreaterHeal")


-- 创建单选框 - 优先治疗目标 的 目标
local checkButton_TargetTarget = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标 的 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetTarget, GetCurrentSaved, "TargetTarget")




postion_y = postion_y-30

-- 创建单选框 - 快速治疗
local checkButton_FlashHeal = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 快速治疗")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FlashHeal, GetCurrentSaved, "FlashHeal")



-- 创建单选框 - 优先治疗自己
local checkButton_SelfFirst = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 自己 (谨慎开启)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SelfFirst, GetCurrentSaved, "SelfFirst")




postion_y = postion_y-30

-- 创建单选框 - 绝望祷言
local checkButton_DesperatePrayer = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 绝望祷言")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_DesperatePrayer, GetCurrentSaved, "DesperatePrayer")


-- 创建单选框 - 治疗大团
local checkButton_ScanTeam = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "治疗大团")
MPBindConfigCheckButton(checkButton_ScanTeam, GetCurrentSaved, "ScanTeam")

local checkButton_ScanTeam_Low = MPCreateCheckButtonSmall(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 460, postion_y, "血量最低")
local checkButton_ScanTeam_Rand = MPCreateCheckButtonSmall(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 560, postion_y, "随机")

checkButton_ScanTeam_Low:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Low = 1
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand = 0
    else
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Low = 0
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand))
end)
checkButton_ScanTeam_Rand:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand = 1
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Low = 0
    else
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand = 0
        MPPriestHealSaved[ConfigCurrent].ScanTeam_Low = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand))
end)



postion_y = postion_y-30


-- 创建单选框 - 移动恢复
local checkButton_MoveRenew = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 恢复 (移动时)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MoveRenew, GetCurrentSaved, "MoveRenew")


-- 创建单选框 - Tip
local checkButton_Tip = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 提示信息")
checkButton_Tip:Hide()
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Tip, GetCurrentSaved, "Tip")

postion_y = postion_y-30

-- 创建单选框 - 真言术：盾
local checkButton_Shield = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 真言术：盾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Shield, GetCurrentSaved, "Shield")

postion_y = postion_y - 40

-- 起始治疗
local slider_Begin_Value = MPCreateConfigSlider(ADDON_NAME.."SliderBegin_Value", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 80, 100, 0.5, 0)

-- 值变化时的回调函数
slider_Begin_Value:SetScript("OnValueChanged", function()
    _G[slider_Begin_Value:GetName().."Text"]:SetText("起始治疗 血线："..arg1.."%")
    MPPriestHealSaved[ConfigCurrent].Begin_Value = arg1
end)




-- 高级



postion_y = postion_y+5

-- 添加提示内容区域
local TipText1 = CatUISettingsPriestHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-90


-- 创建单选框 - 溢出治疗
local checkButton_Overflow = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用 溢出治疗时打断施法")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overflow, GetCurrentSaved, "Overflow")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 300)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPriestHealSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestHealSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPriestHealSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)



postion_y = postion_y-40


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestHealSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestHealSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPriestHealSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestHealSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPriestHealSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40


postion_y = postion_y - 40

-- 祈祷之书
local checkButton_PrayerBook = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "适配天赋 祈祷之书")
--checkButton_PrayerBook:Disable()
MPBindConfigCheckButton(checkButton_PrayerBook, GetCurrentSaved, "PrayerBook")

postion_y = postion_y - 40

-- 治疗祷言 本队优先
local checkButton_PrayerHealingPartyFirst = MPCreateCheckButton(CatUISettingsPriestHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "治疗祷言 本队优先")
MPBindConfigCheckButton(checkButton_PrayerHealingPartyFirst, GetCurrentSaved, "PrayerHealingPartyFirst")

-- 治疗祷言 权重
local slider_PrayerHealing_Value = MPCreateConfigSlider(ADDON_NAME.."SliderPrayerHealing_Value", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 270, postion_y+70, 220, 16, 2, 14, 1, 0)

-- 值变化时的回调函数
slider_PrayerHealing_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_PrayerHealing_Value:GetName().."Text"]:SetText("治疗祷言 权重："..arg1)
    MPPriestHealSaved[ConfigCurrent].PrayerHealing_Value = arg1
end)



postion_y = postion_y+60+40+40+40+40


-- 强效治疗 血线
local slider_GreaterHeal_Value = MPCreateConfigSlider(ADDON_NAME.."SliderGreaterHeal_Value", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 220, 16, 10, 100, 1, 0)

-- 值变化时的回调函数
slider_GreaterHeal_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_GreaterHeal_Value:GetName().."Text"]:SetText("强效治疗术​ 血线："..arg1.."%")
    MPPriestHealSaved[ConfigCurrent].GreaterHeal_Value = arg1
end)



postion_y = postion_y-40

-- 绝望祷言​ 血线
local slider_Desperate_Value = MPCreateConfigSlider(ADDON_NAME.."SliderDesperate_Value", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 220, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_Desperate_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_Desperate_Value:GetName().."Text"]:SetText("绝望祷言​ 血线："..arg1.."%")
    MPPriestHealSaved[ConfigCurrent].Desperate_Value = arg1
end)


postion_y = postion_y-40

-- 真言术：盾​ 血线
local slider_Shield_Value = MPCreateConfigSlider(ADDON_NAME.."SliderShield_Value", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 220, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_Shield_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_Shield_Value:GetName().."Text"]:SetText("真言术：盾​ 血线："..arg1.."%")
    MPPriestHealSaved[ConfigCurrent].Shield_Value = arg1
end)


postion_y = postion_y-40

-- 恢复最低等级
local slider_RenewMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRenewMinLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 10, 1, 100)

slider_RenewMinLevel:SetScript("OnValueChanged", function()
    _G[slider_RenewMinLevel:GetName().."Text"]:SetText("恢复最低"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].RenewMinLevel = arg1
end)

-- 恢复最高等级
local slider_RenewMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderRenewMaxLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 10, 1, 0)

slider_RenewMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_RenewMaxLevel:GetName().."Text"]:SetText("恢复最高"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].RenewMaxLevel = arg1
end)


postion_y = postion_y-40

-- 快速治疗​最低等级
local slider_FlashHealMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderFlashHealMinLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 7, 1, 100)

slider_FlashHealMinLevel:SetScript("OnValueChanged", function()
    _G[slider_FlashHealMinLevel:GetName().."Text"]:SetText("快速治疗最低"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].FlashHealMinLevel = arg1
end)

-- 快速治疗​最高等级
local slider_FlashHealMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderFlashHealMaxLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 7, 1, 0)

slider_FlashHealMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_FlashHealMaxLevel:GetName().."Text"]:SetText("快速治疗最高"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].FlashHealMaxLevel = arg1
end)


postion_y = postion_y-40

-- 强效治疗​最低等级
local slider_GreaterHealMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderGreaterHealMinLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 5, 1, 100)

slider_GreaterHealMinLevel:SetScript("OnValueChanged", function()
    _G[slider_GreaterHealMinLevel:GetName().."Text"]:SetText("强效治疗最低"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].GreaterHealMinLevel = arg1
end)

-- 强效治疗​最高等级
local slider_GreaterHealMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderGreaterHealMaxLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 5, 1, 0)

slider_GreaterHealMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_GreaterHealMaxLevel:GetName().."Text"]:SetText("强效治疗最高"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].GreaterHealMaxLevel = arg1
end)


postion_y = postion_y-40

-- 治疗祷言最低等级
local slider_PrayerHealingMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderPrayerHealingMinLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 20, postion_y, 105, 16, 1, 3, 1, 100)

slider_PrayerHealingMinLevel:SetScript("OnValueChanged", function()
    _G[slider_PrayerHealingMinLevel:GetName().."Text"]:SetText("治疗祷言最低"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].PrayerHealingMinLevel = arg1
end)

-- 强效治疗​最高等级
local slider_PrayerHealingMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderPrayerHealingMaxLevel", CatUISettingsPriestHealWindow, "TOPLEFT", CatUISettingsPriestHealWindow, "TOPLEFT", 135, postion_y, 105, 16, 1, 5, 1, 0)

slider_PrayerHealingMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_PrayerHealingMaxLevel:GetName().."Text"]:SetText("治疗祷言最高"..arg1.."级")
    MPPriestHealSaved[ConfigCurrent].PrayerHealingMaxLevel = arg1
end)




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPriestHealWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPriestHealSettings(ConfigCurrent)
    MPInitPriestHealSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPriestHealWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPriestHealSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPriestHealWindow, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsPriestHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPriestHealWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFFFFFF/mheal|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PriestHealSettingsUIVersion = 19

function MPResetPriestHealSettings(config)

    MPPriestHealSaved.Version = PriestHealSettingsUIVersion

    -- 基本配置

    MPPriestHealSaved[config].GreaterHeal = 1
    MPPriestHealSaved[config].PrayerHealing = 1
    MPPriestHealSaved[config].MoveRenew = 1
    MPPriestHealSaved[config].FlashHeal = 1
    MPPriestHealSaved[config].DesperatePrayer = 0
    MPPriestHealSaved[config].Shield = 0
    MPPriestHealSaved[config].Tip = 1
    MPPriestHealSaved[config].TargetFirst = 1
    MPPriestHealSaved[config].TargetTarget = 1
    MPPriestHealSaved[config].SelfFirst = 0
    MPPriestHealSaved[config].ScanTeam = 1
    MPPriestHealSaved[config].ScanTeam_Low = 1
    MPPriestHealSaved[config].ScanTeam_Rand = 0

    MPPriestHealSaved[config].Begin_Value = 99.5

    -- 高级配置

    -- 治疗石、糖水茶
    MPPriestHealSaved[config].HealthStone = 1
    MPPriestHealSaved[config].HealthStone_Value = 30
    MPPriestHealSaved[config].HerbalTea = 1
    MPPriestHealSaved[config].HerbalTea_Value = 20
    MPPriestHealSaved[config].HerbalTeaMana = 0
    MPPriestHealSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPPriestHealSaved[config].SuperWoW = 1
    MPPriestHealSaved[config].UnitXP = 1

    MPPriestHealSaved[config].Overflow = 0
    MPPriestHealSaved[config].PrayerBook = 0
    MPPriestHealSaved[config].PrayerBook_Value = 0

    MPPriestHealSaved[config].Desperate_Value = 20
    MPPriestHealSaved[config].GreaterHeal_Value = 99
    MPPriestHealSaved[config].Shield_Value = 30
    MPPriestHealSaved[config].PrayerHealingPartyFirst = 1
    MPPriestHealSaved[config].PrayerHealing_Value = 5

    MPPriestHealSaved[config].RenewMinLevel = 1
    MPPriestHealSaved[config].RenewMaxLevel = 10
    MPPriestHealSaved[config].FlashHealMinLevel = 1
    MPPriestHealSaved[config].FlashHealMaxLevel = 7
    MPPriestHealSaved[config].GreaterHealMinLevel = 1
    MPPriestHealSaved[config].GreaterHealMaxLevel = 5
    MPPriestHealSaved[config].PrayerHealingMinLevel = 1
    MPPriestHealSaved[config].PrayerHealingMaxLevel = 5

    -- 通用
    MPPriestHealSaved[config].Power = 0
    MPPriestHealSaved[config].Pick = 0

end


function MPInitPriestHealSettingsPart1()
    checkButton_GreaterHeal:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].GreaterHeal))
    checkButton_PrayerHealing:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].PrayerHealing))
    checkButton_MoveRenew:SetChecked( MPToBoolean(MPPriestHealSaved[ConfigCurrent].MoveRenew) )
    checkButton_FlashHeal:SetChecked( MPToBoolean(MPPriestHealSaved[ConfigCurrent].FlashHeal) )
    checkButton_DesperatePrayer:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].DesperatePrayer))
    checkButton_Shield:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].Shield))

    checkButton_TargetFirst:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].TargetFirst))
    checkButton_TargetTarget:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].TargetTarget))
    checkButton_SelfFirst:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].SelfFirst))
    checkButton_ScanTeam:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam))
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].ScanTeam_Rand))
    checkButton_Tip:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].Tip))

    checkButton_Overflow:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].Overflow))
    checkButton_PrayerBook:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].PrayerBook))
    checkButton_PrayerHealingPartyFirst:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].PrayerHealingPartyFirst))

    checkButton_Power:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].Pick))
end


function MPInitPriestHealSettings()
    if not MPPriestHealSaved then
        MPPriestHealSaved = {}

        -- 第一套配置
        if not MPPriestHealSaved[1] then
            MPPriestHealSaved[1] = {}
            MPResetPriestHealSettings(1)
        end

        -- 第二套配置
        if not MPPriestHealSaved[2] then
            MPPriestHealSaved[2] = {}
            MPResetPriestHealSettings(2)
        end

        -- 第三套配置
        if not MPPriestHealSaved[3] then
            MPPriestHealSaved[3] = {}
            MPResetPriestHealSettings(3)
        end
    end

    if MPPriestHealSaved.Version ~= PriestHealSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[神牧宏]当前配置，这是新版插件正常数据更新！|r")
        MPPriestHealSaved[1] = {}
        MPPriestHealSaved[2] = {}
        MPPriestHealSaved[3] = {}
        MPResetPriestHealSettings(1)
        MPResetPriestHealSettings(2)
        MPResetPriestHealSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitPriestHealSettingsPart1()


    checkButton_HealthStone:SetChecked(MPToBoolean(MPPriestHealSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPriestHealSaved[ConfigCurrent].HealthStone_Value)
    if MPPriestHealSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestHealSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPriestHealSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPriestHealSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    slider_GreaterHeal_Value:SetValue(MPPriestHealSaved[ConfigCurrent].GreaterHeal_Value)
    slider_Desperate_Value:SetValue(MPPriestHealSaved[ConfigCurrent].Desperate_Value)

    slider_Begin_Value:SetValue(MPPriestHealSaved[ConfigCurrent].Begin_Value)
    slider_Shield_Value:SetValue(MPPriestHealSaved[ConfigCurrent].Shield_Value)

    slider_RenewMinLevel:SetValue(MPPriestHealSaved[ConfigCurrent].RenewMinLevel)
    slider_RenewMaxLevel:SetValue(MPPriestHealSaved[ConfigCurrent].RenewMaxLevel)
    slider_FlashHealMinLevel:SetValue(MPPriestHealSaved[ConfigCurrent].FlashHealMinLevel)
    slider_FlashHealMaxLevel:SetValue(MPPriestHealSaved[ConfigCurrent].FlashHealMaxLevel)
    slider_GreaterHealMinLevel:SetValue(MPPriestHealSaved[ConfigCurrent].GreaterHealMinLevel)
    slider_GreaterHealMaxLevel:SetValue(MPPriestHealSaved[ConfigCurrent].GreaterHealMaxLevel)
    slider_PrayerHealingMinLevel:SetValue(MPPriestHealSaved[ConfigCurrent].PrayerHealingMinLevel)
    slider_PrayerHealingMaxLevel:SetValue(MPPriestHealSaved[ConfigCurrent].PrayerHealingMaxLevel)

    slider_PrayerHealing_Value:SetValue(MPPriestHealSaved[ConfigCurrent].PrayerHealing_Value)

end

