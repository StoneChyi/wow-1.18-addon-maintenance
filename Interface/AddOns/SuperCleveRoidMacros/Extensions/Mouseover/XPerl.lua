--[[
    Author: SuperCleveRoidMacros
    License: MIT License

    X-Perl UnitFrames mouseover support.
    Hooks into X-Perl's tooltip functions to track mouseover unit.

    X-Perl uses XPerl_PlayerTip(unitid) for OnEnter and XPerl_PlayerTipHide() for OnLeave.
    These are global functions defined in XPerl/XPerl.lua.
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("XPerl")
-- Use PLAYER_ENTERING_WORLD instead of ADDON_LOADED for reliable timing
Extension.RegisterEvent("PLAYER_ENTERING_WORLD", "DelayedInit")

local hooked = false

function Extension.OnEnter(unitid)
    if unitid and unitid ~= "" then
        CleveRoids.SetMouseoverFrom("xperl", unitid)
    end
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("xperl")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.DelayedInit()
    if hooked then return end

    -- Check if X-Perl is loaded by looking for its global functions
    -- 修复：仅当两个 hook 目标都存在时才置 hooked，避免其中一个缺失后永不重试
    -- by 武藤纯子酱 2026.9.11
    if not (XPerl_PlayerTip and XPerl_PlayerTipHide) then
        return
    end

    -- Hook the tooltip show function
    Extension.Hook("XPerl_PlayerTip", "OnEnter")

    -- Hook the tooltip hide function
    Extension.Hook("XPerl_PlayerTipHide", "OnLeave")

    hooked = true
end

function Extension.OnLoad()
    -- Nothing needed here, we use DelayedInit
end

_G["CleveRoids"] = CleveRoids
