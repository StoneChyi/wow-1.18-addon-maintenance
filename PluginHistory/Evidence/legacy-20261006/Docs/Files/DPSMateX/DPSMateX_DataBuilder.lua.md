# DPSMateX/DPSMateX_DataBuilder.lua

类型：modified；新增 29 行，删除 1 行。

基线：10-06 Insights 接入前
基线来源：E:\1.18\addons_tmp\dpsmatex-insights-backup-20261006\DPSMateX_DataBuilder.lua

当前 SHA-256：`29d238cecdefb58b1a532546def6a2dd706e350fa99efe71b32b5e56f72c37b0`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 231 / 0 | 231 / 2 | insert | `DPSMateX.DB.PLAYER_REGEN_DISABLED（第216行）` |
| 920 / 0 | 922 / 2 | insert | `DPSMateX.DB:DamageDone（第911行）` |
| 2298 / 0 | 2302 / 1 | insert | `DPSMateX.DB:OnUpdate（第2300行）` |
| 2329 / 0 | 2334 / 2 | insert | `DPSMateX.DB:OnUpdate（第2300行）` |
| 2541 / 1 | 2548 / 22 | replace | `DPSMateX.DB:RemoveShieldAsHeal（第2541行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/DPSMateX/DPSMateX_DataBuilder.lua
+++ b/DPSMateX/DPSMateX_DataBuilder.lua
@@ -226,10 +226,12 @@
 	DPSMateX.Options:HideWhenSolo()
 	if (not CombatState and cheatCombat<GT()) then
 		DPSMateX.Options:NewSegment()
 	end
 	CombatState = true
+	if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
+		if DPSMateX.Encounters then DPSMateX.Encounters:Start() end
 end
 
 DPSMateX.DB.PLAYER_REGEN_ENABLED = function()
 	if DPSMateX.Settings["hideincombat"] then
 		for _, val in pairs(DPSMateX.Settings["windows"]) do
@@ -915,10 +917,12 @@
 	Duser, DuserName = self:BuildUser(Duser)
 
 	if (not CombatState and cheatCombat<GT()) then
 		DPSMateX.Options:NewSegment()
 		CombatState = true
+		if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
+		if DPSMateX.Encounters then DPSMateX.Encounters:Start() end
 	else
 		--if victim and UnitClassification(victim) == "worldboss" then
 			--try make boss fight
 		--end
 	end
@@ -2293,10 +2297,11 @@
 	return org_collectgarbage();
 end
 
 function DPSMateX.DB:OnUpdate()
 	local arg1 = arg1
+	if DPSMateX.Encounters then DPSMateX.Encounters:OnUpdate(arg1) end
 
 	if (CombatState) then
 		notInCombat = false
 		LastUpdate = LastUpdate + arg1
 		if LastUpdate>=UpdateTime then
@@ -2324,10 +2329,12 @@
 			end
 		end
 
 		if notInCombat then
 			CombatState = false
+			if DPSMateX.Insights then DPSMateX.Insights:EndCombat() end
+			if DPSMateX.Encounters then DPSMateX.Encounters:End() end
 
 			if DPSMateX.Settings.collectgarbage then
 				local curmem = gcinfo()
 				meminfo = meminfo or curmem
 				gc_time = gc_time or 0
@@ -2536,11 +2543,32 @@
 	if sc and sc[effect] then
 		sc[effect] = nil
 	end
 end
 
-DPSMateX.DB:SetScript("OnEvent", function() this[event](arg1) end)
+DPSMateX.DB:SetScript("OnEvent", function()
+	-- Copy event arguments before legacy handlers can invoke other frame scripts.
+	local extension, ev, receiver = DPSMateX.Insights, event, this
+	local a1,a2,a3,a4,a5,a6,a7,a8,a9 = arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
+	if extension then extension:PrepareEvent(ev,a1,a2,a3,a4) end
+	if DPSMateX.Encounters then DPSMateX.Encounters:PrepareEvent(ev,a1,a2,a3,a4) end
+	receiver[ev](a1)
+	if extension then extension:OnEvent(ev, a1,a2,a3,a4,a5,a6,a7,a8,a9) end
+end)
+
+function DPSMateX.DB:IsCombatActive()
+	return CombatState
+end
+
+function DPSMateX.DB:BeginInsightsCombat()
+	if not CombatState then
+		DPSMateX.Options:NewSegment()
+		CombatState = true
+		if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
+		if DPSMateX.Encounters then DPSMateX.Encounters:Start() end
+	end
+end
 DPSMateX.DB:SetScript("OnUpdate", function() this:OnUpdate() end)
 
 DPSMateX.DB.trackedSpells = {
 	[9907] = "Faerie Fire",
 	[17392] = "Faerie Fire (Feral)",
```
