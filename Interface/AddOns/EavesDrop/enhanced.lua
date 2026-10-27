-- Nampower 4.5+ event adapter for the 1.12 client. No global CVar changes.
-- Contract checked against nampower 4.6.1 EVENTS.md and spellevents.cpp.
-- Legacy drain/leech and kill attribution remain in ParserLib: the enhanced
-- stream does not provide a complete equivalent for those categories.
-- Aura, environmental and shield hooks signal AFTER the original client code;
-- retain their text source to avoid duplicating the first unobserved event.

local frame
local categories = {}
local observed = {}
local disabled = {}
local cvarValues = {}
local legacySpells = {}
local percentageFallback = false
local status = "文字战斗日志"
local originalSetCVar, cvarObserver
local cvarAttached, monitorCVars = false, false
local zeroGuid = "0x0000000000000000"
local questionMark = "Interface\\Icons\\INV_Misc_QuestionMark"
local categoryCVars = {
  melee = "NP_EnableAutoAttackEvents",
  heal = "NP_EnableSpellHealEvents",
  gain = "NP_EnableSpellEnergizeEvents",
}
local cvarCategories = {
  np_enableautoattackevents = "melee",
  np_enablespellhealevents = "heal",
  np_enablespellenergizeevents = "gain",
}

-- Lua 5.0's arg.n retains trailing nil returns. Recursive tail expansion also
-- works on clients whose unpack() does not accept a start/end range.
local function returnValues(values, index, count)
  if index > count then return end
  return values[index], returnValues(values, index + 1, count)
end

local function startCVarObserver()
  monitorCVars = true
  if cvarAttached or type(SetCVar) ~= "function" then return end
  originalSetCVar = SetCVar
  if not cvarObserver then
    cvarObserver = function(name, value, scriptCVar)
      local category = monitorCVars and type(name) == "string" and cvarCategories[string.lower(name)]
      if not category then return originalSetCVar(name, value, scriptCVar) end
      local function afterCall(...)
        -- Observe successful calls, including SetCVar(name, "0") when the
        -- saved value was already 0. Registration may have enabled the internal
        -- emitter without changing that saved value. Do not write any CVar.
        observed[category] = nil
        disabled[category] = tonumber(value) == 0 or nil
        cvarValues[category] = GetCVar and GetCVar(categoryCVars[category]) or tostring(value)
        return returnValues(arg, 1, arg.n or table.getn(arg))
      end
      return afterCall(originalSetCVar(name, value, scriptCVar))
    end
  end
  SetCVar = cvarObserver
  cvarAttached = true
end

local function stopCVarObserver()
  monitorCVars = false
  -- Another addon's hook may call this wrapper. Never cut that chain or install
  -- a second wrapper on restart; retain the existing one as an inert link.
  if cvarAttached and SetCVar == cvarObserver then
    SetCVar = originalSetCVar
    cvarAttached = false
  end
end

local function ready(category)
  if not categories[category] then return false end
  local cvar = categoryCVars[category]
  if cvar and GetCVar then
    local value = GetCVar(cvar)
    if cvarValues[category] ~= nil and value ~= cvarValues[category] then
      observed[category] = nil
      disabled[category] = tonumber(value) == 0 or nil
    end
    cvarValues[category] = value
  end
  return not disabled[category]
end

local function suppress(category)
  return ready(category) and observed[category] == true
end

local function validGuid(guid)
  return type(guid) == "string" and string.sub(guid, 1, 2) == "0x" and guid ~= zeroGuid
end

local function unitGuid(unit)
  local guid
  if GetUnitGUID then guid = GetUnitGUID(unit) end
  if not validGuid(guid) and UnitGUID then guid = UnitGUID(unit) end
  if not validGuid(guid) and UnitExists then local exists; exists, guid = UnitExists(unit) end
  if validGuid(guid) then return guid end
end

local function atLeast(major, minor, patch, a, b, c)
  return major > a or (major == a and (minor > b or (minor == b and patch >= c)))
end

local function flag(value, mask)
  return math.floor((tonumber(value) or 0) / mask) % 2 == 1
end

local function positive(value)
  value = tonumber(value)
  if value and value > 0 then return value end
end

local function school(index)
  if type(index) == "number" and index >= 0 and index <= 6 then
    return getglobal("SPELL_SCHOOL" .. index .. "_CAP")
  end
end

local function spellInfo(id)
  id = tonumber(id)
  if not id or id <= 0 then return nil, nil end
  local name, texture
  -- Valid native arguments only. Do not wrap added native script functions in
  -- pcall: the checked source documents its Lua state pointer limitation.
  if GetSpellRecField then
    name = GetSpellRecField(id, "name")
    if GetSpellIconTexture then
      local icon = GetSpellRecField(id, "spellIconID")
      if icon and icon > 0 then texture = GetSpellIconTexture(icon) end
    end
  end
  if SpellInfo and (not name or not texture) then
    local n, r, t = SpellInfo(id)
    name = name or n
    texture = texture or t
  end
  return name or ("#" .. id), texture or questionMark
end

local function displayName(guid, playerGuid, petGuid)
  if guid == playerGuid then return ParserLib_SELF end
  if petGuid and guid == petGuid then return UnitName("pet") or guid end
  if validGuid(guid) then return UnitName(guid) or guid end
  return UNKNOWNOBJECT or UNKNOWN or "?"
end

local function relevant(source, victim)
  local playerGuid, petGuid = unitGuid("player"), unitGuid("pet")
  if not playerGuid then return end
  local pets = EavesDrop.db and EavesDrop.db.profile.PET == true
  local sourceTemporary, victimTemporary = false, false
  if EavesDrop.IsOwnedTemporarySummon then
    if validGuid(source) then sourceTemporary = EavesDrop:IsOwnedTemporarySummon(source) end
    if validGuid(victim) then victimTemporary = EavesDrop:IsOwnedTemporarySummon(victim) end
  end
  if source == playerGuid or victim == playerGuid or
      (pets and petGuid and (source == petGuid or victim == petGuid)) or sourceTemporary or victimTemporary then
    return playerGuid, petGuid, true, sourceTemporary, victimTemporary
  end
  return playerGuid, petGuid, false
end

local function emit(category, info, sourceGuid, victimGuid, spellId, isSpell)
  if not ready(category) then return end
  local playerGuid, petGuid, isRelevant, sourceTemporary, victimTemporary = relevant(sourceGuid, victimGuid)
  if not isRelevant then
    if not playerGuid or (not validGuid(sourceGuid) and not validGuid(victimGuid)) then
      observed[category] = nil
    end
    return
  end
  info.enhanced = true
  info.sourceGUID, info.victimGUID = sourceGuid, victimGuid
  info.sourceIsPlayer, info.victimIsPlayer = sourceGuid == playerGuid, victimGuid == playerGuid
  info.sourceIsPet = petGuid ~= nil and sourceGuid == petGuid
  info.victimIsPet = petGuid ~= nil and victimGuid == petGuid
  info.sourceIsTemporary, info.victimIsTemporary = sourceTemporary, victimTemporary
  info.source = displayName(sourceGuid, playerGuid, petGuid)
  info.victim = displayName(victimGuid, playerGuid, petGuid)
  info.spellId = positive(spellId)
  if info.spellId then info.skill, info.texture = spellInfo(info.spellId)
  elseif isSpell then info.skill = UNKNOWN or "未知法术" end
  local source = info.sourceIsPlayer and (UnitName("player") or "player") or info.source
  local victim = info.victimIsPlayer and (UnitName("player") or "player") or info.victim
  local skill = info.skill
  if skill == ParserLib_MELEE then skill = MELEE_ATTACK or "Melee" end
  info.message = tostring(source) .. " → " .. tostring(victim) .. "：" .. tostring(skill or info.damageType or "")
  if info.amount ~= nil then info.message = info.message .. " " .. tostring(info.amount) end
  if info.attribute then info.message = info.message .. " " .. tostring(info.attribute) end
  if info.missType then info.message = info.message .. " " .. tostring(getglobal(string.upper(info.missType)) or info.missType) end
  if info.amountAbsorb then info.message = info.message .. " (吸收 " .. info.amountAbsorb .. ")" end
  if info.amountBlock then info.message = info.message .. " (格挡 " .. info.amountBlock .. ")" end
  if info.amountResist then info.message = info.message .. " (抵抗 " .. info.amountResist .. ")" end
  if info.isCrit then info.message = info.message .. " *" end
  -- Registration is not evidence that a DLL actually emits this category.
  -- The checked native hook signals before the original legacy-text handler,
  -- so activating immediately before the sink also deduplicates the first hit.
  observed[category] = true
  EavesDrop:RouteCombatEvent(info)
end

local spellMisses = {
  [1] = "miss", [2] = "resist", [3] = "dodge", [4] = "parry", [5] = "block",
  [6] = "evade", [7] = "immune", [8] = "immune", [9] = "deflect", [10] = "absorb", [11] = "reflect",
}
local swingMisses = { [2] = "dodge", [3] = "parry", [6] = "evade", [7] = "immune", [8] = "deflect" }

function EavesDrop:HandleEnhancedEvent(name, a1, a2, a3, a4, a5, a6, a7, a8, a9)
  if not self:IsActive() or self.db.profile.DATASOURCE == "legacy" then return end
  if name == "SPELL_DAMAGE_EVENT_SELF" or name == "SPELL_DAMAGE_EVENT_OTHER" then
    if not ready("spell") then return end
    if type(a4) ~= "number" then observed.spell = nil; return end
    if legacySpells[tonumber(a3)] then return end
    local _, _, aura = string.find(type(a8) == "string" and a8 or "", ",([^,]+)$")
    if tonumber(aura) == 89 then
      -- The checked event documentation leaves the unit of this raw amount
      -- uncertain. Never turn a possible percentage into hit points. Nampower
      -- signals before the original text handler, so this very text record can
      -- be retained by spell name, with all future damage of this spell using
      -- the same source. No timer or amount matching can erase legitimate ticks.
      local skill = spellInfo(a3)
      if tonumber(a3) then legacySpells[tonumber(a3)] = true end
      if skill and skill ~= ("#" .. a3) then legacySpells[skill] = true
      else categories.spell = nil; observed.spell = nil end
      if not percentageFallback then
        percentageFallback = true
        status = status .. "；百分比 DoT 使用文字记录"
      end
      return
    end
    local absorb, block, resist
    if type(a5) == "string" then
      local _, _, x, y, z = string.find(a5, "^([^,]+),([^,]+),([^,]+)$")
      absorb, block, resist = positive(x), positive(y), positive(z)
    end
    emit("spell", { type = "hit", amount = a4, element = school(a7), isCrit = flag(a6, 2),
      amountAbsorb = absorb, amountBlock = block, amountResist = resist,
      effectAura = a8 }, a2, a1, a3, true)
  elseif name == "AUTO_ATTACK_SELF" or name == "AUTO_ATTACK_OTHER" then
    if not ready("melee") then return end
    if type(a3) ~= "number" then observed.melee = nil; return end
    local miss = swingMisses[a5]
    if not miss and flag(a4, 16) then miss = "miss" end
    if not miss and a3 == 0 then
      if positive(a8) then miss = "absorb" elseif positive(a9) then miss = "resist" end
    end
    emit("melee", { type = miss and "miss" or "hit", skill = ParserLib_MELEE, missType = miss,
      amount = a3, element = school(0), isCrit = flag(a4, 128), isGlancing = flag(a4, 16384),
      isCrushing = flag(a4, 32768), amountBlock = positive(a7), amountAbsorb = positive(a8),
      amountResist = positive(a9) }, a1, a2)
  elseif name == "SPELL_MISS_SELF" or name == "SPELL_MISS_OTHER" then
    if not ready("miss") then return end
    if not spellMisses[a4] then observed.miss = nil; return end
    emit("miss", { type = "miss", missType = spellMisses[a4] }, a1, a2, a3, true)
  elseif name == "SPELL_HEAL_BY_SELF" or name == "SPELL_HEAL_BY_OTHER" then
    if not ready("heal") then return end
    if type(a4) ~= "number" then observed.heal = nil; return end
    emit("heal", { type = "heal", amount = a4, isCrit = a5 == 1, isHoT = a6 == 1 }, a2, a1, a3, true)
  elseif name == "SPELL_ENERGIZE_BY_SELF" or name == "SPELL_ENERGIZE_BY_OTHER" then
    if not ready("gain") then return end
    if type(a5) ~= "number" or type(a4) ~= "number" then observed.gain = nil; return end
    local powerNames = { [0] = MANA, [1] = RAGE, [2] = FOCUS, [3] = ENERGY, [4] = HAPPINESS, [-2] = HEALTH }
    local powerType = a4 == 4294967294 and -2 or a4
    -- The health energize packet is a gain, not a second heal packet.
    emit("gain", { type = "gain", amount = a5, powerType = powerType,
      attribute = powerNames[powerType] or tostring(powerType), isPeriodic = a6 == 1 }, a2, a1, a3, true)
  end
end

function EavesDrop:StopEnhancedEvents()
  if frame then frame:UnregisterAllEvents() end
  stopCVarObserver()
  categories = {}
  observed = {}
  disabled = {}
  cvarValues = {}
  legacySpells = {}
  percentageFallback = false
  self.enhancedCategories = categories
  self.enhancedObserved = observed
  self.enhancedNeedsRetry = false
  status = "文字战斗日志"
end

function EavesDrop:StartEnhancedEvents()
  self:StopEnhancedEvents()
  if self.db.profile.DATASOURCE == "legacy" then return end
  if not GetNampowerVersion then status = "文字战斗日志（未检测到 nampower）"; return end
  local major, minor, patch = GetNampowerVersion()
  major, minor, patch = tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
  if not atLeast(major, minor, patch, 4, 5, 0) then
    status = "文字战斗日志（增强适配需要 nampower 4.5+）"
    return
  end
  if not unitGuid("player") then
    self.enhancedNeedsRetry = true
    status = "文字战斗日志（玩家 GUID 尚不可用，进入世界后重试）"
    return
  end
  if not frame then
    frame = CreateFrame("Frame", "EavesDropEnhancedEvents", UIParent)
    frame:SetScript("OnEvent", function()
      EavesDrop:HandleEnhancedEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end)
    self.enhancedFrame = frame
  end
  local groups = {
    spell = { "SPELL_DAMAGE_EVENT_SELF", "SPELL_DAMAGE_EVENT_OTHER" },
    melee = { "AUTO_ATTACK_SELF", "AUTO_ATTACK_OTHER" },
    miss = { "SPELL_MISS_SELF", "SPELL_MISS_OTHER" },
    heal = { "SPELL_HEAL_BY_SELF", "SPELL_HEAL_BY_OTHER" },
    gain = { "SPELL_ENERGIZE_BY_SELF", "SPELL_ENERGIZE_BY_OTHER" },
  }
  -- Only these five packet hooks emit before the original text handler.
  -- Shield, environmental and aura events retain their legacy text source.
  local active = 0
  for key, names in pairs(groups) do
    local ok = true
    for _, name in ipairs(names) do
      local success = pcall(frame.RegisterEvent, frame, name)
      if not success or (frame.IsEventRegistered and not frame:IsEventRegistered(name)) then ok = false end
    end
    if ok then
      categories[key] = true; active = active + 1
      if categoryCVars[key] and GetCVar then cvarValues[key] = GetCVar(categoryCVars[key]) end
    else for _, name in ipairs(names) do frame:UnregisterEvent(name) end end
  end
  self.enhancedCategories = categories
  if active > 0 then
    startCVarObserver()
    status = "nampower " .. major .. "." .. minor .. "." .. patch
  else
    status = "文字战斗日志（增强事件不可用）"
  end
end

function EavesDrop:ShouldSuppressLegacy(info)
  if not info or info.enhanced then return false end
  if info.type == "hit" then
    if info.skill == ParserLib_MELEE then return suppress("melee") end
    if info.skill == ParserLib_DAMAGESHIELD then return false end
    if legacySpells[info.skill] then return false end
    return suppress("spell")
  elseif info.type == "miss" then
    if info.skill == ParserLib_MELEE then return suppress("melee") end
    return suppress("miss")
  elseif info.type == "heal" then return suppress("heal")
  elseif info.type == "gain" then return suppress("gain")
  end
  return false
end

function EavesDrop:GetCombatSourceStatus()
  local registered, received = 0, 0
  for key in pairs(categories) do
    registered = registered + 1
    if suppress(key) then received = received + 1 end
  end
  if registered == 0 then return status end
  return status .. "：已订阅 " .. registered .. " 类，已收到 " .. received .. " 类；其余使用文字日志"
end
