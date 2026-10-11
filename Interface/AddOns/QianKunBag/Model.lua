local Q = QianKunBag

function Q:GetMetadata(link)
    if not link then return nil end
    local _, _, itemString = string.find(link, "(item:[%d:%-]+)")
    itemString = itemString or link
    if self.metadata[itemString] then return self.metadata[itemString] end
    local name, _, quality, level, itemType, subtype, stack, equipLoc, texture = GetItemInfo(itemString)
    if not name then return nil end
    local meta = { key=itemString, name=name, quality=quality or -1, level=level or 0,
        itemType=itemType, subtype=subtype, stack=stack or 1, equipLoc=equipLoc, texture=texture }
    self.metadata[itemString] = meta
    return meta
end

function Q:Refresh(allowLayout)
    local started = debugprofilestop and debugprofilestop()
    -- Swap generations before API reads: reentrant events cannot be discarded.
    local dirty = self.dirty
    self.dirty = {}
    local changes, sizes, retry = {}, {}, {}
    local structural, pruneNeeded = false, false
    for bag in pairs(dirty) do
        self:Count("bags")
        local size = GetContainerNumSlots(bag) or 0
        sizes[bag] = size
        if self.sizes[bag] ~= size then structural = true; self.layoutNeeded = true end
        for slot = 1, size do
            local key = bag .. ":" .. slot
            local texture, amount, locked, _, readable = GetContainerItemInfo(bag, slot)
            local link = GetContainerItemLink(bag, slot)
            local occupied = link ~= nil or texture ~= nil
            local count, charges = amount or (occupied and 1 or 0), 0
            if count < 0 then charges = -count; count = 1 end
            local _, _, id = string.find(link or "", "item:(%d+)")
            local meta = self:GetMetadata(link)
            if occupied and not meta then retry[bag] = true end
            locked = (locked == 1 or locked == true)
            local old = self.slots[key]
            if not old or old.link ~= link or old.texture ~= texture or old.count ~= count
                or old.charges ~= charges or old.locked ~= locked or old.readable ~= readable
                or old.occupied ~= occupied or old.meta ~= meta then
                local record = { key=key, bag=bag, slot=slot, link=link, id=tonumber(id), texture=texture,
                    occupied=occupied, count=count, charges=charges, locked=locked, readable=readable, meta=meta }
                if not old or old.meta ~= meta or old.link ~= link then pruneNeeded = true end
                if old and old.link == record.link and old.meta == record.meta and old.occupied == record.occupied
                    and (not self.rulesDependCount or old.count == record.count) then
                    record.category, record.reason = old.category, old.reason
                else
                    record.category, record.reason = self:Classify(record)
                end
                if not old or old.category ~= record.category or old.link ~= record.link
                    or old.count ~= record.count or old.meta ~= record.meta then self.layoutNeeded = true end
                table.insert(changes, record)
            end
        end
    end
    -- Commit after all requested containers have been read; no button work during scan.
    for bag, size in pairs(sizes) do
        for slot = size + 1, self.sizes[bag] or 0 do
            local key = bag .. ":" .. slot
            local old = self.slots[key]
            if old and old.occupied then self.filled = (self.filled or 0) - 1 end
            if old and old.occupied and not old.meta then self.pending = (self.pending or 0) - 1 end
            self.slots[key] = nil
            pruneNeeded = true
            if self.buttons[key] then self.buttons[key]:Hide(); self.buttons[key].qRecord = nil end
        end
        self.total = (self.total or 0) + size - (self.sizes[bag] or 0)
        self.sizes[bag] = size
        self.pendingRetry[bag] = retry[bag]
    end
    for _, record in ipairs(changes) do
        local old = self.slots[record.key]
        self.filled = (self.filled or 0) + (record.occupied and 1 or 0) - (old and old.occupied and 1 or 0)
        self.pending = (self.pending or 0) + (record.occupied and not record.meta and 1 or 0) - (old and old.occupied and not old.meta and 1 or 0)
        self.slots[record.key] = record
        self:Count("changed")
        if self.window then self:Paint(record) end
    end
    if self.window then
        -- New/removed physical slots require safe geometry; existing slots never retarget.
        if structural then self.geometryPending = true end
        if self.layoutNeeded and (allowLayout or self.geometryPending) and (not self:Busy() or not self.hasLayout) then self:Layout() end
        self:UpdateStatus()
    end
    if next(self.pendingRetry) and self.retryCount < 5 and (self:IsOpen() or allowLayout) then
        self.retryAt = GetTime() + math.min(2, 0.25 * (self.retryCount + 1))
    else self.retryAt = nil end
    -- Bound metadata by the active inventory, not by every item seen this login.
    if pruneNeeded then
        local used = {}
        for _, record in pairs(self.slots) do if record.meta then used[record.meta.key] = true end end
        for key in pairs(self.metadata) do if not used[key] then self.metadata[key] = nil end end
    end
    if started then self.lastMs = string.format("%.2f", math.max(0, debugprofilestop() - started)) else self.lastMs = nil end
end

function Q:BuildGroups()
    local grouped = {}
    for _, category in ipairs(self.categoryOrder) do grouped[category.id] = {} end
    for _, record in pairs(self.slots) do table.insert(grouped[record.category] or grouped.other, record) end
    local function less(a, b)
        local an, bn = a.meta and a.meta.name or "", b.meta and b.meta.name or ""
        if an ~= bn then return an < bn end
        local aq, bq = a.meta and a.meta.quality or -1, b.meta and b.meta.quality or -1
        if aq ~= bq then return aq > bq end
        if a.count ~= b.count then return a.count > b.count end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end
    for _, list in pairs(grouped) do table.sort(list, less) end
    return grouped
end
