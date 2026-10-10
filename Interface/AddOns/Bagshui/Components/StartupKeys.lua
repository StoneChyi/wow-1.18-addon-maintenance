-- Bounded, session-only evidence for a backpack binding that recovers after login.
-- Does not change bindings, replace other addons' hooks, or open/refresh windows.
Bagshui:AddComponent(function()
local Bags = Bagshui.components.Bags
local Keys = { rows = {}, hooks = {}, closed = false, calls = 0 }
Bagshui.components.StartupKeys = Keys
local names = { "ToggleBackpack", "OpenBackpack", "OpenAllBags" }
local function Pack(...) return arg end
local function Expand(values, first, last)
	if first > last then return end
	return values[first], Expand(values, first + 1, last)
end

local function Identifier(value)
	if type(value) ~= "string" then return "无" end
	if string.len(value) > 80 or not string.find(value, "^[%w_]+$") then return "自定义" end
	return value
end

function Keys:Record(reason, api, bag)
	if table.getn(self.rows) >= 48 then return end
	local now = _G.GetTime()
	self.started = self.started or now
	local status = {}
	for _, name in ipairs(names) do
		local installed = self.hooks[name]
		table.insert(status, name .. "=" .. (not installed and "未记录"
			or (_G[name] == installed and "相同" or "已变化")))
	end
	local search = Bags.ui and Bags.ui.frames and Bags.ui.frames.searchBox
	local chat = _G.ChatFrameEditBox
	local row = string.format("%.2fs %s：初始化=%s；窗口=%s；首次扫描待完成=%s；B=%s；搜索焦点=%s；聊天输入框可见=%s；事件=%s；%s",
		now - self.started, reason, tostring(Bags.initialized == true),
		tostring(Bags.uiFrame and Bags.uiFrame:IsVisible() or false),
		tostring(Bags.initialInventoryUpdateNeeded == true),
		Identifier(_G.GetBindingAction and _G.GetBindingAction("B")),
		tostring(search and search.bagshuiData and search.bagshuiData.hasFocus == true or false),
		tostring(chat and chat:IsVisible() or false), Identifier(_G.event), table.concat(status, ", "))
	if api then
		row = row .. "; API=" .. Identifier(api) .. "; 参数类型=" .. type(bag)
		if type(bag) == "number" then row = row .. "; 袋号=" .. tostring(bag) end
		row = row .. "; 背包接管=" .. tostring(Bags:GetHookEnabled(api, bag))
	end
	table.insert(self.rows, row)
end

local init = Bags.Init
Bags.Init = function(self)
	if self.initialized then return init(self) end
	Keys:Record("初始化开始")
	init(self)
	for _, name in ipairs(names) do Keys.hooks[name] = _G[name] end
	Keys:Record("初始化完成")
end

local openCloseToggle = Bags.OpenCloseToggle
Bags.OpenCloseToggle = function(self, action, api, bag, force)
	local record = not Keys.closed and Keys.calls < 12
	if not record then return openCloseToggle(self, action, api, bag, force) end
	Keys.calls = Keys.calls + 1; Keys:Record("入口前", api, bag)
	local results = Pack(openCloseToggle(self, action, api, bag, force))
	Keys:Record("入口后", api, bag)
	return Expand(results, 1, results.n)
end

function Keys:OnEvent(event)
	if self.scheduled then return end
	self.scheduled = true
	self:Record(event)
	for _, delay in ipairs({ 0.1, 1, 2, 5, 10, 30, 60 }) do
		-- Each callback has its own queue identity; no reset of inventory callbacks.
		local seconds = delay
		Bagshui:QueueEvent(function()
			Keys:Record("登录定点 " .. tostring(seconds) .. "s")
			if seconds == 60 then Keys.closed = true end
		end, seconds)
	end
end
Bagshui:RegisterEvent("PLAYER_LOGIN", Keys)
Bagshui:RegisterEvent("PLAYER_ENTERING_WORLD", Keys)

function Keys:Report()
	self:Record("手动查看")
	local lines = {
		"乾坤袋登录按键诊断 v1 / Bagshui " .. tostring(BS_VERSION),
		"自动保留本次登录前 60 秒的定点状态及最多 12 次背包 API 入口；无需预先开启 perf。",
		"入口记录不等于物理按键记录：按钮及其他插件也可能调用同一 API。没有入口记录不能单独证明钩子被覆盖。",
		"相同/已变化只比较函数身份，其他插件的正常外层包装也会显示已变化；不自动重装钩子。",
		"搜索焦点仅检查乾坤袋；聊天输入框可见不等于拥有焦点。未读取聊天内容、物品或账号资料。",
		"本诊断不修改按键、刷新、可见性或登录等待策略；60 秒后停止自动记录。",
	}
	for _, row in ipairs(self.rows) do table.insert(lines, row) end
	if not self.window then
		self.window = Bagshui.prototypes.ScrollableTextWindow:New({
			name = "StartupKeys", title = "乾坤袋登录按键诊断（Ctrl+A / Ctrl+C 复制）",
			width = 850, height = 500, readOnly = true, selectAllOnFocus = true,
		})
	end
	self.window:Open(table.concat(lines, "\n"))
end
BsSlash:AddHandler("keys", function() Keys:Report() end)
end)
