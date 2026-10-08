from pathlib import Path
import re, shutil, json
import xml.etree.ElementTree as ET

ROOT=Path(r'E:\1.18\Interface\AddOns')
BACKUP=Path(r'E:\1.18\addons_tmp\dpsmatex-compact-details-backup-20261006')
TOKEN=re.compile(r'--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|\b(?:function|if|do|repeat|end|until|else|elseif)\b',re.S)
def block_end(s,start):
    depth=0
    for m in TOKEN.finditer(s,start):
        t=m.group()
        if t in ('function','if','do','repeat'): depth+=1
        elif t in ('end','until'):
            depth-=1
            if depth==0:return m.end()
    raise ValueError(s[start:start+100])

def methods(s):
    return [(m.start(),block_end(s,m.start()),m.group(1)) for m in re.finditer(r'^function [\w.]+:([\w]+)\(',s,re.M)]

def backup(p):
    dest=BACKUP/p.relative_to(ROOT)
    dest.parent.mkdir(parents=True,exist_ok=True)
    if not dest.exists():shutil.copy2(p,dest)

def save(p,s):
    backup(p)
    p.write_bytes(s.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))

legacy=[p for a in ('DPSMateX','DPSMateXExtend','DPSMateXExtendMore') for p in (ROOT/a).rglob('*Details*.lua') if re.search(r'CreateGraphLine|CreateStackedGraph',p.read_text(encoding='utf-8-sig'))]
REMOVE={'UpdateLineGraph','UpdateStackedGraph','UpdateSumGraph','SortLineTable','GetSummarizedTable','CheckProcs','AddProcPoints','GetAuraGainedArr','ToggleIndividual','AddTotalDataSeries','AddLinesButton','RemoveLinesButton','LoadLegendButtons','CheckButtonCheckAll'}

def strip_graphs(s):
    for start,end,name in reversed(methods(s)):
        if name in REMOVE or name.startswith('ProcsDropDown') or (name=='ToggleMode' and not re.search(r':ToggleMode\(bool\)',s[start:end])):
            s=s[:start]+s[end:]
        elif name=='ToggleMode':
            body=s[start:end]
            opening=re.search(r'\bif bool then',body)
            if opening:
                stop=block_end(body,opening.start())
                depth=0;middle=None
                for tok in TOKEN.finditer(body,opening.start()):
                    t=tok.group()
                    if t in ('function','if','do','repeat'):depth+=1
                    elif t in ('end','until'):depth-=1
                    elif t=='else' and depth==1:middle=tok.end();break
                if middle:
                    body=body[:opening.start()]+'if bool then return end\n'+body[middle:stop-3]+body[stop:]
                    s=s[:start]+body+s[end:]
    # Preserve pie initialization and numeric table setup; remove timeline objects.
    for m in reversed(list(re.finditer(r'\bif not (g\d*) then',s))):
        end=block_end(s,m.start());body=s[m.end():end-3]
        lines=[line for line in body.splitlines() if 'CreateGraphPieChart' in line or ':CreateGraphTable(' in line]
        if not lines:
            s=s[:m.start()]+s[end:]
        elif any('CreateGraphPieChart' in line for line in lines):
            s=s[:m.end()]+'\n'+'\n'.join(lines)+'\n\tend'+s[end:]
        else:
            flag='compactTableInitialized'+m.group(1)
            replacement='if not self.'+flag+' then\n\t\tself.'+flag+' = true\n'+'\n'.join(lines)+'\n\tend'
            s=s[:m.start()]+replacement+s[end:]
    out=[]
    for line in s.splitlines():
        if re.search(r':(?:UpdateLineGraph|UpdateStackedGraph|UpdateSumGraph|LoadLegendButtons)\(',line):continue
        if re.search(r'DiagramLegend_Procs|Compare\w*_Graph|_DiagramLine\b',line):continue
        if re.search(r'(?:["\']_CB["\']|_PlayerList_CB\b)',line):continue
        out.append(line)
    return '\n'.join(out)+'\n'

NS='http://www.blizzard.com/wow/ui/'
ET.register_namespace('',NS)
ET.register_namespace('xsi','http://www.w3.org/2001/XMLSchema-instance')
def tag(n):return n.tag.split('}')[-1] if isinstance(n.tag,str) else ''
def child(n,t):return n.find('{'+NS+'}'+t)
def anchor_to(n,x,y):
    anchors=child(n,'Anchors')
    if anchors is None:anchors=ET.SubElement(n,'{'+NS+'}Anchors')
    anchors.clear()
    a=ET.SubElement(anchors,'{'+NS+'}Anchor',{'point':'TOPLEFT','relativePoint':'TOPLEFT'})
    ET.SubElement(a,'{'+NS+'}Offset',{'x':str(x),'y':str(y)})

def compact_xml(p):
    backup(p)
    root=ET.fromstring(p.read_text(encoding='utf-8-sig'),parser=ET.XMLParser(target=ET.TreeBuilder(insert_comments=True)))
    total='Total' in p.stem
    for parent in list(root.iter()):
        for n in list(parent):
            name=n.get('name','')
            if name.endswith(('_DiagramLine','_DiagramLegend','_SwitchGraph','_Individual','_Graph')) or (total and (name.endswith('_CB') or '_Template_LegendColumn' in name)):
                parent.remove(n)
    for n in root.iter():
        if not isinstance(n.tag,str):continue
        name=n.get('name','')
        size=child(n,'Size')
        if n in list(root) and tag(n)=='Frame' and n.get('virtual')!='true' and size is not None:
            removed_height=200 if 'Auras' in p.stem else 250
            if size.get('y'):size.set('y',str(float(size.get('y'))-removed_height).removesuffix('.0'))
            else:
                dim=child(size,'AbsDimension')
                if dim is not None:dim.set('y',str(float(dim.get('y'))-250).removesuffix('.0'))
        anchors=child(n,'Anchors')
        if anchors is None:continue
        for a in list(anchors):
            rel=a.get('relativeTo','')
            if rel.endswith('_DiagramLine'):
                offset=child(a,'Offset');x=0;y=0
                if offset is not None:
                    dim=child(offset,'AbsDimension')
                    attrs=dim.attrib if dim is not None else offset.attrib
                    x=float(attrs.get('x',0));y=float(attrs.get('y',0))
                anchor_to(n,int(15+x),int(-65+y));break
            if rel.endswith('_DiagramLegend'):
                anchor_to(n,260 if a.get('relativePoint')=='TOPRIGHT' else 15,-65)
                if a.get('relativePoint')!='TOPRIGHT' and size is not None:size.set('y','270')
                break
            if rel.endswith(('_SwitchGraph','_Individual')):
                a.set('relativeTo','$parent_CloseButton')
        if total and name=='$parent_Name':
            for a in anchors:
                offset=child(a,'Offset')
                if offset is not None:offset.set('x','15')
    ET.indent(root,space='\t')
    p.write_bytes(ET.tostring(root,encoding='utf-8').replace(b'\n',b'\r\n')+b'\r\n')

def implement():
    for p in legacy:
        save(p,strip_graphs(p.read_text(encoding='utf-8-sig')))
        compact_xml(p.with_suffix('.xml'))
    db=ROOT/'DPSMateX/DPSMateX_DataBuilder.lua'
    s=db.read_text(encoding='utf-8-sig')
    # These five skill leaves use i exclusively for amount/time plots. Parent i totals remain.
    for start,end,name in reversed(methods(s)):
        if name in {'DamageDone','DamageTaken','EnemyDamage','Healing','HealingTaken'}:
            body=s[start:end]
            body=re.sub(r'^\s*\["i"\] = \{\}\s*\n','\n',body,flags=re.M)
            body=re.sub(r'^\s*time = floor\(DPSMateX.CombatTime\[val\]\)\s*\n\s*path\["i"\]\[time\] = \(path\["i"\]\[time\] or 0\) \+ Damount\s*\n','\n',body,flags=re.M)
            s=s[:start]+body+s[end:]
    save(db,s)
    print('Updated',len(legacy),'Lua/XML detail pairs and amount sampling')

if __name__=='__main__':
    inventory={}
    for p in legacy:
        s=p.read_text(encoding='utf-8-sig')
        inventory[str(p.relative_to(ROOT))]=[n for _,_,n in methods(s)]
    Path('addons_tmp/compact-details-methods.json').write_text(json.dumps(inventory,indent=2),encoding='utf-8')
    print(len(legacy),'detail modules inventoried')
    import sys
    if '--apply' in sys.argv:implement()
