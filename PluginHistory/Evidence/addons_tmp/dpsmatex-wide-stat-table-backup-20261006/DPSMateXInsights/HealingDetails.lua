local D,E=DPSMateX,DPSMateX.Insights
local format=string.format
local sources={"all","player","pet","item","shield","death"}
local sourceNames={all="全部来源",player="玩家",pet="宠物",item="物品",shield="护盾",death="死亡"}
local targets={"all","enemy","friendly","self","none"}
local targetNames={all="全部目标",enemy="敌方",friendly="友方",self="自身",none="无目标"}
local visibleRows=11
local sx,sy=0.88,370/270
local rowHeight=23*sy
local function position(parent,x,y)
    if parent.detailBody then y=y*sy elseif y < -65 then y=-65+(y+65)*sy end
    return x*sx,y
end

local function font(parent,style,x,y,width,height)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontNormal")
    local px,py=position(parent,x,y)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",px,py);f:SetWidth(width*sx)
    f:SetHeight((height or 24)*((parent.detailBody or y < -65) and sy or 1))
    f:SetJustifyH("LEFT");return f
end
local function backdrop(f,alpha)
    f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=16,edgeSize=16,insets={left=6,right=6,top=6,bottom=6}})
    f:SetBackdropColor(0.157,0.08,0.06,alpha or 1)
end
local function panel(w,name,x,width)
    local p=CreateFrame("Frame",w:GetName()..name,w)
    p:SetPoint("TOPLEFT",w,"TOPLEFT",x*sx,-65);p:SetWidth(width*sx);p:SetHeight(370);p.detailBody=true;backdrop(p,0.5)
    return p
end
local function button(w,label,x,y,width,action)
    local b=CreateFrame("Button",nil,w,"UIPanelButtonTemplate")
    local px,py=position(w,x,y)
    b:SetPoint("TOPLEFT",w,"TOPLEFT",px,py);b:SetWidth(width*sx);b:SetHeight(23*(y < -65 and sy or 1));b:SetText(label)
    b:SetScript("OnClick",action);return b
end

function E:CreateHealingDetails(index)
    self.healingWindows=self.healingWindows or {}
    if self.healingWindows[index] then return self.healingWindows[index] end
    local w=CreateFrame("Frame","DPSMateX_ActualHealingDetails"..index,UIParent)
    self.healingWindows[index]=w;w.compactHealing=true
    w:SetWidth(880);w:SetHeight(450);w:SetPoint("CENTER",UIParent,"CENTER",0,0)
    w:SetFrameStrata("DIALOG");w:SetMovable(true);w:EnableMouse(true);w:SetClampedToScreen(true);backdrop(w)
    w:SetScript("OnMouseDown",function() if arg1=="LeftButton" then this:StartMoving() end end)
    w:SetScript("OnMouseUp",function() this:StopMovingOrSizing() end)
    table.insert(UISpecialFrames,w:GetName())
    w.title=font(w,"GameFontNormalHuge",20,-10,920,30)
    w.summary=font(w,"GameFontNormalSmall",20,-39,240)
    button(w,"×",960,-12,25,function() w:Hide() end)
    w.piePanel=panel(w,"_Diagram",15,245)
    w.listPanel=panel(w,"_Log",260,345)
    w.dataPanel=panel(w,"_LogDetails",605,380)
    w.search=CreateFrame("EditBox",nil,w)
    w.search:SetPoint("TOPLEFT",w,"TOPLEFT",270*sx,-40);w.search:SetWidth(190*sx);w.search:SetHeight(23)
    w.search:SetFontObject(GameFontHighlightSmall);w.search:SetAutoFocus(false);w.search:SetTextInsets(5,5,0,0);backdrop(w.search,0.5)
    w.search:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    w.search:SetScript("OnEnterPressed",function() this:ClearFocus() end)
    w.search:SetScript("OnTextChanged",function()
        if not w.initializing then w.offset=0;w.selected=nil;E:Render(w) end
    end)
    w.source=button(w,"全部来源",466,-40,96,function()
        w.sourceIndex=math.mod(w.sourceIndex,table.getn(sources))+1;w.offset=0;w.selected=nil;E:Render(w)
    end)
    w.targetType=button(w,"全部目标",466,-40,96,function()
        w.targetIndex=math.mod(w.targetIndex,table.getn(targets))+1;w.offset=0;w.selected=nil;E:Render(w)
    end)
    w.viewButtons={}
    for i,v in ipairs({"players","skills","targets"}) do
        local view=v
        w.viewButtons[v]=button(w,({players="玩家",skills="技能",targets="目标"})[v],568+(i-1)*73,-40,68,function()
            if view=="targets" then w.skill=w.selected and w.selected.skill or w.skill else w.skill=nil end
            w.view=view;w.offset=0;w.selected=nil;E:Render(w)
        end)
    end
    w.back=button(w,"返回玩家",865,-40,100,function()
        w.person=nil;w.skill=nil;w.selected=nil;w.view="players";w.offset=0;E:Render(w)
    end)
    w.refresh=button(w,"刷新",794,-40,63,function() E:Render(w) end)
    w.raw=button(w,"有效治疗＋吸收",27,-303,147,function()
        E.db.config.rawHealing=not E.db.config.rawHealing;D.DB.NeedUpdate=true;E:Render(w)
    end)
    w.viewButtons.audit=button(w,"核对",181,-303,65,function()
        w.view=w.view=="audit" and (w.person and "skills" or "players") or "audit"
        w.skill=nil;w.selected=nil;w.offset=0;E:Render(w)
    end)
    w.note=font(w,"GameFontNormalSmall",27,-277,218,24)
    w.rows={}
    w.scroll=CreateFrame("ScrollFrame",w:GetName().."_ScrollFrame",w.listPanel,"FauxScrollFrameTemplate")
    w.scroll:SetPoint("TOPLEFT",w.listPanel,"TOPLEFT",0,0)
    w.scroll:SetPoint("BOTTOMRIGHT",w.listPanel,"BOTTOMRIGHT",-25,0)
    w.scroll:EnableMouse(false);w.scroll:EnableMouseWheel(true)
    w.scroll:SetScript("OnVerticalScroll",function()
        FauxScrollFrame_OnVerticalScroll(rowHeight,function()
            w.offset=FauxScrollFrame_GetOffset(w.scroll);E:Render(w)
        end)
    end)
    for i=1,visibleRows do
        local row=CreateFrame("Button",nil,w.listPanel)
        row.detailBody=true
        row:SetPoint("TOPLEFT",w.listPanel,"TOPLEFT",7*sx,(-8-(i-1)*23)*sy);row:SetWidth(304*sx);row:SetHeight(rowHeight)
        row:RegisterForClicks("LeftButtonUp","RightButtonUp")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
        row.selected=row:CreateTexture(nil,"BACKGROUND");row.selected:SetAllPoints(row)
        row.selected:SetTexture(0.95,0.9,0.5,0.3);row.selected:Hide()
        row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(24*sx);row.icon:SetHeight(24*sx);row.icon:SetPoint("LEFT",row,"LEFT",8,0)
        row.left=font(row,"GameFontNormal",29+8/sx,0,151-12/sx,23)
        row.right=font(row,"GameFontNormal",184,0,110,23);row.right:SetJustifyH("RIGHT")
        row:SetScript("OnClick",function()
            local line=row.item;if not line then return end
            if line.person then w.person=line.person;w.view="skills";w.skill=nil;w.selected=nil;w.offset=0
            else
                w.selected=line
                if arg1=="RightButton" and line.skill then w.skill=line.skill;w.view="targets";w.offset=0;w.selected=nil end
            end
            E:Render(w)
        end)
        row:SetScript("OnEnter",function()
            if row.item then
                GameTooltip:SetOwner(row,"ANCHOR_RIGHT");GameTooltip:AddLine(row.item.left,1,1,1,true)
                GameTooltip:AddLine(row.item.right or "",1,1,1,true)
                if row.item.tip then GameTooltip:AddLine(row.item.tip,0.7,0.7,0.7,true) end
                if row.item.skill then GameTooltip:AddLine("右键查看该技能的目标",0.7,0.7,0.7,true) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        w.rows[i]=row
    end
    w:EnableMouseWheel(true)
    local function wheel()
        w.offset=math.max(0,math.min(math.max(0,(w.lineCount or 0)-visibleRows),w.offset-arg1*3));E:Render(w)
    end
    w:SetScript("OnMouseWheel",wheel);w.scroll:SetScript("OnMouseWheel",wheel)
    w.listPanel:EnableMouseWheel(true);w.listPanel:SetScript("OnMouseWheel",wheel)
    w.caption=font(w.dataPanel,"GameFontNormal",10,-4,355)
    for _,header in ipairs({{10,50,"类别"},{63,129,"次数 / 占比"},{195,55,"平均"},{255,55,"最小值"},{315,55,"最大值"}}) do
        local label=font(w.dataPanel,"GameFontNormal",header[1],-35,header[2])
        label:SetText(header[3])
        if header[1]>=195 then label:SetJustifyH("CENTER") end
    end
    w.statRows={}
    for i,label in ipairs({"命中","暴击","吸收","未分类"}) do
        local y=-70-(i-1)*30
        local row={}
        row.label=font(w.dataPanel,"GameFontNormal",10,y,50);row.label:SetText(label)
        row.count=font(w.dataPanel,"GameFontHighlight",63,y,35);row.count:SetJustifyH("CENTER")
        row.percent=font(w.dataPanel,"GameFontHighlight",144,y,48);row.percent:SetJustifyH("RIGHT")
        row.average=font(w.dataPanel,"GameFontHighlight",195,y,55);row.average:SetJustifyH("CENTER")
        row.min=font(w.dataPanel,"GameFontHighlight",255,y,55);row.min:SetJustifyH("CENTER")
        row.max=font(w.dataPanel,"GameFontHighlight",315,y,55);row.max:SetJustifyH("CENTER")
        row.bar=CreateFrame("StatusBar",nil,w.dataPanel)
        row.bar:SetPoint("TOPLEFT",w.dataPanel,"TOPLEFT",102*sx,(y-9)*sy);row.bar:SetWidth(30*sx);row.bar:SetHeight(12)
        row.bar:SetMinMaxValues(0,100);row.bar:SetStatusBarTexture("Interface\\AddOns\\DPSMateX\\images\\statusbar\\Healbot")
        local colors={{0.3,0.7,1},{1,0.7,0.3},{0.3,0.9,0.7},{0.5,0.5,0.5}}
        row.bar:SetStatusBarColor(unpack(colors[i]));w.statRows[i]=row
        local line=w.dataPanel:CreateTexture(nil,"BACKGROUND")
        line:SetPoint("TOPLEFT",w.dataPanel,"TOPLEFT",7*sx,(y-28)*sy);line:SetWidth(366*sx);line:SetHeight(1);line:SetTexture(0.5,0.5,0.5,0.5)
    end
    for _,x in ipairs({57,192,252,312}) do
        local line=w.dataPanel:CreateTexture(nil,"BACKGROUND")
        line:SetPoint("TOPLEFT",w.dataPanel,"TOPLEFT",x*sx,-35*sy);line:SetWidth(1);line:SetHeight(192*sy);line:SetTexture(0.5,0.5,0.5,0.5)
    end
    w.statNote=font(w.dataPanel,"GameFontNormalSmall",10,-235,355,32)
    w:Hide();return w
end

function E:HealingPie(w,lines)
    if not D.Options.graph then return end
    local total,signature=0,{w.view}
    for _,line in ipairs(lines) do
        total=total+(line.value or 0)
        table.insert(signature,(line.left or "")..":"..tostring(line.value or 0))
    end
    signature=table.concat(signature,"|")
    if signature==w.pieSignature then return end
    w.pieSignature=signature
    if total<=0 then if w.pie then w.pie:ResetPie();w.pie:Hide() end;return end
    if not w.pie then
        w.pie=D.Options.graph:CreateGraphPieChart(w:GetName().."Pie",w.piePanel,"CENTER","CENTER",0,25*sy,176,176)
    end
    w.pie:ResetPie();w.pie:Show()
    local other=0
    for i,line in ipairs(lines) do
        if i<=12 and (line.value or 0)>0 then w.pie:AddPie(line.value*100/total,nil,line.left)
        else other=other+(line.value or 0) end
    end
    if other>0 then w.pie:AddPie(other*100/total,nil,"其他") end
end

function E:RenderHealing(w)
    local s,duration=self:GetMode(w.key,"healing")
    if s.aggregate and (w.view=="audit" or w.view=="graph") then w.view=w.person and "skills" or "players" end
    local scope=s.scopeName and (" · "..s.scopeName) or ""
    w.title:SetText(self.names.healing.." — "..(w.person or "团队总览")..scope)
    w.summary:SetText(format("战斗 %.1fs · %s",duration or 0,self.db.config.rawHealing and "总治疗＋吸收" or "有效治疗＋吸收"))
    w.raw:SetText(self.db.config.rawHealing and "总治疗＋吸收" or "有效治疗＋吸收")
    w.source:SetText(sourceNames[sources[w.sourceIndex]]);w.targetType:SetText(targetNames[targets[w.targetIndex]])
    if w.view=="skills" then w.source:Show() else w.source:Hide() end
    if w.view=="targets" then w.targetType:Show() else w.targetType:Hide() end
    if s.aggregate then w.viewButtons.audit:Hide() else w.viewButtons.audit:Show() end
    local lines=self:DetailLines(w,s,duration)
    if table.getn(lines)==1 and not lines[1].value and w.view~="audit" then lines={} end
    w.lineCount=table.getn(lines);w.offset=math.min(w.offset,math.max(0,w.lineCount-visibleRows))
    -- Refresh selection from current amounts, so a manual refresh never displays stale totals.
    if w.selected then
        local selected=w.selected;w.selected=nil
        for _,line in ipairs(lines) do if line.left==selected.left then w.selected=line;break end end
    end
    if not w.selected and w.view~="players" and w.view~="audit" then w.selected=lines[w.offset+1] end
    for i,row in ipairs(w.rows) do
        local line=lines[w.offset+i];row.item=line
        if line then
            row.left:SetText(line.left);row.right:SetText(line.right or "")
            local icon=self:Icon(line.spellId,line.spellName or line.left,line.kind)
            if line.person then
                local r,g,b,class=D:GetClassColor(line.person);row.left:SetTextColor(r,g,b)
                icon="Interface\\AddOns\\DPSMateX\\images\\class\\"..class
            else row.left:SetTextColor(1,0.82,0) end
            if icon then row.icon:SetTexture(icon);row.icon:Show() else row.icon:Hide() end
            if line==w.selected then row.selected:Show() else row.selected:Hide() end
            row:Show()
        else row:Hide();row.selected:Hide() end
    end
    w.scroll.offset=w.offset
    FauxScrollFrame_Update(w.scroll,w.lineCount,visibleRows,rowHeight)
    local scrollBar=getglobal(w.scroll:GetName().."ScrollBar")
    if scrollBar and scrollBar:GetValue()~=w.offset*rowHeight then
        scrollBar:SetValue(w.offset*rowHeight)
    end
    if w.view=="audit" then self:HealingPie(w,{}) else self:HealingPie(w,lines) end
    local amounts=w.selected and w.selected.amounts
    if not amounts then
        amounts={total=0,effective=0,absorb=0,count=0}
        for _,u in ipairs(self:SelectedUsers(s,"healing",w.person,w.key)) do
            for _,key in ipairs({"total","effective","absorb","count"}) do amounts[key]=amounts[key]+(u[key] or 0) end
            self:MergeHealingOutcomes(amounts,u)
        end
    end
    local value=self:Value(amounts,"healing")
    w.caption:SetText((w.selected and w.selected.left or (w.skill or "治疗与吸收")).." · "..amounts.count.."次")
    local classified,recorded,maxCount=0,0,1
    for _,o in pairs(amounts.outcomes or {}) do maxCount=math.max(maxCount,o.count) end
    for i,kind in ipairs({"hit","crit","absorb"}) do
        local o=amounts.outcomes and amounts.outcomes[kind]
        local count=o and o.count or 0
        local total=o and (self.db.config.rawHealing and o.total or o.effective) or 0
        classified=classified+count;recorded=recorded+total
        local r=w.statRows[i];r.count:SetText(count)
        local percent=100*count/math.max(1,amounts.count);r.percent:SetText(format("%.1f%%",percent));r.bar:SetValue(math.ceil(100*count/maxCount))
        r.average:SetText(count>0 and tostring(math.ceil(total/count)) or "-")
        r.min:SetText(o and tostring(self.db.config.rawHealing and o.min or o.effectiveMin) or "-")
        r.max:SetText(o and tostring(self.db.config.rawHealing and o.max or o.effectiveMax) or "-")
    end
    local unknown=math.max(0,amounts.count-classified);local r=w.statRows[4]
    r.count:SetText(unknown);r.percent:SetText(format("%.1f%%",100*unknown/math.max(1,amounts.count)))
    r.bar:SetValue(100*unknown/math.max(maxCount,unknown));r.average:SetText(unknown>0 and tostring(math.ceil(math.max(0,value-recorded)/unknown)) or "-")
    r.min:SetText("-");r.max:SetText("-")
    for _,f in ipairs({r.label,r.count,r.percent,r.bar,r.average,r.min,r.max}) do if unknown>0 then f:Show() else f:Hide() end end
    w.statNote:SetText(unknown>0 and "旧记录未区分命中/暴击，归入未分类；新战斗会完整统计。" or "")
    local note=(s.unknown or 0)>0 and format("团队来源未知吸收：%.0f",s.unknown) or ""
    if s.aggregate then note=format("%s · %d场",s.scopeName or "累计范围",s.fightCount or 0)
    elseif w.view=="audit" then note="最近300条核对记录" end
    w.note:SetText(note)
end
