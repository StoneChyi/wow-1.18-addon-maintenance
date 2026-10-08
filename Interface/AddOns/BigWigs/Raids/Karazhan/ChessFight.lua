local module, L = BigWigs:ModuleDeclaration("King", "Karazhan")

-- module variables
module.revision = 30004
module.enabletrigger = module.translatedName
module.toggleoptions = { "kingsfury", "kingscursecd", "voidzone", "voidzonedamage", -1, "subservienceyou", "subservienceothers", "subserviencecast", "marksubservience", "decursebow", "throttlebow", "charmingpresence", "markmindcontrol", -1, "knightsglory", "bishoptonguesalert", "bishopvolley", "empoweredsb", -1, "cleave", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}
module.wipemobs = { "Knight", "Bishop", "Rook" }

local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")
local BS = AceLibrary("Babble-Spell-2.2")

-- module defaults
module.defaultDB = {
	kingsfury = true,
	kingscursecd = true,
	voidzone = true,
	voidzonedamage = true,
	subservienceyou = true,
	subservienceothers = true,
	charmingpresence = playerClass == BC["SHAMAN"],
	subserviencecast = playerClass == BC["SHAMAN"],
	marksubservience = true,
	decursebow = playerClass == BC["Mage"] or playerClass == BC["DRUID"],
	throttlebow = true,
	markmindcontrol = true,
	knightsglory = false,
	bishoptonguesalert = false,
	bishopvolley = false,
	empoweredsb = false,
	cleave = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "ChessEvent",

		kingsfury_cmd = "kingsfury",
		kingsfury_name = "King's Fury Alert",
		kingsfury_desc = "Warns when the King begins to cast King's Fury",

		kingscursecd_cmd = "kingscursecd",
		kingscursecd_name = "King's Curse Cooldown",
		kingscursecd_desc = "Shows a timer bar about the earliest possible King's Curse (41-50s)",

		voidzone_cmd = "voidzone",
		voidzone_name = "Void Zone Cast Alert",
		voidzone_desc = "Warns the target when King casts Blunder (Void Zone) and makes them announce to /say",

		voidzonedamage_cmd = "voidzonedamage",
		voidzonedamage_name = "Void Zone Damage Alert",
		voidzonedamage_desc = "Warns when you take damage from Void Zones (Consumption)",

		subservienceyou_cmd = "subservienceyou",
		subservienceyou_name = "Dark Subservience on You",
		subservienceyou_desc = "Warns when you are afflicted by Dark Subservience or when the Queen is casting it on you",

		subservienceothers_cmd = "subservienceothers",
		subservienceothers_name = "Dark Subservience on Others",
		subservienceothers_desc = "Warns when others are afflicted by Dark Subservience",

		subserviencecast_cmd = "subserviencecast",
		subserviencecast_name = "Dark Subservience Casts",
		subserviencecast_desc = "Shows incoming cast messages for Dark Subservience (for Grounding Totem)",

		marksubservience_cmd = "marksubservience",
		marksubservience_name = "Mark Subservience Target",
		marksubservience_desc = "Marks players affected by Dark Subservience with Skull raid icon (requires assistant or leader)",

		decursebow_cmd = "decursebow",
		decursebow_name = "Decurse Reminder for Bowing Players",
		decursebow_desc = "Shows a notification with decurse button for players who need to bow",

		throttlebow_cmd = "throttlebow",
		throttlebow_name = "Throttle /bow",
		throttlebow_desc = "Throttle the Visual Display of other people's /bow",

		charmingpresence_cmd = "charmingpresence",
		charmingpresence_name = "Charming Presence Timer",
		charmingpresence_desc = "Shows a timer for when the Queen will cast Charming Presence",

		markmindcontrol_cmd = "markmindcontrol",
		markmindcontrol_name = "Mark Mind Controlled Target",
		markmindcontrol_desc = "Marks players affected by King's Curse with X raid icon (requires assistant or leader)",

		knightsglory_cmd = "knightsglory",
		knightsglory_name = "Knight's Glory Alert",
		knightsglory_desc = "Warns when King or Bishop gain Knight's Glory (15yd proximity aura, +50% cast speed)",

		bishoptonguesalert_cmd = "bishoptonguesalert",
		bishoptonguesalert_name = "Bishop Curse of Tongues Alert",
		bishoptonguesalert_desc = "Alerts when the Bishop needs Curse of Tongues applied",

		bishopvolley_cmd = "bishopvolley",
		bishopvolley_name = "Bishop Shadow Bolt Volley Alert",
		bishopvolley_desc = "Shows an accurate timer bar when Bishop is casting Shadow Bolt Volley",

		empoweredsb_cmd = "empoweredsb",
		empoweredsb_name = "Bishop Empowered Shadow Bolt Alert",
		empoweredsb_desc = "Warns when Bishop begins to cast an Empowered Shadow Bolt so the tank can back off",

		cleave_cmd = "cleavealert",
        cleave_name = "Cleave Alert",
        cleave_desc = "Alerts when a player is hit by the Knight's Glory Cleave",

        trigger_cleave = "Knight's Glorious Cleave hits you",
        warn_cleave = "Cleave",

		trigger_kingCastFury = "King begins to cast KingFury", -- they used special character apostrophe for this and queen's Fury
		trigger_voidzone = "King casts Blunder.",		
		trigger_voidzoneDamage = "Consumption hits you for",

		trigger_subservienceYou = "You are afflicted by Dark Subservience",
		trigger_subservienceOther = "(.+) is afflicted by Dark Subservience",
		trigger_subservienceFade = "Dark Subservience fades from (.+)",
		trigger_subservienceFailed = "Dark Subservience fails. Grounding Totem", --not observed in logs since April 2025

		trigger_kingscurseYou = "You are afflicted by King's Curse", --unused
		trigger_kingscurseOther = "(.+) is afflicted by King's Curse",
		trigger_kingscurseFade = "King's Curse fades from (.+)",

		trigger_charmingPresenceYou = "You are afflicted by Charming Presence",
		trigger_charmingPresenceOther = "(.+) is afflicted by Charming Presence",
		trigger_charmingPresenceFade = "Charming Presence fades from (.+)",

		trigger_knightsGloryGain = "(.+) gains Knight",
		trigger_knightsGloryFade = "Glory fades from (.+)%.",
		trigger_tonguesGain = "(.+) gains Curse of Tongues",
		trigger_tonguesAfflicted = "(.+) is afflicted by Curse of Tongues",
		trigger_tonguesFade = "Curse of Tongues fades from (.+)%.",
		
		trigger_bishopVolleyCast = "Bishop begins to cast Shadow Bolt Volley",
		trigger_empoweredCast = "Bishop begins to cast Empowered Shadow Bolt",

		msg_kingCastFury = "King's Fury! - go hide",
		msg_kingCastFuryFast = "Hasted King's Fury! - HIDE",
		msg_kingFurySafe = "Safe!",
		msg_voidzone = "Void Zone MOVE!",
		say_voidzone = "Void Zone On Me!",

		msg_subservienceYou = "YOU need to go Bow to the Queen!",
		msg_subservienceOther = "%s needs to go Bow!",
		msg_queenCastingSubservience = "Queen began casting on %s!",
		msg_queenCastingSubservienceYou = "Dark Subservience incoming! Get ready to /bow (unless grounded).",
		msg_queenSubservienceTotem = "Totem ate cast instead of %s!",
		msg_queenSubservienceTotemYou = "Safe from /bow! Totem ate cast.",

		warning_bow = "BOW TO THE QUEEN!",
		warn_kingsfury = "HIDE",

		bar_subservience = "Go right in front of Queen and Bow! >Click Me<",
		bar_kingsfury = "King's Fury - Hide!",
		bar_charmingpresence = "Next Charming Presence",
		bar_decursebow = "Decurse %s >Click Me<",
		bar_curseCD = "possible King's Curse",

		bishop_name = "Bishop",
		bishop_needsTongues = "Bishop needs Curse of Tongues!",
		
		msg_gloryGain = "Knight too close to the %s!",
		msg_gloryFade = "Knight far enough away from the %s",
		
		bar_bishopVolley = "Volley incoming",
		msg_bishopVolley = "Shadow Bolt Volley incoming",
		msg_empoweredCast = "Empowered SB casting - tank too close!",

		trigger_kingsFuryHit = "Fury hits (.+) for (.+) Holy damage.",
		trigger_subservienceHit = "(.+) suffers (.+) Shadow damage from Queen's Dark Subservience",
	}
end)

-- localization
L:RegisterTranslations("zhCN", function()
	return {
		cmd = "ChessEvent",

		kingsfury_cmd = "kingsfury",
		kingsfury_name = "国王之怒警报",
		kingsfury_desc = "当国王开始施放国王之怒时发出警告",

		kingscursecd_cmd = "kingscursecd",
        kingscursecd_name = "国王诅咒冷却计时",
        kingscursecd_desc = "显示下一次可能施放国王诅咒的计时条（41-50秒）",

        voidzone_cmd = "voidzone",
        voidzone_name = "虚空区域施法警报",
        voidzone_desc = "当国王施放失策（虚空区域）时警告目标，并让他们通过/say频道宣告",

        voidzonedamage_cmd = "voidzonedamage",
        voidzonedamage_name = "虚空区域伤害警报",
        voidzonedamage_desc = "当受到虚空区域伤害时发出警告",

		subservienceyou_cmd = "subservienceyou",
	    subservienceyou_name = "你的黑暗屈从",
	    subservienceyou_desc = "当你受到黑暗屈从影响或皇后对你施放该技能时发出警报",

	    subservienceothers_cmd = "subservienceothers",
	    subservienceothers_name = "其他人的黑暗屈从",
	    subservienceothers_desc = "当其他人受到黑暗屈从影响时发出警报",

	    subserviencecast_cmd = "subserviencecast",
	    subserviencecast_name = "黑暗屈从施法警报",
	    subserviencecast_desc = "显示黑暗屈从的施法信息（用于根基图腾）",

		marksubservience_cmd = "marksubservience",
		marksubservience_name = "标记被屈从的目标",
		marksubservience_desc = "用骷髅标记受黑暗屈从影响的玩家（需要助理或团长权限）",

		decursebow_cmd = "decursebow",
		decursebow_name = "下跪玩家的解诅咒提醒",
		decursebow_desc = "为需要下跪的玩家显示带有解诅咒按钮的通知",

		throttlebow_cmd = "throttlebow",
		throttlebow_name = "限制下跪动作显示",
		throttlebow_desc = "限制其他人下跪动作的视觉显示",

		charmingpresence_cmd = "charmingpresence",
	    charmingpresence_name = "魅惑之心计时器",
	    charmingpresence_desc = "显示皇后将施放魅惑之心的时间",

	    markmindcontrol_cmd = "markmindcontrol",
	    markmindcontrol_name = "标记被心控的玩家",
	    markmindcontrol_desc = "用X团队图标标记被心控的玩家（需要助理或团长权限）",

	    knightsglory_cmd = "knightsglory",
	    knightsglory_name = "骑士荣耀光环警报",
	    knightsglory_desc = "当国王或主教获得骑士荣耀时发出警报（15码光环，+50%施法速度）",

	    bishoptonguesalert_cmd = "bishoptonguesalert",
	    bishoptonguesalert_name = "主教语言诅咒警报",
	    bishoptonguesalert_desc = "当主教需要上语言诅咒时发出警报",

	    bishopvolley_cmd = "bishopvolley",
	    bishopvolley_name = "主教暗影箭雨警报",
	    bishopvolley_desc = "显示主教施放暗影箭雨的精确计时条",

	    empoweredsb_cmd = "empoweredsb",
	    empoweredsb_name = "主教强化暗影箭警报",
	    empoweredsb_desc = "当主教开始施放强化暗影箭时发出警报，以便坦克后退",

		cleave_cmd = "cleavealert",
		cleave_name = "光荣顺劈警报",
		cleave_desc = "当玩家被骑士光荣顺劈时发出警报",

		trigger_cleave = "骑士的光荣顺劈击中你", 
		warn_cleave = "顺劈斩",

		trigger_kingCastFury = "国王开始施放国王之怒", -- they used special character apostrophe for this and queen's Fury
		trigger_voidzone = "国王施放了罪孽深重",		
		trigger_voidzoneDamage = "虚空地区的吞噬击中你造成",

		trigger_subservienceYou = "^你受到了黑暗屈从效果的影响",
		trigger_subservienceOther = "(.+)受到了黑暗屈从效果的影响",
		trigger_subservienceFade = "黑暗屈从效果从(.+)身上消失",
		trigger_subservienceFailed = "皇后的黑暗屈从施放失败",

		trigger_kingscurseYou = "^你受到了国王的诅咒效果的影响",
		trigger_kingscurseOther = "(.+)受到了国王的诅咒效果的影响",
		trigger_kingscurseFade = "国王的诅咒效果从(.+)身上消失",

		trigger_charmingPresenceYou = "^你受到了魅惑之心效果的影响",
		trigger_charmingPresenceOther = "(.+)受到了魅惑之心效果的影响",
		trigger_charmingPresenceFade = "魅惑之心效果从(.+)身上消失",

	    trigger_knightsGloryGain = "(.+)获得了骑士的荣耀的效果",
	    trigger_knightsGloryFade = "骑士的荣耀效果从(.+)身上消失",
	    trigger_tonguesGain = "(.+)获得了语言诅咒的效果",
	    trigger_tonguesAfflicted = "(.+)受到了语言诅咒效果的影响",
	    trigger_tonguesFade = "语言诅咒效果从(.+)身上消失",
	
	    trigger_bishopVolleyCast = "主教开始施放暗影箭雨",
	    trigger_empoweredCast = "主教开始施放魔能暗影箭",

	    msg_kingCastFury = "国王之怒-躲避",
	    msg_kingCastFuryFast = "加速！国王之怒-快躲",
	    msg_kingFurySafe = "安全！",
	    msg_voidzone = "黑水-快躲开！",
	    say_voidzone = "黑水在我身上!",

	    msg_subservienceYou = "你要向皇后下跪！",
	    msg_subservienceOther = "%s去下跪！",
	    msg_queenCastingSubservience = "皇后开始对%s施法！",
	    msg_queenCastingSubservienceYou = "黑暗屈从即将到来！",
	    msg_queenSubservienceTotem = "图腾替%s吸收了施法！",
	    msg_queenSubservienceTotemYou = "无需下跪！图腾吸收了施法",

	    warning_bow = "向皇后下跪！",
	    warn_kingsfury = "躲避",

	    bar_subservience = "立刻到皇后面前下跪！>点击我<",
	    bar_kingsfury = "国王之怒-躲避！",
	    bar_charmingpresence = "下一次魅惑之心",
	    bar_decursebow = "为%s解诅咒>点击我<",
	    bar_curseCD = "可能的国王诅咒",

	    bishop_name = "主教",
	    bishop_needsTongues = "主教需要语言诅咒！",
	
	    msg_gloryGain = "骑士离%s太近了！",
	    msg_gloryFade = "骑士已远离%s",
	
	    bar_bishopVolley = "箭雨即将到来",
	    msg_bishopVolley = "暗影箭雨即将到来",
	    msg_empoweredCast = "正在施放魔能暗影箭-坦克太近了！",

	    trigger_kingsFuryHit = "国王的国王之怒击中(.+)造成(.+)点神圣伤害。",
	    trigger_subservienceHit = "皇后的黑暗屈从使(.+)受到了(.+)点暗影伤害",
	}
end)


-- timer and icon variables
local timer = {
	subservience = 8, -- duration of subservience debuff
	kingsfury = 5, -- duration of king's fury cast
	charmingpresence = 12, -- queen casts every 12 seconds
	throttlebow = 1.5, -- bow throttle rate
	bishopScan = 5, -- check bishop debuffs every 5 seconds
	voidzone = 2, -- duration for void zone warning sign
	sbvolley = 3, --base cast time of Shadow Bolt Volley
	cursecd = {41,50}, --based on logs, removing outliers directly after Fury
	cleave = 1,
}

local icon = {
	subservience = "Spell_BrokenHeart", -- icon for subservience
	kingsfury = "Spell_Holy_HolyNova", -- icon for king's fury
	charmingpresence = "Spell_Shadow_ShadowWordDominate", -- icon for charming presence
	kingscurse = "Spell_Shadow_GrimWard", -- icon for King's curse
	voidzone = "spell_shadow_antishadow", -- icon for void zone
	sbvolley = "Spell_Shadow_ShadowBolt",
	cleave = "Ability_Warrior_Cleave",
}

local kingsCurseTexture = "Interface\\Icons\\Spell_Shadow_GrimWard"

local syncName = {
	subservience = "ChessSubservience" .. module.revision,
	queenCastingSubservience = "ChessQueenCastingSubservience" .. module.revision,
	kingCastFury = "ChessKingCastFury" .. module.revision,
	subservienceFailed = "ChessSubservienceFailed" .. module.revision,
	charmingPresence = "ChessCharmingPresence" .. module.revision,
	bishopNoCurse = "ChessBishopNoCurse" .. module.revision,
	voidzone = "ChessVoidZone" .. module.revision,
	kingGloryGain = "ChessKingGloryGain" .. module.revision,
	kingGloryFade = "ChessKingGloryFade" .. module.revision,
	bishopGloryGain = "ChessBishopGloryGain" .. module.revision,
	bishopGloryFade = "ChessBishopGloryFade" .. module.revision,
	bishopTonguesGain = "ChessBishopTonguesGain" .. module.revision,
	bishopTonguesFade = "ChessBishopTonguesFade" .. module.revision,
	sbvolleyCast = "ChessSbvolleyCast" .. module.revision,
	curseHappened = "ChessCurseHappened" .. module.revision,
}

local spellIds = {
	subservience = 41647, -- Dark Subservience
	charmingpresence = 41644,
	kingscurse = 41635,
	blunder = 52667, -- Void Zone
	tongues = 11719, -- Curse of Tongues rank 2
}

local bowed = {}
local bishopHasTongues = 0
local bishopHasGlory = 0
local kingHasGlory = 0
local scanTargets = {}
local lastVoidzoneSound = 0

local baseChatFrameOnEvent = ChatFrame_OnEvent

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", "AfflictionEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "FadesEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadesEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "SpellEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "EnemyDebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "EnemyDebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")

	if self.db.profile.bishoptonguesalert then
		self:ScheduleRepeatingEvent("BishopDebuffScan", self.ScanBishopDebuffs, timer.bishopScan, self)
	end

	-- install wrapper exactly once
	if not self.origChatFrameOnEvent and self.db.profile.throttlebow then
		self.origChatFrameOnEvent = ChatFrame_OnEvent

		ChatFrame_OnEvent = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			local msg, who = arg1, arg2

			if not self.origChatFrameOnEvent then
				-- something went wrong, just call the original function
				baseChatFrameOnEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
				ChatFrame_OnEvent = baseChatFrameOnEvent
				return
			end

			-- only throttle OTHER players’ /bow emote when we’re engaged
			if self.engaged and event == "CHAT_MSG_TEXT_EMOTE" and who ~= UnitName("player") and string.find(msg, "^.-在皇后面前跪下") then
				local now = GetTime()
				if not bowed[who] or now - bowed[who] >= timer.throttlebow then
					bowed[who] = now
					self.origChatFrameOnEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
				end
			else
				-- everything else goes through as normal
				self.origChatFrameOnEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			end
		end
	end

	if SUPERWOW_VERSION then
		self:RegisterCastEventsForUnitName("Queen", "QueenCastEvent")
		self:RegisterCastEventsForUnitName("皇后", "QueenCastEvent")
		self:RegisterCastEventsForUnitName("King", "KingCastEvent")
		self:RegisterCastEventsForUnitName("国王", "KingCastEvent")
	end

	self:ThrottleSync(1, syncName.subservience)
	self:ThrottleSync(2, syncName.queenCastingSubservience)
	self:ThrottleSync(2, syncName.kingCastFury)
	self:ThrottleSync(2, syncName.subservienceFailed)
	self:ThrottleSync(2, syncName.charmingPresence)
	self:ThrottleSync(2, syncName.bishopNoCurse)
	self:ThrottleSync(2, syncName.voidzone)
	self:ThrottleSync(1, syncName.kingGloryGain)
	self:ThrottleSync(1, syncName.kingGloryFade)
	self:ThrottleSync(1, syncName.bishopGloryGain)
	self:ThrottleSync(1, syncName.bishopGloryFade)
	self:ThrottleSync(2, syncName.bishopTonguesGain)
	self:ThrottleSync(2, syncName.bishopTonguesFade)
	self:ThrottleSync(5, syncName.sbvolleyCast)
	self:ThrottleSync(5, syncName.curseHappened)
	self:Message("友情提示：佩戴徽章/骑士正面顺劈斩", "Important", false, nil, false)
end

function module:OnSetup()
	self.started = nil
end

function module:OnDisable()
	if self.origChatFrameOnEvent and self.db.profile.throttlebow then
		-- remove the wrapper
		ChatFrame_OnEvent = self.origChatFrameOnEvent
		self.origChatFrameOnEvent = nil
	end
end

function module:OnEngage()
	bowed = {}
	bishopHasTongues = 0
	bishopHasGlory = 0
	kingHasGlory = 0

	self.queenTarget = ""
end

function module:OnDisengage()
	self:CancelScheduledEvent("BishopDebuffScan")
end

function module:QueenCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	if spellId == spellIds.subservience and eventType == "START" then
		self.queenTarget = UnitName(targetGuid) or ""
		self:Sync(syncName.queenCastingSubservience .. " " .. self.queenTarget)
	elseif spellId == spellIds.charmingpresence and eventType == "CAST" then
		self:Sync(syncName.charmingPresence)
	end
end

function module:KingCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	if spellId == spellIds.blunder and eventType == "CAST" then
		self.voidZoneTarget = UnitName(targetGuid) or ""
	    self:Sync(syncName.voidzone .. " " .. self.voidZoneTarget) 
	end
end

function module:Event(msg)
	if string.find(msg, L["trigger_cleave"]) and self.db.profile.cleave then
		self:Cleave()
	end	
end

function module:SpellEvent(msg)
	if string.find(msg, L["trigger_subservienceFailed"]) and self.queenTarget ~= "" then
		self:Sync(syncName.subservienceFailed .. " " .. self.queenTarget)
	elseif string.find(msg, L["trigger_kingCastFury"]) then
		self:Sync(syncName.kingCastFury)
	elseif string.find(msg, L["trigger_bishopVolleyCast"]) then
		self:Sync(syncName.sbvolleyCast)
	elseif self.db.profile.empoweredsb and string.find(msg, L["trigger_empoweredCast"]) then
		self:Message(L["msg_empoweredCast"], "Urgent", nil, "Info")
	elseif self.db.profile.voidzonedamage and string.find(msg, L["trigger_voidzoneDamage"]) then
		self:VoidZoneAlert()	
	end
end

function module:AfflictionEvent(msg)
	-- Dark Subservience
	if string.find(msg, L["trigger_subservienceYou"]) then
		local player = UnitName("player")
		self:Subservience(player) -- let's not miss a sync
		self:Sync(syncName.subservience .. " " .. player)
		return
	else
		local _, _, player = string.find(msg, L["trigger_subservienceOther"])
		if player then
			self:Sync(syncName.subservience .. " " .. player)
			return
		end
	end
	-- Charming Presence
	local _, _, player = string.find(msg, L["trigger_charmingPresenceOther"])
	if string.find(msg, L["trigger_charmingPresenceYou"]) then
		player = UnitName("player")
	end
	if player and self.db.profile.markmindcontrol then
		-- Mark the player with X raid target
		self:SetRaidTargetForPlayer(player, 7) -- X
		return
	end
	
	-- King's Curse on anyone (just for timing the CD)
	if string.find(msg, L["trigger_kingscurseOther"]) then
		self:Sync(syncName.curseHappened)
		return
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	if string.find(msg, L["trigger_subservienceFade"]) then
		self:RemoveBar(L["bar_subservience"])
		self:RemoveWarningSign(icon.subservience, true)
		self:Sound("Long")

		if self.db.profile.marksubservience then
			self:RestorePreviousRaidTargetForPlayer(UnitName("player"))
		end
	elseif string.find(msg, L["trigger_kingscurseFade"]) then
		local player = UnitName("player")
		self:RemoveBar(string.format(L["bar_decursebow"], player))
	end
end

function module:EnemyDebuffEvent(msg)
	-- Knight's Glory
	local _,_,mob = string.find(msg, L["trigger_knightsGloryGain"])
	if mob then
		if mob == module.translatedName then
			self:Sync(syncName.kingGloryGain)
		elseif mob == L["bishop_name"] then
			self:Sync(syncName.bishopGloryGain)
		end
		return
	end
	
	-- Curse of Tongues
	_,_,mob = string.find(msg, L["trigger_tonguesAfflicted"])
	if mob and mob == L["bishop_name"] then
		self:Sync(syncName.bishopTonguesGain)
		return
	end
	_,_,mob = string.find(msg, L["trigger_tonguesGain"])
	if mob and mob == L["bishop_name"] then
		self:Sync(syncName.bishopTonguesGain)
		return
	end
end

function module:FadesEvent(msg)
	local _, _, player = string.find(msg, L["trigger_kingscurseFade"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:RemoveBar(string.format(L["bar_decursebow"], player))
		return
	end

	_, _, player = string.find(msg, L["trigger_subservienceFade"])
	if player then
		if player == "你" then
			self:RemoveBar(L["bar_subservience"])
			self:RemoveWarningSign(icon.subservience, true)
			self:Sound("Long")
			player = UnitName("player")
		end
		if self.db.profile.marksubservience then
			self:RestorePreviousRaidTargetForPlayer(player)
		end
		self:RemoveBar(string.format(L["bar_decursebow"], player))
		return
	end

	_, _, player = string.find(msg, L["trigger_charmingPresenceFade"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:CharmingPresenceOver(player)
		return
	end
	
	_, _, player = string.find(msg, L["trigger_knightsGloryFade"])
	if player then
		if player == module.translatedName then
			self:Sync(syncName.kingGloryFade)
		elseif player == L["bishop_name"] then
			self:Sync(syncName.bishopGloryFade)
		end
		return
	end
	
	_, _, player = string.find(msg, L["trigger_tonguesFade"])
	if player and player == L["bishop_name"] then
		self:Sync(syncName.bishopTonguesFade)
		return
	end
end

function module:OnFriendlyDeath(msg)
	local _, _, player = string.find(msg, "(.+)死亡了")
	if player then
		-- Remove raid marks for players who die
		if self.db.profile.marksubservience then
			self:RestorePreviousRaidTargetForPlayer(player)
		end
		self:CharmingPresenceOver(player)
		self:RemoveBar(string.format(L["bar_decursebow"], player))
	end
end

function module:CharmingPresenceOver(player)
	if self.db.profile.markmindcontrol then
		self:RestorePreviousRaidTargetForPlayer(player)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.subservience and rest and rest ~= UnitName("player") then
		self:Subservience(rest)
	elseif sync == syncName.queenCastingSubservience then
		self:QueenCastingSubservience(rest)
	elseif sync == syncName.kingCastFury then
		self:KingCastFury()
	elseif sync == syncName.subservienceFailed and rest then
		self:SubservienceFailed(rest)
	elseif sync == syncName.charmingPresence then
		if self.db.profile.charmingpresence then
			self:StartCharmingPresenceTimer()
		end
	elseif sync == syncName.bishopNoCurse then
		self:BishopNeedsCurseOfTongues()
	elseif sync == syncName.voidzone and rest then
		self:VoidZoneCast(rest)
	elseif sync == syncName.kingGloryGain then
		kingHasGlory = 1
		if self.db.profile.knightsglory then
			self:Message(string.format(L["msg_gloryGain"], module.translatedName), "Urgent", nil, "Beware")
		end
	elseif sync == syncName.kingGloryFade then
		kingHasGlory = 0
		if self.db.profile.knightsglory then
			self:Message(string.format(L["msg_gloryFade"], module.translatedName), "Positive", true, "Alert")
		end
	elseif sync == syncName.bishopGloryGain then
		bishopHasGlory = 1
		if self.db.profile.knightsglory then
			self:Message(string.format(L["msg_gloryGain"], L["bishop_name"]), "Urgent", nil, "Info")
		end
	elseif sync == syncName.bishopGloryFade then
		bishopHasGlory = 0
		if self.db.profile.knightsglory then
			self:Message(string.format(L["msg_gloryFade"], L["bishop_name"]), "Positive", nil, "Alert")
		end
	elseif sync == syncName.bishopTonguesGain then
		bishopHasTongues = 1
	elseif sync == syncName.bishopTonguesFade then
		bishopHasTongues = 0
	elseif sync == syncName.sbvolleyCast then
		self:ShadowBoltVolley()
	elseif sync == syncName.curseHappened then
		self:CurseHappened()
	end
end

function module:StartCharmingPresenceTimer()
	if not self.db.profile.charmingpresence then
		return
	end

	self:Bar(L["bar_charmingpresence"], timer.charmingpresence, icon.charmingpresence)
end

function module:QueenCastingSubservience(playerName)
	self.queenTarget = playerName
	if playerName == UnitName("player") and self.db.profile.subservienceyou then
		self:Message(L["msg_queenCastingSubservienceYou"], "Urgent", true, "Beware")
	elseif self.db.profile.subserviencecast then
		self:Message(string.format(L["msg_queenCastingSubservience"], playerName), "Attention", nil, "Info")
	end	
end

function module:SubservienceFailed(playerName) --might be defunct
	if playerName == UnitName("player") and self.db.profile.subservienceyou then
		self:Message(L["msg_queenSubservienceTotemYou"], "Positive", true, "Long")
	elseif self.db.profile.subserviencecast then
		self:Message(string.format(L["msg_queenSubservienceTotem"], playerName), "Positive", true, false)
	end	
end

function module:Subservience(player)
	if player == UnitName("player") and self.db.profile.subservienceyou then
		self:Message(L["msg_subservienceYou"], "Important", true)
		self:WarningSign(icon.subservience, timer.subservience, true, L["warning_bow"])
		self:Bar(L["bar_subservience"], timer.subservience, icon.subservience)
        self:Sound("xiagui")
		-- Set the bar to target Queen and bow when clicked
		self:SetCandyBarOnClick("BigWigsBar " .. L["bar_subservience"], function()
			TargetByName("皇后", true)
			DoEmote("下跪")
		end)
	else --Subservience on others
		-- Check for King's Curse directly if decursebow is enabled
		if self.db.profile.decursebow then
			-- Find the player in raid
			local raidTarget = nil
			for i = 1, 40 do
				if UnitExists("raid" .. i) and UnitName("raid" .. i) == player then
					raidTarget = "raid" .. i
					break
				end
			end

			-- If found, check for King's Curse debuff
			if raidTarget then
				for i = 1, 16 do
					local texture = UnitDebuff(raidTarget, i)
					if texture then
						if texture == kingsCurseTexture then
							-- Player has King's Curse, show decurse reminder
							self:DecurseReminder(player, raidTarget)
							break
						end
					else
						break
					end
				end
			end
		end
		
		-- Post warning message if enabled
		if self.db.profile.subservienceothers then
			self:Message(string.format(L["msg_subservienceOther"], player), "Important")
		end		
	end

	if self.db.profile.marksubservience then
		self:SetRaidTargetForPlayer(player, 8) -- Skull
	end
end

function module:DecurseReminder(player, raidTarget)
	if not self.db.profile.decursebow then
		return
	end

	-- Create a bar with decurse functionality
	local barText = string.format(L["bar_decursebow"], player)
	self:Bar(barText, timer.subservience, icon.kingscurse)

	-- Set the bar to target player and cast Remove Curse when clicked
	self:SetCandyBarOnClick("BigWigsBar " .. barText, function(name, button, playerName, target)
		if SUPERWOW_VERSION or SetAutoloot then
			if playerClass == BC["MAGE"] then
				CastSpellByName("解除次级诅咒", target)
			elseif playerClass == BC["DRUID"] then
				CastSpellByName("解除诅咒", target)
			end
		else
			TargetByName(playerName, true)
			if playerClass == BC["MAGE"] then
				CastSpellByName("解除次级诅咒")
			elseif playerClass == BC["DRUID"] then
				CastSpellByName("解除诅咒")
			end
		end
	end, player, raidTarget)
end


function module:KingCastFury()
	if not self.db.profile.kingsfury then
		return
	end
	if kingHasGlory == 1 then
		self:Message(L["msg_kingCastFuryFast"], "Attention", nil, "Beware")
	else
		self:Message(L["msg_kingCastFury"], "Attention", nil, "Hide")
	end
	local castTime = timer.kingsfury / (1 + (0.5 * kingHasGlory))
	self:Bar(L["bar_kingsfury"], castTime, icon.kingsfury)
	self:WarningSign(icon.kingsfury, castTime, true, L["warn_kingsfury"])
	self:DelayedMessage(castTime+0.2, L["msg_kingFurySafe"], "Positive", nil, "Long")
end

function module:VoidZoneCast(player)
	if not self.db.profile.voidzone then
		return
	end

	if player == UnitName("player") then
		self:VoidZoneAlert()
		SendChatMessage(L["say_voidzone"], "SAY")
	end
end

function module:VoidZoneAlert()
	self:Message(L["msg_voidzone"], "Important", true, false)
	self:WarningSign(icon.voidzone, timer.voidzone, true, L["msg_voidzone"])
	if GetTime() > lastVoidzoneSound + 5 then
		self:Sound("heishui")
		lastVoidzoneSound = GetTime()
	else
		self:Sound("Info")
	end
end

function module:ScanBishopDebuffs()
	-- Check if current target is Bishop
	if UnitName("target") == L["bishop_name"] then
		-- Scan debuffs
		for i = 1, 16 do
			local texture = UnitDebuff("target", i)
			if texture and string.find(texture, "Spell_Shadow_CurseOfTounges") then
				-- Found Curse of Tongues debuff
				return
			elseif not texture then
				break
			end
		end

		-- Scan buffs
		for i = 1, 32 do
			local texture = UnitBuff("target", i)
			if texture and string.find(texture, "Spell_Shadow_CurseOfTounges") then
				-- Found Curse of Tongues as buff
				return
			elseif not texture then
				break
			end
		end

		-- no curse of tongues found, trigger sync
		self:Sync(syncName.bishopNoCurse)
	end
end

function module:BishopNeedsCurseOfTongues()
	bishopHasTongues = 0
	if self.db.profile.bishoptonguesalert then
       self:Message(L["bishop_needsTongues"], "Important", nil, "Alert")
	end
end

function module:ShadowBoltVolley()
	if self.db.profile.bishopvolley then
		local castTime = timer.sbvolley * (1 + bishopHasTongues * 0.6) / (1 + bishopHasGlory * 0.5)
		self:Bar(L["bar_bishopVolley"], castTime, icon.sbvolley)
		self:Message(L["msg_bishopVolley"], "Purple", nil, "Alarm")
	end
end

function module:CurseHappened()
	self:RemoveBar(L["bar_curseCD"]) --remove old bar
	if self.db.profile.kingscursecd then
		self:IntervalBar(L["bar_curseCD"], timer.cursecd[1], timer.cursecd[2], icon.kingscurse, true, "Black")
	end
end

function module:Cleave()
	self:WarningSign(icon.cleave, 2, true, L["warn_cleave"])
	self:Sound("cleave")
end