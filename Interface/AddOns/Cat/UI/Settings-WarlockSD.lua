
-- 定义插件名称
local ADDON_NAME = "Settings-WarlockSD"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPWarlockSDSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsWarlockSD = MPCreateFrame(ADDON_NAME.."Frame", 520, 600, "|cFF9482C9设置 - 暗毁术|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsWarlockSD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsWarlockSD, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 痛苦诅咒
local checkButton_CurseAgony = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseAgony, GetCurrentSaved, "CurseAgony")
local checkButton_CurseAgonyBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CurseAgonyBoss, GetCurrentSaved, "CurseAgonyBoss")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 腐蚀术​
local checkButton_Corruption = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 腐蚀术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Corruption, GetCurrentSaved, "Corruption")
local checkButton_CorruptionBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_CorruptionBoss, GetCurrentSaved, "CorruptionBoss")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 生命虹吸
local checkButton_SiphonLife = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 生命虹吸")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SiphonLife, GetCurrentSaved, "SiphonLife")
local checkButton_SiphonLifeBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SiphonLifeBoss, GetCurrentSaved, "SiphonLifeBoss")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 献祭
local checkButton_Immolate = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 献祭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Immolate, GetCurrentSaved, "Immolate")


-- 创建单选框 - 超越之力
local checkButton_Overpowering = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "开启 超越之力")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Overpowering, GetCurrentSaved, "Overpowering")



postion_y = postion_y-30

-- 创建单选框 - 暗影灼烧
local checkButton_Shadowburn = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "保持 暗影灼烧")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Shadowburn, GetCurrentSaved, "Shadowburn")
local checkButton_ShadowburnBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_ShadowburnBoss, GetCurrentSaved, "ShadowburnBoss")


-- 创建单选框 - 宠物自动攻击
local checkButton_PetAttack = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "宠物自动攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_PetAttack, GetCurrentSaved, "PetAttack")







-- 团队诅咒


postion_y = postion_y-10

-- 添加提示内容区域
local TipTextTeam = CatUISettingsWarlockSD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipTextTeam:SetPoint("TOPLEFT", CatUISettingsWarlockSD, "TOPLEFT", 20, postion_y)
TipTextTeam:SetWidth(250)
TipTextTeam:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipTextTeam:SetTextColor(1, 0.8, 0)
TipTextTeam:SetJustifyH("LEFT")
TipTextTeam:SetText("大诅咒配置 (单选)")


postion_y = postion_y-80

-- 创建单选框 - 鲁莽诅咒
local checkButton_CurseRecklessness = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "鲁莽")

-- 创建单选框 - 元素诅咒
local checkButton_CurseElements = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 105, postion_y, "元素")

-- 创建单选框 - 暗影诅咒
local checkButton_CurseShadow = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 190, postion_y, "暗影")

-- 创建单选框 - 厄运诅咒
local checkButton_CurseDoom = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 275, postion_y, "厄运")

-- 创建单选框 - 语言诅咒
local checkButton_CurseTongues = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 360, postion_y, "语言")

-- 创建单选框 - 虚弱诅咒
local checkButton_CurseWeakness = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 445, postion_y, "虚弱")

-- 创建单选框 - 疲劳诅咒
local checkButton_CurseFatigue = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 530, postion_y, "疲劳")


checkButton_CurseRecklessness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 1
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseElements:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 1
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseShadow:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 1
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseDoom:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 1
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseTongues:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 1
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseWeakness:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 1
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    else
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)

checkButton_CurseFatigue:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].CurseRecklessness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseElements = 0
        MPWarlockSDSaved[ConfigCurrent].CurseShadow = 0
        MPWarlockSDSaved[ConfigCurrent].CurseDoom = 0
        MPWarlockSDSaved[ConfigCurrent].CurseTongues = 0
        MPWarlockSDSaved[ConfigCurrent].CurseWeakness = 0
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 1
    else
        MPWarlockSDSaved[ConfigCurrent].CurseFatigue = 0
    end

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))

end)








-- 高级


postion_y = postion_y+10

-- 添加提示内容区域
local TipText1 = CatUISettingsWarlockSD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsWarlockSD, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-95


-- 创建单选框 - 预读暗影箭
local checkButton_FirstShadowBolt = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 暗影箭")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstShadowBolt, GetCurrentSaved, "FirstShadowBolt")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPWarlockSDSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPWarlockSDSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 大诅咒BOSS
local checkButton_CurseBOSS = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "非BOSS忽略 大诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseBOSS, GetCurrentSaved, "CurseBOSS")




-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPWarlockSDSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 创建单选框 - 邪咒
local checkButton_CurseEvil = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 20, postion_y, "启用 邪咒替换痛苦诅咒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CurseEvil, GetCurrentSaved, "CurseEvil")


-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y - 40



-- 创建单选框 - 生命分流
local checkButton_LifeTap = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 生命分流")

local slider_LifeTap = MPCreateConfigSlider(ADDON_NAME.."Slider_LifeTap", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -2, 150, 16, 10, 100, 1, 60)

local color_LifeTap = "|cFFFFD100"

-- 值变化时的回调函数
slider_LifeTap:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarlockSDSaved[ConfigCurrent].LifeTap_Value = arg1
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockSDSaved[ConfigCurrent].LifeTap_Value .."%|r")
end)

-- 设置点击事件
checkButton_LifeTap:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarlockSDSaved[ConfigCurrent].LifeTap = 1
        color_LifeTap = "|cFFFFD100"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockSDSaved[ConfigCurrent].LifeTap_Value .."%|r")
    else
        MPWarlockSDSaved[ConfigCurrent].LifeTap = 0
        color_LifeTap = "|cFF888888"
        _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockSDSaved[ConfigCurrent].LifeTap_Value .."%|r")
    end
end)


-- 生命分流 蓝量百分比
local slider_LifeTap_Mana = MPCreateConfigSlider(ADDON_NAME.."SliderLifeTap_Mana", checkButton_LifeTap, "RIGHT", checkButton_LifeTap, "RIGHT", 250, -50, 200, 16, 10, 99, 1, 0)

-- 值变化时的回调函数
slider_LifeTap_Mana:SetScript("OnValueChanged", function()
    _G[slider_LifeTap_Mana:GetName().."Text"]:SetText("生命分流 蓝量启动线："..arg1.."%")
    MPWarlockSDSaved[ConfigCurrent].LifeTap_Mana = arg1
end)



postion_y = postion_y - 40


postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋 (爆发类)
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsWarlockSD, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsWarlockSD, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetWarlockSDSettings(ConfigCurrent)
    MPInitWarlockSDSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsWarlockSD, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitWarlockSDSettings()
end)



local MLDButton = MPCreateButton(CatUISettingsWarlockSD, ADDON_NAME.."ButtonReset", "多线DOT设置", 60, postion_y+120, 120, 22)
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsWarlockSD, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsWarlockSD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsWarlockSD, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF9482C9/ahdps|r [ 1 | 2 | 3 ]   多线Dot |cFF9482C9/MDot|r")



-- 配置文件版本号
local WarlockSDSettingsUIVersion = 18

function MPResetWarlockSDSettings(config)

    MPWarlockSDSaved.Version = WarlockSDSettingsUIVersion

    -- 基本配置

    MPWarlockSDSaved[config].CurseAgony = 1
    MPWarlockSDSaved[config].CurseAgonyBoss = 0
    MPWarlockSDSaved[config].Corruption = 1
    MPWarlockSDSaved[config].CorruptionBoss = 0
    MPWarlockSDSaved[config].SiphonLife = 1
    MPWarlockSDSaved[config].SiphonLifeBoss = 0
    MPWarlockSDSaved[config].Immolate = 0
    MPWarlockSDSaved[config].Shadowburn = 0
    MPWarlockSDSaved[config].ShadowburnBoss = 0

    MPWarlockSDSaved[config].PetAttack = 0

    MPWarlockSDSaved[config].Trinket_Upper = 1
    MPWarlockSDSaved[config].TUBoss = 0
    MPWarlockSDSaved[config].Trinket_Below = 1
    MPWarlockSDSaved[config].TBBoss = 0
    MPWarlockSDSaved[config].Target = 0
    MPWarlockSDSaved[config].Overpowering = 0

    MPWarlockSDSaved[config].CurseRecklessness = 0
    MPWarlockSDSaved[config].CurseElements = 0
    MPWarlockSDSaved[config].CurseShadow = 1
    MPWarlockSDSaved[config].CurseTongues = 0
    MPWarlockSDSaved[config].CurseWeakness = 0
    MPWarlockSDSaved[config].CurseFatigue = 0
    MPWarlockSDSaved[config].CurseDoom = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPWarlockSDSaved[config].HealthStone = 1
    MPWarlockSDSaved[config].HealthStone_Value = 30
    MPWarlockSDSaved[config].HerbalTea = 1
    MPWarlockSDSaved[config].HerbalTea_Value = 20
    MPWarlockSDSaved[config].HerbalTeaMana = 0
    MPWarlockSDSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPWarlockSDSaved[config].SuperWoW = 1
    MPWarlockSDSaved[config].UnitXP = 1

    MPWarlockSDSaved[config].CurseBOSS = 0
    MPWarlockSDSaved[config].FirstShadowBolt = 0
    MPWarlockSDSaved[config].CurseEvil = 1

    MPWarlockSDSaved[config].RacialTraits = 0
    MPWarlockSDSaved[config].RacialTraitsBoss = 1
    MPWarlockSDSaved[config].Soulspeed = 0
    MPWarlockSDSaved[config].SoulspeedBoss = 1

    MPWarlockSDSaved[config].LifeTap = 0
    MPWarlockSDSaved[config].LifeTap_Value = 60
    MPWarlockSDSaved[config].LifeTap_Mana = 70

    -- 通用
    MPWarlockSDSaved[config].Power = 0
    MPWarlockSDSaved[config].Pick = 0

end



local function MPInitWarlockSDSettingsPart1()

    checkButton_CurseAgony:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseAgony))
    checkButton_CurseAgonyBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseAgonyBoss))
    checkButton_Corruption:SetChecked( MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Corruption) )
    checkButton_CorruptionBoss:SetChecked( MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CorruptionBoss) )
    checkButton_SiphonLife:SetChecked( MPToBoolean(MPWarlockSDSaved[ConfigCurrent].SiphonLife) )
    checkButton_SiphonLifeBoss:SetChecked( MPToBoolean(MPWarlockSDSaved[ConfigCurrent].SiphonLifeBoss) )
    checkButton_Immolate:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Immolate))
    checkButton_Shadowburn:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Shadowburn))
    checkButton_ShadowburnBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].ShadowburnBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Target))
    checkButton_Overpowering:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Overpowering))
    checkButton_PetAttack:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].PetAttack))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].TBBoss))
    checkButton_CurseBOSS:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseBOSS))
    checkButton_FirstShadowBolt:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].FirstShadowBolt))
    checkButton_CurseEvil:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseEvil))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].SoulspeedBoss))


end

local function MPInitWarlockSDSettingsPart2()

    checkButton_CurseRecklessness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseRecklessness))
    checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseElements))
    checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseShadow))
    checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseTongues))
    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseWeakness))
    checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseFatigue))
    checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].CurseDoom))

    checkButton_Power:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].Pick))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPWarlockSDSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPWarlockSDSaved[ConfigCurrent].HealthStone_Value)
    if MPWarlockSDSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPWarlockSDSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value)
    if MPWarlockSDSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPWarlockSDSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")

    checkButton_LifeTap:SetChecked(MPWarlockSDSaved[ConfigCurrent].LifeTap)
    slider_LifeTap:SetValue(MPWarlockSDSaved[ConfigCurrent].LifeTap_Value)
    if MPWarlockSDSaved[ConfigCurrent].LifeTap==1 then
        color_LifeTap = "|cFFFFD100"
    else
        color_LifeTap = "|cFF888888"
    end
    _G[slider_LifeTap:GetName().."Text"]:SetText(color_LifeTap.."安全血线: ".. MPWarlockSDSaved[ConfigCurrent].LifeTap_Value .."%|r")

    slider_LifeTap_Mana:SetValue(MPWarlockSDSaved[ConfigCurrent].LifeTap_Mana)
end



function MPInitWarlockSDSettings()
    if not MPWarlockSDSaved then
        MPWarlockSDSaved = {}

        -- 第一套配置
        if not MPWarlockSDSaved[1] then
            MPWarlockSDSaved[1] = {}
            MPResetWarlockSDSettings(1)
        end

        -- 第二套配置
        if not MPWarlockSDSaved[2] then
            MPWarlockSDSaved[2] = {}
            MPResetWarlockSDSettings(2)
        end

        -- 第三套配置
        if not MPWarlockSDSaved[3] then
            MPWarlockSDSaved[3] = {}
            MPResetWarlockSDSettings(3)
        end
    end

    if MPWarlockSDSaved.Version ~= WarlockSDSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[暗毁术宏]当前配置，这是新版插件正常数据更新！|r")
        MPWarlockSDSaved[1] = {}
        MPWarlockSDSaved[2] = {}
        MPWarlockSDSaved[3] = {}
        MPResetWarlockSDSettings(1)
        MPResetWarlockSDSettings(2)
        MPResetWarlockSDSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitWarlockSDSettingsPart1()
    MPInitWarlockSDSettingsPart2()

end

