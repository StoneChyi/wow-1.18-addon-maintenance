# pfUI-addonskinner/skins/Cat.lua

类型：modified；新增 21 行，删除 5 行。

基线：10-06 审判图标与皮肤首次修复前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-seal-icons\original\pfUI-addonskinner\skins\Cat.lua

当前 SHA-256：`a8697f6d9f4f51b9ca4859b0b765460f4c5e63b3d8ce2afaff39d531994041dc`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 38 / 5 | 38 / 8 | replace | `ApplyCatUISkin（第28行）` |
| 44 / 0 | 47 / 9 | insert | `ApplyCatUISkin（第28行）` |
| 62 / 0 | 74 / 4 | insert | `ApplyCatUISkin（第28行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/pfUI-addonskinner/skins/Cat.lua
+++ b/pfUI-addonskinner/skins/Cat.lua
@@ -33,16 +33,28 @@
     CreateBackdrop(frame, nil, nil, .75)
 
     local closeBtn = FindCloseButton(frame)
     for _, child in ipairs({frame:GetChildren()}) do
       local t = child:GetObjectType()
-      if t == "Button" then
-        if child == closeBtn then
-          SkinCloseButton(child, frame.backdrop, -6, -6)
-        else
-          SkinButton(child)
+      if t == "Button" and child == closeBtn then
+        SkinCloseButton(child, frame.backdrop, -6, -6)
+      elseif (t == "Button" or t == "CheckButton") and child.icon
+         and child.icon.SetDrawLayer then
+        -- 图标按钮：图标必须位于按钮深色底板上方，保留图标本身的颜色。
+        -- 审判控制图标保留无边框外观，避免皮肤重新添加底板边框和图标留白。
+        if not child.MPCatBorderlessIcon then
+          SkinButton(child, nil, nil, nil, child.icon)
         end
+        child.icon:SetDrawLayer("ARTWORK")
+        child.icon:SetVertexColor(1, 1, 1)
+        child.icon:Show()
+        -- 保留 Cat 自己的选中/未选亮度，不能一律恢复为白色。
+        if type(child.MPCatRefreshAppearance) == "function" then
+          child.MPCatRefreshAppearance()
+        end
+      elseif t == "Button" then
+        SkinButton(child)
       elseif t == "CheckButton" then
         SkinCheckbox(child)
       elseif t == "EditBox" then
         StripTextures(child, true, "BACKGROUND")
         CreateBackdrop(child)
@@ -57,6 +69,10 @@
     if type(k) == "string" and string.find(k, "^Cat")
        and type(v) == "table" and v.GetObjectType and v:GetObjectType() == "Frame" then
       pcall(ApplyCatUISkin, v)
     end
   end
+  -- pfUI 可能在 Cat 初始化后才创建背景；完整套用皮肤后恢复整体透明度。
+  if type(MPCatPaladinSealApplyAppearance) == "function" then
+    MPCatPaladinSealApplyAppearance()
+  end
 end)
```
