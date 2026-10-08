from pathlib import Path
import re
root=Path(r'E:/1.18/Interface/AddOns')
titles={}
for addon in ('DPSMateX','DPSMateXExtend','DPSMateXExtendMore'):
    for p in (root/addon).rglob('*Details*.lua'):
        s=p.read_text(encoding='utf-8-sig')
        m=re.search(r'DPSMateX.Modules.(Details\w+) =',s)
        if m:
            frames=sorted(set(re.findall(r'(DPSMateX_\w+_Title):SetText',s)))
            if frames: titles[m[1]]=frames
        if m and m[1]=='DetailsOHealingTaken':
            s=re.sub(r'DPSMateX.CombatTime\["effective"\]\[(key|curKey)\]',r'DPSMateX:GetSelectedEffectiveTime(\1)',s)
            p.write_bytes(s.replace('\n','\r\n').encode('utf-8'))
path=root/'DPSMateXEncounters/Views.lua'
s=path.read_text(encoding='utf-8-sig')
assert 'C.detailTitles=' not in s
block='C.detailTitles={\n'
for module,frames in sorted(titles.items()):
    block+='    '+module+'={'+','.join('"'+name+'"' for name in frames)+'},\n'
block+='}\n\n'
s=s.replace('local totals={',block+'local totals={',1)
path.write_bytes(s.replace('\n','\r\n').encode('utf-8'))
print('Registered original detail title labels; corrected received overhealing time adapter.')
