--[[
    SM_ItemLink.lua - 物品链接插入功能
    当超级宏窗口打开时，在背包、角色面板、专业技能窗口中，
    按Shift/Alt/Ctrl点击物品可将物品名称或链接插入到宏编辑框中。
    同时为专业技能界面提供点击插入材料链接的支持。
--]]

-- 根据当前标签页将文本插入到对应的编辑框
function SuperMacroFrame_InsertText(text)
    if ( SM_VARS.tabShown=="regular" ) then
        SuperMacroFrameText:Insert(text);
    elseif ( SM_VARS.tabShown=="super") then
        SuperMacroFrameSuperText:Insert(text);
    end
end

-- 处理物品链接的插入逻辑
-- 根据按键组合决定插入链接、物品名或带引号的物品名
function SuperMacroFrame_InsertItemText(link)
    if ( not link ) then return end;
    -- Alt键：直接插入物品链接
    if ( IsAltKeyDown() ) then
        SuperMacroFrame_InsertText(link);
        return 1;
    end
    -- Shift键：插入物品名称
    if ( IsShiftKeyDown() ) then
        local item=ItemLinkToName(link);
        -- Ctrl+Shift：插入带引号的物品名称
        if ( IsControlKeyDown() ) then
            SuperMacroFrame_InsertText('"'..item..'"');
        else
            SuperMacroFrame_InsertText(item);
        end
        return 1;
    end
end

-- 按键组合说明：
-- Alt         = 插入物品链接 [链接]
-- Shift       = 插入物品名称
-- Ctrl+Shift  = 插入带引号的物品名称 "物品名称"

-- ==================== 背包物品点击重写 ====================
-- 重写背包物品点击函数，超级宏窗口打开时优先插入物品名称/链接
local oldContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick;
function ContainerFrameItemButton_OnClick(button, ignoreShift)
    if ( button=="LeftButton" and not ignoreShift and SuperMacroFrame:IsVisible() ) then
        local link = GetContainerItemLink(this:GetParent():GetID(), this:GetID());
        if ( not SuperMacroFrame_InsertItemText(link) ) then
            -- 如果未插入（例如未按组合键），则执行原始功能
            oldContainerFrameItemButton_OnClick(button, ignoreShift);
        end
        return;
    end
    oldContainerFrameItemButton_OnClick(button, ignoreShift);
end

-- ==================== 角色面板物品点击重写 ====================
-- 重写角色面板装备槽点击函数，超级宏窗口打开时优先插入物品信息
local oldPaperDollItemSlotButton_OnClick = PaperDollItemSlotButton_OnClick;
function PaperDollItemSlotButton_OnClick(button, ignoreShift)
    if ( button=="LeftButton" and not ignoreShift and SuperMacroFrame:IsVisible() ) then
        local link = GetInventoryItemLink("player", this:GetID());
        if ( not SuperMacroFrame_InsertItemText(link) ) then
            oldPaperDollItemSlotButton_OnClick(button, ignoreShift);
        end
        return;
    end
    oldPaperDollItemSlotButton_OnClick(button, ignoreShift);
end

-- ==================== 角色背包槽点击重写 ====================
local oldBagSlotButton_OnClick = BagSlotButton_OnClick;
function BagSlotButton_OnClick()
    if ( arg1=="LeftButton" and SuperMacroFrame:IsVisible() ) then
        this:SetChecked(not this:GetChecked());
        local link = GetInventoryItemLink("player", this:GetID());
        if ( not SuperMacroFrame_InsertItemText(link) ) then
            oldBagSlotButton_OnClick();
        end
        return;
    end
    oldBagSlotButton_OnClick();
end

local oldBagSlotButton_OnShiftClick = BagSlotButton_OnShiftClick;
function BagSlotButton_OnShiftClick()
    if ( SuperMacroFrame:IsVisible() ) then
        this:SetChecked(not this:GetChecked());
        local link = GetInventoryItemLink("player", this:GetID());
        if ( not SuperMacroFrame_InsertItemText(link) ) then
            oldBagSlotButton_OnShiftClick();
        end
        return;
    end
    oldBagSlotButton_OnShiftClick();
end

-- ==================== 专业技能界面物品点击支持 ====================
-- 在专业技能（如裁缝、锻造等）和制造界面中，支持通过组合键插入配方或材料链接
-- 按键说明：
-- Alt         = 插入配方链接
-- Ctrl+Alt    = 插入所有材料链接（带数量）
-- Shift       = 插入物品名称（根据宏窗口状态）
-- 在聊天输入框打开时，Shift点击同样有效

-- 专业技能图标点击处理
function SM_TradeSkillSkillButton_OnClick(button)
    -- 先执行原始点击
    old_SM_TradeSkillSkillButton_OnClick(button);
    local index = TradeSkillFrame.selectedSkill;
    local link = GetTradeSkillItemLink(index);
    if ( link ) then
        -- 超级宏窗口打开时的处理
        if ( SuperMacroFrame:IsVisible() and IsAltKeyDown() ) then
            if ( IsControlKeyDown() ) then
                -- Ctrl+Alt：插入所有材料链接
                for i=1, GetTradeSkillNumReagents(index) do
                    local link = GetTradeSkillReagentItemLink(index, i);
                    local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo( index, i);
                    if ( reagentCount and link ) then
                        SuperMacroFrame_InsertText(" "..reagentCount.."x"..link);
                    end
                end
            else
                -- Alt：插入配方链接
                SuperMacroFrame_InsertText(link);
            end
            return;
        end
        if ( SuperMacroFrame:IsVisible() and IsShiftKeyDown() ) then
            -- Shift：插入物品名称或带引号名称
            SuperMacroFrame_InsertItemText(link);
        end
        -- 聊天输入框打开时的处理
        if ( ChatFrameEditBox:IsVisible() and IsShiftKeyDown() ) then
            if ( IsControlKeyDown() ) then
                for i=1, GetTradeSkillNumReagents(index) do
                    local link = GetTradeSkillReagentItemLink(index, i);
                    local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo( index, i);
                    if ( reagentCount and link ) then
                        ChatFrameEditBox:Insert(" "..reagentCount.."x"..link);
                    end
                end
            else
                ChatFrameEditBox:Insert(link);
            end
            return;
        end
    end
end

-- 制造界面按钮点击处理
function SM_CraftButton_OnClick(button)
    old_SM_CraftButton_OnClick(button);
    local index = GetCraftSelectionIndex();
    local link = GetCraftItemLink(index);
    if ( link ) then
        if ( SuperMacroFrame:IsVisible() and IsAltKeyDown() ) then
            if ( IsControlKeyDown() ) then
                for i=1, GetCraftNumReagents(index) do
                    local link = GetCraftReagentItemLink(index, i);
                    local reagentName, reagentTexture, reagentCount = GetCraftReagentInfo( index, i);
                    if ( reagentCount and link ) then
                        SuperMacroFrame_InsertText(" "..reagentCount.."x"..link);
                    end
                end
            else
                SuperMacroFrame_InsertText(link);
            end
            return;
        end
        if ( SuperMacroFrame:IsVisible() and IsShiftKeyDown() ) then
            SuperMacroFrame_InsertItemText(link);
        end
        if ( ChatFrameEditBox:IsVisible() and IsShiftKeyDown() ) then
            if ( IsControlKeyDown() ) then
                for i=1, GetCraftNumReagents(index) do
                    local link = GetCraftReagentItemLink(index, i);
                    local reagentName, reagentTexture, reagentCount = GetCraftReagentInfo( index, i);
                    if ( reagentCount and link ) then
                        ChatFrameEditBox:Insert(" "..reagentCount.."x"..link);
                    end
                end
            else
                ChatFrameEditBox:Insert(link);
            end
            return;
        end
    end
end

-- 重写专业技能材料图标的点击事件，支持在宏编辑窗口中插入
function SM_TradeSkillItem_OnClick()
    local old_SM_TradeSkillReagent_OnClick = TradeSkillReagent1:GetScript("OnClick");
    for i=1, 8 do
        local item = getglobal("TradeSkillReagent"..i);
        item:SetScript("OnClick", function()
            if ( SuperMacroFrame:IsVisible()) then
                local link = GetTradeSkillReagentItemLink( TradeSkillFrame.selectedSkill, this:GetID());
                if ( link ) then
                    SuperMacroFrame_InsertItemText(link);
                    return;
                end
            end
            if ( old_SM_TradeSkillReagent_OnClick ) then
                old_SM_TradeSkillReagent_OnClick();
            end
        end);
    end

    -- 重写技能图标点击，支持Alt、Shift等组合键
    local old_SM_TradeSkillSkillIcon_OnClick = TradeSkillSkillIcon:GetScript("OnClick");
    TradeSkillSkillIcon:SetScript("OnClick", function()
        local index = TradeSkillFrame.selectedSkill;
        local link = GetTradeSkillItemLink(index);
        if ( link ) then
            if ( SuperMacroFrame:IsVisible() and IsAltKeyDown() ) then
                if ( IsControlKeyDown() ) then
                    for i=1, GetTradeSkillNumReagents(index) do
                        local link = GetTradeSkillReagentItemLink(index, i);
                        local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo( index, i);
                        if ( reagentCount and link ) then
                            SuperMacroFrame_InsertText(" "..reagentCount.."x"..link);
                        end
                    end
                else
                    SuperMacroFrame_InsertText(link);
                end
                return;
            end
            local inserted;
            if ( SuperMacroFrame:IsVisible() and IsShiftKeyDown() ) then
                inserted=SuperMacroFrame_InsertItemText(link);
            end
            if ( ChatFrameEditBox:IsVisible() and IsShiftKeyDown() ) then
                if ( IsControlKeyDown() ) then
                    for i=1, GetTradeSkillNumReagents(index) do
                        local link = GetTradeSkillReagentItemLink(index, i);
                        local reagentName, reagentTexture, reagentCount = GetTradeSkillReagentInfo( index, i);
                        if ( reagentCount and link ) then
                            ChatFrameEditBox:Insert(" "..reagentCount.."x"..link);
                        end
                    end
                else
                    ChatFrameEditBox:Insert(link);
                end
                return;
            end
            if ( inserted ) then return end;
        end
        if ( old_SM_TradeSkillSkillIcon_OnClick )then
            old_SM_TradeSkillSkillIcon_OnClick();
        end
    end);
end

-- 制造界面材料图标的点击重写
function SM_CraftItem_OnClick()
    local old_SM_CraftReagent_OnClick = CraftReagent1:GetScript("OnClick");
    for i=1, 8 do
        local item = getglobal("CraftReagent"..i);
        item:SetScript("OnClick", function()
            if ( SuperMacroFrame:IsVisible() ) then
                    local link = GetCraftReagentItemLink(GetCraftSelectionIndex(), this:GetID());
                    if ( link ) then
                        SuperMacroFrame_InsertItemText(link);
                        return;
                    end
            end
            if ( old_SM_CraftReagent_OnClick ) then
                old_SM_CraftReagent_OnClick();
             end
        end);
    end
    local old_SM_CraftIcon_OnClick = CraftIcon:GetScript("OnClick");
    CraftIcon:SetScript("OnClick", function()
        local index = GetCraftSelectionIndex();
        local link = GetCraftItemLink(index);
        if ( link ) then
            if ( SuperMacroFrame:IsVisible() and IsAltKeyDown() ) then
                if ( IsControlKeyDown() ) then
                    for i=1, GetCraftNumReagents(index) do
                        local link = GetCraftReagentItemLink(index, i);
                        local reagentName, reagentTexture, reagentCount = GetCraftReagentInfo( index, i);
                        if ( reagentCount and link ) then
                            SuperMacroFrame_InsertText(" "..reagentCount.."x"..link);
                        end
                    end
                else
                    SuperMacroFrame_InsertText(link);
                end
                return;
            end
            local inserted;
            if ( SuperMacroFrame:IsVisible() and IsShiftKeyDown() ) then
                inserted=SuperMacroFrame_InsertItemText(link);
            end
            if ( ChatFrameEditBox:IsVisible() and IsShiftKeyDown() ) then
                if ( IsControlKeyDown() ) then
                    for i=1, GetCraftNumReagents(index) do
                        local link = GetCraftReagentItemLink(index, i);
                        local reagentName, reagentTexture, reagentCount = GetCraftReagentInfo( index, i);
                        if ( reagentCount and link ) then
                            ChatFrameEditBox:Insert(" "..reagentCount.."x"..link);
                        end
                    end
                else
                    ChatFrameEditBox:Insert(link);
                end
                return;
            end
            if ( inserted ) then return end;
        end
        if ( old_SM_CraftIcon_OnClick ) then
            old_SM_CraftIcon_OnClick();
        end
    end);
end

-- ==================== 法术书技能点击重写 ====================
-- 在超级宏窗口打开时，Shift点击法术书中的技能可插入施法命令或技能名称
local oldSpellButton_OnClick = SpellButton_OnClick;
function SpellButton_OnClick(drag)
    local id = SpellBook_GetSpellID(this:GetID());
    if ( id > MAX_SPELLS ) then
        return;
    end
    -- 如果超级宏窗口打开且按下Shift键
    if ( IsShiftKeyDown() and SuperMacroFrame:IsVisible() ) then
        local spellName, subSpellName = GetSpellName(id, SpellBookFrame.bookType);
        if ( spellName and not IsSpellPassive(id, SpellBookFrame.bookType) ) then
            -- 若有子技能名（如等级）, 拼接显示
            if ( subSpellName and (strlen(subSpellName) > 0) ) then
                spellName=spellName.."("..subSpellName..")";
            end
            -- Ctrl+Shift：带引号技能名，Alt+Shift：纯技能名，仅Shift：插入/cast命令行
            if ( IsControlKeyDown() ) then
                SuperMacroFrame_InsertText('"'..spellName..'"');
            elseif ( IsAltKeyDown() ) then
                SuperMacroFrame_InsertText(spellName);
            else
                SuperMacroFrame_InsertText("\n"..TEXT(SLASH_CAST1).." "..spellName);
            end
        end
        this:SetChecked(not this:GetChecked());
        return;
    end
    -- 否则执行原始点击行为
    oldSpellButton_OnClick(drag);
end