--[[
    EventMacros - 独立事件宏系统（不再依赖 SuperMacro）
    - 提供与 SuperMacro 同语义的 RegisterEventMacro/UnregisterEventMacro
    - 事件触发时由本插件自己的事件框架派发执行
    - 普通宏：通过 CleveRoids.ExecuteMacroByName 执行（原生宏槽位 + CRM 增强语法）
    - 超级宏：SuperMacro 在场时走其 RunSuperMacro（保持完整超级宏语义），
      不在场时回退 ExecuteMacroByName（GetSuperMacroInfo/CRM 缓存兜底）
    by 武藤纯子酱 2026.9.3
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

-- 防止重复加载
if CleveRoids.EventMacrosLoaded then return end
CleveRoids.EventMacrosLoaded = true

-- 超级宏键前缀：使用控制字符 \1。原用 "SUPER" 前缀，普通宏名恰好以 SUPER 开头时
-- 会被误判为超级宏；控制字符不可能出现在宏名中，彻底避免冲突 by 武藤纯子酱 2026.9.11
local SUPER_PREFIX = "\1"

-- 事件宏监听框架（frame.events[事件][宏键]=1）
local eventsFrame = CreateFrame("Frame")
eventsFrame.events = {}
CleveRoids.EventMacrosFrame = eventsFrame

-- 事件触发时的派发逻辑
eventsFrame:SetScript("OnEvent", function()
    local ev = event
    local macros = eventsFrame.events[ev]
    if not macros then return end

    -- 修复：先对键做快照，避免宏在执行过程中调用 RegisterEventMacro 增键导致
    -- pairs 遍历未定义行为（invalid key to 'next'）by 武藤纯子酱 2026.9.11
    local keys, n = {}, 0
    for macroKey in pairs(macros) do
        n = n + 1
        keys[n] = macroKey
    end

    for i = 1, n do
        local macroKey = keys[i]
        -- 每次事件宏执行前清停止标志（与 SuperMacro 兼容层在宏起始处的清标志行为一致）
        CleveRoids.stopMacroFlag = false
        CleveRoids.skipMacroFlag = false
        CleveRoids.stopOnCastFlag = false

        if string.sub(macroKey, 1, 1) == SUPER_PREFIX then
            local macroName = string.sub(macroKey, 2)
            if type(_G.RunSuperMacro) == "function" then
                -- SuperMacro 在场：走其原生超级宏执行器
                _G.RunSuperMacro(macroName)
            else
                -- SuperMacro 不在场：回退 CRM 执行链（Blizzard 宏 → GetSuperMacroInfo → CRM 缓存）
                CleveRoids.ExecuteMacroByName(macroName)
            end
        else
            -- 普通宏：CRM 原生执行（支持条件语法/增强命令，含递归深度与停止标志保护）
            CleveRoids.ExecuteMacroByName(macroKey)
        end
    end
end)

-- 注册事件宏：宏在指定事件触发时执行
-- macro: 宏名  super: 1=超级宏 0=普通宏  ...: 事件名列表
function CleveRoids.RegisterEventMacro(macro, super, ...)
    if type(macro) ~= "string" or macro == "" then return false end
    local macroname = macro
    if (super == 1) then
        macroname = SUPER_PREFIX .. macroname
    end
    for i = 1, arg.n do
        local eventName = arg[i]
        if type(eventName) == "string" and eventName ~= "" then
            eventsFrame:RegisterEvent(eventName)
            if not eventsFrame.events[eventName] then
                eventsFrame.events[eventName] = {}
            end
            eventsFrame.events[eventName][macroname] = 1
        end
    end
    return true
end

-- 注销事件宏
-- macro: 宏名  super: 1=超级宏 0=普通宏  ...: 事件名列表
function CleveRoids.UnregisterEventMacro(macro, super, ...)
    if type(macro) ~= "string" or macro == "" then return false end
    local macroname = macro
    if (super == 1) then
        macroname = SUPER_PREFIX .. macroname
    end
    for i = 1, arg.n do
        local eventName = arg[i]
        local evTable = eventsFrame.events[eventName]
        if evTable then
            evTable[macroname] = nil
            -- 该事件没有其他宏注册时取消监听
            if not next(evTable) then
                eventsFrame:UnregisterEvent(eventName)
                eventsFrame.events[eventName] = nil
            end
        end
    end
    return true
end

-- 查询某事件宏已注册的全部事件名（返回表）
function CleveRoids.GetEventMacroEvents(macro, super)
    local result = {}
    if type(macro) ~= "string" or macro == "" then return result end
    local macroname = macro
    if (super == 1) then
        macroname = SUPER_PREFIX .. macroname
    end
    for eventName, macros in pairs(eventsFrame.events) do
        if macros[macroname] then
            table.insert(result, eventName)
        end
    end
    return result
end

-- 查询事件宏是否已注册在指定事件上 by 武藤纯子酱 2026.9.3
function CleveRoids.IsEventMacroRegistered(macro, super, eventName)
    if type(macro) ~= "string" or macro == "" then return false end
    local macroname = macro
    if (super == 1) then
        macroname = SUPER_PREFIX .. macroname
    end
    local evTable = eventsFrame.events[eventName]
    return evTable ~= nil and evTable[macroname] ~= nil
end

-- SuperMacro 未加载时提供同名全局函数，保证既有初始化脚本/宏文本可直接调用
-- （SuperMacro 经 OptionalDeps 先于本插件加载，故此处检测可靠） by 武藤纯子酱 2026.9.3
if not _G.RegisterEventMacro then
    _G.RegisterEventMacro = function(macro, super, ...)
        return CleveRoids.RegisterEventMacro(macro, super, unpack(arg))
    end
end
if not _G.UnregisterEventMacro then
    _G.UnregisterEventMacro = function(macro, super, ...)
        return CleveRoids.UnregisterEventMacro(macro, super, unpack(arg))
    end
end
