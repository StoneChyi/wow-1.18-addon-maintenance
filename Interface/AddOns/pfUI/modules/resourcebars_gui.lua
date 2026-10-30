-- ExtraResourceBars settings compatibility. Original addon: Fiur#8658.
-- All controls belong to pfUI; no original globals or saved options are reused.
pfUI:RegisterModule("resourcebars-gui", "vanilla:tbc", function()
  local module = pfUI.resourcebars
  if not module then return end
  local PREFIX = "pfERBConfig"
  local FONT = "Fonts\\FZJZJW.ttf"

  -- Keep the original 39 field identifiers and ordering, including gradiantHP.
  local settings = {
    {"HP - 隐藏", "hp_hide", false, {"erb_hp", "hide"}},
    {"HP - 填充方向", "hp_barResize", "LEFT", {"erb_hp", "barResize"}},
    {"HP - 宽度", "hp_width", 124, {"erb_hp", "width"}},
    {"HP - 高度", "hp_height", 21, {"erb_hp", "height"}},
    {"HP - 颜色", "hp_color", {0,1,0,1}, {"erb_hp", "color"}},
    {"HP - 字体大小", "hp_fontSize", 10, {"erb_hp", "fontSize"}},
    {"HP - 文本样式(0-4)", "hp_textType", 3, {"erb_hp", "textType"}},
    {"HP - 文本对齐", "hp_textAlign", "CENTER", {"erb_hp", "textAlign"}},
    {"HP - 生命值渐变", "hp_gradiantHP", true, {"erb_hp", "gradiantHP"}},
    {"HP - 材质(0-35)", "hp_bar", 4, {"erb_hp", "bar"}},
    {"HP - 边框(0-4)", "hp_border", 3, {"erb_hp", "border"}},
    {"HP - 背景", "hp_background", true, {"erb_hp", "background"}},
    {"HP - 背景颜色", "hp_backgroundColor", {0,0,0,.35}, {"erb_hp", "backgroundColor"}},
    {"HP - 只在战斗中显示", "hp_only_combat", false, {"erb_hp", "only_combat"}},
    {"HP - 血满隐藏", "hp_hide_when_full", false, {"erb_hp", "hide_when_full"}},
    {"HP - 淡入时间", "hp_fade_in_time", .2, {"erb_hp", "fade_in_time"}},
    {"HP - 淡出时间", "hp_fade_out_time", .2, {"erb_hp", "fade_out_time"}},
    {"HP - 移动(按SHIFT)", "hp_moveable", true, {"erb_hp", "moveable"}},
    {"PP - 隐藏", "pp_hide", false, {"erb_pp", "hide"}},
    {"PP - 填充方向", "pp_barResize", "LEFT", {"erb_pp", "barResize"}},
    {"PP - 宽度", "pp_width", 124, {"erb_pp", "width"}},
    {"PP - 高度", "pp_height", 21, {"erb_pp", "height"}},
    {"PP - 原默认资源", "pp_color_main", "mana", {"erb_pp", "main", "powers"}},
    {"PP - 原法力颜色", "pp_color_mana", {.2,.2,1,1}, {"erb_pp", "mana", "powers"}},
    {"PP - 原怒气颜色", "pp_color_rage", {1,0,0,1}, {"erb_pp", "rage", "powers"}},
    {"PP - 原能量颜色", "pp_color_energy", {1,1,0,1}, {"erb_pp", "energy", "powers"}},
    {"PP - 字体大小", "pp_fontSize", 10, {"erb_pp", "fontSize"}},
    {"PP - 文本样式(0-4)", "pp_textType", 1, {"erb_pp", "textType"}},
    {"PP - 文本对齐", "pp_textAlign", "CENTER", {"erb_pp", "textAlign"}},
    {"PP - 在框架下方对齐", "pp_under", "erb_hp", {"erb_pp", "under"}},
    {"PP - 间距", "pp_spacing", 1, {"erb_pp", "spacing"}},
    {"PP - 材质(0-35)", "pp_bar", 4, {"erb_pp", "bar"}},
    {"PP - 边框(0-4)", "pp_border", 3, {"erb_pp", "border"}},
    {"PP - 背景", "pp_background", true, {"erb_pp", "background"}},
    {"PP - 背景颜色", "pp_backgroundColor", {0,0,0,.45}, {"erb_pp", "backgroundColor"}},
    {"PP - 只在战斗中显示", "pp_only_combat", false, {"erb_pp", "only_combat"}},
    {"PP - 条满隐藏", "pp_hide_when_full", false, {"erb_pp", "hide_when_full"}},
    {"PP - 淡入时间", "pp_fade_in_time", .2, {"erb_pp", "fade_in_time"}},
    {"PP - 淡出时间", "pp_fade_out_time", .2, {"erb_pp", "fade_out_time"}}
  }
  local fonts = {
    {"HP - 字体文件", "hp_font", FONT, {"erb_hp", "font"}},
    {"PP - 字体文件", "pp_font", FONT, {"erb_pp", "font"}}
  }
  module.settings = settings

  local function DB() C.resourcebars = C.resourcebars or {}; return C.resourcebars end
  local function Trim(value)
    local result = string.gsub(string.gsub(value or "", "^%s+", ""), "%s+$", "")
    return result
  end
  local function Finite(n) return n and n == n and n ~= math.huge and n ~= -math.huge end

  local function Read(data, field)
    local path = field[4]
    local bar = data[path[1]]
    if not bar then return field[3] end
    if path[3] then return type(bar[path[3]]) == "table" and bar[path[3]][path[2]] or field[3] end
    if path[2] == "under" then return bar.under end
    if bar[path[2]] ~= nil then return bar[path[2]] end
    return field[3]
  end

  local function Write(data, field, value)
    local path = field[4]
    data[path[1]] = data[path[1]] or {}
    if path[3] then
      data[path[1]][path[3]] = data[path[1]][path[3]] or {}
      data[path[1]][path[3]][path[2]] = value
    else data[path[1]][path[2]] = value end
  end

  local function ColorText(value)
    return "{" .. tostring(value[1] or 0) .. ", " .. tostring(value[2] or 0) .. ", " ..
      tostring(value[3] or 0) .. ", " .. tostring(value[4] or 1) .. "}"
  end

  local function Display(control, field, value)
    if type(field[3]) == "boolean" then control:SetChecked(module.IsEnabledValue(value))
    elseif type(field[3]) == "table" then
      if type(value) ~= "table" then value = field[3] end
      control.resourceColorText = ColorText(value)
      control.resourceColorValue = module.CopyData(value)
      control:SetText(control.resourceColorText)
      control:SetTextColor(value[1] or 0, value[2] or 0, value[3] or 0, value[4] or 1)
    else control:SetText(value == nil and "nil" or tostring(value)) end
  end

  local function EachField(fn)
    for _, field in ipairs(settings) do fn(field) end
    for _, field in ipairs(fonts) do fn(field) end
  end

  local function Fill(data)
    EachField(function(field) Display(module.editor.fields[field[2]], field, Read(data, field)) end)
  end

  local function ParseColor(text)
    local _, _, body = string.find(text, "^%s*{%s*(.-)%s*}%s*$")
    if not body or string.find(body, ",%s*,") or string.find(body, "^%s*,") or string.find(body, ",%s*$") then return nil end
    local result = {}
    for token in string.gfind(body, "([^,]+)") do
      local n = tonumber(Trim(token))
      if not Finite(n) or n < 0 or n > 1 then return nil end
      table.insert(result, n)
    end
    if table.getn(result) ~= 3 and table.getn(result) ~= 4 then return nil end
    result[4] = result[4] or 1
    return result
  end

  local function Parse(control, field)
    local kind, option = type(field[3]), field[4][2]
    if kind == "boolean" then return true, module.IsEnabledValue(control:GetChecked()) end
    local text = Trim(control:GetText())
    if kind == "table" then
      local value = ParseColor(text)
      if not value then return false, "颜色须填写 {红, 绿, 蓝, 透明度}，每项为0到1。" end
      if text == control.resourceColorText and control.resourceColorValue then value = module.CopyData(control.resourceColorValue) end
      return true, value
    elseif kind == "number" then
      local n = tonumber(text)
      if not Finite(n) then return false, "须填写有效数字。" end
      local low, high = -4000, 4000
      if option == "width" then low, high = 8, 4000
      elseif option == "height" then low, high = 6, 500
      elseif option == "fontSize" then low, high = 1, 128
      elseif option == "textType" then low, high = 0, 4
      elseif option == "bar" then low, high = 0, 35
      elseif option == "border" then low, high = 0, 4
      elseif option == "fade_in_time" or option == "fade_out_time" then low, high = 0, 60 end
      if n < low or n > high then return false, "范围为 " .. low .. " 到 " .. high .. "。" end
      if (option == "textType" or option == "bar" or option == "border") and math.floor(n) ~= n then return false, "须填写整数。" end
      return true, n
    end
    if option == "barResize" or option == "textAlign" then
      text = string.upper(text)
      if text ~= "LEFT" and text ~= "CENTER" and text ~= "RIGHT" then return false, "请填写 LEFT、CENTER 或 RIGHT。" end
    elseif option == "main" then
      text = string.lower(text)
      if text ~= "mana" and text ~= "rage" and text ~= "energy" then return false, "请填写 mana、rage 或 energy。" end
    elseif option == "under" and (text == "" or text == "nil") then return true, nil
    elseif option == "font" and text == "" then text = FONT end
    return true, text
  end

  function module:SaveEditor()
    if not self.editor then return false, "设置面板尚未打开。" end
    local draft = self.CopyData(DB().data) or self:Defaults()
    local errorText
    EachField(function(field)
      if errorText then return end
      local ok, value = Parse(self.editor.fields[field[2]], field)
      if not ok then errorText = field[1] .. "：" .. value
      else Write(draft, field, value) end
    end)
    if errorText then self:Notify(errorText); return false, errorText end
    DB().data = draft
    self:UpdateConfig()
    self:Notify("内置设置已保存；原版设置未改动。")
    return true
  end

  function module:ResetEditor()
    if self.editor then Fill(self:Defaults()); self:Notify("已填入默认值；点击保存后才会应用。") end
  end

  local function Label(parent, text, size)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetFontObject(GameFontNormalSmall or "GameFontNormalSmall")
    module.SetSafeFont(label, FONT, size or 10)
    label:SetText(text)
    return label
  end

  local function Picker(control, field)
    local current = ParseColor(control:GetText())
    if not current then module:Notify("请先填写有效颜色，再使用拾色器。"); return end
    local picker = _G.ColorPickerFrame
    if not picker then return end
    local function Apply(restore)
      local color
      if type(restore) == "table" then color = restore
      else
        local r, g, b = picker:GetColorRGB()
        local opacity = _G.OpacitySliderFrame and _G.OpacitySliderFrame:GetValue() or 0
        color = {r, g, b, 1 - opacity}
      end
      Display(control, field, color)
    end
    picker:Hide()
    picker.hasOpacity, picker.opacity = true, 1 - current[4]
    picker.previousValues = current
    picker.func, picker.opacityFunc, picker.cancelFunc = Apply, Apply, Apply
    picker:SetColorRGB(current[1], current[2], current[3])
    picker:Show()
  end

  local function CreateControl(editor, field, index)
    local column = math.mod(index - 1, 4)
    local row = math.floor((index - 1) / 4)
    local x, y = 24 + column * 174, -76 - row * 45
    local control
    if type(field[3]) == "boolean" then
      control = CreateFrame("CheckButton", PREFIX .. "_" .. field[2], editor, "OptionsCheckButtonTemplate")
      control:SetPoint("TOPLEFT", editor, "TOPLEFT", x - 7, y)
      local inherited = _G[PREFIX .. "_" .. field[2] .. "Text"]
      if inherited then inherited:Hide() end
      control.label = Label(control, field[1])
      control.label:SetPoint("LEFT", control, "RIGHT", 1, 0)
    else
      control = CreateFrame("EditBox", PREFIX .. "_" .. field[2], editor, "InputBoxTemplate")
      control:SetFontObject(GameFontNormalSmall or "GameFontNormalSmall")
      module.SetSafeFont(control, FONT, 11)
      control:SetAutoFocus(false)
      control:SetWidth(156)
      control:SetHeight(24)
      control:SetPoint("TOPLEFT", editor, "TOPLEFT", x, y)
      control.label = Label(control, field[1])
      control.label:SetPoint("BOTTOMLEFT", control, "TOPLEFT", -3, 1)
      control:SetScript("OnEscapePressed", function() this:ClearFocus() end)
      control:SetScript("OnEnterPressed", function() this:ClearFocus() end)
      if type(field[3]) == "table" then
        control:SetScript("OnMouseUp", function()
          if arg1 == "LeftButton" or arg1 == "RightButton" then Picker(control, field) end
        end)
      end
    end
    editor.fields[field[2]] = control
  end

  function module:BuildConfig()
    if type(DB().data) ~= "table" then
      self:ImportLegacy()
    end
    if not self.editor then
      local editor = CreateFrame("Frame", PREFIX, UIParent)
      self.editor = editor
      editor.fields = {}
      editor:SetWidth(726)
      editor:SetHeight(630)
      editor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
      editor:SetFrameStrata("DIALOG")
      editor:SetMovable(true)
      editor:EnableMouse(true)
      editor:RegisterForDrag("LeftButton")
      editor:SetScript("OnDragStart", function() this:StartMoving() end)
      editor:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
      editor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
        insets = {left = 8, right = 8, top = 8, bottom = 8}})
      editor:SetBackdropColor(.08, .08, .08, .96)
      editor.title = Label(editor, "pfUI 生命与资源条（内置设置）", 15)
      editor.title:SetPoint("TOP", editor, "TOP", 0, -16)
      editor.help = Label(editor, "点击颜色打开拾色器。跟随头像颜色时，PP原颜色保留待切换。资源种类随当前形态。", 10)
      editor.help:SetPoint("TOP", editor, "TOP", 0, -43)
      for i, field in ipairs(settings) do CreateControl(editor, field, i) end
      for i, field in ipairs(fonts) do CreateControl(editor, field, table.getn(settings) + i) end
      local function Button(name, text, x, action)
        local button = CreateFrame("Button", PREFIX .. name, editor, "OptionsButtonTemplate")
        button:SetWidth(100); button:SetHeight(24)
        button:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", x, 16)
        button:SetText(text)
        button:SetScript("OnClick", action)
        return button
      end
      editor.save = Button("Save", "保存", 610, function() module:SaveEditor() end)
      editor.reset = Button("Reset", "重置", 16, function() module:ResetEditor() end)
      editor.close = Button("Close", "关闭", 126, function() module.editor:Hide() end)
    end
    Fill(DB().data or self:Defaults())
    self.editor:Show()
    return true
  end

  function module:InstallFallbackCommand()
    if not _G.SlashCmdList["ERB"] then
      _G.SLASH_ERB1 = "/erb"
      _G.SlashCmdList["ERB"] = function() module:OpenConfig() end
    end
  end

  module:InstallFallbackCommand()
  if module.openPending then module.openPending = nil; module:OpenConfig() end
end)
