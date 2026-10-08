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

-- 统一协调天赋、换装、动作条和属性预设，只执行最新一次稳定的天赋。
local lastSwitchCheckTime = 0
local stableCandidateKey, stableCandidateSince, appliedSpecKey = nil, 0, nil
local pendingSpecSwitch = nil
local expectedSpecSlot, expectedSpecUntil = nil, 0
local worldReady = false
local talentDirty, nextIdleCheck = true, 0
local cachedSpecName, cachedSpecSlot
local lastTalentRead = 0
local lastInventoryChange = 0
local spellRevision = 0
local PROPERTY_PRESETS = {"不切换", "物理", "法系", "治疗", "猎人", "混伤", "防御", "自定义"}

local function IsPropertyPreset(name)
    for _, preset in ipairs(PROPERTY_PRESETS) do
        if preset == name then return true end
    end
    return false
end

local function CanUseCursor()
    if (InCombatLockdown and InCombatLockdown())
       or (UnitAffectingCombat and UnitAffectingCombat("player")) then return false end
    return not (SM_CURSOR or (GetCursorInfo and GetCursorInfo())
        or (CursorHasItem and CursorHasItem())
        or (CursorHasSpell and CursorHasSpell())
        or (CursorHasMacro and CursorHasMacro())
        or (SpellIsTargeting and SpellIsTargeting()))
end

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
                        if CursorHasItem and CursorHasItem() then ClearCursor() end
                        return true
                    end
                end
            end
        end
    end
    return false
end

local EQUIPMENT_SLOT_LABELS = {
    HeadSlot="头部", NeckSlot="项链", ShoulderSlot="肩部", BackSlot="披风",
    ChestSlot="胸部", ShirtSlot="衬衣", TabardSlot="战袍", WristSlot="护腕",
    HandsSlot="手套", WaistSlot="腰带", LegsSlot="腿部", FeetSlot="脚部",
    Finger0Slot="戒指1", Finger1Slot="戒指2", Trinket0Slot="饰品1", Trinket1Slot="饰品2",
    MainHandSlot="主手", SecondaryHandSlot="副手", RangedSlot="远程", AmmoSlot="弹药",
}

-- Matching and diagnostics use the same predicate; normal polling does not
-- allocate a mismatch list or look up item names.
local function GetOutfitSlotMismatch(slotName, item)
    local slot = GetInventorySlotInfo(slotName)
    if not slot or not item or not item.Code then return nil end
    local link = GetInventoryItemLink("player", slot)
    local _, _, code, enchant, sub = string.find(link or "", "item:(%d+):(%d+):(%-?%d+)")
    if not code then local _, _, id = string.find(link or "", "item:(%d+)"); code = id end
    code, enchant, sub = tonumber(code) or 0, tonumber(enchant) or 0, tonumber(sub) or 0
    if code ~= item.Code then
        if item.Code == 0 then return "预设要求卸下", link, slot end
        if code == 0 then return "当前槽位为空", link, slot end
        return "物品不同", link, slot
    end
    if item.Code ~= 0 and item.SubCode and sub ~= item.SubCode then
        return "随机属性不同", link, slot, sub, item.SubCode
    end
    if item.Code ~= 0 and item.EnchantCode and enchant ~= item.EnchantCode then
        return "附魔不同", link, slot, enchant, item.EnchantCode
    end
    return nil
end

local function OutfitMatches(outfit)
    if not outfit or not outfit.Items then return true end
    for slotName, item in pairs(outfit.Items) do
        if GetOutfitSlotMismatch(slotName, item) then return false end
    end
    return true
end

local function ReportUnmatchedEquipment(outfit, name)
    local entries = {}
    for slotName, item in pairs(outfit and outfit.Items or {}) do
        local reason, link, slot, actualValue, expectedValue = GetOutfitSlotMismatch(slotName, item)
        if reason then
            if actualValue then
                reason = reason .. "（预设：" .. expectedValue .. "，当前：" .. actualValue .. "）"
            end
            local target = "空槽（卸下装备）"
            if item.Code ~= 0 then
                local itemName = item.Name
                if not itemName and GetItemInfo then itemName = GetItemInfo(item.Code) end
                target = (itemName or "未知装备") .. "（ID：" .. item.Code .. "）"
            end
            table.insert(entries, {slot=slot, text=(EQUIPMENT_SLOT_LABELS[slotName] or slotName)
                .. "：目标 " .. target .. "；当前 " .. (link or "空槽") .. "；原因：" .. reason})
        end
    end
    if table.getn(entries) == 0 then return end
    table.sort(entries, function(a, b) return a.slot < b.slot end)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 套装“" .. (name or "未知")
        .. "”部分装备未到位，已结束等待。未匹配槽位如下：|r")
    for _, entry in ipairs(entries) do
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] " .. entry.text .. "|r")
    end
end

local function RefreshOutfitCache(includeBags)
    if OutfitterItemList_FlushInventoryFromEquippableItems then
        OutfitterItemList_FlushInventoryFromEquippableItems()
        if includeBags and OutfitterItemList_FlushBagFromEquippableItems then
            for bag = 0, NUM_BAG_SLOTS or 4 do OutfitterItemList_FlushBagFromEquippableItems(bag) end
        end
    elseif OutfitterItemList_FlushEquippableItems then
        OutfitterItemList_FlushEquippableItems()
    elseif gOutfitter_EquippableItems then
        gOutfitter_EquippableItems.NeedsUpdate = true
    end
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

    -- Invalidate the inventory subcache through Outfitter's own API.
    -- Bag events already invalidate individual bags; rebuild all bags only
    -- on the bounded retry if an outfit has failed to arrive.
    RefreshOutfitCache(false)
    Outfitter_WearOutfit(targetOutfit, targetCategory)
    if Outfitter_ForceEquipNow then Outfitter_ForceEquipNow() end

    return true, targetOutfit, targetCategory
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
        talents[tab] = {}
        for talent = 1, 100 do
            local name, icon, row, col, count, max = GetTalentInfo(tab, talent)
            if not name then break end
            talents[tab][talent] = {name = name, icon = icon, row = row, col = col, count = count, max = max}
        end
    end
    return talents
end

-- 完整天赋匹配：1 表示完全一致，0 表示不同，-1 表示没有完整记录。
-- 按天赋页内索引比对名称和点数，避免相同三系总数的不同方案被误识别。
local function ComputeSpecMatchScore(spec, liveTalents)
    if not spec or not spec.talents then return -1 end
    local total = 0
    for tab = 1, 3 do
        local savedTab = spec.talents[tab]
        if type(savedTab) ~= "table" then return -1 end
        -- 必须完整匹配，不能用“最接近”的方案清空动作栏。
        local seen = 0
        for idx = 1, 100 do
            local live = liveTalents[tab][idx]
            if not live then break end
            local name, count = live.name, live.count
            local saved = savedTab[idx]
            if not saved or saved.name ~= name or saved.count ~= count then return 0 end
            seen = seen + 1
            total = total + 1
        end
        if seen ~= table.getn(savedTab) then return 0 end
    end
    if total == 0 then return -1 end
    return 1
end

-- 使用完整天赋记录识别，无须先与洗脑装置交互。
local lastNoMatchDiagKey = nil
local function FindCurrentSpecName()
    if not BrainwasherProDB or not BrainwasherProDB.specs then return nil end
    local t1, t2, t3 = GetTalentCounts()
    local matches = {}
    local liveTalents
    for slotIndex, spec in pairs(BrainwasherProDB.specs) do
        if spec and spec.name and spec.t1 == t1 and spec.t2 == t2 and spec.t3 == t3 then
            liveTalents = liveTalents or FetchCurrentTalents()
            if ComputeSpecMatchScore(spec, liveTalents) == 1 then table.insert(matches, slotIndex) end
        end
    end
    local matchedSlot = nil
    if table.getn(matches) == 1 then
        matchedSlot = matches[1]
    elseif table.getn(matches) > 1 then
        -- 完全相同的天赋：优先采用用户明确选择的槽位，其次保留已确认的槽位。
        if expectedSpecSlot and GetTime() <= expectedSpecUntil then
            for _, slot in ipairs(matches) do
                if slot == expectedSpecSlot then matchedSlot = slot; break end
            end
        end
        if not matchedSlot and BrainwasherPro.activeSpecSlot then
            for _, slot in ipairs(matches) do
                if slot == BrainwasherPro.activeSpecSlot then matchedSlot = slot; break end
            end
        end
    end
    if not matchedSlot then
        if gossipSlots.load then
            local diagKey = t1 .. "/" .. t2 .. "/" .. t3
            if diagKey ~= lastNoMatchDiagKey then
                lastNoMatchDiagKey = diagKey
                DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 当前天赋无法唯一匹配已保存的完整记录，暂不联动。请在对应天赋下重新保存；相同天赋请明确点击要启用的槽位。|r")
            end
        end
        return nil
    end
    lastNoMatchDiagKey = nil
    return BrainwasherProDB.specs[matchedSlot].name, matchedSlot
end

local function ResetTalentSync(slotIndex)
    lastSwitchCheckTime = 0
    stableCandidateKey, appliedSpecKey = nil, nil
    pendingSpecSwitch = nil
    talentDirty, nextIdleCheck = true, 0
    expectedSpecSlot = slotIndex
    expectedSpecUntil = GetTime() + 8
end

local function CheckAndSwitchPresets()
    if not worldReady then return end
    local now = GetTime()
    -- Idle safety check covers clients which occasionally omit talent events.
    -- All expensive work otherwise runs only during an active transition.
    if not talentDirty and not pendingSpecSwitch and now < nextIdleCheck then return end
    if now - lastSwitchCheckTime < 0.1 then return end
    lastSwitchCheckTime = now
    if talentDirty or now >= nextIdleCheck then
        if now - lastTalentRead < 0.15 then return end
        cachedSpecName, cachedSpecSlot = FindCurrentSpecName()
        lastTalentRead, talentDirty, nextIdleCheck = now, false, now + 3
    end
    local name, slot = cachedSpecName, cachedSpecSlot
    if expectedSpecSlot and now <= expectedSpecUntil and slot ~= expectedSpecSlot then
        name, slot = nil, nil
        talentDirty = true
    end
    local spec = slot and BrainwasherProDB.specs[slot]
    local key = spec and (tostring(slot) .. ":" .. name .. ":" .. (spec.propertiesPreset or "不切换"))
    if key ~= stableCandidateKey then
        stableCandidateKey, stableCandidateSince = key, now
        pendingSpecSwitch, appliedSpecKey = nil, nil
    end
    if not key then return end
    -- Exact, stable talents identify the target. Skill readiness is handled
    -- per slot below; recurring SPELLS_CHANGED must not stall the whole job.
    if now - stableCandidateSince < 0.15 then
        -- Keep the coordinator awake until debounce completes.
        talentDirty = true
        return
    end
    if not pendingSpecSwitch and key ~= appliedSpecKey then
        pendingSpecSwitch = {key=key, name=name, slot=slot, deadline=now+8}
        appliedSpecKey, BrainwasherPro.activeSpecSlot, expectedSpecSlot = key, slot, nil
    end
    local job = pendingSpecSwitch
    if not job then return end

    -- Highest priority after talent confirmation: spells, macros and empty
    -- slots. A missing spell never blocks unrelated buttons or equipment.
    if not job.barsDone and CanUseCursor() then
        if not ABP_LoadProfile or not ABP_Layout then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 动作条保存插件未就绪，未切换动作条。|r")
            job.barsDone, job.barsStarted, job.itemBarsDone = true, true, true
        else
            local player = UnitName("player") .. " of " .. GetCVar("realmName")
            if not ABP_Layout[player] or not ABP_Layout[player][name] then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 未找到同名动作条配置：" .. name .. "，当前动作条已保留。|r")
                job.barsDone, job.barsStarted, job.itemBarsDone = true, true, true
            elseif not job.barsStarted or job.spellRevision ~= spellRevision
                or now >= (job.nextSpellRetry or 0) or now >= job.deadline then
                local ok, report = ABP_LoadProfile(name, {
                    quiet=true, phase="core", slots=job.pendingSpellSlots,
                    deferMissingSpells=now<job.deadline, allowPartialSpells=now<job.deadline,
                })
                job.spellRevision = spellRevision
                -- Short polling only while the skillbook is settling; events
                -- resume immediately. Later fallback checks are less frequent.
                job.nextSpellRetry = now + (now - stableCandidateSince < 1.5 and 0.2 or 0.5)
                if ok then
                    if not job.barsStarted then
                        job.barsStartedAt = now
                        job.itemBarsDone = not report.hasItems
                    end
                    job.barsStarted, job.hasActionProfile = true, true
                    job.pendingSpellSlots = report.pendingSpells
                    job.barsDone = not next(report.pendingSpells)
                elseif report ~= "combat" and report ~= "cursor" and report ~= "spells_pending" then
                    job.barsDone, job.barsStarted, job.itemBarsDone = true, true, true
                end
            end
        end
    end

    if not job.panelDone then
        local preset, panel = spec.propertiesPreset, BCS and BCS.PropertiesPanel
        if not preset or preset == "不切换" then job.panelDone = true
        elseif not IsPropertyPreset(preset) then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 属性预设无效，请重新编辑天赋方案。|r")
            job.panelDone = true
        elseif panel and panel.initialized and panel.SelectConfig then
            panel:SelectConfig(preset, true, true)
            job.panelDone = true
        elseif now >= job.deadline then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[洗脑器] 浮动属性面板未就绪，未切换预设。|r")
            job.panelDone = true
        end
    end

    -- Start the heavier outfit work on a later update than the initial bar
    -- restore so both sets of cursor operations don't burst in one frame.
    if not job.itemsStarted and job.barsStarted and now > (job.barsStartedAt or 0) then
        if not gOutfitter_Settings or not Outfitter_WearOutfit then
            job.itemsStarted, job.itemsDone = true, true
        elseif CanUseCursor() then
            local ok, outfit, category = SwitchOutfitterSet(name)
            job.itemsStarted, job.outfit, job.wearTime = true, ok and outfit or nil, now
            job.outfitCategory = category
            job.equipDeadline = now + 8
            if not ok then job.itemsDone = true end
        end
    end
    if job.itemsStarted and not job.itemsDone and CanUseCursor() then
        if OutfitMatches(job.outfit) and now - job.wearTime >= 0.1
            and now - lastInventoryChange >= 0.1 then
            job.itemsDone = true
        elseif now - job.wearTime >= 0.6 and not job.equipRetried then
            job.equipRetried = true
            RefreshOutfitCache(true)
            Outfitter_WearOutfit(job.outfit, job.outfitCategory)
            if Outfitter_ForceEquipNow then Outfitter_ForceEquipNow() end
            -- Preserve the head fallback for clients where Outfitter missed it.
            local head = job.outfit.Items and job.outfit.Items.HeadSlot
            if head and head.Code and head.Code ~= 0 then BrainwasherPro_ForceEquipHead(head.Code) end
        elseif now >= job.equipDeadline then
            ReportUnmatchedEquipment(job.outfit, job.name)
            job.itemsDone = true
        end
    end

    -- Item locations may have changed during the outfit swap. Restore only
    -- item slots here; ready spells/macros are never reloaded a second time.
    if job.itemsDone and not job.itemBarsDone and job.hasActionProfile and CanUseCursor() then
        local ok, reason = ABP_LoadProfile(name, {quiet=true, phase="items"})
        if ok or (reason ~= "combat" and reason ~= "cursor") then job.itemBarsDone = true end
    end

    -- Update stats as soon as equipment settles, independently of a missing
    -- action profile/skillbook, which may remain pending for several seconds.
    if job.itemsDone and job.panelDone and not job.panelFinalDone then
        local panel = BCS and BCS.PropertiesPanel
        if panel and panel.initialized then
            if panel.RequestRefresh then panel:RequestRefresh() else panel:RefreshNow() end
        end
        job.panelFinalDone = true
    end

    if job.panelDone and job.itemsDone and job.barsDone and job.itemBarsDone then pendingSpecSwitch = nil end
end

local function OnTalentLoadComplete(slotIndex)
    ResetTalentSync(slotIndex)
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
    editFrame:SetHeight(500)
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

    local presetLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetLabel:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 110, -95)
    presetLabel:SetText("属性面板预设:")
    presetLabel:SetTextColor(1, 1, 1)
    local presetMenu = CreateFrame("Frame", "BrainwasherProPropertiesPresetMenu", editFrame, "UIDropDownMenuTemplate")
    presetMenu:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 94, -113)
    UIDropDownMenu_SetWidth(170, presetMenu)
    UIDropDownMenu_Initialize(presetMenu, function()
        for _, preset in ipairs(PROPERTY_PRESETS) do
            local selected = preset
            UIDropDownMenu_AddButton({
                text = selected,
                checked = (editFrame.propertiesPreset or "不切换") == selected,
                func = function()
                    editFrame.propertiesPreset = selected ~= "不切换" and selected or nil
                    UIDropDownMenu_SetText(selected, presetMenu)
                    CloseDropDownMenus()
                end,
            })
        end
    end)
    editFrame.presetMenu = presetMenu
    local presetHint = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    presetHint:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 22, -154)
    presetHint:SetText("切换天赋时应用；不切换则保留当前属性预设")
    presetHint:SetTextColor(0.75, 0.75, 0.75)
    
    local iconScrollBackground = CreateFrame("Frame", nil, editFrame)
    iconScrollBackground:SetPoint("TOPLEFT", editFrame, "TOPLEFT", 20, -178)
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
    editFrame.propertiesPreset = IsPropertyPreset(spec.propertiesPreset) and spec.propertiesPreset or nil
    UIDropDownMenu_SetText(editFrame.propertiesPreset or "不切换", editFrame.presetMenu)
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
    if spec then
        spec.name, spec.icon = editFrame.nameEdit:GetText(), editFrame.iconButton.iconTexture:GetTexture()
        spec.propertiesPreset = editFrame.propertiesPreset
        self:UpdateSpecDisplay(slotIndex)
        ResetTalentSync()
    end
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
        button.summary:SetText("点击图标加载天赋 · 属性：" .. (spec.propertiesPreset or "不切换"))
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
    ResetTalentSync(slotIndex)
    
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

            local boundSpec = BrainwasherProDB.specs[slotIndex]
            local propertyInfo = "\n\n属性面板预设: " .. (boundSpec and boundSpec.propertiesPreset or "不切换")
            
            textField:SetText("是否切换'" .. specName .. "'天赋?" .. actionBarInfo .. itemSetInfo .. propertyInfo)
        end
    end,
    OnAccept = function() 
        if BrainwasherPro.currentSlotAction and gossipSlots.load and gossipSlots.load[BrainwasherPro.currentSlotAction] then 
            local slotIndex = BrainwasherPro.currentSlotAction
            OnTalentLoadComplete(slotIndex)
            gossipSlots.load[slotIndex]:Click()
  
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
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "BrainwasherPro" then
        if not BrainwasherProDB then BrainwasherProDB = {specs = {}, style = "dark"} end
        if not BrainwasherProDB.specs then BrainwasherProDB.specs = {} end
        if not BrainwasherProDB.style then BrainwasherProDB.style = "dark" end
        BrainwasherPro.currentStyle = BrainwasherProDB.style
        BrainwasherPro:PopulateMacroIcons()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00地精洗脑装置已加载! 与洗脑装置交互以使用.|r")
        

        eventFrame:SetScript("OnUpdate", function()
            CheckAndSwitchPresets()
        end)
        
    elseif event == "GOSSIP_SHOW" then BrainwasherPro:OnGossipShow()
    elseif event == "GOSSIP_CLOSED" then BrainwasherPro:OnGossipClosed() 
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 此事件也会在传送/进副本时触发；只在首次进入世界恢复预设。
        if not worldReady then
            worldReady = true
            ResetTalentSync()
        end
    elseif event == "SPELLS_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
        talentDirty = true
        spellRevision = spellRevision + 1
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        lastInventoryChange = GetTime()
    elseif event == "BAG_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
        if pendingSpecSwitch then lastSwitchCheckTime = 0 end
    end
end)
