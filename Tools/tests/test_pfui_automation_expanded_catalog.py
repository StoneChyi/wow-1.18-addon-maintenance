"""Audit each actual Automaton module in the shared pfUI details pane.

Uses the catalog's explicit AceDB/CVar and UI boundary, with its five declared
standalone-window initialization boundaries. Gameplay actions are not run.
No user SavedVariables are read or changed; this is not live-client acceptance.
"""
import json

from test_pfui_automation_catalog import ROOT, runtime


EXPECTED_BOUNDARIES = {
    'Trainer': 'RegisterEvent',
    'AutoDB': 'SetMovable',
    'Boomtime': 'FLAT',
    'KneelToQueen': 'SetBackdropColor',
    'LegionShackles': 'SetBackdropColor',
}


def main():
    lua = runtime()
    addon = ROOT / 'Interface/AddOns/Automatonex'
    sources = [line for line in (addon / 'Automatonex.toc').read_text(
        encoding='utf-8-sig').splitlines() if line.startswith('Modules\\')]
    boundaries = {}
    for relative in sources:
        # Match the original catalog's class-gated and optional-client cases.
        if relative.endswith('CancelTiger.lua'):
            lua.execute("savedUnitClass=UnitClass;function UnitClass()return 'Hunter','HUNTER'end")
        if relative.endswith('Superwow.lua'):
            lua.execute('SUPERWOW_VERSION=1')
        before = set(lua.globals().Automaton.modules.keys())
        lua.execute((addon / relative.replace('\\', '/')).read_text(encoding='utf-8-sig'))
        for name, module in lua.globals().Automaton.modules.items():
            if name in before:
                continue
            try:
                if module.OnInitialize:
                    module.OnInitialize(module)
            except Exception as error:
                message = str(error).split('stack traceback')[0].strip()
                assert name in EXPECTED_BOUNDARIES and EXPECTED_BOUNDARIES[name] in message, (
                    'new initialization boundary', name, message)
                boundaries[name] = message
            if module._options is None:
                if module.CreateOptions:
                    module.CreateOptions(module)
                elif module.GetOptions:
                    module.RegisterOptions(module, module.GetOptions(module))
                elif module.options is not None:
                    module.RegisterOptions(module, module.options)
            assert module._options is not None, ('missing original options', name)
        if relative.endswith('CancelTiger.lua'):
            lua.execute('UnitClass=savedUnitClass;savedUnitClass=nil')

    assert len(sources) == 57 and len(list(lua.globals().Automaton.modules.keys())) == 57
    assert set(boundaries) == set(EXPECTED_BOUNDARIES), ('changed initialization boundaries', boundaries)
    # The actual host needs event registration but no GUI navigation for this
    # direct FeatureOptions + renderer check. Install after initialization so
    # this does not silently bypass the catalog's Trainer window boundary.
    lua.execute(r'''
local methods=getmetatable(parent).__index
function methods:RegisterEvent(event)
 self.events=self.events or {};self.events[event]=true
end
Automaton.db={char={hiddenModules={}},profile={moduleScope='char'}}
function Automaton:IsModuleHidden(name)return self.db.char.hiddenModules[name]end
function Automaton:GetModuleScope()return self.db.profile.moduleScope end
C.automation={enabled='1',selected='legacy selection'}
''')
    lua.execute((ROOT / 'Interface/AddOns/pfUI/modules/automation.lua').read_text(encoding='utf-8-sig'))
    lua.execute(r'''
local h,R=pfUI.automation,pfUI.automationOptions
local originalValues={}
for name,module in pairs(Automaton.modules) do originalValues[name]=readvalues(module._options) end
local function unchanged()
 for name,module in pairs(Automaton.modules) do
  local values=readvalues(module._options)
  for key,value in pairs(originalValues[name]) do assert(values[key]==value,'navigation changed '..name..key) end
  for key,value in pairs(values) do assert(originalValues[name][key]==value,'navigation added '..name..key) end
 end
 assert(C.automation.selected=='legacy selection','render changed legacy selection')
end
local function get(opt)
 if opt.passValue~=nil then return opt.get(opt.passValue) end
 return opt.get()
end
local coveredModules={}
local function inspect(name)
 local options=h:ModuleOptions(name)
 local originals={}
 for _,group in pairs(options) do
  if group.type=='group' and group.moduleName then
   local id=group.moduleName
   local module=assert(Automaton.modules[id],'unknown original module '..id)
   assert(not originals[id],'duplicate original module '..id)
   originals[id]=module
   coveredModules[id]=true
   for key,opt in pairs(module._options) do assert(group.args[key]==opt,'original option identity lost '..id..':'..key) end
  end
 end
 assert(next(originals),'page has no original modules '..name)
 assert(R:Render(parent,{_options=options}))
 local expected,optionCount={},0
 local function walk(args)
  for _,opt in pairs(args) do if type(opt)=='table' then
   optionCount=optionCount+1
   local hidden=type(opt.hidden)=='function' and opt.hidden() or opt.hidden
   if not hidden then
    expected[opt]=(expected[opt]or 0)+1
    if opt.args then walk(opt.args) end
   end
  end end
 end
 for _,module in pairs(originals) do walk(module._options) end
 local actual,readbacks={},0
 for _,row in ipairs(rows()) do
  actual[row.option]=(actual[row.option]or 0)+1
  if expected[row.option] and row.option.get then
   local value=get(row.option)
   if row.widget=='checkbox' then assert((not not row.input:GetChecked())==(not not value))
   elseif row.widget=='text' then assert(row.input:GetText()==tostring(value or ''))
   elseif row.widget=='dropdown' then
    local label=tostring(value or '')
    for key,text in pairs(row.option.validate) do if (type(key)=='number' and text or key)==value then label=tostring(text) end end
    assert(row.input.text:GetText()==label)
   elseif row.widget=='color' then
    local r,g,b,a=get(row.option);local actual=row.color.prev.texture
    assert(actual[1]==(r or 1) and actual[2]==(g or 1) and actual[3]==(b or 1) and actual[4]==(a or 1))
   else error('unverified getter widget '..row.widget) end
   readbacks=readbacks+1
  end
 end
 for opt,count in pairs(expected) do assert(actual[opt]==count,'missing option '..name..':'..tostring(opt.name)) end
 unchanged()
 return optionCount,readbacks
end
local entries=h:NavigationEntries(true)
assert(#entries==53)
local totalOptions,totalReadbacks=0,0
for _,entry in ipairs(entries) do
 assert(entry.name~='Repair' and entry.name~='Sell')
 local opts,reads=inspect(entry.name)
 totalOptions=totalOptions+opts;totalReadbacks=totalReadbacks+reads
end
local coveredCount=0
for id,module in pairs(Automaton.modules) do
 if id~='Repair' and id~='Sell' then assert(coveredModules[id],'missing original module '..id);coveredCount=coveredCount+1 end
end
assert(coveredCount==55)
for _,id in ipairs({'Group','StrangerDecline','Invite','invall'}) do assert(coveredModules[id],'missing composed member '..id) end
-- Warm every shape, then alternate all actual modules through one row pool.
local warm=created
for pass=1,3 do
 for _,entry in ipairs(entries) do inspect(entry.name) end
 assert(created==warm,'revisiting module settings allocated new controls')
end
local opened={}
pfUI.automationIntegrations={}
for _,name in ipairs({'Tooltip','ExpBar','InterPlayerLink'}) do
 local id=name
 pfUI.automationIntegrations[id]={managed=true,title=id,OpenSettings=function()opened[id]=true end}
end
local managed=h:NavigationEntries(true);local shortcuts=0
assert(#managed==53,'native settings links disappeared from module navigation')
for _,entry in ipairs(managed) do if entry.native then
 shortcuts=shortcuts+1
 assert(not h:ModuleOptions(entry.name).module,'native engine settings duplicated')
 assert(h:SelectModule(entry.name) and opened[entry.name])
end end
assert(shortcuts==3);unchanged()
local management=h:GeneralOptions();assert(R:Render(parent,{_options=management}));unchanged()
local managedWarm=created
assert(R:Render(parent,{_options=h:GeneralOptions()}));assert(created==managedWarm)
report={module_pages=#entries,original_modules=coveredCount,original_options=totalOptions,original_value_readbacks=totalReadbacks,
 native_shortcuts=shortcuts,shared_detail_passes=3,created_objects=created}
''')
    report = dict(lua.globals().report.items())
    report.update(sources=len(sources), modules=57, excluded=['Repair', 'Sell'],
                  managed_shortcuts=['Tooltip', 'ExpBar', 'InterPlayerLink'],
                  init_boundaries=sorted(boundaries),
                  boundary='offline UI/AceDB/CVar model; no gameplay actions or live-game acceptance')
    print(json.dumps(report, ensure_ascii=True, sort_keys=True))


if __name__ == '__main__':
    main()
