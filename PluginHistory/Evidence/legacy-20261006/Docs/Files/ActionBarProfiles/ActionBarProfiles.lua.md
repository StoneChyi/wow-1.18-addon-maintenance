# ActionBarProfiles/ActionBarProfiles.lua

类型：modified；新增 206 行，删除 83 行。

基线：10-06 天赋动作条联动前
基线来源：E:\1.18\addons_tmp\talent-panel-actionbar-backup-20261006-091747\ActionBarProfiles\ActionBarProfiles.lua

当前 SHA-256：`a10fa80903e38477e32cc07dc57fb0923508f4a7f1bd597006c9d639569dc467`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 52 / 0 | 52 / 32 | insert | `ABP_TooltipAttach（第46行）` |
| 55 / 0 | 87 / 5 | insert | `ABP_SaveProfile（第84行）` |
| 58 / 1 | 95 / 1 | replace | `ABP_SaveProfile（第84行）` |
| 69 / 8 | 106 / 9 | replace | `ABP_SaveProfile（第84行）` |
| 78 / 6 | 116 / 6 | replace | `ABP_SaveProfile（第84行）` |
| 85 / 10 | 123 / 12 | replace | `ABP_SaveProfile（第84行）` |
| 99 / 0 | 139 / 7 | insert | `ABP_SaveProfile（第84行）` |
| 100 / 2 | 147 / 1 | replace | `ABP_SaveProfile（第84行）` |
| 103 / 0 | 149 / 1 | insert | `ABP_SaveProfile（第84行）` |
| 148 / 1 | 195 / 1 | replace | `ABP_FindItemsInEquipment（第182行）` |
| 175 / 1 | 222 / 1 | replace | `ABP_FindItemsInBags（第209行）` |
| 179 / 1 | 226 / 1 | replace | `ABP_FindItemsInBags（第209行）` |
| 195 / 1 | 242 / 1 | replace | `ABP_LoadProfile（第242行）` |
| 199 / 1 | 246 / 9 | replace | `ABP_LoadProfile（第242行）` |
| 203 / 0 | 258 / 4 | insert | `ABP_LoadProfile（第242行）` |
| 206 / 0 | 265 / 22 | insert | `ABP_LoadProfile（第242行）` |
| 221 / 4 | 302 / 10 | replace | `ABP_LoadProfile（第242行）` |
| 226 / 1 | 313 / 0 | delete | `ABP_LoadProfile（第242行）` |
| 228 / 1 | 314 / 0 | delete | `ABP_LoadProfile（第242行）` |
| 233 / 0 | 318 / 1 | insert | `ABP_LoadProfile（第242行）` |
| 234 / 26 | 320 / 15 | replace | `ABP_LoadProfile（第242行）` |
| 261 / 10 | 336 / 1 | replace | `ABP_LoadProfile（第242行）` |
| 273 / 4 | 339 / 15 | replace | `ABP_LoadProfile（第242行）` |
| 279 / 1 | 356 / 27 | replace | `ABP_LoadProfile（第242行）` |
| 281 / 1 | 384 / 8 | replace | `ABP_LoadProfile（第242行）` |
| 283 / 3 | 393 / 16 | replace | `ABP_LoadProfile（第242行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/ActionBarProfiles/ActionBarProfiles.lua
+++ b/ActionBarProfiles/ActionBarProfiles.lua
@@ -47,61 +47,108 @@
     if ABP_Tooltip and ABP_Tooltip.SetOwner then
         ABP_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
     end
 end
 
+-- 自动联动和手动保存/加载共用保护，避免抢走玩家或换装插件的光标。
+function ABP_CanChangeActions()
+    if (InCombatLockdown and InCombatLockdown())
+       or (UnitAffectingCombat and UnitAffectingCombat("player")) then
+        return false, "combat"
+    end
+    if SM_CURSOR or (GetCursorInfo and GetCursorInfo())
+       or (CursorHasItem and CursorHasItem())
+       or (CursorHasSpell and CursorHasSpell())
+       or (CursorHasMacro and CursorHasMacro())
+       or (SpellIsTargeting and SpellIsTargeting()) then
+        return false, "cursor"
+    end
+    return true
+end
+
+local function ABP_ResetCursor()
+    ClearCursor()
+    -- SuperMacro 的虚拟光标不随原生 ClearCursor 清除。
+    if SM_ACTION then SM_CURSOR = nil end
+end
+
+local function ABP_ClearAction(slot)
+    if HasAction(slot) or (SM_ACTION and SM_ACTION[slot]) then
+        PickupAction(slot)
+        ABP_ResetCursor()
+        if HasAction(slot) or (SM_ACTION and SM_ACTION[slot]) then
+            error("无法清除第" .. slot .. "格")
+        end
+    end
+end
+
 function ABP_SaveProfile(profileName)
     if not profileName or profileName == "" then return end
     if not ABP_PlayerName then return end
+    local canChange = ABP_CanChangeActions()
+    if not canChange then
+        ABP_Msg("当前处于战斗或正在拖动/施放，请结束后再保存动作条。")
+        return false
+    end
     if not ABP_Layout then ABP_Layout = {} end
     if not ABP_Layout[ABP_PlayerName] then ABP_Layout[ABP_PlayerName] = {} end
 
-    ABP_Layout[ABP_PlayerName][profileName] = {
+    local profile = {
         spells = {},  -- [slot] = { name=, rank= }
         macros = {},  -- [slot] = macroName
         items  = {},  -- [slot] = itemName
     }
 
     ABP_TooltipAttach()
 
     local scStatus = GetCVar("autoSelfCast")
     SetCVar("autoSelfCast", 0)
 
-    for i = 1, MAX_ACTIONS do
-        if HasAction(i) then
-            local macroName = GetActionText(i)
-            if macroName and macroName ~= "" then
-                ABP_Layout[ABP_PlayerName][profileName].macros[i] = macroName
-            else
-                ABP_Tooltip:ClearLines()
-                ABP_Tooltip:SetAction(i)
-
-                local isSpell = false
-                do
-                    PickupAction(i)
-                    isSpell = CursorHasSpell()
-                    PlaceAction(i)
-                end
-
-                if isSpell then
-                    local spellName, rankText = ABP_GetTooltipLine1()
-                    ABP_Layout[ABP_PlayerName][profileName].spells[i] = {
-                        name = spellName,
-                        rank = rankText,
-                    }
+    local ok, err = pcall(function()
+        for i = 1, MAX_ACTIONS do
+            if HasAction(i) or (SM_ACTION and SM_ACTION[i]) then
+                local macroName = GetActionText(i)
+                if macroName and macroName ~= "" then
+                    profile.macros[i] = macroName
                 else
-                    local itemName = (select(1, ABP_GetTooltipLine1()))
-                    if itemName and itemName ~= "" then
-                        ABP_Layout[ABP_PlayerName][profileName].items[i] = itemName
+                    ABP_Tooltip:ClearLines()
+                    ABP_Tooltip:SetAction(i)
+
+                    local isSpell = false
+                    do
+                        PickupAction(i)
+                        isSpell = CursorHasSpell()
+                        PlaceAction(i)
+                    end
+
+                    if isSpell then
+                        local spellName, rankText = ABP_GetTooltipLine1()
+                        if not spellName or spellName == "" then error("无法读取第" .. i .. "格技能") end
+                        profile.spells[i] = {
+                            name = spellName,
+                            rank = rankText,
+                        }
+                    else
+                        local itemName = ABP_GetTooltipLine1()
+                        if itemName and itemName ~= "" then
+                            profile.items[i] = itemName
+                        end
                     end
                 end
             end
         end
-    end
-
+    end)
+
+    ABP_ResetCursor()
     SetCVar("autoSelfCast", scStatus)
+    if not ok then
+        ABP_Msg("动作条保存失败，原配置已保留：" .. tostring(err))
+        return false
+    end
+    ABP_Layout[ABP_PlayerName][profileName] = profile
     ABP_Msg('配置文件 "' .. profileName .. '" 已保存.')
+    return true
 end
 
 local function ABP_BuildNeededSpellMap(neededSpellKeys)
     local result = {}
     if not neededSpellKeys or not next(neededSpellKeys) then return result end
@@ -143,11 +190,11 @@
 
     for slot = 1, 19 do
         ABP_Tooltip:ClearLines()
         local hasItem = ABP_Tooltip:SetInventoryItem("player", slot)
         if hasItem then
-            local itemName = (select(1, ABP_GetTooltipLine1()))
+            local itemName = ABP_GetTooltipLine1()
             if itemName and remaining[itemName] then
                 equipMap[itemName] = slot
                 remaining[itemName] = nil
                 leftCount = leftCount - 1
                 if leftCount == 0 then
@@ -170,15 +217,15 @@
 
     for bag = 0, NUM_BAG_SLOTS do
         local slots = GetContainerNumSlots(bag)
         if slots and slots > 0 then
             for slot = 1, slots do
-                local texture = (select(1, GetContainerItemInfo(bag, slot)))
+                local texture = GetContainerItemInfo(bag, slot)
                 if texture then
                     ABP_Tooltip:ClearLines()
                     ABP_Tooltip:SetBagItem(bag, slot)
-                    local itemName = (select(1, ABP_GetTooltipLine1()))
+                    local itemName = ABP_GetTooltipLine1()
                     if itemName and remaining[itemName] then
                         bagMap[itemName] = { bag = bag, slot = slot }
                         remaining[itemName] = nil
                         leftCount = leftCount - 1
                         if leftCount == 0 then
@@ -190,22 +237,56 @@
         end
     end
     return bagMap
 end
 
-function ABP_LoadProfile(profileName)
+function ABP_LoadProfile(profileName, options)
     if not ABP_PlayerName or not ABP_Layout or not ABP_Layout[ABP_PlayerName]
        or not ABP_Layout[ABP_PlayerName][profileName] then
         ABP_Msg('配置文件 "' .. tostring(profileName) .. '" 以前没有保存，无法加载.')
-        return
+        return false, "no_profile"
+    end
+
+    local canChange, reason = ABP_CanChangeActions()
+    if not canChange then
+        if not options or not options.quiet then
+            ABP_Msg("当前处于战斗或正在拖动/施放，请结束后再加载动作条。")
+        end
+        return false, reason
     end
 
     local profile = ABP_Layout[ABP_PlayerName][profileName]
+    if type(profile) ~= "table" then
+        ABP_Msg("动作条配置格式有误，未更改当前动作条。")
+        return false, "invalid_profile"
+    end
     local spells = profile.spells or {}
     local macros = profile.macros or {}
     local items  = profile.items  or {}
 
+    -- 检查全部记录后才操作动作栏；旧配置中未记录的格子即为空格。
+    local valid = (profile.spells == nil or type(profile.spells) == "table")
+        and (profile.macros == nil or type(profile.macros) == "table")
+        and (profile.items == nil or type(profile.items) == "table")
+    if valid then
+        for slot, info in pairs(spells) do
+            if type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot)
+               or type(info) ~= "table" or type(info.name) ~= "string" or info.name == ""
+               or (info.rank ~= nil and type(info.rank) ~= "string") then valid = false; break end
+        end
+        for _, entries in ipairs({macros, items}) do
+            for slot, name in pairs(entries) do
+                if type(slot) ~= "number" or slot < 1 or slot > MAX_ACTIONS or slot ~= math.floor(slot)
+                   or type(name) ~= "string" or name == "" then valid = false; break end
+            end
+        end
+    end
+    if not valid then
+        ABP_Msg("动作条配置格式有误，未更改当前动作条。")
+        return false, "invalid_profile"
+    end
+
     local neededSpellKeys = {}
     local neededItemNames = {}
 
     for slot, info in pairs(spells) do
         local key = ABP_ComposeSpellKey(info.name, info.rank)
@@ -216,75 +297,117 @@
     end
 
     local spellKeyToId   = ABP_BuildNeededSpellMap(neededSpellKeys)
     local equipItemToId  = ABP_FindItemsInEquipment(neededItemNames)
 
-    do
-        local remaining = {}
-        for name in pairs(neededItemNames) do
-            if not equipItemToId[name] then remaining[name] = true end
-        end
-        var_bagMap = ABP_FindItemsInBags(remaining)
-    end
-    local bagItemToLoc = var_bagMap or {}
+    local remaining = {}
+    for name in pairs(neededItemNames) do
+        if not equipItemToId[name] then remaining[name] = true end
+    end
+    local bagItemToLoc = ABP_FindItemsInBags(remaining)
+
+    -- 天赋切换时技能书可能尚未更新：此时保持整个动作栏不动，交给调用者稍后重试。
+    if options and options.deferMissingSpells then
+        for key in pairs(neededSpellKeys) do
+            if not spellKeyToId[key] then return false, "spells_pending" end
+        end
+    end
 
     ABP_TooltipAttach()
     local scStatus = GetCVar("autoSelfCast")
     SetCVar("autoSelfCast", 0)
-
-    for i = 1, MAX_ACTIONS do
-        repeat
-            local sp = spells[i]
-            if sp then
-                local key = ABP_ComposeSpellKey(sp.name, sp.rank)
-                local sid = key and spellKeyToId[key] or nil
-                if sid then
-                    PickupSpell(sid, BOOKTYPE_SPELL)
-                    PlaceAction(i)
-                end
-                break
-            end
-
-            local mname = macros[i]
-            if mname and mname ~= "" then
-                local picked = false
-                if GetSuperMacroInfo and GetSuperMacroInfo(mname, "texture") then
-                    PickupMacro(0, mname)
-                    PlaceAction(i)
-                    picked = true
-                else
-                    local idx = GetMacroIndexByName(mname)
-                    if idx and idx > 0 then
-                        PickupMacro(idx)
-                        PlaceAction(i)
-                        picked = true
+    local report = { missing = {}, restored = 0, cleared = 0 }
+
+    local ok, err = pcall(function()
+        for i = 1, MAX_ACTIONS do
+            -- 逐格恢复完整快照，包含空格；先清旧按钮，再放目标按钮。
+            if HasAction(i) then report.cleared = report.cleared + 1 end
+            ABP_ClearAction(i)
+            local restored = false
+            local missingName = nil
+            repeat
+                local sp = spells[i]
+                if sp then
+                    local key = ABP_ComposeSpellKey(sp.name, sp.rank)
+                    local sid = key and spellKeyToId[key] or nil
+                    if sid then
+                        PickupSpell(sid, BOOKTYPE_SPELL)
+                        if CursorHasSpell() then PlaceAction(i); restored = HasAction(i) end
                     end
-                end
-                break
-            end
-
-            local iname = items[i]
-            if iname and iname ~= "" then
-                local eslot = equipItemToId[iname]
-                if eslot then
-                    PickupInventoryItem(eslot)
-                    PlaceAction(i)
+                    missingName = "技能 " .. tostring(key)
                     break
                 end
-                local loc = bagItemToLoc[iname]
-                if loc then
-                    PickupContainerItem(loc.bag, loc.slot)
-                    PlaceAction(i)
+
+                local mname = macros[i]
+                if mname and mname ~= "" then
+                    if GetSuperMacroInfo and GetSuperMacroInfo(mname, "texture") then
+                        PickupMacro(0, mname)
+                        PlaceAction(i)
+                    else
+                        local idx = GetMacroIndexByName(mname)
+                        if idx and idx > 0 then
+                            PickupMacro(idx)
+                            PlaceAction(i)
+                        end
+                    end
+                    restored = GetActionText(i) == mname
+                    missingName = "宏 " .. mname
                     break
                 end
-                break
-            end
-        until true
-    end
-
+
+                local iname = items[i]
+                if iname and iname ~= "" then
+                    local eslot = equipItemToId[iname]
+                    if eslot then
+                        PickupInventoryItem(eslot)
+                        if CursorHasItem() then PlaceAction(i); restored = HasAction(i) end
+                        missingName = "物品 " .. iname
+                        break
+                    end
+                    local loc = bagItemToLoc[iname]
+                    if loc then
+                        PickupContainerItem(loc.bag, loc.slot)
+                        if CursorHasItem() then PlaceAction(i); restored = HasAction(i) end
+                        missingName = "物品 " .. iname
+                        break
+                    end
+                    missingName = "物品 " .. iname
+                    break
+                end
+            until true
+            ABP_ResetCursor()
+            if restored then
+                report.restored = report.restored + 1
+            elseif missingName then
+                ABP_ClearAction(i)
+                table.insert(report.missing, "第" .. i .. "格：" .. missingName)
+            end
+        end
+    end)
+
+    ABP_ResetCursor()
     SetCVar("autoSelfCast", scStatus)
-    ABP_Msg('配置文件 "' .. profileName .. '" 已加载.')
+    if not ok then
+        ABP_Msg("动作条加载中断，请重新加载：" .. tostring(err))
+        return false, "runtime_error"
+    end
+    if Flyout_UpdateBars and Flyout_GetActionButton then
+        for i = 1, 120 do
+            local button = Flyout_GetActionButton(i)
+            if button then
+                button.flyoutActions, button.flyoutAction, button.flyoutActionType = nil, nil, nil
+            end
+        end
+        Flyout_UpdateBars()
+    end
+    if table.getn(report.missing) > 0 then
+        ABP_Msg('配置文件 "' .. profileName .. '" 已恢复；以下内容未找到，对应格子已清空：')
+        for _, message in ipairs(report.missing) do ABP_Msg(message) end
+    else
+        ABP_Msg('配置文件 "' .. profileName .. '" 已完整加载（含空格）.')
+    end
+    return true, report
 end
 
 function ABP_ListProfiles()
     if not ABP_PlayerName or not ABP_Layout or not ABP_Layout[ABP_PlayerName]
        or hasElements(ABP_Layout[ABP_PlayerName]) == 0 then
```
