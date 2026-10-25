local module, L = BigWigs:ModuleDeclaration("吞噬者提里奥克", "Timbermaw Hold")

-- module variables
module.revision = 30140
module.enabletrigger = module.translatedName   -- 完整单位名，CheckForEngage 为精确匹配
module.toggleoptions = { "flame", "flamecd", -1, "corrosion", "corrosionmark", -1, "icelance", "icelancemark", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

-- 软泥怪 / 毒池的真实名称（来自实测），用于死亡检测与文案
local slimeName = "蠕动的异质"   -- 腐蚀之颅脚下刷出的软泥怪
local poisonName = "毒害之云"   -- 软泥怪死后脚底生成的毒池

module.defaultDB = {
	flame = true,
	flamecd = true,
	corrosion = true,
	corrosionmark = true,
	icelance = true,
	icelancemark = true,
}

--[[
	提里奥克 (Trioch) — 木吼要塞 / Timbermaw Hold
	三个技能（战斗日志文本均来自实测，可直接作触发器）：
	1) 烈焰之颅：方向性锥形，注意 BOSS 头部朝向。
	2) 腐蚀之颅：标记 2 人，脚下出软泥怪「蠕动的异质」，集火击杀；软泥死后脚底出毒池「毒害之云」，跑开。
	   软泥死亡用 CHAT_MSG_COMBAT_HOSTILE_DEATH 检测「蠕动的异质」精确触发，定时条仅作击杀窗口兜底。
	3) 冰锥：标记 2 人，集合到被标记者处分担伤害。
	   日志里第一个目标名是字面 %s（boss 当前目标未替换，也可能 %t），用多级回退解析 boss 当前目标；
   第二个名字会被贪婪捕获带上句末标点（如「！」），需剥离。

	下列 timer 中的数字均为占位值，进本后按实测 CD 校准。
]]

local timer = {
	flameCast = 3,        -- 烈焰之颅施法时间（需实测）
	flame = 25,           -- 烈焰之颅 CD（需实测）
	corrosion = 30,       -- 腐蚀之颅 CD（需实测）
	oozeSlime = 15,       -- 集火击杀软泥怪的时间窗口（需实测）
	oozePoison = 8,       -- 软泥死后毒池持续 / 跑开窗口（需实测）
	iceLance = 20,         -- 冰锥 CD（需实测）
	iceLanceHit = 4,       -- 冰锥命中前的集合时间（需实测）
}

local color = {
	flame = "Red",
	flamecd = "Cyan",
	corrosion = "Green",
	poison = "Green",
	icelance = "Blue",
}

local icon = {
	flame = "Spell_Fire_Fireball",
	flameCast = "Spell_Fire_Incinerate",
	corrosion = "Spell_Nature_Acid_01",
	ooze = "Ability_Creature_Disease_02",
	poison = "Spell_Nature_Acid_01",
	icelance = "Spell_Frost_Frost",
	icelanceHit = "Spell_Frost_ChillingBlast",
}

local syncName = {
	flame = "TriochFlame" .. module.revision,
	flameFrontSides = "TriochFlameFS" .. module.revision,
	flameFrontBack = "TriochFlameFB" .. module.revision,
	corrosion = "TriochCorrosion" .. module.revision,
}

------------------------------
--      Localization        --
------------------------------

L:RegisterTranslations("enUS", function()
	return {
		cmd = "Trioch",

		flame_cmd = "flame",
		flame_name = "Flame Skull alert",
		flame_desc = "Warn about Flame Skull (directional cone - watch boss head).",

		flamecd_cmd = "flamecd",
		flamecd_name = "Flame Skull cooldown bar",
		flamecd_desc = "Show a bar for the next Flame Skull.",

		corrosion_cmd = "corrosion",
		corrosion_name = "Corrosion Skull alert",
		corrosion_desc = "Warn and mark the 2 players hit by Corrupt Ooze; focus the slime then run from poison.",

		corrosionmark_cmd = "corrosionmark",
		corrosionmark_name = "Corrupt Ooze marks",
		corrosionmark_desc = "Mark the players targeted by Corrupt Ooze.",

		icelance_cmd = "icelance",
		icelance_name = "Ice Lance alert",
		icelance_desc = "Warn and mark the 2 players targeted by the giant Ice Lance; gather to share damage.",

		icelancemark_cmd = "icelancemark",
		icelancemark_name = "Ice Lance marks",
		icelancemark_desc = "Mark the players targeted by the Ice Lance.",

		trigger_flameCast = "Trioch begins to attack with Flame Skull",
		trigger_flameFrontSides = "Trioch is about to spew flames to the front and sides",
		trigger_flameFrontBack = "Trioch is about to spew flames to the front and behind",
		trigger_corrosionCast = "Trioch begins to attack with Corrosion Skull",
		trigger_iceLance = "Trioch aims a giant ice lance at (.+) and (.+)",

		msg_flame = "Flame Skull! Watch the BOSS HEAD direction!",
		msg_flameFrontSides = "Flame: FRONT + SIDES! Avoid front and sides!",
		msg_flameFrontBack = "Flame: FRONT + BEHIND! Avoid front and back!",
		msg_flameSoon = "5 sec to Flame Skull!",
		bar_flameCast = "Flame Skull cast",
		bar_flame = "Next Flame Skull",

		msg_corrosionCast = "Corrosion Skull incoming!",
		msg_corrosion = "%s has Corrupt Ooze - burn the '蠕动的异质' slime at their feet!",
		msg_corrosionYou = "YOU have Corrupt Ooze! Kill '蠕动的异质', then RUN from '毒害之云'!",
		bar_oozeSlime = "Kill 蠕动的异质",
		msg_oozeDead = "蠕动的异质 dead! RUN from 毒害之云!",
		bar_oozePoison = "毒害之云 - RUN!",

		msg_iceLance = "%s and %s targeted by Ice Lance - GATHER to share damage!",
		msg_iceLanceYou = "YOU are targeted by Ice Lance! Gather on the marked players!",
		bar_iceLance = "Ice Lance - Gather",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Trioch",

		flame_cmd = "flame",
		flame_name = "烈焰之颅警报",
		flame_desc = "烈焰之颅（方向性锥形，注意BOSS头部朝向）警报。",

		flamecd_cmd = "flamecd",
		flamecd_name = "烈焰之颅倒计时",
		flamecd_desc = "显示下次烈焰之颅的倒计时条。",

		corrosion_cmd = "corrosion",
		corrosion_name = "腐蚀之颅警报",
		corrosion_desc = "警告并标记被腐毒软泥命中的2名玩家；集火软泥怪后跑开毒池。",

		corrosionmark_cmd = "corrosionmark",
		corrosionmark_name = "腐毒软泥标记",
		corrosionmark_desc = "为被腐毒软泥命中的玩家打团队标记。",

		icelance_cmd = "icelance",
		icelance_name = "冰锥警报",
		icelance_desc = "警告并标记被巨大冰锥瞄准的2名玩家；集合分担伤害。",

		icelancemark_cmd = "icelancemark",
		icelancemark_name = "冰锥标记",
		icelancemark_desc = "为被冰锥瞄准的玩家打团队标记。",

		trigger_flameCast = "提里奥克在用烈焰之颅攻击",
		trigger_flameFrontSides = "提里奥克即将向前方和两侧喷射烈焰",
		trigger_flameFrontBack = "提里奥克即将向前方和身后喷射烈焰",
		trigger_corrosionCast = "提里奥克在用腐蚀之颅攻击",
		trigger_iceLance = "提里奥克用巨大的冰锥瞄准了(.+)和(.+)",

		msg_flame = "烈焰之颅！注意BOSS头部方向！",
		msg_flameFrontSides = "烈焰：前方+两侧！躲开正面和两侧！",
		msg_flameFrontBack = "烈焰：前方+身后！躲开正面和背后！",
		msg_flameSoon = "5秒后 烈焰之颅！",
		bar_flameCast = "烈焰之颅 施法",
		bar_flame = "下次烈焰之颅",

		msg_corrosionCast = "腐蚀之颅来袭！",
		msg_corrosion = "%s 中了腐毒软泥 - 集火击杀脚下的【蠕动的异质】！",
		msg_corrosionYou = "你中了腐毒软泥！击杀脚下的【蠕动的异质】，死后立刻跑开【毒害之云】！",
		bar_oozeSlime = "集火击杀 蠕动的异质",
		msg_oozeDead = "【蠕动的异质】已死亡！离开【毒害之云】毒池！",
		bar_oozePoison = "毒害之云 - 快跑开！",

		msg_iceLance = "冰锥：%s 和 %s 被瞄准 - 集合分担伤害！",
		msg_iceLanceYou = "你被冰锥瞄准！到被标记者处集合分担！",
		bar_iceLance = "冰锥 - 集合分担",
	}
end)

------------------------------
--      Utility             --
------------------------------

local function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- 自标在 RAID_BOSS_EMOTE 里显示为“你”，需转成本地玩家名才能正确打标记
local function resolveName(s)
	s = trim(s)
	if s == "你" then return UnitName("player") end
	return s
end

-- 冰锥 emote 中第一个目标名在日志里是字面 %s（boss 当前目标未被替换）。
-- 解析 %s = boss 的当前目标。注意：boss1~4 单位框在 1.12 客户端不存在，
-- 且本客户端（SuperWoW/Nampower）对未知单位直接抛错（Unknown unit name: boss1）
-- 而非返回 nil，所以绝不能探测 boss 框；只走 target/全团扫描（参考 Onyxia.lua CheckTarget）。
local function bossTargetName()
	local enemy = module.translatedName
	-- 1) 玩家正瞄着 boss，取其 target 即为 boss 当前目标
	if UnitName("target") == enemy then
		local t = UnitName("targettarget")
		if t then return t end
	end
	-- 2) 扫描全团：谁在瞄 boss，取其 target（= boss 当前目标）
	--    兼容 raid / Raid 两种写法
	local n = (GetNumRaidMembers and GetNumRaidMembers()) or 0
	if n > 0 then
		for i = 1, n do
			if UnitName("raid" .. i .. "target") == enemy then
				local t = UnitName("raid" .. i .. "targettarget")
				if t then return t end
			end
			if UnitName("Raid" .. i .. "target") == enemy then
				local t = UnitName("Raid" .. i .. "targettarget")
				if t then return t end
			end
		end
	end
	-- 3) 小队兜底
	n = (GetNumPartyMembers and GetNumPartyMembers()) or 0
	if n > 0 then
		for i = 1, n do
			if UnitName("party" .. i .. "target") == enemy then
				local t = UnitName("party" .. i .. "targettarget")
				if t then return t end
			end
		end
	end
	return nil
end

-- 剥离名字尾部被贪婪捕获带上的句末标点（！ ! 。 ． . …）。
-- Lua pattern 字符类不认多字节字符，逐个后缀做字节级比较最稳。
local function stripPunct(s)
	local suffixes = { "！", "!", "。", "．", ".", "…" }
	local changed = true
	while changed do
		changed = false
		for _, p in ipairs(suffixes) do
			local lp = string.len(p)
			if string.len(s) >= lp and string.sub(s, -lp) == p then
				s = string.sub(s, 1, -(lp + 1))
				changed = true
			end
		end
	end
	return s
end

-- 归一化 emote 里捕获的“目标名”：
-- 1) 服务器未替换的目标 token：实测为字面 %s（也可能 %t）→ 解析 boss 当前目标；
-- 2) 去掉尾部句末标点；
-- 3) 自标「你」→ 本地玩家名。
-- 解析失败返回 nil，由调用方跳过标记 / 喊话兜底。
local function normalizeTarget(s)
	if not s then return nil end
	s = trim(s)
	if s == "%t" or s == "%s" then
		s = bossTargetName()
		if not s then return nil end
	else
		s = stripPunct(s)
	end
	if s == "" then return nil end
	return resolveName(s)
end

------------------------------
--      Initialization      --
------------------------------

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "Event")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "Event")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")

	self:ThrottleSync(3, syncName.flame)
	self:ThrottleSync(3, syncName.flameFrontSides)
	self:ThrottleSync(3, syncName.flameFrontBack)
	self:ThrottleSync(3, syncName.corrosion)
end

function module:OnSetup()
	self.oozeTargets = {}
	self.iceTargets = {}
	self.oozeActive = false
	self.iceActive = false
	self.oozeDeadFired = false
end

function module:OnEngage()
	self.oozeTargets = {}
	self.iceTargets = {}
	self.oozeActive = false
	self.iceActive = false
	self.oozeDeadFired = false
end

function module:OnDisengage()
	self:CancelScheduledEvent("TriochOozeDead")
	self:CancelScheduledEvent("TriochOozePoisonEnd")
	self:CancelScheduledEvent("TriochIceEnd")
	self:RemoveBar(L["bar_flameCast"])
	self:RemoveBar(L["bar_flame"])
	self:RemoveBar(L["bar_oozeSlime"])
	self:RemoveBar(L["bar_oozePoison"])
	self:RemoveBar(L["bar_iceLance"])
	if self.oozeTargets then
		for name, _ in pairs(self.oozeTargets) do self:RestorePreviousRaidTargetForPlayer(name) end
	end
	if self.iceTargets then
		for name, _ in pairs(self.iceTargets) do self:RestorePreviousRaidTargetForPlayer(name) end
	end
	self.oozeTargets = {}
	self.iceTargets = {}
	self.oozeActive = false
	self.iceActive = false
	self.oozeDeadFired = false
end

------------------------------
--      Events              --
------------------------------

function module:Event(msg)
	-- 烈焰之颅：施法开始
	if string.find(msg, L["trigger_flameCast"]) then
		self:Sync(syncName.flame)
		return
	end
	-- 烈焰之颅：方向预警（前方+两侧）
	if string.find(msg, L["trigger_flameFrontSides"]) then
		self:Sync(syncName.flameFrontSides)
		return
	end
	-- 烈焰之颅：方向预警（前方+身后）
	if string.find(msg, L["trigger_flameFrontBack"]) then
		self:Sync(syncName.flameFrontBack)
		return
	end
	-- 腐蚀之颅：施法开始
	if string.find(msg, L["trigger_corrosionCast"]) then
		self:Sync(syncName.corrosion)
		return
	end
	-- 腐毒软泥：标记玩家（可能一次标1人，或“A和B”一次标2人）
	-- 同样走 normalizeTarget：token 未替换（%s/%t）与句末标点都需处理
	if string.find(msg, "腐毒软泥") then
		local _, _, tgt = string.find(msg, "提里奥克向(.+)释放")
		if tgt then
			local _, _, a, b = string.find(tgt, "^(.-)和(.+)$")
			local names
			if b then names = { a, b } else names = { tgt } end
			for _, nm in ipairs(names) do
				self:CorrosionMark(normalizeTarget(nm))
			end
			return
		end
	end
	-- 冰锥：标记2人，集合分担
	-- 注意：日志里第一个目标名是字面 %s（boss 当前目标未被替换，也可能 %t），需解析 boss 当前目标；
	-- 第二个名字会被贪婪捕获带上句末标点，需剥离。
	local _, _, i1, i2 = string.find(msg, L["trigger_iceLance"])
	if i1 then
		self:IceLance(normalizeTarget(i1), normalizeTarget(i2))
		return
	end
end

-- 软泥怪「蠕动的异质」死亡时，精确触发毒池跑开（替代纯定时猜测）。
-- 保留核心 boss 死亡检测，避免覆盖默认 handler。
function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	BigWigs:CheckForBossDeath(msg, self)
	if self.oozeActive and not self.oozeDeadFired and string.find(msg, slimeName) then
		self:OozeDead()
	end
end

------------------------------
--      Ability: 烈焰之颅   --
------------------------------

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.flame and self.db.profile.flame then
		self:FlameCast()
	elseif sync == syncName.flameFrontSides and self.db.profile.flame then
		self:Message(L["msg_flameFrontSides"], "Important", true, "Beware")
	elseif sync == syncName.flameFrontBack and self.db.profile.flame then
		self:Message(L["msg_flameFrontBack"], "Important", true, "Beware")
	elseif sync == syncName.corrosion and self.db.profile.corrosion then
		self:Message(L["msg_corrosionCast"], "Important", nil, "voiceSwitch")
	end
end

function module:FlameCast()
	self:Bar(L["bar_flameCast"], timer.flameCast, icon.flameCast, true, color.flame)
	self:Message(L["msg_flame"], "Important", true, "Beware")

	if self.db.profile.flamecd then
		self:DelayedBar(timer.flameCast, L["bar_flame"], timer.flame, icon.flame, true, color.flamecd)
		self:DelayedMessage(timer.flameCast + timer.flame - 5, L["msg_flameSoon"], "Attention", nil, nil, true)
	end
end

------------------------------
--      Ability: 腐蚀之颅   --
------------------------------

function module:CorrosionMark(name)
	if not name or name == "" or not self.db.profile.corrosion then return end
	if not self.oozeTargets then self.oozeTargets = {} end
	if self.oozeTargets[name] then return end
	self.oozeTargets[name] = true

	local isYou = (name == UnitName("player"))
	if isYou then
		self:Message(L["msg_corrosionYou"], "Personal", true, "Alarm")
		self:WarningSign(icon.ooze, timer.oozeSlime, true)
	else
		self:Message(string.format(L["msg_corrosion"], name), "Important")
	end

	if self.db.profile.corrosionmark then
		local mark = self:GetAvailableRaidMark(nil, true)
		if mark then self:SetRaidTargetForPlayer(name, mark) end
	end

	-- 软泥集火 + 毒池跑开 的时间线，每个施法只启动一次
	if not self.oozeActive then
		self.oozeActive = true
		self:Bar(L["bar_oozeSlime"], timer.oozeSlime, icon.ooze, true, color.corrosion)
		self:ScheduleEvent("TriochOozeDead", self.OozeDead, timer.oozeSlime, self)
	end
end

function module:OozeDead()
	if not self.db.profile.corrosion then return end
	if self.oozeDeadFired then return end   -- 软泥死亡只触发一次毒池阶段
	self.oozeDeadFired = true
	self:CancelScheduledEvent("TriochOozeDead")   -- 以软泥死亡检测为准，取消定时兜底
	self.oozeActive = false
	self:Message(L["msg_oozeDead"], "Important", true, "Alarm")
	self:WarningSign(icon.poison, timer.oozePoison, true, L["bar_oozePoison"])
	self:Bar(L["bar_oozePoison"], timer.oozePoison, icon.poison, true, color.poison)
	self:ScheduleEvent("TriochOozePoisonEnd", self.OozePoisonEnd, timer.oozePoison, self)
end

function module:OozePoisonEnd()
	if self.oozeTargets then
		for name, _ in pairs(self.oozeTargets) do
			self:RestorePreviousRaidTargetForPlayer(name)
		end
		self.oozeTargets = {}
	end
	self.oozeActive = false
end

------------------------------
--      Ability: 冰锥       --
------------------------------

function module:IceLance(n1, n2)
	if not self.db.profile.icelance then return end
	local isYou = (n1 == UnitName("player")) or (n2 and n2 == UnitName("player"))
	self:Sound("voiceGather")

	if isYou then
		self:Message(L["msg_iceLanceYou"], "Personal", true, "Alarm")
	else
		self:Message(string.format(L["msg_iceLance"], n1 or "?", n2 or ""), "Important")
	end

	if not self.iceTargets then self.iceTargets = {} end
	local names = { n1, n2 }
	for _, nm in ipairs(names) do
		if nm and nm ~= "" and not self.iceTargets[nm] then
			self.iceTargets[nm] = true
			if self.db.profile.icelancemark then
				local mark = self:GetAvailableRaidMark(nil, true)
				if mark then self:SetRaidTargetForPlayer(nm, mark) end
			end
		end
	end

	if not self.iceActive then
		self.iceActive = true
		self:Bar(L["bar_iceLance"], timer.iceLanceHit, icon.icelance, true, color.icelance)
		self:ScheduleEvent("TriochIceEnd", self.IceEnd, timer.iceLanceHit, self)
	end
end

function module:IceEnd()
	if self.iceTargets then
		for name, _ in pairs(self.iceTargets) do
			self:RestorePreviousRaidTargetForPlayer(name)
		end
		self.iceTargets = {}
	end
	self.iceActive = false
end
