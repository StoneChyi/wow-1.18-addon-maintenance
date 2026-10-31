-- Adapt the existing option callbacks to pfUI's own controls. No second window,
-- copied module settings, or permanent per-option update loops are required.
do
  local R = {}
  pfUI.automationOptions = R
  local function Value(value)
    if type(value) == "function" then return value() end
    return value
  end
  local function Get(opt)
    if not opt.get then return nil end
    if opt.passValue ~= nil then return opt.get(opt.passValue) end
    return opt.get()
  end
  local function Set(opt, value)
    if not opt.set then return end
    if opt.passValue ~= nil then return opt.set(opt.passValue, value) end
    return opt.set(value)
  end
  local function Ordered(options)
    local ordered = {}
    for key, opt in pairs(options or {}) do
      if type(opt) == "table" then table.insert(ordered, { key = key, opt = opt }) end
    end
    table.sort(ordered, function(a,b)
      local aa,bb = tonumber(a.opt.order) or 999, tonumber(b.opt.order) or 999
      if aa ~= bb then return aa < bb end
      return tostring(a.key) < tostring(b.key)
    end)
    return ordered
  end
  local function Notify(state)
    if not state.building and state.changed then state.changed(state.module) end
  end
  local function Caption(opt, key)
    return tostring(Value(opt.name) or key or "")
  end
  local function Tooltip(row)
    local opt = row.option
    if not opt or not GameTooltip then return end
    local desc = Value(opt.desc)
    local usage = Value(opt.usage)
    if not desc and not usage then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(Caption(opt), 1, 1, 1)
    if desc then GameTooltip:AddLine(tostring(desc), .7,.7,.7,1) end
    if usage then GameTooltip:AddLine(tostring(usage), .2,1,.8,1) end
    if opt.min or opt.max then
      GameTooltip:AddLine(tostring(opt.min or "") .. " - " .. tostring(opt.max or "") .. " / " .. tostring(opt.step or 1), .7,.7,.7,1)
    end
    GameTooltip:Show()
    R.tooltipRow = row
  end
  local function CanEdit(row)
    return row.option and not row.disabled and not row.state.building
  end
  local function Run(state, action)
    local ok, result = pcall(action)
    if not ok then
      R.lastError = tostring(result)
      if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfUI|r 设置未完成：" .. R.lastError) end
      return false, result
    end
    R.lastError = nil
    return true, result
  end
  local function CommitValue(row)
    local opt, input = row.option, row.input
    local value = input:GetText()
    if value == row.displayed then return end
    if opt.type == "range" or opt.type == "number" then
      value = tonumber(value)
      if not value or value ~= value or value == math.huge or value == -math.huge then
        error(Caption(opt) .. "：请输入有效数字。")
      end
      if opt.step and opt.step > 0 then value = math.floor(value / opt.step + .5) * opt.step end
      value = math.floor(value * 1000 + .5) / 1000
      if opt.min then value = math.max(opt.min, value) end
      if opt.max then value = math.min(opt.max, value) end
    elseif type(opt.validate) == "function" and not opt.validate(value) then
      error(Caption(opt) .. "：输入未通过验证。")
    end
    if tostring(Get(opt) or "") ~= tostring(value) then Set(opt, value) end
    row.displayed = tostring(Get(opt) or "")
    input:SetText(row.displayed)

  end
  local function Commit(row, notify)
    if not CanEdit(row) or row.committing then return true end
    row.committing = true
    local ok = Run(row.state, function() CommitValue(row) end)
    row.committing = nil
    if ok and notify then Notify(row.state) end
    return ok
  end
  local function CommitAll(state)
    for _, candidate in ipairs(state.visible or {}) do
      if candidate.widget == "text" and not Commit(candidate, false) then
        -- A draft can be outside the viewport. Reveal a rejected input so it
        -- can be corrected instead of silently blocking controls elsewhere.
        local scroll = state.parent.parent
        scroll:SetVerticalScroll(math.max(0, math.min(candidate.automationOffset or 0, scroll:GetVerticalScrollRange())))
        R:UpdateViewport(state.parent)
        if scroll.UpdateScrollState then scroll:UpdateScrollState() end
        return false
      end
    end
    return true
  end
  local function NewRow(state, widget)
    local prior = this
    this = state.parent
    local oldDynamic = this.automationDynamic
    this.automationDynamic = true
    local ok, row = pcall(pfUI.gui.CreateConfig, function() end, "", { value = "" }, "value", widget, widget == "button" and function() end or {})
    state.parent.automationDynamic = oldDynamic
    this = prior
    if not ok then error(row) end
    row.state, row.widget = state, widget
    -- Native settings poll mouse focus on every row each frame. Expanded pages
    -- use enter/leave events instead, including for rows outside the viewport.
    row:SetScript("OnUpdate", nil)
    row:SetScript("OnEnter", function()
      if row.tex then row.tex:Show() end
      Tooltip(row)
    end)
    row:SetScript("OnLeave", function()
      if row.tex then row.tex:Hide() end
      if GameTooltip then GameTooltip:Hide() end
      if R.tooltipRow == row then R.tooltipRow = nil end
    end)
    row:EnableMouse(true)
    row:SetScript("OnHide", function()
      if row.input and row.input.menuframe then row.input.menuframe:Hide() end
    end)
    -- CreateConfig supplies initialized font objects and all pfUI skin assets.
    if widget == "text" then
      row.input:SetScript("OnTextChanged", nil)
      row.input:SetScript("OnEnterPressed", function()
        row.suppressFocus = true
        local ok = Commit(row, false)
        if ok then row.input:ClearFocus() end
        row.suppressFocus = nil
        if ok then Notify(state) end
      end)
      row.input:SetScript("OnEscapePressed", function()
        row.suppressFocus = true
        Run(state, function()
          row.displayed = tostring(Get(row.option) or "")
          row.input:SetText(row.displayed)
          row.input:ClearFocus()
        end)
        row.suppressFocus = nil
      end)
      row.input:SetScript("OnEditFocusLost", function()
        if not row.suppressFocus then Commit(row, true) end
      end)
    elseif widget == "checkbox" then
      -- Render supplies the saved value. Scrolling a row into view must not
      -- call module getters or rebind settings.
      row.input:SetScript("OnShow", nil)
      row.input:SetScript("OnClick", function()
        if CanEdit(row) and CommitAll(state) then
          Run(state, function() Set(row.option, row.input:GetChecked() and true or false) end)
          Notify(state)
        end
        -- Native buttons toggle before OnClick; restore the saved value when
        -- a pending edit or setter prevents this action from being saved.
        local ok, saved = pcall(Get, row.option)
        if ok then row.input:SetChecked(saved and 1 or nil) end
      end)
    elseif widget == "button" then
      row.button:SetScript("OnClick", function()
        if not CanEdit(row) then return end
        if not CommitAll(state) then return end
        if row.option.func and not Run(state, row.option.func) then return end
        -- Group actions can insert item placeholders into a captured edit box.
        -- Save that edit before rebuilding dynamic module lists.
        CommitAll(state)
        Notify(state)
      end)
    elseif widget == "color" then
      row.color:SetScript("OnClick", function()
        if not CanEdit(row) then return end
        if not CommitAll(state) then return end
        local opt = row.option
        local r,g,b,a = Get(opt)
        r,g,b,a = r or 1,g or 1,b or 1,a or 1
        local function Apply(cr,cg,cb,ca)
          if opt.set and not Run(state, function() opt.set(cr,cg,cb,ca) end) then return end
          row.color.prev:SetTexture(cr,cg,cb,ca)
        end
        -- SetColorRGB can fire an old callback: clear it while initializing.
        ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nil, nil, nil
        HideUIPanel(ColorPickerFrame)
        ColorPickerFrame.hasOpacity = opt.hasAlpha and 1 or nil
        ColorPickerFrame.opacity = 1-a
        ColorPickerFrame:SetColorRGB(r,g,b)
        OpacitySliderFrame:SetValue(1-a)
        ColorPickerFrame.func = function()
          local cr,cg,cb = ColorPickerFrame:GetColorRGB()
          local ca = opt.hasAlpha and (1-OpacitySliderFrame:GetValue()) or a
          Apply(cr,cg,cb,ca)
        end
        ColorPickerFrame.opacityFunc = ColorPickerFrame.func
        ColorPickerFrame.cancelFunc = function() Apply(r,g,b,a) end
        ColorPickerFrame:SetFrameStrata("DIALOG")
        R.colorOwner, R.colorRow = state, row
        ShowUIPanel(ColorPickerFrame)
      end)
    end
    table.insert(state.pool[widget], row)
    return row
  end
  local function Choices(opt)
    local choices, values = {}, Value(opt.validate) or {}
    for key, label in pairs(values) do
      table.insert(choices, { value = type(key) == "number" and label or key, text = tostring(label), order = key })
    end
    table.sort(choices, function(a,b)
      if type(a.order) == "number" and type(b.order) == "number" then return a.order < b.order end
      if a.text ~= b.text then return a.text < b.text end
      return tostring(a.order) < tostring(b.order)
    end)
    return choices
  end
  local function Add(state, opt, key, depth, parentDisabled)
    if Value(opt.hidden) then return end
    local kind = opt.type or "text"
    local widget = "text"
    if kind == "toggle" then widget = "checkbox"
    elseif kind == "group" or kind == "header" or kind == "description" then widget = "header"
    elseif kind == "execute" then widget = "button"
    elseif kind == "color" then widget = "color"
    elseif kind == "text" and type(opt.validate) == "table" and next(opt.validate) then widget = "dropdown" end
    state.used[widget] = (state.used[widget] or 0) + 1
    state.pool[widget] = state.pool[widget] or {}
    local row = state.pool[widget][state.used[widget]] or NewRow(state, widget)
    row.option, row.disabled = opt, parentDisabled or Value(opt.disabled)
    row.automationOffset = state.y
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", state.parent, "TOPLEFT", 5, -state.y)
    local width = math.max(180, state.parent.parent:GetRight()-state.parent.parent:GetLeft()-20)
    row:SetWidth(width)
    row:SetHeight(22)
    row:SetAlpha(row.disabled and .45 or 1)
    row:EnableMouse(not row.disabled)
    if row.caption then
      row.caption:ClearAllPoints()
      row.caption:SetPoint("LEFT", row, "LEFT", 3 + depth*8, 0)
      row.caption:SetJustifyV("MIDDLE")
      row.caption:SetWidth(math.max(40,width - (widget == "dropdown" and 190 or widget == "checkbox" and 30 or widget == "header" and 10 or 120) - depth*8))
      row.caption:SetHeight(0)
      row.caption:SetText(Caption(opt,key))
      row.caption:SetTextColor(widget == "header" and .2 or 1,1,widget == "header" and .8 or 1,1)
      row:SetHeight(math.max(22,row.caption:GetHeight()+6))
    end
    if widget == "header" then
      if kind == "description" then row.caption:SetTextColor(.7,.7,.7,1) end
      row:SetHeight(math.max(kind == "description" and 24 or 32, row.caption:GetHeight()+8))
    elseif widget == "text" then
      row.displayed = tostring(Get(opt) or "")
      row.input:SetText(row.displayed)
      if opt.onCreateEdit then opt.onCreateEdit(row.input) end
    elseif widget == "checkbox" then row.input:SetChecked(Get(opt) and 1 or nil)
    elseif widget == "dropdown" then
      row.input:SetMenu(function()
        local menu, current = {}, Get(row.option)
        for i, choice in ipairs(Choices(row.option)) do
          local v = choice.value
          table.insert(menu, { text = choice.text, func = function()
            if CanEdit(row) and CommitAll(state) then
              Run(state, function() Set(row.option, v) end); Notify(state)
            end
            row.input.current, row.input.id = nil, nil
            local ok = pcall(row.input.UpdateMenu, row.input)
            if ok then row.input:SetSelection(row.input.current) end
          end })
          if current == v then row.input.current = i end
        end
        return menu
      end)
      row.input.current, row.input.id = nil, nil
      row.input:UpdateMenu()
      row.input:SetSelection(row.input.current)
      if not row.input.current then row.input.text:SetText(tostring(Get(opt) or "")) end
    elseif widget == "color" then
      local r,g,b,a = Get(opt)
      row.color.prev:SetTexture(r or 1,g or 1,b or 1,a or 1)
    elseif widget == "button" then
      row.button:SetText(tostring(Value(opt.buttonText) or Caption(opt,key)))
      row.button:SetWidth(math.min(width-12, math.max(100,row.button:GetFontString():GetStringWidth()+20)))
      if opt.buttonText then
        if not row.actionLabel then
          row.actionLabel = row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
          row.actionLabel:SetPoint("LEFT",row,"LEFT",3,0)
          row.actionLabel:SetJustifyH("LEFT")
        end
        row.actionLabel:SetWidth(math.max(30,width-row.button:GetWidth()-15))
        row.actionLabel:SetText(Caption(opt,key)); row.actionLabel:Show()
      elseif row.actionLabel then row.actionLabel:Hide() end
    end
    local control = row.input or row.button or row.color
    if widget == "text" then
      if row.disabled then row.input:ClearFocus() end
      row.input:EnableKeyboard(not row.disabled)
    end
    if control then
      control:EnableMouse(not row.disabled)
      if control.Disable and control.Enable then
        if row.disabled then control:Disable() else control:Enable() end
      end
      if control.button then
        control.button:EnableMouse(not row.disabled)
        if row.disabled then control.button:Disable() else control.button:Enable() end
      end
    end
    row:Hide()
    row.automationHeight = row:GetHeight()
    table.insert(state.visible,row)
    state.y = state.y + row.automationHeight + 2
    if kind == "group" then
      for _, button in ipairs(opt.buttons or {}) do
        Add(state, { type = "execute", name = button.name, desc = button.tip, func = button.func }, "", depth+1,row.disabled)
      end
      for _, entry in ipairs(Ordered(opt.args)) do Add(state,entry.opt,entry.key,depth+1,row.disabled) end
    end
  end
  local function HideRow(row)
    -- Keep unfinished text in its original EditBox. Moving it out of view is
    -- not an edit submission; CommitAll still visits these logical rows.
    row.suppressFocus = true
    if row.input and row.input.ClearFocus then row.input:ClearFocus() end
    row:Hide()
    row.suppressFocus = nil
    if row.tex then row.tex:Hide() end
    if R.tooltipRow == row then
      if GameTooltip then GameTooltip:Hide() end
      R.tooltipRow = nil
    end
    if R.colorRow == row then
      HideUIPanel(ColorPickerFrame)
      R.colorOwner, R.colorRow = nil, nil
    end
  end
  function R:UpdateViewport(parent)
    local state = parent.automationOptionsState
    if not state or not state.visible or state.building or state.updatingViewport then return end
    local scroll, rows = parent.parent, state.visible
    local top = scroll:GetVerticalScroll()
    -- Vanilla reports the height of this double-anchored frame in scaled
    -- units, unlike explicitly sized rows. Edge coordinates share the rows'
    -- logical units: at scale .75, GetHeight() is 310.5 but the edges span 414.
    local upper, lower = scroll:GetTop(), scroll:GetBottom()
    local height
    if upper and lower and upper > lower then
      height = upper - lower
    else
      -- Edges may be unresolved while a page is being attached or hidden.
      local scale = scroll:GetEffectiveScale()
      height = scroll:GetHeight() / (scale and scale > 0 and scale or 1)
    end
    if state.viewportTop == top and state.viewportHeight == height then return end
    state.updatingViewport = true
    state.viewportTop, state.viewportHeight = top, height
    local count = table.getn(rows)
    -- Binary search measured rows; wheel work depends on the small viewport,
    -- not on the total number of settings. A margin avoids edge flicker.
    local low, high = 1, count + 1
    while low < high do
      local mid = math.floor((low + high)/2)
      local row = rows[mid]
      if row.automationOffset + row.automationHeight < top - 48 then low = mid + 1 else high = mid end
    end
    local first = low
    low, high = first, count + 1
    while low < high do
      local mid = math.floor((low + high)/2)
      if rows[mid].automationOffset <= top + height + 48 then low = mid + 1 else high = mid end
    end
    local last = low - 1
    for i = state.shownFirst or 1, state.shownLast or 0 do
      if i < first or i > last then HideRow(rows[i]) end
    end
    for i = first, last do
      if not state.shownFirst or i < state.shownFirst or i > state.shownLast then rows[i]:Show() end
    end
    state.shownFirst, state.shownLast = first, last
    state.updatingViewport = nil
  end
  local function InstallViewport(parent)
    local scroll = parent.parent
    -- CreateScrollChild's per-frame scrollbar synchronization is unnecessary:
    -- the native wheel/slider and the range-change event already update it.
    parent:SetScript("OnUpdate", nil)
    local vertical, range = scroll:GetScript("OnVerticalScroll"), scroll:GetScript("OnScrollRangeChanged")
    scroll:SetScript("OnVerticalScroll", function()
      if vertical then vertical() end
      R:UpdateViewport(parent)
    end)
    scroll:SetScript("OnScrollRangeChanged", function()
      if range then range() end
      if scroll.UpdateScrollState then scroll:UpdateScrollState() end
      R:UpdateViewport(parent)
    end)
    local size = scroll:GetScript("OnSizeChanged")
    scroll:SetScript("OnSizeChanged", function()
      if size then size() end
      if scroll.UpdateScrollState then scroll:UpdateScrollState() end
      R:UpdateViewport(parent)
    end)
  end
  function R:Clear(parent)
    local state = parent.automationOptionsState
    if not state then return end
    if R.tooltipRow and R.tooltipRow.state == state then
      if GameTooltip then GameTooltip:Hide() end
      R.tooltipRow = nil
    end
    if R.colorOwner == state then
      HideUIPanel(ColorPickerFrame)
      R.colorOwner, R.colorRow = nil, nil
    end
    state.building = true
    for _, rows in pairs(state.pool) do
      for _, row in ipairs(rows) do
        if row.input then
          if row.input.ClearFocus then row.input:ClearFocus() end
          if row.input.menuframe then row.input.menuframe:Hide() end
        end
        row.committing, row.suppressFocus = nil, nil
        row:Hide()
      end
    end
    state.visible = {}
    state.shownFirst, state.shownLast = nil, nil
    state.viewportTop, state.viewportHeight = nil, nil
    state.building = nil
    parent.objectCount = state.base
  end
  function R:Suspend(parent)
    local state = parent.automationOptionsState
    local ok = not state or CommitAll(state)
    self:Clear(parent)
    return ok
  end
  local function Render(self,parent,module,onChanged)
    if not parent or not parent.parent or not pfUI.gui or not pfUI.gui.CreateConfig then return false end
    local state = parent.automationOptionsState
    if not state then
      state = { parent=parent, pool={}, base=parent.objectCount or -1 }
      parent.automationOptionsState = state
      InstallViewport(parent)
      -- Native scroll children start with SetAllPoints; keep only top anchors
      -- so the measured content height controls the scroll range.
      parent:ClearAllPoints()
      parent:SetPoint("TOPLEFT",parent.parent,"TOPLEFT",0,0)
      parent:SetPoint("TOPRIGHT",parent.parent,"TOPRIGHT",0,0)
    end
    -- Only changed drafts are committed: untouched stale controls must never
    -- overwrite a setting that another page or module has just updated.
    if state.visible and not CommitAll(state) then return false end
    self:Clear(parent)
    state.module, state.changed = module, onChanged
    state.used, state.visible, state.building = {}, {}, true
    state.y = (state.base+1)*23+5
    for _,entry in ipairs(Ordered(module and module._options)) do Add(state,entry.opt,entry.key,0,false) end
    state.building = nil
    parent.objectCount = math.ceil(state.y/23)
    parent:SetHeight(state.y+10)
    local scroll = parent.parent
    if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
    if scroll.GetVerticalScroll and scroll.GetVerticalScrollRange then
      scroll:SetVerticalScroll(math.max(0,math.min(scroll:GetVerticalScroll(),scroll:GetVerticalScrollRange())))
    end
    if scroll.UpdateScrollState then scroll:UpdateScrollState() end
    self:UpdateViewport(parent)
    return true
  end  function R:Render(parent,module,onChanged)
    local prior = this
    local ok, result = pcall(Render, self, parent, module, onChanged)
    this = prior
    if not ok then
      -- Failed options must not leave the page permanently locked.
      local state = parent and parent.automationOptionsState
      if state then
        pcall(self.Clear, self, parent)
        state.building = nil
      end
      error(result)
    end
    return result
  end
end
