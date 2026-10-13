"""Clear real units without borrowing markers on self; model server/local channels."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

tree = ast.parse((ROOT / 'PluginHistory/Evidence/addons_tmp/test_srti_tools.py').read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value) for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in node.targets))
ADDON = ROOT / 'Interface/AddOns/SimpleRaidTargetIcons'


def world(superwow, delayed, grouped=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute('''
        entities={}; calls={}; pending={}; onlyClears=false
        function entity(guid,player)
            local value={name=guid,guid=guid,hp=400,max=1000,isPlayer=player}
            units[guid]=value; table.insert(entities,value); return value
        end
        function refreshMarks()
            for i=1,8 do units['mark'..i]=nil end
            if not SetAutoloot then return end
            for _,value in ipairs(entities) do
                local index=value.localMark or value.serverMark
                if index then units['mark'..index]=value end
            end
        end
        function UnitIsPlayer(unit) return units[unit] and units[unit].isPlayer end
        function UnitIsUnit(a,b) return units[a] and units[a]==units[b] end
        function GetRaidTargetIndex(unit)
            local value=units[unit]
            return value and (value.localMark or value.serverMark)
        end
        function IsAltKeyDown() return alt end
        function SetRaidTarget(unit,index,localOnly)
            local value=units[unit]; assert(value,'missing unit')
            assert(not onlyClears or index==0,'clear-all assigned a marker, possibly onto self')
            if localOnly then assert(SetAutoloot,'local flag without SuperWoW') end
            table.insert(calls,{unit,index,localOnly})
            local channel=localOnly and 'localMark' or 'serverMark'
            if index==0 and delayClear and not localOnly then
                table.insert(pending,{value=value,channel=channel,at=time+.6})
            else
                if index>0 then
                    for _,other in ipairs(entities) do
                        if other[channel]==index then other[channel]=nil end
                    end
                end
                value[channel]=index>0 and index or nil
                refreshMarks()
            end
        end
        function tick()
            time=time+.25
            for i=table.getn(pending),1,-1 do
                local reply=pending[i]
                if reply.at<=time then reply.value[reply.channel]=nil; table.remove(pending,i) end
            end
            refreshMarks(); this=BananaFrame; Banana_OnUpdate()
        end
        function assertNoSelfMark()
            assert(not GetRaidTargetIndex('player'),'player received a borrowed marker')
            assert(not SRTI_Health8:IsShown() or SRTI_Health8.value==400,'phantom self health')
        end
    ''')
    if superwow:
        lua.execute('SetAutoloot=function() end')
    for filename in ('IconTextures.lua', 'SimpleRaidTargetIcons.lua', 'Banana.lua', 'RaidTools.lua', 'Localization.lua'):
        if filename == 'SimpleRaidTargetIcons.lua':
            lua.execute("WorldFrame=CreateFrame('Frame','WorldFrame',UIParent)")
        lua.execute((ADDON / filename).read_text(encoding='utf-8-sig'))
    lua.globals().raidCount = 8 if grouped else 0
    lua.globals().delayClear = delayed
    lua.execute('''
        BANANA_CONFIG.SHOW_EXTRA_INFO=0; BANANA_CONFIG.BUTTON_LAYOUT=1
        event='ADDON_LOADED'; arg1='SimpleRaidTargetIcons'; this=BananaFrame
        Banana_OnEvent()
        units.player=entity('self',true); units.player.hp=800
        for i=1,8 do
            local value=entity('enemy'..i)
            value[SetAutoloot and raidCount==0 and 'localMark' or 'serverMark']=i
            units['raid'..i..'target']=value
        end
        units.target=units.enemy8
        refreshMarks(); Banana_UpdateStatus()
        assert(SRTI_Health8:IsShown() and SRTI_Health8.value==400)
    ''')
    return lua


groups = 0
for superwow in (False, True):
    for delayed in (False, True):
        for entry in ('button', 'alt'):
            lua = world(superwow, delayed)
            lua.execute('onlyClears=true')
            if entry == 'button':
                lua.execute("SRTI_ClearButton:Fire('OnClick','LeftButton')")
            else:
                lua.execute("alt=true; this=RaidTargetFrame8Button; Banana_ButtonOnClick('LeftButton'); alt=false")
            lua.execute('''
                assertNoSelfMark()
                for i=1,12 do tick(); assertNoSelfMark() end
                for i=1,8 do assert(not GetRaidTargetIndex('enemy'..i),'uncleared real marker') end
                assert(not SRTI_Health8:IsShown())
                onlyClears=false; Banana_SetSymbol('enemy8',8)
                Banana_UpdateStatus(); assert(SRTI_Health8:IsShown() and SRTI_Health8.value==400)
                units.enemy8.hp=100; tick(); assert(SRTI_Health8.value==100)
            ''')
            groups += 1

# SuperWoW solo marks and a grouped outsider's local marks use only local clears.
for grouped in (False, True):
    lua = world(True, True, grouped)
    lua.execute('''
        if raidCount>0 then
            units.enemy8.isPlayer=true; units.enemy8.serverMark=nil; units.enemy8.localMark=8
        end
        refreshMarks(); onlyClears=true; Banana_ClearAllSymbols()
        assertNoSelfMark()
        for _,call in ipairs(calls) do
            if raidCount==0 or call[1]=='enemy8' then assert(call[3]==1,'native clear for local-only target') end
        end
        for i=1,12 do tick(); assertNoSelfMark() end
        for i=1,8 do assert(not GetRaidTargetIndex('enemy'..i)) end
    ''')
    groups += 1

# Late server updates retry the original GUID, never a changed target alias.
lua = world(True, False)
lua.execute('''
    onlyClears=true; Banana_ClearAllSymbols()
    units.enemy8.serverMark=8; units.target=entity('new-target'); units.target.serverMark=7
    refreshMarks(); tick()
    assert(not GetRaidTargetIndex('enemy8') and GetRaidTargetIndex('new-target')==7)
    assertNoSelfMark()
''')
groups += 1

# Reusing a mark on another unit while waiting must not clear that new unit.
lua = world(True, False)
lua.execute('''
    Banana_ClearAllSymbols()
    units.new=entity('new'); units.new.serverMark=8
    refreshMarks(); onlyClears=true
    for i=1,12 do tick(); assert(GetRaidTargetIndex('new')==8); assertNoSelfMark() end
''')
groups += 1

# Real self skulls are removable; empty/repeated clears never add one.
lua = world(True, False)
lua.execute('''
    units.player.serverMark=8; units.enemy8.serverMark=nil; refreshMarks()
    onlyClears=true; Banana_ClearAllSymbols(); assertNoSelfMark()
    calls={}; Banana_ClearAllSymbols(); assert(table.getn(calls)==0)
''')
groups += 1

# Accepted assignments cancel retries, including the radial menu's wrapper.
for radial in (False, True):
    lua = world(True, False)
    lua.execute('Banana_ClearAllSymbols()')
    if radial:
        lua.execute('''
            local _,handler=debug.getupvalue(WorldFrame:GetScript('OnMouseUp'),1)
            local setter
            for i=1,20 do
                local name,value=debug.getupvalue(handler,i)
                if name=='setRaidTarget' then setter=value break end
            end
            assert(setter); setter('player',8)
        ''')
    else:
        lua.execute("Banana_SetSymbol('player',8)")
    lua.execute('''
        local count=table.getn(calls)
        for i=1,12 do tick() end
        assert(table.getn(calls)==count and GetRaidTargetIndex('player')==8)
        assert(SRTI_Health8:IsShown() and SRTI_Health8.value==800)
    ''')
    groups += 1

# Missing GUIDs receive one immediate clear, without unsafe alias retries.
lua = world(True, False)
lua.execute('''
    units.enemy8.guid=nil
    onlyClears=true; Banana_ClearAllSymbols()
    units.enemy8.serverMark=8; refreshMarks()
    local count=table.getn(calls)
    for i=1,12 do tick() end
    assert(table.getn(calls)==count and GetRaidTargetIndex('enemy8')==8)
''')
groups += 1

# A changed mark on the same original unit is also protected from old retries.
lua = world(True, False)
lua.execute('''
    Banana_ClearAllSymbols(); units.enemy8.serverMark=6; refreshMarks()
    onlyClears=true
    for i=1,12 do tick(); assert(GetRaidTargetIndex('enemy8')==6) end
''')
groups += 1

# A paused/disabled UI cannot revive old cleanup when enabled much later.
lua = world(True, False)
lua.execute('''
    Banana_ClearAllSymbols(); BANANA_CONFIG.ENABLED=0
    time=time+10; units.enemy8.serverMark=8; refreshMarks()
    BANANA_CONFIG.ENABLED=1
    local count=table.getn(calls); tick()
    assert(table.getn(calls)==count and GetRaidTargetIndex('enemy8')==8)
''')
groups += 1

# Local and server marks on one unit both clear, without any assignment to self.
lua = world(True, False)
lua.execute('''
    units.enemy8.localMark=8; units.enemy8.serverMark=7; refreshMarks()
    onlyClears=true; Banana_ClearAllSymbols()
    assert(not units.enemy8.localMark and not units.enemy8.serverMark)
    assertNoSelfMark()
''')
groups += 1

print(f'PASS: {groups} direct-clear groups; no positive marker assignments, native/local channels, delayed replies, pinned GUID retries, empty clears and explicit reassignment')
