-- 定义插件名称
local ADDON_NAME = "Settings-CatMenu"


-- 创建主框架
CatUISettingsCatMenu = MPCreateFrame(ADDON_NAME.."Frame", 520, 130, MPLanguage.UI_SettingsTitle)
tinsert(UISpecialFrames, ADDON_NAME.."Frame")


local postion_y = -50



-- 添加提示内容区域
local TipText = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsCatMenu, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText(MPLanguage.UI_Set_MenuCommandVersion..MPCatAddonVer.." ]")



-- 创建扁平化按钮
local function CreateFlatButton(name, parent, width, height, text, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 90)
    button:SetHeight(height or 28)
    button:SetFont("Fonts\\FRIZQT__.TTF", 12)


    -- 设置文本
    button:SetText(text or "Button")
    
    button:SetScript("OnMouseUp", function(self)
        if onClick then onClick(this) end
    end)
    
    return button
end

local postion_x = 94
local postion_y = -10
local offset = 100
local height = 0


    postion_y = postion_y-50

    -- 添加提示内容区域
    local TipTextDruid = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextDruid:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextDruid:SetWidth(150)
    TipTextDruid:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextDruid:SetTextColor(1, 0.8, 0)
    TipTextDruid:SetJustifyH("LEFT")
    TipTextDruid:SetText(MPLanguage.UI_Druid)

    local buttonCat = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_CatDruid, function()
        MPCatSettingsCloseAll()
        --CatUISettingsCatMini:Show()
        CatUISettingsCatWindow:Show()
    end)
    buttonCat:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonBear = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_BearDruid, function()
        MPCatSettingsCloseAll()
        CatUISettingsBearWindow:Show()
    end)
    buttonBear:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonBird = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_BalanceDruid, function()
        MPCatSettingsCloseAll()
        CatUISettingsCOOWindow:Show()
    end)
    buttonBird:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)


    local buttonHeal = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_RestoDruid, function()
        MPCatSettingsCloseAll()
        CatUISettingsDruidHealWindow:Show()
    end)
    buttonHeal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)


    local lineDruid = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineDruid:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineDruid:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineDruid:SetVertexColor(0.5, 0.5, 0.5)
    lineDruid:SetWidth(460)
    lineDruid:SetHeight(3)
    lineDruid:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)



    postion_y = postion_y-50

    -- 添加提示内容区域
    local TipTextWarrior = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextWarrior:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextWarrior:SetWidth(150)
    TipTextWarrior:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextWarrior:SetTextColor(1, 0.8, 0)
    TipTextWarrior:SetJustifyH("LEFT")
    TipTextWarrior:SetText(MPLanguage.UI_Warrior)

    local buttonWarriorArms = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ArmsWarrior, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarriorArms:Show()
    end)
    buttonWarriorArms:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonWarriorFury = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_FuryWarrior, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarriorFury:Show()
    end)
    buttonWarriorFury:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonWarriorEvil = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_EvilWarrior, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarriorEvil:Show()
    end)
    buttonWarriorEvil:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local buttonWarriorTank = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ProtWarrior, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarriorTank:Show()
    end)
    buttonWarriorTank:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)

    local lineWarrior = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineWarrior:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineWarrior:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineWarrior:SetVertexColor(0.5, 0.5, 0.5)
    lineWarrior:SetWidth(460)
    lineWarrior:SetHeight(3)
    lineWarrior:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)



    postion_y = postion_y-50

    local TipTextPaladin = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextPaladin:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextPaladin:SetWidth(150)
    TipTextPaladin:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextPaladin:SetTextColor(1, 0.8, 0)
    TipTextPaladin:SetJustifyH("LEFT")
    TipTextPaladin:SetText(MPLanguage.UI_Paladin)

    local buttonPaladinCJ = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_RetPaladin, function()
        MPCatSettingsCloseAll()
        CatUISettingsPaladinCJ:Show()
    end)
    buttonPaladinCJ:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonPaladinTank = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ProtPaladin, function()
        MPCatSettingsCloseAll()
        CatUISettingsPaladinTank:Show()
    end)
    buttonPaladinTank:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonPaladinHeal = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_HolyPaladin, function()
        MPCatSettingsCloseAll()
        CatUISettingsPaladinHealWindow:Show()
    end)
    buttonPaladinHeal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    --[[
    local buttonPaladinMeleeHeal = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_MeleeHealPaladin, function()
        MPCatSettingsCloseAll()
        CatUISettingsPaladinMeleeHeal:Show()
    end)
    buttonPaladinMeleeHeal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)
    ]]

    local linePaladin = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    linePaladin:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    linePaladin:SetTexCoord(0.81, 0.94, 0.5, 1)
    linePaladin:SetVertexColor(0.5, 0.5, 0.5)
    linePaladin:SetWidth(460)
    linePaladin:SetHeight(3)
    linePaladin:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)




    postion_y = postion_y-50

    local TipTextRogue = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextRogue:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextRogue:SetWidth(150)
    TipTextRogue:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextRogue:SetTextColor(1, 0.8, 0)
    TipTextRogue:SetJustifyH("LEFT")
    TipTextRogue:SetText(MPLanguage.UI_Rogue)

    local buttonRogueCombatDPS = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_CombatRogue, function()
        MPCatSettingsCloseAll()
        CatUISettingsRogueCombat:Show()
    end)
    buttonRogueCombatDPS:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonRogueEnvenomDPS = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_EnvenomRogue, function()
        MPCatSettingsCloseAll()
        CatUISettingsRogueEnvenom:Show()
    end)
    buttonRogueEnvenomDPS:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonRogueArmor = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ArmorRogue, function()
        MPCatSettingsCloseAll()
        CatUISettingsRogueArmor:Show()
    end)
    buttonRogueArmor:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local buttonRogue = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_CustomRogue, function()
        MPCatSettingsCloseAll()
        CatUISettingsRogue:Show()
    end)
    buttonRogue:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)

    local lineRogue = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineRogue:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineRogue:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineRogue:SetVertexColor(0.5, 0.5, 0.5)
    lineRogue:SetWidth(460)
    lineRogue:SetHeight(3)
    lineRogue:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)





    postion_y = postion_y-50

    local TipTextShaman = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextShaman:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextShaman:SetWidth(150)
    TipTextShaman:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextShaman:SetTextColor(1, 0.8, 0)
    TipTextShaman:SetJustifyH("LEFT")
    TipTextShaman:SetText(MPLanguage.UI_Shaman)

    local buttonShamanEnhance = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_EnhanceShaman, function()
        MPCatSettingsCloseAll()
        CatUISettingsShamanEnhanceWindow:Show()
    end)
    buttonShamanEnhance:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonShamanElemental = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ElementalShaman, function()
        MPCatSettingsCloseAll()
        CatUISettingsShamanElementalWindow:Show()
    end)
    buttonShamanElemental:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonShamanHeal = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_RestoShaman, function()
        MPCatSettingsCloseAll()
        CatUISettingsShamanHealWindow:Show()
    end)
    buttonShamanHeal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local lineShaman = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineShaman:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineShaman:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineShaman:SetVertexColor(0.5, 0.5, 0.5)
    lineShaman:SetWidth(460)
    lineShaman:SetHeight(3)
    lineShaman:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)




    postion_y = postion_y-50

    local TipTextWarlock = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextWarlock:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextWarlock:SetWidth(150)
    TipTextWarlock:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextWarlock:SetTextColor(1, 0.8, 0)
    TipTextWarlock:SetJustifyH("LEFT")
    TipTextWarlock:SetText(MPLanguage.UI_Warlock)

    local buttonWarlockSD = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ShadowDestroLock, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarlockSD:Show()
    end)
    buttonWarlockSD:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonWarlockFD = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_FireDestroLock, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarlockFD:Show()
    end)
    buttonWarlockFD:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonWarlockAff = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_AfflictionLock, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarlockAff:Show()
    end)
    buttonWarlockAff:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local buttonWarlockDemo = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_DemonLock, function()
        MPCatSettingsCloseAll()
        CatUISettingsWarlockDemo:Show()
    end)
    buttonWarlockDemo:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)


    local lineWarlock = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineWarlock:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineWarlock:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineWarlock:SetVertexColor(0.5, 0.5, 0.5)
    lineWarlock:SetWidth(460)
    lineWarlock:SetHeight(3)
    lineWarlock:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)




    postion_y = postion_y-50

    local TipTextMage = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextMage:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextMage:SetWidth(150)
    TipTextMage:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextMage:SetTextColor(1, 0.8, 0)
    TipTextMage:SetJustifyH("LEFT")
    TipTextMage:SetText(MPLanguage.UI_Mage)

    local buttonMageArcane = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ArcaneMage, function()
        MPCatSettingsCloseAll()
        CatUISettingsMageArcane:Show()
    end)
    buttonMageArcane:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonMageFire = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_FireMage, function()
        MPCatSettingsCloseAll()
        CatUISettingsMageFire:Show()
    end)
    buttonMageFire:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonMageFrost = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_FrostMage, function()
        MPCatSettingsCloseAll()
        CatUISettingsMageFrost:Show()
    end)
    buttonMageFrost:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)


    local lineMage = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineMage:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineMage:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineMage:SetVertexColor(0.5, 0.5, 0.5)
    lineMage:SetWidth(460)
    lineMage:SetHeight(3)
    lineMage:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)



    postion_y = postion_y-50

    local TipTextPriest = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextPriest:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextPriest:SetWidth(150)
    TipTextPriest:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextPriest:SetTextColor(1, 0.8, 0)
    TipTextPriest:SetJustifyH("LEFT")
    TipTextPriest:SetText(MPLanguage.UI_Priest)

    local buttonPriestShadow = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_ShadowPriest, function()
        MPCatSettingsCloseAll()
        CatUISettingsPriestShadow:Show()
    end)
    buttonPriestShadow:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonPriestDiscipline = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_DiscPriest, function()
        MPCatSettingsCloseAll()
        CatUISettingsPriestDiscipline:Show()
    end)
    buttonPriestDiscipline:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonPriestHeal = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_HolyPriest, function()
        MPCatSettingsCloseAll()
        CatUISettingsPriestHealWindow:Show()
    end)
    buttonPriestHeal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local linePriest = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    linePriest:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    linePriest:SetTexCoord(0.81, 0.94, 0.5, 1)
    linePriest:SetVertexColor(0.5, 0.5, 0.5)
    linePriest:SetWidth(460)
    linePriest:SetHeight(3)
    linePriest:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)




    postion_y = postion_y-50

    local TipTextHunter = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TipTextHunter:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    TipTextHunter:SetWidth(150)
    TipTextHunter:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
    TipTextHunter:SetTextColor(1, 0.8, 0)
    TipTextHunter:SetJustifyH("LEFT")
    TipTextHunter:SetText(MPLanguage.UI_Hunter)

    local buttonHunterBeast = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_BeastHunter, function()
        MPCatSettingsCloseAll()
        CatUISettingsHunterBeast:Show()
    end)
    buttonHunterBeast:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

    local buttonHunterShot = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_MMHunter, function()
        MPCatSettingsCloseAll()
        CatUISettingsHunterShot:Show()
    end)
    buttonHunterShot:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)

    local buttonHunterMelee = CreateFlatButton("MyFlatButton1", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_SurvivalHunter, function()
        MPCatSettingsCloseAll()
        CatUISettingsHunterMelee:Show()
    end)
    buttonHunterMelee:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)

    local lineHunter = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
    lineHunter:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    lineHunter:SetTexCoord(0.81, 0.94, 0.5, 1)
    lineHunter:SetVertexColor(0.5, 0.5, 0.5)
    lineHunter:SetWidth(460)
    lineHunter:SetHeight(3)
    lineHunter:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)






postion_y = postion_y-50

local TipTextNormal = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextNormal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
TipTextNormal:SetWidth(150)
TipTextNormal:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
TipTextNormal:SetTextColor(1, 0.8, 0)
TipTextNormal:SetJustifyH("LEFT")
TipTextNormal:SetText(MPLanguage.UI_General)

local buttonNormalINT = CreateFlatButton("buttonNormalINT", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_Interrupt, function()
    MPCatSettingsCloseAll()
    CatUISettingsInterrupt:Show()
end)
buttonNormalINT:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

local buttonNormalDOT = CreateFlatButton("buttonNormalDOT", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_MultiDot, function()
    MPCatSettingsCloseAll()
    CatUISettingsMultilineDot:Show()
end)
buttonNormalDOT:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)


local buttonAutoLoot = CreateFlatButton("buttonAutoLoot", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_AutoLoot, function()
    MPCatSettingsCloseAll()
    CatUISettingAutoLoot:Show()
end)
buttonAutoLoot:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)

local buttonPower = CreateFlatButton("buttonPower", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_PowerPotion, function()
    MPCatSettingsCloseAll()
    CatUISettingsPower:Show()
end)
buttonPower:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)


local lineNormal = CatUISettingsCatMenu:CreateTexture(nil, "ARTWORK")
lineNormal:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
lineNormal:SetTexCoord(0.81, 0.94, 0.5, 1)
lineNormal:SetVertexColor(0.5, 0.5, 0.5)
lineNormal:SetWidth(460)
lineNormal:SetHeight(3)
lineNormal:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)


postion_y = postion_y-50

local TipTextAdd = CatUISettingsCatMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextAdd:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
TipTextAdd:SetWidth(150)
TipTextAdd:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
TipTextAdd:SetTextColor(1, 0.8, 0)
TipTextAdd:SetJustifyH("LEFT")
TipTextAdd:SetText(MPLanguage.UI_Addon)


local buttonNormalDebug = CreateFlatButton("buttonNormalDebug", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_RealtimeMonitor, function()
    MPCatSettingsCloseAll()
    CatDebugWindow:Show()
    MPPublicSaved.DebugWindowDisplay=1
end)
buttonNormalDebug:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)


local buttonNormalClassUp = CreateFlatButton("buttonNormalClass", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_Collapse, function()
    MPCatSettingsCloseAll()
    MPPublicSaved.AllClass=0 
    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_CollapseClass)
end)

buttonNormalClassUp:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)
local buttonNormalClassDown = CreateFlatButton("buttonNormalClass", CatUISettingsCatMenu, nil, nil, MPLanguage.UI_Expand, function()
    MPCatSettingsCloseAll()
    MPPublicSaved.AllClass=1 
    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ExpandClass)
end)
buttonNormalClassDown:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)




local ClassMenuGroups = {
    { class = "DRUID", label = TipTextDruid, buttons = { buttonCat, buttonBear, buttonBird, buttonHeal }, line = lineDruid },
    { class = "WARRIOR", label = TipTextWarrior, buttons = { buttonWarriorArms, buttonWarriorFury, buttonWarriorEvil, buttonWarriorTank }, line = lineWarrior },
    { class = "PALADIN", label = TipTextPaladin, buttons = { buttonPaladinCJ, buttonPaladinTank, buttonPaladinHeal }, line = linePaladin },
    { class = "ROGUE", label = TipTextRogue, buttons = { buttonRogueCombatDPS, buttonRogueEnvenomDPS, buttonRogueArmor, buttonRogue }, line = lineRogue },
    { class = "SHAMAN", label = TipTextShaman, buttons = { buttonShamanEnhance, buttonShamanElemental, buttonShamanHeal }, line = lineShaman },
    { class = "WARLOCK", label = TipTextWarlock, buttons = { buttonWarlockSD, buttonWarlockFD, buttonWarlockAff, buttonWarlockDemo }, line = lineWarlock },
    { class = "PRIEST", label = TipTextPriest, buttons = { buttonPriestShadow, buttonPriestDiscipline, buttonPriestHeal }, line = linePriest },
    { class = "MAGE", label = TipTextMage, buttons = { buttonMageArcane, buttonMageFire, buttonMageFrost }, line = lineMage },
    { class = "HUNTER", label = TipTextHunter, buttons = { buttonHunterBeast, buttonHunterShot, buttonHunterMelee }, line = lineHunter }
}

local function InitClassMenuSettings()
    for _, group in ipairs(ClassMenuGroups) do
        if MPPlayerClass == group.class or MPPublicSaved.AllClass == 1 then
            height = height + 50
            postion_y = postion_y - 50
            group.label:Show()
            for _, button in ipairs(group.buttons) do
                button:Show()
            end
            group.line:Show()
            group.label:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y - 6)
            for index, button in ipairs(group.buttons) do
                button:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x + offset * (index - 1), postion_y)
            end
            group.line:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y - 36)
        else
            group.label:Hide()
            for _, button in ipairs(group.buttons) do
                button:Hide()
            end
            group.line:Hide()
        end
    end
end


function MPInitMenuSettings()
    height = 0
    postion_y = -10
    offset = 100
    InitClassMenuSettings()


    postion_y = postion_y-50
    TipTextNormal:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    buttonNormalINT:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)
    buttonNormalDOT:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)
    buttonAutoLoot:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*2, postion_y)
    buttonPower:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset*3, postion_y)
    lineNormal:SetPoint("TOP", CatUISettingsCatMenu, "TOP", 0, postion_y-36)

    postion_y = postion_y-50
    TipTextAdd:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", 34, postion_y-6)
    buttonNormalDebug:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x, postion_y)


    if MPPublicSaved and MPPublicSaved.AllClass and MPPublicSaved.AllClass==1 then 
        buttonNormalClassUp:Show()
        buttonNormalClassDown:Hide()
        buttonNormalClassUp:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)
    else
        buttonNormalClassUp:Hide()
        buttonNormalClassDown:Show()
        buttonNormalClassDown:SetPoint("TOPLEFT", CatUISettingsCatMenu, "TOPLEFT", postion_x+offset, postion_y)
    end

    -- 设置总窗口高度
    CatUISettingsCatMenu:SetHeight(180+height)

end

