-- ExtraResourceBars compatibility display for pfUI.
-- Original addon: Fiur#8658. Personal integration keeps the original settings
-- and Shift-drag workflow; the independent addon and its saved data are retained.
pfUI:RegisterModule("resourcebars", "vanilla:tbc", function()
  local module = { frames = {}, warnings = {} }
  pfUI.resourcebars = module
  local active, prepared, pendingImport = false, false, false
  local leases, command, driver = {}, nil, nil
  local age, dirty = 0, true
  local booting, waitingWorld = true, false
  local MEDIA = "Interface\\AddOns\\pfUI\\img\\resourcebars\\"
  local keys = { "erb_hp", "erb_pp" }
  local names = { erb_hp = "pfERBHealth", erb_pp = "pfERBPower" }
  local eventNames = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_MANA", "UNIT_MAXMANA",
    "UNIT_RAGE", "UNIT_MAXRAGE", "UNIT_ENERGY", "UNIT_MAXENERGY", "UNIT_FOCUS",
    "UNIT_MAXFOCUS", "UNIT_DISPLAYPOWER", "UNIT_AURA", "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "ADDON_LOADED" }

  local function DB()
    C.resourcebars = C.resourcebars or {}
    return C.resourcebars
  end

  local function Number(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return fallback end
    return n
  end

  local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end
  local function Flag(value) return value == true or value == 1 or value == "1" end
  module.IsEnabledValue = Flag

  -- Only saved-data values cross the boundary. Frame tables, functions, userdata
  -- and cycles never enter the character's new settings.
  local function Copy(value, seen, depth)
    local kind = type(value)
    if kind == "string" or kind == "boolean" then return value end
    if kind == "number" then return Number(value, nil) end
    if kind ~= "table" or value.GetObjectType or (depth or 0) > 16 then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local result = {}
    for k, v in pairs(value) do
      if k ~= "frame" and (type(k) == "string" or type(k) == "number") then
        result[k] = Copy(v, seen, (depth or 0) + 1)
      end
    end
    seen[value] = nil
    return result
  end
  module.CopyData = Copy

  function module:Defaults()
    return {
      erb_hp = { hide = false, barResize = "LEFT", width = 124, height = 21,
        color = {0, 1, 0, 1}, fontSize = 10, font = "Fonts\\FZJZJW.ttf",
        textType = 3, textAlign = "CENTER", gradiantHP = true, spacing = 0,
        bar = 4, border = 3, background = true, backgroundColor = {0, 0, 0, .35},
        type = 1, only_combat = false, hide_when_full = false, moveable = true,
        fade_in_time = .2, fade_out_time = .2 },
      erb_pp = { hide = false, barResize = "LEFT", width = 124, height = 21,
        powers = {mana = {.2, .2, 1, 1}, rage = {1, 0, 0, 1}, energy = {1, 1, 0, 1}, main = "mana"},
        fontSize = 10, font = "Fonts\\FZJZJW.ttf", textType = 1, textAlign = "CENTER",
        under = "erb_hp", spacing = 1, bar = 4, border = 3, background = true,
        backgroundColor = {0, 0, 0, .45}, type = 2, only_combat = false,
        hide_when_full = false, moveable = true, fade_in_time = .2, fade_out_time = .2 }
    }
  end

  local function Warn(key, message)
    if module.warnings[key] == message then return end
    module.warnings[key], module.lastWarning = message, message
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
      DEFAULT_CHAT_FRAME:AddMessage("pfUI 资源条：" .. message)
    end
  end

  function module:Notify(message)
    self.lastMessage = message
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage("pfUI 资源条：" .. message) end
  end

  local function Color(value, fallback)
    local result = {}
    for i = 1, 4 do result[i] = Clamp(Number(type(value) == "table" and value[i], fallback[i] or 1), 0, 1) end
    return result
  end

  local function Options(key)
    local result = module:Defaults()[key]
    local saved = DB().data and DB().data[key]
    if type(saved) == "table" then
      result.under = nil
      for k, v in pairs(saved) do if k ~= "frame" then result[k] = Copy(v) end end
    end
    result.type = key == "erb_hp" and 1 or 2
    result.width = Clamp(Number(result.width, 124), 8, 4000)
    result.height = Clamp(Number(result.height, 21), 6, 500)
    result.fontSize = Clamp(Number(result.fontSize, 10), 1, 128)
    result.font = type(result.font) == "string" and result.font or "Fonts\\FZJZJW.ttf"
    result.textType = math.floor(Clamp(Number(result.textType, 1), 0, 4))
    result.bar = math.floor(Clamp(Number(result.bar, 4), 0, 35))
    result.border = math.floor(Clamp(Number(result.border, 3), 0, 4))
    result.spacing = Clamp(Number(result.spacing, 0), -4000, 4000)
    result.fade_in_time = Clamp(Number(result.fade_in_time, .2), 0, 60)
    result.fade_out_time = Clamp(Number(result.fade_out_time, .2), 0, 60)
    if result.barResize ~= "LEFT" and result.barResize ~= "RIGHT" then result.barResize = "CENTER" end
    if result.textAlign ~= "LEFT" and result.textAlign ~= "RIGHT" then result.textAlign = "CENTER" end
    for _, k in ipairs({"hide", "background", "only_combat", "hide_when_full", "gradiantHP"}) do result[k] = Flag(result[k]) end
    result.moveable = result.moveable == nil or Flag(result.moveable)
    if result.under == "" or result.under == "nil" or type(result.under) ~= "string" then result.under = nil end
    result.color = Color(result.color, {0, 1, 0, 1})
    result.backgroundColor = Color(result.backgroundColor, {0, 0, 0, .35})
    result.powers = type(result.powers) == "table" and result.powers or {}
    result.powers.mana = Color(result.powers.mana, {.2, .2, 1, 1})
    result.powers.rage = Color(result.powers.rage, {1, 0, 0, 1})
    result.powers.energy = Color(result.powers.energy, {1, 1, 0, 1})
    return result
  end

  local function Font(text, file, size)
    local ok, accepted = pcall(text.SetFont, text, file, size, "OUTLINE")
    if not ok or not accepted then
      text:SetFontObject(GameFontNormalSmall or "GameFontNormalSmall")
      local fallback = text.GetFont and text:GetFont()
      if fallback then pcall(text.SetFont, text, fallback, size, "OUTLINE") end
    end
  end
  module.SetSafeFont = Font

  local function SetVisible(frame, show)
    if show and not frame:IsShown() then frame:Show()
    elseif not show and frame:IsShown() then frame:Hide() end
  end

  local function SetText(text, value)
    if text.resourceText ~= value then text:SetText(value); text.resourceText = value end
  end

  local function SetAlpha(frame, value)
    if frame.resourceAlpha ~= value then frame:SetAlpha(value); frame.resourceAlpha = value end
  end

  local function CapturePosition(frame)
    if not frame then return nil end
    local scale = Number(frame:GetScale(), 1)
    if frame.GetEffectiveScale and UIParent.GetEffectiveScale then
      local parentScale = Number(UIParent:GetEffectiveScale(), 1)
      if parentScale > 0 then scale = Number(frame:GetEffectiveScale(), scale) / parentScale end
    end
    if frame.GetCenter then
      local ok, x, y = pcall(frame.GetCenter, frame)
      x, y = Number(x, nil), Number(y, nil)
      if ok and x and y then
        return {point = "CENTER", relative = "UIParent", relativePoint = "BOTTOMLEFT", x = x, y = y, scale = scale}
      end
    end
    if frame.GetPoint then
      local ok, point, relative, relativePoint, x, y = pcall(frame.GetPoint, frame, 1)
      if type(relative) == "number" and type(relativePoint) == "number" then
        x, y, relative, relativePoint = relative, relativePoint, nil, point
      elseif type(relative) == "string" and type(relativePoint) == "number" then
        x, y, relative, relativePoint = relativePoint, x, nil, relative
      end
      local kind = type(relative)
      local relativeName = kind == "string" and relative or
        (kind == "table" or kind == "userdata") and relative.GetName and relative:GetName()
      if ok and point and (relative == nil or relativeName) then
        return {point = point, relative = relativeName or "UIParent", relativePoint = relativePoint or point,
          x = Number(x, 0), y = Number(y, 0), scale = scale}
      end
    end
  end

  function module:ImportLegacy()
    if type(DB().data) == "table" then
      local message = "已有内置设置，未重复导入，以保留内置修改。"
      self:Notify(message)
      return false, message
    end
    if type(_G.ERB_options) ~= "table" then
      local message = "原版设置尚未载入；未导入。"
      self:Notify(message)
      return false, message
    end
    if _G.erb_dummy_frame and _G.erb_hp and not _G.erb_hp:GetScript("OnEvent") and not leases.erb_hp then
      local message = "原版尚未完成进入世界时的设置载入；请稍后导入。"
      self:Notify(message)
      return false, message
    end
    local data, positions = {}, {}
    for _, key in ipairs(keys) do
      data[key] = Copy(_G.ERB_options[key]) or self:Defaults()[key]
      positions[key] = CapturePosition(_G[key])
      if not positions[key] then Warn("import_" .. key, "未取得原版 " .. key .. " 的实时位置，保留现有内置位置。") end
    end
    local db = DB()
    db.data = data
    db.positions = db.positions or {}
    for key, position in pairs(positions) do db.positions[key] = position end
    db.imported = "1"
    local message = "已复制原版设置和可用的实时位置；原版数据未改动。"
    self:Notify(message)
    return true, message
  end

  local function OwnKey(name)
    if name == "erb_hp" or name == "pfERBHealth" then return "erb_hp" end
    if name == "erb_pp" or name == "pfERBPower" then return "erb_pp" end
  end

  local function Cyclic(key, seen)
    if seen[key] then return true end
    seen[key] = true
    local nextKey = OwnKey(module.options[key].under)
    if nextKey and Cyclic(nextKey, seen) then return true end
    seen[key] = nil
    return false
  end

  local function Position(frame, key, option)
    local saved = DB().positions and DB().positions[key]
    frame:SetScale(Clamp(Number(saved and saved.scale, 1), .05, 5))
    frame:ClearAllPoints()
    if option.under then
      local target = module.frames[OwnKey(option.under)] or _G[option.under]
      if Cyclic(key, {}) then
        Warn("anchor_" .. key, key .. " 的依附形成循环，已使用自身保存位置。")
      elseif (type(target) == "table" or type(target) == "userdata") and target ~= frame and target.GetPoint then
        frame:SetPoint("CENTER", target, "CENTER", 0, -(option.height + option.spacing))
        frame.resourceDocked = true
        return
      else
        Warn("anchor_" .. key, key .. " 的依附目标不存在，已使用自身保存位置。")
      end
    end
    frame.resourceDocked = false
    if type(saved) == "table" then
      local relative = module.frames[OwnKey(saved.relative)] or _G[saved.relative or "UIParent"]
      if (type(relative) == "table" or type(relative) == "userdata") and relative ~= frame and relative.GetPoint then
        local ok = pcall(frame.SetPoint, frame, saved.point or "CENTER", relative,
          saved.relativePoint or "CENTER", Number(saved.x, 0), Number(saved.y, 0))
        if ok then return end
      end
    end
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, key == "erb_hp" and 0 or -25)
  end

  local function CreateBar(key)
    local frame = CreateFrame("Frame", names[key], UIParent)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("MEDIUM")
    frame.background = CreateFrame("Frame", nil, frame)
    frame.background:SetFrameLevel(frame:GetFrameLevel())
    frame.background:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
    frame.bar = frame:CreateTexture(nil, "ARTWORK")
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.text:SetFontObject(GameFontNormalSmall or "GameFontNormalSmall")
    frame:SetScript("OnDragStart", function()
      local option = module.options[key]
      if active and option.moveable and not this.resourceDocked and IsShiftKeyDown() then this:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function()
      this:StopMovingOrSizing()
      if active and not this.resourceDocked then
        DB().positions = DB().positions or {}
        DB().positions[key] = CapturePosition(this)
      end
    end)
    frame:SetScript("OnEnter", function()
      if GameTooltip then
        GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
        GameTooltip:SetText(this.resourceDocked and "依附条：先清空下方对齐目标再移动" or "按住 Shift 拖动")
        GameTooltip:Show()
      end
    end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    frame.resourceState = {alpha = 1}
    module.frames[key] = frame
    module[key == "erb_hp" and "health" or "power"] = frame
    return frame
  end

  local borderFiles = { [1] = "Interface\\Tooltips\\UI-Tooltip-Border",
    [2] = "Interface\\DialogFrame\\UI-DialogBox-Border", [3] = "Interface\\Glues\\Common\\TextPanel-Border",
    [4] = MEDIA .. "border" }

  local function ApplySettings()
    module.options = {erb_hp = Options("erb_hp"), erb_pp = Options("erb_pp")}
    for _, key in ipairs(keys) do if not module.frames[key] then CreateBar(key) end end
    for _, key in ipairs(keys) do
      local frame, option = module.frames[key], module.options[key]
      frame:SetWidth(option.width)
      frame:SetHeight(option.height)
      Position(frame, key, option)
      frame:EnableMouse(option.moveable and not frame.resourceDocked)
      frame:SetBackdrop({edgeFile = borderFiles[option.border] or "", edgeSize = option.border == 4 and 1.5 or 14})
      frame:SetBackdropBorderColor(option.border == 4 and 0 or 1, option.border == 4 and 0 or 1,
        option.border == 4 and 0 or 1, 1)
      frame.background:ClearAllPoints()
      frame.background:SetPoint("CENTER", frame, "CENTER", 0, 0)
      frame.background:SetWidth(math.max(.001, option.width - 4 + (option.border == 4 and 4 or 0) + (option.border == 0 and -2 or 0)))
      frame.background:SetHeight(math.max(.001, option.height - 5 + (option.border == 4 and 5 or 0) + (option.border == 0 and 2 or 0)))
      frame.background:SetBackdropColor(unpack(option.backgroundColor))
      SetVisible(frame.background, option.background)
      frame.bar:ClearAllPoints()
      local offset = 4 + (option.border == 4 and -2.5 or 0)
      frame.bar:SetPoint(option.barResize, frame, option.barResize,
        option.barResize == "LEFT" and offset or option.barResize == "RIGHT" and -offset or 0, 0)
      frame.bar:SetTexture(MEDIA .. "bar_" .. option.bar)
      SetVisible(frame.bar, option.bar ~= 0)
      frame.bar:SetHeight(math.max(.001, option.height - 5 + (option.border == 4 and 3 or 0)))
      Font(frame.text, option.font, option.fontSize)
      frame.text:ClearAllPoints()
      frame.text:SetPoint(option.textAlign, frame, option.textAlign,
        option.textAlign == "LEFT" and 5 or option.textAlign == "RIGHT" and -5 or 0, 0)
      frame.text:SetJustifyH(option.textAlign)
      frame.text:SetWidth(math.max(1, option.width - 10))
      frame.text:SetHeight(math.max(option.height, option.fontSize + 4))
      frame.text:SetJustifyV("MIDDLE")
      frame.resourceState.alpha = 1
      frame.resourceState.target = nil
      SetAlpha(frame, 1)
      frame.resourceColor = nil
      frame.resourceWidth = nil
    end
    dirty = true
  end

  local function ValueText(value, maximum, style)
    if style == 0 then return "" end
    local current = string.format("%.0f", value)
    if style == 1 then return current end
    local percent = string.format("%.0f%%", maximum > 0 and value / maximum * 100 or 0)
    if style == 2 then return percent end
    local fraction = current .. " / " .. string.format("%.0f", maximum)
    return style == 3 and fraction .. "  " .. percent or percent .. "  " .. fraction
  end

  local function Paint(frame, color)
    local old = frame.resourceColor
    if not old or old[1] ~= color[1] or old[2] ~= color[2] or old[3] ~= color[3] or old[4] ~= color[4] then
      frame.bar:SetVertexColor(unpack(color))
      frame.resourceColor = color
    end
  end

  local function RefreshValues()
    local fighting = UnitAffectingCombat("player") and true or false
    local powerType = UnitPowerType("player")
    for _, key in ipairs(keys) do
      local frame, option = module.frames[key], module.options[key]
      local state = frame.resourceState
      if option.hide then
        state.target = 0
        state.alpha = 0
        SetAlpha(frame, 0)
        SetVisible(frame, false)
      else
        local value = key == "erb_hp" and UnitHealth("player") or UnitMana("player")
        local maximum = key == "erb_hp" and UnitHealthMax("player") or UnitManaMax("player")
        value, maximum = math.max(0, Number(value, 0)), math.max(0, Number(maximum, 0))
        local ratio = maximum > 0 and Clamp(value / maximum, 0, 1) or 0
        local width = math.max(.001, option.width - 8 + (option.border == 4 and 5 or 0)) * ratio + .001
        if frame.resourceWidth ~= width then
          frame.bar:SetWidth(width)
          frame.resourceWidth = width
          if option.barResize == "CENTER" then frame.bar:SetTexCoord((1-ratio)/2, (1+ratio)/2, 0, 1)
          elseif option.barResize == "RIGHT" then frame.bar:SetTexCoord(1-ratio, 1, 0, 1)
          else frame.bar:SetTexCoord(0, ratio, 0, 1) end
        end
        SetText(frame.text, ValueText(value, maximum, option.textType))
        local color
        if key == "erb_hp" then
          if option.gradiantHP then color = ratio < .5 and {1, 2*ratio, 0, 1} or {2*(1-ratio), 1, 0, 1}
          else color = option.color end
        else
          if DB().followcolors == nil or Flag(DB().followcolors) then
            local provider = pfUI.api.GetPlayerResourceColor
            if provider then
              local ok, r, g, b, a = pcall(provider, powerType)
              if ok and Number(r, nil) and Number(g, nil) and Number(b, nil) then color = {r, g, b, Number(a, 1)} end
            end
          end
          if not color then
            local kind = powerType == 1 and "rage" or powerType == 3 and "energy" or "mana"
            color = option.powers[kind]
          end
        end
        Paint(frame, color)
        local full = maximum > 0 and value >= maximum or key == "erb_pp" and powerType == 1 and value == 0
        local show = true
        if option.only_combat then
          -- Legacy combination: outside combat, a non-full bar can remain visible
          -- when full hiding is enabled; inside combat it always remains visible.
          show = fighting or option.hide_when_full and not full
        elseif option.hide_when_full then show = not full end
        state.target = show and 1 or 0
      end
    end
  end

  local function Fade(elapsed)
    for _, key in ipairs(keys) do
      local frame, option = module.frames[key], module.options[key]
      local state = frame.resourceState
      local target = state.target or 0
      local duration = target > state.alpha and option.fade_in_time or option.fade_out_time
      if duration == 0 then state.alpha = target
      elseif state.alpha < target then state.alpha = math.min(target, state.alpha + elapsed / duration)
      elseif state.alpha > target then state.alpha = math.max(target, state.alpha - elapsed / duration) end
      SetAlpha(frame, state.alpha)
      SetVisible(frame, state.alpha > 0 and not option.hide)
    end
  end

  local slashHandler = function() module:OpenConfig() end
  local function TakeCommand()
    if _G.SlashCmdList["ERB"] ~= slashHandler then
      command = {handler = _G.SlashCmdList["ERB"], alias = _G.SLASH_ERB1}
      _G.SlashCmdList["ERB"], _G.SLASH_ERB1 = slashHandler, "/erb"
    end
  end

  local function LegacyReady()
    -- The original creates frames before it applies saved settings at first
    -- PLAYER_ENTERING_WORLD. Do not capture that uninitialized intermediate state.
    if _G.erb_dummy_frame and _G.erb_hp and not _G.erb_hp:GetScript("OnEvent") and not leases.erb_hp then return false end
    return true
  end

  local function TakeLease()
    if not LegacyReady() then return false end
    for _, key in ipairs({"erb_hp", "erb_pp", "erb_dummy_frame"}) do
      local frame = _G[key]
      if frame and not leases[key] then
        leases[key] = {frame = frame, onEvent = frame:GetScript("OnEvent"), onUpdate = frame:GetScript("OnUpdate"),
          shown = frame:IsShown(), alpha = frame:GetAlpha(), time = frame.time, fading = frame.fading}
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
      end
    end
    TakeCommand()
    return true
  end

  local function Prepare()
    if waitingWorld then return false end
    if not LegacyReady() then return false end
    if pendingImport then
      if type(DB().data) ~= "table" then
        if type(_G.ERB_options) == "table" then module:ImportLegacy()
        else DB().data = module:Defaults() end
      end
      pendingImport = false
    end
    if not prepared then ApplySettings(); prepared = true end
    if not TakeLease() then return false end
    return true
  end

  local function EnsureDriver()
    if driver then return end
    driver = CreateFrame("Frame", nil, UIParent)
    module.driver = driver
  end

  function module:StartTrial()
    local db = DB()
    if active then self:UpdateConfig(); self:Notify("内置资源条试用已开启。"); return true, "内置资源条试用已开启。" end
    db.enable, active, self.active = "1", true, true
    pendingImport = type(db.data) ~= "table"
    waitingWorld = booting and not (_G.erb_hp and _G.erb_hp:GetScript("OnEvent"))
    EnsureDriver()
    driver:SetScript("OnEvent", function()
      if event == "PLAYER_ENTERING_WORLD" then waitingWorld = false end
      dirty = true
    end)
    for _, eventName in ipairs(eventNames) do driver:RegisterEvent(eventName) end
    driver:SetScript("OnUpdate", function()
      if not active then return end
      local elapsed = math.max(0, Number(arg1, 0))
      age = age + elapsed
      if waitingWorld or not prepared or not LegacyReady() then
        if not Prepare() then return end
        dirty = true
      elseif age >= .1 then TakeLease() end
      if dirty or age >= .1 then RefreshValues(); dirty, age = false, 0 end
      Fade(elapsed)
    end)
    if Prepare() then RefreshValues(); Fade(0) end
    local message = prepared and "内置资源条试用已开启；可随时退出恢复原版。" or "等待进入世界并载入原版设置后开启试用。"
    self:Notify(message)
    return true, message
  end

  function module:StopTrial()
    DB().enable = "0"
    if not active then self:Notify("当前未开启内置试用，原版未改动。"); return true end
    active, prepared, pendingImport, waitingWorld, self.active = false, false, false, false, false
    if driver then driver:SetScript("OnUpdate", nil); driver:SetScript("OnEvent", nil); driver:UnregisterAllEvents() end
    for _, frame in pairs(self.frames) do frame:Hide() end
    for key, saved in pairs(leases) do
      if (key == "erb_hp" or key == "erb_pp") and saved.onEvent then
        -- Refresh the legacy display once: resource events were intentionally
        -- suspended during the trial. Its own renderer knows its text/skin.
        local oldThis, oldEvent, oldArg1 = _G.this, _G.event, _G.arg1
        _G.this, _G.event, _G.arg1 = saved.frame, key == "erb_hp" and "UNIT_HEALTH" or "UNIT_MANA", "player"
        local ok = pcall(saved.onEvent)
        _G.this, _G.event, _G.arg1 = oldThis, oldEvent, oldArg1
        if not ok then Warn("resume_" .. key, "旧版数值未能刷新；重载界面可重新初始化。") end
      end
      saved.frame:SetScript("OnEvent", saved.onEvent)
      saved.frame:SetScript("OnUpdate", saved.onUpdate)
      saved.frame.time, saved.frame.fading = saved.time, saved.fading
      saved.frame:SetAlpha(saved.alpha)
      SetVisible(saved.frame, saved.shown)
      leases[key] = nil
    end
    if command then
      if _G.SlashCmdList["ERB"] == slashHandler then _G.SlashCmdList["ERB"], _G.SLASH_ERB1 = command.handler, command.alias end
      command = nil
    end
    if self.InstallFallbackCommand then self:InstallFallbackCommand() end
    age, dirty = 0, true
    local message = "已退出试用并恢复原版；原版设置未改动。"
    self:Notify(message)
    return true, message
  end

  function module:UpdateConfig()
    if not Flag(DB().enable) then
      if active then self:StopTrial() end
      return
    end
    if not active then self:StartTrial(); return end
    if not Prepare() then return end
    ApplySettings()
    RefreshValues()
    Fade(0)
  end

  function module:OpenConfig()
    if self.BuildConfig then return self:BuildConfig() end
    self.openPending = true
    return false, "设置面板尚未载入。"
  end

  module:UpdateConfig()
  booting = false
end)
