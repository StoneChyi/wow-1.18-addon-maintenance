
-- 定义插件名称
local ADDON_NAME = "Settings-Rogue"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPRogueSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsRogue = MPCreateFrame(ADDON_NAME.."Frame", 520, 790, "|cFFFFF569设置 - 盗贼 自配置|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40


local CB_SliceDiceTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_SliceDiceTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+12)
CB_SliceDiceTipText:SetWidth(250)
CB_SliceDiceTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_SliceDiceTipText:SetTextColor(1, 0.8, 0)
CB_SliceDiceTipText:SetJustifyH("LEFT")
CB_SliceDiceTipText:SetText("肾击")


-- 创建单选框 - 肾击
local CB_KidneyStrike = {}
CB_KidneyStrike[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_KidneyStrike[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_KidneyStrike[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_KidneyStrike[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_KidneyStrike[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_KidneyStrike[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_KidneyStrike[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_KidneyStrike[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_KidneyStrike[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_KidneyStrike[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].KidneyStrikeStar[5] = 0
    end
end)




-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsRogue, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")





postion_y = postion_y-30


postion_y = postion_y-5
local CB_EnvenomTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_EnvenomTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+19)
CB_EnvenomTipText:SetWidth(250)
CB_EnvenomTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_EnvenomTipText:SetTextColor(1, 0.8, 0)
CB_EnvenomTipText:SetJustifyH("LEFT")
CB_EnvenomTipText:SetText("切割")

-- 创建单选框 - 切割
local CB_SliceDice = {}
CB_SliceDice[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_SliceDice[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SliceDiceStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].SliceDiceStar[1] = 0
    end
end)
-- 创建单选框 - 切割2星
CB_SliceDice[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_SliceDice[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SliceDiceStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].SliceDiceStar[2] = 0
    end
end)
-- 创建单选框 - 切割3星
CB_SliceDice[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_SliceDice[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SliceDiceStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].SliceDiceStar[3] = 0
    end
end)
-- 创建单选框 - 切割4星
CB_SliceDice[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_SliceDice[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SliceDiceStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].SliceDiceStar[4] = 0
    end
end)
-- 创建单选框 - 切割5星
CB_SliceDice[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_SliceDice[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SliceDiceStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].SliceDiceStar[5] = 0
    end
end)

postion_y = postion_y+5

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsRogue, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")



postion_y = postion_y-30



postion_y = postion_y-5
local CB_BloodyTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_BloodyTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+24)
CB_BloodyTipText:SetWidth(250)
CB_BloodyTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_BloodyTipText:SetTextColor(1, 0.8, 0)
CB_BloodyTipText:SetJustifyH("LEFT")
CB_BloodyTipText:SetText("毒伤")


-- 创建单选框 - 毒伤
local CB_Envenom = {}
CB_Envenom[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_Envenom[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EnvenomStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].EnvenomStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_Envenom[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_Envenom[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EnvenomStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].EnvenomStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_Envenom[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_Envenom[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EnvenomStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].EnvenomStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_Envenom[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_Envenom[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EnvenomStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].EnvenomStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_Envenom[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_Envenom[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EnvenomStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].EnvenomStar[5] = 0
    end
end)

postion_y = postion_y+5




-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")



postion_y = postion_y-30


postion_y = postion_y-5
local CB_ExposeArmorTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_ExposeArmorTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+30)
CB_ExposeArmorTipText:SetWidth(250)
CB_ExposeArmorTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_ExposeArmorTipText:SetTextColor(1, 0.8, 0)
CB_ExposeArmorTipText:SetJustifyH("LEFT")
CB_ExposeArmorTipText:SetText("割裂")

-- 创建单选框 - 割裂
local CB_Bloody = {}
CB_Bloody[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_Bloody[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BloodyStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].BloodyStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_Bloody[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_Bloody[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BloodyStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].BloodyStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_Bloody[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_Bloody[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BloodyStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].BloodyStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_Bloody[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_Bloody[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BloodyStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].BloodyStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_Bloody[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_Bloody[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BloodyStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].BloodyStar[5] = 0
    end
end)

postion_y = postion_y+5


-- 创建单选框 - 潜行
local checkButton_Stealth = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "潜行时自动 伏击/绞喉")
MPBindConfigCheckButton(checkButton_Stealth, GetCurrentSaved, "Stealth")



postion_y = postion_y-30


postion_y = postion_y-5
local CB_AdrenalineTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_AdrenalineTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+35)
CB_AdrenalineTipText:SetWidth(250)
CB_AdrenalineTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_AdrenalineTipText:SetTextColor(1, 0.8, 0)
CB_AdrenalineTipText:SetJustifyH("LEFT")
CB_AdrenalineTipText:SetText("破甲")

-- 创建单选框 - 破甲
local CB_ExposeArmor = {}
CB_ExposeArmor[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_ExposeArmor[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_ExposeArmor[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_ExposeArmor[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_ExposeArmor[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_ExposeArmor[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_ExposeArmor[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_ExposeArmor[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_ExposeArmor[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_ExposeArmor[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].ExposeArmorStar[5] = 0
    end
end)

postion_y = postion_y+5


-- 创建单选框 - 还击
local checkButton_Riposte = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "启用 还击")
MPBindConfigCheckButton(checkButton_Riposte, GetCurrentSaved, "Riposte")



postion_y = postion_y-30


postion_y = postion_y-5
local CB_EviscerateTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_EviscerateTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+42)
CB_EviscerateTipText:SetWidth(250)
CB_EviscerateTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_EviscerateTipText:SetTextColor(1, 0.8, 0)
CB_EviscerateTipText:SetJustifyH("LEFT")
CB_EviscerateTipText:SetText("兴奋")

-- 创建单选框 - 兴奋
local CB_Adrenaline = {}
CB_Adrenaline[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_Adrenaline[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].AdrenalineStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].AdrenalineStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_Adrenaline[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_Adrenaline[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].AdrenalineStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].AdrenalineStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_Adrenaline[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_Adrenaline[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].AdrenalineStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].AdrenalineStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_Adrenaline[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_Adrenaline[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].AdrenalineStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].AdrenalineStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_Adrenaline[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_Adrenaline[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].AdrenalineStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].AdrenalineStar[5] = 0
    end
end)

postion_y = postion_y+5


-- 创建单选框 - 鬼魅攻击
local checkButton_GhostlyStrike = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "启用 鬼魅攻击")
MPBindConfigCheckButton(checkButton_GhostlyStrike, GetCurrentSaved, "GhostlyStrike")



postion_y = postion_y-30


postion_y = postion_y-5
local CB_KidneyStrikeTipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
CB_KidneyStrikeTipText:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+48)
CB_KidneyStrikeTipText:SetWidth(250)
CB_KidneyStrikeTipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
CB_KidneyStrikeTipText:SetTextColor(1, 0.8, 0)
CB_KidneyStrikeTipText:SetJustifyH("LEFT")
CB_KidneyStrikeTipText:SetText("剔骨")

-- 创建单选框 - 剔骨
local CB_Eviscerate = {}
CB_Eviscerate[1] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 60, postion_y, "1")
CB_Eviscerate[1]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EviscerateStar[1] = 1
    else
        MPRogueSaved[ConfigCurrent].EviscerateStar[1] = 0
    end
end)
-- 创建单选框 - 2星
CB_Eviscerate[2] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 110, postion_y, "2")
CB_Eviscerate[2]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EviscerateStar[2] = 1
    else
        MPRogueSaved[ConfigCurrent].EviscerateStar[2] = 0
    end
end)
-- 创建单选框 - 3星
CB_Eviscerate[3] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 160, postion_y, "3")
CB_Eviscerate[3]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EviscerateStar[3] = 1
    else
        MPRogueSaved[ConfigCurrent].EviscerateStar[3] = 0
    end
end)
-- 创建单选框 - 4星
CB_Eviscerate[4] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 210, postion_y, "4")
CB_Eviscerate[4]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EviscerateStar[4] = 1
    else
        MPRogueSaved[ConfigCurrent].EviscerateStar[4] = 0
    end
end)
-- 创建单选框 - 5星
CB_Eviscerate[5] = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 260, postion_y, "5")
CB_Eviscerate[5]:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].EviscerateStar[5] = 1
    else
        MPRogueSaved[ConfigCurrent].EviscerateStar[5] = 0
    end
end)

postion_y = postion_y+5


-- 创建单选框 - 突袭
local checkButton_SurpriseStrike = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "启用 突袭")
MPBindConfigCheckButton(checkButton_SurpriseStrike, GetCurrentSaved, "SurpriseStrike")


postion_y = postion_y-30

-- 创建单选框 - 佯攻
local checkButton_Feint = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "启用 佯攻 (内置仇恨判断)")
MPBindConfigCheckButton(checkButton_Feint, GetCurrentSaved, "Feint")








-- 主技能


postion_y = postion_y+20

-- 添加提示内容区域
local TipText1 = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText("主技能配置(单选)")


postion_y = postion_y-90

-- 创建单选框 - 邪恶攻击
local checkButton_Sinister = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "邪恶攻击")

-- 创建单选框 - 双刃毒袭
local checkButton_Poison = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 175, postion_y, "双刃毒袭")

-- 创建单选框 - 出血
local checkButton_Hemo = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 330, postion_y, "出血")

-- 创建单选框 - 背刺
local checkButton_Backstab = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 485, postion_y, "背刺")


-- 邪恶攻击点击事件
checkButton_Sinister:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].Sinister = 1
        MPRogueSaved[ConfigCurrent].Poison = 0
        MPRogueSaved[ConfigCurrent].Hemo = 0
        MPRogueSaved[ConfigCurrent].Backstab = 0
    else
        MPRogueSaved[ConfigCurrent].Sinister = 0
    end
    checkButton_Sinister:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Sinister))
    checkButton_Poison:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Poison))
    checkButton_Hemo:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Hemo))
    checkButton_Backstab:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Backstab))
end)

-- 双刃毒袭点击事件
checkButton_Poison:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].Sinister = 0
        MPRogueSaved[ConfigCurrent].Poison = 1
        MPRogueSaved[ConfigCurrent].Hemo = 0
        MPRogueSaved[ConfigCurrent].Backstab = 0
    else
        MPRogueSaved[ConfigCurrent].Poison = 0
    end
    checkButton_Sinister:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Sinister))
    checkButton_Poison:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Poison))
    checkButton_Hemo:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Hemo))
    checkButton_Backstab:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Backstab))
end)

-- 出血点击事件
checkButton_Hemo:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].Sinister = 0
        MPRogueSaved[ConfigCurrent].Poison = 0
        MPRogueSaved[ConfigCurrent].Hemo = 1
        MPRogueSaved[ConfigCurrent].Backstab = 0
    else
        MPRogueSaved[ConfigCurrent].Hemo = 0
    end
    checkButton_Sinister:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Sinister))
    checkButton_Poison:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Poison))
    checkButton_Hemo:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Hemo))
    checkButton_Backstab:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Backstab))
end)

-- 背刺点击事件
checkButton_Backstab:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].Sinister = 0
        MPRogueSaved[ConfigCurrent].Poison = 0
        MPRogueSaved[ConfigCurrent].Hemo = 0
        MPRogueSaved[ConfigCurrent].Backstab = 1
    else
        MPRogueSaved[ConfigCurrent].Backstab = 0
    end
    checkButton_Sinister:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Sinister))
    checkButton_Poison:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Poison))
    checkButton_Hemo:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Hemo))
    checkButton_Backstab:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Backstab))
end)







-- 毒药


postion_y = postion_y+30

-- 添加提示内容区域
local TipText1 = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(450)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText("毒药配置")




postion_y = postion_y-105

-- 主手
local checkButton_MainHand = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "主手")
MPBindConfigCheckButton(checkButton_MainHand, GetCurrentSaved, "MainHand")

-- 定义选项（带固定索引的表）
local modes_MainHand = {
    [1] = {text = "溶解毒药 II", value = 1},
    [2] = {text = "速效毒药 VI", value = 2},
    [3] = {text = "腐蚀毒药 II", value = 3},
    [4] = {text = "致命毒药 V",   value = 4},
    [5] = {text = "致命毒药 IV",   value = 5},
    [6] = {text = "麻痹毒药 III",   value = 6},
    [7] = {text = "致残毒药 II",   value = 7},
    [8] = {text = "致伤毒药",   value = 8},
}

-- 创建下拉菜单
local dropdown_MainHand = CreateFrame("Button", ADDON_NAME.."Dropdown_MainHand", checkButton_MainHand, "UIDropDownMenuTemplate")
dropdown_MainHand:SetPoint("TOPLEFT", checkButton_MainHand, "TOPLEFT", 80, 0)

-- 菜单初始化
local function Dropdown_Init_MainHand()
    for idx, data in pairs(modes_MainHand) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_MainHand, index)
                MPRogueSaved[ConfigCurrent].MainHand_Value = modes_MainHand[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_MainHand, Dropdown_Init_MainHand)
UIDropDownMenu_SetSelectedID(dropdown_MainHand, 1) -- 默认选中第一项


-- 主手毒药次数
local slider_MainHandCount = MPCreateConfigSlider(ADDON_NAME.."Slider_MainHandCount", CatUISettingsRogue, "TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y+30, 220, 16, 1, 100, 1, 50)

-- 值变化时的回调函数
slider_MainHandCount:SetScript("OnValueChanged", function()
    MPRogueSaved[ConfigCurrent].MainHandCount = arg1
    _G[slider_MainHandCount:GetName().."Text"]:SetText("主手毒药次数 <"..arg1.." 补充")
end)



-- 副手
local checkButton_OffHand = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "副手")
MPBindConfigCheckButton(checkButton_OffHand, GetCurrentSaved, "OffHand")

-- 定义选项（带固定索引的表）
local modes_OffHand = {
    [1] = {text = "溶解毒药 II", value = 1},
    [2] = {text = "速效毒药 VI", value = 2},
    [3] = {text = "腐蚀毒药 II", value = 3},
    [4] = {text = "致命毒药 V",   value = 4},
    [5] = {text = "致命毒药 IV",   value = 5},
    [6] = {text = "麻痹毒药 III",   value = 6},
    [7] = {text = "致残毒药 II",   value = 7},
    [8] = {text = "致伤毒药",   value = 8},
}

-- 创建下拉菜单
local dropdown_OffHand = CreateFrame("Button", ADDON_NAME.."Dropdown_OffHand", checkButton_OffHand, "UIDropDownMenuTemplate")
dropdown_OffHand:SetPoint("TOPLEFT", checkButton_OffHand, "TOPLEFT", 80, 0)

-- 菜单初始化
local function Dropdown_Init_OffHand()
    for idx, data in pairs(modes_OffHand) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_OffHand, index)
                MPRogueSaved[ConfigCurrent].OffHand_Value = modes_OffHand[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_OffHand, Dropdown_Init_OffHand)
UIDropDownMenu_SetSelectedID(dropdown_OffHand, 1) -- 默认选中第一项

-- 副手毒药次数
local slider_OffHandCount = MPCreateConfigSlider(ADDON_NAME.."Slider_OffHandCount", CatUISettingsRogue, "TOPLEFT", CatUISettingsRogue, "TOPLEFT", 275, postion_y+30, 220, 16, 1, 100, 1, 50)

-- 值变化时的回调函数
slider_OffHandCount:SetScript("OnValueChanged", function()
    MPRogueSaved[ConfigCurrent].OffHandCount = arg1
    _G[slider_OffHandCount:GetName().."Text"]:SetText("副手毒药次数 <"..arg1.." 补充")
end)


postion_y = postion_y-100

-- 脱战上毒
local checkButton_LeaveFight = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "补毒药 仅在脱离战斗时")
MPBindConfigCheckButton(checkButton_LeaveFight, GetCurrentSaved, "LeaveFight")


-- 覆盖旧毒药
local checkButton_Cover = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "覆盖原武器上不同的毒药")
MPBindConfigCheckButton(checkButton_Cover, GetCurrentSaved, "Cover")


postion_y = postion_y-40

-- 四武器双毒切换功能
local checkButton_SwitchWeapon = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "|cFFFFF569四武器双毒切换功能|r")
checkButton_SwitchWeapon:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].SwitchWeapon = 1
        print("启动|cFFFFF569四武器双毒切换功能|r 目前仅支持双速效毒药和双溶解毒药的切换，除了手上的两把武器，包里要预备好两把已经上好毒的武器。")
    else
        MPRogueSaved[ConfigCurrent].SwitchWeapon = 0
    end
end)





-- 高级

postion_y = postion_y+80

-- 添加提示内容区域
local TipText1 = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsRogue, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-155

-- 创建单选框 - 剑刃乱舞
local checkButton_BladeFlurry = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "自动 剑刃乱舞")
local slider_BladeFlurry_Value = MPCreateConfigSlider(ADDON_NAME.."Slider_BladeFlurry_Value", checkButton_BladeFlurry, "RIGHT", checkButton_BladeFlurry, "RIGHT", 260, -2, 150, 16, 5, 20, 1, 8)

local color_BladeFlurry = "|cFFFFD100"

-- 值变化时的回调函数
slider_BladeFlurry_Value:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPRogueSaved[ConfigCurrent].BladeFlurry_Value = arg1
    _G[slider_BladeFlurry_Value:GetName().."Text"]:SetText(color_BladeFlurry.."感应范围".. MPRogueSaved[ConfigCurrent].BladeFlurry_Value .."码|r")
end)

-- 设置点击事件
checkButton_BladeFlurry:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].BladeFlurry = 1
        color_BladeFlurry = "|cFFFFD100"
        _G[slider_BladeFlurry_Value:GetName().."Text"]:SetText(color_BladeFlurry.."感应范围".. MPRogueSaved[ConfigCurrent].BladeFlurry_Value .."码|r")
    else
        MPRogueSaved[ConfigCurrent].BladeFlurry = 0
        color_BladeFlurry = "|cFF888888"
        _G[slider_BladeFlurry_Value:GetName().."Text"]:SetText(color_BladeFlurry.."感应范围".. MPRogueSaved[ConfigCurrent].BladeFlurry_Value .."码|r")
    end
end)


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPRogueSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPRogueSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - buff时间
local checkButton_LeftTime = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "提前保持Buff\n(SuperWoW)")

local slider_LeftTime = MPCreateConfigSlider(ADDON_NAME.."Slider_SliceDiceTime", checkButton_LeftTime, "RIGHT", checkButton_LeftTime, "RIGHT", 260, -2, 150, 16, 0, 10, 1, 100)

local color_LeftTime = "|cFFFFD100"

-- 值变化时的回调函数
slider_LeftTime:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPRogueSaved[ConfigCurrent].LeftTime_Value = arg1
    _G[slider_LeftTime:GetName().."Text"]:SetText(color_LeftTime.."提前 ".. MPRogueSaved[ConfigCurrent].LeftTime_Value .." 秒|r")
end)

-- 设置点击事件
checkButton_LeftTime:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].LeftTime = 1
        color_LeftTime = "|cFFFFD100"
        _G[slider_LeftTime:GetName().."Text"]:SetText(color_LeftTime.."提前 ".. MPRogueSaved[ConfigCurrent].LeftTime_Value .." 秒|r")
    else
        MPRogueSaved[ConfigCurrent].LeftTime = 0
        color_LeftTime = "|cFF888888"
        _G[slider_LeftTime:GetName().."Text"]:SetText(color_LeftTime.."提前 ".. MPRogueSaved[ConfigCurrent].LeftTime_Value .." 秒|r")
    end
end)



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPRogueSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPRogueSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y-40

-- 创建单选框 - 背刺 改 邪恶
local checkButton_SinisterStrike = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "背刺 不可用时启用 邪恶攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SinisterStrike, GetCurrentSaved, "SinisterStrike")



-- 创建单选框 - 鞭根块茎
local checkButton_Carrot = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动 鞭根块茎")

local slider_Carrot = MPCreateConfigSlider(ADDON_NAME.."Slider_Carrot", checkButton_Carrot, "RIGHT", checkButton_Carrot, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Carrot = "|cFFFFD100"

-- 值变化时的回调函数
slider_Carrot:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPRogueSaved[ConfigCurrent].Carrot_Value = arg1
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueSaved[ConfigCurrent].Carrot_Value .."%|r")
end)

-- 设置点击事件
checkButton_Carrot:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueSaved[ConfigCurrent].Carrot = 1
        color_Carrot = "|cFFFFD100"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueSaved[ConfigCurrent].Carrot_Value .."%|r")
    else
        MPRogueSaved[ConfigCurrent].Carrot = 0
        color_Carrot = "|cFF888888"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueSaved[ConfigCurrent].Carrot_Value .."%|r")
    end
end)





postion_y = postion_y-40

-- 创建单选框 - 保护剑刃乱舞
local checkButton_Protect = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "保护剑刃乱舞 自动取消无用Buff")
MPBindConfigCheckButton(checkButton_Protect, GetCurrentSaved, "Protect")



-- 创建单选框 - 自动打断
local checkButton_Interrupt = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动 打断读条 (SuperWoW)")
MPBindConfigCheckButton(checkButton_Interrupt, GetCurrentSaved, "Interrupt")



postion_y = postion_y-40

-- 创建单选框 - 冲动
local checkButton_Impulse = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 20, postion_y, "自动 冲动/冷血")
MPBindConfigCheckButton(checkButton_Impulse, GetCurrentSaved, "Impulse")
local checkButton_ImpulseBoss = MPCreateCheckButtonSmall(CatUISettingsRogue, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_ImpulseBoss, GetCurrentSaved, "ImpulseBoss")


-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsRogue, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")


postion_y = postion_y-40



-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsRogue, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsRogue, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsRogue, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetRogueSettings(ConfigCurrent)
    MPInitRogueSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsRogue, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitRogueSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsRogue, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsRogue:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsRogue, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFFF569/rdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local RogueSettingsUIVersion = 32

function MPResetRogueSettings(config)

    MPRogueSaved.Version = RogueSettingsUIVersion

    -- 基本配置

    MPRogueSaved[config].Trinket_Upper = 1
    MPRogueSaved[config].TUBoss = 0
    MPRogueSaved[config].Trinket_Below = 1
    MPRogueSaved[config].TBBoss = 0
    MPRogueSaved[config].Target = 0

    MPRogueSaved[config].SliceDice = 1
    MPRogueSaved[config].Bloody = 1
    MPRogueSaved[config].Eviscerate = 1
    MPRogueSaved[config].Envenom = 1
    MPRogueSaved[config].ExposeArmor = 0
    MPRogueSaved[config].Adrenaline = 0

    MPRogueSaved[config].SurpriseStrike = 0
    MPRogueSaved[config].GhostlyStrike = 0
    MPRogueSaved[config].Stealth = 1
    MPRogueSaved[config].Hemorrhage = 0
    MPRogueSaved[config].Riposte = 0
    MPRogueSaved[config].Feint = 0

    MPRogueSaved[config].Sinister = 1
    MPRogueSaved[config].Poison = 0
    MPRogueSaved[config].Hemo = 0
    MPRogueSaved[config].Backstab = 0


    -- 毒药
    MPRogueSaved[config].MainHand = 0
    MPRogueSaved[config].OffHand = 0
    MPRogueSaved[config].MainHand_Value = "溶解毒药 II"
    MPRogueSaved[config].OffHand_Value = "溶解毒药 II"
    MPRogueSaved[config].MainHandCount = 50
    MPRogueSaved[config].OffHandCount = 50
    MPRogueSaved[config].LeaveFight = 0
    MPRogueSaved[config].Cover = 0

    MPRogueSaved[config].SwitchWeapon = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPRogueSaved[config].HealthStone = 1
    MPRogueSaved[config].HealthStone_Value = 30
    MPRogueSaved[config].HerbalTea = 1
    MPRogueSaved[config].HerbalTea_Value = 20
    MPRogueSaved[config].Carrot = 0
    MPRogueSaved[config].Carrot_Value = 20

    -- SuperWoW,UnitXP
    MPRogueSaved[config].SuperWoW = 1
    MPRogueSaved[config].UnitXP = 0


    -- 星星

    MPRogueSaved[config].SliceDiceStar = {}
    MPRogueSaved[config].SliceDiceStar[1] = 1
    MPRogueSaved[config].SliceDiceStar[2] = 1
    MPRogueSaved[config].SliceDiceStar[3] = 0
    MPRogueSaved[config].SliceDiceStar[4] = 0
    MPRogueSaved[config].SliceDiceStar[5] = 0

    MPRogueSaved[config].EnvenomStar = {}
    MPRogueSaved[config].EnvenomStar[1] = 1
    MPRogueSaved[config].EnvenomStar[2] = 1
    MPRogueSaved[config].EnvenomStar[3] = 0
    MPRogueSaved[config].EnvenomStar[4] = 0
    MPRogueSaved[config].EnvenomStar[5] = 0

    MPRogueSaved[config].BloodyStar = {}
    MPRogueSaved[config].BloodyStar[1] = 0
    MPRogueSaved[config].BloodyStar[2] = 0
    MPRogueSaved[config].BloodyStar[3] = 0
    MPRogueSaved[config].BloodyStar[4] = 0
    MPRogueSaved[config].BloodyStar[5] = 1

    MPRogueSaved[config].EviscerateStar = {}
    MPRogueSaved[config].EviscerateStar[1] = 0
    MPRogueSaved[config].EviscerateStar[2] = 0
    MPRogueSaved[config].EviscerateStar[3] = 0
    MPRogueSaved[config].EviscerateStar[4] = 1
    MPRogueSaved[config].EviscerateStar[5] = 1

    MPRogueSaved[config].ExposeArmorStar = {}
    MPRogueSaved[config].ExposeArmorStar[1] = 0
    MPRogueSaved[config].ExposeArmorStar[2] = 0
    MPRogueSaved[config].ExposeArmorStar[3] = 0
    MPRogueSaved[config].ExposeArmorStar[4] = 0
    MPRogueSaved[config].ExposeArmorStar[5] = 0

    MPRogueSaved[config].AdrenalineStar = {}
    MPRogueSaved[config].AdrenalineStar[1] = 0
    MPRogueSaved[config].AdrenalineStar[2] = 0
    MPRogueSaved[config].AdrenalineStar[3] = 0
    MPRogueSaved[config].AdrenalineStar[4] = 0
    MPRogueSaved[config].AdrenalineStar[5] = 0

    MPRogueSaved[config].KidneyStrikeStar = {}
    MPRogueSaved[config].KidneyStrikeStar[1] = 0
    MPRogueSaved[config].KidneyStrikeStar[2] = 0
    MPRogueSaved[config].KidneyStrikeStar[3] = 0
    MPRogueSaved[config].KidneyStrikeStar[4] = 0
    MPRogueSaved[config].KidneyStrikeStar[5] = 0


    MPRogueSaved[config].Interrupt = 0
    MPRogueSaved[config].RacialTraits = 0
    MPRogueSaved[config].RacialTraitsBoss = 1
    MPRogueSaved[config].Soulspeed = 0
    MPRogueSaved[config].SoulspeedBoss = 1

    MPRogueSaved[config].LeftTime = 1
    MPRogueSaved[config].LeftTime_Value = 2

    MPRogueSaved[config].BladeFlurry = 0
    MPRogueSaved[config].BladeFlurry_Value = 10
    MPRogueSaved[config].Protect = 0
    MPRogueSaved[config].Impulse = 0
    MPRogueSaved[config].ImpulseBoss = 1

    MPRogueSaved[config].SinisterStrike = 1

    -- 通用
    MPRogueSaved[config].Power = 0
    MPRogueSaved[config].Pick = 0

end


local function InitRogueSettingsPart1()

    checkButton_Riposte:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Riposte))
    checkButton_SurpriseStrike:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].SurpriseStrike))
    checkButton_GhostlyStrike:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].GhostlyStrike))
    checkButton_Stealth:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Stealth))

    checkButton_Sinister:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Sinister))
    checkButton_Poison:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Poison))
    checkButton_Hemo:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Hemo))
    checkButton_Backstab:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Backstab))
    checkButton_Feint:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Feint))

    checkButton_Target:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Target))
    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].TBBoss))
    --checkButton_UnitXP:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].UnitXP))

    checkButton_Interrupt:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Interrupt))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_Protect:SetChecked(MPRogueSaved[ConfigCurrent].Protect)
    checkButton_Impulse:SetChecked(MPRogueSaved[ConfigCurrent].Impulse)
    checkButton_ImpulseBoss:SetChecked(MPRogueSaved[ConfigCurrent].ImpulseBoss)
    checkButton_SinisterStrike:SetChecked(MPRogueSaved[ConfigCurrent].SinisterStrike)

    checkButton_LeaveFight:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].LeaveFight))
    checkButton_Cover:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Cover))
    checkButton_SwitchWeapon:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].SwitchWeapon))

    checkButton_Power:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].Pick))
end

local function InitRogueSettingsPart2()

    for i = 1, 5, 1 do
        CB_SliceDice[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].SliceDiceStar[i]))
        CB_Envenom[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].EnvenomStar[i]))
        CB_Bloody[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].BloodyStar[i]))
        CB_Eviscerate[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].EviscerateStar[i]))
        CB_ExposeArmor[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].ExposeArmorStar[i]))
        CB_Adrenaline[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].AdrenalineStar[i]))
        CB_KidneyStrike[i]:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].KidneyStrikeStar[i]))
    end

end

function MPInitRogueSettings()
    if not MPRogueSaved then
        MPRogueSaved = {}

        -- 第一套配置
        if not MPRogueSaved[1] then
            MPRogueSaved[1] = {}
            MPResetRogueSettings(1)
        end

        -- 第二套配置
        if not MPRogueSaved[2] then
            MPRogueSaved[2] = {}
            MPResetRogueSettings(2)
        end

        -- 第三套配置
        if not MPRogueSaved[3] then
            MPRogueSaved[3] = {}
            MPResetRogueSettings(3)
        end
    end

    if MPRogueSaved.Version ~= RogueSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[自配置贼宏]当前配置，这是新版插件正常数据更新！|r")
        MPRogueSaved[1] = {}
        MPRogueSaved[2] = {}
        MPRogueSaved[3] = {}
        MPResetRogueSettings(1)
        MPResetRogueSettings(2)
        MPResetRogueSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitRogueSettingsPart1()
    InitRogueSettingsPart2()


    checkButton_HealthStone:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPRogueSaved[ConfigCurrent].HealthStone_Value)
    if MPRogueSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueSaved[ConfigCurrent].HealthStone_Value .."%|r")



    checkButton_HerbalTea:SetChecked(MPRogueSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPRogueSaved[ConfigCurrent].HerbalTea_Value)
    if MPRogueSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueSaved[ConfigCurrent].HerbalTea_Value .."%|r")


    checkButton_Carrot:SetChecked(MPRogueSaved[ConfigCurrent].Carrot)
    slider_Carrot:SetValue(MPRogueSaved[ConfigCurrent].Carrot_Value)
    if MPRogueSaved[ConfigCurrent].Carrot==1 then
        color_Carrot = "|cFFFFD100"
    else
        color_Carrot = "|cFF888888"
    end
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueSaved[ConfigCurrent].Carrot_Value .."%|r")


    checkButton_BladeFlurry:SetChecked(MPRogueSaved[ConfigCurrent].BladeFlurry)
    slider_BladeFlurry_Value:SetValue(MPRogueSaved[ConfigCurrent].BladeFlurry_Value)
    if MPRogueSaved[ConfigCurrent].BladeFlurry==1 then
        color_BladeFlurry = "|cFFFFD100"
    else
        color_BladeFlurry = "|cFF888888"
    end
    _G[slider_BladeFlurry_Value:GetName().."Text"]:SetText(color_BladeFlurry.."感应范围".. MPRogueSaved[ConfigCurrent].BladeFlurry_Value .."码|r")



    checkButton_LeftTime:SetChecked(MPRogueSaved[ConfigCurrent].LeftTime)
    slider_LeftTime:SetValue(MPRogueSaved[ConfigCurrent].LeftTime_Value)
    if MPRogueSaved[ConfigCurrent].LeftTime==1 then
        color_LeftTime = "|cFFFFD100"
    else
        color_LeftTime = "|cFF888888"
    end
    _G[slider_LeftTime:GetName().."Text"]:SetText(color_LeftTime.."提前 ".. MPRogueSaved[ConfigCurrent].LeftTime_Value .." 秒|r")



    checkButton_MainHand:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].MainHand))
    for idx_MainHand, data_MainHand in pairs(modes_MainHand) do
        if string.find(data_MainHand.text, MPRogueSaved[ConfigCurrent].MainHand_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_MainHand, data_MainHand.value)
            _G[dropdown_MainHand:GetName().."Text"]:SetText(data_MainHand.text)
        end
    end

    checkButton_OffHand:SetChecked(MPToBoolean(MPRogueSaved[ConfigCurrent].OffHand))
    for idx_OffHand, data_OffHand in pairs(modes_OffHand) do
        if string.find(data_OffHand.text, MPRogueSaved[ConfigCurrent].OffHand_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_OffHand, data_OffHand.value)
            _G[dropdown_OffHand:GetName().."Text"]:SetText(data_OffHand.text)
        end
    end

    slider_MainHandCount:SetValue(MPRogueSaved[ConfigCurrent].MainHandCount)
    _G[slider_MainHandCount:GetName().."Text"]:SetText("主手毒药次数 <"..MPRogueSaved[ConfigCurrent].MainHandCount.." 补充")
    slider_OffHandCount:SetValue(MPRogueSaved[ConfigCurrent].OffHandCount)
    _G[slider_OffHandCount:GetName().."Text"]:SetText("副手毒药次数 <"..MPRogueSaved[ConfigCurrent].OffHandCount.." 补充")

end

