# pfUI-addonskinner/skins/StatCompare.lua

类型：modified；新增 6 行，删除 0 行。

基线：10-06 统一观察布局首次修改前
基线来源：E:\1.18\addons_tmp\inspect-layout-backup-20261006\Interface_AddOns_pfUI-addonskinner_skins_StatCompare.lua.original

当前 SHA-256：`ab68053ea16bb68b6cd905177b49f79e0175f7f2153e10046c9437df2f7fe7a0`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 29 / 0 | 29 / 6 | insert | `ReposSpellButton（第20行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/pfUI-addonskinner/skins/StatCompare.lua
+++ b/pfUI-addonskinner/skins/StatCompare.lua
@@ -24,7 +24,13 @@
 end
 
 ReposSpellButton(StatCompareSelfFrameSpellsButton, StatCompareSelfFrame)
 ReposSpellButton(StatCompareTargetFrameSpellsButton, StatCompareTargetFrame)
 
+if SCApplyPanelStyle then
+  SCApplyPanelStyle(StatCompareSelfFrame)
+  SCApplyPanelStyle(StatCompareTargetFrame)
+end
+if SCRequestPanelLayout then SCRequestPanelLayout() end
+
   pfUI.addonskinner:UnregisterSkin("StatCompare")
 end)
```
