-- EzPoison 毒药助手
-- 当打开毒药商界面时显示购买框体

local EZPBuyer = CreateFrame("Frame")
EZPBuyer:RegisterEvent("ADDON_LOADED")
EZPBuyer:RegisterEvent("MERCHANT_SHOW")
EZPBuyer:RegisterEvent("MERCHANT_CLOSED")
EZPBuyer:RegisterEvent("TRADE_SKILL_SHOW")
EZPBuyer:RegisterEvent("TRADE_SKILL_CLOSE")
-- EZPBuyer:RegisterEvent("TRADE_SKILL_UPDATE")

-- 存储从专业技能界面读取的毒药信息
-- {name = "毒药名称", level = 等级, materials = {{id = 材料ID, count = 数量}, ...}}
EZPBuyer.PoisonData = {}
-- EZPBuyer.WaitingForTradeSkill = false -- 标记是否正在等待专业技能界面打开

local function getkey()
    local serverName = GetRealmName()
    local characterName = UnitName("player")
    local level = UnitLevel("player")
    return serverName .. '-' .. characterName .. '-' .. level
end

local function savePoisonData(poisonData)
    local storageKey = getkey()
    EZPBuyerData[storageKey] = poisonData
end

local function getPoisionData()
    local storageKey = getkey()
    -- print('getPoisionData - storageKey ', storageKey)
    return EZPBuyerData[storageKey]
end

local queue = {}
local function delayCall(fn, delay)
    table.insert(queue, { fn = fn, executeAfter = GetTime() + delay })
end

local function processQueue()
    if table.getn(queue) > 0 then
        local currentTime = GetTime()
        for i = table.getn(queue), 1, -1 do
            if queue[i] and queue[i].executeAfter <= currentTime then
                queue[i].fn()
                queue[i].executeAfter = 9999999999
                table.remove(queue, i)
            end
        end
    end
end
CreateFrame("Frame"):SetScript("OnUpdate", processQueue)

-- 尝试打开毒药专业技能界面
local function OpenPoisonTradeSkill()
    CastSpellByName("毒药")
    return true
end

-- 从专业技能界面读取毒药信息
local function ReadPoisonsFromTradeSkill()
    -- print('ReadPoisonsFromTradeSkill')
    -- 检查是否是毒药专业技能
    local tradeSkillName = GetTradeSkillLine()
    if not tradeSkillName or not string.find(tradeSkillName, "毒药") then
        -- -- 如果不是毒药专业技能，尝试打开它
        -- if OpenPoisonTradeSkill() then
        --     -- 等待界面打开后重新检查
        --     return false
        -- end
        return false
    end

    EZPBuyer.PoisonData = {}
    pcall(ExpandTradeSkillSubClass, 1)

    local numTradeSkills = GetNumTradeSkills()
    local inConsumablesCategory = false
    local currentCategory = ""

    for i = 1, numTradeSkills do
        local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
        -- DEFAULT_CHAT_FRAME:AddMessage(skillName..', type='..(skillType or 'notype'))
        if not skillName then
            break
        end

        -- 检查是否是分类标题
        if skillType == "header" then
            -- 检查是否是"消耗品"分类
            if string.find(skillName, "消耗品") or string.find(skillName, "Consumables") then
                inConsumablesCategory = true
                currentCategory = skillName
            else
                inConsumablesCategory = false
            end
            -- elseif skillType == "optimal" or skillType == "medium" or skillType == "trivial" then
        elseif skillType == "optimal" or skillType == "medium" or skillType == "easy" or skillType == "trivial" then
            -- 这是一个可制作的物品
            if inConsumablesCategory then
                -- 读取材料信息
                local materials = {}
                local numReagents = GetTradeSkillNumReagents(i)

                for j = 1, numReagents do
                    local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(i, j)
                    if reagentName then
                        local itemId = nil

                        -- 尝试通过GetTradeSkillReagentItemLink获取物品ID
                        -- 在1.12中，这个API可能不存在，需要检查
                        local reagentLink = nil
                        if GetTradeSkillReagentItemLink then
                            reagentLink = GetTradeSkillReagentItemLink(i, j)
                        end

                        if reagentLink then
                            local itemIdStr = string.match(reagentLink, "item:(%d+):")
                            itemId = itemIdStr and tonumber(itemIdStr)
                        end

                        -- 如果获取到了itemId，存储材料信息
                        if itemId then
                            table.insert(materials, {
                                id = itemId,
                                count = reagentCount or 1,
                                name = reagentName,
                            })
                        else
                            -- 如果无法获取ID，至少存储名称和数量，后续可以通过名称匹配
                            table.insert(materials, {
                                id = nil,
                                count = reagentCount or 1,
                                name = reagentName,
                            })
                        end
                    end
                end

                -- 提取毒药等级
                local level = 0
                local rankMatch = string.match(skillName, "等级 (%d+)")
                if not rankMatch then
                    rankMatch = string.match(skillName, "Rank (%d+)")
                end
                if rankMatch then
                    level = tonumber(rankMatch) or 0
                end

                -- 存储毒药信息，保持专业技能界面中的原始顺序
                table.insert(EZPBuyer.PoisonData, {
                    name = skillName,
                    level = level,
                    materials = materials,
                    tradeSkillIndex = i,
                    originalIndex = table.getn(EZPBuyer.PoisonData) + 1, -- 保存插入顺序
                })
            end
        end
    end

    savePoisonData(EZPBuyer.PoisonData)
end

-- 获取已学会的毒药列表
local function GetLearnedPoisons()
    -- 如果数据为空，尝试读取
    if table.getn(EZPBuyer.PoisonData) == 0 then
        ReadPoisonsFromTradeSkill()
    end

    return EZPBuyer.PoisonData
end

local bagItemsCountMap = {}
local function ScanBagItemsCount()
    bagItemsCountMap = {}
    local poisonsMap = {}
    for i, n in ipairs(EZPBuyer.PoisonData or {}) do
        poisonsMap[n.name] = 1
    end

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local _, itemCount = GetContainerItemInfo(bag, slot)
                if itemCount then
                    local itemLink = GetContainerItemLink(bag, slot)
                    if itemLink then
                        local _, _, itemId, name = string.find(itemLink, "item:(%d+):.+%[(.+)%]")
                        if poisonsMap[name] then
                            -- DEFAULT_CHAT_FRAME:AddMessage('poisonsMap[name],name='..name)
                            bagItemsCountMap[name] = (bagItemsCountMap[name] or 0) + (itemCount or 1)
                            -- DEFAULT_CHAT_FRAME:AddMessage('bagItemsCountMap['..name..']='..bagItemsCountMap[name])

                            if bagItemsCountMap[name] < 0 then bagItemsCountMap[name] = 0 end
                        elseif itemId then
                            bagItemsCountMap[itemId] = (bagItemsCountMap[itemId] or 0) + (itemCount or 1)
                            if bagItemsCountMap[itemId] < 0 then bagItemsCountMap[itemId] = 0 end
                        end
                    end
                end
            end
        end
    end
end

-- 获取背包剩余空间
local function GetFreeBagSlots()
    local freeSlots = 0
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                if not GetContainerItemInfo(bag, slot) then
                    freeSlots = freeSlots + 1
                end
            end
        end
    end
    return freeSlots
end

-- 获取背包中物品数量
local function GetItemCountInBags(itemId)
    return bagItemsCountMap[tostring(itemId)] or 0
end

local machantItemsMap = {}
-- 缓存商人处物品
local function ScanMerchantItems()
    machantItemsMap = {}
    for i = 1, GetMerchantNumItems() do
        local name, _, cost, stack = GetMerchantItemInfo(i)
        local itemLink = GetMerchantItemLink(i)
        if itemLink then
            local merchantItemId = string.match(itemLink, "item:(%d+):")
            machantItemsMap[merchantItemId] = {
                index = i,
                link = itemLink,
                name = name,
                mstack = GetMerchantItemMaxStack(i),
                istack = stack,
                cost = cost
            }
            if string.find(itemLink, "瓶") then
                machantItemsMap[merchantItemId].mstack = 20
            end
        end
    end
end

-- 在商人处查找物品
local function FindMerchantItem(itemId)
    return machantItemsMap[tostring(itemId)]
end

-- 移除商人界面上的按钮
local function RemoveMerchantButton()
    if EZPBuyer.MerchantButton then
        EZPBuyer.MerchantButton:Hide()
        EZPBuyer.MerchantButton = nil
    end
end

-- 创建购买界面
local function CreateBuyerFrame()
    if EZPBuyer.Frame then
        return EZPBuyer.Frame
    end

    local frame = CreateFrame("Frame", "EZPBuyerFrame", UIParent)
    frame:SetWidth(265) -- 调整为原来的70%左右
    frame:SetHeight(400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- 背景
    local backdrop = {
        bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 5, top = 3, bottom = 5 }
    }
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(0, 0, 0, 0.9)

    -- 标题
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("毒药助手")
    title:SetTextColor(1, 1, 0.5)

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- 滚动区域
    local scrollFrame = CreateFrame("ScrollFrame", "EZPBuyerScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 60)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local scrollBar = getglobal(this:GetName() .. "ScrollBar")
        if scrollBar then
            if arg1 > 0 then
                scrollBar:SetValue(scrollBar:GetValue() - 20)
            else
                scrollBar:SetValue(scrollBar:GetValue() + 20)
            end
        end
    end)

    local scrollChild = CreateFrame("Frame", "EZPBuyerScrollChild", scrollFrame)
    scrollChild:SetWidth(230)                                  -- 相应调整宽度
    scrollChild:SetHeight(1)
    scrollChild:EnableMouse(false)                             -- 禁用鼠标事件，让子元素可以接收
    scrollChild:SetFrameLevel(scrollFrame:GetFrameLevel() - 1) -- 确保子元素在滚动区域之上
    scrollFrame:SetScrollChild(scrollChild)

    frame.ScrollFrame = scrollFrame
    frame.ScrollChild = scrollChild
    frame.PoisonItems = {}

    -- 一键购买按钮
    local buyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    buyButton:SetWidth(120)
    buyButton:SetHeight(30)
    buyButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    buyButton:SetText("let's go!")
    buyButton:SetScript("OnClick", function()
        EZPBuyer:BuyMaterials()
    end)
    frame.BuyButton = buyButton

    EZPBuyer.Frame = frame
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, -20)
    if MerchantFrame and MerchantFrame:GetHeight() then
        frame:SetHeight(MerchantFrame:GetHeight() - 100)
    end

    frame:SetScript("OnShow", function()
        if MerchantFrame and MerchantFrame:GetHeight() then
            frame:SetHeight(MerchantFrame:GetHeight() - 100)
        end

        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, -20)
    end)

    if IsAddOnLoaded("pfUI") then
        pfUI.api.SkinScrollbar(EZPBuyerScrollFrameScrollBar)
        -- pfUI:RegisterSkin("EzPoisonBuyer", "vanilla:tbc", function()
        --     pfUI.api.StripTextures(frame, true)
        --     pfUI.api.CreateBackdrop(frame, nil, nil, .75)
        --     pfUI.api.CreateBackdropShadow(frame)

        --     -- frame.backdrop:SetPoint("TOPLEFT", 8, -10)
        --     -- frame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)
        --     -- frame:SetHitRectInsets(8,32,10,74)
        --     frame.backdrop:SetPoint("TOPLEFT", 0, 0)
        --     frame.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)

        --     pfUI.api.SkinCloseButton(closeBtn)
        --     -- frame:SetHitRectInsets(8,32,10,74)
        -- end)
        pfUI.api.StripTextures(frame, true)
        pfUI.api.CreateBackdrop(frame, nil, nil, .75)
        pfUI.api.CreateBackdropShadow(frame)

        -- frame.backdrop:SetPoint("TOPLEFT", 8, -10)
        -- frame.backdrop:SetPoint("BOTTOMRIGHT", -32, 74)
        -- frame:SetHitRectInsets(8,32,10,74)
        frame.backdrop:SetPoint("TOPLEFT", 0, 0)
        frame.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)

        pfUI.api.SkinCloseButton(closeBtn)

        pfUI.api.SkinButton(buyButton)
    end

    return frame
end

-- 更新购买界面
local function UpdateBuyerFrame()
    local frame = EZPBuyer.Frame
    if not frame then
        frame = CreateBuyerFrame()
    end

    -- 清除旧的项目
    for i, item in ipairs(frame.PoisonItems) do
        if item.Frame then
            item.Frame:Hide()
            item.Frame = nil
        end
    end
    frame.PoisonItems = {}

    -- 获取已学会的毒药
    local learnedPoisons = EZPBuyer.PoisonData -- GetLearnedPoisons()
    if table.getn(learnedPoisons) == 0 then
        local noPoisons = frame.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noPoisons:SetPoint("TOP", frame.ScrollChild, "TOP", 0, -10)
        noPoisons:SetText("未学会任何毒药技能")
        noPoisons:SetTextColor(1, 0.5, 0.5)
        frame.ScrollChild:SetHeight(50)
        return
    end

    -- 创建毒药列表项
    local yOffset = -10
    local itemHeight = 30
    local itemSpacing = 35
    for i, poison in ipairs(learnedPoisons) do
        local itemFrame = CreateFrame("Frame", nil, frame.ScrollChild)
        itemFrame:SetWidth(220) -- 相应调整宽度
        itemFrame:SetHeight(itemHeight)
        itemFrame:SetPoint("TOPLEFT", frame.ScrollChild, "TOPLEFT", 5, yOffset)
        -- 确保itemFrame可以接收鼠标事件，但不会阻挡子元素
        itemFrame:EnableMouse(false)                                   -- 禁用鼠标事件，让子元素可以接收
        itemFrame:SetFrameLevel(frame.ScrollChild:GetFrameLevel() + 1) -- 确保在滚动子元素之上

        -- 毒药名称 - 设置最大宽度，避免与输入框重叠
        local nameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", itemFrame, "LEFT", 5, 0)
        nameText:SetPoint("RIGHT", itemFrame, "RIGHT", -90, 0) -- 为右侧按钮和输入框留出空间
        nameText:SetText(poison.name)
        nameText:SetTextColor(1, 1, 0.5)
        nameText:SetJustifyH("LEFT")
        nameText:SetNonSpaceWrap(false)

        -- 数量输入框 - 中间
        local editBox = CreateFrame("EditBox", 'EZPBuyerEditBox' .. i, itemFrame, "InputBoxTemplate")
        editBox:SetWidth(35)
        editBox:SetHeight(20)
        editBox:SetJustifyH("CENTER")
        editBox:SetPoint("RIGHT", itemFrame, "RIGHT", -56, 0)
        editBox:SetAutoFocus(false)
        editBox:SetNumeric(true)
        editBox:SetText("0")
        editBox:SetMaxLetters(4)
        editBox:EnableMouse(true)
        editBox:SetFrameLevel(itemFrame:GetFrameLevel() + 20)

        -- 确保输入的是整数
        editBox:SetScript("OnTextChanged", function()
            local text = this:GetText()
            local num = tonumber(text)
            if num then
                local intNum = math.floor(num)
                if intNum ~= num then
                    this:SetText(tostring(intNum))
                end
                if intNum < 0 then
                    this:SetText("0")
                end
            elseif text ~= "" then
                this:SetText("0")
            end
        end)
        editBox:SetScript("OnEditFocusGained", function()
            this:HighlightText()
        end)
        editBox:SetScript("OnEditFocusLost", function()
            this:HighlightText(0, 0)
        end)
        editBox:SetScript("OnMouseDown", function()
            this:SetFocus()
        end)

        -- 减号按钮 - 输入框左边
        local minusBtn = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        minusBtn:SetWidth(20)
        minusBtn:SetHeight(20)
        minusBtn:SetPoint("RIGHT", editBox, "LEFT", -8, 0)
        minusBtn:SetText("-")
        minusBtn:EnableMouse(true)
        minusBtn:SetFrameLevel(itemFrame:GetFrameLevel() + 15)
        minusBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- 加号按钮 - 在输入框右边
        local plusBtn = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        plusBtn:SetWidth(20)
        plusBtn:SetHeight(20)
        plusBtn:SetPoint("LEFT", editBox, "RIGHT", 4, 0)
        plusBtn:SetText("+")
        plusBtn:EnableMouse(true)
        plusBtn:SetFrameLevel(itemFrame:GetFrameLevel() + 15)
        plusBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- 放一个FontString，文本为“组”，在加号的右边
        local groupText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        groupText:SetPoint("LEFT", plusBtn, "RIGHT", 4, 0)
        groupText:SetText("组")
        groupText:SetTextColor(1, 1, 0.5)
        groupText:SetJustifyH("LEFT")
        groupText:SetNonSpaceWrap(false)

        -- 设置按钮点击事件（使用全局名称获取editBox，避免闭包问题）
        minusBtn:SetScript("OnClick", function()
            local currentText = editBox:GetText()
            local currentValue = tonumber(currentText) or 0
            if currentValue > 0 then
                currentValue = currentValue - 1
                editBox:SetText(tostring(currentValue))
            end
        end)

        plusBtn:SetScript("OnClick", function()
            local currentText = editBox:GetText()
            local currentValue = tonumber(currentText) or 0
            currentValue = currentValue + 1
            editBox:SetText(tostring(currentValue))
        end)

        itemFrame.PoisonData = poison
        itemFrame.EditBox = editBox

        local uniqString = math.floor(GetTime() * 1000)
        if IsAddOnLoaded("pfUI") then
            -- pfUI:RegisterSkin("EZPBuyerFrameItem" .. uniqString .. i, "vanilla:tbc", function()
            --     if IsAddOnLoaded("pfUI") then
            --         pfUI.api.SkinButton(plusBtn)
            --         pfUI.api.SkinButton(minusBtn)
            --         pfUI.api.StripTextures(editBox, nil, "BACKGROUND")
            --         pfUI.api.CreateBackdrop(editBox, nil, true)
            --     end
            -- end)

            pfUI.api.SkinButton(plusBtn)
            pfUI.api.SkinButton(minusBtn)
            pfUI.api.StripTextures(editBox, nil, "BACKGROUND")
            pfUI.api.CreateBackdrop(editBox, nil, true)
        end

        -- 从EZPcfg.poisonGroupCount读取缓存的毒药组数，匹配毒药名称后设置到editbox
        local poisonGroupCount = EZPcfg.poisonGroupCount or {}
        local countText = poisonGroupCount[poison.name]
        if not poisonGroupCount[poison.name] or poisonGroupCount[poison.name] == "" then
            countText = "0"
        end
        editBox:SetText(countText)

        table.insert(frame.PoisonItems, {
            Frame = itemFrame,
            PoisonData = poison,
            EditBox = editBox,
        })

        yOffset = yOffset - itemSpacing
    end

    -- 计算scrollChild高度：
    -- 顶部边距(10) + 最后一个itemFrame的顶部位置(math.abs(yOffset)) + itemFrame高度(30) + 底部边距(20)
    -- 或者：10 + (项目数 * itemSpacing - itemSpacing + itemHeight) + 20
    local itemCount = table.getn(learnedPoisons)
    local totalHeight = 10 + (itemCount * itemSpacing - itemSpacing + itemHeight) + 20
    -- 确保最小高度
    if totalHeight < 50 then
        totalHeight = 50
    end
    frame.ScrollChild:SetHeight(totalHeight)

    if not frame:IsVisible() then
        frame:Show()
    end
end

-- 购买材料
function EZPBuyer:BuyMaterials()
    -- if not MerchantFrame or not MerchantFrame:IsVisible() then
    --     DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000错误: 请先打开商人界面|r", 1, 0, 0)
    --     return
    -- end

    local frame = EZPBuyer.Frame
    if not frame or not frame.PoisonItems then
        return
    end

    -- 扫描背包现存数量
    ScanBagItemsCount()
    -- 扫描商人物品
    ScanMerchantItems()

    -- 汇总所需材料
    local materialNeeds = {} -- {itemId = neededCount}
    local updatedItemIndexes = {}
    local poisonGroupCount = EZPcfg.poisonGroupCount or {}
    for i = 1, table.getn(frame.PoisonItems) do
        local editBox = frame.PoisonItems[i].EditBox
        if editBox then
            local poisonName = frame.PoisonItems[i].PoisonData.name
            local countText = editBox:GetText()
            poisonGroupCount[poisonName] = countText
            local countNumber = tonumber(countText) or 0
            if countNumber > 0 then
                table.insert(updatedItemIndexes, i)
            end
        end
    end
    EZPcfg.poisonGroupCount = poisonGroupCount

    if table.getn(updatedItemIndexes) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000请选择毒药|r", 1, 0, 0)
        return
    end

    -- for _, i in ipairs(updatedItemIndexes) do
    --   print(i, GetTime())
    -- end

    -- for i, item in ipairs(frame.PoisonItems) do
    local needMaterials = false
    -- local notifyPlan = true
    for _, i in ipairs(updatedItemIndexes) do
        local item = frame.PoisonItems[i]
        -- 通过全局名称获取editBox，确保获取正确的值
        local countText = item.EditBox:GetText()
        -- print(i, table.getn(EZPBuyer.PoisonData))
        local poisonName = EZPBuyer.PoisonData[i].name
        local poisonCurrentCount = GetItemCountInBags(poisonName)
        -- DEFAULT_CHAT_FRAME:AddMessage('poisonName='..poisonName..', poisonCurrentCount='..poisonCurrentCount)

        local count = (tonumber(countText) or 0) * 20 -- 毒药固定20个一组
        -- DEFAULT_CHAT_FRAME:AddMessage('count='..count)
        if poisonCurrentCount and poisonCurrentCount > 0 then
            count = count - poisonCurrentCount
        end

        if count > 0 and item.PoisonData and item.PoisonData.materials then
            -- if notifyPlan then
            --   DEFAULT_CHAT_FRAME:AddMessage('计划制作 >> '..poisonName..' X '.. count)
            --   notifyPlan = false
            -- end
            needMaterials = true
            for j, material in ipairs(item.PoisonData.materials) do
                -- 只处理有ID的材料
                if material.id then
                    local needed = material.count * count
                    if not materialNeeds[material.id] then
                        materialNeeds[material.id] = 0
                    end
                    materialNeeds[material.id] = materialNeeds[material.id] + needed
                end
            end
        end
    end
    if not needMaterials then
        DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFFFF00毒药数量充足|r", 1, 1, 0)
        return
    end

    local usableSlotStackNums = {}
    local anyNeeds = false

    for itemId, needed in pairs(materialNeeds) do
        local currentCount = GetItemCountInBags(itemId)
        if currentCount < needed then
            anyNeeds = true
        end
    end

    if anyNeeds then
        -- 去除背包已有材料
        for itemId, needed in pairs(materialNeeds) do
            local currentCount = GetItemCountInBags(itemId)
            local mitem = FindMerchantItem(itemId)
            -- if mitem then
            --   DEFAULT_CHAT_FRAME:AddMessage('背包已有 >> '..mitem.name..' X '.. currentCount)
            -- end
            if mitem then
                if currentCount and currentCount > 0 then
                    usableSlotStackNums[itemId] = math.ceil(currentCount / mitem.mstack) * mitem.mstack - currentCount
                    materialNeeds[itemId] = materialNeeds[itemId] - currentCount
                    if materialNeeds[itemId] <= 0 then
                        materialNeeds[itemId] = nil
                    end
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000商人没有足够的材料，购买失败（请找毒药商）|r", 1, 0, 0)
                return
            end
        end
    end

    -- 检查是否有需要购买的材料
    local hasNeeds = false
    for itemId, needed in pairs(materialNeeds) do
        if needed > 0 then
            hasNeeds = true
            break
        end
    end

    if not hasNeeds or not anyNeeds then
        -- 此处应按照缺少的毒药，调用毒药专业技能开始制作
        for _, i in ipairs(updatedItemIndexes) do
            local item = frame.PoisonItems[i]
            -- 通过全局名称获取editBox，确保获取正确的值
            local countText = item.EditBox:GetText()
            local poisonName = EZPBuyer.PoisonData[i].name
            local poisonCurrentCount = GetItemCountInBags(poisonName)
            -- DEFAULT_CHAT_FRAME:AddMessage('poisonName='..poisonName..', poisonCurrentCount='..poisonCurrentCount)

            local count = (tonumber(countText) or 0) * 20 -- 毒药固定20个一组
            -- DEFAULT_CHAT_FRAME:AddMessage('count='..count)
            if poisonCurrentCount and poisonCurrentCount > 0 then
                count = count - poisonCurrentCount
            end

            if count > 0 and item.PoisonData and item.PoisonData.materials then
                EZPBuyer.keepTradeSkillOpen = true
                if not TradeSkillFrame or not TradeSkillFrame:IsVisible() then
                    CastSpellByName("毒药")
                end
                TradeSkillFrame:SetPoint("TOPLEFT", EZPBuyer.Frame, "TOPRIGHT", 20, 0)
                DEFAULT_CHAT_FRAME:AddMessage('开始制作 >> ' .. poisonName .. ' X ' .. count)
                DoTradeSkill(EZPBuyer.PoisonData[i].tradeSkillIndex, count)
                SelectTradeSkill(EZPBuyer.PoisonData[i].tradeSkillIndex)
                return
            end
        end
        return
    end

    -- for k, v in pairs(materialNeeds) do
    --   local mitem = FindMerchantItem(k)
    --   if mitem then
    --     -- print(k, v, mitem.name, mitem.istack)
    --     DEFAULT_CHAT_FRAME:AddMessage('需要购买 >> '..mitem.name..' X '.. v)
    --   end
    -- end

    -- 计算所需背包空间
    -- 需要获取每个物品的堆叠数量
    local totalSlotsNeeded = 0
    for itemId, needed in pairs(materialNeeds) do
        -- 尝试从商人处获取堆叠信息,默认假设每堆20个
        local mitem = FindMerchantItem(itemId)

        needed = needed - (usableSlotStackNums[itemId] or 0)

        if mitem then
            -- print(mitem.name, needed, mitem.mstack)
            totalSlotsNeeded = totalSlotsNeeded + math.ceil(needed / mitem.mstack)
        else
            DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000商人处没有找到材料 (ID: " .. itemId .. ")|r", 1, 0, 0)
        end
    end
    -- DEFAULT_CHAT_FRAME:AddMessage('共需要空格：'..totalSlotsNeeded)
    -- 检查背包空间
    local freeSlots = GetFreeBagSlots()
    if freeSlots < totalSlotsNeeded then
        DEFAULT_CHAT_FRAME:AddMessage(
            "EzPoison: |cFFFF0000背包空间不足! 需要 " .. totalSlotsNeeded .. " 个空格, 当前只有 " .. freeSlots .. " 个|r", 1, 0, 0)
        return
    end

    -- 扫描背包现有材料并计算需要购买的数量
    local purchaseList = {} -- {merchantIndex = quantity}

    -- for itemId, needed in pairs(materialNeeds) do
    --     local currentCount = GetItemCountInBags(itemId)
    --     local toBuy = needed - currentCount

    --     if toBuy > 0 then
    --         local merchantIndex = FindMerchantItem(itemId)
    --         if merchantIndex then
    --             if not purchaseList[merchantIndex] then
    --                 purchaseList[merchantIndex] = 0
    --             end
    --             purchaseList[merchantIndex] = purchaseList[merchantIndex] + toBuy
    --         else
    --             DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000商人处没有找到材料 (ID: " .. itemId .. ")|r", 1, 0, 0)
    --         end
    --     end
    -- end
    for itemId, needed in pairs(materialNeeds) do
        local mitem = FindMerchantItem(itemId)
        purchaseList[mitem.index] = math.ceil(needed / (mitem.istack or 1))
    end

    -- 执行购买
    local purchased = false
    for merchantIndex, quantity in pairs(purchaseList) do
        if quantity > 0 then
            local itemName, _, price, stack = GetMerchantItemInfo(merchantIndex)
            -- if itemName then
            --     -- 尝试使用数量参数(如果支持)
            --     local success = false
            --     if BuyMerchantItem then
            --     -- 在1.12中,BuyMerchantItem通常只接受索引参数
            --     -- 需要多次调用来购买多个物品
            --     for i = 1, quantity do
            --         BuyMerchantItem(merchantIndex)
            --     end
            --     success = true
            --     end

            --     if success then
            --         DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFF00FF00购买 " .. quantity .. " 个 " .. itemName .. "|r", 0, 1, 0)
            --         purchased = true
            --     else
            --         DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000无法购买 " .. itemName .. "|r", 1, 0, 0)
            --     end
            -- end
            BuyMerchantItem(merchantIndex, quantity)
            -- DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000购买["..itemName.."] X "..(quantity * (stack or 1)).."|r", 1, 0, 0)
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000购买完成|r", 1, 1, 0)

    -- if not purchased then
    --     DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFFFF00所有材料已充足, 无需购买|r", 1, 1, 0)
    -- end
end

-- 创建商人界面上的毒药助手按钮
local function CreateMerchantButton()
    -- 如果不是盗贼，直接返回
    local _, class = UnitClass("player")
    if class ~= "ROGUE" then
        return nil
    end
    -- 如果按钮已存在，直接返回
    if EZPBuyer.MerchantButton then
        return EZPBuyer.MerchantButton
    end

    -- 检查MerchantFrame是否存在
    if not MerchantFrame then
        return nil
    end

    -- 创建按钮
    local button = CreateFrame("Button", "EZPBuyerMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
    button:SetWidth(100)
    button:SetHeight(25)
    -- button:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, -44)  -- 右上位置
    -- 判断pfUI插件是否存在并启用，使用系统API的方式
    if IsAddOnLoaded("pfUI") then
        button:SetPoint("RIGHT", MerchantFrameCloseButton, "RIGHT", 0, -32)
        if pfUI and pfUI.api and pfUI.api.SkinButton then
            pfUI.api.SkinButton(button)
        end
    else
        button:SetPoint("RIGHT", MerchantFrameCloseButton, "RIGHT", -8, -36)
    end

    button:SetText("毒药助手")

    -- 设置点击事件（逻辑待定）
    button:SetScript("OnClick", function()
        -- 点击事件逻辑待定
        -- 可以在这里添加显示/隐藏购买助手界面的逻辑
        if not EZPBuyer.PoisonData or table.getn(EZPBuyer.PoisonData) == 0 then
            local savedPoisonData = getPoisionData()
            if savedPoisonData then
                EZPBuyer.PoisonData = savedPoisonData
            end
        end

        if not EZPBuyer.PoisonData or table.getn(EZPBuyer.PoisonData) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("EzPoison: |cFFFF0000请打开一次毒药技能以读取信息|r", 1, 0, 0)
            return
        end

        if EZPBuyer.Frame and EZPBuyer.Frame:IsVisible() then
            EZPBuyer.Frame:Hide()
        else
            -- EZPBuyer.onMerchantShow(true)
            CreateMerchantButton()
            UpdateBuyerFrame()
        end
    end)

    -- 设置鼠标悬停提示
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        if EZPBuyer.Frame and EZPBuyer.Frame:IsVisible() then
            GameTooltip:SetText("关闭毒药助手")
        else
            GameTooltip:SetText("打开毒药助手")
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    EZPBuyer.MerchantButton = button
    return button
end

local ptooltip = CreateFrame("GameTooltip", "EzPoisonBuyerTooltip", nil, "GameTooltipTemplate")
local function isPoisonVendor(unit)
    if not unit then return end
    if not UnitExists(unit) then return end

    ptooltip:ClearLines()
    ptooltip:SetOwner(UIParent, "ANCHOR_NONE")
    ptooltip:SetUnit(unit)
    return getglobal(ptooltip:GetName() .. 'TextLeft2'):GetText() == '毒药商'
end

local onMerchantShow = function(fromButton)
    -- 非盗贼职业直接退出
    local _, class = UnitClass("player")
    if class ~= "ROGUE" then
        return
    end

    if not isPoisonVendor("target") then
        -- print('不是毒药商')
        return
    end

    -- 创建商人界面上的毒药助手按钮
    CreateMerchantButton()

    -- if EZPBuyer.PoisonData
    -- if not EZPBuyer.lastPoisonUpdateTime or GetTime() - EZPBuyer.lastPoisonUpdateTime > 10 then
    --     EZPBuyer.lastPoisonUpdateTime = GetTime()

    --     EZPBuyer.PoisonData = {}
    --     -- 尝试打开毒药专业技能界面
    --     EZPBuyer.WaitingForTradeSkill = true
    --     OpenPoisonTradeSkill()
    -- elseif EZPBuyer.PoisonData and table.getn(EZPBuyer.PoisonData) > 0 then
    --     print('elseif')
    --     CreateMerchantButton()
    --     UpdateBuyerFrame()
    -- else
    --     print('else')
    --     print(table.getn(EZPBuyer.PoisonData))
    -- end
end
EZPBuyer.onMerchantShow = onMerchantShow

-- 事件处理
function EZPBuyer:OnEvent()
    if event == "ADDON_LOADED" and arg1 == "EzPoison" then
        -- 初始化完成
        EZPBuyerData = EZPBuyerData or {}
    elseif event == "MERCHANT_SHOW" then
        onMerchantShow()
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
        -- 专业技能界面打开或更新时，重新读取毒药信息
        ReadPoisonsFromTradeSkill()
    elseif event == "TRADE_SKILL_CLOSE" then
        -- 专业技能界面关闭时，可以清理数据（可选）
        delayCall(function()
            if EZPBuyer.Frame and EZPBuyer.Frame:IsVisible() and (not MerchantFrame or not MerchantFrame:IsVisible()) then
                EZPBuyer.Frame:Hide()
            end
        end, 0.1)
    elseif event == "MERCHANT_CLOSED" then
        delayCall(function()
            if not TradeSkillFrame or not TradeSkillFrame:IsVisible() then
                if EZPBuyer.Frame and EZPBuyer.Frame:IsVisible() then
                    -- print('隐藏助手窗口')
                    EZPBuyer.Frame:Hide()
                end
                return
            end
            if TradeSkillFrame and TradeSkillFrame:IsVisible() then
                if not string.find(TradeSkillFrameTitleText:GetText() or '', '毒药') then
                    if EZPBuyer.Frame and EZPBuyer.Frame:IsVisible() then
                        EZPBuyer.Frame:Hide()
                    end
                end
            end
        end, 0.1)

        -- 移除商人界面上的按钮
        RemoveMerchantButton()
    end
end

EZPBuyer:SetScript("OnEvent", EZPBuyer.OnEvent)

-- EZPBuyer.closeTradeSkillFrame = function()
--     if EZPBuyer and EZPBuyer.WaitingForTradeSkillClose == true then
--         if TradeSkillFrame and TradeSkillFrame:IsVisible() then
--             EZPBuyer.WaitingForTradeSkillClose = false
--             CloseTradeSkill()
--         end

--         -- 兼容商业插件
--         if ATSWFrame and ATSWFrame:IsVisible() then
--             EZPBuyer.WaitingForTradeSkillClose = false
--             ATSWFrameCloseButton:Click()
--         end
--     end

--     if EZPBuyerFrame and EZPBuyerFrame:IsVisible() and TradeSkillFrame then
--         TradeSkillFrame:SetPoint("TOPLEFT", EZPBuyerFrame, "TOPRIGHT", 20, 0)
--     end

-- end
