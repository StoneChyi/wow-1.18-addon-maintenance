-- Native pfUI settings; the Automaton engine and its saved data remain intact.
pfUI:RegisterModule("automation", "vanilla", function()
  local host = { title = "自动化", general = "管理", detail = "模块设置", merchant = "商人服务", pages = {} }
  pfUI.automation = host
  host.all = host.detail -- existing toolbox commands still use Open().
  host.pageOrder = { host.general, host.merchant, host.detail }
  local input = { item = "", query = "", visibility = "all" }
  local dailyOrder = {
    "Superwow", "QuestAutomation", "AutoNeed", "MasterLootRemind", "CDSafe",
    "Summon", "RandomMount", "QuestItemBar", "CleanChat", "Tooltip",
    "TSTargetMark", "CancelBuff", "Lern2Spell", "Group", "Invite", "Ready",
    "Rez", "AutoShout", "sTrade", "LootBOP", "AutoOpenBag", "Purchases",
    "ShiQu", "MailTo", "Release", "Dismount", "follow", "Trainer", "WorldBuffs",
    "AlertCombat", "Range", "RangeController", "QuestAnnouncer", "ExpBar", "InterPlayerLink",
  }
  local dailyRanks = {}
  for i, name in ipairs(dailyOrder) do dailyRanks[name] = i end
  local attempts, startup = 0, true
  local function Description(text, order) return { type = "description", name = text, order = order or 1 } end
  function host:Config()
    C.automation = C.automation or {}
    if C.automation.enabled == nil then C.automation.enabled = "1" end
    return C.automation
  end
  function host:IsEnabled() return self:Config().enabled == "1" end
  function host:Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfUI|r " .. message) end
  end
  function host:IsReady() return Automaton and Automaton.db and Automaton.db.char and Automaton.modules end
  function host:Sync()
    local integrationsReady = true
    for _, integration in pairs(pfUI.automationIntegrations or {}) do
      if integration.Sync and integration:Sync(self:IsEnabled()) == false then integrationsReady = false end
    end
    local bridge = _G.AutomatonPfUIBridge
    if not bridge then return false end
    if not self:IsEnabled() then
      if bridge.host then bridge:Release() end
      return true
    end
    local ready = bridge:Acquire(self)
    if Automaton and Automaton.mainFrame then Automaton.mainFrame:Hide() end
    return ready and integrationsReady
  end
  function host:QueueRefresh()
    self.refreshPending = true
    if self.driver then self.driver:SetScript("OnUpdate", host.Tick) end
  end
  function host:CanLeave()
    local renderer, content = pfUI.automationOptions, self.pages[self.activePage or ""]
    return not content or not renderer or not renderer.CommitPending or renderer:CommitPending(content)
  end
  function host:UpdateNavigation()
    if self.guiReady and pfUI.automationNavigation then
      local selected = self.activePage == self.detail and self.selectedModule or self.activePage
      pfUI.automationNavigation:Update(self, self:NavigationEntries(false), selected)
    end
  end
  function host:OpenPage(page)
    if not self:CanLeave() then return false end
    if self:IsEnabled() and Automaton and Automaton.mainFrame then Automaton.mainFrame:Hide() end
    if not pfUI.gui and pfUI.ShowGUI then pfUI:ShowGUI() end
    self:BuildGUI()
    if not pfUI.gui or not self.guiReady then self.pendingPage = page; return false end
    local group = pfUI.gui.frames[self.title]
    if not group or not group[page] then return false end
    self.activePage = page
    pfUI.gui:Show()
    group:Click(); group[page]:Click()
    self:RefreshPage(page)
    return true
  end
  function host:Open()
    local selected = self.selectedModule or self:Config().selected
    for _, entry in ipairs(self:NavigationEntries(false)) do
      if entry.name == selected then return self:SelectModule(selected) end
    end
    local entries = self:NavigationEntries(false)
    if entries[1] then return self:SelectModule(entries[1].name) end
    return self:OpenPage(self.general)
  end
  function host:OpenVendor() return self:OpenPage(self.merchant) end
  function host:SelectModule(name)
    if not self:CanLeave() then return false end
    if name == "Repair" or name == "Sell" then return self:OpenVendor() end
    local integration = pfUI.automationIntegrations and pfUI.automationIntegrations[name]
    if integration and (integration.managed or integration.active) and integration.OpenSettings then
      integration:OpenSettings()
      return true
    end
    if not self:IsReady() or not Automaton.modules[name] or not Automaton.modules[name]._options then
      return self:OpenPage(self.general)
    end
    local changed = self.selectedModule ~= name
    self.selectedModule, self:Config().selected = name, name
    Automaton.selectedModule, Automaton.db.char.lastModule = name, name
    if not self:OpenPage(self.detail) then return false end
    local content = self.pages[self.detail]
    if changed and content then
      local scroll = content.parent
      scroll:SetVerticalScroll(0)
      if scroll.UpdateScrollState then scroll:UpdateScrollState() end
      if pfUI.automationOptions.UpdateViewport then pfUI.automationOptions:UpdateViewport(content) end
    end
    if pfUI.automationNavigation and pfUI.automationNavigation.EnsureVisible then
      pfUI.automationNavigation:EnsureVisible(self, name)
    end
    return true
  end
  function host:SortMode()
    local mode = self:Config().navSort
    if mode == "custom" or mode == "name" or mode == "enabled" then return mode end
    return "daily"
  end
  function host:NavigationEntries(includeHidden)
    local entries, ranks, mode = {}, {}, self:SortMode()
    if not self:IsReady() then return entries end
    for i, name in ipairs(self:Config().navOrder or {}) do if not ranks[name] then ranks[name] = i end end
    for name, module in pairs(Automaton.modules) do
      local integration = pfUI.automationIntegrations and pfUI.automationIntegrations[name]
      local native = integration and (integration.managed or integration.active) and integration.OpenSettings
      if (type(module._options) == "table" or native) and name ~= "Repair" and name ~= "Sell"
        and (includeHidden or not Automaton:IsModuleHidden(name)) then
        local label = native and integration.title or module.modulename or name
        table.insert(entries, { name = name, module = module, label = label,
          description = module.moduledesc or "", native = native and true or false,
          rank = dailyRanks[name] or 1000, custom = ranks[name] or 10000,
          active = mode == "enabled" and Automaton:IsModuleActive(name) and true or false })
      end
    end
    table.sort(entries, function(a,b)
      if mode == "custom" and a.custom ~= b.custom then return a.custom < b.custom end
      if mode == "enabled" and a.active ~= b.active then return a.active end
      if mode ~= "name" and a.rank ~= b.rank then return a.rank < b.rank end
      local al, bl = string.lower(a.label), string.lower(b.label)
      if al ~= bl then return al < bl end
      return a.name < b.name
    end)
    return entries
  end
  function host:NavigationPosition(name)
    for i, entry in ipairs(self:NavigationEntries(true)) do if entry.name == name then return i end end
    return 1
  end
  function host:MoveModule(name, position)
    local entries, order, found = self:NavigationEntries(true), {}, nil
    for _, entry in ipairs(entries) do
      if entry.name == name then found = true else table.insert(order, entry.name) end
    end
    if not found then return end
    position = math.max(1, math.min(table.getn(entries), math.floor(tonumber(position) or 1)))
    table.insert(order, position, name)
    -- Keep unavailable modules at the tail so a temporarily missing module does
    -- not lose its saved identity. Independent toolbox ordering is untouched.
    for _, prior in ipairs(self:Config().navOrder or {}) do
      local exists
      for _, current in ipairs(order) do if prior == current then exists = true; break end end
      if not exists then table.insert(order, prior) end
    end
    self:Config().navOrder, self:Config().navSort = order, "custom"
    self:QueueRefresh()
  end
  function host:SetModuleHidden(name, hidden)
    if not self:CanLeave() then return false end
    if not self:IsReady() or not Automaton.modules[name] then return false end
    Automaton.db.char.hiddenModules = Automaton.db.char.hiddenModules or {}
    Automaton.db.char.hiddenModules[name] = hidden and true or nil
    if hidden and self.selectedModule == name and self.activePage == self.detail then self:OpenPage(self.general) end
    self:QueueRefresh()
    return true
  end
  function host:GeneralOptions()
    local options = {
      enabled = { type = "toggle", name = "在 pfUI 中管理自动化", order = 1,
        get = function() return host:IsEnabled() end,
        set = function(value) host:Config().enabled = value and "1" or "0"; host:Sync() end },
      intro = Description("左侧点击模块名称直接设置；在这里管理模块顺序及显示。隐藏只影响入口，功能开关保持原状。", 2),
    }
    if self:IsReady() then
      options.scope = { type = "text", name = "模块开关保存范围", order = 3,
        validate = { char = "当前角色", account = "账号共享" },
        get = function() return Automaton:GetModuleScope() end,
        set = function(value) Automaton:ApplyModuleScope(value) end,
        desc = "切换时保留当前模块开关状态。修理与售卖使用 pfUI 自己的配置。" }
      options.navSort = { type = "text", name = "模块排序", order = 10,
        validate = { daily = "日常优先", custom = "自定义顺序", name = "名称顺序", enabled = "已启用优先" },
        get = function() return host:SortMode() end,
        set = function(value) host:Config().navSort = value end }
      options.query = { type = "text", name = "查找模块", order = 11,
        get = function() return input.query end, set = function(value) input.query = value end }
      options.visibility = { type = "text", name = "显示范围", order = 12,
        validate = { all = "全部（含隐藏）", shown = "列表可见", hidden = "列表隐藏" },
        get = function() return input.visibility end, set = function(value) input.visibility = value end }
      options.orderHelp = Description("修改排列位置会切换为自定义顺序，按回车保存。位置按完整模块列表计算，隐藏模块也保留位置。", 13)
      local entries, query = self:NavigationEntries(true), string.lower(input.query)
      local count = table.getn(entries)
      for i, entry in ipairs(entries) do
        local name = entry.name
        local hidden = Automaton:IsModuleHidden(name)
        local text = string.lower(name .. " " .. entry.label .. " " .. entry.description)
        if (query == "" or string.find(text, query, 1, true))
          and (input.visibility == "all" or (input.visibility == "hidden" and hidden) or (input.visibility == "shown" and not hidden)) then
          options["nav_" .. name] = { type = "group", name = entry.label, moduleName = name, order = 20+i, args = {
            visible = { type = "toggle", name = "在模块列表和常用菜单中显示", order = 1,
              get = function() return not Automaton:IsModuleHidden(name) end,
              set = function(value) host:SetModuleHidden(name, not value) end },
            position = { type = "range", name = "排列位置", order = 2, min = 1, max = count, step = 1,
              get = function() return host:NavigationPosition(name) end,
              set = function(value) host:MoveModule(name, value) end },
            open = { type = "execute", name = entry.native and "打开原生设置" or "打开模块设置", order = 3,
              func = function() host:SelectModule(name) end },
          } }
        end
      end
    else options.missing = Description("Automatonex 尚未加载。请在角色插件列表中保留启用 Automatonex。", 3) end
    if not self:IsEnabled() then
      options.fallback = Description("统一管理已关闭。工具箱恢复原来的商人开关；新售卖名单仍保留在 pfUI。", 7)
      options.open = { type = "execute", name = "打开独立工具箱", order = 8,
        func = function() if Automaton then Automaton:ToggleMainWindow() end end }
    end
    return options
  end
  function host:ModuleOptions(name)
    if not self:IsReady() then return { missing = Description("等待 Automatonex 完成加载。") } end
    if not self:IsEnabled() then
      return { disabled = Description("请先在管理页面开启“在 pfUI 中管理自动化”。"),
        manage = { type = "execute", name = "打开管理设置", order = 2, func = function() host:OpenPage(host.general) end } }
    end
    local integration = name and pfUI.automationIntegrations and pfUI.automationIntegrations[name]
    if integration and (integration.managed or integration.active) and integration.OpenSettings then
      return { native = Description("此模块已合入 pfUI 原生设置。"),
        open = { type = "execute", name = "打开原生设置", order = 2, func = function() host:SelectModule(name) end } }
    end
    local module = name and Automaton.modules[name]
    if not module or not module._options then return { empty = Description("请从左侧选择模块。") } end
    local args = {}
    for key, option in pairs(module._options) do args[key] = option end
    if module.moduledesc and module.moduledesc ~= "" then args.__pfui_description = Description(module.moduledesc, -10) end
    if Automaton:IsModuleHidden(name) then
      args.__pfui_hidden = Description("此模块已从列表隐藏，可在管理页恢复显示。", -9)
    end
    return { module = { type = "group", name = module.modulename or name, moduleName = name, order = 1, args = args } }
  end
  function host:EditRule(kind, remove, selectedId)
    local vendor = pfUI.autovendor
    local id = tonumber(selectedId or input.item)
    if not id or id < 1 or id ~= math.floor(id) then self:Print("请输入有效的物品 ID。"); return end
    if not vendor or not vendor.ready then self:Print("商人服务尚未准备好，请登录完成后再试。"); return end
    local name
    if not remove then name = GetItemInfo(id) or ("物品 " .. id) end
    local ok, reason = vendor:SetRule(kind, id, name)
    if ok == false then self:Print(reason or "规则未保存。"); return end
    self:QueueRefresh()
  end
  function host:MerchantOptions()
    local options = {
      repair = { type = "toggle", name = "自动修理", order = 1,
        get = function() return C.global.autorepair == "1" end,
        set = function(value) C.global.autorepair = value and "1" or "0" end },
      sell = { type = "toggle", name = "自动售卖灰色和指定物品", order = 2,
        get = function() return C.global.autosell == "1" end,
        set = function(value) C.global.autosell = value and "1" or "0" end },
      explain = Description("保留名单优先于自定义售卖。只输入明确需要处理的物品 ID。", 3),
      item = { type = "text", name = "物品 ID", order = 4, get = function() return input.item end,
        set = function(value) input.item = value end },
      addKeep = { type = "execute", name = "加入保留名单", order = 5, func = function() host:EditRule("ignore", false) end },
      removeKeep = { type = "execute", name = "移出保留名单", order = 6, func = function() host:EditRule("ignore", true) end },
      addSell = { type = "execute", name = "加入售卖名单", order = 7, func = function() host:EditRule("custom", false) end },
      removeSell = { type = "execute", name = "移出售卖名单", order = 8, func = function() host:EditRule("custom", true) end },
    }
    local bridge, vendor = _G.AutomatonPfUIBridge, pfUI.autovendor
    if bridge and not bridge.active then
      options.state = Description("工具箱商人服务尚未交接，原工具箱按原设置运行。", 0)
    end
    if not vendor or not vendor.GetRules then options.missing = Description("pfUI 商人服务未加载。", 9); return options end
    local rules = vendor:GetRules()
    for i, kind in ipairs({ "ignore", "custom" }) do
      local args, ids = {}, {}
      for id in pairs(rules[kind] or {}) do table.insert(ids, tostring(id)) end
      table.sort(ids, function(a,b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
      for index, id in ipairs(ids) do
        local key, itemId = kind, id
        local name = rules[kind][id] or rules[kind][tonumber(id)]
        args[id] = { type = "execute", name = tostring(name) .. " (" .. id .. ")", buttonText = "移除", order = index,
          func = function() host:EditRule(key, true, itemId) end }
      end
      if table.getn(ids) == 0 then args.empty = Description("暂无物品") end
      options[kind] = { type = "group", name = kind == "ignore" and "保留名单" or "自定义售卖", order = 8 + i, args = args }
    end
    return options
  end
  function host:RefreshPage(page)
    local content, renderer = self.pages[page], pfUI.automationOptions
    if not content or not renderer or self.rendering then return end
    self.rendering = true
    local ok, reason = pcall(function()
      local options
      if page == self.general then options = self:GeneralOptions()
      elseif page == self.merchant then options = self:MerchantOptions()
      else options = self:ModuleOptions(self.selectedModule) end
      renderer:Render(content, { name = page, _options = options }, function() host:QueueRefresh() end)
    end)
    self.rendering = nil
    if not ok then
      if self.lastRenderError ~= tostring(reason) then
        self:Print("自动化设置页加载失败（" .. page .. "）：" .. tostring(reason))
      end
      self.lastRenderError = tostring(reason)
    else
      self.lastRenderError = nil
    end
    self:UpdateNavigation()
  end
  function host:RefreshVisible()
    local group = pfUI.gui and pfUI.gui.frames[self.title]
    if not group then return end
    self:UpdateNavigation()
    for page in pairs(self.pages) do
      local tab = group[page]
      if tab and tab.area:IsShown() then self:RefreshPage(page) end
    end
  end
  function host:BuildGUI()
    if self.guiReady or not pfUI.gui or not pfUI.gui.CreateGUIEntry or not pfUI.automationOptions then return end
    local gui = pfUI.gui
    for _, title in ipairs(self.pageOrder) do
      local page = title
      gui.CreateGUIEntry(self.title, page, function()
        host.pages[page] = this
        host:RefreshPage(page)
      end)
      local area = gui.frames[self.title][page].area
      local onShow, onHide = area:GetScript("OnShow"), area:GetScript("OnHide")
      area:SetScript("OnShow", function()
        host.activePage = page
        if onShow then onShow() end
        host:RefreshPage(page)
      end)
      area:SetScript("OnHide", function()
        local content = host.pages[page]
        if content and pfUI.automationOptions then pfUI.automationOptions:Suspend(content) end
        if onHide then onHide() end
      end)
    end
    self.guiReady = true
    if pfUI.automationNavigation then pfUI.automationNavigation:Attach(self, gui.frames[self.title]) end
    self:UpdateNavigation()
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
    attempts = 0; startup = true
    host:BuildGUI(); host:QueueRefresh()
  end)
  function host.Tick()
    if host.refreshPending then
      host.refreshPending = nil
      host:RefreshVisible()
    end
    if startup and (driver.nextTick or 0) <= GetTime() then
      driver.nextTick = GetTime() + .25
      attempts = attempts + 1
      host:BuildGUI()
      if host:Sync() or attempts >= 40 then startup = false; host:RefreshVisible() end
    end
    if not startup and not host.refreshPending then driver:SetScript("OnUpdate", nil) end
  end
  host:Config()
  host:BuildGUI()
  driver:SetScript("OnUpdate", host.Tick)
end)
