"""Exercise the real target layout module with scaled rendered rectangles."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = (ROOT / 'Interface/AddOns/pfUI/modules/targetlayout.lua').read_text(encoding='utf-8-sig')

SETUP = r'''
now, locked, previousUpdates, unlockSeenBaseline = 0, false, 0, false
C = {unitframes = {disable = '0'}, position = {}}
pfUI = {uf = {}, unlock = {}}
local methods = {}
function methods:GetName() return self.name end
function methods:GetScale() return self.scale end
function methods:GetParent() return self.parent end
function methods:GetEffectiveScale()
  return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1)
end
function methods:IsShown()
  -- WoW IsShown reports this frame's flag; IsVisible also checks ancestors.
  return self.shown
end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetScript(kind, fn) self.scripts[kind] = fn end
function methods:GetScript(kind) return self.scripts[kind] end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(point, relative, relativepoint, x, y)
  assert(point == 'BOTTOMLEFT' and relativepoint == 'BOTTOMLEFT')
  assert(relative == UIParent, 'temporary placement must use an explicit screen anchor')
  self.sets = self.sets + 1
  self.point = {x=x, y=y}
  self.l, self.b = x*self:GetEffectiveScale(), y*self:GetEffectiveScale()
end
local function edges(self)
  if self.nogeometry then return end
  if self.follows then
    local p = self.follows
    local pl, pb = p:GetLeft(), p:GetBottom()
    if not pl or not pb then return end
    local ps = p:GetEffectiveScale()
    return pl*ps+self.offsetl, pb*ps+self.offsetb
  end
  return self.l, self.b
end
function methods:GetLeft() local l = edges(self); return l and l/self:GetEffectiveScale() end
function methods:GetBottom() local _, b = edges(self); return b and b/self:GetEffectiveScale() end
function methods:GetRight() local l = edges(self); return l and (l+self.w)/self:GetEffectiveScale() end
function methods:GetTop() local _, b = edges(self); return b and (b+self.h)/self:GetEffectiveScale() end
function frame(name, l, b, w, h, scale, parent)
  return setmetatable({name=name,l=l,b=b,w=w,h=h,scale=scale or 1,parent=parent,
    shown=true,scripts={},sets=0,loads=0,buffs={},debuffs={}}, {__index=methods})
end
UIParent = frame('UIParent', 0, 0, 1600, 900, .75)
pfUI.uf = frame('UFDriver', 0, 0, 1, 1, 1, UIParent)
pfUI.unlock = frame('Unlock', 0, 0, 1, 1, 1, UIParent)
pfUI.unlock:Hide()
pfUI.uf:SetScript('OnUpdate', function() previousUpdates=previousUpdates+1 end)
function pfUI:RegisterModule(name, versions, callback)
  assert(name == 'targetlayout' and versions == 'vanilla:tbc')
  callback()
end
function HookScript(owner, kind, callback)
  local previous = owner:GetScript(kind)
  owner:SetScript(kind, function()
    if previous then previous() end
    callback()
  end)
end
function invoke(owner, kind)
  local old = this
  this = owner
  local fn = owner:GetScript(kind)
  if fn then fn() end
  this = old
end
function InCombatLockdown() return locked end
function GetTime() return now end
function savebase(f)
  local s = f:GetEffectiveScale()
  C.position[f.name] = {xpos=f.l/s,ypos=f.b/s,anchor='BOTTOMLEFT',scale=f.scale,parent=f.parent.name}
  f.initial = {l=f.l,b=f.b,scale=f.scale}
end
function LoadMovable(f)
  f.loads=f.loads+1
  local saved=C.position[f.name]
  if saved then
    f.scale=saved.scale or f.scale
    local s=f:GetEffectiveScale()
    f.l,f.b=saved.xpos*s,saved.ypos*s
  else
    f.l,f.b,f.scale=f.initial.l,f.initial.b,f.initial.scale
  end
end
function UpdateMovable(f) LoadMovable(f) end
function unit(name,l,b,w,h,scale)
  local f=frame(name,l,b,w or 150,h or 35,scale or 1,UIParent)
  savebase(f)
  return f
end
function aura(owner,kind,l,b,w,h)
  local f=frame('aura',l,b,w or 25,h or 25,1,owner)
  f.follows,f.offsetl,f.offsetb=owner,l-owner.l,b-owner.b
  table.insert(owner[kind],f)
  return f
end
function scene()
  pfUI.uf.target=unit('pfTarget',600,500,200,50)
  pfUI.uf.targettarget=unit('pfTargetTarget',625,440,150,35)
  return pfUI.uf.target,pfUI.uf.targettarget
end
function rect(f)
  local s=f:GetEffectiveScale()
  return {l=f:GetLeft()*s,b=f:GetBottom()*s,r=f:GetRight()*s,t=f:GetTop()*s}
end
function same(a,b) assert(math.abs(a-b)<.000001, tostring(a)..' ~= '..tostring(b)) end
function at(f,l,b) local r=rect(f); same(r.l,l); same(r.b,b) end
function disjoint(a,b)
  local x,y=rect(a),rect(b)
  assert(x.r<=y.l or x.l>=y.r or x.t<=y.b or x.b>=y.t, 'rendered rectangles overlap')
end
function snapshot()
  local copy={}
  for name,cfg in pairs(C.position) do
    copy[name]={}
    for key,value in pairs(cfg) do copy[name][key]=value end
  end
  return copy
end
function unchanged(before)
  for name,cfg in pairs(before) do
    for key,value in pairs(cfg) do assert(C.position[name][key]==value,'saved setting changed: '..key) end
    for key,value in pairs(C.position[name]) do assert(cfg[key]==value,'saved setting added') end
  end
  for name in pairs(C.position) do assert(before[name],'saved position added') end
end
pfUI.unlock:SetScript('OnShow',function()
  if pfUI.uf.targettarget then at(pfUI.uf.targettarget,625,440) end
  unlockSeenBaseline=true
end)
'''


def case(name, code):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(SETUP)
    lua.compile(SOURCE)
    lua.execute(SOURCE)
    lua.execute('layout=pfUI.uf.targetlayout\n' + code)
    print('PASS:', name)


case('multiple rendered rows, mixed aura sizes/offsets, restore and no saved-position drift', r'''
local target,child=scene()
local before=snapshot()
local a=aura(target,'debuffs',600,450,30,30)
local b=aura(target,'debuffs',600,405,42,35)
local c=aura(target,'buffs',640,420,25,25)
layout:Update()
disjoint(child,a); disjoint(child,b); disjoint(child,c)
assert(rect(child).t<405)
local l,bottom=rect(child).l,rect(child).b
local sets=child.sets
for i=1,25 do layout:Update(); at(child,l,bottom) end
assert(child.sets==sets,'stable layout repeats placement')
unchanged(before)
a:Hide(); b:Hide(); c:Hide()
layout:Update(); at(child,625,440)
assert(not layout.states[child]); unchanged(before)
''')

case('horizontal separation and above-target frames retain their manual locations', r'''
local target,child=scene()
aura(target,'debuffs',600,420,30,40)
child.l=1000; savebase(child)
layout:Update(); at(child,1000,440); assert(child.sets==0)
child.l,child.b=625,570; savebase(child)
layout:Update(); at(child,625,570); assert(child.sets==0)
''')

case('different effective scales compare and place real screen rectangles', r'''
local target,child=scene()
target.scale=.65; child.scale=1.7; savebase(target); savebase(child)
local a=aura(target,'debuffs',620,425,40,40)
local before=snapshot()
layout:Update(); disjoint(child,a)
local r=rect(child); same(r.l,625); assert(r.t<425)
for i=1,3 do layout:Update(); at(child,r.l,r.b) end
unchanged(before)
child.scale=1.2; C.position[child.name].scale=1.2
UpdateMovable(child); layout:Update(); disjoint(child,a)
a:Hide(); layout:Update()
same(child.scale,1.2)
same(child:GetLeft(),C.position[child.name].xpos)
same(child:GetBottom(),C.position[child.name].ypos)
''')

case('external position restoration and edited manual settings never accumulate offsets', r'''
local target,child=scene()
local a=aura(target,'debuffs',610,425,40,40)
layout:Update(); local r=rect(child)
UpdateMovable(child); at(child,625,440)
layout:Update(); at(child,r.l,r.b)
C.position[child.name].xpos=1000/child:GetEffectiveScale()
layout:Update(); at(child,1000,440); assert(not layout.states[child])
a:Hide(); layout:Update(); at(child,1000,440)
''')

case('unlock pre-hook restores before existing handlers and re-applies on exit', r'''
local target,child=scene()
aura(target,'debuffs',610,425,40,40)
local before=snapshot()
layout:Update(); assert(rect(child).b<440)
pfUI.unlock:Show(); invoke(pfUI.unlock,'OnShow')
assert(unlockSeenBaseline); at(child,625,440)
layout:Update(); at(child,625,440); unchanged(before)
pfUI.unlock:Hide(); invoke(pfUI.unlock,'OnHide')
assert(rect(child).b<440); unchanged(before)
''')

case('target-target-target avoids relocated child and its rendered auras', r'''
local target,child=scene()
local grand=unit('pfTargetTargetTarget',625,365,150,35)
pfUI.uf.targettargettarget=grand
local a=aura(target,'debuffs',610,425,40,40)
local ca=aura(child,'debuffs',625,400,30,30)
local before=snapshot()
layout:Update()
disjoint(child,a); disjoint(grand,child); disjoint(grand,ca); disjoint(grand,a)
assert(rect(grand).b<365)
local r=rect(grand)
layout:Update(); at(grand,r.l,r.b); unchanged(before)
a:Hide(); ca:Hide(); layout:Update()
at(child,625,440); at(grand,625,365)
''')

case('sparse target chain permits a grandchild with disabled direct child', r'''
local target,child=scene()
pfUI.uf.targettarget=nil
pfUI.uf.targettargettarget=child
local a=aura(target,'debuffs',610,425,40,40)
layout:Update(); disjoint(child,a)
''')

case('screen-bottom fallback chooses a free in-screen rectangle', r'''
local target,child=scene()
target.b=80; child.b=25; savebase(target); savebase(child)
local a=aura(target,'debuffs',610,5,100,65)
layout:Update(); disjoint(child,a); disjoint(child,target)
local r=rect(child)
assert(r.b>=0 and r.l>=0 and r.r<=1600 and r.t<=900)
assert(r.l~=625 or r.b>25,'bottom overflow was not avoided')
a:Hide(); layout:Update(); at(child,625,25)
''')

case('screen-bottom fallback can use the left and then above a full-width block', r'''
local target,child=scene()
target.l,target.b=1350,80; child.l,child.b=1400,25
savebase(target); savebase(child)
local a=aura(target,'debuffs',1370,5,200,65)
layout:Update(); disjoint(child,a); assert(rect(child).l<1400)
a:Hide(); layout:Update()
local full=aura(target,'debuffs',0,5,1600,65)
layout:Update(); disjoint(child,full); disjoint(child,target)
assert(rect(child).b>=130)
''')

case('hidden and absent geometry safely restore and recover', r'''
local target,child=scene()
local a=aura(target,'debuffs',610,425,40,40)
layout:Update(); child:Hide(); layout:Update()
assert(not layout.states[child]); at(child,625,440)
child:Show(); child.nogeometry=true; layout:Update(); assert(not layout.states[child])
child.nogeometry=false; a.nogeometry=true; layout:Update(); at(child,625,440)
a.nogeometry=false; layout:Update(); assert(layout.states[child])
target:Hide(); layout:Update(); at(child,625,440)
target:Show(); layout:Update(); assert(layout.states[child])
target.nogeometry=true; layout:Update(); at(child,625,440)
''')

case('target removal and swapping rendered aura sets resets stale displacement', r'''
local target,child=scene()
local a=aura(target,'debuffs',610,425,40,40)
layout:Update(); assert(layout.states[child])
pfUI.uf.target=nil; layout:Update(); at(child,625,440)
pfUI.uf.target=target; target.debuffs={}; layout:Update(); at(child,625,440)
local b=aura(target,'debuffs',610,400,40,60)
layout:Update(); disjoint(child,b)
''')

case('TBC lockdown prevents all movement and resumes safely afterward', r'''
local target,child=scene()
local a=aura(target,'debuffs',610,425,40,40)
locked=true; layout:Update(); at(child,625,440); assert(child.sets==0)
locked=false; layout:Update(); assert(layout.states[child])
local r=rect(child); local loads=child.loads
locked=true; a:Hide(); layout:Update(); layout:RestoreAll()
at(child,r.l,r.b); assert(child.loads==loads)
locked=false; layout:Update(); at(child,625,440)
''')

case('UF driver retains its original handler and throttles layout work', r'''
local target,child=scene()
local a=aura(target,'debuffs',610,425,40,40)
invoke(pfUI.uf,'OnUpdate'); assert(previousUpdates==1 and layout.states[child])
a:Hide(); now=.1; invoke(pfUI.uf,'OnUpdate')
assert(previousUpdates==2 and layout.states[child])
now=.2; invoke(pfUI.uf,'OnUpdate'); at(child,625,440)
assert(previousUpdates==3 and not layout.states[child])
''')

case('frames without saved positions return to their initial defaults', r'''
local target,child=scene()
C.position[child.name]=nil
local a=aura(target,'debuffs',610,425,40,40)
layout:Update(); disjoint(child,a)
a:Hide(); layout:Update(); at(child,625,440)
assert(C.position[child.name]==nil)
''')

print('PASS: real targetlayout module, scaled screen geometry, lifecycle and persistence; no FontStrings created')
