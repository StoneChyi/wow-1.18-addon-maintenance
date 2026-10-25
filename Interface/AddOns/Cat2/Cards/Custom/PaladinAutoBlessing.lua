--[[
圣骑自动祝福（每职业单下拉·全时段版）：祝福只要没了就补，不分战斗与非战斗。
遍历目标单位（团队=全团 raid1..N，小队=全队 player+party1..N），按成员职业查对应祝福配置
（每职业一个下拉，含普通/强效祝福选项；选"不刷"=该职业不补）。
每个执行周期只补一个（防 GCD 堆积，瞬发祝福占用GCD属正常机制）。
]]

-- 职业标签颜色（1.12 标准职业色，|cffRRGGBB 颜色码）
local CLASS_COLOR = {
    warrior = "c79c6e",
    paladin = "f58cba",
    priest = "ffffff",
    mage = "40c7eb",
    warlock = "8788ee",
    hunter = "aad372",
    rogue = "fff569",
    druid = "ff7d0a",
    shaman = "0070dd",
}

local BLESSING_CHOICES = {
    { value = "", label = "不刷" },
    { value = "力量祝福", label = "力量祝福" },
    { value = "智慧祝福", label = "智慧祝福" },
    { value = "王者祝福", label = "王者祝福" },
    { value = "拯救祝福", label = "拯救祝福" },
    { value = "光明祝福", label = "光明祝福" },
    { value = "庇护祝福", label = "庇护祝福" },
    { value = "强效力量祝福", label = "强效力量祝福" },
    { value = "强效智慧祝福", label = "强效智慧祝福" },
    { value = "强效王者祝福", label = "强效王者祝福" },
    { value = "强效拯救祝福", label = "强效拯救祝福" },
    { value = "强效光明祝福", label = "强效光明祝福" },
    { value = "强效庇护祝福", label = "强效庇护祝福" },
}

local PET_BLESSING_CHOICES = {
    { value = "跟随猎人", label = "跟随猎人" },
    { value = "", label = "不刷" },
}
for i = 2, table.getn(BLESSING_CHOICES) do
    table.insert(PET_BLESSING_CHOICES, BLESSING_CHOICES[i])
end

-- 职业标签加颜色码（参数界面按职业色显示）
local function ColoredClassLabel(paramKey, label)
    return "|cff" .. (CLASS_COLOR[paramKey] or "ffffff") .. label .. "|r"
end

local card = {
    id = "paladin_auto_blessing",
    name = "自动祝福 |cff00b050-「射箭不手抖」提供|r",
    description = "按职业自动补祝福（不分战斗）",
    details = "普通卡：按流程位置执行，遍历全团/全队及宠物，按配置补充祝福，支持提前刷新。每轮最多尝试一个祝福；发出施放请求后结束本轮流程，无需补充或等待期间继续后续卡片。不分战斗与非战斗。",
    canStopSequence = true,
    sort = 64,
    category = "class",
    classes = {
        PALADIN = 2,
    },
    icons = {
        "Interface\\Icons\\Spell_Holy_BlessingOfStrength",
    },
    optionSchema = {
        {
            key = "warrior",
            type = "string",
            control = "select",
            label = ColoredClassLabel("warrior", "战士祝福"),
            shortLabel = "战士",
            default = "力量祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "paladin",
            type = "string",
            control = "select",
            label = ColoredClassLabel("paladin", "圣骑祝福"),
            shortLabel = "圣骑",
            default = "智慧祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "priest",
            type = "string",
            control = "select",
            label = ColoredClassLabel("priest", "牧师祝福"),
            shortLabel = "牧师",
            default = "智慧祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "mage",
            type = "string",
            control = "select",
            label = ColoredClassLabel("mage", "法师祝福"),
            shortLabel = "法师",
            default = "智慧祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "warlock",
            type = "string",
            control = "select",
            label = ColoredClassLabel("warlock", "术士祝福"),
            shortLabel = "术士",
            default = "智慧祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "hunter",
            type = "string",
            control = "select",
            label = ColoredClassLabel("hunter", "猎人祝福"),
            shortLabel = "猎人",
            default = "王者祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "hunterpet",
            type = "string",
            control = "select",
            label = ColoredClassLabel("hunter", "猎人宠物祝福"),
            shortLabel = "猎人宠",
            default = "跟随猎人",
            choices = PET_BLESSING_CHOICES,
        },
        {
            key = "rogue",
            type = "string",
            control = "select",
            label = ColoredClassLabel("rogue", "盗贼祝福"),
            shortLabel = "盗贼",
            default = "力量祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "druid",
            type = "string",
            control = "select",
            label = ColoredClassLabel("druid", "德鲁伊祝福"),
            shortLabel = "德鲁伊",
            default = "王者祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "shaman",
            type = "string",
            control = "select",
            label = ColoredClassLabel("shaman", "萨满祝福"),
            shortLabel = "萨满",
            default = "力量祝福",
            choices = BLESSING_CHOICES,
        },
        {
            key = "refreshMin",
            type = "string",
            label = "提前刷新(分钟)",
            shortLabel = "提前",
            default = "0",
        },
    },
}

local lastCastTime = 0
local pendingVerify = nil

-- 祝福实际时长（技能说明实证）：强效 30 分钟 / 普通及低级"小X"祝福 10 分钟（截图确认：力量祝福6级持续10分钟）
local function GetBlessingDuration(buffName)
    if string.find(buffName, "强效") then
        return 1800
    end
    return 600
end

-- 强效祝福材料：王者印记（Symbol of Kings，物品ID 21177，截图实证：强效力量祝福也消耗它）
-- 有材料 → 刷强效；无材料 → 降级刷普通祝福补（BUFF 不断），施放时聊天框显示剩余材料
-- 1.12 GetItemCount 名字/ID 语义不稳定（乌龟服实测传 ID 和中文名都可能返回 0）：
-- 改用背包扫描，按物品链接里的 ID 精确计数（GetContainerItemLink 提取 |Hitem:21177: 匹配）
local KINGS_SYMBOL_ID = 21177
local function CountItemById(itemId)
    local count = 0
    for bag = 0, 4 do
        local slots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
            if link then
                local _, _, idStr = string.find(link, "|Hitem:(%d+):")
                if idStr and tonumber(idStr) == itemId then
                    local _, c = GetContainerItemInfo(bag, slot)
                    count = count + (c or 1)
                end
            end
        end
    end
    return count
end
local function GetKingsSymbolCount()
    return CountItemById(KINGS_SYMBOL_ID)
end
local function HasKingsSymbols()
    return GetKingsSymbolCount() > 0
end

-- 施放技能名规范化：低级祝福配置名若带"小"前缀（如"小智慧祝福"），技能书里只有基础名"智慧祝福"
local function NormalizeCastName(buffName)
    return string.gsub(buffName or "", "^小", "")
end

-- 施放记录表：估算队友/宠物 BUFF 剩余时间（中文 1.12 tooltip 无剩余时间行）
-- 乌龟 1.12 祝福时长（技能说明实证）：普通祝福 10 分钟 / 强效祝福 30 分钟
-- 记录格式 castLog[unit..":"..buffName] = 到期绝对时间（time() 系统秒 + 时长）
-- 用绝对时间：RL/大退后经 SavedVariables 恢复，队友提前刷新 RL 后仍有效（RL 会清 GetTime 会话时钟，不能用施放时刻）
local castLog = {}
-- 从 SavedVariables 恢复（RL/大退后保留施放记录，队友提前刷新不失效）
if Cat2DualBoxing_State and Cat2DualBoxing_State.castLog then
    for k, v in pairs(Cat2DualBoxing_State.castLog) do
        castLog[k] = v
    end
end
-- 保存到全局表（WoW 在 RL/退出时自动落盘 SavedVariables；写入内存表无 IO 开销）
local function SaveCastLog()
    if not Cat2DualBoxing_State then
        Cat2DualBoxing_State = {}
    end
    Cat2DualBoxing_State.castLog = castLog
end
-- 单单位失败冷却：验证失败的单位 10 秒内跳过（防无效重试刷屏；其他单位不受影响）
local failedUnits = {}
-- 跨帧确认：tooltip 文本下一帧才刷新，同帧重试无效。判缺先记录，下一轮再读确认才施放（防读名偶发失败误判）
local pendingLack = {}

-- 旧版Lua没有string.match；此文件只需返回string.find捕获的内容。
local function MatchText(text, pattern)
    local _, _, first, second = string.find(text, pattern)
    return first, second
end

function card.RefreshRuntimeData()
end

-- 收集目标单位列表：团队模式扫描全团(raid1..N)，否则扫描小队(player+party1..N)
-- 自己优先（用户要求先刷自己），再宠物/队友
local function GetBuffTargets()
    local units = {}
    tinsert(units, "player")
    if UnitExists("pet") then
        tinsert(units, "pet")
    end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            tinsert(units, "raid" .. i)
            local pet = "raid" .. i .. "pet"
            if UnitExists(pet) then
                tinsert(units, pet)
            end
        end
    else
        for i = 1, GetNumPartyMembers() do
            tinsert(units, "party" .. i)
            local pet = "party" .. i .. "pet"
            if UnitExists(pet) then
                tinsert(units, pet)
            end
        end
    end
    return units
end

-- 隐藏 tooltip 读 BUFF 显示名（UnitBuff 返回的是图标纹理，不是名字，直接比较永远失败）
-- 必须 SetOwner：无 owner 的 tooltip 在部分客户端 SetUnitBuff 后不刷新文本，读不到名字
-- 对齐 CAT2 本体机制（GetBuffNameByIndex）：每次 SetUnitBuff 前重新 SetOwner(UIParent)
-- 修复"owner 被其他插件抢占后 SetUnitBuff 不刷新→读空→判没有→不停刷自己"
local SlotNameTooltip = CreateFrame("GameTooltip", "Cat2BlessNameTooltip", UIParent, "GameTooltipTemplate")
local function GetBuffNameAtSlot(unit, i)
    for attempt = 1, 3 do
        SlotNameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        SlotNameTooltip:ClearLines()
        SlotNameTooltip:SetUnitBuff(unit, i)
        local t = _G["Cat2BlessNameTooltipTextLeft1"]
        local name = t and t:GetText()
        if name and name ~= "" then
            return name
        end
    end
    return nil
end

-- BUFF 名归一化：低级祝福 BUFF 显示"小智慧祝福"等（带"小"前缀），配置/技能名是基础名"智慧祝福"
-- 同时剥离等级后缀（乌龟服 BUFF 可能显示"力量祝福（等级6）"/"(Rank 6)"）
local function NormalizeBuffName(name)
    local s = string.gsub(name or "", "^小", "")
    s = string.gsub(s, "%s*[（(]等级%s*[0-9]+[）)]%s*$", "")
    s = string.gsub(s, "%s*%(Rank%s*[0-9]+%)%s*$", "")
    return s
end

-- 自写 BUFF 检测：遍历单位 BUFF 槽位，返回命中槽位（tooltip 读名，归一化后匹配"小X"变体）
local function FindBuffSlot(buffName, unit)
    local target = NormalizeBuffName(buffName)
    local i = 1
    while UnitBuff(unit, i) do
        local name = GetBuffNameAtSlot(unit, i)
        if name and NormalizeBuffName(name) == target then
            return i
        end
        i = i + 1
    end
    return nil
end

-- 时间文本解析（兼容"4分59秒"/"4 分钟 59 秒"/"1 小时 4 分 59 秒"/"4:59"/"4 min 59 sec"）
local function ParseTimeText(txt)
    if not txt or txt == "" then
        return nil
    end
    local h = tonumber((MatchText(txt, "(%d+)[%s]*小时"))) or 0
    local m = tonumber((MatchText(txt, "(%d+)[%s]*分")))
    local s = tonumber((MatchText(txt, "(%d+)[%s]*秒")))
    if m or s then
        return h * 3600 + (m or 0) * 60 + (s or 0)
    end
    local mm, ss = MatchText(txt, "(%d+):(%d+)")
    if mm then
        return tonumber(mm) * 60 + tonumber(ss)
    end
    local em = tonumber((MatchText(txt, "(%d+)[%s]*min")))
    local es = tonumber((MatchText(txt, "(%d+)[%s]*sec")))
    if em or es then
        return (em or 0) * 60 + (es or 0)
    end
    return nil
end

-- BUFF 剩余时间读取（1.12 无 API，用隐藏 tooltip 解析"剩余 X分Y秒"）
-- 返回秒数；解析不到返回 nil（调用方按"有效、不刷"保守处理）
local BuffTooltip = CreateFrame("GameTooltip", "Cat2BlessBuffTooltip", UIParent, "GameTooltipTemplate")
BuffTooltip:SetOwner(UIParent, "ANCHOR_NONE")
local function GetBuffTimeLeft(unit, slot, buffName)
    -- player 自己：GetPlayerBuffTimeLeft 返回单位有版本差异（乌龟服有的返回毫秒、有的返回秒）
    -- 自适应：>60000 视为毫秒（÷1000），否则视为秒（直接用）；<5 秒视为异常不采信，防单位误判导致不停刷
    if unit == "player" then
        -- 纹理匹配定位真实索引：1.12 的 GetPlayerBuff 索引排序与 UnitBuff 槽位不一致（著名坑，实测 UnitBuff 槽1=力量祝福但 GetPlayerBuffTimeLeft(0) 读到别的 BUFF 的 424 秒）
        -- 用同一个 BUFF 的图标纹理做桥梁：遍历 GetPlayerBuff 找纹理一致的槽，读其时间
        local dur = GetBlessingDuration(buffName)
        local tex = UnitBuff and UnitBuff("player", slot)
        local foundIdx = nil
        if tex then
            local texLow = string.lower(tex)
            for idx = 0, 31 do
                local ptex = GetPlayerBuff and GetPlayerBuff(idx)
                -- 忽略大小写：RL 后客户端缓存返回的纹理路径大小写可能与 UnitBuff 不一致（v89 实证匹配失败）
                if ptex and string.lower(ptex) == texLow then
                    foundIdx = idx
                    break
                end
            end
        end
        if foundIdx then
            local ok2, tl = pcall(GetPlayerBuffTimeLeft, foundIdx)
            if ok2 and tl and tl > 0 then
                if tl > 60000 then
                    tl = tl / 1000
                end
                if tl >= 5 and tl <= dur + 60 then
                    return tl
                end
            end
        end
        -- 回退：castLog 估算（到期绝对时间 - 当前系统时间）
        if buffName then
            local expire = castLog[unit .. ":" .. buffName]
            if expire then
                local remain = expire - time()
                if remain > 0 then
                    return remain
                end
                castLog[unit .. ":" .. buffName] = nil
                SaveCastLog()
            end
        end
        return nil
    end
    -- 队友/宠物：用"施放记录到期时间"估算剩余（中文 1.12 tooltip 无剩余时间行，这是唯一可用通道）
    if buffName then
        local expire = castLog[unit .. ":" .. buffName]
        if expire then
            local remain = expire - time()
            if remain > 0 then
                return remain
            end
            castLog[unit .. ":" .. buffName] = nil
            SaveCastLog()
        end
    end
    if not BuffTooltip then
        return nil
    end
    pcall(function()
        BuffTooltip:ClearLines()
        BuffTooltip:SetUnitBuff(unit, slot)
    end)
    -- 遍历 tooltip 全部文本行（剩余时间可能在第3+行，不只 Left2）
    local txt = ""
    for i = 1, 8 do
        local lv = _G["Cat2BlessBuffTooltipTextLeft" .. i]
        local rv = _G["Cat2BlessBuffTooltipTextRight" .. i]
        local lt = lv and lv:GetText() or ""
        local rt = rv and rv:GetText() or ""
        if lt ~= "" then txt = txt .. " " .. lt end
        if rt ~= "" then txt = txt .. " " .. rt end
    end
    local tl = ParseTimeText(txt)
    if tl then
        return tl
    end
    return nil
end

-- 祝福名匹配：兼容普通祝福的小祝福变体命名（如"力量祝福"施放后可能显示"小力量祝福"）
-- 关键：强效祝福施放后 BUFF 名不带"强效"（如"强效王者祝福"施放后 BUFF 显示"王者祝福"），必须用基础名匹配
-- 普通祝福配置：身上已有"强效"版视为已有（避免普通祝福顶掉强效祝福）
-- 返回槽位：>0=命中槽位（可取剩余时间）；-1=Cat2.Buff 兜底确认存在但无槽位；nil=不存在
local function FindBlessingSlot(buffName, unit)
    -- 直接名匹配：强效配置命中"强效X"、普通配置命中"X"（用户实测：强效 BUFF 显示"强效X"，带前缀，与普通名可区分）
    local slot = FindBuffSlot(buffName, unit)
    if slot then
        return slot
    end
    -- 配置强效（大祝福）：只认"强效X"为已有。
    -- 身上只有普通"X"或低级"小X" → 不算已有（判缺 → 刷大祝福顶掉升级）
    if string.find(buffName, "强效") then
        -- 材料不足时：目标已有小祝福"X"视为已有（保持小，不升级）；无 → 判缺（施放处降级刷小补）
        if not HasKingsSymbols() then
            local smallName = string.gsub(buffName, "^强效", "")
            slot = FindBuffSlot(smallName, unit)
            if slot then
                return slot
            end
            if Cat2.Buff then
                local okS, hasS = pcall(Cat2.Buff, smallName, unit)
                if okS and hasS then return -1 end
            end
        end
        if Cat2.Buff then
            local ok, has = pcall(Cat2.Buff, buffName, unit)
            if ok and has then return -1 end
        end
        return nil
    end
    -- 配置普通（小祝福）：低级普通 BUFF 显示"小X"
    slot = FindBuffSlot("小" .. buffName, unit)
    if slot then
        return slot
    end
    -- 目标已有强效"强效X"（高级祝福）→ 普通不顶，视为已有
    slot = FindBuffSlot("强效" .. buffName, unit)
    if slot then
        return slot
    end
    -- Cat2.Buff 兜底（同规则）：只确认存在，无槽位（-1）
    if Cat2.Buff then
        local ok1, has1 = pcall(Cat2.Buff, buffName, unit)
        if ok1 and has1 then return -1 end
        local ok2, has2 = pcall(Cat2.Buff, "小" .. buffName, unit)
        if ok2 and has2 then return -1 end
        local ok3, has3 = pcall(Cat2.Buff, "强效" .. buffName, unit)
        if ok3 and has3 then return -1 end
    end
    return nil
end

-- 需要刷新？(不存在=补；refreshMin>0 且剩余时间<阈值=补；解析不到时间=保守不刷)
-- 阈值钳制：不能超过 BUFF 时长-60 秒（普通祝福 10 分钟→上限 9 分；强效 30 分钟→上限 29 分）
-- 防止阈值填得比 BUFF 时长还大导致"刷完仍判定需刷"的无限续杯
local function NeedRefresh(buffName, unit, refreshMin)
    local slot = FindBlessingSlot(buffName, unit)
    if not slot then
        -- 纯检测驱动：检测不到=没有/被顶掉 → 立即补（顶掉立即恢复，不设任何冷却/防线）
        local dur = GetBlessingDuration(buffName)
        local expire = castLog[unit .. ":" .. buffName]
        local smallName = string.gsub(buffName, "^强效", "")
        if not expire and smallName ~= buffName then
            local smallExpire = castLog[unit .. ":" .. smallName]
            if smallExpire then
                expire = smallExpire
                dur = GetBlessingDuration(smallName)
            end
        end
        -- 读名失败防线：单位有BUFF（纹理在）但第一个BUFF名读不到 → tooltip 间歇失败 → castLog 未到期则不刷
        -- 根治"降级刷小后验证成功、但下轮读名失败→判缺→又刷"的循环（3秒缓冲只暂缓，读名持续失败仍会循环）
        -- 单位读名正常（能读到其他BUFF名）→ 目标祝福真不在（被顶/没刷）→ 正常补（顶掉立即恢复）
        local anyBuff = UnitBuff and UnitBuff(unit, 1)
        if anyBuff then
            local nameReadOK = GetBuffNameAtSlot(unit, 1) ~= nil
            if not nameReadOK then
                if expire and expire - time() > 0 then
                    return false
                end
                -- 记录已到期：防线失效，清记录放行补刷
                if expire then
                    castLog[unit .. ":" .. buffName] = nil
                    if smallName ~= buffName then
                        castLog[unit .. ":" .. smallName] = nil
                    end
                    SaveCastLog()
                end
            end
        end
        -- 3 秒缓冲：刚刷过 3 秒内不重刷（防"验证成功但下轮判缺→不停刷"的短窗口）
        if expire and expire - time() > dur - 3 then
            return false
        end
        return true
    end
    if slot == -1 then
        return false
    end
    if refreshMin and refreshMin > 0 then
        local dur = GetBlessingDuration(buffName)
        if refreshMin * 60 > dur - 60 then
            refreshMin = (dur - 60) / 60
        end
        local timeLeft = GetBuffTimeLeft(unit, slot, buffName)
        if timeLeft and timeLeft < refreshMin * 60 then
            return true
        end
    end
    return false
end

-- 自写施放：瞬发祝福绕过 Cat2.Cast 的"读条/引导跳过"和"目标不可见跳过"两道检查。
-- 祝福是瞬发、不断读条、30码内可对任意队友施放；目标在屏幕外也照放。
-- 施放包 pcall、恢复目标无条件执行：即使 CastSpellByName 抛错也不残留队友目标
-- 恢复目标必须用名字（1.12 TargetUnit 不接受 GUID，用 GUID 恢复会静默失败→残留队友目标→手动施放错目标）
local function CastBlessing(spellName, unit)
    spellName = NormalizeCastName(spellName)
    if Cat2.SuperWoW then
        pcall(CastSpellByName, spellName, unit)
        return true
    end
    local hadTarget = UnitExists("target")
    local oldTargetName = hadTarget and UnitName("target") or nil
    local switched = false
    if unit ~= "target" then
        TargetUnit(unit)
        switched = true
    end
    -- 目标切换校验：切换后目标 GUID 必须与目标单位一致才施放
    -- （TargetUnit 对下线/无效单位会静默失败并残留原目标，直接施放会刷错目标=给本体刷大祝福）
    if switched then
        local targetOK = UnitExists("target") and UnitGUID("target") == UnitGUID(unit)
        if not targetOK then
            if hadTarget and oldTargetName then
                TargetUnit(oldTargetName)
            end
            return false
        end
    end
    pcall(CastSpellByName, spellName)
    -- 恢复原目标（无论施放是否抛错）；用名字恢复（1.12 兼容）
    if switched then
        if hadTarget and oldTargetName then
            TargetUnit(oldTargetName)
        else
            ClearTarget()
        end
    end
    return true
end

-- 职业 → 祝福参数键 映射
-- UnitClass 在 1.12 返回大写英文（如 PALADIN/HUNTER），键必须全大写；匹配处再做 upper 兜底
local CLASS_PARAM = {
    WARRIOR = "warrior",
    PALADIN = "paladin",
    PRIEST = "priest",
    MAGE = "mage",
    WARLOCK = "warlock",
    HUNTER = "hunter",
    ROGUE = "rogue",
    DRUID = "druid",
    SHAMAN = "shaman",
}

-- 职业 → 祝福参数键 解析（兼容 UnitClass 返回值顺序差异：c1/c2 任一匹配到即用）
-- 修复：CAT2 更新后 UnitClass 返回值可能变化导致职业误判（如不在线单位/宠物返回异常职业 → 乱刷祝福）
local function ResolveClassParamKey(unit)
    local c1, c2 = UnitClass(unit)
    local key = CLASS_PARAM[string.upper(c1 or "")]
    if not key and c2 then
        key = CLASS_PARAM[string.upper(c2 or "")]
    end
    return key
end

-- 单位参数键解析：宠物单位转主人（party1pet→party1，pet→player）
-- 猎人宠物用独立键 hunterpet（可单独配置/跟随猎人），其余宠物按主人职业配置
local function ResolveParamKeyForUnit(unit)
    if unit == "pet" then
        return ResolveClassParamKey("player")
    end
    local ownerUnit = string.gsub(unit, "pet$", "")
    if ownerUnit ~= unit and UnitExists(ownerUnit) then
        local ownerKey = ResolveClassParamKey(ownerUnit)
        if ownerKey == "hunter" then
            return "hunterpet"
        end
        return ownerKey
    end
    return ResolveClassParamKey(unit)
end

-- 施放前距离检查：普通祝福 30 码、强效祝福 40 码（已核实技能说明；超距离直接跳过，省掉无效施放尝试）
-- 优先游戏原生 IsSpellInRange：1=在范围可施放；0/nil 都不可尽信（IsSpellInRange 对 raid 单位/中文法术名可能误判）→ 回退 UnitXP 距离
-- UnitXP 距离可靠（实测返回真实码数）；UnitXP 也失效才放行施放（靠施放后验证兜底，真失败走单单位 10 秒冷却）
local function IsInRange(unit, spellName)
    -- 自己 0 码必然可施放（IsSpellInRange 对 player 也可能返回 nil，放行保证自己正常刷）
    if unit == "player" then
        return true
    end
    if IsSpellInRange then
        local ok, result = pcall(IsSpellInRange, spellName, unit)
        if ok and result == 1 then
            return true
        end
        -- 0=超距离 / nil=不可判断：都回退 UnitXP（不信 0，防 30 码内队友被误判跳过）
    end
    local range = 30
    if string.find(spellName or "", "强效") then
        range = 40
    end
    if Cat2.UnitXP and type(UnitXP) == "function" then
        local ok2, distance = pcall(UnitXP, "distanceBetween", "player", unit)
        if ok2 and distance and distance > 0 then
            return distance <= range
        end
    end
    return true
end

-- 解析"提前刷新"值（数字直接返回；"5分钟"/"5"字符串取数字；解析失败=0）
local function ParseRefreshMin(v)
    if type(v) == "number" then
        return v
    end
    if type(v) ~= "string" then
        return 0
    end
    local m = MatchText(v, "(%d+)")
    return tonumber(m) or 0
end

-- 普通卡：按流程位置执行，发出施放请求后结束本轮。
-- 正式版：静默运行，仅材料提示有聊天输出。自己优先（先补自己再队友/宠物，用户要求）；超距离跳过；施放后验证，未生效拉长冷却防无效刷。
function card.Execute(context, step)
    local now = GetTime()

    -- 延迟验证：施放 0.8 秒后验证是否生效（瞬发祝福生效有网络延迟，立即验证易误判失败）
    -- 已核实技能说明：祝福法术无技能CD，冷却按 GCD 1.5 秒（成功）/ 2.5 秒短惩罚（失败）
    -- 正式版：静默运行
    if pendingVerify then
        if now - pendingVerify.castTime < 1.2 then
            return false
        end
        local vName = pendingVerify.blessingName
        local vUnit = pendingVerify.unit
        local ok = FindBlessingSlot(vName, vUnit) ~= nil
        pendingVerify = nil
        if not ok then
            -- 验证失败：该单位 10 秒内跳过（防无效重试刷屏；其他单位不受影响）
            -- 自身：保留施放记录当防线（刚刷过不重补，防误判循环）
            -- 队友：删除施放记录（真失败要重试，否则估算残留 10 分钟不再补=队友永远不刷）
            failedUnits[vUnit] = now + 10
            if vUnit ~= "player" then
                castLog[vUnit .. ":" .. vName] = nil
                SaveCastLog()
            end
            lastCastTime = now
            return false
        end
        -- 验证成功：清除该单位失败冷却，不重置 GCD 起点（GCD 从施放时刻算），继续走 GCD 检查
        failedUnits[vUnit] = nil
    end

    if now - lastCastTime < 1.5 then
        return false
    end

    -- 遍历目标单位：按职业查祝福配置（团队=全团，小队=全队；player 已由 GetBuffTargets 排首位=先刷自己）
    local units = GetBuffTargets()
    local refreshMin = ParseRefreshMin(context:GetStepOption(step, "refreshMin"))

    for _, unit in ipairs(units) do
        -- UnitIsConnected：过滤下线/占位单位（下线队友 UnitClass 会返回缓存职业导致误判，且施放无效）
        -- failedUnits：该单位近期验证失败过 → 跳过（10 秒后自动恢复）
        -- 注意：不按阵营跳过（乌龟服团队跨阵营可增益，交给游戏判定；失败走单单位冷却）
        if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
            and not (failedUnits[unit] and failedUnits[unit] > now) then
            local paramKey = ResolveParamKeyForUnit(unit)
            local blessingName = nil
            if paramKey then
                blessingName = context:GetStepOption(step, paramKey)
                -- 猎人宠物"跟随猎人"：直接用猎人配置
                if paramKey == "hunterpet" and (blessingName == "跟随猎人" or blessingName == nil or blessingName == "") then
                    blessingName = context:GetStepOption(step, "hunter")
                end
            end
            if type(blessingName) == "string" and blessingName ~= "" then
                if NeedRefresh(blessingName, unit, refreshMin) then
                    -- 跨帧确认：tooltip 下一帧才刷新，首次判缺只记录不施放，下一轮再读仍缺才施放
                    local pk = unit .. ":" .. blessingName
                    if not pendingLack[pk] then
                        pendingLack[pk] = now
                    else
                        pendingLack[pk] = nil
                        if IsInRange(unit, blessingName) then
                        -- 强效祝福需王者印记材料：有材料 → 刷强效并显示剩余；无材料 → 降级刷普通祝福补（BUFF 不断）
                        if string.find(blessingName, "^强效") then
                            local hasSym = HasKingsSymbols()
                            if hasSym then
                                -- 显示"刷后"数量：本次施放会消耗 1 个印记，直接显示 N-1（用户要求：读取的是刷前数量，刷后要减一个）
                                -- 三档颜色：>20 浅黄(1,0.8,0)=充足；≤20 橙红(1,0.4,0)=快没了；0 红(1,0,0)=没有
                                local remainCount = GetKingsSymbolCount() - 1
                                local msgR, msgG, msgB = 1, 0.4, 0
                                if remainCount > 20 then
                                    msgR, msgG, msgB = 1, 0.8, 0
                                end
                                DEFAULT_CHAT_FRAME:AddMessage(format("[祝福] %s 需王者印记，剩余 %d 个", blessingName, remainCount), msgR, msgG, msgB)
                            else
                                blessingName = string.gsub(blessingName, "^强效", "")
                                -- 没有材料：红色(1,0,0)；10 秒节流防刷屏（材料不足会持续判缺，满屏红没意义）
                                local nowS = GetTime()
                                local lastS = _G.CAT2_DBG_SYM_LOW or 0
                                if nowS - lastS > 10 then
                                    _G.CAT2_DBG_SYM_LOW = nowS
                                    DEFAULT_CHAT_FRAME:AddMessage("[祝福] 王者印记不足，改用" .. blessingName, 1, 0, 0)
                                end
                            end
                        end
                        local castOK = CastBlessing(blessingName, unit)
                        -- 目标切换校验通过才挂延迟验证（切换失败=目标无效，惩罚 6 秒后再试，防疯狂重试）
                        if castOK then
                            lastCastTime = now
                            -- 记录到期绝对时间（施放时刻+理论时长），RL 后经 SavedVariables 恢复，队友提前刷新不失效
                            castLog[unit .. ":" .. blessingName] = time() + GetBlessingDuration(blessingName)
                            SaveCastLog()
                            pendingVerify = { blessingName = blessingName, unit = unit, castTime = now }
                        else
                            lastCastTime = now + 6
                        end
                        return castOK == true
                    end
                    end
                end
            end
        end
    end
    return false
end

Cat2.RegisterCard(card)
