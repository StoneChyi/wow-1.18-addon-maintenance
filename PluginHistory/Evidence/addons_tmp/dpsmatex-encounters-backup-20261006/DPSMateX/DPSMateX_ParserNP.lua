-- Events
local DPSMateX = DPSMateX
local DB = DPSMateX.DB

local strsub = string.sub
local strgfind = string.gfind
local UnitName = UnitName
local GT = GetTime
local GetUnitField = GetUnitField

local HITINFO_AFFECTS_VICTIM = 2
local HITINFO_LEFTSWING = 4
local HITINFO_MISS = 16
local HITINFO_ABSORB = 32
local HITINFO_RESIST = 64
local HITINFO_CRITICALHIT = 128  -- 0x80
local HITINFO_GLANCING = 16384   -- 0x4000
local HITINFO_CRUSHING = 32768   -- 0x8000
local HITINFO_ENVIRONMENT = 16777216   -- 0x1000000

local envDamage = {
	[0] = "Exhausted",
	[1] = "Drowning",
	[2] = "Fall",
	[3] = "Lava",
	[4] = "Slime",
	[5] = "Fire",
	[6] = "Void",
}

if GetLocale() == "zhCN" then
	envDamage = {
		[0] = "精疲力竭",
		[1] = "溺水",
		[2] = "下跌",
		[3] = "熔岩",
		[4] = "泥浆",
		[5] = "火焰",
		[6] = "虚空",
	}
end

local bit = bit
local function hitCrit(hitInfo)
	return (bit.band(hitInfo, HITINFO_CRITICALHIT) == 0) and 0 or 1
end

local function hitGlancing(hitInfo)
	return (bit.band(hitInfo, HITINFO_GLANCING) == 0) and 0 or 1
end

local function hitCrushing(hitInfo)
	return (bit.band(hitInfo, HITINFO_CRUSHING) == 0) and 0 or 1
end

local function hitAbsorb(hitInfo)
	return (bit.band(hitInfo, HITINFO_ABSORB) == 0) and 0 or 1
end

local function hitResist(hitInfo)
	return (bit.band(hitInfo, HITINFO_RESIST) == 0) and 0 or 1
end

local function hitMiss(hitInfo)
	return (bit.band(hitInfo, HITINFO_MISS) == 0) and 0 or 1
end

local function isOffHandAttack(hitInfo)
	return bit.band(hitInfo, HITINFO_LEFTSWING) ~= 0
end

local function AutoAttackAB(hitInfo)
	return isOffHandAttack(hitInfo) and DPSMateX.L["AutoAttackOffhand"] or DPSMateX.L["AutoAttack"]
end

local VICTIMSTATE_NORMAL = 1
local VICTIMSTATE_DODGE = 2
local VICTIMSTATE_PARRY = 3
local VICTIMSTATE_BLOCK = 5

local function hitDodge(victimState)
	return (victimState == VICTIMSTATE_DODGE) and 1 or 0
end

local function hitParry(victimState)
	return (victimState == VICTIMSTATE_PARRY) and 1 or 0
end

local function hitBlock(victimState)
	return (victimState == VICTIMSTATE_BLOCK) and 1 or 0
end

local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local GetSpellNameAndRankForId = GetSpellNameAndRankForId
local GetUnitGUID = GetUnitGUID

function IsPet(unit)
	return GetUnitGUID(unit.."owner")
end

local IsPet = IsPet
local Parser = DPSMateX.Parser
DPSMateX.Parser.HitsX = function()
	local attackerGuid, targetGuid, totalDamage, hitInfo, victimState, subDamageCount, blockedAmount, totalAbsorb, totalResist = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	
	local amount = totalDamage --todo do we need subtract the absorb?
	local resist = hitResist(hitInfo)
	
	local ability

	local miss = hitMiss(hitInfo)
	local crit = hitCrit(hitInfo)
	local glance = hitGlancing(hitInfo)
	local parry = hitParry(victimState)
	local dodge = hitDodge(victimState)
	local block = hitBlock(victimState)
	if blockedAmount > 0 then block = 1 end
	--its wheird crit block appear in same hit on twow, so if its crit, then ignore block
	if crit == 1 then block = 0 end
	local hit = (glance + block + crit + parry + dodge + miss) == 0 and 1 or 0
	--if attackerGuid == DPSMateX.Parser.player then print(" crit "..crit.." oblock "..hitBlock(hitInfo).." block "..block.." dodge "..dodge.." glance "..glance.." miss "..miss.." parry "..parry.." hit "..hit) end
	local crush = 0
	
	if UnitIsFriend("player", attackerGuid) and (UnitIsPlayer(attackerGuid) or IsPet(attackerGuid)) then
		local usrid, usr = DB:BuildUser(attackerGuid)
		ability = AutoAttackAB(hitInfo)
		DB:EnemyDamage(true, DPSMateX.DBCache.EDT, attackerGuid, ability, hit, crit, miss, parry, dodge, resist, amount, targetGuid, block, glance)
		if DPSMateX.Parser.TargetParty[targetGuid] then 
			if Parser.TargetParty[attackerGuid] then 
				DB:BuildFail(1, targetGuid, attackerGuid, ability, amount);
			end
			DB:DeathHistory(targetGuid, attackerGuid, ability, amount, hit, crit, 0, crush) 
		else
			DB:DamageDone(attackerGuid, ability, hit, crit, miss, parry, dodge, resist, amount, glance, block, targetGuid)
		end
	else
		ability = AutoAttackAB(hitInfo)
		crush = hitCrushing(hitInfo)
		DB:EnemyDamage(false, DPSMateX.DBCache.EDD, targetGuid, ability, hit, crit, miss, parry, dodge, resist, amount, attackerGuid, block, glance)
		DB:DamageTaken(targetGuid, ability, hit, crit, miss, parry, dodge, resist, amount, attackerGuid, crush, block)
		if UnitIsPlayer(targetGuid) then
			DB:DeathHistory(targetGuid, attackerGuid, ability, amount, hit, crit, 0, crush) 
		end
	end

	if totalAbsorb > 0 then
		DB:SetUnregisterVariables(totalAbsorb, ability, targetGuid)
	end
end

local SPELL_MISS_NONE    = 0   -- No miss (shouldn't normally appear)
local SPELL_MISS_MISS    = 1   -- Miss
local SPELL_MISS_RESIST  = 2   -- Resist (also used for SMSG_PROCRESIST)
local SPELL_MISS_DODGE   = 3   -- Dodge
local SPELL_MISS_PARRY   = 4   -- Parry
local SPELL_MISS_BLOCK   = 5   -- Block
local SPELL_MISS_EVADE   = 6   -- Evade
local SPELL_MISS_IMMUNE  = 7   -- Immune
local SPELL_MISS_IMMUNE2 = 8   -- Immune (variant)
local SPELL_MISS_DEFLECT = 9   -- Deflect
local SPELL_MISS_ABSORB  = 10  -- Absorb
local SPELL_MISS_REFLECT = 11  -- Reflect

DPSMateX.Parser.SpellDamageMiss = function()
	local attackerGuid, targetGuid, spellId, missInfo = arg1, arg2, arg3, arg4
	local miss = (missInfo == SPELL_MISS_MISS) and 1 or 0
	local parry = (missInfo == SPELL_MISS_PARRY) and 1 or 0
	local dodge = (missInfo == SPELL_MISS_DODGE) and 1 or 0
	local resist = (missInfo == SPELL_MISS_RESIST) and 1 or 0
	local block = (missInfo == SPELL_MISS_BLOCK) and 1 or 0

	if missInfo >= SPELL_MISS_EVADE then
		resist = 1 --fall to resist
	end 

	local spell = GetSpellNameAndRankForId(spellId)
	if spell == "瞄准射击" and DB.LockNLoad[attackerGuid] ~= targetGuid then spell = "荷枪实弹" end

	--if not attackerGuid and targetGuid then print(spell.. "on".. UnitName(targetGuid)) end
	if UnitIsFriend("player", attackerGuid) and (UnitIsPlayer(attackerGuid) or IsPet(attackerGuid)) then
		DB:EnemyDamage(true, DPSMateX.DBCache.EDT, attackerGuid, spell, 0, 0, miss, parry, dodge, resist, 0, targetGuid, block, 0)
		DB:DamageDone(attackerGuid, spell, 0, 0, miss, parry, dodge, resist, 0, 0, block, targetGuid)
		if DPSMateX.bTrackingThunderArmor and DB.trackedSpells[spellId] then 
			--if UNIT_CASTEVENT CAST happens before SpellDamageMiss, then TrackingSpell[attackerGuid] will be set, so we just set it to nil
			--otherwise, we add an spell entry with null time to fool around TrackingProc
			if not DPSMateX.Parser.TrackingSpell[attackerGuid] then
				DPSMateX.Parser.TrackingSpell[attackerGuid] = {spell, targetGuid, nil}
			end
		end
	else
		if not attackerGuid then DB:SPELL_DAMAGE_EVENT() return end
		DB:EnemyDamage(false, DPSMateX.DBCache.EDD, targetGuid, spell, 0, 0, miss, parry, dodge, resist, 0, attackerGuid, block, 0)
		DB:DamageTaken(targetGuid, spell, 0, 0, miss, parry, dodge, resist, 0, attackerGuid, 0, block)
		if UnitIsPlayer(targetGuid) then
			DB:DeathHistory(targetGuid, attackerGuid, spell, 0, 0, 0, 0, 0) 
			if Parser.FailDT[spell] then DB:BuildFail(2, attackerGuid, targetGuid, spell, 0) end
		end
	end
end

local schoolMap = {
	[1] = "Physical",
	[2] = "Holy",
	[3] = "Fire",
	[4] = "Nature",
	[5] = "Frost",
	[6] = "Shadow",
	[7] = "Arcane",
}

if GetLocale() == "zhCN" then
	schoolMap = {
		[1] = "物理",
		[2] = "神圣",
		[3] = "火焰",
		[4] = "自然",
		[5] = "冰霜",
		[6] = "暗影",
		[7] = "奥术",
	}
end

local AbilityPeriodic
DPSMateX.Parser.SpellDamageX = function()
	local targetGuid, attackerGuid, spellId, amount, mitigationStr, hitInfo, spellSchool, effectAuraStr = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
	local spell = GetSpellNameAndRankForId(spellId)
	if spell == "瞄准射击" and DB.LockNLoad[attackerGuid] ~= targetGuid then spell = "荷枪实弹" end
	
	local isPlayer = UnitIsPlayer(attackerGuid)
	if not isPlayer then
		local charmer = GetUnitField(attackerGuid, "charm")
		if charmer and charmer ~= "0x0000000000000000" then 
			attackerGuid = charmer 
			isPlayer = UnitIsPlayer(charmer)
		end
	end

	--hit or crit
	local hit, crit
	crit = (hitInfo == 2 and 1 or 0)
	hit = 1 - crit

	local absorb, block, resist = "0", 0, 0
	for a,b,c in strgfind(mitigationStr, "(%d+),(%d+),(%d+)") do
		absorb = a
		block = (b == "0" and 0 or 1)
		--parital resists are not concerned
		--resist = (c == "0" and 0 or 1) 
	end
	
	local effect1, effect2, effect3, auraType
	for a,b,c,d in strgfind(effectAuraStr, "(%d+),(%d+),(%d+),(%d+)") do
		effect1 = a; effect2 = b; effect3 = c; auraType = d
	end

	if auraType == "3" then 
		AbilityPeriodic = AbilityPeriodic or DPSMateX.L["periodic"]
		spell = spell..AbilityPeriodic 
	end

	if absorb ~= "0" then
		DB:SetUnregisterVariables(absorb, spell, targetGuid)
	end

	--[[
	local ok, isFriend = pcall(UnitIsFriend, "player", attackerGuid)
	if not ok then 
		isFriend = isPlayer 
		CombatLogAdd("Error: 未知目标"..spell.."对"..(UnitName(targetGuid) or "nil").."造成"..amount.."点伤害")
		return
 	end
	]]
	--if isFriend and (isPlayer or IsPet(attackerGuid)) then
	local targetInParty = Parser.TargetParty[targetGuid]

	if UnitIsFriend("player", attackerGuid) and (isPlayer or IsPet(attackerGuid)) then
		if targetGuid == attackerGuid or GetUnitGUID(targetGuid.."owner") == attackerGuid then --suicide damage
			DB:DamageTaken(attackerGuid, spell, hit, crit, 0, 0, 0, resist, amount, targetGuid, 0, block)
		else
			if auraType ~= "3" then -- not SPELL_AURA_PERIODIC_DAMAGE 
				if Parser.Kicks[spell] then DB:AssignPotentialKick(attackerGuid, spell, targetGuid, GT()) end
				if Parser.DmgProcs[spell] then DB:BuildBuffs(attackerGuid, attackerGuid, spell, true) end
			end
			if not targetInParty then
				DB:DamageDone(attackerGuid, spell, hit, crit, 0, 0, 0, resist, amount, 0, block, targetGuid)
			end
		end 
		
		DB:EnemyDamage(true, DPSMateX.DBCache.EDT, attackerGuid, spell, hit, crit, 0, 0, 0, resist, amount, targetGuid, block, 0)

		if targetInParty then
			if Parser.TargetParty[attackerGuid] then 
				DB:BuildFail(1, targetGuid, attackerGuid, spell, amount); 
			end 
			DB:DeathHistory(targetGuid, attackerGuid, spell, amount, hit, crit, 0, 0) 
		end
	else
		--creature dealt damage
		DB:UnregisterPotentialKick(targetGuid, spell, GT())
		DB:EnemyDamage(false, DPSMateX.DBCache.EDD, targetGuid, spell, hit, crit, 0, 0, 0, resist, amount, attackerGuid, block, 0)
		DB:DamageTaken(targetGuid, spell, hit, crit, 0, 0, 0, resist, amount, attackerGuid, 0, block)
		if UnitIsPlayer(targetGuid) then
			DB:DeathHistory(targetGuid, attackerGuid, spell, amount, hit, crit, 0, 0) 
			if Parser.FailDT[spell] then DB:BuildFail(2, attackerGuid, targetGuid, spell, amount) end
		end
	end

	if schoolMap[spellSchool + 1] then
		DB:AddSpellSchool(spell, schoolMap[spellSchool + 1])
	end
end

local pcall = pcall
DPSMateX.Parser.AuraChangedX = function(self, debuff, on)
	local guid, luaSlot, spellId, stacks, auraLevel, auraSlot, state = arg1, arg2, arg3, arg4, arg5, arg6, arg7
	
	if not spellId or spellId == 0 then return end --said its triggered by hidden aura
	local ret, spell = pcall(GetSpellNameAndRankForId, spellId)
	--if not ret then print(spellId.." of "..guid.." "..UnitName(guid).." not resovled") spell = "未知技能" TargetUnit(guid) end

	if state == 2 and not self.BuffStackMatters[spell] then return end
	
	if debuff then
		if on then
			DB:BuildBuffs(DB.UserUnknown, guid, spell, false)
			DB:FillDebuffType(guid, spell)
			if self.CC[spell] then DB:BuildActiveCC(guid, spell) end
		else
			DB:DestroyBuffs(guid, spell)
		end
	else
		if on then
			if self.BuffExceptions[spell] then return end
		
			local caster
			if self.BuffStackMatters[spell] then
				self.BuffStacking = self.BuffStacking or {}
				self.BuffStacking[guid] = self.BuffStacking[guid] or {}

				local cur_stack = self.BuffStacking[guid][spell] or 0
				self.BuffStacking[guid][spell] = stacks

				for i = cur_stack + 1, stacks do
					local suffix = (i == 1) and "" or "("..i..")"
					caster = DB:ConfirmBuff(guid, spell..suffix, GT())
				end
			else
				caster = DB:ConfirmBuff(guid, spell, GT())
			end

			if self.HotDispels[spell] then DB:RegisterHotDispel(guid, spell, caster) end
			if self.RCD[spell] then DPSMateX:Broadcast(1, guid, spell) end
			if self.FailDB[spell] then DB:BuildFail(3, guid, guid, spell, 0) end
		else
			if self.BuffExceptions[spell] then return end; 
			
			--if DB.ShieldFlags[spell] then DB:UnregisterAbsorb(spell, guid) end; 
			if DPSMateX.ShieldHealDetect and DB.ShieldAsHeal[spell] then DB:RemoveShieldAsHeal(spell, guid) end; 
			if self.RCD[spell] then DPSMateX:Broadcast(6, guid, spell) end; 

			local maxstacks = self.BuffStackMatters[spell]
			if maxstacks then
				self.BuffStacking = self.BuffStacking or {}
				self.BuffStacking[guid] = self.BuffStacking[guid] or {}

				local cur_stacks = self.BuffStacking[guid][spell] or 1
				for i=1,cur_stacks do
					local suffix = (i == 1) and "" or "("..i..")"
					DB:DestroyBuffs(guid, spell..suffix)
				end

				self.BuffStacking[guid][spell] = 0
			else
				DB:DestroyBuffs(guid, spell)
			end

			if self.HotDispels[spell] then DB:UnregisterHotDispel(guid, spell) end

			--Windfury gone, sometimes it won't trigger any extra attacks
			--if DB.ExtraAttacks[spell] then DB:UnregisterNextSwing(guid, spell) end

			DB:RemoveActiveCC(guid, spell) 
		end
	end
end

DPSMateX.Parser.AuraCastX = function()
	local spellId, casterGuid, targetGuid, effect, effectAuraName, effectAmplitude, effectMiscValue, durationMs, auraCapStatus = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	--effect 王者 = SPELL_EFFECT_APPLY_AURA = 6
	--effectAuraName 王者 = SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE = 137
	local spell = GetSpellNameAndRankForId(spellId)
	
	--local extraAttacks = DB.ExtraAttacks[spell]
	--if extraAttacks and targetGuid then DB:RegisterNextSwing(targetGuid, extraAttacks, spell) end

	local time = GT()
	--DB:AwaitAfflicted(DPSMateX.Parser.playername, spell, UnitName("target"), time)
	DB:AwaitingBuff(casterGuid, targetGuid, spell, GT())
	--DB:AwaitingAbsorbConfirmation(casterGuid, spell, targetGuid, time)
end

DPSMateX.Parser.SpellHealX = function(self)
	local targetGuid, casterGuid, spellId, amount, crit, periodic = arg1, arg2, arg3, arg4, arg5, arg6

	local spell = GetSpellNameAndRankForId(spellId)
	local overheal = self:GetOverhealByName(amount, targetGuid)
	local hit = (crit == 1 and 0 or 1)

	if periodic == "1" then spell = spell..AbilityPeriodic end

	DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, targetGuid, spell, hit, crit, amount, casterGuid)
	DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, targetGuid, spell, hit, crit, amount-overheal, casterGuid)
	DB:Healing(0, DPSMateX.DBCache.EHealing, casterGuid, spell, hit, crit, amount-overheal)
	if overheal>0 then 
		DB:Healing(2, DPSMateX.DBCache.Overhealing, casterGuid, spell, hit, crit, overheal)
		DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, targetGuid, spell, hit, crit, overheal, casterGuid)
	end
	DB:Healing(1, DPSMateX.DBCache.THealing, casterGuid, spell, hit, crit, amount)

	if UnitIsFriend("player", casterGuid) and UnitIsPlayer(targetGuid) then
		DB:DeathHistory(targetGuid, casterGuid, spell, amount, hit, crit, 1, 0)
	end
end

DPSMateX.Parser.EnvDamageX = function()
	local targetGuid, dmgType, amount, absorb, resist = arg1, arg2, arg3, arg4, arg5

	local ability = envDamage[dmgType] or DPSMateX.L["Environment"]
	local attackerGuid = DPSMateX.L["Environment"]
	DB:DamageTaken(targetGuid, ability, 1, 0, 0, 0, 0, 0, amount, attackerGuid, 0, 0)

	if UnitIsPlayer(targetGuid) then
		DB:DeathHistory(targetGuid, attackerGuid, ability, amount, 1, 0, 0, 0)
	end

	if absorb > 0 then
		DB:SetUnregisterVariables(absorb, ability, targetGuid)
	end
end

--its Physical for 0 actually
local shiledDamageType = {
	[1] = "Holy",
	[2] = "Fire",
	[3] = "Nature",
	[4] = "Frost",
	[5] = "Shadow",
	[6] = "Arcane",
	[7] = "Physical",
}

if GetLocale() == "zhCN" then
	shiledDamageType = {
		[1] = "神圣",
		[2] = "火焰",
		[3] = "自然",
		[4] = "冰霜",
		[5] = "暗影",
		[6] = "奥术",
		[7] = "物理",
	}
end

DPSMateX.Parser.DamageShiledX = function() 
	local attackerGuid, targetGuid, amount, spellSchool = arg1, arg2, arg3, arg4
	
	local spell = shiledDamageType[spellSchool] or shiledDamageType[7]
	local spell = "反弹("..spell..")"

	if UnitIsFriend("player", attackerGuid) and (UnitIsPlayer(attackerGuid) or IsPet(attackerGuid)) then
		DB:EnemyDamage(true, DPSMateX.DBCache.EDT, attackerGuid, spell, 1, 0, 0, 0, 0, 0, amount, targetGuid, 0, 0)
		DB:DamageDone(attackerGuid, spell, 1, 0, 0, 0, 0, 0, amount, 0, 0, targetGuid)
	else
		DB:EnemyDamage(true, DPSMateX.DBCache.EDD, targetGuid, spell, 1, 0, 0, 0, 0, 0, amount, attackerGuid, 0, 0)
		DB:DamageTaken(targetGuid, spell, 1, 0, 0, 0, 0, 0, amount, attackerGuid, 0, 0)
	end
end

DPSMateX.Parser.SpellDispelX = function() 
	local casterGuid, targetGuid, spellId = arg1, arg2, arg3

	local spell = GetSpellNameAndRankForId(spellId)

	DB:SeenDebuffDispelled(spell, targetGuid, GT(), casterGuid)
end

DPSMateX.Parser.SpellFailedSelfX = function() 
end

DPSMateX.Parser.SpellFailedOtherX = function() 

	local casterGuid, spellId = arg1, arg2

	DB:OnSpellFailed(casterGuid, spellId)
end

DPSMateX.Parser.SpellGoX = function()
 	local spellId, casterGuid, targetGuid = arg2, arg3, arg4

	if Parser.TargetParty[casterGuid] then
		DB:OnSpellCast(casterGuid, targetGuid, spellId)
	end
end

DPSMateX.Parser.SpellStartX = function()
 	local spellId, casterGuid = arg2, arg3

	if not DPSMateX.Parser.TargetParty[casterGuid] then
		DB:OnSpellStart(casterGuid, spellId)
	end
end

DPSMateX.Parser.UnitDiedX = function() 
	local unitGuid = arg1
	if UnitIsPlayer(unitGuid) and UnitIsFriend("player", unitGuid) then
		DB:UnregisterDeath(unitGuid)
	end
end

local strfind = string.find
local tnbr = tonumber
DPSMateX.Parser.ExtractProcTrigger = function() 
	local _,_,a,c,_,b = strfind(arg1, "(.+)通过(.+)获得(.*)(%d+)次额外攻击")
	if a and c and b then
		if a == "你" then a = DPSMateX.Parser.playername end
		DB:RegisterNextSwing(a, tnbr(b), c)
		DB:BuildBuffs(a, a, c, true)
		DB:DestroyBuffs(a, c)
	end
end
