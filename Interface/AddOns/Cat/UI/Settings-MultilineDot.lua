-- 定义插件名称
local ADDON_NAME = "Settings-MultilineDot"

-- 创建主框架
CatUISettingsMultilineDot = MPCreateFrame(ADDON_NAME.."Frame", 520, 510, "|cFFDD4080"..MPLanguage.UI_Set_MultiDotTitle.."|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsMultilineDot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsMultilineDot, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)




local postion_y = postion_y-40

-- 创建单选框 - 德鲁伊 - 月火术
local checkButton_Moonfire = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_DruidMoonfire)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Moonfire, function() return MPMultilineDotSaved end, "Moonfire")


local checkButton_InsectSwarm = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_DruidInsectSwarm)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_InsectSwarm, function() return MPMultilineDotSaved end, "InsectSwarm")






postion_y = postion_y-60


-- 创建单选框 - 牧师 - 痛
local checkButton_Pain = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_PriestPain)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Pain, function() return MPMultilineDotSaved end, "Pain")




postion_y = postion_y-60

-- 创建单选框 - 术士 - 痛苦诅咒
local checkButton_CurseAgony = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockCurseAgony)


-- 创建单选框 - 术士 - 腐蚀术
local checkButton_Corruption = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_WarlockCorruption)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Corruption, function() return MPMultilineDotSaved end, "Corruption")


postion_y = postion_y-30


local checkButton_CurseDoom = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockCurseDoom)

-- 创建单选框 - 术士 - 生命虹吸
local checkButton_SiphonLife = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_WarlockSiphonLife)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SiphonLife, function() return MPMultilineDotSaved end, "SiphonLife")



postion_y = postion_y-30

-- 创建单选框 - 术士 - 鲁莽诅咒
local checkButton_CurseRecklessness = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockCurseRecklessness)

-- 创建单选框 - 术士 - 献祭
local checkButton_Immolate = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_WarlockImmolate)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Immolate, function() return MPMultilineDotSaved end, "Immolate")



postion_y = postion_y-30

-- 创建单选框 - 术士 - 元素诅咒
local checkButton_CurseElements = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockCurseElements)


postion_y = postion_y-30

-- 创建单选框 - 术士 - 暗影诅咒
local checkButton_CurseShadow = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockCurseShadow)



-- 痛苦点击事件
checkButton_CurseAgony:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMultilineDotSaved.CurseAgony = 1
        MPMultilineDotSaved.CurseDoom = 0
        MPMultilineDotSaved.CurseRecklessness = 0
        MPMultilineDotSaved.CurseElements = 0
        MPMultilineDotSaved.CurseShadow = 0
    else
        MPMultilineDotSaved.CurseAgony = 0
    end
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))
end)

-- 厄运点击事件
checkButton_CurseDoom:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMultilineDotSaved.CurseAgony = 0
        MPMultilineDotSaved.CurseDoom = 1
        MPMultilineDotSaved.CurseRecklessness = 0
        MPMultilineDotSaved.CurseElements = 0
        MPMultilineDotSaved.CurseShadow = 0
    else
        MPMultilineDotSaved.CurseDoom = 0
    end
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))

end)

-- 鲁莽诅咒点击事件
checkButton_CurseRecklessness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMultilineDotSaved.CurseAgony = 0
        MPMultilineDotSaved.CurseDoom = 0
        MPMultilineDotSaved.CurseRecklessness = 1
        MPMultilineDotSaved.CurseElements = 0
        MPMultilineDotSaved.CurseShadow = 0
    else
        MPMultilineDotSaved.CurseRecklessness = 0
    end
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))

end)

-- 元素诅咒点击事件
checkButton_CurseElements:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMultilineDotSaved.CurseAgony = 0
        MPMultilineDotSaved.CurseDoom = 0
        MPMultilineDotSaved.CurseRecklessness = 0
        MPMultilineDotSaved.CurseElements = 1
        MPMultilineDotSaved.CurseShadow = 0
    else
        MPMultilineDotSaved.CurseElements = 0
    end
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))

end)

-- 暗影诅咒点击事件
checkButton_CurseShadow:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPMultilineDotSaved.CurseAgony = 0
        MPMultilineDotSaved.CurseDoom = 0
        MPMultilineDotSaved.CurseRecklessness = 0
        MPMultilineDotSaved.CurseElements = 0
        MPMultilineDotSaved.CurseShadow = 1
    else
        MPMultilineDotSaved.CurseShadow = 0
    end
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))

end)




postion_y = postion_y+20


-- 添加提示内容区域
local TipText = CatUISettingsMultilineDot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsMultilineDot, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-105


-- 创建单选框 - 战斗中
local checkButton_InFight = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_InFightOnly)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_InFight, function() return MPMultilineDotSaved end, "InFight")

-- 创建单选框 - 忽略被硬控目标
local checkButton_NoCC = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_IgnoreCC)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_NoCC, function() return MPMultilineDotSaved end, "NoCC")


postion_y = postion_y-30



-- 创建单选框 - 忽略未进入战斗目标
local checkButton_NoCombat = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_IgnoreNotInCombat)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_NoCombat, function() return MPMultilineDotSaved end, "NoCombat")

-- 创建单选框 - 忽略玩家目标
local checkButton_NOPlayer = MPCreateCheckButton(CatUISettingsMultilineDot, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_IgnorePlayer)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_NOPlayer, function() return MPMultilineDotSaved end, "NOPlayer")


postion_y = postion_y-30


-- 血量节点
local slider_BeginValue = MPCreateConfigSlider(ADDON_NAME.."BeginValue", CatUISettingsMultilineDot, "TOPLEFT", CatUISettingsMultilineDot, "TOPLEFT", 20, postion_y+60, 220, 16, 0, 60000, 1000, 3000)

-- 值变化时的回调函数
slider_BeginValue:SetScript("OnValueChanged", function()
    MPMultilineDotSaved.BeginValue = arg1

    _G[slider_BeginValue:GetName().."Text"]:SetText(MPLanguage.UI_Set_HPAbove..MPMultilineDotSaved.BeginValue)
end)





postion_y = postion_y + 270

-- 添加文字标签
local checkText_SuperWoW = CatUISettingsMultilineDot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
checkText_SuperWoW:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
checkText_SuperWoW:SetTextColor(1, 1, 1)
checkText_SuperWoW:SetPoint("LEFT", CatUISettingsMultilineDot, "LEFT", 20, postion_y)
checkText_SuperWoW:SetText(MPLanguage.UI_Set_MultiDotNote)



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsMultilineDot, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetMultilineDotSettings()
    MPInitMultilineDotSettings()
end)


-- 添加提示内容区域
local TipText = CatUISettingsMultilineDot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsMultilineDot, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText(MPLanguage.UI_Set_MultiDotMacroTip)



-- 配置文件版本号
local MultilineDotSettingsUIVersion = 13

function MPResetMultilineDotSettings()

    MPMultilineDotSaved.Version = MultilineDotSettingsUIVersion

    -- 基本配置

    MPMultilineDotSaved.Moonfire = 1
    MPMultilineDotSaved.InsectSwarm = 0

    MPMultilineDotSaved.CurseAgony = 1
    MPMultilineDotSaved.Corruption = 1
    MPMultilineDotSaved.SiphonLife = 0
    MPMultilineDotSaved.Immolate = 0

    MPMultilineDotSaved.CurseDoom = 0
    MPMultilineDotSaved.CurseRecklessness = 0
    MPMultilineDotSaved.CurseElements = 0
    MPMultilineDotSaved.CurseShadow = 0

    MPMultilineDotSaved.Pain = 1

    MPMultilineDotSaved.InFight = 0
    MPMultilineDotSaved.ScanEnemy = 0
    MPMultilineDotSaved.NoCC = 1
    MPMultilineDotSaved.NoCombat = 1
    MPMultilineDotSaved.NOPlayer = 0

    MPMultilineDotSaved.BeginValue = 0

end




function MPInitMultilineDotSettings()

    if not MPMultilineDotSaved then
        MPMultilineDotSaved = {}
        MPResetMultilineDotSettings()
    end

    if MPMultilineDotSaved.Version ~= MultilineDotSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[打断宏]当前配置，这是新版插件正常数据更新！|r")
        MPResetMultilineDotSettings()
    end

    checkButton_Moonfire:SetChecked(MPToBoolean(MPMultilineDotSaved.Moonfire))
    checkButton_InsectSwarm:SetChecked(MPToBoolean(MPMultilineDotSaved.InsectSwarm))

    checkButton_CurseAgony:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseAgony))
    checkButton_Corruption:SetChecked(MPToBoolean(MPMultilineDotSaved.Corruption))
    checkButton_SiphonLife:SetChecked(MPToBoolean(MPMultilineDotSaved.SiphonLife))
    checkButton_Immolate:SetChecked(MPToBoolean(MPMultilineDotSaved.Immolate))

    checkButton_CurseDoom:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseDoom))
    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPMultilineDotSaved.CurseShadow))

    checkButton_Pain:SetChecked(MPToBoolean(MPMultilineDotSaved.Pain))

    checkButton_InFight:SetChecked(MPToBoolean(MPMultilineDotSaved.InFight))
    checkButton_NoCC:SetChecked(MPToBoolean(MPMultilineDotSaved.NoCC))
    checkButton_NoCombat:SetChecked(MPToBoolean(MPMultilineDotSaved.NoCombat))
    checkButton_NOPlayer:SetChecked(MPToBoolean(MPMultilineDotSaved.NOPlayer))

    slider_BeginValue:SetValue(MPMultilineDotSaved.BeginValue)
    _G[slider_BeginValue:GetName().."Text"]:SetText(MPLanguage.UI_Set_HPAbove..MPMultilineDotSaved.BeginValue)

end

