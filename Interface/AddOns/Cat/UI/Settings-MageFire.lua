
-- 定义插件名称
local ADDON_NAME = "Settings-MageFire"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPMageFireSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsMageFire = MPCreateFrame(ADDON_NAME.."Frame", 520, 520, "|cFF69CCF0设置 - 火法|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsMageFire:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsMageFire, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 魔甲术
local checkButton_MageArmor = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "保持 魔甲术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_MageArmor, GetCurrentSaved, "MageArmor")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 火球术
local checkButton_Fireball = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "开启 火球术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Fireball, GetCurrentSaved, "Fireball")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 奥术涌动​
local checkButton_ArcaneSurge = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奥术涌动")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ArcaneSurge, GetCurrentSaved, "ArcaneSurge")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 火焰冲击
local checkButton_FireBlast = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "开启 火焰冲击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FireBlast, GetCurrentSaved, "FireBlast")


postion_y = postion_y-30

-- 创建单选框 - 炎爆术
local checkButton_Pyroblast = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "开启 炎爆术​ (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Pyroblast, GetCurrentSaved, "Pyroblast")


postion_y = postion_y-30

-- 创建单选框 - 灼烧
local checkButton_Scorch = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "保持 火焰易伤 (SuperWoW)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Scorch, GetCurrentSaved, "Scorch")









-- 高级


postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsMageFire:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsMageFire, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-85


-- 创建单选框 - 进战斗前预读 炎爆术
local checkButton_FirstPyroblast = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 炎爆术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstPyroblast, GetCurrentSaved, "FirstPyroblast")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPMageFireSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFireSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFireSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFireSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPMageFireSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFireSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 保护点燃
local checkButton_IgniteProtect = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 20, postion_y, "保护 优质点燃 (团队中)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_IgniteProtect, GetCurrentSaved, "IgniteProtect")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFireSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFireSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFireSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFireSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPMageFireSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFireSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40





-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFireSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPMageFireSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40


-- 创建单选框 - 宝石 蓝量
local checkButton_JewelMana = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动 法力宝石")

local slider_JewelMana = MPCreateConfigSlider(ADDON_NAME.."Slider_JewelMana", checkButton_JewelMana, "RIGHT", checkButton_JewelMana, "RIGHT", 250, -2, 150, 16, 1, 100, 1, 20)

local color_JewelMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_JewelMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPMageFireSaved[ConfigCurrent].JewelMana_Value = arg1
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].JewelMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_JewelMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMageFireSaved[ConfigCurrent].JewelMana = 1
        color_JewelMana = "|cFFFFD100"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].JewelMana_Value .."%|r")
    else
        MPMageFireSaved[ConfigCurrent].JewelMana = 0
        color_JewelMana = "|cFF888888"
        _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].JewelMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsMageFire, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



-- 炎爆术 法术连击
local slider_Pyromaniac = MPCreateConfigSlider(ADDON_NAME.."SliderPyromaniac", CatUISettingsMageFire, "TOPLEFT", CatUISettingsMageFire, "TOPLEFT", 20, postion_y+180, 220, 16, 1, 5, 1, 0)

-- 值变化时的回调函数
slider_Pyromaniac:SetScript("OnValueChanged", function()
    _G[slider_Pyromaniac:GetName().."Text"]:SetText("炎爆术 法术连击 层级："..arg1)
    MPMageFireSaved[ConfigCurrent].Pyromaniac = arg1
end)



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsMageFire, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetMageFireSettings(ConfigCurrent)
    MPInitMageFireSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsMageFire, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitMageFireSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsMageFire, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsMageFire:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsMageFire, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF69CCF0/mhdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local MageFireSettingsUIVersion = 8

function MPResetMageFireSettings(config)

    MPMageFireSaved.Version = MageFireSettingsUIVersion

    -- 基本配置

    MPMageFireSaved[config].MageArmor = 1
    MPMageFireSaved[config].Fireball = 1
    MPMageFireSaved[config].ArcaneSurge = 1
    MPMageFireSaved[config].FireBlast = 1
    MPMageFireSaved[config].Pyroblast = 1
    MPMageFireSaved[config].Scorch = 0

    MPMageFireSaved[config].Trinket_Upper = 1
    MPMageFireSaved[config].TUBoss = 0
    MPMageFireSaved[config].Trinket_Below = 1
    MPMageFireSaved[config].TBBoss = 0
    MPMageFireSaved[config].Target = 0



    -- 高级配置

    -- 治疗石、糖水茶
    MPMageFireSaved[config].HealthStone = 1
    MPMageFireSaved[config].HealthStone_Value = 30
    MPMageFireSaved[config].HerbalTea = 1
    MPMageFireSaved[config].HerbalTea_Value = 20
    MPMageFireSaved[config].HerbalTeaMana = 0
    MPMageFireSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPMageFireSaved[config].SuperWoW = 1
    MPMageFireSaved[config].UnitXP = 1

    MPMageFireSaved[config].FirstPyroblast = 0
    MPMageFireSaved[config].IgniteProtect = 1
    MPMageFireSaved[config].Pyromaniac = 3

    MPMageFireSaved[config].RacialTraits = 0
    MPMageFireSaved[config].RacialTraitsBoss = 1
    MPMageFireSaved[config].Soulspeed = 0
    MPMageFireSaved[config].SoulspeedBoss = 1

    MPMageFireSaved[config].JewelMana_Value = 35
    MPMageFireSaved[config].JewelMana = 0

    -- 通用
    MPMageFireSaved[config].Power = 0
    MPMageFireSaved[config].Pick = 0

end


local function MPInitMageFireSettingsPart1()

    checkButton_MageArmor:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].MageArmor))
    checkButton_Fireball:SetChecked( MPToBoolean(MPMageFireSaved[ConfigCurrent].Fireball) )
    checkButton_ArcaneSurge:SetChecked( MPToBoolean(MPMageFireSaved[ConfigCurrent].ArcaneSurge) )
    checkButton_FireBlast:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].FireBlast))
    checkButton_Pyroblast:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Pyroblast))
    checkButton_Scorch:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Scorch))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Target))

    checkButton_FirstPyroblast:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].FirstPyroblast))
    checkButton_IgniteProtect:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].IgniteProtect))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].Pick))

end

function MPInitMageFireSettings()
    if not MPMageFireSaved then
        MPMageFireSaved = {}

        -- 第一套配置
        if not MPMageFireSaved[1] then
            MPMageFireSaved[1] = {}
            MPResetMageFireSettings(1)
        end

        -- 第二套配置
        if not MPMageFireSaved[2] then
            MPMageFireSaved[2] = {}
            MPResetMageFireSettings(2)
        end

        -- 第三套配置
        if not MPMageFireSaved[3] then
            MPMageFireSaved[3] = {}
            MPResetMageFireSettings(3)
        end
    end

    if MPMageFireSaved.Version ~= MageFireSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[火法宏]当前配置，这是新版插件正常数据更新！|r")
        MPMageFireSaved[1] = {}
        MPMageFireSaved[2] = {}
        MPMageFireSaved[3] = {}
        MPResetMageFireSettings(1)
        MPResetMageFireSettings(2)
        MPResetMageFireSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitMageFireSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPMageFireSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPMageFireSaved[ConfigCurrent].HealthStone_Value)
    if MPMageFireSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPMageFireSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPMageFireSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPMageFireSaved[ConfigCurrent].HerbalTea_Value)
    if MPMageFireSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPMageFireSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPMageFireSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPMageFireSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_JewelMana:SetChecked(MPMageFireSaved[ConfigCurrent].JewelMana)
    slider_JewelMana:SetValue(MPMageFireSaved[ConfigCurrent].JewelMana_Value)
    if MPMageFireSaved[ConfigCurrent].JewelMana==1 then
        color_JewelMana = "|cFFFFD100"
    else
        color_JewelMana = "|cFF888888"
    end
    _G[slider_JewelMana:GetName().."Text"]:SetText(color_JewelMana.."蓝量: ".. MPMageFireSaved[ConfigCurrent].JewelMana_Value .."%|r")

    slider_Pyromaniac:SetValue(MPMageFireSaved[ConfigCurrent].Pyromaniac)
    _G[slider_Pyromaniac:GetName().."Text"]:SetText("炎爆术 法术连击 层级："..MPMageFireSaved[ConfigCurrent].Pyromaniac)

end

