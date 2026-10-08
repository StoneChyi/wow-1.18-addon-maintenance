--[[
    Author: SuperCleveRoidMacros
    License: MIT License

    DragonflightReloaded mouseover support.

    NOTE: DragonflightReloaded (DFRL namespace) modifies the default Blizzard
    unit frames (PlayerFrame, TargetFrame, etc.) rather than creating its own.
    The Blizzard.lua extension already handles these frames with priority 3.

    DFRL hides the original HealthBar/ManaBar StatusBars and replaces them with
    custom Frame-based bars (CreateStatusBar) that don't have EnableMouse. The
    default PartyMemberFrame HitRectInsets (left=7 right=85) only cover the
    portrait area, so hovering over the replacement bars never fires OnEnter.
    We widen the hit rects so the Blizzard.lua hooks on the parent frames work
    across the full visible area.
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("DragonflightReloaded")

function Extension.OnLoad()
    -- 修复：未装 DragonflightReloaded 时也会无条件改写默认框架命中矩形，
    -- 影响默认 UI 点击/悬停区域；加 IsAddOnLoaded 守卫 by 武藤纯子酱 2026.9.11
    -- 修复：DFRL 的插件目录名带前导连字符（-DragonflightReloaded），原判断漏了连字符导致守卫恒真、
    -- 命中矩形永不改写（@mouseover 在队伍血条区失效）；两种写法都判 by 武藤纯子酱 2026.9.12
    if not (IsAddOnLoaded and (IsAddOnLoaded("-DragonflightReloaded") or IsAddOnLoaded("DragonflightReloaded"))) then return end
    -- Widen hit rects on frames whose original StatusBars are hidden by DFRL.
    -- Without this, the Blizzard.lua mouseover hooks on the parent frames only
    -- fire in the portrait area, causing @mouseover to be skipped over bars.
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame and frame.SetHitRectInsets then
            frame:SetHitRectInsets(0, 0, 0, 0)
        end
        local petFrame = _G["PartyMemberFrame" .. i .. "PetFrame"]
        if petFrame and petFrame.SetHitRectInsets then
            petFrame:SetHitRectInsets(0, 0, 0, 0)
        end
    end
    local pet = _G["PetFrame"]
    if pet and pet.SetHitRectInsets then
        pet:SetHitRectInsets(0, 0, 0, 0)
    end
end

_G["CleveRoids"] = CleveRoids
