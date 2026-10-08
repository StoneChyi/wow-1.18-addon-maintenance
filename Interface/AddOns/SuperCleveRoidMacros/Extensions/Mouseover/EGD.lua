--[[
    Author: SuperCleveRoidMacros
    License: MIT License

    EGD (EasyGrid) mouseover support.
    Hooks into EGD's unit frames to enable [@mouseover] macros.
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("EGD")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter(frame, unitId)
    if unitId then
        CleveRoids.SetMouseoverFrom("egd", unitId)
    end
end

function Extension.OnLeave(frame)
    CleveRoids.ClearMouseoverFrom("egd")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.SetupMouseover(frame)
    if not frame then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发，避免重复包装同一帧 by 武藤纯子酱 2026.9.11
    if frame.__cr_egd_hooked then return end
    frame.__cr_egd_hooked = true

    local origOnEnter = frame:GetScript("OnEnter")
    local origOnLeave = frame:GetScript("OnLeave")

    frame:SetScript("OnEnter", function()
        -- Call original (EGD's tooltip display)
        if origOnEnter then origOnEnter() end
        -- Set mouseover
        Extension.OnEnter(frame, frame.unitId)
    end)

    frame:SetScript("OnLeave", function()
        -- Clear mouseover first
        Extension.OnLeave(frame)
        -- Call original (hide tooltip)
        if origOnLeave then origOnLeave() end
    end)
end

function Extension.OnLoad()
    -- 修复：EGD 在本插件之前加载，ADDON_LOADED 已错过；改用 IsAddOnLoaded（兼容事件参数） by 武藤纯子酱 2026.8.31
    -- 修复：同 Grid——arg1 守卫使 IsAddOnLoaded 兜底永不执行，改为无条件判断
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("EGD")) then return end

    -- 修复（兼容新版 EGD）：不再依赖 EGD 内部变量（MAX_COLUMNS/ROWS_PER_COL 在新版中
    -- 可能是 local，引用全局会得到 nil 导致乘法报错）。改用 EGD 创建帧时固定的命名
    -- 帧名 _G["MyRaidGrid"..i]（团队网格）与 _G["EGDPetFrame"..i]（宠物框），
    -- 并保留 _G.EGDFrame.gridFrames 作为兜底（新版 EGD 在文件末尾暴露全局 EGDFrame）by 武藤纯子酱 2026.8.31
    local hooked = 0

    -- 方式①：按命名帧访问（最可靠，不依赖 EGD 内部变量）
    local MAX_GRID = 40 -- EGD 默认 8列×5行=40 格，留余量
    for i = 1, MAX_GRID do
        local f = _G["MyRaidGrid"..i]
        if f then
            Extension.SetupMouseover(f)
            hooked = hooked + 1
        end
        local pf = _G["EGDPetFrame"..i]
        if pf then
            Extension.SetupMouseover(pf)
            hooked = hooked + 1
        end
    end

    -- 方式②：兜底（若全局 EGDFrame.gridFrames 存在且命名帧方式未命中）
    if hooked == 0 and EGDFrame and EGDFrame.gridFrames then
        for i, frame in ipairs(EGDFrame.gridFrames) do
            if frame then
                Extension.SetupMouseover(frame)
                hooked = hooked + 1
            end
        end
        if EGDFrame.petFrames then
            for i, pf in ipairs(EGDFrame.petFrames) do
                if pf then
                    Extension.SetupMouseover(pf)
                    hooked = hooked + 1
                end
            end
        end
    end

    if hooked == 0 and CleveRoids.debug then
        CleveRoids.Print("|cff00aaff[EGD]|r 未找到 EGD 网格帧（可能未加载或版本变化）")
    end
end

_G["CleveRoids"] = CleveRoids
