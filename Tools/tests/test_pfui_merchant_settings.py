"""Merchant settings preserve Purchases storage and native pfUI controls.

Loads the real Purchases options and host. A final case renders the combined
merchant page with actual pfUI CreateConfig + automation renderer. No merchant
purchase is executed and no saved files are read or modified.
"""
from pathlib import Path
import unittest
from test_pfui_automation_host import ROOT, runtime

PURCHASES = ROOT / 'Interface/AddOns/Automatonex/Modules/Purchases.lua'
SETUP = r'''
function UnitName()return 'Healer'end
function GetRealmName()return 'Realm'end
function GetItemInfo(value)
 assert(type(value)=='string' and string.find(value,'item:',1,true),'native item metadata requires an item string')
 return 'Test reagent',value,1,1,'Reagent','Reagent',20
end
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)
  if locale=='zhCN'then for k,v in pairs(fn())do self[k]=v end end
 end},{__index=function(_,key)return key end})end}
end
saved={profile={
 Purchases_quantity={default=0,['Other-Realm']=200},Purchases_reagents={default={},['Other-Realm']={['101']='Other item'}},
 Purchases1_quantity={default=0},Purchases1_reagents={default={}},
 Purchases2_quantity={default=0},Purchases2_reagents={default={}}
}}
function Automaton:NewModule(name)
 local m=setmetatable({name=name},{__index=self.modulePrototype})
 function m:CancelScheduledEvent(id)assert(id=='Automaton_Restock');self.cancels=(self.cancels or 0)+1 end
 function m:Print(message)end
 self.modules[name]=m;return m
end
function Automaton:AcquireDBNamespace(name)assert(name=='Purchases');return saved end
function Automaton:RegisterDefaults(name,scope,values)
 for k,v in pairs(values)do if saved[scope][k]==nil then saved[scope][k]=v end end
end
function Automaton:SetDisabledAsDefault(module,name)self.db.char.disabledModules[name]=true end
C.global.buyemall='1'
pfUI.buyemall={cancels=0}
function pfUI.buyemall:CancelPurchases()self.cancels=self.cancels+1 end
'''


def host_runtime():
    lua=runtime(True)
    lua.execute(SETUP)
    lua.execute(PURCHASES.read_text(encoding='utf-8-sig'))
    lua.execute('M=Automaton.modules.Purchases;M:OnInitialize();h=pfUI.automation;h:Sync()')
    return lua


class MerchantSettings(unittest.TestCase):
    def test_original_category_objects_and_disabled_edits(self):
        lua=host_runtime()
        lua.execute(r'''
local options=h:MerchantOptions();local original=M._options
assert(options.restock.args==original and options.restock.moduleName=='Purchases')
local profile=M.db.profile
local savedOther=profile.Purchases_reagents['Other-Realm']
for i,group in ipairs({'original','category1','category2'})do
 local cat=({'Purchases','Purchases1','Purchases2'})[i]
 local opts=options.restock.args[group].args
 assert(opts==M._options[group].args,'category options copied instead of reused')
 opts.quantity.set(i*25);assert(opts.quantity.get()==i*25)
 opts.add.set(' 00123 ');assert(profile[cat..'_reagents']['Healer-Realm']['123']=='Test reagent')
 assert(not profile[cat..'_reagents']['Healer-Realm'][' 00123 '])
 opts.remove.set('123');assert(not profile[cat..'_reagents']['Healer-Realm']['123'])
 opts.add.set('123')
end
assert(M.db==saved and M.db.profile==profile)
assert(profile.Purchases_reagents['Other-Realm']==savedOther and savedOther['101']=='Other item')
assert(profile.Purchases_quantity['Other-Realm']==200)
assert(Automaton.db.char.disabledModules.Purchases and not M.restockActive)
assert(M.cancels and M.cancels>=9)
local before=profile.Purchases_quantity['Healer-Realm']
for _,value in ipairs({-1,301,1.5})do original.original.args.quantity.set(value)end
assert(profile.Purchases_quantity['Healer-Realm']==before)
''')

    def test_scope_and_native_bulk_config_are_independent(self):
        lua=host_runtime()
        lua.execute(r'''
local profile=M.db.profile;local list=profile.Purchases_reagents['Healer-Realm']
local options=h:MerchantOptions();assert(options.bulk.get())
options.bulk.set(false);assert(C.global.buyemall=='0' and pfUI.buyemall.cancels==1)
assert(Automaton.db.char.disabledModules.Purchases)
Automaton:ApplyModuleScope('account')
assert(Automaton.rawDisabled.Purchases and Automaton:GetModuleScope()=='account')
local current=h:MerchantOptions()
assert(current.restock.args==M._options and not current.bulk.get())
current.restock.args.original.args.quantity.set(125)
current.restock.args.original.args.add.set('123')
current.bulk.set(true);assert(C.global.buyemall=='1' and pfUI.buyemall.cancels==1)
Automaton:ApplyModuleScope('char')
assert(Automaton.db.char.disabledModules.Purchases and M.db.profile==profile)
assert(profile.Purchases_reagents['Healer-Realm']==list and list['123']=='Test reagent')
assert(profile.Purchases_quantity['Healer-Realm']==125)
assert(h:MerchantOptions().restock.args.original.args.quantity.get()==125)
''')

    def test_legacy_module_selection_uses_shared_merchant_page(self):
        lua=host_runtime()
        lua.execute(r'''
assert(Automaton:SelectModule('Purchases'))
assert(h.activePage==h.merchant and h.pages[h.merchant].options.restock.args==M._options)
h:OpenPage(h.general);assert(h:SelectModule('Purchases') and h.activePage==h.merchant)
h:OpenPage(h.general);pfUI.automationOptions.rejectPending=true
assert(h:SelectModule('Purchases')==false and h.activePage==h.general)
pfUI.automationOptions.rejectPending=nil
C.automation.enabled='0';h:Sync();Automaton:SelectModule('Purchases')
assert(Automaton.selectedModule=='Purchases' and h.activePage==h.general)
''')

    def test_combined_page_renders_original_controls_and_readbacks(self):
        from test_pfui_automation_catalog import runtime as render_runtime
        lua=render_runtime()
        lua.execute(PURCHASES.read_text(encoding='utf-8-sig'))
        lua.execute(r'''
M=Automaton.modules.Purchases;M:OnInitialize()
local methods=getmetatable(parent).__index
function methods:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
Automaton.db={char={hiddenModules={}},profile={moduleScope='char'}}
function Automaton:IsModuleHidden(name)return self.db.char.hiddenModules[name]end
function Automaton:GetModuleScope()return self.db.profile.moduleScope end
C.global={autorepair='0',autosell='0',buyemall='1'}
C.automation={enabled='1'}
pfUI.autovendor={GetRules=function()return {ignore={},custom={}}end}
''')
        lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation.lua').read_text(encoding='utf-8-sig'))
        lua.execute(r'''
local h,R=pfUI.automation,pfUI.automationOptions
local options=h:MerchantOptions()
assert(R:Render(parent,{_options=options}))
local rendered={}
for _,row in ipairs(rows())do
 rendered[row.option]=row
 if row.option==options.bulk then assert(row.widget=='checkbox' and row.input:GetChecked())end
end
assert(rendered[options.bulk] and rendered[options.buyHelp])
for _,group in ipairs({'original','category1','category2'})do
 for key,opt in pairs(M._options[group].args)do
  local row=assert(rendered[opt],'missing original merchant option '..group..':'..key)
  if key=='quantity'then assert(row.input:GetText()=='0','target amount readback lost')end
 end
end
local warm=created
assert(R:Render(parent,{_options=h:MerchantOptions()}));assert(created==warm,'merchant redraw leaked controls')
''')


if __name__=='__main__':
    unittest.main(verbosity=2)
