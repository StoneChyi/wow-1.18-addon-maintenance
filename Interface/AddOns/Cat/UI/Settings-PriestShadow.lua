
-- 定义插件名称
local ADDON_NAME = "Settings-PriestShadow"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPPriestShadowSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsPriestShadow = MPCreateFrame(ADDON_NAME.."Frame", 520, 570, "|cFFFFFFFF设置 - 暗牧|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPriestShadow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPriestShadow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 保持暗影形态
local checkButton_Shadowform = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 暗影形态")
MPBindConfigCheckButton(checkButton_Shadowform, GetCurrentSaved, "Shadowform")



-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 保持 心灵之火
local checkButton_InnerFire = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 心灵之火")
MPBindConfigCheckButton(checkButton_InnerFire, GetCurrentSaved, "InnerFire")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")



postion_y = postion_y-30

-- 创建单选框 - 保持 暗言术：痛
local checkButton_Pain = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 暗言术：痛")
MPBindConfigCheckButton(checkButton_Pain, GetCurrentSaved, "Pain")



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 心灵震爆
local checkButton_MindBlast = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 心灵震爆")
MPBindConfigCheckButton(checkButton_MindBlast, GetCurrentSaved, "MindBlast")



postion_y = postion_y-30

-- 创建单选框 - 精神鞭笞
local checkButton_MindFlay = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 精神鞭笞")
MPBindConfigCheckButton(checkButton_MindFlay, GetCurrentSaved, "MindFlay")



postion_y = postion_y-30

-- 创建单选框 - 痛苦尖刺
local checkButton_MindSpike = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 痛苦尖刺")
MPBindConfigCheckButton(checkButton_MindSpike, GetCurrentSaved, "MindSpike")


postion_y = postion_y-30

-- 创建单选框 - 吸血鬼的拥抱
local checkButton_Vampiric = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 吸血鬼的拥抱")
MPBindConfigCheckButton(checkButton_Vampiric, GetCurrentSaved, "Vampiric")
local checkButton_VampiricBOSS = MPCreateCheckButtonSmall(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_VampiricBOSS, GetCurrentSaved, "VampiricBOSS")


postion_y = postion_y-30

-- 创建单选框 - 渐隐术
local checkButton_Fade = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 渐隐术")
MPBindConfigCheckButton(checkButton_Fade, GetCurrentSaved, "Fade")




-- 高级



postion_y = postion_y+20

-- 添加提示内容区域
local TipText1 = CatUISettingsPriestShadow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPriestShadow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100


-- 创建单选框 - 二段鞭笞
local checkButton_SecondMindFlay = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 二段鞭笞 (5层易伤前)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SecondMindFlay, GetCurrentSaved, "SecondMindFlay")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 300)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPriestShadowSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestShadowSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPriestShadowSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40







-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestShadowSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPriestShadowSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y-40

-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsPriestShadow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



-- 渐隐术 等级
local slider_Fade_Value = MPCreateConfigSlider(ADDON_NAME.."SliderFade_Value", CatUISettingsPriestShadow, "TOPLEFT", CatUISettingsPriestShadow, "TOPLEFT", 20, postion_y+180, 220, 16, 1, 6, 1, 0)

-- 值变化时的回调函数
slider_Fade_Value:SetScript("OnValueChanged", function()
    _G[slider_Fade_Value:GetName().."Text"]:SetText("渐隐术 等级："..arg1)
    MPPriestShadowSaved[ConfigCurrent].Fade_Value = arg1
end)






-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPriestShadow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPriestShadowSettings(ConfigCurrent)
    MPInitPriestShadowSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPriestShadow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPriestShadowSettings()
end)



local MLDButton = CreateFrame("Button", ADDON_NAME.."ButtonReset", CatUISettingsPriestShadow, "UIPanelButtonTemplate")
MLDButton:SetPoint("TOPLEFT", CatUISettingsPriestShadow, "TOPLEFT", 340, postion_y+70)
MLDButton:SetWidth(120)
MLDButton:SetHeight(22)
MLDButton:SetFont("Fonts\\FRIZQT__.TTF", 12)
MLDButton:SetText("多线DOT设置")

-- 调整按钮纹理
MLDButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
MLDButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
MLDButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
MLDButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
-- 按钮点击事件
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPriestShadow, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsPriestShadow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPriestShadow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFFFFFF/amdps|r [ 1 | 2 | 3 ]   多线Dot |cFFFFFFFF/MDot|r")



-- 配置文件版本号
local PriestShadowSettingsUIVersion = 10

function MPResetPriestShadowSettings(config)

    MPPriestShadowSaved.Version = PriestShadowSettingsUIVersion

    -- 基本配置

    MPPriestShadowSaved[config].Shadowform = 1
    MPPriestShadowSaved[config].InnerFire = 1

    MPPriestShadowSaved[config].MindBlast = 1
    MPPriestShadowSaved[config].Pain = 1
    MPPriestShadowSaved[config].MindFlay = 1
    MPPriestShadowSaved[config].MindSpike = 0
    MPPriestShadowSaved[config].Vampiric = 0
    MPPriestShadowSaved[config].Fade = 0

    MPPriestShadowSaved[config].Trinket_Upper = 1
    MPPriestShadowSaved[config].TUBoss = 0
    MPPriestShadowSaved[config].Trinket_Below = 1
    MPPriestShadowSaved[config].TBBoss = 0
    MPPriestShadowSaved[config].Target = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPPriestShadowSaved[config].HealthStone = 1
    MPPriestShadowSaved[config].HealthStone_Value = 30
    MPPriestShadowSaved[config].HerbalTea = 1
    MPPriestShadowSaved[config].HerbalTea_Value = 20
    MPPriestShadowSaved[config].HerbalTeaMana = 0
    MPPriestShadowSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPPriestShadowSaved[config].SuperWoW = 1
    MPPriestShadowSaved[config].UnitXP = 1

    MPPriestShadowSaved[config].SecondMindFlay = 0
    MPPriestShadowSaved[config].VampiricBOSS = 0

    MPPriestShadowSaved[config].Fade_Value = 6
    MPPriestShadowSaved[config].RacialTraits = 0
    MPPriestShadowSaved[config].RacialTraitsBoss = 1
    MPPriestShadowSaved[config].Soulspeed = 0
    MPPriestShadowSaved[config].SoulspeedBoss = 1

    -- 通用
    MPPriestShadowSaved[config].Power = 0
    MPPriestShadowSaved[config].Pick = 0

end

local function MPInitPriestShadowSettingsPart1()
    checkButton_Shadowform:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Shadowform))
    checkButton_InnerFire:SetChecked( MPToBoolean(MPPriestShadowSaved[ConfigCurrent].InnerFire) )
    checkButton_MindBlast:SetChecked( MPToBoolean(MPPriestShadowSaved[ConfigCurrent].MindBlast) )
    checkButton_Pain:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Pain))
    checkButton_MindFlay:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].MindFlay))
    checkButton_MindSpike:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].MindSpike))
    checkButton_Vampiric:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Vampiric))
    checkButton_Fade:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Fade))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Target))

    checkButton_SecondMindFlay:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].SecondMindFlay))
    checkButton_VampiricBOSS:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].VampiricBOSS))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].SoulspeedBoss))
end

function MPInitPriestShadowSettings()
    if not MPPriestShadowSaved then
        MPPriestShadowSaved = {}

        -- 第一套配置
        if not MPPriestShadowSaved[1] then
            MPPriestShadowSaved[1] = {}
            MPResetPriestShadowSettings(1)
        end

        -- 第二套配置
        if not MPPriestShadowSaved[2] then
            MPPriestShadowSaved[2] = {}
            MPResetPriestShadowSettings(2)
        end

        -- 第三套配置
        if not MPPriestShadowSaved[3] then
            MPPriestShadowSaved[3] = {}
            MPResetPriestShadowSettings(3)
        end
    end

    if MPPriestShadowSaved.Version ~= PriestShadowSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[暗牧宏]当前配置，这是新版插件正常数据更新！|r")
        MPPriestShadowSaved[1] = {}
        MPPriestShadowSaved[2] = {}
        MPPriestShadowSaved[3] = {}
        MPResetPriestShadowSettings(1)
        MPResetPriestShadowSettings(2)
        MPResetPriestShadowSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitPriestShadowSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPriestShadowSaved[ConfigCurrent].HealthStone_Value)
    if MPPriestShadowSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestShadowSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestShadowSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestShadowSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestShadowSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestShadowSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    slider_Fade_Value:SetValue(MPPriestShadowSaved[ConfigCurrent].Fade_Value)

    checkButton_Power:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPriestShadowSaved[ConfigCurrent].Pick))

end

