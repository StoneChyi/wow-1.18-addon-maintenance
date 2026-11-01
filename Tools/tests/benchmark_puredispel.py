"""Compare API calls in one fixed mock raid, not FPS or live memory consumption."""
from pathlib import Path
import argparse
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/tests'))
from test_puredispel import CONTRACT, MOCK, LuaRuntime, world

BASELINE = 'ca121f6e'
SETUP = '''
xinDB={maxInRange=6,maxOutRange=3,IgnoreList={},RaidSettings={},PriorityList={},BlackList={}}
raidCount=40
for i=1,40 do
 AddUnit('raid'..i,'Member'..i,'Magic',i<=30 and 10 or 45)
 for j=2,8 do units['raid'..i].auras[j]={name='Aura'..j,kind='Magic'} end
end
'''


def measure(old=False, iterations=100):
    if old:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK, lua.execute(CONTRACT))
        lua.execute(SETUP)
        source = subprocess.check_output(['git', 'show', BASELINE + ':Interface/AddOns/hyx/XinDispel.lua'], cwd=ROOT)
        lua.execute(source.decode('utf-8-sig'))
        lua.execute("FireEvent('VARIABLES_LOADED'); Tick(.3)")
        update = 'UpdateXinList()'
    else:
        lua = world(setup=SETUP)
        update = 'XinDispel.Update(false)'
    lua.execute('''
targetRows=0
for _,o in ipairs(objects) do
 if o.icon and ((o.playerName and o.debuffName) or (o.name and o.aura)) then targetRows=targetRows+1 end
end
ResetCalls()
''')
    lua.execute(f'for i=1,{iterations} do {update} end')
    calls = dict(lua.globals().calls.items())
    result = {'target_row_buttons': lua.globals().targetRows, 'iterations': iterations,
              'api_calls': {key: int(calls.get(key, 0)) for key in
                            ['aura', 'tooltip', 'text', 'texture', 'point', 'show', 'hide', 'distance', 'sight']}}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report')
    args = parser.parse_args()
    old, new = measure(True), measure(False)
    assert old['target_row_buttons'] == 80 and new['target_row_buttons'] == 20
    assert new['api_calls']['tooltip'] < old['api_calls']['tooltip']
    assert new['api_calls']['text'] == 0 and new['api_calls']['texture'] == 0
    result = {'date': '2026-11-02', 'baseline_revision': BASELINE,
              'scenario': '40 friendly units, 8 dispellable Magic auras each; 30 in range, 10 out; 6+3 visible rows; no ignored rules; 100 unchanged scans',
              'baseline_loading': 'Old engine and its two list pools only; old settings UI excluded',
              'new_loading': 'New engine, original raid reference data, new main UI; lazy settings contents unopened',
              'old': old, 'new': new,
              'limits': 'Lua 5.1 API mock; operation counts only. Not a measurement of live CPU, FPS, rendering quality, or client memory. Full-block rules deliberately require extra aura-name checks.'}
    if args.report:
        path = (ROOT / args.report).resolve()
        if not path.is_relative_to((ROOT / 'PluginHistory/Research').resolve()):
            raise ValueError('Report must be under PluginHistory/Research')
        path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
