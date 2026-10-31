"""Render the actual Automaton catalog together on one expanded pfUI page.

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
  for key,value in pairs(originalValues[name]) do assert(values[key]==value,'redraw changed '..name..key) end
  for key,value in pairs(values) do assert(originalValues[name][key]==value,'redraw added '..name..key) end
 end
 assert(C.automation.selected=='legacy selection','render replaced legacy selection')
end
local function visible(opt)
 local hidden=opt.hidden
 if type(hidden)=='function' then hidden=hidden() end
 return not hidden
end
local function get(opt)
 if opt.passValue~=nil then return opt.get(opt.passValue) end
 return opt.get()
end
local function inspect(options, expectedGroups)
 local expected,groups,optionCount,hiddenCount={},0,0,0
 local function walk(args)
  for _,opt in pairs(args) do
   if type(opt)=='table' then
    optionCount=optionCount+1
    if visible(opt) then
     expected[opt]=(expected[opt] or 0)+1
     if opt.args then walk(opt.args) end
    else hiddenCount=hiddenCount+1 end
   end
  end
 end
 for _,entry in ipairs(h:ModuleList(true,'all')) do
  local group=options['module_'..entry.name]
  assert(group and group.moduleName==entry.name,'missing module group '..entry.name)
  groups=groups+1
  for key,opt in pairs(entry.module._options) do
   assert(group.args[key]==opt,'original option identity lost '..entry.name..':'..tostring(key))
  end
  walk(entry.module._options)
 end
 assert(groups==(expectedGroups or 55) and not options.module_Repair and not options.module_Sell)
 local actual,headers,previous,controls,readbacks={},0,-1,0,0
 for _,row in ipairs(rows()) do
  actual[row.option]=(actual[row.option] or 0)+1
  if row.option.moduleName then headers=headers+1 end
  assert(row.automationOffset>=previous,'expanded rows overlap or move backwards')
  previous=row.automationOffset+row:GetHeight()
  if row.input or row.button or row.color then controls=controls+1 end
  if expected[row.option] and row.option.get then
   local value=get(row.option)
   if row.widget=='checkbox' then
    assert((not not row.input:GetChecked())==(not not value),'checkbox readback differs from original getter')
   elseif row.widget=='text' then
    assert(row.input:GetText()==tostring(value or ''),'text readback differs from original getter')
   elseif row.widget=='dropdown' then
    local label=tostring(value or '')
    for key,text in pairs(row.option.validate) do
     local choice=type(key)=='number' and text or key
     if choice==value then label=tostring(text) end
    end
    assert(row.input.text:GetText()==label,'dropdown readback differs from original getter')
   elseif row.widget=='color' then
    local r,g,b,a=get(row.option)
    local actual=row.color.prev.texture
    assert(actual[1]==(r or 1) and actual[2]==(g or 1) and actual[3]==(b or 1) and actual[4]==(a or 1),
     'color readback differs from original getter')
   else error('unverified original getter widget '..row.widget) end
   readbacks=readbacks+1
  end
 end
 assert(headers==groups,'missing visible module heading')
 for opt,count in pairs(expected) do assert(actual[opt]==count,'missing original rendered option '..tostring(opt.name)) end
 assert(parent:GetHeight()>10000 and parent:GetHeight()>=previous,'long page height truncated')
 assert(parent.parent:GetVerticalScrollRange()>10000,'long page has no scroll range')
 return {groups=groups,original_options=optionCount,hidden_options=hiddenCount,
  rows=table.getn(rows()),controls=controls,height=parent:GetHeight(),original_value_readbacks=readbacks}
end
local options=h:FeatureOptions('all')
assert(R:Render(parent,{_options=options}));report=inspect(options);unchanged()
local firstCreated=created
local firstRows={}
for index,row in ipairs(rows()) do firstRows[index]=row end
for iteration=1,5 do
 local fresh=h:FeatureOptions('all')
 assert(R:Render(parent,{_options=fresh}));inspect(fresh);unchanged()
 assert(created==firstCreated,'identical expanded redraw allocated additional UI objects')
 for index,row in ipairs(rows()) do assert(row==firstRows[index],'stable expanded row was not reused') end
end
report.redraws=5
-- Reuse the same pool for a category and return to the longest page. Every
-- original option must recover its own callbacks/value after row rebinding.
local narrow=h:FeatureOptions('quest')
assert(R:Render(parent,{_options=narrow}));unchanged()
local fresh=h:FeatureOptions('all')
assert(R:Render(parent,{_options=fresh}));inspect(fresh);unchanged()
assert(created==firstCreated,'category round-trip leaked pooled UI objects')
report.category_roundtrips=1
report.created_objects=created
-- Model the host's declared ownership flags only: the native integration
-- engines themselves are covered by their separate suites. These three
-- modules retain their original settings while leaving this page entirely.
pfUI.automationIntegrations={Tooltip={managed=true},ExpBar={managed=true},InterPlayerLink={managed=true}}
local poolSizes,actionLabels={},{}
for widget,pool in pairs(parent.automationOptionsState.pool) do
 poolSizes[widget]=table.getn(pool)
 for _,row in ipairs(pool) do if row.actionLabel then actionLabels[row.actionLabel]=true end end
end
local managedCreated
for iteration=1,3 do
 local managed=h:FeatureOptions('all')
 assert(not managed.module_Tooltip and not managed.module_ExpBar and not managed.module_InterPlayerLink)
 assert(R:Render(parent,{_options=managed}));local result=inspect(managed,52);unchanged()
 report.managed_groups=result.groups;report.managed_rows=result.rows
 report.managed_original_options=result.original_options
 report.managed_original_value_readbacks=result.original_value_readbacks
 assert(R:Render(parent,{_options=h:FeatureOptions('quest')}));unchanged()
 assert(R:Render(parent,{_options=h:FeatureOptions('all')}));unchanged()
 for widget,pool in pairs(parent.automationOptionsState.pool) do
  assert(table.getn(pool)==poolSizes[widget],'managed category round-trip allocated new pooled rows')
 end
 -- A reused execute row can lazily acquire its optional action label when
 -- ownership changes which original option occupies that button slot.
 if not managedCreated then managedCreated=created
 else assert(created==managedCreated,'repeated managed round-trip leaked UI objects') end
end
report.managed_category_roundtrips=3
report.managed_warmup_objects=managedCreated-firstCreated
report.final_created_objects=created
local addedLabels=0
for _,pool in pairs(parent.automationOptionsState.pool) do
 for _,row in ipairs(pool) do
  local label=row.actionLabel
  if label and not actionLabels[label] then
   assert(label.kind=='FontString' and label:GetParent()==row,'unexpected lazy action label object')
   addedLabels=addedLabels+1
  end
 end
end
assert(addedLabels==report.managed_warmup_objects,'new objects were not fully accounted for by action labels')
report.managed_new_action_labels=addedLabels
''')
    report = dict(lua.globals().report.items())
    report.update(sources=len(sources), modules=57, excluded=['Repair', 'Sell'],
                  managed_excluded=['Tooltip', 'ExpBar', 'InterPlayerLink'],
                  init_boundaries=sorted(boundaries),
                  boundary='offline UI/AceDB/CVar model; no gameplay actions or live-game acceptance')
    print(json.dumps(report, ensure_ascii=True, sort_keys=True))


if __name__ == '__main__':
    main()
