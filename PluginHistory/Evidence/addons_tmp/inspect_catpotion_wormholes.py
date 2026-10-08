import sys, json, struct
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import catpotion_data as data
items = data.cache_items()
spells, spell_string, _ = data.dbc((data.OUT / 'patch-P.mpq-Spell.dbc').read_bytes())
displays, display_string, _ = data.dbc((data.OUT / 'patch-9.mpq-ItemDisplayInfo.dbc').read_bytes())
for iid in (51312, 51313):
    item = items.get(iid)
    print(json.dumps(item, ensure_ascii=False))
    if not item:
        continue
    print('icon:', display_string(displays[item['display']][5]))
    for sid, trigger, charges, cooldown, category, category_cd in item['spells']:
        if not sid:
            continue
        spell = spells[sid]
        print('spell:', sid, spell_string(spell[124]), 'cooldown:', cooldown if cooldown >= 0 else spell[19],
              'category:', category if category_cd >= 0 else spell[2],
              'category_cd:', category_cd if category_cd >= 0 else spell[20],
              'gcd:', spell[157:159], 'description:', spell_string(spell[142]))
