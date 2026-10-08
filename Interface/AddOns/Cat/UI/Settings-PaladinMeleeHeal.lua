
-- 定义插件名称
local ADDON_NAME = "Settings-PaladinMeleeHeal"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPPaladinMeleeHealSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsPaladinMeleeHeal = MPCreateFrame(ADDON_NAME.."Frame", 520, 540, "|cFFF58CBA设置 - 近战奶骑|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPaladinMeleeHeal:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 圣光术
local checkButton_HolyLight = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣光术 (神圣制裁)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyLight, GetCurrentSaved, "HolyLight")


-- 创建单选框 - 优先治疗目标
local checkButton_TargetFirst = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetFirst, GetCurrentSaved, "TargetFirst")




postion_y = postion_y-30

-- 创建单选框 - 圣光闪现
local checkButton_FlashLight = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣光闪现")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FlashLight, GetCurrentSaved, "FlashLight")

-- 创建单选框 - 优先治疗目标 的 目标
local checkButton_TargetTarget = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 目标 的 目标")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_TargetTarget, GetCurrentSaved, "TargetTarget")





postion_y = postion_y-30

-- 创建单选框 - 神圣震击
local checkButton_HolyShock = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "开启 神圣震击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyShock, GetCurrentSaved, "HolyShock")


-- 创建单选框 - 优先治疗自己
local checkButton_SelfFirst = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "优先治疗 自己 (谨慎开启)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SelfFirst, GetCurrentSaved, "SelfFirst")




postion_y = postion_y-30

-- 创建单选框 - 圣疗
local checkButton_LayHands = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "开启 圣疗术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_LayHands, GetCurrentSaved, "LayHands")


-- 创建单选框 - 治疗大团
local checkButton_ScanTeam = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "扫描治疗大团 (血量最低)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ScanTeam, GetCurrentSaved, "ScanTeam")


postion_y = postion_y - 30


-- 创建单选框 - 启用 十字军打击 (重置神圣震击)
local checkButton_CrusaderStrike = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "启用 十字军打击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CrusaderStrike, GetCurrentSaved, "CrusaderStrike")


-- 创建单选框 - Tip
local checkButton_Tip = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "开启 提示信息")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Tip, GetCurrentSaved, "Tip")


postion_y = postion_y - 30

-- 创建单选框 - 启用 神圣打击 (治疗群体)
local checkButton_HolyStrike = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "启用 神圣打击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyStrike, GetCurrentSaved, "HolyStrike")


--起始治疗
local slider_Begin_Value = MPCreateConfigSlider(ADDON_NAME.."SliderBegin_Value", CatUISettingsPaladinMeleeHeal, "TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 270, postion_y+20, 220, 16, 80, 100, 0.5, 0)

-- 值变化时的回调函数
slider_Begin_Value:SetScript("OnValueChanged", function()
    _G[slider_Begin_Value:GetName().."Text"]:SetText("起始治疗 血线："..arg1.."%")
    MPPaladinMeleeHealSaved[ConfigCurrent].Begin_Value = arg1
end)




-- 高级



postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsPaladinMeleeHeal:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-90


-- 创建单选框 - 暴力治疗
local checkButton_Force = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "启用 暴力治疗 (强制最高等级)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Force, GetCurrentSaved, "Force")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 300)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 溢出治疗
local checkButton_Overflow = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 20, postion_y, "启用 溢出治疗时打断施法")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overflow, GetCurrentSaved, "Overflow")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)




postion_y = postion_y - 40

-- 创建单选框 - 保护之手
local checkButton_Protection = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "自动 保护之手")

local slider_Protection = MPCreateConfigSlider(ADDON_NAME.."Slider_Protection", checkButton_Protection, "RIGHT", checkButton_Protection, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_Protection = "|cFFFFD100"

-- 值变化时的回调函数
slider_Protection:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value = arg1
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value .."%|r")
end)

-- 设置点击事件
checkButton_Protection:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinMeleeHealSaved[ConfigCurrent].Protection = 1
        color_Protection = "|cFFFFD100"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value .."%|r")
    else
        MPPaladinMeleeHealSaved[ConfigCurrent].Protection = 0
        color_Protection = "|cFF888888"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 圣盾术
local checkButton_DivineShield = MPCreateCheckButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."CheckButton", 340, postion_y, "自动 圣盾术")

local slider_DivineShield = MPCreateConfigSlider(ADDON_NAME.."Slider_DivineShield", checkButton_DivineShield, "RIGHT", checkButton_DivineShield, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_DivineShield = "|cFFFFD100"

-- 值变化时的回调函数
slider_DivineShield:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value = arg1
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
end)

-- 设置点击事件
checkButton_DivineShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield = 1
        color_DivineShield = "|cFFFFD100"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
    else
        MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield = 0
        color_DivineShield = "|cFF888888"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value .."%|r")
    end
end)



postion_y = postion_y+100


-- 圣光术 血线
local slider_HolyLight_Value = MPCreateConfigSlider(ADDON_NAME.."SliderHolyLight_Value", CatUISettingsPaladinMeleeHeal, "TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 100, 1, 0)

-- 值变化时的回调函数
slider_HolyLight_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_HolyLight_Value:GetName().."Text"]:SetText("圣光术 血线："..arg1.."%")
    MPPaladinMeleeHealSaved[ConfigCurrent].HolyLight_Value = arg1
end)




postion_y = postion_y-40

-- 神圣震击 血线
local slider_HolyShock_Value = MPCreateConfigSlider(ADDON_NAME.."SliderHolyShock_Value", CatUISettingsPaladinMeleeHeal, "TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 100, 1, 0)

-- 值变化时的回调函数
slider_HolyShock_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_HolyShock_Value:GetName().."Text"]:SetText("神圣震击 血线："..arg1.."%")
    MPPaladinMeleeHealSaved[ConfigCurrent].HolyShock_Value = arg1
end)


postion_y = postion_y-40

-- 圣疗术 血线
local slider_LayHands_Value = MPCreateConfigSlider(ADDON_NAME.."SliderLayHands_Value", CatUISettingsPaladinMeleeHeal, "TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 20, postion_y+40, 220, 16, 10, 100, 1, 2000)

-- 值变化时的回调函数
slider_LayHands_Value:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_LayHands_Value:GetName().."Text"]:SetText("圣疗术 血线："..arg1.."%")
    MPPaladinMeleeHealSaved[ConfigCurrent].LayHands_Value = arg1
end)






postion_y = postion_y + 35

-- 动态控制
local ButtonAutoSeal = CreateFrame("Button", ADDON_NAME.."ButtonAutoSeal", CatUISettingsPaladinMeleeHeal, "UIPanelButtonTemplate")
ButtonAutoSeal:SetPoint("TOPLEFT", CatUISettingsPaladinMeleeHeal, "TOPLEFT", 340, postion_y)
ButtonAutoSeal:SetWidth(100)
ButtonAutoSeal:SetHeight(22)
ButtonAutoSeal:SetFont("Fonts\\FRIZQT__.TTF", 12)
ButtonAutoSeal:SetText("审判控制")

ButtonAutoSeal:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
ButtonAutoSeal:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
ButtonAutoSeal:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
ButtonAutoSeal:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
ButtonAutoSeal:SetScript("OnClick", function()
    MPCatPaladinSealInit()
    if CatPaladinSeal:IsVisible() then
        CatPaladinSeal:Hide()
        MPPublicSaved.PaladinSealDisplay = 0
    else
        CatPaladinSeal:Show()
        MPPublicSaved.PaladinSealDisplay = 1
    end
end)



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPaladinMeleeHeal, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPaladinMeleeHealSettings(ConfigCurrent)
    MPInitPaladinMeleeHealSettings()

    MPCatPaladinSealReset()
    CatPaladinSeal:Hide()
    CatPaladinSeal:ClearAllPoints()
    CatPaladinSeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

end)

local ConfigButton = MPCreateConfigSelector(CatUISettingsPaladinMeleeHeal, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPaladinMeleeHealSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPaladinMeleeHeal, ADDON_NAME, GetCurrentSaved)



-- 添加提示内容区域
local TipText = CatUISettingsPaladinMeleeHeal:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPaladinMeleeHeal, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFF58CBA/mpheal|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PaladinMeleeHealSettingsUIVersion = 3

function MPResetPaladinMeleeHealSettings(config)

    MPPaladinMeleeHealSaved.Version = PaladinMeleeHealSettingsUIVersion

    -- 基本配置

    MPPaladinMeleeHealSaved[config].HolyLight = 1
    MPPaladinMeleeHealSaved[config].FlashLight = 0
    MPPaladinMeleeHealSaved[config].HolyShock = 1
    MPPaladinMeleeHealSaved[config].LayHands = 0
    MPPaladinMeleeHealSaved[config].Justice = 1
    MPPaladinMeleeHealSaved[config].CrusaderStrike = 1
    MPPaladinMeleeHealSaved[config].HolyStrike = 1

    MPPaladinMeleeHealSaved[config].Tip = 1
    MPPaladinMeleeHealSaved[config].TargetFirst = 1
    MPPaladinMeleeHealSaved[config].TargetTarget = 1
    MPPaladinMeleeHealSaved[config].SelfFirst = 0
    MPPaladinMeleeHealSaved[config].ScanTeam = 1

    MPPaladinMeleeHealSaved[config].Begin_Value = 99.5

    -- 高级配置
    MPPaladinMeleeHealSaved[config].Force = 0
    MPPaladinMeleeHealSaved[config].Overflow = 0

    -- 治疗石、糖水茶
    MPPaladinMeleeHealSaved[config].HealthStone = 1
    MPPaladinMeleeHealSaved[config].HealthStone_Value = 30
    MPPaladinMeleeHealSaved[config].HerbalTea = 1
    MPPaladinMeleeHealSaved[config].HerbalTea_Value = 20
    MPPaladinMeleeHealSaved[config].HerbalTeaMana = 0
    MPPaladinMeleeHealSaved[config].HerbalTeaMana_Value = 20

    MPPaladinMeleeHealSaved[config].Protection = 0
    MPPaladinMeleeHealSaved[config].Protection_Value = 10
    MPPaladinMeleeHealSaved[config].DivineShield = 0
    MPPaladinMeleeHealSaved[config].DivineShield_Value = 10

    -- SuperWoW,UnitXP
    MPPaladinMeleeHealSaved[config].SuperWoW = 1
    MPPaladinMeleeHealSaved[config].UnitXP = 1

    MPPaladinMeleeHealSaved[config].HolyLight_Value = 99
    MPPaladinMeleeHealSaved[config].FlashLight_Value = 99
    MPPaladinMeleeHealSaved[config].HolyShock_Value = 99
    MPPaladinMeleeHealSaved[config].LayHands_Value = 10

    -- 通用
    MPPaladinMeleeHealSaved[config].Power = 0
    MPPaladinMeleeHealSaved[config].Pick = 0

end


local function InitPaladinMeleeHealSettingsPart1()
    checkButton_HolyLight:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].HolyLight))
    checkButton_FlashLight:SetChecked( MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].FlashLight) )
    checkButton_HolyShock:SetChecked( MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].HolyShock) )
    checkButton_LayHands:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].LayHands))
    checkButton_CrusaderStrike:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].CrusaderStrike))
    checkButton_HolyStrike:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].HolyStrike))

    checkButton_TargetFirst:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].TargetFirst))
    checkButton_TargetTarget:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].TargetTarget))
    checkButton_SelfFirst:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].SelfFirst))
    checkButton_ScanTeam:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].ScanTeam))
    checkButton_Tip:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].Tip))

    checkButton_Force:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].Force))
    checkButton_Overflow:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].Overflow))

    checkButton_Power:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].Pick))
end

local function InitPaladinMeleeHealSettingsPart2()
    checkButton_HealthStone:SetChecked(MPToBoolean(MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value)
    if MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value)
    if MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinMeleeHealSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_Protection:SetChecked(MPPaladinMeleeHealSaved[ConfigCurrent].Protection)
    slider_Protection:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value)
    if MPPaladinMeleeHealSaved[ConfigCurrent].Protection==1 then
        color_Protection = "|cFFFFD100"
    else
        color_Protection = "|cFF888888"
    end
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].Protection_Value .."%|r")


    checkButton_DivineShield:SetChecked(MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield)
    slider_DivineShield:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value)
    if MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield==1 then
        color_DivineShield = "|cFFFFD100"
    else
        color_DivineShield = "|cFF888888"
    end
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinMeleeHealSaved[ConfigCurrent].DivineShield_Value .."%|r")



    slider_HolyLight_Value:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].HolyLight_Value)
    --slider_FlashLight_Value:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].FlashLight_Value)
    slider_HolyShock_Value:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].HolyShock_Value)
    slider_LayHands_Value:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].LayHands_Value)
    slider_Begin_Value:SetValue(MPPaladinMeleeHealSaved[ConfigCurrent].Begin_Value)
end

function MPInitPaladinMeleeHealSettings()
    if not MPPaladinMeleeHealSaved then
        MPPaladinMeleeHealSaved = {}

        -- 第一套配置
        if not MPPaladinMeleeHealSaved[1] then
            MPPaladinMeleeHealSaved[1] = {}
            MPResetPaladinMeleeHealSettings(1)
        end

        -- 第二套配置
        if not MPPaladinMeleeHealSaved[2] then
            MPPaladinMeleeHealSaved[2] = {}
            MPResetPaladinMeleeHealSettings(2)
        end

        -- 第三套配置
        if not MPPaladinMeleeHealSaved[3] then
            MPPaladinMeleeHealSaved[3] = {}
            MPResetPaladinMeleeHealSettings(3)
        end
    end

    if MPPaladinMeleeHealSaved.Version ~= PaladinMeleeHealSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[近战奶骑宏]当前配置，这是新版插件正常数据更新！|r")
        MPPaladinMeleeHealSaved[1] = {}
        MPPaladinMeleeHealSaved[2] = {}
        MPPaladinMeleeHealSaved[3] = {}
        MPResetPaladinMeleeHealSettings(1)
        MPResetPaladinMeleeHealSettings(2)
        MPResetPaladinMeleeHealSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitPaladinMeleeHealSettingsPart1()
    InitPaladinMeleeHealSettingsPart2()


end

