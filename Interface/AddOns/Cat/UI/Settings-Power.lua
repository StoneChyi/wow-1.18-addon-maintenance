-- 定义插件名称
local ADDON_NAME = "Settings-Power"


-- 创建主框架
CatUISettingsPower = MPCreateFrame(ADDON_NAME.."Frame", 520, 520, "|cFFDD4080"..MPLanguage.UI_Set_PowerTitle.."|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPower:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPower, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)




local postion_y = postion_y-40

-- 创建单选框 - 使用
local checkButton_Use = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_EnablePowerPotionShort)
MPBindConfigCheckButton(checkButton_Use, function() return MPPowerSaved end, "Use")

-- 创建单选框 - 战斗中
local checkButton_Combat = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_CombatOnly)
MPBindConfigCheckButton(checkButton_Combat, function() return MPPowerSaved end, "Combat")


postion_y = postion_y-20

-- 添加提示内容区域
local noCDTipText = CatUISettingsPower:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
noCDTipText:SetPoint("TOPLEFT", CatUISettingsPower, "TOPLEFT", 20, postion_y)
noCDTipText:SetWidth(250)
noCDTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
noCDTipText:SetTextColor(1, 0.8, 0)
noCDTipText:SetJustifyH("LEFT")
noCDTipText:SetText(MPLanguage.UI_Set_ProtectionConfig)


postion_y = postion_y-55


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoHerbalTeaPower)

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_HerbalTea:SetScript("OnValueChanged", function()
    MPPowerSaved.HerbalTea_Value = arg1
    if MPPowerSaved.HerbalTea==1 then
        _G[slider_HerbalTea:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HerbalTea_Value .."%|r")
    else
        _G[slider_HerbalTea:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HerbalTea_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.HerbalTea = 1
        _G[slider_HerbalTea:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HerbalTea_Value .."%|r")
    else
        MPPowerSaved.HerbalTea = 0
        _G[slider_HerbalTea:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HerbalTea_Value .."%|r")
    end
end)


-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoHerbalTeaPower)

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    MPPowerSaved.HerbalTeaMana_Value = arg1
    if MPPowerSaved.HerbalTeaMana==1 then
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.HerbalTeaMana_Value .."%|r")
    else
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.HerbalTeaMana_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.HerbalTeaMana = 1
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.HerbalTeaMana_Value .."%|r")
    else
        MPPowerSaved.HerbalTeaMana = 0
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 活力
local checkButton_Rejuven = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoRejuven)

local slider_Rejuven = MPCreateConfigSlider(ADDON_NAME.."Slider_Rejuven", checkButton_Rejuven, "RIGHT", checkButton_Rejuven, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_Rejuven:SetScript("OnValueChanged", function()
    MPPowerSaved.Rejuven_Value = arg1
    if MPPowerSaved.Rejuven==1 then
        _G[slider_Rejuven:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Rejuven_Value .."%|r")
    else
        _G[slider_Rejuven:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Rejuven_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_Rejuven:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.Rejuven = 1
        _G[slider_Rejuven:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Rejuven_Value .."%|r")
    else
        MPPowerSaved.Rejuven = 0
        _G[slider_Rejuven:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Rejuven_Value .."%|r")
    end
end)


-- 创建单选框 - 活力
local checkButton_RejuvenMana = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoRejuven)

local slider_RejuvenMana = MPCreateConfigSlider(ADDON_NAME.."Slider_RejuvenMana", checkButton_RejuvenMana, "RIGHT", checkButton_RejuvenMana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_RejuvenMana:SetScript("OnValueChanged", function()
    MPPowerSaved.RejuvenMana_Value = arg1
    if MPPowerSaved.RejuvenMana==1 then
        _G[slider_RejuvenMana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.RejuvenMana_Value .."%|r")
    else
        _G[slider_RejuvenMana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.RejuvenMana_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_RejuvenMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.RejuvenMana = 1
        _G[slider_RejuvenMana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.RejuvenMana_Value .."%|r")
    else
        MPPowerSaved.RejuvenMana = 0
        _G[slider_RejuvenMana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.RejuvenMana_Value .."%|r")
    end
end)






postion_y = postion_y-40


-- 创建单选框 - 大红
local checkButton_Healing = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoHealing)

local slider_Healing = MPCreateConfigSlider(ADDON_NAME.."Slider_Heal", checkButton_Healing, "RIGHT", checkButton_Healing, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_Healing:SetScript("OnValueChanged", function()
    MPPowerSaved.Healing_Value = arg1
    if MPPowerSaved.Healing==1 then
        _G[slider_Healing:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Healing_Value .."%|r")
    else
        _G[slider_Healing:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Healing_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_Healing:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.Healing = 1
        _G[slider_Healing:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Healing_Value .."%|r")
    else
        MPPowerSaved.Healing = 0
        _G[slider_Healing:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Healing_Value .."%|r")
    end
end)


-- 创建单选框 - 法力药水
local checkButton_Mana = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoMana)

local slider_Mana = MPCreateConfigSlider(ADDON_NAME.."Slider_Mana", checkButton_Mana, "RIGHT", checkButton_Mana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_Mana:SetScript("OnValueChanged", function()
    MPPowerSaved.Mana_Value = arg1
    if MPPowerSaved.Mana==1 then
        _G[slider_Mana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.Mana_Value .."%|r")
    else
        _G[slider_Mana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.Mana_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_Mana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.Mana = 1
        _G[slider_Mana:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.Mana_Value .."%|r")
    else
        MPPowerSaved.Mana = 0
        _G[slider_Mana:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_ManaLine.. MPPowerSaved.Mana_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoHealthStonePower)

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_HealthStone:SetScript("OnValueChanged", function()
    MPPowerSaved.HealthStone_Value = arg1
    if MPPowerSaved.HealthStone==1 then
        _G[slider_HealthStone:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HealthStone_Value .."%|r")
    else
        _G[slider_HealthStone:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HealthStone_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.HealthStone = 1
        _G[slider_HealthStone:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HealthStone_Value .."%|r")
    else
        MPPowerSaved.HealthStone = 0
        _G[slider_HealthStone:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.HealthStone_Value .."%|r")
    end
end)


-- 创建单选框 - 鞭根块茎
local checkButton_Carrot = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoCarrotPower)

local slider_Carrot = MPCreateConfigSlider(ADDON_NAME.."Slider_Carrot", checkButton_Carrot, "RIGHT", checkButton_Carrot, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 0)

slider_Carrot:SetScript("OnValueChanged", function()
    MPPowerSaved.Carrot_Value = arg1
    if MPPowerSaved.Carrot==1 then
        _G[slider_Carrot:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Carrot_Value .."%|r")
    else
        _G[slider_Carrot:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Carrot_Value .."%|r")
    end
end)

-- 设置点击事件
checkButton_Carrot:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPowerSaved.Carrot = 1
        _G[slider_Carrot:GetName().."Text"]:SetText("|cFFFFD100"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Carrot_Value .."%|r")
    else
        MPPowerSaved.Carrot = 0
        _G[slider_Carrot:GetName().."Text"]:SetText("|cFF888888"..MPLanguage.UI_Set_HealthLine.. MPPowerSaved.Carrot_Value .."%|r")
    end
end)









postion_y = postion_y-40

-- 创建单选框 - 无敌
local checkButton_Invincible = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoInvincible)
MPBindConfigCheckButton(checkButton_Invincible, function() return MPPowerSaved end, "Invincible")
local checkButton_InvincibleBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 190, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_InvincibleBoss, function() return MPPowerSaved end, "InvincibleBoss")


-- 创建单选框 - 解毒药剂
local checkButton_Detoxify = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoDetoxify)
MPBindConfigCheckButton(checkButton_Detoxify, function() return MPPowerSaved end, "Detoxify")





postion_y = postion_y+25

-- 添加提示内容区域
local attackTipText = CatUISettingsPower:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
attackTipText:SetPoint("TOPLEFT", CatUISettingsPower, "TOPLEFT", 20, postion_y)
attackTipText:SetWidth(250)
attackTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
attackTipText:SetTextColor(1, 0.8, 0)
attackTipText:SetJustifyH("LEFT")
attackTipText:SetText(MPLanguage.UI_Set_OffenseConfig)


postion_y = postion_y-105

-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoTrinketBurst)
MPBindConfigCheckButton(checkButton_Trinket_Upper, function() return MPPowerSaved end, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 190, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, function() return MPPowerSaved end, "TUBoss")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoTrinketBurstLower)
MPBindConfigCheckButton(checkButton_Trinket_Below, function() return MPPowerSaved end, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 510, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, function() return MPPowerSaved end, "TBBoss")


postion_y = postion_y-40

-- 创建单选框 - 强怒
local checkButton_Powerful = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoPowerfulRage)
MPBindConfigCheckButton(checkButton_Powerful, function() return MPPowerSaved end, "Powerful")
local checkButton_PowerfulBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 190, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_PowerfulBoss, function() return MPPowerSaved end, "PowerfulBoss")

-- 创建单选框 - 急速
local checkButton_Swiftness = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoSwiftness)
MPBindConfigCheckButton(checkButton_Swiftness, function() return MPPowerSaved end, "Swiftness")
local checkButton_SwiftnessBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 510, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SwiftnessBoss, function() return MPPowerSaved end, "SwiftnessBoss")


postion_y = postion_y-40

-- 创建单选框 - 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoSoulspeedPower)
MPBindConfigCheckButton(checkButton_Soulspeed, function() return MPPowerSaved end, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 190, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, function() return MPPowerSaved end, "SoulspeedBoss")

-- 创建单选框 - 献祭之油
local checkButton_Sacrificial = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_AutoSacrificialPower)
MPBindConfigCheckButton(checkButton_Sacrificial, function() return MPPowerSaved end, "Sacrificial")



postion_y = postion_y+60

-- 添加提示内容区域
local gongnengTipText = CatUISettingsPower:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
gongnengTipText:SetPoint("TOPLEFT", CatUISettingsPower, "TOPLEFT", 20, postion_y)
gongnengTipText:SetWidth(250)
gongnengTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
gongnengTipText:SetTextColor(1, 0.8, 0)
gongnengTipText:SetJustifyH("LEFT")
gongnengTipText:SetText(MPLanguage.UI_Set_SpecialConfig)


postion_y = postion_y-135

-- 创建单选框 - 屠魔药剂
local checkButton_Demon = MPCreateCheckButton(CatUISettingsPower, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_AutoDemonSlaying)
MPBindConfigCheckButton(checkButton_Demon, function() return MPPowerSaved end, "Demon")
local checkButton_DemonBoss = MPCreateCheckButtonSmall(CatUISettingsPower, ADDON_NAME.."CheckButton", 190, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_DemonBoss, function() return MPPowerSaved end, "DemonBoss")




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPower, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
-- 按钮点击事件
myButton:SetScript("OnClick", function()
    MPResetPowerSettings()
    MPInitPowerSettings()
end)


-- 添加提示内容区域
local TipText = CatUISettingsPower:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPower, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText(MPLanguage.UI_Set_PowerMacroTip)



-- 配置文件版本号
local PowerSettingsUIVersion = 3

function MPResetPowerSettings()

    MPPowerSaved.Version = PowerSettingsUIVersion

    -- 基本配置
    MPPowerSaved.Use = 1
    MPPowerSaved.Combat = 1


    MPPowerSaved.HerbalTea = 1
    MPPowerSaved.HerbalTea_Value = 20
    MPPowerSaved.HerbalTeaMana = 0
    MPPowerSaved.HerbalTeaMana_Value = 20

    MPPowerSaved.HealthStone = 1
    MPPowerSaved.HealthStone_Value = 30
    MPPowerSaved.Carrot = 0
    MPPowerSaved.Carrot_Value = 20

    MPPowerSaved.Healing = 0
    MPPowerSaved.Healing_Value = 20
    MPPowerSaved.Mana = 0
    MPPowerSaved.Mana_Value = 20

    MPPowerSaved.Rejuven = 0
    MPPowerSaved.Rejuven_Value = 20
    MPPowerSaved.RejuvenMana = 0
    MPPowerSaved.RejuvenMana_Value = 20

    MPPowerSaved.Invincible = 0
    MPPowerSaved.InvincibleBoss = 0
    MPPowerSaved.Detoxify = 0

    MPPowerSaved.Trinket_Upper = 0
    MPPowerSaved.TUBoss = 0
    MPPowerSaved.Trinket_Below = 0
    MPPowerSaved.TBBoss = 0

    MPPowerSaved.Powerful = 0
    MPPowerSaved.PowerfulBoss = 1
    MPPowerSaved.Swiftness = 0
    MPPowerSaved.SwiftnessBoss = 1
    MPPowerSaved.Soulspeed = 1
    MPPowerSaved.SoulspeedBoss = 1
    MPPowerSaved.Sacrificial = 0

    MPPowerSaved.Demon = 0
    MPPowerSaved.DemonBoss = 1

end


function MPInitPowerSettingsPart1()
    checkButton_Use:SetChecked(MPToBoolean(MPPowerSaved.Use))
    checkButton_Combat:SetChecked(MPToBoolean(MPPowerSaved.Combat))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPPowerSaved.Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPPowerSaved.TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPPowerSaved.Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPPowerSaved.TBBoss))


    checkButton_HerbalTea:SetChecked(MPToBoolean(MPPowerSaved.HerbalTea))
    slider_HerbalTea:SetValue(MPPowerSaved.HerbalTea_Value)
    checkButton_HerbalTeaMana:SetChecked(MPToBoolean(MPPowerSaved.HerbalTeaMana))
    slider_HerbalTeaMana:SetValue(MPPowerSaved.HerbalTeaMana_Value)

    checkButton_Rejuven:SetChecked(MPToBoolean(MPPowerSaved.Rejuven))
    slider_Rejuven:SetValue(MPPowerSaved.Rejuven_Value)
    checkButton_RejuvenMana:SetChecked(MPToBoolean(MPPowerSaved.RejuvenMana))
    slider_RejuvenMana:SetValue(MPPowerSaved.RejuvenMana_Value)

    checkButton_HealthStone:SetChecked(MPToBoolean(MPPowerSaved.HealthStone))
    slider_HealthStone:SetValue(MPPowerSaved.HealthStone_Value)
    checkButton_Carrot:SetChecked(MPToBoolean(MPPowerSaved.Carrot))
    slider_Carrot:SetValue(MPPowerSaved.Carrot_Value)
    checkButton_Healing:SetChecked(MPToBoolean(MPPowerSaved.Healing))
    slider_Healing:SetValue(MPPowerSaved.Healing_Value)
    checkButton_Mana:SetChecked(MPToBoolean(MPPowerSaved.Mana))
    slider_Mana:SetValue(MPPowerSaved.Mana_Value)

end

function MPInitPowerSettings()

    if not MPPowerSaved then
        MPPowerSaved = {}
        MPResetPowerSettings()
    end

    if MPPowerSaved.Version ~= PowerSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[药水宏]当前配置，这是新版插件正常数据更新！|r")
        MPResetPowerSettings()
    end

    MPInitPowerSettingsPart1()


    checkButton_Powerful:SetChecked(MPToBoolean(MPPowerSaved.Powerful))
    checkButton_PowerfulBoss:SetChecked(MPToBoolean(MPPowerSaved.PowerfulBoss))
    checkButton_Swiftness:SetChecked(MPToBoolean(MPPowerSaved.Swiftness))
    checkButton_SwiftnessBoss:SetChecked(MPToBoolean(MPPowerSaved.SwiftnessBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPPowerSaved.Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPPowerSaved.SoulspeedBoss))
    checkButton_Sacrificial:SetChecked(MPToBoolean(MPPowerSaved.Sacrificial))

    checkButton_Demon:SetChecked(MPToBoolean(MPPowerSaved.Demon))
    checkButton_DemonBoss:SetChecked(MPToBoolean(MPPowerSaved.DemonBoss))

    checkButton_Invincible:SetChecked(MPToBoolean(MPPowerSaved.Invincible))
    checkButton_InvincibleBoss:SetChecked(MPToBoolean(MPPowerSaved.InvincibleBoss))
    checkButton_Detoxify:SetChecked(MPToBoolean(MPPowerSaved.Detoxify))


end

