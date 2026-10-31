-- Runtime ownership and UI hosting. Original saved variables stay authoritative
-- for independent fallback; no lease is written into AceDB disabledModules.
local A = Automaton
if not A then return end
local B = { leases = {}, originals = {}, host = nil }
AutomatonPfUIBridge = B
local function Name(module) return type(module) == "table" and module.name or module end
local flags = { Repair = "autorepair", Sell = "autosell" }
local originalActive, originalToggle = A.IsModuleActive, A.ToggleModuleActive
local originalWindow, originalCreate = A.ToggleMainWindow, A.CreateMainWindow

function B:Vendor()
  return pfUI and pfUI.autovendor
end
function B:SavedActive(name)
  return originalActive(A, name) and true or false
end
function B:Stop(name)
  local module = A.modules and A.modules[name]
  if module and self.originals[name] and self.originals[name].disable then
    self.originals[name].disable(module)
  end
end

for name, flag in pairs(flags) do
  local module = A.modules and A.modules[name]
  if module then
    B.originals[name] = { enable = module.OnEnable, disable = module.OnDisable, options = module._options }
    local key = name
    module.OnEnable = function(self)
      if B.leases[key] then B:Stop(key); return end
      local enable = B.originals[key].enable
      if enable then return enable(self) end
    end
  end
end

function A:IsModuleActive(module)
  local name = Name(module)
  if B.leases[name] then
    return pfUI_config and pfUI_config.global and pfUI_config.global[flags[name]] == "1"
  end
  return originalActive(self, module)
end
function A:ToggleModuleActive(module, state)
  local name = Name(module)
  if B.leases[name] then
    if state == nil then state = not self:IsModuleActive(module) end
    pfUI_config.global[flags[name]] = state and "1" or "0"
    B:Stop(name)
    return state
  end
  return originalToggle(self, module, state)
end

function B:Acquire(host)
  self.host = host
  local vendor = self:Vendor()
  if not vendor or not A.db or not A.db.char then return false end
  for name in pairs(flags) do
    local module = A.modules and A.modules[name]
    if not module or not module._options or not module._optionOrder then return false end
  end
  if not vendor:ImportLegacyRules() or not vendor.ready then return false end
  if vendor.CanOwnLegacy and not vendor:CanOwnLegacy() then return false end
  vendor:SetLegacyFallback(true)
  local db = host:Config()
  if not db.merchantMigrated then
    db.merchantBefore = { autorepair = pfUI_config.global.autorepair, autosell = pfUI_config.global.autosell }
    for name, flag in pairs(flags) do
      if self:SavedActive(name) then pfUI_config.global[flag] = "1" end
    end
    db.merchantMigrated = "1"
  end
  for name, flag in pairs(flags) do
    local module = A.modules and A.modules[name]
    if module then
      self.leases[name] = true
      self:Stop(name)
      if not self.originals[name].captured then
        self.originals[name].options = module._options
        self.originals[name].order = module._optionOrder
        self.originals[name].captured = true
      end
      -- All merchant edits use the pfUI source of truth; the old page must not
      -- silently mutate a legacy list which no longer drives item sales.
      local key = name
      module._options = {
        enabled = { type = "toggle", name = "启用", desc = "由 pfUI 商人服务统一执行", order = 1,
          get = function() return A:IsModuleActive(key) end,
          set = function(v) A:ToggleModuleActive(key, v) end },
        pfui = { type = "execute", name = "打开统一商人设置", desc = "保留名单、自定义售卖与修理设置", order = 2,
          func = function() if B.host then B.host:OpenVendor() end end },
      }
      module._optionOrder = {
        { key = "enabled", order = 1, data = module._options.enabled },
        { key = "pfui", order = 2, data = module._options.pfui },
      }
    end
  end
  vendor:SetLegacyFallback(false)
  self.active = true
  return true
end

function B:Release()
  local vendor = self:Vendor()
  if vendor and vendor.SetLegacyFallback then vendor:SetLegacyFallback(true) end
  for name in pairs(flags) do
    local module = A.modules and A.modules[name]
    if self.leases[name] and module then
      self.leases[name] = nil
      module._options = self.originals[name].options
      module._optionOrder = self.originals[name].order
      self.originals[name].captured = nil
      if self:SavedActive(name) and self.originals[name].enable then self.originals[name].enable(module) end
    end
  end
  self.active = nil
  self:Detach()
  self.host = nil
end

function B:Attach(parent)
  if not parent or not A.mainFrame then return end
  local f = A.mainFrame
  if not f.pfuiHostState then
    local state = { parent = f:GetParent(), scale = f:GetScale(), strata = f:GetFrameStrata(), points = {},
      dragStart = f:GetScript("OnDragStart"), dragStop = f:GetScript("OnDragStop"), key = f:GetScript("OnKeyDown") }
    local okLeft, left = pcall(function() return f:GetLeft() end)
    local okBottom, bottom = pcall(function() return f:GetBottom() end)
    if okLeft and type(left) == "number" and okBottom and type(bottom) == "number" then state.left = left; state.bottom = bottom end
    for i = 1, f:GetNumPoints() do state.points[i] = { f:GetPoint(i) } end
    f.pfuiHostState = state
  end
  f:Hide()
  f:SetParent(parent)
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
  f:SetScale(1)
  f:SetFrameStrata("DIALOG")
  f:SetScript("OnDragStart", nil)
  f:SetScript("OnDragStop", nil)
  f:SetScript("OnKeyDown", function() if arg1 == "ESCAPE" and pfUI and pfUI.gui then pfUI.gui:Hide() end end)
  if f.closeBtn then f.closeBtn:Hide() end
  if f.zoomOutBtn then f.zoomOutBtn:Hide() end
  if f.zoomInBtn then f.zoomInBtn:Hide() end
  if f.titleBg then f.titleBg:Hide() end
  if f.titleText then f.titleText:Hide() end
  f:Show()
  A:PopulateModuleList()
  if A.selectedModule then A:SelectModule(A.selectedModule) end
end
function B:Detach()
  local f = A.mainFrame
  local state = f and f.pfuiHostState
  if not state then return end
  f:Hide()
  f:SetParent(state.parent)
  f:ClearAllPoints()
  local positioned
  if state.parent == UIParent and state.left and state.bottom then
    positioned = pcall(function() f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", state.left, state.bottom) end)
  else
    for _, point in ipairs(state.points) do
      if type(point[1]) == "string" and point[2] and type(point[3]) == "string" and type(point[4]) == "number" and type(point[5]) == "number" then
        positioned = pcall(function() f:SetPoint(unpack(point)) end) or positioned
      end
    end
  end
  if not positioned then f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
  f:SetScale(state.scale)
  f:SetFrameStrata(state.strata)
  f:SetScript("OnDragStart", state.dragStart)
  f:SetScript("OnDragStop", state.dragStop)
  f:SetScript("OnKeyDown", state.key)
  if f.closeBtn then f.closeBtn:Show() end
  if f.zoomOutBtn then f.zoomOutBtn:Show() end
  if f.zoomInBtn then f.zoomInBtn:Show() end
  if f.titleBg then f.titleBg:Show() end
  if f.titleText then f.titleText:Show() end
  f.pfuiHostState = nil
end
function A:CreateMainWindow()
  originalCreate(self)
  if B.host and B.host.content then B:Attach(B.host.content) end
end
function A:ToggleMainWindow()
  if B.host and B.host:IsEnabled() then return B.host:Open() end
  return originalWindow(self)
end
-- Zoom reconstructs the original window. The embedded layout owns its size.
local oldScale, oldRebuild = A.SetUIScale, A.RebuildMainWindow
if oldScale then
  function A:SetUIScale(scale)
    if B.host and B.host.content then return end
    return oldScale(self, scale)
  end
end
if oldRebuild then
  function A:RebuildMainWindow()
    local saved = self.mainFrame and self.mainFrame.pfuiHostState
    if saved then B:Detach(); self.mainFrame:Show() end
    local result = oldRebuild(self)
    if B.host and B.host.content then
      if saved and self.mainFrame then self.mainFrame.pfuiHostState = saved end
      B:Attach(B.host.content)
    end
    return result
  end
end
