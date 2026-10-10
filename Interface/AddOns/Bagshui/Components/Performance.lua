-- Opt-in inventory diagnostics. No SavedVariables, item names or account data.
-- Stable wrappers are installed before inventory initialization so queued callback
-- identities never change when recording is toggled. Disabled path only forwards.
Bagshui:AddComponent(function()
local Performance = { enabled = false, inventories = {}, opens = {}, active = {} }
Bagshui.components.Performance = Performance

local labels = {
	Update = "刷新入口", UpdateCache = "格子扫描", ValidateLayout = "布局校验",
	UpdateLayoutLookupTables = "分类索引", CategorizeItems = "分类规则",
	SortGroups = "组内排序", ManageDryRun = "布局比较", FindSpecialItems = "特殊物品查找",
	UpdateWindow = "窗口绘制", UpdateItemButtons = "物品按钮刷新", UpdateBagBar = "背包栏", UpdateToolbar = "工具栏",
	GetTooltip = "物品提示扫描", UiFrame_OnShow = "打开同步处理",
	Open = "基础打开入口", OpenBags = "背包打开入口", OpenBank = "银行打开入口",
}
local order = { "UiFrame_OnShow", "OpenBags", "OpenBank", "Open", "Update", "UpdateCache",
	"GetTooltip", "ValidateLayout", "UpdateLayoutLookupTables", "CategorizeItems", "SortGroups",
	"ManageDryRun", "FindSpecialItems", "UpdateWindow", "UpdateItemButtons", "UpdateBagBar", "UpdateToolbar" }
local detailOrder = { "GetGroupItemCountForLayout", "GroupWidths", "GroupLabels",
	"CreateGroup", "CreateGroupMoveTarget", "AssignItemsToSlots", "CreateInventoryItemSlotButton",
	"ParentCheck", "ParentApplyNew", "ParentApplyReused", "ParentApplyHidden", "ParentApplyVisible",
	"BankPreShowUpdate", "OpenShow", "OpenRaise", "OpenDock", "SkinBorderInit",
	"CreateItemSlotButton", "SkinItemButton", "CreateShadowedTexture", "CreateItemButtonCooldown",
	"SetItemButtonSize", "InvertItemButtonBorderScale", "BorderRead", "BorderApply",
	"SizeAndShowFrame", "PositionFrames", "ReadGeometry", "RowGeometry", "WindowGeometry", "WindowFinish",
	"AssignItemToItemButton", "UpdateItemButtonColorsAndBadges" }
local detailLabels = {
	GetGroupItemCountForLayout = "分组可见格计数", GroupWidths = "分组宽度计算", GroupLabels = "分组颜色与标签",
	CreateGroup = "分组准备（含复用）", CreateGroupMoveTarget = "移动目标准备（含复用）",
	AssignItemsToSlots = "分组物品分配", CreateInventoryItemSlotButton = "库存按钮准备（含复用）",
	ParentCheck = "按钮父框架检查", ParentApplyNew = "新建按钮父框架更换", ParentApplyReused = "复用按钮父框架更换",
	ParentApplyHidden = "隐藏按钮父框架更换", ParentApplyVisible = "可见按钮父框架更换",
	BankPreShowUpdate = "银行显示前更新", OpenShow = "窗口 Show（含打开同步）",
	OpenRaise = "窗口 Raise", OpenDock = "停靠窗口显示", SkinBorderInit = "皮肤首次边框应用",
	CreateItemSlotButton = "新建物品按钮", SkinItemButton = "按钮皮肤初始化",
	CreateShadowedTexture = "阴影装饰创建", CreateItemButtonCooldown = "冷却控件创建",
	SetItemButtonSize = "按钮缩放处理", InvertItemButtonBorderScale = "边框反向缩放",
	BorderRead = "缩放边框读取", BorderApply = "缩放边框应用",
	SizeAndShowFrame = "控件尺寸定位", PositionFrames = "锚点/点击区域/显示", ReadGeometry = "定位后 GetTop",
	RowGeometry = "行宽坐标读取", WindowGeometry = "窗口尺寸测量", WindowFinish = "窗口收尾设置",
	AssignItemToItemButton = "物品绑定与显示", UpdateItemButtonColorsAndBadges = "颜色与徽标",
}
local function ItemPool(inventory)
	local ui = inventory.ui
	return ui and ui.buttons and ui.buttons.itemSlots and table.getn(ui.buttons.itemSlots) or 0
end
local function CreationPool(ui, key)
	if key == "CreateGroup" then return ui.frames and ui.frames.groups end
	if key == "CreateGroupMoveTarget" then return ui.frames and ui.frames.groupMoveTargets end
end
local creations = { CreateItemSlotButton = true, CreateGroup = true, CreateGroupMoveTarget = true,
	CreateShadowedTexture = true, CreateItemButtonCooldown = true }
local inventoryNames = { Bags = "背包", Bank = "银行", Keyring = "钥匙链" }

-- Lua 5.0 unpack() has no range arguments. Preserve nil holes and all returns.
local function Pack(...) return arg end
local function Expand(values, first, last)
	if first > last then return end
	return values[first], Expand(values, first + 1, last)
end

local function AddStat(stats, key, elapsed, own, failed)
	local row = stats[key]
	if not row then
		row = { calls = 0, total = 0, own = 0, max = 0, errors = 0 }
		stats[key] = row
	end
	row.calls = row.calls + 1
	row.total = row.total + elapsed
	row.own = row.own + own
	row.max = math.max(row.max, elapsed)
	if failed then row.errors = row.errors + 1 end
end

function Performance:Reset()
	self.inventories, self.opens, self.active = {}, {}, {}
	self.startedAt = _G.GetTime()
	self.stoppedAt = nil
	self.frameMax, self.frameCount, self.invalidSpans = 0, 0, 0
	self.stack = nil
end

function Performance:GetInventory(inventory)
	local id = inventory.inventoryType
	local data = self.inventories[id]
	if not data then
		data = { stats = {}, events = {}, updates = 0, skipped = 0, queues = 0, redraws = 0, created = {}, poolStart = ItemPool(inventory), poolEnd = ItemPool(inventory) }
		self.inventories[id] = data
	end
	return data
end

function Performance:GetOpen(inventory)
	local sample = self.active[inventory.inventoryType]
	if sample and _G.GetTime() - sample.startedAt <= 1 then return sample end
end

function Performance:StartOpen(inventory)
	local sample = {
		inventoryType = inventory.inventoryType, startedAt = _G.GetTime(), clockStart = self.clock(),
		stats = {}, updates = 0, queues = 0, redraws = 0, created = {}, poolStart = ItemPool(inventory), poolEnd = ItemPool(inventory),
		event = inventory.lastEvent or "无最近事件", online = inventory.online,
	}
	self.active[inventory.inventoryType] = sample
	table.insert(self.opens, sample)
	if table.getn(self.opens) > 20 then table.remove(self.opens, 1) end
	return sample
end

-- Manual block spans use the same nesting tree as method spans. The enclosing
-- protected method closes unfinished blocks on error, preserving error identity.
function Performance:Begin(inventory, key)
	if not self.enabled or not inventory or not inventory.inventoryType then return end
	local span = { parent = self.stack, children = 0, inventory = inventory, key = key,
		data = self:GetInventory(inventory), sample = self:GetOpen(inventory) }
	span.started = self.clock()
	self.stack = span
	return span
end

function Performance:Finish(span, failed)
	local elapsed = self.clock() - span.started
	self.stack = span.parent
	if elapsed < 0 or span.invalid then
		self.invalidSpans = self.invalidSpans + 1
		if span.parent then span.parent.invalid = true end
	else
		if span.parent then span.parent.children = span.parent.children + elapsed end
		local own = math.max(0, elapsed - span.children)
		AddStat(span.data.stats, span.key, elapsed, own, failed)
		if span.sample then AddStat(span.sample.stats, span.key, elapsed, own, failed) end
	end
end

function Performance:Measure(original, key, inventory, args)
	local data = self:GetInventory(inventory)
	local sample
	if key == "UiFrame_OnShow" then sample = self:StartOpen(inventory) end
	sample = sample or self:GetOpen(inventory)
	if key == "Update" then
		if not inventory.windowUpdateBlocked and (inventory:Visible() or inventory.forceCacheUpdate) then
			data.updates = data.updates + 1
			if sample then sample.updates = sample.updates + 1 end
		else
			data.skipped = data.skipped + 1
		end
	elseif key == "UpdateWindow" and inventory.windowUpdateNeeded then
		data.redraws = data.redraws + 1
		if sample then sample.redraws = sample.redraws + 1 end
	end

	local pool = CreationPool(args[1], key)
	local element = pool and (args[2] or table.getn(pool) + 1)
	local existed = pool and pool[element]
	local span = self:Begin(inventory, key)
	local results = Pack(_G.pcall(original, Expand(args, 1, args.n)))
	-- A native call inside a manual block can fail before its Finish().
	while self.stack ~= span do self:Finish(self.stack, not results[1]) end
	self:Finish(span, not results[1])
	if results[1] and creations[key] then
		local count = (not pool or (not existed and pool[element])) and 1 or 0
		data.created[key] = (data.created[key] or 0) + count
		if sample then sample.created[key] = (sample.created[key] or 0) + count end
	end
	if key == "CreateInventoryItemSlotButton" or key == "UpdateWindow" or key == "UiFrame_OnShow" then
		data.poolEnd = ItemPool(inventory)
		if sample then sample.poolEnd = data.poolEnd end
	end
	if key == "UiFrame_OnShow" and sample then
		sample.online, sample.slots, sample.items = inventory.online, 0, 0
		for _, container in pairs(inventory.containers or {}) do
			sample.slots = sample.slots + (container.numSlots or 0)
			sample.items = sample.items + (container.slotsFilled or 0)
		end
	end
	-- Observe errors without swallowing or changing the original error object.
	if not results[1] then error(results[2], 0) end
	return Expand(results, 2, results.n)
end

function Performance:Wrap(owner, key, label, itemInfo)
	local original = owner and owner[key]
	if type(original) ~= "function" then return end
	owner[key] = function(...)
		if not Performance.enabled then return original(Expand(arg, 1, arg.n)) end
		local inventory = arg[1]
		if itemInfo == "ui" then inventory = arg[1].inventory
		elseif itemInfo then inventory = arg[3] end
		-- Standalone tooltips/catalog entries are outside the inventory measurement.
		if not inventory or not inventory.inventoryType then return original(Expand(arg, 1, arg.n)) end
		return Performance:Measure(original, label or key, inventory, arg)
	end
end

function Performance:OnFrame(elapsed)
	if not self.enabled then return end
	elapsed = elapsed or 0
	self.frameCount = self.frameCount + 1
	self.frameMax = math.max(self.frameMax, elapsed * 1000)
	for _, sample in pairs(self.active) do
		if not sample.nextFrame then
			local delta = self.clock() - sample.clockStart
			if delta >= 0 then sample.nextFrame = delta else sample.nextFrame = -1 end
		end
	end
	if _G.GetTime() - self.startedAt >= 60 then
		self:Stop()
		Bagshui:Print("卡顿采样已满 60 秒并停止。输入 /bs perf report 查看并复制报告。")
	end
end

function Performance:Start()
	if type(_G.debugprofilestop) ~= "function" then
		Bagshui:Print("当前客户端缺少精确计时接口 debugprofilestop，无法可靠测量；未开启诊断。")
		return
	end
	self.clock = _G.debugprofilestop
	self:Reset()
	self.enabled = true
	if not self.frame then
		self.frame = _G.CreateFrame("Frame")
		self.frame:SetScript("OnUpdate", function() Performance:OnFrame(_G.arg1) end)
	end
	self.frame:Show()
	Bagshui:Print("卡顿诊断已开启（新采样，60 秒后自动停止）。请打开/关闭背包和银行数次，再输入 /bs perf report。")
end

function Performance:Stop()
	if self.enabled then self.stoppedAt = _G.GetTime() end
	self.enabled = false
	if self.frame then self.frame:Hide() end
end

local function EventsText(events)
	local entries = {}
	for name, count in pairs(events) do table.insert(entries, { name = name, count = count }) end
	table.sort(entries, function(a, b)
		if a.count == b.count then return a.name < b.name end
		return a.count > b.count
	end)
	local text = {}
	for i = 1, math.min(8, table.getn(entries)) do
		table.insert(text, entries[i].name .. "=" .. entries[i].count)
	end
	return table.concat(text, ", ")
end

local function CreationText(data)
	local c = data.created
	return string.format("按钮池 %d→%d；实际新建：物品按钮 %d，分组 %d，移动目标 %d，阴影装饰 %d，冷却控件 %d。",
		data.poolStart, data.poolEnd, c.CreateItemSlotButton or 0, c.CreateGroup or 0,
		c.CreateGroupMoveTarget or 0, c.CreateShadowedTexture or 0, c.CreateItemButtonCooldown or 0)
end

function Performance:ReportText()
	local lines = { "乾坤袋卡顿诊断 v3.2 / Bagshui " .. tostring(BS_VERSION),
		"诊断不改变刷新策略；数据仅保留在本次登录内。",
		"毫秒为墙钟耗时，包含诊断开销。包含内部调用的耗时不能相加。",
		"自身耗时仅扣除已测量的子调用；窗口绘制表示 Lua 布局/按钮处理，不是 GPU 渲染。",
		"下一帧等待和最大帧间隔包含其他插件、游戏及系统耗时，不能单独归因乾坤袋。",
		"v3 细分有额外诊断开销，勿与 v2 直接比较绝对耗时；细分阶段互相包含，不能相加。",
		"v3.1 新增父框架检查/更换计时，更换次数区分新建与复用按钮；与 v3 比较须考虑额外开销。",
		"v3.2 区分隐藏/可见迁移，增加首次边框及打开入口细分；这些计时与已有阶段互相包含。",
		"Show 总耗时包含打开同步；自身耗时仅扣除已测子调用。显示前更新及 Show 可能早于本次打开观察窗，主要查看库存累计。",
		"准备次数包含复用；实际新建数量另列。缩放边框读取/应用仅测缩放路径，皮肤初始化另列。" }
	if not self.startedAt then
		table.insert(lines, "尚无采样。输入 /bs perf on，然后复现卡顿。")
		return table.concat(lines, "\n")
	end
	table.insert(lines, string.format("采样时长 %.1f 秒；状态：%s；帧数 %d；最大帧间隔 %.2f ms；计时失效 %d 段。",
		(self.enabled and _G.GetTime() or self.stoppedAt) - self.startedAt,
		self.enabled and "采样中" or "已停止", self.frameCount, self.frameMax, self.invalidSpans))
	for _, id in ipairs(BS_INVENTORY_TYPE_UI_ORDER) do
		local data = self.inventories[id]
		if data then
			table.insert(lines, "\n[" .. (inventoryNames[id] or id) .. "]")
			table.insert(lines, string.format("实际刷新 %d；跳过入口 %d；排队请求 %d（不等于实际刷新）；完整布局 %d。",
				data.updates, data.skipped, data.queues, data.redraws))
			table.insert(lines, "阶段 | 次数 | 总耗时 ms | 自身 ms | 单次最大 ms | 错误")
			for _, key in ipairs(order) do
				local row = data.stats[key]
				if row then
					table.insert(lines, string.format("%s | %d | %.2f | %.2f | %.2f | %d",
						labels[key], row.calls, row.total, row.own, row.max, row.errors))
				end
			end
			table.insert(lines, CreationText(data))
			table.insert(lines, "窗口处理细分 | 次数 | 总耗时 ms | 自身 ms | 单次最大 ms | 错误")
			for _, key in ipairs(detailOrder) do
				local row = data.stats[key]
				if row then
					table.insert(lines, string.format("%s | %d | %.2f | %.2f | %.2f | %d",
						detailLabels[key], row.calls, row.total, row.own, row.max, row.errors))
				end
			end
			table.insert(lines, "常见事件：" .. EventsText(data.events))
		end
	end
	table.insert(lines, "\n[最近打开，最多 20 次；统计打开后 1 秒内的工作]")
	for index, sample in ipairs(self.opens) do
		local function Total(key)
			return sample.stats[key] and sample.stats[key].total or 0
		end
		local function Calls(key)
			return sample.stats[key] and sample.stats[key].calls or 0
		end
		local tooltip = sample.stats.GetTooltip
		local age = (self.enabled and _G.GetTime() or self.stoppedAt) - sample.startedAt
		table.insert(lines, string.format("#%d %s %s：%d 格/%d 占用格；刷新 %d；布局 %d；排队 %d；窗口观察 %.2f/1 秒。",
			index, inventoryNames[sample.inventoryType] or sample.inventoryType, sample.online and "在线" or "离线",
			sample.slots or 0, sample.items or 0, sample.updates, sample.redraws, sample.queues, math.min(1, age)))
		table.insert(lines, string.format("  打开同步 %.2f ms；扫描 %.2f；分类 %.2f；排序 %.2f；绘制 %.2f；按钮 %.2f；提示 %d 次/%.2f ms。",
			Total("UiFrame_OnShow"), Total("UpdateCache"), Total("CategorizeItems"), Total("SortGroups"),
			Total("UpdateWindow"), Total("UpdateItemButtons"), tooltip and tooltip.calls or 0, Total("GetTooltip")))
		table.insert(lines, "  " .. CreationText(sample))
		table.insert(lines, string.format("  细分 ms：计数 %.2f；组宽 %.2f；标签 %.2f；新按钮 %.2f；皮肤 %.2f；尺寸定位 %.2f；绑定 %.2f；颜色 %.2f。",
			Total("GetGroupItemCountForLayout"), Total("GroupWidths"), Total("GroupLabels"), Total("CreateItemSlotButton"),
			Total("SkinItemButton"), Total("SizeAndShowFrame"), Total("AssignItemToItemButton"), Total("UpdateItemButtonColorsAndBadges")))
		table.insert(lines, string.format("  定位/边框 ms：锚点显示 %.2f；GetTop %.2f；缩放 %.2f；边框读取 %.2f；边框应用 %.2f。",
			Total("PositionFrames"), Total("ReadGeometry"), Total("SetItemButtonSize"), Total("BorderRead"), Total("BorderApply")))
		table.insert(lines, string.format("  父框架：检查 %d 次/%.2f ms；新建按钮更换 %d 次/%.2f ms；复用按钮更换 %d 次/%.2f ms。",
			Calls("ParentCheck"), Total("ParentCheck"), Calls("ParentApplyNew"), Total("ParentApplyNew"),
			Calls("ParentApplyReused"), Total("ParentApplyReused")))
		table.insert(lines, string.format("  迁移可见性：隐藏 %d 次/%.2f ms；可见 %d 次/%.2f ms；首次边框 %.2f ms。",
			Calls("ParentApplyHidden"), Total("ParentApplyHidden"), Calls("ParentApplyVisible"), Total("ParentApplyVisible"), Total("SkinBorderInit")))
		table.insert(lines, string.format("  窗口 ms：行宽坐标 %.2f；尺寸测量 %.2f；收尾设置 %.2f。",
			Total("RowGeometry"), Total("WindowGeometry"), Total("WindowFinish")))
		table.insert(lines, "  打开至下一帧：" .. (sample.nextFrame and sample.nextFrame >= 0
			and string.format("%.2f ms", sample.nextFrame) or "未取得有效样本") .. "；最近事件：" .. sample.event)
	end
	return table.concat(lines, "\n")
end

function Performance:ShowReport()
	-- Freeze first: building/displaying the report must not contaminate samples.
	self:Stop()
	if not self.reportWindow then
		self.reportWindow = Bagshui.prototypes.ScrollableTextWindow:New({
			name = "PerformanceReport", title = "乾坤袋卡顿诊断（Ctrl+A / Ctrl+C 复制）",
			width = 780, height = 520, readOnly = true, selectAllOnFocus = true,
		})
	end
	self.reportWindow:Open(self:ReportText())
	Bagshui:Print("采样已停止。诊断报告可 Ctrl+A、Ctrl+C 复制；/bs perf on 开始新采样。")
end

-- Hook the prototype once, after subclasses exist but before their Init() runs.
local Inventory = Bagshui.prototypes.Inventory
for _, key in ipairs(order) do
	if key ~= "GetTooltip" and key ~= "OpenBags" and key ~= "OpenBank" then
		Performance:Wrap(Inventory, key)
	end
end
Performance:Wrap(Bagshui.components.Bags, "Open", "OpenBags")
Performance:Wrap(Bagshui.components.Bank, "Open", "OpenBank")
Performance:Wrap(BsItemInfo, "GetTooltip", nil, true)
for _, key in ipairs({ "GetGroupItemCountForLayout", "AssignItemsToSlots", "SizeAndShowFrame" }) do
	Performance:Wrap(Inventory, key)
end
local InventoryUi = Bagshui.prototypes.InventoryUi
for _, key in ipairs({ "CreateGroup", "CreateGroupMoveTarget", "CreateInventoryItemSlotButton" }) do
	Performance:Wrap(InventoryUi, key, nil, "ui")
end
local Ui = Bagshui.prototypes.Ui
for _, key in ipairs({ "CreateItemSlotButton", "SkinItemButton", "CreateShadowedTexture", "CreateItemButtonCooldown",
	"SetItemButtonSize", "InvertItemButtonBorderScale", "AssignItemToItemButton", "UpdateItemButtonColorsAndBadges" }) do
	Performance:Wrap(Ui, key, nil, "ui")
end

local originalQueue = Inventory.QueueUpdate
Inventory.QueueUpdate = function(inventory, delay, cascade)
	if Performance.enabled then
		local data = Performance:GetInventory(inventory)
		data.queues = data.queues + 1
		local sample = Performance:GetOpen(inventory)
		if sample then sample.queues = sample.queues + 1 end
	end
	return originalQueue(inventory, delay, cascade)
end

local originalEvent = Inventory.OnEvent
Inventory.OnEvent = function(inventory, event, arg1, arg2)
	if Performance.enabled then
		local events = Performance:GetInventory(inventory).events
		-- Store event identifiers only, never arguments (which may contain user data).
		if type(event) == "string" and string.len(event) <= 80 then
			events[event] = (events[event] or 0) + 1
		end
	end
	return originalEvent(inventory, event, arg1, arg2)
end

L.Slash_Perf = "perf"
BsSlash:AddHandler("Perf", function(tokens)
	local action = string.lower(tokens[2] or "help")
	if action == "on" then Performance:Start()
	elseif action == "off" then
		Performance:Stop()
		Bagshui:Print("卡顿诊断已关闭；已有采样保留，可用 /bs perf report 查看。")
	elseif action == "report" then Performance:ShowReport()
	elseif action == "clear" then
		Performance:Stop()
		Performance:Reset()
		Performance.startedAt = nil
		Bagshui:Print("诊断已关闭，采样已清空。")
	elseif action == "status" then
		Bagshui:Print(Performance.enabled and "卡顿诊断采样中。" or "卡顿诊断已关闭。")
	else
		Bagshui:Print("/bs perf on 开启并清空旧采样（60 秒）；off 停止；report 停止并打开可复制报告；clear 清空；status 状态。")
	end
end)
end)
