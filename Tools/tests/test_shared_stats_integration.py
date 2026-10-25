"""Shared-stat integration and approved remaining updates; no game actions."""
from pathlib import Path
import argparse,sys,re
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
ap=argparse.ArgumentParser();ap.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns');ADDONS=ap.parse_args().addons

def raw(path):return (ADDONS/path).read_bytes().removeprefix(b'\xef\xbb\xbf')
def function(path,name):
    text=raw(path).decode('utf-8',errors='surrogateescape').replace('\r\n','\n')
    start=text.index('function '+name+'(');end=re.search(r'\nend(?:\n|$)',text[start:])
    return text[start:start+end.start()+4]
def fixture(name):return (ROOT/'Tools/tests/fixtures'/name).read_text(encoding='utf-8')

r=LuaRuntime(unpack_returned_tuples=True)
r.execute(r"""
units={player='Self',target='Target'};renders={};frames={}
function UnitExists(unit) return units[unit]~=nil end
function UnitName(unit) return units[unit] end
function getglobal(name) return _G[name] end
function CreateFrame()
 local f={scripts={}}
 function f:SetScript(e,fn) self.scripts[e]=fn end
 table.insert(frames,f);return f
end
function SetPortraitTexture(tex,unit) tex.texture=unit;renders[unit]=(renders[unit] or 0)+1 end
function Panel(name)
 local p={name=name,shown=true}
 function p:GetName() return self.name end
 function p:IsShown() return self.shown end
 local t={};function t:Show() self.shown=true end;function t:GetTexture() return self.texture end
 _G[name..'Portrait']=t;return p
end
function Tick(panel,seconds) local f=panel.portraitUpdateFrame;arg1=seconds;if f.scripts.OnUpdate then f.scripts.OnUpdate() end end
""")
r.execute(function('StatCompare/StatCompare.lua','StatCompare_RefreshPortrait'))
r.execute(r"""
local a,b=Panel('SelfPanel'),Panel('TargetPanel')
StatCompare_RefreshPortrait(a,'player');StatCompare_RefreshPortrait(b,'target')
assert(a.portraitUpdateFrame~=b.portraitUpdateFrame)
local active=a.portraitUpdateFrame.scripts.OnUpdate
StatCompare_RefreshPortrait(a,'player');assert(renders.player==1 and a.portraitUpdateFrame.scripts.OnUpdate==active)
Tick(a,.4);assert(renders.player==1);Tick(a,.1);assert(renders.player==2 and renders.target==1)
Tick(b,.5);assert(renders.target==2)
units.target='Different';Tick(b,1);assert(not b.portraitUpdateFrame.scripts.OnUpdate)
StatCompare_RefreshPortrait(b,'target');assert(renders.target==3)
b.shown=false;Tick(b,1);assert(not b.portraitUpdateFrame.scripts.OnUpdate)
for i=1,20 do Tick(a,40) end
assert(not a.portraitUpdateFrame.scripts.OnUpdate and renders.player==14)
a.scPortraitDirty=true;StatCompare_RefreshPortrait(a,'player');assert(renders.player==15)
SelfPanelPortrait.texture=nil;StatCompare_RefreshPortrait(a,'player');assert(renders.player==16)
units.player=nil;Tick(a,1);assert(not a.portraitUpdateFrame.scripts.OnUpdate)
""")
print('PASS: separate self/target portrait retries, cache-hit preservation, hide/identity/missing-unit cancellation, bounded completion and lost-texture recovery')

r=LuaRuntime(unpack_returned_tuples=True)
r.execute("function IsAddOnLoaded() return true end;BCS={}")
r.execute(function('StatCompare/StatCompareChar/CharStats.lua','StatCompare_GetBCSSpellHit'))
r.execute(r"""
for _,prior in ipairs({false,true,'sentinel'}) do
 BCS.ForceCalculate=prior
 BCS.GetSpellHitRating=function() assert(BCS.ForceCalculate==true);return 5,1,2,0,3,0 end
 assert(StatCompare_GetBCSSpellHit()==8 and BCS.ForceCalculate==prior)
 BCS.GetSpellHitRating=function() error('not ready') end
 assert(StatCompare_GetBCSSpellHit()==nil and BCS.ForceCalculate==prior)
end
BCS.ForceCalculate=nil;assert(StatCompare_GetBCSSpellHit()==nil and BCS.ForceCalculate==nil)
""")
r=LuaRuntime(unpack_returned_tuples=True);r.globals().testClass='WARLOCK';r.execute(fixture('bcs_equipment_tooltip.lua'))
r.execute(raw('BetterCharacterStats/Localization.lua'));r.execute(raw('BetterCharacterStats/helper.lua'))
r.execute(r"""
BCS.GetSpellHitRating=function() return 5,0,0,0,2,0 end
function GetNumTalents() return 1 end
function GetTalentInfo() return BCS.L_TALENT.WARLOCK_SUPPRESSION,nil,nil,nil,5 end
assert(BCS:GetAfflictionHitRating()==17)
local base,_,_,_,shadow=BCS:GetSpellHitRating();assert(base==5 and shadow==2)
function GetTalentInfo() return 'other',nil,nil,nil,5 end
assert(BCS:GetAfflictionHitRating()==7)
""")
print('PASS: force-calculation state restored after success/error, generic spell hit unchanged and Suppression limited to optional Affliction hit')

for mode in ['absent','legacy','skinning']:
 r=LuaRuntime(unpack_returned_tuples=True)
 r.globals().installFontContract=r.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
 stub=fixture('bcs_float_ui.lua').replace('UIParent=CreateFrame("Frame","UIParent")',r"""
installFontContract(Object,object)
strictObject=object
for _,key in ipairs({'SetNormalTexture','SetPushedTexture','SetHighlightTexture','RegisterForClicks','SetFrameLevel','EnableKeyboard','SetNormalFontObject','SetPushedTextOffset','AddDoubleLine','SetTexCoord'}) do Object[key]=function() end end
function Object:GetCenter() return 500,500 end
function Object:GetEffectiveScale() return 1 end
function Object:SetChecked(v) self.checked=v end
function Object:GetChecked() return self.checked end
frames={};local create=CreateFrame
function CreateFrame(...) local f=create(unpack(arg));table.insert(frames,f);return f end
UIParent=CreateFrame("Frame","UIParent")""",1)
 r.execute(stub)
 r.execute(r"""
UISpecialFrames={};Minimap=CreateFrame('Frame','Minimap');tinsert=table.insert
function GetCVar() return '1920x1080' end
function GetScreenHeight() return 1080 end
function UnitAffectingCombat() return false end
registers=0;function UnitXP() registers=registers+1 end
lootCalls=0;corpseCalls=0;skinCalls=0
print=function() end
""")
 if mode!='absent':r.execute("WSLoot={Loot=function() lootCalls=lootCalls+1 end,SetMask=function(v) mask=v end,CorpseTick=function() corpseCalls=corpseCalls+1 end}")
 if mode=='skinning':r.execute('WSLoot.SkinTick=function() skinCalls=skinCalls+1 end')
 r.execute(raw('WushuangLoot/WushuangLoot.lua'))
 r.execute(r"""
assert(WSLootCB2.label=='道具' and WSLootCB2.bit==8 and WSLootCB3.bit==16 and WSLootCB4==nil)
assert(not pcall(function() strictObject('FontString'):SetText('bad') end))
WSLootBindPick();SlashCmdList.WSLootSettings();SlashCmdList.WSLootSettings()
for i=1,3 do
 for _,f in ipairs(frames) do
  if f.scripts.OnUpdate and f~=WSLootMinimapButton then f:Fire('OnUpdate') end
 end
end
""")
 if mode=='absent':assert r.globals().lootCalls==0 and r.globals().skinCalls==0
 else:
  assert r.globals().lootCalls==1 and r.globals().corpseCalls==1 and r.globals().mask==25
  assert r.globals().skinCalls==0
print('PASS: personal WushuangLoot 1.6 UI/strict fonts, original mask/3-frame tick, no SkinTick, missing/legacy DLL dispatch and settings reopen')
