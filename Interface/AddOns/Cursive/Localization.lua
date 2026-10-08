local L = AceLibrary("AceLocale-2.2"):new("Cursive")

L:RegisterTranslations("enUS", function()
	return {
		["|cffffcc00Cursive:|cffffaaaa Commands:"] = true,
		["|cffffcc00Priority choices:"] = true,
		["|cffffcc00Options (separate with ,):"] = true,
		["Display text warnings when a curse fails to cast."] = true,
		["Play a sound when a curse is resisted."] = true,
		["Play a sound when a curse is about to expire."] = true,
		["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."] = true,
		["Minimum HP for a target to be considered.  Example usage minhp=10000. "] = true,
		["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."] = true,
		["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."] = true,
		["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."] = true,
		["For Warlocks with the Malediction talent: when checking if Curse of Recklessness, Curse of the Elements, or Curse of Shadow is already on a target, check for Curse of Agony instead. Default is 1 (enabled). Set malediction=0 to disable and check for the original curse."] = true,
		["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."] = true,
		["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."] = true,
		["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."] = true,
		["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."] = true,
		["Only choose mobs tagged by other players when choosing target for multicurse.  Does not affect 'curse' command."] = true,
		["/cursive curse <spellName:str>|<guid?:str>|<options?:List<str>>: Casts spell if not already on target/guid"] = true,
		["/cursive multicurse <spellName:str>|<priority?:str>|<options?:List<str>>: Picks target based on priority and casts spell if not already on target"] = true,
		["/cursive target <spellName:str>|<priority?:str>|<options?:List<str>>: Targets unit based on priority if spell in range and not already on target"] = true,
		["Target with the highest HP."] = true,
		["Target with the lowest HP."] = true,
		["Target with the highest raid mark."] = true,
		["Target with the highest raid mark with Cross set to -1 and Skull set to -2 (Square highest prio at 6)."] = true,
		["Target with the lowest raid mark."] = true,
		["Target with the highest HP and raid mark."] = true,
		["Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE mark prio."] = true,
		["Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK mark prio."] = true,
		["|cffffcc00Cursive:|cffffaaaa Couldn't find a target to curse."] = true,
		["curse_duration_format"] = ".*over ([%d.]+) sec.",
		["Shared Debuffs"] = true,
		["|cffffcc00Cursive:|cffffaaaa Unknown command."] = true,
		--新增commands条件 by 武藤纯子酱 2025.8.28
		["Target BOSS with the highest raid mark."] = true,
		["Target BOSS with the highest HP."] = true,
		["Maximum HP for a target to be considered. Example usage maxhp=50000."] = true,
		["Maximum health percentage threshold. Example: maxhppercent=50 (Targets with HP% ≤ 50%%)"] = true,
		["Minimum health percentage threshold. Example: minhppercent=50 (Targets with HP% ≥ 50%%)"] = true,
		["Filter boss-type targets only"] = true,
		["Target distance. Without UnitXP, 1/2/3 = 28/11.11/9.9 yards; with UnitXP, the value is used as yards."] = true,
		["Filter targets with specific buff IDs. Example: buffids=789"] = true,
		["Filter targets with specific buff name. Example: buffnames='Power Word: Shield'"] = true,		
		["Filter units is behind."] = true,

		-- curses
		["(.+) fades from (.+)"] = true,
		["Your (.+) was resisted by (.+)"] = true,
		["Your (.+) missed (.+)"] = true,
		["Your (.+) is parried by (.+)"] = true,
		["Your (.+) fail.+\. (.+) is immune"] = true,
		["Your (.+) was blocked by (.+)"] = true,
		["Your (.+) was dodged by (.+)"] = true,
		["Your Molten Blast(.+)for .+ Fire damage"] = true,
		-- 新增 by 武藤纯子酱 2025.8.28
		["%s is afflicted by %s (%d+)."] = true,
		["%s gains %s (%d+)."] = true,

		-- global
		["|cffffcc00Cursive:|cffffaaaa Couldn't detect SuperWoW."] = true,
		["|cffffcc00Cursive:|cffffaaaa Loaded.  /cursive for commands and minimap icon for options."] = true,


		-- settings
		["Cursive"] = true,
		["Show Targeting Arrow"] = true,
		["Show Raid Icons"] = true,
		["Show Health Bar"] = true,
		["Show Unit Name"] = true,
		["Health Bar/Unit Name Width"] = true,
		["Health Bar/Unit Name Height"] = true,
		["Health Bar Texture"] = true,
		["Health Bar Texture Desc"] = "Full path to the texture file like the default: Interface\\TargetingFrame\\UI-StatusBar",
		["Raid Icon Size"] = true,
		["Curse Icon Size"] = true,
		["Spacing"] = true,
		["Name/Hp Text Size"] = true,
		["Curse Timer Text Size"] = true,
		["Scale"] = true,
		["In Combat"] = true,
		["Player"] = true,
		["Player Desc"] = "Only show player units",
		["Not Player"] = true,
		["Not Player Desc"] = "Only show NON player units",
		["Hostile"] = true,
		["Attackable"] = true,
		["Within 28 Range"] = true,
		["Within 45 Range"] = true,
		["Has Raid Mark"] = true,
		["Has Curse"] = true,
		["Only show units you have cursed"] = true,
		["Enabled"] = true,
		["Enable/Disable Cursive"] = true,
		["Show Title"] = true,
		["Show the title of the frame"] = true,
		["Allow clickthrough"] = true,
		["This will allow you to click through the frame to target mobs behind it, but prevents dragging the frame."] = true,
		["Show Frame Background"] = true,
		["Toggle the frame background to help with positioning"] = true,
		["Reset Frame"] = true,
		["Move the frame back to the default position"] = true,
		["Bar Display Settings"] = true,
		["Mob filters"] = true,
		["Target and Raid Marks always shown"] = true,
		["Max Curses"] = true,
		["Max Rows"] = true,
		["Max Columns"] = true,
		["Curse Ordering"] = true,
		["Decimal Duration"] = true,
		["Decimal Duration Desc"] = "Show 1 decimal place for curse durations when less than 10 seconds remaining.",
		["Order applied"] = true,
		["Expiring soonest -> latest"] = true,
		["Expiring latest -> soonest"] = true,
		["Order applied"] = true,
		["Expiring soonest -> latest"] = true,
		["Expiring latest -> soonest"] = true,
		["Not ignored"] = true,
		["Ignored Mobs List (Enter to save)"] = true,
		["Ignored Mobs Desc"] = "Comma separated list of strings to ignore if found in the unit name. Tokens shorter than 3 characters are ignored. If you use any of these regex characters (*+%?) it will do a regex search otherwise it will do a plain text search. So both Rift-Lost and Rift%-Lost should work.",
		["Shared Faerie Fire"] = true,
		["This will show other player's Faerie Fires and avoid trying to cast Faerie Fire on those mobs"] = true,
		--新增 by 武藤纯子酱 2025.8.28
		["Always Show Current Target"] = true,
		["Always show current target at the bottom of the mob list if it is not already shown"] = true,	
		["Distance Filter"] = true,
		["Set maximum target distance (1-250 yards)"] = true,
		["InSight Filter"] = true,
		["Only display units ‌within the visible range of sight"] = true,
		["Max Health Filter"] = true,
		["Set maximum target heatlth (0-1000000)"] = true,	
		["Show Unit Distance"] = true,		
		["Show Unit Health Percent"] = true,	
		 -- 新增中文支持 by 武藤纯子酱 2025.8.29
		["Invert Bar Display"] = true,
		["Show sections in order 3-2-1 and reverse element order in sections 1 and 3"] = true,
		["Expand Bars Upwards"] = true,
		["Make bars expand upwards instead of downwards"] = true,
		["Section Display"] = true,
		["Size & Appearance"] = true,
		-- 新增 共享DEBUFF by 武藤纯子酱 2025.9.10
		["Shared Sunder Armor"] = true,
		["This will show other player's Sunder Armor and avoid trying to cast Sunder Armor on those mobs"] = true,
		["Shared Expose Armor"] = true,
		["This will show other player's Expose Armor and avoid trying to cast Expose Armor on those mobs"] = true,
		["Shared Hunter's Mark"] = true,
		["This will show other player's Hunter's Mark and avoid trying to cast Hunter's Mark on those mobs"] = true,
		["Shared Curse of Recklessness"] = true,
		["This will show other player's Curse of Recklessness and avoid trying to cast it on those mobs"] = true,
		["Shared Curse of the Elements"] = true,
		["This will show other player's Curse of the Elements and avoid trying to cast it on those mobs"] = true,
		["Shared Curse of Shadow"] = true,
		["This will show other player's Curse of Shadow and avoid trying to cast it on those mobs"] = true,
		-- 新增放逐术检查 by 武藤纯子酱 2026.3.17
		["Shared Banish"] = true,
		["This will show other player's Banish and avoid trying to cast Banish on those mobs"] = true,
		-- 新增 目标名字显示相关 by 武藤纯子酱 2025.12.9
		["Show Target Name"] = true,
		["Show the name of the unit's current target"] = true,
		["Target Name Width"] = true,
		["Width of the target name column"] = true,
		-- 新增 目标名字背景 by 武藤纯子酱 2026.9.3
		["Target Name Background"] = true,
		["Show a gray semi-transparent background with black border behind the target name column"] = true,
		-- 新增 按距离排序 / 满槽强调 by 武藤纯子酱 2026.9.10
		["Sort By Distance"] = true,
		["Sort all bars by distance from nearest to farthest"] = true,
		["Distance Sort Mode"] = true,
		["Choose to sort bars from nearest to farthest or farthest to nearest"] = true,
		["Nearest -> Farthest"] = true,
		["Farthest -> Nearest"] = true,
		["Emphasize Full Buff/Debuff Slots"] = true,
		["Emphasize the bar when the unit's buff and debuff slots are both full"] = true,
		["Full Slots Emphasis Style"] = true,
		["How to emphasize a bar when buff/debuff slots are full"] = true,
		["Border"] = true,
		["Health Bar"] = true,
		["Fade"] = true,

		-- spells
		["Rank"] = true,
		["Rank 1"] = true,
		["Rank 2"] = true,
		["Rank 3"] = true,
		["Rank 4"] = true,
		--新增 by 武藤纯子酱 2025.8.28
		["Rank 5"] = true,
		["Rank 6"] = true,
		["Rank 7"] = true,
		["Rank 8"] = true,
		["Rank 9"] = true,
		["Rank 10"] = true,
		["Rank 11"] = true,
		["Rank 12"] = true,
		["Rank 13"] = true,
		["Rank 14"] = true,
		["Rank 15"] = true,	

		-- druid
		["entangling roots"] = true,
		["sleep"] = true,
		["faerie fire"] = true,
		--["faerie fire (bear)()"] = true,
		["faerie fire (feral)"] = true, -- 修复翻译 by 武藤纯子酱 2025.10.2
		["hibernate"] = true,
		["insect swarm"] = true,
		["moonfire"] = true,
		["rake"] = true,
		["rip"] = true,
		["soothe animal"] = true,
		["bash"] = true,
		["Maim"] = true,
		["demoralizing roar"] = true,
		["challenging roar"] = true,
		["ferocious bite"] = true,
		["pounce bleed"] = true,

		-- hunter
		["scorpid sting"] = true,
		["serpent sting"] = true,
		["viper sting"] = true,
		["wing clip"] = true,
		["concussive shot"] = true,
		["wyvern sting"] = true,
		["counterattack"] = true,
		["hunter's mark"] = true,
		["freezing trap"] = true,
		["explosive trap effect"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["immolation trap effect"] = true,	-- 新增 by 武藤纯子酱 2025.8.28	

		-- mage
		["polymorph"] = true,
		["polymorph: cow"] = true,
		["polymorph: turtle"] = true,
		["polymorph: pig"] = true,
		["polymorph: rodent"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["Polymorph: Draenei Homunculus"] = true,	-- 新增 by 武藤纯子酱 2026.9.16
		["fire vulnerability"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["ignite"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["fire blast"] = true,	-- 新增 by 武藤纯子酱 2025.10.15
		["scorch"] = true,	-- 新增 by 武藤纯子酱 2025.10.15		

		-- priest
		["shackle undead"] = true,
		["mind soothe"] = true,
		["mind control"] = true,
		["devouring plague"] = true,
		["hex of weakness"] = true,
		["shadow word: pain"] = true,
		["vampiric embrace"] = true,
		["burning zeal"] = true,
		["holy fire"] = true,
		["mind flay"] = true, -- 新增 by 武藤纯子酱 2025.8.28	

		-- Paladin
		["turn undead"] = true,
		["hammer of justice"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["judgement of wisdom"] = true,	-- 新增 by 武藤纯子酱 2025.8.28
		["judgement of the crusader"] = true,	-- 新增 by 武藤纯子酱 2025.8.28	
		["judgement of justice"] = true,	-- 新增 by 武藤纯子酱 2025.8.28	
		["judgement of light"] = true,	-- 新增 by 武藤纯子酱 2025.8.28

		-- rogue
		["blind"] = true,
		["sap"] = true,
		["gouge"] = true,
		["rupture"] = true,
		["kidney shot"] = true,
		["expose armor"] = true,
		["garrote"] = true,
		["deadly poison"] = true,
		["deadly poison ii"] = true,
		["deadly poison iii"] = true,
		["deadly poison iv"] = true,
		["deadly poison v"] = true,
		["corrosive poison"] = true,
		["corrosive poison ii"] = true,
		["hemorrhage"] = true,
		["cheap shot"] = true,
		["mind-numbing poison"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["mind-numbing poison ii"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["mind-numbing poison iii"] = true, -- 新增 by 武藤纯子酱 2025.8.28	
		["crippling poison"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["crippling poison ii"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison ii"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison iii"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison iv"] = true, -- 新增 by 武藤纯子酱 2025.8.28

		-- shaman
		["flame shock"] = true,
		["molten blast"] = true,
		["frost shock"]  = true, -- 新增 by 武藤纯子酱 2025.8.28   
		["hex"]  = true, -- 新增 by 武藤纯子酱 2025.8.30

		-- warlock
		["conflagrate"] = true,
		["corruption"] = true,
		["curse of agony"] = true,
		["curse of doom"] = true,
		["curse of recklessness"] = true,
		["curse of shadow"] = true,
		["curse of the elements"] = true,
		["curse of tongues"] = true,
		["curse of weakness"] = true,
		["curse of exhaustion"] = true,
		["parasite of aln"] = true,
		["dark harvest"] = true,
		["immolate"] = true,
		["death coil"] = true,
		["banish"] = true,
		["siphon life"] = true,
		["fear"] = true,
		["seduction"] = true, -- 新增 by 武藤纯子酱 2025.8.30
		["spell lock"] = true, -- 新增 by 武藤纯子酱 2025.8.30

		-- warrior
		["rend"] = true,
		["mortal strike"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["sunder armor"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["counterattack"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["concussion blow"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["hamstring"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["disarm"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["thunderclap"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["demoralizing shout"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["mocking blow"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["intimidating shout"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["taunt"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["piercing howl"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["revenge stun"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["charge"] = true, -- 新增 by 武藤纯子酱 2025.8.28
		["intercept"] = true, -- 新增 by 武藤纯子酱 2025.8.28
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["|cffffcc00Cursive:|cffffaaaa Commands:"] = "|cffffcc00Cursive:|cffffaaaa 命令:",
		["|cffffcc00Priority choices:"] = "|cffffcc00优先级选择:",
		["|cffffcc00Options (separate with ,):"] = "|cffffcc00选项 (用半角逗号分隔):",
		["Display text warnings when a curse fails to cast."] = "当诅咒施放失败时显示文本警告.",
		["Play a sound when a curse is resisted."] = "当诅咒被抵抗时播放声音.",
		["Play a sound when a curse is about to expire."] = "当诅咒即将到期时播放声音.\n 详细使用说明及示例请查看readme文件",
		["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."] = "允许战斗外目标被多重诅咒。只有在单人游戏中才会考虑使用这个选项，以避免在副本中意外拉到怪物而造成困扰.",
		["Minimum HP for a target to be considered.  Example usage minhp=10000. "] = "目标考虑的最小生命值。例如：minhp=10000.",
		["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."] = "通过名称过滤目标。可以是部分匹配。如果没有找到匹配项，命令将不执行.",
		["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."] = "忽略已经在目标身上的指定法术ID。对于忽略已经有共享debuff的目标很有用.",
		["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."] = "忽略已经在目标身上的指定法术纹理。对于忽略已经有共享debuff的目标很有用.",
		["For Warlocks with the Malediction talent: when checking if Curse of Recklessness, Curse of the Elements, or Curse of Shadow is already on a target, check for Curse of Agony instead. Default is 1 (enabled). Set malediction=0 to disable and check for the original curse."] = "对于拥有诅咒天赋的术士：检查鲁莽诅咒、元素诅咒或暗影诅咒是否已在目标身上时，改为检查痛苦诅咒。默认为1（启用）。设置malediction=0可禁用并检查原始诅咒。",
		["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."] = "允许刷新诅咒的时间阈值。默认是0秒.例如：refreshtime=2",
		["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."] = "选择多重诅咒目标时总是优先当前目标。不影响‘诅咒’命令。",
		["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."] = "选择多重诅咒目标时忽略当前目标。不影响‘诅咒’命令。",
		["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."] = "选择多重诅咒目标时只选择玩家，忽略NPC。不影响‘诅咒’命令。",
		["Only choose mobs tagged by other players when choosing target for multicurse.  Does not affect 'curse' command."] = "选择多重诅咒目标时只选择被其他玩家标记过的怪物。不影响‘诅咒’命令。",
		["/cursive curse <spellName:str>|<guid?:str>|<options?:List<str>>: Casts spell if not already on target/guid"] = "/cursive curse <法术名称>|<目标ID>|<选项列表,用半角逗号分隔>: 如果目标/ID身上没有此法术，目标ID可以是以下内容(mouseover), (player), (pet), (party)(%d), (partypet)(%d), (raid)(%d+), (raidpet)(%d+), (target), (targettarget)",
		["/cursive multicurse <spellName:str>|<priority?:str>|<options?:List<str>>: Picks target based on priority and casts spell if not already on target"] = "/cursive multicurse <法术名称>|<优先级>|<选项列表,用半角逗号分隔>: 根据优先级选择目标并施放法术，如果目标上没有",
		["/cursive target <spellName:str>|<priority?:str>|<options?:List<str>>: Targets unit based on priority if spell in range and not already on target"] = "/cursive target <法术名称>|<优先级>|<选项列表,用半角逗号分隔>:如果法术在范围内且目标上没有此法术，则根据优先级选择目标",
		["Target with the highest HP."] = "选择生命值最高的目标.",
		["Target with the lowest HP."] = "选择生命值最低的目标.",
		["Target with the highest raid mark."] = "选择团队标记最高的目标.",
		["Target with the highest raid mark with Cross set to -1 and Skull set to -2 (Square highest prio at 6)."] = "选择团队标记最高的目标，但是将红叉设为-1，骷髅设为-2（方块标记最高优先级为6）.",
		["Target with the lowest raid mark."] = "选择团队标记优先级最低的目标.(与RAID_MARK顺序相反)",
		["Target with the highest HP and raid mark."] = "选择生命值和团队标记最高的目标.",
		["Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE mark prio."] = "与HIGHEST_HP_RAID_MARK相同，但是RAID_MARK_SQUARE标记优先.",
		["Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK mark prio."] = "与HIGHEST_HP_RAID_MARK相同，但是INVERSE_RAID_MARK标记优先.",
		["|cffffcc00Cursive:|cffffaaaa Couldn't find a target to curse."] = "|cffffcc00Cursive:|cffffaaaa 找不到要诅咒的目标.",
		-- 法术描述样本
		-- 腐蚀术：腐蚀目标，在18.69秒内造成累计828到834点伤害。
		-- 精灵之火：使目标的护甲降低175点，持续40秒。在效果持续期间，目标无法潜行或隐形。
		-- 扫击：对目标造成19点伤害，并在9秒内造成总计39点额外伤害。伤害受到你的攻击强度加成，奖励1个连击点数。
		-- 虫群：敌人被飞虫围绕，攻击命中率降低2%，在18秒内受到总计99点自然伤害。
		-- 月火术：灼烧敌人，对其造成40到48点伤害，并在18秒内造成额外的120点奥术伤害。
		["curse_duration_format"] = "(%d+%.?%d*)秒",
		["Shared Debuffs"] = "共享debuff",
		["|cffffcc00Cursive:|cffffaaaa Unknown command."] = "|cffffcc00Cursive:|cffffaaaa 未知命令.",
		--新增commands条件 by 武藤纯子酱 2025.8.28
		["Target BOSS with the highest raid mark."] = "BOSS目标中有团队标记的",
		["Target BOSS with the highest HP."] = "BOSS目标中生命值最高的",			
		["Maximum HP for a target to be considered. Example usage maxhp=50000."] = "目标考虑的最大生命值。例如：maxhp=50000",
		["Maximum health percentage threshold. Example: maxhppercent=50 (Targets with HP% ≤ 50%%)"] = "最大生命值百分比阈值。示例：maxhppercent=50（选择生命值≤50%%的目标）",
		["Minimum health percentage threshold. Example: minhppercent=50 (Targets with HP% ≥ 50%%)"] = "最小生命值百分比阈值。示例：minhppercent=50（选择生命值≥50%%的目标）",
		["Filter boss-type targets only"] = "仅筛选BOSS类型目标",
		["Target distance. Without UnitXP, 1/2/3 = 28/11.11/9.9 yards; with UnitXP, the value is used as yards."] = "目标距离。无UnitXP时 1/2/3 对应28/11.11/9.9码；有UnitXP时按实际码数处理。",
		["Filter targets with specific buff IDs. Example: buffids=789"] = "根据目标拥有的BUFF ID过滤。例如：buffids=789",
		["Filter targets with specific buff name. Example: buffnames='Power Word: Shield'"] = "根据目标拥有的BUFF名字过滤。例如：buffnames='真言术：盾'",	
		["Filter units is behind."] = "忽略掉在身后的单位",	

		-- curses
		["(.+) fades from (.+)"] = "(.+)效果从(.+)身上消失",
		["Your (.+) was resisted by (.+)"] = "你的(.+)被(.+)抵抗了",
		["Your (.+) is parried by (.+)"] = "你的(.+)被(.+)招架了",
		["Your (.+) missed (.+)"] = "你的(.+)没有击中(.+)",
		["Your (.+) was dodged by (.+)"] = "你的(.+)被(.+)躲闪过去了",
		["Your (.+) was blocked by (.+)"] = "你的(.+)被(.+)格挡了",
		["Your (.+) fail.+\. (.+) is immune"] = "你的(.+)施放失败。(.+)对此免疫",
		["Your Molten Blast(.+)for .+ Fire damage"] = "你的熔岩爆裂(.+)造成.+点火焰伤害", -- 修复 翻译错误 by 武藤纯子酱 2025.8.30
		-- 新增 by 武藤纯子酱 2025.8.28
		["%s is afflicted by %s (%d+)."] = "^(.-)受到了(.-)效果的影响（(%d+)）。",
		["%s gains %s (%d+)."] = "^(.-)获得了(.-)的效果（(%d+)）。",

		-- global
		["|cffffcc00Cursive:|cffffaaaa Couldn't detect SuperWoW."] = "|cffffcc00Cursive:|cffffaaaa 无法检测到SuperWoW.",
		["|cffffcc00Cursive:|cffffaaaa Loaded.  /cursive for commands and minimap icon for options."] = "|cffffcc00Cursive:|cffffaaaa 已加载。/cursive 用于查看帮助命令，小地图图标打开设置选项.",

		-- settings
		["Cursive"] = "Cursive",
		["Show Targeting Arrow"] = "显示目标箭头",
		["Show Raid Icons"] = "显示团队标记",
		["Show Health Bar"] = "显示生命条",
		["Show Unit Name"] = "显示单位名称",
		["Health Bar/Unit Name Width"] = "生命条宽度",
		["Health Bar/Unit Name Height"] = "生命条高度",
		["Health Bar Texture"] = "生命条纹理",
		["Health Bar Texture Desc"] = "生命条纹理的完整路径，例如默认值：Interface\\TargetingFrame\\UI-StatusBar",
		["Raid Icon Size"] = "团队标记大小",
		["Curse Icon Size"] = "诅咒图标大小",
		["Spacing"] = "间距",
		["Name/Hp Text Size"] = "名称/生命值文字大小",
		["Curse Timer Text Size"] = "诅咒计时器文字大小",
		["Scale"] = "缩放",
		["In Combat"] = "战斗中",
		["Player"] = "玩家",
		["Player Desc"] = "只显示玩家单位",
		["Not Player"] = "非玩家",
		["Not Player Desc"] = "只显示非玩家单位",
		["Hostile"] = "敌对",
		["Attackable"] = "可攻击",
		["Within 28 Range"] = "在28范围内",
		["Within 45 Range"] = "在45范围内",
		["Has Raid Mark"] = "有团队标记",
		["Has Curse"] = "有诅咒",
		["Only show units you have cursed"] = "只显示你诅咒过的单位",
		["Enabled"] = "启用",
		["Enable/Disable Cursive"] = "启用/禁用 Cursive",
		["Show Title"] = "显示标题",
		["Show the title of the frame"] = "显示框架的标题",
		["Allow clickthrough"] = "允许点击穿透",
		["This will allow you to click through the frame to target mobs behind it, but prevents dragging the frame."] = "这将允许你点击穿透框架选中其背后的怪物，但会禁用拖动框架.",
		["Show Frame Background"] = "显示框架背景",
		["Toggle the frame background to help with positioning"] = "切换框架背景以帮助定位",
		["Reset Frame"] = "重置框架",
		["Move the frame back to the default position"] = "将框架移回默认位置",
		["Bar Display Settings"] = "条形显示设置",
		["Mob filters"] = "怪物过滤器",
		["Target and Raid Marks always shown"] = "目标和团队标记始终显示",
		["Max Curses"] = "最大诅咒数",
		["Max Rows"] = "最大行数",
		["Max Columns"] = "最大列数",
		["Curse Ordering"] = "诅咒排序",
		["Decimal Duration"] = "小数持续时间",
		["Decimal Duration Desc"] = "当剩余时间少于10秒时，显示1位小数.",
		["Order applied"] = "应用顺序",
		["Expiring soonest -> latest"] = "即将到期->最新",
		["Expiring latest -> soonest"] = "最新->即将到期",
		["Not ignored"] = "不被忽略",
		["Ignored Mobs List (Enter to save)"] = "忽略的怪物列表（回车保存）",
		["Ignored Mobs Desc"] = "用逗号分隔的字符串列表，如果在单位名称中找到则忽略。少于3个字符的条目会被忽略。如果你使用了这些正则表达式字符(*+%?)，它将进行正则表达式搜索，否则将进行纯文本搜索。所以Rift-Lost和Rift%-Lost都应该有效.",
		["Shared Faerie Fire"] = "共享精灵之火",
		["This will show other player's Faerie Fires and avoid trying to cast Faerie Fire on those mobs"] = "这将显示其他玩家的精灵之火，并避免尝试在这些怪物上施放精灵之火",
		--新增 by 武藤纯子酱 2025.8.28
		["Always Show Current Target"] = "总是显示当前目标",
		["Always show current target at the bottom of the mob list if it is not already shown"] = "如果当前目标尚未显示，则始终将其显示在列表底部",	
		["Distance Filter"] = "距离过滤",
		["Set maximum target distance (1-250 yards)"] = "设置目标最大距离（1-250码）",
		["InSight Filter"] = "视野过滤",
		["Only display units ‌within the visible range of sight"] = "只显示视野范围内的单位",
		["Max Health Filter"] = "最大生命值过滤",
		["Set maximum target heatlth (0-1000000)"] = "只显示最大生命值超过阈值的单位（单位：万）",
		["Show Unit Distance"] = "显示单位距离",		
		["Show Unit Health Percent"] = "显示单位生命值百分比",
		 -- 新增中文支持 by 武藤纯子酱 2025.8.29
		["Invert Bar Display"] = "反转显示",
		["Show sections in order 3-2-1 and reverse element order in sections 1 and 3"] = "在右侧显示团队标记，左侧显示DOT图标",
		["Expand Bars Upwards"] = "向上生长",
		["Make bars expand upwards instead of downwards"] = "向上生长而不是向下生长",
		["Section Display"] = "显示部分",
		["Size & Appearance"] = "尺寸与外观",	
		-- 新增 共享DEBUFF翻译 by 武藤纯子酱 2025.9.10
		["Shared Sunder Armor"] = "共享破甲攻击（战士）",
		["This will show other player's Sunder Armor and avoid trying to cast Sunder Armor on those mobs"] = "这将显示其他玩家的破甲攻击，并避免尝试在这些怪物上施放破甲攻击",
		["Shared Expose Armor"] = "共享破甲（盗贼）",
		["This will show other player's Expose Armor and avoid trying to cast Expose Armor on those mobs"] = "这将显示其他玩家的破甲，并避免尝试在这些怪物上施放破甲",
		["Shared Hunter's Mark"] = "共享猎人印记",
		["This will show other player's Hunter's Mark and avoid trying to cast Hunter's Mark on those mobs"] = "这将显示其他玩家的猎人印记，并避免尝试在这些怪物上施放猎人印记",	
		["Shared Curse of Recklessness"] = "共享鲁莽诅咒",
		["This will show other player's Curse of Recklessness and avoid trying to cast it on those mobs"] = "这将显示其他玩家的鲁莽诅咒，并避免尝试在这些怪物上施放鲁莽诅咒",
		["Shared Curse of the Elements"] = "共享元素诅咒",
		["This will show other player's Curse of the Elements and avoid trying to cast it on those mobs"] = "这将显示其他玩家的元素诅咒，并避免尝试在这些怪物上施放元素诅咒",
		["Shared Curse of Shadow"] = "共享暗影诅咒",
		["This will show other player's Curse of Shadow and avoid trying to cast it on those mobs"] = "这将显示其他玩家的暗影诅咒，并避免尝试在这些怪物上施放暗影诅咒",
		-- 新增放逐术检查 by 武藤纯子酱 2026.3.17
		["Shared Banish"] = "共享放逐术",
		["This will show other player's Banish and avoid trying to cast Banish on those mobs"] = "这将显示其他玩家的放逐术，并避免尝试在这些怪物上施放放逐术",
		-- 新增 目标名字显示相关 by 武藤纯子酱 2025.12.9
		["Show Target Name"] = "显示目标名字",
		["Show the name of the unit's current target"] = "显示单位当前目标的名字",
		["Target Name Width"] = "目标名字宽度",
		["Width of the target name column"] = "目标名字栏的宽度",
		-- 新增 目标名字背景 by 武藤纯子酱 2026.9.3
		["Target Name Background"] = "目标名字背景",
		["Show a gray semi-transparent background with black border behind the target name column"] = "在目标名字栏显示灰色半透明背景和黑色边框",
		-- 新增 按距离排序 / 满槽强调 by 武藤纯子酱 2026.9.10
		["Sort By Distance"] = "按距离排序",
		["Sort all bars by distance from nearest to farthest"] = "将所有单位条按距离从近到远排序显示",
		["Distance Sort Mode"] = "距离排序方向",
		["Choose to sort bars from nearest to farthest or farthest to nearest"] = "选择单位条按距离由近到远还是由远到近排序",
		["Nearest -> Farthest"] = "由近到远",
		["Farthest -> Nearest"] = "由远到近",
		["Emphasize Full Buff/Debuff Slots"] = "满槽强调",
		["Emphasize the bar when the unit's buff and debuff slots are both full"] = "当单位的 buff 与 debuff 位全部占满时对该条进行强调",
		["Full Slots Emphasis Style"] = "满槽强调样式",
		["How to emphasize a bar when buff/debuff slots are full"] = "选择满槽时条目的强调方式",
		["Border"] = "边框变色",
		["Health Bar"] = "血条变色",
		["Fade"] = "半透明淡化",
		
		-- spells
		["Rank"] = "等级",
		["Rank 1"] = "等级 1",
		["Rank 2"] = "等级 2",
		["Rank 3"] = "等级 3",
		["Rank 4"] = "等级 4",
		--新增 by 武藤纯子酱 2025.8.28
		["Rank 5"] = "等级 5",
		["Rank 6"] = "等级 6",
		["Rank 7"] = "等级 7",
		["Rank 8"] = "等级 8",
		["Rank 9"] = "等级 9",
		["Rank 10"] = "等级 10",
		["Rank 11"] = "等级 11",
		["Rank 12"] = "等级 12",
		["Rank 13"] = "等级 13",
		["Rank 14"] = "等级 14",	
		["Rank 15"] = "等级 15",		

		-- druid
		["entangling roots"] = "纠缠根须",
		["sleep"] = "沉睡",
		["faerie fire"] = "精灵之火",
		--["faerie fire (bear)()"] = "精灵之火（熊形态）",
		["faerie fire (feral)"] = "精灵之火（野性）", -- 修复翻译 by 武藤纯子酱 2025.10.2
		["hibernate"] = "休眠",
		["insect swarm"] = "虫群",
		["moonfire"] = "月火术",
		["rake"] = "扫击",
		["rip"] = "撕扯",
		["soothe animal"] = "安抚动物",
		["bash"] = "重击",
		["Maim"] = "致残",
		["demoralizing roar"] = "挫志咆哮",
		["challenging roar"] = "挑战咆哮",
		["ferocious bite"] = "凶猛撕咬",
		["pounce bleed"] = "突袭流血",

		-- hunter
		["scorpid sting"] = "毒蝎钉刺",
		["serpent sting"] = "毒蛇钉刺",
		["viper sting"] = "蝰蛇钉刺",
		["wing clip"] = "摔绊",
		["concussive shot"] = "震荡射击",
		["wyvern sting"] = "翼龙钉刺",
		["counterattack"] = "反击",
		["hunter's mark"] = "猎人印记",
		["freezing trap"] = "冰冻陷阱",
		["explosive trap effect"] = "爆炸陷阱效果",	-- 新增 by 武藤纯子酱 2025.8.28
		["immolation trap effect"] = "献祭陷阱效果",	-- 新增 by 武藤纯子酱 2025.8.28

		-- mage
		["polymorph"] = "变形术",
		["polymorph: cow"] = "变形术：奶牛",
		["polymorph: turtle"] = "变形术：龟",
		["polymorph: pig"] = "变形术：猪",
		["polymorph: rodent"] = "变形术：鼠",	-- 新增 by 武藤纯子酱 2025.8.28
		["Polymorph: Draenei Homunculus"] = "变形术：德莱尼人",	-- 新增 by 武藤纯子酱 2026.9.16
		["fire vulnerability"] = "火焰易伤",	-- 新增 by 武藤纯子酱 2025.8.28
		["ignite"] = "点燃",		-- 新增 by 武藤纯子酱 2025.8.28
		["fire blast"] = "火焰冲击",	-- 新增 by 武藤纯子酱 2025.10.15
		["scorch"] = "灼烧",	-- 新增 by 武藤纯子酱 2025.10.15		

		-- priest
		["shackle undead"] = "束缚亡灵",
		["mind soothe"] = "安抚心灵",
		["mind control"] = "精神控制", -- 修复翻译 by 武藤纯子酱 2025.8.28
		["devouring plague"] = "噬灵瘟疫", -- 修复翻译 by 武藤纯子酱 2025.8.28
		["hex of weakness"] = "虚弱妖术",
		["shadow word: pain"] = "暗言术：痛",
		["vampiric embrace"] = "吸血鬼的拥抱",
		["burning zeal"] = "燃烧热忱",
		["holy fire"] = "神圣之火",
		["mind flay"] = "精神鞭笞",	-- 新增 by 武藤纯子酱 2025.8.28

		-- Paladin
		["turn undead"] = "超度亡灵",
		["hammer of justice"] = "制裁之锤",	-- 新增 by 武藤纯子酱 2025.8.28
		["judgement of wisdom"] = "智慧审判",	-- 新增 by 武藤纯子酱 2025.8.28
		["judgement of the crusader"] = "十字军审判",	-- 新增 by 武藤纯子酱 2025.8.28	
		["judgement of justice"] = "正义审判",	-- 新增 by 武藤纯子酱 2025.8.28	
		["judgement of light"] = "光明审判",	-- 新增 by 武藤纯子酱 2025.8.28

		-- rogue
		["blind"] = "致盲",
		["sap"] = "闷棍",
		["gouge"] = "凿击",
		["rupture"] = "割裂", -- no idea if right
		["kidney shot"] = "肾击", -- no idea if right
		["expose armor"] = "破甲", -- no idea if right
		["garrote"] = "绞喉", -- no idea if right -- 修复翻译 by 武藤纯子酱 2025.9.21
		["deadly poison"] = "致命毒药", -- no idea if right
		["deadly poison ii"] = "致命毒药 II",
		["deadly poison iii"] = "致命毒药 III",
		["deadly poison iv"] = "致命毒药 IV",
		["deadly poison v"] = "致命毒药 V",
		["corrosive poison"] = "腐蚀毒药",
		["corrosive poison ii"] = "腐蚀毒药 II",
		["hemorrhage"] = "出血", -- no idea if right
		["cheap shot"] = "偷袭", -- no idea if right -- 修复翻译 by 武藤纯子酱 2025.9.21
		["mind-numbing poison"] = "麻痹毒药", -- 新增 by 武藤纯子酱 2025.8.28
		["mind-numbing poison ii"] = "麻痹毒药 II", -- 新增 by 武藤纯子酱 2025.8.28
		["mind-numbing poison iii"] = "麻痹毒药 III", -- 新增 by 武藤纯子酱 2025.8.28	
		["crippling poison"] = "致残毒药", -- 新增 by 武藤纯子酱 2025.8.28
		["crippling poison ii"] = "致残毒药 II", -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison"] = "致伤毒药", -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison ii"] = "致伤毒药 II", -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison iii"] = "致伤毒药 III", -- 新增 by 武藤纯子酱 2025.8.28
		["wound poison iv"] = "致伤毒药 IV", -- 新增 by 武藤纯子酱 2025.8.28

		-- shaman
		["flame shock"] = "烈焰震击", -- no idea if right
		["molten blast"] = "熔岩爆裂", -- no idea if right
		["frost shock"]  = "冰霜震击", -- 新增 by 武藤纯子酱 2025.8.28
		["hex"]  = "妖术", -- 新增 by 武藤纯子酱 2025.8.30		

		-- warlock
		["conflagrate"] = "引燃", -- no idea if right
		["corruption"] = "腐蚀术",
		["curse of agony"] = "痛苦诅咒",
		["curse of doom"] = "厄运诅咒", -- 修复翻译 by 武藤纯子酱 2025.8.28
		["curse of recklessness"] = "鲁莽诅咒",
		["curse of shadow"] = "暗影诅咒",
		["curse of the elements"] = "元素诅咒",
		["curse of tongues"] = "语言诅咒",
		["curse of weakness"] = "虚弱诅咒",
		["curse of exhaustion"] = "疲劳诅咒",
		["parasite of aln"] = "艾林寄生",
		["dark harvest"] = "暗影收割", -- 修复翻译 by 武藤纯子酱 2025.8.28
		["immolate"] = "献祭",
		["death coil"] = "死亡缠绕",
		["banish"] = "放逐术",
		["siphon life"] = "生命虹吸",
		["fear"] = "恐惧",
		["seduction"] = "诱惑", -- 新增 by 武藤纯子酱 2025.8.30
		["spell lock"] = "法术封锁", -- 新增 by 武藤纯子酱 2025.8.30

		-- warrior
		["rend"] = '撕裂', -- no idea if right
		["mortal strike"] = "致死打击", -- 新增 by 武藤纯子酱 2025.8.28
		["sunder armor"] = "破甲攻击", -- 新增 by 武藤纯子酱 2025.8.28
		["counterattack"] = "反击", -- 新增 by 武藤纯子酱 2025.8.28
		["concussion blow"] = "震荡猛击", -- 新增 by 武藤纯子酱 2025.8.28
		["hamstring"] = "断筋", -- 新增 by 武藤纯子酱 2025.8.28
		["disarm"] = "缴械", -- 新增 by 武藤纯子酱 2025.8.28
		["thunderclap"] = "雷霆一击", -- 新增 by 武藤纯子酱 2025.8.28
		["demoralizing shout"] = "挫志怒吼", -- 新增 by 武藤纯子酱 2025.8.28
		["mocking blow"] = "惩戒痛击", -- 新增 by 武藤纯子酱 2025.8.28
		["intimidating shout"] = "破胆怒吼", -- 新增 by 武藤纯子酱 2025.8.28
		["taunt"] = "嘲讽", -- 新增 by 武藤纯子酱 2025.8.28
		["piercing howl"] = "刺耳怒吼", -- 新增 by 武藤纯子酱 2025.8.28
		["revenge stun"] = "复仇昏迷", -- 新增 by 武藤纯子酱 2025.8.28
		["charge"] = "冲锋", -- 新增 by 武藤纯子酱 2025.8.28
		["intercept"] = "拦截", -- 新增 by 武藤纯子酱 2025.8.28	
	}
end)
