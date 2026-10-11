--========================================================================
-- RaidCheck BUFF分配模块（参考 HDLRaidTools 移植）
-- 入口：/rc 打开检查窗口，点左上角「分配」按钮；或直接 /rcb
-- 功能：耐力/智力/爪子按小队自动分配、诅咒/坦克手动分配、
--       骑士祝福分配（点击图标换祝福，右键整行统一）、
--       骑士祝福分配（点击图标换祝福，右键整行统一），默认分配以 HDLRaidTools 为准，
--       团队通报（走主窗口所选频道）、补BUFF检查（密语通知加BUFF人员）、
--       密语监控（团友密语 buff 触发检查，60秒CD，需团长/助理）
-- 说明：分配数据为会话内保存（不写 SavedVariables），进本后点一次「自动分配」即可；
--       任务分配的内容通过 SavedVariables（RCBA_TaskDB）持久保存，下次打开可修改后再通报；
--       全部分配数据（耐力/智力/爪子/诅咒/坦克/骑士祝福/坦克高级）经 RCBA_AssignDB
--       每 2 秒自动快照，/rl 或重登后自动恢复
--========================================================================

-- 职业顺序与 RaidCheck 主模块一致（LOCALCLASS1-9）
local ClassNames = {"战士","盗贼","法师","猎人","牧师","圣骑士","德鲁伊","术士","萨满祭司"}
local classIndexMap = {}
for i = 1, 9 do
	classIndexMap[ClassNames[i]] = i
end

-- 祝福编号：1智慧 2力量 3拯救 4光明 5王者 6庇护（与 HDL_BlessingIcon 编号一致）
-- 注意：必须用显式键写法。若写成 {"", "智慧祝福", ...} 数组字面量，"" 会占用 [1]，
-- 导致全部名字相对编号错位 +1（图标对、名字错位的根源）
local BlessingNames = {
	[0] = "",
	[1] = "智慧祝福",
	[2] = "力量祝福",
	[3] = "拯救祝福",
	[4] = "光明祝福",
	[5] = "王者祝福",
	[6] = "庇护祝福",
}
local BlessingIcons = {
	[0] = "",
	[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom",
	[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",
	[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation",
	[4] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight",
	[5] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",
	[6] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary",
}
-- 统一设置图标纹理（所有更新点必须走这里）
local function RCBA_SetIcon(btn, v)
	if not btn or not btn.tex then return end
	btn.tex:SetTexture(BlessingIcons[v] or "")
end
-- 补BUFF检测用图标（小祝福/大祝福 两种都算已有）
local CheckIcons = {
	["智慧祝福"] = {"Interface\\Icons\\Spell_Holy_SealOfWisdom", "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"},
	["力量祝福"] = {"Interface\\Icons\\Spell_Holy_FistOfJustice", "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"},
	["拯救祝福"] = {"Interface\\Icons\\Spell_Holy_SealOfSalvation", "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"},
	["光明祝福"] = {"Interface\\Icons\\Spell_Holy_PrayerOfHealing02", "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"},
	["王者祝福"] = {"Interface\\Icons\\Spell_Magic_MageArmor", "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"},
	["庇护祝福"] = {"Interface\\Icons\\Spell_Nature_LightningShield", "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"},
	["智力"]     = {"Interface\\Icons\\Spell_Holy_MagicalSentry", "Interface\\Icons\\Spell_Holy_ArcaneIntellect"},
	["耐力"]     = {"Interface\\Icons\\Spell_Holy_WordFortitude", "Interface\\Icons\\Spell_Holy_PrayerOfFortitude"},
	["爪子"]     = {"Interface\\Icons\\Spell_Nature_Regeneration", "Interface\\Icons\\Spell_Nature_Regeneration"},
}
-- 职业图标：与 ShaguDPS 同款 classicons.blp 图集（256x256，8列x8行网格）
-- 每职业为纹理坐标 {left, right, top, bottom}，顺序与 ClassNames 一致（战贼法猎牧骑德术萨）
local ClassIconTexture = "Interface\\AddOns\\RaidCheck\\Icons\\classicons"
local ClassTex = {
	[1] = { 0.000, 0.122, 0.000, 0.123 },  -- 战士
	[2] = { 0.250, 0.372, 0.000, 0.123 },  -- 盗贼
	[3] = { 0.125, 0.247, 0.000, 0.123 },  -- 法师
	[4] = { 0.000, 0.122, 0.125, 0.248 },  -- 猎人
	[5] = { 0.250, 0.372, 0.125, 0.248 },  -- 牧师
	[6] = { 0.000, 0.122, 0.250, 0.373 },  -- 圣骑士
	[7] = { 0.375, 0.497, 0.000, 0.123 },  -- 德鲁伊
	[8] = { 0.373, 0.504, 0.121, 0.238 },  -- 术士
	[9] = { 0.125, 0.247, 0.125, 0.248 },  -- 萨满祭司
}
-- 默认骑士祝福分配：照抄 HDLRaidTools 的 HDLUI.DefaultBlessing（HDLBUFF.lua:10-50），
-- 但 HDL 列顺序为 战/贼/牧/德/骑/猎/法/术/萨，本插件为 战/贼/法/猎/牧/骑/德/术/萨，
-- 已按列换算：our[c] = hdl{1,2,7,6,3,5,4,8,9}
local DefaultBlessing = {
	[1] = { {3,3,3,3,1,1,1,3,1} },
	[2] = { {3,3,3,3,1,1,1,3,1}, {5,5,5,5,5,5,5,5,5} },
	[3] = { {3,3,3,3,3,3,3,3,3}, {5,5,5,5,5,5,5,5,5}, {2,2,1,1,1,1,1,1,1} },
	[4] = { {3,3,3,3,3,3,3,3,3}, {5,5,5,5,5,5,5,5,5}, {2,2,0,0,0,2,2,0,2}, {0,0,1,1,1,1,1,1,1} },
	[5] = { {3,3,3,3,3,3,3,3,3}, {5,5,5,5,5,5,5,5,5}, {2,2,0,0,0,2,2,0,2}, {0,0,1,1,1,1,1,1,1}, {4,4,4,4,4,4,4,4,4} },
	[6] = { {3,3,3,3,3,3,3,3,3}, {5,5,5,5,5,5,5,5,5}, {2,2,0,0,0,2,2,0,2}, {0,0,1,1,1,1,1,1,1}, {4,4,4,4,4,4,4,4,4}, {6,6,6,6,6,6,6,6,6} },
}
--========================================================================
-- 各职业需要检查的BUFF（顺序与 ClassNames 一致）
local ClassBuffNeed = {
	[1] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","力量祝福"},
	[2] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","力量祝福"},
	[3] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","智慧祝福","智力"},
	[4] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","智慧祝福","智力"},
	[5] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","智慧祝福","智力"},
	[6] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","力量祝福","智慧祝福","智力"},
	[7] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","力量祝福","智慧祝福","智力"},
	[8] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","智慧祝福","智力"},
	[9] = {"拯救祝福","光明祝福","王者祝福","耐力","爪子","力量祝福","智慧祝福","智力"},
}

------------------------------------------------------------------------
-- 数据
------------------------------------------------------------------------
local List = {
	Fortitude = {Nums = 0, Names = {}},   -- 真言术：韧（牧师） 8队
	Intellect = {Nums = 0, Names = {}},   -- 奥术智慧（法师） 8队
	WildMark  = {Nums = 0, Names = {}},   -- 野性印记（德鲁伊） 8队
	Curse     = {Nums = 0, Names = {}},   -- 诅咒（术士） 4个
	Tank      = {Nums = 0, Names = {}},   -- 坦克 4个
	Blessing  = {Nums = 0, Names = {}, paladinBlessing = {}},
}
for i = 1, 8 do
	List.Fortitude[i] = ""
	List.Intellect[i] = ""
	List.WildMark[i] = ""
end
for i = 1, 4 do
	List.Curse[i] = ""
	List.Tank[i] = ""
end

------------------------------------------------------------------------
-- 通用函数
------------------------------------------------------------------------
local function GetClassN(class)
	local num = 0
	local names = {}
	-- 支持传单个职业字符串或职业表（如坦克槽：战士/德鲁伊/萨满祭司/圣骑士，
	-- 职业名必须与 GetRaidRosterInfo 返回的完整名一致，萨满须写「萨满祭司」）
	local multi = nil
	if type(class) == "table" then
		multi = class
		class = nil
	end
	for i = 1, GetNumRaidMembers() do
		local name, _, _, _, c = GetRaidRosterInfo(i)
		local hit = false
		if name then
			if multi then
				for k = 1, table.getn(multi) do
					if c == multi[k] then
						hit = true
						break
					end
				end
			else
				hit = (c == class)
			end
		end
		if name and hit then
			num = num + 1
			table.insert(names, name)
		end
	end
	return num, names
end

local function GetGroupN()
	local has = {}
	local count = 0
	for i = 1, GetNumRaidMembers() do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if subgroup and not has[subgroup] then
			has[subgroup] = true
			count = count + 1
		end
	end
	return has, count
end

local function IsInList(t, value)
	for i = 1, table.getn(t) do
		if t[i] == value then
			return true
		end
	end
	return false
end

local function HasBuff(unit, buffName)
	local icons = CheckIcons[buffName]
	if not icons then return true end
	local i = 1
	while UnitBuff(unit, i) do
		local tex = UnitBuff(unit, i)
		if tex == icons[1] or tex == icons[2] then
			return true
		end
		i = i + 1
	end
	return false
end

------------------------------------------------------------------------
-- 自动分配
------------------------------------------------------------------------
local function AutoClassBuff(class, key)
	local has, _ = GetGroupN()
	local num, names = GetClassN(class)
	List[key]["Nums"] = num
	List[key]["Names"] = names
	if num == 0 then return end
	local groups = {}
	for g = 1, 8 do
		if has[g] then table.insert(groups, g) end
	end
	local total = table.getn(groups)
	if total == 0 then return end
	local per = math.floor(total / num)
	local extra = math.mod(total, num)
	local idx = 1
	local assigned = 0
	for gi = 1, total do
		List[key][groups[gi]] = names[idx]
		assigned = assigned + 1
		local cap = per + (idx <= extra and 1 or 0)
		if assigned >= cap then
			assigned = 0
			idx = idx + 1
			if idx > num then idx = 1 end
		end
	end
end

local function AutoCurse()
	local num, names = GetClassN("术士")
	List["Curse"]["Nums"] = num
	List["Curse"]["Names"] = names
	for i = 1, 4 do
		if i <= num then
			List["Curse"][i] = names[i]
		else
			List["Curse"][i] = ""
		end
	end
end

local function AutoBlessing()
	local num, names = GetClassN("圣骑士")
	List["Blessing"]["Nums"] = num
	List["Blessing"]["Names"] = names
	List["Blessing"]["paladinBlessing"] = {}
	local def = DefaultBlessing[num]
	if def then
		for p = 1, num do
			List["Blessing"]["paladinBlessing"][p] = {}
			for c = 1, 9 do
				List["Blessing"]["paladinBlessing"][p][c] = def[p][c]
			end
		end
	end
end

local function ResetAll()
	for _, key in ipairs({"Fortitude", "Intellect", "WildMark"}) do
		List[key]["Nums"] = 0
		List[key]["Names"] = {}
		for i = 1, 8 do
			List[key][i] = ""
		end
	end
	List["Curse"]["Nums"] = 0
	List["Curse"]["Names"] = {}
	List["Tank"]["Nums"] = 0
	List["Tank"]["Names"] = {}
	for i = 1, 4 do
		List["Curse"][i] = ""
		List["Tank"][i] = ""
	end
	List["Blessing"]["Nums"] = 0
	List["Blessing"]["Names"] = {}
	List["Blessing"]["paladinBlessing"] = {}
end

------------------------------------------------------------------------
-- 界面
------------------------------------------------------------------------
local main = nil
local blessingFrame = nil
local tankAdvFrame = nil
local taskFrame = nil
local blessingHint = nil
local blessingTip = nil
local classTexList = {}   -- 骑士分配窗口顶部的9个职业图标
local dropdowns = {}      -- dropdowns[key][i]
local palWidgets = {}     -- 祝福窗口控件
local palPool = nil       -- 隐藏回收池（1.12 下不能用 SetParent(nil) 清理控件）
local monitorOn = false
local monitorButton = nil

local function MakeBackdrop(edgeSize)
	return {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = edgeSize or 20,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	}
end

local function MakeButton(parent, name, w, h, text)
	local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
	b:SetWidth(w)
	b:SetHeight(h)
	b:SetText(text)
	return b
end

-- 职业色名字（下拉候选与下拉框显示用，数据仍存纯名字）
local ClassColorHex = {
	["战士"] = "C79C6E", ["萨满祭司"] = "0070DE", ["圣骑士"] = "F58CBA",
	["猎人"] = "ABD473", ["盗贼"] = "FFF569", ["德鲁伊"] = "FF7D0A",
	["牧师"] = "FFFFFF", ["法师"] = "69CCF0", ["术士"] = "9482C9",
}
local nameClassCache = {}
local function RefreshNameClassCache()
	nameClassCache = {}
	for i = 1, GetNumRaidMembers() do
		local nm, _, _, _, cls = GetRaidRosterInfo(i)
		if nm then nameClassCache[nm] = cls end
	end
end
local function ColorName(name)
	if not name or name == "" then return name end
	local cls = nameClassCache[name]
	local hex = cls and ClassColorHex[cls]
	if not hex then return name end
	return "|cff" .. hex .. name .. "|r"
end
-- 职业色的 RGB 形式（供按钮字体 SetTextColor 用）
local function ClassColorRGB(name)
	local cls = name and nameClassCache[name]
	local hex = cls and ClassColorHex[cls]
	if not hex then return nil end
	return tonumber(string.sub(hex, 1, 2), 16) / 255,
	       tonumber(string.sub(hex, 3, 4), 16) / 255,
	       tonumber(string.sub(hex, 5, 6), 16) / 255
end

-- 下拉菜单初始化闭包
local function MakeDropInit(key, idx, className, dd)
	return function()
		RefreshNameClassCache()
		local info = { text = "<空>" }
		info.func = function()
			UIDropDownMenu_SetText("<空>", dd)
			List[key][idx] = ""
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info)
		local num, names = GetClassN(className)
		for k = 1, table.getn(names) do
			local nm = names[k]
			-- 已被同组其它槽位选中的名字不再进入候选，防止同一人被分配到多个槽位
			-- （仅诅咒/坦克去重；韧/智力/野性印记允许一人负责多个小队，与自动分配一致）
			local taken = false
			if key == "Curse" or key == "Tank" then
				for j = 1, 8 do
					if j ~= idx and List[key][j] == nm then
						taken = true
						break
					end
				end
			end
			if not taken then
				local info2 = { text = ColorName(nm) }
				info2.func = function()
					UIDropDownMenu_SetText(ColorName(nm), dd)
					List[key][idx] = nm
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info2)
			end
		end
	end
end

local function MakeBuffColumn(key, label, subClass, x)
	local f = CreateFrame("Frame", "RCBA_" .. key .. "Frame", main)
	f:SetWidth(200)
	f:SetHeight(272)
	f:SetPoint("TOPLEFT", main, "TOPLEFT", x, -52)
	f:SetBackdrop(MakeBackdrop())
	f:SetBackdropColor(0.15, 0.15, 0.15, 1)
	f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetFontObject(GameFontNormal)
	t:SetText(label)
	t:SetPoint("BOTTOM", f, "TOP", 0, 4)

	dropdowns[key] = {}
	for i = 1, 8 do
		local gl = f:CreateFontString(nil, "OVERLAY")
		gl:SetFontObject(GameFontNormalSmall)
		gl:SetText(i .. "队")
		gl:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -14 - (i - 1) * 30)
		local dd = CreateFrame("Button", "RCBA_Drop_" .. key .. i, f, "UIDropDownMenuTemplate")
		dd:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -8 - (i - 1) * 30)
		UIDropDownMenu_SetWidth(100, dd)
		UIDropDownMenu_JustifyText("CENTER", dd)
		UIDropDownMenu_SetText("<空>", dd)
		UIDropDownMenu_Initialize(dd, MakeDropInit(key, i, subClass, dd))
		dropdowns[key][i] = dd
	end
end

local function MakeSimpleAssignFrame(key, label, x, listClass)
	local f = CreateFrame("Frame", "RCBA_" .. key .. "Frame", main)
	f:SetWidth(200)
	f:SetHeight(152)
	f:SetPoint("TOPLEFT", main, "TOPLEFT", x, -352)
	f:SetBackdrop(MakeBackdrop())
	f:SetBackdropColor(0.15, 0.15, 0.15, 1)
	f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetFontObject(GameFontNormal)
	t:SetText(label)
	t:SetPoint("BOTTOM", f, "TOP", 0, 4)

	dropdowns[key] = {}
	for i = 1, 4 do
		local gl = f:CreateFontString(nil, "OVERLAY")
		gl:SetFontObject(GameFontNormalSmall)
		gl:SetText(List[key]["Label" .. i])
		gl:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -14 - (i - 1) * 33)
		local dd = CreateFrame("Button", "RCBA_Drop_" .. key .. i, f, "UIDropDownMenuTemplate")
		dd:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -10 - (i - 1) * 33)
		UIDropDownMenu_SetWidth(100, dd)
		UIDropDownMenu_JustifyText("CENTER", dd)
		UIDropDownMenu_SetText("<空>", dd)
		UIDropDownMenu_Initialize(dd, MakeDropInit(key, i, listClass, dd))
		dropdowns[key][i] = dd
	end
end

local function LoadDropdowns()
	RefreshNameClassCache()
	for _, key in ipairs({"Fortitude", "Intellect", "WildMark"}) do
		for i = 1, 8 do
			local v = List[key][i]
			UIDropDownMenu_SetText(v ~= "" and ColorName(v) or "<空>", dropdowns[key][i])
		end
	end
	for i = 1, 4 do
		local vc = List["Curse"][i]
		UIDropDownMenu_SetText(vc ~= "" and ColorName(vc) or "<空>", dropdowns["Curse"][i])
		local vt = List["Tank"][i]
		UIDropDownMenu_SetText(vt ~= "" and ColorName(vt) or "<空>", dropdowns["Tank"][i])
	end
end

-- 骑士祝福子窗口 ------------------------------------------------------
local function RefreshBlessingFrame()
	if not blessingFrame then return end
	RefreshNameClassCache()  -- 名字→职业缓存，供骑士名按钮职业色显示
	-- 回收池：旧控件隐藏后挪进这个隐藏帧，避免 SetParent(nil) 在 1.12 下
	-- 变成游离控件（按根层级原始大小渲染、不随窗口关闭而隐藏）
	if not palPool then
		palPool = CreateFrame("Frame", "RCBA_PalPool", UIParent)
		palPool:Hide()
	end
	for i = 1, table.getn(palWidgets) do
		local w = palWidgets[i]
		if w.name then w.name:Hide(); w.name:SetParent(palPool) end
		if w.menu then w.menu:Hide(); w.menu:SetParent(palPool) end
		for j = 1, 9 do
			if w.icons[j] then w.icons[j]:Hide(); w.icons[j]:SetParent(palPool) end
		end
	end
	palWidgets = {}

	local n = List["Blessing"]["Nums"]
	local names = List["Blessing"]["Names"]
	local pb = List["Blessing"]["paladinBlessing"]
	blessingFrame:SetHeight(148 + n * 53)

	-- 无骑士时收窄窗口、图标左移，避免左侧大片空白
	local iconX = 104
	if n == 0 then
		iconX = 12
		blessingFrame:SetWidth(445)
	else
		blessingFrame:SetWidth(545)
	end
	for c = 1, 9 do
		classTexList[c]:ClearAllPoints()
		classTexList[c]:SetPoint("TOPLEFT", blessingFrame, "TOPLEFT", iconX + (c - 1) * 48, -44)
	end

	if blessingHint then
		if n == 0 then
			if GetNumRaidMembers() > 0 then
				blessingHint:SetText("团队中未检测到圣骑士")
			else
				blessingHint:SetText("不在团队中，无法检测圣骑士")
			end
			blessingHint:Show()
		else
			blessingHint:Hide()
		end
	end

	for i = 1, n do
		pb[i] = pb[i] or {}
		local myi = i
		local w = { icons = {} }

		local nb = CreateFrame("Button", "RCBA_PalName" .. i, blessingFrame, "UIPanelButtonTemplate")
		nb:SetWidth(84)
		nb:SetHeight(24)
		nb:SetPoint("TOPLEFT", blessingFrame, "TOPLEFT", 10, -100 - (i - 1) * 53)
		nb:SetText(names[i] or "?")
		-- 骑士名按职业色显示（牧师白/骑士粉等；查不到职业保持默认白字）
		local nfs = nb:GetFontString()
		local cr, cg, cb = ClassColorRGB(tostring(names[i] or ""))
		if nfs and cr then nfs:SetTextColor(cr, cg, cb) end
		w.name = nb

		local menu = CreateFrame("Frame", "RCBA_PalMenu" .. i, blessingFrame, "UIDropDownMenuTemplate")
		w.menu = menu
		-- HD 式换人：点骑士名 → 从团队中的圣骑士里选一人接替
		-- 新骑士原地继承本行祝福分配；若选的人已在其它行，则两行（名字+祝福）整体对调
		UIDropDownMenu_Initialize(menu, function()
			local _, cands = GetClassN("圣骑士")
			for k = 1, table.getn(cands) do
				local nm = cands[k]
				-- 该候选当前占用行（nil=未分配）
				local row = nil
				for r = 1, List["Blessing"]["Nums"] do
					if List["Blessing"]["Names"][r] == nm then
						row = r
						break
					end
				end
				if nm ~= List["Blessing"]["Names"][myi] then
					local info = { text = ColorName(nm) }
					info.func = function()
						if row and row ~= myi then
							-- 已在其它行：两行整体对调
							local tmp = List["Blessing"]["Names"][myi]
							List["Blessing"]["Names"][myi] = List["Blessing"]["Names"][row]
							List["Blessing"]["Names"][row] = tmp
							local tb = pb[myi]
							pb[myi] = pb[row]
							pb[row] = tb
						else
							-- 未分配的新骑士：原地换名，本行祝福分配不变（由新骑士继承）
							List["Blessing"]["Names"][myi] = nm
						end
						RefreshBlessingFrame()
						CloseDropDownMenus()
					end
					UIDropDownMenu_AddButton(info)
				end
			end
		end)
		nb:SetScript("OnClick", function()
			ToggleDropDownMenu(1, nil, menu, nb, 0, 0)
		end)
		-- 悬停提示换人玩法
		nb:SetScript("OnEnter", function()
			if not GameTooltip then return end
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("点击更换骑士\n新骑士继承本行祝福分配")
			GameTooltip:Show()
		end)
		nb:SetScript("OnLeave", function()
			if GameTooltip then GameTooltip:Hide() end
		end)

		for j = 1, 9 do
			local myj = j
			local b = CreateFrame("Button", "RCBA_PalIcon" .. i .. "_" .. j, blessingFrame)
			b:SetWidth(33)
			b:SetHeight(33)
			b:SetPoint("TOPLEFT", blessingFrame, "TOPLEFT", 104 + (j - 1) * 48, -100 - (i - 1) * 53)
			local tex = b:CreateTexture(nil, "BACKGROUND")
			tex:SetAllPoints(b)
			b.tex = tex
			RCBA_SetIcon(b, pb[i][j] or 0)
		-- 1.12 下按钮默认只响应左键，必须显式注册右键才能触发 OnClick
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetScript("OnClick", function()
			local cur2 = tonumber(pb[myi][myj]) or 0
			local nv = cur2 + 1
			if nv > 6 then nv = 0 end
			if arg1 == "RightButton" then
				-- 右键：整行设为同一个祝福（被点列的下一个，循环）
				local wb = palWidgets[myi]
				for t = 1, 9 do
					pb[myi][t] = nv
					if wb and wb.icons[t] then
						RCBA_SetIcon(wb.icons[t], nv)
					end
				end
			else
				pb[myi][myj] = nv
				RCBA_SetIcon(b, nv)
			end
		end)
		-- 悬停显示祝福名（智慧/力量图标近似，靠悬停确认，避免认错图标）
		b:SetScript("OnEnter", function()
			if not GameTooltip then return end
			local v = tonumber(pb[myi][myj]) or 0
			local nm = BlessingNames[v]
			if not nm or nm == "" then nm = "（空）" end
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(nm .. "（" .. ClassNames[myj] .. "）")
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function()
			if GameTooltip then GameTooltip:Hide() end
		end)
			b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
			w.icons[j] = b
		end
		table.insert(palWidgets, w)
	end

	-- 底部提示
	if blessingTip then
		blessingTip:SetText("左键点图标换单个祝福，右键整行设为同一祝福；点骑士名换人，新骑士继承本行祝福")
	end
end

local function ToggleBlessingFrame()
	if not blessingFrame then return end
	if blessingFrame:IsVisible() then
		blessingFrame:Hide()
	else
		-- 从未分配过且在团队中：自动检测骑士并套用默认祝福表
		if List["Blessing"]["Nums"] == 0 and GetNumRaidMembers() > 0 then
			AutoBlessing()
		end
		-- 三个子窗口互斥，不同时出现
		if tankAdvFrame then tankAdvFrame:Hide() end
		if taskFrame then taskFrame:Hide() end
		RefreshBlessingFrame()
		blessingFrame:Show()
	end
end

------------------------------------------------------------------------
-- 坦克分配（高级）：8T + 拉的目标 + 分配的治疗
------------------------------------------------------------------------
local TANK_CLASSES = {"战士", "德鲁伊", "萨满祭司", "圣骑士"}
local HEALER_CLASSES = {"牧师", "德鲁伊", "萨满祭司", "圣骑士"}

local tankAdvData = { names = {}, targets = {}, heals = {} }
for i = 1, 8 do
	tankAdvData.names[i] = ""
	tankAdvData.targets[i] = ""
	tankAdvData.heals[i] = { "", "" }
end
local taTankDrops = {}   -- taTankDrops[i]
local taHealDrops = {}   -- taHealDrops[i] = {dd1, dd2}
local taTargetEdits = {} -- taTargetEdits[i]

-- 下拉菜单初始化：kind="tank" 用 TANK_CLASSES，"heal" 用 HEALER_CLASSES
local function MakeTankAdvDropInit(kind, i, slot, dd)
	local classes = (kind == "tank") and TANK_CLASSES or HEALER_CLASSES
	return function()
		RefreshNameClassCache()
		local info = { text = "<空>" }
		info.func = function()
			UIDropDownMenu_SetText("<空>", dd)
			if kind == "tank" then
				tankAdvData.names[i] = ""
			else
				tankAdvData.heals[i][slot] = ""
			end
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info)
		local num, names = GetClassN(classes)
		for k = 1, table.getn(names) do
			local nm = names[k]
			-- 已被其它槽位选中的名字不再进入候选（坦克组 / 治疗组各自去重）
			local taken = false
			if kind == "tank" then
				for j = 1, 8 do
					if j ~= i and tankAdvData.names[j] == nm then
						taken = true
						break
					end
				end
			else
				for j = 1, 8 do
					for s = 1, 2 do
						if (j ~= i or s ~= slot) and tankAdvData.heals[j] and tankAdvData.heals[j][s] == nm then
							taken = true
						end
					end
				end
				-- 已被分配为坦克的（骑士/萨满/德鲁伊）不再进入治疗候选：
				-- 同时查高级窗口坦克行与主窗口 1T-4T
				if not taken then
					for j = 1, 8 do
						if tankAdvData.names[j] == nm then
							taken = true
							break
						end
					end
				end
				if not taken then
					for j = 1, 4 do
						if List["Tank"][j] == nm then
							taken = true
							break
						end
					end
				end
			end
			if not taken then
				local info2 = { text = ColorName(nm) }
				info2.func = function()
					UIDropDownMenu_SetText(ColorName(nm), dd)
					if kind == "tank" then
						tankAdvData.names[i] = nm
					else
						tankAdvData.heals[i][slot] = nm
					end
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info2)
			end
		end
	end
end

local function LoadTankAdv()
	RefreshNameClassCache()
	for i = 1, 8 do
		local v = tankAdvData.names[i]
		UIDropDownMenu_SetText(v ~= "" and ColorName(v) or "<空>", taTankDrops[i])
		for s = 1, 2 do
			local h = tankAdvData.heals[i][s]
			UIDropDownMenu_SetText(h ~= "" and ColorName(h) or "<空>", taHealDrops[i][s])
		end
		taTargetEdits[i]:SetText(tankAdvData.targets[i])
	end
end

local function ToggleTankAdvFrame()
	if not tankAdvFrame then return end
	if tankAdvFrame:IsVisible() then
		tankAdvFrame:Hide()
	else
		-- 三个子窗口互斥，不同时出现
		if blessingFrame then blessingFrame:Hide() end
		if taskFrame then taskFrame:Hide() end
		LoadTankAdv()
		tankAdvFrame:Show()
	end
end

function RCBA_TankAdvReport()
	RefreshNameClassCache()  -- 名字→职业缓存，供职业色显示
	local rows = {}
	for i = 1, 8 do
		local tn = tankAdvData.names[i]
		-- 目标直接从输入框实时读取（本客户端 OnTextChanged 不可靠，存档可能为空）
		local tg = tankAdvData.targets[i]
		if taTargetEdits[i] then
			local live = taTargetEdits[i]:GetText()
			if live then tg = live end
		end
		local hs = {}
		for s = 1, 2 do
			if tankAdvData.heals[i][s] ~= "" then
				table.insert(hs, tankAdvData.heals[i][s])
			end
		end
		if tn ~= "" then
			local line = i .. "T:" .. ColorName(tn)
			if tg ~= "" then line = line .. "→" .. ColorName(tg) end
			if table.getn(hs) > 0 then
				local cs = {}
				for s = 1, table.getn(hs) do
					table.insert(cs, ColorName(hs[s]))
				end
				line = line .. "（治疗:" .. table.concat(cs, ",") .. "）"
			end
			table.insert(rows, line)
		end
	end
	if table.getn(rows) == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("坦克分配: 尚未分配，请先在下拉中选择坦克")
		return
	end
	-- 逐行独立发送（表头一条，每个坦克一条），不合并
	RC_QueueMsgOne("坦克分配")
	for i = 1, table.getn(rows) do
		RC_QueueMsgOne(rows[i])
	end
end

------------------------------------------------------------------------
-- 分配数据持久化（/rl、重登不丢失）：RCBA_AssignDB
-- 保存：隐藏帧 OnUpdate 每 2 秒对 List + tankAdvData 做一次快照写入
--       RCBA_AssignDB（写小表开销可忽略，真正落盘由客户端在退出/重载时统一完成），
--       不在每个下拉/图标改动点插保存调用
-- 恢复：1.12 下 SavedVariables 在插件加载完之后才注入，走 VARS_LOADED 事件恢复
--       （PLAYER_ENTERING_WORLD 兜底 + 打开窗口时再兜底一次）
------------------------------------------------------------------------
local assignRestored = false

local ASSIGN_KEYS = {"Fortitude", "Intellect", "WildMark", "Curse", "Tank", "Blessing"}

local function RCBA_AssignSnapshot()
	local snap = { list = {}, tank = { names = {}, targets = {}, heals = {} } }
	for _, key in ipairs(ASSIGN_KEYS) do
		local src = List[key]
		local dst = { Nums = src["Nums"] or 0, Names = {} }
		local maxg = (key == "Fortitude" or key == "Intellect" or key == "WildMark") and 8 or 4
		for g = 1, maxg do dst[g] = src[g] or "" end
		for p = 1, (src["Names"] and table.getn(src["Names"]) or 0) do
			dst["Names"][p] = src["Names"][p]
		end
		if src["paladinBlessing"] then
			dst["paladinBlessing"] = {}
			for p = 1, (src["Nums"] or 0) do
				local row = src["paladinBlessing"][p]
				if row then
					local nr = {}
					for c = 1, 9 do nr[c] = row[c] end
					dst["paladinBlessing"][p] = nr
				end
			end
		end
		snap["list"][key] = dst
	end
	for i = 1, 8 do
		snap["tank"]["names"][i] = tankAdvData.names[i] or ""
		snap["tank"]["targets"][i] = tankAdvData.targets[i] or ""
		-- 目标直接读输入框实时内容（本客户端 OnTextChanged 不可靠）
		if taTargetEdits[i] then
			local live = taTargetEdits[i]:GetText()
			if live then snap["tank"]["targets"][i] = live end
		end
		snap["tank"]["heals"][i] = { tankAdvData.heals[i][1] or "", tankAdvData.heals[i][2] or "" }
	end
	return snap
end

local function RCBA_AssignRestore()
	if assignRestored then return end
	if RCBA_AssignDB == nil then return end  -- 存档还没注入，等下一个事件
	assignRestored = true
	local db = RCBA_AssignDB
	if db["list"] then
		for _, key in ipairs(ASSIGN_KEYS) do
			local s = db["list"][key]
			if s then
				List[key]["Nums"] = s["Nums"] or 0
				List[key]["Names"] = s["Names"] or {}
				local maxg = (key == "Fortitude" or key == "Intellect" or key == "WildMark") and 8 or 4
				for g = 1, maxg do List[key][g] = s[g] or "" end
				if key == "Blessing" then
					List[key]["paladinBlessing"] = s["paladinBlessing"] or {}
				end
			end
		end
	end
	if db["tank"] then
		for i = 1, 8 do
			tankAdvData.names[i] = (db["tank"]["names"] and db["tank"]["names"][i]) or ""
			tankAdvData.targets[i] = (db["tank"]["targets"] and db["tank"]["targets"][i]) or ""
			local h = db["tank"]["heals"] and db["tank"]["heals"][i]
			if h then
				tankAdvData.heals[i][1] = h[1] or ""
				tankAdvData.heals[i][2] = h[2] or ""
			end
		end
	end
end

local assignSaveFrame = CreateFrame("Frame", "RCBA_AssignSaveFrame", UIParent)
local assignLastSave = 0
assignSaveFrame:SetScript("OnEvent", function()
	if event == "VARS_LOADED" or event == "PLAYER_ENTERING_WORLD" then
		RCBA_AssignRestore()
	end
end)
assignSaveFrame:RegisterEvent("VARS_LOADED")
assignSaveFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
assignSaveFrame:SetScript("OnUpdate", function()
	if GetTime() - assignLastSave < 2 then return end
	assignLastSave = GetTime()
	RCBA_AssignDB = RCBA_AssignSnapshot()
end)

------------------------------------------------------------------------
-- 任务分配：每行一条任务内容，SavedVariables 持久保存，下次打开可修改后通报
-- 注意：1.12 下 SavedVariables 在所有插件加载完成后才注入，所以只在
--       打开窗口/保存时（用户交互阶段）才读 RCBA_TaskDB，不能在文件顶层读
------------------------------------------------------------------------
local taskData = {}
for i = 1, 8 do taskData[i] = "" end
local taskEdits = {}   -- taskEdits[i]

local function LoadTaskData()
	if RCBA_TaskDB == nil then RCBA_TaskDB = {} end
	local t = RCBA_TaskDB.tasks
	for i = 1, 8 do
		taskData[i] = (t and type(t[i]) == "string") and t[i] or ""
	end
end

local function SaveTaskData()
	if RCBA_TaskDB == nil then RCBA_TaskDB = {} end
	RCBA_TaskDB.tasks = {}
	for i = 1, 8 do
		if taskEdits[i] then
			taskData[i] = taskEdits[i]:GetText() or ""
		end
		RCBA_TaskDB.tasks[i] = taskData[i]
	end
	DEFAULT_CHAT_FRAME:AddMessage("任务分配: 已保存，下次打开窗口可继续修改")
end

local function LoadTaskEdits()
	LoadTaskData()
	for i = 1, 8 do
		if taskEdits[i] then taskEdits[i]:SetText(taskData[i]) end
	end
end

local function ToggleTaskFrame()
	if not taskFrame then return end
	if taskFrame:IsVisible() then
		taskFrame:Hide()
	else
		if blessingFrame then blessingFrame:Hide() end
		if tankAdvFrame then tankAdvFrame:Hide() end
		LoadTaskEdits()
		taskFrame:Show()
	end
end

function RCBA_TaskReport()
	local rows = {}
	for i = 1, 8 do
		-- 通报时直接读输入框实时内容（与坦克分配同样处理，避免存档滞后）
		local txt = taskData[i]
		if taskEdits[i] then
			local live = taskEdits[i]:GetText()
			if live then txt = live end
		end
		if txt ~= "" then table.insert(rows, txt) end
	end
	if table.getn(rows) == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("任务分配: 内容为空，请先输入任务")
		return
	end
	-- 逐行独立发送（表头一条，每条任务一条），走同一节流队列防刷屏
	RC_QueueMsgOne("任务分配")
	for i = 1, table.getn(rows) do
		RC_QueueMsgOne(rows[i])
	end
	-- 通报前顺手存档，保证发布的内容与存档一致
	SaveTaskData()
end

local function CreateMain()
	if main then return end
	main = CreateFrame("Frame", "RCBA_MainFrame", UIParent)
	main:SetFrameStrata("DIALOG")
	main:SetWidth(660)
	main:SetHeight(540)
	main:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	main:SetBackdrop(MakeBackdrop(24))
	main:SetBackdropColor(0.15, 0.15, 0.15, 1)
	main:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	main:EnableMouse(true)
	main:SetMovable(true)
	main:RegisterForDrag("LeftButton")
	main:SetScript("OnDragStart", function() main:StartMoving() end)
	main:SetScript("OnDragStop", function() main:StopMovingOrSizing() end)
	main:Hide()

	local title = main:CreateTexture(nil, "ARTWORK")
	title:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	title:SetWidth(256)
	title:SetHeight(64)
	title:SetPoint("TOP", main, "TOP", 0, 12)
	local tt = main:CreateFontString(nil, "OVERLAY")
	tt:SetFontObject(GameFontNormal)
	tt:SetText("团队BUFF分配")
	tt:SetPoint("CENTER", title, "CENTER", 0, 11)

	local cb = MakeButton(main, "RCBA_CloseButton", 40, 24, "关闭")
	cb:SetPoint("TOPRIGHT", main, "TOPRIGHT", -10, -8)
	cb:SetScript("OnClick", function() main:Hide() end)

	MakeBuffColumn("Fortitude", "真言术：韧（牧师）", "牧师", 20)
	MakeBuffColumn("Intellect", "奥术智慧（法师）", "法师", 230)
	MakeBuffColumn("WildMark", "野性印记（德鲁伊）", "德鲁伊", 440)

	List["Curse"]["Label1"] = "鲁莽"
	List["Curse"]["Label2"] = "元素"
	List["Curse"]["Label3"] = "暗影"
	List["Curse"]["Label4"] = "语言"
	MakeSimpleAssignFrame("Curse", "诅咒（术士）", 20, "术士")
	List["Tank"]["Label1"] = "MT"
	List["Tank"]["Label2"] = "2T"
	List["Tank"]["Label3"] = "3T"
	List["Tank"]["Label4"] = "4T"
	MakeSimpleAssignFrame("Tank", "坦克（战/德/萨/骑）", 230, TANK_CLASSES)

	local bb = MakeButton(main, "RCBA_BlessingButton", 200, 30, "骑士祝福设置")
	bb:SetPoint("TOPLEFT", main, "TOPLEFT", 440, -352)
	bb:SetScript("OnClick", function() ToggleBlessingFrame() end)

	local tb = MakeButton(main, "RCBA_TankAdvButton", 200, 30, "坦克分配（高级）")
	tb:SetPoint("TOPLEFT", main, "TOPLEFT", 440, -388)
	tb:SetScript("OnClick", function() ToggleTankAdvFrame() end)

	local ab = MakeButton(main, "RCBA_AutoButton", 100, 30, "自动分配")
	ab:SetPoint("TOPLEFT", main, "TOPLEFT", 440, -424)
	ab:SetScript("OnClick", function()
		ResetAll()
		AutoClassBuff("牧师", "Fortitude")
		AutoClassBuff("法师", "Intellect")
		AutoClassBuff("德鲁伊", "WildMark")
		AutoCurse()
		AutoBlessing()
		LoadDropdowns()
		RefreshBlessingFrame()
	end)

	local nb = MakeButton(main, "RCBA_ReportButton", 100, 30, "团队通报")
	nb:SetPoint("TOPLEFT", main, "TOPLEFT", 545, -424)
	nb:SetScript("OnClick", function() RCBA_Report() end)

	local wb = MakeButton(main, "RCBA_CheckButton", 100, 30, "补BUFF检查")
	wb:SetPoint("TOPLEFT", main, "TOPLEFT", 440, -458)
	wb:SetScript("OnClick", function() RCBA_BuffCheckAndReport() end)

	monitorButton = MakeButton(main, "RCBA_MonitorButton", 100, 30, "密语监控")
	monitorButton:SetPoint("TOPLEFT", main, "TOPLEFT", 545, -458)
	monitorButton:SetScript("OnClick", function() RCBA_ToggleMonitor() end)

	local tkb = MakeButton(main, "RCBA_TaskButton", 200, 30, "任务分配")
	tkb:SetPoint("TOPLEFT", main, "TOPLEFT", 440, -492)
	tkb:SetScript("OnClick", function() ToggleTaskFrame() end)

	local tip = main:CreateFontString(nil, "OVERLAY")
	tip:SetFontObject(GameFontNormalSmall)
	tip:SetText("")
	tip:SetPoint("TOPLEFT", main, "TOPLEFT", 20, -500)
	tip:Hide()

	-- 骑士祝福子窗口
	blessingFrame = CreateFrame("Frame", "RCBA_BlessingFrame", main)
	blessingFrame:SetWidth(560)
	blessingFrame:SetHeight(120)
	blessingFrame:SetPoint("TOPLEFT", main, "TOPRIGHT", 4, 0)
	blessingFrame:SetBackdrop(MakeBackdrop(24))
	blessingFrame:SetBackdropColor(0.15, 0.15, 0.15, 1)
	blessingFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	blessingFrame:Hide()

	local bt = blessingFrame:CreateFontString(nil, "OVERLAY")
	bt:SetFontObject(GameFontNormal)
	bt:SetText("骑士祝福分配")
	bt:SetPoint("TOP", blessingFrame, "TOP", 0, -12)

	for c = 1, 9 do
		local ct = blessingFrame:CreateTexture("RCBA_ClassTex" .. c, "ARTWORK")
		ct:SetTexture(ClassIconTexture)
		local tc = ClassTex[c]
		ct:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
		ct:SetWidth(33)
		ct:SetHeight(33)
		ct:SetPoint("TOPLEFT", blessingFrame, "TOPLEFT", 104 + (c - 1) * 48, -44)
		classTexList[c] = ct
	end
	local cb2 = MakeButton(blessingFrame, "RCBA_BlessingCloseButton", 40, 22, "关闭")
	cb2:SetPoint("TOPRIGHT", blessingFrame, "TOPRIGHT", -8, -8)
	cb2:SetScript("OnClick", function() blessingFrame:Hide() end)

	local rb = MakeButton(blessingFrame, "RCBA_BlessingRefreshButton", 80, 22, "重新检测")
	rb:SetPoint("TOPRIGHT", blessingFrame, "TOPRIGHT", -52, -8)
	rb:SetScript("OnClick", function()
		if GetNumRaidMembers() == 0 then
			DEFAULT_CHAT_FRAME:AddMessage(NORAID)
			return
		end
		AutoBlessing()
		RefreshBlessingFrame()
	end)

	blessingHint = blessingFrame:CreateFontString(nil, "OVERLAY")
	blessingHint:SetFontObject(GameFontNormal)
	blessingHint:SetText("不在团队中，无法检测圣骑士")
	blessingHint:SetPoint("BOTTOMRIGHT", blessingFrame, "BOTTOMRIGHT", -12, 8)
	blessingHint:Hide()

	-- 操作提示固定在骑士分配窗口底部
	blessingTip = blessingFrame:CreateFontString(nil, "OVERLAY")
	blessingTip:SetFontObject(GameFontNormalSmall)
	blessingTip:SetText("左键点图标换单个祝福，右键整行设为同一祝福；点骑士名换人，新骑士继承本行祝福")
	blessingTip:SetPoint("BOTTOMLEFT", blessingFrame, "BOTTOMLEFT", 12, 8)

	-- 坦克分配（高级）子窗口 ------------------------------------------------
	tankAdvFrame = CreateFrame("Frame", "RCBA_TankAdvFrame", main)
	tankAdvFrame:SetWidth(600)
	tankAdvFrame:SetHeight(380)
	tankAdvFrame:SetPoint("TOPLEFT", main, "TOPRIGHT", 4, 0)
	tankAdvFrame:SetBackdrop(MakeBackdrop(24))
	tankAdvFrame:SetBackdropColor(0.15, 0.15, 0.15, 1)
	tankAdvFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	tankAdvFrame:Hide()

	local tat = tankAdvFrame:CreateFontString(nil, "OVERLAY")
	tat:SetFontObject(GameFontNormal)
	tat:SetText("坦克分配（高级）")
	tat:SetPoint("TOP", tankAdvFrame, "TOP", 0, -12)

	local tacb = MakeButton(tankAdvFrame, "RCBA_TankAdvCloseButton", 40, 22, "关闭")
	tacb:SetPoint("TOPRIGHT", tankAdvFrame, "TOPRIGHT", -8, -8)
	tacb:SetScript("OnClick", function() tankAdvFrame:Hide() end)

	-- 列标题
	local heads = {
		{ "坦克", 80 }, { "拉的目标", 220 }, { "治疗1", 368 }, { "治疗2", 505 },
	}
	for h = 1, table.getn(heads) do
		local hd = tankAdvFrame:CreateFontString(nil, "OVERLAY")
		hd:SetFontObject(GameFontNormalSmall)
		hd:SetText(heads[h][1])
		hd:SetPoint("TOPLEFT", tankAdvFrame, "TOPLEFT", heads[h][2], -40)
	end

	for i = 1, 8 do
		local rowY = -60 - (i - 1) * 34
		local rl = tankAdvFrame:CreateFontString(nil, "OVERLAY")
		rl:SetFontObject(GameFontNormalSmall)
		rl:SetText(i .. "T")
		rl:SetPoint("TOPLEFT", tankAdvFrame, "TOPLEFT", 14, rowY - 6)

		local tdd = CreateFrame("Button", "RCBA_TankAdv_Tank" .. i, tankAdvFrame, "UIDropDownMenuTemplate")
		tdd:SetPoint("TOPLEFT", tankAdvFrame, "TOPLEFT", 34, rowY)
		UIDropDownMenu_SetWidth(100, tdd)
		UIDropDownMenu_JustifyText("CENTER", tdd)
		UIDropDownMenu_SetText("<空>", tdd)
		UIDropDownMenu_Initialize(tdd, MakeTankAdvDropInit("tank", i, 0, tdd))
		taTankDrops[i] = tdd

		local ed = CreateFrame("EditBox", "RCBA_TankAdv_Target" .. i, tankAdvFrame, "InputBoxTemplate")
		ed:SetWidth(110)
		ed:SetHeight(24)
		ed:SetPoint("TOPLEFT", tankAdvFrame, "TOPLEFT", 195, rowY + 2)
		ed:SetAutoFocus(false)
		ed:SetMaxLetters(24)
		ed:SetScript("OnEscapePressed", function()
			tankAdvData.targets[i] = this:GetText()
			this:ClearFocus()
		end)
		ed:SetScript("OnEnterPressed", function()
			tankAdvData.targets[i] = this:GetText()
			this:ClearFocus()
		end)
		ed:SetScript("OnEditFocusLost", function()
			tankAdvData.targets[i] = this:GetText()
		end)
		taTargetEdits[i] = ed

		taHealDrops[i] = {}
		for s = 1, 2 do
			local hdd = CreateFrame("Button", "RCBA_TankAdv_Heal" .. i .. "_" .. s, tankAdvFrame, "UIDropDownMenuTemplate")
			hdd:SetPoint("TOPLEFT", tankAdvFrame, "TOPLEFT", 312 + (s - 1) * 140, rowY)
			UIDropDownMenu_SetWidth(100, hdd)
			UIDropDownMenu_JustifyText("CENTER", hdd)
			UIDropDownMenu_SetText("<空>", hdd)
			UIDropDownMenu_Initialize(hdd, MakeTankAdvDropInit("heal", i, s, hdd))
			taHealDrops[i][s] = hdd
		end
	end

	local tarb = MakeButton(tankAdvFrame, "RCBA_TankAdvReportButton", 80, 24, "团队通报")
	tarb:SetPoint("BOTTOMLEFT", tankAdvFrame, "BOTTOMLEFT", 12, 10)
	tarb:SetScript("OnClick", function() RCBA_TankAdvReport() end)

	local tatip = tankAdvFrame:CreateFontString(nil, "OVERLAY")
	tatip:SetFontObject(GameFontNormalSmall)
	tatip:SetText("坦克/治疗下拉选人，拉的目标手动输入")
	tatip:SetPoint("BOTTOMRIGHT", tankAdvFrame, "BOTTOMRIGHT", -12, 14)

	-- 任务分配子窗口 --------------------------------------------------------
	taskFrame = CreateFrame("Frame", "RCBA_TaskFrame", main)
	taskFrame:SetWidth(560)
	taskFrame:SetHeight(380)
	taskFrame:SetPoint("TOPLEFT", main, "TOPRIGHT", 4, 0)
	taskFrame:SetBackdrop(MakeBackdrop(24))
	taskFrame:SetBackdropColor(0.15, 0.15, 0.15, 1)
	taskFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	taskFrame:Hide()

	local tkt = taskFrame:CreateFontString(nil, "OVERLAY")
	tkt:SetFontObject(GameFontNormal)
	tkt:SetText("任务分配")
	tkt:SetPoint("TOP", taskFrame, "TOP", 0, -12)

	local tkcb = MakeButton(taskFrame, "RCBA_TaskCloseButton", 40, 22, "关闭")
	tkcb:SetPoint("TOPRIGHT", taskFrame, "TOPRIGHT", -8, -8)
	tkcb:SetScript("OnClick", function() taskFrame:Hide() end)

	for i = 1, 8 do
		local rowY = -60 - (i - 1) * 34
		local rl = taskFrame:CreateFontString(nil, "OVERLAY")
		rl:SetFontObject(GameFontNormalSmall)
		rl:SetText(i .. ".")
		rl:SetPoint("TOPLEFT", taskFrame, "TOPLEFT", 14, rowY - 6)
		local ed = CreateFrame("EditBox", "RCBA_TaskEdit" .. i, taskFrame, "InputBoxTemplate")
		ed:SetWidth(470)
		ed:SetHeight(24)
		ed:SetPoint("TOPLEFT", taskFrame, "TOPLEFT", 42, rowY + 2)
		ed:SetAutoFocus(false)
		ed:SetMaxLetters(200)  -- 聊天消息上限 255，留余量
		ed:SetScript("OnEscapePressed", function() this:ClearFocus() end)
		ed:SetScript("OnEnterPressed", function() this:ClearFocus() end)
		taskEdits[i] = ed
	end

	local tksb = MakeButton(taskFrame, "RCBA_TaskSaveButton", 80, 24, "保存")
	tksb:SetPoint("BOTTOMLEFT", taskFrame, "BOTTOMLEFT", 12, 10)
	tksb:SetScript("OnClick", function() SaveTaskData() end)

	local tktrb = MakeButton(taskFrame, "RCBA_TaskReportButton", 80, 24, "团队通报")
	tktrb:SetPoint("BOTTOMLEFT", taskFrame, "BOTTOMLEFT", 100, 10)
	tktrb:SetScript("OnClick", function() RCBA_TaskReport() end)

	local pktip = taskFrame:CreateFontString(nil, "OVERLAY")
	pktip:SetFontObject(GameFontNormalSmall)
	pktip:SetText("每行一条任务，保存后跨登录保留，通报逐行发送")
	pktip:SetPoint("BOTTOMRIGHT", taskFrame, "BOTTOMRIGHT", -12, 14)
end

------------------------------------------------------------------------
-- 团队通报（走 RaidCheck 的消息队列，频道跟随主窗口下拉框）
-- 格式与 HDLRaidTools 完全一致（HDLBUFF.lua generateReport/CurseReport/
-- TankReport/BlessingReport）：每段独立一条消息、[名字：1、2队] 方括号、
-- 段落标签与标记着色、坦克无分配时显示"未分配"、祝福去重按列序
------------------------------------------------------------------------
local function GroupReportLines(lines, key, label)
	local nameTeams = {}
	for g = 1, 8 do
		local nm = List[key][g]
		if nm and nm ~= "" then
			nameTeams[nm] = nameTeams[nm] or {}
			table.insert(nameTeams[nm], g)
		end
	end
	local parts = {}
	for nm, teams in pairs(nameTeams) do
		table.sort(teams)
		table.insert(parts, "[" .. ColorName(nm) .. "：" .. table.concat(teams, "、") .. "队]")
	end
	table.insert(lines, label .. "： " .. table.concat(parts, " "))
end

function RCBA_Report()
	if GetNumRaidMembers() == 0 then
		DEFAULT_CHAT_FRAME:AddMessage(NORAID)
		return
	end
	RefreshNameClassCache()  -- 刷新名字→职业缓存，供职业色显示
	local lines = {}
	GroupReportLines(lines, "Fortitude", "|cffFFFFFF耐力|r")
	GroupReportLines(lines, "Intellect", "|cff00BFFF智力|r")
	GroupReportLines(lines, "WildMark", "|cffA0522D爪子|r")

	-- 诅咒（HDLUI.CurseReport 格式）
	local curseNames = {"鲁莽", "元素", "暗影", "语言"}
	local cparts = ""
	for i = 1, 4 do
		if List["Curse"][i] ~= "" then
			cparts = cparts .. "[" .. curseNames[i] .. "：" .. ColorName(List["Curse"][i]) .. "] "
		end
	end
	table.insert(lines, "|cff800080诅咒|r： " .. cparts)

	-- 坦克（HDLUI.TankReport 格式，标记着色；每个坦克独立一行，无分配显示"未分配"）
	local tankMarks = {"|cffFFFFFF骷髅|r", "|cffFF0000叉子|r", "|cff00BFFF方块|r", "|cffF0F0FF月亮|r"}
	local anyTank = false
	for i = 1, 4 do
		if List["Tank"][i] ~= "" then
			anyTank = true
			table.insert(lines, "|cffFFD700坦克|r： " .. i .. "T：" .. ColorName(List["Tank"][i]) .. " →" .. tankMarks[i])
		end
	end
	if not anyTank then
		table.insert(lines, "|cffFFD700坦克|r： 未分配")
	end

	-- 祝福（HDLUI.BlessingReport 格式：每个骑士一条 [名字:祝福1,祝福2]，去重按列序）
	local bparts = ""
	for p = 1, List["Blessing"]["Nums"] do
		local pb = List["Blessing"]["paladinBlessing"][p]
		if pb then
			bparts = bparts .. "[" .. ColorName(tostring(List["Blessing"]["Names"][p])) .. ":"
			local first = true
			local seen = {}
			for c = 1, 9 do
				local bn = BlessingNames[pb[c] or 0]
				if bn and bn ~= "" and not seen[bn] then
					seen[bn] = true
					if first then
						bparts = bparts .. bn
						first = false
					else
						bparts = bparts .. "," .. bn
					end
				end
			end
			bparts = bparts .. "] "
		end
	end
	table.insert(lines, "|cffFFB6C1祝福|r： " .. bparts)

	-- 与 HDL 一致：每段独立一条消息（走同一节流队列，防刷屏）
	for i = 1, table.getn(lines) do
		RC_QueueMsgOne(lines[i])
	end
end

------------------------------------------------------------------------
-- 补BUFF检查（密语通知各加BUFF人员）
------------------------------------------------------------------------
local WhisperQueue = {}
local WhisperLast = 0
local sendFrame = CreateFrame("Frame", "RCBA_WhisperFrame", UIParent)
sendFrame:SetScript("OnUpdate", function()
	if table.getn(WhisperQueue) == 0 then return end
	if GetTime() - WhisperLast < 0.35 then return end
	WhisperLast = GetTime()
	local item = table.remove(WhisperQueue, 1)
	SendChatMessage(item.msg, "WHISPER", nil, item.to)
end)

function RCBA_BuffCheckAndReport()
	if GetNumRaidMembers() == 0 then
		DEFAULT_CHAT_FRAME:AddMessage(NORAID)
		return
	end
	if table.getn(WhisperQueue) > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("补BUFF检查: 正在发送中，请稍候")
		return
	end

	-- 加BUFF人员名单
	local bufferList = {}
	local function ensure(name)
		if name and name ~= "" and bufferList[name] == nil then
			bufferList[name] = ""
		end
	end
	for _, key in ipairs({"Fortitude", "Intellect", "WildMark"}) do
		for g = 1, 8 do
			ensure(List[key][g])
		end
	end
	-- 祝福分工表 [祝福名][职业名]=骑士
	local blessMap = {}
	for p = 1, List["Blessing"]["Nums"] do
		ensure(List["Blessing"]["Names"][p])
		local pb = List["Blessing"]["paladinBlessing"][p]
		if pb then
			for c = 1, 9 do
				local bn = BlessingNames[pb[c] or 0]
				if bn and bn ~= "" then
					blessMap[bn] = blessMap[bn] or {}
					blessMap[bn][ClassNames[c]] = List["Blessing"]["Names"][p]
				end
			end
		end
	end
	local tankList = {}
	for i = 1, 4 do
		if List["Tank"][i] ~= "" then
			table.insert(tankList, List["Tank"][i])
		end
	end

	local total = 0
	for i = 1, GetNumRaidMembers() do
		local unit = "raid" .. i
		local name, _, subgroup, _, class = GetRaidRosterInfo(i)
		if name and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitIsVisible(unit) then
			local cidx = classIndexMap[class]
			if cidx then
				for _, bn in ipairs(ClassBuffNeed[cidx]) do
					if not HasBuff(unit, bn) then
						local who = nil
						if bn == "耐力" then
							who = List["Fortitude"][subgroup]
						elseif bn == "智力" then
							who = List["Intellect"][subgroup]
						elseif bn == "爪子" then
							who = List["WildMark"][subgroup]
						else
							who = blessMap[bn] and blessMap[bn][class] or nil
						end
						if who and who ~= "" and not (bn == "拯救祝福" and IsInList(tankList, name)) then
							if bufferList[who] == "" then
								bufferList[who] = "请及时为以下玩家补" .. bn .. "BUFF: " .. name .. "[" .. subgroup .. "队]"
							else
								bufferList[who] = bufferList[who] .. "," .. name .. "[" .. subgroup .. "队]"
							end
							total = total + 1
						end
					end
				end
			end
		end
	end

	local n = 0
	for who, msg in pairs(bufferList) do
		if msg ~= "" then
			table.insert(WhisperQueue, { to = who, msg = msg })
			n = n + 1
		end
	end
	if n == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("补BUFF检查: 全员BUFF齐全，无需通知")
	else
		DEFAULT_CHAT_FRAME:AddMessage("补BUFF检查: 已向" .. n .. "名加BUFF人员密语发送补BUFF通知（共" .. total .. "个缺口）")
	end
end

------------------------------------------------------------------------
-- 密语监控
------------------------------------------------------------------------
local monitorFrame = CreateFrame("Frame", "RCBA_MonitorFrame", UIParent)
local lastTrigger = 0
monitorFrame:SetScript("OnEvent", function()
	if event == "CHAT_MSG_WHISPER" then
		if (arg1 == "buff" or arg1 == "BUFF") and monitorOn
			and (IsRaidLeader() or IsRaidOfficer())
			and GetTime() - lastTrigger > 60 then
			lastTrigger = GetTime()
			RCBA_BuffCheckAndReport()
		end
	end
end)

function RCBA_ToggleMonitor()
	if monitorOn then
		monitorFrame:UnregisterEvent("CHAT_MSG_WHISPER")
		monitorOn = false
		if monitorButton then monitorButton:SetText("密语监控") end
		DEFAULT_CHAT_FRAME:AddMessage("BUFF分配密语监控: 关闭")
	else
		monitorFrame:RegisterEvent("CHAT_MSG_WHISPER")
		monitorOn = true
		if monitorButton then monitorButton:SetText("监控[开]") end
		DEFAULT_CHAT_FRAME:AddMessage("BUFF分配密语监控: 开启，团友密语你「buff」将自动补BUFF通知（60秒CD）")
	end
end

------------------------------------------------------------------------
-- 开关与命令
------------------------------------------------------------------------
function RCBA_Toggle()
	CreateMain()
	if main:IsVisible() then
		main:Hide()
	else
		RCBA_AssignRestore()  -- 兜底：存档注入晚于事件时，打开窗口前先恢复
		LoadDropdowns()
		main:Show()
		-- 两个窗口都居中，会重叠：打开分配窗口时隐藏BUFF检查主窗口
		RC_MainFrame:Hide()
	end
end

SLASH_RCBA1 = "/rcb"
SlashCmdList["RCBA"] = function()
	RCBA_Toggle()
end

-- 补BUFF检查宏命令：/rcbc（可放进宏按钮一键触发，等价于窗口里的「补BUFF检查」）
SLASH_RCBC1 = "/rcbc"
SlashCmdList["RCBC"] = function()
	RCBA_BuffCheckAndReport()
end

-- 图标校准：列出身上每个 buff 的真实纹理文件名（用于核对祝福图标映射）
SLASH_RCICON1 = "/rcicon"
SlashCmdList["RCICON"] = function()
	if not DEFAULT_CHAT_FRAME then return end
	DEFAULT_CHAT_FRAME:AddMessage("RC图标校准：当前身上buff纹理——")
	for k = 1, 32 do
		local tex = UnitBuff("player", k)
		if not tex then break end
		DEFAULT_CHAT_FRAME:AddMessage(k .. ": " .. tex)
	end
end
