# DPSMateXInsights/DPSMateXInsights.toc

类型：added；新增 13 行，删除 0 行。

基线：10-06 新增独立模块，整文件均为新增代码
基线来源：新增文件，无旧文件

当前 SHA-256：`6a6caf81c2de244a846a6e6ea6cc15f7ae705765f57bd9666e4a8bc024111e26`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 1 / 0 | 1 / 13 | insert | `文件顶部 / 表定义` |

## 当前加载与保存声明

```text
## Interface: 11200
## Title: |CFFEE7600[DPS统计]|RDPSMateXInsights
## Notes: Actual absorbs, successful spell casts and action timelines for DPSMateX.
## Title-zhCN: |CFFEE7600[DPS统计]|RDPSMateX 精确统计扩展
## Notes-zhCN: 治疗与实际吸收、成功施放、动作回放及详细数据界面。
## Version: 1.0.1
## Dependencies: DPSMateX
## SavedVariablesPerCharacter: DPSMateXInsightsDB

Core.lua
Parser.lua
Modules.lua
Details.lua
```

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- /dev/null
+++ b/DPSMateXInsights/DPSMateXInsights.toc
@@ -0,0 +1,13 @@
+## Interface: 11200
+## Title: |CFFEE7600[DPS统计]|RDPSMateXInsights
+## Notes: Actual absorbs, successful spell casts and action timelines for DPSMateX.
+## Title-zhCN: |CFFEE7600[DPS统计]|RDPSMateX 精确统计扩展
+## Notes-zhCN: 治疗与实际吸收、成功施放、动作回放及详细数据界面。
+## Version: 1.0.1
+## Dependencies: DPSMateX
+## SavedVariablesPerCharacter: DPSMateXInsightsDB
+
+Core.lua
+Parser.lua
+Modules.lua
+Details.lua
```
