pfUI.addonskinner:RegisterSkin("SUCC-bag", function()
  if not SUCC_bag then return end

  -- 获取 pfUI 环境中的函数
  local penv = pfUI:GetEnvironment()
  local SkinButton, StripTextures, CreateBackdrop, SkinCloseButton = 
    penv.SkinButton, penv.StripTextures, penv.CreateBackdrop, penv.SkinCloseButton

  

  -- 主背包框架
  SUCC_bag:SetBackdrop(nil)
  CreateBackdrop(SUCC_bag, nil, nil, .75)
  
  if SUCC_bag.closeButton then
    SkinCloseButton(SUCC_bag.closeButton, SUCC_bag.backdrop, -6, -6)
  end
  
  if SUCC_bag.searchFrame then
    StripTextures(SUCC_bag.searchFrame)
    
    local point, relativeTo, relativePoint, xOfs, yOfs = SUCC_bag.searchFrame:GetPoint()
    if point then
      SUCC_bag.searchFrame:ClearAllPoints()
      SUCC_bag.searchFrame:SetPoint(point, relativeTo, relativePoint, xOfs - 14, yOfs - 2)
    end
    
    if SUCC_bag.searchFrame.edit then
      StripTextures(SUCC_bag.searchFrame.edit)
      CreateBackdrop(SUCC_bag.searchFrame.edit, nil, true)
    end
    
    if SUCC_bag.searchFrame.button then
      SkinCloseButton(SUCC_bag.searchFrame.button)
      local point, relativeTo, relativePoint, xOfs, yOfs = SUCC_bag.searchFrame.button:GetPoint()
      if point then
        SUCC_bag.searchFrame.button:ClearAllPoints()
        SUCC_bag.searchFrame.button:SetPoint(point, relativeTo, relativePoint, xOfs - 17, yOfs)
      end
    end
  end
  
  -- 银行框架
  if SUCC_bag.bank then
    SUCC_bag.bank:SetBackdrop(nil)
    CreateBackdrop(SUCC_bag.bank, nil, nil, .75)
    
    -- 关闭按钮
    if SUCC_bag.bank.closeButton then
      SkinCloseButton(SUCC_bag.bank.closeButton, SUCC_bag.bank.backdrop, -6, -6)
    end
    
    -- 银行搜索按钮美化
    if SUCC_bag.bank.searchFrame then
      StripTextures(SUCC_bag.bank.searchFrame)
      
      local point, relativeTo, relativePoint, xOfs, yOfs = SUCC_bag.bank.searchFrame:GetPoint()
      if point then
        SUCC_bag.bank.searchFrame:ClearAllPoints()
        SUCC_bag.bank.searchFrame:SetPoint(point, relativeTo, relativePoint, xOfs - 14, yOfs - 2)
      end
      
      if SUCC_bag.bank.searchFrame.edit then
        StripTextures(SUCC_bag.bank.searchFrame.edit)
        CreateBackdrop(SUCC_bag.bank.searchFrame.edit, nil, true)
      end
      
      if SUCC_bag.bank.searchFrame.button then
        SkinCloseButton(SUCC_bag.bank.searchFrame.button)
        local point, relativeTo, relativePoint, xOfs, yOfs = SUCC_bag.bank.searchFrame.button:GetPoint()
        if point then
          SUCC_bag.bank.searchFrame.button:ClearAllPoints()
          SUCC_bag.bank.searchFrame.button:SetPoint(point, relativeTo, relativePoint, xOfs - 17, yOfs)
        end
      end
    end
  end
  
  -- 钥匙链框架
  if SUCC_bag.keyring then
    SUCC_bag.keyring:SetBackdrop(nil)
    CreateBackdrop(SUCC_bag.keyring, nil, nil, .75)
    
    -- 关闭按钮
    if SUCC_bag.keyring.closeButton then
      SkinCloseButton(SUCC_bag.keyring.closeButton, SUCC_bag.keyring.backdrop, -6, -6)
    end
  end
  
  pfUI.addonskinner:UnregisterSkin("SUCC-bag")
end)