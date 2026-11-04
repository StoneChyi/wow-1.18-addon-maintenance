-- Run with actual Lua 5.0: lua50.exe this-file.lua [AddOns directory].
-- Auction transport/UI are controlled fixtures; no game/network requests occur.
local addons = arg[1] or 'Interface/AddOns'
local checks = 0
local function check(ok, message) assert(ok, message);checks = checks + 1 end
local function scenario()
 local env = setmetatable({}, {__index=_G});env.M=env
 local aux={account_data={},handle={},huge=1000000};local info={};local history={}
 local clock,sequence,current=0,0,nil
 local threads,listeners={},{}
 local requests,processed,flushes,bids,logs={},{},0,0,{}
 local pages,total,page,allowed,ownerPage={},0,0,true,-1
 local function widget(shown)
  return {shown=shown,IsShown=function(self)return self.shown end,Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end}
 end
 local globals={AuctionFrame=widget(true),BrowseNoResultsText=widget(false),BrowseSearchCountText=widget(true)}
 for i=1,15 do globals['BrowseButton'..i]=widget(i<=4) end
 env._G=globals;env.AuctionFrame=globals.AuctionFrame
 env.BrowseNoResultsText=globals.BrowseNoResultsText;env.BrowseSearchCountText=globals.BrowseSearchCountText
 env.module=function()setfenv(2,env)end
 env.require=function(name)
  if name=='aux' then return aux elseif name=='aux.util.info' then return info elseif name=='aux.core.history' then return history elseif name=='T' then return {acquire=function()return {}end} end
  error(name)
 end
 env.GetTime=function()return clock end
 env.UnitName=function()return 'Self'end
 env.GetNumAuctionItems=function()return table.getn(pages[page] or {}),total end
 env.QueryAuctionItems=function(name,a,b,c,d,e,p)page=p;table.insert(requests,{page=p,time=clock})end
 env.GetOwnerAuctionItems=function(p)page=p end
 env.GetBidderAuctionItems=function(p)page=p end
 env.CanSendAuctionQuery=function()return allowed end
 env.ceil=math.ceil;env.max=math.max;env.min=math.min;env.tinsert=table.insert;env.format=string.format
 env.pass=function()end
 info.auction=function(index)return (pages[page] or {})[index]end
 history.process_auction_batch=function(row)table.insert(processed,row)end
 history.flush_batch_updates=function()flushes=flushes+1 end
 aux.thread=function(callback)sequence=sequence+1;threads[sequence]={step=callback};return sequence end
 aux.thread_id=function()return current end
 aux.kill_thread=function(id)threads[id]=nil end
 aux.when=function(predicate,callback,...)
  local args=arg
  if predicate() then return callback(unpack(args)) end
  threads[current].step=function()aux.when(predicate,callback,unpack(args))end
 end
 aux.later=function(delay,start)local due=(start or clock)+delay;return function()return clock>=due end end
 aux.event_listener=function(event,callback)sequence=sequence+1;listeners[sequence]={event=event,callback=callback};return sequence end
 aux.kill_listener=function(id)listeners[id]=nil end
 aux.current_owner_page=function()return ownerPage end
 aux.bids_loaded=function()return true end
 aux.signal=function()local sent=false;return function()sent=true end,function()return sent end end
 aux.place_bid=function(kind,index,price,callback)bids=bids+1;pages[page][index]=nil;callback()end
 aux.print=function(message)table.insert(logs,message)end
 local chunk=assert(loadfile(addons..'/aux-addon/core/scan.lua'));setfenv(chunk,env);chunk()
 local function tick(time)
  clock=time or clock
  local ids={};for id in pairs(threads)do table.insert(ids,id)end
  for _,id in ipairs(ids)do
   local thread=threads[id]
   if thread and thread.step then local step=thread.step;thread.step=nil;current=id;step();current=nil end
  end
 end
 local function event(name)
  local ids={};for id in pairs(listeners)do table.insert(ids,id)end
  for _,id in ipairs(ids)do local l=listeners[id];if l and l.event==name then l.callback(function()listeners[id]=nil end)end end
 end
 local function data(pageIndex,count,offset)
  pages[pageIndex]={};for i=1,count do pages[pageIndex][i]={owner='Other',buyout_price=(offset or 0)+i,aux_quantity=1,bid_price=i}end
 end
 return {scan=env,aux=aux,tick=tick,event=event,data=data,pages=pages,globals=globals,requests=requests,processed=processed,
  total=function(n)total=n end,allow=function(v)allowed=v end,owner=function(v)ownerPage=v end,
  stats=function()return flushes,bids,logs end,listeners=listeners}
end

do -- default full scans wait for native throttling and preserve all pages/history.
 local s=scenario();s.data(0,50);s.data(1,30,50);s.total(80);s.allow(false)
 local found,complete=0,false
 s.scan.start{type='list',queries={{blizzard_query={}}},on_auction=function()found=found+1 end,on_complete=function()complete=true end}
 s.tick(0);check(table.getn(s.requests)==0,'default throttle bypassed')
 check(not s.globals.BrowseButton1.shown,'browse UI did not freeze')
 s.allow(true);s.tick(.1);check(table.getn(s.requests)==1,'query not sent')
 s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.2);check(found==50 and s.requests[2].page==1,'full page omitted')
 s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.3)
 check(complete and found==80 and table.getn(s.processed)==80,'full scan/history incomplete')
 check(s.globals.BrowseButton1.shown and not s.globals.BrowseButton5.shown and not s.globals.BrowseNoResultsText.shown,'UI visibility not restored exactly')
 check(next(s.listeners)==nil,'listeners leaked on complete')
end
do -- optional sampling is query-wide and validates rows before counting prices.
 local s=scenario();s.data(0,50);s.data(1,50,50);s.data(2,50,100);s.total(150)
 local found,progress,complete=0,0,false
 s.scan.start{type='list',read_only=true,max_unique_prices=70,ignore_owner=true,queries={{blizzard_query={},validator=function(row)return math.mod(row.buyout_price,2)==0 end}},on_auction=function()found=found+1 end,on_progress=function(v)check(v<=1 and v>=0,'progress outside range');progress=v end,on_complete=function()complete=true end}
 s.tick(0);s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.1)
 check(not complete,'invalid rows counted toward sample')
 s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.2);check(not complete,'sample reset or ended too early')
 s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.3)
 local flushes=s.stats();check(complete and found==75 and progress==1,'sample did not accumulate across pages')
 check(table.getn(s.processed)==0 and flushes==0,'read-only sample wrote price history')
end
do -- abort and repeated no-response retries are bounded and clean up listeners/UI.
 local s=scenario();local aborted=0
 local id=s.scan.start{type='list',queries={{blizzard_query={}}},on_abort=function()aborted=aborted+1 end}
 s.tick(0);s.scan.abort(id);check(aborted==1 and next(s.listeners)==nil,'manual abort leaked listener')
 check(s.globals.BrowseButton1.shown and not s.globals.BrowseButton5.shown,'abort changed hidden widget')
 s.scan.start{type='list',queries={{blizzard_query={}}},on_abort=function()aborted=aborted+1 end}
 s.tick(0);s.tick(2);s.tick(4);s.tick(6)
 check(aborted==2 and table.getn(s.requests)==4 and next(s.listeners)==nil,'timeout retries not bounded')
end
do -- owner timeout must abort rather than accepting the previous owner page.
 local s=scenario();s.data(0,3);s.total(3);local found,aborted=0,false
 s.scan.start{type='owner',queries={{blizzard_query={}}},on_auction=function()found=found+1 end,on_abort=function()aborted=true end}
 s.tick(0);s.tick(5);check(aborted and found==0 and next(s.listeners)==nil,'stale owner data accepted')
end
do -- normal scanning still waits for seller details after an initial event.
 local s=scenario();s.data(0,5);s.total(5);local found=0
 for _,row in pairs(s.pages[0])do row.owner=nil end
 s.scan.start{type='list',queries={{blizzard_query={}}},on_auction=function()found=found+1 end}
 s.tick(0);s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.1);check(found==0,'partial seller data accepted immediately')
 for _,row in pairs(s.pages[0])do row.owner='Other'end
 s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.2);check(found==5,'complete seller data not accepted')
end
do -- explicit fast query mode still has a finite retry count.
 local s=scenario();s.aux.account_data.scan_throttle=false;s.allow(false);local aborted=false
 s.scan.start{type='list',queries={{blizzard_query={}}},on_abort=function()aborted=true end}
 s.tick(0);s.tick(.41);s.tick(.82);s.tick(1.23);s.tick(1.64);s.tick(2.05)
 check(aborted and table.getn(s.requests)==5,'fast retry limit failed')
end
do -- original automatic buying continues through the original action branch.
 local s=scenario();s.data(0,1);s.total(1)
 s.scan.start{type='list',queries={{blizzard_query={}}},auto_buy_validator=function()return true end}
 s.tick(0);s.event('AUCTION_ITEM_LIST_UPDATE');s.tick(.1);s.tick(.2)
 local _,bids=s.stats();check(bids==1,'automatic buying changed')
end
print('aux Lua 5.0 scenarios passed; assertions='..checks)
