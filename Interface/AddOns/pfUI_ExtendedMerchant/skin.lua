-- pfUI Extended Merchant Skin
-- 为扩展商人界面应用 pfUI 皮肤

-- 注册皮肤到 pfUI
pfUI:RegisterSkin("Extended Merchant", "vanilla", function()
    local rawborder, border = GetBorderSize()
    local bpad = rawborder > 1 and border - GetPerfectPixel() or GetPerfectPixel()
    
    -- 清除原始纹理
    StripTextures(MerchantFrame)
    
    -- 创建 pfUI 背景
    CreateBackdrop(MerchantFrame, nil, nil, .75)
    CreateBackdropShadow(MerchantFrame)
    
    -- 设置背景位置
    MerchantFrame.backdrop:SetPoint("TOPLEFT", 10, -10)
    MerchantFrame.backdrop:SetPoint("BOTTOMRIGHT", -32, 58)
    MerchantFrame:SetHitRectInsets(10, 32, 10, 58)
    
    -- 启用移动
    EnableMovable(MerchantFrame)
    
    -- 关闭按钮
    SkinCloseButton(MerchantFrameCloseButton, MerchantFrame.backdrop, -6, -6)
    
    -- 禁用背景层
    MerchantFrame:DisableDrawLayer("BACKGROUND")
    
    -- 标签页
    SkinTab(MerchantFrameTab1)
    MerchantFrameTab1:ClearAllPoints()
    MerchantFrameTab1:SetPoint("TOPLEFT", MerchantFrame.backdrop, "BOTTOMLEFT", bpad, -(border + (border == 1 and 1 or 2)))
    
    SkinTab(MerchantFrameTab2)
    MerchantFrameTab2:ClearAllPoints()
    MerchantFrameTab2:SetPoint("LEFT", MerchantFrameTab1, "RIGHT", border*2 + 1, 0)
    
    -- 商人物品按钮
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local merchantButton = _G["MerchantItem"..i]
        if merchantButton then
            -- 清理原始纹理（但保留我们的背景）
            local regions = {merchantButton:GetRegions()}
            for _, region in pairs(regions) do
                if region:GetObjectType() == "Texture" and region ~= merchantButton.bg then
                    region:SetTexture(nil)
                end
            end
            
            -- 背景
            if not merchantButton.bg then
                merchantButton.bg = merchantButton:CreateTexture(nil, "BACKGROUND")
                merchantButton.bg:SetTexture(1, 1, 1, .05)
                merchantButton.bg:SetAllPoints()
            end
            
            -- 物品按钮
            local itemButton = _G["MerchantItem"..i.."ItemButton"]
            if itemButton then
                StripTextures(itemButton)
                SkinButton(itemButton, nil, nil, nil, _G[itemButton:GetName()..'IconTexture'])
                
                -- 金钱框架
                local moneyFrame = _G["MerchantItem"..i.."MoneyFrame"]
                if moneyFrame then
                    moneyFrame:ClearAllPoints()
                    moneyFrame:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 5, 1)
                end
            end
        end
    end
    
    -- Hook 更新函数以确保背景统一
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            local merchantButton = _G["MerchantItem"..i]
            if merchantButton then
                -- 清理原始纹理（但保留我们的背景）
                local regions = {merchantButton:GetRegions()}
                for _, region in pairs(regions) do
                    if region:GetObjectType() == "Texture" and region ~= merchantButton.bg then
                        region:SetTexture(nil)
                    end
                end
                
                -- 确保背景存在并显示
                if not merchantButton.bg then
                    merchantButton.bg = merchantButton:CreateTexture(nil, "BACKGROUND")
                    merchantButton.bg:SetAllPoints()
                end
                merchantButton.bg:SetTexture(1, 1, 1, .05)
                merchantButton.bg:Show()
                
                -- 确保物品按钮有皮肤
                local itemButton = _G["MerchantItem"..i.."ItemButton"]
                if itemButton then
                    if not itemButton.pfSkinned then
                        StripTextures(itemButton)
                        SkinButton(itemButton, nil, nil, nil, _G[itemButton:GetName()..'IconTexture'])
                        itemButton.pfSkinned = true
                    end
                    
                    -- 重新定位金钱框架
                    local moneyFrame = _G["MerchantItem"..i.."MoneyFrame"]
                    if moneyFrame then
                        moneyFrame:ClearAllPoints()
                        moneyFrame:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 5, 1)
                    end
                end
            end
        end
    end)
    
    hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            local merchantButton = _G["MerchantItem"..i]
            if merchantButton then
                -- 清理原始纹理（但保留我们的背景）
                local regions = {merchantButton:GetRegions()}
                for _, region in pairs(regions) do
                    if region:GetObjectType() == "Texture" and region ~= merchantButton.bg then
                        region:SetTexture(nil)
                    end
                end
                
                -- 确保背景存在并显示
                if not merchantButton.bg then
                    merchantButton.bg = merchantButton:CreateTexture(nil, "BACKGROUND")
                    merchantButton.bg:SetAllPoints()
                end
                merchantButton.bg:SetTexture(1, 1, 1, .05)
                merchantButton.bg:Show()
                
                -- 确保物品按钮有皮肤
                local itemButton = _G["MerchantItem"..i.."ItemButton"]
                if itemButton then
                    if not itemButton.pfSkinned then
                        StripTextures(itemButton)
                        SkinButton(itemButton, nil, nil, nil, _G[itemButton:GetName()..'IconTexture'])
                        itemButton.pfSkinned = true
                    end
                    
                    -- 重新定位金钱框架
                    local moneyFrame = _G["MerchantItem"..i.."MoneyFrame"]
                    if moneyFrame then
                        moneyFrame:ClearAllPoints()
                        moneyFrame:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 5, 1)
                    end
                end
            end
        end
    end)
    
    -- Hook 物品按钮更新函数
    hooksecurefunc("MerchantItemButton_UpdateItem", function(index)
        local merchantButton = _G["MerchantItem"..index]
        if merchantButton then
            -- 清理原始纹理（但保留我们的背景）
            local regions = {merchantButton:GetRegions()}
            for _, region in pairs(regions) do
                if region:GetObjectType() == "Texture" and region ~= merchantButton.bg then
                    region:SetTexture(nil)
                end
            end
            
            -- 确保背景存在并显示
            if not merchantButton.bg then
                merchantButton.bg = merchantButton:CreateTexture(nil, "BACKGROUND")
                merchantButton.bg:SetAllPoints()
            end
            merchantButton.bg:SetTexture(1, 1, 1, .05)
            merchantButton.bg:Show()
            
            -- 重新应用物品按钮皮肤
            local itemButton = _G["MerchantItem"..index.."ItemButton"]
            if itemButton then
                if not itemButton.pfSkinned then
                    StripTextures(itemButton)
                    SkinButton(itemButton, nil, nil, nil, _G[itemButton:GetName()..'IconTexture'])
                    itemButton.pfSkinned = true
                end
                
                -- 重新定位金钱框架
                local moneyFrame = _G["MerchantItem"..index.."MoneyFrame"]
                if moneyFrame then
                    moneyFrame:ClearAllPoints()
                    moneyFrame:SetPoint("BOTTOMLEFT", itemButton, "BOTTOMRIGHT", 5, 1)
                end
            end
        end
    end)
    
    -- 翻页按钮
    StripTextures(MerchantPrevPageButton)
    SkinArrowButton(MerchantPrevPageButton, "left", 18)
    StripTextures(MerchantNextPageButton)
    SkinArrowButton(MerchantNextPageButton, "right", 18)
    
    -- 回购按钮
    StripTextures(MerchantBuyBackItem)
    local bg = MerchantBuyBackItem:CreateTexture(nil, "LOW")
    bg:SetTexture(1, 1, 1, .05)
    bg:SetAllPoints()
    
    StripTextures(MerchantBuyBackItemItemButton)
    SkinButton(MerchantBuyBackItemItemButton, nil, nil, nil, _G[MerchantBuyBackItemItemButton:GetName()..'IconTexture'])
    
    -- 修理按钮
    SkinButton(MerchantRepairAllButton, nil, nil, nil, MerchantRepairAllIcon)
    MerchantRepairAllIcon:SetTexCoord(.31, .53, .06, .52)
    MerchantRepairAllButton:ClearAllPoints()
    MerchantRepairAllButton:SetPoint("RIGHT", MerchantBuyBackItemItemButton, "LEFT", -6, 0)
    
    StripTextures(MerchantRepairItemButton)
    SkinButton(MerchantRepairItemButton, nil, nil, nil, MerchantRepairItemButton:GetNormalTexture())
    MerchantRepairItemButton:SetNormalTexture("Interface\\MerchantFrame\\UI-Merchant-RepairIcons")
    MerchantRepairItemButton:ClearAllPoints()
    MerchantRepairItemButton:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", -4*bpad, 0)
    MerchantRepairItemButton:GetNormalTexture():SetTexCoord(.03, .25, .07, .50)
end)
