# Cat/CatEvent-Paladin.lua

类型：modified；新增 3 行，删除 0 行。

基线：10-06 骑士控制扩展前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-paladin-controls\original\Cat\CatEvent-Paladin.lua

当前 SHA-256：`d149d1379df49a8ea9588d1d19d987ad73d9d100cf36b50bcda2153a5d971507`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 416 / 0 | 416 / 3 | insert | `MPSeal（第415行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/Cat/CatEvent-Paladin.lua
+++ b/Cat/CatEvent-Paladin.lua
@@ -411,10 +411,13 @@
 
 -- 获取自己是否有圣印效果
 -- 注：SuperWow支持更加准确
 -- return 存在返回真
 function MPSeal(name)
+    if name == "公正圣印" then
+        return MPBuff(name)
+    end
 
     --[[
     -- 检测是否有SuperWow模组
     if not MP_SuperWoW then
 	    if name=="正义圣印" then
```
