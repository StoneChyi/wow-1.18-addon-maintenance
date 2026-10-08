# PallyPower/PallyPower.lua

类型：modified；新增 76 行，删除 25 行。

基线：10-06 团队目标筛选修复前
基线来源：C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\pallypower-targets\original\PallyPower\PallyPower.lua

当前 SHA-256：`f517d0d10b88e8dd89603d3175aa5f5dbe34a7c68a20d06da6c4dd5041c5b25e`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 178 / 1 | 178 / 1 | replace | `PP_Debug（第173行）` |
| 438 / 1 | 438 / 1 | replace | `PallyPowerGrid_Update（第436行）` |
| 448 / 0 | 448 / 1 | insert | `PallyPowerGrid_Update（第436行）` |
| 524 / 1 | 525 / 1 | replace | `PallyPower_UpdateUI（第497行）` |
| 555 / 1 | 556 / 6 | replace | `PallyPower_UpdateUI（第497行）` |
| 583 / 1 | 589 / 1 | replace | `PallyPower_UpdateUI（第497行）` |
| 585 / 1 | 591 / 1 | replace | `PallyPower_UpdateUI（第497行）` |
| 587 / 1 | 593 / 1 | replace | `PallyPower_UpdateUI（第497行）` |
| 710 / 1 | 716 / 1 | replace | `PallyPower_Refresh（第714行）` |
| 727 / 1 | 733 / 1 | replace | `PallyPower_Refresh（第714行）` |
| 729 / 1 | 735 / 1 | replace | `PallyPower_Refresh（第714行）` |
| 745 / 1 | 751 / 1 | replace | `PallyPower_Clear（第740行）` |
| 749 / 1 | 755 / 1 | replace | `PallyPower_Clear（第740行）` |
| 1157 / 1 | 1163 / 1 | replace | `PallyPower_ScanRaid（第1136行）` |
| 1182 / 2 | 1188 / 3 | replace | `PallyPower_ScanRaid（第1136行）` |
| 1202 / 2 | 1209 / 3 | replace | `PallyPower_ScanRaid（第1136行）` |
| 1241 / 0 | 1249 / 40 | insert | `PallyPower_GetBuffTextureID（第1242行）` |
| 1289 / 2 | 1337 / 4 | replace | `PallyPowerBuffButton_OnClick（第1296行）` |
| 1347 / 1 | 1397 / 1 | replace | `PallyPower_CastLesserBlessing（第1362行）` |
| 1767 / 0 | 1817 / 1 | insert | `PallyPower_Options（第1812行）` |
| 1768 / 5 | 1819 / 5 | replace | `PallyPower_ShowFeedback（第1818行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/PallyPower/PallyPower.lua
+++ b/PallyPower/PallyPower.lua
@@ -173,11 +173,11 @@
 local function PP_Debug(string)
     if not string then
         string = "(nil)"
     end
     if (PP_DebugEnabled) then
-        DEFAULT_CHAT_FRAME:AddMessage("[PP] " .. string, 1, 0, 0);
+        -- 聊天通知已关闭；操作结果由界面状态显示。
     end
 end
 
 function PallyPower_OnLoad()
     this:RegisterEvent("SPELLS_CHANGED");
@@ -433,20 +433,21 @@
     return t - GetTime()
 end
 
 function PallyPowerGrid_Update()
     if not initalized then
-        DEFAULT_CHAT_FRAME:AddMessage("[祝福助手] " .. "重新扫描")
+        -- 聊天通知已关闭；操作结果由界面状态显示。
         PallyPower_ScanSpells()
     end
     -- Pally 1 is always myself
     local i = 1;
     local numPallys = 0
     local name, skills
     if PallyPowerFrame:IsVisible() then
         PallyPowerFrame:SetScale(PP_PerUser.scalemain);
         for name, skills in AllPallys do
+            if i > 12 then break end
             local base = "PallyPowerFramePlayer" .. i
             pp_getglobal(base .. "Name"):SetText(name)
             pp_getglobal(base .. "Symbols"):SetText(skills["symbols"])
             pp_getglobal(base .. "Symbols"):SetTextColor(1, 1, 0.5)
             if (PallyPower_CanControl(name)) then
@@ -519,11 +520,11 @@
     local soloActive = PP_Solo_IsActive(false)
 
     --if ((GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) or (IsPally == 0)) then
     --    PallyPowerBuffBar:Hide()
     --else
-    if soloActive then
+    if soloActive and PP_PerUser.alwaysBuffBar ~= 1 then
         PallyPowerBuffBar:Hide()
     elseif ((IsPally == 1) or (GetNumRaidMembers() > 0 and GetNumPartyMembers() > 0)) then
         PallyPowerBuffBar:Show()
         PallyPowerBuffBarTitleText:SetText(format(PallyPower_BuffBarTitle, PP_Symbols));
         BuffNum = 1
@@ -550,11 +551,16 @@
                         for member, stats in CurrentBuffs[class] do
                             if stats["visible"] then
                                 -- stats["name"] 对未取到名字的单位（如宠物）可能为 nil，
                                 -- tinsert(t, nil) 会在表里造出空洞让 concat 报错，回退用 unit token
                                 local uname = stats["name"] or member;
-                                if not stats[assign[class]] then
+                                local desiredBuff = assign[class]
+                                if PallyPower_PersonalBlessing then
+                                    local personal = PallyPower_PersonalBlessing(class,uname)
+                                    if personal ~= nil then desiredBuff = personal end
+                                end
+                                if not stats[desiredBuff] then
                                     if UnitIsDeadOrGhost(member) then
                                         ndead = ndead + 1;
                                         tinsert(btn.dead, uname);
                                     else
                                         nneed = nneed + 1
@@ -578,15 +584,15 @@
                     pp_getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Time"):SetText(PallyPower_FormatTime(PallyPower_LastCastRemaining(assign[class] .. class)));
                     if not (nneed > 0 or nhave > 0) then
                     else
                         BuffNum = BuffNum + 1
                         if (nhave == 0) then
-                            btn:SetBackdropColor(1.0, 0.0, 0.0, 0.5);
+                            PallyPower_SetBuffBarColor(btn,1,0,0);
                         elseif (nneed > 0) then
-                            btn:SetBackdropColor(1.0, 1.0, 0.5, 0.5);
+                            PallyPower_SetBuffBarColor(btn,1,1,0.5);
                         else
-                            btn:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
+                            PallyPower_SetBuffBarColor(btn,0,0,0);
                         end
                         btn:Show();
                     end
                 end
             end
@@ -705,11 +711,11 @@
     PallyPower_ScanInventory()
 end
 
 function PallyPower_Refresh()
 	if ppRefreshAfterClear ~= true then
-		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080    祝福助手|r -- |cffFFFF00刷新中...|r")
+		-- 聊天通知已关闭；操作结果由界面状态显示。
 	end
 
 	--ADDED THESE TO FIX THE REFRESH NOT WORKING
 	PP_Symbols = 0
 	AllPallys = { };
@@ -722,13 +728,13 @@
     PallyPower_RequestSend()
 	PallyPower_ScanSpells()
     PallyPower_UpdateUI()
 	
 	if ppRefreshAfterClear ~= true then
-		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080    祝福助手|r -- |cff00FF00刷新成功!|r")
+		-- 聊天通知已关闭；操作结果由界面状态显示。
 	elseif ppRefreshAfterClear == true then
-		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080    祝福助手|r -- |cff00FF00清理成功!|r")
+		-- 聊天通知已关闭；操作结果由界面状态显示。
 		ppRefreshAfterClear = false
 	end
 end
 
 function PallyPower_Clear(fromupdate, who)
@@ -740,15 +746,15 @@
     end
 	
     for name, skills in PallyPower_Assignments do
         if (PallyPower_CheckRaidLeader(who) or name == who) then
             if name == who then
-				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080    祝福助手|r -- |cffFFFF00清理中...|r")
+				-- 聊天通知已关闭；操作结果由界面状态显示。
 			else
 				if (clearTime + 5) < GetTime() then
 					clearTime = GetTime()
-					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080    祝福助手|r -- |cffFFFF00按照团长要求清理: |r"..who)
+					-- 聊天通知已关闭；操作结果由界面状态显示。
 				end
 			end
 			for class, id in PallyPower_Assignments[name] do
                 PallyPower_Assignments[name][class] = -1
             end
@@ -1152,11 +1158,11 @@
     if (not tests) then
         tests = 1
     end
 
     while PP_Scanners[PP_ScanCursor] do
-        unit = PP_Scanners[PP_ScanCursor]
+        local unit = PP_Scanners[PP_ScanCursor]
         local name = UnitName(unit)
         local class = UnitClass(unit)
         if (name and class) then
             local cid = PallyPower_GetClassID(class)
             PP_Debug("unit " .. unit .. " cid " .. cid .. " class " .. class);
@@ -1177,12 +1183,13 @@
                     PP_ScanInfo[classID][petId] = {};
                     PP_ScanInfo[classID][petId]["name"] = pet_name;
                     PP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId);
 
                     local j = 1
-                    while UnitBuff(petId, j, true) do
-                        local buffIcon, _ = UnitBuff(petId, j, true)
+                    while true do
+                        local buffIcon = UnitBuff(petId, j, true)
+                        if not buffIcon then break end
                         local txtID = PallyPower_GetBuffTextureID(buffIcon)
                         if txtID > 5 then
                             txtID = txtID - 6
                         end
                         PP_ScanInfo[classID][petId][txtID] = true
@@ -1197,12 +1204,13 @@
             PP_ScanInfo[cid][unit] = {};
             PP_ScanInfo[cid][unit]["name"] = name;
             PP_ScanInfo[cid][unit]["visible"] = UnitIsVisible(unit);
 
             local j = 1
-            while UnitBuff(unit, j, true) do
-                local buffIcon, _ = UnitBuff(unit, j, true)
+            while true do
+                local buffIcon = UnitBuff(unit, j, true)
+                if not buffIcon then break end
                 local txtID = PallyPower_GetBuffTextureID(buffIcon)
                 if txtID > 5 then
                     txtID = txtID - 6
                 end
                 PP_ScanInfo[cid][unit][txtID] = true
@@ -1236,10 +1244,50 @@
         if (name == text) then
             return id
         end
     end
     return -2
+end
+
+-- 点击时读取当前队伍名单，不能把周期扫描缓存当作可施法名单。
+-- 新入团、换组或 raid 编号重排后，CurrentBuffs 可能仍是上一次扫描结果。
+local function PP_CurrentClassUnits(classID)
+    local units = {}
+    local function AddMember(unit, pet)
+        if not UnitName(unit) then return end
+        local cid = PallyPower_GetClassID(UnitClass(unit))
+        if cid == classID and not UnitIsDeadOrGhost(unit) then
+            tinsert(units, unit)
+        end
+        if classID == 9 and cid == 5 and UnitName(pet) and not UnitIsDeadOrGhost(pet) then
+            tinsert(units, pet)
+        end
+    end
+    local raidCount = GetNumRaidMembers()
+    if raidCount > 0 then
+        for i = 1, raidCount do AddMember("raid"..i, "raidpet"..i) end
+    else
+        AddMember("player", "pet")
+        for i = 1, GetNumPartyMembers() do AddMember("party"..i, "partypet"..i) end
+    end
+    return units
+end
+
+local function PP_RecentlyCastOn(classID, unit)
+    -- 精确比较 unit token；raid10 不能误匹配 raid1，缺失记录也不能报错。
+    for _, previous in ipairs(LastCastOn[classID] or {}) do
+        if previous == unit then return true end
+    end
+    return false
+end
+
+-- 背景透明度独立于文字、图标；保存状态色供设置滑条即时刷新。
+function PallyPower_SetBuffBarColor(button,r,g,b)
+    button.ppStatusR,button.ppStatusG,button.ppStatusB=r,g,b
+    local alpha=PP_PerUser.barBackgroundAlpha
+    if type(alpha) ~= "number" then alpha=0.5 end
+    button:SetBackdropColor(r,g,b,alpha)
 end
 
 function PallyPowerBuffButton_OnLoad(btn)
     this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
 end
@@ -1284,12 +1332,14 @@
         if PallyPower_LastCastRemaining(btn.buffID .. btn.classID) > (30 * 60) - 30 then
             RecentCast = true
         end
     end
     
-    for unit, stats in (CurrentBuffs[btn.classID] or {}) do
-        if SpellCanTargetUnit(unit) and not (RecentCast and string.find(table.concat(LastCastOn[btn.classID], " "), unit)) then
+    -- 强效祝福按职业施放，点击时允许重新选择可施法成员。
+    -- 30 秒逐人跳过仅适用于 10 分钟小祝福，不能把强效祝福目标锁死。
+    for _, unit in ipairs(PP_CurrentClassUnits(btn.classID)) do
+        if SpellCanTargetUnit(unit) and not (TenMinBlessing == true and RecentCast and PP_RecentlyCastOn(btn.classID, unit)) then
             PP_Debug("Trying to cast on " .. unit);
             SpellTargetUnit(unit)
             PP_NextScan = 1
             if (TenMinBlessing == true) then
                 LastCast[btn.buffID .. btn.classID] = GetTime() + 10 * 60;
@@ -1342,11 +1392,11 @@
         if stats[buffID] then
             hasGreaterBlessing = true
             PP_Debug("Unit "..unit.." already has greater blessing "..buffID..", skipping")
         end
         
-        if not hasGreaterBlessing and SpellCanTargetUnit(unit) and not (RecentCast and string.find(table.concat(LastCastOn[classID], " "), unit)) then
+        if not hasGreaterBlessing and SpellCanTargetUnit(unit) and not (RecentCast and PP_RecentlyCastOn(classID, unit)) then
             PP_Debug("Trying to cast lesser blessing on "..unit);
             SpellTargetUnit(unit)
             PP_NextScan = 1
             if (TenMinBlessing == true) then
                 LastCast[lesserId .. classID] = GetTime() + 10 * 60;
@@ -1762,16 +1812,17 @@
 function PallyPower_Options()
     PallyPowerFrame:Hide()
     PallyPower_OptionsFrame:Show()
 end
 
+local ppLastFeedback, ppLastFeedbackAt
 function PallyPower_ShowFeedback(msg, r, g, b, a)
-    if PP_PerUser.chatfeedback then
-        DEFAULT_CHAT_FRAME:AddMessage("[PallyPower] " .. msg, r, g, b, a)
-    else
-        UIErrorsFrame:AddMessage(msg, r, g, b, a)
-    end
+    if PP_PerUser.screenfeedback == 0 then return end
+    local now = GetTime()
+    if msg == ppLastFeedback and now - (ppLastFeedbackAt or 0) < 1 then return end
+    ppLastFeedback, ppLastFeedbackAt = msg, now
+    UIErrorsFrame:AddMessage(msg, r, g, b, a)
 end
 
 function PallyPowerGridButton_OnMouseWheel(btn, arg1)
     _, _, pnum, class = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)");
     pnum = pnum + 0;
```
