"""S_ItemTip merged Lua 5.1 behavior checks; controlled APIs, not game acceptance.

Pass --addon for an isolated candidate. The default is the installed addon.
"""
from pathlib import Path
import argparse, sys, json, re
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

MOCK = r'''
clock=0; frames={}; infoCalls=0; inventoryCalls=0; priorEvents=0; hookCalls=0
ready=true; class='MAGE'; count=-5; layout='auto'; names={player='Self',target='Other',mouseover='Other'}
items={[100]={'Example','item:100:0:0:0',4,0,0,0,0,'INVTYPE_HEAD'},[101]={'Other','item:101:0:0:0',4,0,0,0,0,'INVTYPE_HEAD'}}
inventories={player={[1]=100},target={[1]=100},mouseover={[1]=100}}
libraries={['LibItem-enUS-1.0']={Item_enUS={[100]='Example',[101]='Other'}},['LibItemLevel-1.0']={Item_Level={[100]=60,[101]=80}}}
LibStub=setmetatable({GetLibrary=function(self,name) return libraries[name] end},{__call=function(self,name) return libraries[name] end})
methods={}
local function noop() end
function newObject(kind,name,parent)
 local obj=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={},events={},width=0,height=0,strata='MEDIUM',level=1}, {__index=methods})
 if name then _G[name]=obj end
 table.insert(frames,obj); return obj
end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetOwner() return self.owner end
function methods:SetOwner(owner) self.owner=owner end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:GetText() return self.text end
function methods:SetWidth(w) self.width=w end
function methods:GetWidth() if self.kind=='FontString' and self.width==0 then return string.len(self.text or '')*6 end return self.width end
function methods:SetHeight(h) self.height=h end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:GetPoint() return unpack(self.point or {}) end
function methods:SetFrameStrata(s) self.strata=s end
function methods:GetFrameStrata() return self.strata end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level end
function methods:SetToplevel(v) self.toplevel=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:SetTexture(v) self.texturePath=v end
function methods:CreateTexture(name,layer) return newObject('Texture',name,self) end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function callScript(obj,k,...)
 local old=this; this=obj; if obj.scripts[k] then obj.scripts[k](...) end; this=old
end
function methods:Show() local old=self.shown;self.shown=true;if not old then callScript(self,'OnShow') end end
function methods:Hide() local old=self.shown;self.shown=false;if old then callScript(self,'OnHide') end end
function methods:NumLines() return self.lines or 0 end
function methods:AddLine(text)
 self.lines=(self.lines or 0)+1
 local font=newObject('FontString',self.name..'TextLeft'..self.lines,self)
 font:SetFontObject(GameFontNormal);font:SetText(text)
end
for _,name in ipairs({'SetTextColor','SetBackdropBorderColor','EnableMouse','SetMovable','RegisterForDrag','StartMoving','StopMovingOrSizing','Raise','SetAllPoints','SetBlendMode','SetVertexColor','SetTexCoord','SetJustifyH','SetJustifyV','SetScale','EnableMouseWheel','SetNormalTexture','SetHighlightTexture','SetPushedTexture'}) do methods[name]=noop end
function CreateFrame(kind,name,parent) return newObject(kind,name,parent) end
function getglobal(name) return _G[name] end
function GetTime() return clock end
function time() return math.floor(clock) end
function UnitExists(unit) return names[unit]~=nil end
function UnitName(unit) return names[unit] end
function UnitIsUnit(a,b) return names[a] and names[a]==names[b] end
function UnitIsPlayer(unit) return UnitExists(unit) end
function UnitClass() return class,class end
function UnitLevel() return 60 end
function UnitRace() return 'Human','Human' end
function UnitSex() return 2 end
enchants={}
function GetInventoryItemLink(unit,slot)
 inventoryCalls=inventoryCalls+1
 local id=inventories[unit] and inventories[unit][slot]
 if id then return 'item:'..id..':'..(enchants[slot] or 0)..':0:0' end
end
function GetInventoryItemTexture() return 'texture' end
function GetItemInfo(id)
 infoCalls=infoCalls+1
 assert(id~=nil,'GetItemInfo requires ID')
 if ready then local row=items[tonumber(id)];if row then return unpack(row) end end
end
function GetItemQualityColor(q) assert(type(q)=='number');return 1,1,1,'|cffffffff' end
function GetContainerItemInfo() return 'texture',count end
function GetContainerItemLink() return 'item:100:0:0:0' end
function GetAuctionItemInfo() return 'Example','texture',count end
function GetAuctionSellItemInfo() return 'Example','texture',count end
function GetInboxItem() return 'Example','texture',count,4 end
function SetAutoloot() end
function InspectUnit(unit) hookCalls=hookCalls+1;InspectFrame.unit=unit;return 'inspect-result' end
function IsAddOnLoaded(name) return name=='pfUI' or name=='StatCompare' end
function hooksecurefunc(name,func) hooks[name]=func end
hooks={};SlashCmdList={};DEFAULT_CHAT_FRAME={AddMessage=function() end}
RAID_CLASS_COLORS={MAGE={r=1,g=1,b=1},HUNTER={r=1,g=1,b=1}}
function SetPortraitTexture() end
function HideUIPanel(frame) frame:Hide() end
function ShowUIPanel(frame) frame:Show() end
function GetInventorySlotInfo() return 1 end
function SCGetPanelLayoutMode() return layout end
function SCApplyPanelDisplayPolicy() end
function SCApplyPanelStyle() end
function SCRequestPanelLayout() end
function SCRelayoutPanels() end
function SCSetPanelPoint(frame,...) frame:SetPoint(...) end
function advance(dt)
 clock=clock+dt
 local oldArg=arg1;arg1=dt
 local active={};for _,obj in ipairs(frames) do if obj.scripts.OnUpdate then table.insert(active,obj) end end
 for _,obj in ipairs(active) do callScript(obj,'OnUpdate',dt) end
 arg1=oldArg
end
function dispatch(obj,ev,arg)
 local oldEvent,oldArg=event,arg1;event=ev;arg1=arg;callScript(obj,'OnEvent');event=oldEvent;arg1=oldArg
end
'''

class Suite:
    def __init__(self, addon):
        self.addon=addon;self.checks=[]
    def runtime(self, panel=False, fonts_fail=False, setup=None):
        l=LuaRuntime(unpack_returned_tuples=True);l.execute(MOCK)
        install=l.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
        install(l.globals().methods,l.globals().newObject)
        l.execute(r'''
local create=methods.CreateFontString
function methods:CreateFontString(name,layer,template)
 if template=='GameFontNormalSmall' or template=='GameTooltipText' then template='GameFontNormal' end
 return create(self,name,layer,template)
end
UIParent=CreateFrame('Frame','UIParent')
CharacterFrame=CreateFrame('Frame','CharacterFrame',UIParent)
PaperDollFrame=CreateFrame('Frame','PaperDollFrame',CharacterFrame)
InspectFrame=CreateFrame('Frame','InspectFrame',UIParent);InspectFrame.unit='target'
GameTooltip=CreateFrame('Frame','GameTooltip',UIParent)
ItemRefTooltip=CreateFrame('Frame','ItemRefTooltip',UIParent);ItemRefTooltip:Hide()
GameTooltip:AddLine('Example');GameTooltip:AddLine('INVTYPE_HEAD')
StatCompareSelfFrame=CreateFrame('Frame','StatCompareSelfFrame',UIParent)
StatCompareSelfFrame:SetScript('OnEvent',function() priorEvents=priorEvents+1 end)
PlayerItemGS=UIParent:CreateFontString('PlayerItemGS','OVERLAY','GameFontNormal')
TargetItemGS=UIParent:CreateFontString('TargetItemGS','OVERLAY','GameFontNormal')
for _,method in ipairs({'SetBagItem','SetQuestLogItem','SetQuestItem','SetLootItem','SetInboxItem','SetInventoryItem','SetLootRollItem','SetMerchantItem','SetCraftItem','SetCraftSpell','SetTradeSkillItem','SetAuctionItem','SetAuctionSellItem','SetTradePlayerItem','SetTradeTargetItem','SetUnit'}) do
 GameTooltip[method]=function() hookCalls=hookCalls+1;return 'hook-result' end
end
function methods:SetHyperlink(link) self.hyperlink=link end
''')
        if fonts_fail:l.execute(r"failedFontPaths['Fonts\\FZXHLJW.TTF']=true;failedFontPaths['Fonts\\FRIZQT__.TTF']=true")
        for name in set(re.findall(r'\bINVTYPE_[A-Z0-9_]+\b',(self.addon/'ItemSocre.lua').read_text(encoding='utf-8'))):
            l.globals()[name]=name
        if setup:l.execute(setup)
        l.execute((self.addon/'EnchantAPI.lua').read_text(encoding='utf-8-sig'))
        l.execute((self.addon/'ItemSocre.lua').read_text(encoding='utf-8-sig'))
        if panel:
            l.execute((self.addon/'InspectFrame.lua').read_text(encoding='utf-8-sig'))
        return l
    def check(self,name,code,l=None):
        l=l or self.runtime();l.execute(code);self.checks.append(name);return l
    def run(self):
        for f in ['ItemSocre.lua','InspectFrame.lua','InspectGemAndEnchant.lua']:
            self.runtime().execute('assert(loadstring(...))',(self.addon/f).read_text(encoding='utf-8-sig'))
            self.checks.append('syntax '+f)
        self.check('score hit/expiry/force',r'''
local a,complete=ItemSocre:ScanUnit('player');assert(a==4.8 and complete)
assert(inventoryCalls==17);ItemSocre:ScanUnit('player');assert(inventoryCalls==17)
advance(.51);ItemSocre:ScanUnit('player');assert(inventoryCalls==34)
ItemSocre:ScanUnit('player',true);assert(inventoryCalls==51)
''')
        self.check('unknown nonplayer and empty player',r'''
assert(ItemSocre:ScanUnit(nil)==nil);assert(ItemSocre:ScanUnit('missing')==nil)
inventories.player={};local score,complete=ItemSocre:ScanUnit('player');assert(score==nil and complete)
''')
        self.check('incomplete info recovers',r'''
ready=false;local _,c=ItemSocre:ScanUnit('player');assert(not c)
ready=true;advance(.11);local v,c=ItemSocre:ScanUnit('player');assert(v==4.8 and c)
''')
        self.check('remote data readiness and empty retry bounded',r'''
local _,c=ItemSocre:ScanUnit('target');assert(not c)
ItemSocre:MarkInspectReady('target');local _,c=ItemSocre:ScanUnit('target');assert(c)
inventories.target={};ItemSocre:InvalidateScores();local _,c=ItemSocre:ScanUnit('target');assert(not c)
local calls=0;ItemSocre:ScheduleScoreRefresh('target','test',function() calls=calls+1 end,function() return true end)
advance(.2);advance(.3);advance(.5);advance(2);assert(calls==3)
''')
        self.check('alias invalidation / both event orders',r'''
names.target=names.player;inventories.target=inventories.player
assert(ItemSocre:ScanUnit('target')==4.8);inventories.player[1]=101
dispatch(StatCompareSelfFrame,'UNIT_INVENTORY_CHANGED','player')
dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player')
assert(ItemSocre:ScanUnit('target')==6.4);assert(priorEvents==1)
inventories.player[1]=100;dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player')
dispatch(StatCompareSelfFrame,'UNIT_INVENTORY_CHANGED','player')
assert(ItemSocre:ScanUnit('target')==4.8);assert(priorEvents==2)
''')
        self.check('unique and ambiguous names',r'''
assert(ItemSocre:ResolveItemID('Example')==100)
libraries['LibItem-enUS-1.0'].Item_enUS={[100]='Twin',[101]='Twin'}
local id,status=ItemSocre:ResolveItemID('Twin');assert(not id and status=='ambiguous')
assert(ItemSocre:GetItemLevel(999,'Twin')==0)
assert(ItemSocre:GetItemLevel(100,'Twin')==60)
assert(ItemSocre:GetItemLinkByName('Twin')==nil)
libraries['LibItemLevel-1.0'].Item_Level={[100]=60,[101]=60}
assert(ItemSocre:GetItemLevel(999,'Twin')==60)
assert(ItemSocre:GetItemLinkByName('Twin')==nil)
''')
        self.check('quality and slot narrow candidates',r'''
libraries['LibItem-enUS-1.0'].Item_enUS={[100]='Twin',[101]='Twin'}
items[101][3]=3;assert(ItemSocre:ResolveItemID('Twin',4)==100)
items[101][3]=4;items[101][8]='INVTYPE_WEAPON';assert(ItemSocre:ResolveItemID('Twin',4,'INVTYPE_HEAD')==100)
ready=false;local id,status=ItemSocre:ResolveItemID('Twin',4);assert(not id and status=='ambiguous')
''')
        self.check('source replacement and manual in-place reset',r'''
assert(ItemSocre:ResolveItemID('Example')==100)
libraries['LibItem-enUS-1.0'].Item_enUS={[101]='Example'}
assert(ItemSocre:ResolveItemID('Example')==101)
assert(ItemSocre:GetItemLevel(999,'Example')==80)
libraries['LibItemLevel-1.0'].Item_Level={[101]=90};assert(ItemSocre:GetItemLevel(999,'Example')==90)
libraries['LibItem-enUS-1.0'].Item_enUS[101]=nil;ItemSocre:InvalidateCaches()
assert(ItemSocre:ResolveItemID('Example')==nil)
''')
        self.check('failed link retries and missing quality',r'''
ready=false;assert(ItemSocre:GetItemLinkByName('Example')==nil)
ready=true;advance(.2);assert(ItemSocre:GetItemLinkByName('Example'))
items[100][3]=nil;ItemSocre:InvalidateCaches();assert(ItemSocre:GetItemLinkByName('Example')==nil)
items[100][3]=4;advance(1.01);assert(ItemSocre:GetItemLinkByName('Example'))
''')
        self.check('fallback global budget/dedup/bounded completion',r'''
libraries['LibItem-enUS-1.0'].Item_enUS={}
for i=1,12 do ItemSocre:GetItemLinkByName('Missing'..i) end
for i=1,4 do local before=infoCalls;advance(.01);assert(infoCalls-before<=256) end
for i=1,900 do advance(.01) end
for _,f in ipairs(frames) do assert(f.scripts.OnUpdate==nil) end
assert(ItemSocre:GetItemLinkByName('Missing1')==nil)
''')
        self.check('fallback positive and negative requery',r'''
libraries['LibItem-enUS-1.0'].Item_enUS={}
assert(not ItemSocre:GetItemLinkByName('Example'))
for i=1,102 do advance(.01) end
assert(ItemSocre:GetItemLinkByName('Example'))
ItemSocre:GetItemLinkByName('Later');for i=1,102 do advance(.01) end
items[102]={'Later','item:102:0:0:0',4,0,0,0,0,'INVTYPE_HEAD'}
advance(1.1);ItemSocre:GetItemLinkByName('Later');for i=1,102 do advance(.01) end
assert(ItemSocre:GetItemLinkByName('Later'))
''')
        self.check('fallback refuses same-name IDs',r'''
libraries['LibItem-enUS-1.0'].Item_enUS={};items[101][1]='Example'
ItemSocre:GetItemLinkByName('Example');advance(.01)
assert(not ItemSocre:GetItemLinkByName('Example'))
''')
        self.check('tooltip completion and stale request cancellation',r'''
ready=false;GameTooltip:SetInboxItem(1,1);ready=true;advance(.2)
assert(GameTooltip.itemLink and string.find(GameTooltip.itemLink,'item:100:'))
ItemSocre:InvalidateCaches();ready=false;GameTooltip:SetInboxItem(1,1)
GameTooltip:SetBagItem(0,1);GameTooltip.itemLink='item:101:0:0:0'
ready=true;advance(.2);assert(GameTooltip.itemLink=='item:101:0:0:0')
''')
        for ability in [True,False]:
            for n in [None,-5,0,5]:
                self.check(f'charge ability={ability} count={n}',f'''
{'SetAutoloot=nil' if not ability else ''}
count={'nil' if n is None else n}
for _,method in ipairs({{'SetBagItem','SetAuctionItem','SetAuctionSellItem'}}) do
 assert(GameTooltip[method](GameTooltip,1,1)=='hook-result')
 assert(GameTooltip.itemCount=={'nil' if n is None else abs(n) if ability else n})
end
''')
        self.check('auction exact link preferred',r'''
function GetAuctionItemLink(kind,index) assert(kind=='list' and index==2);return 'item:101:0:0:0' end
GameTooltip:SetAuctionItem('list',2);assert(GameTooltip.itemLink=='item:101:0:0:0')
''')
        self.check('hook arguments and nil-separated multiple returns',r'''
local a,b,c=GameTooltip:SetInboxItem(7,2);assert(a=='first' and b==nil and c=='third')
a,b,c=InspectUnit('player');assert(a=='inspect' and b==nil and c=='third')
''',self.runtime(setup=r'''
GameTooltip.SetInboxItem=function(self,mail,attachment) assert(self==GameTooltip and mail==7 and attachment==2);return 'first',nil,'third' end
InspectUnit=function(unit) assert(unit=='player');return 'inspect',nil,'third' end
'''))
        self.check('inspect uses supplied unit/returns old result',r'''
assert(InspectUnit('player')=='inspect-result');assert(hookCalls==1)
assert(TargetItemGS:GetText()=='装备等级 4.8')
''')
        self.check('tooltip repeated scores do not duplicate lines',r'''
GameTooltip:SetUnit('player');local n=GameTooltip:NumLines();GameTooltip:SetUnit('player')
assert(GameTooltip:NumLines()==n)
inventories.player[1]=101;ItemSocre:InvalidateScores();GameTooltip:SetUnit('player')
assert(_G['GameTooltipTextLeft'..n]:GetText()=='装备等级 6.4')
''')
        self.check('equipment event refreshes visible tooltip / empty score',r'''
GameTooltip:SetUnit('player');local n=GameTooltip:NumLines()
inventories.player[1]=101;dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player')
assert(_G['GameTooltipTextLeft'..n]:GetText()=='装备等级 6.4')
inventories.player={};dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player')
assert(_G['GameTooltipTextLeft'..n]:GetText()=='')
inventories.player[1]=100;dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player')
assert(GameTooltip:NumLines()==n and _G['GameTooltipTextLeft'..n]:GetText()=='装备等级 4.8')
''')
        self.check('source mutation uses bounded cache storage',r'''
local source=libraries['LibItem-enUS-1.0'].Item_enUS
for i=1,600 do source[1000+i]='Name'..i end
for i=1,600 do ItemSocre:ResolveItemID('Name'..i) end
local function find(fn,target,seen)
 seen=seen or {};if seen[fn] then return end;seen[fn]=true
 for i=1,50 do local name,value=debug.getupvalue(fn,i);if not name then break end
  if name==target then return value end
  if type(value)=='function' then local found=find(value,target,seen);if found then return found end end
 end
end
local cache=find(ItemSocre.ResolveItemID,'nameCache');local count=0;for _ in pairs(cache) do count=count+1 end
assert(count<=512)
for i=1,160 do names.player='Self'..i;ItemSocre:ScanUnit('player') end
cache=find(ItemSocre.ScanUnit,'scoreCache');count=0;for _ in pairs(cache) do count=count+1 end;assert(count<=128)
for i=1,270 do
 local id=1000+i;items[id]={'Name'..i,'item:'..id..':0:0:0',4};assert(ItemSocre:GetItemLinkByName('Name'..i))
end
cache=find(ItemSocre.GetItemLinkByName,'linkCache');count=0;for _ in pairs(cache) do count=count+1 end;assert(count<=256)
''')
        self.check('font failures without template do not SetText',r'''
PlayerItemGS.font=nil;GameFontNormal=nil
failedFontPaths['Fonts\\FZXHLJW.TTF']=true;failedFontPaths['Fonts\\FRIZQT__.TTF']=true
dispatch(StatCompareSelfFrame,'UNIT_INVENTORY_CHANGED','player')
assert(not PlayerItemGS:GetFont())
''')
        self.check('strict FontString precondition and failed fonts fallback',r'''
local raw=UIParent:CreateFontString(nil,'OVERLAY');assert(not pcall(function() raw:SetText('bad') end))
failedFontPaths['missing.ttf']=true;assert(not raw:SetFont('missing.ttf',12))
assert(not pcall(function() raw:SetText('bad') end))
PlayerItemGS.font=nil;TargetItemGS.font=nil
dispatch(StatCompareSelfFrame,'UNIT_INVENTORY_CHANGED','player');InspectUnit('player')
assert(PlayerItemGS:GetFont() and TargetItemGS:GetFont())
''')
        # Exercise production scoring over a matrix rather than mirroring its loop.
        for cls in ['MAGE','HUNTER']:
            for quality,scale in [(0,1),(1,.25),(2,.6),(3,.85),(4,1),(5,1.3)]:
                for slot,kind,coef in [(16,'INVTYPE_2HWEAPON',1 if cls=='HUNTER' else 2.6836),(16,'INVTYPE_WEAPON',.5 if cls=='HUNTER' else 1.6836),(17,'INVTYPE_SHIELD',.5 if cls=='HUNTER' else 1),(18,'INVTYPE_RANGED',2 if cls=='HUNTER' else .3164)]:
                    expected=float(f'{60*scale*coef/17*1.355:.1f}')
                    self.check(f'formula {cls}/{quality}/{slot}/{kind}',f"class='{cls}';inventories.player={{[{slot}]=100}};items[100][3]={quality};items[100][8]='{kind}';assert(ItemSocre:ScanUnit('player')=={expected})")
        l=self.runtime(panel=True,fonts_fail=True)
        self.check('panel creation/reuse/throttle/force/font failures',r'''
S_ItemTip_OnCharacterShow();local frame=S_ItemTip_InspectFrame;assert(frame)
assert(not frame.nameText:SetFont('Fonts\\FZXHLJW.TTF',12))
assert(frame.classIcon.texturePath=='Interface\\AddOns\\S_ItemTip\\Icons\\classicons')
assert(frame.ilevelText:GetText()=='装等 4.8');assert(S_ItemTip_UpdateFrame('player')==false)
inventories.player[1]=101;ItemSocre:InvalidateScores();assert(S_ItemTip_UpdateFrame('player',true)==true)
assert(frame.ilevelText:GetText()=='装等 6.4')
frame:Hide();S_ItemTip_OnCharacterShow();assert(S_ItemTip_InspectFrame==frame)
SlashCmdList.SITEMINSPECT('toggle');assert(not frame:IsShown())
SlashCmdList.SITEMINSPECT('toggle');assert(frame:IsShown())
layout='free';S_ItemTip_ApplyLayoutPolicy(frame);assert(frame.clamped)
layout='auto';S_ItemTip_ApplyLayoutPolicy(frame);assert(not frame.clamped)
SlashCmdList.SITEMINSPECT('cacheclear')
''',l)
        self.check('panel incomplete data retries and event force',r'''
ready=false;S_ItemTip_OnCharacterShow();ready=true;advance(.2)
assert(S_ItemTip_InspectFrame.ilevelText:GetText()=='装等 4.8')
inventories.player[1]=101
for _,obj in ipairs(frames) do if obj.events.INSPECT_READY then dispatch(obj,'UNIT_INVENTORY_CHANGED','player') end end
assert(S_ItemTip_InspectFrame.ilevelText:GetText()=='装等 6.4')
''',self.runtime(panel=True))
        l=self.runtime(panel=True,fonts_fail=True)
        l.execute((self.addon/'InspectGemAndEnchant.lua').read_text(encoding='utf-8-sig'))
        self.check('full enchant wrapper prepares/reuses/hides icons',r'''
enchants[1]=30;S_ItemTip_OnCharacterShow();local frame=S_ItemTip_InspectFrame
assert(frame.gemIcon1 and frame.gemIcon1:IsShown() and frame.gemIcon1.enchantID==30)
local icon=frame.gemIcon1;assert(S_ItemTip_UpdateFrame('player')==false)
S_ItemTip_UpdateFrame('player',true);assert(frame.gemIcon1==icon and icon:IsShown())
enchants[1]=0;S_ItemTip_UpdateFrame('player',true);assert(not icon:IsShown())
''',l)
        self.check('remote visible panel updates from inventory / ready notification',r'''
S_ItemTip_ShowForInspect('target');local frame=S_ItemTip_InspectFrame
assert(frame.ilevelText:GetText()=='装等 4.8')
inventories.target[1]=101
for _,obj in ipairs(frames) do if obj.events.INSPECT_READY then dispatch(obj,'UNIT_INVENTORY_CHANGED','target');dispatch(obj,'INSPECT_READY') end end
assert(frame.ilevelText:GetText()=='装等 6.4' and TargetItemGS:GetText()=='装备等级 6.4')
''',self.runtime(panel=True))
        # Load the real enchant wrapper against a successful/blocked base without rendering icon details.
        l=self.runtime(panel=True)
        l.execute("baseCalls=0;S_ItemTip_UpdateFrame=function(unit,force) baseCalls=baseCalls+1;baseForce=force;return false end")
        l.execute((self.addon/'InspectGemAndEnchant.lua').read_text(encoding='utf-8-sig'))
        self.check('enchant wrapper forwards force and respects false',"assert(S_ItemTip_UpdateFrame('player',true)==false);assert(baseCalls==1 and baseForce==true)",l)
        return {'ok':True,'checks':len(self.checks),'runtime':'Lua 5.1','scope':'Controlled source behavior and FontString contracts; no in-game acceptance','cases':self.checks}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--addon',type=Path,default=ROOT/'Interface/AddOns/S_ItemTip');p.add_argument('--output',type=Path)
    args=p.parse_args();result=Suite(args.addon).run()
    if args.output:args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
