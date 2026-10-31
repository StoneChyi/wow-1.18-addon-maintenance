"""Real pfUI XP bar and legacy ExpBar behavior on a strict WoW 1.12 boundary."""
from pathlib import Path
import sys, unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
MOCK=r'''
local install=...
local methods={}
objects={}
function obj(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,shown=true,events={},scripts={},alpha=1,points={},width=452,height=5},{__index=methods})
 if name then _G[name]=o end;table.insert(objects,o);return o
end
function CreateFrame(kind,name,parent) return obj(kind,name,parent) end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:SetParent(p) self.parent=p end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetWidth(v) assert(tonumber(v)>0);self.width=tonumber(v) end
function methods:SetHeight(v) assert(tonumber(v)>0);self.height=tonumber(v) end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.points={...} end
function methods:GetPoint() return unpack(self.points) end
function methods:ClearAllPoints() self.points={} end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:SetMinMaxValues(a,b) assert(a==a and b==b and b>=a);self.minimum=a;self.maximum=b end
function methods:SetValue(v) assert(v==v and v~=math.huge and v~=-math.huge);self.value=v end
function methods:GetFrameLevel() return self.frameLevel or 1 end
function methods:SetFrameLevel(n) self.frameLevel=n end
function methods:CreateTexture() return obj('Texture',nil,self) end
for _,k in ipairs({'SetFrameStrata','SetBackdrop','SetBackdropBorderColor','SetStatusBarTexture','SetStatusBarColor','SetOrientation','SetAllPoints','SetJustifyH','EnableMouse','SetMovable','RegisterForDrag','StartMoving','StopMovingOrSizing','SetTexture','SetDrawLayer','SetTextColor'})do methods[k]=function()end end
install(methods,obj)
function methods:SetFont() return nil end
UIParent=obj('Frame','UIParent')
now=0;xp=0;maxxp=1000;level=20;rest=500
function GetTime() return now end
function time() return now end
function UnitXP()return xp end
function UnitXPMax()return maxxp end
function UnitLevel()return level end
function GetXPExhaustion()return rest end
function IsResting()return false end
function MouseIsOver()return false end
function GetPetExperience()return 0,0 end
function GetBorderSize()return 1,1 end
function SanitizePattern(x)return x end
function round(x)return math.floor(x+.5) end
floor=math.floor;min=math.min
function SecondsToTime(x) assert(x==x and x~=math.huge);return math.floor(x)..' seconds' end
function AlignToPosition(f) f:SetPoint('BOTTOM',UIParent,'BOTTOM',0,0) end
function UpdateMovable(f) local p=C.position[f:GetName()];if p then f:SetPoint(p.anchor,UIParent,p.anchor,p.xpos,p.ypos)end end
function CreateBackdrop()end
function CreateBackdropShadow()end
MAX_PLAYER_LEVEL=60;FACTION_STANDING_INCREASED='(.+) (%d+)';FACTION_BAR_COLORS={[4]={r=.3,g=.4,b=.5}}
function GetFactionInfo(i)if i==1 then return 'Reputation','',4,0,3000,1200,false,true,false,false,true end end
function GetText(x)return x end
function rgbhex()return '|cffffffff' end
GameTooltip=obj('Tooltip','GameTooltip')
function GameTooltip:ClearLines()self.lines={}end
function GameTooltip:SetOwner()end
function GameTooltip:AddLine(a)table.insert(self.lines,{a})end
function GameTooltip:AddDoubleLine(a,b)table.insert(self.lines,{a,b})end
function GameTooltip_SetDefaultAnchor()end
T=setmetatable({},{__index=function(_,k)return k end})
C={global={font_size=12},position={},panel={xp={xp_color='0,0,1,1',rest_color='1,0,1,1',texture='test',dont_overlap='0',xp_width='452',xp_height='5',xp_mode='HORIZONTAL',xp_timeout='5',xp_anchor='UIParent',xp_position='BOTTOM',xp_display='XPFLEX',xp_text='0',xp_text_off_y='0',xp_text_mouse='0',xp_always='1',rep_width='452',rep_height='5',rep_mode='HORIZONTAL',rep_timeout='5',rep_anchor='pfExperienceBar',rep_position='BOTTOM',rep_display='REP',rep_text='1',rep_text_off_y='0',rep_text_mouse='0',rep_always='1'}}}
pfUI={api={GetStringColor=function()return .1,.2,.3,1 end},media=setmetatable({},{__index=function(_,k)return k end}),font_default='missing-font'}
function pfUI:RegisterModule(_,_,fn)fn()end
function fire(f,k,e,a)
 local oldThis,oldEvent,oldArg=this,event,arg1;this=f;event=e;arg1=a
 if f.scripts[k] then f.scripts[k]()end
 this,event,arg1=oldThis,oldEvent,oldArg
end
function xpEvent(value,seconds,order)
 xp=value;now=seconds
 if order=='barfirst' then fire(pfUI.xp,'OnEvent','PLAYER_XP_UPDATE','player')end
 fire(pfExperienceBarData,'OnEvent','PLAYER_XP_UPDATE','player')
 fire(pfUI.xp,'OnEvent','PLAYER_XP_UPDATE','player')
end
Automaton={modules={},disabled={}}
function Automaton:NewModule(name)
 local m={name=name,events={}};self.modules[name]=m
 function m:RegisterOptions(o)self._options=o end
 function m:RegisterEvent(e)self.events[e]=true end
 function m:UnregisterAllEvents()self.events={}end
 return m
end
function Automaton:AcquireDBNamespace()self.saved=self.saved or {profile={}};return self.saved end
function Automaton:RegisterDefaults(_,_,defaults)for k,v in pairs(defaults)do if self.saved.profile[k]==nil then self.saved.profile[k]=v end end end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive(name)return not self.disabled[name]end
function AceLibrary()return {new=function()return setmetatable({RegisterTranslations=function()end},{__index=function(_,k)return k end})end}end
SlashCmdList={}
'''

def runtime(legacy=False):
 lua=LuaRuntime(unpack_returned_tuples=True)
 font=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf8'))
 lua.execute(MOCK,font)
 if legacy:
  lua.execute((ROOT/'Interface/AddOns/Automatonex/Modules/ExpBar.lua').read_text(encoding='utf8'))
  lua.execute('Automaton.modules.ExpBar:OnInitialize();Automaton.modules.ExpBar:OnEnable()')
 lua.execute((ROOT/'Interface/AddOns/pfUI/modules/xpbar.lua').read_text(encoding='utf8'))
 return lua

class XPFusionTests(unittest.TestCase):
 def check(self,body,legacy=False):runtime(legacy).execute(body)
 def test_zero_baseline_rates_tooltip_and_native_layout(self):
  self.check('''assert(pfUI.xp:GetWidth()==452 and pfUI.xp:GetHeight()==5 and not pfUI.xp.bar.text:IsShown())
  xpEvent(100,60);local p=pfUI.xpbar.progress;assert(p.gained==100);local rate,seconds,count=p:Stats();assert(rate==6000 and seconds==540 and count==9)
  fire(pfUI.xp,'OnEnter');assert(#GameTooltip.lines>5)
  local found=false;for _,line in ipairs(GameTooltip.lines)do if line[1]=='按最近一次经验估算'then found=true end end;assert(found)
  assert(pfUI.rep:IsShown() and pfUI.rep.bar.value==1200)''')
 def test_loading_screen_does_not_reset_and_duplicate_order_is_idempotent(self):
  self.check('''xpEvent(100,60,'barfirst');fire(pfExperienceBarData,'OnEvent','PLAYER_ENTERING_WORLD');xpEvent(200,120,'barfirst');assert(pfUI.xpbar.progress.gained==200 and pfUI.xpbar.progress.started==0)''')
 def test_level_event_before_xp_and_after_xp(self):
  for order in ('before','after'):
   self.check('''xpEvent(950,60);local p=pfUI.xpbar.progress
   '''+('''fire(pfExperienceBarData,'OnEvent','PLAYER_LEVEL_UP',21);xp=50;maxxp=1100;xpEvent(50,90);level=21;xpEvent(50,90)''' if order=='before' else '''xp=50;maxxp=1100;xpEvent(50,90);fire(pfExperienceBarData,'OnEvent','PLAYER_LEVEL_UP',21);level=21;xpEvent(50,90)''')+''';assert(p.gained==1050,'cross-level gained '..p.gained);assert(p.lastGain==100)''')
 def test_zero_elapsed_maximum_and_cap_flex_are_finite(self):
  self.check('''xpEvent(10,0);fire(pfUI.xp,'OnEnter');assert(pfUI.xpbar.progress:Stats()==0)
  level=60;maxxp=0;fire(pfUI.xp,'OnEvent','PLAYER_LEVEL_UP',60);assert(pfUI.xp:IsShown() and not pfUI.xp.progressMode and pfUI.xp.bar.value==1200)
  C.panel.xp.xp_display='XP';pfUI.xpbar:UpdateConfig();assert(not pfUI.xp:IsShown());C.panel.xp.xp_display='PETXP';pfUI.xpbar:UpdateConfig();fire(pfUI.xp,'OnEnter')''')
 def test_stats_toggle_estimate_and_reset_do_not_create_frames(self):
  self.check('''xpEvent(100,60);C.panel.xp.xp_stats='1';pfUI.xpbar:UpdateConfig();assert(pfUI.xp.bar.text:IsShown() and string.find(pfUI.xp.bar.text.text,'同等经验',1,true))
  C.panel.xp.xp_estimate='0';now=120;fire(pfUI.xp,'OnUpdate');assert(not string.find(pfUI.xp.bar.text.text,'同等经验',1,true))
  local n=#objects;for i=1,30 do pfUI.xpbar:UpdateConfig()end;assert(#objects==n)
  pfUI.xpbar:ResetProgress();assert(pfUI.xpbar.progress.gained==0 and pfUI.xpbar.progress.lastGain==nil)''')
 def test_real_legacy_handoff_stops_events_and_preserves_saved_state(self):
  self.check('''local m=Automaton.modules.ExpBar;local config=m.db.profile;local position=config.position;local manager=pfUI.automationIntegrations.ExpBar
  assert(Automaton_ExpBarContainer:IsShown() and next(m.events));assert(manager:Sync(true));assert(not Automaton_ExpBarContainer:IsShown() and not next(m.events))
  for i=1,10 do m:OnEnable();manager:Sync(true)end;assert(not next(m.events) and not Automaton_ExpBarContainer:IsShown())
  manager:SetEnabled(false);assert(not pfUI.xp:IsShown() and pfUI.rep:IsShown());manager:SetEnabled(true);assert(pfUI.xp:IsShown())
  manager:Sync(false);assert(Automaton_ExpBarContainer:IsShown() and next(m.events));assert(config.position==position and config.width==410 and Automaton.disabled.ExpBar==nil)''',True)
 def test_disabled_legacy_not_revived_and_native_reset_not_legacy_position(self):
  self.check('''local m=Automaton.modules.ExpBar;Automaton.disabled.ExpBar=true;m:OnDisable();local original=m.db.profile.position
  local manager=pfUI.automationIntegrations.ExpBar;manager:Sync(true)
  C.position.pfExperienceBar={anchor='TOP',xpos=88,ypos=-44};m:ResetPosition();assert(C.position.pfExperienceBar==nil and m.db.profile.position==original)
  manager:Sync(false);assert(not next(m.events) and not Automaton_ExpBarContainer:IsShown())''',True)
 def test_disabled_native_imports_legacy_once_and_fallback_restores_owners(self):
  self.check('''C.panel.xp.xp_display='DISABLED';pfUI.xpbar:UpdateConfig()
  local m=pfUI.automationIntegrations.ExpBar;assert(m:Sync(true));assert(C.panel.xp.xp_display=='XPFLEX' and pfUI.xp:IsShown() and not Automaton_ExpBarContainer:IsShown())
  m:SetEnabled(false);m:Sync(true);assert(C.panel.xp.xp_display=='DISABLED','import overwrote later choice')
  m:Sync(false);assert(C.panel.xp.xp_display=='DISABLED' and not pfUI.xp:IsShown() and Automaton_ExpBarContainer:IsShown())
  m:Sync(true);assert(C.panel.xp.xp_display=='DISABLED' and not Automaton_ExpBarContainer:IsShown())
  m:SetEnabled(true);m:Sync(false);m:Sync(true);assert(C.panel.xp.xp_display=='XPFLEX')''',True)
 def test_both_disabled_do_not_gain_native_display(self):
  self.check('''C.panel.xp.xp_display='DISABLED';Automaton.disabled.ExpBar=true;Automaton.modules.ExpBar:OnDisable();pfUI.xpbar:UpdateConfig()
  local m=pfUI.automationIntegrations.ExpBar;m:Sync(true);assert(C.panel.xp.xp_display=='DISABLED');m:Sync(false);assert(not Automaton_ExpBarContainer:IsShown())''',True)
 def test_late_module_does_not_claim_uninitialized_engine(self):
  self.check('''local manager=pfUI.automationIntegrations.ExpBar;assert(not manager:Sync(true) and not manager.active)''')

if __name__=='__main__':unittest.main(verbosity=2)
