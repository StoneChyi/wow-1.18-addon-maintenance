"""Cooline time-axis, centered packing, scan, settings and cast regressions.

Uses the existing ignored Lua 5.1 runtime; exercises the actual addon files.
"""
from pathlib import Path
import random
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

FILES = [ROOT / 'Interface/AddOns/Cooline' / f for f in ['settings.lua', 'Cooline.lua']]
FONT_CONTRACT = ROOT / 'Tools/tests/wow112_fontstring_mock.lua'
STUB = r'''
local installFontContract = ...
objects={}; names={}; now=100; spells={}; bags={}; inventory={}; hooks={}
BOOKTYPE_SPELL='spell'; UISpecialFrames={}; SlashCmdList={}; shift=false
min=math.min; max=math.max; floor=math.floor; random=math.random
tinsert=table.insert; tremove=table.remove; strfind=string.find; strupper=string.upper
local methods={}
function newObject(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,width=0,height=0,shown=true,alpha=1,level=1,scripts={},points={}}, {__index=methods})
 table.insert(objects,o)
 if name then _G[name]=o;names[name]=o end
 return o
end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function methods:EnableMouse(v) self.mouse=v end
function methods:RegisterForDrag(...) self.drags={...} end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetMovable(v) end
function methods:SetClampedToScreen(v) end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:SetWidth(v) assert(type(v)=='number' and v>=0);self.width=v end
function methods:SetHeight(v) assert(type(v)=='number' and v>=0);self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetPoint(...)
 local args={...};assert(#args>=3,'1.12 SetPoint needs offsets')
 self.points[args[1]]=args;self.point=args
end
function methods:GetPoint() return unpack(self.point or {'CENTER',UIParent,'CENTER',0,0}) end
function methods:ClearAllPoints() self.points={};self.point=nil end
function methods:SetAllPoints(p) self.allpoints=p end
local anchor={CENTER={0,0},LEFT={-.5,0},RIGHT={.5,0},TOP={0,.5},BOTTOM={0,-.5},TOPLEFT={-.5,.5},TOPRIGHT={.5,.5},BOTTOMLEFT={-.5,-.5},BOTTOMRIGHT={.5,-.5}}
function methods:GetCenter()
 if self==UIParent then return 960,540 end
 local p=self.point
 if not p then return 0,0 end
 local own,relative,target,x,y
 if #p==3 then own,relative,target,x,y=p[1],self.parent or UIParent,p[1],p[2],p[3]
 else own,relative,target,x,y=unpack(p) end
 local rx,ry=relative:GetCenter();local a,b=anchor[own],anchor[target]
 return rx+b[1]*relative.width+x-a[1]*self.width,ry+b[2]*relative.height+y-a[2]*self.height
end
function methods:Show()
 local was=self.shown;self.shown=true
 if not was and self.scripts.OnShow then invoke(self,'OnShow') end
end
function methods:Hide()
 self.hides=(self.hides or 0)+1
 local was=self.shown;self.shown=false
 if was and self.scripts.OnHide then invoke(self,'OnHide') end
end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetFrameLevel(v) assert(v>=0);self.level=v end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetBackdrop(v) self.backdropSpec=v end
function methods:SetBackdropColor(...) self.color={...} end
function methods:SetBackdropBorderColor(...) end
function methods:SetTexture(...) self.texture=(...);self.textureArgs={...} end
function methods:GetTexture() return self.texture end
function methods:SetTexCoord(...) end
function methods:SetVertexColor(...) self.vertexColor={...} end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetShadowColor(...) end
function methods:SetShadowOffset(...) end
function methods:SetJustifyH(...) end
function methods:GetText() return self.text end
function methods:GetStringWidth() return #(self.text or '')*5 end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetMinMaxValues(low,high) self.low,self.high=low,high end
function methods:SetValueStep(v) self.step=v end
function methods:SetValue(v)
 self.value=math.max(self.low,math.min(self.high,v))
 if self.scripts.OnValueChanged then invoke(self,'OnValueChanged') end
end
function methods:GetValue() return self.value end
function methods:CreateTexture(name,...) return newObject('Texture',name,self) end
installFontContract(methods, newObject)
function methods:SetOwner(o,a) self.owner=o end
function methods:IsOwned(o) return self.owner==o and self.shown end
function methods:ClearLines() self.lines={} end
function methods:AddDoubleLine(a,b,...) table.insert(self.lines,{a,b}) end
function methods:AddMessage(msg) end
function methods:SetAction(slot) CoolineZMD_ScanTipTextLeft1:SetText('SpellA') end
function CreateFrame(kind,name,parent,template)
 local obj=newObject(kind,name,parent or UIParent)
 if template=='GameTooltipTemplate' then obj:CreateFontString(name..'TextLeft1','OVERLAY','GameFontNormal') end
 return obj
end
function invoke(o,event,...)
 local oldthis,oldevent,oldarg1,oldarg2,oldarg3,oldarg4=this,_G.event,arg1,arg2,arg3,arg4
 this=o;_G.event=event;arg1,arg2,arg3,arg4=unpack({...})
 if o.scripts[event] then o.scripts[event](...) end
 this,_G.event,arg1,arg2,arg3,arg4=oldthis,oldevent,oldarg1,oldarg2,oldarg3,oldarg4
end
function fire(o,e,...)
 local prev=_G.event;_G.event=e
 local old1,old2,old3,old4=arg1,arg2,arg3,arg4
 arg1,arg2,arg3,arg4=unpack({...});this=o;o.scripts.OnEvent()
 arg1,arg2,arg3,arg4=old1,old2,old3,old4;_G.event=prev
end
UIParent=newObject('Frame','UIParent');UIParent.width=1920;UIParent.height=1080
GameTooltip=newObject('GameTooltip','GameTooltip');GameTooltip:Hide()
DEFAULT_CHAT_FRAME=newObject('Frame','DEFAULT_CHAT_FRAME')
resolution='1920x768'
function GetCVar(name) assert(name=='gxResolution');return resolution end
function GetTime() return now end
function IsShiftKeyDown() return shift end
function GetContainerNumSlots(b) return bags[b] and #bags[b] or 0 end
function GetContainerItemLink(b,s) return bags[b][s].link end
function GetContainerItemInfo(b,s) return bags[b][s].texture end
function GetContainerItemCooldown(b,s) local x=bags[b][s];return x.start or 0,x.duration or 0,x.enabled or 1 end
function GetInventoryItemLink(u,s) return inventory[s] and inventory[s].link end
function GetInventoryItemTexture(u,s) return inventory[s] and inventory[s].texture end
function GetInventoryItemCooldown(u,s) local x=inventory[s] or {};return x.start or 0,x.duration or 0,x.enabled or 1 end
function GetSpellName(id) return spells[id] and spells[id].name end
function GetSpellTexture(id) return spells[id] and spells[id].texture end
function GetSpellCooldown(id) local x=spells[id] or {};return x.start or 0,x.duration or 0,x.enabled or 1 end
function UnitExists(u) return true,'player-guid' end
function IsPassiveSpell(id) return false end
function GetSpellNameAndRankForId(id) return spells[id] and spells[id].name end
function hooksecurefunc(name,callback) hooks[name]=callback end
function GetActionText(slot) return nil end
function activeFrames()
 local out={}
 for _,o in ipairs(objects) do
  if o.parent==cooline and o.icon and o.shown then table.insert(out,o) end
 end
 table.sort(out,function(a,b) return a.end_time==b.end_time and a.name<b.name or a.end_time<b.end_time end)
 return out
end
function allTimers()
 local out={}
 for _,o in ipairs(objects) do if o.parent==cooline and o.icon then table.insert(out,o) end end
 return out
end
function pfEnvironment()
 return {
  StripTextures=function(o) end,
  CreateBackdrop=function(o) o.backdrop=newObject('Frame',nil,o) end,
  SkinButton=function(o) end,SkinCheckbox=function(o) end,SkinSlider=function(o) end,
  SkinCloseButton=function(o) end
 }
end
'''

def new(saved=None, pf=False, superwow=True, saved_zmd=None, theme_font=None):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB, lua.execute(FONT_CONTRACT.read_text(encoding='utf-8')))
    if not superwow:
        lua.execute('GetSpellNameAndRankForId=nil')
    if pf:
        lua.execute('pfUI={GetEnvironment=pfEnvironment}')
    for file in FILES:
        lua.execute(file.read_text(encoding='utf-8-sig'))
    if theme_font:
        lua.globals().cooline_theme.font=theme_font
        lua.globals().failedFontPaths[theme_font]=True
    if saved:
        lua.globals().cooline_settings=lua.table_from(saved,recursive=True)
    if saved_zmd:
        lua.globals().CoolineZMDDB=lua.table_from(saved_zmd,recursive=True)
    lua.globals().cooline.VARIABLES_LOADED()
    lua.execute("fire(ZMD_anchor,'PLAYER_LOGIN')")
    return lua

def equal(lua,a,b):
    return lua.eval('function(a,b) return a==b end')(a,b)

def frames(lua):
    return list(lua.globals().activeFrames().values())

def add(lua,name,left):
    lua.globals().cooline.start_cooldown(name,'icon-'+name,lua.globals().now,left,True)

checks=0
def check(name,fn):
    global checks
    fn(); checks+=1; print('PASS',name)

def assert_internal_marks(lua):
    g=lua.globals();cl=g.cooline;vertical=g.cooline_theme.vertical
    cx,cy=cl.GetCenter(cl)
    physical_height=float(g.resolution.split('x')[-1])
    pixel=768/physical_height/cl.GetEffectiveScale(cl)
    for i,mark in cl.tick_marks.items():
        x,y=mark.GetCenter(mark)
        assert mark.shown and mark.alpha==1
        assert abs(x-cx)+mark.width/2 <= cl.width/2+1e-8
        assert abs(y-cy)+mark.height/2 <= cl.height/2+1e-8
        assert abs((mark.height if vertical else mark.width)/pixel-1)<1e-8
        for edge in [x-mark.width/2,x+mark.width/2,y-mark.height/2,y+mark.height/2]:
            assert abs(edge/pixel-round(edge/pixel))<1e-7
        position=cl.time_position(cl.axis_times[i])
        if g.cooline_theme.reverse:position=cl.length-position
        actual=(y-cy if vertical else x-cx)+cl.length/2
        allowance=1.5 if i in [1,7] else .500001
        assert abs(actual-position)<=allowance*pixel+1e-8
        assert list(mark.textureArgs.values())==[154/255,181/255,187/255,.7]
        span=(mark.width if vertical else mark.height)/pixel
        assert span>=1-1e-8
        if cl.thickness/pixel>=6:
            origin=(cx-cl.width/2) if vertical else (cy-cl.height/2)
            edge=(x-mark.width/2) if vertical else (y-mark.height/2)
            end=(x+mark.width/2) if vertical else (y+mark.height/2)
            assert 2-1e-8 <= (edge-origin)/pixel < 3+1e-8
            assert 2-1e-8 <= (origin+cl.thickness-end)/pixel < 3+1e-8


def axis():
    lua=new();g=lua.globals();cl=g.cooline;theme=g.cooline_theme
    assert theme.max_time==600
    for horizon in [60,180,300,600,900,1800]:
        theme.max_time=horizon;cl.apply_theme();assert_internal_marks(lua)
        assert abs(cl.time_position(horizon)-cl.length)<1e-8
        for i,t in cl.axis_times.items():
            assert abs(cl.time_position(t)-cl.axis_positions[i]*cl.length)<1e-8
        last=-1
        for i in range(1001):
            p=cl.time_position(horizon*i/1000)
            assert p>=last and 0<=p<=cl.length
            last=p
        for t in list(cl.axis_times.values())[1:-1]:
            assert abs(cl.time_position(t-.00001)-cl.time_position(t+.00001))<.01
    for horizon in [600,900,1800]:
        theme.max_time=horizon;cl.apply_theme()
        assert cl.time_position(30)==cl.length*.5
        assert cl.time_position(180)==cl.length*.83
    theme.max_time=600;cl.apply_theme();add(lua,'Long',601);cl.on_update(True)
    assert not frames(lua)
    g.now+=1;cl.on_update(True);assert len(frames(lua))==1
    g.now+=601;cl.on_update(True);assert not frames(lua)
check('six ranges are continuous, exact and prioritize short cooldowns; range entry/expiry',axis)

def centered():
    for n in [1,2,3,4,12]:
        for vertical in [False,True]:
            for reverse in [False,True]:
                lua=new();g=lua.globals();cl=g.cooline;t=g.cooline_theme
                t.vertical=vertical;t.reverse=reverse;t.width=18 if vertical else 200;t.height=200 if vertical else 18
                cl.apply_theme()
                for i in range(n):add(lua,'S'+str(i),10+i*.01)
                cl.on_update(True);fs=frames(lua)
                assert len(fs)==min(n,3)
                size=22 if n==1 else 16
                offsets=[]
                for f in fs:
                    assert f.width==f.height==size
                    assert equal(lua,f.parent,cl)
                    p=f.point
                    axis=float(p[5] if vertical else p[4]);cross=float(p[4] if vertical else p[5]);offsets.append(cross)
                    expected=cl.time_position(f.end_time-g.now)
                    if reverse: expected=cl.length-expected
                    assert abs(axis-expected)<1e-8
                    assert f.guide.shown==(cross!=0)
                assert abs(min(offsets)+max(offsets))<1e-8,(n,vertical,reverse,offsets)
                assert sum(len(f.members) for f in fs)==n
                assert not fs[0].count.text # nearest cooldown remains separate
                for i,a in enumerate(fs):
                    ax,ay=a.GetCenter(a)
                    for b in fs[i+1:]:
                        bx,by=b.GetCenter(b)
                        assert abs(ax-bx)>=size+2-1e-7 or abs(ay-by)>=size+2-1e-7
                old={f.name:f.layout_lane for f in fs}
                g.now+=.05;cl.on_update(True)
                assert {f.name:f.layout_lane for f in frames(lua)}==old
                # Tooltip lists all members with live remaining times.
                for f in fs:
                    cl.show_tooltip(f)
                    assert len(g.GameTooltip.lines)==len(f.members)
    # Shrinking alone can resolve a collision, without shifting a group off center.
    lua=new();g=lua.globals();add(lua,'A',10);add(lua,'B',23);g.cooline.on_update(True)
    fs=frames(lua);assert len(fs)==2
    assert all(f.point[5]==0 for f in fs)
check('20 centered/shrunk layouts retain exact times, stable lanes and readable groups',centered)

def randomized_layout():
    rng=random.Random(918)
    for mode in ['lanes','overlap','compact']:
        for rows in [1,2,3]:
            for vertical in [False,True]:
                lua=new();g=lua.globals();t=g.cooline_theme;cl=g.cooline
                t.layout=mode;t.max_rows=rows;t.vertical=vertical;t.icon_size=rng.choice([12,22,40])
                t.width=18 if vertical else 200;t.height=200 if vertical else 18;cl.apply_theme()
                times=[.3+i*.03 for i in range(8)]+[rng.uniform(5,590) for _ in range(35)]
                for i,left in enumerate(times):add(lua,'S%02d'%i,left)
                for width in [50,120,200,400]:
                    if vertical:t.height=width
                    else:t.width=width
                    cl.apply_theme();fs=frames(lua)
                    assert sum(len(f.members) for f in fs)==len(times)
                    if mode=='overlap': assert len(fs)==len(times)
                    for i,a in enumerate(fs):
                        if mode=='overlap':break
                        ax,ay=a.GetCenter(a)
                        for b in fs[i+1:]:
                            bx,by=b.GetCenter(b)
                            assert abs(ax-bx)>=(a.width+b.width)/2+2-1e-6 or abs(ay-by)>=(a.height+b.height)/2+2-1e-6
check('72 dense layouts with 12/22/40px icons at four lengths preserve every timer and avoid overlap',randomized_layout)

def saved_and_resize():
    lua=new({'x':31,'y':-123,'flash_enabled':False,'show_cooline':False,
             'theme':{'width':320,'height':24,'reverse':True,'max_time':1800,'icon_size':28,'max_rows':2}})
    g=lua.globals();cl=g.cooline;t=g.cooline_theme
    assert t.width==320 and t.height==24 and t.max_time==1800 and t.reverse
    assert not cl.shown and not g.cooline_settings.flash_enabled
    add(lua,'Resize',20);cl.on_update(True)
    t.width=390;t.icon_size=30;cl.apply_theme()
    f=frames(lua)[0];assert f.width==30 and cl.width==390
    assert abs(f.point[4]-(390-cl.time_position(20)))<1e-8
    assert cl.ticks[7].point[4]==0 # reverse endpoint moved immediately
    t.vertical=True;t.width=24;t.height=390;cl.apply_theme()
    assert cl.height==390 and cl.width==24 and f.point[3]=='BOTTOM'
    assert g.ZMD_anchor.width==390 and g.ZMD_anchor.height==24
    saved={k:v for k,v in g.cooline_settings.items() if k!='theme'}
    saved['theme']=dict(g.cooline_settings.theme.items())
    again=new(saved);a=again.globals()
    for key,value in saved['theme'].items():assert a.cooline_theme[key]==value
    assert a.cooline_settings.x==31 and a.cooline_settings.y==-123
    # Legacy and malformed preferences recover without losing position or flags.
    for saved in [{'x':10,'y':20}, {'x':float('nan'),'y':'bad','theme':{'vertical':'x','width':False,'height':float('inf'),'max_rows':9,'max_time':False,'layout':'bad','icon_size':-1}}]:
        a=new(saved).globals();assert a.cooline_theme.max_time==600
        assert 12<=a.cooline_theme.icon_size<=40 and 1<=a.cooline_theme.max_rows<=3
check('dimensions, ticks, orientation and saved preferences survive reload/malformed legacy data',saved_and_resize)

def scanning():
    lua=new();g=lua.globals();cl=g.cooline
    lua.execute('''
spells={{name='Ranks',start=100,duration=60,texture='spell'}, {name='Ranks',duration=0}, {name='Shared',start=100,duration=30}}
bags[0]={{link='|Hitem:1:0:0:0|h[Shared]|h',start=100,duration=90},
 {link='|Hitem:2:0:0:0|h[Shared]|h',duration=0}, {},
 {link='|Hitem:3:0:0:0|h[LongItem]|h',start=100,duration=7200},
 {link='|Hitem:4:0:0:0|h[炉石]|h',start=100,duration=3600}}
cooline.detect_cooldowns()
''')
    fs=frames(lua);assert len(fs)==3 and sum(f.name=='Shared' for f in fs)==2
    assert cl.hyperlink_name(None) is None and cl.hyperlink_name('bad') is None
    cl.start_cooldown(None,'bad',100,10,True)
    lua.execute("spells[1].duration=0;cooline.detect_cooldowns()")
    assert all(f.name!='Ranks' for f in frames(lua))
    lua.execute("bags[0]={};cooline.detect_item_cooldowns();now=6700;cooline.on_update(true)")
    assert any(f.name=='LongItem' for f in frames(lua))
    lua.execute("now=7301.1;cooline.on_update(true)")
    assert not frames(lua)
    # Empty spellbook is safe; global cooldowns do not create icons.
    lua.execute("spells={};cooline.detect_spell_cooldowns();spells={{name='GCD',start=now,duration=1.5}};cooline.detect_cooldowns()")
    assert not frames(lua)
check('scan aggregation, spell/item isolation, nil links, resets, consumed items and >1h items',scanning)

def events_and_expiry():
    lua=new();g=lua.globals();cl=g.cooline
    lua.execute('''
calls=0; originalScan=cooline.detect_spell_cooldowns
cooline.detect_spell_cooldowns=function() calls=calls+1;originalScan() end
cooline.request_spell_rescan()
now=100.05;cooline.request_spell_rescan()
now=100.09;cooline.request_spell_rescan();invoke(cooline.rescan_timer,'OnUpdate')
assert(calls==0)
now=100.101;cooline.request_spell_rescan();invoke(cooline.rescan_timer,'OnUpdate')
assert(calls==1 and not cooline.rescan_timer.shown)
''')
    add(lua,'Expire',3);cl.on_update(True);g.now+=3
    cl.detect_spell_cooldowns() # absent expired spell should still fade/flash
    cl.on_update(True);assert cl.flash.shown
    g.now+=.5;cl.on_update(True);f=frames(lua)[0];assert abs(f.alpha-.5)<1e-8
    g.now+=.6;cl.on_update(True);assert not frames(lua)
    # Pool reuse resets fading, grouping and flash state.
    add(lua,'Reuse',20);cl.on_update(True);f=frames(lua)[0]
    assert f.alpha==1 and f.count.text=='' and not f.flashed
    assert f.color[1]==g.cooline_theme.spellcolor[1]
    g.now+=18;cl.on_update(True);assert f.color[1]==1 and f.color[2]==.82
    g.cooline_settings.show_cooline=False;cl.set_shown(False)
    assert not f.IsVisible(f)
    g.now+=2.01;lua.execute("invoke(cooline.driver,'OnUpdate')")
    assert f.flashed # independent driver continues when main frame is hidden
    g.now+=2;lua.execute("invoke(cooline.driver,'OnUpdate')");assert not frames(lua)
check('bounded event batching, one-shot expiry, fade, pool reuse, threshold and hidden driver',events_and_expiry)

def panel():
    for pf in [False,True]:
        lua=new(pf=pf);g=lua.globals();lua.execute("SlashCmdList.COOLINECONFIG()")
        panel=g.CoolineConfigPanel
        assert panel.height==624 and panel.shown
        assert 'CoolineConfigPanel' in list(g.UISpecialFrames.values())
        buttons=[o for o in g.objects.values() if o.kind=='Button' and equal(lua,o.parent,panel) and o.width>0 and o.height>0]
        for i,a in enumerate(buttons):
            ax,ay=a.GetCenter(a)
            for b in buttons[i+1:]:
                bx,by=b.GetCenter(b)
                assert abs(ax-bx)>=(a.width+b.width)/2 or abs(ay-by)>=(a.height+b.height)/2, (a.text,b.text)
        for o in g.objects.values():
            if equal(lua,o.parent,panel) and o.point:
                x,y=o.GetCenter(o);px,py=panel.GetCenter(panel)
                assert abs(y-py)<=panel.height/2,(o.name,o.text,y,py)
        # Locate controls by their actual values/ranges, not generated names.
        sliders=[o for o in g.objects.values() if o.kind=='Slider']
        length=next(o for o in sliders if o.high==400)
        rows=next(o for o in sliders if o.high==3)
        length.SetValue(length,333.3);assert g.cooline.width==333
        rows.SetValue(rows,1.8);assert g.cooline_theme.max_rows==2
        cbs=[o for o in g.objects.values() if o.kind=='CheckButton']
        cbs[2].SetChecked(cbs[2],True);g.invoke(cbs[2],'OnClick')
        assert g.cooline.height==333 and g.cooline.width==18 and length.value==333
        # Changing external settings is reflected when the panel is reopened.
        panel.Hide(panel);g.cooline_settings.flash_enabled=False
        lua.execute('SlashCmdList.COOLINECONFIG()');assert not cbs[1].checked
        # All three choice controls cycle and persist without callbacks on refresh.
        choices=[o for o in g.objects.values() if o.kind=='Button' and equal(lua,o.parent,panel) and o.text and o.text.endswith(' >')]
        assert len(choices)==2
        for choice in choices:g.invoke(choice,'OnClick')
        assert g.cooline_theme.max_time==900 and g.cooline_theme.layout=='overlap'
        before=dict(g.cooline_settings.theme.items());lua.execute('SlashCmdList.COOLINECONFIG();SlashCmdList.COOLINECONFIG()')
        assert before==dict(g.cooline_settings.theme.items())
        g.shift=False;g.cooline.begin_drag();assert not g.cooline.dragging
        g.shift=True;g.cooline.begin_drag();assert g.cooline.dragging
        g.cooline.end_drag();assert not g.cooline.dragging
check('settings panel with/without pfUI, sizing, orientation, rounding, choices, refresh and Shift drag',panel)

def cast_history():
    lua=new();g=lua.globals()
    lua.execute("spells={{name='SpellA',texture='cast-icon'}};fire(ZMD_anchor,'SPELLS_CHANGED');CoolineZMDDB.sameCD=0;CoolineZMDDB.castStage='start'")
    lua.execute("fire(ZMD_anchor,'UNIT_CASTEVENT','player-guid',nil,'START',1);now=103;fire(ZMD_anchor,'UNIT_CASTEVENT','player-guid',nil,'CAST',1)")
    icons=[o for o in g.objects.values() if equal(lua,o.parent,g.ZMD_anchor) and o.tex and o.shown]
    assert len(icons)==1
    lua.execute("CoolineZMDDB.enabled=false;ZMD_ApplyEnabled();now=200;CoolineZMDDB.enabled=true;ZMD_ApplyEnabled()")
    assert not any(o.shown for o in icons)
    lua.execute("CoolineZMDDB.castStage='finish';fire(ZMD_anchor,'UNIT_CASTEVENT','player-guid',nil,'START',1)")
    assert not any(o.shown for o in icons)
    lua.execute("fire(ZMD_anchor,'UNIT_CASTEVENT','other-guid',nil,'CAST',1)")
    assert not any(o.shown for o in icons)
    lua.execute("fire(ZMD_anchor,'UNIT_CASTEVENT','player-guid',nil,'CAST',1)")
    assert len([o for o in g.objects.values() if equal(lua,o.parent,g.ZMD_anchor) and o.tex and o.shown])==1
    lua.execute("CoolineZMDDB.name=true;ZMD_ApplyName()")
    assert all(o.nameText.shown for o in icons)
    # Native fallback remains operational and disabled hooks do not defer casts.
    lua=new(superwow=False);g=lua.globals()
    lua.execute("spells={{name='SpellA',texture='cast',start=now,duration=5}};fire(ZMD_anchor,'SPELLS_CHANGED');hooks.CastSpell(1,BOOKTYPE_SPELL)")
    assert any(equal(lua,o.parent,g.ZMD_anchor) and o.tex and o.shown for o in g.objects.values())
    lua.execute("CoolineZMDDB.enabled=false;ZMD_ApplyEnabled();hooks.CastSpell(1,BOOKTYPE_SPELL);CoolineZMDDB.enabled=true;ZMD_ApplyEnabled();invoke(ZMD_anchor,'OnUpdate',.02)")
    assert not any(equal(lua,o.parent,g.ZMD_anchor) and o.tex and o.shown for o in g.objects.values())
check('SuperWoW start/finish deduplication, source filtering, toggle cleanup and native fallback',cast_history)

def history_spacing_and_drag():
    for vertical in [False,True]:
        saved={'theme':{'vertical':vertical,'width':18 if vertical else 200,'height':200 if vertical else 18}}
        lua=new(saved);g=lua.globals()
        _,cy=g.cooline.GetCenter(g.cooline);_,zy=g.ZMD_anchor.GetCenter(g.ZMD_anchor)
        occupied=100 if vertical else g.cooline.label_extent+g.cooline_theme.fontsize+10
        assert zy+g.ZMD_anchor.height/2 < cy-occupied
    # Upgrade only the old default; custom independent screen offsets survive.
    lua=new({'x':31,'y':-123},saved_zmd={'converted_to_ui':True,'relativeOffX':31,'relativeOffY':-143})
    assert lua.globals().CoolineZMDDB.relativeOffY < -143
    lua=new({'x':31,'y':-123},saved_zmd={'converted_to_ui':True,'relativeOffX':77,'relativeOffY':-88})
    g=lua.globals();assert g.CoolineZMDDB.relativeOffX==77 and g.CoolineZMDDB.relativeOffY==-88
    lua.execute("ZMD_anchor:ClearAllPoints();ZMD_anchor:SetPoint('TOPLEFT',UIParent,'CENTER',50,60)")
    before=g.ZMD_anchor.GetCenter(g.ZMD_anchor)
    g.invoke(g.ZMD_anchor,'OnDragStop')
    assert abs(g.CoolineZMDDB.relativeOffX-(before[0]-960))<1e-8
    assert abs(g.CoolineZMDDB.relativeOffY-(before[1]-540))<1e-8
    lua.execute("fire(ZMD_anchor,'PLAYER_LOGIN')")
    assert before==g.ZMD_anchor.GetCenter(g.ZMD_anchor)
check('cast-history default spacing, one-time migration, custom positions and drag/reload coordinates',history_spacing_and_drag)

def close_ticks_and_local_fade():
    for vertical in [False,True]:
        for reverse in [False,True]:
            lua=new({'theme':{'vertical':vertical,'reverse':reverse,
                            'width':18 if vertical else 200,'height':200 if vertical else 18}})
            g=lua.globals();cl=g.cooline;t=g.cooline_theme
            assert_internal_marks(lua)
            coordinates=[]
            for i,fs in cl.ticks.items():
                assert abs(abs(fs.cross_position)-fs.half_cross-cl.thickness/2-4)<1e-8
                assert cl.tick_marks[i].shown
                coordinates.append((fs.axis_position,fs.cross_position))
            if not vertical:assert cl.ticks[2].cross_position==-19
            for rows in [1,2,3]:
                t.max_rows=rows;cl.apply_theme()
                assert coordinates==[(f.axis_position,f.cross_position) for f in cl.ticks.values()]
            for i,name in enumerate(['A','B','C']):add(lua,name,3+i*.01)
            cl.on_update(True)
            tick=cl.ticks[2]
            assert tick.blocked and tick.target_alpha==0
            assert cl.ticks[1].target_alpha==1 and cl.ticks[7].target_alpha==1
            assert coordinates==[(f.axis_position,f.cross_position) for f in cl.ticks.values()]
            g.invoke(cl.driver,'OnUpdate',.05);assert abs(tick.tick_alpha-.5)<1e-8
            g.invoke(cl.driver,'OnUpdate',.05);assert tick.tick_alpha<1e-8
            assert cl.tick_marks[2].shown # text fade never removes the time marker
            for name in ['A','B','C']:cl.clear_cooldown('spell:'+name)
            cl.on_update(True);assert not tick.blocked and tick.target_alpha==1
            cl.animate_ticks(.08);assert abs(tick.tick_alpha-.5)<1e-8
            cl.animate_ticks(.08);assert tick.tick_alpha==1
            # Change length/size/orientation without forcing the numbers outward.
            t.icon_size=40;t.max_rows=3
            if vertical:t.height=400;t.width=36
            else:t.width=400;t.height=36
            cl.apply_theme();assert_internal_marks(lua)
            for fs in cl.ticks.values():
                assert abs(abs(fs.cross_position)-fs.half_cross-cl.thickness/2-4)<1e-8
            # Narrow bars retain all small markers even when some text is omitted.
            if vertical:t.height=50
            else:t.width=50
            cl.apply_theme();assert_internal_marks(lua)
            assert all(m.shown for m in cl.tick_marks.values())
            assert any(not f.fits for f in cl.ticks.values())
            assert cl.ticks[1].fits and cl.ticks[7].fits
    # A small clearance band prevents repeated disappear/reappear at a boundary.
    lua=new();g=lua.globals();cl=g.cooline;add(lua,'Boundary',3);cl.on_update(True)
    f=frames(lua)[0];tick=cl.ticks[2]
    f.cross_position=tick.cross_position
    edge=f.display_size/2+tick.half_axis
    for delta,blocked in [(edge+.5,True),(edge+2,True),(edge+3.5,False)]:
        f.axis_position=tick.axis_position+delta
        cl.update_tick_collisions();assert tick.blocked==blocked
check('four layouts, inset internal dividers, resized bounds, local text fade and collision hysteresis',close_ticks_and_local_fade)

def optional_icon_countdown():
    lua=new();g=lua.globals();cl=g.cooline;t=g.cooline_theme
    assert t.show_countdown is False
    add(lua,'Short',10);cl.on_update(True);f=frames(lua)[0]
    assert not f.timer.shown
    t.show_countdown=True;cl.apply_theme();assert f.timer.shown and f.timer.text=='10'
    for advance,text in [(.01,'10'),(1,'9'),(7.98,'2'),(.02,'1')]:
        g.now+=advance;cl.on_update(True);assert f.timer.text==text
    g.now=110;cl.on_update(True);assert not f.timer.shown and f.timer.text==''
    g.now=112;cl.on_update(True)
    add(lua,'Long',11);cl.on_update(True);f=frames(lua)[0]
    assert not f.timer.shown
    g.now+=1;cl.on_update(True);assert f.timer.text=='10'
    t.show_countdown=False;cl.apply_theme();assert not f.timer.shown
    t.show_countdown=True;t.layout='compact';cl.apply_theme()
    add(lua,'AlsoShort',9);cl.on_update(True)
    representative=frames(lua)[0]
    assert representative.count.text=='+1' and not representative.timer.shown
    # Settings persist both enabled and disabled, including legacy defaults.
    for enabled in [False,True]:
        a=new({'theme':{'show_countdown':enabled}}).globals()
        assert a.cooline_theme.show_countdown==enabled and a.cooline_settings.theme.show_countdown==enabled
    lua=new();g=lua.globals();lua.execute('SlashCmdList.COOLINECONFIG()')
    cb=next(o for o in g.objects.values() if o.kind=='CheckButton' and o.point[5]==-326)
    cb.SetChecked(cb,True);g.invoke(cb,'OnClick')
    assert g.cooline_settings.theme.show_countdown
    assert all(f.timer.shown for f in frames(lua))
check('optional last-ten-second numbers, rounding, expiry, grouped-badge priority and saved checkbox',optional_icon_countdown)

def settings_preview():
    for enabled in [False,True]:
        for pf in [False,True]:
            lua=new({'show_cooline':enabled,'flash_enabled':True},pf=pf)
            g=lua.globals();cl=g.cooline
            before=dict(g.cooline_settings.theme.items())
            lua.execute('flashCalls=0;cooline.show_flash=function() flashCalls=flashCalls+1 end;SlashCmdList.COOLINECONFIG()')
            assert cl.preview_enabled and cl.shown and cl.alpha>0
            assert len(frames(lua))==3 and all(f.name.startswith('预览技能') for f in frames(lua))
            assert g.cooline_settings.show_cooline==enabled
            assert before==dict(g.cooline_settings.theme.items())
            length=next(o for o in g.objects.values() if o.kind=='Slider' and o.high==400)
            length.SetValue(length,350);assert cl.width==350
            assert_internal_marks(lua)
            assert abs(frames(lua)[0].axis_position-cl.time_position(8))<1e-8
            previous_hides=[f.hides for f in frames(lua)]
            g.now+=3600;cl.on_update(True);assert g.flashCalls==0 and len(frames(lua))==3
            assert previous_hides==[f.hides for f in frames(lua)]
            # A visibility toggle in the open panel keeps its preview visible.
            g.cooline_settings.show_cooline=False;cl.set_shown(False);assert cl.shown
            add(lua,'Real',20);cl.on_update(True)
            assert [f.name for f in frames(lua)]==['Real']
            assert all(not f.shown for f in cl.preview_frames.values())
            g.invoke(g.CoolineConfigCloseButton,'OnClick')
            assert not cl.preview_enabled and not cl.shown and g.flashCalls==0
            assert [f.name for f in frames(lua)]==['Real'] # closing did not clear real cooldowns
            cl.clear_cooldown('spell:Real');g.cooline_settings.show_cooline=enabled
            lua.execute('SlashCmdList.COOLINECONFIG()');assert len(frames(lua))==3
            g.CoolineConfigPanel.Hide(g.CoolineConfigPanel) # ESC reaches the same OnHide path
            assert not cl.preview_enabled and cl.shown==enabled
            assert not frames(lua) and cl.alpha==0
check('preview with/without pfUI preserves preferences, resizes live, yields to real CDs and exits cleanly',settings_preview)

def font_contract():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB, lua.execute(FONT_CONTRACT.read_text(encoding='utf-8')))
    lua.execute("""
        local f=UIParent:CreateFontString(nil,'OVERLAY')
        for _,text in ipairs({'', 'text'}) do
            local ok,err=pcall(function() f:SetText(text) end)
            assert(not ok and string.find(err,'SetText(): Font not set',1,true))
        end
        f:Hide()
        assert(not pcall(function() f:SetText('') end))
        failedFontPaths['missing.ttf']=true
        assert(not f:SetFont('missing.ttf',10))
        assert(not f:SetFont('valid.ttf',0))
        assert(not pcall(function() f:SetText('') end))
        assert(f:SetFont('valid.ttf',10))
        f:SetText('');f:SetText('ready')
        assert(not f:SetFont('missing.ttf',10))
        f:SetText('existing font survives failure')
        local inherited=UIParent:CreateFontString(nil,'OVERLAY','GameFontNormal')
        inherited:SetText('template ready')
        local explicit=UIParent:CreateFontString(nil,'OVERLAY')
        explicit:SetFontObject(GameFontHighlightSmall);explicit:SetText('object ready')
        assert(not pcall(function() explicit:SetFontObject({}) end))
        assert(not pcall(function() UIParent:CreateFontString(nil,'OVERLAY','unknown') end))
    """)
check('1.12 font contract rejects empty/hidden uninitialized text and failed font loads',font_contract)

def font_lifecycle():
    for missing in [None, 'MissingConfiguredFont.ttf']:
        lua=new(theme_font=missing);g=lua.globals();cl=g.cooline;t=g.cooline_theme
        fresh=cl.cooldown_frame()
        assert fresh.timer.font and fresh.count.font
        fresh.timer.SetText(fresh.timer,'')
        add(lua,'LongFont',20);cl.on_update(True)
        f=frames(lua)[0];assert not f.timer.shown and f.timer.text==''
        t.show_countdown=True;cl.apply_theme()
        assert not f.timer.shown
        g.now+=11;cl.on_update(True);assert f.timer.shown and f.timer.text=='9'
        t.show_countdown=False;cl.apply_theme();assert not f.timer.shown and f.timer.text==''
        cl.clear_cooldown('spell:LongFont');cl.on_update(True)
        add(lua,'ReusedFont',5);cl.on_update(True)
        assert equal(lua,frames(lua)[0],f) and f.timer.font
        cl.clear_cooldown('spell:ReusedFont');cl.on_update(True)
        lua.execute('SlashCmdList.COOLINECONFIG()')
        assert len(frames(lua))==3
        t.show_countdown=True;cl.apply_theme()
        assert all(frame.timer.shown for frame in frames(lua))
        for text in [o for o in g.objects.values() if o.kind=='FontString']:
            assert text.font, 'every Cooline text control must be initialized'
            if missing:assert text.font[1]!=missing
        g.CoolineConfigPanel.Hide(g.CoolineConfigPanel)
check('font initialization, disabled/long/active/recycled timers, preview and missing-font fallback',font_lifecycle)

def pixel_dividers_and_contrast():
    for vertical in [False,True]:
        for reverse in [False,True]:
            lua=new({'x':.37,'y':-123.23,'theme':{
                'vertical':vertical,'reverse':reverse,
                'width':19 if vertical else 233,'height':233 if vertical else 19}})
            g=lua.globals();cl=g.cooline
            add(lua,'Contrast',20);cl.on_update(True)
            assert cl.alpha==1 and frames(lua)[0].alpha==1
            assert list(cl.bg.vertexColor.values())==[87/255,112/255,122/255,.45]
            assert cl.bg.texture=='Interface\\Buttons\\WHITE8X8'
            assert list(cl.ticks[1].textColor.values())==[216/255,222/255,223/255,1]
            for height in [768,1080,1440]:
                g.resolution=f'2560x{height}'
                for scale in [.64,1,1.25]:
                    g.UIParent.scale=scale
                    cl.on_update(True) # scale/resolution changes also update while settings stay closed
                    assert_internal_marks(lua)
                    old=list(cl.tick_marks.values())
                    cl.SetPoint(cl,'CENTER',g.UIParent,'CENTER',.71,-122.91)
                    cl.on_update(True);assert_internal_marks(lua)
                    assert all(equal(lua,a,b) for a,b in zip(old,cl.tick_marks.values()))
                    # Minimum bar thickness still leaves a visible, aligned divider.
                    if vertical:g.cooline_theme.width=8
                    else:g.cooline_theme.height=8
                    cl.apply_theme();assert_internal_marks(lua)
                    if vertical:g.cooline_theme.width=19
                    else:g.cooline_theme.height=19
                    cl.apply_theme()
            # A drag stop refreshes raster alignment without changing saved logical dimensions.
            g.shift=True;cl.begin_drag();cl.end_drag();assert_internal_marks(lua)
            lua.execute('SlashCmdList.COOLINECONFIG()')
            cl.clear_cooldown('spell:Contrast');cl.on_update(True)
            assert cl.alpha==1 and len(frames(lua))==3
            assert_internal_marks(lua)
            g.CoolineConfigPanel.Hide(g.CoolineConfigPanel)
            assert cl.alpha==0 # original idle visibility is retained
check('36 scale/resolution layouts, thin bars, inset one-pixel dividers and approved mist palette',pixel_dividers_and_contrast)

def original_bytes():
    for path in FILES:
        previous=subprocess.check_output(['git','show','HEAD:'+path.relative_to(ROOT).as_posix()],cwd=ROOT)
        current=path.read_bytes()
        assert previous.startswith(b'\xef\xbb\xbf')==current.startswith(b'\xef\xbb\xbf')
        assert (b'\r\n' in previous)==(b'\r\n' in current)
        if b'\r\n' in previous:assert b'\n' not in current.replace(b'\r\n',b'')
check('source files retain original BOM and newline style',original_bytes)
print(f'{checks} behavior groups passed; 2 Lua source files executed successfully.')
