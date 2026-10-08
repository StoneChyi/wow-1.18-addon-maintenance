# Cat/UI/Settings-WarlockFD.lua

类型：modified；新增 1 行，删除 0 行。

基线：10-05 设置读取修复前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-settings-audit\original\UI\Settings-WarlockFD.lua

当前 SHA-256：`06508e1036d405547cd0d3243351ba99dd1c9a65f9aada3815e476caa46794be`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 718 / 0 | 718 / 1 | insert | `MPInitWarlockFDSettingsPart1（第681行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/Cat/UI/Settings-WarlockFD.lua
+++ b/Cat/UI/Settings-WarlockFD.lua
@@ -713,10 +713,11 @@
     checkButton_CurseElements:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseElements))
     checkButton_CurseShadow:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseShadow))
     checkButton_CurseTongues:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseTongues))
     checkButton_CurseFatigue:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseFatigue))
     checkButton_CurseDoom:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseDoom))
+    checkButton_CurseWeakness:SetChecked(MPToBoolean(MPWarlockFDSaved[ConfigCurrent].CurseWeakness))
 
 
 end
 
 function MPInitWarlockFDSettings()
```
