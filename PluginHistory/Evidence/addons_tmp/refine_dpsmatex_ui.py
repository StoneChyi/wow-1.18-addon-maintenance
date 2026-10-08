from pathlib import Path
import re,shutil,xml.etree.ElementTree as ET
ROOT=Path(r'E:/1.18/Interface/AddOns')
OLD=Path(r'E:/1.18/addons_tmp/dpsmatex-compact-details-backup-20261006')
BACKUP=Path(r'E:/1.18/addons_tmp/dpsmatex-ui-localization-backup-20261006')
NS='http://www.blizzard.com/wow/ui/'
SX=.88;SY=370/270
ET.register_namespace('',NS);ET.register_namespace('xsi','http://www.w3.org/2001/XMLSchema-instance')
def save(p,text):
 dest=BACKUP/p.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():shutil.copy2(p,dest)
 p.write_bytes(text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
def num(x):return format(x,'.6f').rstrip('0').rstrip('.')
def transform(n,body=False,header=False):
 tag=n.tag.split('}')[-1] if isinstance(n.tag,str) else ''
 if tag in ('Size','Offset','AbsDimension'):
  x=n.get('x');y=n.get('y')
  if x:n.set('x',num(float(x)*SX))
  if y and body:n.set('y',num(float(y)*SY))
 for c in n:transform(c,body,header)
 if tag=='Texture':
  size=n.find('{'+NS+'}Size')
  if size is not None and size.get('x') and size.get('y'):
   x=float(size.get('x'));y=float(size.get('y'))
   if abs(x/SX-y/(SY if body else 1))<.001:size.set('y',num(x))
 if body and tag=='FontString' and n.get('inherits')=='GameFontNormalSmall':n.set('inherits','GameFontNormal')

files=[]
for old in OLD.rglob('*Details*.xml'):
 if 'Auras' in old.name:continue
 p=ROOT/old.relative_to(OLD)
 root=ET.parse(p).getroot()
 for e in root:
  if e.get('virtual')=='true':
   for f in e.iter():
    if f.get('name')=='$parent_Name':
     size=f.find('{'+NS+'}Size')
     if size is not None and size.get('x')=='90':size.set('x','150')
   transform(e,True)
  else:
   transform(e,False)
   size=e.find('{'+NS+'}Size')
   if size is not None and size.get('y')=='350':size.set('y','450')
   frames=e.find('{'+NS+'}Frames')
   if frames is not None:
    for panel in frames:
     if panel.tag.split('}')[-1] in ('Frame','ScrollFrame'):
      # X was already transformed; transform only vertical body coordinates.
      for n in panel.iter():
       if isinstance(n.tag,str) and n.tag.split('}')[-1] in ('Size','Offset','AbsDimension') and n.get('y'):
        if n.tag.split('}')[-1]!='Size' and n in list(panel.find('{'+NS+'}Anchors') or []):continue
        n.set('y',num(float(n.get('y'))*SY))
       if isinstance(n.tag,str) and n.tag.endswith('FontString') and n.get('inherits')=='GameFontNormalSmall':n.set('inherits','GameFontNormal')
      # Absolute body anchors start below the original header, not a scaled header.
      anchors=panel.find('{'+NS+'}Anchors')
      if anchors is not None:
       for offset in anchors.iter('{'+NS+'}Offset'):
        if offset.get('y')==num(-65*SY):offset.set('y','-65')
      # Keep square icon textures square after the body height change.
      for n in panel.iter('{'+NS+'}Texture'):
       size=n.find('{'+NS+'}Size')
       if size is not None and size.get('x') and size.get('y'):
        if abs(float(size.get('x'))/SX-float(size.get('y'))/SY)<.001:size.set('y',size.get('x'))
 ET.indent(root,space='\t')
 text=ET.tostring(root,encoding='unicode')
 text=text.replace('FauxScrollFrame_OnVerticalScroll(24,','FauxScrollFrame_OnVerticalScroll(DPSMateX.DetailLayout.listRowHeight,')
 save(p,text+'\n')
 lua=p.with_suffix('.lua');s=lua.read_text(encoding='utf-8-sig')
 s=s.replace('DPSMateX.Options.graph:DrawLine(', 'DPSMateX:DrawDetailTableLine(')
 s=re.sub(r'FauxScrollFrame_Update\(([^\n]*),24\)',r'FauxScrollFrame_Update(\1,DPSMateX.DetailLayout.listRowHeight)',s)
 s=re.sub(r':SetHeight\(([^\n]+)\*30\)',r':SetHeight(\1*DPSMateX.DetailLayout.tableRowHeight)',s)
 s=s.replace('"C: "..total','DPSMateX.L["detailtotal"]..total')
 # The pie should fit the narrower left column without growing new UI objects.
 s=s.replace('0, 0, 200, 200)','0, 0, 176, 176)')
 save(lua,s);files.append(p)
print('Adjusted',len(files),'detail layouts and paired rendering scripts')

p=ROOT/'DPSMateX/DPSMateX_!zhCN/zhCN.lua';s=p.read_text(encoding='utf-8-sig')
s=re.sub(r'^.*DPSMateX_Details_(?:CompareDamage_)?DiagramLegend_Procs_Text:SetText.*\n','',s,flags=re.M)
s=s.replace('{"Buffs", "Debuffs"}','{"增益", "减益"}')
for a,b in {'"Buffs"':'"增益"','"Debuffs"':'"减益"','"Delay"':'"发送延迟"','"Hello World!"':'"检查插件同步"','"倒数"':'"次数"','"Beta测试关闭"':'"战斗时间"','"禁用Beta测试显示"':'"隐藏战斗时间"','"受到Debuff"':'"受到减益"'}.items():s=s.replace(a,b)
s=s.replace('"受到Debuff)."','"受到减益)."')
s=s.replace('DPSMateX.L["dmgdonesum"] = "受到伤害总量"','DPSMateX.L["dmgdonesum"] = "造成伤害总量"')
s=s.replace('DPSMateX.L["dmgtakensum"] = "造成伤害总量"','DPSMateX.L["dmgtakensum"] = "受到伤害总量"')
s=s.replace('DPSMateX.L["name"] =','DPSMateX.L["detailtotal"] = "合计: "\n\tDPSMateX.L["none"] = "无"\n\tDPSMateX.L["name"] =',1)
save(p,s)
for rel in ['DPSMateX/DPSMateX.lua','DPSMateX/DPSMateX_Options.lua','DPSMateXInsights/Core.lua','DPSMateXInsights/Parser.lua','DPSMateXInsights/Details.lua','DPSMateXInsights/HealingDetails.lua','DPSMateXInsights/DPSMateXInsights.toc','DPSMateXEncounters/Merge.lua']:
 p=ROOT/rel;dest=BACKUP/rel;dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():shutil.copy2(p,dest)
