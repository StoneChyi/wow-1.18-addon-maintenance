# pfUI-addonskinner/skins/PallyPower.lua

类型：modified；新增 3 行，删除 0 行。

基线：10-06 团队功能扩展前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\pallypower-extension\original\pfUI-addonskinner\skins\PallyPower.lua

当前 SHA-256：`92ed72b0d55f4e95698d10798c1c6f43d7f7bbfd47074ab17e26ccc55f6dfb54`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 176 / 0 | 176 / 3 | insert | `SkinEditBox（第81行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/pfUI-addonskinner/skins/PallyPower.lua
+++ b/pfUI-addonskinner/skins/PallyPower.lua
@@ -171,10 +171,13 @@
     -- 同批新增的两个勾选框
     SkinCheckbox(_G["PallyPower_OptionsFrameSolo"])
     SkinCheckbox(_G["PallyPower_OptionsFrameSoloForce"])
   end
 
+  -- 皮肤可能晚于角色存档加载；恢复用户的背景透明度与锁定状态。
+  if PallyPower_ApplyBuffBarAppearance then PallyPower_ApplyBuffBarAppearance() end
+
   _G.FLAG_OK = true
 end
 
 -- (1) 尝试登记到 addonskinner（供 GUI 列表/统一禁用），pcall 防止时序 nil
 pcall(function()
```
