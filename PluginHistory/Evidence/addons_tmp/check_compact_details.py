from pathlib import Path
import sys,re,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).parent/'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
ROOT=Path(r'E:\1.18\Interface\AddOns')
BACKUP=Path(r'E:\1.18\addons_tmp\dpsmatex-compact-details-backup-20261006')
lua=LuaRuntime(unpack_returned_tuples=True)
compile=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')
errors=[];count=0
for a in ['DPSMateX','DPSMateXExtend','DPSMateXExtendMore','DPSMateXInsights','DPSMateXEncounters']:
    for p in (ROOT/a).rglob('*.lua'):
        ok,error=compile(p.read_text(encoding='utf-8-sig'),str(p))
        if not ok:errors.append(error)
        count+=1
print('Lua compile:',count,'files',len(errors),'errors')
for error in errors:print(error)
ns={'u':'http://www.blizzard.com/wow/ui/'}
for old in BACKUP.rglob('*Details*.xml'):
    p=ROOT/old.relative_to(BACKUP);root=ET.parse(p).getroot()
    bad=[e.get('name','') or e.get('relativeTo','') for e in root.iter()
        if re.search(r'_(DiagramLine|DiagramLegend|SwitchGraph|Individual|Graph)$',e.get('name','')+' '+e.get('relativeTo',''))]
    if bad:errors.append(str(p)+' graph anchor: '+repr(bad))
    for f in root.findall('u:Frame',ns):
        if f.get('virtual')=='true':continue
        size=f.find('u:Size',ns)
        if size is not None and float(size.get('y','0'))<=0:errors.append(str(p)+' invalid size')
print('XML compact layouts:',len(list(BACKUP.rglob('*Details*.xml'))),'files')
if errors:raise SystemExit('\n'.join(errors))

# Build only XML-backed globals: deleted graph controls must never be accessed.
lua.execute('''
objects={};UISpecialFrames={};UIParent={GetScale=function() return 1 end}
local F={}
function F:GetName() return self.name end
function F:GetText() return self.text or "" end
function F:SetText(v) self.text=v end
function F:CreateTexture() return setmetatable({},{__index=F}) end
function F:Show() self.shown=true end
function F:Hide() self.shown=false end
setmetatable(F,{__index=function(t,k) local fn=function() end;rawset(t,k,fn);return fn end})
function object(name) if not objects[name] then objects[name]=setmetatable({name=name},{__index=F});_G[name]=objects[name] end;return objects[name] end
function getglobal(name) assert(objects[name],"Unknown UI object "..name);return objects[name] end
DPSMateX={Modules={},RegistredModules={},Options={graph={}},CombatTime={total=10,current=10,effective={{Compare=4},{Compare=4}}},Settings={targetscale=0.58,mergepets=false,windows={{CurMode="damage"}}},
  CacheUser={Tester={1,"Tester"},Compare={2,"Compare"}},DBCache={EDT={},EDD={},HealingTaken={},DamageDone={},DamageTaken={}},DB={}}
setmetatable(DPSMateX.L or {},{__index=function(t,k) return k end})
DPSMateX.L=setmetatable({},{__index=function(t,k) return k end})
local D=DPSMateX
function D:GetMode() return {},10,{Tester=5,Compare=4} end
function D:GetModeByArr() return {} end
function D:GetSelectedEffectiveTime() return {Tester=5,Compare=4} end
function D:EvalTable() return {},0,{},{} end
function D:TableLength(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
function D:CopyTable(t) return t end
function D.DB:GetPetsName() return {} end
function D:GetClassColor() return 1,1,1,"PRIEST" end
function D:GetUserById(id) return id==1 and "Tester" or "Compare" end
function D:GetAbilityById() return "Spell" end
function D:Round(v) return v end
function FauxScrollFrame_Update() end
function FauxScrollFrame_GetOffset() return 0 end
ceil=math.ceil;floor=math.floor;strlower=string.lower;GameTooltip=object("GameTooltip")
pieCount=0;gridCount=0
function D.Options.graph:CreateGraphLine() error("Unexpected line graph") end
function D.Options.graph:CreateStackedGraph() error("Unexpected stacked graph") end
function D.Options.graph:CreateGraphPieChart() pieCount=pieCount+1;local g=object("Pie"..pieCount);g.ResetPie=function() end;g.AddPie=function() end;return g end
function D.Options.graph:DrawLine() gridCount=gridCount+1;return object("Grid"..gridCount) end
''')

def adapt(s):
    # Lua 5.0 generic iteration is implicit pairs; Lua 5.1 needs an explicit iterator.
    return re.sub(r'for ([\w, ]+) in ([\w.\[\]"\(\)]+) do',lambda m:'for '+m[1]+' in pairs('+m[2]+') do' if not re.search(r'\b(?:pairs|ipairs|next)\(',m[2]) else m[0],s)

def register_tree(e,parent='',templates=None,seen=None):
    name=e.get('name');name=name.replace('$parent',parent) if name else parent
    if e.get('name'):lua.globals().object(name)
    if e.get('inherits') in templates:
        inherit=e.get('inherits')
        if inherit not in seen:
            for n in templates[inherit]:register_tree(n,name,templates,seen|{inherit})
    for n in e:register_tree(n,name,templates,seen)

core=(ROOT/'DPSMateX/DPSMateX.lua').read_text(encoding='utf-8-sig')
lua.execute(core[core.index('DPSMateX.DetailLayout ='):core.index('function DPSMateX:ReleaseDetailTimelines')])
checked=0
for old in BACKUP.rglob('*Details*.lua'):
    p=ROOT/old.relative_to(BACKUP);xml=p.with_suffix('.xml')
    if not xml.exists():continue
    root=ET.parse(xml).getroot()
    templates={e.get('name'):e for e in root if e.get('virtual')=='true'}
    for e in root:
        if e.get('virtual')!='true':register_tree(e,'',templates,set())
    source=p.read_text(encoding='utf-8-sig');lua.execute(adapt(source))
    module=re.search(r'DPSMateX.Modules.(\w+) = \{\}',source)[1]
    # Run opening/comparison with real initialization, stubbing only data list renderers.
    lua.execute('''
    m=DPSMateX.Modules['''+repr(module)+''']
    for k,v in pairs(m) do
      if type(v)=="function" and k~="UpdateDetails" and k~="UpdateCompare" and k~="UpdatePie" and k~="CreateGraphTable" then
        if k=="EvalToggleTable" or k=="SortTable" then m[k]=function() return {},{},0 end
        else m[k]=function() end end
      end
    end
    ''')
    try:
        lua.execute('m:UpdateDetails({user="Tester"},1);firstGrid=gridCount;m:UpdateDetails({user="Tester"},1);assert(gridCount==firstGrid,"Numeric grid recreated");if m.UpdateCompare then m:UpdateCompare({user="Tester"},1,"Compare") end')
    except Exception as ex:errors.append(module+': '+str(ex))
    checked+=1
print('Legacy detail opening/comparison:',checked,'modules',len(errors),'errors')
if errors:raise SystemExit('\n'.join(errors))
