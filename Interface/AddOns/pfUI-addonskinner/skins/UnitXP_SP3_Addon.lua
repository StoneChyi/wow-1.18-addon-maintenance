pfUI.addonskinner:RegisterSkin("UnitXP_SP3_Addon", function()
  -- place main code below
  local penv = pfUI:GetEnvironment()
  local HookAddonOrVariable, StripTextures, SkinButton, SkinCheckbox, CreateBackdrop, CreateBackdropShadow =
  penv.HookAddonOrVariable, penv.StripTextures, penv.SkinButton, penv.SkinCheckbox, penv.CreateBackdrop, penv.CreateBackdropShadow

  HookAddonOrVariable("UnitXP_SP3_Addon", function()
    -- skin UnitXP SP3 window and elements
    local frames = {
      xpsp3Frame,
      xpsp3tooltip,
    }

    -- 所有按钮列表
    local buttons = {
      xpsp3_buttonCancel_close,
      xpsp3_buttonCancel_resetCamera,
      xpsp3_button_cameraHeight_raise,
      xpsp3_button_cameraHeight_lower,
      xpsp3_button_cameraHorizontalDisplacement_leftPlayer,
      xpsp3_button_cameraHorizontalDisplacement_rightPlayer,
      xpsp3_button_cameraPitch_up,
      xpsp3_button_cameraPitch_down,
      xpsp3_button_resourceBar_Texture,
    }

    -- 所有复选框列表
    local boxes = {
      xpsp3_checkButton_minimapButton,
      xpsp3_checkButton_modernNameplate,
      xpsp3_checkButton_prioritizeTargetNameplate,
      xpsp3_checkButton_prioritizeMarkedNameplate,
      xpsp3_checkButton_nameplateCombatFilter,
      xpsp3_checkButton_hideCritterNameplate,
      xpsp3_checkButton_showInCombatNameplatesNearPlayer,
      xpsp3_checkButton_notify_flashTaskbarIcon,
      xpsp3_checkButton_notify_playSystemDefaultSound,
      xpsp3_checkButton_cameraPinHeight,
      xpsp3_checkButton_weatherAlwaysClear,
      xpsp3_checkButton_combatTextSP3,
      xpsp3_checkButton_hideEXPtext,
      xpsp3_checkButton_perfectScreenshot,
      xpsp3_checkButton_selfHealthBar,
    }

    for _, f in pairs(frames) do
      if f then
        StripTextures(f)
        CreateBackdrop(f)
        CreateBackdropShadow(f)
      end
    end

    for _, button in pairs(buttons) do
      if button then
        SkinButton(button)
      end
    end

    for _, box in pairs(boxes) do
      if box then
        SkinCheckbox(box)
      end
    end

    -- 输入框美化
    local editboxes = {
      xpsp3_editBox_FPScap,
      xpsp3_editBox_backgroundFPScap,
      xpsp3_editBox_combatTextSP3_fontName,
    }

    for _, eb in pairs(editboxes) do
      if eb then
        StripTextures(eb, false, "BACKGROUND")
        eb:SetHeight(20)
        CreateBackdrop(eb)
      end
    end

    -- 调整输入框尺寸/位置以匹配当前版本 XML
    if xpsp3_editBox_FPScap then
      xpsp3_editBox_FPScap:SetWidth(40)
      xpsp3_editBox_FPScap:SetPoint("TOPLEFT", xpsp3Frame, 340, -35)
    end

    if xpsp3_editBox_backgroundFPScap then
      xpsp3_editBox_backgroundFPScap:SetWidth(40)
      xpsp3_editBox_backgroundFPScap:SetPoint("TOPLEFT", xpsp3Frame, 490, -35)
    end

    if xpsp3_editBox_combatTextSP3_fontName then
      xpsp3_editBox_combatTextSP3_fontName:SetWidth(150)
      xpsp3_editBox_combatTextSP3_fontName:SetPoint("TOPLEFT", xpsp3Frame, 336, -325)
    end
  end)

  -- remove from pending list when applied
  pfUI.addonskinner:UnregisterSkin("UnitXP_SP3_Addon")
end)
