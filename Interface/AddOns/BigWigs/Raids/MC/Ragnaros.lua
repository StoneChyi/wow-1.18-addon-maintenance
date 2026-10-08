
local module, L = BigWigs:ModuleDeclaration("Ragnaros", "Molten Core")
local BC = AceLibrary("Babble-Class-2.2")
local bzragnaroslair = AceLibrary("Babble-Zone-2.2")["Ragnaros' Lair"]

module.revision = 30078
module.enabletrigger = module.translatedName
module.toggleoptions = {"emerge", "wrathofragnaros", "lava", "adds", "melt", "elementalfire", -1, "tankalert", "tankwrathhit", "tankwrathresist", "tankmark", "bosskill"}
module.wipemobs = {"Son of Flame"}
module.defaultDB = {
	emerge = true,
	wrathofragnaros = true,
	lava = false,
	adds = false,
	melt = false,
	elementalfire = false,
	tankalert = true,
	tankwrathhit = true,
	tankwrathresist = true,
	tankmark = true,
}


L:RegisterTranslations("enUS", function() return {
	cmd = "Ragnaros",

	emerge_cmd = "emerge",
	emerge_name = "Emerge Alert",
	emerge_desc = "Warn for Ragnaros Emerge",
	
	wrathofragnaros_cmd = "wrathofragnaros",
	wrathofragnaros_name = "Wrath of Ragnaros (Knockback) Alert",
	wrathofragnaros_desc = "Warn for Wrath of Ragnaros Knockback",
	
	lava_cmd = "lava",
	lava_name = "Touching Lava Alert",
	lava_desc = "Warn for Touching Lava",
	
	adds_cmd = "adds",
	adds_name = "Son of Flame Dies Alert",
	adds_desc = "Warn for Son of Flame Deaths",
	
	melt_cmd = "melt",
	melt_name = "Melt Weapon Alert",
	melt_desc = "Warn for Melt Weapon",
	
	elementalfire_cmd = "elementalfire",
	elementalfire_name = "Elemental Fire Bars",
	elementalfire_desc = "Show a duration bar for all current victims of Elemental Fire",
	
	tankalert_cmd = "tankalert",
	tankalert_name = "Tank Swap Alert",
	tankalert_desc = "Warning message whenever the character receiving melee hits changes",
	
	tankwrathhit_cmd = "tankwrathhit",
	tankwrathhit_name = "Tank Knockback Alert",
	tankwrathhit_desc = "Warns when the current tank gets knocked back by Wrath of Ragnaros",
	
	tankwrathresist_cmd = "tankwrathresist",
	tankwrathresist_name = "Tank Knockback Resist",
	tankwrathresist_desc = "Confirms that the current tank resisted Wrath of Ragnaros' knockback",
	
	tankmark_cmd = "tankmark",
	tankmark_name = "Tank Mark",
	tankmark_desc = "Marks the current tank with Skull, clears mark on knockback",
	

		--74.137
	trigger_domoStart1 = "Imprudent whelps! You've rushed headlong to your own deaths! See now, the master stirs!", --CHAT_MSG_MONSTER_YELL
	bar_domoStart = "Ragnaros Engage",
	msg_domoStart = "Ragnaros RP has started - Tanks, equip your Fire Resist!",
		--58.792
	trigger_domoStart2 = "Behold Ragnaros, the Firelord! He who was ancient when this world was young! Bow before him, mortals! Bow before your ending!", --CHAT_MSG_MONSTER_YELL
		--45.457
	trigger_domoStart3 = "TOO SOON! YOU HAVE AWAKENED ME TOO SOON, EXECUTUS! WHAT IS THE MEANING OF THIS INTRUSION???", --CHAT_MSG_MONSTER_YELL
		--32.144
	trigger_domoStart4 = "These mortal infidels, my lord! They have invaded your sanctum and seek to steal your secrets!", --CHAT_MSG_MONSTER_YELL
		--23.9
	trigger_domoStart5 = "FOOL! YOU ALLOWED THESE INSECTS TO RUN RAMPANT THROUGH THE HALLOWED CORE, AND NOW YOU LEAD THEM TO MY VERY LAIR? YOU HAVE FAILED ME, EXECUTUS! JUSTICE SHALL BE MET, INDEED!", --CHAT_MSG_MONSTER_YELL
		--19:44:21.439
	trigger_engage = "NOW FOR YOU, INSECTS! BOLDLY, YOU SOUGHT THE POWER OF RAGNAROS. NOW YOU SHALL SEE IT FIRSTHAND!", --CHAT_MSG_MONSTER_YELL
	
	trigger_submerge = "COME FORTH, MY SERVANTS! DEFEND YOUR MASTER!", --CHAT_MSG_MONSTER_YELL (to be confirmed)
	trigger_submerge2 = "YOU CANNOT DEFEAT THE LIVING FLAME! COME YOU MINIONS OF FIRE! COME FORTH YOU CREATURES OF HATE! YOUR MASTER CALLS!", --CHAT_MSG_MONSTER_YELL (to be confirmed)
	bar_nextEmerge = "Emerge",
	msg_submerge = "Ragnaros Submerged - Incoming Sons of Flame!",
	
	msg_emergeSoon = "Emerge in 10 seconds!",
	msg_emerge = "Ragnaros Emerged!",
	
		--melee knockback
	trigger_knockback = "TASTE THE FLAMES OF SULFURON!", --CHAT_MSG_MONSTER_YELL
	bar_knockbackCd = "Knockback CD",
	bar_knockbackSoon = "Knockback Soon...",
	msg_knockbackSoon = "Knockback Soon - Melee Out!",
	msg_knockback = "Knockback - Melee In!",
	
	trigger_lavaYou = "You lose (.+) health for swimming in lava.", --CHAT_MSG_COMBAT_SELF_HITS
	msg_lavaYou = "You're standing in lava!",

	msg_addDead = "/10 Son of Flame Dead",
	
	trigger_meltWeapon = "Ragnaros casts Melt Weapon on you: (.+) damaged.", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE
	bar_melt = "Melt Damage: ",
	
	trigger_elementalFireYou = "You are afflicted by Elemental Fire.", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_elementalFireOther = "(.+) is afflicted by Elemental Fire.", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE //CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_elementalFireFade = "Elemental Fire fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_elementalFire = "%s - Elemental Fire",
	
	trigger_hitCrit = "Ragnaros .-its (.+) for",
	trigger_miss = "Ragnaros misses (.+)%.",
	trigger_dodgeParry = "Ragnaros attacks. (.+) .-%.$",
	msg_newTank = "%s is tanking",
	msg_youTank = "YOU are tanking",
	
	trigger_wrathHit = "Wrath of Ragnaros hits (.+) for",
	trigger_wrathResist = "Wrath of Ragnaros was resisted by (.+)%.",
	trigger_wrathResistYou = "Wrath of Ragnaros was resisted%.",
	msg_tankWrathHit = "Knockback on Tank! %s is flying.",
	msg_tankWrathResist = "Resisted Knockback. %s still tanking.",

	sonofflame = "Son of Flame",
    majordomoexecutus = "Majordomo Executus",
	you = "you",
} end)



L:RegisterTranslations("zhCN", function() return {
	-- Sunelegy，Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22
    cmd = "Ragnaros",

	emerge_cmd = "emerge",
    emerge_name = "出现警报",
    emerge_desc = "拉格纳罗斯出现进行警告",
	
	wrathofragnaros_cmd = "wrathofragnaros",
    wrathofragnaros_name = "拉格纳罗斯之怒（击退）警报",
    wrathofragnaros_desc = "当拉格纳罗斯之怒击退时发出警报",

    lava_cmd = "lava",
    lava_name = "接触熔岩警报",
    lava_desc = "当接触熔岩时发出警告",

    adds_cmd = "adds",
    adds_name = "火焰之子死亡警报",
    adds_desc = "当火焰之子死亡时发出警报",

    melt_cmd = "melt",
    melt_name = "熔化武器警报",
    melt_desc = "当武器被熔化时发出警报",

    elementalfire_cmd = "elementalfire",
    elementalfire_name = "元素火焰持续时间条",
    elementalfire_desc = "为所有当前受到元素火焰影响的玩家显示持续时间条",

    tankalert_cmd = "tankalert",
    tankalert_name = "坦克交换警报",
    tankalert_desc = "当承受近战攻击的角色发生变化时显示警告信息",

    tankwrathhit_cmd = "tankwrathhit",
    tankwrathhit_name = "坦克击退警报",
    tankwrathhit_desc = "当当前坦克被拉格纳罗斯之怒击退时发出警报",

    tankwrathresist_cmd = "tankwrathresist",
    tankwrathresist_name = "坦克抵抗击退警报",
    tankwrathresist_desc = "确认当前坦克抵抗了拉格纳罗斯之怒的击退效果",

    tankmark_cmd = "tankmark",
    tankmark_name = "坦克标记",
    tankmark_desc = "用骷髅标记当前坦克，击退时清除标记",
	

		--74.137
	trigger_domoStart1 = "不谨慎的小崽子们！你已经一头扎进了自己的死里逃生！瞧瞧，主人动起来了！", --CHAT_MSG_MONSTER_YELL
    bar_domoStart = "拉格纳罗斯战斗开始",
    msg_domoStart = "拉格纳罗斯剧情已经开始 - 坦克们，装备你的火焰抗性装备！",
		--58.792
	trigger_domoStart2 = "看哪，炎魔之王拉格纳罗斯！当这个世界还年轻的时候，他就已经远古了！凡人，在他面前鞠躬吧！在你的结局面前鞠躬！", --CHAT_MSG_MONSTER_YELL
		--45.457
	trigger_domoStart3 = "太快了！你太早把我吵醒了，长官！这次入侵的意义是什么？？？", --CHAT_MSG_MONSTER_YELL
		--32.144
	trigger_domoStart4 = "这些凡人的异教徒，陛下！他们入侵了你的圣所并试图窃取你的秘密！", --CHAT_MSG_MONSTER_YELL
		--23.9
	trigger_domoStart5 = "傻子！你让这些昆虫在神圣核心中肆虐", --CHAT_MSG_MONSTER_YELL
		--19:44:21.439
	trigger_engage = "现在，昆虫们！大胆地，你寻求拉格纳罗斯的力量。现在您将亲眼目睹！", --CHAT_MSG_MONSTER_YELL
	
	trigger_submerge = "出来吧，我的仆人们！保卫你的主人！", --CHAT_MSG_MONSTER_YELL (to be confirmed)
	trigger_submerge2 = "^你们无法击败生命之焰", --CHAT_MSG_MONSTER_YELL (to be confirmed)

	bar_nextEmerge = "现身",
    msg_submerge = "拉格纳罗斯潜入熔岩 - 火焰之子即将出现！",
	
    msg_emergeSoon = "10秒后出现！",
    msg_emerge = "拉格纳罗斯已出现！",
	
		--melee knockback
	trigger_knockback = "品尝萨弗隆的火焰！", --CHAT_MSG_MONSTER_YELL
    bar_knockbackCd = "击退冷却",
    bar_knockbackSoon = "即将击退...",
    msg_knockbackSoon = "即将击退 - 近战撤退！",
    msg_knockback = "近战进场！",
	
	trigger_lavaYou = "你泡在岩浆中，损失了", --CHAT_MSG_COMBAT_SELF_HITS
    msg_lavaYou = "你站在岩浆里！",

    msg_addDead = "/10 烈焰之子死亡",
	
	trigger_meltWeapon = "拉格纳罗斯对你施放了熔化武器", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE
    bar_melt = "熔化伤害：",
	
	trigger_elementalFireYou = "你受到了元素火焰效果的影响。", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_elementalFireOther = "(.+)受到了元素火焰效果的影响。", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE //CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_elementalFireFade = "元素火焰效果从(.+)身上消失了。", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHERà
    bar_elementalFire = "元素火焰",

	trigger_hitCrit = "拉格纳罗斯击中(.+)造成",
    trigger_miss = "拉格纳罗斯没有击中(.+)",
    trigger_dodgeParry = "拉格纳罗斯击中(.+)",
    msg_newTank = "%s担任坦克",
    msg_youTank = "你担任坦克",
	
	trigger_wrathHit = "拉格纳罗斯之怒击中(.+)造成",
    trigger_wrathResist = "拉格纳罗斯之怒被(.+)抵抗了",
    trigger_wrathResistYou = "拉格纳罗斯之怒被抵抗了",
    msg_tankWrathHit = "坦克被击退！%s被击飞",
    msg_tankWrathResist = "抵抗击退！%s仍在担任坦克",
    
    sonofflame = "烈焰之子",
    majordomoexecutus = "管理者埃克索图斯",
	you = "你",
} end)


local timer = {
	domoStart1 = 74.137,
	domoStart2 = 58.792,
	domoStart3 = 45.457,
	domoStart4 = 32.144,
	domoStart5 = 23.9,
	
	nextEmerge = 90,
	
	knockbackCd = 25, --supposed to be 25,30
	knockbackSoon = 8,
	
	elementalFire = 8,
}
local icon = {
	domoStart = "inv_misc_pocketwatch_01",
	
	emerge = "ability_stealth",
	
	knockback = "ability_smash",
	
	lava = "spell_fire_fire",
	
	elementalFire = "spell_fire_flametounge",
	
	melt = "inv_sword_36",
}
local color = {
	domoStart = "White",
	
	emerge = "White",
	
	knockbackCd = "Black",
	knockbackSoon = "Cyan",
	
	elementalFire = "Red",
	
	melt = "Yellow",
}
local syncName = {
	submerge = "RagnarosSubmerge"..module.revision,
	emerge = "RagnarosEmerge"..module.revision,
	
	knockback = "RagnarosKnockback"..module.revision,
	
	addDead = "RagnarosSonDead"..module.revision,
	
	elementalFire = "RagnarosElementalFire"..module.revision,
	elementalFireFade = "RagnarosElementalFireFade"..module.revision,
	
	newTank = "RagnarosNewTank"..module.revision,
	tankWrathHit = "RagnarosTankWrathHit"..module.revision,
	tankWrathResist = "RagnarosTankWrathResist"..module.revision,
}

local addDead = 0

local melt1 = nil
local melt2 = nil
local melt3 = nil

local meltCount1 = 50
local meltCount2 = 50
local meltCount3 = 50

local phase = nil

local lastKnockTime = 0
local submergeTime = 0

local knownTank = nil

function module:OnRegister()
	self:RegisterEvent("MINIMAP_ZONE_CHANGED")
end

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug
	
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL") --trigger_domoStart1, 2, 3, 4, 5, trigger_engage
	
	self:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS", "Event") --trigger_lavaYou
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "SpellHitEvent") --trigger_meltWeapon, trigger_wrathHit, trigger_wrathResistYou
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "SpellHitEvent") --trigger_wrathHit, trigger_wrathResist
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellHitEvent") --trigger_wrathHit, trigger_wrathResist
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_elementalFireYou
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") --trigger_elementalFireOther
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_elementalFireOther
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") --trigger_elementalFireFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") --trigger_elementalFireFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") --trigger_elementalFireFade
	
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS", "MeleeHitEvent") 
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES", "MeleeHitEvent")
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS", "MeleeHitEvent")
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES", "MeleeHitEvent")
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS", "MeleeHitEvent") --non-party raid members
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES", "MeleeHitEvent") --non-party raid members
	
	
	self:ThrottleSync(5, syncName.knockback)
	self:ThrottleSync(5, syncName.submerge)
	self:ThrottleSync(5, syncName.emerge)
	self:ThrottleSync(0.5, syncName.addDead)
	self:ThrottleSync(1, syncName.elementalFire)
	self:ThrottleSync(0.1, syncName.elementalFireFade)
	self:ThrottleSync(1, syncName.newTank)
	self:ThrottleSync(5, syncName.tankWrathHit)
	self:ThrottleSync(5, syncName.tankWrathResist)
end

function module:OnSetup()
	self.started = nil
	
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
end

function module:OnEngage()
	self:RemoveBar(L["bar_domoStart"])
	
	addDead = 0
	
	melt1 = nil
	melt2 = nil
	melt3 = nil

	meltCount1 = 50
	meltCount2 = 50
	meltCount3 = 50
	
	phase = "emerged"
	
	lastKnockTime = 0
	submergeTime = 0
	
	knownTank = nil
end

function module:OnDisengage()
	self:ClearKnownTank()
end

function module:MINIMAP_ZONE_CHANGED(msg)
	if GetMinimapZoneText() ~= bzragnaroslair or self.core:IsModuleActive(module.translatedName) then
		return
	end
	
	self.core:EnableModule(module.translatedName)
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	BigWigs:CheckForBossDeath(msg, self)

	if (msg == string.format(UNITDIESOTHER, "sonofflame")) then
		addDead = addDead + 1
		if addDead <= 10 then
			self:Sync(syncName.addDead .. " " .. addDead)
		end
	end
end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["trigger_domoStart1"] then
		self:DomoStart1()
	elseif msg == L["trigger_domoStart2"] then
		self:DomoStart2()
	elseif msg == L["trigger_domoStart3"] then
		self:DomoStart3()
	elseif msg == L["trigger_domoStart4"] then
		self:DomoStart4()
	elseif msg == L["trigger_domoStart5"] then
		self:DomoStart5()
	
	elseif msg == L["trigger_knockback"] then
		self:Sync(syncName.knockback)
	
	elseif msg == L["trigger_submerge"] or msg == L["trigger_submerge2"] then
		self:Sync(syncName.submerge)
	
	elseif string.find(msg, L["trigger_engage"]) then
		self:SendEngageSync()
		
			--old (bad) BigWigs will send bad engage syncs, this is the fix for it
		self:TrueEngage()
	end
end

function module:TrueEngage()
	if self.db.profile.wrathofragnaros then
		self:Bar(L["bar_knockbackCd"], timer.knockbackCd, icon.knockback, true, color.knockbackCd)
		self:DelayedBar(timer.knockbackCd, L["bar_knockbackSoon"], timer.knockbackSoon, icon.knockback, true, color.knockbackSoon)
		
		if not (UnitClass("Player") == "Mage" or UnitClass("Player") == "Priest" or UnitClass("Player") == "Warlock") then
			self:DelayedWarningSign(timer.knockbackCd - 3, icon.knockback, 10)
			self:DelayedMessage(timer.knockbackCd - 3, L["msg_knockbackSoon"], "Urgent", false, nil, false)
			self:DelayedSound(timer.knockbackCd - 3, "RunAway")
		end
	end
end

function module:Event(msg)
	if string.find(msg, L["trigger_lavaYou"]) and self.db.profile.lava then
		self:LavaYou()		
	
	elseif msg == L["trigger_elementalFireYou"] then
		local elementalFirePerson = UnitName("Player")
		self:Sync(syncName.elementalFire .. " " .. elementalFirePerson)
	
	elseif string.find(msg, L["trigger_elementalFireOther"]) then
		local _,_, elementalFirePerson, _ = string.find(msg, L["trigger_elementalFireOther"])
		self:Sync(syncName.elementalFire .. " " .. elementalFirePerson)
	
	elseif string.find(msg, L["trigger_elementalFireFade"]) then
		local _,_, elementalFireFadePerson, _ = string.find(msg, L["trigger_elementalFireFade"])
		if elementalFireFadePerson == "你" or elementalFireFadePerson == "you" then elementalFireFadePerson = UnitName("Player") end
		self:Sync(syncName.elementalFireFade .. " " .. elementalFireFadePerson)
	end
end


function module:SpellHitEvent(msg)
	if string.find(msg, L["trigger_meltWeapon"]) and self.db.profile.melt then
		local _,_, meltWeapon, _ = string.find(msg, L["trigger_meltWeapon"])
		self:MeltWeapon(meltWeapon)
		return
	end

	local _,_, wrathHitPerson = string.find(msg, L["trigger_wrathHit"])
	if wrathHitPerson then
		if wrathHitPerson == "你" or wrathHitPerson == "you" then wrathHitPerson = UnitName("Player") end
		if wrathHitPerson == knownTank then
			self:Sync(syncName.tankWrathHit .. " " .. wrathHitPerson)
		end
		return
	end

	local _,_, wrathResistPerson = string.find(msg, L["trigger_wrathResist"])
	if wrathResistPerson and wrathResistPerson == knownTank then
		self:Sync(syncName.tankWrathResist .. " " .. wrathResistPerson)
		return
	end

	if string.find(msg, L["trigger_wrathResistYou"]) and knownTank == UnitName("Player") then
		self:Sync(syncName.tankWrathResist .. " " .. UnitName("Player"))
		return
	end
end


function module:MeleeHitEvent(msg)
	local victim = "none"

	-- 顺序很重要：dodgeParry 的 (.+) 是贪婪匹配，会把「你造成596点伤害。（194点被格挡）」
	-- 整串都捕获进去，必须放在最前面当兜底，让下面更精确的 hitCrit / miss 覆盖它。
	-- 否则 victim 每拳都因伤害数字不同而变化，导致每一拳都广播一次新坦克，疯狂刷屏。
	local _,_, player = string.find(msg, L["trigger_dodgeParry"])
	victim = player or victim

	local _,_, player = string.find(msg, L["trigger_hitCrit"])
	victim = player or victim

	local _,_, player = string.find(msg, L["trigger_miss"])
	victim = player or victim

	-- 兜底裁剪：去掉「造成…伤害」尾巴与结尾句号，只保留纯目标名
	if victim ~= "none" then
		local _,_, cleanName = string.find(victim, "^(.-)造成")
		if cleanName then victim = cleanName end
		victim = string.gsub(victim, "。$", "")
	end

	if victim ~= "none" then
		-- zhCN 战斗日志里自己挨打显示为「你」，英文为 "you"，两者都映射到玩家真名
		if victim == L["you"] or string.lower(victim) == "you" then victim = UnitName("Player") end

		if victim ~= knownTank then
			self:Sync(syncName.newTank .. " " .. victim)
		end
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.knockback and self.db.profile.wrathofragnaros then
		self:Knockback()

	elseif sync == syncName.submerge then
		self:Submerge()
	elseif sync == syncName.emerge then
		self:Emerge()
	elseif sync == syncName.addDead and rest then
		self:AddDead(rest)
		
	elseif sync == syncName.elementalFire and rest then
		self:ElementalFire(rest)
	elseif sync == syncName.elementalFireFade and rest then
		self:ElementalFireFade(rest)
		
	elseif sync == syncName.newTank and rest then
		self:NewTank(rest)
	elseif sync == syncName.tankWrathHit and rest then
		self:TankKnockbackHit(rest)
	elseif sync == syncName.tankWrathResist and rest then
		self:TankKnockbackResist(rest)
	end
end


function module:DomoStart1()
	self:Bar(L["bar_domoStart"], timer.domoStart1, icon.domoStart, true, color.domoStart)
	self:Message(L["msg_domoStart"])
end

function module:DomoStart2()
	self:Bar(L["bar_domoStart"], timer.domoStart2, icon.domoStart, true, color.domoStart)
end

function module:DomoStart3()
	self:Bar(L["bar_domoStart"], timer.domoStart3, icon.domoStart, true, color.domoStart)
end

function module:DomoStart4()
	self:Bar(L["bar_domoStart"], timer.domoStart4, icon.domoStart, true, color.domoStart)
end

function module:DomoStart5()
	self:Bar(L["bar_domoStart"], timer.domoStart5, icon.domoStart, true, color.domoStart)
end


function module:Knockback()
	self:RemoveBar(L["bar_knockbackCd"])
	self:CancelDelayedBar(L["bar_knockbackSoon"])
	self:RemoveBar(L["bar_knockbackSoon"])
	self:CancelDelayedWarningSign(icon.knockback)
	self:RemoveWarningSign(icon.knockback)
	self:CancelDelayedMessage(L["msg_knockbackSoon"])
	self:CancelDelayedSound("RunAway")
	
	self:Message(L["msg_knockback"], "Important", false, nil, false)
	
	self:Bar(L["bar_knockbackCd"], timer.knockbackCd, icon.knockback, true, color.knockbackCd)
	self:DelayedBar(timer.knockbackCd, L["bar_knockbackSoon"], timer.knockbackSoon, icon.knockback, true, color.knockbackSoon)
	
	if not (UnitClass("Player") == BC["Mage"] or UnitClass("Player") == BC["Priest"] or UnitClass("Player") == BC["Warlock"]) then
		self:DelayedWarningSign(timer.knockbackCd - 3, icon.knockback, 12)
		self:DelayedMessage(timer.knockbackCd - 3, L["msg_knockbackSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.knockbackCd - 3, "RunAway")
	end
	
	lastKnockTime = GetTime()
end

function module:Submerge()
	phase = "submerged"
	self:ClearKnownTank()

		--knockback stuff
	self:RemoveBar(L["bar_knockbackCd"])
	self:CancelDelayedBar(L["bar_knockbackSoon"])
	self:RemoveBar(L["bar_knockbackSoon"])
	self:CancelDelayedWarningSign(icon.knockback)
	self:RemoveWarningSign(icon.knockback)
	self:CancelDelayedMessage(L["msg_knockbackSoon"])
	self:CancelDelayedSound("RunAway")

	submergeTime = GetTime()

	if self.db.profile.emerge then
		self:Message(L["msg_submerge"], "Attention", false, nil, false)

		self:Bar(L["bar_nextEmerge"], timer.nextEmerge, icon.emerge, true, color.emerge)
		self:DelayedMessage(timer.nextEmerge - 10, L["msg_emergeSoon"], "Attention", false, nil, false)
	end

	self:ScheduleRepeatingEvent("CheckForEmerge", self.CheckForEmerge, 1, self)
end

function module:Emerge()	
	self:CancelScheduledEvent("CheckForEmerge")
	
	phase = "emerged"
	addDead = 0
	
	self:RemoveBar(L["bar_nextEmerge"])
	self:CancelDelayedMessage(L["msg_emergeSoon"])
	
	if self.db.profile.emerge then
		self:Message(L["msg_emerge"], "Attention", false, nil, false)
	end
	
	
	if self.db.profile.wrathofragnaros then
			--possibleTime - elapsedTime = timeLeft
		local knockbackTimeLeft = (timer.knockbackCd + timer.knockbackSoon) - (submergeTime - lastKnockTime)
		
			--if timeLeft is before warn, regular bars with remaining time
		if knockbackTimeLeft > timer.knockbackSoon + 3 then
			self:Bar(L["bar_knockbackCd"], knockbackTimeLeft - timer.knockbackSoon, icon.knockback, true, color.knockbackCd)
			self:DelayedBar(knockbackTimeLeft - timer.knockbackSoon, L["bar_knockbackSoon"], timer.knockbackSoon, icon.knockback, true, color.knockbackSoon)
			
			if not (UnitClass("Player") == BC["Mage"] or UnitClass("Player") == BC["Priest"] or UnitClass("Player") == BC["Warlock"]) then
				self:DelayedWarningSign(knockbackTimeLeft - timer.knockbackSoon - 3, icon.knockback, 12)
				self:DelayedMessage(knockbackTimeLeft - timer.knockbackSoon - 3, L["msg_knockbackSoon"], "Urgent", false, nil, false)
				self:DelayedSound(knockbackTimeLeft - timer.knockbackSoon - 3, "RunAway")
			end			
			
			--if timeLeft is 0, expect knockback right the hell now
		elseif knockbackTimeLeft <= 0 then
			if not (UnitClass("Player") == BC["Mage"] or UnitClass("Player") == BC["Priest"] or UnitClass("Player") == BC["Warlock"]) then
				self:WarningSign(icon.knockback, 12)
				self:Message(L["msg_knockbackSoon"], "Urgent", false, nil, false)
				self:Sound("RunAway")
			end			
			
			--if timeLeft is after warn, warn and only start bar soon
		else
			self:Bar(L["bar_knockbackSoon"], knockbackTimeLeft, icon.knockback, true, color.knockbackSoon)
			
			if not (UnitClass("Player") == BC["Mage"] or UnitClass("Player") == BC["Priest"] or UnitClass("Player") == BC["Warlock"]) then
				self:WarningSign(icon.knockback, knockbackTimeLeft + 1)
				self:Message(L["msg_knockbackSoon"], "Urgent", false, nil, false)
				self:Sound("RunAway")
			end
		end
	end
end

function module:CheckForEmerge()
	if UnitExists("Target") and UnitName("Target") == module.translatedName and UnitExists("TargetTarget") and UnitName("TargetTarget") ~= "majordomoexecutus" then
		self:Sync(syncName.emerge)
	else
		for i=1,GetNumRaidMembers() do
			if UnitExists("raid"..i.."Target") and UnitName("raid"..i.."Target") == module.translatedName and UnitExists("raid"..i.."TargetTarget") and UnitName("raid"..i.."TargetTarget") ~= "majordomoexecutus" then
				self:Sync(syncName.emerge)
				break
			end
		end
	end
end

function module:LavaYou()
	self:Message(L["msg_lavaYou"])
	self:WarningSign(icon.lava, 0.7)
	self:Sound("Info")
end

function module:AddDead(rest)
	if self.db.profile.adds then
		self:Message(rest..L["msg_addDead"], "Positive", false, nil, false)
	end
	
	if tonumber(rest) == 10 and phase == "submerged" then
		self:Sync(syncName.emerge)
	end
end

function module:MeltWeapon(rest)
	if melt1 == nil then
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_melt"]..rest, 50, "Interface\\Icons\\"..icon.melt, true, color.melt)
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..rest, (50 - 0.1))
		melt1 = rest
	elseif rest ~= melt1 and melt2 == nil then
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_melt"]..rest, 50, "Interface\\Icons\\"..icon.melt, true, color.melt)
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..rest, (50 - 0.1))
		melt2 = rest
	elseif rest ~= melt1 and rest ~= melt2 and melt3 == nil then
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_melt"]..rest, 50, "Interface\\Icons\\"..icon.melt, true, color.melt)
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..rest, (50 - 0.1))
		melt3 = rest
	end
		
	if rest == melt1 then
		meltCount1 = meltCount1 - 1
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..melt1, meltCount1)
	elseif rest == melt2 then
		meltCount2 = meltCount2 - 1
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..melt2, meltCount2)
	elseif rest == melt3 then
		meltCount3 = meltCount3 - 1
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_melt"]..melt3, meltCount3)
	end
end

function module:ElementalFire(player)
	if self.db.profile.elementalfire then
		self:Bar(string.format(L["bar_elementalFire"], player), timer.elementalFire, icon.elementalFire, true, color.elementalFire)
	end
end

function module:ElementalFireFade(player)
	self:RemoveBar(string.format(L["bar_elementalFire"], player))
end

function module:OnFriendlyDeath(msg)
	local _, _, player = string.find(msg, "(.+)死亡了")
	if player then
		if player == "You" then player = UnitName("player") end

		-- remove Elemental Fire bar when a player dies
		self:ElementalFireFade(player)

		-- clear mark and variable if tank dies
		if player == knownTank then
			self:ClearKnownTank()
		end
	end
end

function module:NewTank(newTank)
	-- sanity check in case remote player has a different knownTank
	if newTank == knownTank then return end

	if self.db.profile.tankalert then
		if newTank == UnitName("player") then
			-- infer whether player is a tank from fire resist
			local _, FR = UnitResistance("player",2)

			if FR < 200 then -- warn for aggro pull
				self:Message(L["msg_youTank"], "Important", true, "Beware")
			else -- player is tanking
				self:Message(L["msg_youTank"], "Positive", true, "Long")		
			end
		else
			self:Message(string.format(L["msg_newTank"], newTank), "Attention", true, "Alarm")
		end
	end

	self:ClearKnownTank()
	knownTank = newTank

	if self.db.profile.tankmark then
		self:SetRaidTargetForPlayer(newTank, 8)
	end
end

function module:ClearKnownTank()
	if self.db.profile.tankmark and knownTank then
		self:RestorePreviousRaidTargetForPlayer(knownTank)
	end

	knownTank = nil
end

function module:TankKnockbackHit(player)
	-- sanity check in case remote player has a different knownTank
	if player ~= knownTank then return end

	if self.db.profile.tankwrathhit then
		self:Message(string.format(L["msg_tankWrathHit"], knownTank), "Urgent", true, "Beware")
	end

	self:ClearKnownTank()
end

function module:TankKnockbackResist(player)
	-- sanity check in case remote player has a different knownTank
	if player ~= knownTank then return end

	if self.db.profile.tankwrathresist then
		self:Message(string.format(L["msg_tankWrathResist"], knownTank), "Positive", true, "Long")
	end
end
