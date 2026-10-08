module 'aux.core.search_cache'

-- 搜索结果缓存系统
-- 避免重复扫描相同的查询

local T = require 'T'
local aux = require 'aux'

-- 缓存结构
local search_cache = {}
local cache_timestamp = {}
local CACHE_DURATION = 180  -- 缓存 3 分钟

-- 生成查询的哈希键
function generate_cache_key(filter_string, first_page, last_page)
	return filter_string .. '|' .. (first_page or '') .. '|' .. (last_page or '')
end

-- 获取缓存的搜索结果
function M.get_cached_results(filter_string, first_page, last_page)
	local cache_key = generate_cache_key(filter_string, first_page, last_page)
	local now = time()
	
	-- 检查缓存是否有效
	if search_cache[cache_key] and cache_timestamp[cache_key] then
		if now - cache_timestamp[cache_key] < CACHE_DURATION then
			aux.print('使用缓存的搜索结果 (' .. (now - cache_timestamp[cache_key]) .. '秒前)')
			return search_cache[cache_key]
		end
	end
	
	return nil
end

-- 缓存搜索结果
function M.cache_results(filter_string, first_page, last_page, results)
	local cache_key = generate_cache_key(filter_string, first_page, last_page)
	
	-- 复制结果（避免引用问题）
	local cached_results = T.acquire()
	for _, record in ipairs(results) do
		tinsert(cached_results, record)
	end
	
	search_cache[cache_key] = cached_results
	cache_timestamp[cache_key] = time()
end

-- 失效缓存
function M.invalidate_cache(filter_string)
	if filter_string then
		-- 失效特定查询的所有页面
		for cache_key in pairs(search_cache) do
			if strsub(cache_key, 1, strlen(filter_string)) == filter_string then
				T.release(search_cache[cache_key])
				search_cache[cache_key] = nil
				cache_timestamp[cache_key] = nil
			end
		end
	else
		-- 清空所有缓存
		for _, results in pairs(search_cache) do
			T.release(results)
		end
		wipe(search_cache)
		wipe(cache_timestamp)
	end
end

-- 清理过期缓存
function M.cleanup_expired()
	local now = time()
	local removed = 0
	
	for cache_key, timestamp in pairs(cache_timestamp) do
		if now - timestamp > CACHE_DURATION then
			T.release(search_cache[cache_key])
			search_cache[cache_key] = nil
			cache_timestamp[cache_key] = nil
			removed = removed + 1
		end
	end
	
	if removed > 0 then
		collectgarbage()  -- 触发垃圾回收
	end
	
	return removed
end

-- 获取缓存统计
function M.get_stats()
	local total = 0
	local expired = 0
	local total_records = 0
	local now = time()
	
	for cache_key, timestamp in pairs(cache_timestamp) do
		total = total + 1
		total_records = total_records + getn(search_cache[cache_key] or {})
		if now - timestamp > CACHE_DURATION then
			expired = expired + 1
		end
	end
	
	return {
		total_queries = total,
		expired_queries = expired,
		valid_queries = total - expired,
		total_records = total_records,
	}
end

-- 定期清理（每 60 秒）
local cleanup_timer = 0
function M.on_update()
	cleanup_timer = cleanup_timer + 1
	if cleanup_timer >= 60 then
		M.cleanup_expired()
		cleanup_timer = 0
	end
end
