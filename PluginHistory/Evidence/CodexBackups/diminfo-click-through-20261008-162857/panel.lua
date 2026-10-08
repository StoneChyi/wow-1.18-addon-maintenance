--来自EK的diminfo，1.12修改by狗血编剧男
local MediaFolder = "Interface\\AddOns\\diminfo\\Media\\"

-- 获取当前角色的唯一标识符（服务器名-角色名）
local function GetCharacterKey()
    return GetRealmName() .. "-" .. UnitName("player")
end

-- 获取当前角色的配置，如果不存在则创建默认配置
local function GetCharacterConfig()
    local charKey = GetCharacterKey()

    -- 确保全局配置表存在
    if not DimInfo_Config then
        DimInfo_Config = {}
    end

    -- 如果当前角色配置不存在，创建默认配置
    if not DimInfo_Config[charKey] then
        DimInfo_Config[charKey] = {
            x = 0,
            spacing = 20,  -- 添加间距设置，默认20
            Hidden = {},
            OrderLeft = { "diminfo_Performance", "diminfo_RaidCD", "diminfo_Quest", "diminfo_Friend", "diminfo_Time" },
            OrderRight = { "diminfo_Loaddll", "diminfo_Durability", "diminfo_Bag", "diminfo_Gold" },
            ShowSeconds = false,  -- 默认不显示秒
            FontSize = 14,  -- 添加字体大小设置，默认14
            FadeMode = false,  -- 渐隐模式默认关闭
            FadeAlpha = 0.15   -- 渐隐透明度默认值
        }
    end

    -- 确保配置字段存在
    local config = DimInfo_Config[charKey]
    if not config.Hidden then config.Hidden = {} end
    if not config.OrderLeft then
        config.OrderLeft = { "diminfo_Performance", "diminfo_RaidCD", "diminfo_Quest", "diminfo_Friend", "diminfo_Time" }
    end
    if not config.OrderRight then
        config.OrderRight = { "diminfo_Loaddll", "diminfo_Durability", "diminfo_Bag", "diminfo_Gold" }
    end
    if config.x == nil then config.x = 0 end
    if config.spacing == nil then config.spacing = 20 end  -- 确保间距字段存在
    if config.ShowSeconds == nil then config.ShowSeconds = false end  -- 确保显示秒字段存在
    if config.FontSize == nil then config.FontSize = 14 end  -- 确保字体大小字段存在
    if config.FadeMode == nil then config.FadeMode = false end  -- 确保渐隐模式字段存在（默认关闭）
    if config.FadeAlpha == nil then config.FadeAlpha = 0.15 end  -- 确保渐隐透明度字段存在

    return config
end

-- 重置当前角色配置到默认状态
local function ResetCharacterConfig()
    local charKey = GetCharacterKey()

    DimInfo_Config[charKey] = {
        x = 0,
        spacing = 20,  -- 重置为默认间距
        Hidden = {},
        OrderLeft = { "diminfo_Performance", "diminfo_RaidCD", "diminfo_Quest", "diminfo_Friend", "diminfo_Time" },
        OrderRight = { "diminfo_Loaddll", "diminfo_Durability", "diminfo_Bag", "diminfo_Gold" },
        ShowSeconds = false,  -- 默认不显示秒
        FontSize = 14,  -- 重置为默认字体大小
        FadeMode = false,  -- 重置渐隐模式为关闭
        FadeAlpha = 0.15   -- 重置渐隐透明度
    }

    return DimInfo_Config[charKey]
end

-- 保存当前角色配置
local function SaveCharacterConfig()
    -- 配置已经通过引用更新，不需要额外保存
    -- WoW会自动保存全局变量DimInfo_Config
end

-- 所有模块 Frame 名（渐隐 / 字体大小等全局效果共用）
local AllModuleNames = {
    "diminfo_Time", "diminfo_RaidCD", "diminfo_Quest", "diminfo_pos",
    "diminfo_Performance", "diminfo_Loaddll", "diminfo_Gold",
    "diminfo_Friend", "diminfo_Durability", "diminfo_Bag"
}

-- 更新所有模块字体大小
local function UpdateAllModulesFontSize()
    local config = GetCharacterConfig()
    local fontSize = config.FontSize or 14

    for _, name in pairs(AllModuleNames) do
        local frame = getglobal(name)
        if frame then
            -- 遍历Frame的所有区域，查找FontString对象
            local regions = {frame:GetRegions()}
            local fontStringsProcessed = 0

            for _, region in ipairs(regions) do
                if region:GetObjectType() == "FontString" then
                    local _, _, fontFlags = region:GetFont()
                    region:SetFont(STANDARD_TEXT_FONT, fontSize, fontFlags)
                    fontStringsProcessed = fontStringsProcessed + 1

                    -- 对于金币模块，最多处理3个FontString（金、银、铜）
                    if name == "diminfo_Gold" and fontStringsProcessed >= 3 then
                        break
                    end
                end
            end

            -- 特殊处理金币模块：还需要检查子Frame中的FontString
            if name == "diminfo_Gold" then
                local children = {frame:GetChildren()}
                for _, child in ipairs(children) do
                    local childRegions = {child:GetRegions()}
                    for _, region in ipairs(childRegions) do
                        if region:GetObjectType() == "FontString" then
                            local _, _, fontFlags = region:GetFont()
                            region:SetFont(STANDARD_TEXT_FONT, fontSize, fontFlags)
                        end
                    end
                end
            end
        end
    end
end

--创建框架
local CreatePanel = function(anchor, parent, relativeTo, x, y, w, h, a)
	local panel = CreateFrame("Frame", "diminfopanel", parent)
	local framelvl = parent:GetFrameLevel()

	-- 使用保存的位置或默认位置
    -- 先获取默认配置，等VARIABLES_LOADED后再更新
    local defaultCfg = { x = x, spacing = 20, Hidden = {}, FontSize = 14 }
    local cfg = defaultCfg  -- 临时使用默认值，事件加载后会更新

	--中间
    panel:SetWidth(w)
	panel:SetHeight(h)
	panel:ClearAllPoints()
	-- 仅使用 X 偏移，保持 Y 和其他锚点固定 (根据用户需求，主要是左右移动)
    -- 如果这里写死了 CENTER/TOP，那么 x 就是相对屏幕中心的偏移
	panel:SetPoint("CENTER", parent, "TOP", cfg.x or x, -10)
	panel:SetFrameStrata("BACKGROUND")
	panel:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)

	panel:SetBackdropColor(.1, .1, .1, a)
	panel:SetBackdropBorderColor(0, 0, 0)
	panel.bg = panel:CreateTexture(nil, "BACKGROUND")
	panel.bg:SetAllPoints(panel)
	panel.bg:SetTexture(MediaFolder.."bar")
	panel.bg:SetVertexColor(.1, .1, .1, a)

	--左侧渐变
	local left = CreateFrame("Frame", nil, parent)
	left:SetWidth(50)
	left:SetHeight(h)
	left:ClearAllPoints()
	left:SetPoint("RIGHT", panel, "LEFT", 0, 0)
	left:SetFrameStrata("BACKGROUND")
	left:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)

	left.bg = left:CreateTexture(nil, "BACKGROUND")
	left.bg:SetAllPoints(left)
	left.bg:SetTexture(MediaFolder.."bar")
	left.bg:SetGradientAlpha("HORIZONTAL", .1, .1, .1, 0, .1, .1, .1, a)

	--右侧渐变
	local right = CreateFrame("Frame", nil, parent)
	right:SetWidth(50)
	right:SetHeight(h)
	right:ClearAllPoints()
	right:SetPoint("LEFT", panel, "RIGHT", 0, 0)
	right:SetFrameStrata("BACKGROUND")
	right:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)

	right.bg = right:CreateTexture(nil, "BACKGROUND")
	right.bg:SetAllPoints(right)
	right.bg:SetTexture(MediaFolder.."bar")
	right.bg:SetGradientAlpha("HORIZONTAL", .1, .1, .1, a, .1, .1, .1, 0)

	-- ================= 渐隐模式 =================
	-- 开启后：鼠标不在信息条上时整体淡出到 FadeAlpha，悬停时淡入
	local fadeAlpha = 0.15      -- 渐隐后的透明度
	local fadeTarget = 1        -- 当前目标透明度
	local lastHover = 0         -- 最后一次悬停时间（用于缝隙防闪烁延迟）

	-- 整体设置透明度：主面板 + 左右渐变 + 所有模块
	panel.ApplyFadeAlpha = function(alpha)
		panel:SetAlpha(alpha)
		left:SetAlpha(alpha)
		right:SetAlpha(alpha)
		for _, name in pairs(AllModuleNames) do
			local f = getglobal(name)
			if f then f:SetAlpha(alpha) end
		end
	end

	-- 鼠标是否在某个 Frame 区域内
	local IsOverFrame = function(f)
		if not f or not f.GetLeft then return false end
		local l, r, b, t = f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
		if not (l and r and b and t) then return false end
		local scale = f:GetEffectiveScale() or 1
		local x, y = GetCursorPosition()
		x = x / scale
		y = y / scale
		return x >= l and x <= r and y >= b and y <= t
	end

	-- 鼠标是否在信息条任意区域（面板 / 渐变 / 各模块文本）
	panel.IsBarHovered = function()
		if IsOverFrame(panel) or IsOverFrame(left) or IsOverFrame(right) then return true end
		for _, name in pairs(AllModuleNames) do
			local f = getglobal(name)
			if f and f:IsShown() and IsOverFrame(f) then return true end
		end
		return false
	end

	-- 开关渐隐模式（关闭时立刻恢复完全不透明）
	panel.SetFadeMode = function(enabled)
		local config = GetCharacterConfig()
		config.FadeMode = enabled and true or false
		if not config.FadeMode then
			fadeTarget = 1
			panel.ApplyFadeAlpha(1)
		end
	end

	-- 设置渐隐后的透明度
	panel.SetFadeAlpha = function(newAlpha)
		local config = GetCharacterConfig()
		config.FadeAlpha = newAlpha
		fadeAlpha = newAlpha
	end

	panel:SetScript("OnUpdate", function()
		if not GetCharacterConfig().FadeMode then return end
		if panel.IsBarHovered() then
			lastHover = GetTime()
			fadeTarget = 1
		elseif GetTime() - lastHover > 0.8 then
			-- 鼠标离开一小段时间后才开始渐隐，避免模块缝隙处来回闪烁
			fadeTarget = fadeAlpha
		end
		local cur = panel:GetAlpha()
		if math.abs(cur - fadeTarget) < 0.01 then
			if cur ~= fadeTarget then panel.ApplyFadeAlpha(fadeTarget) end
			return
		end
		panel.ApplyFadeAlpha(cur + (fadeTarget - cur) * 0.15)
	end)
	-- =============== 渐隐模式结束 ===============

    -- 更新位置函数
    panel.UpdatePosition = function(newX)
        local config = GetCharacterConfig()
        config.x = newX
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", parent, "TOP", newX, -10)
    end

    -- 更新间距函数
    panel.UpdateSpacing = function(newSpacing)
        local config = GetCharacterConfig()
        config.spacing = newSpacing
        panel.ReanchorModules()  -- 重新锚定模块以应用新间距
    end

    -- 更新字体大小函数
    panel.UpdateFontSize = function(newFontSize)
        local config = GetCharacterConfig()
        config.FontSize = newFontSize
        SaveCharacterConfig()
        UpdateAllModulesFontSize()
    end

    -- 重新锚定模块以消除空隙
    panel.ReanchorModules = function()
        local config = GetCharacterConfig()

        -- 确保配置存在
        if not config.OrderLeft then
            config.OrderLeft = { "diminfo_Friend", "diminfo_Time", "diminfo_RaidCD", "diminfo_Quest" }
        end
        if not config.OrderRight then
            config.OrderRight = { "diminfo_Loaddll", "diminfo_Performance", "diminfo_Durability", "diminfo_Bag", "diminfo_Gold" }
        end

        local posFrame = getglobal("diminfo_pos")
        local isPosVisible = posFrame and not config.Hidden["diminfo_pos"]

        -- 获取当前间距设置
        local spacing = config.spacing or 20
        local centerSpacing = spacing / 2  -- 中心间距为一半
        -- 左侧链 (向左延伸)
        -- 用户需求：1 (最左) -> 2 -> 3 -> [Center]
        -- 所以我们需要倒序遍历：先锚定 index=Max (靠近 Center)，然后 index=Max-1 锚定到 index=Max ...
        local leftChain = config.OrderLeft
        local leftCount = table.getn(leftChain)

        local lastAnchor = posFrame -- 默认锚点 (Center)
        local lastAnchorPoint = "LEFT" -- 默认锚点连接点
        local myAnchorPoint = "RIGHT" -- 模块连接点
        local xOffset = -spacing  -- 使用配置的间距

        if not isPosVisible then
            -- 如果中间的位置模块隐藏了，第一个左侧模块 (index=Max) 锚定到主面板中心左侧
            lastAnchor = panel
            lastAnchorPoint = "CENTER"
            xOffset = -centerSpacing  -- 使用中心间距
        end

        -- 倒序遍历: 从靠近中心 (Index=Max) 到远离中心 (Index=1)
        for i = leftCount, 1, -1 do
            local name = leftChain[i]
            local frame = getglobal(name)
            if frame and not config.Hidden[name] then
                -- 查找该 Frame 下的第一个 FontString
                local regions = {frame:GetRegions()}
                local textRegion = nil
                for _, region in ipairs(regions) do
                    if region:GetObjectType() == "FontString" then
                        textRegion = region
                        break
                    end
                end

                -- 特殊处理金币模块（无论在左侧还是右侧）
                if name == "diminfo_Gold" then
                    -- 先锚定整个Frame
                    frame:ClearAllPoints()
                    frame:SetPoint(myAnchorPoint, lastAnchor, lastAnchorPoint, xOffset, 0)

                    -- 如果文字存在，将其锚定到Frame的左侧
                    if textRegion then
                        textRegion:ClearAllPoints()
                        textRegion:SetPoint("LEFT", frame, "LEFT", 2, 0)
                    end

                    lastAnchor = frame
                    lastAnchorPoint = "LEFT"  -- 下一个模块应该锚定到金币Frame的左侧
                else
                    -- 标准模块
                    if textRegion then
                        textRegion:ClearAllPoints()
                        textRegion:SetPoint(myAnchorPoint, lastAnchor, lastAnchorPoint, xOffset, 0)

                        lastAnchor = frame
                        lastAnchorPoint = "LEFT"
                    end
                end

                xOffset = -spacing  -- 使用配置的间距
            end
        end

        -- 右侧链 (向右延伸)
        -- 保持正序：[Center] -> 1 -> 2 -> 3
        local rightChain = config.OrderRight

        lastAnchor = posFrame
        lastAnchorPoint = "RIGHT"
        myAnchorPoint = "LEFT"
        xOffset = spacing  -- 使用配置的间距

        if not isPosVisible then
            lastAnchor = panel
            lastAnchorPoint = "CENTER"
            xOffset = centerSpacing  -- 使用中心间距
        end

        for _, name in ipairs(rightChain) do
            local frame = getglobal(name)
            if frame and not config.Hidden[name] then
                -- 查找 FontString
                local regions = {frame:GetRegions()}
                local textRegion = nil
                for _, region in ipairs(regions) do
                    if region:GetObjectType() == "FontString" then
                        textRegion = region
                        break
                    end
                end

                -- 特殊处理金币模块（无论在左侧还是右侧）
                if name == "diminfo_Gold" then
                    -- 先锚定整个Frame
                    frame:ClearAllPoints()
                    frame:SetPoint(myAnchorPoint, lastAnchor, lastAnchorPoint, xOffset, 0)

                    -- 如果文字存在，将其锚定到Frame的左侧
                    if textRegion then
                        textRegion:ClearAllPoints()
                        textRegion:SetPoint("LEFT", frame, "LEFT", 2, 0)
                    end

                    lastAnchor = frame
                    lastAnchorPoint = "RIGHT"  -- 下一个模块应该锚定到金币Frame的右侧
                else
                    -- 标准模块
                    if textRegion then
                        textRegion:ClearAllPoints()
                        textRegion:SetPoint(myAnchorPoint, lastAnchor, lastAnchorPoint, xOffset, 0)

                        lastAnchor = frame
                        lastAnchorPoint = "RIGHT"
                    end
                end

                xOffset = spacing  -- 使用配置的间距
            end
        end
    end

    -- 应用模块可见性
    panel.ApplyVisibility = function()
        local config = GetCharacterConfig()

        -- 模块列表 (仅用于初始隐藏/显示，顺序不重要)
        local allModules = {
            "diminfo_Time", "diminfo_RaidCD", "diminfo_Quest", "diminfo_pos",
            "diminfo_Performance", "diminfo_Loaddll", "diminfo_Gold",
            "diminfo_Friend", "diminfo_Durability", "diminfo_Bag"
        }

        for _, name in pairs(allModules) do
            local frame = getglobal(name)
            if frame then
                if config.Hidden[name] then
                    frame:Hide()
                else
                    frame:Show()
                end
            end
        end

        panel.ReanchorModules()
    end

    -- 重置所有模块到默认状态
    panel.ResetAllModules = function()
        -- 重置配置
        local config = ResetCharacterConfig()

        -- 更新UI
        panel.UpdatePosition(config.x or 0)
        panel.UpdateSpacing(config.spacing or 20)
        panel.UpdateFontSize(config.FontSize or 14)  -- 重置字体大小
        panel.SetFadeMode(config.FadeMode)  -- 重置渐隐模式（关闭并恢复不透明）
        panel.SetFadeAlpha(config.FadeAlpha or 0.15)  -- 重置渐隐透明度
        panel.ApplyVisibility()

        --刷新设置页面
        if DimInfoOptions and DimInfoOptions.RefreshList then
            DimInfoOptions:RefreshList()
        end

        -- 刷新时间显示
        if DimInfo_Time_UpdateDisplay then
            DimInfo_Time_UpdateDisplay()
        end
    end

	panel:SetScript("OnEnter", function()
	    GameTooltip:SetOwner(panel, "ANCHOR_TOP")
	    GameTooltip:SetText("信息条")
	    GameTooltip:AddLine("右键打开设置界面", 1, 1, 1)
	    GameTooltip:Show()
    end)

    panel:SetScript("OnLeave", function()
	    GameTooltip:Hide()
    end)

	return panel
end

--锚点, 父级框架, 依靠, X, Y, 宽, 高, 透明
-- 注意：这里传入的参数将作为默认值，实际加载时会使用 SavedVariables
local frame = CreatePanel("CENTER", UIParent, "TOP", 0, -10, 480, 22, 0)

------------------------------------------------------------
-- 配置面板（拖拽排序 + 美化UI）
------------------------------------------------------------
local optionsFrame
local optionsContent

-- 模块名称映射 (Friendly Name)
local niceNames = {
    diminfo_pos = "位置",
    diminfo_Friend = "好友",
    diminfo_Time = "时间",
    diminfo_RaidCD = "团本CD",
    diminfo_Quest = "任务",
    diminfo_Performance = "性能",
    diminfo_Loaddll = "模组",
    diminfo_Durability = "耐久",
    diminfo_Bag = "背包",
    diminfo_Gold = "金币"
}

-- ===== 拖拽排序状态 =====
local dragState = nil  -- { list="left"/"right", index=n, name="模块名" }

local function AddBorder(f, r, g, b, a)
    local function newEdge()
        local tex = f:CreateTexture(nil, "BORDER")
        tex:SetTexture(r, g, b)
        if a then tex:SetAlpha(a) end
        return tex
    end
    local top = newEdge()
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    local bottom = newEdge()
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    local left = newEdge()
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    local right = newEdge()
    right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
end

local function IsCursorOver(f)
    if not f or not f.GetLeft then return false end
    local left = f:GetLeft()
    local right = f:GetRight()
    local bottom = f:GetBottom()
    local top = f:GetTop()
    if not (left and right and bottom and top) then return false end
    local scale = f:GetEffectiveScale() or 1
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale
    return x >= left and x <= right and y >= bottom and y <= top
end

-- 创建拖拽时的"幽灵"提示框（跟随鼠标，显示被拖动的模块名）
local function CreateDragGhost()
    if DimInfoDragGhost then return DimInfoDragGhost end
    local ghost = CreateFrame("Frame", "DimInfoDragGhost", UIParent)
    ghost:SetWidth(110)
    ghost:SetHeight(22)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetFrameLevel(120)
    ghost:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    ghost:SetBackdropColor(0.08, 0.08, 0.13, 0.95)
    AddBorder(ghost, 1, 0.82, 0, 0.8)
    ghost.text = ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ghost.text:SetPoint("CENTER", ghost, "CENTER", 0, 0)
    ghost:EnableMouse(false)  -- 不拦截鼠标，避免影响目标行的判定
    ghost:Hide()
    return ghost
end

local function ClearDragVisuals()
    if DimInfoDragGhost then DimInfoDragGhost:Hide() end
    if optionsContent and optionsContent.rows then
        for i = 1, table.getn(optionsContent.rows) do
            local r = optionsContent.rows[i]
            if r then
                if r.drop then r.drop:Hide() end
                r:SetAlpha(1)
            end
        end
    end
end

local function CancelDrag()
    dragState = nil
    ClearDragVisuals()
end

local function MoveModuleTo(srcList, srcIndex, dstList, dstIndex)
    local cfg = GetCharacterConfig()
    local sList = (srcList == "left") and cfg.OrderLeft or cfg.OrderRight
    local dList = (dstList == "left") and cfg.OrderLeft or cfg.OrderRight
    if not sList or not dList then return end
    if sList == dList and srcIndex == dstIndex then return end
    if not sList[srcIndex] then return end
    local item = sList[srcIndex]
    table.remove(sList, srcIndex)
    table.insert(dList, dstIndex, item)
end

local function CommitOrder()
    SaveCharacterConfig()
    frame.ApplyVisibility()
    if optionsFrame and optionsFrame.RefreshList then
        optionsFrame:RefreshList()
    end
end

-- 松手时解析落点并应用排序。
local function ResolveDrop()
    if not dragState then return end
    local src = dragState
    local d = nil
    if optionsContent and optionsContent.rows then
        for i = 1, table.getn(optionsContent.rows) do
            local r = optionsContent.rows[i]
            if r and r:IsShown() and r.data and IsCursorOver(r) then
                d = r.data
                break
            end
        end
    end
    local handled = false
    if d then
        if d.type == "item" and d.list ~= "center" then
            MoveModuleTo(src.list, src.index, d.list, d.index)
            handled = true
        elseif d.type == "header" and d.side == "left" then
            -- 拖到左侧分组标题 = 放到左侧第一位
            MoveModuleTo(src.list, src.index, "left", 1)
            handled = true
        elseif d.type == "header" and d.side == "right" then
            -- 拖到右侧分组标题 = 追加到右侧末尾
            local cfg = GetCharacterConfig()
            MoveModuleTo(src.list, src.index, "right", table.getn(cfg.OrderRight) + 1)
            handled = true
        end
    end
    CancelDrag()
    if handled then
        CommitOrder()
    elseif optionsFrame and optionsFrame.RefreshList then
        optionsFrame:RefreshList()
    end
end

local function CreateOptionsFrame()
    if optionsFrame then return optionsFrame end

    local W, H = 420, 680
    optionsFrame = CreateFrame("Frame", "DimInfoOptions", UIParent)
    optionsFrame:SetWidth(W)
    optionsFrame:SetHeight(H)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    optionsFrame:SetBackdropColor(0.05, 0.05, 0.09, 0.97)
    AddBorder(optionsFrame, 0.45, 0.45, 0.55, 0.9)
    optionsFrame:EnableMouse(true)
    optionsFrame:SetMovable(true)
    optionsFrame:Hide()

    -- 标题栏（只有标题栏可拖动窗口）
    local titleBar = CreateFrame("Frame", nil, optionsFrame)
    titleBar:SetHeight(30)
    -- 右侧留出关闭按钮的位置，避免标题栏拦截按钮点击
    titleBar:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 38, -10)
    titleBar:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -38, -10)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() optionsFrame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() optionsFrame:StopMovingOrSizing() end)

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleBar)
    titleBg:SetTexture(0.14, 0.14, 0.22)
    titleBg:SetAlpha(0.9)
    AddBorder(titleBar, 1, 0.82, 0, 0.35)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleBar, "CENTER", 10, 0)
    title:SetText("|cffd8b040diminfo 设置|r")

    -- ESC 也可关闭
    tinsert(UISpecialFrames, "DimInfoOptions")

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -8)
    closeBtn:SetScript("OnClick", function() optionsFrame:Hide() end)
    closeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 1)

    -- 操作提示
    local hint = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", titleBar, "BOTTOM", 0, -4)
    hint:SetText("拖动模块即可排序（可跨左右侧），勾选框控制显示/隐藏")
    hint:SetTextColor(0.55, 0.55, 0.62)

    -- 滑动条工厂
    local function MakeSlider(name, label, lowText, highText, minV, maxV, defaultV, anchor, yOff)
        local s = CreateFrame("Slider", name, optionsFrame, "OptionsSliderTemplate")
        s:SetPoint("TOP", anchor, "BOTTOM", 0, yOff)
        s:SetWidth(200)
        s:SetHeight(18)
        s:SetMinMaxValues(minV, maxV)
        s:SetValueStep(1)
        s:SetValue(defaultV)
        getglobal(name .. "Text"):SetText(label)
        getglobal(name .. "Low"):SetText(lowText)
        getglobal(name .. "High"):SetText(highText)
        return s
    end

    -- 滑动条：X偏移
    local slider = MakeSlider("DimInfoXSlider", "水平偏移", "左", "右", -400, 400, GetCharacterConfig().x or 0, hint, -18)
    slider:SetScript("OnValueChanged", function()
        frame.UpdatePosition(this:GetValue())
    end)

    local resetBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    resetBtn:SetWidth(70)
    resetBtn:SetHeight(20)
    resetBtn:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    resetBtn:SetText("位置复位")
    resetBtn:SetScript("OnClick", function()
        slider:SetValue(0)
    end)

    -- 滑动条：模块间距
    local spacingSlider = MakeSlider("DimInfoSpacingSlider", "模块间距", "窄", "宽", 1, 50, GetCharacterConfig().spacing or 20, slider, -22)
    spacingSlider:SetScript("OnValueChanged", function()
        frame.UpdateSpacing(this:GetValue())
    end)

    local resetSpacingBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    resetSpacingBtn:SetWidth(70)
    resetSpacingBtn:SetHeight(20)
    resetSpacingBtn:SetPoint("LEFT", spacingSlider, "RIGHT", 12, 0)
    resetSpacingBtn:SetText("间距复位")
    resetSpacingBtn:SetScript("OnClick", function()
        spacingSlider:SetValue(20)
    end)

    -- 滑动条：字体大小
    local fontSizeSlider = MakeSlider("DimInfoFontSizeSlider", "字体大小", "小", "大", 10, 20, GetCharacterConfig().FontSize or 14, spacingSlider, -22)
    fontSizeSlider:SetScript("OnValueChanged", function()
        frame.UpdateFontSize(this:GetValue())
    end)

    local resetFontSizeBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    resetFontSizeBtn:SetWidth(70)
    resetFontSizeBtn:SetHeight(20)
    resetFontSizeBtn:SetPoint("LEFT", fontSizeSlider, "RIGHT", 12, 0)
    resetFontSizeBtn:SetText("字体复位")
    resetFontSizeBtn:SetScript("OnClick", function()
        fontSizeSlider:SetValue(14)
    end)

    -- 时间显示秒复选框
    local showSecondsCheckbox = CreateFrame("CheckButton", "DimInfoShowSecondsCheckbox", optionsFrame, "UICheckButtonTemplate")
    showSecondsCheckbox:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 85, -193)
    showSecondsCheckbox:SetWidth(20)
    showSecondsCheckbox:SetHeight(20)
    getglobal(showSecondsCheckbox:GetName() .. "Text"):SetText("时间模块显示秒")
    showSecondsCheckbox:SetChecked(GetCharacterConfig().ShowSeconds)
    showSecondsCheckbox:SetScript("OnClick", function()
        local config = GetCharacterConfig()
        config.ShowSeconds = this:GetChecked()
        SaveCharacterConfig()
        if DimInfo_Time_UpdateDisplay then
            DimInfo_Time_UpdateDisplay()
        end
    end)

    -- 渐隐模式复选框
    local fadeCheckbox = CreateFrame("CheckButton", "DimInfoFadeCheckbox", optionsFrame, "UICheckButtonTemplate")
    fadeCheckbox:SetPoint("TOPLEFT", showSecondsCheckbox, "BOTTOMLEFT", 0, -8)
    fadeCheckbox:SetWidth(20)
    fadeCheckbox:SetHeight(20)
    getglobal(fadeCheckbox:GetName() .. "Text"):SetText("渐隐模式（鼠标移开时淡出）")
    fadeCheckbox:SetChecked(GetCharacterConfig().FadeMode)
    fadeCheckbox:SetScript("OnClick", function()
        frame.SetFadeMode(this:GetChecked())
        SaveCharacterConfig()
    end)

    -- 渐隐透明度滑块
    local fadeSlider = MakeSlider("DimInfoFadeSlider", "渐隐透明度", "暗", "亮", 0, 1, GetCharacterConfig().FadeAlpha or 0.15, fadeCheckbox, -8)
    fadeSlider:SetValueStep(0.05)
    fadeSlider:ClearAllPoints()
    fadeSlider:SetPoint("TOPLEFT", fadeCheckbox, "BOTTOMLEFT", 0, -8)
    fadeSlider:SetScript("OnValueChanged", function()
        frame.SetFadeAlpha(this:GetValue())
    end)

    -- 组件复位按钮
    local resetAllBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    resetAllBtn:SetWidth(80)
    resetAllBtn:SetHeight(22)
    resetAllBtn:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -85, -190)
    resetAllBtn:SetText("组件复位")
    resetAllBtn:SetScript("OnClick", function()
        frame.ResetAllModules()
    end)

    -- 列表容器
    optionsContent = CreateFrame("Frame", "DimInfoOptionsContent", optionsFrame)
    optionsContent:SetPoint("TOPLEFT", 25, -280)
    optionsContent:SetPoint("BOTTOMRIGHT", -25, 20)

    local function RefreshList()
        local config = GetCharacterConfig()

        slider:SetValue(config.x or 0)
        spacingSlider:SetValue(config.spacing or 20)
        fontSizeSlider:SetValue(config.FontSize or 14)
        showSecondsCheckbox:SetChecked(config.ShowSeconds)
        fadeCheckbox:SetChecked(config.FadeMode)
        fadeSlider:SetValue(config.FadeAlpha or 0.15)

        if not optionsContent.rows then optionsContent.rows = {} end

        local leftList = config.OrderLeft or {}
        local rightList = config.OrderRight or {}

        -- 构建显示列表：左侧 -> 中心锚点 -> 右侧
        local displayList = {}
        table.insert(displayList, { type = "header", text = "左侧模块", side = "left" })
        for i, name in ipairs(leftList) do
            table.insert(displayList, { type = "item", name = name, list = "left", index = i, max = table.getn(leftList) })
        end
        table.insert(displayList, { type = "header", text = "中心（固定）", side = "center" })
        table.insert(displayList, { type = "item", name = "diminfo_pos", list = "center", index = 0, max = 0 })
        table.insert(displayList, { type = "header", text = "右侧模块", side = "right" })
        for i, name in ipairs(rightList) do
            table.insert(displayList, { type = "item", name = name, list = "right", index = i, max = table.getn(rightList) })
        end

        -- 渲染
        local yOffset = 0
        for i, dataInfo in ipairs(displayList) do
            local data = dataInfo

            if not optionsContent.rows[i] then
                local row = CreateFrame("Frame", nil, optionsContent)
                row:SetWidth(370)
                row:SetHeight(25)
                row:EnableMouse(true)

                -- 条目底色
                local bg = row:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(row)
                bg:SetTexture(1, 1, 1)
                bg:SetAlpha(0.03)
                row.bg = bg

                -- 鼠标悬停高亮
                local hover = row:CreateTexture(nil, "HIGHLIGHT")
                hover:SetAllPoints(row)
                hover:SetTexture(1, 1, 1)
                hover:SetAlpha(0.08)

                -- 拖拽落点高亮
                local drop = row:CreateTexture(nil, "ARTWORK")
                drop:SetAllPoints(row)
                drop:SetTexture(1, 0.82, 0)
                drop:SetAlpha(0.16)
                drop:Hide()
                row.drop = drop

                -- 显示/隐藏勾选框
                local cb = CreateFrame("CheckButton", "DimInfoRowChk" .. i, row, "UICheckButtonTemplate")
                cb:SetPoint("LEFT", 2, 0)
                cb:SetWidth(20)
                cb:SetHeight(20)
                getglobal(cb:GetName() .. "Text"):SetText("")
                row.cb = cb

                -- 模块名
                local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
                row.label = label

                -- 序号
                local num = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                num:SetPoint("RIGHT", -30, 0)
                row.num = num

                -- 拖拽把手
                local grip = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                grip:SetPoint("RIGHT", -10, 0)
                grip:SetText(":::")
                grip:SetTextColor(1, 1, 1)
                row.grip = grip

                -- 分组标题
                local hfs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                hfs:SetPoint("LEFT", 6, 0)
                row.headerFS = hfs

                -- 标题下分隔线
                local div = row:CreateTexture(nil, "BORDER")
                div:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
                div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
                div:SetHeight(1)
                div:SetTexture(1, 0.82, 0)
                div:SetAlpha(0.3)
                div:Hide()
                row.div = div

                -- 按下：开始拖拽
                row:SetScript("OnMouseDown", function()
                    if arg1 ~= "LeftButton" then return end
                    local d = this.data
                    if not d or d.type ~= "item" or d.list == "center" then return end
                    dragState = { list = d.list, index = d.index, name = d.name }
                    this:SetAlpha(0.45)  -- 源条目半透明
                    local ghost = CreateDragGhost()
                    ghost.text:SetText(niceNames[d.name] or d.name)
                    ghost:Show()
                end)

                -- 松手：统一走坐标扫描落点解析（见 ResolveDrop 注释）
                row:SetScript("OnMouseUp", ResolveDrop)

                row:SetScript("OnEnter", function()
                    local d = this.data
                    if d and d.type == "item" and d.list == "center" then
                        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                        GameTooltip:SetText("中心锚点")
                        GameTooltip:AddLine("所有模块以它为中心向两侧排列", 1, 1, 1)
                        GameTooltip:Show()
                    end
                end)

                row:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                optionsContent.rows[i] = row
            end

            local row = optionsContent.rows[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, yOffset)
            row:Show()
            row:SetAlpha(1)
            row.data = data

            if data.type == "header" then
                row.cb:Hide()
                row.label:Hide()
                row.num:Hide()
                row.grip:Hide()
                row.bg:Hide()
                row.drop:Hide()
                row.headerFS:Show()
                row.headerFS:SetText(data.text)
                row.headerFS:SetTextColor(1, 0.82, 0)
                row.div:Show()
            else
                row.headerFS:Hide()
                row.div:Hide()
                row.label:Show()
                row.bg:Show()
                row.cb:Show()
                row.cb:SetChecked(not config.Hidden[data.name])
                row.cb:SetScript("OnClick", function()
                    config.Hidden[data.name] = not this:GetChecked()
                    SaveCharacterConfig()
                    frame.ApplyVisibility()
                end)

                if data.list == "center" then
                    row.label:SetTextColor(0.75, 0.75, 0.78)
                    row.label:SetText((niceNames[data.name] or data.name) .. "（锚点）")
                    row.num:Hide()
                    row.grip:Hide()
                    row.drop:Hide()
                else
                    row.label:SetTextColor(1, 1, 1)
                    row.label:SetText(niceNames[data.name] or data.name)
                    row.num:Show()
                    row.num:SetText(tostring(data.index))
                    row.num:SetTextColor(1, 1, 1)
                    row.grip:Show()
                end
            end

            yOffset = yOffset - 27
        end

        -- 隐藏多余行
        for k = table.getn(displayList) + 1, table.getn(optionsContent.rows) do
            optionsContent.rows[k]:Hide()
        end
    end

    -- 拖拽跟随：幽灵框跟随鼠标 + 目标行高亮 + 越界取消
    optionsFrame:SetScript("OnUpdate", function()
        if not dragState then return end
        if not IsCursorOver(optionsFrame) then
            CancelDrag()
            return
        end
        local ghost = DimInfoDragGhost
        if ghost and ghost:IsShown() then
            local scale = UIParent:GetScale()
            local cx, cy = GetCursorPosition()
            ghost:ClearAllPoints()
            ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / scale, cy / scale)
        end
        if optionsContent and optionsContent.rows then
            for i = 1, table.getn(optionsContent.rows) do
                local r = optionsContent.rows[i]
                if r and r:IsShown() and r.drop then
                    local valid = IsCursorOver(r) and r.data
                        and not (r.data.type == "item" and r.data.list == "center")
                    if valid then
                        r.drop:Show()
                    else
                        r.drop:Hide()
                    end
                end
            end
        end
    end)

    -- 松手：行与面板空白统一走落点解析（落在行外自然取消）
    optionsFrame:SetScript("OnMouseUp", ResolveDrop)

    optionsFrame:SetScript("OnShow", RefreshList)
    optionsFrame:SetScript("OnHide", CancelDrag)
    RefreshList() -- Initial draw


    optionsFrame.RefreshList = RefreshList

    return optionsFrame
end

-- Slash Command Handler
SLASH_DIMINFO1 = "/dim"
SLASH_DIMINFO2 = "/diminfo"
SlashCmdList["DIMINFO"] = function(msg)
    local opts = CreateOptionsFrame()
    if opts:IsVisible() then
        opts:Hide()
    else
        opts:Show()
    end
end

-- 右键点击打开设置
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then
        local opts = CreateOptionsFrame()
        if opts:IsVisible() then
            opts:Hide()
        else
            opts:Show()
        end
    end
end)

-- 延迟初始化以等待 SavedVariables
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("VARIABLES_LOADED")
eventHandler:SetScript("OnEvent", function()
    -- 确保全局配置表存在
    if not DimInfo_Config then
        DimInfo_Config = {}
    end

    -- 获取当前角色配置（会自动创建默认配置）
    local config = GetCharacterConfig()

    -- 应用保存的位置
    frame.UpdatePosition(config.x or 0)

    -- 应用模块间距
    frame.UpdateSpacing(config.spacing or 20)

    -- 应用字体大小
    frame.UpdateFontSize(config.FontSize or 14)

    -- 应用渐隐透明度（渐隐开关由 OnUpdate 按配置生效）
    frame.SetFadeAlpha(config.FadeAlpha or 0.15)

    -- 应用模块可见性
    frame.ApplyVisibility()

    -- 再次更新字体大小，确保所有模块（包括金币模块）都应用了正确的字体大小
    UpdateAllModulesFontSize()

    -- 刷新时间显示
    if DimInfo_Time_UpdateDisplay then
        DimInfo_Time_UpdateDisplay()
    end
end)

function ConjureManaStone()
	local x,j,b,s,l,f={"红宝石","黄水晶","翡翠","玛瑙"},1;
	while j<5 do f=nil; for b=0,4 do
		for s=1,36 do l=GetContainerItemLink(b,s);
			if l and strfind(l,"法力"..x[j]) then f=j;break; 
			end; 
		end;
		if f then break;end; 
		end; 
	if f then j=j+1;else CastSpellByName("制造魔法"..x[j]);break;end;
	end;
end;

function CheckTrinket()
    
    local used = false       -- 是否使用了饰品
    
    local start13, duration13, enable13 = GetInventoryItemCooldown("player", 13)
	local start14, duration14, enable14 = GetInventoryItemCooldown("player", 14)
		
		if start13 == 0 and enable13 == 1 then -- 如果饰品CD为0
			
			UseInventoryItem(13) -- 使用该饰品
			
		elseif start14 == 0 and enable14 == 1 then -- 如果饰品CD为0
			
			UseInventoryItem(14) -- 使用该饰品
			
		else used = true
			
		end
                
    return used
end