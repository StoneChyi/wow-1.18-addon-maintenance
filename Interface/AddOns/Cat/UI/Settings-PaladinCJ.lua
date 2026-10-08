
-- 定义插件名称
local ADDON_NAME = "Settings-PaladinCJ"

local ConfigCurrent = 1
local restoring = false
local function GetCurrentSaved() return MPPaladinCJSaved[ConfigCurrent] end

-- 创建主框架
CatUISettingsPaladinCJ = MPCreateFrame(ADDON_NAME.."Frame", 520, 570, "|cFFF58CBA设置 - 惩戒骑|r")

local postion_y = -50

-- 添加提示内容区域
local TipText = CatUISettingsPaladinCJ:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("TOPLEFT", CatUISettingsPaladinCJ, "TOPLEFT", 20, postion_y)
TipText:SetWidth(250)
TipText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText:SetTextColor(1, 0.8, 0)
TipText:SetJustifyH("LEFT")
TipText:SetText(MPLanguage.UI_Set_BasicConfig)






local postion_y = postion_y-40

-- 创建单选框 - 圣洁光环
local checkButton_HolinessAura = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "保持 圣洁光环")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HolinessAura, GetCurrentSaved, "HolinessAura")


-- 创建单选框 - 上方饰品
local checkButton_Trinket_Upper = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(上)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Upper, GetCurrentSaved, "Trinket_Upper")
local checkButton_TUBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TUBoss, GetCurrentSaved, "TUBoss")




postion_y = postion_y-30

-- 创建单选框 - 奉献
local checkButton_Consecration = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "开启 奉献")

local slider_Consecration = MPCreateConfigSlider(ADDON_NAME.."slider_Consecration", checkButton_Consecration, "RIGHT", checkButton_Consecration, "RIGHT", 270, -2, 120, 16, 1, 3, 1, 8)

local color_Consecration = "|cFFFFD100"

-- 值变化时的回调函数
slider_Consecration:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].Consecration_Priority = arg1
    if MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end
    if not restoring and not MPCatPaladinControlUpdating() and CatUISettingsPaladinCJ:IsVisible() then
        MPCatPaladinSyncConsecration("Consecration_Priority", MPPaladinCJSaved[ConfigCurrent].Consecration_Priority, "RET", ConfigCurrent)
    end
end)

-- 设置点击事件
checkButton_Consecration:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].Consecration = 1
        color_Consecration = "|cFFFFD100"
    else
        color_Consecration = "|cFF888888"
        MPPaladinCJSaved[ConfigCurrent].Consecration = 0
    end
    if MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end
    MPCatPaladinSyncConsecration("Consecration", MPPaladinCJSaved[ConfigCurrent].Consecration, "RET", ConfigCurrent)
end)


-- 创建单选框 - 下方饰品
local checkButton_Trinket_Below = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动开启饰品(下)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Trinket_Below, GetCurrentSaved, "Trinket_Below")
local checkButton_TBBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_TBBoss, GetCurrentSaved, "TBBoss")




postion_y = postion_y-30

-- 创建单选框 - 忏悔
local checkButton_Repentance = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "开启 忏悔")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Repentance, GetCurrentSaved, "Repentance")
local checkButton_RepentanceBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RepentanceBoss, GetCurrentSaved, "RepentanceBoss")


-- 创建单选框 - 自动锁敌
local checkButton_Target = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动锁敌 (攻击最近的敌人)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Target, GetCurrentSaved, "Target")

postion_y = postion_y-30


-- 创建单选框 - 驱邪术
local checkButton_Exorcism = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "开启 驱邪术 (亡灵,恶魔)")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_Exorcism, GetCurrentSaved, "Exorcism")


postion_y = postion_y-30


-- 创建单选框 - 愤怒之锤
local checkButton_HammerWrath = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "开启 愤怒之锤")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_HammerWrath, GetCurrentSaved, "HammerWrath")
local checkButton_HammerWrathBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 200, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_HammerWrathBoss, GetCurrentSaved, "HammerWrathBoss")







-- 高级


postion_y = postion_y

-- 添加提示内容区域
local TipText1 = CatUISettingsPaladinCJ:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText1:SetPoint("TOPLEFT", CatUISettingsPaladinCJ, "TOPLEFT", 20, postion_y)
TipText1:SetWidth(250)
TipText1:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- 使用OUTLINE参数
TipText1:SetTextColor(1, 0.8, 0)
TipText1:SetJustifyH("LEFT")
TipText1:SetText(MPLanguage.UI_Set_AdvancedConfig)


postion_y = postion_y-80


-- 输出圣印保留旧编号，新增与公共控制面板一致的辅助圣印显示。
local checkButton_Seal = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "输出圣印")
local slider_Seal = MPCreateConfigSlider(ADDON_NAME.."Slider_Seal", checkButton_Seal, "RIGHT", checkButton_Seal, "RIGHT", 244, -2, 160, 16, 1, 7, 1, 1)
local sealLabels = { "自动识别", "正义圣印", "命令圣印", "智慧圣印", "光明圣印", "十字军圣印", "公正圣印" }
local function RefreshSealLabel()
    local saved = MPPaladinCJSaved[ConfigCurrent]
    local color = saved.Seal == 1 and "|cFFFFD100" or "|cFF888888"
    local label = saved.Seal == 1 and (sealLabels[saved.Seal_Value] or sealLabels[1]) or "无"
    _G[slider_Seal:GetName().."Text"]:SetText(color..label)
end
slider_Seal:SetScript("OnValueChanged", function()
    if not restoring and not MPCatPaladinControlUpdating() then
        MPPaladinCJSaved[ConfigCurrent].Seal_Value = math.max(1, math.min(7, math.floor(slider_Seal:GetValue() + 0.5)))
    end
    RefreshSealLabel()
end)
checkButton_Seal:SetScript("OnClick", function()
    MPPaladinCJSaved[ConfigCurrent].Seal = this:GetChecked() and 1 or 0
    RefreshSealLabel()
end)



-- 创建单选框 - 治疗石
local checkButton_HealthStone = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 治疗石")

local slider_HealthStone = MPCreateConfigSlider(ADDON_NAME.."Slider_HealthStone", checkButton_HealthStone, "RIGHT", checkButton_HealthStone, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 30)

local color_HealthStone = "|cFFFFD100"

-- 值变化时的回调函数
slider_HealthStone:SetScript("OnValueChanged", function()
    --print("HealthStone当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].HealthStone_Value = arg1
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HealthStone_Value .."%|r")
end)

-- 设置点击事件
checkButton_HealthStone:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].HealthStone = 1
        color_HealthStone = "|cFFFFD100"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HealthStone_Value .."%|r")
    else
        MPPaladinCJSaved[ConfigCurrent].HealthStone = 0
        color_HealthStone = "|cFF888888"
        _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HealthStone_Value .."%|r")
    end
end)



postion_y = postion_y-40


-- 创建单选框 - 使用 神打/十打
local checkButton_Strike = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 20, postion_y, "输出技能")

local slider_Strike = MPCreateConfigSlider(ADDON_NAME.."Slider_Strike", checkButton_Strike, "RIGHT", checkButton_Strike, "RIGHT", 244, -2, 160, 16, 1, 5, 1, 2)

-- 鼠标滚轮按整档切换，便于准确选择第五档。
slider_Strike:EnableMouseWheel(true)
slider_Strike:SetScript("OnMouseWheel", function()
    local value = math.floor(this:GetValue() + 0.5)
    this:SetValue(math.max(1, math.min(5, value + arg1)))
end)

local color_Strike = "|cFFFFD100"

-- 值变化时的回调函数
slider_Strike:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].Strike_Value = math.max(1, math.min(5, math.floor(arg1 + 0.5)))
    if MPPaladinCJSaved[ConfigCurrent].Strike_Value==1 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 神圣打击")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==2 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (均衡)")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==3 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 十字军打击 (均衡)")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==4 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 十字军打击")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==5 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (三层狂热)")
    end
end)

-- 设置点击事件
checkButton_Strike:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].Strike = 1
        color_Strike = "|cFFFFD100"
        if MPPaladinCJSaved[ConfigCurrent].Strike_Value==1 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 神圣打击")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==2 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (均衡)")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==3 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 十字军打击 (均衡)")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==4 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 十字军打击")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==5 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (三层狂热)")
        end
    else
        MPPaladinCJSaved[ConfigCurrent].Strike = 0
        color_Strike = "|cFF888888"
        if MPPaladinCJSaved[ConfigCurrent].Strike_Value==1 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 神圣打击")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==2 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (均衡)")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==3 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 十字军打击 (均衡)")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==4 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 十字军打击")
        elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==5 then
            _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (三层狂热)")
        end
    end
end)


-- 创建单选框 - 草药茶
local checkButton_HerbalTea = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTea = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTea", checkButton_HerbalTea, "RIGHT", checkButton_HerbalTea, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTea = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTea:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value = arg1
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTea:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].HerbalTea = 1
        color_HerbalTea = "|cFFFFD100"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    else
        MPPaladinCJSaved[ConfigCurrent].HerbalTea = 0
        color_HerbalTea = "|cFF888888"
        _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value .."%|r")
    end
end)



postion_y = postion_y - 40

-- 创建单选框 - 草药茶 蓝量
local checkButton_HerbalTeaMana = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 草药茶")

local slider_HerbalTeaMana = MPCreateConfigSlider(ADDON_NAME.."Slider_HerbalTeaMana", checkButton_HerbalTeaMana, "RIGHT", checkButton_HerbalTeaMana, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_HerbalTeaMana = "|cFFFFD100"

-- 值变化时的回调函数
slider_HerbalTeaMana:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value = arg1
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
end)

-- 设置点击事件
checkButton_HerbalTeaMana:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana = 1
        color_HerbalTeaMana = "|cFFFFD100"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    else
        MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana = 0
        color_HerbalTeaMana = "|cFF888888"
        _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")
    end
end)




postion_y = postion_y-40


-- 创建单选框 - 保护之手
local checkButton_Protection = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 保护之手")

local slider_Protection = MPCreateConfigSlider(ADDON_NAME.."Slider_Protection", checkButton_Protection, "RIGHT", checkButton_Protection, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_Protection = "|cFFFFD100"

-- 值变化时的回调函数
slider_Protection:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].Protection_Value = arg1
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinCJSaved[ConfigCurrent].Protection_Value .."%|r")
end)

-- 设置点击事件
checkButton_Protection:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].Protection = 1
        color_Protection = "|cFFFFD100"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinCJSaved[ConfigCurrent].Protection_Value .."%|r")
    else
        MPPaladinCJSaved[ConfigCurrent].Protection = 0
        color_Protection = "|cFF888888"
        _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinCJSaved[ConfigCurrent].Protection_Value .."%|r")
    end
end)


postion_y = postion_y-40


-- 创建单选框 - 圣盾术
local checkButton_DivineShield = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 圣盾术")

local slider_DivineShield = MPCreateConfigSlider(ADDON_NAME.."Slider_DivineShield", checkButton_DivineShield, "RIGHT", checkButton_DivineShield, "RIGHT", 250, -2, 150, 16, 0, 100, 1, 20)

local color_DivineShield = "|cFFFFD100"

-- 值变化时的回调函数
slider_DivineShield:SetScript("OnValueChanged", function()
    --print("HerbalTea当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].DivineShield_Value = arg1
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinCJSaved[ConfigCurrent].DivineShield_Value .."%|r")
end)

-- 设置点击事件
checkButton_DivineShield:SetScript("OnClick", function(self)
    if this:GetChecked() then
        MPPaladinCJSaved[ConfigCurrent].DivineShield = 1
        color_DivineShield = "|cFFFFD100"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinCJSaved[ConfigCurrent].DivineShield_Value .."%|r")
    else
        MPPaladinCJSaved[ConfigCurrent].DivineShield = 0
        color_DivineShield = "|cFF888888"
        _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinCJSaved[ConfigCurrent].DivineShield_Value .."%|r")
    end
end)


postion_y = postion_y - 40


-- 创建单选框 - 圣契
local checkButton_Relic = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButtonSoulspeed", 20, postion_y, "目标血量<35%切换圣契")
MPBindConfigCheckButton(checkButton_Relic, GetCurrentSaved, "Relic")
local checkButton_RelicBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 240, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RelicBoss, GetCurrentSaved, "RelicBoss")



-- 获取纹理元素（兼容所有版本）
local function GetDownMenuTex(dropdownIn, part)
    return _G[dropdownIn:GetName()..part.."Texture"] or _G[dropdownIn:GetName()..part]
end

-- 创建下拉菜单
local dropdown_Relic_Low = CreateFrame("Button", ADDON_NAME.."Dropdown_Relic_Low", checkButton_Relic, "UIDropDownMenuTemplate")
dropdown_Relic_Low:SetPoint("TOPLEFT", checkButton_Relic, "TOPLEFT", -12, -30)

local middle_Relic_Low = GetDownMenuTex(dropdown_Relic_Low, "Middle")
middle_Relic_Low:SetWidth(110) -- 主宽度
middle_Relic_Low:SetHeight(60) -- 主宽度

-- 定义选项（带固定索引的表）
local modes_Relic_Low = {
    [1] = {text = "|cFF9D38C8最终审判圣契|r", item="最终审判圣契", value = 1}
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Relic_Low()
    for idx, data in pairs(modes_Relic_Low) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                UIDropDownMenu_SetSelectedID(dropdown_Relic_Low, index)
                MPPaladinCJSaved[ConfigCurrent].Relic_Low = modes_Relic_Low[index].item
            end
        end)(idx)
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Relic_Low, Dropdown_Init_Relic_Low)
UIDropDownMenu_SetSelectedID(dropdown_Relic_Low, 1) -- 默认选中第一项



-- 创建下拉菜单
local dropdown_Relic_Normal = CreateFrame("Button", ADDON_NAME.."CatModeDropdown_Relic_Normal", checkButton_Relic, "UIDropDownMenuTemplate")
dropdown_Relic_Normal:SetPoint("TOPLEFT", checkButton_Relic, "TOPLEFT", 130, -30)

local middle_Relic_Normal = GetDownMenuTex(dropdown_Relic_Normal, "Middle")
middle_Relic_Normal:SetWidth(110) -- 主宽度
middle_Relic_Normal:SetHeight(60) -- 主宽度



-- 定义选项（带固定索引的表）
local modes_Relic_Normal = {
    [1] = {text = "|cFF9D38C8永恒之塔圣契|r", item="永恒之塔圣契", value = 1},
    [2] = {text = "|cFF9D38C8热忱圣契|r", item="热忱圣契", value = 2},
    [3] = {text = "|cFF9D38C8神圣领域圣契|r", item="神圣领域圣契", value = 3},
    [4] = {text = "|cFF0070DD热情圣契|r", item="热情圣契", value = 4},
}

-- 菜单初始化（修复空索引问题）
local function Dropdown_Init_Relic_Normal()
    for idx, data in pairs(modes_Relic_Normal) do
        local info = {}
        info.text = data.text
        info.value = data.value
        info.func = (function(index) 
            return function()
                UIDropDownMenu_SetSelectedID(dropdown_Relic_Normal, index)
                MPPaladinCJSaved[ConfigCurrent].Relic_Normal = modes_Relic_Normal[index].item
            end
        end)(idx) -- 立即传入当前索引
        UIDropDownMenu_AddButton(info)
    end
end

-- 初始化菜单
UIDropDownMenu_Initialize(dropdown_Relic_Normal, Dropdown_Init_Relic_Normal)
UIDropDownMenu_SetSelectedID(dropdown_Relic_Normal, 1) -- 默认选中第一项












-- 创建单选框 - 种族天赋
local checkButton_RacialTraits = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 340, postion_y, "自动 种族天赋")
-- 设置点击事件
MPBindConfigCheckButton(checkButton_RacialTraits, GetCurrentSaved, "RacialTraits")
local checkButton_RacialTraitsBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_RacialTraitsBoss, GetCurrentSaved, "RacialTraitsBoss")



postion_y = postion_y - 40

-- 魂能之速
local checkButton_Soulspeed = MPCreateCheckButton(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButtonSoulspeed", 340, postion_y, "自动 魂能之速")
MPBindConfigCheckButton(checkButton_Soulspeed, GetCurrentSaved, "Soulspeed")
local checkButton_SoulspeedBoss = MPCreateCheckButtonSmall(CatUISettingsPaladinCJ, ADDON_NAME.."CheckButton", 520, postion_y, MPLanguage.UI_Set_BossOnly)
MPBindConfigCheckButton(checkButton_SoulspeedBoss, GetCurrentSaved, "SoulspeedBoss")





postion_y = postion_y+210

-- 前置审判界限
local slider_JudgementOutHP = MPCreateConfigSlider(ADDON_NAME.."SliderJudgementOutHP", CatUISettingsPaladinCJ, "TOPLEFT", CatUISettingsPaladinCJ, "TOPLEFT", 20, postion_y, 220, 16, 0, 50000, 1000, 300000)

-- 值变化时的回调函数
slider_JudgementOutHP:SetScript("OnValueChanged", function()
    --print("Rip当前值:", arg1)
    MPPaladinCJSaved[ConfigCurrent].JudgementOutHP = arg1
    _G[slider_JudgementOutHP:GetName().."Text"]:SetText("目标生命 <".. MPPaladinCJSaved[ConfigCurrent].JudgementOutHP .." 不审判")
end)



postion_y = postion_y -40

-- 奉献等级
local slider_Consecration_Level = MPCreateConfigSlider(ADDON_NAME.."SliderConsecration_Level", CatUISettingsPaladinCJ, "TOPLEFT", CatUISettingsPaladinCJ, "TOPLEFT", 20, postion_y, 220, 16, 0, 5, 1, 10)

-- 值变化时的回调函数
slider_Consecration_Level:SetScript("OnValueChanged", function()
    --print("Ferocious当前值:", arg1)
    if arg1==0 then
        _G[slider_Consecration_Level:GetName().."Text"]:SetText("奉献等级：自动")
    else
        _G[slider_Consecration_Level:GetName().."Text"]:SetText("奉献等级："..arg1)
    end
    MPPaladinCJSaved[ConfigCurrent].Consecration_Level = arg1
end)



postion_y = postion_y - 120

-- 动态控制
local ButtonAutoSeal = CreateFrame("Button", ADDON_NAME.."ButtonAutoSeal", CatUISettingsPaladinCJ, "UIPanelButtonTemplate")
ButtonAutoSeal:SetPoint("TOPLEFT", CatUISettingsPaladinCJ, "TOPLEFT", 340, postion_y+10)
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




-- 创建按钮
local myButton = MPCreateButton(CatUISettingsPaladinCJ, ADDON_NAME.."ButtonReset", MPLanguage.UI_Set_ResetDefaults, 120, -44, 100, 22)
myButton:SetScript("OnClick", function()
    MPResetPaladinCJSettings(ConfigCurrent)
    MPInitPaladinCJSettings()

    MPCatPaladinSealReset()
    MPCatPaladinApplyControl("RET", ConfigCurrent)

    CatPaladinSeal:Hide()
    CatPaladinSeal:ClearAllPoints()
    CatPaladinSeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

end)


local ConfigButton = MPCreateConfigSelector(CatUISettingsPaladinCJ, ADDON_NAME, function(index)
    ConfigCurrent = index
    MPInitPaladinCJSettings()
end)



-- 添加分隔线
local checkButton_Power, checkButton_Pick = MPCreateCommonSettingsFooter(CatUISettingsPaladinCJ, ADDON_NAME, GetCurrentSaved)


-- 添加提示内容区域
local TipText = CatUISettingsPaladinCJ:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatUISettingsPaladinCJ, "BOTTOM", 0, 9)
TipText:SetWidth(450)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText("宏命令 |cFFF58CBA/pdps|r [ 1 | 2 | 3 ]")



-- 配置文件版本号
local PaladinCJSettingsUIVersion = 19

function MPResetPaladinCJSettings(config)

    MPPaladinCJSaved.Version = PaladinCJSettingsUIVersion

    -- 基本配置
    MPPaladinCJSaved[config].HolinessAura = 1
    MPPaladinCJSaved[config].Consecration = 1
    MPPaladinCJSaved[config].Consecration_Level = 0
    MPPaladinCJSaved[config].Consecration_Priority = 1
    MPPaladinCJSaved[config].Repentance = 1
    MPPaladinCJSaved[config].RepentanceBoss = 1
    MPPaladinCJSaved[config].Exorcism = 1
    MPPaladinCJSaved[config].HammerWrath = 0
    MPPaladinCJSaved[config].HammerWrathBoss = 0

    MPPaladinCJSaved[config].Trinket_Upper = 1
    MPPaladinCJSaved[config].TUBoss = 0
    MPPaladinCJSaved[config].Trinket_Below = 1
    MPPaladinCJSaved[config].TBBoss = 0
    MPPaladinCJSaved[config].Target = 0

    -- 高级配置
    MPPaladinCJSaved[config].JudgementOutHP = 5000
    MPPaladinCJSaved[config].Seal = 1
    MPPaladinCJSaved[config].Seal_Value = 1

    MPPaladinCJSaved[config].Strike = 1
    MPPaladinCJSaved[config].Strike_Value = 3

    MPPaladinCJSaved[config].RacialTraits = 0
    MPPaladinCJSaved[config].RacialTraitsBoss = 1
    MPPaladinCJSaved[config].Soulspeed = 0
    MPPaladinCJSaved[config].SoulspeedBoss = 1
    
    -- 圣契
    MPPaladinCJSaved[config].Relic = 0
    MPPaladinCJSaved[config].Relic_Low = "最终审判圣契"
    MPPaladinCJSaved[config].Relic_Normal = "永恒之塔圣契"
    MPPaladinCJSaved[config].RelicBoss = 0

    -- 治疗石、糖水茶
    MPPaladinCJSaved[config].HealthStone = 1
    MPPaladinCJSaved[config].HealthStone_Value = 30
    MPPaladinCJSaved[config].HerbalTea = 1
    MPPaladinCJSaved[config].HerbalTea_Value = 20
    MPPaladinCJSaved[config].HerbalTeaMana = 0
    MPPaladinCJSaved[config].HerbalTeaMana_Value = 20

    MPPaladinCJSaved[config].Protection = 0
    MPPaladinCJSaved[config].Protection_Value = 10
    MPPaladinCJSaved[config].DivineShield = 0
    MPPaladinCJSaved[config].DivineShield_Value = 10

    -- SuperWoW,UnitXP
    MPPaladinCJSaved[config].SuperWoW = 1
    MPPaladinCJSaved[config].UnitXP = 1


    -- 通用
    MPPaladinCJSaved[config].Power = 0
    MPPaladinCJSaved[config].Pick = 0

end


function InitPaladinCJSetPart1()
    checkButton_HolinessAura:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].HolinessAura))

    checkButton_Consecration:SetChecked( MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Consecration) )
    checkButton_Repentance:SetChecked( MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Repentance) )
    checkButton_RepentanceBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].RepentanceBoss))

    checkButton_Trinket_Upper:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Trinket_Upper))
    checkButton_TUBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].TUBoss))
    checkButton_Trinket_Below:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Trinket_Below))
    checkButton_TBBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].TBBoss))

    checkButton_Target:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Target))
    checkButton_Exorcism:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Exorcism))
    checkButton_HammerWrath:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].HammerWrath))
    checkButton_HammerWrathBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].HammerWrathBoss))


    checkButton_HealthStone:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].HealthStone))
    slider_HealthStone:SetValue(MPPaladinCJSaved[ConfigCurrent].HealthStone_Value)
    if MPPaladinCJSaved[ConfigCurrent].HealthStone==1 then
        color_HealthStone = "|cFFFFD100"
    else
        color_HealthStone = "|cFF888888"
    end
    _G[slider_HealthStone:GetName().."Text"]:SetText(color_HealthStone.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HealthStone_Value .."%|r")

    checkButton_HerbalTea:SetChecked(MPPaladinCJSaved[ConfigCurrent].HerbalTea)
    slider_HerbalTea:SetValue(MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value)
    if MPPaladinCJSaved[ConfigCurrent].HerbalTea==1 then
        color_HerbalTea = "|cFFFFD100"
    else
        color_HerbalTea = "|cFF888888"
    end
    _G[slider_HerbalTea:GetName().."Text"]:SetText(color_HerbalTea.."血线: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTea_Value .."%|r")

    checkButton_HerbalTeaMana:SetChecked(MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana)
    slider_HerbalTeaMana:SetValue(MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value)
    if MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana==1 then
        color_HerbalTeaMana = "|cFFFFD100"
    else
        color_HerbalTeaMana = "|cFF888888"
    end
    _G[slider_HerbalTeaMana:GetName().."Text"]:SetText(color_HerbalTeaMana.."蓝量: ".. MPPaladinCJSaved[ConfigCurrent].HerbalTeaMana_Value .."%|r")



    checkButton_Protection:SetChecked(MPPaladinCJSaved[ConfigCurrent].Protection)
    slider_Protection:SetValue(MPPaladinCJSaved[ConfigCurrent].Protection_Value)
    if MPPaladinCJSaved[ConfigCurrent].Protection==1 then
        color_Protection = "|cFFFFD100"
    else
        color_Protection = "|cFF888888"
    end
    _G[slider_Protection:GetName().."Text"]:SetText(color_Protection.."血线: ".. MPPaladinCJSaved[ConfigCurrent].Protection_Value .."%|r")


    checkButton_DivineShield:SetChecked(MPPaladinCJSaved[ConfigCurrent].DivineShield)
    slider_DivineShield:SetValue(MPPaladinCJSaved[ConfigCurrent].DivineShield_Value)
    if MPPaladinCJSaved[ConfigCurrent].DivineShield==1 then
        color_DivineShield = "|cFFFFD100"
    else
        color_DivineShield = "|cFF888888"
    end
    _G[slider_DivineShield:GetName().."Text"]:SetText(color_DivineShield.."血线: ".. MPPaladinCJSaved[ConfigCurrent].DivineShield_Value .."%|r")
end


function InitPaladinCJSetPart2()
    MPCatRefreshPaladinCJSeal(ConfigCurrent)

    checkButton_Strike:SetChecked(MPPaladinCJSaved[ConfigCurrent].Strike)
    slider_Strike:SetMinMaxValues(1, 5)
    slider_Strike:SetValue(MPPaladinCJSaved[ConfigCurrent].Strike_Value)
    if MPPaladinCJSaved[ConfigCurrent].Strike==1 then
        color_Strike = "|cFFFFD100"
    else
        color_Strike = "|cFF888888"
    end
    if MPPaladinCJSaved[ConfigCurrent].Strike_Value==1 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 神圣打击")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==2 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (均衡)")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==3 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 十字军打击 (均衡)")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==4 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."只用 十字军打击")
    elseif MPPaladinCJSaved[ConfigCurrent].Strike_Value==5 then
        _G[slider_Strike:GetName().."Text"]:SetText(color_Strike.."主用 神圣打击 (三层狂热)")
    end


    checkButton_Relic:SetChecked(MPPaladinCJSaved[ConfigCurrent].Relic)
    for idx_Relic_Low, data_Relic_Low in pairs(modes_Relic_Low) do
        if string.find(data_Relic_Low.text,MPPaladinCJSaved[ConfigCurrent].Relic_Low) then
            UIDropDownMenu_SetSelectedID(dropdown_Relic_Low, data_Relic_Low.value)
            _G[dropdown_Relic_Low:GetName().."Text"]:SetText(data_Relic_Low.text)
        end
    end
    checkButton_RelicBoss:SetChecked(MPPaladinCJSaved[ConfigCurrent].RelicBoss)

    for idx_Relic_Normal, data_Relic_Normal in pairs(modes_Relic_Normal) do
        if string.find(data_Relic_Normal.text,MPPaladinCJSaved[ConfigCurrent].Relic_Normal) then
            UIDropDownMenu_SetSelectedID(dropdown_Relic_Normal, modes_Relic_Normal[idx_Relic_Normal].value)
            _G[dropdown_Relic_Normal:GetName().."Text"]:SetText(data_Relic_Normal.text)
        end
    end


    slider_JudgementOutHP:SetValue(MPPaladinCJSaved[ConfigCurrent].JudgementOutHP)
    _G[slider_JudgementOutHP:GetName().."Text"]:SetText("目标生命 <".. MPPaladinCJSaved[ConfigCurrent].JudgementOutHP .." 不审判")

    checkButton_RacialTraits:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].RacialTraits))
    checkButton_RacialTraitsBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].RacialTraitsBoss))
    checkButton_Soulspeed:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Soulspeed))
    checkButton_SoulspeedBoss:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].SoulspeedBoss))

    slider_Consecration_Level:SetValue(MPPaladinCJSaved[ConfigCurrent].Consecration_Level)
    slider_Consecration:SetValue(MPPaladinCJSaved[ConfigCurrent].Consecration_Priority)
    if MPPaladinCJSaved[ConfigCurrent].Consecration==1 then
        color_Consecration = "|cFFFFD100"
    else
        color_Consecration = "|cFF888888"
    end
    if MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==1 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 低|r")
    elseif MPPaladinCJSaved[ConfigCurrent].Consecration_Priority==2 then
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 中|r")
    else
        _G[slider_Consecration:GetName().."Text"]:SetText(color_Consecration.."优先级: 高|r")
    end

    checkButton_Power:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Power))
    checkButton_Pick:SetChecked(MPToBoolean(MPPaladinCJSaved[ConfigCurrent].Pick))
end

function MPInitPaladinCJSettings()
    restoring = true
    if not MPPaladinCJSaved then
        MPPaladinCJSaved = {}

        -- 第一套配置
        if not MPPaladinCJSaved[1] then
            MPPaladinCJSaved[1] = {}
            MPResetPaladinCJSettings(1)
        end

        -- 第二套配置
        if not MPPaladinCJSaved[2] then
            MPPaladinCJSaved[2] = {}
            MPResetPaladinCJSettings(2)
        end

        -- 第三套配置
        if not MPPaladinCJSaved[3] then
            MPPaladinCJSaved[3] = {}
            MPResetPaladinCJSettings(3)
        end
    end

    if MPPaladinCJSaved.Version ~= PaladinCJSettingsUIVersion then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."重置[惩戒骑宏]当前配置，这是新版插件正常数据更新！|r")
        MPPaladinCJSaved[1] = {}
        MPPaladinCJSaved[2] = {}
        MPPaladinCJSaved[3] = {}
        MPResetPaladinCJSettings(1)
        MPResetPaladinCJSettings(2)
        MPResetPaladinCJSettings(3)
    end

    ConfigButton[1]:SetChecked(false)
    ConfigButton[2]:SetChecked(false)
    ConfigButton[3]:SetChecked(false)
    ConfigButton[ConfigCurrent]:SetChecked(true)


    if CatUISettingsPaladinCJ:IsVisible() then MPCatPaladinApplyControl("RET", ConfigCurrent) end
    InitPaladinCJSetPart1()
    InitPaladinCJSetPart2()
    restoring = false

    if CatUISettingsPaladinCJ:IsVisible() then
        MPCatPaladinSealInit()
    end

end


-- 只刷新当前配置的圣印控件，避免重置其他控件或反向覆盖公共选择。
function MPCatRefreshPaladinCJSeal(config)
    if ConfigCurrent ~= config then return end
    local saved = MPPaladinCJSaved and MPPaladinCJSaved[config]
    if not saved then return end
    local previous = restoring
    restoring = true
    checkButton_Seal:SetChecked(MPToBoolean(saved.Seal))
    slider_Seal:SetValue(saved.Seal_Value or 1)
    RefreshSealLabel()
    restoring = previous
end

-- 面板只刷新对应配置的奉献控件，不触发完整设置初始化。
function MPCatRefreshPaladinCJConsecration(config)
    if ConfigCurrent ~= config then return end
    local saved = MPPaladinCJSaved[ConfigCurrent]
    checkButton_Consecration:SetChecked(MPToBoolean(saved.Consecration))
    if saved.Consecration==1 then color_Consecration="|cFFFFD100" else color_Consecration="|cFF888888" end
    slider_Consecration:SetValue(saved.Consecration_Priority)
end

CatUISettingsPaladinCJ:SetScript("OnShow", function()
    MPCatPaladinApplyControl("RET", ConfigCurrent)
    MPCatRefreshPaladinCJSeal(ConfigCurrent)
    MPCatPaladinSealInit()
end)
