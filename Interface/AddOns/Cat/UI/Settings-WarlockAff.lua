
-- 定义插件名称
local ADDON_NAME = "Settings-WarlockAff"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPWarlockAffSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsWarlockAff = MPCreateFrame(ADDON_NAME.."Frame", 520, 600, "|cFF9482C9设置 - 痛苦术|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsWarlockAff:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsWarlockAff, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40


-- 创建单选框 - 痛苦诅咒
local checkButton_CurseAgony = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "保持 痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseAgony, GetCurrentSaved, "CurseAgony")
local checkButton_CurseAgonyBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CurseAgonyBoss, GetCurrentSaved, "CurseAgonyBoss")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30


-- 创建单选框 - 腐蚀术​
local checkButton_Corruption = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "保持 腐蚀术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Corruption, GetCurrentSaved, "Corruption")
local checkButton_CorruptionBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CorruptionBoss, GetCurrentSaved, "CorruptionBoss")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30


-- 创建单选框 - 生命虹吸
local checkButton_SiphonLife = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "保持 生命虹吸")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SiphonLife, GetCurrentSaved, "SiphonLife")

local checkButton_SiphonLifeBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SiphonLifeBoss, GetCurrentSaved, "SiphonLifeBoss")



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30


-- 创建单选框 - 献祭
local checkButton_Immolate = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "保持 献祭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Immolate, GetCurrentSaved, "Immolate")


-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")



postion_y = postion_y-30

-- 创建单选框 - 暗影收割
local checkButton_ShadowHarvest = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "开启 暗影收割")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ShadowHarvest, GetCurrentSaved, "ShadowHarvest")


-- 创建单选框 - 吸取生命
local checkButton_DrainLife = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "开启 吸取生命 (单选)")



postion_y = postion_y-30

-- 创建单选框 - 暗影灼烧
local checkButton_Shadowburn = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "开启 暗影灼烧")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Shadowburn, GetCurrentSaved, "Shadowburn")
local checkButton_ShadowburnBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_ShadowburnBoss, GetCurrentSaved, "ShadowburnBoss")


-- 创建单选框 - 吸取灵魂
local checkButton_DrainSoul = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "开启 吸取灵魂 (单选)")
-- 设置点击事件
checkButton_DrainLife:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].DrainLife = 1
        MPWarlockAffSaved[ConfigCurrent].DrainSoul = 0
    else
        MPWarlockAffSaved[ConfigCurrent].DrainLife = 0
    end

    checkButton_DrainLife:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainLife))
    checkButton_DrainSoul:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainSoul))

end)

-- 设置点击事件
checkButton_DrainSoul:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].DrainSoul = 1
        MPWarlockAffSaved[ConfigCurrent].DrainLife = 0
    else
        MPWarlockAffSaved[ConfigCurrent].DrainSoul = 0
    end

    checkButton_DrainLife:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainLife))
    checkButton_DrainSoul:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainSoul))

end)






-- 团队诅咒


postion_y = postion_y+10

-- 添加提示内容区域
local TipTextTeam = CatUISettingsWarlockAff:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextTeam:SetPoint("TOPLEFT", CatUISettingsWarlockAff, "TOPLEFT", 20, postion_y)
TipTextTeam:SetWidth(250)
TipTextTeam:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipTextTeam:SetTextColor(1, 0.8, 0)
TipTextTeam:SetJustifyH("LEFT")
TipTextTeam:SetText("大诅咒配置 (单选)")


postion_y = postion_y-85

-- 创建单选框 - 鲁莽诅咒
local checkButton_CurseRecklessness = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "鲁莽")

-- 创建单选框 - 元素诅咒
local checkButton_CurseElements = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 105, postion_y, "元素")

-- 创建单选框 - 暗影诅咒
local checkButton_CurseShadow = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 190, postion_y, "暗影")

-- 创建单选框 - 厄运诅咒
local checkButton_CurseDoom = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 275, postion_y, "厄运")

-- 创建单选框 - 语言诅咒
local checkButton_CurseTongues = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 360, postion_y, "语言")

-- 创建单选框 - 虚弱诅咒
local checkButton_CurseWeakness = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 445, postion_y, "虚弱")

-- 创建单选框 - 疲劳诅咒
local checkButton_CurseFatigue = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 530, postion_y, "疲劳")


checkButton_CurseRecklessness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 1
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseElements:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 1
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseShadow:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 1
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseDoom:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 1
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseTongues:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 1
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseWeakness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 1
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseFatigue:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseElements = 0
        MPWarlockAffSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockAffSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockAffSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockAffSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 1
    else
        MPWarlockAffSaved[ConfigCurrent].CurseFatigue = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))

end)










-- 高级


postion_y = postion_y+30

-- 添加提示内容区域
local TipText1 = CatUISettingsWarlockAff:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsWarlockAff, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100

-- 创建单选框 - 预读暗影箭
local checkButton_FirstShadowBolt = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 暗影箭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstShadowBolt, GetCurrentSaved, "FirstShadowBolt")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPWarlockAffSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPWarlockAffSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 邪咒
local checkButton_CurseEvil = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "启用 邪咒替换痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseEvil, GetCurrentSaved, "CurseEvil")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPWarlockAffSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 创建单选框 - 大诅咒BOSS
local checkButton_CurseBOSS = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "非BOSS忽略 大诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseBOSS, GetCurrentSaved, "CurseBOSS")


-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40


-- 创建单选框 - 打断 吸取灵魂
local checkButton_ClipDrainSoul = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 20, postion_y, "允许中断 吸取灵魂 (SuperWoW)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ClipDrainSoul, GetCurrentSaved, "ClipDrainSoul")


-- 创建单选框 - 生命分流
local checkButton_LifeTap = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动 生命分流")

local slider_LifeTap = MPCreateConfigSlider(ADDON_NAME.."Slider_LifeTap", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -2, 150, 16, 10, 100, 1, 60)

local color_LifeTap = "|cFFFFD100"

-- 值变化时的回调函数
slider_LifeTap:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockAffSaved[ConfigCurrent].LifeTap_Value = arg1
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockAffSaved[ConfigCurrent].LifeTap_Value .."%|r")
end)

-- 设置点击事件
checkButton_LifeTap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockAffSaved[ConfigCurrent].LifeTap = 1
        color_LifeTap = "|cFFFFD100"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockAffSaved[ConfigCurrent].LifeTap_Value .."%|r")
    else
        MPWarlockAffSaved[ConfigCurrent].LifeTap = 0
        color_LifeTap = "|cFF888888"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockAffSaved[ConfigCurrent].LifeTap_Value .."%|r")
    end
end)


-- 生命分流 蓝量百分比
local slider_LifeTap_Mana = MPCreateConfigSlider(ADDON_NAME.."SliderLifeTap_Mana", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -50, 200, 16, 10, 99, 1, 70)

_G[slider_LifeTap_Mana:GetName().."Text"]:SetText("生命分流 蓝量启动线: 70%|r")

-- 值变化时的回调函数
slider_LifeTap_Mana:SetScript("OnValueChanged", function()
    _G[slider_LifeTap_Mana:GetName().."Text"]:SetText("生命分流 蓝量启动线："..arg1.."%")
    MPWarlockAffSaved[ConfigCurrent].LifeTap_Mana = arg1
end)




postion_y = postion_y - 40


postion_y = postion_y - 40


-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")



postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockAff, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")




postion_y = postion_y - 40




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsWarlockAff, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetWarlockAffSettings(ConfigCurrent)
    MPInitWarlockAffSettings()
end)

local ConfigButton = MPCreateConfigSelector(CatUISettingsWarlockAff, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitWarlockAffSettings()
end)



local MLDButton = MPCreateButton(CatUISettingsWarlockAff, ADDON_NAME.."ButtonReset", "多线DOT设置", 60, postion_y+160, 120, 22)
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsWarlockAff, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsWarlockAff:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsWarlockAff, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF9482C9/tkdps|r [ 1 | 2 | 3 ]   多线Dot |cFF9482C9/MDot|r")



-- 配置文件版本号
local WarlockAffSettingsUIVersion = 12

function MPResetWarlockAffSettings(config)

    MPWarlockAffSaved.Version = WarlockAffSettingsUIVersion

    -- 基本配置

    MPWarlockAffSaved[config].Corruption = 1
    MPWarlockAffSaved[config].CorruptionBoss = 0
    MPWarlockAffSaved[config].SiphonLife = 1
    MPWarlockAffSaved[config].SiphonLifeBoss = 0
    MPWarlockAffSaved[config].Immolate = 0
    MPWarlockAffSaved[config].DrainLife = 0
    MPWarlockAffSaved[config].DrainSoul = 1
    MPWarlockAffSaved[config].ShadowHarvest = 1
    MPWarlockAffSaved[config].Shadowburn = 0
    MPWarlockAffSaved[config].ShadowburnBoss = 0

    MPWarlockAffSaved[config].PetAttack = 0

    MPWarlockAffSaved[config].Trinket_Upper = 1
    MPWarlockAffSaved[config].TUBoss = 0
    MPWarlockAffSaved[config].Trinket_Below = 1
    MPWarlockAffSaved[config].TBBoss = 0
    MPWarlockAffSaved[config].Target = 0


    MPWarlockAffSaved[config].CurseAgony = 1
    MPWarlockAffSaved[config].CurseAgonyBoss = 0
    MPWarlockAffSaved[config].CurseRecklessness = 0
    MPWarlockAffSaved[config].CurseElements = 0
    MPWarlockAffSaved[config].CurseShadow = 1
    MPWarlockAffSaved[config].CurseTongues = 0
    MPWarlockAffSaved[config].CurseWeakness = 0
    MPWarlockAffSaved[config].CurseFatigue = 0
    MPWarlockAffSaved[config].CurseDoom = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPWarlockAffSaved[config].HealthStone = 1
    MPWarlockAffSaved[config].HealthStone_Value = 30
    MPWarlockAffSaved[config].HerbalTea = 1
    MPWarlockAffSaved[config].HerbalTea_Value = 20
    MPWarlockAffSaved[config].HerbalTeaMana = 0
    MPWarlockAffSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPWarlockAffSaved[config].SuperWoW = 1
    MPWarlockAffSaved[config].UnitXP = 1

    MPWarlockAffSaved[config].ClipDrainSoul = 0
    MPWarlockAffSaved[config].CurseBOSS = 0
    MPWarlockAffSaved[config].ShadowburnBoss = 0
    MPWarlockAffSaved[config].FirstShadowBolt = 0
    MPWarlockAffSaved[config].CurseEvil = 1

    MPWarlockAffSaved[config].RacialTraits = 0
    MPWarlockAffSaved[config].RacialTraitsBoss = 1
    MPWarlockAffSaved[config].Soulspeed = 0
    MPWarlockAffSaved[config].SoulspeedBoss = 1

    MPWarlockAffSaved[config].LifeTap = 0
    MPWarlockAffSaved[config].LifeTap_Value = 60
    MPWarlockAffSaved[config].LifeTap_Mana = 70

    -- 通用
    MPWarlockAffSaved[config].Power = 0
    MPWarlockAffSaved[config].Pick = 0

end


local function MPInitWarlockAffSettingsPart1()
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseAgony))
    checkButton_CurseAgonyBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseAgonyBoss))
    checkButton_Corruption:SetChecked( MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Corruption) )
    checkButton_CorruptionBoss:SetChecked( MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CorruptionBoss) )
    checkButton_SiphonLife:SetChecked( MPToBoolean(MPWarlockAffSaved[ConfigCurrent].SiphonLife) )
    checkButton_SiphonLifeBoss:SetChecked( MPToBoolean(MPWarlockAffSaved[ConfigCurrent].SiphonLifeBoss) )
    checkButton_Immolate:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Immolate))
    checkButton_DrainLife:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainLife))
    checkButton_DrainSoul:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].DrainSoul))
    checkButton_ShadowHarvest:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].ShadowHarvest))
    checkButton_Shadowburn:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Shadowburn))
    checkButton_Target:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Target))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].PetAttack))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].TBBoss))
    checkButton_ClipDrainSoul:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].ClipDrainSoul))
    --checkButton_BOSS:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].BOSS))

    checkButton_CurseBOSS:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseBOSS))
    checkButton_ShadowburnBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].ShadowburnBoss))
    checkButton_FirstShadowBolt:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].FirstShadowBolt))
    checkButton_CurseEvil:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseEvil))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].SoulspeedBoss))



end

function MPInitWarlockAffSettings()
    if not MPWarlockAffSaved then
        MPWarlockAffSaved = {}

        -- 第一套配置
        if not MPWarlockAffSaved[1] then
            MPWarlockAffSaved[1] = {}
            MPResetWarlockAffSettings(1)
        end

        -- 第二套配置
        if not MPWarlockAffSaved[2] then
            MPWarlockAffSaved[2] = {}
            MPResetWarlockAffSettings(2)
        end

        -- 第三套配置
        if not MPWarlockAffSaved[3] then
            MPWarlockAffSaved[3] = {}
            MPResetWarlockAffSettings(3)
        end
    end

    if MPWarlockAffSaved.Version ~= WarlockAffSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[痛苦术宏]当前配置，这是新版插件正常数据更新！|r")
        MPWarlockAffSaved[1] = {}
        MPWarlockAffSaved[2] = {}
        MPWarlockAffSaved[3] = {}
        MPResetWarlockAffSettings(1)
        MPResetWarlockAffSettings(2)
        MPResetWarlockAffSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitWarlockAffSettingsPart1()

    checkButton_Power:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].Pick))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPWarlockAffSaved[ConfigCurrent].HealthStone_Value)
    if MPWarlockAffSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPWarlockAffSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value)
    if MPWarlockAffSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockAffSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_LifeTap:SetChecked(MPWarlockAffSaved[ConfigCurrent].LifeTap)
    slider_LifeTap:SetValue(MPWarlockAffSaved[ConfigCurrent].LifeTap_Value)
    if MPWarlockAffSaved[ConfigCurrent].LifeTap==1 then
        color_LifeTap = "|cFFFFD100"
    else
        color_LifeTap = "|cFF888888"
    end
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockAffSaved[ConfigCurrent].LifeTap_Value .."%|r")

    slider_LifeTap_Mana:SetValue(MPWarlockAffSaved[ConfigCurrent].LifeTap_Mana)

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseFatigue))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockAffSaved[ConfigCurrent].CurseDoom))

end

