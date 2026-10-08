# DPSMateXEncounters/DPSMateXEncounters.toc

类型：added；新增 12 行，删除 0 行。

基线：10-06 新增独立模块，整文件均为新增代码
基线来源：新增文件，无旧文件

当前 SHA-256：`8b0d51765456cd62256fc99ce5b8543073e990be295df8cefb9031b15126d366`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 1 / 0 | 1 / 12 | insert | `文件顶部 / 表定义` |

## 当前加载与保存声明

```text
## Interface: 11200
## Title: |CFFEE7600[DPS统计]|RDPSMateX 战斗分类
## Notes: Boss and trash aggregate time ranges for DPSMateX.
## Notes-zhCN: Boss与小怪汇总时间范围，独立于历史保留数量。
## Version: 1.0.0
## Dependencies: DPSMateX
## OptionalDeps: DPSMateXInsights
## SavedVariablesPerCharacter: DPSMateXEncountersDB

Merge.lua
Encounter.lua
Views.lua
```

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- /dev/null
+++ b/DPSMateXEncounters/DPSMateXEncounters.toc
@@ -0,0 +1,12 @@
+## Interface: 11200
+## Title: |CFFEE7600[DPS统计]|RDPSMateX 战斗分类
+## Notes: Boss and trash aggregate time ranges for DPSMateX.
+## Notes-zhCN: Boss与小怪汇总时间范围，独立于历史保留数量。
+## Version: 1.0.0
+## Dependencies: DPSMateX
+## OptionalDeps: DPSMateXInsights
+## SavedVariablesPerCharacter: DPSMateXEncountersDB
+
+Merge.lua
+Encounter.lua
+Views.lua
```
