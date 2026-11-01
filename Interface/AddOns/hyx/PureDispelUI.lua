-- PureDispel / 净界驱散: personal modifications maintained by StoneChyi & Codex.
-- Original hyx authorship and original licenses are retained.
-- WoW 1.12 / Lua 5.0: all text starts with a built-in font template.
local D = XinDispel
local U = { regions = {}, fonts = {}, styled = {}, ignoredNames = {}, managerOffset = 0, ruleOffset = 0 }
PureDispelUI = U
D.UI = U
local ROWS = 10
local floor, min, max = math.floor, math.min, math.max
local classes = { "WARRIOR", "ROGUE", "PRIEST", "DRUID", "PALADIN", "HUNTER", "MAGE", "WARLOCK", "SHAMAN" }
local classNames = { "战士", "盗贼", "牧师", "小德", "骑士", "猎人", "法师", "术士", "萨满" }
local defaults = { width = 290, height = 0, rowHeight = 34, maxInRange = 6, maxOutRange = 3, backgroundAlpha = .75, borderAlpha = .85, fontSize = 12 }

local function Config(key)
    if xinDB and xinDB[key] ~= nil then return xinDB[key] end
    return defaults[key]
end

local function Number(key, low, high)
    return max(low, min(high, tonumber(Config(key)) or defaults[key] or low))
end

local function PfUI()
    return pfUI and pfUI.api and pfUI_config and pfUI_config.appearance and pfUI_config.appearance.border
end

local function SetFont(text, size)
    -- Reset to a known, built-in FontObject before trying a configurable path.
    text:SetFontObject(GameFontHighlightSmall)
    local path
    if PfUI() and Config("followPfUI") ~= false then path = pfUI.font_default end
    local fontSize = size or Number("fontSize", 9, 18)
    if not size and PfUI() and Config("followPfUI") ~= false and pfUI_config.global then
        fontSize = tonumber(pfUI_config.global.font_size) or fontSize
    end
    if path then
        local ok, result = pcall(text.SetFont, text, path, fontSize, "OUTLINE")
        if ok and result then return end
    end
    local pathDefault = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local ok, result = pcall(text.SetFont, text, pathDefault, fontSize, "OUTLINE")
    if not ok or not result then text:SetFontObject(GameFontHighlightSmall) end
end

local function Text(parent, value, size)
    local t = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.pdSize = size
    SetFont(t, size)
    t:SetJustifyH("LEFT")
    if value ~= nil then t:SetText(value) end
    table.insert(U.fonts, t)
    return t
end

local function Color(which)
    if PfUI() and pfUI.api.GetStringColor then
        local field = which == "background" and "background" or "color"
        return pfUI.api.GetStringColor(pfUI_config.appearance.border[field])
    end
    if which == "background" then return .025, .025, .025, 1 end
    return .22, .22, .22, 1
end

local function Backdrop(frame, popup)
    if not frame.pdSkinned then
        local ok
        if PfUI() and pfUI.api.CreateBackdrop then ok = pcall(pfUI.api.CreateBackdrop, frame, nil, true) end
        if not ok then
            frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        end
        frame.pdSkinned = true
        frame.pdPopup = popup
        table.insert(U.styled, frame)
    end
    local r, g, b = Color("background")
    frame:SetBackdropColor(r, g, b, popup and .96 or Number("backgroundAlpha", 0, 1))
    r, g, b = Color("border")
    frame:SetBackdropBorderColor(r, g, b, popup and .95 or Number("borderAlpha", 0, 1))
end

local function Button(parent, label, width, height, callback)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width or 60); b:SetHeight(height or 22)
    Backdrop(b, true)
    b.label = Text(b, label, 11)
    b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:RegisterForClicks("LeftButtonUp")
    if callback then b:SetScript("OnClick", callback) end
    b:SetScript("OnEnter", function()
        local _, class = UnitClass("player")
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        this:SetBackdropBorderColor(c and c.r or .8, c and c.g or .6, c and c.b or .8, 1)
    end)
    b:SetScript("OnLeave", function() Backdrop(this, true) end)
    return b
end

local function Edit(parent, name, width)
    local e = CreateFrame("EditBox", name, parent)
    e:SetWidth(width); e:SetHeight(22); e:SetAutoFocus(false)
    e:SetFontObject(GameFontHighlightSmall)
    if e.SetTextInsets then e:SetTextInsets(5, 5, 0, 0) end
    Backdrop(e, true)
    return e
end

local function Panel(name, title, width, height)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(width); frame:SetHeight(height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    Backdrop(frame, true)
    frame.title = Text(frame, title, 13)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
    frame.close = Button(frame, "×", 22, 20, function() this:GetParent():Hide() end)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    frame:Hide()
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
    return frame
end

local frame = CreateFrame("Frame", "PureDispelFrame", UIParent)
U.frame = frame
frame:SetPoint("TOPLEFT", UIParent, "CENTER", -145, 210)
frame:SetWidth(290); frame:SetHeight(440); frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(true); frame:SetMovable(true)
if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
Backdrop(frame)
local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0); header:SetHeight(30); header:SetWidth(290)
header:EnableMouse(true); header:RegisterForDrag("LeftButton")
header:SetScript("OnDragStart", function() if not xinDB or xinDB.locked ~= true then frame:StartMoving() end end)
header:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if xinDB then
        local point, relative, relativePoint, x, y = frame:GetPoint()
        xinDB.position = { point, relativePoint, x, y }
    end
end)
frame.title = Text(header, "净界驱散", 12)
frame.title:SetPoint("LEFT", header, "LEFT", 8, 0)
frame.close = Button(header, "×", 21, 20, function() D.SetListsVisible(false) end)
frame.close:SetPoint("RIGHT", header, "RIGHT", -6, 0)
frame.settings = Button(header, "设置", 32, 20, function() U.OpenSettings() end)
frame.settings:SetPoint("RIGHT", frame.close, "LEFT", -3, 0)
frame.manage = Button(header, "名单", 32, 20, function() U.OpenManager("current") end)
frame.manage:SetPoint("RIGHT", frame.settings, "LEFT", -3, 0)
frame.lock = Button(header, "锁定", 32, 20, function()
    xinDB.locked = not xinDB.locked
    frame.lock.label:SetText(xinDB.locked and "已锁" or "可移")
end)
frame.lock:SetPoint("RIGHT", frame.manage, "LEFT", -3, 0)

local function Snapshot(entry)
    if not entry or not entry.debuff then return nil end
    return { key = entry.key, name = entry.name, unit = entry.unit,
        aura = entry.debuff.name, type = entry.debuff.type, index = entry.debuff.index }
end

local function Matches(s, entry)
    return s and entry and entry.debuff and s.name == entry.name and s.unit == entry.unit
        and s.key == entry.key and s.aura == entry.debuff.name and s.type == entry.debuff.type
end

local function EntryFor(snapshot)
    if not snapshot then return nil end
    for _, key in ipairs({ "ready", "blocked" }) do
        for _, e in ipairs(D.entries[key]) do if Matches(snapshot, e) then return e end end
    end
end

local function MenuTargetValid(snapshot, fresh)
    if not snapshot or UnitName(snapshot.unit) ~= snapshot.name or not EntryFor(snapshot) then return false end
    if fresh then
        D.RefreshSpells()
        local aura = D.FindDebuff(snapshot.unit)
        if not aura or aura.name ~= snapshot.aura or aura.type ~= snapshot.type then return false end
        local policy = D.GetPolicy(snapshot.name)
        if policy == "ignore" then return false end
    end
    return true
end

local function Tooltip(row)
    if not row.entry then return end
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    if UnitName(row.entry.unit) == row.entry.name then GameTooltip:SetUnitDebuff(row.entry.unit, row.entry.debuff.index) end
    GameTooltip:AddLine("左键驱散 · 右键目标菜单 · 中键选中", 1, 1, 1)
    if Config("rightClickDispel") then GameTooltip:AddLine("右键也驱散；Shift+右键打开菜单", .7, .85, 1) end
    GameTooltip:AddLine("滚轮浏览本区；Shift+滚轮到首尾", .7, .85, 1)
    if row.entry.reason and row.entry.reason ~= "" then GameTooltip:AddLine(row.entry.reason, 1, .65, .4) end
    GameTooltip:Show()
end

local shortReasons = { ["距离过远"] = "超距", ["视野之外"] = "遮挡", ["冷却中"] = "冷却", ["法力不足"] = "缺蓝", ["距离未知"] = "距离未知", ["宠物不可用"] = "宠物不可用" }

local function CreateRegion(key, title)
    local region = CreateFrame("Frame", nil, frame)
    region.key, region.offset, region.rows = key, 0, {}
    region.head = Text(region, title, 11)
    region.head:SetPoint("TOPLEFT", region, "TOPLEFT", 6, -5)
    region.count = Text(region, "0 人", 10)
    region.count:SetPoint("TOPRIGHT", region, "TOPRIGHT", -8, -5)
    region.area = CreateFrame("Frame", nil, region)
    region.area:SetPoint("TOPLEFT", region, "TOPLEFT", 5, -23)
    region.area:EnableMouseWheel(true)
    region.page = Text(region, "0 / 0", 10)
    region.page:SetTextColor(.65, .65, .65)
    local function OnWheel()
        if U.menu and U.menu:IsShown() then U.menu:Hide() end
        if IsShiftKeyDown() then region.offset = arg1 > 0 and 0 or 999
        else region.offset = region.offset + (arg1 > 0 and -1 or 1) end
        U.RenderRegion(region)
        if xinDB then
            xinDB.offsets = xinDB.offsets or {}
            xinDB.offsets[key] = region.offset
        end
        GameTooltip:Hide()
    end
    region:EnableMouseWheel(true); region:SetScript("OnMouseWheel", OnWheel)
    region.area:SetScript("OnMouseWheel", OnWheel)
    region.up = Button(region, "↑", 19, 16, function() region.offset = region.offset - 1; U.RenderRegion(region) end)
    region.down = Button(region, "↓", 19, 16, function() region.offset = region.offset + 1; U.RenderRegion(region) end)
    region.rail = region:CreateTexture(nil, "BACKGROUND")
    region.rail:SetTexture(1, 1, 1, .08)
    region.thumb = region:CreateTexture(nil, "ARTWORK")
    region.thumb:SetTexture(.6, .6, .6, .6)
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, region.area)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(26); row.icon:SetHeight(26)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexCoord(.08, .92, .08, .92)
        row.name = Text(row, nil)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 35, -2)
        row.aura = Text(row, nil, 10)
        row.aura:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 35, 3)
        row.reason = Text(row, nil, 10)
        row.reason:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -2)
        row.reason:SetWidth(54); row.reason:SetHeight(13)
        row.reason:SetTextColor(.75, .69, .58)
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints(row); row.highlight:SetTexture(1, 1, 1, .055); row.highlight:Hide()
        row:EnableMouseWheel(true); row:SetScript("OnMouseWheel", OnWheel)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        row:SetScript("OnMouseDown", function() this.pressed = Snapshot(this.entry) end)
        row:SetScript("OnClick", function()
            local pressed = this.pressed
            this.pressed = nil
            if pressed and not Matches(pressed, this.entry) then return end
            local entry = this.entry
            if not entry or UnitName(entry.unit) ~= entry.name then return end
            if arg1 == "MiddleButton" then TargetUnit(entry.unit)
            elseif arg1 == "RightButton" and (not Config("rightClickDispel") or IsShiftKeyDown()) then U.OpenMenu(this)
            else
                if U.menu then U.menu:Hide() end
                local ok, reason = D.Cast(entry)
                if not ok and reason then D.Notify(reason) end
            end
        end)
        row:SetScript("OnEnter", function() this.highlight:Show(); Tooltip(this) end)
        row:SetScript("OnLeave", function() this.highlight:Hide(); GameTooltip:Hide() end)
        row:Hide(); region.rows[i] = row
    end
    U.regions[key] = region
    return region
end

CreateRegion("ready", "可驱散")
CreateRegion("blocked", "暂不可驱散")
U.frame.footer = CreateFrame("Frame", nil, frame)
U.frame.footer:SetHeight(28)
U.frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, 3)
U.frame.footer.ignored = Button(U.frame.footer, "已忽略 0", 78, 21, function() U.OpenManager("ignore") end)
U.frame.footer.ignored:SetPoint("LEFT", U.frame.footer, "LEFT", 0, 0)
U.frame.footer.undo = Button(U.frame.footer, "撤销上次操作", 98, 21, function()
    local ok, reason = D.Undo()
    if ok then D.Notify("已撤销上次名单操作") elseif reason then D.Notify(reason) end
    U.Render(true); if U.manager and U.manager:IsShown() then U.RefreshManager() end
end)
U.frame.footer.undo:SetPoint("RIGHT", U.frame.footer, "RIGHT", 0, 0)

function U.Layout()
    local width, rowHeight = Number("width", 180, 600), Number("rowHeight", 28, 44)
    local fontSize = Number("fontSize", 9, 18)
    if PfUI() and Config("followPfUI") ~= false and pfUI_config.global then fontSize = tonumber(pfUI_config.global.font_size) or fontSize end
    rowHeight = max(rowHeight, fontSize + 20)
    local screen = UIParent.GetHeight and UIParent:GetHeight() or 768
    if not screen or screen < 100 then screen = 768 end
    local chrome = 30 + 28 + 3 + 2 * (23 + 19)
    local minimumHeight = chrome + 2 * rowHeight
    local maximumHeight = max(minimumHeight, screen - 30)
    local requestedHeight = tonumber(Config("height")) or 0
    local customHeight = requestedHeight > 0
    local height = customHeight and max(minimumHeight, min(maximumHeight, min(900, requestedHeight))) or maximumHeight
    local budget = max(2, floor((height - chrome) / rowHeight))
    local a, b = floor(Number("maxInRange", 3, 10)), floor(Number("maxOutRange", 3, 10))
    local minimum = budget >= 6 and 3 or 1
    while a + b > budget do
        if a > b and a > minimum then a = a - 1
        elseif b > minimum then b = b - 1
        elseif a > minimum then a = a - 1 else break end
    end
    if not customHeight then height = chrome + (a + b) * rowHeight
    elseif xinDB then xinDB.height = height end
    local extra = max(0, height - chrome - (a + b) * rowHeight)
    local upperExtra = floor(extra * a / (a + b))
    local areas = { ready = a * rowHeight + upperExtra, blocked = b * rowHeight + extra - upperExtra }
    local total = 30 + 28
    frame:SetWidth(width); header:SetWidth(width); U.frame.footer:SetWidth(width - 10)
    local narrow = width < 250
    frame.title:SetText(narrow and "净界" or "净界驱散")
    frame.close:SetWidth(narrow and 20 or 21)
    frame.settings:SetWidth(narrow and 26 or 32)
    frame.manage:SetWidth(narrow and 26 or 32)
    frame.lock:SetWidth(narrow and 26 or 32)
    U.frame.footer.ignored:SetWidth(narrow and 70 or 78)
    U.frame.footer.undo:SetWidth(narrow and 86 or 98)
    for _, item in ipairs({ { "ready", a }, { "blocked", b } }) do
        local region, count = U.regions[item[1]], item[2]
        region.limit, region.rowHeight = count, rowHeight
        region:ClearAllPoints(); region:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -total + 28)
        local h = 23 + areas[item[1]] + 19
        region:SetWidth(width - 6); region:SetHeight(h)
        region.area:SetWidth(width - 20); region.area:SetHeight(areas[item[1]])
        region.page:ClearAllPoints(); region.page:SetPoint("TOPLEFT", region.area, "BOTTOMLEFT", 1, -2)
        region.down:ClearAllPoints(); region.down:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", -3, 1)
        region.up:ClearAllPoints(); region.up:SetPoint("RIGHT", region.down, "LEFT", -3, 0)
        region.rail:ClearAllPoints(); region.rail:SetPoint("TOPRIGHT", region.area, "TOPRIGHT", 4, 0)
        region.rail:SetWidth(2); region.rail:SetHeight(areas[item[1]])
        for i, row in ipairs(region.rows) do
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", region.area, "TOPLEFT", 0, -(i - 1) * rowHeight)
            row:SetWidth(width - 24); row:SetHeight(rowHeight)
            row.name:SetWidth(width - 65); row.name:SetHeight(fontSize + 2)
            row.aura:SetWidth(width - 64); row.aura:SetHeight(13)
        end
        total = total + h
    end
    frame:SetHeight(height)
end

function U.RenderRegion(region)
    local data = D.entries[region.key] or {}
    local total = table.getn(data)
    local count = region.limit or 3
    region.offset = max(0, min(region.offset, max(0, total - count)))
    local countText = total .. " 人"
    if region.countValue ~= countText then region.count:SetText(countText); region.countValue = countText end
    local page = total == 0 and "0 / 0" or ((region.offset + 1) .. "–" .. min(total, region.offset + count) .. " / " .. total)
    if region.pageValue ~= page then region.page:SetText(page); region.pageValue = page end
    for i, row in ipairs(region.rows) do
        local e = i <= count and data[region.offset + i] or nil
        if e then
            local policy = D.GetPolicy(e.name)
            local name = (policy == "priority" and "|cffe4c26b★|r " or "") .. e.name
            local reason = shortReasons[e.reason] or e.reason or ""
            local cache = table.concat({ tostring(e.key), e.name, e.unit, e.debuff.name or "", e.debuff.type or "", tostring(e.debuff.index), tostring(e.debuff.texture), reason, policy or "normal", e.class or "" }, "\001")
            row.entry = e
            if row.displayKey ~= cache then
                row.name:SetWidth(row:GetWidth() - 35 - (reason ~= "" and 60 or 6))
                row.name:SetText(name)
                local c = D.ClassColors and D.ClassColors[e.class]
                row.name:SetTextColor(c and c.r or 1, c and c.g or 1, c and c.b or 1)
                row.icon:SetTexture(e.debuff.texture)
                row.aura:SetText(e.debuff.name or "")
                local t = D.Types and D.Types[e.debuff.type]
                row.aura:SetTextColor(t and t.r or .7, t and t.g or .7, t and t.b or .7)
                row.reason:SetText(reason)
                row.displayKey = cache
                if GameTooltip:IsOwned(row) and GameTooltip:IsShown() then Tooltip(row) end
            end
            if not row:IsShown() then row:Show() end
        else
            if GameTooltip:IsOwned(row) then GameTooltip:Hide() end
            row.entry, row.displayKey = nil, nil
            if row:IsShown() then row:Hide() end
        end
    end
    region.topKey = data[region.offset + 1] and data[region.offset + 1].key or nil
    if total > count then
        local height = region.area:GetHeight()
        local thumbHeight = max(8, height * count / total)
        region.thumb:ClearAllPoints()
        region.thumb:SetPoint("TOPRIGHT", region.area, "TOPRIGHT", 4, -(height - thumbHeight) * region.offset / (total - count))
        region.thumb:SetWidth(2); region.thumb:SetHeight(thumbHeight)
        region.rail:Show(); region.thumb:Show()
    else region.rail:Hide(); region.thumb:Hide() end
end

function U.Render(force)
    if not D.ready then return end
    if not frame:IsShown() then return end
    for _, region in pairs(U.regions) do
        if region.offset > 0 and region.topKey then
            for i, e in ipairs(D.entries[region.key]) do
                if e.key == region.topKey then region.offset = i - 1; break end
            end
        end
        U.RenderRegion(region)
    end
    -- Counting ignored names must not rebuild the 40-person roster or allocate a
    -- rule-list table on each distance/visibility update.
    local unique, number = U.ignoredNames, 0
    for name in pairs(unique) do unique[name] = nil end
    for name, ignored in pairs(xinDB.BlackList or {}) do
        if ignored then unique[name] = true; number = number + 1 end
    end
    for name, state in pairs(xinDB.teamRules or {}) do
        if state == "ignore" and not unique[name] then unique[name] = true; number = number + 1 end
    end
    if U.ignoredCount ~= number then frame.footer.ignored.label:SetText("已忽略 " .. number); U.ignoredCount = number end
    if U.menu and U.menu:IsShown() and not MenuTargetValid(U.menu.snapshot) then U.menu:Hide() end
    if U.manager and U.manager:IsShown() then U.RefreshManager() end
end

function U.ApplyAppearance()
    for _, text in ipairs(U.fonts) do SetFont(text, text.pdSize) end
    for _, f in ipairs(U.styled) do f.pdSkinned = nil end
    -- Do not reinsert frames into the style registry while applying a new skin.
    local old = U.styled; U.styled = {}
    for _, f in ipairs(old) do Backdrop(f, f.pdPopup) end
    U.Layout()
    for _, region in pairs(U.regions) do for _, row in ipairs(region.rows) do row.displayKey = nil end end
    U.Render(true)
    if U.SyncSettings then U.SyncSettings() end
end

local function Feedback(message)
    if U.manager and U.manager:IsShown() and U.manager.feedback then U.manager.feedback:SetText(message or "")
    elseif U.settings and U.settings:IsShown() and U.settings.feedback then U.settings.feedback:SetText(message or "")
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff78c7b5净界驱散|r " .. (message or "")) end
end
D.Notify = Feedback

local function ApplyPolicy(name, state, scope)
    local ok, reason = D.SetPolicy(name, state, scope)
    if not ok then Feedback(reason or "无法修改此目标规则") else Feedback(name .. "：" .. (state == "priority" and "优先" or state == "ignore" and "忽略" or "普通") .. (scope == "longterm" and "（长期）" or "（本队）")) end
    U.Render(true)
    return ok
end

function U.OpenMenu(row)
    local snapshot = Snapshot(row.entry)
    if not MenuTargetValid(snapshot, true) then return end
    if not U.menu then
        local menu = Panel("PureDispelTargetMenu", "", 220, 204)
        menu:SetFrameStrata("TOOLTIP")
        -- One shared click-away surface; no per-row or per-frame polling.
        local blocker = CreateFrame("Button", "PureDispelMenuBlocker", UIParent)
        blocker:SetAllPoints(UIParent)
        blocker:SetFrameStrata("FULLSCREEN_DIALOG")
        blocker:EnableMouse(true)
        blocker:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        blocker:SetScript("OnClick", function() menu:Hide() end)
        blocker:Hide()
        menu.blocker = blocker
        menu:SetScript("OnHide", function() blocker:Hide() end)
        menu.buttons = {}
        for i = 1, 5 do
            local b = Button(menu, "", 204, 27)
            b:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -30 - (i - 1) * 32)
            b.label:SetJustifyH("LEFT"); b.label:ClearAllPoints(); b.label:SetPoint("LEFT", b, "LEFT", 5, 0)
            b.index = i
            b:SetScript("OnClick", function()
                local s = U.menu.snapshot
                if not MenuTargetValid(s, true) then U.menu:Hide(); return end
                local n = this.index
                U.menu:Hide()
                if n == 1 then
                    local policy, scope = D.GetPolicy(s.name)
                    if policy == "priority" and scope == "team" then D.ClearPolicy(s.name, "team")
                    else ApplyPolicy(s.name, "priority", "team") end
                elseif n == 2 then ApplyPolicy(s.name, "ignore", "team")
                elseif n == 3 then D.ClearPolicy(s.name, "team")
                elseif n == 4 then U.OpenRules(s.aura)
                else U.OpenManager("current", s.name) end
                U.Render(true)
            end)
            menu.buttons[i] = b
        end
        U.menu = menu
    end
    U.menu.snapshot = snapshot
    U.menu.title:SetText(snapshot.name)
    local policy, scope = D.GetPolicy(snapshot.name)
    U.menu.buttons[1].label:SetText(policy == "priority" and scope == "team" and "取消本队优先" or "设为本队优先")
    U.menu.buttons[2].label:SetText("本次队伍忽略此人")
    U.menu.buttons[3].label:SetText("清除本队规则")
    U.menu.buttons[4].label:SetText("当前减益规则…")
    U.menu.buttons[5].label:SetText("管理名单…")
    U.menu:ClearAllPoints(); U.menu:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -2)
    U.menu.blocker:Show()
    U.menu:Show(); GameTooltip:Hide()
end

-- Stable compatibility entry point used by the chat-bar shortcut. Its controls
-- are constructed on first open, not on every login.
XinSettingFrame = Panel("XinSettingFrame", "净界驱散 · 设置", 350, 500)
U.settings = XinSettingFrame

local function Slider(parent, title, key, low, high, step, y, percent)
    local label = Text(parent, "", 11)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, y)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetWidth(300); slider:SetHeight(14)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -7)
    slider:SetMinMaxValues(low, high); slider:SetValueStep(step)
    slider:SetOrientation("HORIZONTAL")
    Backdrop(slider, true)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetScript("OnValueChanged", function()
        if U.syncingSettings then return end
        local value = floor(this:GetValue() / step + .5) * step
        xinDB[key] = value
        if key == "maxInRange" or key == "maxOutRange" then xinDB.height = 0 end
        U.ApplyAppearance()
    end)
    slider.pdLabel, slider.pdTitle, slider.pdKey, slider.pdPercent = label, title, key, percent
    return slider
end

local function Toggle(parent, title, key, y)
    local button = Button(parent, "", 316, 22, function()
        xinDB[key] = not xinDB[key]
        this.label:SetText((xinDB[key] and "[开] " or "[关] ") .. title)
        U.ApplyAppearance()
    end)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, y)
    button.label:SetText((Config(key) and "[开] " or "[关] ") .. title)
    button.pdToggleKey, button.pdToggleTitle = key, title
    return button
end

function U.OpenSettings()
    XinSettingFrame:Show()
end

function U.ShowSettingsPage(page)
    local settings = U.settings
    settings.page = page
    for _, control in ipairs(settings.pageControls or {}) do
        if control.pdSettingsPage == page then control:Show() else control:Hide() end
    end
    for key, button in pairs(settings.pageButtons or {}) do
        button.label:SetTextColor(key == page and 1 or .65, key == page and 1 or .65, key == page and 1 or .65)
    end
end

function U.SyncSettings()
    local settings = U.settings
    if not settings or not settings.built then return end
    local previous = U.syncingSettings
    U.syncingSettings = true
    for _, s in ipairs(settings.sliders) do
        local v = Config(s.pdKey)
        if s.pdKey == "height" then v = frame:GetHeight() end
        s:SetValue(v)
        local suffix = s.pdKey == "height" and (tonumber(Config("height")) or 0) <= 0 and "（随行数）" or ""
        s.pdLabel:SetText(s.pdTitle .. ": " .. (s.pdPercent and floor(v * 100 + .5) .. "%" or tostring(v)) .. suffix)
    end
    settings.follow.label:SetText((Config("followPfUI") and "[开] " or "[关] ") .. settings.follow.pdToggleTitle)
    settings.compat.label:SetText((Config("rightClickDispel") and "[开] " or "[关] ") .. settings.compat.pdToggleTitle)
    U.syncingSettings = previous
end

XinSettingFrame:SetScript("OnShow", function()
    if not D.ready then D.Init() end
    if not this.built then
        this.built = true
        this.pageControls, this.pageButtons = {}, {}
        local function OnPage(control, page)
            control.pdSettingsPage = page
            table.insert(XinSettingFrame.pageControls, control)
            if control.pdLabel then
                control.pdLabel.pdSettingsPage = page
                table.insert(XinSettingFrame.pageControls, control.pdLabel)
            end
            return control
        end
        for i, item in ipairs({ { "layout", "布局" }, { "appearance", "外观" } }) do
            local page = item[1]
            local button = Button(this, item[2], 152, 23, function() U.ShowSettingsPage(page) end)
            button:SetPoint("TOPLEFT", this, "TOPLEFT", 15 + (i - 1) * 164, -40)
            this.pageButtons[page] = button
        end
        this.sliders = {
            OnPage(Slider(this, "可驱散显示行数", "maxInRange", 3, 10, 1, -81), "layout"),
            OnPage(Slider(this, "暂不可驱散显示行数", "maxOutRange", 3, 10, 1, -130), "layout"),
            OnPage(Slider(this, "窗口宽度", "width", 180, 600, 5, -179), "layout"),
            OnPage(Slider(this, "窗口高度", "height", 220, 900, 5, -228), "layout"),
            OnPage(Slider(this, "字体大小（自定义模式）", "fontSize", 9, 18, 1, -81), "appearance"),
            OnPage(Slider(this, "背景不透明度", "backgroundAlpha", 0, 1, .05, -130, true), "appearance"),
            OnPage(Slider(this, "边框不透明度", "borderAlpha", 0, 1, .05, -179, true), "appearance")
        }
        this.matchHeight = OnPage(Button(this, "按上下行数匹配高度", 316, 22, function()
            xinDB.height = 0; U.ApplyAppearance()
        end), "layout")
        this.matchHeight:SetPoint("TOPLEFT", this, "TOPLEFT", 15, -276)
        this.follow = OnPage(Toggle(this, "字体跟随 pfUI", "followPfUI", -228), "appearance")
        this.compat = Toggle(this, "右键也驱散（Shift+右键菜单）", "rightClickDispel", -315)
        this.lists = Button(this, "名单管理", 98, 23, function() U.OpenManager("current") end)
        this.lists:SetPoint("TOPLEFT", this, "TOPLEFT", 15, -350)
        this.rules = Button(this, "减益规则", 98, 23, function() U.OpenRules() end)
        this.rules:SetPoint("LEFT", this.lists, "RIGHT", 10, 0)
        this.raids = Button(this, "团本手册", 98, 23, function() U.OpenRaid() end)
        this.raids:SetPoint("LEFT", this.rules, "RIGHT", 10, 0)
        this.debug = Button(this, "调试 / 诊断", 316, 23, function()
            if U.OpenDebug then U.OpenDebug() else D.Notify("调试模块尚未加载，请重载界面") end
        end)
        this.debug:SetPoint("TOPLEFT", this, "TOPLEFT", 15, -383)
        this.feedback = Text(this, "", 10)
        this.feedback:SetPoint("TOPLEFT", this, "TOPLEFT", 15, -419); this.feedback:SetWidth(318)
        this.credit = Text(this, "原作：何雨欣 / hyx\n个人修改与维护：StoneChyi & Codex", 10)
        this.credit:SetPoint("BOTTOMLEFT", this, "BOTTOMLEFT", 15, 13)
        this.credit:SetTextColor(.6, .6, .6)
    end
    U.SyncSettings()
    U.ShowSettingsPage(this.page or "layout")
end)
XinSettingFrame:SetScript("OnHide", function()
    if U.menu then U.menu:Hide() end
    if U.manager then U.manager:Hide() end
    if U.rules then U.rules:Hide() end
    if U.raid then U.raid:Hide() end
    if U.debugPanel then U.debugPanel:Hide() end
end)

local policyText = { normal = "普通", priority = "优先", ignore = "忽略" }
local scopeText = { team = "本队", longterm = "长期", none = "" }

local function SelectedName()
    if not U.manager then return nil end
    local value = U.manager.nameEdit:GetText() or ""
    value = string.gsub(value, "^%s*(.-)%s*$", "%1")
    if value == "" then Feedback("请先选择队员或输入姓名"); return nil end
    return value
end

function U.RefreshManager()
    local manager = U.manager
    if not manager or not manager:IsShown() then return end
    local data = {}
    if manager.kind == "current" then
        for _, member in ipairs(D.GetRoster()) do
            local state, scope = D.GetPolicy(member.name)
            table.insert(data, { name = member.name, state = state, scope = scope, current = true })
        end
    else
        for _, rule in ipairs(D.ListPolicies(manager.kind)) do table.insert(data, rule) end
    end
    table.sort(data, function(a, b)
        if a.name == b.name then return tostring(a.scope) < tostring(b.scope) end
        return a.name < b.name
    end)
    manager.offset = max(0, min(manager.offset or 0, max(0, table.getn(data) - 10)))
    for i, row in ipairs(manager.rows) do
        local item = data[manager.offset + i]
        row.item = item
        if item then
            row.name:SetText(item.name)
            row.state:SetText((policyText[item.state] or "普通") .. " · " .. (scopeText[item.scope] or "") .. (item.current == false and " · 离队" or ""))
            if manager.kind == "ignore" then row.restore:Show() else row.restore:Hide() end
            row:Show()
        else row:Hide() end
    end
    manager.page:SetText(table.getn(data) == 0 and "暂无目标" or ((manager.offset + 1) .. "–" .. min(table.getn(data), manager.offset + 10) .. " / " .. table.getn(data)))
    for key, b in pairs(manager.tabs) do
        b.label:SetTextColor(key == manager.kind and 1 or .65, key == manager.kind and 1 or .65, key == manager.kind and 1 or .65)
    end
    manager.scope.label:SetText("作用范围：" .. (scopeText[manager.scopeValue] or "本队"))
end

function U.OpenManager(kind, name)
    if U.menu then U.menu:Hide() end
    if not U.manager then
        local manager = Panel("PureDispelManager", "净界驱散 · 名单管理", 420, 505)
        U.manager = manager
        XinListFrame = manager
        manager.kind, manager.scopeValue = "current", "team"
        manager.tabs, manager.rows = {}, {}
        for i, item in ipairs({ { "current", "当前队伍" }, { "priority", "优先名单" }, { "ignore", "忽略名单" } }) do
            local key = item[1]
            local b = Button(manager, item[2], 124, 23, function()
                manager.kind, manager.offset = key, 0
                U.RefreshManager()
            end)
            b:SetPoint("TOPLEFT", manager, "TOPLEFT", 15 + (i - 1) * 132, -39)
            manager.tabs[key] = b
        end
        for i = 1, 10 do
            local row = CreateFrame("Button", nil, manager)
            row:SetWidth(386); row:SetHeight(25)
            row:SetPoint("TOPLEFT", manager, "TOPLEFT", 17, -72 - (i - 1) * 26)
            row.name = Text(row, "", 11); row.name:SetPoint("LEFT", row, "LEFT", 3, 0); row.name:SetWidth(160)
            row.state = Text(row, "", 10); row.state:SetPoint("LEFT", row, "LEFT", 166, 0); row.state:SetTextColor(.7, .7, .7)
            row.restore = Button(row, "恢复", 47, 21, function()
                local item = this:GetParent().item
                if not item then return end
                local ok, reason = D.ClearPolicy(item.name, item.scope)
                if ok then
                    local state, scope = D.GetPolicy(item.name)
                    Feedback(item.name .. (state == "ignore" and "：仍由" .. (scopeText[scope] or "其他") .. "忽略规则控制" or "：已恢复显示"))
                else Feedback(reason or "无法恢复目标") end
                U.RefreshManager(); U.Render(true)
            end)
            row.restore:SetPoint("RIGHT", row, "RIGHT", -1, 0); row.restore:Hide()
            row:SetScript("OnClick", function()
                if not this.item then return end
                manager.nameEdit:SetText(this.item.name)
                manager.scopeValue = this.item.scope == "longterm" and "longterm" or "team"
                U.RefreshManager()
            end)
            row:RegisterForClicks("LeftButtonUp")
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function() manager.offset = (manager.offset or 0) + (arg1 > 0 and -1 or 1); U.RefreshManager() end)
            manager.rows[i] = row
        end
        manager:EnableMouseWheel(true)
        manager:SetScript("OnMouseWheel", function() this.offset = (this.offset or 0) + (arg1 > 0 and -1 or 1); U.RefreshManager() end)
        manager.page = Text(manager, "", 10); manager.page:SetPoint("TOPLEFT", manager, "TOPLEFT", 18, -338)
        manager.nameEdit = Edit(manager, "PureDispelManagerName", 210)
        manager.nameEdit:SetPoint("TOPLEFT", manager, "TOPLEFT", 17, -363)
        manager.scope = Button(manager, "作用范围：本队", 165, 22, function()
            manager.scopeValue = manager.scopeValue == "team" and "longterm" or "team"
            U.RefreshManager()
        end)
        manager.scope:SetPoint("LEFT", manager.nameEdit, "RIGHT", 10, 0)
        manager.hint = Text(manager, "选择队员或输入姓名；长期规则会跨队伍保留", 10)
        manager.hint:SetPoint("TOPLEFT", manager, "TOPLEFT", 17, -390); manager.hint:SetTextColor(.6, .6, .6)
        for i, item in ipairs({ { "priority", "设为优先" }, { "ignore", "忽略此人" }, { "clear", "清除此范围规则" }, { "undo", "撤销" } }) do
            local state = item[1]
            local b = Button(manager, item[2], i == 3 and 122 or 78, 23, function()
                if state == "undo" then
                    local ok, reason = D.Undo(); Feedback(ok and "已撤销上次名单操作" or reason or "没有可撤销的操作")
                else
                    local target = SelectedName()
                    if not target then return end
                    if state == "clear" then D.ClearPolicy(target, manager.scopeValue); Feedback(target .. "：已清除" .. scopeText[manager.scopeValue] .. "规则")
                    else ApplyPolicy(target, state, manager.scopeValue) end
                end
                U.RefreshManager(); U.Render(true)
            end)
            b:SetPoint("TOPLEFT", manager, "TOPLEFT", i == 1 and 17 or i == 2 and 101 or i == 3 and 185 or 313, -412)
        end
        manager.feedback = Text(manager, "", 10)
        manager.feedback:SetPoint("TOPLEFT", manager, "TOPLEFT", 17, -448); manager.feedback:SetWidth(386)
        manager.help = Text(manager, "本队规则同队重载保留，确认离队后清除。\n优先不会解除忽略，也不会绕过减益禁驱规则。", 10)
        manager.help:SetPoint("BOTTOMLEFT", manager, "BOTTOMLEFT", 17, 12); manager.help:SetTextColor(.6, .6, .6)
        manager:SetScript("OnShow", function() U.RefreshManager() end)
    end
    U.manager.kind = kind or "current"
    U.manager.offset = 0
    if name then U.manager.nameEdit:SetText(name) end
    U.manager:Show(); U.RefreshManager()
end

local function RuleLevel(name)
    if xinDB and xinDB.IgnoreList and xinDB.IgnoreList[name] then return xinDB.IgnoreList[name], "自定义" end
    if xinDB and xinDB.RaidSettings and xinDB.RaidSettings[name] then return xinDB.RaidSettings[name].ignoreType or 0, "团本" end
    return 0, "默认"
end

function U.RefreshRules()
    local rules = U.rules
    if not rules or not rules:IsShown() then return end
    local data = D.GetIgnoreRules()
    rules.offset = max(0, min(rules.offset or 0, max(0, table.getn(data) - 10)))
    for i, row in ipairs(rules.rows) do
        local item = data[rules.offset + i]
        row.item = item
        if item then
            row.name:SetText(item.name)
            local source = item.source == "custom" and "自定义" or item.source == "raid" and "团本" or item.source or "自定义"
            row.state:SetText((item.level == 2 and "整人跳过" or item.level == 1 and "不提示" or "职业规则") .. " · " .. source)
            row:Show()
        else row:Hide() end
    end
    rules.page:SetText(table.getn(data) == 0 and "暂无自定义规则" or ((rules.offset + 1) .. "–" .. min(table.getn(data), rules.offset + 10) .. " / " .. table.getn(data)))
    local level, source = RuleLevel(rules.nameEdit:GetText() or "")
    rules.source:SetText("当前：" .. (level == 2 and "有此减益时跳过整个人" or level == 1 and "不以此减益提示驱散" or "正常提示") .. "（" .. source .. "）")
end

function U.OpenRules(name)
    if U.menu then U.menu:Hide() end
    if not U.rules then
        local rules = Panel("PureDispelRules", "净界驱散 · 减益规则", 430, 530)
        U.rules = rules
        XinIgnoreFrame = rules
        rules.rows, rules.offset = {}, 0
        rules.nameEdit = Edit(rules, "PureDispelRuleName", 394)
        rules.nameEdit:SetPoint("TOPLEFT", rules, "TOPLEFT", 17, -40)
        rules.source = Text(rules, "", 10)
        rules.source:SetPoint("TOPLEFT", rules, "TOPLEFT", 18, -72); rules.source:SetWidth(394)
        for i, item in ipairs({ { 0, "移除自定义规则（保留团本规则）" }, { 1, "不以此减益提示驱散" }, { 2, "有此减益时跳过整个人" } }) do
            local level = item[1]
            local b = Button(rules, item[2], 394, 23, function()
                local value = rules.nameEdit:GetText() or ""
                value = string.gsub(value, "^%s*(.-)%s*$", "%1")
                if value == "" then Feedback("请选择减益或输入名字"); return end
                D.SetIgnoreRule(value, level)
                U.RefreshRules(); U.Render(true)
            end)
            b:SetPoint("TOPLEFT", rules, "TOPLEFT", 17, -96 - (i - 1) * 28)
        end
        rules.explain = Text(rules, "“不提示”只影响推荐，法术仍可能顺带移除它。\n“整人跳过”会阻止插件对带此减益的人施法。", 10)
        rules.explain:SetPoint("TOPLEFT", rules, "TOPLEFT", 18, -187); rules.explain:SetWidth(394); rules.explain:SetTextColor(.7, .7, .7)
        for i = 1, 10 do
            local row = CreateFrame("Button", nil, rules)
            row:SetWidth(394); row:SetHeight(24); row:SetPoint("TOPLEFT", rules, "TOPLEFT", 17, -232 - (i - 1) * 25)
            row.name = Text(row, "", 11); row.name:SetPoint("LEFT", row, "LEFT", 2, 0); row.name:SetWidth(235)
            row.state = Text(row, "", 10); row.state:SetPoint("RIGHT", row, "RIGHT", -2, 0); row.state:SetTextColor(.7, .7, .7)
            row:SetScript("OnClick", function() if this.item then rules.nameEdit:SetText(this.item.name); U.RefreshRules() end end)
            row:RegisterForClicks("LeftButtonUp"); row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function() rules.offset = rules.offset + (arg1 > 0 and -1 or 1); U.RefreshRules() end)
            rules.rows[i] = row
        end
        rules.page = Text(rules, "", 10); rules.page:SetPoint("BOTTOMLEFT", rules, "BOTTOMLEFT", 18, 25)
        rules.manual = Button(rules, "团本来源与职业规则…", 180, 22, function() U.OpenRaid() end)
        rules.manual:SetPoint("BOTTOMRIGHT", rules, "BOTTOMRIGHT", -17, 13)
        rules:SetScript("OnShow", function() U.RefreshRules() end)
    end
    if name then U.rules.nameEdit:SetText(name) end
    U.rules:Show(); U.RefreshRules()
end

local function CurrentRaidRule()
    if not U.raid or not U.raid.selected then return nil end
    local name = U.raid.selected.name
    xinDB.RaidSettings = xinDB.RaidSettings or {}
    xinDB.RaidSettings[name] = xinDB.RaidSettings[name] or {}
    return xinDB.RaidSettings[name]
end

function U.RefreshRaidDetail(item)
    local raid = U.raid
    if not raid then return end
    raid.selected = item
    raid.scrollOffset = 0
    raid.detailScroll:SetVerticalScroll(0)
    if not item then raid.detail:SetText("请选择左侧减益查看说明。"); return end
    local rule = xinDB.RaidSettings and xinDB.RaidSettings[item.name]
    local text = item.name .. "\n\n使用者：" .. (item.caster or "未知") .. "\n\n效果：\n" .. (item.effect or "") .. "\n\n注意事项：\n" .. (item.note or "无")
    raid.detail:SetText(text)
    local _, lines = string.gsub(text, "\n", "\n")
    local h = (floor(string.len(text) / 45) + lines + 3) * 14
    if type(raid.detail.GetStringHeight) == "function" then
        local ok, measured = pcall(raid.detail.GetStringHeight, raid.detail)
        if ok and type(measured) == "number" and measured > 0 then h = max(h, measured) end
    end
    raid.detailContent:SetHeight(max(260, h + 15))
    for i, b in ipairs(raid.classButtons) do
        local ignored = rule and rule.ignoreClasses and rule.ignoreClasses[classNames[i]]
        b.label:SetText((ignored and "[×] " or "[ ] ") .. classNames[i])
    end
    raid.ruleState:SetText("团本规则：" .. (rule and rule.ignoreType == 2 and "整人跳过" or rule and rule.ignoreType == 1 and "不提示" or "正常提示"))
end

function U.RefreshRaid()
    local raid = U.raid
    if not raid then return end
    local raidName = raid.names[raid.raidIndex]
    raid.selector.label:SetText(raidName or "没有团本数据")
    local data = raidName and XinRaidManualDB and XinRaidManualDB[raidName] or {}
    raid.offset = max(0, min(raid.offset or 0, max(0, table.getn(data) - 12)))
    for i, row in ipairs(raid.rows) do
        local item = data[raid.offset + i]
        row.item = item
        if item then row.label:SetText(item.name); row:Show() else row:Hide() end
    end
    raid.page:SetText(table.getn(data) == 0 and "暂无数据" or ((raid.offset + 1) .. "–" .. min(table.getn(data), raid.offset + 12) .. " / " .. table.getn(data)))
end

function U.OpenRaid()
    if not U.raid then
        local raid = Panel("PureDispelRaidManual", "净界驱散 · 团本手册", 660, 552)
        U.raid = raid
        XinRaidFrame = raid
        raid.names, raid.rows, raid.classButtons, raid.raidIndex, raid.offset = {}, {}, {}, 1, 0
        for name in pairs(XinRaidManualDB or {}) do table.insert(raid.names, name) end
        table.sort(raid.names)
        raid.selector = Button(raid, "", 175, 24, function()
            if not raid.picker then
                local picker = Panel("PureDispelRaidPicker", "选择团本", 230, 38 + table.getn(raid.names) * 27)
                raid.picker = picker
                picker.buttons = {}
                for i, name in ipairs(raid.names) do
                    local index = i
                    local b = Button(picker, name, 210, 23, function()
                        raid.raidIndex, raid.offset = index, 0
                        picker:Hide(); U.RefreshRaid(); U.RefreshRaidDetail(nil)
                    end)
                    b:SetPoint("TOPLEFT", picker, "TOPLEFT", 10, -30 - (i - 1) * 27)
                    picker.buttons[i] = b
                end
            end
            raid.picker:ClearAllPoints(); raid.picker:SetPoint("TOPLEFT", raid.selector, "BOTTOMLEFT", 0, -2)
            raid.picker:Show()
        end)
        raid.selector:SetPoint("TOPLEFT", raid, "TOPLEFT", 15, -40)
        raid.previous = Button(raid, "←", 27, 24, function()
            raid.raidIndex = raid.raidIndex - 1
            if raid.raidIndex < 1 then raid.raidIndex = max(1, table.getn(raid.names)) end
            raid.offset = 0; U.RefreshRaid(); U.RefreshRaidDetail(nil)
        end)
        raid.previous:SetPoint("LEFT", raid.selector, "RIGHT", 4, 0)
        for i = 1, 12 do
            local row = Button(raid, "", 204, 27, function() U.RefreshRaidDetail(this.item) end)
            row:SetPoint("TOPLEFT", raid, "TOPLEFT", 15, -77 - (i - 1) * 31)
            row.label:SetWidth(192); row.label:SetJustifyH("LEFT")
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function() raid.offset = raid.offset + (arg1 > 0 and -1 or 1); U.RefreshRaid() end)
            raid.rows[i] = row
        end
        raid.page = Text(raid, "", 10); raid.page:SetPoint("BOTTOMLEFT", raid, "BOTTOMLEFT", 18, 72)
        raid.detailScroll = CreateFrame("ScrollFrame", nil, raid)
        raid.detailScroll:SetPoint("TOPLEFT", raid, "TOPLEFT", 238, -41)
        raid.detailScroll:SetWidth(402); raid.detailScroll:SetHeight(270)
        raid.detailContent = CreateFrame("Frame", nil, raid.detailScroll)
        raid.detailContent:SetWidth(392); raid.detailContent:SetHeight(270)
        raid.detailScroll:SetScrollChild(raid.detailContent)
        raid.detail = Text(raid.detailContent, "请选择左侧减益查看说明。", 11)
        raid.detail:SetPoint("TOPLEFT", raid.detailContent, "TOPLEFT", 0, 0)
        raid.detail:SetWidth(390)
        if raid.detail.SetJustifyV then raid.detail:SetJustifyV("TOP") end
        raid.detailScroll:EnableMouseWheel(true)
        raid.detailScroll:SetScript("OnMouseWheel", function()
            raid.scrollOffset = max(0, min((raid.scrollOffset or 0) + (arg1 > 0 and -28 or 28), max(0, raid.detailContent:GetHeight() - 270)))
            raid.detailScroll:SetVerticalScroll(raid.scrollOffset)
        end)
        raid.ruleState = Text(raid, "团本规则：正常提示", 11)
        raid.ruleState:SetPoint("TOPLEFT", raid, "TOPLEFT", 238, -326)
        for i, item in ipairs({ { 0, "正常提示" }, { 1, "不提示" }, { 2, "整人跳过" } }) do
            local level = item[1]
            local b = Button(raid, item[2], 122, 23, function()
                local rule = CurrentRaidRule()
                if not rule then return end
                rule.ignoreType = level ~= 0 and level or nil
                D.MarkDirty(); U.RefreshRaidDetail(raid.selected); U.Render(true)
            end)
            b:SetPoint("TOPLEFT", raid, "TOPLEFT", 238 + (i - 1) * 132, -352)
        end
        raid.classTitle = Text(raid, "对此职业不以该减益提示：", 10)
        raid.classTitle:SetPoint("TOPLEFT", raid, "TOPLEFT", 238, -389)
        for i, name in ipairs(classNames) do
            local classIndex = i
            local b = Button(raid, "[ ] " .. name, 122, 22, function()
                local rule = CurrentRaidRule()
                if not rule then return end
                rule.ignoreClasses = rule.ignoreClasses or {}
                local key = classNames[classIndex]
                rule.ignoreClasses[key] = not rule.ignoreClasses[key] or nil
                D.MarkDirty(); U.RefreshRaidDetail(raid.selected); U.Render(true)
            end)
            b:SetPoint("TOPLEFT", raid, "TOPLEFT", 238 + math.mod(i - 1, 3) * 132, -412 - floor((i - 1) / 3) * 27)
            raid.classButtons[i] = b
        end
        raid.hint = Text(raid, "点团本名称选择副本；左右列表均可滚轮。\n手册为原作者参考资料，战术效果仍需按当前服务器确认。", 10)
        raid.hint:SetPoint("BOTTOMLEFT", raid, "BOTTOMLEFT", 17, 16); raid.hint:SetWidth(625); raid.hint:SetTextColor(.6, .6, .6)
        raid:SetScript("OnHide", function() if raid.picker then raid.picker:Hide() end end)
    end
    U.raid:Show(); U.RefreshRaid()
end

D.OnChanged = function(force) U.Render(force) end
D.OnVisibility = function(visible)
    if visible then frame:Show(); U.Render(true)
    else
        frame:Hide()
        if U.menu then U.menu:Hide() end
        GameTooltip:Hide()
    end
end
D.OnReady = function()
    U.ApplyAppearance()
    local position = xinDB.position
    if not position and xinDB.positions then position = xinDB.positions.XinMainFrame_InRange end
    if position and position[1] and position[2] and tonumber(position[3]) and tonumber(position[4]) then
        frame:ClearAllPoints(); frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    end
    for key, region in pairs(U.regions) do region.offset = xinDB.offsets and tonumber(xinDB.offsets[key]) or 0 end
    frame.lock.label:SetText(xinDB.locked and "已锁" or "可移")
    D.OnVisibility(xinDB.listsVisible ~= false)
end

SLASH_PUREDISPEL1 = "/puredispel"
SLASH_PUREDISPEL2 = "/pd"
SLASH_PUREDISPEL3 = "/xin"
SLASH_PUREDISPEL4 = "/hyx"
SLASH_PUREDISPEL5 = "/xinload"
SlashCmdList["PUREDISPEL"] = function(message)
    message = string.lower(string.gsub(message or "", "^%s*(.-)%s*$", "%1"))
    if message == "status" then D.Status()
    elseif message == "top" then
        for _, region in pairs(U.regions) do region.offset = 0; region.topKey = nil end
        U.Render(true)
    elseif message == "show" then D.SetListsVisible(true)
    elseif message == "hide" then D.SetListsVisible(false)
    elseif message == "toggle" then D.ToggleLists()
    elseif message == "debug" then if U.OpenDebug then U.OpenDebug() end
    else U.OpenSettings() end
end
SlashCmdList["XINLOAD"] = SlashCmdList["PUREDISPEL"]
U.CreatePanel, U.CreateText, U.CreateButton, U.CreateEdit, U.SetFont = Panel, Text, Button, Edit, SetFont
U.Layout()
if D.ready then D.OnReady() end
