# PallyPower/PallyPower.toc

类型：modified；新增 1 行，删除 0 行。

基线：10-06 团队功能扩展前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\pallypower-extension\original\PallyPower\PallyPower.toc

当前 SHA-256：`6cfa35a55019a9c1a8909097a09b0d90edfafb9a94eab7d43607406a629f5ecf`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 12 / 0 | 12 / 1 | insert | `文件顶部 / 表定义` |

## 当前加载与保存声明

```text
## Interface: 11200
## Title:|cffFF4500[职业]|r[|Cfff58cba圣骑|R] 祝福助手
## Title-zhCN: |cffFF4500[职业]|r[|Cfff58cba圣骑|R] 祝福助手
## Notes-zhCN:按照预设的分配祝福。 |N命令：/pp 
## Author: Relar Fix, Wind, Sunelegy
## DefaultState: Enabled
## LoadOnDemand: 0
## SavedVariablesPerCharacter: PallyPower_Assignments, TenMinuteBlessingOn, PP_PerUser
## DefaultState: disabled
PallyPower.lua
PallyPower.xml
PallyPower-Extensions.lua
Bindings.xml
```

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/PallyPower/PallyPower.toc
+++ b/PallyPower/PallyPower.toc
@@ -7,6 +7,7 @@
 ## LoadOnDemand: 0
 ## SavedVariablesPerCharacter: PallyPower_Assignments, TenMinuteBlessingOn, PP_PerUser
 ## DefaultState: disabled
 PallyPower.lua
 PallyPower.xml
+PallyPower-Extensions.lua
 Bindings.xml
```
