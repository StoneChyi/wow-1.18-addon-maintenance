assert(BigWigs, "BigWigs not found!")

------------------------------
-- 竖行条 (Vertical Icon Timeline Bar)
-- 逻辑参考 EasyDBM：图标按剩余时间排序，
-- 剩余 >10s 驻留顶部，<=10s 沿竖轨匀速下落，
-- <=5s 放大并显示特效圈，中线标记最近将到期的技能。
-- 适配 WoW 1.12 / Lua 5.0（table.getn、this、无 C_Timer/BackdropTemplate/SetGradientAlpha）
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("BigWigsVerticalBars")

L:RegisterTranslations("enUS", function()
	return {
		["VerticalBars"] = true,
		["verticalbars"] = true,
		["Options for the vertical icon timeline bar."] = true,
		["Enable"] = true,
		["Enables the vertical icon timeline bar."] = true,
		["Test"] = true,
		["Start/stop a test of the vertical bar."] = true,
		["Max icons"] = true,
		["Maximum number of icons waiting above the track."] = true,
		["Icon size"] = true,
		["Size of each icon."] = true,
		["Track height"] = true,
		["Total height of the vertical track (top half 40s-10s compressed, bottom half 10s-0)."] = true,
		["Reset position"] = true,
		["Reset the vertical bar anchor to the center-right of the screen."] = true,
		["Vertical bar enabled"] = true,
		["Vertical bar disabled"] = true,
		["Locked"] = true,
		["Draggable"] = true,
		["Bar position locked"] = true,
		["Bar unlocked, can be dragged"] = true,
		["Background shown"] = true,
		["Background hidden (right-click the track to show again)"] = true,
		["Click to unlock, you can drag the bar"] = true,
		["Click to lock, forbid dragging"] = true,
		["Lock position"] = true,
		["Lock the vertical bar anchor so it cannot be dragged."] = true,
		["Show labels"] = true,
		["Show the spell name text next to each icon."] = true,
		["Label side"] = true,
		["Choose which side of the icon the spell name text is shown on."] = true,
		["Right"] = true,
		["Left"] = true,
		["Label side is now %s"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["VerticalBars"] = "竖行条",
		["verticalbars"] = "竖行条",
		["Options for the vertical icon timeline bar."] = "竖行图标时间轴条选项.",
		["Enable"] = "启用",
		["Enables the vertical icon timeline bar."] = "启用竖行图标时间轴条.",
		["Test"] = "测试",
		["Start/stop a test of the vertical bar."] = "开始/停止竖行条测试.",
		["Max icons"] = "等待数量",
		["Maximum number of icons waiting above the track."] = "轨道上方等待队列的最大图标数量.",
		["Icon size"] = "图标大小",
		["Size of each icon."] = "每个图标的尺寸.",
		["Track height"] = "轨道高度",
		["Total height of the vertical track (top half 40s-10s compressed, bottom half 10s-0)."] = "竖直轨道总高度（上半段 40s→10s 压缩显示，下半段 10s→0 精确下落）.",
		["Reset position"] = "复位位置",
		["Reset the vertical bar anchor to the center-right of the screen."] = "将竖行条锚点重置到屏幕右侧居中.",
		["Vertical bar enabled"] = "竖行条已开启",
		["Vertical bar disabled"] = "竖行条已关闭",
		["Locked"] = "已锁定",
		["Draggable"] = "可拖动",
		["Bar position locked"] = "已锁定竖行条位置",
		["Bar unlocked, can be dragged"] = "已解锁，可拖动竖行条",
		["Background shown"] = "背景已显示",
		["Background hidden (right-click the track to show again)"] = "背景已隐藏（右键轨道再次显示）",
		["Click to unlock, you can drag the bar"] = "点击解锁，可拖动竖行条",
		["Click to lock, forbid dragging"] = "点击锁定，禁止拖动",
		["Lock position"] = "锁定位置",
		["Lock the vertical bar anchor so it cannot be dragged."] = "锁定竖行条锚点，禁止拖动.",
		["Show labels"] = "显示名称",
		["Show the spell name text next to each icon."] = "在图标旁显示技能名称.",
		["Label side"] = "名称方向",
		["Choose which side of the icon the spell name text is shown on."] = "选择技能名称显示在图标的左侧还是右侧.",
		["Right"] = "右侧",
		["Left"] = "左侧",
		["Label side is now %s"] = "名称方向已切换为：%s",
	}
end)

------------------------------
-- Module Declaration
------------------------------

BigWigsVerticalBars = BigWigs:NewModule(L["VerticalBars"])
BigWigsVerticalBars.revision = tonumber(string.sub("$Revision: 20004 $", 12, -3))
BigWigsVerticalBars.defaultDB = {
	enabled = true,
	maxIcons = 5,
	iconSize = 32,
	trackHeight = 300,
	scale = 1.0,
	showLabels = true,
	labelSide = "right",   -- "right" / "left"：技能名称显示在图标的哪一侧
	locked = false,
	bgVisible = true,
	posx = nil,
	posy = nil,
}
BigWigsVerticalBars.consoleCmd = L["verticalbars"]

BigWigsVerticalBars.consoleOptions = {
	type = "group",
	name = L["VerticalBars"],
	desc = L["Options for the vertical icon timeline bar."],
	args = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			desc = L["Enables the vertical icon timeline bar."],
			order = 1,
			get = function()
				return BigWigsVerticalBars.db.profile.enabled
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.enabled = v
				BigWigsVerticalBars:UpdateVisibility()
			end,
		},
		test = {
			type = "execute",
			name = L["Test"],
			desc = L["Start/stop a test of the vertical bar."],
			order = 2,
			func = function()
				BigWigsVerticalBars:RunTest()
			end,
		},
		maxIcons = {
			type = "range",
			name = L["Max icons"],
			desc = L["Maximum number of icons waiting above the track."],
			order = 3,
			min = 1,
			max = 8,
			step = 1,
			get = function()
				return BigWigsVerticalBars.db.profile.maxIcons
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.maxIcons = v
				BigWigsVerticalBars:ApplyLayout()
			end,
		},
		iconSize = {
			type = "range",
			name = L["Icon size"],
			desc = L["Size of each icon."],
			order = 4,
			min = 16,
			max = 64,
			step = 2,
			get = function()
				return BigWigsVerticalBars.db.profile.iconSize
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.iconSize = v
				BigWigsVerticalBars:ApplyLayout()
			end,
		},
		trackHeight = {
			type = "range",
			name = L["Track height"],
			desc = L["Track height"],
			order = 5,
			min = 100,
			max = 600,
			step = 10,
			get = function()
				return BigWigsVerticalBars.db.profile.trackHeight
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.trackHeight = v
				BigWigsVerticalBars:ApplyLayout()
			end,
		},
		showLabels = {
			type = "toggle",
			name = L["Show labels"],
			desc = L["Show the spell name text next to each icon."],
			order = 6,
			get = function()
				return BigWigsVerticalBars.db.profile.showLabels
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.showLabels = v
			end,
		},
		labelSide = {
			type = "text",
			name = L["Label side"],
			desc = L["Choose which side of the icon the spell name text is shown on."],
			order = 7,
			get = function()
				return (BigWigsVerticalBars.db.profile.labelSide == "left") and L["Left"] or L["Right"]
			end,
			validate = { L["Right"], L["Left"] },
			set = function(v)
				BigWigsVerticalBars.db.profile.labelSide = (v == L["Left"]) and "left" or "right"
				BigWigsVerticalBars:ApplyLayout()
				BigWigsVerticalBars:UpdateAllIcons()
			end,
		},
		locked = {
			type = "toggle",
			name = L["Lock position"],
			desc = L["Lock the vertical bar anchor so it cannot be dragged."],
			order = 8,
			get = function()
				return BigWigsVerticalBars.db.profile.locked
			end,
			set = function(v)
				BigWigsVerticalBars.db.profile.locked = v
				BigWigsVerticalBars:UpdateLockState()
			end,
		},
		reset = {
			type = "execute",
			name = L["Reset position"],
			desc = L["Reset the vertical bar anchor to the center-right of the screen."],
			order = 10,
			func = function()
				BigWigsVerticalBars:ResetAnchor()
			end,
		},
	},
}

------------------------------
-- Timeline state
------------------------------

local timeline = {}      -- { {text, icon, key, start, dur, endTime} }
local iconPool = {}      -- created icon frames
local testRunning = false
local testBars = nil

local FONT = "Fonts\\FRIZQT__.ttf"
local WHITE = "Interface\\Tooltips\\UI-Tooltip-Background"
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_PocketWatch_01"
local OVERLAY_TEX = "Interface\\Buttons\\UI-AutoCastableOverlay"

local function TimeLeftText(remain)
	if remain >= 60 then
		return string.format("%d:%02d", math.floor(remain / 60), math.floor(math.mod(remain, 60)))
	elseif remain >= 10 then
		return string.format("%d", math.floor(remain))
	else
		return string.format("%.1f", remain)
	end
end

local function RemainColor(remain)
	-- EasyDBM 配色：>10s 白色；10~5s 白->黄过渡；<5s 黄->红过渡
	if remain > 5 then
		if remain >= 10 then
			return 1, 1, 1, 1
		end
		local t = (remain - 5) / 5
		return 1, 1, t, 1
	else
		local t = remain / 5
		return 1, t, 0, 1
	end
end

local function SortTimeline()
	table.sort(timeline, function(a, b)
		return a.endTime < b.endTime
	end)
end

local function AddTimelineBar(text, timer, icon, key, module)
	if type(timer) ~= "number" or timer <= 0 then
		return
	end
	local now = GetTime()
	key = key or text
	-- 注意: 同 key 重复开条一律视为"重置/刷新"（与横向条 CandyBar 重开即重置的行为一致）。
	-- 曾有"同 key、同时长、仍在进行中就忽略"的 EasyDBM 式去重，会导致重置型条
	--（如奴役恶魔重新奴役、Boss 技能刷新）永远不刷新剩余时间，已移除。
	-- 同 key：视为重启/刷新，原地更新结束时间（也保证不会产生重复条目）
	for _, entry in ipairs(timeline) do
		if entry.key == key then
			entry.start = now
			entry.dur = timer
			entry.endTime = now + timer
			entry.text = text
			entry.icon = icon or entry.icon
			entry.module = module or entry.module
			SortTimeline()
			return
		end
	end
	table.insert(timeline, {
		text = text,
		icon = icon or DEFAULT_ICON,
		key = key,
		start = now,
		dur = timer,
		endTime = now + timer,
		module = module,
	})
	SortTimeline()
end

-- keepShort: 剩余 <= 2 秒的残条不删，让它自然下落到期。
-- 原因：多数 boss 模块在「开始施放」时先 RemoveBar(旧冷却条) 再开读条条
--（如 BWL 三龙 WingBuffet：RemoveBar("龙翼打击冷却") → Bar("正在施放龙翼打击！",1)
-- → DelayedBar(1, "龙翼打击冷却", 29)）。此时旧冷却条通常只剩 1~3 秒（1s 读条 + 29s CD = 30s 循环），
-- 一刀切掉会让竖行条瞬间失去该条；若场上只有这一条，timeline 变空 → 整个锚点隐藏，
-- 表现就是「剩几秒时竖行条突然消失，1 秒后才重新冒出来」。
-- 保留残条后：它自然走到底，同一时刻 DelayedBar 开出的同 key 新条会原地刷新它，无缝衔接。
local function RemoveTimelineBarByKey(key, keepShort)
	local now = GetTime()
	for i = table.getn(timeline), 1, -1 do
		local entry = timeline[i]
		if entry.key == key then
			local remain = entry.endTime - now
			if keepShort and remain <= 2 and remain > 0 then
				-- 残条：保留，交给过期清理 / 同 key 刷新
			else
				table.remove(timeline, i)
			end
		end
	end
end

-- 模块 Disengage（boss 击杀/团灭重置）时收掉该模块在竖行条里的全部条。
-- 奴役恶魔/大恶魔叛变条属于 CommonAuras（非 boss 模块，永不 Disengage），不受影响。
local function RemoveTimelineBarsByModule(module)
	if not module then
		return
	end
	for i = table.getn(timeline), 1, -1 do
		if timeline[i].module == module then
			table.remove(timeline, i)
		end
	end
end

local function WipeTimeline()
	for i = table.getn(timeline), 1, -1 do
		table.remove(timeline, i)
	end
end

------------------------------
-- Icon frames
------------------------------

local function CreateIconFrame(self)
	local f = CreateFrame("Frame", nil, self.frames.anchor)
	f:SetWidth(self.db.profile.iconSize)
	f:SetHeight(self.db.profile.iconSize)

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetAllPoints(f)
	f.icon:SetTexture(DEFAULT_ICON)

	f.autocastAnim = f:CreateTexture(nil, "OVERLAY")
	f.autocastAnim:SetTexture(OVERLAY_TEX)
	f.autocastAnim:SetWidth(self.db.profile.iconSize * 1.7)
	f.autocastAnim:SetHeight(self.db.profile.iconSize * 1.7)
	f.autocastAnim:SetPoint("CENTER", f, "CENTER")
	f.autocastAnim:SetBlendMode("ADD")
	f.autocastAnim:Hide()

	f.cooldown = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.cooldown:SetPoint("CENTER", f, "CENTER")
	f.cooldown:SetJustifyH("CENTER")
	f.cooldown:SetJustifyV("MIDDLE")
	f.cooldown:SetFont(FONT, math.floor(self.db.profile.iconSize * 0.45), "OUTLINE")
	f.cooldown:SetTextColor(1, 1, 1, 1)

	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.text:SetFont(FONT, 13, "OUTLINE")
	-- 名称方向：左侧时文字右对齐贴在图标左边，右侧时文字左对齐贴在图标右边
	if (self.db.profile.labelSide or "right") == "left" then
		f.text:SetPoint("RIGHT", f, "LEFT", -6, 0)
		f.text:SetJustifyH("RIGHT")
	else
		f.text:SetPoint("LEFT", f, "RIGHT", 6, 0)
		f.text:SetJustifyH("LEFT")
	end

	-- 点击图标播报倒计时（对齐横向条 Bars.lua 的 OnBarClick 原逻辑）：
	-- ctrl+左键 → 团队警报（RAID_WARNING）；shift+左键 → 团队/战场频道
	-- this.data 由 DrawIcon 每帧绑定，点击时取当帧条目再实时算剩余秒数
	f:EnableMouse(true)
	f.data = nil
	f:SetScript("OnMouseUp", function()
		local data = this.data
		if not data or not data.text then
			return
		end
		local remain = data.endTime - GetTime()
		if remain <= 0 then
			return
		end
		local msg = data.text .. " in " .. SecondsToTime(math.floor(remain))
		if IsControlKeyDown() then
			SendChatMessage(msg, "RAID_WARNING")
		elseif IsShiftKeyDown() then
			SendChatMessage(msg, "RAID")
			SendChatMessage(msg, "BATTLEGROUND")
		end
	end)
	f:SetScript("OnEnter", function()
		local data = this.data
		if not data or not data.text then
			return
		end
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(data.text)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	f:Hide()
	return f
end

local function GetIcon(self, i)
	if not iconPool[i] then
		iconPool[i] = CreateIconFrame(self)
	end
	return iconPool[i]
end

------------------------------
-- Rendering（单列三段，option C）
-- 长冷却区（>TRACK_CAP=40s）：轨道上方独立区，按真实剩余时间排序，
--   最先进入轨道的贴着轨道顶，最多 maxIcons 个
-- 等待区（轨道上半段 40s→10s）：压缩显示
-- 下落区（轨道下半段 10s→0）：精确下落，位置 = 剩余时间线性映射
-- 所有图标始终在轨道列内
------------------------------

local TRACK_CAP = 40   -- 轨道顶对应的剩余秒数
local FALL_AT = 10     -- 10s 以下为精确下落段（下半段）
local QUEUE_GAP = 6    -- 等待堆叠最小间距
local LABEL_W = 150    -- 名称文字区预留宽度（决定锚点总宽）

-- 剩余时间 → 图标中心相对锚点顶部的 y 偏移（向下为负）
-- 上半段 40s→10s 占 trackH/2，下半段 10s→0 占 trackH/2
local function TimeToY(remain, trackH, iconSize)
	local half = trackH / 2
	local span = half - iconSize / 2
	if remain >= FALL_AT then
		local t = (remain - FALL_AT) / (TRACK_CAP - FALL_AT)
		if t < 0 then t = 0 end
		if t > 1 then t = 1 end
		return -(half - t * span)
	else
		local t = (FALL_AT - remain) / FALL_AT
		if t > 1 then t = 1 end
		return -(half + t * span)
	end
end

function BigWigsVerticalBars:UpdateAllIcons()
	if not self.frames.anchor or not self.db.profile.enabled then
		return
	end
	local db = self.db.profile
	local iconSize = db.iconSize
	local trackH = db.trackHeight
	local maxWait = db.maxIcons
	local now = GetTime()

	-- 图标与轨道背景/刻度线共用同一 x（ApplyLayout 里的 anchor.trackX），
	-- 保证图标始终居中在轨道内
	local x_track = self.frames.anchor.trackX or 25

	-- 过期清理
	for i = table.getn(timeline), 1, -1 do
		if timeline[i].endTime <= now then
			table.remove(timeline, i)
		end
	end

	-- 分桶：长冷却(>TRACK_CAP) / 等待(10s<remain<=TRACK_CAP) / 下落(<=FALL_AT)
	local longList, waiting, falling = {}, {}, {}
	for _, data in ipairs(timeline) do
		local r = data.endTime - now
		if r > TRACK_CAP then
			table.insert(longList, data)
		elseif r > FALL_AT then
			table.insert(waiting, data)
		else
			table.insert(falling, data)
		end
	end
	table.sort(longList, function(a, b) return a.endTime < b.endTime end)  -- 最先进入轨道的在前
	table.sort(waiting, function(a, b) return a.endTime < b.endTime end)
	table.sort(falling, function(a, b) return a.endTime < b.endTime end)
	-- 超限只保留最紧迫的 maxWait 个
	while table.getn(longList) > maxWait do
		table.remove(longList)   -- 列表尾 = 最晚进入轨道，丢弃
	end
	-- 超限丢弃最晚到期的（列表尾），与 longList 的取舍一致：宁可少显示一个还很远的技能，
	-- 也不能把马上要到的条砍掉。原先这里是 table.remove(waiting, 1)——删的正是最先到期那条，
	-- 等于等待区一满就先丢掉最紧迫的条目。
	while table.getn(waiting) > maxWait do
		table.remove(waiting)
	end

	-- 长冷却区高度按实际长条数量动态收缩：无长条时为 0（不占空轨道），
	-- 有几个长条才占相应高度（上限 maxWait 格），避免一截空轨道拉长整体
	local longZoneH = table.getn(longList) * (iconSize + QUEUE_GAP)
	local trackTopY = -longZoneH   -- 下落轨道顶（40s 刻度）相对锚点顶的 y

	-- 长条数量变化时再调整锚点/背景/热区高度与分隔线位置，避免每帧重复 SetHeight
	if self._longZoneH ~= longZoneH then
		self._longZoneH = longZoneH
		local anchor = self.frames.anchor
		local totalH = longZoneH + trackH + 8
		anchor:SetHeight(totalH)
		anchor.pathBG:SetHeight(totalH)
		anchor.pathBG:ClearAllPoints()
		anchor.pathBG:SetPoint("TOPLEFT", anchor, "TOPLEFT", x_track, 0)
		anchor.trackHit:SetHeight(totalH)
		anchor.trackHit:ClearAllPoints()
		anchor.trackHit:SetPoint("TOPLEFT", anchor, "TOPLEFT", x_track, 0)
		if anchor.sepLine then
			if table.getn(longList) > 0 then
				anchor.sepLine:Show()
				anchor.sepLine:SetPoint("CENTER", anchor, "TOPLEFT", x_track + iconSize / 2, -longZoneH)
			else
				anchor.sepLine:Hide()
			end
		end
	end

	local function DrawIcon(slot, data, y, curScale)
		local remain = data.endTime - now
		local iconFrame = GetIcon(self, slot)
		iconFrame:ClearAllPoints()
		iconFrame:SetScale(curScale)
		iconFrame:SetPoint("CENTER", self.frames.anchor, "TOPLEFT",
			(x_track + iconSize / 2) / curScale,
			y / curScale)
		iconFrame:Show()
		iconFrame.icon:SetTexture(data.icon or DEFAULT_ICON)
		iconFrame.data = data

		local fontSize = math.floor(iconSize * curScale * 0.45)
		iconFrame.cooldown:SetFont(FONT, fontSize, "OUTLINE")
		iconFrame.cooldown:SetText(TimeLeftText(remain))
		local r, g, b, a = RemainColor(remain)
		iconFrame.cooldown:SetTextColor(r, g, b, a)

		if remain <= 5 then
			-- 1.12 没有 SetRotation，用透明度脉冲模拟特效圈闪烁
			-- 尺寸除以 curScale：图标本体在 5s 内被放大到 1.3 倍，特效圈如果也跟着乘，
			-- 实际显示会是 1.7×1.3 ≈ 2.2 倍，多个条同时进 5 秒区时圈会互相盖住相邻图标。
			-- 这里归一成恒定的 1.7 倍图标尺寸，只保留闪烁做紧迫感。
			local ringSize = iconSize * 1.7 / curScale
			iconFrame.autocastAnim:SetWidth(ringSize)
			iconFrame.autocastAnim:SetHeight(ringSize)
			iconFrame.autocastAnim:Show()
			local pulse = 0.55 + 0.45 * math.abs(math.sin(now * 4))
			iconFrame.autocastAnim:SetAlpha(pulse)
		else
			iconFrame.autocastAnim:Hide()
		end

		if db.showLabels then
			iconFrame.text:SetText(data.text or "?")
		else
			iconFrame.text:SetText("")
		end
	end

	local count = 0

	-- 下落区（下半段）：位置对应剩余时间，10s 在轨道中点，0 在轨道底。
	-- 但默认轨道 300px 里 10s→0 只摊开约 134px，等于每秒仅 13.4px，而图标直径 32px
	--（5s 内放大到 1.3 倍 = 41.6px）：两个技能相差 2.4s（放大态 3.1s）以内必然叠在一起。
	-- 因此这里和等待区一样做最小间距推挤——拥挤时宁可让「位置=时间」的线性略微偏移，
	-- 也不让两个图标互相压住；条少时会自动回到纯线性下落，观感不变。
	local prevY, prevScale = nil, 1
	for i = 1, table.getn(falling) do
		local data = falling[i]
		local remain = data.endTime - now
		count = count + 1
		local curScale = (remain <= 5) and 1.3 or 1
		local y = trackTopY + TimeToY(remain, trackH, iconSize)
		if prevY then
			-- 间距取相邻两条中较大的那个尺寸（放大态占位更宽）
			local gap
			if curScale > prevScale then
				gap = iconSize * curScale + 2
			else
				gap = iconSize * prevScale + 2
			end
			if y < prevY + gap then
				y = prevY + gap
			end
		end
		-- 兜底：条多到队列被推到 10s 刻度以上时压在轨道顶，不越界去盖等待区
		if y > trackTopY then
			y = trackTopY
		end
		prevY, prevScale = y, curScale
		DrawIcon(count, data, y, curScale)
	end

	-- 等待区（轨道上半段 40s→10s）：按剩余时间排布，从 40s 刻度向上堆叠，
	-- 保证不重叠且不超出轨道顶
	local minGap = (trackH / 2 - iconSize / 2) / math.max(maxWait - 1, 1)
	if minGap > iconSize + QUEUE_GAP then
		minGap = iconSize + QUEUE_GAP
	end
	local prevY = nil
	-- 必须按 1→n（最先到期者先处理）迭代：先到期的占最靠下的自然位置，
	-- 后处理（剩余更长）的图标若与前者太挤才被向上推保持间距。
	-- 若反过来从 n→1，钳制条件会把剩余短的强推到剩余长的上方，顺序整体反转。
	for i = 1, table.getn(waiting) do
		local data = waiting[i]
		local remain = data.endTime - now
		count = count + 1
		local y = trackTopY + TimeToY(remain, trackH, iconSize)
		if prevY then
			-- 必须在前一个（更先将到期）图标的上方，保持最小间距
			if y < prevY + minGap then
				y = prevY + minGap
			end
		end
		-- 不超出轨道顶（40s 刻度处）
		if y > trackTopY + iconSize / 2 then
			y = trackTopY + iconSize / 2
		end
		prevY = y
		DrawIcon(count, data, y, 1)
	end

	-- 长冷却区（轨道上方独立区）：按真实剩余时间排序，最先进入轨道的贴着轨道顶，
	-- 依次向上排；不再用 minGap 推挤，顺序恒等于真实倒计时顺序（option C）
	for i = 1, table.getn(longList) do
		local data = longList[i]
		local remain = data.endTime - now
		count = count + 1
		local y = trackTopY + iconSize / 2 + QUEUE_GAP / 2 + (i - 1) * (iconSize + QUEUE_GAP)
		DrawIcon(count, data, y, 1)
	end

	-- 隐藏多余图标池
	for i = count + 1, table.getn(iconPool) do
		if iconPool[i] then
			iconPool[i]:Hide()
		end
	end

	-- 全部条到期后自动隐藏锚点（EasyDBM 行为）
	self:RefreshShownState()
end

------------------------------
-- Anchor frame
------------------------------

function BigWigsVerticalBars:ApplyLayout()
	local db = self.db.profile
	if not self.frames.anchor then
		return
	end
	local anchor = self.frames.anchor
	local iconSize = db.iconSize
	local trackH = db.trackHeight
	-- 名称方向决定轨道在锚点内的横向位置：
	-- 右侧 → 轨道贴锚点左边（25px 余量），名称向右展开；
	-- 左侧 → 轨道右移 LABEL_W，名称向左展开，整块仍落在锚点内（热区/拖动范围一致）
	local labelSide = db.labelSide or "right"
	local oldTrackX = anchor.trackX
	local x
	if labelSide == "left" then
		x = 25 + LABEL_W
		anchor:SetWidth(x + iconSize + 25)
	else
		x = 25
		anchor:SetWidth(x + iconSize + LABEL_W)
	end
	anchor.trackX = x  -- UpdateAllIcons 用同一 x 定位图标，保证居中在轨道内

	-- 名称方向切换会改变轨道在锚点内的偏移：反向平移锚点，
	-- 让轨道在屏幕上的位置不动（只让名称换边），避免切一次方向整条竖条跳一下
	if oldTrackX and oldTrackX ~= x and anchor:GetLeft() then
		local left, top = anchor:GetLeft(), anchor:GetTop()
		anchor:ClearAllPoints()
		anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left - (x - oldTrackX), top)
		self:SavePosition()
	end

	-- 长冷却区占锚点顶部 longZoneH，下落轨道整体下移；锚点总高 = 长冷却区 + 轨道 + 底部余量
	local longZoneH = db.maxIcons * (iconSize + QUEUE_GAP)
	anchor:SetHeight(longZoneH + trackH + 8)

	-- 锁定按钮（悬停可见，置于最顶部）
	anchor.lockBtn:SetWidth(iconSize)
	anchor.lockBtn:SetHeight(18)
	anchor.lockBtn:ClearAllPoints()
	anchor.lockBtn:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)

	-- 轨道背景：覆盖整列（长冷却区 + 等待区 + 下落区）
	local totalH = longZoneH + trackH + 8
	anchor.pathBG:SetWidth(iconSize)
	anchor.pathBG:SetHeight(totalH)
	anchor.pathBG:ClearAllPoints()
	anchor.pathBG:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)

	-- 轨道鼠标热区（与轨道背景重合）
	anchor.trackHit:SetWidth(iconSize)
	anchor.trackHit:SetHeight(totalH)
	anchor.trackHit:ClearAllPoints()
	anchor.trackHit:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, 0)

	-- 长冷却区 / 下落轨道 分隔线（位于剩余 = TRACK_CAP 处）
	if anchor.sepLine then
		anchor.sepLine:SetWidth(iconSize)
		anchor.sepLine:ClearAllPoints()
		anchor.sepLine:SetPoint("CENTER", anchor, "TOPLEFT", x + iconSize / 2, -longZoneH)
	end

	-- 重建图标池（尺寸/名称方向变化）：旧框先隐藏再丢弃，
	-- 否则它们仍挂在锚点下且保持 Show 状态，会留下换边前的幽灵图标与旧方向文字
	for i in pairs(iconPool) do
		if iconPool[i] then
			iconPool[i]:Hide()
		end
		iconPool[i] = nil
	end
	-- 尺寸变化后重置动态长冷却区高度缓存，下一帧 UpdateAllIcons 会按实际长条数重算
	self._longZoneH = nil
end

function BigWigsVerticalBars:UpdateLockState()
	local db = self.db.profile
	if not self.frames.anchor then
		return
	end
	local anchor = self.frames.anchor
	local lockBtn = anchor.lockBtn
	if db.locked then
		anchor:EnableMouse(false)
		anchor.trackHit:EnableMouse(false)
		lockBtn:SetBackdropColor(0.7, 0.2, 0.2, 0.85)
		lockBtn:SetBackdropBorderColor(1, 0.5, 0.5, 1)
		lockBtn.text:SetText(L["Locked"])
	else
		anchor:EnableMouse(true)
		anchor.trackHit:EnableMouse(true)
		lockBtn:SetBackdropColor(0.2, 0.7, 1, 0.7)
		lockBtn:SetBackdropBorderColor(0.2, 0.7, 1, 0.9)
		lockBtn.text:SetText(L["Draggable"])
	end
end

function BigWigsVerticalBars:SavePosition()
	if not self.frames.anchor then
		return
	end
	local s = self.frames.anchor:GetEffectiveScale()
	self.db.profile.posx = self.frames.anchor:GetLeft() * s
	self.db.profile.posy = self.frames.anchor:GetTop() * s
end

function BigWigsVerticalBars:RestorePosition()
	if not self.frames.anchor then
		return
	end
	local db = self.db.profile
	local f = self.frames.anchor
	local s = f:GetEffectiveScale()
	f:ClearAllPoints()
	if db.posx and db.posy then
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.posx / s, db.posy / s)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
	end
end

function BigWigsVerticalBars:ResetAnchor()
	self.db.profile.posx = nil
	self.db.profile.posy = nil
	if self.frames.anchor then
		self.frames.anchor:ClearAllPoints()
		self.frames.anchor:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
	end
end

-- 按需显示：竖行条启用且轨道上有进行中的计时条时才显示锚点，
-- 没有任何条时整体隐藏（与 EasyDBM 一致，进团队不会空轨道挂着）。
function BigWigsVerticalBars:RefreshShownState()
	local db = self.db.profile
	if not self.frames.anchor then
		return
	end
	if db.enabled and table.getn(timeline) > 0 then
		self.frames.anchor:Show()
	else
		self.frames.anchor:Hide()
	end
end

function BigWigsVerticalBars:UpdateVisibility()
	local db = self.db.profile
	self:RefreshShownState()
	-- 竖行条启用时停掉原版计时条；关闭后新的计时条会自动恢复显示
	if db.enabled and type(BigWigsBars) == "table" and type(BigWigsBars.StopAllBars) == "function" then
		BigWigsBars:StopAllBars()
	end
end

function BigWigsVerticalBars:SetupFrames()
	if self.frames.anchor then
		return
	end
	local db = self.db.profile
	local iconSize = db.iconSize
	local x = 25  -- 轨道在锚点内偏左，右侧留名称空间（与 ApplyLayout 一致）

	local anchor = CreateFrame("Frame", "BigWigsVerticalBarAnchor", UIParent)
	anchor:SetFrameStrata("MEDIUM")
	anchor:SetWidth(db.iconSize + 100)
	anchor:SetHeight(db.trackHeight)
	anchor:SetMovable(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:EnableMouse(not db.locked)
	anchor:SetPoint("CENTER", UIParent, "CENTER", 400, 0)

	anchor:SetScript("OnDragStart", function()
		if not BigWigsVerticalBars.db.profile.locked then
			this:StartMoving()
		end
	end)
	anchor:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		BigWigsVerticalBars:SavePosition()
	end)
	anchor:SetScript("OnHide", function()
		this:StopMovingOrSizing()
	end)

	-- 锁定按钮（悬停可见，点击切换锁定）
	local lockBtn = CreateFrame("Button", nil, anchor)
	lockBtn:SetFrameLevel(3)
	lockBtn:SetBackdrop({
		bgFile = WHITE,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
	})
	lockBtn:SetAlpha(0)
	lockBtn.text = lockBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lockBtn.text:SetPoint("CENTER", lockBtn, "CENTER")
	lockBtn.text:SetFont(FONT, 13, "OUTLINE")
	lockBtn:SetScript("OnClick", function()
		if arg1 == "LeftButton" then
			local db = BigWigsVerticalBars.db.profile
			db.locked = not db.locked
			BigWigsVerticalBars:UpdateLockState()
			if db.locked then
				BigWigs:Print(L["Bar position locked"])
			else
				BigWigs:Print(L["Bar unlocked, can be dragged"])
			end
		end
	end)
	lockBtn:SetScript("OnEnter", function()
		this:SetAlpha(0.92)
		GameTooltip:SetOwner(this, "ANCHOR_TOP")
		GameTooltip:SetText(BigWigsVerticalBars.db.profile.locked and L["Click to unlock, you can drag the bar"] or L["Click to lock, forbid dragging"])
		GameTooltip:Show()
	end)
	lockBtn:SetScript("OnLeave", function()
		this:SetAlpha(0)
		GameTooltip:Hide()
	end)

	-- 竖轨背景
	local pathBG = anchor:CreateTexture(nil, "BACKGROUND")
	pathBG:SetTexture(WHITE)
	pathBG:SetVertexColor(0.0588, 0.0588, 0.0588, 0.8)

	-- 轨道鼠标热区：1.12 的 Texture 没有 EnableMouse/鼠标事件，
	-- 用一个透明 Frame 覆盖轨道来捕获拖动与右键
	local trackHit = CreateFrame("Frame", nil, anchor)
	trackHit:EnableMouse(true)
	trackHit:SetFrameLevel(2)

	-- 长冷却区 / 下落轨道 分隔线
	local sepLine = anchor:CreateTexture(nil, "OVERLAY")
	sepLine:SetTexture(WHITE)
	sepLine:SetVertexColor(0.6, 0.6, 0.6, 0.7)
	sepLine:SetWidth(iconSize)
	sepLine:SetHeight(1)
	sepLine:SetPoint("CENTER", anchor, "TOPLEFT", x + iconSize / 2, 0)
	trackHit:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" and not BigWigsVerticalBars.db.profile.locked then
			anchor:StartMoving()
		end
	end)
	trackHit:SetScript("OnMouseUp", function()
		anchor:StopMovingOrSizing()
		BigWigsVerticalBars:SavePosition()
		if arg1 == "RightButton" then
			local db = BigWigsVerticalBars.db.profile
			db.bgVisible = not db.bgVisible
			pathBG:SetAlpha(db.bgVisible and 1 or 0.05)
			if db.bgVisible then
				BigWigs:Print(L["Background shown"])
			else
				BigWigs:Print(L["Background hidden (right-click the track to show again)"])
			end
		end
	end)

	self.frames.anchor = anchor
	anchor.lockBtn = lockBtn
	anchor.pathBG = pathBG
	anchor.trackHit = trackHit
	anchor.sepLine = sepLine

	if not db.bgVisible then
		pathBG:SetAlpha(0.05)
	end

	self:ApplyLayout()
	self:UpdateLockState()
	self:RestorePosition()

	anchor:SetScript("OnUpdate", function()
		BigWigsVerticalBars:UpdateAllIcons()
	end)

	self:RefreshShownState()
end

------------------------------
-- Test
------------------------------

function BigWigsVerticalBars:RunTest()
	if testRunning then
		testRunning = false
		if testBars then
			for i = 1, table.getn(testBars) do
				RemoveTimelineBarByKey(testBars[i])
			end
		end
		testBars = nil
		return
	end
	testRunning = true
	testBars = {
		"VBTestA",
		"VBTestB",
		"VBTestC",
		"VBTestD",
	}
	AddTimelineBar("测试技能 A", 20, "Interface\\Icons\\Spell_Frost_FrostBolt", testBars[1])
	AddTimelineBar("测试技能 B", 30, "Interface\\Icons\\Spell_Fire_FlameBolt", testBars[2])
	AddTimelineBar("测试技能 C", 40, "Interface\\Icons\\Spell_Nature_WispSplode", testBars[3])
	AddTimelineBar("长冷却 恶魔叛变", 120, "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", testBars[4])
	-- 空轨道时锚点是隐藏的，测试要主动唤起（也可借此拖动定位）
	self:RefreshShownState()
end

------------------------------
-- Event Handlers
------------------------------

function BigWigsVerticalBars:OnEnable()
	self.frames = {}
	self:RegisterEvent("BigWigs_StartBar")
	self:RegisterEvent("BigWigs_StopBar")
	self:RegisterEvent("BigWigs_StopBars")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		WipeTimeline()
		testRunning = false
		testBars = nil
		BigWigsVerticalBars:RefreshShownState()
	end)
	-- 注意: 不要在 PLAYER_REGEN_ENABLED(脱战)时 WipeTimeline——
	-- 会把跨战斗的长条(奴役恶魔/召唤叛变等)清掉且永不恢复; 条到期由 OnUpdate 自动移除
	self:SetupFrames()
	self:UpdateVisibility()
end

function BigWigsVerticalBars:OnDisable()
	if self.frames.anchor then
		self.frames.anchor:Hide()
	end
end

function BigWigsVerticalBars:BigWigs_StartBar(module, text, time, icon, otherc, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, emphasize, target, spell)
	if not self.db.profile.enabled then
		return
	end
	if target then
		return
	end
	if not text or type(time) ~= "number" or time <= 0 then
		return
	end
	AddTimelineBar(text, time, icon, text, module)
	-- 锚点隐藏时 OnUpdate 不跑，新条进来要主动唤起显示
	self:RefreshShownState()
end

function BigWigsVerticalBars:BigWigs_StopBar(module, text)
	if not text then
		return
	end
	-- keepShort = true：不掐断只剩 1~2 秒的条（见 RemoveTimelineBarByKey 注释），
	-- 避免「冷却条剩几秒 → 模块开读条条前先删冷却条 → 竖行条瞬隐再重冒」
	RemoveTimelineBarByKey(text, true)
	self:RefreshShownState()
end

-- 模块 Disengage（boss 击杀/团灭重置）时核心广播 BigWigs_StopBars(module):
-- 横条由 BigWigsBars:Disable 直接清,竖行条此前收不到信号,boss 的激怒/狂暴/残杀
-- 等条在战斗结束后会一直挂到自然到期（与 9-29 移除"脱战清屏"前的兜底行为对齐,
-- 但只清死亡/团灭 boss 自己的条,不再误伤跨战斗长条）
function BigWigsVerticalBars:BigWigs_StopBars(module)
	RemoveTimelineBarsByModule(module)
	self:RefreshShownState()
end

------------------------------
-- Slash command
------------------------------

SLASH_BIGWIGSVERTICAL1 = "/bwv"
SlashCmdList["BIGWIGSVERTICAL"] = function(msg)
	msg = string.lower(msg or "")
	if msg == "test" then
		BigWigsVerticalBars:RunTest()
		return
	end
	-- /bwv left | /bwv right：快速切换技能名称方向（等同选项里的「名称方向」）
	if msg == "left" or msg == "right" then
		BigWigsVerticalBars.db.profile.labelSide = msg
		BigWigsVerticalBars:ApplyLayout()
		BigWigsVerticalBars:UpdateAllIcons()
		BigWigs:Print(string.format(L["Label side is now %s"],
			(msg == "left") and L["Left"] or L["Right"]))
		return
	end
	local db = BigWigsVerticalBars.db.profile
	db.enabled = not db.enabled
	BigWigsVerticalBars:UpdateVisibility()
	if db.enabled then
		BigWigs:Print(L["Vertical bar enabled"])
	else
		BigWigs:Print(L["Vertical bar disabled"])
	end
end
