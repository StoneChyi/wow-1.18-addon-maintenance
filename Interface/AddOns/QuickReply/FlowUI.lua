FlowUI = {
    name = "FlowUI",
}

function FlowUI:CreateDraggableFrame(name, title, width, height, store)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint("CENTER", UIParent, "CENTER", store.x or 0, store.y or 0)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- 标题
    frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -15)
    frame.title:SetText(title)
    
    -- 关闭按钮
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.close:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- 内容区域
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    frame.content:SetWidth(width - 20)
    frame.content:SetHeight(height - 50)

    -- 启用鼠标交互
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    
    -- 拖动逻辑
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        _, _, _, xOfs, yOfs = frame:GetPoint()
        store.x = xOfs  
        store.y = yOfs
    end)
    
    frame:Hide()
    return frame
end

function FlowUI:CreateDiv(name, parent, width, height, padding)
    local width = width or parent:GetWidth()
    local height = height or parent:GetHeight()
    local padding = padding or 0

    local div = CreateFrame("Frame", name, parent)    
    div:SetWidth(width)
    div:SetHeight(height)

    if parent.lastChild then
        div:SetPoint("TOPLEFT", parent.lastChild, "BOTTOMLEFT", 0, 0)
    else
        div:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end

    parent.lastChild = div
    if padding == 0 then
        return div
    end

    local content = FlowUI:CreateDiv(nil, div, width - padding * 2, height)
    content:SetPoint("TOPLEFT", div, "TOPLEFT", padding, 0)
    return content
end

function FlowUI:SplitDiv(div, n, gap, padding)
    if div.parts then
        return nil
    end

    if gap == nil then
        gap = 0
    end

    if padding == nil then
        padding = 0
    end

    local width = (div:GetWidth() - (gap * (n + 1))) / n 
    local height = div:GetHeight() - gap * 2

    div.parts = {}
    for i = 0, n - 1 do
        local part = FlowUI:CreateDiv(nil, div, width, height)
        part:SetPoint("TOPLEFT", div, "TOPLEFT", i * width + (i + 1) * gap , -gap)
        if padding == 0 then
            div.parts[i] = part
        else
            local paddingFrame = FlowUI:CreateDiv(nil, part, width - padding * 2, height - padding * 2)
            paddingFrame:SetPoint("TOPLEFT", part, "TOPLEFT", padding, -padding)
            div.parts[i] = paddingFrame
        end
    end
end

function FlowUI:CreateLabel(name, parent, text, fontSize, height)
    local label = parent:CreateFontString(name, "ARTWORK", "GameFontNormal")
    label:SetHeight(height or 18)
    label:SetText(text)
    label:SetFont(label:GetFont(), fontSize or 12)
    if parent.lastChild then
        label:SetPoint("TOPLEFT", parent.lastChild, "BOTTOMLEFT", 0, 0)
    else
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end
    parent.lastChild = label
    return label
end