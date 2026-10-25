
local module, L = BigWigs:ModuleDeclaration("Anubisath Sentinel", "Ahn'Qiraj")
local bbanubisathsentinel = AceLibrary("Babble-Boss-2.2")["Anubisath Sentinel"]
local bselementalvulnerability = AceLibrary("Babble-Spell-2.2")["Elemental Vulnerability"]
local bsfirestrike = AceLibrary("Babble-Spell-2.2")["Fire Strike"]

module.revision = 30082
module.enabletrigger = module.translatedName
module.toggleoptions = {"abilities", "selfreflect"}
module.trashMod = true
module.defaultDB = {
	bosskill = nil,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Sentinel",

    abilities_cmd = "abilities",
    abilities_name = "技能警报",
    abilities_desc = "技能出现时进行警告",

    selfreflect_cmd = "selfreflect",
    selfreflect_name = "自身反射法术警报",
    selfreflect_desc = "当法术被反射回自己时进行警告",


    bar_knockBack = " 有击退",
    buffIcon_knockBack = "Interface\\Icons\\Ability_UpgradeMoonGlaive",

    bar_manaBurn = " 有法力燃烧",
    buffIcon_manaBurn = "Interface\\Icons\\Spell_Shadow_ManaBurn",

    bar_mending = " 有治愈",
    buffIcon_mending = "Interface\\Icons\\Spell_Nature_ResistNature",

    bar_mortalStrike = " 有致死打击",
    buffIcon_mortalStrike = "Interface\\Icons\\Ability_Warrior_SavageBlow",

    bar_shadowStorm = " 有暗影风暴",
    buffIcon_shadowStorm = "Interface\\Icons\\Spell_Shadow_Haunting",

    bar_thorns = " 有荆棘术",
    buffIcon_thorns = "Interface\\Icons\\Spell_Nature_Thorns",

    bar_thunderClap = " 有雷霆一击",
    buffIcon_thunderClap = "Interface\\Icons\\Ability_ThunderClap",

    trigger_fireArcaneReflect1 = "^Your Moonfire is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect2 = "^Your Scorch is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect3 = "^Your Flame Shock is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect4 = "^Your Fireball is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect5 = "^Your Flame Lash is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect6 = "^Your Detect Magic is reflected back by Anubisath Sentinel.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflectOther = "(.+)'s Detect Magic is reflected back by Anubisath Sentinel.",--CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE // CHAT_MSG_SPELL_PARTY_DAMAGE
    bar_fireArcaneReflect = " 反射火焰 & 奥术",
        --not used for TurtleWoW
    --buffIcon_fireArcaneReflect = "nil",
    
    trigger_shadowFrostReflect1 = "^Your Shadow Word: Pain is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect2 = "^Your Corruption is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect3 = "^Your Frostbolt is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect4 = "^Your Frost Shock is reflected back by Anubisath Defender.",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflectOther = "(.+)'s Corruption is reflected back by Anubisath Sentinel.",--CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE // CHAT_MSG_SPELL_PARTY_DAMAGE
    bar_shadowFrostReflect = " 反射暗影 & 冰霜",
        --not used for TurtleWoW
    --buffIcon_shadowFrostReflect = "Interface\\Icons\\Spell_Arcane_Blink",
    
    trigger_selfReflect = "^Your (.*) is reflected back by Anubisath Sentinel.",--CHAT_MSG_SPELL_SELF_DAMAGE
    msg_selfReflect = "停止自残！",
    
    ["You have slain %s!"] = true,
} end )

L:RegisterTranslations("zhCN", function() return {
	-- Sunelegy，Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22
    cmd = "Sentinel",

    abilities_cmd = "abilities",
    abilities_name = "技能警报",
    abilities_desc = "技能出现时进行警告",

    selfreflect_cmd = "selfreflect",
    selfreflect_name = "自身反射法术警报",
    selfreflect_desc = "当法术被反射回自己时进行警告",


    bar_knockBack = " 有击退",
    buffIcon_knockBack = "Interface\\Icons\\Ability_UpgradeMoonGlaive",

    bar_manaBurn = " 有法力燃烧",
    buffIcon_manaBurn = "Interface\\Icons\\Spell_Shadow_ManaBurn",

    bar_mending = " 有治愈",
    buffIcon_mending = "Interface\\Icons\\Spell_Nature_ResistNature",

    bar_mortalStrike = " 有致死打击",
    buffIcon_mortalStrike = "Interface\\Icons\\Ability_Warrior_SavageBlow",

    bar_shadowStorm = " 有暗影风暴",
    buffIcon_shadowStorm = "Interface\\Icons\\Spell_Shadow_Haunting",

    bar_thorns = " 有荆棘术",
    buffIcon_thorns = "Interface\\Icons\\Spell_Nature_Thorns",

    bar_thunderClap = " 有雷霆一击",
    buffIcon_thunderClap = "Interface\\Icons\\Ability_ThunderClap",

    trigger_fireArcaneReflect1 = "^你的月火术被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect2 = "^你的灼烧被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect3 = "^你的烈焰震击被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect4 = "^你的火球术被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect5 = "^你的烈焰鞭笞被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflect6 = "^你的侦测魔法被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_fireArcaneReflectOther = "(.+)的侦测魔法被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE // CHAT_MSG_SPELL_PARTY_DAMAGE
    bar_fireArcaneReflect = " 反射火焰 & 奥术",
        --not used for TurtleWoW
    --buffIcon_fireArcaneReflect = "nil",
    
    trigger_shadowFrostReflect1 = "^你的暗言术：痛被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect2 = "^你的腐蚀术被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect3 = "^你的寒冰箭被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflect4 = "^你的冰霜震击被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    trigger_shadowFrostReflectOther = "(.+)的腐蚀术被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE // CHAT_MSG_SPELL_PARTY_DAMAGE
    bar_shadowFrostReflect = " 反射暗影 & 冰霜",
        --not used for TurtleWoW
    --buffIcon_shadowFrostReflect = "Interface\\Icons\\Spell_Arcane_Blink",
    
    trigger_selfReflect = "^你的(.*)被阿努比萨斯哨兵反弹回来。",--CHAT_MSG_SPELL_SELF_DAMAGE
    msg_selfReflect = "停止自残！",
    
    ["You have slain %s!"] = "你杀死了%s！",
} end )

local timer = {
	knockBack = 600,
	manaBurn = 600,
	mending = 600,
	mortalStrike = 600,
	shadowStorm = 600,
	thorns = 600,
	thunderClap = 600,
	fireArcaneReflect = 600,
	shadowFrostReflect = 600,
}
local icon = {
	knockBack = "Inv_Gauntlets_05",
	manaBurn = "Spell_Shadow_Manaburn",
	mending = "spell_nature_resistnature",
	mortalStrike = "ability_warrior_savageblow",
	shadowStorm = "spell_shadow_shadowbolt",
	thorns = "Spell_Nature_Thorns",
	thunderClap = "Ability_ThunderClap",
	fireArcaneReflect = "spell_arcane_portaldarnassus",
	shadowFrostReflect = "spell_arcane_portalundercity",
}
local color = {
	knockBack = "yellow",
	manaBurn = "red",
	mending = "green",
	mortalStrike = "yellow",
	shadowStorm = "red",
	thorns = "orange",
	thunderClap = "orange",
	fireArcaneReflect = "yellow",
	shadowFrostReflect = "yellow",
}
local syncName = {
	knockBack = "SentinelKnockback"..module.revision,
	manaBurn = "SentinelManaburn"..module.revision,
	mending = "SentinelMend"..module.revision,
	mortalStrike = "SentinelMortalstrike"..module.revision,
	shadowStorm = "SentinelShadowstorm"..module.revision,
	thorns = "SentinelThorns"..module.revision,
	thunderClap = "SentinelThunderclap"..module.revision,
	fireArcaneReflect = "SentinelArcref2"..module.revision,
	shadowFrostReflect = "SentinelSharef2"..module.revision,
	
	addDead = "SentinelAddDead"..module.revision,
}

-- 英文版 BigWigs 客户端同步过来的标记名归一成中文（兼容混编团队）
local iconEnToCn = {
	Star = "星星", Circle = "大饼", Diamond = "菱形", Triangle = "三角",
	Moon = "月亮", Square = "方块", Cross = "叉子", Skull = "骷髅",
	none = "无", unmarked = "未标记",
}
local function normalizeIconName(rest)
	if rest and iconEnToCn[rest] then
		return iconEnToCn[rest]
	end
	return rest
end

local raidIcon_knockBack = 2
local raidIcon_manaBurn = 4
local raidIcon_mending = 8
local raidIcon_mortalStrike = 6
local raidIcon_thorns = 7
local raidIcon_thunderClap = 3
local raidIcon_shadowStorm = 5
local raidIcon_fireArcaneReflect = "未标记"
local raidIcon_shadowFrostReflect = 1

local knockBackFound = nil
local manaBurnFound = nil
local mendingFound = nil
local mortalStrikeFound = nil
local shadowStormFound = nil
local thornsFound = nil
local thunderClapFound = nil
local fireArcaneReflectFound = nil
local shadowFrostReflectFound = nil

local addDead = 0

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event")--Debug
	
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE", "Event") --trigger_selfReflect, reflect type detection
	self:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE", "Event") --reflect type detection
	self:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE", "Event") --reflect type detection
	
	
	self:ThrottleSync(5, syncName.knockBack)
	self:ThrottleSync(5, syncName.manaBurn)
	self:ThrottleSync(5, syncName.mending)
	self:ThrottleSync(5, syncName.mortalStrike)
	self:ThrottleSync(5, syncName.shadowStorm)
	self:ThrottleSync(5, syncName.thorns)
	self:ThrottleSync(5, syncName.thunderClap)
	self:ThrottleSync(5, syncName.fireArcaneReflect)
	self:ThrottleSync(5, syncName.shadowFrostReflect)
	
	self:ThrottleSync(3, syncName.addDead)
end

function module:OnSetup()
	self.started = nil
	
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
end

function module:OnEngage()
	addDead = 0
	
	self:ResetAllBars()
	
	raidIcon_knockBack = 2
	raidIcon_manaBurn = 4
	raidIcon_mending = 8
	raidIcon_mortalStrike = 6
	raidIcon_thorns = 7
	raidIcon_thunderClap = 3
	raidIcon_shadowStorm = 5
	raidIcon_fireArcaneReflect = "未标记"
	raidIcon_shadowFrostReflect = 1
	
	knockBackFound = nil
	manaBurnFound = nil
	mendingFound = nil
	mortalStrikeFound = nil
	shadowStormFound = nil
	thornsFound = nil
	thunderClapFound = nil
	fireArcaneReflectFound = nil
	shadowFrostReflectFound = nil
	
	self:ScheduleRepeatingEvent("AbilitiesScan", self.AbilitiesScan, 0.5, self)
end

function module:ResetAllBars()
	self:RemoveBar("未标记"..L["bar_knockBack"])
	self:RemoveBar("星星"..L["bar_knockBack"])
	self:RemoveBar("大饼"..L["bar_knockBack"])
	self:RemoveBar("菱形"..L["bar_knockBack"])
	self:RemoveBar("三角"..L["bar_knockBack"])
	self:RemoveBar("月亮"..L["bar_knockBack"])
	self:RemoveBar("方块"..L["bar_knockBack"])
	self:RemoveBar("叉子"..L["bar_knockBack"])
	self:RemoveBar("骷髅"..L["bar_knockBack"])
	
	self:RemoveBar("未标记"..L["bar_manaBurn"])
	self:RemoveBar("星星"..L["bar_manaBurn"])
	self:RemoveBar("大饼"..L["bar_manaBurn"])
	self:RemoveBar("菱形"..L["bar_manaBurn"])
	self:RemoveBar("三角"..L["bar_manaBurn"])
	self:RemoveBar("月亮"..L["bar_manaBurn"])
	self:RemoveBar("方块"..L["bar_manaBurn"])
	self:RemoveBar("叉子"..L["bar_manaBurn"])
	self:RemoveBar("骷髅"..L["bar_manaBurn"])
	
	self:RemoveBar("未标记"..L["bar_mending"])
	self:RemoveBar("星星"..L["bar_mending"])
	self:RemoveBar("大饼"..L["bar_mending"])
	self:RemoveBar("菱形"..L["bar_mending"])
	self:RemoveBar("三角"..L["bar_mending"])
	self:RemoveBar("月亮"..L["bar_mending"])
	self:RemoveBar("方块"..L["bar_mending"])
	self:RemoveBar("叉子"..L["bar_mending"])
	self:RemoveBar("骷髅"..L["bar_mending"])
	
	self:RemoveBar("未标记"..L["bar_mortalStrike"])
	self:RemoveBar("星星"..L["bar_mortalStrike"])
	self:RemoveBar("大饼"..L["bar_mortalStrike"])
	self:RemoveBar("菱形"..L["bar_mortalStrike"])
	self:RemoveBar("三角"..L["bar_mortalStrike"])
	self:RemoveBar("月亮"..L["bar_mortalStrike"])
	self:RemoveBar("方块"..L["bar_mortalStrike"])
	self:RemoveBar("叉子"..L["bar_mortalStrike"])
	self:RemoveBar("骷髅"..L["bar_mortalStrike"])
	
	self:RemoveBar("未标记"..L["bar_shadowStorm"])
	self:RemoveBar("星星"..L["bar_shadowStorm"])
	self:RemoveBar("大饼"..L["bar_shadowStorm"])
	self:RemoveBar("菱形"..L["bar_shadowStorm"])
	self:RemoveBar("三角"..L["bar_shadowStorm"])
	self:RemoveBar("月亮"..L["bar_shadowStorm"])
	self:RemoveBar("方块"..L["bar_shadowStorm"])
	self:RemoveBar("叉子"..L["bar_shadowStorm"])
	self:RemoveBar("骷髅"..L["bar_shadowStorm"])
	
	self:RemoveBar("未标记"..L["bar_thorns"])
	self:RemoveBar("星星"..L["bar_thorns"])
	self:RemoveBar("大饼"..L["bar_thorns"])
	self:RemoveBar("菱形"..L["bar_thorns"])
	self:RemoveBar("三角"..L["bar_thorns"])
	self:RemoveBar("月亮"..L["bar_thorns"])
	self:RemoveBar("方块"..L["bar_thorns"])
	self:RemoveBar("叉子"..L["bar_thorns"])
	self:RemoveBar("骷髅"..L["bar_thorns"])
	
	self:RemoveBar("未标记"..L["bar_thunderClap"])
	self:RemoveBar("星星"..L["bar_thunderClap"])
	self:RemoveBar("大饼"..L["bar_thunderClap"])
	self:RemoveBar("菱形"..L["bar_thunderClap"])
	self:RemoveBar("三角"..L["bar_thunderClap"])
	self:RemoveBar("月亮"..L["bar_thunderClap"])
	self:RemoveBar("方块"..L["bar_thunderClap"])
	self:RemoveBar("叉子"..L["bar_thunderClap"])
	self:RemoveBar("骷髅"..L["bar_thunderClap"])
	
	self:RemoveBar("未标记"..L["bar_fireArcaneReflect"])
	self:RemoveBar("星星"..L["bar_fireArcaneReflect"])
	self:RemoveBar("大饼"..L["bar_fireArcaneReflect"])
	self:RemoveBar("菱形"..L["bar_fireArcaneReflect"])
	self:RemoveBar("三角"..L["bar_fireArcaneReflect"])
	self:RemoveBar("月亮"..L["bar_fireArcaneReflect"])
	self:RemoveBar("方块"..L["bar_fireArcaneReflect"])
	self:RemoveBar("叉子"..L["bar_fireArcaneReflect"])
	self:RemoveBar("骷髅"..L["bar_fireArcaneReflect"])
	
	self:RemoveBar("未标记"..L["bar_shadowFrostReflect"])
	self:RemoveBar("星星"..L["bar_shadowFrostReflect"])
	self:RemoveBar("大饼"..L["bar_shadowFrostReflect"])
	self:RemoveBar("菱形"..L["bar_shadowFrostReflect"])
	self:RemoveBar("三角"..L["bar_shadowFrostReflect"])
	self:RemoveBar("月亮"..L["bar_shadowFrostReflect"])
	self:RemoveBar("方块"..L["bar_shadowFrostReflect"])
	self:RemoveBar("叉子"..L["bar_shadowFrostReflect"])
	self:RemoveBar("骷髅"..L["bar_shadowFrostReflect"])
end

function module:OnDisengage()
	self:ResetAllBars()
	self:CancelScheduledEvent("AbilitiesScan")
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	--BigWigs:CheckForBossDeath(msg, self)

	if (msg == string.format(UNITDIESOTHER, bbanubisathsentinel)) then
		addDead = addDead + 1
		if addDead <= 4 then
			self:Sync(syncName.addDead .. " " .. addDead)
		end
	end
end

function module:CheckForBossDeath(msg)
	if msg == string.format(UNITDIESOTHER, self:ToString())
		or msg == string.format(L["You have slain %s!"], self.translatedName) then
		local function IsBossInCombat()
			local t = module.enabletrigger
			if not t then return false end
			if type(t) == "string" then t = {t} end

			if UnitExists("Target") and UnitAffectingCombat("Target") then
				local target = UnitName("Target")
				for _, mob in pairs(t) do
					if target == mob then
						return true
					end
				end
			end

			local num = GetNumRaidMembers()
			for i = 1, num do
				local raidUnit = string.format("raid%starget", i)
				if UnitExists(raidUnit) and UnitAffectingCombat(raidUnit) then
					local target = UnitName(raidUnit)
					for _, mob in pairs(t) do
						if target == mob then
							return true
						end
					end
				end
			end
			return false
		end

		if not IsBossInCombat() then
			self:SendBossDeathSync()
			self:TriggerEvent("BigWigs_RebootModule", module.translatedName)
		end
	end
end

function module:Event(msg)
	if msg == "add" then
		addDead = addDead + 1
		if addDead <= 4 then
			self:Sync(syncName.addDead .. " " .. addDead)
		end
	end
	--debug
	
	if string.find(msg, L["trigger_selfReflect"]) and self.db.profile.selfreflect and not (string.find(msg, bselementalvulnerability) or string.find(msg, bsfirestrike)) then
		self:SelfReflect()
	end
	
	
	-- Arcane Reflect
	if fireArcaneReflectFound == nil and UnitName("Target") == bbanubisathsentinel and
		string.find(msg, L["trigger_fireArcaneReflect1"]) or
	string.find(msg, L["trigger_fireArcaneReflect2"]) or
	string.find(msg, L["trigger_fireArcaneReflect3"]) or
	string.find(msg, L["trigger_fireArcaneReflect4"]) or
	string.find(msg, L["trigger_fireArcaneReflect5"]) or
	string.find(msg, L["trigger_fireArcaneReflect6"]) then
		if GetRaidTargetIndex("Target") == nil	then raidIcon_fireArcaneReflect = "未标记"		end
		if GetRaidTargetIndex("Target") == 1	then raidIcon_fireArcaneReflect = "星星"		end
		if GetRaidTargetIndex("Target") == 2	then raidIcon_fireArcaneReflect = "大饼"		end
		if GetRaidTargetIndex("Target") == 3	then raidIcon_fireArcaneReflect = "菱形"		end
		if GetRaidTargetIndex("Target") == 4	then raidIcon_fireArcaneReflect = "三角"	end
		if GetRaidTargetIndex("Target") == 5	then raidIcon_fireArcaneReflect = "月亮"		end
		if GetRaidTargetIndex("Target") == 6	then raidIcon_fireArcaneReflect = "方块"		end
		if GetRaidTargetIndex("Target") == 7	then raidIcon_fireArcaneReflect = "叉子"		end
		if GetRaidTargetIndex("Target") == 8	then raidIcon_fireArcaneReflect = "骷髅"		end
		self:Sync(syncName.fireArcaneReflect .. " "..raidIcon_fireArcaneReflect)
	
	elseif fireArcaneReflectFound == nil and UnitName("Target") == bbanubisathsentinel and string.find(msg, L["trigger_fireArcaneReflectOther"]) then
		local _,_, arcaneFireReflectPerson, _ = string.find(msg, L["trigger_fireArcaneReflectOther"])
		for i=1,GetNumRaidMembers() do
			if UnitName("Raid"..i) == arcaneFireReflectPerson then
				if UnitName("Raid"..i.."Target") == bbanubisathsentinel then
					if GetRaidTargetIndex("Raid"..i.."Target")== nil then raidIcon_fireArcaneReflect = "未标记"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 1	then raidIcon_fireArcaneReflect = "星星"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 2	then raidIcon_fireArcaneReflect = "大饼"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 3	then raidIcon_fireArcaneReflect = "菱形"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 4	then raidIcon_fireArcaneReflect = "三角"	end
					if GetRaidTargetIndex("Raid"..i.."Target")== 5	then raidIcon_fireArcaneReflect = "月亮"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 6	then raidIcon_fireArcaneReflect = "方块"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 7	then raidIcon_fireArcaneReflect = "叉子"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 8	then raidIcon_fireArcaneReflect = "骷髅"		end
				end
				break
			end
		end
		self:Sync(syncName.fireArcaneReflect .. " "..raidIcon_fireArcaneReflect)
		
	
	-- Shadow Reflect
	elseif shadowFrostReflectFound == nil and UnitName("Target") == bbanubisathsentinel and
		string.find(msg, L["trigger_shadowFrostReflect1"]) or
	string.find(msg, L["trigger_shadowFrostReflect2"]) or
	string.find(msg, L["trigger_shadowFrostReflect3"]) or
	string.find(msg, L["trigger_shadowFrostReflect4"]) then
		if GetRaidTargetIndex("Target") == nil	then raidIcon_shadowFrostReflect = "未标记"	end
		if GetRaidTargetIndex("Target") == 1	then raidIcon_shadowFrostReflect = "星星"		end
		if GetRaidTargetIndex("Target") == 2	then raidIcon_shadowFrostReflect = "大饼"		end
		if GetRaidTargetIndex("Target") == 3	then raidIcon_shadowFrostReflect = "菱形"	end
		if GetRaidTargetIndex("Target") == 4	then raidIcon_shadowFrostReflect = "三角"	end
		if GetRaidTargetIndex("Target") == 5	then raidIcon_shadowFrostReflect = "月亮"		end
		if GetRaidTargetIndex("Target") == 6	then raidIcon_shadowFrostReflect = "方块"		end
		if GetRaidTargetIndex("Target") == 7	then raidIcon_shadowFrostReflect = "叉子"		end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_shadowFrostReflect = "骷髅"		end
		self:Sync(syncName.shadowFrostReflect .. " "..raidIcon_shadowFrostReflect)
	
		
	elseif shadowFrostReflectFound == nil and UnitName("Target") == bbanubisathsentinel and string.find(msg, L["trigger_shadowFrostReflectOther"]) then
		local _,_, shadowFrostReflectPerson, _ = string.find(msg, L["trigger_shadowFrostReflectOther"])
		for i=1,GetNumRaidMembers() do
			if UnitName("Raid"..i) == shadowFrostReflectPerson then
				if UnitName("Raid"..i.."Target") == bbanubisathsentinel then
					if GetRaidTargetIndex("Raid"..i.."Target")== nil then raidIcon_shadowFrostReflect = "未标记"	end
					if GetRaidTargetIndex("Raid"..i.."Target")== 1	then raidIcon_shadowFrostReflect = "星星"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 2	then raidIcon_shadowFrostReflect = "大饼"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 3	then raidIcon_shadowFrostReflect = "菱形"	end
					if GetRaidTargetIndex("Raid"..i.."Target")== 4	then raidIcon_shadowFrostReflect = "三角"	end
					if GetRaidTargetIndex("Raid"..i.."Target")== 5	then raidIcon_shadowFrostReflect = "月亮"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 6	then raidIcon_shadowFrostReflect = "方块"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 7	then raidIcon_shadowFrostReflect = "叉子"		end
					if GetRaidTargetIndex("Raid"..i.."Target")== 8	then raidIcon_shadowFrostReflect = "骷髅"		end
				end
				break
			end
		end
		self:Sync(syncName.shadowFrostReflect .. " "..raidIcon_shadowFrostReflect)
	end
end

function module:AbilitiesScan()
	if knockBackFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_knockBack"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_knockBack)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_knockBack = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_knockBack = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_knockBack = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_knockBack = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_knockBack = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_knockBack = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_knockBack = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_knockBack = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_knockBack = "骷髅"	end
		
		self:Sync(syncName.knockBack .. " "..raidIcon_knockBack)
	
	elseif manaBurnFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_manaBurn"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_manaBurn)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_manaBurn = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_manaBurn = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_manaBurn = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_manaBurn = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_manaBurn = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_manaBurn = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_manaBurn = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_manaBurn = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_manaBurn = "骷髅"	end
		
		self:Sync(syncName.manaBurn .. " "..raidIcon_manaBurn)
		
		
	elseif mendingFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_mending"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_mending)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_mending = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_mending = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_mending = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_mending = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_mending = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_mending = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_mending = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_mending = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_mending = "骷髅"	end
		
		self:Sync(syncName.mending .. " "..raidIcon_mending)

		
	elseif mortalStrikeFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_mortalStrike"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_mortalStrike)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_mortalStrike = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_mortalStrike = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_mortalStrike = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_mortalStrike = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_mortalStrike = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_mortalStrike = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_mortalStrike = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_mortalStrike = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_mortalStrike = "骷髅"	end
		
		self:Sync(syncName.mortalStrike .. " "..raidIcon_mortalStrike)
		
	
	elseif shadowStormFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_shadowStorm"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_shadowStorm)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_shadowStorm = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_shadowStorm = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_shadowStorm = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_shadowStorm = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_shadowStorm = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_shadowStorm = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_shadowStorm = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_shadowStorm = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_shadowStorm = "骷髅"	end
		
		self:Sync(syncName.shadowStorm .. " "..raidIcon_shadowStorm)
	
	
	elseif thornsFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_thorns"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_thorns)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_thorns = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_thorns = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_thorns = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_thorns = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_thorns = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_thorns = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_thorns = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_thorns = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_thorns = "骷髅"	end
		
		self:Sync(syncName.thorns .. " "..raidIcon_thorns)
	
	
	elseif thunderClapFound == nil and UnitName("Target") == bbanubisathsentinel and UnitBuff("Target",1) == L["buffIcon_thunderClap"] then
		if GetRaidTargetIndex("Target") == nil then 
			if (IsRaidLeader() or IsRaidOfficer()) then
				SetRaidTarget("Target", raidIcon_thunderClap)
			end
		end
		if GetRaidTargetIndex("Target") == nil	then raidIcon_thunderClap = "未标记"	end
		if GetRaidTargetIndex("Target") == 1 	then raidIcon_thunderClap = "星星"		end
		if GetRaidTargetIndex("Target") == 2 	then raidIcon_thunderClap = "大饼"	end
		if GetRaidTargetIndex("Target") == 3 	then raidIcon_thunderClap = "菱形" 	end
		if GetRaidTargetIndex("Target") == 4 	then raidIcon_thunderClap = "三角"	end
		if GetRaidTargetIndex("Target") == 5 	then raidIcon_thunderClap = "月亮"		end
		if GetRaidTargetIndex("Target") == 6 	then raidIcon_thunderClap = "方块"	end
		if GetRaidTargetIndex("Target") == 7 	then raidIcon_thunderClap = "叉子"	end
		if GetRaidTargetIndex("Target") == 8 	then raidIcon_thunderClap = "骷髅"	end
		
		self:Sync(syncName.thunderClap .. " "..raidIcon_thunderClap)
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	rest = normalizeIconName(rest)
	if sync == syncName.knockBack and rest and knockBackFound == nil then
		self:KnockBack(rest)
	elseif sync == syncName.manaBurn and rest and manaBurnFound == nil then
		self:ManaBurn(rest)
	elseif sync == syncName.mending and rest and mendingFound == nil then
		self:Mending(rest)
	elseif sync == syncName.mortalStrike and rest and mortalStrikeFound == nil then
		self:MortalStrike(rest)
	elseif sync == syncName.shadowStorm and rest and shadowStormFound == nil then
		self:ShadowStorm(rest)
	elseif sync == syncName.thorns and rest and thornsFound == nil then
		self:Thorns(rest)
	elseif sync == syncName.thunderClap and rest and thunderClapFound == nil then
		self:ThunderClap(rest)
	
	elseif sync == syncName.fireArcaneReflect and rest and fireArcaneReflectFound == nil then
		self:FireArcaneReflect(rest)
	elseif sync == syncName.shadowFrostReflect and rest and shadowFrostReflectFound == nil then
		self:ShadowFrostReflect(rest)
		
	elseif sync == syncName.addDead and rest then
		self:AddDead(rest)
	end
end


function module:ManaBurn(rest)
	manaBurnFound = true
	
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_manaBurn"], timer.manaBurn, icon.manaBurn, true, color.manaBurn)
		if UnitName("Target") == bbanubisathsentinel and UnitName("TargetTarget") == UnitName("Player") then
			if GetRaidTargetIndex("Target") == nil	and rest == "未标记"	or
			GetRaidTargetIndex("Target") == 1 		and rest == "星星"		or
			GetRaidTargetIndex("Target") == 2 		and rest == "大饼"	or
			GetRaidTargetIndex("Target") == 3 		and rest == "菱形" 	or
			GetRaidTargetIndex("Target") == 4 		and rest == "三角"	or
			GetRaidTargetIndex("Target") == 5 		and rest == "月亮"		or
			GetRaidTargetIndex("Target") == 6 		and rest == "方块"	or
			GetRaidTargetIndex("Target") == 7 		and rest == "叉子"		or
			GetRaidTargetIndex("Target") == 8 		and rest == "骷髅"		then
				self:Message("法力燃烧-拉人 "..rest.." 快走开！", "Urgent", false, nil, false)
			end
		end
	end
end

function module:Mending(rest)
	mendingFound = true
	
	if self.db.profile.abilities then	
		self:Bar(rest .. L["bar_mending"], timer.mending, icon.mending, true, color.mending)
	end
end

function module:MortalStrike(rest)
	mortalStrikeFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_mortalStrike"], timer.mortalStrike, icon.mortalStrike, true, color.mortalStrike)
	end
end

function module:ShadowStorm(rest)
	shadowStormFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_shadowStorm"], timer.shadowStorm, icon.shadowStorm, true, color.shadowStorm)
		if UnitName("Target") == bbanubisathsentinel and UnitName("TargetTarget") == UnitName("Player") then
			if GetRaidTargetIndex("Target") == nil	and rest == "未标记"	or
			GetRaidTargetIndex("Target") == 1 		and rest == "星星"		or
			GetRaidTargetIndex("Target") == 2 		and rest == "大饼"	or
			GetRaidTargetIndex("Target") == 3 		and rest == "菱形" 	or
			GetRaidTargetIndex("Target") == 4 		and rest == "三角"	or
			GetRaidTargetIndex("Target") == 5 		and rest == "月亮"		or
			GetRaidTargetIndex("Target") == 6 		and rest == "方块"	or
			GetRaidTargetIndex("Target") == 7 		and rest == "叉子"		or
			GetRaidTargetIndex("Target") == 8 		and rest == "骷髅"		then
				self:Message("暗影风暴 - 集合 "..rest.." 对施法者！", "Urgent", false, nil, false)
			end
		end
	end
end

function module:Thorns(rest)
	thornsFound = true
	
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_thorns"], timer.thorns, icon.thorns, true, color.thorns)
	end
end

function module:KnockBack(rest)
	knockBackFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_knockBack"], timer.knockBack, icon.knockBack, true, color.knockBack)
	end
end

function module:ThunderClap(rest)
	thunderClapFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_thunderClap"], timer.thunderClap, icon.thunderClap, true, color.thunderClap)
	end
end


function module:FireArcaneReflect(rest)
	fireArcaneReflectFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_fireArcaneReflect"], timer.fireArcaneReflect, icon.fireArcaneReflect, true, color.fireArcaneReflect)
	end
end

function module:ShadowFrostReflect(rest)
	shadowFrostReflectFound = true
		
	if self.db.profile.abilities then
		self:Bar(rest .. L["bar_shadowFrostReflect"], timer.shadowFrostReflect, icon.shadowFrostReflect, true, color.shadowFrostReflect)
	end
end


function module:SelfReflect()
	self:Message(L["msg_selfReflect"], "Personal", false, nil, false)
	self:Sound("Beware")
end

function module:AddDead(rest)
	if tonumber(rest) == 4 then
		self:SendBossDeathSync()
		self:TriggerEvent("BigWigs_RebootModule", module.translatedName)
	end
end
