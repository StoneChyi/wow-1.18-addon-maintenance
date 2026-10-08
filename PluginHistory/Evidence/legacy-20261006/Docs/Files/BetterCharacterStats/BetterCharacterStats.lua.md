# BetterCharacterStats/BetterCharacterStats.lua

类型：modified；新增 8 行，删除 2 行。

基线：10-06 BCS 同次刷新扫描复用前
基线来源：E:\1.18\addons_tmp\character-bcs-scan-backup-20261006\BetterCharacterStats_BetterCharacterStats.lua.original

当前 SHA-256：`85b481bc27e3abfd4e0d2898f4d4f34892b42484ee53e7551f3963f76c2706fa`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 273 / 0 | 273 / 4 | insert | `UpdateBothPaperdollStats（第273行）` |
| 275 / 2 | 279 / 4 | replace | `BCS:UpdateStats（第277行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/BetterCharacterStats/BetterCharacterStats.lua
+++ b/BetterCharacterStats/BetterCharacterStats.lua
@@ -268,14 +268,20 @@
 	
 	BCS:Print(format("Average: %d (%d results), Exact: %d", avg, getn(avgV), timeUsed))
 end
 ]]
 
+local function UpdateBothPaperdollStats()
+	BCS:UpdatePaperdollStats("PlayerStatFrameLeft", IndexLeft)
+	BCS:UpdatePaperdollStats("PlayerStatFrameRight", IndexRight)
+end
 function BCS:UpdateStats()
 	if not BCS:IsCharacterPanelEnabled() then return end
-	BCS:UpdatePaperdollStats("PlayerStatFrameLeft", IndexLeft)
-	BCS:UpdatePaperdollStats("PlayerStatFrameRight", IndexRight)
+	BCS:BeginEquipmentRead()
+	local ok, message = pcall(UpdateBothPaperdollStats)
+	BCS:EndEquipmentRead()
+	if not ok then error(message, 0) end
 end
 
 function BCS:SetStat(statFrame, statIndex)
 	local label = getglobal(statFrame:GetName().."Label")
 	local text = getglobal(statFrame:GetName().."StatText")
```
