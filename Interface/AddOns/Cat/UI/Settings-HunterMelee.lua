-- 定义插件名称
local ADDON_NAME = "Settings-HunterMelee"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPHunterMeleeSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsHunterMelee = MPCreateFrame(ADDON_NAME.."Frame", 520, 510, "|cFFABD473设置 - 生存猎|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsHunterMelee:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsHunterMelee, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 孤狼守护​
local checkButton_LoneWolf = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "保持 孤狼守护")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_LoneWolf, GetCurrentSaved, "LoneWolf")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 强击光环
local checkButton_Trueshot = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "保持 强击光环")
MPBindConfigCheckButton(checkButton_Trueshot, GetCurrentSaved, "Trueshot")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 猛禽一击​
local checkButton_RaptorStrike = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "开启 猛禽一击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RaptorStrike, GetCurrentSaved, "RaptorStrike")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 猫鼬撕咬
local checkButton_MeerkatsBiting = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "开启 猫鼬撕咬")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MeerkatsBiting, GetCurrentSaved, "MeerkatsBiting")



-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")



postion_y = postion_y-30

-- 创建单选框 - 切碎
local checkButton_Rake = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "开启 切碎 (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Rake, GetCurrentSaved, "Rake")



-- 创建单选框 - Trap
local checkButton_Trap = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "开启陷阱")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trap, GetCurrentSaved, "Trap")




postion_y = postion_y-30

-- 创建单选框 - 割伤
local checkButton_Gore = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "开启 割伤 (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Gore, GetCurrentSaved, "Gore")



-- 创建单选框 - ​​爆炸陷阱
local checkButton_ExplosiveTrap = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 370, postion_y, "爆炸陷阱")


-- 创建单选框 - ​​献祭陷阱
local checkButton_ImmolationTrap = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 470, postion_y, "献祭陷阱")


postion_y = postion_y-30

-- 创建单选框 - 摔绊
local checkButton_WingClip = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "开启 摔绊")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WingClip, GetCurrentSaved, "WingClip")


-- 创建单选框 - 自动陷阱
local checkButton_AutoTrap = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 370, postion_y, "自动判断陷阱 (SuperWoW)")

-- 爆炸陷阱点击事件
checkButton_ExplosiveTrap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap = 1
        MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap = 0
        MPHunterMeleeSaved[ConfigCurrent].AutoTrap = 0
    else
        MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap = 0
    end
    checkButton_ExplosiveTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap))
    checkButton_ImmolationTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap))
    checkButton_AutoTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].AutoTrap))
end)
-- 献祭陷阱点击事件
checkButton_ImmolationTrap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap = 1
        MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap = 0
        MPHunterMeleeSaved[ConfigCurrent].AutoTrap = 0
    else
        MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap = 0
    end
    checkButton_ExplosiveTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap))
    checkButton_ImmolationTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap))
    checkButton_AutoTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].AutoTrap))
end)
-- 自动陷阱点击事件
checkButton_AutoTrap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].AutoTrap = 1
        MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap = 0
        MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap = 0
    else
        MPHunterMeleeSaved[ConfigCurrent].AutoTrap = 0
    end
    checkButton_ExplosiveTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap))
    checkButton_ImmolationTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap))
    checkButton_AutoTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].AutoTrap))
end)








-- 高级


postion_y = postion_y+20

-- 添加提示内容区域
local TipText1 = CatUISettingsHunterMelee:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsHunterMelee, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-90

-- 急速射击
local checkButton_RapidFire = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButtonSoulspeed", 20, postion_y, "自动 急速射击")
MPBindConfigCheckButton(checkButton_RapidFire, GetCurrentSaved, "RapidFire")
local checkButton_RapidFireBoss = MPCreateCheckButtonSmall(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RapidFireBoss, GetCurrentSaved, "RapidFireBoss")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPHunterMeleeSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40



-- 创建单选框 - 蝰蛇守护
local checkButton_ViperGuardian = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 20, postion_y, "自动 蝰蛇守护")

local slider_ViperGuardian = MPCreateConfigSlider(ADDON_NAME.."Slider_ViperGuardian", checkButton_ViperGuardian, "RIGHT", checkButton_ViperGuardian, "RIGHT", 260, -2, 150, 16, 100, 3000, 100, 1000)

local color_ViperGuardian = "|cFFFFD100"

-- 值变化时的回调函数
slider_ViperGuardian:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPHunterMeleeSaved[ConfigCurrent].Viper_Value = arg1
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterMeleeSaved[ConfigCurrent].Viper_Value .."|r")
end)
-- 设置点击事件
checkButton_ViperGuardian:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].ViperGuardian = 1
        color_ViperGuardian = "|cFFFFD100"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterMeleeSaved[ConfigCurrent].Viper_Value .."|r")
    else
        MPHunterMeleeSaved[ConfigCurrent].ViperGuardian = 0
        color_ViperGuardian = "|cFF888888"
        _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterMeleeSaved[ConfigCurrent].Viper_Value .."|r")
    end
end)






-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPHunterMeleeSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40





-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")



postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsHunterMelee, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsHunterMelee, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetHunterMeleeSettings(ConfigCurrent)
    MPInitHunterMeleeSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsHunterMelee, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitHunterMeleeSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsHunterMelee, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsHunterMelee:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsHunterMelee, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFABD473/hmdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local HunterMeleeSettingsUIVersion = 10

function MPResetHunterMeleeSettings(config)

    MPHunterMeleeSaved.Version = HunterMeleeSettingsUIVersion

    -- 基本配置

    MPHunterMeleeSaved[config].LoneWolf = 1
    MPHunterMeleeSaved[config].Trueshot = 1
    MPHunterMeleeSaved[config].RaptorStrike = 1
    MPHunterMeleeSaved[config].MeerkatsBiting = 1
    MPHunterMeleeSaved[config].Rake = 1
    MPHunterMeleeSaved[config].Gore = 1
    MPHunterMeleeSaved[config].ExplosiveTrap = 0
    MPHunterMeleeSaved[config].ImmolationTrap = 0
    MPHunterMeleeSaved[config].AutoTrap = 1
    MPHunterMeleeSaved[config].Trap = 1
    MPHunterMeleeSaved[config].WingClip = 0

    MPHunterMeleeSaved[config].Trinket_Upper = 1
    MPHunterMeleeSaved[config].TUBoss = 0
    MPHunterMeleeSaved[config].Trinket_Below = 1
    MPHunterMeleeSaved[config].TBBoss = 0
    MPHunterMeleeSaved[config].Target = 0
    MPHunterMeleeSaved[config].PetAttack = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPHunterMeleeSaved[config].HealthStone = 1
    MPHunterMeleeSaved[config].HealthStone_Value = 30
    MPHunterMeleeSaved[config].HerbalTea = 1
    MPHunterMeleeSaved[config].HerbalTea_Value = 20
    MPHunterMeleeSaved[config].HerbalTeaMana = 0
    MPHunterMeleeSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPHunterMeleeSaved[config].SuperWoW = 1
    MPHunterMeleeSaved[config].UnitXP = 1

    MPHunterMeleeSaved[config].RacialTraits = 0
    MPHunterMeleeSaved[config].RacialTraitsBoss = 1
    MPHunterMeleeSaved[config].Soulspeed = 0
    MPHunterMeleeSaved[config].SoulspeedBoss = 1
    MPHunterMeleeSaved[config].RapidFire = 0
    MPHunterMeleeSaved[config].RapidFireBoss = 0

    MPHunterMeleeSaved[config].ViperGuardian = 0
    MPHunterMeleeSaved[config].Viper_Value = 1000

    -- 通用
    MPHunterMeleeSaved[config].Power = 0
    MPHunterMeleeSaved[config].Pick = 0

end

local function MPInitHunterMeleeSettingsPart1()

    checkButton_LoneWolf:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].LoneWolf))
    checkButton_Trueshot:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Trueshot))
    checkButton_RaptorStrike:SetChecked( MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].RaptorStrike) )
    checkButton_MeerkatsBiting:SetChecked( MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].MeerkatsBiting) )
    checkButton_Rake:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Rake))
    checkButton_Gore:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Gore))
    checkButton_ExplosiveTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ExplosiveTrap))
    checkButton_ImmolationTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ImmolationTrap))
    checkButton_AutoTrap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].AutoTrap))
    checkButton_Trap:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Trap))
    checkButton_WingClip:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].WingClip))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Target))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].PetAttack))

end


function MPInitHunterMeleeSettings()
    if not MPHunterMeleeSaved then
        MPHunterMeleeSaved = {}

        -- 第一套配置
        if not MPHunterMeleeSaved[1] then
            MPHunterMeleeSaved[1] = {}
            MPResetHunterMeleeSettings(1)
        end

        -- 第二套配置
        if not MPHunterMeleeSaved[2] then
            MPHunterMeleeSaved[2] = {}
            MPResetHunterMeleeSettings(2)
        end

        -- 第三套配置
        if not MPHunterMeleeSaved[3] then
            MPHunterMeleeSaved[3] = {}
            MPResetHunterMeleeSettings(3)
        end
    end

    if MPHunterMeleeSaved.Version ~= HunterMeleeSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[生存猎宏]当前配置，这是新版插件正常数据更新！|r")
        MPHunterMeleeSaved[1] = {}
        MPHunterMeleeSaved[2] = {}
        MPHunterMeleeSaved[3] = {}
        MPResetHunterMeleeSettings(1)
        MPResetHunterMeleeSettings(2)
        MPResetHunterMeleeSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitHunterMeleeSettingsPart1()


    checkButton_RacialTraits:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_RapidFire:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].RapidFire))
    checkButton_RapidFireBoss:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].RapidFireBoss))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value)
    if MPHunterMeleeSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPHunterMeleeSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value)
    if MPHunterMeleeSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPHunterMeleeSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")


    checkButton_Power:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].Pick))

    checkButton_ViperGuardian:SetChecked(MPToBoolean(MPHunterMeleeSaved[ConfigCurrent].ViperGuardian))
    slider_ViperGuardian:SetValue(MPHunterMeleeSaved[ConfigCurrent].Viper_Value)
    if MPHunterMeleeSaved[ConfigCurrent].ViperGuardian==1 then
        color_ViperGuardian = "|cFFFFD100"
    else
        color_ViperGuardian = "|cFF888888"
    end
    _G[slider_ViperGuardian:GetName().."Text"]:SetText(color_ViperGuardian.."蓝量 < ".. MPHunterMeleeSaved[ConfigCurrent].Viper_Value .."|r")

end

