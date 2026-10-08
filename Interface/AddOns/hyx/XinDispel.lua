-- hyx dispel engine: WoW 1.12 / Lua 5.0 compatible.
-- UI ideas from Decursive; implementation uses local 1.12 APIs, no retail code.
XinDispel = { spells = {}, ready = false, dirty = true }
local D = XinDispel
local types = { "Magic", "Curse", "Poison", "Disease" }
local colors = {
    Magic = { "魔法", 0.2, 0.6, 1 }, Curse = { "诅咒", 0.65, 0.2, 1 },
    Poison = { "中毒", 0, 0.8, 0 }, Disease = { "疾病", 0.8, 0.5, 0 }
}
local classNames = {
    WARRIOR = "战士", ROGUE = "盗贼", PRIEST = "牧师", DRUID = "小德",
    PALADIN = "骑士", HUNTER = "猎人", MAGE = "法师", WARLOCK = "术士", SHAMAN = "萨满"
}
local classColors = {
    MAGE = { .41, .80, .94 }, HUNTER = { .67, .83, .45 }, ROGUE = { 1, .96, .41 },
    WARRIOR = { .78, .61, .43 }, PRIEST = { 1, 1, 1 }, WARLOCK = { .58, .51, .79 },
    PALADIN = { .96, .55, .73 }, DRUID = { 1, .49, .04 }, SHAMAN = { 0, .44, .87 }
}
-- Each inner table is one spell, with names for supported client locales.
local cleanse = { "清洁术", "淨化術", "Cleanse" }
local purify = { "纯净术", "純淨術", "Purify" }
local curePoison = { "消毒术", "消毒術", "Cure Poison" }
local abolishPoison = { "驱毒术", "驅毒術", "Abolish Poison" }
local cureDisease = { "祛病术", "祛病術", "Cure Disease" }
local abolishDisease = { "驱除疾病", "驅除疾病", "Abolish Disease" }
local spellRules = {
    PALADIN = { Magic = { cleanse }, Poison = { cleanse, purify }, Disease = { cleanse, purify } },
    PRIEST = { Magic = { { "驱散魔法", "驅散魔法", "Dispel Magic" } }, Disease = { cureDisease, abolishDisease } },
    DRUID = { Curse = { { "解除诅咒", "解除詛咒", "Remove Curse" } }, Poison = { abolishPoison, curePoison } },
    MAGE = { Curse = { { "解除次级诅咒", "解除次級詛咒", "Remove Lesser Curse" } } },
    SHAMAN = { Poison = { curePoison }, Disease = { cureDisease } },
    WARLOCK = { Magic = { { "吞噬魔法", "Devour Magic" } } }
}
local scanner = CreateFrame("GameTooltip", "XinTooltipScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function Truth(value) return value ~= nil and value ~= false and value ~= 0 end
local function Say(message) DEFAULT_CHAT_FRAME:AddMessage("|cff80cfff欣|r " .. message) end
local function SafeXP(command, source, unit)
    if type(UnitXP) ~= "function" then return nil end
    local ok, value = pcall(UnitXP, command, source, unit)
    if ok then return value end
    return nil
end

function D.RefreshSpells()
    D.spells = {}
    local _, class = UnitClass("player")
    local rules = spellRules[class] or {}
    local pet = class == "WARLOCK"
    local book = pet and (BOOKTYPE_PET or "pet") or (BOOKTYPE_SPELL or "spell")
    if pet and (not UnitExists("pet") or UnitIsDeadOrGhost("pet")) then D.dirty = false; return end
    local known = {}
    -- Pet spell books must be scanned separately from player talent tabs.
    for slot = 1, 1024 do
        local name = GetSpellName(slot, book)
        if not name then break end
        known[name] = slot -- last slot is the highest learned rank
    end
    for dispelType, candidates in pairs(rules) do
        for _, names in ipairs(candidates) do
            for _, name in ipairs(names) do
                if known[name] then
                    D.spells[dispelType] = { name = name, slot = known[name], book = book, pet = pet, range = 30 }
                    break
                end
            end
            if D.spells[dispelType] then break end
        end
    end
    D.dirty = false
end

local function IgnoreLevel(name, unit)
    local db = xinDB or {}
    local level = db.IgnoreList and db.IgnoreList[name]
    if level and level ~= 0 then return level end
    local rule = db.RaidSettings and db.RaidSettings[name]
    if rule then
        local _, class = UnitClass(unit)
        if rule.ignoreClasses and rule.ignoreClasses[classNames[class]] then return 1 end
        return rule.ignoreType or 0
    end
    return 0
end

-- Examine every aura, even types this class cannot remove: a full-block rule
-- must keep the unit blocked after switching classes as well.
function D.FindDebuff(unit)
    local candidate
    for index = 1, 16 do
        local texture, stacks, dispelType = UnitDebuff(unit, index)
        if not texture then break end
        scanner:ClearLines()
        scanner:SetUnitDebuff(unit, index)
        local name = XinTooltipScannerTextLeft1:GetText() or "未知状态"
        local level = IgnoreLevel(name, unit)
        if level == 2 then return nil end
        if level ~= 1 and D.spells[dispelType] and not candidate then
            candidate = { index = index, texture = texture, stacks = stacks or 0,
                type = dispelType, name = name, spell = D.spells[dispelType] }
        end
    end
    return candidate
end

local function Eligible(unit)
    return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
        and UnitIsFriend("player", unit) and not UnitCanAttack("player", unit)
end

function D.Availability(unit, spell)
    local source = spell.pet and "pet" or "player"
    if spell.pet and (not UnitExists("pet") or UnitIsDeadOrGhost("pet")) then return false, "宠物不可用" end
    local inRange
    if UnitIsUnit(source, unit) then
        inRange = true
    elseif not spell.pet and type(IsSpellInRange) == "function" then
        local ok, result = pcall(IsSpellInRange, spell.name, unit)
        if ok and (result == 0 or result == 1) then inRange = result == 1 end
    end
    if inRange == nil then
        local distance = SafeXP("distanceBetween", source, unit)
        if type(distance) == "number" and distance >= 0 then inRange = distance <= spell.range end
    end
    if inRange == false then return false, "距离过远" end
    if not UnitIsUnit(source, unit) then
        local sight = SafeXP("inSight", source, unit)
        if sight ~= nil and not Truth(sight) then return false, "视野之外" end
    end
    if inRange == nil then return false, "距离未知" end
    if UnitIsDeadOrGhost("player") then return false, "你已死亡" end
    local start, duration, enabled = GetSpellCooldown(spell.slot, spell.book)
    if enabled == 0 then return false, "技能不可用" end
    -- Keep rows in place during the short global cooldown so rapid click/queue
    -- play does not empty and refill both lists after every successful cleanse.
    if start and duration and duration > 1.5 and start + duration > GetTime() then return false, "冷却中" end
    -- Optional Nampower API; stock 1.12 has no IsSpellUsable.
    if not spell.pet and type(IsSpellUsable) == "function" then
        local ok, usable, oom = pcall(IsSpellUsable, spell.name)
        if ok and Truth(oom) then return false, "法力不足" end
        if ok and usable ~= nil and not Truth(usable) then return false, "技能不可用" end
    end
    return true, ""
end

local function ViewLimit(anchor)
    local value = xinDB and xinDB[anchor.limitKey] or 5
    return math.max(3, math.min(10, math.floor(tonumber(value) or 5)))
end

function D.Render(anchor)
    local entries, limit = anchor.entries, ViewLimit(anchor)
    local total = table.getn(entries)
    anchor.offset = math.max(0, math.min(anchor.offset, math.max(0, total - limit)))
    for i = 1, 40 do
        local row, entry = anchor.rows[i], entries[anchor.offset + i]
        if i <= limit and entry then
            row.entry = entry
            row.targetUnit, row.debuffIndex = entry.unit, entry.debuff.index
            row.icon:SetTexture(entry.debuff.texture)
            local c = classColors[entry.class] or { 1, 1, 1 }
            row.playerName:SetTextColor(c[1], c[2], c[3])
            row.playerName:SetText(entry.name .. (entry.reason ~= "" and " |cffff6666(" .. entry.reason .. ")|r" or ""))
            local t = colors[entry.debuff.type]
            row.debuffName:SetText(entry.debuff.name .. "(" .. t[1] .. ")")
            row.debuffName:SetTextColor(t[2], t[3], t[4])
            row:SetAlpha(entry.available and 1 or .55)
            row:Show()
        else
            row.entry, row.targetUnit, row.debuffIndex = nil, nil, nil
            row:Hide()
        end
    end
    anchor.wheelArea:SetHeight(math.max(1, math.min(total, limit) * 32))
    if total > limit then
        anchor.pageText:SetText((anchor.offset + 1) .. "-" .. math.min(total, anchor.offset + limit) .. "/" .. total .. "  滚轮浏览")
        anchor.pageText:Show()
    else anchor.pageText:Hide() end
end

local function Scroll(anchor, delta)
    if not delta or delta == 0 then return end
    anchor.offset = anchor.offset + (delta > 0 and -1 or 1)
    D.Render(anchor)
    GameTooltip:Hide()
end

local function Tooltip(row)
    local entry = row.entry
    if not entry then return end
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    if UnitName(entry.unit) == entry.name then GameTooltip:SetUnitDebuff(entry.unit, entry.debuff.index) end
    GameTooltip:AddLine("左键/右键驱散：" .. entry.debuff.spell.name, 1, 1, 1)
    GameTooltip:AddLine("中键选中目标；滚轮浏览；Shift+滚轮回到首尾", .7, .8, 1)
    if entry.reason ~= "" then GameTooltip:AddLine(entry.reason, 1, .3, .3) end
    GameTooltip:Show()
end

function D.Click(row, button)
    local entry = row.entry
    local pressed = row.pressedEntry
    row.pressedEntry = nil
    if pressed and (not entry or pressed.name ~= entry.name or pressed.debuff.name ~= entry.debuff.name) then return end
    if not entry or UnitName(entry.unit) ~= entry.name or not Eligible(entry.unit) then return end
    if button == "MiddleButton" then TargetUnit(entry.unit); return end
    -- Recheck the actual unit, filters, spell book and aura at click time.
    D.RefreshSpells()
    if BlackList and BlackList[entry.name] then return end
    local aura = D.FindDebuff(entry.unit)
    if not aura or aura.name ~= entry.debuff.name or aura.type ~= entry.debuff.type then return end
    local available, reason = D.Availability(entry.unit, aura.spell)
    if not available then Say(reason); return end
    if SpellIsTargeting and SpellIsTargeting() then Say("请先完成或取消当前的选取目标操作"); return end
    if SUPERWOW_VERSION then
        CastSpellByName(aura.spell.name, entry.unit)
    else
        -- Stock 1.12 fallback. CastSpell's third argument suppresses auto-selfcast;
        -- explicitly resolve a targeting cursor before restoring the old target.
        local hadTarget = UnitExists("target")
        local sameTarget = UnitIsUnit("target", entry.unit)
        if not sameTarget then TargetUnit(entry.unit) end
        CastSpell(aura.spell.slot, aura.spell.book, false)
        if SpellIsTargeting and SpellIsTargeting() then
            SpellTargetUnit(entry.unit)
            if SpellIsTargeting() then SpellStopTargeting() end
        end
        if not sameTarget then
            if hadTarget then TargetLastTarget() else ClearTarget() end
        end
    end
end

local function CreateAnchor(name, title, x, limitKey)
    local anchor = CreateFrame("Frame", name, UIParent)
    anchor:SetWidth(200); anchor:SetHeight(24); anchor:SetPoint("CENTER", x, 0)
    anchor.limitKey, anchor.offset, anchor.entries, anchor.rows = limitKey, 0, {}, {}
    anchor:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16,
        edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    anchor.title = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    anchor.title:SetPoint("LEFT", anchor, "LEFT", 10, 0); anchor.title:SetText(title)
    anchor.title:SetTextColor(1, 1, 1)
    anchor.hideBtn = CreateFrame("Button", nil, anchor, "UIPanelButtonTemplate")
    anchor.hideBtn:SetWidth(40); anchor.hideBtn:SetHeight(18)
    anchor.hideBtn:SetPoint("RIGHT", anchor, "RIGHT", -4, 0); anchor.hideBtn:SetText("隐藏")
    anchor:SetMovable(true); anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function() this:StartMoving() end)
    anchor:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        if xinDB then
            local point, relative, relativePoint, px, py = this:GetPoint()
            xinDB.positions = xinDB.positions or {}
            xinDB.positions[this:GetName()] = { point, relativePoint, px, py }
        end
    end)
    function anchor:Lock()
        self:EnableMouse(false); self:SetBackdropColor(0, 0, 0, 0); self:SetBackdropBorderColor(0, 0, 0, 0)
        self.title:Hide(); self.hideBtn:Hide()
    end
    function anchor:Unlock()
        self:EnableMouse(true); self:SetBackdropColor(0, 0, 0, .8); self:SetBackdropBorderColor(.6, .6, .6, 1)
        self.title:Show(); self.hideBtn:Show()
    end
    anchor.hideBtn:SetScript("OnClick", function() anchor:Lock() end)
    -- Separate mouse surface keeps scrolling working when the anchor is locked.
    anchor.wheelArea = CreateFrame("Frame", nil, anchor)
    anchor.wheelArea:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 5, -2)
    anchor.wheelArea:SetWidth(240); anchor.wheelArea:SetHeight(1)
    anchor.wheelArea:EnableMouseWheel(true)
    local function OnWheel()
        if IsShiftKeyDown() then anchor.offset = arg1 > 0 and 0 or table.getn(anchor.entries); D.Render(anchor)
        else Scroll(anchor, arg1) end
        GameTooltip:Hide()
    end
    anchor.wheelArea:SetScript("OnMouseWheel", OnWheel)
    anchor:EnableMouseWheel(true); anchor:SetScript("OnMouseWheel", OnWheel)
    anchor.pageText = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    anchor.pageText:SetPoint("TOPLEFT", anchor.wheelArea, "BOTTOMLEFT", 0, -2)
    anchor.pageText:SetTextColor(.7, .8, 1); anchor.pageText:Hide()
    for i = 1, 40 do
        local row = CreateFrame("Button", nil, anchor.wheelArea)
        row:SetWidth(240); row:SetHeight(32)
        row:SetPoint("TOPLEFT", anchor.wheelArea, "TOPLEFT", 0, -(i - 1) * 32)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(28); row.icon:SetHeight(28); row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.playerName = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.playerName:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0); row.playerName:SetWidth(200)
        row.playerName:SetJustifyH("LEFT")
        row.debuffName = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.debuffName:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 2); row.debuffName:SetWidth(200)
        row.debuffName:SetJustifyH("LEFT")
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        row:SetScript("OnMouseDown", function() this.pressedEntry = this.entry end)
        row:SetScript("OnClick", function() D.Click(this, arg1) end)
        row:SetScript("OnEnter", function() Tooltip(this) end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:EnableMouseWheel(true); row:SetScript("OnMouseWheel", OnWheel)
        row:Hide(); anchor.rows[i] = row
    end
    anchor:Lock()
    return anchor, anchor.rows
end

XinMainFrame_InRange, XinRows_InRange = CreateAnchor("XinMainFrame_InRange", "锚点(可驱散)", -240, "maxInRange")
XinMainFrame_OutRange, XinRows_OutRange = CreateAnchor("XinMainFrame_OutRange", "锚点(不可驱散)", 20, "maxOutRange")

function D.SetListsVisible(visible)
    xinDB = xinDB or {}
    xinDB.listsVisible = visible and true or false
    for _, anchor in ipairs({ XinMainFrame_InRange, XinMainFrame_OutRange }) do
        if xinDB.listsVisible then anchor:Show() else anchor:Hide() end
    end
end

function D.ToggleLists()
    D.SetListsVisible(not (XinMainFrame_InRange:IsShown() or XinMainFrame_OutRange:IsShown()))
    if xinDB.listsVisible then UpdateXinList() end
end

local function Publish(anchor, entries)
    -- Preserve the top visible person when entries above disappear while scrolled.
    if anchor.offset > 0 then
        local old = anchor.entries[anchor.offset + 1]
        if old then
            for i, entry in ipairs(entries) do
                if entry.name == old.name then anchor.offset = i - 1; break end
            end
        end
    end
    anchor.entries = entries
    D.Render(anchor)
end

function UpdateXinList()
    if not D.ready then return end
    if D.dirty then D.RefreshSpells() end
    if not next(D.spells) then
        Publish(XinMainFrame_InRange, {})
        Publish(XinMainFrame_OutRange, {})
        return
    end
    local raw, ordered, priority, normal = {}, {}, {}, {}
    local raidCount, partyCount = GetNumRaidMembers(), GetNumPartyMembers()
    if raidCount > 0 then
        for i = 1, raidCount do table.insert(raw, "raid" .. i) end
    else
        table.insert(raw, "player")
        for i = 1, partyCount do table.insert(raw, "party" .. i) end
    end
    local selfUnit
    for _, unit in ipairs(raw) do
        local name = UnitName(unit)
        if name and not (BlackList and BlackList[name]) and Eligible(unit) then
            if UnitIsUnit("player", unit) then selfUnit = unit
            elseif PriorityList and PriorityList[name] then table.insert(priority, unit)
            else table.insert(normal, unit) end
        end
    end
    if selfUnit then table.insert(ordered, selfUnit) end
    for _, unit in ipairs(priority) do table.insert(ordered, unit) end
    for _, unit in ipairs(normal) do table.insert(ordered, unit) end
    local inEntries, outEntries = {}, {}
    for _, unit in ipairs(ordered) do
        local aura = D.FindDebuff(unit)
        if aura then
            local available, reason = D.Availability(unit, aura.spell)
            local _, class = UnitClass(unit)
            local entry = { unit = unit, name = UnitName(unit), class = class, debuff = aura, available = available, reason = reason }
            if available then table.insert(inEntries, entry)
            elseif xinDB.enableOutRange ~= false then table.insert(outEntries, entry) end
        end
    end
    Publish(XinMainFrame_InRange, inEntries)
    Publish(XinMainFrame_OutRange, outEntries)
end

local events = CreateFrame("Frame")
events:RegisterEvent("VARIABLES_LOADED"); events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("LEARNED_SPELL_IN_TAB"); events:RegisterEvent("UNIT_PET")
events:RegisterEvent("PET_BAR_UPDATE"); events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        xinDB = xinDB or {}
        xinDB.PriorityList = xinDB.PriorityList or {}; xinDB.BlackList = xinDB.BlackList or {}
        PriorityList, BlackList = xinDB.PriorityList, xinDB.BlackList
        for _, anchor in ipairs({ XinMainFrame_InRange, XinMainFrame_OutRange }) do
            local pos = xinDB.positions and xinDB.positions[anchor:GetName()]
            if pos then anchor:ClearAllPoints(); anchor:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) end
        end
        D.ready = true
        D.SetListsVisible(xinDB.listsVisible ~= false)
    elseif event == "PLAYER_LOGOUT" then
        if xinDB then xinDB.PriorityList, xinDB.BlackList = PriorityList, BlackList end
    end
    D.dirty = true
end)
local elapsed = 0
events:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed >= .25 then elapsed = 0; UpdateXinList() end
end)

function D.Status()
    D.RefreshSpells()
    local found = {}
    for _, dispelType in ipairs(types) do
        if D.spells[dispelType] then table.insert(found, colors[dispelType][1] .. "=" .. D.spells[dispelType].name) end
    end
    Say(table.getn(found) > 0 and table.concat(found, "，") or "当前角色/宠物没有已学习的友方驱散技能")
    Say("UnitXP接口=" .. (type(UnitXP) == "function" and "存在" or "未加载") ..
        "，定向施法=" .. (SUPERWOW_VERSION and "SuperWoW" or "原版选中后还原") ..
        "，两列支持滚轮浏览")
end
