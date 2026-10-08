local module, L = BigWigs:ModuleDeclaration("Rupturan the Broken", "Karazhan")

module.revision = 30005
module.enabletrigger = { module.translatedName, "破碎者鲁普图兰", "Rupturan the Broken" }
module.toggleoptions = { "boulderalert", "bouldermark", "bouldersay", "livingstone", "opportunity", -1, "igniteearth", "dirtmound", "dirtmoundmark", -1, "flamestrike", "flamestrikemove", "felheartalert", "felheartbar", "fragmentbars", "reform", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
	"Outland",
	"The Rock of Desolation",
    "荒芜巨岩",
    "外域",
}

local _, playerClass = UnitClass("player")
local opportunityThreshold = 15
local BC = AceLibrary("Babble-Class-2.2")

module.defaultDB = {
	boulderalert = false,
	bouldermark = true,
	bouldersay = true,
	livingstone = true,
	opportunity = true,
	igniteearth = true,
	dirtmound = true,
	dirtmoundmark = false,
	flamestrike = true,
	flamestrikemove = true,
	felheartalert = true,
	felheartbar = playerClass == BC["HUNTER"] or playerClass == BC["PRIEST"] or playerClass == BC["WARLOCK"],
	reform = true,
	fragmentbars = false,
}

-------------------------------------------------------------------------------
--  Localization
-------------------------------------------------------------------------------
L:RegisterTranslations("enUS", function() return {
	-- Options
	cmd = "Rupturan",

	boulderalert_cmd = "boulderalert",
	boulderalert_name = "Throw Boulder Alert",
	boulderalert_desc = "Gives a warning message with the target of an incoming Boulder.",
	
	bouldermark_cmd = "bouldermark",
	bouldermark_name = "Throw Boulder Mark",
	bouldermark_desc = "Mark the target of an incoming Boulder with Moon.",
	
	bouldersay_cmd = "bouldersay",
	bouldersay_name = "Throw Boulder Say",
	bouldersay_desc = "Alert your surroundings with a /say message if you are the target of an incoming Boulder.",

	livingstone_cmd = "livingstone",
	livingstone_name = "Living Stone Stomp",
	livingstone_desc = "Show time left until a Living Stone stomp after Crash Landing fades.",

	opportunity_cmd = "opportunity",
	opportunity_name = "Window of Opportunity",
	opportunity_desc = "Warns about remaining or incoming Living Stones below "..opportunityThreshold.."% boss HP to avoid Explode mechanic (when the boss dies the remaining Living Stones detonate)",

	igniteearth_cmd  = "igniteearth",
	igniteearth_name = "Ignite Earth",
	igniteearth_desc = "Show cooldown and cast bar for Ignite Earth (P1 flamestrike)",

	dirtmound_cmd = "dirtmound",
	dirtmound_name = "Dirt Mound Indicators",
	dirtmound_desc = "Warn when Dirt Mound Quake hits you and when one is spawned.",

	dirtmoundmark_cmd  = "dirtmoundmark",
	dirtmoundmark_name = "Mark Dirt Mound Target",
	dirtmoundmark_desc = "Mark the player Dirt Mound is chasing with a Diamond.",

	flamestrike_cmd = "flamestrike",
	flamestrike_name = "Flamestrike Cast",
	flamestrike_desc = "Warn when Flamestrike (Ignite Rock) is casting.",

	flamestrikemove_cmd = "flamestrikemove",
	flamestrikemove_name = "Flamestrike Alert",
	flamestrikemove_desc = "Warns when you stand in fire (Ignite Rock).",

	felheartalert_cmd = "felheartalert",
	felheartalert_name = "Felheart Mana Alert",
	felheartalert_desc = "Warns when Felheart has >80% mana (5 second CD).",

	felheartbar_cmd = "felheartbar",
	felheartbar_name = "Felheart Mana Bar",
	felheartbar_desc = "Adds a continuously updating mana bar for Felheart.",

	fragmentbars_cmd = "fragmentbars",
	fragmentbars_name = "Fragment Health Bars",
	fragmentbars_desc = "Show health bars for all 3 fragments in Phase 2.",

	reform_cmd = "reform",
	reform_name = "Reform Timer",
	reform_desc = "When you kill a Fragment, show show time left until Rupturan will be reformed.",

	-- Bars / Messages
	bar_ignite_earth_CD  = "Ignite Earth CD",
	bar_ignite_earth     = "Ignite Earth casting",
	bar_ignite_rock      = "Flamestrike casting",
	warn_ignite_rock     = "Incoming!",
	msg_flamestrike      = "Move out of Flamestrike!",
	warn_flamestrike     = "MOVE",
	bar_ls_earthstomp    = "Living Stone STOMP",
	msg_dm_quake         = "Dirt Mound Quake!  MOVE AWAY!",
	msg_dm_target_you    = "Dirt Mound chasing you!",
	bar_reform           = "Rupturan Reforming",
	msg_boulder          = "Boulder casting on %s",
	msg_boulderMiss      = "Boulder missed, no add",
	say_boulder          = "Boulder incoming on me!",
	bar_window           = "Window of Opportunity",
	msg_windowOpen       = "Kill Rupturan! - all Stones dead",
	msg_windowClosing    = "Stone incoming!",
	msg_windowClosed     = "Stone alive! DON'T kill Rupturan",
	msg_felheartMana     = "Felheart at %s%% mana!",
	bar_fragment	     = "Frag",

	-- Triggers
	trigger_start        = "All shall crumble",
	trigger_phase2       = "Let the cracks of this world destroy you",
	trigger_boss_dead    = "Perished... To dust",
	unit_felheart        = "Felheart",
	unit_fragment        = "Fragment of Rupturan",

	trigger_tb_cast      = "Rupturan the Broken begins to perform Throw Boulder",
	trigger_tb_hit       = "Rupturan the Broken's Throw Boulder hits (.+) for",
	trigger_tb_miss      = "Rupturan the Broken's Throw Boulder missed (.+)%.",
	trigger_ls_fades     = "Crash Landing fades from Living Stone",
	trigger_ls_die       = "Living Stone dies",
	trigger_igniteearth  = "Rupturan the Broken begins to cast Ignite Earth",
	trigger_dm_quake     = "Dirt Mound's Quake hits you for",
	trigger_dm_spawn     = "Rupturan commands the earth to crush (.+)!",
	trigger_dm_die       = "Dirt Mound dies",
	trigger_flamestrike  = "You are afflicted by Ignite Rock",
	trigger_igniterock   = "Fragment of Rupturan begins to cast Ignite Rock",
	trigger_reform       = "Fragment of Rupturan begins to cast Reform",
} end)

L:RegisterTranslations("zhCN", function() return {
	-- Options
	cmd = "Rupturan",
	boulderalert_cmd = "boulderalert",
	boulderalert_name = "投掷巨石警报",
	boulderalert_desc = "当有巨石砸向目标时显示警告信息。",
	
	bouldermark_cmd = "bouldermark",
	bouldermark_name = "投掷巨石标记",
	bouldermark_desc = "用月亮标记被巨石瞄准的目标。",
	
	bouldersay_cmd = "bouldersay",
	bouldersay_name = "投掷巨石喊话",
	bouldersay_desc = "如果你被巨石瞄准，通过/say喊话提醒周围队友。",

	livingstone_cmd = "livingstone",
	livingstone_name = "活体石块践踏",
	livingstone_desc = "在紧急着陆效果消失后，显示活体石块践踏的剩余时间。",

	opportunity_cmd = "opportunity",
	opportunity_name = "机会窗口",
	opportunity_desc = "当首领血量低于15%时警告，以避免爆炸机制（首领死亡时剩余的活体石块会爆炸）。",

	igniteearth_cmd  = "igniteearth",
	igniteearth_name = "灼热大地",
	igniteearth_desc = "显示灼热大地的冷却时间和施法条。",

	dirtmound_cmd = "dirtmound",
	dirtmound_name = "土堆指示器",
	dirtmound_desc = "当土堆的击中你以及土堆生成时发出警告。",

	dirtmoundmark_cmd  = "dirtmoundmark",
	dirtmoundmark_name = "标记土堆目标",
	dirtmoundmark_desc = "用菱形标记被土堆追赶的玩家。",

	flamestrike_cmd = "flamestrike",
	flamestrike_name = "烈焰打击施法",
	flamestrike_desc = "当灼热大地（烈焰打击）施法时发出警告。",

	flamestrikemove_cmd = "flamestrikemove",
	flamestrikemove_name = "烈焰打击警报",
	flamestrikemove_desc = "当你站在火焰中（灼热大地）时发出警告。",

	felheartalert_cmd = "felheartalert",
	felheartalert_name = "魔心法力值警报",
	felheartalert_desc = "当魔心法力值大于80%时发出警告（5秒冷却）。",

	felheartbar_cmd = "felheartbar",
	felheartbar_name = "魔心法力条",
	felheartbar_desc = "为魔心添加一个持续更新的法力条。",

	fragmentbars_cmd = "fragmentbars",
    fragmentbars_name = "鲁普图兰的碎块的血量条",
    fragmentbars_desc = "在第二阶段显示全部3块鲁普图兰碎块的血量条。",

	reform_cmd = "reform",
	reform_name = "重组计时器",
	reform_desc = "当你杀死一个碎片时，显示鲁普图兰重组剩余时间。",

	-- 计时条/消息
 	bar_ignite_earth_CD  = "灼热大地冷却中",
	bar_ignite_earth     = "灼热大地施法中",
	bar_ignite_rock      = "燃烧岩柱施法中",
	warn_ignite_rock     = "即将到来！",
	msg_flamestrike      = "离开火焰区域！",
	warn_flamestrike     = "躲开",
	bar_ls_earthstomp    = "活体石块-践踏",
	msg_dm_quake         = "土堆！快躲开！",
	msg_dm_target_you    = "土堆正在追你！",
	bar_reform           = "鲁普图兰重组中",
	msg_boulder          = "正在对%s施放巨石",
	msg_boulderMiss      = "巨石未命中，未生成活体石块",
	say_boulder          = "巨石正在砸向我！",
	bar_window           = "机会窗口",
	msg_windowOpen       = "击杀鲁普图兰-所有活体石块已死",
	msg_windowClosing    = "活体石块即将出现！",
	msg_windowClosed     = "活体石块存活！不要击杀鲁普图兰",
	msg_felheartMana     = "魔心法力值%s%%！",
	bar_fragment	     = "碎块",


	-- 触发器
	trigger_start = "一切都将崩溃", -- 开始触发器
	trigger_phase2 = "让这个世界的裂缝摧毁你", -- 第二阶段触发器
	trigger_boss_dead = "化为尘土", -- 老板死亡触发器
	unit_felheart        = "恶魔之心",
	unit_fragment        = "鲁普图兰的碎块",

	trigger_tb_cast      = "破碎者鲁普图兰开始施展投掷巨石",
	trigger_tb_hit       = "破碎者鲁普图兰的投掷巨石击中(.+)",
	trigger_tb_miss      = "破碎者鲁普图兰的投掷巨石没有击中(.+)%.", 
	trigger_ls_fades = "紧急着陆效果从活体石块身上消失", -- 活石坠落冲击消失触发器
	trigger_ls_die       = "活体石块死亡了",
	trigger_dm_quake = "土堆的地震对你造成", -- 泥土堆地震触发器
	trigger_dm_spawn = "鲁普图兰命令大地粉碎(.+)", -- 泥土堆生成触发器
	trigger_dm_die = "土堆死亡了", -- 泥土堆死亡触发器
	trigger_igniteearth  = "破碎者鲁普图兰开始施放灼热大地",
    trigger_flamestrike = "你受到了灼热大地效果的影响",
    trigger_igniterock = "鲁普图兰的碎块开始施放燃烧岩柱",
    trigger_reform = "鲁普图兰的碎块开始施放重塑"
} end)

local timer = {
	boulderCast = 2,
	boulderCD = {13,16}, -- lowest 12.6, highest 16.8
	earthstomp = 5,
	igniteEarthCast = 3,
	igniteEarthCD = {15,19}, -- interval based on logs, rarely 14, mostly 16
	igniteRockCD = {20,53},
	igniteRock = 3,
	reform = 10,
}

local icon = {
	earthstomp	= "Ability_ThunderClap",
	quake		= "Spell_Nature_Earthquake",
	igniteEarth	= "Spell_Fire_Immolation",
	igniteRock	= "Spell_Fire_SelfDestruct",
	fire		= "Spell_Fire_Fire", -- warning when standing in Ignite Rock (confusing if same icon as incoming cast)
	reform		= "Spell_Nature_AstralRecalGroup",
	window		= "INV_Misc_PocketWatch_01",
	felheart	= "Spell_Holy_PrayerOfFortitude",
	fragment	= "Spell_Nature_StrengthOfEarthTotem02",
}

local syncName = {
	earthstomp = "RupturanEarthStomp"..module.revision,
	igniteEarth = "RupturanIgniteEarth"..module.revision,
	igniteRock = "RupturanIgniteRock"..module.revision,
	dm_spawn = "RupturanDirtMoundSpawn"..module.revision,
	phase2 = "RupturanPhaseTwo"..module.revision,
	reform = "RupturanReform"..module.revision,
	throwBoulderCast = "RupturanThrowBoulderCast"..module.revision,
	throwBoulderOutcome = "RupturanThrowBoulderOutcome"..module.revision,
	livingStoneDeath = "RupturanLivingStoneDeath"..module.revision,
}

local spellIds = {
	igniteEarth		= 52040,
	throwBoulder	= 51289,
	igniteRock		= 51298,
	reform			= 51299,
}

local guid = {
	rupturan = "0xF13000EA39073D35",
	felheart = nil,
	fragmentA = nil,
	fragmentB = nil,
	fragmentC = nil,
}

-- keep track of players to later reset raid marks, and active Living Stones
local mound_chasing = nil
local boulder_victim = nil
local last_boulder = 0
local active_living_stones = 0
local last_mana_warn = 0


-------------------------------------------------------------------------------
--  Initialization
-------------------------------------------------------------------------------

module:RegisterYellEngage(L.trigger_start)

function module:OnEnable()
	-- Living Stone stomp countdown
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")

	-- Quake damage, Throw Boulder
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellEvent") -- also non-SuperWoW Ignite Earth & Ignite Rock cast

	-- Dirt Mound spawn target announcement (emote)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "Event")

	-- phase2
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")

	-- Ignite Rock affliction
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")

	if SUPERWOW_VERSION or SetAutoloot then
		self:RegisterEvent("UNIT_CASTEVENT")
	else
		self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "SpellEvent") -- Reform cast
	end

	self:ThrottleSync(2, syncName.earthstomp)
	self:ThrottleSync(4, syncName.igniteEarth)
	self:ThrottleSync(1, syncName.igniteRock)
	self:ThrottleSync(2, syncName.dm_spawn)
	self:ThrottleSync(2, syncName.phase2)
	self:ThrottleSync(1, syncName.reform)
	self:ThrottleSync(5, syncName.throwBoulderCast)
	self:ThrottleSync(5, syncName.throwBoulderOutcome)
	self:ThrottleSync(0.5, syncName.livingStoneDeath)
	self:Message("友情提示：卸下勇士印记/吃火抗冰冻符文", "Important", false, nil, false)
end

-- function module:OnSetup()
-- end

function module:OnEngage()
	mound_chasing = nil
	boulder_victim = nil
	last_boulder = 0
	active_living_stones = 0
	last_mana_warn = 0
	self:RemoveFragmentBars()
end

function module:OnDisengage()
	-- clean up bars
	self:RemoveBar(L.bar_ls_earthstomp)
	self:CancelDelayedBar(L.bar_ignite_earth_CD)
	self:RemoveBar(L.bar_ignite_earth_CD)
	self:RestorePreviousRaidTargetForPlayer(mound_chasing)
	self:RestorePreviousRaidTargetForPlayer(boulder_victim)
	self:CancelScheduledEvent("RupturanFindFelheart")
	self:CancelScheduledEvent("RupturanCheckFelheart")
	self:RemoveFragmentBars()
end

-------------------------------------------------------------------------------
--  Event Handler
--------------------------------------------------------------------------------

function module:Event(msg)
	-- Living Stone fade → start stomp timer
	if self.db.profile.livingstone and string.find(msg, L.trigger_ls_fades) then
		self:Sync(syncName.earthstomp)
		return
	end
	-- Dirt Mound spawn emote: capture player name
	local _,_,player = string.find(msg, L.trigger_dm_spawn)
	if player then
		self:Sync(syncName.dm_spawn .. " " .. player)
		return
	end
	if string.find(msg, L.trigger_phase2) then
		self:Sync(syncName.phase2)
		return
	end
	if string.find(msg, L.trigger_boss_dead) then
		self:SendBossDeathSync()
		return
	end
	if self.db.profile.flamestrikemove and string.find(msg, L.trigger_flamestrike) then
		self:WarningSign(icon.fire, 2, false, L.warn_flamestrike)
		self:Message(L.msg_flamestrike, "Important", true, "Info")
	end
end

function module:LowestFragmentCastTimeCoefficient()
	local coefficientA = BigWigs:GetCastTimeCoefficient(guid.fragmentA)
	local coefficientB = BigWigs:GetCastTimeCoefficient(guid.fragmentB)
	local coefficientC = BigWigs:GetCastTimeCoefficient(guid.fragmentC)
	
	return math.min(coefficientA, coefficientB, coefficientC)
end

function module:UNIT_CASTEVENT(caster,target,action,spellId,castTime)
	if spellId == spellIds.igniteEarth and action == "START" then
		self:Sync(syncName.igniteEarth .. " " .. (castTime / 1000))
		return
	end
	if spellId == spellIds.throwBoulder and action == "START" then
		self:Sync(syncName.throwBoulderCast .. " " .. UnitName(target))
		return
	end
	if spellId == spellIds.igniteRock and action == "START" then
		-- check if perhaps other fragments have quicker casts (missing CoT) and sync the lowest cast time to warn about the first Ignite Rock
		local shortestCast = timer.igniteRock * self:LowestFragmentCastTimeCoefficient() * 1000
		if castTime > shortestCast then
			castTime = shortestCast
		end
		self:Sync(syncName.igniteRock .. " " .. (castTime / 1000))
		return
	end
	if spellId == spellIds.reform and action == "START" then
		self:Sync(syncName.reform)
		return
	end
end

function module:SpellEvent(msg)
	-- non-SuperWoW Ignite Earth cast
	if string.find(msg, L.trigger_igniteearth) and not SUPERWOW_VERSION then
		local castTime = timer.igniteEarthCast * BigWigs:GetCastTimeCoefficient(guid.rupturan)
		self:Sync(syncName.igniteEarth .. " " .. castTime)
		return
	end

	-- Quake hit on you
	if string.find(msg, L.trigger_dm_quake) then
		self:DirtMoundQuake() -- personal damage, no syncing
		return
	end

	-- Throw Boulder cast
	if string.find(msg, L.trigger_tb_cast) and not SUPERWOW_VERSION then
		self:ScheduleEvent("RupturanDelayedTargetCheck", self.DelayedTargetCheck, 0.2, self)
		return
	end
	
	-- Throw Boulder hit
	local _,_,player = string.find(msg, L.trigger_tb_hit)
	if player then
		player = player == "你" and UnitName("player") or player
		if player == boulder_victim then
			self:Sync(syncName.throwBoulderOutcome .. "投掷巨石击中")
		end
		return
	end
	
	-- Throw Boulder miss
	local _,_,player = string.find(msg, L.trigger_tb_miss)
	if player then
		player = player == "你" and UnitName("player") or player
		if player == boulder_victim then
			self:Sync(syncName.throwBoulderOutcome .. "投掷巨石没有击中")
		end
		return
	end

	-- non-SuperWoW Ignite Rock cast
	if string.find(msg, L.trigger_igniterock) and not SUPERWOW_VERSION  then
		-- sync lowest cast time among all Fragments (one might be missing CoT)
		local castTime = timer.igniteRock * self:LowestFragmentCastTimeCoefficient()
		self:Sync(syncName.igniteRock .. " " .. castTime)
		return
	end

	-- non-SuperWoW Reform cast
	if string.find(msg, L.trigger_reform) then
		self:Sync(syncName.reform)
		return
	end
end

function module:OnEnemyDeath(msg)
	if string.find(msg, L.trigger_ls_die) then
		self:Sync(syncName.livingStoneDeath)
	end
end

function module:DelayedTargetCheck()
	local target = BigWigs:GetTargetByName(module.translatedName, 1)
	if target then
		self:Sync(syncName.throwBoulderCast .. " " .. target)
	end
end

--------------------------------------------------------------------------------
--  Sync handler
--------------------------------------------------------------------------------

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.earthstomp then
		self:CrashLandingFades()

	elseif sync == syncName.igniteEarth and rest then
		local castTime = tonumber(rest)
		self:IgniteEarth(castTime)

	elseif sync == syncName.dm_spawn and rest then
		self:DirtMoundSpawn(rest)

	elseif sync == syncName.phase2 then
		self:Phase2()

	elseif sync == syncName.igniteRock and rest then
		local castTime = tonumber(rest)
		self:IgniteRock(castTime)

	elseif sync == syncName.reform then
		self:Reform()

	elseif sync == syncName.throwBoulderCast and rest then
		self:ThrowBoulder(rest)

	elseif sync == syncName.throwBoulderOutcome and rest then
		self:ThrowBoulderOutcome(rest)

	elseif sync == syncName.livingStoneDeath then
		active_living_stones = active_living_stones - 1
		self:CheckOpportunity()
	end
end

function module:CrashLandingFades()
	if not self.db.profile.livingstone then return end

	self:Sound("Alarm")
	self:Bar(L.bar_ls_earthstomp, timer.earthstomp, icon.earthstomp)
end

function module:IgniteEarth(castTime)
	if not self.db.profile.igniteearth then return end
		
	castTime = castTime or (timer.igniteEarthCast * BigWigs:GetCastTimeCoefficient(guid.rupturan))

	-- Remove any ongoing CD bar
	self:CancelDelayedBar(L.bar_ignite_earth_CD)
	self:RemoveBar(L.bar_ignite_earth_CD)

	-- Put up cast bar
	self:Bar(L.bar_ignite_earth, castTime, icon.igniteEarth)
	self:Sound("Info")
	-- Schedule CD bar to show after cast finishes
	self:DelayedIntervalBar(castTime, L.bar_ignite_earth_CD, timer.igniteEarthCD[1]-castTime, timer.igniteEarthCD[2]-castTime, icon.igniteEarth, true, "ItemQuality0")
end

function module:DirtMoundQuake()
	if not self.db.profile.dirtmound then return end

	self:Message(L.msg_dm_quake, "Important", true, "Info")
end

function module:DirtMoundSpawn(player)
	if not player then return end

	if self.db.profile.dirtmoundmark then
		self:RestorePreviousRaidTargetForPlayer(mound_chasing)
		self:SetRaidTargetForPlayer(player, 3) -- diamond
		mound_chasing = player
	end

	if not self.db.profile.dirtmound then return end
	if player == UnitName("player") then
		-- you're the target: big warning
		self:WarningSign(icon.quake, 5, true, L.msg_dm_target_you)
		self:Sound("RunAway")
		SendChatMessage("土堆在追我!", "SAY")
	end
end

function module:Phase2()
	-- cancel P1 bars
	self:CancelDelayedBar(L.bar_ignite_earth_CD)
	self:RemoveBar(L.bar_ignite_earth_CD)
	self:RemoveBar(L.bar_window)
	-- clear popcorn mark
	self:RestorePreviousRaidTargetForPlayer(mound_chasing)
	mound_chasing = nil
	-- start looking for adds
	guid.felheart = nil
	self:FindFelheart()
	guid.fragmentA = nil
	guid.fragmentB = nil
	guid.fragmentC = nil
	self:FindFragments()
end

function module:IgniteRock(castTime)
	if not self.db.profile.flamestrike then return end
	castTime = castTime or (timer.igniteRock * self:LowestFragmentCastTimeCoefficient())

	self:Sound("Alarm")
	self:WarningSign(icon.igniteRock, 3, true, L.warn_ignite_rock)
	self:Bar(L.bar_ignite_rock, castTime, icon.igniteRock)
end

function module:Reform()
	if not self.db.profile.reform then return end

	self:Bar(L.bar_reform, timer.reform, icon.reform)
end

function module:ThrowBoulder(targetName)
	boulder_victim = targetName
	last_boulder = GetTime()
	
	if self.db.profile.boulderalert then
		self:Message(string.format(L.msg_boulder, targetName), "Attention")
	end

	if self.db.profile.bouldermark then
		self:SetRaidTargetForPlayer(targetName, "Moon")
	end

	if targetName == UnitName("player") and self.db.profile.bouldersay then
		SendChatMessage(L.say_boulder, "SAY")
	end
	
	if self:GetHealth() <= 15 and self.db.profile.opportunity then
		self:Bar(L.bar_window, timer.boulderCast - 0.3, icon.window, true, "White")
		if not self.db.profile.boulderalert then -- don't double up on messages
			self:Message(L.msg_windowClosing, "Urgent", true, "Beware")
		end
	end
end

function module:ThrowBoulderOutcome(outcome)
	if outcome == "投掷巨石击中" then
		active_living_stones = active_living_stones + 1
		if self:GetHealth() <= 15 and self.db.profile.opportunity then
			self:RemoveBar(L.bar_window)
			self:Message(L.msg_windowClosed, "Important", nil, "Alert")
		end
	end

	if outcome == "投掷巨石没有击中" then
		if self.db.profile.boulderalert then
			self:Message(L.msg_boulderMiss, "Positive", true, "Long")
		end
		if boulder_victim == UnitName("player") and self.db.profile.bouldersay then
			SendChatMessage(L.msg_boulderMiss, "SAY")
		end
		self:CheckOpportunity()
	end

	-- clear victim
	self:RestorePreviousRaidTargetForPlayer(boulder_victim)
	boulder_victim = nil
end

function module:GetHealth()
	local health = 100 -- set to 9 to test window of opportunity
	if UnitExists(guid.rupturan) then
		health = math.floor((UnitHealth(guid.rupturan)/UnitHealthMax(guid.rupturan)) * 100)
	end
	return health
end

function module:CheckOpportunity()
	if self:GetHealth() > 15 or (not self.db.profile.opportunity) then return end

	local windowHigh = last_boulder + timer.boulderCD[2] + timer.boulderCast - GetTime()
	if active_living_stones == 0 and windowHigh > 3 then
		self:Bar(L.bar_window, windowHigh, icon.window, true, "White")
		self:Message(L.msg_windowOpen, "Positive")
	end
end

function module:FindFelheart()
	local found = BigWigs:GetGUIDByName(L.unit_felheart, 1)
	if found then
		guid.felheart = found
		if self.db.profile.felheartalert then
			self:ScheduleRepeatingEvent("RupturanCheckFelheart", self.CheckFelheart, 0.5, self)
		end		
		if self.db.profile.felheartbar then
			self:MonitorBar("Felheart Mana", icon.felheart, guid.felheart, "mana", L.unit_felheart)
		end
	else
		self:ScheduleEvent("RupturanFindFelheart", self.FindFelheart, 0.5, self)
	end
end

function module:CheckFelheart()
	if self.db.profile.felheartalert and guid.felheart and UnitExists(guid.felheart) then
		local percent = math.ceil(UnitMana(guid.felheart)/UnitManaMax(guid.felheart) * 100)
		if percent >= 80 and last_mana_warn + 5 < GetTime() then
			self:Message(string.format(L.msg_felheartMana, percent), "Core", nil, "Beware")
			last_mana_warn = GetTime()
		end
	else
		-- if alert disabled or Felheart doesn't currently exist stop checking
		self:CancelScheduledEvent("RupturanCheckFelheart")
	end
end

function module:FindFragments()
	local newFragment = BigWigs:GetGUIDByName(L.unit_fragment, 1, {guid.fragmentA, guid.fragmentB, guid.fragmentC}) -- can replace unit name for testing
	if newFragment then
		if not guid.fragmentA then
			guid.fragmentA = newFragment
		elseif not guid.fragmentB then
			guid.fragmentB = newFragment
		elseif not guid.fragmentC then
			guid.fragmentC = newFragment
			self:CreateFragmentBars()
			return
		end
	end
	self:ScheduleEvent("RupturanFindFragments", self.FindFragments, 0.2, self)
end

function module:CreateFragmentBars()
	if self.db.profile.fragmentbars then
		self:MonitorBar("fragmentA", icon.fragment, guid.fragmentA, "health", L.bar_fragment, true)
		self:MonitorBar("fragmentB", icon.fragment, guid.fragmentB, "health", L.bar_fragment, true)
		self:MonitorBar("fragmentC", icon.fragment, guid.fragmentC, "health", L.bar_fragment, true)
	end
end

function module:RemoveFragmentBars()
	self:RemoveBar("fragmentA")
	self:RemoveBar("fragmentB")
	self:RemoveBar("fragmentC")
end