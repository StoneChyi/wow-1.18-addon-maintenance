--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("sRaidFrames")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

-- 修复：HookMethod 以普通函数回调；sRaidFrames 用 `sRaidFrames:UnitTooltip(frame)` 调用，
-- 故 arg1=self、arg2=frame，必须用冒号定义才能让 frame 绑定到第二个参数
-- （此前改成点语法导致 frame 变成 self，@mouseover 失效） by 武藤纯子酱 2026.9.11
function Extension:OnEnter(frame)
    if frame and frame.unit then
        CleveRoids.SetMouseoverFrom("sraid", frame.unit)
    end
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("sraid")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnLoad()
    -- 修复：sRaidFrames 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("sRaidFrames")) then return end
    -- 修复：全局可能尚未建立；去重避免重复 HookMethod by 武藤纯子酱 2026.9.11
    if not sRaidFrames then return end
    if Extension.__cr_hooked then return end

    Extension.HookMethod(sRaidFrames, "UnitTooltip", "OnEnter")
    Extension.HookMethod(_G["GameTooltip"], "Hide", "OnLeave")
    Extension.HookMethod(_G["GameTooltip"], "FadeOut", "OnLeave")
    Extension.__cr_hooked = true
end

_G["CleveRoids"] = CleveRoids
