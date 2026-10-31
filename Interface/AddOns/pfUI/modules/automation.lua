-- pfUI is the management surface; Automatonex retains its mature module engine
-- and original saved data for an independent fallback.
pfUI:RegisterModule("automation", "vanilla", function()
  local host = { title = "自动化工具箱", all = "全部功能", merchant = "商人与融合" }
  pfUI.automation = host
  local input = { item = "" }
  local attempts = 0
  function host:Config()
    C.automation = C.automation or {}
    if C.automation.enabled == nil then C.automation.enabled = "1" end
    return C.automation
  end
  function host:IsEnabled() return self:Config().enabled == "1" end
  function host:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfUI|r " .. message) end
  end
  function host:Sync()
    local bridge = _G.AutomatonPfUIBridge
    if not bridge then return false end
    if not self:IsEnabled() then
      if bridge.host then bridge:Release() end
      if self.placeholder then self.placeholder:Show() end
      self:RefreshSummary()
      return true
    end
    local ready = bridge:Acquire(self)
    if self.content and Automaton then
      if self.placeholder then self.placeholder:Hide() end
      Automaton:CreateMainWindow()
      bridge:Attach(self.content)
    end
    self:RefreshSummary()
    return ready
  end
  function host:Expand()
    if not pfUI.gui then return end
    if not self.oldSize then self.oldSize = { pfUI.gui:GetWidth(), pfUI.gui:GetHeight(), pfUI.gui:GetScale() } end
    pfUI.gui:SetWidth(math.max(self.oldSize[1], 1040))
    pfUI.gui:SetHeight(math.max(self.oldSize[2], 640))
    local scale = math.min(self.oldSize[3], (UIParent:GetWidth()-24)/pfUI.gui:GetWidth(), (UIParent:GetHeight()-24)/pfUI.gui:GetHeight())
    if scale > 0 then pfUI.gui:SetScale(scale) end
  end
  function host:RestoreSize()
    if self.oldSize and pfUI.gui then
      pfUI.gui:SetWidth(self.oldSize[1]); pfUI.gui:SetHeight(self.oldSize[2]); pfUI.gui:SetScale(self.oldSize[3]); self.oldSize = nil
    end
  end
  function host:OpenPage(page)
    if not pfUI.gui and pfUI.ShowGUI then pfUI:ShowGUI() end
    self:BuildGUI()
    if not pfUI.gui or not self.guiReady then self.pendingPage = page; return end
    pfUI.gui:Show()
    local parent = pfUI.gui.frames[self.title]
    if parent then parent:Click(); if parent[page] then parent[page]:Click() end end
  end
  function host:Open() self:OpenPage(self.all) end
  function host:OpenVendor() self:OpenPage(self.merchant) end
  function host:RefreshSummary()
    if not self.summary then return end
    local lines = {}
    local bridge = _G.AutomatonPfUIBridge
    if bridge and bridge.active then
      table.insert(lines, "自动修理与售卖：由 pfUI 统一执行。原工具箱保留名单与自定义规则已合并。")
    else
      table.insert(lines, "商人服务尚未接管；原工具箱继续按原设置运行。")
      if not self:IsEnabled() then table.insert(lines, "关闭统一管理后，商人功能恢复工具箱原开关；pfUI 暂停执行，新名单仍保留。") end
    end
    local vendor = pfUI.autovendor
    if vendor and vendor.GetRules then
      local rules = vendor:GetRules()
      for _, kind in ipairs({ "ignore", "custom" }) do
        local values = {}
        for id, name in pairs(rules[kind] or {}) do
          table.insert(values, tostring(id) .. " " .. (type(name) == "string" and name or ""))
        end
        table.sort(values)
        table.insert(lines, (kind == "ignore" and "保留名单：" or "自定义售卖：") ..
          (table.getn(values) > 0 and table.concat(values, "；") or "空"))
      end
    end
    table.insert(lines, "重叠功能检查（隐藏只影响菜单，不代表停用）：")
    if Automaton and Automaton.db and Automaton.db.char then
      for _, item in ipairs({ {"ExpBar", "经验条"}, {"Tooltip", "提示增强"}, {"InterPlayerLink", "角色链接"} }) do
        local active = Automaton:IsModuleActive(item[1]) and "启用" or "停用"
        local hidden = Automaton:IsModuleHidden(item[1]) and "，菜单隐藏" or "，菜单显示"
        table.insert(lines, item[2] .. "：" .. active .. hidden .. "。独有选项保留在“全部功能”。")
      end
    end
    table.insert(lines, "已融合：修理、灰色售卖、保留名单、自定义售卖。其他功能不因名称相似自动关闭。")
    self.summary:SetText(table.concat(lines, "\n\n"))
    local parent = self.summary:GetParent()
    parent:SetHeight(math.max(650, 255 + self.summary:GetStringHeight()))
  end
  function host:EditRule(kind, remove)
    local vendor = pfUI.autovendor
    local id = tonumber(input.item)
    if not id or id < 1 or id ~= math.floor(id) then self:Print("请输入有效的物品 ID。"); return end
    if not vendor or not vendor.ready then self:Print("商人服务尚未准备好，请登录完成后再试。"); return end
    local name
    if not remove then name = GetItemInfo(id) or ("物品 " .. id) end
    local ok, reason = vendor:SetRule(kind, id, name)
    if ok == false then self:Print(reason or "规则未保存。"); return end
    self:RefreshSummary()
  end
  local function MakeSummary(parent, y)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    -- A valid built-in object is installed before any SetText, even when a
    -- configurable font fails to load. Do not rely on a successful SetFont.
    text:SetFontObject(GameFontHighlight or GameFontNormal)
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    text:SetWidth(650)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("")
    return text
  end
  function host:BuildGUI()
    if self.guiReady or not pfUI.gui or not pfUI.gui.CreateGUIEntry then return end
    local gui, create = pfUI.gui, pfUI.gui.CreateConfig
    gui.CreateGUIEntry(self.title, self.all, function()
      host.content = this
      this:SetHeight(520)
      local label = MakeSummary(this, -10)
      host.placeholder = label
      label:SetText("开启统一管理后，这里显示工具箱全部模块和完整设置。若 Automatonex 未加载，请先在角色插件列表中启用它。")
      if Automaton and AutomatonPfUIBridge and host:IsEnabled() then
        label:Hide()
        Automaton:CreateMainWindow()
        AutomatonPfUIBridge:Attach(this)
      end
    end)
    gui.CreateGUIEntry(self.title, self.merchant, function()
      create(function() host:Sync() end, "由 pfUI 统一管理工具箱", host:Config(), "enabled", "checkbox")
      create(function() end, "自动修理", C.global, "autorepair", "checkbox")
      create(function() end, "自动售卖灰色及自定义物品", C.global, "autosell", "checkbox")
      create(function() end, "物品 ID", input, "item", nil, nil, nil, nil, "STRING")
      create(nil, "加入保留名单", nil, nil, "button", function() host:EditRule("ignore", false) end)
      create(nil, "移出保留名单", nil, nil, "button", function() host:EditRule("ignore", true) end)
      create(nil, "加入售卖名单", nil, nil, "button", function() host:EditRule("custom", false) end)
      create(nil, "移出售卖名单", nil, nil, "button", function() host:EditRule("custom", true) end)
      create(nil, "查看全部模块", nil, nil, "button", function() host:Open() end)
      host.summary = MakeSummary(this, -235)
      this:SetHeight(650)
      host:RefreshSummary()
    end)
    local group = gui.frames[self.title]
    local area = group.area
    local show, hide = area:GetScript("OnShow"), area:GetScript("OnHide")
    area:SetScript("OnShow", function()
      if show then show() end
      host:Expand(); host:Sync()
    end)
    area:SetScript("OnHide", function()
      if hide then hide() end
      host:RestoreSize()
    end)
    local allArea = group[self.all].area
    local allShow = allArea:GetScript("OnShow")
    allArea:SetScript("OnShow", function()
      if allShow then allShow() end
      if host.content and host:IsEnabled() and AutomatonPfUIBridge then
        if Automaton then Automaton:CreateMainWindow() end
        AutomatonPfUIBridge:Attach(host.content)
      end
    end)
    local merchantArea = group[self.merchant].area
    local merchantShow = merchantArea:GetScript("OnShow")
    merchantArea:SetScript("OnShow", function()
      if merchantShow then merchantShow() end
      host:RefreshSummary()
    end)
    self.guiReady = true
    if self.pendingPage then local page = self.pendingPage; self.pendingPage = nil; self:OpenPage(page) end
  end
  local showGUI = pfUI.ShowGUI
  if showGUI then
    function pfUI:ShowGUI()
      local result = showGUI(self)
      host:BuildGUI()
      return result
    end
  end
  local driver = CreateFrame("Frame")
  host.driver = driver
  driver:RegisterEvent("PLAYER_LOGIN")
  driver:RegisterEvent("PLAYER_ENTERING_WORLD")
  driver:RegisterEvent("ADDON_LOADED")
  driver:SetScript("OnEvent", function()
    attempts = 0
    host:BuildGUI(); host:Sync()
    driver:SetScript("OnUpdate", host.Tick)
  end)
  function host.Tick()
    if (driver.nextTick or 0) > GetTime() then return end
    driver.nextTick = GetTime() + .25
    attempts = attempts + 1
    host:BuildGUI()
    if host:Sync() or attempts >= 40 then driver:SetScript("OnUpdate", nil) end
  end
  host:Config()
  host:BuildGUI()
  driver:SetScript("OnUpdate", host.Tick)
end)
