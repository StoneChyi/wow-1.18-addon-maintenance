from pathlib import Path
from datetime import datetime, timezone, timedelta
import argparse, collections, csv, difflib, hashlib, json, re, shutil, sys, zipfile

ROOT = Path('E:/1.18')
SRC = ROOT / 'Interface/AddOns'
OLD = Path('C:/Users/Administrator/Documents/Codex/2026-10-05/nik')
WORK = OLD / 'work'
OUT = OLD / 'outputs'
REPORT = ROOT / 'CodexReports/20261006'
TZ = timezone(timedelta(hours=8))
ADDONS = ['Cat','PallyPower','YGB_OTAlarm','STSMmayor','BetterCharacterStats','StatCompare','S_ItemTip','pfUI-addonskinner','PlayerLinkEnhance','ActionBarProfiles','BrainwasherPro','DPSMateX','DPSMateXExtend','DPSMateXExtendMore','DPSMateXInsights','DPSMateXEncounters','TianYan','Outfitter']
NEW_ADDONS = {'DPSMateXInsights','DPSMateXEncounters'}
TEXT_EXT = {'.lua','.xml','.toc','.md','.txt','.ini','.json','.patch','.diff','.py'}

def sha(data): return hashlib.sha256(data).hexdigest()
def save(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')
def savej(path, data): save(path,json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def decode(data):
    for enc in ['utf-8-sig','gb18030','cp1252']:
        try: return data.decode(enc).replace('\r\n','\n').replace('\r','\n'),enc
        except UnicodeDecodeError: pass
    raise ValueError('Unable to decode text without data loss')
def stable_copy(src,dst):
    dst.parent.mkdir(parents=True,exist_ok=True)
    before=src.read_bytes(); stamp=src.stat()
    shutil.copy2(src,dst)
    copied=dst.read_bytes(); after=src.read_bytes()
    if sha(before)!=sha(copied) or sha(before)!=sha(after):
        raise RuntimeError(f'Source changed during backup or copy failed: {src}')
    return {'bytes':len(copied),'sha256':sha(copied),'modifiedShanghai':datetime.fromtimestamp(stamp.st_mtime,TZ).isoformat()}

def map_rel(rel, addon=None):
    rel=rel.replace('\\','/')
    if rel.startswith('Interface/AddOns/'): rel=rel[len('Interface/AddOns/'):]
    if rel.split('/')[0] in ADDONS: return rel
    if addon: return addon+'/'+rel
    return None

def symbols(lines):
    found=[]
    for i,line in enumerate(lines,1):
        m=re.match(r'\s*(?:local\s+)?function\s+([\w.:]+)\s*\(',line)
        if not m: m=re.match(r'\s*(?:local\s+)?([\w.:]+)\s*=\s*function\s*\(',line)
        if m: found.append((i,m.group(1)))
    return found

def snapshot(dest):
    if dest.exists(): raise RuntimeError('Backup directory already exists; refuse to overwrite')
    dest.mkdir(parents=True)
    entries=[]; addon_stats=[]
    print('Copying complete latest addon directories...',flush=True)
    for addon in ADDONS:
        files=sorted(p for p in (SRC/addon).rglob('*') if p.is_file())
        if not files: raise RuntimeError('Missing addon: '+addon)
        total=0
        for p in files:
            rel=p.relative_to(SRC).as_posix()
            item=stable_copy(p,dest/'Latest/Interface/AddOns'/rel)
            entries.append({'path':'Latest/Interface/AddOns/'+rel,'source':str(p),'addon':addon,**item}); total+=item['bytes']
        toc=[]
        for p in (dest/'Latest/Interface/AddOns'/addon).glob('*.toc'):
            text,_=decode(p.read_bytes())
            toc.extend(line for line in text.splitlines() if re.match(r'##\s*(Version|Dependencies|RequiredDeps|OptionalDeps|SavedVariables|SavedVariablesPerCharacter):',line,re.I))
        addon_stats.append({'addon':addon,'files':len(files),'bytes':total,'tocMetadata':toc})
    print('Copying related persisted settings and macros...',flush=True)
    settings=[]
    names={p.stem.lower() for addon in ADDONS for p in (SRC/addon).glob('*.toc')}|{x.lower() for x in ADDONS}
    for p in sorted((ROOT/'WTF').rglob('*')):
        if not p.is_file(): continue
        n=p.name.lower()
        sv=p.parent.name.lower()=='savedvariables' and any(n in {a+'.lua',a+'.lua.bak',a+'.bak'} for a in names)
        supporting=n in {'bindings-cache.wtf','bindings-cache.old','macros-cache.txt','macros-cache.old','addons.txt'}
        if not (sv or supporting): continue
        rel=p.relative_to(ROOT).as_posix()
        item=stable_copy(p,dest/'Settings'/rel)
        settings.append({'path':'Settings/'+rel,'source':str(p),'kind':'SavedVariables' if sv else 'bindings_macros_enablement',**item})
    savej(dest/'Manifest/latest-files.json',entries)
    savej(dest/'Manifest/settings-files.json',settings)
    savej(dest/'Manifest/addons.json',addon_stats)
    return entries,settings,addon_stats

def build_baselines(dest):
    candidates=collections.defaultdict(list)
    absent={}
    def candidate(rel,data,origin,label,rank,kind='before_snapshot'):
        if not rel or rel.split('/')[0] not in ADDONS: return
        if rel in absent: return
        candidates[rel].append({'data':data,'origin':origin,'label':label,'rank':rank,'kind':kind})
    def tree(path,label,rank,addon=None,kind='before_snapshot'):
        if not path.exists(): raise RuntimeError('Required baseline not found: '+str(path))
        for p in sorted(path.rglob('*')):
            if p.is_file() and p.suffix.lower() in TEXT_EXT:
                candidate(map_rel(p.relative_to(path).as_posix(),addon),p.read_bytes(),str(p),label,rank,kind)
    def single(path,rel,label,rank,kind='before_snapshot'):
        if not path.exists(): raise RuntimeError('Required baseline missing: '+str(path))
        candidate(rel,path.read_bytes(),str(path),label,rank,kind)
    # Chronology is curated from manifests and preparation scripts; file mtimes are not used as baseline priority.
    tree(WORK/'cat-ret-tests/original','10-05 惩戒第五档首次修改前',10,'Cat')
    tree(WORK/'cat-settings-audit/original','10-05 设置读取修复前',20,'Cat')
    tree(WORK/'cat-seal-icons/original','10-06 审判图标与皮肤首次修复前',10)
    tree(WORK/'cat-paladin-controls/original','10-06 骑士控制扩展前',30)
    tree(WORK/'pallypower-targets/original','10-06 团队目标筛选修复前',10)
    tree(WORK/'pallypower-extension/original','10-06 团队功能扩展前',20)
    # Zero-byte originals here are sentinels for files absent before the extension.
    absent['PallyPower/PallyPower-Extensions.lua']='pallypower-extension/manifest.json: before=null；新增文件'
    candidates.pop('PallyPower/PallyPower-Extensions.lua',None)
    single(WORK/'stsm-ui/STSMmayor.lua.original','STSMmayor/STSMmayor.lua','10-06 首次 UI 修改前',10)
    single(WORK/'stsm-ui/STSMmayor.toc.original','STSMmayor/STSMmayor.toc','10-06 首次 UI 修改前',10)
    tree(WORK/'tianyan-average/original','10-05 加入战斗均值前',10,'TianYan')
    single(WORK/'outfitter-popup-analysis/QuickSwap.original.lua','Outfitter/QuickSwap.lua','10-05 悬停修复前',10)
    tree(WORK/'ygb-pfui/original','10-06 YGB 首次界面与逻辑修复前',10)
    absent['YGB_OTAlarm/UI.lua']='ygb-pfui/manifest.json: before=null；新增兼容文件'
    tree(ROOT/'addons_tmp/unit-menu-backup-20261006/PlayerLinkEnhance','10-06 头像菜单首次改动前',10,'PlayerLinkEnhance')
    absent['PlayerLinkEnhance/SaferMenu.lua']='菜单优化阶段新增，最终为兼容占位文件；功能已合并主文件'
    tree(ROOT/'addons_tmp/talent-panel-actionbar-backup-20261006-091747','10-06 天赋动作条联动前',30)
    single(ROOT/'addons_tmp/bcs-float-backup-20261006/BCS_PropertiesPanel.lua.original','BetterCharacterStats/BCS_PropertiesPanel.lua','10-06 浮动属性扩展首次修改前',10)
    for name in ['helper.lua','BetterCharacterStats.lua']:
        single(ROOT/'addons_tmp/character-bcs-scan-backup-20261006'/('BetterCharacterStats_'+name+'.original'),'BetterCharacterStats/'+name,'10-06 BCS 同次刷新扫描复用前',10)
    layout_map={
        'Interface_AddOns_pfUI-addonskinner_skins_StatCompare.lua.original':'pfUI-addonskinner/skins/StatCompare.lua',
        'Interface_AddOns_S_ItemTip_InspectFrame.lua.original':'S_ItemTip/InspectFrame.lua',
        'Interface_AddOns_S_ItemTip_InspectGemAndEnchant.lua.original':'S_ItemTip/InspectGemAndEnchant.lua',
        'Interface_AddOns_StatCompare_SCOptions.lua.original':'StatCompare/SCOptions.lua',
        'Interface_AddOns_StatCompare_StatCompare.lua.original':'StatCompare/StatCompare.lua',
        'Interface_AddOns_StatCompare_StatCompare.toc.original':'StatCompare/StatCompare.toc',
        'Interface_AddOns_StatCompare_StatCompare.xml.original':'StatCompare/StatCompare.xml'}
    for f,rel in layout_map.items(): single(ROOT/'addons_tmp/inspect-layout-backup-20261006'/f,rel,'10-06 统一观察布局首次修改前',10)
    absent['StatCompare/PanelLayout.lua']='统一布局阶段新增，最终为兼容占位文件；布局已并入主文件'
    for addon,name in [('S_ItemTip','ItemSocre.lua'),('StatCompare','StatScanner.lua')]:
        single(ROOT/'addons_tmp/character-open-backup-20261006'/(addon+'_'+name+'.original'),addon+'/'+name,'10-06 首轮角色窗口打开优化前',10)
    # Core and options snapshots were made after the lock-window fix; explicitly label this coverage boundary.
    for name in ['DPSMateX.lua','DPSMateX_Options.lua','DPSMateX_DataBuilder.lua']:
        label='10-06 Insights 接入前'
        kind='before_snapshot'
        if name!='DPSMateX_DataBuilder.lua': label+='（已包含较早的锁窗修复）'; kind='partial_baseline_after_lock_fix'
        single(ROOT/'addons_tmp/dpsmatex-insights-backup-20261006'/name,'DPSMateX/'+name,label,10,kind)
    tree(ROOT/'addons_tmp/dpsmatex-encounters-backup-20261006','10-06 Boss/小怪汇总接入前',30)
    for addon in NEW_ADDONS:
        for p in (dest/'Latest/Interface/AddOns'/addon).rglob('*'):
            if p.is_file():
                rel=p.relative_to(dest/'Latest/Interface/AddOns').as_posix()
                absent[rel]='10-06 新增独立模块，整文件均为新增代码'
                candidates.pop(rel,None)
    selected={}; audit=[]
    for rel,opts in sorted(candidates.items()):
        if rel in absent: continue
        opts.sort(key=lambda x:x['rank'])
        c=opts[0]; path=dest/'Baseline/Interface/AddOns'/rel; path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(c['data'])
        selected[rel]={k:v for k,v in c.items() if k!='data'}|{'sha256':sha(c['data']),'path':'Baseline/Interface/AddOns/'+rel}
        for opt in opts:
            audit.append({'file':rel,'origin':opt['origin'],'label':opt['label'],'sha256':sha(opt['data']),'selected':opt is c})
    savej(dest/'Manifest/baselines.json',{'selected':selected,'absentBefore':absent,'candidates':audit,'note':'Per-file earliest verified available stage, not an entire pristine upstream release. Core/options DPSMateX baseline is after lock fix.'})
    return selected,absent

def make_diffs(dest,selected,absent):
    current=dest/'Latest/Interface/AddOns'; changes=[]; combined=[]; per_addon=collections.defaultdict(list); unchanged=[]
    for rel in sorted(set(selected)|set(absent)):
        p=current/rel
        if not p.exists(): continue
        new=p.read_bytes()
        old=(dest/selected[rel]['path']).read_bytes() if rel in selected else b''
        if old==new:
            unchanged.append(rel); continue
        if p.suffix.lower() not in TEXT_EXT: raise RuntimeError('Unexpected non-text changed file: '+rel)
        before,enc_old=decode(old); after,enc_new=decode(new)
        a=before.splitlines(keepends=True); b=after.splitlines(keepends=True)
        # Unified diffs use normalized LF, preserve all source bytes separately in Latest and Baseline.
        aa=[x if x.endswith('\n') else x+'\n' for x in a]; bb=[x if x.endswith('\n') else x+'\n' for x in b]
        patch=''.join(difflib.unified_diff(aa,bb,fromfile='/dev/null' if rel in absent else 'a/'+rel,tofile='b/'+rel,n=5))
        patchpath='Patches/files/'+rel+'.patch'; save(dest/patchpath,patch)
        combined.append(patch); per_addon[rel.split('/')[0]].append(patch)
        functions=symbols(after.splitlines()); oldfunc=symbols(before.splitlines())
        opcodes=difflib.SequenceMatcher(None,before.splitlines(),after.splitlines(),autojunk=False).get_opcodes()
        regions=[]
        for tag,i,j,k,l in opcodes:
            if tag=='equal': continue
            prior=[s for s in functions if s[0]<=k+1]
            oldprior=[s for s in oldfunc if s[0]<=i+1]
            regions.append({'type':tag,'beforeStart':i+1,'beforeCount':j-i,'latestStart':k+1,'latestCount':l-k,'nearLatestDeclaration':prior[-1] if prior else None,'nearBeforeDeclaration':oldprior[-1] if oldprior else None})
        format_only=before==after
        item={'file':rel,'status':'format_only' if format_only else ('added' if rel in absent else 'modified'),'baselineLabel':absent[rel] if rel in absent else selected[rel]['label'],'baselineKind':'absent_before' if rel in absent else selected[rel]['kind'],'baselineSource':None if rel in absent else selected[rel]['origin'],'beforeSHA256':sha(old),'latestSHA256':sha(new),'latestLines':len(after.splitlines()),'addedLines':sum(r['latestCount'] for r in regions),'removedLines':sum(r['beforeCount'] for r in regions),'oldEncoding':enc_old,'latestEncoding':enc_new,'beforeBOM':old.startswith(b'\xef\xbb\xbf'),'latestBOM':new.startswith(b'\xef\xbb\xbf'),'beforeCRLF':old.count(b'\r\n'),'latestCRLF':new.count(b'\r\n'),'patch':patchpath,'regions':regions,'declaredFunctions':[{'line':l,'name':n} for l,n in functions]}
        changes.append(item)
        docpath='Docs/Files/'+rel+'.md'
        md=[f'# {rel}', '',f"类型：{item['status']}；新增 {item['addedLines']} 行，删除 {item['removedLines']} 行。",'',f"基线：{item['baselineLabel']}",f"基线来源：{item['baselineSource'] or '新增文件，无旧文件'}",'',f"当前 SHA-256：`{item['latestSHA256']}`",'', '所有行号均对应备份内 Latest 文件。函数名是变更块前最近的声明，仅用于搜索定位，不是 Lua 语法作用域分析。', '', '## 变更位置', '', '| 旧文件起始/行数 | 当前起始/行数 | 类型 | 当前邻近声明 |', '|---|---|---|---|']
        for r in regions:
            s=r['nearLatestDeclaration']; anchor=f'{s[1]}（第{s[0]}行）' if s else '文件顶部 / 表定义'
            md.append(f"| {r['beforeStart']} / {r['beforeCount']} | {r['latestStart']} / {r['latestCount']} | {r['type']} | `{anchor}` |")
        if rel.endswith('.toc'):
            md+=['','## 当前加载与保存声明','','```text',after.rstrip(),'```']
        if format_only:
            md+=['','## 格式差异','','正文一致，仅编码、BOM、换行或尾部字节差异，无功能改动需要迁移。原始字节均保存在 Baseline 与 Latest。',f"旧/新 UTF-8 BOM：{item['beforeBOM']} / {item['latestBOM']}；CRLF 数量：{item['beforeCRLF']} / {item['latestCRLF']}。"]
        md+=['','## 完整代码差异','','`-` 为基线删除行，`+` 为当前新增行；上下文前缀为空格。新增文件展示整文件。','','```diff',patch.rstrip(),'```','']
        save(dest/docpath,'\n'.join(md))
        item['details']=docpath
    save(dest/'Patches/all-changes.patch',''.join(combined))
    for addon,parts in per_addon.items(): save(dest/f'Patches/addons/{addon}.patch',''.join(parts))
    savej(dest/'Manifest/code-changes.json',{'files':changes,'unchangedAgainstSelectedBaseline':unchanged})
    rows=['# 详细代码修改索引','','按首次可确认的修改前快照与当前完整文件比较；基线限制见“适配指南”。补丁用于审查和迁移，不保证适用于任意新版。','','| 插件/文件 | 类型 | 增加/删除 | 基线范围 | 完整代码差异 |','|---|---|---|---|---|']
    for c in changes:
        rel=c['file']; rows.append(f"| `{rel}` | {c['status']} | +{c['addedLines']} / -{c['removedLines']} | {c['baselineLabel']} | [查看](Files/{rel}.md) |")
    rows+=['','## 已恢复成基线的文件','','以下文件在某轮修改中动过，但当前字节已与所选修改前快照一致，不应把撤销的改动再迁移：','']+['- `'+r+'`' for r in unchanged]
    rows+=['','## 锁窗修复的历史差异缺口','','DPSMateX.lua 与 DPSMateX_Options.lua 最早可找到的快照已包含锁窗修复。因此这些文件的补丁覆盖后续扩展接入，但不包含较早锁窗修复的旧/新对照。[当前修复完整片段](DPSMateX锁窗修复当前代码.md)另附，不能伪造缺失的旧版本。','']
    save(dest/'Docs/详细代码修改索引.md','\n'.join(rows))
    return changes,unchanged

def copy_evidence(dest):
    # Preserve text scripts, tests, manifests and old patch archives, excluding dependency binaries/caches.
    sources=[(WORK,'previous-work'),(OUT,'previous-outputs'),(ROOT/'addons_tmp','addons-tmp'),(ROOT/'CatBackups','cat-backups'),(ROOT/'CodexBackups/PallyPower-team-position-20261006','pallypower-team-position')]
    count=0
    for root,prefix in sources:
        for p in sorted(root.rglob('*')):
            if not p.is_file(): continue
            rel=p.relative_to(root)
            if any(x in {'deps','bcs-test-runtime','__pycache__'} for x in rel.parts): continue
            if p.suffix.lower() not in TEXT_EXT|{'.zip','.original','.before'}: continue
            stable_copy(p,dest/'Evidence'/prefix/rel); count+=1
    for name in ['backup-history-input.json','插件修改清单与更新策略.md','今日文件校验清单.json']:
        stable_copy(REPORT/name,dest/'Evidence/current-audit'/name)
    records=json.loads((REPORT/'backup-history-input.json').read_text(encoding='utf-8'))['records']
    text=['# 相关变更记录','','这是辅助追溯记录；包含“只分析未修改”的对话，实际应以基线、当前文件和代码差异为准。','']
    for r in records:
        text += ['## '+r['date'],'']+['\n\n'.join(r['final']), '']
    save(dest/'Docs/变更记录.md','\n'.join(text))
    return count

def finish(dest):
    latest=json.loads((dest/'Manifest/latest-files.json').read_text(encoding='utf-8'))
    settings=json.loads((dest/'Manifest/settings-files.json').read_text(encoding='utf-8'))
    for item in latest+settings:
        if sha((dest/item['path']).read_bytes())!=item['sha256']: raise RuntimeError('Backup checksum mismatch '+item['path'])
        if sha(Path(item['source']).read_bytes())!=item['sha256']: raise RuntimeError('Source has changed after backup '+item['source'])
    archive=dest.parent/(dest.name+'.zip')
    files=sorted(p for p in dest.rglob('*') if p.is_file())
    package=[{'path':p.relative_to(dest).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p.read_bytes())} for p in files if p.relative_to(dest).as_posix() not in {'Manifest/package-files.json','验证结果.json'}]
    savej(dest/'Manifest/package-files.json',package)
    summary={'status':'verified','addonDirectories':len(ADDONS),'latestFiles':len(latest),'latestBytes':sum(x['bytes'] for x in latest),'settingsFiles':len(settings),'settingsBytes':sum(x['bytes'] for x in settings),'diffFiles':len(json.loads((dest/'Manifest/code-changes.json').read_text(encoding='utf-8'))['files']),'verifiedAtShanghai':datetime.now(TZ).isoformat(),'checks':['Latest and selected settings bytes match SHA-256 manifests','Live source re-read matches copied snapshot','ZIP CRC checked','Every ZIP payload re-read and compared to folder SHA-256'],'limitations':['DPSMateX core/options earliest snapshots already contain lock-window fix','Baseline is earliest available per-file stage, not a pristine upstream package','Settings backup contains on-disk relevant saved variables, bindings, macros and addon enablement; not all WTF']}
    savej(dest/'验证结果.json',summary)
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for p in sorted(dest.rglob('*')):
            if p.is_file(): z.write(p,p.relative_to(dest).as_posix())
    with zipfile.ZipFile(archive) as z:
        bad=z.testzip()
        if bad: raise RuntimeError('ZIP CRC failed '+bad)
        for info in z.infolist():
            if sha(z.read(info))!=sha((dest/info.filename).read_bytes()): raise RuntimeError('ZIP payload mismatch '+info.filename)
    checksum=archive.with_suffix('.zip.sha256'); save(checksum,sha(archive.read_bytes())+'  '+archive.name+'\n')
    savej(REPORT/'latest-backup-result.json',{'directory':str(dest),'archive':str(archive),'archiveBytes':archive.stat().st_size,'archiveSHA256':sha(archive.read_bytes()),**summary})
    print(json.dumps({'directory':str(dest),'archive':str(archive),'archiveMiB':round(archive.stat().st_size/1048576,2),**summary},ensure_ascii=True),flush=True)

def supplement(dest):
    current=dest/'Latest/Interface/AddOns'
    rows=['# 当前函数、依赖与配置入口','','行号对应本包 Latest；用函数名搜索新版，避免依赖旧行号。以下是当前声明索引，并不表示所有函数都在两天内改动。','']
    for addon in ADDONS:
        rows += ['## '+addon,'','```text']
        for p in (current/addon).glob('*.toc'):
            text,_=decode(p.read_bytes())
            rows.extend(line for line in text.splitlines() if re.match(r'##\s*(Version|Dependencies|RequiredDeps|OptionalDeps|SavedVariables|SavedVariablesPerCharacter):',line,re.I))
        rows+=['```','','| 文件 | 行号 | 声明 |','|---|---|---|']
        changes=json.loads((dest/'Manifest/code-changes.json').read_text(encoding='utf-8'))['files']
        for c in changes:
            if c['file'].split('/')[0]!=addon: continue
            for s in c['declaredFunctions']: rows.append(f"| `{c['file']}` | {s['line']} | `{s['name']}` |")
        rows+=['']
    save(dest/'Docs/函数与配置入口.md','\n'.join(rows))
    snippets=['# DPSMateX 锁窗修复当前代码','','缺少修复前快照，因此本页提供真实当前代码及位置，未声称是旧/新补丁。迁移到新版应实现同样的锁定行为，并验证多窗口和拖动中锁定。','']
    for rel in ['DPSMateX/DPSMateX.lua','DPSMateX/DPSMateX_Options.lua']:
        text,_=decode((current/rel).read_bytes());lines=text.splitlines()
        if rel.endswith('DPSMateX.lua'):
            start=next(i for i,l in enumerate(lines) if 'frame:SetResizable(not DPSMateX.Settings' in l);end=next(i for i in range(start,len(lines)) if 'if not val["titlebar"]' in lines[i])
            blocks=[(start,end)]
        else:
            start=next(i for i,l in enumerate(lines) if l.startswith('function DPSMateX.Options:Lock()'));end=next(i for i in range(start,len(lines)) if lines[i].startswith('function DPSMateX.Options:Hide('));blocks=[(start,end)]
        for start,end in blocks:
            snippets += [f'## {rel} 第 {start+1}～{end} 行','','```lua','\n'.join(lines[start:end]),'```','']
    save(dest/'Docs/DPSMateX锁窗修复当前代码.md','\n'.join(snippets))
    save(dest/'Tools/verify_backup.py', '''from pathlib import Path
import hashlib,json,sys
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
manifest=json.loads((root/'Manifest/package-files.json').read_text(encoding='utf-8'))
errors=[]
for item in manifest:
 p=(root/item['path']).resolve()
 if not p.is_relative_to(root): raise SystemExit('Unsafe manifest path')
 if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=item['sha256']:errors.append(item['path'])
print(json.dumps({'filesChecked':len(manifest),'errors':errors,'status':'verified' if not errors else 'failed'},ensure_ascii=False))
raise SystemExit(1 if errors else 0)
''')
    save(dest/'Tools/compare_new_version.py', '''from pathlib import Path
import argparse,difflib,json,hashlib
p=argparse.ArgumentParser(description='Compare staged new AddOns with the backup; does not modify plugin files.')
p.add_argument('--new-addons',required=True);p.add_argument('--output',required=True)
a=p.parse_args();root=Path(__file__).resolve().parents[1];new=Path(a.new_addons).resolve();out=Path(a.output).resolve()
if not new.is_dir():raise SystemExit('New AddOns directory missing')
if out.exists():raise SystemExit('Output already exists; choose a new directory')
if out.is_relative_to(new) or new.is_relative_to(out):raise SystemExit('Keep comparison output separate from new AddOns')
out.mkdir(parents=True);changes=json.loads((root/'Manifest/code-changes.json').read_text(encoding='utf-8'))['files'];rows=['# New upstream comparison','','New files are never modified. Current personal code stays in the backup. Baselines are per-file stage snapshots; review baseline limits in the migration guide.','','| File | New upstream status |','|---|---|']
def text(path):
 data=path.read_bytes()
 for enc in ['utf-8-sig','gb18030','cp1252']:
  try:return data.decode(enc).splitlines(True)
  except UnicodeDecodeError:pass
 raise ValueError(str(path))
for c in changes:
 rel=c['file'];n=new/rel;old=root/'Latest/Interface/AddOns'/rel;base=root/'Baseline/Interface/AddOns'/rel
 if not n.is_file():rows.append('| `'+rel+'` | missing; check renamed file or standalone extension |');continue
 same=hashlib.sha256(n.read_bytes()).hexdigest()==c['latestSHA256'];rows.append('| `'+rel+'` | '+('same as personal snapshot' if same else 'changed; review required')+' |')
 for label,left in [('personal-vs-new',old),('baseline-vs-new',base)]:
  if not left.exists():continue
  diff=''.join(difflib.unified_diff(text(left),text(n),fromfile=label+'/'+rel,tofile='new/'+rel,n=5));target=out/label/(rel+'.patch');target.parent.mkdir(parents=True,exist_ok=True);target.write_text(diff,encoding='utf-8')
(out/'README.md').write_text('\\n'.join(rows),encoding='utf-8');print(str(out/'README.md'))
''')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--destination');parser.add_argument('--finalize'); args=parser.parse_args()
    if args.finalize:
        dest=Path(args.finalize)
        baselines=json.loads((dest/'Manifest/baselines.json').read_text(encoding='utf-8'))
        make_diffs(dest,baselines['selected'],baselines['absentBefore'])
        supplement(dest)
        if (REPORT/'适配指南草稿.md').exists(): stable_copy(REPORT/'适配指南草稿.md',dest/'Docs/适配指南.md')
        finish(dest);return
    dest=Path(args.destination) if args.destination else Path('E:/WoW-PluginBackups')/('20261005-06_latest_'+datetime.now(TZ).strftime('%Y%m%d_%H%M%S'))
    entries,settings,stats=snapshot(dest)
    selected,absent=build_baselines(dest)
    changes,unchanged=make_diffs(dest,selected,absent)
    evidence_count=copy_evidence(dest)
    savej(REPORT/'backup-stage-result.json',{'directory':str(dest),'addons':stats,'changes':[{k:c[k] for k in ['file','status','baselineLabel','addedLines','removedLines','details']} for c in changes],'unchanged':unchanged,'evidenceFiles':evidence_count,'latestFiles':len(entries),'settingsFiles':len(settings)})
    save(dest/'README.md','# 2026-10-05～06 插件最新版备份与迁移资料\n\n此目录备份截至快照时间的当前磁盘最新版，保留两天累计修改，不是每一轮中间版本。\n\n- `Latest/Interface/AddOns/`：18 个完整插件目录，可用于完整回退。\n- `Settings/WTF/`：相关插件保存变量、宏、按键和启用列表；并非整个 WTF。\n- `Baseline/Interface/AddOns/`：逐文件最早可确认的修改前快照。\n- [适配指南](Docs/适配指南.md)：功能迁移入口、依赖、配置与验收。\n- [详细代码修改索引](Docs/详细代码修改索引.md)：各文件的全部增删代码、行号、声明锚点及基线来源。\n- `Patches/`：总补丁、按插件补丁和按文件补丁。\n- `Evidence/`：旧备份、原补丁、变更说明和已有检查脚本。\n- `Manifest/`：SHA-256、文件与基线记录。\n\n回退前退出游戏，先另存更新后的插件目录；将目标旧插件目录整体恢复，避免仅覆盖文件后留下新版多余文件。不要把 Baseline、Patches 或 Evidence 复制进 AddOns。Settings 只在需要恢复旧配置时单独恢复，避免覆盖后续游戏进度。\n\n迁移到新版时，应合并功能改动并验证，不能直接把旧 Lua 整文件覆盖到新版。现有阶段补丁不能不分顺序全部执行。\n\n注意：保护了昨天改过的 Cat、TianYan、Outfitter 和今天的 16 个目录（Cat 重复计一次）。CatPotion 为今天安装，PlayTurtle 仅分析；不计入自行修改目录。\n')
    print(json.dumps({'directory':str(dest),'addons':len(stats),'latestFiles':len(entries),'settingsFiles':len(settings),'diffFiles':len(changes),'unchanged':unchanged,'evidenceFiles':evidence_count},ensure_ascii=True),flush=True)

if __name__=='__main__':main()
