-- Run from repository root with Lua 5.0.3; actual panel + module, strict fonts.
local objects, methods = {}, {}
local function object(kind, name, parent)
    local o = setmetatable({kind=kind, name=name, parent=parent, regions={}, scripts={},
        points={}, shown=true, alpha=1, width=0, height=0}, {__index=methods})
    table.insert(objects, o)
    if name then _G[name]=o end
    return o
end
dofile("Tools/tests/wow112_fontstring_mock.lua")(methods, object)
function methods:SetScript(k, v) self.scripts[k]=v end
function methods:RegisterEvent(e) end
function methods:RegisterForClicks(...) end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetFrameLevel() return 1 end
function methods:SetFrameLevel(v) end
function methods:SetFrameStrata(v) end
function methods:SetBackdropColor(...) end
function methods:SetBackdropBorderColor(...) end
function methods:SetAllPoints(v) self.allpoints=v end
function methods:SetPoint(...)
    self.points=arg
    self.anchors=self.anchors or {};self.anchors[arg[1]]=arg
end
function methods:ClearAllPoints() self.points={};self.anchors={};self.allpoints=nil end
function methods:SetTexture(v) self.texture=v end
function methods:SetVertexColor(...) self.vertex=arg end
function methods:SetGradientAlpha(...) end
function methods:SetTextColor(...) self.textcolor=arg end
function methods:SetShadowOffset(x,y) self.shadow={x,y} end
function methods:SetJustifyV(v) self.justifyV=v end
function methods:SetTexCoord(...) end
function methods:GetFont() return unpack(self.font or {}) end
function methods:GetObjectType() return self.kind end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetChildren() return end
function methods:GetStringWidth() return string.len(self.text or "")*5 end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:Show() self.shown=true end
function methods:Hide()
    self.shown=false
    if self.scripts.OnHide then self.scripts.OnHide() end
end
function methods:CreateTexture(name)
    local o=object("Texture",name,self);table.insert(self.regions,o);return o
end
local createFont=methods.CreateFontString
function methods:CreateFontString(name, layer, template)
    local o=createFont(self,name,layer,template);table.insert(self.regions,o);return o
end
function CreateFrame(kind,name,parent,template) return object(kind,name,parent) end
UIParent=object("Frame","UIParent")
SlashCmdList={};UISpecialFrames={};STANDARD_TEXT_FONT="missing-configured-font.ttf"
failedFontPaths[STANDARD_TEXT_FONT]=true -- Exercise template fallback for every run.
local realm, player="Realm", "Player"
function GetRealmName() return realm end
function UnitName() return player end
function getglobal(name) return _G[name] end
local now=1000
function GetTime() return now end
function GetBindLocation() return "旅店" end
local bags, inventory, used, messages = {}, {}, {}, {}
local function link(id) return "|Hitem:"..id..":0:0:0|h[item]|h" end
function GetContainerNumSlots(bag) return 8 end
function GetContainerItemLink(bag,slot)
    local i=bags[bag] and bags[bag][slot];return i and link(i.id)
end
function GetContainerItemInfo(bag,slot)
    local i=bags[bag] and bags[bag][slot];if i then return "icon"..i.id,1,i.locked end
end
function GetContainerItemCooldown(bag,slot)
    local i=bags[bag][slot];return i.start or 0,i.duration or 0,i.enabled==nil and 1 or i.enabled
end
function GetInventoryItemLink(unit,slot) return inventory[slot] and link(inventory[slot].id) end
function GetInventoryItemTexture(unit,slot) error("bar must use local line art") end
function GetInventoryItemCooldown(unit,slot)
    local i=inventory[slot];return i.start or 0,i.duration or 0,i.enabled==nil and 1 or i.enabled
end
function UseContainerItem(bag,slot) table.insert(used,{bag=bag,slot=slot,id=bags[bag][slot].id}) end
function UseInventoryItem(slot) table.insert(used,{inventory=slot,id=inventory[slot].id}) end
UIErrorsFrame={AddMessage=function(self,v) table.insert(messages,v) end}
GameTooltip=object("Frame","GameTooltip")
function GameTooltip:SetOwner(owner,anchor) end
function GameTooltip:ClearLines() self.lines={} end
function GameTooltip:AddLine(v) table.insert(self.lines,v) end
function GameTooltip:SetBagItem(bag,slot) self.bag=bag;self.slot=slot end
function GameTooltip:SetInventoryItem(unit,slot) self.inventory=slot end
local entries={}
function UIDropDownMenu_Initialize(menu,func,style) menu.initialize=func end
function UIDropDownMenu_AddButton(info,level) table.insert(entries,info) end
function ToggleDropDownMenu(level,value,menu,anchor,x,y)
    UIDROPDOWNMENU_OPEN_MENU=menu;entries={};menu.initialize()
end
function CloseDropDownMenus() UIDROPDOWNMENU_OPEN_MENU=nil end
local function invoke(frame,script,value)
    this=frame;arg1=value;assert(frame.scripts[script],script);frame.scripts[script]()
end
local checks=0
local function check(ok,label) assert(ok,label);checks=checks+1 end

DimInfo_Config={['Realm-Player']={OrderLeft={'diminfo_Time'},OrderRight={'diminfo_Gold'},
    Hidden={diminfo_Bag=true},FontSize=15}}
dofile("Interface/AddOns/diminfo/panel.lua")
object("Button","diminfo_Gold",UIParent)
dofile("Interface/AddOns/diminfo/Modules/Teleport.lua")
local b=diminfo_Teleport
local function cfg() return diminfopanel.GetCharacterConfig() end
local function label() return b.regions[1].text end
local function click(v) invoke(b,"OnClick",v or "LeftButton") end
invoke(b,"OnEvent")
check(label()=="炉石 未携带","initial missing item")
check(table.getn(cfg().OrderRight)==2 and cfg().OrderRight[1]=='diminfo_Gold',"migrate old order")
cfg();cfg();check(table.getn(cfg().OrderRight)==2,"migration idempotent")
check(cfg().Hidden.diminfo_Bag and cfg().FontSize==15,"preserve old settings")
click();check(table.getn(used)==0 and table.getn(messages)==1,"missing item cannot use unrelated slot")
bags[0]={[1]={id=6948},[2]={id=41915},[3]={id=61000},[4]={id=5976}}
invoke(b,"OnEvent");check(label()=="炉石 就绪","bag item ready")
click("RightButton");check(table.getn(entries)==4,"all four choices")
entries[2].func();check(cfg().TeleportItem==41915 and table.getn(used)==0,"menu selects without use")
click();check(used[1].id==41915,"left uses selection")
bags[0][2]={id=12345};bags[3]={[7]={id=41915}}
click();check(used[2].bag==3 and used[2].slot==7,"re-resolve moved item")
bags[3][7]=nil;click();check(table.getn(used)==2 and label()=="翠绿符文 未携带","removed item no fallback")
click("RightButton");check(entries[2].disabled==1,"missing choice disabled")
entries[3].func();bags[0][3].start=now;bags[0][3].duration=125
invoke(b,"OnEvent");check(label()=="时光符文 2分05秒","bag cooldown text")
click();check(table.getn(used)==2,"cooldown blocked")
now=now+126;invoke(b,"OnUpdate",1);check(label()=="时光符文 就绪","cooldown expires")
bags[0][3].locked=true;click();check(table.getn(used)==2,"locked item blocked")
bags[0][3].locked=nil;bags[0][3].enabled=0;click();check(table.getn(used)==2,"disabled item blocked")
bags[0][3].enabled=1;click("RightButton");entries[4].func()
check(label()=="公会战袍 需装备","bag tabard equip hint")
click();check(used[3].id==5976 and used[3].bag==0,"equip tabard via native bag use")
inventory[19]={id=5976};bags[0][4]=nil
click();check(used[4].inventory==19,"equipped tabard used")
inventory[19].start=now;inventory[19].duration=30
invoke(b,"OnEvent");check(label()=="公会战袍 30秒","inventory cooldown")
invoke(b,"OnEnter");check(GameTooltip.inventory==19,"equipped tooltip")
click("RightButton");check(not GameTooltip:IsShown(),"menu hides tooltip")
entries[1].func();invoke(b,"OnEnter")
check(GameTooltip.lines[2]=="炉石绑定：旅店","hearth bind tooltip")
check(b.regions[1].font[1]~='missing-configured-font.ttf',"font template survives SetFont failure")
cfg().OrderLeft={'diminfo_Teleport'};cfg().OrderRight={'diminfo_Gold'}
cfg();check(table.getn(cfg().OrderRight)==1,"keep module moved to left")
diminfopanel.ReanchorModules();check(b.regions[1].points[1]=='RIGHT' and b.regions[1].points[2]~=b,"left text anchors independently")
cfg().Hidden.diminfo_Teleport=true;diminfopanel.ApplyVisibility()
check(not b:IsShown(),"hide through panel")
cfg().Hidden.diminfo_Teleport=nil;diminfopanel.ApplyVisibility();check(b:IsShown(),"show through panel")
diminfopanel.ApplyFadeAlpha(.15);check(b:GetAlpha()==.15,"fade integration")
player='Other';invoke(b,"OnEvent");check(label()=="炉石 就绪" and cfg().TeleportItem==nil,"per-character selection")
player='Player';cfg().TeleportItem=987654;invoke(b,"OnEvent");check(label()=="炉石 就绪","invalid saved selection")
cfg().TeleportItem=5976;diminfopanel.ResetAllModules()
check(cfg().TeleportItem==nil and label()=="炉石 就绪" and b:IsShown(),"reset settings")
check(diminfopanel.mouse==false,"bar background stays click-through")
-- Keep the icon attached to the label across sorting, resizing and refreshes.
local text, icon=b.regions[1], b.regions[2]
local function aligned()
    local _, size=text:GetFont()
    return icon.points[1]=='RIGHT' and icon.points[2]==text and icon.points[3]=='LEFT'
        and icon.points[4]==-4 and icon.points[5]==-size/7
end
check(aligned(),"icon follows label with baseline correction")
for _, size in ipairs({10,14,20}) do
    failedFontPaths[STANDARD_TEXT_FONT]=nil
    diminfopanel.UpdateFontSize(size)
    invoke(b,"OnEvent")
    check(aligned() and text.font[2]==size,"font size preserves icon alignment")
end
cfg().OrderLeft={'diminfo_Teleport'};cfg().OrderRight={'diminfo_Gold'}
diminfopanel.ReanchorModules()
check(aligned() and text.points[1]=='RIGHT' and text.points[2]~=b,"left sort preserves independent text")
cfg().OrderLeft={};cfg().OrderRight={'diminfo_Teleport','diminfo_Gold'}
diminfopanel.ReanchorModules()
check(aligned() and text.points[1]=='LEFT' and text.points[4]==cfg().spacing/2+b.IconPadding,"right sort reserves scaled icon spacing")
-- Each choice keeps its own glyph even when the item leaves the bags.
for _, item in ipairs({{6948,'hearth'},{41915,'verdant'},{61000,'time'},{5976,'guild'}}) do
    cfg().TeleportItem=item[1]
    invoke(b,"OnEvent")
    check(icon.texture=="Interface\\AddOns\\diminfo\\Media\\Teleport\\"..item[2]
        and aligned(),"local glyph identity and alignment")
end
cfg().TeleportItem=6948;invoke(b,"OnEvent")
check(icon.vertex[1]==.3 and icon.vertex[2]==1 and icon.vertex[3]==.6
    and text.textcolor[1]==icon.vertex[1] and text.textcolor[2]==icon.vertex[2]
    and text.textcolor[3]==icon.vertex[3],"ready icon and label share tint")
bags[0][1]=nil;invoke(b,"OnEvent")
check(icon.vertex[1]==.7 and icon.vertex[2]==.7 and icon.vertex[3]==.7
    and text.textcolor[1]==.7 and icon.texture=="Interface\\AddOns\\diminfo\\Media\\Teleport\\hearth",
    "missing item keeps glyph and shares disabled tint")
-- Resolve full rectangles rather than just checking the last SetPoint arguments.
-- Font height deliberately alternates odd/even with size, exposing fixed hit boxes.
local fractions={LEFT={0,.5},RIGHT={1,.5},CENTER={.5,.5},TOPLEFT={0,1},
    TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0},TOP={.5,1},BOTTOM={.5,0}}
local function rectangle(o,cache,visiting)
    if cache[o] then return cache[o] end
    assert(not visiting[o], 'circular UI anchors: '..tostring(o.name));visiting[o]=true
    local result
    if o==UIParent then result={0,0,1920,1080}
    elseif o.allpoints then result=rectangle(o.allpoints,cache,visiting)
    else
        local constraints={}
        for point,p in pairs(o.anchors or {}) do
            local r=rectangle(p[2],cache,visiting)
            local a,t=fractions[point],fractions[p[3]]
            table.insert(constraints,{a[1],r[1]+t[1]*r[3]+p[4],a[2],r[2]+t[2]*r[4]+p[5]})
        end
        local width=o.kind=='FontString' and o:GetStringWidth() or o.width
        local height=o.kind=='FontString' and o.font[2]+3 or o.height
        local function axis(index,extent)
            local first=constraints[1]
            if not first then return 0,extent end
            for _, c in ipairs(constraints) do
                if c[index]~=first[index] then
                    extent=(c[index+1]-first[index+1])/(c[index]-first[index])
                    break
                end
            end
            assert(extent>=0,'negative UI extent')
            return first[index+1]-first[index]*extent,extent
        end
        local x,w=axis(1,width);local y,h=axis(3,height)
        result={x,y,w,h}
    end
    visiting[o]=nil;cache[o]=result;return result
end
local function rect(o,cache) return rectangle(o,cache or {},{}) end
local function centerY(r) return r[2]+r[4]/2 end
local function near(a,b) return math.abs(a-b)<.0001 end
local function source(file)
    local f=assert(io.open('Interface/AddOns/diminfo/Modules/'..file..'.lua','rb'))
    local data=f:read('*a');f:close();return (string.gsub(data,'^\239\187\191',''))
end
-- Execute the actual bar-widget constructors, without unrelated timers/tooltips.
for _, file in ipairs({'Positions','Friend','Time','RaidCD','Quest','Performance','Loaddll','Durability','Bags'}) do
    local data=source(file)
    local start=assert(string.find(data,'local [%w_]+ = CreateFrame%("Button", "diminfo_'))
    local _,finish=string.find(data,':SetAllPoints%(Text%)',start)
    assert(loadstring(string.sub(data,start,assert(finish))))()
end
floor=math.floor;COPPER_PER_SILVER=100;SILVER_PER_GOLD=100
function GetMoney() return 123456 end
assert(loadstring(source('Gold')))()
event='PLAYER_LOGIN';invoke(diminfo_Gold,'OnEvent')
local left={'diminfo_Performance','diminfo_RaidCD','diminfo_Quest','diminfo_Friend','diminfo_Time'}
local right={'diminfo_Loaddll','diminfo_Durability','diminfo_Bag','diminfo_Gold'}
local ids={6948,41915,61000,5976}
local layouts=0
for size=10,20 do
    for placement=1,6 do
        for hidden=0,1 do
            for _, id in ipairs(ids) do
                local c=cfg();c.OrderLeft={unpack(left)};c.OrderRight={unpack(right)}
                c.Hidden={};if hidden==1 then c.Hidden.diminfo_pos=true end
                local order=placement<=3 and c.OrderRight or c.OrderLeft
                local where=math.mod(placement-1,3)
                table.insert(order,where==0 and 1 or where==1 and 3 or table.getn(order)+1,'diminfo_Teleport')
                c.TeleportItem=id;c.spacing=1+(size-10)*4
                invoke(b,'OnEvent');diminfopanel.UpdateFontSize(size)
                local cache={};local baseline=centerY(rect(diminfopanel,cache));local ok=true
                for _, chain in ipairs({c.OrderLeft,c.OrderRight}) do
                    for _, name in ipairs(chain) do
                        local f=_G[name]
                        for _, region in ipairs(f.regions) do
                            if region.kind=='FontString' then
                                ok=ok and near(centerY(rect(region,cache)),baseline) and region.font[2]==size
                            elseif region.kind=='Texture' and f~=b then
                                ok=ok and near(centerY(rect(region,cache)),baseline)
                            end
                        end
                    end
                end
                local tr,br,ir=rect(text,cache),rect(b,cache),rect(icon,cache)
                ok=ok and near(centerY(br),baseline) and near(br[4],tr[4])
                    and near(br[3],tr[3]+b.IconPadding) and near(ir[3],size+2)
                    and near(tr[1]-(ir[1]+ir[3]),4)
                    and near(centerY(ir)+size/7,baseline)
                    and text.shadow[1]==0 and text.shadow[2]==0 and text.justifyV=='MIDDLE'
                -- Centered 24/32 ink fits inside the text-height click target.
                ok=ok and centerY(ir)-ir[4]*.375>=br[2]-.001
                    and centerY(ir)+ir[4]*.375<=br[2]+br[4]+.001
                -- Both chains retain the configured gaps, including around the icon.
                for _, chain in ipairs({c.OrderLeft,c.OrderRight}) do
                    for i=2,table.getn(chain) do
                        local a,z=rect(_G[chain[i-1]],cache),rect(_G[chain[i]],cache)
                        ok=ok and near(z[1]-(a[1]+a[3]),c.spacing)
                    end
                end
                for _, scale in ipairs({.64,1,1.333333}) do
                    ok=ok and near(centerY(tr)*scale,baseline*scale)
                end
                check(ok,'full bar geometry: font '..size..', placement '..placement..', center hidden '..hidden..', item '..id)
                layouts=layouts+1
            end
        end
    end
end
print('diminfo teleport: '..checks..' checks passed, including '..layouts..' full-bar geometry cases (Lua '.._VERSION..')')
