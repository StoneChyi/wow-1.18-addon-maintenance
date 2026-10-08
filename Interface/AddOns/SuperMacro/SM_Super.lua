--[[
    SM_Super.lua - 超级宏动作按钮插入和替换
    挂钩 PickupMacro, PickupAction, PlaceAction, UseAction,
    GetActionText, GetActionTexture 等函数，
    使得可以将超级宏像普通宏一样拖放到动作条上，
    并正确显示名称、图标和冷却。
--]]

-- 从完整纹理路径中提取文件名
function GetStringAfterLastSlash(input)
    if type(input) ~= "string" then
        return nil;
    end
    for i = string.len(input), 1, -1 do
        if string.sub(input, i, i) == "\\" then
            return string.sub(input, i + 1);
        end
    end
    return input;
end

-- 保存原始函数引用
local oldPickupMacro=PickupMacro;
local oldPickupContainerItem=PickupContainerItem;
local oldPickupInventoryItem=PickupInventoryItem;
local oldPickupSpell=PickupSpell;
local oldPickupAction=PickupAction;
local oldPlaceAction=PlaceAction;
local oldUseAction=UseAction;
local oldGetActionText=GetActionText;
local oldGetActionTexture=GetActionTexture;

-- 拾取宏（拖动到动作条时调用）
function PickupMacro(macroid, supername)
    if ( supername ) then
        -- 如果是超级宏，用超级宏的名称和图标临时替换一个普通宏用于拖动显示
        -- 需要至少存在 1 个常规宏作为临时载体，否则 EditMacro(1,...) 会报错 by 武藤纯子酱 2026.9.10
        local numAccountMacros, numCharacterMacros = GetNumMacros();
        if ( (numAccountMacros or 0) + (numCharacterMacros or 0) == 0 ) then
            SM_CURSOR = supername
            oldPickupMacro(nil)
            return
        end
        SM_CURSOR = supername
        local tempicon = GetStringAfterLastSlash(GetSuperMacroInfo(supername, "texture"))
        local macroname, macroicon = GetMacroInfo(1)
        macroicon = GetStringAfterLastSlash(macroicon)
        if type(tonumber(macroicon)) == "number" then
            macroicon = "INV_MISC_QUESTIONMARK"
        end
        EditMacro(1, macroname, tempicon)
        oldPickupMacro(1)
        EditMacro(1, macroname, macroicon)
    else
        SM_CURSOR = nil
        local macroname, macroicon = GetMacroInfo(macroid)
        macroicon = tonumber(GetStringAfterLastSlash(macroicon))
        if type(macroicon) == "number" then
            EditMacro(macroid, macroname, GetStringAfterLastSlash(GetMacroIconInfo(macroicon)))
        end
        oldPickupMacro(macroid)
    end
end

-- 重置光标状态
function PickupContainerItem(index, slot)
    SM_CURSOR=nil;
    oldPickupContainerItem(index, slot);
end

function PickupInventoryItem(index)
    SM_CURSOR=nil;
    oldPickupInventoryItem(index);
end

function PickupSpell(index, book)
    SM_CURSOR=nil;
    oldPickupSpell(index, book);
end

-- 拾取动作（包括超级宏动作）
function PickupAction(id)
    if ( SM_ACTION[id] ) then
        -- 需要至少 1 个常规宏作为临时载体（同 PickupMacro） by 武藤纯子酱 2026.9.10
        local numAccountMacros, numCharacterMacros = GetNumMacros();
        if ( (numAccountMacros or 0) + (numCharacterMacros or 0) > 0 ) then
            SM_CURSOR = SM_ACTION[id]
            local tempicon = GetStringAfterLastSlash(GetSuperMacroInfo(SM_CURSOR, "texture"))
            local macroname, macroicon = GetMacroInfo(1)
            macroicon = GetStringAfterLastSlash(macroicon)
            if type(tonumber(macroicon)) == "number" then
                macroicon = "INV_MISC_QUESTIONMARK"
            end
            EditMacro(1, macroname, tempicon)
            SM_ACTION[id] = nil
            oldPickupAction(id)
            EditMacro(1, macroname, macroicon)
            return
        end
        SM_ACTION[id] = nil
        oldPickupAction(id)
    else
        SM_CURSOR = nil
        SM_ACTION[id] = nil
        oldPickupAction(id)
    end
end

-- 放置动作（包括超级宏）
function PlaceAction(id)
    -- 放置和拾取超级宏
    local cursor;
    if ( SM_ACTION[id] ) then
        cursor=SM_ACTION[id];
    end
    SM_ACTION[id]=SM_CURSOR;
    SM_CURSOR=cursor;
    oldPlaceAction(id);
end

-- 使用动作（点击动作条时调用）
function UseAction( id, click, selfcast)
    lastActionUsed = id;
    -- 如果超级宏窗口打开，先保存宏内容
    if ( SuperMacroFrame_SaveMacro and SuperMacroFrame:IsVisible() ) then
        SuperMacroFrame_SaveMacro();
    end
    -- 如果是超级宏动作，运行超级宏，否则执行原始动作
    if ( SM_ACTION[id] ) then
        RunSuperMacro(SM_ACTION[id]);
    else
        oldUseAction( id, click, selfcast );
    end
end

-- 获取动作文本（动作条上显示的名称）
function GetActionText(id)
    if ( SM_ACTION[id] ) then
        return SM_ACTION[id];
    else
        return oldGetActionText(id);
    end
end

-- 获取动作图标
function GetActionTexture(id)
    if ( SM_ACTION[id] ) then
        local texture=GetSuperMacroInfo(SM_ACTION[id], "texture");
        return texture;
    else
        return oldGetActionTexture(id);
    end
end

-- 当超级宏被重命名时，更新所有关联的动作槽位
function SuperMacro_UpdateAction(oldsuper, newsuper)
    for k,v in SM_ACTION do
        if v==oldsuper then
            SM_ACTION[k]=newsuper;
        end
    end
end

-- 将超级宏直接设置到指定动作槽位
function SetActionSuperMacro(actionid, supername)
    if ( supername and actionid > 0 and actionid <= 120 ) then
        PickupAction( actionid );
        PickupMacro(1, supername );
        PlaceAction ( actionid );
    end
end

-- 动作按钮点击处理（处理超级宏放置）
function SM_ActionButton_OnClick()
    if ( SM_CURSOR ) then
        PlaceAction(ActionButton_GetPagedID(this));
        ActionButton_UpdateState();
        return 1;
    end
end