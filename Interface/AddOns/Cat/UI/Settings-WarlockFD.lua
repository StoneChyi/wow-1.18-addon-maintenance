
-- 定义插件名称
local ADDON_NAME = "Settings-WarlockFD"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPWarlockFDSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsWarlockFD = MPCreateFrame(ADDON_NAME.."Frame", 520, 630, "|cFF9482C9设置 - 火毁术|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsWarlockFD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsWarlockFD, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40


-- 创建单选框 - 痛苦诅咒
local checkButton_CurseAgony = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseAgony, GetCurrentSaved, "CurseAgony")
local checkButton_CurseAgonyBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CurseAgonyBoss, GetCurrentSaved, "CurseAgonyBoss")



-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 腐蚀术​
local checkButton_Corruption = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 腐蚀术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Corruption, GetCurrentSaved, "Corruption")
local checkButton_CorruptionBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CorruptionBoss, GetCurrentSaved, "CorruptionBoss")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 灵魂之火
local checkButton_SoulFire = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "开启 灵魂之火")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SoulFire, GetCurrentSaved, "SoulFire")

local checkButton_SoulFireBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulFireBoss, GetCurrentSaved, "SoulFireBoss")



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 燃烧​
local checkButton_Conflagrate = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "开启 燃烧")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Conflagrate, GetCurrentSaved, "Conflagrate")


-- 创建单选框 - 超越之力
local checkButton_Overpowering = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "开启 超越之力 (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overpowering, GetCurrentSaved, "Overpowering")



postion_y = postion_y-30

-- 创建单选框 - 献祭
local checkButton_Immolate = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 献祭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Immolate, GetCurrentSaved, "Immolate")

-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")




postion_y = postion_y-30

-- 创建单选框 - 暗影灼烧
local checkButton_Shadowburn = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "开启 暗影灼烧")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Shadowburn, GetCurrentSaved, "Shadowburn")
local checkButton_ShadowburnBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_ShadowburnBoss, GetCurrentSaved, "ShadowburnBoss")


-- 创建单选框 - 灼热之痛
local checkButton_SearingPain = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "开启 灼热之痛 (单选)")



postion_y = postion_y-30

-- 创建单选框 - 暗影箭
local checkButton_ShadowBolt = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "开启 暗影箭 (单选)")

-- 灼热之痛点击事件
checkButton_SearingPain:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].SearingPain = 1
        MPWarlockFDSaved[ConfigCurrent].ShadowBolt = 0
    else
        MPWarlockFDSaved[ConfigCurrent].SearingPain = 0
    end
    checkButton_SearingPain:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SearingPain) )
    checkButton_ShadowBolt:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].ShadowBolt) )

end)

-- 暗影箭点击事件
checkButton_ShadowBolt:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].ShadowBolt = 1
        MPWarlockFDSaved[ConfigCurrent].SearingPain = 0
    else
        MPWarlockFDSaved[ConfigCurrent].ShadowBolt = 0
    end
    checkButton_SearingPain:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SearingPain) )
    checkButton_ShadowBolt:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].ShadowBolt) )

end)







-- 团队诅咒


postion_y = postion_y+10

-- 添加提示内容区域
local TipTextTeam = CatUISettingsWarlockFD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextTeam:SetPoint("TOPLEFT", CatUISettingsWarlockFD, "TOPLEFT", 20, postion_y)
TipTextTeam:SetWidth(250)
TipTextTeam:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipTextTeam:SetTextColor(1, 0.8, 0)
TipTextTeam:SetJustifyH("LEFT")
TipTextTeam:SetText("大诅咒配置 (单选)")


postion_y = postion_y-85

-- 创建单选框 - 鲁莽诅咒
local checkButton_CurseRecklessness = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "鲁莽")

-- 创建单选框 - 元素诅咒
local checkButton_CurseElements = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 105, postion_y, "元素")

-- 创建单选框 - 暗影诅咒
local checkButton_CurseShadow = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 190, postion_y, "暗影")

-- 创建单选框 - 厄运诅咒
local checkButton_CurseDoom = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 275, postion_y, "厄运")

-- 创建单选框 - 语言诅咒
local checkButton_CurseTongues = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 360, postion_y, "语言")

-- 创建单选框 - 虚弱诅咒
local checkButton_CurseWeakness = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 445, postion_y, "虚弱")

-- 创建单选框 - 疲劳诅咒
local checkButton_CurseFatigue = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 530, postion_y, "疲劳")


checkButton_CurseRecklessness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 1
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseElements:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 1
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseShadow:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 1
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseDoom:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 1
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseTongues:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 1
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseWeakness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 1
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseFatigue:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockFDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockFDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockFDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockFDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 1
    else
        MPWarlockFDSaved[ConfigCurrent].CurseFatigue = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))

end)









-- 高级


postion_y = postion_y+25

-- 添加提示内容区域
local TipText1 = CatUISettingsWarlockFD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsWarlockFD, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100


-- 创建单选框 - 预读灵魂之火
local checkButton_First = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 灵魂之火")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_First, GetCurrentSaved, "First")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPWarlockFDSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPWarlockFDSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 大诅咒BOSS
local checkButton_CurseBOSS = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 20, postion_y, "非BOSS忽略 大诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseBOSS, GetCurrentSaved, "CurseBOSS")





-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPWarlockFDSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40



-- 创建单选框 - 生命分流
local checkButton_LifeTap = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 生命分流")

local slider_LifeTap = MPCreateConfigSlider(ADDON_NAME.."Slider_LifeTap", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -2, 150, 16, 10, 100, 1, 60)

local color_LifeTap = "|cFFFFD100"

-- 值变化时的回调函数
slider_LifeTap:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockFDSaved[ConfigCurrent].LifeTap_Value = arg1
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockFDSaved[ConfigCurrent].LifeTap_Value .."%|r")
end)

-- 设置点击事件
checkButton_LifeTap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockFDSaved[ConfigCurrent].LifeTap = 1
        color_LifeTap = "|cFFFFD100"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockFDSaved[ConfigCurrent].LifeTap_Value .."%|r")
    else
        MPWarlockFDSaved[ConfigCurrent].LifeTap = 0
        color_LifeTap = "|cFF888888"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockFDSaved[ConfigCurrent].LifeTap_Value .."%|r")
    end
end)


-- 生命分流 蓝量百分比
local slider_LifeTap_Mana = MPCreateConfigSlider(ADDON_NAME.."SliderLifeTap_Mana", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -50, 200, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_LifeTap_Mana:SetScript("OnValueChanged", function()
    _G[slider_LifeTap_Mana:GetName().."Text"]:SetText("生命分流 蓝量启动线："..arg1.."%")
    MPWarlockFDSaved[ConfigCurrent].LifeTap_Mana = arg1
end)





postion_y = postion_y-40



postion_y = postion_y-40


-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y-40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockFD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")


postion_y = postion_y - 60


-- 创建按钮
local myButton = MPCreateButton(CatUISettingsWarlockFD, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetWarlockFDSettings(ConfigCurrent)
    MPInitWarlockFDSettings()
end)

local ConfigButton = MPCreateConfigSelector(CatUISettingsWarlockFD, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitWarlockFDSettings()
end)



local MLDButton = MPCreateButton(CatUISettingsWarlockFD, ADDON_NAME.."ButtonReset", "多线DOT设置", 60, postion_y+190, 120, 22)
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsWarlockFD, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsWarlockFD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsWarlockFD, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF9482C9/fhdps|r [ 1 | 2 | 3 ]   多线Dot |cFF9482C9/MDot|r")



-- 配置文件版本号
local WarlockFDSettingsUIVersion = 13

function MPResetWarlockFDSettings(config)

    MPWarlockFDSaved.Version = WarlockFDSettingsUIVersion

    -- 基本配置

    MPWarlockFDSaved[config].CurseAgony = 0
    MPWarlockFDSaved[config].CurseAgonyBoss = 0
    MPWarlockFDSaved[config].Corruption = 0
    MPWarlockFDSaved[config].CorruptionBoss = 0
    MPWarlockFDSaved[config].SoulFire = 1
    MPWarlockFDSaved[config].SoulFireBoss = 0
    MPWarlockFDSaved[config].Conflagrate = 1
    MPWarlockFDSaved[config].SearingPain = 1
    MPWarlockFDSaved[config].ShadowBolt = 0
    MPWarlockFDSaved[config].Immolate = 1
    MPWarlockFDSaved[config].Shadowburn = 0
    MPWarlockFDSaved[config].ShadowburnBoss = 0

    MPWarlockFDSaved[config].PetAttack = 0

    MPWarlockFDSaved[config].Trinket_Upper = 1
    MPWarlockFDSaved[config].TUBoss = 0
    MPWarlockFDSaved[config].Trinket_Below = 1
    MPWarlockFDSaved[config].TBBoss = 0
    MPWarlockFDSaved[config].Target = 0
    MPWarlockFDSaved[config].Overpowering = 0

    MPWarlockFDSaved[config].CurseRecklessness = 0
    MPWarlockFDSaved[config].CurseElements = 1
    MPWarlockFDSaved[config].CurseShadow = 0
    MPWarlockFDSaved[config].CurseTongues = 0
    MPWarlockFDSaved[config].CurseWeakness = 0
    MPWarlockFDSaved[config].CurseFatigue = 0
    MPWarlockFDSaved[config].CurseDoom = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPWarlockFDSaved[config].HealthStone = 1
    MPWarlockFDSaved[config].HealthStone_Value = 30
    MPWarlockFDSaved[config].HerbalTea = 1
    MPWarlockFDSaved[config].HerbalTea_Value = 20
    MPWarlockFDSaved[config].HerbalTeaMana = 0
    MPWarlockFDSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPWarlockFDSaved[config].SuperWoW = 1
    MPWarlockFDSaved[config].UnitXP = 1

    MPWarlockFDSaved[config].CurseBOSS = 0
    MPWarlockFDSaved[config].First = 0

    MPWarlockFDSaved[config].RacialTraits = 0
    MPWarlockFDSaved[config].RacialTraitsBoss = 1
    MPWarlockFDSaved[config].Soulspeed = 0
    MPWarlockFDSaved[config].SoulspeedBoss = 1

    MPWarlockFDSaved[config].LifeTap = 0
    MPWarlockFDSaved[config].LifeTap_Value = 60
    MPWarlockFDSaved[config].LifeTap_Mana = 70

    -- 通用
    MPWarlockFDSaved[config].Power = 0
    MPWarlockFDSaved[config].Pick = 0

end


local function MPInitWarlockFDSettingsPart1()
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseAgony))
    checkButton_CurseAgonyBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseAgonyBoss))
    checkButton_Corruption:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Corruption))
    checkButton_CorruptionBoss:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CorruptionBoss) )

    checkButton_SoulFire:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SoulFire))
    checkButton_SoulFireBoss:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SoulFireBoss) )
    checkButton_Conflagrate:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Conflagrate) )
    checkButton_SearingPain:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SearingPain) )
    checkButton_ShadowBolt:SetChecked( MPToBoolean(MPWarlockFDSaved[ConfigCurrent].ShadowBolt) )
    checkButton_Immolate:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Immolate))
    checkButton_Shadowburn:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Shadowburn))
    checkButton_ShadowburnBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].ShadowburnBoss))

    checkButton_Target:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Target))
    checkButton_Overpowering:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Overpowering))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].PetAttack))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].TBBoss))

    checkButton_CurseBOSS:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseBOSS))
    checkButton_First:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].First))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))


end

function MPInitWarlockFDSettings()
    if not MPWarlockFDSaved then
        MPWarlockFDSaved = {}

        -- 第一套配置
        if not MPWarlockFDSaved[1] then
            MPWarlockFDSaved[1] = {}
            MPResetWarlockFDSettings(1)
        end

        -- 第二套配置
        if not MPWarlockFDSaved[2] then
            MPWarlockFDSaved[2] = {}
            MPResetWarlockFDSettings(2)
        end

        -- 第三套配置
        if not MPWarlockFDSaved[3] then
            MPWarlockFDSaved[3] = {}
            MPResetWarlockFDSettings(3)
        end
    end

    if MPWarlockFDSaved.Version ~= WarlockFDSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[火毁术宏]当前配置，这是新版插件正常数据更新！|r")
        MPWarlockFDSaved[1] = {}
        MPWarlockFDSaved[2] = {}
        MPWarlockFDSaved[3] = {}
        MPResetWarlockFDSettings(1)
        MPResetWarlockFDSettings(2)
        MPResetWarlockFDSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitWarlockFDSettingsPart1()

    checkButton_Power:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].Pick))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPWarlockFDSaved[ConfigCurrent].HealthStone_Value)
    if MPWarlockFDSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPWarlockFDSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value)
    if MPWarlockFDSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockFDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_LifeTap:SetChecked(MPWarlockFDSaved[ConfigCurrent].LifeTap)
    slider_LifeTap:SetValue(MPWarlockFDSaved[ConfigCurrent].LifeTap_Value)
    if MPWarlockFDSaved[ConfigCurrent].LifeTap==1 then
        color_LifeTap = "|cFFFFD100"
    else
        color_LifeTap = "|cFF888888"
    end
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockFDSaved[ConfigCurrent].LifeTap_Value .."%|r")

    slider_LifeTap_Mana:SetValue(MPWarlockFDSaved[ConfigCurrent].LifeTap_Mana)

end

