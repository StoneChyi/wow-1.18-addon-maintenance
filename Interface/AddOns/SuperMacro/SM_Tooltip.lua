--[[
    SM_Tooltip.lua - 动作条按钮提示与冷却检测
    挂钩动作条的鼠标提示和冷却查询函数，
    使设置在动作条上的宏（包括常规宏和超级宏）能够显示技能/物品提示，
    并自动替换图标、显示冷却时间。
--]]

-- 选项说明：
-- SM_VARS.macroTip1 = 1：显示技能或物品的鼠标提示
-- SM_VARS.macroTip2 = 1：显示宏脚本内容的鼠标提示

-- 匹配物品名称的正则模式
SM_ITEM_PATTERN = "[%w '%-:]+";
-- 匹配法术名称的正则模式（包含括号、空格等）
SM_SPELL_PATTERN="[%w'%(%) %-:]+";

-- ==================== 重写动作按钮的鼠标提示函数 ====================

-- 标准动作按钮的提示函数重写
local oldActionButton_SetTooltip=ActionButton_SetTooltip; -- 改为局部，避免全局命名冲突 by 武藤纯子酱 2026.9.10
function ActionButton_SetTooltip()
    -- 先执行原始函数显示默认提示
    oldActionButton_SetTooltip();
    local actionid=ActionButton_GetPagedID(this);
    -- 附加自定义提示信息
    SM_ActionButton_SetTooltip(actionid);
end

-- Bongos 动作条插件的提示函数重写
if ( BActionButton_SetTooltip ) then
    local oldBActionButton_SetTooltip = BActionButton_SetTooltip;
    function BActionButton_SetTooltip()
        oldBActionButton_SetTooltip();
        if ( BActionButton and BActionButton.GetPagedID ) then
            local actionid=BActionButton.GetPagedID(this:GetID());
            SM_ActionButton_SetTooltip(actionid);
        end
    end
end


-- Bongos 插件另一种提示方式的重写 [Fixed by Threewords]
if ( BActionButton and BActionButton.UpdateTooltip ) then
    -- 修正：保存旧函数为局部、使用正确的 button 参数、增加 GetPagedID 守卫 by 武藤纯子酱 2026.9.10
    local oldUpdateTooltip = BActionButton.UpdateTooltip;
    BActionButton.UpdateTooltip = function(button)
        oldUpdateTooltip(button);
        if ( BActionButton.GetPagedID ) then
            local actionid=BActionButton.GetPagedID(button:GetID());
            SM_ActionButton_SetTooltip(actionid);
        end
    end
end

-- Discord 动作条插件的提示函数重写
if (DAB_ActionButton_OnEnter ~= nil) then
    local oldDAB_ActionButton_OnEnter=DAB_ActionButton_OnEnter; -- 改为局部，避免全局命名冲突 by 武藤纯子酱 2026.9.10
    DAB_ActionButton_OnEnter = function()
        oldDAB_ActionButton_OnEnter();
        local actionid = this:GetActionID();
        SM_ActionButton_SetTooltip(actionid);
    end
end

-- 核心函数：为动作按钮设置超级宏的额外提示
function SM_ActionButton_SetTooltip(actionid)
    if ( not actionid ) then
        return;
    end
    -- 获取动作按钮上对应的宏名称
    local macroname=GetActionText(actionid);
    if ( macroname ) then
        -- 判断是否为超级宏动作
        local superfound = SM_ACTION and SM_ACTION[actionid];
        local macro, body;
        if ( superfound ) then
            -- 超级宏：获取名称和内容
            macro, _, body = GetSuperMacroInfo(superfound);
            if ( macro ) then
                GameTooltipTextLeft1:SetText(macro);
                GameTooltip:Show();
            end
        else
            -- 常规宏：通过名称查找（未找到时编号为 0，先判定避免无效下标） by 武藤纯子酱 2026.9.10
            local id = GetMacroIndexByName(macroname);
            if ( id and id > 0 ) then macro, _, body = GetMacroInfo(id); end;
        end

        -- 如果开启了技能/物品提示，尝试解析宏内第一个技能或物品并显示其官方提示
        if ( macro and SM_VARS and SM_VARS.macroTip1 == 1 ) then
            local actiontype, spell = SM_GetActionSpell(macro, superfound);
            if ( actiontype == "spell" ) then
                local id, book = SM_FindSpell(spell);
                if ( id and book ) then
                    GameTooltip:SetSpell(id, book);
                    -- 如果存在 TheoryCraft 插件，添加它的提示信息
                    if TheoryCraft_AddTooltipInfo then
                        TheoryCraft_AddTooltipInfo(GameTooltip)
                    else
                        -- 否则显示技能等级
                        local s, r = GetSpellName(id, book);
                        if ( r ) then
                            GameTooltipTextRight1:SetText("|cff00ffff"..r.."|r");
                            GameTooltipTextRight1:Show();
                            GameTooltip:Show();
                        end
                    end
                    GameTooltip:Show();
                    return;
                end
            elseif ( actiontype == "item" ) then
                local id, book = FindItem(spell);
                if ( book ) then
                    GameTooltip:SetBagItem(id, book);
                elseif ( id ) then
                    GameTooltip:SetInventoryItem('player', id);
                end
                return;
            end
        end

        -- 如果开启了宏代码提示，在提示框中显示宏的脚本内容
        if ( macro and body and SM_VARS and SM_VARS.macroTip2 == 1 ) then
            if ( not GameTooltipTextLeft1:GetText() ) then return; end
            body = gsub(body, "\n$", "");
            GameTooltipTextLeft1:SetText("|cff00ffff"..macro.."|r");
            GameTooltipTextLeft2:SetText("|cffffffff"..body.."|r");
            GameTooltipTextLeft2:Show();
            GameTooltipTextLeft1:SetWidth(284);
            GameTooltipTextLeft2:SetWidth(284);
            GameTooltip:SetWidth(300);
            GameTooltip:SetHeight(GameTooltipTextLeft1:GetHeight() + GameTooltipTextLeft2:GetHeight() + 23);
            GameTooltipTextLeft2:SetNonSpaceWrap(true);
            return;
        end
    end
    -- 如果没有特殊提示，将所有提示的等级文本高亮显示
    if ( GameTooltipTextRight1:GetText() ) then
        local t = GameTooltipTextRight1:GetText();
        GameTooltipTextRight1:SetText("|cff00ffff"..t.."|r");
    end
    -- 特殊处理攻击技能的提示，防止空指针（使用本地化 ATTACK，非英文客户端也可用） by 武藤纯子酱 2026.9.10
    if ( GameTooltipTextLeft1:GetText()==ATTACK ) then
        local id, book = FindSpell(ATTACK, "");
        if ( id and book ) then
            GameTooltip:SetSpell(id, book);
            GameTooltip:Show();
        end
    end
end

-- 鼠标离开动作按钮时清除自定义提示
function SM_ActionButton_OnLeave()
    this.updateTooltip=nil;
    GameTooltipTextLeft2:SetWidth(100);
    GameTooltipTextLeft2:SetText("");
    GameTooltip:Hide();
end

-- ==================== 重写冷却查询函数 ====================

local oldGetActionCooldown = GetActionCooldown;
function GetActionCooldown( actionid )
    local macro = GetActionText(actionid);
    -- 如果设置了自动检查冷却
    if ( macro and SM_VARS and SM_VARS.checkCooldown == 1 ) then
        local superfound = SM_ACTION and SM_ACTION[actionid];
        local name, icon, body;
        -- 获取宏信息（优先超级宏）
        if ( superfound ) then
            name, icon, body = GetSuperMacroInfo(superfound);
        else
            local id = GetMacroIndexByName(macro); -- 未找到时编号为 0，先判定 by 武藤纯子酱 2026.9.10
            if ( id and id > 0 ) then name, icon, body = GetMacroInfo(id); end;
        end
        if ( not name ) then
            return oldGetActionCooldown( actionid );
        end

        -- 安全获取按钮名称（兼容各种动作条插件）
        local buttonName;
        if ( this and this.GetName ) then
            buttonName = this:GetName();
        end
        if ( not buttonName ) then
            buttonName = "BActionButton"..actionid;
        end

        local macroname, pic;
        if ( this ) then
            macroname = getglobal(buttonName.."Name");
            if ( macroname ) then
                macroname:SetText(name);
            end
            pic = getglobal(buttonName.."Icon");
            if ( pic ) then
                pic:SetTexture(icon);
            end
        end

        -- 解析宏中的动作类型和名称，用于确定冷却
        local actiontype, spell, texture = SM_GetActionSpell(name, superfound);
        if ( actiontype == "spell" ) then
            -- 如果开启了图标自动替换且有对应纹理，更换图标
            if ( SM_VARS and SM_VARS.replaceIcon == 1 and texture and pic ) then
                pic:SetTexture(texture);
            end
            local id, book = SM_FindSpell(spell);
            if not id or not book then
                return 0, 0, 1;
            end
            return GetSpellCooldown( id, book );
        elseif ( actiontype == "item" ) then
            if ( SM_VARS and SM_VARS.replaceIcon == 1 and texture and pic ) then
                pic:SetTexture(texture);
            end
            local id, book, texture, count = FindItem(spell);
            -- 如果物品数量大于1，显示数量并隐藏宏名称
            if ( count and count > 1 and macroname ) then
                macroname:Hide();
                local countFrame = getglobal(buttonName.."Count");
                if ( countFrame ) then
                    countFrame:SetText(count);
                end
            elseif ( macroname ) then
                macroname:Show();
                local countFrame = getglobal(buttonName.."Count");
                if ( countFrame ) then
                    countFrame:SetText("");
                end
            end
            -- 返回物品冷却
            if ( book ) then
                return GetContainerItemCooldown(id, book);
            elseif ( id ) then
                return GetInventoryItemCooldown('player', id);
            end
        end
    end
    -- 默认使用原始冷却查询
    return oldGetActionCooldown( actionid );
end

-- ==================== 解析宏内容，提取第一个法术或物品 ====================

-- 在宏文本中查找第一个法术（支持多种调用方式）
function FindFirstSpell( text )
    if not text then return nil end;
    local body = text;
    -- 如果启用了别名替换，先处理别名
    if (ReplaceAlias and ASFOptions and ASFOptions.aliasOn) then
        body = ReplaceAlias(body);
    end
    local id, book, texture, spell;
    -- 查找 CastSpellByName("法术名")
    while ( string.find(body, "CastSpellByName") ) do
        spell = gsub(body,'^.-CastSpellByName.-%(.-(["\'])(.-)%1.*$','%2');
        id, book = SM_FindSpell(spell);
        if ( id ) then
            texture = GetSpellTexture(id, book);
            break;
        end
        body = gsub(body, "CastSpellByName","",1);
    end
    -- 查找 /cast 命令
    if ( not id and string.find(body,"/cast") ) then
            spell = gsub(body,'^.-/cast *('..SM_SPELL_PATTERN..')[\n]?.*$','%1');
            id, book = SM_FindSpell(spell);
            if ( id and book ) then
                texture = GetSpellTexture(id, book);
            end
    end
    -- 查找 cast("法术名") 形式
    if ( not id ) then
        while ( string.find(body, "[%p%s]cast%(") ) do
            spell = gsub(body,'^.-[%p%s]-cast%(.-(["\'])(.-)%1.*$','%2');
            id, book = SM_FindSpell(spell);
            if ( id ) then
                texture = GetSpellTexture(id, book);
                break;
            end
            body = gsub(body, "[%p%s]cast%(","", 1);
        end
    end
    -- 查找 CastSpell(数字ID, "book") 形式
    if ( not id ) then
        while ( string.find(body, "CastSpell")) do
            -- 修正正则：原模式多一个右括号导致普通单括号调用无法匹配 by 武藤纯子酱 2026.9.10
            spell = gsub(body,'^.-CastSpell.-%(%s*(.-)%s*%).*$','%1');
            local _,_,spellid = strfind(spell,"^(%d+).*");
            if ( spellid ) then
                local _,_,spellbook=strfind(spell,"^.-"..spellid..",%s*'(%a+)'%s*");
                id=spellid;
                book=spellbook or 'spell';
                texture = GetSpellTexture(id, book);
                break;
            end
            body = gsub(body, "CastSpell","", 1);
        end
    end
    return id, book, texture, spell;
end

-- 在宏文本中查找第一个物品（支持多种调用方式）
function FindFirstItem( text )
    if not text then return nil end;
    local body = text;
    if (ReplaceAlias and ASFOptions and ASFOptions.aliasOn) then
        body = ReplaceAlias(body);
    end
    local bag, slot, texture, count, item;
    -- 查找 UseItemByName("物品名")
    if ( strfind(body,"UseItemByName") ) then
        while ( string.find(body, "UseItemByName") ) do
            item = gsub(body,'^.-UseItemByName.-%(.-(["\'])(.-)%1.*$','%2');
            bag, slot, texture, count = FindItem(item);
            if ( bag ) then
                return bag, slot, texture, count, item;
            end
            body = gsub(body, "UseItemByName","", 1);
        end
    end
    -- 查找 /use 命令（数字参数或物品名称）
    if ( strfind(body,"/use") ) then
        while ( string.find(body, "/use") ) do
            if ( strfind(body, '^.-/use *%d') ) then
                -- 数字表示容器或装备槽位
                bag, slot = nil, nil;
                -- 修正：原模式 '/use -(%d+)' 中 - 是字面连字符，"/use 16 4" 永不匹配 by 武藤纯子酱 2026.9.10
                gsub(body,'^.-/use%s*(%d+)[,%s]*(%d*)', function(b,s)
                    bag=tonumber(b);
                    slot=tonumber(s);
                end );
                if ( bag and slot ) then
                    texture, count = GetContainerItemInfo(bag, slot);
                    item = ItemLinkToName(GetContainerItemLink(bag, slot));
                elseif ( bag and bag>0 and bag<=23) then
                    texture, count = GetInventoryItemTexture('player', bag), GetInventoryItemCount('player', bag);
                    item = ItemLinkToName(GetInventoryItemLink('player', bag));
                end
            else
                -- 物品名称
                item = gsub(body,'^.-/use *('..SM_ITEM_PATTERN..')\n?.*$', '%1');
                bag, slot, texture, count = FindItem(item);
            end
            if ( bag ) then
                return bag, slot, texture, count, item;
            end
            body = gsub(body, "/use","", 1);
        end
    end
    -- 查找 use() 函数调用（数字或名称）
    if ( strfind(body,"use") ) then
        while ( string.find(body, "use") ) do
            if ( strfind(body, '^.-use.-%(%s*%d') ) then
                bag, slot = nil, nil;
                gsub(body,'^.-use.-%(.-(%d+)[,%s]*(%d*)', function(b,s)
                    bag=tonumber(b);
                    slot=tonumber(s);
                end );
                if ( bag and slot ) then
                    texture, count = GetContainerItemInfo(bag, slot);
                    item = ItemLinkToName(GetContainerItemLink(bag, slot));
                elseif ( bag and bag>0 and bag<=23) then
                    texture, count = GetInventoryItemTexture('player', bag), GetInventoryItemCount('player', bag);
                    item = ItemLinkToName(GetInventoryItemLink('player', bag));
                end
            else
                item = gsub(body,'^.-use.-%(.-(["\'])('..SM_ITEM_PATTERN..')%1.*$','%2');
                bag, slot, texture, count = FindItem(item);
            end
            if ( bag ) then
                return bag, slot, texture, count, item;
            end
            body = gsub(body, "use","", 1);
        end
    end
    -- 查找 UseInventoryItem(槽位)
    while ( strfind(body, "UseInventoryItem") ) do
        bag = gsub(body,'^.-UseInventoryItem.-(%d+)%s-%).*$','%1');
        if ( bag~=body) then
            texture = GetInventoryItemTexture('player', bag);
            count = GetInventoryItemCount('player', bag);
        end
        if ( texture ) then
            item=ItemLinkToName( GetInventoryItemLink('player', bag) );
            return bag, slot, texture, count, item;
        end
        body = gsub(body, "UseInventoryItem","", 1);
    end
    -- 查找 UseContainerItem(背包,格子)
    while ( strfind(body, "UseContainerItem") ) do
        bag = gsub(body,'^.-UseContainerItem.-(%d+)%s-,%s-(%d+)%s-%).*$','%1');
        slot = gsub(body,'^.-UseContainerItem.-(%d+)%s-,%s-(%d+)%s-%).*$','%2');
        if ( bag~=body and slot~=body) then
            texture, count = GetContainerItemInfo(bag, slot);
        end
        if ( bag~=body and slot~=body and texture ) then
            item=ItemLinkToName( GetContainerItemLink(bag, slot) );
            return bag, slot, texture, count, item;
        end
        body = gsub(body, "UseContainerItem","", 1);
    end
end