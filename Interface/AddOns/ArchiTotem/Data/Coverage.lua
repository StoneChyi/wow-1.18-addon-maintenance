-- ArchiTotem 覆盖窗口模块
-- 显示每系图腾未覆盖的队友（按职业染色）

-- ================= Nampower 依赖检测 =================
local function ArchiTotem_HasNampower()
    if not GetNampowerVersion then return false end
    local major, minor = GetNampowerVersion()
    return major and (major > 4 or (major == 4 and (minor or 0) >= 5))
end

local hasNampower = ArchiTotem_HasNampower()  -- 首次加载时检测

-- 若没有 Nampower，则后续所有功能直接跳过
if not hasNampower then
    -- 定义占位函数以避免报错，并可在命令中给出提示
    function ArchiTotem_ToggleCoverageWindow()
        ArchiTotem_Print("图腾覆盖窗口需要 Nampower 4.5+ 才能使用", "error")
    end
    function ArchiTotem_UpdateCoverageWindow()
        -- 静默忽略
    end
    return  -- 停止加载本文件剩余部分
end

local CLOCK_UPDATE = 0.5  -- 刷新间隔

-- 职业颜色表（如果游戏内未定义则用默认）
local CLASS_COLORS = {
	["WARRIOR"]    = { 0.78, 0.61, 0.43 },
	["PALADIN"]    = { 0.96, 0.55, 0.73 },
	["HUNTER"]     = { 0.67, 0.83, 0.45 },
	["ROGUE"]      = { 1.00, 0.96, 0.41 },
	["PRIEST"]     = { 1.00, 1.00, 1.00 },
	["SHAMAN"]     = { 0.00, 0.44, 1.00 },
	["MAGE"]       = { 0.41, 0.80, 0.94 },
	["WARLOCK"]    = { 0.58, 0.51, 0.79 },
	["DRUID"]      = { 1.00, 0.49, 0.04 },
}
setmetatable(CLASS_COLORS, {__index = function() return {0.6,0.6,0.6} end})

-- 获取当前组队成员列表（包括自己）
local function ArchiTotem_GetGroupUnits()
	local units = {}
    table.insert(units, "player")

    if GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local unit = "party"..i
            if UnitExists(unit) then
                table.insert(units, unit)
            end
        end
    end
	return units
end

-- 判断单位是否在图腾覆盖范围内
local function ArchiTotem_IsUnitCoveredByTotem(unit, totemGuid)
	local unitGuid = GetUnitGUID(unit)
	if not unitGuid or not totemGuid then return false end
	local dist = UnitXP("distanceBetween", totemGuid, unitGuid)
	return dist and dist <= 30
end

-- 获取未覆盖名字列表（已染色字符串）
local function ArchiTotem_GetUncoveredNames(element)
	if not ArchiTotem_ActivePlacedTotems then return "" end
	
	local totemGuid = nil
	for guid, data in pairs(ArchiTotem_ActivePlacedTotems) do
		if data.element == element then
			totemGuid = guid
			break
		end
	end
	
	if not totemGuid then
		return "|cFF888888无图腾|r"
	end
	
	local units = ArchiTotem_GetGroupUnits()
	local uncovered = {}
	for _, unit in ipairs(units) do
		if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
			if not ArchiTotem_IsUnitCoveredByTotem(unit, totemGuid) then
				local name, _ = UnitName(unit)
				local _,class = UnitClass(unit)
				local color = CLASS_COLORS[class] or {0.6,0.6,0.6}
				local coloredName = string.format("|cff%02x%02x%02x%s|r",
					color[1]*255, color[2]*255, color[3]*255, name)
				table.insert(uncovered, coloredName)
			end
		end
	end
	
	if table.getn(uncovered) == 0 then
		return "|cFF00FF00全部覆盖|r"
	else
		return table.concat(uncovered, "  ")
	end
end

-- 刷新整个窗口内容
function ArchiTotem_UpdateCoverageWindow()
	if not ArchiTotemCoverageFrame or not ArchiTotemCoverageFrame:IsVisible() then return end
	
	local elements = {"Earth", "Fire", "Water", "Air"}
	for _, el in ipairs(elements) do
		local namesText = _G["ArchiTotemCoverage_"..el.."Names"]
		if namesText then
			-- 若字体未设置，强制指定一个可用字体
			if not namesText:GetFont() then
				namesText:SetFont("Fonts\\FRIZQT__.TTF", 12)
			end
			namesText:SetText(ArchiTotem_GetUncoveredNames(el))
		end
	end
end

-- 切换覆盖窗口显隐
function ArchiTotem_ToggleCoverageWindow()
	if not ArchiTotemCoverageFrame then return end
	if ArchiTotemCoverageFrame:IsVisible() then
		ArchiTotemCoverageFrame:Hide()
		ArchiTotem_Print("覆盖窗口已关闭")
	else
		ArchiTotemCoverageFrame:Show()
		ArchiTotem_UpdateCoverageWindow()
		ArchiTotem_Print("覆盖窗口已打开")
	end
end

-- 在原有的 OnUpdate 中添加覆盖窗口更新逻辑
-- 我们通过hook或修改 Core.lua 的 ArchiTotem_OnUpdate 来调用
local originalOnUpdate = ArchiTotem_OnUpdate
function ArchiTotem_OnUpdate(arg1)
	originalOnUpdate(arg1)
	if ArchiTotemCoverageFrame and ArchiTotemCoverageFrame:IsVisible() then
		this.CoverageUpdateTimer = (this.CoverageUpdateTimer or 0) + arg1
		if this.CoverageUpdateTimer > CLOCK_UPDATE then
			ArchiTotem_UpdateCoverageWindow()
			this.CoverageUpdateTimer = 0
		end
	end
end