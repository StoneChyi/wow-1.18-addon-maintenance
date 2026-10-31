pfUI:RegisterModule("autoshift", "vanilla", function ()
  pfUI.autoshift = CreateFrame("Frame")
  local driver = pfUI.autoshift
  driver:RegisterEvent("UI_ERROR_MESSAGE")
  driver:RegisterEvent("UI_INFO_MESSAGE")
  driver:RegisterEvent("ADDON_LOADED")
  driver:RegisterEvent("PLAYER_ENTERING_WORLD")

  local function ErrorPattern(template)
    if type(template) ~= "string" then return "^$" end
    local first, last = string.find(template, "%s", 1, true)
    if not first then return "^$" end
    local function Escape(text) return string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") end
    return "^" .. Escape(string.sub(template, 1, first - 1)) .. "(.+)" .. Escape(string.sub(template, last + 1)) .. "$"
  end
  pfUI.autoshift.scanString = ErrorPattern(SPELL_FAILED_ONLY_SHAPESHIFT)
  pfUI.autoshift.mounts = {
    -- deDE
    "^Erhöht Tempo um (.+)%%",
    -- enUS
    "^Increases speed by (.+)%%",
    -- esES
    "^Aumenta la velocidad en un (.+)%%",
    -- frFR
    "^Augmente la vitesse de (.+)%%",
    -- ruRU
    "^Скорость увеличена на (.+)%%",
    -- koKR
    "^이동 속도 (.+)%%만큼 증가",
    -- zhCN
    "^速度提高(.+)%%",
    -- turtle-wow
    "speed based on", "Slow and steady...", "Riding",
    "Lento y constante...", "Aumenta la velocidad según tu habilidad de Montar.",
    "根据您的骑行技能提高速度。", "根据骑术技能提高速度。", "又慢又稳......",
  }

  pfUI.autoshift.shapeshifts = {
    "ability_racial_bearform", "ability_druid_catform", "ability_druid_travelform",
    "ability_druid_aquaticform", "spell_shadow_shadowform", "spell_nature_spiritwolf",
  }

  -- an agility buff exists which has the same icon as the moonkin form
  -- therefore only add the moonkin icon to the removable buffs if
  -- moonkin is skilled and player is druid. Frame is required as talentpoints
  -- are only accessible after certain events.
  local moonkin_scan = CreateFrame("Frame")
  moonkin_scan:RegisterEvent("PLAYER_ENTERING_WORLD")
  moonkin_scan:RegisterEvent("UNIT_NAME_UPDATE")
  moonkin_scan:SetScript("OnEvent", function()
    local _, class = UnitClass("player")
    if class == "DRUID" then
      local _,_,_,_,moonkin = GetTalentInfo(1,16)
      if moonkin == 1 then
        table.insert(pfUI.autoshift.shapeshifts, "spell_nature_forceofnature")
        moonkin_scan:UnregisterAllEvents()
      end
    else
      moonkin_scan:UnregisterAllEvents()
    end
  end)

  pfUI.autoshift.errors = { SPELL_FAILED_NOT_MOUNTED, ERR_ATTACK_MOUNTED, ERR_TAXIPLAYERALREADYMOUNTED,
    SPELL_FAILED_NOT_SHAPESHIFT, SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED, SPELL_NOT_SHAPESHIFTED,
    SPELL_NOT_SHAPESHIFTED_NOSPACE, ERR_CANT_INTERACT_SHAPESHIFTED, ERR_NOT_WHILE_SHAPESHIFTED,
    ERR_NO_ITEMS_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED,ERR_MOUNT_SHAPESHIFTED,
    ERR_EMBLEMERROR_NOTABARDGEOSET }

  pfUI.autoshift.scanner = libtipscan:GetScanner("dismount")

  local function Module(name)
    return Automaton and Automaton.modules and Automaton.modules[name]
  end
  function driver:SyncOwnership(managed)
    if managed ~= nil then self.managed = managed end
    if self.managed == nil then self.managed = not C.automation or C.automation.enabled ~= "0" end
    for _, name in ipairs({ "Stand", "ShaguStance" }) do
      local module = Module(name)
      if module and module.SetMovementOwner then module:SetMovementOwner(self.managed and self or nil) end
    end
    return true
  end
  pfUI.automationIntegrations = pfUI.automationIntegrations or {}
  for _, name in ipairs({ "Stand", "ShaguStance" }) do
    pfUI.automationIntegrations[name] = { Sync = function(_, managed) return driver:SyncOwnership(managed) end }
  end

  function driver:Stand(msg)
    local now = GetTime()
    if self.lastStandMessage == msg and self.lastStandTime and now - self.lastStandTime < .2 then return end
    self.lastStandMessage, self.lastStandTime = msg, now
    DoEmote("stand")
  end
  function driver:SwitchRequiredStance(msg)
    local _, _, names = string.find(msg, self.scanString)
    if not names then return false end
    -- Alternatives in the error are choices, not a list of spells to cast.
    local allowed, candidate = {}, nil
    for name in string.gfind(names, "[^,]+") do
      name = string.gsub(name, "^%s*(.-)%s*$", "%1")
      if name == "豹形态" then name = "猎豹形态" end
      allowed[name] = true
    end
    for i = 1, GetNumShapeshiftForms() do
      local _, known, active, castable = GetShapeshiftFormInfo(i)
      if allowed[known] then
        if active and active ~= 0 then return true end
        if not candidate and castable and castable ~= 0 then candidate = known end
      end
    end
    if candidate then CastSpellByName(candidate) end
    return true
  end
  function driver:HandleEvent(kind, msg)
    if kind == "ADDON_LOADED" or kind == "PLAYER_ENTERING_WORLD" then self:SyncOwnership(); return end
    if (kind ~= "UI_ERROR_MESSAGE" and kind ~= "UI_INFO_MESSAGE") or type(msg) ~= "string" then return end
    local stand, stance = Module("Stand"), Module("ShaguStance")
    if stand and stand.runtimeActive and stand:HandlesMessage(msg) then
      if stand.movementOwner == self then stand:HandleError(msg) end
      return -- independent Stand owns this message when hosting is off
    end
    if kind == "UI_INFO_MESSAGE" then return end
    if msg == SPELL_FAILED_NOT_STANDING then self:Stand(msg); return end
    if stance and stance.runtimeActive then
      if stance.movementOwner == self then stance:HandleError(msg) end
      -- Its error fallback runs on the next matching user action.
      if string.find(msg, self.scanString) then return end
    elseif self:SwitchRequiredStance(msg) then return end

    for _, errorstring in pairs(self.errors) do
      if msg == errorstring then
        -- Clicking an NPC in combat must never cancel a combat form.
        if msg == ERR_CANT_INTERACT_SHAPESHIFTED and UnitAffectingCombat("player") then return end
        local later
        local dismount = C.global.autodismount ~= "0"
        for i = 0, 31 do
          local texture = GetPlayerBuffTexture(i)
          if texture then
            if dismount then
              self.scanner:SetPlayerBuff(i)
              for _, pattern in ipairs(self.mounts) do
                if self.scanner:Find(pattern) then CancelPlayerBuff(i); return end
              end
            end
            for _, icon in ipairs(self.shapeshifts) do
              if string.find(string.lower(texture), icon, 1, true) then
                if icon == "spell_shadow_shadowform" then later = i
                else CancelPlayerBuff(i); return end
              end
            end
          end
        end
        if later then CancelPlayerBuff(later) end
        return
      end
    end
  end
  driver:SetScript("OnEvent", function() driver:HandleEvent(event, arg1) end)
  driver:SyncOwnership()
end)
