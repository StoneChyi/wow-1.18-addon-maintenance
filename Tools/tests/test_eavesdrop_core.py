"""EavesDrop core regressions against actual Lua 5.1 addon functions.

Most cases stub the UI/enhanced adapters; one case loads all three actual modules.
XML font inheritance and failed SetFont obey the strict 1.12 font contract.
"""
from pathlib import Path
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / "Interface/AddOns/EavesDrop"
PARSER = ROOT / "Interface/AddOns/!Libs/ParserLib/ParserLib.lua"
ACEDB = ROOT / "Interface/AddOns/!Libs/Ace2/AceDB-2.0/AceDB-2.0.lua"
FONT = ROOT / "Tools/tests/wow112_fontstring_mock.lua"


def method(source, name):
    start = re.search(r"^function " + re.escape(name) + r"\(", source, re.M)
    assert start, name
    end = re.search(r"^function ", source[start.end():], re.M)
    return source[start.start():start.end() + end.start()] if end else source[start.start():]


STUB = r'''
local installFontContract = ...
methods = {}; objects = {}
function newObject(kind,name,parent)
  local o=setmetatable({kind=kind,name=name,parent=parent,shown=true,alpha=1,
    width=200,height=20,points={}}, {__index=methods})
  if name then _G[name]=o end
  table.insert(objects,o)
  return o
end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:SetWidth(v) self.width=v end
function methods:GetWidth() return self.width end
function methods:SetHeight(v) self.height=v end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.points={...} end
function methods:ClearAllPoints() self.points={} end
function methods:SetJustifyH(v) self.justify=v end
function methods:SetTexCoord(...) self.texcoord={...} end
function methods:SetTexture(v) self.texture=v end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:SetBackdropBorderColor(...) self.border={...} end
function methods:SetGradientAlpha(...) self.gradient={...} end
function methods:SetTextColor(...) self.color={...} end
function methods:EnableMouse(v) self.mouse=v end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function methods:UnregisterEvent(e) if self.events then self.events[e]=nil end end
installFontContract(methods,newObject)
function FS(name) local o=newObject('FontString',name); o:SetFontObject(GameFontNormal); return o end
for _,name in ipairs({'EavesDropFrame','EavesDropHistoryFrame','EavesDropTab',
  'EavesDropFrameUpButton','EavesDropFrameDownButton','EavesDropHistoryButton',
  'EavesDropHistoryScrollBar','EavesDropTopBar','EavesDropBottomBar',
  'EavesDropHistoryTopBar','EavesDropHistoryBottomBar','EavesDropHistoryFrameOutgoingHit',
  'EavesDropHistoryFrameOutgoingHeal','EavesDropHistoryFrameIncomingHit',
  'EavesDropHistoryFrameIncomingHeal'}) do newObject('Frame',name) end
for _,name in ipairs({'EavesDropFramePlayerText','EavesDropFrameTargetText',
  'EavesDropHistoryFrameSkillText','EavesDropHistoryFrameAmountCritText',
  'EavesDropHistoryFrameAmountNormalText','EavesDropHistoryFrameResetText'}) do FS(name) end
for i=1,20 do
  newObject('Frame','EavesDropEvent'..i)
  FS('EavesDropEvent'..i..'EventText')
  for _,s in ipairs({'Incoming','Outgoing','IncomingTexture','OutgoingTexture'}) do
    newObject('Texture','EavesDropEvent'..i..s)
  end
end
for i=1,10 do
  newObject('Frame','EavesDropHistoryEvent'..i)
  newObject('Texture','EavesDropHistoryEvent'..i..'_Texture')
  for _,s in ipairs({'_Skill','_Hit','_Crit'}) do FS('EavesDropHistoryEvent'..i..s) end
end
function getglobal(k) return _G[k] end
getn=table.getn; tremove=table.remove; tinsert=table.insert
strupper=string.upper
function date() return '2026-10-26 12:00:00' end
function UnitName(u)
  if u=='player' then return 'Tester' elseif u=='pet' then return 'Wolf'
  elseif u=='party1' then return 'Ally' end
end
function GetNumPartyMembers() return 1 end
function GetNumRaidMembers() return 0 end
function UnitHealthMax() return 1000 end
function UnitHealth() return 900 end
function SetPortraitTexture(t,u) t.texture='portrait:'..u end
function IsShiftKeyDown() return false end
function FauxScrollFrame_GetOffset(f) return f.offset or 0 end
function FauxScrollFrame_SetOffset(f,o) f.offset=o end
function FauxScrollFrame_Update(...) end
ParserLib_SELF='SELF'; ParserLib_MELEE='MELEE'; ParserLib_DAMAGESHIELD='SHIELD'
MELEE_ATTACK='Melee'; HEALTH='Health'; MISS='Miss'; XP='XP'; HONOR='Honor'
CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF='Damage shield'
for i=0,6 do _G['SPELL_SCHOOL'..i..'_CAP']='School'..i end
local L=setmetatable({}, {__index=function(t,k) return k end})
local addonMethods={}
function deepcopy(v)
  if type(v)~='table' then return v end
  local out={}; for k,x in pairs(v) do out[k]=deepcopy(x) end; return out
end
saved={currentProfile={Tester='Default'}, disabled={}}
function addonMethods:RegisterDB() self.db={raw=saved,profile={},char={}} end
function addonMethods:RegisterDefaults(scope,defaults)
  self.defaults=self.defaults or {}; self.defaults[scope]=deepcopy(defaults)
  for k,v in pairs(defaults) do if self.db[scope][k]==nil then self.db[scope][k]=deepcopy(v) end end
end
function addonMethods:ResetDB(scope) self.db[scope]=deepcopy(self.defaults[scope]) end
function addonMethods:RegisterChatCommand(commands,handler) self.command=handler end
function addonMethods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function addonMethods:UnregisterEvent(e) self.events[e]=nil end
function addonMethods:IsEventRegistered(e) return self.events and self.events[e] end
function addonMethods:UnregisterAllEvents() self.events={} end
function addonMethods:RegisterMetro() self.metroRegistered=true; self.metroRunning=false end
function addonMethods:UnregisterMetro() self.metroRegistered=false; self.metroRunning=false end
function addonMethods:MetroStatus() return nil,nil,self.metroRunning end
function addonMethods:StartMetro() assert(self.metroRegistered); self.metroRunning=true end
function addonMethods:StopMetro() self.metroRunning=false end
local libraries={
 ['AceAddon-2.0']={new=function() return setmetatable({}, {__index=addonMethods}) end},
 ['AceLocale-2.2']={new=function() return L end},
 ['Babble-Spell-2.2']={GetSpellIcon=function() return 'test-icon' end},
 ['Waterfall-1.0']={Register=function()end,Open=function() legacyOpened=true end},
 ['Dewdrop-2.0']={}
}
AceLibrary=function(name) assert(libraries[name],name); return libraries[name] end
parser={clients={},frame=newObject('Frame'),Print=function(self,msg)error(msg)end}
function parser:PreLoadPatternInfo() end
ParserLib={GetInstance=function() return parser end}
AceOO={Class={},inherits=function()return false end}
AceDB={argCheck=function()end}; AceEvent=nil; charID='Tester'
function safecall(f,...) return f(...) end
function installActiveMethods() addonMethods.IsActive=AceDB.IsActive; addonMethods.ToggleActive=AceDB.ToggleActive end
function installAdapters()
  function EavesDrop:StartEnhancedEvents() self.enhancedStarted=(self.enhancedStarted or 0)+1 end
  function EavesDrop:StopEnhancedEvents() self.enhancedStopped=(self.enhancedStopped or 0)+1 end
  function EavesDrop:ShouldSuppressLegacy(info) return false end
  function EavesDrop:ApplySkin() end
  function EavesDrop:OpenSettings() self.settingsOpened=true end
  function EavesDrop:UpdateSettings() self.settingsRefreshed=true end
  function EavesDrop:UpdateReadIndicator(n,overflow) self.indicator={n=n,overflow=overflow} end
end
function emit(n) EavesDrop:DisplayEvent(1,tostring(n),nil,EavesDrop.db.profile.MISC) end
function fill(n) for i=1,n do emit(i) end end
function render() local out={}; for i=1,10 do out[i]=_G['EavesDropEvent'..i..'EventText'].text end;return table.concat(out,'|') end
'''


def runtime(enabled=True, capacity=128):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB, lua.execute(FONT.read_text(encoding="utf-8-sig")))
    parser = PARSER.read_text(encoding="utf-8-sig")
    supported = re.search(r"lib.supportedEvents = (\{.*?\n\})", parser, re.S).group(1)
    lua.execute("parser.supportedEvents=" + supported)
    for name in ("RegisterEvent", "IsEventRegistered", "UnregisterEvent", "UnregisterAllEvents"):
        lua.execute(method(parser, "lib:" + name).replace("function lib:", "function parser:"))
    acedb = ACEDB.read_text(encoding="utf-8-sig")
    # Keep the real active-state methods and their local profile key in one chunk.
    lua.execute("local charID='Tester';\n" + method(acedb, "AceDB:IsActive") + method(acedb, "AceDB:ToggleActive"))
    lua.execute("installActiveMethods()")
    for name in ("EavesDrop.lua", "options.lua", "EavesDropStats.lua"):
        lua.execute((ADDON / name).read_text(encoding="utf-8-sig"))
    lua.execute("installAdapters(); EavesDrop:OnInitialize()")
    lua.execute(f"EavesDrop.db.profile.HISTORYLIMIT={capacity}; EavesDrop:ResizeHistory()")
    if enabled:
        lua.execute("EavesDrop:OnEnable()")
    return lua


INTEGRATION = r'''
-- Additional real-UI/native-event boundaries for the three-module integration.
-- These are 1.12 frame APIs, not replacements for any addon adapter methods.
UISpecialFrames={}
function CreateFrame(kind,name,parent) return newObject(kind,name,parent) end
function methods:SetScript(k,v) self.scripts=self.scripts or {}; self.scripts[k]=v end
function methods:GetScript(k) return self.scripts and self.scripts[k] end
function methods:GetParent() return self.parent end
function methods:SetParent(v) self.parent=v end
function methods:SetHitRectInsets(...) self.hitInsets={...} end
function methods:CreateTexture(name,layer) return newObject('Texture',name,self) end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetMovable(v) self.movable=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:RegisterForDrag(...) self.drag={...} end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:GetTextColor() return unpack(self.color or {1,1,1,1}) end
function methods:SetOrientation(v) self.orientation=v end
function methods:SetThumbTexture(v) self.thumb=newObject('Texture',nil,self); self.thumb.texture=v end
function methods:GetThumbTexture() return self.thumb end
function methods:SetVertexColor(...) self.vertex={...} end
function methods:SetNormalTexture(v) self.normal=v end
function methods:SetPushedTexture(v) self.pushed=v end
function methods:SetHighlightTexture(v) self.highlight=v end
function methods:SetDisabledTexture(v) self.disabledTexture=v end
function methods:GetNormalTexture() return type(self.normal)=='table' and self.normal or nil end
function methods:GetPushedTexture() return type(self.pushed)=='table' and self.pushed or nil end
function methods:GetFontString() return self.caption end
function methods:SetAutoFocus(v) self.autofocus=v end
function methods:SetTextInsets(...) self.insets={...} end
function methods:ClearFocus() self.focused=false end
function methods:GetText() return self.text or '' end
function methods:SetMinMaxValues(low,high) self.low,self.high=low,high end
function methods:SetValueStep(v) self.step=v end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(v)
  self.value=v
  if self.scripts and self.scripts.OnValueChanged then invoke(self,'OnValueChanged') end
end
function methods:UnregisterAllEvents() self.events={} end
function methods:IsEventRegistered(e) return self.events and self.events[e] end
function methods:SetOwner(...) self.owner={...} end
function invoke(obj,script)
  local old=this; this=obj
  local fn=obj:GetScript(script); if fn then fn() end
  this=old
end
UIParent=newObject('Frame','UIParent')
GameTooltip=newObject('GameTooltip','GameTooltip',UIParent)
ColorPickerFrame=newObject('Frame','ColorPickerFrame',UIParent)
OpacitySliderFrame=newObject('Slider','OpacitySliderFrame',UIParent)
function ColorPickerFrame:SetColorRGB(r,g,b) self.rgb={r,g,b} end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb or {1,1,1}) end
function EavesDrop:GetProfile() return 'Default' end
MANA='Mana'; RAGE='Rage'; FOCUS='Focus'; ENERGY='Energy'; HAPPINESS='Happiness'
playerGuid='0x0000000000000001'; petGuid='0x0000000000000002'
enemyGuid='0x0000000000000003'; allyGuid='0x0000000000000004'
GetNampowerVersion=function()return 4,6,1 end
GetUnitGUID=function(u)if u=='player' then return playerGuid elseif u=='pet' then return petGuid end end
local originalUnitName=UnitName
UnitName=function(u)
  if u==playerGuid then return 'Tester' elseif u==petGuid then return 'Wolf'
  elseif u==enemyGuid then return 'Enemy' elseif u==allyGuid then return 'Ally'
  else return originalUnitName(u) end
end
GetSpellRecField=function(id,key)if key=='name' then return 'Spell'..id elseif key=='spellIconID' then return 5 end end
GetSpellIconTexture=function()return 'SpellIcon' end
SetCVar=function()error('Integration must not change global CVars')end
function native(name,...)
  local f=EavesDrop.enhancedFrame
  assert(f and f:IsEventRegistered(name),'native event not registered: '..name)
  event=name
  arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9=unpack({...})
  invoke(f,'OnEvent')
  event=nil; arg1=nil; arg2=nil; arg3=nil; arg4=nil; arg5=nil; arg6=nil; arg7=nil; arg8=nil; arg9=nil
end
function legacy(channel,info)
  local clients=parser.clients[channel]; assert(clients and #clients==1)
  clients[1].func(channel,info)
end
'''


class EavesDropCoreTests(unittest.TestCase):
    def test_xml_window_starts_hidden(self):
        tree = ET.parse(ADDON / "EavesDrop.xml")
        frame = tree.find("{http://www.blizzard.com/wow/ui/}Frame[@name='EavesDropFrame']")
        self.assertEqual(frame.attrib.get("hidden"), "true")

    def test_disabled_initialization_hides_both_windows(self):
        lua = runtime(False)
        lua.execute("saved.disabled.Default=true; EavesDropFrame:Show(); EavesDropHistoryFrame:Show(); EavesDrop:OnInitialize(); assert(not EavesDropFrame:IsShown()); assert(not EavesDropHistoryFrame:IsShown()); assert(not EavesDrop:IsActive()); assert(next(parser.clients)==nil)")

    def test_disable_refresh_and_command_reenable(self):
        lua = runtime()
        lua.execute("EavesDrop.command('disable'); assert(not EavesDrop:IsActive()); assert(not EavesDrop._running); EavesDrop:RefreshProfile(); assert(next(parser.clients)==nil); assert(next(EavesDrop.events)==nil); assert(not EavesDropFrame:IsShown()); assert(not EavesDropHistoryFrame:IsShown()); EavesDrop.command(''); assert(EavesDrop.settingsOpened); EavesDrop.command('enable'); assert(EavesDrop:IsActive()); assert(EavesDrop._running); assert(EavesDropFrame:IsShown()); assert(parser.clients.CHAT_MSG_SPELL_PARTY_BUFF)")

    def test_saved_profile_disable_survives_fresh_addon_instance(self):
        lua = runtime()
        lua.execute("EavesDrop:ToggleActive(false); assert(saved.disabled.Default)")
        for name in ("EavesDrop.lua", "options.lua", "EavesDropStats.lua"):
            lua.execute((ADDON / name).read_text(encoding="utf-8-sig"))
        lua.execute("installAdapters(); EavesDrop:OnInitialize(); if EavesDrop:IsActive() then EavesDrop:OnEnable() end; assert(not EavesDrop:IsActive()); assert(not EavesDropFrame:IsShown()); assert(next(parser.clients)==nil)")

    def test_reading_anchor_survives_new_records(self):
        lua = runtime()
        lua.execute("fill(40); EavesDrop:ScrollUp(); local before=render(); for i=41,70 do emit(i) end; assert(render()==before); EavesDrop:UpdateEvents(); assert(render()==before); assert(EavesDrop:GetHistoryState().unseen==30); assert(EavesDrop.indicator.n==30)")

    def test_reading_survives_complete_live_buffer_recycle(self):
        lua = runtime()
        lua.execute("fill(128); EavesDrop:ScrollToTop(); local before=render(); for i=129,400 do emit(i) end; EavesDrop:UpdateEvents(); assert(render()==before); assert(EavesDrop:GetHistoryState().overflow); assert(EavesDrop:GetHistoryState().count==128)")

    def test_reading_does_not_fade(self):
        lua = runtime()
        lua.execute("fill(30); EavesDrop:ScrollUp(); local a=EavesDropEvent1:GetAlpha(); local delay=EavesDropEvent1.delay; EavesDrop:OnUpdate(1000); assert(EavesDropEvent1:GetAlpha()==a); assert(EavesDropEvent1.delay==delay); assert(EavesDropEvent1:IsShown())")

    def test_return_bottom_resumes_live_follow(self):
        lua = runtime()
        lua.execute("fill(30); EavesDrop:ScrollUp(); emit(31); EavesDrop:ScrollToBottom(); assert(not EavesDrop:GetHistoryState().reading); assert(EavesDrop:GetHistoryState().unseen==0); assert(EavesDropEvent10EventText.text=='31'); emit(32); assert(EavesDropEvent10EventText.text=='32')")

    def test_scrolling_down_into_bottom_resumes_follow(self):
        lua = runtime()
        lua.execute("fill(30); EavesDrop:ScrollUp(); emit(31); EavesDrop:ScrollDown(); assert(not EavesDrop:GetHistoryState().reading); assert(EavesDropEvent10EventText.text=='31')")

    def test_short_history_never_scrolls_into_blank_rows(self):
        lua = runtime()
        lua.execute("fill(5); EavesDrop:ScrollUp(); assert(not EavesDrop:GetHistoryState().reading); assert(EavesDrop:GetHistoryState().offset==0); EavesDrop:ScrollToTop(); assert(EavesDrop:GetHistoryState().offset==0); emit(6); assert(EavesDropEvent10EventText.text=='6')")

    def test_resize_preserves_latest_records_and_clamps(self):
        lua = runtime(capacity=512)
        lua.execute("fill(500); EavesDrop.db.profile.HISTORYLIMIT=128; EavesDrop:ResizeHistory(); assert(EavesDrop:GetHistoryState().count==128); assert(EavesDropEvent10EventText.text=='500'); EavesDrop.db.profile.HISTORYLIMIT=2048; EavesDrop:ResizeHistory(); assert(EavesDropEvent10EventText.text=='500'); EavesDrop:ScrollToTop(); assert(EavesDrop:GetHistoryState().offset==118); EavesDrop.db.profile.HISTORYLIMIT=99999; EavesDrop:ResizeHistory(); assert(EavesDrop:GetHistoryState().capacity==2048)")

    def test_pet_toggle_never_removes_player_subscription(self):
        lua = runtime()
        lua.execute("for i=1,8 do EavesDrop.db.profile.PET=true; EavesDrop:UpdatePetEvents(); EavesDrop.db.profile.PET=false; EavesDrop:UpdatePetEvents() end; assert(#parser.clients.CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS==1); assert(#parser.clients.CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF==1)")

    def test_refresh_does_not_duplicate_parser_subscriptions(self):
        lua = runtime()
        lua.execute("for i=1,4 do EavesDrop:RefreshProfile() end; for event,clients in pairs(parser.clients) do assert(#clients==1,'duplicate subscription: '..event) end")

    def test_player_party_heal_and_pet_heal_directions(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.PET=true; EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim=ParserLib_SELF,skill='Heal',amount=25}); assert(EavesDrop.db.char.Stats[-1].heal.Heal[-2].amount==25); EavesDrop:RouteCombatEvent({type='heal',source='Wolf',victim='Ally',skill='Mend',amount=30}); assert(EavesDrop.db.char.Stats[1].heal.Mend[-2].amount==30); assert(EavesDropEvent10EventText.color[1]==EavesDrop.db.profile.PETO.r); EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim='Wolf',skill='Pet Heal',amount=35}); assert(EavesDrop.db.char.Stats[-1].heal['Pet Heal'][-2].amount==35); assert(EavesDropEvent10EventText.color[1]==EavesDrop.db.profile.PETI.r)")

    def test_enhanced_pet_damage_uses_guid_identity_and_direction(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.PET=true; EavesDrop:RouteCombatEvent({type='hit',source='Enemy',victim='Wolf',skill=ParserLib_MELEE,amount=42,enhanced=true,victimIsPet=true}); assert(EavesDropEvent10EventText.text=='-42'); EavesDrop:RouteCombatEvent({type='hit',source='Wolf',victim='Enemy',skill=ParserLib_MELEE,amount=45,enhanced=true,sourceIsPet=true}); assert(EavesDropEvent10EventText.text=='45')")

    def test_route_ignores_other_units_and_respects_disabled_pets(self):
        lua = runtime()
        lua.execute("EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim='Enemy',skill='Heal',amount=10}); assert(EavesDrop:GetHistoryState().count==0); EavesDrop:RouteCombatEvent({type='hit',source='Wolf',victim='Enemy',skill=ParserLib_MELEE,amount=20}); assert(EavesDrop:GetHistoryState().count==0)")

    def test_event_tooltip_and_stats_keep_explicit_enhanced_message(self):
        lua = runtime()
        lua.execute("arg1='stale unrelated event'; EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim=ParserLib_SELF,skill='Heal',amount=25,message='actual enhanced heal',enhanced=true}); assert(string.find(EavesDropEvent10.tooltipText,'actual enhanced heal',1,true)); assert(string.find(EavesDrop.db.char.Stats[-1].heal.Heal[-2].time,'actual enhanced heal',1,true)); assert(EavesDrop.eventMessage==nil)")

    def test_font_failure_retains_initialized_font_on_empty_and_reuse_paths(self):
        lua = runtime()
        lua.execute(r"failedFontPaths['Fonts\FZXHLJW.TTF']=true; EavesDropEvent1EventText.font=nil; EavesDrop:UpdateEvents(); fill(20); EavesDrop:ScrollUp(); EavesDrop:PerformDisplayOptions(); EavesDrop:UpdateEvents(); for i=1,10 do assert(_G['EavesDropEvent'..i..'EventText'].font) end")

    def test_disabled_runtime_rejects_late_combat_callbacks(self):
        lua = runtime()
        lua.execute("EavesDrop:ToggleActive(false); EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim=ParserLib_SELF,skill='Heal',amount=25}); emit(100); assert(EavesDrop:GetHistoryState().count==0)")

    def test_enhanced_route_bypasses_only_legacy_category_suppression(self):
        lua = runtime()
        lua.execute("function EavesDrop:ShouldSuppressLegacy(info) return info.type=='heal' end; EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim=ParserLib_SELF,skill='Heal',amount=25}); assert(EavesDrop:GetHistoryState().count==0); EavesDrop:RouteCombatEvent({type='heal',source='Ally',victim=ParserLib_SELF,skill='Heal',amount=25,enhanced=true}); assert(EavesDrop:GetHistoryState().count==1)")

    def test_repeated_enable_keeps_single_subscription(self):
        lua = runtime()
        lua.execute("EavesDrop:OnEnable(); EavesDrop:OnEnable(); for event,clients in pairs(parser.clients) do assert(#clients==1,'duplicate subscription: '..event) end")

    def test_reading_snapshot_remains_visible_across_disable_enable_with_fade(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.FADEFRAME=true; fill(30); EavesDrop:ScrollUp(); local before=render(); EavesDrop:ToggleActive(false); EavesDrop:ToggleActive(true); assert(EavesDrop:GetHistoryState().reading); assert(EavesDropFrame:IsShown() and EavesDropFrame:GetAlpha()==1); assert(render()==before); EavesDrop:OnUpdate(1000); assert(EavesDropFrame:GetAlpha()==1)")

    def test_disabling_fade_while_monitor_off_clears_stale_alpha_on_enable(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.FADEFRAME=true; EavesDrop:HideFrame(); assert(EavesDropFrame:GetAlpha()==0); EavesDrop:ToggleActive(false); EavesDrop.db.profile.FADEFRAME=false; EavesDrop:ToggleActive(true); assert(EavesDropFrame:IsShown() and EavesDropFrame:GetAlpha()==1)")

    def test_profile_without_fade_restores_window_alpha(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.FADEFRAME=true; EavesDrop:HideFrame(); EavesDrop.db.profile.FADEFRAME=false; EavesDrop:OnProfileEnable(); assert(EavesDropFrame:GetAlpha()==1); EavesDrop.db.profile.FADEFRAME=true; EavesDrop:HideFrame(); EavesDrop.db.profile.FADEFRAME=false; EavesDrop:PerformDisplayOptions(); assert(EavesDropFrame:GetAlpha()==1)")

    def test_entering_world_refreshes_sources_only_while_active(self):
        lua = runtime()
        lua.execute("assert(EavesDrop:IsEventRegistered('PLAYER_ENTERING_WORLD')); local started=EavesDrop.enhancedStarted; EavesDrop.enhancedNeedsRetry=false; EavesDrop:PLAYER_ENTERING_WORLD(); assert(EavesDrop.enhancedStarted==started,'valid source was needlessly restarted'); EavesDrop.enhancedNeedsRetry=true; EavesDrop:PLAYER_ENTERING_WORLD(); assert(EavesDrop.enhancedStarted==started+1); EavesDrop:ToggleActive(false); local stopped=EavesDrop.enhancedStopped; started=EavesDrop.enhancedStarted; EavesDrop.enhancedNeedsRetry=true; EavesDrop:PLAYER_ENTERING_WORLD(); assert(EavesDrop.enhancedStarted==started and EavesDrop.enhancedStopped==stopped); assert(not EavesDrop:IsEventRegistered('PLAYER_ENTERING_WORLD'))")

    def test_entering_world_retries_real_adapter_after_initial_guid_unavailable(self):
        lua = runtime()
        lua.execute(INTEGRATION)
        lua.execute((ADDON / "enhanced.lua").read_text(encoding="utf-8-sig"))
        lua.execute("local availableGuid=GetUnitGUID; GetUnitGUID=function()return nil end; EavesDrop:RefreshCombatSources(); assert(not EavesDrop.enhancedFrame); GetUnitGUID=availableGuid; EavesDrop:PLAYER_ENTERING_WORLD(); assert(EavesDrop.enhancedFrame:IsEventRegistered('SPELL_HEAL_BY_OTHER')); native('SPELL_HEAL_BY_OTHER',playerGuid,allyGuid,42,50,0,0); assert(EavesDrop:GetHistoryState().count==1); EavesDrop:ToggleActive(false); EavesDrop:PLAYER_ENTERING_WORLD(); assert(next(EavesDrop.enhancedFrame.events)==nil)")

    def test_real_core_ui_enhanced_integration(self):
        lua = runtime()
        lua.execute(INTEGRATION)
        for name in ("ui.lua", "enhanced.lua"):
            lua.execute((ADDON / name).read_text(encoding="utf-8-sig"))
        lua.execute(r'''
          EavesDrop:RefreshCombatSources(); EavesDrop:ApplySkin(); EavesDrop:OpenSettings()
          assert(EavesDrop.enhancedFrame:IsEventRegistered('SPELL_HEAL_BY_OTHER'))
          assert(EavesDrop.enhancedFrame:IsEventRegistered('AUTO_ATTACK_SELF'))
          local panel=EavesDropSettingsFrame
          assert(panel:IsShown() and panel.title.font and panel.rows[1].label.font)
          native('SPELL_HEAL_BY_OTHER',playerGuid,allyGuid,42,50,0,0)
          assert(EavesDrop:GetHistoryState().count==1)
          assert(string.find(EavesDropEvent10EventText.text,'50',1,true) and string.sub(EavesDropEvent10EventText.text,1,1)=='+')
          assert(EavesDrop.db.char.Stats[-1].heal.Spell42[-2].amount==50)
          native('AUTO_ATTACK_SELF',playerGuid,enemyGuid,40,0,1,1,0,0,0)
          assert(EavesDrop:GetHistoryState().count==2)
          assert(string.find(EavesDropEvent10EventText.text,'40',1,true))
          legacy('CHAT_MSG_SPELL_PARTY_BUFF',{type='heal',source='Ally',victim=ParserLib_SELF,skill='Spell42',amount=50})
          legacy('CHAT_MSG_COMBAT_SELF_HITS',{type='hit',source=ParserLib_SELF,victim='Enemy',skill=ParserLib_MELEE,amount=40})
          assert(EavesDrop:GetHistoryState().count==2,'enhanced+legacy double counted')

          -- Switch the real settings control, not a direct configuration stub.
          invoke(panel.nav[4],'OnClick'); invoke(panel.rows[1].action,'OnClick')
          assert(EavesDrop.db.profile.DATASOURCE=='legacy')
          assert(not EavesDrop.enhancedFrame:IsEventRegistered('SPELL_HEAL_BY_OTHER'))
          legacy('CHAT_MSG_SPELL_PARTY_BUFF',{type='heal',source='Ally',victim=ParserLib_SELF,skill='Spell42',amount=51})
          assert(EavesDrop:GetHistoryState().count==3)
          assert(string.find(EavesDropEvent10EventText.text,'51',1,true) and string.sub(EavesDropEvent10EventText.text,1,1)=='+')
          invoke(panel.rows[1].action,'OnClick')
          assert(EavesDrop.db.profile.DATASOURCE=='auto' and EavesDrop.enhancedFrame:IsEventRegistered('SPELL_HEAL_BY_OTHER'))

          -- Alpha slider calls the real skin without changing foreground alpha.
          invoke(panel.nav[1],'OnClick')
          panel.rows[1].slider:SetValue(.4); panel.rows[2].slider:SetValue(.25)
          assert(math.abs(EavesDropFrame.bg[4]-.4)<.0001)
          assert(math.abs(EavesDropHistoryFrame.bg[4]-.4)<.0001)
          assert(math.abs(panel.bg[4]-.25)<.0001 and panel:GetAlpha()==1)
          panel.rows[3].slider:SetValue(.35); panel.rows[4].slider:SetValue(0)
          assert(math.abs(EavesDropFrame.border[4]-.35)<.0001)
          assert(math.abs(EavesDropHistoryFrame.border[4]-.35)<.0001)
          assert(panel.border[4]==0 and panel:GetAlpha()==1)
          assert(math.abs(panel.bg[4]-.25)<.0001 and math.abs(EavesDropFrame.bg[4]-.4)<.0001)

          invoke(panel.enabled,'OnClick')
          assert(not EavesDrop:IsActive() and not EavesDropFrame:IsShown())
          assert(next(parser.clients)==nil and next(EavesDrop.enhancedFrame.events)==nil)
          assert(panel:IsShown(),'disabling monitor also hid settings')
          EavesDrop:OpenSettings(); invoke(panel.enabled,'OnClick')
          assert(EavesDrop:IsActive() and EavesDropFrame:IsShown())
          assert(EavesDrop.enhancedFrame:IsEventRegistered('AUTO_ATTACK_SELF'))

          for i=1,25 do native('AUTO_ATTACK_SELF',playerGuid,enemyGuid,10+i,0,1,1,0,0,0) end
          EavesDrop:ScrollUp(); local before=render()
          native('SPELL_HEAL_BY_OTHER',playerGuid,allyGuid,42,52,0,0)
          assert(render()==before and EavesDrop:GetHistoryState().unseen==1)
          assert(EavesDrop.readIndicator:IsShown())
          assert(string.find(EavesDrop.readIndicator.caption.text,'+1',1,true))
          invoke(EavesDrop.readIndicator,'OnClick')
          assert(not EavesDrop:GetHistoryState().reading)
          assert(string.find(EavesDropEvent10EventText.text,'52',1,true) and string.sub(EavesDropEvent10EventText.text,1,1)=='+')
          assert(not EavesDrop.readIndicator:IsShown())
        ''')


    def test_empty_auto_hidden_window_stays_hidden_until_new_event(self):
        lua = runtime()
        lua.execute("EavesDrop.db.profile.FADEFRAME=true; EavesDrop:HideFrame(); EavesDrop:OnUpdate(.1); assert(EavesDropFrame:GetAlpha()==0); EavesDrop:OnUpdate(.1); assert(EavesDropFrame:GetAlpha()==0); emit(10); EavesDrop:OnUpdate(.1); assert(EavesDropFrame:GetAlpha()==1)")

    def test_utility_skin_preserves_xml_click_actions(self):
        lua = runtime()
        lua.execute(INTEGRATION)
        tree = ET.parse(ADDON / "EavesDrop.xml")
        ns = "{http://www.blizzard.com/wow/ui/}"
        for name, variable in (("$parentUpButton", "upClick"), ("$parentDownButton", "downClick"), ("EavesDropHistoryButton", "historyClick")):
            element = next(e for e in tree.iter(ns + "Button") if e.attrib.get("name") == name)
            source = element.find(ns + "Scripts/" + ns + "OnClick").text
            lua.globals()[variable] = lua.eval("function()\n" + source + "\nend")
        lua.execute("EavesDropFrameUpButton:SetScript('OnClick',upClick); EavesDropFrameDownButton:SetScript('OnClick',downClick); EavesDropHistoryButton:SetScript('OnClick',historyClick); function PlaySound()end; shift=false; IsShiftKeyDown=function()return shift end")
        lua.execute((ADDON / "ui.lua").read_text(encoding="utf-8-sig"))
        lua.execute("EavesDrop:ApplySkin(); assert(EavesDropFrameUpButton:GetScript('OnClick')==upClick and EavesDropFrameDownButton:GetScript('OnClick')==downClick and EavesDropHistoryButton:GetScript('OnClick')==historyClick); fill(30); invoke(EavesDropFrameUpButton,'OnClick'); assert(EavesDrop:GetHistoryState().offset==1); shift=true; invoke(EavesDropFrameUpButton,'OnClick'); assert(EavesDrop:GetHistoryState().offset==20); shift=false; invoke(EavesDropFrameDownButton,'OnClick'); assert(EavesDrop:GetHistoryState().offset==19); shift=true; invoke(EavesDropFrameDownButton,'OnClick'); assert(not EavesDrop:GetHistoryState().reading); invoke(EavesDropHistoryButton,'OnClick'); assert(EavesDropHistoryFrame:IsShown()); invoke(EavesDropHistoryButton,'OnClick'); assert(not EavesDropHistoryFrame:IsShown()); shift=false; invoke(EavesDropFrameUpButton,'OnClick'); emit(31); invoke(EavesDrop.readIndicator,'OnClick'); assert(not EavesDrop:GetHistoryState().reading and EavesDrop:GetHistoryState().unseen==0)")


if __name__ == "__main__":
    unittest.main(verbosity=2)
