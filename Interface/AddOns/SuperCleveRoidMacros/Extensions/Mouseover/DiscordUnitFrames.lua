--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("DiscordUnitFrames")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnterFrame()
    CleveRoids.SetMouseoverFrom("duf", this.unit)
end

function Extension.OnLeaveFrame()
    CleveRoids.ClearMouseoverFrom("duf")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnEnterElement()
    CleveRoids.SetMouseoverFrom("duf", this:GetParent().unit)
end

function Extension.OnLeaveElement()
    CleveRoids.ClearMouseoverFrom("duf")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnLoad()
    -- 修复：DiscordUnitFrames 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("DiscordUnitFrames")) then return end

    CleveRoids.ClearHooks("DiscordUnitFrames") -- 指定解除DiscordUnitFrames的hook，而不是全局 by 武藤纯子酱 2026.7.2
    Extension.Hook("DUF_UnitFrame_OnEnter", "OnEnterFrame")
    Extension.Hook("DUF_UnitFrame_OnLeave", "OnLeaveFrame")

    Extension.Hook("DUF_Element_OnEnter", "OnEnterElement")
    Extension.Hook("DUF_Element_OnLeave", "OnLeaveElement")
end

_G["CleveRoids"] = CleveRoids
