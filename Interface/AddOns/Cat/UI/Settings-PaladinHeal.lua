
-- 定义插件名称
local ADDON_NAME = "Settings-PaladinHeal"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPPaladinHealSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsPaladinHealWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 600, "|cFFF58CBA设置 - 奶骑|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPaladinHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)




local postion_y = postion_y-40

-- 创建单选框 - 圣光术
local checkButton_HolyLight = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣光术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyLight, GetCurrentSaved, "HolyLight")


-- 创建单选框 - 优先治疗目标
local checkButton_TargetFirst = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetFirst, GetCurrentSaved, "TargetFirst")



postion_y = postion_y-30

-- 创建单选框 - 圣光闪现
local checkButton_FlashLight = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣光闪现")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FlashLight, GetCurrentSaved, "FlashLight")

-- 创建单选框 - 优先治疗目标 的 目标
local checkButton_TargetTarget = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标 的 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetTarget, GetCurrentSaved, "TargetTarget")



postion_y = postion_y-30

-- 创建单选框 - 神圣震击
local checkButton_HolyShock = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 神圣震击 (移动也能施放)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyShock, GetCurrentSaved, "HolyShock")


-- 创建单选框 - 优先治疗自己
local checkButton_SelfFirst = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 自己 (谨慎开启)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SelfFirst, GetCurrentSaved, "SelfFirst")




postion_y = postion_y-30

-- 创建单选框 - 圣疗
local checkButton_LayHands = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣疗术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_LayHands, GetCurrentSaved, "LayHands")


-- 创建单选框 - 治疗大团
local checkButton_ScanTeam = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "治疗大团")
MPBindConfigCheckButton(checkButton_ScanTeam, GetCurrentSaved, "ScanTeam")

local checkButton_ScanTeam_Low = MPCreateCheckButtonSmall(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 460, postion_y, "血量最低")
local checkButton_ScanTeam_Rand = MPCreateCheckButtonSmall(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 560, postion_y, "随机")

checkButton_ScanTeam_Low:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low = 1
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand = 0
    else
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low = 0
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand))
end)
checkButton_ScanTeam_Rand:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand = 1
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low = 0
    else
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand = 0
        MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low = 1
    end
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand))
end)


postion_y = postion_y-30

-- 创建单选框 - 神圣打击
local checkButton_SacredStrike = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 神圣打击 (近战奶)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SacredStrike, GetCurrentSaved, "SacredStrike")

--[[
postion_y = postion_y - 30

-- 创建单选框 - Tip
local checkButton_Tip = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 提示信息")
checkButton_Tip:Hide()
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Tip, GetCurrentSaved, "Tip")
]]
postion_y = postion_y - 50

--起始治疗
local slider_Begin_Value = MPCreateConfigSlider(ADDON_NAME.."SliderBegin_Value", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 80, 100, 0.5, 0)

-- 值变化时的回调函数
slider_Begin_Value:SetScript("OnValueChanged", function()
    _G[slider_Begin_Value:GetName().."Text"]:SetText("起始治疗 血线："..arg1.."%")
    MPPaladinHealSaved[ConfigCurrent].Begin_Value = arg1
end)




-- 高级



postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsPaladinHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-90


-- 创建单选框 - 溢出治疗
local checkButton_Overflow = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用 溢出治疗时打断施法")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overflow, GetCurrentSaved, "Overflow")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 300)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinHealSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPaladinHealSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40





-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPaladinHealSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)




postion_y = postion_y - 40


-- 创建单选框 - 保护之手
local checkButton_Protection = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 保护之手")

local slider_Protection = MPCreateConfigSlider(ADDON_NAME.."Slider_Protection", checkButton_Protection, "RIGHT", checkButton_Protection, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_Protection = "|cFFFFD100"

-- 值变化时的回调函数
slider_Protection:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinHealSaved[ConfigCurrent].Protection_Value = arg1
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinHealSaved[ConfigCurrent].Protection_Value .."%|r")
end)

-- 设置点击事件
checkButton_Protection:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].Protection = 1
        color_Protection = "|cFFFFD100"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinHealSaved[ConfigCurrent].Protection_Value .."%|r")
    else
        MPPaladinHealSaved[ConfigCurrent].Protection = 0
        color_Protection = "|cFF888888"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinHealSaved[ConfigCurrent].Protection_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 圣盾术
local checkButton_DivineShield = MPCreateCheckButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 圣盾术")

local slider_DivineShield = MPCreateConfigSlider(ADDON_NAME.."Slider_DivineShield", checkButton_DivineShield, "RIGHT", checkButton_DivineShield, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_DivineShield = "|cFFFFD100"

-- 值变化时的回调函数
slider_DivineShield:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinHealSaved[ConfigCurrent].DivineShield_Value = arg1
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
end)

-- 设置点击事件
checkButton_DivineShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinHealSaved[ConfigCurrent].DivineShield = 1
        color_DivineShield = "|cFFFFD100"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
    else
        MPPaladinHealSaved[ConfigCurrent].DivineShield = 0
        color_DivineShield = "|cFF888888"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
    end
end)


postion_y = postion_y+100+40


-- 圣光术 血线
local slider_HolyLight_Value = MPCreateConfigSlider(ADDON_NAME.."SliderHolyLight_Value", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 99, 1, 2000)

-- 值变化时的回调函数
slider_HolyLight_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_HolyLight_Value:GetName().."Text"]:SetText("圣光术 血线："..arg1.."%")
    MPPaladinHealSaved[ConfigCurrent].HolyLight_Value = arg1
end)




postion_y = postion_y-40

-- 神圣震击 血线
local slider_HolyShock_Value = MPCreateConfigSlider(ADDON_NAME.."SliderHolyShock_Value", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_HolyShock_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_HolyShock_Value:GetName().."Text"]:SetText("神圣震击 血线："..arg1.."%")
    MPPaladinHealSaved[ConfigCurrent].HolyShock_Value = arg1
end)


postion_y = postion_y-40

-- 圣疗术 血线
local slider_LayHands_Value = MPCreateConfigSlider(ADDON_NAME.."SliderLayHands_Value", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 90, 10, 11)

-- 值变化时的回调函数
slider_LayHands_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_LayHands_Value:GetName().."Text"]:SetText("圣疗术 血线："..arg1.."%")
    MPPaladinHealSaved[ConfigCurrent].LayHands_Value = arg1
end)


postion_y = postion_y-40

-- 圣光闪现最低等级
local slider_FlashLightMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderLayFlashLightMinLevel", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 105, 16, 1, 7, 1, 100)

-- 值变化时的回调函数
slider_FlashLightMinLevel:SetScript("OnValueChanged", function()
    _G[slider_FlashLightMinLevel:GetName().."Text"]:SetText("圣光闪现最低"..arg1.."级")
    MPPaladinHealSaved[ConfigCurrent].FlashLightMinLevel = arg1
end)

-- 圣光闪现最高等级
local slider_FlashLightMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderLayFlashLightMaxLevel", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 135, postion_y+40, 105, 16, 1, 7, 1, 0)

slider_FlashLightMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_FlashLightMaxLevel:GetName().."Text"]:SetText("圣光闪现最高"..arg1.."级")
    MPPaladinHealSaved[ConfigCurrent].FlashLightMaxLevel = arg1
end)


postion_y = postion_y-40

-- 圣光术最低等级
local slider_HolyLightMinLevel = MPCreateConfigSlider(ADDON_NAME.."SliderLayHolyLightMinLevel", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 20, postion_y+40, 105, 16, 1, 9, 1, 100)

slider_HolyLightMinLevel:SetScript("OnValueChanged", function()
    _G[slider_HolyLightMinLevel:GetName().."Text"]:SetText("圣光术最低"..arg1.."级")
    MPPaladinHealSaved[ConfigCurrent].HolyLightMinLevel = arg1
end)

-- 圣光术最高等级
local slider_HolyLightMaxLevel = MPCreateConfigSlider(ADDON_NAME.."SliderLayHolyLightMaxLevel", CatUISettingsPaladinHealWindow, "TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 135, postion_y+40, 105, 16, 1, 9, 1, 0)

slider_HolyLightMaxLevel:SetScript("OnValueChanged", function()
    _G[slider_HolyLightMaxLevel:GetName().."Text"]:SetText("圣光术最高"..arg1.."级")
    MPPaladinHealSaved[ConfigCurrent].HolyLightMaxLevel = arg1
end)




postion_y = postion_y+40



-- 动态控制
local ButtonControl = CreateFrame("Button", ADDON_NAME.."ButtonControl", CatUISettingsPaladinHealWindow, "UIPanelButtonTemplate")
ButtonControl:SetPoint("TOPLEFT", CatUISettingsPaladinHealWindow, "TOPLEFT", 340, postion_y)
ButtonControl:SetWidth(100)
ButtonControl:SetHeight(22)
ButtonControl:SetFont("Fonts\\FRIZQT__.TTF", 12)
ButtonControl:SetText("动态控制")

ButtonControl:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
ButtonControl:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
ButtonControl:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
ButtonControl:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
ButtonControl:SetScript("OnClick", function()
    MPCatPaladinControlHealInit()
    if CatPaladinHeal:IsVisible() then
        CatPaladinHeal:Hide()
        MPPublicSaved.PaladinHealDisplay = 0
    else
        CatPaladinHeal:Show()
        MPPublicSaved.PaladinHealDisplay = 1
    end
end)



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPaladinHealWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPaladinHealSettings(ConfigCurrent)
    MPInitPaladinHealSettings()

    CatPaladinHeal:Hide()
    CatPaladinHeal:ClearAllPoints()
    CatPaladinHeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPaladinHealWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPaladinHealSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPaladinHealWindow, ADDON_NAME, GetCurrentSaved)



-- 添加提示内容区域
local TipText = CatUISettingsPaladinHealWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPaladinHealWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFF58CBA/pheal|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PaladinHealSettingsUIVersion = 18

function MPResetPaladinHealSettings(config)

    MPPaladinHealSaved.Version = PaladinHealSettingsUIVersion

    -- 基本配置

    MPPaladinHealSaved[config].HolyLight = 1
    MPPaladinHealSaved[config].FlashLight = 1
    MPPaladinHealSaved[config].HolyShock = 1
    MPPaladinHealSaved[config].LayHands = 0
    MPPaladinHealSaved[config].SacredStrike = 1
    MPPaladinHealSaved[config].Tip = 1
    MPPaladinHealSaved[config].TargetFirst = 1
    MPPaladinHealSaved[config].TargetTarget = 1
    MPPaladinHealSaved[config].SelfFirst = 0
    MPPaladinHealSaved[config].ScanTeam = 1
    MPPaladinHealSaved[config].ScanTeam_Low = 1
    MPPaladinHealSaved[config].ScanTeam_Rand = 0

    MPPaladinHealSaved[config].Begin_Value = 99.5

    -- 高级配置
    MPPaladinHealSaved[config].Overflow = 0

    -- 治疗石、糖水茶
    MPPaladinHealSaved[config].HealthStone = 1
    MPPaladinHealSaved[config].HealthStone_Value = 30
    MPPaladinHealSaved[config].HerbalTea = 1
    MPPaladinHealSaved[config].HerbalTea_Value = 20
    MPPaladinHealSaved[config].HerbalTeaMana = 0
    MPPaladinHealSaved[config].HerbalTeaMana_Value = 20

    MPPaladinHealSaved[config].Protection = 0
    MPPaladinHealSaved[config].Protection_Value = 10
    MPPaladinHealSaved[config].DivineShield = 0
    MPPaladinHealSaved[config].DivineShield_Value = 10

    -- SuperWoW,UnitXP
    MPPaladinHealSaved[config].SuperWoW = 1
    MPPaladinHealSaved[config].UnitXP = 1

    MPPaladinHealSaved[config].HolyLight_Value = 60
    MPPaladinHealSaved[config].FlashLight_Value = 99
    MPPaladinHealSaved[config].HolyShock_Value = 70
    MPPaladinHealSaved[config].LayHands_Value = 20

    MPPaladinHealSaved[config].FlashLightMinLevel = 1
    MPPaladinHealSaved[config].FlashLightMaxLevel = 7
    MPPaladinHealSaved[config].HolyLightMinLevel = 1
    MPPaladinHealSaved[config].HolyLightMaxLevel = 9

    -- 通用
    MPPaladinHealSaved[config].Power = 0
    MPPaladinHealSaved[config].Pick = 0

end

local function InitPaladinHealSettingsPart1()
    checkButton_HolyLight:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].HolyLight))
    checkButton_FlashLight:SetChecked( MPToBoolean(MPPaladinHealSaved[ConfigCurrent].FlashLight) )
    checkButton_HolyShock:SetChecked( MPToBoolean(MPPaladinHealSaved[ConfigCurrent].HolyShock) )
    checkButton_LayHands:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].LayHands))
    checkButton_SacredStrike:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].SacredStrike))

    checkButton_TargetFirst:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].TargetFirst))
    checkButton_TargetTarget:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].TargetTarget))
    checkButton_SelfFirst:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].SelfFirst))
    checkButton_ScanTeam:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam))
    checkButton_ScanTeam_Low:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Low))
    checkButton_ScanTeam_Rand:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].ScanTeam_Rand))
    --checkButton_Tip:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].Tip))

    checkButton_Overflow:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].Overflow))

    checkButton_Power:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].Pick))

end

local function InitPaladinHealSettingsPart2()
    checkButton_HealthStone:SetChecked(MPToBoolean(MPPaladinHealSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPaladinHealSaved[ConfigCurrent].HealthStone_Value)
    if MPPaladinHealSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPaladinHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPPaladinHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_Protection:SetChecked(MPPaladinHealSaved[ConfigCurrent].Protection)
    slider_Protection:SetValue(MPPaladinHealSaved[ConfigCurrent].Protection_Value)
    if MPPaladinHealSaved[ConfigCurrent].Protection==1 then
        color_Protection = "|cFFFFD100"
    else
        color_Protection = "|cFF888888"
    end
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinHealSaved[ConfigCurrent].Protection_Value .."%|r")


    checkButton_DivineShield:SetChecked(MPPaladinHealSaved[ConfigCurrent].DivineShield)
    slider_DivineShield:SetValue(MPPaladinHealSaved[ConfigCurrent].DivineShield_Value)
    if MPPaladinHealSaved[ConfigCurrent].DivineShield==1 then
        color_DivineShield = "|cFFFFD100"
    else
        color_DivineShield = "|cFF888888"
    end
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinHealSaved[ConfigCurrent].DivineShield_Value .."%|r")



    slider_HolyLight_Value:SetValue(MPPaladinHealSaved[ConfigCurrent].HolyLight_Value)
    --slider_FlashLight_Value:SetValue(MPPaladinHealSaved[ConfigCurrent].FlashLight_Value)
    slider_HolyShock_Value:SetValue(MPPaladinHealSaved[ConfigCurrent].HolyShock_Value)
    slider_LayHands_Value:SetValue(MPPaladinHealSaved[ConfigCurrent].LayHands_Value)
    slider_Begin_Value:SetValue(MPPaladinHealSaved[ConfigCurrent].Begin_Value)

    slider_FlashLightMinLevel:SetValue(MPPaladinHealSaved[ConfigCurrent].FlashLightMinLevel)
    slider_FlashLightMaxLevel:SetValue(MPPaladinHealSaved[ConfigCurrent].FlashLightMaxLevel)
    slider_HolyLightMinLevel:SetValue(MPPaladinHealSaved[ConfigCurrent].HolyLightMinLevel)
    slider_HolyLightMaxLevel:SetValue(MPPaladinHealSaved[ConfigCurrent].HolyLightMaxLevel)

end

function MPInitPaladinHealSettings()
    if not MPPaladinHealSaved then
        MPPaladinHealSaved = {}

        -- 第一套配置
        if not MPPaladinHealSaved[1] then
            MPPaladinHealSaved[1] = {}
            MPResetPaladinHealSettings(1)
        end

        -- 第二套配置
        if not MPPaladinHealSaved[2] then
            MPPaladinHealSaved[2] = {}
            MPResetPaladinHealSettings(2)
        end

        -- 第三套配置
        if not MPPaladinHealSaved[3] then
            MPPaladinHealSaved[3] = {}
            MPResetPaladinHealSettings(3)
        end
    end

    if MPPaladinHealSaved.Version ~= PaladinHealSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[奶骑宏]当前配置，这是新版插件正常数据更新！|r")
        MPPaladinHealSaved[1] = {}
        MPPaladinHealSaved[2] = {}
        MPPaladinHealSaved[3] = {}
        MPResetPaladinHealSettings(1)
        MPResetPaladinHealSettings(2)
        MPResetPaladinHealSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitPaladinHealSettingsPart1()
    InitPaladinHealSettingsPart2()

end

