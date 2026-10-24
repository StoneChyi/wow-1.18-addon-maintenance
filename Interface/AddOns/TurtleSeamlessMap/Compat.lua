-- Adapters read existing addon data; they never reparent original map frames,
-- replace pfQuest node tables, or rebuild its tracker/route during map movement.
local M=TurtleSeamlessMap
local G=M.Geometry
local types={"DUNGEON","RAID","WORLDBOSS","BOAT","ZEPPELIN","TRAM"}
local labels={DUNGEON="地下城",RAID="团队副本",WORLDBOSS="世界首领",BOAT="船",ZEPPELIN="飞艇",TRAM="地铁"}
local textures={DUNGEON="dungeon",RAID="raid",WORLDBOSS="worldboss",BOAT="boat",ZEPPELIN="zepp",TRAM="tram"}

local function ModernMap(data)
    local loc=ModernMapMarkers_Locale
    local name=loc and loc:GetLocalizedZoneName(data.zoneName) or data.zoneName
    return M.byName[name] or M.byName[data.zoneName]
end

local function ModernEnter(p)
    local data=p.data
    local loc=ModernMapMarkers_Locale
    GameTooltip:SetOwner(p,"ANCHOR_RIGHT")
    GameTooltip:SetText(loc and loc:GetLocalizedMarkerName(data.name) or data.name)
    if data.description then GameTooltip:AddLine(loc and loc:GetLocalizedMarkerName(data.description) or data.description,1,1,1) end
    if data.atlasID then GameTooltip:AddLine("点击打开 Atlas",0.6,0.8,1) end
    GameTooltip:Show()
end

local function ModernClick(p)
    local core=ModernMapMarkersCore
    if core and core.OnMarkerClick then
        local data=p.data
        -- Pass a temporary descriptor, not a shared pooled map marker frame.
        core:OnMarkerClick({atlasID=data.atlasID,zoneName=data.zoneName,name=data.name})
        if data.atlasID and AtlasFrame and AtlasFrame:IsShown() then M.frame:Hide() end
    end
end

local function HideTooltip() GameTooltip:Hide() end

local function DrawModern(self)
    local core=ModernMapMarkersCore
    if not core or not core.Data then return end
    for _,data in ipairs(core.Data) do
        local on=core.filters[data.type]
        if on and (data.type=="BOAT" or data.type=="ZEPPELIN" or data.type=="TRAM") then
            local f=core.filters.FACTION
            if f~="ALL" and data.description~="Neutral" and data.description~=f then on=false end
        end
        if on then
            local map=ModernMap(data)
            local x,y
            if self:CanShowMapPins(map) then x,y=self:MapToWorld(map.id,data.x,data.y) end
            local texture=textures[data.type]
            if texture then self:AddPin("mmm"..data.id,x,y,"Interface\\AddOns\\ModernMapMarkers\\Textures\\"..texture,24,ModernEnter,HideTooltip,ModernClick,data,map and map.id) end
        end
    end
end

function M:ToggleMarkerMenu()
    if self.markerMenu then
        if self.markerMenu:IsShown() then self.markerMenu:Hide() else self.markerMenu:Show();self:UpdateMarkerMenu() end
        return
    end
    local menu=CreateFrame("Frame",nil,self.frame)
    self.markerMenu=menu
    menu:SetWidth(180);menu:SetHeight(224);menu:SetFrameLevel(180)
    menu:SetPoint("TOPLEFT",self.canvas,"TOPLEFT",12,-8)
    menu:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    menu:SetBackdropColor(0.05,0.05,0.05,1);menu:EnableMouse(true)
    self.markerButtons={}
    for i,key in ipairs(types) do
        local b=CreateFrame("Button",nil,menu,"UIPanelButtonTemplate")
        b:SetWidth(152);b:SetHeight(24);b:SetPoint("TOPLEFT",menu,"TOPLEFT",14,-12-(i-1)*26)
        b.filterKey=key
        b:SetScript("OnClick",function()
            local core=ModernMapMarkersCore
            if core and ModernMapMarkers_SetFilter then ModernMapMarkers_SetFilter(this.filterKey,not core.filters[this.filterKey]) end
            M.dirty=true;M:UpdateMarkerMenu()
        end)
        self.markerButtons[i]=b
    end
    local faction=CreateFrame("Button",nil,menu,"UIPanelButtonTemplate")
    faction:SetWidth(152);faction:SetHeight(24);faction:SetPoint("TOPLEFT",menu,"TOPLEFT",14,-174)
    faction:SetScript("OnClick",function()
        local core=ModernMapMarkersCore
        if core and ModernMapMarkers_SetFactionFilter then
            local nextFaction={ALL="Alliance",Alliance="Horde",Horde="ALL"}
            ModernMapMarkers_SetFactionFilter(nextFaction[core.filters.FACTION] or "ALL")
        end
        M.dirty=true;M:UpdateMarkerMenu()
    end)
    self.factionButton=faction
    self:UpdateMarkerMenu()
end

function M:UpdateMarkerMenu()
    local core=ModernMapMarkersCore
    for _,b in ipairs(self.markerButtons) do
        b:SetText((core and core.filters[b.filterKey] and "[开] " or "[关] ")..labels[b.filterKey])
    end
    local f=core and core.filters.FACTION or "ALL"
    self.factionButton:SetText("交通阵营："..({ALL="全部",Alliance="联盟",Horde="部落"})[f])
end

local function QuestEnter(p)
    local meta=p.data.meta
    GameTooltip:SetOwner(p,"ANCHOR_RIGHT")
    GameTooltip:SetText(meta.spawn or meta.title or "任务标记",0.3,1,0.8)
    if pfMap and pfMap.ShowTooltip then
        for _,entry in pairs(p.data.node) do pfMap:ShowTooltip(entry,GameTooltip,entry.spawnalias) end
    end
    GameTooltip:AddLine("点击：原任务操作 · Shift+点击：移除标记",0.6,0.6,0.6)
    GameTooltip:Show()
end

local function QuestClick(p)
    if p.data.meta.func then p.data.meta.func()
    elseif pfMap and pfMap.NodeClick then pfMap:NodeClick() end
    M.dirty=true
end

local questFields={"spawn","spawnid","spawnalias","summonsrc","spawntype","respawn","level","questid","texture","vertex","title","func","cluster","description","priority","quest","qlvl","itemreq","arrow","icon","fade_range"}
local function QuestLayer(meta)
    if meta.layer then return meta.layer end
    if meta.cluster then return 9 end
    if meta.texture and string.find(meta.texture,"complete_c",1,true) then return 4 end
    return 1
end

local function DrawQuests(self)
    self.questNodesVisited=0
    if not self.settings.quests or not pfMap or not pfMap.nodes then return end
    local config=pfQuest_config or {}
    for addon,areas in pairs(pfMap.nodes) do
        for area,nodes in pairs(areas) do
            local map=self.byArea[tonumber(area)]
            if self:CanShowMapPins(map) then
                -- Cull a zone before walking its potentially large node table.
                local visible=map.visible
                if visible then
                    for coords,node in pairs(nodes) do
                        self.questNodesVisited=self.questNodesVisited+1
                        local _,_,xs,ys=string.find(coords,"^([^|]+)|([^|]+)$")
                        local x,y=tonumber(xs),tonumber(ys)
                        local chosen,chosenTitle
                        for title,meta in pairs(node) do
                            if not chosen or QuestLayer(meta)>QuestLayer(chosen) then chosen,chosenTitle=meta,title end
                        end
                        if chosen and x and y and not (config.showcluster=="0" and chosen.cluster) and
                            not (config.showspawn=="0" and addon=="PFQUEST" and not chosen.texture) and
                            not (chosen.cluster and IsControlKeyDown()) then
                            local wx,wy=self:MapToWorld(map.id,x/100,y/100)
                            local texture=chosen.texture or chosen.icon or (pfQuest and pfQuest.icons and pfQuest.icons[chosenTitle]) or "Interface\\AddOns\\pfQuest\\img\\node"
                            local p=self:AddPin("pf:"..addon..":"..area..":"..coords,wx,wy,texture,chosen.cluster and 18 or 14,QuestEnter,HideTooltip,QuestClick,{meta=chosen,node=node},map.id)
                            if p then
                                for _,key in ipairs(questFields) do p[key]=chosen[key] end
                                p.title=chosenTitle;p.node=node;p.layer=QuestLayer(chosen)
                                p.color=config.spawncolors=="1" and (chosen.spawn or chosenTitle) or chosenTitle
                                if chosen.vertex then p.tex:SetVertexColor(unpack(chosen.vertex)) end
                            end
                        end
                    end
                end
            end
        end
    end
end

function M:InstallCompat()
    local function ScopedCall(fn,a,b)
        local previous=M.ignoreMapEvent;M.ignoreMapEvent=true
        local ok,result=pcall(fn,a,b)
        M.ignoreMapEvent=previous
        if not ok then error(result) end
        return result
    end
    if ModernMapMarkersCore then
        ModernMapMarkersCore:BuildData()
        self:RegisterProvider("ModernMapMarkers",DrawModern)
        local original=ModernMapMarkers_FindMarker
        if original then
            ModernMapMarkers_FindMarker=function(index)
                ScopedCall(original,index)
                local data=ModernMapMarkersCore.Data[index]
                local map=data and ModernMap(data)
                if map then M:FocusMap(map.id);M.frame:Show() end
            end
        end
    end
    if pfMap then
        self:RegisterProvider("pfQuest",DrawQuests)
        local original=pfMap.ShowMapID
        if original then
            pfMap.ShowMapID=function(self,id)
                ScopedCall(original,self,id)
                local map=M.byArea[tonumber(id)]
                if map then M:FocusMap(map.id);M.frame:Show() end
            end
        end
    end
    -- Frame method calls from other addons are redirected by Core's OnShow.
    -- SetMapZoom is also used by background data readers. It is not proof of
    -- a user navigation. Known explicit clicks above call FocusMap themselves.
    local originalSetMapZoom=SetMapZoom
    SetMapZoom=function(continent,zone)
        if zone==nil then originalSetMapZoom(continent) else originalSetMapZoom(continent,zone) end
        if M.frame:IsShown() then M.dirty=true end
    end
end
