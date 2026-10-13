"""Target/self panel layering against pfUI units; actual 1.12 layout functions.
No FontStrings are constructed by this focused frame-only test.
"""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime
rt = LuaRuntime()
source = (ROOT / "Interface/AddOns/StatCompare/StatCompare.lua").read_text(encoding="utf-8-sig")
rt.execute("assert(loadstring(...))", source)
rt.execute(r'''
objects={}; checks=0
function check(value,label) assert(value,label);checks=checks+1 end
local methods={}
function CreateFrame(kind,name)
 local f=setmetatable({shown=true,strata='LOW',scripts={},writes=0,shows=0}, {__index=methods})
 table.insert(objects,f);if name then _G[name]=f end;return f
end
function methods:GetFrameStrata() return self.strata end
function methods:SetFrameStrata(v) self.strata=v;self.writes=self.writes+1 end
function methods:SetToplevel(v) self.topLevel=v;self.topWrites=(self.topWrites or 0)+1 end
function methods:Raise() error('layout must not raise frames') end
function methods:IsVisible() return self.shown end
function methods:IsShown() return self.shown end
function methods:Show() self.shown=true;self.shows=self.shows+1 end
function methods:Hide() self.shown=false end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent() end
function methods:GetPoint() if self.point then return unpack(self.point) end end
function methods:GetNumPoints() return self.point and 1 or 0 end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(...) self.point={...};self.points=(self.points or 0)+1 end
function getglobal(name) return _G[name] end
UIParent=CreateFrame('Frame','UIParent')
CharacterFrame=CreateFrame('Frame','CharacterFrame');CharacterFrame.shown=false
PaperDollFrame=CreateFrame('Frame','PaperDollFrame')
InspectFrame=CreateFrame('Frame','InspectFrame');InspectFrame.unit='target'
InspectPaperDollFrame=CreateFrame('Frame','InspectPaperDollFrame')
StatCompareTargetFrame=CreateFrame('Frame','StatCompareTargetFrame')
StatCompareSelfFrame=CreateFrame('Frame','StatCompareSelfFrame')
S_ItemTip_InspectFrame=CreateFrame('Frame','S_ItemTip_InspectFrame')
pfPlayerFrame=CreateFrame('Frame','pfPlayerFrame');pfPlayerFrame.strata='MEDIUM'
StatCompare_Player={PanelLayoutMode='auto'}
''')
# Load the real policy, relayout, and mode-switch functions, closing their guard.
rt.execute(source[:source.index("function SCEnsureLayoutButton()")] + "\nend")
rt.execute(r'''
-- Styling and settings creation are unrelated; existing integration tests cover them.
function SCApplyPanelStyle() end
function SCEnsureSettingsButton() end
local restoreCalls=0
function StatCompare_RestoreFramePosition(name)
 restoreCalls=restoreCalls+1;_G[name]:SetPoint('TOPLEFT',UIParent,'TOPLEFT',800,-40)
end
local target,selfPanel,equipment=StatCompareTargetFrame,StatCompareSelfFrame,S_ItemTip_InspectFrame
local ranks={LOW=1,MEDIUM=2,HIGH=3,DIALOG=4}
for _,rootStrata in ipairs({'LOW','MEDIUM','HIGH','DIALOG'}) do
 InspectFrame.strata=rootStrata;target.strata='LOW';selfPanel.strata='LOW'
 SCRelayoutPanels()
 check(target.strata=='HIGH','target attributes stay above MEDIUM player unit frame after auto attach')
 check(selfPanel.strata=='HIGH','self attributes retain existing HIGH policy')
 check(ranks[target.strata]>ranks[pfPlayerFrame.strata],'target cannot be covered by pfUI player frame')
 check(equipment.strata==rootStrata,'equipment keeps root layer')
 check(target.point[2]==equipment and selfPanel.point[2]==target,'existing inspection anchors retained')
 check(target.topLevel==false and selfPanel.topLevel==false,'automatic panels do not auto-raise')
end
local targetWrites,selfWrites=target.writes,selfPanel.writes
local targetPoints,selfPoints=target.points,selfPanel.points
for i=1,10 do SCRelayoutPanels();SCShowPanel(target);SCShowPanel(selfPanel) end
check(target.writes==targetWrites and selfPanel.writes==selfWrites,'stable relayout has no strata churn')
check(target.points==targetPoints and selfPanel.points==selfPoints,'stable relayout has no anchor churn')
check(target.shows==0 and selfPanel.shows==0,'visible panels are not shown again')
SCSetPanelLayoutMode('free')
check(target.strata=='HIGH' and selfPanel.strata=='HIGH','free mode retains both attribute panel layers')
check(target.topLevel and selfPanel.topLevel,'free dragging keeps top-level behavior')
check(restoreCalls==2 and target.point[2]==UIParent,'free positions restored normally')
target:Hide();target.strata='LOW';SCShowPanel(target)
check(target.strata=='HIGH' and target.shows==1,'hidden target receives policy when reopened')
check(target.point[4]==800 and target.point[5]==-40,'free position survives reopen')
SCSetPanelLayoutMode('auto')
check(target.point[2]==equipment and selfPanel.point[2]==target,'return to automatic restores chain')
SCApplyPanelDisplayPolicy(pfPlayerFrame)
check(pfPlayerFrame.strata=='MEDIUM' and not pfPlayerFrame.topLevel,'unit frame itself remains unchanged')
InspectFrame.shown=false;CharacterFrame.shown=true;PaperDollFrame.shown=true
SCRelayoutPanels()
check(not target.shown and selfPanel.shown,'character page still hides target and retains self')
check(selfPanel.strata=='HIGH','character self layering retained')
print('PASS: '..checks..' actual StatCompare layer/lifecycle checks; full Lua 5.1 syntax passed, no live game validation')
''')
