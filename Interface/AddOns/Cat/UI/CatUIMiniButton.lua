

local ADDON_NAME = "CatMinimapButton"


-- 创建小地图按钮
local miniButton = CreateFrame("Button", ADDON_NAME.."Frame", Minimap)
miniButton:SetFrameStrata("HIGH")
miniButton:SetWidth(32)  -- 按钮大小
miniButton:SetHeight(32)
miniButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
miniButton:SetFrameLevel(1)

-- 设置初始位置（小地图右侧）
miniButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)

function MPInitMiniButton()
    if MPPublicSaved and MPPublicSaved.MiniButtonX and MPPublicSaved.MiniButtonY then
        -- 设置存储位置
        miniButton:SetPoint("CENTER", Minimap, "CENTER", MPPublicSaved.MiniButtonX, MPPublicSaved.MiniButtonY)
    else
        -- 设置初始位置（小地图右侧）
        miniButton:SetPoint("CENTER", Minimap, "CENTER", 54, -58)
    end
end

-- ==========================================
-- 1. 圆形背景（修复版）
-- ==========================================
miniButton.background = miniButton:CreateTexture(nil, "BACKGROUND")
miniButton.background:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")  -- 使用团队标记图标集
miniButton.background:SetTexCoord(0.5, 1, 0.5, 1)  -- 选择紫色圆形部分
miniButton.background:SetWidth(24)  -- 与按钮同尺寸
miniButton.background:SetHeight(24)
miniButton.background:SetPoint("CENTER", 0, 0)

-- ==========================================
-- 2. 中心图标（调整尺寸）
-- ==========================================
miniButton.icon = miniButton:CreateTexture(nil, "ARTWORK")
miniButton.icon:SetTexture("Interface\\Icons\\inv_pet_cats_siamesecat")
miniButton.icon:SetWidth(24)  -- 比背景小
miniButton.icon:SetHeight(24)
miniButton.icon:SetPoint("CENTER", 0, 0)

-- ==========================================
-- 3. 悬停高亮效果
-- ==========================================
miniButton.highlight = miniButton:CreateTexture(nil, "HIGHLIGHT")
miniButton.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
miniButton.highlight:SetBlendMode("ADD")
miniButton.highlight:SetWidth(24)  -- 与背景同尺寸
miniButton.highlight:SetHeight(24)
miniButton.highlight:SetPoint("CENTER", 0, 0)

-- ==========================================
-- 4. 使按钮围绕小地图拖动
-- ==========================================
miniButton:SetMovable(true)
miniButton:RegisterForDrag("LeftButton")

miniButton:SetScript("OnDragStart", function()
    this.isDragging = true
end)

miniButton:SetScript("OnDragStop", function()
    this.isDragging = false
end)

miniButton:SetScript("OnUpdate", function()
    if this.isDragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        mx = mx * UIParent:GetScale()
        my = my * UIParent:GetScale()
        
        -- 计算角度并保持在小地图周围
        local angle = math.atan2(py - my, px - mx)
        local x = math.cos(angle) * 80
        local y = math.sin(angle) * 80
        
        this:ClearAllPoints()
        this:SetPoint("CENTER", Minimap, "CENTER", x, y)

        MPPublicSaved.MiniButtonX = x
        MPPublicSaved.MiniButtonY = y
    end
end)
--[[
-- ==========================================
-- 5. 点击功能
-- ==========================================
miniButton:SetScript("OnClick", function(self, button)

    -- 两个窗口都关闭
    if not CatDebugWindow:IsShown() or not CatUISettingsCatWindow:IsShown() then

        CatDebugWindow:Show()

        -- 根据职业打开相关窗口
        local _, englishClass = UnitClass("player")
        if englishClass == "DRUID" then
            MPInitCatSettings()
            CatUISettingsCatWindow:Show()
        end

    elseif CatDebugWindow:IsShown() and CatUISettingsCatWindow:IsShown() then
        CatDebugWindow:Hide()
        CatUISettingsCatWindow:Hide()
    end

end)
]]

local SettingsWindows = {
    { "MPInitCatSettings", "CatUISettingsCatWindow" },
    { "MPInitBearSettings", "CatUISettingsBearWindow" },
    { "MPInitCOOSettings", "CatUISettingsCOOWindow" },
    { "MPInitDruidHealSettings", "CatUISettingsDruidHealWindow" },
    { "MPInitWarriorArmsSettings", "CatUISettingsWarriorArms" },
    { "MPInitWarriorFurySettings", "CatUISettingsWarriorFury" },
    { "MPInitWarriorEvilSettings", "CatUISettingsWarriorEvil" },
    { "MPInitWarriorTankSettings", "CatUISettingsWarriorTank" },
    { "MPInitPaladinCJSettings", "CatUISettingsPaladinCJ" },
    { "MPInitPaladinHealSettings", "CatUISettingsPaladinHealWindow" },
    { "MPInitPaladinMeleeHealSettings", "CatUISettingsPaladinMeleeHeal" },
    { run = function()
        if type(MPInitPaladinTankSettings) == "function" and type(MPCatPaladinControlHealInit) == "function" then
            MPInitPaladinTankSettings()
            CatUISettingsPaladinTank:Hide()
            CatUISettingsPaladinTank:ClearAllPoints()
            CatUISettingsPaladinTank:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            MPCatPaladinControlHealInit()
            if MPPublicSaved.PaladinHealDisplay == 1 then
                CatPaladinHeal:Show()
            end
        end
    end },
    { run = function()
        if type(MPCatPaladinSealInit) == "function" then
            MPCatPaladinSealInit()
            if MPPublicSaved.PaladinSealDisplay == 1 then
                CatPaladinSeal:Show()
            end
        end
    end },
    { "MPInitRogueSettings", "CatUISettingsRogue" },
    { "MPInitRogueCombatSettings", "CatUISettingsRogueCombat" },
    { "MPInitRogueEnvenomSettings", "CatUISettingsRogueEnvenom" },
    { "MPInitRogueArmorSettings", "CatUISettingsRogueArmor" },
    { "MPInitShamanHealSettings", "CatUISettingsShamanHealWindow" },
    { "MPInitShamanEnhanceSettings", "CatUISettingsShamanEnhanceWindow" },
    { "MPInitShamanElementalSettings", "CatUISettingsShamanElementalWindow" },
    { "MPInitWarlockSDSettings", "CatUISettingsWarlockSD" },
    { "MPInitWarlockFDSettings", "CatUISettingsWarlockFD" },
    { "MPInitWarlockAffSettings", "CatUISettingsWarlockAff" },
    { "MPInitWarlockDemoSettings", "CatUISettingsWarlockDemo" },
    { "MPInitMageArcaneSettings", "CatUISettingsMageArcane" },
    { "MPInitMageFireSettings", "CatUISettingsMageFire" },
    { "MPInitMageFrostSettings", "CatUISettingsMageFrost" },
    { "MPInitPriestHealSettings", "CatUISettingsPriestHealWindow" },
    { "MPInitPriestShadowSettings", "CatUISettingsPriestShadow" },
    { "MPInitPriestDisciplineSettings", "CatUISettingsPriestDiscipline" },
    { "MPInitHunterShotSettings", "CatUISettingsHunterShot" },
    { "MPInitHunterBeastSettings", "CatUISettingsHunterBeast" },
    { "MPInitHunterMeleeSettings", "CatUISettingsHunterMelee" },
    { "MPInitAutoLootSettings", "CatUISettingAutoLoot" },
    { "MPInitInterruptSettings", "CatUISettingsInterrupt" },
    { "MPInitMultilineDotSettings", "CatUISettingsMultilineDot" },
    { "MPInitPowerSettings", "CatUISettingsPower" },
    { "MPInitMenuSettings", "CatUISettingsCatMenu" }
}

function MPCatSettingsCloseAll()
    if not MPPublicSaved then
        MPPublicSaved = {}
    end
    if not MPPublicSaved.AllClass then
        MPPublicSaved.AllClass = 1
    end

    MPRefreshAndCenterSettingsWindows(SettingsWindows)
end

-- ==========================================
-- 菜单功能
-- ==========================================
function MPCreateMiniButtonMenu()

    local dropdown = CreateFrame("Frame", "CatMinimapButtonDropdown", miniButton, "UIDropDownMenuTemplate")

    -- 修改下拉菜单外观为Tooltip风格
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
    
    dropdown:SetBackdrop(backdrop)
    dropdown:SetBackdropColor(0, 0, 0, 0.8)
    dropdown:SetBackdropBorderColor(0.8, 0.6, 0, 1)

    dropdown:SetFrameStrata("TOOLTIP")
    
    
    local function InitializeMenu(level)
        -- 标题
        local info = {}
        info.isTitle = 1
        info.text = MPLanguage.UI_BindingHeader
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info)

        local info = {}
        info.isTitle = 1
        info.text = MPLanguage.UI_Mon_Version.." |cFFDDDDDD"..MPCatAddonVer.."|r ]"
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info)

       -- 分隔线
        info = {}
        info.text = " "
        info.disabled = 1
        UIDropDownMenu_AddButton(info)


        -- 打开职业一键宏
        info = {}
        info.text = MPLanguage.UI_OpenAllMacros
        info.notCheckable = 1
        info.func = function() MPCatSettingsCloseAll() CatUISettingsCatMenu:Show() end
        UIDropDownMenu_AddButton(info,1)

       -- 分隔线
        info = {}
        info.text = " "
        info.disabled = 1
        UIDropDownMenu_AddButton(info)


        -- 打开读条打断
        info = {}
        info.text = "|cFFDD4080"..MPLanguage.UI_Set_InterruptTitle.."|r"
        info.notCheckable = 1
        info.func = function() MPCatSettingsCloseAll() CatUISettingsInterrupt:Show() end
        UIDropDownMenu_AddButton(info)

        -- 打开多线DOT
        info = {}
        info.text = "|cFFDD4080"..MPLanguage.UI_Set_MultiDotTitle.."|r"
        info.notCheckable = 1
        info.func = function() MPCatSettingsCloseAll() CatUISettingsMultilineDot:Show() end
        UIDropDownMenu_AddButton(info)

        -- 打开功能药水
        info = {}
        info.text = "|cFFDD4080"..MPLanguage.UI_Set_PowerTitle.."|r"
        info.notCheckable = 1
        info.func = function() MPCatSettingsCloseAll() CatUISettingsPower:Show() end
        UIDropDownMenu_AddButton(info)


        -- 打开自动拾取
        info = {}
        info.text = "|cFFDD4080"..MPLanguage.UI_Set_AutoLootTitle.."|r"
        info.notCheckable = 1
        info.func = function() MPCatSettingsCloseAll() CatUISettingAutoLoot:Show() end
        UIDropDownMenu_AddButton(info)

       -- 分隔线
        info = {}
        info.text = " "
        info.disabled = 1
        UIDropDownMenu_AddButton(info)


        -- 打开监视窗口
        info = {}
        info.text = "|cFF007582"..MPLanguage.UI_Mini_AddonMonitor.."|r"
        info.notCheckable = 1
        info.func = function() CatDebugWindow:Show() MPPublicSaved.DebugWindowDisplay=1 end
        UIDropDownMenu_AddButton(info)


       -- 分隔线
        info = {}
        info.text = " "
        info.disabled = 1
        UIDropDownMenu_AddButton(info)


        -- 打开监视窗口
        info = {}
        if MPPublicSaved.AllClass==0 then
            info.text = MPLanguage.UI_Mini_AllClassClosed
        else
            info.text = MPLanguage.UI_Mini_AllClassOpen
        end
        info.notCheckable = 1
        info.func = function() 
            if MPPublicSaved.AllClass==1 then 
                MPPublicSaved.AllClass=0 
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_CollapseClass)
            else 
                MPPublicSaved.AllClass=1 
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_ExpandClass)
            end
            MPCatSettingsCloseAll()
        end
        UIDropDownMenu_AddButton(info)

       -- 分隔线
        info = {}
        info.text = " "
        info.disabled = 1
        UIDropDownMenu_AddButton(info)


        -- 关闭所有窗口
        info = {}
        info.text = MPLanguage.UI_Mini_CloseAll
        info.notCheckable = 1
        info.func = function() 
            MPCatSettingsCloseAll()
            CatDebugWindow:Hide()
            MPPublicSaved.DebugWindowDisplay=0

            if MPPlayerClass == "PALADIN" or MPPublicSaved.AllClass==1 then
                CatPaladinSeal:Hide()
                MPPublicSaved.PaladinSealDisplay = 0
            end

        end
        UIDropDownMenu_AddButton(info)
    end


    UIDropDownMenu_Initialize(dropdown, InitializeMenu)
    return dropdown
end

-- 点击显示菜单
miniButton:SetScript("OnClick", function(self, button)

    if arg1 == "LeftButton" then

        if CatUISettingsCatMenu:IsVisible() then
            MPCatSettingsCloseAll()
        else
            MPCatSettingsCloseAll()
            CatUISettingsCatMenu:Show()
        end

    elseif arg1 == "RightButton" then

        local dropdown = MPCreateMiniButtonMenu()

        --local x, y = GetCursorPosition()
        --local scale = UIParent:GetEffectiveScale()
        
        -- 显示在鼠标左侧
        ToggleDropDownMenu(
            1, nil, dropdown, 
            "cursor", 
            -20, 0, 
            nil, nil, 
            "TOPRIGHT", "TOPLEFT"
        )
        --ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)

    end

end)


-- ==========================================
-- 6. 鼠标悬停提示
-- ==========================================
miniButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText(MPLanguage.UI_BindingHeader)
    GameTooltip:AddLine(MPLanguage.UI_LeftClickOpen, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

miniButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 确保按钮显示
miniButton:Show()
