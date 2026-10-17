--[[
	Name: Babble-ItemSet-2.2
	Revision: $Rev: 1000 $
	Author(s): Lichery
	Description: A library to provide localizations for factions.
	Dependencies: AceLibrary, AceLocale-2.2
]]
-- Проверить ЗГ, АК20, АК40, Т3, разобраться с сетами AB

-- Wind汉化修复Turtle-WOW中文数据
-- https://github.com/NineTears/Libs-Turtle-zhCN
-- Last update: 2024-02-29

local MAJOR_VERSION = "Babble-ItemSet-2.2"
local MINOR_VERSION = tonumber(string.sub("$Revision: 1000 $", 12, -3))

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end

if not AceLibrary:HasInstance("AceLocale-2.2") then error(MAJOR_VERSION .. " requires AceLocale-2.2") end

local _, x = AceLibrary("AceLocale-2.2"):GetLibraryVersion()
MINOR_VERSION = MINOR_VERSION * 100000 + x

if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local BabbleItemSet = AceLibrary("AceLocale-2.2"):new(MAJOR_VERSION)

-- uncomment below for debug information
-- BabbleItemSet:EnableDebugging()

BabbleItemSet:RegisterTranslations("enUS", function()
	return {
	-- Blacksmithing Crafted Sets
		["Bloodsoul Embrace"] = true,
		["Imperial Plate"] = true,
		["The Darksoul"] = true,
    -- Tailoring Crafted Sets
		["Bloodvine Garb"] = true,
    -- Leatherworking Crafted Sets
		["Black Dragon Mail"] = true,
		["Blood Tiger Harness"] = true,
		["Blue Dragon Mail"] = true,
		["Devilsaur Armor"] = true,
		["Green Dragon Mail"] = true,
		["Ironfeather Armor"] = true,
		["Primal Batskin"] = true,
		["Stormshroud Armor"] = true,
		["Volcanic Armor"] = true,
    --Pre60 Sets
		["Battlegear of Undead Slaying"] = true,
		["Bloodmail Regalia"] = true,
		["Cadaverous Garb"] = true,
		["Chain of the Scarlet Crusade"] = true,
		["Dal'Rend's Arms"] = true,
		["Deathbone Guardian"] = true,
		["Defias Leather"] = true,
		["Embrace of the Viper"] = true,
		["Garb of the Undead Slayer"] = true,
		["Ironweave Battlesuit"] = true,
		["Major Mojo Infusion"] = true,
		["Necropile Raiment"] = true,
		["Overlord's Resolution"] = true,
		["Prayer of the Primal"] = true,
		["Primal Blessing"] = true,
		["Regalia of Undead Cleansing"] = true,
		["Shard of the Gods"] = true,
		["Spider's Kiss"] = true,
		["Spirit of Eskhandar"] = true,
		["The Gladiator"] = true,
		["The Postmaster"] = true,
		["The Twin Blades of Hakkari"] = true,
		["Undead Slayer's Armor"] = true,
		["Zanzil's Concentration"] = true,
    --ZG Sets
		["Augur's Regalia"] = true,
		["Confessor's Raiment"] = true,
		["Demoniac's Threads"] = true,
		["Freethinker's Armor"] = true,
		["Haruspex's Garb"] = true,
		["Illusionist's Attire"] = true,
		["Madcap's Outfit"] = true,
		["Predator's Armor"] = true,
		["Vindicator's Battlegear"] = true,
    --AQ20 Sets
		["Battlegear of Eternal Justice"] = true,
		["Battlegear of Unyielding Strength"] = true,
		["Emblems of Veiled Shadows"] = true,
		["Finery of Infinite Wisdom"] = true,
		["Gift of the Gathering Storm"] = true,
		["Implements of Unspoken Names"] = true,
		["Symbols of Unending Life"] = true,
		["Trappings of the Unseen Path"] = true,
		["Trappings of Vaulted Secrets"] = true,
    --AQ40 Sets
		["Avenger's Battlegear"] = true,
		["Conqueror's Battlegear"] = true,
		["Deathdealer's Embrace"] = true,
		["Doomcaller's Attire"] = true,
		["Enigma Vestments"] = true,
		["Garments of the Oracle"] = true,
		["Genesis Raiment"] = true,
		["Stormcaller's Garb"] = true,
		["Striker's Garb"] = true,
    --T0 Sets
		["Battlegear of Valor"] = true,
		["Beaststalker Armor"] = true,
		["Dreadmist Raiment"] = true,
		["Lightforge Armor"] = true,
		["Magister's Regalia"] = true,
		["Shadowcraft Armor"] = true,
		["The Elements"] = true,
		["Vestments of the Devout"] = true,
		["Wildheart Raiment"] = true,
    --T0.5 Sets
		["Battlegear of Heroism"] = true,
		["Beastmaster Armor"] = true,
		["Darkmantle Armor"] = true,
		["Deathmist Raiment"] = true,
		["Feralheart Raiment"] = true,
		["Sorcerer's Regalia"] = true,
		["Soulforge Armor"] = true,
		["The Five Thunders"] = true,
		["Vestments of the Virtuous"] = true,
    --T1 Sets
		["Arcanist Regalia"] = true,
		["Battlegear of Might"] = true,
		["Cenarion Raiment"] = true,
		["Felheart Raiment"] = true,
		["Giantstalker Armor"] = true,
		["Lawbringer Armor"] = true,
		["Nightslayer Armor"] = true,
		["The Earthfury"] = true,
		["Vestments of Prophecy"] = true,
    --T2 Sets
		["Battlegear of Wrath"] = true,
		["Bloodfang Armor"] = true,
		["Dragonstalker Armor"] = true,
		["Judgement Armor"] = true,
		["Nemesis Raiment"] = true,
		["Netherwind Regalia"] = true,
		["Stormrage Raiment"] = true,
		["The Ten Storms"] = true,
		["Vestments of Transcendence"] = true,
    --T3 Sets
		["Bonescythe Armor"] = true,
		["Cryptstalker Armor"] = true,
		["Dreamwalker Raiment"] = true,
		["Frostfire Regalia"] = true,
		["Plagueheart Raiment"] = true,
		["Redemption Armor"] = true,
		["The Earthshatterer"] = true,
		["Vestments of Faith"] = true,
		["Dreadnaught's Battlegear"] = true,
	--PvP Epic Horde Sets
		["Warlord's Battlegear"] = true,
		["Warlord's Earthshaker"] = true,
		["Warlord's Pursuit"] = true,
		["Warlord's Raiment"] = true,
		["Warlord's Regalia"] = true,
		["Warlord's Sanctuary"] = true,
		["Warlord's Threads"] = true,
		["Warlord's Vestments"] = true,
    --PvP Epic Alliance Sets		
		["Field Marshal's Aegis"] = true,
		["Field Marshal's Battlegear"] = true,
		["Field Marshal's Pursuit"] = true,
		["Field Marshal's Raiment"] = true,
		["Field Marshal's Regalia"] = true,
		["Field Marshal's Sanctuary"] = true,
		["Field Marshal's Threads"] = true,
		["Field Marshal's Vestments"] = true,
    --PvP Rare Horde Sets
		["Champion's Refuge"] = true,
		["Champion's Pursuance"] = true,
		["Champion's Arcanum"] = true,
		["Champion's Investiture"] = true,
		["Champion's Guard"] = true,
		["Champion's Stormcaller"] = true,
		["Champion's Dreadgear"] = true,
		["Champion's Battlearmor"] = true,
    --PvP Rare Alliance Sets	
		["Lieutenant Commander's Refuge"] = true,
		["Lieutenant Commander's Pursuance"] = true,
		["Lieutenant Commander's Arcanum"] = true,
		["Lieutenant Commander's Redoubt"] = true,
		["Lieutenant Commander's Investiture"] = true,
		["Lieutenant Commander's Guard"] = true,
		["Lieutenant Commander's Dreadgear"] = true,
		["Lieutenant Commander's Battlearmor"] = true,
	--AB Rare Horde Sets
		["The Defiler's Determination"] = true,
		["The Defiler's Fortitude"] = true,
		["The Defiler's Intent"] = true,
		["The Defiler's Purpose"] = true,
		["The Defiler's Resolution"] = true,
		["The Defiler's Will"] = true,
	--AB Rare Alliance Sets
		["The Highlander's Determination"] = true,
		["The Highlander's Fortitude"] = true,
		["The Highlander's Intent"] = true,
		["The Highlander's Purpose"] = true,
		["The Highlander's Resolution"] = true,
		["The Highlander's Resolve"] = true,
		["The Highlander's Will"] = true,
		
		["Twilight Trappings"] = true,
		
		
		["Lieutenant Commander's Aegis"] = true,
		["Lieutenant Commander's Battlegear"] = true,
		["Lieutenant Commander's Pursuit"] = true,
		["Lieutenant Commander's Raiment"] = true,
		["Lieutenant Commander's Regalia"] = true,
		["Lieutenant Commander's Sanctuary"] = true,
		["Lieutenant Commander's Threads"] = true,
		["Lieutenant Commander's Vestments"] = true,	
		
		["Champion's Battlegear"] = true,
		["Champion's Earthshaker"] = true,
		["Champion's Pursuit"] = true,
		["Champion's Raiment"] = true,
		["Champion's Regalia"] = true,
		["Champion's Sanctuary"] = true,
		["Champion's Threads"] = true,
		["Champion's Vestments"] = true,
	}
end)

BabbleItemSet:RegisterTranslations("zhCN", function()
	return {

		-- Blacksmithing Crafted Sets
		["Bloodsoul Embrace"]  = "血魂之拥",
		["Imperial Plate"]  = "帝国板甲",
		["The Darksoul"]  = "黑暗之魂",
		-- Tailoring Crafted Sets
		["Bloodvine Garb"]  = "血藤套装",
		-- Leatherworking Crafted Sets
		["Black Dragon Mail"]  = "黑龙锁甲",
		["Blood Tiger Harness"]  = "血虎套装",
		["Blue Dragon Mail"]  = "蓝龙锁甲",
		["Devilsaur Armor"]  = "魔暴龙护甲",
		["Green Dragon Mail"]  = "绿龙锁甲",
		["Ironfeather Armor"]  = "铁羽护甲",
		["Primal Batskin"]  = "原始蝙蝠皮套装",
		["Stormshroud Armor"]  = "雷暴套装",
		["Volcanic Armor"]  = "火山套装",
		--Pre60 Sets
		["Battlegear of Undead Slaying"]  = "亡灵杀手战甲",
		["Bloodmail Regalia"]  = "血链套装",
		["Cadaverous Garb"]  = "尸体装束",
		["Chain of the Scarlet Crusade"]  = "血色十字军链甲",
		["Dal'Rend's Arms"]  = "达尔兰德的武器",
		["Deathbone Guardian"]  = "死骨守卫",
		["Defias Leather"]  = "迪菲亚皮甲",
		["Embrace of the Viper"]  = "蝰蛇之拥",
		["Garb of the Undead Slayer"]  = "亡灵杀手外套",
		["Ironweave Battlesuit"]  = "铁纹战甲",
		["Major Mojo Infusion"]  = "重要魔精注入",
		["Necropile Raiment"]  = "死灵套装",
		["Overlord's Resolution"]  = "霸主的决心",
		["Prayer of the Primal"]  = "原始祈福",
		["Primal Blessing"]  = "原始祝福",
		["Regalia of Undead Cleansing"]  = "亡灵净化法衣",
		["Shard of the Gods"]  = "神灵碎片",
		["Spider's Kiss"]  = "蜘蛛之吻",
		["Spirit of Eskhandar"]  = "艾斯卡达尔之魂",
		["The Gladiator"]  = "角斗士",
		["The Postmaster"]  = "邮差",
		["The Twin Blades of Hakkari"]  = "哈卡莱双刃",
		["Undead Slayer's Armor"]  = "亡灵杀手盔甲",
		["Zanzil's Concentration"]  = "赞吉尔的专注",
		--ZG Sets
		["Augur's Regalia"]  = "占卜师的法衣",
		["Confessor's Raiment"]  = "忏悔者的法衣",
		["Demoniac's Threads"]  = "恶魔使徒的衣物",
		["Freethinker's Armor"]  = "自由思考者的盔甲",
		["Haruspex's Garb"]  = "占卜者的服饰",
		["Illusionist's Attire"]  = "幻术师的服饰",
		["Madcap's Outfit"]  = "疯狂帽子的套装",
		["Predator's Armor"]  = "掠夺者的盔甲",
		["Vindicator's Battlegear"]  = "维护者的战甲",
		-- AQ20 Sets
		["Battlegear of Eternal Justice"]  = "永恒正义战甲",
		["Battlegear of Unyielding Strength"]  = "坚定力量战甲",
		["Emblems of Veiled Shadows"]  = "幽暗徽记",
		["Finery of Infinite Wisdom"]  = "无尽智慧华服",
		["Gift of the Gathering Storm"]  = "聚风者的礼物",
		["Implements of Unspoken Names"]  = "无言之名法器",
		["Symbols of Unending Life"]  = "无尽生命符文",
		["Trappings of the Unseen Path"]  = "无形之路装束",
		["Trappings of Vaulted Secrets"]  = "秘密宝库装束",
		-- AQ40 Sets
		["Avenger's Battlegear"]  = "复仇者战甲",
		["Conqueror's Battlegear"]  = "征服者战甲",
		["Deathdealer's Embrace"]  = "死亡使者的拥抱",
		["Doomcaller's Attire"]  = "末日召唤者的服饰",
		["Enigma Vestments"]  = "谜题法衣",
		["Garments of the Oracle"]  = "神谕者的服饰",
		["Genesis Raiment"]  = "创世者的护甲",
		["Stormcaller's Garb"]  = "唤风者的衣饰",
		["Striker's Garb"]  = "打击者的衣饰",
		-- T0 Sets
		["Battlegear of Valor"]  = "勇气战甲",
		["Beaststalker Armor"]  = "兽王护甲",
		["Dreadmist Raiment"]  = "恐怖之雾法衣",
		["Lightforge Armor"]  = "光铸护甲",
		["Magister's Regalia"]  = "博学者法衣",
		["Shadowcraft Armor"]  = "暗影之纹",
		["The Elements"]  = "元素套装",
		["Vestments of the Devout"]  = "虔诚套装",
		["Wildheart Raiment"]  = "野性之心法衣",
		-- T0.5 Sets
		["Battlegear of Heroism"]  = "英勇战甲",
		["Beastmaster Armor"]  = "兽王护甲",
		["Darkmantle Armor"]  = "暗幕护甲",
		["Deathmist Raiment"]  = "死雾法衣",
		["Feralheart Raiment"]  = "野性之心法衣",
		["Sorcerer's Regalia"]  = "巫师法衣",
		["Soulforge Armor"]  = "灵魂熔炉护甲",
		["The Five Thunders"]  = "五雷套装",
		["Vestments of the Virtuous"]  = "贤者法衣",
		-- T1 Sets
		["Arcanist Regalia"]  = "秘法师法衣",
		["Battlegear of Might"]  = "力量战甲",
		["Cenarion Raiment"]  = "塞纳里奥法衣",
		["Felheart Raiment"]  = "恶魔之心法衣",
		["Giantstalker Armor"]  = "巨人追猎者护甲",
		["Lawbringer Armor"]  = "审判者护甲",
		["Nightslayer Armor"]  = "夜幕杀手护甲",
		["The Earthfury"]  = "大地之怒套装",
		["Vestments of Prophecy"]  = "预言法衣",
		--T2 Sets
		["Battlegear of Wrath"]  = "愤怒战甲",
		["Bloodfang Armor"]  = "血牙护甲",
		["Dragonstalker Armor"]  = "龙骑士护甲",
		["Judgement Armor"]  = "审判护甲",
		["Nemesis Raiment"]  = "复仇者法衣",
		["Netherwind Regalia"]  = "灵风法衣",
		["Stormrage Raiment"]  = "怒风套装",
		["The Ten Storms"]  = "十雷套装",
		["Vestments of Transcendence"]  = "超凡法衣",
		-- T3 Sets
		["Bonescythe Armor"]  = "白骨追猎者护甲",
		["Cryptstalker Armor"]  = "地穴追猎者护甲",
		["Dreamwalker Raiment"]  = "梦行者法衣",
		["Frostfire Regalia"]  = "霜火法衣",
		["Plagueheart Raiment"]  = "瘟疫之心法衣",
		["Redemption Armor"]  = "救赎护甲",
		["The Earthshatterer"]  = "地震者",
		["Vestments of Faith"]  = "信仰法衣",
		["Dreadnaught's Battlegear"]  = "无畏战甲",
		-- PvP Epic Horde Sets
		["Warlord's Battlegear"]  = "督军战甲",
		["Warlord's Earthshaker"]  = "督军震地者",
		["Warlord's Pursuit"]  = "督军追猎者",
		["Warlord's Raiment"]  = "督军法衣",
		["Warlord's Regalia"]  = "督军法袍",
		["Warlord's Sanctuary"]  = "督军圣装",
		["Warlord's Threads"]  = "督军衣饰",
		["Warlord's Vestments"]  = "督军法袍",
		-- PvP Epic Alliance Sets
		["Field Marshal's Aegis"]  = "元帅的庇护",
		["Field Marshal's Battlegear"]  = "元帅的战甲",
		["Field Marshal's Pursuit"]  = "元帅的追猎者",
		["Field Marshal's Raiment"]  = "元帅的法衣",
		["Field Marshal's Regalia"]  = "元帅的法袍",
		["Field Marshal's Sanctuary"]  = "元帅的圣装",
		["Field Marshal's Threads"]  = "元帅的衣饰",
		["Field Marshal's Vestments"]  = "元帅的法袍",
		-- PvP Rare Horde Sets
		["Champion's Refuge"]  = "勇士的庇护",
		["Champion's Pursuance"]  = "勇士的追猎者",
		["Champion's Arcanum"]  = "勇士的奥秘",
		["Champion's Investiture"]  = "勇士的祭服",
		["Champion's Guard"]  = "勇士的守卫",
		["Champion's Stormcaller"]  = "勇士的唤风者",
		["Champion's Dreadgear"]  = "勇士的恐怖之装",
		["Champion's Battlearmor"]  = "勇士的战甲",
		--PvP Rare Alliance Sets    
		["Lieutenant Commander's Refuge"]  = "中尉指挥官的庇护",
		["Lieutenant Commander's Pursuance"]  = "中尉指挥官的追猎者",
		["Lieutenant Commander's Arcanum"]  = "中尉指挥官的奥秘",
		["Lieutenant Commander's Redoubt"]  = "中尉指挥官的堡垒",
		["Lieutenant Commander's Investiture"]  = "中尉指挥官的祭服",
		["Lieutenant Commander's Guard"]  = "中尉指挥官的守卫",
		["Lieutenant Commander's Dreadgear"]  = "中尉指挥官的恐怖之装",
		["Lieutenant Commander's Battlearmor"]  = "中尉指挥官的战甲",
		-- AB Rare Horde Sets
		["The Defiler's Determination"]  = "亵渎者的决心",
		["The Defiler's Fortitude"]  = "亵渎者的坚毅",
		["The Defiler's Intent"]  = "亵渎者的意图",
		["The Defiler's Purpose"]  = "亵渎者的目标",
		["The Defiler's Resolution"]  = "亵渎者的决议",
		["The Defiler's Will"]  = "亵渎者的意志",
		-- AB Rare Alliance Sets
		["The Highlander's Determination"]  = "高地人的决心",
		["The Highlander's Fortitude"]  = "高地人的坚毅",
		["The Highlander's Intent"]  = "高地人的意图",
		["The Highlander's Purpose"]  = "高地人的目标",
		["The Highlander's Resolution"]  = "高地人的决议",
		["The Highlander's Resolve"]  = "高地人的决心",
		["The Highlander's Will"]  = "高地人的意志",
    
		["Twilight Trappings"]  = "暮光装束",
    
    
		["Lieutenant Commander's Aegis"]  = "中尉指挥官的庇护",
		["Lieutenant Commander's Battlegear"]  = "中尉指挥官的战甲",
		["Lieutenant Commander's Pursuit"]  = "中尉指挥官的追猎者",
		["Lieutenant Commander's Raiment"]  = "中尉指挥官的法衣",
		["Lieutenant Commander's Regalia"]  = "中尉指挥官的法袍",
		["Lieutenant Commander's Sanctuary"]  = "中尉指挥官的圣装",
		["Lieutenant Commander's Threads"]  = "中尉指挥官的衣饰",
		["Lieutenant Commander's Vestments"]  = "中尉指挥官的法袍",    
    
		["Champion's Battlegear"]  = "勇士战甲",
		["Champion's Earthshaker"]  = "勇士震地者",
		["Champion's Pursuit"]  = "勇士追猎者",
		["Champion's Raiment"]  = "勇士法衣",
		["Champion's Regalia"]  = "勇士法袍",
		["Champion's Sanctuary"]  = "勇士圣装",
		["Champion's Threads"]  = "勇士衣饰",
		["Champion's Vestments"]  = "勇士法袍",

	}
end)
BabbleItemSet:Debug()
BabbleItemSet:SetStrictness(true)

AceLibrary:Register(BabbleItemSet, MAJOR_VERSION, MINOR_VERSION)
BabbleItemSet = nil
