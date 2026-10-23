local M = TurtleSeamlessMap
local G = M.Geometry
local ART = "Interface\\AddOns\\TurtleSeamlessMap\\Art\\"
local max,min,abs = math.max,math.min,math.abs

local function Text(parent,value,size)
    local text = parent:CreateFontString(nil,"OVERLAY")
    -- SetFont can fail on missing user fonts; an existing built-in FontObject
    -- initializes every text path before SetText, including empty labels.
    text:SetFontObject(GameFontNormal)
    if STANDARD_TEXT_FONT then text:SetFont(STANDARD_TEXT_FONT,size or 12) end
    text:SetText(value or "")
    return text
end

local function Button(parent,label,width,callback)
    local b = CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetWidth(width or 70); b:SetHeight(24)
    b:SetText(label)
    b:SetScript("OnClick",callback)
    return b
end

function M:Fit(rect)
    local w,h = self.canvas:GetWidth(),self.canvas:GetHeight()
    self.view.x,self.view.y = rect[1]+rect[3]/2,rect[2]+rect[4]/2
    self.view.scale = min(w/rect[3],h/rect[4])*0.92
    self.minScale = min(w/self.world[3],h/self.world[4])*0.75
    if self.scene then self.minScale=min(w/1002,h/668)*0.5 end
    self.dirty = true
end

function M:WorldView()
    self.scene,self.selected = nil,nil
    self:Fit(self.world)
    if self.title then self.title:SetText("乌龟服无缝世界地图") end
end

function M:FocusMap(id, full)
    local map = self.byID[id]
    if not map then return end
    self.selected = id
    if full or not map.rect then
        self.scene = id
        self:Fit({0,0,1002,668})
    else
        self.scene = nil
        self:Fit(map.rect)
    end
    self.title:SetText(map.name .. (self.scene and " · 完整区域" or " · 连续地图"))
    self.dirty = true
end

function M:Cursor()
    local x,y = GetCursorPosition()
    local scale = self.canvas:GetEffectiveScale()
    return x/scale-self.canvas:GetLeft(),self.canvas:GetTop()-y/scale
end

function M:Zoom(factor)
    local x,y = self:Cursor()
    x,y=G.Clamp(x,0,self.canvas:GetWidth()),G.Clamp(y,0,self.canvas:GetHeight())
    G.Zoom(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y,factor,self.minScale or 0.001,self.scene and 8 or 3)
    self.dirty=true
end

function M:Tile(path,x,y,w,h,u,v,alpha)
    local a,b,c,d,e,f,g,i = G.Clip(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y,w,h,u or 1,v or 1)
    if not a then return end
    self.tileUsed=self.tileUsed+1
    local t = self.tiles[self.tileUsed]
    if not t then
        t=self.art:CreateTexture(nil,"ARTWORK")
        self.tiles[self.tileUsed]=t
    end
    if t.path~=path then t:SetTexture(path);t.path=path end
    t:ClearAllPoints();t:SetPoint("TOPLEFT",self.canvas,"TOPLEFT",a,-b)
    t:SetWidth(c);t:SetHeight(d);t:SetTexCoord(e,f,g,i)
    t:SetAlpha(alpha or 1);t:Show()
end

function M:DrawMap(map)
    if self.scene then
        for _,tile in ipairs(map.tiles) do
            local index=math.floor(tile[3]/256)*4+math.floor(tile[2]/256)+1
            local path="Interface\\WorldMap\\"..map.file.."\\"..map.file..index
            self:Tile(path,tile[2],tile[3],tile[4],tile[5],tile[4]/256,tile[5]/256,1)
        end
        for _,o in ipairs(map.overlays) do
            local cols=math.ceil(o.width/256)
            for i,path in ipairs(o.paths) do
                local col,row=math.mod(i-1,cols),math.floor((i-1)/cols)
                local w,h=min(256,o.width-col*256),min(256,o.height-row*256)
                local fw,fh=16,16
                while fw<w do fw=fw*2 end
                while fh<h do fh=fh*2 end
                self:Tile(path,o.x+col*256,o.y+row*256,w,h,w/fw,h/fh,1)
            end
        end
        return
    end
    local r=map.rect
    local pixels=r[3]*self.view.scale
    local alpha
    if map.kind=="continent" then alpha=1-G.Clamp((pixels-2000)/2000,0,1)
    elseif map.city then alpha=G.Clamp((pixels-420)/380,0,1)
    else alpha=G.Clamp((pixels-130)/220,0,1) end
    if alpha<=0 then return end
    for _,tile in ipairs(map.tiles) do
        self:Tile(ART..tile[1],r[1]+tile[2]/1002*r[3],r[2]+tile[3]/668*r[4],tile[4]/1002*r[3],tile[5]/668*r[4],tile[4]/256,tile[5]/256,alpha)
    end
end

-- Providers supply world coordinates and their original behavior via callbacks.
-- Pin keys are stable; panning reuses frames and never rebuilds quest databases.
function M:AddPin(key,x,y,texture,size,enter,leave,click,data)
    if not x or not y then return end
    local sx,sy=G.Screen(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y)
    local half=(size or 18)/2
    if sx<half or sy<half or sx>self.canvas:GetWidth()-half or sy>self.canvas:GetHeight()-half then return end
    if self.pinUsed >= 900 then self.pinOverflow=true;return end
    self.pinUsed=self.pinUsed+1
    local p=self.pins[self.pinUsed]
    if not p then
        p=CreateFrame("Button",nil,self.pinLayer)
        p.tex=p:CreateTexture(nil,"ARTWORK");p.tex:SetAllPoints(p)
        p:RegisterForClicks("LeftButtonUp","RightButtonUp")
        p:SetScript("OnEnter",function() if this.enter then this.enter(this) end end)
        p:SetScript("OnLeave",function() if this.leave then this.leave(this) end end)
        p:SetScript("OnClick",function() if this.click then this.click(this,arg1) end end)
        p:EnableMouseWheel(true)
        p:SetScript("OnMouseWheel",function() M:Zoom(arg1>0 and 1.18 or 1/1.18) end)
        self.pins[self.pinUsed]=p
    end
    p.key,p.enter,p.leave,p.click,p.data=key,enter,leave,click,data
    p:SetWidth(size or 18);p:SetHeight(size or 18)
    p:ClearAllPoints();p:SetPoint("CENTER",self.canvas,"TOPLEFT",sx,-sy)
    p.tex:SetTexture(texture);p.tex:SetVertexColor(1,1,1,1)
    p:Show()
    return p
end

function M:Render()
    self.tileUsed,self.pinUsed,self.pinOverflow=0,0,false
    if self.scene then
        local map=self.byID[self.scene]
        if map then self:DrawMap(map) end
    else
        for _,map in ipairs(self.drawOrder) do self:DrawMap(map) end
    end
    for i=self.tileUsed+1,table.getn(self.tiles) do self.tiles[i]:Hide() end
    for name,provider in pairs(self.providers) do
        local ok,err=pcall(provider,self)
        if not ok and not self.providerErrors[name] then
            self.providerErrors[name]=true
            DEFAULT_CHAT_FRAME:AddMessage("TurtleSeamlessMap "..name..": "..tostring(err))
        end
    end
    self:DrawPlayer()
    self:DrawNotes()
    for i=self.pinUsed+1,table.getn(self.pins) do self.pins[i]:Hide() end
    self.dirty=false
end

function M:DrawPlayer()
    if not GetMapInfo or not GetPlayerMapPosition then return end
    local file=GetMapInfo()
    local map=file and self.byFile[string.lower(file)]
    if not map then return end
    -- GetPlayerMapPosition uses global map selection. A remote selected map
    -- must not manufacture a player position on a different continent.
    local real=GetRealZoneText and GetRealZoneText()
    if real and map.name~=real and not self.byName[real] then return end
    if real and self.byName[real] and self.byName[real].id~=map.id then return end
    local x,y=GetPlayerMapPosition("player")
    if not x or (x==0 and y==0) then return end
    x,y=self:MapToWorld(map.id,x,y)
    self:AddPin("player",x,y,"Interface\\Minimap\\MinimapArrow",22)
end

function M:FindPlayer()
    -- Once on explicit user request, never during map panning/rendering.
    self.ignoreMapEvent=true
    SetMapToCurrentZone()
    self.ignoreMapEvent=false
    local file=GetMapInfo()
    local map=file and self.byFile[string.lower(file)]
    if not map then return end
    self:FocusMap(map.id)
    local x,y=GetPlayerMapPosition("player")
    if x and y and not (x==0 and y==0) then
        local wx,wy=self:MapToWorld(map.id,x,y)
        if wx then self.view.x,self.view.y=wx,wy end
    end
end

function M:DrawNotes()
    for i,n in ipairs(self.settings.notes) do
        if (n.scene or 0)==(self.scene or 0) then
            self:AddPin("note"..i,n.x,n.y,"Interface\\WorldStateFrame\\AllianceFlag",22,
                function(p) GameTooltip:SetOwner(p,"ANCHOR_RIGHT");GameTooltip:SetText("自定义标记 · 右键删除");GameTooltip:Show() end,
                function() GameTooltip:Hide() end,
                function(p,button) if button=="RightButton" then table.remove(M.settings.notes,p.data);M.dirty=true;GameTooltip:Hide() end end,i)
        end
    end
end

function M:Toggle()
    if WorldMapFrame and WorldMapFrame:IsShown() then WorldMapFrame:Hide();return end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end

function M:ShowNative()
    self.frame:Hide()
    self.nativeRequested=true
    WorldMapFrame:Show()
    self.nativeRequested=false
end

function M:UpdateList()
    local query=string.lower(self.search:GetText() or "")
    self.listMaps={}
    for _,map in ipairs(self.maps) do
        if query=="" or string.find(string.lower(map.name),query,1,true) or string.find(string.lower(map.file),query,1,true) then
            table.insert(self.listMaps,map)
        end
    end
    self.listOffset=G.Clamp(self.listOffset or 0,0,max(0,table.getn(self.listMaps)-16))
    for i,b in ipairs(self.listRows) do
        local map=self.listMaps[self.listOffset+i]
        if map then b.mapID=map.id;b:SetText(map.name);b:Show() else b:Hide() end
    end
    self.listCount:SetText(table.getn(self.listMaps).." 张地图 · 滚轮翻页")
end

function M:BuildUI()
    local f=CreateFrame("Frame","TurtleSeamlessMapFrame",UIParent)
    self.frame=f
    f:SetFrameStrata("DIALOG");f:SetFrameLevel(90)
    local w=min(1180,UIParent:GetWidth()-50)
    local h=min(790,UIParent:GetHeight()-60)
    f:SetWidth(w);f:SetHeight(h);f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(0.06,0.07,0.08,0.98)
    f:EnableMouse(true);f:SetMovable(true);f:SetClampedToScreen(true)
    f:Hide();table.insert(UISpecialFrames,"TurtleSeamlessMapFrame")
    local title=Text(f,"乌龟服无缝世界地图",15)
    title:SetPoint("TOPLEFT",f,"TOPLEFT",18,-12);self.title=title
    local header=CreateFrame("Frame",nil,f)
    header:SetWidth(w-100);header:SetHeight(30);header:SetPoint("TOPLEFT",f,"TOPLEFT",8,-2)
    header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function() f:StartMoving() end)
    header:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    local close=Button(f,"关闭",54,function() f:Hide() end)
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-12,-8)
    local canvas=CreateFrame("Frame",nil,f)
    self.canvas=canvas
    canvas:SetWidth(w-28);canvas:SetHeight(h-112)
    canvas:SetPoint("TOPLEFT",f,"TOPLEFT",14,-70)
    local bg=canvas:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(canvas);bg:SetTexture(0.43,0.39,0.27,1)
    canvas:EnableMouse(true);canvas:EnableMouseWheel(true)
    canvas:SetScript("OnMouseWheel",function() M:Zoom(arg1>0 and 1.18 or 1/1.18) end)
    canvas:SetScript("OnMouseDown",function()
        if arg1=="LeftButton" then
            local x,y=M:Cursor()
            if IsControlKeyDown() then
                local wx,wy=G.World(M.view,canvas:GetWidth(),canvas:GetHeight(),x,y)
                table.insert(M.settings.notes,{x=wx,y=wy,scene=M.scene});M.dirty=true
            else M.drag={x=x,y=y,cx=M.view.x,cy=M.view.y} end
        elseif arg1=="RightButton" then M:Zoom(0.5) end
    end)
    canvas:SetScript("OnMouseUp",function() M.drag=nil end)
    self.art=CreateFrame("Frame",nil,canvas);self.art:SetAllPoints(canvas);self.art:SetFrameLevel(91)
    self.pinLayer=CreateFrame("Frame",nil,canvas);self.pinLayer:SetAllPoints(canvas);self.pinLayer:SetFrameLevel(125)
    local buttons={
        {"世界",54,function() M:WorldView() end},
        {"卡利姆多",78,function() M:FocusMap(13) end},
        {"东部王国",78,function() M:FocusMap(14) end},
        {"我的位置",78,function() M:FindPlayer() end},
        {"区域列表",78,function() if M.list:IsShown() then M.list:Hide() else M:UpdateList();M.list:Show() end end},
        {"完整区域",78,function()
            local map=M.scene and M.byID[M.scene] or M:MapAt(M.view.x,M.view.y) or (M.selected and M.byID[M.selected])
            if map then M:FocusMap(map.id,not M.scene) end
        end},
        {"标记筛选",78,function() M:ToggleMarkerMenu() end},
        {"任务开关",78,function() M.settings.quests=not M.settings.quests;M.dirty=true end},
        {"原地图",66,function() M:ShowNative() end},
    }
    local previous
    for _,spec in ipairs(buttons) do
        local b=Button(f,spec[1],spec[2],spec[3])
        if previous then b:SetPoint("LEFT",previous,"RIGHT",4,0) else b:SetPoint("TOPLEFT",f,"TOPLEFT",14,-38) end
        previous=b
    end
    self.status=Text(f,"",11)
    self.status:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,14)
    local list=CreateFrame("Frame",nil,f);self.list=list
    list:SetWidth(270);list:SetHeight(476);list:SetFrameLevel(180)
    list:SetPoint("TOPRIGHT",canvas,"TOPRIGHT",-6,-6)
    list:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    list:SetBackdropColor(0.05,0.05,0.05,1)
    list:EnableMouse(true);list:EnableMouseWheel(true);list:Hide()
    list:SetScript("OnMouseWheel",function() M.listOffset=(M.listOffset or 0)-arg1*4;M:UpdateList() end)
    local search=CreateFrame("EditBox",nil,list,"InputBoxTemplate");self.search=search
    search:SetWidth(226);search:SetHeight(24);search:SetPoint("TOPLEFT",list,"TOPLEFT",18,-12)
    search:SetAutoFocus(false);search:SetFontObject(GameFontNormal);search:SetText("")
    search:SetScript("OnTextChanged",function() M.listOffset=0;M:UpdateList() end)
    search:SetScript("OnEscapePressed",function() this:ClearFocus();list:Hide() end)
    search:SetScript("OnEnterPressed",function()
        if M.listMaps and M.listMaps[1] then M:FocusMap(M.listMaps[1].id);list:Hide();this:ClearFocus() end
    end)
    self.listRows={}
    for i=1,16 do
        local b=Button(list,"",238,function() M:FocusMap(this.mapID);list:Hide();search:ClearFocus() end)
        b:SetPoint("TOPLEFT",list,"TOPLEFT",14,-42-(i-1)*25)
        b:EnableMouseWheel(true);b:SetScript("OnMouseWheel",list:GetScript("OnMouseWheel"))
        self.listRows[i]=b
    end
    self.listCount=Text(list,"",11);self.listCount:SetPoint("BOTTOMLEFT",list,"BOTTOMLEFT",14,12)
    f:SetScript("OnShow",function()
        if WorldMapFrame:IsShown() then WorldMapFrame:Hide() end
        M.dirty=true;M.lastProviderRefresh=0
        if not M.view.scale then M:WorldView() end
        if UpdateMicroButtons then UpdateMicroButtons() end
    end)
    f:SetScript("OnHide",function()
        M.drag=nil;M.list:Hide();search:ClearFocus();GameTooltip:Hide()
        if M.markerMenu then M.markerMenu:Hide() end
        M.settings.view={x=M.view.x,y=M.view.y,scale=M.view.scale,scene=M.scene,selected=M.selected}
        if UpdateMicroButtons then UpdateMicroButtons() end
    end)
    f:SetScript("OnUpdate",function()
        if M.drag then
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then M.drag=nil
            else
                local x,y=M:Cursor()
                M.view.x=M.drag.cx-(x-M.drag.x)/M.view.scale
                M.view.y=M.drag.cy-(y-M.drag.y)/M.view.scale
                M.dirty=true
            end
        end
        local now=GetTime()
        if now-(M.lastProviderRefresh or 0)>0.35 then M.lastProviderRefresh=now;M.dirty=true end
        if now-(M.lastRender or 0)<0.03 then return end
        M.lastRender=now
        if M.dirty then M:Render() end
        local x,y=M:Cursor()
        local wx,wy=G.World(M.view,canvas:GetWidth(),canvas:GetHeight(),x,y)
        local map=M.scene and M.byID[M.scene] or M:MapAt(wx,wy)
        local where=map and map.name or "世界"
        M.status:SetText(where.."   滚轮缩放 · 左键拖动 · 右键缩小 · Ctrl+左键标记"..(M.pinOverflow and "   标记过密，请放大查看" or ""))
    end)
end

function M:Install()
    if self.installed then return end
    self.installed=true
    TurtleSeamlessMapDB=TurtleSeamlessMapDB or {}
    self.settings=TurtleSeamlessMapDB
    self.settings.notes=self.settings.notes or {}
    if self.settings.quests==nil then self.settings.quests=true end
    self.tiles,self.pins,self.providerErrors,self.view={},{},{},{}
    self:IndexMaps();self:BuildUI();self:WorldView()
    local saved=self.settings.view
    if saved and G.Finite(saved.x) and G.Finite(saved.y) and G.Finite(saved.scale) and saved.scale>0 and saved.scale<=8 and (not saved.scene or self.byID[saved.scene]) then
        self.scene,self.selected=saved.scene,saved.selected
        self.view={x=saved.x,y=saved.y,scale=saved.scale}
        self.minScale=self.scene and min(self.canvas:GetWidth()/1002,self.canvas:GetHeight()/668)*0.5 or self.minScale
    end
    ToggleWorldMap=function() M:Toggle() end
    local originalShow=WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow",function()
        if M.nativeRequested then if originalShow then originalShow() end;return end
        local file=GetMapInfo()
        local map=file and M.byFile[string.lower(file)]
        WorldMapFrame:Hide();M.frame:Show()
        if map then M:FocusMap(map.id) end
    end)
    self:InstallCompat()
end

local loader=CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("WORLD_MAP_UPDATE")
loader:RegisterEvent("CLOSE_WORLD_MAP")
loader:SetScript("OnEvent",function()
    if event=="PLAYER_ENTERING_WORLD" and not M.installed then
        this:SetScript("OnUpdate",function()
            this.elapsed=(this.elapsed or 0)+arg1
            if this.elapsed>0.5 then this:SetScript("OnUpdate",nil);M:Install() end
        end)
    elseif event=="CLOSE_WORLD_MAP" and M.installed then
        M.frame:Hide()
    elseif event=="WORLD_MAP_UPDATE" and M.installed and M.frame:IsShown() and not M.ignoreMapEvent then
        M.dirty=true
    end
end)

SLASH_TURTLESEAMLESSMAP1="/tsm"
SlashCmdList["TURTLESEAMLESSMAP"]=function(msg)
    if not M.installed then return end
    if msg=="native" then M:ShowNative()
    elseif msg=="world" then M:WorldView();M.frame:Show()
    else M:Toggle() end
end
