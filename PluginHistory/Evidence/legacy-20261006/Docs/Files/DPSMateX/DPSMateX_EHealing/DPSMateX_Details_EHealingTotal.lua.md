# DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua

类型：modified；新增 1 行，删除 1 行。

基线：10-06 Boss/小怪汇总接入前
基线来源：E:\1.18\addons_tmp\dpsmatex-encounters-backup-20261006\DPSMateX\DPSMateX_EHealing\DPSMateX_Details_EHealingTotal.lua

当前 SHA-256：`b2c283a78f124de1537ea971ca980b96fd1d5f81bbc013600fe2dbfab1c45301`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 271 / 1 | 271 / 1 | replace | `DPSMateX.Modules.DetailsEHealingTotal:GetTableValues（第258行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua
+++ b/DPSMateX/DPSMateX_EHealing/DPSMateX_Details_EHealingTotal.lua
@@ -266,11 +266,11 @@
 					totCrit=totCrit+va[3]+va[2]
 					totMiss=totMiss+va[2]+va[3]
 					crit=crit+va[3]
 					miss=miss+va[2]
 				else
-					time = tonumber(strformat("%.2f", DPSMateX.CombatTime["effective"][curKey][name] or 0))
+					time = tonumber(strformat("%.2f", DPSMateX:GetSelectedEffectiveTime(curKey)[name] or 0))
 				end
 			end
 			tinsert(arr, {name, val["i"], crit, miss, time, totCrit, totMiss, cat})
 			total = total + val["i"]
 		end
```
