from pathlib import Path
import runpy

HERE = Path(__file__).parent
ROOT = Path(r'E:/1.18/Interface/AddOns')
rt = runpy.run_path(str(HERE / 'test_inspect_layout.py'))['runtime']
rt.execute(r'''
clock=100
gear={player={[1]=7,[16]=8},target={[1]=9,[16]=10}}
function GetTime() return clock end
function time() return 123 end
function GetInventoryItemLink(unit,slot)
 local enchant=gear[unit] and gear[unit][slot]
 if enchant~=nil then return '|cffaa00ff|Hitem:'..(100+slot)..':'..enchant..':0:0|h[测试装备]|h|r' end
end
function GetItemInfo(id) return '测试装备',nil,4,60,'Armor' end
function GetItemQualityColor() return .6,0,.8 end
function S_ItemTip_GetEnchantIDFromLink(link)
 local _,_,id=string.find(link,'item:%d+:(%d+)')
 return id and tonumber(id)
end
LibItem_Level={[101]=76,[116]=80}
S_ItemTip_EnchantNames={[7]='头部附魔',[8]='武器附魔',[9]='目标头部附魔',[10]='目标武器附魔'}
ItemSocre.ScanUnit=function() return 77 end
CharacterFrame.visible=true;PaperDollFrame.visible=true;InspectFrame.visible=false
S_ItemTip_InspectFrame:Hide();S_ItemTip_InspectFrame.lastUpdateTime=nil
''')
rt.execute(ROOT.joinpath('S_ItemTip/InspectGemAndEnchant.lua').read_text(encoding='utf-8-sig'))
rt.execute(r'''
local frame=S_ItemTip_InspectFrame
local object=getmetatable(frame)
local shows=0
local expectedUnit='player'
local function AssertIcons(unit)
 local count=0
 for _,id in pairs(gear[unit]) do if id>0 then count=count+1 end end
 local shown=0
 for i=1,20 do
  local icon=frame['gemIcon'..i]
  if icon and icon:IsShown() then
   assert(icon.title==S_ItemTip_EnchantNames[icon.enchantID],'icon title matches current enchant')
   shown=shown+1
  end
 end
 assert(shown==count,'each enchanted equipped item has a prepared icon')
end
frame.Show=function(self)
 shows=shows+1
 assert(not self:IsShown(),'parent is still hidden when icons are checked')
 assert(self.currentUnit==expectedUnit,'parent unit is prepared before showing')
 AssertIcons(expectedUnit)
 object.Show(self)
end

S_ItemTip_OnCharacterShow();Tick();Tick()
assert(shows==1 and frame.gemIcon1 and frame.gemIcon2,'first open shows two prepared enchant icons')
local first,second=frame.gemIcon1,frame.gemIcon2
assert(first.topLevel==false and second.topLevel==false,'decorative icons do not independently promote windows')
assert(frame.gemIcon3==nil,'only necessary icon frames are allocated')
frame:Hide()
-- Reopen inside the throttle period: previously prepared child icons must
-- survive the skipped update and become visible with the parent again.
S_ItemTip_OnCharacterShow();Tick();Tick()
assert(shows==2 and frame.gemIcon1==first and frame.gemIcon2==second,'throttled reopen preserves the icons')
assert(S_ItemTip_UpdateFrame('player')==false,'duplicate update retains throttle')
AssertIcons('player')

frame:Hide();clock=clock+.1
gear.player[1]=0
S_ItemTip_OnCharacterShow();Tick();Tick()
AssertIcons('player')
assert(frame.gemIcon1==first and frame.gemIcon2==second and frame.gemIcon3==nil,'updates reuse child frames')

frame:Hide();expectedUnit='target'
CharacterFrame.visible=false;PaperDollFrame.visible=false
InspectFrame.visible=true;InspectFrame.unit='target';InspectPaperDollFrame.visible=true
S_ItemTip_ShowForInspect('target');Tick();Tick()
AssertIcons('target')
assert(frame.currentUnit=='target','inspection refreshes enchant ownership')

frame:Hide();clock=clock+.1
gear.target={}
S_ItemTip_UpdateFrame('target')
assert(not frame:IsShown(),'data preparation never shows the parent')
assert(not first:IsShown() and not second:IsShown(),'hidden updates clear removed equipment enchants')
print('PASS: hidden preparation, first open, throttled reopen, changed enchant, inspection, icon reuse and removed gear')
''')
