"""Cross-module EavesDrop regressions with actual core, UI and event modules.

Runs Lua 5.1 with the shared strict 1.12 font contract. No game, DLL, account
settings, private chat, file export or network action is involved.
"""
import unittest

from test_eavesdrop_core import ADDON, INTEGRATION, runtime


SETUP = r'''
current=0
function GetTime() return current end
lostGuid='0xF13000EA59000001'
foreignLostGuid='0xF13000EA59000002'
owners={[lostGuid..'owner']=playerGuid,[foreignLostGuid..'owner']=allyGuid}
local oldGuid, oldName, oldSpell=GetUnitGUID,UnitName,GetSpellRecField
function GetUnitGUID(u) return owners[u] or oldGuid(u) end
function UnitName(u)
  if u==lostGuid or u==foreignLostGuid then return '迷失者' end
  return oldName(u)
end
function GetUnitField(u,key)
  assert(key=='createdBy' or key=='summonedBy','unexpected native field')
  if key=='createdBy' then return owners[u..'owner'] end
end
function GetSpellRecField(id,key)
  if key=='name' and id==99 then return '召唤迷失者' end
  return oldSpell(id,key)
end
function GetSpellNameAndRankForId(id) return GetSpellRecField(id,'name') end
function dispatch(frame,name,...)
  assert(frame and frame:IsEventRegistered(name),'event not registered: '..name)
  event=name
  arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9=unpack(arg)
  invoke(frame,'OnEvent')
  event=nil;arg1=nil;arg2=nil;arg3=nil;arg4=nil;arg5=nil;arg6=nil;arg7=nil;arg8=nil;arg9=nil
end
function floating(kind,name)
  dispatch(EavesDrop.procFrame,'COMBAT_TEXT_UPDATE',kind,name)
  if EavesDrop.captureFrame and EavesDrop.captureFrame:IsEventRegistered('COMBAT_TEXT_UPDATE') then
    dispatch(EavesDrop.captureFrame,'COMBAT_TEXT_UPDATE',kind,name)
  end
end
function summonHit(guid,amount)
  native('AUTO_ATTACK_OTHER',guid,enemyGuid,amount,0,1,1,0,0,0)
end
'''


def full_runtime():
    lua = runtime()
    lua.execute(INTEGRATION)
    lua.execute(SETUP)
    for name in ('icons.lua', 'enhanced.lua', 'procs.lua', 'diagnostics.lua', 'ui.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute('EavesDrop:RefreshCombatSources(); EavesDrop:StartProcMonitoring(); EavesDrop:ApplySkin()')
    return lua


class EavesDropModuleTests(unittest.TestCase):
    def test_legacy_buffs_debuffs_and_late_icon_provider(self):
        lua = full_runtime()
        lua.execute(r'''
          AceLibrary('Babble-Spell-2.2').GetSpellIcon=function()return nil end
          EavesDrop.db.profile.BUFF=true; EavesDrop.db.profile.DEBUFF=true; EavesDrop.db.profile.FADE=true
          local info={type='buff',victim=ParserLib_SELF,skill='测试光环'}
          EavesDrop:RouteCombatEvent(info)
          assert(EavesDropEvent10IncomingTexture.texture==nil)
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            if name=='测试光环' then return 'Interface\\Icons\\TestAura' end
          end}}
          for _,kind in ipairs({'buff','debuff','fade'}) do
            EavesDrop:RouteCombatEvent({type=kind,victim=ParserLib_SELF,skill='测试光环'})
            assert(EavesDropEvent10IncomingTexture.texture=='Interface\\Icons\\TestAura')
          end
          EavesDrop.db.profile.PLACEHOLDER=true
          EavesDrop:RouteCombatEvent({type='buff',victim=ParserLib_SELF,skill='未知光环'})
          assert(EavesDropEvent10IncomingTexture.texture=='Interface\\Icons\\INV_Misc_QuestionMark')
        ''')

    def test_unknown_enhanced_icon_uses_name_and_high_record_retains_texture(self):
        lua = full_runtime()
        lua.execute(r'''
          AceLibrary('Babble-Spell-2.2').GetSpellIcon=function()return nil end
          local original=GetSpellRecField
          function GetSpellRecField(id,key)
            if id==42 and key=='spellIconID' then return 0 end
            return original(id,key)
          end
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            if name=='Spell42' then return 'Interface\\Icons\\KnownSpell' end
          end}}
          native('SPELL_DAMAGE_EVENT_SELF',enemyGuid,playerGuid,42,33,'0,0,0',0,5,'0,0,0,3')
          assert(EavesDropEvent10OutgoingTexture.texture=='Interface\\Icons\\KnownSpell')
          assert(EavesDrop.db.char.Stats[1].hit.Spell42[-2].texture=='Interface\\Icons\\KnownSpell')
          DPSMateX=nil
          EavesDrop:SetDisplay(1,'hit')
          assert(EavesDropHistoryEvent1_Texture.texture=='Interface\\Icons\\KnownSpell')
          EavesDrop:RouteCombatEvent({type='hit',source='Enemy',victim=ParserLib_SELF,
            skill='Spell42',element='Fire',amount=11,texture='Interface\\Icons\\KnownSpell',enhanced=true})
          assert(EavesDrop.db.char.Stats[-1].hit.Fire[-2].texture==nil)
        ''')

    def test_proc_notification_uses_named_icon(self):
        lua = full_runtime()
        lua.execute(r'''
          AceLibrary('Babble-Spell-2.2').GetSpellIcon=function()return nil end
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            if name=='召唤迷失者' then return 'Interface\\Icons\\Spell_Shadow_RaiseDead' end
          end}}
          floating('SPELL_CAST','召唤迷失者')
          assert(EavesDrop:GetProcRecords()[1].texture=='Interface\\Icons\\Spell_Shadow_RaiseDead')
          assert(EavesDropEvent10IncomingTexture.texture=='Interface\\Icons\\Spell_Shadow_RaiseDead')
        ''')

    def test_floating_available_and_cast_stay_distinct_in_records_and_sample(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop:StartCapture()
          floating('SPELL_ACTIVE','召唤迷失者')
          floating('SPELL_CAST','召唤迷失者')
          assert(EavesDrop.procStats.available==1 and EavesDrop.procStats.triggers==1)
          assert(EavesDrop.procStats.summons==0)
          local records=EavesDrop:GetProcRecords()
          assert(#records==2 and records[1].evidence=='available')
          assert(string.find(records[2].message,'不据此认定单位已生成',1,true))
          assert(#EavesDropCaptureDB.records==2)
          assert(EavesDropCaptureDB.records[1].args[1]=='SPELL_ACTIVE')
          assert(EavesDropCaptureDB.records[2].args[1]=='SPELL_CAST')
        ''')

    def test_owned_guardian_damage_works_independently_of_regular_pet_toggle(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop.db.profile.PET=false
          summonHit(lostGuid,42)
          assert(EavesDrop.procStats.summons==1 and EavesDrop.procStats.damage==42)
          assert(EavesDrop:GetHistoryState().count==2,'expected one first-observed notice and one hit')
          assert(EavesDropEvent10EventText.text=='[迷失者] 42')
          assert(EavesDrop:GetProcRecords()[1].evidence=='first_observed')
          summonHit(lostGuid,8)
          assert(EavesDrop.procStats.summons==1 and EavesDrop.procStats.damage==50)
          assert(EavesDrop:GetHistoryState().count==3)
        ''')

    def test_foreign_same_name_and_later_changed_owner_are_excluded(self):
        lua = full_runtime()
        lua.execute(r'''
          summonHit(foreignLostGuid,42)
          assert(EavesDrop:GetHistoryState().count==0 and #EavesDrop:GetProcRecords()==0)
          summonHit(lostGuid,10)
          owners[lostGuid..'owner']=allyGuid
          summonHit(lostGuid,99)
          assert(EavesDrop.procStats.damage==10 and EavesDrop:GetHistoryState().count==2)
        ''')

    def test_player_heal_to_guardian_keeps_core_high_record_without_double_display(self):
        lua = full_runtime()
        lua.execute(r'''
          native('SPELL_HEAL_BY_SELF',lostGuid,playerGuid,42,37,0,0)
          assert(EavesDrop.procStats.healing==37)
          assert(EavesDrop:GetHistoryState().count==2,'discovery plus one original player heal expected')
          assert(string.find(EavesDropEvent10EventText.text,'+37',1,true))
          assert(EavesDrop.db.char.Stats[1].heal.Spell42[-2].amount==37)
          local records=EavesDrop:GetProcRecords()
          assert(#records==2 and records[2].combatType=='heal' and records[2].merge==false)
        ''')

    def test_guardian_heal_to_player_keeps_incoming_high_record(self):
        lua = full_runtime()
        lua.execute(r'''
          native('SPELL_HEAL_BY_OTHER',playerGuid,lostGuid,42,29,0,0)
          assert(EavesDrop.procStats.healing==29 and EavesDrop:GetHistoryState().count==2)
          assert(string.sub(EavesDropEvent10EventText.text,1,1)=='+')
          assert(string.find(EavesDropEvent10EventText.text,'29',1,true))
          assert(EavesDrop.db.char.Stats[-1].heal.Spell42[-2].amount==29)
        ''')

    def test_merge_switch_retains_independent_records_but_not_main_history(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop.db.profile.PROCMERGE=false
          floating('SPELL_CAST','召唤迷失者');summonHit(lostGuid,15)
          assert(EavesDrop:GetHistoryState().count==0)
          assert(#EavesDrop:GetProcRecords()==3 and EavesDrop.procStats.triggers==1)
          assert(EavesDrop.procStats.summons==1 and EavesDrop.procStats.damage==15)
          EavesDrop:OpenProcRecords()
          assert(EavesDropProcRecordsFrame:IsShown())
        ''')

    def test_disable_stops_sampler_and_monitors_but_retains_this_round(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop:StartCapture();floating('SPELL_CAST','召唤迷失者')
          EavesDrop:ToggleActive(false)
          assert(not EavesDrop:IsActive() and not EavesDrop._running)
          assert(not EavesDrop:GetCaptureState().active and #EavesDropCaptureDB.records==1)
          assert(EavesDrop:GetCaptureState().reason=='监视已停用')
          assert(next(EavesDrop.captureFrame.events)==nil)
          assert(next(EavesDrop.procFrame.events)==nil and next(EavesDrop.enhancedFrame.events)==nil)
          EavesDrop:ToggleActive(true)
          assert(EavesDrop:IsActive() and EavesDrop._running)
          assert(not EavesDrop:GetCaptureState().active,'enabling monitor must not resume capture')
          assert(EavesDrop.procFrame:IsEventRegistered('COMBAT_TEXT_UPDATE'))
          assert(EavesDrop.procStats.triggers==1 and #EavesDropCaptureDB.records==1)
        ''')

    def test_selected_source_ignores_other_cast_feeds_and_refresh_keeps_counts(self):
        lua = full_runtime()
        lua.execute(r'''
          floating('SPELL_CAST','召唤迷失者')
          EavesDrop.db.profile.PROCSOURCE='native';EavesDrop:RefreshProcMonitoring()
          floating('SPELL_CAST','召唤迷失者')
          dispatch(EavesDrop.procFrame,'SPELL_GO_SELF',0,99,playerGuid,enemyGuid)
          EavesDrop:HandleProcEvent('UNIT_CASTEVENT',playerGuid,enemyGuid,'CAST',99)
          assert(EavesDrop.procStats.triggers==2)
          EavesDrop:RefreshProfile()
          assert(EavesDrop.procStats.triggers==2)
          assert(EavesDrop.procFrame:IsEventRegistered('SPELL_GO_SELF'))
        ''')

    def test_all_seven_settings_tabs_and_capture_buttons_use_actual_modules(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop:OpenSettings()
          local p=EavesDropSettingsFrame
          assert(#p.nav==7)
          for i=1,7 do invoke(p.nav[i],'OnClick');assert(p:IsShown())end
          invoke(p.rows[1].action,'OnClick');assert(EavesDrop:GetCaptureState().active)
          floating('SPELL_CAST','召唤迷失者')
          invoke(p.rows[2].action,'OnClick');assert(not EavesDrop:GetCaptureState().active)
          assert(#EavesDropCaptureDB.records==1)
          invoke(p.rows[3].action,'OnClick');assert(#EavesDropCaptureDB.records==0)
          invoke(p.nav[6],'OnClick');invoke(p.rows[7].action,'OnClick')
          assert(EavesDropProcRecordsFrame:IsShown())
          for _,o in ipairs(objects)do
            if o.kind=='FontString'then assert(o.font and o.font[1],'uninitialized font')end
          end
        ''')

    def test_capture_timer_does_not_replace_an_unapplied_profile_name(self):
        lua = full_runtime()
        lua.execute(r'''
          EavesDrop:StartCapture(); EavesDrop:OpenSettings(5)
          local edit=EavesDropSettingsFrame.rows[1].edit
          edit:SetText('New profile still being typed')
          current=1; invoke(EavesDrop.captureFrame,'OnUpdate')
          assert(edit:GetText()=='New profile still being typed')
          EavesDrop:OpenSettings(7)
          current=2; invoke(EavesDrop.captureFrame,'OnUpdate')
          assert(string.find(EavesDropSettingsFrame.rows[4].status.text,'118',1,true))
        ''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
