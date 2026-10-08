-- 定义插件名称
local ADDON_NAME = "Settings-HunterShot"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPHunterShotSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsHunterShot = MPCreateFrame(ADDON_NAME.."Frame", 520, 570, "|cFFABD473设置 - 射击猎|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsHunterShot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsHunterShot, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 雄鹰守护​
local checkButton_Hawk = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "保持 雄鹰守护")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Hawk, GetCurrentSaved, "Hawk")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 强击光环​
local checkButton_Trueshot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "保持 强击光环")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trueshot, GetCurrentSaved, "Trueshot")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 猎人印记
local checkButton_Mark = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "保持 猎人印记")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Mark, GetCurrentSaved, "Mark")
local checkButton_MarkBossOnly = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_MarkBossOnly, GetCurrentSaved, "MarkBossOnly")


-- 创建单选框 - 自动锁敌 近
local checkButton_Target = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击|cFF33BB33最近|r的敌人)")



postion_y = postion_y-30

-- 创建单选框 - 稳固射击
local checkButton_SteadyShot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "开启 稳固射击 (主技能)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SteadyShot, GetCurrentSaved, "SteadyShot")


-- 创建单选框 - 自动锁敌 远
local checkButton_Distant = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击|cFFDDBB33最远|r的敌人)")

-- 设置点击事件 近
checkButton_Target:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].Target = 1
        MPHunterShotSaved[ConfigCurrent].Distant = 0
    else
        MPHunterShotSaved[ConfigCurrent].Target = 0
    end
    checkButton_Target:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Target))
    checkButton_Distant:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Distant))
end)

-- 设置点击事件 远
checkButton_Distant:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].Distant = 1
        MPHunterShotSaved[ConfigCurrent].Target = 0
    else
        MPHunterShotSaved[ConfigCurrent].Distant = 0
    end
    checkButton_Target:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Target))
    checkButton_Distant:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Distant))
end)



postion_y = postion_y-30

-- 创建单选框 - 瞄准射击
local checkButton_AimedShot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "开启 瞄准射击 (主技能)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_AimedShot, GetCurrentSaved, "AimedShot")

-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")


postion_y = postion_y-30

-- 创建单选框 - 多重射击
local checkButton_MultiShot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "开启 多重射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MultiShot, GetCurrentSaved, "MultiShot")


postion_y = postion_y-30

-- 创建单选框 - 奥术射击
local checkButton_ArcaneShot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneShot, GetCurrentSaved, "ArcaneShot")



postion_y = postion_y-30

-- 创建单选框 - ​​毒蛇钉刺
local checkButton_SerpentSting = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "保持 ​​毒蛇钉刺 (钉刺单选)")



-- 创建单选框 - 近身 猛禽一击
local checkButton_RaptorStrike = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "近身 猛禽一击 (UnitXP模组)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RaptorStrike, GetCurrentSaved, "RaptorStrike")




postion_y = postion_y-30

-- 创建单选框 - ​​蝰蛇钉刺
local checkButton_ViperSting = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "保持 ​​蝰蛇钉刺 (钉刺单选)")


-- 创建单选框 - 近身 猫鼬撕咬
local checkButton_MeerkatsBiting = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "近身 猫鼬撕咬 (UnitXP模组)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MeerkatsBiting, GetCurrentSaved, "MeerkatsBiting")




-- 毒蛇钉刺点击事件
checkButton_SerpentSting:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].Serpent = 1
        MPHunterShotSaved[ConfigCurrent].Viper = 0
    else
        MPHunterShotSaved[ConfigCurrent].Serpent = 0
    end
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Viper))

end)
-- 蝰蛇钉刺点击事件
checkButton_ViperSting:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].Viper = 1
        MPHunterShotSaved[ConfigCurrent].Serpent = 0
    else
        MPHunterShotSaved[ConfigCurrent].Viper = 0
    end
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Viper))

end)








-- 高级


postion_y = postion_y+30

-- 添加提示内容区域
local TipText1 = CatUISettingsHunterShot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsHunterShot, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100

-- 急速射击
local checkButton_RapidFire = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButtonSoulspeed", 20, postion_y, "自动 急速射击")
MPBindConfigCheckButton(checkButton_RapidFire, GetCurrentSaved, "RapidFire")
local checkButton_RapidFireBoss = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RapidFireBoss, GetCurrentSaved, "RapidFireBoss")




-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterShotSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterShotSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterShotSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPHunterShotSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterShotSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 预读 瞄准射击
local checkButton_FirstAimedShot = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 瞄准射击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstAimedShot, GetCurrentSaved, "FirstAimedShot")





-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterShotSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterShotSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterShotSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPHunterShotSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterShotSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 创建单选框 - 荷枪实弹
local checkButton_FullyArmed = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "瞄准射击 仅在荷枪实弹触发时")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FullyArmed, GetCurrentSaved, "FullyArmed")




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPHunterShotSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 蝰蛇守护
local checkButton_ViperGuardian = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 20, postion_y, "自动 蝰蛇守护")

local slider_ViperGuardian = MPCreateConfigSlider(ADDON_NAME.."Slider_ViperGuardian", checkButton_ViperGuardian, "RIGHT", checkButton_ViperGuardian, "RIGHT", 260, -2, 150, 16, 100, 3000, 100, 1000)

local color_ViperGuardian = "|cFFFFD100"

-- 值变化时的回调函数
slider_ViperGuardian:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterShotSaved[ConfigCurrent].Viper_Value = arg1
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterShotSaved[ConfigCurrent].Viper_Value .."|r")
end)
-- 设置点击事件
checkButton_ViperGuardian:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterShotSaved[ConfigCurrent].ViperGuardian = 1
        color_ViperGuardian = "|cFFFFD100"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterShotSaved[ConfigCurrent].Viper_Value .."|r")
    else
        MPHunterShotSaved[ConfigCurrent].ViperGuardian = 0
        color_ViperGuardian = "|cFF888888"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterShotSaved[ConfigCurrent].Viper_Value .."|r")
    end
end)



-- 稳固节点
local slider_SteadyShotValue = MPCreateConfigSlider(ADDON_NAME.."SliderSteadyShotValue", CatUISettingsHunterShot, "TOPLEFT", CatUISettingsHunterShot, "TOPLEFT", 20, postion_y+50, 220, 16, 0.8, 3, 0.1, 1.5)

-- 值变化时的回调函数
slider_SteadyShotValue:SetScript("OnValueChanged", function()
    MPHunterShotSaved[ConfigCurrent].SteadyShot_Value = arg1

    _G[slider_SteadyShotValue:GetName().."Text"]:SetText("稳固 >"..string.format("%.1f", arg1).."秒 下一次平射前")
end)



-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsHunterShot, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsHunterShot, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetHunterShotSettings(ConfigCurrent)
    MPInitHunterShotSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsHunterShot, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitHunterShotSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsHunterShot, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsHunterShot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsHunterShot, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFABD473/sjdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local HunterShotSettingsUIVersion = 26

function MPResetHunterShotSettings(config)

    MPHunterShotSaved.Version = HunterShotSettingsUIVersion

    -- 基本配置

    MPHunterShotSaved[config].Hawk = 1
    MPHunterShotSaved[config].Trueshot = 1
    MPHunterShotSaved[config].Mark = 0
    MPHunterShotSaved[config].MarkBossOnly = 0
    MPHunterShotSaved[config].AimedShot = 1
    MPHunterShotSaved[config].MultiShot = 1
    MPHunterShotSaved[config].ArcaneShot = 1
    MPHunterShotSaved[config].SteadyShot = 1
    MPHunterShotSaved[config].Serpent = 1
    MPHunterShotSaved[config].Viper = 0

    MPHunterShotSaved[config].Trinket_Upper = 1
    MPHunterShotSaved[config].TUBoss = 0
    MPHunterShotSaved[config].Trinket_Below = 1
    MPHunterShotSaved[config].TBBoss = 0
    MPHunterShotSaved[config].Target = 0
    MPHunterShotSaved[config].Distant = 0
    MPHunterShotSaved[config].PetAttack = 0

    MPHunterShotSaved[config].RaptorStrike = 1
    MPHunterShotSaved[config].MeerkatsBiting = 1

    -- 高级配置

    -- 治疗石、糖水茶
    MPHunterShotSaved[config].HealthStone = 1
    MPHunterShotSaved[config].HealthStone_Value = 30
    MPHunterShotSaved[config].HerbalTea = 1
    MPHunterShotSaved[config].HerbalTea_Value = 20
    MPHunterShotSaved[config].HerbalTeaMana = 0
    MPHunterShotSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPHunterShotSaved[config].SuperWoW = 1
    MPHunterShotSaved[config].UnitXP = 1

    MPHunterShotSaved[config].RacialTraits = 0
    MPHunterShotSaved[config].RacialTraitsBoss = 1
    MPHunterShotSaved[config].Soulspeed = 0
    MPHunterShotSaved[config].SoulspeedBoss = 1
    MPHunterShotSaved[config].FirstAimedShot = 0
    MPHunterShotSaved[config].ViperGuardian = 0
    MPHunterShotSaved[config].Viper_Value = 1000
    MPHunterShotSaved[config].RapidFire = 0
    MPHunterShotSaved[config].RapidFireBoss = 0
    MPHunterShotSaved[config].FullyArmed = 0

    MPHunterShotSaved[config].SteadyShot_Value = 1.5

    -- 通用
    MPHunterShotSaved[config].Power = 0
    MPHunterShotSaved[config].Pick = 0

end


local function MPInitHunterShotSettingsPart1()

    checkButton_Hawk:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Hawk))
    checkButton_Trueshot:SetChecked( MPToBoolean(MPHunterShotSaved[ConfigCurrent].Trueshot) )
    checkButton_Mark:SetChecked( MPToBoolean(MPHunterShotSaved[ConfigCurrent].Mark) )
    checkButton_MarkBossOnly:SetChecked( MPToBoolean(MPHunterShotSaved[ConfigCurrent].MarkBossOnly) )
    checkButton_AimedShot:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].AimedShot))
    checkButton_MultiShot:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].MultiShot))
    checkButton_ArcaneShot:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].ArcaneShot))
    checkButton_SteadyShot:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].SteadyShot))
    checkButton_SerpentSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Serpent))
    checkButton_ViperSting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Viper))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Target))
    checkButton_Distant:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Distant))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].PetAttack))

    checkButton_RaptorStrike:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].RaptorStrike))
    checkButton_MeerkatsBiting:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].MeerkatsBiting))

    checkButton_FirstAimedShot:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].FirstAimedShot))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_RapidFire:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].RapidFire))
    checkButton_RapidFireBoss:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].RapidFireBoss))
    checkButton_FullyArmed:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].FullyArmed))

    checkButton_Power:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].Pick))
end

function MPInitHunterShotSettings()
    if not MPHunterShotSaved then
        MPHunterShotSaved = {}

        -- 第一套配置
        if not MPHunterShotSaved[1] then
            MPHunterShotSaved[1] = {}
            MPResetHunterShotSettings(1)
        end

        -- 第二套配置
        if not MPHunterShotSaved[2] then
            MPHunterShotSaved[2] = {}
            MPResetHunterShotSettings(2)
        end

        -- 第三套配置
        if not MPHunterShotSaved[3] then
            MPHunterShotSaved[3] = {}
            MPResetHunterShotSettings(3)
        end
    end

    if MPHunterShotSaved.Version ~= HunterShotSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[射击猎宏]当前配置，这是新版插件正常数据更新！|r")
        MPHunterShotSaved[1] = {}
        MPHunterShotSaved[2] = {}
        MPHunterShotSaved[3] = {}
        MPResetHunterShotSettings(1)
        MPResetHunterShotSettings(2)
        MPResetHunterShotSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitHunterShotSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPHunterShotSaved[ConfigCurrent].HealthStone_Value)
    if MPHunterShotSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterShotSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPHunterShotSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPHunterShotSaved[ConfigCurrent].HerbalTea_Value)
    if MPHunterShotSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterShotSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPHunterShotSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPHunterShotSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")


    slider_SteadyShotValue:SetValue(MPHunterShotSaved[ConfigCurrent].SteadyShot_Value)
    _G[slider_SteadyShotValue:GetName().."Text"]:SetText("稳固射击 射击前 >"..string.format("%.1f", MPHunterShotSaved[ConfigCurrent].SteadyShot_Value).." 秒")

        --[[
    checkButton_JewelMana:SetChecked(MPHunterShotSaved[ConfigCurrent].JewelMana)
    slider_JewelMana:SetValue(MPHunterShotSaved[ConfigCurrent].JewelMana_Value)
    if MPHunterShotSaved[ConfigCurrent].JewelMana==1 then
        color_JewelMana = "|cFFFFD100"
    else
        color_JewelMana = "|cFF888888"
    end
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].JewelMana_Value .."%|r")


    checkButton_ArcanePowerSafe:SetChecked(MPHunterShotSaved[ConfigCurrent].ArcanePowerSafe)
    slider_ArcanePowerSafe:SetValue(MPHunterShotSaved[ConfigCurrent].ArcanePowerSafe_Value)
    if MPHunterShotSaved[ConfigCurrent].ArcanePowerSafe==1 then
        color_ArcanePowerSafe = "|cFFFFD100"
    else
        color_ArcanePowerSafe = "|cFF888888"
    end
    _G[slider_ArcanePowerSafe:GetName().."Text"]:SetText(color_ArcanePowerSafe.."蓝量: ".. MPHunterShotSaved[ConfigCurrent].ArcanePowerSafe_Value .."%|r")
    ]]

    checkButton_ViperGuardian:SetChecked(MPToBoolean(MPHunterShotSaved[ConfigCurrent].ViperGuardian))
    slider_ViperGuardian:SetValue(MPHunterShotSaved[ConfigCurrent].Viper_Value)
    if MPHunterShotSaved[ConfigCurrent].ViperGuardian==1 then
        color_ViperGuardian = "|cFFFFD100"
    else
        color_ViperGuardian = "|cFF888888"
    end
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterShotSaved[ConfigCurrent].Viper_Value .."|r")


end

