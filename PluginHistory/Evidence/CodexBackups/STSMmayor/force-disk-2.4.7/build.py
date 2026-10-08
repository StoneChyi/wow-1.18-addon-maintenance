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
    print('Installed and hash verified force reactive disk auto-enable.');sys.exit()
original={name:(work/(name+'.before')).read_bytes() for name in ['STSMmayor.lua','STSMmayor.toc']}
source=original['STSMmayor.lua'].decode('utf-8-sig').replace('\r\n','\n')
def replace(old,new):
    global source
    assert source.count(old)==1,old[:100]
    source=source.replace(old,new,1)
replace('local AUTO_REPAIR_THRESHOLD = 30 -- 自动修理耐久阈值（百分比）', '''local AUTO_REPAIR_THRESHOLD = 30 -- 自动修理耐久阈值（百分比）
local FORCE_REACTIVE_DISK_ID = 18168 -- 力反馈盾牌：按物品编号识别，兼容不同语言
local forceReactiveDiskEquipped = false

-- Only an equipment transition opens the panel. Inventory refreshes while
-- already wearing the disk must respect a manual hide/disable in this session.
local function STSMmayor_ForceReactiveDiskJustEquipped()
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if not slotID then return false end
    local itemLink = GetInventoryItemLink("player", slotID)
    local _, _, itemID = string.find(itemLink or "", "item:(%d+):")
    local wearing = tonumber(itemID) == FORCE_REACTIVE_DISK_ID
    local justEquipped = wearing and not forceReactiveDiskEquipped
    -- Update before enabling: shield checks may cause a nested equipment event.
    forceReactiveDiskEquipped = wearing
    return justEquipped
end''')
replace('''        if not startupComplete then return end
        STSMmayor_UpdateDurabilityDisplay()
        if STSMmayor_Enabled then STSMmayor_CheckShield() end''','''        if not startupComplete then return end
        if currentEvent == "UNIT_INVENTORY_CHANGED" and STSMmayor_ForceReactiveDiskJustEquipped() then
            STSMmayor_SetEnabled(true)
            return
        end
        STSMmayor_UpdateDurabilityDisplay()
        if STSMmayor_Enabled then STSMmayor_CheckShield() end''')
replace('''        if startupComplete then
            STSMmayor_UpdateDurabilityDisplay()''','''        if startupComplete then
            if STSMmayor_ForceReactiveDiskJustEquipped() then
                STSMmayor_SetEnabled(true)
                return
            end
            STSMmayor_UpdateDurabilityDisplay()''')
replace('''            -- 仅首次无保存状态时沿用原来的区域自动开启。
            -- 用户明确关闭后，过图/重登录都尊重已保存的关闭状态。
            if STSMmayorDB.Enabled == nil then''','''            -- An equipped disk explicitly enables the addon on login/reload.
            -- Automatic repair/swap choices and the saved position remain intact.
            if STSMmayor_ForceReactiveDiskJustEquipped() then
                STSMmayor_Enabled = true
                STSMmayorDB.Visible = true
            elseif STSMmayorDB.Enabled == nil then''')
toc=original['STSMmayor.toc'].decode('utf-8-sig').replace('## Version: 2.4.6','## Version: 2.4.7')
manifest={}
for name,value in [('STSMmayor.lua',source),('STSMmayor.toc',toc)]:
    data=value.encode('utf-8')
    (work/name).write_bytes(data)
    manifest[name]={'before':sha(original[name]),'after':sha(data)}
(work/'manifest.json').write_text(json.dumps(manifest,indent=2))
with zipfile.ZipFile(work/'修改前备份.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name,value in original.items():archive.writestr('STSMmayor/'+name,value)
print('Prepared item-ID equipment transition and startup auto-enable.')
