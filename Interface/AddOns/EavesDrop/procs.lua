-- Equipment-effect and owned temporary-summon observations for WoW 1.12.
-- COMBAT_TEXT_UPDATE uses arg1/arg2 directly in the original client.
-- SPELL_CAST is a cast notification; SPELL_ACTIVE only reports availability.
-- None of these events alone proves that a summoned unit was created.
local frame
local monitoring = false
local source = "floating"
local sourceReady = false
local unavailable
local rules = {
  lost = {
    label = "失落之物", unitLabel = "迷失者",
    -- Verified local Babble name. Do not guess a spell ID or English name.
    spellNames = { ["召唤迷失者"] = true }, spellIds = {},
    unitNames = { ["迷失者"] = true, ["The Lost"] = true },
    creatureIds = { [59993] = true },
  },
}
local zeroGuid = "0x0000000000000000"
local records, seen, seenOrder = {}, {}, {}
local stats = { triggers = 0, available = 0, summons = 0, damage = 0, taken = 0, healing = 0 }
local RECORD_LIMIT, GUID_LIMIT = 128, 256

local function enabled(key)
  return EavesDrop._running and EavesDrop.db and EavesDrop.db.profile[key] ~= false
end

local function validGuid(guid)
  return type(guid) == "string" and string.len(guid) == 18 and
    string.find(guid, "^0x%x+$") ~= nil and string.lower(guid) ~= zeroGuid
end

local function sameGuid(a, b)
  return validGuid(a) and validGuid(b) and string.lower(a) == string.lower(b)
end

local function fieldsSupported()
  if not GetUnitField or not GetNampowerVersion then return false end
  local major, minor = GetNampowerVersion()
  major, minor = tonumber(major) or 0, tonumber(minor) or 0
  -- The field signatures were checked in the retained 4.6.1 source. This
  -- module already targets the 4.5+ registration/API family; no old-field guess.
  return major > 4 or (major == 4 and minor >= 5)
end

local function unitGuid(unit)
  local guid
  if GetUnitGUID then guid = GetUnitGUID(unit) end
  if not validGuid(guid) and UnitGUID then guid = UnitGUID(unit) end
  if not validGuid(guid) and UnitExists then local exists; exists, guid = UnitExists(unit) end
  if validGuid(guid) then return guid end
end

local function now()
  return GetTime and GetTime() or 0
end

local function spellName(id)
  id = tonumber(id)
  if not id or id <= 0 then return end
  if GetSpellRecField then
    local name = GetSpellRecField(id, "name")
    if type(name) == "string" and name ~= "" then return name end
  end
  if GetSpellNameAndRankForId then
    local name = GetSpellNameAndRankForId(id)
    if type(name) == "string" and name ~= "" then return name end
  end
  if SpellInfo then
    local name = SpellInfo(id)
    if type(name) == "string" and name ~= "" then return name end
  end
end

local function spellRule(name, id)
  for key, rule in pairs(rules) do
    if (type(name) == "string" and rule.spellNames[name]) or
        (tonumber(id) and rule.spellIds[tonumber(id)]) then return rule, key end
  end
end

local function unitRule(guid)
  local name = UnitName and UnitName(guid)
  local entry
  -- vmangos ObjectGuid: HIGHGUID_UNIT 0xF130, entry << 24, 24-bit counter.
  -- Never interpret player/item GUIDs as a creature entry.
  if string.upper(string.sub(guid, 3, 6)) == "F130" then
    entry = tonumber(string.sub(guid, 7, 12), 16)
  end
  for key, rule in pairs(rules) do
    local identified = entry and rule.creatureIds[entry]
    if not entry or not next(rule.creatureIds) then identified = name and rule.unitNames[name] end
    if identified then
      return rule, key
    end
  end
end

local function publish(record)
  record.time = now()
  record.timestamp = date and date("%H:%M:%S") or tostring(record.time)
  record.detail = record.detail or record.message or record.text
  if table.getn(records) >= RECORD_LIMIT then table.remove(records, 1) end
  table.insert(records, record)
  EavesDrop.procRecords = records
  EavesDrop.procStats = stats
  if EavesDrop.OnProcRecord then EavesDrop:OnProcRecord(record) end
  if record.merge ~= false and EavesDrop.db.profile.PROCMERGE ~= false and EavesDrop.DisplayEvent then
    local previous = EavesDrop.eventMessage
    EavesDrop.eventMessage = record.message or record.text
    local color = EavesDrop.db.profile[record.kind == "summon" and "SUMMONCOLOR" or "PROCCOLOR"]
      or EavesDrop.db.profile.MISC or { r = .4, g = .85, b = .7 }
    EavesDrop:DisplayEvent(record.direction or 3, record.text, record.texture, color)
    EavesDrop.eventMessage = previous
  end
end

function EavesDrop:RegisterProcRule(key, rule)
  -- Extension point for future verified rules; never auto-learn from fuzzy text.
  if type(key) ~= "string" or key == "" or type(rule) ~= "table" or
      type(rule.label) ~= "string" or type(rule.unitLabel) ~= "string" then return false end
  for _, field in ipairs({ "spellNames", "spellIds", "unitNames", "creatureIds" }) do
    if rule[field] ~= nil and type(rule[field]) ~= "table" then return false end
  end
  rule.spellNames, rule.spellIds = rule.spellNames or {}, rule.spellIds or {}
  rule.unitNames, rule.creatureIds = rule.unitNames or {}, rule.creatureIds or {}
  rules[key] = rule
  return true
end

function EavesDrop:IsOwnedTemporarySummon(guid)
  if not enabled("SUMMONWATCH") or not validGuid(guid) then return false end
  local player = unitGuid("player")
  if not player or sameGuid(guid, player) or sameGuid(guid, unitGuid("pet")) then return false end
  if UnitIsPlayer and UnitIsPlayer(guid) then return false end
  local rule, key = unitRule(guid)
  if not rule then return false end
  local owner
  if GetUnitGUID then owner = GetUnitGUID(guid .. "owner") end
  if validGuid(owner) then
    if sameGuid(owner, player) then return true, rule.unitLabel, key end
    return false
  end
  -- These exact object-reference fields are documented by Nampower.
  -- No ownership cache: a name/GUID alone must never confer ownership.
  if fieldsSupported() then
    local summonedBy = GetUnitField(guid, "summonedBy")
    if validGuid(summonedBy) then
      if sameGuid(summonedBy, player) then return true, rule.unitLabel, key end
      return false
    end
    if sameGuid(GetUnitField(guid, "createdBy"), player) then return true, rule.unitLabel, key end
  end
  return false
end

local function discover(guid, label, key)
  local canonical = string.lower(guid)
  if seen[canonical] then return end
  if table.getn(seenOrder) >= GUID_LIMIT then seen[table.remove(seenOrder, 1)] = nil end
  seen[canonical] = true
  table.insert(seenOrder, canonical)
  stats.summons = stats.summons + 1
  publish({ kind = "summon", evidence = "first_observed", guid = guid, rule = key,
    text = "首次发现：" .. label,
    message = "首次在战斗事件中确认属于你的" .. label .. "；不代表准确生成时间。" })
end

function EavesDrop:ObserveSummonCombat(info, passthrough)
  if not enabled("SUMMONWATCH") or type(info) ~= "table" then return false end
  if info.type ~= "hit" and info.type ~= "heal" and info.type ~= "miss" then return false end
  if info.type ~= "miss" and (type(info.amount) ~= "number" or info.amount < 0 or
      info.amount ~= info.amount or info.amount == math.huge) then return false end
  local ownsSource, sourceLabel, sourceKey = self:IsOwnedTemporarySummon(info.sourceGUID)
  local ownsVictim, victimLabel, victimKey = self:IsOwnedTemporarySummon(info.victimGUID)
  if not ownsSource and not ownsVictim then return false end
  if ownsSource then discover(info.sourceGUID, sourceLabel, sourceKey) end
  if ownsVictim then discover(info.victimGUID, victimLabel, victimKey) end
  local incoming = ownsVictim and not ownsSource
  local label = incoming and victimLabel or sourceLabel
  local text
  if info.type == "miss" then
    text = getglobal and getglobal(string.upper(info.missType or "MISS"))
    text = text or info.missType or MISS or "未命中"
  elseif info.type == "heal" then
    stats.healing = stats.healing + info.amount
    text = "+" .. info.amount
  else
    if incoming then stats.taken = stats.taken + info.amount
    else stats.damage = stats.damage + info.amount end
    text = (incoming and "-" or "") .. info.amount
  end
  if info.isCrit then text = "*" .. text .. "*" end
  publish({ kind = "summon", evidence = "combat", rule = incoming and victimKey or sourceKey,
    guid = incoming and info.victimGUID or info.sourceGUID, amount = info.amount,
    combatType = info.type, direction = incoming and -1 or 1,
    merge = not passthrough,
    text = "[" .. label .. "] " .. text, texture = info.texture,
    message = info.message or ("已确认归属的" .. label .. "：" .. text) })
  return not passthrough
end

local function trigger(rule, key, name, id, evidence)
  stats.triggers = stats.triggers + 1
  publish({ kind = "proc", evidence = evidence, rule = key, spellId = tonumber(id),
    text = "[" .. rule.label .. "] 召唤触发",
    message = "来源：" .. evidence .. "；" .. (name or "已核实技能") ..
      "。记录施法/触发提示，不据此认定单位已生成。" })
end

function EavesDrop:HandleProcEvent(eventName, a1, a2, a3, a4)
  if not monitoring or not enabled("PROCWATCH") then return end
  if eventName == "COMBAT_TEXT_UPDATE" then
    local rule, key = spellRule(a2)
    if not rule then return end
    if a1 == "SPELL_CAST" and source == "floating" and sourceReady then
      trigger(rule, key, a2, nil, "浮动战斗信息 SPELL_CAST")
    elseif a1 == "SPELL_ACTIVE" then
      -- Original CombatText calls this a reactive/available-skill message.
      stats.available = stats.available + 1
      publish({ kind = "proc", evidence = "available", rule = key,
        text = "[" .. rule.label .. "] 技能可用提示",
        message = (a2 or "") .. "：SPELL_ACTIVE 只表示技能变为可用，不计入召唤触发次数。" })
    end
  elseif eventName == "SPELL_GO_SELF" and source == "native" and sourceReady then
    if not sameGuid(a3, unitGuid("player")) then return end
    local name = spellName(a2)
    local rule, key = spellRule(name, a2)
    -- itemId=0 is normal for some triggered spells; not an attribution proof.
    if rule then trigger(rule, key, name, a2, "nampower SPELL_GO_SELF") end
  elseif eventName == "UNIT_CASTEVENT" and source == "superwow" and sourceReady then
    if a3 ~= "CAST" or not sameGuid(a1, unitGuid("player")) then return end
    local name = spellName(a4)
    local rule, key = spellRule(name, a4)
    if rule then trigger(rule, key, name, a4, "SuperWoW UNIT_CASTEVENT") end
  end
end

function EavesDrop:StopProcMonitoring()
  if frame then frame:UnregisterAllEvents() end
  monitoring = false
  sourceReady = false
  -- Keep this login's bounded records and counts through settings/enable changes.
end

function EavesDrop:StartProcMonitoring()
  self:StopProcMonitoring()
  unavailable = nil
  source = self.db and self.db.profile.PROCSOURCE or "floating"
  if source ~= "floating" and source ~= "native" and source ~= "superwow" then source = "floating" end
  if not enabled("PROCWATCH") then return end
  if not frame then
    frame = CreateFrame("Frame", "EavesDropProcEvents", UIParent)
    frame:SetScript("OnEvent", function()
      EavesDrop:HandleProcEvent(event, arg1, arg2, arg3, arg4)
    end)
    self.procFrame = frame
  end
  frame:RegisterEvent("COMBAT_TEXT_UPDATE")
  monitoring = true
  if source == "floating" then sourceReady = true
  elseif source == "native" then
    local major, minor
    if GetNampowerVersion then major, minor = GetNampowerVersion() end
    major, minor = tonumber(major) or 0, tonumber(minor) or 0
    if major > 4 or (major == 4 and minor >= 5) then
      sourceReady = pcall(frame.RegisterEvent, frame, "SPELL_GO_SELF")
      if sourceReady and frame.IsEventRegistered then sourceReady = frame:IsEventRegistered("SPELL_GO_SELF") end
    end
    if not sourceReady then unavailable = "nampower 施法事件不可用，未切换到其他触发来源" end
  else
    if GetSpellNameAndRankForId then sourceReady = pcall(frame.RegisterEvent, frame, "UNIT_CASTEVENT") end
    if sourceReady and frame.IsEventRegistered then sourceReady = frame:IsEventRegistered("UNIT_CASTEVENT") end
    if not sourceReady then unavailable = "SuperWoW 施法事件不可用，未切换到其他触发来源" end
  end
end

function EavesDrop:RefreshProcMonitoring()
  self:StartProcMonitoring()
end

function EavesDrop:GetProcRecords()
  return records
end

function EavesDrop:GetSummonStatus()
  if not enabled("SUMMONWATCH") then return "临时召唤监视已关闭" end
  if self.db.profile.DATASOURCE == "legacy" then return "临时召唤伤害不可用：旧文字模式无可靠归属" end
  if not self.enhancedCategories or not next(self.enhancedCategories) then
    return "临时召唤伤害等待增强日志与归属确认"
  end
  return "临时召唤按GUID归属筛选，生成时间未确认"
end

function EavesDrop:GetProcStatus()
  local names = { floating = "默认浮动战斗信息", native = "nampower 施法", superwow = "SuperWoW 施法" }
  local state = not enabled("PROCWATCH") and "装备触发监视已关闭" or
    (unavailable or ("触发来源：" .. (names[source] or names.floating)))
  return state .. "；触发 " .. stats.triggers .. " 次，首见 " .. stats.summons ..
    " 个，伤害 " .. stats.damage .. "；" .. self:GetSummonStatus()
end

EavesDrop.procRules, EavesDrop.procRecords, EavesDrop.procStats = rules, records, stats
