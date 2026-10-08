local _, playerClass = UnitClass("player")

S_ChatBarDB = S_ChatBarDB or {
    trackingMode = "modern" -- 默认模式: "native"=原生, "modern"=替换原生按钮, "hide"=隐藏
}

-- 如果检测到pfUI，则默认设置为隐藏，避免冲突
if pfUI and pfUI.env then
    S_ChatBarDB.trackingMode = "hide"
end

local function HasEntries(tbl)
    for _ in pairs(tbl) do
        return true
    end
    return nil
end

local size = 24 -- 默认尺寸
local pulse = true -- 默认启用脉冲效果

local knownTrackingSpellTextures = {
    any = {
        "Racial_Dwarf_FindTreasure", -- 寻找财宝
        "Spell_Nature_Earthquake",   -- 寻找矿物
        "INV_Misc_Flower_02",        -- 寻找草药
        "inv_tradeskillitem_03",     -- 寻找树木 (乌龟服生存)
        "INV_Misc_Fish_28",           -- 寻找渔点(乌龟服钓鱼)
    },
    HUNTER = {
        "Ability_Tracking",          -- 追踪野兽
        "Spell_Holy_PrayerOfHealing",-- 追踪人型生物
        "Spell_Shadow_DarkSummoning",-- 追踪亡灵
        "Ability_Stealth",           -- 追踪隐藏生物
        "Spell_Frost_SummonWaterElemental", -- 追踪元素生物
        "Spell_Shadow_SummonFelHunter",     -- 追踪恶魔
        "Ability_Racial_Avatar",     -- 追踪巨人
        "INV_Misc_Head_Dragon_01"    -- 追踪龙类
    },
    PALADIN = {
        "Spell_Holy_SenseUndead"     -- 感知亡灵
    },
    WARLOCK = {
        "Spell_Shadow_Metamorphosis" -- 感知恶魔
    },
    DRUID = {
        "Ability_Tracking"           -- 追踪人型生物（猎豹形态）
    }
}

local state = {
    texture = nil,
    spells = {}
}

-- 创建主框架
local TrackingFrame = CreateFrame("Button", "TrackingFrame", UIParent)
TrackingFrame:SetFrameStrata("HIGH")
TrackingFrame:SetWidth(size)
TrackingFrame:SetHeight(size)
TrackingFrame:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 10, 30)

TrackingFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
TrackingFrame:SetBackdropColor(0, 0, 0, 0.8)

-- 图标
TrackingFrame.icon = TrackingFrame:CreateTexture(nil, "BACKGROUND")
TrackingFrame.icon:SetTexCoord(0, 1, 0, 1)
TrackingFrame.icon:SetAllPoints(TrackingFrame)

-- 菜单
TrackingFrame.menu = CreateFrame("Frame", "TrackingDropDownMenu", nil, "UIDropDownMenuTemplate")

-- 事件
TrackingFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TrackingFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
TrackingFrame:RegisterEvent("SPELLS_CHANGED")
TrackingFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
TrackingFrame:SetScript("OnEvent", function()
    local event = arg1
    if event == "SPELLS_CHANGED" then
        state.spells = {}
    end

    -- 三种模式控制
    if S_ChatBarDB.trackingMode == "native" then
        TrackingFrame:Hide()
        MiniMapTrackingFrame:Show()
    elseif S_ChatBarDB.trackingMode == "modern" then
        TrackingFrame:Show()
        MiniMapTrackingFrame:Hide()
    elseif S_ChatBarDB.trackingMode == "hide" then
        TrackingFrame:Hide()
        MiniMapTrackingFrame:Hide()
    end

    TrackingFrame:RefreshSpells()
    local texture = GetTrackingTexture()
    if texture and texture ~= state.texture then
        state.texture = texture
        TrackingFrame.pulse = nil
        TrackingFrame.icon:SetTexture(texture)
        TrackingFrame.icon:SetVertexColor(1, 1, 1, 1)
    elseif not texture then
        state.texture = nil
        if pulse and HasEntries(state.spells) then
            TrackingFrame.pulse = true
            TrackingFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            TrackingFrame.icon:SetVertexColor(1, 1, 1, 1)
        else
            TrackingFrame.pulse = nil
            TrackingFrame:Hide()
        end
    end
end)

-- OnUpdate 脉冲效果
TrackingFrame:SetScript("OnUpdate", function()
    if TrackingFrame.pulse then
        local _,_,_,alpha = TrackingFrame.icon:GetVertexColor()
        local fpsmod = GetFramerate() / 30
        if not alpha or alpha >= 0.9 then
            TrackingFrame.modifier = -0.03 / fpsmod
        elseif alpha <= 0.5 then
            TrackingFrame.modifier = 0.03 / fpsmod
        end
        TrackingFrame.icon:SetVertexColor(1,1,1,alpha + TrackingFrame.modifier)
    end
end)

-- 点击处理
TrackingFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
TrackingFrame:SetScript("OnClick", function()
    local button = arg1
    if button == "LeftButton" then
        TrackingFrame:InitMenu()
        ToggleDropDownMenu(1, nil, TrackingFrame.menu, this, 0, 0)
    elseif button == "RightButton" then
        -- 循环模式: native → modern → hide → native
        if S_ChatBarDB.trackingMode == "native" then
            S_ChatBarDB.trackingMode = "modern"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 现代 (modern)|r")
        elseif S_ChatBarDB.trackingMode == "modern" then
            S_ChatBarDB.trackingMode = "hide"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 隐藏 (hide)|r")
        else
            S_ChatBarDB.trackingMode = "native"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 原生 (native)|r")
        end

        -- 应用模式
        if S_ChatBarDB.trackingMode == "native" then
            TrackingFrame:Hide()
            MiniMapTrackingFrame:Show()
        elseif S_ChatBarDB.trackingMode == "modern" then
            TrackingFrame:Show()
            MiniMapTrackingFrame:Hide()
        elseif S_ChatBarDB.trackingMode == "hide" then
            TrackingFrame:Hide()
            MiniMapTrackingFrame:Hide()
        end
    end
end)

-- Tooltip
TrackingFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if state.texture then
        GameTooltip:SetTrackingSpell()
    else
        GameTooltip:SetText("没有追踪")
    end
    GameTooltip:Show()
end)
TrackingFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 刷新法术
function TrackingFrame:RefreshSpells()
    local isCatForm = self:PlayerIsDruidInCatForm(playerClass)
    state.spells = {}
    for tabIndex = 1, GetNumSpellTabs() do
        local name, texture, offset, numSpells = GetSpellTabInfo(tabIndex)
        for spellIndex = offset + 1, offset + numSpells do
            local spellTexture = GetSpellTexture(spellIndex, BOOKTYPE_SPELL)
            if name == "综合" then
                for _, textureKey in pairs(knownTrackingSpellTextures.any) do
                    if spellTexture and strfind(spellTexture, textureKey) then
                        state.spells[textureKey] = {
                            index = spellIndex,
                            name = GetSpellName(spellIndex, BOOKTYPE_SPELL),
                            texture = spellTexture
                        }
                    end
                end
            end
            if knownTrackingSpellTextures[playerClass] then
                for _, textureKey in pairs(knownTrackingSpellTextures[playerClass]) do
                    if spellTexture and strfind(spellTexture, textureKey) then
                        state.spells[textureKey] = {
                            index = spellIndex,
                            name = GetSpellName(spellIndex, BOOKTYPE_SPELL),
                            texture = spellTexture
                        }
                    end
                end
            end
        end
    end
    if playerClass == "DRUID" and not isCatForm then
        state.spells["Ability_Tracking"] = nil
        TrackingFrame.pulse = true
        TrackingFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        TrackingFrame.icon:SetVertexColor(1, 1, 1, 1)
    end
end

-- 猎豹形态检测
function TrackingFrame:PlayerIsDruidInCatForm(class)
    if class == "DRUID" then
        for i = 0, 31 do
            local texture = GetPlayerBuffTexture(i)
            if not texture then break end
            if strfind(texture, "Ability_Druid_CatForm") then
                return true
            end
        end
    end
    return false
end

-- 初始化菜单
function TrackingFrame:InitMenu()
    UIDropDownMenu_Initialize(self.menu, function()
        UIDropDownMenu_AddButton({ text = "追踪类型", isTitle = true })
        for _, spell in pairs(state.spells) do
            local spellName = spell.name
            UIDropDownMenu_AddButton({
                text = spellName,
                icon = spell.texture,
                checked = spell.texture == state.texture,
                func = function()
                    CastSpellByName(spellName)
                    CloseDropDownMenus()
                end
            })
        end
    end, "MENU")
end

-- 可拖动
TrackingFrame:SetMovable(true)
TrackingFrame:RegisterForDrag("LeftButton")
TrackingFrame:SetScript("OnDragStart", function() this:StartMoving() end)
TrackingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

TrackingFrame:Hide()