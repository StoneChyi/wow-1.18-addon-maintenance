
-- 定义插件名称
local ADDON_NAME = "Settings-DruidBear"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPDruidBearSaved[ConfigCurrent] end

CatUISettingsBearWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 500, "|cFFFF7D0A设置 - 熊德|r")



local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsBearWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsBearWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 熊形态
local checkButton_Bear = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 巨熊形态")
MPBindConfigCheckButton(checkButton_Bear, GetCurrentSaved, "Bear")

-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")


postion_y = postion_y-30

-- 创建单选框 - 挫志咆哮
local checkButton_Demoralizing = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 挫志咆哮")
MPBindConfigCheckButton(checkButton_Demoralizing, GetCurrentSaved, "Demoralizing")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")


postion_y = postion_y-30

-- 创建单选框 - 狂怒
local checkButton_Fury = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 狂怒")
MPBindConfigCheckButton(checkButton_Fury, GetCurrentSaved, "Fury")
local checkButton_FuryBoss = MPCreateCheckButtonSmall(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_FuryBoss, GetCurrentSaved, "FuryBoss")




-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 挥击
local checkButton_Swipe = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 挥击")
MPBindConfigCheckButton(checkButton_Swipe, GetCurrentSaved, "Swipe")



postion_y = postion_y-30

-- 创建单选框 - 精灵之火
local checkButton_FaerieFire = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 精灵之火")
MPBindConfigCheckButton(checkButton_FaerieFire, GetCurrentSaved, "FaerieFire")







-- 高级



postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsBearWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsBearWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-80


-- 创建单选框 - 群体优先挥击
local checkButton_SwipeFirst = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonSwipeFirst", 20, postion_y, "群体策略 优先挥击 (SuperWow)")
MPBindConfigCheckButton(checkButton_SwipeFirst, GetCurrentSaved, "SwipeFirst")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonSuperWow", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

_G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: 30%|r")
-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPDruidBearSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidBearSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidBearSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidBearSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPDruidBearSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidBearSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 优先槌击
local checkButton_MangleFirst = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonMangleFirst", 20, postion_y, "单体策略 槌击优先")
MPBindConfigCheckButton(checkButton_MangleFirst, GetCurrentSaved, "MangleFirst")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton_HerbalTea", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

_G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: 20%|r")
-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidBearSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidBearSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidBearSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidBearSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPDruidBearSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidBearSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y-40

--[[
-- boss再开爆发
local checkButton_Burst = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonBurst", 20, postion_y, "爆发保留BOSS阶段 狂怒")
MPBindConfigCheckButton(checkButton_Burst, GetCurrentSaved, "Burst")
]]
-- 创建单选框 - 取消拯救
local checkButton_UnSalvation = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonUnSalvation", 20, postion_y, "自动取消 拯救祝福")
MPBindConfigCheckButton(checkButton_UnSalvation, GetCurrentSaved, "UnSalvation")

-- 创建单选框 - 狂暴回复
local checkButton_Frenzied = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton_Frenzied", 340, postion_y, "自动 狂暴回复")

local slider_Frenzied = MPCreateConfigSlider(ADDON_NAME.."Slider_Frenzied", checkButton_Frenzied, "RIGHT", checkButton_Frenzied, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Frenzied = "|cFFFFD100"

_G[slider_Frenzied:GetName().."Text"]:SetText(color_Frenzied.."血线: 20%|r")
-- 值变化时的回调函数
slider_Frenzied:SetScript("OnValueChanged", function()
    --print("Frenzied当前值:", arg1)
    MPDruidBearSaved[ConfigCurrent].Frenzied_Value = arg1
    _G[slider_Frenzied:GetName().."Text"]:SetText(color_Frenzied.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_Frenzied:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidBearSaved[ConfigCurrent].Frenzied = 1
        color_Frenzied = "|cFFFFD100"
        _G[slider_Frenzied:GetName().."Text"]:SetText(color_Frenzied.."血线: ".. MPDruidBearSaved[ConfigCurrent].Frenzied_Value .."%|r")
    else
        MPDruidBearSaved[ConfigCurrent].Frenzied = 0
        color_Frenzied = "|cFF888888"
        _G[slider_Frenzied:GetName().."Text"]:SetText(color_Frenzied.."血线: ".. MPDruidBearSaved[ConfigCurrent].Frenzied_Value .."%|r")
    end
end)



postion_y = postion_y-40





-- 创建单选框 - 狂暴
local checkButton_Berserk = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton_Berserk", 340, postion_y, "自动 狂暴")

local slider_Berserk = MPCreateConfigSlider(ADDON_NAME.."Slider_Berserk", checkButton_Berserk, "RIGHT", checkButton_Berserk, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Berserk = "|cFFFFD100"

_G[slider_Berserk:GetName().."Text"]:SetText(color_Berserk.."血线: 20%|r")
-- 值变化时的回调函数
slider_Berserk:SetScript("OnValueChanged", function()
    --print("Berserk当前值:", arg1)
    MPDruidBearSaved[ConfigCurrent].Berserk_Value = arg1
    _G[slider_Berserk:GetName().."Text"]:SetText(color_Berserk.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_Berserk:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidBearSaved[ConfigCurrent].Berserk = 1
        color_Berserk = "|cFFFFD100"
        _G[slider_Berserk:GetName().."Text"]:SetText(color_Berserk.."血线: ".. MPDruidBearSaved[ConfigCurrent].Berserk_Value .."%|r")
    else
        MPDruidBearSaved[ConfigCurrent].Berserk = 0
        color_Berserk = "|cFF888888"
        _G[slider_Berserk:GetName().."Text"]:SetText(color_Berserk.."血线: ".. MPDruidBearSaved[ConfigCurrent].Berserk_Value .."%|r")
    end
end)





postion_y = postion_y-40





-- 创建单选框 - 树皮术
local checkButton_Barkskin = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButton_Barkskin", 340, postion_y, "自动 树皮术")

local slider_Barkskin = MPCreateConfigSlider(ADDON_NAME.."Slider_Barkskin", checkButton_Barkskin, "RIGHT", checkButton_Barkskin, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Barkskin = "|cFFFFD100"

_G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: 20%|r")
-- 值变化时的回调函数
slider_Barkskin:SetScript("OnValueChanged", function()
    --print("Berserk当前值:", arg1)
    MPDruidBearSaved[ConfigCurrent].Barkskin_Value = arg1
    _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_Barkskin:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidBearSaved[ConfigCurrent].Barkskin = 1
        color_Barkskin = "|cFFFFD100"
        _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidBearSaved[ConfigCurrent].Barkskin_Value .."%|r")
    else
        MPDruidBearSaved[ConfigCurrent].Barkskin = 0
        color_Barkskin = "|cFF888888"
        _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidBearSaved[ConfigCurrent].Barkskin_Value .."%|r")
    end
end)



postion_y = postion_y-40



-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsBearWindow, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsBearWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")





local myButton = MPCreateButton(CatUISettingsBearWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetBearSettings(ConfigCurrent)
    MPInitBearSettings()
end)



local ConfigButton = MPCreateConfigSelector(CatUISettingsBearWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitBearSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsBearWindow, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsBearWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsBearWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFF7D0A/beardps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local BearSettingsUIVersion = 16

function MPResetBearSettings(config)

    MPDruidBearSaved.Version = BearSettingsUIVersion

    -- 基本配置

    MPDruidBearSaved[config].Bear = 1
    MPDruidBearSaved[config].Trinket_Upper = 1
    MPDruidBearSaved[config].TUBoss = 0
    MPDruidBearSaved[config].Trinket_Below = 1
    MPDruidBearSaved[config].TBBoss = 0
    MPDruidBearSaved[config].Fury = 1
    MPDruidBearSaved[config].FuryBoss = 0
    MPDruidBearSaved[config].Swipe = 1
    MPDruidBearSaved[config].FaerieFire = 1
    MPDruidBearSaved[config].Demoralizing = 1
    MPDruidBearSaved[config].Target = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPDruidBearSaved[config].HealthStone = 1
    MPDruidBearSaved[config].HealthStone_Value = 30
    MPDruidBearSaved[config].HerbalTea = 1
    MPDruidBearSaved[config].HerbalTea_Value = 20
    MPDruidBearSaved[config].Frenzied = 0
    MPDruidBearSaved[config].Frenzied_Value = 20
    MPDruidBearSaved[config].Berserk = 0
    MPDruidBearSaved[config].Berserk_Value = 20
    MPDruidBearSaved[config].Barkskin = 0
    MPDruidBearSaved[config].Barkskin_Value = 30

    -- SuperWoW,UnitXP
    MPDruidBearSaved[config].SuperWoW = 1
    MPDruidBearSaved[config].UnitXP = 1

    MPDruidBearSaved[config].SwipeFirst = 1
    MPDruidBearSaved[config].MangleFirst = 0
    MPDruidBearSaved[config].Burst = 0
    MPDruidBearSaved[config].UnSalvation = 0
    MPDruidBearSaved[config].Soulspeed = 0
    MPDruidBearSaved[config].SoulspeedBoss = 1

    -- 通用
    MPDruidBearSaved[config].Power = 0
    MPDruidBearSaved[config].Pick = 0

end


local function InitBearSettingsPart1()
    checkButton_Bear:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Bear))
    checkButton_Frenzied:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Frenzied))
    checkButton_Berserk:SetChecked( MPToBoolean(MPDruidBearSaved[ConfigCurrent].Berserk) )
    checkButton_FaerieFire:SetChecked( MPToBoolean(MPDruidBearSaved[ConfigCurrent].FaerieFire) )
    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Target))
    checkButton_Demoralizing:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Demoralizing))
    checkButton_Fury:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Fury))
    checkButton_FuryBoss:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].FuryBoss))
    checkButton_Swipe:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Swipe))

    --checkButton_SuperWoW:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].SuperWoW))
    --checkButton_UnitXP:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].UnitXP))
    checkButton_SwipeFirst:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].SwipeFirst))
    checkButton_MangleFirst:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].MangleFirst))
    --checkButton_Burst:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Burst))
    checkButton_UnSalvation:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].UnSalvation))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].Pick))

end

function MPInitBearSettings()
    if not MPDruidBearSaved then
        MPDruidBearSaved = {}

        -- 第一套配置
        if not MPDruidBearSaved[1] then
            MPDruidBearSaved[1] = {}
            MPResetBearSettings(1)
        end

        -- 第二套配置
        if not MPDruidBearSaved[2] then
            MPDruidBearSaved[2] = {}
            MPResetBearSettings(2)
        end

        -- 第三套配置
        if not MPDruidBearSaved[3] then
            MPDruidBearSaved[3] = {}
            MPResetBearSettings(3)
        end
    end

    if MPDruidBearSaved.Version ~= BearSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[熊德宏]当前配置，这是新版插件正常数据更新！|r")
        MPDruidBearSaved[1] = {}
        MPDruidBearSaved[2] = {}
        MPDruidBearSaved[3] = {}
        MPResetBearSettings(1)
        MPResetBearSettings(2)
        MPResetBearSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitBearSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPDruidBearSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPDruidBearSaved[ConfigCurrent].HealthStone_Value)
    if MPDruidBearSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidBearSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPDruidBearSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPDruidBearSaved[ConfigCurrent].HerbalTea_Value)
    if MPDruidBearSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidBearSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_Frenzied:SetChecked(MPDruidBearSaved[ConfigCurrent].Frenzied)
    slider_Frenzied:SetValue(MPDruidBearSaved[ConfigCurrent].Frenzied_Value)
    if MPDruidBearSaved[ConfigCurrent].Frenzied==1 then
        color_Frenzied = "|cFFFFD100"
    else
        color_Frenzied = "|cFF888888"
    end
    _G[slider_Frenzied:GetName().."Text"]:SetText(color_Frenzied.."血线: ".. MPDruidBearSaved[ConfigCurrent].Frenzied_Value .."%|r")

    checkButton_Berserk:SetChecked(MPDruidBearSaved[ConfigCurrent].Berserk)
    slider_Berserk:SetValue(MPDruidBearSaved[ConfigCurrent].Berserk_Value)
    if MPDruidBearSaved[ConfigCurrent].Berserk==1 then
        color_Berserk = "|cFFFFD100"
    else
        color_Berserk = "|cFF888888"
    end
    _G[slider_Berserk:GetName().."Text"]:SetText(color_Berserk.."血线: ".. MPDruidBearSaved[ConfigCurrent].Berserk_Value .."%|r")

    checkButton_Barkskin:SetChecked(MPDruidBearSaved[ConfigCurrent].Barkskin)
    slider_Barkskin:SetValue(MPDruidBearSaved[ConfigCurrent].Barkskin_Value)
    if MPDruidBearSaved[ConfigCurrent].Barkskin==1 then
        color_Barkskin = "|cFFFFD100"
    else
        color_Barkskin = "|cFF888888"
    end
    _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidBearSaved[ConfigCurrent].Barkskin_Value .."%|r")

end

