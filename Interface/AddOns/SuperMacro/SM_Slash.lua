--[[
    SM_Slash.lua - 斜杠命令和扩展工具函数
    定义 /supermacro, /macro, /smacro 及其他扩展命令。
    提供计时器、物品查找、法术查找、 Buff/Debuff 检测、
    交易技能、别名替换、调试打印等大量实用功能。
--]]

-- 检测 Superwow 环境（提供扩展 API）
local hasSuperwow; -- 初值交由下方检测赋值 by 武藤纯子酱 2026.9.10
if not GetPlayerBuffID or not CombatLogAdd or not SpellInfo then
    hasSuperwow = false;
else
    hasSuperwow = true;
end;

-- 获取目标的唯一标识（Superwow 下为 GUID，否则返回 0）
local function GetUnitIdentifier(unit)
    if hasSuperwow then
        local _, guid = UnitExists(unit)
        return guid         -- Superwow 提供真正的 GUID
    else
        return 0            -- 默认返回 0
    end
end

-- 避免事件注销时用 getn 判断字典表可能不准
local function TableHasEntries(t)
    if ( not t ) then return false; end
    for _ in pairs(t) do return true; end
    return false;
end

-- 装备槽位名称到索引的映射表（键为大写；查询时用 strupper 归一 by 武藤纯子酱 2026.9.10）
SM_INV_SLOT = {
    ["AMMOSLOT"]=0,
    ["HEADSLOT"]=1,
    ["NECKSLOT"]=2,
    ["SHOULDERSLOT"]=3,
    ["SHIRTSLOT"]=4,
    ["CHESTSLOT"]=5,
    ["WAISTSLOT"]=6,
    ["LEGSSLOT"]=7,
    ["FEETSLOT"]=8,
    ["WRISTSLOT"]=9,
    ["HANDSSLOT"]=10,
    ["FINGER0SLOT"]=11,
    ["FINGER1SLOT"]=12,
    ["TRINKET0SLOT"]=13,
    ["TRINKET1SLOT"]=14,
    ["BACKSLOT"]=15,
    ["MAINHANDSLOT"]=16,
    ["SECONDARYHANDSLOT"]=17,
    ["RANGEDSLOT"]=18,
    ["TABARDSLOT"]=19,
    ["BAG0SLOT"]=20,
    ["BAG1SLOT"]=21,
    ["BAG2SLOT"]=22,
    ["BAG3SLOT"]=23,
}

-- ==================== /supermacro 命令处理 ====================
SlashCmdList["SUPERMACRO"] = function(msg)
    local info = ChatTypeInfo["SYSTEM"];
    local text;
    local cmd = gsub(msg,"^%s*(%a*)%s*(.*)%s*$","%1" );
    local param = gsub(msg,"^%s*(%a*)%s*([%w %p]*)%s*$","%2" );
    
    -- hideaction 子命令：隐藏/显示动作条宏名
    if ( cmd=="hideaction") then
        text = param;
        if ( text == "0" or text=="false") then
            SM_VARS.hideAction = 0;
            HideActionText();
        elseif ( text == "1" or text=="true") then
            SM_VARS.hideAction = 1;
            HideActionText();
        else
            ChatFrame_DisplaySlashHelp("SUPERMACRO",3,3);
        end
        if ( not SM_VARS.hideAction ) then SM_VARS.hideAction = 0; end
        text = "SM_VARS.hideAction is "..SM_VARS.hideAction;
        if ( SuperMacroOptionsFrame:IsVisible() ) then
            SuperMacroOptionsFrame_OnShow();
        end
        DEFAULT_CHAT_FRAME:AddMessage( text, info.r, info.g, info.b, info.id);
        return;
    end
    
    -- printcolor 子命令：设置打印颜色
    if ( cmd=="printcolor" ) then
        text = param;
        if ( text =="default" ) then
            SM_VARS.printColor.r = PRINT_COLOR_DEF.r;
            SM_VARS.printColor.g = PRINT_COLOR_DEF.g;
            SM_VARS.printColor.b = PRINT_COLOR_DEF.b;
            if ( SuperMacroOptionsFrame:IsVisible() ) then
                SuperMacroOptionsFrame_OnShow();
            end
            return;
        end
        if ( gsub(text,"%s*","")=="" ) then
            ChatFrame_DisplaySlashHelp("SUPERMACRO",4,4);
            return;
        end
        local color = gsub(msg, ".*color%s*(.*)","%1");
        local red = gsub(color, "%s*(-?%d*%.*%d*)%s*.*","%1");
        local green = gsub(color, "%s*(-?%d*%.*%d*)%s*(-?%d*%.*%d*)%s*(-?%d*%.*%d*)%s*.*","%2");
        local blue = gsub(color, "%s*(-?%d*%.*%d*)%s*(-?%d*%.*%d*)%s*(-?%d*%.*%d*)%s*.*","%3");
        red = tonumber(red) or 0;
        green = tonumber(green) or 0;
        blue = tonumber(blue) or 0;
        red = (red < 0 and 0) or (red > 1 and 1) or red;
        green = (green < 0 and 0) or (green > 1 and 1) or green;
        blue = (blue < 0 and 0) or (blue > 1 and 1) or blue;
        SM_VARS.printColor = { r=red,g=green,b=blue };
        if ( SuperMacroOptionsFrame:IsVisible() ) then
            SuperMacroOptionsFrame_OnShow();
        end
        return;
    end
    
    -- macrotip 子命令：设置鼠标提示宏代码/法术
    if ( cmd=="macrotip" ) then
        text = param;
        if ( text =="default" ) then
            SM_VARS.macroTip1 = 1;
            SM_VARS.macroTip2 = 0;
            if ( SuperMacroOptionsFrame:IsVisible() ) then
                SuperMacroOptionsFrame_OnShow();
            end
            return;
        end
        text = tonumber(text);
        if ( text and text >= 0 and text <= 3) then
            if ( mod(text, 2) == 1 ) then
                SM_VARS.macroTip1 = 1;
            else
                SM_VARS.macroTip1 = 0;
            end
            if ( text >= 2 ) then
                SM_VARS.macroTip2 = 1;
            else
                SM_VARS.macroTip2 = 0;
            end
            if ( SuperMacroOptionsFrame:IsVisible() ) then
                SuperMacroOptionsFrame_OnShow();
            end
        else
            ChatFrame_DisplaySlashHelp("SUPERMACRO",5,6);
        end
        return;
    end
    
    -- options 子命令：打开设置面板
    if ( cmd=="options" ) then
        ShowUIPanel(SuperMacroOptionsFrame);
        return;
    end

    ChatFrame_DisplaySlashHelp("SUPERMACRO");
    return;
end

-- /macro 命令：无参数时打开超级宏窗口，有参数时运行指定名称的宏
SlashCmdList["MACRO"] = function(msg)
    if(not msg or msg == "") then
        ShowUIPanel(SuperMacroFrame);
    else
        SuperMacro_RunMacro(msg);
    end
end

-- /smacro 命令：运行指定名称或编号的超级宏
SlashCmdList["SMRUNSUPER"] = function(msg)
    if(msg) then
        RunSuperMacro(msg);
    end
end

-- /use 或 /smuse 命令：使用物品
SlashCmdList["SMUSE"] = function(msg)
    use(unpack(ListToTable(msg)));
end

-- /equip 等命令：装备物品
SlashCmdList["SMEQUIP"] = function(msg)
    use(unpack(ListToTable(msg)));
end

-- /equipoff 命令：装备副手物品
SlashCmdList["SMEQUIPOFF"] = function(msg)
    local bag, slot = FindItem(TrimSpaces(msg));
    if ( bag and slot ) then
        PickupContainerItem(bag, slot);
        PickupInventoryItem(17); -- 副手槽位
    end
end

-- /unequip 命令：卸下装备
SlashCmdList["SMUNEQUIP"] = function(msg)
    local name = TrimSpaces(msg);
    if ( not name or name=="" ) then return end
    local bag, bagSlot = FindItem(name);
    local e,f = FindLastEmptyBagSlot();
    -- 仅当物品在装备栏（bag 有值且 bagSlot 为空）且有空袋位时才卸下 by 武藤纯子酱 2026.9.10
    if ( e and bag and not bagSlot ) then
        PickupInventoryItem(bag);
        PickupContainerItem(e,f);
    end
end

-- /print 命令：以自定义颜色打印文本
SlashCmdList["SMPRINT"] = function(msg)
    SM_print(msg);
end

-- /pass 命令：在上一个动作成功时执行
SlashCmdList["SMPASS"] = function(msg)
    Pass(msg);
end

-- /fail 命令：在上一个动作失败时执行
SlashCmdList["SMFAIL"] = function(msg)
    Fail(msg);
end

-- /order 命令：按顺序使用物品或法术，直到一个可用
SlashCmdList["SMDOORDER"] = function(msg)
    DoOrder(unpack(ListToTable(msg)));
end

-- /smchan 命令：无打断地施放通道法术
SlashCmdList["SMCHANNEL"] = function(msg)
    SM_Channel(msg);
end

-- 自定义打印函数，使用设置的颜色
function SM_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, SM_VARS.printColor.r, SM_VARS.printColor.g, SM_VARS.printColor.b);
end

-- 如果游戏缺省斜杠帮助函数，则提供简化版
if ( not ChatFrame_DisplaySlashHelp ) then
    function ChatFrame_DisplaySlashHelp(pre, start, last, frame)
        if ( not frame ) then
            frame=DEFAULT_CHAT_FRAME;
        end
        local info = ChatTypeInfo["SYSTEM"];
        local i = 1;
        if ( type(start) =="number" ) then i = start; end
        if ( i < 1 ) then i =1; end
        local text = TEXT(getglobal(pre.."_HELP_LINE"..i));
        while text do
            frame:AddMessage(text, info.r, info.g, info.b, info.id);
            i = i + 1;
            text = TEXT(getglobal(pre.."_HELP_LINE"..i));
            if ( last and i > last ) then break; end
        end
    end
end

-- /in 命令：延时执行命令（支持重复）
SlashCmdList["SMIN"] = function(msg)
    local _,_,s,r,c = strfind(msg, "(%d+h?%d*m?%d*s?)(%+?)%s+(.*)");
    if ( not c or TrimSpaces(c)=="" ) then return end
    c=gsub(c,"\\n","\n");
    SuperMacro_InEnter(s,c,r);
end

-- 形态简称映射表
SM_SHIFT_FORM = { bear=1,aquatic=2,cat=3,travel=4,moonkin=5, stealth=1, battle=1,defend=2,berzerk=3 };

-- /shift 命令：切换形态
SlashCmdList["SMSHIFT"] = function(msg)
    local form=msg;
    if ( SM_SHIFT_FORM[msg] ) then
        form=SM_SHIFT_FORM[msg];
    end
    CastShapeshiftForm(form);
end

-- /craft 命令：制造物品
SlashCmdList["SMCRAFT"] = function(msg)
    local skill, item, count = unpack(ListToTable(msg));
    count = tonumber(count);
    CraftItem(skill, item, count);
end

-- /sayrandom 命令：随机喊话
SlashCmdList["SMSAYRANDOM"] = function(msg)
    SayRandom(unpack(ListToTable(msg)));
end

-- /unbuff 命令：取消指定 Buff
SlashCmdList["SMCANCELBUFF"] = function(msg)
    CancelBuff(unpack(ListToTable(msg)));
end

-- 随机发送一条消息
function SayRandom(...)
    tinsert(arg, "");
    local r=random(arg.n);
    RunLine(arg[r]);
end

-- ==================== 计时器框架处理 ====================
function SuperMacro_InEnter( sec, cmd, rep)
    if ( not sec or not cmd ) then return end
    local t=SM_INFRAME.events;
    local seconds=sec;
    -- 支持时、分、秒格式
    if ( strfind(seconds,'[hms]') ) then
        seconds=gsub(seconds,'^(%d+)(h?)(%d*)(m?)(%d*)(s?)$', function(hd, h, md, m, sd, s)
            local a=0;
            if ( h=="h" ) then a=a+hd*3600
            else md=hd..md end;
            if ( m=="m" ) then a=a+md*60
            else sd=md..sd end;
            if ( sd~="" ) then a=a+sd end;
            return a;
        end );
    end
    seconds = tonumber(seconds) or 0;
    local s=GetTime()+seconds;
    t[s]={};
    t[s].cmd=cmd;
    t[s].sec=seconds;
    t[s].rep=rep and rep or "";
    t.n=t.n+1;
    if ( not SM_INFRAME.nextTime or s < SM_INFRAME.nextTime ) then
        SM_INFRAME.nextTime = s;
    end
    SM_INFRAME:Show();
end

SM_IN=SuperMacro_InEnter;

-- 计时器每帧更新，执行到期的定时事件
function SM_INFRAME_OnUpdate( )
    local t=this.events;
    if ( getn(t)==0 ) then
        this.nextTime = nil;
        SM_INFRAME:Hide();
        return;
    end
    local now = GetTime();
    if ( this.nextTime and this.nextTime > now ) then
        return;
    end
    for k,v in t do
        if ( k~='n' and k<=now ) then
            RunBody(v.cmd);
            if ( v.rep~="" ) then
                local s=GetTime()+v.sec;
                t[s]={};
                t[s].cmd=v.cmd;
                t[s].sec=v.sec;
                t[s].rep=v.rep;
                t[k]=nil;
            else
                t[k]=nil;
                t.n=t.n-1;
            end
        end
    end
    -- 更新下一个最近事件的时间
    this.nextTime = nil;
    for k in pairs(t) do
        if ( k ~= "n" and ( not this.nextTime or k < this.nextTime ) ) then
            this.nextTime = k;
        end
    end
end

-- Pass 函数：若最近使用的动作成功，则执行备用文本
function Pass(text)
    -- 未点过动作条时 lastActionUsed 为 nil，先判空 by 武藤纯子酱 2026.9.10
    if( lastActionUsed and IsCurrentAction(lastActionUsed) ) then
        RunLine(text);
        return text;
    end
end

-- Fail 函数：若最近使用的动作失败，则执行备用文本
function Fail(text)
    if ( lastActionUsed and not IsCurrentAction(lastActionUsed) ) then
        RunLine(text);
        return text;
    end
end

-- 按名称使用物品
function UseItemByName(item)
    local bag,slot = FindItem(item);
    if ( not bag ) then return; end;
    if ( slot ) then
        UseContainerItem(bag,slot); -- 使用背包中的物品
        return bag, slot;
    else
        UseInventoryItem(bag); -- 使用装备栏物品
        return bag;
    end
end

-- 通用使用函数（支持数字或名称）
function use(bag, slot)
    local b,s=tonumber(bag), tonumber(slot);
    if ( b ) then
        if ( s ) then
            UseContainerItem(bag,slot); -- 数字对应的背包格子
        else
            UseInventoryItem(bag);       -- 装备槽位
        end
    else
        UseItemByName(bag);             -- 按名称使用
    end
end

-- 顺序尝试使用物品或法术，返回第一个成功的
function DoOrder(...)
    for k,i in arg do
        local item=FindItem(i);
        local spell,book=SM_FindSpell(i);
        -- 如果法术可用且冷却为0，优先施法
        if ( spell and GetSpellCooldown(spell,book)==0) then
            CastSpell(spell,book);
            return i, spell, book;
        end
        -- 否则尝试使用物品
        if ( item and SM_GetItemCooldown(i)==0 ) then
            UseItemByName(i);
            -- 修正：原 return 引用了未定义的全局 slot，恒为 nil by 武藤纯子酱 2026.9.10
            return i, item, nil;
        end
    end
end

-- 按名称查询物品冷却（供 DoOrder 使用；不再全局覆盖暴雪 GetItemCooldown API，避免破坏第三方插件 by 武藤纯子酱 2026.9.10）
function SM_GetItemCooldown(item)
    local bag, slot = FindItem(item);
    if ( slot ) then
        return GetContainerItemCooldown(bag, slot);
    elseif ( bag ) then
        return GetInventoryItemCooldown('player', bag);
    end
end

-- 在背包和装备栏中按名称查找物品
function FindItem(item)
    if ( not item ) then return; end
    item = string.lower(ItemLinkToName(item));
    local link;
    -- 先搜索装备栏
    for i = 1,23 do
        link = GetInventoryItemLink("player",i);
        if ( link ) then
            if ( item == string.lower(ItemLinkToName(link)) )then
                return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i);
            end
        end
    end
    -- 再搜索背包
    local count, bag, slot, texture;
    local totalcount = 0;
    for i = 0,NUM_BAG_FRAMES do
        for j = 1,MAX_CONTAINER_ITEMS do
            link = GetContainerItemLink(i,j);
            if ( link ) then
                if ( item == string.lower(ItemLinkToName(link))) then
                    bag, slot = i, j;
                    texture, count = GetContainerItemInfo(i,j);
                    totalcount = totalcount + count;
                end
            end
        end
    end
    return bag, slot, texture, totalcount;
end

-- 获取物品冷却时间
function GetItemCooldown(item)
    local bag, slot = FindItem(item);
    if ( slot ) then
        return GetContainerItemCooldown(bag, slot);
    elseif ( bag ) then
        return GetInventoryItemCooldown('player', bag);
    end
end

-- 查找最后一个空背包格
function FindLastEmptyBagSlot()
    for i=NUM_BAG_FRAMES,0,-1 do
        for j=GetContainerNumSlots(i),1,-1 do
            if not GetContainerItemInfo(i,j) then
                return i,j;
            end
        end
    end
end

-- 将逗号分隔的字符串转换为Lua表
function ListToTable(text)
    local t={};
    -- 如果逗号是物品名称的一部分，用 % 转义
    text=gsub(text, "%%,", "%%044");
    -- 将物品链接转换为名称（因为链接中可能包含逗号）
    text=gsub(text, "|c.-%[(.+)%]|h|r", function(x)
        return gsub(x, ",", "%%044");
    end );
    -- 按逗号分割
    gsub(text, "[^,]+", function(a)
        a = TrimSpaces(a);
        if ( a~="" ) then
            a=gsub(a, "%%044", ",");
            tinsert(t,a);
        end
    end);
    return t;
end

-- 去除字符串首尾空格
function TrimSpaces(str)
    if ( str ) then
        return gsub(str,"^%s*(.-)%s*$","%1");
    end
end

-- 从物品链接中提取物品名称
function ItemLinkToName(link)
    if ( link ) then
        return gsub(link,"^.*%[(.*)%].*$","%1");
    end
end

-- 判断指定 Buff/Debuff 是否由自己施放（依赖 Chronometer 插件）
function IsMyBuff(unitId,name)
    -- 增加 Chronometer.bars 守卫、unitId 局部化避免污染全局 by 武藤纯子酱 2026.9.10
    if not Chronometer or not Chronometer.bars then Print('Error: Chronometer not found.') return false end
    if not UnitExists(unitId) then return false end
    local u = UnitName(unitId)
    for i = 1, 20 do
        -- bars[i] 本身可能为 nil（计时条数不足20） by 武藤纯子酱 2026.9.10
        if ( Chronometer.bars[i] and Chronometer.bars[i].id ) then
            if Chronometer.bars[i].target == u and Chronometer.bars[i].name == name then
                return true
            end
        end
    end
    return false
end

-- 检查自己的周期性效果（依赖 Cursive 插件）
function CheckMyDot(unit, spellName, refreshtime)
    if UnitExists(unit) and not UnitIsFriend("player", unit) and Cursive and Cursive.curses and Cursive.curses.HasCurse then
        local targetGuid = GetUnitIdentifier(unit);
        local spellNameNoRank = spellName;
        local refresh = refreshtime;
        if Cursive.curses:HasCurse(spellNameNoRank, targetGuid, refresh) then
            local curseData
            if Cursive.curses.guids[targetGuid] and Cursive.curses.guids[targetGuid][spellNameNoRank] then
                curseData = Cursive.curses.guids[targetGuid][spellNameNoRank];
            else
                curseData = nil;
            end
            if curseData then
                -- 移除未使用的 remaining 变量 by 武藤纯子酱 2026.9.10
                return true;
            else
                return false;
            end
        else
            return false;
        end
    end
    return false; -- Cursive 未开启或无目标时返回 false
end

-- 查找 Buff/Debuff（核心函数）
function FindBuff( obuff, unit, isMine, refreshtime, item)
    local buff=strlower(obuff);
    local tooltip=SM_Tooltip;
    local textleft1=getglobal(tooltip:GetName().."TextLeft1");
    local refresh = refreshtime
    if ( not unit ) then
        unit ='player';
    elseif ( unit == "mouseover" ) then
        local frame = GetMouseFocus()
        if ( frame.label and frame.id ) then
            unit = frame.label .. frame.id
        end
    end
    local my, me, mc, oy, oe, oc = GetWeaponEnchantInfo();
    if ( my ) then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        -- SetInventoryItem 只接受 "player"；武器附魔是自己的，固定用 player by 武藤纯子酱 2026.9.10
        tooltip:SetInventoryItem( "player", 16);
        for i=1, 64 do
            local text = getglobal("SM_TooltipTextLeft"..i):GetText();
            if ( not text ) then
                break;
            elseif ( strfind(strlower(text), buff) ) then
                tooltip:Hide();
                return "main",me, mc;
            end
        end
        tooltip:Hide();
    elseif ( oy ) then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        tooltip:SetInventoryItem( "player", 17);
        for i=1, 64 do
            local text = getglobal("SM_TooltipTextLeft"..i):GetText();
            if ( not text ) then
                break;
            elseif ( strfind(strlower(text), buff) ) then
                tooltip:Hide();
                return "off", oe, oc;
            end
        end
        tooltip:Hide();
    end
    if ( item ) then return end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    tooltip:SetTrackingSpell();
    local b = textleft1:GetText();
    if ( b and strfind(strlower(b), buff) ) then
        tooltip:Hide();
        return "track",b;
    end
    local c=nil;
    for i=1, 64 do
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        tooltip:SetUnitBuff(unit, i);
        local b = textleft1:GetText();
        tooltip:Hide();
        if ( b and strfind(strlower(b), buff) ) then
            if not isMine then
                return "buff", i, b;
            elseif Cursive and CheckMyDot(unit,obuff,refreshtime) then
                return "buff", i, b;
            elseif Chronometer and IsMyBuff(unit,obuff) then
                return "buff", i, b;
            end
        elseif ( c==b ) then
            -- 连续两格读空说明 buff 列表已到头，提前退出 by 武藤纯子酱 2026.9.10
            break;
        end
        c = b; -- 恢复哨兵赋值（原被注释导致空槽扫满 64 次） by 武藤纯子酱 2026.9.10
    end
    c=nil;
    for i=1, 64 do
        tooltip:SetOwner(UIParent, "ANCHOR_NONE");
        tooltip:SetUnitDebuff(unit, i);
        local b = textleft1:GetText();
        tooltip:Hide();
        if ( b and strfind(strlower(b), buff) ) then
            if not isMine then
                return "debuff", i, b;
            elseif Cursive and CheckMyDot(unit,obuff,refreshtime) then
                return "debuff", i, b;
            elseif Chronometer and IsMyBuff(unit,obuff) then
                return "debuff", i, b;
            end
        elseif ( c==b) then
            break;
        end
        c = b;
    end
    tooltip:Hide();
end

-- 检查法术是否就绪（冷却为0且可用）
function SpellReady(spell)
    local _, _, offset, numSpells = GetSpellTabInfo(GetNumSpellTabs())
    local i = 1
    local totalSpells = offset + numSpells
    while i <= totalSpells do
        local spellName = GetSpellName(i, "spell")
        if spellName == spell then
            return GetSpellCooldown(i, "spell") == 0
        end
        i = i + 1
    end
    return false
end

-- 取消指定 Buff
function CancelBuff(...)
    for j=1, getn(arg) do
        local buff = strlower(arg[j]);
        for i=0, 32 do
            SM_Tooltip:SetOwner(UIParent, "ANCHOR_NONE");
            SM_Tooltip:SetPlayerBuff(i);
            local name = SM_TooltipTextLeft1:GetText();
            if ( not name ) then
                SM_Tooltip:Hide();
                break;
            end;
            if ( strfind(strlower(name), buff) ) then
                SM_Tooltip:Hide(); -- 先收起提示框再取消，避免 tooltip 残留 by 武藤纯子酱 2026.9.10
                CancelPlayerBuff(i);
            else
                SM_Tooltip:Hide();
            end
        end
    end
end

-- 拾取物品或装备到光标
function SM_Pickup(bag, slot)
    if ( type(bag)=="string") then
        -- 修正：GetInventorySlotInfo 要求混合大小写槽名（如 "HeadSlot"），strupper 全大写会查不到 by 武藤纯子酱 2026.9.10
        if ( SM_INV_SLOT[bag] or SM_INV_SLOT[strupper(bag)] ) then
            bag=GetInventorySlotInfo(bag);
        else
            bag,slot=FindItem(bag);
        end
    end
    if ( bag and not slot ) then
        PickupInventoryItem(bag);
    elseif ( bag and slot ) then
        PickupContainerItem(bag, slot);
    end
end

-- 立即打断施法（用于队列）
function caststop(...)
    for i=1, arg.n do
        -- 修正：先停止当前施法再施放，否则刚放的法术会被自己打断 by 武藤纯子酱 2026.9.10
        SpellStopCasting();
        CastSpellByName(arg[i]);
    end
end

-- 安全释放通道法术
function SM_Channel(spell)
    local cf = CastingBarFrame;
    local sp, book = SM_FindSpell(spell);
    if ( not sp ) then return; end
    -- 修正：GetSpellCooldown 返回 (start, duration, enabled)，原代码拿 start 当冷却时长比 by 武藤纯子酱 2026.9.10
    local _, duration = GetSpellCooldown(sp, book);
    if ( not cf.channeling and duration<=1.5 ) then
        cast(spell);
    end
end
Channel = SM_Channel;

-- 在专业技能窗口中查找技能索引
function FindTradeSkillIndex(tradeskill)
    tradeskill=strlower(tradeskill);
    if ( TradeSkillFrame and TradeSkillFrame:IsVisible()) then
        for i=1,GetNumTradeSkills() do
            local tsn,tst,tsx=GetTradeSkillInfo(i);
            if (strlower(tsn)==tradeskill) then
                SelectTradeSkill(i);
                TradeSkillInputBox:SetNumber(tsx);
                TradeSkillFrame.numAvailable=tsx;
                return i, tsx;
            end
        end
    end
    if ( CraftFrame and CraftFrame:IsVisible()) then
        for i=1,GetNumCrafts() do
            local tsn,_,_,tsx=GetCraftInfo(i);
            if (strlower(tsn)==tradeskill) then
                SelectCraft(i);
                return i, 'c';
            end
        end
    end
end

-- 制造指定物品（自动打开专业技能窗口）
function CraftItem( tradeskill, tradeitem, count)
    if ( TradeSkillFrame and TradeSkillFrame:IsVisible() ) then
        HideUIPanel(TradeSkillFrame);
    end
    if ( CraftFrame and CraftFrame:IsVisible() ) then
        HideUIPanel(CraftFrame);
    end
    cast(tradeskill);
    local index, avail = FindTradeSkillIndex(tradeitem);
    if ( avail=='c' ) then
        DoCraft(index);
    elseif (avail and avail > 0) then
        local amount;
        count = count or 1;
        if ( count <= 0 ) then
            -- 0 表示制造全部，-1 表示留一个材料
            amount =avail+count;
        else
            -- 用户指定数量
            amount=count;
        end
        amount = amount<1 and 1 or amount>avail and avail or amount;
        TradeSkillInputBox:SetNumber(amount);
        DoTradeSkill(index, amount);
    end
end

-- ==================== 事件宏注册 ====================
-- 注册一个宏在指定事件触发时执行
function RegisterEventMacro( macro, super, ...)
    -- ... 为所有要注册的事件
    -- super 为 1 表示运行超级宏，否则运行常规宏
    local macroname = macro;
    if ( super == 1 ) then
        macroname = "SUPER" .. macroname;
    end
    for i=1, arg.n do
        local event = arg[i];
        SuperMacro_EventsFrame:RegisterEvent(event);
        if ( not SuperMacro_EventsFrame.events[event] ) then
            SuperMacro_EventsFrame.events[event]={};
        end
        SuperMacro_EventsFrame.events[event][macroname] = 1;
    end
end

-- 取消注册事件宏
function UnregisterEventMacro( macro, super, ...)
    local macroname = macro;
    if ( super == 1 ) then
        macroname = "SUPER" .. macroname;
    end
    for i=1, arg.n do
        local event = arg[i];
        if ( SuperMacro_EventsFrame.events[event] ) then
            SuperMacro_EventsFrame.events[event][macroname] = nil;
            if ( not TableHasEntries( SuperMacro_EventsFrame.events[event] ) ) then
                -- 该事件没有其他宏注册，取消监听
                SuperMacro_EventsFrame:UnregisterEvent(event);
                SuperMacro_EventsFrame.events[event]=nil;
            end
        end
        -- 事件未注册时直接跳过本项，继续处理后续事件 by 武藤纯子酱 2026.9.10
    end
end

-- 事件触发时的处理函数
function SuperMacro_EventsFrame_OnEvent()
    local ev = event;
    if ( this.events[ev] ) then
        for macro in pairs(this.events[ev]) do
            if ( strfind(macro, "^SUPER") ) then
                RunSuperMacro( strsub( macro, 6) );
            else
                SuperMacro_RunMacro( macro );
            end
        end
    end
end

-- 打印所有已注册的事件宏
function ViewEventMacros()
    Printt(SuperMacro_EventsFrame.events, "EventMacros");
end

-- ==================== 快捷别名 ====================
-- 提供常用函数的短名称，方便在宏中调用
cast = CastSpellByName;
stopcast = SpellStopCasting;
echo = SM_print;
send = SendChatMessage;
buffed = FindBuff;
unbuff = CancelBuff;
pickup = SM_Pickup;

-- ==================== 调试打印函数 ====================
-- 打印调试信息（白色）
function Printd(...)
    for i=1, arg.n do
        local t=arg[i] and (arg[i]~="" and arg[i] or '-""-' )or "-nil-";
        if ( type(t)=="boolean") then
            t="-"..tostring(t).."-";
        end
        DEFAULT_CHAT_FRAME:AddMessage(t,1,1,1);
    end
end

-- 带颜色打印调试信息
function PrintColor(r,g,b,...)
    for i=1, arg.n do
        local t=arg[i] and (arg[i]~="" and arg[i] or '-""-' )or "-nil-";
        if ( type(t)=="boolean") then
            t="-"..tostring(t).."-";
        end
        DEFAULT_CHAT_FRAME:AddMessage(t,r,g,b);
    end
end
Printc=PrintColor;

-- 以树形结构格式化打印表
function PrintTable(table, rowname, level)
    if ( rowname == nil ) then rowname = "ROOT"; end
    if ( not level ) then level = 1; end
    local msg = "";
    for i=1, level do
        msg = msg .. "   ";
    end
    if ( table == nil ) then Print (msg.."["..rowname.."] := nil "); return end
    if ( type(table) == "table" ) then
        Print(msg..rowname.." { ");
        for k,v in table do
            PrintTable(v,k,level+1);
        end
        Print(msg.."} ");
    elseif (type(table) == "function" ) then
        Print(msg.."["..rowname.."] => {{FunctionPtr*}}");
    else
        Print(msg.."["..rowname.."] => "..table);
    end
end
Printt=PrintTable;