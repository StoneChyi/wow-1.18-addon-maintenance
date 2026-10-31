"""RandomMount casting gates on real module code; offline, not game acceptance.

The legacy suite is executed unchanged on import and supplies actual AceDB
save/default helpers. New cases model native 1.12 global event arguments.
"""
import contextlib
import importlib.util
import io
from pathlib import Path
import unittest

PATH = Path(__file__).with_name("test_automaton_randommount.py")
spec = importlib.util.spec_from_file_location("randommount_previous_suite", PATH)
base = importlib.util.module_from_spec(spec)
with contextlib.redirect_stdout(io.StringIO()):
    spec.loader.exec_module(base)

EXTRA = r'''
now=10; frames={}; channel=nil; actionQueries=0
function GetTime() return now end
function IsCurrentAction() actionQueries=actionQueries+1; return true end
function CreateFrame(kind)
    assert(kind=='Frame')
    local frame={events={},scripts={}}
    function frame:RegisterEvent(name) self.events[name]=true end
    function frame:SetScript(name,callback)
        assert(name=='OnEvent', 'no per-frame polling or unrelated scripts')
        self.scripts[name]=callback
    end
    table.insert(frames,frame)
    return frame
end
function emit(name,a,b)
    local oldevent,old1,old2=event,arg1,arg2
    event,arg1,arg2=name,a,b
    for _,frame in ipairs(frames) do
        if frame.events[name] then frame.scripts.OnEvent() end
    end
    event,arg1,arg2=oldevent,old1,old2
end
function UnitChannelInfo(unit) assert(unit=='player'); return channel end
string.match=nil; string.gmatch=nil; select=nil; math.huge=nil
'''


def world(source=None):
    lua = base.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().inheritDefaults = lua.execute(base.INHERIT + "\nreturn inheritDefaults")
    lua.globals().cleanDefaults = lua.execute(base.CLEAN + "\nreturn cleanDefaults")
    lua.execute(base.STUB)
    lua.execute(EXTRA)
    lua.execute(base.BOOK)
    lua.execute(source or base.SOURCE)
    lua.execute("module:OnInitialize()")
    return lua


class RandomMountCastGate(unittest.TestCase):
    def test_active_action_is_not_a_cast(self):
        world().execute("RandomMount(); assert(#calls==1 and actionQueries==0)")

    def test_optional_cast_and_channel_queries(self):
        world().execute(r'''
casting=true; RandomMount(); assert(#calls==0)
casting=false; channel='引导'; RandomMount(); assert(#calls==0)
channel=nil; RandomMount(); assert(#calls==1)
''')

    def test_native_cast_start_delay_stop(self):
        world().execute(r'''
UnitCastingInfo=nil; UnitChannelInfo=nil
emit('SPELLCAST_START','治疗术',2000); RandomMount(); assert(#calls==0)
now=11; emit('SPELLCAST_DELAYED',1500)
now=13; RandomMount(); assert(#calls==0)
emit('SPELLCAST_STOP'); RandomMount(); assert(#calls==1)
assert(namespace.char.lastMountName=='黑马')
''')

    def test_native_channel_update_and_stop(self):
        world().execute(r'''
UnitCastingInfo=nil; UnitChannelInfo=nil
emit('SPELLCAST_CHANNEL_START',6000,'暴风雪'); RandomMount(); assert(#calls==0)
-- A failed cast attempted during an existing channel does not end it.
emit('SPELLCAST_FAILED'); emit('SPELLCAST_STOP'); RandomMount(); assert(#calls==0)
now=11; emit('SPELLCAST_CHANNEL_UPDATE',1000)
now=11.5; RandomMount(); assert(#calls==0)
emit('SPELLCAST_CHANNEL_STOP'); RandomMount(); assert(#calls==1)
emit('SPELLCAST_CHANNEL_START',3000,'引导')
emit('SPELLCAST_CHANNEL_UPDATE',0); RandomMount(); assert(#calls==2)
''')

    def test_missing_end_event_expires_without_polling(self):
        world().execute(r'''
UnitCastingInfo=nil; UnitChannelInfo=nil
emit('SPELLCAST_START','治疗术',1000)
now=11; RandomMount(); assert(#calls==1 and module.castObserver.mode==nil)
emit('SPELLCAST_CHANNEL_START',2000,'引导')
now=13; RandomMount(); assert(#calls==2)
assert(frames[1].scripts.OnUpdate==nil)
''')

    def test_failed_interrupted_and_world_change_release(self):
        for ending in ('SPELLCAST_FAILED','SPELLCAST_INTERRUPTED',
                       'PLAYER_ENTERING_WORLD','PLAYER_LEAVING_WORLD'):
            with self.subTest(ending=ending):
                world().execute("emit('SPELLCAST_START','治疗术',6000); emit('" + ending + "'); RandomMount(); assert(#calls==1)")

    def test_world_change_clears_channel(self):
        world().execute("emit('SPELLCAST_CHANNEL_START',6000,'引导'); emit('PLAYER_LEAVING_WORLD'); RandomMount(); assert(#calls==1)")

    def test_bad_optional_queries_use_native_observation(self):
        world().execute(r'''
UnitCastingInfo=function() error('extension unavailable') end
UnitChannelInfo='unavailable'
emit('SPELLCAST_START','治疗术',1000); RandomMount(); assert(#calls==0)
now=11; RandomMount(); assert(#calls==1)
''')

    def test_manual_commands_and_reenable_reuse_observer(self):
        world().execute(r'''
local options=module.registeredOptions
local observer=module.castObserver
module:OnDisable(); SlashCmdList.RANDOMMOUNT(''); assert(#calls==1)
assert(SLASH_RANDOMMOUNT1=='/rm' and SLASH_RANDOMMOUNT2=='/randommount')
module:OnEnable(); module:OnDisable(); module:OnInitialize()
assert(#frames==1 and observer==module.castObserver and options==module.registeredOptions)
module:AddCustomMount('黑马'); module:ExcludeMount('白马')
emit('SPELLCAST_START','治疗术',3000)
SlashCmdList.RANDOMMOUNT(''); assert(#calls==1)
emit('SPELLCAST_STOP'); SlashCmdList.RANDOMMOUNT(''); assert(#calls==2 and calls[2][2]=='黑马')
assert(namespace.char.customMounts[1]=='黑马' and namespace.char.excludedMounts[1]=='白马')
''')

    def test_invalid_event_durations_do_not_stick(self):
        world().execute(r'''
emit('SPELLCAST_START','治疗术','3000'); RandomMount(); assert(#calls==1)
emit('SPELLCAST_CHANNEL_START',0,'引导'); RandomMount(); assert(#calls==2)
emit('SPELLCAST_START','治疗术',0/0); RandomMount(); assert(#calls==3)
emit('SPELLCAST_CHANNEL_START',1/0,'引导'); RandomMount(); assert(#calls==4)
''')

    def test_combat_and_blocked_calls_preserve_previous_selection(self):
        world().execute(r'''
RandomMount(); local previous=namespace.char.lastMountName
combat=true; RandomMount(); combat=false
emit('SPELLCAST_START','治疗术',2000); RandomMount()
assert(#calls==1 and namespace.char.lastMountName==previous)
emit('SPELLCAST_STOP'); RandomMount(); assert(#calls==2 and calls[2][2]~=previous)
''')

    def test_negative_control_missing_gate_is_rejected(self):
        source=base.SOURCE.replace('if IsPlayerCasting() then','if false then',1)
        with self.assertRaises(Exception):
            world(source).execute("emit('SPELLCAST_START','治疗术',2000); RandomMount(); assert(#calls==0)")


if __name__ == '__main__':
    print(f'Legacy unchanged behavior groups: {base.groups}')
    unittest.main()
