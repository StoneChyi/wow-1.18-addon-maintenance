local module, L = BigWigs:ModuleDeclaration("C'Thun", "Ahn'Qiraj")
local bbqirajimindslayer = AceLibrary("Babble-Boss-2.2")["Qiraji Mindslayer"]
local bbeyeofcthun = AceLibrary("Babble-Boss-2.2")["Eye of C'Thun"]
local bbgiantclawtentacle = AceLibrary("Babble-Boss-2.2")["Giant Claw Tentacle"]
local bbgianteyetentacle = AceLibrary("Babble-Boss-2.2")["Giant Eye Tentacle"]
local bbfleshtentacle = AceLibrary("Babble-Boss-2.2")["Flesh Tentacle"]
local bbeyetentacle = AceLibrary("Babble-Boss-2.2")["Eye Tentacle"]
local bbcthun = AceLibrary("Babble-Boss-2.2")["C'Thun"]
local bzthescarabwall = AceLibrary("Babble-Zone-2.2")["The Scarab Wall"]
local bzgatesofahnqiraj = AceLibrary("Babble-Zone-2.2")["Gates of Ahn'Qiraj"]

module.revision = 30080
module.enabletrigger = {bbeyeofcthun, bbcthun}
module.toggleoptions = {
	"cthuneyebeam",
	"darkglare",
	"smalltentacle",
	"smallclaw",
	-1,
	"gianttimer",
	"gianteyeeyebeam",
	"groundtremor",
	"window",
	"weakened",
	"acid",
	-1,
	"stomachhp",
	"proximity",
	"stomachplayers",
	-1,
	"raidicon",
	"bosskill"
}
module.defaultDB = {
	window = false,
}

L:RegisterTranslations("enUS", function()
	return {
		cmd = "Cthun",

		cthuneyebeam_cmd = "cthuneyebeam",
		cthuneyebeam_name = "C'Thun's Eye Beam Alert",
		cthuneyebeam_desc = "Warn for C'Thun's Eye Beam",

		darkglare_cmd = "darkglare",
		darkglare_name = "Dark Glare Alert",
		darkglare_desc = "Warn for Dark Glare",

		smalltentacle_cmd = "smalltentacle",
		smalltentacle_name = "Small Eye Tentacles Alert",
		smalltentacle_desc = "Warn for Small Eye Tentacles",

		smallclaw_cmd = "smallclaw",
		smallclaw_name = "Small Claw Alert",
		smallclaw_desc = "Warn for Small Claw Tentacle",

		gianttimer_cmd = "gianttimer",
		gianttimer_name = "Giant Claw/Eye Spawn Alert",
		gianttimer_desc = "Warn for Giant Claw and Giant Eye spawns",

		gianteyeeyebeam_cmd = "gianteyeeyebeam",
		gianteyeeyebeam_name = "Giant Eye's Eye Beam Alert",
		gianteyeeyebeam_desc = "Warn for Giant Eye's Eye Beam",

		groundtremor_cmd = "groundtremor",
		groundtremor_name = "Ground Tremor Alert",
		groundtremor_desc = "Warn for Ground Tremor",

		window_cmd = "window",
		window_name = "Window of Opportunity Alert",
		window_desc = "Warn for best time to push weaken",

		weakened_cmd = "weakened",
		weakened_name = "Weakened Alert",
		weakened_desc = "Warn for Weakened State",

		acid_cmd = "acid",
		acid_name = "Digestive Acid Alert",
		acid_desc = "Warn for High Digestive Acid Stacks",

		stomachhp_cmd = "stomachhp",
		stomachhp_name = "Stomach Tentacle HP",
		stomachhp_desc = "Bars and Warnings for Stomach Tentacles' HP",

		proximity_cmd = "proximity",
		proximity_name = "Proximity Warning Frame",
		proximity_desc = "Show Proximity Warning Frame",

		stomachplayers_cmd = "stomachplayers",
		stomachplayers_name = "Players in Stomach Frame",
		stomachplayers_desc = "Show Players in Stomach Frame",

		raidicon_cmd = "raidicon",
		raidicon_name = "Skull on Eye Beams",
		raidicon_desc = "Put a Skull on Eye Beam targets",


		bar_startRandomBeams = "Start of Random Beams!",

		trigger_cthun_eyeBeam = "Eye of C'Thun begins to cast Eye Beam.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
		bar_eyeBeam = "Eye Beam on ",

		--no dark glare trigger
		bar_darkGlareCd = "Next Dark Glare",
		bar_darkGlareCasting = "Casting Dark Glare!",
		bar_darkGlareDur = "Dark Glare!",
		msg_darkGlareCasting = "Dark Glare!",
		msg_darkGlareEndsSoon = "Dark Glare ends in 5 sec",

		trigger_smallEyeTentacles = "Eye Tentacle begins to cast Birth.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		msg_smallEyeTentaclesSoon = "Small Eye Tentacles in 3 sec",
		bar_smallEyeTentacles = "Small Eye Tentacles",
		bar_smallEyesDead = "/8 Eye Tentacles Dead",

		trigger_smallClaw = "Claw Tentacle begins to cast Birth.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_smallClaw = "Small Claw Spawn",

		msg_phase2 = "The Eye is dead - Body incoming!",

		trigger_giantClaw = "Giant Claw Tentacle begins to cast Birth.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_giantClaw = "Giant Claw Spawns",

		trigger_giantEye = "Giant Eye Tentacle begins to cast Birth.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_giantEye = "Giant Eye Spawns",

		trigger_giantEye_eyeBeam = "Giant Eye Tentacle begins to cast Eye Beam.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
		--bar_eyeBeam = "Eye Beam on ",

		trigger_groundTremor = "afflicted by Ground Tremor.", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE // CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
		bar_groundTremorDur = "Ground Tremor Stun",

		bar_windowOfOpportunity = "Window of Opportunity",

		--must be a string.find
		trigger_weakened = "is weakened!", --CHAT_MSG_MONSTER_EMOTE
		bar_weakened = "C'Thun is Weakened!",
		msg_weakened = "C'Thun is Weakened!",
		msg_weakenedFade = "Weaken is Over",

		trigger_digestiveAcid = "^You are afflicted by Digestive Acid %((.+)%).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
		msg_digestiveAcid = " Acid Stacks - Consider getting out of the Stomach",

		unit_fleshTentacle = "Flesh Tentacle",
		msg_firstTentacleDead = "First Tentacle Dead",
		msg_secondTentacleLow = "Second Tentacle at %s%% HP",

		frameHeader_playersInStomach = "Players in Stomach",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Cthun",

		cthuneyebeam_cmd = "cthuneyebeam",
		cthuneyebeam_name = "克苏恩眼棱警报",
		cthuneyebeam_desc = "克苏恩眼棱技能警报",

		darkglare_cmd = "darkglare",
		darkglare_name = "红光警报",
		darkglare_desc = "红光技能警报",

		smalltentacle_cmd = "smalltentacle",
		smalltentacle_name = "小眼警报",
		smalltentacle_desc = "小眼刷新警报",

		smallclaw_cmd = "smallclaw",
		smallclaw_name = "小爪须警报",
		smallclaw_desc = "小爪刷新警报",

		gianttimer_cmd = "gianttimer",
		gianttimer_name = "巨型爪/眼刷新警报",
		gianttimer_desc = "巨爪和巨眼须刷新警报",

		gianteyeeyebeam_cmd = "gianteyeeyebeam",
		gianteyeeyebeam_name = "巨眼的眼棱警报",
		gianteyeeyebeam_desc = "巨眼的眼棱技能警报",

		groundtremor_cmd = "groundtremor",
		groundtremor_name = "大地震颤警报",
		groundtremor_desc = "大地震颤技能警报",

		window_cmd = "window",
		window_name = "最佳输出窗口警报",
		window_desc = "提示进入虚弱状态的最佳时机",

		weakened_cmd = "weakened",
		weakened_name = "虚弱状态警报",
		weakened_desc = "虚弱状态提示",

		acid_cmd = "acid",
		acid_name = "消化酸液层数警报",
		acid_desc = "高消化酸液层数警告",

		stomachhp_cmd = "stomachhp",
		stomachhp_name = "胃内触须血量",
		stomachhp_desc = "胃内触须血量条和警告",

	    proximity_cmd = "proximity",
        proximity_name = "距离警告框",
        proximity_desc = "显示距离警告框",

		stomachplayers_cmd = "stomachplayers",
		stomachplayers_name = "胃内玩家框架",
		stomachplayers_desc = "显示胃内玩家框架",

		raidicon_cmd = "raidicon",
		raidicon_name = "眼棱目标标记骷髅",
		raidicon_desc = "为眼棱目标标记骷髅图标",


		bar_startRandomBeams = "开始随机眼棱！",

		trigger_cthun_eyeBeam = "克苏恩之眼开始施放眼棱", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
		bar_eyeBeam = "眼棱->",

		--no dark glare trigger
		bar_darkGlareCd = "下一次黑暗闪耀（红光）",
		bar_darkGlareCasting = "正在施放黑暗闪耀（红光）！",
		bar_darkGlareDur = "黑暗闪耀！",
		msg_darkGlareCasting = "黑暗闪耀！",
		msg_darkGlareEndsSoon = "黑暗闪耀5秒后结束",

		trigger_smallEyeTentacles = "眼球触须开始施放出生", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		msg_smallEyeTentaclesSoon = "3秒后刷新小眼",
		bar_smallEyeTentacles = "小眼",
		bar_smallEyesDead = "/8小眼触须已死",

		trigger_smallClaw = "爪触须开始施放出生。", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_smallClaw = "小爪刷新",

		msg_phase2 = "眼睛已死-本体即将出现！",

		trigger_giantClaw = "巨型利爪触须开始施放出生", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_giantClaw = "巨爪刷新",

		trigger_giantEye = "巨眼触须开始施放出生", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF
		bar_giantEye = "巨眼刷新",

		trigger_giantEye_eyeBeam = "巨眼触须开始施放眼棱", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
		--bar_eyeBeam = "眼棱 -> ",

		trigger_groundTremor = "受到了大地震颤效果的影响", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE // CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
		bar_groundTremorDur = "大地震颤昏迷",

		bar_windowOfOpportunity = "最佳输出窗口",

		--must be a string.find
		trigger_weakened = "被削弱了！", --CHAT_MSG_MONSTER_EMOTE
		bar_weakened = "克苏恩进入虚弱状态！",
		msg_weakened = "克苏恩进入虚弱状态！",
		msg_weakenedFade = "虚弱状态结束",

		trigger_digestiveAcid = "^你受到了消化酸液效果的影响（(%d+)）", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
		msg_digestiveAcid = "消化酸层数过高-离开胃部",

		unit_fleshTentacle = "血肉触须",
		msg_firstTentacleDead = "第一根触须已死",
		msg_secondTentacleLow = "第二根触须%s%%血量",

		frameHeader_playersInStomach = "胃内玩家",
	}
end)

local timer = {
	p1_startRandomBeams = 8,
	eyeBeamCast = 2,

	darkGlareFirstCd = 45,
	darkGlareCd = 87,
	darkGlareCasting = 3,
	darkGlareDur = 39,

	p1_smallEyeTentaclesFirstCd = 45,
	p1_smallEyeTentaclesCd = 45,

	smallClaw = 8,


	p2_smallEyeTentaclesFirstCd = 42,
	p2_smallEyeTentaclesCd = 30,
	p2_smallEyeTentaclesAfterWeakenCd = 38,

	giantClawFirstCd = 12,
	giantClawCd = 30,
	giantClawAfterWeakenCd = 8,

	giantEyeCd = 30,

	p2_timeBetweenGiantSpawn = 30,

	groundTremor = 2,

	weakenedDur = 45,
}
local icon = {
	eyeBeam = "spell_shadow_lifedrain02",
	darkGlare = "Inv_misc_ahnqirajtrinket_04",
	smallEyeTentacles = "spell_shadow_siphonmana",
	smallClaw = "spell_nature_thorns",

	giantClaw = "spell_nature_thorns",
	giantEye = "inv_misc_eye_01",

	groundTremor = "spell_nature_earthquake",

	window = "inv_misc_pocketwatch_01",
	weakened = "spell_shadow_deadofnight",

	digestiveAcid = "ability_creature_disease_02",

	stomachTentacle = "INV_Misc_AhnQirajTrinket_05",
}
local color = {
	startRandomBeams = "Cyan",
	eyeBeam = "Green",

	darkGlareCd = "Orange",
	darkGlareCast = "Red",
	darkGlareDur = "Red",

	smallEyeTentacles = "Blue",
	smallEyesDead = "Yellow",
	smallClaw = "Black",

	giantClaw = "Black",
	giantEye = "Cyan",

	groundTremor = "Yellow",

	window = "White",
	weakened = "White",

	stomachTentacle = "Magenta",
}
local syncName = {
	eyeBeam = "CThunEyeBeam" .. module.revision,

	smallEyeTentacles = "CThunSmallEyeTentaclesSpawn" .. module.revision,
	allSmallEyeTentaclesDead = "CThunAllSmallEyeTentaclesDead" .. module.revision,

	smallClaw = "CThunSmallClawTentacleSpawn" .. module.revision,

	phase2 = "CThunP2Start" .. module.revision,

	giantClaw = "CThunGiantClaw" .. module.revision,
	giantEye = "CThunGiantEye" .. module.revision,

	groundTremor = "CThunGroundTremor" .. module.revision,

	window = "CThunWindow" .. module.revision,

	weakened = "CThunWeakened" .. module.revision,
	weakenedOver = "CThunWeakenedOver2" .. module.revision,

	firstStomachTentacleDead = "CThunFleshTentacleDead2" .. module.revision,
}
local guid = {
	stomachL = nil,
	stomachR = nil,
}

module.proximityCheck = function(unit)
	return CheckInteractDistance(unit, 2)
end
module.proximitySilent = false

local doCheckForWipe = false
local cthunStarted = nil
local phase = "phase1"
local eyeTarget = nil
local lastEyeTarget = nil

local firstStomachTentacleDead = nil
local secondTentacleLowWarn = nil

local smallEyeDead = 0
local smallEyeDeadCounter = 8

local lastspawn = 0

function module:OnRegister()
	self:RegisterEvent("MINIMAP_ZONE_CHANGED")
end

function module:OnEnable()

	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE") --trigger_weakened

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_cthun_eyeBeam, trigger_giantEye_eyeBeam

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "Event") --trigger_smallEyeTentacles, trigger_smallClaw, trigger_giantClaw, trigger_giantEye

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_groundTremor, trigger_digestiveAcid
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") --trigger_groundTremor
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_groundTremor


	self:ThrottleSync(1, syncName.eyeBeam)

	self:ThrottleSync(10, syncName.smallEyeTentacles)
	self:ThrottleSync(10, syncName.allSmallEyeTentaclesDead)

	self:ThrottleSync(5, syncName.smallClaw)

	self:ThrottleSync(10, syncName.phase2)

	self:ThrottleSync(10, syncName.giantClaw)
	self:ThrottleSync(10, syncName.giantEye)

	self:ThrottleSync(3, syncName.groundTremor)

	self:ThrottleSync(3, syncName.window)

	self:ThrottleSync(10, syncName.weakened)
	self:ThrottleSync(10, syncName.weakenedOver)

	self:ThrottleSync(2, syncName.firstStomachTentacleDead)
end

function module:OnSetup()
	self.started = nil

	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
end

function module:OnEngage()
	if self.core:IsModuleActive(bbqirajimindslayer, "Ahn'Qiraj") then
		self.core:DisableModule(bbqirajimindslayer, "Ahn'Qiraj")
	end

	doCheckForWipe = false
	cthunStarted = nil
	phase = "phase1"
	eyeTarget = nil
	lastEyeTarget = nil

	firstStomachTentacleDead = nil
	secondTentacleLowWarn = nil

	smallEyeDead = 0
	smallEyeDeadCounter = 8

	lastspawn = 0

	if self.db.profile.cthuneyebeam then
		self:Bar(L["bar_startRandomBeams"], timer.p1_startRandomBeams, icon.giantEye, true, color.startRandomBeams)
	end

	if self.db.profile.darkglare then
		self:Bar(L["bar_darkGlareCd"], timer.darkGlareFirstCd, icon.darkGlare, true, color.darkGlareCd)
		self:ScheduleEvent("CthunDarkGlare", self.DarkGlare, timer.darkGlareFirstCd, self)
	end

	if self.db.profile.smalltentacle then
		self:Bar(L["bar_smallEyeTentacles"], timer.p1_smallEyeTentaclesFirstCd, icon.smallEyeTentacles, true, color.smallEyeTentacles)

		self:DelayedMessage(timer.p1_smallEyeTentaclesFirstCd - 3, L["msg_smallEyeTentaclesSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.p1_smallEyeTentaclesFirstCd - 3, "Alert")
	end

	if self.db.profile.smallclaw then
		self:Bar(L["bar_smallClaw"], timer.smallClaw, icon.smallClaw, true, color.smallClaw)
	end

	if self.db.profile.proximity then
		self:TriggerEvent("BigWigs_ShowProximity")
	end

	self:ScheduleRepeatingEvent("CthunCheckTarget", self.CheckTarget, 0.5, self)
end

function module:OnDisengage()

	self:TriggerEvent("BigWigs_HideProximity")
	self:TriggerEvent("BigWigs_StopDebuffTrack")

	self:CancelScheduledEvent("CthunP1Claw")
	self:CancelScheduledEvent("CthunDarkGlare")
	self:CancelScheduledEvent("CThunDelayedEyeBeamCheck")
	self:CancelScheduledEvent("CthunCheckTarget")
	self:CancelScheduledEvent("CthunFindFleshTentacle")
	self:CancelScheduledEvent("CthunCheckFleshTentacles")
	self:RemoveBar("stomachL")
    self:RemoveBar("stomachR")
end

function module:MINIMAP_ZONE_CHANGED(msg)
	--The Scarab Wall when you release, then Gates of Ahn'Qiraj as you run back, then Ahn'Qiraj when you zone in
	if (GetMinimapZoneText() == bzthescarabwall or GetMinimapZoneText() == bzgatesofahnqiraj) and self.core:IsModuleActive(module.translatedName) then
		self:TriggerEvent("BigWigs_RebootModule", module.translatedName)
		self:ResetModule()
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f   [BigWigs]|r - 自动重启模块："..module.translatedName)
	end
end

function module:ResetModule()
	doCheckForWipe = false
	cthunStarted = nil
	phase = "phase1"
	eyeTarget = nil

	firstStomachTentacleDead = nil
	secondTentacleLowWarn = nil

	smallEyeDead = 0
	smallEyeDeadCounter = 8

	lastspawn = 0

	self:TriggerEvent("BigWigs_HideProximity")
	self:TriggerEvent("BigWigs_StopDebuffTrack")

	self:CancelScheduledEvent("CthunP1Claw")
	self:CancelScheduledEvent("CthunDarkGlare")
	self:CancelScheduledEvent("CThunDelayedEyeBeamCheck")
	self:CancelScheduledEvent("CthunCheckTarget")
	self:CancelScheduledEvent("CthunFindFleshTentacle")
	self:CancelScheduledEvent("CthunCheckFleshTentacles")
    self:RemoveBar("stomachL")
    self:RemoveBar("stomachR")
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	BigWigs:CheckForBossDeath(msg, self)

	if (msg == string.format(UNITDIESOTHER, bbeyeofcthun)) then
		self:Sync(syncName.phase2)
	
	elseif (msg == string.format(UNITDIESOTHER, bbgiantclawtentacle)) then
		self:Sync(syncName.window)
	
	elseif (msg == string.format(UNITDIESOTHER, bbgianteyetentacle)) then
		self:Sync(syncName.window)
	
	elseif (msg == string.format(UNITDIESOTHER, bbfleshtentacle)) and not firstStomachTentacleDead then
		self:Sync(syncName.firstStomachTentacleDead)
		
	elseif (msg == string.format(UNITDIESOTHER, bbeyetentacle)) then
		smallEyeDead = smallEyeDead + 1
		smallEyeDeadCounter = 8 - smallEyeDead
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_smallEyesDead"], smallEyeDeadCounter)
		if smallEyeDead >= 8 then
			self:Sync(syncName.allSmallEyeTentaclesDead)
		end		
	end
end

function module:CheckForWipe(event)
	if doCheckForWipe then
		BigWigs:CheckForWipe(self)
	end
end

function module:CHAT_MSG_MONSTER_EMOTE(msg)
	if string.find(msg, L["trigger_weakened"]) then
		self:Sync(syncName.weakened)
	end
end

function module:Event(msg)
	if msg == L["trigger_cthun_eyeBeam"] then
		if not cthunStarted then
			module:SendEngageSync()
		end
		self:Sync(syncName.eyeBeam)

	elseif msg == L["trigger_smallEyeTentacles"] then
		self:Sync(syncName.smallEyeTentacles)

	elseif msg == L["trigger_smallClaw"] then
		self:Sync(syncName.smallClaw)

	elseif msg == L["trigger_giantClaw"] then
		self:Sync(syncName.giantClaw)

	elseif msg == L["trigger_giantEye"] then
		self:Sync(syncName.giantEye)


	elseif msg == L["trigger_giantEye_eyeBeam"] then
		self:Sync(syncName.eyeBeam)

	elseif string.find(msg, L["trigger_groundTremor"]) then
		self:Sync(syncName.groundTremor)

	elseif string.find(msg, L["trigger_digestiveAcid"]) and self.db.profile.acid then
		local _, _, acidQty, _ = string.find(msg, L["trigger_digestiveAcid"])
		if tonumber(acidQty) >= 5 then
			self:DigestiveAcid(acidQty)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.eyeBeam then
		self:EyeBeam()

	elseif sync == syncName.smallEyeTentacles and self.db.profile.smalltentacle then
		self:SmallEyeTentacles()
	elseif sync == syncName.allSmallEyeTentaclesDead and self.db.profile.smalltentacle then
		self:AllSmallEyeTentaclesDead()

	elseif sync == syncName.smallClaw and self.db.profile.smallclaw then
		self:SmallClaw()

	elseif sync == syncName.phase2 then
		self:Phase2()

	elseif sync == syncName.giantClaw then
		self:GiantClaw()

	elseif sync == syncName.giantEye then
		self:GiantEye()

	elseif sync == syncName.groundTremor and self.db.profile.groundtremor then
		self:GroundTremor()

	elseif sync == syncName.window and self.db.profile.window then
		self:Window()

	elseif sync == syncName.weakened then
		self:Weakened()
	elseif sync == syncName.weakenedOver then
		self:WeakenedOver()

	elseif sync == syncName.firstStomachTentacleDead and self.db.profile.stomachhp then
		self:FleshTentacleDead()

	end
end

function module:EyeBeam()
	self:ScheduleEvent("CThunDelayedEyeBeamCheck", self.DelayedEyeBeamCheck, 0.2, self) -- has to be done delayed since the target change is delayed
end

function module:DelayedEyeBeamCheck()
	local name = "Unknown"
	self:CheckTarget()

	if eyeTarget then
		name = eyeTarget

		if self.db.profile.raidicon and name ~= lastEyeTarget then
			self:RestorePreviousRaidTargetForPlayer(lastEyeTarget)
			lastEyeTarget = name
			self:SetRaidTargetForPlayer(name, 8)
		end

		if name == UnitName("player") then
			self:WarningSign(icon.eyeBeam, 2 - 0.1)
			SendChatMessage("我受到眼棱攻击！", "SAY")
		else
			for i = 1, GetNumRaidMembers(), 1 do
				if name == UnitName('Raid' .. i) and CheckInteractDistance("Raid" .. i, 3) then
					if (phase == "phase1" and self.db.profile.cthuneyebeam) or (phase == "phase2" and self.db.profile.gianteyeeyebeam) then
						self:Message("眼棱即将攻击 " .. name .. " ! 快离开！", "Important", false, nil, false)
					end
				end
			end
		end
	end

	if (phase == "phase1" and self.db.profile.cthuneyebeam) or (phase == "phase2" and self.db.profile.gianteyeeyebeam) then
		self:Bar(L["bar_eyeBeam"] .. name, timer.eyeBeamCast - 0.1, icon.giantEye, true, color.eyeBeam)
	end
end

function module:CheckTarget()
	local newtarget = nil
	local enemy = bbeyeofcthun

	if phase == "phase2" then
		enemy = bbgianteyetentacle
	end
	if UnitName("Target") == enemy then
		newtarget = UnitName("TargetTarget")
	else
		for i = 1, GetNumRaidMembers() do
			if UnitName("Raid" .. i .. "Target") == enemy then
				newtarget = UnitName("Raid" .. i .. "TargetTarget")
				break
			end
		end
	end
	if newtarget then
		eyeTarget = newtarget
	end
end

function module:DarkGlare()
	self:RestorePreviousRaidTargetForPlayer(lastEyeTarget)
	lastEyeTarget = nil

	self:Bar(L["bar_darkGlareCasting"], timer.darkGlareCasting, icon.darkGlare, true, color.darkGlareCast)
	self:WarningSign(icon.darkGlare, timer.darkGlareCasting)
	self:Message(L["msg_darkGlareCasting"], "Urgent", false, nil, false)
	self:Sound("RunAway")

	self:DelayedBar(timer.darkGlareCasting, L["bar_darkGlareDur"], timer.darkGlareDur, icon.darkGlare, true, color.darkGlareDur)
	self:DelayedMessage(timer.darkGlareCasting + timer.darkGlareDur - 5, L["msg_darkGlareEndsSoon"], "Urgent", false, nil, true)
	self:DelayedBar(timer.darkGlareCasting + timer.darkGlareDur, L["bar_darkGlareCd"], timer.darkGlareCd - timer.darkGlareCasting - timer.darkGlareDur, icon.darkGlare, true, color.darkGlareCd)

	self:ScheduleEvent("CthunDarkGlare", self.DarkGlare, timer.darkGlareCd, self)
end

function module:SmallEyeTentacles()
	self:CancelDelayedMessage(L["msg_smallEyeTentaclesSoon"])
	self:CancelDelayedSound("Alert")

	self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_smallEyesDead"], 8, "Interface\\Icons\\" .. icon.smallEyeTentacles, true, color.smallEyesDead)
	self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_smallEyesDead"], (8 - 0.1))

	smallEyeDead = 0
	smallEyeDeadCounter = 8

	if phase == "phase1" then
		self:Bar(L["bar_smallEyeTentacles"], timer.p1_smallEyeTentaclesCd, icon.smallEyeTentacles, true, color.smallEyeTentacles)

		self:DelayedMessage(timer.p1_smallEyeTentaclesCd - 3, L["msg_smallEyeTentaclesSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.p1_smallEyeTentaclesCd - 3, "Alert")

	elseif phase == "phase2" then
		self:Bar(L["bar_smallEyeTentacles"], timer.p2_smallEyeTentaclesCd, icon.smallEyeTentacles, true, color.smallEyeTentacles)

		self:DelayedMessage(timer.p2_smallEyeTentaclesCd - 3, L["msg_smallEyeTentaclesSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.p2_smallEyeTentaclesCd - 3, "Alert")
	end
end

function module:AllSmallEyeTentaclesDead()
	smallEyeDead = 0
	smallEyeDeadCounter = 8
	self:TriggerEvent("BigWigs_StopCounterBar", self, L["bar_smallEyesDead"])
end

function module:SmallClaw()
	self:Bar(L["bar_smallClaw"], timer.smallClaw, icon.smallClaw, true, color.smallClaw)
end

function module:Phase2()
	phase = "phase2"

	doCheckForWipe = false -- disable wipe check since we get out of combat, enable it later again

	self:Message(L["msg_phase2"], "Positive", false, nil, false)
	-- cancel dark glare
	self:CancelScheduledEvent("CthunDarkGlare")
	self:CancelDelayedBar(L["bar_darkGlareCd"])
	self:CancelDelayedBar(L["bar_darkGlareDur"])
	self:RemoveBar(L["bar_darkGlareCasting"])
	self:RemoveBar(L["bar_darkGlareCd"])
	self:RemoveBar(L["bar_darkGlareDur"])
	self:CancelDelayedMessage(L["msg_darkGlareEndsSoon"])
	self:RemoveWarningSign(icon.darkGlare)

	-- cancel small eye tentacles
	self:CancelDelayedMessage(L["msg_smallEyeTentaclesSoon"])
	self:CancelDelayedSound("Alert")
	self:RemoveBar(L["bar_smallEyeTentacles"])

	-- cancel small claw tentacle
	self:RemoveBar(L["bar_smallClaw"])

	if self.db.profile.smalltentacle then
		self:DelayedMessage(timer.p2_smallEyeTentaclesFirstCd - 3, L["msg_smallEyeTentaclesSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.p2_smallEyeTentaclesFirstCd - 3, "Alert")
		self:Bar(L["bar_smallEyeTentacles"], timer.p2_smallEyeTentaclesFirstCd, icon.smallEyeTentacles, true, color.smallEyeTentacles)
	end

	if self.db.profile.gianttimer then
		self:Bar(L["bar_giantClaw"], timer.giantClawFirstCd, icon.giantClaw, true, color.giantClaw)
	end

	if self.db.profile.stomachhp then
		firstStomachTentacleDead = nil
		secondTentacleLowWarn = nil

		self:ScheduleEvent("CthunFindFleshTentacle", self.FindFleshTentacle, 12, self)
	end

	if self.db.profile.stomachplayers then
		self:TriggerEvent("BigWigs_StartDebuffTrack", self:ToString(), "Interface\\Icons\\Ability_Creature_Disease_02", L["frameHeader_playersInStomach"])
	end
end

function module:GiantClaw()
	lastspawn = GetTime()

	doCheckForWipe = true

	if self.db.profile.gianttimer then
		self:Bar(L["bar_giantEye"], timer.giantEyeCd, icon.giantEye, true, color.giantEye)
	end
end

function module:GiantEye()
	lastspawn = GetTime()

	if self.db.profile.gianttimer then
		self:Bar(L["bar_giantClaw"], timer.giantClawCd, icon.giantClaw, true, color.giantClaw)
	end
end

function module:GroundTremor()
	self:Bar(L["bar_groundTremorDur"], timer.groundTremor, icon.groundTremor, true, color.groundTremor)
end

function module:Window()
	local window = (lastspawn + timer.p2_timeBetweenGiantSpawn - 2) - GetTime()
	if window > 0 then
		self:Bar(L["bar_windowOfOpportunity"], window, icon.window, true, color.window)
	end
end

function module:Weakened()
	firstStomachTentacleDead = nil
	secondTentacleLowWarn = nil
	self:RemoveBar("stomachL")
	self:RemoveBar("stomachR")

	self:CancelDelayedMessage(L["msg_smallEyeTentaclesSoon"])
	self:CancelDelayedSound("Alert")
	self:RemoveBar(L["bar_smallEyeTentacles"])

	self:RemoveBar(L["bar_giantEye"])
	self:RemoveBar(L["bar_giantClaw"])

	self:CancelScheduledEvent("CthunCheckFleshTentacles")

	if self.db.profile.weakened then
		self:Message(L["msg_weakened"], "Positive", false, nil, false)
		self:Sound("Murloc")
		self:Bar(L["bar_weakened"], timer.weakenedDur, icon.weakened, true, color.weakened)
	end

	self:DelayedSync(timer.weakenedDur, syncName.weakenedOver)
end

function module:WeakenedOver()
	self:CancelDelayedSync(syncName.weakenedOver)
	self:RemoveBar(L["bar_weakened"])

	if self.db.profile.weakened then
		self:Message(L["msg_weakenedFade"], "Important", false, nil, false)
	end

	if self.db.profile.smalltentacle then
		self:Bar(L["bar_smallEyeTentacles"], timer.p2_smallEyeTentaclesAfterWeakenCd, icon.smallEyeTentacles, true, color.smallEyeTentacles)
		self:DelayedMessage(timer.p2_smallEyeTentaclesAfterWeakenCd - 3, L["msg_smallEyeTentaclesSoon"], "Urgent", false, nil, false)
		self:DelayedSound(timer.p2_smallEyeTentaclesAfterWeakenCd - 3, "Alert")
	end

	if self.db.profile.gianttimer then
		self:Bar(L["bar_giantClaw"], timer.giantClawAfterWeakenCd, icon.giantClaw, true, color.giantClaw)
	end

	if self.db.profile.stomachhp then
		firstStomachTentacleDead = nil
		secondTentacleLowWarn = nil

		self:ScheduleEvent("CthunFindFleshTentacle", self.FindFleshTentacle, 12, self)
	end
end

function module:DigestiveAcid(rest)
	self:Message(rest .. L["msg_digestiveAcid"], "Personal", false, nil, false)
	self:WarningSign(icon.digestiveAcid, 0.7)
end

function module:FleshTentacleDead()
	if not firstStomachTentacleDead then
		firstStomachTentacleDead = true
		secondTentacleLowWarn = nil

		self:Message(L["msg_firstTentacleDead"], "Important", false, nil, false)
	end
end

function module:FindFleshTentacle()
	local found = BigWigs:GetGUIDByName(L["unit_fleshTentacle"], 1)
	if found then
		self:GetSecondFleshTentacle(found)
	else
		self:ScheduleEvent("CthunFindFleshTentacle", self.FindFleshTentacle, 0.5, self)
	end
end

function module:GetSecondFleshTentacle(firstGUID)
	local minus = BigWigs:OffsetGUID(firstGUID,-1)
	local plus = BigWigs:OffsetGUID(firstGUID,1)
	if minus and UnitExists(minus) and UnitName(minus) == L["unit_fleshTentacle"] then
		guid.stomachL = firstGUID
		guid.stomachR = minus
	elseif plus and UnitExists(plus) and UnitName(plus) == L["unit_fleshTentacle"] then
		guid.stomachL = plus
		guid.stomachR = firstGUID
	else
		-- inferring the second tentacle from consecutive GUIDs is elegant, but possibly not 100% reliable?
		print("Unable to find a second Flesh Tentacle - Please submit a bug report on Github!")
		return
	end

	self:MonitorBar("stomachL", icon.stomachTentacle, guid.stomachL, "health", "一根胃触须")
	self:MonitorBar("stomachR", icon.stomachTentacle, guid.stomachR, "health", "二根胃触须")
	self:ScheduleRepeatingEvent("CthunCheckFleshTentacles", self.CheckFleshTentacles, 0.5, self)
end

function module:CheckFleshTentacles()
	if secondTentacleLowWarn or not firstStomachTentacleDead then
		return
	end

	local guidSecond
	if UnitExists(guid.stomachL) and not UnitIsDead(guid.stomachL) then
		guidSecond = guid.stomachL
	elseif UnitExists(guid.stomachR) and not UnitIsDead(guid.stomachR) then
		guidSecond = guid.stomachR
	end

	local percent = UnitHealth(guidSecond) / UnitHealthMax(guidSecond) * 100
	if percent <= 20 then
		self:Message(string.format(L["msg_secondTentacleLow"],math.ceil(percent)), "Urgent")
		secondTentacleLowWarn = true
		self:CancelScheduledEvent("CthunCheckFleshTentacles")
	end
end
