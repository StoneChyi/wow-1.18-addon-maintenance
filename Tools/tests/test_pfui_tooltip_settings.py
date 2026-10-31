"""Tooltip provider options rendered through actual pfUI config controls."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK
lua=LuaRuntime(unpack_returned_tuples=True)
font=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf8'))
lua.execute(MOCK,font)
source=(ROOT/'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf8')
a=source.index('    function CreateConfig(');b=source.index('    local TabFrameOnMouseDown',a)
lua.execute('local searchDB={}\n'+source[a:b]+'\npfUI.gui.CreateConfig=CreateConfig')
lua.execute(r"""
pfUI.gui.frames={};C.tooltip={itemid='0'};pfUI.tooltip=obj('Frame');pfUI.api={}
function Automaton:IsModuleActive(name)return self.modules[name].active end
function Automaton:ToggleModuleActive(name,v)self.modules[name].active=v end
function SetCursorScale(v)cursorScale=v end
function pfUI.gui.CreateGUIEntry(label,title,populate)
 pfUI.gui.frames[label]=pfUI.gui.frames[label] or {}
 local entry={area=obj('Frame')};pfUI.gui.frames[label][title]=entry
 entry.populate=populate
end
""")
lua.execute((ROOT/'Interface/AddOns/Automatonex/Modules/Tooltip.lua').read_text(encoding='utf8'))
lua.execute(r"""
m=Automaton.modules.Tooltip
m.active=true;m.db={profile={showitemid=true,showFrameName=false,cursorScale=1}}
m._options=m.options
m._options.enabled={name='Enabled',type='toggle',order=1,get=function()return Automaton:IsModuleActive('Tooltip')end,set=function(v)Automaton:ToggleModuleActive('Tooltip',v)end}
""")
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf8'))
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/tooltip_extensions.lua').read_text(encoding='utf8'))
lua.execute(r"""
I=pfUI.automationIntegrations.Tooltip
assert(I:Sync(true));assert(C.tooltip.itemid=='1')
local entry=pfUI.gui.frames.Tooltip['增强信息'];assert(entry)
this=parent;entry.populate();this=nil
local count=0
for _,r in ipairs(rows())do if r.widget=='checkbox' then count=count+1 end end
assert(count==15,'unexpected missing tooltip controls '..count)
local r=rowNamed('显示物品ID');r.input:SetChecked(nil);click(r)
assert(C.tooltip.itemid=='0' and m.db.profile.showitemid==true,'shared ID overwrote fallback preference')
r=rowNamed('单位框始终显示提示');r.input:SetChecked(nil);click(r)
assert(m.db.profile.forceUnitTooltip==false and not pfUI.tooltip:ForceUnitTooltip())
r=rowNamed('目标护甲和抗性');r.input:SetChecked(1);click(r);assert(m.db.profile.showResistance==true)
r=rowNamed('框架显示');r.input:SetChecked(1);click(r);assert(m.db.profile.showFrameName and m.frameWatcher:IsShown())
r=rowNamed('框架显示');r.input:SetChecked(nil);click(r);assert(not m.db.profile.showFrameName and not m.frameWatcher:IsShown())
edit(rowNamed('鼠标大小'),'2.34');assert(math.abs(cursorScale-2.3)<.001 and m.db.profile.cursorScale==cursorScale)
r=rowNamed('Enabled');r.input:SetChecked(nil);click(r);assert(not m.active)
r=rowNamed('Enabled');r.input:SetChecked(1);click(r);assert(m.active)
for _,r in ipairs(rows())do
 if r.widget=='checkbox' and r.option.name~='Enabled' and r.option.name~='显示物品ID' then
  local opt=r.option;r.input:SetChecked(1);click(r);assert(opt.get()==true)
  r=rowNamed(opt.name);r.input:SetChecked(nil);click(r);assert(not opt.get())
 end
end
I:Sync(false);I:Refresh();r=rowNamed('显示物品ID');r.input:SetChecked(nil);click(r)
assert(m.db.profile.showitemid==false,'fallback ID setting lost original target')
print('PASS: native tooltip extension page, 15 toggles, shared item ID, original fallback data, unit-frame policy, cursor range, frame watcher and enable state')
""")
