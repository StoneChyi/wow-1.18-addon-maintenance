
-- 定义插件名称
local ADDON_NAME = "Settings-WarriorTank"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPWarriorTankSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsWarriorTank = MPCreateFrame(ADDON_NAME.."Frame", 520, 690, "|cFFC79C6E设置 - 战士坦|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsWarriorTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsWarriorTank, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40


-- 创建单选框 - 防御姿态
local checkButton_Defensive = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "保持 防御姿态")
MPBindConfigCheckButton(checkButton_Defensive, GetCurrentSaved, "Defensive")



-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 战斗怒吼
local checkButton_BattleShout = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "保持 战斗怒吼")
MPBindConfigCheckButton(checkButton_BattleShout, GetCurrentSaved, "BattleShout")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 挫志怒吼
local checkButton_Demoralizing = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "保持 挫志怒吼")
MPBindConfigCheckButton(checkButton_Demoralizing, GetCurrentSaved, "Demoralizing")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")

postion_y = postion_y-30

-- 创建单选框 - 血性狂暴
local checkButton_BerserkerRage = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 血性狂暴")
MPBindConfigCheckButton(checkButton_BerserkerRage, GetCurrentSaved, "BerserkerRage")





-- 创建单选框 - 单体/群体
local checkButton_NearbyEnemies = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动判断 单体/群体 (SuperWoW)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_NearbyEnemies, GetCurrentSaved, "NearbyEnemies")



postion_y = postion_y-30

-- 创建单选框 - 雷霆一击
local checkButton_ThunderClap = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 雷霆一击")
MPBindConfigCheckButton(checkButton_ThunderClap, GetCurrentSaved, "ThunderClap")


postion_y = postion_y-30

-- 创建单选框 - 复仇
local checkButton_Revenge = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 复仇")
MPBindConfigCheckButton(checkButton_Revenge, GetCurrentSaved, "Revenge")

-- 创建单选框 - 主技能
local checkButton_MainSkill = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "开启 盾牌猛击/致死打击/嗜血")
MPBindConfigCheckButton(checkButton_MainSkill, GetCurrentSaved, "MainSkill")

postion_y = postion_y-30

-- 创建单选框 - 震荡猛击
local checkButton_Shockwave = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 震荡猛击")
MPBindConfigCheckButton(checkButton_Shockwave, GetCurrentSaved, "Shockwave")

-- 创建单选框 - 旋风斩
local checkButton_Whirlwind = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "开启 旋风斩")
MPBindConfigCheckButton(checkButton_Whirlwind, GetCurrentSaved, "Whirlwind")


postion_y = postion_y-30

-- 创建单选框 - 破甲攻击
local checkButton_SunderArmor = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 破甲攻击")
MPBindConfigCheckButton(checkButton_SunderArmor, GetCurrentSaved, "SunderArmor")

-- 创建单选框 - 斩杀
local checkButton_Execute = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "开启 斩杀")
MPBindConfigCheckButton(checkButton_Execute, GetCurrentSaved, "Execute")





-- 高级


postion_y = postion_y+20

-- 添加提示内容区域
local TipText1 = CatUISettingsWarriorTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsWarriorTank, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-100


-- 创建单选框 - 自动打断
local checkButton_Interrupt = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动 打断读条 (SuperWoW)")
MPBindConfigCheckButton(checkButton_Interrupt, GetCurrentSaved, "Interrupt")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)



postion_y = postion_y-40


-- 创建单选框 - 压制
local checkButton_Overpower = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动 压制")

local slider_Overpower = MPCreateConfigSlider(ADDON_NAME.."Slider_Overpower", checkButton_Overpower, "RIGHT", checkButton_Overpower, "RIGHT", 244, -2, 160, 16, 10, 100, 1, 90)

local color_Overpower = "|cFFFFD100"

-- 值变化时的回调函数
slider_Overpower:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].Overpower_Value = arg1
    _G[slider_Overpower:GetName().."Text"]:SetText(color_Overpower.."怒气 < ".. arg1)
end)

-- 设置点击事件
checkButton_Overpower:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].Overpower = 1
        color_Overpower = "|cFFFFD100"
        _G[slider_Overpower:GetName().."Text"]:SetText(color_Overpower.."怒气 < ".. MPWarriorTankSaved[ConfigCurrent].Overpower_Value)
    else
        MPWarriorTankSaved[ConfigCurrent].Overpower = 0
        color_Overpower = "|cFF888888"
        _G[slider_Overpower:GetName().."Text"]:SetText(color_Overpower.."怒气 < ".. MPWarriorTankSaved[ConfigCurrent].Overpower_Value)
    end
end)


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)




postion_y = postion_y-40


-- 创建单选框 - 取消拯救
local checkButton_UnSalvation = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动取消 拯救祝福")
MPBindConfigCheckButton(checkButton_UnSalvation, GetCurrentSaved, "UnSalvation")



-- 创建单选框 - 鞭根块茎
local checkButton_Carrot = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 鞭根块茎")

local slider_Carrot = MPCreateConfigSlider(ADDON_NAME.."Slider_Carrot", checkButton_Carrot, "RIGHT", checkButton_Carrot, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 80)

local color_Carrot = "|cFFFFD100"

-- 值变化时的回调函数
slider_Carrot:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].Carrot_Value = arg1
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPWarriorTankSaved[ConfigCurrent].Carrot_Value .."%|r")
end)

-- 设置点击事件
checkButton_Carrot:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].Carrot = 1
        color_Carrot = "|cFFFFD100"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPWarriorTankSaved[ConfigCurrent].Carrot_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].Carrot = 0
        color_Carrot = "|cFF888888"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPWarriorTankSaved[ConfigCurrent].Carrot_Value .."%|r")
    end
end)




postion_y = postion_y-40

-- 创建单选框 - 盾牌格挡
local checkButton_ShieldBlock = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 盾牌格挡")

local slider_ShieldBlock = MPCreateConfigSlider(ADDON_NAME.."Slider_ShieldBlock", checkButton_ShieldBlock, "RIGHT", checkButton_ShieldBlock, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 80)

local color_ShieldBlock = "|cFFFFD100"

-- 值变化时的回调函数
slider_ShieldBlock:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value = arg1
    _G[slider_ShieldBlock:GetName().."Text"]:SetText(color_ShieldBlock.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value .."%|r")
end)

-- 设置点击事件
checkButton_ShieldBlock:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].ShieldBlock = 1
        color_ShieldBlock = "|cFFFFD100"
        _G[slider_ShieldBlock:GetName().."Text"]:SetText(color_ShieldBlock.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].ShieldBlock = 0
        color_ShieldBlock = "|cFF888888"
        _G[slider_ShieldBlock:GetName().."Text"]:SetText(color_ShieldBlock.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value .."%|r")
    end
end)




postion_y = postion_y-40

-- 创建单选框 - 破釜沉舟
local checkButton_LastStand = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 破釜沉舟")

local slider_LastStand = MPCreateConfigSlider(ADDON_NAME.."Slider_LastStand", checkButton_LastStand, "RIGHT", checkButton_LastStand, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 15)

local color_LastStand = "|cFFFFD100"

-- 值变化时的回调函数
slider_LastStand:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].LastStand_Value = arg1
    _G[slider_LastStand:GetName().."Text"]:SetText(color_LastStand.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LastStand_Value .."%|r")
end)

-- 设置点击事件
checkButton_LastStand:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].LastStand = 1
        color_LastStand = "|cFFFFD100"
        _G[slider_LastStand:GetName().."Text"]:SetText(color_LastStand.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LastStand_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].LastStand = 0
        color_LastStand = "|cFF888888"
        _G[slider_LastStand:GetName().."Text"]:SetText(color_LastStand.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LastStand_Value .."%|r")
    end
end)



postion_y = postion_y-40

-- 创建单选框 - 盾墙
local checkButton_ShieldWall = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 盾墙")

local slider_ShieldWall = MPCreateConfigSlider(ADDON_NAME.."Slider_ShieldWall", checkButton_ShieldWall, "RIGHT", checkButton_ShieldWall, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_ShieldWall = "|cFFFFD100"

-- 值变化时的回调函数
slider_ShieldWall:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value = arg1
    _G[slider_ShieldWall:GetName().."Text"]:SetText(color_ShieldWall.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value .."%|r")
end)

-- 设置点击事件
checkButton_ShieldWall:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].ShieldWall = 1
        color_ShieldWall = "|cFFFFD100"
        _G[slider_ShieldWall:GetName().."Text"]:SetText(color_ShieldWall.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].ShieldWall = 0
        color_ShieldWall = "|cFF888888"
        _G[slider_ShieldWall:GetName().."Text"]:SetText(color_ShieldWall.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value .."%|r")
    end
end)


postion_y = postion_y-40

-- 创建单选框 - 生命宝石
local checkButton_LifeJewel = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 生命宝石")

local slider_LifeJewel = MPCreateConfigSlider(ADDON_NAME.."Slider_LifeJewel​", checkButton_LifeJewel, "RIGHT", checkButton_LifeJewel, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_LifeJewel = "|cFFFFD100"

-- 值变化时的回调函数
slider_LifeJewel:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value = arg1
    _G[slider_LifeJewel:GetName().."Text"]:SetText(color_LifeJewel.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value .."%|r")
end)

-- 设置点击事件
checkButton_LifeJewel:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPWarriorTankSaved[ConfigCurrent].LifeJewel = 1
        color_LifeJewel = "|cFFFFD100"
        _G[slider_LifeJewel:GetName().."Text"]:SetText(color_LifeJewel.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value .."%|r")
    else
        MPWarriorTankSaved[ConfigCurrent].LifeJewel = 0
        color_LifeJewel = "|cFF888888"
        _G[slider_LifeJewel:GetName().."Text"]:SetText(color_LifeJewel.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value .."%|r")
    end
end)


postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y - 40

-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")


postion_y = postion_y - 40

-- 创建单选框 - 死亡之愿
local checkButton_DeathWish = MPCreateCheckButton(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 死亡之愿")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_DeathWish, GetCurrentSaved, "DeathWish")
local checkButton_DeathWishBoss = MPCreateCheckButtonSmall(CatUISettingsWarriorTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_DeathWishBoss, GetCurrentSaved, "DeathWishBoss")


postion_y = postion_y+40+40+40+40+40+40+40+40

-- 英勇/顺劈
local slider_HeroicStrike = MPCreateConfigSlider(ADDON_NAME.."SliderHeroicStrike", CatUISettingsWarriorTank, "TOPLEFT", CatUISettingsWarriorTank, "TOPLEFT", 20, postion_y, 220, 16, 10, 100, 1, 50)

-- 值变化时的回调函数
slider_HeroicStrike:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].HeroicStrike = arg1
    _G[slider_HeroicStrike:GetName().."Text"]:SetText("英勇/顺劈 >"..arg1.." 怒气")
end)

postion_y = postion_y - 40


-- 破甲
local slider_SunderArmor = MPCreateConfigSlider(ADDON_NAME.."SliderSunderArmor", CatUISettingsWarriorTank, "TOPLEFT", CatUISettingsWarriorTank, "TOPLEFT", 20, postion_y, 220, 16, 1, 100, 1, 50)

-- 值变化时的回调函数
slider_SunderArmor:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    MPWarriorTankSaved[ConfigCurrent].SunderArmor_Value = arg1
    _G[slider_SunderArmor:GetName().."Text"]:SetText("破甲攻击 >"..arg1.." 怒气")
end)







-- 创建按钮
local myButton = MPCreateButton(CatUISettingsWarriorTank, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetWarriorTankSettings(ConfigCurrent)
    MPInitWarriorTankSettings()
end)

local ConfigButton = MPCreateConfigSelector(CatUISettingsWarriorTank, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitWarriorTankSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsWarriorTank, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsWarriorTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsWarriorTank, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFC79C6E/wtank|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local WarriorTankSettingsUIVersion = 25

function MPResetWarriorTankSettings(config)

    MPWarriorTankSaved.Version = WarriorTankSettingsUIVersion

    -- 基本配置
    MPWarriorTankSaved[config].Defensive = 0
    MPWarriorTankSaved[config].BerserkerRage = 1
    MPWarriorTankSaved[config].BattleShout = 1
    MPWarriorTankSaved[config].Demoralizing = 1
    MPWarriorTankSaved[config].ThunderClap = 0
    MPWarriorTankSaved[config].Shockwave = 1
    MPWarriorTankSaved[config].Revenge = 1
    MPWarriorTankSaved[config].SunderArmor = 1

    MPWarriorTankSaved[config].Trinket_Upper = 1
    MPWarriorTankSaved[config].TUBoss = 0
    MPWarriorTankSaved[config].Trinket_Below = 1
    MPWarriorTankSaved[config].TBBoss = 0
    MPWarriorTankSaved[config].Target = 0
    MPWarriorTankSaved[config].NearbyEnemies = 1

    MPWarriorTankSaved[config].MainSkill = 1
    MPWarriorTankSaved[config].Whirlwind = 1
    MPWarriorTankSaved[config].Execute = 1

    -- 高级配置
    MPWarriorTankSaved[config].HeroicStrike = 50
    MPWarriorTankSaved[config].SunderArmor_Value = 30

    MPWarriorTankSaved[config].Interrupt = 0

    MPWarriorTankSaved[config].UnSalvation = 0

    -- 治疗石、糖水茶
    MPWarriorTankSaved[config].HealthStone = 1
    MPWarriorTankSaved[config].HealthStone_Value = 30
    MPWarriorTankSaved[config].HerbalTea = 1
    MPWarriorTankSaved[config].HerbalTea_Value = 20
    MPWarriorTankSaved[config].Carrot = 0
    MPWarriorTankSaved[config].Carrot_Value = 20
    MPWarriorTankSaved[config].Overpower = 0
    MPWarriorTankSaved[config].Overpower_Value = 30

    MPWarriorTankSaved[config].ShieldBlock = 1
    MPWarriorTankSaved[config].ShieldBlock_Value = 90
    MPWarriorTankSaved[config].LastStand = 0
    MPWarriorTankSaved[config].LastStand_Value = 10
    MPWarriorTankSaved[config].ShieldWall = 0
    MPWarriorTankSaved[config].ShieldWall_Value = 20
    MPWarriorTankSaved[config].LifeJewel = 0
    MPWarriorTankSaved[config].LifeJewel_Value = 30

    -- SuperWoW,UnitXP
    MPWarriorTankSaved[config].SuperWoW = 1
    MPWarriorTankSaved[config].UnitXP = 1

    MPWarriorTankSaved[config].RacialTraits = 0
    MPWarriorTankSaved[config].RacialTraitsBoss = 1
    MPWarriorTankSaved[config].Soulspeed = 0
    MPWarriorTankSaved[config].SoulspeedBoss = 1
    MPWarriorTankSaved[config].DeathWish = 0
    MPWarriorTankSaved[config].DeathWishBoss = 1

    -- 通用
    MPWarriorTankSaved[config].Power = 0
    MPWarriorTankSaved[config].Pick = 0

end


local function InitWarriorTankSettingsPart1()
    checkButton_Defensive:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Defensive))
    checkButton_BerserkerRage:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].BerserkerRage))
    checkButton_BattleShout:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].BattleShout) )
    checkButton_Demoralizing:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Demoralizing) )
    checkButton_ThunderClap:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].ThunderClap) )
    checkButton_Shockwave:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Shockwave) )
    checkButton_Revenge:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Revenge) )
    checkButton_SunderArmor:SetChecked( MPToBoolean(MPWarriorTankSaved[ConfigCurrent].SunderArmor) )

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].TBBoss))

    checkButton_Target:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Target))
    checkButton_NearbyEnemies:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].NearbyEnemies))
    
    checkButton_MainSkill:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].MainSkill))
    checkButton_Whirlwind:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Whirlwind))
    checkButton_Execute:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Execute))

    checkButton_RacialTraits:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_DeathWish:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].DeathWish))
    checkButton_DeathWishBoss:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].DeathWishBoss))


end

local function InitWarriorTankSettingsPart2()
    checkButton_HealthStone:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPWarriorTankSaved[ConfigCurrent].HealthStone_Value)
    if MPWarriorTankSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPWarriorTankSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value)
    if MPWarriorTankSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPWarriorTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_Carrot:SetChecked(MPWarriorTankSaved[ConfigCurrent].Carrot)
    slider_Carrot:SetValue(MPWarriorTankSaved[ConfigCurrent].Carrot_Value)
    if MPWarriorTankSaved[ConfigCurrent].Carrot==1 then
        color_Carrot = "|cFFFFD100"
    else
        color_Carrot = "|cFF888888"
    end
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPWarriorTankSaved[ConfigCurrent].Carrot_Value .."%|r")

    checkButton_Overpower:SetChecked(MPWarriorTankSaved[ConfigCurrent].Overpower)
    slider_Overpower:SetValue(MPWarriorTankSaved[ConfigCurrent].Overpower_Value)
    if MPWarriorTankSaved[ConfigCurrent].Overpower==1 then
        color_Overpower = "|cFFFFD100"
    else
        color_Overpower = "|cFF888888"
    end
    _G[slider_Overpower:GetName().."Text"]:SetText(color_Overpower.."怒气 < ".. MPWarriorTankSaved[ConfigCurrent].Overpower_Value)

end

function MPInitWarriorTankSettings()
    if not MPWarriorTankSaved then
        MPWarriorTankSaved = {}

        -- 第一套配置
        if not MPWarriorTankSaved[1] then
            MPWarriorTankSaved[1] = {}
            MPResetWarriorTankSettings(1)
        end

        -- 第二套配置
        if not MPWarriorTankSaved[2] then
            MPWarriorTankSaved[2] = {}
            MPResetWarriorTankSettings(2)
        end

        -- 第三套配置
        if not MPWarriorTankSaved[3] then
            MPWarriorTankSaved[3] = {}
            MPResetWarriorTankSettings(3)
        end
    end

    if MPWarriorTankSaved.Version ~= WarriorTankSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[战士坦克宏]当前配置，这是新版插件正常数据更新！|r")
        MPWarriorTankSaved[1] = {}
        MPWarriorTankSaved[2] = {}
        MPWarriorTankSaved[3] = {}
        MPResetWarriorTankSettings(1)
        MPResetWarriorTankSettings(2)
        MPResetWarriorTankSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)


    InitWarriorTankSettingsPart1()
    InitWarriorTankSettingsPart2()


    checkButton_ShieldBlock:SetChecked(MPWarriorTankSaved[ConfigCurrent].ShieldBlock)
    slider_ShieldBlock:SetValue(MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value)
    if MPWarriorTankSaved[ConfigCurrent].ShieldBlock==1 then
        color_ShieldBlock = "|cFFFFD100"
    else
        color_ShieldBlock = "|cFF888888"
    end
    _G[slider_ShieldBlock:GetName().."Text"]:SetText(color_ShieldBlock.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldBlock_Value .."%|r")

    checkButton_LastStand:SetChecked(MPWarriorTankSaved[ConfigCurrent].LastStand)
    slider_LastStand:SetValue(MPWarriorTankSaved[ConfigCurrent].LastStand_Value)
    if MPWarriorTankSaved[ConfigCurrent].LastStand==1 then
        color_LastStand = "|cFFFFD100"
    else
        color_LastStand = "|cFF888888"
    end
    _G[slider_LastStand:GetName().."Text"]:SetText(color_LastStand.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LastStand_Value .."%|r")


    checkButton_ShieldWall:SetChecked(MPWarriorTankSaved[ConfigCurrent].ShieldWall)
    slider_ShieldWall:SetValue(MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value)
    if MPWarriorTankSaved[ConfigCurrent].ShieldWall==1 then
        color_ShieldWall = "|cFFFFD100"
    else
        color_ShieldWall = "|cFF888888"
    end
    _G[slider_ShieldWall:GetName().."Text"]:SetText(color_ShieldWall.."血线: ".. MPWarriorTankSaved[ConfigCurrent].ShieldWall_Value .."%|r")


    checkButton_LifeJewel:SetChecked(MPWarriorTankSaved[ConfigCurrent].LifeJewel)
    slider_LifeJewel:SetValue(MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value)
    if MPWarriorTankSaved[ConfigCurrent].LifeJewel==1 then
        color_LifeJewel = "|cFFFFD100"
    else
        color_LifeJewel = "|cFF888888"
    end
    _G[slider_LifeJewel:GetName().."Text"]:SetText(color_LifeJewel.."血线: ".. MPWarriorTankSaved[ConfigCurrent].LifeJewel_Value .."%|r")


    slider_HeroicStrike:SetValue(MPWarriorTankSaved[ConfigCurrent].HeroicStrike)
    _G[slider_HeroicStrike:GetName().."Text"]:SetText("英勇/顺劈 >"..MPWarriorTankSaved[ConfigCurrent].HeroicStrike.." 怒气")

    slider_SunderArmor:SetValue(MPWarriorTankSaved[ConfigCurrent].SunderArmor_Value)
    _G[slider_SunderArmor:GetName().."Text"]:SetText("破甲攻击 >"..MPWarriorTankSaved[ConfigCurrent].SunderArmor_Value.." 怒气")


    checkButton_Interrupt:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Interrupt))
    checkButton_UnSalvation:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].UnSalvation))

    checkButton_Power:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPWarriorTankSaved[ConfigCurrent].Pick))
end

