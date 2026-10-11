TurtleMail = TurtleMail or {}
L = TurtleMail.L

local m = TurtleMail

local function get_realm_faction_key()
  local realm = "UnknownRealm"
  if m.api and m.api.GetCVar then
    local ok, r = pcall(m.api.GetCVar, "realmName")
    if ok and r and r ~= "" then realm = r end
  end

  local faction = "Unknown"
  if m.api and m.api.UnitFactionGroup then
    local ok2, f = pcall(m.api.UnitFactionGroup, "player")
    if ok2 and f and f ~= "" then faction = f end
  end

  return realm .. "|" .. faction
end

-- Optional: expose via m for convenience
m.get_realm_faction_key = get_realm_faction_key

local getn = table.getn 
local function pack( ... ) return arg end

local ATTACHMENTS_MAX = 21
local ATTACHMENTS_PER_ROW_SEND = 7
local ATTACHMENTS_MAX_ROWS_SEND = 3

local TurtleMail_SelectedItems = {} 
local INBOX_AUCTIONHOUSES = {
  [ "Stormwind Auction House" ] = true,
  [ "Alliance Auction House" ] = true,
  [ "Darnassus Auction House" ] = true,
  [ "Undercity Auction House" ] = true,
  [ "Thunder Bluff  Auction House" ] = true,
  [ "Horde Auction House" ] = true,
  [ "Blackwater Auction House" ] = true,
}

local FILTER_DEFS = {
  [ "Sold" ]     = { label = "拍卖成功", kind = "ah", value = "Sold" },
  [ "Won" ]      = { label = "一口价",   kind = "ah", value = "Won" },
  [ "Outbid" ]   = { label = "竞拍",     kind = "ah", value = "Outbid" },
  [ "Expired" ]  = { label = "已到期",   kind = "ah", value = "Expired" },
  [ "Removed" ]  = { label = "已取消",   kind = "ah", value = "Removed" },
  [ "Money" ]    = { label = "带钱",     kind = "money" },
  [ "Item" ]     = { label = "带附件",   kind = "item" },
  [ "COD" ]      = { label = "到付",     kind = "cod" },
  [ "Returned" ] = { label = "退信",     kind = "returned" },
  [ "Unread" ]   = { label = "未读",     kind = "unread" },
}

local function classify_ah_mail( subject )
  if not subject then return nil end
  local subj = string.gsub( subject, "|%s", "" )
  if string.find( subj, string.gsub( m.api.AUCTION_SOLD_MAIL_SUBJECT, "%%s", "" ) ) then
    return "Sold"
  elseif string.find( subj, string.gsub( m.api.AUCTION_REMOVED_MAIL_SUBJECT, "%%s", "" ) ) then
    return "Removed"
  elseif string.find( subj, string.gsub( m.api.AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", "" ) ) then
    return "Expired"
  elseif string.find( subj, string.gsub( m.api.AUCTION_WON_MAIL_SUBJECT, "%%s", "" ) ) then
    return "Won"
  elseif string.find( subj, string.gsub( m.api.AUCTION_OUTBID_MAIL_SUBJECT, "%%s", "" ) ) then
    return "Outbid"
  end
end

-- 竞得(Won)邮件的花费只在正文货币文本里（N金N银N铜），邮件头 money 恒为 0。
-- 单位可缺省（如只有银铜）；取正文第一处金额。5.0 无 string.match，用 string.find 捕获。
function TurtleMail.parse_body_money( body )
  if not body or body == "" then return nil end
  -- 每种捕获按实际单位换算；缺少金/银时不能把第一个数都当成金币。
  local pats = {
    { "(%d+)金%s*(%d+)银%s*(%d+)铜", 10000, 100, 1 },
    { "(%d+)金%s*(%d+)银", 10000, 100 },
    { "(%d+)金%s*(%d+)铜", 10000, 1 },
    { "(%d+)银%s*(%d+)铜", 100, 1 },
    { "(%d+)金", 10000 },
    { "(%d+)银", 100 },
    { "(%d+)铜", 1 },
  }
  local first, last, money
  for k = 1, getn( pats ) do
    local pat = pats[ k ]
    local start, finish, a, b, c = string.find( body, pat[ 1 ] )
    -- 正文取第一笔金额；同一起点优先完整组合，避免只取其中的金币。
    if start and ( not first or start < first or ( start == first and finish > last ) ) then
      first, last = start, finish
      money = ( tonumber( a ) or 0 ) * pat[ 2 ]
        + ( tonumber( b ) or 0 ) * ( pat[ 3 ] or 0 )
        + ( tonumber( c ) or 0 ) * ( pat[ 4 ] or 0 )
    end
  end
  return money
end

TurtleMail.api = getfenv()
TurtleMail.timer = 0
TurtleMail.log = {}
TurtleMail.orig = {}
TurtleMail.hooks = {}
TurtleMail.hook = setmetatable( {}, { __newindex = function( _, k, v ) m.hooks[ k ] = v end } )
TurtleMail.debug_enabled = false
TurtleMail.mailable = {}

-- 1.12 无 GetItemLink，且 GetItemInfo 未回包时返回 nil，失败也要缓存空标记
TurtleMail.item_name_cache = {}

---@type Calendar
TurtleMail.calendar = m.Calendar.new()

function TurtleMail:init()
  self.debug( "TurtleMail.init" )
  self.update_frame = m.api.CreateFrame( "Frame", "TurtleMailFrame", m.api.MailFrame )
  self.update_frame:SetScript( "OnUpdate", self.on_update )

  -- Register events
  self.update_frame:SetScript( "OnEvent", function() self[ event ]() end )
  for _, event in { "ADDON_LOADED", "PLAYER_LOGIN", "UI_ERROR_MESSAGE", "CURSOR_UPDATE", "BAG_UPDATE", "MAIL_SHOW", "MAIL_CLOSED", "MAIL_SEND_SUCCESS", "MAIL_INBOX_UPDATE" } do
    self.update_frame:RegisterEvent( event )
  end

  -- Set default log settings
  m.api.TurtleMail_Log = {
    Sent = {},
    Received = {},
    Settings = {
      -- 日志默认启用（仅对没有存档的新角色生效；已有存档的角色沿用其保存的设置，可用 /tm log 切换）
      Enabled = true,
      SentFilters = { Money = 1, COD = 1, Other = 1 },
      ReceivedFilters = { Money = 1, COD = 1, Other = 1, Returned = 1, AH = 1, AHSold = 1, AHOutbid = 1, AHWon = 1, AHCancelled = 1, AHExpired = 1 }
    }
  }
  m.api.TurtleMail_AutoCompleteNames = {}

  -- hack to prevent beancounter from deleting mail
  self.TakeInboxMoney, self.TakeInboxItem, self.DeleteInboxItem = m.api.TakeInboxMoney, m.api.TakeInboxItem, m.api.DeleteInboxItem

  self.tooltip_frame = m.api.CreateFrame( "GameTooltip", "TurtleMailTooltipFrame", nil, "GameTooltipTemplate" )
  self.tooltip_frame:SetOwner( m.api.WorldFrame, "ANCHOR_NONE" );
end

-- 1.12 无 UIDropDownMenu，筛选条件只能用按钮排
local CHECK_BOX = 16
-- 单元格：方框 16 + 间隙 4 + 文字 72（4 个汉字约 53px，加宽留出字体被放大的余量）
local CELL_W = 92
local PAD = 6
local ROW_H = 20
local ROW_GAP = 3
local FILTER_ROWS = 5
-- 面板左缘与邮箱外框右缘的间距
local PANEL_GAP = 4
-- 原版皮肤下 MailFrame 本体比可见装饰边框宽出一截（实测 MailFrame.R 467 而
-- 邮件列表 MailItem7.R 只有 411），拿 GetRight() 当锚点会留可见空隙。
-- pfUI 有 backdrop 能算出内缩，原版没有，用捞哥实测校准值（/tm paneloff 调出来的）。
-- /tm paneloff <dx> [dy] 可临时覆盖；/tm paneloff reset 回到下面这组默认值。
local PANEL_OFFSET_X = -38
local PANEL_OFFSET_Y = -12
-- pfUI 皮肤的默认校准值（捞哥实测），/tm paneloff 可临时覆盖
local PANEL_OFFSET_PF_X = 1
local PANEL_OFFSET_PF_Y = -5
-- pfUI 给整窗画的可见外框内缩量（pfUI/skins/blizzard/mail.lua:178-179：
-- TOPLEFT 12,-12 / BOTTOMRIGHT -30,72）。面板要贴的是这个可见边框，
-- 所以锚 MailFrame 本体时必须把这截内缩让掉。
local MAIL_INSET_TOP = -12
local MAIL_INSET_RIGHT = -30
-- 宽：PAD*2 + CELL_W*2 = 196，正好两列
local SIDE_PANEL_W = PAD * 2 + CELL_W * 2
-- 高：PAD + 4 行按钮(20+3) + 间隔 + 本页全选行 + FILTER_ROWS 行条件 + PAD
local SIDE_PANEL_H = PAD * 2 + 4 * ( ROW_H + ROW_GAP ) + 8 + ( CHECK_BOX + 6 )
  + FILTER_ROWS * ( CHECK_BOX + ROW_GAP )

---@param args string
function TurtleMail.slash_command( args )
  if args == "" or args == "help" then
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473TurtleMail " .. L[ "Help" ] .. "|r" )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm log|r " .. L[ "Toggle logging on/off" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm clear sent|r " .. L[ "Clear sent log" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm clear received|r " .. L[ "Clear received log" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm clear names|r " .. L[ "Clear saved recipient names from autocomplete" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm take|r " .. L[ "Batch take all filtered mails" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm drop|r " .. L[ "Batch delete all filtered mails" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm return|r " .. L[ "Batch return all filtered mails to sender" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm filter <keys>|clear|r " .. L[ "Batch usage" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm paneloff <dx> [dy]|reset|r " .. L[ "Panel offset usage" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm panel|r " .. L[ "Panel layout diag" ] )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473/tm save|r " .. L[ "Panel offset saved" ] )
    return
  end

  -- 必须排在 ^panel 之前：paneloff 以 panel 开头，被它截胡就永远进不来
  if string.find( args, "^paneloff" ) then
    local rest = string.gsub( args, "^paneloff%s*", "" )
    -- 原皮肤 / pfUI 各用各的存档键，校准互不影响
    local dflt_x = m.pfui_skin_enabled and PANEL_OFFSET_PF_X or PANEL_OFFSET_X
    local dflt_y = m.pfui_skin_enabled and PANEL_OFFSET_PF_Y or PANEL_OFFSET_Y
    local store = m.pfui_skin_enabled and "TurtleMail_PanelOffsetPF" or "TurtleMail_PanelOffset"
    local cur = m.api[ store ] or { x = dflt_x, y = dflt_y }
    if rest == "reset" or rest == "复位" then
      -- 回落到当前皮肤源码默认值，清掉对应存档覆盖
      m.api[ store ] = nil
      cur = { x = dflt_x, y = dflt_y }
    elseif rest ~= "" then
      -- 1.12 只有 string.gmatch，string.gfind 根本不存在（pfUI 自己也写 gmatch or gfind 兜底）。
      -- 这里只用 string.find 手撸切词，不碰 gmatch/gfind，跨版本最稳。
      local parts, pos = {}, 1
      while true do
        local s, e = string.find( rest, "%S+", pos )
        if not s then break end
        tinsert( parts, string.sub( rest, s, e ) )
        pos = e + 1
      end
      cur.x = tonumber( parts[ 1 ] ) or cur.x
      cur.y = tonumber( parts[ 2 ] ) or cur.y
      m.api[ store ] = cur
    end
    if m.batch_panel then
      if m.batch_reanchor then m.batch_reanchor() end
      -- batch_settle 的 OnUpdate 会连帧 reanchor 30 次，命令后必须留够帧数才生效
      m.batch_settle = 30
      if m.batch_reanchor then m.batch_reanchor() end
    end
    m.info( string.format( "面板偏移 X=%d Y=%d", cur.x, cur.y ) )
    m.info( string.format( "|cffffd100pfui皮肤=%s 面板L=%s 邮箱R=%s|r",
      m.pfui_skin_enabled and "开" or "关",
      m.batch_panel and tostring( math.floor( m.batch_panel:GetLeft() or -1 ) ) or "?",
      m.api.MailFrame and tostring( math.floor( m.api.MailFrame:GetRight() or -1 ) ) or "?" ) )
    if rest ~= "reset" and rest ~= "复位" then
      m.info( "满意后敲 /tm save 确认；/tm paneloff reset 复位" )
    end
    return
  end

  if string.find( args, "^panel" ) then
    -- 布局诊断：直接读屏幕坐标，避免靠截图猜像素
    local function r( f )
      if not f then return "nil" end
      if not f.GetLeft then return "no-Geometry" end
      -- 用 GetRight/GetTop 而不是 L+W：backdrop 类 frame 的 GetWidth 会跟锚点不一致
      local l, b, rt, tp = f:GetLeft(), f:GetBottom(), f:GetRight(), f:GetTop()
      if not l then return "no-left(未显示)" end
      return string.format( "L=%.0f R=%.0f T=%.0f W=%.0f H=%.0f", l, rt, tp, rt - l, tp - b )
    end
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473-- 面板布局诊断 --|r" )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100pfui皮肤=|r" ..
      ( m.pfui_skin_enabled and "|cff20ff20开（皮肤回调已跑）|r" or "|cffff6060关（当前原版皮肤）|r" ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100MailFrame|r      " .. r( m.api.MailFrame ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100MailFrame.bd|r   " .. r( m.api.MailFrame.backdrop ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100InboxFrame|r     " .. r( m.api.InboxFrame ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100InboxFrame.bd|r  " .. r( m.api.InboxFrame.backdrop ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100MailItem1|r      " .. r( m.api.MailItem1 ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100MailItem7|r      " .. r( m.api.MailItem7 ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100BatchPanel|r     " .. r( m.batch_panel ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100筛选按钮|r        " .. r( m.filterButton ) )
    -- 拍卖行/退信标记：XML 挂在 MailItemNExpireTime 下，用来核对它们有没有跑到窗外
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100AH图标1|r        " .. r( m.api.TurtleMailAuctionIcon1 ) )
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffffd100退信箭头1|r      " .. r( m.api.TurtleMailReturnedArrow1 ) )
    local mf = m.api.MailFrame
    local mfRight = mf and mf.GetRight and mf:GetRight()
    if mfRight then
      local inset = m.pfui_skin_enabled and MAIL_INSET_RIGHT or 0
      local ox, oy = 0, 0
      if m.pfui_skin_enabled then
        local off = m.api.TurtleMail_PanelOffsetPF
        if off then
          ox = off.x or 0
          oy = off.y or 0
        end
      else
        local off = m.api.TurtleMail_PanelOffset
        if off then
          ox = off.x or 0
          oy = off.y or 0
        else
          ox = PANEL_OFFSET_X
          oy = PANEL_OFFSET_Y
        end
      end
      m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cff20ff20BatchPanel.L 应≈" .. string.format( "%.0f", mfRight + inset + PANEL_GAP + ox )
        .. "（MailFrame.R " .. string.format( "%.0f", mfRight )
        .. " 内缩 " .. tostring( inset ) .. " + 间距 " .. tostring( PANEL_GAP )
        .. " + 校准X " .. tostring( ox ) .. " 校准Y " .. tostring( oy ) .. "）|r" )
    end
    m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cff808080backdrop 的 W/H 不可信，只看 L/B|r" )
    return
  end


  if string.find( args, "^save" ) then
    local off = m.api[ m.pfui_skin_enabled and "TurtleMail_PanelOffsetPF" or "TurtleMail_PanelOffset" ]
    if not off then
      m.info( string.format( "当前用源码默认值 X=%d Y=%d（无存档覆盖）|r",
        m.pfui_skin_enabled and PANEL_OFFSET_PF_X or PANEL_OFFSET_X,
        m.pfui_skin_enabled and PANEL_OFFSET_PF_Y or PANEL_OFFSET_Y ) )
    else
      m.info( string.format( "当前偏移 X=%d Y=%d 已在内存中。|r", off.x or 0, off.y or 0 ) )
      m.info( "|cffffd100要写入硬盘必须完全退出游戏（不是 /reload），否则会丢|r" )
    end
    return
  end

  if string.find( args, "^filter" ) then
    local rest = string.gsub( args, "^filter%s*", "" )
    m.batch_filters = m.batch_filters or {}
    if rest == "clear" or rest == "" then
      m.batch_filters = {}
      for key, btn in pairs( m.batch_filter_buttons or {} ) do
        btn:SetChecked( false )
      end
      m.batch_preview_dirty = true
      m.batch_refresh_label()
      m.info( L[ "Batch filter cleared" ] )
      return
    end
    local set, invalid = {}, {}
    local gmatch = string.gmatch or string.gfind
    local defs = {}
    for k2, v2 in pairs( FILTER_DEFS ) do defs[ string.lower( k2 ) ] = k2 end
    for word in gmatch( rest, "%S+" ) do
      local lower = string.lower( word )
      local key = defs[ lower ]
      if key then
        m.batch_filters[ key ] = true
        tinsert( set, key )
        if m.batch_filter_buttons and m.batch_filter_buttons[ key ] then
          m.batch_filter_buttons[ key ]:SetChecked( true )
        end
      else
        tinsert( invalid, word )
      end
    end
    m.batch_preview_dirty = true
    m.batch_refresh_label()
    if getn( set ) > 0 then
      m.info( L[ "Batch filter set" ] .. " " .. table.concat( set, ", " ) )
    end
    if getn( invalid ) > 0 then
      m.info( "|cffff6060" .. table.concat( invalid, ", " ) .. "|r" )
    end
    return
  end

  if args == "take" then
    m.batch_start( "take" )
    return
  end

  if args == "drop" then
    m.batch_start( "delete" )
    return
  end

  if args == "return" then
    m.batch_start( "return" )
    return
  end

  if args == "log" then
    m.api.TurtleMail_Log[ "Settings" ][ "Enabled" ] = not m.api.TurtleMail_Log[ "Settings" ][ "Enabled" ]
    if m.api.TurtleMail_Log[ "Settings" ][ "Enabled" ] then
      m.info( L[ "Logging is enabled." ] )
      if m.api.MailFrame:IsVisible() then
        m.api.MailFrameTab3:Show()
      end
    else
      m.info( L[ "Logging is disabled." ] )
      if m.api.MailFrame:IsVisible() then
        m.api.MailFrameTab3:Hide()
      end
    end
    m.log_enabled = m.api.TurtleMail_Log[ "Settings" ][ "Enabled" ]
  end

  if string.find( args, "^clear" ) then
    if args == "clear sent" then
      m.info( L[ "Sent log cleared." ] )
      m.api.TurtleMail_Log[ "Sent" ] = {}
    elseif args == "clear received" then
      m.info( L[ "Received log cleared." ] )
      m.api.TurtleMail_Log[ "Received" ] = {}
    elseif args == "clear names" then
      m.info( L[ "Recipient autocomplete names have been cleared." ] )
      local key = get_realm_faction_key()
      m.api.TurtleMail_AutoCompleteNames[ key ] = {}
    end
  end

  if args == "debug" then
    m.debug_enabled = not m.debug_enabled
    if m.debug_enabled then
      m.info( L[ "Debug is enabled." ] )
    else
      m.info( L[ "Debug is disabled." ] )
    end
  end
end

function TurtleMail_selected_time() 
  m.selected_time = m.selected_time - 1
  m.inbox_update = true
end

function TurtleMail.on_update()
  if not m.api.MailFrame or not m.api.MailFrame:IsVisible() then return end

  -- 一次右键会连抛好几次 BAG_UPDATE/ITEM_LOCK_CHANGED，合并成每帧只重排一次附件区
  if m.sendmail_need_update then
    m.debug( "on_update: sendmail_frame_update" )
    m.sendmail_need_update = nil
    m.api.SendMailFrame_Update()
  end

  if m._cursorItem then
    m.debug( "on_update: cursorItem" )
    m.cursorItem = m._cursorItem
    m._cursorItem = nil
  end

  if m.sendmail_update then
    m.debug( "on_update: sendmail" )
    m.sendmail_update = nil
    if m.sendmail_sending then
      m.debug( "m.sendmail_sending" )
      m.sendmail_send()
    end
  end

  -- 右键收取的延迟队列：等发票就绪再开信（每封上限 150 帧兜底）
  if m.delayed_opens and getn( m.delayed_opens ) > 0 then
    local item = m.delayed_opens[ 1 ]
    item.frames = item.frames - 1
    if item.frames <= 0 then
      local _, _, _, subject = m.api.GetInboxHeaderInfo( item.i )
      local inv_ready = true
      if classify_ah_mail( subject ) == "Won" then
        local okI, _, _, _, invMoney = pcall( m.api.GetInboxInvoiceInfo, item.i )
        inv_ready = okI and invMoney and invMoney > 0
      end
      if not inv_ready and ( item.waits or 0 ) < 150 then
        item.waits = ( item.waits or 0 ) + 1
        m.api.GetInboxText( item.i )
        m.api.GetInboxInvoiceInfo( item.i )
      else
        tremove( m.delayed_opens, 1 )
        m.inbox_open( item.i, true )
      end
    end
  end

  if m.inbox_update then
    m.debug( "on_update: inbox_update" )
    m.inbox_update = false
    if m.batch_opening then
      m.batch_step()
    elseif not m.Mail_open_Selected then
      local  _, _, _, _, _, COD, _, _, _, _, _, _, isGM = m.api.GetInboxHeaderInfo( m.inbox_index )
      if m.inbox_index > m.api.GetInboxNumItems() then
        if m.money_received > 0 then
          m.info( string.format( "%s%s.", m.format_money( m.money_received ), L[ "collected" ] ) )
        end
        m.inbox_abort()
      elseif m.inbox_skip or isGM  or (m.api.TurtleMail_AutoCOD ~= 1 and COD > 0) then
        m.inbox_skip = false
        m.inbox_index = m.inbox_index + 1
        m.inbox_update = true
      else
        m.inbox_open( m.inbox_index )
      end
    else
      -- 选择取件（批量取件/接收选择邮件共用）：
      -- 按邮件身份（发件人+主题）匹配而不是索引——取件会让列表索引漂移，
      -- 邮件一多索引必错（重复记录/读错邮件/金额错乱的根源），身份永远不漂。
      if not m.take_idents or getn( m.take_idents ) == 0 then
        if m.money_received > 0 then
          m.info( string.format( "%s%s.", m.format_money( m.money_received ), L[ "collected" ] ) )
        end
        if m.take_total and m.take_total > 0 then
          m.info( string.format( L[ "Batch done: %d" ], m.take_total ) )
        end
        m.take_total = nil
        m.money_received = 0
        m.inbox_opening = false
        m.Mail_open_Selected = false
        return
      end
      -- 上一封还没从列表消失就先等（150 帧等不到则跳过，防卡死）
      if m.take_wait_count and m.api.GetInboxNumItems() == m.take_wait_count and ( m.take_waits or 0 ) < 150 then
        m.take_waits = ( m.take_waits or 0 ) + 1
        m.inbox_update = true
        return
      end
      m.take_wait_count = nil
      m.take_waits = 0

      local ident = m.take_idents[ 1 ]
      local found, cod_amount = nil, nil
      local total = m.api.GetInboxNumItems()
      for i = 1, total do
        local _, _, sender2, subject2, _, cod2, _, _, _, _, _, _, isGM2 = m.api.GetInboxHeaderInfo( i )
        if not isGM2 and sender2 == ident.from and subject2 == ident.subject then
          found = i
          cod_amount = cod2
          break
        end
      end
      if not found then
        -- 这封已不在邮箱里（被其它操作收走/删除）：跳过
        tremove( m.take_idents, 1 )
        m.inbox_update = true
        return
      end
      if m.api.TurtleMail_AutoCOD ~= 1 and cod_amount and cod_amount > 0 then
        tremove( m.take_idents, 1 )
        m.inbox_update = true
        return
      end
      -- 竞得邮件的发票金额要等服务器回包：没就绪就继续预取再等（150 帧兜底），
      -- 否则落档时读到的还是 0 → "花费:?"
      local inv_ready = true
      if classify_ah_mail( ident.subject ) == "Won" then
        local okI, _, _, _, invMoney = pcall( m.api.GetInboxInvoiceInfo, found )
        inv_ready = okI and invMoney and invMoney > 0
      end
      if not inv_ready and ( m.inv_waits or 0 ) < 150 then
        m.inv_waits = ( m.inv_waits or 0 ) + 1
        m.api.GetInboxText( found )
        m.api.GetInboxInvoiceInfo( found )
        m.inbox_update = true
        return
      end
      m.inv_waits = 0
      -- manual=true：用户明确勾选要取的邮件一律记日志，未读也落档
      m.inbox_open( found, true )
      tremove( m.take_idents, 1 )
      -- 等这封真的消失再找下一封：防止身份扫描撞上还没消失的同一封
      m.take_wait_count = m.api.GetInboxNumItems()
      m.inbox_update = true
    end
  end

  if m.timer > 0 then
    m.timer = m.timer - 1
  elseif not m.inbox_opening then
    m.timer = 200
    m.api.CheckInbox()
  end
end

function TurtleMail.CURSOR_UPDATE()
  m.cursorItem = nil
end

function TurtleMail.get_cursor_item()
  return m.cursorItem
end

---@param item table
function TurtleMail.set_cursor_item( item )
  m._cursorItem = item
end

function TurtleMail.sendmail_queue_update()
  m.sendmail_need_update = true
end

function TurtleMail.BAG_UPDATE()
  if m.api.MailFrame:IsVisible() then
    m.sendmail_queue_update()
  end
end

function TurtleMail.MAIL_SHOW()
  m.pfui_skin()
  m.restore_position()

  if not m.first_show then
    m.first_show = true
    if m.pfui_skin_enabled then
      m.api.pfUI.api.StripTextures( m.api.SendMailPackageButton )
    end

    local background = ({ m.api.SendMailPackageButton:GetRegions() })[ 1 ]
    background:Hide()
    local count = ({ m.api.SendMailPackageButton:GetRegions() })[ 3 ]
    count:Hide()
    m.api.SendMailPackageButton:Disable()
    m.api.SendMailPackageButton:SetScript( "OnReceiveDrag", nil )
    m.api.SendMailPackageButton:SetScript( "OnDragStart", nil )
  end

  if m.log_enabled then
    m.api.MailFrameTab3:Show()
  else
    m.api.MailFrameTab3:Hide()
  end

  m.timer = 0
  m.money_received = 0
  m.update_money( 0 )
end

function TurtleMail.MAIL_CLOSED()
  m.inbox_abort()
  m.sendmail_sending = false
  m.sendmail_clear()
  -- 关闭邮箱时也记录一次当前位置，防止拖动信息因其它插件覆盖 OnDragStop 而丢失
  local point, _, _, x, y = m.api.MailFrame:GetPoint()
  if point then
    m.api.TurtleMail_Point = { point = point, x = x, y = y }
  end
end

function TurtleMail.UI_ERROR_MESSAGE()
  if m.inbox_opening then
    if arg1 == m.api.ERR_INV_FULL then
      m.inbox_abort()
    elseif arg1 == m.api.ERR_ITEM_MAX_COUNT then
      m.inbox_skip = true
    end
  elseif m.sendmail_sending and (arg1 == m.api.ERR_MAIL_TO_SELF or arg1 == m.api.ERR_PLAYER_WRONG_FACTION or arg1 == m.api.ERR_MAIL_TARGET_NOT_FOUND or arg1 == m.api.ERR_MAIL_REACHED_CAP) then
    m.sendmail_sending = false
    m.sendmail_state = nil
    m.api.ClearCursor()
    m.orig.ClickSendMailItemButton()
    m.api.ClearCursor()
  end
end

function TurtleMail.ADDON_LOADED()
  if arg1 ~= "TurtleMail" then return end

  local version = m.api.GetAddOnMetadata( "TurtleMail", "Version" )
  m.info( string.format( "Loaded (|cffeda55fv%s|r).", version ) )

  -- 日志一次性迁移：老角色存档里存的是关，本版本起强制开一次；之后 /tm log 的手动开关照旧尊重
  local log_settings = m.api.TurtleMail_Log[ "Settings" ]
  if log_settings.log_on_version ~= version then
    log_settings.log_on_version = version
    log_settings.Enabled = true
    m.info( "日志已默认启用，可用 /tm log 关闭。" )
  end

  if not m.api.TurtleMail_Log[ "Settings" ].first_run then
    m.api.TurtleMail_Log[ "Settings" ].first_run = version
    m.info( "New in |cffeda55fv1.4|r: Enable logging with |cffabd473/tm log|r" )
  end

  if m.api.UIPanelWindows[ "MailFrame" ] then
    m.api.UIPanelWindows[ "MailFrame" ].pushable = 1
  else
    m.api.UIPanelWindows[ "MailFrame" ] = { area = "left", pushable = 1 }
  end

  if m.api.UIPanelWindows[ "FriendsFrame" ] then
    m.api.UIPanelWindows[ "FriendsFrame" ].pushable = 2
  else
    m.api.UIPanelWindows[ "FriendsFrame" ] = { area = "left", pushable = 2 }
  end

  -- 让邮箱窗口自身可拖动（不依赖 pfUI 的 EnableMovable）；InboxFrame/SendMailFrame 已在 load 时禁用鼠标，背景处即可拖拽
  m.api.MailFrame:SetMovable( true )
  m.api.MailFrame:RegisterForDrag( "LeftButton" )
  m.api.MailFrame:SetScript( "OnDragStart", function() this:StartMoving() end )
  m.api.MailFrame:SetScript( "OnDragStop", m.on_drag_stop )
  m.api.MailFrame:SetClampedToScreen( true )
  m.api.PanelTemplates_SetNumTabs( m.api.MailFrame, 3 )

  m.inbox_load()
  m.sendmail_load()
  m.log.load()
  -- batch_load 必须在 pfui_skin 之前：pfUI 就绪时皮肤回调当场执行，
  -- 面板按钮若还没创建就会被 SkinButton 永远漏掉（斜角原版按钮）
  m.batch_load()
  m.pfui_skin()
end

function TurtleMail.PLAYER_LOGIN()
  m.debug( "PLAYER_LOGIN" )
  -- pfUI 晚于本插件加载时 ADDON_LOADED 那次注册会落空，登录/开邮箱时再补注册
  m.pfui_skin()
  for k, v in m.hooks do
    m.orig[ k ] = m.api[ k ]
    m.api[ k ] = v
  end
	local key = get_realm_faction_key()
	m.api.TurtleMail_AutoCompleteNames[ key ] = m.api.TurtleMail_AutoCompleteNames[ key ] or {}

	for char, last_seen in pairs( m.api.TurtleMail_AutoCompleteNames[ key ] or {} ) do
	  -- 用 time()（Unix 时间戳）而非 GetTime()（会话秒数，重载即归零，跨会话比较无意义）
	  if time() - last_seen > 60 * 60 * 24 * 30 then
		m.api.TurtleMail_AutoCompleteNames[ key ][ char ] = nil
	  end
	end

  m.add_auto_complete_name( m.api.UnitName( "player" ) )
  m.log_enabled = m.api.TurtleMail_Log[ "Settings" ][ "Enabled" ]

  SLASH_TURTLEMAIL1 = "/turtlemail"
  SLASH_TURTLEMAIL2 = "/tm"
  m.api.SlashCmdList[ "TURTLEMAIL" ] = m.slash_command
end

function TurtleMail.MAIL_SEND_SUCCESS()
  m.debug( "MAIL_SEND_SUCCESS" )
  if m.sendmail_state and not m.sendmail_state.sent then
    m.sendmail_state.sent = true
    m.log.add( 'Sent', m.sendmail_state )
    m.add_auto_complete_name( m.sendmail_state.to )
  end
  if m.sendmail_sending then
    m.sendmail_update = true
  end
end

function TurtleMail.MAIL_INBOX_UPDATE()
  if m.inbox_opening then
    m.inbox_update = true
  end

  for i = 1, 7 do
    local index = (i + (m.api.InboxFrame.pageNum - 1) * 7)
    if index <= m.api.GetInboxNumItems() then
      local _, _, sender, _, _, _, _, _, _, was_returned = m.api.GetInboxHeaderInfo( index )
      if INBOX_AUCTIONHOUSES[ sender ] then
        m.api[ "TurtleMailAuctionIcon" .. i ]:Show()
      else
        m.api[ "TurtleMailAuctionIcon" .. i ]:Hide()
      end
      if was_returned then
        m.api[ "TurtleMailReturnedArrow" .. i ]:Show()
      else
        m.api[ "TurtleMailReturnedArrow" .. i ]:Hide()
      end
    end
  end

--新增选择取件
  -- 预览必须在刷勾选框之前算，否则勾选状态会落后一帧
  if not m.inbox_opening then
    local page = m.api.InboxFrame.pageNum or 1
    local total = m.api.GetInboxNumItems()
    if m.batch_preview_dirty or m.batch_preview_page ~= page or m.batch_preview_total ~= total then
      m.batch_preview_dirty = nil
      m.batch_preview_update()
    end
  end

  m.inbox_refresh_checkboxes()

end

---@param name string
function TurtleMail.add_auto_complete_name( name )
  local key = get_realm_faction_key()
  m.api.TurtleMail_AutoCompleteNames[ key ] = m.api.TurtleMail_AutoCompleteNames[ key ] or {}
  m.api.TurtleMail_AutoCompleteNames[ key ][ name ] = time()
end

function TurtleMail.inbox_load()

--新增选择取件
  m.api.InboxFrame:EnableMouse( false )
  local btnAll = m.api.CreateFrame( "Button", "TurtleMailOpenAllMailButton", m.api.InboxFrame, "UIPanelButtonTemplate" )
  btnAll:SetPoint( "LEFT",m.api.InboxFrame, "TOP", 15, -53 )
  btnAll:SetText("接收所有邮件")
  btnAll:SetWidth(120)
  btnAll:SetHeight( 25 )
  btnAll:SetScript( "OnClick", m.inbox_open_all )

  local btnSelected = m.api.CreateFrame( "Button", "TurtleMailOpenSelectedMailButton", m.api.InboxFrame, "UIPanelButtonTemplate" )
  btnSelected:SetPoint( "RIGHT",m.api.InboxFrame, "TOP", 5, -53 )
  btnSelected:SetText("接收选择邮件")
  btnSelected:SetWidth(120)
  btnSelected:SetHeight( 25 )
  btnSelected:SetScript( "OnClick", m.inbox_open_selected )

  -- 小窗开关（方案A）：钉在"接收所有邮件"右侧，纯字体符号零贴图；
  -- pfUI 下由皮肤回调 SkinButton 换装，原版走按钮原生底
  local btnToggle = m.api.CreateFrame( "Button", "TurtleMailPanelToggleButton", m.api.InboxFrame, "UIPanelButtonTemplate" )
  btnToggle:SetPoint( "LEFT", btnAll, "RIGHT", 0, 0 )
  btnToggle:SetWidth( 15 )   -- 与邮箱右上角关闭按钮同尺寸（pfUI SkinCloseButton = 15x15）
  btnToggle:SetHeight( 15 )
  btnToggle:SetScript( "OnClick", function()
    if not m.batch_panel then return end
    if m.batch_panel:IsVisible() then
      m.batch_panel:Hide()
      m.api.TurtleMail_PanelHidden = 1
    else
      m.batch_panel:Show()
      m.api.TurtleMail_PanelHidden = nil
      if m.batch_reanchor then m.batch_reanchor() end
      m.batch_settle = 30
    end
    m.update_panel_toggle_btn()
  end )
  btnToggle:SetScript( "OnEnter", function()
    m.api.GameTooltip:ClearLines()
    m.api.GameTooltip:SetOwner( this, "ANCHOR_LEFT" )
    m.api.GameTooltip:AddLine( m.api.TurtleMail_PanelHidden and "展开批量面板" or "收起批量面板", "", 1, 1, 0 )
    m.api.GameTooltip:Show()
  end )
  btnToggle:SetScript( "OnLeave", function() m.api.GameTooltip:Hide() end )
  m.update_panel_toggle_btn()

  -- batch_load 内部自建自守，只在第一次真正建控件；
  -- inbox_load 每次开邮箱都会跑，不能在这里无条件调用重建。

--新增自动到付选项
  local CODCheckButton = m.api.CreateFrame( "CheckButton", "TurtleMailCODCheckButton", m.api.InboxFrame, "OptionsCheckButtonTemplate" )
  CODCheckButton:SetPoint( "TOP",m.api.InboxFrame, "BOTTOM", -25, 115)
  TurtleMailCODCheckButtonText:SetText("自动到付")
  CODCheckButton:SetWidth(24)
  CODCheckButton:SetHeight( 24 )
  CODCheckButton:SetScript( "OnUpdate", function()
    if m.api.TurtleMail_AutoCOD == 1 then
      CODCheckButton:SetChecked(1)
    else
      CODCheckButton:SetChecked(0)
    end
  end)
  CODCheckButton:SetScript( "OnClick", function()
    if m.api.TurtleMail_AutoCOD == 1 then
      m.api.TurtleMail_AutoCOD = 0
    else
      m.api.TurtleMail_AutoCOD = 1
    end
  end)
  CODCheckButton:SetScript( "OnEnter", function()
    GameTooltip:ClearLines();
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine("警告！！！")
    GameTooltip:AddLine("请仔核对认邮件，否则遭受损失概不负责！")
    GameTooltip:Show()
  end)
  CODCheckButton:SetScript( "OnLeave", function() GameTooltip:Hide() end )

  MailItem1:SetPoint("TOPLEFT", m.api.InboxFrame, "TOPLEFT", 48, -80)
  for i=1,7 do
    -- 到期时间左移 15px，给右侧新增的邮件勾选框腾位
    getglobal("MailItem" .. i .. "ExpireTime"):SetPoint("TOPRIGHT", "MailItem" .. i, "TOPRIGHT", -15, -4)
    getglobal("MailItem" .. i):SetWidth(280)
  end

  for i = 1, 7 do
    m.api[ "TurtleMailAuctionIcon" .. i .. "Texture" ]:SetVertexColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
    m.api[ "TurtleMailReturnedArrow" .. i .. "Texture" ]:SetVertexColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
  end
end

--新增选择取件
function TurtleMail.inbox_open_all()
  m.inbox_opening = true
  m.inbox_update_lock()
  m.inbox_skip = false
  m.inbox_index = 1
  m.inbox_update = true
  m.Mail_open_Selected = false
end

function TurtleMail_Inbox_SetSelected()
  local id = this:GetID() + (m.api.InboxFrame.pageNum - 1) * 7
    if not this:GetChecked() then
		for k, v in ipairs(TurtleMail_SelectedItems) do
		  if v == id then
			tremove(TurtleMail_SelectedItems, k)
			break
		  end
		end
    else
      tinsert(TurtleMail_SelectedItems, id)
    end
end

function TurtleMail.inbox_open_selected()
	if getn(TurtleMail_SelectedItems) == 0 then
	  return
	end

	-- 按邮件身份（发件人+主题）排队，索引在取件过程中会漂移
	m.take_idents = {}
	local seen = {}
	local total = m.api.GetInboxNumItems()
	for _, i in ipairs(TurtleMail_SelectedItems) do
	  if type(i) == "number" and i >= 1 and i <= total and not seen[i] then
		local _, _, sender2, subject2 = m.api.GetInboxHeaderInfo( i )
		seen[i] = true
		tinsert( m.take_idents, { from = sender2, subject = subject2 } )
	  end
	end

	TurtleMail_SelectedItems = {}

	m.Mail_open_Selected = true
	m.inbox_opening = true
	m.inbox_update_lock()
	m.inbox_skip = false
	m.inbox_update = true
	m.take_total = getn( m.take_idents )
	m.take_wait_count = nil
	m.take_waits = 0
	m.inv_waits = 0
end

function TurtleMail.inbox_abort()
  m.inbox_opening = false
  m.inbox_update_lock()
  m.inbox_update = false
end

-- 本页全选：把当前页 7 个勾选框一次性切到同一状态。
-- 直接改 TurtleMail_SelectedItems 而不是逐个模拟点击，保证不重复入表。
function TurtleMail.inbox_select_page( checked )
  local page = m.api.InboxFrame.pageNum or 1
  local total = m.api.GetInboxNumItems()

  for i = 1, 7 do
    local index = i + ( page - 1 ) * 7
    if index > total then break end
    local cb = getglobal( "TurtleMailBoxItem" .. i .. "CB" )
    -- 1.12 只有 IsVisible/IsShown，没有 IsHidden（2.0 才加）
    if cb and cb:IsVisible() then
      cb:SetChecked( checked and 1 or nil )
      local at = nil
      for k, v in ipairs( TurtleMail_SelectedItems ) do
        if v == index then at = k break end
      end
      if checked and not at then
        tinsert( TurtleMail_SelectedItems, index )
      elseif not checked and at then
        tremove( TurtleMail_SelectedItems, at )
      end
    end
  end
end

-- 把 TurtleMail_SelectedItems 同步到当前页 7 个勾选框，并回推"本页全选"状态。
function TurtleMail.inbox_refresh_checkboxes()
  local page = m.api.InboxFrame.pageNum or 1
  local total = m.api.GetInboxNumItems()
  local page_checked, page_total = 0, 0

  for i = 1, 7 do
    local index = i + ( page - 1 ) * 7
    local cb = getglobal( "TurtleMailBoxItem" .. i .. "CB" )
    if cb then
      if index > total then
        cb:Hide()
      else
        cb:Show()
        cb:SetChecked( nil )
        page_total = page_total + 1
        for k = 1, getn( TurtleMail_SelectedItems ) do
          if TurtleMail_SelectedItems[ k ] == index then
            cb:SetChecked( 1 )
            page_checked = page_checked + 1
            break
          end
        end
      end
    end
  end

  if m.select_all_button then
    m.select_all_button:SetChecked( page_total > 0 and page_checked == page_total and true or false )
  end
end

-- 筛选预览：把当前页里命中筛选条件的邮件勾上，一眼看清批量操作会动哪几封。
-- 预览勾的索引单独记在 m.batch_preview：条件/页码/邮件数变化时先撤回再重算，
-- 所以条件不变期间手动取消勾选是有效的，不会被预览立刻盖回去。
function TurtleMail.batch_preview_update()
  local page = m.api.InboxFrame.pageNum or 1
  local total = m.api.GetInboxNumItems()
  m.batch_preview = m.batch_preview or {}
  m.batch_preview_page = page
  m.batch_preview_total = total

  for k = getn( m.batch_preview ), 1, -1 do
    local idx = m.batch_preview[ k ]
    for j = getn( TurtleMail_SelectedItems ), 1, -1 do
      if TurtleMail_SelectedItems[ j ] == idx then tremove( TurtleMail_SelectedItems, j ) end
    end
    tremove( m.batch_preview, k )
  end

  local filters = m.batch_filters or {}
  if next( filters ) then
    for i = 1, 7 do
      local index = i + ( page - 1 ) * 7
      if index <= total then
        local _, _, sender, subject, money, cod, _, has_item, read, returned, _, _, isGM =
          m.api.GetInboxHeaderInfo( index )
        if not isGM and m.batch_match( filters, sender, subject, money, cod, has_item, read, returned ) then
          tinsert( m.batch_preview, index )
          local at = false
          for k = 1, getn( TurtleMail_SelectedItems ) do
            if TurtleMail_SelectedItems[ k ] == index then at = true break end
          end
          if not at then tinsert( TurtleMail_SelectedItems, index ) end
        end
      end
    end
  end

  m.batch_refresh_label()
end

function TurtleMail.batch_refresh_label()
  if not m.filterButton then return end
  local n = 0
  for _ in pairs( m.batch_filters or {} ) do n = n + 1 end
  if n == 0 then
    m.filterButton:SetText( L[ "Filter" ] )
    return
  end
  -- 命中数每次现算：跨页总数，让"本页只看到 2 封、其实一共 12 封"不至于误判
  local matched = getn( m.batch_scan( m.batch_filters ) )
  m.filterButton:SetText( string.format( L[ "Filter (%d)" ], n ) ..
    " · " .. string.format( L[ "Matched (%d)" ], matched ) )
end

function TurtleMail.batch_toggle_filter( key )
  if m.batch_filters[ key ] then
    m.batch_filters[ key ] = nil
  else
    m.batch_filters[ key ] = true
  end
  local btn = m.batch_filter_buttons and m.batch_filter_buttons[ key ]
  if btn then
    btn:SetChecked( m.batch_filters[ key ] and true or false )
  end
  m.batch_preview_update()
  if m.batch_panel then m.inbox_refresh_checkboxes() end
end

-- 小窗开关按钮的两态文案：+ / - 恒为金色（捞哥要求不做变灰），加号=展开、减号=收起
function TurtleMail.update_panel_toggle_btn()
  local btn = m.api.TurtleMailPanelToggleButton
  if not btn then return end
  if m.api.TurtleMail_PanelHidden then
    btn:SetText( "|cffffd100+|r" )
  else
    btn:SetText( "|cffffd100-|r" )
  end
end

function TurtleMail.batch_load()
  -- 只建一次。inbox_load 每次开邮箱都会调用这里，重复 CreateFrame 同名控件
  -- 会返回新 frame 而旧的仍留在屏幕上，叠成一堆错位的面板。
  if m.batch_panel then
    -- 尊重小窗开关的收起状态：不能每次开邮箱都强制弹出来
    if not m.api.TurtleMail_PanelHidden then
      m.batch_panel:Show()
    end
    if m.batch_reanchor then m.batch_reanchor() end
    return
  end

  m.batch_filters = m.batch_filters or {}
  m.batch_filter_buttons = m.batch_filter_buttons or {}

  local keys = {}
  for key in pairs( FILTER_DEFS ) do tinsert( keys, key ) end
  sort( keys )

  -- 旧版本遗留的同名 frame 先清掉，避免和这次的叠在一起
  local stale = getglobal( "TurtleMailBatchPanel" )
  if stale then pcall( function() stale:Hide() end ) end

  local panel = m.api.CreateFrame( "Frame", "TurtleMailBatchPanel", m.api.InboxFrame )
  panel:SetWidth( SIDE_PANEL_W )
  panel:SetHeight( SIDE_PANEL_H )
  panel:EnableMouse( true )

  -- 锚 MailFrame 本体 + 已知内缩，不要锚 backdrop：pfUI 的 backdrop 会被重建/重排，
  -- 实测它的 L/B 与锚点一致但 W/H 会凭空缩掉 64/80（MailFrame.bd R 报 620，
  -- 而按 mail.lua:179 应为 684）。锚它等于把位置交给一个会漂的对象。
  -- 不开放拖动：StartMoving 存下的偏移会让面板永久脱离邮箱。
  local function right_inset()
    if m.pfui_skin_enabled then return MAIL_INSET_RIGHT end
    return 0
  end
  -- 内缩量是 pfUI 外框的，没皮肤时可见边缘就是本体边缘，不该跟着让
  local function top_inset()
    if m.pfui_skin_enabled then return MAIL_INSET_TOP end
    return 0
  end
  local function reanchor()
    panel:ClearAllPoints()
    local mf = m.api.MailFrame
    -- 两套皮肤各存各的校准值：原皮肤用 TurtleMail_PanelOffset（默认 -38/-12），
    -- pfUI 用 TurtleMail_PanelOffsetPF（默认 0/0），互不串扰。
    local dx, dy = 0, 0
    if m.pfui_skin_enabled then
      local off = m.api.TurtleMail_PanelOffsetPF
      if off then
        dx = off.x or 0
        dy = off.y or 0
      else
        dx = PANEL_OFFSET_PF_X
        dy = PANEL_OFFSET_PF_Y
      end
    else
      local off = m.api.TurtleMail_PanelOffset
      if off then
        dx = off.x or 0
        dy = off.y or 0
      else
        dx = PANEL_OFFSET_X
        dy = PANEL_OFFSET_Y
      end
    end
    if mf then
      panel:SetPoint( "TOPLEFT", mf, "TOPRIGHT", PANEL_GAP + right_inset() + dx, top_inset() + dy )
    else
      panel:SetPoint( "TOPLEFT", m.api.InboxFrame, "TOPRIGHT", PANEL_GAP + dx, dy )
    end
  end

  -- pfUI 皮肤在本插件之后才撑开 MailFrame.backdrop，锚点会停在旧位置。
  -- 开面板后连续重锚到布局稳定（30 帧足够跨过皮肤重排）。
  m.batch_settle = 30
  reanchor()
  panel:SetScript( "OnUpdate", function( self )
    if m.batch_settle and m.batch_settle > 0 then
      m.batch_settle = m.batch_settle - 1
      reanchor()
    end
  end )

  panel:SetScript( "OnShow", function()
    m.batch_settle = 30
    m.batch_preview_dirty = true
    reanchor()
  end )
  panel:RegisterEvent( "MAIL_INBOX_UPDATE" )
  panel:SetScript( "OnEvent", function() m.batch_settle = 30; reanchor() end )

  if m.api.pfUI and m.api.pfUI.api and m.api.pfUI.api.CreateBackdrop then
    pcall( m.api.pfUI.api.CreateBackdrop, panel, 4 )
  else
    -- 没装 pfUI：面板得自己画背景，否则只剩一圈裸按钮飘在游戏画面上。
    -- 1.12 的 Frame 原生支持 SetBackdrop（XML 里 MailAutoCompleteBox 就是这种写法）。
    panel:SetBackdrop( {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    } )
    panel:SetBackdropColor( 0, 0, 0, 0.75 )
  end
  m.batch_panel = panel
  m.batch_reanchor = reanchor

  local y = -PAD

  local btnMenu = m.api.CreateFrame( "Button", "TurtleMailFilterMenuButton", panel, "UIPanelButtonTemplate" )
  btnMenu:SetPoint( "TOPLEFT", panel, "TOPLEFT", PAD, y )
  btnMenu:SetWidth( SIDE_PANEL_W - PAD * 2 )
  btnMenu:SetHeight( ROW_H )
  btnMenu:SetScript( "OnClick", function() end )
  m.filterButton = btnMenu
  m.batch_refresh_label()
  y = y - ( ROW_H + ROW_GAP )

  local function action_button( name, text, tip, r, g, b, onclick )
    local btn = m.api.CreateFrame( "Button", name, panel, "UIPanelButtonTemplate" )
    btn:SetPoint( "TOPLEFT", panel, "TOPLEFT", PAD, y )
    btn:SetWidth( SIDE_PANEL_W - PAD * 2 )
    btn:SetHeight( ROW_H )
    btn:SetText( text )
    btn:SetScript( "OnClick", onclick )
    btn:SetScript( "OnEnter", function()
      m.api.GameTooltip:ClearLines()
      m.api.GameTooltip:SetOwner( this, "ANCHOR_LEFT" )
      m.api.GameTooltip:AddLine( tip, "", r, g, b )
      m.api.GameTooltip:Show()
    end )
    btn:SetScript( "OnLeave", function() m.api.GameTooltip:Hide() end )
    y = y - ( ROW_H + ROW_GAP )
    return btn
  end

  local btnTake = action_button( "TurtleMailBatchTakeButton", L[ "Batch take" ],
    L[ "Batch take tip" ], 0, 1, 0, function() m.batch_start( "take" ) end )

  local btnReturn = action_button( "TurtleMailBatchReturnButton", L[ "Batch return" ],
    L[ "Batch return tip" ], 1, 1, 0, function() m.batch_start( "return" ) end )
  m.batch_return_button = btnReturn

  local btnDelete = action_button( "TurtleMailBatchDeleteButton", L[ "Batch delete" ],
    L[ "Batch delete tip" ], 1, 0, 0, function() m.batch_start( "delete" ) end )
  m.batch_delete_button = btnDelete

  y = y - 8

  -- 勾选框：不用 OptionsCheckButtonTemplate——它的命中区/贴图在不同客户端会错位，
  -- 表现为"点方框没反应、点文字才生效"。自绘 16x16 方框保证命中区 == 可见框。
  -- 注意必须用 Button：1.12 的普通 Frame 没有 RegisterForClicks/OnClick，点了没反应。
  local function checkbox( name, label, x, yy, onclick )
    local cb = m.api.CreateFrame( "Button", name, panel )
    cb:SetWidth( CHECK_BOX )
    cb:SetHeight( CHECK_BOX )
    cb:SetPoint( "TOPLEFT", panel, "TOPLEFT", x, yy )
    cb:EnableMouse( true )
    cb:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )

    local box = cb:CreateTexture( name .. "Box", "BACKGROUND" )
    box:SetTexture( "Interface\\Buttons\\UI-CheckBox-Up" )
    box:SetAllPoints( cb )
    local mark = cb:CreateTexture( name .. "Mark", "ARTWORK" )
    mark:SetTexture( "Interface\\Buttons\\UI-CheckBox-Check" )
    mark:SetAllPoints( cb )
    mark:Hide()

    local checked = false
    cb.SetChecked = function( self, v )
      checked = v and true or false
      if checked then mark:Show() else mark:Hide() end
    end
    cb.GetChecked = function( self ) return checked end
    cb.Click = function( self )
      cb:SetChecked( not checked )
      onclick()
    end
    cb:SetScript( "OnClick", function() cb:Click() end )

    local txt = m.api.CreateFrame( "Button", name .. "Label", panel )
    txt:SetHeight( CHECK_BOX )
    txt:SetPoint( "TOPLEFT", cb, "TOPRIGHT", 4, 0 )
    txt:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
    local fs = txt:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
    fs:SetPoint( "LEFT", txt, "LEFT", 0, 0 )
    fs:SetText( label )
    -- 按文字实宽收窄命中区；字体未就绪时 GetWidth 可能为 0，回落到单元格文字宽
    local tw = fs:GetWidth()
    if not tw or tw <= 0 then tw = CELL_W - CHECK_BOX - 4 end
    txt:SetWidth( math.floor( tw + 0.5 ) + 2 )
    txt:SetScript( "OnClick", function() cb:Click() end )
    return cb
  end

  local cbAll
  cbAll = checkbox( "TurtleMailSelectAllCB", L[ "Select all" ], PAD + 2, y, function()
    -- 不能用 OnClick 的 button 参数：点文字标签时走 cb:Click()，该参数为 nil
    m.inbox_select_page( cbAll:GetChecked() and true or false )
  end )
  m.select_all_button = cbAll
  y = y - ( CHECK_BOX + 6 )

  for idx = 1, getn( keys ) do
    local key = keys[ idx ]
    local row = math.ceil( idx / 2 )
    -- 奇偶不能用 % 或 math.fmod：两者都是 Lua 5.1 才有的，1.12 的 5.0 会报语法错/字段 nil
    local col = idx - ( row - 1 ) * 2

    local cb
    cb = checkbox( "TurtleMailBatchFilter" .. idx, FILTER_DEFS[ key ].label,
      PAD + ( col - 1 ) * CELL_W, y - ( row - 1 ) * ( CHECK_BOX + ROW_GAP ),
      function()
        -- 同上：button 参数在「点文字」路径下为 nil，改用闭包捕获的 cb
        m.batch_toggle_filter( key )
        cb:SetChecked( m.batch_filters[ key ] and true or false )
      end )

    m.batch_filter_buttons[ key ] = cb
  end

  -- 存档里是收起状态：首次建好后保持隐藏
  if m.api.TurtleMail_PanelHidden then
    panel:Hide()
  end
end

-- 倒序队列：删掉第 N 封后只有 >N 的索引左移，而那些都已处理完，剩余索引不受影响
function TurtleMail.batch_scan( filters )
  local total = m.api.GetInboxNumItems()
  local list = {}
  for i = 1, total do
    local _, _, sender, subject, money, cod, _, has_item, read, returned, _, _, isGM = m.api.GetInboxHeaderInfo( i )
    if not isGM and m.batch_match( filters, sender, subject, money, cod, has_item, read, returned ) then
      tinsert( list, i )
    end
  end

  local sorted = {}
  for k = getn( list ), 1, -1 do
    tinsert( sorted, list[ k ] )
  end
  return sorted
end

--- 多条件之间是 OR：命中任意一个已勾选条件即入选
function TurtleMail.batch_match( filters, sender, subject, money, cod, has_item, read, returned )
  local ah = classify_ah_mail( subject )
  local has_any = false

  for key in pairs( filters ) do
    local def = FILTER_DEFS[ key ]
    if not def then return false end
    has_any = true
    if def.kind == "ah" then
      if ah == def.value then return true end
    elseif def.kind == "money" then
      if money and money > 0 then return true end
    elseif def.kind == "item" then
      if has_item then return true end
    elseif def.kind == "cod" then
      if cod and cod > 0 then return true end
    elseif def.kind == "returned" then
      if returned then return true end
    elseif def.kind == "unread" then
      if not read then return true end
    end
  end

  return false
end

--- 没勾筛选条件时的队列：直接用收件箱里手动打勾的邮件。
--- 与 batch_scan 同为倒序，且要剔掉越界与 GM 邮件，否则 batch_step 会空转。
function TurtleMail.batch_scan_selected()
  local total = m.api.GetInboxNumItems()
  local seen = {}
  local list = {}
  for k = 1, getn( TurtleMail_SelectedItems ) do
    local i = TurtleMail_SelectedItems[ k ]
    if type( i ) == "number" and i >= 1 and i <= total and not seen[ i ] then
      local _, _, _, _, _, _, _, _, _, _, _, _, isGM = m.api.GetInboxHeaderInfo( i )
      if not isGM then
        seen[ i ] = true
        tinsert( list, i )
      end
    end
  end

  local sorted = {}
  for k = getn( list ), 1, -1 do
    tinsert( sorted, list[ k ] )
  end
  return sorted
end

--- mode: "take" 取件 / "return" 退信 / "delete" 删除
function TurtleMail.batch_start( mode )
  local filters = m.batch_filters or {}

  -- 队列 = 筛选命中 ∪ 手动勾选，去重；两边都是倒序，合并后仍倒序，
  -- 删信时只会影响已处理完的高索引，剩余索引不漂移。
  local filter_hits = {}
  if next( filters ) then
    filter_hits = m.batch_scan( filters )
  end
  local picked = m.batch_scan_selected()

  local queue, seen = {}, {}
  for k = 1, getn( picked ) do
    local i = picked[ k ]
    if not seen[ i ] then
      seen[ i ] = true
      tinsert( queue, i )
    end
  end
  for k = 1, getn( filter_hits ) do
    local i = filter_hits[ k ]
    if not seen[ i ] then
      seen[ i ] = true
      tinsert( queue, i )
    end
  end

  -- 合并后必须整体重排成倒序：两段各自倒序，拼接后不保证。
  -- 取走一封邮件它会从列表消失、比它大的索引全部左移，乱序队列会拿旧索引取空/取错。
  table.sort( queue, function( a, b ) return a > b end )

  -- 有手动勾选参与本次批量，跑完才清空勾选
  if getn( picked ) > 0 then
    m.batch_used_selection = true
  end

  if getn( queue ) == 0 then
    if next( filters ) then
      m.info( L[ "No mail matched" ] )
    else
      m.info( L[ "No filter selected" ] )
    end
    return
  end

  if mode == "take" then
    -- 取件按邮件身份（发件人+主题）排队：索引会随邮件消失漂移，身份不会。
    -- 处理流程在 on_update 的 Mail_open_Selected 分支（与"接收选择邮件"共用）。
    m.take_idents = {}
    for k = 1, getn( queue ) do
      local _, _, sender2, subject2 = m.api.GetInboxHeaderInfo( queue[ k ] )
      tinsert( m.take_idents, { from = sender2, subject = subject2 } )
    end
    TurtleMail_SelectedItems = {}
    if m.batch_panel then m.inbox_refresh_checkboxes() end
    m.Mail_open_Selected = true
    m.inbox_opening = true
    m.inbox_update_lock()
    m.inbox_skip = false
    m.inbox_update = true
    m.take_total = getn( m.take_idents )
    m.take_wait_count = nil
    m.take_waits = 0
    m.inv_waits = 0
    m.batch_queue = nil
    m.batch_opening = false
    m.batch_used_selection = nil
    return
  end

  if mode == "delete" and m.batch_pending_delete ~= getn( queue ) then
    m.batch_pending_delete = getn( queue )
    local tip = m.api.GameTooltip
    tip:Hide()
    tip:ClearLines()
    tip:SetOwner( m.batch_delete_button or m.batch_panel or m.api.InboxFrame, "ANCHOR_LEFT" )
    tip:AddLine( string.format( L[ "Really delete %d mails?" ], getn( queue ) ), "", 1, 0, 0 )
    tip:AddLine( L[ "Click again to confirm" ], "", 1, 0, 0 )
    tip:Show()
    return
  end
  m.batch_pending_delete = nil

  m.batch_mode = mode
  m.batch_queue = queue
  m.batch_total = getn( queue )
  m.batch_done = 0
  m.batch_returned = 0
  m.batch_opening = true

  m.inbox_opening = true
  m.inbox_update_lock()
  m.inbox_skip = false
  m.inbox_update = true
end

function TurtleMail.batch_abort()
  m.batch_opening = false
  m.batch_queue = nil
  m.batch_wait_count = nil
  m.batch_wait_frames = nil
  m.inbox_opening = false
  m.inbox_update_lock()
  m.inbox_update = false
  -- 手动勾选只对本次批量有效，跑完就清空，否则残留索引会指向别的邮件
  if m.batch_used_selection then
    m.batch_used_selection = nil
    TurtleMail_SelectedItems = {}
    if m.batch_panel then
      m.inbox_refresh_checkboxes()
    end
  end
  if m.batch_mode == "return" then
    local returned = m.batch_returned or 0
    if returned > 0 then
      m.info( string.format( L[ "Batch returned: %d" ], returned ) )
    end
  end
  local gained = m.money_received or 0
  if gained > 0 then
    m.info( string.format( "%s%s.", m.format_money( gained ), L[ "collected" ] ) )
    m.money_received = 0
  end
end

function TurtleMail.batch_step()
  if not m.batch_queue or getn( m.batch_queue ) == 0 then
    m.batch_abort()
    if m.batch_done > 0 then
      m.info( string.format( L[ "Batch done: %d" ], m.batch_done ) )
    end
    return false
  end

  -- 1.12 邮箱同一时刻只受理一个取件：上一封还没从列表消失就开下一封会静默失败。
  -- 等 GetInboxNumItems 掉下来（邮件真被取走）才放行下一封，超时 100 帧兜底防卡死。
  -- 与"接收选择邮件"按钮的同步方式（MAIL_INBOX_UPDATE 里等 cur < last_inbox_count）一致。
  if m.batch_wait_count then
    if m.api.GetInboxNumItems() == m.batch_wait_count and ( m.batch_wait_frames or 0 ) < 100 then
      m.batch_wait_frames = ( m.batch_wait_frames or 0 ) + 1
      m.inbox_update = true
      return true
    end
    m.batch_wait_count = nil
    m.batch_wait_frames = nil
  end

  local index = tremove( m.batch_queue, 1 )
  if index > m.api.GetInboxNumItems() then
    m.inbox_update = true
    return true
  end

  local hdr_icon, _, _, _, _, COD, _, _, _, _, _, _, isGM = m.api.GetInboxHeaderInfo( index )
  -- 槽位已空（邮件被取走后列表左移，队里残留的是旧索引）→ 跳过且不计入完成数
  -- GM 邮件与未开启自动到付时的 COD 邮件一律跳过
  if not hdr_icon or isGM or (m.api.TurtleMail_AutoCOD ~= 1 and COD and COD > 0) then
    m.inbox_update = true
    return true
  end

  if m.batch_mode == "delete" then
    m.api.DeleteInboxItem( index )
  elseif m.batch_mode == "return" then
    -- 不要用 InboxItemCanDelete 预判：它在 1.12 存在，但对普通邮件也返回 falsy，
    -- 会把每封都算成"kept"导致退信永远不成功。直接调 ReturnInboxItem，
    -- 退不掉的（已退回过、GM 邮件等）会在下一轮按索引越界自然跳过。
    m.api.ReturnInboxItem( index )
    m.batch_returned = (m.batch_returned or 0 ) + 1
    m.batch_done = m.batch_done + 1
    m.batch_wait_count = m.api.GetInboxNumItems()
    m.batch_wait_frames = 0
    m.inbox_update = true
    return true
  else
    m.inbox_open( index )
  end
  m.batch_done = m.batch_done + 1
  m.batch_wait_count = m.api.GetInboxNumItems()
  m.batch_wait_frames = 0
  m.inbox_update = true
  return true
end

---Sunelegy修复付款取信报错
function TurtleMail.set_cod_text()
    local text = m.api.COD_AMOUNT or ""

  if not m.pfui_skin_enabled then
    -- Lua 5.0 没有 string.match，用 string.find 取捕获
    local _, _, matched = string.find(text, "^(.-)%s+%S+$")
    if matched then
      text = matched
    end
  end

  text = text or ""

  if m.api.SendMailCODAllButton:GetChecked() then
    m.api.SendMailMoneyText:SetText(L["each mail"] .. " " .. text)-- .. " " .. L["each mail"] .. ":")
  else
    m.api.SendMailMoneyText:SetText(L["1st mail"] .. " " .. text)-- .. " " .. L["1st mail"] .. ":")
  end
end

-- 把时间戳格式化为 "2026.8.29 5:23"（月/日/时不补零，24 小时制，分补零）
---@param timestamp number
function TurtleMail.format_datetime( timestamp )
  local _, _, y, mo, d, h, mi = string.find( date( "%Y %m %d %H %M", timestamp ), "^(%d+) (%d+) (%d+) (%d+) (%d+)$" )
  return string.format( "%d.%d.%d %d:%02d", y, mo, d, h, mi )
end

-- 把时间戳格式化为 "2026.8.29"（月/日不补零）
---@param timestamp number
function TurtleMail.format_date( timestamp )
  local _, _, y, mo, d = string.find( date( "%Y %m %d", timestamp ), "^(%d+) (%d+) (%d+)$" )
  return string.format( "%d.%d.%d", y, mo, d )
end

---@param copper number
function TurtleMail.format_money( copper )
  if type( copper ) ~= "number" then return "-" end

  local gold = math.floor( copper / 10000 )
  local silver = math.floor( (copper - gold * 10000) / 100 )
  local copper_remain = copper - (gold * 10000) - (silver * 100)

  local result = ""
  if gold > 0 then
    result = result .. string.format( "|cffffffff%d|cffffd700金|r ", gold )
  end
  if silver > 0 then
    result = result .. string.format( "|cffffffff%d|cffc7c7cf银|r ", silver )
  end
  if copper_remain > 0 or result == "" then
    result = result .. string.format( "|cffffffff%d|cffeda55f铜|r ", copper_remain )
  end

  return result
end

---@param money number
function TurtleMail.update_money( money )
  m.money_received = (m.money_received or 0) + money
  m.api.MoneyReceived:SetText( L[ "Money received" ] .. ": " .. m.format_money( m.money_received ) )

  -- 调整到自动到付底部中央
  m.api.MoneyReceived:ClearAllPoints()
  m.api.MoneyReceived:SetPoint("BOTTOM", m.api.TurtleMailCODCheckButton, "BOTTOM", 11, -13)
  
  if m.money_received > 0 then
    m.api.MoneyReceived:Show()
  else
    m.api.MoneyReceived:Hide()
  end
end

-- 恢复拖动后保存的邮箱窗口位置
function TurtleMail.restore_position()
  if m.api.TurtleMail_Point and m.api.TurtleMail_Point.point then
    m.debug( "Set point" )
    m.api.MailFrame:ClearAllPoints()
    m.api.MailFrame:SetPoint( m.api.TurtleMail_Point.point, m.api.TurtleMail_Point.x, m.api.TurtleMail_Point.y )
  end
end

function TurtleMail.on_drag_stop()
  this:StopMovingOrSizing()
  local point, _, _, x, y = m.api.MailFrame:GetPoint()
  m.api.TurtleMail_Point = { point = point, x = x, y = y }
end

--- GetItemInfo 未回包时返回 nil，解析结果需缓存
function TurtleMail.get_item_name( link )
  if not link or link == "" then return nil end
  local cached = m.item_name_cache[ link ]
  if cached ~= nil then
    if cached == false then return nil end
    return cached
  end

  local ok, name = pcall( m.api.GetItemInfo, link )
  if ok and name and name ~= "" then
    m.item_name_cache[ link ] = name
    return name
  end
  m.item_name_cache[ link ] = false
  return nil
end

---@param i number
---@param manual boolean?
function TurtleMail.inbox_open( i, manual )
  m.debug( "inbox_open" )
  local package_icon, _, sender, subject, money, cod, _, has_item, read, returned, _, _, gm = m.api.GetInboxHeaderInfo( i )

  -- 竞得邮件的花费只在正文里，邮件头 money 恒为 0
  local body = m.api.GetInboxText( i )

  if has_item then
    if not m.received_icon then
      m.received_item = m.api.GetInboxItem( i )
      m.received_icon = package_icon
      -- COD 会在取件付款后被清掉、附件会在 TakeInboxItem 后清空，都得提前取
      m.received_cod = (cod and cod > 0) and cod or nil
      m.received_item_name = m.get_item_name( m.received_item )
    end
  end

  if (read or manual) then
    if money > 0 then
      m.update_money( money )
      m.received_money = money
    end
    if money == 0 or manual then
      local money_logged = manual and money or m.received_money
      -- 竞得邮件的花费是发票式排版（付费金额用钱币图标渲染），正文文本里没有数字可解析，
      -- 走 GetInboxInvoiceInfo（已在 WoW.exe 字符串里验证存在）：返回第 4 值 = 金额
      if ( not money_logged or money_logged == 0 ) and classify_ah_mail( subject ) == "Won" then
        local ok, _, _, _, inv_money = pcall( m.api.GetInboxInvoiceInfo, i )
        if ok and inv_money and inv_money > 0 then
          money_logged = inv_money
        else
          -- 兜底：万一某些客户端把金额写进正文文本
          local bid = m.parse_body_money( body )
          if bid then money_logged = bid end
        end
      end
      m.log.add( "Received", {
        from = sender,
        subject = subject,
        money = money_logged,
        cod = m.received_cod or cod,
        returned = returned,
        gm = gm,
        icon = m.received_icon,
        item = m.received_item,
        item_name = m.received_item_name,
        body = body
      } )
      m.received_money = 0
      m.received_icon = nil
      m.received_item = nil
      m.received_item_name = nil
      m.received_cod = nil
    end
  end

  m.TakeInboxMoney( i )
  m.TakeInboxItem( i )
  m.DeleteInboxItem( i )

end

function TurtleMail.inbox_update_lock()
  for i = 1, 7 do
    m.api[ "MailItem" .. i .. "ButtonIcon" ]:SetDesaturated( m.inbox_opening )
    if m.inbox_opening then
      m.api[ "MailItem" .. i .. "Button" ]:SetChecked( nil )
    end
  end
end

-- 打开/关闭邮件阅读窗格或其它面板时，UIPanel 系统会把 MailFrame 重置回默认面板位置，
-- 在系统重排之后重新应用拖动保存的位置
function TurtleMail.hook.UpdateUIPanelPositions( currentFrame )
  m.orig.UpdateUIPanelPositions( currentFrame )
  m.restore_position()
end

function TurtleMail.hook.GetInboxHeaderInfo( ... )
  local sender, canReply = arg[ 3 ], arg[ 12 ]
  if sender and canReply then
    m.add_auto_complete_name( sender )
  end

  return m.orig.GetInboxHeaderInfo( unpack( arg ) )
end

function TurtleMail.hook.OpenMail_Reply( ... )
  m.api.TurtleMail_To = nil
  return m.orig.OpenMail_Reply( unpack( arg ) )
end

function TurtleMail.hook.InboxFrame_Update()
  m.orig.InboxFrame_Update()
  for i = 1, 7 do
    -- hack for tooltip update
    m.api[ "MailItem" .. i ]:Hide()
    m.api[ "MailItem" .. i ]:Show()
  end

  local currentPage = m.api.InboxFrame.pageNum
  local totalPages = math.ceil( m.api.GetInboxNumItems() / m.api.INBOXITEMS_TO_DISPLAY )
  local text = totalPages > 0 and (currentPage .. "/" .. totalPages) or m.api.EMPTY
  m.api.InboxTitleText:SetText( m.api.INBOX .. " [" .. text .. "]" )

  m.inbox_update_lock()
end

---@param i number
function TurtleMail.hook.InboxFrame_OnClick( i )
  if m.inbox_opening or arg1 == "RightButton" and (m.api.TurtleMail_AutoCOD ~= 1) and ({ m.api.GetInboxHeaderInfo( i ) })[ 6 ] > 0 then --新增自动到付选项
    this:SetChecked( nil )
  elseif arg1 == "RightButton" then
    -- 预取正文/发票并排队延迟开信：竞得邮件的发票金额要等服务器回包，
    -- 右键当场读是 0（邮件随后就删了，再没机会补），日志里就成了"花费:?"
    m.api.GetInboxText( i )
    m.api.GetInboxInvoiceInfo( i )
    m.delayed_opens = m.delayed_opens or {}
    tinsert( m.delayed_opens, { i = i, frames = 10 } )
  else
    return m.orig.InboxFrame_OnClick( i )
  end
end

function TurtleMail.hook.InboxFrameItem_OnEnter()
  m.orig.InboxFrameItem_OnEnter()
  if m.api.GetInboxItem( this.index ) then
    m.api.GameTooltip:AddLine( m.api.ITEM_OPENABLE, "", 0, 1, 0 )
    m.api.GameTooltip:Show()
  end
end

function TurtleMail.hook.SendMailFrame_Update()
  local gap
  local last = m.sendmail_num_attachments()

  for i = 1, ATTACHMENTS_MAX do
    local btn = m.api[ "MailAttachment" .. i ]

    local texture, count
    if btn.item then
      texture, count = m.api.GetContainerItemInfo( unpack( btn.item ) )
    end
    if not texture then
      btn:SetNormalTexture( nil )
      m.api[ btn:GetName() .. "Count" ]:Hide()
      btn.item = nil
    else
      btn:SetNormalTexture( texture )
      if count > 1 then
        m.api[ btn:GetName() .. "Count" ]:Show()
        m.api[ btn:GetName() .. "Count" ]:SetText( count )
      else
        m.api[ btn:GetName() .. "Count" ]:Hide()
      end
    end
  end

  if m.sendmail_num_attachments() > 0 then
    m.api.SendMailCODButton:Enable()
    m.api.SendMailCODButtonText:SetTextColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
    if m.sendmail_num_attachments() > 1 and m.api.SendMailCODButton:GetChecked() then
      m.api.SendMailCODAllButton:Enable()
      m.api.SendMailCODAllButtonText:SetTextColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
      m.set_cod_text()
    else
      m.api.SendMailCODAllButton:Disable()
      m.api.SendMailCODAllButtonText:SetTextColor( m.api.GRAY_FONT_COLOR.r, m.api.GRAY_FONT_COLOR.g, m.api.GRAY_FONT_COLOR.b )
      m.api.SendMailMoneyText:SetText( m.api.AMOUNT_TO_SEND )
    end
  else
    m.api.SendMailSendMoneyButton:SetChecked( 1 )
    m.api.SendMailCODButton:SetChecked( nil )
    m.api.SendMailMoneyText:SetText( m.api.AMOUNT_TO_SEND )
    m.api.SendMailCODButton:Disable()
    m.api.SendMailCODButtonText:SetTextColor( m.api.GRAY_FONT_COLOR.r, m.api.GRAY_FONT_COLOR.g, m.api.GRAY_FONT_COLOR.b )
    m.api.SendMailCODAllButton:Disable()
    m.api.SendMailCODAllButtonText:SetTextColor( m.api.GRAY_FONT_COLOR.r, m.api.GRAY_FONT_COLOR.g, m.api.GRAY_FONT_COLOR.b )
  end

  m.api.MoneyFrame_Update( "SendMailCostMoneyFrame", m.api.GetSendMailPrice() * math.max( 1, m.sendmail_num_attachments() ) )

  -- Determine how many rows of attachments to show
  local itemRowCount = 1
  local temp = last
  while temp > ATTACHMENTS_PER_ROW_SEND and itemRowCount < ATTACHMENTS_MAX_ROWS_SEND do
    itemRowCount = itemRowCount + 1
    temp = temp - ATTACHMENTS_PER_ROW_SEND
  end

  if not gap and temp == ATTACHMENTS_PER_ROW_SEND and itemRowCount < ATTACHMENTS_MAX_ROWS_SEND then
    itemRowCount = itemRowCount + 1
  end
  if m.api.SendMailFrame.maxRowsShown and last > 0 and itemRowCount < m.api.SendMailFrame.maxRowsShown then
    itemRowCount = m.api.SendMailFrame.maxRowsShown
  else
    m.api.SendMailFrame.maxRowsShown = itemRowCount
  end

  -- Compute sizes
  local cursorx = 0
  local cursory = itemRowCount - 1
  local marginxl = 8 + 6
  local marginxr = 40 + 6
  local areax = m.api.SendMailFrame:GetWidth() - marginxl - marginxr
  local iconx = m.api.MailAttachment1:GetWidth() + 2
  local icony = m.api.MailAttachment1:GetHeight() + 2
  local gapx1 = m.api.floor( (areax - (iconx * ATTACHMENTS_PER_ROW_SEND)) / (ATTACHMENTS_PER_ROW_SEND - 1) )
  local gapx2 = m.api.floor( (areax - (iconx * ATTACHMENTS_PER_ROW_SEND) - (gapx1 * (ATTACHMENTS_PER_ROW_SEND - 1))) / 2 )
  local gapy1 = 5
  local gapy2 = 6
  local areay = (gapy2 * 2) + (gapy1 * (itemRowCount - 1)) + (icony * itemRowCount)
  local indentx = marginxl + gapx2 + 17
  local indenty = 170 + gapy2 + icony - 13
  local tabx = (iconx + gapx1) - 3 --this magic number changes the attachment spacing
  local taby = (icony + gapy1)
  local scrollHeight = 249 - areay

  m.api.MailHorizontalBarLeft:SetPoint( "TOPLEFT", m.api.SendMailFrame, "BOTTOMLEFT", 2 + 15, 184 + areay - 14 )

  m.api.SendMailScrollFrame:SetHeight( scrollHeight )
  m.api.SendMailScrollChildFrame:SetHeight( scrollHeight )

  local SendMailScrollFrameTop = ({ m.api.SendMailScrollFrame:GetRegions() })[ 3 ]
  SendMailScrollFrameTop:SetHeight( scrollHeight )
  SendMailScrollFrameTop:SetTexCoord( 0, .484375, 0, scrollHeight / 256 )

  m.api.StationeryBackgroundLeft:SetHeight( scrollHeight )
  m.api.StationeryBackgroundLeft:SetTexCoord( 0, 1, 0, scrollHeight / 256 )


  m.api.StationeryBackgroundRight:SetHeight( scrollHeight )
  m.api.StationeryBackgroundRight:SetTexCoord( 0, 1, 0, scrollHeight / 256 )

  -- Set Items
  for i = 1, ATTACHMENTS_MAX do
    if cursory >= 0 then
      m.api[ "MailAttachment" .. i ]:Enable()
      m.api[ "MailAttachment" .. i ]:Show()
      m.api[ "MailAttachment" .. i ]:SetPoint( "TOPLEFT", "SendMailFrame", "BOTTOMLEFT", indentx + (tabx * cursorx),
        indenty + (taby * cursory) )

      cursorx = cursorx + 1
      if cursorx >= ATTACHMENTS_PER_ROW_SEND then
        cursory = cursory - 1
        cursorx = 0
      end
    else
      m.api[ "MailAttachment" .. i ]:Hide()
    end
  end

  m.api.SendMailFrame_CanSend()
end

function TurtleMail.hook.SendMailRadioButton_OnClick( index )
  if (index == 1) then
    m.api.SendMailSendMoneyButton:SetChecked( 1 );
    m.api.SendMailCODButton:SetChecked( nil );
    m.api.SendMailMoneyText:SetText( m.api.AMOUNT_TO_SEND );
    m.api.SendMailCODAllButton:Disable()
    m.api.SendMailCODAllButtonText:SetTextColor( m.api.GRAY_FONT_COLOR.r, m.api.GRAY_FONT_COLOR.g, m.api.GRAY_FONT_COLOR.b )
  else
    m.api.SendMailSendMoneyButton:SetChecked( nil );
    m.api.SendMailCODButton:SetChecked( 1 );
    m.api.SendMailMoneyText:SetText( m.api.COD_AMOUNT );

    if m.sendmail_num_attachments() > 1 then
      m.api.SendMailCODAllButton:Enable()
      m.api.SendMailCODAllButtonText:SetTextColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
      m.set_cod_text()
    end
  end
  m.api.PlaySound( "igMainMenuOptionCheckBoxOn" );
end

function TurtleMail.hook.ClickSendMailItemButton()
  m.sendmail_set_attachment( m.get_cursor_item() )
end

function TurtleMail.hook.GetContainerItemInfo( bag, slot )
  local ret = pack( m.orig.GetContainerItemInfo( bag, slot ) )
  ret[ 3 ] = ret[ 3 ] or m.sendmail_attached( bag, slot ) and 1 or nil
  return unpack( ret )
end

function TurtleMail.hook.PickupContainerItem( bag, slot )
  -- Alt+Left: add all same items Alt+左键一键添加相同物品到发送框
  if arg1 == "LeftButton" and m.api.IsAltKeyDown() and m.api.MailFrame:IsVisible() then
    local link = m.api.GetContainerItemLink(bag, slot)
    if link then
      local _, _, itemId = string.find(link, "item:(%d+)")
      if itemId then
        itemId = tonumber(itemId)
        -- Iterate through all bags
        for b = 0, 4 do
          local slots = m.api.GetContainerNumSlots(b)
          for s = 1, slots do
            -- Check if attachment slots are full
            if m.sendmail_num_attachments() >= ATTACHMENTS_MAX then
              break
            end
            local l = m.api.GetContainerItemLink(b, s)
            if l then
              local _, _, id = string.find(l, "item:(%d+)")
              if id and tonumber(id) == itemId then
                if not m.sendmail_attached(b, s) then
                  m.sendmail_set_attachment({b, s})
                end
              end
            end
          end
          if m.sendmail_num_attachments() >= ATTACHMENTS_MAX then
            break
          end
        end
      end
    end
    return
  end

  if m.sendmail_attached( bag, slot ) then
    if arg1 == "RightButton" and m.api.MailFrame:IsVisible() then
      return m.sendmail_remove_attachment( { bag, slot } )
    end
    return m.orig.PickupContainerItem( bag, slot )
  end

  if m.api.GetContainerItemInfo( bag, slot ) then
    if arg1 == "RightButton" and m.api.MailFrame:IsVisible() then
      m.sendmail_show_send_tab()
      m.sendmail_set_attachment( { bag, slot } )
      return
    else
      m.set_cursor_item( { bag, slot } )
    end
  end
  return m.orig.PickupContainerItem( bag, slot )
end

function TurtleMail.hook.SplitContainerItem( bag, slot, amount )
  if m.sendmail_attached( bag, slot ) then return end
  return m.orig.SplitContainerItem( bag, slot, amount )
end

function TurtleMail.hook.UseContainerItem( bag, slot, onself )
  if m.sendmail_attached( bag, slot ) then return end
  if m.api.IsShiftKeyDown() or m.api.IsControlKeyDown() or m.api.IsAltKeyDown() then
    return m.orig.UseContainerItem( bag, slot, onself )
  elseif m.api.MailFrame:IsVisible() then
    m.sendmail_show_send_tab()
    m.sendmail_set_attachment( { bag, slot } )
  elseif m.api.TradeFrame:IsVisible() then
    for i = 1, 6 do
      if not m.api.GetTradePlayerItemLink( i ) then
        m.orig.PickupContainerItem( bag, slot )
        m.api.ClickTradeButton( i )
        return
      end
    end
  else
    return m.orig.UseContainerItem( bag, slot, onself )
  end
end

function TurtleMail.hook.SendMailFrame_CanSend()
  if not m.sendmail_sending and string.len( m.api.SendMailNameEditBox:GetText() ) > 0 and (m.api.SendMailSendMoneyButton:GetChecked() and m.api.MoneyInputFrame_GetCopper( m.api.SendMailMoney ) or 0) + m.api.GetSendMailPrice() * math.max( 1, m.sendmail_num_attachments() ) <= m.api.GetMoney() then
    MailMailButton:Enable()
  else
    MailMailButton:Disable()
  end
end

function TurtleMail.hook.MailFrameTab_OnClick( tab )
  if not tab then
    tab = this:GetID()
  end

  if tab == 3 then
    m.api.PanelTemplates_SetTab( m.api.MailFrame, 3 )
    m.api.InboxFrame:Hide()
    m.api.SendMailFrame:Hide()
    m.api.TurtleMailLogFrame:Show()
    m.api.MailFrameTopLeft:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopLeft" )
    m.api.MailFrameTopRight:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopRight" )
    m.api.MailFrameBotLeft:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotLeft" )
    m.api.MailFrameBotRight:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotRight" )
    m.api.MailFrameTopLeft:SetPoint( "TOPLEFT", "MailFrame", "TOPLEFT", 2, -1 )
    m.log.populate( "Received" )
    return
  else
    m.api.TurtleMailLogFrame:Hide()
  end

  m.orig.MailFrameTab_OnClick( tab )
end

function TurtleMail.hook.OpenMailFrame_OnHide()
  if m.api.InboxFrame.openMailID then
    local package_icon, _, sender, subject, money, cod, _, itemID, _, returned, text_created, _, gm = m.api.GetInboxHeaderInfo( m.api.InboxFrame.openMailID )
    if (money == 0 and not itemID and text_created) then
      local received_item = m.api.GetInboxItem( m.api.InboxFrame.openMailID )
      m.log.add( "Received", {
        from = sender,
        subject = subject,
        money = money,
        cod = cod,
        returned = returned,
        gm = gm,
        icon = package_icon,
        item = received_item
      } )
    end
  else
    m.debug( "returning mail" )
  end

  m.orig.OpenMailFrame_OnHide()
end

function TurtleMail.send_mail_button_onclick()
  m.api.MailAutoCompleteBox:Hide()

  m.api.TurtleMail_To = m.api.SendMailNameEditBox:GetText()
  m.api.SendMailNameEditBox:HighlightText()

  m.sendmail_state = {
    to = m.api.TurtleMail_To,
    subject = MailSubjectEditBox:GetText(),
    body = m.api.SendMailBodyEditBox:GetText(),
    money = m.api.MoneyInputFrame_GetCopper( m.api.SendMailMoney ),
    cod = m.api.SendMailCODButton:GetChecked(),
    attachments = m.sendmail_attachments(),
    numMessages = math.max( 1, m.sendmail_num_attachments() ),
  }

  m.sendmail_clear()
  m.sendmail_sending = true
  m.sendmail_send()
end

function TurtleMail.sendmail_load()
  m.api.SendMailFrame:EnableMouse( false )

  m.api.SendMailFrame:CreateTexture( "MailHorizontalBarLeft", "BACKGROUND" )
  m.api.MailHorizontalBarLeft:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar" )
  m.api.MailHorizontalBarLeft:SetWidth( 256 )
  m.api.MailHorizontalBarLeft:SetHeight( 16 )
  m.api.MailHorizontalBarLeft:SetTexCoord( 0, 1, 0, .25 )

  m.api.SendMailFrame:CreateTexture( "MailHorizontalBarRight", "BACKGROUND" )
  m.api.MailHorizontalBarRight:SetTexture( "Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar" )
  m.api.MailHorizontalBarRight:SetWidth( 75 )
  m.api.MailHorizontalBarRight:SetHeight( 16 )
  m.api.MailHorizontalBarRight:SetTexCoord( 0, .29296875, .25, .5 )
  m.api.MailHorizontalBarRight:SetPoint( "LEFT", m.api.MailHorizontalBarLeft, "RIGHT" )

  m.api.SendMailMoneyText:SetJustifyH( "LEFT" )
  m.api.SendMailMoneyText:SetPoint( "TOPLEFT", 0, 0 )
  m.api.SendMailMoney:ClearAllPoints()
  m.api.SendMailMoney:SetPoint( "TOPLEFT", m.api.SendMailMoneyText, "BOTTOMLEFT", 5, -5 )
  m.api.SendMailMoneyGoldRight:SetPoint( "RIGHT", 20, 0 )
  do ({ m.api.SendMailMoneyGold:GetRegions() })[ 9 ]:SetDrawLayer( "BORDER" ) end
  m.api.SendMailMoneyGold:SetMaxLetters( 7 )
  m.api.SendMailMoneyGold:SetWidth( 50 )
  m.api.SendMailMoneySilverRight:SetPoint( "RIGHT", 10, 0 )
  do ({ m.api.SendMailMoneySilver:GetRegions() })[ 9 ]:SetDrawLayer( "BORDER" ) end
  m.api.SendMailMoneySilver:SetWidth( 28 )
  m.api.SendMailMoneySilver:SetPoint( "LEFT", m.api.SendMailMoneyGold, "RIGHT", 30, 0 )
  m.api.SendMailMoneyCopperRight:SetPoint( "RIGHT", 10, 0 )
  do ({ m.api.SendMailMoneyCopper:GetRegions() })[ 9 ]:SetDrawLayer( "BORDER" ) end
  m.api.SendMailMoneyCopper:SetWidth( 28 )
  m.api.SendMailMoneyCopper:SetPoint( "LEFT", m.api.SendMailMoneySilver, "RIGHT", 20, 0 )
  m.api.SendMailSendMoneyButton:SetPoint( "TOPLEFT", m.api.SendMailMoney, "TOPRIGHT", 20, 25 )

  -- hack to avoid automatic subject setting and button disabling from weird blizzard code
  MailMailButton = m.api.SendMailMailButton
  m.api.SendMailMailButton = setmetatable( {}, { __index = function() return function() end end } )
  m.api.SendMailMailButton_OnClick = m.send_mail_button_onclick
  MailSubjectEditBox = m.api.SendMailSubjectEditBox
  m.api.SendMailSubjectEditBox = setmetatable( {}, {
    __index = function( _, key )
      return function( _, ... )
        return MailSubjectEditBox[ key ]( MailSubjectEditBox, unpack( arg ) )
      end
    end,
  } )

  m.api.SendMailNameEditBox._SetText = m.api.SendMailNameEditBox.SetText
  function m.api.SendMailNameEditBox:SetText( ... )
  -- 确保在选择新收件人时能正常更新输入框内容
    local text = unpack(arg)
	 self:_SetText(text)
  end

  m.api.SendMailNameEditBox:SetScript( "OnShow", function()
    if m.api.TurtleMail_To then
      m.api.this:_SetText( m.api.TurtleMail_To )
    end
  end )
  m.api.SendMailNameEditBox:SetScript( "OnChar", function()
    m.api.TurtleMail_To = nil
    GetSuggestions()
  end )
  m.api.SendMailNameEditBox:SetScript( "OnTabPressed", function()
    if m.api.MailAutoCompleteBox:IsVisible() then
      if m.api.IsShiftKeyDown() then
        m.previous_match()
      else
        m.next_match()
      end
    else
      MailSubjectEditBox:SetFocus()
    end
  end )
  m.api.SendMailNameEditBox:SetScript( "OnEnterPressed", function()
    if m.api.MailAutoCompleteBox:IsVisible() then
      m.api.MailAutoCompleteBox:Hide()
      this:HighlightText( 0, 0 )
    else
      MailSubjectEditBox:SetFocus()
    end
  end )
  m.api.SendMailNameEditBox:SetScript( "OnEscapePressed", function()
    if m.api.MailAutoCompleteBox:IsVisible() then
      m.api.MailAutoCompleteBox:Hide()
    else
      this:ClearFocus()
    end
  end )
  function m.api.SendMailNameEditBox.focusLoss()
    m.api.MailAutoCompleteBox:Hide()
  end

  m.api.SendMailCODAllButtonText:SetText( L[ "All mails" ] )
  m.api.SendMailCODAllButton:SetScript( "OnClick", m.set_cod_text )

  do

  end

  for _, editBox in { m.api.SendMailNameEditBox, m.api.SendMailSubjectEditBox } do
    editBox:SetScript( "OnEditFocusGained", function()
      this:HighlightText()
    end )
    editBox:SetScript( "OnEditFocusLost", function()
      (this.focusLoss or function() end)()
      this:HighlightText( 0, 0 )
    end )
    do
      local lastClick
      editBox:SetScript( "OnMouseDown", function()
        local x, y = m.api.GetCursorPosition()
        if lastClick and m.api.GetTime() - lastClick.t < .5 and x == lastClick.x and y == lastClick.y then
          this:SetScript( "OnUpdate", function()
            this:HighlightText()
            this:SetScript( "OnUpdate", nil )
          end )
        end
        lastClick = { t = m.api.GetTime(), x = x, y = y }
      end )
    end
  end
end

--@param bag number
--@param slot number
function TurtleMail.sendmail_attached( bag, slot )
  if not m.api.MailFrame:IsVisible() then return false end
  for i = 1, ATTACHMENTS_MAX do
    local btn = m.api[ "MailAttachment" .. i ]
    if btn.item and btn.item[ 1 ] == bag and btn.item[ 2 ] == slot then
      return true
    end
  end
  if m.sendmail_state then
    for _, attachment in m.sendmail_state.attachments do
      if attachment[ 1 ] == bag and attachment[ 2 ] == slot then
        return true
      end
    end
  end
end

-- 已经在发信页就别再切一次：MailFrameTab_OnClick 会连带 Hide/Show 一整套 + 一次完整 Update
function TurtleMail.sendmail_show_send_tab()
  if not m.api.SendMailFrame:IsVisible() then
    m.api.MailFrameTab_OnClick( 2 )
  end
end

function TurtleMail.attachment_button_on_click()
  local attachedItem = this.item
  local cursorItem = m.get_cursor_item()
  if m.sendmail_set_attachment( cursorItem, this ) then
    if attachedItem then
      if arg1 == "LeftButton" then m.set_cursor_item( attachedItem ) end
      m.orig.PickupContainerItem( unpack( attachedItem ) )
      if arg1 ~= "LeftButton" then m.api.ClearCursor() end -- for the lock changed event
    end
  end
end

function TurtleMail.sendmail_remove_attachment( item )
  if not item then return end
  if type( item ) == "table" and m.sendmail_attached( item[ 1 ], item[ 2 ] ) then
    for i = 1, ATTACHMENTS_MAX do
      local btn = m.api[ "MailAttachment" .. i ]
      if btn.item and btn.item[ 1 ] == item[ 1 ] and btn.item[ 2 ] == item[ 2 ] then
        m.api[ "MailAttachment" .. i ].item = nil
        m.orig.PickupContainerItem( unpack( item ) )
        m.api.ClearCursor()
        m.sendmail_queue_update()
        return
      end
    end
  end
end

-- requires an item lock changed event for a proper update
---@param item table
---@param slot number?
function TurtleMail.sendmail_set_attachment( item, slot )
  if item and not m.sendmail_pickup_mailable( item ) then
    m.api.ClearCursor()
    return
  elseif not slot then
    for i = 1, ATTACHMENTS_MAX do
      if not m.api[ "MailAttachment" .. i ].item then
        slot = m.api[ "MailAttachment" .. i ]
        break
      end
    end
  end
  if slot then
    if not (item or slot.item) then return true end
    slot.item = item
    m.api.ClearCursor()
    m.sendmail_queue_update()
    return true
  end
end

---@param item table
function TurtleMail.sendmail_pickup_mailable( item )
  -- 命中缓存直接放行：跳过"拿起→塞进邮寄槽→读回→取出"这串锁操作。
  -- 原写法每次右键都抛 4 次 ITEM_LOCK_CHANGED，pfUI/Guda 会跟着把全背包重扫 4 遍 = 卡顿来源
  local _, _, itemId = string.find( m.api.GetContainerItemLink( item[ 1 ], item[ 2 ] ) or "", "item:(%d+)" )
  if itemId and m.mailable[ itemId ] then return true end

  m.api.ClearCursor()
  -- 邮寄槽平时是空的，只有真有残留时才值得多花这一次锁操作
  if m.api.GetSendMailItem() then
    m.orig.ClickSendMailItemButton()
    m.api.ClearCursor()
  end
  m.orig.PickupContainerItem( unpack( item ) )
  m.orig.ClickSendMailItemButton()
  local mailable = m.api.GetSendMailItem() and true or false
  m.orig.ClickSendMailItemButton()
  -- 只缓存能邮的：绑定是实例级的，同 itemID 可能有的绑有的没绑
  if mailable and itemId then
    m.mailable[ itemId ] = true
  end
  return mailable
end

function TurtleMail.sendmail_num_attachments()
  local x = 0
  for i = 1, ATTACHMENTS_MAX do
    if m.api[ "MailAttachment" .. i ].item then
      x = x + 1
    end
  end
  return x
end

function TurtleMail.sendmail_attachments()
  local t = {}
  for i = 1, ATTACHMENTS_MAX do
    local btn = m.api[ "MailAttachment" .. i ]
    if btn.item then
      table.insert( t, btn.item )
    end
  end
  return t
end

function TurtleMail.sendmail_clear()
  local anyItem
  for i = 1, ATTACHMENTS_MAX do
    anyItem = anyItem or m.api[ "MailAttachment" .. i ].item
    m.api[ "MailAttachment" .. i ].item = nil
  end
  if anyItem then
    m.api.ClearCursor()
    -- 必须走原版：hook 版在 arg1 还是 "RightButton" 时会把物品重新挂回附件格
    m.orig.PickupContainerItem( unpack( anyItem ) )
    m.api.ClearCursor()
  end
  MailMailButton:Disable()
  m.api.SendMailNameEditBox:SetText ""
  m.api.SendMailNameEditBox:SetFocus()
  MailSubjectEditBox:SetText ""
  m.api.SendMailBodyEditBox:SetText ""
  m.api.MoneyInputFrame_ResetMoney( m.api.SendMailMoney )
  m.api.SendMailRadioButton_OnClick( 1 )

  m.sendmail_queue_update()
end

function TurtleMail.sendmail_send()
  local item = table.remove( m.sendmail_state.attachments, 1 )
  if item then
    m.api.ClearCursor()
    m.orig.ClickSendMailItemButton()
    m.api.ClearCursor()
    m.orig.PickupContainerItem( unpack( item ) )
    m.orig.ClickSendMailItemButton()

    if not m.api.GetSendMailItem() then
      m.api.DEFAULT_CHAT_FRAME:AddMessage( "|cffabd473TurtleMail|r: " .. m.api.ERROR_CAPS, 1, 0, 0 )
      return
    end
  end

  local amount = m.sendmail_state.money
  m.sendmail_state.sent_money = m.sendmail_state.money
  m.sendmail_state.sent = false

  if amount > 0 then
    if not m.api.SendMailCODAllButton:GetChecked() then
      m.sendmail_state.money = 0
    end
    if m.sendmail_state.cod then
      m.sendmail_state.cod = amount
      m.api.SetSendMailCOD( amount )
    else
      m.sendmail_state.money = 0
      m.api.SetSendMailMoney( amount )
    end
  end

  local subject = m.sendmail_state.subject
  if subject == "" then
    if item then
      local item_name, texture, stack_count = m.api.GetSendMailItem()
      subject = item_name .. (stack_count > 1 and " (" .. stack_count .. ")" or "")
      m.sendmail_state.item = item_name
      m.sendmail_state.icon = texture
    else
      subject = "<" .. m.api.NO_ATTACHMENTS .. ">"
    end
  elseif m.sendmail_state.numMessages > 1 then
    subject = subject .. string.format( " [%d/%d]", m.sendmail_state.numMessages - getn( m.sendmail_state.attachments ),
      m.sendmail_state.numMessages )
  end

  m.sendmail_state.sent_subject = subject

  m.debug( "SendMail" )
  m.api.SendMail( m.sendmail_state.to, subject, m.sendmail_state.body )

  if getn( m.sendmail_state.attachments ) == 0 then
    m.sendmail_sending = false
  end
end

do
  local inputLength
  local matches = {}
  local index

  local function complete()
    m.api.SendMailNameEditBox:SetText( matches[ index ] )
    m.api.SendMailNameEditBox:HighlightText( inputLength, -1 )
    for i = 1, m.api.MAIL_AUTOCOMPLETE_MAX_BUTTONS do
      local button = m.api[ "MailAutoCompleteButton" .. i ]
      if i == index then
        button:LockHighlight()
      else
        button:UnlockHighlight()
      end
    end
  end

  function TurtleMail.previous_match()
    if index then
      index = index > 1 and index - 1 or getn( matches )
      complete()
    end
  end

  function TurtleMail.next_match()
    if index then
      ---@diagnostic disable-next-line: undefined-global
      index = mod( index, getn( matches ) ) + 1
      complete()
    end
  end

  function TurtleMail.select_match( i )
    index = i
    complete()
    m.api.MailAutoCompleteBox:Hide()
    m.api.SendMailNameEditBox:HighlightText( 0, 0 )
  end

  function GetSuggestions()
    local input = m.api.SendMailNameEditBox:GetText()
    inputLength = string.len( input )

    ---@diagnostic disable-next-line: undefined-field
    table.setn( matches, 0 )
    index = nil

	local autoCompleteNames = {}
	local key = get_realm_faction_key()
	local names_table = m.api.TurtleMail_AutoCompleteNames[ key ] or {}
	for name, time in pairs( names_table ) do
	  table.insert( autoCompleteNames, { name = name, time = time } )
	end

    table.sort( autoCompleteNames, function( a, b ) return b.time < a.time end )

    local ignore = { [ m.api.UnitName "player" ] = true }
    local function process( name )
      if name then
        if not ignore[ name ] and string.find( string.upper( name ), string.upper( input ), nil, true ) == 1 then
          table.insert( matches, name )
        end
        ignore[ name ] = true
      end
    end
    for _, t in autoCompleteNames do
      process( t.name )
    end
    for i = 1, m.api.GetNumFriends() do
      process( m.api.GetFriendInfo( i ) )
    end
    for i = 1, m.api.GetNumGuildMembers( true ) do
      process( m.api.GetGuildRosterInfo( i ) )
    end

    ---@diagnostic disable-next-line: undefined-field
    table.setn( matches, math.min( getn( matches ), m.api.MAIL_AUTOCOMPLETE_MAX_BUTTONS ) )
    if getn( matches ) > 0 and (getn( matches ) > 1 or input ~= matches[ 1 ]) then
      for i = 1, m.api.MAIL_AUTOCOMPLETE_MAX_BUTTONS do
        local button = m.api[ "MailAutoCompleteButton" .. i ]
        if i <= getn( matches ) then
          button:SetText( matches[ i ] )
          button:GetFontString():SetPoint( "LEFT", button, "LEFT", 15, 0 )
          button:Show()
        else
          button:Hide()
        end
      end
      m.api.MailAutoCompleteBox:SetHeight( getn( matches ) * m.api.MailAutoCompleteButton1:GetHeight() + 35 )
      m.api.MailAutoCompleteBox:SetWidth( 120 )
      m.api.MailAutoCompleteBox:Show()
      index = 1
      complete()
    else
      m.api.MailAutoCompleteBox:Hide()
    end
  end
end

function TurtleMail.log.load()
  m.api.TurtleMailLogTitleText:SetText( L[ "Log" ] )
  m.api.MailFrameTab3:SetText( L[ "Log" ] )

  local font_file = m.pfui_skin_enabled and m.api.pfUI.font_default or "FONTS\\ARIALN.TTF"
  local font_size = 11

  for i = 1, 10 do
    m.api[ "TurtleMailLogItem" .. i .. "Background" ]:SetVertexColor( .5, .5, .5, 0.6 )
    m.api[ "TurtleMailLogItem" .. i .. "TimeStamp" ]:SetTextColor( 1, 1, 1, 1 )
    m.api[ "TurtleMailLogItem" .. i .. "TimeStamp" ]:SetJustifyH( "LEFT" )
    m.api[ "TurtleMailLogItem" .. i .. "TimeStamp" ]:SetFont( font_file, font_size )
    m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:SetTextColor( 1, 1, 1, 1 )
    m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:SetJustifyH( "RIGHT" )
    m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:SetFont( font_file, font_size )
    m.api[ "TurtleMailLogItem" .. i .. "Subject" ]:SetJustifyH( "LEFT" )
    m.api[ "TurtleMailLogItem" .. i .. "Subject" ]:SetFont( font_file, font_size )
    m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetTextColor( 1, 1, 1, 1 )
    m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetJustifyH( "LEFT" )
    m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetFont( font_file, font_size )
    m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetVertexColor( m.api.NORMAL_FONT_COLOR.r, m.api.NORMAL_FONT_COLOR.g, m.api.NORMAL_FONT_COLOR.b )
    if i > 1 then
      m.api[ "TurtleMailLogItem" .. i ]:SetPoint( "TOPLEFT", m.api[ "TurtleMailLogItem" .. i - 1 ], "BOTTOMLEFT", 0, -1 )
    end
  end
  m.api.TurtleMailLogItem10Background:Hide()

  m.api.TurtleMailLogStatusText:SetTextColor( 1, 1, 1, 1 )
  m.api.TurtleMailLogStatusText:SetFont( "Fonts\\FRIZQT__.TTF", 10 )
  m.api.TurtleMailLogScrollFrameScrollBar:SetValueStep( 1 )
  m.api.TurtleMailLogScrollFrameScrollBar:SetScript( "OnValueChanged", m.log.on_scroll_value_changed )

  m.api.TurtleMailLogScrollFrame:SetScript( "OnMouseWheel", function()
    m.log.scroll( arg1 * 10 )
  end )
  m.api.TurtleMailLogScrollFrameScrollBarScrollUpButton:SetScript( "OnClick", function()
    m.api.PlaySound( "UChatScrollButton" );
    m.log.scroll( 10 )
  end )
  m.api.TurtleMailLogScrollFrameScrollBarScrollDownButton:SetScript( "OnClick", function()
    m.api.PlaySound( "UChatScrollButton" );
    m.log.scroll( -10 )
  end )

  m.api.TurtleMailLogFiltersButton:SetText( L[ "Filters" ] )
  m.api.TurtleMailLogFiltersButton:GetFontString():SetPoint( "LEFT", m.api.TurtleMailLogFiltersButton, "LEFT", 10, 0 )

  m.api.TurtleMailLogFiltersButton:SetScript( "OnMouseDown", function()
    m.api.TurtleMailLogFiltersButtonArrow:SetPoint( "RIGHT", m.pfui_skin_enabled and -4 or -8, -3 )
  end )
  m.api.TurtleMailLogFiltersButton:SetScript( "OnMouseUp", function()
    m.api.TurtleMailLogFiltersButtonArrow:SetPoint( "RIGHT", m.pfui_skin_enabled and -4 or -8, -1 )
  end )

  m.api.TurtleMailLogStartTimeText:SetTextColor( 1, 1, 1, 1 )
  m.api.TurtleMailLogStartTimeButton:SetScale( 0.9 )
  m.api.TurtleMailLogEndTimeText:SetTextColor( 1, 1, 1, 1 )
  m.api.TurtleMailLogEndTimeButton:SetScale( 0.9 )

  m.api.TurtleMailLogStartTime:SetScript( "OnClick", function()
    m.api.TurtleMailLogStartTimeText:SetText( "" )
    m[ m.current_log_type .. "_start_time" ] = nil
    m.log.populate( m.current_log_type )
  end )
  m.api.TurtleMailLogEndTime:SetScript( "OnClick", function()
    m.api.TurtleMailLogEndTimeText:SetText( "" )
    m[ m.current_log_type .. "_end_time" ] = nil
    m.log.populate( m.current_log_type )
  end )

  m.api.TurtleMailLogPlayersDropDown:SetScale( 0.9 )
  m.api.UIDropDownMenu_SetText( L[ "All players"] , m.api.TurtleMailLogPlayersDropDown )

  m.dropdown_filters = m.api.CreateFrame( "Frame", "TurtleMailDropDownFilters" )
  m.dropdown_filters.displayMode = "MENU"
  m.dropdown_filters.info = {}
end

function TurtleMail.log.players_dropdown_on_load()
  m.api.UIDropDownMenu_Initialize( m.api.TurtleMailLogPlayersDropDown, function()
    local info = {}
    info.notCheckable = 1
    info.text = L[ "All players"]
    info.arg1 = info.text
    info.arg2 = "All"
    info.func = m.log.select_player
    m.api.UIDropDownMenu_AddButton( info )

    if not m.current_log_type then return end

    local players = {}
    for _, v in ipairs( m.api.TurtleMail_Log[ m.current_log_type ] ) do
      if v then
        players[ v.participant ] = players[ v.participant ] and players[ v.participant ] + 1 or 1
      end
    end

    for player, count in pairs( players ) do
      info.text = player .. " (" .. count .. ")"
      info.arg1 = player
      info.arg2 = nil
      m.api.UIDropDownMenu_AddButton( info )
    end
  end )
end

function TurtleMail.log.select_player( player, is_all )
  m.api.UIDropDownMenu_SetText( player, m.api.TurtleMailLogPlayersDropDown )
  if is_all then
    m.filter_player = nil
  else
    m.filter_player = player
  end
  m.log.populate( m.current_log_type )
end

function TurtleMail.log.filter_dropdown()
  if m.dropdown_filters.initialize ~= TurtleMail.log.filters_menu then
    m.api.CloseDropDownMenus()
    m.dropdown_filters.initialize = TurtleMail.log.filters_menu
  end
  m.api.ToggleDropDownMenu( 1, nil, m.dropdown_filters, this:GetName(), 0, 0 )
end

function TurtleMail.log.filters_menu( level )
  local filters = m.api.TurtleMail_Log[ "Settings" ][ m.current_log_type .. "Filters" ] or {}
  local info = {}
  info.keepShownOnClick = 1

  -- 键名必须与 TurtleMail_Log.Settings 各过滤表及 populate 使用的英文键一致
  local values = { "Money", "COD", "Other" }
  if m.current_log_type == "Received" then
    table.insert( values, "Returned" )
    table.insert( values, "AH" )
  end

  if level == 1 then
    for _, filter in values do
      info.text = L[ filter ]
      info.checked = filters[ filter ]
      info.arg1 = filter
      info.func = m.log.toggle_filter
      if filter == "AH" then info.hasArrow = 1 end

      m.api.UIDropDownMenu_AddButton( info, level )
    end

    -- 清空日志入口：菜单末尾红字项，点击弹确认框（新表防复用 info 带上 keepShownOnClick 导致菜单不关）
    info = { notCheckable = 1 }
    info.text = "|cffff3333清空日志|r"
    info.func = TurtleMail.clear_log_confirm
    m.api.UIDropDownMenu_AddButton( info, level )
  elseif level == 2 then
    -- 一级菜单的 hasArrow 会残留在复用的 info 上，清掉
    info.hasArrow = nil
    for _, filter in { "Sold", "Removed", "Expired", "Outbid", "Won" } do
      info.text = L[ filter ]
      info.checked = filters[ "AH" .. filter ]
      info.arg1 = filter
      info.arg2 = "AH"
      info.func = m.log.toggle_filter
      m.api.UIDropDownMenu_AddButton( info, level )
    end
  end
end

function TurtleMail.log.toggle_filter( filter, parent_filter )
  if not parent_filter then parent_filter = "" end
  local filter_value = m.api.TurtleMail_Log[ "Settings" ][ m.current_log_type .. "Filters" ][ parent_filter .. filter ]

  m.api.TurtleMail_Log[ "Settings" ][ m.current_log_type .. "Filters" ][ parent_filter .. filter ] = not filter_value
  m.log.populate( m.current_log_type )
end

function TurtleMail.log.show_calendar()
  if m.calendar.is_visible() then
    m.calendar.hide()
  else
    local text = string.gsub( this:GetName(), "Button", "Text" )
    m.calendar.show( m.api.TurtleMail_Log[ m.current_log_type ], time(), this, function( selected_date )
      local date_str = m.format_date( selected_date )
      m.api[ text ]:SetText( date_str )

      local v = m.current_log_type .. (string.find( text, "Start" ) and "_start_time" or "_end_time")
      m[ v ] = selected_date
      m.log.populate( m.current_log_type )
    end )
  end
end

function TurtleMail.log.scroll( step )
  local scroll_bar = m.api.TurtleMailLogScrollFrameScrollBar
  local current = scroll_bar:GetValue()
  local min, max = scroll_bar:GetMinMaxValues()
  local new = current - step

  if new >= max then
    scroll_bar:SetValue( max )
  elseif new <= min then
    scroll_bar:SetValue( 0 )
  else
    scroll_bar:SetValue( new )
  end
end

function TurtleMail.log.on_scroll_value_changed()
  local function round( num )
    return num + (2 ^ 52 + 2 ^ 51) - (2 ^ 52 + 2 ^ 51)
  end

  local scrollBar = m.api.TurtleMailLogScrollFrameScrollBar
  local scrollUp = m.api.TurtleMailLogScrollFrameScrollBarScrollUpButton
  local scrollDown = m.api.TurtleMailLogScrollFrameScrollBarScrollDownButton

  local minVal, maxVal = scrollBar:GetMinMaxValues()
  local currentVal = round( scrollBar:GetValue() )

  if currentVal <= round( minVal ) then
    scrollUp:Disable()
  else
    scrollUp:Enable()
  end

  if currentVal >= round( maxVal ) then
    scrollDown:Disable()
  else
    scrollDown:Enable()
  end

  m.log.populate( m.current_log_type, currentVal )
end

---@alias LogType
---| "Sent"
---| "Received"

---@param log_type LogType
---@param state table
function TurtleMail.log.add( log_type, state )
  if not m.log_enabled then return end
  m.debug( "Logging " .. log_type .. " message" )

  local data = {
    timestamp = time(),
    icon = state.icon,
    item = state.item
  }

  if state.item_name then data.item_name = state.item_name end
  -- 留档邮件正文：竞得(Won)类邮件的花费金额只在正文里，邮件头没有该字段
  if state.body and state.body ~= "" then data.body = state.body end

  if state.cod and state.cod > 0 then data.cod = tonumber( state.cod ) end
  if log_type == "Sent" then
    data.participant = state.to
    data.subject = state.sent_subject
    if state.send_money and state.sent_money > 0 then data.money = tonumber( state.sent_money ) end
  else -- Received
    data.participant = state.from
    data.subject = state.subject
    data.returned = state.returned
    data.gm = state.gm

    if state.money and state.money > 0 then data.money = tonumber( state.money ) end

    if string.find( data.subject, string.gsub( m.api.AUCTION_SOLD_MAIL_SUBJECT, "%%s", "" ) ) then
      data[ "ah" ] = "Sold"
    elseif string.find( data.subject, string.gsub( m.api.AUCTION_REMOVED_MAIL_SUBJECT, "%%s", "" ) ) then
      data[ "ah" ] = "Removed"
    elseif string.find( data.subject, string.gsub( m.api.AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", "" ) ) then
      data[ "ah" ] = "Expired"
    elseif string.find( data.subject, string.gsub( m.api.AUCTION_WON_MAIL_SUBJECT, "%%s", "" ) ) then
      data[ "ah" ] = "Won"
    elseif string.find( data.subject, string.gsub( m.api.AUCTION_OUTBID_MAIL_SUBJECT, "%%s", "" ) ) then
      data[ "ah" ] = "Outbid"
    end
  end

  table.insert( m.api.TurtleMail_Log[ log_type ], data )
end

-- 清空当前日志页（已收到/已发送）的确认弹窗；1.12 用 StaticPopup，pfUI 会自动美化弹窗
function TurtleMail.clear_log_confirm()
  if not m.current_log_type then return end
  m.api.CloseDropDownMenus()
  m.api.StaticPopupDialogs[ "TURTLEMAIL_CLEAR_LOG" ] = {
    text = "确定清空「" .. ( L[ m.current_log_type ] or m.current_log_type ) .. "」日志的全部记录吗？\n\n|cffff3333该操作不可恢复！|r",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
      m.api.TurtleMail_Log[ m.current_log_type ] = { }
      -- 清掉时间筛选，避免空表配旧筛选时状态文字显示异常
      m[ m.current_log_type .. "_start_time" ] = nil
      m[ m.current_log_type .. "_end_time" ] = nil
      m.log.populate( m.current_log_type )
      m.info( "日志已清空。" )
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
  }
  m.api.StaticPopup_Show( "TURTLEMAIL_CLEAR_LOG" )
end

---@param log_type LogType
---@param index number?
function TurtleMail.log.populate( log_type, index )
  m.current_log_type = log_type
  local filters = m.api.TurtleMail_Log[ "Settings" ][ log_type .. "Filters" ] or {}
  local start_time = m[ log_type .. "_start_time" ]
  local end_time = m[ log_type .. "_end_time" ]
  if start_time then start_time = start_time - 43200 end
  if end_time then end_time = end_time + 43140 end

  local log = m.filter( m.api.TurtleMail_Log[ log_type ], function( item )
    local ret =
        (filters.Money and item.money and item.money > 0 and (not item.cod or item.cod == 0) and not item.ah)
        or
        (filters.COD and item.cod and item.cod > 0)
        or
        (filters.Other and (not item.cod or item.cod == 0) and not item.ah and not item.returned and (not item.money or item.money == 0))
        or
        (filters.Returned and item.returned)
        or
        (filters.AH and filters.AHWon and item.ah == "Won")
        or
        (filters.AH and filters.AHSold and item.ah == "Sold")
        or
        (filters.AH and filters.AHCancelled and item.ah == "Removed")
        or
        (filters.AH and filters.AHOutbid and item.ah == "Outbid")
        or
        (filters.AH and filters.AHExpired and item.ah == "Expired")

    if m.filter_player then
      ret = ret and item.participant == m.filter_player
    end
    if start_time then
      ret = ret and item.timestamp >= start_time
    end
    if end_time then
      ret = ret and item.timestamp <= end_time
    end

    return ret
  end )

  m.api.TurtleMailLogStartTimeText:SetText( start_time and m.format_date( start_time ) or "" )
  m.api.TurtleMailLogEndTimeText:SetText( end_time and m.format_date( end_time ) or "" )

  if not log then return end
  local log_count = getn( log )

  m.api.TurtleMailLogScrollFrameScrollBar:SetMinMaxValues( 0, math.max( 0, log_count - 10 ) )

  if not index then
    m.api.TurtleMailLogScrollFrameScrollBar:SetValue( log_count - 10 )
    m.api.TurtleMailLogScrollFrameScrollBar:SetScript( "OnUpdate", function()
      m.api.TurtleMailLogScrollFrameScrollBar:SetValue( log_count - 10 )
      m.api.TurtleMailLogScrollFrameScrollBar:SetScript( "OnUpdate", nil )
    end )

    index = math.max( 0, log_count - 10 )
  end

  -- 标题显示当前日志类型（已收到/已发送）
  m.api.TurtleMailLogTitleText:SetText( string.format( "%s %s", L[ m.current_log_type ], L[ "Log" ] ) )
  m.api.TurtleMailLogStatusText:SetText( string.format( "显示%d-%d，总共%d", (index == 0 and log_count == 0) and index or index + 1,
  math.min( log_count, index + 10 ), log_count ) )

  for i = 1, 10 do
    if log[ index + i ] then
      local entry = log[ index + i ]

      m.api[ "TurtleMailLogItem" .. i .. "IconTexture" ]:SetTexture( entry.icon or "Interface/Icons/INV_Misc_Note_01" )
      m.api[ "TurtleMailLogItem" .. i .. "Icon" ].item = entry.item
      m.api[ "TurtleMailLogItem" .. i .. "TimeStamp" ]:SetText( m.format_datetime( entry.timestamp ) )

      local subj = entry.subject or ""
      if entry.item_name and entry.item_name ~= "" and not string.find( subj, entry.item_name, 1, true ) then
        subj = subj .. " - " .. entry.item_name
      end
      m.api[ "TurtleMailLogItem" .. i .. "Subject" ]:SetText( subj )

      -- 正文全文（含竞得邮件的花费金额）挂到整行 tooltip 上
      local row = m.api[ "TurtleMailLogItem" .. i ]
      row.entry = entry
      row:EnableMouse( true )
      -- 1.12 的 SetScript 回调不传 self（参数恒为 nil），脚本执行期间用全局 this 取触发控件
      row:SetScript( "OnEnter", function()
        local e = this.entry
        m.api.GameTooltip:ClearLines()
        m.api.GameTooltip:SetOwner( this, "ANCHOR_RIGHT" )
        if e.item_name and e.item_name ~= "" then
          m.api.GameTooltip:AddLine( e.item_name, "", 1, 1, 0 )
        end
        if e.subject and e.subject ~= "" then
          m.api.GameTooltip:AddLine( e.subject, "", 0.7, 0.7, 0.7 )
        end
        if e.money and e.money > 0 then
          m.api.GameTooltip:AddLine( L[ "Money received" ] .. ": " .. m.format_money( e.money ), "", 0, 1, 0 )
        end
        if e.cod and e.cod > 0 then
          m.api.GameTooltip:AddLine( L[ "COD" ] .. ": " .. m.format_money( e.cod ), "", 0, 1, 0 )
        end
        -- 正文里的物品链接/颜色码要剥掉，否则 tooltip 会显示成方块
        if e.body and e.body ~= "" then
          local body = string.gsub( e.body, "|c%x%x%x%x%x%x%x%x", "" )
          body = string.gsub( body, "|r", "" )
          body = string.gsub( body, "|H[^|]*|h", "" )
          body = string.gsub( body, "|h", "" )
          body = string.gsub( body, "%s+$", "" )
          if body ~= "" then
            m.api.GameTooltip:AddLine( "" )
            m.api.GameTooltip:AddLine( body, "", 1, 1, 1, true )
          end
        end
        m.api.GameTooltip:Show()
      end )
      row:SetScript( "OnLeave", function() m.api.GameTooltip:Hide() end )

      m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetTexture( "" )
      if entry.ah then
        m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:SetText( "" )
        m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetTexture( "Interface\\Addons\\TurtleMail\\TurtleMail-AH.blp" )
        m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetPoint( "TOPRIGHT", 4, -10 )
      else
        m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:SetText( entry.participant )
      end
      if entry.returned then
        m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetTexture( "Interface\\Addons\\TurtleMail\\TurtleMail-RetArrow.blp" )
        local w = m.api[ "TurtleMailLogItem" .. i .. "Participant" ]:GetStringWidth()
        m.api[ "TurtleMailLogItem" .. i .. "Status" ]:SetPoint( "TOPRIGHT", -w + 4, -9 )
      end

      if entry.money and entry.money > 0 then
        local cod = (entry.cod and entry.cod > 0) and "COD: " or " "
        m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetText( cod .. m.format_money( entry.money ) )
      elseif entry.cod then
        m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetText( "COD" .. (entry.cod > 1 and (": " .. m.format_money( entry.cod )) or "") )
      elseif entry.ah == "Won" then
        -- 竞得邮件：旧存档没存金额也解析不了（正文当时没落档），只能挂 tooltip 看原文
        m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetText( L[ "Pay" ] .. ": ?" )
      else
        m.api[ "TurtleMailLogItem" .. i .. "Money" ]:SetText( "" )
      end

      m.api[ "TurtleMailLogItem" .. i ]:Show();
    else
      m.api[ "TurtleMailLogItem" .. i ]:Hide();
    end
  end
end

-- pfUI 美化代码已剥离到 pfui-skin.lua，此处仅保留调用
function TurtleMail.filter( t, f, extract_field )
  if not t then return nil end
  if type( f ) ~= "function" then return t end

  local result = {}

  for i = 1, getn( t ) do
    local v = t[ i ]
    local value = type( v ) == "table" and extract_field and v[ extract_field ] or v
    if f( value ) then table.insert( result, v ) end
  end

  return result
end

function TurtleMail.info( message )
  m.api.DEFAULT_CHAT_FRAME:AddMessage( string.format( "|cffabd473TurtleMail|r: %s", message ) )
end

function TurtleMail.dump( o )
  if not o then return "nil" end
  if type( o ) ~= 'table' then return tostring( o ) end

  local entries = 0
  local s = "{"

  for k, v in pairs( o ) do
    if (entries == 0) then s = s .. " " end
    local key = type( k ) ~= "number" and '"' .. k .. '"' or k
    if (entries > 0) then s = s .. ", " end
    s = s .. "[" .. key .. "] = " .. m.dump( v )
    entries = entries + 1
  end

  if (entries > 0) then s = s .. " " end
  return s .. "}"
end

function TurtleMail.debug( ... )
  if m.debug_enabled then
    local messages = ""
    for i = 1, getn( arg ) do
      local message = arg[ i ]
      if message then
        messages = messages == "" and "" or messages .. ", "
        if type( message ) == 'table' then
          messages = messages .. TurtleMail.dump( message )
        else
          messages = messages .. message
        end
      end
    end

    m.api.DEFAULT_CHAT_FRAME:AddMessage( string.format( "|cffabd473TurtleMail|r: %s", messages ) )
  end
end

TurtleMail:init()
