--[[
    Author: Dennis Werner Garske (DWG) / brian / Mewtiny
    License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

-- A list of all registered extensions
CleveRoids.Extensions = CleveRoids.Extensions or {}

-- Calls the "OnLoad" function of every extension
function CleveRoids.InitializeExtensions()
    for k, v in pairs(CleveRoids.Extensions) do
        local func = v["OnLoad"]
        if not func then
            CleveRoids.Print("CleveRoids.InitializeExtensions - Couldn't find 'OnLoad' function for extension "..k)
        else
            -- 修复：单个扩展 OnLoad 抛错会中断其余扩展初始化（pairs 顺序不定），逐个隔离 by 武藤纯子酱 2026.8.31
            local ok, err = pcall(func)
            if not ok and CleveRoids.debug then
                CleveRoids.Print("|cffff0000[Extension Error]|r " .. k .. ": " .. tostring(err))
            end
        end
    end
end

-- Removes the given hook
-- hook: The hook to remove
-- 修复：当本扩展的 wrapper 已被其它扩展后装包裹时，直接还原会丢失真正原函数；
-- 改为在包装链中把“指向本 wrapper 的 original”直接接到本 hook 的 original 上 by 武藤纯子酱 2026.9.11
local function SpliceOutGlobalHook(hook)
    for _, ext in pairs(CleveRoids.Extensions) do
        local hooks = ext.internal and ext.internal.hooks
        local h = hooks and hooks[hook.name]
        if h and h.original == hook.wrapper then
            h.original = hook.original
            return true
        end
    end
    return false
end

local function SpliceOutMethodHook(object, hook)
    for _, ext in pairs(CleveRoids.Extensions) do
        local mh = ext.internal and ext.internal.memberHooks
        local hooks = mh and mh[object]
        local h = hooks and hooks[hook.name]
        if h and h.original == hook.wrapper then
            h.original = hook.original
            return true
        end
    end
    return false
end

function CleveRoids.RemoveHook(hook)
    -- 修复：仅当全局当前仍指向本扩展安装的包装函数时才还原，避免覆盖其它扩展后装的 hook
    -- by 武藤纯子酱 2026.9.11
    if not hook.wrapper then
        _G[hook.name] = hook.original
        return
    end
    if _G[hook.name] == hook.wrapper then
        _G[hook.name] = hook.original
    else
        -- 被后装 hook 包裹：在包装链中摘除本 wrapper（可能多层） by 武藤纯子酱 2026.9.11
        local guard = 0
        while SpliceOutGlobalHook(hook) and guard < 32 do guard = guard + 1 end
    end
end

-- Removes the given hook from the given object
-- object: The object to remove the hook from
-- hook: The hook to remove
function CleveRoids.RemoveMethodHook(object, hook)
    -- 修复：同上，避免覆盖其它扩展后装的 hook by 武藤纯子酱 2026.9.11
    if not hook.wrapper then
        object[hook.name] = hook.original
        return
    end
    if object[hook.name] == hook.wrapper then
        object[hook.name] = hook.original
    else
        local guard = 0
        while SpliceOutMethodHook(object, hook) and guard < 32 do guard = guard + 1 end
    end
end

-- 删除：旧版 ClearHooks（整体注释，已被下方支持 extensionName 的版本取代） by 武藤纯子酱 2026.9.11
-- 修复：支持取消指定框架的hook by 武藤纯子酱 2026.7.2
function CleveRoids.ClearHooks(extensionName)
    local extensions = CleveRoids.Extensions

    if extensionName then
        -- Only clear hooks for the specified extension
        local ext = extensions[extensionName]
        if ext then
            for obj, hooks in pairs(ext.internal.memberHooks) do
                for name, hook in pairs(hooks) do
                    CleveRoids.RemoveMethodHook(obj, hook)
                end
            end
            for name, hook in pairs(ext.internal.hooks) do
                CleveRoids.RemoveHook(hook)
            end
            -- Clear the internal tables to prevent double removal
            ext.internal.memberHooks = {}
            ext.internal.hooks = {}
        end
    else
        -- Original behavior: clear all extensions' hooks
        for _, ext in pairs(extensions) do
            for obj, hooks in pairs(ext.internal.memberHooks) do
                for name, hook in pairs(hooks) do
                    CleveRoids.RemoveMethodHook(obj, hook)
                end
            end
            for name, hook in pairs(ext.internal.hooks) do
                CleveRoids.RemoveHook(hook)
            end
            ext.internal.memberHooks = {}
            ext.internal.hooks = {}
        end
    end
end

-- Creates a new extension with the given name
-- name: the name of the extension
function CleveRoids.RegisterExtension(name)
    local extension = {
        internal =
        {
            frame = CreateFrame("FRAME"),
            eventHandlers = {},
            hooks = {},
            memberHooks = {},
            activeHooks = {},  -- Re-entrancy guard: tracks hooks currently executing
        },
    }

    extension.RegisterEvent = function(eventName, callbackName)
        CleveRoids.RegisterEvent(name, eventName, callbackName)
    end

    extension.Hook = function(functionName, callbackName, dontCallOriginal)
        CleveRoids.RegisterHook(name, functionName, callbackName, dontCallOriginal)
    end

    extension.HookMethod = function(object, functionName, callbackName, dontCallOriginal)
        CleveRoids.RegisterMethodHook(name, object, functionName, callbackName, dontCallOriginal)
    end


    extension.UnregisterEvent = function(eventName, callbackName)
        CleveRoids.UnregisterEvent(name, eventName, callbackName)
    end

    extension.internal.OnEvent = function()
        -- 修复：同一事件原先只支持一个回调（后注册的静默覆盖前一个），改为回调列表 by 武藤纯子酱 2026.8.31
        local handlers = extension.internal.eventHandlers[event]
        if type(handlers) == "table" then
            for _, callbackName in ipairs(handlers) do
                local cb = extension[callbackName]
                if cb then cb() end
            end
        elseif type(handlers) == "string" then
            extension[handlers]()
        end
    end


    -- This is a function wrapper that we swap with the function that we want to hook
    -- @return Value of Callback() or Origininal() if dontCallOriginal is false
    extension.internal.OnHook = function(object, functionName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        -- 性能优化（P2-7）：hookKey 在注册时预生成并存入 hook 表，调用时不再拼接字符串；
        -- 同时合并了原先的两次 hook 查找 by 武藤纯子酱 2026.8.31
        local hook
        if object then
            local memberHooks = extension.internal.memberHooks[object]
            hook = memberHooks and memberHooks[functionName]
        else
            hook = extension.internal.hooks[functionName]
        end
        if not hook then return end

        local hookKey = hook.hookKey

        -- Re-entrancy guard: if this hook is already executing, call original directly
        if extension.internal.activeHooks[hookKey] then
            if hook.original then
                return hook.original(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
            end
            return
        end

        -- Mark this hook as active
        extension.internal.activeHooks[hookKey] = true
        -- 修复：无论 callback 还是 original 抛出任何错误，activeHooks[hookKey] 都会被清理，后续调用不会因重入标志卡住 by 武藤纯子酱 2026.7.2
        -- 1. 调用 callback（增强逻辑），错误时记录
        -- 修复：pcall 会把多返回值折叠为第一个，改用结果表 + unpack 还原全部返回值 by 武藤纯子酱 2026.8.31
        local cbResults = { pcall(hook.callback, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) }
        if not cbResults[1] then
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Hook Callback Error]|r " .. tostring(cbResults[2]))
            end
        end

        -- 2. 如果需要调用原始函数
        local results = cbResults
        if not hook.dontCallOriginal then
            local origResults = { pcall(hook.original, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) }
            if not origResults[1] then
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Hook Original Error]|r " .. tostring(origResults[2]))
                end
            end
            results = origResults
        end

        -- Mark this hook as inactive
        extension.internal.activeHooks[hookKey] = nil

        -- 修复：出错时不再把错误消息字符串当返回值（原 retval = cbResult 会把错误串返回给调用方） by 武藤纯子酱 2026.8.31
        if results[1] then
            -- 修复：table.getn 对含 nil 洞的返回值表（如原函数返回 (a, nil, c)）边界未定义，
            -- 可能截断返回值；改用"最高非 nil 索引"作 unpack 上界，完整还原返回值序列
            -- （中间 nil 洞保留、尾部值不丢）by 武藤纯子酱 2026.9.9
            local maxIdx = 1
            for i = 2, 32 do
                if results[i] ~= nil then maxIdx = i end
            end
            if maxIdx > 1 then
                return unpack(results, 2, maxIdx)
            end
            return nil
        end
        return nil
    end

    extension.internal.frame:SetScript("OnEvent", extension.internal.OnEvent)

    CleveRoids.Extensions[name] = extension

    return extension
end

-- Registers a callback function for a given event name
-- extensionName: The name of the extension trying to register the callback
-- eventName: The event's name we'd like to register a callback for
-- callbackName: The name of the callback that get's called when the event fires
function CleveRoids.RegisterEvent(extensionName, eventName, callbackName)
    local extension = CleveRoids.Extensions[extensionName]
    -- 修复：extension 为 nil 时下方 extension.internal 会崩 by 武藤纯子酱 2026.9.11
    if not extension then return end
    -- 修复：同一事件注册第二个回调时会静默覆盖第一个，改为回调名列表 by 武藤纯子酱 2026.8.31
    local handlers = extension.internal.eventHandlers[eventName]
    if handlers == nil then
        extension.internal.eventHandlers[eventName] = { callbackName }
    elseif type(handlers) == "table" then
        local exists = false
        for _, n in ipairs(handlers) do
            if n == callbackName then exists = true break end
        end
        if not exists then table.insert(handlers, callbackName) end
    else
        -- 兼容旧格式（字符串）
        extension.internal.eventHandlers[eventName] = { handlers, callbackName }
    end
    extension.internal.frame:RegisterEvent(eventName)
end

-- Hooks the given function by it's name
-- extensionName: The name of the extension trying to register the callback
-- functionName: The name of the function that'll be hooked
-- callbackName: The name of the callback that get's called when the hooked function is called
-- dontCallOriginal: Set to true when the original function should not be called
function CleveRoids.RegisterHook(extensionName, functionName, callbackName, dontCallOriginal)
    local orig = _G[functionName]
    local extension = CleveRoids.Extensions[extensionName]

    if not orig then
        CleveRoids.Print("CleveRoids.RegisterHook - Invalid function to hook: "..functionName)
        return -- 在检查到 orig 为空时，打印错误后立即 return，避免无效 hook 注册 by 武藤纯子酱 2026.7.2
    end

    if not extension then
        -- 修复：该分支的触发条件就是 extension 为 nil，原拼接 "..extension" 自身抛错 by 武藤纯子酱 2026.9.9
        CleveRoids.Print("CleveRoids.RegisterHook - Invalid extension: "..tostring(extensionName))
        return
    end

    if not extension[callbackName] then
        CleveRoids.Print("CleveRoids.RegisterHook - Couldn't find callback: "..tostring(callbackName))
        return
    end


    -- 修复：重复注册去重，避免包装链叠加（回调/原函数被多次执行）by 武藤纯子酱 2026.9.11
    if extension.internal.hooks[functionName] then return end

    local wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        return extension.internal.OnHook(nil, functionName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    end

    extension.internal.hooks[functionName] = {
        original = orig,
        callback = extension[callbackName],
        name = functionName,
        dontCallOriginal = dontCallOriginal,
        hookKey = "global:" .. functionName, -- 性能优化：调用时预生成的 key，避免每次拼接 by 武藤纯子酱 2026.8.31
        wrapper = wrapper, -- 供 RemoveHook 判断是否仍为本扩展的包装 by 武藤纯子酱 2026.9.11
    }

    _G[functionName] = wrapper
end

-- Hooks the given object's function
-- object: The object you want to hook
-- extensionName: The name of the extension trying to register the callback
-- functionName: The name of the function that'll be hooked
-- callbackName: The name of the callback that get's called when the hooked function is called
function CleveRoids.RegisterMethodHook(extensionName, object, functionName, callbackName, dontCallOriginal)
    if not object then
        CleveRoids.Print("CleveRoids.RegisterMethodHook - The object could not be found!")
        return
    end

    if type(object) ~= "table" then
        CleveRoids.Print("CleveRoids.RegisterMethodHook - The object needs to be a table!")
        return
    end

    local orig = object[functionName]

    if not orig then
        CleveRoids.Print("CleveRoids.RegisterMethodHook - The object doesn't have a function named "..functionName)
        return
    end

    local extension = CleveRoids.Extensions[extensionName]

    if not extension then
        -- 修复：同 RegisterHook——触发条件即 extension 为 nil，拼接自身会抛错 by 武藤纯子酱 2026.9.9
        CleveRoids.Print("CleveRoids.RegisterMethodHook - Invalid extension: "..tostring(extensionName))
        return
    end

    if not extension[callbackName] then
        CleveRoids.Print("CleveRoids.RegisterMethodHook - Couldn't find callback: "..tostring(callbackName))
        return
    end

    if not extension.internal.memberHooks[object] then
        extension.internal.memberHooks[object] = {}
    end

    -- 修复：重复注册去重，避免包装链叠加 by 武藤纯子酱 2026.9.11
    if extension.internal.memberHooks[object][functionName] then return end

    local wrapper = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        return extension.internal.OnHook(object, functionName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    end

    extension.internal.memberHooks[object][functionName] = {
        original = orig,
        callback = extension[callbackName],
        name = functionName,
        dontCallOriginal = dontCallOriginal,
        hookKey = tostring(object) .. ":" .. functionName, -- 性能优化：调用时预生成的 key，避免每次拼接 by 武藤纯子酱 2026.8.31
        wrapper = wrapper, -- 供 RemoveMethodHook 判断是否仍为本扩展的包装 by 武藤纯子酱 2026.9.11
    }

    object[functionName] = wrapper
end

function CleveRoids.UnregisterEvent(extensionName, eventName, callbackName)
    local extension = CleveRoids.Extensions[extensionName]
    -- 修复：extension 为 nil 保护 + 按 callbackName 精确移除（原忽略 callbackName，误清该事件全部回调）
    -- by 武藤纯子酱 2026.9.11
    if not extension then return end
    local handlers = extension.internal.eventHandlers[eventName]
    if handlers == nil then return end
    if type(handlers) == "table" and callbackName then
        for i = table.getn(handlers), 1, -1 do
            if handlers[i] == callbackName then table.remove(handlers, i) end
        end
        if table.getn(handlers) == 0 then
            extension.internal.eventHandlers[eventName] = nil
            extension.internal.frame:UnregisterEvent(eventName)
        end
    else
        extension.internal.eventHandlers[eventName] = nil
        extension.internal.frame:UnregisterEvent(eventName)
    end
end

_G["CleveRoids"] = CleveRoids
