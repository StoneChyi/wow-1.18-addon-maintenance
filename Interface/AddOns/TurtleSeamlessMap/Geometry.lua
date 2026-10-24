-- Pure geometry: no global client map selection is changed by these functions.
TurtleSeamlessMap = { version = "0.4.0", providers = {}, dirty = true }
local M = TurtleSeamlessMap
local G = {}
M.Geometry = G
local max, min = math.max, math.min

function G.Clamp(v, lo, hi)
    return max(lo, min(hi, v))
end

function G.Finite(v)
    return type(v) == "number" and v == v and v > -math.huge and v < math.huge
end

-- DBC coordinates run west->east and north->south in decreasing game yards.
-- Both continents share the original client's world presentation coordinates.
function G.Rect(map)
    if map.kind == "world" then return 0,0,1002,668 end
    local b = map.bounds
    local t = TurtleSeamlessMap_Layout[map.map]
    return t.x-b[1]*t.scale,t.y-b[3]*t.scale,(b[1]-b[2])*t.scale,(b[3]-b[4])*t.scale
end

function G.Project(rect, x, y)
    return rect[1] + rect[3]*x, rect[2] + rect[4]*y
end

function G.Inverse(rect, x, y)
    if rect[3] <= 0 or rect[4] <= 0 then return end
    return (x-rect[1])/rect[3], (y-rect[2])/rect[4]
end

function G.Hit(map,x,y)
    local u,v=G.Inverse(map.rect,x,y)
    if not u or u<0 or u>=1 or v<0 or v>=1 then return false end
    local mask=TurtleSeamlessMap_Focus[map.id]
    if not mask then return true end
    local col,row=math.floor(u*mask[1]),math.floor(v*mask[2])
    local digit=math.floor(col/4)+row*(mask[1]/4)+1
    local value=tonumber(string.sub(mask[3],digit,digit),16) or 0
    return math.mod(math.floor(value/(2^math.mod(col,4))),2)==1
end

function G.Screen(view, width, height, x, y)
    return width/2 + (x-view.x)*view.scale, height/2 + (y-view.y)*view.scale
end

function G.World(view, width, height, x, y)
    return view.x+(x-width/2)/view.scale, view.y+(y-height/2)/view.scale
end

function G.Zoom(view, width, height, x, y, factor, low, high)
    local wx, wy = G.World(view,width,height,x,y)
    view.scale = G.Clamp(view.scale*factor,low,high)
    view.x = wx-(x-width/2)/view.scale
    view.y = wy-(y-height/2)/view.scale
end

-- Constrain the camera, not the map artwork: the full world remains complete
-- and keeps its original aspect ratio, with no empty margin to drag into view.
function G.Constrain(view, width, height, rect)
    local halfW,halfH = width/view.scale/2,height/view.scale/2
    if halfW*2>=rect[3] then view.x=rect[1]+rect[3]/2
    else view.x=G.Clamp(view.x,rect[1]+halfW,rect[1]+rect[3]-halfW) end
    if halfH*2>=rect[4] then view.y=rect[2]+rect[4]/2
    else view.y=G.Clamp(view.y,rect[2]+halfH,rect[2]+rect[4]-halfH) end
end

-- Clip both geometry and texture coordinates. 1.12 has no modern clipping API;
-- no oversized texture/frame or invisible offscreen clickable pin is necessary.
function G.Clip(view, width, height, x, y, w, h, u, v)
    local sx, sy = G.Screen(view,width,height,x,y)
    local sw, sh = w*view.scale, h*view.scale
    if sw <= 0 or sh <= 0 then return end
    local l,t,r,b = max(0,sx),max(0,sy),min(width,sx+sw),min(height,sy+sh)
    if r-l < 0.01 or b-t < 0.01 then return end
    return l,t,r-l,b-t,(l-sx)/sw*u,(r-sx)/sw*u,(t-sy)/sh*v,(b-sy)/sh*v
end

function M:IndexMaps()
    self.byID,self.byFile,self.byName,self.byArea = {},{},{},{}
    self.maps = TurtleSeamlessMap_Data
    for _,map in ipairs(self.maps) do
        self.byID[map.id] = map
        self.byFile[string.lower(map.file)] = map
        self.byName[map.name] = map
        self.byName[map.file] = map
        if map.area > 0 and (not self.byArea[map.area] or map.kind == "surface") then
            self.byArea[map.area] = map
        end
        map.rect = {G.Rect(map)}
        -- Source page rectangles remain geographic data. The baked atlas owns
        -- outdoor artwork; no coarse source page is drawn underneath its coast.
        map.tiles={};map.backing={};map.sea={}
        if map.kind=="world" then map.atlas=TurtleSeamlessMap_Atlas.background
        elseif map.kind=="continent" then
            for _,continent in ipairs(TurtleSeamlessMap_Atlas.continents) do
                if continent.id==map.map then map.atlas=continent end
            end
        end
        local art=TurtleSeamlessMap_Presentation.cities[map.id]
        if art then
            map.tiles=art.tiles;map.artWidth=art.width;map.artHeight=art.height
            local r=map.rect
            map.artRect={r[1]+art.x/1002*r[3],r[2]+art.y/668*r[4],art.width/1002*r[3],art.height/668*r[4]}
        end
    end
    for name,id in pairs(TurtleSeamlessMap_Terrain.aliases or {}) do
        if self.byID[id] then self.byName[name]=self.byID[id] end
    end
    self.world = {0,0,1002,668}
    self.detailAreas = {}
    -- Continent source pages have wide decorative ocean margins. Navigation
    -- fits retained outdoor extents rather than exposing those margins as cards.
    for _,continent in ipairs(self.maps) do
        if continent.kind == "continent" then
            local l,t,r,b
            for _,map in ipairs(self.maps) do
                if map.kind == "surface" and not map.city and map.map == continent.map then
                    local q = map.rect
                    l,t = min(l or q[1],q[1]),min(t or q[2],q[2])
                    r,b = max(r or q[1]+q[3],q[1]+q[3]),max(b or q[2]+q[4],q[2]+q[4])
                end
            end
            continent.focusRect = {l,t,r-l,b-t}
        end
    end
    -- Native world ocean, continent backing, outdoor zones, then city detail.
    self.drawOrder = {}
    for _,map in ipairs(self.maps) do
        if map.rect then table.insert(self.drawOrder,map) end
    end
    table.sort(self.drawOrder,function(a,b)
        if a.kind == "world" then return true end
        if b.kind == "world" then return false end
        if a.kind == "continent" and b.kind ~= "continent" then return true end
        if b.kind == "continent" and a.kind ~= "continent" then return false end
        if a.city ~= b.city then return not a.city end
        return a.rect[3]*a.rect[4] > b.rect[3]*b.rect[4]
    end)
    for order,map in ipairs(self.drawOrder) do map.drawLevel=91+order end
end

function M:MapAt(x,y)
    if self.settings.detailStyle=="terrain" then
        local map=self:TerrainMapAt(x,y)
        if map and map.city and not map.cityActive then return self.byID[map.parent] end
        return map
    end
    local best
    for _,map in ipairs(self.drawOrder) do
        local r = map.rect
        if map.kind == "surface" and (not map.city or map.cityActive) and G.Hit(map,x,y) then
            -- The coarse art mask is not a precise terrain ownership claim.
            if not best or r[3]*r[4] < best.rect[3]*best.rect[4] then best=map end
        end
    end
    return best
end

-- Exactly one detail map follows the cursor. Transparent margins are not a
-- territory hit. Toolbar/menu use retains the last focus until map re-entry.
function M:ChooseDetailMap()
    if self:IsWorldView() then return end
    local x,y=self:Cursor()
    local w,h=self.canvas:GetWidth(),self.canvas:GetHeight()
    if x<0 or x>w or y<0 or y>h or (self.list and self.list:IsShown()) or (self.markerMenu and self.markerMenu:IsShown()) or (self.styleMenu and self.styleMenu:IsShown()) then
        local id=self.hoveredID
        if id==nil then id=self.selected end
        local map=self.byID[id]
        if map and map.city then
            local coverage=min(map.rect[3]*self.view.scale/w,map.rect[4]*self.view.scale/h)
            if coverage<(map.cityActive and 0.58 or 0.72) then return self.byID[map.parent] end
        end
        return map and map.kind=="surface" and map or nil
    end
    local wx,wy=G.World(self.view,w,h,x,y)
    if self.settings.detailStyle=="terrain" then
        -- Cities retain explicit near-zoom ownership; outdoor ownership
        -- comes from actual ADT AreaIDs, never the paper/exploration silhouette.
        for _,map in ipairs(self.maps) do
            if map.city and G.Hit(map,wx,wy) then
                local coverage=min(map.rect[3]*self.view.scale/w,map.rect[4]*self.view.scale/h)
                if coverage>=(map.cityActive and 0.58 or 0.72) then return map end
            end
        end
        local map=self:TerrainMapAt(wx,wy)
        if map and map.city then
            local coverage=min(map.rect[3]*self.view.scale/w,map.rect[4]*self.view.scale/h)
            if coverage<(map.cityActive and 0.58 or 0.72) then return self.byID[map.parent] end
        end
        return map
    end
    local best,city
    for _,map in ipairs(self.maps) do
        if map.kind=="surface" and G.Hit(map,wx,wy) then
            if map.city then
                local coverage=min(map.rect[3]*self.view.scale/w,map.rect[4]*self.view.scale/h)
                if coverage>=(map.cityActive and 0.58 or 0.72) then city=map end
            elseif not best or map.rect[3]*map.rect[4]<best.rect[3]*best.rect[4] then best=map end
        end
    end
    return city or best
end

function M:TerrainMapAt(x,y)
    for _,continent in ipairs(TurtleSeamlessMap_Terrain.continents) do
        local r=continent.rect
        if x>=r[1] and x<r[1]+r[3] and y>=r[2] and y<r[2]+r[4] then
            local grid=TurtleSeamlessMap_Terrain.territory[continent.id]
            local px,py=(x-grid.x)/grid.step+32,(y-grid.y)/grid.step+32
            local col,row=math.floor(px),math.floor(py)
            local code=grid.tiles[row*64+col+1]
            if code then
                local index=math.floor((py-row)*16)*16+math.floor((px-col)*16)+1
                for i=1,string.len(code),6 do
                    if index<=tonumber(string.sub(code,i,i+2),16) then
                        return self.byID[tonumber(string.sub(code,i+3,i+5),16)]
                    end
                end
            end
        end
    end
end

function M:RegisterProvider(name, callback)
    assert(type(name)=="string" and type(callback)=="function")
    self.providers[name] = callback
    self.dirty = true
end

function M:MapToWorld(id,x,y)
    local map = self.byID[id]
    if not map or not G.Finite(x) or not G.Finite(y) then return end
    if not map.rect then return end
    return G.Project(map.rect,x,y)
end

function M:UpdateVisibility()
    self.detailAreas = {}
    local target=self:ChooseDetailMap()
    self.detailTarget=target
    self.hoveredID=target and target.id or false
    local w,h = self.canvas:GetWidth(),self.canvas:GetHeight()
    for _,map in ipairs(self.drawOrder) do
        local r = map.rect
        map.visible = G.Clip(self.view,w,h,r[1],r[2],r[3],r[4],1,1) ~= nil
        local coverage = min(r[3]*self.view.scale/w,r[4]*self.view.scale/h)
        if map.kind == "world" or map.kind == "continent" then
            map.alpha = 1
        elseif map.city then
            map.cityActive = map==target and map.visible and coverage >= (map.cityActive and 0.58 or 0.72)
            map.alpha = map.cityActive and G.Clamp((coverage-0.58)/0.38,0,1) or 0
        else
            map.alpha = map==target and G.Clamp((coverage-0.10)/0.24,0,1) or 0
        end
        if map.kind == "surface" then
            map.detail = map.visible and map.alpha>=0.95 and coverage >= (map.detail and 0.34 or 0.40)
            if map.detail then self.detailAreas[map.area] = true end
        end
    end
end

-- Providers must test this BEFORE walking a zone's node table.
function M:CanShowMapPins(map)
    return map and self.detailAreas[map.area] == true
end

-- v1 stored yard coordinates and isolated 1002x668 scenes. Preserve the full
-- old records, quarantine unplaceable notes, and migrate once, never by guess.
function M:MigrateSettings()
    local s = self.settings
    if s.layoutVersion == 2 then return end
    local oldNotes,oldView = s.notes,s.view
    local function convert(x,y,scene)
        if not G.Finite(x) or not G.Finite(y) then return end
        if scene then
            local map = self.byID[scene]
            if map then
                local wx,wy = G.Project(map.rect,x/1002,y/668)
                return wx,wy,map.rect[3]/1002
            end
            return
        end
        -- The two old yard origins have disjoint outdoor extents. Require a
        -- real retained zone hit rather than inferring from empty ocean padding.
        for _,map in ipairs(self.drawOrder) do
            if map.kind == "surface" then
                local b = map.bounds
                local ox = map.map == 0 and 42000 or 0
                if x>=ox-b[1] and x<=ox-b[2] and y>=-b[3] and y<=-b[4] then
                    local t = TurtleSeamlessMap_Layout[map.map]
                    return t.x+(x-ox)*t.scale,t.y+y*t.scale,t.scale
                end
            end
        end
    end
    if table.getn(oldNotes)>0 or oldView then s.layoutV1Backup={notes=oldNotes,view=oldView} end
    s.notes,s.unplacedNotes = {},s.unplacedNotes or {}
    for _,note in ipairs(oldNotes) do
        local x,y = convert(note.x,note.y,note.scene)
        if x then table.insert(s.notes,{x=x,y=y}) else table.insert(s.unplacedNotes,note) end
    end
    s.view = nil
    if oldView then
        local x,y,k = convert(oldView.x,oldView.y,oldView.scene)
        if x and k and G.Finite(oldView.scale) and oldView.scale>0 then
            s.view={x=x,y=y,scale=G.Clamp(oldView.scale/k,0.001,64),selected=oldView.selected}
        elseif self.byID[oldView.selected] then s.focusAfterMigration=oldView.selected end
    end
    s.layoutVersion=2
    if table.getn(s.unplacedNotes)>0 then
        DEFAULT_CHAT_FRAME:AddMessage("TurtleSeamlessMap：部分旧标记暂时无法定位，已完整备份；其余标记已迁移，无需删除地图设置。")
    end
end
