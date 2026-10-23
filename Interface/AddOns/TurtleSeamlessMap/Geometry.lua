-- Pure geometry: no global client map selection is changed by these functions.
TurtleSeamlessMap = { version = "0.2.0", providers = {}, dirty = true }
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
end

function M:MapAt(x,y)
    local best
    for _,map in ipairs(self.drawOrder) do
        local r = map.rect
        if map.kind == "surface" and (not map.city or map.cityActive) and x>=r[1] and x<=r[1]+r[3] and y>=r[2] and y<=r[2]+r[4] then
            -- This is a bounding-box lookup, not a terrain ownership claim.
            if not best or r[3]*r[4] < best.rect[3]*best.rect[4] then best=map end
        end
    end
    return best
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
    local w,h = self.canvas:GetWidth(),self.canvas:GetHeight()
    for _,map in ipairs(self.drawOrder) do
        local r = map.rect
        map.visible = G.Clip(self.view,w,h,r[1],r[2],r[3],r[4],1,1) ~= nil
        local coverage = min(r[3]*self.view.scale/w,r[4]*self.view.scale/h)
        if map.kind == "world" or map.kind == "continent" then
            map.alpha = 1
        elseif map.city then
            local margin = map.cityActive and 0.25 or 0.05
            local near = self.view.x>=r[1]-r[3]*margin and self.view.x<=r[1]+r[3]*(1+margin)
                and self.view.y>=r[2]-r[4]*margin and self.view.y<=r[2]+r[4]*(1+margin)
            local focus = self.zoomFocus
            if not near and focus and focus.x>=r[1] and focus.x<=r[1]+r[3] and focus.y>=r[2] and focus.y<=r[2]+r[4] then
                local sx,sy = G.Screen(self.view,w,h,focus.x,focus.y)
                near = sx>=0 and sx<=w and sy>=0 and sy<=h
            end
            map.cityActive = map.visible and near and coverage >= (map.cityActive and 0.58 or 0.72)
            map.alpha = map.cityActive and G.Clamp((coverage-0.58)/0.38,0,1) or 0
        else
            map.alpha = G.Clamp((coverage-0.10)/0.24,0,1)
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
