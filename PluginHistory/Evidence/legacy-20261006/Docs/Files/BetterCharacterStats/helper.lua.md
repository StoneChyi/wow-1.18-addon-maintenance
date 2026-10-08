# BetterCharacterStats/helper.lua

类型：modified；新增 245 行，删除 161 行。

基线：10-06 BCS 同次刷新扫描复用前
基线来源：E:\1.18\addons_tmp\character-bcs-scan-backup-20261006\BetterCharacterStats_helper.lua.original

当前 SHA-256：`563a76bb39840da6f0b4896daec056e703b8882a152c2d8133cc4a7c9d99d83d`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 7 / 0 | 7 / 53 | insert | `文件顶部 / 表定义` |
| 99 / 0 | 152 / 31 | insert | `BCS:GetPlayerAura（第151行）` |
| 183 / 1 | 267 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 186 / 1 | 270 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 190 / 3 | 274 / 3 | replace | `BCS:GetLiveHitRating（第260行）` |
| 196 / 1 | 280 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 201 / 1 | 285 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 206 / 1 | 290 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 211 / 1 | 295 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 215 / 1 | 299 / 1 | replace | `BCS:GetLiveHitRating（第260行）` |
| 414 / 1 | 498 / 1 | replace | `BCS:GetLiveRangedHitRating（第493行）` |
| 416 / 1 | 500 / 1 | replace | `BCS:GetLiveRangedHitRating（第493行）` |
| 418 / 3 | 502 / 3 | replace | `BCS:GetLiveRangedHitRating（第493行）` |
| 475 / 1 | 559 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 479 / 1 | 563 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 482 / 1 | 566 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 484 / 2 | 568 / 2 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 489 / 1 | 573 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 494 / 1 | 578 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 499 / 1 | 583 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 504 / 1 | 588 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 508 / 1 | 592 / 1 | replace | `BCS:GetLiveSpellHitRating（第547行）` |
| 693 / 1 | 777 / 1 | replace | `BCS:GetLiveRangedCritChance（第771行）` |
| 695 / 4 | 779 / 4 | replace | `BCS:GetLiveRangedCritChance（第771行）` |
| 775 / 1 | 859 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 780 / 2 | 864 / 2 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 783 / 2 | 867 / 2 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 789 / 1 | 873 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 794 / 1 | 878 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 799 / 1 | 883 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 804 / 1 | 888 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 809 / 1 | 893 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 816 / 1 | 900 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 821 / 1 | 905 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 826 / 1 | 910 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 831 / 1 | 915 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 837 / 1 | 921 / 1 | replace | `BCS:GetLiveSpellCritChance（第833行）` |
| 1072 / 1 | 1156 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1075 / 4 | 1159 / 4 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1083 / 1 | 1167 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1088 / 1 | 1172 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1093 / 1 | 1177 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1099 / 1 | 1183 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1105 / 1 | 1189 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1111 / 1 | 1195 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1116 / 1 | 1200 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1120 / 1 | 1204 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1124 / 1 | 1208 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1128 / 1 | 1212 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1133 / 1 | 1217 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1137 / 1 | 1221 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1141 / 1 | 1225 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1147 / 1 | 1231 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1151 / 1 | 1235 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1155 / 1 | 1239 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1159 / 1 | 1243 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1164 / 1 | 1248 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1168 / 1 | 1252 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1172 / 1 | 1256 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1177 / 1 | 1261 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1181 / 1 | 1265 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1185 / 1 | 1269 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1189 / 1 | 1273 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1194 / 1 | 1278 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1198 / 1 | 1282 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1203 / 1 | 1287 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1207 / 1 | 1291 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1211 / 1 | 1295 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1217 / 1 | 1301 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1221 / 1 | 1305 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1225 / 1 | 1309 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1229 / 1 | 1313 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1233 / 1 | 1317 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1238 / 1 | 1322 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1243 / 1 | 1327 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1249 / 1 | 1333 / 1 | replace | `BCS:GetLiveSpellPower（第1142行）` |
| 1462 / 1 | 1546 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1467 / 2 | 1551 / 2 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1470 / 2 | 1554 / 2 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1475 / 1 | 1559 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1479 / 1 | 1563 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1483 / 1 | 1567 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1488 / 1 | 1572 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1493 / 1 | 1577 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1498 / 1 | 1582 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1503 / 1 | 1587 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1508 / 1 | 1592 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1513 / 1 | 1597 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1519 / 1 | 1603 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1524 / 1 | 1608 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1529 / 1 | 1613 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1533 / 1 | 1617 / 1 | replace | `BCS:GetLiveHealingPower（第1540行）` |
| 1717 / 1 | 1801 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1723 / 2 | 1807 / 2 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1726 / 2 | 1810 / 2 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1731 / 1 | 1815 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1735 / 1 | 1819 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1739 / 1 | 1823 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1743 / 1 | 1827 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1749 / 1 | 1833 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1753 / 1 | 1837 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1757 / 1 | 1841 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1763 / 1 | 1847 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1767 / 1 | 1851 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1773 / 1 | 1857 / 1 | replace | `BCS:GetLiveManaRegen（第1780行）` |
| 1968 / 1 | 2052 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1971 / 2 | 2055 / 2 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1974 / 1 | 2058 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1976 / 1 | 2060 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1981 / 1 | 2065 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1986 / 1 | 2070 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1991 / 1 | 2075 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 1997 / 1 | 2081 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 2002 / 1 | 2086 / 1 | replace | `BCS:GetLiveHaste（第2046行）` |
| 2084 / 1 | 2168 / 1 | replace | `BCS:GetOriWeaponSpeed（第2163行）` |
| 2086 / 4 | 2170 / 4 | replace | `BCS:GetOriWeaponSpeed（第2163行）` |
| 2141 / 1 | 2225 / 1 | replace | `BCS:GetLiveOnlyGearArmor（第2221行）` |
| 2144 / 4 | 2228 / 4 | replace | `BCS:GetLiveOnlyGearArmor（第2221行）` |
| 2152 / 1 | 2236 / 1 | replace | `BCS:GetLiveOnlyGearArmor（第2221行）` |
| 2156 / 1 | 2240 / 1 | replace | `BCS:GetLiveOnlyGearArmor（第2221行）` |
| 2227 / 1 | 2311 / 1 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2230 / 4 | 2314 / 4 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2237 / 1 | 2321 / 1 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2243 / 1 | 2327 / 1 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2247 / 1 | 2331 / 1 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2252 / 1 | 2336 / 1 | replace | `BCS:GetLiveBlockValue（第2285行）` |
| 2341 / 1 | 2425 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2344 / 4 | 2428 / 4 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2351 / 1 | 2435 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2356 / 1 | 2440 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2363 / 1 | 2447 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2367 / 1 | 2451 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |
| 2372 / 1 | 2456 / 1 | replace | `BCS:GetLiveArmorPenetrationValue（第2414行）` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- a/BetterCharacterStats/helper.lua
+++ b/BetterCharacterStats/helper.lua
@@ -2,10 +2,63 @@
 
 
 local BCS_Tooltip = getglobal("BetterCharacterStatsTooltip") or CreateFrame("GameTooltip", "BetterCharacterStatsTooltip", nil, "GameTooltipTemplate")
 local BCS_Prefix = "BetterCharacterStatsTooltip"
 BCS_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
+
+-- Share immutable equipment/aura text only within one UpdateStats call.
+-- Neither cache survives the update; standalone consumers retain live reads.
+local equipmentReadDepth = 0
+local equipmentReadCache
+local auraReadCache
+-- Standalone consumers retain native tooltip reads without allocating a
+-- snapshot for every slot. The live view never stores item text.
+local liveEquipment = {
+    left=setmetatable({}, {__index=function(_, line)
+        local font = getglobal(BCS_Prefix .. "TextLeft" .. line)
+        return font and font:GetText()
+    end}),
+    right=setmetatable({}, {__index=function(_, line)
+        local font = getglobal(BCS_Prefix .. "TextRight" .. line)
+        return font and font:GetText()
+    end})
+}
+function BCS:BeginEquipmentRead()
+    if equipmentReadDepth == 0 then equipmentReadCache = {}; auraReadCache = {} end
+    equipmentReadDepth = equipmentReadDepth + 1
+end
+function BCS:EndEquipmentRead()
+    equipmentReadDepth = equipmentReadDepth - 1
+    if equipmentReadDepth <= 0 then
+        equipmentReadDepth = 0
+        equipmentReadCache = nil
+        auraReadCache = nil
+    end
+end
+local function ReadEquipmentTooltip(slot)
+    if equipmentReadCache and equipmentReadCache[slot] then
+        local cached = equipmentReadCache[slot]
+        return cached.hasItem, cached
+    end
+    local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+    if not equipmentReadCache then
+        liveEquipment.count = hasItem and BCS_Tooltip:NumLines() or 0
+        return hasItem, liveEquipment
+    end
+    local snapshot = {hasItem=hasItem, count=0, left={}, right={}}
+    if hasItem then
+        snapshot.count = BCS_Tooltip:NumLines()
+        for line=1, snapshot.count do
+            local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+            local right = getglobal(BCS_Prefix .. "TextRight" .. line)
+            snapshot.left[line] = left and left:GetText()
+            snapshot.right[line] = right and right:GetText()
+        end
+    end
+    if equipmentReadCache then equipmentReadCache[slot] = snapshot end
+    return hasItem, snapshot
+end
 
 local L = BCS["L"]
 local L_RACE = BCS["L_RACE"]
 local L_TALENT = BCS["L_TALENT"]
 local L_HASTE = BCS["L_HASTE"]
@@ -94,10 +147,41 @@
 	end
 	return nil
 end
 
 function BCS:GetPlayerAura(searchText, auraType)
+	-- The same active buffs are otherwise rebuilt once for every searched
+	-- pattern. Capture their text once, preserving buff/line search order.
+	if auraReadCache and (not auraType or auraType == 'HARMFUL') then
+		local kind = auraType or 'HELPFUL'
+		local auras = auraReadCache[kind]
+		if not auras then
+			auras = {}
+			for i=0, kind == 'HELPFUL' and 31 or 6 do
+				local index = GetPlayerBuff(i, kind)
+				if index > -1 then
+					BCS_Tooltip:SetPlayerBuff(index)
+					local lines = {count=BCS_Tooltip:NumLines()}
+					for line=1, lines.count do
+						local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+						lines[line] = left and left:GetText()
+					end
+					tinsert(auras, lines)
+				end
+			end
+			auraReadCache[kind] = auras
+		end
+		for _, lines in ipairs(auras) do
+			for line=1, lines.count do
+				if lines[line] then
+					local value = {strfind(lines[line], searchText)}
+					if value[1] then return unpack(value) end
+				end
+			end
+		end
+		return
+	end
 	if not auraType then
 		-- buffs
 		-- http://blue.cardplace.com/cache/wow-dungeons/624230.htm
 		-- 32 buffs max
 		for i=0, 31 do
@@ -178,43 +262,43 @@
 	local hit = 0
 	local MAX_INVENTORY_SLOTS = 19
 	hit_debuff = 0
 	
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 
-			local MAX_LINES = BCS_Tooltip:NumLines()
+			local MAX_LINES = equipment.count
 			local SET_NAME = nil
 			
 			for line=1, MAX_LINES do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L["Equip: Improves your chance to hit by (%d)%%."])
+				local left = equipment.left[line]
+				if left then
+					local _,_, value = strfind(left, L["Equip: Improves your chance to hit by (%d)%%."])
 					if value then
 						hit = hit + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L["/Hit %+(%d+)"])
+					_,_, value = strfind(left, L["/Hit %+(%d+)"])
 					if value then
 						hit = hit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_HIT["Rune_of_the_Guard_Captain"])
+					_,_, value = strfind(left, L_HIT["Rune_of_the_Guard_Captain"])
 					if value then
 						hit = hit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_HIT["Signet_of_Howling_Nightmares"])
+					_,_, value = strfind(left, L_HIT["Signet_of_Howling_Nightmares"])
 					if value then
 						hit = hit - tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_,_, value = strfind(left:GetText(), L["^Set: Improves your chance to hit by (%d)%%."])
+					_,_, value = strfind(left, L["^Set: Improves your chance to hit by (%d)%%."])
 					if value and SET_NAME and not tContains(Hit_Set_Bonus, SET_NAME) then
 						tinsert(Hit_Set_Bonus, SET_NAME)
 						hit = hit + tonumber(value)
 						line = MAX_LINES
 					end
@@ -409,17 +493,17 @@
 function BCS:GetLiveRangedHitRating()
 	local melee_hit = BCS:GetHitRating(true)
 	local ranged_hit = melee_hit
 	local debuff = hit_debuff
 
-	local hasItem = BCS_Tooltip:SetInventoryItem("player", 18) -- ranged enchant
+	local hasItem, equipment = ReadEquipmentTooltip(18) -- ranged enchant
 	if hasItem then
-		local MAX_LINES = BCS_Tooltip:NumLines()
+		local MAX_LINES = equipment.count
 		for line=1, MAX_LINES do
-			local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-			if left:GetText() then
-				local _,_, value = strfind(left:GetText(), L["+(%d)%% Hit"])
+			local left = equipment.left[line]
+			if left then
+				local _,_, value = strfind(left, L["+(%d)%% Hit"])
 				if value then
 					ranged_hit = ranged_hit + tonumber(value)
 					line = MAX_LINES
 				end
 			end
@@ -470,44 +554,44 @@
 	local hit_Set_Bonus = {}
 	
 	-- scan gear
 	local MAX_INVENTORY_SLOTS = 19
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		
 		if hasItem then
 			local SET_NAME
-			local MAX_LINES = BCS_Tooltip:NumLines()
+			local MAX_LINES = equipment.count
 			
 			for line=1, MAX_LINES do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+				local left = equipment.left[line]
 				
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_SPELLHIT["Equip: Improves your chance to hit with spells by (%d)%%."])
+				if left then
+					local _,_, value = strfind(left, L_SPELLHIT["Equip: Improves your chance to hit with spells by (%d)%%."])
 					if value then
 						hit = hit + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLHIT["/Spell Hit %+(%d+)"])
+					_,_, value = strfind(left, L_SPELLHIT["/Spell Hit %+(%d+)"])
 					if value then
 						hit = hit + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_SPELLHIT["Scythe_of_Elune"])
+					_,_, value = strfind(left, L_SPELLHIT["Scythe_of_Elune"])
 					if value then
 						hit = hit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_SPELLHIT["Rune_of_the_Guard_Captain"])
+					_,_, value = strfind(left, L_SPELLHIT["Rune_of_the_Guard_Captain"])
 					if value then
 						hit = hit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_SPELLHIT["^Set: Improves your chance to hit with spells by (%d)%%."])
+					_, _, value = strfind(left, L_SPELLHIT["^Set: Improves your chance to hit with spells by (%d)%%."])
 					if value and SET_NAME and not tContains(hit_Set_Bonus, SET_NAME) then
 						tinsert(hit_Set_Bonus, SET_NAME)
 						hit = hit + tonumber(value)
 					end
 				end
@@ -688,16 +772,16 @@
 	local crit = BCS:GetCritChance()
 	
 	local MAX_INVENTORY_SLOTS = 19
 	for slot=0, MAX_INVENTORY_SLOTS do
 		if slot == 18 then  --远程武器处理专用
-			local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+			local hasItem, equipment = ReadEquipmentTooltip(slot)
 			if hasItem then
-				for line=1, BCS_Tooltip:NumLines() do
-					local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-					if left and left:GetText() then
-						local _,_, value = strfind(left:GetText(), L_RANGECRIT["RANGECRIT_1"])
+				for line=1, equipment.count do
+					local left = equipment.left[line]
+					if left then
+						local _,_, value = strfind(left, L_RANGECRIT["RANGECRIT_1"])
 						if value then
 							crit = crit + tonumber(value)
 						end
 					end
 				end
@@ -770,73 +854,73 @@
 	end
 	
 	local MAX_INVENTORY_SLOTS = 19
 	
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		
 		if hasItem then
 			local SET_NAME = nil
 			
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_SPELLCRIT["Equip: Improves your chance to get a critical strike with spells by (%d)%%."])
+			for line=1, equipment.count do
+				local left = equipment.left[line]
+
+				if left then
+					local _,_, value = strfind(left, L_SPELLCRIT["Equip: Improves your chance to get a critical strike with spells by (%d)%%."])
 					if value then
 						spellCrit = spellCrit + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_SPELLCRIT["Eye of Diminution"])
+					_,_, value = strfind(left, L_SPELLCRIT["Eye of Diminution"])
 					if value then
 						spellCrit = spellCrit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_SPELLCRIT["Brilliant_Wizard_Oil"])
+					_,_, value = strfind(left, L_SPELLCRIT["Brilliant_Wizard_Oil"])
 					if value then
 						spellCrit = spellCrit + 1
 					end
 
-					_,_,_, value = strfind(left:GetText(), L_SPELLCRIT["Power of the Scourge"])
+					_,_,_, value = strfind(left, L_SPELLCRIT["Power of the Scourge"])
 					if value then
 						spellCrit = spellCrit + tonumber(value)
 					end
 
-					_,_,_, value = strfind(left:GetText(), L_SPELLCRIT["Scythe_of_Elune"])
+					_,_,_, value = strfind(left, L_SPELLCRIT["Scythe_of_Elune"])
 					if value then
 						spellCrit = spellCrit + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_SPELLCRIT["Mantle_of_the_Horusath"])
+					_,_, value = strfind(left, L_SPELLCRIT["Mantle_of_the_Horusath"])
 					if value then
 						spellCrit = spellCrit + tonumber(value)
 					end
 					
 					
 
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
 
-					_, _, value = strfind(left:GetText(), L_SPELLCRIT["^Set: Improves your chance to get a critical strike with spells by (%d)%%."])
+					_, _, value = strfind(left, L_SPELLCRIT["^Set: Improves your chance to get a critical strike with spells by (%d)%%."])
 					if value and SET_NAME and not tContains(Crit_Set_Bonus, SET_NAME) then
 						tinsert(Crit_Set_Bonus, SET_NAME)
 						spellCrit = spellCrit + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLCRIT["nature_spell_crit_set_1"])
+					_,_, value = strfind(left, L_SPELLCRIT["nature_spell_crit_set_1"])
 					if value and SET_NAME and not tContains(Crit_Set_Bonus, SET_NAME) then
 						tinsert(Crit_Set_Bonus, SET_NAME)
 						spellCritBySchool[L.SPELL_SCHOOL_NATURE] = spellCritBySchool[L.SPELL_SCHOOL_NATURE] or 0 + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLCRIT["holy_spell_crit_set_1"])
+					_,_, value = strfind(left, L_SPELLCRIT["holy_spell_crit_set_1"])
 					if value and SET_NAME and not tContains(Crit_Set_Bonus, SET_NAME) then
 						tinsert(Crit_Set_Bonus, SET_NAME)
 						spellCritBySchool[L.SPELL_SCHOOL_HOLY] = spellCritBySchool[L.SPELL_SCHOOL_HOLY] or 0 + tonumber(value)
 					end
 					if class == "SHAMAN" then
-						_,_, value = strfind(left:GetText(), L_SPELLCRIT["shock_spell_crit_set_1"])
+						_,_, value = strfind(left, L_SPELLCRIT["shock_spell_crit_set_1"])
 						if value and SET_NAME and not tContains(Crit_Set_Bonus, SET_NAME) then
 							tinsert(Crit_Set_Bonus, SET_NAME)
 							spellCritBySchool[L.SPELL_SCHOOL_SHOCK] = spellCritBySchool[L.SPELL_SCHOOL_SHOCK] or 0 + tonumber(value)
 						end
 					end
@@ -1067,188 +1151,188 @@
 	local MAX_INVENTORY_SLOTS = 19
 	local SpellPower_Set_Bonus = {}
 		
 	-- scan gear
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 			local SET_NAME
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_SPELLPOWER["Equip: Increases damage and healing done by magical spells and effects by up to (%d+)."])
+			for line=1, equipment.count do
+				local left = equipment.left[line]
+				if left then
+					local _,_, value = strfind(left, L_SPELLPOWER["Equip: Increases damage and healing done by magical spells and effects by up to (%d+)."])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["jewel_5_spell_power"])
+					_,_, value = strfind(left, L_SPELLPOWER["jewel_5_spell_power"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["Desecration"])
+					_,_, value = strfind(left, L_SPELLPOWER["Desecration"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
 														
-					_,_, value,_ = strfind(left:GetText(), L_SPELLPOWER["Atiesh, Greatstaff of the Guardian_Druid"])
+					_,_, value,_ = strfind(left, L_SPELLPOWER["Atiesh, Greatstaff of the Guardian_Druid"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 						damagePower = damagePower + tonumber(value)
 					end
 
-					_,_, value,_ = strfind(left:GetText(), L_SPELLPOWER["Atiesh, Greatstaff of the Guardian_Priest"])
+					_,_, value,_ = strfind(left, L_SPELLPOWER["Atiesh, Greatstaff of the Guardian_Priest"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 						damagePower = damagePower + tonumber(value)
 					end
 
-					_,_,_,_, value = strfind(left:GetText(), L_SPELLPOWER["Scythe_of_Elune"])
+					_,_,_,_, value = strfind(left, L_SPELLPOWER["Scythe_of_Elune"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 						damagePower = damagePower + tonumber(value)
 					end
 
-					_,_, value,_ = strfind(left:GetText(), L_SPELLPOWER["Power of the Scourge"])
+					_,_, value,_ = strfind(left, L_SPELLPOWER["Power of the Scourge"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
 						
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["Spell Damage %+(%d+)"])
+					_,_, value = strfind(left, L_SPELLPOWER["Spell Damage %+(%d+)"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["^%+(%d+) Spell Damage and Healing"])
+					_,_, value = strfind(left, L_SPELLPOWER["^%+(%d+) Spell Damage and Healing"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["^%+(%d+) Damage and Healing Spells"])
+					_,_, value = strfind(left, L_SPELLPOWER["^%+(%d+) Damage and Healing Spells"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["fm_12_spell_damage"])
+					_,_, value = strfind(left, L_SPELLPOWER["fm_12_spell_damage"])
 					if value then
 						spellPower = spellPower + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["Minor_Wizard_Oil"])
+					_,_, value = strfind(left, L_SPELLPOWER["Minor_Wizard_Oil"])
 					if value then
 						spellPower = spellPower + 8
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["Wizard_Oil"])
+					_,_, value = strfind(left, L_SPELLPOWER["Wizard_Oil"])
 					if value then
 						spellPower = spellPower + 24
 					end
-					_,_, value = strfind(left:GetText(), L_SPELLPOWER["Brilliant_Wizard_Oil"])
+					_,_, value = strfind(left, L_SPELLPOWER["Brilliant_Wizard_Oil"])
 					if value then
 						spellPower = spellPower + 36
 					end
 					
 						
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Arcane spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Arcane spells and effects by up to (%d+)."])
 					if value then
 						arcanePower = arcanePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Arcane Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Arcane Spell Damage"])
 					if value then
 						arcanePower = arcanePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Netherwind Epaulets"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Netherwind Epaulets"])
 					if value then
 						arcanePower = arcanePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["glove_20_arcane_power"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["glove_20_arcane_power"])
 					if value then
 						arcanePower = arcanePower + tonumber(value)
 					end
 						
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Fire spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Fire spells and effects by up to (%d+)."])
 					if value then
 						firePower = firePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Fire Damage %+(%d+)"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Fire Damage %+(%d+)"])
 					if value then
 						firePower = firePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Fire Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Fire Spell Damage"])
 					if value then
 						firePower = firePower + tonumber(value)
 					end
 						
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Frost spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Frost spells and effects by up to (%d+)."])
 					if value then
 						frostPower = frostPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Frost Damage %+(%d+)"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Frost Damage %+(%d+)"])
 					if value then
 						frostPower = frostPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Frost_Spell_Damage1"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Frost_Spell_Damage1"])
 					if value then
 						frostPower = frostPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Frost Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Frost Spell Damage"])
 					if value then
 						frostPower = frostPower + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Holy spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Holy spells and effects by up to (%d+)."])
 					if value then
 						holyPower = holyPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Holy Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Holy Spell Damage"])
 					if value then
 						holyPower = holyPower + tonumber(value)
 					end
 						
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Nature spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Nature spells and effects by up to (%d+)."])
 					if value then
 						naturePower = naturePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Nature Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Nature Spell Damage"])
 					if value then
 						naturePower = naturePower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["jewel_9_nature_power"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["jewel_9_nature_power"])
 					if value then
 						naturePower = naturePower + tonumber(value)
 					end
 				
 						
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Shadow spells and effects by up to (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Shadow spells and effects by up to (%d+)."])
 					if value then
 						shadowPower = shadowPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Equip: Increases damage done by Shadow spells and effects by up (%d+)."])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Equip: Increases damage done by Shadow spells and effects by up (%d+)."])
 					if value then
 						shadowPower = shadowPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Shadow_effect_3"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Shadow_effect_3"])
 					if value then
 						shadowPower = shadowPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["Shadow Damage %+(%d+)"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["Shadow Damage %+(%d+)"])
 					if value then
 						shadowPower = shadowPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_SPELL_SCHOOL["^%+(%d+) Shadow Spell Damage"])
+					_,_, value = strfind(left, L_SPELL_SCHOOL["^%+(%d+) Shadow Spell Damage"])
 					if value then
 						shadowPower = shadowPower + tonumber(value)
 					end
 						
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
 
-					_, _, value = strfind(left:GetText(), L_SPELLPOWER["^Set: Increases damage and healing done by magical spells and effects by up to (%d+)%."])
+					_, _, value = strfind(left, L_SPELLPOWER["^Set: Increases damage and healing done by magical spells and effects by up to (%d+)%."])
 					if value and SET_NAME and not tContains(SpellPower_Set_Bonus, SET_NAME) then
 						tinsert(SpellPower_Set_Bonus, SET_NAME)
 						spellPower = spellPower + tonumber(value)
 					end
 					
-					_, _, value = strfind(left:GetText(), L_SPELL_SCHOOL["Set_Nature_damage"])
+					_, _, value = strfind(left, L_SPELL_SCHOOL["Set_Nature_damage"])
 					if value and SET_NAME and not tContains(SpellPower_Set_Bonus, SET_NAME) then
 						tinsert(SpellPower_Set_Bonus, SET_NAME)
 						naturePower = naturePower + tonumber(value)
 					end
 					
@@ -1457,82 +1541,82 @@
 	local healPower = 0
 	local healPower_Set_Bonus = {}
 	local MAX_INVENTORY_SLOTS = 19
 	
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		
 		if hasItem then
 			local SET_NAME
 			
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+			for line=1, equipment.count do
+				local left = equipment.left[line]
 				
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_HEALPOWER["Equip: Increases healing done by spells and effects by up to (%d+)."])
+				if left then
+					local _,_, value = strfind(left, L_HEALPOWER["Equip: Increases healing done by spells and effects by up to (%d+)."])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Healing Spells %+(%d+)"])
+					_,_, value = strfind(left, L_HEALPOWER["Healing Spells %+(%d+)"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Equip: Increases healing (%d+)."])
+					_,_, value = strfind(left, L_HEALPOWER["Equip: Increases healing (%d+)."])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["^%+(%d+) Healing Spells"])
+					_,_, value = strfind(left, L_HEALPOWER["^%+(%d+) Healing Spells"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["jewel_12_heal_power"])
+					_,_, value = strfind(left, L_HEALPOWER["jewel_12_heal_power"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Hammer of the Twisting Nether"])
+					_,_, value = strfind(left, L_HEALPOWER["Hammer of the Twisting Nether"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Scepter of the False Prophet"])
+					_,_, value = strfind(left, L_HEALPOWER["Scepter of the False Prophet"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_,_, value = strfind(left:GetText(), L_HEALPOWER["Atiesh, Greatstaff of the Guardian_Druid"])
+					_,_,_, value = strfind(left, L_HEALPOWER["Atiesh, Greatstaff of the Guardian_Druid"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_,_, value = strfind(left:GetText(), L_HEALPOWER["Atiesh, Greatstaff of the Guardian_Priest"])
+					_,_,_, value = strfind(left, L_HEALPOWER["Atiesh, Greatstaff of the Guardian_Priest"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Resilience of the Scourge"])
+					_,_, value = strfind(left, L_HEALPOWER["Resilience of the Scourge"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 					
 					--[[
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["fm_12_spell_damage"])
+					_,_, value = strfind(left, L_HEALPOWER["fm_12_spell_damage"])
 					if value then
 						healPower = healPower + tonumber(value)
 					end
 					]]
-					_,_, value = strfind(left:GetText(), L_HEALPOWER["Brilliant_Mana_Oil"])
+					_,_, value = strfind(left, L_HEALPOWER["Brilliant_Mana_Oil"])
 					if value then
 						healPower = healPower + 25
 					end
 					
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_HEALPOWER["^Set: Increases healing done by spells and effects by up to (%d+)%."])
+					_, _, value = strfind(left, L_HEALPOWER["^Set: Increases healing done by spells and effects by up to (%d+)%."])
 					if value and SET_NAME and not tContains(healPower_Set_Bonus, SET_NAME) then
 						tinsert(healPower_Set_Bonus, SET_NAME)
 						healPower = healPower + tonumber(value)
 					end
 				end
@@ -1712,67 +1796,67 @@
 	local MAX_INVENTORY_SLOTS = 19
 	
 	local arcane_mage_3T2 = 0
 	
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		 
 		
 		
 		if hasItem then
 			local SET_NAME
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+			for line=1, equipment.count do
+				local left = equipment.left[line]
 				
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_MANAREGEN["^Mana Regen %+(%d+)"])
+				if left then
+					local _,_, value = strfind(left, L_MANAREGEN["^Mana Regen %+(%d+)"])
 					if value then
 						mp5 = mp5 + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["Equip: Restores (%d+) mana per 5 sec."])
+					_,_, value = strfind(left, L_MANAREGEN["Equip: Restores (%d+) mana per 5 sec."])
 					if value then
 						mp5 = mp5 + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["^%+(%d+) mana every 5 sec."])
+					_,_, value = strfind(left, L_MANAREGEN["^%+(%d+) mana every 5 sec."])
 					if value then
 						mp5 = mp5 + tonumber(value)
 					end
-					_,_,_, value = strfind(left:GetText(), L_MANAREGEN["Resilience of the Scourge"])
+					_,_,_, value = strfind(left, L_MANAREGEN["Resilience of the Scourge"])
 					if value then
 						mp5 = mp5 + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["Brilliant_Mana_Oil"])
+					_,_, value = strfind(left, L_MANAREGEN["Brilliant_Mana_Oil"])
 					if value then
 						mp5 = mp5 + 12
 					end
 		
 					
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["cast_mana_percent_regen_1"])
+					_,_, value = strfind(left, L_MANAREGEN["cast_mana_percent_regen_1"])
 					if value then
 						casting_percent = casting_percent + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["cast_mana_percent_regen_2"])
+					_,_, value = strfind(left, L_MANAREGEN["cast_mana_percent_regen_2"])
 					if value then
 						casting_percent = casting_percent + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_MANAREGEN["cast_mana_percent_regen_3"])
+					_,_, value = strfind(left, L_MANAREGEN["cast_mana_percent_regen_3"])
 					if value then
 						casting_percent = casting_percent + tonumber(value)
 					end
 					
 					--from set
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_MANAREGEN["cast_mana_percent_regen_set"])
+					_, _, value = strfind(left, L_MANAREGEN["cast_mana_percent_regen_set"])
 					if value and SET_NAME and not tContains(ManaRegenCastPercent_Set_bonus, SET_NAME) then
 						tinsert(ManaRegenCastPercent_Set_bonus, SET_NAME)
 						casting_percent = casting_percent + tonumber(value)
 					end
 					
-					_, _, value = strfind(left:GetText(), L_MANAREGEN["arcane_mage_3T2"])
+					_, _, value = strfind(left, L_MANAREGEN["arcane_mage_3T2"])
 					if value then
 						arcane_mage_3T2 = 1
 					end
 					
 				end
@@ -1963,45 +2047,45 @@
 	local haste = 1.0000
 	local haste_Set_bonus = {}
 	local MAX_INVENTORY_SLOTS = 19
 	--from gear
 	for slot=0, MAX_INVENTORY_SLOTS do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 			local SET_NAME = nil
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
+			for line=1, equipment.count do
+				local left = equipment.left[line]
 				
-				if left:GetText() then
-
-					local _,_, value = strfind(left:GetText(), L_HASTE["HASTE_improve_equip_1"])
+				if left then
+
+					local _,_, value = strfind(left, L_HASTE["HASTE_improve_equip_1"])
 					if value then
 						haste = haste * (1+tonumber(value)/100)
 					end
 
-					local _,_, value = strfind(left:GetText(), L_HASTE["HASTE_improve_equip_2"])
+					local _,_, value = strfind(left, L_HASTE["HASTE_improve_equip_2"])
 					if value then
 						haste = haste * (1+tonumber(value)/100)
 					end
 
-					local _,_, value = strfind(left:GetText(), L_HASTE["HASTE_improve_enchant"])
+					local _,_, value = strfind(left, L_HASTE["HASTE_improve_enchant"])
 					if value then
 						haste = haste * (1+tonumber(value)/100)
 					end
 
-					local _,_, value = strfind(left:GetText(), L_HASTE["Libram of Rapidity"])
+					local _,_, value = strfind(left, L_HASTE["Libram of Rapidity"])
 					if value then
 						haste = haste * (1+tonumber(value)/100)
 					end
 					
 					--from set
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
 
-					_, _, value = strfind(left:GetText(), L_HASTE["HASTE_improve_set"])
+					_, _, value = strfind(left, L_HASTE["HASTE_improve_set"])
 					if value and SET_NAME and not tContains(haste_Set_bonus, SET_NAME) then
 						tinsert(haste_Set_bonus, SET_NAME)
 						haste = haste * (1+tonumber(value)/100)
 					end
 
@@ -2079,16 +2163,16 @@
 function BCS:GetOriWeaponSpeed(slotID)
 	if slotID ~= 16 and  slotID ~= 18 then 
 		return nil
 	end 
 	local weaponSpeed = 0
-	local hasItem = BCS_Tooltip:SetInventoryItem("player", slotID)
+	local hasItem, equipment = ReadEquipmentTooltip(slotID)
 	if hasItem then
-		for line=1, BCS_Tooltip:NumLines() do
-			local right = getglobal(BCS_Prefix .. "TextRight" .. line)
-			if right:GetText() then
-				local _, _, v1, v2 = strfind(right:GetText(), L["weaponSpeed"])
+		for line=1, equipment.count do
+			local right = equipment.right[line]
+			if right then
+				local _, _, v1, v2 = strfind(right, L["weaponSpeed"])
 				if v1 then
 					weaponSpeed = v2/100+v1
 					break
 				end
 			end
@@ -2136,26 +2220,26 @@
 
 function BCS:GetLiveOnlyGearArmor()
 	local armor = 0
 	local Set_bonus = {}
 	for slot=0, 19 do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 			local SET_NAME = nil
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_ARMOR["gainarmor"])
+			for line=1, equipment.count do
+				local left = equipment.left[line]
+				if left then
+					local _,_, value = strfind(left, L_ARMOR["gainarmor"])
 					if value then
 						armor = armor + tonumber(value)
 					end
 					--from set
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_ARMOR["gainarmor_set"])
+					_, _, value = strfind(left, L_ARMOR["gainarmor_set"])
 					if value and SET_NAME and not tContains(Set_bonus, SET_NAME) then
 						tinsert(Set_bonus, SET_NAME)
 						armor = armor + tonumber(value)
 					end
 
@@ -2222,36 +2306,36 @@
 	blockvalue = blockvalue + UnitStat("player", 1) / 20
 	
 	--from equip
 	local Set_bonus = {}
 	for slot=0, 19 do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 			local SET_NAME = nil
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_BLOCKVALUE["BLOCKVALUE_1"])
+			for line=1, equipment.count do
+				local left = equipment.left[line]
+				if left then
+					local _,_, value = strfind(left, L_BLOCKVALUE["BLOCKVALUE_1"])
 					if value then
 						blockvalue = blockvalue + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_BLOCKVALUE["BLOCKVALUE_2"])
+					_,_, value = strfind(left, L_BLOCKVALUE["BLOCKVALUE_2"])
 					if value then
 						blockvalue = blockvalue + tonumber(value)
 					end
 					
 					--from set
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_BLOCKVALUE["BLOCKVALUE_SET_1"])
+					_, _, value = strfind(left, L_BLOCKVALUE["BLOCKVALUE_SET_1"])
 					if value and SET_NAME and not tContains(Set_bonus, SET_NAME) then
 						tinsert(Set_bonus, SET_NAME)
 						blockvalue = blockvalue + tonumber(value)
 					end
-					_, _, value = strfind(left:GetText(), L_BLOCKVALUE["BLOCKVALUE_SET_2"])
+					_, _, value = strfind(left, L_BLOCKVALUE["BLOCKVALUE_SET_2"])
 					if value and SET_NAME and not tContains(Set_bonus, SET_NAME) then
 						tinsert(Set_bonus, SET_NAME)
 						blockvalue = blockvalue + tonumber(value)
 					end
 
@@ -2336,42 +2420,42 @@
 	end
 
 	--from equip
 	local Set_bonus = {}
 	for slot=0, 19 do
-		local hasItem = BCS_Tooltip:SetInventoryItem("player", slot)
+		local hasItem, equipment = ReadEquipmentTooltip(slot)
 		if hasItem then
 			local SET_NAME = nil
-			for line=1, BCS_Tooltip:NumLines() do
-				local left = getglobal(BCS_Prefix .. "TextLeft" .. line)
-				if left:GetText() then
-					local _,_, value = strfind(left:GetText(), L_ARMORPENETRATION["ARMORPENETRATION_1"])
+			for line=1, equipment.count do
+				local left = equipment.left[line]
+				if left then
+					local _,_, value = strfind(left, L_ARMORPENETRATION["ARMORPENETRATION_1"])
 					if value then
 						armorPenetrationvalue = armorPenetrationvalue + tonumber(value)
 					end
-					_,_, value = strfind(left:GetText(), L_ARMORPENETRATION["ARMORPENETRATION_2"])
+					_,_, value = strfind(left, L_ARMORPENETRATION["ARMORPENETRATION_2"])
 					if value then
 						armorPenetrationvalue = armorPenetrationvalue + tonumber(value)
 					end
 					
-					_,_, value = strfind(left:GetText(), L_ARMORPENETRATION["ARMORPENETRATION_3"])
+					_,_, value = strfind(left, L_ARMORPENETRATION["ARMORPENETRATION_3"])
 					if value then
 						armorPenetrationvalue = armorPenetrationvalue + tonumber(value)
 					end
 					
 					--[[
 					--from set
-					_,_, value = strfind(left:GetText(), "(.+)（%d/%d）")
+					_,_, value = strfind(left, "(.+)（%d/%d）")
 					if value then
 						SET_NAME = value
 					end
-					_, _, value = strfind(left:GetText(), L_BLOCKVALUE["ARMORPENETRATION_SET_1"])
+					_, _, value = strfind(left, L_BLOCKVALUE["ARMORPENETRATION_SET_1"])
 					if value and SET_NAME and not tContains(Set_bonus, SET_NAME) then
 						tinsert(Set_bonus, SET_NAME)
 						armorPenetrationvalue = armorPenetrationvalue + tonumber(value)
 					end
-					_, _, value = strfind(left:GetText(), L_BLOCKVALUE["ARMORPENETRATION_SET_2"])
+					_, _, value = strfind(left, L_BLOCKVALUE["ARMORPENETRATION_SET_2"])
 					if value and SET_NAME and not tContains(Set_bonus, SET_NAME) then
 						tinsert(Set_bonus, SET_NAME)
 						armorPenetrationvalue = armorPenetrationvalue + tonumber(value)
 					end
 					]]
```
