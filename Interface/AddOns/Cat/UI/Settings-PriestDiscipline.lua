
-- 定义插件名称
local ADDON_NAME = "Settings-PriestDiscipline"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPPriestDisciplineSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsPriestDiscipline = MPCreateFrame(ADDON_NAME.."Frame", 520, 460, "|cFFFFFFFF设置 - 戒律牧|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPriestDiscipline:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPriestDiscipline, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 保持神圣之火
local checkButton_HolyFire = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "保持 神圣之火")
MPBindConfigCheckButton(checkButton_HolyFire, GetCurrentSaved, "HolyFire")



-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 保持 心灵之火
local checkButton_InnerFire = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "保持 心灵之火")
MPBindConfigCheckButton(checkButton_InnerFire, GetCurrentSaved, "InnerFire")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")



postion_y = postion_y-30

-- 创建单选框 - 保持 痛
local checkButton_Pain = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "保持 暗言术：痛")
MPBindConfigCheckButton(checkButton_Pain, GetCurrentSaved, "Pain")




-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")



postion_y = postion_y-30


-- 创建单选框 - 惩击
local checkButton_Smite = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "开启 惩击")
MPBindConfigCheckButton(checkButton_Smite, GetCurrentSaved, "Smite")


postion_y = postion_y-30

-- 创建单选框 - 责罚
local checkButton_Chastise = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "开启 责罚")
MPBindConfigCheckButton(checkButton_Chastise, GetCurrentSaved, "Chastise")









-- 高级



postion_y = postion_y+5

-- 添加提示内容区域
local TipText1 = CatUISettingsPriestDiscipline:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPriestDiscipline, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-80


-- 创建单选框 - 启发对自己
local checkButton_InspireMyself = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "启发 对 自己使用")
MPBindConfigCheckButton(checkButton_InspireMyself, GetCurrentSaved, "InspireMyself")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 300)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestDisciplineSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPriestDisciplineSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 责罚对自己
local checkButton_ChastiseMyself = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 20, postion_y, "责罚 对 自己使用")
MPBindConfigCheckButton(checkButton_ChastiseMyself, GetCurrentSaved, "ChastiseMyself")




-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestDisciplineSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPriestDisciplineSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40






-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 200)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")



postion_y = postion_y-40

-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsPriestDiscipline, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



--[[
-- 渐隐术 等级
local slider_Fade_Value = MPCreateConfigSlider(ADDON_NAME.."SliderFade_Value", CatUISettingsPriestDiscipline, "TOPLEFT", CatUISettingsPriestDiscipline, "TOPLEFT", 20, postion_y+80, 220, 16, 1, 6, 1, 0)

-- 值变化时的回调函数
slider_Fade_Value:SetScript("OnValueChanged", function()
    _G[slider_Fade_Value:GetName().."Text"]:SetText("渐隐术 等级："..arg1)
    MPPriestDisciplineSaved[ConfigCurrent].Fade_Value = arg1
end)
]]





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPriestDiscipline, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPriestDisciplineSettings(ConfigCurrent)
    MPInitPriestDisciplineSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPriestDiscipline, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPriestDisciplineSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPriestDiscipline, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsPriestDiscipline:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPriestDiscipline, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFFFFFF/JLdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PriestDisciplineSettingsUIVersion = 9

function MPResetPriestDisciplineSettings(config)

    MPPriestDisciplineSaved.Version = PriestDisciplineSettingsUIVersion

    -- 基本配置

    MPPriestDisciplineSaved[config].HolyFire = 1
    MPPriestDisciplineSaved[config].InnerFire = 1
    MPPriestDisciplineSaved[config].Pain = 0

    MPPriestDisciplineSaved[config].Smite = 1
    MPPriestDisciplineSaved[config].Chastise = 0

    MPPriestDisciplineSaved[config].Trinket_Upper = 1
    MPPriestDisciplineSaved[config].TUBoss = 0
    MPPriestDisciplineSaved[config].Trinket_Below = 1
    MPPriestDisciplineSaved[config].TBBoss = 0
    MPPriestDisciplineSaved[config].Target = 0



    MPPriestDisciplineSaved[config].InspireMyself = 0
    MPPriestDisciplineSaved[config].ChastiseMyself = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPPriestDisciplineSaved[config].HealthStone = 1
    MPPriestDisciplineSaved[config].HealthStone_Value = 30
    MPPriestDisciplineSaved[config].HerbalTea = 1
    MPPriestDisciplineSaved[config].HerbalTea_Value = 20
    MPPriestDisciplineSaved[config].HerbalTeaMana = 0
    MPPriestDisciplineSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPPriestDisciplineSaved[config].SuperWoW = 1
    MPPriestDisciplineSaved[config].UnitXP = 1

    --MPPriestDisciplineSaved[config].Fade_Value = 6
    MPPriestDisciplineSaved[config].RacialTraits = 0
    MPPriestDisciplineSaved[config].RacialTraitsBoss = 1
    MPPriestDisciplineSaved[config].Soulspeed = 0
    MPPriestDisciplineSaved[config].SoulspeedBoss = 1

    -- 通用
    MPPriestDisciplineSaved[config].Power = 0
    MPPriestDisciplineSaved[config].Pick = 0

end


function MPInitPriestDisciplineSettings()
    if not MPPriestDisciplineSaved then
        MPPriestDisciplineSaved = {}

        -- 第一套配置
        if not MPPriestDisciplineSaved[1] then
            MPPriestDisciplineSaved[1] = {}
            MPResetPriestDisciplineSettings(1)
        end

        -- 第二套配置
        if not MPPriestDisciplineSaved[2] then
            MPPriestDisciplineSaved[2] = {}
            MPResetPriestDisciplineSettings(2)
        end

        -- 第三套配置
        if not MPPriestDisciplineSaved[3] then
            MPPriestDisciplineSaved[3] = {}
            MPResetPriestDisciplineSettings(3)
        end
    end

    if MPPriestDisciplineSaved.Version ~= PriestDisciplineSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[戒律牧宏]当前配置，这是新版插件正常数据更新！|r")
        MPPriestDisciplineSaved[1] = {}
        MPPriestDisciplineSaved[2] = {}
        MPPriestDisciplineSaved[3] = {}
        MPResetPriestDisciplineSettings(1)
        MPResetPriestDisciplineSettings(2)
        MPResetPriestDisciplineSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)


    checkButton_HolyFire:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].HolyFire))
    checkButton_InnerFire:SetChecked( MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].InnerFire) )
    checkButton_Pain:SetChecked( MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Pain) )
    checkButton_Smite:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Smite))
    checkButton_Chastise:SetChecked( MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Chastise) )

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Target))

    checkButton_ChastiseMyself:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].ChastiseMyself))
    checkButton_InspireMyself:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].InspireMyself))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value)
    if MPPriestDisciplineSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestDisciplineSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestDisciplineSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPriestDisciplineSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value)
    if MPPriestDisciplineSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPriestDisciplineSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    --slider_Fade_Value:SetValue(MPPriestDisciplineSaved[ConfigCurrent].Fade_Value)

    checkButton_Power:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPriestDisciplineSaved[ConfigCurrent].Pick))

end

