pfUI.addonskinner:RegisterSkin("AtlasQuest", function()
  -- upvalue the pfUI methods we use to avoid repeated lookups
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton,
    SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar,
    HookScript, hooksecurefunc, SkinDropDown, SkinSlider =
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton,
  penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar,
  penv.HookScript, penv.hooksecurefunc, penv.SkinDropDown, penv.SkinSlider

  local noop = function() end

  -- [reposition] Keep AtlasQuestFrame beside AtlasFrame WITHOUT overlap.
  -- Root cause of the overlap: AtlasQuest's own Left-side code uses
  --   SetPoint("RIGHT", AtlasFrame, "LEFT", 16, -10)   (positive gap => overlaps)
  -- and Atlas_OnShow does NOT position AQ at all on the Left side, so it falls
  -- back to the XML default offset (-556) which also overlaps ~14px.
  -- We hook Atlas_OnShow (runs AFTER AtlasQuest's own handler, which would
  -- otherwise overwrite our position every time Atlas opens) and re-anchor AQ
  -- with a NEGATIVE gap so it always sits fully outside AtlasFrame.
  local function getSide()
    -- Authoritative saved preference: AtlasQuest persists the side choice in
    --   AtlasQuest_Options[PlayerName]["ShownSide"]
    -- NOTE: AQRIGHTOption's XML has checked="true" by default and AtlasQuest's
    -- VARIABLES_LOADED never restores the checkbox from the saved option, so the
    -- checkbox state is WRONG after reload (always looks "Right"). That's why we
    -- must read the saved table, NOT the checkbox, to avoid reverting to Right.
    if AtlasQuest_Options then
      local pn = UnitName("player")
      local saved = AtlasQuest_Options[pn] and AtlasQuest_Options[pn]["ShownSide"]
      if saved == "Right" then return "Right" end
      if saved == "Left"  then return "Left"  end
    end
    if AQ_ShownSide == "Right" then return "Right" end
    if AQ_ShownSide == "Left"  then return "Left"  end
    if AQRIGHTOption and AQRIGHTOption:GetChecked() then return "Right" end
    return "Left"
  end

  local function reposition()
    if not AtlasFrame or not AtlasQuestFrame then return end
    if AtlasORAlphaMap and AtlasORAlphaMap ~= "Atlas" then return end
    local pref = getSide()
    AtlasQuestFrame:ClearAllPoints()
    if pref == "Right" then
      -- AQ flush to the RIGHT of AtlasFrame, tops aligned (0 gap, y = 0)
      AtlasQuestFrame:SetPoint("TOPLEFT", AtlasFrame, "TOPRIGHT", 0, 0)
    else
      -- AQ flush to the LEFT of AtlasFrame, tops aligned (0 gap, y = 0)
      AtlasQuestFrame:SetPoint("TOPRIGHT", AtlasFrame, "TOPLEFT", 0, 0)
    end
  end

  -->> AtlasQuestFrame (main panel)
  StripTextures(AtlasQuestFrame, nil, "ARTWORK")
  CreateBackdrop(AtlasQuestFrame, nil, nil, .75)

  -- Close button (full global name: AtlasQuestFrameCloseButton via $parentCloseButton)
  if AtlasQuestFrameCloseButton then
    AtlasQuestFrameCloseButton:SetText("")
    SkinCloseButton(AtlasQuestFrameCloseButton, AtlasQuestFrame.backdrop, -6, -6)
  end
  -- Fallback: some versions expose short global
  if CLOSEbutton and CLOSEbutton ~= AtlasQuestFrameCloseButton then
    CLOSEbutton:SetText("")
    SkinCloseButton(CLOSEbutton, AtlasQuestFrame.backdrop, -6, -6)
  end

  -- Faction toggle buttons (Horde / Alliance) — UICheckButtonTemplate shield icons
  if AtlasQuestFrameHordeButton then
    SkinCheckbox(AtlasQuestFrameHordeButton, 24)
    -- Force smaller size to fit neatly as faction icon
    AtlasQuestFrameHordeButton:SetWidth(24)
    AtlasQuestFrameHordeButton:SetHeight(24)
  end
  if AtlasQuestFrameAllianceButton then
    SkinCheckbox(AtlasQuestFrameAllianceButton, 24)
    AtlasQuestFrameAllianceButton:SetWidth(24)
    AtlasQuestFrameAllianceButton:SetHeight(24)
  end

  -- Story / Options buttons at bottom of main panel (OptionsButtonTemplate)
  if AtlasQuestFrameStoryButton then
    SkinButton(AtlasQuestFrameStoryButton)
  end
  if STORYbutton and STORYbutton ~= AtlasQuestFrameStoryButton then
    SkinButton(STORYbutton)
  end

  if AtlasQuestFrameOptionsButton then
    SkinButton(AtlasQuestFrameOptionsButton)
  end
  if OPTIONbutton and OPTIONbutton ~= AtlasQuestFrameOptionsButton then
    SkinButton(OPTIONbutton)
  end

  -->> AtlasQuestInsideFrame (detail popup)
  StripTextures(AtlasQuestInsideFrame)
  CreateBackdrop(AtlasQuestInsideFrame, nil, nil, .9)

  if AtlasQuestInsideFrameCloseButton then
    AtlasQuestInsideFrameCloseButton:SetText("")
    SkinCloseButton(AtlasQuestInsideFrameCloseButton, AtlasQuestInsideFrame.backdrop, -6, -6)
  end
  if CLOSEbutton2 and CLOSEbutton2 ~= AtlasQuestInsideFrameCloseButton then
    CLOSEbutton2:SetText("")
    SkinCloseButton(CLOSEbutton2, AtlasQuestInsideFrame.backdrop, -6, -6)
  end

  if CLOSEbutton3 then
    SkinButton(CLOSEbutton3)
  end

  -- Checkboxes in main panel
  if AQFinishedQuest then SkinCheckbox(AQFinishedQuest, 20) end
  if AQACB then SkinCheckbox(AQACB, 20) end
  if AQHCB then SkinCheckbox(AQHCB, 20) end

  -- Hook reposition on side-switch / mode-switch AND on every Atlas open.
  -- Atlas_OnShow is the one that would otherwise overwrite our position.
  hooksecurefunc("Atlas_OnShow", function()
    reposition()
  end, true)
  hooksecurefunc("AQ_AtlasOrAlphamap", function()
    reposition()
  end, true)
  hooksecurefunc("AQRIGHTOption_OnClick", function()
    reposition()
  end, true)
  hooksecurefunc("AQLEFTOption_OnClick", function()
    reposition()
  end, true)

  -->> Options frame
  StripTextures(AtlasQuestOptionFrame)
  CreateBackdrop(AtlasQuestOptionFrame, nil, nil, .75)
  if AQAutoshowOption then SkinCheckbox(AQAutoshowOption, 20) end
  if AQLEFTOption then SkinCheckbox(AQLEFTOption, 20) end
  if AQRIGHTOption then SkinCheckbox(AQRIGHTOption, 20) end
  if AQColourOption then SkinCheckbox(AQColourOption, 20) end
  if AQCheckQuestlogButton then SkinCheckbox(AQCheckQuestlogButton, 20) end
  if AQAutoQueryOption then SkinCheckbox(AQAutoQueryOption, 20) end
  if AQNoQuerySpamOption then SkinCheckbox(AQNoQuerySpamOption, 20) end
  if AQCompareTooltipOption then SkinCheckbox(AQCompareTooltipOption, 20) end
  if AQOptionCloseButton then SkinButton(AQOptionCloseButton) end

  -- Apply correct (non-overlapping) position immediately on skin load.
  reposition()

  pfUI.addonskinner:UnregisterSkin("AtlasQuest")
end)
