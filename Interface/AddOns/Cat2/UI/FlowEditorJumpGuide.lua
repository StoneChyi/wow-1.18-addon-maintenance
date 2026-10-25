-- 流程跳转辅助线：仅供编辑器预览，不执行卡片或修改跳转参数。
-- 使用旧版客户端支持的矩形纹理，显式裁剪到流程可视区。
local ui = Cat2.UI
local editor = ui.FlowEditor
editor.jumpGuides = editor.jumpGuides or {}

local function HideGuide(guide)
    if guide then
        guide:Hide()
        guide.sourceIndex = nil
    end
end

function editor.HideJumpGuide()
    for _, guide in pairs(editor.jumpGuides) do HideGuide(guide) end
end

local function CreateGuide(scroll)
    -- 挂在外层面板，允许竖线进入滚动框左侧留白；纵向仍由下方逻辑显式裁剪。
    local guide = CreateFrame("Frame", nil, editor.flowPanel or scroll)
    guide:SetAllPoints(scroll)
    guide:SetFrameLevel(scroll:GetFrameLevel() + 20)
    guide:EnableMouse(false)
    local function Line()
        local texture = guide:CreateTexture(nil, "OVERLAY")
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(0.76, 0.49, 0.25, 0.9)
        return texture
    end
    guide.stem = Line()
    guide.sourceLine = Line()
    guide.targetLine = Line()
    guide:Hide()
    return guide
end

local function IsJumpBlock(block)
    return block and block.step and block.step.behavior == "logic"
        and not block.step.isMissing
        and Cat2.GetCardOptionDefinition(block.step, "targetIndex") ~= nil
end

-- 悬停优先，其次使用选中的跳转卡；其余路线仍显示，但降低透明度。
local function FindSource()
    if ui.IsCursorInside(editor.flowScroll) then
        local index = 1
        local total = table.getn(editor.leftBlocks)
        while index <= total do
            local block = editor.leftBlocks[index]
            if block:GetTop() and ui.IsCursorInside(block) and IsJumpBlock(block) then
                return index, block
            end
            index = index + 1
        end
    end
    local index = editor.selectedFlowIndex
    local block = index and editor.leftBlocks[index]
    if IsJumpBlock(block) then return index, block end
end

local function PlaceLine(texture, guide, x, y, width, height)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", guide, "TOPLEFT", x, -y)
    texture:SetWidth(math.max(1, width))
    texture:SetHeight(math.max(1, height))
    texture:Show()
end

local function DrawGuide(scroll, sourceIndex, highlighted)
    local source = editor.leftBlocks[sourceIndex]
    local guide = editor.jumpGuides[sourceIndex]
    if not IsJumpBlock(source) then
        HideGuide(guide)
        return
    end
    local targetIndex = source and Cat2.ResolveStepOption(source.step, "targetIndex", nil)
    local target = type(targetIndex) == "number" and editor.leftBlocks[targetIndex]
    if not source or not target or not editor.selectedSteps[targetIndex] then
        HideGuide(guide)
        return
    end
    local top, left, height = scroll:GetTop(), scroll:GetLeft(), scroll:GetHeight()
    if not top or not left or not height or height <= 12
        or not source:GetTop() or not target:GetTop() then
        HideGuide(guide)
        return
    end

    -- 接口放在序号的上/下方，避开序号文字；自跳转画成同一卡片左侧的小回路。
    local downward = targetIndex > sourceIndex
    local sourceY = top - source:GetTop() + source:GetHeight() * (downward and 0.75 or 0.25)
    local targetY = top - target:GetTop() + target:GetHeight() * (downward and 0.25 or 0.75)
    if (sourceY < 0 and targetY < 0) or (sourceY > height and targetY > height) then
        HideGuide(guide)
        return
    end
    if not guide then
        guide = CreateGuide(scroll)
        editor.jumpGuides[sourceIndex] = guide
    end
    local endX = source:GetLeft() - left - 2
    -- 竖线向边框侧移6个单位，居中放在面板边框与序号之间。
    local startX = endX - 27
    local firstY = math.max(6, math.min(height - 6, sourceY))
    local lastY = math.max(6, math.min(height - 6, targetY))
    -- 卡片、滚动位置和参数均未变化时，不重复设置纹理锚点。
    if guide:IsShown() and guide.sourceIndex == sourceIndex and guide.targetIndex == targetIndex
        and guide.sourceY == sourceY and guide.targetY == targetY
        and guide.endX == endX and guide.viewHeight == height
        and guide.highlighted == highlighted then return end
    guide.sourceIndex, guide.targetIndex = sourceIndex, targetIndex
    guide.sourceY, guide.targetY = sourceY, targetY
    guide.endX, guide.viewHeight = endX, height
    guide.highlighted = highlighted
    guide:SetAlpha(highlighted and 1 or 0.28)
    -- 高亮路线盖在淡色路线之上，共用走线位置时仍能清楚识别。
    guide:SetFrameLevel(scroll:GetFrameLevel() + (highlighted and 21 or 20))
    PlaceLine(guide.stem, guide, startX, math.min(firstY, lastY), 2, math.abs(lastY - firstY) + 2)
    guide.sourceLine:Hide()
    guide.targetLine:Hide()
    if sourceY >= 6 and sourceY <= height - 6 then
        PlaceLine(guide.sourceLine, guide, startX, firstY, endX - startX, 2)
    end
    if targetY >= 6 and targetY <= height - 6 then
        PlaceLine(guide.targetLine, guide, startX, lastY, endX - startX, 2)
    end
    guide:Show()
end

function editor.UpdateJumpGuide()
    local scroll = editor.flowScroll
    if not scroll or not scroll:IsVisible()
        or (editor.dragGhost and editor.dragGhost:IsVisible()) then
        editor.HideJumpGuide()
        return
    end
    local focusIndex = FindSource()
    local total = table.getn(editor.selectedSteps)
    local index = 1
    while index <= total do
        DrawGuide(scroll, index, index == focusIndex)
        index = index + 1
    end
    -- 删除卡片或切换到更短的配置时，隐藏控件池里已不使用的连线。
    for sourceIndex, guide in pairs(editor.jumpGuides) do
        if sourceIndex > total then HideGuide(guide) end
    end
end
