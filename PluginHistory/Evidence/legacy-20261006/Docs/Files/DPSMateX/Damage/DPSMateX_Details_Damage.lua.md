# DPSMateX/Damage/DPSMateX_Details_Damage.lua

类型：modified；新增 1 行，删除 1 行。

基线：10-06 Boss/小怪汇总接入前
基线来源：E:\1.18\addons_tmp\dpsmatex-encounters-backup-20261006\DPSMateX\Damage\DPSMateX_Details_Damage.lua

当前 SHA-256：`74512438031dda3061ebf5566592761bd2eb9e5ec8353fb5cc27d3cc6784731d`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 78 / 1 | 78 / 1 | replace | `DPSMateX.Modules.DetailsDamage:UpdateCompare（第70行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateX/Damage/DPSMateX_Details_Damage.lua
+++ b/DPSMateX/Damage/DPSMateX_Details_Damage.lua
@@ -73,11 +73,11 @@
 	
 	DPSMateX_Details_CompareDamage.proc = "None"
 	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, "None")
 	DetailsUserComp = comp
 	DPSMateX_Details_CompareDamage_Title:SetText(DPSMateX.L["dmgdoneby"]..comp)
-	DPSMateX_Details_CompareDamage_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", DPSMateX.CombatTime["effective"][key][comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateX.CombatTime["effective"][key][comp] or 0)/cbt).."%)")
+	DPSMateX_Details_CompareDamage_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0)/cbt).."%)")
 	UIDropDownMenu_Initialize(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, DPSMateX.Modules.DetailsDamage.ProcsDropDown_CompareDamage)
 	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
 	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
 	
 	if not g4 then
```
