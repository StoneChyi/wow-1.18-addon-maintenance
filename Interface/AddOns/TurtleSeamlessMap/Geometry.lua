-- Pure geometry: no global client map selection is changed by these functions.
TurtleSeamlessMap = { version = "0.1.0", providers = {}, dirty = true }
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
-- Separate continents use separate origins, with their own uniform yard scale.
function G.Rect(map)
    local b = map.bounds
    local offset = map.map == 0 and 42000 or 0
    return offset-b[1], -b[3], b[1]-b[2], b[3]-b[4]
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
    local left,top,right,bottom
    for _,map in ipairs(self.maps) do
        self.byID[map.id] = map
        self.byFile[string.lower(map.file)] = map
        self.byName[map.name] = map
        self.byName[map.file] = map
        if map.area > 0 and (not self.byArea[map.area] or map.kind == "surface") then
            self.byArea[map.area] = map
        end
        if map.kind == "surface" or map.kind == "continent" then
            map.rect = {G.Rect(map)}
            local r = map.rect
            left,top = min(left or r[1],r[1]),min(top or r[2],r[2])
            right,bottom = max(right or r[1]+r[3],r[1]+r[3]),max(bottom or r[2]+r[4],r[2]+r[4])
        end
    end
    self.world = {left,top,right-left,bottom-top}
    -- Large maps first, small cities / entrance maps above their parent zones.
    self.drawOrder = {}
    for _,map in ipairs(self.maps) do
        if map.rect then table.insert(self.drawOrder,map) end
    end
    table.sort(self.drawOrder,function(a,b)
        if a.kind == "continent" and b.kind ~= "continent" then return true end
        if b.kind == "continent" and a.kind ~= "continent" then return false end
        return a.rect[3]*a.rect[4] > b.rect[3]*b.rect[4]
    end)
end

function M:MapAt(x,y)
    local best
    for _,map in ipairs(self.drawOrder) do
        local r = map.rect
        if map.kind == "surface" and x>=r[1] and x<=r[1]+r[3] and y>=r[2] and y<=r[2]+r[4] then
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
    if self.scene then
        if self.scene ~= id then return end
        return x*1002,y*668
    end
    if not map.rect then return end
    return G.Project(map.rect,x,y)
end
