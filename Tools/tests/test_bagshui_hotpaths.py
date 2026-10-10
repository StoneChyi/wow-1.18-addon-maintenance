"""Compare real rule and item-layout paths with the pre-optimization personal build.

Lua 5.1 stand-ins check behavior/work counts, not game timings or game acceptance.
The reference is a project maintenance commit, not an official upstream version.
"""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / 'Interface/AddOns/Bagshui'
REFERENCE = '431fbc4f55774eae4846feddf1782cfd17acdc1a'
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

PRELUDE = r'''
Bagshui={environment={},components={},config={},prototypes={Ui={},Inventory={}},
 currentCharacterInfo={class='MAGE'},activeQuestItems={}}
function Bagshui:AddComponent(fn) fn() end
Bagshui.LoadComponent=Bagshui.AddComponent
function Bagshui:PrintWarning() end
L=setmetatable({Error_RuleNilArgument='nil argument %d',Error_RuleInvalidArgument='%d %s %s %s',
 Error_RuleExecution='%s %s',Error_RuleTooManyArguments='%s %s',
 Error_RuleInvalidArgumentType='invalid type %s %s',Error_RuleFunctionInvalid='invalid %s',
 Error_RuleNoArguments='no arguments',Bag='Bag'}, {__index=function(_,k) return k end})
L_nil={armor='armure'}
BS_RULE_ARGUMENT_TYPE={STRING={string=true},NUMBER={number=true},
 ['STRING,NUMBER']={string=true,number=true},['NUMBER,STRING']={string=true,number=true}}
BS_RULE_MATCH_TYPE={EQUALS='EQUALS',CONTAINS='CONTAINS',BETWEEN='BETWEEN'}
BS_RULE_ENVIRONMENT_VARIABLES={}
clock=10
function GetTime() return clock end
function time() return 1000 end
BS_COLOR={ITEM_SLOT_STATE_NORMAL={1,1,1,1},ITEM_SLOT_STATE_LOCKED={0.5,0.5,0.5,0.5},
 FULL_RED={1,0,0},LIGHT_GREEN={0.5,1,0.5},ITEM_SLOT_HIGHLIGHT={1,1,0}}
NORMAL_FONT_COLOR={r=1,g=0.8,b=0}
ITEM_QUALITY_COLORS={[-1]={r=1,g=1,b=1,a=0},[0]={r=0.5,g=0.5,b=0.5,a=1},
 [1]={r=1,g=1,b=1,a=1},[2]={r=0,g=1,b=0,a=1}}
BS_INVENTORY_QUALITY_BADGE_COORD={[2]={0,0.25,0,0.25}}
BS_INVENTORY_QUALITY_BADGE_RECOLOR={}
BS_INVENTORY_USABLE_BADGE={UNUSABLE={texture='unusable',texCoord={0,1,0,1}},
 KNOWN={texture='known',texCoord={0,1,0,1}}}
BS_INVENTORY_EMPTY_SLOT_TEXTURE={Bag='empty'}
BS_INVENTORY_STOCK_BADGE_MAX_FADE=0.3
BS_ITEM_STOCK_STATE={NO_CHANGE='',NEW='New'}
BS_UI_ITEM_BUTTON_TYPE={ITEM='Item'}
BsSkin={itemSlotBorderInverseScale=true,itemSlotEdgeSize=1,itemSlotBorderOpacity=1,
 itemSlotInnerGlowOpacity=0.5,itemSlotTextureOfflineOpacity=0.5,itemSlotTextureDimmedOpacity=0.2,
 itemSlotTextureEditModeOpacity=0.3,itemSlotBorderContainerHighlightOpacity=1,
 itemSlotInnerGlowContainerHighlightOpacity=0.5}
BsItemInfo={}
function BsItemInfo:IsUsable(item) return item.usable~=false,item.alreadyKnown end
counts={}
function hit(name) counts[name]=(counts[name] or 0)+1 end
methods={}
function object(kind,name,parent)
 return setmetatable({kind=kind,name=name,parent=parent,scale=1,shown=true,alpha=1}, {__index=methods})
end
function methods:GetName() return self.name end
function methods:GetScale() return self.scale end
function methods:SetScale(v) hit('scale'); self.scale=v end
function methods:GetParent() return self.parent end
function methods:SetParent(v) hit('parent'); self.parent=v end
function methods:SetBackdrop(v)
 hit('backdrop'); self.edgeSize=v.edgeSize; self.edgeFile=v.edgeFile
 self.backdrop=BsUtil.TableCopy(v)
 self.borderColor={1,1,1,1} -- 1.12 backdrop replacement resets colors.
end
function methods:GetBackdrop() return self.backdrop and BsUtil.TableCopy(self.backdrop) end
function methods:SetBackdropBorderColor(r,g,b,a) self.borderColor={r,g,b,a} end
function methods:SetTexture(v) self.texture=v end
function methods:SetVertexColor(r,g,b,a) self.color={r,g,b,a or 1} end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetTexCoord(a,b,c,d) self.texCoord={a,b,c,d} end
function methods:SetTextColor(r,g,b) self.textColor={r,g,b} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsVisible() return self.shown end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(p,other,op,x,y) self.point={p,other.name,op,x,y} end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetTop() return 1 end
function methods:SetHitRectInsets(a,b,c,d) self.hitRect={a,b,c,d} end
function SetItemButtonTexture(b,t) hit('texture'); b.bagshuiData.buttonComponents.iconTexture:SetTexture(t) end
function SetItemButtonCount(b,n)
 hit('count'); b.count=n
 local text=b.bagshuiData.buttonComponents.count
 text:SetText(n>1 and tostring(n) or ''); text.shown=n>1
end
function SetItemButtonDesaturated(b,v,r,g,bl) b.desaturated=v end
function SetItemButtonTextureVertexColor(b,r,g,bl,a) b.bagshuiData.buttonComponents.iconTexture:SetVertexColor(r,g,bl,a) end
function GetContainerItemCooldown(bag,slot) hit('cooldownRead'); return cooldownStart or 0,cooldownDuration or 0,cooldownEnabled or 0 end
function CooldownFrame_SetTimer(c,s,d,e) hit('cooldown'); c.timer={s,d,e} end
function snapshot()
 local d=button.bagshuiData
 local result={parent=button.parent.name,scale=button.scale,point=button.point,
  count=button.count,desaturated=button.desaturated,itemId=d.itemId,group=d.groupId,
  bagNum=d.bagNum,slotNum=d.slotNum,position=d.position,emptyStack=d.isEmptySlotStack,components={}}
 for name,c in pairs(d.buttonComponents) do
  local v={shown=c.shown,alpha=c.alpha,texture=c.texture,color=c.color,borderColor=c.borderColor,
   text=c.text,textColor=c.textColor,edgeSize=c.edgeSize,edgeFile=c.edgeFile,timer=c.timer}
  if c.bagshuiData then
   v.texture=c.bagshuiData.texture.texture; v.texCoord=c.bagshuiData.texture.texCoord
   v.shadowColor=c.bagshuiData.shadow.color
  end
  result.components[name]=v
 end
 local function encode(t)
  if type(t)~='table' then return tostring(t) end
  local keys={}; for k in pairs(t) do table.insert(keys,k) end
  table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
  local out={}; for _,k in ipairs(keys) do table.insert(out,tostring(k)..'='..encode(t[k])) end
  return '{'..table.concat(out,';')..'}'
 end
 return encode(result)
end
'''

SETUP = r'''
Rules=Bagshui.components.Rules; BsRules=Rules
Rules:PrepareEnvironment()
Rules.allowedArgumentTypes='STRING NUMBER'
function register(name,fn) assert(Rules:AddEnvironmentFunction(fn,name)) end
register('Name',function(r,a) return r:TestItemAttribute('name',a,'string','contains') end)
register('Tooltip',function(r,a) return r:TestItemAttribute('tooltip',a,'string','contains') end)
register('Type',function(r,a) return r:TestItemAttribute('type',a,nil,nil,nil,nil,true) end)
register('Count',function(r,a) return r:TestItemAttribute('count',a,'number','between',nil,true) end)
register('Bad',function() error('rule failure') end)
register('Echo',function(r,a)
 echo={}; for i,v in ipairs(a) do echo[i]=v end; return true
end)
helperCalls=0
local originalInsert=BsUtil.TableInsertNonNil
function BsUtil.TableInsertNonNil(t,v,empty) helperCalls=helperCalls+1; return originalInsert(t,v,empty) end
group=object('Frame','group'); otherGroup=object('Frame','otherGroup')
inventory=setmetatable({online=true,inventoryTypeSavedVars='bags',settings={windowContentAlignment='LEFT',
 itemStockChangeExpiration=10,itemStockBadgeFadeDuration=2,emptySlotBackgroundImage=true},groups={g={}},groupItems={},containers={[0]={genericType='Bag'}},
 hideItems={},positioningTables={},emptySlotStacks={},editState={}}, {__index=Bagshui.prototypes.Inventory})
ui=setmetatable({inventory=inventory,frames={groups={group}},buttons={itemSlots={}}}, {__index=Bagshui.prototypes.Ui})
inventory.ui=ui
function ui:CreateInventoryItemSlotButton(i) assert(self.buttons.itemSlots[i]) end
function inventory:GetEmptySlotTexture() return 'empty' end
button=object('Button','item',otherGroup)
button.bagshuiData={inventory=inventory,originalSizeAdjusted=32,originalSize=32,type=BS_UI_ITEM_BUTTON_TYPE.ITEM,
 borderBackdropTable={tile=false,tileSize=0,edgeFile='border',edgeSize=1,insets={left=0,right=0,top=0,bottom=0}},
 buttonComponents={},qualityColor=ITEM_QUALITY_COLORS[1],qualityBadgeAlpha=0,stockBadgeAlpha=0,topLeftBadgeAlpha=0}
ui.buttons.itemSlots[1]=button
for _,name in ipairs({'iconTexture','background','border','highlightTexture','normalTexture','innerGlow','cooldown'}) do
 button.bagshuiData.buttonComponents[name]=object('Texture',name,button)
end
button.bagshuiData.buttonComponents.border.backdrop=BsUtil.TableCopy(button.bagshuiData.borderBackdropTable)
button.bagshuiData.buttonComponents.count=object('FontString','count',button)
button.bagshuiData.buttonComponents.count:SetFontObject('GameFontNormal')
for _,name in ipairs({'stockBadge','topLeftBadge','qualityBadge'}) do
 local b=object('Frame',name,button)
 b.bagshuiData={texture=object('Texture',name..'texture',b),shadow=object('Texture',name..'shadow',b),shadowOpacity=0.6}
 button.bagshuiData.buttonComponents[name]=b
end
item={id=1,name='Test Sword',tooltip='Restores Health. 100%!',type='Armor',count=4,quality=2,
 emptySlot=0,bagNum=0,slotNum=1,itemString='item:1',texture='sword',maxStackCount=20,charges=0,locked=0,bagshuiStockState=''}
Rules:SetItemAndCharacter(item)
BS_ITEM_SKELETON=BsUtil.TableCopy(item)
function render(size)
 inventory.groupItems.g={item}
 return inventory:AssignItemsToSlots('g',1,1,1,2,size or 32,1)
end
local colorUpdate=ui.UpdateItemButtonColorsAndBadges
function ui:UpdateItemButtonColorsAndBadges(b,force) hit('colors'); return colorUpdate(self,b,force) end
'''


def source(name, original=False):
    if original:
        return subprocess.check_output(['git', 'show', f'{REFERENCE}:Interface/AddOns/Bagshui/Components/{name}'], cwd=ROOT).decode('utf-8-sig')
    return (ADDON / 'Components' / name).read_bytes().decode('utf-8-sig')


def runtime(original=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute(source('Util.lua'))
    lua.execute('BsUtil=Bagshui.components.Util')
    rule_source = source('Rules.lua', original)
    assert rule_source.count('\nRules:Init()') == 1
    # UI/template catalogs are outside this fixture; keep all rule methods real.
    lua.execute(rule_source.replace('\nRules:Init()', '\n-- Initialized explicitly by this test.'))
    lua.execute(source('Ui.ItemButton.lua', original))
    lua.execute(source('Ui.TextAndTextures.lua'))
    lua.execute(source('Inventory.Layout.lua', original))
    font_contract = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')
    lua.execute(font_contract)(lua.globals().methods, lua.globals().object)
    lua.execute(SETUP)
    # Exercise the real category priority/list/class paths with real rule compilation.
    category_source = source('Categories.lua')
    parts = []
    for name in ['FinalizeRule', 'BuildFinalizedRuleId', 'Categorize', 'MatchCategory']:
        start = category_source.index(f'function Categories:{name}(')
        next_function = category_source.find('\nfunction ', start + 1)
        assert next_function > start
        parts.append(category_source[start:next_function])
    lua.execute('''Categories={defaultCategory='all',list={},finalizedCategoryRules={},errors={},errorTimestamps={},recursedCategories={}}
function Categories:Get(id) return self.list[id] end
function Categories:ReportError(id,err) self.errors[id]=err end
function Bagshui:PrintDebug() end
''' + '\n'.join(parts))
    return lua


checks = []


def check(name, script):
    lua = runtime()
    lua.execute(script)
    checks.append(name)


def compare(name, steps):
    before, after = runtime(True), runtime()
    for step in steps:
        before.execute(step)
        after.execute(step)
        assert before.eval('snapshot()') == after.eval('snapshot()'), (name, step)
    checks.append(name)
    return before, after


check('fixed argument wrapper preserves nil compaction, false, empty strings and limit', r'''
Rules.environment.Echo(nil,false,'',nil,0,'last')
assert(#echo==4 and echo[1]==false and echo[2]=='' and echo[3]==0 and echo[4]=='last')
assert(helperCalls==0)
local args={}; for i=1,50 do args[i]=i end
Rules.environment.Echo(unpack(args)); assert(#echo==50 and echo[50]==50)
Rules.environment.Echo(); assert(#echo==0 and next(Rules.ruleFunctionArguments)==nil)
args[51]=51; assert(Rules.environment.Echo(unpack(args))==false and Rules.error~=nil)
Rules.environment.Echo(2); assert(#echo==1 and echo[1]==2)
''')

# Lua 5.0 retains explicit list sizes after insert/remove; Lua 5.1 does not.
# Model the documented old standard-library contract to catch direct-write regressions.
length_contract = r'''
local sizes=setmetatable({}, {__mode='k'})
local insert,remove=table.insert,table.remove
function table.getn(t)
 if type(t.n)=='number' then return t.n end
 if sizes[t]~=nil then return sizes[t] end
 local n=0; while t[n+1]~=nil do n=n+1 end; return n
end
function table.setn(t,n)
 if type(t.n)=='number' then t.n=n else sizes[t]=n end
end
function table.insert(t,pos,value)
 local n=table.getn(t)
 if value==nil then value=pos; pos=n+1 end
 insert(t,pos,value); table.setn(t,n+1)
end
function table.remove(t,pos)
 local n=table.getn(t); local result=remove(t,pos or n)
 table.setn(t,n-1); return result
end
register('Length',function(r,a) length=table.getn(a); return true end)
for i=1,3 do
 Rules.environment.Length(1,2); assert(length==2)
 Rules.environment.Length(); assert(length==0)
 Rules.environment.Length(nil,false,nil,4); assert(length==2)
 Rules.environment.Length(5); assert(length==1)
end
'''
runtime(True).execute(length_contract)
runtime().execute(length_contract)
checks.append('Lua 5.0 explicit array length remains correct across repeated compacted calls')

check('one classification session reuses text while new sessions see edits', r'''
local session=Rules:SetItemAndCharacter(item)
for i=1,20 do assert(Rules:Match('Tooltip("health")',item,nil,session)) end
assert(Rules.lowercaseMatchValueCount==1 and Rules.normalizedMatchArgumentCount==1)
item.tooltip='RESTORES MANA'; clock=clock+1
session=Rules:SetItemAndCharacter(item)
assert(not Rules:Match('Tooltip("health")',item,nil,session))
assert(Rules:Match('Tooltip("mana")',item,nil,session))
item.tooltip='Restores Health'; clock=clock+1
assert(Rules:Match('Tooltip("health")',item))
''')

check('text caches are bounded and do not reuse category outcomes', r'''
for i=1,600 do
 assert(Rules:TestValue('VALUE'..i,{'value'..i},'string','equals'))
 assert(Rules:TestValue('VALUE'..i,{'value'..i},'string','contains'))
end
assert(Rules.normalizedMatchArgumentCount<=256 and Rules.lowercaseMatchValueCount<=16)
local long=string.rep('a',2049); local n=Rules.normalizedMatchArgumentCount
assert(Rules:TestValue(long,{long})); assert(Rules.normalizedMatchArgumentCount==n)
local args={'health'}
assert(Rules:TestValue('Health',args,'string','contains'))
args[1]='mana'; assert(not Rules:TestValue('Health',args,'string','contains'))
''')

check('normalization cache separates equality from contains and preserves false results', r'''
assert(Rules:TestValue('100%!',{'100%!'},'string','equals'))
assert(Rules:TestValue('100%!',{'100%!'},'string','contains'))
assert(not Rules:TestValue('100x!',{'100%!'},'string','contains'))
assert(not Rules:TestValue('different',{'100%!'},'string','equals'))
assert(Rules:TestValue('foo',{'foo','bad'},'string','equals'))
assert(not Rules:TestValue('foo',{false},'string','equals') and Rules.errorMessage~=nil)
''')

# Differential checks retain literal, Lua-pattern, localization, error and numeric behavior.
old, new = runtime(True), runtime()
cases = [
    ('Health', ' health ', 'string', 'contains'), ('100%!', '100%!', 'string', 'contains'),
    ('a.b[c]+?', 'a.b[c]+?', 'string', 'contains'), ('HELLO', '/%A/', 'string', 'contains'),
    ('123', '/%D/', 'string', 'contains'), ('abc 123', '/%D/', 'string', 'contains'),
    ('Foo', '/^FOO$/', 'string', 'contains'), ('Sword', '/[/', 'string', 'contains'),
    ('Foo', 'foo', 'STRING', 'invalid'), ('foo', '', 'string', 'equals'),
    ('Foo', 'foo', 'invalid type', 'equals'), ('armure', 'Armor', None, 'equals'),
    (12, 12, 'string,number', 'equals'), (12, 12, 'number', 'between'),
    ('法力药水', '法力', 'string', 'contains'), ('血量提升', '/血量/', 'string', 'contains'),
]
runner = '''function(value,argument,types,mode)
 Rules.errorMessage=nil
 local ok,result=pcall(Rules.TestValue,Rules,value,{argument},types,mode,nil,true,true)
 return ok,tostring(result),tostring(Rules.errorMessage)
end'''
for case in cases * 2:
    def normalize_error(result):
        if not isinstance(result, tuple):
            result = (result,)
        return tuple(re.sub(r'\[string "<python>"\]:\d+: ', '', part) if isinstance(part, str) else part for part in result)
    assert normalize_error(old.eval(runner)(*case)) == normalize_error(new.eval(runner)(*case)), case
checks.append('original and optimized literal/pattern/localization/error/numeric matching agree')

check('search, aliases, dynamic expressions and protected errors remain live', r'''
assert(Rules:Match('sword',item,nil,nil,true))
item.name='Test Axe'; clock=clock+1
assert(not Rules:Match('sword',item,nil,nil,true))
assert(Rules:Match('=Count(4)',item,nil,nil,true))
item.count=1; clock=clock+1
assert(not Rules:Match('=Count(4)',item,nil,nil,true))
assert(Rules:Match('name("axe")',item))
local ok,err=Rules:Match('Bad()',item); assert(not ok)
ok,err=Rules:Match('Missing()',item); assert(not ok and string.find(err,'invalid'))
assert(Rules:Match('Name("axe")',item))
local valid,e=Rules:Validate('Name("axe")'); assert(valid and e==nil)
''')

for expression in ['Bad()', 'Missing()', 'Name(false)', 'Tooltip("/[ /")', 'Count(1,5)', 'i.count == 4']:
    old.globals().expression = new.globals().expression = expression
    assert normalize_error(old.eval('function() return Rules:Match(expression,item) end')()) == normalize_error(new.eval('function() return Rules:Match(expression,item) end')())

check('category priority, direct lists, class rules and dynamic counts remain live', r'''
Categories.list={direct={list={1},dateModified=1},many={rule='Count(5)',dateModified=1},
 class={classes={MAGE={rule='Tooltip("health")'},WARRIOR={rule='Name("axe")'}},dateModified=1},
 all={rule='*',dateModified=1}}
local order={1,2,3,4}
local groups={[1]={direct='g1'},[2]={many='g2'},[3]={class='g3'},[4]={all='g4'}}
-- Normal initialization compiles category rules before inventory evaluation.
Categories:FinalizeRule('many',Categories.list.many,nil,true)
for class,category in pairs(Categories.list.class.classes) do
 Categories:FinalizeRule('class',category,class,true)
end
local function categorize(class)
 clock=clock+1; Categories:Categorize(item,{class=class},order,groups)
 return item.bagshuiCategoryId
end
assert(categorize('MAGE')=='direct')
item.id=2; item.count=7; assert(categorize('MAGE')=='many')
item.count=1; assert(categorize('MAGE')=='class')
assert(categorize('WARRIOR')=='all')
item.name='Test Axe'; assert(categorize('WARRIOR')=='class')
item.tooltip='Restores Mana'; assert(categorize('MAGE')=='all')
Categories.list.class.classes.MAGE.rule='Tooltip("mana")'
Categories:FinalizeRule('class',Categories.list.class.classes.MAGE,'MAGE',true)
assert(categorize('MAGE')=='class')
''')

check('nested rule matching and dynamic argument values retain argument-table semantics', r'''
register('Nested',function(r,a)
 return r:Match('Tooltip("health")',item,nil,r.currentSession,nil,true)
end)
assert(Rules:Match('Nested() and Count(4)',item))
assert(Rules:Match('Name(i.name)',item))
item={id=3,name='Potion',tooltip='Mana',count=1}; clock=clock+1
assert(not Rules:Match('Nested()',item))
assert(Rules:Match('Name(i.name) and Count(1)',item))
''')

before, after = runtime(True), runtime()
workload = r'''
local lower=string.lower
function string.lower(value)
 if value==item.tooltip then hit('tooltipLower') end
 return lower(value)
end
local trim=BsUtil.Trim
function BsUtil.Trim(value,...) hit('trim'); return trim(value,...) end
local session=Rules:SetItemAndCharacter(item)
local rule=Rules:Compile('Tooltip("health")')
for i=1,100 do assert(Rules:Match(rule,item,nil,session)) end
'''
before.execute(workload)
after.execute(workload)
assert before.eval('counts.tooltipLower') == 100 and after.eval('counts.tooltipLower') == 1
assert before.eval('counts.trim') == 100 and after.eval('counts.trim') == 1
assert before.eval('helperCalls') == 5000 and after.eval('helperCalls') == 0
checks.append('100 real rule evaluations reuse tooltip lowercase and argument preparation')

compare('layout colors, coordinates, assignment and hook calls agree', [
    'render(40)', 'render(40)', 'render(48)',
    'inventory.settings.windowContentAlignment="RIGHT"; render(48)',
    'group=otherGroup; ui.frames.groups[1]=group; render(32)',
])

before, after = compare('stable layout removes duplicate colors, border, scale and parent work', ['render(40)', 'render(40)'])
assert before.eval('counts.colors') == 4 and after.eval('counts.colors') == 2
assert before.eval('counts.backdrop') == 2 and after.eval('counts.backdrop') == 1
assert before.eval('counts.scale') == 2 and after.eval('counts.scale') == 1
assert before.eval('counts.parent') == 2 and after.eval('counts.parent') == 1
for key in ['texture', 'count', 'cooldown', 'cooldownRead']:
    assert before.eval(f'counts.{key}') == after.eval(f'counts.{key}') == 2

compare('locked, charged, stock, quest and usable displays agree', [
    'inventory.settings.itemQualityBadges=true; render(40)',
    'item.locked=1; render(40)', 'item.locked=0; item.count=1; item.maxStackCount=1; item.charges=7; render(40)',
    'inventory.settings.itemActiveQuestBadges=true; Bagshui.activeQuestItems[item.name]=true; render(40)',
    'Bagshui.activeQuestItems={}; inventory.settings.itemUsableBadges=true; inventory.settings.itemUsableColors=true; item.usable=false; render(40)',
    'item.usable=true; item.alreadyKnown=true; render(40)',
    'item.bagshuiDate=990; item.bagshuiStockState="New"; inventory.settings.itemStockBadges=true; render(40)',
    'item.bagshuiDate=1; render(40)',
])

compare('cooldown start, finish and disabled dimming retain game API refresh', [
    'cooldownStart=900; cooldownDuration=30; cooldownEnabled=1; render(40)',
    'cooldownEnabled=0; render(40)', 'cooldownDuration=0; render(40)',
])

compare('online/offline, search and container highlighting agree', [
    'render(40)', 'inventory.online=false; render(40)', 'inventory.online=true; render(40)',
    'inventory.searchText="axe"; render(40)', 'inventory.searchText="sword"; render(40)',
    'inventory.searchText=nil; inventory.highlightItemsInContainerId=1; render(40)',
    'inventory.highlightItemsInContainerId=0; inventory.highlightItemsContainerSlot=1; render(40)',
])

compare('edit mode colors and restored badges agree', [
    'render(40)', 'inventory.editMode=true; render(40)',
    'inventory.editState.highlightCategory="weapons"; item.bagshuiCategoryId="weapons"; render(40)',
    'inventory.editMode=false; render(40)',
])

compare('skin edge, texture, insets, replacement and external scale changes invalidate geometry', [
    'render(40)', 'BsSkin.itemSlotEdgeSize=2; render(40)',
    'button.bagshuiData.borderBackdropTable.edgeFile="new border"; render(40)',
    'button.bagshuiData.borderBackdropTable.insets.left=2; render(40)',
    'button.bagshuiData.borderBackdropTable.tile=true; button.bagshuiData.borderBackdropTable.tileSize=4; render(40)',
    'button.bagshuiData.buttonComponents.border=object("Frame","newBorder",button); render(40)',
    'button.bagshuiData.buttonComponents.border:SetBackdrop({edgeFile="external",edgeSize=7}); render(40)',
    'button.scale=2; render(40)', 'BsSkin.itemSlotBorderInverseScale=false; render(40)',
    'BsSkin.itemSlotBorderInverseScale=true; render(40)',
])

compare('standalone sizing restores colors immediately and respects border opt out', [
    'ui:AssignItemToItemButton(button,item,"g"); ui:SetItemButtonSize(button,40)',
    'ui:SetItemButtonSize(button,40)', 'button.bagshuiData.noBorderScale=true; ui:SetItemButtonSize(button,48)',
    'button.bagshuiData.noBorderScale=nil; ui:SetItemButtonSize(button,48)',
])

compare('empty slots, item replacement and bag/slot moves agree', [
    'render(40)', 'item.id=2; item.itemString="item:2"; item.texture="axe"; item.slotNum=2; render(40)',
    'item.id=0; item.emptySlot=1; item.itemString=nil; item.texture=nil; item.count=0; item.quality=-1; render(40)',
    'inventory.settings.emptySlotBackgroundImage=false; inventory.settings.emptySlotBackgroundColor={0.2,0.3,0.4,0.5}; render(40)',
])

check('font contract rejects uninitialized and failed fonts in affected count writes', r'''
local f=object('FontString','invalid')
assert(not pcall(function() f:SetText('') end))
failedFontPaths.missing=true; assert(not f:SetFont('missing',12))
assert(not pcall(function() f:SetText('1') end))
f:SetFontObject('GameFontNormal'); f:SetText('1'); assert(f.text=='1')
''')

print(f'PASS: {len(checks)} rule/UI behavior groups against real functions; original-build differential checks passed')
print('WORK COUNTS: rule argument helpers 50 -> 0 per call; two stable layouts: colors 4 -> 2, backdrops 2 -> 1; texture/count/cooldown hooks retained')
