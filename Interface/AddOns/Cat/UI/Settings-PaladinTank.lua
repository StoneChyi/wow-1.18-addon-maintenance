
-- 定义插件名称
local ADDON_NAME = "Settings-PaladinTank"

local ConfigCurrent = 1
local restoring = false
local function GetCurrentSaved() return MPPaladinTankSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsPaladinTank = MPCreateFrame(ADDON_NAME.."Frame", 520, 550, "|cFFF58CBA设置 - 防骑|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPaladinTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 正义之怒
local checkButton_RighteousFury = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "保持 正义之怒")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RighteousFury, GetCurrentSaved, "RighteousFury")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 奉献
local checkButton_Consecration = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奉献")

local slider_Consecration = MPCreateConfigSlider(ADDON_NAME.."slider_Consecration", checkButton_Consecration, "RIGHT", checkButton_Consecration, "RIGHT", 270, -2, 120, 16, 1, 3, 1, 8)

local color_Consecration = "|cFFFFD100"

-- 值变化时的回调函数
slider_Consecration:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].Consecration_Priority = arg1
    if MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end
    if not restoring and not MPCatPaladinControlUpdating() and CatUISettingsPaladinTank:IsVisible() then
        MPCatPaladinSyncConsecration("Consecration_Priority", MPPaladinTankSaved[ConfigCurrent].Consecration_Priority, "TANK", ConfigCurrent)
    end
end)

-- 设置点击事件
checkButton_Consecration:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].Consecration = 1
        color_Consecration = "|cFFFFD100"
    else
        color_Consecration = "|cFF888888"
        MPPaladinTankSaved[ConfigCurrent].Consecration = 0
    end
    if MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end
    MPCatPaladinSyncConsecration("Consecration", MPPaladinTankSaved[ConfigCurrent].Consecration, "TANK", ConfigCurrent)
end)




-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 神圣之盾
local checkButton_HolyShield = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 神圣之盾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyShield, GetCurrentSaved, "HolyShield")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 十字军打击
local checkButton_CrusaderStrike = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 十字军打击")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_CrusaderStrike, GetCurrentSaved, "CrusaderStrike")

postion_y = postion_y-30

-- 创建单选框 - 驱邪术
local checkButton_Exorcism = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "开启 驱邪术 (亡灵,恶魔)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Exorcism, GetCurrentSaved, "Exorcism")


-- 高级



postion_y = postion_y+10

-- 添加提示内容区域
local TipText1 = CatUISettingsPaladinTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-75


-- 创建单选框 - 神圣之盾
local checkButton_HolyShieldTarget = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "目标看你时 允许 神圣之盾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolyShieldTarget, GetCurrentSaved, "HolyShieldTarget")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPaladinTankSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 取消拯救
local checkButton_UnSalvation = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动取消 拯救祝福")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_UnSalvation, GetCurrentSaved, "UnSalvation")


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPaladinTankSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)





postion_y = postion_y-40



-- 创建单选框 - 小庇护祝福
local checkButton_Sanctuary = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动 小庇护祝福")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Sanctuary, GetCurrentSaved, "Sanctuary")




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)




postion_y = postion_y-40



-- 创建单选框 - 正义壁垒
local checkButton_Righteous = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 20, postion_y, "自动 正义壁垒")

local slider_Righteous = MPCreateConfigSlider(ADDON_NAME.."Slider_Righteous", checkButton_Righteous, "RIGHT", checkButton_Righteous, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Righteous = "|cFFFFD100"

-- 值变化时的回调函数
slider_Righteous:SetScript("OnValueChanged", function()
    --print("Frenzied当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].Righteous_Value = arg1
    _G[slider_Righteous:GetName().."Text"]:SetText(color_Righteous.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_Righteous:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].Righteous = 1
        color_Righteous = "|cFFFFD100"
        _G[slider_Righteous:GetName().."Text"]:SetText(color_Righteous.."血线: ".. MPPaladinTankSaved[ConfigCurrent].Righteous_Value .."%|r")
    else
        MPPaladinTankSaved[ConfigCurrent].Righteous = 0
        color_Righteous = "|cFF888888"
        _G[slider_Righteous:GetName().."Text"]:SetText(color_Righteous.."血线: ".. MPPaladinTankSaved[ConfigCurrent].Righteous_Value .."%|r")
    end
end)


-- 下一次防骑宏按键取消免疫，默认关闭，各套配置独立保存。
local checkButton_AutoCancelImmunity = MPCreateCheckButton(CatUISettingsPaladinTank,
    ADDON_NAME.."CheckButtonAutoCancelImmunity", 340, postion_y, "自动取消 无敌/保护之手")
MPBindConfigCheckButton(checkButton_AutoCancelImmunity, GetCurrentSaved, "AutoCancelImmunity")
checkButton_AutoCancelImmunity:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("下一次按防骑宏时，优先取消自己身上的圣盾术、保护之手（保护祝福）。")
    GameTooltip:Show()
end)
checkButton_AutoCancelImmunity:SetScript("OnLeave", function() GameTooltip:Hide() end)

postion_y = postion_y-40

-- 创建单选框 - 圣疗术
local checkButton_LayHands = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 圣疗术")

local slider_LayHands = MPCreateConfigSlider(ADDON_NAME.."Slider_LayHands", checkButton_LayHands, "RIGHT", checkButton_LayHands, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 10)

local color_LayHands = "|cFFFFD100"

-- 值变化时的回调函数
slider_LayHands:SetScript("OnValueChanged", function()
    --print("Frenzied当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].LayHands_Value = arg1
    _G[slider_LayHands:GetName().."Text"]:SetText(color_LayHands.."血线: ".. arg1 .."%|r")
end)

-- 设置点击事件
checkButton_LayHands:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinTankSaved[ConfigCurrent].LayHands = 1
        color_LayHands = "|cFFFFD100"
        _G[slider_LayHands:GetName().."Text"]:SetText(color_LayHands.."血线: ".. MPPaladinTankSaved[ConfigCurrent].LayHands_Value .."%|r")
    else
        MPPaladinTankSaved[ConfigCurrent].LayHands = 0
        color_LayHands = "|cFF888888"
        _G[slider_LayHands:GetName().."Text"]:SetText(color_LayHands.."血线: ".. MPPaladinTankSaved[ConfigCurrent].LayHands_Value .."%|r")
    end
end)

postion_y = postion_y-40


-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")


postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsPaladinTank, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinTank, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")


postion_y = postion_y+150


-- 审判界限
local slider_JudgementOutHP = MPCreateConfigSlider(ADDON_NAME.."SliderJudgementOutHP", CatUISettingsPaladinTank, "TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 20, postion_y, 220, 16, 0, 50000, 1000, 500000)

-- 值变化时的回调函数
slider_JudgementOutHP:SetScript("OnValueChanged", function()
    --print("Rip当前值:", arg1)
    MPPaladinTankSaved[ConfigCurrent].JudgementOutHP = arg1
    _G[slider_JudgementOutHP:GetName().."Text"]:SetText("目标生命 <".. MPPaladinTankSaved[ConfigCurrent].JudgementOutHP .." 不审判")
end)

postion_y = postion_y-45

-- 十字军打击时机
local slider_CrusaderStrikeTimer = MPCreateConfigSlider(ADDON_NAME.."SliderCrusaderStrikeTimer", CatUISettingsPaladinTank, "TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 20, postion_y, 220, 16, 1, 180, 1, 0)

-- 值变化时的回调函数
slider_CrusaderStrikeTimer:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    _G[slider_CrusaderStrikeTimer:GetName().."Text"]:SetText(arg1.."秒后开启 十字军打击")
    MPPaladinTankSaved[ConfigCurrent].CrusaderStrikeTimer = arg1
end)


postion_y = postion_y-45


-- 奉献等级
local slider_Consecration_Level = MPCreateConfigSlider(ADDON_NAME.."SliderConsecration_Level", CatUISettingsPaladinTank, "TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 20, postion_y, 220, 16, 0, 5, 1, 10)

-- 值变化时的回调函数
slider_Consecration_Level:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    if arg1==0 then
        _G[slider_Consecration_Level:GetName().."Text"]:SetText("奉献等级：自动")
    else
        _G[slider_Consecration_Level:GetName().."Text"]:SetText("奉献等级："..arg1)
    end
    MPPaladinTankSaved[ConfigCurrent].Consecration_Level = arg1
end)




-- 动态控制
local ButtonAutoSeal = CreateFrame("Button", ADDON_NAME.."ButtonAutoSeal", CatUISettingsPaladinTank, "UIPanelButtonTemplate")
ButtonAutoSeal:SetPoint("TOPLEFT", CatUISettingsPaladinTank, "TOPLEFT", 340, postion_y)
ButtonAutoSeal:SetWidth(100)
ButtonAutoSeal:SetHeight(22)
ButtonAutoSeal:SetFont("Fonts\\FRIZQT__.TTF", 12)
ButtonAutoSeal:SetText("审判控制")

ButtonAutoSeal:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
ButtonAutoSeal:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
ButtonAutoSeal:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
ButtonAutoSeal:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
ButtonAutoSeal:SetScript("OnClick", function()
    MPCatPaladinSealInit()
    if CatPaladinSeal:IsVisible() then
        CatPaladinSeal:Hide()
        MPPublicSaved.PaladinSealDisplay = 0
    else
        CatPaladinSeal:Show()
        MPPublicSaved.PaladinSealDisplay = 1
    end
end)



-- 回蓝配置使用独立居中窗口，跟随防骑设置当前选中的配置编号。
CatPaladinTankManaSettings = MPCreateFrame(ADDON_NAME.."ManaFrame", 480, 270, "防骑 - 回蓝设置")
if CatPaladinTankManaSettings.SetClampedToScreen then CatPaladinTankManaSettings:SetClampedToScreen(true) end
-- 只允许标题栏拖动，阈值滑条不会拖走窗口。
CatPaladinTankManaSettings:RegisterForDrag()
CatPaladinTankManaSettings:SetScript("OnDragStart", nil)
CatPaladinTankManaSettings:SetScript("OnDragStop", nil)
local manaDrag = CreateFrame("Frame", nil, CatPaladinTankManaSettings)
manaDrag:SetPoint("TOPLEFT", CatPaladinTankManaSettings, "TOPLEFT", 0, 0)
manaDrag:SetWidth(300)
manaDrag:SetHeight(28)
manaDrag:EnableMouse(true)
manaDrag:RegisterForDrag("LeftButton")
manaDrag:SetScript("OnDragStart", function() CatPaladinTankManaSettings:StartMoving() end)
manaDrag:SetScript("OnDragStop", function() CatPaladinTankManaSettings:StopMovingOrSizing() end)
local manaRestoring = false
local autoWisdom = MPCreateCheckButton(CatPaladinTankManaSettings, ADDON_NAME.."AutoWisdom", 20, -52, "低蓝自动切换智慧圣印")
MPBindConfigCheckButton(autoWisdom, GetCurrentSaved, "AutoWisdom", function()
    if type(MPCatPaladinTankManaOptionsChanged) == "function" then MPCatPaladinTankManaOptionsChanged() end
end)
local economy = MPCreateCheckButton(CatPaladinTankManaSettings, ADDON_NAME.."WisdomEconomy", 20, -165, "回蓝时节省蓝量")
MPBindConfigCheckButton(economy, GetCurrentSaved, "WisdomEconomy")
local enter = MPCreateConfigSlider(ADDON_NAME.."WisdomEnter", CatPaladinTankManaSettings, "TOPLEFT", CatPaladinTankManaSettings, "TOPLEFT", 20, -110, 200, 16, 5, 80, 1, 25)
local leave = MPCreateConfigSlider(ADDON_NAME.."WisdomExit", CatPaladinTankManaSettings, "TOPLEFT", CatPaladinTankManaSettings, "TOPLEFT", 250, -110, 200, 16, 10, 95, 1, 40)
local manaProfile = CatPaladinTankManaSettings:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
manaProfile:SetPoint("TOPLEFT", CatPaladinTankManaSettings, "TOPLEFT", 20, -83)
local manaDescription = CatPaladinTankManaSettings:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
manaDescription:SetPoint("TOPLEFT", CatPaladinTankManaSettings, "TOPLEFT", 20, -204)
manaDescription:SetWidth(440)
manaDescription:SetJustifyH("LEFT")
manaDescription:SetText("手动切换圣印或使用惩戒宏后，本场战斗尊重手动选择。节蓝：暂停驱邪术，自动档奉献改用等级1。")
function MPCatRefreshPaladinTankManaSettings()
    local saved = GetCurrentSaved()
    if not saved then return end
    MPCatPaladinTankEnsureManaConfig(saved)
    manaRestoring = true
    manaProfile:SetText("当前防骑配置："..ConfigCurrent)
    autoWisdom:SetChecked(saved.AutoWisdom == 1)
    economy:SetChecked(saved.WisdomEconomy == 1)
    enter:SetValue(saved.WisdomEnter)
    leave:SetValue(saved.WisdomExit)
    _G[enter:GetName().."Text"]:SetText("进入回蓝：<"..saved.WisdomEnter.."%")
    _G[leave:GetName().."Text"]:SetText("恢复输出：≥"..saved.WisdomExit.."%")
    manaRestoring = false
end
enter:SetScript("OnValueChanged", function()
    if restoring or manaRestoring then return end
    local saved = GetCurrentSaved()
    saved.WisdomEnter = math.floor(enter:GetValue() + 0.5)
    MPCatPaladinTankEnsureManaConfig(saved)
    MPCatRefreshPaladinTankManaSettings()
end)
leave:SetScript("OnValueChanged", function()
    if restoring or manaRestoring then return end
    local saved = GetCurrentSaved()
    saved.WisdomExit = math.floor(leave:GetValue() + 0.5)
    if saved.WisdomExit <= saved.WisdomEnter then saved.WisdomEnter = saved.WisdomExit - 5 end
    MPCatPaladinTankEnsureManaConfig(saved)
    MPCatRefreshPaladinTankManaSettings()
end)
CatPaladinTankManaSettings:SetScript("OnShow", function() MPCatRefreshPaladinTankManaSettings() end)
local manaButton = MPCreateButton(CatUISettingsPaladinTank, ADDON_NAME.."ManaSettingsButton", "回蓝设置", 448, postion_y, 66, 22)
manaButton:SetScript("OnClick", function()
    if CatPaladinTankManaSettings:IsVisible() then CatPaladinTankManaSettings:Hide()
    else CatPaladinTankManaSettings:Show() end
end)


-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPaladinTank, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPaladinTankSettings(ConfigCurrent)
    MPInitPaladinTankSettings()

    MPCatPaladinSealReset()
    MPCatPaladinApplyControl("TANK", ConfigCurrent)

    CatPaladinSeal:Hide()
    CatPaladinSeal:ClearAllPoints()
    CatPaladinSeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPaladinTank, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPaladinTankSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPaladinTank, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsPaladinTank:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPaladinTank, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFF58CBA/ptank|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PaladinTankSettingsUIVersion = 22

function MPResetPaladinTankSettings(config)

    MPPaladinTankSaved.Version = PaladinTankSettingsUIVersion

    -- 基本配置

    MPPaladinTankSaved[config].Trinket_Upper = 1
    MPPaladinTankSaved[config].TUBoss = 0
    MPPaladinTankSaved[config].Trinket_Below = 1
    MPPaladinTankSaved[config].TBBoss = 0

    MPPaladinTankSaved[config].RighteousFury = 1
    MPPaladinTankSaved[config].Consecration = 1
    MPPaladinTankSaved[config].Consecration_Level = 0
    MPPaladinTankSaved[config].Consecration_Priority = 1

    MPPaladinTankSaved[config].HolyShield = 1
    MPPaladinTankSaved[config].Exorcism = 1

    MPPaladinTankSaved[config].Target = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPPaladinTankSaved[config].HealthStone = 1
    MPPaladinTankSaved[config].HealthStone_Value = 30
    MPPaladinTankSaved[config].HerbalTea = 1
    MPPaladinTankSaved[config].HerbalTea_Value = 20
    MPPaladinTankSaved[config].HerbalTeaMana = 0
    MPPaladinTankSaved[config].HerbalTeaMana_Value = 20
    MPPaladinTankSaved[config].Righteous = 0
    MPPaladinTankSaved[config].Righteous_Value = 20
    MPPaladinTankSaved[config].LayHands = 0
    MPPaladinTankSaved[config].LayHands_Value = 10

    MPPaladinTankSaved[config].JudgementOutHP = 5000
    MPPaladinTankSaved[config].Seal = 1
    MPPaladinTankSaved[config].Seal_Value = 1


    MPPaladinTankSaved[config].CrusaderStrike = 0
    MPPaladinTankSaved[config].CrusaderStrikeTimer = 15


    -- SuperWoW,UnitXP
    MPPaladinTankSaved[config].SuperWoW = 1
    MPPaladinTankSaved[config].UnitXP = 1

    MPPaladinTankSaved[config].UnSalvation = 0
    MPPaladinTankSaved[config].AutoCancelImmunity = 0
    MPPaladinTankSaved[config].AutoWisdom = 0
    MPPaladinTankSaved[config].WisdomEconomy = 0
    MPPaladinTankSaved[config].WisdomEnter = 25
    MPPaladinTankSaved[config].WisdomExit = 40
    MPPaladinTankSaved[config].HolyShieldTarget = 0
    MPPaladinTankSaved[config].Sanctuary = 0

    MPPaladinTankSaved[config].RacialTraits = 0
    MPPaladinTankSaved[config].RacialTraitsBoss = 1
    MPPaladinTankSaved[config].Soulspeed = 0
    MPPaladinTankSaved[config].SoulspeedBoss = 1
    MPPaladinTankSaved[config].SwipeFirst = 1

    -- 通用
    MPPaladinTankSaved[config].Power = 0
    MPPaladinTankSaved[config].Pick = 0

end


function InitPaladinTankSettingsPart1()
    MPCatRefreshPaladinTankManaSettings()
    checkButton_RighteousFury:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].RighteousFury))
    checkButton_Consecration:SetChecked( MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Consecration) )
    checkButton_HolyShield:SetChecked( MPToBoolean(MPPaladinTankSaved[ConfigCurrent].HolyShield) )
    checkButton_CrusaderStrike:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].CrusaderStrike))
    checkButton_Exorcism:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Exorcism))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].TBBoss))
    checkButton_Target:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Target))

    checkButton_RacialTraits:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_UnSalvation:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].UnSalvation))
    checkButton_AutoCancelImmunity:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].AutoCancelImmunity))
    checkButton_HolyShieldTarget:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].HolyShieldTarget))
    checkButton_Sanctuary:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Sanctuary))

    checkButton_Power:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].Pick))
end

function InitPaladinTankSettingsPart2()
    checkButton_HealthStone:SetChecked(MPToBoolean(MPPaladinTankSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPaladinTankSaved[ConfigCurrent].HealthStone_Value)
    if MPPaladinTankSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPaladinTankSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value)
    if MPPaladinTankSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinTankSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")


    checkButton_Righteous:SetChecked(MPPaladinTankSaved[ConfigCurrent].Righteous)
    slider_Righteous:SetValue(MPPaladinTankSaved[ConfigCurrent].Righteous_Value)
    if MPPaladinTankSaved[ConfigCurrent].Righteous==1 then
        color_Righteous = "|cFFFFD100"
    else
        color_Righteous = "|cFF888888"
    end
    _G[slider_Righteous:GetName().."Text"]:SetText(color_Righteous.."血线: ".. MPPaladinTankSaved[ConfigCurrent].Righteous_Value .."%|r")


    checkButton_LayHands:SetChecked(MPPaladinTankSaved[ConfigCurrent].LayHands)
    slider_LayHands:SetValue(MPPaladinTankSaved[ConfigCurrent].LayHands_Value)
    if MPPaladinTankSaved[ConfigCurrent].LayHands==1 then
        color_LayHands = "|cFFFFD100"
    else
        color_LayHands = "|cFF888888"
    end
    _G[slider_LayHands:GetName().."Text"]:SetText(color_LayHands.."血线: ".. MPPaladinTankSaved[ConfigCurrent].LayHands_Value .."%|r")


    --[[ 前置审判
    checkButton_Judgement:SetChecked(MPPaladinTankSaved[ConfigCurrent].Judgement)
    slider_Judgement:SetValue(MPPaladinTankSaved[ConfigCurrent].Judgement_Value)
    if MPPaladinTankSaved[ConfigCurrent].Judgement==1 then
        color_Judgement = "|cFFFFD100"
    else
        color_Judgement = "|cFF888888"
    end
    if MPPaladinTankSaved[ConfigCurrent].Judgement_Value==0 then
        _G[slider_Judgement:GetName().."Text"]:SetText(color_Judgement.."正义审判")
    elseif MPPaladinTankSaved[ConfigCurrent].Judgement_Value==1 then
        _G[slider_Judgement:GetName().."Text"]:SetText(color_Judgement.."智慧审判")
    elseif MPPaladinTankSaved[ConfigCurrent].Judgement_Value==2 then
        _G[slider_Judgement:GetName().."Text"]:SetText(color_Judgement.."十字军审判")
    elseif MPPaladinTankSaved[ConfigCurrent].Judgement_Value==3 then
        _G[slider_Judgement:GetName().."Text"]:SetText(color_Judgement.."光明审判")
    end
    ]]

    slider_JudgementOutHP:SetValue(MPPaladinTankSaved[ConfigCurrent].JudgementOutHP)
    _G[slider_JudgementOutHP:GetName().."Text"]:SetText("目标生命 <".. MPPaladinTankSaved[ConfigCurrent].JudgementOutHP .." 不审判")


    --[[ 中段审判
    checkButton_MiddleJudgement:SetChecked(MPPaladinTankSaved[ConfigCurrent].MiddleJudgement)
    slider_MiddleJudgement:SetValue(MPPaladinTankSaved[ConfigCurrent].MiddleJudgement_Value)
    if MPPaladinTankSaved[ConfigCurrent].MiddleJudgement==1 then
        color_MiddleJudgement = "|cFFFFD100"
    else
        color_MiddleJudgement = "|cFF888888"
    end
    if MPPaladinTankSaved[ConfigCurrent].MiddleJudgement_Value==1 then
        _G[slider_MiddleJudgement:GetName().."Text"]:SetText(color_MiddleJudgement.."智慧审判")
    elseif MPPaladinTankSaved[ConfigCurrent].MiddleJudgement_Value==2 then
        _G[slider_MiddleJudgement:GetName().."Text"]:SetText(color_MiddleJudgement.."十字军审判")
    elseif MPPaladinTankSaved[ConfigCurrent].MiddleJudgement_Value==3 then
        _G[slider_MiddleJudgement:GetName().."Text"]:SetText(color_MiddleJudgement.."光明审判")
    end
    slider_MiddleJudgementTimer:SetValue(MPPaladinTankSaved[ConfigCurrent].MiddleJudgementTimer)
    _G[slider_MiddleJudgementTimer:GetName().."Text"]:SetText(color_MiddleJudgement.."约".. MPPaladinTankSaved[ConfigCurrent].MiddleJudgementTimer .."秒后 中段审判")
    ]]

    -- 奉献
    slider_Consecration_Level:SetValue(MPPaladinTankSaved[ConfigCurrent].Consecration_Level)

    slider_CrusaderStrikeTimer:SetValue(MPPaladinTankSaved[ConfigCurrent].CrusaderStrikeTimer)

    slider_Consecration:SetValue(MPPaladinTankSaved[ConfigCurrent].Consecration_Priority)
    if MPPaladinTankSaved[ConfigCurrent].Consecration==1 then
        color_Consecration = "|cFFFFD100"
    else
        color_Consecration = "|cFF888888"
    end
    if MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinTankSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end

end


function MPInitPaladinTankSettings()
    restoring = true
    if not MPPaladinTankSaved then
        MPPaladinTankSaved = {}

        -- 第一套配置
        if not MPPaladinTankSaved[1] then
            MPPaladinTankSaved[1] = {}
            MPResetPaladinTankSettings(1)
        end

        -- 第二套配置
        if not MPPaladinTankSaved[2] then
            MPPaladinTankSaved[2] = {}
            MPResetPaladinTankSettings(2)
        end

        -- 第三套配置
        if not MPPaladinTankSaved[3] then
            MPPaladinTankSaved[3] = {}
            MPResetPaladinTankSettings(3)
        end
    end

    if MPPaladinTankSaved.Version ~= PaladinTankSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[防骑宏]当前配置，这是新版插件正常数据更新！|r")
        MPPaladinTankSaved[1] = {}
        MPPaladinTankSaved[2] = {}
        MPPaladinTankSaved[3] = {}
        MPResetPaladinTankSettings(1)
        MPResetPaladinTankSettings(2)
        MPResetPaladinTankSettings(3)
    end

    -- 增量补齐新字段，不升级配置版本、不重置原有三套设置。
    for config = 1, 3 do
        MPCatPaladinTankEnsureManaConfig(MPPaladinTankSaved[config])
        if MPPaladinTankSaved[config].AutoCancelImmunity == nil then
            MPPaladinTankSaved[config].AutoCancelImmunity = 0
        end
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    if CatUISettingsPaladinTank:IsVisible() then MPCatPaladinApplyControl("TANK", ConfigCurrent) end
    InitPaladinTankSettingsPart1()
    InitPaladinTankSettingsPart2()
    restoring = false

    if CatUISettingsPaladinTank:IsVisible() then
        MPCatPaladinSealInit()
    end


end


-- 面板只刷新对应配置的奉献控件，不触发完整设置初始化。
function MPCatRefreshPaladinTankConsecration(config)
    if ConfigCurrent ~= config then return end
    local saved = MPPaladinTankSaved[ConfigCurrent]
    checkButton_Consecration:SetChecked(MPToBoolean(saved.Consecration))
    if saved.Consecration==1 then color_Consecration="|cFFFFD100" else color_Consecration="|cFF888888" end
    slider_Consecration:SetValue(saved.Consecration_Priority)
end

CatUISettingsPaladinTank:SetScript("OnShow", function()
    MPCatPaladinApplyControl("TANK", ConfigCurrent)
    MPCatPaladinSealInit()
end)
