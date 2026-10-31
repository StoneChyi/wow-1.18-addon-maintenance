pfUI:RegisterModule("xpbar", "vanilla:tbc", function ()
  local rawborder, default_border = GetBorderSize()
  local parse_faction = SanitizePattern(FACTION_STANDING_INCREASED)

  -- One accumulator drives native bar text and tooltip, including level changes.
  local progress = { gained = 0, started = GetTime() }
  function progress:Reset()
    self.gained, self.lastGain, self.pendingLevel, self.resetXP = 0, nil, nil, nil
    self.started = GetTime()
    self.xp, self.maximum, self.level = UnitXP("player") or 0, UnitXPMax("player") or 0, UnitLevel("player")
  end
  function progress:Observe()
    local xp, maximum, level = UnitXP("player") or 0, UnitXPMax("player") or 0, UnitLevel("player")
    if not self.level then self:Reset(); return end
    if self.pendingLevel then level = math.max(level, self.pendingLevel) end
    if level < self.level then return end
    local gain
    if level == self.level and xp >= self.xp then gain = xp - self.xp
    elseif level == self.level + 1 and self.maximum > 0 then gain = self.maximum - self.xp + xp
    elseif level == self.level and xp < self.xp then self.resetXP = xp; return end
    if gain and gain > 0 then self.gained = self.gained + gain; self.lastGain = gain end
    if level ~= self.level and not gain then self.lastGain = nil end
    self.xp, self.maximum, self.level = xp, maximum, level
    self.pendingLevel, self.resetXP = nil, nil
  end
  function progress:Stats()
    local elapsed = math.max(0, GetTime() - self.started)
    local remaining = math.max(0, (UnitXPMax("player") or 0) - (UnitXP("player") or 0))
    local rate = elapsed > 0 and self.gained * 3600 / elapsed or 0
    local seconds = rate > 0 and remaining * 3600 / rate or nil
    local count = self.lastGain and self.lastGain > 0 and math.ceil(remaining / self.lastGain) or nil
    return rate, seconds, count
  end
  progress:Reset()
  if C.panel.xp.xp_stats == nil then C.panel.xp.xp_stats = "0" end
  if C.panel.xp.xp_estimate == nil then C.panel.xp.xp_estimate = "1" end
  local data = CreateFrame("Frame", "pfExperienceBarData", UIParent)
  data:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
  data:RegisterEvent("PLAYER_ENTERING_WORLD")
  data:RegisterEvent("PLAYER_LEVEL_UP")
  data:RegisterEvent("PLAYER_XP_UPDATE")
  data:SetScript("OnEvent", function()
    if event == "PLAYER_LEVEL_UP" then
      progress.pendingLevel = tonumber(arg1)
      if progress.resetXP then progress:Observe() end
    elseif event == "PLAYER_ENTERING_WORLD" or (event == "PLAYER_XP_UPDATE" and (not arg1 or arg1 == "player")) then
      progress:Observe()
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
      local _,_, faction, amount = string.find(arg1, parse_faction)
      data.faction = faction or data.faction
    end
  end)
  local function ProgressText()
    local rate, seconds, count = progress:Stats()
    local text = "每小时经验: " .. math.floor(rate)
    if seconds then text = text .. "  预计升级: " .. SecondsToTime(seconds) end
    if C.panel.xp.xp_estimate == "1" and count then text = text .. "  同等经验: " .. count .. "次" end
    return text
  end

  local function OnLeave(self)
    local self = self or this

    self.tick = GetTime() + 3.00
    GameTooltip:Hide()
  end

local function OnEnter(self)
  local self = self or this
  local lines = {}

  -- set either experience, reputation or flex-rep handler
  local mode = self.display
  if self.display == "XPFLEX" then
    mode = UnitLevel("player") < MAX_PLAYER_LEVEL and "XP" or "REP"
  elseif self.display == "FLEX" then
    mode = "REP"
  end

  self:SetAlpha(1)

  if mode == "XP" then
    local xp, xpmax, exh = UnitXP("player") or 0, math.max(1, UnitXPMax("player") or 0), GetXPExhaustion()
    local xp_perc = round(xp / xpmax * 100)
    local remaining = xpmax - xp
    local remaining_perc = round(remaining / xpmax * 100)
    local exh_perc = GetXPExhaustion() and round(GetXPExhaustion() / xpmax * 100) or 0
    local avg_hour, seconds, count = progress:Stats()
    local session = progress.gained
    avg_hour = math.floor(avg_hour)
    local time_remaining = seconds and SecondsToTime(seconds) or "--"

    -- fill gametooltip data
    table.insert(lines, { "|cff555555" .. T["Experience"], "" })
    table.insert(lines, { T["XP"], "|cffffffff" .. xp .. " / " .. xpmax .. " (" .. xp_perc .. "%)" })
    table.insert(lines, { T["Remaining"], "|cffffffff" .. remaining .. " (" .. remaining_perc .. "%)" })
    if IsResting() then
      table.insert(lines, { T["Status"], "|cffffffff" .. T["Resting"] })
    end
    if GetXPExhaustion() then
      table.insert(lines, { T["Rested"], "|cff5555ff+" .. exh .. " (" .. exh_perc .. "%)" })
    end
    table.insert(lines, { "" })
    table.insert(lines, { T["This Session"], "|cffffffff" .. session })
    table.insert(lines, { T["Average Per Hour"], "|cffffffff" .. avg_hour })
    table.insert(lines, { T["Time Remaining"], "|cffffffff" .. time_remaining })
    if C.panel.xp.xp_estimate == "1" and count then
      table.insert(lines, { "按最近一次经验估算", "|cffffffff" .. count .. " 次" })
      table.insert(lines, { "|cff888888任务、击杀等经验均会更新估算，不等同于击杀次数。" })
    end
  elseif mode == "PETXP" then
    local xp, xpmax = GetPetExperience()
    xp, xpmax = xp or 0, math.max(1, xpmax or 0)
    local xp_perc = round(xp / xpmax * 100)
    local remaining = xpmax - xp
    local remaining_perc = round(remaining / xpmax * 100)

    -- fill gametooltip data
    table.insert(lines, { "|cff555555" .. T["Experience"], "" })
    table.insert(lines, { T["XP"], "|cffffffff" .. xp .. " / " .. xpmax .. " (" .. xp_perc .. "%)" })
    table.insert(lines, { T["Remaining"], "|cffffffff" .. remaining .. " (" .. remaining_perc .. "%)" })
  elseif mode == "REP" then
    for i=1, 99 do
      local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, isWatched = GetFactionInfo(i)
      if ( isWatched and not self.faction ) or ( self.faction and name == self.faction) then
        barMax = barMax - barMin
        barValue = barValue - barMin

        local color = FACTION_BAR_COLORS[standingID]
        if color then
          color = rgbhex(color.r + .3, color.g + .3, color.b + .3)
        else
          color = rgbhex(.5, .5, .5)
        end

        table.insert(lines, { "|cff555555" .. T["Reputation"], "" })
        table.insert(lines, { color .. name .. " (" .. GetText("FACTION_STANDING_LABEL"..standingID, gender) .. ")"})
        table.insert(lines, { barValue .. " / " .. barMax .. " (" .. round(barValue / barMax * 100) .. "%)" })
        break
      end
    end
  end

  -- draw tooltip
  GameTooltip:ClearLines()
  GameTooltip_SetDefaultAnchor(GameTooltip, self)
  GameTooltip:SetOwner(self, "ANCHOR_CURSOR")

  for id, data in pairs(lines) do
    if data[2] then
      GameTooltip:AddDoubleLine(data[1], data[2])
    else
      GameTooltip:AddLine(data[1])
    end
  end
  GameTooltip:Show()
end

  local function OnUpdate(self)
    local self = self or this

    if self.progressMode and C.panel.xp.xp_stats == "1" and (self.progressTick or 0) <= GetTime() then
      self.progressTick = GetTime() + 1
      self.bar.text:SetText(ProgressText())
    end
    if self.text_mouse == "1" and (self.text == "1" or self.progressMode and C.panel.xp.xp_stats == "1") then
      if MouseIsOver(self) then
        self.bar.text:Show()
      else
        self.bar.text:Hide()
      end
    end

    if self.always then return end
    if self:GetAlpha() == 0 or MouseIsOver(self) then return end
    if ( self.tick or 1) > GetTime() then return else self.tick = GetTime() + .01 end
    self:SetAlpha(self:GetAlpha() - .05)
  end

  local function OnEvent(self)
    local self = self or this

    if event == "PLAYER_XP_UPDATE" and (not arg1 or arg1 == "player") then progress:Observe() end

    -- realign when entering world to ensure all frames got loaded
    AlignToPosition(self, _G[self.anchor], self.position, default_border*3)
    UpdateMovable(self, true)

    -- set either experience, reputation or flex-rep handler
    local mode = self.display
    if self.display == "XPFLEX" then
      self.faction = data.faction or nil
      mode = UnitLevel("player") < MAX_PLAYER_LEVEL and "XP" or "REP"
    elseif self.display == "FLEX" then
      self.faction = data.faction or nil
      mode = "REP"
    end

    self.progressMode = mode == "XP"
    if mode == "DISABLED" or (mode == "XP" and (UnitLevel("player") >= MAX_PLAYER_LEVEL or (UnitXPMax("player") or 0) <= 0)) then
      self.enabled = nil; self:Hide(); return
    end
    self:Show()
    if self.always then self:SetAlpha(1) end
    if self.text == "1" or self.progressMode and C.panel.xp.xp_stats == "1" then self.bar.text:Show() else self.bar.text:Hide() end

    -- skip on events of no interest
    if mode == "XP" and ( event == "CHAT_MSG_COMBAT_FACTION_CHANGE" or event == "UPDATE_FACTION" ) then return end
    if mode == "REP" and ( event == "PLAYER_XP_UPDATE" or event == "UPDATE_EXHAUSTION" ) then return end

    if mode == "XP" then
      self.enabled = true
      self:SetAlpha(1)
      self.bar:SetMinMaxValues(0, UnitXPMax("player"))
      self.bar:SetValue(UnitXP("player"))
      if GetXPExhaustion() then
        self.restedbar:Show()
        self.restedbar:SetMinMaxValues(0, UnitXPMax("player"))
        self.restedbar:SetValue(math.min(UnitXPMax("player"), UnitXP("player") + GetXPExhaustion()))
      else
        self.restedbar:Hide()
      end

      local text = "%s: %s%%"
      local xp, xpmax, ex = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
      local xpperc = round(xp / xpmax * 100)
      local experc = ex and round(ex / xpmax * 100) or 0
      if ex then text = "%s: %s%% (%s%% %s)" end
      self.bar.text:SetText(string.format(text, T["Experience"], xpperc, experc, T["Rested"]))
      if C.panel.xp.xp_stats == "1" then self.bar.text:SetText(ProgressText()) end

      self.tick = GetTime() + self.timeout
      return
    elseif mode == "PETXP" then
      self.restedbar:Hide()
      self.enabled = true
      self:SetAlpha(1)

      local currXP, nextXP = GetPetExperience()
      self.bar:SetMinMaxValues(min(0, currXP), nextXP)
      self.bar:SetValue(currXP)

      local text = "%s: %s%%"
      local xpperc = nextXP and nextXP ~= 0 and round(currXP / nextXP * 100) or 0
      self.bar.text:SetText(string.format(text, T["Pet Experience"], xpperc))

      self.tick = GetTime() + self.timeout
      return
    elseif mode == "REP" then
      self.restedbar:Hide()

      for i=1, 99 do
        local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, isWatched = GetFactionInfo(i)
        if ( isWatched and not self.faction ) or ( self.faction and name == self.faction) then
          self.enabled = true
          self:SetAlpha(1)

          barMax = barMax - barMin
          barValue = barValue - barMin

          self.bar:SetMinMaxValues(0, barMax)
          self.bar:SetValue(barValue)

          local color = FACTION_BAR_COLORS[standingID]
          if color then
            self.bar:SetStatusBarColor((color.r + .5) * .5, (color.g + .5) * .5, (color.b + .5) * .5, 1)
          else
            self.bar:SetStatusBarColor(.5,.5,.5,1)
          end

          local text = "%s: %s%% (%s)"
          local perc = round(barValue / barMax * 100)
          local standing = GetText("FACTION_STANDING_LABEL"..standingID, gender)
          self.bar.text:SetText(string.format(text, name, perc, standing))

          self.tick = GetTime() + self.timeout
          return
        end
      end
    end

    self.bar:SetStatusBarColor(.5,.5,.5,1)
    self.bar:SetMinMaxValues(0, 1)
    self.bar:SetValue(0)
  end

  local function CreateBar(t)
    local name = t == "XP" and "pfExperienceBar" or "pfReputationBar"
    local b = _G[name] or CreateFrame("Frame", name, UIParent)

    b.xp_color = C.panel.xp.xp_color
    b.rest_color = C.panel.xp.rest_color
    b.width = t == "XP" and C.panel.xp.xp_width or C.panel.xp.rep_width
    b.height = t == "XP" and C.panel.xp.xp_height or C.panel.xp.rep_height
    b.mode = t == "XP" and C.panel.xp.xp_mode or C.panel.xp.rep_mode
    b.timeout = t == "XP" and tonumber(C.panel.xp.xp_timeout) or tonumber(C.panel.xp.rep_timeout)
    b.anchor = t == "XP" and C.panel.xp.xp_anchor or C.panel.xp.rep_anchor
    b.position = t == "XP" and C.panel.xp.xp_position or C.panel.xp.rep_position
    b.display = t == "XP" and C.panel.xp.xp_display or C.panel.xp.rep_display
    b.text = t == "XP" and C.panel.xp.xp_text or C.panel.xp.rep_text
    b.text_off_y = t == "XP" and C.panel.xp.xp_text_off_y or C.panel.xp.rep_text_off_y
    b.text_mouse = t == "XP" and C.panel.xp.xp_text_mouse or C.panel.xp.rep_text_mouse

    local barLevel, restedLevel = 0, 1
    if C.panel.xp.dont_overlap == "1" then
      barLevel, restedLevel = 1, 0
    end

    if t == "XP" and C.panel.xp.xp_always == "1" then
      b.always = true
    elseif t == "REP" and C.panel.xp.rep_always == "1" then
      b.always = true
    else
      b.always = nil
    end

    b:SetWidth(b.width)
    b:SetHeight(b.height)
    b:SetFrameStrata("BACKGROUND")

    AlignToPosition(b, _G[b.anchor], b.position, default_border*3)
    UpdateMovable(b, true)
    CreateBackdrop(b)
    CreateBackdropShadow(b)

    b.bar = b.bar or CreateFrame("StatusBar", nil, b)
    b.bar:SetStatusBarTexture(pfUI.media[C.panel.xp.texture])
    b.bar:ClearAllPoints()
    b.bar:SetAllPoints(b)
    b.bar:SetFrameLevel(barLevel)

    local cr, cg, cb, ca = pfUI.api.GetStringColor(b.xp_color)
    b.bar:SetStatusBarColor(cr,cg,cb,ca)
    b.bar:SetOrientation(b.mode)

    b.bar.text = b.bar.text or b.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.bar.text:SetFontObject(GameFontHighlight)
    b.bar.text:ClearAllPoints()
    b.bar.text:SetPoint("CENTER", b, "CENTER", 0, b.text_off_y)
    b.bar.text:SetJustifyH("CENTER")
    b.bar.text:SetFont(pfUI.font_default, C.global.font_size, "OUTLINE")

    if b.text == "1" then
      b.bar.text:Show()
    else
      b.bar.text:Hide()
    end

    b.restedbar = b.restedbar or CreateFrame("StatusBar", nil, b)
    b.restedbar:SetStatusBarTexture(pfUI.media[C.panel.xp.texture])
    b.restedbar:ClearAllPoints()
    b.restedbar:SetAllPoints(b)
    b.restedbar:SetFrameLevel(restedLevel)
    local cr, cg, cb, ca = pfUI.api.GetStringColor(b.rest_color)
    b.restedbar:SetStatusBarColor(cr,cg,cb,ca)
    b.restedbar:SetOrientation(b.mode)

    -- auto hide
    b:EnableMouse(true)

    b:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    b:RegisterEvent("UNIT_PET")
    b:RegisterEvent("UNIT_LEVEL")
    b:RegisterEvent("UNIT_PET_EXPERIENCE")
    b:RegisterEvent("PLAYER_ENTERING_WORLD")
    b:RegisterEvent("UPDATE_EXHAUSTION")
    b:RegisterEvent("PLAYER_XP_UPDATE")
    b:RegisterEvent("PLAYER_LEVEL_UP")
    b:RegisterEvent("UPDATE_FACTION")

    b:SetScript("OnUpdate", OnUpdate)
    b:SetScript("OnEvent", OnEvent)
    b:SetScript("OnEnter", OnEnter)
    b:SetScript("OnLeave", OnLeave)
    b:GetScript("OnEvent")(b)

    return b
  end

  pfUI.xpbar = { ["UpdateConfig"] = function()
    pfUI.xp = CreateBar("XP")
    pfUI.rep = CreateBar("REP")
  end}

  pfUI.xpbar.progress = progress
  function pfUI.xpbar:ResetProgress()
    progress:Reset()
    self:UpdateConfig()
  end
  function pfUI.xpbar:ResetPosition()
    C.position = C.position or {}
    C.position.pfExperienceBar = nil
    self:UpdateConfig()
  end
  local integration = { name = "ExpBar", title = "经验条统计" }
  pfUI.automationIntegrations = pfUI.automationIntegrations or {}
  pfUI.automationIntegrations.ExpBar = integration
  function integration:IsManaged() return self.active and true or false end
  function integration:GetEnabled() return C.panel.xp.xp_display ~= "DISABLED" end
  function integration:SetEnabled(value)
    if value and C.panel.xp.xp_display == "DISABLED" then
      C.panel.xp.xp_display = C.panel.xp.xp_fusion_display or "XPFLEX"
    elseif not value then
      if C.panel.xp.xp_display ~= "DISABLED" then C.panel.xp.xp_fusion_display = C.panel.xp.xp_display end
      C.panel.xp.xp_display = "DISABLED"
    end
    pfUI.xpbar:UpdateConfig()
  end
  function integration:OpenSettings()
    if pfUI.ShowGUI then pfUI:ShowGUI() end
    local parent = pfUI.gui and pfUI.gui.frames[T["XP Bar"]]
    if parent then parent:Click(); if parent[T["Experience Bar"]] then parent[T["Experience Bar"]]:Click() end end
  end
  function integration:Sync(enabled)
    local legacy = Automaton and Automaton.modules and Automaton.modules.ExpBar
    if not legacy or not legacy.db or not legacy._options then return false end
    local config = C.panel.xp
    if enabled then
      local refresh
      if config.xp_fusion_imported ~= "1" then
        local bridge = AutomatonPfUIBridge
        local wanted
        if bridge and bridge.SavedActive then wanted = bridge:SavedActive("ExpBar")
        else wanted = Automaton:IsModuleActive("ExpBar") end
        config.xp_fusion_before_display = config.xp_display
        if config.xp_display == "DISABLED" and wanted then
          config.xp_fusion_promoted = "1"
          config.xp_fusion_managed_display = "XPFLEX"
          config.xp_fusion_released = "1"
        end
        config.xp_fusion_imported = "1"
      end
      self.active = true
      legacy:OnDisable()
      if config.xp_fusion_released == "1" then
        -- Preserve native display edits made while using independent mode.
        if config.xp_display ~= config.xp_fusion_before_display then
          config.xp_fusion_before_display = config.xp_display
          config.xp_fusion_managed_display = config.xp_display
        end
        config.xp_display = config.xp_fusion_managed_display or "XPFLEX"
        config.xp_fusion_released = nil
        refresh = true
      end
      if refresh then pfUI.xpbar:UpdateConfig() end
    elseif self.active then
      if config.xp_fusion_promoted == "1" then
        config.xp_fusion_managed_display = config.xp_display
        config.xp_display = config.xp_fusion_before_display or "DISABLED"
        config.xp_fusion_released = "1"
        pfUI.xpbar:UpdateConfig()
      end
      self.active = nil
      if Automaton:IsModuleActive("ExpBar") then legacy:OnEnable() end
    end
    return true
  end
  pfUI.xpbar:UpdateConfig()
end)