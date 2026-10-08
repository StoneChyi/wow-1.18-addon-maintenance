--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local CreateFrames = nil

local Extension = CleveRoids.RegisterExtension("NotGrid")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter()
    CleveRoids.SetMouseoverFrom("ngrid", this.unit)
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("ngrid")
    CleveRoids.ClearMouseoverFrom("native")
end

-- 修复：抽取包裹逻辑，方便在 OnLoad 时对已存在帧补挂（原先要等下次队伍变动才生效） by 武藤纯子酱 2026.8.31
local function HookNotGridFrames()
    if not (NotGrid and NotGrid.UnitFrames) then return end

    for k, frame in pairs(NotGrid.UnitFrames) do
        if not frame.__cr_ngrid_hooked then -- 修复：每次 CreateFrames（队伍变动）都会重复包裹所有帧，形成无限包装链 by 武藤纯子酱 2026.8.31
            frame.__cr_ngrid_hooked = true
            local enter = frame:GetScript("OnEnter")
            local leave = frame:GetScript("OnLeave")

            frame:SetScript("OnEnter", function()
                if enter then enter() end -- 修复：原帧可能没有脚本，直接调用会报 nil 错 by 武藤纯子酱 2026.8.31
                Extension.OnEnter()
            end)

            frame:SetScript("OnLeave", function()
                if leave then leave() end
                Extension.OnLeave()
            end)
        end
    end
end

function CleveRoids:NotGrid_CreateFrames(...)
    -- 修复：转发调用参数（原忽略全部参数，若 NotGrid 以参数调用会丢语义）by 武藤纯子酱 2026.9.11
    CreateFrames(NotGrid, unpack(arg)); -- call the original

    HookNotGridFrames()
end

function Extension.OnLoad()
    -- NotGrid loads before CleveRoids, so if NotGrid is enabled, then it's global will exist.
    if not NotGrid then
        return
    end
    -- Hooking manually as we need a post hook.
    if not CreateFrames then -- 修复：防止重复 Hook 原函数导致无限递归 by 武藤纯子酱 2026.8.31
        CreateFrames = NotGrid.CreateFrames
        NotGrid.CreateFrames = CleveRoids.NotGrid_CreateFrames
    end

    -- 修复：主动包裹 NotGrid 初始创建的帧 by 武藤纯子酱 2026.8.31
    HookNotGridFrames()

    Extension.UnregisterEvent("ADDON_LOADED", "OnLoad") -- 修复：原名大小写笔误 Onload≠OnLoad，事件永不注销 by 武藤纯子酱 2026.9.11
end

_G["CleveRoids"] = CleveRoids
