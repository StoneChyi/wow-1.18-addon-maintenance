"""Inventory actual Automaton TOC module options against the native renderer.
All TOC sources load as actual Lua. AceDB and CVar storage are explicit test
models; optional business libraries are opaque handles, not permissive no-ops.
Five standalone gameplay windows have declared initialization boundaries;
actual declared option factories still run. Execute/free-text command actions
are intercepted only to verify UI routing, never claimed as gameplay coverage.
No user SavedVariables are read or changed.
"""
from pathlib import Path
import sys, json, hashlib, argparse, subprocess
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK
SETUP=r'''
MAX_PARTY_MEMBERS=4;MAX_RAID_MEMBERS=40
UIParent=obj('Frame');WorldFrame=UIParent
local native=getmetatable(UIParent).__index
function native:SetOwner(owner,anchor)self.owner=owner;self.anchor=anchor end
function native:AddFontStrings(a,b)self.lines=self.lines or {};table.insert(self.lines,{a,b})end
function native:SetVertexColor(...)self.vertex={unpack(arg)}end
function native:SetDrawLayer(layer)self.layer=layer end
function native:SetTextHeight(height)self.textHeight=height end
ParserLib={GetInstance=function(_,version)assert(version=='1.1');return {}end}
 DEFAULT_CHAT_FRAME={AddMessage=function()end}
StaticPopupDialogs={}
function TEXT(text)return text end
SlashCmdList={};floor=math.floor;ceil=math.ceil;format=string.format;getn=table.getn;mod=math.mod;strlower=string.lower
function GetLocale()return 'zhCN'end
function GetTime()return 100 end
cvars={}
function GetCVar(name)return cvars[name] or '1'end
function SetCVar(name,value)cvars[name]=tostring(value)end
superState={}
function Clickthrough(v)superState.clickthrough=v end
function SetAutoloot(v)superState.autoloot=v end
function IsShiftKeyDown()return false end
SPELL_FAILED_ONLY_SHAPESHIFT='Requires %s'
LOOT='Loot';LOOT_FREE_FOR_ALL='Free';LOOT_ROUND_ROBIN='Round';LOOT_MASTER_LOOTER='Master';LOOT_GROUP_LOOT='Group';LOOT_NEED_BEFORE_GREED='Need'

function UnitLevel()return 60 end
function UnitFactionGroup()return 'Alliance'end
function GetRealmName()return 'TestRealm'end
function GetScreenWidth()return 1920 end
function GetScreenHeight()return 1080 end
function GetNumSavedInstances()return 0 end
function GetNumShapeshiftForms()return 0 end
function GetNumSpellTabs()return 0 end
function GetSpellTabInfo()return '',nil,0,0 end
function GetBuildInfo()return '1.12.1','5875','Sep 2006',11200 end
SPELL_FAILED_NOT_STANDING='not standing';ERR_CANTATTACK_NOTSTANDING='attack standing';ERR_LOOT_NOTSTANDING='loot standing';ERR_TAXINOTSTANDING='taxi standing'
function LibStub(name)assert(name=='LibItem-enUS-1.0');return {Item_enUS={}}end
function GetNumSkillLines()return 0 end
function GetNumGroupMembers()return 0 end
function GetSpellName()return nil end
function GetItemInfo(id)return 'Item '..tostring(id)end
function GetAddOnMetadata()return nil end
function IsAddOnLoaded()return false end
function UnitExists()return false end
function UnitIsPlayer()return false end
function InCombatLockdown()return false end
function GetUnitName()return 'TestPlayer'end
function UnitRace()return 'Human','Human'end
function CreateColor()error('modern API unavailable')end
local new=Automaton.NewModule
function Automaton:NewModule(name)
 local m=new(self,name)
 m.events={};m.commands={}
 function m:RegisterEvent(name,handler)self.events[name]=handler or name end
 function m:UnregisterEvent(name)self.events[name]=nil end
 function m:IsEventRegistered(name)return self.events[name]~=nil end
 function m:RegisterChatCommand(cmd,options)self.commands[cmd]=options end
 function m:RegisterOptions(opts)
  opts=opts or {};opts.enabled={type='toggle',name='Enabled',get=function()return Automaton:IsModuleActive(name)end,set=function(v)Automaton:ToggleModuleActive(name,v)end}
  self._options=opts
 end
 return m
end
Automaton.disabled={}
function Automaton:IsModuleActive(name)return not self.disabled[name]end
function Automaton:ToggleModuleActive(name,state)self.disabled[name]=not state end
function Automaton:Print()end
function Automaton:RegisterChatCommand()end
local oldDefaults=Automaton.RegisterDefaults
function Automaton:RegisterDefaults(name,scope,defaults)
 self:AcquireDBNamespace(name)[scope]=self:AcquireDBNamespace(name)[scope] or {}
 oldDefaults(self,name,scope,defaults)
 self.dbs[name].defaults=self.dbs[name].defaults or {};self.dbs[name].defaults[scope]=defaults
end
function AceLibrary(lib)
 if lib=='Babble-Boss-2.2' then return setmetatable({}, {__index=function(_,key)return key end})end
 if lib~='AceLocale-2.2' then
  if lib=='Abacus-2.0' or lib=='Gratuity-2.0' or lib=='Compost-2.0' or lib=='Deformat-2.0' or lib=='Babble-Boss-2.2' then
   return setmetatable({}, {__index=function(_,key)error('unmodeled library method '..lib..':'..key)end})
  end
  error('unmodeled library '..lib)
 end
 return {new=function()
  return setmetatable({RegisterTranslations=function(self,locale,fn)
   local t=fn();if locale=='zhCN' then for k,v in pairs(t)do self[k]=v end end
  end},{__index=function(_,key)return key end})
 end}
end
local call=AceLibrary
AceLibrary=setmetatable({HasInstance=function(_,name)return name=='Gratuity-2.0'end},{__call=function(_,...)return call(unpack(arg))end})
function exercise()
 local result={}
 for _,row in ipairs(rows())do
  local opt=row.option
  local item={name=tostring(type(opt.name)=='function' and opt.name() or opt.name),type=opt.type or 'text'}
  table.insert(result,item)
  if opt.type=='execute' then
   local original=opt.func;local calls=0
   opt.func=function()calls=calls+1 end
   click(row);opt.func=original;assert(calls==1,'action not routed exactly once')
   item.status='action routing only; gameplay not executed'
  elseif row.widget=='header' then item.status='display'
  elseif row.widget=='text' and opt.type=='text' and opt.set then
   local originalGet,originalSet=opt.get,opt.set
   local saved=originalGet and (opt.passValue~=nil and originalGet(opt.passValue) or originalGet()) or ''
   local text='catalog input';local calls=0;local stored=''
   opt.get=function()return stored end
   opt.set=function(a,b)
    calls=calls+1
    if opt.passValue~=nil then assert(a==opt.passValue);stored=b else stored=a end
   end
   edit(row,text);assert(calls==1 and stored==text,'text not routed exactly once')
   opt.get,opt.set=originalGet,originalSet;row.displayed=tostring(saved or '');row.input:SetText(row.displayed)
   item.status='text routing only; command side effects not executed'
  elseif not opt.set or not opt.get then item.status='no get/set pair'
  else
   local get=function()if opt.passValue~=nil then return opt.get(opt.passValue)end;return opt.get()end
   local expected
   local ok,err=pcall(function()
    if row.widget=='checkbox' then expected=not get();row.input:SetChecked(expected and 1 or nil);click(row)
    elseif row.widget=='dropdown' then
     row.input:UpdateMenu();local entry=row.input.menu[table.getn(row.input.menu)];assert(entry)
     for key,label in pairs(opt.validate)do if tostring(label)==entry.text then expected=type(key)=='number' and label or key end end
     assert(expected~=nil,'unknown dropdown label');entry.func()
    elseif row.widget=='text' then
     if opt.type=='range' or opt.type=='number' then expected=opt.max or ((tonumber(get())or 0)+1)
     else item.status='free text: read only (command effects require targeted scenario)';return end
     edit(row,tostring(expected))
    else item.status='type requires targeted test';return end
    item.readback=tostring(get());item.expected=tostring(expected)
    assert(item.readback==item.expected,'readback mismatch')
   end)
   item.status=item.status or (ok and 'callback/readback pass' or 'blocked callback')
   if not ok then item.reason=tostring(err)end
  end
 end
 return result
end
function readvalues(options)
 local values={}
 local function walk(opts,path)
  for key,opt in pairs(opts or {})do if type(opt)=='table' then
   local nextpath=path..'/'..tostring(key)
   if opt.get then
    local v=opt.passValue~=nil and opt.get(opt.passValue) or opt.get()
    values[nextpath]=type(v)..':'..tostring(v)
   end
   if opt.args then walk(opt.args,nextpath)end
  end end
 end
 walk(options,'');return values
end
function snapshot(options)
 local result={}
 local function visit(opts,path)
  for key,opt in pairs(opts or {})do
   if type(opt)=='table' then
    local route=path..'/'..tostring(key)
    table.insert(result,{path=route,type=opt.type or 'text',get=type(opt.get)=='function',set=type(opt.set)=='function',action=type(opt.func)=='function'})
    if opt.args then visit(opt.args,route)end
   end
  end
 end
 visit(options,'');return result
end
'''
def runtime():
 lua=LuaRuntime(unpack_returned_tuples=True)
 font=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
 lua.execute(MOCK,font);lua.execute(SETUP)
 source=(ROOT/'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8-sig')
 a=source.index('    function CreateConfig(');b=source.index('    local TabFrameOnMouseDown',a)
 lua.execute('local searchDB={}\n'+source[a:b]+'\npfUI.gui.CreateConfig=CreateConfig')
 lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf-8-sig'))
 return lua

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--module-ref',help='Read only the TOC and Automaton module sources from this Git commit; GUI/renderer remain working-tree code.')
 args=parser.parse_args()
 source_ref='working-tree'
 if args.module_ref:
  source_ref=subprocess.check_output(['git','rev-parse','--verify',args.module_ref+'^{commit}'],cwd=ROOT,text=True).strip()
 def read_module(relative):
  path='Interface/AddOns/Automatonex/'+relative.replace('\\','/')
  if args.module_ref:return subprocess.check_output(['git','show',source_ref+':'+path],cwd=ROOT)
  return (ROOT/path).read_bytes()
 report=[]
 toc=read_module('Automatonex.toc').decode('utf-8-sig')
 for rel in toc.splitlines():
  if not rel.startswith('Modules\\'):continue
  lua=runtime();entry={'file':rel};report.append(entry)
  if rel.endswith('CancelTiger.lua'):lua.execute("function UnitClass()return 'Hunter','HUNTER'end");entry['scenario']='Hunter'
  if rel.endswith('Superwow.lua'):lua.execute('SUPERWOW_VERSION=1');entry['scenario']='SuperWoW present'
  source=read_module(rel)
  entry['sha256']=hashlib.sha256(source).hexdigest()
  try:lua.execute(source.decode('utf-8-sig'))
  except Exception as e:entry['load_error']=str(e).split('stack traceback')[0].strip()
  modules=list(lua.globals().Automaton.modules.items());entry['modules']=[]
  for name,m in modules:
   item={'name':name};entry['modules'].append(item)
   try:
    if m.OnInitialize:m.OnInitialize(m)
   except Exception as e:item['init_error']=str(e).split('stack traceback')[0].strip()
   if m._options is None:
    if m.CreateOptions:
     try:m.CreateOptions(m);item['options_recovery']='real CreateOptions after unrelated init boundary'
     except Exception as e:item['options_error']=str(e).split('stack traceback')[0].strip()
    elif m.GetOptions:
     try:m.RegisterOptions(m,m.GetOptions(m));item['options_recovery']='real GetOptions after unrelated init boundary'
     except Exception as e:item['options_error']=str(e).split('stack traceback')[0].strip()
    elif m.options is not None:
     m.RegisterOptions(m,m.options);item['options_recovery']='declared options registered after unrelated init boundary'
   if m._options is None:
    item['options']='not registered';continue
   info=lua.globals().snapshot(m._options)
   item['options']=[dict(row.items()) for _,row in info.items()]
   try:
    renderer=lua.globals().pfUI.automationOptions
    renderer.Render(renderer,lua.globals().parent,m,None)
    item['render']='pass'
    item['interaction']=[dict(v.items()) for _,v in lua.globals().exercise().items()]
    before=dict(lua.globals().readvalues(m._options).items())
    renderer.Render(renderer,lua.globals().parent,m,None)
    assert before==dict(lua.globals().readvalues(m._options).items()),'redraw mutated saved values'
    item['redraw_readback']='pass'
   except Exception as e:item['render_error']=str(e).split('stack traceback')[0].strip()
 suffix=source_ref[:12] if args.module_ref else 'working-tree'
 out=ROOT/('PluginHistory/staging/automation-catalog-audit-'+suffix+'.json')
 out.write_text(json.dumps({'source_ref':source_ref,'requested_module_ref':args.module_ref,'gui_renderer_source':'working-tree','modules':report},ensure_ascii=False,indent=2),encoding='utf8')
 for entry in report:
  if entry.get('load_error'):raise AssertionError((entry['file'],entry['load_error']))
  for m in entry['modules']:
   if m.get('init_error'):
    expected={'Trainer':"RegisterEvent",'AutoDB':"SetMovable",'Boomtime':"FLAT",'KneelToQueen':"SetBackdropColor",'LegionShackles':"SetBackdropColor"}
    assert m['name'] in expected and expected[m['name']] in m['init_error'],('new initialization boundary',m['name'],m['init_error'])
   assert m.get('render')=='pass',(m['name'],m.get('render_error'),m.get('options'))
   assert m.get('redraw_readback')=='pass',(m['name'],m.get('render_error'))
   assert all(v['status']!='blocked callback' for v in m.get('interaction',[])),(m['name'],m['interaction'])
 import collections
 counts=collections.Counter(v['status'] for e in report for m in e['modules'] for v in m.get('interaction',[]))
 print(json.dumps({'source_ref':source_ref,'gui_renderer_source':'working-tree','sources':len(report),'modules':sum(len(e['modules']) for e in report),'options':sum(len(m['options']) for e in report for m in e['modules']),'checks':dict(counts),'init_boundaries':[m['name'] for e in report for m in e['modules'] if m.get('init_error')],'report':str(out)},ensure_ascii=True))
if __name__=='__main__':main()
