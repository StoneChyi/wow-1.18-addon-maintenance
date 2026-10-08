pfUI.addonskinner:RegisterSkin("InstanceJournal", function()
  local api = pfUI.api
  local StripTextures = api.StripTextures
  local CreateBackdrop = api.CreateBackdrop
  local SkinCloseButton = api.SkinCloseButton
  local SkinButton = api.SkinButton
  local SkinScrollbar = api.SkinScrollbar
  local SkinDropDown = api.SkinDropDown
  local SkinArrowButton = api.SkinArrowButton
  local GetStringColor = api.GetStringColor

  local function BtnTextWidth(btn, fallback)
    fallback = fallback or 40
    if not btn then return fallback end
    if btn.GetTextWidth then
      local w = btn:GetTextWidth()
      if w and w > 0 then return w end
    end
    local fs = btn.GetFontString and btn:GetFontString()
    if fs and fs.GetStringWidth then
      local w = fs:GetStringWidth()
      if w and w > 0 then return w end
    end
    return fallback
  end

  local function SyncBackdropColors(src, dst)
    if not src or not dst then return end
    if src.GetBackdropColor and dst.SetBackdropColor then
      local r, g, b, a = src:GetBackdropColor()
      if r then dst:SetBackdropColor(r, g, b, a or 1) end
    end
    if src.GetBackdropBorderColor and dst.SetBackdropBorderColor then
      local r, g, b, a = src:GetBackdropBorderColor()
      if r then dst:SetBackdropBorderColor(r, g, b, a or 1) end
    end
  end

  local SetHighlight = api.SetHighlight

  local function PanelBackdropFill()
    local br, bg, bb, ba = GetStringColor(pfUI_config.appearance.border.background)
    br, bg, bb, ba = tonumber(br) or 0.1, tonumber(bg) or 0.1, tonumber(bb) or 0.12, tonumber(ba) or 0.85
    return br, bg, bb, math.min(ba, 0.9)
  end

  local function ScrubSideTabTextures(tab)
    if not tab or not tab.GetRegions then return end
    for _, v in ipairs({ tab:GetRegions() }) do
      if v and v.SetTexture and v.GetObjectType then
        local ot = v:GetObjectType()
        if ot and string.lower(ot) == "texture" then
          if (not tab.icon or v ~= tab.icon) and (not tab.activeGlow or v ~= tab.activeGlow) then
            v:SetTexture(nil)
            v:Hide()
          end
        end
      end
    end
  end

  local function FinishInfoSideTab(tab, isActive)
    if not tab then return end
    ScrubSideTabTextures(tab)
    tab:SetNormalTexture("")
    tab:SetPushedTexture("")
    tab:SetHighlightTexture("")
    if tab.activeGlow then
      tab.activeGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
      tab.activeGlow:SetTexCoord(0, 1, 0, 1)
      tab.activeGlow:SetBlendMode("ADD")
      tab.activeGlow:SetVertexColor(0.9, 0.78, 0.3, 0.3)
      if isActive then
        tab.activeGlow:Show()
      else
        tab.activeGlow:Hide()
      end
    end
    if not tab.__pfui_side_tab then
      CreateBackdrop(tab, nil, nil, 0)
      tab.__pfui_side_tab = true
    end
    if tab.backdrop then
      tab.backdrop:EnableMouse(false)
      local refdd = IJ_ClassFilterDropDown or IJ_SlotFilterDropDown
      if refdd and refdd.backdrop then
        SyncBackdropColors(refdd.backdrop, tab.backdrop)
      else
        local br, bg, bb, ba = PanelBackdropFill()
        tab.backdrop:SetBackdropColor(br, bg, bb, ba * 0.92)
      end
      local er, eg, eb, ea = GetStringColor(pfUI_config.appearance.border.color)
      er, eg, eb, ea = tonumber(er) or 0.3, tonumber(eg) or 0.3, tonumber(eb) or 0.3, tonumber(ea) or 1
      if isActive then
        local _, class = UnitClass("player")
        local c = RAID_CLASS_COLORS[class]
        if c then
          tab.backdrop:SetBackdropBorderColor(c.r, c.g, c.b, 1)
        else
          tab.backdrop:SetBackdropBorderColor(er, eg, eb, ea)
        end
      else
        tab.backdrop:SetBackdropBorderColor(er, eg, eb, ea)
      end
    end
    if IJ_EncounterPanel then
      tab:SetFrameLevel(IJ_EncounterPanel:GetFrameLevel() + 25)
    else
      tab:SetFrameLevel(70)
    end
    tab:EnableMouse(true)
  end

  local function FixNavAnchors()
    if not IJ_HomeButton or not IJ_InstanceNavBar then return end
    local gap = 4
    if IJ_HomeButton then
      local hbw = BtnTextWidth(IJ_HomeButton, 40) + 12
      IJ_HomeButton:SetWidth(math.max(hbw, 48))
    end
    if IJ_InstanceNavBar:IsShown() and IJ_InstanceNavBar.text then
      local tw = IJ_InstanceNavBar.text:GetStringWidth()
      if tw and tw > 0 then
        if IJ_InstanceNavBar.body then
          IJ_InstanceNavBar.body:SetWidth(tw + 8)
        end
        IJ_InstanceNavBar:SetWidth(tw + 32)
      end
      IJ_InstanceNavBar:ClearAllPoints()
      IJ_InstanceNavBar:SetPoint("LEFT", IJ_HomeButton, "RIGHT", gap, 0)
      IJ_InstanceNavBar:SetFrameLevel(57)
      if IJ_InstanceNavBar.arrow then
        IJ_InstanceNavBar.arrow:ClearAllPoints()
        IJ_InstanceNavBar.arrow:SetPoint("RIGHT", IJ_InstanceNavBar, "RIGHT", -4, 0)
        IJ_InstanceNavBar.arrow:SetFrameLevel(59)
      end
    end
    if IJ_BossNavBar and IJ_BossNavBar:IsShown() and IJ_BossNavBar.text then
      local tw = IJ_BossNavBar.text:GetStringWidth()
      if tw and tw > 0 then
        if IJ_BossNavBar.body then
          IJ_BossNavBar.body:SetWidth(tw + 8)
        end
        IJ_BossNavBar:SetWidth(tw + 32)
      end
      IJ_BossNavBar:ClearAllPoints()
      if IJ_InstanceNavBar:IsShown() then
        IJ_BossNavBar:SetPoint("LEFT", IJ_InstanceNavBar, "RIGHT", gap, 0)
      else
        IJ_BossNavBar:SetPoint("LEFT", IJ_HomeButton, "RIGHT", gap, 0)
      end
      IJ_BossNavBar:SetFrameLevel(58)
      if IJ_BossNavBar.arrow then
        IJ_BossNavBar.arrow:ClearAllPoints()
        IJ_BossNavBar.arrow:SetPoint("RIGHT", IJ_BossNavBar, "RIGHT", -4, 0)
        IJ_BossNavBar.arrow:SetFrameLevel(60)
      end
    end
  end

  local function SkinNavBar(btn)
    if not btn then return end
    for _, key in ipairs({ "body", "tip", "bodyPushed", "tipPushed", "hl", "sel" }) do
      local r = btn[key]
      if r and r.SetAlpha then r:SetAlpha(0) end
    end
    StripTextures(btn)
    btn:SetNormalTexture("")
    btn:SetPushedTexture("")
    btn:SetHighlightTexture("")
    if btn.SetBackdrop then btn:SetBackdrop(nil) end
    if not btn.__pfui_ij_nav2 then
      -- Match SkinDropDown: no transp cap (.75 made fills too transparent vs filter dropdowns).
      CreateBackdrop(btn)
      btn.__pfui_ij_nav2 = true
    end
    local ref = IJ_ClassFilterDropDown or IJ_SlotFilterDropDown
    if ref and ref.backdrop and btn.backdrop then
      SyncBackdropColors(ref.backdrop, btn.backdrop)
      btn.backdrop:ClearAllPoints()
      btn.backdrop:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
      btn.backdrop:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
      btn.backdrop:EnableMouse(false)
    end
    if SetHighlight then
      pcall(SetHighlight, btn)
    end
    if btn.text and btn.text.SetTextColor then
      btn.text:SetTextColor(0.35, 0.82, 0.38)
    end
    if btn.GetFontString and btn:GetFontString() then
      btn:GetFontString():SetTextColor(0.35, 0.82, 0.38)
    end
    if btn.arrow and SkinArrowButton then
      SkinArrowButton(btn.arrow, "down", 16)
      btn.arrow:ClearAllPoints()
      btn.arrow:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
      if btn.arrow.EnableMouse then
        btn.arrow:EnableMouse(true)
      end
      if btn.arrow.icon then
        btn.arrow.icon:SetVertexColor(1, 0.9, 0.1)
        btn.arrow.icon:SetAlpha(0.8)
      end
      if btn.arrow.pficonfade then
        btn.arrow.pficonfade:SetScript("OnUpdate", nil)
      end
    end
    if btn.EnableMouse then
      btn:EnableMouse(true)
    end
    if btn.HitRect then
      btn.HitRect:EnableMouse(false)
    end
  end

  local function SkinBossRow(btn)
    if not btn then return end
    btn:SetNormalTexture("")
    btn:SetPushedTexture("")
    if btn.customHighlight then
      btn.customHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
      btn.customHighlight:SetTexCoord(0, 1, 0, 1)
      btn.customHighlight:SetBlendMode("ADD")
      btn.customHighlight:SetVertexColor(0.9, 0.78, 0.3, 0.22)
    end
    if not btn.__pfui_boss_skinned then
      CreateBackdrop(btn, nil, nil, 0)
      btn.__pfui_boss_skinned = true
    end
    if btn.backdrop then
      btn.backdrop:SetBackdropColor(0, 0, 0, 0.18)
    end
    if SetHighlight then
      pcall(SetHighlight, btn)
    end
  end

  local function SkinLootRow(row)
    if not row then return end
    if row.background then
      row.background:SetTexture(nil)
      row.background:Hide()
    end
    if not row.__pfui_loot_skinned then
      CreateBackdrop(row, nil, nil, 0)
      row.__pfui_loot_skinned = true
    end
    if row.backdrop then
      row.backdrop:SetBackdropColor(0, 0, 0, 0.15)
    end
    if row.slotText then
      row.slotText:SetTextColor(0.35, 0.82, 0.38)
    end
    if row.typeText then
      row.typeText:SetTextColor(0.35, 0.82, 0.38)
    end
  end

  local IJ_ABIL_ROW_H = 29
  local IJ_ABIL_OVERLAP = 6

  local function SkinAbilityOverviewRow(row)
    if not row or not row.hitBox then return end
    for _, key in ipairs({ "bgLeft", "bgRight", "bgCentral", "expandedBgBottom" }) do
      local t = row[key]
      if t then
        t:SetTexture(nil)
        t:Hide()
      end
    end
    local eb = row.expandedBg
    if eb then
      local w = eb:GetWidth()
      local h = eb:GetHeight()
      eb:SetTexture(nil)
      eb:Hide()
      if row.effectText and row.effectText:IsShown() then
        if not row.__pfui_expand_anchor then
          row.__pfui_expand_anchor = CreateFrame("Frame", nil, row)
        end
        local a = row.__pfui_expand_anchor
        a:ClearAllPoints()
        a:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -IJ_ABIL_ROW_H + IJ_ABIL_OVERLAP)
        a:SetWidth((w and w > 0) and w or 200)
        a:SetHeight(math.max(h or 1, 1))
        row.effectText:ClearAllPoints()
        row.effectText:SetPoint("TOPLEFT", a, "TOPLEFT", 18, -8)
      end
    end
    if row.hitBox.GetRegions then
      for _, v in ipairs({ row.hitBox:GetRegions() }) do
        if v and v.GetObjectType and string.lower(v:GetObjectType()) == "texture" then
          v:SetTexture(nil)
          v:Hide()
        end
      end
    end
    if not row.__pfui_ab_backdrop then
      CreateBackdrop(row, nil, nil, 0)
      row.__pfui_ab_backdrop = true
    end
    if row.backdrop then
      row.backdrop:ClearAllPoints()
      row.backdrop:SetPoint("TOPLEFT", row, "TOPLEFT", -2, 2)
      row.backdrop:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 2, -2)
      row.backdrop:EnableMouse(false)
      local br, bg, bb, ba = PanelBackdropFill()
      row.backdrop:SetBackdropColor(br, bg, bb, 0.4)
      row.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
    end
    row.hitBox:SetScript("OnMouseDown", nil)
    row.hitBox:SetScript("OnMouseUp", nil)
    if row.effectText then
      row.effectText:SetTextColor(0.35, 0.82, 0.38)
    end
  end

  local function SkinAllAbilityOverviewRows()
    if not IJ_AbilityRows then return end
    for _, row in pairs(IJ_AbilityRows) do
      if row and row:IsShown() then
        SkinAbilityOverviewRow(row)
      end
    end
  end

  local function SkinGridButtons()
    if not IJ_InstanceButtons then return end
    for _, btn in ipairs(IJ_InstanceButtons) do
      if btn and btn.bg then
        btn:SetBackdrop(nil)
        if not btn.__pfui_skinned then
          CreateBackdrop(btn, nil, nil, 0)
          btn.__pfui_skinned = true
        end
        if btn.backdrop then
          btn.backdrop:SetBackdropColor(0, 0, 0, 0)
        end
        btn.bg:Show()
      end
    end
  end

  local function ResizeBottomTabs()
    local t1 = IJ_InstanceJournalFrameTab1
    local t2 = IJ_InstanceJournalFrameTab2
    local frame = IJ_InstanceJournalFrame
    if not t1 or not t2 or not frame then return end
    local pad = 10
    local h = 22
    local w1 = BtnTextWidth(t1, 48) + pad
    local w2 = BtnTextWidth(t2, 48) + pad
    t1:SetWidth(w1)
    t1:SetHeight(h)
    t2:SetWidth(w2)
    t2:SetHeight(h)
    t1:ClearAllPoints()
    t1:SetPoint("CENTER", frame, "BOTTOMLEFT", 60, 57)
    t2:ClearAllPoints()
    t2:SetPoint("LEFT", t1, "RIGHT", 4, 0)
    local h1 = getglobal(t1:GetName() .. "HighlightTexture")
    local h2 = getglobal(t2:GetName() .. "HighlightTexture")
    if h1 and h1.SetWidth then h1:SetWidth(w1) end
    if h2 and h2.SetWidth then h2:SetWidth(w2) end
  end

  local function Apply()
    local frame = IJ_InstanceJournalFrame
    if not frame then return end

    local l, r, t, b = 0, 34, 0, 75
    if frame.GetHitRectInsets then
      l, r, t, b = frame:GetHitRectInsets()
    end

    StripTextures(frame)
    CreateBackdrop(frame, nil, nil, .75)
    if frame.SetHitRectInsets then
      frame:SetHitRectInsets(l, r, t, b)
    end

    if frame.backdrop then
      frame.backdrop:ClearAllPoints()
      frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
      frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 70)
      frame.backdrop:EnableMouse(false)
    end

    if IJ_InstanceJournalFrameCloseButton and frame.backdrop then
      SkinCloseButton(IJ_InstanceJournalFrameCloseButton, frame.backdrop, -6, -6)
    end

    if IJ_SearchBar then
      StripTextures(IJ_SearchBar, true, "BACKGROUND")
      CreateBackdrop(IJ_SearchBar, nil, true)
      if IJ_SearchBarClearButton then SkinButton(IJ_SearchBarClearButton) end
      IJ_SearchBar:SetFrameLevel(65)
    end

    local dropdowns = {
      "IJ_ContinentFilterDropDown",
      "IJ_InstanceNavDropDown",
      "IJ_BossNavDropDown",
      "IJ_SlotFilterDropDown",
      "IJ_ClassFilterDropDown",
    }
    for _, name in ipairs(dropdowns) do
      local dd = getglobal(name)
      if dd and SkinDropDown then
        StripTextures(dd)
        pcall(SkinDropDown, dd)
      end
    end

    if IJ_EncounterPanelBookBackgroundLeft then IJ_EncounterPanelBookBackgroundLeft:Hide() end
    if IJ_EncounterPanelBookBackgroundRight then IJ_EncounterPanelBookBackgroundRight:Hide() end
    if IJ_EncounterPanel then
      CreateBackdrop(IJ_EncounterPanel, nil, nil, .75)
      if IJ_EncounterPanel.backdrop then
        IJ_EncounterPanel.backdrop:EnableMouse(false)
        IJ_EncounterPanel.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
      end
    end

    if IJ_MapButtonBackground then IJ_MapButtonBackground:Hide() end
    if IJ_MapButtonButton then
      IJ_MapButtonButton:SetNormalTexture("")
      IJ_MapButtonButton:SetPushedTexture("")
      IJ_MapButtonButton:SetHighlightTexture("")
    end
    if IJ_MapButton then
      CreateBackdrop(IJ_MapButton, nil, nil, 0)
      if IJ_MapButton.backdrop then
        IJ_MapButton.backdrop:SetBackdropColor(0, 0, 0, 0)
        IJ_MapButton.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
        IJ_MapButton.backdrop:EnableMouse(false)
      end
      IJ_MapButton:EnableMouse(false)
    end
    if IJ_MapButtonButton then
      CreateBackdrop(IJ_MapButtonButton, nil, nil, 0)
      if IJ_MapButtonButton.backdrop then
        IJ_MapButtonButton.backdrop:SetBackdropColor(0, 0, 0, 0)
        IJ_MapButtonButton.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
        IJ_MapButtonButton.backdrop:EnableMouse(false)
      end
    end

    if IJ_NavbarShadow then IJ_NavbarShadow:Hide() end

    if IJ_HomeButton then
      StripTextures(IJ_HomeButton)
      IJ_HomeButton:SetNormalTexture("")
      IJ_HomeButton:SetPushedTexture("")
      IJ_HomeButton:SetHighlightTexture("")
      IJ_HomeButton:SetDisabledTexture("")
      if IJ_HomeButton.SetBackdrop then
        IJ_HomeButton:SetBackdrop(nil)
      end
      if not IJ_HomeButton.__pfui_home_ddlike then
        CreateBackdrop(IJ_HomeButton, nil, nil, .75)
        IJ_HomeButton.__pfui_home_ddlike = true
      end
      local href = IJ_ClassFilterDropDown or IJ_SlotFilterDropDown
      if href and href.backdrop and IJ_HomeButton.backdrop then
        SyncBackdropColors(href.backdrop, IJ_HomeButton.backdrop)
        IJ_HomeButton.backdrop:ClearAllPoints()
        IJ_HomeButton.backdrop:SetPoint("TOPLEFT", IJ_HomeButton, "TOPLEFT", 2, -2)
        IJ_HomeButton.backdrop:SetPoint("BOTTOMRIGHT", IJ_HomeButton, "BOTTOMRIGHT", -2, 2)
        IJ_HomeButton.backdrop:EnableMouse(false)
      end
      if SetHighlight then
        pcall(SetHighlight, IJ_HomeButton)
      end
      if IJ_HomeButton.GetFontString and IJ_HomeButton:GetFontString() then
        IJ_HomeButton:GetFontString():SetPoint("LEFT", 8, 0)
        IJ_HomeButton:GetFontString():SetTextColor(0.35, 0.82, 0.38)
      end
      local hbw = BtnTextWidth(IJ_HomeButton, 40) + 12
      IJ_HomeButton:SetWidth(math.max(hbw, 48))
      IJ_HomeButton:SetHeight(24)
      IJ_HomeButton:SetFrameLevel(56)
      if IJ_HomeButton.EnableMouse then
        IJ_HomeButton:EnableMouse(true)
      end
      if IJ_HomeButton.HitRect then
        IJ_HomeButton.HitRect:EnableMouse(false)
      end
    end

    if frame.pfuiNavStrip then
      frame.pfuiNavStrip:Hide()
      frame.pfuiNavStrip:EnableMouse(false)
      if frame.pfuiNavStrip.backdrop then
        frame.pfuiNavStrip.backdrop:Hide()
        frame.pfuiNavStrip.backdrop:EnableMouse(false)
      end
    end

    SkinNavBar(IJ_InstanceNavBar)
    SkinNavBar(IJ_BossNavBar)
    FixNavAnchors()

    if IJ_HomeButton then
      IJ_HomeButton:SetFrameLevel(56)
    end

    for _, tname in ipairs({ "IJ_InstanceJournalFrameTab1", "IJ_InstanceJournalFrameTab2" }) do
      local tab = getglobal(tname)
      if tab then
        StripTextures(tab)
        CreateBackdrop(tab, nil, nil, .75)
      end
    end
    ResizeBottomTabs()

    local scrolls = { IJ_InstanceGridScroll, IJ_OverviewScroll, IJ_SearchScroll }
    for _, sf in ipairs(scrolls) do
      if sf and sf.bar and sf.bar.GetName then
        local barName = sf.bar:GetName()
        if barName and string.find(barName, "ScrollBar") and getglobal(barName .. "ScrollUpButton") then
          StripTextures(sf)
          SkinScrollbar(sf.bar)
        end
      end
    end

    SkinGridButtons()

    if IJ_BossButtons then
      for _, btn in ipairs(IJ_BossButtons) do
        if btn and btn:IsShown() then SkinBossRow(btn) end
      end
    end
    if IJ_LootRows then
      for _, row in pairs(IJ_LootRows) do
        if row and row:IsShown() then SkinLootRow(row) end
      end
    end

    SkinAllAbilityOverviewRows()

    if IJ_EncounterPanel and IJ_EncounterPanel:IsShown() and type(IJ_UpdateInfoTabs) == "function" then
      IJ_UpdateInfoTabs()
    end
  end

  if type(IJ_PopulateInstanceGrid) == "function" and not _G.__pfui_ij_grid_wrapped then
    _G.__pfui_ij_grid_wrapped = true
    local oldGrid = IJ_PopulateInstanceGrid
    IJ_PopulateInstanceGrid = function()
      oldGrid()
      SkinGridButtons()
    end
  end

  if type(IJ_PopulateBossList) == "function" and not _G.__pfui_ij_boss_wrapped then
    _G.__pfui_ij_boss_wrapped = true
    local oldBoss = IJ_PopulateBossList
    IJ_PopulateBossList = function(instance)
      oldBoss(instance)
      if IJ_BossButtons then
        for _, btn in ipairs(IJ_BossButtons) do
          if btn and btn:IsShown() then SkinBossRow(btn) end
        end
      end
    end
  end

  if type(IJ_PopulateLoot) == "function" and not _G.__pfui_ij_loot_wrapped then
    _G.__pfui_ij_loot_wrapped = true
    local oldLoot = IJ_PopulateLoot
    IJ_PopulateLoot = function(a, b)
      oldLoot(a, b)
      if IJ_LootRows then
        for _, row in pairs(IJ_LootRows) do
          if row and row:IsShown() then SkinLootRow(row) end
        end
      end
    end
  end

  if type(IJ_PopulateOverview) == "function" and not _G.__pfui_ij_overview_wrapped then
    _G.__pfui_ij_overview_wrapped = true
    local oldOverview = IJ_PopulateOverview
    IJ_PopulateOverview = function(boss)
      oldOverview(boss)
      SkinAllAbilityOverviewRows()
    end
  end

  if type(IJ_UpdateNavBars) == "function" and not _G.__pfui_ij_navbars_wrapped then
    _G.__pfui_ij_navbars_wrapped = true
    local oldNav = IJ_UpdateNavBars
    IJ_UpdateNavBars = function()
      oldNav()
      FixNavAnchors()
    end
  end

  if type(IJ_UpdateTabVisuals) == "function" and not _G.__pfui_ij_tabvis_wrapped then
    _G.__pfui_ij_tabvis_wrapped = true
    local oldTabVis = IJ_UpdateTabVisuals
    IJ_UpdateTabVisuals = function(tabName, isActive)
      oldTabVis(tabName, isActive)
      FinishInfoSideTab(getglobal(tabName), isActive)
    end
  end

  Apply()

  if IJ_InstanceJournalFrame and not IJ_InstanceJournalFrame.__pfui_ij_onshow_wrapped then
    local oldOnShow = IJ_InstanceJournalFrame:GetScript("OnShow")
    IJ_InstanceJournalFrame:SetScript("OnShow", function()
      if oldOnShow then oldOnShow() end
      Apply()
    end)
    IJ_InstanceJournalFrame.__pfui_ij_onshow_wrapped = true
  end
end)
