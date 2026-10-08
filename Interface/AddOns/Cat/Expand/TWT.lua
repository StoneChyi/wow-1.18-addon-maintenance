-- -------------------------------------
-- 乌龟服 - 轻量仇恨兼容入口
-- 更新日期：2026-06-30 
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
-- -------------------------------------
--



function MPGetHatredFromTWT()
	-- 保留旧函数名，内部改用四个 Cat 插件共享的 CatThreatLite。
	-- 暂无有效目标/队伍数据时返回 -1，维持既有职业模块的后备行为。
	if CatThreatLite and type(CatThreatLite.GetPercent) == "function" then
		local percent = CatThreatLite.GetPercent()
		if percent ~= nil then
			return math.floor(percent + 0.5)
		end
	end
	return -1

end





