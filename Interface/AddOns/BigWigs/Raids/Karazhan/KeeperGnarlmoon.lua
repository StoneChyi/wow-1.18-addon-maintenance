local module, L = BigWigs:ModuleDeclaration("Keeper Gnarlmoon", "Karazhan")

-- module variables
module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = { "moondebuff", "lunarshift", "ravens", "ravensbar", "bloodboil", -1, "owlphase", "owlenrage", "owlhpframe", "owlgaze", -1, "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}
-- module defaults
module.defaultDB = {
	moondebuff = true,
	lunarshift = true,
	ravens = true,
	ravensbar = true,
	bloodboil = true,
	owlphase = true,
	owlenrage = true,
	owlhpframe = true,
	owlframeposx = 100,
	owlframeposy = 400,
	owlgaze = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Gnarlmoon",

		moondebuff_cmd = "moondebuff",
		moondebuff_name = "Moon Debuff Alert",
		moondebuff_desc = "Warns when you get Red Moon or Blue Moon",

		lunarshift_cmd = "lunarshift",
		lunarshift_name = "Lunar Shift Alert",
		lunarshift_desc = "Warns when Keeper Gnarlmoon begins to cast Lunar Shift",

		ravens_cmd = "ravens",
		ravens_name = "Raven Alert",
		ravens_desc = "Alerts a few seconds before 12 Blood Ravens will appear (requires someone with SuperWoW in the raid)",

		ravensbar_cmd = "ravensbar",
		ravensbar_name = "Raven timer bar",
		ravensbar_desc = "Shows a timer bar for Flock of Ravens (requires someone with SuperWoW in the raid)",

		bloodboil_cmd = "bloodboil",
		bloodboil_name = "Blood Boil Alert",
		bloodboil_desc = "Timer for Keeper Gnarlmoon's Blood Boil ability",

		owlphase_cmd = "owlphase",
		owlphase_name = "Owl Phase Alert",
		owlphase_desc = "Warns about timing of the Owl phase",

		owlenrage_cmd = "owlenrage",
		owlenrage_name = "Owl Enrage Alert",
		owlenrage_desc = "Warns when the Owls are about to enrage",

		owlhpframe_cmd = "owlhpframe",
		owlhpframe_name = "Owl HP Frame",
		owlhpframe_desc = "Shows a frame with the owl HP during owl phases",

		owlgaze_cmd = "owlgaze",
		owlgaze_name = "Owl Gaze Alert",
		owlgaze_desc = "Warns when Owl Gaze is about to swap your Moon color",

		printkeeper_cmd = "printkeeper",
		printkeeper_name = "Troubleshoot Info",
		printkeeper_desc = "Print information to your main chat window: Owl kill time stamps",


		lowRedOwl = "Low Red Owl",
		lowBlueOwl = "Low Blue Owl",
		highRedOwl = "High Red Owl",
		highBlueOwl = "High Blue Owl",

		trigger_lunarShiftCast = "Keeper Gnarlmoon begins to perform Lunar Shift",
		bar_lunarShiftCast = "Lunar Shift Casting!",
		bar_lunarShiftCD = "Next Lunar Shift",
		msg_lunarShift = "Lunar Shift casting!",

		warn_lunarShift = "Lunar Shift",

		msg_ravensSoon = "12 ravens incoming",
		bar_ravens = "Flock of Ravens",

		msg_midHp = "Keeper Gnarlmoon < 71% - Owls Soon (@ 66%)!",
		msg_lowHp = "Keeper Gnarlmoon < 38% - Owls Soon (@ 33%)!",

		trigger_owlPhaseStart = "Keeper Gnarlmoon gains Worgen Dimension",
		trigger_owlKill = "Owl dies.", --CHAT_MSG_COMBAT_HOSTILE_DEATH
		trigger_owlPhaseEnd = "Worgen Dimension fades from Keeper Gnarlmoon",
		msg_owlPhaseStart = "Owl Phase begins - kill the owls at the same time within 1 min!",
		msg_owlPhaseEnd = "Owl Phase ended!",

		bar_owlEnrage = "Owls Enrage",
		msg_owlEnrage = "Owls will enrage in 10 seconds!",
		msg_owlsEnraged = "Owls Enraged!",

		trigger_owlGaze = "You are afflicted by Owl Gaze", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
		bar_owlGaze = "Color Change!",
		msg_owlGaze = "Imminent color change - swap sides!",
		warn_owlGaze = "OWL GAZE",

		trigger_redMoon = "afflicted by Red Moon",
		trigger_blueMoon = "afflicted by Blue Moon",
		msg_redMoon = "You have RED MOON!",
		msg_blueMoon = "You have BLUE MOON!",
		warn_redMoon = "<-- RED",
		warn_blueMoon = "BLUE -->",

		trigger_bloodBoil = "Keeper Gnarlmoon's Blood Boil hits",
		bar_bloodBoil = "Next Blood Boil",
	}
end)


L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Gnarlmoon",

		moondebuff_cmd = "moondebuff",
		moondebuff_name = "月之减益警报",
		moondebuff_desc = "当你受到红月或蓝月影响时发出警告",

		lunarshift_cmd = "lunarshift",
		lunarshift_name = "月相转换警报",
		lunarshift_desc = "当守护者纳尔穆恩开始施放月相转换时发出警告",

		ravens_cmd = "ravens",
		ravens_name = "血乌鸦警报",
		ravens_desc = "当12只血乌鸦出现时发出警告",

		ravensbar_cmd = "ravensbar",
		ravensbar_name = "血乌鸦计时条",
		ravensbar_desc = "显示血乌鸦计时条",
		bar_ravens = "血乌鸦",

		bloodboil_cmd = "bloodboil",
		bloodboil_name = "血液沸腾警报",
		bloodboil_desc = "守护者的血液沸腾技能计时器",

		owlphase_cmd = "owlphase",
		owlphase_name = "猫头鹰阶段警报",
		owlphase_desc = "当守护者纳尔穆恩进入或退出猫头鹰维度阶段时发出警告",

		owlenrage_cmd = "owlenrage",
		owlenrage_name = "猫头鹰激怒警报",
		owlenrage_desc = "当猫头鹰即将激怒时发出警告",

	    owlhpframe_cmd = "owlhpframe",
		owlhpframe_name = "猫头鹰血量监控",
		owlhpframe_desc = "在猫头鹰阶段显示监控猫头鹰血量的框架",

		owlgaze_cmd = "owlgaze",
		owlgaze_name = "猫头鹰凝视警报",
		owlgaze_desc = "当猫头鹰凝视即将改变你的颜色时发出警报",

		lowRedOwl = "红枭一",
		lowBlueOwl = "蓝枭一",
		highRedOwl = "红枭二",
		highBlueOwl = "蓝枭二",

		trigger_lunarShiftCast = "守护者纳尔穆恩开始施展月之转换",
		bar_lunarShiftCast = "月相转换施放中!",
		bar_lunarShiftCD = "下一次月相转换",
		msg_lunarShift = "月相转换施放中!",

		warn_lunarShift = "月相",

		msg_ravensSoon = "12只血乌鸦即将出现！",
		bar_ravens = "下一次血乌鸦",

		msg_midHp = "当前血量<71%-猫头鹰阶段即将开始（66%触发）",
		msg_lowHp = "当前血量<38%-猫头鹰阶段即将开始（33%触发）",

		trigger_owlPhaseStart = "守护者纳尔穆恩获得了狼人维度的效果",
		trigger_owlKill = "枭死亡了", --CHAT_MSG_COMBAT_HOSTILE_DEATH
		trigger_owlPhaseEnd = "狼人维度效果从守护者纳尔穆恩身上消失",
		msg_owlPhaseStart = "猫头鹰阶段-1分钟内同时击杀猫头鹰!",
		msg_owlPhaseEnd = "猫头鹰阶段结束!",

		bar_owlEnrage = "猫头鹰狂暴",
		msg_owlEnrage = "10秒后猫头鹰狂暴！",
		msg_owlsEnraged = "猫头鹰已狂暴！",

        trigger_owlGaze = "你受到了猫头鹰凝视效果的影响", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
		bar_owlGaze = "颜色即将改变！",
		msg_owlGaze = "即将改变颜色-交换位置！",
		warn_owlGaze = "猫头鹰凝视",

		trigger_redMoon = "受到了红月效果的影响",
		trigger_blueMoon = "受到了蓝月效果的影响",
		msg_redMoon = "你是红月!",
		msg_blueMoon = "你是蓝月!",

		warn_redMoon = "<--红色",
		warn_blueMoon = "蓝色-->",

		trigger_bloodBoil = "守护者纳尔穆恩的血液沸腾击中",
		bar_bloodBoil = "下一次血液沸腾",
	}
end)


-- timer and icon variables
local timer = {
	lunarShiftCast = 5,
	lunarShiftCD = 30,
	owlEnrage = 60,
	owlKill = 10,
	owlGaze = 2.5,
	ravenSummon = { 15, 35 },
	bloodBoil = 11,
}

local icon = {
	lunarShift = "Spell_Nature_StarFall",
	owlPhase = "Ability_EyeOfTheOwl",
	owlEnrage = "Spell_Shadow_UnholyFrenzy",
	owlGaze = "Ability_EyeOfTheOwl",
	redMoon = "inv_misc_orb_05",
	blueMoon = "inv_ore_arcanite_02",
	bloodBoil = "Spell_Shadow_BloodBoil",
	ravens = "Ability_Hunter_Pet_Bat",
}

local color = {
	lunarShift = "Blue",
	owlPhase = "Green",
	owlEnrage = "Red",
	bloodBoil = "Red",
	ravens = "Black",
}

local syncName = {
	lunarShift = "GnarlmoonLunarShift" .. module.revision,
	owlPhaseStart = "GnarlmoonOwlStart" .. module.revision,
	owlKill = "GnarlmoonOwlKill" .. module.revision,
	owlPhaseEnd = "GnarlmoonOwlEnd" .. module.revision,
	bloodBoil = "GnarlmoonBloodBoil" .. module.revision,
	ravens = "GnarlmoonRavens" .. module.revision,
}

local spellIds = {
	ravens = 51083, -- Flock of Ravens
}

function module:OnSetup()
	self.started = nil

	-- Used to monitor when owl phase will begin
	self.lowHp = nil
	self.midHp = nil
	self.gnarlHealth = 100

	-- Reset owl health values
	self.lowRedOwlHp = 100
	self.lowBlueOwlHp = 100
	self.highRedOwlHp = 100
	self.highBlueOwlHp = 100

	self.owlsExist = false
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")

	self:ThrottleSync(3, syncName.lunarShift)
	self:ThrottleSync(5, syncName.owlPhaseStart)
	self:ThrottleSync(25, syncName.owlKill) --only check 1 owl kill per phase
	self:ThrottleSync(5, syncName.owlPhaseEnd)
	self:ThrottleSync(5, syncName.bloodBoil)
	self:ThrottleSync(5, syncName.ravens)

	if SUPERWOW_VERSION then
		self:RegisterCastEventsForUnitName("Keeper Gnarlmoon", "GnarlmoonCastEvent")
		self:RegisterCastEventsForUnitName("守护者纳尔穆恩", "GnarlmoonCastEvent")
	end

	-- Store owl health
	self.lowRedOwlHp = 100
	self.lowBlueOwlHp = 100
	self.highRedOwlHp = 100
	self.highBlueOwlHp = 100

	-- Create the owl status frame but keep it hidden until needed
	if self.db.profile.owlhpframe then
		self:UpdateOwlStatusFrame()
		self.owlStatusFrame:Show() -- let people position before fight
	end
end

function module:OnEngage()
	if self.owlStatusFrame then
		self.owlStatusFrame:Hide()
	end

	-- Used to monitor when owl phase will begin
	self.lowHp = nil
	self.midHp = nil
	self.gnarlHealth = 100

	-- Make sure the owl frame is hidden at the start of the encounter
	self.owlsExist = false
	self:UpdateOwlStatusFrame()

	if self.db.profile.lunarshift then
		self:Bar(L["bar_lunarShiftCD"], timer.lunarShiftCD, icon.lunarShift, true, color.lunarShift)
	end

	if self.db.profile.ravensbar then
		self:Bar(L["bar_ravens"], timer.ravenSummon[1], icon.ravens, true, color.ravens)
	end
	if self.db.profile.ravens then
		self:DelayedMessage(timer.ravenSummon[1] - 5, L["msg_ravensSoon"], "Important")
	end

	self:ScheduleRepeatingEvent("CheckHps", self.CheckHps, 1, self)
end

function module:OnDisengage()
	if self:IsEventScheduled("CheckHps") then
		self:CancelScheduledEvent("CheckHps")
	end

	self.owlsExist = false
	self:UpdateOwlStatusFrame()
end

function module:CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE(msg)
	if string.find(msg, L["trigger_lunarShiftCast"]) then
		self:Sync(syncName.lunarShift)
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
	if string.find(msg, L["trigger_owlPhaseStart"]) then
		self:Sync(syncName.owlPhaseStart)
	end
end

function module:OnEnemyDeath(msg)
	if string.find(msg, L["trigger_owlKill"]) then
		self:Sync(syncName.owlKill)
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
	if string.find(msg, L["trigger_owlPhaseEnd"]) then
		self:Sync(syncName.owlPhaseEnd)
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE(msg)
	if self.db.profile.moondebuff then
		if string.find(msg, L["trigger_redMoon"]) then
			self:Message(L["msg_redMoon"], "Important", true, "Alarm")
			self:WarningSign(icon.redMoon, 5, true, L["warn_redMoon"])
		elseif string.find(msg, L["trigger_blueMoon"]) then
			self:Message(L["msg_blueMoon"], "Important", true, "Alert")
			self:WarningSign(icon.blueMoon, 5, true, L["warn_blueMoon"])
		end
	end
	if self.db.profile.owlgaze then
		if string.find(msg, L["trigger_owlGaze"]) then
			self:Message(L["msg_owlGaze"], "Important", true, "Beware")
			self:Bar(L["bar_owlGaze"], timer.owlGaze, icon.owlGaze, false)
			self:WarningSign(icon.owlGaze, timer.owlGaze, false, L["warn_owlGaze"])
		end
	end
end

function module:CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE(msg)
	if string.find(msg, L["trigger_bloodBoil"]) then
		self:Sync(syncName.bloodBoil)
	end
end

function module:BloodBoil()
	if self.db.profile.bloodboil then
		self:RemoveBar(L["bar_bloodBoil"])
		self:Bar(L["bar_bloodBoil"], timer.bloodBoil, icon.bloodBoil, true, color.bloodBoil)
	end
end

function module:GnarlmoonCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	if spellId == spellIds.ravens and eventType == "CAST" then
		self:Sync(syncName.ravens)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.lunarShift then
		self:LunarShift()
	elseif sync == syncName.owlPhaseStart then
		self:OwlPhaseStart()
	elseif sync == syncName.owlKill then
		self:OwlKill()
	elseif sync == syncName.owlPhaseEnd then
		self:OwlPhaseEnd()
	elseif sync == syncName.bloodBoil then
		self:BloodBoil()
	elseif sync == syncName.ravens then
		self:Ravens()
	end
end

function module:LunarShift()
	if self.db.profile.lunarshift then
		self:Message(L["msg_lunarShift"], "Important")
		self:RemoveBar(L["bar_lunarShiftCD"])
		self:Bar(L["bar_lunarShiftCast"], timer.lunarShiftCast, icon.lunarShift, true, color.lunarShift)
		self:DelayedBar(timer.lunarShiftCast, L["bar_lunarShiftCD"], timer.lunarShiftCD - timer.lunarShiftCast, icon.lunarShift, true, color.lunarShift)
		self:WarningSign(icon.lunarShift, 3, true, L.warn_lunarShift)
		self:Sound("yuexiang")
	end
end

function module:Ravens()
	if self.db.profile.ravensbar then
		self:RemoveBar(L["bar_ravens"])
		self:Bar(L["bar_ravens"], timer.ravenSummon[2], icon.ravens, true, color.ravens)
	end
	if self.db.profile.ravens then
		self:DelayedMessage(timer.ravenSummon[2] - 5, L["msg_ravensSoon"], "Important")
	end
end

function module:OwlPhaseStart()
	-- set owl hps to 100
	self.lowRedOwlHp = 100
	self.lowBlueOwlHp = 100
	self.highRedOwlHp = 100
	self.highBlueOwlHp = 100
	
	if self.db.profile.owlphase then		
		self:Message(L["msg_owlPhaseStart"], "Attention", nil, "Alarm")
	end

	if self.db.profile.owlenrage then
		self:Bar(L["bar_owlEnrage"], timer.owlEnrage, icon.owlEnrage, true, color.owlEnrage)
		self:DelayedMessage(timer.owlEnrage - timer.owlKill, L["msg_owlEnrage"], "Urgent")
		self:DelayedMessage(timer.owlEnrage, L["msg_owlsEnraged"], "Important")
	end

	-- Cancel Lunar Shift bars during owl phase
	self:RemoveBar(L["bar_lunarShiftCast"])
	self:RemoveBar(L["bar_lunarShiftCD"])

	-- Cancel Blood Boil bar during owl phase
	self:RemoveBar(L["bar_bloodBoil"])

	if self.db.profile.owlhpframe then
		self.owlsExist = true
		self:UpdateOwlStatusFrame()
	end
end

function module:OwlKill()
	local enrageBar, time, elapsed = self:BarStatus(L["bar_owlEnrage"])
	if self.db.profile.owlenrage and enrageBar and time - elapsed > timer.owlKill then -- if an owl dies >10s before enrage, shorten the timer
		--adjust bar
		self:Bar(L["bar_owlEnrage"], timer.owlKill, icon.owlEnrage, true, color.owlEnrage)
		--cancel scheduled enrage messages
		self:CancelDelayedMessage(L["msg_owlEnrage"])
		self:CancelDelayedMessage(L["msg_owlsEnraged"])
		--trigger 10s warning immediately
		self:Message(L["msg_owlEnrage"], "Urgent")
		--schedule new enrage announcement
		self:DelayedMessage(timer.owlKill, L["msg_owlsEnraged"], "Important")
	end
end

function module:OwlPhaseEnd()
	if self.db.profile.owlphase then
		self:Message(L["msg_owlPhaseEnd"], "Positive", nil, "Long")
	end

	local enrageBar, time, elapsed = self:BarStatus(L["bar_owlEnrage"])
	if enrageBar then
		if time - elapsed > timer.owlKill then -- more than 10s left
		self:CancelDelayedMessage(L["msg_owlEnrage"])
		end
		if time - elapsed > 0 then -- more than 0s left
			self:CancelDelayedMessage(L["msg_owlsEnraged"])
		end
		self:RemoveBar(L["bar_owlEnrage"])
	end

	self.owlsExist = false
	self:UpdateOwlStatusFrame()
end

function module:CheckHps()
	-- For tracking owl health
	local lowestRedOwlHp = 100
	local lowestBlueOwlHp = 100
	local highestRedOwlHp = 0
	local highestBlueOwlHp = 0

	for i = 1, GetNumRaidMembers() do
		local targetString = "raid" .. i .. "target"
		local targetName = UnitName(targetString)

		if targetName == module.translatedName then
			-- Check Gnarlmoon's health
			local tempH = UnitHealth(targetString)
			if tempH > 0 then
				local tempM = UnitHealthMax(targetString)
				if tempM and tempM > 0 then
					local health = tempH / tempM * 100
					if health < 100 then
						self.gnarlHealth = health
					end
				end
			end
		elseif self.owlsExist and targetName and string.find(targetName, "枭") then
			-- Calculate owl health percentage
			local owlHealth = 100
			local h = UnitHealth(targetString)
			local m = UnitHealthMax(targetString)

			if h and m and m > 0 then
				owlHealth = math.floor((h / m) * 100)
			end

			-- Check owl name to determine type and track lowest health
			if string.find(targetName, "红") then
				if owlHealth < lowestRedOwlHp then
					lowestRedOwlHp = owlHealth
				end
				if owlHealth > highestRedOwlHp then
					highestRedOwlHp = owlHealth
				end
			elseif string.find(targetName, "蓝") then
				if owlHealth < lowestBlueOwlHp then
					lowestBlueOwlHp = owlHealth
				end
				if owlHealth > highestBlueOwlHp then
					highestBlueOwlHp = owlHealth
				end
			end
		end
	end

	-- During test function, don't reset owl health
	if self.owlsExist and not self.testInProgress then
		-- Only update if the new health is lower than current health
		if lowestRedOwlHp < 100 then
			self.lowRedOwlHp = lowestRedOwlHp
		end

		if lowestBlueOwlHp < 100 then
			self.lowBlueOwlHp = lowestBlueOwlHp
		end

		if highestRedOwlHp > 0 then
			self.highRedOwlHp = highestRedOwlHp
		end

		if highestBlueOwlHp > 0 then
			self.highBlueOwlHp = highestBlueOwlHp
		end
	end

	if self.owlsExist then
		self:UpdateOwlStatusFrame()
	end

	-- Handle Gnarlmoon's health thresholds for phase warnings
	if self.gnarlHealth < 71 and self.midHp == nil then
		self.midHp = true
		self:Message(L["msg_midHp"], "Urgent", true, "Info")
	end

	if self.gnarlHealth < 38 and self.lowHp == nil then
		self.lowHp = true
		self:Message(L["msg_lowHp"], "Urgent", true, "Info")
	end
end

function module:UpdateOwlStatusFrame()
	if not self.db.profile.owlhpframe then
		return
	end

	-- Create frame if needed
	if not self.owlStatusFrame then
		self.owlStatusFrame = CreateFrame("Frame", "GnarlmoonOwlStatusFrame", UIParent)
		self.owlStatusFrame.module = self
		self.owlStatusFrame:SetWidth(200)  -- Wider to fit columns
		self.owlStatusFrame:SetHeight(90)  -- Increased height for more padding
		self.owlStatusFrame:ClearAllPoints()
		local s = self.owlStatusFrame:GetEffectiveScale()
		self.owlStatusFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (self.db.profile.owlframeposx or 100) / s, (self.db.profile.owlframeposy or 400) / s)
		self.owlStatusFrame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.owlStatusFrame:SetBackdropColor(0, 0, 0, 1)

		-- Allow dragging
		self.owlStatusFrame:SetMovable(true)
		self.owlStatusFrame:EnableMouse(true)
		self.owlStatusFrame:RegisterForDrag("LeftButton")
		self.owlStatusFrame:SetScript("OnDragStart", function()
			this:StartMoving()
		end)
		self.owlStatusFrame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()

			local scale = this:GetEffectiveScale()
			this.module.db.profile.owlframeposx = this:GetLeft() * scale
			this.module.db.profile.owlframeposy = this:GetTop() * scale
		end)

		local font = "Fonts\\FRIZQT__.TTF"
		local fontSize = 12

		-- Frame title
		self.owlStatusFrame.title = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.title:SetFontObject(GameFontNormal)
		self.owlStatusFrame.title:SetPoint("TOP", self.owlStatusFrame, "TOP", 0, -10)
		self.owlStatusFrame.title:SetText("猫头鹰生命值")
		self.owlStatusFrame.title:SetFont(font, fontSize)

		-- Red Column Header (Left Side)
		self.owlStatusFrame.redHeader = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.redHeader:SetFontObject(GameFontNormal)
		self.owlStatusFrame.redHeader:SetPoint("TOPLEFT", self.owlStatusFrame, "TOPLEFT", 15, -25)
		self.owlStatusFrame.redHeader:SetText("红")
		self.owlStatusFrame.redHeader:SetFont(font, fontSize)
		self.owlStatusFrame.redHeader:SetTextColor(1, 0.3, 0.3)

		-- Blue Column Header (Right Side)
		self.owlStatusFrame.blueHeader = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.blueHeader:SetFontObject(GameFontNormal)
		self.owlStatusFrame.blueHeader:SetPoint("TOPRIGHT", self.owlStatusFrame, "TOPRIGHT", -15, -25)
		self.owlStatusFrame.blueHeader:SetText("蓝")
		self.owlStatusFrame.blueHeader:SetFont(font, fontSize)
		self.owlStatusFrame.blueHeader:SetTextColor(0.3, 0.3, 1)

		-- Create invisible anchor frames for precise alignment
		local leftAnchor = CreateFrame("Frame", nil, self.owlStatusFrame)
		leftAnchor:SetPoint("CENTER", self.owlStatusFrame, "CENTER", -60, 0)
		leftAnchor:SetWidth(1)
		leftAnchor:SetHeight(1)

		local rightAnchor = CreateFrame("Frame", nil, self.owlStatusFrame)
		rightAnchor:SetPoint("CENTER", self.owlStatusFrame, "CENTER", 60, 0)
		rightAnchor:SetWidth(1)
		rightAnchor:SetHeight(1)

		-- Low Owls Row Label
		self.owlStatusFrame.lowLabel = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.lowLabel:SetFontObject(GameFontNormal)
		self.owlStatusFrame.lowLabel:SetPoint("CENTER", self.owlStatusFrame, "CENTER", 0, -10)
		self.owlStatusFrame.lowLabel:SetText("低")
		self.owlStatusFrame.lowLabel:SetFont(font, fontSize)

		-- High Owls Row Label
		self.owlStatusFrame.highLabel = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.highLabel:SetFontObject(GameFontNormal)
		self.owlStatusFrame.highLabel:SetPoint("CENTER", self.owlStatusFrame, "CENTER", 0, -30)
		self.owlStatusFrame.highLabel:SetText("高")
		self.owlStatusFrame.highLabel:SetFont(font, fontSize)

		-- Red Low Owl HP (left column)
		self.owlStatusFrame.lowRedOwlHp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.lowRedOwlHp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.lowRedOwlHp:SetPoint("CENTER", leftAnchor, "CENTER", 0, -10)
		self.owlStatusFrame.lowRedOwlHp:SetJustifyH("CENTER")
		self.owlStatusFrame.lowRedOwlHp:SetFont(font, fontSize)
		self.owlStatusFrame.lowRedOwlHp:SetTextColor(1, 0.3, 0.3)

		-- Blue Low Owl HP (right column)
		self.owlStatusFrame.lowBlueOwlHp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.lowBlueOwlHp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.lowBlueOwlHp:SetPoint("CENTER", rightAnchor, "CENTER", 0, -10)
		self.owlStatusFrame.lowBlueOwlHp:SetJustifyH("CENTER")
		self.owlStatusFrame.lowBlueOwlHp:SetFont(font, fontSize)
		self.owlStatusFrame.lowBlueOwlHp:SetTextColor(0.3, 0.3, 1)

		-- Red High Owl HP (left column)
		self.owlStatusFrame.highRedOwlHp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.highRedOwlHp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.highRedOwlHp:SetPoint("CENTER", leftAnchor, "CENTER", 0, -30)
		self.owlStatusFrame.highRedOwlHp:SetJustifyH("CENTER")
		self.owlStatusFrame.highRedOwlHp:SetFont(font, fontSize)
		self.owlStatusFrame.highRedOwlHp:SetTextColor(1, 0.3, 0.3)

		-- Blue High Owl HP (right column)
		self.owlStatusFrame.highBlueOwlHp = self.owlStatusFrame:CreateFontString(nil, "ARTWORK")
		self.owlStatusFrame.highBlueOwlHp:SetFontObject(GameFontNormal)
		self.owlStatusFrame.highBlueOwlHp:SetPoint("CENTER", rightAnchor, "CENTER", 0, -30)
		self.owlStatusFrame.highBlueOwlHp:SetJustifyH("CENTER")
		self.owlStatusFrame.highBlueOwlHp:SetFont(font, fontSize)
		self.owlStatusFrame.highBlueOwlHp:SetTextColor(0.3, 0.3, 1)
	end

	-- Show/hide frame based on whether owls exist
	if self.owlsExist then
		self.owlStatusFrame:Show()
	else
		self.owlStatusFrame:Hide()
		return
	end

	-- Update HP values
	self:SetOwlHpText(self.owlStatusFrame.lowBlueOwlHp, self.lowBlueOwlHp)
	self:SetOwlHpText(self.owlStatusFrame.lowRedOwlHp, self.lowRedOwlHp)
	self:SetOwlHpText(self.owlStatusFrame.highBlueOwlHp, self.highBlueOwlHp)
	self:SetOwlHpText(self.owlStatusFrame.highRedOwlHp, self.highRedOwlHp)
end

function module:SetOwlHpText(fontString, healthPercent)
	if not fontString then
		return
	end

	-- Format health percentage string
	local text = healthPercent .. "%"

	-- Color based on health percentage
	local r, g, b = 1, 1, 1
	if healthPercent <= 0 then
		text = "死亡"
		r, g, b = 0.5, 0.5, 0.5
	elseif healthPercent < 15 then
		r, g, b = 1, 1, 0
	end

	-- Set the text and color
	fontString:SetText(text)
	fontString:SetTextColor(r, g, b)
end

