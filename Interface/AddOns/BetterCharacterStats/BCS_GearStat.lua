--[[
BCS_GearStat.lua: 10 月 24 日包共享装备采集层，按个人版需求合并。
扫描 0..19 共 20 槽，提供压缩左侧文本、品质色及原始左右行/套装激活状态。
BCS 与 StatCompare 共享采集结果，继续使用各自原有属性解析与个人计算口径；
规则汇总接口保留供兼容使用，不以规则总量替代个人急速、狂热或套装算法。
每次复用均核对装备签名；换装/进入世界事件失效，600 秒只作装备快照兜底。
光环、天赋及派生数值仍由个人版刷新和短缓存管理。
complete=false 时消费者回退原扫描路径，不缓存不完整结果。
]]

GearStat = GearStat or {}
local GS = GearStat

GS.VERSION = "1.0"

local getglobal = getglobal
local strfind = strfind
local gsub = gsub
local tonumber = tonumber
local getn = table.getn

local MIN_SLOT, MAX_SLOT = 0, 19
local ITEM_FRAME_UNIT = "player"

-- 硬兜底（秒）：超过这个时间无论签名如何都重扫一次
GS.CACHE_TTL_HARD = 600

--==========================================================================
-- tooltip
--==========================================================================
-- ⚠️ 这台 1.12 客户端上，「ClearLines() + SetInventoryItem()」这个组合会返回 nil、
--    NumLines() 为 0，一行都抓不到（实测：SET=nil LINES=0）。原 BCS 的装备扫描
--    从来**没调过** ClearLines / Hide —— SetInventoryItem 自己会清旧行。
--    所以这里也一律不调用这两个，保持和验证过的旧代码完全同一条路径。
local PREFIX = "BCS_GearStatTooltip"
-- 备用 tooltip：BCS helper.lua 自己那个（这个客户端上被验证过能出行）。
-- 自己的 tooltip 万一还是读不到，就临时借用它。
local SHARED_NAME = "BetterCharacterStatsTooltip"

local GS_Tooltip = getglobal(PREFIX) or CreateFrame("GameTooltip", PREFIX, nil, "GameTooltipTemplate")
local GS_TOOLTIP_NAME = PREFIX
GS_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- unit -> snapshot
local CACHE = {}
-- 调试计数：累计真正执行的扫描轮次（仿真/排查用，正常游戏里只增不减）
GS.ScanCount = 0


--==========================================================================
-- 装备签名
--==========================================================================
-- 用「槽位 + 裸 item 串」拼签名。刻意不用 GetInventoryItemLink 的完整串，
-- 因为链接里带超链接文本（item 名字），本地化改文案会误判成换了装备。
local function BuildSignature(unit)
	local parts, n = {}, 0
	for slot = MIN_SLOT, MAX_SLOT do
		local part = "-"
		local link = GetInventoryItemLink(unit, slot)
		if link then
			local bare = gsub(link, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
			if bare and bare ~= link then
				part = bare
			else
				part = link
			end
		end
		n = n + 1
		parts[n] = part
	end
    if unit == "player" and type(GetWeaponEnchantInfo) == "function" then
        local mh, _, mc, oh, _, oc = GetWeaponEnchantInfo()
        n=n+1;parts[n]=tostring(mh)..":"..tostring(mc)..":"..tostring(oh)..":"..tostring(oc)
    end
	return table.concat(parts, "|")
end


--==========================================================================
-- 规则表
--==========================================================================
-- 每条规则：
--   pattern  必填，Lua 模式（用 strfind，第一个捕获组当数值）
--   key      必填，字符串或数组（数组 = 一个数值同时加到多个键）
--   value    可选，固定数值（有它就不看捕获组，用于「某物品固定加成」这类）
--   mode     可选，"mult" 表示按百分比连乘（急速是这个口径），默认相加
--
-- ⚠️ 这里是**共享规则表**，外部可以直接 table.insert(GS.RULES, {...}) 追加，
--    但请把「本插件专属、别处不认」的规则放在自己的局部表里，
--    避免两边的口径互相污染。
GS.RULES = {
	-- 主属性
	{ pattern = "^%+(%d+) 力量", key = "STR" },
	{ pattern = "^%+(%d+) 敏捷", key = "AGI" },
	{ pattern = "^%+(%d+) 耐力", key = "STA" },
	{ pattern = "^%+(%d+) 智力", key = "INT" },
	{ pattern = "^%+(%d+) 精神", key = "SPI" },

	-- 护甲 / 抗性
	{ pattern = "^%+(%d+) 护甲", key = "ENARMOR" },
	{ pattern = "%+(%d+)点护甲值", key = "ENARMOR" },
	{ pattern = "^%+(%d+) 奥术抗性", key = "ARCANERES" },
	{ pattern = "^%+(%d+) 火焰抗性", key = "FIRERES" },
	{ pattern = "^%+(%d+) 冰霜抗性", key = "FROSTRES" },
	{ pattern = "^%+(%d+) 自然抗性", key = "NATURERES" },
	{ pattern = "^%+(%d+) 暗影抗性", key = "SHADOWRES" },
	{ pattern = "^%+(%d+) 所有魔法抗性", key = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" } },

	-- 攻击强度 / 法术强度
	{ pattern = "^%+(%d+) 攻击强度", key = { "ATTACKPOWER", "RANGEDATTACKPOWER" } },
	{ pattern = "^%+(%d+) 远程攻击强度", key = "RANGEDATTACKPOWER" },
	{ pattern = "提高所有法术和魔法效果所造成的伤害和治疗效果，最多(%d+)点", key = { "DMG", "HEAL" } },
	{ pattern = "法术伤害和治疗效果提高(%d+)点", key = { "DMG", "HEAL" } },
	{ pattern = "提高法术所造成的治疗效果，最多(%d+)点", key = "HEAL" },
	{ pattern = "提高法术和魔法效果所造成的治疗效果，最多(%d+)点", key = "HEAL" },
	{ pattern = "使治疗法术和效果所回复的生命值提高(%d+)点", key = "HEAL" },
	{ pattern = "提高奥术法术和效果所造成的伤害，最多(%d+)点", key = "ARCANEDMG" },
	{ pattern = "提高火焰法术和效果所造成的伤害，最多(%d+)点", key = "FIREDMG" },
	{ pattern = "提高冰霜法术和效果所造成的伤害，最多(%d+)点", key = "FROSTDMG" },
	{ pattern = "提高神圣法术和效果所造成的伤害，最多(%d+)点", key = "HOLYDMG" },
	{ pattern = "提高自然法术和效果所造成的伤害，最多(%d+)点", key = "NATUREDMG" },
	{ pattern = "提高暗影法术和效果所造成的伤害，最多(%d+)点", key = "SHADOWDMG" },

	-- 命中 / 暴击
	{ pattern = "使你击中目标的几率提高(%d+)%%", key = "TOHIT" },
	{ pattern = "使你的物理攻击和法术击中敌人的几率提高(%d+)%%", key = { "TOHIT", "SPELLTOHIT", "RANGEDTOHIT" } },
	{ pattern = "使你的法术击中敌人的几率提高(%d+)%%", key = "SPELLTOHIT" },
	{ pattern = "使你造成致命一击的几率提高(%d+)%%", key = "CRIT" },
	{ pattern = "使你打出致命一击的几率提高(%d+)%%", key = "CRIT" },
	{ pattern = "使你的法术造成致命一击的几率提高(%d+)%%", key = "SPELLCRIT" },
	{ pattern = "提高你的法术造成致命一击的几率(%d+)%%", key = "SPELLCRIT" },
	{ pattern = "使你的远程武器造成致命一击的几率提高(%d+)%%", key = "RANGEDCRIT" },

	-- 防御类
	{ pattern = "防御技能提高(%d+)点", key = "DEFENSE" },
	{ pattern = "使你躲闪攻击的几率提高(%d+)%%", key = "DODGE" },
	{ pattern = "使你招架攻击的几率提高(%d+)%%", key = "PARRY" },
	{ pattern = "使你用盾牌格挡攻击的几率提高(%d+)%%", key = "TOBLOCK" },
	{ pattern = "使你的盾牌的格挡值提高(%d+)点", key = "BLOCK" },
	{ pattern = "%+(%d+)点格挡", key = "BLOCK" },
	{ pattern = "格挡 %+(%d+)%%", key = "TOBLOCK" },

	-- 回复
	{ pattern = "每5秒恢复(%d+)点生命值", key = "HEALTHREG" },
	{ pattern = "每5秒回复(%d+)点生命值", key = "HEALTHREG" },
	{ pattern = "每5秒恢复(%d+)点法力值", key = "MANAREG" },
	{ pattern = "每5秒回复(%d+)点法力值", key = "MANAREG" },
	{ pattern = "使你在施法时仍保持(%d+)%%的法力", key = "CASTING_MANA_REG" },

	-- 急速 / 穿透
	-- 急速是乘法叠加：两个 2%% 不是 4%% 而是 1.02*1.02-1
	{ pattern = "使你的攻击和施法速度提高(%d+)%%", key = "HASTE", mode = "mult" },
	{ pattern = "使你的攻击速度和施法速度提高(%d+)%%", key = "HASTE", mode = "mult" },
	{ pattern = "%+(%d+)%% 急速", key = "HASTE", mode = "mult" },
	{ pattern = "你的攻击无视目标(%d+)点护甲", key = "ARMORPENETRATION" },
	{ pattern = "%+(%d+) 护甲穿透", key = "ARMORPENETRATION" },
	{ pattern = "护甲穿透 %+(%d+)", key = "ARMORPENETRATION" },
	{ pattern = "使你的法术目标的魔法抗性降低(%d+)点", key = "SPELLPENETRATION" },
	{ pattern = "将你的法术目标的魔法抗性降低(%d+)点", key = "SPELLPENETRATION" },
	{ pattern = "%+(%d+) 法术穿透", key = "SPELLPENETRATION" },
	{ pattern = "法术穿透%s*%+(%d+)", key = "SPELLPENETRATION" },

	-- 吸血（键名沿用 StatCompare 的 LIFEDRAIN，将来换库时口径直接对齐）
	{ pattern = "%+(%d+)%% 吸血", key = "LIFEDRAIN" },
	{ pattern = "所造成伤害的(%d+)%%作为治疗返还", key = "LIFEDRAIN" },
}


local function AddBonus(bonus, key, value, mode)
	if not key or not value then
		return
	end
	if mode == "mult" then
		if bonus[key] then
			bonus[key] = ((bonus[key] / 100 + 1) * (value / 100 + 1) - 1) * 100
		else
			bonus[key] = value
		end
	else
		if bonus[key] then
			bonus[key] = bonus[key] + value
		else
			bonus[key] = value
		end
	end
end


-- 对一行文本跑全部规则。返回是否命中，仅供调试。
local function ApplyLine(bonus, text, rules, total)
	local hit = false
	for r = 1, total do
		local rule = rules[r]
		local _, _, cap = strfind(text, rule.pattern)
		if cap or (rule.value and strfind(text, rule.pattern)) then
			local value = rule.value
			if not value and cap then
				value = tonumber(cap)
			end
			if value then
				local key = rule.key
				if type(key) == "table" then
					for k = 1, getn(key) do
						AddBonus(bonus, key[k], value, rule.mode)
					end
				else
					AddBonus(bonus, key, value, rule.mode)
				end
				hit = true
			end
		end
	end
	return hit
end


local function ApplyRules(snap)
	local rules = GS.RULES
	local total = getn(rules)
	if total == 0 then
		return
	end
	for slot = MIN_SLOT, MAX_SLOT do
		local texts = snap.texts[slot]
		if texts then
			local n = getn(texts)
			for i = 1, n do
				ApplyLine(snap.bonus, texts[i], rules, total)
			end
		end
	end
end


-- 规则汇总是按需的：BCS 现在只吃 texts 缓冲，没人读 bonus 时就不算。
-- 50 条规则 × 150 行 ≈ 7500 次 strfind，放在每次扫描里白花 1~3ms 不值得。
local function EnsureBonuses(snap)
	if snap.rulesDone then
		return snap.bonus
	end
	snap.bonus = {}
	snap.rulesDone = true
	ApplyRules(snap)
	return snap.bonus
end


--==========================================================================
-- 扫描
--==========================================================================
-- 单趟：19 槽逐槽填 tooltip → 收非空行。
-- 刻意不 ClearLines / 不 Hide（见文件上方 tooltip 段的说明）。
local function ScanPass(tip, tipName, unit, snap)
    snap.equipment = {}; snap.texts = {}; snap.colors = {}; snap.count = 0; snap.complete = true
    for slot = MIN_SLOT, MAX_SLOT do
        local hasItem = tip:SetInventoryItem(unit, slot)
        local eq = {hasItem=hasItem, count=hasItem and tip:NumLines() or 0,
            left={}, right={}, hasteSetActive={}}
        local texts = {}
        for line = 1, eq.count do
            local fs = getglobal(tipName .. "TextLeft" .. line)
            local rs = getglobal(tipName .. "TextRight" .. line)
            local text = fs and fs:GetText()
            eq.left[line] = text; eq.right[line] = rs and rs:GetText()
            if text and text ~= "" then table.insert(texts, text) end
            if fs and type(fs.GetTextColor) == "function" then
                local red, green, blue = fs:GetTextColor()
                if red and green and blue then
                    eq.hasteSetActive[line] = not (red < .75 and green < .75 and blue < .75
                        and math.abs(red-green)<.05 and math.abs(green-blue)<.05)
                    if line==1 then snap.colors[slot]={red,green,blue} end
                end
            end
        end
        if GetInventoryItemLink(unit,slot) and eq.count==0 then snap.complete=false end
        snap.equipment[slot]=eq
        if table.getn(texts)>0 then
            snap.texts[slot]=texts; snap.count=snap.count+table.getn(texts)
        end
    end
end


-- 身上有没有穿着东西（判断「0 行」是真空身还是读不到）
local function HasGear(unit)
	if GetInventoryItemLink(unit, 1) then
		return true
	end
	if GetInventoryItemLink(unit, 16) then
		return true
	end
	return false
end

local function NewSnap(unit, sig)
	local now = GetTime()
	return {
		unit = unit,
		sig = sig,
		time = now,       -- 上次真正扫描的时刻（硬兜底用）
		checkTime = now,  -- 上次签名校验的时刻（同帧去重用）
		sigTime = now,    -- 上次签名校验的时刻（调试用）
		count = 0,        -- 抓到的文本行总数
		equipment = {},   -- raw line/right/color view shared by personal BCS and StatCompare
        complete = false,
        texts = {},       -- [slot] = { 行文本... }，空行已压缩掉
		colors = {},      -- [slot] = { r, g, b }，取自首行（物品名）的品质色
		bonus = nil,      -- [key] = 数值，首次 GetBonus / GetAllBonuses 时才填
		rulesDone = false,
	}
end

-- 扫描一轮。库不可用时（GS.BROKEN）返回 count=0 的空快照，
-- 消费方看到 count=0 就退回各自的旧扫描。
local function ScanUnit(unit, sig)
	local snap = NewSnap(unit, sig)

	-- 已判定本客户端上读不到 → 直接返回空快照，别每帧白扫 20 槽
	if GS.BROKEN then
		return snap
	end

	local gear = HasGear(unit)
	ScanPass(GS_Tooltip, GS_TOOLTIP_NAME, unit, snap)

	-- 自检 1：重新认领 owner 再试一次（SetOwner 会重建 tooltip 内部状态）
	if snap.count == 0 and gear then
		GS_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		ScanPass(GS_Tooltip, GS_TOOLTIP_NAME, unit, snap)
	end

	-- 自检 2：借用 BCS helper 自己那个 tooltip（原版装备扫描一直在用它，最可靠）。
	-- 成功就永久切过去，省掉后面每轮的重试。
	if snap.count == 0 and gear then
		local shared = getglobal(SHARED_NAME)
		if shared and shared ~= GS_Tooltip then
			shared:SetOwner(WorldFrame, "ANCHOR_NONE")
			ScanPass(shared, SHARED_NAME, unit, snap)
			if snap.count > 0 then
				GS_Tooltip = shared
				GS_TOOLTIP_NAME = SHARED_NAME
			end
		end
	end

	-- 自检 3：有装备却一行都读不到 → 标记不可用，让消费方退回自己的扫描
	if snap.count == 0 and gear then
		GS.BROKEN = true
		if DEFAULT_CHAT_FRAME and not GS.BROKEN_WARNED then
			GS.BROKEN_WARNED = true
			DEFAULT_CHAT_FRAME:AddMessage("|cffffd200BetterCharacterStats|r：共享采集层在当前客户端读不到物品 tooltip，" ..
				"已自动退回内置扫描（功能正常，性能恢复旧水平）。")
		end
	end

	GS.ScanCount = GS.ScanCount + 1
	-- 排查用：当前真正生效的 tooltip 名（/run print(GearStat.TooltipName)）
	GS.TooltipName = GS_TOOLTIP_NAME
	return snap
end


--==========================================================================
-- 对外接口
--==========================================================================

-- 取快照。装备没变就返回缓存（连 tooltip 都不碰）。
-- force = true 跳过一切校验，强制重扫。
--
-- ⚠️ 刻意**不对签名校验做时间节流**：GetSnapshot 的调用方是那 10 个 GetLive*
--    函数，它们本身已经被 BCS.CACHE_TTL(300s) + 事件失效挡在外面，真正跑到
--    这里一天也就几十次。节流省不下东西，却会留下「刚换装备 1 秒内还是旧值」
--    的错觉窗口（仿真里就是这么被抓出来的）。签名计算 = 20 次
--    GetInventoryItemLink + 拼接，比一次 tooltip 重建便宜两个数量级。
function GS:GetSnapshot(unit, force)
	unit = unit or ITEM_FRAME_UNIT
	if type(unit) ~= "string" then
		unit = ITEM_FRAME_UNIT
	end

	local snap = CACHE[unit]
	if snap and not force then
		local now = GetTime()
		-- 同帧也可能换装，复用前仍须比较完整装备签名。

		if (now - snap.time) < GS.CACHE_TTL_HARD and BuildSignature(unit) == snap.sig then
			snap.checkTime = now
			return snap
		end
	end

	local sig = BuildSignature(unit)
	snap = ScanUnit(unit, sig)
	if snap.complete and (snap.count > 0 or not GS.BROKEN) then
		CACHE[unit] = snap
	end
	return snap
end

-- 取单个汇总键，没有则返回 0
function GS:GetBonus(unit, key)
	local snap = self:GetSnapshot(unit)
	local bonus = EnsureBonuses(snap)
	local v = bonus[key]
	if v then
		return v
	end
	return 0
end

-- 取整张汇总表（只读，别就地改：它是快照的一部分，改了会污染后续消费者）
function GS:GetAllBonuses(unit)
	local snap = self:GetSnapshot(unit)
	return EnsureBonuses(snap)
end

-- 取某槽的原始行数组，没有该槽返回 nil
function GS:GetSlotTexts(unit, slot)
	local snap = self:GetSnapshot(unit)
	return snap.texts[slot]
end

-- 丢弃某单位的快照（下次取时重扫）
function GS:Invalidate(unit)
	CACHE[unit or ITEM_FRAME_UNIT] = nil
    GS.BROKEN = nil
end

function GS:InvalidateAll()
	CACHE = {}
    GS.BROKEN = nil
end

-- 调试：返回最近一次扫描的统计
function GS:GetDebugInfo()
	return GS.ScanCount
end

-- The collector is usable by either addon and owns gear-only invalidation.
GS.eventFrame = GS.eventFrame or CreateFrame("Frame")
GS.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
GS.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GS.eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" or (event == "UNIT_INVENTORY_CHANGED" and (not arg1 or arg1 == "player")) then
        GS:InvalidateAll()
    end
end)
