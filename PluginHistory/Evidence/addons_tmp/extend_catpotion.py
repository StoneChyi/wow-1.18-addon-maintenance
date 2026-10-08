import sys, re, shutil, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import catpotion_data as data

root = data.ROOT / 'Interface/AddOns/CatPotion'
backup = data.ROOT / 'addons_tmp/catpotion-consumables-backup-20261006'
backup.mkdir(exist_ok=True)
for filename in ['Core.lua', 'Settings.lua', 'Window.lua', 'README.md']:
    if not (backup/filename).exists(): shutil.copy2(root/filename, backup/filename)

items = data.cache_items()
spells, string, _ = data.dbc((data.OUT/'patch-P.mpq-Spell.dbc').read_bytes())
displays, display_string, _ = data.dbc((data.OUT/'patch-9.mpq-ItemDisplayInfo.dbc').read_bytes())
icons, icon_string, _ = data.dbc((data.OUT/'patch-P.mpq-SpellIcon.dbc').read_bytes())

# All IDs, names, textures and cooldown categories below are verified against this
# client's WDB and current patched DBC files; text deliberately avoids stale ranges.
catalogue = [
 ('swiftness',2459,'功能药水','迅捷药水','50%移速/15秒','buff'),
 ('immolationOil',8956,'功能药水','献祭之油','周围火焰伤害/15秒','buff'),
 ('limitedInvulnerability',3387,'功能药水','有限无敌','物理免疫/6秒','buff'),
 ('quickness',61181,'功能药水','加速药水','5%急速/30秒','buff'),
 ('jujuFlurry',12450,'功能药水','魂能之速','3%攻击/施法急速','buff'),
 ('freeAction',5634,'功能药水','自由行动','免疫昏迷/移动限制','buff'),
 ('livingAction',20008,'功能药水','活力行动','解除并免疫控制','buff'),
 ('mightyRage',13442,'功能药水','强效怒气（强怒）','怒气+60力量/20秒','buff'),
 ('greatRage',5633,'功能药水','暴怒药水','补充怒气','manual'),
 ('ragePotion',5631,'功能药水','怒气药水','补充怒气','manual'),
 ('greaterStoneshield',13455,'功能药水','强效石盾','护甲提高/2分钟','buff'),
 ('lesserStoneshield',4623,'功能药水','次级石盾','护甲提高','buff'),
 ('restorative',9030,'功能药水','滋补药剂','定期驱散负面效果','buff'),
 ('purification',13462,'功能药水','净化药水','解除诅咒/疾病/中毒','manual'),
 ('poisonResistance',3386,'功能药水','抗毒药水','解除中毒','manual'),
 ('invisibility',9172,'功能药水','隐形药水','隐形/18秒','buff'),
 ('lesserInvisibility',3823,'功能药水','次级隐形','隐形/15秒','buff'),
 ('magicResistance',9036,'功能药水','抗魔药水','提高全系魔法抗性','buff'),
 ('swimSpeed',6372,'功能药水','速游药水','提高游泳速度','buff'),
 ('greaterWaterBreathing',18294,'功能药水','强力水下呼吸','水下呼吸/1小时','buff'),
 ('petrification',13506,'功能药水','化石合剂','无法行动/免疫伤害','buff'),
 ('majorHealing',13446,'恢复物品','特效治疗（大红）','恢复生命值','manual'),
 ('majorMana',13444,'恢复物品','特效法力（大蓝）','恢复法力值','manual'),
 ('majorRejuvenation',18253,'恢复物品','特效活力','恢复生命/法力','manual'),
 ('superiorHealing',3928,'恢复物品','优质治疗','恢复生命值','manual'),
 ('superiorMana',13443,'恢复物品','优质法力','恢复法力值','manual'),
 ('greaterMana',6149,'恢复物品','强效法力','恢复法力值','manual'),
 ('greaterDreamlessSleep',20002,'恢复物品','强效昏睡','睡眠中恢复生命/法力','manual'),
 ('dreamlessSleep',12190,'恢复物品','昏睡药水','睡眠中恢复生命/法力','manual'),
 ('nordanaarTea',61675,'恢复物品','诺达纳尔草药茶','恢复生命/法力','manual'),
 ('thistleTea',7676,'恢复物品','菊花茶','恢复能量（盗贼）','manual'),
 ('demonicRune',12662,'恢复物品','恶魔符文','消耗生命恢复法力','manual'),
 ('darkRune',20520,'恢复物品','黑暗符文','消耗生命恢复法力','manual'),
 ('majorHealthstone',9421,'恢复物品','特效治疗石','恢复生命值','manual'),
 ('powerfulAntivenom',19440,'恢复物品','极效抗毒药剂','解除中毒（可对友方）','manual'),
 ('sapperCharge',10646,'常用炸药','地精工兵炸药','范围伤害/自身受伤','manual'),
 ('thoriumGrenade',15993,'常用炸药','瑟银手榴弹','范围伤害/昏迷','manual'),
 ('ironGrenade',4390,'常用炸药','铁皮手雷','范围伤害/昏迷','manual'),
 ('denseDynamite',18641,'常用炸药','致密炸弹','范围火焰伤害','manual'),
 ('solidDynamite',10507,'常用炸药','实心炸弹','范围火焰伤害','manual'),
 ('mithrilFragBomb',10514,'常用炸药','秘银破片炸弹','范围伤害/昏迷','manual'),
 ('darkIronBomb',16005,'常用炸药','黑铁炸弹','范围伤害/昏迷','manual'),
 ('bigOne',10586,'常用炸药','大炸弹','大范围伤害/昏迷','manual'),
 ('arcaneBomb',16040,'常用炸药','奥术炸弹','吸收法力/伤害/沉默','manual'),
 ('heavyIronBomb',4394,'常用炸药','重磅铁制炸弹','范围伤害/昏迷','manual'),
 ('ezThrowBomb',18588,'常用炸药','简易投掷炸弹 II','无需工程学','manual'),
 ('stratholmeWater',13180,'常用炸药','斯坦索姆圣水','对亡灵造成范围伤害','manual'),
 ('explosiveSheep',4384,'工程道具','自爆绵羊','召唤爆炸绵羊','manual'),
 ('goblinLandMine',4395,'工程道具','地精暗雷','放置爆炸地雷','manual'),
 ('targetDummy',4366,'工程道具','活动假人','吸引附近怪物','manual'),
 ('advancedDummy',4392,'工程道具','高级假人','吸引附近怪物','manual'),
 ('masterDummy',16023,'工程道具','高级活动假人','吸引附近怪物','manual'),
 ('discombobulator',4388,'工程道具','退化射线','削弱/减速敌人','manual'),
 ('alarmBot',18645,'工程道具','报警机器人','侦测潜行/隐形','manual'),
 ('repairBot',18232,'工程道具','修理机器人74A','展开修理机器人','manual'),
 ('battleChicken',10725,'工程道具','侏儒作战小鸡','需装备饰品','manual'),
 ('netOMatic',10720,'工程道具','侏儒撒网器','需装备饰品','manual'),
 ('deathRay',10645,'工程道具','侏儒死亡射线','需装备饰品','manual'),
 ('shrinkRay',10716,'工程道具','侏儒缩小射线','需装备饰品','manual'),
 ('dragonGun',10727,'工程道具','地精龙枪','需装备饰品','manual'),
 ('goblinMortar',10577,'工程道具','地精迫击炮','需装备饰品','manual'),
 ('recombobulator',4381,'工程道具','自动净化装置','需装备/对友方使用','manual'),
 ('iceReflector',18634,'工程道具','超低温寒冰偏斜器','需装备/反射冰霜','buff'),
 ('fireReflector',18638,'工程道具','高辐射烈焰反射器','需装备/反射火焰','buff'),
 ('shadowReflector',18639,'工程道具','快速暗影反射器','需装备/反射暗影','buff'),
 ('gnomishRocketBoots',10724,'工程道具','侏儒火箭靴','需装备靴子','buff'),
 ('rocketHelmet',10588,'工程道具','地精火箭头盔','需装备头盔','manual'),
 ('mindControlCap',10726,'工程道具','侏儒洗脑帽','需装备头盔','manual'),
]

def lua(value):
    if value is None: return 'nil'
    if value is True: return 'true'
    if value is False: return 'false'
    if isinstance(value,str): return json.dumps(value, ensure_ascii=False)
    return str(value)

def metadata(iid):
    item = items[iid]
    sid, trigger, charges, cooldown, category, category_cd = item['spells'][0]
    spell = spells.get(sid)
    if cooldown < 0: cooldown = spell[19] if spell else 0
    if category_cd < 0:
        category, category_cd = (spell[2],spell[20]) if spell else (0,0)
    return dict(itemID=iid, cooldown=cooldown/1000, cooldownCategory=category,
                categoryCooldown=category_cd/1000, gcdCategory=spell[157] if spell else 0,
                gcd=(spell[158]/1000) if spell else 0,
                requiresEquipped=True if item['inventory'] else None)

def fields(values):
    return ', '.join(k+' = '+lua(v) for k,v in values.items() if v is not None)

core = (root/'Core.lua').read_text(encoding='utf-8-sig')
core = core.replace('"武器强化", "毒药" }','"武器强化", "毒药", "功能药水", "恢复物品", "常用炸药", "工程道具" }',1)
section = ['-- 短效药水、恢复品与工程道具：数据来自本客户端 WDB/DBC（2026-10-06）。',
           '-- 短效 Buff 默认仅显示，右键可启用宏；无 Buff 的恢复品、炸药和工程装备仅手动使用。',
           'local usableItems = {']
for key,iid,category,label,detail,mode in catalogue:
    item, info = items[iid], metadata(iid)
    spell = spells.get(item['spells'][0][0])
    info = dict(key=key,category=category,item=item['name'],label=label,
                buff=string(spell[124]) if mode=='buff' and not info.get('requiresEquipped') else None,
                detail=detail,texture='Interface\\Icons\\'+display_string(displays[item['display']][5]),
                defaultMacroExcluded=True,manualOnly=(mode=='manual' or bool(info.get('requiresEquipped'))) or None,
                macroWarningSeconds=0,**info)
    if iid==12450: info['selfTarget']=True
    if iid==9421: info['alternateIDs'] = '{ 19012, 19013 }'
    line = fields({k:v for k,v in info.items() if k!='alternateIDs'})
    if 'alternateIDs' in info: line+=', alternateIDs = '+info['alternateIDs']
    section.append('    { '+line+' },')
section += ['}', 'local usableIndex, usableItem', 'for usableIndex, usableItem in ipairs(usableItems) do',
            '    addon.ItemTextures[usableItem.key] = usableItem.texture',
            '    addon.ItemDetails[usableItem.key] = usableItem.detail',
            '    table.insert(addon.Items, usableItem)', 'end', '',
            '-- 同时补齐原有药剂的冷却类别，使新旧药水/魂能/药剂的共享冷却一致。',
            'local existingCooldowns = {']
byname = {v['name']:v for v in items.values()}
original = re.findall(r'AddItem\("([^"]+)", "[^"]+", (?:nil|"[^"]*"), "([^"]+)"',core)
ids_by_name = {}
for file in [data.ROOT/'Interface/AddOns/pfQuest/db/zhCN/items.lua',data.ROOT/'Interface/AddOns/pfQuest-turtle/db/zhCN/items-turtle.lua']:
    for iid,name in re.findall(r'\[(\d+)\]\s*=\s*"([^"]+)"',file.read_text(encoding='utf8')):
        ids_by_name[name]=int(iid)
for key,name in original:
    iid = byname[name]['id'] if name in byname else ids_by_name.get(name)
    if iid in items:
        section.append('    '+key+' = { '+fields(metadata(iid))+' },')
section += ['}', 'addon.ItemsByName = {}', 'addon.ItemsByID = {}',
            'local dataIndex, dataItem', 'for dataIndex, dataItem in ipairs(addon.Items) do',
            '    local info = existingCooldowns[dataItem.key]',
            '    if info then', '        local field, value',
            '        for field, value in pairs(info) do dataItem[field] = value end', '    end',
            '    addon.ItemsByName[dataItem.item] = dataItem',
            '    if dataItem.itemID then addon.ItemsByID[dataItem.itemID] = dataItem end',
            '    if dataItem.alternateIDs then', '        local idIndex, itemID',
            '        for idIndex, itemID in ipairs(dataItem.alternateIDs) do addon.ItemsByID[itemID] = dataItem end',
            '    end', 'end', '',
            'function addon.IsMacroExcluded(item, profile)',
            '    if item.manualOnly then return true end',
            '    local excluded = profile and profile.macroExcluded and profile.macroExcluded[item.key]',
            '    if excluded == nil then return item.defaultMacroExcluded end',
            '    return addon.ToBoolean(excluded)', 'end', '']
marker='-- 设置界面、药剂小窗和 /catpotion 共用这一顺序'
core=core.replace(marker,'\n'.join(section)+'\n'+marker,1)
(root/'Core.lua').write_text(core,encoding='utf8',newline='\r\n')
(data.OUT/'catalogue.json').write_text(json.dumps(catalogue,ensure_ascii=False,indent=2),encoding='utf8')
print('Added',len(catalogue),'items; original cooldown records',len(original))
