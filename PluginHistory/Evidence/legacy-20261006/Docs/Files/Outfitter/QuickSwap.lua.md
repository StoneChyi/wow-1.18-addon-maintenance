# Outfitter/QuickSwap.lua

类型：modified；新增 36 行，删除 18 行。

基线：10-05 悬停修复前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\outfitter-popup-analysis\QuickSwap.original.lua

当前 SHA-256：`7b63550153780d6834cafbdc149f182c007294654e7943f1604f5927883476e5`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 3618 / 0 | 3618 / 21 | insert | `OutfitterQuickSwap_OnEvent（第3569行）` |
| 3663 / 18 | 3684 / 15 | replace | `OutfitterQuickSwap_OnUpdate（第3639行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/Outfitter/QuickSwap.lua
+++ b/Outfitter/QuickSwap.lua
@@ -3613,10 +3613,31 @@
     elseif vEvent == "PLAYER_LOGOUT" then
         OutfitterQuickSwap_SaveSettings();
     end
 end
 
+-- 按整个框体的矩形范围判断悬停，物品之间的空隙也属于列表。
+-- 鼠标坐标换算到框体坐标，兼容主界面缩放与两分栏的独立缩放。
+local function OutfitterQuickSwap_IsCursorInsideFrame(pFrame)
+    if not pFrame or not pFrame:IsShown() then
+        return false;
+    end
+
+    local vLeft, vRight = pFrame:GetLeft(), pFrame:GetRight();
+    local vBottom, vTop = pFrame:GetBottom(), pFrame:GetTop();
+    local vScale = pFrame:GetEffectiveScale();
+
+    if not vLeft or not vRight or not vBottom or not vTop or not vScale or vScale <= 0 then
+        return false;
+    end
+
+    local vX, vY = GetCursorPosition();
+    vX, vY = vX / vScale, vY / vScale;
+
+    return vX >= vLeft and vX <= vRight and vY >= vBottom and vY <= vTop;
+end
+
 function OutfitterQuickSwap_OnUpdate(pElapsed)
     -- 缩放百分比提示显示 1s 后消失
     if gQS_ScaleTextHideAt and GetTime() > gQS_ScaleTextHideAt then
         gQS_ScaleTextHideAt = nil;
         if OutfitterQuickSwapScaleText then
@@ -3658,28 +3679,25 @@
     if gQS_ForceRefreshAt and GetTime() >= gQS_ForceRefreshAt then
         gQS_ForceRefreshAt = nil;
         OutfitterQuickSwap_RefreshBar();
     end
 
-    -- 悬停弹出的自动收起：鼠标同时离开锚定按钮和弹出框，宽限 0.75s（TrinketMenu 手感）。
-    -- 备选框常显（PopupAlways，TrinketMenu KeepOpen 同款）时不安排收起，已排队的也取消
-    if gQS_HideAt then
-        if gOutfitterQuickSwap_Settings.PopupAlways then
-            gQS_HideAt = nil;
-        elseif GetTime() >= gQS_HideAt then
-            if OutfitterQuickSwapPopup then
-                OutfitterQuickSwapPopup:Hide();
-            end
-            gQS_PopupOwner = nil;
-            gQS_PopupSlot = nil;
-            gQS_HideAt = nil;
-        end
-    elseif gQS_PopupOwner and OutfitterQuickSwapPopup and OutfitterQuickSwapPopup:IsShown() then
-        if not gOutfitterQuickSwap_Settings.PopupAlways
-            and not MouseIsOver(gQS_PopupOwner) and not MouseIsOver(OutfitterQuickSwapPopup) then
-            gQS_HideAt = GetTime() + 0.75;
-        end
+    -- 整个备选框（含装备间隙）及原按钮都能保持列表开启。
+    -- 只有持续离开两者 0.75s 才收起；重新进入时立即取消倒计时。
+    if gOutfitterQuickSwap_Settings.PopupAlways
+        or not gQS_PopupOwner or not OutfitterQuickSwapPopup or not OutfitterQuickSwapPopup:IsShown() then
+        gQS_HideAt = nil;
+    elseif OutfitterQuickSwap_IsCursorInsideFrame(gQS_PopupOwner)
+        or OutfitterQuickSwap_IsCursorInsideFrame(OutfitterQuickSwapPopup) then
+        gQS_HideAt = nil;
+    elseif not gQS_HideAt then
+        gQS_HideAt = GetTime() + 0.75;
+    elseif GetTime() >= gQS_HideAt then
+        OutfitterQuickSwapPopup:Hide();
+        gQS_PopupOwner = nil;
+        gQS_PopupSlot = nil;
+        gQS_HideAt = nil;
     end
 end
 
 --------------------------------------------------------------------------
 -- 初始化
```
