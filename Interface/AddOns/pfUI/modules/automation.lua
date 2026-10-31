-- Native pfUI settings; the Automaton engine and its saved data remain intact.
pfUI:RegisterModule("automation", "vanilla", function()
  local host = { title = "自动化", general = "管理", all = "功能设置", merchant = "商人服务", pages = {} }
  pfUI.automation = host
  local input = { query = "", category = "all", visibility = "all", item = "" }
  local categories = { all = "全部功能", merchant = "物品与交易", quest = "任务与升级",
    party = "组队与社交", combat = "战斗与移动", interface = "界面与提示", misc = "其他便利功能" }
  local categoryMap = {}
  local categoryNames = {
    merchant = "AutoNeed AutoOpenBag Discard LootBOP MailTo MasterLootRemind Purchases SendRollItem shiqu sTrade",
    quest = "ExpBar NewLevelFrame QuestAnnouncer QuestAutomation QuestItemBar Trainer",
    party = "1invall AutoShout Follow Group InterPlayerLink Invite Loner pfQuestSendLink Queue Ready Summon Xguild",
    combat = "AlertCombat CancelBuff CancelTiger CDSafe Dismount KneelToQueen PicoPoisons ProcDoc RandomMount Range RangeController Release Rez ShaguStance Stand TSTargetMark WorldBuffs Wuss",
    interface = "Boomtime ErrClear Filter HideActionBarEndCaps Lern2Spell OmniCC Plates S_ActionCount S_ItemLinktoenUS SelfName Tooltip",
  }
  for category, names in pairs(categoryNames) do
    for name in string.gfind(names, "%S+") do categoryMap[name] = category end
  end
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
    local bridge = _G.AutomatonPfUIBridge
    if not bridge then return false end
    if not self:IsEnabled() then
      if bridge.host then bridge:Release() end
      return true
    end
    local ready = bridge:Acquire(self)
    if Automaton and Automaton.mainFrame then Automaton.mainFrame:Hide() end
    return ready
  end
  function host:QueueRefresh()
    self.refreshPending = true
    if self.driver then self.driver:SetScript("OnUpdate", host.Tick) end
  end
  function host:OpenPage(page)
    if self:IsEnabled() and Automaton and Automaton.mainFrame then Automaton.mainFrame:Hide() end
    if not pfUI.gui and pfUI.ShowGUI then pfUI:ShowGUI() end
    self:BuildGUI()
    if not pfUI.gui or not self.guiReady then self.pendingPage = page; return end
    pfUI.gui:Show()
    local parent = pfUI.gui.frames[self.title]
    if parent then parent:Click(); if parent[page] then parent[page]:Click() end end
    self:RefreshPage(page)
  end
  function host:Open() self:OpenPage(self.all) end
  function host:OpenVendor() self:OpenPage(self.merchant) end
  function host:SelectModule(name)
    if name == "Repair" or name == "Sell" then self:OpenVendor(); return end
    self:Config().selected = name
    if self:IsReady() then
      Automaton.selectedModule = name
      Automaton.db.char.lastModule = name
    end
    self:Open()
  end
  function host:ModuleList(filtered)
    local list, ranks = {}, {}
    if not self:IsReady() then return list end
    for i, name in ipairs(Automaton.db.char.moduleOrder or {}) do ranks[name] = i end
    local query = string.lower(input.query)
    for name, module in pairs(Automaton.modules) do
      if type(module._options) == "table" and name ~= "Repair" and name ~= "Sell" then
        local show = true
        if filtered then
          local text = string.lower(name .. " " .. (module.modulename or "") .. " " .. (module.moduledesc or ""))
          local hidden = Automaton:IsModuleHidden(name)
          show = (input.category == "all" or (categoryMap[name] or "misc") == input.category)
            and (query == "" or string.find(text, query, 1, true))
            and (input.visibility == "all" or (input.visibility == "shown" and not hidden)
              or (input.visibility == "hidden" and hidden)
              or (input.visibility == "enabled" and Automaton:IsModuleActive(name)))
        end
        if show then table.insert(list, { name = name, module = module }) end
      end
    end
    table.sort(list, function(a,b)
      local ar, br = ranks[a.name], ranks[b.name]
      if ar and br and ar ~= br then return ar < br end
      if ar and not br then return true end
      if br and not ar then return false end
      return a.name < b.name
    end)
    return list
  end
  function host:MoveModule(name, delta)
    local list = self:ModuleList(false)
    for i, entry in ipairs(list) do
      local nextIndex = i + delta
      if entry.name == name and nextIndex > 0 and nextIndex <= table.getn(list) then
        list[i], list[nextIndex] = list[nextIndex], list[i]
        local order = {}
        for _, item in ipairs(list) do table.insert(order, item.name) end
        -- Merchant modules still exist in the independent fallback list.
        table.insert(order, "Repair"); table.insert(order, "Sell")
        Automaton.db.char.moduleOrder = order
        return
      end
    end
  end
  function host:GeneralOptions()
    local options = {
      enabled = { type = "toggle", name = "在 pfUI 中管理自动化", order = 1,
        get = function() return host:IsEnabled() end,
        set = function(value) host:Config().enabled = value and "1" or "0"; host:Sync() end },
      intro = Description("功能开关和详细选项使用 pfUI 的设置控件。原有模块配置继续保留。", 2),
    }
    if self:IsReady() then
      options.scope = { type = "text", name = "模块开关保存范围", order = 3,
        validate = { char = "当前角色", account = "账号共享" },
        get = function() return Automaton:GetModuleScope() end,
        set = function(value) Automaton:ApplyModuleScope(value) end,
        desc = "切换时保留当前模块开关状态。修理与售卖使用 pfUI 自己的配置。" }
      options.visibility = Description("菜单隐藏只影响显示，不会停用功能。在功能设置中可以查看隐藏模块。", 4)
      options.features = { type = "execute", name = "功能设置", order = 5, func = function() host:Open() end }
      options.vendor = { type = "execute", name = "商人服务", order = 6, func = function() host:OpenVendor() end }
    else
      options.missing = Description("Automatonex 尚未加载。请在角色插件列表中保留启用 Automatonex。", 3)
    end
    if not self:IsEnabled() then
      options.fallback = Description("统一管理已关闭。工具箱恢复原来的商人开关；新售卖名单仍保留在 pfUI。", 7)
      options.open = { type = "execute", name = "打开独立工具箱", order = 8,
        func = function() if Automaton then Automaton:ToggleMainWindow() end end }
    end
    return options
  end
  function host:FeatureOptions()
    if not self:IsReady() then return { missing = Description("等待 Automatonex 完成加载。") } end
    if not self:IsEnabled() then
      return { disabled = Description("请先在管理页面开启“在 pfUI 中管理自动化”。"),
        manage = { type = "execute", name = "打开管理设置", order = 2, func = function() host:OpenPage(host.general) end } }
    end
    local options = {
      query = { type = "text", name = "搜索功能", order = 1, get = function() return input.query end,
        set = function(value) input.query = value end, desc = "按名称或说明搜索，按回车应用。" },
      category = { type = "text", name = "功能分类", order = 2, validate = categories,
        get = function() return input.category end, set = function(value) input.category = value end },
      visibility = { type = "text", name = "显示范围", order = 3,
        validate = { all = "全部（含隐藏）", shown = "菜单可见", hidden = "菜单隐藏", enabled = "已启用" },
        get = function() return input.visibility end, set = function(value) input.visibility = value end },
    }
    local list, choices = self:ModuleList(true), {}
    for i, entry in ipairs(list) do
      local state = Automaton:IsModuleActive(entry.name) and "开启" or "关闭"
      choices[entry.name] = string.format("%02d  %s · %s", i, entry.module.modulename or entry.name, state)
    end
    if table.getn(list) == 0 then options.empty = Description("没有符合条件的模块。修理和售卖请使用商人服务页面。", 4); return options end
    local selected = self:Config().selected or Automaton.db.char.lastModule
    if not choices[selected] then selected = list[1].name end
    self:Config().selected = selected
    local module = Automaton.modules[selected]
    Automaton.selectedModule = selected
    options.selected = { type = "text", name = "选择功能", order = 4, validate = choices,
      get = function() return host:Config().selected end,
      set = function(value) host:Config().selected = value; Automaton.selectedModule = value; Automaton.db.char.lastModule = value end }
    options.description = Description(module.moduledesc or "", 5)
    options.visible = { type = "toggle", name = "在常用菜单中显示", order = 6,
      desc = "隐藏不代表停用；显示范围选择“全部”或“菜单隐藏”可再次找到。",
      get = function() return not Automaton:IsModuleHidden(selected) end,
      set = function(value)
        Automaton.db.char.hiddenModules = Automaton.db.char.hiddenModules or {}
        Automaton.db.char.hiddenModules[selected] = not value or nil
      end }
    options.order = { type = "group", name = "菜单顺序", order = 7, args = {}, buttons = {
      { name = "上移", func = function() host:MoveModule(selected, -1) end },
      { name = "下移", func = function() host:MoveModule(selected, 1) end },
    } }
    options.module = { type = "group", name = module.modulename or selected, order = 8, args = module._options }
    return options
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
    local options
    if page == self.general then options = self:GeneralOptions()
    elseif page == self.merchant then options = self:MerchantOptions()
    else options = self:FeatureOptions() end
    renderer:Render(content, { name = page, _options = options }, function() host:QueueRefresh() end)
    self.rendering = nil
  end
  function host:RefreshVisible()
    local group = pfUI.gui and pfUI.gui.frames[self.title]
    if not group then return end
    for page in pairs(self.pages) do
      local tab = group[page]
      if tab and tab.area:IsShown() then self:RefreshPage(page) end
    end
  end
  function host:BuildGUI()
    if self.guiReady or not pfUI.gui or not pfUI.gui.CreateGUIEntry or not pfUI.automationOptions then return end
    local gui = pfUI.gui
    for _, title in ipairs({ self.general, self.all, self.merchant }) do
      local page = title
      gui.CreateGUIEntry(self.title, page, function()
        host.pages[page] = this
        host:RefreshPage(page)
      end)
      local area = gui.frames[self.title][page].area
      local onShow, onHide = area:GetScript("OnShow"), area:GetScript("OnHide")
      area:SetScript("OnShow", function()
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
