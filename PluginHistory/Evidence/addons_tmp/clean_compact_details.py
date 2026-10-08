from refactor_compact_details import ROOT,BACKUP,save,methods
import re,xml.etree.ElementTree as ET
for old in BACKUP.rglob('*Details*.lua'):
    if not old.with_suffix('.xml').exists():continue
    p=ROOT/old.relative_to(BACKUP);s=p.read_text(encoding='utf-8-sig')
    if 'Total' in p.stem:
        s=re.sub(r'^\s*ColorTable=\{.*?^\s*\}\s*\n','\n',s,flags=re.M|re.S)
        s=re.sub(r'^\s*(?:local )?(?:ColorTable|buttons|totSumTable|totMax|totTime)\s*=.*\n','',s,flags=re.M)
    # Retain only actually used pie handles; timeline handles no longer exist.
    def handles(m):
        vars=re.findall(r'\bg\d*\b',m.group())
        remainder=s[:m.start()]+s[m.end():]
        used=[v for v in vars if re.search(r'\b'+v+r'\b',remainder)]
        return 'local '+', '.join(used)+'\n' if used else ''
    s=re.sub(r'^local g\d*[^\n]*\n',handles,s,flags=re.M)
    s=re.sub(r'^local PieChart = true\n','',s,flags=re.M)
    s=s.replace('local toggle, toggle2, toggle3 = false, false, false','local toggle = false')
    s=re.sub(r'^local toggle2, toggle3 = false, false\n','',s,flags=re.M)
    s=s.replace('compactTableInitializedg','compactTableInitialized')
    s=re.sub(r'\n(?:[ \t]*\n){3,}','\n\n',s)
    save(p,s)
p=ROOT/'DPSMateX/DPSMateX_Sync.lua';s=p.read_text(encoding='utf-8-sig')
for a,b,name in reversed(methods(s)):
    if name in {'DMGDoneAbilityIn','DMGTakenAbilityIn','EDAbilityIn','HealingAbilityIn','HealingTakenAbilityIn'}:
        body=re.sub(r'^\s*\["i"\] = \{\}\s*\n','\n',s[a:b],flags=re.M)
        s=s[:a]+body+s[b:]
save(p,s)
print('Released graph-only color arrays and handles; synced amount skills no longer allocate sample tables')
