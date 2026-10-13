"""Reject invalid native player markers before the client can flash them on self."""
import ast
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/SimpleRaidTargetIcons'
tree = ast.parse((ROOT / 'PluginHistory/Evidence/addons_tmp/test_srti_tools.py').read_text(encoding='utf-8-sig'))
MOCK = next(ast.literal_eval(node.value) for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in node.targets))


def world(superwow, group, entry):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    contract = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute('''
        local install = ...
        local methods = getmetatable(UIParent)
        install(methods, CreateFrame)
        for _,obj in ipairs(frameObjects) do
            if obj.kind=='FontString' then obj:SetFontObject('GameFontNormal') end
        end
        function methods:SetFrameLevel() end
        function methods:SetDrawLayer() end
        function methods:GetEffectiveScale() return self:GetScale() end
        local create = CreateFrame
        function CreateFrame(kind, ...) return create(kind=='button' and 'Button' or kind, ...) end
        WorldFrame=CreateFrame('Frame','WorldFrame',UIParent)
        function GetCursorPosition() return 200,400 end
        function UnitIsPlayer(unit) return units[unit] and units[unit].isPlayer end
        function UnitIsUnit(a,b) return units[a] and units[a]==units[b] end
        function IsAltKeyDown() return alt end
        function IsControlKeyDown() return ctrl end
        sounds={}
        function PlaySound(name) table.insert(sounds,name) end
        calls={}; errors={}; flashes=0
        function SetRaidTarget(unit,index,localOnly)
            table.insert(calls,{unit,index,localOnly})
            local entity=units[unit]
            -- Model the reported client-side failure as a dangerous side effect.
            -- Production must reject this request before calling the native function.
            if not entity or (entity.outsider and not localOnly) then
                units.player.mark=index; flashes=flashes+1; return
            end
            entity.mark=index>0 and index or nil
        end
    ''', contract)
    if superwow:
        lua.execute('SetAutoloot=function() end')
    # Match TOC order: radial callbacks run only after Banana's shared guard loads.
    for name in ('IconTextures.lua', 'SimpleRaidTargetIcons.lua', 'Banana.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute('''
        units.player={name='Self',guid='self',hp=800,max=1000,isPlayer=true,mark=3}
        units.outsider={name='Outsider',guid='external-guid',hp=500,max=1000,isPlayer=true,outsider=true}
        units['external-guid']=units.outsider
        units.npc={name='Enemy',guid='npc',hp=500,max=1000}
        units.member={name='Member',guid='member',hp=600,max=1000,isPlayer=true}
        BANANA_CONFIG.DISABLE_ERROR_TEXT=0; errors=messages
        function Banana_PlayError() end
        function Banana_PlaySetSymbol() table.insert(sounds,'assigned') end
        function Banana_PlayRemove1() table.insert(sounds,'removed') end
        function Banana_PlayRemoveAll() end
        -- No UI startup required for click handlers; strict fonts still cover the radial path.
        function Banana_UpdateStatus() end
    ''')
    lua.globals().partyCount = 4 if group == 'party' else 0
    lua.globals().raidCount = 40 if group == 'raid' else 0
    lua.execute("units.party4=units.member; units.raid40=units.member")
    lua.globals().entry = entry
    lua.execute('''
        function click(unit,index,remove)
            units.target=units[unit]
            if entry=='direct' then
                return Banana_SetSymbol(unit,remove and 0 or index)
            elseif entry=='radial' then
                SRTIRadialMenu_Show()
                SRTIRadialMenu.i=index; SRTIRadialMenu.h=nil
                SRTIRadialMenu:Fire('OnClick',remove and 'RightButton' or 'LeftButton')
            elseif entry=='world' then
                SRTIRadialMenu_Show()
                WorldFrame:Fire('OnMouseUp','RightButton')
                time=time+1
            else
                this=getglobal('RaidTargetFrame'..index..'Button')
                ctrl=entry=='ctrl'
                Banana_ButtonOnClick(ctrl and 'LeftButton' or 'RightButton')
                ctrl=false
            end
        end
        function assertSafe()
            assert(table.getn(calls)==0 and flashes==0,'invalid request reached native client')
            assert(units.player.mark==3,'own existing marker changed')
            assert(table.getn(sounds)==0,'failed request played success sound')
        end
    ''')
    return lua


groups = 0
for superwow in (False, True):
    for group in ('solo', 'party', 'raid'):
        for entry in ('direct', 'right', 'ctrl', 'radial'):
            lua = world(superwow, group, entry)
            if superwow:
                lua.execute('''
                    for i=1,8 do
                        units.outsider.mark=nil; calls={}
                        click('external-guid',i,false)
                        assert(table.getn(calls)==1 and calls[1][3]==1)
                        assert(units.outsider.mark==i and units.player.mark==3 and flashes==0)
                    end
                    calls={}; click('outsider',8,true)
                    assert(table.getn(calls)==1 and calls[1][2]==0 and calls[1][3]==1)
                    assert(not units.outsider.mark and units.player.mark==3 and flashes==0)
                    units.outsider.hostile=true; click('outsider',1,false)
                    assert(units.outsider.mark==1 and calls[2][3]==1 and flashes==0)
                ''')
            else:
                lua.execute('''
                    for i=1,8 do click('external-guid',i,false); assertSafe() end
                    units.outsider.mark=8
                    click('outsider',8,true); assertSafe()
                    assert(table.getn(errors)==9, entry..':'..GetNumPartyMembers()..':'..GetNumRaidMembers()..':'..table.getn(errors))
                    units.outsider.hostile=true
                    click('outsider',1,false); assertSafe()
                ''')
            groups += 1
            # Missing target, NPC, self and group member are separate cases.
            if entry in ('direct', 'radial'):
                lua.execute("calls={}; sounds={}; click('missing',8,false); assertSafe()")
                groups += 1
            lua.execute("calls={}; click('npc',8,false); assert(table.getn(calls)==1 and units.npc.mark==8 and flashes==0)")
            lua.execute("calls={}; click('player',7,false); assert(table.getn(calls)==1 and units.player.mark==7 and flashes==0)")
            if group != 'solo':
                lua.execute("calls={}; click('member',5,false); assert(table.getn(calls)==1 and units.member.mark==5 and flashes==0)")
            groups += 1

# Outside-circle right click uses a second radial removal path.
for superwow in (False, True):
    lua = world(superwow, 'party', 'world')
    if superwow:
        lua.execute("units.outsider.mark=8; click('outsider',8,true); assert(table.getn(calls)==1 and calls[1][2]==0 and calls[1][3]==1 and not units.outsider.mark and units.player.mark==3 and flashes==0)")
    else:
        lua.execute("units.outsider.mark=8; click('outsider',8,true); assertSafe()")
    groups += 1

# Local marking of outsiders stays available to ordinary party/raid members.
for group in ('party', 'raid'):
    lua = world(True, group, 'radial')
    lua.execute('''
        partyLeader=false; raidLeader=false; raidOfficer=false
        click('outsider',8,false)
        assert(SRTIRadialMenu:IsShown() and calls[1][3]==1 and units.outsider.mark==8)
        assert(units.player.mark==3 and flashes==0)
        units.target=units.npc; SRTIRadialMenu_Show()
        assert(not SRTIRadialMenu:IsShown(),'server-mark permissions bypassed')
    ''')
    groups += 1

print(f'PASS: {groups} marker-target behavior groups; native/SuperWoW, solo/party/raid, bar/radial clicks, outsider/GUID local marking or native rejection, valid targets and strict fonts')
