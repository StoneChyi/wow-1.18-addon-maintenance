--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

CleveRoids.Hooks = CleveRoids.Hooks or {}

local Extension = CleveRoids.RegisterExtension("PerfectRaid")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter(unit)
    CleveRoids.SetMouseoverFrom("praid", unit)
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("praid")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnLoad()
    -- 修复：PerfectRaid 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("PerfectRaid")) then return end
    -- 修复：仅 IsAddOnLoaded 不够，PerfectRaid 全局可能尚未建立 by 武藤纯子酱 2026.9.11
    if not PerfectRaid then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发，避免重复替换 by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end

    CleveRoids.Hooks.PerfectRaid = { CreateFrame = PerfectRaid.CreateFrame }
    PerfectRaid.CreateFrame = CleveRoids.PerfectRaidCreateFrame
    Extension.__cr_hooked = true
end

function CleveRoids.PerfectRaidCreateFrame(self, num)
    -- We need to allocate up to num frames

    if self.poolsize >= num then return end

--[[
    local mem,thr = gcinfo()
    self:Msg("Memory Usage Before: %s [%s].", mem, thr)
--]]
    local side = self.opt.Align

    local justify,point,relative,offset

    if side == "left" then
        justify = "RIGHT"
        point = "LEFT"
        relative = "RIGHT"
        offset = 5
    elseif side == "right" then
        justify = "LEFT"
        point = "RIGHT"
        relative = "LEFT"
        offset = -5
    end

    for i=(self.poolsize + 1),num do
        local frame = CreateFrame("Button", nil, PerfectRaidFrame)
        frame:EnableMouse(true)
        frame.unit = "raid"..i
        frame.id = i
        frame:SetWidth(225)
        frame:SetHeight(13)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() self["master"]:StartMoving() end)
        frame:SetScript("OnDragStop", function() self["master"]:StopMovingOrSizing() self:SavePosition() end)
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
        frame:SetScript("OnClick", self.OnClick)
        frame:SetScript("OnEnter", function()
            Extension.OnEnter(this.unit)
        end)
        frame:SetScript("OnLeave", function()
            Extension.OnLeave()
        end)
        frame:SetParent(self.master)

        local font = frame:CreateFontString(nil, "ARTWORK")
        font:SetFontObject(GameFontHighlightSmall)
        font:SetText("WW")
        font:SetJustifyH("CENTER")
        font:SetWidth(font:GetStringWidth())
        font:SetHeight(14)
        font:Show()
        font:ClearAllPoints()
        font:SetPoint(point, frame, relative,0, 0)
        -- Add this font string to the frame
        frame.Prefix = font

        font = frame:CreateFontString(nil, "ARTWORK")
        font:SetFontObject(GameFontHighlightSmall)
        font:SetText()
        font:SetJustifyH(justify)
        font:SetWidth(55)
        font:SetHeight(12)
        font:Show()
        font:ClearAllPoints()
        font:SetPoint(point, frame.Prefix, relative, offset, 0)
        -- Add this font string to the frame
        frame.Name = font

        local bar = CreateFrame("StatusBar", nil, frame)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0,100)
        bar:ClearAllPoints()
        bar:SetPoint(point, frame.Name, relative, offset, 0)
        bar:SetWidth(60)
        bar:SetHeight(7)
        bar:Show()
        -- Add this status bar to the frame
        frame.Bar = bar

        font = frame:CreateFontString(nil, "ARTWORK")
        font:SetFontObject(GameFontHighlightSmall)
        font:SetText("")
        font:SetJustifyH(justify)
        font:SetWidth(font:GetStringWidth())
        font:SetHeight(12)
        font:Show()
        font:ClearAllPoints()
        font:SetPoint(point, frame.Bar, relative, offset, 0)
        -- Add this font string to the frame
        frame.Status = font

        -- Lets set the frame in the indexed array
        self.frames[i] = frame
        self.frames["raid"..i] = frame
        self.poolsize = i
    end

    -- 修复：原 `mem2,thr2 = gcinfo()` 泄漏两个全局，且仅被下方注释块引用；删除 by 武藤纯子酱 2026.9.11
--[[
    self:Msg("Memory Usage After: %s [%s].", mem2, thr2)
    self:Msg("Frame creation change: %s [%s].", mem2 - mem, thr2 - thr)
--]]
end

_G["CleveRoids"] = CleveRoids
