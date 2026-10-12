assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_RandomMount")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
    return {
        ["RandomMount"] = "Random Mount",
        ["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"] = "Automatically summon random mounts, using bug mounts in Ahn'Qiraj",
    }
end)

L:RegisterTranslations("zhCN", function()
    return {
        ["RandomMount"] = "随机坐骑",
        ["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"] = "自动召唤随机坐骑，在安其拉神殿使用虫子坐骑，/rm 或 /randommount（建议做宏） - 使用随机坐骑",
    }
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_RandomMount = Automaton:NewModule("RandomMount")
Automaton_RandomMount.modulename = L["RandomMount"]
Automaton_RandomMount.moduledesc = L["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"]
Automaton_RandomMount.options = {}

-- 日志输出控制（0=禁用，1=启用）
local RM_ENABLE_DEBUG = 0

-- 坐骑页面的可能名称（用于在多语言环境下识别）
local mountTabNames = {
    "坐骑", "坐騎", "Mounts"
}

-- 职业坐骑列表
local classMounts = {
    -- 术士职业坐骑
    "召唤地狱战马",
    "召唤恐惧战马",
    
    -- 圣骑士职业坐骑
    "召唤战马",
    "召唤军马",
    "Summon Felsteed",
    "Summon Dreadsteed",
    "Summon Warhorse",
    "Summon Charger",
    "骑乘斑马",
    -- 德鲁伊特殊形态
    "条纹霜刃豹",
    "迅捷旅行形态"
}

-- 不被视为坐骑的法术列表（优先包含所有生活技能）
local nonMountSpells = {
    -- 生活技能（主要专业）
    "采矿",
    "熔炼矿石",
    "草药学",
    "剥皮",
    "锻造",
    "工程学",
    "侏儒工程学",
    "地精工程学",
    "炼金术",
    "转化",
    "裁缝",
    "制皮",
    "元素制皮",
    "部落制皮",
    "龙鳞制皮",
    "附魔",
    "分解",
    -- 生活技能（次要专业）
    "烹饪",
    "急救",
    "绷带",
    "钓鱼",
    "生存",
    -- 其他非坐骑法术
    "传送门",
    "传送",
    "开锁",
    "复活",
    "霜甲术",
    "侦测隐藏",
    "侦测魔法",
    "追踪矿物",
    "追踪草药",
    "追踪野兽",
    "追踪亡灵",
    "追踪恶魔",
    "追踪人型生物",
    "碾磨",
    "制作",
    "研磨",
    "龟速模式"
}

-- 打印调试信息
local function DebugMessage(message, force)
    if force or RM_ENABLE_DEBUG == 1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33AAFF[随机坐骑]|r " .. message)
    end
end

-- 获取表的长度（兼容所有表）
local function GetTableLength(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function TrimName(name)
    if type(name) ~= "string" then return "" end
    return (string.gsub(name, "^%s*(.-)%s*$", "%1"))
end

-- 安全获取法术名称，如果出错返回nil
local function SafeGetSpellName(spellIndex, bookType)
    local success, name = pcall(GetSpellName, spellIndex, bookType)
    if success then
        return name
    end
    return nil
end

-- 检查玩家是否在安其拉神殿
local function IsInAhnQiraj()
    local zoneName = GetRealZoneText()
    
    if not zoneName then return false end
    
    local aqPatterns = {
        "安其拉",
    }
    
    for i = 1, GetTableLength(aqPatterns) do
        local pattern = aqPatterns[i]
        if zoneName == pattern then
            DebugMessage("检测到当前位置：" .. zoneName .. "，判定为安其拉区域")
            return true
        end
    end
    
    DebugMessage("当前位置：" .. zoneName .. "，非安其拉区域")
    return false
end

-- 检查页面名称是否是坐骑页面
local function IsMountTab(tabName)
    if not tabName then return false end
    
    tabName = string.lower(tabName)
    for i = 1, GetTableLength(mountTabNames) do
        local name = string.lower(mountTabNames[i])
        if string.find(tabName, name, 1, true) then
            return true
        end
    end
    
    return false
end

-- 判断是否是虫子坐骑（通过名称）
local function IsBugMount(spellName)
    if not spellName then return false end
    
    if string.find(spellName, "其拉作战坦克") or
       string.find(spellName, "Qiraji") then
        return true
    end
    
    return false
end

-- 检查是否是职业坐骑
local function IsClassMount(spellName)
    if not spellName then return false end
    
    for i = 1, GetTableLength(classMounts) do
        if spellName == classMounts[i] then
            return true
        end
    end
    
    return false
end

-- 检查法术是否在nonMountSpells列表中（完全匹配）
local function IsNonMountSpell(spellName)
    if not spellName then return false end
    
    for i = 1, GetTableLength(nonMountSpells) do
        if spellName == nonMountSpells[i] then
            return true
        end
    end
    
    return false
end

-- Spellbook offsets are zero-based; GetSpellName/CastSpell use offset + 1.
local function ScanMounts()
    local mounts, byName, byIndex, seenMount = {}, {}, {}, {}
    for tabIndex = 1, GetNumSpellTabs() do
        local tabName, _, offset, count = GetSpellTabInfo(tabIndex)
        if type(offset) == "number" and type(count) == "number" then
            for index = offset + 1, offset + count do
                local name = SafeGetSpellName(index, BOOKTYPE_SPELL)
                if name and name ~= "" and not IsNonMountSpell(name) then
                    local isMount = IsMountTab(tabName) or IsClassMount(name)
                        or string.find(name, "骑乘乌龟", 1, true)
                        or string.find(name, "Riding Turtle", 1, true)
                    local key = string.lower(name)
                    local mount = {name = name, id = index, isMount = isMount}
                    byIndex[index] = mount
                    if not byName[key] or (isMount and not byName[key].isMount) then
                        byName[key] = mount
                    end
                    if isMount and not seenMount[key] then
                        seenMount[key] = true
                        table.insert(mounts, mount)
                    end
                end
            end
        end
    end
    return mounts, byName, byIndex
end

-- Persist names, never mutable spellbook positions. Unknown legacy positions
-- stay in the saved list for review and are never used to cast another spell.
local function MigrateMountList(list, byIndex)
    local seen, migrated = {}, false
    for i = GetTableLength(list), 1, -1 do
        local entry = list[i]
        if type(entry) == "number" and byIndex[entry] and byIndex[entry].isMount then
            entry = byIndex[entry].name
            list[i] = entry
            migrated = true
        end
        if type(entry) == "string" then
            local key = string.lower(entry)
            if seen[key] then
                table.remove(list, i)
            else
                seen[key] = true
            end
        end
    end
    return migrated
end

local function GetMountData()
    local mounts, byName, byIndex = ScanMounts()
    local char = Automaton_RandomMount.db.char
    char.customMounts = char.customMounts or {}
    char.excludedMounts = char.excludedMounts or {}
    -- Wait for the mount book to be available; do not reinterpret unresolved
    -- legacy positions after later spellbook changes.
    if mounts[1] and char.mountNamesVersion ~= 1 then
        local migratedCustom = MigrateMountList(char.customMounts, byIndex)
        local migratedExcluded = MigrateMountList(char.excludedMounts, byIndex)
        char.mountNamesVersion = 1
        if migratedCustom or migratedExcluded then
            DebugMessage("旧坐骑记录已按当前法术书转为名称保存，请核对自定义和移除列表。", true)
        end
    end
    return mounts, byName
end

local function FindMountByName(inputName)
    local _, byName = GetMountData()
    return byName[string.lower(TrimName(inputName))]
end

-- All learned mounts on the mount tab are eligible, including its last entry.
local function GetPlayerMounts()
    local mounts, byName = GetMountData()
    local excludedSet = {}
    for _, name in ipairs(Automaton_RandomMount.db.char.excludedMounts) do
        if type(name) == "string" then excludedSet[string.lower(name)] = true end
    end
    local result, seen = {bugs = {}, normal = {}}, {}
    local function AddMount(mount)
        local key = mount and string.lower(mount.name)
        if key and not seen[key] and not excludedSet[key] then
            seen[key] = true
            table.insert(IsBugMount(mount.name) and result.bugs or result.normal, mount)
        end
    end
    for _, mount in ipairs(mounts) do AddMount(mount) end
    if Automaton_RandomMount.db.char.customMountsEnable then
        for _, name in ipairs(Automaton_RandomMount.db.char.customMounts) do
            if type(name) == "string" then AddMount(byName[string.lower(name)]) end
        end
    end
    return result
end

-- 随机选择坐骑并释放
local function RandomMount()
    if UnitAffectingCombat("player") then
        DebugMessage("战斗中无法召唤坐骑！")
        return
    end
    
    if UnitCastingInfo and UnitCastingInfo("player") then
        DebugMessage("施法中无法召唤坐骑！")
        return
    elseif IsCurrentAction(1) or IsCurrentAction(2) or IsCurrentAction(3) or IsCurrentAction(4) then
        DebugMessage("施法中无法召唤坐骑！")
        return
    end
    
    local mounts = GetPlayerMounts()
    local selectedMount = nil
    
    local hasBugMounts = (mounts.bugs and mounts.bugs[1] ~= nil)
    local hasNormalMounts = (mounts.normal and mounts.normal[1] ~= nil)
    
    if not hasBugMounts and not hasNormalMounts then
        DebugMessage("您没有任何坐骑！")
        return
    end
    
    local inAhnQiraj = IsInAhnQiraj()
    
    if inAhnQiraj then
        local bugMountCount = GetTableLength(mounts.bugs)
        if bugMountCount > 0 then
            local index = random(bugMountCount)
            selectedMount = mounts.bugs[index]
            DebugMessage("在安其拉神殿中，选择虫子坐骑: " .. selectedMount.name)
        else
            DebugMessage("您没有虫子坐骑，无法在安其拉神殿骑行！")
            return
        end
    else
        local normalMountCount = GetTableLength(mounts.normal)
        if normalMountCount > 0 then
            local index = random(normalMountCount)
            selectedMount = mounts.normal[index]
            DebugMessage("选择普通坐骑: " .. selectedMount.name)
        else
            local bugMountCount = GetTableLength(mounts.bugs)
            if bugMountCount > 0 then
                local index = random(bugMountCount)
                selectedMount = mounts.bugs[index]
                DebugMessage("没有普通坐骑，只能使用虫子坐骑: " .. selectedMount.name)
            end
        end
    end
    
    if selectedMount then
        CastSpell(selectedMount.id, BOOKTYPE_SPELL)
    end
end

-- 处理聊天命令
local function HandleChatCommand(msg)
    msg = TrimName(msg)
    
    if msg == "list" then
        local mounts = GetPlayerMounts()
        DebugMessage("您当前可用的坐骑列表（已过滤移除的）:", true)
        
        if GetTableLength(mounts.bugs) > 0 then
            DebugMessage("虫子坐骑:", true)
            for i, mount in ipairs(mounts.bugs) do
                DebugMessage("  " .. i .. ". " .. mount.name, true)
            end
        end
        
        if GetTableLength(mounts.normal) > 0 then
            DebugMessage("普通坐骑:", true)
            for i, mount in ipairs(mounts.normal) do
                DebugMessage("  " .. i .. ". " .. mount.name, true)
            end
        end
        
        if GetTableLength(mounts.bugs) == 0 and GetTableLength(mounts.normal) == 0 then
            DebugMessage("没有找到任何坐骑", true)
        end
    elseif string.find(msg, "^debug") then
        local _, _, value = string.find(msg, "debug%s+(%d)")
        if value then
            value = tonumber(value)
            if value == 0 or value == 1 then
                RM_ENABLE_DEBUG = value
                DebugMessage("日志输出已" .. (value == 1 and "启用" or "禁用"), true)
            else
                DebugMessage("日志设置值无效，请使用 0（禁用）或 1（启用）", true)
            end
        else
            DebugMessage("当前日志输出状态：" .. (RM_ENABLE_DEBUG == 1 and "启用" or "禁用"), true)
            DebugMessage("使用 /rm debug 0 禁用日志输出，或 /rm debug 1 启用日志输出", true)
        end
    elseif msg == "customlist" then
        if Automaton_RandomMount.ListCustomMounts then
            Automaton_RandomMount:ListCustomMounts()
        end
    elseif msg == "excludelist" then
        if Automaton_RandomMount.ListExcludedMounts then
            Automaton_RandomMount:ListExcludedMounts()
        end
    elseif string.find(msg, "^exclude add ") then
        local _, _, name = string.find(msg, "^exclude add (.+)")
        if name then
            Automaton_RandomMount:ExcludeMount(name)
        else
            DebugMessage("用法: /rm exclude add 坐骑名称", true)
        end
    elseif string.find(msg, "^exclude remove ") then
        local _, _, name = string.find(msg, "^exclude remove (.+)")
        if name then
            Automaton_RandomMount:UnExcludeMount(name)
        else
            DebugMessage("用法: /rm exclude remove 坐骑名称", true)
        end
    elseif msg == "exclude clear" then
        Automaton_RandomMount:ClearExcludedMounts()
    elseif msg == "help" or msg == "?" then
        DebugMessage("随机坐骑命令:", true)
        DebugMessage("- /rm 或 /randommount - 使用随机坐骑", true)
        DebugMessage("- /rm list - 查看当前可用坐骑（已过滤移除的）", true)
        DebugMessage("- /rm customlist - 查看自定义坐骑列表", true)
        DebugMessage("- /rm excludelist - 查看已移除（黑名单）的坐骑", true)
        DebugMessage("- /rm exclude add 坐骑名称 - 将坐骑加入黑名单（不再出现）", true)
        DebugMessage("- /rm exclude remove 坐骑名称 - 将坐骑移出黑名单", true)
        DebugMessage("- /rm exclude clear - 清空黑名单", true)
        DebugMessage("- /rm debug 0|1 - 设置日志输出", true)
        DebugMessage("- /rm help - 显示此帮助信息", true)
        DebugMessage("- 更多设置请打开Automaton配置界面", true)
    else
        RandomMount()
    end
end

------------------------------
--      Options 构建        --
------------------------------

-- 添加自定义坐骑（通过名称）
function Automaton_RandomMount:AddCustomMount(inputName)
    inputName = TrimName(inputName)
    if inputName == "" then
        DebugMessage("请输入坐骑名称！", true)
        return
    end
    local mount = FindMountByName(inputName)
    if not mount then
        DebugMessage("未找到名为 \"" .. inputName .. "\" 的坐骑，请确认名称正确且已学会。", true)
        return
    end
    self.db.char.customMountsEnable = true
    for _, name in ipairs(self.db.char.customMounts) do
        if type(name) == "string" and string.lower(name) == string.lower(mount.name) then
            DebugMessage("坐骑 \"" .. mount.name .. "\" 已在自定义列表中！", true)
            return
        end
    end
    table.insert(self.db.char.customMounts, mount.name)
    DebugMessage("成功添加自定义坐骑：" .. mount.name, true)
end

local function ListSavedMounts(list, byName)
    for i, entry in ipairs(list) do
        if type(entry) == "string" then
            local suffix = byName[string.lower(entry)] and "" or "（当前未学会）"
            DebugMessage("  " .. i .. ". " .. entry .. suffix, true)
        else
            DebugMessage("  " .. i .. ". 旧法术书序号 " .. tostring(entry) .. "（无法确认，请重新添加坐骑名称）", true)
        end
    end
end

-- 列出所有自定义坐骑
function Automaton_RandomMount:ListCustomMounts()
    local _, byName = GetMountData()
    if GetTableLength(self.db.char.customMounts) == 0 then
        DebugMessage("自定义坐骑列表为空", true)
        return
    end
    DebugMessage("自定义坐骑列表:", true)
    ListSavedMounts(self.db.char.customMounts, byName)
end

-- 清除所有自定义坐骑
function Automaton_RandomMount:ClearCustomMounts()
    self.db.char.customMounts = {}
    DebugMessage("已清除所有自定义坐骑！", true)
end

-- 黑名单管理：添加坐骑到排除列表
function Automaton_RandomMount:ExcludeMount(inputName)
    inputName = TrimName(inputName)
    if inputName == "" then
        DebugMessage("请输入坐骑名称！", true)
        return
    end
    local mount = FindMountByName(inputName)
    if not mount then
        DebugMessage("未找到名为 \"" .. inputName .. "\" 的坐骑，请确认名称正确且已学会。", true)
        return
    end
    for _, name in ipairs(self.db.char.excludedMounts) do
        if type(name) == "string" and string.lower(name) == string.lower(mount.name) then
            DebugMessage("坐骑 \"" .. mount.name .. "\" 已在移除列表中！", true)
            return
        end
    end
    table.insert(self.db.char.excludedMounts, mount.name)
    DebugMessage("成功将坐骑加入移除列表：" .. mount.name, true)
end

-- Saved names can be removed even when the mount is no longer learned.
function Automaton_RandomMount:UnExcludeMount(inputName)
    inputName = TrimName(inputName)
    if inputName == "" then
        DebugMessage("请输入坐骑名称！", true)
        return
    end
    GetMountData()
    for i, name in ipairs(self.db.char.excludedMounts) do
        if type(name) == "string" and string.lower(name) == string.lower(inputName) then
            table.remove(self.db.char.excludedMounts, i)
            DebugMessage("成功将坐骑移出移除列表：" .. name, true)
            return
        end
    end
    DebugMessage("移除列表中不存在坐骑 \"" .. inputName .. "\"", true)
end

-- 列出黑名单中的所有坐骑
function Automaton_RandomMount:ListExcludedMounts()
    local _, byName = GetMountData()
    if GetTableLength(self.db.char.excludedMounts) == 0 then
        DebugMessage("移除列表为空", true)
        return
    end
    DebugMessage("已移除的坐骑列表:", true)
    ListSavedMounts(self.db.char.excludedMounts, byName)
end

-- 清空黑名单
function Automaton_RandomMount:ClearExcludedMounts()
    self.db.char.excludedMounts = {}
    DebugMessage("已清空移除列表！", true)
end

-- 构建选项面板
Automaton_RandomMount.options = {
    customMountsEnable = {
        name = "启用自定义坐骑",
        desc = "启用后，随机坐骑将包括您自定义添加的坐骑（与自动扫描的坐骑合并）",
        type = "toggle",
        order = 1,
        get = function() return Automaton_RandomMount.db.char.customMountsEnable end,
        set = function(v) Automaton_RandomMount.db.char.customMountsEnable = v end,
    },
    listMounts = {
        type = "execute",
        name = "列出所有可用坐骑",
        desc = "在聊天框显示您当前可用的所有坐骑（已过滤移除的）",
        order = 2,
        func = function()
            HandleChatCommand("list")
        end,
    },
    separator1 = {
        type = "header",
        name = "自定义坐骑管理（通过名称）",
        order = 10,
    },
    customMountAdd = {
        type = "text",
        name = "添加自定义坐骑",
        desc = "输入坐骑名称添加（例如：召唤战马）",
        order = 11,
        get = false,
        set = function(v) Automaton_RandomMount:AddCustomMount(v) end,
        usage = "输入坐骑名称后按回车",
    },
    customMountList = {
        type = "execute",
        name = "查看自定义坐骑列表",
        desc = "显示所有已添加的自定义坐骑",
        order = 12,
        func = function() Automaton_RandomMount:ListCustomMounts() end,
    },
    customMountClear = {
        type = "execute",
        name = "清除所有自定义坐骑",
        desc = "一键清除所有自定义坐骑",
        order = 13,
        func = function() Automaton_RandomMount:ClearCustomMounts() end,
    },
    separator2 = {
        type = "header",
        name = "移除坐骑管理（黑名单）",
        order = 20,
    },
    excludeMountAdd = {
        type = "text",
        name = "移除坐骑（加入黑名单）",
        desc = "输入坐骑名称，将其从可用坐骑中移除",
        order = 21,
        get = false,
        set = function(v) Automaton_RandomMount:ExcludeMount(v) end,
        usage = "输入坐骑名称后按回车",
    },
    excludeMountRemove = {
        type = "text",
        name = "恢复坐骑（移出黑名单）",
        desc = "输入坐骑名称，将其重新加入可用坐骑",
        order = 22,
        get = false,
        set = function(v) Automaton_RandomMount:UnExcludeMount(v) end,
        usage = "输入坐骑名称后按回车",
    },
    excludeMountList = {
        type = "execute",
        name = "查看已移除的坐骑列表",
        desc = "显示所有已被移除（黑名单）的坐骑",
        order = 23,
        func = function() Automaton_RandomMount:ListExcludedMounts() end,
    },
    excludeMountClear = {
        type = "execute",
        name = "清空移除列表",
        desc = "一键恢复所有被移除的坐骑",
        order = 24,
        func = function() Automaton_RandomMount:ClearExcludedMounts() end,
    },
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_RandomMount:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("RandomMount")
    -- 注册 profile 默认值（模块禁用状态，跨角色）
    Automaton:RegisterDefaults("RandomMount", "profile", {
        disabled = true,
    })
    -- 注册 char 默认值（角色特定数据）
    Automaton:RegisterDefaults("RandomMount", "char", {
        customMountsEnable = false,
        customMounts = {},
        excludedMounts = {},
    })
    Automaton:SetDisabledAsDefault(self, "RandomMount")
    self:RegisterOptions(self.options)
    
    SLASH_RANDOMMOUNT1 = "/rm"
    SLASH_RANDOMMOUNT2 = "/randommount"
    SlashCmdList["RANDOMMOUNT"] = HandleChatCommand
    
    _G["RandomMount"] = RandomMount
end

function Automaton_RandomMount:OnEnable() end
function Automaton_RandomMount:OnDisable() end