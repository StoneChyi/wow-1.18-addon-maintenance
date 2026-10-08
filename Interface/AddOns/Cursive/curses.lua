if not Cursive.nampower then
	return
end
local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local _, playerClassName = UnitClass("player")

-- Nampower SPELL_MISS_* 的 missInfo：0 = 无未命中（不处理） by 武藤纯子酱 2026.9.10
local SPELL_MISS_NONE = 0
-- miss 守卫有效期（秒），需覆盖 AURA_CAST 延迟应用 + 网络延迟 by 武藤纯子酱 2026.9.10
local MISS_GUARD_DURATION = 0.75
-- miss 后校验目标光环的延迟（秒），等待服务器光环字段更新 by 武藤纯子酱 2026.9.10
local MISS_VERIFY_DELAY = 0.3

local curses = {
	trackedCurseIds = {},
	trackedCurseNamesToTextures = {},
	trackedCurseNameRanksToSpellSlots = {},
	conflagrateSpellIds = {
		[17962] = true,
		[18930] = true,
		[18931] = true,
		[18932] = true,
	},
	darkHarvestSpellIds = {
		[52550] = true,
		[52551] = true,
		[52552] = true,
	},
  travelTimeSpellIds = {},
	darkHarvestData = {},
	guids = {},
	isChanneling = false,
	pendingCast = {},
	resistSoundGuids = {},
	expiringSoundGuids = {},
	requestedExpiringSoundGuids = {}, -- guid added on spellcast, moved to expiringSoundGuids once rendered by ui
	missGuards = {}, -- miss 守卫：targetGuid -> { [curseName] = 过期时间 }，用于跳过未命中后的延迟乐观应用 by 武藤纯子酱 2026.9.10
	previousComboPoints = 0,
	comboPoints = 0,
	lastFerociousBiteTime = 0,
	lastFerociousBiteTargetGuid = 0,
	lastMoltenBlastTargetGuid = 0,

	sharedDebuffs = {
		faeriefire = {},
		sunderarmor = {}, -- 新增共享战士破甲攻击 by 武藤纯子酱 2025.9.10
		exposearmor = {}, -- 新增共享盗贼破甲 by 武藤纯子酱 2025.9.10
		huntersmark = {}, -- 新增共享猎人印记 by 武藤纯子酱 2025.9.10
		recklessness = {}, -- 新增共享鲁莽诅咒 by 武藤纯子酱 2025.9.10
		elements = {}, -- 新增共享元素诅咒 by 武藤纯子酱 2025.9.10
		shadow = {}, -- 新增共享暗影诅咒 by 武藤纯子酱 2025.9.10
		banish = {}, -- 新增共享放逐术默认占位 by 武藤纯子酱 2026.9.17
	},
	sharedDebuffGuids = {
		faeriefire = {}, -- used for scanning for shared debuffs like faerie fire
		sunderarmor = {}, -- 新增共享战士破甲攻击 by 武藤纯子酱 2025.9.10
		exposearmor = {}, -- 新增共享盗贼破甲 by 武藤纯子酱 2025.9.10
		huntersmark = {}, -- 新增共享猎人印记 by 武藤纯子酱 2025.9.10
		recklessness = {}, -- 新增共享鲁莽诅咒 by 武藤纯子酱 2025.9.10
		elements = {}, -- 新增共享元素诅咒 by 武藤纯子酱 2025.9.10
		shadow = {}, -- 新增共享暗影诅咒 by 武藤纯子酱 2025.9.10
		banish = {},   -- 新增共享放逐术 by 武藤纯子酱 2026.3.17
	}, -- used for scanning for shared debuffs like faerie fire

	-- Whitelist of mobs that can bleed (for rake tracking at client debuff cap)
	mobsThatBleed = {
		["0xF13000F1F3276A33"] = true, -- Keeper Gnarlmoon
		["0xF13000F1FA276A32"] = true, -- Ley-Watcher Incantagos
		["0xF13000EA3F276C05"] = true, -- King
		["0xF13000EA31279058"] = true, -- Queen
		["0xF13000EA43276C06"] = true, -- Bishop
		["0xF13000EA44279044"] = true, -- Pawn
		["0xF13000EA42276C07"] = true, -- Rook
		["0xF13000EA4D05DA44"] = true, -- Sanv Tas'dal
		["0xF13000EA57276C04"] = true, -- Kruul
		["0xF130016C95276DAF"] = true, -- Mephistroth

		["0xF130003E5401591A"] = true, --Anub'Rekhan
		["0xF130003E510159B0"] = true, --Grand Widow Faerlina
		["0xF130003E500159A3"] = true, --Maexxna
		["0xF130003EBD01598C"] = true, --Razuvious
		["0xF130003EBC01599F"] = true, --Gothik
		["0xF130003EBF015AB2"] = true, --Zeliek
		["0xF130003EBE015AB3"] = true, --Mograine
		["0xF130003EC1015AB1"] = true, --Blaumeux
		["0xF130003EC0015AB0"] = true, --Thane
		["0xF130003E52015824"] = true, --Noth
		["0xF130003E4001588D"] = true, --Heigan
		["0xF130003E8B0158A2"] = true, --Loatheb
		["0xF130003E9C0158EA"] = true, --Patchwerk
		["0xF130003E3B0158EF"] = true, --Grobbulus
		["0xF130003E3C0158F0"] = true, --Gluth
		["0xF130003E380159A0"] = true, --Thaddius
		["0xF130003E75015AB4"] = true, --Sapphiron
		["0xF130003E76015AED"] = true, --Kel'Thuzad
	},
  bleedImmuneMobs = { -- populated with mob names that fail VerifyMeleeBleedApplied to allow skipping future bleed checks
  }
}

-- 新增 by 武藤纯子酱 2025.8.28
local playertalent = {
	survivalhunter = nil,
	firemage = nil,
	malediction = nil, -- 新增 by 武藤纯子酱 2025.10.8	
}

local paladinsealtype = {
	--智慧圣印
	[20166] = 20186,
	[20356] = 20354,
	[20357] = 20355,
	[51745] = 51751,
	[51746] = 51752,
	--光明圣印
	[20165] = 20267,
	[20347] = 20341,
	[20348] = 20342,
	[20349] = 20343,
	--十字军圣印
	[21082] = 21183,
	[20162] = 21188,
	[20305] = 20300,
	[20306] = 20301,
	[20307] = 20302,
	[20308] = 20303,
	--公正圣印
	[20164] = 20184,
}

function curses:GetPlayerSealType()
	local i = 0
	while true do
		local auraid = GetPlayerBuffID(i)
		if not auraid then 
			break
		end

		if paladinsealtype[auraid] then --智慧圣印
			return paladinsealtype[auraid]
		end
		i = i + 1
	end
	return
end

function curses:GetPlayerTalentRank(talenttexture)
	-- 获取法术标签信息
	local numTabs = GetNumSpellTabs()
	for t=1, numTabs do
		local numTalents = GetNumTalents(t)
		for i=1, numTalents do
			local nameTalent,texture,_,_,currRank,maxRank = GetTalentInfo(t,i)
			if nameTalent and strfind(texture,talenttexture) then
				return tonumber(currRank)
			end					
		end
	end
	
	return 0
end

local afflict_test = L["%s is afflicted by %s (%d+)."]
local gains_test = L["%s gains %s (%d+)."]
-- 以上新增 by 武藤纯子酱 2025.8.28
-- combat events for curses
local fades_test = L["(.+) fades from (.+)"]

local lastGuid = nil

-- I think depending on ping the combo point used event can fire either before or after your ability cast
function curses:GetComboPointsUsed()
	if curses.comboPoints == 0 then
		return curses.previousComboPoints
	else
		return curses.comboPoints
	end
end


function curses:LoadCurses()
	-- reset dicts
	curses.trackedCurseIds = {}
	curses.trackedCurseNamesToTextures = {}
	curses.trackedCurseNameRanksToSpellSlots = {}

	curses.isWarlock = playerClassName == "WARLOCK"
	curses.isPriest = playerClassName == "PRIEST"
	curses.isMage = playerClassName == "MAGE"
	curses.isDruid = playerClassName == "DRUID"
	curses.isHunter = playerClassName == "HUNTER"
	curses.isRogue = playerClassName == "ROGUE"
	curses.isShaman = playerClassName == "SHAMAN"
	curses.isWarrior = playerClassName == "WARRIOR"
	curses.isPaladin = playerClassName == "PALADIN" -- 新增 by 武藤纯子酱 2025.8.29

	-- curses to track
	if curses.isWarlock then
		curses.trackedCurseIds = getWarlockSpells()
		playertalent.malediction = curses:GetPlayerTalentRank("Spell_Shadow_CurseOfAchimonde") -- 新增 by 武藤纯子酱 2025.10.8
	elseif curses.isPriest then
		curses.trackedCurseIds = getPriestSpells()
	elseif curses.isMage then
		curses.trackedCurseIds = getMageSpells()
		playertalent.firemage = curses:GetPlayerTalentRank("Spell_Fire_SoulBurn") -- 新增 by 武藤纯子酱 2025.9.1
	elseif curses.isDruid then
		curses.trackedCurseIds = getDruidSpells()
	elseif curses.isHunter then
		curses.trackedCurseIds = getHunterSpells()
	elseif curses.isRogue then
		curses.trackedCurseIds = getRogueSpells()
	elseif curses.isShaman then
		curses.trackedCurseIds = getShamanSpells()
	elseif curses.isWarrior then
		curses.trackedCurseIds = getWarriorSpells()
	elseif curses.isPaladin then -- 新增 by 武藤纯子酱 2025.8.29
		curses.trackedCurseIds = getPaladinSpells()
	end

  -- build travelTimeSpellIds from spell data
  -- travelTime spells must have a damage component otherwise it won't work
  curses.travelTimeSpellIds = {}
  for id, data in pairs(curses.trackedCurseIds) do
	if data.travelTime then
	  curses.travelTimeSpellIds[id] = true
	end
  end

  -- register travel time spell tracking
  if next(curses.travelTimeSpellIds) and not Cursive:IsEventRegistered("SPELL_DAMAGE_EVENT_SELF") then
	Cursive:RegisterEvent("SPELL_DAMAGE_EVENT_SELF", function(targetGuid, casterGuid, spellID, amount, mitigationStr, hitInfo, spellSchool, effectAuraStr)
	  if curses.travelTimeSpellIds[spellID] and curses.trackedCurseIds[spellID] then
		lastGuid = targetGuid
		local duration = curses:GetCurseDuration(spellID)
		curses:ApplyCurse(spellID, targetGuid, GetTime(), duration)
	  end
	end)
  end

	-- load shared debuffs
	curses.sharedDebuffs = getSharedDebuffs()
	-- 修复：兜底补齐 banish，避免旧版 shared_debuffs 缺少该表时索引报错 by 武藤纯子酱 2026.9.17
	if not curses.sharedDebuffs.banish then
		curses.sharedDebuffs.banish = {}
	end

  -- register faerie fire tracking from other players
  if Cursive.db.profile.shareddebuffs.faeriefire
  or Cursive.db.profile.shareddebuffs.sunderarmor -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.exposearmor -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.huntersmark -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.recklessness -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.elements -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.shadow -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  or Cursive.db.profile.shareddebuffs.banish -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
  then
	if not Cursive:IsEventRegistered("SPELL_GO_OTHER") then
	  Cursive:RegisterEvent("SPELL_GO_OTHER", function(itemId, spellID, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed)
		if curses.sharedDebuffs.faeriefire[spellID] then
		  curses.sharedDebuffGuids.faeriefire[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.sunderarmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.sunderarmor[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.exposearmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.exposearmor[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.huntersmark[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.huntersmark[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.recklessness[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.recklessness[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.elements[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.elements[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.shadow[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.shadow[targetGuid] = GetTime()
		end
		if curses.sharedDebuffs.banish[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
		  curses.sharedDebuffGuids.banish[targetGuid] = GetTime()
		end
	  end)
	end
  end

	-- go through spell slots and
	local i = 1
	while true do
		local spellname, spellrank = GetSpellName(i, BOOKTYPE_SPELL)
		if not spellname then
			break
		end

		if spellrank == "" then
			spellrank = L["Rank 1"]
		end

		curses.trackedCurseNameRanksToSpellSlots[string.lower(spellname) .. spellrank] = i
		i = i + 1
	end

	for id, data in pairs(curses.trackedCurseIds) do
		-- get the texture
		local texture = GetSpellIconTexture(GetSpellRecField(id, "spellIconID"))
		-- update trackedCurseNamesToTextures
		curses.trackedCurseNamesToTextures[data.name] = texture
		-- update trackedCurseIds
		curses.trackedCurseIds[id].texture = texture
	end

	if curses.isDruid or curses.isRogue then
		Cursive:RegisterEvent("PLAYER_COMBO_POINTS", function()
			local currentComboPoints = GetComboPoints()
			if curses.isDruid and currentComboPoints >= curses.comboPoints then
				-- combo points did not decrease, check if Ferocious Bite was used is the last .5 sec
				if GetTime() - curses.lastFerociousBiteTime < 0.5 and
						curses.lastFerociousBiteTargetGuid and
						curses.lastFerociousBiteTargetGuid ~= 0 then

					-- check if Rip active
					local rip = L["rip"]
					if curses:HasCurse(rip, curses.lastFerociousBiteTargetGuid, 0) then
						curses.guids[curses.lastFerociousBiteTargetGuid][rip]["start"] = GetTime() -- reset start time to current time
					end

					-- check if Rake active
					local rake = L["rake"]
					if curses:HasCurse(rake, curses.lastFerociousBiteTargetGuid, 0) then
						curses.guids[curses.lastFerociousBiteTargetGuid][rake]["start"] = GetTime() -- reset start time to current time
					end
				end
			end
			curses.previousComboPoints = curses.comboPoints
			curses.comboPoints = currentComboPoints
		end)
	end
end
-- 修改支持非追踪技能的持续时间识别 by 武藤纯子酱 2025.8.30
function curses:ScanTooltipForDuration(curseSpellID)
	local OK, duration = pcall(GetSpellDuration,curseSpellID)
	if OK then
		return duration/1000
	else
		return 0
	end
end

function curses:GetCurseDuration(curseSpellID) -- 修复nil报错 by 武藤纯子酱 2025.9.1
	if curses.trackedCurseIds[curseSpellID] and curses.trackedCurseIds[curseSpellID].variableDuration then
		return curses:ScanTooltipForDuration(curseSpellID)
	elseif curses.trackedCurseIds[curseSpellID] and curses.trackedCurseIds[curseSpellID].calculateDuration then
		return curses.trackedCurseIds[curseSpellID].calculateDuration()
	elseif curses.trackedCurseIds[curseSpellID] then
		return curses.trackedCurseIds[curseSpellID].duration
	else
		return curses:ScanTooltipForDuration(curseSpellID)
	end	
end

function curses:ScanGuidForCurse(guid, curseSpellID)
  local auras = GetUnitField(guid, "aura") or {}
  for i, spellID in pairs(auras) do
    if spellID == curseSpellID then
      return true
		end
	end

	return nil
end

function curses:GetLowercaseSpellName(spellName)
	spellName = string.lower(spellName)

	-- handle faerie fire special case
	if curses.isDruid and string.find(spellName, L["faerie fire"]) then
		return L["faerie fire"]
	end

	return spellName
end

Cursive:RegisterEvent("LEARNED_SPELL_IN_TAB", function()
	-- reload curses in case spell slots changed
	curses:LoadCurses()
end)

local function StopChanneling()
	curses.isChanneling = false
end

local function GetAppliedCurseSpellID(spellID)
	local curseData = curses.trackedCurseIds[spellID]
	if curseData and curseData.debuffSpellId then
		return curseData.debuffSpellId
	end

	return spellID
end

local function VerifyMeleeBleedApplied(targetGuid, spellID)
	local curseData = curses.trackedCurseIds[spellID]
	if not curseData or not curseData.meleeBleed then
		return
	end

	if not curses.guids[targetGuid] or not curses.guids[targetGuid][curseData.name] then
		return
	end

  if not UnitExists(targetGuid) then
    return
  end

  local hasFullBuffsAndDebuffs = true
	local appliedSpellID = GetAppliedCurseSpellID(spellID)
	local auras = GetUnitField(targetGuid, "aura") or {}
	for i, auraSpellID in pairs(auras) do
		if auraSpellID == appliedSpellID then
			return
    elseif auraSpellID <= 0 then
      hasFullBuffsAndDebuffs = false
		end
	end

  if not hasFullBuffsAndDebuffs then
    local mobName = UnitName(targetGuid)
    if mobName then
      curses.bleedImmuneMobs[mobName] = true
    end
  end

	curses:RemoveCurse(targetGuid, curseData.name)
end

-- 新增：miss 后延迟校验目标身上是否真的没有该 debuff，没有则移除图标 by 武藤纯子酱 2026.9.10
local function VerifyMissedCurse(targetGuid, spellID)
	if not targetGuid or not UnitExists(targetGuid) then
		return
	end

	local curseData = curses.trackedCurseIds[spellID]
	if not curseData then
		return
	end

	-- 若目标身上实际存在该 debuff（例如本次只是刷新失败、旧 debuff 仍在），则保留显示
	local appliedSpellID = GetAppliedCurseSpellID(spellID)
	if not curses:ScanGuidForCurse(targetGuid, appliedSpellID) then
		curses:RemoveCurse(targetGuid, string.lower(curseData.name))
	end
end

-- 新增：处理任意法术未命中（miss/resist/dodge/parry/block/evade/immune/deflect/absorb/reflect）
-- 设置守卫阻止延迟的乐观应用，并延迟校验实际光环后移除误加图标 by 武藤纯子酱 2026.9.10
local function HandleSpellMiss(targetGuid, spellID)
	if not targetGuid or not curses.trackedCurseIds[spellID] then
		return
	end

	local name = string.lower(curses.trackedCurseIds[spellID].name)

	if not curses.missGuards[targetGuid] then
		curses.missGuards[targetGuid] = {}
	end
	curses.missGuards[targetGuid][name] = GetTime() + MISS_GUARD_DURATION

	Cursive:ScheduleEvent("verifyMiss" .. targetGuid .. name, VerifyMissedCurse, MISS_VERIFY_DELAY, targetGuid, spellID)
end

-- 新增：判断该次 debuff 应用是否处于 miss 守卫窗口内（应跳过） by 武藤纯子酱 2026.9.10
local function IsMissGuarded(targetGuid, spellID)
	local guard = curses.missGuards[targetGuid]
	if not guard or not curses.trackedCurseIds[spellID] then
		return false
	end

	local name = string.lower(curses.trackedCurseIds[spellID].name)
	local expiry = guard[name]
	if not expiry then
		return false
	end

	if GetTime() > expiry then
		guard[name] = nil
		return false
	end

	return true
end

Cursive:RegisterEvent("SPELLCAST_CHANNEL_START", function()
	curses.isChanneling = true
end);
Cursive:RegisterEvent("SPELLCAST_CHANNEL_STOP", StopChanneling);
Cursive:RegisterEvent("SPELLCAST_INTERRUPTED", StopChanneling);

-- player spell completions
Cursive:RegisterEvent("SPELL_GO_SELF", function(itemId, spellID, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed)
  if curses.travelTimeSpellIds[spellID] and numTargetsMissed == 0 then
			curses.pendingCast = {
				spellID = spellID,
				targetGuid = targetGuid,
			}
  end

  if curses.isPaladin then --新增 by 武藤纯子酱 2025.8.29
	if spellID == 20271 and curses:GetPlayerSealType() then
	  spellID = curses:GetPlayerSealType()
	elseif ( spellID == 679 or spellID == 678 or spellID == 1866 or spellID == 680 or spellID == 2495 or spellID == 5569 or spellID == 10332 or spellID == 10333 ) 
	or ( spellID == 2537 or spellID == 8823 or spellID == 8824 or spellID == 10336 or spellID == 10337 ) then
	  if curses:HasCurse(L["judgement of wisdom"], targetGuid) then
		spellID = curses.guids[targetGuid][L["judgement of wisdom"]].spellID
	  elseif curses:HasCurse(L["judgement of light"], targetGuid) then
		spellID = curses.guids[targetGuid][L["judgement of light"]].spellID
	  elseif curses:HasCurse(L["judgement of the crusader"], targetGuid) then
		spellID = curses.guids[targetGuid][L["judgement of the crusader"]].spellID
	  elseif curses:HasCurse(L["judgement of justice"], targetGuid) then
		spellID = curses.guids[targetGuid][L["judgement of justice"]].spellID
	  end
	else
	  return
	end
  end
		
  if curses.isMage then --新增 by 武藤纯子酱 2025.9.1
	if not playertalent.firemage or playertalent.firemage == 0 then	
	  playertalent.firemage = curses:GetPlayerTalentRank("Spell_Fire_SoulBurn")
	end	
			
	if playertalent.firemage ~= 3 then
	  return
	elseif ( spellID == 2948 or spellID == 8444 or spellID == 8445 or spellID == 8446 or spellID == 10205 or spellID == 10206 or spellID == 10207 -- 灼烧 by 武藤纯子酱 2025.10.15
	or spellID == 2136 or spellID == 2137 or spellID == 2138 or spellID == 8412 or spellID == 8413 or spellID == 10197 or spellID == 10199 ) then -- 火焰冲击 by 武藤纯子酱 2025.10.15
	  spellID = 22959
	end
  end

  if curses.isDruid then
	-- track ferocious bite cast time and target
	if spellID == 22557 or
		spellID == 22568 or
		spellID == 22827 or
		spellID == 22828 or
		spellID == 22829 or
		spellID == 31018 then
	  curses.lastFerociousBiteTime = GetTime()
	  curses.lastFerociousBiteTargetGuid = targetGuid
	end
  end

  if curses.isShaman then
	if spellID >= 36916 and spellID <= 36921 then
	  curses.lastMoltenBlastTargetGuid = targetGuid
	  if numTargetsHit > 0 then
		local flame_shock = L["flame shock"]
		if curses:HasCurse(flame_shock, targetGuid, 0) then
		  curses.guids[targetGuid][flame_shock]["start"] = GetTime()
		end
	  end
	end
  end

  if numTargetsHit > 0 then
	if curses.trackedCurseIds[spellID] and not curses.travelTimeSpellIds[spellID] then
			lastGuid = targetGuid
      local curseData = curses.trackedCurseIds[spellID]
      if curseData.meleeBleed then
        if numTargetsMissed > 0 then
          -- I think this will always mean the bleed missed and we can skip the extra bleed immunity logic
          return
        end
        local mobName = UnitName(targetGuid)
        local isBleedImmuneMob = mobName and mobName ~= "" and curses.bleedImmuneMobs[mobName]
        if not isBleedImmuneMob then
          local duration = curses:GetCurseDuration(spellID)
          curses:ApplyCurse(spellID, targetGuid, GetTime(), duration)
          if not curses.mobsThatBleed[targetGuid] then
            Cursive:ScheduleEvent(VerifyMeleeBleedApplied, 1, targetGuid, spellID)
          end
        end
      else
        local duration = curses:GetCurseDuration(spellID)
        curses:ApplyCurse(spellID, targetGuid, GetTime(), duration)
      end
		elseif curses.conflagrateSpellIds[spellID] then
	  curses:UpdateCurse(spellID, targetGuid, GetTime())
		end
  end
end)

-- player spell start (cast time spells)
Cursive:RegisterEvent("SPELL_START_SELF", function(itemId, spellID, casterGuid, targetGuid, castFlags, castTime)
  if curses.trackedCurseIds[spellID] then
	curses.pendingCast = {
	  spellID = spellID,
	  targetGuid = targetGuid,
	}
  end
end)

-- player spell failure
Cursive:RegisterEvent("SPELL_FAILED_SELF", function(spellID, spellResult, failedByServer)
  if curses.trackedCurseIds[spellID] then
	curses.pendingCast = {}
  end
end)

-- player channel start (dark harvest)
Cursive:RegisterEvent("SPELL_CHANNEL_START", function(spellID, targetGuid, durationMs)
  if curses.darkHarvestSpellIds[spellID] then
	curses.darkHarvestData = {
	  spellID = spellID,
	  targetGuid = targetGuid,
      castDuration = durationMs / 1000,
	  start = GetTime()
	}
	end
end)

Cursive:RegisterEvent("SPELL_MISS_SELF", function(casterGuid, targetGuid, spellID, missInfo)
  curses.pendingCast = {}

  -- 新增：任意未命中（miss/resist/dodge/parry/block/evade/immune/deflect/absorb/reflect）
  -- 都校验并取消误加的 debuff 图标 by 武藤纯子酱 2026.9.10
  if missInfo and missInfo ~= SPELL_MISS_NONE then
	HandleSpellMiss(targetGuid, spellID)
  end

  if curses.trackedCurseIds[spellID] and lastGuid then
	if curses:ShouldPlayResistSound(lastGuid) then
	  PlaySoundFile("Interface\\AddOns\\Cursive\\Sounds\\resist.mp3")
	end
  end
end)

-- 新增：宠物/被控单位施法的未命中同样处理 by 武藤纯子酱 2026.9.10
Cursive:RegisterEvent("SPELL_MISS_OTHER", function(casterGuid, targetGuid, spellID, missInfo)
	if not missInfo or missInfo == SPELL_MISS_NONE or not curses.trackedCurseIds[spellID] then
		return
	end

	local playerGuid = GetUnitGUID("player")
	local isOurs = (casterGuid == playerGuid)
	if not isOurs and casterGuid then
		local owner = GetUnitGUID(casterGuid.."owner")
		local charmer = GetUnitField(casterGuid, "charm")
		local creater = GetUnitField(casterGuid, "createdBy")
		isOurs = (owner and owner == playerGuid) or (charmer and charmer == playerGuid) or (creater and creater == playerGuid)
	end

	if isOurs then
		HandleSpellMiss(targetGuid, spellID)
	end
end)

Cursive:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", function(message)
	-- check if spell that faded is relevant
	local _, _, spellName, target = string.find(message, fades_test)
	if spellName and target then
		spellName = curses:GetLowercaseSpellName(spellName)
		if curses.trackedCurseNamesToTextures[spellName] then
			-- loop through targets with active curses
			for guid, data in pairs(curses.guids) do
				for curseName, curseData in pairs(data) do
					if curseName == spellName then
						-- see if target still has that curse
						if not curses:ScanGuidForCurse(guid, curseData.appliedSpellID or curseData.spellID) then
							-- remove curse
							curses:RemoveCurse(guid, curseName)
						end
					end
				end
			end
		end
	end
end
)

-- 新增DEBUFF_ADDED_OTHER by 武藤纯子酱 2026.3.30
Cursive:RegisterEvent("DEBUFF_ADDED_OTHER", function(targetGuid, luaSlot, spellID, stacks, auraLevel, auraSlot, state)
  if Cursive.db.profile.shareddebuffs.faeriefire and curses.sharedDebuffs.faeriefire[spellID] then
    curses.sharedDebuffGuids.faeriefire[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.sunderarmor and curses.sharedDebuffs.sunderarmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.sunderarmor[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.exposearmor and curses.sharedDebuffs.exposearmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.exposearmor[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.huntersmark and curses.sharedDebuffs.huntersmark[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.huntersmark[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.recklessness and curses.sharedDebuffs.recklessness[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.recklessness[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.elements and curses.sharedDebuffs.elements[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.elements[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.shadow and curses.sharedDebuffs.shadow[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.shadow[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.banish and curses.sharedDebuffs.banish[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.30
    curses.sharedDebuffGuids.banish[targetGuid] = GetTime()
  end
end)

-- 新增SPELL_GO_OTHER by 武藤纯子酱 2026.3.18
Cursive:RegisterEvent("SPELL_GO_OTHER", function(itemId, spellID, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed)
  if Cursive.db.profile.shareddebuffs.faeriefire and curses.sharedDebuffs.faeriefire[spellID] then
    curses.sharedDebuffGuids.faeriefire[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.sunderarmor and curses.sharedDebuffs.sunderarmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.sunderarmor[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.exposearmor and curses.sharedDebuffs.exposearmor[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.exposearmor[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.huntersmark and curses.sharedDebuffs.huntersmark[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.huntersmark[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.recklessness and curses.sharedDebuffs.recklessness[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.recklessness[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.elements and curses.sharedDebuffs.elements[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.elements[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.shadow and curses.sharedDebuffs.shadow[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.shadow[targetGuid] = GetTime()
  elseif Cursive.db.profile.shareddebuffs.banish and curses.sharedDebuffs.banish[spellID] then -- 新增共享DEBUFF by 武藤纯子酱 2026.3.18
    curses.sharedDebuffGuids.banish[targetGuid] = GetTime()
  end

  local casterownerGuid = GetUnitGUID(casterGuid.."owner")
  if not casterownerGuid or ( casterownerGuid ~= GetUnitGUID("player") ) then
	return
  end

  if numTargetsMissed > 0 then
	curses.pendingCast = {}
  elseif numTargetsHit > 0 or curses.travelTimeSpellIds[spellID] then
		curses.pendingCast = {
			spellID = spellID,
			targetGuid = targetGuid,
		}
  end

  if numTargetsHit > 0 then
	if curses.trackedCurseIds[spellID] and not curses.travelTimeSpellIds[spellID] then
			lastGuid = targetGuid
	  local duration = curses:GetCurseDuration(spellID)
	  curses:ApplyCurse(spellID, targetGuid, GetTime(), duration)
		elseif curses.conflagrateSpellIds[spellID] then
	  curses:UpdateCurse(spellID, targetGuid, GetTime())
		end
  end
end)

-- 新增AURA_CAST_ON_OTHER by 武藤纯子酱 2026.2.12
Cursive:RegisterEvent("AURA_CAST_ON_OTHER", function(spellID, casterGuid, targetGuid, effect, effectAuraName, effectAmplitude, effectMiscValue, durationMs, auraCapStatus)
	if not casterGuid then return end
	local charmer = GetUnitField(casterGuid, "charm")
	local creater = GetUnitField(casterGuid, "createdBy")
	local casterownerGuid = GetUnitGUID(casterGuid.."owner")
	local playerGuid = GetUnitGUID("player")
	if casterGuid == playerGuid or ( casterownerGuid and casterownerGuid == playerGuid ) or ( charmer and charmer == playerGuid ) or ( creater and creater == playerGuid ) then

		-- delay to check for resists/failures
		local delay = 0.2

		local _, _, nping = GetNetStats()
		-- ignore extreme pings
		if nping and nping > 0 and nping < 500 then
			delay = 0.05 + (nping / 1000.0) -- convert to seconds
		end

		if curses.trackedCurseIds[spellID] and targetGuid and durationMs and durationMs > 0 then
			if curses.isDruid and curses.trackedCurseIds[spellID].name == L["rip"] then
				return
			elseif curses.isRogue and curses.trackedCurseIds[spellID].name == L["rupture"] or curses.trackedCurseIds[spellID].name == L["gouge"] or curses.trackedCurseIds[spellID].name == L["kidney shot"] then
				return
			end
			
			lastGuid = targetGuid
			local duration = durationMs/1000 - delay
			Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, delay, self, spellID, targetGuid, GetTime(), duration)
		elseif curses.conflagrateSpellIds[spellID] then
			Cursive:ScheduleEvent("updateCurse" .. targetGuid .. L["conflagrate"], curses.UpdateCurse, delay, self, spellID, targetGuid, GetTime())
		end
		
		if GetSpellRecField(spellID, "name") == L["immolation trap effect"] then
			playertalent.survivalhunter = curses:GetPlayerTalentRank("INV_Misc_Herb_16")
		
			local spellID = curses:GetHighestRankSpellId(L["serpent sting"])
			local castDuration = (curses.trackedCurseIds[spellID].duration)*0.2*playertalent.survivalhunter - 0.2

			if targetGuid and curses.trackedCurseIds[spellID] then
				lastGuid = targetGuid
				Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, 0.2, self, spellID, targetGuid, GetTime(), castDuration)
			end
		end
	end
end
)

-- 新增SPELL_DAMAGE_EVENT_SELF by 武藤纯子酱 2026.3.18
Cursive:RegisterEvent("SPELL_DAMAGE_EVENT_SELF", function(targetGuid, casterGuid, spellID, amount, mitigation, hitInfo, spellSchool, effectAura)
	if hitInfo and bit.band(hitInfo, 2) ~= 0 and spellSchool and spellSchool == 2 then 
		if curses.isMage then --新增 by 武藤纯子酱 2025.9.1
			if not playertalent.firemage or playertalent.firemage == 0 then	
				playertalent.firemage = curses:GetPlayerTalentRank("Spell_Fire_SoulBurn")
			end	

			if playertalent.firemage == 3 then
				-- delay to check for resists/failures
				local delay = 0.2
				local spellID = 12654
				local _, _, nping = GetNetStats()
				-- ignore extreme pings
				if nping and nping > 0 and nping < 500 then
					delay = 0.05 + (nping / 1000.0) -- convert to seconds
				end

				if curses.trackedCurseIds[spellID] then
					lastGuid = targetGuid
					local duration = curses:GetCurseDuration(spellID) - delay
					Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, delay, self, spellID, targetGuid, GetTime(), duration)
				end	
			end
		end		
	end
end
)

-- 新增SPELL_DAMAGE_EVENT_OTHER by 武藤纯子酱 2026.3.18
Cursive:RegisterEvent("SPELL_DAMAGE_EVENT_OTHER", function(targetGuid, casterGuid, spellID, amount, mitigation, hitInfo, spellSchool, effectAura)
	local charmer = GetUnitField(casterGuid, "charm")
	local creater = GetUnitField(casterGuid, "createdBy")
	local casterownerGuid = GetUnitGUID(casterGuid.."owner")
	if ( charmer and charmer ~= "0x0000000000000000" ) or ( creater and creater ~= "0x0000000000000000" ) or ( casterownerGuid and casterownerGuid ~= "0x0000000000000000" ) then
		local playerGuid = GetUnitGUID("player")
		if charmer == playerGuid or creater == playerGuid or casterownerGuid == playerGuid then
			-- delay to check for resists/failures
			local delay = 0.2

			local _, _, nping = GetNetStats()
			-- ignore extreme pings
			if nping and nping > 0 and nping < 500 then
				delay = 0.05 + (nping / 1000.0) -- convert to seconds
			end

			if curses.trackedCurseIds[spellID] and targetGuid then
				if curses.isDruid and curses.trackedCurseIds[spellID].name == L["rip"] then
					return
				elseif curses.isRogue and curses.trackedCurseIds[spellID].name == L["rupture"] or curses.trackedCurseIds[spellID].name == L["gouge"] or curses.trackedCurseIds[spellID].name == L["kidney shot"] then
					return
				end
				
				lastGuid = targetGuid
				local duration = curses:GetCurseDuration(spellID)
				Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, delay, self, spellID, targetGuid, GetTime(), duration)
			elseif curses.conflagrateSpellIds[spellID] then
				Cursive:ScheduleEvent("updateCurse" .. targetGuid .. L["conflagrate"], curses.UpdateCurse, delay, self, spellID, targetGuid, GetTime())
			end
			
			if GetSpellRecField(spellID, "name") == L["immolation trap effect"] or GetSpellRecField(spellID, "name") == L["explosive trap effect"] then
				playertalent.survivalhunter = curses:GetPlayerTalentRank("INV_Misc_Herb_16")
			
				local spellID = curses:GetHighestRankSpellId(L["serpent sting"])
				local castDuration = (curses.trackedCurseIds[spellID].duration)*0.2*playertalent.survivalhunter - 0.2

				if targetGuid and curses.trackedCurseIds[spellID] then
					lastGuid = targetGuid
					Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, 0.2, self, spellID, targetGuid, GetTime(), castDuration)
				end
			end
		end
	end
end
)

-- 新增AUTO_ATTACK_SELF by 武藤纯子酱 2026.3.18
Cursive:RegisterEvent("AUTO_ATTACK_SELF", function(attackerGuid, targetGuid, totalDamage, hitInfo, victimState, subDamageCount, blockedAmount, totalAbsorb, totalResist)
	if playerClassName == "PALADIN" and victimState == 1 then
		local spellID
		if curses:HasCurse(L["judgement of wisdom"], targetGuid) then
			spellID = curses.guids[targetGuid][L["judgement of wisdom"]].spellID
		elseif curses:HasCurse(L["judgement of light"], targetGuid) then
			spellID = curses.guids[targetGuid][L["judgement of light"]].spellID
		elseif curses:HasCurse(L["judgement of the crusader"], targetGuid) then
			spellID = curses.guids[targetGuid][L["judgement of the crusader"]].spellID
		elseif curses:HasCurse(L["judgement of justice"], targetGuid) then
			spellID = curses.guids[targetGuid][L["judgement of justice"]].spellID
		end

		if targetGuid and curses.trackedCurseIds[spellID] then			
			local castDuration = curses.trackedCurseIds[spellID].duration - 0.2			
			lastGuid = targetGuid
			Cursive:ScheduleEvent("addCurse" .. targetGuid .. curses.trackedCurseIds[spellID].name, curses.ApplyCurse, 0.2, self, spellID, targetGuid, GetTime(), castDuration)
		end			
	end
end
)

function curses:GetLastTickTime(curseData)
	local ticks = curses.trackedCurseIds[curseData.spellID].numTicks
	if not ticks then
		return GetTime()
	end

	local tickTime = curseData.duration / ticks
	local currentTime = GetTime()

	return math.floor((currentTime - curseData.start) / tickTime) * tickTime + curseData.start
end

function curses:TrackDarkHarvest(curseData)
	if curses.darkHarvestData["targetGuid"] and curses.darkHarvestData["targetGuid"] == curseData["targetGuid"] then
		local dhActive = false
		-- check if still channeling
		if curses.isChanneling then
			local dhTimeRemaining = curses.darkHarvestData.castDuration - (GetTime() - curses.darkHarvestData.start)
			-- check if dh still active based on cast duration
			if dhTimeRemaining > 0 then
				dhActive = true
				-- dh is active
				if not curseData["dhStartTime"] then
					curseData["dhStartTime"] = curses:GetLastTickTime(curseData) -- dh will reduce full tick duration
				end
			end
		end
		if curseData["dhStartTime"] and dhActive == false and not curseData["dhEndTime"] then
			-- if dh no longer active, store end time if not already stored
			curseData["dhEndTime"] = GetTime()
		end
	end
end

function curses:GetDarkHarvestReduction(curseData)
	if curseData["dhStartTime"] then
		local endTime = curseData["dhEndTime"] or GetTime()
		local dhActiveTime = endTime - curseData["dhStartTime"]
		if dhActiveTime > 0 then
			return dhActiveTime * .3 -- 30% reduction
		end
	end
	return 0
end

function curses:TimeRemaining(curseData)
	local dhReduction = 0

	if curses.trackedCurseIds[curseData.spellID] and curses.trackedCurseIds[curseData.spellID].darkHarvest then
		curses:TrackDarkHarvest(curseData)

		dhReduction = curses:GetDarkHarvestReduction(curseData)
	end

	local remaining = curseData.duration - (GetTime() - curseData.start) - dhReduction
	if Cursive.db.profile.curseshowdecimals and remaining < 10 then
		-- round to 1 decimal point
		remaining = math.floor(remaining * 10) / 10
	else
		remaining = math.ceil(remaining)
	end

	return remaining
end

function curses:EnableResistSound(guid)
	curses.resistSoundGuids[guid] = true
end

function curses:EnableExpiringSound(lowercaseSpellNameNoRank, guid)
	if curses.requestedExpiringSoundGuids[guid] and curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] then
		curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] = nil
	end

	if not curses.expiringSoundGuids[guid] then
		curses.expiringSoundGuids[guid] = {}
	end
	curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] = true
end

function curses:RequestExpiringSound(lowercaseSpellNameNoRank, guid)
	if not curses.requestedExpiringSoundGuids[guid] then
		curses.requestedExpiringSoundGuids[guid] = {}
	end
	curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] = true
end

function curses:HasRequestedExpiringSound(lowercaseSpellNameNoRank, guid)
	return curses.requestedExpiringSoundGuids[guid] and curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank]
end

function curses:ShouldPlayExpiringSound(lowercaseSpellNameNoRank, guid)
	if curses.expiringSoundGuids[guid] and curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] then
		curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] = nil -- remove entry to avoid playing sound multiple times
		return true
	end

	return false
end

function curses:ShouldPlayResistSound(guid)
	if curses.resistSoundGuids[guid] then
		curses.resistSoundGuids[guid] = nil -- remove entry to avoid playing sound multiple times
		return true
	end

	return false
end

function curses:HasAnyCurse(guid)
	if curses.guids[guid] and next(curses.guids[guid]) then
		return true
	end
	return nil
end

function curses:GetCurseData(spellName, guid)
	-- convert to lowercase and remove rank
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	if curses.guids[guid] and curses.guids[guid][lowercaseSpellNameNoRank] then
		return curses.guids[guid][lowercaseSpellNameNoRank]
	end

	return nil
end

function curses:HasCurse(lowercaseSpellNameNoRank, targetGuid, minRemaining, malediction)
	if not minRemaining then
		minRemaining = 0 -- default to 0
	end

	if malediction == nil then
		malediction = 1 -- default to enabled
	end

	-- handle faerie fire special case
	if curses.isDruid and string.find(lowercaseSpellNameNoRank, L["faerie fire"]) then
		-- remove (feral) or (bear) from spell name
		lowercaseSpellNameNoRank = L["faerie fire"]
	end

	-- handle malediction for warlocks
	if curses.isWarlock and malediction ~= 0 and (
			lowercaseSpellNameNoRank == L["curse of recklessness"] or
			lowercaseSpellNameNoRank == L["curse of the elements"] or
			lowercaseSpellNameNoRank == L["curse of shadow"]) then
		local _, _, _, _, hasMalediction = GetTalentInfo(1, 17)
		if hasMalediction > 0 then
			lowercaseSpellNameNoRank = L["curse of agony"]
		end
	end

	if curses.guids[targetGuid] and curses.guids[targetGuid][lowercaseSpellNameNoRank] then
		local remaining = Cursive.curses:TimeRemaining(curses.guids[targetGuid][lowercaseSpellNameNoRank])

		if remaining >= minRemaining then
			return true
		end
	end

	-- check pending cast
	if curses.pendingCast and
			curses.pendingCast.targetGuid == targetGuid and
			curses.pendingCast.spellID and
			curses.trackedCurseIds[curses.pendingCast.spellID] and
			curses.trackedCurseIds[curses.pendingCast.spellID].name == lowercaseSpellNameNoRank then
		return true
	end

	return nil
end

-- Apply shared curse from another player
function curses:ApplySharedCurse(sharedDebuffKey, spellID, targetGuid, startTime)
	local name = curses.sharedDebuffs[sharedDebuffKey][spellID].name
	local rank = curses.sharedDebuffs[sharedDebuffKey][spellID].rank
	local duration = curses.sharedDebuffs[sharedDebuffKey][spellID].duration

	if not curses.guids[targetGuid] then
		curses.guids[targetGuid] = {}
	end

	curses.guids[targetGuid][name] = {
		rank = rank,
		duration = duration,
		start = startTime,
		spellID = spellID,
		appliedSpellID = GetAppliedCurseSpellID(spellID),
		targetGuid = targetGuid,
		currentPlayer = false,
	}
end

-- Apply curse from player
function curses:ApplyCurse(spellID, targetGuid, startTime, duration)
	-- clear pending cast
	curses.pendingCast = {}

	-- 新增：跳过处于 miss 守卫窗口内的 debuff，避免延迟事件再次误加 by 武藤纯子酱 2026.9.10
	if IsMissGuarded(targetGuid, spellID) then
		return
	end

  local curseData = curses.trackedCurseIds[spellID]
  local name = string.lower(curseData.name) -- 修改默认小写 by 武藤纯子酱 2026.7.1
  local rank = curseData.rank

	if not curses.guids[targetGuid] then
		curses.guids[targetGuid] = {}
	end

	curses.guids[targetGuid][name] = {
		rank = rank,
		duration = duration,
		start = startTime,
		spellID = spellID,
		targetGuid = targetGuid,
		currentPlayer = true,
	}
end

function curses:UpdateCurse(spellID, targetGuid, startTime)
	-- clear pending cast
	curses.pendingCast = {}

	if curses.conflagrateSpellIds[spellID] then
		-- check if target has immolate
		if curses:HasCurse(L["immolate"], targetGuid) then
			-- reduce duration by 3 sec
			curses.guids[targetGuid][L["immolate"]].duration = curses.guids[targetGuid][L["immolate"]].duration - 3
		end
	end
end

function curses:RemoveCurse(guid, curseName)
	if curses.guids[guid] and curses.guids[guid][curseName] then
		curses.guids[guid][curseName] = nil
	end
	if curses.expiringSoundGuids[guid] and curses.expiringSoundGuids[guid][curseName] then
		curses.expiringSoundGuids[guid][curseName] = nil
	end
end

function curses:RemoveGuid(guid)
	curses.guids[guid] = nil
	curses.resistSoundGuids[guid] = nil
	curses.expiringSoundGuids[guid] = nil
	curses.requestedExpiringSoundGuids[guid] = nil
	curses.missGuards[guid] = nil -- 新增：清理 miss 守卫 by 武藤纯子酱 2026.9.10
end

-- 新增 by 武藤纯子酱 2025.8.29
function curses:GetHighestRankSpellId(spellName)
	local highestRank = 0
	local highestRankId = nil
	local spellTables = {}

	curses.isWarlock = playerClassName == "WARLOCK"
	curses.isPriest = playerClassName == "PRIEST"
	curses.isMage = playerClassName == "MAGE"
	curses.isDruid = playerClassName == "DRUID"
	curses.isHunter = playerClassName == "HUNTER"
	curses.isRogue = playerClassName == "ROGUE"
	curses.isShaman = playerClassName == "SHAMAN"
	curses.isWarrior = playerClassName == "WARRIOR"
	curses.isPaladin = playerClassName == "PALADIN" -- 新增 by 武藤纯子酱 2025.8.29

	-- curses to track
	if curses.isWarlock then
		spellTables = getWarlockSpells()
	elseif curses.isPriest then
		spellTables = getPriestSpells()
	elseif curses.isMage then
		spellTables = getMageSpells()
	elseif curses.isDruid then
		spellTables = getDruidSpells()
	elseif curses.isHunter then
		spellTables = getHunterSpells()
	elseif curses.isRogue then
		spellTables = getRogueSpells()
	elseif curses.isShaman then
		spellTables = getShamanSpells()
	elseif curses.isWarrior then
		spellTables = getWarriorSpells()
	elseif curses.isPaladin then
		spellTables = getPaladinSpells()
	end	
	-- 遍历所有法术表来查找	
	for spellId, spellData in pairs(spellTables) do
		if spellData.name == spellName then
			if spellData.rank > highestRank then
				highestRank = spellData.rank
				highestRankId = spellId
			end
		end
	end
	
	return highestRankId
end

Cursive.curses = curses

