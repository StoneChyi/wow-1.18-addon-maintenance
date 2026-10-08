# STSMmayor/STSMmayor.toc

类型：modified；新增 3 行，删除 1 行。

基线：10-06 首次 UI 修改前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\stsm-ui\STSMmayor.toc.original

当前 SHA-256：`13f9549e6c1f76930249add75701956b8f25dbe9dccb38b911157f4ccf22b1e1`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 5 / 1 | 5 / 3 | replace | `文件顶部 / 表定义` |

## 当前加载与保存声明

```text
## Interface: 11200
## Title: 斯坦索姆镇长-盾牌耐久检测自动换盾插件
## Notes: 请将备用盾牌放在背包前8个格子中，使用/STSM命令 开启/关闭，支持interact和无双交互两种模组
## Author: jimmy
## Version: 2.4.6
## OptionalDeps: pfUI
## SavedVariablesPerCharacter: STSMmayorDB
## DefaultState: disabled

Libs\Ace2\AceLibrary\AceLibrary.lua
Libs\Deformat-2.0\Deformat-2.0.lua
Libs\Gratuity-2.0\Gratuity-2.0.lua
STSMmayor.lua
```

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/STSMmayor/STSMmayor.toc
+++ b/STSMmayor/STSMmayor.toc
@@ -1,10 +1,12 @@
 ## Interface: 11200
 ## Title: 斯坦索姆镇长-盾牌耐久检测自动换盾插件
 ## Notes: 请将备用盾牌放在背包前8个格子中，使用/STSM命令 开启/关闭，支持interact和无双交互两种模组
 ## Author: jimmy
-## Version: 2.4
+## Version: 2.4.6
+## OptionalDeps: pfUI
+## SavedVariablesPerCharacter: STSMmayorDB
 ## DefaultState: disabled
 
 Libs\Ace2\AceLibrary\AceLibrary.lua
 Libs\Deformat-2.0\Deformat-2.0.lua
 Libs\Gratuity-2.0\Gratuity-2.0.lua
```
