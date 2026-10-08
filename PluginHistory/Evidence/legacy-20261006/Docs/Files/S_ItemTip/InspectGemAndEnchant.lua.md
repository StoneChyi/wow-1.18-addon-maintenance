# S_ItemTip/InspectGemAndEnchant.lua

类型：modified；新增 9 行，删除 3 行。

基线：10-06 统一观察布局首次修改前
基线来源：E:\1.18\addons_tmp\inspect-layout-backup-20261006\Interface_AddOns_S_ItemTip_InspectGemAndEnchant.lua.original

当前 SHA-256：`6f784b8b42f4ca865a68f0e397921f719bd4acc31d9466efcf2b8446d1ab87be`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 85 / 1 | 85 / 3 | replace | `CreateIconFrame（第66行）` |
| 387 / 1 | 389 / 2 | replace | `S_ItemTip_UpdateFrame（第387行）` |
| 391 / 1 | 394 / 3 | replace | `S_ItemTip_UpdateFrame（第387行）` |
| 440 / 0 | 445 / 1 | insert | `S_ItemTip_UpdateFrame（第387行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/S_ItemTip/InspectGemAndEnchant.lua
+++ b/S_ItemTip/InspectGemAndEnchant.lua
@@ -80,11 +80,13 @@
     -- 设置较高的层级，确保不被遮挡
     icon:SetFrameLevel(frame:GetFrameLevel() + 10)
     
     -- 启用鼠标事件，阻止穿透到下层
     icon:EnableMouse(true)
-    icon:SetToplevel(true)
+    -- A static child icon needs its explicit frame level, not independent
+    -- window promotion when it becomes visible with its parent.
+    icon:SetToplevel(false)
     
     icon:SetScript("OnEnter", function()
         if this.title then
             GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
             GameTooltip:SetText(this.title, 0, 1, 0.5, 1, true)
@@ -382,15 +384,18 @@
 
 --Hook 到装备更新函数（立即执行，不延迟）
 local originalUpdateFrame = S_ItemTip_UpdateFrame
 function S_ItemTip_UpdateFrame(unit)
     if originalUpdateFrame then
-        originalUpdateFrame(unit)
+        -- Respect the base update's throttle before redrawing enchant icons.
+        if originalUpdateFrame(unit) == false then return false end
     end
     
     local frame = S_ItemTip_InspectFrame
-    if not frame or not frame:IsShown() then
+    -- Equipment is populated before its parent is shown. Prepare the child
+    -- icons in the same update; their visibility follows the parent frame.
+    if not frame then
         return
     end
     
     -- 保存当前单位
     frame.currentUnit = unit
@@ -435,10 +440,11 @@
     local unitName = UnitName(unit)
     unitGuidCache[unitName] = {
         scanTime = time(),
         enchantCount = enchantCount
     }
+    if SCRequestPanelLayout then SCRequestPanelLayout() end
 end
 
 
 --Hook 到装备更新函数
 local function ExportCache()
```
