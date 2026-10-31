assert(Automaton, "Automaton not found!")

Automaton_ShaguStance = Automaton:NewModule("ShaguStance")
Automaton_ShaguStance.modulename = "自动姿态切换"
Automaton_ShaguStance.moduledesc = "保留战士错误后再次施法切姿态，以及德鲁伊施法前形态判断"
Automaton_ShaguStance.options = {}

local function Trim(value)
  return type(value) == "string" and string.gsub(value, "^%s*(.-)%s*$", "%1") or ""
end
local function FormName(value)
  value = Trim(value)
  return value == "豹形态" and "猎豹形态" or value
end
local function FormatPattern(value, token, replacement)
  if type(value) ~= "string" then return nil end
  local first, last = string.find(value, token, 1, true)
  if not first then return nil end
  local function Escape(text) return string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") end
  return "^" .. Escape(string.sub(value, 1, first - 1)) .. replacement .. Escape(string.sub(value, last + 1)) .. "$"
end
local function IsTurtle()
  local build = GetBuildInfo()
  local _, _, major, minor = string.find(build or "", "^(%d+)%.(%d+)")
  return tonumber(major) == 1 and (tonumber(minor) or 0) >= 16
end
local function ReadLine(tip, number)
  local line = tip and _G[tip:GetName() .. "TextLeft" .. number]
  return line and line:GetText()
end

function Automaton_ShaguStance:OnInitialize()
  self.db = Automaton:AcquireDBNamespace("ShaguStance")
  Automaton:RegisterDefaults("ShaguStance", "profile", { disabled = false })
  Automaton:SetDisabledAsDefault(self, "ShaguStance")
  self:RegisterOptions(self.options)
  self.scanString = FormatPattern(SPELL_FAILED_ONLY_SHAPESHIFT, "%s", "(.+)")
  self.manaString = FormatPattern(MANA_COST, "%d", "%d+")
  if self.manaString then self.manaString = string.sub(self.manaString, 1, -2) end
  self.isTurtle = IsTurtle()
end

function Automaton_ShaguStance:ClearPending()
  self.lastError, self.pendingStance, self.lastAction, self.formRequest = "", nil, nil, nil
end
function Automaton_ShaguStance:UpdateEvents()
  self:UnregisterAllEvents()
  if not self.runtimeActive then return end
  if not self.movementOwner then self:RegisterEvent("UI_ERROR_MESSAGE") end
  self:RegisterEvent("PLAYER_LEAVING_WORLD", "ClearPending")
end
function Automaton_ShaguStance:SetMovementOwner(owner)
  if self.movementOwner ~= owner then
    self.movementOwner = owner
    self:ClearPending()
  end
  self:UpdateEvents()
end
function Automaton_ShaguStance:OnEnable()
  if self.runtimeActive then return end
  self.runtimeActive = true
  self:ClearPending()
  local _, class = UnitClass("player")
  if class == "DRUID" then
    -- Named GameTooltipTemplate supplies initialized font strings; reuse on enable.
    self.tip = self.tip or _G.Automaton_ShaguStance_Tip or CreateFrame("GameTooltip", "Automaton_ShaguStance_Tip", nil, "GameTooltipTemplate")
    self.tip:SetOwner(UIParent, "ANCHOR_NONE")
  end
  self:Hook("CastSpell")
  self:Hook("CastSpellByName")
  self:Hook("UseAction")
  if pfUI and pfUI.autoshift and pfUI.autoshift.SyncOwnership then pfUI.autoshift:SyncOwnership() end
  self:UpdateEvents()
end
function Automaton_ShaguStance:OnDisable()
  self.runtimeActive = nil
  self:UnregisterAllEvents()
  self:UnhookAll()
  self:ClearPending()
  if self.tip then self.tip:Hide() end
  if pfUI and pfUI.autoshift and pfUI.autoshift.SyncOwnership then pfUI.autoshift:SyncOwnership() end
end

function Automaton_ShaguStance:HandleError(msg)
  if self.switchingForm or not self.runtimeActive or type(msg) ~= "string" or not self.scanString then return false end
  local _, _, names = string.find(msg, self.scanString)
  if not names then
    self.pendingStance, self.lastError = nil, ""
    return false
  end
  -- The next action may be unrelated to the failed spell; never reuse that error.
  local action = self.lastAction
  if not action or GetTime() - action.time > 5 then return false end
  self.lastError = msg
  self.pendingStance = { names = names, key = action.key, time = GetTime() }
  return true
end
function Automaton_ShaguStance:UI_ERROR_MESSAGE(msg)
  return self:HandleError(msg or arg1)
end

-- A form change can reach the server before its active-state update reaches us.
-- Repeated clicks in that interval must not toggle the same form twice.
function Automaton_ShaguStance:RequestForm(index)
  local _, _, active = GetShapeshiftFormInfo(index)
  local request = self.formRequest
  if request and request.index == index and request.active == active and GetTime() - request.time < 1 then return true end
  self.formRequest = { index = index, active = active, time = GetTime() }
  self.switchingForm = true
  local ok, err = pcall(CastShapeshiftForm, index)
  self.switchingForm = nil
  if not ok then self.formRequest = nil; error(err) end
  return true
end

-- Prefer an already-active allowed form, otherwise one learned/castable form.
-- The 1.12 API returns texture, name, active, castable; form indices vary by level.
function Automaton_ShaguStance:ChooseForm(names)
  local allowed = {}
  for name in string.gfind(string.gsub(names, "，", ","), "[^,]+") do allowed[FormName(name)] = true end
  local candidate
  for i = 1, GetNumShapeshiftForms() do
    local _, name, active, castable = GetShapeshiftFormInfo(i)
    if allowed[FormName(name)] then
      if active and active ~= 0 then return true end
      if not candidate and castable and castable ~= 0 then candidate = i end
    end
  end
  if candidate then return self:RequestForm(candidate) end
  return false
end
function Automaton_ShaguStance:SwitchStance(key)
  local pending = self.pendingStance
  self.pendingStance, self.lastError = nil, ""
  if pending and pending.key == key and GetTime() - pending.time <= 5 then
    return self:ChooseForm(pending.names)
  end
  return false
end
function Automaton_ShaguStance:Unshapeshift()
  for i = 1, GetNumShapeshiftForms() do
    local _, _, active = GetShapeshiftFormInfo(i)
    if active and active ~= 0 then return self:RequestForm(i) end
  end
  return false
end

function Automaton_ShaguStance:FindSpell(spellName, rank)
  if type(spellName) ~= "string" then return end
  local i = 1
  while true do
    local name, subtext = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then return end
    if name == spellName and (not rank or subtext == rank) then return i end
    i = i + 1
  end
end
function Automaton_ShaguStance:CheckAndSwitchDruidForm(spellName, spellId, book)
  local _, class = UnitClass("player")
  if class ~= "DRUID" or not self.tip or not spellName or spellName == "" then return false end
  local id = spellId or self:FindSpell(spellName)
  if not id or (book and book ~= BOOKTYPE_SPELL) then return false end
  self.tip:ClearLines()
  self.tip:SetSpell(id, BOOKTYPE_SPELL)
  local powerType = UnitPowerType("player")
  for j = 3, 4 do
    local requirement = Trim(ReadLine(self.tip, j))
    if requirement == "需要熊形态, 巨熊形态" then
      if powerType ~= 1 then self:ChooseForm("熊形态, 巨熊形态") end
      return true
    elseif requirement == "需要豹形态" or requirement == "需要猎豹形态" then
      if powerType ~= 3 then self:ChooseForm("猎豹形态") end
      return true
    end
  end
  local mana = ReadLine(self.tip, 2)
  if mana and self.manaString and string.find(mana, self.manaString) and powerType ~= 0 then
    if self.isTurtle and ((string.find(spellName, "自然之握", 1, true) and powerType == 1) or string.find(spellName, "重整", 1, true)) then
      return true
    end
    self:Unshapeshift()
    return true
  end
  return false
end
function Automaton_ShaguStance:PrepareAction(key, spellName, spellId, book)
  if not self.runtimeActive then return end
  if self:CheckAndSwitchDruidForm(spellName, spellId, book) then
    self.pendingStance, self.lastError = nil, ""
  else
    self:SwitchStance(key)
  end
  self.lastAction = { key = key, time = GetTime() }
end

function Automaton_ShaguStance:CastSpell(spellId, book)
  local spellName = GetSpellName(spellId, book)
  self:PrepareAction("spell:" .. tostring(book) .. ":" .. tostring(spellId), spellName, spellId, book)
  return self.hooks.CastSpell(spellId, book)
end
function Automaton_ShaguStance:CastSpellByName(spellName, onSelf)
  local _, _, rawName, rank = string.find(spellName or "", "^(.-)%s*%((.-)%)$")
  rawName = Trim(rawName or spellName)
  local _, class = UnitClass("player")
  local id = class == "DRUID" and self:FindSpell(rawName, rank)
  self:PrepareAction("name:" .. tostring(spellName), id and rawName, id, BOOKTYPE_SPELL)
  -- The original requested rank and self-target flag are never rewritten.
  return self.hooks.CastSpellByName(spellName, onSelf)
end
function Automaton_ShaguStance:UseAction(slot, checkCursor, onSelf)
  local macro = GetActionText(slot)
  local texture = GetActionTexture(slot)
  local spellName, id
  if not macro and self.tip then
    self.tip:ClearLines()
    self.tip:SetAction(slot)
    spellName = ReadLine(self.tip, 1)
    id = self:FindSpell(spellName)
    -- Item tooltips can share a spell name. Require matching spell artwork too.
    if not id or not GetSpellTexture or GetSpellTexture(id, BOOKTYPE_SPELL) ~= texture then id, spellName = nil, nil end
  end
  local key = "action:" .. tostring(slot) .. ":" .. tostring(macro) .. ":" .. tostring(texture) .. ":" .. tostring(spellName)
  self:PrepareAction(key, spellName, id, BOOKTYPE_SPELL)
  return self.hooks.UseAction(slot, checkCursor, onSelf)
end
