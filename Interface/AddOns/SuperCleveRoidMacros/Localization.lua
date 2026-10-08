--[[
	Author  : Dennis Werner Garske (DWG) / brian / Mewtiny
	License : MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}
CleveRoids.Locale = GetLocale()
CleveRoids.Localized = {}

if CleveRoids.Locale ~= "zhCN" then -- 非中文一律归入英文分支（Turtle 仅有中英文） by 武藤纯子酱 2026.8.31
    -- place item in backpack slot 1 and run:
    -- /script local l=GetContainerItemLink(0,1);local _,_,id=string.find(l,"item:(%d+)");local n,_,_,_,t,st=GetItemInfo(id);DEFAULT_CHAT_FRAME:AddMessage("\n\nID: ["..id.."]\nName: ["..n.."]\nType: ["..t.."]\nSub Type: ["..st.."]\n\n");
    CleveRoids.Localized.Shield     = "Shields"
    CleveRoids.Localized.Bow        = "Bows"
    CleveRoids.Localized.Crossbow   = "Crossbows"
    CleveRoids.Localized.Gun        = "Guns"
    CleveRoids.Localized.Thrown     = "Thrown"
    CleveRoids.Localized.Wand       = "Wands"
    CleveRoids.Localized.Sword      = "Swords"
    CleveRoids.Localized.Staff      = "Staves"
    CleveRoids.Localized.Polearm    = "Polearms"
    CleveRoids.Localized.Mace       = "Maces"
    CleveRoids.Localized.FistWeapon = "Fist Weapons"
    CleveRoids.Localized.Dagger     = "Daggers"
    CleveRoids.Localized.Axe        = "Axes"

    CleveRoids.Localized.Attack    = "Attack"
    CleveRoids.Localized.AutoShot  = "Auto Shot"
    CleveRoids.Localized.Shoot     = "Shoot"
    CleveRoids.Localized.PetDismissSpell = "Dismiss Pet" -- 宠物技能名：/petdismiss 经此技能解散野兽（宠物动作条无该按钮时兜底 CastSpellByName）by 武藤纯子酱 2026.9.3
    CleveRoids.Localized.SpellRank = "%(Rank %d+%)"
    CleveRoids.Localized.SpellRank2 = "%(Rank%s+(%d+)%)"

    -- target creature and run:
    -- /script local ct, uc = UnitCreatureType("target"),UnitClassification("target"); DEFAULT_CHAT_FRAME:AddMessage("\n\nUnitCreatureType: ["..ct.."]\nUnitClassificationType: ["..uc.."]\n\n");
    CleveRoids.Localized.CreatureTypes = {
        ["Beast"]         = "Beast",
        ["Critter"]       = "Critter",
        ["Demon"]         = "Demon",
        ["Dragonkin"]     = "Dragonkin",
        ["Elemental"]     = "Elemental",
        ["Giant"]         = "Giant",
        ["Humanoid"]      = "Humanoid",
        ["Mechanical"]    = "Mechanical",
        ["Not specified"] = "Not Specified",
        ["Not Specified"] = "Not Specified", -- 别名：兼容大小写差异 by 武藤纯子酱 2026.9.11
        ["Totem"]         = "Totem",
        ["Undead"]        = "Undead",
    }

    CleveRoids.Localized.Spells = {
        ["Shadowform"]      = "Shadowform",
        ["Stealth"]         = "Stealth",
        ["Prowl"]           = "Prowl",
        ["Shadowmeld"]      = "Shadowmeld",
        ["Revenge"]         = "Revenge",
        ["Overpower"]       = "Overpower",
        ["Riposte"]         = "Riposte",
        ["Surprise Attack"] = "Surprise Attack",
        ["Lacerate"]        = "Lacerate",
        ["Baited Shot"]     = "Baited Shot",
        ["Counterattack"]   = "Counterattack",
        ["Arcane Surge"]    = "Arcane Surge",
		["Aquatic Form"]    = "Aquatic Form", -- 增加德鲁伊技能：水栖形态 by 武藤纯子酱 2025.11.27
		["Rupture"]		    = "Rupture", -- 增加盗贼技能：割裂 by 武藤纯子酱 2025.12.1
		["Kidney Shot"]		= "Kidney Shot", -- 增加盗贼技能：肾击 by 武藤纯子酱 2025.12.1
		["Rip"]				= "Rip", -- 增加德鲁伊技能：撕扯 by 武藤纯子酱 2025.12.1
		["Rake"]			= "Rake", -- 增加德鲁伊技能：扫击 by 武藤纯子酱 2025.12.1
		["Pounce"]			= "Pounce", -- 增加德鲁伊技能：突袭 by 武藤纯子酱 2025.12.2
		["Garrote"]			= "Garrote", -- 增加盗贼技能：绞喉 by 武藤纯子酱 2025.12.2
		["Rend"] 			= "Rend",  -- 增加战士技能：撕裂 by 武藤纯子酱 2025.12.2
		["Deep Wound"] 		= "Deep Wound",  -- 增加战士技能：重伤 by 武藤纯子酱 2025.12.2
		["Deep Wounds"] 	= "Deep Wounds",  -- 增加战士技能：重伤 by 武藤纯子酱 2025.12.30
		["Hemorrhage"]		= "Hemorrhage", -- 增加盗贼技能：出血 by 武藤纯子酱 2025.12.2
		["Polymorph"]		= "Polymorph", -- 增加法师技能：变形术 by 武藤纯子酱 2025.12.2
		["Mana Burn"]		= "Mana Burn", -- 增加牧师技能：法力燃烧 by 武藤纯子酱 2025.12.2
		["Ignite"] 			= "Ignite", -- 增加法师技能：点燃 by 武藤纯子酱 2025.12.2
		["Immolate"] 		= "Immolate", -- 增加术士技能：献祭 by 武藤纯子酱 2025.12.2（修复拼写 Immolat→Immolate by 武藤纯子酱 2026.8.31）
		["Immolat"] 		= "Immolate", -- 旧拼写别名：兼容 Utility.lua GetSpellSchool 旧键引用 by 武藤纯子酱 2026.8.31
		["Scorch"] 			= "Scorch", -- 增加法师技能：灼烧 by 武藤纯子酱 2025.12.2
		["Pyroblast"]		= "Pyroblast", -- 增加法师技能：炎爆术 by 武藤纯子酱 2025.12.2
		["Combustion"]		= "Combustion", -- 增加术士技能：燃烧 by 武藤纯子酱 2025.12.2
		["Blizzard"]		= "Blizzard", -- 增加法师技能：暴风雪 by 武藤纯子酱 2025.12.2
		["Freeze"]			= "Freeze", -- 增加技能：冰冻术 by 武藤纯子酱 2025.12.2
		["Wrath"]			= "Wrath", -- 增加德鲁伊技能：愤怒 by 武藤纯子酱 2025.12.2
		["Heroic Strike"]	= "Heroic Strike", -- 增加战士技能：英勇打击 by 武藤纯子酱 2026.1.4
		["Cleave"]			= "Cleave", -- 增加战士技能：顺劈斩 by 武藤纯子酱 2026.1.4
		["Maul"]			= "Maul", -- 增加德鲁伊技能：槌击 by 武藤纯子酱 2026.1.4
		["Slam"]			= "Slam", -- 增加战士技能：猛击 by 武藤纯子酱 2026.1.4
		["Raptor Strike"]	= "Raptor Strike", -- 增加猎人技能：猛禽一击 by 武藤纯子酱 2026.1.4
		["Mongoose Bite"]	= "Mongoose Bite", -- 增加猎人技能：猫鼬撕咬 by 武藤纯子酱 2026.1.4
		["Arcane Missiles"]	= "Arcane Missiles", -- 增加法师技能：奥术飞弹 by 武藤纯子酱 2026.1.4
		["Drain Life"]		= "Drain Life", -- 增加术士技能：吸取生命 by 武藤纯子酱 2026.1.4
		["Drain Mana"]		= "Drain Mana", -- 增加术士技能：吸取法力 by 武藤纯子酱 2026.1.4
		["Drain Soul"]		= "Drain Soul", -- 增加术士技能：吸取灵魂 by 武藤纯子酱 2026.1.4
		["Evocation"]		= "Evocation", -- 增加法师技能：唤醒 by 武藤纯子酱 2026.1.4
		["Health Funnel"]	= "Health Funnel", -- 增加术士技能：生命通道 by 武藤纯子酱 2026.1.4
		["Hellfire"]		= "Hellfire", -- 增加术士技能：地狱烈焰 by 武藤纯子酱 2026.1.4
		["Hurricane"]		= "Hurricane", -- 增加德鲁伊技能：飓风 by 武藤纯子酱 2026.1.4
		["Mind Flay"]		= "Mind Flay", -- 增加牧师技能：精神鞭笞 by 武藤纯子酱 2026.1.4
		["Rain of Fire"]	= "Rain of Fire", -- 增加术士技能：火焰之雨 by 武藤纯子酱 2026.1.4
		["Tranquility"]		= "Tranquility", -- 增加德鲁伊技能：宁静 by 武藤纯子酱 2026.1.4
		["Volley"]			= "Volley", -- 增加猎人技能：乱射 by 武藤纯子酱 2026.1.4
		["Mind Soothe"]		= "Mind Soothe", -- 增加牧师技能：心灵安抚 by 武藤纯子酱 2026.1.4
		["Mind Vision"]		= "Mind Vision", -- 增加牧师技能：心灵视界 by 武藤纯子酱 2026.1.4
		["First Aid"]		= "First Aid", -- 增加通用技能：急救 by 武藤纯子酱 2026.1.4
		["Hamstring"]		= "Hamstring", -- 增加战士技能：断筋 by 武藤纯子酱 2026.1.4
		["Taunt"]			= "Taunt", -- 增加战士技能：嘲讽 by 武藤纯子酱 2026.1.4
		["Growl"]			= "Growl", -- 增加猎人宠物技能：低吼 by 武藤纯子酱 2026.1.4
		["Mocking Blow"]	= "Mocking Blow", -- 增加战士技能：惩戒痛击 by 武藤纯子酱 2026.1.4
		["Hand of Reckoning"]	= "Hand of Reckoning", -- 增加圣骑士技能：清算之手 by 武藤纯子酱 2026.1.4
		["Deadly Poison"]	= "Deadly Poison", -- 增加盗贼毒药：致命毒药 by 武藤纯子酱 2026.1.4
		["Crippling Poison"]= "Crippling Poison", -- 增加盗贼毒药：致残毒药 by 武藤纯子酱 2026.1.4
		["Wound Poison"]	= "Wound Poison", -- 增加盗贼毒药：致伤毒药 by 武藤纯子酱 2026.1.4
		["Mind-numbing Poison"]= "Mind-numbing Poison", -- 增加盗贼毒药：麻痹毒药 by 武藤纯子酱 2026.1.4
		["Thunderfury"]		= "Thunderfury", -- 增加风剑特效：雷霆之怒 by 武藤纯子酱 2026.1.4
		["Thunderfury Slow"]= "Thunderfury Slow", -- 增加风剑特效：雷霆之怒 by 武藤纯子酱 2026.1.4
		["Master Strike"]	= "Master Strike", -- 增加特效打击 by 武藤纯子酱 2026.1.16
		["Nightfall"]		= "Spell Vulnerability", -- 增加夜幕法术易伤 by 武藤纯子酱 2026.2.1

		-- Druid
		["Faerie Fire"] 			= "Faerie Fire", -- 增加德鲁伊技能：精灵之火 by 武藤纯子酱 2025.12.2
		["Moonfire"] 				= "Moonfire",  -- 增加德鲁伊技能：月火术 by 武藤纯子酱 2025.12.2
		["Insect Swarm"] 			= "Insect Swarm", -- 增加德鲁伊技能：虫群 by 武藤纯子酱 2025.12.2
		["Abolish Poison"] 			= "Abolish Poison", -- 增加德鲁伊技能：驱毒术 by 武藤纯子酱 2025.12.2
		["Remove Curse"] 			= "Remove Curse", -- 增加德鲁伊技能：解除诅咒 by 武藤纯子酱 2025.12.2
		["Starfire"]				= "Starfire", -- 增加德鲁伊技能：星火术 by 武藤纯子酱 2025.12.2
		["Thorns"]					= "Thorns", -- 增加德鲁伊技能：荆棘术 by 武藤纯子酱 2025.12.2
		["Faerie Fire (Feral)"] 	= "Faerie Fire (Feral)", -- 增加德鲁伊技能：精灵之火（野性） by 武藤纯子酱 2025.12.29
		["Faerie Fire (Bear)"] 		= "Faerie Fire (Bear)", -- 增加德鲁伊技能：精灵之火（熊） by 武藤纯子酱 2025.12.29
		["Pounce Bleed"] 			= "Pounce Bleed", -- 增加德鲁伊技能：血袭 by 武藤纯子酱 2025.12.29
		["Demoralizing Roar"] 		= "Demoralizing Roar", -- 增加德鲁伊技能：挫志咆哮 by 武藤纯子酱 2026.2.1

		-- Mage
		["Amplify Magic"] 			= "Amplify Magic", -- 增加法师技能：魔法增效 by 武藤纯子酱 2025.12.2
		["Dampen Magic"] 			= "Dampen Magic", -- 增加法师技能：魔法抑制 by 武藤纯子酱 2025.12.2
		["Remove Lesser Curse"] 	= "Remove Lesser Curse", -- 增加法师技能：解除次级诅咒袭 by 武藤纯子酱 2025.12.2
		["Slow Fall"] 				= "Slow Fall", -- 增加法师技能：缓落术 by 武藤纯子酱 2025.12.2
		["Detect Magic"] 			= "Detect Magic", -- 增加法师技能：侦测魔法 by 武藤纯子酱 2025.12.2
		["Improved Scorch"]			= "Fire Vulnerability", -- 增加火焰易伤 by 武藤纯子酱 2026.2.1
		["Winter's Chill"]			= "Winter's Chill", -- 增加深冬之寒 by 武藤纯子酱 2026.2.1

		-- Priest
		["Dispel Magic"] 			= "Dispel Magic", -- 增加牧师技能：驱散魔法 by 武藤纯子酱 2025.12.2
		["Cure Disease"] 			= "Cure Disease", -- 增加牧师技能：祛病术 by 武藤纯子酱 2025.12.2
		["Abolish Disease"] 		= "Abolish Disease", -- 增加牧师技能：驱除疾病 by 武藤纯子酱 2025.12.2
		["Power Word: Fortitude"] 	= "Power Word: Fortitude", -- 增加牧师技能：真言术：韧 by 武藤纯子酱 2025.12.2
		["Power Word: Shield"] 		= "Power Word: Shield", -- 增加牧师技能：真言术：盾 by 武藤纯子酱 2025.12.2
		["Divine Spirit"] 			= "Divine Spirit", -- 增加牧师技能：神圣之灵 by 武藤纯子酱 2025.12.2
		["Fear Ward"] 				= "Fear Ward", -- 增加牧师技能：防护恐惧结界 by 武藤纯子酱 2025.12.2
		["Resurrection"] 			= "Resurrection", -- 增加牧师技能：复活术 by 武藤纯子酱 2025.12.2
		["Smite"]					= "Smite", -- 增加牧师技能：惩击 by 武藤纯子酱 2025.12.2
		["Shadow Weaving"]			= "Shadow Weaving", -- 增加牧师技能：暗影之波 by 武藤纯子酱 2026.2.1

		-- Paladin
		["Cleanse"] 				= "Cleanse", -- 增加圣骑士技能：清洁术 by 武藤纯子酱 2025.12.2
		["Purify"] 					= "Purify", -- 增加圣骑士技能：纯净术 by 武藤纯子酱 2025.12.2
		["Divine Protection"]		= "Divine Protection", -- 增加圣骑士技能：圣佑术 by 武藤纯子酱 2025.12.2
		["Divine Shield"] 			= "Divine Shield", -- 增加圣骑士技能：圣盾术 by 武藤纯子酱 2025.12.2
		["Blessing of Protection"] 	= "Blessing of Protection", -- 增加圣骑士技能：保护祝福 by 武藤纯子酱 2025.12.2
		["Blessing of Freedom"] 	= "Blessing of Freedom", -- 增加圣骑士技能：自由祝福 by 武藤纯子酱 2025.12.2
		["Blessing of Sacrifice"] 	= "Blessing of Sacrifice", -- 增加圣骑士技能：牺牲祝福 by 武藤纯子酱 2025.12.2
		["Redemption"] 				= "Redemption", -- 增加圣骑士技能：救赎 by 武藤纯子酱 2025.12.2（修复拼写 Redemptio→Redemption by 武藤纯子酱 2026.8.31）
		["Exorcism"]				= "Exorcism", -- 增加圣骑士技能：驱邪术 by 武藤纯子酱 2025.12.2
		["Consecration"]			= "Consecration", -- 增加圣骑士技能：奉献 by 武藤纯子酱 2025.12.2（修复拼写 Consecrat→Consecration by 武藤纯子酱 2026.8.31）
		["Consecrat"]			= "Consecration", -- 旧拼写别名：兼容 Utility.lua GetSpellSchool 旧键引用 by 武藤纯子酱 2026.8.31
		["Hammer of Wrath"]			= "Hammer of Wrath", -- 增加圣骑士技能：愤怒之锤 by 武藤纯子酱 2025.12.2
		["Judgement of Justice"]	= "Judgement of Justice", -- 增加圣骑士技能：正义审判 by 武藤纯子酱 2025.12.3
		["Judgement of Light"]		= "Judgement of Light", -- 增加圣骑士技能：光明审判 by 武藤纯子酱 2025.12.3
		["Judgement of Wisdom"]		= "Judgement of Wisdom", -- 增加圣骑士技能：智慧审判 by 武藤纯子酱 2025.12.3
		["Judgement of the Crusader"] = "Judgement of the Crusader", -- 增加圣骑士技能：十字军审判 by 武藤纯子酱 2025.12.3
		["Judgement of Righteousness"]= "Judgement of Righteousness", -- 增加圣骑士技能：正义审判 by 武藤纯子酱 2026.1.4
		["Judgement of Command"] 	= "Judgement of Command", -- 增加圣骑士技能：命令审判 by 武藤纯子酱 2026.1.4
		["Judgement"] 				= "Judgement", -- 增加圣骑士技能：审判 by 武藤纯子酱 2026.1.4

		-- Warlock
		["Banish"] 					= "Banish", -- 增加术士技能：放逐术 by 武藤纯子酱 2025.12.2
		["Curse of Weakness"] 		= "Curse of Weakness", -- 增加术士技能：虚弱诅咒 by 武藤纯子酱 2025.12.2
		["Curse of Recklessness"] 	= "Curse of Recklessness", -- 增加术士技能：鲁莽诅咒 by 武藤纯子酱 2025.12.2
		["Curse of Tongues"] 		= "Curse of Tongues", -- 增加术士技能：语言诅咒 by 武藤纯子酱 2025.12.2
		["Amplify Curse"] 			= "Amplify Curse", -- 增加术士技能：诅咒增幅 by 武藤纯子酱 2025.12.2
		["Death Coil"] 				= "Death Coil",  -- 增加术士技能：死亡缠绕 by 武藤纯子酱 2025.12.2
		["Corruption"] 				= "Corruption",  -- 增加术士技能：腐蚀术 by 武藤纯子酱 2025.12.2
		["Curse of the Elements"]	= "Curse of the Elements", -- 增加术士技能：元素诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Shadow"]			= "Curse of Shadow", -- 增加术士技能：暗影诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Idiocy"]			= "Curse of Idiocy", -- 增加术士技能：痴呆诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Agony"]			= "Curse of Agony", -- 增加术士技能：痛苦诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Doom"]			= "Curse of Doom", -- 增加术士技能：厄运诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Exhaustion"]		= "Curse of Exhaustion", -- 增加术士技能：疲劳诅咒 by 武藤纯子酱 2026.2.1
		["Shadow Vulnerability"]	= "Shadow Vulnerability", -- 增加术士技能：暗影易伤 by 武藤纯子酱 2026.2.1

		-- Shaman
		["Cure Poison"] 			= "Cure Poison", -- 增加萨满技能：消毒术 by 武藤纯子酱 2025.12.2
		["Cure Disease"] 			= "Cure Disease", -- 增加萨满技能：祛病术 by 武藤纯子酱 2025.12.2
		["Purge"] 					= "Purge", -- 增加萨满技能：净化术 by 武藤纯子酱 2025.12.2
		["Ancestral Spirit"] 		= "Ancestral Spirit", -- 增加萨满技能：先祖之魂 by 武藤纯子酱 2025.12.2
		["Molten Blast"] 			= "Molten Blast", -- 增加萨满技能：熔岩爆裂 by 武藤纯子酱 2025.12.29		
		["Stormstrike"] 			= "Stormstrike", -- 增加萨满技能：风暴打击 by 武藤纯子酱 2026.2.1

		-- Hunter
		["Aspect of the Hawk"] 		= "Aspect of the Hawk", -- 增加猎人技能：雄鹰守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Monkey"] 	= "Aspect of the Monkey", -- 增加猎人技能：灵猴守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Cheetah"] 	= "Aspect of the Cheetah", -- 增加猎人技能：猎豹守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Pack"] 		= "Aspect of the Pack", -- 增加猎人技能：豹群守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Wild"] 		= "Aspect of the Wild", -- 增加猎人技能：野性守护 by 武藤纯子酱 2025.12.2
		["Hunter's Mark"] 			= "Hunter's Mark", -- 增加猎人技能：猎人印记 by 武藤纯子酱 2026.2.1
		["Scorpid Sting"] 			= "Scorpid Sting", -- 增加猎人技能：毒蝎钉刺 by 武藤纯子酱 2026.2.1
		
		-- Warrior
		["Sunder Armor"] 			= "Sunder Armor", -- 增加战士技能：破甲攻击 by 武藤纯子酱 2026.2.1
		["Demoralizing Shout"] 		= "Demoralizing Shout", -- 增加战士技能：挫志怒吼 by 武藤纯子酱 2026.2.1

		-- Rogue
		["Expose Armor"] 			= "Expose Armor", -- 增加盗贼技能：破甲 by 武藤纯子酱 2026.2.1
		["Slice and Dice"] 			= "Slice and Dice", -- 增加盗贼技能：切割 by 武藤纯子酱 2026.2.1		
    }

    -- place item in backpack slot 1 and run:
    -- /script local l=GetContainerItemLink(0,1);local _,_,id=string.find(l,"item:(%d+)");local n,_,_,_,t,st=GetItemInfo(id);DEFAULT_CHAT_FRAME:AddMessage("\n\nID: ["..id.."]\nName: ["..n.."]\nType: ["..t.."]\nSub Type: ["..st.."]\n\n");
    CleveRoids.Localized.ItemTypes = {
        ["Consumable"]  = "Consumable",
        ["Reagent"]     = "Reagent",
        ["Projectile"]  = "Projectile",
        ["Trade Goods"] = "Trade Goods",
    }
	-- 增加团队标记 by 武藤纯子酱 2025.11.27
    CleveRoids.Localized.RaidTargetIndex = {
        [1]  = "Star",
        [2]     = "Circle",
        [3]  = "Diamond",
        [4] = "Triangle",
        [5]  = "Moon",
        [6]     = "Square",
        [7]  = "Cross",
        [8] = "Skull",		
    }

	-- 增加战斗日志关键词翻译 by 武藤纯子酱 2025.12.2
    CleveRoids.Localized.CombatLogs = {
        ["hit"]			= "hit",
        ["crit"]		= "crit",
		["fades from"]	= "fades from",
		["you"]			= "you",
		["resist"]		= "resist",
		["miss"]		= "miss",
		["dodge"]		= "dodge",
		["parry"]		= "parry",
		["block"]		= "block",
		["immune"]		= "immune",
		["failed"]		= "failed",
		["resisted%)"]	= "resisted%)",
        ["^You hit"]	= "^You hit",
        ["^You crit"]	= "^You crit",
        ["Fire damage"]	= "Fire damage",
        ["afflicted by"]= "afflicted by",
        ["^(.-)%s+is afflicted by%s+(.+)"]= "^(.-)%s+is afflicted by%s+(.+)",
		["reflect"]		= "reflect",
		["evade"]		= "evade",
		["(.+) fades from (.+)"]= "(.+) fades from (.+)",
    }

	-- 增加战斗日志施法失败相关文字翻译 by 武藤纯子酱 2025.12.2
    CleveRoids.Localized.SpellFailedTests = {
		["resisted"]	=	"Your (.+) was resisted by (.+)",
		["missed"]		=	"Your (.+) missed (.+)",
		["parried"]		=	"Your (.+) is parried by (.+)",
		["dodged"]		=	"Your (.+) was dodged by (.+)",
		["blocked"]		=	"Your (.+) was blocked by (.+)",
		["immune"]		=	"Your (.+) fail.+%. (.+) is immune",
		["fades"]		=	"(.+) fades from (.+)",
		["immune_2"]	=	"Your%s+(.-)%s+fails%.%s+(.-)%s+is immune",
		["immune_3"]	=	"Your%s+(.-)%s+failed%.%s+(.-)%s+is immune",
		["immune_4"]	=	"^(.-)%s+is immune to",
		["immune_5"]	=	"^(.-)%s+is immune",
		["immune_6"]	=	"is immune to",
		["immune_7"]	=	"is immune to%s*",
		["resisted_2"]	=	"^(.-)%s+resists your (.-)%.",
		["reflect_1"]	=	"Your%s+(.-)%s+is reflected back by%s+(.-)%.",
		["reflect_2"]	=	"Your%s+(.-)%s+was reflected by%s+(.-)%.",
		["reflect_3"]	=	"^(.-)%s+reflects your%s+(.-)%.",
		["reflect_4"]	=	"^(.-)%s+reflects%s+(.-)%s+back",
		["evade_1"]	=	"Your%s+(.-)%s+fails%.%s+(.-)%s+evades",
		["evade_2"]	=	"Your%s+(.-)%s+failed%.%s+(.-)%s+evades",
		["evade_3"]	=	"^(.-)%s+evades your%s+(.-)%.",
		["evade_4"]	=	"^(.-)%s+evades",
    }
	
	-- 增加天赋相关文字翻译 by 武藤纯子酱 2025.12.2
	CleveRoids.Localized.talentModifiers = {
		["Taste for Blood"]					=	"Taste for Blood",
		["Improved Gouge"]					=	"Improved Gouge",
		["Improved Shadow Word: Pain"]		=	"Improved Shadow Word: Pain",
		["Brutal Impact"]					=	"Brutal Impact",
		["Booming Voice"]					=	"Booming Voice",
	}
	
	-- 伤害类型相关文字翻译 by 武藤纯子酱 2025.12.2
	CleveRoids.Localized.SpellSchool = {
		["physical"]	=	"physical",
		["holy"]		=	"holy",
		["fire"]		=	"fire",
		["nature"]		=	"nature",
		["frost"]		=	"frost",
		["shadow"]		=	"shadow",
		["arcane"]		=	"arcane",
		["bleed"]		=	"bleed",	
		["ice"]			=	"ice",
		["poison"]		=	"poison",
		["flame"]		=	"flame",
		["dark"]		=	"dark",
		["divine"]		=	"divine",
		["^fire"]		=	"^fire",
		[" fire"]		=	"fire",
		["chill"]		=	"chill",
		["sting"]		=	"sting",
		["curse"]		=	"curse",
		["drain"]		=	"drain",
		["vampir"]		=	"vampir",
		["affliction"]	=	"affliction",
		["judgment"]	=	"judgment",
	}
	
	-- 技能描述中获取持续时间 by 武藤纯子酱 2025.12.11
	CleveRoids.Localized.SpellDuration = {
		["for"] = "for (%d+%.?%d*) sec",
		["over"] = "over (%d+%.?%d*) sec",
		["per"] = "(%d+%.?%d*) sec",
		["sec"] = "(%d+%.?%d*) sec",
		["(%d+%.?%d*) sec cast"] = "(%d+%.?%d*) sec cast",
		["Instant"] = "Instant",
		["Attack Speed"] = "Attack Speed",
	}
	
	-- 技能等级 by 武藤纯子酱 2025.12.18
	CleveRoids.Localized.SpellRanks = {
		["Rank "]  = "Rank ",
		["Rank 1"] = "Rank 1",
		["Rank 2"] = "Rank 2",
	}
	
	-- 附魔 by 武藤纯子酱 2026.1.9
	CleveRoids.Localized.Enchantment = {
		["%("] 			= "%(",
		[" min%)"] 		= " min%)",
		[" sec%)"] 			= " sec%)",
		[" charge"] 	= " charge",
	}	
elseif CleveRoids.Locale == "zhCN" then
    CleveRoids.Localized.Shield     = "盾牌"
    CleveRoids.Localized.Bow        = "弓"
    CleveRoids.Localized.Crossbow   = "弩"
    CleveRoids.Localized.Gun        = "枪械"
    CleveRoids.Localized.Thrown     = "投掷武器"
    CleveRoids.Localized.Wand       = "魔杖"
    CleveRoids.Localized.Sword      = "剑"
    CleveRoids.Localized.Staff      = "法杖"
    CleveRoids.Localized.Polearm    = "长柄武器"
    CleveRoids.Localized.Mace       = "锤"
    CleveRoids.Localized.FistWeapon = "拳套"
    CleveRoids.Localized.Dagger     = "匕首"
    CleveRoids.Localized.Axe        = "斧"

    CleveRoids.Localized.Attack    = "攻击"
    CleveRoids.Localized.AutoShot  = "自动射击"
    CleveRoids.Localized.Shoot     = "射击"
    CleveRoids.Localized.PetDismissSpell = "解散野兽" -- 宠物技能名：/petdismiss 经此技能解散野兽（宠物动作条无该按钮时兜底 CastSpellByName）by 武藤纯子酱 2026.9.3
    CleveRoids.Localized.SpellRank = "%(等级 %d+%)"
    CleveRoids.Localized.SpellRank2 = "%(等级%s+(%d+)%)"

    CleveRoids.Localized.CreatureTypes = {
        ["Beast"]         = "野兽",
        ["Critter"]       = "小动物",
        ["Demon"]         = "恶魔",
        ["Dragonkin"]     = "龙类",
        ["Elemental"]     = "元素生物",
        ["Giant"]         = "巨人",
        ["Humanoid"]      = "人型生物",
        ["Mechanical"]    = "机械",
        ["Not Specified"] = "未指定",
        ["Not specified"] = "未指定", -- 别名：兼容大小写差异 by 武藤纯子酱 2026.9.11
        ["Totem"]         = "图腾",
        ["Undead"]        = "亡灵",
    }

    CleveRoids.Localized.Spells = {
        ["Shadowform"]      = "暗影形态",
        ["Stealth"]         = "潜行",
        ["Prowl"]           = "潜行",
        ["Shadowmeld"]      = "影遁",
        ["Revenge"]         = "复仇",
        ["Overpower"]       = "压制",
        ["Riposte"]         = "还击",
        ["Surprise Attack"] = "突袭",
        ["Lacerate"]        = "割伤", -- 修复翻译 by 武藤纯子酱 2025.11.27
        ["Baited Shot"]     = "诱饵射击",
        ["Counterattack"]   = "反击",
        ["Arcane Surge"]    = "奥术涌动",
		["Aquatic Form"]    = "水栖形态", -- 增加德鲁伊技能：水栖形态 by 武藤纯子酱 2025.11.27
		["Rupture"]		    = "割裂", -- 增加盗贼技能：割裂 by 武藤纯子酱 2025.12.1
		["Kidney Shot"]		= "肾击", -- 增加盗贼技能：肾击 by 武藤纯子酱 2025.12.1
		["Rip"]				= "撕扯", -- 增加德鲁伊技能：撕扯 by 武藤纯子酱 2025.12.1
		["Rake"]			= "扫击", -- 增加德鲁伊技能：扫击 by 武藤纯子酱 2025.12.1
		["Pounce"]			= "突袭", -- 增加德鲁伊技能：突袭 by 武藤纯子酱 2025.12.2
		["Garrote"]			= "绞喉", -- 增加盗贼技能：绞喉 by 武藤纯子酱 2025.12.2
		["Rend"] 			= "撕裂",  -- 增加战士技能：撕裂 by 武藤纯子酱 2025.12.2
		["Deep Wound"] 		= "重伤",  -- 增加战士技能：重伤 by 武藤纯子酱 2025.12.2
		["Deep Wounds"] 	= "重伤",  -- 增加战士技能：重伤 by 武藤纯子酱 2025.12.30
		["Hemorrhage"]		= "出血", -- 增加盗贼技能：出血 by 武藤纯子酱 2025.12.2
		["Polymorph"]		= "变形术", -- 增加法师技能：变形术 by 武藤纯子酱 2025.12.2
		["Mana Burn"]		= "法力燃烧", -- 增加牧师技能：法力燃烧 by 武藤纯子酱 2025.12.2
		["Ignite"] 			= "点燃", -- 增加法师技能：点燃 by 武藤纯子酱 2025.12.2
		["Immolat"] 		= "献祭", -- 增加术士技能：献祭 by 武藤纯子酱 2025.12.2
		["Immolate"] 		= "献祭", -- 别名：正确拼写，兼容 enUS 键名 by 武藤纯子酱 2026.9.11
		["Scorch"] 			= "灼烧", -- 增加法师技能：灼烧 by 武藤纯子酱 2025.12.2
		["Pyroblast"]		= "炎爆术", -- 增加法师技能：炎爆术 by 武藤纯子酱 2025.12.2
		["Combustion"]		= "燃烧", -- 增加术士技能：燃烧 by 武藤纯子酱 2025.12.2
		["Blizzard"]		= "暴风雪", -- 增加法师技能：暴风雪 by 武藤纯子酱 2025.12.2
		["Freeze"]			= "冰冻术", -- 增加技能：冰冻术 by 武藤纯子酱 2025.12.2
		["Wrath"]			= "愤怒", -- 增加德鲁伊技能：愤怒 by 武藤纯子酱 2025.12.2
		["Heroic Strike"]	= "英勇打击", -- 增加战士技能：英勇打击 by 武藤纯子酱 2026.1.4
		["Cleave"]			= "顺劈斩", -- 增加战士技能：顺劈斩 by 武藤纯子酱 2026.1.4
		["Maul"]			= "槌击", -- 增加德鲁伊技能：槌击 by 武藤纯子酱 2026.1.4
		["Slam"]			= "猛击", -- 增加战士技能：猛击 by 武藤纯子酱 2026.1.4
		["Raptor Strike"]	= "猛禽一击", -- 增加猎人技能：猛禽一击 by 武藤纯子酱 2026.1.4
		["Mongoose Bite"]	= "猫鼬撕咬", -- 增加猎人技能：猫鼬撕咬 by 武藤纯子酱 2026.1.4
		["Arcane Missiles"]	= "奥术飞弹", -- 增加法师技能：奥术飞弹 by 武藤纯子酱 2026.1.4
		["Drain Life"]		= "吸取生命", -- 增加术士技能：吸取生命 by 武藤纯子酱 2026.1.4
		["Drain Mana"]		= "吸取法力", -- 增加术士技能：吸取法力 by 武藤纯子酱 2026.1.4
		["Drain Soul"]		= "吸取灵魂", -- 增加术士技能：吸取灵魂 by 武藤纯子酱 2026.1.4
		["Evocation"]		= "唤醒", -- 增加法师技能：唤醒 by 武藤纯子酱 2026.1.4
		["Health Funnel"]	= "生命通道", -- 增加术士技能：生命通道 by 武藤纯子酱 2026.1.4
		["Hellfire"]		= "地狱烈焰", -- 增加术士技能：地狱烈焰 by 武藤纯子酱 2026.1.4
		["Hurricane"]		= "飓风", -- 增加德鲁伊技能：飓风 by 武藤纯子酱 2026.1.4
		["Mind Flay"]		= "精神鞭笞", -- 增加牧师技能：精神鞭笞 by 武藤纯子酱 2026.1.4
		["Rain of Fire"]	= "火焰之雨", -- 增加术士技能：火焰之雨 by 武藤纯子酱 2026.1.4
		["Tranquility"]		= "宁静", -- 增加德鲁伊技能：宁静 by 武藤纯子酱 2026.1.4
		["Volley"]			= "乱射", -- 增加猎人技能：乱射 by 武藤纯子酱 2026.1.4
		["Mind Soothe"]		= "心灵安抚", -- 增加牧师技能：心灵安抚 by 武藤纯子酱 2026.1.4
		["Mind Vision"]		= "心灵视界", -- 增加牧师技能：心灵视界 by 武藤纯子酱 2026.1.4
		["First Aid"]		= "急救", -- 增加通用技能：急救 by 武藤纯子酱 2026.1.4
		["Hamstring"]		= "断筋", -- 增加战士技能：断筋 by 武藤纯子酱 2026.1.4
		["Taunt"]			= "嘲讽", -- 增加战士技能：嘲讽 by 武藤纯子酱 2026.1.4
		["Growl"]			= "低吼", -- 增加猎人宠物技能：低吼 by 武藤纯子酱 2026.1.4
		["Mocking Blow"]	= "惩戒痛击", -- 增加战士技能：惩戒痛击 by 武藤纯子酱 2026.1.4
		["Hand of Reckoning"]	= "清算之手", -- 增加圣骑士技能：清算之手 by 武藤纯子酱 2026.1.4
		["Deadly Poison"]	= "致命毒药", -- 增加盗贼毒药：致命毒药 by 武藤纯子酱 2026.1.4
		["Crippling Poison"]= "致残毒药", -- 增加盗贼毒药：致残毒药 by 武藤纯子酱 2026.1.4
		["Wound Poison"]	= "致伤毒药", -- 增加盗贼毒药：致伤毒药 by 武藤纯子酱 2026.1.4
		["Mind-numbing Poison"]= "麻痹毒药", -- 增加盗贼毒药：麻痹毒药 by 武藤纯子酱 2026.1.4
		["Thunderfury"]		= "雷霆之怒", -- 增加风剑特效：雷霆之怒 by 武藤纯子酱 2026.1.4
		["Thunderfury Slow"]= "雷霆之怒", -- 增加风剑特效：雷霆之怒 by 武藤纯子酱 2026.1.4
		["Master Strike"]	= "特效打击", -- 增加特效打击 by 武藤纯子酱 2026.1.16
		["Nightfall"]		= "法术易伤", -- 增加夜幕法术易伤 by 武藤纯子酱 2026.2.1
		
		-- Druid
		["Faerie Fire"] 			= "精灵之火", -- 增加德鲁伊技能：精灵之火 by 武藤纯子酱 2025.12.2
		["Moonfire"] 				= "月火术",  -- 增加德鲁伊技能：月火术 by 武藤纯子酱 2025.12.2
		["Insect Swarm"] 			= "虫群", -- 增加德鲁伊技能：虫群 by 武藤纯子酱 2025.12.2
		["Abolish Poison"] 			= "驱毒术", -- 增加德鲁伊技能：驱毒术 by 武藤纯子酱 2025.12.2
		["Remove Curse"] 			= "解除诅咒", -- 增加德鲁伊技能：解除诅咒 by 武藤纯子酱 2025.12.2
		["Starfire"]				= "星火术", -- 增加德鲁伊技能：星火术 by 武藤纯子酱 2025.12.2
		["Thorns"]					= "荆棘术", -- 增加德鲁伊技能：荆棘术 by 武藤纯子酱 2025.12.2
		["Faerie Fire (Feral)"] 	= "精灵之火（野性）", -- 增加德鲁伊技能：精灵之火（野性） by 武藤纯子酱 2025.12.29
		["Faerie Fire (Bear)"] 		= "精灵之火（熊）", -- 增加德鲁伊技能：精灵之火（熊） by 武藤纯子酱 2025.12.29
		["Pounce Bleed"] 			= "血袭", -- 增加德鲁伊技能：血袭 by 武藤纯子酱 2025.12.29
		["Demoralizing Roar"] 		= "挫志咆哮", -- 增加德鲁伊技能：挫志咆哮 by 武藤纯子酱 2026.2.1

		-- Mage
		["Amplify Magic"] 			= "魔法增效", -- 增加法师技能：魔法增效 by 武藤纯子酱 2025.12.2
		["Dampen Magic"] 			= "魔法抑制", -- 增加法师技能：魔法抑制 by 武藤纯子酱 2025.12.2
		["Remove Lesser Curse"] 	= "解除次级诅咒", -- 增加法师技能：解除次级诅咒袭 by 武藤纯子酱 2025.12.2
		["Slow Fall"] 				= "缓落术", -- 增加法师技能：缓落术 by 武藤纯子酱 2025.12.2
		["Detect Magic"] 			= "侦测魔法", -- 增加法师技能：侦测魔法 by 武藤纯子酱 2025.12.2
		["Improved Scorch"]			= "火焰易伤", -- 增加火焰易伤 by 武藤纯子酱 2026.2.1
		["Winter's Chill"]			= "深冬之寒", -- 增加深冬之寒 by 武藤纯子酱 2026.2.1

		-- Priest
		["Dispel Magic"] 			= "驱散魔法", -- 增加牧师技能：驱散魔法 by 武藤纯子酱 2025.12.2
		["Cure Disease"] 			= "祛病术", -- 增加牧师技能：祛病术 by 武藤纯子酱 2025.12.2
		["Abolish Disease"] 		= "驱除疾病", -- 增加牧师技能：驱除疾病 by 武藤纯子酱 2025.12.2
		["Power Word: Fortitude"] 	= "真言术：韧", -- 增加牧师技能：真言术：韧 by 武藤纯子酱 2025.12.2
		["Power Word: Shield"] 		= "真言术：盾", -- 增加牧师技能：真言术：盾 by 武藤纯子酱 2025.12.2
		["Divine Spirit"] 			= "神圣之灵", -- 增加牧师技能：神圣之灵 by 武藤纯子酱 2025.12.2
		["Fear Ward"] 				= "防护恐惧结界", -- 增加牧师技能：防护恐惧结界 by 武藤纯子酱 2025.12.2
		["Resurrection"] 			= "复活术", -- 增加牧师技能：复活术 by 武藤纯子酱 2025.12.2
		["Smite"]					= "惩击", -- 增加牧师技能：惩击 by 武藤纯子酱 2025.12.2
		["Shadow Weaving"]			= "暗影之波", -- 增加牧师技能：暗影之波 by 武藤纯子酱 2026.2.1

		-- Paladin
		["Cleanse"] 				= "清洁术", -- 增加圣骑士技能：清洁术 by 武藤纯子酱 2025.12.2
		["Purify"] 					= "纯净术", -- 增加圣骑士技能：纯净术 by 武藤纯子酱 2025.12.2
		["Divine Protection"]		= "圣佑术", -- 增加圣骑士技能：圣佑术 by 武藤纯子酱 2025.12.2
		["Divine Shield"] 			= "圣盾术", -- 增加圣骑士技能：圣盾术 by 武藤纯子酱 2025.12.2
		["Blessing of Protection"] 	= "保护祝福", -- 增加圣骑士技能：保护祝福 by 武藤纯子酱 2025.12.2
		["Blessing of Freedom"] 	= "自由祝福", -- 增加圣骑士技能：自由祝福 by 武藤纯子酱 2025.12.2
		["Blessing of Sacrifice"] 	= "牺牲祝福", -- 增加圣骑士技能：牺牲祝福 by 武藤纯子酱 2025.12.2
		["Redemption"] 				= "救赎", -- 增加圣骑士技能：救赎 by 武藤纯子酱 2025.12.2
		["Exorcism"]				= "驱邪术", -- 增加圣骑士技能：驱邪术 by 武藤纯子酱 2025.12.2
		["Consecrat"]				= "奉献", -- 增加圣骑士技能：奉献 by 武藤纯子酱 2025.12.2
		["Consecration"]			= "奉献", -- 别名：正确拼写，兼容 enUS 键名 by 武藤纯子酱 2026.9.11
		["Hammer of Wrath"]			= "愤怒之锤", -- 增加圣骑士技能：愤怒之锤 by 武藤纯子酱 2025.12.2
		["Judgement of Justice"]	= "正义审判", -- 增加圣骑士技能：正义审判 by 武藤纯子酱 2025.12.3
		["Judgement of Light"]		= "光明审判", -- 增加圣骑士技能：光明审判 by 武藤纯子酱 2025.12.3
		["Judgement of Wisdom"]		= "智慧审判", -- 增加圣骑士技能：智慧审判 by 武藤纯子酱 2025.12.3
		["Judgement of the Crusader"] = "十字军审判", -- 增加圣骑士技能：十字军审判 by 武藤纯子酱 2025.12.3
		["Judgement of Righteousness"]= "正义审判", -- 增加圣骑士技能：正义审判 by 武藤纯子酱 2026.1.4
		["Judgement of Command"] 	= "命令审判", -- 增加圣骑士技能：命令审判 by 武藤纯子酱 2026.1.4
		["Judgement"] 				= "审判", -- 增加圣骑士技能：审判 by 武藤纯子酱 2026.1.4

		-- Warlock
		["Banish"] 					= "放逐术", -- 增加术士技能：放逐术 by 武藤纯子酱 2025.12.2
		["Curse of Weakness"] 		= "虚弱诅咒", -- 增加术士技能：虚弱诅咒 by 武藤纯子酱 2025.12.2
		["Curse of Recklessness"] 	= "鲁莽诅咒", -- 增加术士技能：鲁莽诅咒 by 武藤纯子酱 2025.12.2
		["Curse of Tongues"] 		= "语言诅咒", -- 增加术士技能：语言诅咒 by 武藤纯子酱 2025.12.2
		["Amplify Curse"] 			= "诅咒增幅", -- 增加术士技能：诅咒增幅 by 武藤纯子酱 2025.12.2
		["Death Coil"] 				= "死亡缠绕",  -- 增加术士技能：死亡缠绕 by 武藤纯子酱 2025.12.2
		["Corruption"] 				= "腐蚀术",  -- 增加术士技能：腐蚀术 by 武藤纯子酱 2025.12.2
		["Curse of the Elements"]	= "元素诅咒", -- 增加术士技能：元素诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Shadow"]			= "暗影诅咒", -- 增加术士技能：暗影诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Idiocy"]			= "痴呆诅咒", -- 增加术士技能：痴呆诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Agony"]			= "痛苦诅咒", -- 增加术士技能：痛苦诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Doom"]			= "厄运诅咒", -- 增加术士技能：厄运诅咒 by 武藤纯子酱 2026.2.1
		["Curse of Exhaustion"]		= "疲劳诅咒", -- 增加术士技能：疲劳诅咒 by 武藤纯子酱 2026.2.1
		["Shadow Vulnerability"]	= "暗影易伤", -- 增加术士技能：暗影易伤 by 武藤纯子酱 2026.2.1
		
		-- Shaman
		["Cure Poison"] 			= "消毒术", -- 增加萨满技能：消毒术 by 武藤纯子酱 2025.12.2
		["Cure Disease"] 			= "祛病术", -- 增加萨满技能：祛病术 by 武藤纯子酱 2025.12.2
		["Purge"] 					= "净化术", -- 增加萨满技能：净化术 by 武藤纯子酱 2025.12.2
		["Ancestral Spirit"] 		= "先祖之魂", -- 增加萨满技能：先祖之魂 by 武藤纯子酱 2025.12.2
		["Molten Blast"] 			= "熔岩爆裂", -- 增加萨满技能：熔岩爆裂 by 武藤纯子酱 2025.12.29	
		["Stormstrike"] 			= "风暴打击", -- 增加萨满技能：风暴打击 by 武藤纯子酱 2026.2.1

		-- Hunter
		["Aspect of the Hawk"] 		= "雄鹰守护", -- 增加猎人技能：雄鹰守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Monkey"] 	= "灵猴守护", -- 增加猎人技能：灵猴守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Cheetah"] 	= "猎豹守护", -- 增加猎人技能：猎豹守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Pack"] 		= "豹群守护", -- 增加猎人技能：豹群守护 by 武藤纯子酱 2025.12.2
		["Aspect of the Wild"] 		= "野性守护", -- 增加猎人技能：野性守护 by 武藤纯子酱 2025.12.2
		["Hunter's Mark"] 			= "猎人印记", -- 增加猎人技能：猎人印记 by 武藤纯子酱 2026.2.1
		["Scorpid Sting"] 			= "毒蝎钉刺", -- 增加猎人技能：毒蝎钉刺 by 武藤纯子酱 2026.2.1

		-- Warrior
		["Sunder Armor"] 			= "破甲攻击", -- 增加战士技能：破甲攻击 by 武藤纯子酱 2026.2.1
		["Demoralizing Shout"] 		= "挫志怒吼", -- 增加战士技能：挫志怒吼 by 武藤纯子酱 2026.2.1
		
		-- Rogue
		["Expose Armor"] 			= "破甲", -- 增加盗贼技能：破甲 by 武藤纯子酱 2026.2.1
		["Slice and Dice"] 			= "切割", -- 增加盗贼技能：切割 by 武藤纯子酱 2026.2.1
    }

    CleveRoids.Localized.ItemTypes = {
        ["Consumable"]  = "消耗品",
        ["Reagent"]    = "材料",
        ["Projectile"] = "弹药",
        ["Trade Goods"] = "商品",
    }
	-- 增加团队标记 by 武藤纯子酱 2025.11.27	
    CleveRoids.Localized.RaidTargetIndex = {
        [1]  = "星星",
        [2]     = "大饼",
        [3]  = "紫菱",
        [4] = "三角",
        [5]  = "月亮",
        [6]     = "方块",
        [7]  = "红叉",
        [8] = "骷髅",		
    }
	
	-- 增加战斗日志关键词翻译 by 武藤纯子酱 2025.12.2
    CleveRoids.Localized.CombatLogs = {
        ["hit"]			= "击中",
        ["crit"]		= "致命一击",
		["fades from"]	= "消失",
		["you"]			= "你",
		["resist"]		= "抵抗",
		["miss"]		= "没有击中",
		["dodge"]		= "躲闪",
		["parry"]		= "招架",
		["block"]		= "格挡",
		["immune"]		= "免疫",
		["failed"]		= "失败",
		["resisted%)"]	= "抵抗）",
        ["^You hit"]	= "^你击中",
        ["^You crit"]	= "你对(.+)造成(.+)的致命一击伤害。",
        ["Fire damage"]	= "火焰伤害",
        ["afflicted by"]= "效果的影响",
        ["^(.-)%s+is afflicted by%s+(.+)"]= "^(.-)受到了(.-)效果的影响（(%d+)）。",
		["reflect"]		= "反弹",
		["evade"]		= "闪避",
		["(.+) fades from (.+)"]= "(.+)效果从(.+)身上消失",
    }	

	-- 增加战斗日志施法失败相关文字翻译 by 武藤纯子酱 2025.12.2
    CleveRoids.Localized.SpellFailedTests = {
		["resisted"]	=	"你的(.+)被(.+)抵抗了",
		["missed"]		=	"你的(.+)没有击中(.+)",
		["parried"]		=	"你的(.+)被(.+)招架了",
		["dodged"]		=	"你的(.+)被(.+)躲闪过去了",
		["blocked"]		=	"你的(.+)被(.+)格挡了",
		["immune"]		=	"你的(.+)施放失败。(.+)对此免疫",
		["fades"]		=	"(.+)效果从(.+)身上消失",
		["immune_2"]	=	"你的(.+)施放失败。(.+)对此免疫",
		["immune_3"]	=	"你的(.+)施放失败。(.+)对此免疫",
		["immune_4"]	=	"^(.-)对此免疫",
		["immune_5"]	=	"^(.-)对此免疫",
		["immune_6"]	=	"免疫",
		["immune_7"]	=	"免疫",
		["resisted_2"]	=	"^(.+)抵抗了你的(.-)",
		["reflect_1"]	=	"你的(.+)被(.+)反弹回来。",
		["reflect_2"]	=	"你的(.+)被(.+)反弹回来。",
		["reflect_3"]	=	"你的(.+)被(.+)反弹回来。",
		["reflect_4"]	=	"被(.+)反弹回来。",
		["evade_1"]		=	"你的(.+)被(.+)闪避过去了。",
		["evade_2"]		=	"你的(.+)被(.+)闪避过去了。",
		["evade_3"]		=	"你的(.+)被(.+)闪避过去了。",
		["evade_4"]		=	"被(.+)闪避过去了。",
    }
	
	-- 增加天赋相关文字翻译 by 武藤纯子酱 2025.12.2
	CleveRoids.Localized.talentModifiers = {
		["Taste for Blood"]					=	"血腥气息",
		["Improved Gouge"]					=	"强化凿击",
		["Improved Shadow Word: Pain"]		=	"强化暗言术：痛",
		["Brutal Impact"]					=	"野蛮冲撞",
		["Booming Voice"]					=	"震耳噪音",
	}
	
	-- 伤害类型相关文字翻译 by 武藤纯子酱 2025.12.2
	CleveRoids.Localized.SpellSchool = {
		["physical"]	=	"物理",
		["holy"]		=	"神圣",
		["fire"]		=	"火焰",
		["nature"]		=	"自然",
		["frost"]		=	"冰霜",
		["shadow"]		=	"暗影",
		["arcane"]		=	"奥术",
		["bleed"]		=	"流血",
		["ice"]			=	"冰",
		["poison"]		=	"毒药",
		["flame"]		=	"烈焰",
		["dark"]		=	"黑暗",
		["divine"]		=	"神圣",
		["^fire"]		=	"火",
		[" fire"]		=	"火",
		["chill"]		=	"寒",
		["sting"]		=	"钉刺",
		["curse"]		=	"诅咒",
		["drain"]		=	"吸取",
		["vampir"]		=	"吸血鬼",
		["affliction"]	=	"痛",
		["judgment"]	=	"审判",
	}
	
	-- 技能描述中获取持续时间 by 武藤纯子酱 2025.12.11
	CleveRoids.Localized.SpellDuration = {
		["for"] = "持续(%d+%.?%d*)秒",
		["over"] = "在(%d+%.?%d*)秒",
		["per"] = "每(%d+%.?%d*)秒",
		["sec"] = "(%d+%.?%d*)秒",
		["(%d+%.?%d*) sec cast"] = "(%d+%.?%d*)秒施法时间",
		["Instant"] = "瞬发法术",
		["Attack Speed"] = "攻击速度",
	}
	
	-- 技能等级 by 武藤纯子酱 2025.12.18
	CleveRoids.Localized.SpellRanks = {
		["Rank "]  = "等级 ",
		["Rank 1"] = "等级 1",
		["Rank 2"] = "等级 2",
	}
	
	-- 附魔 by 武藤纯子酱 2026.1.9
	CleveRoids.Localized.Enchantment = {
		["%("] 			= "（",
		[" min%)"] 		= "分钟）",
		[" sec%)"] 			= "秒）",
		[" charge"] 	= "(%d+)次",
	}
end

_G["CleveRoids"] = CleveRoids
