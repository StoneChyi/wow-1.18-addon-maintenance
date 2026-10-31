-- pfUI owns merchant actions; Automatonex remains a read-only migration source.
pfUI:RegisterModule("autovendor", "vanilla:tbc", function ()
  local rawborder, border = GetBorderSize()
  local bpad = rawborder > 1 and border - GetPerfectPixel() or GetPerfectPixel()
  local module = { ready = false, eventsReady = false }
  pfUI.autovendor = module
  local processed = {}

  local function ItemID(value)
    local id = tonumber(value)
    if not id or id ~= id or id < 1 or id > 2147483647 or math.floor(id) ~= id then return nil end
    return tostring(id)
  end

  function module:GetRules()
    if type(C.autovendor_rules) ~= "table" then C.autovendor_rules = {} end
    local db = C.autovendor_rules
    if type(db.ignore) ~= "table" then db.ignore = {} end
    if type(db.custom) ~= "table" then db.custom = {} end
    if type(db.edited) ~= "table" then db.edited = {} end
    db.version = 1
    return db
  end

  function module:SetRule(kind, id, name)
    if kind ~= "ignore" and kind ~= "custom" then return false end
    id = ItemID(id)
    if not id then return false end
    if name ~= nil and type(name) ~= "string" and name ~= true then return false end
    local db = self:GetRules()
    -- Tombstones keep an intentional deletion from being undone by a late import.
    db.edited[id] = true
    db[kind][id] = name
    return true
  end

  function module:RefreshLegacyEngine()
    if self.legacyEngine ~= Automaton then
      self.legacyEngine = Automaton
      self.ownershipGranted = false
    end
  end

  function module:SetLegacyFallback(fallback)
    self:RefreshLegacyEngine()
    self.legacyFallback = fallback and true or false
    self.ownershipGranted = not fallback and self.ready == true
    if fallback and self.frame then self.frame:Hide() end
    if not fallback and self.Resume then self:Resume() end
    return self.ownershipGranted
  end

  function module:CanExecute()
    self:RefreshLegacyEngine()
    if not Automaton then return true end
    -- Migration only prepares data. The bridge must first stop both old engines
    -- and explicitly grant ownership, including after a late engine load.
    return self.ready and self.ownershipGranted and not self.legacyFallback
  end

  function module:ImportLegacyRules()
    self:RefreshLegacyEngine()
    local db = self:GetRules()
    if db.imported then
      self.ready = self.eventsReady
      return true
    end
    local legacy
    if Automaton and type(Automaton.AcquireDBNamespace) == "function" then
      local ok, namespace = pcall(Automaton.AcquireDBNamespace, Automaton, "Sell")
      if ok and type(namespace) == "table" and type(namespace.profile) == "table" then
        legacy = namespace.profile
      end
    end
    if not legacy then
      self.ready = false
      return false, "Automatonex settings are not ready"
    end
    -- AceDB defaults are empty tables. Do not mark a partially initialized source imported.
    if type(legacy.ignore) ~= "table" or type(legacy.custom) ~= "table" then
      self.ready = false
      return false, "Automatonex sale lists are not ready"
    end
    -- Historical numeric arrays are not item-ID dictionaries. Wait for the
    -- legacy module's own format migration rather than treating indices as IDs.
    for _, kind in ipairs({"ignore", "custom"}) do
      for id in pairs(legacy[kind]) do
        if type(id) ~= "string" then
          self.ready = false
          return false, "Automatonex sale lists need their legacy format migration"
        end
      end
    end
    local existing = {}
    for id in pairs(db.ignore) do existing[tostring(id)] = true end
    for id in pairs(db.custom) do existing[tostring(id)] = true end
    for _, kind in ipairs({"ignore", "custom"}) do
      for id, name in pairs(legacy[kind]) do
        local key = ItemID(id)
        if key and not existing[key] and not db.edited[key]
          and (type(name) == "string" or name == true) then
          db[kind][key] = name
        end
      end
    end
    db.imported = true
    self.ready = self.eventsReady
    return true
  end

  function module:CanOwnLegacy()
    return self.ready == true
  end

  local function CanSell(link, quality)
    if type(link) ~= "string" or type(quality) ~= "number" or quality < 0 then return false end
    local _, _, rawID = string.find(link, "item:(%d+):")
    local id = ItemID(rawID)
    if not id then return false end
    local db = module:GetRules()
    if db.ignore[id] or db.ignore[tonumber(id)] then return false end
    if db.custom[id] or db.custom[tonumber(id)] then return true end
    return quality == 0 and string.find(link, "|cff9d9d9d", 1, true) ~= nil
  end
  module.CanSell = function(self, link, quality) return CanSell(link, quality) end

  local function MerchantOpen()
    return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1
  end

  local function FindItem()
    local waiting = false
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        local texture, count, locked, quality = GetContainerItemInfo(bag, slot)
        if texture and count and count > 0 and CanSell(link, quality) then
          local key = bag .. ":" .. slot
          local fingerprint = link .. ":" .. count
          if processed[key] ~= fingerprint then
            if locked then waiting = true else return bag, slot, link, fingerprint end
          end
        end
      end
    end
    return nil, nil, nil, nil, waiting
  end

  local function RepairItems()
    if not module:CanExecute() or not MerchantOpen() or not CanMerchantRepair() then return end
    local cost, possible = GetRepairAllCost()
    if possible and cost > 0 then
      if GetMoney() < cost then
        DEFAULT_CHAT_FRAME:AddMessage(GetLocale and GetLocale() == "zhCN" and "没有足够的金币修理。" or T["Not enough money to repair."])
        return
      end
      RepairAllItems()
      DEFAULT_CHAT_FRAME:AddMessage(T["Your items have been repaired for"] .. " " .. CreateGoldString(cost))
    end
  end

  local autovendor = CreateFrame("Frame", "pfMoneyUpdate", nil)
  module.frame = autovendor
  autovendor:Hide()
  autovendor:SetScript("OnShow", function()
    this.count = 0
    this.gold = GetMoney()
  end)
  autovendor:SetScript("OnUpdate", function()
    if not module:CanExecute() or not this.merchant or not MerchantOpen()
      or (this.runMode == "auto" and C.global.autosell ~= "1") then this:Hide(); return end
    if (this.tick or 0) > GetTime() then return end
    this.tick = GetTime() + .1
    -- Never clear or overwrite an item the player is holding on the cursor.
    if CursorHasItem() then return end
    if Automaton and not module:ImportLegacyRules() then return end
    local bag, slot, link, fingerprint, waiting = FindItem()
    if not bag then
      if not waiting then this:Hide() end
      return
    end
    -- Fresh identity/lock/quality check immediately before the native sale call.
    local current = GetContainerItemLink(bag, slot)
    local texture, count, locked, quality = GetContainerItemInfo(bag, slot)
    if current ~= link or not texture or locked or not count
      or current .. ":" .. count ~= fingerprint or not CanSell(current, quality)
      or CursorHasItem() or not this.merchant or not MerchantOpen() then return end
    processed[bag .. ":" .. slot] = fingerprint
    this.count = this.count + 1
    UseContainerItem(bag, slot)
  end)
  autovendor:SetScript("OnHide", function()
    if (this.count or 0) > 0 then
      local income = GetMoney() - (this.gold or GetMoney())
      if income > 0 then
        DEFAULT_CHAT_FRAME:AddMessage(T["Your vendor trash has been sold and you earned"] .. " " .. CreateGoldString(income))
      end
      this.count = 0
    end
  end)

  function module:Resume()
    if not self:CanExecute() or not autovendor.merchant or not MerchantOpen() then return end
    if C.global.autorepair == "1" and not autovendor.repairAttempted then
      autovendor.repairAttempted = true
      RepairItems()
    end
    if C.global.autosell == "1" then
      local bag, slot, link, fingerprint, waiting = FindItem()
      if bag or waiting then
        autovendor.runMode = "auto"
        autovendor:Show()
      end
    end
  end

  -- Keep one session across duplicate MERCHANT_SHOW events. An attempted stack
  -- is never sold twice before a close/reopen, even while the server is lagging.
  autovendor:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" then
      module:ImportLegacyRules()
      return
    elseif event == "MERCHANT_CLOSED" then
      autovendor.merchant = nil
      autovendor:Hide()
      processed = {}
    elseif event == "MERCHANT_SHOW" then
      module:ImportLegacyRules()
      if not autovendor.merchant then
        processed = {}
        autovendor.merchant = true
        autovendor.repairAttempted = nil
      end
      module:Resume()
      if C.global.autosell == "1" then
        autovendor.button:Hide()
      else
        autovendor.button:Show()
      end
      MerchantRepairText:SetText("")
      autovendor.button:ClearAllPoints()
      if MerchantRepairItemButton:IsShown() then
        autovendor.button:SetPoint("RIGHT", MerchantRepairItemButton, "LEFT", -4*bpad, 0)
      else
        autovendor.button:SetPoint("RIGHT", MerchantBuyBackItemItemButton, "LEFT", -14, 0)
      end
    elseif event == "BAG_UPDATE" and autovendor.merchant and MerchantOpen()
      and C.global.autosell == "1" and FindItem() then
      module:Resume()
    end
    autovendor.button:Update()
  end)

  autovendor.button = CreateFrame("Button", "pfMerchantAutoVendorButton", MerchantFrame)
  autovendor.button:SetWidth(36)
  autovendor.button:SetHeight(36)
  autovendor.button.icon = autovendor.button:CreateTexture(nil, "ARTWORK")
  autovendor.button.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield")
  autovendor.button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(T["Sell Grey Items"])
    GameTooltip:AddLine(GetLocale and GetLocale() == "zhCN" and "包括自定义售卖名单；保留忽略名单中的物品。"
      or T["Includes your custom sale list; ignored items are kept."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  autovendor.button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  SkinButton(autovendor.button, nil, nil, nil, autovendor.button.icon)
  autovendor.button:SetScript("OnClick", function()
    if module:CanExecute() and autovendor.merchant and MerchantOpen() then
      autovendor.runMode = "manual"
      autovendor:Show()
    end
  end)
  autovendor.button.Update = function()
    local bag = FindItem()
    if module:CanExecute() and not autovendor:IsVisible() and bag then
      autovendor.button:Enable()
      autovendor.button.icon:SetDesaturated(false)
    else
      autovendor.button:Disable()
      autovendor.button.icon:SetDesaturated(true)
    end
  end

  local originalUpdate = MerchantFrame_Update
  function _G.MerchantFrame_Update()
    if MerchantFrame.selectedTab == 1 and C.global.autosell ~= "1" then
      autovendor.button:Show()
    else
      autovendor.button:Hide()
    end
    originalUpdate()
  end
  for _, name in ipairs({"MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE",
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD"}) do autovendor:RegisterEvent(name) end
  module.eventsReady = true
  module:ImportLegacyRules()
end)
