-- Contract mock for production QianKunBag. Does not simulate the client renderer.
now = 0; calls = {}; messages = {}; bagSizes = {[0]=4,[1]=2,[2]=0,[3]=0,[4]=0}
bags = {[0]={},[1]={},[2]={},[3]={},[4]={}}
info = {
    [100]={name="药水",quality=1,itemType="消耗品",subtype="消耗品",stack=20},
    [200]={name="头盔",quality=2,itemType="护甲",subtype="板甲",stack=1},
    [300]={name="配方",quality=1,itemType="配方",subtype="炼金术",stack=1},
    [400]={name="矿石",quality=1,itemType="商品",subtype="金属和矿石",stack=20},
    [500]={name="任务信",quality=1,itemType="任务",subtype="任务",stack=1},
    [600]={name="破布",quality=0,itemType="杂物",subtype="垃圾",stack=1},
}
function item(id, count, locked, suffix)
    return {id=id,count=count or 1,locked=locked,suffix=suffix or 0}
end
bags[0][1]=item(100,2); bags[0][2]=item(200); bags[0][4]=item(300); bags[1][1]=item(400,5)
function record(name, ...)
    calls[name] = calls[name] or {}; table.insert(calls[name], {...})
end
function count(name) return calls[name] and table.getn(calls[name]) or 0 end
function GetTime() return now end
function debugprofilestop() return now*1000 end
function GetContainerNumSlots(bag) assert(bag>=0 and bag<=4); record('size',bag); return bagSizes[bag] end
function GetContainerItemInfo(bag,slot)
    record('info',bag,slot)
    local value=bags[bag][slot]
    if not value then return nil end
    return 'icon'..value.id,value.count,value.locked,1,value.readable
end
function GetContainerItemLink(bag,slot)
    local value=bags[bag][slot]; if not value or value.noLink then return nil end
    return '|Hitem:'..value.id..':0:'..value.suffix..':0|h['..(info[value.id] and info[value.id].name or '未知')..']|h'
end
function GetItemInfo(key)
    record('metadata',key)
    local _,_,id=string.find(key,'item:(%d+)')
    local value=info[tonumber(id)]
    if not value or value.missing then return nil end
    return value.name,key,value.quality,1,value.itemType,value.subtype,value.stack,'','icon'..id
end
function GetBagName(bag) return bag==0 and '背包' or '专业包' end
function GetContainerItemCooldown(bag,slot)
    record('cooldownRead',bag,slot)
    local value=bags[bag][slot]
    return value and value.start or 0,value and value.duration or 0,value and value.enabled or 0
end
function CursorHasItem() return cursor end
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return control end
function IsAltKeyDown() return alt end
function PickupContainerItem(bag,slot) record('pickup',bag,slot) end
function UseContainerItem(bag,slot) record('use',bag,slot) end
function ResetCursor() record('resetCursor') end
function CursorUpdate() assert(this.qRecord, 'CursorUpdate must receive the actual hovered button'); record('cursorUpdate',this) end
function getglobal(name) return _G[name] end
function OpenBackpack() record('originalOpen') end
function ToggleBackpack() record('originalToggle') end
function OpenAllBags() record('originalAll') end
Bagshui = { sentinel=true }; BagshuiData={untouched=true}
originalOpen,originalToggle,originalAll=OpenBackpack,ToggleBackpack,OpenAllBags
SlashCmdList={}; UISpecialFrames={}; DEFAULT_CHAT_FRAME={AddMessage=function(_,message) table.insert(messages,message) end}
ITEM_QUALITY_COLORS={[2]={r=0.1,g=1,b=0.1},[3]={r=0.1,g=0.1,b=1}}

methods={}
function newObject(kind,name,parent)
    local object=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={},level=1,children={}}, {__index=methods})
    if name then assert(not _G[name], 'duplicate frame name: '..name); _G[name]=object end
    if parent then table.insert(parent.children,object) end
    return object
end
function methods:SetWidth(value) self.width=value end
function methods:SetHeight(value) self.height=value end
function methods:GetHeight() return self.height or 768 end
function methods:SetPoint(...) self.point={...}; record('point',self) end
function methods:ClearAllPoints() self.point=nil end
function methods:SetAllPoints(parent) self.allPoints=parent end
function methods:SetBackdrop(value) assert(value.bgFile and value.edgeFile); self.backdrop=value end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetFrameStrata(value) self.strata=value end
function methods:SetFrameLevel(value) self.level=value end
function methods:GetFrameLevel() return self.level end
function methods:SetMovable(value) self.movable=value end
function methods:EnableMouse(value) self.mouse=value end
function methods:EnableMouseWheel(value) self.mouseWheel=value end
function methods:SetClampedToScreen(value) self.clamped=value end
function methods:RegisterForDrag(...) self.drag={...} end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events=self.events or {}; self.events[name]=true end
function methods:SetID(value) self.id=value end
function methods:GetID() return self.id end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function script(object,name,value)
    local oldThis,oldArg,oldEvent=this,arg1,event
    this=object; arg1=value
    local ok,problem=pcall(function() if object.scripts[name] then object.scripts[name]() end end)
    this,arg1,event=oldThis,oldArg,oldEvent
    if not ok then error(problem) end
end
function methods:Show()
    local old=self.shown; self.shown=true
    if not old then script(self,'OnShow') end
end
function methods:Hide()
    local old=self.shown; self.shown=false
    if old then
        script(self,'OnHide')
        for _,child in ipairs(self.children) do if child.shown then script(child,'OnHide') end end
    end
end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=nil end
function methods:GetCenter() return 400,300 end
function methods:SetAutoFocus(value) self.autoFocus=value end
function methods:GetText() return self.text end
function methods:ClearFocus() self.focus=nil end
function methods:SetHighlightTexture(value) self.highlight=value end
function methods:CreateTexture(name,layer)
    local texture=newObject('Texture',name,self); texture.layer=layer; return texture
end
function methods:SetTexture(value) self.texture=value; record('texture',self,value) end
function methods:SetBlendMode(value) self.blend=value end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAlpha(value) self.alpha=value; record('alpha',self,value) end
function methods:SetScrollChild(child) self.scrollChild=child end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return math.max(0,(self.scrollChild.height or 0)-300) end

-- The shared strict font contract is installed by Python before CreateFrame.
function installFrames()
    function CreateFrame(kind,name,parent,template)
        local object=newObject(kind,name,parent)
        object.template=template
        if template=='ContainerFrameItemButtonTemplate' then
            object.icon=object:CreateTexture(name..'IconTexture','ARTWORK')
            object.nativeCount=object:CreateFontString(name..'Count','OVERLAY','GameFontNormal')
            object.scripts.OnUpdate=function() error('inherited per-button OnUpdate was not removed') end
            CreateFrame('Model',name..'Cooldown',object,'CooldownFrameTemplate')
        elseif template=='InputBoxTemplate' then
            object:SetFontObject(GameFontNormal)
        elseif template then
            assert(template=='CooldownFrameTemplate' or template=='UIPanelScrollFrameTemplate',template)
        end
        return object
    end
    UIParent=CreateFrame('Frame','UIParent'); UIParent.height=768
    StackSplitFrame=CreateFrame('Frame','StackSplitFrame'); StackSplitFrame:Hide()
    GameTooltip=CreateFrame('GameTooltip','GameTooltip'); GameTooltip.lines={}; GameTooltip:SetFontObject(GameFontNormal)
    function GameTooltip:SetOwner(owner,anchor) self.owner=owner; self.anchor=anchor end
    function GameTooltip:IsOwned(owner) return self.owner==owner end
    function GameTooltip:SetBagItem(bag,slot) self.lines={GetContainerItemLink(bag,slot) or '未知'}; record('tooltip',bag,slot) end
    function GameTooltip:AddLine(text,...) table.insert(self.lines,text) end
    local setText=methods.SetText
    function GameTooltip:SetText(text) setText(self,text); self.lines={text} end
end
function SetItemButtonTexture(button,value) button.icon:SetTexture(value) end
function SetItemButtonCount(button,value) button.nativeCount:SetText(value); button.count=value end
function SetItemButtonDesaturated(button,value) button.desaturated=value; record('desaturate',button,value) end
function CooldownFrame_SetTimer(frame,start,duration,enabled)
    frame.timer={start,duration,enabled}; record('cooldown',frame,start,duration,enabled)
end
-- Client handler stub checks physical binding and receives count for splitting.
function ContainerFrameItemButton_OnClick(mouse)
    assert(this and this.qRecord and this:GetParent():GetID()==this.qRecord.bag and this:GetID()==this.qRecord.slot)
    record('nativeClick',this,mouse)
    if shift and this.count>1 then StackSplitFrame.owner=this; this.hasStackSplit=1; StackSplitFrame:Show()
    elseif control then record('dressUp',this)
    elseif mouse=='RightButton' then UseContainerItem(this:GetParent():GetID(),this:GetID())
    else PickupContainerItem(this:GetParent():GetID(),this:GetID()) end
end
function open() QianKunBag:Open() end
function tick(seconds) now=now+(seconds or 0.016); QianKunBag:Tick(seconds or 0.016) end
