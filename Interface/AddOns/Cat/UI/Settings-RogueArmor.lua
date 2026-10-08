
-- 定义插件名称
local ADDON_NAME = "Settings-RogueArmor"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPRogueArmorSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsRogueArmor = MPCreateFrame(ADDON_NAME.."Frame", 520, 650, "|cFFFFF569设置 - 破甲贼|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsRogueArmor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsRogueArmor, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 切割
local checkButton_SliceDice = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "保持 切割 (1星)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_SliceDice, GetCurrentSaved, "SliceDice")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30


-- 创建单选框 - 破甲
local checkButton_ExposeArmor = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "保持 破甲 (5星破甲)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ExposeArmor, GetCurrentSaved, "ExposeArmor")


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")


postion_y = postion_y-30



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30


-- 创建单选框 - 鬼魅攻击
local checkButton_GhostlyStrike = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "启用 鬼魅攻击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_GhostlyStrike, GetCurrentSaved, "GhostlyStrike")



-- 创建单选框 - 还击
local checkButton_Riposte = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "开启 还击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Riposte, GetCurrentSaved, "Riposte")


postion_y = postion_y-30


-- 创建单选框 - 潜行
local checkButton_Stealth = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "潜行时自动 伏击/绞喉")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Stealth, GetCurrentSaved, "Stealth")






-- 毒药


postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsRogueArmor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsRogueArmor, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(450)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText("毒药配置")




postion_y = postion_y-80

-- 主手
local checkButton_MainHand = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "主手")
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
                MPRogueArmorSaved[ConfigCurrent].MainHand_Value = modes_MainHand[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_MainHand, Dropdown_Init_MainHand)
UIDropDownMenu_SetSelectedID(dropdown_MainHand, 1) -- 默认选中第一项


-- 主手毒药次数
local slider_MainHandCount = MPCreateConfigSlider(ADDON_NAME.."Slider_MainHandCount", CatUISettingsRogueArmor, "TOPLEFT", CatUISettingsRogueArmor, "TOPLEFT", 20, postion_y+10, 220, 16, 1, 100, 1, 50)

-- 值变化时的回调函数
slider_MainHandCount:SetScript("OnValueChanged", function()
    MPRogueArmorSaved[ConfigCurrent].MainHandCount = arg1
    _G[slider_MainHandCount:GetName().."Text"]:SetText("主手毒药次数 <"..arg1.." 补充")
end)



-- 副手
local checkButton_OffHand = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "副手")
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
                MPRogueArmorSaved[ConfigCurrent].OffHand_Value = modes_OffHand[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_OffHand, Dropdown_Init_OffHand)
UIDropDownMenu_SetSelectedID(dropdown_OffHand, 1) -- 默认选中第一项

-- 副手毒药次数
local slider_OffHandCount = MPCreateConfigSlider(ADDON_NAME.."Slider_OffHandCount", CatUISettingsRogueArmor, "TOPLEFT", CatUISettingsRogueArmor, "TOPLEFT", 275, postion_y+10, 220, 16, 1, 100, 1, 50)

-- 值变化时的回调函数
slider_OffHandCount:SetScript("OnValueChanged", function()
    MPRogueArmorSaved[ConfigCurrent].OffHandCount = arg1
    _G[slider_OffHandCount:GetName().."Text"]:SetText("副手毒药次数 <"..arg1.." 补充")
end)


postion_y = postion_y-100

-- 脱战上毒
local checkButton_LeaveFight = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "补毒药 仅在脱离战斗时")
MPBindConfigCheckButton(checkButton_LeaveFight, GetCurrentSaved, "LeaveFight")

-- 覆盖旧毒药
local checkButton_Cover = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "覆盖原武器上不同的毒药")
MPBindConfigCheckButton(checkButton_Cover, GetCurrentSaved, "Cover")







-- 高级



postion_y = postion_y+30

-- 添加提示内容区域
local TipText1 = CatUISettingsRogueArmor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsRogueArmor, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-120


-- 创建单选框 - 死亡标记 Marked
local checkButton_Marked = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "启用 死亡标记")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Marked, GetCurrentSaved, "Marked")
local checkButton_MarkedBoss = MPCreateCheckButtonSmall(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_MarkedBoss, GetCurrentSaved, "MarkedBoss")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPRogueArmorSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueArmorSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPRogueArmorSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 低星破甲
local checkButton_FirstStar = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "启用 低星破填补\n|cFF888888(谨慎使用)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstStar, GetCurrentSaved, "FirstStar")

local slider_FirstStar = MPCreateConfigSlider(ADDON_NAME.."Slider_FirstStar", checkButton_FirstStar, "RIGHT", checkButton_FirstStar, "RIGHT", 270, -2, 150, 16, 1, 4, 1, 1.5)

local color_FirstStar = "|cFFFFD100"

-- 值变化时的回调函数
slider_FirstStar:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPRogueArmorSaved[ConfigCurrent].FirstStar_Value = arg1
    _G[slider_FirstStar:GetName().."Text"]:SetText(color_FirstStar..arg1.."星 破甲|r")
end)




-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueArmorSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPRogueArmorSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y-40

-- 创建单选框 - 低星破甲 boss
local checkButton_FirstStarNoBoss = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 20, postion_y, "低星破填补 仅小怪")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstStarNoBoss, GetCurrentSaved, "FirstStarNoBoss")



-- 创建单选框 - 鞭根块茎
local checkButton_Carrot = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动 鞭根块茎")

local slider_Carrot = MPCreateConfigSlider(ADDON_NAME.."Slider_Carrot", checkButton_Carrot, "RIGHT", checkButton_Carrot, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Carrot = "|cFFFFD100"

-- 值变化时的回调函数
slider_Carrot:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPRogueArmorSaved[ConfigCurrent].Carrot_Value = arg1
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueArmorSaved[ConfigCurrent].Carrot_Value .."%|r")
end)

-- 设置点击事件
checkButton_Carrot:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPRogueArmorSaved[ConfigCurrent].Carrot = 1
        color_Carrot = "|cFFFFD100"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueArmorSaved[ConfigCurrent].Carrot_Value .."%|r")
    else
        MPRogueArmorSaved[ConfigCurrent].Carrot = 0
        color_Carrot = "|cFF888888"
        _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueArmorSaved[ConfigCurrent].Carrot_Value .."%|r")
    end
end)



postion_y = postion_y-40


-- 创建单选框 - 自动打断
local checkButton_Interrupt = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动 打断读条 (SuperWoW)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Interrupt, GetCurrentSaved, "Interrupt")


postion_y = postion_y-40


-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")


postion_y = postion_y-40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsRogueArmor, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsRogueArmor, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")





-- 创建按钮
local myButton = MPCreateButton(CatUISettingsRogueArmor, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetRogueArmorSettings(ConfigCurrent)
    MPInitRogueArmorSettings()
end)

local ConfigButton = MPCreateConfigSelector(CatUISettingsRogueArmor, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitRogueArmorSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsRogueArmor, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsRogueArmor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsRogueArmor, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFFF569/pjz|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local RogueArmorSettingsUIVersion = 14

function MPResetRogueArmorSettings(config)

    MPRogueArmorSaved.Version = RogueArmorSettingsUIVersion

    -- 基本配置

    MPRogueArmorSaved[config].Trinket_Upper = 1
    MPRogueArmorSaved[config].TUBoss = 0
    MPRogueArmorSaved[config].Trinket_Below = 1
    MPRogueArmorSaved[config].TBBoss = 0
    MPRogueArmorSaved[config].Target = 0
    MPRogueArmorSaved[config].Riposte = 0

    MPRogueArmorSaved[config].SliceDice = 1
    MPRogueArmorSaved[config].Eviscerate = 0
    MPRogueArmorSaved[config].GhostlyStrike = 0
    MPRogueArmorSaved[config].Backstab = 1
    MPRogueArmorSaved[config].ExposeArmor = 1
    MPRogueArmorSaved[config].Stealth = 1


    -- 毒药
    MPRogueArmorSaved[config].MainHand = 0
    MPRogueArmorSaved[config].OffHand = 0
    MPRogueArmorSaved[config].MainHand_Value = "溶解毒药 II"
    MPRogueArmorSaved[config].OffHand_Value = "溶解毒药 II"
    MPRogueArmorSaved[config].MainHandCount = 50
    MPRogueArmorSaved[config].OffHandCount = 50
    MPRogueArmorSaved[config].LeaveFight = 0
    MPRogueArmorSaved[config].Cover = 0


    -- 高级配置

    -- 治疗石、糖水茶
    MPRogueArmorSaved[config].HealthStone = 1
    MPRogueArmorSaved[config].HealthStone_Value = 30
    MPRogueArmorSaved[config].HerbalTea = 1
    MPRogueArmorSaved[config].HerbalTea_Value = 20
    MPRogueArmorSaved[config].Carrot = 0
    MPRogueArmorSaved[config].Carrot_Value = 20

    -- SuperWoW,UnitXP
    MPRogueArmorSaved[config].SuperWoW = 1
    MPRogueArmorSaved[config].UnitXP = 0

    MPRogueArmorSaved[config].Marked = 0
    MPRogueArmorSaved[config].MarkedBoss = 1

    MPRogueArmorSaved[config].EvisceratePoint = 5
    MPRogueArmorSaved[config].EviscerateEnergy = 30

    MPRogueArmorSaved[config].Interrupt = 0
    MPRogueArmorSaved[config].RacialTraits = 0
    MPRogueArmorSaved[config].RacialTraitsBoss = 1
    MPRogueArmorSaved[config].Soulspeed = 0
    MPRogueArmorSaved[config].SoulspeedBoss = 1

    MPRogueArmorSaved[config].FirstStar = 0
    MPRogueArmorSaved[config].FirstStar_Value = 3
    MPRogueArmorSaved[config].FirstStarNoBoss = 1

    -- 通用
    MPRogueArmorSaved[config].Power = 0
    MPRogueArmorSaved[config].Pick = 0


end


local function InitRogueArmorSettingsPart1()
    checkButton_SliceDice:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].SliceDice))
    checkButton_GhostlyStrike:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].GhostlyStrike))
    checkButton_ExposeArmor:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].ExposeArmor))
    checkButton_Stealth:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Stealth))
    --checkButton_Eviscerate:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Eviscerate))
    checkButton_Riposte:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Riposte))

    checkButton_Target:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Target))
    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].TBBoss))

    checkButton_Marked:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Marked))
    checkButton_MarkedBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].MarkedBoss))

    checkButton_Interrupt:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Interrupt))
    checkButton_RacialTraits:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_LeaveFight:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].LeaveFight))
    checkButton_Cover:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Cover))

    checkButton_FirstStar:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].FirstStar))
    checkButton_FirstStarNoBoss:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].FirstStarNoBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].Pick))
end

function MPInitRogueArmorSettings()
    if not MPRogueArmorSaved then
        MPRogueArmorSaved = {}

        -- 第一套配置
        if not MPRogueArmorSaved[1] then
            MPRogueArmorSaved[1] = {}
            MPResetRogueArmorSettings(1)
        end

        -- 第二套配置
        if not MPRogueArmorSaved[2] then
            MPRogueArmorSaved[2] = {}
            MPResetRogueArmorSettings(2)
        end

        -- 第三套配置
        if not MPRogueArmorSaved[3] then
            MPRogueArmorSaved[3] = {}
            MPResetRogueArmorSettings(3)
        end
    end

    if MPRogueArmorSaved.Version ~= RogueArmorSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[破甲贼宏]当前配置，这是新版插件正常数据更新！|r")
        MPRogueArmorSaved[1] = {}
        MPRogueArmorSaved[2] = {}
        MPRogueArmorSaved[3] = {}
        MPResetRogueArmorSettings(1)
        MPResetRogueArmorSettings(2)
        MPResetRogueArmorSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitRogueArmorSettingsPart1()




    checkButton_HealthStone:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPRogueArmorSaved[ConfigCurrent].HealthStone_Value)
    if MPRogueArmorSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HealthStone_Value .."%|r")



    checkButton_HerbalTea:SetChecked(MPRogueArmorSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value)
    if MPRogueArmorSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPRogueArmorSaved[ConfigCurrent].HerbalTea_Value .."%|r")


    checkButton_Carrot:SetChecked(MPRogueArmorSaved[ConfigCurrent].Carrot)
    slider_Carrot:SetValue(MPRogueArmorSaved[ConfigCurrent].Carrot_Value)
    if MPRogueArmorSaved[ConfigCurrent].Carrot==1 then
        color_Carrot = "|cFFFFD100"
    else
        color_Carrot = "|cFF888888"
    end
    _G[slider_Carrot:GetName().."Text"]:SetText(color_Carrot.."血线: ".. MPRogueArmorSaved[ConfigCurrent].Carrot_Value .."%|r")


    checkButton_MainHand:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].MainHand))
    for idx_MainHand, data_MainHand in pairs(modes_MainHand) do
        if string.find(data_MainHand.text, MPRogueArmorSaved[ConfigCurrent].MainHand_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_MainHand, data_MainHand.value)
            _G[dropdown_MainHand:GetName().."Text"]:SetText(data_MainHand.text)
        end
    end

    checkButton_OffHand:SetChecked(MPToBoolean(MPRogueArmorSaved[ConfigCurrent].OffHand))
    for idx_OffHand, data_OffHand in pairs(modes_OffHand) do
        if string.find(data_OffHand.text, MPRogueArmorSaved[ConfigCurrent].OffHand_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_OffHand, data_OffHand.value)
            _G[dropdown_OffHand:GetName().."Text"]:SetText(data_OffHand.text)
        end
    end

    slider_MainHandCount:SetValue(MPRogueArmorSaved[ConfigCurrent].MainHandCount)
    _G[slider_MainHandCount:GetName().."Text"]:SetText("主手毒药次数 <"..MPRogueArmorSaved[ConfigCurrent].MainHandCount.." 补充")
    slider_OffHandCount:SetValue(MPRogueArmorSaved[ConfigCurrent].OffHandCount)
    _G[slider_OffHandCount:GetName().."Text"]:SetText("副手毒药次数 <"..MPRogueArmorSaved[ConfigCurrent].OffHandCount.." 补充")

    slider_FirstStar:SetValue(MPRogueArmorSaved[ConfigCurrent].FirstStar_Value)
    --_G[slider_FirstStar:GetName().."Text"]:SetText("副手毒药次数 <"..MPRogueArmorSaved[ConfigCurrent].FirstStar_Value.." 补充")
end

