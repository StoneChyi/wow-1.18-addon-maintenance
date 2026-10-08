from pathlib import Path
import hashlib, json, zipfile

work=Path(__file__).parent
root=Path(r'E:\1.18\Interface\AddOns')
manifest=json.loads((work/'manifest.json').read_text(encoding='utf-8'))
digest=lambda data:hashlib.sha256(data).hexdigest()
with zipfile.ZipFile(work/'PallyPower-before.zip') as backup,zipfile.ZipFile(work/'PallyPower-fixed.zip') as package:
    assert backup.testzip() is None and package.testzip() is None
    for name,hashes in manifest.items():
        assert digest((root/name).read_bytes())==hashes['before'],'Installed source changed: '+name
        assert digest(backup.read(name))==hashes['before'],'Backup mismatch: '+name
        assert digest(package.read(name))==hashes['after'],'Package mismatch: '+name
        assert digest((work/'patched'/name).read_bytes())==hashes['after'],'Staged mismatch: '+name
for name in manifest:
    (root/name).write_bytes((work/'patched'/name).read_bytes())
for name,hashes in manifest.items():
    assert digest((root/name).read_bytes())==hashes['after'],'Installation mismatch: '+name
print('Installed and hash-verified PallyPower-Extensions.lua. Source backup verified; SavedVariables and other addon files unchanged.')
