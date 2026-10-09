"""Clear-all regression against current addon code; requires lupa's Lua 5.1 backend."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

# Reuse only the immutable UI mock, never execute historical addon code or tests.
fixture = ROOT / 'PluginHistory/Evidence/addons_tmp/test_srti_tools.py'
tree = ast.parse(fixture.read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value) for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in node.targets))
ADDON = ROOT / 'Interface/AddOns/SimpleRaidTargetIcons'


def world(superwow, delayed):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if superwow:
        lua.execute('SetAutoloot=function() end')
    for filename in ('IconTextures.lua', 'Banana.lua', 'RaidTools.lua', 'Localization.lua'):
        lua.execute((ADDON / filename).read_text(encoding='utf-8-sig'))
    lua.execute('''
        BANANA_CONFIG.SHOW_EXTRA_INFO=0; BANANA_CONFIG.BUTTON_LAYOUT=1
        event='ADDON_LOADED'; arg1='SimpleRaidTargetIcons'; this=BananaFrame
        Banana_OnEvent()
        partyCount=1
        units.player={name='Player',guid='player',hp=800,max=1000}
        units.party1=units.player
        function UnitIsUnit(a,b) return units[a] and units[a]==units[b] end
        function IsAltKeyDown() return alt end
        calls={}; pendingClear=false
        function SetRaidTarget(unit,index)
            table.insert(calls,{unit,index})
            if index==0 and delayClear then pendingClear=true; return end
            for _,entity in pairs(units) do
                if index>0 and entity.mark==index then entity.mark=nil end
            end
            units[unit].mark=index>0 and index or nil
            if index>0 then units['mark'..index]=units[unit] end
        end
        function tick()
            time=time+.25; this=BananaFrame; Banana_OnUpdate()
        end
        function assertNoHealth()
            for i=1,8 do
                assert(not getglobal('SRTI_Health'..i):IsShown(), 'phantom health: '..i)
            end
        end
        -- Every real icon starts occupied, including a skull target with visible health.
        for i=1,8 do
            units['enemy'..i]={name='Enemy'..i,guid='enemy'..i,hp=400,max=1000,mark=i}
            units['mark'..i]=units['enemy'..i]
        end
        units.target=units.enemy8
        Banana_UpdateStatus()
        assert(SRTI_Health8:IsShown() and SRTI_Health8.value==400)
    ''')
    lua.globals().delayClear = delayed
    return lua


groups = 0
for superwow in (False, True):
    for delayed in (False, True):
        for entry in ('button', 'alt'):
            lua = world(superwow, delayed)
            if entry == 'button':
                lua.execute("SRTI_ClearButton:Fire('OnClick','LeftButton')")
            else:
                lua.execute("alt=true; this=RaidTargetFrame8Button; Banana_ButtonOnClick('LeftButton'); alt=false")
            lua.execute('''
                assert(table.getn(calls)==9, 'clear must include immediate zero')
                for i=1,8 do
                    assert(calls[i][1]=='player' and calls[i][2]==i)
                    assert(not units['enemy'..i].mark, 'uncleared real marker')
                end
                assert(calls[9][2]==0)
                assertNoHealth()
                -- Both direct player reads and the SuperWoW/party aliases must be suppressed.
                assert(Banana_GetSymbol('player')==0)
                assert(Banana_GetSymbol('party1')==0)
                assert(Banana_GetSymbol('mark8')==0)
                for i=1,10 do
                    tick(); assertNoHealth()
                end
                if pendingClear then units.player.mark=nil; pendingClear=false end
                tick(); assertNoHealth()
                -- A genuine skull target continues to display its changing health normally.
                units.enemy8.mark=8; units.mark8=units.enemy8
                Banana_UpdateStatus()
                assert(SRTI_Health8:IsShown() and SRTI_Health8.value==400)
                units.enemy8.hp=100; tick()
                assert(SRTI_Health8.value==100)
            ''')
            groups += 1

    # A new explicit assignment cancels pending cleanup, so it cannot be erased later.
    lua = world(superwow, True)
    lua.execute('''
        Banana_ClearAllSymbols()
        delayClear=false
        Banana_SetSymbol('player',8)
        Banana_UpdateStatus()
        assert(SRTI_Health8:IsShown() and SRTI_Health8.value==800)
        local count=table.getn(calls)
        for i=1,12 do tick() end
        assert(table.getn(calls)==count and units.player.mark==8)
        assert(SRTI_Health8:IsShown())
    ''')
    groups += 1

print(f'PASS: {groups} clear-all behavior groups (native/SuperWoW, immediate/delayed, button/Alt, explicit reassignment)')
