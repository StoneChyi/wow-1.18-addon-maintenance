local module, L = BigWigs:ModuleDeclaration("Archdruid Kronn", "Timbermaw Hold")
local bztimbermawhold = AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"]

module.revision = 30002
module.enabletrigger = { module.translatedName, "大德鲁伊科罗恩", "梦境中的科罗恩", "Archdruid Kronn", "Dreamform of Kronn" }
module.toggleoptions = {"hpframe", "dreamfever", "bodycasts", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

module.defaultDB = {
	hpframe = true,
	dreamfever = true,
	-- hpframeposx / hpframeposy computed in UpdateHpFrame on first frame
	-- creation so GetScreenWidth/Height return real values (they can be
	-- unreliable at file-load time).
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Kronn",

	hpframe_cmd = "hpframe",
	hpframe_name = "HP Frame",
	hpframe_desc = "Shows a frame with the HP of Archdruid Kronn and Dreamform of Kronn",

	kronn_label = "Kronn HP",
	dream_label = "Dream HP",

	kronn_dying = "DYING",
	dream_waking = "WAKING",

	trigger_engage = "You will not awaken him.",

	dreamfever_cmd = "dreamfever",
	dreamfever_name = "Dream Fever Alert",
	dreamfever_desc = "Warn when someone is afflicted by Dream Fever and mark them",

	trigger_feverYou = "^You are afflicted by Dream Fever",
	trigger_feverOther = "(.+) is afflicted by Dream Fever",
	trigger_feverFadeYou = "Dream Fever fades from you",
	trigger_feverFadeOther = "Dream Fever fades from (.+)%.",

	msg_feverYou = "DREAM FEVER ON YOU - GET AWAY FROM OTHERS!",
	msg_feverOther = "Dream Fever on %s - get away from them!",

	bodycasts_cmd = "bodycasts",
	bodycasts_name = "Body Cast Bars",
	bodycasts_desc = "Show 10s cast bars for Dreamform's Return to Body and Archdruid Kronn's Reform Body",

	trigger_returnBody = "Dreamform of Kronn begins to cast Return to Body%.",
	trigger_reformBody = "Archdruid Kronn begins to cast Reform Body%.",
	bar_returnBody = "Return to Body",
	bar_reformBody = "Reform Body",
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Kronn",

    hpframe_cmd = "hpframe",
    hpframe_name = "生命值框架",
    hpframe_desc = "显示大德鲁伊科罗恩及梦境中科罗恩的剩余生命值",

	kronn_label = "外场生命值",
	dream_label = "内场生命值",

	kronn_dying = "濒死中",
	dream_waking = "苏醒中",

    trigger_engage = "你休想唤醒他",

    dreamfever_cmd = "dreamfever",
    dreamfever_name = "狂热梦境警报",
    dreamfever_desc = "当有人受到狂热梦境影响时发出警告并标记",

    trigger_feverYou = "^你受到了狂热梦境效果的影响",
    trigger_feverOther = "(.+)受到了狂热梦境效果的影响",
    trigger_feverFadeYou = "狂热梦境效果从你身上消失了",
    trigger_feverFadeOther = "狂热梦境效果从(.+)身上消失",

    msg_feverYou = "你中了狂热梦境-远离其他人！",
    msg_feverOther = "%s中了狂热梦境-远离他/她！",

    bodycasts_cmd = "bodycasts",
    bodycasts_name = "躯体施法条",
    bodycasts_desc = "为回归躯体和重塑躯体显示10秒施法条",

    trigger_returnBody = "梦境中的科罗恩开始施放回归躯体",
    trigger_reformBody = "大德鲁伊科罗恩开始施放重塑躯体",
    bar_returnBody = "回归躯体",
    bar_reformBody = "重塑躯体",
} end )


local realKronn = "Archdruid Kronn"
local dreamKronn = "Dreamform of Kronn"

local icon = {
	fever = "Spell_Nature_NullifyDisease",
	returnBody = "Spell_Nature_Sleep",
	reformBody = "Spell_Shadow_UnholyStrength",
}

local timer = {
	bodyCast = 10,
}

local syncName = {
	kronnHp = "KronnHp"..module.revision,
	dreamHp = "KronnDreamHp"..module.revision,
	feverGain = "KronnFeverGain"..module.revision,
	feverFade = "KronnFeverFade"..module.revision,
	returnBody = "KronnReturnBody"..module.revision,
	reformBody = "KronnReformBody"..module.revision,
}

local feverGainPattern = "^"..syncName.feverGain.."(.+)"
local feverFadePattern = "^"..syncName.feverFade.."(.+)"

function module:OnSetup()
	self.kronnHp = nil
	self.dreamHp = nil
	self.victorySent = nil
	self.kronnDying = nil
	self.dreamWaking = nil
	self.feverTargets = {}
end

function module:OnEnable()
	self:ThrottleSync(1, syncName.kronnHp)
	self:ThrottleSync(1, syncName.dreamHp)
	self:ThrottleSync(5, syncName.returnBody)
	self:ThrottleSync(5, syncName.reformBody)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent") -- TODO: remove if BUFF covers casts properly
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")
	self:Message("友情提示：进入梦境前喝自然抗药水", "Important", false, nil, false)
end

function module:CastEvent(msg)
	if string.find(msg, L["trigger_returnBody"]) then
		self:Sync(syncName.returnBody)
	elseif string.find(msg, L["trigger_reformBody"]) then
		self:Sync(syncName.reformBody)
	end
end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_engage"]) then
		self:SendEngageSync()
	end
end

function module:OnEngage()
	self.kronnHp = nil
	self.dreamHp = nil
	self.victorySent = nil
	self.kronnDying = nil
	self.dreamWaking = nil
	self:CancelScheduledEvent("KronnDyingExpire")
	self:CancelScheduledEvent("KronnDreamWakeExpire")
	self.feverTargets = {}

	if self.db.profile.hpframe then
		self:UpdateHpFrame()
		self.hpFrame:Show()
	end
	self:ScheduleRepeatingEvent("KronnHpPoll", self.PollHp, 1, self)
end

function module:OnDisengage()
	self:CancelScheduledEvent("KronnHpPoll")
	self:CancelScheduledEvent("KronnDyingExpire")
	self:CancelScheduledEvent("KronnDreamWakeExpire")
	-- Framework auto-restores initialPlayerMarks on disengage (Core.lua:484-488)
	self.feverTargets = {}
	if self.hpFrame then
		self.hpFrame:Hide()
	end
end

function module:AfflictionEvent(msg)
	if string.find(msg, L["trigger_feverYou"]) then
		self:Sync(syncName.feverGain..UnitName("player"))
		return
	end
	local _, _, target = string.find(msg, L["trigger_feverOther"])
	if target then
		self:Sync(syncName.feverGain..target)
	end
end

function module:FadeEvent(msg)
	if string.find(msg, L["trigger_feverFadeYou"]) then
		self:Sync(syncName.feverFade..UnitName("player"))
		return
	end
	local _, _, target = string.find(msg, L["trigger_feverFadeOther"])
	if target then
		self:Sync(syncName.feverFade..target)
	end
end

function module:ZONE_CHANGED_NEW_AREA()
	if GetRealZoneText() ~= bztimbermawhold and self.hpFrame then
		self.hpFrame:Hide()
	end
end

function module:PollHp()
	local foundKronn, foundDream = false, false
	for i = 1, GetNumRaidMembers() do
		local unit = "raid"..i.."target"
		local name = UnitName(unit)
		if name == "大德鲁伊科罗恩" then
			foundKronn = true
			-- Archdruid Kronn never actually dies; the fight ends when he
			-- becomes non-hostile.
			if not UnitIsEnemy("player", unit) then
				if self.engaged and not self.victorySent then
					self.victorySent = true
					self:SendBossDeathSync()
				end
			else
				local h, m = UnitHealth(unit), UnitHealthMax(unit)
				if h and m and m > 0 then
					local pct = math.floor((h / m) * 100)
					self.kronnHp = pct
					self:Sync(syncName.kronnHp.." "..pct)
				end
			end
		elseif name == "梦境中的科罗恩" then
			foundDream = true
			local h, m = UnitHealth(unit), UnitHealthMax(unit)
			if h and m and m > 0 then
				local pct = math.floor((h / m) * 100)
				self.dreamHp = pct
				self:Sync(syncName.dreamHp.." "..pct)
			end
		end
		if foundKronn and foundDream then break end
	end
end

function module:UpdateHpFrame()
	if not self.db.profile.hpframe then return end

	if not self.hpFrame then
		local f = CreateFrame("Frame", "BigWigsKronnHpFrame", UIParent)
		f.module = self
		local frameW, frameH = 300, 70
		f:SetWidth(frameW)
		f:SetHeight(frameH)
		local s = f:GetEffectiveScale()

		-- Default to screen center if no saved position.
		if not self.db.profile.hpframeposx or not self.db.profile.hpframeposy then
			self.db.profile.hpframeposx = UIParent:GetWidth() / 2
			self.db.profile.hpframeposy = UIParent:GetHeight() / 2
		end

		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
			self.db.profile.hpframeposx / s - frameW / 2,
			self.db.profile.hpframeposy / s + frameH / 2)
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		f:SetBackdropColor(0, 0, 0, 1)

		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", function() this:StartMoving() end)
		f:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			local sc = this:GetEffectiveScale()
			this.module.db.profile.hpframeposx = this:GetLeft() * sc
			this.module.db.profile.hpframeposy = this:GetTop() * sc
		end)

		local font = "Fonts\\FRIZQT__.TTF"
		local fs = 16
		local midX = frameW / 2

		-- Left side: Kronn
		f.kronnLabel = f:CreateFontString(nil, "ARTWORK")
		f.kronnLabel:SetPoint("TOP", f, "TOPLEFT", midX / 2, -14)
		f.kronnLabel:SetFont(font, fs)
		f.kronnLabel:SetText(L["kronn_label"])
		f.kronnLabel:SetTextColor(1, 0.8, 0.3)

		f.kronnHpText = f:CreateFontString(nil, "ARTWORK")
		f.kronnHpText:SetPoint("TOP", f.kronnLabel, "BOTTOM", 0, -8)
		f.kronnHpText:SetFont(font, fs + 2)

		-- Right side: Dream
		f.dreamLabel = f:CreateFontString(nil, "ARTWORK")
		f.dreamLabel:SetPoint("TOP", f, "TOPLEFT", midX + midX / 2, -14)
		f.dreamLabel:SetFont(font, fs)
		f.dreamLabel:SetText(L["dream_label"])
		f.dreamLabel:SetTextColor(0.5, 0.5, 1)

		f.dreamHpText = f:CreateFontString(nil, "ARTWORK")
		f.dreamHpText:SetPoint("TOP", f.dreamLabel, "BOTTOM", 0, -8)
		f.dreamHpText:SetFont(font, fs + 2)

		self.hpFrame = f
	end

	-- Kronn: locked to DYING on Reform Body cast, otherwise show HP
	if self.kronnDying then
		self.hpFrame.kronnHpText:SetText(L["kronn_dying"])
		self.hpFrame.kronnHpText:SetTextColor(1, 0, 0)
	elseif self.kronnHp == nil then
		self.hpFrame.kronnHpText:SetText("--")
		self.hpFrame.kronnHpText:SetTextColor(0.7, 0.7, 0.7)
	else
		self.hpFrame.kronnHpText:SetText(self.kronnHp.."%")
		-- Green when low (dying), yellow mid, white high
		if self.kronnHp < 15 then
			self.hpFrame.kronnHpText:SetTextColor(0.3, 1, 0.3)
		elseif self.kronnHp < 35 then
			self.hpFrame.kronnHpText:SetTextColor(1, 1, 0)
		else
			self.hpFrame.kronnHpText:SetTextColor(1, 1, 1)
		end
	end

	-- Dream: locked to WAKING on Return to Body cast, otherwise show HP
	if self.dreamWaking then
		self.hpFrame.dreamHpText:SetText(L["dream_waking"])
		self.hpFrame.dreamHpText:SetTextColor(0.3, 1, 0.3)
	elseif self.dreamHp == nil then
		self.hpFrame.dreamHpText:SetText("--")
		self.hpFrame.dreamHpText:SetTextColor(0.7, 0.7, 0.7)
	else
		self.hpFrame.dreamHpText:SetText(self.dreamHp.."%")
		-- Green when high (filling), yellow mid, white low
		if self.dreamHp > 85 then
			self.hpFrame.dreamHpText:SetTextColor(0.3, 1, 0.3)
		elseif self.dreamHp > 65 then
			self.hpFrame.dreamHpText:SetTextColor(1, 1, 0)
		else
			self.hpFrame.dreamHpText:SetTextColor(1, 1, 1)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.kronnHp and rest then
		local n = tonumber(rest)
		if n then
			self.kronnHp = n
			if self.db.profile.hpframe then
				self:UpdateHpFrame()
			end
		end
	elseif sync == syncName.dreamHp and rest then
		local n = tonumber(rest)
		if n then
			self.dreamHp = n
			if self.db.profile.hpframe then
				self:UpdateHpFrame()
			end
		end
	elseif sync == syncName.returnBody then
		self.dreamWaking = true
		self:ScheduleEvent("KronnDreamWakeExpire", function()
			module.dreamWaking = nil
			module:UpdateHpFrame()
		end, timer.bodyCast)
		if self.db.profile.hpframe then
			self:UpdateHpFrame()
		end
		if self.db.profile.bodycasts then
			self:RemoveBar(L["bar_returnBody"])
			self:Bar(L["bar_returnBody"], timer.bodyCast, icon.returnBody, true, "Green")
			self:Sound("Info")
		end
	elseif sync == syncName.reformBody then
		self.kronnDying = true
		self:ScheduleEvent("KronnDyingExpire", function()
			module.kronnDying = nil
			module:UpdateHpFrame()
		end, timer.bodyCast)
		if self.db.profile.hpframe then
			self:UpdateHpFrame()
		end
		if self.db.profile.bodycasts then
			self:RemoveBar(L["bar_reformBody"])
			self:Bar(L["bar_reformBody"], timer.bodyCast, icon.reformBody, true, "Red")
			self:Sound("Info")
		end
	elseif self.db.profile.dreamfever then
		local _, _, feverTarget = string.find(sync, feverGainPattern)
		if feverTarget then
			self:FeverGain(feverTarget)
		else
			local _, _, fadeTarget = string.find(sync, feverFadePattern)
			if fadeTarget then
				self:FeverFade(fadeTarget)
			end
		end
	end
end

function module:FeverGain(target)
	if self.feverTargets[target] then return end
	self.feverTargets[target] = true

	local mark = self:GetAvailableRaidMark()
	if mark then
		self:SetRaidTargetForPlayer(target, mark)
	end

	if target == UnitName("player") then
		self:Message(L["msg_feverYou"], "Personal", true, "Alarm")
		self:WarningSign(icon.fever, 3, true)
	else
		local nearby = false
		for i = 1, GetNumRaidMembers() do
			local unit = "raid"..i
			if UnitName(unit) == target then
				nearby = UnitIsVisible(unit) and CheckInteractDistance(unit, 2)
				break
			end
		end
		if nearby then
			self:Message(string.format(L["msg_feverOther"], target), "Urgent", false, "Alert")
			self:WarningSign(icon.fever, 3, true)
		end
	end
end

function module:FeverFade(target)
	if not self.feverTargets[target] then return end
	self.feverTargets[target] = nil
	self:RestorePreviousRaidTargetForPlayer(target)
end

