from pathlib import Path
import runpy

HERE = Path(__file__).parent
fixture = runpy.run_path(str(HERE / 'test_bcs_float.py'))
rt = fixture['LuaRuntime'](unpack_returned_tuples=True)
rt.execute(fixture['STUB'])
rt.execute(r'''
local Object=getmetatable(UIParent)
local factors={CENTER={0,0},TOPLEFT={-.5,.5},TOP={0,.5},TOPRIGHT={.5,.5},
 LEFT={-.5,0},RIGHT={.5,0},BOTTOMLEFT={-.5,-.5},BOTTOM={0,-.5},BOTTOMRIGHT={.5,-.5}}
function Object:GetEffectiveScale()
 return self==UIParent and .8 or .8*(self.scale or 1)
end
function Object:SetPoint(point,relative,rp,x,y)
 if type(relative)=='number' then
  x,y=relative,rp;relative,rp=UIParent,point
 elseif type(relative)=='string' and type(rp)=='number' then
  x,y=rp,x;rp=relative;relative=UIParent
 else relative=relative or UIParent;rp=rp or point end
 self.point={point,relative,rp,x or 0,y or 0}
 self.pointWrites=(self.pointWrites or 0)+1
end
function Object:GetPoint()
 if self.point then return unpack(self.point) end
end
function ExpectedCenter(frame,point,rp,x,y)
 local a,b=factors[point],factors[rp]
 local ratio=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
 return UIParent:GetWidth()*(.5+b[1])*ratio+x-a[1]*frame:GetWidth(),
        UIParent:GetHeight()*(.5+b[2])*ratio+y-a[2]*frame:GetHeight()
end
function Object:GetCenter()
 if self==UIParent then return self:GetWidth()/2,self:GetHeight()/2 end
 local point,relative,rp,x,y=self:GetPoint()
 if point and relative==UIParent then return ExpectedCenter(self,point,rp,x,y) end
end
function PhysicalCenter(frame)
 local x,y=frame:GetCenter()
 return x*frame:GetEffectiveScale(),y*frame:GetEffectiveScale()
end
function Close(a,b) return math.abs(a-b)<.02 end
''')
rt.execute(fixture['SOURCE'])
rt.execute(r'''
local P=BCS.PropertiesPanel
local anchors={'CENTER','TOPLEFT','TOP','TOPRIGHT','LEFT','RIGHT','BOTTOMLEFT','BOTTOM','BOTTOMRIGHT'}
for _,point in ipairs(anchors) do
 for _,rp in ipairs(anchors) do
  BCSConfig={PropertiesPanel={point=point,rel_point=rp,x_offset=80,y_offset=-70,
   displayConfig='防御',enabled=true,locked=false,scale=1.25}}
  P:Init();P:UpdateDisplay(1,'标题','短属性一\n短属性二')
  local actualX,actualY=P.frame:GetCenter()
  local expectedX,expectedY=ExpectedCenter(P.frame,point,rp,80,-70)
  assert(Close(actualX,expectedX) and Close(actualY,expectedY),'legacy visual position is preserved during center migration')
  local saved=BCSConfig.PropertiesPanel
  assert(saved.point=='CENTER' and saved.rel_point=='CENTER','all legacy anchors migrate to center')
  local x,y=PhysicalCenter(P.frame)
  P:UpdateDisplay(1,'不同标题','属性一\n属性二\n属性三\n属性四\n属性五\n属性六\n属性七')
  local nextX,nextY=PhysicalCenter(P.frame)
  assert(Close(nextX,x) and Close(nextY,y),'changing the number of rows retains the same center')
 end
end
print('PASS: all 81 frame/reference anchor combinations preserve legacy positions and center across row counts at non-default scale')

P:SetPanelOption('rowsPerColumn',2)
local x,y=PhysicalCenter(P.frame)
P:UpdateDisplay(1,'标题','一\n二\n三\n四\n五\n六\n七')
local nextX,nextY=PhysicalCenter(P.frame)
assert(Close(nextX,x) and Close(nextY,y),'adding columns expands symmetrically around the center')
for _,name in ipairs({'物理','法系','治疗','防御','猎人','自定义'}) do
 P:SelectConfig(name)
 local nextX,nextY=PhysicalCenter(P.frame)
 assert(Close(nextX,x) and Close(nextY,y),'actual preset switches keep the physical center')
end
print('PASS: actual preset switches and multiple columns keep their common center')

P:SetLocked(false)
P.frame:Fire('OnDragStart')
P.frame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',700,420)
local x,y=PhysicalCenter(P.frame)
local before=P.frame.pointWrites
P.frame:Fire('OnDragStop')
assert(P.frame.pointWrites==before,'drag-stop saves without immediate native reanchoring')
assert(BCSConfig.PropertiesPanel.point=='CENTER','drag saves a canonical center anchor')
P:UpdateDisplay(1,'拖动后标题','一\n二\n三')
local nextX,nextY=PhysicalCenter(P.frame)
assert(Close(nextX,x) and Close(nextY,y),'first post-drag resize preserves the dropped center')
assert(P.frame:GetPoint()=='CENTER','next display refresh applies the center anchor')
local before=P.frame.pointWrites
P:UpdateDisplay(1,'拖动后标题','一\n二\n三')
assert(P.frame.pointWrites==before,'unchanged refresh does not rewrite the panel anchor')

P.frame:Fire('OnDragStart')
P.frame:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMLEFT',740,330)
local x,y=PhysicalCenter(P.frame)
P:SetLocked(true)
assert(not P.dragging and BCSConfig.PropertiesPanel.point=='CENTER','locking mid-drag saves center too')
P:UpdateDisplay(1,'锁定后','一\n二\n三\n四')
local nextX,nextY=PhysicalCenter(P.frame)
assert(Close(nextX,x) and Close(nextY,y),'locking and resizing keep the dropped center')

local x,y=PhysicalCenter(P.frame)
P:Init();P:UpdateDisplay(1,'重载后','仅一行')
local nextX,nextY=PhysicalCenter(P.frame)
assert(Close(nextX,x) and Close(nextY,y),'saved center survives initialization with different dimensions')
print('PASS: dragging, locking during drag, no repeated anchor writes and reload persistence')
''')
