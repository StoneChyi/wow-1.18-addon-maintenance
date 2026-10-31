"""Merchant ownership and rule migration regressions against the real pfUI module.

Offline Lua 5.1 is a behavioral simulation, not a client/server acceptance test.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r"""
objects={}; now=1; money=1000; repairCost=100; repairs=0; sales={}; bags={};
legacy={ignore={},custom={}}; sourceReady=true; cursor=false; deferred=false
C={global={autorepair='1',autosell='1'}}
T=setmetatable({}, {__index=function(_,key) return key end})
pfUI={};function pfUI:RegisterModule(name,version,fn) fn() end
function GetBorderSize() return 1,1 end
function GetPerfectPixel() return 1 end
function SkinButton() end
function GetTime() return now end
function GetMoney() return money end
function CreateGoldString(n) return tostring(n) end
function CanMerchantRepair() return true end
function GetRepairAllCost() return repairCost,true end
function RepairAllItems() repairs=repairs+1;money=money-repairCost;repairCost=0 end
DEFAULT_CHAT_FRAME={messages={}};function DEFAULT_CHAT_FRAME:AddMessage(t) table.insert(self.messages,t) end
Automaton={}
function Automaton:AcquireDBNamespace(name)
 if sourceReady then return {profile=legacy} else return {profile={}} end
end
local methods={}
function newObject(kind,name,parent)
 local o=setmetatable({kind=kind,shown=true,scripts={},events={},parent=parent},{__index=methods})
 if name then _G[name]=o end;table.insert(objects,o);return o
end
function invoke(obj,script)
 local prior=this;this=obj;if obj.scripts[script] then obj.scripts[script]() end;this=prior
end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:Show() local was=self.shown;self.shown=true;if not was then invoke(self,'OnShow') end end
function methods:Hide() local was=self.shown;self.shown=false;if was then invoke(self,'OnHide') end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetWidth(n) self.width=n end
function methods:SetHeight(n) self.height=n end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:CreateTexture(name,layer) assert(name==nil and layer=='ARTWORK');return newObject('Texture',name,self) end
function methods:SetTexture(x) self.texture=x end
function methods:SetDesaturated(x) self.desaturated=x end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetOwner(x) self.owner=x end
function methods:AddLine(t) self.line=t end
function CreateFrame(kind,name,parent) return newObject(kind,name,parent) end
mockMethods=methods
MerchantFrame=newObject('Frame','MerchantFrame');MerchantFrame.shown=false;MerchantFrame.selectedTab=1
MerchantRepairItemButton=newObject('Button','MerchantRepairItemButton',MerchantFrame)
MerchantBuyBackItemItemButton=newObject('Button','MerchantBuyBackItemItemButton',MerchantFrame)
GameTooltip=newObject('GameTooltip','GameTooltip')
function MerchantFrame_Update() end
function CursorHasItem() return cursor end
function ClearCursor() error('must not clear user cursor') end
function GetContainerNumSlots(bag) return bag==0 and 8 or 0 end
function GetContainerItemLink(bag,slot)
 if bag~=0 then return end
 if raceAt and raceSlot==slot then
  reads=(reads or 0)+1
  if reads==raceAt then bags[slot]=replacement end
 end
 local v=bags[slot];return v and v.link
end
function GetContainerItemInfo(bag,slot)
 local v=bag==0 and bags[slot];if v then return v.texture,v.count,v.locked,v.quality end
end
function UseContainerItem(bag,slot)
 assert(MerchantFrame:IsShown() and MerchantFrame.selectedTab==1 and not cursor)
 table.insert(sales,{slot=slot,link=bags[slot].link})
 if not deferred then bags[slot]=nil;money=money+10 end
end
function item(id,quality,count)
 local color=quality==0 and 'ff9d9d9d' or 'ffffffff'
 return {link='|c'..color..'|Hitem:'..id..':0:0:0|h[test]|h|r',quality=quality,count=count or 1,texture='icon'}
end
function emit(e)
 event=e;invoke(pfUI.autovendor.frame,'OnEvent');event=nil
end
function open()
 MerchantFrame.shown=true;emit('MERCHANT_SHOW')
end
function step()
 now=now+.2;if pfUI.autovendor.frame.shown then invoke(pfUI.autovendor.frame,'OnUpdate') end
end
function takeOwnership()
 assert(pfUI.autovendor:ImportLegacyRules());assert(pfUI.autovendor:SetLegacyFallback(false))
end
"""


class MerchantTests(unittest.TestCase):
    def fresh(self, setup=""):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        contract = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        contract(self.lua.globals().mockMethods, self.lua.globals().newObject)
        self.lua.execute("MerchantRepairText=newObject('FontString','MerchantRepairText');MerchantRepairText:SetFontObject(GameFontNormal)")
        self.lua.execute(setup)
        self.lua.execute((ROOT / "Interface/AddOns/pfUI/modules/autovendor.lua").read_text(encoding="utf-8"))

    def check(self, source):
        self.lua.execute(source)

    def test_import_is_copy_once_and_ignore_wins(self):
        self.fresh("legacy.ignore['1']='keep';legacy.custom['1']='sell';legacy.custom['2']='white'")
        self.check("""
        local m=pfUI.autovendor;local db=m:GetRules()
        assert(m.ready and db.imported and db.ignore['1']=='keep' and db.custom['2']=='white')
        assert(not m:CanSell(item(1,0).link,0));assert(m:CanSell(item(2,1).link,1))
        db.custom['2']='changed';m:ImportLegacyRules();assert(db.custom['2']=='changed')
        assert(legacy.custom['2']=='white')
        """)

    def test_existing_pfui_rules_and_deletion_survive_import(self):
        self.fresh("C.autovendor_rules={ignore={},custom={['3']='local'}};legacy.ignore['3']='legacy';sourceReady=false")
        self.check("""
        local m=pfUI.autovendor;m:SetRule('custom',4,nil);legacy.custom['4']='old';sourceReady=true
        assert(m:ImportLegacyRules());assert(not m:GetRules().ignore['3'])
        assert(m:GetRules().custom['3']=='local' and not m:GetRules().custom['4'])
        assert(not m:SetRule('invalid',1,'x'));assert(not m:SetRule('ignore',-1,'x'))
        """)

    def test_not_ready_blocks_all_actions(self):
        self.fresh("sourceReady=false;bags[1]=item(1,0)")
        self.check("open();step();assert(not pfUI.autovendor.ready and repairs==0 and #sales==0)")

    def test_ready_does_not_grant_ownership(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("assert(pfUI.autovendor.ready);open();step();assert(repairs==0 and #sales==0)")

    def test_standalone_pfui_keeps_legacy_behavior(self):
        self.fresh("Automaton=nil;bags[1]=item(1,0)")
        self.check("open();step();assert(repairs==1 and #sales==1)")

    def test_whitelist_sells_white_and_preserves_other_white(self):
        self.fresh("legacy.custom['2']='white';bags[1]=item(1,0);bags[2]=item(2,1);bags[3]=item(3,1)")
        self.check("takeOwnership();open();step();step();step();assert(#sales==2 and bags[3] and repairs==1)")

    def test_ignored_gray_and_custom_survive(self):
        self.fresh("legacy.ignore['1']='keep';legacy.custom['1']='sell';bags[1]=item(1,0)")
        self.check("takeOwnership();open();step();assert(#sales==0 and bags[1])")

    def test_cursor_is_preserved_and_locked_item_waits(self):
        self.fresh("bags[1]=item(1,0);bags[1].locked=true;cursor=true")
        self.check("""
        takeOwnership();open();step();assert(#sales==0 and cursor)
        cursor=false;step();assert(#sales==0 and pfUI.autovendor.frame.shown)
        bags[1].locked=false;step();assert(#sales==1)
        """)

    def test_unknown_quality_or_missing_texture_never_sells(self):
        self.fresh("legacy.custom['1']='white';bags[1]=item(1,-1);bags[2]=item(2,0);bags[2].texture=nil")
        self.check("takeOwnership();open();step();assert(#sales==0)")

    def test_slot_replacement_is_rechecked(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("""
        takeOwnership();open();reads=0;raceSlot=1;raceAt=2;replacement=item(2,1)
        step();assert(#sales==0 and bags[1].quality==1)
        """)

    def test_same_item_server_delay_does_not_duplicate(self):
        self.fresh("bags[1]=item(1,0);deferred=true")
        self.check("""
        takeOwnership();open();step();open();step();emit('BAG_UPDATE');step()
        assert(#sales==1 and repairs==1)
        """)

    def test_merchant_close_and_buyback_stop_sale(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("""
        takeOwnership();open();MerchantFrame.shown=false;step();assert(#sales==0)
        emit('MERCHANT_CLOSED');MerchantFrame.shown=true;MerchantFrame.selectedTab=2
        open();step();assert(#sales==0)
        """)

    def test_fallback_revokes_actions_and_settings_remain(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("""
        takeOwnership();open();pfUI.autovendor:SetLegacyFallback(true);step()
        assert(#sales==0 and C.global.autosell=='1' and C.global.autorepair=='1')
        emit('MERCHANT_CLOSED');repairCost=100;open();assert(repairs==1)
        """)

    def test_late_engine_load_revokes_standalone_permission(self):
        self.fresh("oldEngine=Automaton;Automaton=nil;bags[1]=item(1,0)")
        self.check("""
        open();Automaton=oldEngine;emit('ADDON_LOADED');step();assert(#sales==0)
        assert(pfUI.autovendor.ready and not pfUI.autovendor:CanExecute())
        takeOwnership();open();step();assert(#sales==1)
        """)

    def test_disable_autosell_stops_active_queue_but_manual_sale_works(self):
        self.fresh("bags[1]=item(1,0);bags[2]=item(2,0)")
        self.check("""
        takeOwnership();open();step();assert(#sales==1)
        C.global.autosell='0';step();assert(#sales==1 and bags[2])
        invoke(pfUI.autovendor.frame.button,'OnClick');step();assert(#sales==2)
        """)

    def test_late_ready_ownership_resumes_open_merchant(self):
        self.fresh("sourceReady=false;bags[1]=item(1,0)")
        self.check("""
        open();step();assert(repairs==0 and #sales==0)
        sourceReady=true;takeOwnership();step();assert(repairs==1 and #sales==1)
        """)

    def test_numeric_legacy_arrays_fail_closed(self):
        self.fresh("legacy.custom[1]='not an item id';bags[1]=item(1,1)")
        self.check("open();step();assert(not pfUI.autovendor.ready and #sales==0 and repairs==0)")

    def test_new_stack_identity_in_old_slot_is_rechecked(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("""
        takeOwnership();open();step();assert(#sales==1)
        bags[1]=item(2,0);emit('BAG_UPDATE');step();assert(#sales==2)
        bags[1]=item(3,1);emit('BAG_UPDATE');step();assert(#sales==2)
        """)

    def test_insufficient_money_does_not_repair(self):
        self.fresh("money=50")
        self.check("takeOwnership();open();assert(repairs==0 and money==50)")


if __name__ == '__main__':
    unittest.main(verbosity=2)
