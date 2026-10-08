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
    print('Installed and hash verified range + line-of-sight detection.');sys.exit()
original={name:(work/(name+'.before')).read_bytes() for name in ['STSMmayor.lua','STSMmayor.toc']}
source=original['STSMmayor.lua'].decode('utf-8-sig').replace('\r\n','\n')
def replace(old,new):
    global source
    assert source.count(old)==1,old[:100]
    source=source.replace(old,new,1)
replace('local function STSMmayor_RememberRepairBot(unit)', '''-- UnitIsVisible only means the client has loaded the unit; it does not test
-- walls. Query the player's line of sight, never the camera's visibility.
-- This is a local precheck, not a server-confirmed interaction result.
local function STSMmayor_BotInSight(unit)
    if type(UnitXP) ~= "function" then return false end
    local ok, inSight = pcall(UnitXP, "inSight", "player", unit)
    -- Lua treats 0 and -1 as true, so never use generic truthiness here.
    return ok and (inSight == true or inSight == 1)
end

local function STSMmayor_RememberRepairBot(unit)''')
replace('    if guid then repairBotUnits[guid] = true; repairBotGUID = guid end', '''    -- Keep nearby candidates even while occluded so walking around a wall
    -- can restore green on the normal poll, without another discovery event.
    if guid then repairBotUnits[guid] = true end''')
replace('''            found = true; repairBotGUID = guid
''','''            if STSMmayor_BotInSight(guid) then
                found = true; repairBotGUID = guid
            end
''')
replace('    if STSMmayor_RememberRepairBot("target") then found = true end', '    if STSMmayor_RememberRepairBot("target") and STSMmayor_BotInSight("target") then found = true end')
replace('    if STSMmayor_RememberRepairBot("mouseover") then found = true end', '    if STSMmayor_RememberRepairBot("mouseover") and STSMmayor_BotInSight("mouseover") then found = true end')
replace('修理机器人在无双交互距离内（5码；仍受商人/过滤设置影响）', '修理机器人在5码内且无遮挡（本地预判；仍受商人/过滤设置及服务器规则影响）')
replace('未确认5码内有修理机器人（无双交互范围；无法测距时不报可用）', '未确认可交互的修理机器人（超出5码、被遮挡或距离/视线检测不可用）')
toc=original['STSMmayor.toc'].decode('utf-8-sig').replace('## Version: 2.4.9','## Version: 2.4.10')
assert '## Version: 2.4.10' in toc
manifest={}
for name,value in [('STSMmayor.lua',source),('STSMmayor.toc',toc)]:
    data=value.encode('utf-8');(work/name).write_bytes(data)
    manifest[name]={'before':sha(original[name]),'after':sha(data)}
(work/'manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(work/'修改前备份.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name,value in original.items():archive.writestr('STSMmayor/'+name,value)
print('Prepared conservative 5-yard range + player line-of-sight detection.')
