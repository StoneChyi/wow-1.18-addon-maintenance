--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("CT_RaidAssist")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter()
	if ( SpellIsTargeting() ) then
		SetCursor("CAST_CURSOR")
	end
	local parent = this.frameParent
	if not parent then return end -- 修复：frameParent 缺失时下方 parent.id/parent.name 会抛错 by 武藤纯子酱 2026.9.12
	local id = parent.id
	local parentName = parent.name or "" -- 修复：未命名 frame 的 name 为 nil，strsub(nil,...) 抛错 by 武藤纯子酱 2026.9.12
	if ( strsub(parentName, 1, 12) == "CT_RAMTGroup" ) then
		local name
		if ( CT_RA_MainTanks and CT_RA_MainTanks[id] ) then -- 修复：CT_RA_MainTanks 表可能不存在，先判空 by 武藤纯子酱 2026.9.11
			name = CT_RA_MainTanks[id]
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i)
			if ( name and name == memberName ) then -- 修复：name 为 nil（空槽位）时不再误配 by 武藤纯子酱 2026.9.11
				id = i
				break
			end
		end
	elseif ( strsub(parentName, 1, 12) == "CT_RAPTGroup" ) then
		local name
		if ( CT_RA_PTargets and CT_RA_PTargets[id] ) then -- 修复：同上 by 武藤纯子酱 2026.9.11
			name = CT_RA_PTargets[id]
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i)
			if ( name and name == memberName ) then -- 修复：同上 by 武藤纯子酱 2026.9.11
				id = i
				break
			end
		end
	end
	CleveRoids.SetMouseoverFrom("ctra", "raid"..id)
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("ctra")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnLoad()
    -- 修复：CT_RaidAssist 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("CT_RaidAssist")) then return end
    -- 修复：hook 目标缺失时 Extension.Hook 不会注册；此时不应置 __cr_hooked，
    -- 否则后续 ADDON_LOADED 不再重试 by 武藤纯子酱 2026.9.11
    if not _G["CT_RA_MemberFrame_OnEnter"] then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发，避免重复 Hook by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end

    Extension.Hook("CT_RA_MemberFrame_OnEnter", "OnEnter")
    Extension.HookMethod(_G["GameTooltip"], "Hide", "OnLeave")
    Extension.HookMethod(_G["GameTooltip"], "FadeOut", "OnLeave")
    Extension.__cr_hooked = true

end

_G["CleveRoids"] = CleveRoids
