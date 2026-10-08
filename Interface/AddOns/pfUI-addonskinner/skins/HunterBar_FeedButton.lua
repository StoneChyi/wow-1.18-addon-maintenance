pfUI.addonskinner:RegisterSkin("HunterBar_FeedButton", function()
  -- 获取pfUI环境中的方法
  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinCloseButton, SkinButton, SkinArrowButton, 
    SkinCheckbox, SkinCollapseButton, SetAllPointsOffset, SetHighlight, SkinScrollbar, 
    HookScript, hooksecurefunc, SkinDropDown, SkinSlider, SkinTab, SkinItemButton = 
  penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton, penv.SkinButton, penv.SkinArrowButton, 
  penv.SkinCheckbox, penv.SkinCollapseButton, penv.SetAllPointsOffset, penv.SetHighlight, penv.SkinScrollbar, 
  penv.HookScript, penv.hooksecurefunc, penv.SkinDropDown, penv.SkinSlider, penv.SkinTab, penv.SkinItemButton

  local noop = function() end




  -- 皮肤化喂养按钮
  if FeedButton then
    -- 使用pfUI的物品按钮皮肤化函数
    SkinItemButton(FeedButton)
    
    -- 移除默认边框并创建pfUI风格的背景
    StripTextures(FeedButton)
    CreateBackdrop(FeedButton, nil, nil, .85)
    FeedButton:SetBackdropBorderColor(.3, .3, .3, 1)
    
    -- 调整按钮大小以匹配pfUI的标准物品按钮
    FeedButton:SetWidth(36)
    FeedButton:SetHeight(36)
    
    -- 修复按钮位置 - 确保按钮正确锚定到移动框
    FeedButton:ClearAllPoints()
    FeedButton:SetPoint("CENTER", FeedButtonMover or FeedButtonFrame, "CENTER", 0, 0)
    
    -- 皮肤化图标纹理
    if FeedButtonIconTexture then
      FeedButtonIconTexture:SetTexCoord(.08, .92, .08, .92)
      FeedButtonIconTexture:ClearAllPoints()
      FeedButtonIconTexture:SetPoint("TOPLEFT", FeedButton, "TOPLEFT", 2, -2)
      FeedButtonIconTexture:SetPoint("BOTTOMRIGHT", FeedButton, "BOTTOMRIGHT", -2, 2)
    end
    
    -- 皮肤化计数警告文本
    if FeedButtonCountWarn then
      FeedButtonCountWarn:SetFont(pfUI.font_default, 16, "OUTLINE")
      FeedButtonCountWarn:SetTextColor(1, 0.2, 0.2, 1)
      FeedButtonCountWarn:ClearAllPoints()
      FeedButtonCountWarn:SetPoint("BOTTOMRIGHT", FeedButton, "BOTTOMRIGHT", -2, 2)
    end
    
    -- 移除默认冷却帧并创建pfUI风格的冷却帧
    local cooldown = _G[FeedButton:GetName().."Cooldown"]
    if cooldown then
      cooldown:ClearAllPoints()
      cooldown:SetPoint("TOPLEFT", FeedButton, "TOPLEFT", 2, -2)
      cooldown:SetPoint("BOTTOMRIGHT", FeedButton, "BOTTOMRIGHT", -2, 2)
    end
    
    -- 皮肤化正常状态纹理
    local normalTexture = _G[FeedButton:GetName().."NormalTexture"]
    if normalTexture then
      normalTexture:SetTexture(nil) -- 移除默认纹理
    end
  end


  -- 延迟皮肤化以确保所有元素都已创建
  C_Timer.After(1, function()
    -- 延迟后重新应用皮肤化
    if FeedButton then
      SkinItemButton(FeedButton)
      CreateBackdrop(FeedButton, nil, nil, .85)
      
      -- 修复按钮位置
      FeedButton:ClearAllPoints()
      FeedButton:SetPoint("CENTER", FeedButtonMover or FeedButtonFrame, "CENTER", 0, 0)
      
      if FeedButtonIconTexture then
        FeedButtonIconTexture:SetTexCoord(.08, .92, .08, .92)
      end
      
      if FeedButtonCountWarn then
        FeedButtonCountWarn:SetFont(pfUI.font_default, 16, "OUTLINE")
      end
    end
    
    if FeedButtonMover then
      -- 根据初始锁定状态更新移动框外观
      if FeedPetButton_Food and FeedPetButton_Food.Locked then
        FeedButtonMover:SetBackdropBorderColor(.3, .3, .3, 0.5)
        local moverTex = FeedButtonMover:GetRegions()
        if moverTex and moverTex.SetVertexColor then
          moverTex:SetVertexColor(0.3, 0.3, 0.3, 0.3)
        end
      else
        FeedButtonMover:SetBackdropBorderColor(.8, .8, .8, 1)
        local moverTex = FeedButtonMover:GetRegions()
        if moverTex and moverTex.SetVertexColor then
          moverTex:SetVertexColor(0.5, 0.5, 0.5, 0.7)
        end
      end
    end
  end)



  pfUI.addonskinner:UnregisterSkin("HunterBar_FeedButton")
end)