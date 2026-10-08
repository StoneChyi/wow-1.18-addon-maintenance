pfUI.addonskinner:RegisterSkin("DoiteAuras", function()
  -- ============================================
  -- ENVIRONMENT & FONT SETUP
  -- ============================================
  local penv = pfUI:GetEnvironment()
  local StripTextures = penv.StripTextures
  local CreateBackdrop = penv.CreateBackdrop
  local SkinButton = penv.SkinButton
  local SkinCheckbox = penv.SkinCheckbox
  local SkinCloseButton = penv.SkinCloseButton
  local SkinScrollbar = penv.SkinScrollbar
  local SkinDropDown = penv.SkinDropDown
  local SkinSlider = penv.SkinSlider
  local SkinCollapseButton = penv.SkinCollapseButton

  -- ============================================
  -- UTILITY FUNCTIONS
  -- ============================================
  local function ApplyFrameSkin(frame, alpha)
    if not frame or frame.pfui_skinned then return end
    StripTextures(frame, true)
    CreateBackdrop(frame, nil, nil, alpha or .75)
    frame.pfui_skinned = true
  end

  local function SkinEditBox(editbox)
    if not editbox or editbox.pfui_skinned then return end
    StripTextures(editbox, true, "BACKGROUND")
    CreateBackdrop(editbox, nil, true)
    editbox.pfui_skinned = true
  end

  -- ============================================
  -- STATIC FRAME SKINNING (called once)
  -- ============================================
  local function SkinAllFrames()
    -- 主框架
    if DoiteAurasFrame and not DoiteAurasFrame.pfui_skinned then
      ApplyFrameSkin(DoiteAurasFrame)

      -- 关闭按钮（未命名）
      for _, child in ipairs({DoiteAurasFrame:GetChildren()}) do
        if child:GetObjectType() == "Button" and not child:GetName() then
          SkinCloseButton(child, DoiteAurasFrame.backdrop, -5, -6)
        end
      end

      -- 已知按钮（如果存在）
      if DoiteAurasExportButton then SkinButton(DoiteAurasExportButton) end
      if DoiteAurasImportButton then SkinButton(DoiteAurasImportButton) end
      if DoiteAurasSettingsButton then SkinButton(DoiteAurasSettingsButton) end
      if DoiteAurasAddBtn then SkinButton(DoiteAurasAddBtn) end
      if DoiteAurasTestAllBtn then SkinButton(DoiteAurasTestAllBtn) end

      -- 输入框
      if DoiteAurasInput then SkinEditBox(DoiteAurasInput) end

      -- 滚动条
      if DoiteAurasScrollScrollBar then SkinScrollbar(DoiteAurasScrollScrollBar) end
      if DoiteConditionsScrollScrollBar then SkinScrollbar(DoiteConditionsScrollScrollBar) end

      -- ============================================
      -- 新增：美化下拉菜单（技能、物品、条）
      -- ============================================
      if DoiteAurasAbilityDropDown then
        SkinDropDown(DoiteAurasAbilityDropDown)
        -- 同时美化下拉按钮（如果有单独按钮）
        local btn = _G["DoiteAurasAbilityDropDownButton"]
        if btn and not btn.pfui_skinned then
          SkinButton(btn)
          btn.pfui_skinned = true
        end
      end
      if DoiteAurasItemDropDown then
        SkinDropDown(DoiteAurasItemDropDown)
        local btn = _G["DoiteAurasItemDropDownButton"]
        if btn and not btn.pfui_skinned then
          SkinButton(btn)
          btn.pfui_skinned = true
        end
      end
      if DoiteAurasBarDropDown then
        SkinDropDown(DoiteAurasBarDropDown)
        local btn = _G["DoiteAurasBarDropDownButton"]
        if btn and not btn.pfui_skinned then
          SkinButton(btn)
          btn.pfui_skinned = true
        end
      end

      DoiteAurasFrame.pfui_skinned = true
    end

    -- 编辑/条件框架
    if DoiteConditionsFrame and not DoiteConditionsFrame.pfui_skinned then
      ApplyFrameSkin(DoiteConditionsFrame)

      -- 关闭按钮
      for _, child in ipairs({DoiteConditionsFrame:GetChildren()}) do
        if child:GetObjectType() == "Button" and not child:GetName() then
          SkinCloseButton(child, DoiteConditionsFrame.backdrop, -5, -6)
        end
      end

      -- 滑块
      if DoiteConditions_SpacingSlider then SkinSlider(DoiteConditions_SpacingSlider) end
      if DoiteConditions_SliderX then SkinSlider(DoiteConditions_SliderX) end
      if DoiteConditions_SliderY then SkinSlider(DoiteConditions_SliderY) end
      if DoiteConditions_SliderSize then SkinSlider(DoiteConditions_SliderSize) end

      -- 复选框（假设是框架的成员）
      if DoiteConditionsFrame.leaderCB then SkinCheckbox(DoiteConditionsFrame.leaderCB, 20) end
      if DoiteConditionsFrame.categoryCheck then SkinCheckbox(DoiteConditionsFrame.categoryCheck, 20) end

      -- 编辑框
      if DoiteConditionsFrame.categoryInput then SkinEditBox(DoiteConditionsFrame.categoryInput) end
      if DoiteConditionsFrame.sliderXBox then SkinEditBox(DoiteConditionsFrame.sliderXBox) end
      if DoiteConditionsFrame.sliderYBox then SkinEditBox(DoiteConditionsFrame.sliderYBox) end
      if DoiteConditionsFrame.sliderSizeBox then SkinEditBox(DoiteConditionsFrame.sliderSizeBox) end
      if DoiteConditionsFrame.spacingEdit then SkinEditBox(DoiteConditionsFrame.spacingEdit) end

      -- 按钮
      if DoiteConditions_GridBtn then SkinButton(DoiteConditions_GridBtn) end
      if DoiteConditionsFrame.categoryButton then SkinButton(DoiteConditionsFrame.categoryButton) end
      if DoiteConditionsFrame.testAllBtn then SkinButton(DoiteConditionsFrame.testAllBtn) end

      DoiteConditionsFrame.pfui_skinned = true
    end

    -- 导出框架
    if DoiteAurasExportFrame and not DoiteAurasExportFrame.pfui_skinned then
      ApplyFrameSkin(DoiteAurasExportFrame)

      -- 关闭按钮
      for _, child in ipairs({DoiteAurasExportFrame:GetChildren()}) do
        if child:GetObjectType() == "Button" and not child:GetName() then
          SkinCloseButton(child, DoiteAurasExportFrame.backdrop, -5, -6)
          break
        end
      end

      if DoiteAurasExportScrollScrollBar then SkinScrollbar(DoiteAurasExportScrollScrollBar) end
      if DoiteAurasExportEditBox then SkinEditBox(DoiteAurasExportEditBox) end
      if DoiteAurasCreateExportButton then SkinButton(DoiteAurasCreateExportButton) end
      if DoiteAurasClearExportButton then SkinButton(DoiteAurasClearExportButton) end
      if DoiteAurasCopyExportButton then SkinButton(DoiteAurasCopyExportButton) end

      DoiteAurasExportFrame.pfui_skinned = true
    end

    -- 导入框架
    if DoiteAurasImportFrame and not DoiteAurasImportFrame.pfui_skinned then
      ApplyFrameSkin(DoiteAurasImportFrame)

      for _, child in ipairs({DoiteAurasImportFrame:GetChildren()}) do
        if child:GetObjectType() == "Button" and not child:GetName() then
          SkinCloseButton(child, DoiteAurasImportFrame.backdrop, -5, -6)
          break
        end
      end

      if DoiteAurasImportScrollScrollBar then SkinScrollbar(DoiteAurasImportScrollScrollBar) end
      if DoiteAurasImportEditBox then SkinEditBox(DoiteAurasImportEditBox) end
      if DoiteAurasImportDoButton then SkinButton(DoiteAurasImportDoButton) end

      DoiteAurasImportFrame.pfui_skinned = true
    end

    -- 设置框架
    if DoiteAurasSettingsFrame and not DoiteAurasSettingsFrame.pfui_skinned then
      ApplyFrameSkin(DoiteAurasSettingsFrame)

      local unnamedCount = 0
      for _, child in ipairs({DoiteAurasSettingsFrame:GetChildren()}) do
        if child:GetObjectType() == "Button" then
          if not child:GetName() then
            unnamedCount = unnamedCount + 1
            if unnamedCount == 1 then
              SkinCloseButton(child, DoiteAurasSettingsFrame.backdrop, -5, -6)
            else
              SkinButton(child)
            end
          else
            SkinButton(child)
          end
        end
      end

      DoiteAurasSettingsFrame.pfui_skinned = true
    end

    -- 类别确认对话框
    if DoiteCond_CategoryConfirmFrame and not DoiteCond_CategoryConfirmFrame.pfui_skinned then
      ApplyFrameSkin(DoiteCond_CategoryConfirmFrame)

      for _, child in ipairs({DoiteCond_CategoryConfirmFrame:GetChildren()}) do
        if child:GetObjectType() == "Frame" then
          StripTextures(child, true)
          CreateBackdrop(child, nil, nil, .85)
          for _, btn in ipairs({child:GetChildren()}) do
            if btn:GetObjectType() == "Button" then
              SkinButton(btn)
            end
          end
        end
      end

      DoiteCond_CategoryConfirmFrame.pfui_skinned = true
    end
  end

  -- ============================================
  -- DYNAMIC LIST ELEMENTS SKINNING (called on show)
  -- ============================================
  local function SkinListElements()
    if not DoiteAurasListContent then return end

    for _, row in ipairs({DoiteAurasListContent:GetChildren()}) do
      if row then
        -- 折叠/展开按钮
        if row.toggleBtn and not row.toggleBtn.pfui_skinned then
          SkinButton(row.toggleBtn)
          row.toggleBtn.pfui_skinned = true
        end
        -- 编辑按钮
        if row.editBtn and not row.editBtn.pfui_skinned then
          SkinButton(row.editBtn)
          row.editBtn.pfui_skinned = true
        end
        -- 删除按钮
        if row.removeBtn and not row.removeBtn.pfui_skinned then
          SkinButton(row.removeBtn)
          row.removeBtn.pfui_skinned = true
        end
        -- 上下箭头
        if row.upBtn and not row.upBtn.pfui_skinned then
          CreateBackdrop(row.upBtn, nil, nil, .75)
          if row.upBtn.backdrop then
            row.upBtn.backdrop:SetFrameLevel(row.upBtn:GetFrameLevel() - 1)
          end
          local tex = row.upBtn:GetNormalTexture()
          if tex then tex:SetTexCoord(.2, .8, .2, .8) end
          row.upBtn.pfui_skinned = true
        end
        if row.downBtn and not row.downBtn.pfui_skinned then
          CreateBackdrop(row.downBtn, nil, nil, .75)
          if row.downBtn.backdrop then
            row.downBtn.backdrop:SetFrameLevel(row.downBtn:GetFrameLevel() - 1)
          end
          local tex = row.downBtn:GetNormalTexture()
          if tex then tex:SetTexCoord(.2, .8, .2, .8) end
          row.downBtn.pfui_skinned = true
        end
        -- 复选框
        if row.disableCheck and not row.disableCheck.pfui_skinned then
          SkinCheckbox(row.disableCheck, 14)
          row.disableCheck.pfui_skinned = true
        end
        if row.sortTime and not row.sortTime.pfui_skinned then
          SkinCheckbox(row.sortTime, 14)
          row.sortTime.pfui_skinned = true
        end
        if row.sortPrio and not row.sortPrio.pfui_skinned then
          SkinCheckbox(row.sortPrio, 14)
          row.sortPrio.pfui_skinned = true
        end
        if row.fixedCheck and not row.fixedCheck.pfui_skinned then
          SkinCheckbox(row.fixedCheck, 14)
          row.fixedCheck.pfui_skinned = true
        end
      end
    end
  end

  local function SkinConditionRows()
    if not DoiteConditionsFrame then return end

    local anchors = {DoiteConditionsFrame.abilityAuraAnchor, DoiteConditionsFrame.auraAuraAnchor, DoiteConditionsFrame.itemAuraAnchor}
    for _, anchor in ipairs(anchors) do
      if anchor then
        for _, row in ipairs({anchor:GetChildren()}) do
          if row then
            if row.btn1 and not row.btn1.pfui_skinned then
              SkinButton(row.btn1)
              row.btn1.pfui_skinned = true
            end
            if row.btn2 and not row.btn2.pfui_skinned then
              SkinButton(row.btn2)
              row.btn2.pfui_skinned = true
            end
            if row.btn3 and not row.btn3.pfui_skinned then
              SkinButton(row.btn3)
              row.btn3.pfui_skinned = true
            end
            if row.closeBtn and not row.closeBtn.pfui_skinned then
              SkinButton(row.closeBtn)
              row.closeBtn.pfui_skinned = true
            end
            if row.addButton and not row.addButton.pfui_skinned then
              SkinButton(row.addButton)
              row.addButton.pfui_skinned = true
            end
            if row.editBox and not row.editBox.pfui_skinned then
              SkinEditBox(row.editBox)
              row.editBox.pfui_skinned = true
            end
            if row.checkBox and not row.checkBox.pfui_skinned then
              SkinCheckbox(row.checkBox, 16)
              row.checkBox.pfui_skinned = true
            end
            -- 注意：下拉菜单不处理，避免错误（但此处是条件行内的下拉菜单，可单独处理）
            -- 如果希望美化条件行内的下拉菜单，可在此添加类似处理，但为避免复杂，先保留原注释
          end
        end
      end
    end
  end

  -- ============================================
  -- WAIT FOR FRAMES TO EXIST AND APPLY SKIN
  -- ============================================
  local waitFrame = CreateFrame("Frame")
  waitFrame:SetScript("OnUpdate", function()
    if DoiteAurasFrame then
      -- 主框架已存在，应用静态皮肤
      SkinAllFrames()

      -- 为主框架设置 OnShow 钩子，以便每次显示时重新处理动态行
      local origOnShow = DoiteAurasFrame:GetScript("OnShow")
      DoiteAurasFrame:SetScript("OnShow", function()
        if origOnShow then origOnShow() end
        SkinListElements()
        SkinConditionRows()
      end)

      -- 如果当前已显示，立即皮肤动态行
      if DoiteAurasFrame:IsVisible() then
        SkinListElements()
        SkinConditionRows()
      end

      -- 为编辑框架也设置 OnShow 钩子（它可能动态创建行）
      if DoiteConditionsFrame then
        local origCondOnShow = DoiteConditionsFrame:GetScript("OnShow")
        DoiteConditionsFrame:SetScript("OnShow", function()
          if origCondOnShow then origCondOnShow() end
          SkinConditionRows()
        end)
        if DoiteConditionsFrame:IsVisible() then
          SkinConditionRows()
        end
      end

      -- 停止等待
      waitFrame:SetScript("OnUpdate", nil)
    end
  end)

  pfUI.addonskinner:UnregisterSkin("DoiteAuras")
end)