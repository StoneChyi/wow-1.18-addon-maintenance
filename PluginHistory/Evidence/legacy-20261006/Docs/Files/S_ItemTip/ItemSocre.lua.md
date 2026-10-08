# S_ItemTip/ItemSocre.lua

类型：modified；新增 22 行，删除 12 行。

基线：10-06 首轮角色窗口打开优化前
基线来源：E:\1.18\addons_tmp\character-open-backup-20261006\S_ItemTip_ItemSocre.lua.original

当前 SHA-256：`37308f4cf26eeabe7f6f335cbe6242124c6b9e056966f9367b6bb0e2467a473e`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 7 / 0 | 7 / 19 | insert | `文件顶部 / 表定义` |
| 273 / 11 | 292 / 3 | replace | `ItemSocre:ScanUnit（第257行）` |
| 453 / 1 | 464 / 0 | delete | `GameTooltip.SetUnit（第443行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/S_ItemTip/ItemSocre.lua
+++ b/S_ItemTip/ItemSocre.lua
@@ -2,10 +2,29 @@
 --别特鸣谢：天乖乖
 
 local lib = LibStub("LibItem-enUS-1.0")
 local libLevel = LibStub("LibItemLevel-1.0")
 LibItem_Level = libLevel and libLevel.Item_Level or LibItem_Level or {}
+
+-- Cache only names actually requested; avoid allocating a complete database
+-- index during the first character-panel opening.
+local scoreNameIndex
+local scoreNameSource
+local function GetScoreItemIDByName(name)
+    if not lib or not lib.Item_enUS then return nil end
+    if not scoreNameIndex or scoreNameSource ~= lib.Item_enUS then
+        scoreNameIndex = {}
+        scoreNameSource = lib.Item_enUS
+    end
+    if scoreNameIndex[name] == nil then
+        scoreNameIndex[name] = false
+        for itemID, itemName in pairs(scoreNameSource) do
+            if itemName == name then scoreNameIndex[name] = itemID; break end
+        end
+    end
+    return scoreNameIndex[name] or nil
+end
 local USE_PFUI_STYLE = (pfUI and type(pfUI) == "table") or IsAddOnLoaded("pfUI")
 
 local EquipSoltList = {
 	INVTYPE_2HWEAPON,
 	INVTYPE_BODY,
@@ -268,21 +287,13 @@
             if itemLink then
                 local _, _, itemID = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")
                 local itemLevel = LibItem_Level[tonumber(itemID)] or 0
                 local itemName, _, itemRarity = GetItemInfo(itemID)
 
-                if itemLevel == 0 then              
-                    local itemName = GetItemInfo(itemID)
-                    if itemName and lib and lib.Item_enUS then
-                        for realID, engName in pairs(lib.Item_enUS) do
-                            if engName == itemName then
-                                local newItemLevel = LibItem_Level[realID] or 0
-                                itemLevel = newItemLevel
-                                break
-                            end
-                        end
-                    end
+                if itemLevel == 0 and itemName then
+                    local realID = GetScoreItemIDByName(itemName)
+                    if realID then itemLevel = LibItem_Level[realID] or 0 end
                 end
 
                 local coef = slotCoefficients[i] or 1
 
                 if i == 16 then
@@ -448,6 +459,5 @@
 				end
 			end
 		end
 	end
 end
-
```
