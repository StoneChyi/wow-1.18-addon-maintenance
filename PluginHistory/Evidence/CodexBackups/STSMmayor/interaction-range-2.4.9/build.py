from pathlib import Path
import hashlib,json,sys,zipfile
work=Path(__file__).parent
root=Path(r'E:\1.18\Interface\AddOns\STSMmayor')
sha=lambda data:hashlib.sha256(data).hexdigest()
if len(sys.argv)>1 and sys.argv[1]=='deploy':
    manifest=json.loads((work/'manifest.json').read_text())
    for name,data in manifest.items():
        assert sha((root/name).read_bytes())==data['before'], 'Live file changed: '+name
        assert sha((work/name).read_bytes())==data['after']
    for name,data in manifest.items():
        (root/name).write_bytes((work/name).read_bytes())
        assert sha((root/name).read_bytes())==data['after']
    print('Installed and hash verified 5-yard interaction range.');sys.exit()
original={name:(work/(name+'.before')).read_bytes() for name in ['STSMmayor.lua','STSMmayor.toc']}
source=original['STSMmayor.lua'].decode('utf-8-sig').replace('\r\n','\n')
def replace(old,new):
    global source
    assert source.count(old)==1,old[:100]
    source=source.replace(old,new,1)
start=source.index('-- A loaded/visible GUID is not proof')
end=source.index('function STSMmayor_ResetRepairBots()',start)
source=source[:start]+(work/'range.lua').read_text(encoding='utf-8')+'\n'+source[end:]
start=source.index('    local now = GetTime()\n    for guid, record in pairs(repairBotUnits)')
end=source.index('    -- Standard unit tokens remain usable',start)
source=source[:start]+'''    for guid in pairs(repairBotUnits) do
        if STSMmayor_UnitIsRepairBot(guid) and STSMmayor_BotRange(guid) == true then
            found = true; repairBotGUID = guid
        else
            repairBotUnits[guid] = nil
        end
    end
'''+source[end:]
replace('STSMmayor_RememberRepairBot(guid, frame)', 'STSMmayor_RememberRepairBot(guid)')
replace('已检测到附近存活的修理机器人（可测距时限40码内；不代表可立即修理）',
        '修理机器人在无双交互距离内（5码；仍受商人/过滤设置影响）')
replace('当前未确认附近有修理机器人（可测距时限40码内；需客户端可见数据）',
        '未确认5码内有修理机器人（无双交互范围；无法测距时不报可用）')
toc=original['STSMmayor.toc'].decode('utf-8-sig').replace('## Version: 2.4.8','## Version: 2.4.9')
manifest={}
for name,value in [('STSMmayor.lua',source),('STSMmayor.toc',toc)]:
    data=value.encode('utf-8');(work/name).write_bytes(data)
    manifest[name]={'before':sha(original[name]),'after':sha(data)}
(work/'manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(work/'修改前备份.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name,value in original.items():archive.writestr('STSMmayor/'+name,value)
print('Prepared 5-yard 3D range matching installed wsloot.dll.')
