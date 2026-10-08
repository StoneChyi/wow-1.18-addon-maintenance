from pathlib import Path
import json
import sys

work=Path(__file__).parent
sys.path.insert(0,r'C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work\cat-ret-tests\deps')
from lupa.lua51 import LuaRuntime
source=(work/'STSMmayor.lua').read_text(encoding='utf-8-sig')

stub=r'''
frames={}; messages={}; routes={}; now=0; zone='Elwynn Forest'; screenW=1280; screenH=720
STANDARD_TEXT_FONT='Fonts\FRIZQT__.TTF'; SlashCmdList={}; DURABILITY_TEMPLATE='耐久度 %d / %d'
strlower=string.lower; strfind=string.find
DEFAULT_CHAT_FRAME={AddMessage=function(self,message) table.insert(messages,message) end}
function GetTime() return now end
function GetRealZoneText() return zone end
function GetZoneText() return zone end
function GetSubZoneText() return '' end
function GetScreenWidth() return screenW end
function GetScreenHeight() return screenH end
function GetInventorySlotInfo() return 17 end
function GetInventoryItemLink(unit,slot) if unit=='player' and slot==17 then return equippedLink end end
function UnitName() return nil end
function UnitExists() return false end
function UnitCanAttack() return false end
function UnitAffectingCombat() return false end
function UnitIsVisible() return false end
function TargetByName() end
function ClearTarget() end
function GetItemInfo(id)
 if id==18168 then return '力反馈盾牌','link',4,60,'Armor','Shields',1,'INVTYPE_SHIELD' end
end
function AceLibrary()
 return {SetInventoryItem=function() end,FindDeformat=function() return 100,150 end}
end
local methods={}
function methods:SetScript(key,value) self.scripts[key]=value end
function methods:GetScript(key) return self.scripts[key] end
function methods:RegisterEvent(key) self.events[key]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:SetWidth(value) self.width=value end
function methods:SetHeight(value) self.height=value end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(point,parent,relative,x,y)
 self.point={point,parent,relative,x or 0,y or 0}
 self.pointWrites=(self.pointWrites or 0)+1
end
local pointFactors={TOPLEFT={0,1},TOP={0.5,1},TOPRIGHT={1,1},LEFT={0,0.5},CENTER={0.5,0.5},RIGHT={1,0.5},BOTTOMLEFT={0,0},BOTTOM={0.5,0},BOTTOMRIGHT={1,0}}
function frameRect(frame)
 local scale=frame:GetEffectiveScale()
 local width=(frame.width or 0)*scale
 local height=(frame.height or (frame.font and frame.font[2]) or 0)*scale
 if frame==UIParent then return 0,0,width,height end
 local p=frame.point
 if not p then return 0,0,width,height end
 local relative=p[2] or frame.parent or UIParent
 if type(relative)=='string' then relative=_G[relative] end
 local left,bottom,rw,rh=frameRect(relative)
 local own=pointFactors[p[1]]; local other=pointFactors[p[3]]
 return left+other[1]*rw+(p[4] or 0)*scale-own[1]*width,
  bottom+other[2]*rh+(p[5] or 0)*scale-own[2]*height,width,height
end
function methods:GetLeft() if self.forbidGeometry then error('Unexpected geometry read') end; local left=frameRect(self);return left/self:GetEffectiveScale() end
function methods:GetTop() local _,bottom,_,height=frameRect(self);return (bottom+height)/self:GetEffectiveScale() end
function methods:GetPoint() if self.point then return unpack(self.point) end end
function methods:GetScale() return self.scale or 1 end
function methods:SetMovable(value) self.movable=value end
function methods:StartMoving() self.startCount=(self.startCount or 0)+1; self.moving=true end
function methods:StopMovingOrSizing() self.stopCount=(self.stopCount or 0)+1; self.moving=false end
function methods:GetBottom() local _,bottom=frameRect(self);return bottom/self:GetEffectiveScale() end
function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetScale(value) self.scale=value;self.scaleWrites=(self.scaleWrites or 0)+1 end
function methods:SetClampedToScreen(value) self.clamped=value end
function methods:SetBackdropColor(r,g,b,a) self.bg={r,g,b,a} end
function methods:GetBackdropColor() if self.bg then return unpack(self.bg) end; return 0.08,0.08,0.08,0.92 end
function methods:SetMinMaxValues(low,high) self.low=low; self.high=high end
function methods:SetValueStep(value) self.step=value end
function methods:SetValue(value)
 self.value=math.max(self.low, math.min(value, self.high))
 local old=this; this=self
 if self.scripts.OnValueChanged then self.scripts.OnValueChanged() end
 this=old
end
function methods:GetValue() return self.value end
function methods:SetOrientation(value) self.orientation=value end
function methods:SetThumbTexture(value) self.thumb=newObject('Texture',nil,self) end
function methods:GetThumbTexture() return self.thumb end
function methods:GetFontString() if not self.label then self.label=newObject('FontString',nil,self) end; return self.label end
function methods:SetText(value)
 if self.kind=='FontString' and not self.font then error('<unnamed>:SetText(): Font not set') end
 self.text=value
 if self.kind=='Button' then self:GetFontString():SetText(value) end
end
function methods:GetText() return self.text end
function methods:SetFont(path,size,flags) self.font={path,size,flags} end
function methods:SetTextColor(r,g,b,a) self.color={r,g,b,a} end
function methods:Show() self.shown=true end
function methods:Hide() local was=self.shown; self.shown=false; if was and self.scripts.OnHide then local old=this; this=self; self.scripts.OnHide(); this=old end end
function methods:IsShown() return self.shown end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:GetCheckedTexture() if not self.checkedTexture then self.checkedTexture=newObject('Texture',nil,self) end; return self.checkedTexture end
function methods:GetHighlightTexture() if not self.highlightTexture then self.highlightTexture=newObject('Texture',nil,self) end; return self.highlightTexture end
function methods:CreateFontString(name) return newObject('FontString',name,self) end
function methods:CreateTexture(name) return newObject('Texture',name,self) end
function methods:SetNormalTexture(texture) self.normalTexture=texture end
function methods:SetPushedTexture(texture) self.pushedTexture=texture end
function methods:SetHighlightTexture(texture) self.highlight=texture end
function methods:SetHitRectInsets(a,b,c,d) self.hitInsets={a,b,c,d} end
for _,name in ipairs({'SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetFrameStrata','SetMovable','SetClampedToScreen','EnableMouse','RegisterForDrag','StartMoving','StopMovingOrSizing','SetDisabledTexture','SetVertexColor','SetTexture','SetJustifyH','Enable','SetAllPoints','SetJustifyV'}) do
 if not methods[name] then methods[name]=function() end end
end
function newObject(kind,name,parent)
 local object=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={},events={}}, {__index=methods})
 if name then _G[name]=object end
 return object
end
function CreateFrame(kind,name,parent,template)
 local frame=newObject(kind,name,parent)
 -- Blizzard's button template supplies GameFontNormal to its existing label.
 if template=='UIPanelButtonTemplate' then frame:GetFontString():SetFont(STANDARD_TEXT_FONT,12,'') end
 table.insert(frames,frame); return frame
end
UIParent=newObject('Frame','UIParent'); UIParent.width=screenW; UIParent.height=screenH
GameTooltip={SetOwner=function() end,SetText=function() end,Show=function() end,Hide=function() end}
function call(frame,script)
 this=frame; arg1=nil
 local fn=frame.scripts[script]; if fn then fn() end
end
function fire(name,unit)
 event=name; arg1=unit
 for _,frame in ipairs(frames) do if frame.events[name] and frame.scripts.OnEvent then this=frame; frame.scripts.OnEvent() end end
end
function tick(time)
 now=time
 for _,frame in ipairs(frames) do if frame.shown and frame.scripts.OnUpdate then call(frame,'OnUpdate') end end
end
function setupPF()
 pfUI={font_default='pfUI-font',env={C={}},api={}}
 pfUI.api.CreateBackdrop=function(frame) frame.pfSkinned=true end
 pfUI.api.SkinButton=function(frame) frame.pfSkinned=true; frame:SetNormalTexture(''); frame:SetPushedTexture('') end
 pfUI.api.SkinCloseButton=function(frame,parent,x,y) frame.pfSkinned=true; frame:SetWidth(15); frame:SetHeight(15); frame:ClearAllPoints(); frame:SetPoint('TOPRIGHT',parent,'TOPRIGHT',x,y) end
 pfUI.api.SkinCheckbox=function(frame) frame.pfSkinned=true; frame.backdrop=newObject('Frame',nil,frame) end
end
'''

def new(saved=None,zone='Elwynn Forest',pf=True,equipped=None):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(stub)
    if pf: lua.globals().setupPF()
    lua.execute(source)
    lua.globals().equippedLink=equipped
    if saved is not None: lua.globals().STSMmayorDB=lua.table_from(saved,recursive=True)
    lua.globals().zone=zone
    lua.globals().fire('ADDON_LOADED','STSMmayor')
    lua.globals().fire('PLAYER_ENTERING_WORLD',None)
    lua.globals().tick(2)
    return lua

def db(lua):
    def convert(value):
        if hasattr(value,'items'): return {k:convert(v) for k,v in value.items()}
        return value
    return convert(lua.globals().STSMmayorDB)

tests=[]
def check(name,fn): fn(); tests.append(name)

def first_target():
    lua=new(zone='Stratholme')
    assert lua.globals().STSMmayor_Enabled
    assert lua.globals().STSMmayorDurabilityFrame.shown
    assert len(lua.globals().messages)==0
    assert db(lua)['AutoSwap'] is True
check('first_run_target_zone_auto_enables_without_chat_spam',first_target)

def first_elsewhere():
    lua=new()
    assert not lua.globals().STSMmayor_Enabled and db(lua)['Visible'] is False
check('first_run_elsewhere_stays_disabled',first_elsewhere)

def disabled_restore():
    lua=new({'Enabled':False,'Visible':False,'AutoSwap':False,'AutoRepair':False,'RobotDetection':False},'Stratholme')
    lua.globals().fire('PLAYER_ENTERING_WORLD',None); lua.globals().tick(5)
    assert not lua.globals().STSMmayor_Enabled and db(lua)['Visible'] is False
    lua.globals().SlashCmdList.STSM('')
    assert lua.globals().STSMmayor_Enabled
    lua.globals().STSMmayor_ToggleAppearance()
    assert lua.globals().STSMmayorAutoSwapCheck.checked is False
    lua.globals().SlashCmdList.STSM('')
    assert not lua.globals().STSMmayor_Enabled and not lua.globals().STSMmayorDurabilityFrame.shown
    assert len(lua.globals().messages)==0
check('saved_false_and_manual_disable_survive_zone_entry',disabled_restore)

def choices():
    lua=new({'Enabled':True,'Visible':True,'AutoSwap':True,'AutoRepair':False,'RobotDetection':False})
    lua.globals().STSMmayor_ToggleAppearance()
    lua.execute("Interact=function(mode) table.insert(routes,mode) end")
    lua.globals().call(lua.globals().STSMmayorAutoSwapCheck,'OnClick')
    lua.globals().call(lua.globals().STSMmayorAutoRepairCheck,'OnClick')
    lua.globals().call(lua.globals().STSMmayorRobotDetectionCheck,'OnClick')
    saved=db(lua)
    assert saved['AutoSwap'] is False and saved['AutoRepair'] is True and saved['RobotDetection'] is True
    again=new(saved)
    again.globals().STSMmayor_ToggleAppearance()
    assert again.globals().STSMmayorAutoSwapCheck.checked is False
    assert again.globals().STSMmayorAutoRepairCheck.checked is True
    assert again.globals().STSMmayorRobotDetectionCheck.checked is True
check('all_three_options_persist_across_new_runtime',choices)

def position():
    lua=new({'Enabled':True,'Visible':True,'UIScale':1})
    lua.globals().call(lua.globals().STSMmayorDurabilityFrame,'OnDragStart')
    lua.execute('STSMmayorPositionFrame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",240,180)')
    lua.globals().call(lua.globals().STSMmayorDurabilityFrame,'OnDragStop')
    assert db(lua)['PositionAnchor']=={'point':'TOPLEFT','relativePoint':'BOTTOMLEFT','x':240,'y':180}
    before=lua.globals().frameRect(lua.globals().STSMmayorDurabilityFrame)
    lua.globals().fire('PLAYER_LOGOUT',None)
    again=new(db(lua))
    assert again.globals().frameRect(again.globals().STSMmayorDurabilityFrame)==before
check('drag_and_logout_restore_position',position)

def close_only():
    lua=new({'Enabled':True,'Visible':True})
    lua.globals().call(lua.globals().STSMmayorCloseButton,'OnClick')
    assert lua.globals().STSMmayor_Enabled and not db(lua)['Visible']
    again=new(db(lua))
    assert again.globals().STSMmayor_Enabled and not db(again)['Visible']
check('close_window_preserves_enabled_monitor_and_hidden_state',close_only)

def layout_and_pf():
    lua=new({'Enabled':True,'Visible':True})
    lua.globals().STSMmayor_ToggleAppearance()
    frame=lua.globals().STSMmayorDurabilityFrame
    assert frame.width==320 and frame.height==34 and frame.pfSkinned
    assert lua.globals().STSMmayorEquipButton.Label.font[1]=='pfUI-font'
    assert lua.globals().STSMmayorEquipButton.normalTexture==''
    assert lua.globals().STSMmayorAutoSwapCheck.hitInsets[2]==-47
    lua.globals().call(lua.globals().STSMmayorRobotDetectionCheck,'OnClick')
    assert frame.height==34
    lua.execute('Interact=function() end; STSMmayor_UpdateInteractButtons()')
    assert frame.height==34
    lua.globals().call(lua.globals().STSMmayorRobotDetectionCheck,'OnClick')
    assert frame.height==34
check('pfui_skin_and_optional_footer_do_not_overlap',layout_and_pf)

check('fallback_without_pfui_creates_panel', lambda: new({'Enabled':True,'Visible':True},pf=False))

def routes():
    lua=new({'Enabled':True,'Visible':True})
    lua.execute('Interact=function(mode) table.insert(routes,mode) end')
    lua.execute('assert(STSMmayor_AutoPickup()); assert(STSMmayor_AutoRepair()); assert(routes[1]==0 and routes[2]==1); assert(table.getn(messages)==0)')
    lua.execute('WSLoot={Loot=function() table.insert(routes,9) end}; assert(STSMmayor_AutoPickup()); assert(STSMmayor_AutoRepair()); assert(routes[3]==0 and routes[4]==9); assert(table.getn(messages)==0)')
    lua.execute('Interact=nil; assert(STSMmayor_AutoPickup()); assert(STSMmayor_AutoRepair()); assert(routes[5]==9 and routes[6]==9); assert(table.getn(messages)==0)')
check('repair_and_loot_routes_remain_correct_and_quiet',routes)

def missing():
    lua=new({'Enabled':True,'Visible':True})
    lua.execute('assert(not STSMmayor_AutoPickup()); assert(not STSMmayor_AutoRepair()); assert(table.getn(messages)==2)')
check('real_missing_dependency_errors_are_retained',missing)

def timers():
    lua=new({'Enabled':True,'Visible':False})
    lua.execute('bagChecks=0; STSMmayor_CheckBagForBrokenShields=function() bagChecks=bagChecks+1 end')
    lua.globals().tick(21); assert lua.globals().bagChecks==0
    lua.globals().tick(22); assert lua.globals().bagChecks==1
    lua.globals().tick(65); assert lua.globals().bagChecks==2
    lua.globals().STSMmayor_SetEnabled(False)
    lua.globals().tick(120); assert lua.globals().bagChecks==2
check('timers_use_wall_time_without_legacy_arg1',timers)

def clamp():
    lua=new({'Enabled':True,'Visible':True,'Position':{'x':3,'y':-2}})
    left,bottom,width,height=lua.globals().frameRect(lua.globals().STSMmayorDurabilityFrame)
    assert abs(left-(1280-320*0.9))<1e-8 and abs(bottom)<1e-8
check('offscreen_saved_position_is_clamped',clamp)

def scaled_position():
    lua=new({'Enabled':True,'Visible':True})
    lua.execute('UIParent.scale=0.8; STSMmayor_SetUIScale(1.2); STSMmayorPositionFrame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",200,100)')
    before=lua.globals().frameRect(lua.globals().STSMmayorDurabilityFrame)
    lua.execute('STSMmayor_SaveSettings(); STSMmayor_RestorePosition()')
    assert lua.globals().frameRect(lua.globals().STSMmayorDurabilityFrame)==before
check('effective_scale_coordinate_roundtrip',scaled_position)


def appearance_defaults():
    lua=new({'Enabled':True,'Visible':True})
    frame=lua.globals().STSMmayorDurabilityFrame
    assert db(lua)['UIScale']==0.9 and db(lua)['BackgroundAlpha']==0.35
    assert frame.scale==0.9 and frame.bg[4]==0.35
    lua.globals().call(lua.globals().STSMmayorSettingsButton,'OnClick')
    panel=lua.globals().STSMmayorAppearanceFrame
    assert panel.shown and panel.Transparency.value==65 and panel.Scale.value==90
    assert panel.bg[4]==0.94
    lua.globals().call(lua.globals().STSMmayorSettingsButton,'OnClick')
    assert not panel.shown
check('compact_defaults_and_settings_toggle',appearance_defaults)

def appearance_changes():
    lua=new({'Enabled':True,'Visible':True,'UIScale':1,'Position':{'x':0.25,'y':0.2}})
    lua.globals().STSMmayor_ToggleAppearance()
    lua.globals().STSMmayorTransparencySlider.SetValue(lua.globals().STSMmayorTransparencySlider,100)
    assert db(lua)['BackgroundAlpha']==0
    assert lua.globals().STSMmayorDurabilityFrame.bg[4]==0
    assert lua.globals().STSMmayorEquipButton.bg[4]==0
    assert lua.globals().STSMmayorAutoSwapCheck.parent.name=='STSMmayorAppearanceFrame'
    assert lua.globals().STSMmayorAutoSwapCheck.backdrop.GetBackdropColor(lua.globals().STSMmayorAutoSwapCheck.backdrop)[3]!=0
    assert lua.globals().STSMmayorAppearanceFrame.bg[4]==0.94
    lua.globals().STSMmayorScaleSlider.SetValue(lua.globals().STSMmayorScaleSlider,50)
    frame=lua.globals().STSMmayorDurabilityFrame
    assert frame.scale==0.5 and db(lua)['UIScale']==0.5
    left,bottom,width,height=lua.globals().frameRect(frame)
    assert abs(left-320)<1e-8 and abs(bottom+height-178)<1e-8
    lua.globals().fire('PLAYER_LOGOUT',None)
    again=new(db(lua))
    assert db(again)['BackgroundAlpha']==0 and db(again)['UIScale']==0.5
    frame=again.globals().STSMmayorDurabilityFrame
    left,bottom,width,height=again.globals().frameRect(frame)
    assert abs(left-320)<1e-8 and abs(bottom+height-178)<1e-8
    again.globals().STSMmayor_ToggleAppearance()
    again.globals().STSMmayorScaleSlider.SetValue(again.globals().STSMmayorScaleSlider,150)
    assert frame.scale==1.5
    again.globals().STSMmayorTransparencySlider.SetValue(again.globals().STSMmayorTransparencySlider,0)
    assert db(again)['BackgroundAlpha']==1
check('transparency_endpoints_scale_endpoints_and_relogin_persistence',appearance_changes)

def popup_close():
    lua=new({'Enabled':True,'Visible':True})
    lua.globals().STSMmayor_ToggleAppearance()
    lua.globals().call(lua.globals().STSMmayorAppearanceClose,'OnClick')
    assert not lua.globals().STSMmayorAppearanceFrame.shown
    lua.globals().STSMmayor_ToggleAppearance()
    lua.globals().STSMmayor_HideDurabilityFrame()
    assert not lua.globals().STSMmayorAppearanceFrame.shown
check('popup_closes_with_main_panel_or_done_button',popup_close)

def invalid_appearance():
    lua=new({'Enabled':True,'Visible':True,'UIScale':'bad','BackgroundAlpha':'bad'})
    assert db(lua)['UIScale']==0.9 and db(lua)['BackgroundAlpha']==0.35
    lua=new({'Enabled':True,'Visible':True,'UIScale':99,'BackgroundAlpha':-12})
    assert db(lua)['UIScale']==1.5 and db(lua)['BackgroundAlpha']==0
check('invalid_saved_appearance_is_repaired_and_clamped',invalid_appearance)

def no_pf_popup():
    lua=new({'Enabled':True,'Visible':True},pf=False)
    lua.globals().STSMmayor_ToggleAppearance()
    lua.globals().STSMmayorScaleSlider.SetValue(lua.globals().STSMmayorScaleSlider,80)
    assert db(lua)['UIScale']==0.8
check('appearance_controls_work_without_pfui',no_pf_popup)

assert 'STSM 镇长' not in source and 'local divider =' not in source


def dragged_transparency_no_geometry():
    lua=new({'Enabled':True,'Visible':True,'UIScale':0.8})
    frame=lua.globals().STSMmayorDurabilityFrame
    anchor=lua.globals().STSMmayorPositionFrame
    lua.globals().call(frame,'OnDragStart')
    lua.execute('STSMmayorPositionFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-180,-96)')
    lua.globals().call(frame,'OnDragStop')
    frame.forbidGeometry=True
    saved=db(lua)['PositionAnchor']
    lua.globals().STSMmayor_ToggleAppearance()
    popup=lua.globals().STSMmayorAppearanceFrame
    for value in [66,42,7,91,55]:
        popup.Transparency.SetValue(popup.Transparency,value)
        assert anchor.point[1]=='TOPRIGHT' and anchor.point[4]==-180 and anchor.point[5]==-96
        assert db(lua)['PositionAnchor']==saved
        assert popup.point[1]=='CENTER' and popup.point[4]==0 and popup.point[5]==0
    again=new(db(lua))
    assert db(again)['PositionAnchor']==saved
check('dragged_panel_transparency_never_reanchors_or_reads_geometry',dragged_transparency_no_geometry)

def dragged_scale_native_anchor():
    for point in ['BOTTOMLEFT','BOTTOM','BOTTOMRIGHT','LEFT','CENTER','RIGHT','TOPLEFT','TOP','TOPRIGHT']:
        lua=new({'Enabled':True,'Visible':True,'UIScale':0.8})
        frame=lua.globals().STSMmayorDurabilityFrame
        carrier=lua.globals().STSMmayorPositionFrame
        lua.globals().call(frame,'OnDragStart')
        carrier.SetPoint(carrier,point,lua.globals().UIParent,point,120,-80)
        lua.globals().call(frame,'OnDragStop')
        frame.forbidGeometry=True
        left,bottom,width,height=lua.globals().frameRect(frame)
        original=(left,bottom+height)
        rootWrites,carrierWrites=frame.pointWrites,carrier.pointWrites
        lua.globals().STSMmayor_ToggleAppearance()
        panel=lua.globals().STSMmayorAppearanceFrame
        saved=db(lua)['PositionAnchor']
        for value in [95,110,65,140,50,80]:
            panel.Scale.SetValue(panel.Scale,value)
            left,bottom,width,height=lua.globals().frameRect(frame)
            assert abs(left-original[0])<1e-8 and abs(bottom+height-original[1])<1e-8
            assert frame.pointWrites==rootWrites and carrier.pointWrites==carrierWrites
            assert carrier.GetScale(carrier)==1 and carrier.width==1 and carrier.height==1
            assert db(lua)['PositionAnchor']==saved
            assert panel.point[1]=='CENTER' and panel.point[4]==0 and panel.point[5]==0
        again=new(db(lua))
        left,bottom,width,height=again.globals().frameRect(again.globals().STSMmayorDurabilityFrame)
        assert abs(left-original[0])<1e-8 and abs(bottom+height-original[1])<1e-8
check('five_drag_anchor_types_stay_fixed_through_repeated_scale_changes',dragged_scale_native_anchor)

def position_lock():
    lua=new({'Enabled':True,'Visible':True})
    frame=lua.globals().STSMmayorDurabilityFrame
    carrier=lua.globals().STSMmayorPositionFrame
    assert carrier.movable and not frame.movable and not db(lua)['PositionLocked']
    lua.globals().STSMmayor_ToggleAppearance()
    lock=lua.globals().STSMmayorPositionLockCheck
    lua.globals().call(lock,'OnClick')
    assert not carrier.movable and db(lua)['PositionLocked'] and lock.checked
    lua.globals().call(frame,'OnDragStart');lua.globals().call(frame,'OnDragStop')
    assert carrier.startCount is None and carrier.stopCount is None
    panel=lua.globals().STSMmayorAppearanceFrame
    panel.Scale.SetValue(panel.Scale,105);panel.Transparency.SetValue(panel.Transparency,40)
    assert frame.scale==1.05 and abs(db(lua)['BackgroundAlpha']-0.6)<1e-8 and panel.shown
    again=new(db(lua))
    root=again.globals().STSMmayorDurabilityFrame
    restored=again.globals().STSMmayorPositionFrame
    assert not restored.movable
    again.globals().STSMmayor_ToggleAppearance()
    again.globals().call(again.globals().STSMmayorPositionLockCheck,'OnClick')
    assert restored.movable
    again.globals().call(root,'OnDragStart');again.globals().call(root,'OnDragStop')
    assert restored.startCount==1 and restored.stopCount==1
check('position_lock_persists_and_does_not_disable_other_controls',position_lock)

def lock_during_drag():
    lua=new({'Enabled':True,'Visible':True})
    frame=lua.globals().STSMmayorDurabilityFrame
    carrier=lua.globals().STSMmayorPositionFrame
    lua.globals().call(frame,'OnDragStart')
    lua.globals().STSMmayor_SetPositionLocked(True)
    lua.globals().call(frame,'OnDragStop')
    assert carrier.stopCount==1 and not carrier.moving and not carrier.movable
check('locking_during_movement_stops_once',lock_during_drag)

def enabling_repair_quiet():
    lua=new({'Enabled':True,'Visible':True,'AutoRepair':False})
    lua.globals().STSMmayor_ToggleAppearance()
    lua.execute('Interact=function(mode) table.insert(routes,mode) end')
    lua.globals().call(lua.globals().STSMmayorAutoRepairCheck,'OnClick')
    assert db(lua)['AutoRepair'] is True and len(lua.globals().routes)==0
    lua.execute('STSMmayor_UpdateDurabilityDisplay()')
    assert len(lua.globals().routes)==0
    lua.execute('GetInventoryItemLink=function() return "shield" end; STSMmayor_IsOffHandItem=function() return true end; STSMmayor_GetInventoryDurability=function() return 90,100 end; STSMmayor_UpdateDurabilityDisplay()')
    assert len(lua.globals().routes)==0
    lua.execute('STSMmayor_GetInventoryDurability=function() return 20,100 end; STSMmayor_UpdateDurabilityDisplay()')
    assert len(lua.globals().routes)==1 and lua.globals().routes[1]==1
    lua.execute('STSMmayor_UpdateInteractButtons()')
    lua.globals().call(lua.globals().STSMmayorRepairButton,'OnClick')
    assert len(lua.globals().routes)==2
check('enabling_auto_repair_does_not_interact_but_low_durability_and_manual_button_do',enabling_repair_quiet)

def settings_separated():
    lua=new({'Enabled':True,'Visible':True})
    frame=lua.globals().STSMmayorDurabilityFrame
    settings=lua.globals().STSMmayorSettingsButton
    indicator=lua.globals().STSMmayorRobotIndicator
    assert frame.height==34 and settings.point[1]=='LEFT' and settings.point[5]==0
    for name in ['STSMmayorEquipButton','STSMmayorRepairButton','STSMmayorPickupButton']:
        action=lua.globals()[name]
        assert action.width==32 and action.height==24 and action.point[1]=='LEFT' and action.point[5]==0
        assert action.point[4]+action.width<=indicator.point[4]-10
    assert indicator.point[4]+indicator.width<=settings.point[4]-10
    assert lua.globals().STSMmayorAutoSwapCheck is None
    lua.globals().STSMmayor_ToggleAppearance()
    for name in ['STSMmayorAutoSwapCheck','STSMmayorAutoRepairCheck','STSMmayorRobotDetectionCheck']:
        assert lua.globals()[name].parent.name=='STSMmayorAppearanceFrame'

check('settings_button_has_separate_row_and_nonoverlapping_hit_area',settings_separated)

def invalid_anchor():
    lua=new({'Enabled':True,'Visible':True,'Anchor':{'point':'bad','relativePoint':'CENTER','x':0,'y':0},'PositionLocked':'bad'})
    assert lua.globals().STSMmayorPositionFrame.point[1]=='TOPLEFT'
    assert not db(lua)['PositionLocked']
check('invalid_new_saved_fields_recover_to_safe_defaults',invalid_anchor)


bot_stub="""
botUnits={}; botTokens={}; targetCalls=0
function TargetByName() targetCalls=targetCalls+1 end
function botObject(unit) return botUnits[botTokens[unit] or unit] end
function UnitName(unit) local u=botObject(unit); return u and u.name end
function UnitExists(unit) local guid=botTokens[unit] or unit; local u=botUnits[guid]; return u and u.exists, u and guid end
function UnitIsVisible(unit) local u=botObject(unit); return u and u.visible end
function UnitCanAttack(player,unit) local u=botObject(unit); return u and u.hostile end
function UnitIsDead(unit) local u=botObject(unit); return u and u.dead end
function UnitHealth(unit) local u=botObject(unit); return u and u.health or 0 end
function addBot(guid,name) botUnits[guid]={name=name or '修理机器人75B型',exists=true,visible=true,hostile=false,health=100} end
function setPlates(...)
 local guids=arg
 WorldFrame={GetChildren=function()
  local plates={}
  for _,guid in ipairs(guids) do
   local plate={IsShown=function() return true end,GetName=function(self,mode) return guid end}
   table.insert(plates,plate)
  end
  return unpack(plates)
 end}
end
"""
def bot_runtime():
    lua=new({'Enabled':True,'Visible':True,'RobotDetection':True})
    lua.execute(bot_stub)
    lua.globals().STSMmayor_ResetRepairBots()
    lua.globals().STSMmayor_UpdateRepairBotStatus()
    return lua

def bot_event_and_loss():
    lua=bot_runtime()
    icon=lua.globals().STSMmayorRobotIndicator
    assert icon.Status=='missing'
    lua.execute('addBot("0xA1")')
    lua.globals().fire('UNIT_MODEL_CHANGED_GUID','0xA1')
    assert icon.Status=='present'
    lua.execute('botUnits["0xA1"].visible=false')
    lua.globals().tick(2.25)
    assert icon.Status=='missing' and lua.globals().targetCalls==0
check('robot_event_is_immediate_and_disappearance_is_checked_in_quarter_second',bot_event_and_loss)

def bot_target_guid_return():
    lua=bot_runtime()
    lua.execute('addBot("0xA2"); botTokens.target="0xA2"')
    lua.globals().fire('PLAYER_TARGET_CHANGED',None)
    assert lua.globals().STSMmayorRobotIndicator.Status=='present'
    lua.execute('botTokens.target=nil')
    lua.globals().tick(2.25)
    assert lua.globals().STSMmayorRobotIndicator.Status=='present'
    lua.execute('botUnits["0xA2"].exists=false')
    lua.globals().tick(2.5)
    assert lua.globals().STSMmayorRobotIndicator.Status=='missing'
check('pcall_unpacks_true_exists_and_guid_correctly',bot_target_guid_return)

def bot_multiple_and_death():
    lua=bot_runtime()
    lua.execute('addBot("0xA3"); addBot("0xA4","Repair Bot 75A")')
    lua.globals().fire('UNIT_FLAGS','0xA3')
    lua.globals().fire('UNIT_FLAGS_GUID','0xA4')
    lua.globals().fire('UNIT_DIED','0xA4')
    assert lua.globals().STSMmayorRobotIndicator.Status=='present'
    lua.globals().fire('UNIT_DIED','0xA3')
    assert lua.globals().STSMmayorRobotIndicator.Status=='missing'
    lua.globals().fire('UNIT_FLAGS_GUID','0xA3')
    assert lua.globals().STSMmayorRobotIndicator.Status=='missing'
check('multiple_robots_and_death_events_do_not_leave_stale_green_indicator',bot_multiple_and_death)

def bot_existing_nameplate():
    lua=bot_runtime()
    lua.execute('addBot("0xA5"); setPlates("0xA5")')
    lua.globals().STSMmayor_ResetRepairBots()
    lua.globals().STSMmayor_UpdateRepairBotStatus()
    assert lua.globals().STSMmayorRobotIndicator.Status=='present'
    lua.execute('botUnits["0xA5"].health=0')
    lua.globals().tick(2.25)
    assert lua.globals().STSMmayorRobotIndicator.Status=='missing'
    assert lua.globals().targetCalls==0
check('visible_nameplates_find_preexisting_robots_and_dead_units_are_excluded',bot_existing_nameplate)

def bot_toggle_and_world():
    lua=bot_runtime()
    lua.execute('addBot("0xA6")')
    lua.globals().fire('UNIT_FLAGS_GUID','0xA6')
    lua.globals().fire('PLAYER_ENTERING_WORLD',None)
    assert lua.globals().STSMmayorRobotIndicator.Status=='missing'
    lua.globals().STSMmayor_ToggleAppearance()
    lua.globals().call(lua.globals().STSMmayorRobotDetectionCheck,'OnClick')
    assert lua.globals().STSMmayorRobotIndicator.Status=='disabled'
    watcher=lua.globals().STSMmayorRobotWatcher
    assert not watcher.shown and len(watcher.events)==0
    lua.globals().tick(10)
    assert lua.globals().STSMmayorRobotIndicator.Status=='disabled'
check('world_change_clears_robot_cache_and_detection_off_stops_polling',bot_toggle_and_world)

def settings_reopen_and_old_preferences():
    lua=new({'Enabled':True,'Visible':True,'AutoSwap':False,'AutoRepair':False,'RobotDetection':False})
    assert lua.globals().STSMmayorAutoRepairCheck is None
    lua.globals().STSMmayor_ToggleAppearance()
    panel=lua.globals().STSMmayorAppearanceFrame
    assert not lua.globals().STSMmayorAutoSwapCheck.checked
    lua.globals().call(lua.globals().STSMmayorAutoRepairCheck,'OnClick')
    lua.globals().STSMmayor_ToggleAppearance();lua.globals().STSMmayor_ToggleAppearance()
    assert panel.shown and lua.globals().STSMmayorAutoRepairCheck.checked
    assert lua.globals().STSMmayorDurabilityFrame.height==34
check('moved_settings_keep_preferences_and_do_not_duplicate_on_reopen',settings_reopen_and_old_preferences)

def adaptive_robot_polling():
    def count(mode):
        lua=bot_runtime()
        lua.execute('addBot("0xB1")')
        lua.globals().fire('UNIT_MODEL_CHANGED_GUID','0xB1')
        lua.execute('visibleCalls=0; oldUnitVisible=UnitIsVisible; UnitIsVisible=function(unit) if unit=="0xB1" then visibleCalls=visibleCalls+1 end; return oldUnitVisible(unit) end')
        if mode=='busy': lua.execute('GetFramerate=function() return 20 end')
        if mode=='hidden': lua.globals().STSMmayorDurabilityFrame.Hide(lua.globals().STSMmayorDurabilityFrame)
        for n in range(1,9): lua.globals().tick(2+n*0.25)
        return lua.globals().visibleCalls
    fast,busy,hidden=count('fast'),count('busy'),count('hidden')
    assert fast==8 and busy==3 and hidden==1
check('low_fps_and_hidden_panel_reduce_robot_polling_without_changing_state',adaptive_robot_polling)

def bounded_nameplate_scan():
    lua=bot_runtime()
    lua.execute("""
        plateLookups=0; enumerations=0; plates={}
        for i=1,300 do
            local guid=string.format("0xC%X",i)
            table.insert(plates,{IsShown=function() return true end,GetName=function() plateLookups=plateLookups+1; return guid end})
        end
        WorldFrame={GetChildren=function() enumerations=enumerations+1; return unpack(plates) end}
        STSMmayor_ResetRepairBots()
    """)
    for n in range(5):
        lua.globals().now=2+n*0.25
        before=lua.globals().plateLookups
        lua.globals().STSMmayor_UpdateRepairBotStatus()
        assert lua.globals().plateLookups-before<=64
        after=lua.globals().plateLookups
        lua.globals().STSMmayor_UpdateRepairBotStatus()
        assert lua.globals().plateLookups==after
    assert lua.globals().plateLookups==300 and lua.globals().enumerations==1
    events=lua.globals().STSMmayorRobotWatcher.events
    assert not events.UNIT_HEALTH and not events.UNIT_HEALTH_GUID
check('crowded_nameplates_are_batched_and_high_frequency_health_events_are_not_subscribed',bounded_nameplate_scan)



def legacy_anchor_migration():
    factors={'TOPLEFT':(0,1),'TOP':(0.5,1),'TOPRIGHT':(1,1),'LEFT':(0,0.5),'CENTER':(0.5,0.5),'RIGHT':(1,0.5),'BOTTOMLEFT':(0,0),'BOTTOM':(0.5,0),'BOTTOMRIGHT':(1,0)}
    for point,(px,py) in factors.items():
        lua=new({'Enabled':True,'Visible':True,'UIScale':0.75,'Anchor':{'point':point,'relativePoint':point,'x':80,'y':-40}})
        anchor=db(lua)['PositionAnchor']
        assert anchor['point']=='TOPLEFT' and anchor['relativePoint']=='BOTTOMLEFT'
        assert abs(anchor['x']-(px*1280+(80-px*320)*0.75))<1e-8
        assert abs(anchor['y']-(py*720+(-40+(1-py)*34)*0.75))<1e-8
        saved=dict(anchor)
        lua.globals().STSMmayor_SetUIScale(1.3);lua.globals().STSMmayor_SaveSettings()
        assert db(lua)['PositionAnchor']==saved
check('nine_legacy_anchor_types_migrate_once_without_slider_coordinate_conversion',legacy_anchor_migration)

def position_recovery_only():
    lua=new({'Enabled':True,'Visible':True,'PositionLocked':True,'UIScale':1.1,'BackgroundAlpha':0.2,'AutoRepair':False,'PositionAnchor':{'point':'BOTTOMRIGHT','relativePoint':'BOTTOMRIGHT','x':0,'y':0}})
    before=db(lua)
    lua.globals().SlashCmdList.STSMPOS()
    after=db(lua)
    assert after['PositionAnchor']['relativePoint']=='BOTTOMLEFT'
    assert abs(after['PositionAnchor']['x']-464)<1e-8
    assert abs(after['PositionAnchor']['y']-217.4)<1e-8
    for key in ['PositionLocked','UIScale','BackgroundAlpha','AutoRepair','Enabled','Visible']:
        assert before[key]==after[key]
check('position_only_recovery_keeps_lock_scale_transparency_and_function_preferences',position_recovery_only)

def horizontal_alignment():
    for pf in [True,False]:
        lua=new({'Enabled':True,'Visible':True},pf=pf)
        main=lua.globals().STSMmayorDurabilityFrame
        for value in [0.5,0.9,1,1.5]:
            lua.globals().STSMmayor_SetUIScale(value)
            left,bottom,width,height=lua.globals().frameRect(main)
            middle=bottom+height/2
            for name in ['STSMmayorEquipButton','STSMmayorRepairButton','STSMmayorPickupButton','STSMmayorRobotIndicator','STSMmayorSettingsButton','STSMmayorCloseButton']:
                obj=lua.globals()[name]
                _,b,_,h=lua.globals().frameRect(obj)
                assert abs(b+h/2-middle)<1e-8
                if obj.Label and obj.kind=='Button':
                    _,b,_,h=lua.globals().frameRect(obj.Label)
                    assert abs(b+h/2-middle)<1e-8
check('all_main_controls_and_button_text_share_one_centerline_at_four_scales',horizontal_alignment)

def settings_alignment():
    for pf in [True,False]:
        lua=new({'Enabled':True,'Visible':True},pf=pf)
        lua.globals().STSMmayor_ToggleAppearance()
        labelLeft=[]
        for name in ['STSMmayorAutoSwapCheck','STSMmayorAutoRepairCheck','STSMmayorRobotDetectionCheck','STSMmayorPositionLockCheck']:
            obj=lua.globals()[name]
            left,bottom,width,height=lua.globals().frameRect(obj)
            ll,lb,lw,lh=lua.globals().frameRect(obj.Label)
            labelLeft.append(ll)
            assert abs(lb+lh/2-(bottom+height/2))<1e-8
        assert max(labelLeft)-min(labelLeft)<1e-8
        obj=lua.globals().STSMmayorAppearanceClose
        left,bottom,width,height=lua.globals().frameRect(obj)
        ll,lb,lw,lh=lua.globals().frameRect(obj.GetFontString(obj))
        assert abs(lb+lh/2-(bottom+height/2))<1e-8
check('settings_checkboxes_labels_and_done_button_align_with_and_without_pfui',settings_alignment)

def reproduce_old_missing_drag_anchor():
    previous=LuaRuntime(unpack_returned_tuples=True)
    previous.execute(stub)
    previous.execute((work/'STSMmayor-v2.4.5.lua').read_text(encoding='utf-8-sig'))
    previous.execute("STSMmayorDB={Enabled=true,Visible=true};fire('ADDON_LOADED','STSMmayor');fire('PLAYER_ENTERING_WORLD');tick(2)")
    before=db(previous).get('Anchor')
    previous.execute("call(STSMmayorDurabilityFrame,'OnDragStart'); STSMmayorDurabilityFrame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',300,220); STSMmayorDurabilityFrame.GetPoint=function() return nil end; call(STSMmayorDurabilityFrame,'OnDragStop'); fire('PLAYER_LOGOUT')")
    assert db(previous).get('Anchor')==before
    assert before.get('x')!=300 or before.get('y')!=220
check('previous_version_reproduces_lost_drag_position_when_native_GetPoint_is_empty',reproduce_old_missing_drag_anchor)

def empty_or_corrupt_getpoint_reload():
    for mode in ['empty','garbage']:
        lua=new({'Enabled':True,'Visible':True,'UIScale':0.75})
        lua.execute("call(STSMmayorDurabilityFrame,'OnDragStart'); STSMmayorPositionFrame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',370,420)")
        if mode=='empty': lua.execute('STSMmayorPositionFrame.GetPoint=function() return nil end')
        else: lua.execute("STSMmayorPositionFrame.GetPoint=function() return 'junk', 'junk', 'junk', 9999, 9999 end")
        lua.globals().call(lua.globals().STSMmayorDurabilityFrame,'OnDragStop')
        lua.globals().tick(2.1)
        assert db(lua)['PositionAnchor']=={'point':'TOPLEFT','relativePoint':'BOTTOMLEFT','x':370,'y':420}
        lua.globals().fire('PLAYER_LOGOUT',None)
        again=new(db(lua))
        assert again.globals().frameRect(again.globals().STSMmayorDurabilityFrame)==lua.globals().frameRect(lua.globals().STSMmayorDurabilityFrame)
check('empty_or_corrupt_native_GetPoint_no_longer_loses_position_on_reload',empty_or_corrupt_getpoint_reload)

def deferred_geometry_and_preservation():
    lua=new({'Enabled':True,'Visible':True})
    original=db(lua)['PositionAnchor']
    lua.execute("call(STSMmayorDurabilityFrame,'OnDragStart'); STSMmayorPositionFrame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',120,280); savedLeft=STSMmayorPositionFrame.GetLeft; savedTop=STSMmayorPositionFrame.GetTop; STSMmayorPositionFrame.GetLeft=function() return nil end; STSMmayorPositionFrame.GetTop=function() return nil end; call(STSMmayorDurabilityFrame,'OnDragStop')")
    assert db(lua)['PositionAnchor']==original
    lua.globals().tick(2.05)
    assert db(lua)['PositionAnchor']==original
    lua.execute('STSMmayorPositionFrame.GetLeft=savedLeft;STSMmayorPositionFrame.GetTop=savedTop')
    lua.globals().tick(2.15)
    assert db(lua)['PositionAnchor']['x']==120 and db(lua)['PositionAnchor']['y']==280
    assert lua.globals().STSMmayorPositionFrame.scripts.OnUpdate is None
    lua.execute("call(STSMmayorDurabilityFrame,'OnDragStart'); STSMmayorPositionFrame.GetTop=function() return nil end;call(STSMmayorDurabilityFrame,'OnDragStop')")
    lua.globals().tick(4)
    assert lua.globals().STSMmayorPositionFrame.scripts.OnUpdate is None
    assert db(lua)['PositionAnchor']['x']==120
check('transient_geometry_retries_once_layout_is_ready_and_never_erases_last_position',deferred_geometry_and_preservation)

def logout_during_drag_and_repeat_reload():
    lua=new({'Enabled':True,'Visible':True})
    lua.execute("call(STSMmayorDurabilityFrame,'OnDragStart');STSMmayorPositionFrame:SetPoint('TOPLEFT',UIParent,'BOTTOMLEFT',190,340)")
    lua.globals().fire('PLAYER_LOGOUT',None)
    assert lua.globals().STSMmayorPositionFrame.moving is False
    expected={'point':'TOPLEFT','relativePoint':'BOTTOMLEFT','x':190,'y':340}
    assert db(lua)['PositionAnchor']==expected
    for _ in range(5):
        lua=new(db(lua));lua.globals().fire('PLAYER_ENTERING_WORLD',None)
        lua.globals().fire('PLAYER_LOGOUT',None)
        assert db(lua)['PositionAnchor']==expected
check('reload_while_dragging_and_five_reloads_preserve_final_position',logout_during_drag_and_repeat_reload)

FORCE_LINK='|cffa335ee|Hitem:18168:0:0:0|h[力反馈盾牌]|h|r'

def force_login_preserves_preferences():
    saved={'Enabled':False,'Visible':False,'AutoSwap':False,'AutoRepair':False,'RobotDetection':False,'UIScale':1.2,'BackgroundAlpha':0.1,'PositionLocked':True,'PositionAnchor':{'point':'TOPLEFT','relativePoint':'BOTTOMLEFT','x':205,'y':320}}
    for link in [FORCE_LINK,'|Hitem:18168:123:456:0|h[Force Reactive Disk]|h']:
        lua=new(saved,equipped=link)
        assert lua.globals().STSMmayor_Enabled and lua.globals().STSMmayorDurabilityFrame.shown
        after=db(lua)
        assert after['Enabled'] and after['Visible']
        for key in ['AutoSwap','AutoRepair','RobotDetection','UIScale','BackgroundAlpha','PositionLocked','PositionAnchor']:
            assert after[key]==saved[key]
        assert len(lua.globals().messages)==0
check('force_disk_on_login_opens_panel_by_ID_and_keeps_all_preferences_and_position',force_login_preserves_preferences)

def force_only_player_equipment_opens():
    lua=new({'Enabled':False,'Visible':False})
    lua.globals().equippedLink=FORCE_LINK
    lua.globals().fire('UNIT_INVENTORY_CHANGED','party1')
    lua.globals().fire('UPDATE_INVENTORY_DURABILITY',None)
    assert not lua.globals().STSMmayor_Enabled
    lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
    assert lua.globals().STSMmayor_Enabled and lua.globals().STSMmayorDurabilityFrame.shown
    assert db(lua)['Enabled'] and db(lua)['Visible'] and len(lua.globals().messages)==0
check('only_player_inventory_equipment_transition_auto_enables',force_only_player_equipment_opens)

def force_manual_hide_and_disable():
    for close in ['close','disable']:
        lua=new({'Enabled':False,'Visible':False},equipped=FORCE_LINK)
        if close=='close': lua.globals().call(lua.globals().STSMmayorCloseButton,'OnClick')
        else: lua.globals().STSMmayor_SetEnabled(False)
        for _ in range(3):
            lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
            lua.globals().fire('UPDATE_INVENTORY_DURABILITY',None)
            lua.globals().fire('PLAYER_ENTERING_WORLD',None)
        assert not lua.globals().STSMmayorDurabilityFrame.shown
        assert db(lua)['Visible'] is False
        lua.globals().equippedLink=None
        lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
        assert not lua.globals().STSMmayorDurabilityFrame.shown
        lua.globals().equippedLink=FORCE_LINK
        lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
        assert lua.globals().STSMmayor_Enabled and lua.globals().STSMmayorDurabilityFrame.shown
check('manual_close_or_disable_is_respected_until_next_disk_equip',force_manual_hide_and_disable)

def other_items_do_not_enable():
    for link in [None,'|Hitem:181680:0:0:0|h[力反馈盾牌]|h','|Hitem:18291:0:0:0|h[结构图：力反馈盾牌]|h','|Hitem:1234:0:0:0|h[盾牌]|h','malformed']:
        lua=new({'Enabled':False,'Visible':False},equipped=link)
        lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
        assert not lua.globals().STSMmayor_Enabled
check('empty_offhand_recipe_similar_ID_other_shield_and_invalid_link_do_not_auto_enable',other_items_do_not_enable)

def pending_equipment_data():
    lua=new({'Enabled':False,'Visible':False})
    lua.execute('GetInventorySlotInfo=function() return nil end')
    lua.globals().equippedLink=FORCE_LINK
    lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
    assert not lua.globals().STSMmayor_Enabled
    lua.execute('GetInventorySlotInfo=function() return 17 end')
    lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
    assert lua.globals().STSMmayor_Enabled
check('missing_equipment_data_is_safe_and_later_equipment_event_enables',pending_equipment_data)

def nested_equipment_event():
    lua=new({'Enabled':False,'Visible':False})
    lua.execute("enableCalls=0;oldEnable=STSMmayor_SetEnabled;STSMmayor_SetEnabled=function(value) enableCalls=enableCalls+1;fire('UNIT_INVENTORY_CHANGED','player');oldEnable(value) end")
    lua.globals().equippedLink=FORCE_LINK
    lua.globals().fire('UNIT_INVENTORY_CHANGED','player')
    assert lua.globals().enableCalls==1
    assert lua.globals().STSMmayor_Enabled
check('nested_inventory_event_does_not_recurse_or_enable_twice',nested_equipment_event)

def world_entry_and_reload_with_disk():
    lua=new({'Enabled':False,'Visible':False})
    lua.globals().equippedLink=FORCE_LINK
    lua.globals().fire('PLAYER_ENTERING_WORLD',None)
    assert lua.globals().STSMmayor_Enabled
    lua.globals().STSMmayor_SetEnabled(False)
    again=new(db(lua),equipped=FORCE_LINK)
    assert again.globals().STSMmayor_Enabled and db(again)['Visible']
    again.globals().equippedLink=None
    again.globals().fire('UNIT_INVENTORY_CHANGED','player')
    assert again.globals().STSMmayor_Enabled and db(again)['Visible']
check('world_entry_detects_new_disk_reload_reopens_and_unequip_keeps_monitor_enabled',world_entry_and_reload_with_disk)

toc=(work/'STSMmayor.toc').read_text(encoding='utf-8-sig')
assert '## SavedVariablesPerCharacter: STSMmayorDB' in toc
assert '## OptionalDeps: pfUI' in toc
assert '正在执行自动修理' not in source and '正在执行自动拾取' not in source
assert '常用命令：' not in source and '插件已加载，使用' not in source
(work/'test-results.json').write_text(json.dumps({'passed':len(tests),'cases':tests},indent=2),encoding='utf-8')
print('Full source loads in Lua 5.1; lifecycle/behavior cases passed: '+str(len(tests)))
