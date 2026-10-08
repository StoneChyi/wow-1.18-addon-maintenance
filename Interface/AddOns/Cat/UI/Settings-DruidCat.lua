
-- 定义插件名称
local ADDON_NAME = "Settings-DruidCat"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPDruidCatSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsCatWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 690, "|cFFFF7D0A设置 - 猫德|r")

--[[
CatUISettingsCatMini, CatUISettingsCatWindow = MPCreateMainFrame(ADDON_NAME.."Frame", 520, 660, "|cFFFF7D0A猫德|r")

local Skill_Shapeshift = MPSKillButton(CatUISettingsCatMini, -40, "Interface\\Icons\\spell_reshift_2", "重整")
Skill_Shapeshift:SetScript("OnClick", function(self)
    if MPDruidCatSaved[ConfigCurrent].Shapeshift == 0 then
        MPDruidCatSaved[ConfigCurrent].Shapeshift = 1
    else
        MPDruidCatSaved[ConfigCurrent].Shapeshift = 0
    end
    MPInitCatSettings()
end)

local Skill_TigerFury = MPSKillButton(CatUISettingsCatMini, -80, "Interface\\Icons\\Ability_Mount_JungleTiger", "猛虎之怒")
Skill_TigerFury:SetScript("OnClick", function(self)
    if MPDruidCatSaved[ConfigCurrent].TigerFury == 0 then
        MPDruidCatSaved[ConfigCurrent].TigerFury = 1
    else
        MPDruidCatSaved[ConfigCurrent].TigerFury = 0
    end
    MPInitCatSettings()
end)

local Skill_FaerieFire = MPSKillButton(CatUISettingsCatMini, -120, "Interface\\Icons\\Spell_Nature_FaerieFire", "精灵之火")
Skill_FaerieFire:SetScript("OnClick", function(self)
    if MPDruidCatSaved[ConfigCurrent].FaerieFire == 0 then
        MPDruidCatSaved[ConfigCurrent].FaerieFire = 1
    else
        MPDruidCatSaved[ConfigCurrent].FaerieFire = 0
    end
    MPInitCatSettings()
end)

local Skill_Cower = MPSKillButton(CatUISettingsCatMini, -160, "Interface\\Icons\\Ability_Druid_Cower", "畏缩")
Skill_Cower:SetScript("OnClick", function(self)
    if MPDruidCatSaved[ConfigCurrent].Cower == 0 then
        MPDruidCatSaved[ConfigCurrent].Cower = 1
    else
        MPDruidCatSaved[ConfigCurrent].Cower = 0
    end
    MPInitCatSettings()
end)

local Skill_Target = MPSKillButton(CatUISettingsCatMini, -200, "Interface\\Icons\\Ability_Hunter_Pathfinding", "自动锁敌")
Skill_Target:SetScript("OnClick", function(self)
    if MPDruidCatSaved[ConfigCurrent].Target == 0 then
        MPDruidCatSaved[ConfigCurrent].Target = 1
    else
        MPDruidCatSaved[ConfigCurrent].Target = 0
    end
    MPInitCatSettings()
end)
]]



local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsCatWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)


local postion_y = postion_y-40

-- 创建单选框 - 变身回能
local checkButton_Shapeshift = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用 重整 (变身回能)")
checkButton_Shapeshift:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Shapeshift = 1
    else
        MPDruidCatSaved[ConfigCurrent].Shapeshift = 0
    end
    MPInitCatSettings()
end)



-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")


postion_y = postion_y-30

-- 创建单选框 - 猛虎之怒
local checkButton_TigerFury = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 猛虎之怒")
checkButton_TigerFury:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].TigerFury = 1
    else
        MPDruidCatSaved[ConfigCurrent].TigerFury = 0
    end
    MPInitCatSettings()
end)


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")


postion_y = postion_y-30

-- 创建单选框 - 精灵之火
local checkButton_FaerieFire = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 精灵之火")
checkButton_FaerieFire:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].FaerieFire = 1
    else
        MPDruidCatSaved[ConfigCurrent].FaerieFire = 0
    end
    MPInitCatSettings()
end)


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")

postion_y = postion_y-30


-- 创建单选框 - 潜行
local checkButton_Prowl = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "潜行时自动 突袭/毁灭")
MPBindConfigCheckButton(checkButton_Prowl, GetCurrentSaved, "Prowl")


-- 创建单选框 - 畏缩
local checkButton_Cower = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 畏缩 (内置仇恨判断)")
checkButton_Cower:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Cower = 1
    else
        MPDruidCatSaved[ConfigCurrent].Cower = 0
    end
    MPInitCatSettings()
end)





-- 高级


postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsCatWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-70

--[[
-- 创建单选框 - UnitXP
local checkButton_UnitXP = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "启用UnitXP模组 (朝向判断)")
MPBindConfigCheckButton(checkButton_UnitXP, GetCurrentSaved, "UnitXP")
]]

-- 阿莎曼之怒
local checkButton_Ashamane = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "阿莎曼之怒 (T3.5特性倾斜)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Ashamane, GetCurrentSaved, "Ashamane")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCatSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCatSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPDruidCatSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCatSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)



postion_y = postion_y-40




-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidCatSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCatSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCatSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPDruidCatSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCatSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 树皮术
local checkButton_Barkskin = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 树皮术")

local slider_Barkskin = MPCreateConfigSlider(ADDON_NAME.."Slider_Barkskin", checkButton_Barkskin, "RIGHT", checkButton_Barkskin, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Barkskin = "|cFFFFD100"

-- 值变化时的回调函数
slider_Barkskin:SetScript("OnValueChanged", function()
    --print("Berserk当前值:", arg1)
    MPDruidCatSaved[ConfigCurrent].Barkskin_Value = arg1
    _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_Barkskin:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Barkskin = 1
        color_Barkskin = "|cFFFFD100"
        _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidCatSaved[ConfigCurrent].Barkskin_Value .."%|r")
    else
        MPDruidCatSaved[ConfigCurrent].Barkskin = 0
        color_Barkskin = "|cFF888888"
        _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidCatSaved[ConfigCurrent].Barkskin_Value .."%|r")
    end
end)




-- 双流血

local ripBack = CreateFrame("Frame", nil, CatUISettingsCatWindow)
ripBack:SetWidth(240)
ripBack:SetHeight(170)
ripBack:SetPoint("TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 10, postion_y+80)
ripBack:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ripBack:SetBackdropColor(0.1, 0.1, 0.2, 0.45)

local ripBackText = ripBack:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ripBackText:SetPoint("TOPLEFT", ripBack, "TOPLEFT", 0, 8)
ripBackText:SetWidth(250)
ripBackText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
ripBackText:SetTextColor(1, 1, 1)
ripBackText:SetJustifyH("CENTER")
ripBackText:SetText("双流血")


postion_y = postion_y+50

-- 撕咬星
local slider_Ferocious = MPCreateConfigSlider(ADDON_NAME.."SliderFerocious", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 15, postion_y, 110, 16, 1, 5, 1, 0)

-- 值变化时的回调函数
slider_Ferocious:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].Ferocious_Bite = arg1
    _G[slider_Ferocious:GetName().."Text"]:SetText("撕咬: ".. arg1 .."星")
end)


-- 撕咬 能量
local slider_Ferocious_Value = MPCreateConfigSlider(ADDON_NAME.."SliderFerocious_Value", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 135, postion_y, 110, 16, 36, 100, 1, 50)

-- 值变化时的回调函数
slider_Ferocious_Value:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].Ferocious_Value = arg1

    _G[slider_Ferocious_Value:GetName().."Text"]:SetText("撕咬<"..arg1.."能量")
end)




postion_y = postion_y-40

-- 撕扯星
local slider_Rip_Bite = MPCreateConfigSlider(ADDON_NAME.."SliderRip_Bite", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 15, postion_y, 110, 16, 1, 5, 1, 0)

-- 值变化时的回调函数
slider_Rip_Bite:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].Rip_Bite = arg1
    _G[slider_Rip_Bite:GetName().."Text"]:SetText("撕扯: ".. arg1 .."星")
end)



-- 撕扯界限
local slider_Rip = MPCreateConfigSlider(ADDON_NAME.."SliderRip", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 135, postion_y, 110, 16, 0, 20000, 1000, 7100)


-- 值变化时的回调函数
slider_Rip:SetScript("OnValueChanged", function()
    --print("Rip当前值:", arg1)
    MPDruidCatSaved[ConfigCurrent].OutHPRip = arg1
    _G[slider_Rip:GetName().."Text"]:SetText("<".. arg1/1000 .."k不撕扯")
end)

-- 设置悬停提示
slider_Rip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddLine("目标血量过低，不足撕扯跳伤害时间，提前凶猛撕咬", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

slider_Rip:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

postion_y = postion_y-40

-- 变身 双流血
local slider_BleedModeShapeshift = MPCreateConfigSlider(ADDON_NAME.."SliderBleedModeShapeshift", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 15, postion_y, 110, 16, 10, 50, 1, 0)

-- 值变化时的回调函数
slider_BleedModeShapeshift:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].BleedModeShapeshift = arg1

    _G[slider_BleedModeShapeshift:GetName().."Text"]:SetText("变身<"..arg1.."能量")
end)


postion_y = postion_y-160




-- BOSS
local checkButton_BOSS = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y+30, "非BOSS级 禁用撕扯")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_BOSS, GetCurrentSaved, "BOSS")


-- 背刺流

postion_y = postion_y+75

local ShredBack = CreateFrame("Frame", nil, CatUISettingsCatWindow)
ShredBack:SetWidth(240)
ShredBack:SetHeight(100)
ShredBack:SetPoint("TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 10, postion_y)
ShredBack:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ShredBack:SetBackdropColor(0.1, 0.1, 0.2, 0.45)

local ShredBackText = ShredBack:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ShredBackText:SetPoint("TOPLEFT", ShredBack, "TOPLEFT", 0, 8)
ShredBackText:SetWidth(250)
ShredBackText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") -- 使用OUTLINE参数
ShredBackText:SetTextColor(1, 1, 1)
ShredBackText:SetJustifyH("CENTER")
ShredBackText:SetText("背刺流")

postion_y = postion_y-30

-- 背刺撕咬星
local slider_ShredFerocious = MPCreateConfigSlider(ADDON_NAME.."SliderShredFerocious", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 15, postion_y, 110, 16, 1, 5, 1, 0)

-- 值变化时的回调函数
slider_ShredFerocious:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].ShredFerocious_Bite = arg1
    _G[slider_ShredFerocious:GetName().."Text"]:SetText("撕咬: ".. arg1 .."星")
end)


-- 背刺撕咬 能量
local slider_ShredFerocious_Value = MPCreateConfigSlider(ADDON_NAME.."SliderShredFerocious_Value", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 135, postion_y, 110, 16, 36, 100, 1, 0)

-- 值变化时的回调函数
slider_ShredFerocious_Value:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].ShredFerocious_Value = arg1

    _G[slider_ShredFerocious_Value:GetName().."Text"]:SetText("撕咬<"..arg1.."能量")
end)

postion_y = postion_y-40

-- 变身 背刺流
local slider_ShredModeShapeshift = MPCreateConfigSlider(ADDON_NAME.."SliderShredModeShapeshift", CatUISettingsCatWindow, "TOPLEFT", CatUISettingsCatWindow, "TOPLEFT", 15, postion_y, 110, 16, 10, 50, 1, 0)

-- 值变化时的回调函数
slider_ShredModeShapeshift:SetScript("OnValueChanged", function()
    MPDruidCatSaved[ConfigCurrent].ShredModeShapeshift = arg1

    _G[slider_ShredModeShapeshift:GetName().."Text"]:SetText("变身<"..arg1 .."能量")
end)


postion_y = postion_y-190

local checkButton_Style1 = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "仅爪击")
local checkButton_Style2 = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 140, postion_y, "均衡 朝向自动")
postion_y = postion_y-30
local checkButton_Style4 = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 20, postion_y, "仅撕碎")
local checkButton_Style3 = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 140, postion_y, "均衡 偏向撕碎")
checkButton_Style1:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Style = 1
    end
    checkButton_Style1:SetChecked(MPDruidCatSaved[ConfigCurrent].Style)
    checkButton_Style2:SetChecked(false)
    checkButton_Style3:SetChecked(false)
    checkButton_Style4:SetChecked(false)
end)
checkButton_Style2:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Style = 2
    end
    checkButton_Style1:SetChecked(false)
    checkButton_Style2:SetChecked(MPDruidCatSaved[ConfigCurrent].Style)
    checkButton_Style3:SetChecked(false)
    checkButton_Style4:SetChecked(false)
end)
checkButton_Style3:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Style = 3
    end
    checkButton_Style1:SetChecked(false)
    checkButton_Style2:SetChecked(false)
    checkButton_Style3:SetChecked(MPDruidCatSaved[ConfigCurrent].Style)
    checkButton_Style4:SetChecked(false)
end)
checkButton_Style4:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCatSaved[ConfigCurrent].Style = 4
    end
    checkButton_Style1:SetChecked(false)
    checkButton_Style2:SetChecked(false)
    checkButton_Style3:SetChecked(false)
    checkButton_Style4:SetChecked(MPDruidCatSaved[ConfigCurrent].Style)
end)




postion_y = postion_y+365


-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 魂能之速")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y-40

-- 献祭之油
local checkButton_Sacrificial = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 献祭之油 (SuperWoW)")
checkButton_Sacrificial:Hide()
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Sacrificial, GetCurrentSaved, "Sacrificial")


-- 获取纹理元素（兼容所有版本）
local function GetDownMenuTex(dropdownIn, part)
    return _G[dropdownIn:GetName()..part.."Texture"] or _G[dropdownIn:GetName()..part]
end


postion_y = postion_y-60

-- 创建单选框 - 神像舞
local checkButton_Idol_Dance = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButtonUnSalvation", 340, postion_y, "神像舞 (正常 <-> 终结技)")
MPBindConfigCheckButton(checkButton_Idol_Dance, GetCurrentSaved, "Idol_Dance")


-- 创建下拉菜单
local dropdown_Idol_Dance_Low = CreateFrame("Button", ADDON_NAME.."Dropdown_Idol_Dance_Low", checkButton_Idol_Dance, "UIDropDownMenuTemplate")
dropdown_Idol_Dance_Low:SetPoint("TOPLEFT", checkButton_Idol_Dance, "TOPLEFT", -12, -30)

local middle_Idol_Dance_Low = GetDownMenuTex(dropdown_Idol_Dance_Low, "Middle")
middle_Idol_Dance_Low:SetWidth(110) -- 主宽度
middle_Idol_Dance_Low:SetHeight(60) -- 主宽度

-- 定义选项（带固定索引的表）
local modes_Idol_Dance_Low = {
    [1] = {text = "|cFF0070DD凶猛神像|r", item="凶猛神像", value = 1},
    [2] = {text = "|cFF0070DD野蛮神像|r", item="野蛮神像", value = 2},
    [3] = {text = "|cFF9D38C8月牙神像|r", item="月牙神像", value = 3},
    [4] = {text = "|cFF9D38C8狂野变形者神像|r", item="狂野变形者神像", value = 4},
    [5] = {text = "|cFF9D38C8酸蚀神像|r", item="酸蚀神像", value = 5},
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Idol_Dance_Low()
    for idx, data in pairs(modes_Idol_Dance_Low) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_Low, index)
                MPDruidCatSaved[ConfigCurrent].Idol_Dance_Low = modes_Idol_Dance_Low[index].item
                --message("选择："..modes_Idol_Dance_Low[index].text)
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Idol_Dance_Low, Dropdown_Init_Idol_Dance_Low)
UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_Low, 1) -- 默认选中第一项



-- 创建下拉菜单
local dropdown_Idol_Dance_High = CreateFrame("Button", ADDON_NAME.."CatModeDropdown_Idol_Dance_High", checkButton_Idol_Dance, "UIDropDownMenuTemplate")
dropdown_Idol_Dance_High:SetPoint("TOPLEFT", checkButton_Idol_Dance, "TOPLEFT", 130, -30)

local middle_Idol_Dance_High = GetDownMenuTex(dropdown_Idol_Dance_High, "Middle")
middle_Idol_Dance_High:SetWidth(110) -- 主宽度
middle_Idol_Dance_High:SetHeight(60) -- 主宽度



-- 定义选项（带固定索引的表）
local modes_Idol_Dance_High = {
    [1] = {text = "|cFF9D38C8腐败翡翠神像|r", item="腐败翡翠神像", value = 1},
    [2] = {text = "|cFF9D38C8撕裂神像|r", item="撕裂神像", value = 2},
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Idol_Dance_High()
    for idx, data in pairs(modes_Idol_Dance_High) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_High, index)
                MPDruidCatSaved[ConfigCurrent].Idol_Dance_High = modes_Idol_Dance_High[index].item
                --message("选择："..modes_Idol_Dance_High[index].text)
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Idol_Dance_High, Dropdown_Init_Idol_Dance_High)
UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_High, 1) -- 默认选中第一项






postion_y = postion_y-80

-- 创建单选框 - 随目标神像
local checkButton_Swap_Idol = MPCreateCheckButton(CatUISettingsCatWindow, ADDON_NAME.."CheckButtonUnSalvation", 340, postion_y, "随目标神像 (是否吃流血)")
MPBindConfigCheckButton(checkButton_Swap_Idol, GetCurrentSaved, "Target_Swap_Idol")



-- 创建下拉菜单
local dropdown_Target_Swap_Idol_Bleed = CreateFrame("Button", ADDON_NAME.."Dropdown_Swap_Idol_Bleed", checkButton_Swap_Idol, "UIDropDownMenuTemplate")
dropdown_Target_Swap_Idol_Bleed:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 130, -30)

local middle_Target_Swap_Idol_Bleed = GetDownMenuTex(dropdown_Target_Swap_Idol_Bleed, "Middle")
middle_Target_Swap_Idol_Bleed:SetWidth(110) -- 主宽度
middle_Target_Swap_Idol_Bleed:SetHeight(60) -- 主宽度



-- 定义选项（带固定索引的表）
local modes_Target_Swap_Idol_Bleed = {
    [1] = {text = "|cFF0070DD凶猛神像|r", item="凶猛神像", value = 1},
    [2] = {text = "|cFF0070DD野蛮神像|r", item="野蛮神像", value = 2},
    [3] = {text = "|cFF0070DD常青神像|r",  item="常青神像", value = 3},
    [4] = {text = "|cFF9D38C8月牙神像|r", item="月牙神像", value = 4},
    [5] = {text = "|cFF9D38C8撕裂神像|r", item="撕裂神像", value = 5},
    [6] = {text = "|cFF9D38C8腐败翡翠神像|r", item="腐败翡翠神像", value = 6},
    [7] = {text = "|cFF9D38C8狂野变形者神像|r", item="狂野变形者神像", value = 7},
    [8] = {text = "|cFF9D38C8酸蚀神像|r", item="酸蚀神像", value = 8},
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Target_Swap_Idol_Bleed()
    for idx, data in pairs(modes_Target_Swap_Idol_Bleed) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bleed, index)
                MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Bleed = modes_Target_Swap_Idol_Bleed[index].item
                --message("选择："..modes_Target_Swap_Idol_Bleed[index].text)
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Target_Swap_Idol_Bleed, Dropdown_Init_Target_Swap_Idol_Bleed)
UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bleed, 1) -- 默认选中第一项

local Text_Swap_Idol_Bleed = checkButton_Swap_Idol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Text_Swap_Idol_Bleed:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 90, -35)
Text_Swap_Idol_Bleed:SetFont("Fonts\\FRIZQT__.TTF", 14)
Text_Swap_Idol_Bleed:SetText("|cFFFFFFFF吃流血|r")



-- 创建下拉菜单
local dropdown_Target_Swap_Idol_Shred = CreateFrame("Button", ADDON_NAME.."Dropdown_Swap_Idol_Shred", checkButton_Swap_Idol, "UIDropDownMenuTemplate")
dropdown_Target_Swap_Idol_Shred:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 130, -60)

local middle_Target_Swap_Idol_Shred = GetDownMenuTex(dropdown_Target_Swap_Idol_Shred, "Middle")
middle_Target_Swap_Idol_Shred:SetWidth(110) -- 主宽度
middle_Target_Swap_Idol_Shred:SetHeight(60) -- 主宽度



-- 定义选项（带固定索引的表）
local modes_Target_Swap_Idol_Shred = {
    [1] = {text = "|cFF0070DD凶猛神像|r", item="凶猛神像", value = 1},
    [2] = {text = "|cFF0070DD野蛮神像|r", item="野蛮神像", value = 2},
    [3] = {text = "|cFF0070DD常青神像|r",  item="常青神像", value = 3},
    [4] = {text = "|cFF9D38C8月牙神像|r", item="月牙神像", value = 4},
    [5] = {text = "|cFF9D38C8撕裂神像|r", item="撕裂神像", value = 5},
    [6] = {text = "|cFF9D38C8腐败翡翠神像|r", item="腐败翡翠神像", value = 6},
    [7] = {text = "|cFF9D38C8狂野变形者神像|r", item="狂野变形者神像", value = 7},
    [8] = {text = "|cFF9D38C8酸蚀神像|r", item="酸蚀神像", value = 8},
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Target_Swap_Idol_Shred()
    for idx, data in pairs(modes_Target_Swap_Idol_Shred) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Shred, index)
                MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Shred = modes_Target_Swap_Idol_Shred[index].item
                --message("选择："..modes_Target_Swap_Idol_Shred[index].text)
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Target_Swap_Idol_Shred, Dropdown_Init_Target_Swap_Idol_Shred)
UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Shred, 4) -- 默认选中第一项

local Text_Swap_Idol_Shred = checkButton_Swap_Idol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Text_Swap_Idol_Shred:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 90, -65)
Text_Swap_Idol_Shred:SetFont("Fonts\\FRIZQT__.TTF", 14)
Text_Swap_Idol_Shred:SetText("|cFFFFFFFF不吃流血|r")





-- 创建下拉菜单
local dropdown_Target_Swap_Idol_Bear = CreateFrame("Button", ADDON_NAME.."Dropdown_Swap_Idol_Bear", checkButton_Swap_Idol, "UIDropDownMenuTemplate")
dropdown_Target_Swap_Idol_Bear:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 130, -90)

local middle_Target_Swap_Idol_Bear = GetDownMenuTex(dropdown_Target_Swap_Idol_Bear, "Middle")
middle_Target_Swap_Idol_Bear:SetWidth(110) -- 主宽度
middle_Target_Swap_Idol_Bear:SetHeight(60) -- 主宽度



-- 定义选项（带固定索引的表）
local modes_Target_Swap_Idol_Bear = {
    [1] = {text = "|cFF0070DD蛮兽神像|r", item="野蛮神像", value = 1},
    [2] = {text = "|cFF0070DD常青神像|r",  item="常青神像", value = 2},
    [3] = {text = "|cFF9D38C8月牙神像|r", item="月牙神像", value = 3},
    [4] = {text = "|cFF9D38C8狂野变形者神像|r", item="狂野变形者神像", value = 4},
    [5] = {text = "|cFF9D38C8酸蚀神像|r", item="酸蚀神像", value = 5},
--    [6] = {text = "狂野变形者神像",   value = 6}
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Target_Swap_Idol_Bear()
    for idx, data in pairs(modes_Target_Swap_Idol_Bear) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bear, index)
                MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Bear = modes_Target_Swap_Idol_Bear[index].item
                --message("选择："..modes_Target_Swap_Idol_Bear[index].text)
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Target_Swap_Idol_Bear, Dropdown_Init_Target_Swap_Idol_Bear)
UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bear, 4) -- 默认选中第一项

local Text_Swap_Idol_Bear = checkButton_Swap_Idol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Text_Swap_Idol_Bear:SetPoint("TOPLEFT", checkButton_Swap_Idol, "TOPLEFT", 90, -95)
Text_Swap_Idol_Bear:SetFont("Fonts\\FRIZQT__.TTF", 14)
Text_Swap_Idol_Bear:SetText("|cFFFFFFFF熊形态|r")





local myButton = MPCreateButton(CatUISettingsCatWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetCatSettings(ConfigCurrent)
    MPInitCatSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsCatWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitCatSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsCatWindow, ADDON_NAME, GetCurrentSaved)




-- 添加提示内容区域
local TipText = CatUISettingsCatWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsCatWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 全自动 |cFFFF7D0A/catdps |r[ 1 | 2 | 3 ]  背刺流 |cFFFF7D0A/catshred |r[ 1 | 2 | 3 ]")



-- 通用部分
--local public = MPSettingPublic(CatUISettingsCatWindow)


-- 配置文件版本号
local CatSettingsUIVersion = 30

function MPResetCatSettings(config)

    MPDruidCatSaved.Version = CatSettingsUIVersion

    -- 基本配置
    MPDruidCatSaved[config].Shapeshift = 1
    MPDruidCatSaved[config].TigerFury = 1
    MPDruidCatSaved[config].FaerieFire = 1
    MPDruidCatSaved[config].Prowl = 1
    MPDruidCatSaved[config].Trinket_Upper = 1
    MPDruidCatSaved[config].TUBoss = 0
    MPDruidCatSaved[config].Trinket_Below = 1
    MPDruidCatSaved[config].TBBoss = 0
    MPDruidCatSaved[config].Target = 0
    MPDruidCatSaved[config].Cower = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPDruidCatSaved[config].HealthStone = 1
    MPDruidCatSaved[config].HealthStone_Value = 30
    MPDruidCatSaved[config].HerbalTea = 1
    MPDruidCatSaved[config].HerbalTea_Value = 20
    MPDruidCatSaved[config].Barkskin = 0
    MPDruidCatSaved[config].Barkskin_Value = 30

    -- SuperWoW,UnitXP
    MPDruidCatSaved[config].SuperWoW = 1
    MPDruidCatSaved[config].UnitXP = 0

    -- 参数
    MPDruidCatSaved[config].Ferocious_Bite = 5
    MPDruidCatSaved[config].Ferocious_Value = 53
    MPDruidCatSaved[config].BleedModeShapeshift = 20
    MPDruidCatSaved[config].Rip_Bite = 5
    MPDruidCatSaved[config].OutHPRip = 0
    MPDruidCatSaved[config].HighShred = 1
    MPDruidCatSaved[config].HighShred_Value = 68
    MPDruidCatSaved[config].Style = 2

    MPDruidCatSaved[config].ShredFerocious_Bite = 3
    MPDruidCatSaved[config].ShredFerocious_Value = 55
    MPDruidCatSaved[config].ShredModeShapeshift = 25

    MPDruidCatSaved[config].Ashamane = 0
    MPDruidCatSaved[config].Soulspeed = 0
    MPDruidCatSaved[config].SoulspeedBoss = 1
    MPDruidCatSaved[config].Sacrificial = 0

    MPDruidCatSaved[config].BOSS = 0

    -- 神像相关
    MPDruidCatSaved[config].Idol_Dance = 0
    MPDruidCatSaved[config].Idol_Dance_Point = 4
    MPDruidCatSaved[config].Idol_Dance_Low = "凶猛神像"
    MPDruidCatSaved[config].Idol_Dance_High = "撕裂神像"

    MPDruidCatSaved[config].Target_Swap_Idol = 0
    MPDruidCatSaved[config].Target_Swap_Idol_Bleed = "凶猛神像"
    MPDruidCatSaved[config].Target_Swap_Idol_Shred = "撕裂神像"
    MPDruidCatSaved[config].Target_Swap_Idol_Bear = "蛮兽神像"


    -- 通用
    MPDruidCatSaved[config].Power = 0
    MPDruidCatSaved[config].Pick = 0

end


local function CatSettingsPart1()
    checkButton_Shapeshift:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Shapeshift))
    checkButton_TigerFury:SetChecked( MPToBoolean(MPDruidCatSaved[ConfigCurrent].TigerFury) )
    checkButton_FaerieFire:SetChecked( MPToBoolean(MPDruidCatSaved[ConfigCurrent].FaerieFire) )

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].TBBoss))

    checkButton_Target:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Target))
    checkButton_Prowl:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Prowl))
    checkButton_Cower:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Cower))

    --checkButton_UnitXP:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].UnitXP))

    checkButton_HealthStone:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPDruidCatSaved[ConfigCurrent].HealthStone_Value)
    if MPDruidCatSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCatSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPDruidCatSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPDruidCatSaved[ConfigCurrent].HerbalTea_Value)
    if MPDruidCatSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCatSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_Barkskin:SetChecked(MPDruidCatSaved[ConfigCurrent].Barkskin)
    slider_Barkskin:SetValue(MPDruidCatSaved[ConfigCurrent].Barkskin_Value)
    if MPDruidCatSaved[ConfigCurrent].Barkskin==1 then
        color_Barkskin = "|cFFFFD100"
    else
        color_Barkskin = "|cFF888888"
    end
    _G[slider_Barkskin:GetName().."Text"]:SetText(color_Barkskin.."血线: ".. MPDruidCatSaved[ConfigCurrent].Barkskin_Value .."%|r")

end

local function CatSettingsPart2()
    slider_Ferocious:SetValue(MPDruidCatSaved[ConfigCurrent].Ferocious_Bite)
    slider_Rip_Bite:SetValue(MPDruidCatSaved[ConfigCurrent].Rip_Bite)
    slider_Ferocious_Value:SetValue(MPDruidCatSaved[ConfigCurrent].Ferocious_Value)
    slider_BleedModeShapeshift:SetValue(MPDruidCatSaved[ConfigCurrent].BleedModeShapeshift)
    slider_Rip:SetValue(MPDruidCatSaved[ConfigCurrent].OutHPRip)

    slider_ShredFerocious:SetValue(MPDruidCatSaved[ConfigCurrent].ShredFerocious_Bite)
    slider_ShredFerocious_Value:SetValue(MPDruidCatSaved[ConfigCurrent].ShredFerocious_Value)
    slider_ShredModeShapeshift:SetValue(MPDruidCatSaved[ConfigCurrent].ShredModeShapeshift)


    if MPDruidCatSaved[ConfigCurrent].Style==1 then
        checkButton_Style1:SetChecked(true)
    else
        checkButton_Style1:SetChecked(false)
    end
    if MPDruidCatSaved[ConfigCurrent].Style==2 then
        checkButton_Style2:SetChecked(true)
    else
        checkButton_Style2:SetChecked(false)
    end
    if MPDruidCatSaved[ConfigCurrent].Style==3 then
        checkButton_Style3:SetChecked(true)
    else
        checkButton_Style3:SetChecked(false)
    end
    if MPDruidCatSaved[ConfigCurrent].Style==4 then
        checkButton_Style4:SetChecked(true)
    else
        checkButton_Style4:SetChecked(false)
    end



    checkButton_Idol_Dance:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Idol_Dance))

    for idx_Idol_Dance_Low, data_Idol_Dance_Low in pairs(modes_Idol_Dance_Low) do
        if string.find(data_Idol_Dance_Low.text,MPDruidCatSaved[ConfigCurrent].Idol_Dance_Low) then
            UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_Low, data_Idol_Dance_Low.value)
            _G[dropdown_Idol_Dance_Low:GetName().."Text"]:SetText(data_Idol_Dance_Low.text)
        end
    end

    for idx_Idol_Dance_High, data_Idol_Dance_High in pairs(modes_Idol_Dance_High) do
        if string.find(data_Idol_Dance_High.text,MPDruidCatSaved[ConfigCurrent].Idol_Dance_High) then
            UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_High, modes_Idol_Dance_High[idx_Idol_Dance_High].value)
            _G[dropdown_Idol_Dance_High:GetName().."Text"]:SetText(data_Idol_Dance_High.text)
        end
    end

    

    checkButton_Swap_Idol:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol))

    for idx_Target_Swap_Idol_Bleed, data_Target_Swap_Idol_Bleed in pairs(modes_Target_Swap_Idol_Bleed) do
        if string.find(data_Target_Swap_Idol_Bleed.text,MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Bleed) then
            UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bleed, data_Target_Swap_Idol_Bleed.value)
            _G[dropdown_Target_Swap_Idol_Bleed:GetName().."Text"]:SetText(data_Target_Swap_Idol_Bleed.text)
        end
    end

    for idx_Target_Swap_Idol_Shred, data_Target_Swap_Idol_Shred in pairs(modes_Target_Swap_Idol_Shred) do
        if string.find(data_Target_Swap_Idol_Shred.text,MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Shred) then
            UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Shred, modes_Target_Swap_Idol_Shred[idx_Target_Swap_Idol_Shred].value)
            _G[dropdown_Target_Swap_Idol_Shred:GetName().."Text"]:SetText(data_Target_Swap_Idol_Shred.text)
        end
    end

    for idx_Target_Swap_Idol_Bear, data_Target_Swap_Idol_Bear in pairs(modes_Target_Swap_Idol_Bear) do
        if string.find(data_Target_Swap_Idol_Bear.text,MPDruidCatSaved[ConfigCurrent].Target_Swap_Idol_Bear) then
            UIDropDownMenu_SetSelectedID(dropdown_Target_Swap_Idol_Bear, modes_Target_Swap_Idol_Bear[idx_Target_Swap_Idol_Bear].value)
            _G[dropdown_Target_Swap_Idol_Bear:GetName().."Text"]:SetText(data_Target_Swap_Idol_Bear.text)
        end
    end

    checkButton_Ashamane:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Ashamane))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].SoulspeedBoss))
    checkButton_Sacrificial:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Sacrificial))
    checkButton_BOSS:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].BOSS))

    checkButton_Power:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPDruidCatSaved[ConfigCurrent].Pick))

end

function MPInitCatSettings()

    if not MPDruidCatSaved then
        MPDruidCatSaved = {}

        -- 第一套配置
        if not MPDruidCatSaved[1] then
            MPDruidCatSaved[1] = {}
            MPResetCatSettings(1)
        end

        -- 第二套配置
        if not MPDruidCatSaved[2] then
            MPDruidCatSaved[2] = {}
            MPResetCatSettings(2)
        end

        -- 第三套配置
        if not MPDruidCatSaved[3] then
            MPDruidCatSaved[3] = {}
            MPResetCatSettings(3)
        end
    end


    if MPDruidCatSaved.Version ~= CatSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[猫德宏]当前配置，这是新版插件正常数据更新！|r")
        MPDruidCatSaved[1] = {}
        MPDruidCatSaved[2] = {}
        MPDruidCatSaved[3] = {}
        MPResetCatSettings(1)
        MPResetCatSettings(2)
        MPResetCatSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    CatSettingsPart1()
    CatSettingsPart2()

    --[[
    if MPDruidCatSaved[ConfigCurrent].Shapeshift == 0 then
        MPSKillButtonClose(Skill_Shapeshift, "重整")
    else
        MPSKillButtonOpen(Skill_Shapeshift, "重整")
    end
    if MPDruidCatSaved[ConfigCurrent].TigerFury == 0 then
        MPSKillButtonClose(Skill_TigerFury, "猛虎之怒")
    else
        MPSKillButtonOpen(Skill_TigerFury, "猛虎之怒")
    end
    if MPDruidCatSaved[ConfigCurrent].FaerieFire == 0 then
        MPSKillButtonClose(Skill_FaerieFire, "精灵之火")
    else
        MPSKillButtonOpen(Skill_FaerieFire, "精灵之火")
    end
    if MPDruidCatSaved[ConfigCurrent].Cower == 0 then
        MPSKillButtonClose(Skill_Cower, "畏缩")
    else
        MPSKillButtonOpen(Skill_Cower, "畏缩")
    end
    if MPDruidCatSaved[ConfigCurrent].Target == 0 then
        MPSKillButtonClose(Skill_Target, "自动锁敌")
    else
        MPSKillButtonOpen(Skill_Target, "自动锁敌")
    end
    ]]

end

