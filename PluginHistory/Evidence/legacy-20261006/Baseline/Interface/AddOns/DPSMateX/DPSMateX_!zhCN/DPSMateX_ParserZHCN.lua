local DPSMateX = DPSMateX
local DB = DPSMateX.DB

local overheal
local strgfind = string.gfind
local tnbr = tonumber
local strgsub = string.gsub
local GetTime = GetTime
local strfind = string.find
local strsub = string.sub
local getn = table.getn
local tinsert = table.insert

local AbilityPeriodic = DPSMateX.L["periodic"]
DB.UserUnknown = DPSMateX.L["unknown"]

local function incStats(name, index)
	DPSMateX.Stats[name] = DPSMateX.Stats[name] or {}
	DPSMateX.Stats[name][index] = (DPSMateX.Stats[name][index] or 0) + 1
end

local function logMsg(name, type, msg)
	DPSMateX.Stats[name] = DPSMateX.Stats[name] or {}
	DPSMateX.Stats[name][type] = DPSMateX.Stats[name][type] or {}
	if getn(DPSMateX.Stats[name][type]) < 100 then
		tinsert(DPSMateX.Stats[name][type], msg)
	end
end

local logcount = 0
local DEFAULT_CHAT_FRAME
local logUnhandledMsg = function(name, type, msg)
	if logcount < 100 then
		logcount = logcount + 1
		DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME or getglobal("DEFAULT_CHAT_FRAME")
		DEFAULT_CHAT_FRAME:AddMessage(name.." "..type.." "..msg)
	end
	logMsg(name, type, msg)
end

local AbilityAutoAttack = DPSMateX.L["AutoAttack"]

if (GetLocale() == "zhCN") then
	DPSMateX.Parser.SelfHits = function(self, msg)
		--教官拉苏维奥斯击中剑舞狂沙造成2437点伤害。（295点被格挡）(1507点被吸收)
			--incStats("SelfHits", 1)
		for a,b,c,_,d in strgfind(msg, "你击中(.+)造成(%d+)点(.*)伤害。(.-)(%d+)点被吸收") do 
			DB:SetUnregisterVariables(tnbr(d), AbilityAutoAttack, self.player)
		end
			--incStats("SelfHits", 2)
		for a,b,f,c in strgfind(msg, "你击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, _, glance, block, amount = nil, nil, nil, nil, tnbr(b)
			--if c == "(偏斜)" then glance=1;hit=0 elseif c ~= "" then block=1;hit=0; end
			if c~="" then 
				if strfind(c, "偏斜") then glance=1;hit=0 elseif strfind(c, "被格挡") then block=1;hit=0; end
			end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, a, block or 0, glance or 0)
			DB:DamageDone(self.player, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, glance or 0, block or 0, a)
			if self.TargetParty[a] then DB:BuildFail(1, a, self.player, AbilityAutoAttack, amount);DB:DeathHistory(a, self.player, AbilityAutoAttack, amount, 1, 0, 0, 0) end
			return
		end
			--incStats("SelfHits", 3)
		for a,b,c in strgfind(msg, "你对(.+)造成(%d+)的致命一击伤害。%s?(.*)") do
			local val = tnbr(b)
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 1, 0, 0, 0, 0, val, a, 0, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 1, 0, 0, 0, 0, val, 0, 0, a)
			if self.TargetParty[a] then DB:BuildFail(1, a, self.player, AbilityAutoAttack, val);DB:DeathHistory(a, self.player, AbilityAutoAttack, val, 0, 1, 0, 0) end
			return
		end
			--incStats("SelfHits", 4)
		for a,b,f,c in strgfind(msg, "你的致命一击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local val = tnbr(b)
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 1, 0, 0, 0, 0, val, a, 0, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 1, 0, 0, 0, 0, val, 0, 0, a)
			if self.TargetParty[a] then DB:BuildFail(1, a, self.player, AbilityAutoAttack, val);DB:DeathHistory(a, self.player, AbilityAutoAttack, val, 0, 1, 0, 0) end
			return
		end
			--incStats("SelfHits", 5)
		for a in strgfind(msg, "你从高处掉落损失(%d+)生命值。") do
			local val = tnbr(a)
			DB:DamageTaken(self.player, "下跌", 1, 0, 0, 0, 0, 0, val, "环境", 0, 0)
			DB:DeathHistory(self.player, "环境", "下跌", val, 1, 0, 0, 0)
			return
		end
			--incStats("SelfHits", 6)
		for a in strgfind(msg, "你泡在岩浆中，损失了(%d+)点生命值。") do
			local val = tnbr(a)
			DB:DamageTaken(self.player, "熔岩", 1, 0, 0, 0, 0, 0, val, "环境", 0, 0)
			DB:DeathHistory(self.player, "环境", "熔岩", val, 1, 0, 0, 0)
			DB:AddSpellSchool("熔岩","火焰")
			return
		end
			--incStats("SelfHits", 7)
		for a in strgfind(msg, "你受到(%d+)点火焰伤害。") do
			local val = tnbr(a)
			DB:DamageTaken(self.player, "火焰", 1, 0, 0, 0, 0, 0, val, "环境", 0, 0)
			DB:DeathHistory(self.player, "环境", "火焰", val, 1, 0, 0, 0)
			DB:AddSpellSchool("火焰","火焰")
			return
		end
			--incStats("SelfHits", 8)
		for a in strgfind(msg, "你现在处于溺水状态并损失(%d+)生命值。") do
			local val = tnbr(a)
			DB:DamageTaken(self.player, "溺死", 1, 0, 0, 0, 0, 0, val, "环境", 0, 0)
			DB:DeathHistory(self.player, "环境", "溺死", val, 1, 0, 0, 0)
			return
		end
			--incStats("SelfHits", 9)
		for a in strgfind(msg, "你泡在泥浆中，损失了(%d+)点生命值。") do
			local val = tnbr(a)
			DB:DamageTaken(self.player, "泥浆", 1, 0, 0, 0, 0, 0, val, "环境", 0, 0)
			DB:DeathHistory(self.player, "环境", "泥浆", val, 1, 0, 0, 0)
			return
		end
			--incStats("SelfHits", 10)
		--logUnhandledMsg("SelfHits", arg1, msg)
	end
	
	DPSMateX.Parser.SelfMisses = function(self, msg)
			--incStats("SelfMisses", 1)
		for a in strgfind(msg, "你没有击中(.+)。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
			--incStats("SelfMisses", 2)
		for a,b in strgfind(msg, "你发起了攻击。(.+)闪开了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
			--incStats("SelfMisses", 3)
		for a in strgfind(msg, "你发起了攻击。(.+)招架住了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
			--incStats("SelfMisses", 4)
		for a in strgfind(msg, "你发起了攻击。(.+)格挡住了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, a, 1, 0)
			DB:DamageDone(self.player, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
			--incStats("SelfMisses", 5)
			--"你发起了攻击，但是0xF13000F1FC276BDC对此免疫。"
		for ta in strgfind(msg, "你发起了攻击，但是(.+)对此免疫。") do 
			DB:Absorb(AbilityAutoAttack, ta, self.player); 
			return 
		end
			--incStats("SelfMisses", 6)
		for ta in strgfind(msg, "你发动攻击，(.+)吸收了所有伤害。") do 
			DB:Absorb(AbilityAutoAttack, ta, self.player); 
			return 
		end
			--incStats("SelfMisses", 7)
		--logUnhandledMsg("SelfMisses", arg1, msg)
	end
	
	DPSMateX.Parser.SpellSelfDamage = function(self, msg)
			--incStats("SpellSelfDamage", 1)
		for a,b,x,c,d,e in strgfind(msg, "你的(.+)击中(.+)造成([了]*)(%d+)点(.-)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if c~=""then
				if strfind(e, "点被格挡") then block=1;hit=0; end
				local _,_,_,absorb=strfind(c,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), a, self.player) end
			end
			if b=="你" then --suicide damage
				b=self.player 
				DB:DamageTaken(self.player, a, 1, 0, 0, 0, 0, 0, amount, b, 0, block or 0)
				DB:DeathHistory(self.player, b, a, amount, 1, 0, 0, 0)
				if self.FailDT[a] then DB:BuildFail(2, self.player, b, a, amount) end
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(self.player, a, b, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(self.player, self.player, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a,  hit or 1, 0, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(self.player, a, hit or 1, 0, 0, 0, 0, 0, amount, 0, block or 0, b)
				if self.TargetParty[b] then DB:BuildFail(1, b, self.player, a, amount);DB:DeathHistory(b, self.player, a, amount, 1, 0, 0, 0) end
			end 
			if d then DB:AddSpellSchool(a,d) end
			return
		end
		--你的旋风斩对死灵捕猎者造成1255的致命一击伤害。（36点被格挡）
			--incStats("SpellSelfDamage", 2)
		for a,b,d,e in strgfind(msg, "你的(.+)对(.+)造成(%d+)的致命一击伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(d), nil, nil
			--t = {tnbr(d), nil, nil, nil}
			if b=="你" then  --suicide damage
				b=self.player 
				DB:DamageTaken(self.player, a, 0, 1, 0, 0, 0, 0, amount, b, 0, block or 0)
				DB:DeathHistory(self.player, b, a, amount, 0, 1, 0, 0)
				if self.FailDT[a] then DB:BuildFail(2, self.player, b, a, amount) end
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(self.player, a, b, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(self.player, self.player, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a,  0, hit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(self.player, a, 0, hit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
				--DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a,  0, 1, 0, 0, 0, 0, amount, b, 0, 0)
				--DB:DamageDone(self.player, a, 0, 1, 0, 0, 0, 0, amount, 0, 0, b)
				if self.TargetParty[b] then DB:BuildFail(1, b, self.player, a, amount);DB:DeathHistory(b, self.player, a, amount, 1, 0, 0, 0) end
			end
			return
		end
		--X骑的神圣打击致命一击对淤泥喷射者造成1580点神圣伤害。（38点被格挡）
			--incStats("SpellSelfDamage", 3)
		for a,b,c,d,e in strgfind(msg, "你的(.+)致命一击对(.+)造成(%d+)点(.-)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then  --suicide damage
				b=self.player
				DB:DamageTaken(self.player, a, 0, 1, 0, 0, 0, 0, amount, b, 0, block or 0)
				DB:DeathHistory(self.player, b, a, amount, 0, 1, 0, 0)
				if self.FailDT[a] then DB:BuildFail(2, self.player, b, a, amount) end
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(self.player, a, b, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(self.player, self.player, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a,  0, hit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(self.player, a, 0, hit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
				if self.TargetParty[b] then DB:BuildFail(1, b, self.player, a, amount);DB:DeathHistory(b, self.player, a, amount, 1, 0, 0, 0) end
			end
			if d then DB:AddSpellSchool(a,d) end
			return
		end
			--incStats("SpellSelfDamage", 4)
		for whom, what in strgfind(msg, "你打断了(.-)的(.+)。") do
			local usr = DPSMateX.CacheUser[self.player]
			local causeAbility = "法术反制"
			if usr and usr[2] == "priest" then
				causeAbility = "沉默"
			end
			DB:Kick(self.player, whom, causeAbility, what)
			return
		end
			--incStats("SpellSelfDamage", 5)
		for b,a in strgfind(msg, "你的(.+)被(.+)闪躲过去。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(self.player, b, 0, 0, 0, 0, 1, 0, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
			--incStats("SpellSelfDamage", 6)
		for a,b in strgfind(msg, "你的(.+)被(.+)招架了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(self.player, a, 0, 0, 0, 1, 0, 0, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
			--incStats("SpellSelfDamage", 7)
		for a,b in strgfind(msg, "你的(.+)没有击中(.+)。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(self.player, a, 0, 0, 1, 0, 0, 0, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
			--incStats("SpellSelfDamage", 8)
		for a,b in strgfind(msg, "你的(.+)被(.+)抵抗了。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(self.player, a, 0, 0, 0, 0, 0, 1, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
			--incStats("SpellSelfDamage", 9)
		for a,b in strgfind(msg, "你的(.+)被(.+)格挡了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(self.player, a, 0, 0, 0, 0, 0, 0, 0, 0, 1, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
			--incStats("SpellSelfDamage", 10)
		for a,b in strgfind(msg, "你的(.+)施放失败。(.+)对此免疫。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, self.player, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(self.player, a, 0, 0, 0, 0, 0, 1, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[self.player] then DPSMateX.Parser.TrackingSpell[self.player] = nil end
			return
		end
		--0xF13000EA4D05DA44对你的重伤免疫。
		--你对你的血性狂暴免疫。
			--incStats("SpellSelfDamage", 11)
		for c, a in strgfind(msg, "你对(.+)施放了(.+)。") do 
			return
		end
		for a,b,c in strgfind(msg, "(.-)对(.+)的(.+)免疫。") do 
			return
		end	
		--你的旋风斩被0xF13000EA56279AD6闪避过去了。
		for a,b,c in strgfind(msg, "你的(.+)被(.+)闪避过去了。") do 
			return
		end	
			--incStats("SpellSelfDamage", 13)
		--logUnhandledMsg("SpellSelfDamage", arg1, msg)
	end
	
	DPSMateX.Parser.PeriodicDamage = function(self, msg)
		--incStats("PeriodicDamage", 1)
		--毒液捕猎者的毒性充能使海水受到了996点自然伤害。(1504点被吸收)
		for d,e,a,b,c,f in strgfind(msg, "(.-)的(.+)使(.+)受到了(%d+)点(.+)伤害。%s?(.*)") do
			local val = tnbr(b)
			if d=="你" then d=self.player end
			if f~="" then
				local _,_,_,absorb=strfind(f,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), e..AbilityPeriodic, d) end
			end	
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, d, e..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, a, 0, 0)
			DB:DamageDone(d, e..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, 0, 0, a)
			if self.TargetParty[a] and self.TargetParty[d] then DB:BuildFail(1, a, d, e..AbilityPeriodic, val);DB:DeathHistory(a, d, e..AbilityPeriodic, val, 1, 0, 0, 0) end
			DB:AddSpellSchool(e..AbilityPeriodic,c)
			return
		end
			--incStats("PeriodicDamage", 2)
		for f,a in strgfind(msg, "(.+)受到了(.+)效果的影响") do
			return
		end
			--incStats("PeriodicDamage", 3)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)吸收了。") do
			DB:Absorb(a..AbilityPeriodic, b, f)
			return
		end
			--incStats("PeriodicDamage", 4)
		for a,b in strgfind(msg, "你的(.+)被(.+)吸收了。") do
			DB:Absorb(a..AbilityPeriodic, b, self.player)
			return
		end
			--incStats("PeriodicDamage", 5)
		--0xF13000F1FC2783E4的不稳定的法力从0x0000000000135FAE身上吸取了600点法力值。
		for a,b in strgfind(msg, "(.-)的(.+)从(.+)身上吸取了") do
			return
		end
			--incStats("PeriodicDamage", 6)
		--logUnhandledMsg("PeriodicDamage", arg1, msg)
	end
	
	DPSMateX.Parser.FriendlyOrHostilePlayerDamage = function(self, msg)
		--某法系的燃烧仇恨击中某法系造成226点火焰伤害。(75点被吸收)
			--incStats("FriendlyOrHostilePlayerDamage", 1)
		for f,a,b,c,g,e in strgfind(msg, "(.-)的(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if e~="" then
				if strfind(e, "点被格挡") then block=1;hit=0; end
				local _,_,_,absorb=strfind(e,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), a, f) end
			end
			if f == b then --suicide damage
				DB:DamageTaken(b, a, hit or 1, 0, 0, 0, 0, 0, amount, f, 0, 0)
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, b, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  hit or 1, 0, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(f, a, hit or 1, 0, 0, 0, 0, 0, amount, 0, block or 0, b)
			end
			if self.TargetParty[b] then if self.TargetParty[f] then DB:BuildFail(1, b, f, a, amount);end DB:DeathHistory(b, f, a, amount, 1, 0, 0, 0) end
			return
		end
		--某战士的血性狂暴对某战士造成159点致命一击伤害。
		--某骑士的十字军打击对某骑士造成415点致命一击伤害
			--incStats("FriendlyOrHostilePlayerDamage", 2)
		for f,a,b,x,c,y,e in strgfind(msg, "(.-)的(.+)对(.+)造成([了]*)(%d+)点([致命一击]*)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if e~="" then
				local _,_,_,absorb=strfind(e,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), a, f) end
			end
			if f == b then --suicide damage
				DB:DamageTaken(b, a, 0, 1, 0, 0, 0, 0, amount, f, 0, 0)
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, c, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  0, hit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(f, a, 0, hit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
			end
			if self.TargetParty[b] then if self.TargetParty[f] then DB:BuildFail(1, b, f, a, amount);end DB:DeathHistory(b, f, a, amount, 0, 1, 0, 0) end
			return
		end
		--某骑士的火焰打击致命一击对某骑士造成6点火焰伤害。
			--incStats("FriendlyOrHostilePlayerDamage", 3)
		for f,a,b,c,g,e in strgfind(msg, "(.-)的(.+)致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if e~="" then
				local _,_,_,absorb=strfind(e,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), a, f) end
			end
			if f == b then --suicide damage
				DB:DamageTaken(b, a, 0, 1, 0, 0, 0, 0, amount, f, 0, 0)
			else
				if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, b, GetTime()) end
				if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  0, hit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
				DB:DamageDone(f, a, 0, hit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
			end
			if self.TargetParty[b] then if self.TargetParty[f] then DB:BuildFail(1, b, f, a, amount); end DB:DeathHistory(b, f, a, amount, 0, 1, 0, 0) end
			DB:AddSpellSchool(a,g)
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 4)
		for a,b in strgfind(msg, "(.+)开始施放(.+)。")  do
			DB:RegisterPotentialKick(a, b, GetTime())
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 5)
		for a,b in strgfind(msg, "(.+)开始施展(.+)。")  do
			DB:RegisterPotentialKick(a, b, GetTime())
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 6)
		for c, b, a in strgfind(msg, "(.+)对(.+)使用(.+)。") do 
			return
		end
		for c, b, a in strgfind(msg, "(.+)对(.+)的(.+)免疫。") do 
			return
		end
		for c, a in strgfind(msg, "(.+)施放了(.+)。") do 
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 7)
		--0x00000000001234A1的神圣打击被闪躲过去。
		--你的雷霆一击被虛空地狱火闪避过去了。
		--xx的嘲讽被桑夫·塔斯达尔闪避过去。
		for f,b,a,c in strgfind(msg, "(.-)的(.+)被(.*)闪(.+)过去") do 
			if c=="避" then return end --aovid
			if a=="" then a=nil end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(f, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 8)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)招架了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 9)
		for f,a,b in strgfind(msg, "(.-)的(.+)没有击中(.+)。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 10)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)抵抗了。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 11)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)格挡过去。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 12)
		for who, whom, what in strgfind(msg, "(.+)打断了(.-)的(.+)。") do
			local usrId
			usrId, who = DB:BuildUser(who)
			local usr = DPSMateX.CacheUser[who]

			local causeAbility = "法术反制"
			if usr then
				if usr[2] == "priest" then
					causeAbility = "沉默"
				end
				-- Account for felhunter silence
				if usr[4] and usr[6] then
					local owner = DPSMateX:GetUserById(usr[6])
					if owner and DPSMateX.CacheUser[owner] then
						causeAbility = "法术封锁"
						who = owner
					end
				end
			end
			DB:Kick(who, whom, causeAbility, what)
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 13)
		for f,a,b in strgfind(msg, "(.-)的(.+)施放失败。(.+)对此免疫。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0, b)
			if DPSMateX.bTrackingThunderArmor and DPSMateX.Parser.TrackingSpell[f] then DPSMateX.Parser.TrackingSpell[f] = nil end
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 14)
		--0x00000000001AD58A的生命虹吸从0xF130003EBC01599F身上吸取了156点法力值，0x00000000001AD58A获得了156点法力值。
		for f,a,b,c,d in strgfind(msg, "(.-)的(.+)从(.+)身上吸取了(.-)点(.+)值") do 
			return
		end
			--0x00000000000320B2被奥术强化杀死了。
			--incStats("FriendlyOrHostilePlayerDamage", 15)
		for f,a in strgfind(msg, "(.-)被(.+)杀死了。") do 
			if f=="你" then f=self.player end
			DB:DeathHistory(f, f, a, 0, 1, 0, 0, 0)
			DB:UnregisterDeath(f) 
			DB:DestroyBuffs(f, "all")
			return
		end
			--0x000000000002D0B1的奥术增效被0xF13000F201276D67反弹回来。
			--incStats("FriendlyOrHostilePlayerDamage", 16)
		for f,a in strgfind(msg, "(.-)的(.+)被(.+)反弹回来。") do 
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 17)
		--logUnhandledMsg("FriendlyOrHostilePlayerDamage", arg1, msg)
	end
	
	DPSMateX.Parser.FriendlyOrHostilePlayerHits = function(self, msg)
			--incStats("FriendlyOrHostilePlayerHits", 1)
		for a,b,c,f,d in strgfind(msg, "(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if b=="你" then b=self.player end
			if d~="" then
				if strfind(d, "偏斜") then glance=1;crit=0 elseif strfind(d, "被格挡") then block=1;crit=0; end
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, a) end
			end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, crit or 1, 0, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, crit or 1, 0, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 1, 0, 0, 0) end
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 2)
		for a,b,c,d in strgfind(msg, "(.+)对(.+)造成(%d+)的致命一击伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if b == "你" then b=self.player end
			if d then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, a) end
			end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 0, 1, 0, 0) end
			return
		end
		--"0x00000000001234A1的致命一击对你造成616点伤害。"
			--incStats("FriendlyOrHostilePlayerHits", 3)
		for a,b,c,d in strgfind(msg, "(.+)的致命一击对(.+)造成(%d+)点伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if b == "你" then b=self.player end
			if d then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, a) end
			end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 0, 1, 0, 0) end
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 4)
		for a,b in strgfind(msg, "在岩浆中，(.+)损失了(%d+)生命值。") do
			DB:DamageTaken(a, "熔岩", 1, 0, 0, 0, 0, 0, tnbr(b), DPSMateX.L["Environment"], 0, 0)
			DB:DeathHistory(a, DPSMateX.L["Environment"], "熔岩", tnbr(b), 1, 0, 0, 0)
			DB:AddSpellSchool("熔岩","火焰")
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 5)
		for a,b in strgfind(msg, "(.+)受到(%d+)点火焰伤害。") do
			DB:DamageTaken(a, "火焰", 1, 0, 0, 0, 0, 0, tnbr(b), DPSMateX.L["Environment"], 0, 0)
			DB:DeathHistory(a, DPSMateX.L["Environment"], "火焰", tnbr(b), 1, 0, 0, 0)
			DB:AddSpellSchool("火焰","火焰")
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 6)
		for a,b in strgfind(msg, "(.+)从高处掉落损失(%d+)生命值。") do
			DB:DamageTaken(a, "下跌", 1, 0, 0, 0, 0, 0, tnbr(b), DPSMateX.L["Environment"], 0, 0)
			DB:DeathHistory(a, DPSMateX.L["Environment"], "下跌", tnbr(b), 1, 0, 0, 0)
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 7)
		for a,b in strgfind(msg, "(.+)现在处于溺水状态并损失(%d+)生命值。") do
			DB:DamageTaken(a, "溺死", 1, 0, 0, 0, 0, 0, tnbr(b), DPSMateX.L["Environment"], 0, 0)
			DB:DeathHistory(a, DPSMateX.L["Environment"], "溺死", tnbr(b), 1, 0, 0, 0)
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 8)
		for a,b in strgfind(msg, "在泥浆中，(.+)损失了(%d+)生命值。") do
			DB:DamageTaken(a, "泥浆", 1, 0, 0, 0, 0, 0, tnbr(b), DPSMateX.L["Environment"], 0, 0)
			DB:DeathHistory(a, DPSMateX.L["Environment"], "泥浆", tnbr(b), 1, 0, 0, 0)
			return
		end
			--incStats("FriendlyOrHostilePlayerHits", 9)
		--logUnhandledMsg("FriendlyOrHostilePlayerHits", arg1, msg)
	end
	
	DPSMateX.Parser.FriendlyPlayerMisses = function(self, msg)
			--incStats("FriendlyPlayerMisses", 1)
		for a,b in strgfind(msg, "(.+)没有击中(.+)。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
			--incStats("FriendlyPlayerMisses", 2)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)闪躲开了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
			--incStats("FriendlyPlayerMisses", 3)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)招架住了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
			--incStats("FriendlyPlayerMisses", 4)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)格挡住了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
			--incStats("FriendlyPlayerMisses", 5)
		for c,b in strgfind(msg, "(.+)发起攻击，(.+)吸收了所有伤害。") do
			if b=="你" then b=self.player end; 
			DB:Absorb(AbilityAutoAttack, b, c); 
			return 
		end
			--incStats("FriendlyPlayerMisses", 6)
		for a,b in strgfind(msg, "(.+)发起了攻击，但是(.+)对此免疫。") do 
			return 
		end
			--incStats("FriendlyPlayerMisses", 7)
		--logUnhandledMsg("FriendlyPlayerMisses", arg1, msg)
	end
	
	DPSMateX.Parser.SpellDamageShieldsOnSelf = function(self, msg)
			--incStats("SpellDamageShieldsOnSelf", 1)
		for source,a,b,c in strgfind(msg, "(.+)将(%d+)点(.+)伤害反弹给(.+)。") do 
			local val = tnbr(a)
			if source == "你" then source=self.player end
			b="反弹("..b..")"
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, source, b, 1, 0, 0, 0, 0, 0, val, c, 0, 0)
			DB:DamageDone(source, b, 1, 0, 0, 0, 0, 0, val, 0, 0)
			return
		end
			--incStats("SpellDamageShieldsOnSelf", 2)
		--logUnhandledMsg("SpellDamageShieldsOnSelf", arg1, msg)
	end
	
	DPSMateX.Parser.SpellDamageShieldsOnOthers = function(self, msg)
			--incStats("SpellDamageShieldsOnOthers", 1)
		for a,b,c,_,d in strgfind(msg, "(.+)将(%d+)点(.+)伤害反(.+)给(.+)。") do
			local val = tnbr(b)
			if d == "你" then d=self.player end
			if strfind(a, "%s") then
				DB:EnemyDamage(false, DPSMateX.DBCache.EDD, d, "棱光反射", 1, 0, 0, 0, 0, 0, val, a, 0, 0)
				DB:DamageTaken(d, "棱光反射", 1, 0, 0, 0, 0, 0, val, a, 0,0)
				DB:DeathHistory(d, a, "棱光反射", val, 1, 0, 0, 0)
			else
				DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, "棱光反射", 1, 0, 0, 0, 0, 0, val, d, 0, 0)
				DB:DamageDone(a, "棱光反射", 1, 0, 0, 0, 0, 0, val, 0, 0)
			end
			return
		end
			--incStats("SpellDamageShieldsOnOthers", 2)
		--0xF13000EA38279A14的破碎流放被抵抗了。
		for a,b,c in strgfind(msg, "(.-)的(.+)被(.*)抵抗了。") do
			return
		end
			--incStats("SpellDamageShieldsOnOthers", 3)
		for a,b in strgfind(msg, "(.+)的(.+)施放失败。") do
			return
		end
			--incStats("SpellDamageShieldsOnOthers", 4)
		--0xF13000EA552792EA的法力箭被0xF14000FC000000BB闪避过去。
		for a,b,c in strgfind(msg, "(.+)的(.+)被(.+)闪避过去。") do
			return
		end
		for a,b,c in strgfind(msg, "(.+)的(.+)被(.+)反弹回来。") do
			return
		end
		for a,b,c in strgfind(msg, "(.+)的(.+)没有击中(.+)。") do
			return
		end
			--incStats("SpellDamageShieldsOnOthers", 5)
		--logUnhandledMsg("SpellDamageShieldsOnOthers", arg1, msg)
	end
	
	----------------------------------------------------------------------------------
	--------------                    Damage taken                      --------------                                  
	----------------------------------------------------------------------------------

	DPSMateX.Parser.CreatureVsSelfHits = function(self, msg)
			--incStats("CreatureVsSelfHits", 1)
		for a,e,c,f,d in strgfind(msg, "(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crush, block, amount = nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if e=="你" then e=self.player end
			if d~= "" then
				if strfind(d, "碾压") then crush=1;hit=0; elseif strfind(d, "点被格挡") then block=1;hit=0; end
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, e) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(e, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(e, a, AbilityAutoAttack, amount, hit or 1, 0, 0, crush or 0)
			return
		end
			--incStats("CreatureVsSelfHits", 2)
		for a,e,c,d in strgfind(msg, "(.+)对(.+)造成(%d+)的致命一击伤害。%s?(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if e=="你" then e=self.player end
			if d~= "" then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, e) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(e, a, AbilityAutoAttack, amount, 0, crit or 1, 0, crush or 0)
			return
		end
			--incStats("CreatureVsSelfHits", 3)
		for a,e,c,f,d in strgfind(msg, "(.+)的致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if e=="你" then e=self.player end
			if d~= "" then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, e) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(e, a, AbilityAutoAttack, amount, 0, crit or 1, 0, crush or 0)
			return
		end
			--incStats("CreatureVsSelfHits", 4)
		--logUnhandledMsg("CreatureVsSelfHits", arg1, msg)
	end
	
	DPSMateX.Parser.CreatureVsSelfMisses = function(self, msg)
			--incStats("CreatureVsSelfMisses", 1)
		for a,e in strgfind(msg, "(.+)没有击中(.+)。") do 
			if e=="你" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsSelfMisses", 2)
		for a,e in strgfind(msg, "(.+)发起了攻击。(.+)闪躲开了。") do 
			local parry, dodge, block = nil, 1, nil
			if e=="你" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, block or 0, 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, 0, block or 0)
			return
		end
			--incStats("CreatureVsSelfMisses", 3)
		for a,e in strgfind(msg, "(.+)发起了攻击。(.+)招架住了。") do 
			local parry, dodge, block = 1, nil, nil
			if e=="你" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, block or 0, 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, 0, block or 0)
			return
		end
			--incStats("CreatureVsSelfMisses",4)
		for a,e in strgfind(msg, "(.+)发起了攻击。(.+)格挡住了。") do 
			local parry, dodge, block = nil, nil, 1
			if e=="你" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, block or 0, 0)
			DB:DamageTaken(e, AbilityAutoAttack, 0, 0, 0, parry or 0, dodge or 0, 0, 0, a, 0, block or 0)
			return
		end
			--incStats("CreatureVsSelfMisses",5)
		for a,b in strgfind(msg, "(.+)发起了攻击，但是(.+)对此免疫。") do 
			return 
		end
			--incStats("CreatureVsSelfMisses", 6)
		for c,e in strgfind(msg, "(.+)发起攻击，(.+)吸收了所有伤害。") do 
			if e=="你" then e=self.player end
			DB:Absorb(AbilityAutoAttack, e, c); 
			return 
		end
			--incStats("CreatureVsSelfMisses", 7)
		--logUnhandledMsg("CreatureVsSelfMisses", arg1, msg)
	end 
	
	DPSMateX.Parser.CreatureVsSelfSpellDamage = function(self, msg)
			--incStats("CreatureVsSelfSpellDamage", 1)
		for a,b,e,c,f,d in strgfind(msg, "(.-)的(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local val = tnbr(c)
			if e=="你" then e=self.player end
			if d~= "" then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), b, e) end
			end
			DB:UnregisterPotentialKick(e, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 1, 0, 0, 0, 0, 0, val, a, 0, 0)
			DB:DamageTaken(e, b, 1, 0, 0, 0, 0, 0, val, a, 0, 0)
			DB:DeathHistory(e, a, b, val, 1, 0, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, e, b, val) end
			DB:AddSpellSchool(b,f)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 2)
		for a,b,e,c,d in strgfind(msg, "(.-)的(.+)对(.+)造成(%d+)点致命一击伤害。%s?(.*)") do
			local val = tnbr(c)
			if e=="你" then e=self.player end
			if d~= "" then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), b, e) end
			end
			DB:UnregisterPotentialKick(e, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 1, 0, 0, 0, 0, val, a,  0, 0)
			DB:DamageTaken(e, b, 0, 1, 0, 0, 0, 0, val, a, 0, 0)
			DB:DeathHistory(e, a, b, val, 0, 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, e, b, val) end
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 3)
		for a,b,e,c,f,d in strgfind(msg, "(.-)的(.+)致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local val = tnbr(c)
			if e=="你" then e=self.player end
			if d~= "" then
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), b, e) end
			end
			DB:UnregisterPotentialKick(e, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 1, 0, 0, 0, 0, val, a, 0, 0)
			DB:DamageTaken(e, b, 0, 1, 0, 0, 0, 0, val, a, 0, 0)
			DB:DeathHistory(e, a, b, val, 0, 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, e, b, val) end
			DB:AddSpellSchool(b,f)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 4)
		for a,b,e in strgfind(msg, "(.-)的(.+)没有击中(.+)。") do
			if e=="你" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(e, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 5)
		for a,b,e in strgfind(msg, "(.-)的(.+)被(.*)招架了。") do
			if e=="" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(e, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 6)
		for a,b,e,c in strgfind(msg, "(.-)的(.+)被(.*)闪(.+)过去。") do
			if c=="避" then return end --aovid
			if e=="" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageTaken(e, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 7)
		for a,b,e in strgfind(msg, "(.-)的(.+)被(.*)抵抗了。") do
			if e=="" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			DB:DamageTaken(e, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 8)
		for a,b,e in strgfind(msg, "(.-)的(.+)被(.*)格挡过去。") do
			if e=="" then e=self.player end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, e, b, 0, 0, 0, 0, 0, 0, 0, a, 1, 0)
			DB:DamageTaken(e, b, 0, 0, 0, 0, 0, 0, 0, a, 0, 1)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 9)
		for e,a,b in strgfind(msg, "(.+)吸收了(.-)的(.+)。") do
			if e=="你" then e=self.player end
			DB:Absorb(b, e, a)
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 10)
		for a,e,b in strgfind(msg, "(.-)对(.-)使用(.+)。") do
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 11)
		for a,e,b in strgfind(msg, "(.-)对(.-)施放了(.+)。") do
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 12)
		for a,b,e in strgfind(msg, "(.-)的(.+)施放失败。(.+)对此免疫。") do 
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 13)
		for e, c, b, a in strgfind(msg, "(.+)对(.+)的(.+)免疫。") do 
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 14)
		for e, c, b, a in strgfind(msg, "(.-)的(.+)从(.+)身上吸取了(%d+)点") do 
			return
		end
			--incStats("CreatureVsSelfSpellDamage", 15)	
		--logUnhandledMsg("CreatureVsSelfSpellDamage", arg1, msg)
	end
	
	DPSMateX.Parser.PeriodicSelfDamage = function(self, msg)
			--incStats("PeriodicSelfDamage", 1)
		for cc,a,b,c,d,e,f in strgfind(msg, "(.-)受到(%d+)点(.+)伤害（(.-)的(.+)）(.*)。(.*)") do
			local val = tnbr(a)
			if c=="你" then c=self.player end
			if cc=="你" then cc=self.player end
			if f~="" then
				local _,_,_,absorb=strfind(f,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), d..AbilityPeriodic, c) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, cc, d..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, c, 0, 0)
			DB:DamageTaken(cc, d..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, c, 0, 0)
			DB:DeathHistory(cc, c, d..AbilityPeriodic, val, 1, 0, 0, 0)
			if self.FailDT[d] then DB:BuildFail(2, c, cc, d, val) end
			DB:AddSpellSchool(d..AbilityPeriodic,b)
			return
		end
			--incStats("PeriodicSelfDamage", 2)
		for c,a in strgfind(msg, "(.-)受到了(.+)效果的影响([（1）]*)。") do
			if c=="你" then c=self.player end
			DB:BuildBuffs(DB.UserUnknown, c, a, false)
			DB:FillDebuffType(c, a)
			if self.CC[a] then DB:BuildActiveCC(c, a) end
			return
		end
		--stack more
			--incStats("PeriodicSelfDamage", 3)
		for c,a in strgfind(msg, "(.-)受到了(.+)效果的影响") do
			return
		end
			--incStats("PeriodicSelfDamage", 4)
		for c,a,b in strgfind(msg, "(.-)吸收了(.-)的(.+)。") do
			if c=="你" then c=self.player end
			DB:Absorb(b..AbilityPeriodic, c, a)
			return
		end
			--incStats("PeriodicSelfDamage", 5)
		for c,d,cc,a,b,f in strgfind(msg, "(.-)的(.+)使(.+)受到(%d+)点(.+)伤害。(.*)") do
			local val = tnbr(a)
			if c=="你" then c=self.player end
			if cc=="你" then cc=self.player end
			if f~="" then
				local _,_,_,absorb=strfind(f,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), d..AbilityPeriodic, c) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, cc, d..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, c, 0, 0)
			DB:DamageTaken(cc, d..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, c, 0, 0)
			DB:DeathHistory(cc, c, d..AbilityPeriodic, val, 1, 0, 0, 0)
			if self.FailDT[d] then DB:BuildFail(2, c, cc, d, val) end
			DB:AddSpellSchool(d..AbilityPeriodic,b)
			return
		end
			--incStats("PeriodicSelfDamage", 6)
		--logUnhandledMsg("PeriodicSelfDamage", arg1, msg)
	end
	
	DPSMateX.Parser.CreatureVsCreatureHits = function(self, msg) 
			--incStats("CreatureVsCreatureHits", 1)
		for a,c,d,g,e in strgfind(msg, "(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(d)
			--t = {nil, nil, nil, nil, tnbr(d)}
			if e~= "" then
				if strfind(e, "碾压") then crush=1;hit=0;crit=0 elseif strfind(e, "点被格挡") then block=1;hit=0;crit=0 end
				local _,_,_,absorb = strfind(e,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, c) end
			end
			
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(c, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(c, a, AbilityAutoAttack, amount, hit or 1, 0, 0, crush or 0)
			return
		end
			--incStats("CreatureVsCreatureHits", 2)
		for a,c,d,e in strgfind(msg, "(.+)对(.+)造成(%d+)的致命一击伤害。(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(d)
		 	--t = {nil, nil, nil, nil, tnbr(d)}
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(c, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(c, a, AbilityAutoAttack, amount, 0, crit or 1, 0, crush or 0)
			return
		end
			--incStats("CreatureVsCreatureHits", 3)
		--0xF13000EA412797A6的致命一击对0x00000000000F85A2造成2130点暗影伤害。
		for a,c,d,f,e in strgfind(msg, "(.+)的致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(d)
		 	--t = {nil, nil, nil, nil, tnbr(d)}
			if d~="" then
				if strfind(d, "偏斜") then glance=1;crit=0 elseif strfind(d, "被格挡") then block=1;crit=0; end
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, a) end
			end
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, crush or 0)
			DB:DamageTaken(c, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, a, crush or 0, block or 0)
			DB:DeathHistory(c, a, AbilityAutoAttack, amount, 0, crit or 1, 0, crush or 0)
			return
		end
			--incStats("CreatureVsCreatureHits", 4)
		--logUnhandledMsg("CreatureVsCreatureHits", arg1, msg)
	end
	
	DPSMateX.Parser.CreatureVsCreatureMisses = function(self, msg)
			--incStats("CreatureVsCreatureMisses", 1)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)格挡住了。") do 
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, b, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, a, 1, 0)
			DB:DamageTaken(b, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, a, 0, 1)
			return
		end
			--incStats("CreatureVsCreatureMisses", 2)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)闪躲开了。") do 
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, b, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageTaken(b, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsCreatureMisses", 3)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)招架住了。") do 
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, b, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(b, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureVsCreatureMisses", 4)
		for a,b in strgfind(msg, "(.+)发起了攻击，但是(.+)对此免疫。") do 
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, b, AbilityAutoAttack, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			DB:DamageTaken(b, AbilityAutoAttack, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			return 
		end
			--incStats("CreatureVsCreatureMisses", 5)
		for a,b in strgfind(msg, "(.+)没有击中(.+)。") do 
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, b, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(b, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			return 
		end
		 	--incStats("CreatureVsCreatureMisses", 6)
		for c, ta in strgfind(msg, "(.+)发起攻击，(.+)吸收了所有伤害。") do
			 DB:Absorb(AbilityAutoAttack, ta, c); 
			 return 
		 end
		 	--incStats("CreatureVsCreatureMisses", 7)
		--logUnhandledMsg("CreatureVsCreatureMisses", arg1, msg)
	end
	
	DPSMateX.Parser.SpellPeriodicDamageTaken = function(self, msg)
		--黑女巫法琳娜的毒箭之雨使XX受到了369点自然伤害。(103点被吸收)
			--incStats("SpellPeriodicDamageTaken", 1)
		for d,e,a,b,c,f in strgfind(msg, "(.-)的(.+)使(.+)受到了(%d+)点(.+)伤害。%s?(.*)") do
			local val = tnbr(b)

			if f~="" then
				local _,_,_,absorb=strfind(f,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), e..AbilityPeriodic, d) end
			end	
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, a, e..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, d, 0, 0)
			DB:DamageTaken(a, e..AbilityPeriodic, 1, 0, 0, 0, 0, 0, val, d, 0, 0)
			DB:DeathHistory(a, d, e..AbilityPeriodic, val, 1, 0, 0, 0)
			if self.FailDT[e] then DB:BuildFail(2, d, a, e, val) end
			DB:AddSpellSchool(e..AbilityPeriodic,c)
			return
		end
			--incStats("SpellPeriodicDamageTaken", 2)
		for f,a in strgfind(msg, "(.+)受到了(.+)效果的影响([（1）]*)。") do
			DB:BuildBuffs(DB.UserUnknown, f, a, false)
			DB:FillDebuffType(f, a)
			if self.CC[a] then DB:BuildActiveCC(f, a) end
			return
		end
		--stack more
			--incStats("SpellPeriodicDamageTaken", 3)
		for f,a in strgfind(msg, "(.+)受到了(.+)效果的影响") do
			return
		end
			--incStats("SpellPeriodicDamageTaken", 4)
		--0x00000000001AD58A的艾露恩的黄昏从0xF130004043015ADB身上吸取了100点法力值。
		for f,a in strgfind(msg, "(.+)的(.+)从(.+)身上吸取了") do
			return
		end
		--for a, b in strgfind(msg, "(.+)受到(.+)的伤害") do
		--	DB:BuildBuffs(DB.UserUnknown, a, b, false)
		--	if self.CC[b] then DB:BuildActiveCC(a, b) end
		--	return
		--end
			--incStats("SpellPeriodicDamageTaken", 5)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)吸收了。") do
			DB:Absorb(a..AbilityPeriodic, f, b)
			return
		end
			--incStats("SpellPeriodicDamageTaken", 6)
		--logUnhandledMsg("SpellPeriodicDamageTaken", arg1, msg)
	end
	
	DPSMateX.Parser.CreatureSpellDamage = function(self, msg)
			--incStats("CreatureSpellDamage", 1)
		for a,b,d,e,h,f in strgfind(msg, "(.-)的(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(e)
			--t = {nil, nil, tnbr(e), nil}
			if f~= "" then
				if strfind(f, "点被格挡") then block=1;hit=0 end
			end
			DB:UnregisterPotentialKick(d, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, d, b, hit or 1, 0, 0, 0, 0, 0, amount, a, block or 0, 0)
			DB:DamageTaken(d, b, hit or 1, 0, 0, 0, 0, 0, amount, a, 0, block or 0)
			DB:DeathHistory(d, a, b, amount, hit or 1, 0, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, d, b, amount) end
			DB:AddSpellSchool(b,h)
			return
		end
			--incStats("CreatureSpellDamage", 2)
		for a,b,d,e,f in strgfind(msg, "(.-)的(.+)对(.+)造成(%d+)点致命一击伤害。(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(e)
		 	--t = {false, false, tnbr(e), false}
			DB:UnregisterPotentialKick(d, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, d, b, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, 0)
			DB:DamageTaken(d, b, 0, crit or 1, 0, 0, 0, 0, amount, a, 0, block or 0)
			DB:DeathHistory(d, a, b, amount, 0, crit or 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, d, b, amount) end
			return
		end
			--incStats("CreatureSpellDamage", 3)
		for a,b,d,e,f,g in strgfind(msg, "(.-)的(.+)致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, crush, block, amount = nil, nil, nil, nil, tnbr(e)
			--t = {false, false, tnbr(e), false}
			DB:UnregisterPotentialKick(d, b, GetTime())
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, d, b, 0, crit or 1, 0, 0, 0, 0, amount, a, block or 0, 0)
			DB:DamageTaken(d, b, 0, crit or 1, 0, 0, 0, 0, amount, a, 0, block or 0)
			DB:DeathHistory(d, a, b, amount, 0, crit or 1, 0, 0)
			if self.FailDT[b] then DB:BuildFail(2, a, d, b, amount) end
			DB:AddSpellSchool(b,f)
			return
		end
			--incStats("CreatureSpellDamage", 4)
		for a,b,c,d in strgfind(msg, "(.-)的(.+)被(.+)闪(.+)过去。") do
			if d=="避" then return end --aovid
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureSpellDamage", 5)
		for a,b,c in strgfind(msg, "(.-)的(.+)被(.+)招架了。") do
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 1, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureSpellDamage", 6)
		for a,b,c in strgfind(msg, "(.-)的(.+)没有击中(.+)。") do
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 1, 0, 0, 0, 0, a, 0, 0)
			return
		end
			--incStats("CreatureSpellDamage", 7)
		for a,b,c in strgfind(msg, "(.-)的(.+)被(.+)抵抗了。") do
			DB:EnemyDamage(false, DPSMateX.DBCache.EDD, c, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			DB:DamageTaken(c, b, 0, 0, 0, 0, 0, 1, 0, a, 0, 0)
			return
		end
			--incStats("CreatureSpellDamage", 8)
		for f,a in strgfind(msg, "(.-)开始施(.+)。") do
			return
		end
			--incStats("CreatureSpellDamage", 9)
		for c, b, a in strgfind(msg, "(.+)对(.+)使用(.+)。") do 
			return
		end
		for c, b, a in strgfind(msg, "(.+)对(.+)施放了(.+)。") do 
			return
		end
			--incStats("CreatureSpellDamage", 10)
		--0xF13000EA3F276C05施放了罪孽深重。
		for c, b in strgfind(msg, "(.+)施放了(.+)。") do 
			return
		end
			--incStats("CreatureSpellDamage", 11)
		for a,b in strgfind(msg, "(.-)的(.+)施放失败。(.+)对此免疫。") do 
			return
		end
		--0x0000000000214F36对0xF13000EA5F279403的血之撕裂免疫。
			--incStats("CreatureSpellDamage", 12)
		for a,b in strgfind(msg, "(.-)对(.+)的(.+)免疫。") do 
			return
		end
			--incStats("CreatureSpellDamage", 13)
		for a,b in strgfind(msg, "(.-)被(.+)杀死了。") do 
			return
		end
			--incStats("CreatureSpellDamage", 14)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)吸收了。") do
			DB:Absorb(a, f, b)
			return
		end
			--incStats("CreatureSpellDamage", 15)
		--幻象：燃棘狂战士的灼热箭被0xF13000F201276D66反弹回来。
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)反弹回来。") do 
			return
		end
			--incStats("CreatureSpellDamage", 16)
		for f,a,b,c,d,e in strgfind(msg, "(.-)的(.+)从(.+)身上(.+)了(%d+)点(.+)") do
			return
		end
			--incStats("FriendlyOrHostilePlayerDamage", 17)
		--logUnhandledMsg("CreatureSpellDamage", arg1, msg)
		--0xF13000215C01684A开始施放女妖诅咒。
		--0xF1300040BD2792F4的蛛网施放失败。0x0000000000130B36对此免疫。
		--0xF1300040BD2792F4对xx使用眩晕.
	end

	----------------------------------------------------------------------------------
	--------------                       Healing                        --------------                                  
	----------------------------------------------------------------------------------
	
	local HealingStream = "治疗之泉"
	DPSMateX.Parser.SpellSelfBuff = function(self, msg)
			--incStats("SpellSelfBuff", 1)
		for a in strgfind(msg, "你从(.*)获得了(.*)") do 
			return true
		end
			--incStats("SpellSelfBuff", 2)
		for a,b,c in strgfind(msg, "你的(.+)对(.+)产生极效治疗效果，恢复了(%d+)点生命值。") do 
			local val = tnbr(c)
			overheal = self:GetOverhealByName(val, b)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, b, a, 0, 1, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, b, a, 0, 1, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, a, 0, 1, val-overheal, b)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, a, 0, 1, overheal, b)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, b, a, 0, 1, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, a, 0, 1, val, b)
			DB:DeathHistory(b, self.player, a, val, 0, 1, 1, 0)
			return true
		end
			--incStats("SpellSelfBuff", 3)
		for a,c in strgfind(msg, "你的(.+)对你造成极效治疗，恢复了(%d+)点生命值。") do 
			local val = tnbr(c)
			overheal = self:GetOverhealByName(val, self.player)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, self.player, a, 0, 1, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, self.player, a, 0, 1, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, a, 0, 1, val-overheal, self.player)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, a, 0, 1, overheal, self.player)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, self.player, a, 0, 1, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, a, 0, 1, val, self.player)
			DB:DeathHistory(self.player, self.player, a, val, 0, 1, 1, 0)
			return true
		end
			--incStats("SpellSelfBuff", 4)
		--for superwow
		-- 某些msbt版本修改了日志格式，b后面多了个空格，导致无法正确解析，增加%s*增加兼容性
		for a,b,c in strgfind(msg, "你的(.+)治疗了0x(................)%s*(%d+)点生命值。") do 
			local val = tnbr(c)
			b = "0x"..b
			overheal = self:GetOverhealByName(val, b)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, b, a, 1, 0, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, b, a, 1, 0, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, a, 1, 0, val-overheal, b)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, a, 1, 0, overheal, b)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, b, a, 1, 0, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, a, 1, 0, val, b)
			DB:DeathHistory(b, self.player, a, val, 1, 0, 1, 0)
			if self.procs[a] and not self.OtherExceptions[a] then
				DB:BuildBuffs(self.player, self.player, a, true)
			end
			return true
		end
			--incStats("SpellSelfBuff", 5)
		-- Thanks to korolevlong
		-- 某些msbt版本修改了日志格式，b后面多了个空格，导致无法正确解析，(.+[^0-9])改为(.-)%s*增加兼容性
		for a,b,c in strgfind(msg, "你的(.+)治疗了(.-)%s*(%d+)点生命值。") do 
			local val = tnbr(c)
			if b=="你" then b=self.player end
			overheal = self:GetOverhealByName(val, b)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, b, a, 1, 0, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, b, a, 1, 0, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, a, 1, 0, val-overheal, b)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, a, 1, 0, overheal, b)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, b, a, 1, 0, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, a, 1, 0, val, b)
			DB:DeathHistory(b, self.player, a, val, 1, 0, 1, 0)
			if self.procs[a] and not self.OtherExceptions[a] then
				DB:BuildBuffs(self.player, self.player, a, true)
			end
			return true
		end
			--incStats("SpellSelfBuff", 6)
		for a,b in strgfind(msg, "你获得了(%d+)点(.+)。") do
			if self.procs[b] and not self.OtherExceptions[b] then
				DB:BuildBuffs(self.player, self.player, b, true)
				DB:DestroyBuffs(self.player, b)
			end
			return true
		end
			--incStats("SpellSelfBuff", 7)
		for b,f,a in strgfind(msg, "你通过(.+)获(.*)(%d+)次额外攻击。") do
			DB:RegisterNextSwing(self.player, tnbr(a), b)
			DB:BuildBuffs(self.player, self.player, b, true)
			DB:DestroyBuffs(self.player, b)
			return true
		end	
			--incStats("SpellSelfBuff", 8)
		for a in strgfind(msg, "你使用(.+)。") do
			return true
		end		
		
		for tar, ab in strgfind(msg, "你对(.+)施放了(.+)。") do 
			if self.HotDispels[ab] then DB:RegisterHotDispel(tar, ab, self.player) end; 
			if self.Dispels[ab] then DB:TryDispel(ab, tar, self.player, GetTime()) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(2, self.player, tar, ab) end; 
			return true
		end
			--incStats("SpellSelfBuffDispels", 2)
		for ab in strgfind(msg, "你施放了(.+)。") do 
			if self.TotemDispels[ab] then 
				DB:CastDispelTotem(ab, self.player, GetTime()) 
			elseif self.Dispels[ab] then 
				DB:TryDispel(ab, self.player, self.player, GetTime())
			end; 
			return true
		end
			--incStats("SpellSelfBuff", 9)
		--logUnhandledMsg("SpellSelfBuff", arg1, msg)
	end
	
	DPSMateX.Parser.SpellPeriodicSelfBuff = function(self, msg)
		--你从血性狂暴获得了1点怒气。
			--incStats("SpellPeriodicSelfBuff", 1)
		for u,f,a,b in strgfind(msg, "(.-)从(.-)获得了(%d+)点(.+)。") do
			return
		end
		--你从银白之刃的强效智慧祝福获得了36点法力值。
			--incStats("SpellPeriodicSelfBuff", 2)
		for u,f,a,b,c in strgfind(msg, "(.-)从(.-)的(.+)获得了(%d+)点(.+)。") do
			return
		end
			--incStats("SpellPeriodicSelfBuff", 3)
		for b,c,a in strgfind(msg, "你因(.-)的(.+)而获得了(%d+)点生命值。") do
			local val = tnbr(a)
			if c==HealingStream then
				b = self:AssociateShaman(self.player, b, false)
			end
			overheal = self:GetOverhealByName(val, self.player)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, self.player, c..AbilityPeriodic, 1, 0, val, b)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, self.player, c..AbilityPeriodic, 1, 0, val-overheal, b)
			DB:Healing(0, DPSMateX.DBCache.EHealing, b, c..AbilityPeriodic, 1, 0, val-overheal, self.player)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, b, c..AbilityPeriodic, 1, 0, overheal, self.player)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, self.player, c..AbilityPeriodic, 1, 0, overheal, b)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, b, c..AbilityPeriodic, 1, 0, val, self.player)
			DB:DeathHistory(self.player, b, c..AbilityPeriodic, val, 1, 0, 1, 0)
			return
		end
			--incStats("SpellPeriodicSelfBuff", 5)
		for f, a, stacks in strgfind(msg, "(.+)获得了(.+)的效果（(%d+)）。") do
			if f=="你" then f=self.player end --也可能是宠物
			if self.BuffExceptions[a] then return end

			if self.BuffStackMatters[a] then
				self.BuffStacking = self.BuffStacking or {}
				self.BuffStacking[f] = self.BuffStacking[f] or {}

				local cur_stack = self.BuffStacking[f][a] or 0
				self.BuffStacking[f][a] = tnbr(stacks)

				for i = cur_stack + 1, tnbr(stacks) do
					local suffix = (i == 1) and "" or "("..i..")"
					DB:ConfirmBuff(f, a..suffix, GetTime())
				end
			else
				DB:ConfirmBuff(f, a, GetTime())
			end

			if self.HotDispels[a] then 
				DB:RegisterHotDispel(f, a)
			end
			if self.RCD[a] then DPSMateX:Broadcast(1, f, a) end
			if self.FailDB[a] then DB:BuildFail(3, DPSMateX.L["Environment"], f, a, 0) end
			return 
		end
			--incStats("SpellPeriodicSelfBuff", 6)
		for f, a in strgfind(msg, "(.+)获得了(.+)的效果。") do
			if f=="你" then f=self.player end --也可能是宠物
			if self.BuffExceptions[a] then return end
	
			DB:ConfirmBuff(f, a, GetTime())

			if self.HotDispels[a] then 
				DB:RegisterHotDispel(f, a)
			end
			if self.RCD[a] then DPSMateX:Broadcast(1, f, a) end
			if self.FailDB[a] then DB:BuildFail(3, DPSMateX.L["Environment"], f, a, 0) end
			return 
		end
			--incStats("SpellPeriodicSelfBuff", 7)
		for b,a in strgfind(msg, "你因(.+)而获得了(%d+)点生命值。") do 
			local val = tnbr(a)
			overheal = self:GetOverhealByName(val, self.player)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, self.player, b..AbilityPeriodic, 1, 0, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, self.player, b..AbilityPeriodic, 1, 0, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, b..AbilityPeriodic, 1, 0, val-overheal, self.player)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, b..AbilityPeriodic, 1, 0, overheal, self.player)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, self.player, b..AbilityPeriodic, 1, 0, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, b..AbilityPeriodic, 1, 0, val, self.player)
			DB:DeathHistory(self.player, self.player, b..AbilityPeriodic, val, 1, 0, 1, 0)
			return
		end
			--incStats("SpellPeriodicSelfBuff", 8)
		--logUnhandledMsg("SpellPeriodicSelfBuff", arg1, msg)
	end
	
	DPSMateX.Parser.SpellPeriodicFriendlyOrHostilePlayerBuffs = function(self, msg)
		--忽略周期性获得资源
		--银白之刃从银白之刃的强效智慧祝福获得了36点法力值。
		--杨慢逵从老酒瓶的喂养宠物效果获得了35点快乐。
		--大草原的湖边从大草原的湖边的血性狂暴获得了1点怒气。
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 1)
		for f,a,b,c,d in strgfind(msg, "(.+)从(.-)的(.+)获得了(%d+)点(.+)。") do
			return
		end
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 2)
		for f,a,b in strgfind(msg, "(.+)获得了(.+)的效果([（1）]*)。") do
			if self.BuffExceptions[a] then return end
	
			DB:ConfirmBuff(f, a, GetTime())
			if self.HotDispels[a] then 
				DB:RegisterHotDispel(f, a)
			end
			if self.RCD[a] then DPSMateX:Broadcast(1, f, a) end
			if self.FailDB[a] then DB:BuildFail(3, self.player, f, a, 0) end
			return 
		end
		--[[
		--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 3)
		for f,a,b in strgfind(msg, "(.+)获得(%d+)点生命值（你的(.+)）。") do
			local val = tnbr(a)
			overheal = self:GetOverhealByName(val, f)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, f, b..AbilityPeriodic, 1, 0, val, self.player)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, f, b..AbilityPeriodic, 1, 0, val-overheal, self.player)
			DB:Healing(0, DPSMateX.DBCache.EHealing, self.player, b..AbilityPeriodic, 1, 0, val-overheal)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, self.player, b..AbilityPeriodic, 1, 0, overheal)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, f, b..AbilityPeriodic, 1, 0, overheal, self.player)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, self.player, b..AbilityPeriodic, 1, 0, val)
			DB:DeathHistory(f, self.player, b..AbilityPeriodic, val, 1, 0, 1, 0)
			return
		end
		--]]
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 3)
		for f,a,b,c in strgfind(msg, "(.+)获得(%d+)点生命值（(.-)的(.+)）。") do
			local val = tnbr(a)
			if c==HealingStream then
				b = self:AssociateShaman(a, b, false)
			end
			if b=="你" then b=self.player end
			overheal = self:GetOverhealByName(val, f)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, f, c..AbilityPeriodic, 1, 0, val, b)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, f, c..AbilityPeriodic, 1, 0, val-overheal, b)
			DB:Healing(0, DPSMateX.DBCache.EHealing, b, c..AbilityPeriodic, 1, 0, val-overheal, f)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, b, c..AbilityPeriodic, 1, 0, overheal, f)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, f, c..AbilityPeriodic, 1, 0, overheal, b)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, b, c..AbilityPeriodic, 1, 0, val, f)
			DB:DeathHistory(f, b, c..AbilityPeriodic, val, 1, 0, 1, 0)
			return
		end
		--stack more
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 4)
		for f,a,b in strgfind(msg, "(.+)获得了(.+)的效果") do
			return
		end
		--[[
		for f,a in strgfind(msg, "(.+)获得了(.+)。") do
			if self.BuffExceptions[a] then return end
			DB:ConfirmBuff(f, a, GetTime())
			if self.HotDispels[a] then
				DB:RegisterHotDispel(f, a)
			end
			if self.RCD[a] then DPSMateX:Broadcast(1, f, a) end
			if self.FailDB[a] then DB:BuildFail(3, f, f, a, 0) end
			return 
		end
		--]]
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 6)
			--银白之刃的生命虹吸从银白之刃身上吸取了获得了36点法力值,xxx获得了xxx点法力值。
		for f,a,b,c,d,e in strgfind(msg, "(.-)的(.+)从(.+)身上(.+)了(%d+)点(.+)") do
			return
		end
			--incStats("SpellPeriodicFriendlyOrHostilePlayerBuffs", 7)
		--logUnhandledMsg("SpellPeriodicFriendlyOrHostilePlayerBuffs", arg1, msg)
	end

	DPSMateX.Parser.SpellFriendlyOrlHostilePlayerBuff = function(self, msg)
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 1)
		--XX从XX的强效智慧祝福获得了39点法力值。
		for f,a,b,c,d in strgfind(msg, "(.+)从(.-)的(.+)获得了(%d+)点(.+)。") do
			return true
		end
		--有才的爪子的吸血鬼的拥抱发挥极效，为某玩家恢复了95点生命值？
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 2)
		for user,a,target,amount in strgfind(msg, "(.-)的(.+)为(.+)恢复了(%d+)点生命值。") do 
			local hit,crit
			local _,_,ability=strfind(a, "(.+)发挥极效，")
			hit = ability and 0 or 1
			crit = 1 - hit
			ability = ability or a

			if not DB.has_superwow then
				for aa,bb in strgfind(user, "(.+)的(.+)") do
					--aa == 有才的爪子, bb == 拥抱
					local bbb = bb.."的"..ability
					if DPSMateX.BabbleSpellX:HasReverseTranslation(bbb) then
						user = aa
						ability = bbb
					end
					break
				end
			end
			local val = tnbr(amount)

			if target=="你" then target=self.player end
			overheal = self:GetOverhealByName(val, target)
			DB:HealingTaken(0, DPSMateX.DBCache.HealingTaken, target, ability, hit, crit, val, user)
			DB:HealingTaken(1, DPSMateX.DBCache.EHealingTaken, target, ability, hit, crit, val-overheal, user)
			DB:Healing(0, DPSMateX.DBCache.EHealing, user, ability, hit, crit, val-overheal, target)
			if overheal>0 then 
				DB:Healing(2, DPSMateX.DBCache.Overhealing, user, ability, hit, crit, overheal, target)
				DB:HealingTaken(2, DPSMateX.DBCache.OverhealingTaken, target, ability, hit, crit, overheal, user)
			end
			DB:Healing(1, DPSMateX.DBCache.THealing, user, ability, hit, crit, val, target)
			DB:DeathHistory(target, user, ability, val, hit, crit, 1, 0)

			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 3)
		for a,b in strgfind(msg, "(.+)开始施放(.+)。")  do
			DB:RegisterPotentialKick(a, b, GetTime())
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 4)
		for c, ta, ab in strgfind(msg, "(.+)对(.+)施放了(.+)。") do 
			if ta=="你" then ta = self.player end; 
			if self.HotDispels[ab] then DB:RegisterHotDispel(ta, ab, c) end; 
			if self.Dispels[ab] then DB:TryDispel(ab, ta, c, GetTime()) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(2, c, ta, ab) end; 
			return true
		end
		for c, ab in strgfind(msg, "(.+)施放了(.+)。") do 
			if self.TotemDispels[ab] then 
				DB:CastDispelTotem(ab, c, GetTime())
			elseif self.Dispels[ab] then 
				DB:TryDispel(ab, c, c, GetTime())
			end 
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 5)
		for a,b in strgfind(msg, "(.+)开始施展(.+)。")  do
			DB:RegisterPotentialKick(a, b, GetTime())
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 6)
		for c, ab in strgfind(msg, "(.+)使用(.+)。") do 
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 7)
		for a,c,b in strgfind(msg, "(.+)通过(.+)获得了(%d+)次额外攻击。") do
			DB:RegisterNextSwing(a, tnbr(b), c)
			DB:BuildBuffs(a, a, c, true)
			DB:DestroyBuffs(a, c)
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 8)
		for a,b,d in strgfind(msg, "(.+)获得(%d+)点(.+)。") do
			if self.procs[d] and not self.OtherExceptions[d] then
				DB:BuildBuffs(a, a, d, true)
				DB:DestroyBuffs(a, d)
			end
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 9)
		--0x00000000000940E1的吸血鬼的拥抱施放失败。0x000000000006A7CB对此免疫。
		--0x00000000001A1EB6的治疗链施放失败。0x0000000000092792对此免疫。
		for a,b,c in strgfind(msg, "(-)的(.+)施放失败。(.+)对此免疫。") do
			return true
		end
			--incStats("SpellFriendlyOrlHostilePlayerBuff", 10)
	end
	
	----------------------------------------------------------------------------------
	--------------                       Absorbs                        --------------                                  
	----------------------------------------------------------------------------------
	DPSMateX.Parser.CreatureVsSelfHitsAbsorb = function(self, msg)
	end
	
	DPSMateX.Parser.CreatureVsCreatureHitsAbsorb = function(self, msg) end
	
	DPSMateX.Parser.CreatureVsSelfSpellDamageAbsorb = function(self, msg)
	end
	
	DPSMateX.Parser.CreatureSpellDamageAbsorb = function(self, msg) end
	
	DPSMateX.Parser.SpellPeriodicSelfBuffAbsorb = function(self, msg)
			--incStats("SpellPeriodicSelfBuffAbsorb", 1)
		for ab in strgfind(msg, "你获得了(.+)的效果([（1）]*)。") do if DB.ShieldFlags[ab] then DB:ConfirmAbsorbApplication(ab, self.player, GetTime()) end end
	end

	DPSMateX.Parser.SpellPeriodicFriendlyPlayerBuffsAbsorb = function(self, msg)
			--incStats("SpellPeriodicFriendlyPlayerBuffsAbsorb", 1)
		for ta, ab in strgfind(msg, "(.+)获得了(.+)的效果([（1）]*)。") do if DB.ShieldFlags[ab] then DB:ConfirmAbsorbApplication(ab, ta, GetTime()) end end
	end
	
	DPSMateX.Parser.SpellAuraGoneSelf = function(self, msg)
			--incStats("SpellAuraGoneSelf", 1)
		for ab in strgfind(msg, "(.+)效果从你身上消失了。") do 
			if self.BuffExceptions[ab] then return end; 
			
			if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, self.player) end; 
			if DPSMateX.ShieldHealDetect and DB.ShieldAsHeal[ab] then DB:RemoveShieldAsHeal(ab, self.player) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(6, self.player, ab) end; 

			local maxstacks = self.BuffStackMatters[ab]
			if maxstacks then
				self.BuffStacking = self.BuffStacking or {}
				self.BuffStacking[self.player] = self.BuffStacking[self.player] or {}

				local cur_stacks = self.BuffStacking[self.player][ab] or 1
				for i=1,cur_stacks do
					local suffix = (i == 1) and "" or "("..i..")"
					DB:DestroyBuffs(self.player, ab..suffix)
				end

				self.BuffStacking[self.player][ab] = 0
			else
				DB:DestroyBuffs(self.player, ab)
			end

			if self.HotDispels[ab] then DB:UnregisterHotDispel(self.player, ab) end
			DB:RemoveActiveCC(self.player, ab)
		end
	end
	
	DPSMateX.Parser.SpellAuraGoneParty = function(self, msg)
			--incStats("SpellAuraGoneParty", 1)
		for ab, ta in strgfind(msg, "(.+)效果从(.+)身上消失。") do 
			if self.BuffExceptions[ab] then return end; 
			
			if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, ta) end; 
			if DPSMateX.ShieldHealDetect and DB.ShieldAsHeal[ab] then DB:RemoveShieldAsHeal(ab, ta) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(6, ta, ab) end; 
			DB:DestroyBuffs(ta, ab); 
			if self.HotDispels[ab] then DB:UnregisterHotDispel(ta, ab) end
			DB:RemoveActiveCC(ta, ab) 
		end
	end
	
	DPSMateX.Parser.SpellAuraGoneOther = function(self, msg)
			--incStats("SpellAuraGoneOther", 1)
		for ab, ta in strgfind(msg, "(.+)效果从(.+)身上消失。") do 
			if self.BuffExceptions[ab] then return end; 
	
			if DB.ShieldFlags[ab] then DB:UnregisterAbsorb(ab, ta) end; 
			if DPSMateX.ShieldHealDetect and DB.ShieldAsHeal[ab] then DB:RemoveShieldAsHeal(ab, ta) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(6, ta, ab) end; 
			DB:DestroyBuffs(ta, ab); 
			if self.HotDispels[ab] then DB:UnregisterHotDispel(ta, ab) end
			DB:RemoveActiveCC(ta, ab) 
		end
	end
	
	----------------------------------------------------------------------------------
	--------------                       Dispels                        --------------                                  
	----------------------------------------------------------------------------------
	
	DPSMateX.Parser.SpellSelfBuffDispels = function(self, msg)
			--incStats("SpellSelfBuffDispels", 1)
		for tar, ab in strgfind(msg, "你对(.+)施放了(.+)。") do 
			if self.HotDispels[ab] then DB:RegisterHotDispel(tar, ab, self.player) end; 
			if self.Dispels[ab] then DB:TryDispel(ab, tar, self.player, GetTime()) end; 
			return 
		end
			--incStats("SpellSelfBuffDispels", 2)
		for ab in strgfind(msg, "你施放了(.+)。") do 
			if self.TotemDispels[ab] then 
				DB:CastDispelTotem(ab, self.player, GetTime()) 
			elseif self.Dispels[ab] then 
				DB:TryDispel(ab, self.player, self.player, GetTime())
			end
			if self.RCD[ab] then DPSMateX:Broadcast(2, self.player, tar, ab) end; 
			return 
		end
		--for a in strgfind(msg, "你从图腾召回获得了(%d+)点") do
		--	DB:RemoveDispelTotem(self.player) 
		--	return
		--end
		--logUnhandledMsg("SpellSelfBuffDispels", arg1, msg)
	end
	
	DPSMateX.Parser.SpellHostileOrPlayerBuffDispels = function(self, msg)
			--incStats("SpellHostileOrPlayerBuffDispels", 1)
		for c, ta, ab in strgfind(msg, "(.+)对(.+)施放了(.+)。") do 
			if ta=="你" then ta = self.player end; 
			if self.HotDispels[ab] then DB:RegisterHotDispel(ta, ab, c) end; 
			if self.Dispels[ab] then DB:TryDispel(ab, ta, c, GetTime()) end; 
			if self.RCD[ab] then DPSMateX:Broadcast(2, c, ta, ab) end; 
			return 
		end
			--incStats("SpellHostileOrPlayerBuffDispels", 2)
		for c, ab in strgfind(msg, "(.+)施放了(.+)。") do 
			if self.TotemDispels[ab] then 
				DB:CastDispelTotem(ab, c, GetTime())
			elseif self.Dispels[ab] then 
				DB:TryDispel(ab, c, c, GetTime())
			end 
			return
		end
			--incStats("SpellHostileOrPlayerBuffDispels", 3)
		--logUnhandledMsg("SpellHostileOrPlayerBuffDispels", arg1, msg)
		--for c, ta in strgfind(msg, "(.+)从(.+)的图腾召回获得了") do
		--	DB:RemoveDispelTotem(c) 
		--	return
		--end
	end
	
	DPSMateX.Parser.SpellBreakAura = function(self, msg) 
			--incStats("SpellBreakAura", 1)
		for ab in strgfind(msg, "你的(.+)被移除了。") do DB:SeenDebuffDispelled(ab, self.player, GetTime()); return end
		--XX的因塔苟斯的凝视被移除了。
		--考虑到中文技能名中可能包含"的"字，比如"瘟疫使者的诅咒"、"因塔苟斯的凝视"等
		--又玩家名字中也可能包括"的"字，两者已经不可得兼，取兼容技能名称含的字。
			--incStats("SpellBreakAura", 2)
		for ta, ab in strgfind(msg, "(.-)的(.+)被移除了。") do DB:SeenDebuffDispelled(ab, ta, GetTime()); return end
	end
	
	----------------------------------------------------------------------------------
	--------------                       Deaths                         --------------                                  
	----------------------------------------------------------------------------------

	DPSMateX.Parser.CombatFriendlyDeath = function(self, msg)
		for ta in strgfind(msg, "(.+)被摧毁了。") do
			DB:UnregisterDeath(ta) 
		end
		for ta in strgfind(msg, "(.+)死亡了。") do 
			DB:UnregisterDeath(ta) 
			if GetCVar("NP_EnableAuraCastEvents") ~= "1" then
				DB:DestroyBuffs(ta, "all")
			end
		end
		if msg == "你死了。" then 
			DB:UnregisterDeath(self.player) 
			if GetCVar("NP_EnableAuraCastEvents") ~= "1" then
				DB:DestroyBuffs(self.player, "all")
			end
		end
	end

	DPSMateX.Parser.CombatHostileDeaths = function(self, msg)
		for ta in strgfind(msg, "(.+)死亡了。") do 
			DB:UnregisterDeath(ta)
			if GetCVar("NP_EnableAuraCastEvents") ~= "1" then
				DB:DestroyBuffs(ta, "all")
			end
		end
		for ta in strgfind(msg, "(.+)被摧毁了。") do 
			DB:UnregisterDeath(ta)
			if GetCVar("NP_EnableAuraCastEvents") ~= "1" then
				DB:DestroyBuffs(ta, "all")
			end
		end
	end
	
	----------------------------------------------------------------------------------
	--------------                     Interrupts                       --------------                                  
	----------------------------------------------------------------------------------

	DPSMateX.Parser.CreatureVsCreatureSpellDamageInterrupts = function(self, msg)
			--incStats("CreatureVsCreatureSpellDamageInterrupts", 1)
		for c, ab in strgfind(msg, "(.+)开始施放(.+)。") do 
			DB:RegisterPotentialKick(c, ab, GetTime())
			return
		end
	end
	DPSMateX.Parser.HostilePlayerSpellDamageInterrupts = function(self, msg)
			--incStats("HostilePlayerSpellDamageInterrupts", 1)
		for c, ab in strgfind(msg, "(.+)开始施放(.+)。") do 
			DB:RegisterPotentialKick(c, ab, GetTime())
			return
		end
	end
	
	-- Pet section
	DPSMateX.Parser.PetHits = function(self, msg)
			--incStats("PetHits", 1)
		for a,b,c,d in strgfind(msg, "(.+)对(.+)造成(%d+)的致命一击伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if b == "你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 0, 1, 0, 0) end
			return
		end
			--incStats("PetHits", 2)
		for a,b,c,f,d in strgfind(msg, "(.+)的致命一击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if b == "你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, crit or 1, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then 
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 0, 1, 0, 0) end
			return
		end
			--incStats("PetHits", 3)
		for a,b,c,f,d in strgfind(msg, "(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do
			local hit, crit, glance, block, amount = nil, nil, nil, nil, tnbr(c)
			--t = {nil, nil, nil, nil, tnbr(c)}
			if d~= "" then
				if strfind(d, "偏斜") then glance=1;hit=0 elseif strfind(d, "被格挡") then block=1;hit=0; end
				local _,_,_,absorb=strfind(d,"(.-)(%d+)点被吸收")
				if absorb then DB:SetUnregisterVariables(tnbr(absorb), AbilityAutoAttack, a) end
			end
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, b, block or 0, glance or 0)
			DB:DamageDone(a, AbilityAutoAttack, hit or 1, 0, 0, 0, 0, 0, amount, glance or 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[a] then
					DB:BuildFail(1, b, a, AbilityAutoAttack, amount);
				end
				DB:DeathHistory(b, a, AbilityAutoAttack, amount, 1, 0, 0, 0) end
			return
		end
			--incStats("PetHits", 4)
		--logUnhandledMsg("PetHits", arg1, msg)
	end

	DPSMateX.Parser.PetMisses = function(self, msg)
			--incStats("PetMisses", 1)
		for a,b in strgfind(msg, "(.+)没有击中(.+)。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
			--incStats("PetMisses", 2)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)闪躲开了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
			--incStats("PetMisses", 3)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)招架住了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
			--incStats("PetMisses", 4)
		for a,b in strgfind(msg, "(.+)发起了攻击。(.+)格挡住了。") do 
			if b=="你" then b=self.player end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, a, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(a, AbilityAutoAttack, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
			--incStats("PetMisses", 5)
		for c,b in strgfind(msg, "(.+)发起攻击，(.+)吸收了所有伤害。") do if b=="你" then b=self.player end; DB:Absorb(AbilityAutoAttack, b, c); return end
			--incStats("PetMisses", 6)
		--logUnhandledMsg("PetMisses", arg1, msg)
	end

	DPSMateX.Parser.PetSpellDamage = function(self, msg)
			--incStats("PetSpellDamage", 1)
		for k,a,b,c,g,_,f in strgfind(msg, "(.-)的(.+)击中(.+)造成(%d+)点(.*)伤害。(.-)(%d+)点被吸收") do 
			DB:SetUnregisterVariables(tnbr(f), b, k)
		end
			--incStats("PetSpellDamage", 2)
		for f,a,b,c,e in strgfind(msg, "(.-)的(.+)对(.+)造成(%d+)点致命一击伤害。%s?(.*)") do 
			local amount, crit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, c, GetTime()) end
			if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
			DB:DamageDone(f, a, 0, crit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[f] then
					DB:BuildFail(1, b, f, a, amount);
				end
				DB:DeathHistory(b, f, a, amount, 0, 1, 0, 0) end
			return
		end
			--incStats("PetSpellDamage", 3)
		for f,a,b,c,g,e in strgfind(msg, "(.+)的(.+)致命一击对(.+)造成(%d+)点(.*)伤害。%s?(.*)") do 
			local amount, crit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, c, GetTime()) end
			if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  0, crit or 1, 0, 0, 0, 0, amount, b, block or 0, 0)
			DB:DamageDone(f, a, 0, crit or 1, 0, 0, 0, 0, amount, 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[f] then
					DB:BuildFail(1, b, f, a, amount);
				end
				DB:DeathHistory(b, f, a, amount, 0, 1, 0, 0) end
			DB:AddSpellSchool(a,g)
			return
		end
			--incStats("PetSpellDamage", 4)
		for f,a,b,c,g,e in strgfind(msg, "(.+)的(.+)击中(.+)造成(%d+)点(.*)伤害。%s?(.*)") do 
			local amount, hit, block = tnbr(c), nil, nil
			--t = {tnbr(c), nil, nil, nil}
			if b=="你" then b=self.player end
			if e then 
				if strfind(e, "点被格挡") then block=1;hit=0; end
			end
			if DPSMateX.Parser.Kicks[a] then DB:AssignPotentialKick(f, a, b, GetTime()) end
			if DPSMateX.Parser.DmgProcs[a] then DB:BuildBuffs(f, f, a, true) end
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a,  hit or 1, 0, 0, 0, 0, 0, amount, b, block or 0, 0)
			DB:DamageDone(f, a, hit or 1, 0, 0, 0, 0, 0, amount, 0, block or 0, b)
			if self.TargetParty[b] then 
				if self.TargetParty[f] then
					DB:BuildFail(1, b, f, a, amount);
				end
				DB:DeathHistory(b, f, a, amount, 1, 0, 0, 0) end
			return
		end
			--incStats("PetSpellDamage", 5)
		for f,b,a,c in strgfind(msg, "(.+)的(.+)被(.+)闪(.+)过去。") do 
			if c=="避" then return end --aovid
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, b, 0, 0, 0, 0, 1, 0, 0, a, 0, 0)
			DB:DamageDone(f, b, 0, 0, 0, 0, 1, 0, 0, 0, 0)
			return
		end
			--incStats("PetSpellDamage", 6)
		for f,a,b in strgfind(msg, "(.+)的(.+)被(.+)招架了。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 1, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 1, 0, 0, 0, 0, 0)
			return
		end
			--incStats("PetSpellDamage", 7)
		for f,a,b in strgfind(msg, "(.+)的(.+)没有击中(.+)。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 1, 0, 0, 0, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 1, 0, 0, 0, 0, 0, 0)
			return
		end
			--incStats("PetSpellDamage", 8)
		for f,a,b in strgfind(msg, "(.-)的(.+)被(.+)抵抗了。") do
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 0, 0, 1, 0, b, 0, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 1, 0, 0, 0)
			return
		end
			--incStats("PetSpellDamage", 9)
		for f,a,b in strgfind(msg, "(.+)的(.+)被(.+)格挡过去。") do 
			DB:EnemyDamage(true, DPSMateX.DBCache.EDT, f, a, 0, 0, 0, 0, 0, 0, 0, b, 1, 0)
			DB:DamageDone(f, a, 0, 0, 0, 0, 0, 0, 0, 0, 1)
			return
		end
		for f, c, a in strgfind(msg, "(.-)对(.+)施放了(.+)。") do 
			return
		end
			--incStats("PetSpellDamage", 10)
		for who, whom, what in strgfind(msg, "(.+)打断了(.+)的(.+)。") do
			local usrId
			usrId, who = DB:BuildUser(who)
			local usr = DPSMateX.CacheUser[who]
		
			local causeAbility = "法术反制"
			if usr then
				if usr[2] == "priest" then
					causeAbility = "沉默"
				end
				-- Account for felhunter silence
				if usr[4] and usr[6] then
					local owner = DPSMateX:GetUserById(usr[6])
					if owner and DPSMateX.CacheUser[owner] then
						causeAbility = "法术封锁"
						who = owner
					end
				end
			end
			DB:Kick(who, whom, causeAbility, what)
		end
			--incStats("PetSpellDamage", 11)
		--logUnhandledMsg("PetSpellDamage", arg1, msg)
	end
end
