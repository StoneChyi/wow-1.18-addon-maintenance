-- ============================================================
-- 文件名: GoubayuHeal_C.lua
-- 功能: 治疗法术监控插件（纯 Nampower 实现）
--       包含 CastingSpeed 模块（跟踪其他治疗者的施法）、
--       单位ID查询、增益/减益数据管理、玩家数据刷新、
--       治疗强度计算等核心工具函数
-- ============================================================

GoubayuHeal = GoubayuHeal or {}

-- ============================================================
-- CastingSpeed 模块：监控其他治疗者施法
-- ============================================================

local CastingSpeed = {}

-- 存储施法信息：castData[目标GUID][施法者GUID] = { spellID, castTime, startTime, endTime }
CastingSpeed.castData = {}

-- 他人复活读条跟踪：rezData[被复活玩家GUID] = { caster=施法者GUID, endTime=预计完成时间 }
-- 供 GetOtherRezing 判定"别人正在复活该目标"，避免宏重复复活同一人（一键复活竞速避让）
-- by 武藤纯子酱 2026.9.4
CastingSpeed.rezData = {}

-- ============================================================
-- 初始化
-- ============================================================

function CastingSpeed:Init()
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        CastingSpeed:DoInit()
        this:UnregisterEvent("PLAYER_LOGIN")
    end)
end

function CastingSpeed:DoInit()
    if not GetNampowerVersion then
        return
    end
    self.nampower = true
    self:BuildHealSpellSet()
    self:RegisterEvents()

    -- 进出地图时重置玩家GUID缓存与施法记录
    local worldFrame = CreateFrame("Frame")
    worldFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    worldFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    worldFrame:SetScript("OnEvent", function()
        CastingSpeed.playerGUID = nil
        CastingSpeed.castData = {}
        CastingSpeed.rezData = {}
    end)

    -- 定期轮询自己当前施法的实时信息（每0.3秒）：
    -- 施法期间的加速/减速变化（加速药水/饰品/增益）实时更新到实测施法时间缓存与在读条记录，
    -- 不依赖施法瞬间的事件快照，竞争比较永远用最新值
    local pollFrame = CreateFrame("Frame")
    local pollElapsed = 0
    pollFrame:SetScript("OnUpdate", function()
        pollElapsed = pollElapsed + (arg1 or 0)
        if pollElapsed < 0.3 then
            return
        end
        pollElapsed = 0
        CastingSpeed:PollSelfCastInfo()
    end)
end

-- ============================================================
-- 注册 Nampower 事件
-- ============================================================

function CastingSpeed:RegisterEvents()
    local frame = CreateFrame("Frame")
    SetCVar("NP_EnableSpellStartEvents", "1")
    SetCVar("NP_EnableSpellGoEvents", "1")

    frame:RegisterEvent("SPELL_START_OTHER")
    frame:RegisterEvent("SPELL_START_SELF")
    frame:RegisterEvent("SPELL_GO_OTHER")
    frame:RegisterEvent("SPELL_GO_SELF")
    frame:RegisterEvent("SPELL_FAILED_OTHER")
    frame:RegisterEvent("SPELL_FAILED_SELF")
    -- 施法延时（推条/实时施法时间变化）：服务端只发给被影响的玩家本人，
    -- 实际只会收到 SELF；OTHER 一并注册（文档保留，当前不会触发）
    frame:RegisterEvent("SPELL_DELAYED_SELF")
    frame:RegisterEvent("SPELL_DELAYED_OTHER")

    frame:SetScript("OnEvent", function()
        if event == "SPELL_START_OTHER" or event == "SPELL_START_SELF" then
            CastingSpeed:OnSpellStart(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        elseif event == "SPELL_GO_OTHER" or event == "SPELL_GO_SELF" then
            CastingSpeed:OnSpellGo(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
        elseif event == "SPELL_FAILED_OTHER" then
            CastingSpeed:OnSpellFailed(arg1, arg2)
        elseif event == "SPELL_FAILED_SELF" then
            CastingSpeed:OnSpellFailed(CastingSpeed:GetPlayerGUID(), arg1)
        elseif event == "SPELL_DELAYED_SELF" or event == "SPELL_DELAYED_OTHER" then
            CastingSpeed:OnSpellDelayed(arg1, arg2)
        end
    end)
end

-- ============================================================
-- 事件处理：记录/清除施法信息
-- ============================================================

-- SPELL_START：记录施法
function CastingSpeed:OnSpellStart(itemId, spellId, casterGuid, targetGuid, castFlags, castTime,
    duration, spellType, corpseOwnerGuid)
    -- 复活读条跟踪：复活类法术不在治疗库（IsHealSpellId 恒假），单独记录；
    -- 注意放在治疗库守卫之前（尸体目标的 UnitIsFriend 不可靠）
    if CastingSpeed:IsRezSpellId(spellId) then
        CastingSpeed:AddRezCastInfo(casterGuid, targetGuid, corpseOwnerGuid, castTime)
        return
    end
    if not castTime or castTime <= 0 then
        return
    end
    if not (targetGuid and targetGuid ~= "0x0000000000000000") then
        return
    end
    if not UnitIsFriend("player", targetGuid) then
        return
    end
    -- 只认插件治疗库中的法术参与竞争判定（复活/激活/增益等其他读条法术的
    -- 治疗库键若存在也会计入——复活读条10秒同样占用治疗者，属预期行为）
    if not CastingSpeed:IsHealSpellId(spellId) then
        return
    end
    CastingSpeed:AddCastInfo(casterGuid, targetGuid, spellId, castTime)
end

-- ============================================================
-- 治疗法术库识别
-- ============================================================

-- 构建治疗库名单：以主模块 heal_spells_text（法术库/方案的权威名单，含全职业技能）的键为准
function CastingSpeed:BuildHealSpellSet()
    local set = {}
    if GoubayuHeal and GoubayuHeal.heal_spells_text then
        for spellName, _ in pairs(GoubayuHeal.heal_spells_text) do
            if type(spellName) == "string" then
                set[spellName] = true
            end
        end
    end
    self.healSpellNames = set
    self.spellIdCache = {}
end

-- 判定法术 ID 是否属于治疗库：spellId 反查法术名（去等级后缀）后比对名单，结果会话内缓存
function CastingSpeed:IsHealSpellId(spellId)
    if not spellId or spellId == 0 then
        return false
    end
    -- 懒构建：C.lua 加载早于主文件，heal_spells_text 需等主文件就绪
    if not self.healSpellNames then
        self:BuildHealSpellSet()
    end
    if not self.healSpellNames or not GetSpellNameAndRankForId then
        return false
    end

    self.spellIdCache = self.spellIdCache or {}
    local cached = self.spellIdCache[spellId]
    if cached ~= nil then
        return cached
    end

    local isHeal = false
    local ok, name = pcall(GetSpellNameAndRankForId, spellId)
    if ok and name and name ~= "" then
        -- 去掉等级后缀（如 "快速治疗(等级 7)"）
        local cleanName = string.gsub(name, "%s*%(.*%)", "")
        isHeal = self.healSpellNames[cleanName] and true or false
    end
    self.spellIdCache[spellId] = isHeal
    return isHeal
end

-- ============================================================
-- 他人复活读条跟踪（一键复活竞速避让）
-- ============================================================

-- 判定法术 ID 是否为复活类法术（先祖之魂/复活术/救赎/重生）：spellId 反查法术名后
-- 比对主模块 rez_spells 名单，结果会话内缓存。C.lua 加载早于主文件，rez_spells 懒比对
function CastingSpeed:IsRezSpellId(spellId)
    if not spellId or spellId == 0 then
        return false
    end
    if not (GoubayuHeal and GoubayuHeal.rez_spells) or not GetSpellNameAndRankForId then
        return false
    end

    self.rezSpellIdCache = self.rezSpellIdCache or {}
    local cached = self.rezSpellIdCache[spellId]
    if cached ~= nil then
        return cached
    end

    local isRez = false
    local ok, name = pcall(GetSpellNameAndRankForId, spellId)
    if ok and name and name ~= "" then
        -- 去掉等级后缀（如 "先祖之魂(等级 5)"）
        local cleanName = string.gsub(name, "%s*%(.*%)", "")
        isRez = (GoubayuHeal.rez_spells[cleanName] and true) or false
    end
    self.rezSpellIdCache[spellId] = isRez
    return isRez
end

-- 记录复活读条（castTime 毫秒）。复活包 targetGuid 是尸体 GUID，corpseOwnerGuid 才是
-- 被复活玩家的 GUID（查询按玩家 GUID 命中），两个键都建双向冗余；瞬发重生（重生
-- castTime=0）不会触发 SPELL_START，无读条窗口，无需也无法竞争避让
function CastingSpeed:AddRezCastInfo(casterGuid, targetGuid, corpseOwnerGuid, castTime)
    if not casterGuid or not castTime or castTime <= 0 then
        return
    end
    local endTime = GetTime() + castTime / 1000
    if corpseOwnerGuid and corpseOwnerGuid ~= "0x0000000000000000" then
        CastingSpeed.rezData[corpseOwnerGuid] = { caster = casterGuid, endTime = endTime }
    end
    if targetGuid and targetGuid ~= "0x0000000000000000" and targetGuid ~= corpseOwnerGuid then
        CastingSpeed.rezData[targetGuid] = { caster = casterGuid, endTime = endTime }
    end
end

-- 清除复活读条跟踪（按尸体 GUID/玩家 GUID 任一键匹配）
function CastingSpeed:RemoveRezCastInfo(targetGuid, corpseOwnerGuid)
    if targetGuid and targetGuid ~= "0x0000000000000000" then
        CastingSpeed.rezData[targetGuid] = nil
    end
    if corpseOwnerGuid and corpseOwnerGuid ~= "0x0000000000000000"
        and corpseOwnerGuid ~= targetGuid then
        CastingSpeed.rezData[corpseOwnerGuid] = nil
    end
end

-- 查询目标是否正被其他玩家复活读条中；targetGUID 为被复活玩家的 GUID
-- （DoRez 候选以单位 ID 传入，主模块 GetOtherRezing 负责转 GUID）
function CastingSpeed:IsOtherRezing(targetGUID)
    if not targetGUID or not CastingSpeed.rezData then
        return
    end
    local info = CastingSpeed.rezData[targetGUID]
    if not info then
        return
    end
    -- 自己的读条不算"别人在复活"（避免自我拦截）
    if info.caster == CastingSpeed:GetPlayerGUID() then
        return
    end
    -- 兜底过期：未收到 GO/FAILED（施法者死亡/离线/事件丢失）也能自然失效；
    -- 1.5 秒宽限覆盖对方被推条时我方收不到 SPELL_DELAYED_OTHER 的偏差
    if GetTime() > info.endTime + 1.5 then
        CastingSpeed.rezData[targetGUID] = nil
        return
    end
    return 1
end

-- SPELL_GO：施法完成，清除记录
function CastingSpeed:OnSpellGo(itemId, spellId, casterGuid, targetGuid,
    castFlags, numTargetsHit, numTargetsMissed, corpseOwnerGuid)
    -- 复活读条落地（成功复活）→ 清除跟踪
    if CastingSpeed:IsRezSpellId(spellId) then
        CastingSpeed:RemoveRezCastInfo(targetGuid, corpseOwnerGuid)
        return
    end
    if not (targetGuid and CastingSpeed.castData and CastingSpeed.castData[targetGuid]) then
        return
    end
    CastingSpeed.castData[targetGuid][casterGuid] = nil
    if next(CastingSpeed.castData[targetGuid]) == nil then
        CastingSpeed.castData[targetGuid] = nil
    end
end

-- SPELL_FAILED：施法失败/打断，清除记录
function CastingSpeed:OnSpellFailed(casterGuid, spellId)
    -- 复活读条失败/打断 → 清除该施法者的所有复活跟踪
    if casterGuid and CastingSpeed.rezData then
        for guid, info in pairs(CastingSpeed.rezData) do
            if info and info.caster == casterGuid then
                CastingSpeed.rezData[guid] = nil
            end
        end
    end
    if not (casterGuid and CastingSpeed.castData) then
        return
    end
    for targetGUID, casters in pairs(CastingSpeed.castData) do
        if casters[casterGuid] then
            casters[casterGuid] = nil
            if next(casters) == nil then
                CastingSpeed.castData[targetGUID] = nil
            end
        end
    end
end

-- SPELL_DELAYED：施法被延时（受击推条等实时变化）→ 实时修正记录的施法时间/完成时间
-- 注意：服务端只把延时包发给被影响的玩家本人，实际只会收到 SELF（自己的施法被推条）
function CastingSpeed:OnSpellDelayed(casterGuid, delayMs)
    if not casterGuid or not delayMs or delayMs == 0 or not CastingSpeed.castData then
        return
    end
    for targetGUID, casters in pairs(CastingSpeed.castData) do
        local info = casters[casterGuid]
        if info then
            info.castTime = info.castTime + delayMs
            info.endTime = info.endTime + delayMs / 1000
        end
    end
end

-- 定期轮询自己当前施法的实时信息（每0.3秒，DoInit 内注册）：
-- 1) 实时同步在读条记录的完成时间（castEndS，Nampower 权威值，含推条/施法时间实时变化）
-- 2) 实时更新自己治疗技能的实测施法时间缓存（castDurationMs，反映当前加速/减速状态）——
--    即使本轮没触发治疗决策，缓存也持续保持最新
function CastingSpeed:PollSelfCastInfo()
    if not GetCastInfo then
        return
    end
    local ok, info = pcall(GetCastInfo)
    if not ok or not info or not info.castEndS or not info.guid then
        return
    end

    local playerGUID = self:GetPlayerGUID()
    if not playerGUID then
        return
    end

    -- 1) 同步在读条记录（仅当该目标上存在自己的施法记录时）
    local targetCasters = CastingSpeed.castData[info.guid]
    if targetCasters and targetCasters[playerGUID] then
        targetCasters[playerGUID].endTime = info.castEndS
    end

    -- 2) 更新治疗技能的实测施法时间（治疗库内的法术才记录）
    if info.spellId and info.castDurationMs and info.castDurationMs > 0
        and self:IsHealSpellId(info.spellId) then
        self.selfObservedCastMs = self.selfObservedCastMs or {}
        self.selfObservedCastMs[info.spellId] = info.castDurationMs
    end
end

-- 决策瞬间同步自己在读条记录的完成时间（与0.3秒轮询互补，保证比较时零延迟）
function CastingSpeed:SyncSelfCastInfo()
    if not GetCastInfo then
        return
    end
    local ok, info = pcall(GetCastInfo)
    if not ok or not info or not info.castEndS or not info.guid then
        return
    end
    local playerGUID = self:GetPlayerGUID()
    if not playerGUID then
        return
    end
    local targetCasters = CastingSpeed.castData[info.guid]
    if targetCasters and targetCasters[playerGUID] then
        targetCasters[playerGUID].endTime = info.castEndS
    end
end

-- 获取玩家GUID（缓存，会话内不变）
function CastingSpeed:GetPlayerGUID()
    if CastingSpeed.playerGUID then
        return CastingSpeed.playerGUID
    end
    local g = (GetNampowerVersion and GetUnitGUID) and GetUnitGUID("player")
    CastingSpeed.playerGUID = g
    return g
end

-- 存储施法信息
function CastingSpeed:AddCastInfo(casterGUID, targetGUID, spellID, castTime)
    if not casterGUID or not targetGUID then
        return
    end
    local currentTime = GetTime()
    local endTime = currentTime + castTime / 1000

    if not CastingSpeed.castData[targetGUID] then
        CastingSpeed.castData[targetGUID] = {}
    end

    CastingSpeed.castData[targetGUID][casterGUID] = {
        spellID = spellID,
        castTime = castTime,
        startTime = currentTime,
        endTime = endTime
    }

    -- 记录自己各法术最近一次实测施法时间（毫秒快照，反映当时的加速/减速状态），
    -- 供预测下一次同类施法的完成时间用
    if casterGUID and casterGUID == self:GetPlayerGUID() then
        self.selfObservedCastMs = self.selfObservedCastMs or {}
        self.selfObservedCastMs[spellID] = castTime
    end
end

-- ============================================================
-- 查询函数（供治疗决策使用）
-- ============================================================

-- 获取目标的治疗施法者数量（排除自己；过期条目不计）
function CastingSpeed:GetHealerCount(targetGUID)
    if not CastingSpeed.castData[targetGUID] then
        return 0
    end

    local count = 0
    local playerGUID = CastingSpeed:GetPlayerGUID()
    local now = GetTime()

    for casterGUID, castInfo in pairs(CastingSpeed.castData[targetGUID]) do
        if casterGUID ~= playerGUID and castInfo.endTime > now then
            count = count + 1
        end
    end

    return count
end

-- 检查是否有人会先于本次施法完成治疗
-- predictedEndTime：本次施法的预测完成时间（GetTime() 基准，秒）；nil 时退回用自己当前在读条的完成时间
function CastingSpeed:HasFasterCaster(targetGUID, casterGUID, predictedEndTime)
    if not CastingSpeed.castData[targetGUID] then
        return false
    end

    local currentTime = GetTime()
    local myEndTime = predictedEndTime

    if not myEndTime then
        local own = CastingSpeed.castData[targetGUID][casterGUID]
        if own then
            myEndTime = own.endTime
        end
    end

    if not myEndTime then
        return false
    end

    for guid, castInfo in pairs(CastingSpeed.castData[targetGUID] or {}) do
        if guid ~= casterGUID and castInfo.endTime < myEndTime
            and castInfo.endTime > currentTime then
            return true
        end
    end

    return false
end

-- 清理过期的施法数据
function CastingSpeed:CleanExpiredCastData()
    local currentTime = GetTime()
    for targetGUID, casters in pairs(CastingSpeed.castData or {}) do
        for casterGUID, castInfo in pairs(casters) do
            if castInfo.endTime <= currentTime then
                casters[casterGUID] = nil
            end
        end
        if next(casters) == nil then
            CastingSpeed.castData[targetGUID] = nil
        end
    end
end

-- 从GoubayuHeal获取配置
function CastingSpeed:GetGoubayuHealConfig()
    if GoubayuHeal.Config then
        return GoubayuHeal.Config
    else
        return {
            healer_count_limit = 3,
            block_faster_healers = 0
        }
    end
end

-- 判断是否应该治疗目标（竞争逻辑）
-- predictedEndTime：本次施法的预测完成时间（GetTime() + casttime 秒）
function CastingSpeed:ShouldHealTarget(targetGUID, casterGUID, predictedEndTime)
    -- 比较前先同步自己在读条记录的最新完成时间（含推条/实时施法时间变化）
    CastingSpeed:SyncSelfCastInfo()

    -- 兜底标志：竞争回退时强制放行
    if GoubayuHeal and GoubayuHeal.competition_fallback then
        return true
    end

    local config = CastingSpeed:GetGoubayuHealConfig()

    -- 两个条件独立共存，任一不满足即放弃该目标（互不掩盖）：
    -- ① 人数限制：目标上除我之外同时在读条的治疗者 >= 设定值 → 放弃（并发太多）
    -- ② 更快者限制（勾选时）：目标上已有别人的治疗条会先于本次施法落地 → 放弃（大概率过量）
    -- 例：人数限制=3，目标有2个在读慢速治疗（强效/祷言）→ 人数通过；若我能读快速/圣光闪现
    --     且预测先落地 → 通过 → 正常施放；若有人读条会先于我落地 → 放弃
    local healerCount = CastingSpeed:GetHealerCount(targetGUID)
    if type(healerCount) == "number" and type(config.healer_count_limit) == "number"
        and healerCount >= config.healer_count_limit then
        return false
    end

    if config.block_faster_healers == 1 then
        -- 预测口径：目标上已有别人的治疗条会先于本次施法落地 → 本次治疗大概率过量 → 放弃该目标
        -- （瞬发 casttime=0 时预测完成时间=now，不可能有人更快，恒放行）
        local hasFaster = CastingSpeed:HasFasterCaster(targetGUID, casterGUID, predictedEndTime)
        if hasFaster then
            return false
        end
    end

    return true
end

GoubayuHeal.CastingSpeed = CastingSpeed

-- 模块加载即初始化：Init 内部注册 PLAYER_LOGIN，登录后按环境启用 Nampower 施法事件
-- （此前从未调用过 Init，竞争人数限制/更快治疗者检测两个功能整体失效）
CastingSpeed:Init()

-- ============================================================
-- 替代单位ID查询（AKA）
-- ============================================================

function GoubayuHeal.AKA(target)
    if (not target or not UnitExists(target)) then
        return target
    end

    local players = GetNumRaidMembers()
    local por = "raid"
    if (players == 0) then
        players = GetNumPartyMembers()
        por = "party"
        if (UnitIsUnit(target, "player")) then
            return "player"
        end
        if (UnitExists("pet") and UnitIsUnit(target, "pet")) then
            return "pet"
        end
    end

    for a = 1, players do
        local unit = por .. a
        if (UnitExists(unit)) then
            if (UnitIsUnit(target, unit)) then
                return unit
            end
            unit = por .. "pet" .. a
            if (UnitExists(unit) and UnitIsUnit(target, unit)) then
                return unit
            end
        end
    end

    return target
end

-- ============================================================
-- 清除提示框
-- ============================================================

function GoubayuHeal.ClearTooltip()
    if not GoubayuHeal_Tooltip then
        return
    end
    -- 1.12离屏查询规范：每次填充前重新SetOwner（冷启动会话直接SetSpell可能填充失败）
    -- 实证约束（两次回归的教训）：查询tooltip的显示状态（Show/Hide）不可变更，
    -- 否则 Set* 填充失效（治疗值全0）。改用透明度控制可见性：
    -- alpha=0 时填充/读取完全正常但渲染不可见（查询框永不显示为可见框）
    GoubayuHeal_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GoubayuHeal_Tooltip:ClearLines()
    GoubayuHeal_Tooltip:SetAlpha(0)
end

-- ============================================================
-- 获取增益/减益数据（从tooltip读取）
-- ============================================================

function GoubayuHeal.GetBuffData(unit, index)
    if (not unit or not index) then
        return
    end
    GoubayuHeal.ClearTooltip()
    pcall(function() GoubayuHeal_Tooltip:SetUnitBuff(unit, index) end)

    local left1 = getglobal("GoubayuHealTooltipTextLeft1")
    local right1 = getglobal("GoubayuHealTooltipTextRight1")
    local left2 = getglobal("GoubayuHealTooltipTextLeft2")
    local name = left1 and left1:GetText() or ""
    local dtype = right1 and right1:GetText() or ""
    local text = left2 and left2:GetText() or ""
    return name, dtype, text
end

function GoubayuHeal.GetDebuffData(unit, index)
    if (not unit or not index) then
        return
    end
    GoubayuHeal.ClearTooltip()
    pcall(function() GoubayuHeal_Tooltip:SetUnitDebuff(unit, index) end)

    local left1 = getglobal("GoubayuHealTooltipTextLeft1")
    local right1 = getglobal("GoubayuHealTooltipTextRight1")
    local left2 = getglobal("GoubayuHealTooltipTextLeft2")
    local name = left1 and left1:GetText() or ""
    local dtype = right1 and right1:GetText() or ""
    local text = left2 and left2:GetText() or ""
    return name, dtype, text
end

-- ============================================================
-- 获取法术数据（从tooltip读取）
-- ============================================================

function GoubayuHeal.GetSpellData(spellid, bookid)
    GoubayuHeal.ClearTooltip()
    -- 冷启动登录时法术书可能未就绪，SetSpell 抛错会让整个解析中断；按空数据容错
    local okSet = pcall(function() GoubayuHeal_Tooltip:SetSpell(spellid, bookid) end)

    local function gtLeft(n)
        local f = getglobal("GoubayuHealTooltipTextLeft" .. n)
        return f and f:GetText() or nil
    end
    local function gtRight(n)
        local f = getglobal("GoubayuHealTooltipTextRight" .. n)
        return f and f:GetText() or nil
    end

    -- 拼接描述行：从第4行扫到 tooltip 结束（描述可能超过5行，硬窗口会截断关键数值行）
    local text = ""
    local tlLines = GoubayuHeal_Tooltip:NumLines() or 0
    for ln = 4, tlLines do
        text = text .. (gtLeft(ln) or "")
    end
    text = string.gsub(text, ",", ".")

    -- Nampower快路径：用DBC字段拿mana/range/casttime
    if GetNampowerVersion and GetSpellBookItemInfo and GetSpellRecField then
        local stype, sid = GetSpellBookItemInfo(spellid, bookid or BOOKTYPE_SPELL)
        if stype == "SPELL" and sid then
            local mana, range, casttime = 0, 0, 0
            local ok_m, val_m = pcall(GetSpellRecField, sid, "manaCost")
            -- 字段不存在时部分Nampower版本返回"Unknown field name"字符串，需类型校验防止比较/算术报错
            if ok_m and type(val_m) == "number" then
                mana = val_m
            end
            local ok_ct, val_ct = pcall(GetSpellRecField, sid, "castTime")
            -- 部分Nampower版本castTime字段不存在，会返回"Unknown field name"字符串，需类型校验防止算术报错
            if ok_ct and type(val_ct) == "number" then
                casttime = val_ct / 1000
            end
            local ok_ri, val_ri = pcall(GetSpellRecField, sid, "rangeIndex")
    if ok_ri and type(val_ri) == "number" and val_ri > 0 and GetSpellRangeData then
        -- GetSpellRangeData 返回 minRange, maxRange, flags, name（多返回值，非表）
        local ok_rr, _, maxRange = pcall(GetSpellRangeData, val_ri)
        if ok_rr and maxRange then
            range = maxRange
        end
    end
            if mana > 0 or casttime > 0 or range > 0 then
                return mana, range, casttime, text
            end
        end
    end

    -- fallback: tooltip解析
    local mana = gtLeft(2)
    local range = gtRight(2)
    local time = gtLeft(3)
    local start, stop

    start, stop, mana = string.find(string.gsub((mana or ""), ",", "."), "(%d+%.?%d*)")
    mana = (mana or 0) / 1.0

    start, stop, time = string.find(string.gsub((time or ""), ",", "."), "(%d+%.?%d*)")
    time = (time or 0) / 1.0

    start, stop, range = string.find(string.gsub((range or ""), ",", "."), "(%d+%.?%d*)")
    range = (range or 0) / 1.0

    return mana, range, time, text
end

-- ============================================================
-- 单位ID查询（根据名称查找单位token）
-- ============================================================

-- 构建 名字→单位token 映射（团队变动/进世界时刷新，避免反复线性扫描）
function GoubayuHeal.BuildUnitMap()
    local nu = {}
    local units = { "player" }
    if UnitExists("pet") then table.insert(units, "pet") end
    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    for a = 1, n do
        table.insert(units, por .. a)
        table.insert(units, por .. "pet" .. a)
    end
    table.insert(units, "target")
    table.insert(units, "targettarget")
    table.insert(units, "mouseover")
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local name = GoubayuHeal.UnitName(u)
            if name and name ~= "" then
                nu[name] = u
                if u == "pet" then nu[GoubayuHeal.UnitName("player") .. "-" .. name] = u end
                if string.find(u, "pet") and u ~= "pet" then
                    nu[GoubayuHeal.UnitName(string.gsub(u, "pet", "")) .. "-" .. name] = u
                end
            end
        end
    end
    GoubayuHeal.name_unit_map = nu
end

function GoubayuHeal.GetUnitID(name)
    if (not name) then
        return
    end

    GoubayuHeal.player_map = (GoubayuHeal.player_map or {})
    -- 优先查名字→单位映射（团队变动时已刷新）
    if GoubayuHeal.name_unit_map and GoubayuHeal.name_unit_map[name] then
        local mu = GoubayuHeal.name_unit_map[name]
        if UnitExists(mu) then
            GoubayuHeal.player_map[name] = mu
            return mu
        end
    end

    local unit = GoubayuHeal.player_map[name]
    if (unit and UnitExists(unit)) then
        if (GoubayuHeal.UnitName(unit) == name) then
            return unit
        elseif (unit == "pet" and GoubayuHeal.UnitName("player") .. "-" .. GoubayuHeal.UnitName("pet") == name) then
            return unit
        elseif (string.find(unit, "pet") and GoubayuHeal.UnitName(string.gsub(unit, "pet", "")) .. "-"
                .. GoubayuHeal.UnitName(unit) == name) then
            return unit
        end
    end

    -- 慢速查找
    local players = GetNumRaidMembers()
    local por = "raid"
    if (players == 0) then
        if (GoubayuHeal.my_name == name) then
            GoubayuHeal.player_map[name] = "player"
            return "player"
        end
        if (UnitExists("pet") and GoubayuHeal.UnitName("player") .. "-" .. GoubayuHeal.UnitName("pet") == name) then
            GoubayuHeal.player_map[name] = "pet"
            return "pet"
        end
        players = GetNumPartyMembers()
        por = "party"
    end

    for a = 1, players do
        local unit = por .. a
        local unitpet = por .. "pet" .. a
        if (UnitExists(unit) and GoubayuHeal.UnitName(unit) == name) then
            GoubayuHeal.player_map[name] = unit
            return unit
        elseif (UnitExists(unitpet) and GoubayuHeal.UnitName(unit) .. "-" .. GoubayuHeal.UnitName(unitpet) == name) then
            GoubayuHeal.player_map[name] = unitpet
            return unitpet
        end
    end

    if (GoubayuHeal.UnitName("target") == name) then
        return "target"
    end
    if (GoubayuHeal.UnitName("targettarget") == name) then
        return "targettarget"
    end
    if (GoubayuHeal.UnitName("mouseover") == name) then
        return "mouseover"
    end
end

-- ============================================================
-- 单位名称（去除服务器名）
-- ============================================================

function GoubayuHeal.UnitName(unit)
    local name = UnitName(unit)
    return name or ""
end

-- ============================================================
-- 聊天输出
-- ============================================================

function GoubayuHeal.Print(message, color)
    if (not message) then
        return
    end
    if (not color) then
        color = "|cffFF9000"
    end
    if (DEFAULT_CHAT_FRAME) then
        DEFAULT_CHAT_FRAME:AddMessage(color .. message)
    end
end

-- ============================================================
-- 玩家数据更新（buff/debuff快照）
-- ============================================================

-- Nampower光环快照优化
GoubayuHeal.aura_snapshot = {}
GoubayuHeal.aura_snapshot_counter = {}

-- 生成单位光环签名（Nampower aura字段）
function GoubayuHeal.GetAuraSignature(unit)
    if (not (GetNampowerVersion and GetUnitField)) then
        return nil
    end
    local auras = GetUnitField(unit, "aura")
    if (not auras) then
        return nil
    end
    local applications = GetUnitField(unit, "auraApplications")
    local sig = {}
    local n = 0
    for i = 1, 48 do
        local id = auras[i]
        if (id and id ~= 0) then
            n = n + 1
            if (applications and applications[i] and applications[i] > 1) then
                sig[n] = id .. "_" .. applications[i]
            else
                sig[n] = id
            end
        end
    end
    return sig
end

-- 比较两份光环签名是否一致
function GoubayuHeal.AuraSignatureEqual(a, b)
    if (table.getn(a) ~= table.getn(b)) then
        return false
    end
    for i = 1, table.getn(a) do
        if (a[i] ~= b[i]) then
            return false
        end
    end
    return true
end

-- 设置单个玩家的数据（buff/debuff）
function GoubayuHeal.SetPlayerData(unit, elapsed)
    local name = GoubayuHeal.UnitName(unit)
    if (string.find(unit, "pet")) then
        if (unit == "pet") then
            name = GoubayuHeal.UnitName("player") .. "-" .. name
        else
            name = GoubayuHeal.UnitName(string.gsub(unit, "pet", "")) .. "-" .. name
        end
    end

    if (not GoubayuHeal.player_data[name]) then
        GoubayuHeal.player_data[name] = {
            ["Buff"] = {},
            ["Debuff"] = {}
        }
    end

    GoubayuHeal.buff_texture_map = (GoubayuHeal.buff_texture_map or {})
    GoubayuHeal.debuff_texture_map = (GoubayuHeal.debuff_texture_map or {})

    GoubayuHeal.player_data[name]["CurrentTick"] = (GoubayuHeal.player_data[name]["CurrentTick"] or 0) + 1
    GoubayuHeal.player_data[name]["UpdateTime"] = GetTime()

    -- Nampower快速路径：光环集合未变化时跳过UnitBuff/UnitDebuff扫描
    if (GetNampowerVersion and GetUnitField) then
        local sig = GoubayuHeal.GetAuraSignature(unit)
        if (sig) then
            GoubayuHeal.aura_snapshot_counter[name] = (GoubayuHeal.aura_snapshot_counter[name] or 0) + 1
            local prev = GoubayuHeal.aura_snapshot[name]

            -- 每约60秒强制全量扫描一次
            if (prev and GoubayuHeal.aura_snapshot_counter[name] < 120
                and GoubayuHeal.AuraSignatureEqual(prev, sig)) then
                -- 轻量扫描：只更新Tick，不读tooltip
                local presentBuff, presentDebuff = {}, {}
                for slot = 1, 32 do
                    local bt = UnitBuff(unit, slot)
                    local dt = UnitDebuff(unit, slot)
                    if (not bt and not dt) then
                        break
                    end
                    if bt then
                        presentBuff[bt] = true
                    end
                    if dt then
                        presentDebuff[dt] = true
                    end
                end
                for texture, buffData in pairs(GoubayuHeal.player_data[name]["Buff"]) do
                    if presentBuff[texture] then
                        buffData["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                        buffData["Time"] = buffData["Time"] + elapsed
                    end
                end
                for texture, debuffData in pairs(GoubayuHeal.player_data[name]["Debuff"]) do
                    if presentDebuff[texture] then
                        debuffData["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                        debuffData["Time"] = debuffData["Time"] + elapsed
                    end
                end
                return
            end

            GoubayuHeal.aura_snapshot[name] = sig
            GoubayuHeal.aura_snapshot_counter[name] = 0
        end
    end

    -- 全量扫描buff/debuff
    for slot = 1, 32 do
        local bufftexture, buffamount = UnitBuff(unit, slot)
        local debufftexture, debuffamount = UnitDebuff(unit, slot)

        if (not bufftexture and not debufftexture) then
            return
        end

        if (bufftexture) then
            if (not GoubayuHeal.player_data[name]["Buff"][bufftexture]) then
                local buffname, bufftype, bufftext = GoubayuHeal.GetBuffData(unit, slot)
                if (buffname) then
                    GoubayuHeal.buff_texture_map[buffname] = bufftexture
                    GoubayuHeal.player_data[name]["Buff"][bufftexture] = {
                        ["Count"] = buffamount,
                        ["Name"] = buffname,
                        ["Text"] = string.gsub((bufftext or ""), ",", "."),
                        ["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"],
                        ["Time"] = elapsed,
                        ["Type"] = bufftype
                    }
                end
            elseif (GoubayuHeal.player_data[name]["Buff"][bufftexture]["Tick"] == GoubayuHeal.player_data[name]["CurrentTick"] - 1
                    and buffamount == GoubayuHeal.player_data[name]["Buff"][bufftexture]["Count"]) then
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Time"] = GoubayuHeal.player_data[name]["Buff"][bufftexture]["Time"] + elapsed
            else
                local buffname, bufftype, bufftext = GoubayuHeal.GetBuffData(unit, slot)
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Count"] = buffamount
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Name"] = buffname
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Text"] = string.gsub((bufftext or ""), ",", ".")
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Time"] = elapsed
                GoubayuHeal.player_data[name]["Buff"][bufftexture]["Type"] = bufftype
            end
        end

        if (debufftexture) then
            if (not GoubayuHeal.player_data[name]["Debuff"][debufftexture]) then
                local debuffname, debufftype, debufftext = GoubayuHeal.GetDebuffData(unit, slot)
                if (debuffname) then
                    GoubayuHeal.debuff_texture_map[debuffname] = debufftexture
                    GoubayuHeal.player_data[name]["Debuff"][debufftexture] = {
                        ["Count"] = debuffamount,
                        ["Name"] = debuffname,
                        ["Text"] = string.gsub((debufftext or ""), ",", "."),
                        ["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"],
                        ["Time"] = elapsed,
                        ["Type"] = debufftype
                    }
                end
            elseif (GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Tick"] == GoubayuHeal.player_data[name]["CurrentTick"] - 1
                    and debuffamount == GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Count"]) then
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Time"] = GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Time"] + elapsed
            else
                local debuffname, debufftype, debufftext = GoubayuHeal.GetDebuffData(unit, slot)
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Count"] = debuffamount
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Name"] = debuffname
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Text"] = string.gsub((debufftext or ""), ",", ".")
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Tick"] = GoubayuHeal.player_data[name]["CurrentTick"]
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Time"] = elapsed
                GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Type"] = debufftype
            end
        end
    end
end

-- ============================================================
-- 增益/减益判断（基于缓存数据）
-- ============================================================

function GoubayuHeal.UnitGotBuff(unit, buff)
    local bufftexture = GoubayuHeal.buff_texture_map and GoubayuHeal.buff_texture_map[buff]
    if (not bufftexture) then
        return
    end

    local name = GoubayuHeal.UnitName(unit)
    if (string.find(unit, "pet")) then
        if (unit == "pet") then
            name = GoubayuHeal.UnitName("player") .. "-" .. name
        else
            name = GoubayuHeal.UnitName(string.gsub(unit, "pet", "")) .. "-" .. name
        end
    end

    if (not GoubayuHeal.player_data or not GoubayuHeal.player_data[name]
        or not GoubayuHeal.player_data[name]["Buff"]
        or not GoubayuHeal.player_data[name]["Buff"][bufftexture]) then
        return
    end

    if (GoubayuHeal.player_data[name]["Buff"][bufftexture]["Tick"] == GoubayuHeal.player_data[name]["CurrentTick"]
        and GoubayuHeal.player_data[name]["Buff"][bufftexture]["Name"] == buff) then
        return GoubayuHeal.player_data[name]["Buff"][bufftexture]
    end
end

function GoubayuHeal.UnitGotDebuff(unit, debuff)
    local debufftexture = GoubayuHeal.debuff_texture_map and GoubayuHeal.debuff_texture_map[debuff]
    if (not debufftexture) then
        return
    end

    local name = GoubayuHeal.UnitName(unit)
    if (string.find(unit, "pet")) then
        if (unit == "pet") then
            name = GoubayuHeal.UnitName("player") .. "-" .. name
        else
            name = GoubayuHeal.UnitName(string.gsub(unit, "pet", "")) .. "-" .. name
        end
    end

    if (not GoubayuHeal.player_data or not GoubayuHeal.player_data[name]
        or not GoubayuHeal.player_data[name]["Debuff"]
        or not GoubayuHeal.player_data[name]["Debuff"][debufftexture]) then
        return
    end

    if (GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Tick"] == GoubayuHeal.player_data[name]["CurrentTick"]
        and GoubayuHeal.player_data[name]["Debuff"][debufftexture]["Name"] == debuff) then
        return GoubayuHeal.player_data[name]["Debuff"][debufftexture]
    end
end

-- ============================================================
-- 玩家数据批量更新
-- ============================================================

function GoubayuHeal.UpdatePlayerData(elapsed, unit)
    elapsed = (elapsed or 0)
    if (not this) then
        elapsed = 0
    end

    if (elapsed ~= 0 and this and GoubayuHeal.last_update_player_data_caller
        and GoubayuHeal.last_update_player_data_caller ~= this:GetName()) then
        return
    end

    local start = GetTime()
    GoubayuHeal.player_data = (GoubayuHeal.player_data or {})

    if (this and elapsed ~= 0) then
        GoubayuHeal.last_update_player_data_caller = this:GetName()
    end

    if (unit) then
        GoubayuHeal.SetPlayerData(unit, 0)
        return
    end

    local players = GetNumRaidMembers()
    local por = "raid"
    if (players == 0) then
        players = GetNumPartyMembers()
        por = "party"
        GoubayuHeal.SetPlayerData("player", elapsed)
        if (UnitExists("pet")) then
            GoubayuHeal.SetPlayerData("pet", elapsed)
        end
    end

    if (UnitExists("target")) then
        GoubayuHeal.SetPlayerData("target", elapsed)
    end
    if (UnitExists("targettarget")) then
        GoubayuHeal.SetPlayerData("targettarget", elapsed)
    end
    if (UnitExists("mouseover")) then
        GoubayuHeal.SetPlayerData("mouseover", elapsed)
    end

    for a = 1, players do
        local unit = por .. a
        if (UnitExists(unit)) then
            GoubayuHeal.SetPlayerData(unit, elapsed)
            unit = por .. "pet" .. a
            if (UnitExists(unit)) then
                GoubayuHeal.SetPlayerData(unit, elapsed)
            end
        end
    end

    if (elapsed > 0) then
        local configured = GoubayuHeal.Config and GoubayuHeal.Config["update_player_data_time"]
        if (not configured or configured <= 0) then
            configured = 2.5
        end
        if (configured > 100) then
            configured = 2.5
        elseif (configured < 0.1) then
            configured = 0.1
        end
        GoubayuHeal.update_player_data_interval = configured

        local scanTime = GetTime() - start
        if (scanTime > configured * 0.5) then
            GoubayuHeal.update_player_data_interval = configured + scanTime
        end
        if (GoubayuHeal.update_player_data_interval < 0.5) then
            GoubayuHeal.update_player_data_interval = 0.5
        elseif (GoubayuHeal.update_player_data_interval > 10) then
            GoubayuHeal.update_player_data_interval = 10
        end
    end
end