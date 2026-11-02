"""PureDispel dock geometry, layering and state checks with actual addon Lua.

The fixture computes anchors in physical pixels, inherited scale/alpha, parent
frame-level changes and mouse hit order. It is not a renderer or live-client QA.
Chinese glyph widths remain the shared mock's approximation.
"""
import unittest

from test_puredispel_presets import world as preset_world


GEOMETRY = r'''
local pointX={LEFT=0,TOPLEFT=0,BOTTOMLEFT=0,CENTER=.5,TOP=.5,BOTTOM=.5,RIGHT=1,TOPRIGHT=1,BOTTOMRIGHT=1}
local pointY={BOTTOM=0,BOTTOMLEFT=0,BOTTOMRIGHT=0,CENTER=.5,LEFT=.5,RIGHT=.5,TOP=1,TOPLEFT=1,TOPRIGHT=1}
local rawNewObject=newObject
local SyncVisibility
function newObject(kind,name,parent)
 local object=rawNewObject(kind,name,parent)
 object.level=parent and parent:GetFrameLevel()+1 or 0
 if kind=='Button' or kind=='EditBox' or kind=='Slider' then object.mouse=true end
 object.geometryVisible=object:IsVisible()
 return object
end
SyncVisibility=function(object)
 local visible=object:IsVisible() and true or false
 if object.geometryVisible~=visible then
  object.geometryVisible=visible
  invoke(object,visible and 'OnShow' or 'OnHide')
 end
 for _,child in ipairs(object.children) do SyncVisibility(child) end
end
for _,object in ipairs(objects) do object.geometryVisible=object:IsVisible() and true or false end
function methods:Show() self.shown=true;record('show');SyncVisibility(self) end
function methods:Hide() self.shown=false;record('hide');SyncVisibility(self) end
local function MoveLevels(object,delta)
 object.level=(object.level or 0)+delta
 for _,child in ipairs(object.children) do MoveLevels(child,delta) end
end
function methods:SetFrameLevel(value)
 assert(type(value)=='number' and value>=0,'invalid frame level')
 MoveLevels(self,value-(self.level or 0))
end
function methods:SetParent(parent)
 assert(parent==nil or type(parent)=='table','unknown frame parent')
 local ancestor=parent
 while ancestor do assert(ancestor~=self,'cyclic parenting');ancestor=ancestor.parent end
 if self.parent==parent then return end
 if self.parent then
  for i=table.getn(self.parent.children),1,-1 do
   if self.parent.children[i]==self then table.remove(self.parent.children,i) end
  end
 end
 self.parent=parent
 if parent then table.insert(parent.children,self) end
 self:SetFrameLevel(parent and parent:GetFrameLevel()+1 or 0)
 SyncVisibility(self)
end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
function methods:GetEffectiveAlpha() return (self.alpha or 1)*(self.parent and self.parent:GetEffectiveAlpha() or 1) end
function methods:SetScale(value) assert(type(value)=='number' and value>0);self.scale=value end
function methods:SetPoint(point,relative,relativePoint,x,y)
 assert(pointX[point]~=nil,'unsupported anchor '..tostring(point))
 if type(relative)=='number' then x,y,relative,relativePoint=relative,relativePoint,self.parent,point end
 if type(relative)=='string' then relative=_G[relative] end
 relative=relative or self.parent or UIParent;relativePoint=relativePoint or point
 assert(type(relative)=='table' and pointX[relativePoint]~=nil,'bad relative anchor')
 local anchor={point,relative,relativePoint,x or 0,y or 0}
 self.points[point]=anchor;self.point=anchor;self.allPoints=nil;record('point')
end
function methods:SetAllPoints(target)
 if type(target)=='string' then target=_G[target] end
 self.allPoints=target or self.parent;self.points={};self.point=nil
end
function methods:ClearAllPoints() self.points={};self.point=nil;self.allPoints=nil end
local function Axis(constraints,size)
 local first=constraints[1]
 if not first then return nil,size end
 for i=2,table.getn(constraints) do
  local other=constraints[i]
  if other[1]~=first[1] then
   size=(other[2]-first[2])/(other[1]-first[1]);break
  end
 end
 return first[2]-first[1]*size,size
end
local function Bounds(object,stack)
 local scale=object:GetEffectiveScale()
 if object==UIParent then return 0,0,object.width*scale,object.height*scale end
 stack=stack or {};assert(not stack[object],'cyclic anchor geometry');stack[object]=true
 if object.allPoints then
  local l,b,r,t=Bounds(object.allPoints,stack);stack[object]=nil;return l,b,r,t
 end
 local xs,ys={},{}
 for _,a in pairs(object.points) do
  local l,b,r,t=Bounds(a[2],stack)
  assert(l~=nil,'anchor target has no bounds')
  table.insert(xs,{pointX[a[1]],l+(r-l)*pointX[a[3]]+a[4]*scale})
  table.insert(ys,{pointY[a[1]],b+(t-b)*pointY[a[3]]+a[5]*scale})
 end
 local width,height=(object.width or 0)*scale,(object.height or 0)*scale
 if object.kind=='FontString' then
  if width==0 then width=object:GetStringWidth()*scale end
  if height==0 then height=object:GetStringHeight()*scale end
 end
 local left;left,width=Axis(xs,width)
 local bottom;bottom,height=Axis(ys,height)
 stack[object]=nil
 if left==nil or bottom==nil then return nil end
 assert(width>=-.001 and height>=-.001,'negative resolved geometry')
 -- The real client clamps the whole frame, not each child independently.
 if object.clamped then
  if width<=SCREEN_W then left=math.max(0,math.min(left,SCREEN_W-width)) end
  if height<=SCREEN_H then bottom=math.max(0,math.min(bottom,SCREEN_H-height)) end
 end
 return left,bottom,left+width,bottom+height
end
function GeometryBox(object) return Bounds(object) end
function GetScreenRect(object)
 local l,b,r,t=Bounds(object)
 if l then return l,b,r-l,t-b end
end
function methods:GetLeft() local l=Bounds(self);return l and l/self:GetEffectiveScale() end
function methods:GetBottom() local l,b=Bounds(self);return l and b/self:GetEffectiveScale() end
function methods:GetRight() local l,b,r=Bounds(self);return l and r/self:GetEffectiveScale() end
function methods:GetTop() local l,b,r,t=Bounds(self);return l and t/self:GetEffectiveScale() end
function methods:GetCenter()
 local l,b,r,t=Bounds(self);if l then return (l+r)/2/self:GetEffectiveScale(),(b+t)/2/self:GetEffectiveScale() end
end
function methods:GetWidth()
 if self==UIParent then return PARENT_MODEL=='raw' and SCREEN_W or self.width end
 local l,b,r=Bounds(self);return l and (r-l)/self:GetEffectiveScale() or self.width
end
function methods:GetHeight()
 if self==UIParent then return PARENT_MODEL=='raw' and SCREEN_H or self.height end
 local l,b,r,t=Bounds(self);return l and (t-b)/self:GetEffectiveScale() or self.height
end
function GetScreenWidth() return SCREEN_W end
function GetScreenHeight() return SCREEN_H end
function GeometryNear(a,b,label) assert(math.abs(a-b)<.05,(label or '')..': '..tostring(a)..' ~= '..tostring(b)) end
function GeometryInside(object)
 local l,b,r,t=Bounds(object);assert(l and l>=-.05 and b>=-.05 and r<=SCREEN_W+.05 and t<=SCREEN_H+.05,'offscreen '..tostring(object.name)..' '..tostring(l)..','..tostring(b)..','..tostring(r)..','..tostring(t))
end
function GeometryContained(child,parent)
 local l,b,r,t=Bounds(child);local pl,pb,pr,pt=Bounds(parent)
 assert(l>=pl-.05 and b>=pb-.05 and r<=pr+.05 and t<=pt+.05,'child outside parent')
end
local strata={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
function GeometryHit(x,y)
 local found,bestStrata,bestLevel,bestIndex=nil,-1,-1,-1
 for i,object in ipairs(objects) do
  if object.mouse and object:IsVisible() and not object.disabled then
   local l,b,r,t=Bounds(object)
   if l and x>=l and x<=r and y>=b and y<=t then
    local s,level=strata[object:GetFrameStrata()],object:GetFrameLevel()
    if s>bestStrata or (s==bestStrata and (level>bestLevel or level==bestLevel and i>bestIndex)) then
     found,bestStrata,bestLevel,bestIndex=object,s,level,i
    end
   end
  end
 end
 return found
end
function GeometryClick(object)
 local l,b,r,t=Bounds(object);local top=GeometryHit((l+r)/2,(b+t)/2)
 assert(top==object,'mouse blocked by '..tostring(top and top.name or top and top.kind))
 Press(top)
end
function GeometryMove(object,x,y)
 local scale=object:GetEffectiveScale()
 object:ClearAllPoints();object:SetPoint('CENTER',UIParent,'BOTTOMLEFT',x/scale,y/scale)
end
function GeometryPair()
 local u=XinDispel.UI;local a,b=u.manager,u.presets
 assert(a:IsVisible() and b:IsVisible())
 local al,ab,ar,at=Bounds(a);local bl,bb,br,bt=Bounds(b)
 assert(bl>ar,'preset pane is not strictly to the right')
 GeometryNear(bl-ar,8*a:GetEffectiveScale(),'pane gap')
 GeometryNear(ab,bb,'same bottom');GeometryNear(at,bt,'same top')
 GeometryNear(a:GetHeight(),505,'manager height');GeometryNear(b:GetHeight(),505,'preset height')
 assert(a:GetParent()==u.managerDock and b:GetParent()==u.managerDock)
 GeometryInside(a);GeometryInside(b);GeometryInside(u.managerDock)
end
function GeometryUpdates()
 local n=0;for _,o in ipairs(objects) do if o.scripts.OnUpdate then n=n+1 end end;return n
end
-- The client's built-in tooltip starts in TOOLTIP strata; the old shared mock
-- deliberately does not model this native rendering detail.
GameTooltip:SetFrameStrata('TOOLTIP');GameTooltip:EnableMouse(false)
UIParent:SetScale(UI_SCALE)
-- Both clients have the same physical root rectangle. Only the reported
-- GetWidth/GetHeight differ: logical units versus already-scaled dimensions.
UIParent.width=SCREEN_W/UI_SCALE
UIParent.height=SCREEN_H/UI_SCALE
'''


def world(screen=(1920, 1080), ui_scale=1, model='logical', bad_font=False, setup=''):
    config = f"SCREEN_W={screen[0]};SCREEN_H={screen[1]};UI_SCALE={ui_scale};PARENT_MODEL='{model}'\n"
    lua = preset_world(ui=True, bad_font=bad_font, setup=config + GEOMETRY + setup)
    lua.execute('U=XinDispel.UI;D=XinDispel')
    return lua


class DockingTests(unittest.TestCase):
    def test_parent_models_share_physical_bounds_but_report_different_sizes(self):
        sizes = []
        for model in ('logical', 'raw'):
            lua = world(ui_scale=.8, model=model)
            self.assertEqual(lua.globals().GetScreenRect(lua.globals().UIParent), (0, 0, 1920, 1080))
            sizes.append(lua.globals().UIParent.GetWidth(lua.globals().UIParent))
        self.assertEqual(sizes, [2400, 1920])

    def test_fixture_resolves_mixed_scale_anchors_and_parent_levels(self):
        lua = world(ui_scale=.8)
        lua.execute(r'''
local parent=CreateFrame('Frame',nil,UIParent);parent:SetWidth(200);parent:SetHeight(100)
parent:SetScale(1.5);parent:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',10,20)
local child=CreateFrame('Button',nil,parent);child:SetWidth(50);child:SetHeight(30)
child:SetScale(.5);child:SetPoint('TOPLEFT',parent,'BOTTOMRIGHT',4,6)
local l,b,r,t=GeometryBox(child)
GeometryNear(l,12+240+2.4);GeometryNear(t,24+3.6);GeometryNear(r-l,30);GeometryNear(t-b,18)
local level=child:GetFrameLevel();parent:SetFrameLevel(parent:GetFrameLevel()+7)
assert(child:GetFrameLevel()==level+7)
child:SetParent(UIParent);assert(child:GetFrameLevel()==UIParent:GetFrameLevel()+1)
local hidden,shown=0,0
child:SetScript('OnHide',function() hidden=hidden+1 end)
child:SetScript('OnShow',function() shown=shown+1 end)
child:SetParent(parent);parent:Hide();assert(child:IsShown() and not child:IsVisible() and hidden==1)
parent:Show();assert(child:IsVisible() and shown==1)
''')

    def test_dock_is_lazy_transparent_and_independent_of_main_alpha(self):
        lua = world(setup='xinDB={backgroundAlpha=0,borderAlpha=0,listsVisible=true}')
        lua.execute(r'''
assert(not U.managerDock and not U.manager and not U.presets)
U.frame:SetAlpha(0);U.OpenPresets();U.ApplyAppearance();GeometryPair()
assert(U.managerDock.mouse==false and U.managerDock.clamped)
assert(U.managerDock:GetAlpha()==1 and U.managerDock:GetParent()==UIParent)
assert(not U.managerDock.backdropSpec and not U.managerDock.bgColor,'dock host must not draw a background')
assert(U.manager:GetEffectiveAlpha()>.9 and U.presets:GetEffectiveAlpha()>.9)
GeometryNear(U.manager.bgColor[4],.94);GeometryNear(U.manager.borderColor[4],.85)
GeometryNear(U.presets.bgColor[4],.94);GeometryNear(U.presets.borderColor[4],.85)
assert(U.manager:GetFrameStrata()=='DIALOG' and U.presets:GetFrameStrata()=='DIALOG')
''')

    def test_right_edge_opening_fits_both_parent_size_models_and_scales(self):
        for model in ('logical', 'raw'):
            for size, scale in (((1920, 1080), .64), ((1280, 720), 1), ((1024, 600), 1.45), ((800, 450), 1.75)):
                with self.subTest(model=model, screen=size, scale=scale):
                    lua = world(screen=size, ui_scale=scale, model=model)
                    lua.execute(r'''
U.OpenManager('current');GeometryMove(U.managerDock,SCREEN_W-5,SCREEN_H-5)
U.LayoutManagerDock();U.OpenPresets();GeometryPair()
for _,key in ipairs({'priority','ignore','selfFirst','identify','manageRoles','reset','undo'}) do
 GeometryContained(U.presets[key],U.presets)
end
''')

    def test_collapse_expand_and_slash_preserve_manager_state(self):
        lua = world()
        lua.execute(r'''
for i=1,25 do xinDB.PriorityList['Stored'..i]=true end
U.OpenManager('priority');U.OpenPresets();U.manager.offset=7
U.manager.nameEdit:SetText('KeepThisName');U.manager.scopeValue='longterm'
local panel=U.manager
U.TogglePresets();assert(not U.presets:IsShown() and not U.managerDock.expanded and U.manager:IsVisible())
U.TogglePresets();assert(U.managerDock.expanded);GeometryPair()
assert(panel==U.manager and panel.kind=='priority' and panel.offset==7)
assert(panel.nameEdit:GetText()=='KeepThisName' and panel.scopeValue=='longterm')
U.TogglePresets();SlashCmdList.PUREDISPEL('presets');assert(U.managerDock.expanded)
assert(panel.kind=='priority' and panel.offset==7 and panel.nameEdit:GetText()=='KeepThisName')
''')

    def test_dynamic_parent_resize_keeps_both_panes_on_screen(self):
        lua = world()
        lua.execute(r'''
U.OpenPresets()
for _,size in ipairs({{1024,600,1.5},{800,450,1.75},{1920,1080,.64}}) do
 SCREEN_W,SCREEN_H=size[1],size[2];UIParent:SetScale(size[3])
 UIParent.width=SCREEN_W/size[3];UIParent.height=SCREEN_H/size[3]
 U.LayoutManagerDock();GeometryPair()
end
''')

    def test_scale_event_repositions_or_dismisses_existing_picker_safely(self):
        for model in ('logical', 'raw'):
            with self.subTest(model=model):
                lua = world(screen=(800, 450), ui_scale=.64, model=model)
                lua.execute(r'''
U.OpenPresets();GeometryClick(U.presets.priority)
UIParent:SetScale(1.75);UIParent.width=SCREEN_W/1.75;UIParent.height=SCREEN_H/1.75
FireEvent('UI_SCALE_CHANGED');GeometryPair()
local picker=U.presetPicker
if picker:IsVisible() then
 GeometryInside(picker);assert(picker.blocker:IsVisible())
 local key=picker.rows[2].option.key;GeometryClick(picker.rows[2]);assert(P.GetConfig().priority==key)
else assert(not picker.blocker:IsVisible(),'scale event leaves an orphan mouse blocker') end
GeometryClick(U.presets.priority);GeometryInside(picker)
local key=picker.rows[3].option.key;GeometryClick(picker.rows[3])
assert(P.GetConfig().priority==key and not picker.blocker:IsVisible())
''')

    def test_repeated_unchanged_refresh_does_not_write_text_or_geometry(self):
        lua = world()
        lua.execute(r'''
U.OpenPresets();U.RefreshPresets();ResetCalls()
for i=1,40 do U.RefreshPresets() end
assert((calls.text or 0)==0,'unchanged preset text is rewritten')
assert((calls.height or 0)==0,'unchanged status height is recomputed')
assert((calls.point or 0)==0,'unchanged preset anchors are rewritten')
local old=R.GetDiagnostics
R.GetDiagnostics=function() return {state='querying',message=string.rep('Changed state ',60),
 total=10,completed=2,pending=true,unknown=8} end
U.RefreshPresets()
assert((calls.text or 0)>0 and (calls.height or 0)>0)
assert(string.find(U.presets.progress:GetText(),'Changed state',1,true) and U.presets.statusMax>0)
ResetCalls();for i=1,40 do U.RefreshPresets() end
assert((calls.text or 0)==0 and (calls.height or 0)==0 and (calls.point or 0)==0)
R.GetDiagnostics=old
''')

    def test_both_title_drags_move_host_and_keep_panes_bound(self):
        lua = world()
        lua.execute(r'''
U.OpenPresets();local host=U.managerDock
for _,panel in ipairs({U.manager,U.presets}) do
 local l,b,r,t=GeometryBox(host)
 invoke(panel.dragBar,'OnDragStart');assert(host.moving)
 GeometryMove(host,(l+r)/2+90,(b+t)/2-50)
 invoke(panel.dragBar,'OnDragStop');assert(not host.moving);GeometryPair()
end
''')

    def test_late_preset_creation_tracks_an_already_raised_dock(self):
        lua = world()
        lua.execute(r'''
U.OpenManager('current');assert(not U.presets)
U.managerDock:SetFrameLevel(80);U.OpenPresets();GeometryPair()
for _,pane in ipairs({U.manager,U.presets}) do
 assert(pane:GetFrameLevel()>U.managerDock:GetFrameLevel())
 assert(pane.dragBar:GetFrameLevel()>pane:GetFrameLevel())
 assert(pane.close:GetFrameLevel()>pane.dragBar:GetFrameLevel())
end
GeometryClick(U.presets.priority);GeometryClick(U.presetPicker.rows[2])
GeometryClick(U.manager.presets);assert(not U.managerDock.expanded)
GeometryClick(U.manager.presets);GeometryPair()
local before=U.presets:GetFrameLevel()
U.managerDock:SetFrameLevel(120)
assert(U.presets:GetFrameLevel()==before+40)
GeometryClick(U.presets.ignore);GeometryClick(U.presetPicker.rows[2])
''')

    def test_dropdown_layering_hit_target_tooltip_and_outside_dismiss(self):
        lua = world()
        lua.execute(r'''
U.OpenPresets();GeometryClick(U.presets.priority)
local picker=U.presetPicker
assert(picker:IsVisible() and picker.blocker:IsVisible())
assert(picker:GetFrameStrata()=='FULLSCREEN_DIALOG')
assert(picker:GetFrameLevel()>picker.blocker:GetFrameLevel())
local row=picker.rows[2];invoke(row,'OnEnter')
assert(GameTooltip:GetFrameStrata()=='TOOLTIP')
local key=row.option.key;GeometryClick(row)
assert(P.GetConfig().priority==key and not picker:IsShown() and not picker.blocker:IsShown())
GeometryClick(U.presets.ignore);assert(picker.blocker:IsShown())
local blocker=GeometryHit(1,1);assert(blocker==picker.blocker)
Press(blocker);assert(not picker:IsShown() and not picker.blocker:IsShown())
''')

    def test_dropdown_flips_up_and_stays_inside_screen(self):
        lua = world(screen=(1280, 720), ui_scale=1.25)
        lua.execute(r'''
U.OpenPresets();GeometryClick(U.presets.priority)
local anchor=CreateFrame('Button',nil,UIParent);anchor:SetWidth(120);anchor:SetHeight(20)
anchor:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-5,5)
U.PositionPresetPicker(anchor)
assert(U.presetPicker.direction=='up');GeometryInside(U.presetPicker)
local l,b,r,t=GeometryBox(U.presetPicker);local al,ab,ar,at=GeometryBox(anchor)
assert(b>=at-.05,'upward dropdown overlaps its anchor')
''')

    def test_closing_either_panel_releases_picker_and_blocker(self):
        for panel in ('manager', 'presets'):
            with self.subTest(panel=panel):
                lua = world()
                lua.globals().close_panel = panel
                lua.execute(r'''
U.OpenPresets();GeometryClick(U.presets.priority)
local close=U[close_panel].close;local l,b,r,t=GeometryBox(close)
assert(GeometryHit((l+r)/2,(b+t)/2)==U.presetPicker.blocker)
Press(U.presetPicker.blocker);GeometryClick(close)
assert(not U.presetPicker:IsVisible() and not U.presetPicker.blocker:IsVisible())
if close_panel=='manager' then assert(not U.managerDock:IsShown())
else assert(U.manager:IsVisible() and not U.managerDock.expanded) end
''')

    def test_close_and_escape_hide_entire_combination_and_overlays(self):
        lua = world()
        lua.execute(r'''
U.OpenPresets();GeometryClick(U.presets.priority);U.CloseManager()
assert(not U.managerDock:IsVisible() and not U.presetPicker.blocker:IsVisible())
-- With no popup, Escape closes the combination. The separate layered-Escape
-- case below checks that an open picker consumes the first Escape itself.
U.OpenPresets()
local found=0
local escapeFrames=UISpecialFrames
for _,name in ipairs(escapeFrames) do
 assert(name~='PureDispelManager' and name~='PureDispelPresets','dock child competes for Escape')
 if name==U.managerDock:GetName() then found=found+1 end
end
assert(found==1,'management dock must have exactly one Escape entry')
-- Native Escape hides shown special frames from an existing snapshot.
for _,name in ipairs(escapeFrames) do local frame=_G[name];if frame and frame:IsVisible() then frame:Hide() end end
assert(not U.managerDock:IsVisible() and not U.presetPicker.blocker:IsVisible())
''')

    def test_native_escape_closes_picker_then_dock_without_duplicate_entries(self):
        lua = world()
        lua.execute(r'''
local function UniqueSpecialFrames()
 local names={}
 for _,name in ipairs(UISpecialFrames) do
  assert(not names[name],'duplicate Escape entry '..name);names[name]=true
 end
end
local function NativeEscape()
 local snapshot=UISpecialFrames
 for _,name in ipairs(snapshot) do
  local frame=_G[name]
  if frame and frame:IsShown() then frame:Hide() end
 end
end
U.OpenSettings();U.OpenPresets();assert(U.settings:IsShown())
GeometryClick(U.presets.priority);UniqueSpecialFrames()
NativeEscape()
assert(not U.presetPicker:IsShown() and not U.presetPicker.blocker:IsShown())
assert(U.settings:IsShown(),'first Escape also closes the settings entrance')
assert(U.managerDock:IsShown() and U.manager:IsVisible() and U.presets:IsVisible())
GeometryPair();UniqueSpecialFrames()
NativeEscape()
assert(not U.managerDock:IsShown() and not U.manager:IsVisible() and not U.presets:IsVisible())
assert(not U.settings:IsShown() and not U.presetPicker.blocker:IsShown())
UniqueSpecialFrames()
for i=1,20 do
 U.OpenSettings();U.OpenPresets();GeometryClick(U.presets.priority)
 UniqueSpecialFrames();NativeEscape();UniqueSpecialFrames()
 assert(U.managerDock:IsVisible() and not U.presetPicker.blocker:IsVisible())
 NativeEscape();UniqueSpecialFrames()
 assert(not U.managerDock:IsVisible() and not U.presetPicker.blocker:IsVisible())
end
''')

    def test_font_failure_retains_readable_font_contract(self):
        lua = world(bad_font=True, setup='failedFontPaths[STANDARD_TEXT_FONT]=true')
        lua.execute(r'''
U.OpenPresets();GeometryPair();GeometryClick(U.presets.priority)
for _,font in ipairs(U.fonts) do
 assert(font.fontObject or font.font,'text has no font fallback')
 font:SetText(font:GetText())
end
''')

    def test_external_role_window_returns_to_same_dock_state(self):
        lua = world()
        lua.execute(r'''
local external=U.CreatePanel('DockingRoleWindow','Team roles',500,450)
local originalHide=0
local oldLevel,oldStrata=external:GetFrameLevel(),external:GetFrameStrata()
external:SetScript('OnHide',function() originalHide=originalHide+1 end)
pfUI.OpenTeamRoles=function(self,name) external.requestedName=name;external:Show();return external end
pfUI.teamroles={frame=external};pfTeamRoles=external
for i=1,20 do xinDB.BlackList['Blocked'..i]=true end
U.OpenManager('ignore');U.OpenPresets();U.manager.offset=3;U.manager.nameEdit:SetText('SavedName')
U.manager.scopeValue='longterm';GeometryClick(U.presets.priority);U.OpenRoleEditor('Tank')
assert(external:IsShown() and external.requestedName=='Tank')
assert(not U.managerDock:IsVisible() and not U.presetPicker.blocker:IsVisible())
assert(external:GetFrameStrata()=='DIALOG' and external:GetFrameLevel()>U.managerDock:GetFrameLevel())
local snapshot=UISpecialFrames
for _,name in ipairs(snapshot) do local frame=_G[name];if frame and frame:IsVisible() then frame:Hide() end end
assert(originalHide==1);GeometryPair()
assert(external:GetFrameLevel()==oldLevel and external:GetFrameStrata()==oldStrata)
assert(U.manager.kind=='ignore' and U.manager.offset==3)
assert(U.manager.nameEdit:GetText()=='SavedName' and U.manager.scopeValue=='longterm')
local handler=external:GetScript('OnHide')
U.OpenRoleEditor('Tank');external:Hide();assert(originalHide==2);GeometryPair()
assert(external:GetScript('OnHide')==handler and external:GetFrameLevel()==oldLevel)
''')

    def test_repeated_opening_reuses_frames_without_new_update_loops(self):
        lua = world()
        lua.execute(r'''
local updates=GeometryUpdates();U.OpenPresets();GeometryClick(U.presets.priority)
U.presetPicker:Hide();local count=table.getn(objects)
for i=1,30 do
 U.OpenPresets();U.TogglePresets();U.TogglePresets()
 GeometryClick(U.presets.priority);U.presetPicker:Hide();U.CloseManager()
end
assert(table.getn(objects)==count,'management frames leak across repeated opens')
assert(GeometryUpdates()==updates,'management adds an update loop')
''')

    def test_escape_from_role_window_survives_settings_in_both_creation_orders(self):
        for early_role_frame in (False, True):
            with self.subTest(early_role_frame=early_role_frame):
                lua = world()
                lua.globals().early_role_frame = early_role_frame
                lua.execute(r'''
local external,originalHide,oldLevel,oldStrata=nil,0,nil,nil
local function EnsureExternal()
 if not external then
  external=U.CreatePanel('DockingRoleSettingsWindow','Team roles',500,450)
  oldLevel,oldStrata=external:GetFrameLevel(),external:GetFrameStrata()
  external:SetScript('OnHide',function() originalHide=originalHide+1 end)
  pfUI.teamroles={frame=external};pfTeamRoles=external
 end
 return external
end
if early_role_frame then EnsureExternal() end
pfUI.OpenTeamRoles=function(self,name) EnsureExternal():Show() end
U.OpenSettings()
for i=1,25 do xinDB.PriorityList['Stored'..i]=true end
U.OpenManager('priority');U.OpenPresets()
U.manager.offset=7;U.manager.nameEdit:SetText('EscReturnName');U.manager.scopeValue='longterm'
U.OpenRoleEditor('Tank')
assert(external:IsVisible() and not U.managerDock:IsVisible())
assert(external:GetFrameLevel()>U.settings:GetFrameLevel())
local l,b,r,t=GeometryBox(external);assert(GeometryHit((l+r)/2,(b+t)/2)==external,'settings covers role window')
local snapshot=UISpecialFrames
for _,name in ipairs(snapshot) do local frame=_G[name];if frame and frame:IsVisible() then frame:Hide() end end
assert(originalHide==1);GeometryPair()
assert(external:GetFrameLevel()==oldLevel and external:GetFrameStrata()==oldStrata)
assert(U.managerDock.expanded and U.manager.kind=='priority' and U.manager.offset==7)
assert(U.manager.nameEdit:GetText()=='EscReturnName' and U.manager.scopeValue=='longterm')
''')


if __name__ == '__main__':
    unittest.main()
