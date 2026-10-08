local D,E = DPSMateX,DPSMateX.Insights
local format=string.format
local sourceNames={all="全部来源",player="玩家",pet="宠物",item="物品",shield="护盾",death="死亡"}
local targetNames={all="全部目标",enemy="敌方",friendly="友方",self="自身",none="无目标"}
local sources={"all","player","pet","item","shield","death"}
local targets={"all","enemy","friendly","self","none"}
local labels={players="玩家",skills="技能",targets="目标",audit="核对",events="动作"}

local function text(parent,size,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY",size or "GameFontNormalSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); f:SetWidth(width or 300); f:SetHeight(22); f:SetJustifyH("LEFT")
    return f
end
local function box(frame,alpha)
    frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=16,edgeSize=16,insets={left=6,right=6,top=6,bottom=6}})
    frame:SetBackdropColor(0.157,0.08,0.06,alpha or 1)
end
local function button(parent,label,x,y,width,action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetWidth(width or 76); b:SetHeight(23); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); b:SetText(label)
    b:SetScript("OnClick",action)
    return b
end
local function edit(parent,label,x,y,width)
    local caption=text(parent,nil,x,y,width);caption:SetText(label)
    local f=CreateFrame("EditBox",nil,parent)
    f.label=caption
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y-22); f:SetWidth(width); f:SetHeight(24)
    f:SetFontObject(GameFontHighlightSmall); f:SetAutoFocus(false); box(f,0.5); f:SetTextInsets(5,5,0,0)
    f:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    f:SetScript("OnEnterPressed",function() this:ClearFocus() end)
    return f
end

function E:HideDetails()
    for _,w in pairs(self.windows or {}) do w:Hide() end
    for _,w in pairs(self.healingWindows or {}) do w:Hide() end
end

function E:CreateDetails(index)
    self.windows=self.windows or {}
    if self.windows[index] then return self.windows[index] end
    local w=CreateFrame("Frame","DPSMateX_InsightsDetails"..index,UIParent)
    self.windows[index]=w
    w:SetWidth(860); w:SetHeight(650); w:SetPoint("CENTER",UIParent,"CENTER",0,0)
    w:SetFrameStrata("DIALOG"); w:SetMovable(true); w:EnableMouse(true); box(w)
    w:SetClampedToScreen(true)
    w:SetScript("OnMouseDown",function() if arg1=="LeftButton" then this:StartMoving() end end)
    w:SetScript("OnMouseUp",function() this:StopMovingOrSizing() end)
    table.insert(UISpecialFrames,w:GetName())
    w.title=text(w,"GameFontNormalHuge",18,-13,780)
    w.summary=text(w,"GameFontNormal",18,-43,818)
    w.summary:SetHeight(42)
    button(w,"×",818,-12,25,function() w:Hide() end)
    w.refresh=button(w,"刷新",179,-91,73,function() E:Render(w) end)
    w.back=button(w,"返回玩家",259,-91,92,function()
        w.person=nil;w.skill=nil;w.view=w.kind=="playback" and "events" or "players";w.offset=0;E:Render(w)
    end)
    w.search=edit(w,"技能／目标名称",18,-122,235)
    w.start=edit(w,"起始秒",265,-122,67)
    w.finish=edit(w,"结束秒",344,-122,67)
    w.source=button(w,"全部来源",426,-145,100,function()
        w.sourceIndex=math.mod(w.sourceIndex,table.getn(sources))+1;w.offset=0;E:Render(w)
    end)
    w.targetType=button(w,"全部目标",535,-145,100,function()
        w.targetIndex=math.mod(w.targetIndex,table.getn(targets))+1;w.offset=0;E:Render(w)
    end)
    w.viewButtons={}
    local x=18
    for _,view in ipairs({"players","skills","targets","audit","events"}) do
        local v=view
        w.viewButtons[view]=button(w,labels[view],x,-180,72,function() w.view=v;w.offset=0;w.skill=nil;E:Render(w) end)
        x=x+80
    end
    w.caption=text(w,"GameFontNormal",18,-211,818)
    w.rows={}
    for i=1,16 do
        local row=CreateFrame("Button",nil,w)
        row:SetPoint("TOPLEFT",w,"TOPLEFT",18,-239-(i-1)*22);row:SetWidth(820);row:SetHeight(22)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(19);row.icon:SetHeight(19)
        row.icon:SetPoint("LEFT",row,"LEFT",0,0)
        row.left=text(row,nil,25,0,495);row.right=text(row,nil,527,0,282);row.right:SetJustifyH("RIGHT")
        row:SetScript("OnClick",function()
            if row.item and row.item.person then w.person=row.item.person;w.view="skills";w.skill=nil
            elseif row.item and row.item.skill then w.skill=row.item.skill;w.view="targets"
            else return end
            w.offset=0;E:Render(w)
        end)
        row:SetScript("OnEnter",function()
            if row.item then
                GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
                GameTooltip:AddLine(row.item.left,1,1,1,true)
                GameTooltip:AddLine(row.item.right or "",1,1,1,true)
                if row.item.tip then GameTooltip:AddLine(row.item.tip,0.7,0.7,0.7,true) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        w.rows[i]=row
    end
    w:EnableMouseWheel(true)
    w:SetScript("OnMouseWheel",function()
        w.offset=math.max(0,math.min(math.max(0,(w.lineCount or 0)-16),w.offset-arg1*3));E:Render(w)
    end)
    button(w,"上一页",18,-603,86,function() w.offset=math.max(0,w.offset-16);E:Render(w) end)
    button(w,"下一页",111,-603,86,function()
        w.offset=math.min(math.max(0,(w.lineCount or 0)-16),w.offset+16);E:Render(w)
    end)
    w.page=text(w,nil,210,-603,180)
    w.note=text(w,nil,399,-598,440);w.note:SetHeight(40)
    for _,field in ipairs({w.search,w.start,w.finish}) do
        field:SetScript("OnTextChanged",function()
            if w.initializing then return end
            w.offset=0;E:Render(w)
        end)
    end
    w:Hide()
    return w
end

local function matches(s,query) return query=="" or string.find(s or "",query,1,true)~=nil end
function E:Filters(w)
    return { query=w.search:GetText() or "",from=w.start and tonumber(w.start:GetText()),to=w.finish and tonumber(w.finish:GetText()),
        source=sources[w.sourceIndex],target=targets[w.targetIndex] }
end
function E:MatchEvent(ev,f)
    return (not f.from or ev.t>=f.from) and (not f.to or ev.t<=f.to) and
        (f.source=="all" or ev.source==f.source) and
        (f.target=="all" or ev.ttype==f.target or (f.target=="friendly" and ev.ttype=="self")) and
        (matches(ev.spell,f.query) or matches(ev.target,f.query))
end

function E:DetailLines(w,s,duration)
    local result={}
    if s.unsupported then return {{left="动作回放按单场战斗保存",right="请在主窗口选择当前或历史战斗"}} end
    if s.missing then return {{left="该历史战斗未采集新模块",right="新战斗开始后会记录"}} end
    if not self.available then return {{left="无法采集：需要 Nampower 4.5 或以上",right=self.versionText}} end
    local f=self:Filters(w)
    if f.from and f.to and f.from>f.to then return {{left="起始时间不能大于结束时间",right=""}} end
    local users=self:SelectedUsers(s,w.kind,w.person,w.key)
    if w.view=="players" then
        local sorted,total=self:Sorted(s,w.kind,w.key)
        for _,row in ipairs(sorted) do
            if matches(row.name,f.query) then
                table.insert(result,{person=row.name,left=row.name,value=row.value,
                    right=format("%.0f  (%.1f%%)",row.value,100*row.value/math.max(1,total))})
            end
        end
    elseif w.view=="events" then
        local evs={}
        for _,u in ipairs(users) do
            for _,ev in ipairs(self:RingValues(u.events,self.limits.perUser)) do
                if self:MatchEvent(ev,f) then table.insert(evs,{ev=ev,user=u.name}) end
            end
        end
        table.sort(evs,function(a,b) if a.ev.t==b.ev.t then return a.ev.seq<b.ev.seq end return a.ev.t<b.ev.t end)
        for _,record in ipairs(evs) do
            local ev=record.ev
            local color=ev.kind=="death" and "|cffff5555" or "|cffffffff"
            local name=w.person and "" or (record.user.."：")
            local tc=ev.ttype=="enemy" and {r=1,g=0.25,b=0.25} or {r=0.2,g=1,b=0.2}
            if ev.ttype~="enemy" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[ev.targetClass] then tc=RAID_CLASS_COLORS[ev.targetClass] end
            local target=format("|cff%02x%02x%02x%s|r",math.floor(tc.r*255),math.floor(tc.g*255),math.floor(tc.b*255),ev.target or "无目标")
            if ev.targetOwner then target=target.."（宠物："..ev.targetOwner.."）" end
            if ev.charmedBy then target=target.."（心控："..ev.charmedBy.."）" end
            if ev.dead then target=target.."（已死亡）" end
            table.insert(result,{left=color..format("[%07.2fs] ",ev.t)..name..(ev.spell or "动作").."|r",
                right=target.."  ("..(targetNames[ev.ttype] or "未知")..")",spellId=ev.spellId,spellName=ev.spell,kind=ev.kind,
                tip=(sourceNames[ev.source] or "未知来源").." · 记录序号 "..ev.seq})
        end
    elseif w.view=="audit" then
        for _,ev in ipairs(self:RingValues(s.audit,self.limits.audit)) do
            if (not w.person or ev.owner==w.person) and (not f.from or ev.t>=f.from) and (not f.to or ev.t<=f.to) and
                (matches(ev.owner,f.query) or matches(ev.target,f.query) or matches(self:Spell(ev.spellId),f.query)) then
                table.insert(result,{left=format("[%.2fs] %s → %s",ev.t,ev.owner or "未知",ev.target or "无目标"),
                    right=format("%s  %.0f",ev.event,ev.amount or 1),spellId=ev.spellId,
                    tip="归属依据："..(ev.reason or "").."；目标GUID："..(ev.targetGuid or "").."；技能ID："..tostring(ev.spellId or 0)})
            end
        end
    else
        local merged={}
        local function collect(key,row)
                if (f.source=="all" or row.source==f.source or w.view=="targets") and matches(row.name,f.query) and
                    (w.view~="targets" or f.target=="all" or row.ttype==f.target or (f.target=="friendly" and row.ttype=="self")) then
                    -- Display all ranks and sources of the same named ability together.
                    local group=w.view=="targets" and key or row.name
                    local r=merged[group]
                    if not r then
                        r={name=row.name,spellId=row.spellId,source=row.source,total=0,effective=0,absorb=0,count=0,ids={}}
                        merged[group]=r
                    end
                    if row.spellId and row.spellId>0 then
                        r.ids[row.spellId]=true
                        if not r.spellId or r.spellId<=0 or row.spellId<r.spellId then r.spellId=row.spellId end
                    end
                    if r.source~=row.source then r.source="all" end
                    r.total=r.total+row.total;r.effective=r.effective+row.effective;r.absorb=r.absorb+row.absorb;r.count=r.count+row.count
                end
        end
        for _,u in ipairs(users) do
            if w.view=="targets" and w.skill then
                for key,skill in pairs(u.skills) do
                    if (skill.name==w.skill or key==w.skill) and (f.source=="all" or skill.source==f.source) then
                        for target,row in pairs(skill.targets) do collect(target,row) end
                    end
                end
            else
                for key,row in pairs(w.view=="targets" and u.targets or u.skills) do collect(key,row) end
            end
        end
        local sorted,total={},0
        for key,row in pairs(merged) do row.key=key;row.value=self:Value(row,w.kind);total=total+row.value;table.insert(sorted,row) end
        table.sort(sorted,function(a,b) if a.value==b.value then return a.name<b.name end return a.value>b.value end)
        for _,row in ipairs(sorted) do
            local line={left=row.name,spellName=row.name,spellId=row.spellId,skill=w.view=="skills" and row.key or nil,value=row.value,amounts=row,
                right=format("%.0f  (%.1f%%)",row.value,100*row.value/math.max(1,total))}
            if w.kind=="healing" then
                line.tip=format("总治疗 %.0f；有效治疗 %.0f；实际吸收 %.0f；事件数 %d",row.total,row.effective,row.absorb,row.count)
            else line.tip=(sourceNames[row.source] or "目标分布").."；成功施放 "..row.count.." 次" end
            local ids={};for id in pairs(row.ids) do table.insert(ids,id) end;table.sort(ids)
            if table.getn(ids)>0 then
                local visible={}
                for i=1,math.min(8,table.getn(ids)) do visible[i]=tostring(ids[i]) end
                line.tip=line.tip.."；技能ID："..table.concat(visible,", ")..(table.getn(ids)>8 and " …" or "")
                if table.getn(ids)>1 then line.tip=line.tip.."（已合并同名技能）" end
            end
            table.insert(result,line)
        end
    end
    if table.getn(result)==0 then result[1]={left="没有匹配的数据",right="检查战斗分段、模块开关或筛选条件"} end
    return result
end



function E:Render(w)
    if not self.ready then return end
    if w.compactHealing then return self:RenderHealing(w) end
    local s,duration=self:GetMode(w.key,w.kind)
    duration=math.max(1,duration or 0)
    if s.aggregate and w.view=="audit" then w.view=w.person and "skills" or "players" end
    w.title:SetText(self.names[w.kind].." — "..(w.person or "团队总览")..(s.scopeName and (" · "..s.scopeName) or ""))
    local users=self:SelectedUsers(s,w.kind,w.person,w.key)
    local totals={total=0,effective=0,absorb=0,count=0}
    for _,u in ipairs(users) do
        totals.total=totals.total+u.total;totals.effective=totals.effective+u.effective
        totals.absorb=totals.absorb+u.absorb;totals.count=totals.count+u.count
    end

    w.summary:SetText(format("%s %d 次  ·  战斗 %.1f 秒  ·  Nampower %s\n%s",
            w.kind=="casts" and "成功施放" or "技能与平砍动作",totals.count,duration,self.versionText or "未知",
            w.kind=="casts" and "一次 SPELL_GO 计一次；持续效果与群体命中不增加施放数" or "按单场战斗时间排序；死亡标记不计入动作次数"))
    
    w.source:SetText(sourceNames[sources[w.sourceIndex]]);w.targetType:SetText(targetNames[targets[w.targetIndex]])
    local lines=self:DetailLines(w,s,duration)
    w.lineCount=table.getn(lines);w.offset=math.min(w.offset,math.max(0,w.lineCount-16))
    w.caption:SetText((labels[w.view] or "详情")..(w.skill and " · 技能目标明细" or "").."                                      数量 / 占比；悬停查看拆分")
    if w.view=="events" then w.caption:SetText("时间 / 技能（同一时刻按采集顺序）                                             目标 / 类型")
    elseif w.view=="audit" then w.caption:SetText("时间 / 施法者 → 目标                                                          事件 / 金额") end
    for i,row in ipairs(w.rows) do
        local line=lines[w.offset+i]
        if line then
            row.item=line;row.left:SetText(line.left);row.right:SetText(line.right or "")
            local icon=self:Icon(line.spellId,line.spellName or line.left,line.kind)
            if line.person then
                local r,g,b,class=D:GetClassColor(line.person)
                row.left:SetTextColor(r,g,b)
                icon="Interface\\AddOns\\DPSMateX\\images\\class\\"..class
            else row.left:SetTextColor(1,1,1) end
            if icon then row.icon:SetTexture(icon);row.icon:Show() else row.icon:Hide() end
            row:Show()
        else row:Hide();row.item=nil end
    end
    w.page:SetText(format("%d–%d / %d",w.offset+1,math.min(w.offset+16,w.lineCount),w.lineCount))
    local note=""
    if s.missing then note="该战斗未采集此模块"
    elseif s.unsupported then note="请在主窗口选择单场战斗"
    elseif w.kind=="playback" then note=format("全场保留 %d；丢弃 %d；未解析 %d",s.stored or 0,s.dropped or 0,s.missed or 0)
    elseif w.view=="audit" then note="最近300条核对记录；/dpsx debug 保存限量调试日志"
    elseif w.kind=="healing" then note="多盾无法确定施法者时保留为来源未知" end
    if s.aggregate then note="累计范围，"..(s.fightCount or 0).."场战斗"..(s.detailTrimmed and "；超出明细上限的内容归入其他，总数保留" or "") end
    w.note:SetText(note)
    for view,b in pairs(w.viewButtons) do
        local show=(view=="players" or view=="skills" or view=="targets") and w.kind~="playback" or
            (view=="events" and w.kind=="playback") or (view=="audit" and not s.aggregate)
        if show then b:Show() else b:Hide() end
    end
    local showTime=w.view=="events" or w.view=="audit"
    if showTime then w.start:Show();w.finish:Show();w.start.label:Show();w.finish.label:Show()
    else w.start:Hide();w.finish:Hide();w.start.label:Hide();w.finish.label:Hide() end
    if w.view=="events" or w.view=="skills" then w.source:Show() else w.source:Hide() end
    if w.view=="events" or w.view=="targets" then w.targetType:Show() else w.targetType:Hide() end
end

function E:OpenDetails(kind,person,key,compare)
    if not self.ready then return end
    local w=kind=="healing" and self:CreateHealingDetails(compare and 2 or 1) or self:CreateDetails(compare and 2 or 1)
    local other=kind=="healing" and self.windows or self.healingWindows
    if other and other[compare and 2 or 1] then other[compare and 2 or 1]:Hide() end
    w.initializing=true;w.kind=kind;w.person=person;w.key=key or 1
    w.view=kind=="playback" and "events" or (person and "skills" or "players")
    w.skill=nil;w.selected=nil;w.offset=0;w.sourceIndex=1;w.targetIndex=1
    w.search:SetText("");if w.start then w.start:SetText("");w.finish:SetText("") end;w.initializing=nil
    w:SetScale((D.Settings.targetscale or 0.58)/UIParent:GetScale())
    if compare then
        local windows=kind=="healing" and self.healingWindows or self.windows
        w:ClearAllPoints();w:SetPoint("TOPLEFT",windows[1],"TOPRIGHT",8,0)
    end
    self:Render(w);w:Show()
end
