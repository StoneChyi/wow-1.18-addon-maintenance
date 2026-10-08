module 'aux.util.temptable'

-- TSM 风格的临时表对象池
-- 减少 GC 压力，提高性能

local pool = {}
local pool_size = 0
local MAX_POOL_SIZE = 100  -- 最多缓存 100 个表

-- 从池中获取一个表
function M.acquire()
	if pool_size > 0 then
		local t = pool[pool_size]
		pool[pool_size] = nil
		pool_size = pool_size - 1
		return t
	else
		return {}
	end
end

-- 归还表到池中
function M.release(t)
	if not t then return end
	
	-- 清空表
	wipe(t)
	
	-- 如果池未满，归还
	if pool_size < MAX_POOL_SIZE then
		pool_size = pool_size + 1
		pool[pool_size] = t
	end
end

-- 批量释放多个表
function M.release_all(...)
	for i = 1, arg.n do
		M.release(arg[i])
	end
end

-- 获取池的统计信息
function M.get_stats()
	return {
		pool_size = pool_size,
		max_size = MAX_POOL_SIZE,
		usage = pool_size / MAX_POOL_SIZE * 100
	}
end

-- 清空池（用于调试）
function M.clear_pool()
	wipe(pool)
	pool_size = 0
end
