--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("CT_UnitFrames")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.SetHook(widget)
    local hookedOnEnter = widget:GetScript("OnEnter")
    local hookedOnLeave = widget:GetScript("OnLeave")

    widget:SetScript("OnEnter", function()
        -- 修复：部分控件（如拖动框）可能没有原 OnEnter/OnLeave 脚本，直接调用会报 nil 错 by 武藤纯子酱 2026.8.31
        if hookedOnEnter then hookedOnEnter() end
        CleveRoids.SetMouseoverFrom("ctuf", "targettarget")
    end)

    widget:SetScript("OnLeave", function()
        if hookedOnLeave then hookedOnLeave() end
        CleveRoids.ClearMouseoverFrom("ctuf")
        CleveRoids.ClearMouseoverFrom("native")
    end)
end

function Extension.OnLoad()
    -- 修复：CT_UnitFrames 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("CT_UnitFrames")) then return end
    -- 修复：仅判 CT_AssistFrame 不够，其余三个子框架任一缺失时 SetHook(nil) 报错 by 武藤纯子酱 2026.9.9
    if not (CT_AssistFrame and CT_AssistFrameHealthBar and CT_AssistFrameManaBar and CT_AssistFrame_Drag) then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发，避免重复包装 SetScript by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end
    CleveRoids.Print("CT_UnitFrames module loaded.")

    Extension.SetHook(CT_AssistFrame)
    Extension.SetHook(CT_AssistFrameHealthBar)
    Extension.SetHook(CT_AssistFrameManaBar)
    Extension.SetHook(CT_AssistFrame_Drag)
    Extension.__cr_hooked = true
end

_G["CleveRoids"] = CleveRoids
