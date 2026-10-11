-- Rules are plain data, in priority order. No loadstring or legacy engine dependency.
-- Fields in a rule use AND; values inside types/subtypes/ids use OR.
-- Optional fields: ids={123}, exclude={456}, types={"..."}, subtypes={"..."},
-- quality=0, nameContains="...", minCount=2. Strings are literal, not Lua patterns.
-- A manual item assignment has explicit priority over automatic rules.
local Q = QianKunBag
Q.categoryDefinitions = {
    { id="quest", name="任务物品", types={"Quest", "任务", "任务物品"} },
    { id="consume", name="消耗品", types={"Consumable", "消耗品"} },
    { id="equipment", name="装备", types={"Weapon", "Armor", "武器", "护甲"} },
    { id="materials", name="材料", types={"Trade Goods", "Reagent", "商品", "贸易品", "材料", "施法材料"} },
    { id="recipe", name="配方", types={"Recipe", "配方"} },
    { id="ammo", name="弹药", types={"Projectile", "Quiver", "弹药", "箭袋"} },
    { id="containers", name="容器", types={"Container", "容器"} },
    { id="junk", name="灰色杂物", quality=0 },
    { id="other", name="其他" },
    { id="empty", name="空格" },
}

local function set(values)
    if not values then return nil end
    local result = {}
    for _, value in ipairs(values) do result[value] = true end
    return result
end

function Q:CompileCategories()
    self.categoryByID = {}; self.categoryOrder = {}; self.rules = {}
    for _, definition in ipairs(self.categoryDefinitions) do
        local category = {}
        for key, value in pairs(definition) do category[key] = value end
        category.ids = set(category.ids); category.exclude = set(category.exclude)
        category.types = set(category.types); category.subtypes = set(category.subtypes)
        category.dependsCount = category.minCount ~= nil
        if not category.id or self.categoryByID[category.id] then error("QianKunBag: duplicate or missing category id") end
        self.categoryByID[category.id] = category
        table.insert(self.rules, category)
    end
    if not self.categoryByID.other or not self.categoryByID.empty then error("QianKunBag: other/empty required") end
    local seen = {}
    for _, id in ipairs(self.db.groupOrder) do
        if self.categoryByID[id] and not seen[id] then
            table.insert(self.categoryOrder, self.categoryByID[id]); seen[id] = true
        end
    end
    for _, category in ipairs(self.rules) do
        if not seen[category.id] then table.insert(self.categoryOrder, category) end
    end
    self.rulesDependCount = nil
    for _, category in ipairs(self.rules) do if category.dependsCount then self.rulesDependCount = true end end
end

function Q:Classify(record)
    self:Count("classified")
    if not record.occupied then return "empty", "空槽位" end
    local override = self.db.overrides[record.id]
    if override and self.categoryByID[override] and override ~= "empty" then return override, "手动指定" end
    if not record.meta then return "other", "物品信息待就绪" end
    for _, category in ipairs(self.rules) do
        if category.id ~= "empty" and category.id ~= "other"
            and (not category.exclude or not category.exclude[record.id])
            and (not category.ids or category.ids[record.id])
            and (not category.types or category.types[record.meta.itemType])
            and (not category.subtypes or category.subtypes[record.meta.subtype])
            and (category.quality == nil or category.quality == record.meta.quality)
            and (not category.minCount or record.count >= category.minCount)
            and (not category.nameContains or string.find(string.lower(record.meta.name), string.lower(category.nameContains), 1, true)) then
            return category.id, "规则：" .. category.name
        end
    end
    return "other", "默认类别"
end

function Q:SetOverride(id, categoryID)
    if not id or id <= 0 or id ~= math.floor(id) then self:Print("请提供正确物品 ID。"); return end
    if categoryID and (not self.categoryByID[categoryID] or categoryID == "empty") then self:Print("类别不存在；用 /qkb categories 查看。"); return end
    self.db.overrides[id] = categoryID
    for _, record in pairs(self.slots) do
        if record.id == id then
            record.category, record.reason = self:Classify(record)
            if self.buttons[record.key] then
                self.buttons[record.key].qRecord = record
                self:SearchButton(self.buttons[record.key])
            end
        end
    end
    self.layoutNeeded = true
    self:UpdateStatus()
    self:Print("物品 " .. id .. "：" .. (categoryID and self.categoryByID[categoryID].name or "恢复自动分类") .. "；重新打开或点击整理后更新位置。")
end

function Q:SetGroupOrder(text)
    local order, seen = {}, {}
    for id in string.gfind(text or "", "[^,%s]+") do
        if not self.categoryByID[id] or seen[id] then self:Print("类别不存在或重复；用 /qkb categories 查看。"); return false end
        table.insert(order, id); seen[id] = true
    end
    if table.getn(order) == 0 then self:Print("用法：/qkb order quest,consume,equipment,...；未列类别接在后面。"); return false end
    self.db.groupOrder = order; self:CompileCategories(); self.layoutNeeded = true
    self:UpdateStatus()
    self:Print("显示组顺序已保存；分类匹配优先级不变。点击整理或重新打开应用位置。")
    return true
end
