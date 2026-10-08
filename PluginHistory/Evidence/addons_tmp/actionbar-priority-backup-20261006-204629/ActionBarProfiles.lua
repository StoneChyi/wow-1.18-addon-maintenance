-- ActionBarProfiles.lua (WoW 1.12)
-- 经过Sunelgy优化的轻量版本：按需扫描 / 降低Tooltip与拾取操作 / 避免不必要表分配
-- 作者：Sunelgy在原作者基础上优化，武藤纯子酱修复宏逻辑

local ABP_PlayerName = nil
-- WoW 1.12 普通动作栏只有120个槽位；姿态和宠物栏使用各自的接口。
local MAX_ACTIONS = 120
local LEGACY_MAX_ACTIONS = 144
-- 在 SuperMacro 等插件包装前保留接口，兼容 SuperWoW 追加的动作类型/物品ID。
local ABP_NativeGetActionText = GetActionText

local CMD_SAVE   = "保存"
local CMD_LOAD   = "加载"
local CMD_REMOVE = "删除"
local CMD_LIST   = "列表"

local function hasElements(T)
    if type(T) ~= "table" then return 0 end
    for _ in pairs(T) do
        return 1
    end
    return 0
end

local function ABP_GetTooltipLine1()
    local left, right = nil, nil
    if ABP_TooltipTextLeft1 and ABP_TooltipTextLeft1:IsShown() then
        left = ABP_TooltipTextLeft1:GetText()
    end
    if ABP_TooltipTextRight1 and ABP_TooltipTextRight1:IsShown() then
        right = ABP_TooltipTextRight1:GetText()
    end
    return left, right
end

local function ABP_ComposeSpellKey(name, rankText)
    if not name or name == "" then return nil end
    if rankText and rankText ~= "" then
        return name .. " " .. rankText
    end
    return name
end

local function ABP_Msg(msg)
    if DEFAULT_CHAT_FRAME and msg then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end

local function ABP_TooltipAttach()
    if ABP_Tooltip and ABP_Tooltip.SetOwner then
        ABP_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
end

-- 自动联动和手动保存/加载共用保护，避免抢走玩家或换装插件的光标。
function ABP_CanChangeActions()
    if (InCombatLockdown and InCombatLockdown())
       or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        return false, "combat"
    end
    if SM_CURSOR or (GetCursorInfo and GetCursorInfo())
       or (CursorHasItem and CursorHasItem())
       or (CursorHasSpell and CursorHasSpell())
       or (CursorHasMacro and CursorHasMacro())
       or (SpellIsTargeting and SpellIsTargeting()) then
        return false, "cursor"
    end
    return true
end

local function ABP_ResetCursor()
    ClearCursor()
    -- SuperMacro 的虚拟光标不随原生 ClearCursor 清除。
    if SM_ACTION then SM_CURSOR = nil end
end

local function ABP_HasAction(slot)
    if type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot) then
        return false
    end
    if HasAction(slot) or (GetActionTexture and GetActionTexture(slot))
       or (SM_ACTION and SM_ACTION[slot]) then return true end
    local _, actionType, actionId = ABP_NativeGetActionText(slot)
    return actionType == "ITEM" and actionId ~= nil
end

local function ABP_IsLegacySlot(slot)
    return type(slot) == "number" and slot > MAX_ACTIONS
        and slot <= LEGACY_MAX_ACTIONS and slot == math.floor(slot)
end

local function ABP_ItemIdFromLink(link)
    if type(link) ~= "string" then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return id and tonumber(id) or nil
end

local function ABP_ReadItemInfo(slot, name)
    local _, actionType, actionId = ABP_NativeGetActionText(slot)
    local id = actionType == "ITEM" and tonumber(actionId) or nil
    if not id and GetItemInfo then
        local _, link = GetItemInfo(name)
        id = ABP_ItemIdFromLink(link)
    end
    return {id = id, texture = GetActionTexture and GetActionTexture(slot) or nil}
end

local ITEM_MACRO_MARKER = "/script -- ABP_ITEM_PLACEHOLDER\n/use "

-- 识别本插件创建的占位宏，重新保存时仍记为物品，不混进普通宏列表。
local function ABP_GetPlaceholder(macroName)
    if not macroName or not GetMacroIndexByName or not GetMacroInfo then return nil end
    local index = GetMacroIndexByName(macroName)
    if not index or index <= 0 then return nil end
    local _, texture, body = GetMacroInfo(index)
    if type(body) ~= "string" then return nil end
    local id = nil
    local _, prefixEnd, itemId = string.find(body, "^/tooltip item:(%d+)\n")
    if prefixEnd then id = tonumber(itemId); body = string.sub(body, prefixEnd + 1) end
    if string.sub(body, 1, string.len(ITEM_MACRO_MARKER)) ~= ITEM_MACRO_MARKER then return nil end
    local name = string.sub(body, string.len(ITEM_MACRO_MARKER) + 1)
    if name == "" or string.find(name, "[\r\n]") then return nil end
    return name, {id = id, texture = texture}
end

local function ABP_MatchesItem(slot, name, info, allowPlaceholder)
    if not ABP_HasAction(slot) then return false end
    local macro = GetActionText(slot)
    if macro and macro ~= "" then
        if not allowPlaceholder then return false end
        local itemName = ABP_GetPlaceholder(macro)
        return itemName == name
    end
    local _, actionType, actionId = ABP_NativeGetActionText(slot)
    if actionType == "SPELL" or actionType == "MACRO" then return false end
    if actionType == "ITEM" and info and info.id then return tonumber(actionId) == info.id end
    ABP_Tooltip:ClearLines()
    ABP_Tooltip:SetAction(slot)
    local itemName, rank = ABP_GetTooltipLine1()
    return itemName == name and (actionType == "ITEM" or not rank or rank == "")
end

-- Compare before touching the cursor. Native spell IDs are book indices,
-- which move after talent changes; compare name/rank instead. Macro hooks
-- remain authoritative for SuperMacro virtual actions.
local function ABP_MatchesSpell(slot, spell)
    if not ABP_HasAction(slot) or GetActionText(slot) then return false end
    local _, kind = ABP_NativeGetActionText(slot)
    if kind and kind ~= "SPELL" then return false end
    if not kind and IsConsumableAction and IsConsumableAction(slot) then return false end
    if not kind and IsEquippedAction and IsEquippedAction(slot) then return false end
    ABP_Tooltip:ClearLines()
    ABP_Tooltip:SetAction(slot)
    local name, rank = ABP_GetTooltipLine1()
    -- With the classic API, rank-less actions cannot safely be distinguished
    -- from an item of the same name. Restore those conservatively.
    if not kind and (not rank or rank == "") then return false end
    return ABP_ComposeSpellKey(name, rank) == ABP_ComposeSpellKey(spell.name, spell.rank)
end

local function ABP_GetItemMacro(name, info)
    if not CreateMacro or not GetMacroInfo or not GetMacroIndexByName then return nil end
    -- 物品名来自游戏；拒绝换行，避免构造出额外宏命令。
    if string.find(name, "[\r\n]") then return nil end
    local body = ITEM_MACRO_MARKER .. name
    if info and info.id then body = "/tooltip item:" .. info.id .. "\n" .. body end
    local hash = 0
    for i = 1, string.len(name) do hash = math.mod(hash * 31 + string.byte(name, i), 2147483647) end
    local base = "ABPi" .. tostring(info and info.id or hash)
    local macroName = nil
    for suffix = 0, 99 do
        local candidate = base .. (suffix > 0 and ("_" .. suffix) or "")
        local index = GetMacroIndexByName(candidate)
        if index and index > 0 then
            local _, _, existingBody = GetMacroInfo(index)
            if existingBody == body then return index end
        else macroName = candidate; break end
    end
    if not macroName then return nil end
    local iconIndex = 1
    if info and info.texture and GetNumMacroIcons and GetMacroIconInfo then
        for i = 1, GetNumMacroIcons() do
            if GetMacroIconInfo(i) == info.texture then iconIndex = i; break end
        end
    end
    -- 优先使用角色宏，不改写玩家已有宏；角色宏满时尝试账号宏。
    for attempt = 1, 2 do
        -- 1.12 第4参是 isLocal，第5参才是角色专用开关。
        local ok, index = pcall(CreateMacro, macroName, iconIndex, body, nil, attempt == 1)
        if ok and index and index > 0 then return index end
    end
    return nil
end

local function ABP_ClearAction(slot)
    if ABP_HasAction(slot) then
        PickupAction(slot)
        ABP_ResetCursor()
        if ABP_HasAction(slot) then
            error("无法清除第" .. slot .. "格")
        end
    end
end

function ABP_SaveProfile(profileName)
    if not profileName or profileName == "" then return end
    if not ABP_PlayerName then return end
    local canChange = ABP_CanChangeActions()
    if not canChange then
        ABP_Msg("当前处于战斗或正在拖动/施放，请结束后再保存动作条。")
        return false
    end
    if not ABP_Layout then ABP_Layout = {} end
    if not ABP_Layout[ABP_PlayerName] then ABP_Layout[ABP_PlayerName] = {} end

    local profile = {
        spells = {},  -- [slot] = { name=, rank= }
        macros = {},  -- [slot] = macroName
        items  = {},  -- [slot] = itemName
        itemInfo = {}, -- [slot] = {id=, texture=}，用于零数量物品占位
    }

    ABP_TooltipAttach()

    local scStatus = GetCVar("autoSelfCast")
    SetCVar("autoSelfCast", 0)

    local ok, err = pcall(function()
        for i = 1, MAX_ACTIONS do
            if ABP_HasAction(i) then
                local macroName = GetActionText(i)
                local placeholderName, placeholderInfo = ABP_GetPlaceholder(macroName)
                if placeholderName then
                    profile.items[i], profile.itemInfo[i] = placeholderName, placeholderInfo
                elseif macroName and macroName ~= "" then
                    profile.macros[i] = macroName
                else
                    ABP_Tooltip:ClearLines()
                    ABP_Tooltip:SetAction(i)

                    local isSpell = false
                    do
                        PickupAction(i)
                        isSpell = CursorHasSpell()
                        PlaceAction(i)
                    end

                    if isSpell then
                        local spellName, rankText = ABP_GetTooltipLine1()
                        if not spellName or spellName == "" then error("无法读取第" .. i .. "格技能") end
                        profile.spells[i] = {
                            name = spellName,
                            rank = rankText,
                        }
                    else
                        local itemName = ABP_GetTooltipLine1()
                        if itemName and itemName ~= "" then
                            profile.items[i] = itemName
                            profile.itemInfo[i] = ABP_ReadItemInfo(i, itemName)
                        end
                    end
                end
            end
        end
    end)

    ABP_ResetCursor()
    SetCVar("autoSelfCast", scStatus)
    if not ok then
        ABP_Msg("动作条保存失败，原配置已保留：" .. tostring(err))
        return false
    end
    ABP_Layout[ABP_PlayerName][profileName] = profile
    ABP_Msg('配置文件 "' .. profileName .. '" 已保存.')
    return true
end

local function ABP_BuildNeededSpellMap(neededSpellKeys)
    local result = {}
    if not neededSpellKeys or not next(neededSpellKeys) then return result end

    local remaining = {}
    local remainingCount = 0
    for key in pairs(neededSpellKeys) do
        remaining[key] = true
        remainingCount = remainingCount + 1
    end

    for tab = 1, MAX_SKILLLINE_TABS do
        local name, _, offset, numSpells = GetSpellTabInfo(tab)
        if not name then break end
        for s = offset + 1, offset + numSpells do
            local n, r = GetSpellName(s, BOOKTYPE_SPELL)
            local key = ABP_ComposeSpellKey(n, (r ~= "" and r or nil))
            if key and remaining[key] then
                result[key] = s
                remaining[key] = nil
                remainingCount = remainingCount - 1
                if remainingCount == 0 then
                    return result
                end
            end
        end
    end
    return result
end

local function ABP_FindItemsInEquipment(neededItems)
    local equipMap = {}
    if not neededItems or not next(neededItems) then return equipMap end

    ABP_TooltipAttach()
    local remaining = {}
    local leftCount = 0
    for name in pairs(neededItems) do remaining[name] = true; leftCount = leftCount + 1 end

    for slot = 1, 19 do
        ABP_Tooltip:ClearLines()
        local hasItem = ABP_Tooltip:SetInventoryItem("player", slot)
        if hasItem then
            local itemName = ABP_GetTooltipLine1()
            if itemName and remaining[itemName] then
                equipMap[itemName] = slot
                remaining[itemName] = nil
                leftCount = leftCount - 1
                if leftCount == 0 then
                    break
                end
            end
        end
    end
    return equipMap
end

local function ABP_FindItemsInBags(neededItems)
    local bagMap = {}
    if not neededItems or not next(neededItems) then return bagMap end

    ABP_TooltipAttach()
    local remaining = {}
    local leftCount = 0
    for name in pairs(neededItems) do remaining[name] = true; leftCount = leftCount + 1 end

    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local texture = GetContainerItemInfo(bag, slot)
                if texture then
                    ABP_Tooltip:ClearLines()
                    ABP_Tooltip:SetBagItem(bag, slot)
                    local itemName = ABP_GetTooltipLine1()
                    if itemName and remaining[itemName] then
                        bagMap[itemName] = { bag = bag, slot = slot }
                        remaining[itemName] = nil
                        leftCount = leftCount - 1
                        if leftCount == 0 then
                            return bagMap
                        end
                    end
                end
            end
        end
    end
    return bagMap
end

function ABP_LoadProfile(profileName, options)
    if not ABP_PlayerName or not ABP_Layout or not ABP_Layout[ABP_PlayerName]
       or not ABP_Layout[ABP_PlayerName][profileName] then
        ABP_Msg('配置文件 "' .. tostring(profileName) .. '" 以前没有保存，无法加载.')
        return false, "no_profile"
    end

    local canChange, reason = ABP_CanChangeActions()
    if not canChange then
        if not options or not options.quiet then
            ABP_Msg("当前处于战斗或正在拖动/施放，请结束后再加载动作条。")
        end
        return false, reason
    end

    local profile = ABP_Layout[ABP_PlayerName][profileName]
    if type(profile) ~= "table" then
        ABP_Msg("动作条配置格式有误，未更改当前动作条。")
        return false, "invalid_profile"
    end
    local spells = profile.spells or {}
    local macros = profile.macros or {}
    local items  = profile.items  or {}
    local itemInfo = profile.itemInfo or {}

    -- 检查全部记录后才操作动作栏；旧配置中未记录的格子即为空格。
    local valid = (profile.spells == nil or type(profile.spells) == "table")
        and (profile.macros == nil or type(profile.macros) == "table")
        and (profile.items == nil or type(profile.items) == "table")
        and (profile.itemInfo == nil or type(profile.itemInfo) == "table")
    local ignoredSlots = {}
    if valid then
        for slot, info in pairs(spells) do
            if ABP_IsLegacySlot(slot) then
                ignoredSlots[slot] = true
            elseif type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot)
               or type(info) ~= "table" or type(info.name) ~= "string" or info.name == ""
               or (info.rank ~= nil and type(info.rank) ~= "string") then valid = false; break end
        end
        for _, entries in ipairs({macros, items}) do
            for slot, name in pairs(entries) do
                if ABP_IsLegacySlot(slot) then
                    ignoredSlots[slot] = true
                elseif type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot)
                   or type(name) ~= "string" or name == "" then valid = false; break end
            end
        end
        for slot, info in pairs(itemInfo) do
            if ABP_IsLegacySlot(slot) then
                ignoredSlots[slot] = true
            elseif type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot)
               or type(info) ~= "table" or not items[slot]
               or (info.id ~= nil and (type(info.id) ~= "number" or info.id <= 0 or info.id ~= math.floor(info.id)))
               or (info.texture ~= nil and type(info.texture) ~= "string") then valid = false; break end
        end
    end
    if not valid then
        ABP_Msg("动作条配置格式有误，未更改当前动作条。")
        return false, "invalid_profile"
    end

    local neededSpellKeys = {}
    local neededItemNames = {}

    for slot, info in pairs(spells) do
        if not ABP_IsLegacySlot(slot) then
            local key = ABP_ComposeSpellKey(info.name, info.rank)
            if key then neededSpellKeys[key] = true end
        end
    end
    for slot, itemName in pairs(items) do
        if not ABP_IsLegacySlot(slot) and itemName and itemName ~= "" then neededItemNames[itemName] = true end
    end

    local spellKeyToId   = ABP_BuildNeededSpellMap(neededSpellKeys)
    -- 天赋切换时技能书可能尚未更新：此时保持整个动作栏不动，交给调用者稍后重试。
    if options and options.deferMissingSpells then
        for key in pairs(neededSpellKeys) do
            if not spellKeyToId[key] then return false, "spells_pending" end
        end
    end

    local equipItemToId  = ABP_FindItemsInEquipment(neededItemNames)

    local remaining = {}
    for name in pairs(neededItemNames) do
        if not equipItemToId[name] then remaining[name] = true end
    end
    local bagItemToLoc = ABP_FindItemsInBags(remaining)

    ABP_TooltipAttach()
    local scStatus = GetCVar("autoSelfCast")
    SetCVar("autoSelfCast", 0)
    local report = { missing = {}, restored = 0, cleared = 0, placeholders = 0, preservedItems = 0, unchanged = 0, ignoredSlots = ignoredSlots }
    local changedSlots = {}

    local ok, err = pcall(function()
        for i = 1, MAX_ACTIONS do
            -- 逐格恢复完整快照，包含空格；先清旧按钮，再放目标按钮。
            local iname = items[i]
            local info = itemInfo[i]
            local availableItem = iname and (equipItemToId[iname] or bagItemToLoc[iname])
            -- 零数量不代表空格：先保留匹配的原生按钮/占位宏，不能先清再从背包找。
            local keepItem = not spells[i] and not macros[i] and iname
                and ABP_MatchesItem(i, iname, info, not availableItem)
            local keepAction = keepItem
                or (spells[i] and spellKeyToId[ABP_ComposeSpellKey(spells[i].name, spells[i].rank)]
                    and ABP_MatchesSpell(i, spells[i]))
                or (not spells[i] and macros[i] and GetActionText(i) == macros[i]
                    and ((GetSuperMacroInfo and GetSuperMacroInfo(macros[i], "texture"))
                        or GetMacroIndexByName(macros[i]) > 0))
            if not keepAction then
                if ABP_HasAction(i) then
                    report.cleared = report.cleared + 1
                    changedSlots[i] = true
                end
                if spells[i] or macros[i] or iname then changedSlots[i] = true end
                ABP_ClearAction(i)
            end
            local restored = keepAction and true or false
            if keepAction then report.unchanged = report.unchanged + 1 end
            if keepItem then report.preservedItems = report.preservedItems + 1 end
            local missingName = nil
            repeat
                if keepAction then break end
                local sp = spells[i]
                if sp then
                    local key = ABP_ComposeSpellKey(sp.name, sp.rank)
                    local sid = key and spellKeyToId[key] or nil
                    if sid then
                        PickupSpell(sid, BOOKTYPE_SPELL)
                        if CursorHasSpell() then PlaceAction(i); restored = HasAction(i) end
                    end
                    missingName = "技能 " .. tostring(key)
                    break
                end

                local mname = macros[i]
                if mname and mname ~= "" then
                    if GetSuperMacroInfo and GetSuperMacroInfo(mname, "texture") then
                        PickupMacro(0, mname)
                        PlaceAction(i)
                    else
                        local idx = GetMacroIndexByName(mname)
                        if idx and idx > 0 then
                            PickupMacro(idx)
                            PlaceAction(i)
                        end
                    end
                    restored = GetActionText(i) == mname
                    missingName = "宏 " .. mname
                    break
                end

                if iname and iname ~= "" then
                    local eslot = equipItemToId[iname]
                    if eslot then
                        PickupInventoryItem(eslot)
                        if CursorHasItem() then PlaceAction(i); restored = HasAction(i) end
                        missingName = "物品 " .. iname
                        break
                    end
                    local loc = bagItemToLoc[iname]
                    if loc then
                        PickupContainerItem(loc.bag, loc.slot)
                        if CursorHasItem() then PlaceAction(i); restored = HasAction(i) end
                        missingName = "物品 " .. iname
                        break
                    end
                    if not info or not info.id then
                        if GetItemInfo then
                            local _, link = GetItemInfo(iname)
                            local id = ABP_ItemIdFromLink(link)
                            if id then info = {id = id, texture = info and info.texture} end
                        end
                    end
                    local index = ABP_GetItemMacro(iname, info)
                    if index then
                        PickupMacro(index)
                        PlaceAction(i)
                        local placed = GetActionText(i)
                        restored = ABP_GetPlaceholder(placed) == iname
                        if restored then report.placeholders = report.placeholders + 1 end
                    end
                    missingName = "物品 " .. iname
                    if not index then
                        missingName = missingName .. "（缺货且无法创建占位宏，请检查宏栏空间或宏接口）"
                    end
                    break
                end
            until true
            ABP_ResetCursor()
            if restored then
                report.restored = report.restored + 1
            elseif missingName then
                ABP_ClearAction(i)
                table.insert(report.missing, "第" .. i .. "格：" .. missingName)
            end
        end
    end)

    ABP_ResetCursor()
    SetCVar("autoSelfCast", scStatus)
    if not ok then
        ABP_Msg("动作条加载中断，请重新加载：" .. tostring(err))
        return false, "runtime_error"
    end
    if next(changedSlots) and Flyout_UpdateBars and Flyout_GetActionButton then
        for i in pairs(changedSlots) do
            local button = Flyout_GetActionButton(i)
            if button then
                button.flyoutActions, button.flyoutAction, button.flyoutActionType = nil, nil, nil
            end
        end
        Flyout_UpdateBars()
    end
    if table.getn(report.missing) > 0 then
        ABP_Msg('配置文件 "' .. profileName .. '" 已恢复；以下内容未找到，对应格子已清空：')
        for _, message in ipairs(report.missing) do ABP_Msg(message) end
    else
        ABP_Msg('配置文件 "' .. profileName .. '" 已完整加载（含空格）.')
    end
    if report.placeholders > 0 then
        ABP_Msg("已为" .. report.placeholders .. "个缺货物品恢复占位宏；补货后可直接使用，重新加载预设可恢复普通物品按钮。")
    end
    if next(ignoredSlots) then
        ABP_Msg("旧预设中的121–144号越界槽位已跳过，其余动作栏已按预设恢复。")
    end
    return true, report
end

function ABP_ListProfiles()
    if not ABP_PlayerName or not ABP_Layout or not ABP_Layout[ABP_PlayerName]
       or hasElements(ABP_Layout[ABP_PlayerName]) == 0 then
        ABP_Msg("你没有为这个人物保存的配置文件.")
        return
    end
    ABP_Msg("这个人物的配置文件有:")
    for profileName in pairs(ABP_Layout[ABP_PlayerName]) do
        ABP_Msg(profileName)
    end
end

function ABP_RemoveProfile(profileName)
    if not ABP_PlayerName or not ABP_Layout
       or not ABP_Layout[ABP_PlayerName]
       or not ABP_Layout[ABP_PlayerName][profileName] then
        ABP_Msg("你没有配置文件 '" .. tostring(profileName) .. "' 保存在这个人物上.")
        return
    end
    ABP_Layout[ABP_PlayerName][profileName] = nil
    ABP_Msg("配置文件 '" .. profileName .. "' 已经删除.")
end

function ABP_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED")
    SLASH_ABP1 = "/ABP"
    SlashCmdList["ABP"] = function(msg) ABP_SlashCommand(msg or "") end
end

function ABP_OnEvent()
    if event == "VARIABLES_LOADED" then
        ABP_PlayerName = UnitName("player") .. " of " .. GetCVar("realmName")

        if not ABP_Layout then ABP_Layout = {} end
        if not ABP_Layout[ABP_PlayerName] then ABP_Layout[ABP_PlayerName] = {} end

        if ABP_ButtonPosition == nil then ABP_ButtonPosition = 60 end

        UIDropDownMenu_Initialize(getglobal("ABP_DropDownMenu"), ABP_DropDownMenu_OnLoad, "MENU")
        ABPButton_UpdatePosition()
    end
end

function ABP_SlashCommand(msg)
    msg = msg or ""
    if msg == "" then
        ABP_Msg("ActionBarProfiles, 由Kronos的<Vanguard>制作, 60addons汉化")
        ABP_Msg("/abp 保存 [配置文件名字]")
        ABP_Msg("/abp 加载 [配置文件名字]")
        ABP_Msg("/abp 删除 [配置文件名字]")
        ABP_Msg("/abp 列表")
        return
    end

    for profileName in string.gfind(msg, CMD_SAVE .. " (.*)") do
        ABP_SaveProfile(profileName)
        return
    end
    for profileName in string.gfind(msg, CMD_LOAD .. " (.*)") do
        ABP_LoadProfile(profileName)
        return
    end
    for profileName in string.gfind(msg, CMD_REMOVE .. " (.*)") do
        ABP_RemoveProfile(profileName)
        return
    end
    if string.find(msg, CMD_LIST, 1, true) then
        ABP_ListProfiles()
        return
    end
end

function ABP_DropDownMenu_OnLoad()
    if UIDROPDOWNMENU_MENU_VALUE == "Delete menu" then
        UIDropDownMenu_AddButton({
            text = "选择要删除的布局",
            isTitle = true,
            owner = this:GetParent(),
            justifyH = "CENTER",
        }, UIDROPDOWNMENU_MENU_LEVEL)

        local list = ABP_Layout and ABP_Layout[ABP_PlayerName] or nil
        if list then
            for profileName in pairs(list) do
                UIDropDownMenu_AddButton({
                    text = profileName,
                    value = profileName,
                    func = function() ABP_RemoveProfile(this:GetText()) end,
                    notCheckable = 1,
                    owner = this:GetParent(),
                }, UIDROPDOWNMENU_MENU_LEVEL)
            end
        end
        return
    end

    -- 新增：保存子菜单
    if UIDROPDOWNMENU_MENU_VALUE == "Save menu" then
        UIDropDownMenu_AddButton({
            text = "选择要覆盖的布局",
            isTitle = true,
            owner = this:GetParent(),
            justifyH = "CENTER",
        }, UIDROPDOWNMENU_MENU_LEVEL)

        local list = ABP_Layout and ABP_Layout[ABP_PlayerName] or nil
        if list then
            for profileName in pairs(list) do
                UIDropDownMenu_AddButton({
                    text = profileName,
                    value = profileName,
                    func = function() ABP_SaveProfile(this:GetText()) end,
                    notCheckable = 1,
                    owner = this:GetParent(),
                }, UIDROPDOWNMENU_MENU_LEVEL)
            end
        end

        UIDropDownMenu_AddButton({
            text = "新建...",
            func = function() StaticPopup_Show("ABP_NewProfile") end,
            notCheckable = 1,
            owner = this:GetParent(),
        }, UIDROPDOWNMENU_MENU_LEVEL)
        return
    end

    -- 原默认菜单
    UIDropDownMenu_AddButton({
        text = UnitName("player") .. "的动作条",
        isTitle = true,
        owner = this:GetParent(),
        justifyH = "CENTER",
    }, UIDROPDOWNMENU_MENU_LEVEL)

    local list = ABP_Layout and ABP_Layout[ABP_PlayerName] or nil
    if list then
        for profileName in pairs(list) do
            UIDropDownMenu_AddButton({
                text = profileName,
                func = function() ABP_LoadProfile(this:GetText()) end,
                notCheckable = 1,
                owner = this:GetParent(),
            }, UIDROPDOWNMENU_MENU_LEVEL)
        end
    end

    UIDropDownMenu_AddButton({
        text = "选项",
        isTitle = true,
        justifyH = "CENTER",
    }, UIDROPDOWNMENU_MENU_LEVEL)

    -- 原“保存当前动作条的布局”改为带有子菜单的按钮
    UIDropDownMenu_AddButton({
        text = "保存当前动作条的布局",
        value = "Save menu",
        notCheckable = 1,
        hasArrow = true,
        owner = this:GetParent(),
    }, UIDROPDOWNMENU_MENU_LEVEL)

    UIDropDownMenu_AddButton({
        text = "删除一个布局",
        value = "Delete menu",
        notCheckable = 1,
        hasArrow = true,
    }, UIDROPDOWNMENU_MENU_LEVEL)
end

local ABP_ButtonRadius = 78

function ABPButton_UpdatePosition()
    ActionBarProfiles_IconFrame:SetPoint(
        "TOPLEFT", "Minimap", "TOPLEFT",
        54 - (ABP_ButtonRadius * cos(ABP_ButtonPosition)),
        (ABP_ButtonRadius * sin(ABP_ButtonPosition)) - 55
    )
end

function ABPButton_BeingDragged()
    local xpos, ypos = GetCursorPosition()
    local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
    xpos = xmin - xpos / UIParent:GetScale() + 70
    ypos = ypos / UIParent:GetScale() - ymin - 70
    ABPButton_SetPosition(math.deg(math.atan2(ypos, xpos)))
end

function ABPButton_SetPosition(v)
    if v < 0 then v = v + 360 end
    ABP_ButtonPosition = v
    ABPButton_UpdatePosition()
end

StaticPopupDialogs["ABP_NewProfile"] = {
    text = "为当前动作条保存输入一个名称",
    button1 = SAVE,
    button2 = CANCEL,
    OnAccept = function()
        local profileName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        ABP_SaveProfile(profileName)
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText("")
    end,
    EditBoxOnEnterPressed = function()
        local profileName = this:GetText()
        ABP_SaveProfile(profileName)
        this:SetText("")
        this:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    hasEditBox = true,
    preferredIndex = 3,
}
