pfUI.addonskinner:RegisterSkin("Accountant", function()
  -- 获取pfUI环境方法
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinButton, SkinCloseButton, SkinCheckbox,
    SkinSlider, SkinDropDown, HookScript, SetAllPointsOffset =
  penv.StripTextures, penv.CreateBackdrop, penv.SkinButton, penv.SkinCloseButton,
  penv.SkinCheckbox, penv.SkinSlider, penv.SkinDropDown, penv.HookScript, penv.SetAllPointsOffset

  local tooltip_alpha = tonumber(pfUI_config.tooltip.alpha) or 0.75
  if tooltip_alpha > 0.75 then tooltip_alpha = 0.75 end

  -- 主框架皮肤化
  if AccountantFrame then
    StripTextures(AccountantFrame)
    CreateBackdrop(AccountantFrame, nil, nil, tooltip_alpha)
    AccountantFrame.backdrop:SetPoint("TOPLEFT", 5, -5)
    AccountantFrame.backdrop:SetPoint("BOTTOMRIGHT", -5, 5)
    
    -- 标题文本美化
    if AccountantFrameTitleText then
      AccountantFrameTitleText:SetFont(pfUI.font_default, 14, "OUTLINE")
    end
  end

  -- 关闭按钮美化
  if AccountantFrameCloseButton then
    SkinCloseButton(AccountantFrameCloseButton)
    AccountantFrameCloseButton:ClearAllPoints()
    AccountantFrameCloseButton:SetPoint("TOPRIGHT", AccountantFrame.backdrop, "TOPRIGHT", -2, -2)
  end

  -- 标签页美化 (修改部分：减少背景宽度)
  for i = 1, 5 do
    local tab = _G["AccountantFrameTab" .. i]
    if tab then
      StripTextures(tab)
      CreateBackdrop(tab)
      tab.backdrop:SetPoint("TOPLEFT", 7, -5)
      tab.backdrop:SetPoint("BOTTOMRIGHT", -7, 8)
      
      -- 标签文本美化
      local text = _G["AccountantFrameTab" .. i .. "Text"]
      if text then
        text:SetFont(pfUI.font_default, 12, "")
        text:ClearAllPoints()
        text:SetPoint("CENTER", tab, "CENTER", 0, 0)
      end
      
      -- 设置标签大小
      tab:SetHeight(30)
      tab:SetWidth(tab:GetTextWidth() - 15) -- 增加少量内边距 
     end
  end

  -- 主要功能按钮美化（兼容两种命名方式）
  local mainButtons = {
    "AccountantShowButton",
    "AccountantResetButton",
    "AccountantOptionsButton",
    "AccountantExitButton",
    -- 新增按钮
    "AccountantFrameResetButton",
    "AccountantFrameOptionsButton",
    "AccountantFrameExitButton"
  }
  for _, btnName in ipairs(mainButtons) do
    local btn = _G[btnName]
    if btn then
      StripTextures(btn)
      SkinButton(btn)
      btn:SetHeight(22)
    end
  end

  -- 选项框架美化
  if AccountantOptionsFrame then
    StripTextures(AccountantOptionsFrame)
    CreateBackdrop(AccountantOptionsFrame, nil, nil, tooltip_alpha)
    
    -- 选项框架关闭按钮
    if AccountantOptionsFrameCloseButton then
      SkinCloseButton(AccountantOptionsFrameCloseButton)
    end
  end

  -- 复选框美化
  local checkboxes = {
    "AccountantTrackGold",
    "AccountantTrackItems",
    "AccountantShowMinimap",
    "AccountantCompactMode",
    "AccountantShowTooltips"
  }
  for _, cbName in ipairs(checkboxes) do
    local cb = _G[cbName]
    if cb then
      SkinCheckbox(cb, 20)
      cb:SetWidth(20)
      cb:SetHeight(20)
      
      -- 复选框文本美化
      local text = _G[cb:GetName() .. "Text"]
      if text then
        text:SetFont(pfUI.font_default, 12, "")
      end
    end
  end

  -- 滑块美化
  local sliders = {
    "AccountantTooltipScale",
    "AccountantFrameScale"
  }
  for _, sliderName in ipairs(sliders) do
    local slider = _G[sliderName]
    if slider then
      SkinSlider(slider)
    end
  end

  -- 下拉菜单美化
  if AccountantReportPeriodDropDown then
    SkinDropDown(AccountantReportPeriodDropDown)
  end

  -- 工具提示美化
  if AccountantTooltip then
    CreateBackdrop(AccountantTooltip, nil, nil, tooltip_alpha)
    CreateBackdropShadow(AccountantTooltip)
  end
end)