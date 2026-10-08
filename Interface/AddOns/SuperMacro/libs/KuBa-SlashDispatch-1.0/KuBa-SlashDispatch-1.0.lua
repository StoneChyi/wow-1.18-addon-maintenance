--[[
Name: KuBa-SlashDispatch-1.0
Revision: $Rev: 10001 $
Author(s): Crazydru
Website: https://gitee.com/ku-ba
Description: 自动扫描 SLASH_* 全局变量构建反向缓存，提供 O(1) slash 命令分发执行。
Dependencies: AceLibrary, AceEvent-2.0

使用方法：
-- 获取库实例
local dispatch = AceLibrary("KuBa-SlashDispatch-1.0")

-- 执行插件命令
dispatch:Execute("/qh party1")     -- QuickHeal
dispatch:Execute("decurse")        -- Decurse 插件

-- 手动注册
dispatch:RegisterSlashHandler("hi", function(params)
    print("Hi " .. (params or "there"))
end)
dispatch:Execute("/hi Crazydru")   -- 输出: Hi Crazydru
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-SlashDispatch-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验AceLibrary
if not AceLibrary then
    error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验AceEvent2.0
if not AceLibrary:HasInstance("AceEvent-2.0") then
    error(MAJOR_VERSION .. " requires AceEvent-2.0")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
    return
end

local Library = {}

--------------------------------
-- 内部状态
local reverseCache  = {}   -- "/qh"      → function
local manualAliases = {}   -- "qh"       → function（手动注册，不被自动扫描覆盖）
local dispatchDepth = 0
local MAX_DEPTH     = 3
-- ============================================================
-- 内部：聊天框兜底
-- ============================================================
local function ChatFallback(fullCmd, params)
    local text = fullCmd .. (params ~= "" and (" " .. params) or "")
    if ChatFrameEditBox then
        return pcall(function()
            ChatFrameEditBox:SetText(text)
            ChatEdit_SendText(ChatFrameEditBox)
        end)
    end
    return false
end
-- ============================================================
-- 核心：构建反向缓存（扫描 SLASH_* 全局变量）
-- ============================================================
local function BuildCache()
    -- 1) 保留手动注册的别名
    local preserved = {}
    for name, fn in pairs(manualAliases) do
        preserved["/" .. name] = fn
    end

    -- 2) 清空自动条目
    for k in pairs(reverseCache) do
        if not manualAliases[k] then
            reverseCache[k] = nil
        end
    end

    -- 3) 放回手动别名
    for k, v in pairs(preserved) do
        reverseCache[k] = v
    end

    -- 4) 扫描 SLASH_* 全局变量
    local env = getfenv(0)
    for name, value in pairs(env) do
        local key = string.match(name, "^SLASH_(%w+)%d+$")
        if key and type(value) == "string" and string.sub(value, 1, 1) == "/" then
            local lowerCmd = string.lower(value)
            -- 手动别名优先
            if reverseCache[lowerCmd] == nil then
                local handler = SlashCmdList[key]
                if handler then
                    reverseCache[lowerCmd] = handler
                end
            end
        end
    end
end

-- ============================================================
-- 事件回调：PLAYER_LOGIN / ADDON_LOADED 时自动补扫
-- ============================================================
function Library:PLAYER_LOGIN()
    BuildCache()
end

function Library:ADDON_LOADED()
    BuildCache()
end

-- ============================================================
-- 公共 API
-- ============================================================

--- 执行一条 slash 命令
--- @param input string 完整命令，可带或不带前导 "/"
--- @return boolean success
function Library:Execute(input)
    if type(input) ~= "string" or input == "" then return false end

    dispatchDepth = dispatchDepth + 1
    if dispatchDepth > MAX_DEPTH then
        dispatchDepth = dispatchDepth - 1
        return false
    end

    -- 去掉所有前导斜杠
    local raw = string.gsub(input, "^/+", "")
    local spaceIdx = string.find(raw, " ")
    local cmdName, params = raw, ""
    if spaceIdx then
        cmdName = string.sub(raw, 1, spaceIdx - 1)
        params  = string.sub(raw, spaceIdx + 1)
    end

    local fullCmd = "/" .. cmdName
    local handler  = reverseCache[fullCmd]

    if handler then
        local ok, err = pcall(handler, params)
        dispatchDepth = dispatchDepth - 1
        if ok then
            return true
        end
        -- 临时：把错误打出来
        DEFAULT_CHAT_FRAME:AddMessage("USE ERROR: " .. tostring(err))
        return ChatFallback(fullCmd, params)
    end

    -- 没找到 → 聊天框兜底
    dispatchDepth = dispatchDepth - 1
    return ChatFallback(fullCmd, params)
end

--- 手动注册一个 slash 命令（给不走 SLASH_* 的插件用）
--- @param cmdName string 不带斜杠，如 "mycmd"
--- @param handler function 接收 params 作为唯一参数
function Library:RegisterSlashHandler(cmdName, handler)
    if type(cmdName) ~= "string" or type(handler) ~= "function" then return end
    local lower = string.lower(cmdName)
    manualAliases[lower] = handler
    reverseCache["/" .. lower] = handler
end

--- 注销手动注册的命令
--- @param cmdName string
function Library:UnregisterSlashHandler(cmdName)
    if type(cmdName) ~= "string" then return end
    local lower = string.lower(cmdName)
    manualAliases[lower] = nil
    reverseCache["/" .. lower] = nil
end

--- 手动刷新缓存（一般不用，PLAYER_LOGIN / ADDON_LOADED 会自动触发）
function Library:RebuildCache()
    reverseCache  = {}
    BuildCache()
end

--- 调试用：查看某命令绑了哪个函数
--- @param cmdName string 命令名，带不带斜杠都行，如 "cast" 或 "/cast"
--- @return function|nil
function Library:GetHandler(cmdName)
    if type(cmdName) ~= "string" then return nil end
    local cmd = string.lower(cmdName)
    if string.sub(cmd, 1, 1) ~= "/" then
        cmd = "/" .. cmd
    end
    return reverseCache[cmd]
end



--------------------------------
-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
    Library = self

    if oldLib then
        -- 迁移旧版缓存（如果有）
        if oldLib.GetHandler then
            -- 旧版数据不继承，直接重建
        end
    end

    -- 新版本初始化：立即扫一次（此时大多数插件的 SLASH_* 已注册）
    BuildCache()

    if oldDeactivate then
        oldDeactivate(oldLib)
    end
end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)
    if major == "AceEvent-2.0" then
        -- 混入事件
        instance:embed(self)
        -- 注册事件
        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("ADDON_LOADED")
    end
end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil