-- OneBag, OneBank & OneViewFrame pfUI 美化
pfUI.addonskinner:RegisterSkin("OneBag", function()
  if not OneBagFrame then return end

  local penv = pfUI:GetEnvironment()
  local StripTextures, CreateBackdrop, SkinButton, SkinCloseButton = 
    penv.StripTextures, penv.CreateBackdrop, penv.SkinButton, penv.SkinCloseButton

  -- OneBag 主框架
  StripTextures(OneBagFrame)
  CreateBackdrop(OneBagFrame, nil, nil, .75)

    -- OneBag 关闭按钮
 if OneBagFrameCloseButton then
    SkinCloseButton(OneBagFrameCloseButton)
    OneBagFrameCloseButton:SetPoint("TOPRIGHT", OneBagFrame, "TOPRIGHT", -5, -5)
  end 

  -- OneBag 搜索框
  if OneBagFrame.searchBox then
    CreateBackdrop(OneBagFrame.searchBox, nil, true)
  end

  -- OneBag 背包框架
  if OBBagFram then
    StripTextures(OBBagFram)
    CreateBackdrop(OBBagFram, nil, nil, .75)
  end
  
  -- OBBBagFra 框架美化（新增）
  if OBBBagFra then
    StripTextures(OBBBagFra)
    CreateBackdrop(OBBBagFra, nil, nil, .75)
  end
  
  -- OneBank 相关框架美化
  if OneBankFrame then
    -- OneBank 主框架
    StripTextures(OneBankFrame)
    CreateBackdrop(OneBankFrame, nil, nil, .75)
    
    -- OneBank 关闭按钮
    if OneBankFrameCloseButton then
      SkinCloseButton(OneBankFrameCloseButton)
      OneBankFrameCloseButton:SetPoint("TOPRIGHT", OneBankFrame, "TOPRIGHT", -5, -5)
    end

    -- OneBank 搜索框（如果存在）
    if OneBankFrame.searchBox then
      CreateBackdrop(OneBankFrame.searchBox, nil, true)
    end

    -- OneBank 背包框架
    if OBBankFram then
      StripTextures(OBBankFram)
      CreateBackdrop(OBBankFram, nil, nil, .75)
    end
  end
  
  -- OneViewFrame 相关框架美化
  if OneViewFrame then
    -- OneViewFrame 主框架
    StripTextures(OneViewFrame)
    CreateBackdrop(OneViewFrame, nil, nil, .75)
    
    -- OneViewFrame 关闭按钮
    if OneViewFrameCloseButton then
      SkinCloseButton(OneViewFrameCloseButton)
      OneViewFrameCloseButton:SetPoint("TOPRIGHT", OneViewFrame, "TOPRIGHT", -5, -5)
    end

    -- OneViewFrame 搜索框（如果存在）
    if OneViewFrame.searchBox then
      CreateBackdrop(OneViewFrame.searchBox, nil, true)
    end

    -- OneViewFrame 容器框架
    if OBViewFram then
      StripTextures(OBViewFram)
      CreateBackdrop(OBViewFram, nil, nil, .75)
    end
  end

  -- OneRingFrame（钥匙链）相关框架美化
  if OneRingFrame then
    -- OneRing 主框架
    StripTextures(OneRingFrame)
    CreateBackdrop(OneRingFrame, nil, nil, .75)

    -- OneRing 关闭按钮
    if OneRingFrameCloseButton then
      SkinCloseButton(OneRingFrameCloseButton)
      OneRingFrameCloseButton:SetPoint("TOPRIGHT", OneRingFrame, "TOPRIGHT", -5, -5)
    end
  end

  -- ===== 新增：极简风格美化背包格子 =====
  local function ApplyBagSlotStyle(slot)
    if not slot then return end
    -- 清除原有纹理（防止与pfUI默认样式冲突）
    StripTextures(slot)
    -- 极简风格：纯白细边框（1px），深色背景
    slot:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    slot:SetBackdropColor(0.12, 0.12, 0.12)       -- 深色背景
    slot:SetBackdropBorderColor(0.30, 0.30, 0.30) -- 灰色边框
  end

  local function ApplyStyleToContainer(container)
    if not container then return end
    for i = 1, container:GetNumChildren() do
      local child = select(i, container:GetChildren())
      if child and child:GetObjectType() == "Button" then
        ApplyBagSlotStyle(child)
      end
    end
  end

  -- 对已知的容器框架应用格子样式
  ApplyStyleToContainer(OBBagFram)
  ApplyStyleToContainer(OBBBagFra)
  ApplyStyleToContainer(OBBankFram)
  ApplyStyleToContainer(OBViewFram)
  -- ===== 新增结束 =====
end)