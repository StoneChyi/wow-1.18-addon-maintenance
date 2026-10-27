-- Manual, bounded 1.12 combat-event sampling. No chat, file export or CVar writes.
-- COMBAT_TEXT_UPDATE uses arg1/arg2/arg3 directly in vanilla CombatText.lua.
-- UNIT_CASTEVENT: caster GUID, target GUID, action, spell ID, cast duration.
local LIMIT, DURATION, TEXTLIMIT = 1000, 120, 384
local frame, active, started, nextCheck, nextRefresh
local registered, unavailable = {}, {}
local hasNampower = false
local blockedReason
local zeroGuid = "0x0000000000000000"

local selfText = {
  CHAT_MSG_SPELL_SELF_BUFF = true, CHAT_MSG_SPELL_SELF_DAMAGE = true,
  CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = true, CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE = true,
  CHAT_MSG_SPELL_AURA_GONE_SELF = true, CHAT_MSG_SPELL_FAILED_LOCALPLAYER = true,
  CHAT_MSG_COMBAT_PET_HITS = true, CHAT_MSG_COMBAT_PET_MISSES = true,
  CHAT_MSG_SPELL_PET_DAMAGE = true,
}
local candidateText = {
  "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF", "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
  "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
  "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS", "CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS",
  "CHAT_MSG_COMBAT_FRIENDLY_DEATH", "CHAT_MSG_COMBAT_HOSTILE_DEATH",
}
local enhanced = {
  "SPELL_GO_SELF", "SPELL_GO_OTHER", "SPELL_DAMAGE_EVENT_SELF", "SPELL_DAMAGE_EVENT_OTHER",
  "AUTO_ATTACK_SELF", "AUTO_ATTACK_OTHER", "SPELL_MISS_SELF", "SPELL_MISS_OTHER",
  "SPELL_HEAL_BY_SELF", "SPELL_HEAL_BY_OTHER", "SPELL_ENERGIZE_BY_SELF", "SPELL_ENERGIZE_BY_OTHER",
}

local function now()
  return GetTime()
end

local function database()
  if type(EavesDropCaptureDB) ~= "table" then EavesDropCaptureDB = {} end
  local db = EavesDropCaptureDB
  if type(db.records) ~= "table" then db.records = {} end
  db.schema, db.limit, db.duration = 1, LIMIT, DURATION
  return db
end

local function refresh()
  if EavesDrop.RefreshCaptureStatus then EavesDrop:RefreshCaptureStatus()
  elseif EavesDrop.UpdateSettings then EavesDrop:UpdateSettings() end
end

local function scalar(value)
  local kind = type(value)
  if kind == "string" then
    if string.len(value) > TEXTLIMIT then
      local cut = TEXTLIMIT - 3
      local following = string.byte(value, cut + 1)
      if following and following >= 128 and following <= 191 then
        while cut > 0 do
          local byte = string.byte(value, cut)
          if byte < 128 or byte > 191 then break end
          cut = cut - 1
        end
        cut = cut - 1
      end
      return string.sub(value, 1, math.max(0, cut)) .. "..."
    end
    return value
  elseif kind == "boolean" then return value
  elseif kind == "number" and value * 0 == 0 then return value end
end

local function validGuid(guid)
  return type(guid) == "string" and string.len(guid) == 18 and
    string.find(guid, "^0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$") and guid ~= zeroGuid
end

local function guid(unit)
  local value
  if GetUnitGUID then value = GetUnitGUID(unit) end
  if not validGuid(value) and UnitGUID then value = UnitGUID(unit) end
  if not validGuid(value) and UnitExists then local exists; exists, value = UnitExists(unit) end
  if validGuid(value) then return value end
end

local function isLostName(value)
  return value == "迷失者" or value == "The Lost"
end

local function lostText(value)
  return type(value) == "string" and
    (string.find(value, "迷失者", 1, true) or string.find(value, "The Lost", 1, true))
end

local function actor(value, player, pet, role)
  if not validGuid(value) then return end
  local result = { guid = value, role = role }
  if value == player then result.relation = "player"
  elseif value == pet then result.relation = "pet" end
  if UnitName then result.name = scalar(UnitName(value)) end
  -- Vanilla creature GUID stores its entry in the middle three bytes. Identity
  -- is only a sampling candidate; name/entry alone never establishes ownership.
  if string.upper(string.sub(value, 3, 6)) == "F130" then
    result.entry = tonumber(string.sub(value, 7, 12), 16)
  end
  if hasNampower and not result.relation then
    if GetUnitGUID then
      local owner = GetUnitGUID(value .. "owner")
      if validGuid(owner) then result.ownerGUID = owner end
    end
    if GetUnitField then
      local created = GetUnitField(value, "createdBy")
      local summoned = GetUnitField(value, "summonedBy")
      if validGuid(created) then result.createdBy = created end
      if validGuid(summoned) then result.summonedBy = summoned end
    end
    local owner = result.ownerGUID or result.summonedBy or result.createdBy
    if owner then
      result.ownerGUID = owner
      result.relation = owner == player and "owned" or "other-owner"
    end
  end
  if not result.relation then result.relation = "unknown-owner" end
  result.candidate = result.entry == 59993 or isLostName(result.name) or nil
  return result
end

local function actorPair(name, args)
  if name == "SPELL_GO_SELF" or name == "SPELL_GO_OTHER" then return args[3], args[4] end
  if name == "AUTO_ATTACK_SELF" or name == "AUTO_ATTACK_OTHER" or
      name == "SPELL_MISS_SELF" or name == "SPELL_MISS_OTHER" or name == "UNIT_CASTEVENT" then
    return args[1], args[2]
  end
  if string.find(name, "^SPELL_DAMAGE_EVENT_") or string.find(name, "^SPELL_HEAL_BY_") or
      string.find(name, "^SPELL_ENERGIZE_BY_") then return args[2], args[1] end
end

local function belongsToCapture(name, args)
  if name == "COMBAT_TEXT_UPDATE" or selfText[name] then return true, {} end
  if string.find(name, "^CHAT_MSG_") then return lostText(args[1]), {} end
  local player, pet = guid("player"), guid("pet")
  local source, target = actorPair(name, args)
  local actors = {}
  local first = actor(source, player, pet, "source")
  local second = target ~= source and actor(target, player, pet, "target") or nil
  if first then table.insert(actors, first) end
  if second then table.insert(actors, second) end
  for _, item in ipairs(actors) do
    if item.relation == "player" or item.relation == "pet" or item.relation == "owned" or item.candidate then
      return true, actors
    end
  end
  -- Native SELF spell-go is self-scoped even when its GUID is briefly unavailable.
  return name == "SPELL_GO_SELF", actors
end

function EavesDrop:GetCaptureState()
  local db = database()
  local elapsed = active and math.max(0, now() - started) or tonumber(db.elapsed) or 0
  return { active = active == true, count = table.getn(db.records), limit = LIMIT,
    duration = DURATION, remaining = active and math.max(0, math.ceil(DURATION - elapsed)) or 0,
    reason = blockedReason or ((not active and db.reason == "采样中") and "上次会话已结束" or db.reason or "尚未开始"),
    unavailable = unavailable, registered = registered }
end

function EavesDrop:GetCaptureStatus()
  local state = self:GetCaptureState()
  local text = (state.active and "正在采样 " or "采样已停止 ") .. state.count .. "/" .. LIMIT
  if state.active then text = text .. "，剩余 " .. state.remaining .. " 秒"
  else text = text .. "（" .. state.reason .. "）" end
  if table.getn(unavailable) > 0 then text = text .. "；部分扩展事件不可用" end
  return text
end

function EavesDrop:StopCapture(reason)
  if not active then return false end
  local db = database()
  db.elapsed = math.min(DURATION, math.max(0, now() - started))
  db.reason = scalar(reason) or "手动停止"
  active = false
  blockedReason = nil
  if frame then frame:UnregisterAllEvents(); frame:SetScript("OnUpdate", nil) end
  registered = {}
  refresh()
  return true
end

function EavesDrop:ClearCapture()
  self:StopCapture("已清除")
  EavesDropCaptureDB = { schema = 1, limit = LIMIT, duration = DURATION, records = {}, elapsed = 0, reason = "已清除" }
  unavailable = {}
  blockedReason = nil
  refresh()
end

function EavesDrop:CaptureEvent(name, a1, a2, a3, a4, a5, a6, a7, a8, a9)
  if not active or not registered[name] then return end
  if now() - started >= DURATION then self:StopCapture("达到时间上限"); return end
  local args = { a1, a2, a3, a4, a5, a6, a7, a8, a9 }
  local accepted, actors = belongsToCapture(name, args)
  if not accepted then return end
  local record = { time = math.floor((now() - started) * 1000 + .5) / 1000,
    event = name, args = { n = 9 }, actors = actors }
  for i = 1, 9 do record.args[i] = scalar(args[i]) end
  local spellId
  if name == "SPELL_GO_SELF" or name == "SPELL_GO_OTHER" then spellId = a2
  elseif name == "UNIT_CASTEVENT" then spellId = a4
  elseif string.find(name, "^SPELL_DAMAGE_EVENT_") or string.find(name, "^SPELL_MISS_") or
      string.find(name, "^SPELL_HEAL_BY_") or string.find(name, "^SPELL_ENERGIZE_BY_") then spellId = a3 end
  if type(spellId) == "number" and spellId > 0 then
    record.spellId = spellId
    if hasNampower and GetSpellRecField then record.spellName = scalar(GetSpellRecField(spellId, "name")) end
    if not record.spellName and SpellInfo then record.spellName = scalar(SpellInfo(spellId)) end
  end
  local db = database()
  table.insert(db.records, record)
  if table.getn(db.records) >= LIMIT then self:StopCapture("达到条数上限") end
end

local function subscribe(name)
  local ok = pcall(frame.RegisterEvent, frame, name)
  if ok and (not frame.IsEventRegistered or frame:IsEventRegistered(name)) then registered[name] = true
  else table.insert(unavailable, name) end
end

local function captureEnvironment(profile)
  -- Collect this fixed whitelist only at manual start. Never change CVars or
  -- retain arbitrary globals/profile fields, account details or addon settings.
  local environment = { cvars = {}, nampower = {}, superwow = {} }
  if type(profile) == "table" then
    environment.datasource = scalar(profile.DATASOURCE)
    environment.procsource = scalar(profile.PROCSOURCE)
  end
  environment.superwow.version = scalar(SUPERWOW_VERSION)
  environment.superwow.description = scalar(SUPERWOW_STRING)
  if GetCVar then
    for _, name in ipairs({ "NP_EnableAutoAttackEvents", "NP_EnableSpellHealEvents",
        "NP_EnableSpellEnergizeEvents", "enableCombatText" }) do
      -- Old clients can error for a CVar not registered by a missing DLL.
      local ok, value = pcall(GetCVar, name)
      if ok then environment.cvars[name] = scalar(value) end
    end
  end
  local major, minor, patch
  if GetNampowerVersion then major, minor, patch = GetNampowerVersion() end
  environment.nampower.major = scalar(major)
  environment.nampower.minor = scalar(minor)
  environment.nampower.patch = scalar(patch)
  major, minor = tonumber(major) or 0, tonumber(minor) or 0
  return environment, major > 4 or (major == 4 and minor >= 5)
end

local function retainEnvironment(db, environment)
  db.environment, db.registered, db.unavailable = environment, {}, {}
  -- Independent plain tables survive StopCapture clearing its live registration
  -- map and make the saved snapshot useful after reload, with no live handles.
  for name in pairs(registered) do table.insert(db.registered, scalar(name)) end
  table.sort(db.registered)
  for _, name in ipairs(unavailable) do table.insert(db.unavailable, scalar(name)) end
end

function EavesDrop:StartCapture()
  if not self._running or (self.IsActive and not self:IsActive()) then
    blockedReason = "需先启用监视"
    refresh()
    return false, blockedReason
  end
  blockedReason = nil
  self:StopCapture("重新开始")
  EavesDropCaptureDB = { schema = 1, limit = LIMIT, duration = DURATION, records = {}, elapsed = 0, reason = "采样中" }
  registered, unavailable = {}, {}
  started = now()
  nextCheck, nextRefresh, active = started + .25, started + 1, true
  if not frame then
    frame = CreateFrame("Frame", "EavesDropCaptureFrame", UIParent)
    frame:SetScript("OnEvent", function()
      if event == "PLAYER_LOGOUT" then EavesDrop:StopCapture("退出游戏")
      else EavesDrop:CaptureEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end
    end)
    self.captureFrame = frame
  end
  subscribe("COMBAT_TEXT_UPDATE")
  subscribe("PLAYER_LOGOUT")
  for name in pairs(selfText) do subscribe(name) end
  for _, name in ipairs(candidateText) do subscribe(name) end
  local environment
  environment, hasNampower = captureEnvironment(self.db and self.db.profile)
  if hasNampower then
    for _, name in ipairs(enhanced) do subscribe(name) end
  else table.insert(unavailable, "nampower 增强事件") end
  if SUPERWOW_VERSION or SUPERWOW_STRING or SetAutoloot then subscribe("UNIT_CASTEVENT")
  else table.insert(unavailable, "SuperWoW 施法事件") end
  retainEnvironment(EavesDropCaptureDB, environment)
  frame:SetScript("OnUpdate", function()
    local time = now()
    if active and time >= nextCheck then
      nextCheck = time + .25
      if time - started >= DURATION then EavesDrop:StopCapture("达到时间上限")
      elseif time >= nextRefresh then nextRefresh = time + 1; refresh() end
    end
  end)
  refresh()
  return true
end
