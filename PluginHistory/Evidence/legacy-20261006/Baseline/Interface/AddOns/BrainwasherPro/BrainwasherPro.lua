BrainwasherPro = {}

local L = {
    ["TITLE"] = "地精洗脑装置",
    ["AVAILABLE_SLOT"] = "可用天赋位",
    ["EDIT"] = "编辑",
    ["SAVE"] = "保存",
    ["RESET_TALENTS"] = "重置天赋",
    ["EDIT_SPEC"] = "编辑天赋配置",
    ["SPEC_NAME"] = "配置名称:",
    ["SPEC_ICON"] = "配置图标:",
    ["CANCEL"] = "取消",
    ["CONFIRM"] = "确认",
    ["SAVE_SPEC_CONFIRM"] = "将当前天赋保存到此位置?",
    ["LOAD_SPEC_CONFIRM"] = "是否更换此天赋? ",
    ["RESET_TALENTS_CONFIRM"] = "是否重置天赋? 这将花费5金。", 
    ["YES"] = "是",
    ["NO"] = "否",
    ["SHOW_ORIGINAL"] = "显示原版界面",
    ["SHOW_TALENT_POINTS"] = "显示天赋点",  
    ["HIDE_TALENT_POINTS"] = "隐藏天赋点",
    ["BUY_SLOT_CONFIRM"] = "是否购买第%d个天赋槽位? 这将花费%d金。",
    ["SWITCH_STYLE"] = "切换风格",
    ["SWITCH_STYLE_CONFIRM"] = "是否确认切换界面风格? 这将重新加载界面。",
    ["STYLE_CLASSIC"] = "经典风格",
    ["STYLE_DARK"] = "暗黑风格"
}

local mainFrame, editFrame, iconFrame
local specButtons, gossipSlots, iconButtons, macroIcons = {}, {}, {}, {}
local currentEditSlot = 1
BrainwasherPro.currentSlotAction, BrainwasherPro.showTalentPoints, BrainwasherPro.currentStyle = nil, true, "dark"

-- 新增：动作条切换相关变量
local ABP_ACTIONBAR_CHECK_INTERVAL = 0.5 -- 检查间隔（秒）
local lastActionBarCheckTime = 0
local lastLoadedSpecName = nil
local lastSpecLoadAt = {} -- 每个 spec 上次实际调用 ABP_LoadProfile 的时间，用于防止短时间内重复加载（刷屏）
local ABP_SPEC_RELOAD_COOLDOWN = 3 -- 同一 spec 两次实际加载之间的最小间隔（秒），消除天赋切换时动作条配置的重复加载刷屏
local lastLoadedItemSetName = nil -- 新增：记录上次加载的套装名称
local ABP_ITEMSET_CHECK_INTERVAL = 0.5 -- 套装切换检查间隔（秒）
local lastItemSetCheckTime = 0

-- 换装串行化保护：连续两次 WearOutfit+ForceEquipNow 会共用“光标”做背包取装，
-- 若上一次换装还在飞行中（光标被占用），后一次会抢占光标导致头部换装丢失。
-- 因此强制两次换装之间至少间隔 ABP_OUTFIT_EQUIP_GAP 秒，等上一次落地再发下一次。
local ABP_OUTFIT_EQUIP_GAP = 1.3 -- 两次换装最小间隔（秒）
local lastWearTime = 0 -- 上次下发换装的时间
local equipInFlight = false -- 上一次换装是否仍在“飞行中”（光标可能被占用）
-- 头部换装由 BrainwasherPro_VerifyHead 在延迟校验时“直接扫描背包并强制戴上”兜底
-- （绕过 Outfitter 缓存陈旧导致的漏换），不再依赖单独的重试队列。

-- 切换后延迟校验头部是否真的换上（用于排查“头部不换”问题）
local pendingHeadCheck = nil

-- 直接、绕过 Outfitter 缓存，从背包(0-4)扫描目标头部并强制戴上。
-- 返回 true：背包里找到了该物品并已尝试佩戴；
-- 返回 false：背包里找不到（可能在银行/仓库，无法自动取装）。
-- 这是针对“Outfitter 因物品缓存陈旧而把头部从换装清单里跳过”的兜底，最可靠且不依赖 Outfitter 内部状态。
local function BrainwasherPro_ForceEquipHead(pTargetCode)
    if not pTargetCode then
        return false
    end
    -- 已经在头上就直接视为成功
    local vCurLink = GetInventoryItemLink("player", 1) -- 1 = HeadSlot
    local vCurCode = vCurLink and string.match(vCurLink, "item:(%d+):")
    vCurCode = vCurCode and tonumber(vCurCode)
    if vCurCode and vCurCode == pTargetCode then
        return true
    end
    local vHeadID = GetInventorySlotInfo("HeadSlot")
    for vBag = 0, 4 do
        local vNumSlots = GetContainerNumSlots(vBag)
        if vNumSlots and vNumSlots > 0 then
            for vSlot = 1, vNumSlots do
                local vBagLink = GetContainerItemLink(vBag, vSlot)
                if vBagLink then
                    local vCode = string.match(vBagLink, "item:(%d+):")
                    vCode = vCode and tonumber(vCode)
                    if vCode and vCode == pTargetCode then
                        PickupContainerItem(vBag, vSlot)
                        EquipCursorItem(vHeadID)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function BrainwasherPro_VerifyHead()
    if not pendingHeadCheck then
        return
    end
    if GetTime() - pendingHeadCheck.time < 0.8 then
        return
    end
    local vLink = GetInventoryItemLink("player", 1) -- 1 = HeadSlot
    -- 直接从装备链接里取出 itemID 对比，避免中英文物品名不一致造成的误判
    local vCurCode = vLink and string.match(vLink, "item:(%d+):")
    vCurCode = vCurCode and tonumber(vCurCode)
    if vCurCode and vCurCode == pendingHeadCheck.code then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[洗脑器] 头部已正确更换 (itemID: " .. vCurCode .. ", " .. (pendingHeadCheck.name or "") .. ")|r")
    else
        -- Outfitter 可能因物品缓存陈旧把头部从换装清单里跳过（猛切天赋时常见）：
        -- 这里绕过 Outfitter，自己扫描背包并强制戴上目标头部，最可靠。
        local vOk = BrainwasherPro_ForceEquipHead(pendingHeadCheck.code)
        if vOk then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] Outfitter 漏换了头部，已直接强制戴上 " ..
                (pendingHeadCheck.name or "") .. "（itemID: " .. pendingHeadCheck.code .. "）|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[洗脑器] 头部仍未更换！当前头部 itemID: " ..
                (vCurCode and tostring(vCurCode) or "空(无装备)") ..
                " | 目标 itemID: " .. pendingHeadCheck.code ..
                " | 目标头部不在背包（可能在银行/仓库），无法自动取装，请把它放入背包后再切。|r")
        end
    end
    equipInFlight = false -- 无论成功与否都解锁，避免长期阻塞下一次换装
    pendingHeadCheck = nil
end

-- 新增：获取Outfitter套装列表
local function GetOutfitterSetNames()
    local setNames = {}
    if gOutfitter_Settings and gOutfitter_Settings.Outfits then
        for category, outfits in pairs(gOutfitter_Settings.Outfits) do
            if type(outfits) == "table" then
                for _, outfit in ipairs(outfits) do
                    if outfit.Name then
                        table.insert(setNames, outfit.Name)
                    end
                end
            end
        end
    end
    return setNames
end

-- 新增：切换Outfitter套装
local function SwitchOutfitterSet(setName)
    if not gOutfitter_Settings or not gOutfitter_Settings.Outfits then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Outfitter插件未加载或未找到套装数据|r")
        return false, nil
    end

    -- 用 Outfitter 自带函数按名称精确查找，直接拿到 outfit 引用与正确的分类ID
    -- （比手写遍历更可靠：分类键、引用、名称比对都由 Outfitter 自身把关）
    local targetOutfit, targetCategory
    if Outfitter_FindOutfitByName then
        targetOutfit, targetCategory = Outfitter_FindOutfitByName(setName)
    else
        -- 回退：手写遍历（兼容极端情况）
        for category, outfits in pairs(gOutfitter_Settings.Outfits) do
            if type(outfits) == "table" then
                for _, outfit in ipairs(outfits) do
                    if outfit.Name == setName then
                        targetOutfit = outfit
                        targetCategory = category
                        break
                    end
                end
            end
            if targetOutfit then break end
        end
    end

    if not targetOutfit then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000未找到Outfitter套装: " .. (setName or "nil") .. "|r")
        return false, nil
    end

    -- 关键修复：强制 Outfitter 重新扫描背包/装备，避免其物品缓存陈旧，
    -- 误判“目标头部已在头上”而把头部换装从清单里跳过（猛切天赋时最常见）。
    -- Outfitter 的物品缓存只在 BAG_UPDATE/PLAYER_EQUIPMENT_CHANGED 事件时失效，
    -- 连续快速换装时这些事件会延迟/合并，缓存停在旧状态（例如还记着“头部=47228”），
    -- 下次切回该套装就会误以为头部已就位而跳过，实际头部仍是上一套的。
    if gOutfitter_EquippableItems then
        gOutfitter_EquippableItems.NeedsUpdate = true
    end

    -- 穿戴套装，传入正确的分类ID，让 Outfitter 按完整/混搭规则清理套装栈
    -- 否则旧套装会一直留在栈中，导致列表里同时出现多个勾选，且未覆盖的槽位（如头部）不会更换
    Outfitter_WearOutfit(targetOutfit, targetCategory)

    -- 强制立即执行可能被节流的换装（绕过 Outfitter 的 1.5s 装备节流），
    -- 避免部分槽位（尤其头部）因延迟而被跳过 / 未生效
    if Outfitter_ForceEquipNow then
        Outfitter_ForceEquipNow()
    end

    -- 报告目标套装头部配置，便于排查“头部装备未更换”问题
    local vHeadItem = targetOutfit.Items and targetOutfit.Items.HeadSlot
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00已切换Outfitter套装: " .. setName ..
        " | 分类: " .. (targetCategory or "nil") ..
        " | 目标头部: " .. (vHeadItem and (vHeadItem.Name .. " (ID " .. (vHeadItem.Code or "?") .. ")") or "无（空槽）") .. "|r")

    -- 登记一次延迟校验：0.8 秒后检查头部是否真的换上（用 itemID 对比，避免中英文名不一致）
    if vHeadItem and vHeadItem.Code then
        pendingHeadCheck = { code = vHeadItem.Code, name = vHeadItem.Name, time = GetTime() }
    end

    -- 标记本次换装“在飞行中”，用于串行化：阻止下一次换装在光标被占用时抢占
    lastWearTime = GetTime()
    equipInFlight = true

    return true, targetCategory
end



local function ColorTalentSummary(t1, t2, t3)
    local largest, smallest = math.max(t1, t2, t3), math.min(t1, t2, t3)
    local function getColor(value)
        if value == largest then return "|cff00ff00"
        elseif value == smallest then return "|cff0077ff"
        else return "|cffffff00" end
    end
    return getColor(t1)..t1.."|r/"..getColor(t2)..t2.."|r/"..getColor(t3)..t3.."|r"
end

local function GetTalentCounts()
    local _, _, t1 = GetTalentTabInfo(1)
    local _, _, t2 = GetTalentTabInfo(2)
    local _, _, t3 = GetTalentTabInfo(3)
    return t1 or 0, t2 or 0, t3 or 0
end

local function FetchCurrentTalents()
    local talents = {}
    for tab = 1, 3 do
        local _, _, tcount = GetTalentTabInfo(tab)
        talents[tab] = {}
        for talent = 1, 100 do
            local name, icon, row, col, count, max = GetTalentInfo(tab, talent)
            if not name then break end
            talents[tab][talent] = {name = name, icon = icon, row = row, col = col, count = count, max = max}
        end
    end
    return talents
end

-- 计算某个已保存配置与当前实际天赋的匹配度（0~1；-1 表示无法评估，如从未保存过具体天赋）。
-- 按"天赋页内索引"逐一比对当前点数与保存点数，比只比三系总数精确得多。
local function ComputeSpecMatchScore(spec)
    if not spec or not spec.talents then return -1 end
    local score, total = 0, 0
    for tab = 1, 3 do
        local savedTab = spec.talents[tab]
        if type(savedTab) == "table" then
            for idx = 1, table.getn(savedTab) do
                local saved = savedTab[idx]
                if saved and saved.max then
                    total = total + saved.max
                    local _, _, _, _, count = GetTalentInfo(tab, idx)
                    if count == saved.count then
                        score = score + saved.max
                    end
                end
            end
        end
    end
    if total == 0 then return -1 end
    return score / total
end

-- 识别当前天赋对应的配置名称：先按三系点数粗筛，再逐天赋比对取最匹配者。
-- 修复"第4个天赋切换时装备/动作条不动"：
--   1) 旧逻辑用 pairs 遍历 + break，命中"第一个点数相同的 spec"；当第4槽与其它槽
--      三系点数相同（只是具体天赋不同）时，会误识别成别的槽位 → 什么都不切。
--   2) 槽位4保存时点数与当前不符（或只有 0/0/0 占位记录）→ 永远匹配不上。
-- 现改为取"点数相同且逐天赋匹配度最高"的配置；完全无匹配时输出一次性诊断。
local lastNoMatchDiagKey = nil
local function FindCurrentSpecName()
    local t1, t2, t3 = GetTalentCounts()
    local bestName, bestScore = nil, -2
    for slotIndex, spec in pairs(BrainwasherProDB.specs) do
        if spec and spec.name and gossipSlots.load and gossipSlots.load[slotIndex] then
            if spec.t1 == t1 and spec.t2 == t2 and spec.t3 == t3 then
                local score = ComputeSpecMatchScore(spec)
                if score > bestScore then
                    bestScore, bestName = score, spec.name
                end
            end
        end
    end
    if not bestName then
        -- 仅在解析过 gossip 选项之后才提示（登录后还没和装置交互过时不误报）
        if gossipSlots.load then
            local diagKey = t1 .. "/" .. t2 .. "/" .. t3
            if diagKey ~= lastNoMatchDiagKey then
                lastNoMatchDiagKey = diagKey
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[洗脑器] 当前天赋 " .. t1 .. "/" .. t2 .. "/" .. t3 ..
                    " 与任何已保存配置的点数不符，无法联动切换装备/动作条。已保存配置:|r")
                for slotIndex, spec in pairs(BrainwasherProDB.specs) do
                    if spec and spec.name then
                        local hasLoad = gossipSlots.load[slotIndex]
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff8888  槽位" .. slotIndex .. ": " .. (spec.name or "?") ..
                            " " .. (spec.t1 or "?") .. "/" .. (spec.t2 or "?") .. "/" .. (spec.t3 or "?") ..
                            (hasLoad and "" or "（未检测到'启用'选项）") .. "|r")
                    end
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00请在对应天赋下点\"保存\"重新记录一次即可修复。|r")
            end
        end
    else
        lastNoMatchDiagKey = nil
    end
    return bestName
end

-- 修改后的检查并切换动作条配置函数
local pendingBarReload = nil -- { name =, time = } 延迟补加载待办：首遍加载后 0.5s 补一次，规避与 Outfitter 抢光标导致的个别槽位丢失

local function CheckAndSwitchActionBar()

    if not ABP_Layout or not BrainwasherProDB then
        return
    end
    
    local currentTime = GetTime()
    

    -- 延迟补加载：首遍加载 0.5s 后，再加载一次以确保完整（规避与 Outfitter 抢光标时个别槽位丢失）
    if pendingBarReload and currentTime >= pendingBarReload.time then
        local vName = pendingBarReload.name
        pendingBarReload = nil
        ABP_LoadProfile(vName)
        lastSpecLoadAt[vName] = currentTime
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 动作条 '" .. vName .. "' 延迟补加载一次（确保完整）|r")
        return
    end


    if currentTime - lastActionBarCheckTime < ABP_ACTIONBAR_CHECK_INTERVAL then
        return
    end
    lastActionBarCheckTime = currentTime
    

    local currentSpecName = FindCurrentSpecName()


    if currentSpecName and currentSpecName ~= lastLoadedSpecName
       and (not lastSpecLoadAt[currentSpecName] or currentTime - lastSpecLoadAt[currentSpecName] > ABP_SPEC_RELOAD_COOLDOWN) then

        local ABP_PlayerName = UnitName("player") .. " of " .. GetCVar("realmName")
        if ABP_Layout[ABP_PlayerName] and ABP_Layout[ABP_PlayerName][currentSpecName] then

            -- 原 3 遍重载的状态赋值已移除（优化：仅加载 1 次 + 0.5s 后延迟补 1 次）
            

            -- 仅加载 1 次（已移除 3 遍重试；0.5s 后由 pendingBarReload 补 1 次）
             ABP_LoadProfile(currentSpecName)
            lastSpecLoadAt[currentSpecName] = currentTime
	        if Flyout_UpdateBars and Flyout_GetActionButton then
			for i = 1, 120 do
				local b = Flyout_GetActionButton(i)
				if b then
                			b.flyoutActions = nil
                			b.flyoutAction = nil
                			b.flyoutActionType = nil
            			end
        		end
        		Flyout_UpdateBars()
    		end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00已自动切换动作条配置: " .. currentSpecName .. "|r")
            lastLoadedSpecName = currentSpecName
            -- 0.5s 后补加载一次，确保完整（单次加载在光标争用时偶尔丢槽，补一次即可，不再 3 遍）
            pendingBarReload = { name = currentSpecName, time = currentTime + 0.5 }
        else
            lastLoadedSpecName = currentSpecName
        end
    end
end


-- 新增：检查并切换Outfitter套装
local function CheckAndSwitchItemSet()
    if not gOutfitter_Settings then
        return
    end
    
    local currentTime = GetTime()
    if currentTime - lastItemSetCheckTime < ABP_ITEMSET_CHECK_INTERVAL then
        return
    end
    lastItemSetCheckTime = currentTime

    -- 串行化保护：若上一次换装还在“飞行中”（光标可能被占用），且未超过安全间隔，
    -- 则本次先不下发换装，等下一帧再试，避免两次换装在光标上打架把头部换装弄丢
    -- （猛切天赋时最常见：上一次头部换装还没落地，下一次又来抢占光标）
    if equipInFlight and (currentTime - lastWearTime) < ABP_OUTFIT_EQUIP_GAP then
        return
    end

    -- 查找当前天赋对应的配置名称
    local currentSpecName = FindCurrentSpecName()

    -- 如果找到配置名称且与上次不同，则切换套装
    if currentSpecName and currentSpecName ~= lastLoadedItemSetName then
        equipInFlight = false -- 上一次已落地或已超时，允许新的换装
        if SwitchOutfitterSet(currentSpecName) then
            lastLoadedItemSetName = currentSpecName
        else
            -- 如果切换失败，也记录当前套装名称，避免重复尝试
            lastLoadedItemSetName = currentSpecName
        end
    end
end

local function OnTalentLoadComplete()
    lastActionBarCheckTime = GetTime() - ABP_ACTIONBAR_CHECK_INTERVAL + 0.1 
    lastItemSetCheckTime = GetTime() - ABP_ITEMSET_CHECK_INTERVAL + 0.1
    lastLoadedSpecName = nil 
    lastLoadedItemSetName = nil -- 重置套装记录，允许重新检测
end


function BrainwasherPro:PopulateMacroIcons()
    local numIcons = GetNumMacroIcons()
    for i = 1, numIcons do table.insert(macroIcons, GetMacroIconInfo(i)) end
end

function BrainwasherPro:CreateMainFrame()
    if mainFrame then return end
    
    mainFrame = CreateFrame("Frame", "BrainwasherProFrame", UIParent)
    mainFrame:SetWidth(384)
    mainFrame:SetHeight(512)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    local bgTexture = mainFrame:CreateTexture(nil, "BACKGROUND")
    if BrainwasherPro.currentStyle == "classic" then
        bgTexture:SetTexture("Interface\\Stationery\\StationeryTest1")
    else
        bgTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bgTexture:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    end
    
    bgTexture:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -12)
    bgTexture:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -12, 12)
    
    mainFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    mainFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    mainFrame:Hide()
    table.insert(UISpecialFrames, "BrainwasherProFrame")
    
    local topLeft = mainFrame:CreateTexture(nil, "ARTWORK")
    topLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    topLeft:SetPoint("TOP", mainFrame, "TOP", 0, 12)
    topLeft:SetWidth(256)
    topLeft:SetHeight(64)
    
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -5)
    title:SetText(L["TITLE"])
    title:SetTextColor(1, 0.82, 0)
    
    local styleButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    styleButton:SetWidth(100)
    styleButton:SetHeight(22)
    styleButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -10)
    styleButton:SetText(BrainwasherPro.currentStyle == "classic" and L["STYLE_DARK"] or L["STYLE_CLASSIC"])
    styleButton:SetScript("OnClick", function() StaticPopup_Show("BRAINWASHERPRO_SWITCH_STYLE") end)
    
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() 
        mainFrame:Hide()
        if editFrame and editFrame:IsVisible() then editFrame:Hide() end
        CloseGossip()
    end)
    
    for i = 1, 4 do self:CreateSpecSlot(i) end
    
    local bottomPanel = CreateFrame("Frame", nil, mainFrame)
    if BrainwasherPro.currentStyle == "classic" then
        bottomPanel:SetWidth(320)
        bottomPanel:SetHeight(40)
        bottomPanel:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 15)
        bottomPanel:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        bottomPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
        bottomPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        local resetButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        resetButton:SetWidth(100)
        resetButton:SetHeight(22)
        resetButton:SetPoint("LEFT", bottomPanel, "LEFT", 10, 0)
        resetButton:SetText(L["RESET_TALENTS"])
        self.mainResetButton = resetButton
        resetButton:SetScript("OnClick", function()
            local price = gossipSlots.resetPrice or 0
            StaticPopupDialogs["BRAINWASHERPRO_RESET_TALENTS"].text = price > 0 and "重置所有天赋? 这将花费 " .. price .. " 金并导致一个debuff。" or L["RESET_TALENTS_CONFIRM"]
            StaticPopup_Show("BRAINWASHERPRO_RESET_TALENTS")
        end)

        local toggleTalentPointsButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        toggleTalentPointsButton:SetWidth(100)
        toggleTalentPointsButton:SetHeight(22)
        toggleTalentPointsButton:SetPoint("CENTER", bottomPanel, "CENTER", 0, 0)
        toggleTalentPointsButton:SetText(L["HIDE_TALENT_POINTS"])
        self.toggleTalentPointsButton = toggleTalentPointsButton
        toggleTalentPointsButton:SetScript("OnClick", function()
            BrainwasherPro.showTalentPoints = not BrainwasherPro.showTalentPoints
            toggleTalentPointsButton:SetText(BrainwasherPro.showTalentPoints and L["HIDE_TALENT_POINTS"] or L["SHOW_TALENT_POINTS"])
            BrainwasherPro:UpdateAllDisplays()
        end)

        local showOriginalButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        showOriginalButton:SetWidth(100)
        showOriginalButton:SetHeight(22)
        showOriginalButton:SetPoint("RIGHT", bottomPanel, "RIGHT", -10, 0)
        showOriginalButton:SetText(L["SHOW_ORIGINAL"])
        showOriginalButton:SetScript("OnClick", function() 
            mainFrame:Hide()
            GossipFrame:SetAlpha(1)
        end)
    else
        bottomPanel:SetWidth(270) 
        bottomPanel:SetHeight(30) 
        bottomPanel:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 12)

        local resetButton = CreateFrame("Button", nil, bottomPanel)
        resetButton:SetWidth(90)  
        resetButton:SetHeight(27) 
        resetButton:SetPoint("LEFT", bottomPanel, "LEFT", 0, 0)
        resetButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6, 
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5} 
        })
        resetButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        resetButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resetText:SetPoint("CENTER", resetButton, "CENTER", 0, 0)
        resetText:SetText(L["RESET_TALENTS"])
        resetText:SetTextColor(1, 1, 1, 1)
        self.mainResetButton, self.mainResetText = resetButton, resetText
        resetButton:SetScript("OnEnter", function() resetButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        resetButton:SetScript("OnLeave", function() resetButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
        resetButton:SetScript("OnClick", function()
            local price = gossipSlots.resetPrice or 0
            StaticPopupDialogs["BRAINWASHERPRO_RESET_TALENTS"].text = price > 0 and "重置所有天赋? 这将花费 " .. price .. " 金并导致一个debuff。" or L["RESET_TALENTS_CONFIRM"]
            StaticPopup_Show("BRAINWASHERPRO_RESET_TALENTS")
        end)

        local toggleTalentPointsButton = CreateFrame("Button", nil, bottomPanel)
        toggleTalentPointsButton:SetWidth(90) 
        toggleTalentPointsButton:SetHeight(27) 
        toggleTalentPointsButton:SetPoint("CENTER", bottomPanel, "CENTER", 0, 0)
        toggleTalentPointsButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6, 
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5} 
        })
        toggleTalentPointsButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        toggleTalentPointsButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local toggleText = toggleTalentPointsButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        toggleText:SetPoint("CENTER", toggleTalentPointsButton, "CENTER", 0, 0)
        toggleText:SetText(L["HIDE_TALENT_POINTS"])
        toggleText:SetTextColor(1, 1, 1, 1)
        toggleTalentPointsButton.toggleText = toggleText
        self.toggleTalentPointsButton = toggleTalentPointsButton
        toggleTalentPointsButton:SetScript("OnEnter", function() toggleTalentPointsButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        toggleTalentPointsButton:SetScript("OnLeave", function() toggleTalentPointsButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
        toggleTalentPointsButton:SetScript("OnClick", function()
            BrainwasherPro.showTalentPoints = not BrainwasherPro.showTalentPoints
            toggleText:SetText(BrainwasherPro.showTalentPoints and L["HIDE_TALENT_POINTS"] or L["SHOW_TALENT_POINTS"])
            BrainwasherPro:UpdateAllDisplays()
        end)

        local showOriginalButton = CreateFrame("Button", nil, bottomPanel)
        showOriginalButton:SetWidth(90)  
        showOriginalButton:SetHeight(27) 
        showOriginalButton:SetPoint("RIGHT", bottomPanel, "RIGHT", 0, 0)
        showOriginalButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6, 
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5} 
        })
        showOriginalButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        showOriginalButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local originalText = showOriginalButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        originalText:SetPoint("CENTER", showOriginalButton, "CENTER", 0, 0)
        originalText:SetText(L["SHOW_ORIGINAL"])
        originalText:SetTextColor(1, 1, 1, 1)
        showOriginalButton:SetScript("OnEnter", function() showOriginalButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        showOriginalButton:SetScript("OnLeave", function() showOriginalButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
        showOriginalButton:SetScript("OnClick", function() 
            mainFrame:Hide()
            GossipFrame:SetAlpha(1)
        end)
    end
end

function BrainwasherPro:CreateSpecSlot(slotIndex)
    local yOffset = -60 - ((slotIndex - 1) * 90)
    local slotFrame = CreateFrame("Frame", "BrainwasherProSlot"..slotIndex, mainFrame)
    slotFrame:SetWidth(340)
    slotFrame:SetHeight(80)
    slotFrame:SetPoint("TOP", mainFrame, "TOP", 0, yOffset)
    slotFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    slotFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    slotFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    slotFrame:EnableMouse(true)
    slotFrame:SetScript("OnEnter", function() slotFrame:SetBackdropBorderColor(1, 1, 0.5, 1) end)
    slotFrame:SetScript("OnLeave", function() slotFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) end)
    
    local iconButton = CreateFrame("Button", "BrainwasherProIcon"..slotIndex, slotFrame)
    iconButton:SetWidth(40)
    iconButton:SetHeight(40)
    iconButton:SetPoint("LEFT", slotFrame, "LEFT", 10, 0)
    iconButton:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot")
    iconButton:SetPushedTexture("Interface\\Buttons\\UI-EmptySlot")
    iconButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    iconButton:RegisterForClicks("LeftButtonUp")
    local iconTexture = iconButton:CreateTexture(nil, "OVERLAY")  
    iconTexture:SetWidth(36)
    iconTexture:SetHeight(36)
    iconTexture:SetPoint("CENTER", iconButton, "CENTER", 0, 0)
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    iconButton.iconTexture = iconTexture

    local nameText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", iconButton, "RIGHT", 10, 10)
    nameText:SetWidth(180)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(L["AVAILABLE_SLOT"])
    nameText:SetTextColor(0.9, 0.9, 0.9, 1)
    
    local summaryText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summaryText:SetPoint("LEFT", iconButton, "RIGHT", 10, -10)
    summaryText:SetWidth(180)
    summaryText:SetJustifyH("LEFT")
    summaryText:SetText("")
    
    local buttonPanel = CreateFrame("Frame", nil, slotFrame)
    buttonPanel:SetWidth(80)
    buttonPanel:SetHeight(60)  
    buttonPanel:SetPoint("RIGHT", slotFrame, "RIGHT", -10, 0)
    
    local editButton, saveButton
    if BrainwasherPro.currentStyle == "classic" then
        editButton = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
        editButton:SetWidth(70)
        editButton:SetHeight(22)
        editButton:SetPoint("TOP", buttonPanel, "TOP", 0, 5)
        editButton:SetText(L["EDIT"])
        saveButton = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
        saveButton:SetWidth(70)
        saveButton:SetHeight(22)
        saveButton:SetPoint("BOTTOM", buttonPanel, "BOTTOM", 0, -5)
        saveButton:SetText(L["SAVE"])
    else
        editButton = CreateFrame("Button", nil, buttonPanel)
        editButton:SetWidth(70)
        editButton:SetHeight(22)
        editButton:SetPoint("TOP", buttonPanel, "TOP", 0, 5)
        editButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6, 
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5} 
        })
        editButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        editButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local editText = editButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        editText:SetPoint("CENTER", editButton, "CENTER", 0, 0)
        editText:SetText(L["EDIT"])
        editText:SetTextColor(1, 1, 1, 1)
        saveButton = CreateFrame("Button", nil, buttonPanel)
        saveButton:SetWidth(70)
        saveButton:SetHeight(22)
        saveButton:SetPoint("BOTTOM", buttonPanel, "BOTTOM", 0, -5)
        saveButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6, 
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5} 
        })
        saveButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        saveButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local saveText = saveButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        saveText:SetPoint("CENTER", saveButton, "CENTER", 0, 0)
        saveText:SetText(L["SAVE"])
        saveText:SetTextColor(1, 1, 1, 1)
        editButton:SetScript("OnEnter", function() editButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        editButton:SetScript("OnLeave", function() editButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
        saveButton:SetScript("OnEnter", function() saveButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        saveButton:SetScript("OnLeave", function() saveButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
    end
    
    specButtons[slotIndex] = {
        frame = slotFrame,
        icon = iconButton,
        name = nameText,
        summary = summaryText,
        edit = editButton,
        save = saveButton,
        slotIndex = slotIndex
    }
    
    iconButton:SetScript("OnClick", function(self, button) BrainwasherPro:OnSpecClicked(slotIndex) end)
    editButton:SetScript("OnClick", function() BrainwasherPro:OnEditClicked(slotIndex) end)
    saveButton:SetScript("OnClick", function() BrainwasherPro:OnSaveClicked(slotIndex) end)
end

function BrainwasherPro:CreateEditFrame()
    if editFrame then return end
    
    editFrame = CreateFrame("Frame", "BrainwasherProEditFrame", UIParent)
    editFrame:SetWidth(350)
    editFrame:SetHeight(450)
    editFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    local bgTexture = editFrame:CreateTexture(nil, "BACKGROUND")
    if BrainwasherPro.currentStyle == "classic" then
        bgTexture:SetTexture("Interface\\Stationery\\StationeryTest1")
    else
        bgTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bgTexture:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    end
    
    bgTexture:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 12, -12)
    bgTexture:SetPoint("BOTTOMRIGHT", editFrame, "BOTTOMRIGHT", -12, 12)
    
    if BrainwasherPro.currentStyle == "classic" then
        editFrame:SetBackdrop({
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        editFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    else
        editFrame:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        editFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        editFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    end
    
    editFrame:SetFrameStrata("DIALOG")
    editFrame:SetMovable(true)
    editFrame:EnableMouse(true)
    editFrame:RegisterForDrag("LeftButton")
    editFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    editFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    editFrame:Hide()
    
    local topLeft = editFrame:CreateTexture(nil, "ARTWORK")
    topLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    topLeft:SetPoint("TOP", editFrame, "TOP", 0, 12)
    topLeft:SetWidth(256)
    topLeft:SetHeight(64)
    
    local title = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", editFrame, "TOP", 0, -5)
    title:SetText(L["EDIT_SPEC"])
    title:SetTextColor(1, 0.82, 0)
    
    local closeButton = CreateFrame("Button", nil, editFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", editFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() editFrame:Hide() end)
    
    local iconLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iconLabel:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 30, -60)
    iconLabel:SetText(L["SPEC_ICON"])
    iconLabel:SetTextColor(1, 1, 1, 1)
    
    local iconButton = CreateFrame("Button", nil, editFrame)
    iconButton:SetWidth(50)
    iconButton:SetHeight(50)
    iconButton:SetPoint("TOPLEFT", iconLabel, "BOTTOMLEFT", 0, -10)
    iconButton:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot")
    iconButton:SetPushedTexture("Interface\\Buttons\\UI-EmptySlot")
    iconButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local iconTexture = iconButton:CreateTexture(nil, "OVERLAY")  
    iconTexture:SetWidth(40)
    iconTexture:SetHeight(40)
    iconTexture:SetPoint("CENTER", iconButton, "CENTER", 0, 0)
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    iconButton.iconTexture = iconTexture
    editFrame.iconButton = iconButton
    
    local nameLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", iconLabel, "RIGHT", 30, 0)
    nameLabel:SetText(L["SPEC_NAME"])
    nameLabel:SetTextColor(1, 1, 1, 1)
    
    local nameEdit = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
    nameEdit:SetWidth(120)  
    nameEdit:SetHeight(20)
    nameEdit:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameEdit:SetFont("Fonts\\FRIZQT__.TTF", 11)
    nameEdit:SetTextColor(1, 1, 1, 1)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetMaxLetters(20)
    editFrame.nameEdit = nameEdit
    
    local iconScrollBackground = CreateFrame("Frame", nil, editFrame)
    iconScrollBackground:SetPoint("TOPLEFT", iconButton, "BOTTOMLEFT", -10, -15)  
    iconScrollBackground:SetPoint("BOTTOMRIGHT", editFrame, "BOTTOMRIGHT", -20, 70)
    
    if BrainwasherPro.currentStyle == "classic" then
        iconScrollBackground:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        iconScrollBackground:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    else
        iconScrollBackground:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        iconScrollBackground:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        iconScrollBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    local scrollFrame = CreateFrame("ScrollFrame", "BrainwasherProIconScrollFrame", iconScrollBackground, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", iconScrollBackground, "TOPLEFT", 8, -8)  
    scrollFrame:SetPoint("BOTTOMRIGHT", iconScrollBackground, "BOTTOMRIGHT", -28, 8)  
    
    local content = CreateFrame("Frame", "BrainwasherProIconContent", scrollFrame)
    content:SetWidth(250)  
    scrollFrame:SetScrollChild(content)
    editFrame.iconScrollFrame, editFrame.iconContent, editFrame.iconScrollBackground = scrollFrame, content, iconScrollBackground
    
    local iconsPerRow, iconSize, iconSpacing = 8, 30, 33
    local totalRows = math.ceil(table.getn(macroIcons) / iconsPerRow)
    content:SetHeight(totalRows * iconSpacing + 15)
    
    for i = 1, table.getn(macroIcons) do
        local row = math.ceil(i / iconsPerRow) - 1
        local col = i - 1 - (row * iconsPerRow)
        local iconBtn = CreateFrame("Button", nil, content)
        iconBtn:SetWidth(iconSize)
        iconBtn:SetHeight(iconSize)
        iconBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 10 + (col * iconSpacing), -10 - (row * iconSpacing))  
        iconBtn:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot")
        iconBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local btnTexture = iconBtn:CreateTexture(nil, "OVERLAY")  
        btnTexture:SetWidth(iconSize - 4)
        btnTexture:SetHeight(iconSize - 4)
        btnTexture:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
        btnTexture:SetTexture(macroIcons[i])
        iconBtn.iconTexture = btnTexture
        iconBtn:SetScript("OnClick", (function(iconIndex)
            return function()
                if iconIndex <= table.getn(macroIcons) and editFrame and editFrame.iconButton and editFrame.iconButton.iconTexture then
                    editFrame.iconButton.iconTexture:SetTexture(macroIcons[iconIndex])
                end
            end
        end)(i))
        iconButtons[i] = iconBtn
    end
    
    local buttonPanel = CreateFrame("Frame", nil, editFrame)
    buttonPanel:SetWidth(300)
    buttonPanel:SetHeight(40)
    buttonPanel:SetPoint("BOTTOM", editFrame, "BOTTOM", 0, 20)
    
    local confirmButton, cancelButton
    if BrainwasherPro.currentStyle == "classic" then
        confirmButton = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
        confirmButton:SetWidth(100)
        confirmButton:SetHeight(22)
        confirmButton:SetPoint("LEFT", buttonPanel, "LEFT", 30, 0)
        confirmButton:SetText(L["CONFIRM"])
        cancelButton = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(22)
        cancelButton:SetPoint("RIGHT", buttonPanel, "RIGHT", -30, 0)
        cancelButton:SetText(L["CANCEL"])
    else
        confirmButton = CreateFrame("Button", nil, buttonPanel)
        confirmButton:SetWidth(100)
        confirmButton:SetHeight(22)
        confirmButton:SetPoint("LEFT", buttonPanel, "LEFT", 30, 0)
        confirmButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6,
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5}
        })
        confirmButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        confirmButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local confirmText = confirmButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        confirmText:SetPoint("CENTER", confirmButton, "CENTER", 0, 0)
        confirmText:SetText(L["CONFIRM"])
        confirmText:SetTextColor(1, 1, 1, 1)
        confirmButton:SetScript("OnEnter", function() confirmButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        confirmButton:SetScript("OnLeave", function() confirmButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
        cancelButton = CreateFrame("Button", nil, buttonPanel)
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(22)
        cancelButton:SetPoint("RIGHT", buttonPanel, "RIGHT", -30, 0)
        cancelButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 6,
            insets = {left = 1.5, right = 1.5, top = 1.5, bottom = 1.5}
        })
        cancelButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
        cancelButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local cancelText = cancelButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cancelText:SetPoint("CENTER", cancelButton, "CENTER", 0, 0)
        cancelText:SetText(L["CANCEL"])
        cancelText:SetTextColor(1, 1, 1, 1)
        cancelButton:SetScript("OnEnter", function() cancelButton:SetBackdropColor(0.8, 0.3, 0.3, 1) end)
        cancelButton:SetScript("OnLeave", function() cancelButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8) end)
    end
    
    confirmButton:SetScript("OnClick", function() BrainwasherPro:ConfirmEdit() end)
    cancelButton:SetScript("OnClick", function() editFrame:Hide() end)
end

function BrainwasherPro:OnSpecClicked(slotIndex)
    local hasBuyOption, hasLoadOption, hasSaveOption = gossipSlots.buy and gossipSlots.buy[slotIndex], gossipSlots.load and gossipSlots.load[slotIndex], gossipSlots.save and gossipSlots.save[slotIndex]
    if hasBuyOption then
        BrainwasherPro.currentSlotAction = slotIndex
        local price = gossipSlots.buy[slotIndex].price
        StaticPopupDialogs["BRAINWASHERPRO_BUY_SLOT"].text = string.format(L["BUY_SLOT_CONFIRM"], slotIndex, price)
        StaticPopup_Show("BRAINWASHERPRO_BUY_SLOT")
    elseif hasLoadOption then
        BrainwasherPro.currentSlotAction = slotIndex
        StaticPopup_Show("BRAINWASHERPRO_LOAD_SPEC")
    elseif hasSaveOption then
        BrainwasherPro:OnSaveClicked(slotIndex)
    end
end

function BrainwasherPro:OnEditClicked(slotIndex)
    local spec = BrainwasherProDB.specs[slotIndex]
    if not spec then return end
    currentEditSlot = slotIndex
    if not editFrame then self:CreateEditFrame() end
    editFrame.nameEdit:SetText(spec.name or "配置 " .. slotIndex)
    editFrame.iconButton.iconTexture:SetTexture(spec.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if mainFrame and mainFrame:IsVisible() then
        local mainX, mainY, mainWidth, mainHeight = mainFrame:GetCenter(), mainFrame:GetWidth(), mainFrame:GetHeight()
        local editWidth, screenWidth = editFrame:GetWidth(), UIParent:GetWidth()
        local rightSpace = screenWidth - (mainX + mainWidth/2)
        editFrame:ClearAllPoints()
        if rightSpace < editWidth + 20 then editFrame:SetPoint("RIGHT", mainFrame, "LEFT", -20, 0)
        else editFrame:SetPoint("LEFT", mainFrame, "RIGHT", 20, 0) end
    else editFrame:ClearAllPoints(); editFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
    editFrame:Show()
end

function BrainwasherPro:OnSaveClicked(slotIndex)
    if gossipSlots.save and gossipSlots.save[slotIndex] then
        BrainwasherPro.currentSlotAction = slotIndex
        StaticPopup_Show("BRAINWASHERPRO_SAVE_SPEC")
    end
end

function BrainwasherPro:ConfirmEdit()
    local slotIndex, spec = currentEditSlot, BrainwasherProDB.specs[currentEditSlot]
    if spec then spec.name, spec.icon = editFrame.nameEdit:GetText(), editFrame.iconButton.iconTexture:GetTexture(); self:UpdateSpecDisplay(slotIndex) end
    editFrame:Hide()
end

function BrainwasherPro:UpdateSpecDisplay(slotIndex)
    local button, spec = specButtons[slotIndex], BrainwasherProDB.specs[slotIndex]
    local hasLoadOption, hasSaveOption, hasBuyOption = gossipSlots.load and gossipSlots.load[slotIndex], gossipSlots.save and gossipSlots.save[slotIndex], gossipSlots.buy and gossipSlots.buy[slotIndex]
    
    if hasBuyOption then
        button.icon.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
        local price = gossipSlots.buy[slotIndex].price
        button.name:SetText("购买槽位 " .. slotIndex .. " (" .. price .. "金)")
        button.name:SetTextColor(1, 0.8, 0, 1)
        button.summary:SetText("点击图标购买新的天赋栏")
        button.edit:Hide(); button.save:Hide()
    elseif hasLoadOption and spec then
        button.icon.iconTexture:SetTexture(spec.icon or "Interface\\Icons\\Spell_ChargePositive")
        local nameText = spec.name or "已保存配置 " .. slotIndex
        if BrainwasherPro.showTalentPoints and spec.t1 and spec.t2 and spec.t3 then 
            nameText = nameText .. " (" .. ColorTalentSummary(spec.t1, spec.t2, spec.t3) .. ")"
        end
        button.name:SetText(nameText); button.name:SetTextColor(0.5, 1, 0.5, 1)
        button.summary:SetText("点击图标加载天赋")
        button.edit:Show(); button.save:Show()
    elseif hasSaveOption then
        button.icon.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.name:SetText(L["AVAILABLE_SLOT"]); button.name:SetTextColor(0.7, 0.7, 0.7, 1)
        button.summary:SetText(" "); button.edit:Hide(); button.save:Show()
    else
        button.icon.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.name:SetText("请购买上一个天赋栏"); button.name:SetTextColor(1, 0, 0, 1)
        button.summary:SetText(""); button.edit:Hide(); button.save:Hide()
    end
end

function BrainwasherPro:UpdateAllDisplays() for i = 1, 4 do self:UpdateSpecDisplay(i) end end

function BrainwasherPro:SaveCurrentSpec(slotIndex)
    if not slotIndex then return end
    local t1, t2, t3 = GetTalentCounts()
    local talents = FetchCurrentTalents()
    
    local spec = BrainwasherProDB.specs[slotIndex] or {}
    
    spec.t1 = t1
    spec.t2 = t2
    spec.t3 = t3
    spec.talents = talents

    if not spec.name then
        spec.name = "配置 " .. slotIndex
    end
    if not spec.icon then
        spec.icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    
    BrainwasherProDB.specs[slotIndex] = spec
    
    if gossipSlots.save and gossipSlots.save[slotIndex] then
        gossipSlots.save[slotIndex]:Click()
    end
end

function BrainwasherPro:ResetTalents()
    if gossipSlots.reset then
        gossipSlots.reset:Click()
    end
end

function BrainwasherPro:BuySlot(slotIndex)
    if slotIndex and gossipSlots.buy and gossipSlots.buy[slotIndex] then
        -- 模拟点击购买按钮
        local buyInfo = gossipSlots.buy[slotIndex]
        if buyInfo.button and buyInfo.button:IsVisible() then
            buyInfo.button:Click()
            
            -- 更新UI显示
            self:ParseGossipOptions()  -- 重新解析gossip选项
            self:UpdateAllDisplays()   -- 更新所有显示
        end
    end
end

function BrainwasherPro:ParseGossipOptions()
    gossipSlots = {save = {}, load = {}, buy = {}, reset = nil, resetPrice = 0}
    for i = 1, NUMGOSSIPBUTTONS do
        local titleButton = getglobal("GossipTitleButton" .. i)
        if titleButton and titleButton:IsVisible() then
            local text = titleButton:GetText()
            local _, _, saveSpec = string.find(text, "保存第(%d+)天赋")
            local _, _, loadSpec = string.find(text, "启用第(%d+)天赋")
            local _, _, buyPrice, buySpec = string.find(text, "用(%d+)金币购买第(%d+)个天赋标签")
            local resetMatch, _, resetPrice = string.find(text, "重置我的天赋"), string.find(text, "重置我的天赋.*(%d+)金币")
            if saveSpec then gossipSlots.save[tonumber(saveSpec)] = titleButton
            elseif loadSpec then 
                local slotNum = tonumber(loadSpec)
                gossipSlots.load[slotNum] = titleButton
                if not BrainwasherProDB.specs[slotNum] then BrainwasherProDB.specs[slotNum] = {name = "配置 " .. slotNum, icon = "Interface\\Icons\\INV_Misc_QuestionMark", t1 = 0, t2 = 0, t3 = 0, talents = {}} end
            elseif buySpec and buyPrice then gossipSlots.buy[tonumber(buySpec)] = {button = titleButton, price = tonumber(buyPrice) or 0}
            elseif resetMatch then gossipSlots.reset = titleButton; if resetPrice then gossipSlots.resetPrice = tonumber(resetPrice) or 0 end end
        end
    end
end

function BrainwasherPro:OnGossipShow()
    if GossipFrameNpcNameText:GetText() ~= "地精洗脑装置" then return end
    self:ParseGossipOptions()
    GossipFrame:SetAlpha(0)
    if not mainFrame then self:CreateMainFrame() end
    if self.mainResetButton and self.mainResetText then
        if gossipSlots.reset then
            self.mainResetButton:Show()
            if gossipSlots.resetPrice and gossipSlots.resetPrice > 0 then self.mainResetText:SetText(L["RESET_TALENTS"] .. " (" .. gossipSlots.resetPrice .. "金)")
            else self.mainResetText:SetText(L["RESET_TALENTS"]) end
        else self.mainResetButton:Hide() end
    end
    if self.toggleTalentPointsButton and self.toggleTalentPointsButton.toggleText then
        self.toggleTalentPointsButton.toggleText:SetText(BrainwasherPro.showTalentPoints and L["HIDE_TALENT_POINTS"] or L["SHOW_TALENT_POINTS"])
    end
    mainFrame:Show(); self:UpdateAllDisplays()
end

function BrainwasherPro:OnGossipClosed() 
    if mainFrame then mainFrame:Hide() end; 
    if editFrame and editFrame:IsVisible() then editFrame:Hide() end 
    GossipFrame:SetAlpha(1)
end

StaticPopupDialogs["BRAINWASHERPRO_LOAD_SPEC"] = {
    text = L["LOAD_SPEC_CONFIRM"], button1 = L["YES"], button2 = L["NO"],
    OnShow = function()
        local slotIndex, specName = BrainwasherPro.currentSlotAction, "配置 " .. BrainwasherPro.currentSlotAction
        if slotIndex and BrainwasherProDB.specs[slotIndex] and BrainwasherProDB.specs[slotIndex].name then specName = BrainwasherProDB.specs[slotIndex].name end
        local textField = getglobal(this:GetName().."Text")
        if textField then 
            -- 检查是否有对应的动作条配置和Outfitter套装
            local actionBarInfo = ""
            local itemSetInfo = ""
            local playerName = UnitName("player") .. " of " .. GetCVar("realmName")
            
            if ABP_Layout and ABP_Layout[playerName] and ABP_Layout[playerName][specName] then
                actionBarInfo = "\n\n|cff00ff00同时将切换动作条配置: " .. specName .. "|r"
            else
                actionBarInfo = "\n\n|cffff0000(未找到同名的动作条配置)|r"
            end
            
            local hasOutfitterSet = false
            local setNames = GetOutfitterSetNames()
            for _, setName in ipairs(setNames) do
                if setName == specName then
                    hasOutfitterSet = true
                    break
                end
            end
            
            if hasOutfitterSet then
                itemSetInfo = "\n\n|cff00ff00同时将切换Outfitter套装: " .. specName .. "|r"
            else
                itemSetInfo = "\n\n|cffff0000(未找到同名的Outfitter套装)|r"
            end
            
            textField:SetText("是否切换'" .. specName .. "'天赋?" .. actionBarInfo .. itemSetInfo) 
        end
    end,
    OnAccept = function() 
        if BrainwasherPro.currentSlotAction and gossipSlots.load and gossipSlots.load[BrainwasherPro.currentSlotAction] then 
            gossipSlots.load[BrainwasherPro.currentSlotAction]:Click() 
  
            OnTalentLoadComplete()
        end 
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["BRAINWASHERPRO_SAVE_SPEC"] = {
    text = L["SAVE_SPEC_CONFIRM"], button1 = L["YES"], button2 = L["NO"],
    OnAccept = function() BrainwasherPro:SaveCurrentSpec(BrainwasherPro.currentSlotAction) end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["BRAINWASHERPRO_RESET_TALENTS"] = {
    text = L["RESET_TALENTS_CONFIRM"], button1 = L["YES"], button2 = L["NO"],
    OnAccept = function() BrainwasherPro:ResetTalents() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["BRAINWASHERPRO_BUY_SLOT"] = {
    text = "", button1 = L["YES"], button2 = L["NO"],
    OnAccept = function() BrainwasherPro:BuySlot(BrainwasherPro.currentSlotAction) end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["BRAINWASHERPRO_SWITCH_STYLE"] = {
    text = L["SWITCH_STYLE_CONFIRM"], button1 = L["YES"], button2 = L["NO"],
    OnAccept = function()
        BrainwasherPro.currentStyle = BrainwasherPro.currentStyle == "classic" and "dark" or "classic"
        BrainwasherProDB.style = BrainwasherPro.currentStyle
        ReloadUI()
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("GOSSIP_CLOSED")
-- eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- 取消注册这个事件，如果我们不需要它的话
eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "BrainwasherPro" then
        if not BrainwasherProDB then BrainwasherProDB = {specs = {}, style = "dark"} end
        if not BrainwasherProDB.specs then BrainwasherProDB.specs = {} end
        if not BrainwasherProDB.style then BrainwasherProDB.style = "dark" end
        BrainwasherPro.currentStyle = BrainwasherProDB.style
        BrainwasherPro:PopulateMacroIcons()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00地精洗脑装置已加载! 与洗脑装置交互以使用.|r")
        

        eventFrame:SetScript("OnUpdate", function()
            CheckAndSwitchActionBar()
            CheckAndSwitchItemSet() -- 新增：检查并切换Outfitter套装
            BrainwasherPro_VerifyHead() -- 校验头部是否真的换上；若 Outfitter 漏换则直接强制戴上
        end)
        
    elseif event == "GOSSIP_SHOW" then BrainwasherPro:OnGossipShow()
    elseif event == "GOSSIP_CLOSED" then BrainwasherPro:OnGossipClosed() 
    -- 注释掉PLAYER_ENTERING_WORLD事件的处理
    -- elseif event == "PLAYER_ENTERING_WORLD" then
    --     lastActionBarCheckTime = 0
    --     lastLoadedSpecName = nil
    --     lastLoadedItemSetName = nil -- 新增：重置套装记录
    end
end)