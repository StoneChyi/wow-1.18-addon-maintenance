from refactor_compact_details import ROOT,BACKUP,save,methods,block_end,TOKEN,NS
import re,xml.etree.ElementTree as ET
p=ROOT/'DPSMateXInsights/Details.lua';s=p.read_text(encoding='utf-8-sig')
start=s.index('    w.healShare=w:CreateTexture');end=s.index('    button(w,"×"',start)
s=s[:start]+s[end:]
start=s.index('    w.raw=button(');end=s.index('    w.refresh=button(',start)
s=s[:start]+s[end:]
start=s.index('    if w.kind=="healing" then\n',s.index('function E:Render(w)'));end=block_end(s,start+4)
depth=0;mid=None
for tok in TOKEN.finditer(s,start+4):
    t=tok.group()
    if t in ('function','if','do','repeat'):depth+=1
    elif t in ('end','until'):depth-=1
    elif t=='else' and depth==1:mid=tok.end();break
body=s[mid:end-3]
body=body.replace('        w.healShare:Hide();w.absorbShare:Hide()\n','')
s=s[:start]+body+s[end:]
s=re.sub(r'^.*if w.kind=="healing" then w.raw:Show\(\) else w.raw:Hide\(\) end\n','',s,flags=re.M)
s=s.replace('        w.summary:SetText','    w.summary:SetText')
save(p,s)
p=ROOT/'DPSMateXEncounters/Merge.lua';s=p.read_text(encoding='utf-8-sig')
s=s.replace('skills={},targets={},bins={},events={}','skills={},targets={},events={}')
save(p,s)
# Short titles must stay inside narrower aura/total windows as well.
ET.register_namespace('',NS);ET.register_namespace('xsi','http://www.w3.org/2001/XMLSchema-instance')
for old in BACKUP.rglob('*Details*.xml'):
    p=ROOT/old.relative_to(BACKUP);root=ET.parse(p).getroot();changed=False
    for frame in list(root):
        size=frame.find('{'+NS+'}Size')
        if size is None or frame.get('virtual')=='true':continue
        width=float(size.get('x',1000))-80
        for f in frame.findall('{'+NS+'}Layers/{'+NS+'}Layer/{'+NS+'}FontString'):
            if not f.get('name','').endswith(('_Title','_SubTitle')):continue
            size=f.find('{'+NS+'}Size')
            if size is not None and float(size.get('x',0))>width:
                size.set('x',str(int(width)));changed=True
    if changed:
        ET.indent(root,space='\t');p.write_bytes(ET.tostring(root,encoding='utf-8').replace(b'\n',b'\r\n')+b'\r\n')
print('Removed unused healing UI from cast/replay windows; bounded title widths')
