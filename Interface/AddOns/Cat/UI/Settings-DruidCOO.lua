
-- 定义插件名称
local ADDON_NAME = "Settings-DruidCOO"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPDruidCOOSaved[ConfigCurrent] end


-- 创建主框架
CatUISettingsCOOWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 480, "|cFFFF7D0A设置 - 鸟德|r")


local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsCOOWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 枭兽形态
local checkButton_Shapeshift = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 枭兽形态")
MPBindConfigCheckButton(checkButton_Shapeshift, GetCurrentSaved, "Shapeshift")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 月火术
local checkButton_Moonfire = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 月火术")
MPBindConfigCheckButton(checkButton_Moonfire, GetCurrentSaved, "Moonfire")
local checkButton_MoonfireBoss = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_MoonfireBoss, GetCurrentSaved, "MoonfireBoss")

-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 虫群
local checkButton_InsectSwarm = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 虫群")
MPBindConfigCheckButton(checkButton_InsectSwarm, GetCurrentSaved, "InsectSwarm")
local checkButton_InsectSwarmBoss = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_InsectSwarmBoss, GetCurrentSaved, "InsectSwarmBoss")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌")
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 精灵之火
local checkButton_FaerieFire = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 精灵之火")
MPBindConfigCheckButton(checkButton_FaerieFire, GetCurrentSaved, "FaerieFire")
local checkButton_FaerieFireBOSS = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_FaerieFireBOSS, GetCurrentSaved, "FaerieFireBOSS")









-- 高级

postion_y = postion_y-10

-- 添加提示内容区域
local TipText1 = CatUISettingsCOOWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-80


-- 创建单选框 - 预读星火术 FirstStarfire
local checkButton_FirstStarfire = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 20, postion_y, "进战斗前预读 星火术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FirstStarfire, GetCurrentSaved, "FirstStarfire")


-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPDruidCOOSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCOOSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPDruidCOOSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 添加提示内容区域
local StrategyText = CatUISettingsCOOWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
StrategyText:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 20, postion_y+56)
StrategyText:SetWidth(60)
StrategyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
StrategyText:SetJustifyH("LEFT")
StrategyText:SetTextColor(1, 1, 1)
StrategyText:SetText("策略")

-- 创建单选框 - 策略选择
local checkButton_Strategy1 = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 80, postion_y, "日月交替")
local checkButton_Strategy2 = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 200, postion_y, "愤怒偏向")
-- 设置点击事件
checkButton_Strategy1:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCOOSaved[ConfigCurrent].Strategy = 1
    end
    checkButton_Strategy1:SetChecked(true)
    checkButton_Strategy2:SetChecked(false)
end)
checkButton_Strategy2:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCOOSaved[ConfigCurrent].Strategy = 2
    end
    checkButton_Strategy1:SetChecked(false)
    checkButton_Strategy2:SetChecked(true)
end)



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCOOSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPDruidCOOSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)


postion_y = postion_y - 40




-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)


postion_y = postion_y - 40




-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsCOOWindow, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsCOOWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")





postion_y = postion_y + 20


-- 月火<->虫群
local slider_MoonfireInsectSwarm = CreateFrame("Slider", ADDON_NAME.."SliderMoonfireInsectSwarm", CatUISettingsCOOWindow, "OptionsSliderTemplate")
slider_MoonfireInsectSwarm:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 20, postion_y+40)
slider_MoonfireInsectSwarm:SetWidth(220) -- 拖动条长度
slider_MoonfireInsectSwarm:SetHeight(16) -- 拖动条高度
slider_MoonfireInsectSwarm:Hide()

slider_MoonfireInsectSwarm:SetMinMaxValues(1, 2)
slider_MoonfireInsectSwarm:SetValueStep(1)
slider_MoonfireInsectSwarm:SetValue(0) -- 默认值
MPCatUISliderRegionHide(slider_MoonfireInsectSwarm)

-- 值变化时的回调函数
slider_MoonfireInsectSwarm:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    if arg1==1 then
        _G[slider_MoonfireInsectSwarm:GetName().."Text"]:SetText("优先级：月火 -> 虫群")
        MPDruidCOOSaved[ConfigCurrent].MoonfireInsectSwarm = 1
    elseif arg1==2 then
        _G[slider_MoonfireInsectSwarm:GetName().."Text"]:SetText("优先级：虫群 -> 月火")
        MPDruidCOOSaved[ConfigCurrent].MoonfireInsectSwarm = 2
    end
end)



postion_y = postion_y - 50


-- 月火、虫群 等级
local slider_MILevel = MPCreateConfigSlider(ADDON_NAME.."SliderMILevel", CatUISettingsCOOWindow, "TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 20, postion_y+40, 220, 16, 0, 3, 1, 5)

-- 值变化时的回调函数
slider_MILevel:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)

    MPDruidCOOSaved[ConfigCurrent].MILevel = arg1

    if arg1==0 then
        _G[slider_MILevel:GetName().."Text"]:SetText("月火/虫群等级：自动")
    elseif arg1==1 then
        _G[slider_MILevel:GetName().."Text"]:SetText("月火/虫群等级：低")
    elseif arg1==2 then
        _G[slider_MILevel:GetName().."Text"]:SetText("月火/虫群等级：中")
    elseif arg1==3 then
        _G[slider_MILevel:GetName().."Text"]:SetText("月火/虫群等级：高")
    end
end)







--[[
postion_y = postion_y+30

-- 创建单选框 - 神像舞
local checkButton_Idol_Dance = CreateFrame("CheckButton", ADDON_NAME.."CheckButton", CatUISettingsCOOWindow, "UICheckButtonTemplate")
checkButton_Idol_Dance:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 340, postion_y)
checkButton_Idol_Dance:SetScale(0.8)

-- 添加文字标签
local checkText_Idol_Dance = checkButton_Idol_Dance:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
checkText_Idol_Dance:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
checkText_Idol_Dance:SetTextColor(1, 1, 1)
checkText_Idol_Dance:SetPoint("LEFT", checkButton_Idol_Dance, "LEFT", 34, 1)
checkText_Idol_Dance:SetText("神像舞 (月蚀 切换)")



-- 获取纹理元素（兼容所有版本）
local function GetDownMenuTex(dropdownIn, part)
    return _G[dropdownIn:GetName()..part.."Texture"] or _G[dropdownIn:GetName()..part]
end


-- 创建下拉菜单
local dropdown_Idol_Dance_Low = CreateFrame("Button", ADDON_NAME.."Dropdown_Idol_Dance_Low", checkButton_Idol_Dance, "UIDropDownMenuTemplate")
dropdown_Idol_Dance_Low:SetPoint("TOPLEFT", checkButton_Idol_Dance, "TOPLEFT", -12, -30)

local middle_Idol_Dance_Low = GetDownMenuTex(dropdown_Idol_Dance_Low, "Middle")
middle_Idol_Dance_Low:SetWidth(110) -- 主宽度
middle_Idol_Dance_Low:SetHeight(60) -- 主宽度

-- 定义选项（带固定索引的表）
local modes_Idol_Dance_Low = {
    [1] = {text = "|cFF9D38C8月牙神像|r", item="月牙神像", value = 1},
    [2] = {text = "|cFF0070DD月亮神像|r", item="月亮神像", value = 2},
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
                MPDruidCOOSaved[ConfigCurrent].Idol_Dance_Normal = modes_Idol_Dance_Low[index].item
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
    [1] = {text = "|cFF9D38C8潮汐神像|r", item="潮汐神像", value = 1},
--    [2] = {text = "|cFF9D38C8撕裂神像|r", value = 2},
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
                MPDruidCOOSaved[ConfigCurrent].Idol_Dance_Starfire = modes_Idol_Dance_High[index].item
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Idol_Dance_High, Dropdown_Init_Idol_Dance_High)
UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_High, 1) -- 默认选中第一项

-- 设置点击事件
MPBindConfigCheckButton(checkButton_Idol_Dance, GetCurrentSaved, "Idol_Dance")

]]






postion_y = postion_y-60


local myButton = MPCreateButton(CatUISettingsCOOWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetCOOSettings(ConfigCurrent)
    MPInitCOOSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsCOOWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitCOOSettings()
end)




local MLDButton = CreateFrame("Button", ADDON_NAME.."ButtonReset", CatUISettingsCOOWindow, "UIPanelButtonTemplate")
MLDButton:SetPoint("TOPLEFT", CatUISettingsCOOWindow, "TOPLEFT", 340, postion_y+100)
MLDButton:SetWidth(120)
MLDButton:SetHeight(22)
MLDButton:SetFont("Fonts\\FRIZQT__.TTF", 12)
MLDButton:SetText("多线DOT设置")

-- 调整按钮纹理
MLDButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
MLDButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
MLDButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
MLDButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
-- 按钮点击事件
MLDButton:SetScript("OnClick", function()
    MPCatSettingsCloseAll() 
    CatUISettingsMultilineDot:Show()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsCOOWindow, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsCOOWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsCOOWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFFF7D0A/coodps|r [ 1 | 2 | 3 ]    多线Dot |cFFFF7D0A/MDot|r")



-- 配置文件版本号
local COOSettingsUIVersion = 14

function MPResetCOOSettings(config)

    MPDruidCOOSaved.Version = COOSettingsUIVersion

    -- 基本配置

    MPDruidCOOSaved[config].Shapeshift = 1
    MPDruidCOOSaved[config].Moonfire = 1
    MPDruidCOOSaved[config].MoonfireBoss = 0
    MPDruidCOOSaved[config].InsectSwarm = 1
    MPDruidCOOSaved[config].InsectSwarmBoss = 0
    MPDruidCOOSaved[config].FaerieFire = 0
    MPDruidCOOSaved[config].FaerieFireBOSS = 0
    MPDruidCOOSaved[config].Trinket_Upper = 1
    MPDruidCOOSaved[config].TUBoss = 0
    MPDruidCOOSaved[config].Trinket_Below = 1
    MPDruidCOOSaved[config].TBBoss = 0
    MPDruidCOOSaved[config].Target = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPDruidCOOSaved[config].HealthStone = 1
    MPDruidCOOSaved[config].HealthStone_Value = 30
    MPDruidCOOSaved[config].HerbalTea = 1
    MPDruidCOOSaved[config].HerbalTea_Value = 20
    MPDruidCOOSaved[config].HerbalTeaMana = 0
    MPDruidCOOSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPDruidCOOSaved[config].SuperWoW = 1
    MPDruidCOOSaved[config].UnitXP = 1

    MPDruidCOOSaved[config].Strategy = 1

    --MPDruidCOOSaved[config].BOSS = 0
    MPDruidCOOSaved[config].EclipseSun = 0
    MPDruidCOOSaved[config].FirstStarfire = 0

    MPDruidCOOSaved[config].MILevel = 0
    MPDruidCOOSaved[config].MoonfireInsectSwarm = 1

    MPDruidCOOSaved[config].Soulspeed = 0
    MPDruidCOOSaved[config].SoulspeedBoss = 1

    -- 神像相关
    MPDruidCOOSaved[config].Idol_Dance = 0
    MPDruidCOOSaved[config].Idol_Dance_Normal = "月牙神像"
    MPDruidCOOSaved[config].Idol_Dance_Starfire = "潮汐神像"

    -- 通用
    MPDruidCOOSaved[config].Power = 0
    MPDruidCOOSaved[config].Pick = 0
end


local function MPInitCOOSettingsPart1()
    checkButton_Shapeshift:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Shapeshift))
    checkButton_Moonfire:SetChecked( MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Moonfire) )
    checkButton_MoonfireBoss:SetChecked( MPToBoolean(MPDruidCOOSaved[ConfigCurrent].MoonfireBoss) )
    checkButton_InsectSwarm:SetChecked( MPToBoolean(MPDruidCOOSaved[ConfigCurrent].InsectSwarm) )
    checkButton_InsectSwarmBoss:SetChecked( MPToBoolean(MPDruidCOOSaved[ConfigCurrent].InsectSwarmBoss) )
    checkButton_FaerieFire:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].FaerieFire))
    checkButton_FaerieFireBOSS:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].FaerieFireBOSS))
    checkButton_Target:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Target))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].TBBoss))

    if MPDruidCOOSaved[ConfigCurrent].Strategy==1 then
        checkButton_Strategy1:SetChecked(true)
        checkButton_Strategy2:SetChecked(false)
    elseif MPDruidCOOSaved[ConfigCurrent].Strategy==2 then
        checkButton_Strategy1:SetChecked(false)
        checkButton_Strategy2:SetChecked(true)
    end

    checkButton_FirstStarfire:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].FirstStarfire))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Pick))
end

function MPInitCOOSettings()

    if not MPDruidCOOSaved then
        MPDruidCOOSaved = {}
        -- 第一套配置
        if not MPDruidCOOSaved[1] then
            MPDruidCOOSaved[1] = {}
            MPResetCOOSettings(1)
        end

        -- 第二套配置
        if not MPDruidCOOSaved[2] then
            MPDruidCOOSaved[2] = {}
            MPResetCOOSettings(2)
        end

        -- 第三套配置
        if not MPDruidCOOSaved[3] then
            MPDruidCOOSaved[3] = {}
            MPResetCOOSettings(3)
        end
    end

    if MPDruidCOOSaved.Version ~= COOSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[鸟德宏]当前配置，这是新版插件正常数据更新！|r")
        MPDruidCOOSaved[1] = {}
        MPDruidCOOSaved[2] = {}
        MPDruidCOOSaved[3] = {}
        MPResetCOOSettings(1)
        MPResetCOOSettings(2)
        MPResetCOOSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    MPInitCOOSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPDruidCOOSaved[ConfigCurrent].HealthStone_Value)
    if MPDruidCOOSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPDruidCOOSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value)
    if MPDruidCOOSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPDruidCOOSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")


    slider_MoonfireInsectSwarm:SetValue(MPDruidCOOSaved[ConfigCurrent].MoonfireInsectSwarm)
    slider_MILevel:SetValue(MPDruidCOOSaved[ConfigCurrent].MILevel)

    --[[
    -- 神像舞
    checkButton_Idol_Dance:SetChecked(MPToBoolean(MPDruidCOOSaved[ConfigCurrent].Idol_Dance))

    for idx_Idol_Dance_Low, data_Idol_Dance_Low in pairs(modes_Idol_Dance_Low) do
        if string.find(data_Idol_Dance_Low.text,MPDruidCOOSaved[ConfigCurrent].Idol_Dance_Normal) then
            UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_Low, data_Idol_Dance_Low.value)
            _G[dropdown_Idol_Dance_Low:GetName().."Text"]:SetText(data_Idol_Dance_Low.text)
        end
    end

    for idx_Idol_Dance_High, data_Idol_Dance_High in pairs(modes_Idol_Dance_High) do
        if string.find(data_Idol_Dance_High.text,MPDruidCOOSaved[ConfigCurrent].Idol_Dance_Starfire) then
            UIDropDownMenu_SetSelectedID(dropdown_Idol_Dance_High, modes_Idol_Dance_High[idx_Idol_Dance_High].value)
            _G[dropdown_Idol_Dance_High:GetName().."Text"]:SetText(data_Idol_Dance_High.text)
        end
    end
    ]]
end

