local module, L = BigWigs:ModuleDeclaration("Chieftain Partath", "Timbermaw Hold")

module.revision = 30002
module.enabletrigger = module.translatedName
module.toggleoptions = {"might", "immune", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Partath",

	might_cmd = "might",
	might_name = "Might of the Chieftain Bar",
	might_desc = "Counter bar for Chieftain Partath's Might of the Chieftain stacks (caps at 50, turns yellow at 30 and red at 40)",

	immune_cmd = "immune",
	immune_name = "Immune (Shade of the Withermaw) Timer",
	immune_desc = "Shows a 15 second bar when Chieftain Partath gains Shade of the Withermaw",

	trigger_mightStack = "Chieftain Partath gains Might of the Chieftain %((%d+)%)",
	trigger_mightKeyword = "Might of the Chieftain",
	trigger_mightFade = "fades",
	trigger_immuneGain = "Chieftain Partath gains Shade of the Withermaw",
	trigger_immuneFade = "Shade of the Withermaw fades from Chieftain Partath",

	bar_might = "Might of the Chieftain",
	bar_immune = "Immune",
	bar_nextImmune = "Next Immune",

	msg_immune = "Chieftain Partath is immune - bring Illuminators to him!",
	msg_immuneOver = "Immune ended!",
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Partath",

    might_cmd = "might",
    might_name = "大酋长之力叠层条",
    might_desc = "追踪大酋长帕萨斯「大酋长之力」的叠层数（上限50层，30层转黄、40层转红）",

    immune_cmd = "immune",
    immune_name = "免疫（枯萎复苏）计时器",
    immune_desc = "当大酋长帕萨斯获得枯喉之影时，显示15秒免疫条",

    -- 中文日志句式未经实测，先用「关键词 + 括号数字」的宽松匹配；确认真实文本后可改成整句
    trigger_mightStack = "大酋长之力.-%((%d+)%)",
    trigger_mightKeyword = "大酋长之力",
    trigger_mightFade = "消失",
    trigger_immuneGain = "大酋长帕萨斯获得了枯喉之影的效果",
    trigger_immuneFade = "枯喉之影效果从大酋长帕萨斯身上消失",

    bar_might = "大酋长之力",
    bar_immune = "免疫",
    bar_nextImmune = "下次免疫",

    msg_immune = "大酋长免疫了！带照明者到他身边！",
    msg_immuneOver = "免疫已结束！",
} end )

local candybar = AceLibrary("CandyBar-2.2")

local timer = {
	mightCap = 50,
	mightWarn = 30,
	mightAlarm = 40,
	immune = 15,
	immuneCycle = 52,
}

local icon = {
	might = "Ability_Druid_Maul",
	immune = "Spell_Shadow_SummonVoidWalker",
	immuneCycle = "spell_cloaked_in_shadows_2",
}

-- 从日志里取出叠层数：先按整句 pattern，失败再退回「关键词 + (N)」的宽松匹配，
-- 这样中文端句式和我猜的不一样也能工作
local function ParseMightStacks(msg)
	local _, _, stacks = string.find(msg, L["trigger_mightStack"])
	if stacks then
		return tonumber(stacks)
	end
	if string.find(msg, L["trigger_mightKeyword"]) then
		local _, _, n = string.find(msg, "%((%d+)%)")
		if not n then
			_, _, n = string.find(msg, "（(%d+)）")
		end
		if n then
			return tonumber(n)
		end
	end
	return nil
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
end

function module:OnSetup()
	self.mightStacks = 0
end

function module:OnEngage()
	self.mightStacks = 0
	if self.db.profile.immune then
		self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
		-- 免疫是循环机制，单次条走完就没了；用重复事件保证「下次免疫」始终在追踪
		self:ScheduleRepeatingEvent("PartathNextImmune", self.StartNextImmuneBar, timer.immuneCycle, self)
	end
end

function module:StartNextImmuneBar()
	if not self.db.profile.immune then
		-- 循环跑起来之后才关掉开关：把残留的条收掉，循环本身留着（重开即恢复）
		self:RemoveBar(L["bar_nextImmune"])
		return
	end
	self:RemoveBar(L["bar_nextImmune"])
	self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
end

function module:OnDisengage()
	self:RemoveBar(L["bar_nextImmune"])
	self:RemoveBar(L["bar_immune"])
	self:TriggerEvent("BigWigs_StopCounterBar", self, L["bar_might"])
	if self:IsEventScheduled("PartathNextImmune") then
		self:CancelScheduledEvent("PartathNextImmune")
	end
	self.mightStacks = 0
end

function module:Event(msg)
	local stacks = ParseMightStacks(msg)
	if stacks then
		-- 选项必须在事件入口判定，否则 /bw 里关掉开关依旧报警、依旧建条
		if self.db.profile.might then
			if stacks == 0 then
				self:ResetMight()
			else
				self:UpdateMight(stacks)
			end
		end
		return
	elseif string.find(msg, L["trigger_immuneGain"]) then
		if self.db.profile.immune then
			self:ImmuneStart()
		end
		return
	elseif string.find(msg, L["trigger_immuneFade"]) then
		if self.db.profile.immune then
			self:ImmuneEnd()
		end
		return
	elseif string.find(msg, L["trigger_mightKeyword"]) and string.find(msg, L["trigger_mightFade"]) then
		-- 同时含关键词与「消失」类词 = 叠层 buff 掉了，必须归零。
		-- 否则 UpdateMight 的「层数必须递增」判断会一直挡着，条永久卡在满层。
		-- 注意：只命中关键词、提不出数字、又没有「消失」字样时一律不动，
		-- 避免中文句式与预期不符时把每次叠层都误判成消失。
		self:ResetMight()
		return
	end
end

function module:ResetMight()
	if not self.mightStacks or self.mightStacks == 0 then
		return
	end
	self.mightStacks = 0
	self:TriggerEvent("BigWigs_StopCounterBar", self, L["bar_might"])
end

function module:UpdateMight(stacks)
	if not self.mightStacks then
		self.mightStacks = 0
	end
	if stacks <= self.mightStacks then
		return
	end
	local prev = self.mightStacks
	self.mightStacks = stacks
	if stacks > timer.mightCap then
		stacks = timer.mightCap
	end

	if prev == 0 then
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_might"], timer.mightCap, "Interface\\Icons\\"..icon.might, true, "White")
	end
	self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_might"], timer.mightCap - stacks)

	local c = "White"
	if stacks >= timer.mightAlarm then
		c = "Red"
	elseif stacks >= timer.mightWarn then
		c = "Yellow"
	end
	candybar:SetColor("BigWigsBar "..L["bar_might"], c, 1)
end

function module:ImmuneStart()
	-- 免疫真的触发了 = 本轮「下次免疫」计时作废，从此刻重新起算
	self:RemoveBar(L["bar_nextImmune"])
	self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
	if self:IsEventScheduled("PartathNextImmune") then
		self:CancelScheduledEvent("PartathNextImmune")
	end
	self:ScheduleRepeatingEvent("PartathNextImmune", self.StartNextImmuneBar, timer.immuneCycle, self)

	self:Message(L["msg_immune"], "Urgent", false, "Alarm")
	self:Bar(L["bar_immune"], timer.immune, icon.immune, true, "Black")
end

function module:ImmuneEnd()
	self:RemoveBar(L["bar_immune"])
	self:Message(L["msg_immuneOver"], "Positive")
end
