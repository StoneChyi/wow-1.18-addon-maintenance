# DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.lua

类型：modified；新增 1 行，删除 1 行。

基线：10-06 Boss/小怪汇总接入前
基线来源：E:\1.18\addons_tmp\dpsmatex-encounters-backup-20261006\DPSMateX\DPSMateX_Healing\DPSMateX_Details_Healing.lua

当前 SHA-256：`f4b4380c648966844ee1764c748c9c1f7be257e239c509d5c00298a487d13ffc`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 75 / 1 | 75 / 1 | replace | `DPSMateX.Modules.DetailsHealing:UpdateCompare（第68行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.lua
+++ b/DPSMateX/DPSMateX_Healing/DPSMateX_Details_Healing.lua
@@ -70,11 +70,11 @@
 	
 	DPSMateX_Details_CompareHealing.proc = "None"
 	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareHealing_DiagramLegend_Procs, "None")
 	DetailsUserComp = comp
 	DPSMateX_Details_CompareHealing_Title:SetText(DPSMateX.L["healdoneby"]..comp)
-	DPSMateX_Details_CompareHealing_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.1f", DPSMateX.CombatTime["effective"][key][comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.1f", cbt).."s ("..strformat("%.1f", 100*(DPSMateX.CombatTime["effective"][key][comp] or 0)/cbt).."%)")
+	DPSMateX_Details_CompareHealing_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.1f", DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.1f", cbt).."s ("..strformat("%.1f", 100*(DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0)/cbt).."%)")
 	UIDropDownMenu_Initialize(DPSMateX_Details_CompareHealing_DiagramLegend_Procs, DPSMateX.Modules.DetailsHealing.ProcsDropDown_CompareHealing)
 	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
 	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
 	
 	if not g4 then
```
