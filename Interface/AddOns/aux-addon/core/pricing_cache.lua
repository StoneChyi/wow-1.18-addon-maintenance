module 'aux.core.pricing_cache'

-- TSM 风格的定价缓存系统
-- 避免重复计算，提高上架速度

local aux = require 'aux'
local history = require 'aux.core.history'
local disenchant = require 'aux.core.disenchant'

-- 缓存结构
local price_cache = {}
local cache_timestamp = {}
local CACHE_DURATION = 300  -- 缓存 5 分钟

-- 获取缓存的定价
function M.get_cached_price(item_key, item_info)
	local now = time()
	
	-- 检查缓存是否有效
	if price_cache[item_key] and cache_timestamp[item_key] then
		if now - cache_timestamp[item_key] < CACHE_DURATION then
			return price_cache[item_key]
		end
	end
	
	-- 计算新价格
	local prices = calculate_prices(item_key, item_info)
	
	-- 缓存结果
	price_cache[item_key] = prices
	cache_timestamp[item_key] = now
	
	return prices
end

-- 计算价格（优化后的算法）
function calculate_prices(item_key, item_info)
	local prices = {
		market_value = history.market_value(item_key),
		historical_value = history.value(item_key),
		vendor_price = get_vendor_price(item_info),
		disenchant_value = get_disenchant_value(item_info),
	}
	
	-- 计算建议价格
	prices.suggested_start = calculate_start_price(prices)
	prices.suggested_buyout = calculate_buyout_price(prices)
	
	return prices
end

-- 获取商人价格
function get_vendor_price(item_info)
	if aux.account_data.merchant_buy[item_info.item_id] then
		local tmp = tostring(aux.account_data.merchant_buy[item_info.item_id])
		return tonumber(strsub(tmp, 1, -3))
	elseif aux.account_data.merchant_sell[item_info.item_id] then
		return tonumber(aux.account_data.merchant_sell[item_info.item_id])
	elseif ShaguTweaks and ShaguTweaks.SellValueDB[item_info.item_id] then
		local charges = 1
		if item_info.max_charges then
			charges = item_info.max_charges
		end
		return ShaguTweaks.SellValueDB[item_info.item_id] / charges
	end
	return 0
end

-- 获取分解价值
function get_disenchant_value(item_info)
	if item_info.slot and item_info.quality and item_info.level then
		return disenchant.value(item_info.slot, item_info.quality, item_info.level, item_info.item_id)
	end
	return nil
end

-- 计算起拍价
function calculate_start_price(prices)
	local start_price = 0
	
	-- 优先使用市场价
	if prices.market_value then
		start_price = max(start_price, prices.market_value - 1)
	end
	
	-- 考虑历史价格
	if prices.historical_value then
		start_price = max(start_price, prices.historical_value * 0.8)
	end
	
	-- 考虑商人价格
	if prices.vendor_price > 0 then
		if prices.market_value then
			start_price = max(start_price, prices.vendor_price * 1.35)
		else
			start_price = max(start_price, prices.vendor_price * (1.35 + 3.65 * math.exp(-(1/4000) * prices.vendor_price)))
		end
	end
	
	-- 考虑分解价值
	if prices.disenchant_value then
		start_price = max(start_price, prices.disenchant_value * 0.85)
	end
	
	return start_price
end

-- 计算一口价
function calculate_buyout_price(prices)
	local buyout_price = 0
	
	-- 优先使用市场价
	if prices.market_value then
		buyout_price = max(buyout_price, prices.market_value)
	end
	
	-- 考虑历史价格
	if prices.historical_value then
		if prices.market_value then
			buyout_price = max(buyout_price, prices.historical_value * 0.5)
		else
			buyout_price = max(buyout_price, prices.historical_value * 0.95)
		end
	end
	
	-- 考虑商人价格
	if prices.vendor_price > 0 then
		buyout_price = max(buyout_price, prices.vendor_price * 1.15)
	end
	
	return buyout_price
end

-- 失效缓存
function M.invalidate_cache(item_key)
	if item_key then
		price_cache[item_key] = nil
		cache_timestamp[item_key] = nil
	else
		-- 清空所有缓存
		wipe(price_cache)
		wipe(cache_timestamp)
	end
end

-- 清理过期缓存
function M.cleanup_expired()
	local now = time()
	local removed = 0
	
	for item_key, timestamp in pairs(cache_timestamp) do
		if now - timestamp > CACHE_DURATION then
			price_cache[item_key] = nil
			cache_timestamp[item_key] = nil
			removed = removed + 1
		end
	end
	
	return removed
end

-- 获取缓存统计
function M.get_stats()
	local total = 0
	local expired = 0
	local now = time()
	
	for item_key, timestamp in pairs(cache_timestamp) do
		total = total + 1
		if now - timestamp > CACHE_DURATION then
			expired = expired + 1
		end
	end
	
	return {
		total = total,
		expired = expired,
		valid = total - expired,
	}
end
