-- Cat针对免疫各种属性库

--- 检验单位能否流血
--- unit对象，默认为目标
--- return boolean can 能流血返回真，否则返回假
MPmonsterList = {

    -- 木喉
    ["裂地者欧曼诺斯"] = true,
    ["欧曼诺斯的颤岩"] = true,

	-- K40
    ["地狱之怒碎片"] = true,
    ["噩梦爬行者"] = true,
    ["麦迪文的回响"] = true,
    ["恶魔之心"] = true,
    ["战争使者监军"] = true,
    ["兵卒"] = true,
    ["共鸣水晶"] = true,
    ["徘徊的魔法师"] = true,
    ["徘徊的占星家"] = true,
    ["徘徊的魔术师"] = true,
    ["徘徊的工匠"] = true,
    ["鬼灵训练师"] = true,
    ["荒芜的入侵者"] = true,

	-- 卡拉赞下层
    ["幻影守卫"] = true,
    ["幽灵厨师"] = true,
    ["闹鬼铁匠"] = true,
    ["幻影仆从"] = true,
    ["莫罗斯"] = true,

	-- NAXX
    ["瘟疫战士"] = true,
    ["白骨构造体"] = true,
    ["邪恶之斧"] = true,
    ["邪恶法杖"] = true,
    ["邪恶之剑"] = true,
    ["纳克萨玛斯之魂"] = true,
    ["纳克萨玛斯之影"] = true,
    ["憎恨吟唱者"] = true,
    ["死灵骑士"] = true,
    ["死灵骑士卫兵"] = true,
    ["骷髅骏马"] = true,

	-- TAQ

    -- 黑龙
    ["奥妮克希亚火嗣"] = true,

    -- FX
    ["莫阿姆"] = true,

	-- MC
    ["熔核巨人"] = true,
    ["暗炉卫士"] = true,
    ["暗炉织焰者"] = true,
    ["暗炉圣职者"] = true,
    ["法师领主索瑞森"] = true,
    ["巫王索瑞森"] = true,
    ["熔核摧毁者"] = true,

	-- STSM
    ["安娜丝塔丽男爵夫人"] = true,
    ["埃提耶什"] = true,

    -- 龙吼居所
    ["被遗忘的先祖"] = true,
    ["哈尔甘·红标"] = true,

    -- 黑石深渊
    ["弗莱拉斯大使"] = true,
    ["安格雷尔"] = true,
    ["西斯雷尔"] = true,
    ["多普雷尔"] = true,
    ["格鲁雷尔"] = true,
    ["瓦勒雷尔"] = true,
    ["黑特雷尔"] = true,
    ["杜姆雷尔"] = true,
    ["玛格姆斯"] = true,

	-- 玛拉顿
    ["瑟莱德丝公主"] = true,

	-- 暴风城地牢
    ["戴米安"] = true,

	-- 其他
    ["黑衣守卫斥候"] = true,
    ["哀嚎的女妖"] = true,
    ["尖叫的女妖"] = true,
    ["无眼观察者"] = true,
    ["黑暗法师"] = true,
    ["幽灵训练师"] = true,
    ["受难的上层精灵"] = true,
    ["死亡歌手"] = true,
    ["恐怖编织者"] = true,
    ["哀嚎的死者"] = true,
    ["亡鬼幻象"] = true,
    ["恐惧骸骨"] = true,
    ["骷髅刽子手"] = true,
    ["骷髅剥皮者"] = true,
    ["骷髅守护者"] = true,
    ["骷髅巫师"] = true,
    ["骷髅军官"] = true,
    ["骷髅侍僧"] = true,
    ["游荡的骷髅"] = true,
    ["骷髅铁匠"] = true,
    ["鬼魅随从"] = true,
    ["艾德雷斯妖灵"] = true,
    ["天灾勇士"] = true,
    ["天灾卫兵"] = true,
    ["不安宁的阴影"] = true,
    ["不死的看守者"] = true,
    ["哀嚎的鬼怪"] = true,
    ["被诅咒的灵魂"] = true,
    ["不死的居民"] = true,
    ["不死的看守者"] = true,
    ["幽灵工人"] = true,
    ["鬼灵工人"] = true,
    ["徘徊的农夫"] = true,
    ["被诅咒的水兵"] = true,
    ["峭壁咆哮者"] = true,
    ["峭壁行者"] = true,
    ["峭壁击碎者"] = true,
}

-- 元素生物,机械中的白名单列表
MPmonsterWhiteList = {

	-- K40
    ["失控的骑士"] = true,

	-- MC
    ["加尔"] = true,
    ["焚化者古雷曼格"] = true,
    ["巴萨尔萨"] = true,
    ["斯摩达利斯"] = true,

	-- 玛拉顿
	["锐刺鞭笞者"] = true,

	-- World
    ["灌木塑根者"] = true,
    ["灌木露水收集者"] = true,
    ["长瘤的灌木兽"] = true,
    ["焦油潜伏者"] = true,
    ["焦油爬行者"] = true,
    ["焦油兽王"] = true,
    ["焦油兽"] = true,
}

function MPCanBleed(unit)
	unit = unit or "target"
	local name = UnitName(unit)

	if not name then
		return false
	end

	-- 元素生物,机械，直接认定为不可流血
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("元素生物,机械", creature)
	if position then
		-- 元素生物与机械中的白名单
		if MPmonsterWhiteList[name] == true then
			return true
		end
		return false
	end

	-- 判断怪物名单
	if MPmonsterList[name] == true then
		return false
	end

	return true
end

--- 检验单位是否为BOSS级别
--- return boolean can 返回真，否则返回假
function MPIsBossTarget()
    if not UnitExists("target") then return false end
    
    -- 检查精英标志(骷髅级)
    if UnitClassification("target") == "worldboss" or 
       UnitClassification("target") == "rareelite" then
        return true
    end
    
    -- 检查血量（普通BOSS通常血量远高于玩家）
    local healthMax = UnitHealthMax("target")
    if healthMax > 300000 then
        return true
    end
    
    -- 检查已知BOSS名字
    local bossList = {
        ["克尔苏加德"] = true,
        ["拉格纳罗斯"] = true,
    }
    if bossList[UnitName("target")] then
        return true
    end
    
    return false
end



-- 吸血黑名单
MPDrainBlcokList = {
	-- TAQ
    ["维克洛尔大帝"] = true,
    ["维克尼拉斯大帝"] = true,

	-- test
    --["学徒训练假人"] = true,
}

-- 检测单位是否可以吸血
--- return boolean can 返回真，否则返回假
function MPIsDrain(unit)
	unit = unit or "target"
	local name = UnitName(unit)

	if not name then
		return false
	end

	-- 机械，直接认定为不可吸血
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("机械", creature)
	if position then
		return false
	end

	-- 判断怪物名单
	if MPDrainBlcokList[name] == true then
		return false
	end

	return true
end


MPPosionBlcokList = {
	-- TAQ
    ["维克洛尔大帝"] = true,
    ["维克尼拉斯大帝"] = true,

    -- 世界

}

-- 检测单位是否可以中毒
--- return boolean can 返回真，否则返回假
function MPIsPosion(unit)
	unit = unit or "target"

	-- 机械、元素，直接认定为不可中毒
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("元素生物,机械", creature)
	if position then
		return false
	end

	-- 判断不吃毒名单
	local name = UnitName(unit)
	if MPPosionBlcokList[name] == true then
		return false
	end

	return true
end



-- 精灵之火黑名单
MPFaerieFireBlcokList = {

    -- 木喉
    ["被污染的胶团"] = true,

	-- NAXX
    ["鬼灵训练师"] = true,
    ["鬼灵坐骑"] = true,
    ["鬼灵骑兵"] = true,

	-- TAQ
    ["维克洛尔大帝"] = true,
    ["维克尼拉斯大帝"] = true,

    -- BWL
    ["黑翼缚法者"] = true,

	-- 神庙
    ["德拉维沃尔"] = true,

	-- 世界BOSS
    ["桑德兰王子"] = true,

    -- 世界
    ["熔岩元素"] = true,
    ["涅玛丝拉"] = true,
    ["雷霆流放者"] = true,
    ["狂风漩涡"] = true,

    -- 黑石深渊
    ["达格兰·索瑞森大帝"] = true,

	-- test
    --["学徒训练假人"] = true,
}

-- 检测单位是否吃精灵之火
--- return boolean can 返回真，否则返回假
function MPIsFaerieFire(unit)
	unit = unit or "target"
	local name = UnitName(unit)

	if not name then
		return false
	end

	-- 判断精灵之火名单
	if MPFaerieFireBlcokList[name] == true then
		return false
	end

	return true
end


-- 猎人印记黑名单
MPHunterMarkBlcokList = {

	-- K40
    ["阿诺玛鲁斯"] = true,

	-- TAQ
    ["维克洛尔大帝"] = true,
    ["维克尼拉斯大帝"] = true,
}

-- 检测单位是否吃猎人印记
--- return boolean can 返回真，否则返回假
function MPIsHunterMark(unit)
	unit = unit or "target"
	local name = UnitName(unit)

	if not name then
		return false
	end

	-- 判断猎人印记名单
	if MPHunterMarkBlcokList[name] == true then
		return false
	end

	return true
end



-- 奥术射击黑名单
MPHunterArcaneShotBlcokList = {
	-- K40
    ["阿诺玛鲁斯"] = true,

	-- TAQ
    ["维克洛尔大帝"] = true,
    ["维克尼拉斯大帝"] = true,
}

-- 检测单位是否吃奥术射击
--- return boolean can 返回真，否则返回假
function MPIsHunterArcaneShot(unit)
	unit = unit or "target"
	local name = UnitName(unit)

	if not name then
		return false
	end

	-- 判断奥术射击名单
	if MPHunterArcaneShotBlcokList[name] == true then
		return false
	end

	return true
end









-- iCerHe 修改部分
-- 火焰免疫检测相关变量和功能

-- 火焰免疫怪物静态名单
MPFireImmuneList = {
    -- 野外
    ["地狱元素"] = true,
    
    -- 黑翼之巢
    ["堕落的瓦拉斯塔兹"] = true,
    ["奈法利安"] = true,
    
    -- MC
    ["拉格纳罗斯"] = true,
    ["迦顿男爵"] = true,
    ["焚化者古雷曼格"] = true,
    ["火焰行者"] = true,
    ["火焰之王"] = true,
    
    -- 黑龙
    ["奥妮克希亚"] = true,
}

-- 动态缓存（持久化保存）
local MPFireImmuneCache = {}

-- 测试队列（临时数据，不持久化）
local MPFireImmuneTestQueue = {}
local MPFireImmuneTestCooldown = {}

-- 初始化火焰免疫缓存（持久化）
function MPInitFireImmuneCache()
    if not MPPublicSaved then
        MPPublicSaved = {}
    end
    
    if not MPPublicSaved.FireImmuneCache then
        MPPublicSaved.FireImmuneCache = {}
    end
    
    -- 使用持久化保存的数据
    MPFireImmuneCache = MPPublicSaved.FireImmuneCache
    
    -- 调试信息
    if MPCatDebug == 1 then
        local count = 0
        for _ in pairs(MPFireImmuneCache) do
            count = count + 1
        end
        MPMsg("加载了 " .. count .. " 条火焰免疫缓存数据")
    end
end

-- 更新缓存并同步到持久化存储
local function UpdateFireImmuneCache(monsterName, immuneData)
    MPFireImmuneCache[monsterName] = immuneData
    MPPublicSaved.FireImmuneCache[monsterName] = immuneData
    
    if MPCatDebug == 1 then
        local status = immuneData.immune and "火焰免疫" or "可受火焰伤害"
        MPMsg("更新缓存: " .. monsterName .. " - " .. status)
    end
end

-- 火焰免疫检测事件处理
function CheckFireImmuneFromCombat(str)
    -- 检测免疫消息 - 修正日志解析
    if string.find(str, "免疫") or string.find(str, "IMMUNE") then
        local targetName = nil
        
        -- 处理 "你的技能施放失败。目标对此免疫" 格式
        targetName = MPMatch(str, "施放失败。(.-)对此免疫")
        
        -- 处理 "目标免疫了你的技能" 格式
        if not targetName then
            targetName = MPMatch(str, "(.-)免疫了")
        end
        
        -- 处理 "目标免疫" 格式
        if not targetName then
            targetName = MPMatch(str, "(.-)免疫")
        end
        
        -- 处理 "对目标造成...免疫" 格式
        if not targetName then
            targetName = MPMatch(str, "对(.-)造成.*免疫")
        end
        
        if targetName then
            -- 检查是否为火焰技能免疫
            if string.find(str, "烈焰震击") or string.find(str, "熔岩爆裂") then
                
                UpdateFireImmuneCache(targetName, {
                    immune = true,
                    timestamp = GetTime(),
                    confidence = "confirmed",
                    source = "combat_log"
                })
                
                MPMsg("检测到 " .. targetName .. " 火焰免疫")
            end
        end
    end
end

-- 动态检测火焰免疫
function MPDetectFireImmune(unit)
    unit = unit or "target"
    local unitName = UnitName(unit)
    
    if not unitName then
        return false
    end
    
    -- 检查缓存
    local cacheEntry = MPFireImmuneCache[unitName]
    if cacheEntry then
        if cacheEntry.immune then
            return true
        elseif cacheEntry.resist_count and cacheEntry.resist_count >= 3 then
            return true
        end
    end
    
    -- 检查测试冷却时间
    if MPFireImmuneTestCooldown[unitName] and 
       GetTime() - MPFireImmuneTestCooldown[unitName] < 30 then
        return false -- 30秒内不重复测试同一目标
    end
    
    -- 检查是否可以进行测试
    if MPInCombat and UnitCanAttack("player", unit) and MPGetTargetDistance(unit) then
        
        -- 如果是萨满，尝试用烈焰震击测试
        if MPPlayerClass == "SHAMAN" then
            if MPSpellReady("烈焰震击") and UnitMana("player") >= 50 then
                -- 记录测试
                MPFireImmuneTestQueue[unitName] = {
                    spell = "烈焰震击",
                    timestamp = GetTime(),
                    unit = unit
                }
                MPFireImmuneTestCooldown[unitName] = GetTime()
                
                -- 施放技能进行测试
                CastSpellByName("烈焰震击")
                MPMsg("正在测试 " .. unitName .. " 的火焰免疫...")
                return false
            end
        end
    end
    
    return false
end

-- 完整的火焰免疫检测函数 - 修正调试信息
function MPIsFireImmune(unit)
    unit = unit or "target"
    local name = UnitName(unit)
    
    if not name then
        return false
    end
    
    if MPCatDebug == 1 then
        MPMsg("检查 " .. name .. " 的火焰免疫状态...")
    end
    
    -- 1. 首先检查静态名单
    if MPFireImmuneList[name] == true then
        if MPCatDebug == 1 then
            MPMsg(name .. " 在静态免疫名单中")
        end
        return true
    end
    
    -- 3. 动态检测
    return MPDetectFireImmune(unit)
end


function MPCanBurnByFire(unit)
    return not MPIsFireImmune(unit)
end

-- 显示火焰免疫缓存的调试命令
function MPShowFireImmuneCache()
    if not MPFireImmuneCache then
        MPMsg("火焰免疫缓存为空")
        return
    end
    
    local count = 0
    MPMsg("=== 火焰免疫缓存数据 ===")
    for name, data in pairs(MPFireImmuneCache) do
        count = count + 1
        local immuneText = data.immune and "火焰免疫" or "可受火焰伤害"
        local timeAgo = GetTime() - (data.timestamp or 0)
        local confidence = data.confidence or "unknown"
        
        MPMsg(string.format("%s: %s (%s, %.1f秒前)", 
            name, immuneText, confidence, timeAgo))
        
        if data.resist_count then
            MPMsg(string.format("  抵抗次数: %d", data.resist_count))
        end
    end
    
    if count == 0 then
        MPMsg("缓存为空")
    else
        MPMsg(string.format("总计: %d 条记录", count))
    end
    MPMsg("========================")
end

-- 清空火焰免疫缓存的命令
function MPClearFireImmuneCache()
    if MPPublicSaved and MPPublicSaved.FireImmuneCache then
        MPPublicSaved.FireImmuneCache = {}
        MPFireImmuneCache = {}
        MPMsg("火焰免疫缓存已清空")
    end
end


-- 自然免疫怪物静态名单
MPNatureImmuneList = {
    ["测试怪物"] = true,
}

-- 动态自然免疫缓存（持久化保存）
local MPNatureImmuneCache = {}

-- 自然免疫测试队列（临时数据，不持久化）
local MPNatureImmuneTestQueue = {}
local MPNatureImmuneTestCooldown = {}

-- 初始化自然免疫缓存（持久化）
function MPInitNatureImmuneCache()
    if not MPPublicSaved then
        MPPublicSaved = {}
    end
    
    -- 初始化自然免疫缓存
    if not MPPublicSaved.NatureImmuneCache then
        MPPublicSaved.NatureImmuneCache = {}
    end
    MPNatureImmuneCache = MPPublicSaved.NatureImmuneCache
    
    -- 调试信息
    if MPCatDebug == 1 then
        local natureCount = 0
        for _ in pairs(MPNatureImmuneCache) do
            natureCount = natureCount + 1
        end
        MPMsg("加载了 " .. natureCount .. " 条自然免疫缓存")
    end
end

-- 更新自然免疫缓存并同步到持久化存储
local function UpdateNatureImmuneCache(monsterName, immuneData)
    MPNatureImmuneCache[monsterName] = immuneData
    MPPublicSaved.NatureImmuneCache[monsterName] = immuneData
    
    if MPCatDebug == 1 then
        local status = immuneData.immune and "自然免疫" or "可受自然伤害"
        MPMsg("更新缓存: " .. monsterName .. " - " .. status)
    end
end

-- 自然免疫检测事件处理
function CheckNatureImmuneFromCombat(str)
    -- 检测免疫消息
    if string.find(str, "免疫") or string.find(str, "IMMUNE") then
        local targetName = nil
        
        -- 处理各种免疫消息格式
        targetName = MPMatch(str, "施放失败。(.-)对此免疫")
        if not targetName then
            targetName = MPMatch(str, "(.-)免疫了")
        end
        if not targetName then
            targetName = MPMatch(str, "(.-)免疫")
        end
        if not targetName then
            targetName = MPMatch(str, "对(.-)造成.*免疫")
        end
        
        if targetName then
            -- 检查是否为自然技能免疫
            if string.find(str, "闪电链") or string.find(str, "闪电箭") or 
               string.find(str, "地震术") or string.find(str, "大地震击") then
                
                UpdateNatureImmuneCache(targetName, {
                    immune = true,
                    timestamp = GetTime(),
                    confidence = "confirmed",
                    source = "combat_log"
                })
                
                MPMsg("检测到 " .. targetName .. " 自然免疫")
            end
        end
    end
end

-- 动态检测自然免疫
function MPDetectNatureImmune(unit)
    unit = unit or "target"
    local unitName = UnitName(unit)
    
    if not unitName then
        return false
    end
    
    -- 检查缓存
    local cacheEntry = MPNatureImmuneCache[unitName]
    if cacheEntry then
        if cacheEntry.immune then
            return true
        end
    end

    return false
end

-- 完整的自然免疫检测函数
function MPIsNatureImmune(unit)
    unit = unit or "target"
    local name = UnitName(unit)
    
    if not name then
        return false
    end
    
    if MPCatDebug == 1 then
        MPMsg("检查 " .. name .. " 的自然免疫状态...")
    end
    
    -- 1. 首先检查静态名单
    if MPNatureImmuneList[name] == true then
        if MPCatDebug == 1 then
            MPMsg(name .. " 在静态自然免疫名单中")
        end
        return true
    end
    
    -- 3. 动态检测
    return MPDetectNatureImmune(unit)
end

-- 检测单位是否可以被自然伤害（与MPCanBleed函数类似）
function MPCanBeDamagedByNature(unit)
    return not MPIsNatureImmune(unit)
end

-- 显示自然免疫缓存的调试命令
function MPShowNatureImmuneCache()
    if not MPNatureImmuneCache then
        MPMsg("自然免疫缓存为空")
        return
    end
    
    local count = 0
    MPMsg("=== 自然免疫缓存数据 ===")
    for name, data in pairs(MPNatureImmuneCache) do
        count = count + 1
        local immuneText = data.immune and "自然免疫" or "可受自然伤害"
        local timeAgo = GetTime() - (data.timestamp or 0)
        local confidence = data.confidence or "unknown"
        
        MPMsg(string.format("%s: %s (%s, %.1f秒前)", 
            name, immuneText, confidence, timeAgo))
        
        if data.resist_count then
            MPMsg(string.format("  抵抗次数: %d", data.resist_count))
        end
    end
    
    if count == 0 then
        MPMsg("缓存为空")
    else
        MPMsg(string.format("总计: %d 条记录", count))
    end
    MPMsg("========================")
end

-- 清空自然免疫缓存的命令
function MPClearNatureImmuneCache()
    if MPPublicSaved and MPPublicSaved.NatureImmuneCache then
        MPPublicSaved.NatureImmuneCache = {}
        MPNatureImmuneCache = {}
        MPMsg("自然免疫缓存已清空")
    end
end

-- 显示所有免疫缓存的命令
function MPShowAllImmuneCache()
    MPMsg("=== 所有免疫缓存数据 ===")
    MPShowFireImmuneCache()
    MPShowNatureImmuneCache()
end

-- 清空所有免疫缓存的命令
function MPClearAllImmuneCache()
    MPClearFireImmuneCache()
    MPClearNatureImmuneCache()
    MPMsg("已清空所有免疫缓存")
end