
local module, L = BigWigs:ModuleDeclaration("Firemaw", "Blackwing Lair")
local bbfiremaw = AceLibrary("Babble-Boss-2.2")["Firemaw"]

module.revision = 30085
module.enabletrigger = module.translatedName
module.toggleoptions = {"wingbuffet", "shadowflame", "sfzonealert", "sfzonebar", "sfexplosion", "flamebuffet", "stacks", "bosskill"}

-- module defaults
module.defaultDB = {
	wingbuffet = true,
	shadowflame = true,
	sfzonealert = true,
	sfzonebar = true,
	sfexplosion = true,
	flamebuffet = false,
	stacks = true,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Firemaw",
	
	wingbuffet_cmd = "wingbuffet",
	wingbuffet_name = "Wing Buffet Alert",
	wingbuffet_desc = "Warn for Wing Buffet",

	shadowflame_cmd = "shadowflame",
	shadowflame_name = "Shadow Flame Alert",
	shadowflame_desc = "Warn for Shadow Flame casts (requires someone to have SuperWoW) and Shadow Flame CD",

	sfzonealert_cmd = "sfzonealert",
	sfzonealert_name = "Shadowflame Zone Alert",
	sfzonealert_desc = "Warns when new floor zones (Shadowflame Jet) spawn",

	sfzonebar_cmd = "sfzonebar",
	sfzonebar_name = "Shadowflame Zone Bar",
	sfzonebar_desc = "Shows timer bars for floor zones (Shadowflame Jet)",

	sfexplosion_cmd = "sfexplosion",
	sfexplosion_name = "Shadowflame Explosion Alert",
	sfexplosion_desc = "Warns when Shadowflame Explosions happen (unsoaked floor zones)",
	
	flamebuffet_cmd = "flamebuffet",
	flamebuffet_name = "Flame Buffet Alert",
	flamebuffet_desc = "Warn for Flame Buffet",
	
	stacks_cmd = "stacks",
	stacks_name = "High Flame Buffet Stacks Alert",
	stacks_desc = "Warn for High Flame Buffet Stacks",
	
	
	trigger_wingBuffet = "Firemaw begins to cast Wing Buffet.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_wingBuffetCast = "Casting Wing Buffet!",
	bar_wingBuffetCd = "Wing Buffet CD",
	msg_wingBuffetCast = "Casting Wing Buffet!",
	msg_wingBuffetSoon = "Wing Buffet in 2 seconds - Taunt now!",
	
	trigger_shadowFlameCast = "Firemaw begins to cast Shadow Flame.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE - seems to no longer appear in logs since 1.18
	bar_shadowFlameCast = "Casting Shadow Flame!",
	msg_shadowFlameCast = "Casting Shadow Flame!",
	trigger_shadowFlameHit = "Firemaw's Shadow Flame hits", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_shadowFlameCd = "Shadow Flame CD",
	
	msg_sfzone = "Look for new Floor Zones!",
	bar_sfzoneFind = "find new Zone(s)",
	bar_sfzone = "soak Floor Zone(s)",
	trigger_sfexplosion = "Shadowflame Jet's Shadowflame Explosion", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE // etc
	warn_sfexplosion = "Unsoaked Zone!",
	
	trigger_flameBuffet = "Firemaw's Flame Buffet", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
		--Firemaw's Flame Buffet fails. (.+) is immune.
		--Firemaw's Flame Buffet was resisted by (.+).
		--Firemaw's Flame Buffet was resisted.
		--Firemaw's Flame Buffet hits (.+) for (.+) Fire damage.
		--Firemaw's Flame Buffet is absorbed by (.+).
		--You absorb Firemaw's Flame Buffet.
	bar_flameBuffet = "Flame Buffet",
	
	trigger_flameBuffetYou = "You are afflicted by Flame Buffet %((.+)%).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	msg_flameBuffetYou = " Flame Buffet Stacks - Consider losing your stacks",
} end)

L:RegisterTranslations("zhCN", function() return {
	cmd = "Firemaw",
	
	wingbuffet_cmd = "wingbuffet",
	wingbuffet_name = "龙翼打击警报",
	wingbuffet_desc = "提示龙翼打击技能",
	
	shadowflame_cmd = "shadowflame",
	shadowflame_name = "暗影烈焰警报",
	shadowflame_desc = "提示暗影烈焰施法（需要有人安装SuperWoW）及暗影烈焰冷却",
	
	sfzonealert_cmd = "sfzonealert",
	sfzonealert_name = "暗影烈焰区域警报",
	sfzonealert_desc = "当新的地面区域（暗影烈焰喷射）出现时发出警告",
	
	sfzonebar_cmd = "sfzonebar",
	sfzonebar_name = "暗影烈焰区域计时条",
	sfzonebar_desc = "显示地面区域（暗影烈焰喷射）的计时条",
	
	sfexplosion_cmd = "sfexplosion",
	sfexplosion_name = "暗影烈焰爆炸警报",
	sfexplosion_desc = "当暗影烈焰爆炸发生时发出警告（未被吸收的地面区域）",
	
	flamebuffet_cmd = "flamebuffet",
	flamebuffet_name = "烈焰打击警报",
	flamebuffet_desc = "提示烈焰打击技能",
	
	stacks_cmd = "stacks",
	stacks_name = "烈焰打击层数过高警报",
	stacks_desc = "烈焰打击层数过高时发出警告",
	
	
	trigger_wingBuffet = "费尔默开始施放龙翼打击",
	bar_wingBuffetCast = "正在施放龙翼打击！",
	bar_wingBuffetCd = "龙翼打击冷却",
	msg_wingBuffetCast = "正在施放龙翼打击！",
	msg_wingBuffetSoon = "2秒后龙翼打击-立即嘲讽！",
	
	trigger_shadowFlameCast = "费尔默开始施放暗影烈焰。",
	bar_shadowFlameCast = "正在施放暗影烈焰！",
	msg_shadowFlameCast = "正在施放暗影烈焰！",
	trigger_shadowFlameHit = "费尔默的暗影烈焰击中",
	bar_shadowFlameCd = "暗影烈焰冷却",
	
	msg_sfzone = "注意新的地面区域！",
	bar_sfzoneFind = "寻找新区域",
	bar_sfzone = "吸收地面区域",
	trigger_sfexplosion = "暗影烈焰喷射的暗影烈焰爆炸",
	warn_sfexplosion = "未吸收的区域！",
	
	trigger_flameBuffet = "费尔默的烈焰打击击中",
		--火喉的烈焰打击未命中。(.+) 免疫。
		--火喉的烈焰打击被 (.+) 抵抗。
		--火喉的烈焰打击被抵抗。
		--火喉的烈焰打击击中 (.+) 造成 (.+) 点火焰伤害。
		--火喉的烈焰打击被 (.+) 吸收。
		--你吸收了火喉的烈焰打击。
	bar_flameBuffet = "烈焰打击",
	
	trigger_flameBuffetYou = "你受到了烈焰打击效果的影响（(%d+)）",
	msg_flameBuffetYou = "烈焰打击层数-考虑清除你的层数",
} end)



local timer = {
	wingBuffetFirstCd = 30,
	wingBuffetCd = 29, --30sec - 1sec cast
	wingBuffetCast = 1,
	
	shadowFlameFirstCd = 16,
	shadowFlameCd = 14, --16 - 2sec cast
	shadowFlameCast = 2,
	
	sfzonePre = 4,
	sfzoneDur = 8,
	
	flameBuffet = {1.913,4.936}, --saw 1.913 to 4.936
}
local icon = {
	wingBuffet = "INV_Misc_MonsterScales_14",
	shadowFlame = "Spell_Fire_Incinerate",
	flameBuffet = "Spell_Fire_Fireball",
	sfzone = "spell_shadow_antishadow",
	sfexplosion = "Spell_Fire_SelfDestruct",
}
local color = {
	wingBuffetCd = "Cyan",
	wingBuffetCast = "Blue",
	
	shadowFlameCd = "Orange",
	shadowFlameCast = "Red",
	sfzone = "Black",
	
	flameBuffet = "Black"
}
local syncName = {
	wingBuffet = "FiremawWingBuffet"..module.revision,
	shadowFlameCast = "FiremawShadowflame"..module.revision,
	shadowFlameHit = "FiremawShadowflameHit"..module.revision,
	sfexplosion = "FiremawShadowflameExplosion"..module.revision,
	flameBuffet = "FiremawFlameBuffet"..module.revision,
}
local spellId = {
	shadowFlame = 22539,
}

local zoneWarned = false

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event") --trigger_flameBuffet, trigger_sfexplosion, trigger_shadowFlameHit
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event") --trigger_flameBuffet, trigger_sfexplosion, trigger_shadowFlameHit
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_wingBuffet, trigger_shadowFlameCast, trigger_flameBuffet, trigger_sfexplosion, trigger_shadowFlameHit
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_flameBuffetYou
	
	if SUPERWOW_VERSION or SetAutoloot then
		self:RegisterEvent("UNIT_CASTEVENT")
	end
	
	self:ThrottleSync(3, syncName.wingBuffet)
	self:ThrottleSync(3, syncName.shadowFlameCast)
	self:ThrottleSync(3, syncName.shadowFlameHit)
	self:ThrottleSync(1.5, syncName.sfexplosion)
	self:ThrottleSync(1.5, syncName.flameBuffet)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	if self.db.profile.wingbuffet then
		self:Bar(L["bar_wingBuffetCd"], timer.wingBuffetFirstCd, icon.wingBuffet, true, color.wingBuffetCd)
		self:DelayedMessage(timer.wingBuffetFirstCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
	end
	
	if self.db.profile.shadowflame then
		self:Bar(L["bar_shadowFlameCd"], timer.shadowFlameCd, icon.shadowFlame, true, color.shadowFlameCd)
	end
	
	if self.db.profile.flamebuffet then
		self:IntervalBar(L["bar_flameBuffet"], timer.flameBuffet[1], timer.flameBuffet[2], icon.flameBuffet, true, color.flameBuffet)
	end
end

function module:OnDisengage()
end

function module:Event(msg)
	if msg == L["trigger_wingBuffet"] then
		self:Sync(syncName.wingBuffet)
	
	elseif msg == L["trigger_shadowFlameCast"] then
		self:Sync(syncName.shadowFlameCast)
	
	elseif string.find(msg, L["trigger_shadowFlameHit"]) then
		self:Sync(syncName.shadowFlameHit)
	
	elseif string.find(msg, L["trigger_sfexplosion"]) then
		self:Sync(syncName.sfexplosion)
	
	elseif string.find(msg, L["trigger_flameBuffet"]) then
		self:Sync(syncName.flameBuffet)
	
	elseif string.find(msg, L["trigger_flameBuffetYou"]) and self.db.profile.stacks then
		local _,_,stacks,_ = string.find(msg, L["trigger_flameBuffetYou"])
		local stacksNum = tonumber(stacks)
		if stacksNum > 4 then
			self:FlameBuffetStacks(stacksNum)
		end
	end
end

function module:UNIT_CASTEVENT(caster,target,action,spell,castTime)
	if spell == spellId.shadowFlame and action == "START" then
		self:Sync(syncName.shadowFlameCast)
		self:DelayedSync(castTime/1000, syncName.shadowFlameHit)
		return
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.wingBuffet and self.db.profile.wingbuffet then
		self:WingBuffet()
	elseif sync == syncName.shadowFlameCast and self.db.profile.shadowflame then
		self:RemoveBar(L["bar_shadowFlameCd"])
		self:Bar(L["bar_shadowFlameCast"], timer.shadowFlameCast, icon.shadowFlame, true, color.shadowFlameCast)
		self:Message(L["msg_shadowFlameCast"], "Urgent", false, nil, false)
	elseif sync == syncName.shadowFlameHit then
		self:ShadowFlameHit()
	elseif sync == syncName.sfexplosion then
		self:ShadowflameExplosion()
	elseif sync == syncName.flameBuffet and self.db.profile.flamebuffet then
		self:FlameBuffet()
	end
end


function module:WingBuffet()
	self:CancelDelayedMessage(L["msg_wingBuffetSoon"])
	self:RemoveBar(L["bar_wingBuffetCd"])
	
	self:Bar(L["bar_wingBuffetCast"], timer.wingBuffetCast, icon.wingBuffet, true, color.wingBuffetCast)
	
	self:DelayedBar(timer.wingBuffetCast, L["bar_wingBuffetCd"], timer.wingBuffetCd, icon.wingBuffet, true, color.wingBuffetCd)
	self:DelayedMessage(timer.wingBuffetCast + timer.wingBuffetCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
end

function module:ShadowFlameHit()
	if self.db.profile.shadowflame then
		self:RemoveBar(L["bar_shadowFlameCd"])

		self:Bar(L["bar_shadowFlameCd"], timer.shadowFlameCd, icon.shadowFlame, true, color.shadowFlameCd)
	end

	if self.db.profile.sfzonealert then
		self:Message(L["msg_sfzone"], "Core")
	end
	if self.db.profile.sfzonebar then
		self:Bar(L["bar_sfzoneFind"], timer.sfzonePre, icon.sfzone, true, color.sfzone)
		self:DelayedBar(timer.sfzonePre, L["bar_sfzone"], timer.sfzoneDur, icon.sfzone, true, color.sfzone)
	end
	zoneWarned = false
end

function module:FlameBuffet()
	self:IntervalBar(L["bar_flameBuffet"], timer.flameBuffet[1], timer.flameBuffet[2], icon.flameBuffet, true, color.flameBuffet)
end

function module:FlameBuffetStacks(stacksNum)
	--don't bother if you are tanking
	if UnitName("Target") == bbfiremaw and UnitName("TargetTarget") == UnitName("Player") then return end
	
	self:Message(stacksNum..L["msg_flameBuffetYou"], "Personal", false, nil, false)
	self:WarningSign(icon.flameBuffet, 0.7)
	self:Sound("Info")
end

function module:ShadowflameExplosion()
	if self.db.profile.sfexplosion then	 
		self:WarningSign(icon.sfexplosion, 1, false, L["warn_sfexplosion"])
		if zoneWarned then
			self:Sound("Alarm")
		else
			self:Sound("Beware")
			zoneWarned = true
		end
	end
end
