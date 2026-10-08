from pathlib import Path
import runpy

HERE = Path(__file__).parent
rt = runpy.run_path(str(HERE / 'test_inspect_layout.py'))['runtime']
rt.execute(r'''
local object=getmetatable(CharacterFrame)
local oldClear,oldPoint,oldBackdrop=object.ClearAllPoints,object.SetPoint,object.SetBackdrop
pointWrites,backdropWrites=0,0
-- Native anchor changes may emit size events even when the final dimensions
-- are unchanged. The earlier fixture did not model this feedback path.
object.ClearAllPoints=function(self) oldClear(self);self:Fire('OnSizeChanged') end
object.SetPoint=function(self,...) pointWrites=pointWrites+1;oldPoint(self,unpack(arg));self:Fire('OnSizeChanged') end
object.SetBackdrop=function(self,v) backdropWrites=backdropWrites+1;oldBackdrop(self,v) end
CharacterFrame.visible=true;PaperDollFrame.visible=true;InspectFrame.visible=false
StatCompareSelfFrame.visible=true;S_ItemTip_InspectFrame.visible=true
SCRelayoutPanels()
for i=1,10 do Tick() end
assert(PendingTicks()==0,'anchor-generated size events must not keep scheduling layouts')
local p,b=pointWrites,backdropWrites
for i=1,20 do Tick();SCRelayoutPanels() end
assert(PendingTicks()==0 and pointWrites==p and backdropWrites==b,'settled layout never rewrites anchors or backdrops')
StatCompareSelfFrame:SetWidth(345)
Tick();Tick()
assert(PendingTicks()==0,'external size updates still settle')
CharacterFrame.backdrop=CreateFrame('Frame')
CharacterFrame.backdrop:SetBackdrop({bgFile='updated',edgeFile='border',insets={left=2}})
CharacterFrame.backdrop:SetBackdropColor(.1,.2,.3,.6)
SCRelayoutPanels()
local background=StatCompareSelfFrame.backdrop or StatCompareSelfFrame
assert(background.background.bgFile=='updated','changed root style still propagates')
assert(background.color[4]==.6,'changed root opacity still propagates')
local baseline=backdropWrites
SCRelayoutPanels()
assert(backdropWrites==baseline,'unchanged style does not recreate backdrop')
print('PASS: anchor/size feedback loop ends; unchanged geometry/style incurs no writes')

local clock=0
-- WoW 1.12's Lua 5.0 ignores unpack's optional range arguments. Emulate this
-- API difference under the available Lua 5.1 test runtime.
local modernUnpack=unpack
unpack=function(list) return modernUnpack(list,1,list.n or #list) end
function debugprofilestop() return clock end
local messages={}
DEFAULT_CHAT_FRAME.AddMessage=function(self,text) table.insert(messages,text) end
function StatScanner_ScanAll() clock=clock+5 end
function oldPaperDollFrame_OnShow() clock=clock+2 end
PaperDollFrame:SetScript('OnShow',function()
 StatScanner_ScanAll();oldPaperDollFrame_OnShow();return nil,'kept',nil,9
end)
local oldScript=PaperDollFrame:GetScript('OnShow')
local oldScan=StatScanner_ScanAll
SCProfileNextCharacterOpen()
assert(StatScanner_ScanAll~=oldScan,'profiler installs optional hooks')
local a,b,c,d=PaperDollFrame:GetScript('OnShow')()
assert(a==nil and b=='kept' and c==nil and d==9,'profiler preserves multiple and nil returns')
for i=1,5 do Tick() end
assert(PaperDollFrame:GetScript('OnShow')==oldScript and StatScanner_ScanAll==oldScan,'one-opening profiler restores every hook')
local text=table.concat(messages,'\n')
assert(string.find(text,'装备提示文本扫描：5.00 ms / 1 次',1,true),'gear timing recorded accurately')
assert(string.find(text,'角色属性页打开回调：7.00 ms / 1 次',1,true),'whole script timing includes nested calls')
assert(string.find(text,'采样已自动关闭',1,true),'report explains automatic shutdown')
SCProfileNextCharacterOpen();SCProfileNextCharacterOpen()
assert(StatScanner_ScanAll==oldScan and PaperDollFrame:GetScript('OnShow')==oldScript,'armed profiler can be cancelled')

-- Reproduce the user's actual SCShowFrame >0 comparison with profiling active.
ItemSocre={ScanUnit=function(self,unit)
 assert(self==ItemSocre and unit=='player','method self and unit arguments preserved')
 return 77.2
end}
function IsAddOnLoaded(name) return name=='S_ItemTip' end
StatCompareSelfFrame.levelBg=nil
CreateFrame('FontString','StatCompareSelfFrameILevelText')
PaperDollFrame:SetScript('OnShow',function()
 SCShowFrame(StatCompareSelfFrame,PaperDollFrame,'player','stats',200,-12)
end)
local unprofiledScore=ItemSocre.ScanUnit
SCProfileNextCharacterOpen()
assert(ItemSocre:ScanUnit('player')==77.2,'armed profiler preserves numeric score before opening')
PaperDollFrame:GetScript('OnShow')()
assert(StatCompareSelfFrameILevelText.text=='装等 77.2','numeric score reaches actual display with Lua 5.0 unpack')
for i=1,5 do Tick() end
assert(ItemSocre.ScanUnit==unprofiledScore,'score method restored after sampling')
print('PASS: Lua 5.0 unpack compatibility, method arguments and actual profiled score display')

local memoryReads=0
function gcinfo() memoryReads=memoryReads+1;return memoryReads==1 and 20000 or 10000 end
SCProfileNextCharacterOpen();PaperDollFrame:GetScript('OnShow')()
for i=1,5 do Tick() end
assert(string.find(table.concat(messages,'\n'),'期间内存回落 10000 KB',1,true),'memory drops are reported as possible collection')
gcinfo=nil
print('PASS: root callbacks report memory drops without forcing garbage collection')

-- A list created during the opening must also have its native methods timed
-- and restored. Previously these hooks were silently absent for cold opens.
local existingEquipment=S_ItemTip_InspectFrame
local existingCreate=S_ItemTip_CreateInspectFrame
S_ItemTip_InspectFrame=nil
local createdEquipment
function S_ItemTip_CreateInspectFrame()
 clock=clock+2
 createdEquipment=CreateFrame('Frame')
 createdEquipment.Show=function() clock=clock+7 end
 S_ItemTip_InspectFrame=createdEquipment
 return createdEquipment
end
local createBefore=S_ItemTip_CreateInspectFrame
PaperDollFrame:SetScript('OnShow',function()
 local frame=S_ItemTip_CreateInspectFrame()
 frame:Show()
end)
SCProfileNextCharacterOpen();PaperDollFrame:GetScript('OnShow')()
local wrappedShow=createdEquipment.Show
for i=1,5 do Tick() end
local report=table.concat(messages,'\n')
assert(string.find(report,'装备列表首次创建：2.00 ms / 1 次',1,true),'cold creation timed')
assert(string.find(report,'装备列表显示操作：7.00 ms / 1 次',1,true),'new frame native Show timed')
assert(createdEquipment.Show~=wrappedShow and S_ItemTip_CreateInspectFrame==createBefore,'dynamic native hooks restored')
S_ItemTip_InspectFrame=existingEquipment;S_ItemTip_CreateInspectFrame=existingCreate
print('PASS: cold creation and newly created frame native operations are captured and restored')

-- Native display timing includes nested callbacks; exclusive timing must
-- subtract each child span once, including the child's own nested work.
local priorShow=existingEquipment.Show
BCS={UpdateStats=function() clock=clock+3;StatScanner_ScanAll() end}
existingEquipment.Show=function() clock=clock+11;BCS:UpdateStats() end
PaperDollFrame:SetScript('OnShow',function() existingEquipment:Show() end)
SCProfileNextCharacterOpen();PaperDollFrame:GetScript('OnShow')()
for i=1,5 do Tick() end
local report=table.concat(messages,'\n')
assert(string.find(report,'装备列表显示操作：19.00 ms / 1 次',1,true),'native show inclusive timing retains nested callbacks')
assert(string.find(report,'装备显示扣除已计时内部调用：11.00 ms',1,true),'exclusive native show subtracts nested spans once')
existingEquipment.Show=priorShow
print('PASS: inclusive/exclusive timing distinguishes native display from nested attribute callbacks')

debugprofilestop=nil;SCProfileNextCharacterOpen()
assert(StatScanner_ScanAll==oldScan,'no unreliable GetTime fallback')
print('PASS: opt-in profiler captures exact timings, preserves returns, reports once and removes hooks')
''')

root = Path(r'E:\1.18')
assert (root / 'Interface/AddOns/StatCompare/StatScanner.lua').read_bytes() == (HERE / 'character-open-backup-20261006/StatCompare_StatScanner.lua.original').read_bytes()
print('PASS: previous equipment-cache overhead fully reverted')
