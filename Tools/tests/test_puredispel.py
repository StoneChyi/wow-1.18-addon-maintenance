"""PureDispel behavior and strict font checks against actual WoW 1.12 Lua files.

Mock checks do not establish rendering quality or live client performance.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/hyx'
CONTRACT = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')
MOCK = (ROOT / 'Tools/tests/puredispel_wow112_mock.lua').read_text(encoding='utf-8-sig')


def world(ui=True, pfui=True, setup='', bad_font=False, chatbar=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    installer = lua.execute(CONTRACT)
    lua.execute(MOCK, installer)
    if pfui:
        lua.execute('SetPfUI()')
    if bad_font:
        lua.execute("failedFontPaths['test-pf-font.ttf']=true")
    if setup:
        lua.execute(setup)
    files = ['XinDispel.lua', 'RaidData.lua']
    if ui:
        files.extend(['PureDispelUI.lua', 'Debug.lua'])
    for name in files:
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute("FireEvent('VARIABLES_LOADED'); FireEvent('PLAYER_ENTERING_WORLD'); Tick(.3)")
    if chatbar:
        lua.execute((ROOT / 'Interface/AddOns/S_ChatBar/ChatBar.lua').read_text(encoding='utf-8-sig'))
        lua.execute("FireEvent('PLAYER_LOGIN')")
    return lua


checks = 0


def check(name, code, **kwargs):
    global checks
    lua = world(**kwargs)
    lua.execute(code)
    checks += 1
    print('PASS', name)
    return lua


def main():
    check('strict font mock rejects uninitialized and failed font paths', '''
local text=newObject('FontString',nil,UIParent)
assert(not pcall(function() text:SetText('broken') end))
failedFontPaths.broken=true;assert(not text:SetFont('broken',12))
assert(not pcall(function() text:SetText('still broken') end))
text:SetFontObject(GameFontNormal);text:SetText('valid')
''', ui=False)
    check('all nine classes match learned friendly dispel abilities', '''
local cases={
 {'PALADIN',{'清洁术'},'Magic','Poison','Disease'},
 {'PRIEST',{'驱散魔法','祛病术'},'Magic','Disease'},
 {'DRUID',{'解除诅咒','驱毒术'},'Curse','Poison'},
 {'MAGE',{'解除次级诅咒'},'Curse'},
 {'SHAMAN',{'消毒术','祛病术'},'Poison','Disease'},
 {'WARLOCK',{},'Magic'}, {'WARRIOR',{}}, {'ROGUE',{}}, {'HUNTER',{}}
}
for _,c in ipairs(cases) do
 playerClass=c[1];books.spell=c[2];books.pet={'吞噬魔法'};AddUnit('pet','Pet')
 XinDispel.RefreshSpells();local expected={}
 for i=3,table.getn(c) do expected[c[i]]=true end
 for _,t in ipairs({'Magic','Poison','Curse','Disease'}) do
  assert((XinDispel.spells[t]~=nil)==(expected[t]==true),c[1]..':'..t)
 end
end
playerClass='PALADIN';books.spell={'纯净术'};XinDispel.RefreshSpells()
assert(not XinDispel.spells.Magic and XinDispel.spells.Poison)
books.spell={};XinDispel.RefreshSpells();assert(not next(XinDispel.spells))
''', ui=False)
    check('English names and highest learned rank', '''
playerClass='PRIEST';books.spell={'Dispel Magic','Dispel Magic','Cure Disease'}
XinDispel.RefreshSpells();assert(XinDispel.spells.Magic.slot==2)
assert(XinDispel.spells.Disease.name=='Cure Disease')
''', ui=False)
    check('40-person roster keeps all candidates in two dense lists', '''
raidCount=40
for i=1,40 do AddUnit('raid'..i,'Mate'..i,'Magic',i<=24 and 10 or 45) end
XinDispel.MarkDirty();XinDispel.Update(true)
assert(table.getn(XinDispel.entries.ready)==24)
assert(table.getn(XinDispel.entries.blocked)==16)
''', ui=False)
    check('hidden engine performs no aura, distance or tooltip scanning', '''
partyCount=1;AddUnit('party1','Mate','Magic');XinDispel.Update(true)
XinDispel.SetListsVisible(false);ResetCalls()
for i=1,30 do Tick(.3) end
assert(not calls.aura and not calls.tooltip and not calls.distance)
units.party1.auras={{name='Replacement',kind='Magic'}}
XinDispel.SetListsVisible(true)
assert(XinDispel.entries.ready[1].debuff.name=='Replacement')
''', ui=False)
    check('policy actions are reversible, full-ignore blocks priority', '''
partyCount=2;AddUnit('party1','Alpha','Magic');AddUnit('party2','Beta','Magic')
assert(XinDispel.SetPolicy('Beta','priority','team'))
assert(XinDispel.GetPolicy('Beta')=='priority')
assert(XinDispel.SetPolicy('Beta','ignore','team'))
XinDispel.Update(true);assert(table.getn(XinDispel.entries.ready)==1)
assert(XinDispel.Undo());assert(XinDispel.GetPolicy('Beta')=='priority')
assert(XinDispel.SetPolicy('Alpha','ignore','longterm'))
assert(not XinDispel.SetPolicy('Alpha','priority','team'))
assert(XinDispel.GetPolicy('Alpha')=='ignore')
assert(XinDispel.ClearPolicy('Alpha','longterm'))
assert(XinDispel.GetPolicy('Alpha')=='normal')
''', ui=False)
    check('both ignore meanings, complete-block on unsupported aura type', '''
partyCount=1;AddUnit('party1','Mate','Magic')
units.party1.auras[2]={name='Hold',kind='Curse'}
XinDispel.SetIgnoreRule('Debuff-Magic',1);XinDispel.Update(true)
assert(table.getn(XinDispel.entries.ready)==0)
XinDispel.SetIgnoreRule('Debuff-Magic',0);XinDispel.SetIgnoreRule('Hold',2)
XinDispel.Update(true);assert(table.getn(XinDispel.entries.ready)==0)
XinDispel.SetIgnoreRule('Hold',0);XinDispel.Update(true)
assert(table.getn(XinDispel.entries.ready)==1)
''', ui=False)
    check('pet range uses pet origin and pet loss invalidates capability', '''
playerClass='WARLOCK';books.spell={};books.pet={'吞噬魔法'};AddUnit('pet','Felhunter')
units.player.auras={{name='Debuff-Magic',kind='Magic'}};units.player.distance=10
FireEvent('UNIT_PET','player');XinDispel.Update(true)
assert(xpSource=='pet' and XinDispel.spells.Magic.pet)
units.pet=nil;books.pet={};FireEvent('UNIT_PET','player');XinDispel.Update(true)
assert(not XinDispel.spells.Magic and table.getn(XinDispel.entries.ready)==0)
''', ui=False)
    check('stale entries, changed auras and newly ignored names cannot cast', '''
partyCount=1;AddUnit('party1','Mate','Magic');XinDispel.Update(true)
local entry=XinDispel.entries.ready[1]
units.party1.name='Replacement';assert(not XinDispel.Cast(entry));assert(table.getn(casts)==0)
units.party1.name='Mate';units.party1.auras={};assert(not XinDispel.Cast(entry))
units.party1.auras={{name='Debuff-Magic',kind='Magic'}}
XinDispel.SetPolicy('Mate','ignore','team');assert(not XinDispel.Cast(entry))
assert(table.getn(casts)==0)
''', ui=False)
    check('original raid data extracted without edits', '''
assert(XinRaidManualDB['祖尔格拉布'] and XinRaidManualDB['纳克萨玛斯'])
''', ui=False)
    original = (ADDON / 'hyx.lua').read_bytes()
    data = original[original.index(b'XinRaidManualDB = {'):original.index(b'local topDivider')]
    assert (ADDON / 'RaidData.lua').read_bytes().endswith(data)
    toc = (ADDON / 'hyx.toc').read_text(encoding='utf-8-sig')
    entries = [x.strip() for x in toc.splitlines() if x.strip() and not x.startswith('#')]
    assert entries == ['XinDispel.lua', 'RaidData.lua', 'PureDispelUI.lua', 'Debug.lua']
    check('full new load chain has initialized fonts with missing pfUI font', '''
assert(XinDispel.UI)
for _,obj in ipairs(objects) do if obj.kind=='FontString' then assert(obj.font,'FontString lacks a font') end end
''', bad_font=True)
    check('native skin fallback loads without pfUI', '''
assert(XinDispel.UI and XinDispel.ready)
''', pfui=False)
    check('20 reusable target rows, fixed simultaneous regions, independent wheel', '''
local D,U=XinDispel,XinDispel.UI
raidCount=40
for i=1,40 do AddUnit('raid'..i,'Mate'..i,'Magic',i<=24 and 10 or 45) end
D.MarkDirty();local a,b=U.regions.ready,U.regions.blocked
assert(table.getn(a.rows)==10 and table.getn(b.rows)==10)
local y=b.point[5];local height=b.height
invoke(a.rows[1],'OnMouseWheel',-1)
assert(a.offset==1 and b.offset==0)
assert(a.rows[1].entry.name=='Mate2')
assert(b.point[5]==y and b.height==height)
invoke(b.area,'OnMouseWheel',-1);assert(b.offset==1 and a.offset==1)
shift=true;invoke(a.rows[1],'OnMouseWheel',-1);assert(a.offset==24-a.limit)
invoke(a.rows[1],'OnMouseWheel',1);assert(a.offset==0)
local rowCount=0;for _,o in ipairs(objects) do if o.icon and o.name and o.aura then rowCount=rowCount+1 end end
assert(rowCount==20)
''')
    check('empty upper section leaves lower section anchored and visible', '''
local D,U=XinDispel,XinDispel.UI
partyCount=2;AddUnit('party1','Near','Magic');AddUnit('party2','Far','Magic',45)
D.MarkDirty();local y=U.regions.blocked.point[5]
units.party1.auras={};D.Update(true)
assert(not U.regions.ready.empty and not U.regions.ready.rows[1]:IsShown())
assert(U.regions.blocked.rows[1]:IsVisible())
assert(U.regions.blocked.point[5]==y)
''')
    check('scrolling preserves top visible person when an earlier target disappears', '''
local D,U=XinDispel,XinDispel.UI;raidCount=15
for i=1,15 do AddUnit('raid'..i,'Mate'..i,'Magic') end
D.MarkDirty();local r=U.regions.ready
for i=1,3 do invoke(r.rows[1],'OnMouseWheel',-1) end
local name=r.rows[1].entry.name
units.raid1.auras={};D.Update(true)
assert(r.rows[1].entry.name==name)
''')
    check('row refresh between press and release cancels wrong-target cast', '''
local D,U=XinDispel,XinDispel.UI;partyCount=2
AddUnit('party1','First','Magic');AddUnit('party2','Second','Magic');D.MarkDirty()
local row=U.regions.ready.rows[1];invoke(row,'OnMouseDown','LeftButton')
units.party1.auras={};D.Update(true)
assert(row.entry.name=='Second')
invoke(row,'OnClick','LeftButton');assert(table.getn(casts)==0)
''')
    check('right click menu sets ignore, recovery and one-step undo', '''
local D,U=XinDispel,XinDispel.UI;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
local row=U.regions.ready.rows[1]
invoke(row,'OnClick','RightButton');assert(U.menu:IsShown())
invoke(U.menu.buttons[2],'OnClick','LeftButton')
assert(D.GetPolicy('Mate')=='ignore' and table.getn(D.entries.ready)==0)
invoke(U.frame.footer.ignored,'OnClick','LeftButton')
assert(U.manager:IsShown() and U.manager.kind=='ignore')
assert(U.manager.rows[1].item.name=='Mate')
invoke(U.frame.footer.undo,'OnClick','LeftButton')
assert(D.GetPolicy('Mate')=='normal' and table.getn(D.entries.ready)==1)
''')
    check('menu action cannot apply to a stale actual aura before next scan', '''
local D,U=XinDispel,XinDispel.UI;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
U.OpenMenu(U.regions.ready.rows[1]);assert(U.menu:IsShown())
units.party1.auras={};invoke(U.menu.buttons[1],'OnClick','LeftButton')
assert(D.GetPolicy('Mate')=='normal')
''')
    check('compatibility right click cast and middle-click targeting', '''
local D,U=XinDispel,XinDispel.UI;partyCount=1;AddUnit('party1','Mate','Magic');AddUnit('target','Boss');D.MarkDirty()
xinDB.rightClickDispel=true
invoke(U.regions.ready.rows[1],'OnClick','RightButton')
assert(table.getn(casts)==1 and units.target.name=='Boss')
shift=true;invoke(U.regions.ready.rows[1],'OnClick','RightButton');assert(U.menu:IsShown())
shift=false;invoke(U.regions.ready.rows[1],'OnClick','MiddleButton');assert(units.target.name=='Mate')
''')
    check('background and border alpha do not fade text or icons', '''
local U=XinDispel.UI
xinDB.backgroundAlpha=0;xinDB.borderAlpha=.4;U.ApplyAppearance()
assert(U.frame.bgColor[4]==0 and U.frame.borderColor[4]==.4)
assert(U.frame.alpha==1)
xinDB.backgroundAlpha=1;xinDB.borderAlpha=0;U.ApplyAppearance()
assert(U.frame.bgColor[4]==1 and U.frame.borderColor[4]==0)
for _,o in ipairs(objects) do if o.kind=='FontString' then assert(o.alpha==1) end end
''')
    check('settings, manager, rules and raid manual are lazy singletons; fonts valid', '''
local U=XinDispel.UI
assert(not U.manager and not U.rules and not U.raid)
U.OpenSettings();U.OpenManager('current');U.OpenRules('Debuff-Magic');U.OpenRaid()
assert(U.settings:IsShown() and U.manager:IsShown() and U.rules:IsShown() and U.raid:IsShown())
for _,o in ipairs(objects) do if o.kind=='FontString' then assert(o.font) end end
local n=table.getn(objects)
for i=1,8 do U.OpenSettings();U.OpenManager('priority');U.OpenRules();U.OpenRaid() end
assert(table.getn(objects)==n)
invoke(U.settings.close,'OnClick','LeftButton')
assert(not U.settings:IsShown() and not U.manager:IsShown() and not U.rules:IsShown() and not U.raid:IsShown())
assert(U.frame:IsShown())
''', bad_font=True)
    check('small screen and largest font preserve both visible regions', '''
local U=XinDispel.UI;UIParent.height=480
xinDB.maxInRange=10;xinDB.maxOutRange=10;xinDB.followPfUI=false;xinDB.fontSize=18
U.ApplyAppearance()
assert(U.frame.height<=UIParent.height)
assert(U.regions.ready.limit>=1 and U.regions.blocked.limit>=1)
assert(U.regions.ready.rowHeight>=34)
''')
    check('unchanged scans do not recreate UI or repeatedly set row content', '''
local D,U=XinDispel,XinDispel.UI;raidCount=40
for i=1,40 do AddUnit('raid'..i,'Mate'..i,'Magic',i<30 and 10 or 45) end
D.MarkDirty();local n=table.getn(objects);local ready=D.entries.ready
local entry=ready[1];local aura=entry.debuff
ResetCalls();for i=1,40 do D.Update(false) end
assert(table.getn(objects)==n and D.entries.ready==ready and D.entries.ready[1]==entry and entry.debuff==aura)
assert(not calls.text and not calls.texture and not calls.point)
''')
    check('team rules persist normal roster changes and party-to-raid transitions', '''
local D=XinDispel
partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty();D.SetPolicy('Mate','priority','team')
FireEvent('VARIABLES_LOADED');FireEvent('PLAYER_ENTERING_WORLD')
assert(D.GetPolicy('Mate')=='priority')
partyCount=2;AddUnit('party2','New','Magic');FireEvent('PARTY_MEMBERS_CHANGED');Tick(.3)
assert(D.GetPolicy('Mate')=='priority')
partyCount=0;raidCount=0;Tick(.5)
raidCount=2;units.raid1=units.player;units.raid2=units.party1;FireEvent('RAID_ROSTER_UPDATE');Tick(.3)
assert(D.GetPolicy('Mate')=='priority')
''', ui=False)
    check('confirmed leaving a group clears only temporary rules, even hidden', '''
local D=XinDispel;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
D.SetPolicy('Mate','priority','team');D.SetPolicy('Permanent','ignore','longterm')
D.SetListsVisible(false);partyCount=0;FireEvent('PARTY_MEMBERS_CHANGED')
for i=1,9 do Tick(1) end
assert(D.GetPolicy('Mate')=='normal' and D.GetPolicy('Permanent')=='ignore')
assert(not D.Undo())
''', ui=False)
    check('long cooldown, GCD, mana and failing DLL reasons remain accurate', '''
local D=XinDispel;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
units.party1.sight=0;D.Update(true);assert(D.entries.blocked[1].reason=='视野之外')
units.party1.sight=true;cooldowns={spell1={start=now,duration=1.5}};D.Update(true)
assert(table.getn(D.entries.ready)==1)
cooldowns.spell1.duration=8;D.Update(true);assert(D.entries.blocked[1].reason=='冷却中')
cooldowns={};oom=true;D.Update(true);assert(D.entries.blocked[1].reason=='法力不足')
oom=false;xpError=true;D.Update(true);assert(D.entries.blocked[1].reason=='距离未知')
UnitXP=nil;D.Update(true);assert(D.entries.blocked[1].reason=='距离未知')
units.party1.nativeRange=1;D.Update(true);assert(table.getn(D.entries.ready)==1)
''', ui=False)
    check('stock fallback casts on selected unit then restores target', '''
SUPERWOW_VERSION=nil;partyCount=1;AddUnit('party1','Mate','Magic');AddUnit('target','Boss')
XinDispel.MarkDirty();assert(XinDispel.Cast(XinDispel.entries.ready[1]))
assert(units.target.name=='Boss' and resolved=='party1' and not targeting)
ClearTarget();assert(XinDispel.Cast(XinDispel.entries.ready[1]));assert(not units.target)
''', ui=False)
    check('temporary policies belong to character and realm, legacy long-term rules remain', '''
local D=XinDispel
assert(D.GetPolicy('Mate')=='normal')
assert(D.GetPolicy('Permanent')=='ignore')
assert(xinDB.teamOwner~='Elsewhere::Other')
partyCount=1;AddUnit('party1','Mate','Magic');D.SetPolicy('Mate','priority','team')
local owner=xinDB.teamOwner;FireEvent('VARIABLES_LOADED');assert(xinDB.teamOwner==owner)
assert(D.GetPolicy('Mate')=='priority')
function GetRealmName() return 'OtherRealm' end
D.Init();assert(D.GetPolicy('Mate')=='normal' and D.GetPolicy('Permanent')=='ignore')
''', ui=False, setup="xinDB={teamRules={Mate='ignore'},teamOwner='Elsewhere::Other',BlackList={Permanent=true}}")
    check('empty team rules cannot resurrect an old group policy through undo', '''
local D=XinDispel;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
D.SetPolicy('Mate','ignore','team');D.ClearPolicy('Mate','team')
assert(not next(xinDB.teamRules) and D.CanUndo())
partyCount=0;for i=1,9 do Tick(1) end
assert(not D.CanUndo() and not D.Undo())
assert(D.GetPolicy('Mate')=='normal')
''', ui=False)
    check('menu click-away is shared, closes cleanly, and no ordinary cast is triggered', '''
local D,U=XinDispel,XinDispel.UI;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
U.OpenMenu(U.regions.ready.rows[1]);assert(U.menu.blocker:IsShown())
local n=table.getn(objects)
invoke(U.menu.blocker,'OnClick','LeftButton')
assert(not U.menu:IsShown() and not U.menu.blocker:IsShown() and table.getn(casts)==0)
for i=1,10 do U.OpenMenu(U.regions.ready.rows[1]);U.menu:Hide() end
assert(table.getn(objects)==n and not U.menu.blocker:IsShown())
''')
    check('manual supports missing height API and direct raid selection', '''
local U=XinDispel.UI;methods.GetStringHeight=nil
U.OpenRaid();U.RefreshRaidDetail(XinRaidManualDB['祖尔格拉布'][1])
assert(U.raid.detailContent.height>=260)
invoke(U.raid.selector,'OnClick','LeftButton')
assert(U.raid.picker and U.raid.picker:IsShown())
invoke(U.raid.picker.buttons[table.getn(U.raid.names)],'OnClick','LeftButton')
assert(U.raid.raidIndex==table.getn(U.raid.names) and not U.raid.picker:IsShown())
''')
    check('hovered aura tooltip is refreshed and dismissed with its hidden row', '''
local D,U=XinDispel,XinDispel.UI;partyCount=1;AddUnit('party1','Mate','Magic');D.MarkDirty()
local base=methods.SetUnitDebuff
function GameTooltip:SetUnitDebuff(unit,index) self.shownAura=units[unit].auras[index].name;base(self,unit,index) end
local row=U.regions.ready.rows[1];invoke(row,'OnEnter')
assert(GameTooltip.shownAura=='Debuff-Magic')
units.party1.auras[1].name='Changed aura';D.Update(true)
assert(GameTooltip.shownAura=='Changed aura')
units.party1.auras={};D.Update(true);assert(not GameTooltip:IsShown())
''')
    check('chat-bar shortcut opens new settings and toggles whole window', '''
assert(Channelhyx and Channelhyx.text:GetText()=='驱')
invoke(Channelhyx,'OnClick','LeftButton');assert(not PureDispelFrame:IsShown())
invoke(Channelhyx,'OnClick','RightButton');assert(XinSettingFrame:IsShown())
invoke(Channelhyx,'OnClick','RightButton');assert(XinSettingFrame:IsShown())
invoke(Channelhyx,'OnClick','LeftButton');assert(PureDispelFrame:IsShown())
''', setup="C_Timer={After=function(delay,fn)fn()end}", chatbar=True)
    check('legacy rows, positions, long-term policies and raid rules migrate intact', '''
local D,U=XinDispel,XinDispel.UI
assert(xinDB.maxInRange==8 and xinDB.maxOutRange==3 and U.regions.ready.limit==8)
assert(xinDB.enableOutRange==false and table.getn(D.entries.blocked)==1)
assert(D.GetPolicy('Alpha')=='priority' and D.GetPolicy('Beta')=='ignore')
assert(xinDB.IgnoreList.Custom==2 and xinDB.RaidSettings.Old.ignoreClasses['战士'])
assert(xinDB.sentinel.keep and U.frame.point[4]==50 and U.frame.point[5]==-80)
''', setup="""
xinDB={maxInRange=8,maxOutRange=3,enableOutRange=false,positions={XinMainFrame_InRange={'TOPLEFT','TOPLEFT',50,-80}},PriorityList={Alpha=true},BlackList={Beta=true},IgnoreList={Custom=2},RaidSettings={Old={ignoreType=1,ignoreClasses={['战士']=true}}},sentinel={keep=true}}
partyCount=3;AddUnit('party1','Alpha','Magic');AddUnit('party2','Beta','Magic');AddUnit('party3','Far','Magic',45)
""")
    check('unavailable identity delays temporary-policy binding and then resolves safely', '''
local D=XinDispel
assert(xinDB.teamOwner=='OldRealm::Other' and xinDB.teamRules.Mate=='ignore')
assert(D.GetPolicy('Mate')~='ignore')
units.player.name='Self';D.Init()
assert(D.GetPolicy('Mate')=='normal' and not next(xinDB.teamRules))
assert(D.GetPolicy('Permanent')=='ignore')
''', ui=False, setup="xinDB={teamOwner='OldRealm::Other',teamRules={Mate='ignore'},BlackList={Permanent=true}};units.player.name=nil")
    check('all SetFont paths may fail while built-in font objects remain valid', '''
local U=XinDispel.UI
U.OpenSettings();U.OpenManager('current');U.OpenRules();U.OpenRaid();U.ApplyAppearance()
for _,o in ipairs(objects) do if o.kind=='FontString' then assert(o.font) end end
''', setup="failedFontPaths[STANDARD_TEXT_FONT]=true", bad_font=True)
    check('same icon does not cache the wrong debuff identity, missing names fail closed', '''
local D=XinDispel;partyCount=1;AddUnit('party1','Mate','Magic')
units.party1.auras[1]={name='Block',kind='Magic',texture='shared'}
D.SetIgnoreRule('Block',2);D.Update(true);assert(table.getn(D.entries.ready)==0)
units.party1.auras[1].name='Safe';D.Update(true);assert(D.entries.ready[1].debuff.name=='Safe')
units.party1.auras[1].name=nil;D.Update(true);assert(table.getn(D.entries.ready)==0)
''', ui=False)
    check('explicit window height is applied and keeps fixed regions under roster changes', '''
local D,U=XinDispel,XinDispel.UI
xinDB.height=520;U.ApplyAppearance();assert(U.frame.height==520)
assert(U.regions.ready.limit==6 and U.regions.blocked.limit==3)
local y=U.regions.blocked.point[5];local a=U.regions.ready.area.height
assert(a>6*U.regions.ready.rowHeight)
partyCount=1;AddUnit('party1','Mate','Magic',45);D.MarkDirty()
assert(U.frame.height==520 and U.regions.blocked.point[5]==y)
''')
    check('height clamps to screen and always retains both independent scrolling regions', '''
local U=XinDispel.UI;UIParent.height=480
xinDB.height=900;xinDB.maxInRange=10;xinDB.maxOutRange=10;U.ApplyAppearance()
assert(U.frame.height<=450 and xinDB.height==U.frame.height)
xinDB.height=220;U.ApplyAppearance()
assert(U.regions.ready.limit>=1 and U.regions.blocked.limit>=1)
assert(U.frame.height>=145+2*U.regions.ready.rowHeight)
assert(U.frame.height==xinDB.height)
''')
    check('width supports 180 through 600 without overlapping narrow header or footer controls', '''
local D,U=XinDispel,XinDispel.UI
partyCount=2;AddUnit('party1','Nearby','Magic');AddUnit('party2','Distant','Magic',45);D.MarkDirty()
xinDB.width=180;U.ApplyAppearance();assert(U.frame.width==180)
assert(U.frame.title:GetStringWidth()+U.frame.close.width+U.frame.settings.width+U.frame.manage.width+U.frame.lock.width+25<180)
assert(U.frame.footer.ignored.width+U.frame.footer.undo.width<U.frame.footer.width)
assert(U.regions.ready.rows[1].name.width>0 and U.regions.blocked.rows[1].name.width>0)
assert(U.regions.blocked.rows[1].reason.point[1]=='TOPRIGHT')
xinDB.width=600;U.ApplyAppearance();assert(U.frame.width==600)
''')
    check('layout settings expose height and wider width range, reset height and keep page controls exclusive', '''
local U=XinDispel.UI;U.OpenSettings()
local sliders={};for _,s in ipairs(U.settings.sliders) do sliders[s.pdKey]=s end
assert(sliders.width.low==180 and sliders.width.high==600)
assert(sliders.height and sliders.height.low==220 and sliders.height.high==900)
sliders.height:SetValue(520);assert(xinDB.height==520 and U.frame.height==520)
U.ShowSettingsPage('appearance')
assert(sliders.backgroundAlpha:IsShown() and not sliders.height:IsShown() and not sliders.height.pdLabel:IsShown())
U.ShowSettingsPage('layout');sliders.maxInRange:SetValue(8)
assert(xinDB.height==0 and U.regions.ready.limit==8)
sliders.height:SetValue(550);invoke(U.settings.matchHeight,'OnClick','LeftButton')
assert(xinDB.height==0)
''')
    check('empty combat regions have no placeholder FontString or text', '''
local U=XinDispel.UI
assert(not U.regions.ready.empty and not U.regions.blocked.empty)
for _,region in pairs(U.regions) do
 for _,obj in ipairs(objects) do
  if obj.parent==region or obj.parent==region.area then assert(obj.text~='暂无目标') end
 end
 for _,row in ipairs(region.rows) do assert(not row:IsShown()) end
end
''')
    check('debug report is manual and allocates no active sampling or extra scanning', '''
local D,U,B=XinDispel,XinDispel.UI,XinDispel.Debug
assert(B and not B.enabled and not B.frame)
local drivers=0;for _,o in ipairs(objects) do if o.scripts.OnUpdate then drivers=drivers+1 end end
assert(drivers==1)
ResetCalls();local scans=D.GetMetrics().scanCycles
local s=B.Snapshot();local text=B.Report()
assert(s.version=='2.1.0' and string.find(text,'StoneChyi & Codex',1,true))
assert(not calls.aura and not calls.tooltip and not calls.distance and table.getn(casts)==0)
assert(D.GetMetrics().scanCycles==scans)
''')
    check('debug panel fonts, copy selection, close linkage and singleton refresh', '''
local U,B=XinDispel.UI,XinDispel.Debug
SlashCmdList.PUREDISPEL('debug');assert(U.debugPanel and U.debugPanel:IsShown())
local n=table.getn(objects)
for i=1,8 do U.OpenDebug();B.RefreshPanel() end
assert(table.getn(objects)==n)
invoke(B.frame.select,'OnClick','LeftButton');assert(B.frame.report.focus)
for _,o in ipairs(objects) do if o.kind=='FontString' then assert(o.font) end end
U.OpenSettings();invoke(U.settings.close,'OnClick','LeftButton')
assert(not B.frame:IsShown() and not B.frame.report.focus)
''', bad_font=True)
    check('debug logs are bounded, memory-only and exclude names and unknown reasons', '''
local D,B=XinDispel,XinDispel.Debug
assert(not B.enabled);D.SetPolicy('PrivateChar','priority','team');assert(B.count==0)
B.SetEnabled(true)
for i=1,65 do D.SetPolicy('PrivateChar','normal','team') end
assert(B.count==60 and table.getn(B.GetLogs())==60)
local text=B.Report();assert(not string.find(text,'PrivateChar',1,true))
local saved=xinDB.debugLogs;assert(saved==nil)
B.SetEnabled(false);D.SetIgnoreRule('PrivateAura',1);assert(B.count==60)
B.Clear();assert(B.count==0 and table.getn(B.GetLogs())==0)
''')
    compiler = ROOT / 'PluginHistory/staging/lua503-validation/win64/luac50.exe'
    if not compiler.is_file():
        raise AssertionError('Actual Lua 5.0 compiler unavailable')
    for name in entries:
        result = subprocess.run([str(compiler), '-p', str(ADDON / name)], capture_output=True, text=True)
        assert result.returncode == 0, f'{name}: {result.stderr}'
    print(f'{checks} behavior groups passed; actual Lua 5.0 syntax passed for {len(entries)} loaded files. Live game QA still required.')


if __name__ == '__main__':
    main()
