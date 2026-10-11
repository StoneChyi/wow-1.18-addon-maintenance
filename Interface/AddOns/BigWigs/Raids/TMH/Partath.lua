local module, L = BigWigs:ModuleDeclaration("Chieftain Partath", "Timbermaw Hold")

module.revision = 30004
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
	might_desc = "Tracks Chieftain Partath's Might of the Chieftain stacks (caps at 50)",

	immune_cmd = "immune",
	immune_name = "Immune (Shade of the Withermaw) Timer",
	immune_desc = "Alerts when Chieftain Partath gains Shade of the Withermaw, and keeps a repeating Next Immune cycle bar",

	trigger_mightStack = "Chieftain Partath gains Might of the Chieftain %((%d+)%)",
	trigger_immuneGain = "Chieftain Partath gains Shade of the Withermaw",
	trigger_immuneGain2 = "Chieftain Partath gains Shade of the Withermaw",
	trigger_immuneFade = "Shade of the Withermaw fades from Chieftain Partath",
	trigger_immuneFade2 = "Shade of the Withermaw fades from Chieftain Partath",

	bar_immune = "Immune",
	bar_might = "Might of the Chieftain",
	bar_nextImmune = "Next Immune",

	msg_immune = "Chieftain Partath is immune - bring Illuminators to him!",
	msg_immuneOver = "Immune ended!",
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Partath",

    might_cmd = "might",
    might_name = "酋长之力层数",
    might_desc = "追踪大酋长之力层数（上限50层）",
    immune_cmd = "immune",
    immune_name = "免疫（枯喉之影/枯萎复苏）计时器",
    immune_desc = "大酋长帕萨斯获得免疫时警报+免疫条，并按52秒循环显示「下次免疫」条（不依赖战斗日志）",

    -- 实测「大酋长帕萨斯获得了枯喉之影的效果」命中过(#1/#3)；参考版用「枯萎复苏」，双名兼容，
    -- 覆盖第2次免疫可能换名播报的情况
    trigger_mightStack = "大酋长帕萨斯获得了酋长之力的效果（(%d+)）",
    trigger_immuneGain = "大酋长帕萨斯获得了枯喉之影的效果",
    trigger_immuneGain2 = "大酋长帕萨斯获得了枯萎复苏的效果",
    trigger_immuneFade = "枯喉之影效果从大酋长帕萨斯身上消失",
    trigger_immuneFade2 = "枯萎复苏效果从大酋长帕萨斯身上消失",

    bar_immune = "免疫",
    bar_might = "酋长之力",
    bar_nextImmune = "下次免疫",

    msg_immune = "大酋长免疫了！带照明者到他身边！",
    msg_immuneOver = "免疫已结束！",
} end )

-- ===== 临时调试（免疫条排查用，定案后删除）=====
-- 开启方式：/script BigWigsPartathDebug = true   （每次登录后需重新执行）
local function PDbg(tag, msg)
	if not BigWigsPartathDebug then return end
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[PDBG " .. date("%H:%M:%S") .. " " .. tag .. "]|r " .. tostring(msg))
	end
end

local timer = {
	mightCap = 50,
	immune = 15,
	immuneCycle = 52,
}

local icon = {
	might = "Ability_Druid_Maul",
	immune = "Spell_Shadow_SummonVoidWalker",
	immuneCycle = "spell_cloaked_in_shadows_2",
}

local syncName = {
	mightStack = "PartathMight"..module.revision,
	immuneGain = "PartathImmune"..module.revision,
	immuneFade = "PartathImmuneOff"..module.revision,
}

local candybar = AceLibrary("CandyBar-2.2")

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")

	self:ThrottleSync(0, syncName.mightStack)
	self:ThrottleSync(5, syncName.immuneGain)
	self:ThrottleSync(5, syncName.immuneFade)

	-- 调试：免疫播报可能走的其它通道（仅打印，不参与触发判定）
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "DebugEvent")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "DebugEvent")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "DebugEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "DebugEvent")
end

function module:DebugEvent(msg)
	PDbg("其它通道", msg)
end

function module:OnSetup()
	self.mightStacks = 0
	self.immuneActive = false
end

function module:OnEngage()
	self.mightStacks = 0
	PDbg("状态", "Engage —— 启动52秒循环「下次免疫」条")
	if self.db.profile.immune then
		self:StartNextImmuneBar()
		self:ScheduleRepeatingEvent("PartathNextImmune", self.StartNextImmuneBar, timer.immuneCycle, self)
	end
end

-- 循环条不依赖战斗日志：免疫增益漏报（通道盲区/文本变体）时条也不会断档
function module:StartNextImmuneBar()
	self:RemoveBar(L["bar_nextImmune"])
	self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
end

function module:OnDisengage()
	PDbg("状态", "Disengage —— 模块脱战/被重启")
	if self:IsEventScheduled("PartathNextImmune") then
		self:CancelScheduledEvent("PartathNextImmune")
	end
	if self:IsEventScheduled("PartathImmuneEndFallback") then
		self:CancelScheduledEvent("PartathImmuneEndFallback")
	end
	self.immuneActive = false
	self:TriggerEvent("BigWigs_StopCounterBar", self, L["bar_might"])
	self:RemoveBar(L["bar_immune"])
	self:RemoveBar(L["bar_nextImmune"])
end

function module:Event(msg)
	PDbg("日志", msg)
	local _, _, stacks = string.find(msg, L["trigger_mightStack"])
	if stacks then
		self:Sync(syncName.mightStack.." "..stacks)
		return
	end
	if string.find(msg, L["trigger_immuneGain"]) or string.find(msg, L["trigger_immuneGain2"]) then
		PDbg("命中", "immuneGain —— 警报+免疫条（Sync 全团同步）")
		self:Sync(syncName.immuneGain)
	elseif string.find(msg, L["trigger_immuneFade"]) or string.find(msg, L["trigger_immuneFade2"]) then
		PDbg("命中", "immuneFade —— 免疫结束")
		self:Sync(syncName.immuneFade)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.mightStack and rest and self.db.profile.might then
		local n = tonumber(rest)
		if n then self:UpdateMight(n) end
	elseif sync == syncName.immuneGain and self.db.profile.immune then
		self:ImmuneStart()
	elseif sync == syncName.immuneFade and self.db.profile.immune then
		self:ImmuneEnd()
	end
end

function module:ImmuneStart()
	self.immuneActive = true
	self:RemoveBar(L["bar_immune"])
	self:Bar(L["bar_immune"], timer.immune, icon.immune, true, "Black")
	self:Message(L["msg_immune"], "Urgent", false, "Alarm")
	-- 以实际免疫时刻校准 52 秒循环的相位：否则循环条与实际免疫错位，
	-- 出现「下次免疫条走完了没动静、提醒却在条中间响」的不同步（实测问题）
	self:RemoveBar(L["bar_nextImmune"])
	if self:IsEventScheduled("PartathNextImmune") then
		self:CancelScheduledEvent("PartathNextImmune")
	end
	self:ScheduleRepeatingEvent("PartathNextImmune", self.StartNextImmuneBar, timer.immuneCycle, self)
	-- fade 日志盲区兜底：免疫时长走完仍无 fade 日志则强制收尾（ImmuneEnd 内防重复提醒）
	self:ScheduleEvent("PartathImmuneEndFallback", self.ImmuneEnd, timer.immune + 1, self)
end

function module:ImmuneEnd()
	if not self.immuneActive then return end
	self.immuneActive = false
	if self:IsEventScheduled("PartathImmuneEndFallback") then
		self:CancelScheduledEvent("PartathImmuneEndFallback")
	end
	self:RemoveBar(L["bar_immune"])
	self:Message(L["msg_immuneOver"], "Positive")
	-- 免疫结束后距下次免疫 = cycle - immune，画精确的「下次免疫」条，与下次提醒对齐
	self:RemoveBar(L["bar_nextImmune"])
	self:Bar(L["bar_nextImmune"], timer.immuneCycle - timer.immune, icon.immuneCycle, true, "Blue")
end

function module:UpdateMight(stacks)
	if stacks <= self.mightStacks then return end
	local prev = self.mightStacks
	self.mightStacks = stacks
	if stacks > timer.mightCap then stacks = timer.mightCap end

	if prev == 0 then
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["bar_might"], timer.mightCap, "Interface\\Icons\\"..icon.might, true, "White")
	end
	self:TriggerEvent("BigWigs_SetCounterBar", self, L["bar_might"], timer.mightCap - stacks)
	self:ApplyMightTextColor(stacks)
end

function module:ApplyMightTextColor(stacks)
	local id = "BigWigsBar "..L["bar_might"]
	local c = "White"
	if stacks >= 40 then
		c = "Red"
	elseif stacks >= 30 then
		c = "Yellow"
	end
	candybar:SetColor(id, c, 1)
end
