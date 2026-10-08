-- ============================================
-- Sunelegy 适配 TurtleWOW 1.18.0
-- S_WorldMap 兼容常规界面 + pfUI界面
-- ============================================

local isPfUI = (pfUI and pfUI.env)

if isPfUI and AceLibrary then
    S_WorldMap = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceModuleCore-2.0", "AceHook-2.1")
    local BZ = AceLibrary("Babble-Zone-2.2")
    S_WorldMap:RegisterDB("S_WorldMapDB")

    function S_WorldMap:OnInitialize()
        S_WorldMap_CommonInit()
    end

    local currentInstance
    function S_WorldMap:SetCurrentInstance(zone)
        if currentInstance ~= zone then
            currentInstance = zone
            self:TriggerEvent("Cartographer_SetCurrentInstance", zone)
            self:TriggerEvent("Cartographer_ChangeZone", self:GetCurrentLocalizedZoneName())
        end
    end

    function S_WorldMap:GetCurrentInstance()
        return currentInstance
    end

    local instanceWorldMapButton
    function S_WorldMap:RegisterInstanceWorldMapButton(frame)
        instanceWorldMapButton = frame
        self:TriggerEvent("Cartographer_RegisterInstanceWorldMapButton", frame)
    end

    function S_WorldMap:GetInstanceWorldMapButton()
        return instanceWorldMapButton
    end

    function S_WorldMap:GetCurrentLocalizedZoneName()
        return GetRealZoneText()
    end

else
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function()
        S_WorldMap_CommonInit()
    end)
end

function S_WorldMap_CommonInit()
    UIPanelWindows["WorldMapFrame"] = { area = "center" }
    
    -- 实现真正的缩小功能
    WorldMapFrame.isMinimized = false
    WorldMapFrame.savedScale = nil
    WorldMapFrame.savedAlpha = nil
    
    WorldMapFrame_Minimize = function()
        if not WorldMapFrame.isMinimized then
            -- 缩小：保存当前状态并缩小
            WorldMapFrame.savedScale = WorldMapFrame:GetScale()
            WorldMapFrame.savedAlpha = WorldMapFrame:GetAlpha()
            WorldMapFrame:SetScale(0.4)
            WorldMapFrame:SetAlpha(0.6)
            WorldMapFrame.isMinimized = true
            
            -- 移动到右上角
            WorldMapFrame:ClearAllPoints()
            WorldMapFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -50)
        else
            -- 恢复：还原到原始大小
            WorldMapFrame:SetScale(WorldMapFrame.savedScale or 0.9)
            WorldMapFrame:SetAlpha(WorldMapFrame.savedAlpha or 0.8)
            WorldMapFrame.isMinimized = false
            
            -- 恢复到中心位置
            WorldMapFrame:ClearAllPoints()
            WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
    
    -- 修复最小化按钮
    if WorldMapFrameMinimizeButton then
        WorldMapFrameMinimizeButton:SetScript("OnClick", function()
            WorldMapFrame_Minimize()
        end)
    end

    WorldMapFrame:SetScript("OnShow", function()
        UpdateMicroButtons()
        PlaySound("igQuestLogOpen")
        CloseDropDownMenus()
        SetMapToCurrentZone()
        WorldMapFrame_PingPlayerPosition()
        this:EnableKeyboard(false)
        table.insert(UISpecialFrames, "WorldMapFrame")
        this:EnableMouseWheel(1)
        BlackoutWorld:Hide()
        WorldMapZoomOutButton:Hide()
        -- WorldMapMagnifyingGlassButton:Hide()  -- 保留放大镜按钮，用于显示/隐藏未探索区域
        this:SetClampedToScreen(true)

        if not this.playerModel then
            for _,v in ipairs({WorldMapFrame:GetChildren()}) do
                if v:GetFrameType() == "Model" and not v:GetName() then
                    this.playerModel = v
                    break
                end
            end 
        end
        this.playerModel:SetAlpha(1)
        this.playerModel:SetModelScale(1.3)
        this.playerModel:SetFrameLevel(3)
    end)

    WorldMapFrame:SetScript("OnHide", function()
        SetMapToCurrentZone()
    end)

    WorldMapFrame:SetScript("OnMouseWheel", function()
        if IsShiftKeyDown() then
            alpha = clamp(this:GetAlpha() + arg1/10, 0.1, 1.0)
            this:SetAlpha(alpha)
            this.playerModel:SetAlpha(1)
        elseif IsControlKeyDown() then
            scale = clamp(this:GetScale() + arg1/10, 0.1, 1.0)
            this:SetScale(scale)
        end
    end)

    WorldMapFrame:SetMovable(true)
    WorldMapFrame:EnableMouse(true)

    WorldMapFrame:SetAlpha(0.8)
    WorldMapFrame:SetScale(0.9)

    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    WorldMapFrame:SetWidth(WorldMapButton:GetWidth()+22)
    WorldMapFrame:SetHeight(WorldMapButton:GetHeight()+100)
    UIPanelWindows["WorldMapFrame"] = nil

    WorldMapFrame:RegisterForDrag("LeftButton")
    WorldMapFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)

    WorldMapFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local x,y = this:GetCenter()
        local z = UIParent:GetEffectiveScale() / 2 / this:GetScale()
        x = x - GetScreenWidth() * z
        y = y - GetScreenHeight() * z
        this:ClearAllPoints()
        this:SetPoint("CENTER", "UIParent", "CENTER", x, y)
    end)

    if not WorldMapButton.coords then
        local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
        WorldMapButton.coords = CreateFrame("Frame", "WorldMapButtonCoords", WorldMapFrame)
        WorldMapButton.coords.text = WorldMapButton.coords:CreateFontString(nil, "ARTWORK")
        WorldMapButton.coords.text:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", 0, 9)
        WorldMapButton.coords.text:SetFontObject(GameFontNormal)
        WorldMapButton.coords:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local px, py = GetPlayerMapPosition("player")
            local scale = WorldMapFrame:GetEffectiveScale()
            x = x / scale
            y = y / scale
            local width  = WorldMapButton:GetWidth()
            local height = WorldMapButton:GetHeight()
            local centerX, centerY = WorldMapFrame:GetCenter()
            local adjustedX = (x - (centerX - (width/2))) / width
            local adjustedY = (centerY + (height/2) - y) / height
            x = (adjustedX + 0.0022) * 100
            y = (adjustedY + -0.0262) * 100

            if MouseIsOver(WorldMapButton) then
                WorldMapButton.coords.text:SetText("鼠标 "..format("%d,%d",x,y).."      "..HexColors(color.r or 1, color.g or 1, color.b or 0).."玩家|r "..Round(px * 100)..","..Round(py * 100))
            else
                WorldMapButton.coords.text:SetText("")
            end
        end)
    end
end

local function CreatepfQuestButton(name, anchor, parent, relativeTo, x, y, text)
    local Button = CreateFrame("Button", name, WorldMapFrame, "UIPanelButtonTemplate")
    Button:SetWidth(35)
    Button:SetHeight(20)
    Button:SetFont(STANDARD_TEXT_FONT, 12)
    Button:SetPoint(anchor, parent, relativeTo, x, y)    
    Button:SetText(text)
end

local function pfQuestButtonClick(frame, cmd)
    frame:SetScript("OnMouseDown", function()
        SlashCmdList["PFDB"](cmd)
    end)
end

local function pfQuestButtonOnEnter(frame, text)
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(text)
        GameTooltip:Show()    
    end)
end

local function pfQuestButtonOnLeave(frame)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function pfQuestButton(frame, cmd, text)
    pfQuestButtonClick(frame, cmd)
    pfQuestButtonOnEnter(frame, text)
    pfQuestButtonOnLeave(frame)
end

if pfQuest then
    local xOffset, yOffset
    if isPfUI then
        xOffset = 5
        yOffset = -15
    else
        xOffset = 10
        yOffset = -40
    end

    CreatepfQuestButton("pfQuestMines", "TOPLEFT", WorldMapFrame, "TOPLEFT", xOffset, yOffset, "矿物")
    CreatepfQuestButton("pfQuestherbs", "LEFT", "pfQuestMines", "RIGHT", 0, 0, "草药")
    CreatepfQuestButton("pfQuestchests", "LEFT", "pfQuestherbs", "RIGHT", 0, 0, "宝箱")
    CreatepfQuestButton("pfQuestrares", "LEFT", "pfQuestchests", "RIGHT", 0, 0, "稀有")
    CreatepfQuestButton("pfQuesttaxi", "LEFT", "pfQuestrares", "RIGHT", 0, 0, "鸟点")
    CreatepfQuestButton("pfQuestfish", "LEFT", "pfQuesttaxi", "RIGHT", 0, 0, "鱼点")
    CreatepfQuestButton("pfQuestinnkeeper", "LEFT", "pfQuestfish", "RIGHT", 0, 0, "旅店")
    CreatepfQuestButton("pfQuestSerach", "LEFT", "pfQuestinnkeeper", "RIGHT", 10, 0, "搜索")
    CreatepfQuestButton("pfQuestclean", "LEFT", "pfQuestSerach", "RIGHT", 0, 0, "清除")

    if isPfUI then
        pfUI.api.SkinButton("pfQuestMines")
        pfUI.api.SkinButton("pfQuestherbs")
        pfUI.api.SkinButton("pfQuestchests")
        pfUI.api.SkinButton("pfQuestrares")
        pfUI.api.SkinButton("pfQuesttaxi")
        pfUI.api.SkinButton("pfQuestfish")
        pfUI.api.SkinButton("pfQuestinnkeeper")
        pfUI.api.SkinButton("pfQuestSerach")
        pfUI.api.SkinButton("pfQuestclean")
    end

    pfQuestButton(pfQuestMines, "track mines auto", "显示当前采矿等级范围内的矿石")
    pfQuestButton(pfQuestherbs, "track herbs auto", "显示当前采药等级范围内的草药")
    pfQuestButton(pfQuestchests, "track chests", "显示所有宝箱")
    pfQuestButton(pfQuestrares, "track rares", "显示所有稀有精英")
    pfQuestButton(pfQuesttaxi, "track taxi", "显示本阵营所有鸟点")
    pfQuestButton(pfQuestfish, "track fish", "显示所有鱼点")
    pfQuestButton(pfQuestinnkeeper, "track innkeeper", "显示本阵营所有旅店")
    pfQuestButton(pfQuestSerach, "show", "显示pfQuest浏览器")
    pfQuestButton(pfQuestclean, "track clean", "清除地图标记")
end