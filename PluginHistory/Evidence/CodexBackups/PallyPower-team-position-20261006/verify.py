from pathlib import Path
import sys,re,ast,itertools,math,time,json,xml.etree.ElementTree as ET

work=Path(__file__).parent; support=Path(r'C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work'); root=Path(r'E:\1.18\Interface\AddOns')
sys.path.insert(0,str(support/'cat-ret-tests/deps'))
from lupa.lua51 import LuaRuntime
old_test=ast.parse((support/'pallypower-targets/verify.py').read_text(encoding='utf-8'))
game=ast.literal_eval(next(n.value for n in old_test.body if isinstance(n,ast.Assign) and any(getattr(t,'id',None)=='mock' for t in n.targets)))
exec(compile(ast.Module(body=[next(n for n in old_test.body if isinstance(n,ast.FunctionDef) and n.name=='compatible')],type_ignores=[]),'<compatibility>','exec'))
prior=ast.parse((support/'cat-paladin-unified/verify.py').read_text(encoding='utf-8'))
node=next(n.value for n in prior.body if isinstance(n,ast.Assign) and any(getattr(t,'id',None)=='mock' for t in n.targets))
ui=eval(compile(ast.Expression(node),'<UI mock>','eval'),{'work':support/'team-position'})
def read(name):
    path=work/'patched'/name
    return (path if path.exists() else root/name).read_text(encoding='utf-8-sig')
manifest=json.loads((work/'manifest.json').read_text(encoding='utf-8'))
for name in manifest:
    if name.endswith('.lua'):
        ok,error=LuaRuntime().eval('function(s) local f,e=loadstring(s); return f~=nil,e end')(read(name)); assert ok,(name,error)
xml=ET.fromstring(read('PallyPower/PallyPower.xml'))
for element in xml.iter():
    if element.tag.split('}')[-1].startswith('On') and element.text:
        ok,error=LuaRuntime().eval('function(s) local f,e=loadstring(s); return f~=nil,e end')(element.text); assert ok,error
assert 'MiddleButtonUp' in read('PallyPower/PallyPower.xml')
toc=read('PallyPower/PallyPower.toc')
assert toc.index('PallyPower-Extensions.lua')>toc.index('PallyPower.xml')

mock='''
table.setn=nil -- Lua 5.1 derives array length; WoW Lua 5.0 uses setn normally.
PallyPower_BuffBarTitle='祝福助手 (%d)'; PallyPower_BuffFrameText='祝福'
PallyPower_Have='已有'; PallyPower_Need='需要'; PallyPower_NotHere='不在场'; PallyPower_Dead='死亡'
local originalObject=NewObject
function NewObject(...)
    local object=originalObject(unpack(arg))
    function object:SetBackdropColor(r,g,b,a) self.bgcolor={r,g,b,a} end
    function object:SetBackdrop(value) self.bg=value end
    function object:GetBackdrop() return self.bg end
    function object:SetMovable(value) self.movable=value end
    function object:EnableMouse(value) self.mouse=value end
    function object:RegisterForClicks(...) self.clicks={unpack(arg)} end
    function object:LockHighlight() self.highlight=true end
    function object:UnlockHighlight() self.highlight=false end
    function object:SetTextColor(r,g,b,a) self.textcolor={r,g,b,a} end
    return object
end
PallyPowerFrame=CreateFrame('Frame','PallyPowerFrame',UIParent); PallyPowerFrame:Hide(); PallyPowerFrame:SetWidth(720); PallyPowerFrame:SetHeight(170)
PallyPowerBuffBar=CreateFrame('Frame','PallyPowerBuffBar',UIParent); PallyPowerBuffBar:SetWidth(110); PallyPowerBuffBar:SetHeight(100)
PallyPower_OptionsFrame=CreateFrame('Frame','PallyPower_OptionsFrame',UIParent); PallyPower_OptionsFrame:Hide()
PallyPower_ScalingFrame=CreateFrame('Frame','PallyPower_ScalingFrame',UIParent); PallyPower_ScalingFrame:Hide()
for _,n in ipairs({'PallyPowerFrameRefresh','PallyPowerFrameClear','PallyPowerFrameOptions','PallyPowerFrameCloseButton','TenMinBlessingMainChk','TenMinBlessingChk'}) do CreateFrame('Button',n,PallyPowerFrame) end
for _,n in ipairs({'PallyPowerBuffBarTitle','PallyPowerBuffBarResizeButton'}) do CreateFrame('Button',n,PallyPowerBuffBar) end
PallyPowerBuffBarTitleText=PallyPowerBuffBar:CreateFontString('PallyPowerBuffBarTitleText','OVERLAY')
PallyPowerFrameTitleText=PallyPowerFrame:CreateFontString('PallyPowerFrameTitleText','OVERLAY')
for i=1,10 do
    local b=CreateFrame('Button','PallyPowerBuffBarBuff'..i,PallyPowerBuffBar); b:SetWidth(100); b:SetHeight(34)
    for _,suffix in ipairs({'Time','Text'}) do b:CreateFontString(b.name..suffix,'OVERLAY') end
    for _,suffix in ipairs({'ClassIcon','BuffIcon'}) do b:CreateTexture(b.name..suffix,'OVERLAY') end
end
for p=1,12 do
    local name='PallyPowerFramePlayer'..p
    local row=CreateFrame('Frame',name,PallyPowerFrame)
    row:CreateFontString(name..'Name','OVERLAY'); row:CreateFontString(name..'Symbols','OVERLAY')
    for i=0,5 do row:CreateTexture(name..'Icon'..i,'OVERLAY'); row:CreateFontString(name..'Skill'..i,'OVERLAY') end
    for i=0,9 do local b=CreateFrame('Button',name..'Class'..i,row); b:CreateTexture(b.name..'Icon','OVERLAY') end
end
for _,suffix in ipairs({'Title','CloseButton','Scan1','Scan2','Feedback','Smart','Solo','SoloForce'}) do CreateFrame('Button','PallyPower_OptionsFrame'..suffix,PallyPower_OptionsFrame) end
spellMessages={}; buffReads=0; frameScans=0; scanMax=0; inventoryScans=0
function SendAddonMessage(prefix,message) table.insert(spellMessages,message) end
function UnitExists(unit) if unit=='target' then return target~=nil end return units[unit]~=nil end
function UnitIsUnit(a,b) if a=='target' then return target==b end return a==b end
function TargetUnit(unit) oldTarget=target; target=unit end
function UnitIsConnected(unit) return units[unit] and not units[unit].offline end
function UnitIsVisible(unit) return units[unit]~=nil end
function SpellIsTargeting() return cursor end
function CastSpell(id,book)
    table.insert(castSpells,id)
    if target and units[target] then
        table.insert(targets,target)
        if not failCast then units[target].buffs={BuffIcon[id-16]} end
        cursor=false
    else cursor=true end
end
function UnitBuff(unit,index)
    buffReads=buffReads+1
    return units[unit] and units[unit].buffs and units[unit].buffs[index]
end
function GetContainerNumSlots() return 0 end
function GetPlayerBuff() return -1 end
function IsPartyLeader() return true end
function GetRaidRosterInfo(index) return nil,0 end
function UnitIsPartyLeader() return false end
abs=math.abs; floor=math.floor
GameTooltip={SetOwner=function() end,SetText=function() end,AddLine=function() end,Show=function() end,Hide=function() end}
chatCalls=0; DEFAULT_CHAT_FRAME.AddMessage=function() chatCalls=chatCalls+1 end
UIErrorsFrame={AddMessage=function(self,message) table.insert(feedback,message) end}
pfUI.api.CreateBackdropShadow=function() end
pfUI.api.SkinButton=function(b) if b then b.skinned=true end end
function IsAddOnLoaded() return true end
'''
def setup(saved=None, parent_scale=1, fire_login=True):
    lua=LuaRuntime(unpack_returned_tuples=True); lua.execute(ui+game+mock)
    lua.execute(compatible(read('PallyPower/PallyPower.lua')))
    lua.execute('''
        function PallyPower_ScanSpells() end
        PP_IsPally=true; TenMinBlessing=false; PallyPower_SwapIconsForThirtyMin()
        AllPallys['骑士']={symbols=185}; for i=0,11 do AllPallys['骑士'][i]={id=i+10,rank=1,talent=0} end
        PallyPower_Assignments['骑士']={[4]=4}; CurrentBuffs={[4]={player={name='骑士',visible=true}}}
        btn={classID=4,buffID=4}
    ''')
    lua.execute('UIParent:SetWidth(1920); UIParent:SetHeight(1080); PallyPower_OptionsFrame:SetWidth(300); function PallyPower_OptionsFrame:GetFrameLevel() return 2 end; PallyPowerSoloBar=CreateFrame("Button","PallyPowerSoloBar",UIParent); PallyPowerSoloBar:SetWidth(55); PallyPowerSoloBar:SetHeight(55); btn=PallyPowerBuffBarBuff1; btn.classID=4; btn.buffID=4')
    lua.globals().UIParent.scale=parent_scale
    lua.execute('PallyPowerSoloBar:SetPoint("CENTER",UIParent,"CENTER",-380,0)')
    lua.execute(read('PallyPower/PallyPower-Extensions.lua'))
    if saved:lua.execute('PP_PerUser='+saved)
    if fire_login: lua.execute('event="PLAYER_LOGIN"; PallyPowerExtensionEvents.scripts.OnEvent()')
    return lua
def click(lua,object,button=None):
    g=lua.globals(); g.this=object
    if button is None:object.scripts.OnClick()
    else:g.PallyPowerBuffButton_OnClick(object,button)

# FindWarrior maps, learned-spell guards, own assignments only, repeat no spam.
lua=setup(); g=lua.globals()
lua.execute('''raidCount=9; classes={'Warrior','Rogue','Priest','Druid','Paladin','Hunter','Mage','Warlock','Shaman'};
for i=1,9 do units['raid'..i]={name='成员'..i,class=classes[i],eligible=true} end
PallyPower_Assignments['其他骑士']={[0]=5,[4]=3}; PP_PerUser.personalBlessings={['成员1']={classID=0,buffID=1}}
''')
for key,expected in [('mightwisdom',[1,1,0,0,0,1,0,0,0]),('salvationwisdom',[2,2,0,0,0,2,2,2,0])]:
    click(lua,g['PallyPowerPreset'+key])
    assert [g.PallyPower_Assignments['骑士'][i] for i in range(9)]==expected
    assert g.PallyPower_Assignments['其他骑士'][0]==5 and g.PallyPower_Assignments['其他骑士'][4]==3
    assert g.PallyPower_PersonalBlessing(0,'成员1')==1
    count=len(g.spellMessages); click(lua,g['PallyPowerPreset'+key]); assert len(g.spellMessages)==count
g.AllPallys['骑士'][5]=None
g.PallyPower_Assignments['骑士'][0]=2
_,missing=g.PallyPower_ApplyPreset('sanctuary'); assert missing==9 and g.PallyPower_Assignments['骑士'][0]==2
for key,buff in [('might',1),('wisdom',0),('salvation',2),('kings',4),('light',3)]:
    g.PallyPower_ApplyPreset(key); assert all(g.PallyPower_Assignments['骑士'][i]==buff for i in range(9))

# No automatic chat output, even if old SavedVariables enabled chat feedback.
lua=setup(); g=lua.globals(); g.PP_PerUser.chatfeedback=1
g.PallyPower_ShowFeedback('技能错误',1,0,0); assert g.chatCalls==0 and g.feedback[1]=='技能错误'
g.PallyPower_ShowFeedback('技能错误',1,0,0); assert len(g.feedback)==1
g.PP_PerUser.screenfeedback=0; g.PallyPower_ShowFeedback('另一个提示',1,0,0); assert len(g.feedback)==1
assert not re.search(r'(?m)^\s*DEFAULT_CHAT_FRAME:AddMessage',read('PallyPower/PallyPower.lua'))


# Secondary member menu and tertiary blessing menu replace the standalone dialog.
lua=setup(); g=lua.globals(); lua.execute('''
raidCount=40; btn=PallyPowerBuffBarBuff1; btn.classID=0; btn.buffID=2;
CurrentBuffs={[0]={}}
for i=1,40 do units['raid'..i]={name=string.format('战士%02d',i),class='Warrior',token='WARRIOR',eligible=true}; CurrentBuffs[0]['raid'..i]={name=units['raid'..i].name,visible=true} end
PallyPower_Assignments['骑士'][0]=2
''')
click(lua,g.btn,'MiddleButton')
assert len(g.castSpells)==0 and g.target=='敌人' and g.PallyPowerMemberMenu.shown
assert g.PallyPowerPersonalFrame is None
assert g.PallyPowerMemberRow1.memberName=='战士01'
for i in range(3):click(lua,g.PallyPowerMemberNext)
assert g.PallyPowerMemberRow1.memberName=='战士31'
click(lua,g.PallyPowerMemberRow1); assert g.PallyPowerBlessingMenu.shown
g.LastCast['20']=1900
click(lua,g.PallyPowerSmallChoice1)
assert g.PallyPower_PersonalBlessing(0,'战士31')==1
assert not g.PallyPowerMemberMenu.shown and not g.PallyPowerBlessingMenu.shown
assert g.targets[len(g.targets)]=='raid31' and g.castSpells[len(g.castSpells)]==17
assert g.LastCast['20']==1900 and g.target=='敌人'
saved=g.Snapshot(g.PP_PerUser); restored=setup(saved); assert restored.globals().PallyPower_PersonalBlessing(0,'战士31')==1
lua.execute("units.raid31,units.raid9=units.raid9,units.raid31; targets={}")
click(lua,g.btn,'MiddleButton')
for i in range(3):click(lua,g.PallyPowerMemberNext)
click(lua,g.PallyPowerMemberRow1); click(lua,g.PallyPowerSmallCast); assert g.targets[1]=='raid9', (list(g.targets.values()),g.PallyPowerMemberRow1.memberName,g.btn.classID)
click(lua,g.btn,'MiddleButton')
for i in range(3):click(lua,g.PallyPowerMemberNext)
click(lua,g.PallyPowerMemberRow1); click(lua,g.PallyPowerSmallFollow)
assert g.PallyPower_PersonalBlessing(0,'战士31') is None
# Opening at the right/bottom edge flips/clamps both menu levels onto screen.
bar=g.PallyPowerBuffBar; bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',1880,90)
click(lua,g.btn,'MiddleButton'); click(lua,g.PallyPowerMemberRow1)
for menu in [g.PallyPowerMemberMenu,g.PallyPowerBlessingMenu]:
    assert 0<=menu.GetLeft(menu) and menu.GetRight(menu)<=1920
    assert menu.GetTop(menu)<=1080 and menu.GetTop(menu)-menu.height>=0
g.event='RAID_ROSTER_UPDATE'; g.PallyPowerExtensionEvents.scripts.OnEvent()
assert not g.PallyPowerMemberMenu.shown and not g.PallyPowerBlessingMenu.shown

# Right click prioritizes exceptions and never applies default Salv over tank Might.
lua=setup(); g=lua.globals(); lua.execute('''raidCount=2; btn={classID=0,buffID=2}; PallyPower_Assignments['骑士'][0]=2;
units.raid1={name='坦克',class='Warrior',token='WARRIOR',eligible=true,buffs={BuffIcon[2]}};
units.raid2={name='输出',class='Warrior',token='WARRIOR',eligible=true,buffs={BuffIcon[2]}}
''')
assert g.PallyPower_SetPersonalBlessing(0,'坦克',1)
click(lua,g.btn,'RightButton'); assert g.targets[len(g.targets)]=='raid1' and g.castSpells[len(g.castSpells)]==17
count=len(g.castSpells); click(lua,g.btn,'RightButton'); assert len(g.castSpells)==count
g.units.raid2.buffs=lua.table(); click(lua,g.btn,'RightButton'); assert g.targets[len(g.targets)]=='raid2' and g.castSpells[len(g.castSpells)]==18
lua.execute('units.raid1.buffs={BuffIcon[2]}; now=102; targets={}')
click(lua,g.btn,'RightButton'); assert g.targets[1]=='raid1'
lua.execute('units.raid1.offline=true; units.raid1.buffs={}; now=105; targets={}')
assert g.PallyPower_CastPersonalBlessing(0,'坦克',1) is False and len(g.targets)==0
lua.execute('units.raid1.offline=false; units.raid1.dead=true'); assert g.PallyPower_CastPersonalBlessing(0,'坦克',1) is False
lua.execute('units.raid1.dead=false; units.raid1.name="替换成员"'); assert g.PallyPower_CastPersonalBlessing(0,'坦克',1) is False

# Background alpha leaves icon and text alpha untouched; lock blocks every resize path.
lua=setup(); g=lua.globals()
g.PallyPower_SetBuffBarColor(g.PallyPowerBuffBarBuff1,1,0,0)
for value in [0,50,100]:
    g.PallyPowerBuffBarTransparency.SetValue(g.PallyPowerBuffBarTransparency,value)
    assert g.PallyPowerBuffBar.bgcolor[4]==1-value/100
    assert g.PallyPowerBuffBarBuff1.bgcolor[1]==1 and g.PallyPowerBuffBarBuff1.bgcolor[4]==1-value/100
    assert g.PallyPowerBuffBarBuff1.alpha==1 and g.PallyPowerBuffBarBuff1BuffIcon.alpha==1
lock=g.PallyPowerBuffBarLock; lock.checked=True; click(lua,lock)
assert g.PP_PerUser.barLocked==1 and not g.PallyPowerBuffBar.movable and not g.PallyPowerBuffBarResizeButton.shown
g.PallyPowerBuffBar_MouseDown('LeftButton'); assert not g.PallyPowerBuffBar.moving
g.this=g.PallyPowerBuffBarResizeButton; g.PallyPower_StartScaling('LeftButton'); assert g.PallyPower.FrameToScale is None
g.PallyPower.FrameToScale=g.PallyPowerBuffBar; old=g.PallyPowerBuffBar.scale; g.PallyPower_ScaleFrame(2); assert g.PallyPowerBuffBar.scale==old
g.PallyPower_ApplyBuffBarAppearance(); assert g.PallyPower.FrameToScale is None
saved=g.Snapshot(g.PP_PerUser); loaded=setup(saved); assert loaded.globals().PP_PerUser.barLocked==1
g.PallyPower_OptionsFrame.Show(g.PallyPower_OptionsFrame); assert lock.checked and g.PallyPowerBuffBarTransparency.value==100
lock.checked=False; click(lua,lock); g.this=g.PallyPowerBuffBarResizeButton; g.PallyPower_StartScaling('LeftButton')
assert g.PallyPower.FrameToScale.name=='PallyPowerBuffBar'
lua.execute(read('pfUI-addonskinner/skins/PallyPower.lua')); g.pfUI.addonskinner.callback()
assert g.PallyPowerBuffBar.bgcolor[4]==0

# Full UpdateUI honors personal exceptions in the displayed missing count.
lua=setup(); g=lua.globals(); lua.execute('''raidCount=2; units.raid1={name='坦克',class='Warrior',token='WARRIOR',eligible=true};
units.raid2={name='输出',class='Warrior',token='WARRIOR',eligible=true};
PallyPower_Assignments['骑士']={[0]=2}; PP_PerUser.personalBlessings={['坦克']={classID=0,buffID=1}};
CurrentBuffs={[0]={raid1={name='坦克',visible=true,[2]=true},raid2={name='输出',visible=true,[2]=true}}}; now=110''')
g.PallyPower_UpdateUI(); assert g.PallyPowerBuffBarBuff1Text.textvalue==1
g.CurrentBuffs[0].raid1[1]=True; g.now=111; g.PallyPower_UpdateUI(); assert g.PallyPowerBuffBarBuff1Text.textvalue==0
# Main grid must not grow cumulatively; exactly 12 rows supported.
g.PallyPowerFrame.Show(g.PallyPowerFrame)
lua.execute("for n=1,15 do AllPallys['额外骑士'..n]={symbols=1} end")
g.PallyPowerGrid_Update(); height=g.PallyPowerFrame.height; g.PallyPowerGrid_Update(); assert g.PallyPowerFrame.height==height

# Performance: one original scan step per frame despite both bars calling; no
# extension buff work while idle; actual 40x32-buff scan halves UnitBuff calls.
lua=setup(); g=lua.globals(); lua.execute('''raidCount=40; PP_PerUser.scanfreq=10; PP_PerUser.scanperframe=1;
for i=1,40 do units['raid'..i]={name='成员'..i,class='Warrior',token='WARRIOR',eligible=true,buffs={}};
for j=1,32 do units['raid'..i].buffs[j]='unrelated' end end
local scan=PallyPower_ScanRaid
function PallyPower_ScanRaid() frameScans=frameScans+1; scan() end
''')
start=time.perf_counter()
g.PallyPower_OnUpdate(.016)
for i in range(1,42):
    g.now=100+i/60; g.PallyPower_OnUpdate(.016); g.PallyPower_OnUpdate(.016)
assert g.frameScans==41 and g.buffReads==40*33,(g.frameScans,g.buffReads)
reads=g.buffReads
for i in range(42,600):
    g.now=100+i/60; g.PallyPower_OnUpdate(.016); g.PallyPower_OnUpdate(.016)
assert g.buffReads==reads
assert g.PallyPowerMemberMenu.scripts.OnUpdate is None and g.PallyPowerBlessingMenu.scripts.OnUpdate is None and g.PallyPowerExtensionEvents.scripts.OnUpdate is None
g.event='RAID_ROSTER_UPDATE'; g.PallyPowerExtensionEvents.scripts.OnEvent(); assert g.PP_ScanInfo is None and g.PP_NextScan==0
baseline=LuaRuntime(unpack_returned_tuples=True); baseline.execute(ui+game+mock)
baseline.execute(compatible((support/'pallypower-extension/original/PallyPower/PallyPower.lua').read_text(encoding='utf-8-sig')))
baseline.execute('''PP_IsPally=true; raidCount=40; AllPallys['骑士']={};
for i=1,40 do units['raid'..i]={name='成员'..i,class='Warrior',token='WARRIOR',eligible=true,buffs={}};
for j=1,32 do units['raid'..i].buffs[j]='unrelated' end end''')
for i in range(41): baseline.globals().PallyPower_ScanRaid()
assert baseline.globals().buffReads==2600

# Original greater-target repairs remain effective through the new middle/right dispatch.
lua=setup(); g=lua.globals(); g.CurrentBuffs=lua.table()
g.PallyPowerBuffButton_OnClick(g.btn,'LeftButton'); assert g.targets[1]=='player'
lua.execute('targets={}; now=101'); g.PallyPowerBuffButton_OnClick(g.btn,'LeftButton'); assert g.targets[1]=='player'
lua=setup(); g=lua.globals(); lua.execute('''raidCount=10; btn={classID=4,buffID=4};
units.raid1={name='近处骑士',class='Paladin',token='PALADIN',eligible=true}; LastCast['44']=now+1800; LastCastOn[4]={'raid10'}''')
g.PallyPowerBuffButton_OnClick(g.btn,'LeftButton'); assert g.targets[1]=='raid1'
print(f'PASS: FindWarrior preset mappings/all eight UI buttons; learned guards/own-only persistence; no chat output and optional deduplicated screen feedback; middle-click 40-person paging; individual casts/live name resolution; tank overrides/default exclusions; alpha/pfUI/lock/reload; missing-count integration/12-row limit; original target fixes retained; actual 40x32 scan uses 1320 UnitBuff calls vs original 2600; duplicate updates deduplicated and 558 idle frames add zero UnitBuff calls. Full-frame harness took {time.perf_counter()-start:.3f}s (not an in-game CPU benchmark).')

# Verify native-event dispatch semantics for both allowed surfaces and all locks.
entry_cases=0
for locked in [False,True]:
    lua=setup(); g=lua.globals(); options=g.PallyPower_OptionsFrame
    g.PP_PerUser.barLocked=int(locked); g.PallyPower_ApplyBuffBarAppearance()
    assert g.PallyPowerFrameOptions.shown
    g.this=g.PallyPowerFrameOptions
    assert g.PallyPower_Options() is True and options.shown
    options.Hide(options)
    assert g.PallyPower_Options('LeftButton') is True and options.shown
    options.Hide(options)
    assert g.PallyPower_Options('RightButton') is False and not options.shown
    for surface in [g.PallyPowerBuffBar,g.PallyPowerBuffBarTitle]:
        options.Hide(options); g.this=surface; g.arg1='RightButton'
        g.PallyPowerBuffBar_MouseDown('RightButton')
        surface.scripts.OnMouseUp()
        assert options.shown and not g.PallyPowerBuffBar.moving
        # User title drag moves only settings, including when the buff bar is locked.
        drag=g.PallyPowerOptionsDragHandle
        drag.scripts.OnDragStart(); assert options.moving
        options.ClearAllPoints(options); options.SetPoint(options,'TOPLEFT',g.UIParent,'BOTTOMLEFT',380,790)
        drag.scripts.OnDragStop(); assert options.moving is False
        position=(options.GetLeft(options),options.GetTop(options))
        options.Hide(options); g.this=surface; surface.scripts.OnMouseUp()
        assert (options.GetLeft(options),options.GetTop(options))==position
        drag.scripts.OnDragStart(); options.scripts.OnHide(); assert options.moving is False
        options.Hide(options); g.arg1='LeftButton'
        g.PallyPowerBuffBar_MouseDown('LeftButton'); g.PallyPowerBuffBar_MouseUp('LeftButton')
        assert not options.shown
        entry_cases+=1
    # Class-row right and middle click cannot route to the options window.
    options.Hide(options); g.this=g.PallyPowerBuffBarBuff1
    g.PallyPowerBuffButton_OnClick(g.btn,'RightButton'); assert not options.shown
    g.PallyPowerBuffButton_OnClick(g.btn,'MiddleButton'); assert g.PallyPowerMemberMenu.shown and not options.shown
print(f'PASS: {entry_cases} title/background right-click and lock combinations; settings title dragging, reopen position, close-during-drag; distribution Options button restored; left bar/class-row clicks do not open settings. No new OnUpdate or roster scan.')

# Always-visible group bar works solo; solo lock preserves orb clicks but blocks resizing.
lua=setup(); g=lua.globals(); g.now=110; g.PallyPower_UpdateUI()
assert not g.PallyPowerBuffBar.shown and g.PallyPowerSoloBar.shown
check=g.PallyPowerAlwaysBuffBar; check.checked=True; click(lua,check)
g.now=111; g.PallyPower_UpdateUI(); assert g.PallyPowerBuffBar.shown and g.PallyPowerSoloBar.shown
check.checked=False; click(lua,check); g.now=112; g.PallyPower_UpdateUI(); assert not g.PallyPowerBuffBar.shown
orb=g.PallyPowerSoloBar
lock=g.PallyPowerSoloLock; lock.checked=True; click(lua,lock)
assert g.PP_PerUser.soloLocked==1 and orb.movable is False
g.PallyPowerSoloBar_MouseDown('LeftButton'); assert not orb.moving
g.PallyPowerSoloBar_MouseUp('LeftButton'); assert g.PP_PerUser.soloGreater==1
g.PallyPowerSoloBar_MouseDown('RightButton'); g.PallyPowerSoloBar_MouseUp('RightButton'); assert g.PallyPowerFrame.shown
before=orb.scale; g.PallyPowerSoloBar_OnMouseWheel(1); assert orb.scale==before
grip=g.CreateFrame('Button','TestSoloGrip',orb); g.this=grip
g.PallyPower_StartScaling('LeftButton'); assert g.PallyPower.FrameToScale is None
g.PallyPower.FrameToScale=orb; g.PallyPower_ScaleFrame(2); assert orb.scale==before
g.PallyPower_ApplySoloLock(); assert g.PallyPower.FrameToScale is None
g.PP_PerUser.alwaysBuffBar=1
saved=g.Snapshot(g.PP_PerUser); restored=setup(saved); rg=restored.globals()
rg.PallyPower_OptionsFrame.Show(rg.PallyPower_OptionsFrame)
assert rg.PallyPowerAlwaysBuffBar.checked and rg.PallyPowerSoloLock.checked
assert rg.PP_PerUser.alwaysBuffBar==1 and rg.PP_PerUser.soloLocked==1
lock.checked=False; click(lua,lock); g.PallyPowerSoloBar_OnMouseWheel(1); assert orb.scale!=before
print('PASS: solo/group display toggle; solo lock covers move, mouse wheel and shared resizing; orb left/right actions preserved; both options restored from saved settings.')


def position(g):
    orb=g.PallyPowerSoloBar
    ratio=orb.GetEffectiveScale(orb)/g.UIParent.GetEffectiveScale(g.UIParent)
    return (orb.GetLeft(orb)*ratio,orb.GetTop(orb)*ratio)

def same(actual,expected):
    assert all(math.isclose(a,b,rel_tol=1e-9,abs_tol=1e-8) for a,b in zip(actual,expected)),(actual,expected)

position_cases=0
for parent_scale,scale,locked in itertools.product([.64,.8,1],[.5,1,2],[0,1]):
    lua=setup('{scalesolo='+str(scale)+'}',parent_scale); g=lua.globals(); orb=g.PallyPowerSoloBar
    previous_group=g.PP_PerUser.soloGreater
    g.PallyPowerSoloBar_MouseDown('LeftButton'); assert orb.moving
    orb.ClearAllPoints(orb); orb.SetPoint(orb,'TOPLEFT',g.UIParent,'BOTTOMLEFT',233/scale,741/scale)
    g.PallyPowerSoloBar_MouseUp('LeftButton'); assert not orb.moving
    same(position(g),(233,741))
    same((g.PP_PerUser.soloPositionX,g.PP_PerUser.soloPositionY),(233,741))
    assert g.PP_PerUser.soloGreater==previous_group
    # Scale changes maintain position and are persisted independently of dragging.
    for new_scale in [1.4,.7,1.9]:
        g.PallyPower.FrameToScale=orb; g.PallyPower_ScaleFrame(new_scale); g.PallyPower.FrameToScale=None
        same(position(g),(233,741)); assert math.isclose(g.PP_PerUser.scalesolo,new_scale)
        same((g.PP_PerUser.soloPositionX,g.PP_PerUser.soloPositionY),(233,741))
    # Mouse wheel uses the same save path; relog restores position and own scale.
    g.PallyPowerSoloBar_OnMouseWheel(-1); same(position(g),(233,741))
    g.PP_PerUser.soloLocked=locked; g.PallyPower_ApplySoloLock()
    snapshot=g.Snapshot(g.PP_PerUser)
    loaded=setup(snapshot,parent_scale); lg=loaded.globals(); lo=lg.PallyPowerSoloBar
    same(position(lg),(233,741)); assert math.isclose(lo.scale,orb.scale)
    assert lg.PP_PerUser.soloLocked==locked and lo.movable==bool(not locked)
    for ev in ['PLAYER_ENTERING_WORLD','PLAYER_LOGIN','PARTY_MEMBERS_CHANGED']:
        lg.event=ev; lg.PallyPowerExtensionEvents.scripts.OnEvent(); same(position(lg),(233,741))
    # Moving after login must not snap back on a later entering-world event.
    if not locked:
        lg.PallyPowerSoloBar_MouseDown('LeftButton')
        lo.ClearAllPoints(lo); lo.SetPoint(lo,'TOPLEFT',lg.UIParent,'BOTTOMLEFT',412/lo.scale,638/lo.scale)
        lg.event='PLAYER_ENTERING_WORLD'; lg.PallyPowerExtensionEvents.scripts.OnEvent()
        same(position(lg),(412,638)); lg.PallyPowerSoloBar_MouseUp('LeftButton')
        same((lg.PP_PerUser.soloPositionX,lg.PP_PerUser.soloPositionY),(412,638))
    position_cases+=1

# Hiding, locking and logging out during a drag must stop movement and save it.
for action in ['hide','lock','logout']:
    lua=setup(); g=lua.globals(); orb=g.PallyPowerSoloBar
    g.PallyPowerSoloBar_MouseDown('LeftButton')
    orb.ClearAllPoints(orb); orb.SetPoint(orb,'TOPLEFT',g.UIParent,'BOTTOMLEFT',477,693)
    if action=='hide': orb.scripts.OnHide()
    elif action=='lock': g.PP_PerUser.soloLocked=1; g.PallyPower_ApplySoloLock()
    else: g.event='PLAYER_LOGOUT'; g.PallyPowerExtensionEvents.scripts.OnEvent()
    assert not orb.moving and not orb.isMoving
    same((g.PP_PerUser.soloPositionX,g.PP_PerUser.soloPositionY),(477,693))
    restored=setup(g.Snapshot(g.PP_PerUser)); same(position(restored.globals()),(477,693))

# Old/malformed saves retain the XML default; they must not create invalid anchors.
for settings in ['{}','{soloPositionX="bad",soloPositionY=100}',
                 '{soloPositionX=300}', '{soloPositionX=0/0,soloPositionY=100}',
                 '{soloPositionX=math.huge,soloPositionY=100}']:
    lua=setup(settings); g=lua.globals(); orb=g.PallyPowerSoloBar
    assert orb.point[1]=='CENTER'
assert setup('{soloPositionX=0,soloPositionY=0}').globals().PallyPowerSoloBar.point[1]=='TOPLEFT'

# Settings entry must retain appearance, class assignments and personal overrides.
lua=setup('{barBackgroundAlpha=.27,barLocked=1,soloLocked=1,alwaysBuffBar=1,soloPositionX=244,soloPositionY=744}')
g=lua.globals(); saved=g.Snapshot(g.PP_PerUser); assignments=g.Snapshot(g.PallyPower_Assignments)
g.this=g.PallyPowerFrameOptions
assert g.PallyPower_Options() and g.PallyPower_OptionsFrame.shown
assert g.Snapshot(g.PP_PerUser)==saved and g.Snapshot(g.PallyPower_Assignments)==assignments
same(position(g),(244,744))
assert g.PallyPowerExtensionEvents.scripts.OnUpdate is None
print(f'PASS: {position_cases} relog cases across UI/orb scales and lock states; scale/wheel position preservation; entering-world does not reset moved positions; interrupted drags saved on hide/lock/logout; old/corrupt saves safe; restored Options preserves other settings.')


# Reproduce the reported group-position loss against the previous installed source.
patched_read=read
def read_previous(name):
    path=work/'original'/name
    return path.read_text(encoding='utf-8-sig') if path.exists() else patched_read(name)
read=read_previous
lua=setup(); g=lua.globals(); bar=g.PallyPowerBuffBar
g.this=g.PallyPowerBuffBarTitle; g.arg1='LeftButton'
g.PallyPowerBuffBar_MouseDown('LeftButton')
bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',331,762)
g.PallyPowerBuffBar_MouseUp('LeftButton')
assert g.PP_PerUser.barPositionX is None and g.PP_PerUser.barPositionY is None
restored=setup(g.Snapshot(g.PP_PerUser)); rb=restored.globals().PallyPowerBuffBar
assert (rb.GetLeft(rb),rb.GetTop(rb))!=(331,762)
read=patched_read
print('PASS: previous installed source reproduces group-frame position loss after a fresh runtime.')

def bar_position(g):
    bar=g.PallyPowerBuffBar
    ratio=bar.GetEffectiveScale(bar)/g.UIParent.GetEffectiveScale(g.UIParent)
    return (bar.GetLeft(bar)*ratio,bar.GetTop(bar)*ratio)

cases=0
for parent_scale,scale,locked in itertools.product([.64,.8,1],[.5,1,2],[0,1]):
    lua=setup('{scalebar='+str(scale)+',barBackgroundAlpha=.32,alwaysBuffBar=1}',parent_scale)
    g=lua.globals(); bar=g.PallyPowerBuffBar
    # Title and blank-area native mouse-up routes both save, without opening distribution.
    for anchor,x,y in [(g.PallyPowerBuffBarTitle,335,773),(bar,351,728)]:
        g.this=anchor; g.arg1='LeftButton'; g.PallyPowerBuffBar_MouseDown('LeftButton')
        assert bar.moving
        bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',x/scale,y/scale)
        anchor.scripts.OnMouseUp()
        assert not bar.moving and not g.PallyPowerFrame.shown
        same(bar_position(g),(x,y)); same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(x,y))
    for new_scale in [1.4,.7,1.9]:
        g.PallyPower.FrameToScale=bar; g.PallyPower_ScaleFrame(new_scale); g.PallyPower.FrameToScale=None
        same(bar_position(g),(351,728)); assert math.isclose(g.PP_PerUser.scalebar,new_scale)
    # Dynamic height changes must keep the top-left stationary.
    for height in [64,302,370,98]:
        bar.SetHeight(bar,height); same(bar_position(g),(351,728))
    g.PP_PerUser.barLocked=locked; g.PallyPower_ApplyBuffBarAppearance()
    snapshot=g.Snapshot(g.PP_PerUser)
    loaded=setup(snapshot,parent_scale); lg=loaded.globals(); lb=lg.PallyPowerBuffBar
    same(bar_position(lg),(351,728)); assert math.isclose(lb.scale,bar.scale)
    assert lb.movable==bool(not locked) and lg.PP_PerUser.barLocked==locked
    assert lg.PP_PerUser.barBackgroundAlpha==.32 and lg.PP_PerUser.alwaysBuffBar==1
    for ev in ['PLAYER_ENTERING_WORLD','PLAYER_LOGIN','RAID_ROSTER_UPDATE','PARTY_MEMBERS_CHANGED']:
        lg.event=ev; lg.PallyPowerExtensionEvents.scripts.OnEvent(); same(bar_position(lg),(351,728))
    lg.now=110; lg.PallyPower_UpdateUI(); same(bar_position(lg),(351,728))
    # Skin callbacks and settings controls must never change frame location.
    lg.PallyPower_OptionsFrame.Show(lg.PallyPower_OptionsFrame)
    lg.PallyPowerBuffBarTransparency.SetValue(lg.PallyPowerBuffBarTransparency,70)
    loaded.execute(read('pfUI-addonskinner/skins/PallyPower.lua')); lg.pfUI.addonskinner.callback()
    same(bar_position(lg),(351,728))
    # Locked resize remains blocked, and later entering-world cannot reset a new drag.
    lg.PallyPower.FrameToScale=lb; before_scale=lb.scale
    if locked:
        lg.PallyPower_ScaleFrame(2.5); assert lb.scale==before_scale
        lg.PallyPower.FrameToScale=None; lg.PallyPowerBuffBar_MouseDown('LeftButton'); assert not lb.moving
    else:
        lg.PallyPower.FrameToScale=None; lg.this=lb; lg.arg1='LeftButton'
        lg.PallyPowerBuffBar_MouseDown('LeftButton')
        lb.ClearAllPoints(lb); lb.SetPoint(lb,'TOPLEFT',lg.UIParent,'BOTTOMLEFT',457/lb.scale,659/lb.scale)
        lg.event='PLAYER_ENTERING_WORLD'; lg.PallyPowerExtensionEvents.scripts.OnEvent()
        same(bar_position(lg),(457,659)); lg.PallyPowerBuffBar_MouseUp('LeftButton')
        same((lg.PP_PerUser.barPositionX,lg.PP_PerUser.barPositionY),(457,659))
    cases+=1

for action in ['hide','lock','logout']:
    lua=setup(); g=lua.globals(); bar=g.PallyPowerBuffBar
    g.PallyPowerBuffBar_MouseDown('LeftButton')
    bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',482,698)
    if action=='hide': bar.scripts.OnHide()
    elif action=='lock': g.PP_PerUser.barLocked=1; g.PallyPower_ApplyBuffBarAppearance()
    else: g.event='PLAYER_LOGOUT'; g.PallyPowerExtensionEvents.scripts.OnEvent()
    assert not bar.moving and not bar.isMoving
    same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(482,698))
    loaded=setup(g.Snapshot(g.PP_PerUser)); same(bar_position(loaded.globals()),(482,698))

# Startup hides before restoration cannot overwrite a saved position; event order is safe.
for core_first in [True,False]:
    lua=setup('{barPositionX=318,barPositionY=748,scalebar=1.6}',.8,False); g=lua.globals()
    g.PallyPowerBuffBar.scripts.OnHide()
    same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(318,748))
    if core_first: g.PallyPower_UpdateUI()
    g.event='PLAYER_LOGIN'; g.PallyPowerExtensionEvents.scripts.OnEvent()
    if not core_first: g.PallyPower_UpdateUI()
    same(bar_position(g),(318,748))
for saved in ['{}','{barPositionX="bad",barPositionY=100}',
              '{barPositionX=300}', '{barPositionX=0/0,barPositionY=100}',
              '{barPositionX=math.huge,barPositionY=100}']:
    lua=setup(saved); assert lua.globals().PallyPowerBuffBar.point is None
lua=setup('{barPositionX=0,barPositionY=0}'); same(bar_position(lua.globals()),(0,0))

# Group and solo coordinates are stored independently across logout/relogin.
lua=setup('{barPositionX=234,barPositionY=634,soloPositionX=478,soloPositionY=878,scalebar=.8,scalesolo=1.4}')
g=lua.globals(); g.event='PLAYER_LOGOUT'; g.PallyPowerExtensionEvents.scripts.OnEvent()
loaded=setup(g.Snapshot(g.PP_PerUser)); lg=loaded.globals()
same(bar_position(lg),(234,634)); same(position(lg),(478,878))
assert lg.PallyPowerExtensionEvents.scripts.OnUpdate is None
print(f'PASS: {cases} group-frame reload/relogin cases across UI scales, own scales and locks; title/blank drag saves; resize and roster-height changes retain position; settings/skin preserve location; interrupted drags and login order safe; invalid/old saves and independent solo coordinates retained. No added per-frame work.')
