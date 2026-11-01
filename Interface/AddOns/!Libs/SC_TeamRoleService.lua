-- Unified talent transport and current-team role cache, StoneChyi & Codex.
-- Lua 5.0 / Turtle 1.12. No saved roster, CVar, UI, target changes or casts.
if SC_TeamRolesService and SC_TeamRolesService.apiVersion == 1 then return end
SC_TeamRolesService = { apiVersion = 1, cacheTime = 180, inspectCacheTime = 30,
    interval = 1.5, timeout = 12 }
local S = SC_TeamRolesService
local frame = CreateFrame("Frame")
local records, roster, interests, listeners, queue = {}, {}, {}, {}, {}
local pending, external, busy, notifying, combat, combatStart, frozenAt
local ready, ownerKey, lastSend, nextTick, failures, circuitUntil = false, nil, -100, 0, 0, 0
local nextSweep=0
local wasGrouped
local recent = {}
local guardedSenders = {}
local nativeHandler, nativeGuard
local eventsActive, driverActive
local message = "等待团队职责需求"
local metrics = { requests = 0, timeouts = 0, rejected = 0, completed = 0, merged = 0,
    ignored = 0, types = {}, tabs = 0, nodes = 0 }
local Wake, Reconcile, Enqueue, Classify
local prefix = "TW_CHAT_MSG_WHISPER"
local function Now() return GetTime() end
local function Truth(v) return v ~= nil and v ~= false and v ~= 0 end
local function Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function Data(class) return SC_TeamRoleData and SC_TeamRoleData[class] end
local function Int(v, low, high)
    local n=tonumber(v)
    if n and n==math.floor(n) and n>=low and n<=high then return n end
end
local function Identity(unit)
    if type(unit)~="string" then return end
    local exists,guid=UnitExists(unit)
    if not Truth(exists) then return end
    local name=UnitName(unit)
    local _,class=UnitClass(unit)
    if not name or name=="" or name==UNKNOWNOBJECT or name==UNKNOWN or not Data(class) then return end
    return name,class,type(guid)=="string" and guid~="" and guid or name
end
local function Valid(rec)
    if not rec or not rec.current then return false end
    local name,class,key=Identity(rec.unit)
    return name==rec.name and class==rec.class and key==rec.key
end
local function Fresh(rec, age)
    if not Valid(rec) or not rec.time then return false end
    local clock=combat and rec.combatSnapshot and frozenAt or Now()
    return clock-rec.time < (age or S.cacheTime)
end
local function CachedFresh(rec)
    if not rec or not rec.current or not rec.time then return false end
    local clock=combat and rec.combatSnapshot and frozenAt or Now()
    return clock-rec.time<S.cacheTime
end
local function Notify(rec)
    if notifying then return end
    notifying=true
    for _,fn in pairs(listeners) do pcall(fn,rec) end
    notifying=false
end
local function Callback(rec, why)
    local callbacks=rec.callbacks or {}
    rec.callbacks={}
    for _,fn in pairs(callbacks) do
        if why then pcall(fn,nil,why) else pcall(fn,rec) end
    end
end
function S:EnsureNativeGuard()
    local current=InspectTalentsFrame_HandleMessage
    if type(current)~="function" or current==nativeGuard then return end
    if not nativeHandler then nativeHandler=current end
    local previous=current
    nativeGuard=function(body,sender)
        if type(body)=="string" then
            local text=string.gsub(body,"^%s+","")
            local at=string.find(text,";",1,true)
            local kind=at and string.sub(text,1,at-1) or text
            if kind=="INSTalentShow" then return previous("INSTalentShow",sender) end
            if string.sub(kind,1,9)=="INSTalent" and type(sender)=="string"
                and ((pending and pending.rec.name==sender) or (guardedSenders[sender] or 0)>Now()) then return end
        end
        return previous(body,sender)
    end
    InspectTalentsFrame_HandleMessage=nativeGuard
end
function S:GetNativeMessageHandler()
    self:EnsureNativeGuard()
    return nativeHandler
end
local function Unknown(rec)
    rec.role,rec.style,rec.confidence,rec.provisional,rec.source=nil,nil,"unknown",true,"unknown"
    rec.candidateRole=nil
end
local function Rank(rec,tree,index)
    return rec.talents and rec.talents[tree] and rec.talents[tree][index]
        and rec.talents[tree][index].rank or 0
end
Classify=function(rec)
    Unknown(rec)
    if rec.overrideRole then
        rec.role,rec.style,rec.confidence,rec.provisional,rec.source=
            rec.overrideRole,rec.overrideStyle,"high",false,"manual"
        return
    end
    if not rec.tabs or not rec.talents then return end
    local a,b,c=rec.tabs[1].points,rec.tabs[2].points,rec.tabs[3].points
    local tree,points,second=1,a,math.max(b,c)
    if b>points then tree,points,second=2,b,math.max(a,c) end
    if c>points then tree,points,second=3,c,math.max(a,b) end
    local role,style,confidence,provisional=nil,nil,"medium",true
    local deep=points>=31 and points>second
    local class=rec.class
    if class=="MAGE" or class=="WARLOCK" then role,style,confidence,provisional="DAMAGER","RANGED","high",false
    elseif class=="ROGUE" then role,style,confidence,provisional="DAMAGER","MELEE","high",false
    elseif points>=21 and points>second then
        if class=="WARRIOR" then
            role,style="DAMAGER","MELEE"
            if tree==3 then
                role="TANK"
                if deep and Rank(rec,3,14)>0 then confidence,provisional="high",false end
            elseif deep then confidence,provisional="high",false end
            if tree==2 and deep and Rank(rec,3,12)>0 then
                confidence,provisional,rec.candidateRole="medium",true,"TANK"
            end
        elseif class=="PALADIN" then
            role=tree==1 and "HEALER" or tree==2 and "TANK" or "DAMAGER"
            style=tree==3 and "MELEE" or nil
            if deep and (tree==3 or (tree==2 and Rank(rec,2,13)>0 and Rank(rec,2,6)>0)
                or (tree==1 and Rank(rec,1,6)>0 and Rank(rec,1,11)>0)) then confidence,provisional="high",false end
        elseif class=="PRIEST" then
            role,style=tree==3 and "DAMAGER" or "HEALER",tree==3 and "RANGED" or nil
            if deep and ((tree==3 and Rank(rec,3,17)>0) or (tree==2 and Rank(rec,2,16)>0)) then
                confidence,provisional="high",false
            end
        elseif class=="SHAMAN" then
            role,style=tree==3 and "HEALER" or "DAMAGER",tree==1 and "RANGED" or tree==2 and "MELEE" or nil
            if deep then confidence,provisional="high",false end
            if tree==2 and Rank(rec,2,2)>=3 and Rank(rec,2,9)>0 then
                confidence,provisional,rec.candidateRole="medium",true,"TANK"
            end
        elseif class=="DRUID" then
            role,style=tree==3 and "HEALER" or "DAMAGER",tree==1 and "RANGED" or tree==2 and "MELEE" or nil
            if deep and tree~=2 then confidence,provisional="high",false end
            if tree==2 then rec.candidateRole="TANK" end
        elseif class=="HUNTER" then
            role,style="DAMAGER","RANGED"
            if deep and tree~=3 then confidence,provisional="high",false
            elseif deep and Rank(rec,3,17)>0 then style,confidence,provisional="MELEE","high",false end
        end
    end
    rec.role,rec.style,rec.confidence,rec.provisional,rec.source=role,style,confidence,provisional,"talent"
end
local function New(unit,team)
    local name,class,key=Identity(unit)
    if not name then return end
    local rec={name=name,class=class,key=key,unit=unit,current=true,team=team,
        callbacks={},queryState="idle"}
    Unknown(rec);return rec
end
local function PruneRecent()
    local now=Now()
    for name,t in pairs(recent) do if t<=now then recent[name]=nil end end
    for name,t in pairs(guardedSenders) do if t<=now then guardedSenders[name]=nil end end
    while Count(guardedSenders)>80 do
        local name,oldest
        for k,t in pairs(guardedSenders) do if not oldest or t<oldest then name,oldest=k,t end end
        guardedSenders[name]=nil
    end
    while Count(recent)>80 do
        local name,oldest
        for k,t in pairs(recent) do if not oldest or t<oldest then name,oldest=k,t end end
        recent[name]=nil
    end
end
local function Fail(why,timeout)
    local p=pending
    if not p then return end
    pending=nil;p.rec.queryState=why;p.rec.queued=nil
    if not p.rec.overrideRole then p.rec.time=nil;Unknown(p.rec) end
    recent[p.rec.name]=math.max(recent[p.rec.name] or 0,Now()+30)
    if timeout then metrics.timeouts=metrics.timeouts+1 end
    failures=failures+1
    if failures>=3 then circuitUntil=Now()+60;message="连续查询失败，已暂缓后台查询"
    else message="该队员查询未完成，已跳过" end
    Callback(p.rec,why);Notify(p.rec)
end
local function Finish()
    local p=pending
    if not p or not Valid(p.rec) then Fail("identity");return end
    local structure=Data(p.rec.class)
    local total=0
    for tree=1,3 do
        local tab=p.tabs[tree]
        if not tab or tab.count~=table.getn(structure[tree]) then Fail("incomplete");return end
        local sum=0
        for index=1,tab.count do
            local node=p.talents[tree][index]
            if not node then Fail("incomplete");return end
            sum=sum+node.rank
        end
        if sum~=tab.points then Fail("points");return end
        total=total+sum
    end
    if total>51 then Fail("points");return end
    pending=nil;failures=0
    local rec=p.rec
    rec.tabs,rec.talents,rec.time,rec.queryState=p.tabs,p.talents,Now(),"complete"
    rec.stale=nil
    rec.combatSnapshot=combat and true or nil
    Classify(rec);metrics.completed=metrics.completed+1
    recent[rec.name]=Now()+2
    message="天赋已完整校验"
    Callback(rec);Notify(rec)
end
local function Fields(text)
    local fields={}
    for field in string.gfind(text..";","(.-);") do
        table.insert(fields,field)
        if table.getn(fields)>14 then return fields end
    end
    if fields[table.getn(fields)]=="" then table.remove(fields) end
    return fields
end
function S:Packet(receivedPrefix,body,channel,sender)
    if not pending or type(body)~="string" or type(sender)~="string" then return end
    if sender~=pending.rec.name then metrics.rejected=metrics.rejected+1;return end
    local selfName=UnitName("player")
    if receivedPrefix~=prefix and receivedPrefix~=prefix.."<"..tostring(selfName)..">" then
        metrics.rejected=metrics.rejected+1;return
    end
    if not Valid(pending.rec) then Fail("identity");return end
    if Now()>=pending.deadline then Fail("timeout",true);return end
    local text=string.gsub(body,"^%s+","")
    local at=string.find(text,";",1,true)
    local kind=at and string.sub(text,1,at-1) or text
    if kind~="INSTalentEND" and kind~="INSTalentTabInfo" and kind~="INSTalentInfo" then
        metrics.ignored=metrics.ignored+1
        local token=string.sub(kind,1,48)
        token=string.gsub(token,"[^%w_]",function(c) return string.format("\\x%02X",string.byte(c)) end)
        local seen=false
        for _,value in ipairs(metrics.types) do if value==token then seen=true end end
        if not seen and table.getn(metrics.types)<6 then table.insert(metrics.types,token) end
        return
    end
    metrics.lastType=kind
    if string.len(body)>2048 then Fail("invalid");return end
    if kind=="INSTalentEND" then Finish();return end
    local f=Fields(text)
    local tree=Int(f[2],1,3)
    local data=Data(pending.rec.class)
    if not tree or not data then Fail("structure");return end
    if kind=="INSTalentTabInfo" then
        local points,count=Int(f[4],0,51),Int(f[5],1,50)
        if table.getn(f)~=5 or f[3]=="" or not points or count~=table.getn(data[tree]) then Fail("structure");return end
        local old=pending.tabs[tree]
        if old and (old.points~=points or old.count~=count) then Fail("conflict");return end
        if not old then metrics.tabs=metrics.tabs+1 end
        pending.tabs[tree]={points=points,count=count,message=text}
    else
        local index=Int(f[3],1,table.getn(data[tree]))
        local expected=index and data[tree][index]
        local rank=expected and Int(f[7],0,expected[1])
        local pt,pc=Int(f[10],-1,8),Int(f[11],-1,4)
        if table.getn(f)~=12 or not expected or f[4]=="" or not rank
            or tonumber(f[5])~=expected[2] or tonumber(f[6])~=expected[3] or tonumber(f[8])~=expected[1]
            or (f[9]~="0" and f[9]~="1") or not pt or not pc or (pt~=-1 and pt<1) or (pc~=-1 and pc<1)
            or (f[12]~="-1" and f[12]~="1") then Fail("structure");return end
        local old=pending.talents[tree][index]
        if old and old.rank~=rank then Fail("conflict");return end
        if not old then metrics.nodes=metrics.nodes+1 end
        pending.talents[tree][index]={rank=rank,maximum=expected[1],tier=expected[2],column=expected[3],message=text}
    end
end
local function Self(rec)
    local data=Data(rec.class)
    if type(GetNumTalentTabs)~="function" or type(GetTalentInfo)~="function"
        or type(GetTalentTabInfo)~="function" or type(GetNumTalents)~="function" then rec.queryState="unavailable";return end
    local ok,tabs=pcall(GetNumTalentTabs)
    if not ok or tabs~=3 then rec.queryState="unavailable";return end
    local record={rec=rec,tabs={},talents={{},{},{}}}
    for tree=1,3 do
        local success,count=pcall(GetNumTalents,tree)
        local tabOK,name,icon,points=pcall(GetTalentTabInfo,tree)
        if not success or not tabOK or count~=table.getn(data[tree]) or not Int(points,0,51) then rec.queryState="unavailable";return end
        record.tabs[tree]={points=points,count=count,message="INSTalentTabInfo;"..tree..";"..tostring(name)..";"..points..";"..count}
        for index=1,count do
            local good,n,texture,tier,column,rank,maximum=pcall(GetTalentInfo,tree,index)
            local expected=data[tree][index]
            if not good or not Int(rank,0,expected[1]) or maximum~=expected[1] or tier~=expected[2] or column~=expected[3] then
                rec.queryState="unavailable";return
            end
            record.talents[tree][index]={rank=rank,maximum=maximum,tier=tier,column=column,
                message="INSTalentInfo;"..tree..";"..index..";"..tostring(n)..";"..tier..";"..column..";"..rank..";"..maximum..";0;-1;-1;-1"}
        end
    end
    pending=record;Finish();return true
end
Reconcile=function()
    local name,class,key=Identity("player")
    if not name then ready=false;return end
    local realm=type(GetRealmName)=="function" and GetRealmName() or ""
    local identity=tostring(realm)..":"..key
    if ownerKey and ownerKey~=identity then
        for _,rec in pairs(records) do Callback(rec,"owner") end
        records,roster,queue,recent={},{},{},{}
        pending,external=nil,nil
    end
    ownerKey,ready=identity,true
    nextSweep=0
    local nextRecords,nextRoster={},{}
    local raid=math.min(GetNumRaidMembers(),40)
    local count=raid>0 and raid or math.min(GetNumPartyMembers(),4)+1
    local grouped=count>1
    if wasGrouped~=nil and wasGrouped~=grouped then
        for _,rec in pairs(records) do
            rec.overrideRole,rec.overrideStyle,rec.order=nil,nil,nil
            Classify(rec)
        end
    end
    wasGrouped=grouped
    for i=1,count do
        local unit=raid>0 and "raid"..i or i==1 and "player" or "party"..(i-1)
        local n,c,k=Identity(unit)
        if n then
            local rec=records[n]
            if not rec or rec.key~=k or rec.class~=c then
                if rec then rec.current=false;Callback(rec,"identity") end
                rec=New(unit,true)
            end
            rec.unit,rec.current,rec.team=unit,true,true
            if (rec.queryState=="offline" or rec.queryState=="unavailable") and Truth(UnitIsConnected(unit)) then
                rec.queryState="idle"
            end
            nextRecords[n]=rec;table.insert(nextRoster,rec)
        end
    end
    for n,rec in pairs(records) do
        if nextRecords[n]~=rec then rec.current=false;rec.overrideRole,rec.overrideStyle,rec.order=nil,nil,nil;Callback(rec,"departed") end
    end
    records,roster=nextRecords,nextRoster
    for i=table.getn(queue),1,-1 do
        if not Valid(queue[i]) then queue[i].queued=nil;table.remove(queue,i) end
    end
    if external and records[external.name] and records[external.name].key==external.key then
        local team=records[external.name]
        for owner,fn in pairs(external.callbacks or {}) do team.callbacks[owner]=fn end
        if pending and pending.rec==external then pending.rec=team end
        external=nil
    end
    if pending and not Valid(pending.rec) then Fail("identity") end
    Notify()
end
local function Lookup(input)
    if type(input)~="string" then return end
    local rec=records[input]
    if not rec then
        local name,class,key=Identity(input)
        rec=name and records[name]
        if rec and (rec.key~=key or rec.class~=class) then rec=nil end
        if not rec and external and external.name==name and external.key==key and external.class==class then rec=external end
    end
    if not rec and external and external.name==input then rec=external end
    if Valid(rec) then return rec end
end
Enqueue=function(rec,owner,callback,force,priority)
    if callback and type(owner)=="string" then rec.callbacks[owner]=callback end
    if not force and Fresh(rec,S.inspectCacheTime) and rec.tabs then
        if callback then rec.callbacks[owner]=nil;pcall(callback,rec) end
        return true
    end
    if pending and pending.rec==rec then metrics.merged=metrics.merged+1;return true end
    if recent[rec.name] and recent[rec.name]>Now() then
        if callback then rec.callbacks[owner]=nil;pcall(callback,nil,"isolated") end
        return false,"上一查询尚在隔离期，请稍后重试"
    end
    if rec.queued then
        rec.priority=math.max(rec.priority or 0,priority or 0);metrics.merged=metrics.merged+1;return true
    end
    rec.queued,rec.priority,rec.queryState=true,tonumber(priority) or 0,"queued"
    table.insert(queue,rec);nextTick=0;Wake();return true
end
local function Pick()
    local best,index
    for i,rec in ipairs(queue) do
        if not best or (rec.priority or 0)>(best.priority or 0) then best,index=rec,i end
    end
    if index then table.remove(queue,index);best.queued=nil end
    return best
end
local function Interested() return next(interests)~=nil end
local function Needed() return Interested() and table.getn(roster)>1 or pending or table.getn(queue)>0 end
local function Update() S:Tick() end
Wake=function()
    local work=Needed() and true or false
    if work~=driverActive then frame:SetScript("OnUpdate",work and Update or nil);driverActive=work end
    local events=work or Interested()
    if events==eventsActive then return end
    eventsActive=events
    if events then
        frame:RegisterEvent("CHAT_MSG_ADDON");frame:RegisterEvent("RAID_ROSTER_UPDATE")
        frame:RegisterEvent("PARTY_MEMBERS_CHANGED");frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED");frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("UNIT_CONNECTION")
    else
        frame:UnregisterEvent("CHAT_MSG_ADDON");frame:UnregisterEvent("RAID_ROSTER_UPDATE")
        frame:UnregisterEvent("PARTY_MEMBERS_CHANGED");frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        frame:UnregisterEvent("PLAYER_REGEN_DISABLED");frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:UnregisterEvent("CHARACTER_POINTS_CHANGED")
        frame:UnregisterEvent("ADDON_LOADED")
        frame:UnregisterEvent("UNIT_CONNECTION")
    end
end
function S:Acquire(owner)
    if type(owner)~="string" then return false end
    if interests[owner] then return true end
    interests[owner]=true;Reconcile();nextTick=0;Wake();return true
end
function S:Release(owner)
    interests[owner]=nil
    for i=table.getn(queue),1,-1 do
        local rec=queue[i]
        if not Interested() and not next(rec.callbacks) then rec.queued=nil;table.remove(queue,i) end
    end
    Wake()
end
function S:Subscribe(owner,fn) if type(owner)=="string" and type(fn)=="function" then listeners[owner]=fn end end
function S:Unsubscribe(owner) listeners[owner]=nil end
function S:GetInfo(unit) return Lookup(unit) end
function S:GetRoster() return roster end
function S:Peek(name,key,class)
    local rec=records[name]
    if rec and rec.current and rec.key==key and rec.class==class then
        return rec,rec.overrideRole~=nil or CachedFresh(rec)
    end
end
function S:IsFresh(unit)
    local rec=type(unit)=="table" and unit or Lookup(unit)
    return Fresh(rec)
end
function S:IsReady() return ready end
function S:GetRole(unit)
    local rec=Lookup(unit)
    if not rec then return end
    if rec.overrideRole or (CachedFresh(rec) and rec.confidence=="high" and not rec.provisional) then
        return rec.role,rec.role=="TANK" and rec.order or nil,rec.source
    end
end
function S:Request(unit,owner,callback,force,priority)
    if type(owner)~="string" or (callback~=nil and type(callback)~="function") then return false,"无效查询订阅" end
    Reconcile()
    local rec=Lookup(unit)
    if not rec then
        if type(UnitIsPlayer)=="function" and not Truth(UnitIsPlayer(unit)) then return false,"无效观察目标" end
        local candidate=New(unit,false)
        if not candidate then return false,"无效观察目标" end
        if external and external.key~=candidate.key then
            for i=table.getn(queue),1,-1 do
                if queue[i]==external then external.queued=nil;table.remove(queue,i) end
            end
            external.current=false;Callback(external,"replaced")
        end
        external=candidate;rec=external
    end
    return Enqueue(rec,owner,callback,force,tonumber(priority) or 100)
end
function S:Cancel(owner)
    for _,rec in pairs(records) do rec.callbacks[owner]=nil end
    if external then external.callbacks[owner]=nil end
    if pending then pending.rec.callbacks[owner]=nil end
    for i=table.getn(queue),1,-1 do
        local rec=queue[i]
        if not next(rec.callbacks) and (not Interested() or not rec.team) then
            rec.queued=nil;table.remove(queue,i)
        end
    end
    Wake()
end
function S:SetOverride(unit,role,style)
    local rec=Lookup(unit)
    if not rec or not rec.team then return false,"队员已离队" end
    if role~=nil and role~="TANK" and role~="HEALER" and role~="DAMAGER" then return false,"无效职责" end
    if style~=nil and style~="MELEE" and style~="RANGED" then return false,"无效作战方式" end
    rec.overrideRole,rec.overrideStyle=role,role and style or nil
    if role then rec.stale=nil end
    if role~="TANK" then rec.order=nil end
    Classify(rec);Notify(rec);return true
end
function S:SetTankOrder(unit,order)
    local rec=Lookup(unit)
    if not rec or not rec.team or rec.role~="TANK" then return false,"请先确认坦克职责" end
    if order~=nil and not Int(order,1,40) then return false,"无效坦克顺位" end
    if order then
        for _,other in ipairs(roster) do if other~=rec and other.order==order then other.order=nil end end
    end
    rec.order=order and tonumber(order) or nil;Notify(rec);return true
end
function S:Refresh(unit)
    if combat then return false,"战斗中使用缓存，脱战后再刷新" end
    Reconcile();circuitUntil,failures=0,0
    if unit then
        local rec=Lookup(unit)
        if not rec then return false,"队员已离队" end
        return Enqueue(rec,nil,nil,true,50)
    end
    local any=false
    for _,rec in ipairs(roster) do if Enqueue(rec,nil,nil,true,10) then any=true end end
    return any,any and nil or "查询尚在隔离期"
end
function S:Tick()
    if busy or notifying then return end
    local now=Now()
    if now<nextTick then return end
    nextTick=now+.25;busy=true
    if pending and (not Valid(pending.rec) or now>=pending.deadline) then Fail("timeout",true) end
    if Interested() and not combat and now>=nextSweep then
        nextSweep=now+5
        for _,rec in ipairs(roster) do
            if not rec.overrideRole and not rec.queued and not (pending and pending.rec==rec)
                and (rec.queryState=="idle" or rec.queryState=="complete" and not CachedFresh(rec)) then
                if rec.time and not CachedFresh(rec) then rec.stale=true;Unknown(rec) end
                Enqueue(rec,nil,nil,true,0)
            end
        end
    end
    if not combat and not pending and now>=lastSend+S.interval and now>=circuitUntil then
        local rec=Pick()
        if rec and Valid(rec) then
            if not Truth(UnitIsConnected(rec.unit)) then
                rec.queryState="offline";Callback(rec,"offline")
            elseif UnitIsUnit and Truth(UnitIsUnit("player",rec.unit)) then
                if not Self(rec) then Callback(rec,"unavailable");Notify(rec) end
                lastSend=now
            else
                self:EnsureNativeGuard()
                pending={rec=rec,deadline=now+S.timeout,tabs={},talents={{},{},{}}}
                metrics.tabs,metrics.nodes,metrics.lastType=0,0,nil
                guardedSenders[rec.name]=now+S.cacheTime
                rec.queryState="pending";lastSend=now
                local ok=type(SendAddonMessage)=="function" and pcall(SendAddonMessage,prefix.."<"..rec.name..">","INSTalentShow","GUILD")
                if not ok then Fail("unavailable") else metrics.requests=metrics.requests+1;message="正在自动补全团队天赋" end
            end
        elseif rec then Callback(rec,"identity") end
    end
    if external and not Valid(external) and not (pending and pending.rec==external) then external=nil end
    PruneRecent();busy=false
    if not pending and table.getn(queue)==0 then nextTick=now+5 end
    Wake()
end
function S:OnEvent(event,a1,a2,a3,a4)
    if event=="CHAT_MSG_ADDON" then self:Packet(a1,a2,a3,a4)
    elseif event=="ADDON_LOADED" then self:EnsureNativeGuard()
    elseif event=="PLAYER_REGEN_DISABLED" then
        combat,combatStart,frozenAt=true,Now(),Now()
        for _,rec in ipairs(roster) do rec.combatSnapshot=Fresh(rec) end
    elseif event=="PLAYER_REGEN_ENABLED" then
        combat=false
        for _,rec in ipairs(roster) do rec.combatSnapshot=nil end
        nextTick=0
    elseif event=="CHARACTER_POINTS_CHANGED" then
        local rec=Lookup("player")
        if rec then rec.queryState="idle";rec.time=nil end
    else Reconcile();nextTick=0 end
    Wake()
end
function S:GetDiagnostics()
    local completed,unknown=0,0
    for _,rec in ipairs(roster) do
        if Fresh(rec) and rec.tabs then completed=completed+1 end
        if not self:GetRole(rec.unit) then unknown=unknown+1 end
    end
    local d={completed=completed,total=table.getn(roster),unknown=unknown,pending=pending~=nil,
        queued=table.getn(queue),state=combat and "combat" or Now()<circuitUntil and "paused" or pending and "querying"
            or Interested() and "ready" or "idle",message=message,consumers=Count(interests)}
    for k,v in pairs(metrics) do d[k]=v end
    -- completed counts current cache entries, not lifetime replies.
    d.completed=completed
    return d
end
SC_TeamRolesProvider=S
frame:SetScript("OnEvent",function() S:OnEvent(event,arg1,arg2,arg3,arg4) end)
