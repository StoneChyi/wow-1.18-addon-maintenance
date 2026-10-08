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
    print('Installed and hash verified robot presence fix.');sys.exit()
original={name:(work/(name+'.before')).read_bytes() for name in ['STSMmayor.lua','STSMmayor.toc']}
source=original['STSMmayor.lua'].decode('utf-8-sig').replace('\r\n','\n')
def replace(old,new):
    global source
    assert source.count(old)==1,old[:100]
    source=source.replace(old,new,1)
replace('''    local lower = strlower(name)
    return strfind(lower, "修理机器人") ~= nil or strfind(lower, "repair bot") ~= nil''','''    local lower = strlower(name)
    return string.find(lower, "^修理机器人7[45][ab]型$") ~= nil
        or string.find(lower, "^战地修理机器人7[45][ab]型$") ~= nil
        or string.find(lower, "^修理機器人7[45][ab]型$") ~= nil
        or string.find(lower, "^field repair bot 7[45][ab]$") ~= nil
        or string.find(lower, "^repair bot 7[45][ab]$") ~= nil''')
start=source.index('local function STSMmayor_RememberRepairBot(unit)')
end=source.index('function STSMmayor_ResetRepairBots()',start)
source=source[:start]+(work/'range.lua').read_text(encoding='utf-8')+'\n\n'+source[end:]
replace('if ok and STSMmayor_IsGUID(guid) then STSMmayor_RememberRepairBot(guid) end',
        'if ok and STSMmayor_IsGUID(guid) then STSMmayor_RememberRepairBot(guid, frame) end')
replace('''    for guid in pairs(repairBotUnits) do
        if STSMmayor_UnitIsRepairBot(guid) then found = true; repairBotGUID = guid
        else repairBotUnits[guid] = nil end
    end''','''    local now = GetTime()
    for guid, record in pairs(repairBotUnits) do
        local valid = STSMmayor_UnitIsRepairBot(guid)
        if valid then
            local nearby, queried = STSMmayor_BotRange(guid)
            if not queried and nearby == nil and type(record) == "table" then
                if record.plate then
                    valid = STSMmayor_CurrentBotPlate(guid, record.plate)
                    if valid then record.lastObserved = now end
                else
                    valid = now - record.lastObserved <= REPAIR_BOT_EVIDENCE_TTL
                end
            else
                valid = nearby == true
            end
        end
        if valid then found = true; repairBotGUID = guid
        else repairBotUnits[guid] = nil end
    end''')
replace('text = "已检测到附近可见且存活的修理机器人"',
        'text = "已检测到附近存活的修理机器人（可测距时限40码内；不代表可立即修理）"')
replace('text = "当前未检测到修理机器人（仅限客户端可见范围）"',
        'text = "当前未确认附近有修理机器人（可测距时限40码内；需客户端可见数据）"')
toc=original['STSMmayor.toc'].decode('utf-8-sig').replace('## Version: 2.4.7','## Version: 2.4.8')
manifest={}
for name,value in [('STSMmayor.lua',source),('STSMmayor.toc',toc)]:
    data=value.encode('utf-8')
    (work/name).write_bytes(data)
    manifest[name]={'before':sha(original[name]),'after':sha(data)}
(work/'manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(work/'修改前备份.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name,value in original.items():archive.writestr('STSMmayor/'+name,value)
print('Prepared range validation, exact robot names and expiring fallback evidence.')
