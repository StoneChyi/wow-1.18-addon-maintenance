--[[
    ClientModCompat —— 无 Nampower / SuperWoW / UnitXP SP3 时的优雅降级层 by 武藤纯子酱 2026.9.11

    目标：缺少这些客户端 Mod 时，依赖它们的功能一律「静默失效」，绝不抛红字，
          即使宏里写了相应条件/命令也不报错。

    关键原则：
      * 每个 Mod 单独判断——**只有该 Mod 缺失时才为它的全局装安全空桩**，
        且**只有 Nampower / UnitXP 缺失时才启用条件求值包裹**（命中缺失功能的条件判 false）。
      * Nampower + UnitXP 齐全的环境（无论是否装 SuperWoW、也无论 Nampower 版本高低）
        本文件完全惰性：不装 Nampower/UnitXP 桩、不包裹关键字，零开销、零干扰。
      * 不碰任何被用作能力判断（`if GetXxx then`）的全局。
]]

local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}
_G.CleveRoids = CleveRoids

CleveRoids._compatActive = false   -- 是否装了任意空桩（仅诊断用）
CleveRoids._compatWrap = false     -- 是否需要包裹条件求值（仅 Nampower/UnitXP 缺失）
CleveRoids._featureMiss = false
CleveRoids._featureDepth = 0       -- 包裹嵌套深度：仅最外层读取/重置 _featureMiss

local function MakeStub()
    return function()
        CleveRoids._featureMiss = true
        return nil
    end
end

local function InstallStub(name)
    if _G[name] == nil then
        _G[name] = MakeStub()
        CleveRoids._compatActive = true
    end
end

-- ===== Nampower（缺失时才装桩 + 包裹）=====
if CleveRoids.hasNampower ~= true then
    local NAMEPOWER_DATA_STUBS = {
        "GetSpellRecField", "GetSpellRec", "GetSpellRangeData",
        "GetUnitField", "GetUnitData", "GetUnitGUID",
        "GetItemStats", "GetItemStatsField", "GetSpellNameAndRankForId",
        "GetItemIconTexture", "GetSpellIconTexture",
        "GetSpellPower", "GetSpellModifiers",
        "GetBagItems", "GetBagItem", "GetBagItemsWithIndex",
        "GetEquippedItems", "GetEquippedItem",
        "GetTrinkets", "GetTrinketCooldown",
        "GetAmmo", "GetItemLevel", "GetSpellSlotTypeIdForName",
        "CastSpellByNameNoQueue", "QueueScript",
        "ChannelStopCastingNextTick", "DisenchantAll", "LearnTalentRank",
        "PlayerIsMoving",
    }
    for i = 1, table.getn(NAMEPOWER_DATA_STUBS) do
        InstallStub(NAMEPOWER_DATA_STUBS[i])
    end
    CleveRoids._compatWrap = true
end

-- ===== UnitXP（缺失时才装桩 + 包裹）=====
if _G.UnitXP == nil then
    _G.UnitXP = MakeStub()
    CleveRoids._compatActive = true
    CleveRoids._compatWrap = true
end

-- ===== SuperWoW（缺失时只装桩；不参与包裹，避免影响有 Nampower+UnitXP 的环境）=====
-- SetAutoloot / SUPERWOW_VERSION 用于能力探测，不桩
if CleveRoids.hasSuperwow ~= true then
    local SUPERWOW_STUBS = {
        "IsMounted", "IsIndoors", "isIndoors", "IsSwimming", "GetSpeed",
        "GetPlayerBuffID", "GetWeaponEnchantID",
        "UnitPosition", "CursorPosition", "UnitNameplate",
    }
    for i = 1, table.getn(SUPERWOW_STUBS) do
        InstallStub(SUPERWOW_STUBS[i])
    end
end

-- 条件求值兜底：仅当 Nampower/UnitXP 缺失时包裹，pcall 失败或命中缺失功能 → 条件判 false
-- 用深度计数保证：嵌套关键字不会重置外层的 _featureMiss；同时保留全部参数与返回值
local function WrapKeywords()
    if not CleveRoids._compatWrap or CleveRoids._keywordsWrapped then return end
    local K = CleveRoids.Keywords
    if type(K) ~= "table" then return end
    CleveRoids._keywordsWrapped = true
    CleveRoids._featureDepth = 0
    for name, fn in pairs(K) do
        if type(fn) == "function" then
            K[name] = function(...)
                local outermost = (CleveRoids._featureDepth == 0)
                if outermost then CleveRoids._featureMiss = false end
                CleveRoids._featureDepth = CleveRoids._featureDepth + 1
                local results = { pcall(fn, unpack(arg, 1, arg.n)) }
                CleveRoids._featureDepth = CleveRoids._featureDepth - 1
                if not results[1] then
                    if outermost then CleveRoids._featureMiss = false end
                    return false
                end
                if outermost and CleveRoids._featureMiss then
                    CleveRoids._featureMiss = false
                    return false
                end
                local maxIdx = 1
                for i = 2, 32 do if results[i] ~= nil then maxIdx = i end end
                if maxIdx > 1 then return unpack(results, 2, maxIdx) end
                return nil
            end
        end
    end
end

-- CleveRoids.Keywords 在 Conditionals.lua 中定义（本文件之后加载），登录时再包裹
local compatFrame = CreateFrame("Frame")
compatFrame:RegisterEvent("PLAYER_LOGIN")
compatFrame:SetScript("OnEvent", function() WrapKeywords() end)

_G["CleveRoids"] = CleveRoids
