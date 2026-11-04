module 'aux.core.scan'

local T = require 'T'
local aux = require 'aux'
local info = require 'aux.util.info'
local history = require 'aux.core.history'

local PAGE_SIZE = 50

-- 【极限提速 1】：缓存热路径全局函数
local GetTime = GetTime
local GetNumAuctionItems = GetNumAuctionItems
local GetAuctionItemInfo = GetAuctionItemInfo
local QueryAuctionItems = QueryAuctionItems
local GetBidderAuctionItems = GetBidderAuctionItems
local GetOwnerAuctionItems = GetOwnerAuctionItems
local UnitName = UnitName
local collectgarbage = collectgarbage
local tinsert = table.insert
local ceil = math.ceil
local max = math.max
local min = math.min
local fmod = math.mod
local floor = math.floor

local info_auction = info.auction
local history_process = history.process_auction_batch
local history_flush = history.flush_batch_updates

local aux_thread = aux.thread
local aux_kill_thread = aux.kill_thread
local aux_when = aux.when
local aux_later = aux.later
local aux_signal = aux.signal
local aux_event_listener = aux.event_listener
local aux_kill_listener = aux.kill_listener
local aux_place_bid = aux.place_bid
local aux_huge = aux.huge

function aux.handle.CLOSE()
	abort()
end

-- 【修复 1.06 遗留】冻结/解冻浏览列表 UI 抽成函数：
-- 原版只在 complete() 里解冻，扫描被 abort（关闭 AH、点取消、超时看门狗）时按钮会永久隐藏。
local browse_ui_saved
local function freeze_browse_ui(frozen)
    if frozen then
        if browse_ui_saved then return end
        browse_ui_saved = {}
        local widgets = { BrowseNoResultsText, BrowseSearchCountText }
        for i = 1, 15 do table.insert(widgets, _G["BrowseButton" .. i]) end
        for _, widget in pairs(widgets) do
            browse_ui_saved[widget] = widget:IsShown() and true or false
            widget:Hide()
        end
    elseif browse_ui_saved then
        for widget, shown in pairs(browse_ui_saved) do
            if shown then widget:Show() else widget:Hide() end
        end
        browse_ui_saved = nil
    end
end

do
	local scan_states = {}

	function M.start(params)
		local old_state = scan_states[params.type]
		if old_state then
			abort(old_state.id)
		end
		do (params.on_scan_start or pass)() end

		-- 冻结 UI
		if params.type == 'list' and AuctionFrame and AuctionFrame:IsShown() then
			freeze_browse_ui(true)
		end

		local thread_id = aux_thread(scan)
		scan_states[params.type] = {
			id = thread_id,
			params = params,
			gc_counter = 0,
			-- 【计时】扫描速度统计
			scan_started_at = GetTime(),
			page_count = 0,
			page_total = 0,
			page_max = 0,
			query_total = 0,
			query_wait_total = 0,
			retry_wait_total = 0,
			submit_count = 0,
		}
		return thread_id
	end

	function M.abort(scan_id)
		local aborted = T.acquire()
		for type, state in scan_states do
			if not scan_id or state.id == scan_id then
				if state.wait_listener then aux_kill_listener(state.wait_listener) end
				aux_kill_thread(state.id)
				scan_states[type] = nil
				tinsert(aborted, state)
			end
		end
		for _, state in aborted do
			-- 【修复】被 abort 的 list 扫描也要解冻，否则浏览列表按钮永久隐藏
			if state.params.type == 'list' then
				freeze_browse_ui(false)
			end
			do (state.params.on_abort or pass)() end
		end
	end

	function M.stop()
		get_state().stopped = true
	end

	function complete()
		local on_complete = get_state().params.on_complete
        if get_state().wait_listener then aux_kill_listener(get_state().wait_listener) end

		-- 解冻 UI（不看 AuctionFrame 是否显示，避免关框中止后按钮残留在隐藏状态）
		if get_state().params.type == 'list' then
			freeze_browse_ui(false)
		end

		-- 【计时】扫描结束打印速度统计
		report_scan_stats(get_state())

		scan_states[get_state().params.type] = nil
		do (on_complete or pass)() end
	end

	function get_state()
		for _, state in scan_states do
			if state.id == aux.thread_id() then
				return state
			end
		end
	end
end

function get_query()
	return get_state().params.queries[get_state().query_index]
end

function total_pages(total_auctions)
    return ceil(total_auctions / PAGE_SIZE)
end

function last_page(total_auctions)
    local last_page = max(total_pages(total_auctions) - 1, 0)
    local last_page_limit = get_query().blizzard_query.last_page or last_page
    return min(last_page_limit, last_page)
end

function scan()
    get_state().unique_prices, get_state().unique_count = {}, 0
	get_state().query_index = get_state().query_index and get_state().query_index + 1 or 1
	if get_query() and not get_state().stopped then
		do (get_state().params.on_start_query or pass)(get_state().query_index) end
		if get_query().blizzard_query then
			if (get_query().blizzard_query.first_page or 0) <= (get_query().blizzard_query.last_page or aux_huge) then
				get_state().page = get_query().blizzard_query.first_page or 0
				return submit_query()
			end
		else
			get_state().page = nil
			return scan_page()
		end
	end
	return complete()
end

do
	local function submit()
		get_state().submit_count = get_state().submit_count + 1
		if get_state().params.type == 'bidder' then
			GetBidderAuctionItems(get_state().page)
		elseif get_state().params.type == 'owner' then
			GetOwnerAuctionItems(get_state().page)
		else
			get_state().last_list_query = GetTime()
			local blizzard_query = get_query().blizzard_query or T.acquire()
			QueryAuctionItems(
				blizzard_query.name,
				blizzard_query.min_level,
				blizzard_query.max_level,
				blizzard_query.slot,
				blizzard_query.class,
				blizzard_query.subclass,
				get_state().page,
				blizzard_query.usable,
				blizzard_query.quality
			)
		end
		return wait_for_results()
	end
	function submit_query()
		if get_state().stopped then return end
        -- Preserve client throttling unless fast querying was explicitly selected.
		if get_state().params.type ~= 'list' or aux.account_data.scan_throttle == false then
			return submit()
		end
		if CanSendAuctionQuery() then
			return submit()
		end
		-- 【计时】节流等待：客户端不允许查询时在这里空等，单独计它的时间
		local requested_at = GetTime()
		return aux_when(CanSendAuctionQuery, function()
			get_state().query_wait_total = get_state().query_wait_total + (GetTime() - requested_at)
			return submit()
		end)
	end
end

-- 【极限提速 2】：将递归改为 for 循环，缓存所有热路径变量
function scan_page(i)
	i = i or 1
	local pages
	
	if i == 1 then
		local has_auto_action = false
		local items_processed = 0

		local state = get_state()
		local params = state.params
		local query = get_query()
		local blizzard_query = query.blizzard_query
		local validator = query.validator
		local auto_buy_validator = params.auto_buy_validator
		local auto_bid_validator = params.auto_bid_validator
		local on_auction = params.on_auction
		local on_progress = params.on_progress
		local ignore_owner = params.ignore_owner or aux.account_data.ignore_owner
		local query_type = params.type
		local read_only = params.read_only
		-- 【修复1】：去掉 or 20，全局扫描不传此参数时为 nil，不触发提前中断
		local max_unique_prices = read_only and tonumber(params.max_unique_prices)
        if max_unique_prices and max_unique_prices < 1 then max_unique_prices = nil end

		local player_name = UnitName("player")

		local unique_prices = state.unique_prices or {}
		local unique_count = state.unique_count or 0
		local early_abort = false

		if blizzard_query and state.page then
			pages = last_page(state.total_auctions)
		end
		
		for idx = 1, PAGE_SIZE do
			local auction_info = info_auction(idx, query_type)
			if auction_info and (auction_info.owner or ignore_owner) then
				auction_info.index = idx
				auction_info.page = state.page
				auction_info.blizzard_query = blizzard_query
				auction_info.query_type = query_type

				if not read_only then history_process(auction_info, pages) end

				-- 智能计数：统计不同的价格种类（仅在 max_unique_prices 有值时启用）
				if max_unique_prices and (not validator or validator(auction_info)) and auction_info.buyout_price > 0 and auction_info.owner ~= player_name then
					local price_key = auction_info.buyout_price .. '_' .. auction_info.aux_quantity
					if not unique_prices[price_key] then
						unique_prices[price_key] = true
						unique_count = unique_count + 1
						if unique_count >= max_unique_prices then
							early_abort = true
						end
					end
				end
				
				items_processed = items_processed + 1

				-- 【修复2】：进度回调加保护，防止 max_unique_prices 为 nil 时除零报错
				if on_progress and max_unique_prices then
					if fmod(items_processed, 5) == 0 then
						local ratio = unique_count / max_unique_prices
						on_progress(min(1, ratio))
					end
				end
				
				if (auto_buy_validator or pass)(auction_info) and auction_info.buyout_price > 0 and auction_info.owner ~= player_name then
					has_auto_action = true
				elseif (auto_bid_validator or pass)(auction_info) and auction_info.owner ~= player_name and auction_info.high_bidder == nil then
					has_auto_action = true
				elseif not validator or validator(auction_info) then
					do (on_auction or pass)(auction_info) end
				end
			end
		end
		
		if not read_only then history_flush() end
        state.unique_prices, state.unique_count = unique_prices, unique_count

		-- 最终进度更新（仅在 max_unique_prices 有值时）
		if on_progress and max_unique_prices then
			local ratio = unique_count / max_unique_prices
			on_progress(min(1, ratio))
		end
		
		if early_abort and not has_auto_action then
			i = PAGE_SIZE + 1
			state.early_abort = true
		elseif has_auto_action then
			i = 1
		else
			i = PAGE_SIZE + 1
		end
	end

	if i > PAGE_SIZE then
		local state = get_state()

		do (state.params.on_page_scanned or pass)() end

		if state.early_abort then
			return complete()
		end

		if get_query().blizzard_query and state.page < last_page(state.total_auctions) then
			state.page = state.page + 1
			return submit_query()
		else
			return scan()
		end
	end

	local auction_info = info_auction(i, get_state().params.type)
	if auction_info and (auction_info.owner or get_state().params.ignore_owner or aux.account_data.ignore_owner) then
		auction_info.index = i
		auction_info.page = get_state().page
		auction_info.blizzard_query = get_query().blizzard_query
		auction_info.query_type = get_state().params.type
		
		if (get_state().params.auto_buy_validator or pass)(auction_info) and auction_info.buyout_price > 0 and auction_info.owner ~= UnitName("player") then
			local send_signal, signal_received = aux_signal()
			aux_when(signal_received, scan_page, i)
			return aux_place_bid(auction_info.query_type, auction_info.index, auction_info.buyout_price, send_signal)
		elseif (get_state().params.auto_bid_validator or pass)(auction_info) and auction_info.owner ~= UnitName("player") and auction_info.high_bidder == nil then
			local send_signal, signal_received = aux_signal()
			aux_when(signal_received, scan_page, i)
			return aux_place_bid(auction_info.query_type, auction_info.index, auction_info.bid_price, send_signal)
		end
	end

	return scan_page(i + 1)
end

function wait_for_results()
    if get_state().params.type == 'bidder' then
        return aux_when(function() return aux.bids_loaded() end, accept_results)
    elseif get_state().params.type == 'owner' then
        return wait_for_owner_results()
    elseif get_state().params.type == 'list' then
        return wait_for_list_results()
    end
end

-- 【计时】每页：cycle = 上一页接受 → 本页接受；其中
--   query = 发出查询 → 本页接受（服务器往返）
--   wait  = 想发查询 → 客户端允许发（AH 自身节流，aux 控制不了）
--   本地  = cycle - query - wait（50 条处理 + UI 刷新 + 历史库写入）
function record_page_stats()
	local state = get_state()
	if not state or not state.scan_started_at then return end
	local now = GetTime()
	local cycle = now - (state.last_page_at or state.scan_started_at)
	state.last_page_at = now
	state.page_count = state.page_count + 1
	state.page_total = state.page_total + cycle
	if cycle > state.page_max then state.page_max = cycle end
	if state.last_list_query then
		state.query_total = state.query_total + (now - state.last_list_query)
	end
end

function report_scan_stats(state)
	if aux.account_data.scan_stats ~= true then return end
	if not state or not state.scan_started_at or (state.page_count or 0) == 0 then return end
	local pages = state.page_count
	local elapsed = GetTime() - state.scan_started_at
	local per_page = state.page_total / pages
	local wait_avg = (state.query_wait_total or 0) / pages
	local rtt_avg = (state.query_total or 0) / pages
	local retry_avg = (state.retry_wait_total or 0) / pages
	local local_avg = per_page - wait_avg - rtt_avg - retry_avg
	if local_avg < 0 then local_avg = 0 end
	aux.print(format(
		'扫描统计[%s%s%s] %d 页 / %.1f 秒 | 每页 %.2f = 节流 %.2f + 往返 %.2f + 重试 %.2f + 本地 %.2f | 提交 %.1f 次/页 | 最慢 %.2f 秒',
		tostring(state.params.type),
		state.early_abort and '·提前中止' or '',
		aux.account_data.scan_throttle ~= false and '·节流' or '',
		pages,
		elapsed,
		per_page,
		wait_avg,
		rtt_avg,
		retry_avg,
		local_avg,
		(state.submit_count or 0) / pages,
		state.page_max
	))
end

function accept_results()
	record_page_stats()
	_, get_state().total_auctions = GetNumAuctionItems(get_state().params.type)
	do
		(get_state().params.on_page_loaded or pass)(
			get_state().page - (get_query().blizzard_query.first_page or 0) + 1,
			last_page(get_state().total_auctions) - (get_query().blizzard_query.first_page or 0) + 1,
			total_pages(get_state().total_auctions) - 1
		)
	end
	return scan_page()
end

function wait_for_owner_results()
    local state = get_state()
    if state.page == aux.current_owner_page() then return accept_results() end
    local updated = false
    state.wait_listener = aux_event_listener('AUCTION_OWNED_LIST_UPDATE', function() updated = true end)
    local timeout = aux_later(5)
    return aux_when(function() return updated or timeout() end, function()
        aux_kill_listener(state.wait_listener); state.wait_listener = nil
        if not updated or state.page ~= aux.current_owner_page() then
            aux.print('已拍卖数据未能及时加载，扫描已终止。请刷新重试。')
            return abort(state.id)
        end
        return accept_results()
    end)
end

function wait_for_list_results()
    local state = get_state()
    local updated, last_update = false, nil
    state.wait_listener = aux_event_listener('AUCTION_ITEM_LIST_UPDATE', function()
        updated, last_update = true, GetTime()
    end)
    local fast = aux.account_data.scan_throttle == false
    local timeout = aux_later(fast and .4 or 2, state.last_list_query)
    local deadline = aux_later(5, state.last_list_query)
    local ignore_owner = state.params.ignore_owner or aux.account_data.ignore_owner
    return aux_when(function()
        if not last_update then return timeout() end
        if updated and (ignore_owner or owner_data_sufficient()) then return true end
        return GetTime() - last_update > 1.5 or deadline()
    end, function()
        aux_kill_listener(state.wait_listener); state.wait_listener = nil
        if not last_update then
            local page_key = tostring(state.query_index) .. ':' .. tostring(state.page)
            if state.retry_page ~= page_key then state.retry_page, state.retries = page_key, 0 end
            state.retries = state.retries + 1
            if state.retries >= (fast and 5 or 3) then
                aux.print('拍卖查询未收到结果，扫描已终止。请刷新重试。')
                return abort(state.id)
            end
            state.retry_wait_total = state.retry_wait_total + GetTime() - state.last_list_query
            return submit_query()
        end
        state.retries = 0
        return accept_results()
    end)
end

-- Keep the personal scan's seller-completeness gate for normal full scans.
function owner_data_sufficient()
	local total_count = 0
	local valid_count = 0
	
    for i = 1, PAGE_SIZE do
        local auction_info = info.auction(i, 'list')
        if auction_info then
	        total_count = total_count + 1
	        if auction_info.owner then
		        valid_count = valid_count + 1
	        end
        end
    end
    
    -- 如果没有数据，返回 false
    if total_count == 0 then
	    return false
    end
    
    -- TSM 风格：至少 80% 的数据有卖家信息就认为足够了
    return (valid_count / total_count) >= 0.8
end

-- 保留原始的 100% 完整性检查（备用）
function owner_data_complete()
    for i = 1, PAGE_SIZE do
        local auction_info = info.auction(i, 'list')
        if auction_info and not auction_info.owner then
	        return false
        end
    end
    return true
end