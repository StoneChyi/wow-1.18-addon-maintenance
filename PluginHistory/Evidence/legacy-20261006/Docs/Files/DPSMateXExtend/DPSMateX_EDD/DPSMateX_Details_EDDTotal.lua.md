# DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua

类型：modified；新增 1 行，删除 1 行。

基线：10-06 Boss/小怪汇总接入前
基线来源：E:\1.18\addons_tmp\dpsmatex-encounters-backup-20261006\DPSMateXExtend\DPSMateX_EDD\DPSMateX_Details_EDDTotal.lua

当前 SHA-256：`73f3d5bc4e2156c5703b584689dcb02f1e42af1938ee05fdb7adfbeb56bb4755`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 446 / 1 | 446 / 1 | replace | `DPSMateX.Modules.DetailsEDDTotal:LoadTable（第425行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua
+++ b/DPSMateXExtend/DPSMateX_EDD/DPSMateX_Details_EDDTotal.lua
@@ -441,11 +441,11 @@
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_Crush"):SetText(strformat("%.1f", 100*val[10]/val[11]).."%")
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_Hit"):SetText(strformat("%.1f", 100*val[8]/val[11]).."%")
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[11]).."%")
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[11]).."%")
-		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_EDPS"):SetText(strformat("%.1f", val[2]/(((DPSMateX.CombatTime["effective"][curKey][val[1]]) or cbt)+1)))
+		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat.."_EDPS"):SetText(strformat("%.1f", val[2]/(((DPSMateX:GetSelectedEffectiveTime(curKey)[val[1]]) or cbt)+1)))
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat).user = val[7]
 		_G("DPSMateX_Details_EDDTotal_PlayerList_Child_R"..cat):Show()
 	end
 end
```
