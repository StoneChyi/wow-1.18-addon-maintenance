-- Baked geographic artwork is independent from the cursor's node territory.
-- Visit visible cells only; each scene declares its interior and gutter size.
local M = TurtleSeamlessMap
local G = M.Geometry
local ART = "Interface\\AddOns\\TurtleSeamlessMap\\Art\\"
local floor,ceil,min,max = math.floor,math.ceil,math.min,math.max
local LIMIT = 256

local function Window(view,w,h,rect,density,cols,rows,inner)
    local cell=inner/density
    local l=max(0,floor((view.x-w/view.scale/2-rect[1])/cell))
    local t=max(0,floor((view.y-h/view.scale/2-rect[2])/cell))
    local r=min(cols-1,ceil((view.x+w/view.scale/2-rect[1])/cell)-1)
    local b=min(rows-1,ceil((view.y+h/view.scale/2-rect[2])/cell)-1)
    return l,t,r,b,cell
end

function M:DrawAtlas(map,data,background)
    local w,h=self.canvas:GetWidth(),self.canvas:GetHeight()
    local inner=data.inner or TurtleSeamlessMap_Atlas.inner
    local gutter=data.gutter or 1
    local levels=background and {data.level} or data.levels
    local choice=table.getn(levels)
    for i,level in ipairs(levels) do
        if level.density>=self.view.scale then choice=i;break end
    end
    local rect=data.rect
    while choice>1 do
        local q=levels[choice]
        local l,t,r,b=Window(self.view,w,h,rect,q.density,q.cols,q.rows,inner)
        if (r-l+1)*(b-t+1)<=LIMIT then break end
        choice=choice-1
    end
    if not map.artFrame then
        map.artFrame=CreateFrame("Frame",nil,self.art)
        map.artFrame:SetAllPoints(self.canvas);map.artFrame:SetFrameLevel(map.drawLevel)
        map.textures={};map.texturePool={}
    end
    map.atlasPool=map.atlasPool or {}
    map.atlasVisits=0
    -- SetTexture on 1.12 reports failure, not asynchronous readiness. If any
    -- asset fails, retry this scene at a complete lower resolution this pass.
    -- Physical asset completeness is checked offline before deployment.
    while choice>=1 do
        local level=levels[choice]
        local prefix=level.prefix or (background and "v4_paper" or "v4_c"..data.id.."_"..level.density)
        local l,t,r,b,cell=Window(self.view,w,h,rect,level.density,level.cols,level.rows,inner)
        local used,failed=0,false
        local start=self.tileUsed
        for row=t,b do
            for col=l,r do
                map.atlasVisits=map.atlasVisits+1
                if level.tiles[row*level.cols+col+1] then
                    local x,y=rect[1]+col*cell,rect[2]+row*cell
                    local tw,th=min(cell,rect[1]+rect[3]-x),min(cell,rect[2]+rect[4]-y)
                    -- Full edge cells are represented by a partial UV, never
                    -- stretched. Clip returns normalized source cell fractions.
                    local a,c,d,e,u,v,s,z=G.Clip(self.view,w,h,x,y,tw,th,tw/cell,th/cell)
                    if a then
                        used=used+1
                        assert(used<=LIMIT,"Atlas viewport exceeded bounded pool")
                        local texture=map.atlasPool[used]
                        if not texture then
                            texture=map.artFrame:CreateTexture(nil,"ARTWORK")
                            texture.atlasSlot=true;map.atlasPool[used]=texture;table.insert(map.textures,texture)
                        end
                        local path=ART..prefix.."_"..col.."_"..row
                        if texture.path~=path then
                            if texture:SetTexture(path) then texture.path=path
                            else texture.path=nil;failed=true end
                        end
                        if texture.path then
                            texture:ClearAllPoints();texture:SetPoint("TOPLEFT",self.canvas,"TOPLEFT",a,-c)
                            texture:SetWidth(d);texture:SetHeight(e)
                            texture:SetTexCoord((gutter+u*inner)/256,(gutter+v*inner)/256,(gutter+s*inner)/256,(gutter+z*inner)/256)
                            texture:SetAlpha(map.city and map.alpha or 1);texture:Show();texture.active=true
                            texture.paintPass=self.paintPass
                            self.tileUsed=self.tileUsed+1;self.tiles[self.tileUsed]=texture
                        end
                    end
                end
            end
        end
        map.atlasLevel=level.density
        if not failed then break end
        for i=start+1,self.tileUsed do
            local texture=self.tiles[i];texture:Hide();texture.active=false;texture.paintPass=nil
            texture:SetTexture(nil);texture.path=nil;self.tiles[i]=nil
        end
        self.tileUsed=start;choice=choice-1
    end
end
