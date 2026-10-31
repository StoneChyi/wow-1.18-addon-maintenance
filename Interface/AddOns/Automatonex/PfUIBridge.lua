-- Runtime ownership and UI hosting. Original saved variables stay authoritative
-- for independent fallback; no lease is written into AceDB disabledModules.
local A = Automaton
if not A then return end
local B = { leases = {}, originals = {}, host = nil }
AutomatonPfUIBridge = B
local function Name(module) return type(module) == "table" and module.name or module end
local flags = { Repair = "autorepair", Sell = "autosell" }
local originalActive, originalToggle = A.IsModuleActive, A.ToggleModuleActive
local originalWindow = A.ToggleMainWindow

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
  self.host = nil
end

-- Commands and dynamic option updates use native pfUI pages. The independent
-- window stays untouched (same parent, anchors and scale) for a later fallback.
local function ManagedHost()
  local host = B.host or (pfUI and pfUI.automation)
  if host and host:IsEnabled() then return host end
end
function A:ToggleMainWindow()
  local host = ManagedHost()
  if host then return host:Open() end
  return originalWindow(self)
end
local originalRefresh = A.RefreshModuleSettings
if originalRefresh then
  function A:RefreshModuleSettings(name)
    local host = ManagedHost()
    if host then
      host:QueueRefresh()
      if not self.mainFrame or not self.mainFrame:IsShown() then return end
    end
    return originalRefresh(self, name)
  end
end
local originalOptions = A.modulePrototype and A.modulePrototype.RegisterOptions
if originalOptions then
  function A.modulePrototype:RegisterOptions(options)
    local result = originalOptions(self, options)
    local host = ManagedHost()
    if host then
      if B.leases[self.name] then
        B.originals[self.name].options = self._options
        B.originals[self.name].order = self._optionOrder
        B:Acquire(host)
      end
      host:QueueRefresh()
    end
    return result
  end
end
