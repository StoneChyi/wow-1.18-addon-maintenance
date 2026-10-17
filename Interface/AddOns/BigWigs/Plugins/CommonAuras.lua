
local name = "Common Auras"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs" .. name)
local BC = AceLibrary("Babble-Class-2.2")
local BS = AceLibrary("Babble-Spell-2.2")

local bzorgrimmar = AceLibrary("Babble-Zone-2.2")["Orgrimmar"]
local bzthunderbluff = AceLibrary("Babble-Zone-2.2")["Thunder Bluff"]
local bzundercity = AceLibrary("Babble-Zone-2.2")["Undercity"]
local bzstonard = AceLibrary("Babble-Zone-2.2")["Stonard"]
local bzstormwind = AceLibrary("Babble-Zone-2.2")["Stormwind City"]
local bzironforge = AceLibrary("Babble-Zone-2.2")["Ironforge"]
local bzdarnassus = AceLibrary("Babble-Zone-2.2")["Darnassus"]
local bztheramore = AceLibrary("Babble-Zone-2.2")["Theramore Isle"]
local bzkarazhan = AceLibrary("Babble-Zone-2.2")["Karazhan"]

local spellStatus = nil

local whZone = nil
local whColor = nil
local whText = nil

local portalColor = nil
local portalText = nil

local PROTOCOL_VERSION = "2.16.1"

-- Use for detecting instant cast target (Fear Ward)
local spellTarget = nil
local spellCasting = nil

local timeToShutdown = nil
local shutdownBigWarning = nil

L:RegisterTranslations("enUS", function()
	return {
		-- iconPrefix = "Interface\\Icons\\",

		-- msg_fearward = " FearWard on ",
		-- bar_fearward = " FearWard CD",

		-- msg_shieldwall = " Shield Wall",
		-- bar_shieldwall = " Shield Wall",

		-- msg_laststand = " Last Stand",
		-- bar_laststand = " Last Stand",

		-- msg_lifegivingGem = " Enlightened State",
		-- bar_lifegivingGem = " Enlightened State",

		-- msg_challengingShout = " Challenging Shout",
		-- bar_challengingShout = " Challenging Shout",

		-- msg_challengingRoar = " Challenging Roar",
		-- bar_challengingRoar = " Challenging Roar",

		-- msg_divineIntervention = "Divine Intervention on ",
		-- bar_divineIntervention = " Divine Intervention",

		-- msg_divineIntervention = "Divine Intervention on ",
		-- bar_divineIntervention = " Divine Intervention",

		-- msg_barkskin = " Barkskin",
		-- bar_barkskin = " Barkskin",

		-- msg_berserk = " Berserk",
		-- bar_berserk = " Berserk",


		trigger_barkskin = "You cast Barkskin.",
		trigger_berserk = "You cast Berserk.",
		trigger_spiritlink = "You cast Spirit Link on (.+).",
		trigger_spiritlink_self = "You cast Spirit Link.",
		trigger_fearward = "You cast Fear Ward on (.+).",
		trigger_fearward_self = "You cast Fear Ward.",

		-- msg_spiritlink = " Spirit Link on ",

		-- msg_spiritlink = " Spirit Link on ",

		-- msg_spiritlink = " Spirit Link on ",
		-- bar_spiritlink = " Spirit Link",

		trigger_scythe = "You cast The Scythe of Elune.",
		msg_scythe = " Scythe of Elune",
		bar_scythe = " Scythe of Elune",

		trigger_scythe = "You cast The Scythe of Elune.",
		msg_scythe = " Scythe of Elune",
		bar_scythe = " Scythe of Elune",

		-- portal_regexp = ".*: (.*)",

		-- trigger_wormhole = "just opened a wormhole.", --CHAT_MSG_MONSTER_EMOTE
		-- bar_wormhole = " Wormhole",
		-- msg_wormhole = " Wormhole",

		-- trigger_orange = "begins to conjure a refreshment table.", --CHAT_MSG_MONSTER_EMOTE
		-- bar_orange = "Oranges!",
		-- msg_orange = "Oranges! Get your Vitamin C",

		-- trigger_soulwell = "begins a Soulwell ritual.", --CHAT_MSG_MONSTER_EMOTE
		-- bar_soulwell = "Soulwell!",
		-- msg_soulwell = "Soulwell! Get your Cookie",

		-- trigger_shutdown = "Shutdown in (.+) (.+)", --CHAT_MSG_SYSTEM
		-- trigger_restart = "Restart in (.+) (.+)", --CHAT_MSG_SYSTEM
		-- trigger_restartMinSec = "Shutdown in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
		-- trigger_shutdownMinSec = "Restart in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
		-- bar_shutDown = "Server Shutdown/Restart",
	
		casounds = "Common Auras Sounds",
		
		["Toggle %s display."] = true,
		["Wormhole"] = true,
		["Orange"] = true,
		["Soulwell"] = true,
		["Portal"] = true,
		["Shutdown"] = true,
		["broadcast"] = true,
		["Broadcast"] = true,
		["Toggle broadcasting the messages to the raidwarning channel."] = true,
		["Enable the Sounds for Common Auras Events"] = true,

		["Gives timer bars and raid messages about common buffs and debuffs."] = true,
		["Common Auras"] = true,
		["commonauras"] = true,

		["Invisibility"] = true,
		["Deepwood Pipe"] = true,
		["Lesser Invisibility"] = true,
		["Limited Invulnerability Potion"] = true,
		["Blessing of Protection"] = true,
		["Power Infusion"] = true,

		-- ["di_trigger"] = "You gain Divine Intervention",
		-- ["invis_trigger"] = "You gain Invisibility",
		-- ["lesser_invis_trigger"] = "You gain Lesser Invisibility",
		-- ["cloaking_invis_trigger"] = "You gain Cloaking",
		-- ["lip_trigger"] = "You gain Invulnerability",
		-- ["bop_trigger"] = "You gain Blessing of Protection",
		-- ["powerinfusion_trigger"] = "You gain Power Infusion",
		-- ["deepwoodpipe_trigger"] = "You gain Smoke Cloud", -- use this as trigger instead of Stealth due to overlap with rogue ability

		-- ["di_fades"] = "Divine Intervention fades",
		-- ["invis_fades"] = "Invisibility fades",
		-- ["lesser_invis_fades"] = "Lesser Invisibility fades",
		-- ["cloaking_invis_fades"] = "Cloaking fades",
		-- ["lip_fades"] = "Invulnerability fades",
		-- ["bop_fades"] = "Blessing of Protection fades",
		-- ["powerinfusion_fades"] = "Power Infusion fades",
		-- ["deepwoodpipe_fades"] = "Stealth fades",

		--英文端汉化，wind
		iconPrefix = "Interface\\Icons\\",

	msg_fearward = " 防护恐惧结界 ",
	bar_fearward = " 防护恐惧结界冷却",
	
	msg_shieldwall = " 盾墙",
	bar_shieldwall = " 盾墙",
	
	msg_laststand = " 破釜沉舟",
	bar_laststand = " 破釜沉舟",
	
	msg_lifegivingGem = " 生命宝石",
	bar_lifegivingGem = " 生命宝石",
	
	msg_challengingShout = " 挑战怒吼",
	bar_challengingShout = " 挑战怒吼",
	
	msg_challengingRoar = " 挑战咆哮",
	bar_challengingRoar = " 挑战咆哮",
	
	msg_divineIntervention = "圣佑术在 ",
	bar_divineIntervention = " 圣佑术",

	msg_barkskin = " 树皮术",
	bar_barkskin = " 树皮术",

	msg_berserk = " 狂暴",
	bar_berserk = " 狂暴",

	msg_spiritlink = " 灵魂连接: ",
	msg_spiritlink = " 灵魂连接: ",
	bar_spiritlink = " 灵魂连接",

	msg_scythe = " 艾露恩之镰",
	bar_scythe = " 艾露恩之镰",

	["Enslave Demon"] = true,
	trigger_enslave = "施放了奴役恶魔",
	enslave_regexp = "对(.+)施放了奴役恶魔",
	trigger_enslave_pet = "受到了奴役恶魔效果的影响",
	enslave_aura_regexp = "(.+)受到了奴役恶魔效果的影响",
	msg_enslave = " 奴役了 ",
	bar_enslave = " 奴役恶魔",
	msg_enslave_expiring = "的奴役恶魔即将失效！",
	msg_enslave_gone = "的奴役恶魔已失效，小心恶魔失控！",

		portal_regexp = ".*: (.*)",

		trigger_wormhole = "just opened a wormhole.", --CHAT_MSG_MONSTER_EMOTE
	bar_wormhole = " 虫洞",
	msg_wormhole = " 虫洞",

		trigger_orange = "begins to conjure a refreshment table.", --CHAT_MSG_MONSTER_EMOTE
	bar_orange = "橙子！",
	msg_orange = "橙子！补充维生素C",

		trigger_soulwell = "begins a Soulwell ritual.", --CHAT_MSG_MONSTER_EMOTE
	bar_soulwell = "灵魂之井!",
	msg_soulwell = "灵魂之井！拿你的饼干",

		trigger_shutdown = "Shutdown in (.+) (.+)", --CHAT_MSG_SYSTEM
		trigger_restart = "Restart in (.+) (.+)", --CHAT_MSG_SYSTEM
		trigger_restartMinSec = "Shutdown in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
		trigger_shutdownMinSec = "Restart in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
	bar_shutDown = "服务器关机/重启",

    
    -- casounds = "常用光环音效",
        
	["Toggle %s display."] = "切换%s显示。",
	-- ["Wormhole"] = "虫洞",
	-- ["Orange"] = "橘子",
	-- ["Soulwell"] = "灵魂之井",
	-- ["Portal"] = "传送门",
	-- ["Shutdown"] = "关机",
	-- ["broadcast"] = "广播",
	-- ["Broadcast"] = "广播",
	["Toggle broadcasting the messages to the raidwarning channel."] = "切换广播信息到团队警告频道。",
	["Enable the Sounds for Common Auras Events"] = "启用常用光环事件的音效",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "提供关于常见增益和减益的计时条和团队信息。",
	["Common Auras"] = "常见的光环",
	-- ["commonauras"] = "常见的光环",

		["Invisibility"] = "隐形术",
		["Deepwood Pipe"] = "深木管",
		["Lesser Invisibility"] = "次级隐形术",
		["Limited Invulnerability Potion"] = "有限无敌药水",
		["Blessing of Protection"] = "保护祝福",
		["Power Infusion"] = "能量灌注",

		["di_trigger"] = "You gain Divine Intervention",
		["invis_trigger"] = "You gain Invisibility",
		["lesser_invis_trigger"] = "You gain Lesser Invisibility",
		["cloaking_invis_trigger"] = "You gain Cloaking",
		["lip_trigger"] = "You gain Invulnerability",
		["bop_trigger"] = "You gain Blessing of Protection",
		["powerinfusion_trigger"] = "You gain Power Infusion",
		["deepwoodpipe_trigger"] = "You gain Smoke Cloud", -- use this as trigger instead of Stealth due to overlap with rogue ability

		["di_fades"] = "Divine Intervention fades",
		["invis_fades"] = "Invisibility fades",
		["lesser_invis_fades"] = "Lesser Invisibility fades",
		["cloaking_invis_fades"] = "Cloaking fades",
		["lip_fades"] = "Invulnerability fades",
		["bop_fades"] = "Blessing of Protection fades",
		["powerinfusion_fades"] = "Power Infusion fades",
		["deepwoodpipe_fades"] = "Stealth fades",

	Dwarf = "Dwarf",
	Alliance = "Alliance",
	Horde = "Horde",
	inminutesseconds = " in (.+) Minutes (.+) Seconds.",
	in_plus = " in (.+) (.+)",
	inute = "inute",
	["Warlock Pet"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
	-- Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22
		iconPrefix = "Interface\\Icons\\",

	msg_fearward = " 防护恐惧结界 ",
	bar_fearward = " 防护恐惧结界冷却",
	
	msg_shieldwall = " 盾墙",
	bar_shieldwall = " 盾墙",
	
	msg_laststand = " 破釜沉舟",
	bar_laststand = " 破釜沉舟",
	
	msg_lifegivingGem = " 生命宝石",
	bar_lifegivingGem = " 生命宝石",
	
	msg_challengingShout = " 挑战怒吼",
	bar_challengingShout = " 挑战怒吼",
	
	msg_challengingRoar = " 挑战咆哮",
	bar_challengingRoar = " 挑战咆哮",
	
	msg_divineIntervention = "圣佑术在 ",
	bar_divineIntervention = " 圣佑术",

	msg_barkskin = " 树皮术",
	bar_barkskin = " 树皮术",

	msg_berserk = " 狂暴",
	bar_berserk = " 狂暴",

	msg_spiritlink = " 灵魂连接: ",
	bar_spiritlink = " 灵魂连接",

	msg_scythe = " 艾露恩之镰",
	bar_scythe = " 艾露恩之镰",

	["Enslave Demon"] = "奴役恶魔",
	trigger_enslave = "施放了奴役恶魔",
	enslave_regexp = "对(.+)施放了奴役恶魔",
	trigger_enslave_pet = "受到了奴役恶魔效果的影响",
	enslave_aura_regexp = "(.+)受到了奴役恶魔效果的影响",
	msg_enslave = " 奴役了 ",
	bar_enslave = " 奴役恶魔",
	msg_enslave_expiring = "的奴役恶魔即将失效！",
	msg_enslave_gone = "的奴役恶魔已失效，小心恶魔失控！",

	trigger_barkskin = "你施放了树皮术",
	trigger_berserk = "你施放了狂暴。",
	trigger_spiritlink = "你对(.+)施放了灵魂连接。",
	trigger_spiritlink_self = "你施放了灵魂连接。",
	trigger_fearward = "你对(.+)施放了防护恐惧结界。",
	trigger_fearward_self = "你施放了防护恐惧结界。",

		portal_regexp = ".*: (.*)",

		portal_regexp = ".*: (.*)",

		trigger_wormhole = "just opened a wormhole.", --CHAT_MSG_MONSTER_EMOTE
	bar_wormhole = " 虫洞",
	msg_wormhole = " 虫洞",

		trigger_orange = "begins to conjure a refreshment table.", --CHAT_MSG_MONSTER_EMOTE
	bar_orange = "橙子！",
	msg_orange = "橙子！补充维生素C",

		trigger_soulwell = "begins a Soulwell ritual.", --CHAT_MSG_MONSTER_EMOTE
	bar_soulwell = "灵魂之井!",
	msg_soulwell = "灵魂之井！拿你的糖",

		trigger_shutdown = "Shutdown in (.+) (.+)", --CHAT_MSG_SYSTEM
		trigger_restart = "Restart in (.+) (.+)", --CHAT_MSG_SYSTEM
		trigger_restartMinSec = "Shutdown in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
		trigger_shutdownMinSec = "Restart in (.+) Minutes (.+) Seconds.", --CHAT_MSG_SYSTEM
	bar_shutDown = "服务器关机/重启",
    
    casounds = "常用光环音效",
        
	["Toggle %s display."] = "切换%s显示。",
	["Wormhole"] = "虫洞",
	["Orange"] = "橘子",
	["Soulwell"] = "灵魂之井",
	["Portal"] = "传送门",
	["Shutdown"] = "关机",
	["broadcast"] = "广播",
	["Broadcast"] = "广播",
	["Toggle broadcasting the messages to the raidwarning channel."] = "切换广播信息到团队警告频道。",
	["Enable the Sounds for Common Auras Events"] = "启用常用光环事件的音效",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "提供关于常见增益和减益的计时条和团队信息。",
	["Common Auras"] = "常见的光环",
	["commonauras"] = "常见的光环",

		["Invisibility"] = "隐形术",
		["Deepwood Pipe"] = "深木管",
		["Lesser Invisibility"] = "次级隐形术",
		["Limited Invulnerability Potion"] = "有限无敌药水",
		["Blessing of Protection"] = "保护祝福",
		["Power Infusion"] = "能量灌注",

		["di_trigger"] = "You gain Divine Intervention",
		["invis_trigger"] = "You gain Invisibility",
		["lesser_invis_trigger"] = "You gain Lesser Invisibility",
		["cloaking_invis_trigger"] = "You gain Cloaking",
		["lip_trigger"] = "You gain Invulnerability",
		["bop_trigger"] = "保护[祝之][福手]",
		["powerinfusion_trigger"] = "You gain Power Infusion",
		["deepwoodpipe_trigger"] = "You gain Smoke Cloud", -- use this as trigger instead of Stealth due to overlap with rogue ability

        ["di_fades"] = "神圣干涉消失了",
        ["invis_fades"] = "隐形术消失了",
        ["lesser_invis_fades"] = "次级隐形术消失了",
        ["cloaking_invis_fades"] = "隐蔽消失了",
        ["lip_fades"] = "无敌消失了",
        ["bop_fades"] = "保护[祝之][福手]",
        ["powerinfusion_fades"] = "能量灌注消失了",
        ["deepwoodpipe_fades"] = "潜行消失了",

	Dwarf = "矮人",
	Alliance = "联盟",
	Horde = "部落",
	inminutesseconds = "在 (.+) 分钟 (.+) 秒。",
	in_plus = "在 (.+) (.+)",
	inute = "分",
	["Warlock Pet"] = "术士宠物",
	}
end)

BigWigsCommonAuras = BigWigs:NewModule(name, "AceHook-2.1")
BigWigsCommonAuras.synctoken = myname
BigWigsCommonAuras.defaultDB = {
	challengingshout = true,
	laststand = true,
	shieldwall = true,
	
	challengingroar = true,
	
	bop = true,
	deepwood = true,
	di = true,
	fearward = true,
	invis = true,
	lifegivinggem = true,
	lip = true,
	powerinfusion = true,
	
	barkskin = true,
	berserk = true,
	spiritlink = true,
	
	orange = true,
	portal = true,
	shutdown = true,
	soulwell = true,
	wormhole = true,
	warlockpet = true,
	enslave = true,
	
	broadcast = false,
	
	casounds = true,
}
BigWigsCommonAuras.consoleCmd = L["commonauras"]
BigWigsCommonAuras.revision = 30094
BigWigsCommonAuras.external = true
BigWigsCommonAuras.consoleOptions = {
	type = "group",
	name = L["Common Auras"],
	desc = L["Gives timer bars and raid messages about common buffs and debuffs."],
	args = {
		
		
		["challengingshout"] = {
			type = "toggle",
			name = BS["Challenging Shout"],
			order = 1,
			desc = string.format(L["Toggle %s display."], BS["Challenging Shout"]),
			get = function()
				return BigWigsCommonAuras.db.profile.challengingshout
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.challengingshout = v
			end,
		},
		["laststand"] = {
			type = "toggle",
			name = BS["Last Stand"],
			order = 2,
			desc = string.format(L["Toggle %s display."], BS["Last Stand"]),
			get = function()
				return BigWigsCommonAuras.db.profile.laststand
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.laststand = v
			end,
		},
		["shieldwall"] = {
			type = "toggle",
			name = BS["Shield Wall"],
			order = 3,
			desc = string.format(L["Toggle %s display."], BS["Shield Wall"]),
			get = function()
				return BigWigsCommonAuras.db.profile.shieldwall
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.shieldwall = v
			end,
		},
		["spacer1"] = {
			type = "header",
			name = " ",
			order = 4,
		},
	
		["challengingroar"] = {
			type = "toggle",
			name = BS["Challenging Roar"],
			order = 5,
			desc = string.format(L["Toggle %s display."], BS["Challenging Roar"]),
			get = function()
				return BigWigsCommonAuras.db.profile.challengingroar
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.challengingroar = v
			end,
		},
		["barkskin"] = {
			type = "toggle",
			name = L["msg_barkskin"],
			order = 5.1,
			desc = string.format(L["Toggle %s display."], L["msg_barkskin"]),
			get = function()
				return BigWigsCommonAuras.db.profile.barkskin
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.barkskin = v
			end,
		},
		["berserk"] = {
			type = "toggle",
			name = L["msg_berserk"],
			order = 5.2,
			desc = string.format(L["Toggle %s display."], L["msg_berserk"]),
			get = function()
				return BigWigsCommonAuras.db.profile.berserk
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.berserk = v
			end,
		},
		["spiritlink"] = {
			type = "toggle",
			name = L["bar_spiritlink"],
			order = 5.3,
			desc = string.format(L["Toggle %s display."], L["bar_spiritlink"]),
			get = function()
				return BigWigsCommonAuras.db.profile.spiritlink
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.spiritlink = v
			end,
		},
		["spacer2"] = {
			type = "header",
			name = " ",
			order = 6,
		},
		
		["bop"] = {
			type = "toggle",
			name = L["Blessing of Protection"],
			order = 7,
			desc = string.format(L["Toggle %s display."], L["Blessing of Protection"]),
			get = function()
				return BigWigsCommonAuras.db.profile.bop
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.bop = v
			end,
		},
		["deepwood"] = {
			type = "toggle",
			name = L["Deepwood Pipe"],
			order = 8,
			desc = string.format(L["Toggle %s display."], L["Deepwood Pipe"]),
			get = function()
				return BigWigsCommonAuras.db.profile.deepwood
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.deepwood = v
			end,
		},
		["di"] = {
			type = "toggle",
			name = BS["Divine Intervention"],
			order = 9,
			desc = string.format(L["Toggle %s display."], BS["Divine Intervention"]),
			get = function()
				return BigWigsCommonAuras.db.profile.di
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.di = v
			end,
		},
		["fearward"] = {
			type = "toggle",
			name = BS["Fear Ward"],
			order = 10,
			desc = string.format(L["Toggle %s display."], BS["Fear Ward"]),
			get = function()
				return BigWigsCommonAuras.db.profile.fearward
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.fearward = v
			end,
		},
		["invisibility"] = {
			type = "toggle",
			name = L["Invisibility"],
			order = 11,
			desc = string.format(L["Toggle %s display."], L["Invisibility"]),
			get = function()
				return BigWigsCommonAuras.db.profile.invis
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.invis = v
			end,
		},
		["lifegivinggem"] = {
			type = "toggle",
			name = BS["Enlightened State"],
			order = 12,
			desc = string.format(L["Toggle %s display."], BS["Enlightened State"]),
			get = function()
				return BigWigsCommonAuras.db.profile.lifegivinggem
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.lifegivinggem = v
			end,
		},
		["lip"] = {
			type = "toggle",
			name = L["Limited Invulnerability Potion"],
			order = 13,
			desc = string.format(L["Toggle %s display."], L["Limited Invulnerability Potion"]),
			get = function()
				return BigWigsCommonAuras.db.profile.lip
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.lip = v
			end,
		},		
		["powerinfusion"] = {
			type = "toggle",
			name = L["Power Infusion"],
			order = 14,
			desc = string.format(L["Toggle %s display."], L["Power Infusion"]),
			get = function()
				return BigWigsCommonAuras.db.profile.powerinfusion
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.powerinfusion = v
			end,
		},
		["spacer3"] = {
			type = "header",
			name = " ",
			order = 15,
		},
		
		["orange"] = {
			type = "toggle",
			name = L["Orange"],
			order = 16,
			desc = string.format(L["Toggle %s display."], L["Orange"]),
			get = function()
				return BigWigsCommonAuras.db.profile.orange
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.orange = v
			end,
		},
		["portal"] = {
			type = "toggle",
			name = L["Portal"],
			order = 17,
			desc = string.format(L["Toggle %s display."], L["Portal"]),
			get = function()
				return BigWigsCommonAuras.db.profile.portal
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.portal = v
			end,
		},
		["shutdown"] = {
			type = "toggle",
			name = L["Shutdown"],
			order = 18,
			desc = string.format(L["Toggle %s display."], L["Shutdown"]),
			get = function()
				return BigWigsCommonAuras.db.profile.shutdown
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.shutdown = v
			end,
		},
		["soulwell"] = {
			type = "toggle",
			name = L["Soulwell"],
			order = 19,
			desc = string.format(L["Toggle %s display."], L["Soulwell"]),
			get = function()
				return BigWigsCommonAuras.db.profile.soulwell
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.soulwell = v
			end,
		},
		["wormhole"] = {
			type = "toggle",
			name = L["Wormhole"],
			order = 20,
			desc = string.format(L["Toggle %s display."], L["Wormhole"]),
			get = function()
				return BigWigsCommonAuras.db.profile.wormhole
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.wormhole = v
			end,
		},
		["warlockpet"] = {
			type = "toggle",
			name = L["Warlock Pet"],
			order = 21,
			desc = string.format(L["Toggle %s display."], L["Warlock Pet"]),
			get = function()
				return BigWigsCommonAuras.db.profile.warlockpet
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.warlockpet = v
			end,
		},
		["enslave"] = {
			type = "toggle",
			name = L["Enslave Demon"],
			order = 20.5,
			desc = string.format(L["Toggle %s display."], L["Enslave Demon"]),
			get = function()
				return BigWigsCommonAuras.db.profile.enslave
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.enslave = v
			end,
		},
		["spacer4"] = {
			type = "header",
			name = " ",
			order = 21,
		},

		["broadcast"] = {
			type = "toggle",
			name = L["Broadcast"],
			order = 22,
			desc = L["Toggle broadcasting the messages to the raidwarning channel."],
			get = function()
				return BigWigsCommonAuras.db.profile.broadcast
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.broadcast = v
			end,
		},		
		["casounds"] = {
			type = "toggle",
			name = L["casounds"],
			order = 23,
			desc = L["Enable the Sounds for Common Auras Events"],
			get = function()
				return BigWigsCommonAuras.db.profile.casounds
			end,
			set = function(v)
				BigWigsCommonAuras.db.profile.casounds = v
			end,
		},
	}
}

local timer = {
	fearward = 30,
	laststand = 20,
	lifegivingGem = 20,
	challenging = 6,
	di = 60,
	portal = 60,
	wormhole = 8,
	orange = 60,
	soulwell = 60,
	barkskin = 12,
	berserk = 20,
	spiritlink = 20,
	enslave = 300,
}
local icon = {
	fearward = L["iconPrefix"] .. "spell_holy_excorcism",
	shieldwall = L["iconPrefix"] .. "ability_warrior_shieldwall",
	laststand = L["iconPrefix"] .. "spell_holy_ashestoashes",
	lifegivingGem = L["iconPrefix"] .. "inv_misc_gem_pearl_05",
	challengingShout = L["iconPrefix"] .. "ability_bullrush",
	challengingRoar = L["iconPrefix"] .. "ability_druid_challangingroar",
	di = L["iconPrefix"] .. "spell_nature_timestop",
	wormhole = L["iconPrefix"] .. "Inv_Misc_EngGizmos_12",
	orange = L["iconPrefix"] .. "inv_misc_food_41",
	soulwell = L["iconPrefix"] .. "inv_stone_04",
	shutdown = L["iconPrefix"] .. "trade_engineering",
	barkskin = L["iconPrefix"] .. "Spell_Nature_StoneClawTotem",
	berserk = L["iconPrefix"] .. "Ability_Druid_Berserk",
	spiritlink = L["iconPrefix"] .. "Spell_Shaman_SpiritLink",
	enslave = L["iconPrefix"] .. "Spell_Shadow_EnslaveDemon",
}
local color = {
	fearward = "Cyan",
	shieldwall = "Red",
	laststand = "Red",
	lifegivingGem = "Red",
	challengingShout = "Red",
	challengingRoar = "Red",
	di = "Blue",
	wormhole = "Cyan",
	orange = "Green",
	soulwell = "Green",
	shutdown = "White",
	barkskin = "Orange",
	berserk = "Red",
	spiritlink = "Cyan",
	enslave = "Purple",
}

function BigWigsCommonAuras:OnEnable()
	--if UnitName("Player") == "Relar" then self:RegisterEvent("CHAT_MSG_SAY") end --Debug

	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")--trigger_wormhole, trigger_orange, trigger_soulwell
	self:RegisterEvent("CHAT_MSG_SYSTEM")--trigger_shutdown, trigger_restart
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF") -- For custom spells checking

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("UNIT_PET")

	-- Enslave Demon (warlock): 施放成功 + 全部周期增益通道兜底
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PET_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPARTY_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_PET_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("SPELLCAST_START")
	-- 奴役恶魔: 施法结束(成功/失败/打断)清除读条中标记，恢复落地广播
	self:RegisterEvent("SPELLCAST_STOP", "EnslaveCastEnded")
	self:RegisterEvent("SPELLCAST_FAILED", "EnslaveCastEnded")
	self:RegisterEvent("SPELLCAST_INTERRUPTED", "EnslaveCastEnded")

	-- 奴役恶魔: 每 2 秒轮询宠物减益（不依赖日志与事件的终极兜底）
	self:ScheduleRepeatingEvent("BWCA_EnslavePetScan", self.ScanPetEnslave, 2, self)

	-- For Scythe of Elune Party Timer
	self:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
	self:RegisterEvent("CHAT_MSG_ADDON")
	
	-- For Scythe of Elune Party Timer
	self:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
	self:RegisterEvent("CHAT_MSG_ADDON")
	-- DEBUG: Register all spell casts for debugging
	-- self:RegisterEvent("SPELLCAST_STOP")

	if UnitClass("player") == BC["Warrior"] or UnitClass("player") == BC["Druid"] or UnitClass("player") == BC["Shaman"] then
		self:RegisterEvent("SpellStatus_SpellCastInstant")

	elseif UnitClass("player") == BC["Priest"] then
		self:RegisterEvent("SpellStatus_SpellCastInstant")

	elseif UnitClass("player") == BC["Mage"] then
		-- SpellStatusLib 是可选外部依赖（toc OptionalDeps），未安装时 AceLibrary 直接抛错，
		-- 会把整个 CommonAuras 模块的启用流程打断。用 pcall 防御：拿不到库就不注册相关事件
		-- （仅法师传送门施法检测降级，不影响模块启用及其余功能）。
		if not spellStatus then
			local ok, lib = pcall(AceLibrary, "SpellStatus-1.0")
			if ok and lib then
				spellStatus = lib
			end
		end
		if spellStatus then
			self:RegisterEvent("SpellStatus_SpellCastCastingFinish")
			self:RegisterEvent("SpellStatus_SpellCastFailure")
		end
	end

	self:RegisterEvent("BigWigs_RecvSync")
	-- XXX Lets have a low throttle because you'll get 2 syncs from yourself, so
	-- it results in 2 messages.
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAFW", .4) -- Fear Ward
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCASW", .4) -- Shield Wall
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCALS", .4) -- Last Stand
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCALG", .4) -- Last Stand
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCACS", .4) -- Challenging Shout
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCACR", .4) -- Challenging Roar
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAP", .4) -- Portal
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAWH", .4) -- Wormhole
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAOR", .4) -- Orange
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAWL", .4) -- Soulwell
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCABS", .4) -- Barkskin
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCAFR", .4) -- Berserk
	self:TriggerEvent("BigWigs_ThrottleSync", "BWCASL", .4) -- Spirit Link
end

function BigWigsCommonAuras:SpellStatus_SpellCastInstant(sId, sName, sRank, sFullName, sCastTime)
	if sName == BS["Fear Ward"] or tonumber(sId) == 6346 then
		local targetName = nil
		if spellTarget then
			targetName = spellTarget
			spellCasting = nil
			spellTarget = nil
		else
			if UnitExists("target") and UnitIsPlayer("target") and not UnitIsEnemy("target", "player") then
				targetName = UnitName("target")
			else
				targetName = UnitName("player")
			end
		end
		self:TriggerEvent("BigWigs_SendSync", "BWCAFW " .. targetName)
	elseif sName == BS["Shield Wall"] then
		local shieldWallDuration
		local talentName, _, _, _, currentRank, _, _, _ = GetTalentInfo(3, 13)
		if currentRank == 0 then
			shieldWallDuration = 10
		elseif currentRank == 1 then
			shieldWallDuration = 13
		else
			shieldWallDuration = 15
		end
		self:TriggerEvent("BigWigs_SendSync", "BWCASW " .. tostring(shieldWallDuration))
	elseif sName == BS["Last Stand"] then
		self:TriggerEvent("BigWigs_SendSync", "BWCALS")
	elseif sName == BS["Challenging Shout"] then
		self:TriggerEvent("BigWigs_SendSync", "BWCACS")
	elseif sName == BS["Challenging Roar"] then
		self:TriggerEvent("BigWigs_SendSync", "BWCACR")
	end

	-- Debug / Backup Check
	-- DEFAULT_CHAT_FRAME:AddMessage("BWCA Debug: Cast " .. tostring(sName) .. " ID: " .. tostring(sId))

	local id = tonumber(sId)
	local playerClass = UnitClass("player")
	
	if playerClass == BC["Druid"] then
		if id == 51452 or (sName and string.find(sName, "树皮术")) or sName == "Barkskin" then -- Barkskin
			self:TriggerEvent("BigWigs_SendSync", "BWCABS " .. PROTOCOL_VERSION)
		elseif id == 45708 or (sName and string.find(sName, "狂暴") and not string.find(sName, "回复") and not string.find(sName, "血性")) or sName == "Berserk" then -- Berserk
			self:TriggerEvent("BigWigs_SendSync", "BWCAFR " .. PROTOCOL_VERSION)
		end
	elseif playerClass == BC["Shaman"] then
		if id == 51363 or id == 202 or (sName and string.find(sName, "灵魂连接")) or sName == "Spirit Link" then -- Spirit Link
			local targetName = nil
			if spellTarget then
				targetName = spellTarget
				spellCasting = nil
				spellTarget = nil
			else
				if UnitExists("target") and UnitIsPlayer("target") then
					targetName = UnitName("target")
				else
					targetName = UnitName("player")
				end
			end
			self:TriggerEvent("BigWigs_SendSync", "BWCASL " .. PROTOCOL_VERSION .. " " .. targetName)
		end
	end
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_SELF_BUFF(msg)
	self:CheckEnslaveCast(msg, "SELF_BUFF") -- 奴役恶魔兜底: 部分客户端把"你对X施放了Y"投递到本通道
	self:CheckEnslaveAura(msg, true, "SELF_BUFF")

	if string.find(msg, "艾露恩之镰") or string.find(msg, "The Scythe of Elune") or string.find(msg, "艾露恩的守护") or string.find(msg, "Protection of Elune") then
		local player = UnitName("player")
		SendAddonMessage("BigWigs", "BWCA_Scythe " .. player, "PARTY")
		self:CHAT_MSG_ADDON("BigWigs", "BWCA_Scythe " .. player, "PARTY", player) -- Local Loopback
	end

	local _, playerClass = UnitClass("player")
	if string.find(msg, L["trigger_barkskin"]) and playerClass == "DRUID" then
		self:TriggerEvent("BigWigs_SendSync", "BWCABS " .. PROTOCOL_VERSION)
	elseif string.find(msg, L["trigger_berserk"]) and playerClass == "DRUID" then
		self:TriggerEvent("BigWigs_SendSync", "BWCAFR " .. PROTOCOL_VERSION)
	elseif string.find(msg, L["trigger_spiritlink"]) and playerClass == "SHAMAN" then
	elseif string.find(msg, L["trigger_spiritlink"]) then
		local _, _, target = string.find(msg, L["trigger_spiritlink"])
		if target then
			self:TriggerEvent("BigWigs_SendSync", "BWCASL " .. PROTOCOL_VERSION .. " " .. target)
		end
	elseif string.find(msg, L["trigger_spiritlink_self"]) then
		local target = UnitName("player")
		self:TriggerEvent("BigWigs_SendSync", "BWCASL " .. PROTOCOL_VERSION .. " " .. target)
	elseif playerClass == "PRIEST" then
		if string.find(msg, L["trigger_fearward"]) then
			local _, _, target = string.find(msg, L["trigger_fearward"])
			if target then
				self:TriggerEvent("BigWigs_SendSync", "BWCAFW " .. target)
			end
		elseif string.find(msg, L["trigger_fearward_self"]) then
			self:TriggerEvent("BigWigs_SendSync", "BWCAFW " .. UnitName("player"))
		end
	end
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "SELF") -- 奴役恶魔兜底
	if string.find(msg, BS["Gift of Life"]) and (UnitClass("Player") == BC["Warrior"] or UnitClass("Player") == BC["Druid"] or UnitClass("Player") == BC["Paladin"] ) then
		self:TriggerEvent("BigWigs_SendSync", "BWCALG")
	elseif string.find(msg, L["di_trigger"]) then
		self:TriggerEvent("BigWigs_SendSync", "BWCADI")
	elseif string.find(msg, L["invis_trigger"]) and self.db.profile.invis then
		self:Bar(L["invis_trigger"], 18, "Spell_Magic_LesserInvisibilty", true)
	elseif string.find(msg, L["lesser_invis_trigger"]) and self.db.profile.invis then
		self:Bar(L["lesser_invis_trigger"], 15, "Spell_Magic_LesserInvisibilty", true)
	elseif string.find(msg, L["cloaking_invis_trigger"]) and self.db.profile.invis then
		self:Bar(L["cloaking_invis_trigger"], 10, "Spell_Magic_LesserInvisibilty", true)
	elseif string.find(msg, L["deepwoodpipe_trigger"]) and self.db.profile.deepwood then
		self:Bar(L["deepwoodpipe_trigger"], 30, "ability_stealth", true)
	elseif string.find(msg, L["lip_trigger"]) and self.db.profile.lip then
		self:Bar(L["lip_trigger"], 6, "inv_potion_62", true)
	elseif string.find(msg, L["bop_trigger"]) and self.db.profile.bop then
		self:Bar(L["Blessing of Protection"], 10, "Spell_Holy_SealOfProtection", true)
	elseif string.find(msg, L["powerinfusion_trigger"]) and self.db.profile.powerinfusion then
		self:Bar(L["powerinfusion_trigger"], 15, "Spell_Holy_PowerInfusion", true)
	end
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	if string.find(msg, L["di_fades"]) then
		self:RemoveBar(L["di_trigger"])
	elseif string.find(msg, L["invis_fades"]) then
		self:RemoveBar(L["invis_trigger"])
	elseif string.find(msg, L["lesser_invis_fades"]) then
		self:RemoveBar(L["lesser_invis_trigger"])
	elseif string.find(msg, L["cloaking_invis_fades"]) then
		self:RemoveBar(L["cloaking_invis_trigger"])
	elseif string.find(msg, L["deepwoodpipe_fades"]) then
		self:RemoveBar(L["deepwoodpipe_trigger"])
	elseif string.find(msg, L["lip_fades"]) then
		self:RemoveBar(L["lip_trigger"])
	elseif string.find(msg, L["bop_fades"]) then
		self:RemoveBar(L["Blessing of Protection"])
	elseif string.find(msg, L["powerinfusion_fades"]) then
		self:RemoveBar(L["powerinfusion_trigger"])
	end
end

------------------------------
--      Enslave Demon       --
------------------------------

-- 召唤大恶魔奴役闸门(确定性): 不依赖事件先后顺序,扫描/日志触发时直接看当前宠物身份分流。
-- 返回: true=放行(无宠物/普通恶魔/真奴役大恶魔落地); false=宠物是召唤大恶魔且非真奴役→抑制奴役条;
--       nil=宠物名未解析(未知目标)→等待解析(实测1~2秒)后再分流。
-- 真奴役大恶魔判定: 5秒内施放过奴役恶魔,且施法起仅发生过一次换宠(=这次换宠就是奴役落地)。
-- 施法起换宠计数: SPELLCAST_START 打 enslaveCastPetSeq 快照, UNIT_PET 递增 enslavePetSeq。
-- (旧版 enslaveSummonAt/enslaveSummonHold 时间戳式抑制有事件顺序竞态: 施法 freshCast 窗口
--  旁路抑制后,召唤大恶魔的 1 秒延迟扫描会把大恶魔自带的同款奴役纹理减益误判为重新奴役)
function BigWigsCommonAuras:CheckEnslavePetGate()
	if not UnitExists("pet") then return true end
	local nm, fam = UnitName("pet"), UnitCreatureFamily("pet")
	if not nm or nm == "" or nm == "未知目标" or nm == "Unknown Entity" then return nil end
	local isSummon = (fam == "地狱火") or (nm == "地狱火") or (nm == "Infernal")
		or (fam == "恶魔卫士") or (nm == "恶魔卫士") or (nm == "Felguard")
		or (fam == "末日守卫") or (nm == "末日守卫") or (nm == "Doomguard")
	if not isSummon then return true end
	local fresh = self.enslaveCastAt and (GetTime() - self.enslaveCastAt) < 5
	if fresh and self.enslavePetSeq and self.enslaveCastPetSeq
		and self.enslavePetSeq == self.enslaveCastPetSeq + 1 then
		return true -- 奴役落地: 施法后仅一次换宠(=这次换宠就是奴役把大恶魔拉过来)
	end
	if fresh and self.enslavePetSeq and self.enslaveCastPetSeq
		and self.enslavePetSeq == self.enslaveCastPetSeq
		and self.enslaveActive and self.enslavePetName == nm then
		return true -- 对已奴役的同一只大恶魔重复施放刷新: 施法后无换宠且奴役条已在跑
	end
	return false
end

-- 奴役恶魔: 施放成功日志捕获（兼容自身增益/自身伤害多个通道），仅术士生效
function BigWigsCommonAuras:CheckEnslaveCast(msg, channel)
	local _, playerClass = UnitClass("player")
	if playerClass ~= "WARLOCK" then return end
	if not self.db.profile.enslave then return end
	if not msg then return end
	if not string.find(msg, L["trigger_enslave"]) then return end
	-- 召唤大恶魔闸门(确定性): 施法日志本身就是真施放的证据,仅当宠物是已解析的召唤大恶魔且非真奴役落地时不出条
	if self:CheckEnslavePetGate() == false then return end
	local _, _, demon = string.find(msg, L["enslave_regexp"])
	if not demon or demon == "" then demon = UnitName("pet") end
	if not demon then return end
	-- 去重: 同一次施放可能同时命中"施放成功"与"宠物获得增益"两条日志
	if not self.enslaveThrottle then self.enslaveThrottle = {} end
	if self.enslaveThrottle[demon] and GetTime() < self.enslaveThrottle[demon] then return end
	self.enslaveThrottle[demon] = GetTime() + 15
	self.enslaveActive = true -- 日志路径同样置位,保证 UNIT_PET 停条分支覆盖所有开条来源
	self:ShowEnslaveLocal(demon)
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_SELF_DAMAGE(msg)
	self:CheckEnslaveCast(msg, "SELF_DAMAGE")
end

-- 奴役恶魔: 增益生效日志捕获（实测日志:「未知目标 (最爱吸血)受到了奴役恶魔效果的影响（1）。」）
-- 多通道兜底: 宠物/自身/小队/友方/敌对玩家/敌对小队/怪物 周期增益均走这里
function BigWigsCommonAuras:CheckEnslaveAura(msg, force, channel)
	local _, playerClass = UnitClass("player")
	if playerClass ~= "WARLOCK" then return end
	if not self.db.profile.enslave then return end
	if not msg then return end
	if not string.find(msg, L["trigger_enslave_pet"]) then return end
	-- 宠物通道消息必属自己; 其余通道没宠物说明不是自己的奴役，由真正施法的术士去广播
	if not force and not UnitExists("pet") then return end
	local captured = nil
	local _, _, cap = string.find(msg, L["enslave_aura_regexp"])
	if cap then
		local _, _, inner = string.find(cap, "%(([^%(%)]+)%)") -- 兼容「未知目标 (名字)」类显示
		if inner and inner ~= "" then cap = inner end
		cap = string.gsub(cap, "未知目标", "")
		cap = string.gsub(cap, "^%s+", "")
		cap = string.gsub(cap, "%s+$", "")
		if cap ~= "" then captured = cap end
	end
	-- 被奴役恶魔就是自己的宠物，宠物名最可靠; 日志捕获可能混入主人名，仅作回退
	local demon = UnitName("pet") or captured
	if not demon or demon == "" or demon == "?" then return end
	-- 召唤大恶魔闸门(确定性): 宠物是已解析的召唤大恶魔且非真奴役落地→不出条; 未解析→等待扫描(2秒内)分流
	if self:CheckEnslavePetGate() ~= true then return end
	-- 去重: 同一次施放可能同时命中多条日志通道
	if not self.enslaveThrottle then self.enslaveThrottle = {} end
	if self.enslaveThrottle[demon] and GetTime() < self.enslaveThrottle[demon] then return end
	self.enslaveThrottle[demon] = GetTime() + 15
	self.enslaveActive = true -- 日志路径同样置位,保证 UNIT_PET 停条分支覆盖所有开条来源
	self:ShowEnslaveLocal(demon)
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_PET_BUFFS(msg)
	self:CheckEnslaveAura(msg, true, "PET")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "FRIENDLYPLAYER")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "CREATURE")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "HOSTILEPLAYER")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_HOSTILEPARTY_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "PERIODIC_HOSTILEPARTY")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_CREATURE_BUFF(msg)
	self:CheckEnslaveAura(msg, nil, "CREATURE_BUFF")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PET_BUFF(msg)
	self:CheckEnslaveAura(msg, nil, "PET_BUFF")
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF(msg)
	self:CheckEnslaveAura(msg, nil, "HOSTILEPLAYER_BUFF")
end

-- 奴役恶魔终极兜底: 直接扫描宠物减益图标纹理（Spell_Shadow_EnslaveDemon），完全不依赖战斗日志
-- 注意: 奴役恶魔对恶魔是"减益"(诅咒)，必须用 UnitDebuff 而非 UnitBuff
function BigWigsCommonAuras:ScanPetEnslave()
	if not self.db.profile.enslave then return end
	local _, playerClass = UnitClass("player")
	if playerClass ~= "WARLOCK" then return end
	local found = nil
	if UnitExists("pet") then
		local i = 1
		while UnitDebuff("pet", i) do
			local tex = UnitDebuff("pet", i)
			if tex and string.find(string.lower(tex), "enslavedemon") then
				found = true
				break
			end
			i = i + 1
		end
	end
	if not found then
		self.enslaveMiss = (self.enslaveMiss or 0) + 1
		if self.enslaveActive then
			-- 解除判定(保守): 宠物不在(解散/死亡)→立即解除;
			-- 宠物在但名字未解析(未知目标=单位数据瞬态)→一律忽略,绝不判解除;
			-- 名字已解析且连续3次(~6秒)扫不到减益→才认定解除(驱散/到期)
			local petMissing = not UnitExists("pet")
			local petName = UnitName("pet")
			local resolved = petMissing or (petName and petName ~= "" and petName ~= "未知目标" and petName ~= "Unknown Entity")
			if resolved and self.enslaveMiss >= 3 then
				self.enslaveActive = nil
				self.enslaveMiss = nil
				self.enslaveThrottle = nil -- 清去重,之后重新奴役能立刻广播恢复
				self:HideEnslaveLocal()
			end
		end
		return
	end
	self.enslaveMiss = nil
	local demon = UnitName("pet") or "?"
	-- 确定性闸门: 宠物是召唤大恶魔(地狱火/恶魔卫士/末日守卫)→奴役条一律不出(真奴役落地除外);
	-- 宠物名未解析(未知目标)→等解析后再分流,不抢在名字出来前出条
	local gate = self:CheckEnslavePetGate()
	if gate == false then
		-- 防御: 召唤大恶魔顶掉旧奴役恶魔时收掉可能残留的奴役条
		if self.enslaveActive then
			self.enslaveActive = nil
			self.enslaveMiss = nil
			self.enslaveThrottle = nil
			self:HideEnslaveLocal()
		end
		return
	end
	if gate == nil then return end
	-- 施法窗口内(15秒,覆盖施法时间+旧宠释放/新宠建立的换宠延迟)视为刚重新奴役，强制重置计时条
	local freshCast = self.enslaveCastAt and (GetTime() - self.enslaveCastAt) < 15
	-- 读条进行中(START后5秒内，时限兜底防 STOP 事件缺失)不广播:
	-- 读条期间旧恶魔仍在宠物位且带减益，此时广播会以旧恶魔名重置条（换奴另一只时的错误中间广播）
	if freshCast and self.enslaveCasting and (GetTime() - self.enslaveCasting) < 5 then return end
	-- 目标恶魔更换(重新奴役另一只): 解除"同一次施法只广播一次"限制，确保新恶魔落地后必广播
	if demon ~= self.enslavePetName then
		self.enslaveCastDone = nil
	end
	if self.enslaveActive and not freshCast then return end -- 同一恶魔持续奴役中，不重复广播
	-- 同一次施法只广播一次(中途轮询扫到旧宠会广播一次，落地后扫到新宠因换宠重置标记必再广播)
	if freshCast and self.enslaveCastDone then return end
	self.enslaveActive = true
	self.enslaveThrottle = nil -- 扫描路径不做15秒去重: active位已防重复广播,保证任何状态误判后2秒内自愈
	if freshCast then
		self.enslaveCastDone = true
	end
	self.enslavePetName = demon
	self:ShowEnslaveLocal(demon)
end

-- 重新奴役检测: 施放奴役恶魔时打时间戳（是否成功由扫描确认）
function BigWigsCommonAuras:SPELLCAST_START(arg1)
	local _, playerClass = UnitClass("player")
	if playerClass ~= "WARLOCK" then return end
	if arg1 and string.find(arg1, "奴役恶魔") then
		self.enslaveCastAt = GetTime()
		self.enslaveCasting = GetTime() -- 读条中标记（落地/失败/打断时清除）
		self.enslaveCastDone = nil -- 新的一次施法，允许 fresh 广播
		self.enslaveCastPetSeq = self.enslavePetSeq or 0 -- 施法起换宠计数快照(真奴役大恶魔判定用)
	end
end

-- 施法结束(成功/失败/打断都会触发，无参数): 清除读条中标记
function BigWigsCommonAuras:EnslaveCastEnded()
	self.enslaveCasting = nil
end

-- 宠物增益变化时扫描（捕获奴役生效/重复奴役/解除）
function BigWigsCommonAuras:UNIT_AURA(arg1)
	if arg1 ~= "pet" then return end
	self:ScanPetEnslave()
end

function BigWigsCommonAuras:SpellStatus_SpellCastCastingFinish(sId, sName, sRank, sFullName, sCastTime)
	if not string.find(sName, L["Portal"]) then
		return
	end
	local name = BS:HasReverseTranslation(sName) and BS:GetReverseTranslation(sName) or sName
	self:ScheduleEvent("bwcaspellcast", self.SpellCast, 0.3, self, name)
end

function BigWigsCommonAuras:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	-- do nothing if we are casting a spell but the error doesn't consern that spell, thanks Iceroth.
	if (spellStatus:IsCastingOrChanneling() and not spellStatus:IsActiveSpell(sId, sName)) then
		return
	end
	if self:IsEventScheduled("bwcaspellcast") then
		self:CancelScheduledEvent("bwcaspellcast")
	end
end

function BigWigsCommonAuras:SpellCast(sName)
	self:TriggerEvent("BigWigs_SendSync", "BWCAP " .. sName)
end

function BigWigsCommonAuras:CHAT_MSG_MONSTER_EMOTE(msg, sender)
	if string.find(msg, L["trigger_wormhole"]) then

		--Debug
		if UnitName("Player") == "Relar" or UnitName("Player") == "Dreadsome" then
			DEFAULT_CHAT_FRAME:AddMessage("发送者： " .. sender)
		end

		whZone = nil
		if GetNumRaidMembers() > 0 then
			for i = 1, GetNumRaidMembers() do
				if UnitName("raid" .. i) == sender then
					if UnitFactionGroup("raid" .. i) == L["Alliance"] then
						whZone = "Stormwind"
					elseif UnitFactionGroup("raid" .. i) == L["Horde"] then
						whZone = "Orgrimmar"
					else
						whZone = sender
					end
				end
			end
		elseif GetNumPartyMembers() > 0 then
			for i = 1, GetNumPartyMembers() do
				if UnitName("party" .. i) == sender then
					if UnitFactionGroup("party" .. i) == L["Alliance"] then
						whZone = "Stormwind"
					elseif UnitFactionGroup("party" .. i) == L["Horde"] then
						whZone = "Orgrimmar"
					else
						whZone = sender
					end
				end
			end
		else
			whZone = sender
		end

		if whZone ~= nil then
			self:TriggerEvent("BigWigs_SendSync", "BWCAWH " .. whZone)
		end


	elseif string.find(msg, L["trigger_orange"]) then
		self:TriggerEvent("BigWigs_SendSync", "BWCAOR")

	elseif string.find(msg, L["trigger_soulwell"]) then
		self:TriggerEvent("BigWigs_SendSync", "BWCAWL")
	end
end

function BigWigsCommonAuras:CHAT_MSG_SYSTEM(msg)
	if string.find(msg, L["trigger_restartMinSec"]) or string.find(msg, L["trigger_shutdownMinSec"]) then
		local _, _, minutes, seconds = string.find(msg, L["inminutesseconds"])
		timeToShutdown = tonumber(minutes) * 60 + tonumber(seconds)

		if self.db.profile.shutdown then
			if timeToShutdown > 9 then
				self:TriggerEvent("BigWigs_StopBar", self, L["bar_shutDown"])
				self:TriggerEvent("BigWigs_StartBar", self, L["bar_shutDown"], timeToShutdown, icon.shutdown, true, color.shutdown)
			end

			if not shutdownBigWarning then
				if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "Beware") end
				self:TriggerEvent("BigWigs_ShowWarningSign", icon.shutdown, 2)
				shutdownBigWarning = true
			end
		end


	elseif string.find(msg, L["trigger_restart"]) or string.find(msg, L["trigger_shutdown"]) then
		local _, _, digits, minSec = string.find(msg, L["in_plus"])
		if string.find(minSec, L["inute"]) then
			timeToShutdown = tonumber(digits) * 60
		else
			timeToShutdown = tonumber(digits)
		end

		if self.db.profile.shutdown then
			if timeToShutdown > 9 then
				self:TriggerEvent("BigWigs_StopBar", self, L["bar_shutDown"])
				self:TriggerEvent("BigWigs_StartBar", self, L["bar_shutDown"], timeToShutdown, icon.shutdown, true, color.shutdown)
			end

			if not shutdownBigWarning then
				if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "Beware") end
				self:TriggerEvent("BigWigs_ShowWarningSign", icon.shutdown, 2)
				shutdownBigWarning = true
			end
		end
	end
end

--Debug
--function BigWigsCommonAuras:CHAT_MSG_SAY(msg)
--end



function BigWigsCommonAuras:BigWigs_RecvSync(sync, rest, nick)
	if not nick then
		nick = UnitName("player")
	end

	if self.db.profile.fearward and sync == "BWCAFW" and rest then
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_fearward"] .. rest, "Positive", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_fearward"], timer.fearward, icon.fearward, true, color.fearward)


	elseif self.db.profile.shieldwall and sync == "BWCASW" then
		local swTime = tonumber(rest)
		if not swTime then
			swTime = 10
		end -- If the tank uses an old BWCA, just assume 10 seconds.
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_shieldwall"], "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_shieldwall"], swTime, icon.shieldwall, true, color.shieldwall)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_shieldwall"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)


	elseif self.db.profile.laststand and sync == "BWCALS" then
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_laststand"], "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_laststand"], timer.laststand, icon.laststand, true, color.laststand)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_laststand"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)


	elseif self.db.profile.lifegivinggem and sync == "BWCALG" then
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_lifegivingGem"], "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_lifegivingGem"], timer.lifegivingGem, icon.lifegivingGem, true, color.lifegivingGem)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_lifegivingGem"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)


	elseif self.db.profile.challengingshout and sync == "BWCACS" then
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_challengingShout"], "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_challengingShout"], timer.challenging, icon.challengingShout, true, color.challengingShout)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_challengingShout"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)


	elseif self.db.profile.challengingroar and sync == "BWCACR" then
		self:TriggerEvent("BigWigs_Message", nick .. L["msg_challengingRoar"], "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_challengingRoar"], timer.challenging, icon.challengingRoar, true, color.challengingRoar)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_challengingRoar"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)

	elseif self.db.profile.di and sync == "BWCADI" then
		self:TriggerEvent("BigWigs_Message", L["msg_divineIntervention"] .. nick, "Urgent", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_divineIntervention"], timer.di, icon.di, true, color.di)
		self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_divineIntervention"], function(name, button, extra)
			TargetByName(extra, true)
		end, nick)

	elseif self.db.profile.portal and sync == "BWCAP" and rest then
		rest = BS:HasTranslation(rest) and BS:GetTranslation(rest) or rest
		local _, _, zone = string.find(rest, L["portal_regexp"])
		if zone then
			if zone == "Orgrimmar" or zone == "Thunder Bluff" or zone == "Undercity" or zone == "Stonard" then
				portalColor = "Red"
				portalText = "--部落-- 传送门到 "
			elseif zone == "Stormwind" or zone == "Ironforge" or zone == "Darnassus" or zone == "Theramore" then
				portalColor = "Blue"
				portalText = "--联盟-- 传送门到 "
			elseif zone == "Karazhan" or zone then
				portalColor = "Green"
				portalText = "--中立-- 传送门到 "
			end
			self:TriggerEvent("BigWigs_Message", portalText .. zone, "Attention", false, nil, false)
			if zone == "Stonard" then
				self:TriggerEvent("BigWigs_StartBar", self, rest, timer.portal, L["iconPrefix"] .. "Spell_Arcane_PortalStonard", true, portalColor)
			elseif zone == "Theramore" then
				self:TriggerEvent("BigWigs_StartBar", self, rest, timer.portal, L["iconPrefix"] .. "Spell_Arcane_PortalTheramore", true, portalColor)
			elseif zone == "Karazhan" then
				self:TriggerEvent("BigWigs_StartBar", self, rest, timer.portal, L["iconPrefix"] .. "Spell_Arcane_PortalUndercity", true, portalColor)
			else
				self:TriggerEvent("BigWigs_StartBar", self, rest, timer.portal, BS:GetSpellIcon(rest), true, portalColor)
			end
		end


	elseif self.db.profile.wormhole and sync == "BWCAWH" and rest then
		if rest == "Orgrimmar" then
			whColor = "Red"
			whText = "--部落-- 虫洞到奥格瑞玛"
		elseif rest == "Stormwind" then
			whColor = "Blue"
			whText = "--联盟-- 虫洞到暴风城"
		end
		self:TriggerEvent("BigWigs_Message", whText, "Attention", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, rest .. L["bar_wormhole"], timer.wormhole, icon.wormhole, true, whColor)
		if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "BikeHorn") end
		self:TriggerEvent("BigWigs_ShowWarningSign", icon.wormhole, 2)


	elseif self.db.profile.orange and sync == "BWCAOR" then
		self:TriggerEvent("BigWigs_Message", L["msg_orange"], "Positive", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, L["bar_orange"], timer.orange, icon.orange, true, color.orange)
		if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "BikeHorn") end
		self:TriggerEvent("BigWigs_ShowWarningSign", icon.orange, 5)


	elseif self.db.profile.soulwell and sync == "BWCAWL" then
		self:TriggerEvent("BigWigs_Message", L["msg_soulwell"], "Positive", false, nil, false)
		self:TriggerEvent("BigWigs_StartBar", self, L["bar_soulwell"], timer.soulwell, icon.soulwell, true, color.soulwell)
		if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "BikeHorn") end
		self:TriggerEvent("BigWigs_ShowWarningSign", icon.soulwell, 5)

	elseif self.db.profile.barkskin and sync == "BWCABS" then
		if self:VerifyVersion(rest) then
			self:TriggerEvent("BigWigs_Message", nick .. L["msg_barkskin"], "Urgent", false, nil, false)
			self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_barkskin"], timer.barkskin, icon.barkskin, true, color.barkskin)
			self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_barkskin"], function(name, button, extra)
				TargetByName(extra, true)
			end, nick)
		end

	elseif self.db.profile.berserk and sync == "BWCAFR" then
		if self:VerifyVersion(rest) then
			self:TriggerEvent("BigWigs_Message", nick .. L["msg_berserk"], "Urgent", false, nil, false)
			self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_berserk"], timer.berserk, icon.berserk, true, color.berserk)
			self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_berserk"], function(name, button, extra)
				TargetByName(extra, true)
			end, nick)
		end

	elseif self.db.profile.spiritlink and sync == "BWCASL" and rest then
		local ver, target = string.match(rest, "^(%S+)%s+(.*)$")
		if self:VerifyVersion(ver) and target then
			self:TriggerEvent("BigWigs_Message", nick .. L["msg_spiritlink"] .. target, "Urgent", false, nil, false)
			self:TriggerEvent("BigWigs_StartBar", self, target .. L["bar_spiritlink"], timer.spiritlink, icon.spiritlink, true, color.spiritlink)
			self:SetCandyBarOnClick("BigWigsBar " .. nick .. L["bar_spiritlink"], function(name, button, extra)
				TargetByName(extra, true)
			end, nick)
		end

	end
end

-- 奴役恶魔: 仅本机显示（不做全团同步），参考大恶魔叛变的本地开条方式
function BigWigsCommonAuras:ShowEnslaveLocal(demon)
	local nick = UnitName("player")
	self:TriggerEvent("BigWigs_Message", nick .. L["msg_enslave"] .. demon, "Attention", false, nil, false)
	self:TriggerEvent("BigWigs_StartBar", self, nick .. L["bar_enslave"], timer.enslave, icon.enslave, true, color.enslave)
	-- 到期前 10 秒预警 + 到期警报（重复奴役时同 id 事件自动覆盖）
	self:ScheduleEvent("BWCA_EnslaveExp_local", self.EnslaveExpiring, timer.enslave - 10, self, nick, demon)
	self:ScheduleEvent("BWCA_EnslaveGone_local", self.EnslaveGone, timer.enslave, self, nick)
end

-- 奴役解除(解散/死亡/驱散): 停条并取消到期提醒
function BigWigsCommonAuras:HideEnslaveLocal()
	local nick = UnitName("player")
	self:TriggerEvent("BigWigs_StopBar", self, nick .. L["bar_enslave"])
	if self:IsEventScheduled("BWCA_EnslaveExp_local") then
		self:CancelScheduledEvent("BWCA_EnslaveExp_local")
	end
	if self:IsEventScheduled("BWCA_EnslaveGone_local") then
		self:CancelScheduledEvent("BWCA_EnslaveGone_local")
	end
end

-- 奴役恶魔到期前 10 秒预警
function BigWigsCommonAuras:EnslaveExpiring(nick, demon)
	if not self.db.profile.enslave then return end
	self:TriggerEvent("BigWigs_Message", nick .. L["msg_enslave_expiring"] .. "(" .. (demon or "?") .. ")", "Urgent", false, nil, false)
	if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "Long") end
end

-- 奴役恶魔到期警报（5分钟到，恶魔可能失控）
function BigWigsCommonAuras:EnslaveGone(nick)
	if not self.db.profile.enslave then return end
	self:TriggerEvent("BigWigs_Message", nick .. L["msg_enslave_gone"], "Urgent", false, nil, false)
	self:TriggerEvent("BigWigs_ShowWarningSign", icon.enslave, 3)
	if self.db.profile.casounds then self:TriggerEvent("BigWigs_Sound", "Beware") end
end

function BigWigsCommonAuras:VerifyVersion(ver)
	if not ver then return false end
	local major, minor, patch = string.match(ver, "^(%d+)%.(%d+)%.(%d+)$")
	if not major then return false end

	-- Protocol baseline: 2.16.1
	-- Accept any version >= 2.16.1
	if tonumber(major) > 2 then return true end
	if tonumber(major) == 2 then
		if tonumber(minor) > 16 then return true end
		if tonumber(minor) == 16 then
			if tonumber(patch) >= 1 then return true end
		end
	end
	return false
end

function BigWigsCommonAuras:CheckWarlockPet()
	if not self.db.profile.warlockpet then return end
	if not UnitExists("pet") then return end
	local name = UnitName("pet")
	local family = UnitCreatureFamily("pet")

	-- 名字未解析(未知目标): 无法辨认是否召唤大恶魔，1秒后重查(最多5次,同id覆盖)，解析后照常开叛变条
	if not name or name == "" or name == "未知目标" or name == "Unknown Entity" then
		self.enslaveWlRetries = (self.enslaveWlRetries or 0) + 1
		if self.enslaveWlRetries <= 5 then
			self:ScheduleEvent("BigWigsCommonAuras_CheckWarlockPet", self.CheckWarlockPet, 1.0, self)
		end
		return
	end
	self.enslaveWlRetries = nil
	
	-- Fallback to name checking if family is nil (common on some private servers for custom pets)
	-- Also check English names just in case
	
	if (family == "地狱火") or (name == "地狱火") or (name == "Infernal") then
		self:TriggerEvent("BigWigs_StartBar", self, "地狱火叛变", 180, "Interface\\Icons\\Spell_Shadow_SummonInfernal")
	elseif (family == "恶魔卫士") or (name == "恶魔卫士") or (name == "Felguard") then
		self:TriggerEvent("BigWigs_StartBar", self, "恶魔卫士叛变", 180, "Interface\\Icons\\Spell_Shadow_SummonFelGuard")
	elseif (family == "末日守卫") or (name == "末日守卫") or (name == "Doomguard") then
		self:TriggerEvent("BigWigs_StartBar", self, "末日守卫叛变", 180, "Interface\\Icons\\Spell_Shadow_AntiMagicShell")
	end
	-- 召唤抑制时间戳已废除: 奴役条改由 CheckEnslavePetGate 按宠物身份确定性判定
end

function BigWigsCommonAuras:UNIT_PET(arg1)
	if arg1 ~= "player" then return end
	-- 换宠计数递增: 配合 SPELLCAST_START 的 enslaveCastPetSeq 快照,判定"施法后仅一次换宠"=真奴役大恶魔落地
	self.enslavePetSeq = (self.enslavePetSeq or 0) + 1
	self.enslaveWlRetries = nil
	-- 换宠(重新奴役另一只): 重置广播标记——新旧恶魔可能都显示"未知目标"，名字比对不可靠，
	-- UNIT_PET 是宠物切换的确定信号，重置后落地扫描必广播
	self.enslaveCastDone = nil
	-- 宠物切换: 旧奴役恶魔已不在宠物位，立即结束本机奴役显示（条/到期提醒）。
	-- 召唤大恶魔顶掉旧奴役恶魔时旧条必须消失（大恶魔自带同款奴役纹理，扫得到减益，
	-- 靠 miss 判解除永远触发不了）；若新宠物是刚奴役的普通恶魔，落地扫描会立刻重新开条
	if self.enslaveActive then
		self.enslaveActive = nil
		self.enslaveMiss = nil
		self:HideEnslaveLocal()
	end
	-- 大恶魔叛变条: 宠物位一变(解散/死亡消失/被顶掉/换宠)立即收掉旧条——
	-- 叛变条只随宠物存在，解散大恶魔后条必须消失; 若新宠物仍是召唤大恶魔，
	-- CheckWarlockPet 0.5 秒后按新身份重新开条（换宠场景新条重开 180 秒，合理）
	self:TriggerEvent("BigWigs_StopBar", self, "地狱火叛变")
	self:TriggerEvent("BigWigs_StopBar", self, "恶魔卫士叛变")
	self:TriggerEvent("BigWigs_StopBar", self, "末日守卫叛变")
	self:ScheduleEvent("BigWigsCommonAuras_CheckWarlockPet", self.CheckWarlockPet, 0.5, self)
	-- 奴役恶魔: 宠物出现后延迟扫描（等 buff 挂上），1 秒与 3 秒各一次
	self:ScheduleEvent("BigWigsCommonAuras_ScanPetEnslave1", self.ScanPetEnslave, 1.0, self)
	self:ScheduleEvent("BigWigsCommonAuras_ScanPetEnslave2", self.ScanPetEnslave, 3.0, self)
end

------------------------------
--      Scythe of Elune     --
------------------------------

function BigWigsCommonAuras:CHAT_MSG_SPELL_PARTY_BUFF(msg)
	self:CheckEnslaveAura(msg, nil, "PARTY_BUFF") -- 奴役恶魔兜底
	local _, _, player, spell = string.find(msg, "^(.+) casts (.+).$") 
    -- 英文: X casts Y.
    -- 中文: X施放了Y。
    if not player then
        _, _, player, spell = string.find(msg, "^(.+)施放了(.+)。$")
    end
    
	if spell and (string.find(spell, "艾露恩之镰") or string.find(spell, "The Scythe of Elune") or string.find(spell, "艾露恩的守护") or string.find(spell, "Protection of Elune")) then
		-- Only trigger locally, do NOT sync (Caster will sync)
		self:CHAT_MSG_ADDON("BigWigs", "BWCA_Scythe " .. player, "PARTY", player)
	end
end

function BigWigsCommonAuras:CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS(msg)
	self:CheckEnslaveAura(msg, nil, "PARTY") -- 奴役恶魔兜底
    local _, _, player, spell = string.find(msg, "^(.+) gains (.+).$")
    if not player then
         _, _, player, spell = string.find(msg, "^(.+)获得了(.+)。$")
    end
    
    if spell and (string.find(spell, "艾露恩之镰") or string.find(spell, "The Scythe of Elune") or string.find(spell, "艾露恩的守护") or string.find(spell, "Protection of Elune")) then
		-- Only trigger locally, do NOT sync
		self:CHAT_MSG_ADDON("BigWigs", "BWCA_Scythe " .. player, "PARTY", player)
	end
end

function BigWigsCommonAuras:CHAT_MSG_ADDON(prefix, message, type, sender)
	if prefix ~= "BigWigs" or type ~= "PARTY" then return end
	
    local _, _, sync, rest = string.find(message, "(%S+)%s*(.*)$")
	if not sync then return end

	if sync == "BWCA_Scythe" and rest then
        -- 触发计时条: rest 是玩家名字
        local player = rest
        
        -- Simple throttling to prevent double bars from Local + Sync both firing
        if not self.scytheThrottle then self.scytheThrottle = {} end
        if self.scytheThrottle[player] and GetTime() < self.scytheThrottle[player] then return end
        self.scytheThrottle[player] = GetTime() + 2
        
        local icon = "Interface\\Icons\\INV_Staff_05" -- Default fallback
        local _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(55505)
        if itemIcon then icon = itemIcon end
        
        local barName = player .. L["bar_scythe"]
        local registered, time, elapsed, running = BigWigsBars:GetBarStatus(self, barName)
        if registered and running and (time - elapsed) > 10 then return end

        self:TriggerEvent("BigWigs_StartBar", self, barName, 60, icon, true, "Cyan")
        self:TriggerEvent("BigWigs_Message", player .. L["msg_scythe"], "Positive")
	end
end

