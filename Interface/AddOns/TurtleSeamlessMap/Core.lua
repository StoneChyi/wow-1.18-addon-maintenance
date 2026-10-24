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
    b:SetScript("OnClick",function() M.pendingLocation=nil;callback() end)
    return b
end

function M:Fit(rect)
    local w,h = self.canvas:GetWidth(),self.canvas:GetHeight()
    self.view.x,self.view.y = rect[1]+rect[3]/2,rect[2]+rect[4]/2
    self.view.scale = min(w/rect[3],h/rect[4])*0.92
    self.minScale = self:WorldScale()
    self.view.scale=max(self.minScale,min(64,self.view.scale))
    self:ConstrainView()
    self.dirty = true
end

function M:WorldScale()
    return min(self.canvas:GetWidth()/self.world[3],self.canvas:GetHeight()/self.world[4])
end

function M:IsWorldView()
    return self.view.scale and self.view.scale<=self:WorldScale()*1.000001
end

function M:ConstrainView()
    G.Constrain(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),self.world)
end

function M:WorldView()
    self.pendingLocation=nil
    self.scene,self.selected = nil,nil
    self.zoomFocus = nil
    self.hoveredID = false
    self.view.x,self.view.y=501,334
    self.minScale=self:WorldScale()
    self.view.scale=self.minScale
    self.drag=nil;self.dirty=true
    if self.title then self.title:SetText("乌龟服无缝世界地图") end
    if self.frame:IsShown() then self:RenderArt();self:LayoutPins() end
end

function M:FocusMap(id)
    local map = self.byID[id]
    if not map then return end
    self.pendingLocation=nil
    self.selected = id
    self.hoveredID = id
    self.scene = nil
    self.zoomFocus = nil
    self:Fit(map.focusRect or map.rect)
    if map.city then self.view.scale=min(64,self.view.scale*1.35) end
    self.title:SetText(map.name .. " · 连续地图")
    self.dirty = true
    if self.frame:IsShown() then self:RenderArt();self:LayoutPins() end
end

function M:Cursor()
    local x,y = GetCursorPosition()
    local scale = self.canvas:GetEffectiveScale()
    return x/scale-self.canvas:GetLeft(),self.canvas:GetTop()-y/scale
end

function M:Zoom(factor)
    self.pendingLocation=nil
    local x,y = self:Cursor()
    x,y=G.Clamp(x,0,self.canvas:GetWidth()),G.Clamp(y,0,self.canvas:GetHeight())
    local wx,wy=G.World(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y)
    self.zoomFocus={x=wx,y=wy}
    G.Zoom(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y,factor,self.minScale or 0.001,64)
    self:ConstrainView()
    if self:IsWorldView() then self.drag=nil;self.zoomFocus=nil end
    self.dirty=true
    self.lastInteraction=GetTime()
    -- The map is ready before returning from the input handler. Node scans
    -- run separately; they must not hold up the new map geometry.
    if self:ViewChanged() then self:RenderArt();self:LayoutPins() end
end

function M:Tile(path,x,y,w,h,u,v,alpha,layer)
    local a,b,c,d,e,f,g,i = G.Clip(self.view,self.canvas:GetWidth(),self.canvas:GetHeight(),x,y,w,h,u or 1,v or 1)
    if not a then return end
    self.tileUsed=self.tileUsed+1
    local map=self.activeMap
    if not map.artFrame then
        map.artFrame=CreateFrame("Frame",nil,self.art)
        map.artFrame:SetAllPoints(self.canvas);map.artFrame:SetFrameLevel(map.drawLevel)
        map.texturePool={};map.textures={}
    end
    -- A texture always belongs to one map and one asset. Never recycle a
    -- continent region as a zone region in the same unordered ARTWORK layer.
    local t = map.texturePool[path]
    if not t then
        t=map.artFrame:CreateTexture(nil,layer or "ARTWORK")
        t:SetTexture(path);t.path=path
        map.texturePool[path]=t;table.insert(map.textures,t)
    end
    self.tiles[self.tileUsed]=t;t.paintPass=self.paintPass
    t:ClearAllPoints();t:SetPoint("TOPLEFT",self.canvas,"TOPLEFT",a,-b)
    t:SetWidth(c);t:SetHeight(d);t:SetTexCoord(e,f,g,i)
    t:SetAlpha(alpha or 1)
    if not t.active then t:Show();t.active=true end
end

function M:DrawMap(map)
    local classic=self:IsWorldView() and self.settings.overviewStyle=="classic"
    if map.kind=="world" and classic then self:DrawAtlas(map,TurtleSeamlessMap_Terrain.classic,true);return end
    if map.kind=="world" and self.settings.detailStyle=="terrain" then
        self:DrawAtlas(map,TurtleSeamlessMap_Terrain.ocean,true);return
    end
    if map.kind=="continent" and classic then return end
    if map.kind=="continent" and self.settings.detailStyle=="terrain" then
        for _,continent in ipairs(TurtleSeamlessMap_Terrain.continents) do
            if continent.id==map.map then self:DrawAtlas(map,continent,false);return end
        end
    end
    if map.atlas then self:DrawAtlas(map,map.atlas,map.kind=="world");return end
    if not map.city then return end
    if not self.settings.cityMaps then return end
    if not map.visible or map.alpha<=0 then return end
    if self.settings.detailStyle=="terrain" then
        -- Surface cities already belong to the continuous native terrain. Only
        -- underground rooms need a separate, coordinate-registered real layer.
        local city=TurtleSeamlessMap_Terrain.cities[map.id]
        if city then self:DrawAtlas(map,city,false) end
        return
    end
    local r=map.artRect or map.rect
    local artW,artH=map.artWidth or 1002,map.artHeight or 668
    local alpha=map.alpha
    if alpha<=0 then return end
    local function draw(tiles,a,layer)
        if a<=0 then return end
        for _,tile in ipairs(tiles) do
            self:Tile(ART..tile[1],r[1]+tile[2]/artW*r[3],r[2]+tile[3]/artH*r[4],tile[4]/artW*r[3],tile[5]/artH*r[4],tile[4]/256,tile[5]/256,a,layer)
        end
    end
    draw(map.tiles,alpha)
end

-- Providers supply world coordinates and their original behavior via callbacks.
-- Pin keys are stable; panning reuses frames and never rebuilds quest databases.
function M:AddPin(key,x,y,texture,size,enter,leave,click,data,mapID)
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
    p.worldX,p.worldY,p.mapID=x,y,mapID
    p:SetWidth(size or 18);p:SetHeight(size or 18)
    p:ClearAllPoints();p:SetPoint("CENTER",self.canvas,"TOPLEFT",sx,-sy)
    if p.tex.path~=texture then p.tex:SetTexture(texture);p.tex.path=texture end
    p.tex:SetVertexColor(1,1,1,1)
    p:Show()
    return p
end

function M:CameraChanged()
    local v=self.paintedView
    return not v or v.x~=self.view.x or v.y~=self.view.y or v.scale~=self.view.scale
        or v.w~=self.canvas:GetWidth() or v.h~=self.canvas:GetHeight()
        or v.style~=self.settings.detailStyle or v.overview~=self.settings.overviewStyle or v.cityMaps~=self.settings.cityMaps
end

function M:ViewChanged()
    if self:CameraChanged() then return true end
    local focus=self:ChooseDetailMap()
    return self.paintedView.focus~=(focus and focus.id)
end

function M:RenderArt()
    local moved=self:CameraChanged()
    self.tileUsed=0
    for i=table.getn(self.tiles),1,-1 do self.tiles[i]=nil end
    self.paintPass=(self.paintPass or 0)+1
    self:UpdateVisibility()
    local focused=self.detailTarget and self.detailTarget.id
    if self.paintedView and self.paintedView.focus~=focused then self.lastInteraction=GetTime() end
    for _,map in ipairs(self.drawOrder) do
        if not moved and map.kind~="surface" then
            -- Cursor-only region switching does not touch world/continent
            -- texture geometry or rebind their assets.
            for _,texture in ipairs(map.textures or {}) do
                if texture.active then
                    texture.paintPass=self.paintPass
                    self.tileUsed=self.tileUsed+1;self.tiles[self.tileUsed]=texture
                end
            end
        else self.activeMap=map;self:DrawMap(map) end
        for _,texture in ipairs(map.textures or {}) do
            if texture.paintPass~=self.paintPass then
                if texture.active then texture:Hide();texture.active=false end
                -- Reusable atlas slots must not retain every visited asset.
                -- This bounds live references, not the driver's internal cache.
                if texture.atlasSlot and texture.path then texture:SetTexture(nil);texture.path=nil end
            end
        end
    end
    self.activeMap=nil
    self.paintedView={x=self.view.x,y=self.view.y,scale=self.view.scale,w=self.canvas:GetWidth(),h=self.canvas:GetHeight(),focus=focused,style=self.settings.detailStyle,overview=self.settings.overviewStyle,cityMaps=self.settings.cityMaps}
    self:DrawRegionLabels()
    self.artRenders=(self.artRenders or 0)+1
end

function M:LayoutPins()
    local w,h=self.canvas:GetWidth(),self.canvas:GetHeight()
    for i=1,self.pinUsed or 0 do
        local p=self.pins[i]
        local sx,sy=G.Screen(self.view,w,h,p.worldX,p.worldY)
        local half=p:GetWidth()/2
        if sx<half or sy<half or sx>w-half or sy>h-half or (p.mapID and not self:CanShowMapPins(self.byID[p.mapID])) then
            p:Hide()
        else
            p:ClearAllPoints();p:SetPoint("CENTER",self.canvas,"TOPLEFT",sx,-sy);p:Show()
        end
    end
end

function M:RenderPins()
    self.pinUsed,self.pinOverflow=0,false
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
    self.lastProviderRefresh=GetTime()
end

function M:Render()
    if self:ViewChanged() then self:RenderArt() end
    self:RenderPins()
end

function M:PlayerArea()
    local real=GetRealZoneText and GetRealZoneText()
    if real and real~="" and self.byName[real] then return self.byName[real] end
    local zone=GetZoneText and GetZoneText()
    return zone and zone~="" and self.byName[zone] or nil
end

function M:PlayerCoordinates(map)
    local file=GetMapInfo()
    local selected=file and self.byFile[string.lower(file)]
    if not map or selected~=map then return end
    local x,y=GetPlayerMapPosition("player")
    if G.Finite(x) and G.Finite(y) and x>=0 and x<=1 and y>=0 and y<=1 and not (x==0 and y==0) then
        return self:MapToWorld(map.id,x,y)
    end
end

function M:DrawPlayer()
    local map=self:PlayerArea()
    if not map then return end
    local x,y=self:PlayerCoordinates(map)
    if x then self.lastPlayer={id=map.id,x=x,y=y} end
    local last=self.lastPlayer
    if last and last.id==map.id then self:AddPin("player",last.x,last.y,"Interface\\Minimap\\MinimapArrow",22) end
end

function M:FindPlayer(retry)
    if self.locating then return true end
    -- Once when opening with M or requesting location, never during pan/zoom.
    local previousIgnore=self.ignoreMapEvent
    self.ignoreMapEvent=true;self.locating=true
    local ok,err=pcall(SetMapToCurrentZone)
    self.ignoreMapEvent=previousIgnore;self.locating=nil
    self.pendingLocation=nil
    local map=self:PlayerArea()
    if map then self:FocusMap(map.id) else self:WorldView();self.lastPlayer=nil end
    local x,y
    if ok then x,y=self:PlayerCoordinates(map) end
    if x then
        self.view.x,self.view.y=x,y;self.lastPlayer={id=map.id,x=x,y=y}
    else
        local remaining=retry and retry.remaining-1 or 7
        if remaining>0 then self.pendingLocation={next=GetTime()+0.1+(7-remaining)*.025,remaining=remaining} end
    end
    self.locationError=not ok and tostring(err) or nil
    self:ConstrainView()
    if self.frame:IsShown() then self:RenderArt();self:LayoutPins() end
    return true
end

function M:DrawRegionLabels()
    self.regionLabels=self.regionLabels or {}
    local used=0
    local map=self.detailTarget
    if self.settings.detailStyle=="terrain" and not self:IsWorldView() and map then
        local w,h=self.canvas:GetWidth(),self.canvas:GetHeight()
        local coverage=min(map.rect[3]*self.view.scale/w,map.rect[4]*self.view.scale/h)
        -- One focused region, only when its extent occupies a near view. Broad
        -- views never show a random subset of labels for small regions.
        local position=TurtleSeamlessMap_Terrain.labels[map.id]
        local city=TurtleSeamlessMap_Terrain.cities[map.id]
        if city then position={city.rect[1]+city.rect[3]/2,city.rect[2]+city.rect[4]/2} end
        if position and coverage>=0.72 then
            local sx,sy=G.Screen(self.view,w,h,position[1],position[2])
            if sx>70 and sx<w-70 and sy>15 and sy<h-15 then
                used=1
                local label=self.regionLabels[1]
                if not label then label=Text(self.labelLayer,"",13);self.regionLabels[1]=label end
                label.mapID=map.id
                label:SetText(map.name);label:ClearAllPoints();label:SetPoint("CENTER",self.canvas,"TOPLEFT",sx,-sy);label:Show()
            end
        end
    end
    for i=used+1,table.getn(self.regionLabels) do self.regionLabels[i]:Hide() end
end

function M:RefreshAppearance()
    self.pendingLocation=nil;self.paintedView=nil;self.dirty=true
    if self.frame:IsShown() then self:RenderArt();self:LayoutPins() end
end

function M:DrawNotes()
    for i,n in ipairs(self.settings.notes) do
        if G.Finite(n.x) and G.Finite(n.y) then
            self:AddPin("note"..i,n.x,n.y,"Interface\\WorldStateFrame\\AllianceFlag",22,
                function(p) GameTooltip:SetOwner(p,"ANCHOR_RIGHT");GameTooltip:SetText("自定义标记 · 右键删除");GameTooltip:Show() end,
                function() GameTooltip:Hide() end,
                function(p,button) if button=="RightButton" then table.remove(M.settings.notes,p.data);M.dirty=true;GameTooltip:Hide() end end,i)
        end
    end
end

function M:Toggle()
    if WorldMapFrame and WorldMapFrame:IsShown() then WorldMapFrame:Hide();return end
    if self.frame:IsShown() then self.frame:Hide()
    else
        if not self.ignoreMapEvent and not self:FindPlayer() then self:WorldView() end
        self.frame:Show()
    end
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
        if map.kind=="surface" and (query=="" or string.find(string.lower(map.name),query,1,true) or string.find(string.lower(map.file),query,1,true)) then
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
    -- Match the native world aspect rather than letterboxing, stretching or
    -- cropping geography to fill a differently shaped canvas.
    local w=min(1180,UIParent:GetWidth()-50,(UIParent:GetHeight()-172)*1.5+28)
    local toolbarExtra=w<830 and 30 or 0
    if toolbarExtra>0 then w=min(w,(UIParent:GetHeight()-202)*1.5+28) end
    local h=(w-28)/1.5+112+toolbarExtra
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
    canvas:SetWidth(w-28);canvas:SetHeight(h-112-toolbarExtra)
    canvas:SetPoint("TOPLEFT",f,"TOPLEFT",14,-70-toolbarExtra)
    -- The original world's paper, sea and ornaments are geographic artwork in
    -- the atlas background. No repeating sea texture replaces them on zoom.
    canvas:EnableMouse(true);canvas:EnableMouseWheel(true)
    canvas:SetScript("OnMouseWheel",function() M:Zoom(arg1>0 and 1.18 or 1/1.18) end)
    canvas:SetScript("OnMouseDown",function()
        M.pendingLocation=nil
        if arg1=="LeftButton" then
            local x,y=M:Cursor()
            if IsControlKeyDown() then
                local wx,wy=G.World(M.view,canvas:GetWidth(),canvas:GetHeight(),x,y)
                table.insert(M.settings.notes,{x=wx,y=wy});M.dirty=true
            elseif not M:IsWorldView() then M.pendingLocation=nil;M.zoomFocus=nil;M.drag={x=x,y=y,cx=M.view.x,cy=M.view.y} end
        elseif arg1=="RightButton" then M:Zoom(0.5) end
    end)
    canvas:SetScript("OnMouseUp",function() M.drag=nil end)
    self.art=CreateFrame("Frame",nil,canvas);self.art:SetAllPoints(canvas);self.art:SetFrameLevel(91)
    self.pinLayer=CreateFrame("Frame",nil,canvas);self.pinLayer:SetAllPoints(canvas);self.pinLayer:SetFrameLevel(94+table.getn(self.drawOrder))
    self.labelLayer=CreateFrame("Frame",nil,canvas);self.labelLayer:SetAllPoints(canvas);self.labelLayer:SetFrameLevel(self.pinLayer:GetFrameLevel()-1)
    local buttons={
        {"世界",54,function() M:WorldView() end},
        {"卡利姆多",78,function() M:FocusMap(13) end},
        {"东部王国",78,function() M:FocusMap(14) end},
        {"我的位置",78,function() M:FindPlayer() end},
        {"区域列表",78,function() if M.list:IsShown() then M.list:Hide() else M:UpdateList();M.list:Show() end end},
        {"区域定位",78,function()
            local map=M:MapAt(M.view.x,M.view.y) or (M.selected and M.byID[M.selected])
            if map then M:FocusMap(map.id) end
        end},
        {"标记筛选",78,function() M:ToggleMarkerMenu() end},
        {"任务开关",78,function() M.settings.quests=not M.settings.quests;M.dirty=true end},
        {"地图样式",78,function() if M.styleMenu:IsShown() then M.styleMenu:Hide() else M:UpdateStyleMenu();M.styleMenu:Show() end end},
        {"原地图",66,function() M:ShowNative() end},
    }
    local previous;self.toolbarButtons={}
    for index,spec in ipairs(buttons) do
        local b=Button(f,spec[1],spec[2],spec[3])
        if toolbarExtra>0 and index==6 then b:SetPoint("TOPLEFT",f,"TOPLEFT",14,-68)
        elseif previous then b:SetPoint("LEFT",previous,"RIGHT",4,0) else b:SetPoint("TOPLEFT",f,"TOPLEFT",14,-38) end
        table.insert(self.toolbarButtons,b)
        previous=b
    end
    self.status=Text(f,"",11)
    self.status:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,14)
    local style=CreateFrame("Frame",nil,f);self.styleMenu=style
    style:SetWidth(246);style:SetHeight(140);style:SetFrameLevel(185)
    style:SetPoint("TOPRIGHT",canvas,"TOPRIGHT",-6,-6)
    style:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    style:SetBackdropColor(.05,.05,.05,1);style:EnableMouse(true);style:Hide()
    local heading=Text(style,"地图样式",13);heading:SetPoint("TOPLEFT",style,"TOPLEFT",14,-12)
    self.styleButtons={}
    local callbacks={
        function() M.settings.detailStyle=M.settings.detailStyle=="terrain" and "paper" or "terrain" end,
        function() M.settings.overviewStyle=M.settings.overviewStyle=="classic" and "continuous" or "classic" end,
        function() M.settings.cityMaps=not M.settings.cityMaps end,
    }
    for i,callback in ipairs(callbacks) do
        local action=callback
        local button=Button(style,"",218,function() action();M:UpdateStyleMenu();M:RefreshAppearance() end)
        button:SetPoint("TOPLEFT",style,"TOPLEFT",14,-32-(i-1)*31);self.styleButtons[i]=button
    end
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
        M:Render()
        if UpdateMicroButtons then UpdateMicroButtons() end
    end)
    f:SetScript("OnHide",function()
        M.pendingLocation=nil
        M.drag=nil;M.list:Hide();M.styleMenu:Hide();search:ClearFocus();GameTooltip:Hide()
        if M.markerMenu then M.markerMenu:Hide() end
        M.settings.view={x=M.view.x,y=M.view.y,scale=M.view.scale,selected=M.selected}
        if UpdateMicroButtons then UpdateMicroButtons() end
    end)
    f:SetScript("OnUpdate",function()
        if M.pendingLocation and GetTime()>=M.pendingLocation.next then M:FindPlayer(M.pendingLocation) end
        if M.drag then
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then M.drag=nil
            else
                local x,y=M:Cursor()
                M.view.x=M.drag.cx-(x-M.drag.x)/M.view.scale
                M.view.y=M.drag.cy-(y-M.drag.y)/M.view.scale
                M:ConstrainView();M.lastInteraction=GetTime()
                M.dirty=true
            end
        end
        local now=GetTime()
        if M:ViewChanged() then M:RenderArt();M:LayoutPins();M.dirty=true end
        -- Reuse and reposition existing pins during input. Let detail artwork
        -- update every frame, coalescing expensive provider work during bursts.
        local sincePins=now-(M.lastProviderRefresh or 0)
        local quiet=now-(M.lastInteraction or -1)>0.08
        if (M.dirty and quiet) or sincePins>0.35 then M:RenderPins() end
        if now-(M.lastStatus or 0)<0.08 then return end
        M.lastStatus=now
        local x,y=M:Cursor()
        local wx,wy=G.World(M.view,canvas:GetWidth(),canvas:GetHeight(),x,y)
        local map=M:MapAt(wx,wy)
        local where=map and map.name or "世界"
        M.status:SetText(where..(M:IsWorldView() and "   滚轮放大 · Ctrl+左键标记" or "   指向区域查看标记 · 滚轮缩放 · 左键拖动 · 右键缩小 · Ctrl+左键标记")..(M.pinOverflow and "   标记过密，请放大查看" or ""))
    end)
end

function M:Install()
    if self.installed then return end
    self.installed=true
    TurtleSeamlessMapDB=TurtleSeamlessMapDB or {}
    self.settings=TurtleSeamlessMapDB
    self.settings.notes=self.settings.notes or {}
    if self.settings.quests==nil then self.settings.quests=true end
    if self.settings.detailStyle~="paper" and self.settings.detailStyle~="terrain" then self.settings.detailStyle="terrain" end
    if self.settings.overviewStyle~="continuous" and self.settings.overviewStyle~="classic" then self.settings.overviewStyle="classic" end
    if self.settings.cityMaps==nil then self.settings.cityMaps=true end
    self.tiles,self.pins,self.providerErrors,self.view={},{},{},{}
    self:IndexMaps();self:MigrateSettings();self:BuildUI();self:WorldView()
    local saved=self.settings.view
    if saved and G.Finite(saved.x) and G.Finite(saved.y) and G.Finite(saved.scale) and saved.scale>0 and saved.scale<=64 then
        self.selected=saved.selected
        self.view={x=saved.x,y=saved.y,scale=max(self.minScale,saved.scale)}
        self:ConstrainView()
    end
    if self.settings.focusAfterMigration then self:FocusMap(self.settings.focusAfterMigration);self.settings.focusAfterMigration=nil end
    ToggleWorldMap=function() M:Toggle() end
    local originalShow=WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow",function()
        if M.nativeRequested then if originalShow then originalShow() end;return end
        local explicit=M.ignoreMapEvent and not M.locating
        local file=explicit and GetMapInfo()
        local map=file and M.byFile[string.lower(file)]
        local previousIgnore=M.ignoreMapEvent
        M.ignoreMapEvent=true;WorldMapFrame:Hide();M.ignoreMapEvent=previousIgnore
        if M.locating then return end
        if explicit then
            if map then M:FocusMap(map.id) end
        elseif not M:FindPlayer() then M:WorldView() end
        M.frame:Show()
    end)
    self:InstallCompat()
end

local loader=CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("WORLD_MAP_UPDATE")
loader:RegisterEvent("CLOSE_WORLD_MAP")
loader:RegisterEvent("ZONE_CHANGED_NEW_AREA")
loader:RegisterEvent("ZONE_CHANGED")
loader:RegisterEvent("ZONE_CHANGED_INDOORS")
loader:SetScript("OnEvent",function()
    if event=="PLAYER_ENTERING_WORLD" and not M.installed then
        this:SetScript("OnUpdate",function()
            this.elapsed=(this.elapsed or 0)+arg1
            if this.elapsed>0.5 then this:SetScript("OnUpdate",nil);M:Install() end
        end)
    elseif M.installed and (event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_INDOORS" or event=="PLAYER_ENTERING_WORLD") then
        M.lastPlayer=nil;M.dirty=true
    elseif event=="CLOSE_WORLD_MAP" and M.installed then
        M.frame:Hide()
    elseif event=="WORLD_MAP_UPDATE" and M.installed and M.frame:IsShown() and not M.ignoreMapEvent then
        M.dirty=true
    end
end)

function M:UpdateStyleMenu()
    self.styleButtons[1]:SetText("详情："..(self.settings.detailStyle=="terrain" and "真实地形" or "手绘地图"))
    self.styleButtons[2]:SetText("总览："..(self.settings.overviewStyle=="classic" and "原版世界" or "连续地图"))
    self.styleButtons[3]:SetText((self.settings.detailStyle=="terrain" and "室内图：" or "城市图：")..(self.settings.cityMaps and "开启" or "关闭"))
end

SLASH_TURTLESEAMLESSMAP1="/tsm"
SlashCmdList["TURTLESEAMLESSMAP"]=function(msg)
    if not M.installed then return end
    if msg=="native" then M:ShowNative()
    elseif msg=="world" then M:WorldView();M.frame:Show()
    else M:Toggle() end
end
