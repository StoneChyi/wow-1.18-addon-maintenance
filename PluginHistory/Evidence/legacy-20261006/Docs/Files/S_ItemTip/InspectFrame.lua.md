# S_ItemTip/InspectFrame.lua

类型：modified；新增 99 行，删除 48 行。

基线：10-06 统一观察布局首次修改前
基线来源：E:\1.18\addons_tmp\inspect-layout-backup-20261006\Interface_AddOns_S_ItemTip_InspectFrame.lua.original

当前 SHA-256：`9198ae78619c3861f112941fcdf1a29fb1f9667b0bddc221431f5a5264893547`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 199 / 0 | 199 / 30 | insert | `S_ItemTip_ApplyLayoutPolicy（第199行）` |
| 200 / 1 | 230 / 1 | replace | `S_ItemTip_CreateInspectFrame（第230行）` |
| 209 / 1 | 239 / 1 | replace | `S_ItemTip_CreateInspectFrame（第230行）` |
| 218 / 1 | 248 / 2 | replace | `S_ItemTip_CreateInspectFrame（第230行）` |
| 221 / 1 | 252 / 1 | replace | `S_ItemTip_CreateInspectFrame（第230行）` |
| 232 / 1 | 263 / 1 | replace | `S_ItemTip_CreateInspectFrame（第230行）` |
| 236 / 0 | 267 / 2 | insert | `S_ItemTip_CreateInspectFrame（第230行）` |
| 419 / 2 | 452 / 2 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 424 / 1 | 457 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 443 / 1 | 476 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 453 / 1 | 486 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 479 / 1 | 512 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 521 / 1 | 554 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 523 / 1 | 556 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 534 / 7 | 567 / 2 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 555 / 1 | 583 / 1 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 574 / 2 | 602 / 2 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 588 / 2 | 616 / 2 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 603 / 5 | 631 / 2 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 614 / 1 | 639 / 5 | replace | `S_ItemTip_UpdateFrame（第450行）` |
| 619 / 0 | 648 / 5 | insert | `S_ItemTip_RelayoutStatCompare（第647行）` |
| 706 / 1 | 740 / 1 | replace | `S_ItemTip_ShowForInspect（第738行）` |
| 710 / 0 | 744 / 1 | insert | `S_ItemTip_ShowForInspect（第738行）` |
| 711 / 8 | 746 / 10 | replace | `S_ItemTip_ShowForInspect（第738行）` |
| 720 / 0 | 757 / 1 | insert | `S_ItemTip_ShowForInspect（第738行）` |
| 730 / 1 | 768 / 1 | replace | `S_ItemTip_OnCharacterShow（第766行）` |
| 735 / 0 | 773 / 1 | insert | `S_ItemTip_OnCharacterShow（第766行）` |
| 743 / 4 | 782 / 11 | replace | `S_ItemTip_OnCharacterShow（第766行）` |
| 748 / 0 | 794 / 1 | insert | `S_ItemTip_OnCharacterShow（第766行）` |
| 885 / 1 | 932 / 1 | replace | `HookInspectFrame（第865行）` |
| 912 / 1 | 959 / 1 | replace | `HookInspectFrame（第865行）` |
| 930 / 1 | 977 / 1 | replace | `HookInspectFrame（第865行）` |
| 992 / 0 | 1039 / 4 | insert | `ForceStatComparePosition（第1038行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/S_ItemTip/InspectFrame.lua
+++ b/S_ItemTip/InspectFrame.lua
@@ -194,47 +194,80 @@
 
 --全局变量（供 InspectGemAndEnchant.lua 使用）
 S_ItemTip_InspectFrame = nil
 local currentUnit = "player"
 
+function S_ItemTip_ApplyLayoutPolicy(frame)
+    if SCApplyPanelDisplayPolicy then SCApplyPanelDisplayPolicy(frame) end
+    -- Automatic anchors belong to the shared chain. Independent screen
+    -- clamping can move that chain while its root is becoming visible.
+    local clamp = not SCGetPanelLayoutMode or SCGetPanelLayoutMode() == "free"
+    if frame.sItemTipClamped ~= clamp then
+        frame:SetClampedToScreen(clamp)
+        frame.sItemTipClamped = clamp
+    end
+end
+
+local function SetPanelText(font, value)
+    value = tostring(value or "")
+    if font:GetText() ~= value then font:SetText(value) end
+end
+
+local function ItemNameWidth(font)
+    local text = font:GetText()
+    local file, size, flags = font:GetFont()
+    local cache = font.sItemTipMeasurement
+    if cache and cache.text == text and cache.file == file and cache.size == size and cache.flags == flags then
+        return cache.width
+    end
+    font:SetWidth(0)
+    local width = font:GetWidth()
+    font:SetWidth(width)
+    font.sItemTipMeasurement = {text=text,file=file,size=size,flags=flags,width=width}
+    return width
+end
+
 --创建主框架
-local function CreateFrame_Delayed()
+function S_ItemTip_CreateInspectFrame()
     if S_ItemTip_InspectFrame then return S_ItemTip_InspectFrame end
     
     S_ItemTip_InspectFrame = CreateFrame("Frame", "S_ItemTip_InspectFrame_UI", UIParent)
     local frame = S_ItemTip_InspectFrame
     frame:SetWidth(INSPECT_FRAME_WIDTH)
     frame:SetHeight(INSPECT_FRAME_HEIGHT)  -- 保持原来的固定高度
     frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -35, -10)
     frame:SetFrameStrata("MEDIUM")
-    frame:SetToplevel(true)
+    if not SCApplyPanelDisplayPolicy then frame:SetToplevel(true) end
     frame:SetBackdrop({
         bgFile = "Interface\\AddOns\\pfUI\\img\\bar",
         edgeFile = "",  -- 空字符串，无边框
         tile = true,
         tileSize = 16,
         edgeSize = 10,
         insets = {left = 5, right = 5, top = 5, bottom = 5}
     })
-    frame:SetBackdropColor(0, 0, 0, 0.5)
+    frame:SetBackdropColor(0, 0, 0, 0.75)
+    if SCApplyPanelStyle then SCApplyPanelStyle(frame) end
     frame:EnableMouse(true)
     frame:SetMovable(true)
-    frame:SetClampedToScreen(true)
+    S_ItemTip_ApplyLayoutPolicy(frame)
     frame:Hide()
 
     -- 点击时提升层级
     frame:SetScript("OnMouseDown", function()
         this:Raise()
     end)
 
     -- 添加拖动功能
     frame:RegisterForDrag("LeftButton")
     frame:SetScript("OnDragStart", function()
-        this:StartMoving()
+        if not SCGetPanelLayoutMode or SCGetPanelLayoutMode() == "free" then this:StartMoving() end
     end)
     frame:SetScript("OnDragStop", function()
         this:StopMovingOrSizing()
+        this.scFreePosition = true
+        if SCRequestPanelLayout then SCRequestPanelLayout() end
     end)
 
     --头像框架
     frame.portraitFrame = CreateFrame("Frame", nil, frame)
     frame.portraitFrame:SetWidth(64)
@@ -414,16 +447,16 @@
 end
 
 --更新装备信息（全局函数，供 InspectGemAndEnchant.lua 使用）
 function S_ItemTip_UpdateFrame(unit)
     local frame = S_ItemTip_InspectFrame
-    if not frame then return end
-    if not UnitExists(unit) then return end
+    if not frame then return false end
+    if not UnitExists(unit) then return false end
 
     local now = GetTime()
     if frame.lastUpdateUnit == unit and frame.lastUpdateTime and (now - frame.lastUpdateTime) < S_ITEMTIP_UPDATE_THROTTLE then
-        return
+        return false
     end
     frame.lastUpdateUnit = unit
     frame.lastUpdateTime = now
     currentUnit = unit
     frame.currentUnit = unit  -- 保存到框架上，供 tooltip 使用
@@ -438,21 +471,21 @@
         index = index + 1
     end
     
     --设置头像和等级
     local level = UnitLevel(unit)
-    frame.levelText:SetText(level)
+    SetPanelText(frame.levelText, level)
     
     -- 每次都刷新头像（参考 SUCC-bag 的做法）
     if frame.portrait and UnitExists(unit) then
         SetPortraitTexture(frame.portrait, unit)
         frame.portrait:Show()
     end
     
     --设置姓名
     local name = UnitName(unit)
-    frame.nameText:SetText(name)
+    SetPanelText(frame.nameText, name)
     
     --设置职业和颜色
     local localizedClass, class = UnitClass(unit)
     local classColor = RAID_CLASS_COLORS[class]
     if classColor then
@@ -474,11 +507,11 @@
     else
         frame.classIcon:Hide()
     end
     
     --隐藏职业文字（因为有图标了）
-    frame.classText:SetText("")
+    SetPanelText(frame.classText, "")
     
     --更新装备槽位并计算最大宽度
     local maxWidth = 200  -- 最小宽度
     local itemCount = 0
     for i, slotFrame in ipairs(frame.slotFrames) do
@@ -516,30 +549,25 @@
                     end
                 end
                 
                 -- 显示装备等级
                 if itemLevel > 0 then
-                    slotFrame.itemLevel:SetText(itemLevel)
+                    SetPanelText(slotFrame.itemLevel, itemLevel)
                 else
-                    slotFrame.itemLevel:SetText("")
+                    SetPanelText(slotFrame.itemLevel, "")
                 end
                 
                 -- 显示装备名称（不再显示附魔文本，改用图标）
                 if itemName then
                     
 					--if ItemSocre:IsEnglinshName(itemName) then
 					if lib and ItemSocre and ItemSocre:IsEnglinshName(itemName) then
 						-- 传入 itemID 作为第二个参数，提高准确率
 						itemName = ItemSocre:TranslatedItem(itemName, tonumber(itemID))
 					end
-					slotFrame.itemName:SetText(itemName)
-                    -- 先重置宽度以获取实际文本宽度
-                    slotFrame.itemName:SetWidth(0)
-                    local actualNameWidth = slotFrame.itemName:GetWidth()
-                    
-                    -- 设置为实际宽度，让名称完整显示
-                    slotFrame.itemName:SetWidth(actualNameWidth)
+					SetPanelText(slotFrame.itemName, itemName)
+                    local actualNameWidth = ItemNameWidth(slotFrame.itemName)
                     
                     -- 计算这一行的总宽度（宝石和附魔图标会在 InspectGemAndEnchant.lua 中添加）
                     -- 预留附魔图标空间（最多2个图标，每个21像素）
                     local rowWidth = 15 + 32 + 24 + actualNameWidth + 50  -- 50是附魔图标预留空间（增加）
                     if rowWidth > maxWidth then
@@ -550,11 +578,11 @@
                     if itemQuality then
                         local r, g, b = GetItemQualityColor(itemQuality)
                         slotFrame.itemName:SetTextColor(r, g, b)
                     end
                 else
-                    slotFrame.itemName:SetText("")
+                    SetPanelText(slotFrame.itemName, "")
                 end
                 
                 -- 保存品质信息
                 slotFrame.itemID = tonumber(itemID)
                 slotFrame.localizedName = itemName
@@ -569,12 +597,12 @@
                 slotFrame.labelBg:SetBackdropColor(r, g, b, 0.2)
                 slotFrame.labelBg:SetBackdropBorderColor(r, g, b, 0.2)
                 slotFrame.slotName:SetTextColor(r, g, b)
                 slotFrame:SetAlpha(1)
             else
-                slotFrame.itemLevel:SetText("")
-                slotFrame.itemName:SetText("")
+                SetPanelText(slotFrame.itemLevel, "")
+                SetPanelText(slotFrame.itemName, "")
                 slotFrame.itemID = nil
                 slotFrame.localizedName = nil											 
                 slotFrame.itemLink = nil
                 slotFrame.quality = nil
                 -- 重置为默认颜色
@@ -583,12 +611,12 @@
                 slotFrame.slotName:SetTextColor(0, 0.9, 0.9)
                 slotFrame:SetAlpha(0.5)
             end
         else
             -- 没有装备时显示灰色
-            slotFrame.itemLevel:SetText("")
-            slotFrame.itemName:SetText("")
+            SetPanelText(slotFrame.itemLevel, "")
+            SetPanelText(slotFrame.itemName, "")
             slotFrame.itemID = nil
             slotFrame.localizedName = nil
             slotFrame.itemLink = nil
             slotFrame.quality = nil
             -- 设置为灰色
@@ -598,26 +626,32 @@
             slotFrame:SetAlpha(0.5)
         end
     end
     
     -- 调整框体宽度
-    if maxWidth > 200 then
-        frame:SetWidth(maxWidth + 20)
-    else
-        frame:SetWidth(200)
-    end
+    local desiredWidth = maxWidth > 200 and maxWidth + 20 or 200
+    if frame:GetWidth() ~= desiredWidth then frame:SetWidth(desiredWidth) end
     
     --使用 ItemSocre 的计算方法获取总装等
     local avgLevel = 0
     if ItemSocre and ItemSocre.ScanUnit then
         avgLevel = ItemSocre:ScanUnit(unit) or 0
     end
-    frame.ilevelText:SetText(string.format("装等 %.1f", avgLevel))
+    SetPanelText(frame.ilevelText, string.format("装等 %.1f", avgLevel))
+    -- Throttle from completion, even if the first update itself took >80ms.
+    frame.lastUpdateTime = GetTime()
+    if SCRequestPanelLayout then SCRequestPanelLayout() end
+    return true
 end
 
 -- 重新布局 StatCompare 框架（根据装备面板的显示状态）
 function S_ItemTip_RelayoutStatCompare()
+    if SCRelayoutPanels then
+        SCRelayoutPanels()
+        SCRequestPanelLayout()
+        return
+    end
     local settings = S_ItemTip_Settings or { showInspect = true }
     local showInspect = settings.showInspect
 
     local charVisible = CharacterFrame:IsVisible() and PaperDollFrame:IsVisible()
     local inspectVisible = InspectFrame and InspectFrame:IsVisible() and InspectFrame.unit
@@ -701,52 +735,65 @@
 end
 
 -- 在查看他人时显示装备面板（根据设置）
 function S_ItemTip_ShowForInspect(unit)
     if not S_ItemTip_InspectFrame then
-        CreateFrame_Delayed()
+        S_ItemTip_CreateInspectFrame()
     end
     local frame = S_ItemTip_InspectFrame
     if frame then
+        S_ItemTip_ApplyLayoutPolicy(frame)
         local settings = S_ItemTip_Settings or { showInspect = true }
-        -- 如果角色面板已打开，则隐藏装备界面（不显示他人）
-        if CharacterFrame and CharacterFrame:IsVisible() then
-            frame:Hide()
-        elseif settings.showInspect then
-            frame:SetFrameStrata("LOW")
-            frame:ClearAllPoints()
-            frame:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", -35, -5.2)
-            frame:Show()
+        if settings.showInspect then
+            if frame:GetFrameStrata() ~= InspectFrame:GetFrameStrata() then frame:SetFrameStrata(InspectFrame:GetFrameStrata()) end
+            local managed = SCRelayoutPanels and SCGetPanelLayoutMode and SCGetPanelLayoutMode() == "auto"
+            if not managed and (not SCGetPanelLayoutMode or not frame.scFreePosition) then
+                if SCSetPanelPoint then SCSetPanelPoint(frame,"TOPLEFT",InspectFrame,"TOPRIGHT",-35,-5.2)
+                else
+                    frame:ClearAllPoints()
+                    frame:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", -35, -5.2)
+                end
+            end
             S_ItemTip_UpdateFrame(unit)
+            if not frame:IsShown() then frame:Show() end
         else
             frame:Hide()
         end
         S_ItemTip_RelayoutStatCompare()
     end
 end
 
 --当角色面板打开时
 function S_ItemTip_OnCharacterShow()
     if not S_ItemTip_InspectFrame then
-        CreateFrame_Delayed()
+        S_ItemTip_CreateInspectFrame()
     end
 
     local frame = S_ItemTip_InspectFrame
     if frame then
+        S_ItemTip_ApplyLayoutPolicy(frame)
         local settings = S_ItemTip_Settings or { showInspect = true }
 
         -- ★ 新增：如果正在观察别人，先关闭观察界面
         if InspectFrame and InspectFrame:IsVisible() then
             HideUIPanel(InspectFrame)
         end
 
         if settings.showInspect then
-            frame:SetFrameStrata("MEDIUM")
-            frame:ClearAllPoints()
-            frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -35.5, -5)
-            frame:Show()
+            local managed = SCRelayoutPanels and SCGetPanelLayoutMode and SCGetPanelLayoutMode() == "auto"
+            if not managed then
+                if frame:GetFrameStrata() ~= "MEDIUM" then frame:SetFrameStrata("MEDIUM") end
+                if not SCGetPanelLayoutMode or not frame.scFreePosition then
+                    if SCSetPanelPoint then SCSetPanelPoint(frame,"TOPLEFT",CharacterFrame,"TOPRIGHT",-35.5,-5)
+                    else
+                        frame:ClearAllPoints()
+                        frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", -35.5, -5)
+                    end
+                end
+            end
             S_ItemTip_UpdateFrame("player")
+            if not frame:IsShown() then frame:Show() end
         else
             frame:Hide()
         end
         S_ItemTip_RelayoutStatCompare()
     end
@@ -880,11 +927,11 @@
         end
     elseif event == "INSPECT_READY" then
         -- 当查看其他玩家的装备数据准备好时
         if InspectFrame and InspectFrame:IsShown() and InspectFrame.unit then
             if not S_ItemTip_InspectFrame then
-                CreateFrame_Delayed()
+                S_ItemTip_CreateInspectFrame()
             end
             local frame = S_ItemTip_InspectFrame
             if frame then
                 local settings = S_ItemTip_Settings or { showInspect = true }
                 if settings.showInspect then
@@ -907,11 +954,11 @@
         S_ItemTip_ToggleInspect()
         DEFAULT_CHAT_FRAME:AddMessage("S_ItemTip 装备查看已" .. (S_ItemTip_Settings.showInspect and "显示" or "隐藏"))
     elseif msg == "target" then
         if UnitExists("target") and UnitIsPlayer("target") then
             if not S_ItemTip_InspectFrame then
-                CreateFrame_Delayed()
+                S_ItemTip_CreateInspectFrame()
             end
             local frame = S_ItemTip_InspectFrame
             if frame then
                 local settings = S_ItemTip_Settings or { showInspect = true }
                 if settings.showInspect then
@@ -925,11 +972,11 @@
             DEFAULT_CHAT_FRAME:AddMessage("请选择一个玩家目标")
         end
     else
         -- 默认显示自己
         if not S_ItemTip_InspectFrame then
-            CreateFrame_Delayed()
+            S_ItemTip_CreateInspectFrame()
         end
         local frame = S_ItemTip_InspectFrame
         if frame then
             local settings = S_ItemTip_Settings or { showInspect = true }
             if settings.showInspect then
@@ -987,10 +1034,14 @@
 end
 -- ==========================================================
 
 -- ========== 强制修正 StatCompareSelfFrame 位置（解决空白问题） ==========
 local function ForceStatComparePosition()
+    if SCRequestPanelLayout then
+        SCRequestPanelLayout()
+        return
+    end
     if not StatCompareSelfFrame then
         -- 如果框架还未创建，延迟重试
         local timer = 0
         local waitFrame = CreateFrame("Frame")
         waitFrame:SetScript("OnUpdate", function()
```
