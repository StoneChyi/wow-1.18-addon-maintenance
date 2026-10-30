-- pfUI Extended Merchant for WoW 1.12
-- 扩展商人界面，在一页显示所有商品
-- 使用 pfUI 皮肤系统

local ITEMS_PER_SUBPAGE = MERCHANT_ITEMS_PER_PAGE  -- 保存原版每页物品数（10个）
local SUBPAGES_PER_PAGE = 2   -- 2个子页面并排
MERCHANT_ITEMS_PER_PAGE = 20  -- 覆盖全局变量，每页显示20个物品

-- 创建额外的商人按钮
local function CreateExtraMerchantButtons()
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        if not _G["MerchantItem"..i] then
            local btn = CreateFrame("Frame", "MerchantItem"..i, MerchantFrame, "MerchantItemTemplate")
            -- 触发皮肤初始化
            if pfUI and pfUI.skin and pfUI.skin["Extended Merchant"] then
                -- 延迟应用皮肤，确保按钮完全创建
                local itemButton = _G["MerchantItem"..i.."ItemButton"]
                if itemButton then
                    itemButton.needsSkin = true
                end
            end
        end
    end
end

-- 重新排列商人按钮位置（2x2 网格布局，每个子页面 2列x5行）
local function RepositionMerchantButtons()
    local vertSpacing = -16
    local horizSpacing = 12
    local numMerchantItems = GetMerchantNumItems() or 0
    local pageOffset = ((MerchantFrame.page or 1) - 1) * MERCHANT_ITEMS_PER_PAGE
    
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local btn = _G["MerchantItem"..i]
        if btn then
            local name
            local index = pageOffset + i
            if index <= numMerchantItems then
                name = GetMerchantItemInfo(index)
            end
            -- The native merchant update hides parents 11/12 after updating their children.
            if name and name ~= "" then
                btn:Show()
            else
                btn:Hide()
            end
            btn:SetHeight(37)
            
            -- 每个子页面的第一个物品（1, 11）
            if mod((i - 1), ITEMS_PER_SUBPAGE) == 0 then
                if i == 1 then
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 22, -70)
                else
                    -- 第二个子页面的第一个物品，放在第一个子页面右边
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", _G["MerchantItem"..(i - (ITEMS_PER_SUBPAGE - 1))], "TOPRIGHT", horizSpacing, 0)
                end
            else
                -- 子页面内部布局：2列x5行
                if mod((i - 1), 2) == 1 then
                    -- 奇数位置（子页面内的第2列）
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", _G["MerchantItem"..(i - 1)], "TOPRIGHT", horizSpacing, 0)
                else
                    -- 偶数位置（子页面内的第1列，下一行）
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", _G["MerchantItem"..(i - 2)], "BOTTOMLEFT", 0, vertSpacing)
                end
            end
        end
    end
end

-- 重新排列回购按钮位置（3列布局）
local function RepositionBuybackButtons()
    local vertSpacing = -30
    local horizSpacing = 50
    local numBuybackItems = GetNumBuybackItems() or 0
    
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local btn = _G["MerchantItem"..i]
        if btn then
            if i > 12 then
                btn:Hide()
            else
                local name
                if i <= numBuybackItems then
                    name = GetBuybackItemInfo(i)
                end
                if name and name ~= "" then
                    btn:Show()
                else
                    btn:Hide()
                end
                btn:SetHeight(37)
                
                if i == 1 then
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 64, -120)
                else
                    if mod((i - 1), 3) == 0 then
                        -- 每行第一个，放在上一行第一个的下方
                        btn:ClearAllPoints()
                        btn:SetPoint("TOPLEFT", _G["MerchantItem"..(i - 3)], "BOTTOMLEFT", 0, vertSpacing)
                    else
                        -- 同一行，放在左边物品的右边
                        btn:ClearAllPoints()
                        btn:SetPoint("TOPLEFT", _G["MerchantItem"..(i - 1)], "TOPRIGHT", horizSpacing, 0)
                    end
                end
            end
        end
    end
end

-- 重建商人框架
local function RebuildMerchantFrame()
    -- 设置框架宽度（适配 2x2 网格布局）
    MerchantFrame:SetWidth(715)
    
    -- 创建额外按钮
    CreateExtraMerchantButtons()
    
    -- 调整回购按钮位置
    MerchantBuyBackItem:ClearAllPoints()
    MerchantBuyBackItem:SetPoint("TOPLEFT", MerchantItem10, "BOTTOMLEFT", 0, -20)
    
    -- 移动翻页按钮
    MerchantPrevPageButton:ClearAllPoints()
    MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 20, 115)
    MerchantPageText:ClearAllPoints()
    MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", 150, 110)
    MerchantNextPageButton:ClearAllPoints()
    MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 280, 115)
end

-- Hook更新函数
local HOOKS = {}

local function HookUpdateFunctions()
    HOOKS["MerchantFrame_UpdateMerchantInfo"] = MerchantFrame_UpdateMerchantInfo
    MerchantFrame_UpdateMerchantInfo = function()
        HOOKS["MerchantFrame_UpdateMerchantInfo"]()
        RepositionMerchantButtons()
    end
    
    HOOKS["MerchantFrame_UpdateBuybackInfo"] = MerchantFrame_UpdateBuybackInfo
    MerchantFrame_UpdateBuybackInfo = function()
        HOOKS["MerchantFrame_UpdateBuybackInfo"]()
        RepositionBuybackButtons()
    end
end

-- 初始化
local function Initialize()
    RebuildMerchantFrame()
    RepositionMerchantButtons()
    HookUpdateFunctions()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffUI|r |cff00ff00ExtendedMerchant|r 已加载")
end

-- 事件处理
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "pfUI_ExtendedMerchant" then
        -- 等待 pfUI 加载完成
        if pfUI then
            Initialize()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000错误:|r pfUI_ExtendedMerchant 需要 pfUI 插件")
        end
    end
end)
