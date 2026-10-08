
-- 定义插件名称
local ADDON_NAME = "Settings-MageArcane"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPMageArcaneSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsMageArcane = MPCreateFrame(ADDON_NAME.."Frame", 520, 500, "|cFF69CCF0设置 - 奥法|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsMageArcane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsMageArcane, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 魔甲术
local checkButton_MageArmor = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "保持 魔甲术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MageArmor, GetCurrentSaved, "MageArmor")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 奥术溃裂​
local checkButton_ArcaneExplosion = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术溃裂​​ (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneExplosion, GetCurrentSaved, "ArcaneExplosion")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 奥术飞弹
local checkButton_ArcaneMissiles = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术飞弹")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneMissiles, GetCurrentSaved, "ArcaneMissiles")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 奥术涌动​
local checkButton_ArcaneSurge = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术涌动")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneSurge, GetCurrentSaved, "ArcaneSurge")



postion_y = postion_y-30

-- 创建单选框 - 火焰冲击
local checkButton_FireBlast = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "开启 火焰冲击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FireBlast, GetCurrentSaved, "FireBlast")







-- 高级


postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsMageArcane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsMageArcane, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-80


-- 创建单选框 - 奥术强化保护
local checkButton_ArcanePowerSafe = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术强化保护")

local slider_ArcanePowerSafe = MPCreateConfigSlider(ADDON_NAME.."Slider_ArcanePowerSafe", checkButton_ArcanePowerSafe, "RIGHT", checkButton_ArcanePowerSafe, "RIGHT", 260, -2, 120, 16, 10, 30, 1, 30)

local color_ArcanePowerSafe = "|cFFFFD100"

-- 值变化时的回调函数
slider_ArcanePowerSafe:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value = arg1
    _G[slider_ArcanePowerSafe:GetName().."Text"]:SetText(color_ArcanePowerSafe.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value .."%|r")
end)

-- 设置点击事件
checkButton_ArcanePowerSafe:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe = 1
        color_ArcanePowerSafe = "|cFFFFD100"
        _G[slider_ArcanePowerSafe:GetName().."Text"]:SetText(color_ArcanePowerSafe.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value .."%|r")
    else
        MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe = 0
        color_ArcanePowerSafe = "|cFF888888"
        _G[slider_ArcanePowerSafe:GetName().."Text"]:SetText(color_ArcanePowerSafe.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value .."%|r")
    end
end)



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPMageArcaneSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageArcaneSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPMageArcaneSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 奥术强化时不涌动
local checkButton_ArcanePowerNoSurge = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "奥术强化时 不打 奥术涌动")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcanePowerNoSurge, GetCurrentSaved, "ArcanePowerNoSurge")


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageArcaneSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPMageArcaneSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 奥术溃裂 时不涌动
local checkButton_ArcaneExplosionNoSurge = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "奥术溃裂时 不打 奥术涌动")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneExplosionNoSurge, GetCurrentSaved, "ArcaneExplosionNoSurge")



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40


-- 创建单选框 - 断条补溃裂
local checkButton_IntExplosion = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "断条补 奥术溃裂")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_IntExplosion, GetCurrentSaved, "IntExplosion")



-- 创建单选框 - 宝石 蓝量
local checkButton_JewelMana = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动 法力宝石")

local slider_JewelMana = MPCreateConfigSlider(ADDON_NAME.."Slider_JewelMana", checkButton_JewelMana, "RIGHT", checkButton_JewelMana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 20)

local color_JewelMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_JewelMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageArcaneSaved[ConfigCurrent].JewelMana_Value = arg1
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].JewelMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_JewelMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageArcaneSaved[ConfigCurrent].JewelMana = 1
        color_JewelMana = "|cFFFFD100"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].JewelMana_Value .."%|r")
    else
        MPMageArcaneSaved[ConfigCurrent].JewelMana = 0
        color_JewelMana = "|cFF888888"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].JewelMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 保护点燃
local checkButton_IgniteProtect = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 20, postion_y, "保护 优质点燃 (团队中)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_IgniteProtect, GetCurrentSaved, "IgniteProtect")


-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40


-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsMageArcane, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsMageArcane, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetMageArcaneSettings(ConfigCurrent)
    MPInitMageArcaneSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsMageArcane, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitMageArcaneSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsMageArcane, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsMageArcane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsMageArcane, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF69CCF0/madps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local MageArcaneSettingsUIVersion = 11

function MPResetMageArcaneSettings(config)

    MPMageArcaneSaved.Version = MageArcaneSettingsUIVersion

    -- 基本配置

    MPMageArcaneSaved[config].MageArmor = 1
    MPMageArcaneSaved[config].ArcaneExplosion = 1
    MPMageArcaneSaved[config].ArcaneMissiles = 1
    MPMageArcaneSaved[config].ArcaneSurge = 1
    MPMageArcaneSaved[config].FireBlast = 0

    MPMageArcaneSaved[config].Trinket_Upper = 1
    MPMageArcaneSaved[config].TUBoss = 0
    MPMageArcaneSaved[config].Trinket_Below = 1
    MPMageArcaneSaved[config].TBBoss = 0
    MPMageArcaneSaved[config].Target = 0



    -- 高级配置

    -- 治疗石、糖水茶
    MPMageArcaneSaved[config].HealthStone = 1
    MPMageArcaneSaved[config].HealthStone_Value = 30
    MPMageArcaneSaved[config].HerbalTea = 1
    MPMageArcaneSaved[config].HerbalTea_Value = 20
    MPMageArcaneSaved[config].HerbalTeaMana = 0
    MPMageArcaneSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPMageArcaneSaved[config].SuperWoW = 1
    MPMageArcaneSaved[config].UnitXP = 1

    MPMageArcaneSaved[config].ArcanePowerSafe = 0
    MPMageArcaneSaved[config].ArcanePowerSafe_Value = 30
    MPMageArcaneSaved[config].ArcanePowerNoSurge = 0
    MPMageArcaneSaved[config].ArcaneExplosionNoSurge = 0
    MPMageArcaneSaved[config].IntExplosion = 0

    MPMageArcaneSaved[config].RacialTraits = 0
    MPMageArcaneSaved[config].RacialTraitsBoss = 1
    MPMageArcaneSaved[config].Soulspeed = 0
    MPMageArcaneSaved[config].SoulspeedBoss = 1
    MPMageArcaneSaved[config].IgniteProtect = 1

    MPMageArcaneSaved[config].JewelMana_Value = 35
    MPMageArcaneSaved[config].JewelMana = 0

    -- 通用
    MPMageArcaneSaved[config].Power = 0
    MPMageArcaneSaved[config].Pick = 0

end


local function MPInitMageArcaneSettingsPart1()

    checkButton_MageArmor:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].MageArmor))
    checkButton_ArcaneExplosion:SetChecked( MPToBoolean(MPMageArcaneSaved[ConfigCurrent].ArcaneExplosion) )
    checkButton_ArcaneMissiles:SetChecked( MPToBoolean(MPMageArcaneSaved[ConfigCurrent].ArcaneMissiles) )
    checkButton_ArcaneSurge:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].ArcaneSurge))
    checkButton_FireBlast:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].FireBlast))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Target))

    checkButton_IntExplosion:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].IntExplosion))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_IgniteProtect:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].IgniteProtect))

    checkButton_ArcanePowerNoSurge:SetChecked(MPMageArcaneSaved[ConfigCurrent].ArcanePowerNoSurge)
    checkButton_ArcaneExplosionNoSurge:SetChecked(MPMageArcaneSaved[ConfigCurrent].ArcaneExplosionNoSurge)

    checkButton_Power:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].Pick))
end

function MPInitMageArcaneSettings()
    if not MPMageArcaneSaved then
        MPMageArcaneSaved = {}

        -- 第一套配置
        if not MPMageArcaneSaved[1] then
            MPMageArcaneSaved[1] = {}
            MPResetMageArcaneSettings(1)
        end

        -- 第二套配置
        if not MPMageArcaneSaved[2] then
            MPMageArcaneSaved[2] = {}
            MPResetMageArcaneSettings(2)
        end

        -- 第三套配置
        if not MPMageArcaneSaved[3] then
            MPMageArcaneSaved[3] = {}
            MPResetMageArcaneSettings(3)
        end
    end

    if MPMageArcaneSaved.Version ~= MageArcaneSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[奥法宏]当前配置，这是新版插件正常数据更新！|r")
        MPMageArcaneSaved[1] = {}
        MPMageArcaneSaved[2] = {}
        MPMageArcaneSaved[3] = {}
        MPResetMageArcaneSettings(1)
        MPResetMageArcaneSettings(2)
        MPResetMageArcaneSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitMageArcaneSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPMageArcaneSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPMageArcaneSaved[ConfigCurrent].HealthStone_Value)
    if MPMageArcaneSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPMageArcaneSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value)
    if MPMageArcaneSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_JewelMana:SetChecked(MPMageArcaneSaved[ConfigCurrent].JewelMana)
    slider_JewelMana:SetValue(MPMageArcaneSaved[ConfigCurrent].JewelMana_Value)
    if MPMageArcaneSaved[ConfigCurrent].JewelMana==1 then
        color_JewelMana = "|cFFFFD100"
    else
        color_JewelMana = "|cFF888888"
    end
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].JewelMana_Value .."%|r")

    checkButton_ArcanePowerSafe:SetChecked(MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe)
    slider_ArcanePowerSafe:SetValue(MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value)
    if MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe==1 then
        color_ArcanePowerSafe = "|cFFFFD100"
    else
        color_ArcanePowerSafe = "|cFF888888"
    end
    _G[slider_ArcanePowerSafe:GetName().."Text"]:SetText(color_ArcanePowerSafe.."蓝量: ".. MPMageArcaneSaved[ConfigCurrent].ArcanePowerSafe_Value .."%|r")


end

