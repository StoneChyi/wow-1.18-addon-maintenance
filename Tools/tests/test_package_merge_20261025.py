"""Exercise Oct 24 merge decisions against production Lua without game actions.

Supports --addons for the isolated candidate. UI checks enforce real font
initialization and failed SetFont fallback; they are not client acceptance.
"""
from pathlib import Path
import argparse
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
parser=argparse.ArgumentParser()
parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns')
ADDONS=parser.parse_args().addons
def read(path):return (ADDONS/path).read_text(encoding='utf-8-sig')
def function(source,name):
    a=source.index('local function '+name+'(')
    return source[a:source.index('\nend',a)+4]

# A GUID keyed set must not bypass the boss outcome fallback.
r=LuaRuntime(unpack_returned_tuples=True)
r.execute('''
bossGUIDsThisFight={};dead=false;friendly=false;exists=true;playerDead=false
function UnitIsDead(unit) if unit=='player' then return playerDead and 1 end;return dead and 1 end
function UnitExists() return exists end
function UnitCanAssist() return friendly end
''')
boss=r.execute(function(read('ShaguDPS/parser.lua'),'BossClearedFallback')+'\nreturn BossClearedFallback')
assert boss() is False
r.execute("bossGUIDsThisFight={['0xABCD']=true};dead=true")
assert boss() is True
for code,expected in [('dead=false',False),('friendly=true',True),
                      ('friendly=false;exists=false',True),('playerDead=true',False)]:
    r.execute(code);assert boss()==expected
print('PASS: 6 actual BOSS fallback outcomes; GUID dictionaries work; approved new despawn/alive heuristic and dead-player guard')

# Complete pre-heal module: OnUpdate only evaluates, the command consumes ready.
r=LuaRuntime(unpack_returned_tuples=True)
r.execute('''
GoubayuHeal={Config={predict_enabled=1},current_action_profile='A'}
now=100;frames={};dead=false;moving=false
function GetTime() return now end
function GetNampowerVersion() return 1 end
function GetUnitGUID() return 'Ally' end
function UnitExists(unit) return unit=='Ally' end
function UnitIsDeadOrGhost() return dead end
function CreateFrame() local f={scripts={},events={}}
 function f:RegisterEvent(e) self.events[e]=true end
 function f:SetScript(e,fn) self.scripts[e]=fn end
 table.insert(frames,f);return f end
GoubayuHeal.IsMoving=function() return moving end
GoubayuHeal.PlayerDeadBlocked=function() return dead end
''')
r.execute(read('GoubayuHeal/GoubayuHeal_Predict.lua'))
r.execute('''
local p=GoubayuHeal.Predict;casts=0;evaluations=0
p.Cleanup=function() end
p.Evaluate=function(profile) evaluations=evaluations+1;return {unit='Ally',spell='Heal',rank=1,
 profile=profile,at=now,startAt=now,dueTime=now+1} end
p.CastPick=function() casts=casts+1;return true end
p.OnUpdate(.2);assert(evaluations==1 and casts==0 and p.ready.profile=='A')
assert(GoubayuHeal.Predict_TryPreHeal('A') and casts==1 and p.ready==nil)
p.OnUpdate(.2);assert(casts==1)
assert(GoubayuHeal.Predict_TryPreHeal('B') and casts==2 and evaluations==3)
p.OnUpdate(.2);now=103
assert(GoubayuHeal.Predict_TryPreHeal('B') and casts==3 and evaluations==5)
moving=true;p.OnUpdate(.2);assert(not p.ready and not GoubayuHeal.Predict_TryPreHeal('A'))
moving=false;GoubayuHeal.Config.predict_enabled=0;p.OnUpdate(.2)
assert(not p.ready and not GoubayuHeal.Predict_TryPreHeal('A'))
GoubayuHeal.Config.predict_enabled=1;GoubayuHeal._abortAction=true;p.OnUpdate(.2)
assert(not p.ready and not GoubayuHeal.Predict_TryPreHeal('A'))
GoubayuHeal._abortAction=false;dead=true;p.OnUpdate(.2);assert(not p.ready)
dead=false;GoubayuHeal.casting_spell='busy';p.OnUpdate(.2);assert(not p.ready)
GoubayuHeal.casting_spell=nil
p.ready={unit='Ally',spell='Heal',rank=1,profile='A',at=now,startAt=now-2,dueTime=now-2}
assert(not GoubayuHeal.Predict_TryPreHeal('A') and casts==3)
''')
print('PASS: complete pre-heal module, no timer casting, key consumption, profile/expiry/movement/disable/death/abort/busy/late guards')

# The actual first-login migration is run in a fresh environment per character.
src=read('SuperMacro/SuperMacro.lua')
a=src.index('        if ( not SM_MIGRATED_CHAR ) then')
b=src.index('        SuperMacroEnsureSavedTables();',a)
migration=src[a:b]
for key in ['Realm PlayerA','Realm PlayerB']:
    r=LuaRuntime(unpack_returned_tuples=True);r.globals().playerKey=key
    r.execute('''
    function SuperMacroGetPlayerKey() return playerKey end
    SM_SUPER={Example={'Example','Icon','original'}};SM_EXTEND={Script='return 7'}
    SM_ACTION_SUPER={[playerKey]={[4]=2},Other={[6]=1}}
    ''')
    r.execute(migration)
    r.execute('''
    assert(SM_MIGRATED_CHAR==1 and SM_SUPER_CHAR.Example[3]=='original')
    assert(SM_EXTEND_CHAR.Script=='return 7' and SM_ACTION_CHAR[playerKey][4]==2)
    assert(SM_ACTION_CHAR.Other==nil and SM_SUPER.Example~=SM_SUPER_CHAR.Example)
    SM_SUPER_CHAR.Example[3]='character edit';assert(SM_SUPER.Example[3]=='original')
    SM_EXTEND_CHAR.Script='character script';SM_ACTION_CHAR[playerKey][4]=5
    assert(SM_EXTEND.Script=='return 7' and SM_ACTION_SUPER[playerKey][4]==2)
    ''')
    r.execute(migration)
    assert r.eval('SM_SUPER_CHAR.Example[3]')=='character edit'
r=LuaRuntime();r.execute("SM_SUPER_CHAR={Own='keep'};SM_EXTEND_CHAR={Own='keep'};SM_ACTION_CHAR={};SM_SUPER={Old='do not copy'};SM_EXTEND={Old='do not copy'};function SuperMacroGetPlayerKey() return 'x' end")
r.execute(migration)
assert r.eval('SM_SUPER_CHAR.Old') is None and r.eval('SM_EXTEND_CHAR.Old') is None
print('PASS: actual character migration, legacy preservation, independent tables, existing data and idempotence')

# Construct the complete replacement SuperMacro UI with strict font behavior.
r=LuaRuntime(unpack_returned_tuples=True)
r.execute('''
objects={};methods={};SlashCmdList={};UISpecialFrames={};SM_VARS={}
function object(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,width=100,height=20,scripts={},children={}}, {__index=methods})
 if name then _G[name]=o end
 if parent and parent.children then table.insert(parent.children,o) end
 table.insert(objects,o);return o
end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function methods:GetChildren() return unpack(self.children) end
function methods:GetFrameLevel() return self.level or 1 end
function methods:IsShown() return not self.hidden end
function methods:IsVisible() return not self.hidden end
function methods:Show() self.hidden=false end
function methods:Hide() self.hidden=true end
function methods:GetChecked() return self.checked end
function methods:SetChecked(v) self.checked=v end
function methods:GetText() return self.text or '' end
function methods:GetStringWidth() return #(self.text or '')*5 end
function methods:GetStringHeight() return 12 end
function methods:CreateTexture(name) return object('Texture',name,self) end
function methods:GetNormalTexture() return nil end
function methods:GetPushedTexture() return nil end
function methods:GetHighlightTexture() return nil end
function methods:GetCheckedTexture() return nil end
function methods:GetDisabledTexture() return nil end
function methods:GetFontString()
 if not self.label then self.label=self:CreateFontString(nil,'OVERLAY','GameFontNormal') end
 return self.label
end
setmetatable(methods,{__index=function(t,k)
 if not string.find(k,'^[A-Z]') then return nil end
 local f=function() end;rawset(t,k,f);return f end})
function getglobal(name) return _G[name] end
function CreateFrame(kind,name,parent,template) return object(kind,name,parent) end
UIParent=object('Frame','UIParent');WorldFrame=UIParent
GameMenuFrame=object('Frame','GameMenuFrame',UIParent)
GameMenuButtonMacros=object('Button','GameMenuButtonMacros',GameMenuFrame)
Minimap=object('Frame','Minimap',UIParent)
format=string.format;ceil=math.ceil;floor=math.floor
BOOKTYPE_SPELL='spell';MAX_MACROS=120;MAX_CHARACTER_MACROS=18
function TEXT(v) return v or '' end
function PanelTemplates_SetNumTabs() end
function PanelTemplates_SetTab() end
function SM_utf8len(s) return #s end
function SuperMacro_GetRegularMacroMaxLetters() return 255 end
SUPERMACRO_TITLE='SuperMacro';SUPERMACRO_VERSION='3.25';CHARACTER_SPECIFIC_MACROS='%s'
SM_VARS.tabShown='regular'
function UnitName() return 'Player' end
function PanelTemplates_UpdateTabs() end
function SM_UpdateAction() actionHooked=true end
function SuperMacroFrame_SetAccountMacros() accountTabInitialized=true end
function SM_LoadMacroIcons() return {} end
''')
r.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))(r.globals().methods,r.globals().object)
r.execute('''
ChatFontNormal=GameFontNormal
uninitialized=object('FontString')
assert(not pcall(function() uninitialized:SetText('bad') end))
failedFontPaths['Fonts\\\\FRIZQT__.TTF']=true
''')
main_source=read('SuperMacro/SuperMacro.lua')
a=main_source.index('function SuperMacroFrame_OnLoad()')
b=main_source.index('\nend',a)+4
r.execute(main_source[a:b])
r.execute(read('SuperMacro/SM_UI.lua'))
r.execute('''
assert(SuperMacroFrame and SuperMacroOptionsFrame)
assert(SuperMacroFrame.events.VARIABLES_LOADED and actionHooked and accountTabInitialized)
count=0
for _,o in ipairs(objects) do if o.kind=='FontString' and o~=uninitialized then
 count=count+1;assert(o.font,'missing font: '..tostring(o.name));o:SetText('');o:Hide();o:SetText('hidden');o:Show();o:SetText('reused')
end end
assert(count>50)
local before=#objects;SuperMacro_BuildUI();assert(#objects==before,'UI rebuilt twice')
''')
print('PASS: full SuperMacro UI creates',r.globals().count,'font-initialized strings with failed configured font, hidden/reuse and idempotent build')

# Complete combo-point module: new layouts, switches, preview and font failure.
r.execute('''
C={unitframes={combopipnumbers='1',comboglow='1'},position={}}
pfUI={font_default='Fonts\\\\FRIZQT__.TTF',unlock=object('Frame'),uf={}}
pfUI.RegisterModule=function(self,name,versions,fn) fn() end
function GetBorderSize() return 1,1 end
ComboFrame=object('Frame')
function UnitClass() return 'Rogue','ROGUE' end
function GetComboPoints() return 3 end
function CreateBackdrop(f) f.backdrop=object('Frame',nil,f) end
function CreateBackdropShadow(f) f.backdrop_shadow=object('Frame',nil,f) end
function UpdateMovable(f) movableCount=(movableCount or 0)+1 end
function HookScript(f,event,fn) f.scripts[event]=fn end
''')
r.execute(read('pfUI/modules/combopoints.lua'))
r.execute('''
local c=pfUI.combopoints;assert(movableCount==1 and #c.points==5)
c:DisplayNum(5);assert(c.glowing and c.points[5]:IsShown())
for _,f in ipairs(c.points) do assert(f.text.font);f.text:SetText('') end
for _,direction in ipairs({'right','left','up','down'}) do
 C.unitframes.combogrow=direction;c:UpdateConfig();c:DisplayNum(3)
 assert(c.points[3]:IsShown() and not c.points[4]:IsShown())
end
C.unitframes.combostyle='numbers';c:UpdateConfig();c:DisplayNum(4)
assert(c.points[1].text.text=='4' and not c.points[2]:IsShown())
C.unitframes.comboshow='0';c:UpdateConfig();assert(not c.points[1]:IsShown())
C.unitframes.comboshow='1';C.unitframes.combostyle='pips';c:UpdateConfig()
pfUI.unlock.scripts.OnShow();assert(c.unlocking and c.count==5 and not c.glowing)
pfUI.unlock.scripts.OnHide();assert(not c.unlocking and c.count==4)
''')
print('PASS: complete combo module, four directions, number/pip switching, disable/reuse, unlock preview and failed font fallback')

# Actual new debuff icon factory, including empty/hidden/reused label writes.
src=read('pfUI/modules/debuffmonitor.lua')
a=src.index('  local function CreateDebuff(');b=src.index('\n  end',a)+6
r.execute("font='Fonts\\\\FZLBJW.TTF';failedFontPaths[font]=true;debuff_list={Test={texture='icon'}};pfUI.debuffmonitor={target={debuffs=object('Frame')}}")
factory=r.execute(src[a:b]+'\nreturn CreateDebuff')
icon=factory('Test','test')
for name in ['stacks','time','caster']:
    fs=icon[name];assert fs.font is not None
    fs.SetText(fs,'');fs.Hide(fs);fs.SetText(fs,'hidden');fs.Show(fs);fs.SetText(fs,'reused')
print('PASS: actual new debuff icon factory retains template fonts with unavailable configured font')

# Actual retained healing UI font factory and the special totem button used by
# the new recall cooldown writer. No SetText path gets an empty font mock.
ui=read('GoubayuHeal/GoubayuHeal_UI.lua')
r.execute('GoubayuHeal={UI={}};totemFrame=object("Frame")')
factory=r.execute(ui[:ui.index('-- 设置悬停提示')]+'\nreturn GoubayuHeal_UI_MakeFontString')
fs=factory(r.globals().object('Frame',None,None),'OVERLAY',12,1,1,1)
fs.SetText(fs,'');fs.Hide(fs);fs.SetText(fs,'hidden');fs.Show(fs);fs.SetText(fs,'reused')
a=ui.index('local function GoubayuHeal_CreateTotemSpecialButton(')
b=ui.index('\nend',a)+4
special=r.execute(ui[a:b]+'\nreturn GoubayuHeal_CreateTotemSpecialButton')
special('GoubayuHeal_TotemButton_Place',False)
cd=r.globals().GoubayuHeal_TotemButton_PlaceCooldownText
assert cd.font is not None
cd.SetText(cd,'1');cd.Hide(cd);cd.SetText(cd,'');cd.Show(cd)
print('PASS: retained healing font factory and new recall-timer target initialize valid fallback fonts before all text writes')

# Actual card entry points, no cast or item API reaches the game.
r=LuaRuntime(unpack_returned_tuples=True)
r.execute('''
cards={};Cat2={RegisterCard=function(c) cards[c.id]=c end}
channel=0;ready=true;castCount=0;used=0;locked=false;enabled=1;now=100;duration=0
Cat2.GetChanneled=function() return channel end
Cat2.SpellReady=function() return ready end
Cat2.Cast=function() castCount=castCount+1 end
function GetTime() return now end
function GetContainerNumSlots(bag) return bag==0 and 1 or 0 end
function GetContainerItemLink() return '|Hitem:1:0:0:0|h[Test]|h|r' end
function GetContainerItemInfo() return 'icon',1,locked end
function GetContainerItemCooldown() return 100,duration,enabled end
function UseContainerItem() used=used+1 end
context={GetStepOption=function(self,step,key) return self[key] end}
''')
for path in ['Cat2/Cards/Common/CustomSpell.lua','Cat2/Cards/Items/CustomUseItem.lua']:
    r.execute(read(path))
r.execute('''
local c=cards.common_custom_spell
context.spellName='';assert(not c.Execute(context,{}))
context.spellName='Test';channel=.1;assert(not c.Execute(context,{}))
channel=0;ready=false;assert(not c.Execute(context,{}))
ready=true;assert(c.Execute(context,{}) and castCount==1)
local item=cards.item_custom_use_item
context.itemName=' Test ';assert(not item.Execute(context,{}) and used==1)
locked=true;item.Execute(context,{});assert(used==1)
locked=false;duration=20;item.Execute(context,{});assert(used==1)
duration=0;enabled=0;item.Execute(context,{});assert(used==1)
''')
print('PASS: custom spell readiness/channel guards and custom item lock/cooldown/use behavior')

# The shared scanner must accept unavailable enabled flags, while explicit
# disabled/active entries and invalid timer data stay excluded.
r=LuaRuntime(unpack_returned_tuples=True)
r.execute("function ignored() return false end;function GetTime() return 100 end")
scan=r.execute(function(read('Cooline/Cooline.lua'),'scan_record')+'\nreturn scan_record')
for enabled,expected in [(None,True),(1,True),(0,False),(False,False)]:
    records=r.table();scan(records,r.table(),'Timer','icon',90,20,enabled,2.5)
    assert (records['Timer'] is not None)==expected
print('PASS: actual cooldown scanner accepts nil/1 and excludes zero/false disabled flags')
