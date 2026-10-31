-- A bounded native-style second-level menu for automation modules.
-- The three native content areas remain responsible for page lifecycle/save.
do
  local N = {}
  pfUI.automationNavigation = N
  local ROW, WIDTH = 20, 130
  local function FontSize()
    local config = pfUI_config
    return tonumber(config and config.global and config.global.font_size) or 12
  end
  local function Text(parent, layer, size)
    local text = parent:CreateFontString(nil, layer or "OVERLAY", "GameFontHighlight")
    if pfUI.font_default then text:SetFont(pfUI.font_default, size or FontSize()) end
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    return text
  end
  local function Height(frame)
    local upper, lower = frame:GetTop(), frame:GetBottom()
    if upper and lower and upper > lower then return upper-lower end
    local scale = frame:GetEffectiveScale()
    return frame:GetHeight() / (scale and scale > 0 and scale or 1)
  end
  local function ClearFocus(state)
    state.search:ClearFocus()
    if pfUI.gui.search then pfUI.gui.search:ClearFocus() end
  end
  local function HideTip(state)
    if state.tipOwner then
      if GameTooltip then GameTooltip:Hide() end
      state.tipOwner = nil
    end
  end
  local function Fit(text, caption, width)
    -- Clip only at UTF-8 character boundaries. Old FontStrings do not expose
    -- SetWordWrap; bounding the label prevents wrapping into another menu row.
    -- Measure without the display width: otherwise a wrapped/clipped line
    -- can report a fitting width even though the complete caption is longer.
    text:SetWidth(0)
    text:SetText(caption)
    if text:GetStringWidth() <= width then text:SetWidth(width);return end
    local value = caption
    while string.len(value) > 0 do
      local last = string.len(value)
      while last > 1 and string.byte(value,last) >= 128 and string.byte(value,last) < 192 do last = last-1 end
      value = string.sub(value,1,last-1)
      text:SetText(value .. "...")
      if text:GetStringWidth() <= width then text:SetWidth(width);return end
    end
    text:SetText("...")
    text:SetWidth(width)
  end
  local function Style(button, active)
    button.text:SetTextColor(active and .2 or 1, 1, active and .8 or 1, 1)
    button.bg:SetTexture(active and 1 or 0,active and 1 or 0,active and 1 or 0,active and 1 or 0)
    if active then button.bg:SetGradientAlpha("HORIZONTAL",0,0,0,0,1,1,1,.05) end
  end
  local function Button(state, parent)
    local button = CreateFrame("Button",nil,parent)
    button:SetWidth(WIDTH-8)
    button:SetHeight(ROW)
    button.bg = button:CreateTexture(nil,"BACKGROUND")
    button.bg:SetAllPoints(button)
    button.text = Text(button,"OVERLAY")
    button.text:SetPoint("LEFT",button,"LEFT",4,0)
    button.text:SetWidth(WIDTH-16)
    button.text:SetHeight(ROW)
    button:SetScript("OnMouseDown",function() ClearFocus(state) end)
    button:SetScript("OnEnter",function()
      if not button.entry or not GameTooltip then return end
      state.tipOwner = button
      GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
      GameTooltip:SetText(button.entry.label or button.entry.name,1,1,1)
      if button.entry.description and button.entry.description ~= "" then
        GameTooltip:AddLine(button.entry.description,.7,.7,.7,1)
      end
      if button.entry.native then GameTooltip:AddLine("点击打开对应的 pfUI 原生设置。",.2,1,.8,1) end
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() if state.tipOwner == button then HideTip(state) end end)
    button:EnableMouseWheel(true)
    button:SetScript("OnMouseWheel",function()
      state.offset = state.offset-(arg1 or 0)*3
      N:Render(state)
    end)
    return button
  end
  function N:Filter(state)
    state.filtered = {}
    local query = string.lower(state.query or "")
    for _,entry in ipairs(state.entries or {}) do
      local label = entry.label or entry.name
      local haystack = string.lower(entry.name .. " " .. label .. " " .. (entry.description or ""))
      if not entry.hidden and (query == "" or string.find(haystack,query,1,true)) then
        table.insert(state.filtered,entry)
      end
    end
  end
  function N:Render(state)
    if state.rendering then return end
    state.rendering = true
    HideTip(state)
    local room = math.max(ROW,Height(state.frame)-86)
    local capacity = math.max(1,math.floor(room/ROW))
    local count = table.getn(state.filtered or {})
    state.capacity = capacity
    state.offset = math.max(0,math.min(math.floor(state.offset or 0),math.max(0,count-capacity)))
    state.slider:SetMinMaxValues(0,math.max(0,count-capacity))
    state.slider:SetValue(state.offset)
    if count > capacity then
      state.slider.thumb:SetHeight(math.max(16,math.floor(capacity*ROW*capacity/count)))
      state.slider:Show()
    else
      state.slider:Hide()
    end
    for i=1,capacity do
      local entry = state.filtered[state.offset+i]
      local button = state.rows[i]
      if entry and not button then
        button = Button(state,state.frame)
        button:SetPoint("TOPLEFT",state.frame,"TOPLEFT",0,-68-(i-1)*ROW)
        button:SetScript("OnClick",function()
          if button.entry then state.host:SelectModule(button.entry.name) end
        end)
        state.rows[i] = button
      end
      if button then
        button.entry = entry
        if entry then
          Fit(button.text,entry.label or entry.name,WIDTH-16)
          Style(button,state.selected == entry.name)
          button:Show()
        else button:Hide() end
      end
    end
    for i=capacity+1,table.getn(state.rows) do state.rows[i].entry=nil;state.rows[i]:Hide() end
    Style(state.manage,state.selected == state.host.general)
    Style(state.merchant,state.selected == state.host.merchant)
    if count == 0 then
      state.empty:Show();state.count:SetText("0")
    else
      state.empty:Hide()
      state.count:SetText(tostring(state.offset+1).."-"..tostring(math.min(count,state.offset+capacity)).." / "..tostring(count))
    end
    state.rendering = nil
  end
  function N:Attach(host,group)
    if host.navigation and host.navigation.group == group then return host.navigation end
    local state = { host=host,group=group,entries={},filtered={},rows={},query="",offset=0 }
    host.navigation = state
    -- Never add another .area member to the native group: TabFrameOnClick
    -- treats every group member with .area as a mutually exclusive page.
    local frame = CreateFrame("Frame",nil,group.area)
    state.frame = frame
    frame:SetPoint("TOPLEFT",group.area,"TOPLEFT",0,0)
    frame:SetPoint("BOTTOMLEFT",group.area,"BOTTOMLEFT",0,0)
    frame:SetWidth(WIDTH)
    for key,tab in pairs(group) do
      if key ~= "parent" and type(tab) == "table" and tab.area then tab:Hide() end
    end
    state.manage = Button(state,frame)
    state.manage:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
    state.manage.text:SetText(host.general)
    state.manage:SetScript("OnClick",function() host:OpenPage(host.general) end)
    state.merchant = Button(state,frame)
    state.merchant:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-ROW)
    state.merchant.text:SetText(host.merchant)
    state.merchant:SetScript("OnClick",function() host:OpenPage(host.merchant) end)
    local search = CreateFrame("EditBox",nil,frame)
    state.search = search
    search:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-43)
    search:SetWidth(WIDTH-12)
    search:SetHeight(20)
    search:SetFontObject(GameFontHighlight)
    if pfUI.font_default then search:SetFont(pfUI.font_default,FontSize()) end
    search:SetAutoFocus(false)
    search:SetTextInsets(4,4,0,0)
    search:SetTextColor(1,1,1,1)
    if pfUI.api and pfUI.api.CreateBackdrop then pfUI.api.CreateBackdrop(search,nil,true) end
    state.hint = Text(search)
    state.hint:SetPoint("LEFT",search,"LEFT",4,0)
    state.hint:SetWidth(WIDTH-22)
    state.hint:SetHeight(18)
    state.hint:SetTextColor(.6,.6,.6,1)
    state.hint:SetText("搜索模块")
    search:SetText("")
    search:SetScript("OnTextChanged",function()
      state.query = search:GetText()
      if state.query == "" and not state.searchFocused then state.hint:Show() else state.hint:Hide() end
      state.offset = 0
      N:Filter(state);N:Render(state)
    end)
    search:SetScript("OnEditFocusGained",function() state.searchFocused=true;state.hint:Hide() end)
    search:SetScript("OnEditFocusLost",function()
      state.searchFocused=nil
      if state.query == "" then state.hint:Show() end
    end)
    search:SetScript("OnEnterPressed",function() search:ClearFocus() end)
    search:SetScript("OnEscapePressed",function() search:SetText("");search:ClearFocus() end)
    state.empty = Text(frame)
    state.empty:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-70)
    state.empty:SetWidth(WIDTH-12)
    state.empty:SetHeight(20)
    state.empty:SetText("没有匹配模块")
    state.empty:SetTextColor(.6,.6,.6,1)
    state.count = Text(frame)
    state.count:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",4,2)
    state.count:SetWidth(WIDTH-12)
    state.count:SetHeight(16)
    state.count:SetTextColor(.6,.6,.6,1)
    local slider = CreateFrame("Slider",nil,frame)
    state.slider = slider
    slider:SetOrientation("VERTICAL")
    slider:SetPoint("TOPLEFT",frame,"TOPLEFT",WIDTH-7,-68)
    slider:SetPoint("BOTTOMRIGHT",frame,"BOTTOMLEFT",WIDTH-2,20)
    slider:SetThumbTexture(pfUI.media and pfUI.media["img:col"] or "Interface\\Buttons\\WHITE8X8")
    slider.thumb = slider:GetThumbTexture()
    slider.thumb:SetTexture(.3,1,.8,.5)
    slider:SetScript("OnValueChanged",function()
      if state.rendering then return end
      state.offset = math.floor(slider:GetValue()+.5)
      N:Render(state)
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel",function()
      state.offset=state.offset-(arg1 or 0)*3;N:Render(state)
    end)
    frame:SetScript("OnShow",function() N:Render(state) end)
    frame:SetScript("OnSizeChanged",function() N:Render(state) end)
    frame:SetScript("OnHide",function() search:ClearFocus();HideTip(state) end)
    N:Render(state)
    return state
  end
  function N:Update(host,entries,selected)
    local state = host.navigation
    if not state then return end
    state.entries,state.selected = entries or {},selected
    self:Filter(state)
    self:Render(state)
  end
  function N:EnsureVisible(host,name)
    local state = host.navigation
    if not state then return end
    local found
    for _,entry in ipairs(state.entries) do if entry.name == name and not entry.hidden then found=true;break end end
    if not found then return end
    local index
    for i,entry in ipairs(state.filtered) do if entry.name == name then index=i;break end end
    if not index then
      state.query="";state.search:SetText("");self:Filter(state)
      for i,entry in ipairs(state.filtered) do if entry.name == name then index=i;break end end
    end
    if index then
      local capacity = state.capacity or 1
      if index <= state.offset then state.offset=index-1
      elseif index > state.offset+capacity then state.offset=index-capacity end
      self:Render(state)
    end
  end
end
