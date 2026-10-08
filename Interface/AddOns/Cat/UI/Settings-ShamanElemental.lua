
-- 定义插件名称
local ADDON_NAME = "Settings-ShamanElemental"

local ConfigCurrent = 1
local function GetCurrentSaved() return MPShamanElementalSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsShamanElementalWindow = MPCreateFrame(ADDON_NAME.."Frame", 520, 650, "|cFF0070DE设置 - 元素萨|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsShamanElementalWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsShamanElementalWindow, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40


-- 创建单选框 - 闪电箭
local checkButton_LightningBolt = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 闪电箭")
-- 闪电箭设置点击事件
MPBindConfigCheckButton(checkButton_LightningBolt, GetCurrentSaved, "LightningBolt")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")



postion_y = postion_y-30

-- 创建单选框 - 闪电链
local checkButton_ChainLightning = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 闪电链")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ChainLightning, GetCurrentSaved, "ChainLightning")




-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")



postion_y = postion_y-30


-- 创建单选框 - 地震术
local checkButton_EarthSpell = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 地震术")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_EarthSpell, GetCurrentSaved, "EarthSpell")



-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")


postion_y = postion_y-30

-- 创建单选框 - 烈焰震击
local checkButton_FlameShock = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 烈焰震击")




postion_y = postion_y-30

-- 创建单选框 - 烈焰震击 通过 熔岩爆裂
local checkButton_FlameShockFromLavaBurst = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 烈焰震击 通过 熔岩爆裂")

checkButton_FlameShock:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].FlameShock = 1
    else
        MPShamanElementalSaved[ConfigCurrent].FlameShock = 0
        MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst = 0
    end
    checkButton_FlameShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShock) )
    checkButton_FlameShockFromLavaBurst:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst) )
end)
checkButton_FlameShockFromLavaBurst:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst = 1
        MPShamanElementalSaved[ConfigCurrent].FlameShock = 1
    else
        MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst = 0
    end
    checkButton_FlameShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShock) )
    checkButton_FlameShockFromLavaBurst:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst) )
end)

-- 创建单选框 - 闪电之盾
local checkButton_LightningShield = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "保持 闪电之盾 (单选)")



postion_y = postion_y-30

-- 创建单选框 - 大地震击
local checkButton_EarthShock = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 大地震击 (单选)")


-- 创建单选框 - 水之护盾
local checkButton_WaterShield = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "保持 水之护盾 (单选)")



postion_y = postion_y-30

-- 创建单选框 - 冰霜震击
local checkButton_FrostShock = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "开启 冰霜震击 (单选)")

-- 大地震击设置点击事件
checkButton_EarthShock:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].EarthShock = 1
        MPShamanElementalSaved[ConfigCurrent].FrostShock = 0
    else
        MPShamanElementalSaved[ConfigCurrent].EarthShock = 0
        MPShamanElementalSaved[ConfigCurrent].FrostShock = 0
    end
    checkButton_EarthShock:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShock))
    checkButton_FrostShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FrostShock) )
end)

-- 冰霜震击设置点击事件
checkButton_FrostShock:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].FrostShock = 1
        MPShamanElementalSaved[ConfigCurrent].EarthShock = 0
    else
        MPShamanElementalSaved[ConfigCurrent].FrostShock = 0
        MPShamanElementalSaved[ConfigCurrent].EarthShock = 0
    end
    checkButton_EarthShock:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShock))
    checkButton_FrostShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FrostShock) )
end)


-- 创建单选框 - 大地之盾
local checkButton_EarthShield = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "保持 大地之盾 (单选)")

-- 设置点击事件
checkButton_LightningShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 0
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 0
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 1
    else
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 0
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 0
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 0
    end
    checkButton_LightningShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LightningShield) )
    checkButton_WaterShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WaterShield) )
    checkButton_EarthShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShield) )
end)

-- 设置点击事件
checkButton_WaterShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 0
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 1
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 0
    else
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 0
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 0
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 0
    end
    checkButton_LightningShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LightningShield) )
    checkButton_WaterShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WaterShield) )
    checkButton_EarthShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShield) )
end)

-- 设置点击事件
checkButton_EarthShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 1
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 0
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 0
    else
        MPShamanElementalSaved[ConfigCurrent].EarthShield = 0
        MPShamanElementalSaved[ConfigCurrent].WaterShield = 0
        MPShamanElementalSaved[ConfigCurrent].LightningShield = 0
    end
    checkButton_LightningShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LightningShield) )
    checkButton_WaterShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WaterShield) )
    checkButton_EarthShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShield) )
end)






-- 图腾

postion_y = postion_y+10

-- 添加提示内容区域
local TipText2 = CatUISettingsShamanElementalWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText2:SetPoint("TOPLEFT", CatUISettingsShamanElementalWindow, "TOPLEFT", 20, postion_y)
TipText2:SetWidth(250)
TipText2:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText2:SetTextColor(1, 0.8, 0)
TipText2:SetJustifyH("LEFT")
TipText2:SetText("图腾配置")

postion_y = postion_y-90



-- 大地图腾
local checkButton_EarthTotem = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "大地图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_EarthTotem, GetCurrentSaved, "EarthTotem")

-- 定义选项（带固定索引的表）
local modes_EarthTotem = {
    [1] = {text = "大地之力图腾", value = 1},
    [2] = {text = "石肤图腾", value = 2},
    [3] = {text = "石爪图腾", value = 3},
    [4] = {text = "战栗图腾",   value = 4},
    [5] = {text = "地缚图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_EarthTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_EarthTotem", checkButton_EarthTotem, "UIDropDownMenuTemplate")
dropdown_EarthTotem:SetPoint("TOPLEFT", checkButton_EarthTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_EarthTotem()
    for idx, data in pairs(modes_EarthTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, index)
                MPShamanElementalSaved[ConfigCurrent].EarthTotem_Value = modes_EarthTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_EarthTotem, Dropdown_Init_EarthTotem)
UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, 1) -- 默认选中第一项








-- 火焰图腾
local checkButton_FireTotem = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 175, postion_y, "火焰图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_FireTotem, GetCurrentSaved, "FireTotem")

-- 定义选项（带固定索引的表）
local modes_FireTotem = {
    [1] = {text = "火焰新星图腾", value = 1},
    [2] = {text = "灼热图腾", value = 2},
    [3] = {text = "熔岩图腾", value = 3},
    [4] = {text = "抗寒图腾",   value = 4},
    [5] = {text = "火舌图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_FireTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_FireTotem", checkButton_FireTotem, "UIDropDownMenuTemplate")
dropdown_FireTotem:SetPoint("TOPLEFT", checkButton_FireTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_FireTotem()
    for idx, data in pairs(modes_FireTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_FireTotem, index)
                MPShamanElementalSaved[ConfigCurrent].FireTotem_Value = modes_FireTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_FireTotem, Dropdown_Init_FireTotem)
UIDropDownMenu_SetSelectedID(dropdown_FireTotem, 1) -- 默认选中第一项







-- 水之图腾
local checkButton_WaterTotem = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 330, postion_y, "水之图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WaterTotem, GetCurrentSaved, "WaterTotem")

-- 定义选项（带固定索引的表）
local modes_WaterTotem = {
    [1] = {text = "抗火图腾", value = 1},
    [2] = {text = "治疗之泉图腾", value = 2},
    [3] = {text = "法力之泉图腾", value = 3},
    [4] = {text = "清毒图腾",   value = 4},
    [5] = {text = "祛病图腾",   value = 5},
}

-- 创建下拉菜单
local dropdown_WaterTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_WaterTotem", checkButton_WaterTotem, "UIDropDownMenuTemplate")
dropdown_WaterTotem:SetPoint("TOPLEFT", checkButton_WaterTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_WaterTotem()
    for idx, data in pairs(modes_WaterTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, index)
                MPShamanElementalSaved[ConfigCurrent].WaterTotem_Value = modes_WaterTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_WaterTotem, Dropdown_Init_WaterTotem)
UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, 1) -- 默认选中第一项





-- 空气图腾
local checkButton_AirTotem = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 485, postion_y, "空气图腾")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_AirTotem, GetCurrentSaved, "AirTotem")

-- 定义选项（带固定索引的表）
local modes_AirTotem = {
    [1] = {text = "根基图腾", value = 1},
    [2] = {text = "自然抗性图腾", value = 2},
    [3] = {text = "风之优雅图腾", value = 3},
    [4] = {text = "风墙图腾",   value = 4},
    [5] = {text = "风怒图腾",   value = 5},
    [6] = {text = "宁静之风图腾",   value = 6},
    -- 这里剔除了 岗哨图腾
}

-- 创建下拉菜单
local dropdown_AirTotem = CreateFrame("Button", ADDON_NAME.."Dropdown_AirTotem", checkButton_AirTotem, "UIDropDownMenuTemplate")
dropdown_AirTotem:SetPoint("TOPLEFT", checkButton_AirTotem, "TOPLEFT", -12, -35)

-- 菜单初始化
local function Dropdown_Init_AirTotem()
    for idx, data in pairs(modes_AirTotem) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                -- 使用闭包保存的index
                UIDropDownMenu_SetSelectedID(dropdown_AirTotem, index)
                MPShamanElementalSaved[ConfigCurrent].AirTotem_Value = modes_AirTotem[index].text
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_AirTotem, Dropdown_Init_AirTotem)
UIDropDownMenu_SetSelectedID(dropdown_AirTotem, 1) -- 默认选中第一项




postion_y = postion_y-90

--[[
-- 创建单选框 - 图腾召回
local checkButton_RecallTotems = CreateFrame("CheckButton", ADDON_NAME.."CheckButton_RecallTotems", CatUISettingsShamanElementalWindow, "UICheckButtonTemplate")
checkButton_RecallTotems:SetPoint("TOPLEFT", CatUISettingsShamanElementalWindow, "TOPLEFT", 20, postion_y)
checkButton_RecallTotems:SetScale(0.8)

-- 添加文字标签
local checkText_RecallTotems = checkButton_RecallTotems:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
checkText_RecallTotems:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
checkText_RecallTotems:SetTextColor(1, 1, 1)
checkText_RecallTotems:SetPoint("LEFT", checkButton_RecallTotems, "LEFT", 34, 1)
checkText_RecallTotems:SetText("自动 图腾召回")


local slider_RecallTotems = MPCreateConfigSlider(ADDON_NAME.."Slider_RecallTotems", checkButton_RecallTotems, "RIGHT", checkButton_RecallTotems, "RIGHT", 260, -2, 150, 16, 15, 100, 1, 30)

local color_RecallTotems = "|cFFFFD100"

-- 值变化时的回调函数
slider_RecallTotems:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value = arg1
    _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
end)

-- 设置点击事件
checkButton_RecallTotems:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].RecallTotems = 1
        color_RecallTotems = "|cFFFFD100"
        _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    else
        MPShamanElementalSaved[ConfigCurrent].RecallTotems = 0
        color_RecallTotems = "|cFF888888"
        _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." "..MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    end
end)

]]

-- 创建单选框 - 强制图腾
local checkButton_ForceTotem = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "开启 强制图腾配置")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_ForceTotem, GetCurrentSaved, "ForceTotem")






-- 高级



postion_y = postion_y+40

-- 添加提示内容区域
local TipText1 = CatUISettingsShamanElementalWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsShamanElementalWindow, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-130


-- 创建单选框 - 熔岩爆裂
local checkButton_LavaBurst = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "仅开启 火萨流程 熔岩+烈震")
-- 熔岩爆裂设置点击事件
MPBindConfigCheckButton(checkButton_LavaBurst, GetCurrentSaved, "LavaBurst")



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPShamanElementalSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPShamanElementalSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 保持 火舌图腾
local checkButton_WEnhance = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 20, postion_y, "保持 火舌武器")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_WEnhance, GetCurrentSaved, "WEnhance")



-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPShamanElementalSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y - 40

-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)



postion_y = postion_y-40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")



postion_y = postion_y-40

-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsShamanElementalWindow, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



-- 创建按钮
local myButton = MPCreateButton(CatUISettingsShamanElementalWindow, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetShamanElementalSettings(ConfigCurrent)
    MPInitShamanElementalSettings()
end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsShamanElementalWindow, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitShamanElementalSettings()
end)


-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsShamanElementalWindow, ADDON_NAME, GetCurrentSaved)

-- 添加提示内容区域
local TipText = CatUISettingsShamanElementalWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsShamanElementalWindow, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFF0070DE/sedps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local ShamanElementalSettingsUIVersion = 14

function MPResetShamanElementalSettings(config)

    MPShamanElementalSaved.Version = ShamanElementalSettingsUIVersion

    -- 基本配置

    MPShamanElementalSaved[config].LightningBolt = 1
    MPShamanElementalSaved[config].ChainLightning = 1
    MPShamanElementalSaved[config].EarthSpell = 0
    MPShamanElementalSaved[config].EarthShock = 1
    MPShamanElementalSaved[config].FrostShock = 0
    MPShamanElementalSaved[config].FlameShock = 0
    MPShamanElementalSaved[config].FlameShockFromLavaBurst = 0

    MPShamanElementalSaved[config].LightningShield = 0
    MPShamanElementalSaved[config].WaterShield = 1
    MPShamanElementalSaved[config].EarthShield = 0

    MPShamanElementalSaved[config].Trinket_Upper = 1
    MPShamanElementalSaved[config].TUBoss = 0
    MPShamanElementalSaved[config].Trinket_Below = 1
    MPShamanElementalSaved[config].TBBoss = 0
    MPShamanElementalSaved[config].Target = 0

    --- 火萨
    MPShamanElementalSaved[config].WEnhance = 0
    MPShamanElementalSaved[config].WEnhance_Value = "火舌武器"
    MPShamanElementalSaved[config].LavaBurst = 0

    MPShamanElementalSaved[config].EarthTotem = 1
    MPShamanElementalSaved[config].EarthTotem_Value = "大地之力图腾"
    MPShamanElementalSaved[config].FireTotem = 1
    MPShamanElementalSaved[config].FireTotem_Value = "灼热图腾"
    MPShamanElementalSaved[config].WaterTotem = 1
    MPShamanElementalSaved[config].WaterTotem_Value = "法力之泉图腾"
    MPShamanElementalSaved[config].AirTotem = 1
    MPShamanElementalSaved[config].AirTotem_Value = "风怒图腾"

    MPShamanElementalSaved[config].RecallTotems = 1
    MPShamanElementalSaved[config].RecallTotems_Value = 40

    MPShamanElementalSaved[config].ForceTotem = 0

    -- 高级配置

    -- 治疗石、糖水茶
    MPShamanElementalSaved[config].HealthStone = 1
    MPShamanElementalSaved[config].HealthStone_Value = 30
    MPShamanElementalSaved[config].HerbalTea = 1
    MPShamanElementalSaved[config].HerbalTea_Value = 20
    MPShamanElementalSaved[config].HerbalTeaMana = 0
    MPShamanElementalSaved[config].HerbalTeaMana_Value = 20

    -- SuperWoW,UnitXP
    MPShamanElementalSaved[config].SuperWoW = 1
    MPShamanElementalSaved[config].UnitXP = 1

    MPShamanElementalSaved[config].RacialTraits = 0
    MPShamanElementalSaved[config].RacialTraitsBoss = 1
    MPShamanElementalSaved[config].Soulspeed = 0
    MPShamanElementalSaved[config].SoulspeedBoss = 1

    --MPShamanElementalSaved[config].Force = 0

    --MPShamanElementalSaved[config].Wave_Value = 60
    --MPShamanElementalSaved[config].SecondaryWave_Value = 99
    --MPShamanElementalSaved[config].Chain_Value = 3
    --MPShamanElementalSaved[config].WaterShieldLevel = 0

    -- 通用
    MPShamanElementalSaved[config].Power = 0
    MPShamanElementalSaved[config].Pick = 0

end


function InitShamanElementalSettingsPart1()

    checkButton_LightningBolt:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LightningBolt))
    checkButton_ChainLightning:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].ChainLightning))
    checkButton_EarthSpell:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthSpell))
    checkButton_EarthShock:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShock))
    checkButton_FrostShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FrostShock) )
    checkButton_FlameShock:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShock) )
    checkButton_FlameShockFromLavaBurst:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FlameShockFromLavaBurst) )
    checkButton_LavaBurst:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LavaBurst) )

    checkButton_WEnhance:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WEnhance) )

    checkButton_LightningShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].LightningShield) )
    checkButton_WaterShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WaterShield) )
    checkButton_EarthShield:SetChecked( MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthShield) )

    checkButton_Target:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Target))
    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].TBBoss))

    checkButton_RacialTraits:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].SoulspeedBoss))

    checkButton_Power:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].Pick))
end

function MPInitShamanElementalSettings()
    if not MPShamanElementalSaved then
        MPShamanElementalSaved = {}

        -- 第一套配置
        if not MPShamanElementalSaved[1] then
            MPShamanElementalSaved[1] = {}
            MPResetShamanElementalSettings(1)
        end

        -- 第二套配置
        if not MPShamanElementalSaved[2] then
            MPShamanElementalSaved[2] = {}
            MPResetShamanElementalSettings(2)
        end

        -- 第三套配置
        if not MPShamanElementalSaved[3] then
            MPShamanElementalSaved[3] = {}
            MPResetShamanElementalSettings(3)
        end
    end

    if MPShamanElementalSaved.Version ~= ShamanElementalSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[元素萨宏]当前配置，这是新版插件正常数据更新！|r")
        MPShamanElementalSaved[1] = {}
        MPShamanElementalSaved[2] = {}
        MPShamanElementalSaved[3] = {}
        MPResetShamanElementalSettings(1)
        MPResetShamanElementalSettings(2)
        MPResetShamanElementalSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)

    InitShamanElementalSettingsPart1()

    checkButton_HealthStone:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPShamanElementalSaved[ConfigCurrent].HealthStone_Value)
    if MPShamanElementalSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPShamanElementalSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value)
    if MPShamanElementalSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPShamanElementalSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")




    checkButton_EarthTotem:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].EarthTotem))
    for idx_EarthTotem, data_EarthTotem in pairs(modes_EarthTotem) do
        if string.find(data_EarthTotem.text, MPShamanElementalSaved[ConfigCurrent].EarthTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_EarthTotem, data_EarthTotem.value)
            _G[dropdown_EarthTotem:GetName().."Text"]:SetText(data_EarthTotem.text)
        end
    end

    checkButton_FireTotem:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].FireTotem))
    for idx_FireTotem, data_FireTotem in pairs(modes_FireTotem) do
        if string.find(data_FireTotem.text, MPShamanElementalSaved[ConfigCurrent].FireTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_FireTotem, data_FireTotem.value)
            _G[dropdown_FireTotem:GetName().."Text"]:SetText(data_FireTotem.text)
        end
    end

    checkButton_WaterTotem:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].WaterTotem))
    for idx_WaterTotem, data_WaterTotem in pairs(modes_WaterTotem) do
        if string.find(data_WaterTotem.text, MPShamanElementalSaved[ConfigCurrent].WaterTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_WaterTotem, data_WaterTotem.value)
            _G[dropdown_WaterTotem:GetName().."Text"]:SetText(data_WaterTotem.text)
        end
    end

    checkButton_AirTotem:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].AirTotem))
    for idx_AirTotem, data_AirTotem in pairs(modes_AirTotem) do
        if string.find(data_AirTotem.text, MPShamanElementalSaved[ConfigCurrent].AirTotem_Value) then
            UIDropDownMenu_SetSelectedID(dropdown_AirTotem, data_AirTotem.value)
            _G[dropdown_AirTotem:GetName().."Text"]:SetText(data_AirTotem.text)
        end
    end


    --[[
    checkButton_RecallTotems:SetChecked(MPShamanElementalSaved[ConfigCurrent].RecallTotems)
    slider_RecallTotems:SetValue(MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value)
    if MPShamanElementalSaved[ConfigCurrent].RecallTotems==1 then
        color_RecallTotems = "|cFFFFD100"
    else
        color_RecallTotems = "|cFF888888"
    end
    _G[slider_RecallTotems:GetName().."Text"]:SetText(color_RecallTotems.." ".. MPShamanElementalSaved[ConfigCurrent].RecallTotems_Value .." 码距离|r")
    ]]

    checkButton_ForceTotem:SetChecked(MPToBoolean(MPShamanElementalSaved[ConfigCurrent].ForceTotem))

end

