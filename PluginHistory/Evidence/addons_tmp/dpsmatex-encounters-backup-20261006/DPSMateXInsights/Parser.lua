local D,E = DPSMateX,DPSMateX.Insights
local ZERO = "0x0000000000000000"
local function valid(guid) return type(guid)=="string" and guid~="" and guid~=ZERO end
local function safe(fn,...)
    if not fn then return nil end
    local ok,value = pcall(fn,unpack(arg))
    if ok then return value end
end
local known = {
    ["Power Word: Shield"]=127,["真言术：盾"]=127,
    ["Ice Barrier"]=127,["寒冰护体"]=127,["Persistent Shield"]=127,["持续护盾"]=127,
    ["Earth Shield"]=127,["大地障壁"]=127,["Mana Shield"]=1,["法力护盾"]=1,
    ["Fire Ward"]=4,["防护火焰结界"]=4,["Frost Ward"]=16,["防护冰霜结界"]=16,
    ["Shadow Ward"]=32,["防护暗影结界"]=32,["Fire Protection"]=4,["火焰防护"]=4,
    ["防护火焰"]=4,["Frost Protection"]=16,["防护冰霜"]=16,["Nature Protection"]=8,["防护自然"]=8,
    ["Shadow Protection"]=32,["防护暗影"]=32,["Arcane Protection"]=64,["奥术防护"]=64,
    ["Holy Protection"]=2,["防护神圣"]=2,
}
local excluded = {["红月"]=true,["蓝月"]=true}
local families={
    SPELL_GO_SELF="cast",SPELL_GO_OTHER="cast",SPELL_HEAL_BY_SELF="heal",SPELL_HEAL_BY_OTHER="heal",
    SPELL_DAMAGE_EVENT_SELF="damage",SPELL_DAMAGE_EVENT_OTHER="damage",AUTO_ATTACK_SELF="swing",AUTO_ATTACK_OTHER="swing",
    ENVIRONMENTAL_DMG_SELF="environment",ENVIRONMENTAL_DMG_OTHER="environment",
    AURA_CAST_ON_SELF="aura",AURA_CAST_ON_OTHER="aura",BUFF_REMOVED_SELF="remove",BUFF_REMOVED_OTHER="remove",
    UNIT_DIED="death",ZONE_CHANGED_NEW_AREA="zone",
}
local metadata,metadataCount={},0
local function spellMetadata(id)
    local row=metadata[id]
    if row then return row end
    local name=safe(GetSpellNameAndRankForId,id)
    if not name or name=="" then return nil end
    if metadataCount>=512 then metadata={};metadataCount=0 end
    row={name=name};metadata[id]=row;metadataCount=metadataCount+1
    return row
end

function E:Spell(id)
    local row=id and spellMetadata(id)
    return row and row.name or ("技能 #"..tostring(id or 0))
end

function E:Icon(id,name,kind)
    if kind=="swing" then return "Interface\\Icons\\INV_Sword_04" end
    if kind=="death" then return "Interface\\Icons\\Spell_Shadow_DeathCoil" end
    if not id or id<=0 then return nil end
    local row=spellMetadata(id)
    if row and not row.iconChecked then
        -- Nampower expects the DBC icon ID, not the spell ID.
        local iconId=safe(GetSpellRecField,id,"spellIconID")
        row.icon=iconId and safe(GetSpellIconTexture,iconId)
        row.iconChecked=true
    end
    local icon=row and row.icon
    if not icon or icon=="" then
        local icons=D.BabbleSpellX and D.BabbleSpellX.SpellIcons
        icon=icons and icons[name or (row and row.name)]
        if icon and not string.find(icon,"\\",1,true) then icon="Interface\\Icons\\"..icon end
    end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function E:EventRelevant(ev)
    local family=families[ev]
    if not family or not self.ready or not self.available or not D.Registered then return nil end
    local healing=D.EnabledModules[self.ids.healing]
    local casts=D.EnabledModules[self.ids.casts]
    local playback=D.EnabledModules[self.ids.playback]
    if not healing and next(self.shields) then self.shields={} end
    if family=="cast" then return (casts or playback) and family
    elseif family=="swing" or family=="death" then return (healing or playback) and family
    elseif family=="zone" then return (healing or casts or playback) and family
    else return healing and family end
end

function E:Owner(guid)
    local owner
    if GetUnitGUID then
        local ok,first,second=pcall(GetUnitGUID,guid.."owner")
        if ok then
            owner=(valid(second) and string.sub(second,1,2)=="0x") and second or first
        end
    end
    if not valid(owner) then owner = safe(GetUnitField,guid,"createdBy") end
    if valid(owner) and owner~=guid then return owner end
end

function E:Tracked(guid)
    if not valid(guid) then return false end
    if D.Parser.TargetParty[guid] or guid == D.Parser.player then return true end
    local owner = self:Owner(guid)
    return owner and (D.Parser.TargetParty[owner] or owner==D.Parser.player) and true or false
end

function E:Identity(guid)
    if not valid(guid) then return nil end
    local cached = self.identities[guid]
    if cached then return cached end
    local name = safe(UnitName,guid)
    if not name or name=="" or name==D.L.unknown then return nil end
    local _,class = UnitClass(guid)
    class = class and string.lower(class) or "warrior"
    local ownerGuid = self:Owner(guid)
    local owner = ownerGuid and safe(UnitName,ownerGuid)
    local _,display = D.DB:BuildUser(guid,class)
    local person = {name=display or name,class=class,owner=owner,guid=guid}
    if owner then D.DB:BuildUser(owner) end
    self.identityCount=self.identityCount or 0
    if self.identityCount>=256 then self.identities={};self.identityCount=0 end
    self.identities[guid]=person
    self.identityCount=self.identityCount+1
    return person
end

function E:TargetInfo(guid,caster)
    if not valid(guid) then return "无目标","none" end
    local name = safe(UnitName,guid) or ("未知目标 "..guid)
    if guid==caster then return name,"self" end
    return name, safe(UnitIsFriend,"player",guid) and "friendly" or "enemy"
end

function E:TargetSnapshot(record,guid,caster)
    record.target,record.ttype=self:TargetInfo(guid,caster);record.targetGuid=guid
    if not valid(guid) then return record end
    local owner=self:Owner(guid)
    record.targetOwner=owner and safe(UnitName,owner)
    if UnitClass then
        local ok,_,class=pcall(UnitClass,owner or guid)
        if ok then record.targetClass=class end
    end
    local charm=safe(GetUnitField,guid,"charm")
    if valid(charm) then record.charmedBy=safe(UnitName,charm) end
    local dead=safe(UnitIsDead,guid)
    record.dead=(dead==true or dead==1)
    return record
end

function E:Queue(ev,args)
    if self.retrying then return end
    if table.getn(self.pending)>=100 then self.db.current.missed=(self.db.current.missed or 0)+1; return end
    table.insert(self.pending,{event=ev,args=args,expires=GetTime()+2,t=self:RelativeTime(),segment=self.db.current})
end

function E:FlushPending()
    if table.getn(self.pending)==0 then return end
    local pending=self.pending; self.pending={}; self.retrying=true
    for _,item in ipairs(pending) do
        if item.segment==self.db.current then
            self.eventTime=item.t; self.pendingCombat=true
            local done=self:Handle(item.event,unpack(item.args,1,9))
            if not done and GetTime()<item.expires then table.insert(self.pending,item)
            elseif not done then self.db.current.missed=(self.db.current.missed or 0)+1 end
        end
    end
    self.retrying=nil; self.eventTime=nil; self.pendingCombat=nil
end

function E:InCombat() return self.pendingCombat or D.DB:IsCombatActive() end

function E:PrepareEvent(ev,a1,a2,a3,a4)
    if not self:EventRelevant(ev) or self:InCombat() then return end
    local source,target
    if ev=="SPELL_GO_SELF" or ev=="SPELL_GO_OTHER" then source=a3;target=a4
    elseif ev=="SPELL_DAMAGE_EVENT_SELF" or ev=="SPELL_DAMAGE_EVENT_OTHER" or ev=="SPELL_HEAL_BY_SELF" or ev=="SPELL_HEAL_BY_OTHER" then source=a2;target=a1
    elseif ev=="AUTO_ATTACK_SELF" or ev=="AUTO_ATTACK_OTHER" then source=a1;target=a2
    elseif ev=="ENVIRONMENTAL_DMG_SELF" or ev=="ENVIRONMENTAL_DMG_OTHER" then target=a1
    else return end
    local fighting=(self:Tracked(source) and safe(UnitAffectingCombat,source)) or (self:Tracked(target) and safe(UnitAffectingCombat,target))
    local hostileCast=(ev=="SPELL_GO_SELF" or ev=="SPELL_GO_OTHER") and self:Tracked(source) and valid(target) and safe(UnitCanAttack,"player",target)
    if fighting or hostileCast then D.DB:BeginInsightsCombat() end
end

function E:Heal(caster,target,id,amount,periodic)
    if not self:Enabled("healing") or not self:InCombat() or not self:Tracked(caster) then return true end
    local person=self:Identity(caster)
    if not person then return false end
    amount=math.max(0,tonumber(amount) or 0)
    if amount==0 then return true end
    local health,maxHealth=safe(GetUnitField,target,"health"),safe(GetUnitField,target,"maxHealth")
    local effective=amount
    if health and maxHealth then effective=math.min(amount,math.max(0,maxHealth-health)) end
    local spell=self:Spell(id)
    if tonumber(periodic)==1 then spell=spell.." (HoT)" end
    local source=person.owner and "pet" or "player"
    local targetName,ttype=self:TargetInfo(target,caster)
    for _,s in ipairs({self.db.total,self.db.current}) do
        local u=self:User(s,"healing",person)
        local skill=self:Skill(u,source..":"..tostring(id)..":"..tostring(periodic),spell,id,source)
        local receiver=self:Target(u.targets,targetName)
        local starget=self:Target(skill.targets,targetName)
        receiver.ttype=ttype;starget.ttype=ttype
        for _,row in ipairs({u,skill,receiver,starget}) do
            row.total=row.total+amount; row.effective=row.effective+effective; row.count=row.count+1
        end
        if s==self.db.current then self:AddBin(u,amount,effective,0) end
    end
    self:Audit({t=self:RelativeTime(),event="heal",owner=person.name,casterGuid=caster,target=targetName,targetGuid=target,spellId=id,
        amount=amount,effective=effective,reason=health and maxHealth and "health-deficit" or "health-unavailable"})
    self:Touch("healing")
    return true
end

function E:Aura(id,caster,target,effect,aura,misc,duration,cap)
    if not self:Tracked(target) then return end
    local spell=self:Spell(id)
    aura=tonumber(aura)
    if aura~=69 and aura~=97 and not known[spell] and not excluded[spell] then return end
    if tonumber(cap) and bit.band(tonumber(cap),1)~=0 then return end
    local mask=(aura==69 or aura==97) and tonumber(misc) or known[spell]
    if not mask or mask<=0 then mask=known[spell] or 127 end
    self.shields[target]=self.shields[target] or {}
    -- A refreshed rank replaces the previous rank of the same aura, not other shields.
    for key,shield in pairs(self.shields[target]) do
        if shield.name==spell then self.shields[target][key]=nil end
    end
    self.shields[target][id]={id=id,name=spell,caster=caster,mask=mask,ignored=excluded[spell],
        expires=(tonumber(duration) and tonumber(duration)>0) and GetTime()+tonumber(duration)/1000 or nil}
end

function E:Absorb(target,school,amount,attackId)
    amount=tonumber(amount) or 0
    if amount<=0 or not self:Enabled("healing") or not self:InCombat() or not self:Tracked(target) then return end
    local candidates={}
    local shields=self.shields[target] or {}
    for id,shield in pairs(shields) do
        if shield.expires and shield.expires<=GetTime() then shields[id]=nil
        elseif school==nil or bit.band(shield.mask,2^school)~=0 then table.insert(candidates,shield) end
    end
    local person,spell,id,reason
    local ignored=false
    if table.getn(candidates)==1 then
        local shield=candidates[1]; ignored=shield.ignored
        person=self:Identity(shield.caster); spell=shield.name; id=shield.id
        reason=person and "single-compatible-shield" or "caster-unavailable"
    elseif table.getn(candidates)>1 then
        local caster=candidates[1].caster
        local same=valid(caster); ignored=candidates[1].ignored and true or false
        for _,shield in ipairs(candidates) do
            if shield.caster~=caster or (shield.ignored and true or false)~=ignored then same=false end
        end
        if same then person=self:Identity(caster); spell="多重护盾（技能未知）"; id=0
        else ignored=false end
        reason=person and "same-owner-multiple-shields" or "ambiguous-shields"
    else reason="no-compatible-shield" end
    local targetName=self:TargetInfo(target)
    if not person and not ignored then person={name=self.UNKNOWN,class="priest"}; spell="吸收（来源未知）"; id=0 end
    if person and not self:Tracked(person.guid) and person.name~=self.UNKNOWN then
        person={name=self.UNKNOWN,class="priest"}; spell="吸收（来源未知）"; id=0; reason="caster-outside-group"
    end
    for _,s in ipairs({self.db.total,self.db.current}) do
        s.absorbed=s.absorbed+amount
        if ignored then s.excluded=s.excluded+amount
        else
            if person.name==self.UNKNOWN then s.unknown=s.unknown+amount end
            local u=self:User(s,"healing",person)
            local skill=self:Skill(u,"absorb:"..tostring(id),spell,id,"shield")
            local receiver=self:Target(u.targets,targetName); local starget=self:Target(skill.targets,targetName)
            local _,ttype=self:TargetInfo(target)
            receiver.ttype=ttype;starget.ttype=ttype
            for _,row in ipairs({u,skill,receiver,starget}) do row.absorb=row.absorb+amount; row.count=row.count+1 end
            if s==self.db.current then self:AddBin(u,0,0,amount) end
        end
    end
    self:Audit({t=self:RelativeTime(),event="absorb",amount=amount,owner=ignored and "已排除" or person.name,casterGuid=person and person.guid,
        target=targetName,targetGuid=target,spellId=id,attackId=attackId,school=school,reason=reason})
    self:Touch("healing")
end

function E:Replay(person,record,action)
    if not self:Enabled("playback") or not self:InCombat() then return end
    local s=self.db.current; local u=self:User(s,"playback",person)
    if action then u.count=u.count+1 end
    s.seq=s.seq+1; record.seq=s.seq; record.t=self:RelativeTime()
    if s.stored>=self.limits.perFight and (u.events.count or 0)<self.limits.perUser then
        s.dropped=s.dropped+1; u.dropped=(u.dropped or 0)+1
    else
        local targets=self:ReplayTargetIndex(u)
        if (u.events.count or 0)<self.limits.perUser then s.stored=s.stored+1
        else
            s.dropped=s.dropped+1
            local previous=u.events.data[u.events.head]
            if previous and previous.targetGuid and targets[previous.targetGuid] then
                local count=targets[previous.targetGuid]-1
                targets[previous.targetGuid]=count>0 and count or nil
            end
        end
        self:Push(u.events,record,self.limits.perUser)
        if record.targetGuid then targets[record.targetGuid]=(targets[record.targetGuid] or 0)+1 end
    end
    self:Touch("playback")
end

function E:Cast(itemId,id,caster,target)
    if not self:Tracked(caster) then return true end
    if not self:InCombat() then
        if safe(UnitAffectingCombat,caster) or (valid(target) and safe(UnitCanAttack,"player",target)) then
            D.DB:BeginInsightsCombat()
        else return true end
    end
    local person=self:Identity(caster)
    if not person then return false end
    local spell=self:Spell(id); local source=person.owner and "pet" or "player"
    itemId=tonumber(itemId) or 0
    if itemId~=0 then
        source="item"
        spell=(safe(GetItemInfo,itemId) or ("物品 #"..itemId)).." - "..spell
    end
    local targetName,ttype=self:TargetInfo(target,caster)
    if self:Enabled("casts") then
        for _,s in ipairs({self.db.total,self.db.current}) do
            local u=self:User(s,"casts",person)
            local skill=self:Skill(u,source..":"..itemId..":"..tostring(id),spell,id,source)
            local receiver=self:Target(u.targets,targetName); local starget=self:Target(skill.targets,targetName)
            receiver.ttype=ttype;starget.ttype=ttype
            for _,row in ipairs({u,skill,receiver,starget}) do row.count=row.count+1 end
            skill.targetTypes=skill.targetTypes or {}
            skill.targetTypes[ttype]=(skill.targetTypes[ttype] or 0)+1
        end
        self:Touch("casts")
    end
    if self:Enabled("playback") then
        self:Replay(person,self:TargetSnapshot({kind="cast",spell=spell,spellId=id,source=source,owner=person.owner},target,caster),true)
    end
    self:Audit({t=self:RelativeTime(),event="cast",owner=person.name,casterGuid=caster,spellId=id,target=targetName,targetGuid=target,reason="SPELL_GO"})
    return true
end

function E:ReplayTargetIndex(u)
    self.replayIndexes=self.replayIndexes or setmetatable({},{__mode="k"})
    local targets=self.replayIndexes[u]
    if not targets then
        targets={};self.replayIndexes[u]=targets
        local ring=u.events
        for i=0,(ring.count or 0)-1 do
            local ev=ring.data[math.mod((ring.head or 1)+i-1,self.limits.perUser)+1]
            if ev and ev.targetGuid then targets[ev.targetGuid]=(targets[ev.targetGuid] or 0)+1 end
        end
    end
    return targets
end

function E:Death(guid)
    self.shields[guid]=nil
    if not self:Enabled("playback") or not self:InCombat() then return end
    local name,ttype=self:TargetInfo(guid)
    for _,u in pairs(self.db.current.playback) do
        local match=u.guid==guid or u.name==name or self:ReplayTargetIndex(u)[guid]
        if match then self:Replay(u,{kind="death",spell="死亡",source="death",target=name,ttype=ttype,targetGuid=guid},false) end
    end
end

function E:Handle(ev,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    if ev=="AURA_CAST_ON_SELF" or ev=="AURA_CAST_ON_OTHER" then
        self:Aura(a1,a2,a3,a4,a5,a7,a8,a9)
    elseif ev=="BUFF_REMOVED_SELF" or ev=="BUFF_REMOVED_OTHER" then
        if tonumber(a7)==1 and self.shields[a1] then self.shields[a1][a3]=nil end
    elseif ev=="SPELL_DAMAGE_EVENT_SELF" or ev=="SPELL_DAMAGE_EVENT_OTHER" then
        local amount=type(a5)=="string" and tonumber((string.gsub(a5,",.*$",""))) or 0
        self:Absorb(a1,tonumber(a7),amount,a3)
    elseif ev=="AUTO_ATTACK_SELF" or ev=="AUTO_ATTACK_OTHER" then
        if not self.retrying then self:Absorb(a2,0,a8,0) end
        if self:Tracked(a1) and self:Enabled("playback") and self:InCombat() then
            local person=self:Identity(a1)
            if not person then return false end
            local target,ttype=self:TargetInfo(a2,a1)
            self:Replay(person,self:TargetSnapshot({kind="swing",spell=bit.band(tonumber(a4) or 0,4)~=0 and "副手攻击" or "普通攻击",
                source=person.owner and "pet" or "player"},a2,a1),true)
        end
    elseif ev=="ENVIRONMENTAL_DMG_SELF" or ev=="ENVIRONMENTAL_DMG_OTHER" then
        local schools={[3]=2,[4]=3,[5]=2}
        self:Absorb(a1,schools[tonumber(a2)],a4,0)
    elseif ev=="SPELL_HEAL_BY_SELF" or ev=="SPELL_HEAL_BY_OTHER" then
        return self:Heal(a2,a1,a3,a4,a6)
    elseif ev=="SPELL_GO_SELF" or ev=="SPELL_GO_OTHER" then
        if not self:Enabled("casts") and not self:Enabled("playback") then return true end
        return self:Cast(a1,a2,a3,a4)
    elseif ev=="UNIT_DIED" then self:Death(a1)
    elseif ev=="ZONE_CHANGED_NEW_AREA" then self.shields={};self.identities={}
    end
    return true
end

function E:OnEvent(ev,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    local family=self:EventRelevant(ev)
    if not family then return end
    self:PrepareEvent(ev,a1,a2,a3,a4)
    -- Only suppress a mirrored SELF/OTHER notification with identical payload and time.
    -- Repeated events from the same stream are real actions and must remain countable.
    local now=GetTime(); local old=self.seen[family]
    if old and old.ev~=ev and old.time==now and old[1]==a1 and old[2]==a2 and old[3]==a3 and
        old[4]==a4 and old[5]==a5 and old[6]==a6 and old[7]==a7 and old[8]==a8 and old[9]==a9 then return end
    local done=self:Handle(ev,a1,a2,a3,a4,a5,a6,a7,a8,a9)
    self.seen[family]={ev=ev,time=now,a1,a2,a3,a4,a5,a6,a7,a8,a9}
    if not done then self:Queue(ev,{a1,a2,a3,a4,a5,a6,a7,a8,a9}) end
end
