pfUI.addonskinner:RegisterSkin("AutoBar", function()
  -- upvalue the pfUI methods we use to avoid repeated lookups
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton, 
    SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar, 
    HookScript, hooksecurefunc, SkinDropDown, SkinSlider, SkinTab = 
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton, 
  penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar, 
  penv.HookScript, penv.hooksecurefunc, penv.SkinDropDown, penv.SkinSlider, penv.SkinTab

  local noop = function() end

  -- 皮肤化主界面按钮 - 使用与设置界面相同的风格
  if AutoBarFrame then
    for i = 1, 24 do
      local button = _G["AutoBarFrameButton" .. i]
      if button then
--[[
        -- 移除默认纹理
        StripTextures(button)
        -- 创建pfUI风格背景
        CreateBackdrop(button, nil, nil, .85)
        button.backdrop:SetPoint("TOPLEFT", -4, 4)
        button.backdrop:SetPoint("BOTTOMRIGHT", 4, -4)
        
        -- 皮肤化按钮
        SkinButton(button)
        
        -- 处理图标 - 使用与设置界面相同的风格
        local icon = _G[button:GetName() .. "Icon"]
        if icon then
          -- 移除原边框和闪光效果
          local border = _G[button:GetName() .. "Border"]
          local flash = _G[button:GetName() .. "Flash"]
          
          if border then
            border:SetTexture("")
            border:Hide()
          end
          
          if flash then
            flash:SetTexture("")
            flash:Hide()
          end
          
          -- 使用与设置界面相同的图标风格
          icon:SetTexCoord(.08, .92, .08, .92) -- 正常边距
          icon:SetAllPoints(button)
          icon:SetDrawLayer("ARTWORK")
        end
]]--        
        -- 处理数量文字
        local count = _G[button:GetName() .. "Count"]
        if count then
          count:SetFont(pfUI.font_default, 12, "OUTLINE")
          count:SetJustifyH("RIGHT")
          count:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        
        -- 处理冷却文字
        local cooldown = _G[button:GetName() .. "Cooldown"]
        if cooldown then
          cooldown:SetAllPoints(button)
        end
      end
    end
  end

  -- 皮肤化弹出菜单按钮 - 使用与设置界面相同的风格
  if AutoBarPopupFrame then
    for i = 1, 12 do
      local button = _G["AutoBarPopupFrame_Button" .. i]
      if button then
--[[
        -- 移除默认纹理
        StripTextures(button)
        -- 创建pfUI风格背景
        CreateBackdrop(button, nil, nil, .85)
        button.backdrop:SetPoint("TOPLEFT", -4, 4)
        button.backdrop:SetPoint("BOTTOMRIGHT", 4, -4)
        
        -- 皮肤化按钮
        SkinButton(button)
        
        -- 处理图标 - 使用与设置界面相同的风格
        local icon = _G[button:GetName() .. "Icon"]
        if icon then
          local border = _G[button:GetName() .. "Border"]
          local flash = _G[button:GetName() .. "Flash"]
          
          if border then
            border:SetTexture("")
            border:Hide()
          end
          
          if flash then
            flash:SetTexture("")
            flash:Hide()
          end
          
          -- 使用与设置界面相同的图标风格
          icon:SetTexCoord(.08, .92, .08, .92) -- 正常边距
          icon:SetAllPoints(button)
          icon:SetDrawLayer("ARTWORK")
        end
 ]]--       
        -- 处理数量文字
        local count = _G[button:GetName() .. "Count"]
        if count then
          count:SetFont(pfUI.font_default, 12, "OUTLINE")
          count:SetJustifyH("RIGHT")
          count:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        
        -- 处理冷却文字
        local cooldown = _G[button:GetName() .. "Cooldown"]
        if cooldown then
          cooldown:SetAllPoints(button)
        end
      end
    end
    
    -- 皮肤化弹出菜单框架
    StripTextures(AutoBarPopupFrame)
    CreateBackdrop(AutoBarPopupFrame, nil, nil, .85)
  end

  -- 皮肤化AutoBarConfigSlotFrame框架
  if AutoBarConfigSlotFrame then
    -- 移除默认纹理
    StripTextures(AutoBarConfigSlotFrame)
    -- 创建pfUI风格背景
    CreateBackdrop(AutoBarConfigSlotFrame, nil, nil, .85)
    AutoBarConfigSlotFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
    AutoBarConfigSlotFrame.backdrop:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- 皮肤化标题文本
    if AutoBarConfigSlotFrameTitleText then
      AutoBarConfigSlotFrameTitleText:SetFont(pfUI.font_default, 14, "OUTLINE")
    end
    
    if AutoBarConfigSlotFrameViewText then
      AutoBarConfigSlotFrameViewText:SetFont(pfUI.font_default, 12, "OUTLINE")
    end
    
    -- 皮肤化所有按钮
    for i = 1, 16 do
      local button = _G["AutoBarConfigSlotFrame_Button" .. i]
      if button then
        StripTextures(button)
        CreateBackdrop(button, nil, nil, .85)
        SkinButton(button)
        
        -- 处理图标
        local icon = _G[button:GetName() .. "Icon"]
        if icon then
          icon:SetTexCoord(.08, .92, .08, .92)
          icon:SetAllPoints(button)
        end
      end
    end
    
    -- 皮肤化所有选项复选框 - 调整尺寸为20
    for i = 1, 16 do
      local option = _G["AutoBarConfigSlotFrame_Option" .. i]
      if option then
        SkinCheckbox(option, 20) -- 使用20的尺寸
        option:SetWidth(20)
        option:SetHeight(20)
      end
    end
    
    -- 皮肤化底部按钮
    local bottomButtons = {
      "AutoBarConfigSlotFrameEmptySlotButton",
      "AutoBarConfigSlotFrameClearSlotButton",
      "AutoBarConfigSlotFrameDoneButton"
    }
    
    for _, buttonName in ipairs(bottomButtons) do
      local button = _G[buttonName]
      if button then
        StripTextures(button)
        SkinButton(button)
        -- 调整按钮长度
        button:SetWidth(120) -- 设置适当宽度
        button:SetHeight(22) -- 适当调整高度以保持比例
        
        -- 确保文字适应新尺寸
        local buttonText = _G[buttonName .. "Text"]
        if buttonText then
          buttonText:SetFont(pfUI.font_default, 11, "OUTLINE")
          buttonText:SetWidth(110)
          buttonText:SetJustifyH("CENTER")
        end
      end
    end
    
    -- 皮肤化其他复选框
    local slotCheckboxes = {
      "AutoBarConfigSlotFrameNoPopup",
      "AutoBarConfigSlotFrameArrangeOnUse",
      "AutoBarConfigSlotFrameRightClickTargetsPet"
    }
    
    for _, checkboxName in ipairs(slotCheckboxes) do
      local checkbox = _G[checkboxName]
      if checkbox then
        SkinCheckbox(checkbox, 20) -- 使用20的尺寸
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
      end
    end
  end

  -- 皮肤化主配置框架 AutoBarConfigFrame
  if AutoBarConfigFrame then
    -- 移除默认纹理
    StripTextures(AutoBarConfigFrame)
    -- 创建pfUI风格背景
    CreateBackdrop(AutoBarConfigFrame, nil, nil, .85)
    AutoBarConfigFrame.backdrop:SetPoint("TOPLEFT", 10, -12)
    AutoBarConfigFrame.backdrop:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- 皮肤化关闭按钮
    if AutoBarConfigFrameCloseButton then
      SkinCloseButton(AutoBarConfigFrameCloseButton, AutoBarConfigFrame.backdrop, -6, -6)
    end
    
    -- 皮肤化选项卡 - 恢复原有尺寸
    for i = 1, 5 do
      local tab = _G["AutoBarConfigFrameTab" .. i]
      if tab then
        SkinTab(tab)
        -- 恢复选项卡原有高度，移除之前的SetHeight(24)设置
        -- 选项卡将使用pfUI默认的高度设置
      end
    end
    
    -- 皮肤化底部按钮
    if AutoBarConfigFrameDoneButton then
      StripTextures(AutoBarConfigFrameDoneButton)
      SkinButton(AutoBarConfigFrameDoneButton)
    end
    
    if AutoBarConfigFrameRevertButton then
      StripTextures(AutoBarConfigFrameRevertButton)
      SkinButton(AutoBarConfigFrameRevertButton)
    end
    
    if AutoBarConfigFrameResetDisplay then
      StripTextures(AutoBarConfigFrameResetDisplay)
      SkinButton(AutoBarConfigFrameResetDisplay)
    end
    
    -- 皮肤化单选按钮 - 调整尺寸为20
    if AutoBarConfigFrameLayout1 then
      SkinCheckbox(AutoBarConfigFrameLayout1, 20) -- 使用20的尺寸
      AutoBarConfigFrameLayout1:SetWidth(20)
      AutoBarConfigFrameLayout1:SetHeight(20)
    end
    
    if AutoBarConfigFrameLayout2 then
      SkinCheckbox(AutoBarConfigFrameLayout2, 20) -- 使用20的尺寸
      AutoBarConfigFrameLayout2:SetWidth(20)
      AutoBarConfigFrameLayout2:SetHeight(20)
    end
    
    -- 皮肤化各种视图按钮
    for i = 1, 24 do
      local viewButton = _G["AutoBarConfigFrameSlotsView_Button" .. i]
      if viewButton then
        StripTextures(viewButton)
        CreateBackdrop(viewButton, nil, nil, .85)
        SkinButton(viewButton)
        
        -- 处理图标
        local icon = _G[viewButton:GetName() .. "Icon"]
        if icon then
          icon:SetTexCoord(.08, .92, .08, .92)
          icon:SetAllPoints(viewButton)
        end
      end
      
      local slotButton = _G["AutoBarConfigFrameSlots_Button" .. i]
      if slotButton then
        StripTextures(slotButton)
        CreateBackdrop(slotButton, nil, nil, .85)
        SkinButton(slotButton)
        
        -- 处理图标
        local icon = _G[slotButton:GetName() .. "Icon"]
        if icon then
          icon:SetTexCoord(.08, .92, .08, .92)
          icon:SetAllPoints(slotButton)
        end
      end
    end
    
    -- 皮肤化编辑选项单选按钮 - 调整尺寸为20
    for i = 1, 4 do
      local editButton = _G["AutoBarConfigFrameSlotsEdit" .. i]
      if editButton then
        SkinCheckbox(editButton, 20) -- 使用20的尺寸
        editButton:SetWidth(20)
        editButton:SetHeight(20)
      end
    end
    
    -- 皮肤化使用选项复选框 - 调整尺寸为20
    if AutoBarConfigFrameSlotsViewUseCharacter then
      SkinCheckbox(AutoBarConfigFrameSlotsViewUseCharacter, 20) -- 使用20的尺寸
      AutoBarConfigFrameSlotsViewUseCharacter:SetWidth(20)
      AutoBarConfigFrameSlotsViewUseCharacter:SetHeight(20)
    end
    
    if AutoBarConfigFrameSlotsViewUseShared then
      SkinCheckbox(AutoBarConfigFrameSlotsViewUseShared, 20) -- 使用20的尺寸
      AutoBarConfigFrameSlotsViewUseShared:SetWidth(20)
      AutoBarConfigFrameSlotsViewUseShared:SetHeight(20)
    end
    
    if AutoBarConfigFrameSlotsViewUseClass then
      SkinCheckbox(AutoBarConfigFrameSlotsViewUseClass, 20) -- 使用20的尺寸
      AutoBarConfigFrameSlotsViewUseClass:SetWidth(20)
      AutoBarConfigFrameSlotsViewUseClass:SetHeight(20)
    end
    
    if AutoBarConfigFrameSlotsViewUseBasic then
      SkinCheckbox(AutoBarConfigFrameSlotsViewUseBasic, 20) -- 使用20的尺寸
      AutoBarConfigFrameSlotsViewUseBasic:SetWidth(20)
      AutoBarConfigFrameSlotsViewUseBasic:SetHeight(20)
    end
    
    -- 皮肤化Bar选项卡中的滑块
    local barSliders = {
      "AutoBarConfigFrameBarRows",
      "AutoBarConfigFrameBarColumns",
      "AutoBarConfigFrameBarGapping",
      "AutoBarConfigFrameBarButtonWidth",
      "AutoBarConfigFrameBarButtonHeight",
      "AutoBarConfigFrameBarDockShiftX",
      "AutoBarConfigFrameBarDockShiftY"
    }
    
    for _, sliderName in ipairs(barSliders) do
      local slider = _G[sliderName]
      if slider then
        SkinSlider(slider)
      end
    end
    
    -- 皮肤化Bar选项卡中的复选框 - 调整尺寸为20
    if AutoBarConfigFrameBarWidthHeightUnlocked then
      SkinCheckbox(AutoBarConfigFrameBarWidthHeightUnlocked, 20) -- 使用20的尺寸
      AutoBarConfigFrameBarWidthHeightUnlocked:SetWidth(20)
      AutoBarConfigFrameBarWidthHeightUnlocked:SetHeight(20)
    end
    
    if AutoBarConfigFrameBarHideDragHandle then
      SkinCheckbox(AutoBarConfigFrameBarHideDragHandle, 20) -- 使用20的尺寸
      AutoBarConfigFrameBarHideDragHandle:SetWidth(20)
      AutoBarConfigFrameBarHideDragHandle:SetHeight(20)
    end
    
    -- 皮肤化对齐按钮 - 调整尺寸为20
    for i = 1, 9 do
      local alignButton = _G["AutoBarConfigFrameBarAlign" .. i]
      if alignButton then
        SkinCheckbox(alignButton, 20) -- 使用20的尺寸
        alignButton:SetWidth(20)
        alignButton:SetHeight(20)
      end
    end
    
    -- 皮肤化DockTo下拉菜单
    if AutoBarConfigFrameBarDockTo then
      SkinDropDown(AutoBarConfigFrameBarDockTo)
    end
    
    -- 皮肤化Buttons选项卡中的滑块
    if AutoBarConfigFrameButtonsAlpha then
      SkinSlider(AutoBarConfigFrameButtonsAlpha)
    end
    
    -- 皮肤化Buttons选项卡中的复选框 - 调整尺寸为20
    local buttonsCheckboxes = {
      "AutoBarConfigFrameButtonsHideKeyText",
      "AutoBarConfigFrameButtonsHideCount",
      "AutoBarConfigFrameButtonsPlainButtons",
      "AutoBarConfigFrameButtonsSmartSelfCast",
      "AutoBarConfigFrameButtonsShowEmptyButtons",
      "AutoBarConfigFrameButtonsShowCategoryIcon",
      "AutoBarConfigFrameButtonsHideTooltips"
    }
    
    for _, checkboxName in ipairs(buttonsCheckboxes) do
      local checkbox = _G[checkboxName]
      if checkbox then
        SkinCheckbox(checkbox, 20) -- 使用20的尺寸
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
      end
    end
    
    -- 皮肤化Popup选项卡中的复选框 - 调整尺寸为20
    local popupCheckboxes = {
      "AutoBarConfigFramePopupPopupToTop",
      "AutoBarConfigFramePopupPopupDisable",
      "AutoBarConfigFramePopupPopupOnShift",
      "AutoBarConfigFramePopupPopupToRight",
      "AutoBarConfigFramePopupPopupToLeft",
      "AutoBarConfigFramePopupPopupToBottom"
    }
    
    for _, checkboxName in ipairs(popupCheckboxes) do
      local checkbox = _G[checkboxName]
      if checkbox then
        SkinCheckbox(checkbox, 20) -- 使用20的尺寸
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
      end
    end
    
    -- 皮肤化Profile选项卡中的元素
    if AutoBarConfigFrameProfileSetShared then
      SkinDropDown(AutoBarConfigFrameProfileSetShared)
    end
    
    -- 皮肤化Profile选项卡中的复选框 - 调整尺寸为20
    if AutoBarConfigFrameProfileHideConfigTooltips then
      SkinCheckbox(AutoBarConfigFrameProfileHideConfigTooltips, 20) -- 使用20的尺寸
      AutoBarConfigFrameProfileHideConfigTooltips:SetWidth(20)
      AutoBarConfigFrameProfileHideConfigTooltips:SetHeight(20)
    end
    
    if AutoBarConfigFrameProfileoSkin then
      SkinCheckbox(AutoBarConfigFrameProfileoSkin, 20) -- 使用20的尺寸
      AutoBarConfigFrameProfileoSkin:SetWidth(20)
      AutoBarConfigFrameProfileoSkin:SetHeight(20)
    end
    
    -- 皮肤化Profile选项卡中的按钮 - 调整长度
    local profileButtons = {
      "AutoBarConfigFrameProfileSetupSingleButton",
      "AutoBarConfigFrameProfileSetupSharedButton",
      "AutoBarConfigFrameProfileSetupStandardButton",
      "AutoBarConfigFrameProfileSetupBlankSlateButton",
      "AutoBarConfigFrameProfileResetSingleButton",
      "AutoBarConfigFrameProfileResetSharedButton",
      "AutoBarConfigFrameProfileResetStandardButton"
    }
    
    for _, buttonName in ipairs(profileButtons) do
      local button = _G[buttonName]
      if button then
        StripTextures(button)
        SkinButton(button)
        -- 调整按钮长度
        button:SetWidth(130) -- 设置为130宽度
        button:SetHeight(22) -- 适当调整高度以保持比例
        
        -- 确保文字适应新尺寸
        local buttonText = _G[buttonName .. "Text"]
        if buttonText then
          buttonText:SetFont(pfUI.font_default, 11, "OUTLINE")
          buttonText:SetWidth(120)
          buttonText:SetJustifyH("CENTER")
        end
      end
    end
  end

  -- 皮肤化分类按钮
  if AutoBarClassButton then
    for i = 1, 20 do
      local classButton = _G["AutoBarClassButton" .. i]
      if classButton then
        StripTextures(classButton)
        CreateBackdrop(classButton, nil, nil, .85)
        SkinButton(classButton)
      end
    end
  end

  -- 延迟执行以确保所有元素都已加载
  C_Timer.After(1, ProcessItemIconBorders)
  
  pfUI.addonskinner:UnregisterSkin("AutoBar")
end)