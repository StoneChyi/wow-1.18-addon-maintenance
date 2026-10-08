pfUI.addonskinner:RegisterSkin("WorldBuffsTracker", function()
  -- upvalue the pfUI methods we use to avoid repeated lookups
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton, 
    SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar, 
    HookScript, hooksecurefunc, SkinDropDown, SkinSlider, SkinTab = 
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton, 
  penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar, 
  penv.HookScript, penv.hooksecurefunc, penv.SkinDropDown, penv.SkinSlider, penv.SkinTab

  local noop = function() end

  -- 替换所有状态栏的材质为pfUI材质
  local function ReplaceStatusBarTextures()
    -- 主框架状态栏
    if WorldBuffsTrackerMainFrame_Timer_StatusBar then
      -- 移除默认纹理
      StripTextures(WorldBuffsTrackerMainFrame_Timer_StatusBar)
      -- 设置pfUI材质
      WorldBuffsTrackerMainFrame_Timer_StatusBar:SetStatusBarTexture("Interface\\AddOns\\pfUI\\img\\bar")
      -- 创建pfUI风格背景
      CreateBackdrop(WorldBuffsTrackerMainFrame_Timer_StatusBar, nil, nil, .85)
    end

    -- 物品框架状态栏
    for i = 1, 4 do
      local statusBar = _G["WorldBuffsTrackerItemFrame_Item" .. i]
      if statusBar then
        -- 移除默认纹理
        StripTextures(statusBar)
        -- 设置pfUI材质
        statusBar:SetStatusBarTexture("Interface\\AddOns\\pfUI\\img\\bar")
        -- 创建pfUI风格背景
        CreateBackdrop(statusBar, nil, nil, .85)
        
        -- 处理状态条文本
        local text = _G[statusBar:GetName() .. "_Text"]
        if text then
          text:SetFont(pfUI.font_default, 12, "")
        end
      end
    end

    -- 确保所有状态栏都使用pfUI材质
    local allStatusBars = {
      WorldBuffsTrackerMainFrame_Timer_StatusBar,
      WorldBuffsTrackerItemFrame_Item1,
      WorldBuffsTrackerItemFrame_Item2,
      WorldBuffsTrackerItemFrame_Item3,
      WorldBuffsTrackerItemFrame_Item4
    }

    for _, bar in ipairs(allStatusBars) do
      if bar then
        -- 获取当前状态栏纹理
        local texture = bar:GetStatusBarTexture()
        if texture then
          -- 确保使用pfUI材质
          bar:SetStatusBarTexture("Interface\\AddOns\\pfUI\\img\\bar")
          -- 设置纹理坐标和缩放
          texture:SetTexCoord(0, 1, 0, 1)
        end
      end
    end
  end

  -- 皮肤化主框架
  if WorldBuffsTrackerMainFrame then

    WorldBuffsTrackerMainFrame:SetWidth(200)
    StripTextures(WorldBuffsTrackerMainFrame)
    CreateBackdrop(WorldBuffsTrackerMainFrame, nil, nil, .85)
        
    -- 皮肤化状态条（材质已在ReplaceStatusBarTextures中处理）
    if WorldBuffsTrackerMainFrame_Timer_StatusBar then
      CreateBackdrop(WorldBuffsTrackerMainFrame_Timer_StatusBar, nil, nil, .85)

      -- 设置状态条颜色为绿色
      WorldBuffsTrackerMainFrame_Timer_StatusBar:SetStatusBarColor(0, 0.7, 0.4, 1)

      -- 处理状态条文本
      if WorldBuffsTrackerMainFrame_Timer_StatusBar_Title then
        WorldBuffsTrackerMainFrame_Timer_StatusBar_Title:SetFont(pfUI.font_default, 12, "")
      end
      
      if WorldBuffsTrackerMainFrame_Timer_StatusBar_Text then
        WorldBuffsTrackerMainFrame_Timer_StatusBar_Text:SetFont(pfUI.font_default, 12, "")
      end
    end
  end

  -- 皮肤化物品框架
  if WorldBuffsTrackerItemFrame then
    StripTextures(WorldBuffsTrackerItemFrame)
    CreateBackdrop(WorldBuffsTrackerItemFrame, nil, nil, .85)
    
    -- 皮肤化所有状态条（材质已在ReplaceStatusBarTextures中处理）
    for i = 1, 4 do
      local statusBar = _G["WorldBuffsTrackerItemFrame_Item" .. i]
      if statusBar then
        CreateBackdrop(statusBar, nil, nil, .85)
      end
    end
    
    -- 皮肤化所有复选框
    local checkButtons = {
      "WorldBuffsTrackerItemFrame_Check_Alliance_Onyxia",
      "WorldBuffsTrackerItemFrame_Check_Alliance_Nefarian",
      "WorldBuffsTrackerItemFrame_Check_Horde_Onyxia",
      "WorldBuffsTrackerItemFrame_Check_Horde_Nefarian",
      "WorldBuffsTrackerItemFrame_Check_Priority_display"
    }
    
    for _, buttonName in ipairs(checkButtons) do
      local checkbox = _G[buttonName]
      if checkbox then
        SkinCheckbox(checkbox, 20)
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
        
        -- 处理复选框文本
        local text = _G[checkbox:GetName() .. "Text"]
        if text then
          text:SetFont(pfUI.font_default, 12, "")
        end
      end
    end
  end

    local TimerButtons = {
      "TWB_Horde_Onyxia_Button_Frame",
      "TWB_Horde_Nefarian_Button_Frame",
      "TWB_Alliance_Nefarian_Button_Frame",
      "TWB_Alliance_Onyxia_Button_Frame", 
      "WBT_Button_Mulgore", 
      "WBT_Button_Elwynn"
    }
    
    for _, buttonName in ipairs(TimerButtons) do
      local button = _G[buttonName]
      if button then
        local icon = _G[button:GetName() .. "Icon"]
        SkinButton(button)
        button:SetNormalTexture("");
        --icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        local text = _G[button:GetName() .. "Text"]
        if text then
          text:SetFont(pfUI.font_default, 12, "OUTLINE")
        end
      end
    end
    



  -- 皮肤化配置框架
  if WorldBuffsTrackerConfigFrame then
    StripTextures(WorldBuffsTrackerConfigFrame)
    CreateBackdrop(WorldBuffsTrackerConfigFrame, nil, nil, .85)
    
    -- 处理标题文本
    if WorldBuffsTrackerConfigFrame_ReportToTitle then
      WorldBuffsTrackerConfigFrame_ReportToTitle:SetFont(pfUI.font_default, 12, "")
    end
    
    -- 皮肤化下拉菜单
    if WorldBuffsTrackerConfigFrame_ReportTo then
      WorldBuffsTrackerConfigFrame_ReportTo:SetPoint("TOPRIGHT", 10, 0)
      --SkinDropDown(WorldBuffsTrackerConfigFrame_ReportTo)
    end
    
    -- 皮肤化所有复选框
    local configCheckboxes = {
      "WorldBuffsTrackerConfigFrame_ReportAlliance_allowed",
      "WorldBuffsTrackerConfigFrame_ReportHorde_allowed",
      "WorldBuffsTrackerConfigFrame_MergeReport_allowed",
      "WorldBuffsTrackerConfigFrame_AlarmSwitch",
      "WorldBuffsTrackerConfigFrame_Hearthstone",
      "WorldBuffsTrackerConfigFrame_AlarmSoundSwitch"
    }
    
    for _, buttonName in ipairs(configCheckboxes) do
      local checkbox = _G[buttonName]
      if checkbox then
        SkinCheckbox(checkbox, 20)
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
        
        -- 处理复选框文本
        local text = _G[checkbox:GetName() .. "Text"]
        if text then
          text:SetFont(pfUI.font_default, 12, "")
        end
      end
    end
  end

  -- 皮肤化主框架
  if WorldBuffsTrackerFrame then
    -- 这里可以添加对主框架的额外皮肤化处理
  end

  -- 皮肤化工具提示
  if WorldBuffsTrackerTooltip then
    StripTextures(WorldBuffsTrackerTooltip)
    CreateBackdrop(WorldBuffsTrackerTooltip, nil, nil, .85)
  end

  -- 延迟执行以确保所有元素已加载
  C_Timer.After(1, ReplaceStatusBarTextures)

  pfUI.addonskinner:UnregisterSkin("WorldBuffsTracker")
end)