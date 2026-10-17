--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

local Extension = CleveRoids.RegisterExtension("MacroLengthWarn")

-- Set a global flag so we can check if this file loaded
CleveRoids.MacroLengthWarnLoaded = true

-- Maximum line length for macros (including spaces)
local MAX_LINE_LENGTH = 261

-- Store original functions
local edit_orig = nil
local macroframe_save_orig = nil

-- Validation function - returns true if valid, false if too long
local function ValidateMacroBody(body, macroName)
    if not body then
        return true -- No body means it's valid
    end

    for line in string.gfind(body, "([^\n]+)") do
        local lineLen = string.len(line)
        if lineLen > MAX_LINE_LENGTH then
            local name = macroName or "Unknown"
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffff0000ERROR:|r A line in the macro < |cffffffff%s|r > is |cffff0000%d characters|r long (max: |cffffffff%d|r).",
                name, lineLen, MAX_LINE_LENGTH
            ), 1, 0.82, 0)
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000This will CRASH the client and may DELETE all macros!|r Macro NOT saved.", 1, 0.82, 0)
            DEFAULT_CHAT_FRAME:AddMessage("Line: |cffffffff" .. string.sub(line, 1, 100) .. "...|r", 1, 1, 1)
            return false
        end
    end
    return true
end

-- Hook for EditMacro API function
-- 修复：1.12 EditMacro 签名为 (index, name, textureIndex, body, perCharacter)，
-- 原固定 4 参数转发会丢弃第 5 参 perCharacter，SuperMacro 等以第 5 参调用的
-- 路径会把角色专用宏写成账号宏；改用 arg 透传全部参数 by 武藤纯子酱 2026.9.9

-- 读取宏现有正文：本客户端 GetMacroInfo(index) → name, icon, body(, isLocal) by 武藤纯子酱 2026.9.28
local function GetMacroBodyForEdit(id)
    if not id then return "" end
    local ok, _, _, body = pcall(GetMacroInfo, id)
    if ok and type(body) == "string" then return body end
    return ""
end

-- SuperMacro 兼容分支专用：它用 EditMacro(id, name, icon)（body==nil）只改名/换图标，
-- 而原生 EditMacro 要求 body 非空（否则抛 Usage）→ 这里补上宏现有正文再转发。
-- 并**把返回值规整为宏序号**：部分客户端"带 body 写入"时返回的是布尔，而调用方普遍按
-- index = EditMacro(...) 使用（SuperMacro 亦是），若把布尔返回出去会被赋给 MacroFrame.selectedMacro
-- by 武藤纯子酱 2026.9.28
local function ForwardEditMacro(...)
    local idx, name, icon, body, perChar = arg[1], arg[2], arg[3], arg[4], arg[5]
    local r
    if body == nil and name ~= nil and icon ~= nil then
        body = GetMacroBodyForEdit(idx)
        if perChar ~= nil then
            r = edit_orig(idx, name, icon, body, perChar)
        else
            r = edit_orig(idx, name, icon, body)
        end
    else
        r = edit_orig(unpack(arg))
    end
    if type(r) == "number" then return r end
    return idx
end

function Extension.SafeEditMacro(...)
    local macro_id = arg[1]
    local body = arg[4]
    if CleveRoids.MacroLengthDebug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r EditMacro called for ID: " .. tostring(macro_id))
    end

    -- SuperMacro 兼容：它用 EditMacro(id, name, icon)（body==nil）只改名/换图标，
    -- 交给 ForwardEditMacro 补上现有正文再转发（原样转发会触发原生 Usage 报错） by 武藤纯子酱 2026.9.28
    if SuperMacroFrame ~= nil and arg[2] and arg[3] and body == nil then
        if edit_orig then return ForwardEditMacro(unpack(arg)) end
        return
    end

    -- Get macro name for error messages（仅在 id 为数字时查，否则 GetMacroInfo 会抛 Usage）
    -- by 武藤纯子酱 2026.9.28
    local macroName = (type(macro_id) == "number") and GetMacroInfo(macro_id) or nil

    -- Validate the macro body
    if not ValidateMacroBody(body, macroName) then
        -- Validation failed - do NOT save
        if CleveRoids.MacroLengthDebug then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r BLOCKED save - line too long")
        end
        return
    end

    -- Validation passed - call original
    if edit_orig then
        if CleveRoids.MacroLengthDebug then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r Validation passed, saving...")
        end
        -- 回退：非 SuperMacro 路径**原样转发**，不改动原生参数——此前"通用补 body"会让原生宏界面
        -- 改图标流程里 EditMacro 的返回值变成布尔并被赋给 MacroFrame.selectedMacro，引发连锁报错
        -- by 武藤纯子酱 2026.9.28
        return edit_orig(unpack(arg))
    end
end

-- Hook for MacroFrame_SaveMacro (Blizzard UI function)
function Extension.SafeMacroFrameSave()
    if CleveRoids.MacroLengthDebug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r MacroFrame_SaveMacro called")
    end

    -- This is called by the macro UI, so we need to get the text from the edit box
    -- selectedMacro 必须是数字（可能是其它流程遗留的布尔值），否则 GetMacroInfo 会抛 Usage
    -- by 武藤纯子酱 2026.9.28
    if MacroFrameText and type(MacroFrame.selectedMacro) == "number" then
        local body = MacroFrameText:GetText()
        local macroName = GetMacroInfo(MacroFrame.selectedMacro)

        -- Validate before allowing the save
        if not ValidateMacroBody(body, macroName) then
            if CleveRoids.MacroLengthDebug then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r BLOCKED MacroFrame save")
            end
            -- Don't call original - block the save
            return
        end
    end

    -- Validation passed or no text to validate
    if macroframe_save_orig then
        if CleveRoids.MacroLengthDebug then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r MacroFrame validation passed")
        end
        macroframe_save_orig()
    end
end

-- Install hooks when macro frame loads
function Extension.OnMacroFrameLoad()
    if Extension.macroFrameHooked then
        return
    end

    if CleveRoids.MacroLengthDebug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r Hooking MacroFrame_SaveMacro")
    end

    -- Hook MacroFrame_SaveMacro if it exists
    if MacroFrame_SaveMacro then
        macroframe_save_orig = MacroFrame_SaveMacro
        MacroFrame_SaveMacro = function(...)
            -- 修复：pcall 折叠返回值，改为结果表 + 最高非 nil 索引解包 by 武藤纯子酱 2026.9.11
            local results = { pcall(Extension.SafeMacroFrameSave, unpack(arg)) }
            if not results[1] then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MacroLengthWarn]|r MacroFrame hook error: " .. tostring(results[2]))
                -- Call original on error
                if macroframe_save_orig then
                    return macroframe_save_orig(unpack(arg))
                end
            end
            local maxIdx = 0
            for i = 2, 32 do if results[i] ~= nil then maxIdx = i end end
            if maxIdx > 1 then return unpack(results, 2, maxIdx) end
        end
        Extension.macroFrameHooked = true

        if CleveRoids.MacroLengthDebug then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MacroLengthWarn]|r MacroFrame_SaveMacro hooked successfully")
        end
    end
end

function Extension.OnAddonLoaded()
    -- 修复：1.12 无 Blizzard_MacroUI 插件，原 arg1 分支永不触发；OnMacroFrameLoad 自身幂等，
    -- 改为每次 ADDON_LOADED 尝试（已 hook 则直接返回）by 武藤纯子酱 2026.9.11
    Extension.OnMacroFrameLoad()
end

function Extension.OnLoad()
    -- 删除：ShowMessages 从未被调用（原仅被 PLAYER_LOGIN 空壳引用），为死代码 by 武藤纯子酱 2026.9.11

    -- Check if EditMacro exists
    if not EditMacro then
        CleveRoids.Print("[MacroLengthWarn] ERROR: EditMacro not found!")
        return
    end

    -- Capture and hook EditMacro immediately with error protection
    edit_orig = EditMacro
    EditMacro = function(...)
        -- 修复：pcall 折叠返回值，改为结果表 + 最高非 nil 索引解包 by 武藤纯子酱 2026.9.11
        local results = { pcall(Extension.SafeEditMacro, unpack(arg)) }
        if not results[1] then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MacroLengthWarn]|r Hook error: " .. tostring(results[2]))
            -- Call original on error to prevent breaking macros by 武藤纯子酱 2026.9.28
            if edit_orig then
                return edit_orig(unpack(arg))
            end
        end
        -- 只透传"宏序号"(数字)：本客户端原生 EditMacro 成功时返回的是布尔而非序号，
        -- 若把布尔透给调用方，会被赋给 MacroFrame.selectedMacro，引发后续算术 / GetMacroInfo 报错
        -- （旧版就是"不透传返回值"因而不报错） by 武藤纯子酱 2026.10.3
        if type(results[2]) ~= "number" then return end
        local maxIdx = 2
        for i = 3, 32 do if results[i] ~= nil then maxIdx = i end end
        return unpack(results, 2, maxIdx)
    end

    -- Listen for macro UI loading
    Extension.RegisterEvent("ADDON_LOADED", "OnAddonLoaded")

    -- Also try to hook MacroFrame_SaveMacro if it already exists
    if MacroFrame_SaveMacro then
        Extension.OnMacroFrameLoad()
    end
end

_G["CleveRoids"] = CleveRoids