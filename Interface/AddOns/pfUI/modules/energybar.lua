-- 独立能量条：参考 RogueTicker 的能量条样式
-- Derived from the October 29 package's resource display: textured fill,
-- resource values and CastingBar spark. Saved movable positions take priority.
-- Personal integration: independent display only. The existing energytick owns
-- the regeneration model; this module never moves or reconfigures other frames.
pfUI:RegisterModule("energybar", "vanilla:tbc", function()
  local module = {}
  pfUI.energybar = module

  local UPDATE_INTERVAL = 0.02
  local MANA_INTERVAL = 0.10
  local SMOOTH_TIME = 0.15
  local FADE_TIME = 0.20
  local DEFAULT_WIDTH = 214.5
  local DEFAULT_TEXTURE = "Interface\\AddOns\\pfUI-CustomMedia\\bars\\pfUI-F.tga"
  local frame, driver
  local enabled = false
  local elapsedTotal = 0
  local cfg = {}
  local state = { initialized = false, alpha = 1, idle = 0, manaAge = MANA_INTERVAL }

  local function Number(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return fallback end
    return n
  end

  local function Color(value, r, g, b, a)
    if type(value) == "string" then
      local _, _, cr, cg, cb, ca = string.find(value, "^([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+)$")
      if cr then return { Number(cr, r), Number(cg, g), Number(cb, b), Number(ca, a) } end
    end
    return { r, g, b, a }
  end

  local function Show(object, visible)
    if visible then
      if not object:IsShown() then object:Show() end
    elseif object:IsShown() then
      object:Hide()
    end
  end

  local function SetText(object, value)
    if object.energyText ~= value then
      object:SetText(value)
      object.energyText = value
    end
  end

  local function SetWidth(object, value)
    if object.energyWidth == nil or math.abs(object.energyWidth - value) > 0.001 then
      object:SetWidth(value)
      object.energyWidth = value
    end
  end

  local function SetAlpha(object, value)
    if object.energyAlpha ~= value then
      object:SetAlpha(value)
      object.energyAlpha = value
    end
  end

  local function Font(object, size)
    -- Creation always supplies a valid template before any SetText, including
    -- empty/hidden text. A rejected configurable file keeps a built-in font.
    local ok, accepted = false, nil
    if type(pfUI.font_default) == "string" then
      ok, accepted = pcall(object.SetFont, object, pfUI.font_default, size, "OUTLINE")
    end
    if not ok or not accepted then
      object:SetFontObject(GameFontNormalSmall or "GameFontNormalSmall")
      if object.GetFont then
        local file = object:GetFont()
        if file then pcall(object.SetFont, object, file, size, "OUTLINE") end
      end
    end
  end

  local function ValueText(value, maximum)
    if not cfg.showText then return "" end
    if cfg.textFormat == 1 then
      return string.format("%d/%d", math.floor(value + 0.5), math.floor(maximum + 0.5))
    elseif cfg.textFormat == 2 then
      return string.format("%d%%", math.floor(value / maximum * 100 + 0.5))
    end
    return string.format("%d", math.floor(value + 0.5))
  end

  local function Paint(texture, color)
    if cfg.texture == "solid" or cfg.texture == "" then
      texture:SetTexture(color[1], color[2], color[3], color[4])
      texture:SetVertexColor(1, 1, 1, 1)
    else
      texture:SetTexture(cfg.texture)
      texture:SetVertexColor(color[1], color[2], color[3], color[4])
    end
  end

  -- Automatic colors belong to the resource, not the avatar theme. Prefer
  -- the client's numeric power palette and retain explicit classic fallbacks.
  local POWER_COLORS = {
    [0] = { 0, 0, 1, 1 }, -- mana
    [1] = { 1, 0, 0, 1 }, -- rage
    [2] = { 1, 0.5, 0.25, 1 }, -- focus
    [3] = { 1, 1, 0, 1 }, -- energy
    [4] = { 0, 1, 1, 1 }, -- happiness
  }

  local function PowerColor(powerType)
    local fallback = POWER_COLORS[powerType] or POWER_COLORS[0]
    local palette = ManaBarColor or PowerBarColor
    local color = type(palette) == "table" and palette[powerType]
    if type(color) ~= "table" then return fallback end
    return {
      math.max(0, math.min(1, Number(color.r, fallback[1]))),
      math.max(0, math.min(1, Number(color.g, fallback[2]))),
      math.max(0, math.min(1, Number(color.b, fallback[3]))), 1,
    }
  end

  local function PaintPower(powerType)
    Paint(frame.fill, cfg.autoColor and PowerColor(powerType or 0) or cfg.color)
  end

  local function TextAnchor(object, owner)
    -- An explicit line box and MIDDLE alignment avoid inheriting template
    -- baselines. Extra height prevents clipping when the font exceeds the bar.
    object:SetWidth(math.max(1, owner:GetWidth() - 10))
    object:SetHeight(math.max(owner:GetHeight(), cfg.fontSize + 4))
    object:SetJustifyV("MIDDLE")
    object:ClearAllPoints()
    if cfg.textAlign == "left" then
      object:SetJustifyH("LEFT")
      object:SetPoint("LEFT", owner, "LEFT", 5, 0)
    elseif cfg.textAlign == "right" then
      object:SetJustifyH("RIGHT")
      object:SetPoint("RIGHT", owner, "RIGHT", -5, 0)
    else
      object:SetJustifyH("CENTER")
      object:SetPoint("CENTER", owner, "CENTER", 0, 0)
    end
  end

  local function Geometry()
    frame:SetWidth(cfg.width)
    frame:SetHeight(cfg.height)
    frame.fill:SetHeight(cfg.height)
    frame.spark:SetHeight(cfg.height + 8)
    frame.spark:SetWidth(cfg.height + 4)
    frame.sparkcore:SetHeight(cfg.height)
    frame.manaBar:SetWidth(cfg.width)
    frame.manaBar:SetHeight(cfg.manaHeight)
    frame.manaBar.fill:SetHeight(cfg.manaHeight)
    -- Refresh this frame's default before capturing posdata. The movable API
    -- then reapplies a saved position, if present; clearing that saved entry
    -- can still restore the current defaults, including GUI offset changes.
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", cfg.offx, cfg.offy)
    frame.fill.energyWidth = nil
    frame.manaBar.fill.energyWidth = nil
  end

  local function Style()
    frame.bg:SetTexture(cfg.background[1], cfg.background[2], cfg.background[3], cfg.background[4])
    for i = 1, table.getn(frame.edges) do Show(frame.edges[i], cfg.border) end
    Font(frame.text, cfg.fontSize)
    Font(frame.manaBar.text, math.max(6, cfg.fontSize - 2))
    frame.text:SetTextColor(cfg.textColor[1], cfg.textColor[2], cfg.textColor[3], cfg.textColor[4])
    frame.manaBar.text:SetTextColor(1, 1, 1, 1)
    TextAnchor(frame.text, frame)
    TextAnchor(frame.manaBar.text, frame.manaBar)
    PaintPower(state.powerType)
    Paint(frame.manaBar.fill, PowerColor(0))
    Show(frame.text, cfg.showText)
    Show(frame.manaBar.text, cfg.showText)
    if not cfg.showTick then Show(frame.tick, false) end
    if not cfg.druidMana then Show(frame.manaBar, false) end
    frame.text.energyText, frame.manaBar.text.energyText = nil, nil
  end

  local function CreateBar()
    frame = CreateFrame("Frame", "pfEnergyBar", UIParent)
    module.frame = frame
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(false)
    frame:Hide()
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.fill = frame:CreateTexture(nil, "ARTWORK")
    frame.fill:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.edges = {}
    for i = 1, 4 do
      local edge = frame:CreateTexture(nil, "OVERLAY")
      edge:SetTexture(0, 0, 0, 0.8)
      if i == 1 then
        edge:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
        edge:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
        edge:SetHeight(1)
      elseif i == 2 then
        edge:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
        edge:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
        edge:SetHeight(1)
      elseif i == 3 then
        edge:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
        edge:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
        edge:SetWidth(1)
      else
        edge:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
        edge:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
        edge:SetWidth(1)
      end
      frame.edges[i] = edge
    end
    frame.tick = CreateFrame("Frame", nil, frame)
    frame.tick:SetAllPoints(frame)
    frame.tick:Hide()
    frame.spark = frame.tick:CreateTexture(nil, "OVERLAY")
    frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    frame.spark:SetBlendMode("ADD")
    frame.sparkcore = frame.tick:CreateTexture(nil, "OVERLAY")
    frame.sparkcore:SetTexture(1, 1, 1, 1)
    frame.sparkcore:SetWidth(2)
    frame.sparkcore:SetPoint("CENTER", frame.spark, "CENTER", 0, 0)
    frame.sparkcore:SetBlendMode("ADD")
    frame.manaBar = CreateFrame("Frame", nil, frame)
    frame.manaBar:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    frame.manaBar:Hide()
    frame.manaBar.bg = frame.manaBar:CreateTexture(nil, "BACKGROUND")
    frame.manaBar.bg:SetAllPoints(frame.manaBar)
    frame.manaBar.bg:SetTexture(0, 0, 0, 0.4)
    frame.manaBar.fill = frame.manaBar:CreateTexture(nil, "ARTWORK")
    frame.manaBar.fill:SetPoint("LEFT", frame.manaBar, "LEFT", 0, 0)
    frame.manaBar.text = frame.manaBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  end

  local function Druid()
    local name, token = UnitClass("player")
    local loc = pfUI_locale and pfUI_locale[GetLocale()]
    if loc and loc.class and name and loc.class[name] then token = loc.class[name] end
    return token == "DRUID" or name == "DRUID"
  end

  local function Mana(delta, powerType, width)
    local mbar = frame.manaBar
    if not cfg.druidMana or not cfg.isDruid or powerType == 0 or type(GetUnitField) ~= "function" then
      Show(mbar, false)
      state.manaAge = MANA_INTERVAL
      return
    end
    state.manaAge = state.manaAge + delta
    if state.manaAge < MANA_INTERVAL then return end
    state.manaAge = 0
    local _, guid = UnitExists("player")
    local ok, value, maxok, maximum
    if guid then
      ok, value = pcall(GetUnitField, guid, "power1")
      maxok, maximum = pcall(GetUnitField, guid, "maxPower1")
    end
    if not ok or not maxok or type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
      Show(mbar, false)
      return
    end
    value = math.max(0, math.min(value, maximum))
    SetWidth(mbar.fill, width * value / maximum)
    SetText(mbar.text, ValueText(value, maximum))
    Show(mbar, true)
  end

  local function Update(delta)
    local rawType = UnitPowerType("player")
    local powerType = Number(rawType, 0)
    if not cfg.allPower and powerType ~= 3 then
      Show(frame, false)
      Show(frame.tick, false)
      Show(frame.manaBar, false)
      state.initialized = false
      state.alpha, state.idle = 1, 0
      return
    end
    local rawValue = UnitMana("player")
    local rawMaximum = UnitManaMax("player")
    local maximum = math.max(1, Number(rawMaximum, 1))
    local value = math.max(0, math.min(Number(rawValue, 0), maximum))
    local changed = not state.initialized or value ~= state.value
    local reset = not state.initialized or state.powerType ~= powerType or state.maximum ~= maximum
    if reset then
      state.displayed, state.from, state.target, state.smoothElapsed = value, value, value, SMOOTH_TIME
      state.manaAge = MANA_INTERVAL
      PaintPower(powerType)
    elseif value ~= state.target then
      state.from, state.target, state.smoothElapsed = state.displayed, value, 0
    end
    if not cfg.smooth then
      state.displayed = value
    elseif state.smoothElapsed < SMOOTH_TIME then
      state.smoothElapsed = math.min(SMOOTH_TIME, state.smoothElapsed + delta)
      state.displayed = state.from + (state.target - state.from) * state.smoothElapsed / SMOOTH_TIME
    end
    state.initialized, state.powerType, state.maximum, state.value = true, powerType, maximum, value
    Show(frame, true)
    local width = frame:GetWidth()
    SetWidth(frame.fill, width * state.displayed / maximum)
    local label = ValueText(value, maximum)
    SetText(frame.text, label)
    Mana(delta, powerType, width)

    local preview = pfUI.unlock and pfUI.unlock:IsShown()
    local alpha = 1
    if cfg.autoHide and not preview then
      local combat = cfg.showCombat and UnitAffectingCombat("player")
      if changed or reset or combat or (value >= maximum and not cfg.hideFull) then
        state.idle = 0
      else
        state.idle = state.idle + delta
        if state.idle >= cfg.hideTime then alpha = 0 end
      end
    else
      state.idle = 0
    end
    if preview then
      state.alpha = 1
    elseif state.alpha < alpha then
      state.alpha = math.min(alpha, state.alpha + delta / FADE_TIME)
    elseif state.alpha > alpha then
      state.alpha = math.max(alpha, state.alpha - delta / FADE_TIME)
    end
    SetAlpha(frame, state.alpha)

    local progress
    local provider = pfUI.energytick
    if cfg.showTick and powerType == 3 and provider and type(provider.EnergyProgress) == "function" then
      local ok, result = pcall(provider.EnergyProgress, provider)
      if ok and type(result) == "number" and result == result and result >= 0 and result <= 1 then
        progress = result
      end
    end
    if progress ~= nil then
      if state.progress ~= progress or state.sparkWidth ~= width then
        frame.spark:SetPoint("LEFT", frame.tick, "LEFT", width * progress - (cfg.height + 4) / 2, 0)
        state.progress, state.sparkWidth = progress, width
      end
      Show(frame.tick, true)
    else
      state.progress = nil
      Show(frame.tick, false)
    end
  end

  local function OnUpdate(elapsed)
    if not enabled then return end
    local delta = type(elapsed) == "number" and elapsed or (type(arg1) == "number" and arg1 or 0)
    if delta <= 0 then return end
    elapsedTotal = elapsedTotal + delta
    if elapsedTotal + 0.000001 < UPDATE_INTERVAL then return end
    delta, elapsedTotal = elapsedTotal, 0
    Update(delta)
  end

  function module:RefreshLayout()
    if not enabled or not frame then return end
    Geometry()
    UpdateMovable(frame, true)
  end

  function module:UpdateConfig()
    local settings = C and C.unitframes or {}
    enabled = settings.comboenergyshow == "1"
    elapsedTotal = 0
    if not enabled then
      if driver then driver:SetScript("OnUpdate", nil); driver:Hide() end
      if frame then frame:Hide() end
      state.initialized = false
      return
    end
    cfg.width = Number(settings.comboenergywidth, DEFAULT_WIDTH)
    if cfg.width <= 0 then cfg.width = DEFAULT_WIDTH end
    cfg.height = math.max(4, Number(settings.comboenergyheight, 12))
    cfg.offx = Number(settings.comboenergyoffx, 0)
    cfg.offy = Number(settings.comboenergyoffy, 278)
    cfg.fontSize = math.max(6, Number(settings.comboenergyfontsize, 12))
    cfg.showText = settings.comboenergyshowtext ~= "0"
    cfg.showTick = settings.comboenergyshowtick ~= "0"
    cfg.allPower = settings.comboenergyallpower ~= "0"
    cfg.autoColor = settings.comboenergyautocolor ~= "0"
    cfg.border = settings.comboenergyborder ~= "0"
    cfg.smooth = settings.comboenergysmooth ~= "0"
    cfg.texture = settings.comboenergytexture or DEFAULT_TEXTURE
    cfg.textFormat = Number(settings.comboenergytextformat, 0)
    cfg.textAlign = settings.comboenergytextalign or "center"
    cfg.color = Color(settings.comboenergycolor, 0.8, 0.77, 0.33, 1)
    cfg.background = Color(settings.comboenergybgcolor, 0, 0, 0, 0.4)
    cfg.textColor = Color(settings.comboenergytextcolor, 1, 1, 1, 1)
    cfg.druidMana = settings.comboenergydruidmana == "1"
    cfg.manaHeight = math.max(2, Number(settings.comboenergydruidmanaheight, 6))
    cfg.isDruid = cfg.druidMana and Druid() or false
    cfg.autoHide = settings.comboenergyauthide == "1"
    cfg.hideTime = math.max(0, Number(settings.comboenergyhidetime, 3))
    cfg.showCombat = settings.comboenergyhidecombat ~= "0"
    cfg.hideFull = settings.comboenergyhidefull == "1"
    if not frame then CreateBar() end
    Geometry()
    Style()
    UpdateMovable(frame, true)
    state.initialized, state.idle, state.alpha, state.manaAge = false, 0, 1, MANA_INTERVAL
    state.progress, state.sparkWidth = nil, nil
    SetAlpha(frame, 1)
    if not driver then
      driver = CreateFrame("Frame")
      module.driver = driver
      driver:RegisterEvent("PLAYER_ENTERING_WORLD")
      driver:SetScript("OnEvent", function()
        if enabled then state.initialized = false; state.manaAge = MANA_INTERVAL end
      end)
    end
    driver:SetScript("OnUpdate", OnUpdate)
    driver:Show()
  end

  module:UpdateConfig()
end)
