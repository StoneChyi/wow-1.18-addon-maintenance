# DPSMateX/DPSMateX_Options.lua

类型：modified；新增 14 行，删除 4 行。

基线：10-06 Insights 接入前（已包含较早的锁窗修复）
基线来源：E:\1.18\addons_tmp\dpsmatex-insights-backup-20261006\DPSMateX_Options.lua

当前 SHA-256：`d16f534946ed30abcb72e5de9409014101ff03c1f88e8fc92f02c4462925d46d`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 1506 / 1 | 1506 / 1 | replace | `DPSMateX.Options:ReportUserDetails（第1448行）` |
| 1664 / 1 | 1664 / 5 | replace | `DPSMateX.Options:NewSegment（第1639行）` |
| 1701 / 1 | 1705 / 3 | replace | `DPSMateX.Options:CreateSegment（第1686行）` |
| 1740 / 0 | 1746 / 1 | insert | `set（第1743行）` |
| 1782 / 0 | 1789 / 2 | insert | `DPSMateX.Options:ToggleSegment（第1788行）` |
| 1790 / 1 | 1799 / 1 | replace | `DPSMateX.Options:ToggleSegment（第1788行）` |
| 2002 / 0 | 2011 / 1 | insert | `DPSMateX.Options:RemoveSegment（第2010行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateX/DPSMateX_Options.lua
+++ b/DPSMateX/DPSMateX_Options.lua
@@ -1501,11 +1501,11 @@
 					tinsert(DPSMateX.DelayMsg, {i..". "..DPSMateX.Modules.Fails:Type(ablity).." - "..p, chn, index})
 				else
 					SendChatMessage(i..". "..DPSMateX.Modules.Fails:Type(ablity).." - "..p, chn, nil, index)
 				end
 			else
-				if DPSMateX:TContains(AbilityModes, DPSMateX.Settings["windows"][Key]["CurMode"]) then
+				if DPSMateX:TContains(AbilityModes, DPSMateX.Settings["windows"][Key]["CurMode"]) or DPSMateX.RegistredModules[DPSMateX.Settings["windows"][Key]["CurMode"]].Insights then
 					if DPSMateX.Settings["reportdelay"] then
 						tinsert(DPSMateX.DelayMsg, {i..". "..DPSMateX:GetAbilityById(ablity).." - "..p, chn, index})
 					else
 						SendChatMessage(i..". "..DPSMateX:GetAbilityById(ablity).." - "..p, chn, nil, index)
 					end
@@ -1659,11 +1659,15 @@
 			name = DPSMateX:GetUserById(a)
 			name = name or DPSMateX.L["unknown"]
 			extra = " - CBT: "..self:FormatTime(DPSMateX.CombatTime["current"])
 		end
 		if name ~= DPSMateX.L["unknown"] or (name == DPSMateX.L["unknown"]) then
-			local bossname = DPSMateX.BabbleBoss:Contains(name)
+			local encounter=DPSMateX.Encounters
+			local fight=encounter and encounter.ready and encounter.db.current
+			local classifiedBoss=fight and fight.kind=="boss"
+			if classifiedBoss and fight.name and not segname then name=fight.name end
+			local bossname = classifiedBoss or DPSMateX.BabbleBoss:Contains(name)
 			if bossname and type(bossname) == "string" then name = bossname end
 
 			if DPSMateX.Settings["onlybossfights"] then
 				if bossname then
 					DPSMateX.Options:CreateSegment(name..extra)
@@ -1696,11 +1700,13 @@
 		["Interrupts"] = DPSMateX.DBCache.Interrupts[2],
 		["Dispels"] = DPSMateX.DBCache.Dispels[2],
 		["Auras"] = DPSMateX.DBCache.AurasGained[2],
 	}
 	
-	tinsert(DPSMateX.DPSMateXHistory["names"], 1, name.." - "..GameTime_GetTime())
+	local segmentLabel = name.." - "..GameTime_GetTime()
+	if DPSMateX.Insights then DPSMateX.Insights:SaveSegment(segmentLabel) end
+	tinsert(DPSMateX.DPSMateXHistory["names"], 1, segmentLabel)
 	for cat, val in pairs(modes) do
 		tinsert(DPSMateX.DPSMateXHistory[cat], 1, DPSMateX:CopyTable(val))
 		if DPSMateX:TableLength(DPSMateX.DPSMateXHistory[cat])>DPSMateX.Settings["datasegments"] then
 			for i=DPSMateX.Settings["datasegments"]+1, DPSMateX:TableLength(DPSMateX.DPSMateXHistory[cat]) do
 				tremove(DPSMateX.DPSMateXHistory[cat], i)
@@ -1735,10 +1741,11 @@
 			desc = DPSMateX.L["currentmode"],
 			get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["currentfight"] end,
 			set = function() DPSMateX.Options:ToggleDrewDrop(2, "currentfight", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
 		},
 	}
+	if DPSMateX.Encounters and DPSMateX.Encounters.ready then DPSMateX.Encounters:InstallMenus() end
 	DPSMateX.Options.Options[3]["args"]["deletesegment"]["args"] = {}
 	for cat, val in pairs(DPSMateX.DPSMateXHistory["DMGDone"]) do
 		if not val then break end
 		DPSMateX.Options.Options[2]["args"]["segment"..i] = {
 			order = 20+i*10,
@@ -1777,19 +1784,21 @@
 		 end
 	end
 end
 
 function DPSMateX.Options:ToggleSegment(k, obj)
+	if DPSMateX.Encounters then obj=DPSMateX.Encounters:ValidateScope(k,obj)
+	elseif obj=="bossall" or obj=="trashall" then obj="currentfight" end
 	for cat, _ in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
 		DPSMateX.Settings["windows"][k]["options"][2][cat] = false
 	end
 	DPSMateX.Settings["windows"][k]["options"][2][obj] = true
 
 	local module = DPSMateX.RegistredModules[DPSMateX.Settings["windows"][k]["CurMode"]]
 	if module then 
 		module.acceptNewValues = module.acceptNewValues or {}
-		module.acceptNewValues[k] = (obj == "total" or obj == "currentfight")
+		module.acceptNewValues[k] = (obj == "total" or obj == "currentfight" or obj == "bossall" or obj == "trashall")
 	end
 end
 
 function DPSMateX.Options:OnVerticalScroll(obj, arg1, pre, spec)
 	pre = pre or 20
@@ -1997,10 +2006,11 @@
 	DPSMateX.Settings["windows"][frame.Key]["hidden"] = false
 	frame:Show()
 end
 
 function DPSMateX.Options:RemoveSegment(i)
+	if DPSMateX.Insights then DPSMateX.Insights:RemoveSegment(i) end
 	for cat, val in DPSMateX.DPSMateXHistory do
 		tremove(DPSMateX.DPSMateXHistory[cat], i)
 	end
 	DPSMateX.Options:InitializeSegments()
 	DPSMateX.Options.Dewdrop:Close()
```
