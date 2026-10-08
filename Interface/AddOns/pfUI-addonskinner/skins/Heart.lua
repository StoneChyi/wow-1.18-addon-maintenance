pfUI.addonskinner:RegisterSkin("Heart", function()
  -- 获取 pfUI 环境方法
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton,
    SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar,
    HookScript, hooksecurefunc, SkinDropDown, SkinSlider =
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton,
  penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar,
  penv.HookScript, penv.hooksecurefunc, penv.SkinDropDown, penv.SkinSlider

  -- ========== Heart_ClickFrame 美化 ==========
  if Heart_ClickFrame then
    Heart_ClickFrame:DisableDrawLayer("BACKGROUND")
    StripTextures(Heart_ClickFrame, true)
    CreateBackdrop(Heart_ClickFrame, nil, nil, .75)

    local closeBtn = getglobal("Heart_ClickFrameCloseButton")
    if closeBtn then SkinCloseButton(closeBtn, Heart_ClickFrame.backdrop, -6, -6) end

    for i = 1, 5 do
      local btn = getglobal("Heart_ClickFrameClass" .. i)
      if btn then SkinButton(btn) end
    end

    local rezBtn = getglobal("Heart_ClickFrameRezButton")
    local tankBtn = getglobal("Heart_ClickFrameTankButton")
    local setTVBtn = getglobal("Heart_ClickFrameSetTV")
    if rezBtn then SkinButton(rezBtn) end
    if tankBtn then SkinButton(tankBtn) end
    if setTVBtn then SkinButton(setTVBtn) end

    if Heart_GUIProfileDropDownMenu then
      SkinDropDown(Heart_GUIProfileDropDownMenu, nil, nil, nil, true)
    end

    local title = getglobal("Heart_ClickFrameTitle")
    if title then title:SetFontObject(GameFontNormal) end
  end

  -- ========== 主设置面板 Heart_GUI ==========
  if Heart_GUI then
    Heart_GUI:DisableDrawLayer("BACKGROUND")
    StripTextures(Heart_GUI, true)
    CreateBackdrop(Heart_GUI, nil, nil, .75)
    if Heart_GUICloseButton then
      SkinCloseButton(Heart_GUICloseButton, Heart_GUI.backdrop, -6, -6)
    end
    if Heart_GUIHeader then
      Heart_GUIHeader:SetFontObject(GameFontNormal)
    end

    -- 美化主面板的8个标签页按钮（增强纹理清除）
    for i = 1, 8 do
      local tab = getglobal("Heart_GUITab" .. i)
      if tab then
        StripTextures(tab, true)
        -- ★ 强制移除所有原版纹理（包括选中状态）
        for _, region in ipairs({tab:GetRegions()}) do
          if region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:Hide()
          end
        end
        SkinButton(tab)
        if tab:GetFontString() then
          tab:GetFontString():SetFontObject(GameFontNormal)
        end
      end
    end

    -- 美化选项按钮和新配置文件按钮
    if Heart_GUIOptButton then SkinButton(Heart_GUIOptButton) end
    if Heart_GUINewProfileButton then SkinButton(Heart_GUINewProfileButton) end

    -- 处理标签页内容面板
    local tabFrames = {
      Heart_GUIClasses, Heart_GUISettings, Heart_GUIPriorities,
      Heart_GUIRaid, Heart_GUIMouseKeys, Heart_GUIDisplay,
      Heart_GUIRez, Heart_GUIAdv
    }
    for _, frame in ipairs(tabFrames) do
      if frame then
        frame:DisableDrawLayer("BACKGROUND")
        StripTextures(frame, true)
        CreateBackdrop(frame, nil, nil, .5)
      end
    end

    -- ---- Heart_GUIClasses ----
    if Heart_GUIClasses then
      if Heart_GUIClassDropDownMenu then
        SkinDropDown(Heart_GUIClassDropDownMenu, nil, nil, nil, true)
      end
      SkinButton(Heart_GUINewClassButton)
      SkinButton(Heart_GUIDeleteClassButton)

      local classCheckboxes = {
        Heart_GUIKeepWaterShield,
        Heart_GUIShamanTotem,
        Heart_GUIPaladinHolyStrike,
        Heart_GUIPaladinWisdomJudgment,
        Heart_GUIAllowFirstRankIgnoreOverheal,
      }
      for _, cb in ipairs(classCheckboxes) do
        if cb then SkinCheckbox(cb, 20) end
      end

      if Heart_GUIEssenceOfEluneSlider then
        SkinSlider(Heart_GUIEssenceOfEluneSlider)
      end

      for i = 1, 10 do
        local selectFrame = getglobal("Heart_GUISpellSelect" .. i)
        if selectFrame then
          StripTextures(selectFrame, true)
          CreateBackdrop(selectFrame, nil, nil, .5)
          local btn = getglobal("Heart_GUISpellSelect" .. i .. "Spell")
          if btn then
            SkinButton(btn, nil, nil, nil, nil, true)
            local tex = getglobal(btn:GetName() .. "Texture")
            if tex then
              tex:SetTexCoord(.08, .92, .08, .92)
            end
          end
        end
      end

      if Heart_GUIClassesInset then
        StripTextures(Heart_GUIClassesInset, true)
        CreateBackdrop(Heart_GUIClassesInset, nil, nil, .5)
        SkinScrollbar(Heart_GUIClassesInsetScrollBar)
      end
    end

    -- ---- Heart_GUISettings ----
    if Heart_GUISettings then
      local settingsCheckboxes = {
    Heart_GUIUseActionCheckButton,
    Heart_GUINinjaUseActionCheckButton,
    Heart_GUIHookShieldsCheckButton,
    Heart_GUIHealCharmedCheckButton,
    Heart_GUIScaleHotCheckButton,
    Heart_GUIScaleSpellsCheckButton,
    Heart_GUISafeCancelCheckButton,
    Heart_GUITankTargetCheckButton,
    Heart_GUIBlockFasterHealersCheckButton,
  }
  for _, cb in ipairs(settingsCheckboxes) do
    if cb then SkinCheckbox(cb, 20) end
  end

      local settingsSliders = {
        Heart_GUIHOTMinCancelThresholdSlider,
        Heart_GUIHOTMultiplySlider,
        Heart_GUIHOTMultiplyBattleSlider,
        Heart_GUIMaxOverhealSlider,
        Heart_GUIMinHealThresholdSlider,
        Heart_GUIHealPowerSlider,
        Heart_GUIUpdatePlayerDataTimeSlider,
        Heart_GUIHealStrategySlider,
        Heart_GUIHealerCountLimitSlider,
      }
      for _, sld in ipairs(settingsSliders) do
        if sld then SkinSlider(sld) end
      end
    end

    -- ---- Heart_GUIPriorities ----
    if Heart_GUIPriorities then
      local prioritySliders = {
        Heart_GUIPlayerPrioritySlider,
        Heart_GUIPartyPrioritySlider,
        Heart_GUIRaidPrioritySlider,
        Heart_GUIPetPrioritySlider,
        Heart_GUIMTPrioritySlider,
        Heart_GUIBOPPrioritySlider,
        Heart_GUIPWSPrioritySlider,
        Heart_GUIRBPrioritySlider,
        Heart_GUIWSPrioritySlider,
        Heart_GUIMSPrioritySlider,
        Heart_GUIDruidPrioritySlider,
        Heart_GUIHunterPrioritySlider,
        Heart_GUIMagePrioritySlider,
        Heart_GUIPaladinPriestPrioritySlider,
        Heart_GUIPriestRoguePrioritySlider,
        Heart_GUIRoguePrioritySlider,
        Heart_GUIShamanPrioritySlider,
        Heart_GUIWarlockPrioritySlider,
        Heart_GUIWarriorPrioritySlider,
      }
      for _, sld in ipairs(prioritySliders) do
        if sld then SkinSlider(sld) end
      end
    end

    -- ---- Heart_GUIRaid ----
    if Heart_GUIRaid then
      SkinButton(Heart_GUIRaidCheckAllButton)
      SkinButton(Heart_GUIRaidInvertCheckedButton)
      if Heart_GUIRaidUncheckedPrioritySlider then
        SkinSlider(Heart_GUIRaidUncheckedPrioritySlider)
      end
      for group = 1, 8 do
        local groupFrame = getglobal("Heart_GUIRaidGroup" .. group)
        if groupFrame then
          StripTextures(groupFrame, true)
          CreateBackdrop(groupFrame, nil, nil, .4)
          for slot = 1, 5 do
            local slotFrame = getglobal("Heart_GUIRaidGroup" .. group .. "Slot" .. slot)
            if slotFrame then
              StripTextures(slotFrame, true)
              local cb = getglobal(slotFrame:GetName() .. "CheckButton")
              if cb then SkinCheckbox(cb, 20) end
            end
          end
          local label = getglobal(groupFrame:GetName() .. "Label")
          if label then SkinButton(label) end
        end
      end
    end

    -- ---- Heart_GUIMouseKeys ----
    if Heart_GUIMouseKeys then
      local mouseCheckboxes = {
        Heart_GUIEnableMouseCheckButton,
      }
      for _, cb in ipairs(mouseCheckboxes) do
        if cb then SkinCheckbox(cb, 20) end
      end
      local mouseSliders = {
        Heart_GUIHealSelfModifierSlider,
        Heart_GUIHealTargettargetModifierSlider,
        Heart_GUIHealEnoughModifierSlider,
        Heart_GUIHealMaxModifierSlider,
        Heart_GUIHealNoneModifierSlider,
      }
      for _, sld in ipairs(mouseSliders) do
        if sld then SkinSlider(sld) end
      end
      -- 原有 Button1~5 下拉菜单
      for i = 1, 5 do
        local dd = getglobal("Heart_GUIButton" .. i .. "DropDownMenu")
        if dd then SkinDropDown(dd, nil, nil, nil, true) end
      end
      -- ★ 新增：美化遗漏的 Left/Right/Middle/CustomButton1/CustomButton2 下拉菜单
      local extraDDs = {
        "Heart_GUILeftButtonDropDownMenu",
        "Heart_GUIRightButtonDropDownMenu",
        "Heart_GUIMiddleButtonDropDownMenu",
        "Heart_GUICustomButton1DropDownMenu",
        "Heart_GUICustomButton2DropDownMenu",
      }
      for _, name in ipairs(extraDDs) do
        local dd = getglobal(name)
        if dd then SkinDropDown(dd, nil, nil, nil, true) end
      end
    end

    -- ---- Heart_GUIDisplay ----
    if Heart_GUIDisplay then
      local displayCheckboxes = {
        Heart_GUIShowCurrentHealBarsCheckButton,
        Heart_GUIShowHealBarsCheckButton,
        Heart_GUIShowSpellRankHealCheckButton,
        Heart_GUIShowTargetHealthCheckButton,
        Heart_GUIShowAfterHealthCheckButton,
        Heart_GUIShowOverhealCheckButton,
        Heart_GUIShowHealingCheckButton,
      }
      for _, cb in ipairs(displayCheckboxes) do
        if cb then SkinCheckbox(cb, 20) end
      end
      local displaySliders = {
        Heart_GUIHealBarScaleSlider,
        Heart_GUICurrentHealBarsScaleSlider,
        Heart_GUIButtonsScaleSlider,
      }
      for _, sld in ipairs(displaySliders) do
        if sld then SkinSlider(sld) end
      end
      if Heart_GUIAboutBox then
        StripTextures(Heart_GUIAboutBox, true)
        CreateBackdrop(Heart_GUIAboutBox, nil, nil, .3)
      end
    end

    -- ---- Heart_GUIRez ----
    if Heart_GUIRez then
      local rezCheckboxes = {
        Heart_GUIRezRaidCheckButton,
        Heart_GUIUseActionRezCheckButton,
        Heart_GUIRezYellCheckButton,
        Heart_GUIRezSayCheckButton,
        Heart_GUIRezPartyRaidCheckButton,
      }
      for _, cb in ipairs(rezCheckboxes) do
        if cb then SkinCheckbox(cb, 20) end
      end
      if Heart_GUIRezRankSlider then
        SkinSlider(Heart_GUIRezRankSlider)
      end
      if Heart_GUIRezEditBox then
        StripTextures(Heart_GUIRezEditBox, true)
        CreateBackdrop(Heart_GUIRezEditBox, nil, nil, .3)
      end
      local rezSliders = {
        Heart_GUIDruidPriorityRezSlider,
        Heart_GUIHunterPriorityRezSlider,
        Heart_GUIMagePriorityRezSlider,
        Heart_GUIPaladinPriestPriorityRezSlider,
        Heart_GUIPriestRoguePriorityRezSlider,
        Heart_GUIRoguePriorityRezSlider,
        Heart_GUIShamanPriorityRezSlider,
        Heart_GUIWarlockPriorityRezSlider,
        Heart_GUIWarriorPriorityRezSlider,
      }
      for _, sld in ipairs(rezSliders) do
        if sld then SkinSlider(sld) end
      end
    end

    -- ---- Heart_GUIAdv ----
    if Heart_GUIAdv then
      local advSliders = {
        Heart_GUICastTimeDebuff_ValueSlider,
        Heart_GUIMTCastTimeDebuff_ValueSlider,
      }
      for _, sld in ipairs(advSliders) do
        if sld then SkinSlider(sld) end
      end
      if Heart_GUIShapeshiftedDruidsCheckButton then
        SkinCheckbox(Heart_GUIShapeshiftedDruidsCheckButton, 20)
      end
    end
  end

  -- ========== 治疗条框架（已移除美化） ==========
  -- 以下原治疗条美化代码已被删除，保留默认外观

  -- ========== 弹出框 ==========
  local popups = {
    Heart_SpellSelectPopUpFrame,
    Heart_GUITextBox,
    Heart_GUIProfileTextBox,
  }
  for _, frame in ipairs(popups) do
    if frame then
      frame:DisableDrawLayer("BACKGROUND")
      StripTextures(frame, true)
      CreateBackdrop(frame, nil, nil, .75)
      local closeBtn = getglobal(frame:GetName() .. "CloseButton")
      if closeBtn then SkinCloseButton(closeBtn, frame.backdrop, -6, -6) end
      local okBtn = getglobal(frame:GetName() .. "ButtonOK")
      local cancelBtn = getglobal(frame:GetName() .. "ButtonCancel")
      if okBtn then SkinButton(okBtn) end
      if cancelBtn then SkinButton(cancelBtn) end
    end
  end
  if Heart_SpellSelectPopUpFramePercentSlider then
    SkinSlider(Heart_SpellSelectPopUpFramePercentSlider)
  end

  -- ========== 动态创建的法术条目（类框架） ==========
  if Heart_ClassDropDownMenuUpdate then
    hooksecurefunc("Heart_ClassDropDownMenuUpdate", function()
      C_Timer.After(0.05, function()
        for i = 1, 30 do
          local frame = getglobal("Heart_GUIClass" .. i)
          if frame and not frame._skinned then
            StripTextures(frame, true, "BACKGROUND")
            CreateBackdrop(frame, nil, nil, .4)
            local spellBtn = getglobal(frame:GetName() .. "Spell")
            if spellBtn then
              StripTextures(spellBtn, true)
              local tex = getglobal(spellBtn:GetName() .. "Texture")
              if tex then
                tex:SetTexCoord(.08, .92, .08, .92)
              end
            end
            local attachBtn = getglobal(frame:GetName() .. "SpellAttachment")
            if attachBtn then
              StripTextures(attachBtn, true)
              local tex = getglobal(attachBtn:GetName() .. "Texture")
              if tex then
                tex:SetTexCoord(.08, .92, .08, .92)
              end
            end
            local rankSlider = getglobal(frame:GetName() .. "RankSlider")
            if rankSlider then SkinSlider(rankSlider) end
            local scaleBox = getglobal(frame:GetName() .. "ScaleCheckBox")
            if scaleBox then SkinCheckbox(scaleBox, 20) end
            frame._skinned = true
          end
        end
      end)
    end)
  end

  -- ========== 注销皮肤（一次性） ==========
  pfUI.addonskinner:UnregisterSkin("Heart")
end)