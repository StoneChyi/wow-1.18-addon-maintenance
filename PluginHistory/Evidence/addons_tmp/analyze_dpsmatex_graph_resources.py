from pathlib import Path
import re,json,sys
root=Path(r'E:/1.18')
sys.path.insert(0,str(root/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
graph=(root/'Interface/AddOns/DPSMateX/libs/GraphLib/Graph-1.0/Graph-1.0.lua').read_text(encoding='utf-8-sig')
# Adapt only the obsolete Lua 5.0 iterator used by this path, for the offline runtime.
graph=graph.replace('for uuu, zzz in self.DataPoints do','for uuu, zzz in pairs(self.DataPoints) do')
start=graph.index('function lib:DrawLine(C,')
end=graph.index('function lib:DrawVLine',start)
part=graph[start:end].replace('for k,v in pairs(C.GraphLib_Lines) do','for k,v in pairs(C.GraphLib_Lines) do walk_count=walk_count+1',1)
graph=graph[:start]+part+graph[end:]
def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
counts={Frame=0,Texture=0,FontString=0};walk_count=0
sqrt=math.sqrt;ceil=math.ceil;floor=math.floor;tinsert=table.insert;tremove=table.remove;gsub=string.gsub
getn=table.getn
TAXIROUTE_LINEFACTOR_2=0.5
AceLibrary={IsNewVersion=function() return true end,Register=function(self,lib) graphlib=lib end}
local methods={}
function methods:GetName() return self.name end
function methods:SetHeight(n) self.height=n end
function methods:SetWidth(n) self.width=n end
function methods:GetHeight() return self.height or 230 end
function methods:GetWidth() return self.width or 950 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:CreateTexture(name) return newObject("Texture",name,self) end
function methods:CreateFontString(name) return newObject("FontString",name,self) end
function newObject(kind,name,parent)
 counts[kind]=counts[kind]+1
 return setmetatable({name=name or (kind..counts[kind]),shown=true,parent=parent,scripts={}},
 {__index=function(o,key)
  if methods[key] then return methods[key] end
  if string.find(key,"^Set") or string.find(key,"^Clear") or string.find(key,"^Enable") then return function() end end
 end})
end
function CreateFrame(kind,name,parent) return newObject("Frame",name,parent) end
function GetTime() return 0 end
function GetCursorPosition() return 0,0 end
function MouseIsOver() return false end
UIParent=CreateFrame("Frame","UIParent")
''')
    lua.execute(graph)
    return lua
results=[]
for n in (20,100,199):
    lua=runtime()
    lua.execute('''
g=graphlib:CreateGraphLine("MeasuredGraph",UIParent,"CENTER","CENTER",0,0,950,230)
g:SetAutoScale(true);g:SetYLabels(true,false);g:SetXLabels(true)
points={{0,0}};for i=1,... do points[#points+1]={i,100+math.mod(i,17)*23,false} end
g:AddDataSeries(points,{{1,0,0,0.8},{1,1,0,0.8}},{})
g:RefreshGraph()
''',n)
    first=int(lua.globals().walk_count)
    obj={k:int(lua.globals().counts[k]) for k in ('Frame','Texture','FontString')}
    lua.execute('walk_count=0;g:RefreshGraph()')
    repeat=int(lua.globals().walk_count)
    same=all(obj[k]==int(lua.globals().counts[k]) for k in obj)
    obj['Frame']-=1 # Exclude UIParent.
    results.append({'segments':n,'objects':obj,'first_line_pool_visits':first,'repeat_line_pool_visits':repeat,'objects_reused':same})
lua=runtime()
lua.execute('''
p=graphlib:CreateGraphPieChart("Pie",UIParent,"CENTER","CENTER",0,0,200,200)
p:ResetPie()
for i,value in ipairs({42.2,23.9,12.2,8.3,6,5.6,1.9}) do p:AddPie(value,nil,"skill"..i) end
''')
pie={k:int(lua.globals().counts[k]) for k in ('Frame','Texture','FontString')};pie['Frame']-=1
# Count serialized per-second table entries using tokens only: never execute saved files.
token=re.compile(r'"(?:\\.|[^"\\])*"|--[^\n]*|[{}]|[^{}"]+',re.S)
def end_table(text,start):
    depth=0
    for m in token.finditer(text,start):
        if m[0]=='{': depth+=1
        elif m[0]=='}':
            depth-=1
            if depth==0: return m.end()
    raise ValueError('unbalanced saved table')
def saved_sample(path):
    text=path.read_text(encoding='utf-8-sig');rows={}
    variables=['DPSMateXDamageDone','DPSMateXDamageTaken','DPSMateXEDD','DPSMateXEDT','DPSMateXTHealing','DPSMateXEHealing','DPSMateXHealingTaken','DPSMateXEHealingTaken','DPSMateXOverhealing','DPSMateXOverhealingTaken']
    for name in variables:
        found=re.search(r'(?m)^'+name+r'\s*=\s*\{',text)
        if not found: continue
        a=text.index('{',found.start());b=end_table(text,a);section=text[a:b]
        count=0;size=0;tables=0
        for i in re.finditer(r'\["i"\]\s*=\s*\{',section):
            begin=section.index('{',i.start());finish=end_table(section,begin);body=section[begin:finish]
            # Ignore special event tables; selected amount categories contain numeric bins.
            if re.search(r'\[\d+\]\s*=\s*\{',body): continue
            n=len(re.findall(r'\[\d+\]\s*=\s*-?[\d.]+',body))
            count+=n;size+=len(body.encode('utf-8'));tables+=1
        if count: rows[name]={'bins':count,'serialized_bin_table_bytes':size,'tables':tables}
    return {'file_bytes':path.stat().st_size,'amount_categories':rows,'total_bins':sum(x['bins'] for x in rows.values()),'serialized_bin_table_bytes':sum(x['serialized_bin_table_bytes'] for x in rows.values())}
paths=list((root/'WTF').rglob('DPSMateX.lua'))
paths=[p for p in paths if p.parent.parent.name=='兼职奶骑']
paths.sort(key=lambda p:p.stat().st_mtime,reverse=True)
samples=[saved_sample(p) for p in paths[:1]]
report={'measurement':'Actual bundled GraphLib with mock UI objects; counts are not game memory, FPS or CPU timings.','line_examples':results,'seven_skill_pie':pie,'latest_matching_character_saved_sample':samples}
out=root/'addons_tmp/dpsmatex-graph-resource-audit-20261006.json'
out.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
