"""Save/reload and callback-failure checks through actual native option code.

The UI boundary is simulated. Saved tables are serialized to JSON and restored
into a fresh Lua VM: this checks persistence, not merely setter invocation.
"""
from pathlib import Path
import json
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime, lua_type
from test_pfui_automation_options import MOCK


def runtime(saved=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    install = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute(MOCK, install)
    lua.execute('reported={};DEFAULT_CHAT_FRAME={AddMessage=function(self,text)table.insert(reported,text)end}')
    source = (ROOT / 'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8-sig')
    start = source.index('    function CreateConfig(')
    end = source.index('    local TabFrameOnMouseDown', start)
    lua.execute('local searchDB={}\n' + source[start:end] + '\npfUI.gui.CreateConfig=CreateConfig')
    lua.execute((ROOT / 'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf-8-sig'))
    if saved is not None:
        lua.globals().restored = restore(lua, json.loads(saved))
        lua.execute('Automaton.dbs=restored')
    return lua


def snapshot(value):
    if lua_type(value) == 'table':
        return {'__lua_table__': [[snapshot(key), snapshot(item)] for key, item in value.items()]}
    assert value is None or isinstance(value, (str, bool, int, float)), 'non-saveable data'
    return value


def restore(lua, value):
    if isinstance(value, dict):
        result = lua.table()
        for key, item in value['__lua_table__']:
            result[restore(lua, key)] = restore(lua, item)
        return result
    return value


def pages_runtime(saved=None):
    # Reuse only the existing boundary setup, not its assertions or test data.
    path = ROOT / 'Tools/tests/test_pfui_automation_pages.py'
    source = path.read_text(encoding='utf-8-sig')
    setup = source.split("lua.execute(r'''\nlocal h=pfUI.automation", 1)[0]
    namespace = {'__file__': str(path)}
    exec(compile(setup, str(path), 'exec'), namespace)
    lua = namespace['lua']
    lua.execute(r'''
function moduleRow(moduleName, key)
 local visible=parent.automationOptionsState.visible
 for _,heading in ipairs(visible) do
  if heading.option.moduleName==moduleName then
   local option=heading.option.args[key]
   for _,row in ipairs(visible) do if row.option==option then return row end end
  end
 end
 error('missing module control '..moduleName..':'..key)
end
''')
    # Exercise the actual storage implementation rather than the page fixture's
    # simplified SetRule. Merchant event dispatch is tested separately.
    vendor = (ROOT / 'Interface/AddOns/pfUI/modules/autovendor.lua').read_text(encoding='utf-8-sig')
    start = vendor.index('  local function ItemID(')
    end = vendor.index('  function module:RefreshLegacyEngine()', start)
    lua.execute('local module=pfUI.autovendor\n' + vendor[start:end])
    if saved is not None:
        lua.globals().restored = restore(lua, json.loads(saved))
        lua.execute('C=restored.config;pfUI_config=C;Automaton.db=restored.automaton;values=restored.values')
    return lua


def load_real_modules(lua):
    for name in ('AutoNeed', 'AutoShout'):
        lua.execute((ROOT / f'Interface/AddOns/Automatonex/Modules/{name}.lua').read_text(encoding='utf-8-sig'))
        lua.execute(f'Automaton.modules.{name}:OnInitialize()')
    lua.execute('Automaton.modules.AutoShout.RestartTimer=function()end')


class PersistenceTests(unittest.TestCase):
    def test_three_page_state_survives_fresh_vm_reload(self):
        lua = pages_runtime()
        lua.execute(r'''
local h=pfUI.automation
h:Sync();h:OpenVendor();current(h.merchant)
rowName('自动修理').input:SetChecked(1);click(rowName('自动修理'));tick()
rowName('自动售卖灰色和指定物品').input:SetChecked(1);click(rowName('自动售卖灰色和指定物品'));tick()
rowName('物品 ID').input:SetText('123');click(rowName('加入保留名单'));tick()
rowName('物品 ID').input:SetText('456');click(rowName('加入售卖名单'));tick()
rowName('物品 ID').input:SetText('789');click(rowName('加入保留名单'));tick()
click(rowName('移出保留名单'));tick()
h:SelectModule('Tooltip');h:Open();current(h.all)
assert(rowName('Text Tooltip') and rowName('Text QuestAutomation'))
moduleRow('Tooltip','__pfui_visible').input:SetChecked(nil);click(moduleRow('Tooltip','__pfui_visible'));tick()
assert(not moduleRow('Tooltip','__pfui_visible').input:GetChecked())
assert(moduleRow('QuestAutomation','__pfui_visible').input:GetChecked(),'hiding one group hid another')
rowName('Enabled Tooltip').input:SetChecked(nil);click(rowName('Enabled Tooltip'));tick()
assert(rowName('Enabled QuestAutomation').input:GetChecked(),'toggling one group disabled another')
rowName('Text Tooltip').input:SetText('Saved profile value')
rowName('Text QuestAutomation').input:SetText('Separate quest value')
local ordering=moduleRow('Tooltip','__pfui_order')
ordering.option.buttons[1].func();h:QueueRefresh();tick()
assert(values.Tooltip=='Saved profile value' and values.QuestAutomation=='Separate quest value')
assert(Automaton.db.char.moduleOrder[1]=='Tooltip')
h:OpenPage(h.general);current(h.general)
rowName('在 pfUI 中管理自动化').input:SetChecked(nil);click(rowName('在 pfUI 中管理自动化'));tick()
saved={config=C,automaton=Automaton.db,values=values}
''')
        serialized = json.dumps(snapshot(lua.globals().saved), ensure_ascii=False)
        lua = pages_runtime(serialized)
        lua.execute(r'''
local h=pfUI.automation
h:OpenPage(h.general);current(h.general)
assert(not rowName('在 pfUI 中管理自动化').input:GetChecked())
local db=pfUI.autovendor:GetRules()
assert(db.ignore['123']=='Item 123' and db.custom['456']=='Item 456')
assert(db.ignore['789']==nil and db.edited['789']==true,'deletion tombstone lost')
h:OpenVendor();current(h.merchant)
assert(rowName('自动修理').input:GetChecked() and rowName('自动售卖灰色和指定物品').input:GetChecked())
h:OpenPage(h.general);current(h.general)
rowName('在 pfUI 中管理自动化').input:SetChecked(1);click(rowName('在 pfUI 中管理自动化'));tick()
h:Open();current(h.all)
assert(C.automation.selected=='Tooltip' and Automaton.db.char.lastModule=='Tooltip')
assert(not moduleRow('Tooltip','__pfui_visible').input:GetChecked())
assert(moduleRow('QuestAutomation','__pfui_visible').input:GetChecked())
assert(not rowName('Enabled Tooltip').input:GetChecked())
assert(rowName('Enabled QuestAutomation').input:GetChecked())
assert(rowName('Text Tooltip').input:GetText()=='Saved profile value')
assert(rowName('Text QuestAutomation').input:GetText()=='Separate quest value')
assert(Automaton.db.char.moduleOrder[1]=='Tooltip')
local groups=h:ModuleList(false);assert(groups[1].name=='Tooltip')
pick('显示范围','菜单隐藏')
assert(rowName('Text Tooltip').input:GetText()=='Saved profile value')
for _,row in ipairs(parent.automationOptionsState.visible) do
 assert(row.option.name~='Text QuestAutomation','hidden filter leaked an unrelated group')
 assert(row.option.name~='选择功能','single-module selector returned after reload')
end
''')

    def test_real_module_settings_survive_fresh_vm_reload(self):
        lua = runtime()
        load_real_modules(lua)
        lua.execute(r'''
R=pfUI.automationOptions
local need=Automaton.modules.AutoNeed
R:Render(parent,need)
local count=0
for _,row in ipairs(rows()) do
 if row.widget=='dropdown' then choose(row,'不选择');count=count+1 end
end
assert(count==31)
local shout=Automaton.modules.AutoShout
R:Render(parent,shout)
rowNamed('Message').input:SetText('持久化测试 {item1}')
choose(rowNamed('Channel'),'Guild')
edit(rowNamed('Interval'),'80')
R:Suspend(parent)
assert(shout.db.profile.messages.TestPlayer=='持久化测试 {item1}')
''')
        saved = json.dumps(snapshot(lua.globals().Automaton.dbs), ensure_ascii=False)
        restored = runtime(saved)
        load_real_modules(restored)
        restored.execute(r'''
local R=pfUI.automationOptions
R:Render(parent,Automaton.modules.AutoNeed)
local count=0
for _,row in ipairs(rows()) do
 if row.widget=='dropdown' then
  assert(row.input.text:GetText()=='不选择','selector did not restore saved value');count=count+1
 end
end
assert(count==31)
R:Render(parent,Automaton.modules.AutoShout)
assert(rowNamed('Message').input:GetText()=='持久化测试 {item1}')
assert(rowNamed('Channel').input.text:GetText()=='Guild')
assert(tonumber(rowNamed('Interval').input:GetText())==80)
''')

    def test_failed_text_setter_can_retry_without_reopening(self):
        lua = runtime()
        lua.execute(r'''
local failures=1
local value='old'
local module={_options={edit={type='text',name='Text',get=function()return value end,
 set=function(v)if failures>0 then failures=failures-1;error('setter failed')end;value=v end}}}
pfUI.automationOptions:Render(parent,module)
local row=rowNamed('Text')
row.input:SetText('first')
fire(row.input,'OnEnterPressed')
assert(pfUI.automationOptions.lastError and #reported>0,'original error disappeared')
assert(not row.committing,'failed setter poisoned future commits')
assert(not row.suppressFocus,'failed Enter suppressed future blur saves')
row.input:SetText('retry')
fire(row.input,'OnEnterPressed')
assert(value=='retry')
''')

    def test_suspend_failure_still_cleans_up_detached_menu(self):
        lua = runtime()
        lua.execute(r'''
local module={_options={
 edit={type='text',name='Text',get=function()return 'old' end,set=function()error('cannot save')end},
 pick={type='text',name='Pick',validate={'A','B'},get=function()return 'A'end,set=function()end},
}}
local R=pfUI.automationOptions
R:Render(parent,module)
local menu=rowNamed('Pick').input.menuframe;menu:Show()
rowNamed('Text').input:SetText('draft')
assert(R:Suspend(parent)==false,'failed save reported success')
assert(R.lastError and #reported>0,'save error must remain visible')
assert(not menu:IsShown(),'failed save left a detached menu blocking other pages')
assert(not parent.automationOptionsState.building)
for _,bucket in pairs(parent.automationOptionsState.pool) do
 for _,row in ipairs(bucket) do assert(not row:IsShown()) end
end
R:Render(parent,{_options={normal={type='description',name='Next page'}}})
assert(rowNamed('Next page'):IsShown())
''')

    def test_failed_pending_edit_blocks_dependent_actions_and_can_retry(self):
        lua = runtime()
        lua.execute(r'''
local reject=true
local value='old'
local actions=0
local selected='A'
local enabled=false
local module={_options={
 edit={type='text',name='Text',order=1,get=function()return value end,
 set=function(v)if reject then error('cannot save pending edit')end;value=v end},
 action={type='execute',name='Action',func=function()actions=actions+1 end},
 toggle={type='toggle',name='Toggle',get=function()return enabled end,set=function(v)enabled=v end},
 pick={type='text',name='Pick',validate={'A','B'},get=function()return selected end,set=function(v)selected=v end},
}}
local R=pfUI.automationOptions
R:Render(parent,module)
rowNamed('Text').input:SetText('new')
click(rowNamed('Action'));assert(actions==0 and value=='old')
rowNamed('Toggle').input:SetChecked(1);click(rowNamed('Toggle'));assert(not enabled and not rowNamed('Toggle').input:GetChecked())
choose(rowNamed('Pick'),'B');assert(selected=='A' and rowNamed('Pick').input.text:GetText()=='A')
assert(R.lastError and #reported>0)
reject=false
click(rowNamed('Action'));assert(actions==1 and value=='new')
rowNamed('Toggle').input:SetChecked(1);click(rowNamed('Toggle'));assert(enabled)
choose(rowNamed('Pick'),'B');assert(selected=='B')
''')

    def test_getter_failure_during_edit_does_not_poison_future_saves(self):
        lua = runtime()
        lua.execute(r'''
local fail=false
local value='old'
local module={_options={edit={type='text',name='Text',get=function()
 if fail then error('getter failed') end;return value end,set=function(v)value=v end}}}
local R=pfUI.automationOptions
R:Render(parent,module)
local row=rowNamed('Text');row.input:SetText('new');fail=true
fire(row.input,'OnEnterPressed')
assert(R.lastError and not row.committing and not row.suppressFocus)
fail=false
fire(row.input,'OnEditFocusLost')
assert(value=='new')
''')


    def test_invalid_number_blocks_action_without_discarding_input(self):
        lua = runtime()
        lua.execute(r'''
local value=10;local actions=0;local redraws=0
local module={_options={
 number={type='range',name='Number',min=1,max=100,step=1,get=function()return value end,set=function(v)value=v end},
 action={type='execute',name='Action',func=function()actions=actions+1 end},
}}
local R=pfUI.automationOptions
R:Render(parent,module,function()redraws=redraws+1 end)
local row=rowNamed('Number');row.input:SetText('invalid')
fire(row.input,'OnEnterPressed')
assert(R.lastError and value==10 and redraws==0)
assert(row.input:GetText()=='invalid' and not row.suppressFocus)
click(rowNamed('Action'));assert(actions==0)
row.input:SetText('42');click(rowNamed('Action'))
assert(value==42 and actions==1)
''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
