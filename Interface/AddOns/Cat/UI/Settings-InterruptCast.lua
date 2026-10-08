-- 定义插件名称
local ADDON_NAME = "Settings-Interrupt"


-- 创建主框架
CatUISettingsInterrupt = MPCreateFrame(ADDON_NAME.."Frame", 520, 280, "|cFFDD4080"..MPLanguage.UI_Set_InterruptTitle.."|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsInterrupt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsInterrupt, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)




local postion_y = postion_y-40

-- 创建单选框 - 战士
local checkButton_Warrior = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarriorInterrupt)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Warrior, function() return MPInterruptCastSaved end, "Warrior")


-- 创建单选框 - 法师
local checkButton_Mage = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_MageInterrupt)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Mage, function() return MPInterruptCastSaved end, "Mage")




postion_y = postion_y-30

-- 创建单选框 - 盗贼
local checkButton_Rogue = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_RogueInterrupt)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Rogue, function() return MPInterruptCastSaved end, "Rogue")



-- 创建单选框 - 萨满
local checkButton_Shaman = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_ShamanInterrupt)

local slider_Shaman = MPCreateConfigSlider(ADDON_NAME.."Slider_Shaman", checkButton_Shaman, "RIGHT", checkButton_Shaman, "RIGHT", 265, -2, 100, 16, 1, 7, 1, 1)

local color_Shaman = "|cFFFFD100"

-- 值变化时的回调函数
slider_Shaman:SetScript("OnValueChanged", function()
    MPInterruptCastSaved.Shaman_Value = arg1
    _G[slider_Shaman:GetName().."Text"]:SetText(color_Shaman..MPLanguage.UI_Set_LevelLabel.. MPInterruptCastSaved.Shaman_Value .."|r")
end)

-- 设置点击事件
checkButton_Shaman:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPInterruptCastSaved.Shaman = 1
        color_Shaman = "|cFFFFD100"
        _G[slider_Shaman:GetName().."Text"]:SetText(color_Shaman..MPLanguage.UI_Set_LevelLabel.. MPInterruptCastSaved.Shaman_Value .."|r")
    else
        MPInterruptCastSaved.Shaman = 0
        color_Shaman = "|cFF888888"
        _G[slider_Shaman:GetName().."Text"]:SetText(color_Shaman..MPLanguage.UI_Set_LevelLabel.. MPInterruptCastSaved.Shaman_Value .."|r")
    end
end)


postion_y = postion_y-30



-- 创建单选框 - 术士
local checkButton_Warlock = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_WarlockInterrupt)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Warlock, function() return MPInterruptCastSaved end, "Warlock")



-- 创建单选框 - 牧师
local checkButton_Priest = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 340, postion_y, MPLanguage.UI_Set_PriestInterrupt)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Priest, function() return MPInterruptCastSaved end, "Priest")



postion_y = postion_y-60



-- 创建单选框 - 断条
local checkButton_StopCasting = MPCreateCheckButton(CatUISettingsInterrupt, ADDON_NAME.."CheckButton", 20, postion_y, MPLanguage.UI_Set_StopOwnCast)
-- 设置点击事件
MPBindConfigCheckButton(checkButton_StopCasting, function() return MPInterruptCastSaved end, "StopCasting")


-- 添加文字标签
local checkText_SuperWoW = CatUISettingsInterrupt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
checkText_SuperWoW:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
checkText_SuperWoW:SetTextColor(1, 1, 1)
checkText_SuperWoW:SetPoint("LEFT", CatUISettingsInterrupt, "LEFT", 20, postion_y+120)
checkText_SuperWoW:SetText(MPLanguage.UI_Set_InterruptNote)



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsInterrupt, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetInterruptSettings()
    MPInitInterruptSettings()
end)


-- 添加提示内容区域
local TipText = CatUISettingsInterrupt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsInterrupt, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText(MPLanguage.UI_Set_InterruptMacroTip)



-- 配置文件版本号
local InterruptSettingsUIVersion = 4

function MPResetInterruptSettings()

    MPInterruptCastSaved.Version = InterruptSettingsUIVersion

    -- 基本配置

    MPInterruptCastSaved.Warrior = 1
    MPInterruptCastSaved.Rogue = 1
    MPInterruptCastSaved.Mage = 1
    MPInterruptCastSaved.Mage_Value = 1
    MPInterruptCastSaved.Shaman = 1
    MPInterruptCastSaved.Shaman_Value = 1
    MPInterruptCastSaved.Warlock = 1
    MPInterruptCastSaved.Priest = 1
    MPInterruptCastSaved.StopCasting = 1


end


function MPInitInterruptSettings()

    if not MPInterruptCastSaved then
        MPInterruptCastSaved = {}
        MPResetInterruptSettings()
    end

    if MPInterruptCastSaved.Version ~= InterruptSettingsUIVersion then
        MPResetInterruptSettings()
    end

    checkButton_Warrior:SetChecked(MPToBoolean(MPInterruptCastSaved.Warrior))
    checkButton_Rogue:SetChecked(MPToBoolean(MPInterruptCastSaved.Rogue))
    checkButton_Mage:SetChecked(MPToBoolean(MPInterruptCastSaved.Mage))
    checkButton_Warlock:SetChecked(MPToBoolean(MPInterruptCastSaved.Warlock))
    checkButton_Priest:SetChecked(MPToBoolean(MPInterruptCastSaved.Priest))
    checkButton_StopCasting:SetChecked(MPToBoolean(MPInterruptCastSaved.StopCasting))

    --[[
    checkButton_Mage:SetChecked(MPToBoolean(MPInterruptCastSaved.Mage))
    slider_Mage:SetValue(MPInterruptCastSaved.Mage_Value)
    if MPInterruptCastSaved.Mage==1 then
        color_Mage = "|cFFFFD100"
    else
        color_Mage = "|cFF888888"
    end
    _G[slider_Mage:GetName().."Text"]:SetText(color_Mage.."等级: ".. MPInterruptCastSaved.Mage_Value .."|r")
    ]]

    checkButton_Shaman:SetChecked(MPToBoolean(MPInterruptCastSaved.Shaman))
    slider_Shaman:SetValue(MPInterruptCastSaved.Shaman_Value)
    if MPInterruptCastSaved.Shaman==1 then
        color_Shaman = "|cFFFFD100"
    else
        color_Shaman = "|cFF888888"
    end
    _G[slider_Shaman:GetName().."Text"]:SetText(color_Shaman..MPLanguage.UI_Set_LevelLabel.. MPInterruptCastSaved.Shaman_Value .."|r")

end

