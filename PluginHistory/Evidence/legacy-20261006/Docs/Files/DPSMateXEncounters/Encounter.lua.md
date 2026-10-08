# DPSMateXEncounters/Encounter.lua

类型：added；新增 264 行，删除 0 行。

基线：10-06 新增独立模块，整文件均为新增代码
基线来源：新增文件，无旧文件

当前 SHA-256：`b697d65c62fc5103857f66c81b6fb6fa9ff8c88f3547add28885bff1cc1871ac`

所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。

## 变更位置

| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |
|---|---|---|---|
| 1 / 0 | 1 / 264 | insert | `文件顶部 / 表定义` |

## 完整代码差异

`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。

```diff
--- /dev/null
+++ b/DPSMateXEncounters/Encounter.lua
@@ -0,0 +1,264 @@
+local D,C=DPSMateX,DPSMateX.Encounters
+local function yes(value) return value==true or value==1 end
+local function safe(fn,...)
+    if not fn then return nil end
+    local ok,value=pcall(fn,unpack(arg));if ok then return value end
+end
+local function guid(value) return type(value)=="string" and string.sub(value,1,2)=="0x" and value~="0x0000000000000000" end
+-- Small explicit fallback list. Translation dictionaries also contain ordinary mobs.
+local dungeonBosses={
+    ["Baron Rivendare"]=true,["瑞文戴尔男爵"]=true,["Darkmaster Gandling"]=true,["黑暗院长加丁"]=true,
+    ["General Drakkisath"]=true,["达基萨斯将军"]=true,["King Gordok"]=true,["戈多克大王"]=true,
+    ["Princess Theradras"]=true,["瑟莱德丝公主"]=true,["Emperor Dagran Thaurissan"]=true,["达格兰·索瑞森大帝"]=true,
+    ["Edwin VanCleef"]=true,["艾德温·范克里夫"]=true,["Archaedas"]=true,["阿扎达斯"]=true,
+}
+local events={AUTO_ATTACK_SELF="attack",AUTO_ATTACK_OTHER="attack",SPELL_MISS_SELF="attack",SPELL_MISS_OTHER="attack",
+    SPELL_DAMAGE_EVENT_SELF="damage",SPELL_DAMAGE_EVENT_OTHER="damage",DAMAGE_SHIELD_SELF="attack",DAMAGE_SHIELD_OTHER="attack",
+    SPELL_GO_SELF="cast",SPELL_GO_OTHER="cast",SPELL_HEAL_BY_SELF="heal",SPELL_HEAL_BY_OTHER="heal"}
+
+function C:Log(reason,f)
+    if not self.db or not self.db.debug then return end
+    local log=self.db.log;table.insert(log,{reason=reason,id=f and f.id,kind=f and f.kind,time=GetTime()})
+    if table.getn(log)>self.limits.debug then table.remove(log,1) end
+end
+
+function C:Invalidate()
+    self.revision=(self.revision or 0)+1;self.cache={};D.DB.NeedUpdate=true
+end
+
+function C:Initialize()
+    if not D.Settings or not D.DBCache or not D.CombatTime then return end
+    local db=DPSMateXEncountersDB
+    if type(db)~="table" or db.version~=self.VERSION then
+        db={version=self.VERSION,startedAt=time and time() or 0,nextId=1,
+            buckets={boss=self:NewBucket(),trash=self:NewBucket(),unclassified=self:NewBucket()},bossNames={},log={},debug=false}
+        DPSMateXEncountersDB=db
+    end
+    self.db=db;self.ready=true
+    self.available=D.DB.has_nampower and UnitClassification and GetUnitGUID and true or false
+    if not self.initialized then
+        self.initialized=true
+        local f=db.current
+        if f and not f.settled then
+            -- GetTime belongs to the old process; only use the saved elapsed time.
+            f.active=false;f.ended=true;f.interrupted=true;f.waiting=false
+            if f.kind~="boss" then f.kind="unclassified" end
+            self:Finalize()
+        end
+    end
+    self:InstallMenus();self:InstallDetailHooks();self:Invalidate()
+    if D.DB:IsCombatActive() and not db.current then self:Start() end
+end
+
+function C:Reset()
+    local db=self.db or DPSMateXEncountersDB
+    if type(db)~="table" then return end
+    local kind=self.ready and db.current and db.current.active and db.current.kind
+    db.buckets={boss=self:NewBucket(),trash=self:NewBucket(),unclassified=self:NewBucket()}
+    db.current=nil;db.startedAt=time and time() or 0;db.log={}
+    self.guidCache={};self.guidCount=0;self.suspended=nil;self:Invalidate()
+    if self.ready and D.DB:IsCombatActive() then self:Start(kind) end
+end
+
+function C:Start(kind)
+    if not self.ready or not self.available or self.suspended then return end
+    local previous=self.db.current
+    if previous and previous.active then return end
+    if previous and not previous.settled then self:Finalize() end
+    local id=self.db.nextId;self.db.nextId=id+1
+    self.db.current={id=id,slice=1,active=true,kind=kind or "unclassified",bosses={},bossCount=0,
+        zone=safe(GetRealZoneText) or "",instance=yes(safe(IsInInstance)),
+        sliceStart=GetTime(),cutDuration=0,elapsed=0,pending=self:NewBucket()}
+    self:Log("start",self.db.current);self:Invalidate()
+end
+
+function C:Elapsed(f)
+    if f.active then return (f.cutDuration or 0)+math.max(0,GetTime()-(f.sliceStart or GetTime())) end
+    return f.elapsed or 0
+end
+
+function C:IsTracked(unit)
+    if not guid(unit) then return false end
+    if D.Parser.TargetParty[unit] or unit==D.Parser.player then return true end
+    local known=self.guidCache[unit]
+    if known and known.owner and GetTime()<(known.expires or 0) then return D.Parser.TargetParty[known.owner] or known.owner==D.Parser.player end
+    if known and known.npc then return false end
+    local ok,first,second=pcall(GetUnitGUID,unit.."owner")
+    local owner=ok and (guid(second) and second or first)
+    if not guid(owner) then owner=safe(GetUnitField,unit,"createdBy") end
+    if guid(owner) then
+        if self.guidCount>=self.limits.guids then self.guidCache={};self.guidCount=0 end
+        self.guidCache[unit]={owner=owner,expires=GetTime()+5};self.guidCount=self.guidCount+1
+    end
+    return guid(owner) and (D.Parser.TargetParty[owner] or owner==D.Parser.player) and true or false
+end
+
+function C:NPC(unit)
+    if not guid(unit) then return nil end
+    local cached=self.guidCache[unit]
+    if cached then return cached end
+    if yes(safe(UnitIsPlayer,unit)) or self:IsTracked(unit) then return nil end
+    local class=safe(UnitClassification,unit)
+    if not class then return nil end
+    local name=safe(UnitName,unit)
+    local f=self.db.current
+    local info={npc=true,name=name,classification=class,
+        boss=class=="worldboss" or (f.instance and name and (dungeonBosses[name] or self.db.bossNames[f.zone.."\031"..name]))}
+    if self.guidCount>=self.limits.guids then self.guidCache={};self.guidCount=0 end
+    -- Missing names are retried on the next event, so whitelist recognition can recover.
+    if name then self.guidCache[unit]=info;self.guidCount=self.guidCount+1 end
+    return info
+end
+
+function C:ObserveUnit(unit)
+    local f=self.db.current
+    if not f or not f.active then return end
+    local npc=self:NPC(unit)
+    if not npc or not yes(safe(UnitCanAttack,"player",unit)) then return end
+    if npc.boss then
+        f.kind="boss"
+        if not f.bosses[unit] and f.bossCount<32 then
+            f.bosses[unit]=npc.name or unit;f.bossCount=f.bossCount+1
+            f.name=f.name or npc.name
+            self:Log("boss-observed",f);self:Invalidate()
+        end
+    elseif f.kind~="boss" and f.kind~="trash" then f.kind="trash";self:Invalidate() end
+end
+
+function C:PrepareEvent(ev,a1,a2,a3,a4)
+    if not self.ready or not self.available or not D.Registered or self.suspended then return end
+    if ev=="ZONE_CHANGED_NEW_AREA" then self:End("zone");self.suspended=D.DB:IsCombatActive() or nil;return end
+    if ev=="UNIT_DIED" then
+        local f=self.db.current
+        if f and f.active and f.bosses[a1] then f.observedBossDeath=true end
+        return
+    end
+    local family=events[ev]
+    if not family then return end
+    local source,target
+    if family=="cast" then source=a3;target=a4
+    elseif family=="damage" or family=="heal" then source=a2;target=a1
+    else source=a1;target=a2 end
+    local sourceTracked,targetTracked=self:IsTracked(source),self:IsTracked(target)
+    if not sourceTracked and not targetTracked then return end
+    local active=D.DB:IsCombatActive()
+    if not active then
+        local hostile=(family~="heal" and ((sourceTracked and yes(safe(UnitCanAttack,"player",target))) or
+            (targetTracked and yes(safe(UnitCanAttack,"player",source)))))
+        local fighting=(sourceTracked and yes(safe(UnitAffectingCombat,source))) or (targetTracked and yes(safe(UnitAffectingCombat,target)))
+        if not hostile and not fighting then return end
+        D.DB:BeginInsightsCombat()
+    end
+    if not self.db.current or not self.db.current.active then self:Start() end
+    if family~="heal" then
+        if sourceTracked then self:ObserveUnit(target) end
+        if targetTracked then self:ObserveUnit(source) end
+    end
+end
+
+function C:Snapshot(destination,core)
+    self:MergeCore(destination.core,core or self:CaptureCore(),destination)
+    local E=D.Insights
+    if E and E.ready then self:MergeInsights(destination,E.db.current,destination) end
+    local effective=D.CombatTime.effective[2]
+    for name,value in pairs(effective) do destination.effective[name]=(destination.effective[name] or 0)+value end
+end
+
+function C:FinishPending()
+    local E=D.Insights
+    if E and E.ready and E.FlushPending then
+        E:FlushPending()
+        if table.getn(E.pending)>0 then
+            E.db.current.missed=(E.db.current.missed or 0)+table.getn(E.pending);E.pending={}
+            self:Log("unresolved-at-boundary",self.db.current)
+        end
+    end
+end
+
+function C:BeforeReset()
+    if not self.ready then return end
+    local f=self.db.current
+    if f and f.active then
+        self:FinishPending();self:Snapshot(f.pending)
+        f.cutDuration=(f.cutDuration or 0)+math.max(0,GetTime()-f.sliceStart)
+        f.sliceStart=GetTime();f.slice=f.slice+1;f.elapsed=f.cutDuration
+        self:Log("manual-slice",f)
+    else
+        if f and not f.settled then self:Finalize() end
+        self.db.current=nil;self.suspended=nil
+        self.guidCache={};self.guidCount=0
+    end
+    self:Invalidate()
+end
+
+function C:End(reason)
+    if not self.ready then return end
+    local f=self.db.current
+    if not f or not f.active then return end
+    f.elapsed=self:Elapsed(f);f.active=false;f.ended=true
+    if reason then
+        f.interrupted=true
+        if f.kind~="boss" then f.kind="unclassified" end
+    end
+    local E=D.Insights
+    if not reason and E and E.ready and table.getn(E.pending)>0 then
+        f.waiting=true;f.deadline=GetTime()+2;f.frozen=self:NewBucket()
+        self:MergeCore(f.frozen.core,self:CaptureCore(),f.frozen)
+        f.frozen.effective=self:Copy(D.CombatTime.effective[2])
+    else self:Finalize() end
+end
+
+function C:Finalize()
+    local f=self.db.current
+    if not f or f.settled or f.active then return end
+    self:FinishPending()
+    local last=self:NewBucket()
+    if f.frozen then
+        self:MergeCore(last.core,f.frozen.core,last);last.effective=self:Copy(f.frozen.effective)
+        local E=D.Insights;if E and E.ready then self:MergeInsights(last,E.db.current,last) end
+    else self:Snapshot(last) end
+    self:MergeSummary(f.pending,last)
+    local bucket=self.db.buckets[f.kind or "unclassified"]
+    self:MergeSummary(bucket,f.pending)
+    bucket.duration=bucket.duration+(f.elapsed or 0);bucket.fightCount=bucket.fightCount+1
+    bucket.revision=bucket.revision+1
+    f.settled=true;f.waiting=false;f.frozen=nil;f.pending=nil
+    self:Log(f.interrupted and "interrupted-settled" or "settled",f);self:Invalidate()
+end
+
+local elapsed=0
+function C:OnUpdate(delta)
+    if not self.ready then return end
+    local f=self.db.current
+    if not f or (not f.active and not f.waiting) then return end
+    elapsed=elapsed+(delta or 0)
+    if elapsed<0.5 then return end;elapsed=0
+    if f.active then f.elapsed=self:Elapsed(f)
+    elseif f.waiting then
+        local E=D.Insights
+        if not E or table.getn(E.pending)==0 or GetTime()>=f.deadline then self:Finalize() end
+    end
+end
+
+local frame=CreateFrame("Frame")
+frame:RegisterEvent("PLAYER_LOGOUT")
+frame:SetScript("OnEvent",function()
+    if C.ready then C:End("logout");C:Finalize() end
+end)
+
+SLASH_DPSMATEXENCOUNTERS1="/dpsxenc"
+SlashCmdList.DPSMATEXENCOUNTERS=function(message)
+    if not C.ready then return end
+    local cmd=string.lower(message or "")
+    if cmd=="debug" then C.db.debug=not C.db.debug;D:SendMessage("战斗分类调试："..(C.db.debug and "开启" or "关闭"))
+    elseif cmd=="boss" then
+        local name=safe(UnitName,"target");local zone=safe(GetRealZoneText)
+        if name and zone and yes(safe(IsInInstance)) and yes(safe(UnitCanAttack,"player","target")) and not yes(safe(UnitIsPlayer,"target")) then
+            C.db.bossNames[zone.."\031"..name]=true;C.guidCache={};C.guidCount=0
+            D:SendMessage("已加入本副本Boss名单："..name)
+        else D:SendMessage("请在副本内选择需要补充识别的敌方首领。") end
+    else
+        local b,t,u=C.db.buckets.boss,C.db.buckets.trash,C.db.buckets.unclassified
+        D:SendMessage(string.format("Boss %d场 %.1fs；小怪 %d场 %.1fs；未分类 %d场；/dpsxenc debug；/dpsxenc boss",b.fightCount,b.duration,t.fightCount,t.duration,u.fightCount))
+    end
+end
```
