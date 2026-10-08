
-- 定义插件名称
local ADDON_NAME = "Settings-WarlockDemo"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPWarlockDemoSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsWarlockDemo = MPCreateFrame(ADDON_NAME.."Frame", 520, 610, "|cFF9482C9设置 - 恶魔术|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsWarlockDemo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsWarlockDemo, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 痛苦诅咒
local checkButton_CurseAgony = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "保持 痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseAgony, GetCurrentSaved, "CurseAgony")
local checkButton_CurseAgonyBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CurseAgonyBoss, GetCurrentSaved, "CurseAgonyBoss")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 腐蚀术​
local checkButton_Corruption = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "保持 腐蚀术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Corruption, GetCurrentSaved, "Corruption")

local checkButton_CorruptionBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CorruptionBoss, GetCurrentSaved, "CorruptionBoss")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 献祭
local checkButton_Immolate = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "保持 献祭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Immolate, GetCurrentSaved, "Immolate")



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 暗影灼烧
local checkButton_Shadowburn = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "开启 暗影灼烧")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Shadowburn, GetCurrentSaved, "Shadowburn")
local checkButton_ShadowburnBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_ShadowburnBoss, GetCurrentSaved, "ShadowburnBoss")



-- 创建单选框 - 超越之力
local checkButton_Overpowering = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "开启 超越之力 (自动识别天赋)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overpowering, GetCurrentSaved, "Overpowering")



postion_y = postion_y-30

local checkButton_Potential = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "释放潜力")
MPBindConfigCheckButton(checkButton_Potential, GetCurrentSaved, "Potential")

local slider_Potential = MPCreateConfigSlider(ADDON_NAME.."Potential_Value", CatUISettingsWarlockDemo, "TOPLEFT", CatUISettingsWarlockDemo, "TOPLEFT", 120, postion_y+34, 120, 15, 1, 10, 1, 0)

-- 值变化时的回调函数
slider_Potential:SetScript("OnValueChanged", function()
    MPWarlockDemoSaved[ConfigCurrent].Potential_Value = arg1
    _G[slider_Potential:GetName().."Text"]:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    _G[slider_Potential:GetName().."Text"]:SetText("剩余 "..MPWarlockDemoSaved[ConfigCurrent].Potential_Value.." 秒")
end)


-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")


postion_y = postion_y-30

local checkButton_ManaChannel = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 80, postion_y, "法力通道")
local checkButton_LifeChannel = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 180, postion_y, "生命通道")

checkButton_ManaChannel:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].ManaChannel = 1
        MPWarlockDemoSaved[ConfigCurrent].LifeChannel = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].ManaChannel = 0
    end
    checkButton_ManaChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].ManaChannel))
    checkButton_LifeChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].LifeChannel))
end)
checkButton_LifeChannel:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].LifeChannel = 1
        MPWarlockDemoSaved[ConfigCurrent].ManaChannel = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].LifeChannel = 0
    end
    checkButton_ManaChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].ManaChannel))
    checkButton_LifeChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].LifeChannel))
end)





-- 团队诅咒


postion_y = postion_y+10

-- 添加提示内容区域
local TipTextTeam = CatUISettingsWarlockDemo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextTeam:SetPoint("TOPLEFT", CatUISettingsWarlockDemo, "TOPLEFT", 20, postion_y)
TipTextTeam:SetWidth(250)
TipTextTeam:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipTextTeam:SetTextColor(1, 0.8, 0)
TipTextTeam:SetJustifyH("LEFT")
TipTextTeam:SetText("大诅咒配置 (单选)")


postion_y = postion_y-80

-- 创建单选框 - 鲁莽诅咒
local checkButton_CurseRecklessness = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "鲁莽")

-- 创建单选框 - 元素诅咒
local checkButton_CurseElements = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 105, postion_y, "元素")

-- 创建单选框 - 暗影诅咒
local checkButton_CurseShadow = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 190, postion_y, "暗影")

-- 创建单选框 - 厄运诅咒
local checkButton_CurseDoom = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 275, postion_y, "厄运")

-- 创建单选框 - 语言诅咒
local checkButton_CurseTongues = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 360, postion_y, "语言")

-- 创建单选框 - 虚弱诅咒
local checkButton_CurseWeakness = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 445, postion_y, "虚弱")

-- 创建单选框 - 疲劳诅咒
local checkButton_CurseFatigue = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 530, postion_y, "疲劳")


checkButton_CurseRecklessness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseElements:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseShadow:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseDoom:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseTongues:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseWeakness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 1
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseFatigue:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseElements = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 1
    else
        MPWarlockDemoSaved[ConfigCurrent].CurseFatigue = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))

end)








-- 高级


postion_y = postion_y+20

-- 添加提示内容区域
local TipText1 = CatUISettingsWarlockDemo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsWarlockDemo, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100

-- 创建单选框 - 预读暗影箭
local checkButton_FirstShadowBolt = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 暗影箭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstShadowBolt, GetCurrentSaved, "FirstShadowBolt")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPWarlockDemoSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 大诅咒BOSS
local checkButton_CurseBOSS = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 20, postion_y, "非BOSS忽略 大诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseBOSS, GetCurrentSaved, "CurseBOSS")


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPWarlockDemoSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40



-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40


-- 创建单选框 - 生命分流
local checkButton_LifeTap = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动 生命分流")

local slider_LifeTap = MPCreateConfigSlider(ADDON_NAME.."Slider_LifeTap", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -2, 150, 16, 10, 100, 1, 60)

local color_LifeTap = "|cFFFFD100"

-- 值变化时的回调函数
slider_LifeTap:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value = arg1
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value .."%|r")
end)

-- 设置点击事件
checkButton_LifeTap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockDemoSaved[ConfigCurrent].LifeTap = 1
        color_LifeTap = "|cFFFFD100"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value .."%|r")
    else
        MPWarlockDemoSaved[ConfigCurrent].LifeTap = 0
        color_LifeTap = "|cFF888888"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value .."%|r")
    end
end)


-- 生命分流 蓝量百分比
local slider_LifeTap_Mana = MPCreateConfigSlider(ADDON_NAME.."SliderLifeTap_Mana", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -50, 200, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_LifeTap_Mana:SetScript("OnValueChanged", function()
    _G[slider_LifeTap_Mana:GetName().."Text"]:SetText("生命分流 蓝量启动线："..arg1.."%")
    MPWarlockDemoSaved[ConfigCurrent].LifeTap_Mana = arg1
end)





postion_y = postion_y - 40



postion_y = postion_y - 40


-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockDemo, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsWarlockDemo, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetWarlockDemoSettings(ConfigCurrent)
    MPInitWarlockDemoSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsWarlockDemo, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitWarlockDemoSettings()
end)


local MLDButton = MPCreateButton(CatUISettingsWarlockDemo, ADDON_NAME.."ButtonReset", "多线DOT设置", 60, postion_y+120, 120, 22)
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsWarlockDemo, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsWarlockDemo:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsWarlockDemo, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF9482C9/dedps|r [ 1 | 2 | 3 ]   多线Dot |cFF9482C9/MDot|r")



-- 配置文件版本号
local WarlockDemoSettingsUIVersion = 16

function MPResetWarlockDemoSettings(config)

    MPWarlockDemoSaved.Version = WarlockDemoSettingsUIVersion

    -- 基本配置

    MPWarlockDemoSaved[config].CurseAgony = 0
    MPWarlockDemoSaved[config].CurseAgonyBoss = 0
    MPWarlockDemoSaved[config].Corruption = 1
    MPWarlockDemoSaved[config].CorruptionBoss = 0
    MPWarlockDemoSaved[config].Immolate = 1
    MPWarlockDemoSaved[config].Shadowburn = 0
    MPWarlockDemoSaved[config].ShadowburnBoss = 0

    MPWarlockDemoSaved[config].Potential = 1
    MPWarlockDemoSaved[config].Potential_Value = 5
    MPWarlockDemoSaved[config].ManaChannel = 1
    MPWarlockDemoSaved[config].LifeChannel = 0

    MPWarlockDemoSaved[config].PetAttack = 1

    MPWarlockDemoSaved[config].Trinket_Upper = 1
    MPWarlockDemoSaved[config].TUBoss = 0
    MPWarlockDemoSaved[config].Trinket_Below = 1
    MPWarlockDemoSaved[config].TBBoss = 0
    MPWarlockDemoSaved[config].Target = 0
    MPWarlockDemoSaved[config].Overpowering = 1

    MPWarlockDemoSaved[config].CurseRecklessness = 1
    MPWarlockDemoSaved[config].CurseElements = 0
    MPWarlockDemoSaved[config].CurseShadow = 0
    MPWarlockDemoSaved[config].CurseTongues = 0
    MPWarlockDemoSaved[config].CurseWeakness = 0
    MPWarlockDemoSaved[config].CurseFatigue = 0
    MPWarlockDemoSaved[config].CurseDoom = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPWarlockDemoSaved[config].HealthStone = 1
    MPWarlockDemoSaved[config].HealthStone_Value = 30
    MPWarlockDemoSaved[config].HerbalTea = 1
    MPWarlockDemoSaved[config].HerbalTea_Value = 20
    MPWarlockDemoSaved[config].HerbalTeaMana = 0
    MPWarlockDemoSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPWarlockDemoSaved[config].SuperWoW = 1
    MPWarlockDemoSaved[config].UnitXP = 1

    MPWarlockDemoSaved[config].CurseBOSS = 0
    MPWarlockDemoSaved[config].FirstShadowBolt = 0

    MPWarlockDemoSaved[config].RacialTraits = 0
    MPWarlockDemoSaved[config].RacialTraitsBoss = 1
    MPWarlockDemoSaved[config].Soulspeed = 0
    MPWarlockDemoSaved[config].SoulspeedBoss = 1

    MPWarlockDemoSaved[config].LifeTap = 0
    MPWarlockDemoSaved[config].LifeTap_Value = 60
    MPWarlockDemoSaved[config].LifeTap_Mana = 70

    -- 通用
    MPWarlockDemoSaved[config].Power = 0
    MPWarlockDemoSaved[config].Pick = 0

end


local function MPInitWarlockDemoSettingsPart1()
    checkButton_CurseAgony:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseAgony))
    checkButton_CurseAgonyBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseAgonyBoss))
    checkButton_Corruption:SetChecked( MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Corruption) )
    checkButton_CorruptionBoss:SetChecked( MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CorruptionBoss) )
    checkButton_Immolate:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Immolate))
    checkButton_Shadowburn:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Shadowburn))
    checkButton_Target:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Target))
    checkButton_Overpowering:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Overpowering))
    checkButton_Potential:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Potential))
    checkButton_ManaChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].ManaChannel))
    checkButton_LifeChannel:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].LifeChannel))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].PetAttack))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].TBBoss))
    --checkButton_BOSS:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].BOSS))
    checkButton_CurseBOSS:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseBOSS))
    checkButton_ShadowburnBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].ShadowburnBoss))
    checkButton_FirstShadowBolt:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].FirstShadowBolt))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseFatigue))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].CurseDoom))

end

function MPInitWarlockDemoSettings()
    if not MPWarlockDemoSaved then
        MPWarlockDemoSaved = {}

        -- 第一套配置
        if not MPWarlockDemoSaved[1] then
            MPWarlockDemoSaved[1] = {}
            MPResetWarlockDemoSettings(1)
        end

        -- 第二套配置
        if not MPWarlockDemoSaved[2] then
            MPWarlockDemoSaved[2] = {}
            MPResetWarlockDemoSettings(2)
        end

        -- 第三套配置
        if not MPWarlockDemoSaved[3] then
            MPWarlockDemoSaved[3] = {}
            MPResetWarlockDemoSettings(3)
        end
    end

    if MPWarlockDemoSaved.Version ~= WarlockDemoSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[恶魔术宏]当前配置，这是新版插件正常数据更新！|r")
        MPWarlockDemoSaved[1] = {}
        MPWarlockDemoSaved[2] = {}
        MPWarlockDemoSaved[3] = {}
        MPResetWarlockDemoSettings(1)
        MPResetWarlockDemoSettings(2)
        MPResetWarlockDemoSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitWarlockDemoSettingsPart1()

    checkButton_Power:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].Pick))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPWarlockDemoSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value)
    if MPWarlockDemoSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPWarlockDemoSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value)
    if MPWarlockDemoSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockDemoSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_LifeTap:SetChecked(MPWarlockDemoSaved[ConfigCurrent].LifeTap)
    slider_LifeTap:SetValue(MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value)
    if MPWarlockDemoSaved[ConfigCurrent].LifeTap==1 then
        color_LifeTap = "|cFFFFD100"
    else
        color_LifeTap = "|cFF888888"
    end
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockDemoSaved[ConfigCurrent].LifeTap_Value .."%|r")

    slider_LifeTap_Mana:SetValue(MPWarlockDemoSaved[ConfigCurrent].LifeTap_Mana)
    slider_Potential:SetValue(MPWarlockDemoSaved[ConfigCurrent].Potential_Value)

end

