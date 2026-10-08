pfUI.addonskinner:RegisterSkin("TrainerSkills", function()
  -- upvalue the pfUI methods we use to avoid repeated lookups
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton,
    SkinCheckbox, SkinCollapseButton, SetHighlight, SkinScrollbar,
    HookScript, SkinDropDown =
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton,
    penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetHighlight, penv.SkinScrollbar,
    penv.HookScript, penv.SkinDropDown

  -- 安全地检查插件是否加载
  if not TrainerSkills then
    return
  end

  -- =========================================================
  -- 主窗口 TrainerSkills
  -- =========================================================
  local originalWidth, originalHeight = TrainerSkills:GetWidth(), TrainerSkills:GetHeight()

  StripTextures(TrainerSkills)
  CreateBackdrop(TrainerSkills, nil, nil, .85)
  TrainerSkills.backdrop:SetPoint("TOPLEFT", 0, 0)
  TrainerSkills.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)

  -- 恢复原始尺寸
  TrainerSkills:SetWidth(originalWidth)
  TrainerSkills:SetHeight(originalHeight)

  -- 修复：主窗口不可拖动
  -- XML 只声明了 movable="true"，但既没有 TitleRegion 也没有拖拽脚本，
  -- 1.12 客户端下必须自己挂 OnDragStart/OnDragStop 才能拖动
  if TrainerSkills.SetMovable then
    TrainerSkills:SetMovable(true)
    TrainerSkills:EnableMouse(true)
    TrainerSkills:RegisterForDrag("LeftButton")
    TrainerSkills:SetScript("OnDragStart", function()
      TrainerSkills:StartMoving()
    end)
    TrainerSkills:SetScript("OnDragStop", function()
      TrainerSkills:StopMovingOrSizing()
    end)
    -- 拖出屏幕边界保护（老客户端可能没有此 API，需判空）
    if TrainerSkills.SetClampedToScreen then
      TrainerSkills:SetClampedToScreen(true)
    end
  end

  -- 头像：TrainerSkills_Show() 每次打开窗口都会 SetPortraitTexture 重设贴图，
  -- 在 OnShow 之后补一次正方形裁剪，避免头像被拉成圆形原图比例
  if TrainerSkillsPortrait and HookScript then
    HookScript(TrainerSkills, "OnShow", function()
      if TrainerSkillsPortrait and TrainerSkillsPortrait.SetTexCoord then
        TrainerSkillsPortrait:SetTexCoord(.08, .92, .08, .92)
      end
    end)
  end

  -- 关闭按钮美化
  if TrainerSkillsCloseButton then
    SkinCloseButton(TrainerSkillsCloseButton, TrainerSkills.backdrop, -6, -6)
  end

  -- 标题文本美化
  if TrainerSkillsNameText then
    TrainerSkillsNameText:SetFont(pfUI.font_default, 14, "OUTLINE")
  end

  -- 问候文本美化
  if TrainerSkillsGreetingText then
    TrainerSkillsGreetingText:SetFont(pfUI.font_default, 11, "")
    TrainerSkillsGreetingText:SetTextColor(1, 1, 1)
  end

  -- =========================================================
  -- 下拉菜单（Npc / Character / Filter）
  -- 注意 SkinDropDown 签名是 (frame, cr, cg, cb, useSmall)，不要把宽度塞进第二参
  -- =========================================================
  local dropdownsToSkin = {
    "TrainerSkillsNpcDropDown",
    "TrainerSkillsCharDropDown",
    "TrainerSkillsFilterDropDown"
  }

  for _, dropdownName in pairs(dropdownsToSkin) do
    local dropdown = _G[dropdownName]
    if dropdown then
      local originalPoint, relativeTo, relativePoint, x, y = dropdown:GetPoint()
      local originalWidth, originalHeight = dropdown:GetWidth(), dropdown:GetHeight()

      StripTextures(dropdown)
      SkinDropDown(dropdown)

      -- 恢复原始位置和尺寸
      if originalPoint then
        dropdown:ClearAllPoints()
        dropdown:SetPoint(originalPoint, relativeTo, relativePoint, x, y)
      end
      if originalWidth then dropdown:SetWidth(originalWidth) end
      if originalHeight then dropdown:SetHeight(originalHeight) end

      -- 下拉菜单文本美化
      local dropdownText = _G[dropdownName.."Text"]
      if dropdownText then
        dropdownText:SetFont(pfUI.font_default, 11, "")
      end
    end
  end

  -- =========================================================
  -- 配置 / 取消按钮（保持原有位置）
  -- =========================================================
  local actionButtons = {
    "TrainerSkillsConfigButton",
    "TrainerSkillsCancelButton"
  }

  for _, buttonName in pairs(actionButtons) do
    local button = _G[buttonName]
    if button then
      local originalPoint, relativeTo, relativePoint, x, y = button:GetPoint()

      SkinButton(button)

      if originalPoint then
        button:ClearAllPoints()
        button:SetPoint(originalPoint, relativeTo, relativePoint, x, y)
      end
    end
  end

  -- =========================================================
  -- 技能列表 / 详情滚动区
  -- =========================================================
  if TrainerSkillsListScrollFrame then
    StripTextures(TrainerSkillsListScrollFrame)

    if TrainerSkillsListScrollFrameScrollBar then
      SkinScrollbar(TrainerSkillsListScrollFrameScrollBar)
    end
  end

  if TrainerSkillsDetailScrollFrame then
    StripTextures(TrainerSkillsDetailScrollFrame)

    if TrainerSkillsDetailScrollFrameScrollBar then
      SkinScrollbar(TrainerSkillsDetailScrollFrameScrollBar)
    end
  end

  -- =========================================================
  -- 技能行按钮 1-11
  -- 插件运行时用 SetNormalTexture(UI-Plus/MinusButton-Up) 切换折叠状态，
  -- 用 SkinCollapseButton 替换为 pfUI 的 +/- 图标（重写了 SetNormalTexture），
  -- 注意顺序：先 CreateBackdrop 再 SkinCollapseButton，保证 +/- 图标不被行底板盖住
  -- =========================================================
  for i = 1, 11 do
    local skillButton = _G["TrainerSkillsSkill"..i]
    if skillButton then
      local originalPoint, relativeTo, relativePoint, x, y = skillButton:GetPoint()

      -- 移除所有默认纹理
      StripTextures(skillButton)

      -- 创建行底板 + 鼠标悬停高亮
      CreateBackdrop(skillButton, nil, nil, .75)
      SetHighlight(skillButton)

      -- pfUI 加减号折叠图标（含 Highlight 纹理中和）
      SkinCollapseButton(skillButton)

      -- 恢复原始位置
      if originalPoint then
        skillButton:ClearAllPoints()
        skillButton:SetPoint(originalPoint, relativeTo, relativePoint, x, y)
      end

      -- 处理按钮文本
      local normalText = _G["TrainerSkillsSkill"..i.."NormalText"]
      local highlightText = _G["TrainerSkillsSkill"..i.."HighlightText"]
      local disabledText = _G["TrainerSkillsSkill"..i.."DisabledText"]

      if normalText then
        normalText:SetFont(pfUI.font_default, 11, "")
        normalText:SetTextColor(1, 1, 1)
      end

      if highlightText then
        highlightText:SetFont(pfUI.font_default, 11, "")
        highlightText:SetTextColor(1, 0.82, 0)
      end

      if disabledText then
        disabledText:SetFont(pfUI.font_default, 11, "")
        disabledText:SetTextColor(0.5, 0.5, 0.5)
      end

      -- 处理子文本（子专业行）
      local subText = _G["TrainerSkillsSkill"..i.."SubText"]
      if subText then
        subText:SetFont(pfUI.font_default, 10, "")
        subText:SetTextColor(0.8, 0.8, 0.8)
      end
    end
  end

  -- "ALL" 全部折叠按钮（与技能行同模板，同样有 +/- 状态切换）
  if TrainerSkillsExpandButtonFrame then
    StripTextures(TrainerSkillsExpandButtonFrame)
  end

  if TrainerSkillsCollapseAllButton then
    SkinCollapseButton(TrainerSkillsCollapseAllButton, true)

    local allText = _G["TrainerSkillsCollapseAllButtonText"]
    if allText then
      allText:SetFont(pfUI.font_default, 11, "")
      allText:SetTextColor(1, 1, 1)
    end
  end

  -- =========================================================
  -- 技能详情区
  -- =========================================================
  if TrainerSkillsDetailScrollChildFrame then
    CreateBackdrop(TrainerSkillsDetailScrollChildFrame, nil, nil, .75)
  end

  -- 技能图标：图标是运行时 SetNormalTexture 动态设置的，
  -- 加载时 GetNormalTexture() 为 nil，所以必须包装 SetNormalTexture，
  -- 每次设置图标后补正方形裁剪并铺满按钮
  if TrainerSkillsSkillIcon then
    StripTextures(TrainerSkillsSkillIcon)
    CreateBackdrop(TrainerSkillsSkillIcon)

    local origSetNormalTexture = TrainerSkillsSkillIcon.SetNormalTexture
    if origSetNormalTexture then
      TrainerSkillsSkillIcon.SetNormalTexture = function(self, tex)
        origSetNormalTexture(self, tex)
        local iconTexture = self:GetNormalTexture()
        if iconTexture and tex and tex ~= "" then
          iconTexture:ClearAllPoints()
          iconTexture:SetAllPoints(self)
          iconTexture:SetTexCoord(.08, .92, .08, .92)
        end
      end
    end
  end

  -- 技能名称文本美化
  if TrainerSkillsSkillName then
    TrainerSkillsSkillName:SetFont(pfUI.font_default, 13, "OUTLINE")
    TrainerSkillsSkillName:SetTextColor(1, 0.82, 0)
  end

  -- 子技能名称文本美化
  if TrainerSkillsSubSkillName then
    TrainerSkillsSubSkillName:SetFont(pfUI.font_default, 11, "")
    TrainerSkillsSubSkillName:SetTextColor(1, 1, 1)
  end

  -- 技能需求文本美化
  if TrainerSkillsSkillRequirements then
    TrainerSkillsSkillRequirements:SetFont(pfUI.font_default, 11, "")
    TrainerSkillsSkillRequirements:SetTextColor(1, 1, 1)
  end

  -- 费用标签美化
  if TrainerSkillsCostLabel then
    TrainerSkillsCostLabel:SetFont(pfUI.font_default, 11, "OUTLINE")
    TrainerSkillsCostLabel:SetTextColor(1, 1, 1)
  end

  -- 技能描述文本美化
  if TrainerSkillsSkillDescription then
    TrainerSkillsSkillDescription:SetFont(pfUI.font_default, 11, "")
    TrainerSkillsSkillDescription:SetTextColor(0.9, 0.9, 0.9)
  end

  -- =========================================================
  -- 金钱框架（保持原有位置）
  -- =========================================================
  if TrainerSkillsMoneyFrame then
    StripTextures(TrainerSkillsMoneyFrame)
    CreateBackdrop(TrainerSkillsMoneyFrame, nil, nil, .75)
  end

  if TrainerSkillsDetailMoneyFrame then
    StripTextures(TrainerSkillsDetailMoneyFrame)
    CreateBackdrop(TrainerSkillsDetailMoneyFrame, nil, nil, .75)
  end

  -- =========================================================
  -- 选中行高亮框：抬高底板层级，避免被技能行底板盖住
  -- =========================================================
  if TrainerSkillsSkillHighlightFrame then
    StripTextures(TrainerSkillsSkillHighlightFrame)
    CreateBackdrop(TrainerSkillsSkillHighlightFrame, nil, nil, .5)

    TrainerSkillsSkillHighlightFrame.backdrop:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    TrainerSkillsSkillHighlightFrame.backdrop:SetBackdropColor(1, 0.82, 0, 0.2)

    if TrainerSkillsSkill1 then
      TrainerSkillsSkillHighlightFrame.backdrop:SetFrameLevel(TrainerSkillsSkill1:GetFrameLevel() + 1)
    end
  end

  -- 工具提示美化
  if TrainerSkillsTT then
    CreateBackdrop(TrainerSkillsTT, nil, nil, .9)
  end

  -- =========================================================
  -- 配置窗口 TrainerSkillsConfig（原皮肤完全遗漏）
  -- =========================================================
  if TrainerSkillsConfig then
    StripTextures(TrainerSkillsConfig)
    CreateBackdrop(TrainerSkillsConfig, nil, nil, .85)

    -- 两个选项面板
    local configPanels = {
      "TrainerSkillsConfig_Options_Panel",
      "TrainerSkillsConfig_Save_Panel"
    }
    for _, panelName in pairs(configPanels) do
      local panel = _G[panelName]
      if panel then
        StripTextures(panel)
        CreateBackdrop(panel, nil, nil, .75)
      end
    end

    -- 8 个复选框
    local configCheckboxes = {
      "TrainerSkillsConfig_CB_Notify",
      "TrainerSkillsConfig_CB_MinimapButton",
      "TrainerSkillsConfig_CB_MinimapButtonMoveable",
      "TrainerSkillsConfig_CB_TrainerFilter",
      "TrainerSkillsConfig_CB_GrapDescription",
      "TrainerSkillsConfig_CB_GrapToolTips",
      "TrainerSkillsConfig_CB_GrabNpcNamesAndLocations",
      "TrainerSkillsConfig_CB_SavePlayerSkills"
    }
    for _, cbName in pairs(configCheckboxes) do
      local checkbox = _G[cbName]
      if checkbox then
        SkinCheckbox(checkbox, 20)

        local cbText = _G[cbName.."Text"]
        if cbText then
          cbText:SetFont(pfUI.font_default, 11, "")
        end
      end
    end

    -- 清库 / 关闭按钮
    if TrainerSkillsConfigPurgeButton then
      SkinButton(TrainerSkillsConfigPurgeButton)
    end

    if TrainerSkillsConfigCloseButton then
      SkinButton(TrainerSkillsConfigCloseButton)
    end
  end

  -- =========================================================
  -- 延迟补偿（C_Timer 在本客户端不一定存在，需判空）
  -- =========================================================
  local delayedFix = function()
    -- 确保标题/问候文本在可能的字体重置后仍使用 pfUI 字体
    local textElements = {
      "TrainerSkillsNameText",
      "TrainerSkillsGreetingText"
    }

    for _, textName in pairs(textElements) do
      local text = _G[textName]
      if text and text.SetFont then
        text:SetFont(pfUI.font_default, select(2, text:GetFont()) or 12, "")
      end
    end

    -- 确保下拉/按钮等元素可见（部分控件在皮肤化后可能被意外隐藏）
    local elementsToShow = {
      "TrainerSkillsDeleteTrainerButton",
      "TrainerSkillsDeleteCharacterButton",
      "TrainerSkillsNpcDropDown",
      "TrainerSkillsCharDropDown",
      "TrainerSkillsFilterDropDown",
      "TrainerSkillsConfigButton",
      "TrainerSkillsCancelButton"
    }

    for _, elementName in pairs(elementsToShow) do
      local element = _G[elementName]
      if element then
        element:Show()
        element:SetAlpha(1)
      end
    end
  end

  if C_Timer and C_Timer.After then
    C_Timer.After(0.5, delayedFix)
  else
    delayedFix()
  end

  pfUI.addonskinner:UnregisterSkin("TrainerSkills")
end)
