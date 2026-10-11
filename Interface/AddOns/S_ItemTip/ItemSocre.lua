--由佚名基于Shagu装备评分插件修改 20250210
--别特鸣谢：天乖乖

local lib = LibStub("LibItem-enUS-1.0")
local libLevel = LibStub("LibItemLevel-1.0")
LibItem_Level = libLevel and libLevel.Item_Level or LibItem_Level or {}

-- One bounded, on-demand resolver shared by scores, links and inspection.
local nameCache, linkCache, scoreCache = {}, {}, {}
local nameSource, levelSource
local dataGeneration, scoreGeneration = 0, 0
local linkJobs, retryJobs = {}, {}
local pendingTooltip
local worker = CreateFrame("Frame")
local RETRY_DELAYS = {0.2, 0.5, 1}
local inspectReady = {}
-- The 1.12 vararg table retains nil holes and the return count.
local function PackReturns(...) return arg end

local function TrimCache(cache, limit)
    local count, oldest, oldestTime = 0
    for key, entry in pairs(cache) do
        count = count + 1
        if not oldestTime or entry.used < oldestTime then oldest, oldestTime = key, entry.used end
    end
    if count >= limit and oldest then cache[oldest] = nil end
end

local function ResetScores()
    scoreCache = {}
    scoreGeneration = scoreGeneration + 1
end

local function ResetAll()
    nameCache, linkCache, linkJobs, retryJobs, inspectReady = {}, {}, {}, {}, {}
    pendingTooltip = nil
    dataGeneration = dataGeneration + 1
    ResetScores()
    worker:SetScript("OnUpdate", nil)
end

local function CheckSources()
    local names = lib and lib.Item_enUS
    local levels = libLevel and libLevel.Item_Level or LibItem_Level or {}
    if names ~= nameSource or levels ~= levelSource then
        nameSource, levelSource = names, levels
        LibItem_Level = levels
        ResetAll()
    end
end

local function GetCandidates(name)
    CheckSources()
    if not name or name == "" then return {} end
    local now = GetTime()
    local cached = nameCache[name]
    if cached and (not cached.expires or now < cached.expires) then
        cached.used = now
        return cached.ids
    end
    local ids = {}
    if nameSource then
        for id, english in pairs(nameSource) do
            if english == name then table.insert(ids, id) end
        end
    end
    TrimCache(nameCache, 512)
    nameCache[name] = {ids=ids, used=now, expires=table.getn(ids) == 0 and now + 1 or nil}
    return ids
end

local function ResolveItem(name, rarity, equipSlot)
    local ids = GetCandidates(name)
    local possible = {}
    for _, id in ipairs(ids) do
        local matches = true
        if rarity or equipSlot then
            local _, _, quality, _, _, _, _, slot = GetItemInfo(id)
            if rarity and quality and quality ~= rarity then matches = false end
            if equipSlot and slot and slot ~= equipSlot then matches = false end
        end
        if matches then table.insert(possible, id) end
    end
    if table.getn(possible) == 1 then return possible[1], "unique" end
    if table.getn(possible) == 0 then return nil, "missing" end
    local common
    for _, id in ipairs(possible) do
        local level = LibItem_Level[id]
        if not level or level <= 0 then return nil, "ambiguous" end
        if common and level ~= common then return nil, "ambiguous" end
        common = level
    end
    return nil, "ambiguous", common
end

local function BuildItemLink(id)
    local name, link, quality = GetItemInfo(id)
    if not name or not link or not quality then return nil end
    local _, _, _, hex = GetItemQualityColor(quality)
    if not hex then return nil end
    return hex .. "|H" .. link .. "|h[" .. name .. "]|h|r"
end

local function CacheLink(name, id, status)
    TrimCache(linkCache, 256)
    linkCache[name] = {id=id, status=status, used=GetTime(), expires=not id and GetTime()+1 or nil}
end

local function SetScoreText(font, text)
    if not font then return end
    local path, size = font:GetFont()
    if not path or not size or size <= 0 then
        if GameFontNormal then font:SetFontObject(GameFontNormal)
        elseif not font:SetFont("Fonts\\FZXHLJW.TTF", 12) and not font:SetFont("Fonts\\FRIZQT__.TTF", 12) then return end
    end
    font:SetText(text or "")
end

local function StartWorker()
    worker:SetScript("OnUpdate", function()
        CheckSources()
        local now, budget = GetTime(), 256
        -- One shared budget, not 256 queries per request.
        for name, job in pairs(linkJobs) do
            if job.knownID then
                if now >= job.started + RETRY_DELAYS[job.attempt] and budget > 0 then
                    budget = budget - 1
                    local link = BuildItemLink(job.knownID)
                    job.attempt = job.attempt + 1
                    if link or job.attempt > table.getn(RETRY_DELAYS) then
                        CacheLink(name, link and job.knownID or nil, link and nil or "not-ready")
                        linkJobs[name] = nil
                        if pendingTooltip and pendingTooltip.name == name and ItemSocre.RefreshPendingTooltip then
                            ItemSocre:RefreshPendingTooltip()
                        end
                    end
                end
            else
            while budget > 0 and job.nextID <= 25818 do
                local id = job.nextID
                job.nextID = id + 1
                budget = budget - 1
                local itemName, link, quality = GetItemInfo(id)
                if itemName == name and link and quality then
                    if job.id and job.id ~= id then job.ambiguous = true; break end
                    job.id = id
                end
            end
            end
            if job.ambiguous or (job.nextID and job.nextID > 25818) then
                local id = not job.ambiguous and job.id or nil
                CacheLink(name, id, job.ambiguous and "ambiguous" or "missing")
                linkJobs[name] = nil
                if pendingTooltip and pendingTooltip.name == name and ItemSocre.RefreshPendingTooltip then
                    ItemSocre:RefreshPendingTooltip()
                end
            end
            if budget == 0 then break end
        end
        for key, job in pairs(retryJobs) do
            if UnitName(job.unit) ~= job.name or not UnitExists(job.unit) or not job.valid() then
                retryJobs[key] = nil
            elseif now >= job.started + RETRY_DELAYS[job.attempt] then
                local score, complete = ItemSocre:ScanUnit(job.unit, true)
                job.callback(score, complete)
                job.attempt = job.attempt + 1
                if complete or job.attempt > table.getn(RETRY_DELAYS) then retryJobs[key] = nil end
            end
        end
        if not next(linkJobs) and not next(retryJobs) then worker:SetScript("OnUpdate", nil) end
    end)
end

local function QueueLink(name, knownID)
    if linkJobs[name] then return end
    local count = 0
    for _ in pairs(linkJobs) do count = count + 1 end
    if count >= 8 then return end
    linkJobs[name] = knownID and {knownID=knownID, started=GetTime(), attempt=1} or {nextID=1}
    StartWorker()
end

-- Public methods are attached after the existing ItemSocre frame is created.
local function InstallCacheAPI(self)
    function self:InvalidateScores()
        ResetScores()
        inspectReady = {}
    end
    function self:InvalidateCaches()
        ResetAll()
    end
    function self:GetDataGeneration()
        CheckSources()
        return dataGeneration
    end
    function self:ResolveItemID(name, rarity, equipSlot)
        return ResolveItem(name, rarity, equipSlot)
    end
    function self:GetItemLevel(id, name, rarity, equipSlot)
        CheckSources()
        local level = LibItem_Level[tonumber(id)]
        if level and level > 0 then return level end
        local realID, status, common = ResolveItem(name, rarity, equipSlot)
        return realID and LibItem_Level[realID] or common or 0, status
    end
    function self:MarkInspectReady(unit)
        ResetScores()
        inspectReady[unit .. ":" .. tostring(UnitName(unit) or "")] = true
    end
    function self:ScheduleScoreRefresh(unit, key, callback, valid)
        local name = UnitName(unit)
        local old = retryJobs[key]
        if old and old.unit == unit and old.name == name then return end
        retryJobs[key] = {unit=unit, name=name, started=GetTime(), attempt=1, callback=callback, valid=valid}
        StartWorker()
    end
    function self:CancelTooltipRequest()
        pendingTooltip = nil
    end
    function self:TrackTooltipRequest(name, validate)
        local title = _G.GameTooltipTextLeft1
        pendingTooltip = {name=name, validate=validate, title=title and title:GetText(), owner=GameTooltip:GetOwner()}
    end
    CheckSources()
end

local function GetItemLinkByName(name, exactID)
    CheckSources()
    if not name or name == "" then return nil end
    if exactID then return BuildItemLink(exactID) end
    local now = GetTime()
    local cached = linkCache[name]
    if cached and (not cached.expires or now < cached.expires) then
        cached.used = now
        return cached.id and BuildItemLink(cached.id) or nil
    end
    local id, status = ResolveItem(name)
    if status == "ambiguous" then CacheLink(name, nil, status); return nil end
    if id then
        local link = BuildItemLink(id)
        if link then CacheLink(name, id); return link end
        CacheLink(name, nil, "not-ready")
        QueueLink(name, id)
        return nil
    end
    QueueLink(name)
    return nil
end

local USE_PFUI_STYLE = (pfUI and type(pfUI) == "table") or IsAddOnLoaded("pfUI")

local EquipSoltList = {
	INVTYPE_2HWEAPON,
	INVTYPE_BODY,
	INVTYPE_CHEST,
	INVTYPE_CLOAK,
	INVTYPE_FEET,
	INVTYPE_FINGER,
	INVTYPE_HAND,
	INVTYPE_HEAD,
	INVTYPE_HOLDABLE,
	INVTYPE_LEGS,
	INVTYPE_NECK,
	INVTYPE_RANGED,
	INVTYPE_RELIC,
	INVTYPE_ROBE,
	INVTYPE_SHIELD,
	INVTYPE_SHOULDER,
	INVTYPE_TABARD,
	INVTYPE_TRINKET,
	INVTYPE_WAIST,
	INVTYPE_WEAPON,
	INVTYPE_WEAPONMAINHAND,
	INVTYPE_WEAPONOFFHAND,
	INVTYPE_WRIST,
	"枪械",
	"弩",
	"魔杖",
	"投掷武器",
	"弹药",
}

-- 槽位类型集合：O(1) 查找替代逐条数组比对 by 武藤纯子酱 2026.10.8
local EQUIP_SLOT_SET = {}
for _, equip in pairs(EquipSoltList) do
	EQUIP_SLOT_SET[equip] = true
end

local function IsEquip(tooltip)
	tooltip = tooltip or (ItemRefTooltip:IsVisible() and ItemRefTooltip or GameTooltip)
	local name = tooltip:GetName()
	for i = 2, 5 do
		local line = _G[name .. "TextLeft" .. i]
		local text = line and line:GetText()
		if text and EQUIP_SLOT_SET[text] then
			return true
		end
	end
	return false
end

local function AddScoreLineOnce(tooltip, text)
    local owned = tooltip.sItemTipScoreLine
    if owned and tooltip.sItemTipScoreText == "" and owned:GetText() == "" then
        SetScoreText(owned, text)
        tooltip.sItemTipScoreText = text
        return
    end
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        local old = line and line:GetText()
        if old and string.find(old, "^装备等级") then
            if old == tooltip.sItemTipScoreText then SetScoreText(line, text); tooltip.sItemTipScoreText = text end
            return
        end
    end
    tooltip:AddLine(text, 1, 1, 0)
    tooltip.sItemTipScoreLine = _G[tooltip:GetName() .. "TextLeft" .. tooltip:NumLines()]
    tooltip.sItemTipScoreText = text
    tooltip:Show()
end

local function ClearOwnedScoreLine(tooltip)
    local line = tooltip.sItemTipScoreLine
    if line and line:GetText() == tooltip.sItemTipScoreText then
        SetScoreText(line, "")
        tooltip.sItemTipScoreText = ""
    end
end

local function Add_ItemLevelLine(itemID, itemLevel, tooltip)
    if not itemID or not itemLevel or itemLevel <= 0 then return end
    tooltip = tooltip or (ItemRefTooltip:IsVisible() and ItemRefTooltip or GameTooltip)
    if IsEquip(tooltip) then AddScoreLineOnce(tooltip, "装备等级 " .. itemLevel) end
end

local SLOT_COEFFICIENTS = {
	[1] = 1, [2] = 0.5625, [3] = 0.75, [5] = 1, [6] = 0.5625, [7] = 0.75,
	[8] = 0.75, [9] = 0.75, [10] = 0.75, [11] = 0.5625, [12] = 0.5625,
	[13] = 0.5625, [14] = 0.5625, [15] = 0.5625, [16] = 1, [17] = 1, [18] = 0.3164,
}

ItemSocre = CreateFrame("Frame" , "ItemSocreTooltip", GameTooltip)
ItemSocre:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
InstallCacheAPI(ItemSocre)

local function ShowUnitScore(tooltip, unit, force)
    local score, complete = ItemSocre:ScanUnit(unit, force)
    if score and score > 0 then AddScoreLineOnce(tooltip, "装备等级 " .. score) else ClearOwnedScoreLine(tooltip) end
    if not complete then
        ItemSocre:ScheduleScoreRefresh(unit, "tooltip", function(value)
            if value and value > 0 then AddScoreLineOnce(tooltip, "装备等级 " .. value) else ClearOwnedScoreLine(tooltip) end
        end, function() return tooltip:IsVisible() and tooltip.sItemTipUnit == unit end)
    end
end

ItemSocre:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        ItemSocre:InvalidateCaches()
    else
        ItemSocre:InvalidateScores()
    end
    if event == "UPDATE_MOUSEOVER_UNIT" and GameTooltip:IsVisible() and UnitExists("mouseover") and UnitIsPlayer("mouseover") then
        ItemSocre:CancelTooltipRequest()
        GameTooltip.sItemTipUnit = "mouseover"
        ShowUnitScore(GameTooltip, "mouseover", true)
    elseif GameTooltip:IsVisible() and GameTooltip.sItemTipUnit then
        ShowUnitScore(GameTooltip, GameTooltip.sItemTipUnit, true)
    end
end)
for _, ev in ipairs({"UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE"}) do
    ItemSocre:RegisterEvent(ev)
end

function ItemSocre:RefreshPendingTooltip()
    local request = pendingTooltip
    local title = _G.GameTooltipTextLeft1
    if not request or not GameTooltip:IsVisible() or GameTooltip:GetOwner() ~= request.owner
        or (title and title:GetText() ~= request.title) or not request.validate() then
        pendingTooltip = nil
        return
    end
    local link = GetItemLinkByName(request.name)
    if link then
        GameTooltip.itemLink = link
        local _, _, id = string.find(link, "item:(%d+)")
        local level = ItemSocre:GetItemLevel(id, request.name)
        Add_ItemLevelLine(id, level, GameTooltip)
        pendingTooltip = nil
    end
end

function S_ItemTip_ClearEngNameToItemID()
    ItemSocre:InvalidateCaches()
end

ItemSocre:SetScript("OnShow", function()
	if GameTooltip.itemLink then
		local _, _, itemID = string.find(GameTooltip.itemLink, "item:(%d+):%d+:%d+:%d+")
		local itemLevel = LibItem_Level[tonumber(itemID)] or 0
		Add_ItemLevelLine(itemID, itemLevel)
	end
end)

ItemSocre:SetScript("OnHide", function()
	GameTooltip.itemLink = nil
    GameTooltip.sItemTipUnit = nil
    ItemSocre:CancelTooltipRequest()
end)

hooksecurefunc("SetItemRef", function(link, button)
	if ItemRefTooltip:IsVisible() then
		local _, _, itemID = string.find(link, "item:(%d+):%d+:%d+:%d+")
		local itemLevel = LibItem_Level[tonumber(itemID)] or 0
		Add_ItemLevelLine(itemID, itemLevel)
	end
end)

local function UpdateSelfScore(force)
    local score, complete = ItemSocre:ScanUnit("player", force)
    SetScoreText(PlayerItemGS, score and ((USE_PFUI_STYLE and "装等: " or "装备等级: ") .. score) or "")
    if PlayerItemGS then PlayerItemGS:SetTextColor(1, 1, 0) end
    if not complete then
        ItemSocre:ScheduleScoreRefresh("player", "self", function(value)
            SetScoreText(PlayerItemGS, value and ((USE_PFUI_STYLE and "装等: " or "装备等级: ") .. value) or "")
        end, function() return PlayerItemGS and CharacterFrame and CharacterFrame:IsShown() end)
    end
end

if IsAddOnLoaded("StatCompare") and StatCompareSelfFrame then
    StatCompareSelfFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    StatCompareSelfFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    StatCompareSelfFrame:RegisterEvent("BAG_UPDATE")
    local previous = StatCompareSelfFrame:GetScript("OnEvent")
    StatCompareSelfFrame:SetScript("OnEvent", function()
        if previous then previous() end
        if event == "PLAYER_ENTERING_WORLD" then ItemSocre:InvalidateCaches() else ItemSocre:InvalidateScores() end
        UpdateSelfScore(true)
    end)
end

-- 增加AtlasLoot装备装等显示支持
if AtlasLootItem_OnEnter then
    local Hook_AtlasLootItem_OnEnter = AtlasLootItem_OnEnter
    AtlasLootItem_OnEnter = function()
        Hook_AtlasLootItem_OnEnter()
        local sid = this.itemID
        if sid == 0 then
            return
        end

        local st = string.sub(sid, 1, 1)
        local itemID = sid
        if st == "e" then
            return
        elseif st == "s" then
            if GetSpellInfoVanillaDB then
                itemID = GetSpellInfoVanillaDB["craftspells"][tonumber(string.sub(sid, 2))]["craftItem"]
            else
                return
            end
        end

        local tooltip = AtlasLootTooltip
        if st == "s" then
            tooltip = AtlasLootTooltip2
        end

        local itemName = GetItemInfo(itemID)
        local itemLevel = ItemSocre:GetItemLevel(itemID, itemName)

        if itemLevel > 0 then
            AddScoreLineOnce(tooltip, "装备等级 " .. itemLevel)
        end
    end
end

local ItemSocreHookInspectUnit = InspectUnit
local function UpdateInspectScore(unit)
    local score, complete = ItemSocre:ScanUnit(unit)
    if IsAddOnLoaded("StatCompare") then
        SetScoreText(TargetItemGS, score and ("装备等级 " .. score) or "")
        if TargetItemGS then TargetItemGS:SetTextColor(1, 1, 0) end
    end
    if not complete then
        ItemSocre:ScheduleScoreRefresh(unit, "inspect", function(value)
            if IsAddOnLoaded("StatCompare") then SetScoreText(TargetItemGS, value and ("装备等级 " .. value) or "") end
        end, function() return InspectFrame and InspectFrame:IsShown() and InspectFrame.unit == unit end)
    end
end
function InspectUnit(unit)
    ItemSocre:InvalidateScores()
    local result = PackReturns(ItemSocreHookInspectUnit(unit))
    if unit and UnitExists(unit) then UpdateInspectScore(unit) end
    return unpack(result, 1, result.n)
end

function ItemSocre:RefreshInspectScore(unit) UpdateInspectScore(unit) end

function ItemSocre:Calculate(rarity, ilvl)
	if not rarity then rarity = 0 end

	local qualityScale = 1
	if rarity == 5 then
		qualityScale = 1.3
	elseif rarity == 4 then
		qualityScale = 1.0
	elseif rarity == 3 then
		qualityScale = 0.85
	elseif rarity == 2 then
		qualityScale = 0.6
	elseif rarity == 1 then
		qualityScale = 0.25
	end

	return ilvl * qualityScale
end

function ItemSocre:ScanUnit(unit, force)
    CheckSources()
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return nil, true end
    local key = unit .. ":" .. tostring(UnitName(unit) or "")
    local now = GetTime()
    local cached = scoreCache[key]
    if not force and cached and cached.generation == scoreGeneration and now < cached.expires then
        cached.used = now
        return cached.value or nil, cached.complete
    end
    local score = 0
    local _, class = UnitClass(unit)
    local isHunter = class == "HUNTER"
    local complete = (UnitIsUnit and UnitIsUnit(unit, "player")) or inspectReady[key] or false
    for i = 1, 19 do
        if i ~= 4 and i ~= 19 then
            local link = GetInventoryItemLink(unit, i)
            if link then
                local _, _, id = string.find(link, "item:(%d+)")
                local name, rarity, equipSlot
                if id then
                    local unused
                    name, unused, rarity, unused, unused, unused, unused, equipSlot = GetItemInfo(tonumber(id))
                end
                local level = id and self:GetItemLevel(id, name, rarity, equipSlot) or 0
                if not name or rarity == nil or level <= 0 or (i == 16 and not equipSlot) then complete = false end
                local coef = SLOT_COEFFICIENTS[i] or 1
                if i == 16 then
                    coef = equipSlot == "INVTYPE_2HWEAPON" and (isHunter and 1 or 2.6836) or (isHunter and 0.5 or 1.6836)
                elseif i == 17 then coef = isHunter and 0.5 or 1
                elseif i == 18 then coef = isHunter and 2 or 0.3164 end
                score = score + self:Calculate(rarity, level) * coef
            end
        end
    end
    score = tonumber(string.format("%0.1f", (score / 17) * 1.355))
    local result = score ~= 0 and score or nil
    TrimCache(scoreCache, 128)
    scoreCache[key] = {value=result or false, complete=complete, generation=scoreGeneration, expires=now+(complete and 0.5 or 0.1), used=now}
    return result, complete
end

function ItemSocre:GetItemLinkByName(name, exactID)
    return GetItemLinkByName(name, exactID)
end

local HookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetContainerItemLink(container, slot)
	_, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
	-- SuperWoW：带充能物品（法力/巫师之油等）count 返回负的剩余充能，归一为正（与 ItemCount.lua 同口径）
	if GameTooltip.itemCount and GameTooltip.itemCount < 0 and SetAutoloot then GameTooltip.itemCount = -GameTooltip.itemCount end
	return HookSetBagItem(self, container, slot)
end

local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
function GameTooltip.SetQuestLogItem(self, itemType, index)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
	if not GameTooltip.itemLink then return end
	return HookSetQuestLogItem(self, itemType, index)
end

local HookSetQuestItem = GameTooltip.SetQuestItem
function GameTooltip.SetQuestItem(self, itemType, index)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetQuestItemLink(itemType, index)
	return HookSetQuestItem(self, itemType, index)
end

local HookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetLootSlotLink(slot)
	HookSetLootItem(self, slot)
end

local HookSetInboxItem = GameTooltip.SetInboxItem
function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
    local name = GetInboxItem(mailID)
    GameTooltip.itemLink = ItemSocre:GetItemLinkByName(name)
    local result = PackReturns(HookSetInboxItem(self, mailID, attachmentIndex))
    if name and not GameTooltip.itemLink then
        ItemSocre:TrackTooltipRequest(name, function() return GetInboxItem(mailID) == name end)
    end
    return unpack(result, 1, result.n)
end

local HookSetInventoryItem = GameTooltip.SetInventoryItem
function GameTooltip.SetInventoryItem(self, unit, slot)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
	return HookSetInventoryItem(self, unit, slot)
end

local HookSetLootRollItem = GameTooltip.SetLootRollItem
function GameTooltip.SetLootRollItem(self, id)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetLootRollItemLink(id)
	return HookSetLootRollItem(self, id)
end

local HookSetMerchantItem = GameTooltip.SetMerchantItem
function GameTooltip.SetMerchantItem(self, merchantIndex)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetMerchantItemLink(merchantIndex)
	return HookSetMerchantItem(self, merchantIndex)
end

local HookSetCraftItem = GameTooltip.SetCraftItem
function GameTooltip.SetCraftItem(self, skill, slot)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetCraftReagentItemLink(skill, slot)
	return HookSetCraftItem(self, skill, slot)
end

local HookSetCraftSpell = GameTooltip.SetCraftSpell
function GameTooltip.SetCraftSpell(self, slot)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetCraftItemLink(slot)
	return HookSetCraftSpell(self, slot)
end

local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	if reagentIndex then
		GameTooltip.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
	else
		GameTooltip.itemLink = GetTradeSkillItemLink(skillIndex)
	end
	return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
end

local HookSetAuctionItem = GameTooltip.SetAuctionItem
function GameTooltip.SetAuctionItem(self, atype, index)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
    local name, _, count = GetAuctionItemInfo(atype, index)
    if count and count < 0 and SetAutoloot then count = -count end
    GameTooltip.itemCount = count
    local exact = GetAuctionItemLink and GetAuctionItemLink(atype, index)
    local _, _, id = string.find(exact or "", "item:(%d+)")
    GameTooltip.itemLink = exact or ItemSocre:GetItemLinkByName(name, tonumber(id))
    local result = PackReturns(HookSetAuctionItem(self, atype, index))
    if name and not GameTooltip.itemLink then
        ItemSocre:TrackTooltipRequest(name, function() return GetAuctionItemInfo(atype, index) == name end)
    end
    return unpack(result, 1, result.n)
end

local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
function GameTooltip.SetAuctionSellItem(self)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
    local name, _, count = GetAuctionSellItemInfo()
    if count and count < 0 and SetAutoloot then count = -count end
    GameTooltip.itemCount = count
    GameTooltip.itemLink = ItemSocre:GetItemLinkByName(name)
    local result = PackReturns(HookSetAuctionSellItem(self))
    if name and not GameTooltip.itemLink then
        ItemSocre:TrackTooltipRequest(name, function() return GetAuctionSellItemInfo() == name end)
    end
    return unpack(result, 1, result.n)
end

local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
function GameTooltip.SetTradePlayerItem(self, index)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetTradePlayerItemLink(index)
	return HookSetTradePlayerItem(self, index)
end

local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
function GameTooltip.SetTradeTargetItem(self, index)
    ItemSocre:CancelTooltipRequest()
    GameTooltip.sItemTipUnit = nil
	GameTooltip.itemLink = GetTradeTargetItemLink(index)
	return HookSetTradeTargetItem(self, index)
end

if USE_PFUI_STYLE then
    local HookSetUnit = GameTooltip.SetUnit
    function GameTooltip.SetUnit(self, unit)
        ItemSocre:CancelTooltipRequest()
        self.sItemTipUnit = unit
        local result = PackReturns(HookSetUnit(self, unit))
        if unit and UnitExists(unit) and UnitIsPlayer(unit) then ShowUnitScore(self, unit) end
        return unpack(result, 1, result.n)
    end
end
