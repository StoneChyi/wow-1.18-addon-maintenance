import sys, re
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import catpotion_data as data
sys.path.insert(0,str(data.ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
root=data.ROOT/'Interface/AddOns/CatPotion'
runtime=LuaRuntime()
runtime.execute('UIParent={}; SlashCmdList={}; function CreateFrame() return {} end')
runtime.execute((root/'Core.lua').read_text(encoding='utf8'))
addon=runtime.globals().CatPotionAddon
spells,string,_=data.dbc((data.OUT/'patch-P.mpq-Spell.dbc').read_bytes())
displays,ds,_=data.dbc((data.OUT/'patch-9.mpq-ItemDisplayInfo.dbc').read_bytes())
cache=data.cache_items()
new, textures = [],set()
for _,item in addon.Items.items():
    if item.defaultMacroExcluded:
        source=cache[item.itemID]
        assert item.item==source['name'],(item.key,'name')
        assert addon.GetItemTexture(item)=='Interface\\Icons\\'+ds(displays[source['display']][5]),(item.key,'texture')
        spell=spells[source['spells'][0][0]]
        assert item.gcd==spell[158]/1000,(item.key,'GCD')
        assert not item.requiresEquipped and source['inventory']==0,(item.key,'equipment')
        if item.buff: assert item.buff==string(spell[124]),(item.key,'buff')
        textures.add(addon.GetItemTexture(item)+'.blp')
        new.append(item)
unresolved=set(textures)
for path in (data.ROOT/'Data').iterdir():
    if path.suffix.lower()!='.mpq':continue
    archive=data.MPQ(path)
    entries={(h[0],h[1]) for h in archive.hashes if h[4]<len(archive.blocks)}
    for texture in list(unresolved):
        if (data.hashname(texture,1),data.hashname(texture,2)) in entries:unresolved.remove(texture)
    archive.file.close()
    if not unresolved:break
assert not unresolved,unresolved
print('PASS: all',len(new),'new item IDs, localized names, Buff names, GCD values and static icons match client data; all',len(textures),'textures exist in client archives')
original=data.ROOT/'addons_tmp/catpotion-consumables-backup-20261006/Core.lua'
old_keys=re.findall(r'AddItem\("([^"]+)"',original.read_text(encoding='utf-8-sig'))
assert len(addon.Items)==len(old_keys)+59
print('Total:',len(addon.Items),'items; original',len(old_keys),'preserved')
