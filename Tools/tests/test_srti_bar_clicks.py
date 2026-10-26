"""WoW 1.12 bar clicks: preserve targets and disambiguate single/double clicks."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/SimpleRaidTargetIcons'
fixture = ROOT / 'PluginHistory/Evidence/addons_tmp/test_srti_tools.py'
tree = ast.parse(fixture.read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value) for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in node.targets))


def world(superwow=True, failed_font=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    contract = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute('''
        local install = ...
        local methods=getmetatable(UIParent)
        install(methods,CreateFrame)
        for _,obj in ipairs(frameObjects) do
            if obj.kind=='FontString' then obj:SetFontObject('GameFontNormal') end
        end
        local createFont=methods.CreateFontString
        function methods:CreateFontString(name,layer,template)
            return createFont(self,name,layer,template=='GameFontNormalSmall' and 'GameFontNormal' or template)
        end
        local create=CreateFrame
        function CreateFrame(kind,name,parent,template)
            local obj=create(kind,name,parent,template)
            if template=='OptionsCheckButtonTemplate' then getglobal(name..'Text'):SetFontObject('GameFontNormal') end
            return obj
        end
        function methods:RegisterEvent(name) self.events=self.events or {}; self.events[name]=true end
        function methods:UnregisterEvent(name) if self.events then self.events[name]=nil end end
        function methods:GetNumChildren() return 0 end
        function methods:GetChildren() end
        WorldFrame=CreateFrame('Frame','WorldFrame',UIParent)
        function UnitIsPlayer(unit) return units[unit] and units[unit].isPlayer end
        function UnitIsUnit(a,b) return units[a] and units[a]==units[b] end
        function IsAltKeyDown() return alt end
        function IsControlKeyDown() return ctrl end
        nearestCalls=0; selects={}; calls={}
        function TargetNearestEnemy()
            nearestCalls=nearestCalls+1; units.target=units.nearest
        end
        function TargetUnit(unit)
            table.insert(selects,unit); units.target=units[unit]
            if SRTI_BarClick and SRTI_BarClick.events and SRTI_BarClick.events.PLAYER_TARGET_CHANGED then
                SRTI_BarClick:Fire('OnEvent')
            end
        end
        function SetRaidTarget(unit,index,localOnly)
            assert(units[unit],'invalid target')
            table.insert(calls,{unit,index,localOnly,units[unit]})
            units[unit].mark=index>0 and index or nil
        end
        function advance(seconds)
            time=time+seconds
            if SRTI_BarClick then SRTI_BarClick:Fire('OnUpdate') end
        end
        function click(index,button)
            this=getglobal('RaidTargetFrame'..index..'Button')
            Banana_ButtonOnClick(button or 'LeftButton')
        end
        function double(index)
            click(index); advance(.1); click(index)
        end
        function idle()
            assert(not SRTI_BarClick:GetScript('OnUpdate'),'click timer left running')
            assert(not SRTI_BarClick.events.PLAYER_TARGET_CHANGED,'click event left registered')
        end
    ''', contract)
    if superwow:
        lua.execute('SetAutoloot=function() end')
    if failed_font:
        lua.execute("failedFontPaths[STANDARD_TEXT_FONT]=true")
    for name in ('IconTextures.lua', 'Banana.lua', 'RaidTools.lua', 'Localization.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute('''
        BANANA_CONFIG.SHOW_EXTRA_INFO=0; BANANA_CONFIG.BUTTON_LAYOUT=1
        event='ADDON_LOADED'; arg1='SimpleRaidTargetIcons'; this=BananaFrame; Banana_OnEvent()
        units.player={name='Self',guid='self',hp=800,max=1000,isPlayer=true}
        units.original={name='Original',guid='original',hp=600,max=1000}
        units.marked={name='Marked',guid='marked',hp=400,max=1000,mark=8}
        units.nearest={name='Nearest',guid='nearest',hp=700,max=1000}
        units.target=units.original
        BANANA_CONFIG.DISABLE_ERROR_TEXT=0
    ''')
    return lua


groups = 0
for superwow in (False, True):
    for failed_font in (False, True):
        # A missing icon must neither walk nearby enemies nor change an existing target.
        lua = world(superwow, failed_font)
        lua.execute('''
            click(8); assert(units.target==units.original)
            advance(.31)
            assert(nearestCalls==0 and units.target==units.original,'missing marker stole target')
            assert(table.getn(selects)==0 and table.getn(calls)==0); idle()
            units.target=nil; click(8); advance(.31)
            assert(units.target==nil and nearestCalls==0); idle()
        ''')
        groups += 1

        # Each of the eight icons toggles the original target once per pair, not per click.
        for index in range(1, 9):
            lua = world(superwow, failed_font)
            lua.execute(f'''
                units.marked.mark={index}; units['mark'..{index}]=units.marked
                units.party1target=units.marked; partyCount=1
                double({index})
                assert(table.getn(calls)==1 and calls[1][2]=={index} and calls[1][4]==units.original)
                assert(units.target==units.original and nearestCalls==0 and table.getn(selects)==0)
                advance(.4); idle()
                double({index})
                assert(table.getn(calls)==2 and calls[2][2]==0 and not units.original.mark)
                advance(.4); idle()
            ''')
            groups += 1

        # Reverse targeting still works through the extension and native party-target route.
        lua = world(superwow, failed_font)
        lua.execute('''
            units.mark8=units.marked; units.party1=units.player; units.party1target=units.marked
            click(8); advance(.1); assert(units.target==units.original)
            advance(.21); assert(units.target==units.marked and table.getn(calls)==0)
            assert(nearestCalls==0); idle()
        ''')
        groups += 1

        # No target means no toggle and no implicit auto-selection, including quick actions.
        lua = world(superwow, failed_font)
        lua.execute('''
            units.target=nil; double(8); advance(.4); idle()
            click(8,'RightButton'); ctrl=true; click(8); ctrl=false
            assert(not units.target and nearestCalls==0 and table.getn(calls)==0)
        ''')
        groups += 1

        # A real target change between clicks cancels the pair, including clients without GUIDs.
        lua = world(superwow, failed_font)
        lua.execute('''
            click(8); TargetUnit('nearest'); advance(.1); click(8); advance(.31)
            assert(table.getn(calls)==0 and units.target==units.nearest); idle()
            click(8); advance(.1)
            units.target=units.original -- Also guard GUID changes if the event was missed.
            click(8); advance(.31)
            assert(table.getn(calls)==0 and units.target==units.original); idle()
        ''')
        groups += 1

# Only same-icon pairs count; rapid icon changes, slow pairs and triple clicks stay bounded.
lua = world()
lua.execute('''
    click(8); advance(.1); click(7); advance(.31)
    assert(table.getn(calls)==0 and units.target==units.original); idle()
    click(8); advance(.31); click(8); advance(.31)
    assert(table.getn(calls)==0); idle()
    double(8); click(8); advance(.31)
    assert(table.getn(calls)==1 and units.original.mark==8); idle()
''')
groups += 1

# Other actions must cancel the queued single click; no later timer steals target.
for action in ('right', 'ctrl', 'clear', 'disable', 'drag'):
    lua = world()
    lua.execute("units.mark8=units.marked; click(8)")
    if action == 'right':
        lua.execute("click(7,'RightButton')")
    elif action == 'ctrl':
        lua.execute('ctrl=true; click(7); ctrl=false')
    elif action == 'clear':
        lua.execute('Banana_ClearAllSymbols()')
    elif action == 'disable':
        lua.execute('Banana_SetEnabled(false)')
    else:
        lua.execute("ctrl=true; this=RaidTargetFrame8Button; Banana_ButtonOnMouseDown('RightButton'); ctrl=false; Banana_ButtonOnMouseUp()")
    lua.execute('advance(.5); assert(units.target==units.original); idle()')
    groups += 1

# Native clients still identify target changes through the actual target-change event.
lua = world(False)
lua.execute('''
    units.original.guid=nil; units.nearest.guid=nil
    click(8); TargetUnit('nearest'); advance(.1); click(8); advance(.31)
    assert(table.getn(calls)==0 and units.target==units.nearest); idle()
''')
groups += 1

# Missing target events still cannot revive an old single click when GUIDs are available.
lua = world()
lua.execute('''
    units.mark8=units.marked; click(8); units.target=units.nearest; advance(.31)
    assert(units.target==units.nearest and table.getn(calls)==0); idle()
    click(8); units.target=nil; advance(.31)
    assert(units.target==nil); idle()
''')
groups += 1

# The hunter icon is a spell action, not a native marker-removal request.
lua = world()
lua.execute('''
    BOOKTYPE_SPELL='spell'; casts=0
    units.original.debuff='Interface\\\\Icons\\\\Ability_Hunter_SniperShot'
    function GetSpellTexture(index) if index==1 then return units.original.debuff end end
    function GetSpellName() return 'Hunter Mark' end
    function CastSpellByName() casts=casts+1 end
    double(9); advance(.4)
    assert(casts==1 and table.getn(calls)==0 and units.target==units.original); idle()
''')
groups += 1

print(f'PASS: {groups} bar-click groups; no nearest-target mutation, eight icon toggles, single/double timing, cancellation, native/SuperWoW and strict font fallback')
