"""Two-row UI geometry and saved-position regressions against the live addon."""
import ast
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

work=ROOT/'PluginHistory/Evidence/CodexBackups/STSMmayor/interaction-los-2.4.10'
source=(ROOT/'Interface/AddOns/STSMmayor/STSMmayor.lua').read_text(encoding='utf-8-sig')
fixture=(work/'verify.py').read_text(encoding='utf-8-sig')
tree=ast.parse(fixture)
# Reuse immutable mocks and behavioral regressions without writing historical
# evidence or treating historical layout assertions as the new specification.
skip={'layout_and_pf','settings_separated','horizontal_alignment','clamp',
      'position_recovery_only','dll_static_range_evidence'}
for node in tree.body:
    if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id in {'stub','bot_stub','tests','FORCE_LINK'} for t in node.targets):
        exec(compile(ast.Module(body=[node],type_ignores=[]),str(work/'verify.py'),'exec'))
        if any(isinstance(t,ast.Name) and t.id=='stub' for t in node.targets):
            stub+='''
allObjects={};originalNewObject=newObject
function newObject(kind,name,parent)
 local obj=originalNewObject(kind,name,parent);table.insert(allObjects,obj);return obj
end
'''
    elif isinstance(node,ast.FunctionDef):
        body=ast.get_source_segment(fixture,node)
        if node.name=='settings_reopen_and_old_preferences':
            body=body.replace('.height==34','.height==62')
        if node.name=='appearance_changes':
            body=body.replace('bottom+height-178','bottom+height-206')
        exec(compile(body,str(work/'verify.py'),'exec'))
    elif isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and isinstance(node.value.func,ast.Name) and node.value.func.id=='check':
        fn=node.value.args[1]
        if isinstance(fn,ast.Name) and fn.id in skip: continue
        exec(compile(ast.Module(body=[node],type_ignores=[]),str(work/'verify.py'),'exec'))

def rect(lua,obj): return lua.globals().frameRect(obj)
actions=['STSMmayorEquipButton','STSMmayorRepairButton','STSMmayorPickupButton']
header=['STSMmayorRobotIndicator','STSMmayorSettingsButton','STSMmayorCloseButton']

def two_rows_and_hit_areas():
    for pf in [True,False]:
        lua=new({'Enabled':True,'Visible':True},pf=pf)
        main=lua.globals().STSMmayorDurabilityFrame
        assert main.width==192 and main.height==62
        for scale in [.5,.9,1,1.5]:
            lua.globals().STSMmayor_SetUIScale(scale)
            left,bottom,width,height=rect(lua,main); top=bottom+height
            boxes=[]
            for names,offset in [(header,16),(actions,44)]:
                for name in names:
                    obj=lua.globals()[name]; l,b,w,h=rect(lua,obj)
                    assert abs(b+h/2-(top-offset*scale))<1e-8,(pf,scale,name)
                    assert l>=left and l+w<=left+width and b>=bottom and b+h<=top
                    if obj.Label:
                        _,lb,_,lh=rect(lua,obj.Label)
                        assert abs(lb+lh/2-(b+h/2))<1e-8
                    boxes.append((l,b,w,h))
            for i,(l,b,w,h) in enumerate(boxes):
                for ll,bb,ww,hh in boxes[i+1:]:
                    assert l+w<=ll or ll+ww<=l or b+h<=bb or bb+hh<=b
            text=next(f for _,f in lua.globals().allObjects.items() if f.kind=='FontString' and f.GetText(f)=='未装备盾牌')
            l,b,w,h=rect(lua,text)
            assert abs(b+h/2-(top-16*scale))<1e-8
            assert l+w<=rect(lua,lua.globals().STSMmayorRobotIndicator)[0]
        assert [lua.globals()[n].width for n in actions]==[56,56,56]
check('two_rows_are_aligned_contained_and_nonoverlapping_with_and_without_pfUI_at_four_scales',two_rows_and_hit_areas)

def footer_does_not_revert_height():
    lua=new({'Enabled':True,'Visible':True})
    lua.globals().STSMmayor_ToggleAppearance()
    for _ in range(3):
        lua.globals().call(lua.globals().STSMmayorRobotDetectionCheck,'OnClick')
        lua.globals().STSMmayor_UpdateInteractButtons()
        assert lua.globals().STSMmayorDurabilityFrame.height==62
check('dependency_and_robot_setting_refresh_preserves_two_rows',footer_does_not_revert_height)

def saved_anchor_survives_layout_and_reload():
    anchor={'point':'TOPLEFT','relativePoint':'BOTTOMLEFT','x':300,'y':500}
    lua=new({'Enabled':True,'Visible':True,'PositionAnchor':anchor,'UIScale':.9,'BackgroundAlpha':.23,'PositionLocked':True})
    lua.globals().STSMmayor_ToggleAppearance()
    for scale in [.5,1.5,.9]:
        lua.globals().STSMmayor_SetUIScale(scale)
        lua.globals().STSMmayor_SaveSettings()
        saved=db(lua);assert saved['PositionAnchor']==anchor
        again=new(saved)
        assert db(again)['PositionAnchor']==anchor
        assert rect(lua,lua.globals().STSMmayorDurabilityFrame)==rect(again,again.globals().STSMmayorDurabilityFrame)
        assert db(again)['BackgroundAlpha']==.23 and db(again)['PositionLocked']
check('existing_top_left_position_scale_alpha_and_lock_survive_two_row_layout_and_reload',saved_anchor_survives_layout_and_reload)

def settings_and_close():
    lua=new({'Enabled':True,'Visible':True})
    settings=lua.globals().STSMmayorSettingsButton
    assert settings.Label.GetText(settings.Label)=='设' and settings.width==18
    lua.globals().call(settings,'OnClick')
    assert lua.globals().STSMmayorAppearanceFrame.shown
    lua.globals().call(lua.globals().STSMmayorCloseButton,'OnClick')
    assert not lua.globals().STSMmayorDurabilityFrame.shown
    assert not lua.globals().STSMmayorAppearanceFrame.shown
    assert db(lua)['Enabled'] and not db(lua)['Visible']
check('compact_settings_entry_and_header_close_keep_existing_behavior',settings_and_close)

def default_position_matches_new_dimensions():
    lua=new({'Enabled':True,'Visible':True})
    l,b,w,h=rect(lua,lua.globals().STSMmayorDurabilityFrame)
    assert abs(l+w/2-640)<1e-8
    assert abs(b-180)<1e-8
    lua.globals().SlashCmdList.STSMPOS()
    assert rect(lua,lua.globals().STSMmayorDurabilityFrame)==(l,b,w,h)
check('new_default_and_position_reset_center_the_narrower_panel',default_position_matches_new_dimensions)

def normalized_legacy_position_is_clamped():
    for x,y in [(3,-2),(3,3),(0,0)]:
        lua=new({'Enabled':True,'Visible':True,'Position':{'x':x,'y':y}})
        l,b,w,h=rect(lua,lua.globals().STSMmayorDurabilityFrame)
        assert l>=0 and b>=0 and l+w<=1280 and b+h<=720
check('legacy_normalized_positions_clamp_using_new_panel_dimensions',normalized_legacy_position_is_clamped)

print('Lua 5.1: '+str(len(tests))+' behavior groups passed against live STSMmayor.')
