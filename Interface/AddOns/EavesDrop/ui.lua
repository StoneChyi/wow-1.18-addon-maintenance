-- EavesDrop: local pfUI-style surfaces for the 1.12 client.
-- Never reskin the shared Dewdrop/Waterfall libraries or change global fonts.
local BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 8, edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
local rowsPerPage = 8
local panel, reader
local selectedTab, page = 1, 1
local tabs = { "外观", "事件", "颜色", "历史与数据", "配置" }

local function Font(text, size)
  -- SetText(nil) also needs a font in 1.12. Keep a known-valid object even
  -- when a configured/custom font is missing, including hidden controls.
  local r, g, b, a
  if text.GetTextColor then r, g, b, a = text:GetTextColor() end
  text:SetFontObject(GameFontNormal)
  local path = pfUI and pfUI.font_default
  if not path then
    local fallback = text:GetFont()
    path = fallback
  end
  if path then
    local ok, loaded = pcall(text.SetFont, text, path, size or 12, "")
    if not ok or not loaded then text:SetFontObject(GameFontNormal) end
  end
  if r then text:SetTextColor(r, g, b, a or 1) end
end

local function Text(parent, value, size)
  local text = parent:CreateFontString(nil, "OVERLAY")
  Font(text, size)
  text:SetTextColor(.9, .9, .9)
  text:SetText(value or "")
  return text
end

local function Backdrop(frame, r, g, b, a)
  if pfUI and pfUI.api and pfUI.api.CreateBackdrop then
    -- Existing 1.12 pfUI signature: frame, inset, legacy, transparency.
    local ok = pcall(pfUI.api.CreateBackdrop, frame, 1, true, a)
    if not ok then frame:SetBackdrop(BACKDROP) end
  else
    frame:SetBackdrop(BACKDROP)
  end
  frame:SetBackdropColor(r or .04, g or .04, b or .04, a or .9)
  frame:SetBackdropBorderColor(.25, .25, .25, 1)
end

local function Hover(button, hint)
  button.hint = hint
  button:SetScript("OnEnter", function()
    this:SetBackdropBorderColor(.35, .8, .7, 1)
    if this.hint and this.hint ~= "" then
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText(this.hint, 1, 1, 1, 1, 1)
    end
  end)
  button:SetScript("OnLeave", function()
    this:SetBackdropBorderColor(.25, .25, .25, 1)
    GameTooltip:Hide()
  end)
end

local function Button(parent, value, width, height, click)
  local button = CreateFrame("Button", nil, parent)
  button:SetWidth(width or 100)
  button:SetHeight(height or 24)
  Backdrop(button, .08, .08, .08, .95)
  button.caption = Text(button, value, 12)
  button.caption:SetPoint("CENTER", button, "CENTER", 0, 0)
  button:SetScript("OnClick", click)
  Hover(button)
  return button
end

local function SetCaption(button, value)
  button.caption:SetText(value)
end

local function Profile()
  return EavesDrop.db.profile
end

local function UpdateAppearance()
  EavesDrop:PerformDisplayOptions()
  EavesDrop:ApplySkin()
  EavesDrop:UpdateEvents()
end

local function Toggle(key, name, hint, after)
  return { type = "toggle", name = name, desc = hint,
    get = function() return Profile()[key] end,
    set = function(value)
      Profile()[key] = value
      if after then after() end
    end,
  }
end

local function Range(key, name, low, high, step, after)
  return { type = "range", name = name, min = low, max = high, step = step,
    get = function() return Profile()[key] end,
    set = function(value)
      Profile()[key] = value
      if after then after() end
    end,
  }
end

local function SortedOptions(group, result, prefix)
  if not group or not group.args then return end
  local ordered = {}
  for key, option in pairs(group.args) do
    table.insert(ordered, { key = key, option = option })
  end
  table.sort(ordered, function(a, b)
    local ao, bo = a.option.order or 100, b.option.order or 100
    if ao == bo then return a.key < b.key end
    return ao < bo
  end)
  for _, entry in ipairs(ordered) do
    local option = entry.option
    if option.type == "group" then
      SortedOptions(option, result, (prefix or "") .. (option.name or entry.key) .. " / ")
    elseif option.type == "toggle" or option.type == "range" or option.type == "color" or option.type == "execute" then
      table.insert(result, { option = option, prefix = prefix })
    end
  end
end

local function BuildOptions(tab)
  local options, args = {}, EavesDrop.options.args
  local function Add(option) table.insert(options, { option = option }) end
  if tab == 1 then
    Add({ type = "range", name = "战斗窗口 / 历史窗口背景不透明度", min = 0, max = 1, step = .05,
      get = function() return Profile().FRAME.a end,
      set = function(value) Profile().FRAME.a = value; EavesDrop:ApplySkin() end,
    })
    Add(Range("SETTINGALPHA", "设置面板背景不透明度", 0, 1, .05, function() EavesDrop:ApplySkin() end))
    Add({ type = "range", name = "战斗窗口 / 历史窗口边框不透明度", min = 0, max = 1, step = .05,
      get = function() return Profile().BORDER.a or 1 end,
      set = function(value) Profile().BORDER.a = value; EavesDrop:ApplySkin() end,
    })
    Add(Range("SETTINGBORDERALPHA", "设置面板边框不透明度", 0, 1, .05, function() EavesDrop:ApplySkin() end))
    Add(args.lock)
    SortedOptions(args.frame, options)
    -- Keep all the old miscellaneous appearance controls, not only a subset.
    local misc = args.misc.args
    for _, key in ipairs({ "buttons", "details", "timestamp", "flip", "placeholder" }) do Add(misc[key]) end
  elseif tab == 2 then
    SortedOptions(args.events, options)
    Add(args.misc.args.hfilter)
    Add(args.misc.args.mfilter)
  elseif tab == 3 then
    SortedOptions(args.colors, options)
  elseif tab == 4 then
    Add({ type = "selectsource", name = "战斗数据来源",
      desc = "自动：使用可用的 nampower 增强事件；未覆盖的类别保留旧文字日志。旧文字：仅使用兼容解析。",
      get = function() return Profile().DATASOURCE or "auto" end,
      set = function(value) Profile().DATASOURCE = value; EavesDrop:RefreshCombatSources() end,
    })
    Add(Range("HISTORYLIMIT", "本次登录的战斗记录容量", 128, 2048, 128, function() EavesDrop:ResizeHistory() end))
    Add(args.misc.args.history)
    Add({ type = "execute", name = "回到最新战斗记录", func = function() EavesDrop:ScrollToBottom() end })
    Add({ type = "execute", name = "查看最高数值历史", func = function()
      if EavesDrop:IsActive() and Profile().HISTORY then EavesDropHistoryFrame:Show() end
    end, desc = "最高数值历史独立保存；滚轮浏览的是本次登录内的战斗记录。" })
    Add({ type = "status", name = "当前数据状态" })
  else
    Add({ type = "profile", name = "切换或新建配置文件", desc = "输入配置名后点击应用。配置文件沿用现有 AceDB 数据。" })
    Add({ type = "execute", name = "使用默认配置文件", func = function()
      EavesDrop:SetProfile("Default"); EavesDrop:RefreshProfile()
    end })
    Add({ type = "execute", name = "重置当前配置", func = function()
      panel.confirmReset = not panel.confirmReset
      if panel.confirmReset then
        panel.notice:SetText("再次点击“重置当前配置”以确认。最高数值历史不会清除。")
      else
        EavesDrop:Reset(); EavesDrop:RefreshProfile()
      end
    end })
    Add({ type = "execute", name = "原版高级设置 / 配置文件复制", func = function()
      if EavesDrop.OpenLegacySettings then EavesDrop:OpenLegacySettings()
      elseif AceLibrary:HasInstance("Waterfall-1.0") then AceLibrary("Waterfall-1.0"):Open("EavesDrop") end
    end, desc = "保留原版选项与配置文件管理入口，不改变其他插件的菜单。" })
    Add({ type = "status", name = "当前配置文件", profileStatus = true })
  end
  return options
end

local function RefreshAfterSet()
  EavesDrop:ApplySkin()
  EavesDrop:UpdateSettings()
end

local function ChooseColor(option)
  local r, g, b, a = option.get()
  a = a or 1
  local old = { r, g, b, a }
  ColorPickerFrame:Hide()
  ColorPickerFrame.func = nil
  ColorPickerFrame.opacityFunc = nil
  ColorPickerFrame.cancelFunc = nil
  ColorPickerFrame.hasOpacity = option.hasAlpha and true or false
  ColorPickerFrame.opacity = 1 - a
  local function Apply()
    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
    local na = option.hasAlpha and (1 - OpacitySliderFrame:GetValue()) or a
    option.set(nr, ng, nb, na)
    RefreshAfterSet()
  end
  ColorPickerFrame:SetColorRGB(r, g, b)
  if option.hasAlpha then OpacitySliderFrame:SetValue(1 - a) end
  ColorPickerFrame.func = Apply
  ColorPickerFrame.opacityFunc = Apply
  ColorPickerFrame.cancelFunc = function()
    option.set(old[1], old[2], old[3], old[4])
    RefreshAfterSet()
  end
  ColorPickerFrame:Show()
end

local function NewRow(parent, index)
  local row = CreateFrame("Frame", nil, parent)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -114 - (index - 1) * 43)
  row:SetWidth(570); row:SetHeight(39)
  row.label = Text(row, "", 12)
  row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.label:SetWidth(285); row.label:SetHeight(36); row.label:SetJustifyH("LEFT")
  row.action = Button(row, "", 240, 27, function()
    local option = this:GetParent().option
    if not option or this:GetParent().disabled then return end
    if option.type == "toggle" then option.set(not option.get())
    elseif option.type == "color" then ChooseColor(option)
    elseif option.type == "selectsource" then option.set(option.get() == "legacy" and "auto" or "legacy")
    elseif option.type == "execute" then option.func() end
    RefreshAfterSet()
  end)
  row.action:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  row.slider = CreateFrame("Slider", nil, row)
  row.slider:SetPoint("RIGHT", row, "RIGHT", -53, -3)
  row.slider:SetWidth(185); row.slider:SetHeight(16)
  row.slider:SetOrientation("HORIZONTAL")
  Backdrop(row.slider, .06, .06, .06, .95)
  row.slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
  local thumb = row.slider:GetThumbTexture()
  if thumb then thumb:SetWidth(8); thumb:SetHeight(18); thumb:SetVertexColor(.3, .8, .7) end
  row.value = Text(row, "", 12)
  row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  row.value:SetWidth(45); row.value:SetJustifyH("RIGHT")
  row.slider:SetScript("OnValueChanged", function()
    local owner = this:GetParent()
    local option = owner.option
    if panel.refreshing or not option then return end
    local step = option.step or 1
    local value = math.floor((this:GetValue() - option.min) / step + .5) * step + option.min
    value = math.max(option.min, math.min(option.max, value))
    if math.abs((option.get() or 0) - value) > .0001 then option.set(value) end
    if option.max <= 1 then owner.value:SetText(string.format("%d%%", value * 100 + .5))
    else owner.value:SetText(tostring(value)) end
  end)
  row.edit = CreateFrame("EditBox", nil, row)
  row.edit:SetPoint("RIGHT", row, "RIGHT", -73, 0)
  row.edit:SetWidth(165); row.edit:SetHeight(27)
  row.edit:SetFontObject(GameFontNormal)
  row.edit:SetAutoFocus(false)
  row.edit:SetTextInsets(5, 5, 0, 0)
  Backdrop(row.edit, .04, .04, .04, .95)
  row.edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  row.apply = Button(row, "应用", 65, 27, function()
    local edit = this:GetParent().edit
    local name = string.gsub(edit:GetText() or "", "^%s*(.-)%s*$", "%1")
    if name == "" then return end
    EavesDrop:SetProfile(name)
    edit:ClearFocus()
    EavesDrop:RefreshProfile()
    EavesDrop:UpdateSettings()
  end)
  row.apply:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  row.status = Text(row, "", 11)
  row.status:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  row.status:SetWidth(255); row.status:SetHeight(39); row.status:SetJustifyH("LEFT")
  return row
end

local function CreateSettings()
  if panel then return end
  panel = CreateFrame("Frame", "EavesDropSettingsFrame", UIParent)
  panel:Hide()
  panel:SetWidth(610); panel:SetHeight(540)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  panel:SetFrameStrata("DIALOG")
  panel:SetMovable(true); panel:EnableMouse(true); panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function() this:StartMoving() end)
  panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  Backdrop(panel)
  panel.title = Text(panel, "EavesDrop  /  设置", 15)
  panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -17)
  panel.close = Button(panel, "×", 25, 24, function() panel:Hide() end)
  panel.close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
  panel.enabled = Button(panel, "", 125, 24, function()
    EavesDrop:ToggleActive(not EavesDrop:IsActive())
    EavesDrop:UpdateSettings()
  end)
  panel.enabled:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -47, -10)
  Hover(panel.enabled, "停用时停止监视并隐藏战斗窗口；可用 /ed 再次打开设置。")
  panel.nav = {}
  for i, name in ipairs(tabs) do
    local index = i
    local button = Button(panel, name, 108, 27, function()
      selectedTab, page = index, 1
      panel.confirmReset = nil
      EavesDrop:UpdateSettings()
    end)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", 18 + (i - 1) * 116, -55)
    panel.nav[i] = button
  end
  panel.subtitle = Text(panel, "", 11)
  panel.subtitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -91)
  panel.rows = {}
  for i = 1, rowsPerPage do panel.rows[i] = NewRow(panel, i) end
  panel.previous = Button(panel, "上一页", 80, 25, function()
    page = math.max(1, page - 1); EavesDrop:UpdateSettings()
  end)
  panel.previous:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 49)
  panel.next = Button(panel, "下一页", 80, 25, function()
    page = page + 1; EavesDrop:UpdateSettings()
  end)
  panel.next:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 49)
  panel.pageText = Text(panel, "", 11)
  panel.pageText:SetPoint("BOTTOM", panel, "BOTTOM", 0, 56)
  panel.notice = Text(panel, "", 11)
  panel.notice:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 12)
  panel.notice:SetWidth(574); panel.notice:SetHeight(30); panel.notice:SetJustifyH("LEFT")
  if UISpecialFrames then table.insert(UISpecialFrames, "EavesDropSettingsFrame") end
end

function EavesDrop:UpdateSettings()
  if not panel or not self.db or not self.options then return end
  panel.refreshing = true
  local options = BuildOptions(selectedTab)
  local pages = math.max(1, math.ceil(table.getn(options) / rowsPerPage))
  page = math.max(1, math.min(page, pages))
  SetCaption(panel.enabled, self:IsActive() and "监视：已启用" or "监视：已停用")
  panel.enabled.caption:SetTextColor(self:IsActive() and .4 or .9, self:IsActive() and .9 or .45, .6)
  for i, button in ipairs(panel.nav) do
    button:SetBackdropBorderColor(i == selectedTab and .35 or .25, i == selectedTab and .8 or .25, i == selectedTab and .7 or .25, 1)
  end
  panel.subtitle:SetText(selectedTab == 4 and "浏览历史时固定内容；点击窗口底部提示返回最新。" or "修改即时生效，设置随配置文件保存。")
  for i, row in ipairs(panel.rows) do
    local entry = options[(page - 1) * rowsPerPage + i]
    row.action:Hide(); row.slider:Hide(); row.value:Hide(); row.edit:Hide(); row.apply:Hide(); row.status:Hide()
    row.option = entry and entry.option
    if row.option then
      local option = row.option
      row.disabled = option.disabled and (type(option.disabled) == "function" and option.disabled() or option.disabled == true) or false
      row:Show()
      row.label:SetText((entry.prefix or "") .. (option.name or ""))
      row.action.hint = option.desc
      row.action:SetBackdropColor(.08, .08, .08, .95)
      row.action:SetAlpha(row.disabled and .45 or 1)
      row.action:EnableMouse(not row.disabled)
      row.slider:EnableMouse(not row.disabled)
      if option.type == "range" then
        row.slider:Show(); row.value:Show()
        row.slider:SetMinMaxValues(option.min, option.max)
        row.slider:SetValueStep(option.step or 1)
        local value = option.get() or option.min
        row.slider:SetValue(value)
        row.value:SetText(option.max <= 1 and string.format("%d%%", value * 100 + .5) or tostring(value))
      elseif option.type == "profile" then
        row.edit:Show(); row.apply:Show()
        row.edit:SetText(self:GetProfile() or "Default")
      elseif option.type == "status" then
        row.status:Show()
        if option.profileStatus then row.status:SetText(self:GetProfile() or "Default")
        else row.status:SetText(self.GetCombatSourceStatus and self:GetCombatSourceStatus() or "旧文字日志") end
      else
        row.action:Show()
        if option.type == "toggle" then
          SetCaption(row.action, option.get() and "已开启  ✓" or "已关闭")
        elseif option.type == "color" then
          local r, g, b = option.get()
          row.action:SetBackdropColor(r, g, b, .7)
          SetCaption(row.action, "选择颜色")
        elseif option.type == "selectsource" then
          SetCaption(row.action, option.get() == "legacy" and "旧文字日志" or "自动使用增强事件")
        else SetCaption(row.action, "打开 / 执行") end
      end
    else row:Hide() end
  end
  panel.previous:SetAlpha(page > 1 and 1 or .4)
  panel.next:SetAlpha(page < pages and 1 or .4)
  panel.pageText:SetText(string.format("%d / %d", page, pages))
  if not panel.confirmReset then
    panel.notice:SetText("背景与边框不透明度 0% 为透明，100% 为不透明。可通过 /ed 或右键战斗窗口打开设置。")
  end
  panel.refreshing = nil
end

function EavesDrop:OpenSettings()
  CreateSettings()
  self:ApplySkin()
  self:UpdateSettings()
  panel:Show()
end

local function SkinExistingButton(button, isIcon)
  if not button then return end
  Backdrop(button, .06, .06, .06, .85)
  if isIcon then
    local normal = button:GetNormalTexture()
    if normal then normal:SetTexCoord(.1, .9, .1, .9) end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetTexCoord(.1, .9, .1, .9) end
  else
    button:SetNormalTexture(""); button:SetPushedTexture(""); button:SetHighlightTexture("")
  end
  local caption = button.GetFontString and button:GetFontString()
  if caption then Font(caption, 11) end
end

function EavesDrop:ApplySkin()
  if not self.db then return end
  local profile = self.db.profile
  local color = profile.FRAME
  for _, frame in ipairs({ EavesDropFrame, EavesDropHistoryFrame }) do
    if frame then
      Backdrop(frame, color.r, color.g, color.b, color.a)
      local border = profile.BORDER
      frame:SetBackdropBorderColor(border.r, border.g, border.b, border.a or 1)
    end
  end
  for _, texture in ipairs({ EavesDropTopBar, EavesDropBottomBar, EavesDropHistoryTopBar, EavesDropHistoryBottomBar,
      EavesDropTabLeft, EavesDropTabMiddle, EavesDropTabRight }) do
    if texture then texture:Hide() end
  end
  if EavesDropTabText then Font(EavesDropTabText, 11); EavesDropTabText:SetTextColor(.7, .85, .8) end
  for _, name in ipairs({ "EavesDropFramePlayerText", "EavesDropFrameTargetText", "EavesDropHistoryFrameSkillText",
      "EavesDropHistoryFrameAmountCritText", "EavesDropHistoryFrameAmountNormalText" }) do
    local text = getglobal(name)
    if text then Font(text, 12) end
  end
  for i = 1, 20 do
    local text = getglobal("EavesDropEvent" .. i .. "EventText")
    if text then Font(text, profile.TEXTSIZE or 14) end
  end
  for i = 1, 10 do
    for _, suffix in ipairs({ "_Skill", "_Hit", "_Crit" }) do
      local text = getglobal("EavesDropHistoryEvent" .. i .. suffix)
      if text then Font(text, 11) end
    end
  end
  for _, name in ipairs({ "EavesDropHistoryButton", "EavesDropHistoryFrameOutgoingHit", "EavesDropHistoryFrameOutgoingHeal",
      "EavesDropHistoryFrameIncomingHit", "EavesDropHistoryFrameIncomingHeal" }) do
    SkinExistingButton(getglobal(name), true)
  end
  SkinExistingButton(EavesDropHistoryFrameReset, false)
  if EavesDropHistoryFrameClose and not EavesDropHistoryFrameClose.edCaption then
    local close = EavesDropHistoryFrameClose
    SkinExistingButton(close, false)
    close.edCaption = Text(close, "×", 13)
    close.edCaption:SetPoint("CENTER", close, "CENTER", 0, 0)
  end
  for _, entry in ipairs({ { EavesDropFrameUpButton, "↑" }, { EavesDropFrameDownButton, "↓" } }) do
    local button = entry[1]
    if button then
      SkinExistingButton(button, false)
      if not button.edCaption then
        button.edCaption = Text(button, entry[2], 12)
        button.edCaption:SetPoint("CENTER", button, "CENTER", 0, 0)
      end
    end
  end
  if not reader and EavesDropFrame then
    reader = Button(EavesDropFrame, "", 160, 19, function() EavesDrop:ScrollToBottom() end)
    reader:SetPoint("BOTTOM", EavesDropFrame, "BOTTOM", 0, 4)
    reader:Hide()
    Hover(reader, "正在浏览历史，新的战斗事件继续收集。点击返回最新记录。")
    EavesDrop.readIndicator = reader
  end
  if reader and EavesDropFrame then
    reader:SetWidth(math.max(100, EavesDropFrame:GetWidth() - 42))
    reader.caption:SetWidth(reader:GetWidth() - 8)
    reader.caption:SetHeight(16)
  end
  if panel then
    Backdrop(panel, .035, .035, .035, profile.SETTINGALPHA or .95)
    panel:SetBackdropBorderColor(.25, .25, .25, profile.SETTINGBORDERALPHA or 1)
  end
end

function EavesDrop:UpdateReadIndicator(count, overflow)
  if not reader then self:ApplySkin() end
  if not reader then return end
  local state = self.GetHistoryState and self:GetHistoryState()
  local reading = state and state.reading or (count and count > 0)
  if reading then
    local value = overflow and "历史快照" or "历史"
    if count and count > 0 then value = value .. " +" .. count end
    value = value .. " · 返回"
    SetCaption(reader, value)
    reader:Show()
  else reader:Hide() end
end
