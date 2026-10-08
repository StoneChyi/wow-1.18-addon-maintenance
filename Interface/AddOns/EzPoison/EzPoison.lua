EzPoison = EzPoison or {}

local p = EzPoison

EzPoison.api = getfenv()
EzPoison.logs = {}

local function log(msg)
	table.insert(EzPoison.logs, tostring(msg))
	if table.getn(EzPoison.logs) > 200 then
		table.remove(EzPoison.logs, 1)
	end
end

function EzPoison.showlogs()
	for i = 1, table.getn(EzPoison.logs) do
		DEFAULT_CHAT_FRAME:AddMessage(i .. ": " .. EzPoison.logs[i])
	end
end

function EzPoison.log(a)
	log(a)
end

local allItems = {
	{
		id = 1,
		name = "速效毒药",
		ids = { 6947, 6949, 6950, 8926, 8927, 8928 },
		texture = "Interface\\Icons\\Ability_Poisons",
	},
	{
		id = 2,
		name = "致命毒药",
		ids = { 2892, 2893, 8984, 8985, 20844 },
		texture = "Interface\\Icons\\Ability_Rogue_DualWeild",
	},
	{
		id = 3,
		name = "致残毒药",
		ids = { 3775, 3776 },
		texture = "Interface\\Icons\\INV_Potion_19",
	},
	{
		id = 4,
		name = "致伤毒药",
		ids = { 10918, 10920, 10921, 10922 },
		texture = "Interface\\Icons\\Ability_PoisonSting",
	},
	{
		id = 5,
		name = "腐蚀毒药",
		ids = { 47408, 47409 },
		texture = "Interface\\Icons\\inv_corrosive_01",
	},
	{
		id = 6,
		name = "麻痹毒药",
		ids = { 5237, 6951, 9186 },
		texture = "Interface\\Icons\\Spell_Nature_NullifyDisease",
	},
	{
		id = 7,
		name = "煽动毒药",
		ids = { 65032 },
		texture = "Interface\\Icons\\Spell_Nature_NullifyPoison",
	},
	{
		id = 8,
		name = "溶解毒药",
		ids = { 54009, 54010 },
		texture = "Interface\\Icons\\Spell_Nature_SlowPoison",
	},
	{
		id = 9,
		name = "致密磨刀石",
		ids = { 12404 },
		texture = "Interface\\Icons\\inv_stone_sharpeningstone_05",
	},
	{
		id = 10,
		name = "致密平衡石",
		ids = { 12643 },
		texture = "Interface\\Icons\\INV_Stone_WeightStone_05",
	},
	{
		id = 11,
		name = "元素磨刀石",
		ids = { 18262 },
		texture = "Interface\\Icons\\inv_stone_02",
	},
	{
		id = 12,
		name = "神圣磨刀石",
		ids = { 23122 },
		texture = "Interface\\Icons\\INV_Stone_SharpeningStone_02",
	},
	{
		id = 13,
		name = "卓越巫师之油",
		ids = { 20749 },
		texture = "Interface\\Icons\\INV_Potion_105",
	},
	{
		id = 14,
		name = "卓越法力之油",
		ids = { 20748 },
		texture = "Interface\\Icons\\INV_Potion_100",
	},
	{
		id = 15,
		name = "神圣巫师之油",
		ids = { 23123 },
		texture = "Interface\\Icons\\INV_POTION_26",
	},
}

local function vPlayerClass(itemName, playerClassEN)
	if type(itemName) ~= "string" then
		return false
	end

	-- local onlyPhisicalClasses = {
	-- 	["WARRIOR"] = 1,
	-- 	["ROGUE"] = 1,
	-- }

	local phisicalClasses = {
		["WARRIOR"] = 1,
		["ROGUE"] = 1,
		["HUNTER"] = 1,
		["PALADIN"] = 1,
		["SHAMAN"] = 1,
		["DRUID"] = 1,
	}

	local magicalClasses = {
		["MAGE"] = 1,
		["PRIEST"] = 1,
		["WARLOCK"] = 1,
		["SHAMAN"] = 1,
		["DRUID"] = 1,
		["PALADIN"] = 1,
		["HUNTER"] = 1,
	}

	if playerClassEN == "ROGUE" and string.find(itemName, "毒药") then
		return true
	end

	if magicalClasses[playerClassEN] and string.find(itemName, "油$") then
		return true
	end

	if phisicalClasses[playerClassEN] and string.find(itemName, "石$") then
		return true
	end

	return false
end

local EZP = CreateFrame("Frame")
EZP.ConfigFrame = CreateFrame("Frame", nil, UIParent)
EZP.Parser = CreateFrame("GameTooltip", "EZPParser", nil, "GameTooltipTemplate")
EZP.ACE = AceLibrary("AceAddon-2.0"):new("FuBarPlugin-2.0")
EZP:RegisterEvent("ADDON_LOADED")
EZP:RegisterEvent("UNIT_INVENTORY_CHANGED")
EZP:RegisterEvent("BAG_UPDATE")

local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()
local screenCenterX = screenWidth / 2
local screenCenterY = screenHeight / 2

--fubar/mapicon
EZP.ACE.name = "EzPoison"
EZP.ACE.hasIcon = "Interface\\Icons\\Ability_Rogue_DualWeild"
EZP.ACE.defaultMinimapPosition = 200
EZP.ACE.cannotDetachTooltip = true

local usableItems = {}
local classCheckFrame = CreateFrame("Frame")
classCheckFrame:SetScript("OnUpdate", function()
	local _, playerClassEN = UnitClass("player")
	if playerClassEN and EzPoison.loaded then
		classCheckFrame:SetScript("OnUpdate", nil)

		EZP.ConfigFrame:ConfigureUI()
		EZP:SetProfile()
		EZP:ConfigFubar()
		EZP:ApplyLockPosition() -- 应用锁定状态
		EZP.ConfigFrame:SetScript("OnUpdate", EZP.AddonStart)
	end
end)

local function initUsableItems()
	local _, playerClassEN = UnitClass("player")
	if playerClassEN then
		usableItems = {}

		for _, item in ipairs(allItems) do
			if vPlayerClass(item.name, playerClassEN) then
				table.insert(usableItems, item)
			end
		end
	end
end

function EZP.ACE:OnClick()
	if (arg1 == "LeftButton") then
		if EZP.ConfigFrame:IsVisible() then
			EZP.ConfigFrame:Hide()
		else
			EZP:UpdateTexture(); EZP.ConfigFrame:Show()
		end
	end
end

-- pre-allocate work variables
EZP.Work = {
	slotInfo = {},
	ToolTipBuff = "",
	ID = {},
	Time = 0,
	iSCasting = nil,

	Poison = {
		[1] = "速效毒药",
		[2] = "致命毒药",
		[3] = "致残毒药",
		[4] = "致伤毒药",
		[5] = "腐蚀毒药",
		[6] = "麻痹毒药",
		[7] = "煽动毒药",
		[8] = "溶解毒药",
		[9] = "致密磨刀石",
		[10] = "致密平衡石",
		[11] = "元素磨刀石",
		[12] = "神圣磨刀石",
		[13] = "卓越巫师之油",
		[14] = "卓越法力之油",
		[15] = "神圣巫师之油",
	},
	PoisonID = {
		[1] = { 6947, 6949, 6950, 8926, 8927, 8928 },
		[2] = { 2892, 2893, 8984, 8985, 20844 },
		[3] = { 3775, 3776 },
		[4] = { 10918, 10920, 10921, 10922 },
		[5] = { 47408, 47409 },
		[6] = { 5237, 6951, 9186 },
		[7] = 65032,
		[8] = { 54009, 54010 },
		[9] = 12404,
		[10] = 12643,
		[11] = 18262,
		[12] = 23122,
		[13] = 20749,
		[14] = 20748,
		[15] = 23123,
	},
	PoisonIcon = {
		[1] = "Interface\\Icons\\Ability_Poisons",
		[2] = "Interface\\Icons\\Ability_Rogue_DualWeild",
		[3] = "Interface\\Icons\\INV_Potion_19",
		[4] = "Interface\\Icons\\Ability_PoisonSting",
		-- [5] = "Interface\\Icons\\inv_misc_slime_01",
		[5] = "Interface\\Icons\\inv_corrosive_01",
		[6] = "Interface\\Icons\\Spell_Nature_NullifyDisease",
		[7] = "Interface\\Icons\\Spell_Nature_NullifyPoison",
		[8] = "Interface\\Icons\\Spell_Nature_SlowPoison",
		[9] = "Interface\\Icons\\inv_stone_sharpeningstone_05",
		[10] = "Interface\\Icons\\INV_Stone_WeightStone_05",
		[11] = "Interface\\Icons\\inv_stone_02",
		[12] = "Interface\\Icons\\INV_Stone_SharpeningStone_02",
		[13] = "Interface\\Icons\\INV_Potion_105",
		[14] = "Interface\\Icons\\INV_Potion_100",
		[15] = "Interface\\Icons\\INV_POTION_26",
	}
}

local poisonsCount = table.getn(EZP.Work.Poison)

-- local functions
EZP.GetWeaponEnchantInfo = GetWeaponEnchantInfo

function EZP:OnEvent()
	if event == "BAG_UPDATE" then
		if arg1 == 0 or arg1 == 1 or arg1 == 2 or arg1 == 3 or arg1 == 4 then
			EZP:UpdatePoisonCount()
		end
	elseif event == "ADDON_LOADED" and arg1 == "EzPoison" then
		if not EZPcfg then
			EZPcfg = {
				Profile = {
					[1] = { MainHand = 0, OffHand = 0, Name = "方案 1" },
					[2] = { MainHand = 0, OffHand = 0, Name = "方案 2" },
					[3] = { MainHand = 0, OffHand = 0, Name = "方案 3" },
					[4] = { MainHand = 0, OffHand = 0, Name = "方案 4" },
					[5] = { MainHand = 0, OffHand = 0, Name = "方案 5" },
					[6] = { MainHand = 0, OffHand = 0, Name = "方案 6" },
					[7] = { MainHand = 0, OffHand = 0, Name = "方案 7" },
				},
				CurrentProfile = 1,
				PosX = screenCenterX,
				PosY = -screenCenterY,
				Scale = 1,
				FadeInactive = 1, -- 未激活褪色，1=启用，0=禁用
				LockPosition = 0, -- 锁定位置，1=锁定（点击穿透），0=未锁定
			}
		else
			-- 兼容旧版本配置，如果FadeInactive不存在则设置为默认值1
			if EZPcfg.FadeInactive == nil then
				EZPcfg.FadeInactive = 1
			end
			-- 兼容旧版本配置，如果LockPosition不存在则设置为默认值0
			if EZPcfg.LockPosition == nil then
				EZPcfg.LockPosition = 0
			end
		end

		EzPoison.loaded = 1
		-- EZP.ConfigFrame:ConfigureUI()
		-- EZP:SetProfile()
		-- EZP:ConfigFubar()
		-- EZP:ApplyLockPosition() -- 应用锁定状态
		-- EZP.ConfigFrame:SetScript("OnUpdate", EZP.AddonStart)
	elseif event == "SPELLCAST_START" then
		EZP.Work.iSCasting = 1
	elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_FAILED" then
		EZP:UnregisterEvent("SPELLCAST_STOP")
		EZP:UnregisterEvent("SPELLCAST_START")
		EZP:UnregisterEvent("SPELLCAST_INTERRUPTED")
		EZP:UnregisterEvent("SPELLCAST_FAILED")
		EZP.Work.iSCasting = nil
		EZP:UpdateTexture()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		EZP:UpdateTexture()
	end
end

EZP:SetScript("OnEvent", EZP.OnEvent)

local function timeleftWarn(text, hand, props)
	if not props then
		props = {
			fontSize = 16,
		}
	else
		if not props.fontSize then
			props.fontSize = 16
		end
	end

	local _, _, minutes = string.find(text, "(%d+)分钟")
	if EZPcfg.LeftWarn == 1 and tonumber(minutes) then
		EZP.ConfigFrame[hand]:SetAlpha(1)

		if tonumber(minutes) < 6 then
			EZP.ConfigFrame[hand].Background:SetVertexColor(1, 0, 0, 0.8)
			EZP.ConfigFrame[hand].Count:SetText(minutes.."m")
			EZP.ConfigFrame[hand].Count:SetFont("Fonts\\ARIALN.TTF", props.fontSize, "OUTLINE")
		else
			EZP.ConfigFrame[hand].Count:SetText("")
			EZP.ConfigFrame[hand].Background:SetVertexColor(1, 1, 1, 0)
		end
	else
		local _, _, seconds = string.find(text, "(%d+)秒")
		if EZPcfg.LeftWarn == 1 and tonumber(seconds) then
			EZP.ConfigFrame[hand].Background:SetVertexColor(1, 0, 0, 0.8)
			EZP.ConfigFrame[hand].Count:SetText(seconds.."s")
			EZP.ConfigFrame[hand].Count:SetFont("Fonts\\ARIALN.TTF", props.fontSize, "OUTLINE")
		else
			EZP.ConfigFrame[hand].Count:SetText("")
			EZP.ConfigFrame[hand].Background:SetVertexColor(1, 1, 1, 0)
		end
	end
end

local checkNotPoisonActiveSettings = {
	[9] = "磨快",
	[10] = "增重",
	[11] = "致命一击 ",
	[12] = "攻击强度vs亡灵",
	[13] = "卓越巫师之油",
	[14] = "卓越法力之油",
	[15] = "法术伤害vs亡灵",
}
local function checkNotPoisonActive(workID, text, hand)
	if checkNotPoisonActiveSettings[workID] then
		if string.find(text, checkNotPoisonActiveSettings[workID]) then
			EZP.ConfigFrame[hand]:SetAlpha(1)
			timeleftWarn(text, hand)

			return 2
		end

		return 1
	end
end

-- 应用位置锁定状态
function EZP:ApplyLockPosition()
	local frame = EZP.ConfigFrame
	if not frame then
		return
	end

	if EZPcfg.LockPosition == 1 then
		-- 锁定位置：禁用鼠标交互和拖动，实现点击穿透
		frame:SetMovable(false)
		frame:EnableMouse(false)
		frame:SetScript("OnDragStart", nil)
		frame:SetScript("OnDragStop", nil)
		-- 清除拖动注册
		frame:RegisterForDrag()
	else
		-- 未锁定：启用鼠标交互和拖动
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", EZP.ConfigFrame.StartMove)
		frame:SetScript("OnDragStop", EZP.ConfigFrame.StopMove)
	end

	-- 确保主副手按钮始终可以交互（它们不受父框架EnableMouse影响）
	if frame.MainHand then
		frame.MainHand:EnableMouse(true)
	end
	if frame.OffHand then
		frame.OffHand:EnableMouse(true)
	end
end

-- 应用位置（立即生效）
function EZP:ApplyPosition()
	local frame = EZP.ConfigFrame
	if not frame then
		return
	end

	-- 确保位置配置有效
	if not EZPcfg.PosX or not EZPcfg.PosY then
		EZPcfg.PosX = screenCenterX
		EZPcfg.PosY = -screenCenterY
	end

	-- 获取当前缩放值
	local currentScale = frame:GetScale() or (EZPcfg.Scale or 1)

	-- 应用位置（基准位置除以当前缩放值）
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", EZPcfg.PosX / currentScale, EZPcfg.PosY / currentScale)
end

-- 应用缩放并保持中心点不变
function EZP:ApplyScale(newScale)
	local frame = EZP.ConfigFrame
	if not frame then
		return
	end

	-- 从frame获取当前实际的缩放值（这是最准确的）
	local oldScale = frame:GetScale() or (EZPcfg.Scale or 1)

	-- 如果新旧缩放相同，不需要做任何操作
	if math.abs(oldScale - newScale) < 0.001 then
		EZPcfg.Scale = newScale
		return
	end

	-- 保存新缩放值到配置
	EZPcfg.Scale = newScale

	-- 使用保存的基准位置（scale=1时的位置）除以新缩放值
	-- 如果位置未保存，使用默认值
	local baseX = EZPcfg.PosX or screenCenterX
	local baseY = EZPcfg.PosY or -screenCenterY

	frame:SetScale(newScale)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", baseX / newScale, baseY / newScale)
	-- 	-- 	EZPcfg.PosX = newX
	-- 	-- 	EZPcfg.PosY = newY

	-- 如果frame已经显示且有有效位置，计算中心点并重新定位
	-- if frame:IsVisible() then
	-- 	-- 获取frame的原始尺寸（不考虑缩放）
	-- 	local width = frame:GetWidth()
	-- 	local height = frame:GetHeight()

	-- 	-- 获取当前锚点信息
	-- 	local point, relativeTo, relativePoint, x, y = frame:GetPoint()

	-- 	-- -- 如果锚点有效且是相对于UIParent的
	-- 	-- if point and x and y and relativeTo == UIParent and relativePoint == "BOTTOMLEFT" then
	-- 	-- 	-- 使用实际屏幕坐标计算中心点，避免锚点坐标系统的理解偏差
	-- 	-- 	-- 获取当前frame的实际屏幕坐标（这些坐标已经考虑了当前缩放）
	-- 	-- 	local left = frame:GetLeft()
	-- 	-- 	local right = frame:GetRight()
	-- 	-- 	local top = frame:GetTop()
	-- 	-- 	local bottom = frame:GetBottom()

	-- 	-- 	-- 如果能够获取有效的屏幕坐标，使用它们计算中心点
	-- 	-- 	local newX, newY
	-- 	-- 	if left and right and top and bottom and
	-- 	-- 	   math.abs(right - left) > 0.1 and math.abs(top - bottom) > 0.1 then
	-- 	-- 		-- 计算当前实际显示的中心点（屏幕坐标）
	-- 	-- 		local centerX = (left + right) / 2
	-- 	-- 		local centerY = (top + bottom) / 2

	-- 	-- 		-- 计算新锚点，保持中心点不变
	-- 	-- 		-- 新frame的中心点应该等于当前中心点
	-- 	-- 		newX = centerX - (width * newScale) / 2
	-- 	-- 		newY = centerY + (height * newScale) / 2
	-- 	-- 	else
	-- 	-- 		-- 如果无法获取屏幕坐标，回退到基于锚点的计算
	-- 	-- 		-- 使用精确的数学计算
	-- 	-- 		local scaleDiff = oldScale - newScale
	-- 	-- 		newX = x + (width * scaleDiff) / 2
	-- 	-- 		newY = y - (height * scaleDiff) / 2
	-- 	-- 	end

	-- 	-- 	-- 确保frame在屏幕范围内
	-- 	-- 	local screenWidth = UIParent:GetWidth()
	-- 	-- 	local screenHeight = UIParent:GetHeight()

	-- 	-- 	-- 限制在屏幕范围内
	-- 	-- 	if newX < 0 then newX = 0 end
	-- 	-- 	if newX + (width * newScale) > screenWidth then
	-- 	-- 		newX = math.max(0, screenWidth - (width * newScale))
	-- 	-- 	end
	-- 	-- 	if newY > screenHeight then newY = screenHeight end
	-- 	-- 	if newY - (height * newScale) < 0 then
	-- 	-- 		newY = math.min(screenHeight, height * newScale)
	-- 	-- 	end

	-- 	-- 	-- 先更新位置，再应用缩放
	-- 	-- 	-- 这样可以确保位置计算基于旧缩放，然后应用新缩放
	-- 	-- 	frame:ClearAllPoints()
	-- 	-- 	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
	-- 	-- 	frame:SetScale(newScale)

	-- 	-- 	-- 保存新位置到配置
	-- 	-- 	EZPcfg.PosX = newX
	-- 	-- 	EZPcfg.PosY = newY
	-- 	-- else
	-- 	-- 	-- 如果锚点信息无效或格式不对，使用保存的位置并应用缩放
	-- 	-- 	frame:SetScale(newScale)
	-- 	-- 	if EZPcfg.PosX and EZPcfg.PosY then
	-- 	-- 		frame:ClearAllPoints()
	-- 	-- 		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", EZPcfg.PosX, EZPcfg.PosY)
	-- 	-- 	end
	-- 	-- end
	-- else
	-- 	-- 如果frame还没显示，直接应用缩放，位置会在显示时从配置恢复
	-- 	frame:SetScale(newScale)
	-- end
end

function EZP.ConfigFrame:ConfigureUI()
	-- moving frames function
	function EZP.ConfigFrame:StartMove()
		this:StartMoving()
	end

	function EZP.ConfigFrame:StopMove()
		this:StopMovingOrSizing()
		local a, _, b, x, y = EZP.ConfigFrame:GetPoint()
		-- 获取当前缩放值
		local currentScale = EZP.ConfigFrame:GetScale() or (EZPcfg.Scale or 1)
		-- 保存位置时乘以当前缩放值，得到scale=1时的基准位置
		EZPcfg.PosX = x * currentScale
		EZPcfg.PosY = y * currentScale
	end

	-- 确保位置配置有效，如果无效则使用默认值（这些是scale=1时的基准位置）
	if not EZPcfg.PosX or not EZPcfg.PosY then
		EZPcfg.PosX = screenCenterX
		EZPcfg.PosY = -screenCenterY
	end

	local currentScale = EZPcfg.Scale or 1
	self:SetScale(currentScale)
	local backdrop = {
		bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
		edgeFile =
		"Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 3, right = 5, top = 3, bottom = 5 }
	} -- path to the background texture
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 0.8)
	self:SetWidth(82)
	self:SetHeight(48)
	-- 使用基准位置除以当前缩放值
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", EZPcfg.PosX / currentScale, EZPcfg.PosY / currentScale)
	-- 应用锁定状态
	EZP:ApplyLockPosition()

	self.ProfileButton = CreateFrame("Button", nil, self)
	self.ProfileButton:SetWidth(82)
	self.ProfileButton:SetHeight(12)
	self.ProfileButton:SetPoint("BOTTOM", self, "TOP", 0, 0)
	self.ProfileButton:SetScript("OnEnter", function() for j = 1, 7 do self.ProfileButton[j]:Show() end end)
	self.ProfileButton:SetScript("OnLeave", function() for j = 1, 7 do self.ProfileButton[j]:Hide() end end)

	for i = 1, 8 do
		if i == 1 then
			self.ProfileButton[i] = CreateFrame("Button", nil, self.ProfileButton); self.ProfileButton[i]:SetPoint("BOTTOM",
				self, "TOPLEFT", 11, 0)
		else
			self.ProfileButton[i] = CreateFrame("Button", nil, self.ProfileButton[i - 1]); self.ProfileButton[i]:SetPoint(
				"LEFT", self.ProfileButton[i - 1], "RIGHT", 3, 0)
		end
		self.ProfileButton[i]:SetID(i)
		self.ProfileButton[i]:SetWidth(7)
		self.ProfileButton[i]:SetHeight(7)
		self.ProfileButton[i]:SetScript("OnClick", function()
			EZP:SetProfile(this:GetID())
		end)
		self.ProfileButton[i]:SetNormalTexture("Interface\\AddOns\\EzPoison\\Media\\buttonD")
		self.ProfileButton[i]:SetScript("OnEnter", function() for j = 1, 7 do self.ProfileButton[j]:Show() end end)
		self.ProfileButton[i]:SetScript("OnLeave", function() for j = 1, 7 do self.ProfileButton[j]:Hide() end end)
		self.ProfileButton[i]:Hide()
	end

	-- 初始化选项
	initUsableItems()

	-- Mainhand
	local function MainHandDropDownFun()
		local info = {}
		info.text = "主手"
		info.isTitle = 1
		UIDropDownMenu_AddButton(info)
		info = {}
		-- for i = 1, poisonsCount do
		-- 	if vPlayerClass(EZP.Work.Poison[i]) then
		-- 		info.text = EZP.Work.Poison[i]
		-- 		info.icon = EZP.Work.PoisonIcon[i]
		-- 		info.checked = false
		-- 		info.textR = 0.4; info.textG = 0.8; info.textB = 0.4
		-- 		info.isTitle = nil
		-- 		info.func = function()
		-- 			UIDropDownMenu_SetSelectedID(getglobal("EZPMainHandDD"), this:GetID(), 0)
		-- 			EZP:UpdateSelection()
		-- 			EZP:SaveProfiles()
		-- 		end
		-- 		UIDropDownMenu_AddButton(info)
		-- 	end
		-- end

		for i = 1, table.getn(usableItems) do
			local item = usableItems[i]
			info.text = item.name
			info.icon = item.texture
			info.checked = false
			info.textR = 0.4; info.textG = 0.8; info.textB = 0.4
			info.isTitle = nil
			info.arg1 = item.id
			info.func = function(a1)
				UIDropDownMenu_SetSelectedID(getglobal("EZPMainHandDD"), a1 + 1, 0)
				EZP:UpdateSelection()
				EZP:SaveProfiles()
			end
			UIDropDownMenu_AddButton(info)
		end

		info = {}
		info.text = "无"
		info.checked = false
		info.textR = 1; info.textG = 1; info.textB = 1
		info.isTitle = nil
		info.func = function()
			UIDropDownMenu_SetSelectedID(getglobal("EZPMainHandDD"), 1, 0)
			EZP:UpdateSelection()
			EZP:SaveProfiles()
		end
		UIDropDownMenu_AddButton(info)
	end

	self.MainHand = CreateFrame("Button", "EZPMHButton", self)
	self.MainHand.BorderDropdown = CreateFrame("Frame", "EZPMainHandDD", self, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(getglobal("EZPMainHandDD"), MainHandDropDownFun, "MENU")

	self.MainHand:SetWidth(32)
	self.MainHand:SetHeight(32)
	self.MainHand:SetPoint("LEFT", 7, 0)
	self.MainHand:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.MainHand:SetScript("OnClick", function()
		if arg1 == "LeftButton" then EZP:ApplyPoisen("MH") end
		if arg1 == "RightButton" then ToggleDropDownMenu(1, nil, self.MainHand.BorderDropdown, self.OffHand, 0, 0) end
	end)
	self.MainHand:SetScript("OnEnter", function()
		self.MainHand.Background:SetVertexColor(1, 1, 1, 1)
		local id = EZP:GetInventoryID("MH")
		if id then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:" .. id[4])
			GameTooltip:Show()
		end
	end)
	self.MainHand:SetScript("OnLeave", function()
		self.MainHand.Background:SetVertexColor(1, 1, 1, 0)
		GameTooltip:Hide()
	end)
	self.MainHand:SetNormalTexture("Interface\\Buttons\\UI-Quickslot-Depress")

	-- 创建独立的图标纹理，用于pfUI皮肤
	self.MainHand.Icon = self.MainHand:CreateTexture(nil, "ARTWORK")
	self.MainHand.Icon:SetPoint("CENTER", self.MainHand, "CENTER", 0, 0)
	self.MainHand.Icon:SetWidth(32)
	self.MainHand.Icon:SetHeight(32)
	self.MainHand.Icon:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

	self.MainHand.Background = self:CreateTexture(self, "BACKGROUND")
	self.MainHand.Background:SetPoint("CENTER", self.MainHand, "CENTER", 0, 0)
	self.MainHand.Background:SetWidth(36)
	self.MainHand.Background:SetHeight(36)
	self.MainHand.Background:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	self.MainHand.Background:SetVertexColor(1, 1, 1, 0)
	self.MainHand.Background:SetBlendMode("ADD")

	self.MainHand.Font = self.MainHand:CreateFontString(nil, "OVERLAY")
	self.MainHand.Font:SetPoint("BOTTOMRIGHT", -2, 2)
	self.MainHand.Font:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
	self.MainHand.Font:SetTextColor(0.8, 0.8, 0.8)
	--self.MainHand.Font:SetText("999")

	-- 在MainHand的中间添加一个文本，显示当前毒药剩余次数
	self.MainHand.Count = self.MainHand:CreateFontString(nil, "OVERLAY")
	self.MainHand.Count:SetPoint("CENTER", self.MainHand, "CENTER")
	self.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
	self.MainHand.Count:SetTextColor(1, 0, 0, 0.9)
	self.MainHand.Count:SetText("")

	-- OffHand
	local function OffHandDropDownFun()
		local info = {}
		info.text = "副手"
		info.isTitle = 1
		UIDropDownMenu_AddButton(info)
		info = {}
		-- for i = 1, poisonsCount do
		-- 		info.text = EZP.Work.Poison[i]
		-- 		info.checked = false
		-- 		info.icon = EZP.Work.PoisonIcon[i]
		-- 		info.textR = 0.4; info.textG = 0.8; info.textB = 0.4
		-- 		info.isTitle = nil
		-- 		info.func = function()
		-- 			UIDropDownMenu_SetSelectedID(getglobal("EZPOffHandDD"), this:GetID(), 0)
		-- 			EZP:UpdateSelection()
		-- 			EZP:SaveProfiles()
		-- 		end
		-- 		UIDropDownMenu_AddButton(info)
		-- end
		-- info = {}
		-- info.text = "无"
		-- info.checked = false
		-- info.textR = 1; info.textG = 1; info.textB = 1
		-- info.isTitle = nil
		-- info.func = function()
		-- 	UIDropDownMenu_SetSelectedID(getglobal("EZPOffHandDD"), this:GetID(), 0)
		-- 	EZP:UpdateSelection()
		-- 	EZP:SaveProfiles()
		-- end
		-- UIDropDownMenu_AddButton(info)

		for i = 1, table.getn(usableItems) do
			local item = usableItems[i]
			info.text = item.name
			info.icon = item.texture
			info.checked = false
			info.textR = 0.4; info.textG = 0.8; info.textB = 0.4
			info.isTitle = nil
			info.arg1 = item.id
			info.func = function(a1)
				UIDropDownMenu_SetSelectedID(getglobal("EZPOffHandDD"), a1 + 1, 0)
				EZP:UpdateSelection()
				EZP:SaveProfiles()
			end
			UIDropDownMenu_AddButton(info)
		end

		info = {}
		info.text = "无"
		info.checked = false
		info.textR = 1; info.textG = 1; info.textB = 1
		info.isTitle = nil
		info.func = function()
			UIDropDownMenu_SetSelectedID(getglobal("EZPOffHandDD"), 1, 0)
			EZP:UpdateSelection()
			EZP:SaveProfiles()
		end
		UIDropDownMenu_AddButton(info)
	end

	self.OffHand = CreateFrame("Button", "EZPOHButton", self)
	self.OffHand.BorderDropdown = CreateFrame("Frame", "EZPOffHandDD", self, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(getglobal("EZPOffHandDD"), OffHandDropDownFun, "MENU")

	self.OffHand:SetWidth(32)
	self.OffHand:SetHeight(32)
	self.OffHand:SetPoint("RIGHT", -7, 0)
	self.OffHand:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.OffHand:SetScript("OnClick", function()
		if arg1 == "LeftButton" then EZP:ApplyPoisen("OH") end
		if arg1 == "RightButton" then ToggleDropDownMenu(1, nil, self.OffHand.BorderDropdown, self.OffHand, 0, 0) end
	end)
	self.OffHand:SetScript("OnEnter", function()
		self.OffHand.Background:SetVertexColor(1, 1, 1, 1)
		local id = EZP:GetInventoryID("OH")
		if id then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:" .. id[4])
			GameTooltip:Show()
		end
	end)
	self.OffHand:SetScript("OnLeave", function()
		self.OffHand.Background:SetVertexColor(1, 1, 1, 0)
		GameTooltip:Hide()
	end)
	self.OffHand:SetNormalTexture("Interface\\Buttons\\UI-Quickslot-Depress")

	-- 创建独立的图标纹理，用于pfUI皮肤
	self.OffHand.Icon = self.OffHand:CreateTexture(nil, "ARTWORK")
	self.OffHand.Icon:SetPoint("CENTER", self.OffHand, "CENTER", 0, 0)
	self.OffHand.Icon:SetWidth(32)
	self.OffHand.Icon:SetHeight(32)
	self.OffHand.Icon:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

	self.OffHand.Background = self:CreateTexture(self, "BACKGROUND")
	self.OffHand.Background:SetPoint("CENTER", self.OffHand, "CENTER", 0, 0)
	self.OffHand.Background:SetWidth(36)
	self.OffHand.Background:SetHeight(36)
	self.OffHand.Background:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	self.OffHand.Background:SetVertexColor(1, 1, 1, 0)
	self.OffHand.Background:SetBlendMode("ADD")

	self.OffHand.Font = self.OffHand:CreateFontString(nil, "OVERLAY")
	self.OffHand.Font:SetPoint("BOTTOMRIGHT", -2, 2)
	self.OffHand.Font:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
	self.OffHand.Font:SetTextColor(0.8, 0.8, 0.8)
	--self.OffHand.Font:SetText("999")
	self.OffHand.Count = self.OffHand:CreateFontString(nil, "OVERLAY")
	self.OffHand.Count:SetPoint("CENTER", self.OffHand, "CENTER")
	self.OffHand.Count:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
	self.OffHand.Count:SetTextColor(1, 0, 0, 0.9)
	self.OffHand.Count:SetText("")

	self:SetScript("OnShow", function() EZPcfg.isVisible = 1 end)
	self:SetScript("OnHide", function() EZPcfg.isVisible = nil end)

	if not EZPcfg.isVisible then EZP.ConfigFrame:Hide() end

	EZP.skin_pfUI()
end

--[[ EzPoison / pfUI 皮肤说明：
  1) 不要用未前缀的全局 dbg 在 pfUI.RegisterSkin 里调试（与加载顺序有关，见先前讨论）。
  2) 不能依赖 pfUI.env.C 作为「pfUI 已就绪」判断：pfUI.env 初始带 __index=getfenv(0)，在 GetEnvironment()
     真正把 C 写入 env 之前，pfUI.env.C 往往是 nil（全局通常没有 C），导致永远不注册；
     若 pfUI 在 EzPoison 之前加载，ADDON_LOADED("pfUI") 已过，再监听该事件也等不到，皮肤永久失效。 ]]
local ezPoisonPfUISkinListener
local ezPoisonPfUISkinChatOnce
local ezPoisonPfUISkinLoadedOnce
local ezPoisonPfUISkinRetryFrame
local ezPoisonPfUIConfigBootstrapped

local function EnsurePfUISkinLoaded()
	if ezPoisonPfUISkinLoadedOnce then return true end
	-- 兼容：pfUI.bootup 一直为 true 时，主 OnEvent 可能没执行完。
	-- 只在第一次 Ensure 时尝试补齐配置/字体环境，避免 LoadSkin 里依赖的 pfUI 配置为空。
	if pfUI and pfUI.bootup and not ezPoisonPfUIConfigBootstrapped then
		ezPoisonPfUIConfigBootstrapped = true
		pcall(function()
			if pfUI.LoadConfig then pfUI:LoadConfig() end
			if pfUI.MigrateConfig then pfUI:MigrateConfig() end
			if pfUI.UpdateFonts then pfUI:UpdateFonts() end
		end)
	end
	if not (pfUI and pfUI.api and pfUI.LoadSkin and pfUI.skin and pfUI.skin["EzPoison"]) then
		return false
	end
	local ok = pcall(function()
		pfUI:LoadSkin("EzPoison")
	end)
	if ok then
		ezPoisonPfUISkinLoadedOnce = true
		return true
	end
	return false
end

local function RegisterPfUISkin()
	if not (pfUI and pfUI.api and pfUI.RegisterSkin) then
		return false
	end
	if pfUI.skin["EzPoison"] then
		if ezPoisonPfUISkinListener then
			ezPoisonPfUISkinListener:UnregisterAllEvents()
			ezPoisonPfUISkinListener:SetScript("OnEvent", nil)
			ezPoisonPfUISkinListener = nil
		end
		return true
	end

	pfUI:RegisterSkin("EzPoison", function()
		if not ezPoisonPfUISkinChatOnce then
			ezPoisonPfUISkinChatOnce = true
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFFFFFFF" .. "pfUI skin applied." .. "|r", 0.4, 0.8, 0.4)
		end

		pfUI.api.StripTextures(EZP.ConfigFrame, true)
		pfUI.api.CreateBackdrop(EZP.ConfigFrame, nil, nil, .75)
		pfUI.api.CreateBackdropShadow(EZP.ConfigFrame)

		EZP.ConfigFrame.backdrop:SetPoint("TOPLEFT", 0, 0)
		EZP.ConfigFrame.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)

		EZP.ConfigFrame:SetWidth(72)
		EZP.ConfigFrame:SetHeight(38)
		EZP.ConfigFrame.MainHand:SetPoint("LEFT", 3, 0)
		EZP.ConfigFrame.OffHand:SetPoint("RIGHT", -3, 0)
		EZP.ConfigFrame.ProfileButton:SetWidth(72)
		EZP.ConfigFrame.ProfileButton[1]:ClearAllPoints()
		EZP.ConfigFrame.ProfileButton[1]:SetPoint("BOTTOM", EZP.ConfigFrame, "TOPLEFT", 6, 0)
	end)

	if not pfUI.skin["EzPoison"] then
		return false
	end

	-- pfUI.bootup 有时会一直保持为 true（例如主 OnEvent 没触发）。
	-- 为兼容这种情况：在皮肤注册后短时间内重试 LoadSkin，但只在成功后停止，避免重复执行。
	if not EnsurePfUISkinLoaded() and not ezPoisonPfUISkinRetryFrame then
		ezPoisonPfUISkinRetryFrame = CreateFrame("Frame")
		ezPoisonPfUISkinRetryFrame.baseTime = GetTime()
		ezPoisonPfUISkinRetryFrame:SetScript("OnUpdate", function()
			-- 成功后会把脚本卸载掉
			if EnsurePfUISkinLoaded() then
				ezPoisonPfUISkinRetryFrame:SetScript("OnUpdate", nil)
				ezPoisonPfUISkinRetryFrame = nil
				return
			end
			-- 最多重试 8 秒，避免永远挂着造成额外开销
			if GetTime() - ezPoisonPfUISkinRetryFrame.baseTime > 8 then
				ezPoisonPfUISkinRetryFrame:SetScript("OnUpdate", nil)
				ezPoisonPfUISkinRetryFrame = nil
			end
		end)
	end

	if ezPoisonPfUISkinListener then
		ezPoisonPfUISkinListener:UnregisterAllEvents()
		ezPoisonPfUISkinListener:SetScript("OnEvent", nil)
		ezPoisonPfUISkinListener = nil
	end
	return true
end

function EZP.skin_pfUI()
	if RegisterPfUISkin() then
		return
	end
	-- pfUI 尚未执行完主文件：在后续任意 ADDON_LOADED 上重试，直到 pfUI.api 可用
	if ezPoisonPfUISkinListener then
		return
	end
	ezPoisonPfUISkinListener = CreateFrame("Frame")
	ezPoisonPfUISkinListener:RegisterEvent("ADDON_LOADED")
	ezPoisonPfUISkinListener:SetScript("OnEvent", function()
		if pfUI and pfUI.api and pfUI.RegisterSkin then
			RegisterPfUISkin()
		end
	end)
end

-- workarround for the fact that temp. enchants are not loaded at the addon start
function EZP:AddonStart()
	EZP.Work.Time = EZP.Work.Time + arg1

	-- 只在第一次调用SkinButton，避免重复调用
	if not EZP.Work.SkinApplied then
		-- 调用SkinButton时传递图标纹理，这样图标不会被清空
		-- 必须先判断pfUI是否已加载，否则会报错
		if IsAddOnLoaded("pfUI") and pfUI and pfUI.api then
			if EZPMHButton and EZPMHButton.Icon then
				pfUI.api.SkinButton(EZPMHButton, nil, nil, nil, EZPMHButton.Icon)
			elseif EZPMHButton then
				pfUI.api.SkinButton(EZPMHButton)
			end
			if EZPOHButton and EZPOHButton.Icon then
				pfUI.api.SkinButton(EZPOHButton, nil, nil, nil, EZPOHButton.Icon)
			elseif EZPOHButton then
				pfUI.api.SkinButton(EZPOHButton)
			end
		end
		EZP.Work.SkinApplied = true
	end

	if EZP.Work.Time >= 2 then
		EZP.Work.Time = 0
		EZP.ConfigFrame:SetScript("OnUpdate", nil)
		EZP:UpdateTexture()
	end
end

-- -- 刷新FuBar菜单（重新生成菜单配置）
-- function EZP:RefreshMenu()
-- 	-- 重新生成菜单配置
-- 	EZP:ConfigFubar()
-- 	-- 尝试关闭并重新打开菜单以强制刷新
-- 	-- FuBar的菜单是动态生成的，每次打开时都会调用OnMenuRequest
-- 	if EZP.ACE and EZP.ACE.frame then
-- 		-- 检查是否有菜单框架
-- 		local menuFrame = EZP.ACE.frame.menuFrame
-- 		if menuFrame and menuFrame:IsVisible() then
-- 			-- 关闭菜单
-- 			menuFrame:Hide()
-- 			-- 使用延迟重新打开菜单
-- 			local refreshTimer = CreateFrame("Frame")
-- 			refreshTimer:SetScript("OnUpdate", function()
-- 				refreshTimer:SetScript("OnUpdate", nil)
-- 				refreshTimer = nil
-- 				-- 尝试重新打开菜单（如果用户还在右键点击状态）
-- 				-- 注意：这可能需要用户手动重新打开菜单
-- 			end)
-- 		end
-- 	end
-- end

local function getProfileName(index)
	local prefix = ''
	if EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == index then
		prefix = "|cFFFFCC00" .. "✔" .. "|r"
	end
	return prefix .. (EZPcfg.Profile[index].Name or ("方案 " .. index))
end

local options

function EZP:updateProfileName(index, name)
	-- options.args["Profile" .. index].name = name
	options.args["Profile" .. index].name = getProfileName(index)
	EZP:ConfigFubar()
end

function EZP:ConfigFubar()
	-- 动态生成配置文件名称
	-- 打钩标记通过checked属性显示，不需要在name中添加
	if not options then
		options = {
			handler = EZP.ACE,
			type = "group",
			args = {
				Profile1 = {
					name = getProfileName(1),
					type = "group",
					desc = "配置文件1修改",
					order = 1,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 1 end,
							set = function() EZP:SetProfile(1) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[1].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 1" end
								EZPcfg.Profile[1].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 1 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[1].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(1, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile2 = {
					name = getProfileName(2),
					type = "group",
					desc = "配置文件2修改",
					order = 2,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 2 end,
							set = function() EZP:SetProfile(2) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[2].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 2" end
								EZPcfg.Profile[2].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 2 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[2].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(2, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile3 = {
					name = getProfileName(3),
					type = "group",
					desc = "配置文件3修改",
					order = 3,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 3 end,
							set = function() EZP:SetProfile(3) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[3].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 3" end
								EZPcfg.Profile[3].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 3 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[3].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(3, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile4 = {
					name = getProfileName(4),
					type = "group",
					desc = "配置文件4修改",
					order = 4,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 4 end,
							set = function() EZP:SetProfile(4) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[4].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 4" end
								EZPcfg.Profile[4].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 4 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[4].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(4, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile5 = {
					name = getProfileName(5),
					type = "group",
					desc = "配置文件5修改",
					order = 5,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 5 end,
							set = function() EZP:SetProfile(5) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[5].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 5" end
								EZPcfg.Profile[5].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 5 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[5].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(5, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile6 = {
					name = getProfileName(6),
					type = "group",
					desc = "配置文件6修改",
					order = 6,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 6 end,
							set = function() EZP:SetProfile(6) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[6].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 6" end
								EZPcfg.Profile[6].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 6 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[6].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(6, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				Profile7 = {
					name = getProfileName(7),
					type = "group",
					desc = "配置文件7修改",
					order = 7,
					args = {
						Profiletoggle = {
							type = 'toggle',
							name = "启用",
							desc = "启用此配置文件",
							get = function() return EZPcfg.CurrentProfile and EZPcfg.CurrentProfile == 7 end,
							set = function() EZP:SetProfile(7) end,
							order = 1,
						},
						Profileuse = {
							type = 'text',
							name = "重命名",
							desc = "重命名此配置文件",
							get = function() return EZPcfg.Profile[7].Name end,
							set = function(value)
								if not value or value == "" then value = "方案 7" end
								EZPcfg.Profile[7].Name = value
								DEFAULT_CHAT_FRAME:AddMessage(
									"EzPoison: " ..
									"|cFFFFFFFF" .. "Profile 7 renamed to: " ..
									"|cFFCC9900" .. EZPcfg.Profile[7].Name .. "|r" .. "|cFFFFFFFF" .. "." .. "|r", 0.4, 0.8, 0.4)
								-- 刷新菜单以显示新名称
								EZP:updateProfileName(7, value)
							end,
							usage = "Renaming",
							order = 2,
						},
					},
				},
				scaling = {
					type = "range",
					name = "窗口缩放",
					desc = "UI界面的窗口缩放比例",
					min = 0.5,
					max = 2,
					step = 0.1,
					get = function()
						return EZPcfg.Scale
					end,
					set = function(value)
						EZP:ApplyScale(value)
					end,
					order = 8,
				},
				fadeInactive = {
					type = 'toggle',
					name = "未激活褪色",
					desc = "当未检测到武器磨刀石/毒药时，按钮是否褪色显示",
					get = function()
						return EZPcfg.FadeInactive == 1
					end,
					set = function(value)
						EZPcfg.FadeInactive = value and 1 or 0
						EZP:UpdateTexture() -- 更新显示以应用新设置
					end,
					order = 9,
				},
				leftWarn = {
					type='toggle',
					name="时长/次数不足文字提示",
					desc="激活的毒药/磨刀石次数或时长不足时出现文字提示",
					get = function()
						return EZPcfg.LeftWarn == 1
					end,
					set = function(value)
						EZPcfg.LeftWarn = value and 1 or 0
						EZP:UpdateTexture() -- 更新显示以应用新设置
					end,
					order = 10,
				},
				lockPosition = {
					type = 'toggle',
					name = "锁定位置",
					desc = "锁定窗口位置，锁定后窗口可点击穿透，但主副手按钮仍可正常交互",
					get = function()
						return EZPcfg.LockPosition == 1
					end,
					set = function(value)
						EZPcfg.LockPosition = value and 1 or 0
						EZP:ApplyLockPosition() -- 应用锁定状态
					end,
					order = 11,
				},
				apply = {
					type = 'toggle',
					name = "重置位置",
					desc = "重置窗口位置和缩放比例",
					get = function() end,
					set = function()
						-- 重置为默认基准位置（scale=1时的位置）
						EZPcfg.PosX = screenCenterX
						EZPcfg.PosY = -screenCenterY
						EZPcfg.Scale = 1
						local frame = EZP.ConfigFrame
						if frame then
							frame:SetScale(EZPcfg.Scale)
							frame:ClearAllPoints()
							-- 使用基准位置除以缩放值（缩放为1时就是基准位置）
							frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", EZPcfg.PosX / EZPcfg.Scale, EZPcfg.PosY / EZPcfg.Scale)
							if not frame:IsVisible() then
								frame:Show()
							end
						end
					end,
					order = 12,
				},
			},
		}
	end

	EZP.ACE.OnMenuRequest = options
end

function EZP:UpdateTexture()
	EZP.Work.slotInfo[1], EZP.Work.slotInfo[2], EZP.Work.slotInfo[3], EZP.Work.slotInfo[4], EZP.Work.slotInfo[5], EZP.Work.slotInfo[6], EZP.Work.slotInfo[7] =
			EZP.GetWeaponEnchantInfo()

	if EZP.Work.slotInfo[1] then
		EZP.Work.ID = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown) - 1
		for i = 1, 20 do
			EZP.Parser:SetOwner(UIParent, "ANCHOR_NONE")
			EZP.Work.ToolTipBuff = EZP.Parser:SetInventoryItem("player", 16)
			if not EZP.Work.ToolTipBuff or not getglobal(EZP.Parser:GetName() .. "TextLeft" .. i):GetText() or EZP.Work.ID > poisonsCount or EZP.Work.ID < 1 then
				EZP.Parser:Hide()
				if EZPcfg.FadeInactive == 1 then
					EZP.ConfigFrame.MainHand:SetAlpha(0.3)
				else
					EZP.ConfigFrame.MainHand:SetAlpha(1)
				end
				EZP.ConfigFrame.MainHand.Count:SetText("")
				break
			end
			local lowerText = gsub(string.lower(getglobal(EZP.Parser:GetName() .. "TextLeft" .. i):GetText()), "-", "")

			local notPoisonCheckResult = checkNotPoisonActive(EZP.Work.ID, lowerText, "MainHand")
			if notPoisonCheckResult then
				if notPoisonCheckResult == 2 then
					break
				elseif i == 20 then
					EZP.ConfigFrame.MainHand.Count:SetText("")
				end
			else
				if string.find(lowerText, gsub(string.lower(EZP.Work.Poison[EZP.Work.ID]), "-", "")) then
					EZP.ConfigFrame.MainHand:SetAlpha(1)

					if EZPcfg.LeftWarn == 1 and (EZP.Work.slotInfo[2] and EZP.Work.slotInfo[2] < 300000) or (EZP.Work.slotInfo[3] and EZP.Work.slotInfo[3] < 35) then
						EZP.ConfigFrame.MainHand.Background:SetVertexColor(1, 0, 0, 0.8)
						EZP.ConfigFrame.MainHand.Count:SetText(EZP.Work.slotInfo[3])
						if EZP.Work.slotInfo[3] > 30 then
							EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
						elseif EZP.Work.slotInfo[3] > 20 then
							EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 17, "OUTLINE")
						elseif EZP.Work.slotInfo[3] > 10 then
							EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 18, "OUTLINE")
						elseif EZP.Work.slotInfo[3] <= 10 then
							EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 21, "OUTLINE")
						end
						break
					end

					EZP.ConfigFrame.MainHand.Background:SetVertexColor(1, 1, 1, 0)
					EZP.ConfigFrame.MainHand.Count:SetText("")
					break
				end
			end
			-- if EZP.Work.ID == 9 then -- 磨刀石
			-- 	if string.find(lowerText, "磨快") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 10 then -- 平衡石
			-- 	if string.find(lowerText, "增重") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 11 then -- 元素磨刀石
			-- 	if string.find(lowerText, "致命一击 ") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 12 then -- 神圣磨刀石
			-- 	if string.find(lowerText, "+100 攻击强度vs亡灵") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- 	-- elseif EZP.Work.ID == 8 then
			-- 	-- 	if string.find(lowerText, '^（%d+分钟） %(%d+次%)$') then
			-- 	-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 	-- 		break
			-- 	-- 	end
			-- elseif EZP.Work.ID == 13 then -- 卓越巫师之油
			-- 	if string.find(lowerText, "卓越巫师之油") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 14 then -- 卓越法力之油
			-- 	if string.find(lowerText, "卓越法力之油") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 15 then -- 神圣巫师之油
			-- 	if string.find(lowerText, "+60 法术伤害vs亡灵") then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "MainHand")
			-- 		break
			-- 	end
			-- else
			-- 	if string.find(lowerText, gsub(string.lower(EZP.Work.Poison[EZP.Work.ID]), "-", "")) then
			-- 		EZP.ConfigFrame.MainHand:SetAlpha(1)

			-- 		if (EZP.Work.slotInfo[2] and EZP.Work.slotInfo[2] < 300000) or (EZP.Work.slotInfo[3] and EZP.Work.slotInfo[3] < 35) then
			-- 			EZP.ConfigFrame.MainHand.Background:SetVertexColor(1, 0, 0, 0.8)
			-- 			EZP.ConfigFrame.MainHand.Count:SetText(EZP.Work.slotInfo[3])
			-- 			if EZP.Work.slotInfo[3] > 30 then
			-- 				EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
			-- 			elseif EZP.Work.slotInfo[3] > 20 then
			-- 				EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 17, "OUTLINE")
			-- 			elseif EZP.Work.slotInfo[3] > 10 then
			-- 				EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 18, "OUTLINE")
			-- 			elseif EZP.Work.slotInfo[3] <= 10 then
			-- 				EZP.ConfigFrame.MainHand.Count:SetFont("Fonts\\ARIALN.TTF", 21, "OUTLINE")
			-- 			end
			-- 		else
			-- 			EZP.ConfigFrame.MainHand.Background:SetVertexColor(1, 1, 1, 0)
			-- 			EZP.ConfigFrame.MainHand.Count:SetText("")
			-- 		end
			-- 		break
			-- 	end
			-- end
		end
	else
		if EZPcfg.FadeInactive == 1 then
			EZP.ConfigFrame.MainHand:SetAlpha(0.3)
		else
			EZP.ConfigFrame.MainHand:SetAlpha(1)
		end
		EZP.ConfigFrame.MainHand.Count:SetText("")
	end

	if EZP.Work.slotInfo[4] then
		EZP.Work.ID = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown) - 1
		for i = 1, 20 do
			EZP.Parser:SetOwner(UIParent, "ANCHOR_NONE")
			EZP.Work.ToolTipBuff = EZP.Parser:SetInventoryItem("player", 17)
			if not EZP.Work.ToolTipBuff or not getglobal(EZP.Parser:GetName() .. "TextLeft" .. i):GetText() or EZP.Work.ID > poisonsCount or EZP.Work.ID < 1 then
				EZP.Parser:Hide()
				if EZPcfg.FadeInactive == 1 then
					EZP.ConfigFrame.OffHand:SetAlpha(0.3)
				else
					EZP.ConfigFrame.OffHand:SetAlpha(1)
				end
				EZP.ConfigFrame.OffHand.Count:SetText("")
				break
			end
			local lowerText = gsub(string.lower(getglobal(EZP.Parser:GetName() .. "TextLeft" .. i):GetText()), "-", "")
			local notPoisonCheckResult = checkNotPoisonActive(EZP.Work.ID, lowerText, "OffHand")
			if notPoisonCheckResult then
				if notPoisonCheckResult == 2 then
					break
				elseif i == 20 then
					EZP.ConfigFrame.OffHand.Count:SetText("")
				end
			else
			-- if EZP.Work.ID == 9 then -- 磨刀石
			-- 	if string.find(lowerText, "磨快") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 10 then -- 平衡石
			-- 	if string.find(lowerText, "增重") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 11 then -- 元素磨刀石
			-- 	if string.find(lowerText, "致命一击 ") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 12 then -- 神圣磨刀石
			-- 	if string.find(lowerText, "+100 攻击强度vs亡灵") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- 	-- elseif EZP.Work.ID == 8 then
			-- 	-- 	if string.find(lowerText, '^（%d+分钟） %(%d+次%)$') then
			-- 	-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 	-- 		break
			-- 	-- 	end
			-- elseif EZP.Work.ID == 13 then -- 卓越巫师之油
			-- 	if string.find(lowerText, "卓越巫师之油") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 14 then -- 卓越法力之油
			-- 	if string.find(lowerText, "卓越法力之油") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- elseif EZP.Work.ID == 15 then -- 神圣巫师之油
			-- 	if string.find(lowerText, "+60 法术伤害vs亡灵") then
			-- 		EZP.ConfigFrame.OffHand:SetAlpha(1)
			-- 		timeleftWarn(lowerText, "OffHand")
			-- 		break
			-- 	end
			-- else
				if string.find(lowerText, gsub(string.lower(EZP.Work.Poison[EZP.Work.ID]), "-", "")) then
					EZP.ConfigFrame.OffHand:SetAlpha(1)
					if EZPcfg.LeftWarn == 1 and (EZP.Work.slotInfo[5] and EZP.Work.slotInfo[5] < 300000) or (EZP.Work.slotInfo[6] and EZP.Work.slotInfo[6] < 35) then
						EZP.ConfigFrame.OffHand.Background:SetVertexColor(1, 0, 0, 0.8)
						EZP.ConfigFrame.OffHand.Count:SetText(EZP.Work.slotInfo[6])
						if EZP.Work.slotInfo[6] > 30 then
							EZP.ConfigFrame.OffHand.Count:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
						elseif EZP.Work.slotInfo[6] > 20 then
							EZP.ConfigFrame.OffHand.Count:SetFont("Fonts\\ARIALN.TTF", 17, "OUTLINE")
						elseif EZP.Work.slotInfo[6] > 10 then
							EZP.ConfigFrame.OffHand.Count:SetFont("Fonts\\ARIALN.TTF", 18, "OUTLINE")
						elseif EZP.Work.slotInfo[6] <= 10 then
							EZP.ConfigFrame.OffHand.Count:SetFont("Fonts\\ARIALN.TTF", 21, "OUTLINE")
						end
						break
					end

					EZP.ConfigFrame.OffHand.Background:SetVertexColor(1, 1, 1, 0)
					EZP.ConfigFrame.OffHand.Count:SetText("")
					break
				end
			end
		end
	else
		if EZPcfg.FadeInactive == 1 then
			EZP.ConfigFrame.OffHand:SetAlpha(0.3)
		else
			EZP.ConfigFrame.OffHand:SetAlpha(1)
		end
		EZP.ConfigFrame.OffHand.Count:SetText("")
	end

	EZP:UpdatePoisonCount()
end

function EZP:UpdatePoisonCount()
	if not EzPoison.loaded or table.getn(usableItems) == 0 then return end
	-- MainHand
	local countPoison, countPoisonOH = 0, 0
	local id, idOH = EZP:GetInventoryID("MH"), EZP:GetInventoryID("OH")
	local poisonName, poisonNameOH
	if id then
		poisonName = gsub(string.lower(EZP.Work.Poison[id[5]] .. id[3]), "-", "")
	end
	if idOH then
		poisonNameOH = gsub(string.lower(EZP.Work.Poison[idOH[5]] .. idOH[3]), "-", "")
	end

	if poisonName or poisonNameOH then
		-- 扫描所有背包，累加所有匹配物品的数量、
		for i = 0, 4 do
			local bagSize = GetContainerNumSlots(i)
			if bagSize and bagSize > 0 then
				for j = 1, bagSize do
					local _, itemCount = GetContainerItemInfo(i, j)
					if itemCount then
						if itemCount < 0 then itemCount = itemCount * -1 end
						local itemLink = GetContainerItemLink(i, j)
						if itemLink then
							local itemName = gsub(string.lower(gsub(itemLink, "^.*%[(.*)%].*$", "%1")), "-", "")
							-- DEFAULT_CHAT_FRAME:AddMessage('itemName='..itemName..', poisonName='..poisonName)
							if itemName == poisonName then
								countPoison = countPoison + (itemCount or 0)
							end
							if itemName == poisonNameOH then
								countPoisonOH = countPoisonOH + (itemCount or 0)
							end
						end
					end
				end
			end
		end
	end
	if poisonName then
		EZP.ConfigFrame.MainHand.Font:SetText(tostring(countPoison))
	else
		EZP.ConfigFrame.MainHand.Font:SetText("0")
	end
	if poisonNameOH then
		EZP.ConfigFrame.OffHand.Font:SetText(tostring(countPoisonOH))
	else
		EZP.ConfigFrame.OffHand.Font:SetText("0")
	end

	-- -- OffHand
	-- if idOH then
	--     local poisonName = gsub(string.lower(EZP.Work.Poison[idOH[5]]..idOH[3]), "-", "")
	--     -- 扫描所有背包，累加所有匹配物品的数量
	--     for i = 0, 4 do
	--         local bagSize = GetContainerNumSlots(i)
	--         if bagSize and bagSize > 0 then
	--             for j = 1, bagSize do
	--                 local _, itemCount = GetContainerItemInfo(i, j)
	--                 if itemCount then
	--                     local itemLink = GetContainerItemLink(i, j)
	--                     if itemLink then
	--                         local itemName = gsub(string.lower(gsub(itemLink, "^.*%[(.*)%].*$", "%1")), "-", "")
	--                         if itemName == poisonName then
	--                             countPoison = countPoison + (itemCount or 0)
	--                         end
	--                     end
	--                 end
	--             end
	--         end
	--     end
	-- end
	-- EZP.ConfigFrame.OffHand.Font:SetText(countPoison)
end

function EZP:GetInventoryID(hand)
	local offhandLevelDown = hand == 'OH' and
			UIDropDownMenu_GetSelectedID(EZPOffHandDD) == UIDropDownMenu_GetSelectedID(EZPMainHandDD)
	if hand then
		local H = 0
		if hand == "MH" then
			H = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown)
		elseif hand == "OH" then
			H = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown)
		end

		-- 速效毒药
		if H == 2 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药 VI" then
							return { i, j, " VI", 8928, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药 V" then
							return { i, j, " V", 8927, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药 IV" then
							return { i, j, " IV", 8926, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药 III" then
							return { i, j, " III", 6950, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药 II" then
							return { i, j, " II", 6949, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "速效毒药" then
							return { i, j, "", 6947, H - 1 }
						end
					end
				end
			end
		end

		-- 致命毒药
		if H == 3 then
			if not offhandLevelDown then
				for i = 0, 4 do
					for j = 1, 36 do
						if GetContainerItemInfo(i, j) then
							local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
							if link == "致命毒药 V" then
								return { i, j, " V", 20844, H - 1 }
							end
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致命毒药 IV" then
							return { i, j, " IV", 8985, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致命毒药 III" then
							return { i, j, " III", 8984, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致命毒药 II" then
							return { i, j, " II", 2893, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致命毒药" then
							return { i, j, "", 2892, H - 1 }
						end
					end
				end
			end
		end

		-- 致残毒药
		if H == 4 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致残毒药 II" then
							return { i, j, " II", 3776, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致残毒药" then
							return { i, j, "", 3775, H - 1 }
						end
					end
				end
			end
		end

		-- 致伤毒药
		if H == 5 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致伤毒药 IV" then
							return { i, j, " IV", 10922, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致伤毒药 III" then
							return { i, j, " III", 10921, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致伤毒药 II" then
							return { i, j, " II", 10920, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "致伤毒药" then
							return { i, j, "", 10918, H - 1 }
						end
					end
				end
			end
		end

		-- 腐蚀毒药
		if H == 6 then
			if not offhandLevelDown then
				for i = 0, 4 do
					for j = 1, 36 do
						if GetContainerItemInfo(i, j) then
							local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
							if link == "腐蚀毒药 II" then
								return { i, j, " II", 47409, H - 1 }
							end
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "腐蚀毒药" then
							return { i, j, "", 47408, H - 1 }
						end
					end
				end
			end
		end

		-- 麻痹毒药
		if H == 7 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "麻痹毒药 III" then
							return { i, j, " III", 9186, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "麻痹毒药 II" then
							return { i, j, " II", 6951, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "麻痹毒药" then
							return { i, j, "", 5237, H - 1 }
						end
					end
				end
			end
		end

		-- 煽动毒药
		if H == 8 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "煽动毒药" then
						return { i, j, "", 65032, H - 1 }
					end
				end
			end
		end

		-- 溶解毒药
		if H == 9 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "溶解毒药 II" then
							return { i, j, " II", 54010, H - 1 }
						end
					end
				end
			end
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) then
						local link = gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1")
						if link == "溶解毒药" then
							return { i, j, "", 54009, H - 1 }
						end
					end
				end
			end
		end

		-- 致密磨刀石
		if H == 10 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "致密磨刀石" then
						return { i, j, "", 12404, H - 1 }
					end
				end
			end
		end

		-- 致密平衡石
		if H == 11 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "致密平衡石" then
						return { i, j, "", 12643, H - 1 }
					end
				end
			end
		end

		-- 元素磨刀石
		if H == 12 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "元素磨刀石" then
						return { i, j, "", 18262, H - 1 }
					end
				end
			end
		end

		-- 神圣磨刀石
		if H == 13 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "神圣磨刀石" then
						return { i, j, "", 23122, H - 1 }
					end
				end
			end
		end

		-- 卓越巫师之油
		if H == 14 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "卓越巫师之油" then
						return { i, j, "", 20749, H - 1 }
					end
				end
			end
		end

		-- 卓越法力之油
		if H == 15 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "卓越法力之油" then
						return { i, j, "", 20748, H - 1 }
					end
				end
			end
		end

		-- 神圣巫师之油（return 第4位物品ID自填）
		if H == 16 then
			for i = 0, 4 do
				for j = 1, 36 do
					if GetContainerItemInfo(i, j) and gsub(GetContainerItemLink(i, j), "^.*%[(.*)%].*$", "%1") == "神圣巫师之油" then
						return { i, j, "", 23123, H - 1 }
					end
				end
			end
		end

		return nil
	end
end

function EZP:ApplyPoisen(hand)
	EZP:UpdateTexture()

	if hand and not EZP.Work.iSCasting then
		if hand == "OH" and not GetInventoryItemTexture("player", 17) then
			-- 没有副手
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFCC9900" .. "OffHand " ..
					"|r" .. "|cFFFFFFFF" .. "未装备副手。" .. "|r", 0.4, 0.8, 0.4)
			return
		end

		local id = EZP:GetInventoryID(hand)
		if id then
			EZP:RegisterEvent("SPELLCAST_START")
			EZP:RegisterEvent("SPELLCAST_STOP")
			EZP:RegisterEvent("SPELLCAST_INTERRUPTED")
			EZP:RegisterEvent("SPELLCAST_FAILED")
			UseContainerItem(id[1], id[2])
			if hand == "MH" then
				PickupInventoryItem(16)
			elseif hand == "OH" then
				PickupInventoryItem(17)
			end
			ReplaceEnchant()
			ClearCursor()
		else
			-- if hand == "MH" and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown) ~= 1 and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown) ~= 9 then
			-- 	DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFCC9900" .. "MainHand " ..
			-- 		"|r" .. "|cFFFFFFFF" .. "未发现毒药/磨刀石。" .. "|r", 0.4, 0.8, 0.4)
			-- elseif hand == "OH" and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown) ~= 1 and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown) ~= 9 then
			-- 	DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFCC9900" .. "OffHand " ..
			-- 		"|r" .. "|cFFFFFFFF" .. "未发现毒药/磨刀石。" .. "|r", 0.4, 0.8, 0.4)
			-- end

			local usingID
			if hand == "MH" then
				usingID = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown)
			else
				usingID = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown)
			end

			local itemName = usingID and EZP.Work.Poison[usingID - 1] or '毒药/磨刀石/油'

			if hand == "MH" and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown) ~= 1 then
				DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFCC9900" .. "MainHand " ..
					"|r" .. "|cFFFFFFFF" .. "未发现" .. itemName .. "。" .. "|r", 0.4, 0.8, 0.4)
			elseif hand == "OH" and UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown) ~= 1 then
				DEFAULT_CHAT_FRAME:AddMessage("EzPoison: " .. "|cFFCC9900" .. "OffHand " ..
					"|r" .. "|cFFFFFFFF" .. "未发现" .. itemName .. "。" .. "|r", 0.4, 0.8, 0.4)
			end
		end
	end
end

function EZP:AutoApplyPoison()
	EZP:UpdateTexture()
	if EZP.ConfigFrame.MainHand:GetAlpha() < 1 then
		EZP:ApplyPoisen("MH")
	elseif EZP.ConfigFrame.OffHand:GetAlpha() < 1 then
		EZP:ApplyPoisen("OH")
	end
end

function EZP:SaveProfiles()
	local MH = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown)
	local OH = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown)

	if MH and MH <= poisonsCount + 1 and MH >= 2 then
		EZPcfg.Profile[EZPcfg.CurrentProfile].MainHand = MH - 1
	else
		EZPcfg.Profile[EZPcfg.CurrentProfile].MainHand = 0
	end

	if OH and OH <= poisonsCount + 1 and OH >= 2 then
		EZPcfg.Profile[EZPcfg.CurrentProfile].OffHand = OH - 1
	else
		EZPcfg.Profile[EZPcfg.CurrentProfile].OffHand = 0
	end
end

function EZP:SetProfile(profileNum)
	if profileNum then EZPcfg.CurrentProfile = profileNum end

	for i = 1, 7 do
		EZP.ConfigFrame.ProfileButton[i]:SetNormalTexture("Interface\\AddOns\\EzPoison\\Media\\buttonD")
		if options and options.args and options.args["Profile" .. i] then
			options.args["Profile" .. i].name = getProfileName(i)
		end
	end
	EZP.ConfigFrame.ProfileButton[EZPcfg.CurrentProfile]:SetNormalTexture(
		"Interface\\AddOns\\EzPoison\\Media\\buttonDselected")

	UIDropDownMenu_SetSelectedID(getglobal("EZPMainHandDD"), EZPcfg.Profile[EZPcfg.CurrentProfile].MainHand + 1)
	UIDropDownMenu_SetSelectedID(getglobal("EZPOffHandDD"), EZPcfg.Profile[EZPcfg.CurrentProfile].OffHand + 1)
	--DEFAULT_CHAT_FRAME:AddMessage("EzPoison: ".."|cFFFFFFFF".."Profile: ".."|cFFCC9900"..EZPcfg.Profile[EZPcfg.CurrentProfile].Name.."|r".."|cFFFFFFFF".." set.".."|r",0.4,0.8,0.4)

	-- 刷新菜单以更新打钩标记
	-- EZP:RefreshMenu()

	EZP:UpdateSelection()
end

function EZP:UpdateSelection()
	local MH = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.MainHand.BorderDropdown)
	local OH = UIDropDownMenu_GetSelectedID(EZP.ConfigFrame.OffHand.BorderDropdown)

	-- 更新主手图标
	if MH and MH <= poisonsCount + 1 and MH >= 2 then
		local iconPath = EZP.Work.PoisonIcon[MH - 1]
		EZP.ConfigFrame.MainHand:SetNormalTexture(iconPath)
		-- 如果存在独立的图标纹理（用于pfUI皮肤），也更新它
		if EZP.ConfigFrame.MainHand.Icon then
			EZP.ConfigFrame.MainHand.Icon:SetTexture(iconPath)
		end
	else
		EZP.ConfigFrame.MainHand:SetNormalTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		if EZP.ConfigFrame.MainHand.Icon then
			EZP.ConfigFrame.MainHand.Icon:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		end
	end

	-- 更新副手图标
	if OH and OH <= poisonsCount + 1 and OH >= 2 then
		local iconPath = EZP.Work.PoisonIcon[OH - 1]
		EZP.ConfigFrame.OffHand:SetNormalTexture(iconPath)
		-- 如果存在独立的图标纹理（用于pfUI皮肤），也更新它
		if EZP.ConfigFrame.OffHand.Icon then
			EZP.ConfigFrame.OffHand.Icon:SetTexture(iconPath)
		end
	else
		EZP.ConfigFrame.OffHand:SetNormalTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		if EZP.ConfigFrame.OffHand.Icon then
			EZP.ConfigFrame.OffHand.Icon:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		end
	end

	-- 如果pfUI已加载且皮肤已应用，重新应用皮肤以确保样式正确
	-- 这可以修复切换方案时可能丢失的pfUI样式
	if IsAddOnLoaded("pfUI") and pfUI and pfUI.api and EZP.Work.SkinApplied then
		if EZPMHButton then
			if EZPMHButton.Icon then
				pfUI.api.SkinButton(EZPMHButton, nil, nil, nil, EZPMHButton.Icon)
			else
				pfUI.api.SkinButton(EZPMHButton)
			end
		end
		if EZPOHButton then
			if EZPOHButton.Icon then
				pfUI.api.SkinButton(EZPOHButton, nil, nil, nil, EZPOHButton.Icon)
			else
				pfUI.api.SkinButton(EZPOHButton)
			end
		end
	end

	EZP:UpdateTexture()
end

--additonal feature/ hooking temp-enchant OnUpdate function
function EZP:BuffFrame_Enchant_OnUpdate(elapsed)
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges =
			GetWeaponEnchantInfo();

	-- No enchants, kick out early
	if (not hasMainHandEnchant and not hasOffHandEnchant) then
		TempEnchant1:Hide();
		TempEnchant1Duration:Hide();
		TempEnchant2:Hide();
		TempEnchant2Duration:Hide();
		BuffFrame:SetPoint("TOPRIGHT", "TemporaryEnchantFrame", "TOPRIGHT", 0, 0);
		return;
	end
	-- Has enchants
	local enchantButton;
	local textureName;
	local buffAlphaValue;
	local enchantIndex = 0;
	if (hasOffHandEnchant) then
		enchantIndex = enchantIndex + 1;
		textureName = GetInventoryItemTexture("player", 17);
		TempEnchant1:SetID(17);
		TempEnchant1Icon:SetTexture(textureName);
		TempEnchant1:Show();
		hasEnchant = 1;

		-- Show buff durations if necessary
		if (offHandExpiration) then
			offHandExpiration = offHandExpiration / 1000;
		end
		if offHandCharges and offHandCharges > 0 then getglobal("TempEnchant1" .. "Count"):SetText(offHandCharges) end
		BuffFrame_UpdateDuration(TempEnchant1, offHandExpiration);

		-- Handle flashing
		if (offHandExpiration and offHandExpiration < BUFF_WARNING_TIME) then
			TempEnchant1:SetAlpha(BUFF_ALPHA_VALUE);
		else
			TempEnchant1:SetAlpha(1.0);
		end
	end
	if (hasMainHandEnchant) then
		enchantIndex = enchantIndex + 1;
		enchantButton = getglobal("TempEnchant" .. enchantIndex);
		textureName = GetInventoryItemTexture("player", 16);
		enchantButton:SetID(16);
		getglobal(enchantButton:GetName() .. "Icon"):SetTexture(textureName);
		enchantButton:Show();
		hasEnchant = 1;

		-- Show buff durations if necessary
		if (mainHandExpiration) then
			mainHandExpiration = mainHandExpiration / 1000;
		end
		if mainHandCharges and mainHandCharges > 0 then getglobal("TempEnchant2" .. "Count"):SetText(mainHandCharges) end
		BuffFrame_UpdateDuration(enchantButton, mainHandExpiration);

		-- Handle flashing
		if (mainHandExpiration and mainHandExpiration < BUFF_WARNING_TIME) then
			enchantButton:SetAlpha(BUFF_ALPHA_VALUE);
		else
			enchantButton:SetAlpha(1.0);
		end
	end
	--Hide unused enchants
	for i = enchantIndex + 1, 2 do
		getglobal("TempEnchant" .. i):Hide();
		getglobal("TempEnchant" .. i .. "Duration"):Hide();
	end

	-- Position buff frame
	TemporaryEnchantFrame:SetWidth(enchantIndex * 32);
	BuffFrame:SetPoint("TOPRIGHT", "TemporaryEnchantFrame", "TOPLEFT", -5, 0);
end

BuffFrame_Enchant_OnUpdate = EZP.BuffFrame_Enchant_OnUpdate

-- prompt
function EzPoisonPromt(arg1)
	arg1 = string.lower(arg1)
	if string.sub(arg1, 1, 5) == "scale" then
		local scale = tonumber(string.sub(arg1, 6, string.len(arg1)))
		if scale <= 3 and scale >= 0.3 then
			EZP:ApplyScale(scale)
		end
	elseif string.sub(arg1, 1, 5) == "apply" then
		EZP:AutoApplyPoison()
	elseif string.sub(arg1, 1, 7) == "profile" then
		local num = tonumber(string.sub(arg1, 8, string.len(arg1)))
		if num <= 7 and num >= 1 then
			EZP:SetProfile(num)
		end
	elseif string.sub(arg1, 1, 5) == "reset" then
		-- 重置位置和缩放
		-- 重置为默认基准位置（scale=1时的位置）
		EZPcfg.PosX = screenCenterX
		EZPcfg.PosY = -screenCenterY
		EZPcfg.Scale = 1
		local frame = EZP.ConfigFrame
		if frame then
			frame:SetScale(EZPcfg.Scale)
			frame:ClearAllPoints()
			-- 使用基准位置除以缩放值（缩放为1时就是基准位置）
			frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", EZPcfg.PosX / EZPcfg.Scale, EZPcfg.PosY / EZPcfg.Scale)
			frame:Show()
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口位置已重置", 0.4, 0.8, 0.4)
		end
	elseif string.sub(arg1, 1, 4) == "lock" then
		-- 锁定位置
		EZPcfg.LockPosition = 1
		EZP:ApplyLockPosition()
		DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口位置已锁定", 0.4, 0.8, 0.4)
	elseif string.sub(arg1, 1, 6) == "unlock" then
		-- 解锁位置
		EZPcfg.LockPosition = 0
		EZP:ApplyLockPosition()
		DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口位置已解锁", 0.4, 0.8, 0.4)
	elseif string.sub(arg1, 1, 3) == "pos" then
		-- 设置位置 pos x,y
		local _, _, x, y = string.find(arg1, "^pos%s+(%d+)[, ](%d+)")
		if x and y then
			x = tonumber(x)
			y = tonumber(y)
			EZPcfg.PosX = x
			EZPcfg.PosY = -y -- 注意：Y坐标需要取负值，因为使用的是TOPLEFT锚点
			EZP:ApplyPosition()
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口位置已设置为 (" .. x .. ", " .. y .. ")", 0.4, 0.8, 0.4)
		else
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 命令参数错误 (例: /ezpoison pos 100,100)", 1, 0, 0)
		end
	elseif string.sub(arg1, 1, 2) == "x " then
		-- 只设置X坐标 x 100
		local _, _, x = string.find(arg1, "^x%s+(%d+)")
		if x then
			x = tonumber(x)
			-- 如果PosY不存在，使用当前Y或默认值
			if not EZPcfg.PosY then
				local frame = EZP.ConfigFrame
				if frame then
					local a, _, b, _, currentY = frame:GetPoint()
					if currentY then
						local currentScale = frame:GetScale() or (EZPcfg.Scale or 1)
						EZPcfg.PosY = currentY * currentScale
					else
						EZPcfg.PosY = -screenCenterY
					end
				else
					EZPcfg.PosY = -screenCenterY
				end
			end
			EZPcfg.PosX = x
			EZP:ApplyPosition()
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口X位置已设置为 " .. x, 0.4, 0.8, 0.4)
		else
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 命令参数错误 (例: /ezpoison x 100)", 1, 0, 0)
		end
	elseif string.sub(arg1, 1, 2) == "y " then
		-- 只设置Y坐标 y 100
		local _, _, y = string.find(arg1, "^y%s+(%d+)")
		if y then
			y = tonumber(y)
			-- 如果PosX不存在，使用当前X或默认值
			if not EZPcfg.PosX then
				local frame = EZP.ConfigFrame
				if frame then
					local a, _, b, currentX = frame:GetPoint()
					if currentX then
						local currentScale = frame:GetScale() or (EZPcfg.Scale or 1)
						EZPcfg.PosX = currentX * currentScale
					else
						EZPcfg.PosX = screenCenterX
					end
				else
					EZPcfg.PosX = screenCenterX
				end
			end
			EZPcfg.PosY = -y -- 注意：Y坐标需要取负值，因为使用的是TOPLEFT锚点
			EZP:ApplyPosition()
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 窗口Y位置已设置为 " .. y, 0.4, 0.8, 0.4)
		else
			DEFAULT_CHAT_FRAME:AddMessage("EzPoison: 命令参数错误 (例: /ezpoison y 100)", 1, 0, 0)
		end
	elseif arg1 == nil or arg1 == "" then
		if EZP.ConfigFrame:IsVisible() then
			EZP.ConfigFrame:Hide()
		else
			EZP:UpdateTexture(); EZP.ConfigFrame:Show()
		end
	end
end

function EzPoisonProfile(num) EZP:SetProfile(num) end

function EzPoisonApply() EZP:AutoApplyPoison() end

function EzPoisonToggle()
	if EZP.ConfigFrame:IsVisible() then
		EZP.ConfigFrame:Hide()
	else
		EZP:UpdateTexture(); EZP.ConfigFrame:Show()
	end
end

-- binding list
BINDING_HEADER_HEAD = "EzPoison"

SlashCmdList['EZPOISON'] = EzPoisonPromt
SLASH_EZPOISON1 = '/ezpoison'
SLASH_EZPOISON2 = '/EzPoison'
