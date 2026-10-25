-- ============================================================
-- Cooline - 冷却计时条 + 走马灯（独立显隐控制）
-- ============================================================
cooline = CreateFrame('Button', nil, UIParent)
cooline:SetScript('OnEvent', function()
	this[event]()
end)
cooline:RegisterEvent('VARIABLES_LOADED')
cooline:EnableMouse(true)

cooline_settings = { x = 0, y = -240, flash_enabled = true, show_cooline = true }   -- 新增 show_cooline

local frame_pool = {}
local cooldowns = {}

-- Reviewed client categories / Turtle patch notes only; never infer groups
-- from equal timings alone. See PluginHistory/Research/Cooline-shared-cooldowns-20261012.md.
-- Ordered aliases supply a deterministic representative after reload.
local shared_groups = {
    {key = 'paladin_strikes', names = {'十字军打击', '神圣打击', 'Crusader Strike', 'Holy Strike'}},
    {key = 'paladin_immunity', names = {'圣盾术', '圣佑术', 'Divine Shield', 'Divine Protection'}},
    {key = 'warrior_reactions', names = {'压制', '复仇', 'Overpower', 'Revenge'}},
    {key = 'warrior_interrupts', names = {'拳击', '盾击', 'Pummel', 'Shield Bash'}},
    {key = 'warrior_major', names = {'盾墙', '鲁莽', '反击风暴', 'Shield Wall', 'Recklessness', 'Retaliation'}},
    {key = 'warrior_intercept', names = {'拦截', '援护', 'Intercept', 'Intervene'}},
    {key = 'warrior_attacks', names = {'致死打击', '嗜血', '盾牌猛击', 'Mortal Strike', 'Bloodthirst', 'Shield Slam'}},
    {key = 'hunter_cleave', names = {'多重射击', '切碎', 'Multi-Shot', 'Carve'}},
    {key = 'hunter_traps', names = {'冰冻陷阱', '冰霜陷阱', '献祭陷阱', '爆炸陷阱',
        'Freezing Trap', 'Frost Trap', 'Immolation Trap', 'Explosive Trap'}},
    {key = 'hunter_shots', names = {'奥术射击', '瞄准射击', 'Arcane Shot', 'Aimed Shot'}},
    {key = 'rogue_interrupts', names = {'脚踢', '致命投掷', 'Kick', 'Deadly Throw'}},
    {key = 'priest_prayers', names = {'绝望祷言', '太阳的拥抱', 'Desperate Prayer', "Sun's Embrace"}},
    {key = 'priest_racials', names = {'艾露恩的赐福', '回馈', "Elune's Grace", 'Feedback'}},
    {key = 'shaman_shocks', names = {'大地震击', '烈焰震击', '冰霜震击', 'Earth Shock', 'Flame Shock', 'Frost Shock'}},
    {key = 'shaman_strikes', names = {'风暴打击', '熔岩猛击', 'Stormstrike', 'Lava Lash'}},
    {key = 'mage_wards', names = {'防护火焰结界', '防护冰霜结界', 'Fire Ward', 'Frost Ward'}},
    {key = 'mage_instant', names = {'燃烧', '气定神闲', 'Combustion', 'Presence of Mind'}},
}
local shared_by_name, shared_casts = {}, {}
local item_catalog = cooline_shared_items or {}
local item_known, item_casts, item_use_spells = {}, {}, {}
for _, data in pairs(item_catalog) do item_use_spells[data[2]] = true end
local SHARED_EPS = 0.1
for _, group in ipairs(shared_groups) do
    for _, name in ipairs(group.names) do shared_by_name[name] = group end
end

local function shared_base_name(name)
    if type(name) ~= 'string' then return nil end
    local cut = string.find(name, '(', 1, true)
    local wide = string.find(name, '（', 1, true)
    if wide and (not cut or wide < cut) then cut = wide end
    return string.gsub(cut and string.sub(name, 1, cut - 1) or name, '%s+$', '')
end

function cooline.set_shown(shown)
	if shown or cooline.preview_enabled then
		cooline:Show()
		if cooline.on_update then cooline.on_update(true) end
	else
		cooline:Hide()
	end
end

-- Item links can be absent while slots are empty or item data is loading.
function cooline.hyperlink_name(link)
    if type(link) ~= 'string' then return nil end
    local _, _, name = string.find(link, '|h%[([^%]]+)%]|h')
    return name
end

function cooline.hyperlink_id(link)
    if type(link) ~= 'string' then return nil end
    local _, _, id = string.find(link, '|Hitem:(%d+)')
    return id and tonumber(id)
end

local function ignored(name)
    if type(name) ~= 'string' or name == '' then return true end
    for _, value in ipairs(cooline_ignore_list) do
        if string.upper(name) == string.upper(value) then return true end
    end
    return false
end

function cooline.start_cooldown(name, texture, start_time, duration, is_spell, record_name)
    if ignored(name) or type(start_time) ~= 'number' or type(duration) ~= 'number' then return end
    if duration <= 0 or start_time + duration <= GetTime() then return end
    local key = (is_spell and 'spell:' or 'item:') .. (record_name or name)
    local frame = cooldowns[key]
    if not frame then
        frame = tremove(frame_pool) or cooline.cooldown_frame()
        cooldowns[key] = frame
        frame.layout_lane = nil
        frame.crowded = false
        frame.end_time = nil
    end
    local end_time = start_time + duration
    if not frame.end_time or math.abs(frame.end_time - end_time) > 0.05 then
        frame.flashed = false
    end
    frame.name, frame.is_spell, frame.end_time = name, is_spell, end_time
    frame.scan_name, frame.start_time = record_name or name, start_time
    frame.shared_group, frame.shared_names, frame.shared_confirmed = nil, nil, nil
    frame.item_id, frame.item_members = nil, nil
    frame.icon:SetTexture(texture or 'Interface\\Icons\\INV_Misc_QuestionMark')
    frame:SetBackdropColor(unpack(is_spell and cooline_theme.spellcolor or cooline_theme.nospellcolor))
    return frame
end

function cooline.clear_cooldown(key)
    local frame = key and cooldowns[key]
    if not frame then return end
    if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    frame:Hide()
    frame.members = nil
    frame.shared_group, frame.shared_names, frame.shared_confirmed = nil, nil, nil
    frame.item_id, frame.item_members = nil, nil
    tinsert(frame_pool, frame)
    cooldowns[key] = nil
end

-- Reconcile a whole source at once: a ready duplicate/rank must not clear an
-- active cooldown with the same name. Spells and items have separate keys.
local function scan_record(records, seen, name, texture, start, duration, enabled, minimum)
    if ignored(name) then return end
    seen[name] = true
    if (enabled ~= nil and enabled ~= 1) or type(start) ~= 'number' or type(duration) ~= 'number' then return end
    if duration <= minimum or start + duration <= GetTime() then return end
    local old = records[name]
    if not old or start + duration > old.start + old.duration then
        records[name] = {texture = texture, start = start, duration = duration}
        return records[name]
    end
end

local function merge_shared_records(records, groups, is_spell)
    local prefix = is_spell and 'spell:' or 'item:'
    for _, group in ipairs(groups) do
        local cohorts = {}
        for _, name in ipairs(group.names) do
            local data = records[name]
            if data then
                local matching
                local ending = data.start + data.duration
                for _, cohort in ipairs(cohorts) do
                    if math.max(cohort.start_max, data.start) - math.min(cohort.start_min, data.start) <= SHARED_EPS and
                        math.max(cohort.duration_max, data.duration) - math.min(cohort.duration_min, data.duration) <= SHARED_EPS and
                        math.max(cohort.finish_max, ending) - math.min(cohort.finish_min, ending) <= SHARED_EPS then
                        matching = cohort
                        break
                    end
                end
                if not matching then
                    matching = {names = {}, start_min = data.start, start_max = data.start,
                        duration_min = data.duration, duration_max = data.duration,
                        finish_min = ending, finish_max = ending}
                    tinsert(cohorts, matching)
                end
                tinsert(matching.names, name)
                matching.start_min, matching.start_max = math.min(matching.start_min, data.start), math.max(matching.start_max, data.start)
                matching.duration_min, matching.duration_max = math.min(matching.duration_min, data.duration), math.max(matching.duration_max, data.duration)
                matching.finish_min, matching.finish_max = math.min(matching.finish_min, ending), math.max(matching.finish_max, ending)
            end
        end
        local merged = 0
        for _, cohort in ipairs(cohorts) do
          local names = cohort.names
          if table.getn(names) > 1 then
            local start, finish = cohort.start_max, cohort.finish_max
            -- Keep the original key for the first synchronized subset. A second
            -- subset (e.g. two pairs of traps) needs its own independent timer.
            local key = 'shared:' .. group.key .. (merged == 0 and '' or ':' .. names[1])
            merged = merged + 1
            local contains = {}
            for _, name in ipairs(names) do contains[name] = true end
            local old = cooldowns[prefix .. key]
            local current = old and old.shared_group == group.key and
                math.abs(old.start_time - start) <= SHARED_EPS and math.abs(old.end_time - finish) <= SHARED_EPS
            -- A surviving subset can move to the primary key when another
            -- subset disappears. Preserve this cycle's confirmed cast icon.
            if not current then
                for _, candidate in pairs(cooldowns) do
                    if candidate.is_spell == is_spell and candidate.shared_group == group.key and contains[candidate.name] and
                        math.abs(candidate.start_time - start) <= SHARED_EPS and
                        math.abs(candidate.end_time - finish) <= SHARED_EPS then
                        old, current = candidate, true
                        break
                    end
                end
            end
            local cast = shared_casts[group.key]
            if not is_spell then
                cast = nil
                for _, name in ipairs(names) do
                    local meta = item_catalog[records[name].item_id]
                    local at = meta and item_casts[meta[2]]
                    if at and math.abs(at - start) <= 0.5 and (not cast or at > cast.at) then
                        cast = {name = name, at = at}
                    end
                end
            end
            -- A confirmed success must belong to this cooldown, not a previous cast.
            local confirmed = cast and contains[cast.name] and math.abs(cast.at - start) <= 0.5
            local chosen = names[1]
            if current and old.shared_confirmed and contains[old.name] then
                chosen, confirmed = old.name, true
            elseif confirmed then
                chosen = cast.name
            elseif current and contains[old.name] then
                chosen = old.name
            end
            records[key] = {name = chosen, texture = records[chosen].texture, start = start,
                duration = finish - start, shared_group = group.key, shared_names = names,
                shared_confirmed = confirmed and true or false}
            if not is_spell then
                local members = {}
                for _, name in ipairs(names) do
                    local data = records[name]
                    tinsert(members, {name = name, texture = data.texture, item_id = data.item_id,
                        start = data.start, duration = data.duration})
                end
                records[key].item_members = members
                records[key].item_id = records[chosen].item_id
            end
            for _, name in ipairs(names) do records[name] = nil end
          end
        end
    end
end

local function replaced_shared_record(frame, records)
    local group = frame.is_spell and shared_by_name[frame.name]
    local item = not frame.is_spell and item_catalog[frame.item_id]
    local group_key = group and group.key or item and 'item_category_' .. item[1]
    if not group_key then return false end
    local previous = {}
    for _, name in ipairs(frame.shared_names or {frame.name}) do previous[name] = true end
    for name, data in pairs(records) do
        if previous[name] then return true end
        if data.shared_group == group_key then
            for _, member in ipairs(data.shared_names) do
                if previous[member] then return true end
            end
        end
    end
    return false
end

local function finish_scan(records, seen, is_spell, groups)
    merge_shared_records(records, is_spell and shared_groups or groups or {}, is_spell)
    for name, data in pairs(records) do
        local frame = cooline.start_cooldown(data.name or name, data.texture, data.start, data.duration, is_spell, name)
        if frame then
            frame.shared_group, frame.shared_names, frame.shared_confirmed = data.shared_group, data.shared_names, data.shared_confirmed
            frame.item_id, frame.item_members = data.item_id, data.item_members
        end
    end
    for key, frame in pairs(cooldowns) do
        if frame.is_spell == is_spell and not records[frame.scan_name] then
            -- Consumed/removed items keep their running timer. Natural expiry
            -- is handled by the animation driver, so completion can still flash.
            local present = seen[frame.name]
            for _, name in ipairs(frame.shared_names or {}) do present = present or seen[name] end
            if replaced_shared_record(frame, records) or
                ((is_spell or present) and frame.end_time > GetTime() + 0.05) then
                cooline.clear_cooldown(key)
            end
        end
    end
end

local function scan_item(records, seen, link, texture, start, duration, enabled)
    local name, id = cooline.hyperlink_name(link), cooline.hyperlink_id(link)
    if id and item_catalog[id] and not ignored(name) then
        item_known[id] = {name = name, texture = texture}
    end
    local data = scan_record(records, seen, name, texture, start, duration, enabled, 3)
    if data then data.item_id = id end
end

local function same_item_time(a, b)
    return math.abs(a.start - b.start) <= SHARED_EPS and
        math.abs(a.duration - b.duration) <= SHARED_EPS and
        math.abs(a.start + a.duration - b.start - b.duration) <= SHARED_EPS
end

local function item_groups(records, seen)
    -- Preserve an already observed consumed item's timer. For a shared timer,
    -- ready/reset surviving members invalidate the old missing-member snapshot.
    for _, frame in pairs(cooldowns) do
        if not frame.is_spell and item_catalog[frame.item_id] and frame.end_time > GetTime() then
            local members = frame.item_members or {{name = frame.name, item_id = frame.item_id,
                texture = frame.icon:GetTexture(), start = frame.start_time, duration = frame.end_time - frame.start_time}}
            local present, matching = false, false
            for _, member in ipairs(members) do
                present = present or seen[member.name]
                local data = records[member.name]
                if data and same_item_time(member, data) then matching = true end
            end
            if not frame.item_members or not present or matching then
                for _, member in ipairs(members) do
                    if not seen[member.name] and not records[member.name] then records[member.name] = member end
                end
            end
        end
    end
    -- An unambiguous player CAST can identify the last consumed item even if
    -- its slot is empty before the first cooldown scan. Require a live same-
    -- category timing sample; never invent a duration or treat a use attempt as success.
    local successful = {}
    for id, known in pairs(item_known) do
        local meta = item_catalog[id]
        local at = item_casts[meta[2]]
        if at and math.abs(GetTime() - at) <= 1 and meta[3] <= meta[4] then
            local previous = successful[meta[2]]
            successful[meta[2]] = previous == nil and id or false
        end
    end
    for spell, id in pairs(successful) do
        if id then
            local known, meta = item_known[id], item_catalog[id]
            if not seen[known.name] and not records[known.name] then
                local sample
                for _, data in pairs(records) do
                    local other = item_catalog[data.item_id]
                    if other and other[1] == meta[1] and data.duration <= meta[4] + SHARED_EPS and
                        math.abs(data.start - item_casts[spell]) <= 0.5 then
                        sample = data
                        break
                    end
                end
                if sample then
                    records[known.name] = {name = known.name, texture = known.texture, item_id = id,
                        start = sample.start, duration = sample.duration}
                end
            end
        end
    end
    local by_category, groups = {}, {}
    for name, data in pairs(records) do
        local meta = item_catalog[data.item_id]
        if meta then
            local group = by_category[meta[1]]
            if not group then
                group = {key = 'item_category_' .. meta[1], names = {}}
                by_category[meta[1]] = group
                tinsert(groups, group)
            end
            tinsert(group.names, name)
        end
    end
    for _, group in ipairs(groups) do
        table.sort(group.names, function(a, b)
            return records[a].item_id < records[b].item_id
        end)
    end
    return groups
end

function cooline.detect_item_cooldowns()
    local records, seen = {}, {}
    for bag = 0, 4 do
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local start, duration, enabled = GetContainerItemCooldown(bag, slot)
            scan_item(records, seen, GetContainerItemLink(bag, slot),
                GetContainerItemInfo(bag, slot), start, duration, enabled)
        end
    end
    for slot = 0, 19 do
        local start, duration, enabled = GetInventoryItemCooldown('player', slot)
        scan_item(records, seen, GetInventoryItemLink('player', slot),
            GetInventoryItemTexture('player', slot), start, duration, enabled)
    end
    finish_scan(records, seen, false, item_groups(records, seen))
end

function cooline.detect_spell_cooldowns()
    local records, seen = {}, {}
    local id = 1
    while true do
        local name = GetSpellName(id, BOOKTYPE_SPELL)
        if not name then break end
        local start, duration, enabled = GetSpellCooldown(id, BOOKTYPE_SPELL)
        scan_record(records, seen, name, GetSpellTexture(id, BOOKTYPE_SPELL), start, duration, enabled, 2.5)
        id = id + 1
    end
    finish_scan(records, seen, true)
end

function cooline.detect_cooldowns()
    cooline.detect_item_cooldowns()
    cooline.detect_spell_cooldowns()
    cooline.on_update(true)
end

local pending_spell, pending_item = nil, nil
cooline.rescan_timer = CreateFrame('Frame')
cooline.rescan_timer:Hide()
cooline.rescan_timer:SetScript('OnUpdate', function()
    local now, did = GetTime(), false
    if pending_spell and now >= pending_spell then
        pending_spell = nil
        cooline.detect_spell_cooldowns()
        did = true
    end
    if pending_item and now >= pending_item then
        pending_item = nil
        cooline.detect_item_cooldowns()
        did = true
    end
    if did then cooline.on_update(true) end
    if not pending_spell and not pending_item then cooline.rescan_timer:Hide() end
end)

function cooline.request_spell_rescan()
    pending_spell = pending_spell or GetTime() + 0.1
    cooline.rescan_timer:Show()
end
function cooline.request_item_rescan()
    pending_item = pending_item or GetTime() + 0.1
    cooline.rescan_timer:Show()
end

-- Independent of cast-history settings. CAST is success; START/FAIL and cast
-- function hooks must never select a representative for a shared cooldown.
function cooline.UNIT_CASTEVENT()
    if arg3 ~= 'CAST' or not arg4 or type(GetSpellNameAndRankForId) ~= 'function' then return end
    local _, player_guid = UnitExists('player')
    if not player_guid or arg1 ~= player_guid then return end
    if item_use_spells[arg4] then
        item_casts[arg4] = GetTime()
        cooline.request_item_rescan()
    end
    local name = shared_base_name(GetSpellNameAndRankForId(arg4))
    local group = name and shared_by_name[name]
    if not group then return end
    shared_casts[group.key] = {name = name, at = GetTime()}
    cooline.request_spell_rescan()
end

function cooline.begin_drag()
    if not IsShiftKeyDown() then return end
    cooline.dragging = true
    cooline:StartMoving()
end
function cooline.end_drag()
    cooline:StopMovingOrSizing()
    local x, y = cooline:GetCenter()
    local ux, uy = UIParent:GetCenter()
    cooline_settings.x, cooline_settings.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
    cooline.dragging = false
    cooline.refresh_dividers()
end

local function remaining_text(seconds)
    seconds = math.max(0, seconds)
    if seconds < 60 then return string.format('%.1f 秒', seconds) end
    return string.format('%d 分 %02d 秒', math.floor(seconds / 60), math.floor(math.mod(seconds, 60)))
end

function cooline.show_tooltip(frame)
    GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
    GameTooltip:ClearLines()
    for _, member in ipairs(frame.members or {frame}) do
        if member.shared_names then
            GameTooltip:AddDoubleLine('共享冷却', remaining_text(member.end_time - GetTime()), 1, 1, 1, 1, 0.82, 0)
            for _, name in ipairs(member.shared_names) do
                GameTooltip:AddDoubleLine(name, name == member.name and '当前图标' or '', 1, 1, 1, 1, 1, 1)
            end
        else
            GameTooltip:AddDoubleLine(member.name, remaining_text(member.end_time - GetTime()), 1, 1, 1, 1, 0.82, 0)
        end
    end
    GameTooltip:Show()
end

function cooline.cooldown_frame()
    local frame = CreateFrame('Button', nil, cooline)
    frame:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8'})
    frame.guide = frame:CreateTexture(nil, 'BACKGROUND')
    frame.guide:SetTexture(1, 1, 1, 0.25)
    frame.icon = frame:CreateTexture(nil, 'ARTWORK')
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.icon:SetPoint('TOPLEFT', 1, -1)
    frame.icon:SetPoint('BOTTOMRIGHT', -1, 1)
    frame.count = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.count:SetFont(cooline_theme.font, 9, 'OUTLINE')
    frame.count:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
    -- Even SetText('') needs a font in the 1.12 client. Initialize before any branch.
    frame.timer = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.timer:SetFont(cooline_theme.font, 9, 'OUTLINE')
    frame.timer:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.timer:SetTextColor(1, 1, 1, 1)
    frame.timer:SetShadowColor(0, 0, 0, 1)
    frame.timer:SetShadowOffset(1, -1)
    frame.timer:Hide()
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:RegisterForClicks('RightButtonUp')
    frame:SetScript('OnDragStart', cooline.begin_drag)
    frame:SetScript('OnDragStop', cooline.end_drag)
    frame:SetScript('OnClick', function()
        local callback = cooline:GetScript('OnClick')
        if callback then callback() end
    end)
    frame:SetScript('OnEnter', function() cooline.show_tooltip(this) end)
    frame:SetScript('OnLeave', function() GameTooltip:Hide() end)
    frame:Hide()
    return frame
end

function cooline.build_axis()
    local maximum = cooline_theme.max_time
    if maximum == 60 then
        cooline.axis_times = {0, 1, 3, 5, 10, 30, 60}
        cooline.axis_positions = {0, 0.12, 0.24, 0.38, 0.55, 0.78, 1}
    elseif maximum < 600 then
        cooline.axis_times = {0, 1, 3, 10, 30, 60, maximum}
        cooline.axis_positions = {0, 0.08, 0.17, 0.32, 0.5, 0.7, 1}
    else
        -- Keep the first three minutes identical for 10/15/30 minute modes.
        cooline.axis_times = {0, 3, 10, 30, 60, 180, maximum}
        cooline.axis_positions = {0, 0.17, 0.32, 0.5, 0.64, 0.83, 1}
    end
end

function cooline.time_position(seconds)
    local times, points = cooline.axis_times, cooline.axis_positions
    if seconds <= 0 then return 0 end
    for i = 2, table.getn(times) do
        if seconds <= times[i] then
            return cooline.length * (points[i-1] + (points[i] - points[i-1]) *
                (seconds - times[i-1]) / (times[i] - times[i-1]))
        end
    end
    return cooline.length
end

-- Only the perpendicular coordinate changes between rows; the time coordinate
-- always stays exact. Both rows and the optional guide stay centered on the bar.
function cooline.place(object, position, cross)
    cross = cross or 0
    if cooline_theme.reverse then position = cooline.length - position end
    object:ClearAllPoints()
    if cooline_theme.vertical then
        object:SetPoint('CENTER', cooline, 'BOTTOM', cross, position)
    else
        object:SetPoint('CENTER', cooline, 'LEFT', position, cross)
    end
end

local function compact_size()
    return math.max(12, math.floor(cooline.icon_size * 0.75))
end

-- 1.12 renders a 768-unit canvas. Convert through the actual frame scale,
-- then snap texture EDGES (not centers) to physical pixels, including reverse.
local divider_geometry = {}
function cooline.refresh_dividers(force)
    if not cooline.ticks then return end
    local x, y = cooline:GetCenter()
    if not x or not y then return end
    local _, _, height = string.find(GetCVar('gxResolution') or '', '^%d+x(%d+)$')
    height = tonumber(height) or 768
    if height <= 0 then height = 768 end
    local pixel = 768 / height / cooline:GetEffectiveScale()
    local width, thickness = cooline.length, cooline.thickness
    local vertical, reverse = cooline_theme.vertical, cooline_theme.reverse
    local old = divider_geometry
    if not force and old.x == x and old.y == y and old.pixel == pixel and
        old.width == width and old.thickness == thickness and
        old.vertical == vertical and old.reverse == reverse then return end
    old.x, old.y, old.pixel = x, y, pixel
    old.width, old.thickness, old.vertical, old.reverse = width, thickness, vertical, reverse
    local left, bottom = x - cooline_theme.width / 2, y - cooline_theme.height / 2
    local origin, cross_origin = vertical and bottom or left, vertical and left or bottom
    -- Entire pixels inside the background, even after fractional-position drags.
    local first = math.ceil(origin / pixel - 0.000001)
    local last = math.floor((origin + width) / pixel + 0.000001) - 1
    local cross_first = math.ceil(cross_origin / pixel - 0.000001) * pixel
    local cross_last = math.floor((cross_origin + thickness) / pixel + 0.000001) * pixel
    -- Two physical pixels of breathing room; keep at least one on thin bars.
    local inset = math.min(2, math.max(0, math.floor(((cross_last - cross_first) / pixel - 1) / 2 + 0.000001))) * pixel
    cross_first, cross_last = cross_first + inset, cross_last - inset
    for i, fs in ipairs(cooline.ticks) do
        local mark = cooline.tick_marks[i]
        if not mark then
            mark = cooline.overlay:CreateTexture(nil, 'BACKGROUND')
            cooline.tick_marks[i] = mark
        end
        mark:SetTexture(unpack(cooline_theme.tickcolor))
        local position = reverse and width - fs.axis_position or fs.axis_position
        local edge = math.floor((origin + position) / pixel)
        edge = math.max(first, math.min(last, edge))
        local along, cross = edge * pixel - origin, cross_first - cross_origin
        mark:SetWidth(vertical and cross_last - cross_first or pixel)
        mark:SetHeight(vertical and pixel or cross_last - cross_first)
        mark:ClearAllPoints()
        mark:SetPoint('BOTTOMLEFT', cooline, 'BOTTOMLEFT', vertical and cross or along, vertical and along or cross)
        mark:Show()
    end
end

function cooline.refresh_ticks()
    if not cooline.ticks then return end
    local size = compact_size()
    local rows = cooline_theme.layout == 'lanes' and cooline_theme.max_rows or 1
    local extent = math.max(cooline.thickness / 2, cooline.icon_size / 2,
        rows == 3 and size * 1.5 + 2 or (rows == 2 and size + 1 or size / 2))
    local height = cooline_theme.fontsize + 2
    -- Reserve the full footprint only for the separate cast-history default.
    -- Tick text itself always stays four pixels outside the actual bar edge.
    cooline.label_extent = math.max(extent, cooline.thickness / 2 + 4 + height)
    cooline.tick_marks = cooline.tick_marks or {}
    local last_edge = -1000
    for i, fs in ipairs(cooline.ticks) do
        local seconds = cooline.axis_times[i]
        local text = seconds == 0 and '0' or (seconds < 60 and tostring(seconds) .. 's' or tostring(seconds / 60) .. 'm')
        fs:SetFont(cooline_theme.font, cooline_theme.fontsize)
        fs:SetTextColor(unpack(cooline_theme.fontcolor))
        fs:SetText(text)
        fs:SetWidth(36)
        local width = math.ceil(fs:GetStringWidth()) + 2
        fs:SetWidth(width)
        fs:SetHeight(height)
        fs:SetJustifyH('CENTER')
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
        local position = cooline.time_position(seconds)
        local half_axis = (cooline_theme.vertical and height or width) / 2
        local half_cross = (cooline_theme.vertical and width or height) / 2
        local cross = cooline.thickness / 2 + 4 + half_cross
        if not cooline_theme.vertical then cross = -cross end
        cooline.place(fs, position, cross)
        fs.axis_position, fs.cross_position = position, cross
        fs.half_axis, fs.half_cross = half_axis, half_cross
        local endpoint = i == table.getn(cooline.ticks)
        local end_half = cooline_theme.vertical and height / 2 or 12
        fs.fits = endpoint or (position - half_axis >= last_edge + 4 and position + half_axis < cooline.length - end_half - 4)
        if fs.fits then
            fs:Show()
            last_edge = position + half_axis
        else
            fs:Hide()
        end
        fs.tick_alpha = fs.tick_alpha or 1
        fs:SetAlpha(fs.tick_alpha)
    end
    cooline.refresh_dividers(true)
end

-- Compare cached coordinates in bar space. Reversing the time axis preserves
-- distances; avoiding GetCenter here also keeps this work independent of scale.
function cooline.update_tick_collisions()
    if not cooline.ticks then return end
    local now = GetTime()
    for _, fs in ipairs(cooline.ticks) do
        local blocked = false
        local margin = fs.blocked and 3 or 1
        if fs.fits then
            for _, frame in ipairs(cooline.visible_icons or {}) do
                if frame.end_time > now - 0.85 and
                    math.abs(frame.axis_position - fs.axis_position) < frame.display_size / 2 + fs.half_axis + margin and
                    math.abs(frame.cross_position - fs.cross_position) < frame.display_size / 2 + fs.half_cross + margin then
                    blocked = true
                    break
                end
            end
        end
        fs.blocked = blocked
        fs.target_alpha = blocked and 0 or 1
    end
end

function cooline.animate_ticks(elapsed)
    if not cooline.ticks or type(elapsed) ~= 'number' then return end
    elapsed = math.max(0, elapsed)
    for _, fs in ipairs(cooline.ticks) do
        local target = fs.target_alpha or 1
        local alpha = fs.tick_alpha or 1
        if alpha ~= target then
            local step = elapsed / (target == 0 and 0.1 or 0.16)
            alpha = target == 0 and math.max(0, alpha - step) or math.min(1, alpha + step)
            fs.tick_alpha = alpha
            fs:SetAlpha(alpha)
        end
    end
end

local function position_frame(frame, position, cross, size, level)
    frame:SetWidth(size)
    frame:SetHeight(size)
    frame:SetFrameLevel(level)
    frame.axis_position, frame.cross_position, frame.display_size = position, cross, size
    tinsert(cooline.visible_icons, frame)
    cooline.place(frame, position, cross)
    frame.guide:ClearAllPoints()
    if cross == 0 then
        frame.guide:Hide()
    else
        if cooline_theme.vertical then
            frame.guide:SetWidth(math.abs(cross))
            frame.guide:SetHeight(1)
            frame.guide:SetPoint('CENTER', frame, 'CENTER', -cross / 2, 0)
        else
            frame.guide:SetWidth(1)
            frame.guide:SetHeight(math.abs(cross))
            frame.guide:SetPoint('CENTER', frame, 'CENTER', 0, -cross / 2)
        end
        frame.guide:Show()
    end
    local member_count = table.getn(frame.members)
    frame.count:SetText(member_count > 1 and '+' .. (member_count - 1) or '')
    local left = frame.end_time - GetTime()
    if cooline_theme.show_countdown and member_count == 1 and left > 0 and left <= 10 then
        frame.timer:SetFont(cooline_theme.font, math.max(8, math.min(12, math.floor(size * 0.65))), 'OUTLINE')
        frame.timer:SetWidth(size - 2)
        frame.timer:SetHeight(size - 2)
        frame.timer:SetText(tostring(math.ceil(left)))
        frame.timer:Show()
    else
        frame.timer:Hide()
        frame.timer:SetText('')
    end
    frame:Show()
end

local function layout_group(entries, first, last)
    local count = last - first + 1
    local crowded = count > 1 and cooline_theme.layout ~= 'overlap'
    local size = crowded and compact_size() or cooline.icon_size
    local rows = 1
    if crowded and cooline_theme.layout == 'lanes' then
        local left, peak = first, 1
        for i = first, last do
            while entries[i].position - entries[left].position >= size + 2 do left = left + 1 end
            peak = math.max(peak, i - left + 1)
        end
        rows = math.min(cooline_theme.max_rows, peak)
    end
    local lanes, placed = {}, {}
    for i = 1, rows do lanes[i] = {} end
    for i = first, last do
        local entry, lane = entries[i], nil
        local frame = entry.frame
        frame.crowded = crowded
        if cooline_theme.layout == 'overlap' then
            lane = 1
        else
            -- Try the previous lane first. Extra clearance when joining separate
            -- groups supplies hysteresis without moving icons along the axis.
            local preferred = frame.layout_lane
            for attempt = 0, rows do
                local candidate = attempt == 0 and preferred or attempt
                if candidate and candidate >= 1 and candidate <= rows then
                    local fits = true
                    for _, other in ipairs(lanes[candidate]) do
                        if math.abs(entry.position - other.position) < size + 2 then fits = false; break end
                    end
                    if fits then lane = candidate; break end
                end
            end
        end
        if lane then
            frame.layout_lane = lane
            frame.members = {frame}
            entry.lane = lane
            tinsert(lanes[lane], entry)
            tinsert(placed, entry)
        else
            -- Entries are processed soonest first. Overflow is attached to the
            -- nearest, least urgent representative; short timers stay visible.
            local representative, distance
            for _, other in ipairs(placed) do
                local delta = math.abs(other.position - entry.position)
                if not distance or delta <= distance then representative, distance = other, delta end
            end
            tinsert(representative.frame.members, frame)
            if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
            frame:Hide()
        end
    end
    for i, entry in ipairs(placed) do
        local cross = 0
        if rows == 2 then cross = (entry.lane == 1 and -0.5 or 0.5) * (size + 2) end
        if rows == 3 then cross = (entry.lane == 1 and 0 or (entry.lane == 2 and -1 or 1)) * (size + 2) end
        position_frame(entry.frame, entry.position, cross, size, cooline:GetFrameLevel() + 2 + last - first - i + 1)
        if GameTooltip:IsOwned(entry.frame) then cooline.show_tooltip(entry.frame) end
    end
end

function cooline.layout_icons(entries)
    cooline.visible_icons = {}
    local first = 1
    while first <= table.getn(entries) do
        local last = first
        while last < table.getn(entries) do
            local a, b = entries[last], entries[last+1]
            local margin = (a.frame.crowded or b.frame.crowded) and 6 or 2
            if b.position - a.position >= cooline.icon_size + margin then break end
            last = last + 1
        end
        layout_group(entries, first, last)
        first = last + 1
    end
end

-- Preview frames never enter the real cooldown registry or completion path.
function cooline.begin_preview()
    cooline.preview_enabled = true
    cooline.set_shown(true)
end

function cooline.end_preview()
    cooline.preview_enabled = false
    cooline.on_update(true)
    cooline.set_shown(cooline_settings.show_cooline)
end

local function preview_entries(now)
    cooline.preview_frames = cooline.preview_frames or {}
    local icons = {'Spell_Holy_HolyBolt', 'Spell_Holy_SealOfProtection', 'Spell_Holy_DevotionAura'}
    local entries = {}
    for i = 1, 3 do
        local frame = cooline.preview_frames[i]
        if not frame then
            frame = cooline.cooldown_frame()
            frame.name = '预览技能 ' .. i
            frame.is_spell = true
            frame.icon:SetTexture('Interface\\Icons\\' .. icons[i])
            cooline.preview_frames[i] = frame
        end
        frame.end_time = now + 8 + (i - 1) * 0.05
        frame:SetAlpha(1)
        frame:SetBackdropColor(unpack(cooline_theme.spellcolor))
        tinsert(entries, {frame = frame, key = 'preview:' .. i, position = cooline.time_position(frame.end_time - now)})
    end
    return entries
end

function cooline.show_flash(texture)
    if not cooline_settings.flash_enabled or not cooline.flash then return end
    if cooline.flash:IsVisible() and cooline.flash:GetScript('OnUpdate') then return end
    cooline.flash.texture:SetTexture(texture)
    cooline.flash:SetAlpha(0.75)
    cooline.flash:Show()
    local start = GetTime()
    cooline.flash:SetScript('OnUpdate', function()
        local elapsed = GetTime() - start
        if elapsed >= 0.8 then
            cooline.flash:Hide()
            cooline.flash:SetScript('OnUpdate', nil)
        else
            cooline.flash:SetAlpha(0.75 * (1 - elapsed / 0.8))
        end
    end)
end

local last_update, throttle = 0, 0
function cooline.on_update(force)
    if not cooline.axis_times then return end
    local now = GetTime()
    if not force and now - last_update < throttle then return end
    last_update, throttle = now, 1
    cooline.refresh_dividers()
    local entries = {}
    for key, frame in pairs(cooldowns) do
        local left = frame.end_time - now
        if left <= 0 and not frame.flashed then
            frame.flashed = true
            if left > -0.25 then cooline.show_flash(frame.icon:GetTexture()) end
        end
        if left <= -1 then
            cooline.clear_cooldown(key)
        elseif left > cooline_theme.max_time then
            frame:Hide()
        else
            frame:SetAlpha(left < 0 and 1 + left or 1)
            if left >= 0 and left <= cooline_theme.treshold then
                frame:SetBackdropColor(1, 0.82, 0, 1)
            else
                frame:SetBackdropColor(unpack(frame.is_spell and cooline_theme.spellcolor or cooline_theme.nospellcolor))
            end
            tinsert(entries, {frame = frame, key = key, position = cooline.time_position(left)})
            throttle = math.min(throttle, left < 10 and 0.02 or (left < 30 and 0.06 or (left < 180 and 0.15 or 0.4)))
        end
    end
    table.sort(entries, function(a, b)
        if a.frame.end_time == b.frame.end_time then return a.key < b.key end
        return a.frame.end_time < b.frame.end_time
    end)
    if cooline.preview_frames and (not cooline.preview_enabled or table.getn(entries) > 0) then
        for _, frame in ipairs(cooline.preview_frames) do
            if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
            frame:Hide()
        end
    end
    if cooline.preview_enabled and table.getn(entries) == 0 then
        entries = preview_entries(now)
        throttle = math.min(throttle, 0.1)
    end
    cooline.layout_icons(entries)
    cooline.update_tick_collisions()
    cooline:SetAlpha(table.getn(entries) > 0 and cooline_theme.activealpha or cooline_theme.inactivealpha)
end

function cooline.apply_theme()
    cooline:SetWidth(cooline_theme.width)
    cooline:SetHeight(cooline_theme.height)
    cooline.length = cooline_theme.vertical and cooline_theme.height or cooline_theme.width
    cooline.thickness = cooline_theme.vertical and cooline_theme.width or cooline_theme.height
    cooline.icon_size = cooline_theme.icon_size
    cooline.build_axis()
    if cooline.bg then
        cooline.bg:SetTexture(cooline_theme.statusbar)
        cooline.bg:SetVertexColor(unpack(cooline_theme.bgcolor))
        if cooline_theme.vertical then cooline.bg:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
        else cooline.bg:SetTexCoord(0, 1, 0, 1) end
    end
    cooline.refresh_ticks()
    Cooline_SaveTheme()
    if CoolineZMDDB and ZMD_ApplyDimensions then ZMD_ApplyDimensions() end
    cooline.on_update(true)
end

function cooline.VARIABLES_LOADED()
	Cooline_LoadSettings()

    cooline.flash = CreateFrame('Frame', nil, UIParent)
    cooline.flash:SetWidth(64)
    cooline.flash:SetHeight(64)
    cooline.flash:SetPoint('CENTER', UIParent, 'CENTER', 0, -16)
    cooline.flash:Hide()
    
    cooline.flash.texture = cooline.flash:CreateTexture(nil, 'ARTWORK')
    cooline.flash.texture:SetAllPoints(cooline.flash)
    cooline.flash.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	cooline:SetClampedToScreen(true)
	cooline:SetMovable(true)
	cooline:RegisterForDrag('LeftButton')
	
	-- 右键点击：切换闪烁提示（普通右键），Shift+右键切换走马灯
	cooline:RegisterForClicks("RightButtonUp")
	cooline:SetScript("OnClick", function()
		if arg1 == "RightButton" then
			if IsShiftKeyDown() then
				-- 切换走马灯启用状态
				if CoolineZMDDB then
					CoolineZMDDB.enabled = not CoolineZMDDB.enabled
					if ZMD_ApplyEnabled then
						ZMD_ApplyEnabled()
					end
					if CoolineZMDDB.enabled then
						DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00走马灯: 已启用")
					else
						DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00走马灯: 已禁用")
					end
				end
			else
				-- 切换 Cooline 闪烁提示
				cooline_settings.flash_enabled = not cooline_settings.flash_enabled
				if cooline_settings.flash_enabled then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Cooline: 技能冷却闪烁提示已启用")
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Cooline: 技能冷却闪烁提示已禁用")
					cooline.flash:Hide()
				end
			end
		end
	end)
	
	cooline:SetScript('OnDragStart', cooline.begin_drag)
	cooline:SetScript('OnDragStop', cooline.end_drag)
	cooline:SetScript('OnUpdate', function()
		if not IsShiftKeyDown() and cooline.dragging then cooline.end_drag() end
	end)
	-- Independent driver keeps expiry/flash correct when the bar is hidden.
	cooline.driver = CreateFrame('Frame', nil, UIParent)
	cooline.driver:SetScript('OnUpdate', function()
		local elapsed = arg1
		cooline.on_update()
		cooline.animate_ticks(elapsed)
	end)

	cooline:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	cooline:SetWidth(cooline_theme.width)
	cooline:SetHeight(cooline_theme.height)
	cooline:SetPoint('CENTER', cooline_settings.x, cooline_settings.y)
	
	-- ★ 新增：根据设置显示/隐藏冷却条
	cooline.set_shown(cooline_settings.show_cooline)
	
	cooline.bg = cooline:CreateTexture(nil, 'ARTWORK')
	cooline.bg:SetTexture(cooline_theme.statusbar)
	cooline.bg:SetVertexColor(unpack(cooline_theme.bgcolor))
	cooline.bg:SetAllPoints(cooline)
	if cooline_theme.vertical then
		cooline.bg:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
	else
		cooline.bg:SetTexCoord(0, 1, 0, 1)
	end

	cooline.overlay = CreateFrame('Frame', nil, cooline)

	cooline.ticks = {}
	for i = 1, 7 do
		cooline.ticks[i] = cooline.overlay:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	end
	cooline.apply_theme()
	-- A changed spellbook can reset or remove running spell cooldowns.
	cooline:RegisterEvent('SPELLS_CHANGED')
	cooline:RegisterEvent('PLAYER_ENTERING_WORLD')

    if type(GetSpellNameAndRankForId) == 'function' then cooline:RegisterEvent('UNIT_CASTEVENT') end
	cooline:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	cooline:RegisterEvent('BAG_UPDATE_COOLDOWN')
    cooline:RegisterEvent('BAG_UPDATE')
    cooline:RegisterEvent('UNIT_INVENTORY_CHANGED')
	cooline:SetFrameStrata("LOW")
	
	cooline.detect_cooldowns()
end

function cooline.SPELLS_CHANGED()
    cooline.request_spell_rescan()
end
function cooline.PLAYER_ENTERING_WORLD()
    cooline.request_spell_rescan()
    cooline.request_item_rescan()
end

function cooline.BAG_UPDATE_COOLDOWN()
	cooline.request_item_rescan()
end

function cooline.BAG_UPDATE()
    cooline.request_item_rescan()
end

function cooline.UNIT_INVENTORY_CHANGED()
    if arg1 == 'player' then cooline.request_item_rescan() end
end

function cooline.SPELL_UPDATE_COOLDOWN()
	cooline.request_spell_rescan()
end

-- ============================================================
-- 走马灯（施法序列滚动显示）- 独立于冷却条
-- ============================================================

local ZMD_CONFIRM_WINDOW = 3.5
local ZMD_FRESH_EPS = 0.1
local ZMD_FADE_TIME = 1.0
local ZMD_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local ZMD_DEFAULTS = {
  enabled = true,
  speed = 60,
  life = 3,
  dir = "left",
  name = false,
  relativeOffX = 0,
  relativeOffY = nil,
  sameCD = 1.5,
  castStage = "finish",   -- "start"=读条/引导开始时就出现；"finish"=读条后/施法完成后出现
}

local ZMD_SPECIAL_INSTANT_SPELLS = {
  ["审判"] = true,
}

local ZMD_spellByName = {}
local ZMD_active = {}
local ZMD_pool = {}
local ZMD_allIcons = {}
local ZMD_pending = nil
local ZMD_lastSpellTime = {}
local ZMD_lastSpawnName = nil
local ZMD_lastSpawnAt = 0

-- ★ 走马灯施法检测优化（参考 Cat2 ViewMyCasts / ViewMyCastsDetailed）
--   优先使用 SuperWoW 的 UNIT_CASTEVENT：自带 sourceGuid / castState / spellId，
--   无需再钩 CastSpell / UseAction 并扫描 tooltip，也不用靠“冷却出现”来确认一次施法。
--   无 SuperWoW 时回退到原有钩子方案（ZMD_TryInstant 等）。

local ZMD_HAS_SUPERWOW = type(GetSpellNameAndRankForId) == "function"
local ZMD_spellCache = {}
local ZMD_recentCastId = nil
local ZMD_recentCastAt = 0

local function ZMD_GetPlayerGuid()
  local exists, playerGuid = UnitExists("player")
  return playerGuid
end

local function ZMD_BaseName(name)
  if not name then return nil end
  local p1 = string.find(name, "(", 1, true)
  local p2 = string.find(name, "（", 1, true)
  local cut = p1
  if p2 and (not cut or p2 < cut) then cut = p2 end
  if not cut then return name end
  return string.gsub(string.sub(name, 1, cut - 1), "%s+$", "")
end

-- 由 spellId 取得 名称 + 图标（参考 Cat2 的 GetSpellNameAndRankForId / SpellInfo 回退）
local function ZMD_GetSpellById(spellId)
  if not spellId then return nil, nil end
  if ZMD_spellCache[spellId] then
    return ZMD_spellCache[spellId].name, ZMD_spellCache[spellId].texture
  end
  local name
  if type(GetSpellNameAndRankForId) == "function" then
    name = GetSpellNameAndRankForId(spellId)
  end
  if not name and type(SpellInfo) == "function" then
    name = SpellInfo(spellId)
  end
  if not name then return nil, nil end

  local texture = ZMD_DEFAULT_ICON
  local base = ZMD_BaseName(name)
  local info = ZMD_spellByName[base]
  if info and info.texture then
    texture = info.texture
  elseif type(GetSpellRecField) == "function" and type(GetSpellIconTexture) == "function" then
    local ok, iconId = pcall(GetSpellRecField, spellId, "spellIconID")
    if ok and iconId then
      local ok2, tex = pcall(GetSpellIconTexture, iconId)
      if ok2 and tex then texture = tex end
    end
  end
  ZMD_spellCache[spellId] = { name = name, texture = texture }
  return name, texture
end

-- 仅显示玩家主动施法（过滤被动 / 触发效果），参考 ViewMyCasts.IsPlayerActiveSpell
local function ZMD_IsPlayerActiveSpell(spellId)
  local name = ZMD_GetSpellById(spellId)
  if not name then return false end
  local info = ZMD_spellByName[ZMD_BaseName(name)]
  if info and info.index and type(IsPassiveSpell) == "function" then
    local ok, isPassive = pcall(IsPassiveSpell, info.index, BOOKTYPE_SPELL)
    if ok and isPassive then return false end
  end
  return true
end

local function ZMD_Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffff00走马灯|r：" .. msg)
end

local function ZMD_Debug(msg)
  if CoolineZMDDB and CoolineZMDDB.debug then
    ZMD_Print("|cffff8080调试|r " .. msg)
  end
end

local function ZMD_DefaultOffsetY()
  local extent = cooline_theme.vertical and (cooline.length or 200) / 2 or (cooline.label_extent or 26)
  return -extent - cooline_theme.fontsize - 18 - math.max(cooline.thickness or 18, 16) / 2
end

local function ZMD_InitDB()
  if type(CoolineZMDDB) ~= 'table' then CoolineZMDDB = {} end
  CoolineZMDDB.locked = nil
  for k, v in pairs(ZMD_DEFAULTS) do
    if CoolineZMDDB[k] == nil then
      CoolineZMDDB[k] = v
    end
  end
  local db = CoolineZMDDB
  if db.relativeOffY == nil then db.relativeOffY = ZMD_DefaultOffsetY() end
  if not db.centered_layout_spacing then
    -- Move only the exact old default below the larger icon/label footprint.
    -- Independently positioned histories keep their saved screen coordinates.
    local oldY = -(cooline.thickness or 18) - 2
    local baseX, baseY = 0, 0
    if db.converted_to_ui then
      local cx, cy = cooline:GetCenter()
      local sx, sy = UIParent:GetCenter()
      baseX, baseY = cx - sx, cy - sy
    end
    if math.abs(db.relativeOffX - baseX) < 0.5 and math.abs(db.relativeOffY - baseY - oldY) < 0.5 then
      db.relativeOffY = baseY + ZMD_DefaultOffsetY()
    end
    db.centered_layout_spacing = true
  end
end

local function ZMD_ScanSpellbook()
  ZMD_spellByName = {}
  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end
    if not ZMD_spellByName[name] then
      ZMD_spellByName[name] = {
        index = i,
        texture = GetSpellTexture(i, BOOKTYPE_SPELL),
      }
    end
    i = i + 1
  end
end

local function ZMD_FindSpell(query)
  if not query then return nil end
  if ZMD_spellByName[query] then return ZMD_spellByName[query], query end
  local p1 = string.find(query, "(", 1, true)
  local p2 = string.find(query, "（", 1, true)
  local cut = p1
  if p2 and (not cut or p2 < cut) then cut = p2 end
  if not cut then return nil end
  local base = string.gsub(string.sub(query, 1, cut - 1), "%s+$", "")
  if ZMD_spellByName[base] then return ZMD_spellByName[base], base end
  return nil
end

local function ZMD_GetIconSize()
  local height = cooline.thickness or 18
  return math.max(height, 16)
end

-- ★ 走马灯父级改为 UIParent，独立于冷却条
ZMD_anchor = CreateFrame("Frame", "CoolineZMD_Frame", UIParent)
ZMD_anchor:SetMovable(true)
ZMD_anchor:RegisterForDrag("LeftButton")
ZMD_anchor:SetFrameStrata("MEDIUM")
ZMD_anchor:EnableMouse(true)

ZMD_anchor:SetScript("OnDragStart", function()
  this:StartMoving()
end)
ZMD_anchor:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local x, y = this:GetCenter()
  local sx, sy = UIParent:GetCenter()
  if CoolineZMDDB then
    CoolineZMDDB.relativeOffX = x - sx
    CoolineZMDDB.relativeOffY = y - sy
    CoolineZMDDB.converted_to_ui = true
  end
end)

-- 全局启用/禁用函数
function ZMD_ApplyEnabled()
  if not ZMD_anchor then return end
  ZMD_pending = nil
  for i = table.getn(ZMD_active), 1, -1 do
    local entry = table.remove(ZMD_active, i)
    entry.frame:Hide()
    table.insert(ZMD_pool, entry.frame)
  end
  ZMD_lastSpellTime = {}
  ZMD_recentCastId, ZMD_recentCastAt = nil, 0
  if CoolineZMDDB and CoolineZMDDB.enabled then
    ZMD_anchor:Show()
  else
    ZMD_anchor:Hide()
  end
end

-- 图标框体
local function ZMD_CreateIconFrame()
  local frame = CreateFrame("Frame", nil, ZMD_anchor)
  local size = ZMD_GetIconSize()
  frame:SetWidth(size)
  frame:SetHeight(size)
  frame.tex = frame:CreateTexture(nil, "ARTWORK")
  frame.tex:SetAllPoints(frame)
  frame.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  frame.nameText = frame:CreateFontString(nil, "OVERLAY")
  frame.nameText:SetFontObject(GameFontHighlightSmall)
  frame.nameText:SetTextColor(1, 1, 0)
  frame.nameText:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  table.insert(ZMD_allIcons, frame)
  return frame
end

local function ZMD_AcquireIcon()
  local frame = table.remove(ZMD_pool)
  if not frame then
    frame = ZMD_CreateIconFrame()
  end
  local size = ZMD_GetIconSize()
  frame:SetWidth(size)
  frame:SetHeight(size)
  frame:SetAlpha(1)
  frame:Show()
  return frame
end

local function ZMD_ReleaseIcon(frame)
  frame:Hide()
  frame:SetAlpha(1)
  frame.nameText:SetText("")
  table.insert(ZMD_pool, frame)
end

local function ZMD_MaxX()
  local width = ZMD_anchor:GetWidth()
  if width == 0 then width = 200 end
  return math.max(0, width - ZMD_GetIconSize())
end

local function ZMD_SpawnX()
  if CoolineZMDDB.dir == "left" then
    return ZMD_MaxX()
  end
  return 0
end

local function ZMD_PositionIcon(entry)
  entry.frame:ClearAllPoints()
  entry.frame:SetPoint("LEFT", ZMD_anchor, "LEFT", entry.x, 0)
end

local function ZMD_RemoveEntry(index)
  local entry = ZMD_active[index]
  table.remove(ZMD_active, index)
  ZMD_ReleaseIcon(entry.frame)
end

local function ZMD_SpawnIcon(name, texture)
  if not name then return end
  local cd = CoolineZMDDB.sameCD
  if cd and cd > 0 then
    local last = ZMD_lastSpellTime[name]
    local now = GetTime()
    if last and (now - last) < cd then
      ZMD_Debug("同名技能冷却中，忽略生成: " .. tostring(name))
      return
    end
    ZMD_lastSpellTime[name] = now
  end

  local frame = ZMD_AcquireIcon()
  frame.tex:SetTexture(texture or ZMD_DEFAULT_ICON)
  frame.nameText:SetText(name)
  if CoolineZMDDB.name then
    frame.nameText:Show()
  else
    frame.nameText:Hide()
  end

  local entry = {
    frame = frame,
    x = ZMD_SpawnX(),
    dieAt = GetTime() + CoolineZMDDB.life - ZMD_FADE_TIME,
    fading = false,
  }
  ZMD_PositionIcon(entry)
  table.insert(ZMD_active, entry)

  ZMD_lastSpawnName = name
  ZMD_lastSpawnAt = GetTime()
  ZMD_Debug("生成图标: " .. tostring(name))
end

local function ZMD_JustSpawned(name)
  return name == ZMD_lastSpawnName and (GetTime() - ZMD_lastSpawnAt) < 0.5
end

local function ZMD_SpawnByName(name)
  if not name then return end
  local info = ZMD_FindSpell(name)
  ZMD_SpawnIcon(name, info and info.texture or ZMD_DEFAULT_ICON)
end

local function ZMD_TryInstant(query)
  if not CoolineZMDDB or not CoolineZMDDB.enabled then return end
  local info, name = ZMD_FindSpell(query)
  if not info then return end

  local now = GetTime()
  local start, duration = GetSpellCooldown(info.index, BOOKTYPE_SPELL)
  ZMD_Debug("按下: " .. tostring(name) .. " start=" .. tostring(start) .. " duration=" .. tostring(duration))

  if ZMD_SPECIAL_INSTANT_SPELLS[name] then
    ZMD_Debug("特殊技能（白名单）: " .. tostring(name) .. " 跳过冷却判定")
    ZMD_pending = {
      name = name,
      texture = info.texture,
      index = info.index,
      pressedAt = now,
      isSpecial = true,
    }
    return
  end

  if duration and duration > 0 and start and start >= now - ZMD_FRESH_EPS then
    ZMD_SpawnIcon(name, info.texture)
    ZMD_pending = nil
  else
    ZMD_pending = {
      name = name,
      texture = info.texture,
      index = info.index,
      pressedAt = now,
      isSpecial = false,
    }
  end
end

if not ZMD_HAS_SUPERWOW then
  -- 旧方案（无 SuperWoW 回退）：钩住施法函数并通过 Action 扫描法术名来检测施法
  hooksecurefunc("CastSpell", function(id, bookType)
    if bookType == BOOKTYPE_SPELL then
      ZMD_TryInstant(GetSpellName(id, BOOKTYPE_SPELL))
    end
  end)

  hooksecurefunc("CastSpellByName", function(name, onSelf)
    ZMD_TryInstant(name)
  end)

  if type(QueueSpellByName) == "function" then
    hooksecurefunc("QueueSpellByName", function(name)
      ZMD_TryInstant(name)
    end)
  end

  local ZMD_scanTip = CreateFrame("GameTooltip", "CoolineZMD_ScanTip", UIParent, "GameTooltipTemplate")

  -- 槽位 -> 法术名 缓存：避免每次点击动作条都做一次 tooltip 扫描（SetAction 较重）
  local ZMD_actionNameCache = {}

  local function ZMD_ScanActionName(slot)
    ZMD_scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    ZMD_scanTip:SetAction(slot)
    local name = CoolineZMD_ScanTipTextLeft1:GetText()
    ZMD_scanTip:Hide()
    return name
  end

  local function ZMD_GetActionSpellName(slot)
    local cached = ZMD_actionNameCache[slot]
    if cached ~= nil then
      return cached  -- false 表示“无名称/非技能”，直接返回，不再扫描
    end
    local name = ZMD_ScanActionName(slot)
    ZMD_actionNameCache[slot] = name or false
    return name
  end

  hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
    if GetActionText(slot) then return end
    local name = ZMD_GetActionSpellName(slot)
    if name then
      ZMD_TryInstant(name)
    end
  end)

  -- 动作条内容/分页变化、进服时清空缓存，下次点击按需重扫（而非每次点击都扫）
  local ZMD_cacheFrame = CreateFrame("Frame")
  ZMD_cacheFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  ZMD_cacheFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  ZMD_cacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  ZMD_cacheFrame:SetScript("OnEvent", function()
    ZMD_actionNameCache = {}
  end)
end

local function ZMD_OnUpdate()
  local dt = arg1
  local db = CoolineZMDDB
  if not db then return end

  if ZMD_pending then
    local now = GetTime()
    if ZMD_pending.isSpecial then
      ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
      ZMD_pending = nil
    else
      local start, duration = GetSpellCooldown(ZMD_pending.index, BOOKTYPE_SPELL)
      if duration and duration > 0 and start and start >= ZMD_pending.pressedAt - ZMD_FRESH_EPS then
        ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
        ZMD_pending = nil
      elseif now - ZMD_pending.pressedAt > ZMD_CONFIRM_WINDOW then
        ZMD_pending = nil
      end
    end
  end

  local now = GetTime()
  local move = db.speed * dt
  if db.dir == "left" then move = -move end

  local i = 1
  while i <= table.getn(ZMD_active) do
    local entry = ZMD_active[i]
    if entry.fading then
      local a = 1 - (now - entry.fadeStart) / ZMD_FADE_TIME
      if a <= 0 then
        ZMD_RemoveEntry(i)
      else
        entry.frame:SetAlpha(a)
        i = i + 1
      end
    else
      entry.x = entry.x + move
      if entry.x < 0 then entry.x = 0 end
      local maxX = ZMD_MaxX()
      if entry.x > maxX then entry.x = maxX end
      ZMD_PositionIcon(entry)

      if now >= entry.dieAt then
        entry.fading = true
        entry.fadeStart = now
      end
      i = i + 1
    end
  end
end

function ZMD_ApplyDimensions()
  local width = cooline.length or 200
  local height = cooline.thickness or 18
  ZMD_anchor:SetWidth(width)
  ZMD_anchor:SetHeight(height)
  local size = ZMD_GetIconSize()
  for _, frame in ipairs(ZMD_allIcons) do
    frame:SetWidth(size)
    frame:SetHeight(size)
  end
  local maxX = ZMD_MaxX()
  for _, entry in ipairs(ZMD_active) do
    if entry.x > maxX then
      entry.x = maxX
      ZMD_PositionIcon(entry)
    end
  end
  local showName = CoolineZMDDB.name
  for _, frame in ipairs(ZMD_allIcons) do
    if showName then frame.nameText:Show() else frame.nameText:Hide() end
  end
end

-- ★ 走马灯位置独立于冷却条，相对于屏幕中心
local function ZMD_ApplyRelativeOffset()
  if CoolineZMDDB.relativeOffX == nil or CoolineZMDDB.relativeOffY == nil then
    CoolineZMDDB.relativeOffX = 0
    CoolineZMDDB.relativeOffY = ZMD_DefaultOffsetY()
  end
  ZMD_anchor:ClearAllPoints()
  ZMD_anchor:SetPoint("CENTER", UIParent, "CENTER", CoolineZMDDB.relativeOffX, CoolineZMDDB.relativeOffY)
end

function ZMD_ApplyName()
  local showName = CoolineZMDDB.name
  for _, frame in ipairs(ZMD_allIcons) do
    if showName then frame.nameText:Show() else frame.nameText:Hide() end
  end
end

ZMD_anchor:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    ZMD_InitDB()
    -- ★ 如果是旧版本升级，将之前的相对偏移（相对于冷却条）转换为相对于屏幕中心
    if not CoolineZMDDB.converted_to_ui then
      local cx, cy = cooline:GetCenter()
      local sx, sy = UIParent:GetCenter()
      if cx and cy then
        local offX = CoolineZMDDB.relativeOffX or 0
        local offY = CoolineZMDDB.relativeOffY or 0
        CoolineZMDDB.relativeOffX = (cx - sx) + offX
        CoolineZMDDB.relativeOffY = (cy - sy) + offY
        CoolineZMDDB.converted_to_ui = true
      end
    end
    ZMD_ApplyDimensions()
    ZMD_ApplyRelativeOffset()
    ZMD_ApplyName()
    ZMD_ApplyEnabled()
    ZMD_ScanSpellbook()
    ZMD_anchor:SetScript("OnUpdate", ZMD_OnUpdate)
    ZMD_Print("走马灯已加载（独立于冷却条），输入 /cl 打开配置面板")
  elseif event == "SPELLS_CHANGED" then
    ZMD_ScanSpellbook()
  elseif event == "UNIT_CASTEVENT" then
    -- ★ 主检测路径（SuperWoW）：GUID 精准、自带 spellId 与 castState
    if not CoolineZMDDB or not CoolineZMDDB.enabled then return end
    local sourceGuid = arg1
    local castState = arg3
    local spellId = arg4
    if sourceGuid ~= ZMD_GetPlayerGuid() then return end
    local stage = CoolineZMDDB.castStage == "finish" and "finish" or "start"

    if castState == "START" or castState == "CHANNEL" then
      if not ZMD_IsPlayerActiveSpell(spellId) then return end
      -- 记录这一次施法，供 CAST 阶段去重 / 延迟生成
      ZMD_recentCastId = spellId
      ZMD_recentCastAt = GetTime()
      if stage == "start" then
        -- 读条/引导开始时就出现
        local name, texture = ZMD_GetSpellById(spellId)
        if name then
          ZMD_SpawnIcon(name, texture)
          -- Keep the cast marker until CAST/FAIL, including when sameCD is 0.
        end
      end
      -- stage == "finish"：此时不生成，等 CAST（施法完成）再出现
    elseif castState == "CAST" then
      -- 本次施法是否已在 START/CHANNEL 阶段登记过（读条技能；瞬发往往直接发 CAST）
      local matched = (ZMD_recentCastId == spellId and GetTime() - ZMD_recentCastAt <= 60)
      if matched and stage == "start" then
        -- start 模式已在 START/CHANNEL 生成过，抑制这次 CAST 的重复生成
        ZMD_recentCastId = nil
        ZMD_recentCastAt = 0
        return
      end
      if not ZMD_IsPlayerActiveSpell(spellId) then return end
      local name, texture = ZMD_GetSpellById(spellId)
      if name then
        ZMD_SpawnIcon(name, texture)
        ZMD_recentCastId = nil
        ZMD_recentCastAt = 0
      end
    elseif castState == "FAIL" then
      ZMD_recentCastId = nil
      ZMD_recentCastAt = 0
    end
  elseif not ZMD_HAS_SUPERWOW and (event == "SPELLCAST_START" or event == "SPELLCAST_CHANNEL_START") then
    -- 旧方案（无 SuperWoW 回退）：依赖 SPELLCAST_* 事件
    if not CoolineZMDDB or not CoolineZMDDB.enabled then return end
    ZMD_Debug(event .. " arg1=" .. tostring(arg1) .. " arg2=" .. tostring(arg2))
    if ZMD_pending then
      ZMD_SpawnIcon(ZMD_pending.name, ZMD_pending.texture)
      ZMD_pending = nil
    else
      local evName = arg1
      if event == "SPELLCAST_CHANNEL_START" then evName = arg2 end
      if evName and ZMD_FindSpell(evName) and not ZMD_JustSpawned(evName) then
        ZMD_SpawnByName(evName)
      end
    end
  end
end)
ZMD_anchor:RegisterEvent("PLAYER_LOGIN")
ZMD_anchor:RegisterEvent("SPELLS_CHANGED")
ZMD_anchor:RegisterEvent("UNIT_CASTEVENT")
ZMD_anchor:RegisterEvent("SPELLCAST_START")
ZMD_anchor:RegisterEvent("SPELLCAST_CHANNEL_START")

-- ============================================================
-- 走马灯集成结束
-- ============================================================
