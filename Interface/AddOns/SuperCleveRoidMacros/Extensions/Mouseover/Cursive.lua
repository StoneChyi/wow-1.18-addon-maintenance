--[[
    Cursive mouseover support.
    Hooks into Cursive's bar OnEnter/OnLeave to track mouseover unit by GUID.
    Enables [@mouseover] macros when hovering over Cursive DoT timer bars.
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

CleveRoids.Hooks = CleveRoids.Hooks or {}

local Extension = CleveRoids.RegisterExtension("CursiveMouseover")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

local hooked = false

function Extension.OnEnter(guid)
    if guid and guid ~= 0 then
        -- SetMouseoverUnit (Nampower v2.37+ / SuperWoW) supports GUIDs directly by 武藤纯子酱 2026.9.1
        CleveRoids.SetMouseoverFrom("cursive", guid)
    end
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("cursive")
end

local function HookCursiveUI()
    -- Check if Cursive and its UI module exist
    if not Cursive or not Cursive.ui then
        return false
    end

    -- Already hooked
    if hooked then
        return true
    end

    local ui = Cursive.ui
    local hookedSomething = false

    -- Hook BarEnter if it exists
    if ui.BarEnter and not CleveRoids.Hooks.CursiveBarEnter then
        hookedSomething = true
        CleveRoids.Hooks.CursiveBarEnter = ui.BarEnter
        ui.BarEnter = function(...)
            -- Call original（转发全部参数，原实现丢弃了 Cursive 传入的参数）by 武藤纯子酱 2026.9.11
            CleveRoids.Hooks.CursiveBarEnter(unpack(arg))
            -- Set mouseover from the bar's parent guid
            if this and this.parent and this.parent.guid then
                Extension.OnEnter(this.parent.guid)
            end
        end
    end

    -- Hook BarLeave if it exists
    if ui.BarLeave and not CleveRoids.Hooks.CursiveBarLeave then
        hookedSomething = true
        CleveRoids.Hooks.CursiveBarLeave = ui.BarLeave
        ui.BarLeave = function(...)
            -- Clear mouseover first
            Extension.OnLeave()
            -- Call original（转发全部参数）by 武藤纯子酱 2026.9.11
            CleveRoids.Hooks.CursiveBarLeave(unpack(arg))
        end
    end

    -- 修复：原先无论是否实际 Hook 了任何东西都标记 hooked=true 并放弃重试 by 武藤纯子酱 2026.8.31
    if hookedSomething then
        hooked = true
        return true
    end
    return false
end

function Extension.OnLoad()
    -- 修复：Cursive 按字母序在本插件之前加载，其 ADDON_LOADED 事件已错过（原 arg1 守卫永不通过）；
    -- 改为 IsAddOnLoaded 判断，同时保留真实事件参数的兼容 by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("Cursive")) then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发，避免创建多个重试帧 by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end
    Extension.__cr_hooked = true

    -- Delay slightly to ensure Cursive.ui is initialized
    local frame = CreateFrame("Frame")
    frame.attempts = 0
    frame:SetScript("OnUpdate", function()
        frame.attempts = frame.attempts + 1
        if HookCursiveUI() then
            -- 修复：Hide() 不会停止 OnUpdate，必须显式清除脚本，否则每帧空转整个会话 by 武藤纯子酱 2026.8.31
            frame:SetScript("OnUpdate", nil)
        elseif frame.attempts > 600 then
            -- 约 10 秒仍无法 Hook（如 Cursive 版本没有 BarEnter/BarLeave），放弃重试避免永久空转 by 武藤纯子酱 2026.8.31
            frame:SetScript("OnUpdate", nil)
        end
    end)
end

-- Also try to hook immediately in case Cursive is already loaded
if Cursive and Cursive.ui then
    HookCursiveUI()
end

_G["CleveRoids"] = CleveRoids
