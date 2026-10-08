pfUI.addonskinner:RegisterSkin("AutoMarker", function()
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinCheckbox, SkinEditBox, SkinFrame, SetAllPointsOffset, SetHighlight, HookScript =
    penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinCheckbox, penv.SkinEditBox, penv.SetAllPointsOffset, penv.SetHighlight

  -- 获取 SkinDropDown（兼容多种来源）
  local SkinDropDown = pfUI.skin and pfUI.skin.SkinDropDown or
                       (pfUI.api and pfUI.api.SkinDropDown) or
                       penv.SkinDropDown

  -- 美化主框架（完全保留原样）
  local frame = _G["AutoMarkerUIFrame"]
  if frame then
    StripTextures(frame)
    CreateBackdrop(frame, nil, nil, .75)
    local title = _G["AutoMarkerUIFrameTitle"]
    if title then
      title:SetParent(frame.backdrop)
      title:SetPoint("TOP", frame.backdrop, "TOP", 0, -5)
    end
    local closeBtn = _G["AutoMarkerUIFrameCloseButton"]
    if closeBtn then
      SkinCloseButton(closeBtn, frame.backdrop, -6, -6)
    end
    local buttonNames = {
      "AutoMarkerUIFrameSetPackButton",
      "AutoMarkerUIFramePackNamePlusButton",
      "AutoMarkerUIFrameEnableButton",
      "AutoMarkerUIFrameScanButton",
      "AutoMarkerUIFrameMarkDistButton",
      "AutoMarkerUIFrameQuickMarkButton",
      "AutoMarkerUIFrameClearMarksButton",
      "AutoMarkerUIFrameAddTargetButton",
      "AutoMarkerUIFrameRemoveTargetButton",
    }
    for _, name in ipairs(buttonNames) do
      local btn = _G[name]
      if btn then SkinButton(btn) end
    end
    local editPack = _G["AutoMarkerUIFramePackNameEditBox"]
    if editPack then
      StripTextures(editPack, true, "BACKGROUND")
      CreateBackdrop(editPack, nil, true)
    end
    local editDist = _G["AutoMarkerUIFrameMarkDistEditBox"]
    if editDist then
      StripTextures(editDist, true, "BACKGROUND")
      CreateBackdrop(editDist, nil, true)
    end
    local nameEdit = _G["AutoMarkerTargetNameEditBox"]
    if nameEdit then
      StripTextures(nameEdit, true, "BACKGROUND")
      CreateBackdrop(nameEdit, nil, true)
    end
    local check = _G["AutoMarkerUIFrameMarkDifferentCheckBox"]
    if check then
      SkinCheckbox(check)
    end
    local check = _G["AutoMarkerUIFrameAutoMarkCheckBox"]
    if check then
      SkinCheckbox(check)
    end
  end

  -- 美化目标配置界面（动态创建）
  local function SkinTargetConfigUI()
    local configFrame = _G["AutoMarkerTargetConfigPanel"]
    if not configFrame then return end

    StripTextures(configFrame)
    CreateBackdrop(configFrame, nil, nil, .75)

    local closeBtn = _G["AutoMarkerTargetConfigPanelCloseButton"]
    if closeBtn then
      SkinCloseButton(closeBtn, configFrame.backdrop, -6, -6)
    end

    local btnNames = {
      "AutoMarkerTargetConfigPanelSchemePanelAddSchemeBtn",
      "AutoMarkerTargetConfigPanelSchemePanelDelSchemeBtn",
      "AutoMarkerTargetConfigPanelAddTargetBtn",
    }
    for _, name in ipairs(btnNames) do
      local btn = _G[name]
      if btn then SkinButton(btn) end
    end

    local rangeEdit = _G["AutoMarkerTargetConfigPanelRangePanelRangeEditBox"]
    if rangeEdit then
      StripTextures(rangeEdit, true, "BACKGROUND")
      CreateBackdrop(rangeEdit, nil, true)
    end

    local nameEdit = _G["AutoMarkerTargetNameEditBox"]
    if nameEdit then
      StripTextures(nameEdit, true, "BACKGROUND")
      CreateBackdrop(nameEdit, nil, true)
    end

    -- 美化方案下拉框（关键修复点）
    local schemeDropdown = _G["AutoMarkerSchemeDropdown"]
    if schemeDropdown and SkinDropDown then
      -- 使用 pcall 保护，避免该处错误中断整体皮肤流程
      local ok, err = pcall(function()
        StripTextures(schemeDropdown)
        SkinDropDown(schemeDropdown, nil, nil, nil, true)
        -- 替换原 `schemeDropdown:HookScript` 为 `hooksecurefunc`
        hooksecurefunc(schemeDropdown, "OnShow", function()
          SkinDropDown(schemeDropdown, nil, nil, nil, true)
        end)
      end)
      if not ok then
        -- 可选的错误日志（调试时打开）
        -- print("AutoMarker skin error:", err)
      end
    end
  end

  -- 钩住创建函数
  if type(CreateAutoMarkerTargetConfigUI) == "function" then
    hooksecurefunc("CreateAutoMarkerTargetConfigUI", SkinTargetConfigUI)
  else
    SkinTargetConfigUI()
  end
end)