-- 定义插件名称
local ADDON_NAME = "Settings-HunterBeast"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPHunterBeastSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsHunterBeast = MPCreateFrame(ADDON_NAME.."Frame", 520, 590, "|cFFABD473设置 - 兽王猎|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsHunterBeast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsHunterBeast, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 雄鹰守护​
local checkButton_Hawk = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "保持 雄鹰守护")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Hawk, GetCurrentSaved, "Hawk")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 强击光环
local checkButton_Trueshot = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "保持 强击光环")
MPBindConfigCheckButton(checkButton_Trueshot, GetCurrentSaved, "Trueshot")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 猎人印记
local checkButton_Mark = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "保持 猎人印记")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Mark, GetCurrentSaved, "Mark")
local checkButton_MarkBossOnly = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_MarkBossOnly, GetCurrentSaved, "MarkBossOnly")

-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")




postion_y = postion_y-30

-- 创建单选框 - 杀戮命令
local checkButton_KillCommand = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "开启 杀戮命令")
MPBindConfigCheckButton(checkButton_KillCommand, GetCurrentSaved, "KillCommand")



postion_y = postion_y-30

-- 创建单选框 - 稳固射击
local checkButton_SteadyShot = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "开启 稳固射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SteadyShot, GetCurrentSaved, "SteadyShot")

postion_y = postion_y-30

-- 创建单选框 - 瞄准射击
local checkButton_AimedShot = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "开启 瞄准射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_AimedShot, GetCurrentSaved, "AimedShot")

-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")


postion_y = postion_y-30

-- 创建单选框 - 多重射击
local checkButton_MultiShot = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "开启 多重射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MultiShot, GetCurrentSaved, "MultiShot")



postion_y = postion_y-30

-- 创建单选框 - 奥术射击
local checkButton_ArcaneShot = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneShot, GetCurrentSaved, "ArcaneShot")



postion_y = postion_y-30

-- 创建单选框 - ​​毒蛇钉刺
local checkButton_SerpentSting = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "保持 ​​毒蛇钉刺 (钉刺单选)")



-- 创建单选框 - 近身 猛禽一击
local checkButton_RaptorStrike = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "近身 猛禽一击 (UnitXP模组)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RaptorStrike, GetCurrentSaved, "RaptorStrike")




postion_y = postion_y-30

-- 创建单选框 - ​​蝰蛇钉刺
local checkButton_ViperSting = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "保持 ​​蝰蛇钉刺 (钉刺单选)")


-- 创建单选框 - 近身 猫鼬撕咬
local checkButton_MeerkatsBiting = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "近身 猫鼬撕咬 (UnitXP模组)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MeerkatsBiting, GetCurrentSaved, "MeerkatsBiting")




-- 毒蛇钉刺点击事件
checkButton_SerpentSting:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].Serpent = 1
        MPHunterBeastSaved[ConfigCurrent].Viper = 0
    else
        MPHunterBeastSaved[ConfigCurrent].Serpent = 0
    end
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Viper))

end)
-- 蝰蛇钉刺点击事件
checkButton_ViperSting:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].Viper = 1
        MPHunterBeastSaved[ConfigCurrent].Serpent = 0
    else
        MPHunterBeastSaved[ConfigCurrent].Viper = 0
    end
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Viper))

end)










-- 高级


postion_y = postion_y+30

-- 添加提示内容区域
local TipText1 = CatUISettingsHunterBeast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsHunterBeast, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-110


-- 急速射击
local checkButton_RapidFire = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "自动 急速射击")
MPBindConfigCheckButton(checkButton_RapidFire, GetCurrentSaved, "RapidFire")
local checkButton_RapidFireBoss = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RapidFireBoss, GetCurrentSaved, "RapidFireBoss")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterBeastSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPHunterBeastSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40



-- 创建单选框 - 蝰蛇守护
local checkButton_ViperGuardian = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 20, postion_y, "自动 蝰蛇守护")

local slider_ViperGuardian = MPCreateConfigSlider(ADDON_NAME.."Slider_ViperGuardian", checkButton_ViperGuardian, "RIGHT", checkButton_ViperGuardian, "RIGHT", 260, -2, 150, 16, 100, 3000, 100, 1000)

local color_ViperGuardian = "|cFFFFD100"

-- 值变化时的回调函数
slider_ViperGuardian:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterBeastSaved[ConfigCurrent].Viper_Value = arg1
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterBeastSaved[ConfigCurrent].Viper_Value .."|r")
end)
-- 设置点击事件
checkButton_ViperGuardian:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].ViperGuardian = 1
        color_ViperGuardian = "|cFFFFD100"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterBeastSaved[ConfigCurrent].Viper_Value .."|r")
    else
        MPHunterBeastSaved[ConfigCurrent].ViperGuardian = 0
        color_ViperGuardian = "|cFF888888"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterBeastSaved[ConfigCurrent].Viper_Value .."|r")
    end
end)





-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPHunterBeastSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsHunterBeast, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsHunterBeast, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetHunterBeastSettings(ConfigCurrent)
    MPInitHunterBeastSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsHunterBeast, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitHunterBeastSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsHunterBeast, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsHunterBeast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsHunterBeast, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFABD473/hbdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local HunterBeastSettingsUIVersion = 13

function MPResetHunterBeastSettings(config)

    MPHunterBeastSaved.Version = HunterBeastSettingsUIVersion

    -- 基本配置

    MPHunterBeastSaved[config].Hawk = 1
    MPHunterBeastSaved[config].Trueshot = 1
    MPHunterBeastSaved[config].Mark = 0
    MPHunterBeastSaved[config].MarkBossOnly = 0
    MPHunterBeastSaved[config].KillCommand = 1
    MPHunterBeastSaved[config].AimedShot = 1
    MPHunterBeastSaved[config].BaitShot = 1
    MPHunterBeastSaved[config].SteadyShot = 1
    MPHunterBeastSaved[config].MultiShot = 1
    MPHunterBeastSaved[config].ArcaneShot = 1
    MPHunterBeastSaved[config].Serpent = 1
    MPHunterBeastSaved[config].Viper = 0

    MPHunterBeastSaved[config].Trinket_Upper = 1
    MPHunterBeastSaved[config].TUBoss = 0
    MPHunterBeastSaved[config].Trinket_Below = 1
    MPHunterBeastSaved[config].TBBoss = 0
    MPHunterBeastSaved[config].Target = 0
    MPHunterBeastSaved[config].PetAttack = 0

    MPHunterBeastSaved[config].RaptorStrike = 1
    MPHunterBeastSaved[config].MeerkatsBiting = 1

    -- 高级配置

    -- 治疗石、糖水茶
    MPHunterBeastSaved[config].HealthStone = 1
    MPHunterBeastSaved[config].HealthStone_Value = 30
    MPHunterBeastSaved[config].HerbalTea = 1
    MPHunterBeastSaved[config].HerbalTea_Value = 20
    MPHunterBeastSaved[config].HerbalTeaMana = 0
    MPHunterBeastSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPHunterBeastSaved[config].SuperWoW = 1
    MPHunterBeastSaved[config].UnitXP = 1

    MPHunterBeastSaved[config].RacialTraits = 0
    MPHunterBeastSaved[config].RacialTraitsBoss = 1
    MPHunterBeastSaved[config].Soulspeed = 0
    MPHunterBeastSaved[config].SoulspeedBoss = 1
    MPHunterBeastSaved[config].RapidFire = 0
    MPHunterBeastSaved[config].RapidFireBoss = 0

    MPHunterBeastSaved[config].ViperGuardian = 0
    MPHunterBeastSaved[config].Viper_Value = 1000

    MPHunterBeastSaved[config].SteadyShot_Value = 1.9

    -- 通用
    MPHunterBeastSaved[config].Power = 0
    MPHunterBeastSaved[config].Pick = 0

end


local function MPInitHunterBeastSettingsPart1()

    checkButton_Hawk:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Hawk))
    checkButton_Mark:SetChecked( MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Mark) )
    checkButton_MarkBossOnly:SetChecked( MPToBoolean(MPHunterBeastSaved[ConfigCurrent].MarkBossOnly) )
    checkButton_KillCommand:SetChecked( MPToBoolean(MPHunterBeastSaved[ConfigCurrent].KillCommand) )
    checkButton_SteadyShot:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].SteadyShot))
    checkButton_Trueshot:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Trueshot))
    checkButton_AimedShot:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].AimedShot))
    checkButton_MultiShot:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].MultiShot))
    checkButton_ArcaneShot:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].ArcaneShot))
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Viper))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Target))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].PetAttack))

    checkButton_RaptorStrike:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].RaptorStrike))
    checkButton_MeerkatsBiting:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].MeerkatsBiting))

    checkButton_RacialTraits:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_RapidFire:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].RapidFire))
    checkButton_RapidFireBoss:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].RapidFireBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].Pick))
end

function MPInitHunterBeastSettings()
    if not MPHunterBeastSaved then
        MPHunterBeastSaved = {}

        -- 第一套配置
        if not MPHunterBeastSaved[1] then
            MPHunterBeastSaved[1] = {}
            MPResetHunterBeastSettings(1)
        end

        -- 第二套配置
        if not MPHunterBeastSaved[2] then
            MPHunterBeastSaved[2] = {}
            MPResetHunterBeastSettings(2)
        end

        -- 第三套配置
        if not MPHunterBeastSaved[3] then
            MPHunterBeastSaved[3] = {}
            MPResetHunterBeastSettings(3)
        end
    end

    if MPHunterBeastSaved.Version ~= HunterBeastSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[兽王猎宏]当前配置，这是新版插件正常数据更新！|r")
        MPHunterBeastSaved[1] = {}
        MPHunterBeastSaved[2] = {}
        MPHunterBeastSaved[3] = {}
        MPResetHunterBeastSettings(1)
        MPResetHunterBeastSettings(2)
        MPResetHunterBeastSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitHunterBeastSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPHunterBeastSaved[ConfigCurrent].HealthStone_Value)
    if MPHunterBeastSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPHunterBeastSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value)
    if MPHunterBeastSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterBeastSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")


    checkButton_ViperGuardian:SetChecked(MPToBoolean(MPHunterBeastSaved[ConfigCurrent].ViperGuardian))
    slider_ViperGuardian:SetValue(MPHunterBeastSaved[ConfigCurrent].Viper_Value)
    if MPHunterBeastSaved[ConfigCurrent].ViperGuardian==1 then
        color_ViperGuardian = "|cFFFFD100"
    else
        color_ViperGuardian = "|cFF888888"
    end
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterBeastSaved[ConfigCurrent].Viper_Value .."|r")

end

