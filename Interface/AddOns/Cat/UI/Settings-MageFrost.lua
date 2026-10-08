
-- 定义插件名称
local ADDON_NAME = "Settings-MageFrost"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPMageFrostSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsMageFrost = MPCreateFrame(ADDON_NAME.."Frame", 520, 540, "|cFF69CCF0设置 - 冰法|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsMageFrost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsMageFrost, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 魔甲术
local checkButton_MageArmor = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "保持 魔甲术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MageArmor, GetCurrentSaved, "MageArmor")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 寒冰护体
local checkButton_IceBarrier = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "保持 寒冰护体")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_IceBarrier, GetCurrentSaved, "IceBarrier")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 奥术涌动​
local checkButton_ArcaneSurge = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术涌动")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneSurge, GetCurrentSaved, "ArcaneSurge")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 冰锥术​
local checkButton_ConeCold = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 冰锥术 (需UnitXP)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ConeCold, GetCurrentSaved, "ConeCold")


postion_y = postion_y-30

-- 创建单选框 - 冰霜新星
local checkButton_FrostNova = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 冰霜新星 (需UnitXP)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FrostNova, GetCurrentSaved, "FrostNova")


postion_y = postion_y-30

-- 创建单选框 - 冰柱​
local checkButton_Icicle = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 冰柱")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Icicle, GetCurrentSaved, "Icicle")


postion_y = postion_y-30

-- 创建单选框 - 火焰冲击
local checkButton_FireBlast = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 火焰冲击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FireBlast, GetCurrentSaved, "FireBlast")











-- 高级


postion_y = postion_y+10

-- 添加提示内容区域
local TipText1 = CatUISettingsMageFrost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsMageFrost, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-95


-- 创建单选框 - 冰霜速冻
local checkButton_Frostbite = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "开启 冰柱条件 冰霜速冻")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Frostbite, GetCurrentSaved, "Frostbite")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPMageFrostSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFrostSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFrostSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFrostSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPMageFrostSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFrostSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 冰冷血脉
local checkButton_ColdBloodline = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "仅保持 冰冷血脉")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ColdBloodline, GetCurrentSaved, "ColdBloodline")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFrostSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFrostSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFrostSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFrostSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPMageFrostSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFrostSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 保护点燃
local checkButton_IgniteProtect = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 20, postion_y, "保护 优质点燃 (团队中)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_IgniteProtect, GetCurrentSaved, "IgniteProtect")


-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFrostSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPMageFrostSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40




-- 创建单选框 - 宝石 蓝量
local checkButton_JewelMana = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动 法力宝石")

local slider_JewelMana = MPCreateConfigSlider(ADDON_NAME.."Slider_JewelMana", checkButton_JewelMana, "RIGHT", checkButton_JewelMana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 20)

local color_JewelMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_JewelMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFrostSaved[ConfigCurrent].JewelMana_Value = arg1
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].JewelMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_JewelMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFrostSaved[ConfigCurrent].JewelMana = 1
        color_JewelMana = "|cFFFFD100"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].JewelMana_Value .."%|r")
    else
        MPMageFrostSaved[ConfigCurrent].JewelMana = 0
        color_JewelMana = "|cFF888888"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].JewelMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")



postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsMageFrost, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsMageFrost, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetMageFrostSettings(ConfigCurrent)
    MPInitMageFrostSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsMageFrost, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitMageFrostSettings()
end)




-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsMageFrost, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsMageFrost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsMageFrost, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF69CCF0/mfdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local MageFrostSettingsUIVersion = 11

function MPResetMageFrostSettings(config)

    MPMageFrostSaved.Version = MageFrostSettingsUIVersion

    -- 基本配置

    MPMageFrostSaved[config].MageArmor = 1
    MPMageFrostSaved[config].IceBarrier = 1
    MPMageFrostSaved[config].ArcaneSurge = 1
    MPMageFrostSaved[config].ConeCold = 0
    MPMageFrostSaved[config].FrostNova = 1
    MPMageFrostSaved[config].Icicle = 1
    MPMageFrostSaved[config].FireBlast = 0

    MPMageFrostSaved[config].Trinket_Upper = 1
    MPMageFrostSaved[config].TUBoss = 0
    MPMageFrostSaved[config].Trinket_Below = 1
    MPMageFrostSaved[config].TBBoss = 0
    MPMageFrostSaved[config].Target = 0



    -- 高级配置

    -- 治疗石、糖水茶
    MPMageFrostSaved[config].HealthStone = 1
    MPMageFrostSaved[config].HealthStone_Value = 30
    MPMageFrostSaved[config].HerbalTea = 1
    MPMageFrostSaved[config].HerbalTea_Value = 20
    MPMageFrostSaved[config].HerbalTeaMana = 0
    MPMageFrostSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPMageFrostSaved[config].SuperWoW = 1
    MPMageFrostSaved[config].UnitXP = 1

    MPMageFrostSaved[config].Frostbite = 1
    MPMageFrostSaved[config].RacialTraits = 0
    MPMageFrostSaved[config].RacialTraitsBoss = 1
    MPMageFrostSaved[config].Soulspeed = 0
    MPMageFrostSaved[config].SoulspeedBoss = 1
    MPMageFrostSaved[config].IgniteProtect = 1
    MPMageFrostSaved[config].ColdBloodline = 0

    MPMageFrostSaved[config].JewelMana_Value = 35
    MPMageFrostSaved[config].JewelMana = 0

    -- 通用
    MPMageFrostSaved[config].Power = 0
    MPMageFrostSaved[config].Pick = 0

end


local function MPInitMageFrostSettingsPart1()

    checkButton_MageArmor:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].MageArmor))
    checkButton_IceBarrier:SetChecked( MPToBoolean(MPMageFrostSaved[ConfigCurrent].IceBarrier) )
    checkButton_ArcaneSurge:SetChecked( MPToBoolean(MPMageFrostSaved[ConfigCurrent].ArcaneSurge) )
    checkButton_ConeCold:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].ConeCold))
    checkButton_FrostNova:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].FrostNova))
    checkButton_Icicle:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Icicle))
    checkButton_FireBlast:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].FireBlast))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Target))

    checkButton_Frostbite:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Frostbite))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_IgniteProtect:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].IgniteProtect))
    checkButton_ColdBloodline:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].ColdBloodline))

    checkButton_Power:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].Pick))
end

function MPInitMageFrostSettings()
    if not MPMageFrostSaved then
        MPMageFrostSaved = {}

        -- 第一套配置
        if not MPMageFrostSaved[1] then
            MPMageFrostSaved[1] = {}
            MPResetMageFrostSettings(1)
        end

        -- 第二套配置
        if not MPMageFrostSaved[2] then
            MPMageFrostSaved[2] = {}
            MPResetMageFrostSettings(2)
        end

        -- 第三套配置
        if not MPMageFrostSaved[3] then
            MPMageFrostSaved[3] = {}
            MPResetMageFrostSettings(3)
        end
    end

    if MPMageFrostSaved.Version ~= MageFrostSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[猫德宏]当前配置，这是新版插件正常数据更新！|r")
        MPMageFrostSaved[1] = {}
        MPMageFrostSaved[2] = {}
        MPMageFrostSaved[3] = {}
        MPResetMageFrostSettings(1)
        MPResetMageFrostSettings(2)
        MPResetMageFrostSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitMageFrostSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPMageFrostSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPMageFrostSaved[ConfigCurrent].HealthStone_Value)
    if MPMageFrostSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFrostSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPMageFrostSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPMageFrostSaved[ConfigCurrent].HerbalTea_Value)
    if MPMageFrostSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFrostSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPMageFrostSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPMageFrostSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_JewelMana:SetChecked(MPMageFrostSaved[ConfigCurrent].JewelMana)
    slider_JewelMana:SetValue(MPMageFrostSaved[ConfigCurrent].JewelMana_Value)
    if MPMageFrostSaved[ConfigCurrent].JewelMana==1 then
        color_JewelMana = "|cFFFFD100"
    else
        color_JewelMana = "|cFF888888"
    end
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFrostSaved[ConfigCurrent].JewelMana_Value .."%|r")


end

