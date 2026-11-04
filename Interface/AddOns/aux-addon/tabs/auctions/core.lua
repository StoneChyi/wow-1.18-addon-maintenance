module 'aux.tabs.auctions'

local T = require 'T'
local aux = require 'aux'
local scan_util = require 'aux.util.scan'
local scan = require 'aux.core.scan'

local tab = aux.tab '已拍卖'

auction_records = T.acquire()

-- 【兜底策略】扫描看门狗：若扫描超过 MAX_SCAN_SECONDS 仍未完成则强制终止，避免部分玩家卡死在扫描中
local MAX_SCAN_SECONDS = 30
local scan_started_at = nil
local active_scan_id = nil

function tab.OPEN()
    frame:Show()
    scan_auctions()
end

function tab.CLOSE()
    frame:Hide()
end

function update_listing()
    listing:SetDatabase(auction_records)
end

function M.scan_auctions()

    status_bar:update_status(0, 0)
    status_bar:set_text('扫描拍卖...')

    T.wipe(auction_records)
    update_listing()

    scan_started_at = GetTime()
    active_scan_id = scan.start{
        type = 'owner',
        queries = {{blizzard_query = T.acquire()}},
        on_page_loaded = function(page, total_pages)
            scan_started_at = GetTime() -- 每页刷新计时，避免大列表被误杀
            status_bar:update_status(page / total_pages, 0)
            status_bar:set_text(format('扫描中 （第 %d/%d 页）', page, total_pages))
        end,
        on_auction = function(auction_record)
            tinsert(auction_records, auction_record)
        end,
        on_complete = function()
            scan_started_at = nil
            active_scan_id = nil
            status_bar:update_status(1, 1)
            status_bar:set_text('扫描完成')
            update_listing()
        end,
        on_abort = function()
            scan_started_at = nil
            active_scan_id = nil
            status_bar:update_status(1, 1)
            status_bar:set_text('扫描终止')
        end,
    }
end

do
    local scan_id = 0
    local IDLE, SEARCHING, FOUND = aux.enum(3)
    local state = IDLE
    local found_index

    function find_auction(record)
        if not listing:ContainsRecord(record) then return end

        scan.abort(scan_id)
        state = SEARCHING
        scan_id = scan_util.find(
            record,
            status_bar,
            function() state = IDLE end,
            function() state = IDLE; listing:RemoveAuctionRecord(record) end,
            function(index)
                state = FOUND
                found_index = index

                cancel_button:SetScript('OnClick', function()
                    if scan_util.test(record, index) and listing:ContainsRecord(record) then
                        aux.cancel_auction(index, function() listing:RemoveAuctionRecord(record) end)
                    end
                end)
                cancel_button:Enable()
            end
        )
    end

    function on_update()
        -- 【兜底策略】扫描看门狗：超时强制终止，防止卡死
        if scan_started_at and (GetTime() - scan_started_at) > MAX_SCAN_SECONDS then
            if active_scan_id then
                scan.abort(active_scan_id)
            end
            scan_started_at = nil
            active_scan_id = nil
            status_bar:update_status(1, 1)
            status_bar:set_text('扫描超时，已终止（可点击刷新重试）')
            aux.print('已拍卖扫描超时，已自动终止。点击刷新按钮重试。')
        end

        if state == IDLE or state == SEARCHING then
            cancel_button:Disable()
        end

        if state == SEARCHING then return end

        local selection = listing:GetSelection()
        if not selection then
            state = IDLE
        elseif selection and state == IDLE then
            find_auction(selection.record)
        elseif state == FOUND and not scan_util.test(selection.record, found_index) then
            cancel_button:Disable()
            if not aux.cancel_in_progress() then state = IDLE end
        end
    end
end