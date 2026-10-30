"""Exercise the full merchant extension while preserving native slot visibility.

The client-update contract controls slot IDs and visibility. Layout must leave
those decisions intact, including when the merchant parent is currently hidden.
No purchase is performed and no FontStrings are created by this test.
"""
import argparse
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=ROOT / 'Interface/AddOns/pfUI_ExtendedMerchant/pfUI_ExtendedMerchant.lua')
ARGS, REMAINING = parser.parse_known_args()

MOCK = r'''
objects={};nativeMerchantCalls=0;nativeBuybackCalls=0;products=0;buybacks=0
MERCHANT_ITEMS_PER_PAGE=10;BUYBACK_ITEMS_PER_PAGE=12;pfUI={skin={}}
mod=math.fmod
local methods={}
function methods:Show() self.shown=true;self.shows=self.shows+1 end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetName() return self.name end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:ClearAllPoints() self.points={} end
function methods:SetPoint(...) self.points[#self.points+1]={...} end
function methods:SetScript(kind,fn) self.scripts[kind]=fn end
function methods:RegisterEvent(e) self.events[e]=true end
function CreateFrame(kind,name,parent,template)
  local f=setmetatable({name=name,parent=parent,shown=true,shows=0,scripts={},events={},points={}}, {__index=methods})
  objects[#objects+1]=f;if name then _G[name]=f end
  return f
end
UIParent=CreateFrame('Frame','UIParent')
MerchantFrame=CreateFrame('Frame','MerchantFrame',UIParent);MerchantFrame.page=1;MerchantFrame.selectedTab=1
for i=1,10 do
  local f=CreateFrame('Frame','MerchantItem'..i,MerchantFrame)
  f.bg=CreateFrame('Texture',nil,f)
end
for _,name in ipairs({'MerchantBuyBackItem','MerchantPrevPageButton','MerchantPageText','MerchantNextPageButton'}) do
 CreateFrame('Frame',name,MerchantFrame)
end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function BuyMerchantItem() error('layout must never buy items') end
function BuybackItem() error('layout must never buy items back') end
local function skinChildren()
  -- Both installed skin files show child backgrounds, never parent slots.
  for i=1,MERCHANT_ITEMS_PER_PAGE do
    local f=_G['MerchantItem'..i]
    if not f.bg then f.bg=CreateFrame('Texture',nil,f) end
    f.bg:Show()
  end
end
function MerchantFrame_UpdateMerchantInfo()
  nativeMerchantCalls=nativeMerchantCalls+1
  for i=1,MERCHANT_ITEMS_PER_PAGE do
    local f=_G['MerchantItem'..i];local index=(MerchantFrame.page-1)*MERCHANT_ITEMS_PER_PAGE+i
    f.itemId=index
    if index<=products then f:Show() else f:Hide() end
  end
  skinChildren()
end
function MerchantFrame_UpdateBuybackInfo()
  nativeBuybackCalls=nativeBuybackCalls+1
  for i=1,BUYBACK_ITEMS_PER_PAGE do
    local f=_G['MerchantItem'..i];f.itemId=i
    if i<=buybacks then f:Show() else f:Hide() end
  end
  skinChildren()
end
function dispatch(name,arg)
  local oldThis,oldEvent,oldArg=this,event,arg1
  for _,f in ipairs(objects) do if f.events[name] and f.scripts.OnEvent then
    this,event,arg1=f,name,arg;f.scripts.OnEvent()
  end end
  this,event,arg1=oldThis,oldEvent,oldArg
end
function merchant(count,page)
  products=count;MerchantFrame.page=page or 1;MerchantFrame.selectedTab=1
  MerchantFrame_UpdateMerchantInfo()
end
function buyback(count)
  buybacks=count;MerchantFrame.selectedTab=2;MerchantFrame_UpdateBuybackInfo()
end
function slotVisibility(count)
  for i=1,MERCHANT_ITEMS_PER_PAGE do
    local f=_G['MerchantItem'..i]
    assert(f:IsShown()==(i<=count),'slot visibility '..i..' expected count '..count)
    if i>count then assert(f.bg:IsShown() and not f.bg:IsVisible(),'hidden parent exposed child') end
  end
end
'''


class MerchantVisibility(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute(ARGS.source.read_text(encoding='utf-8-sig'))
        lua.execute("dispatch('ADDON_LOADED','pfUI_ExtendedMerchant')")
        return lua

    def test_partial_last_page_keeps_empty_slots_hidden(self):
        lua = self.runtime()
        lua.execute('merchant(24,1);slotVisibility(20);merchant(24,2);slotVisibility(4)')
        lua.execute('assert(nativeMerchantCalls==2)')

    def test_empty_and_partial_pages_matrix(self):
        lua = self.runtime()
        for count in (0, 1, 9, 10, 11, 19, 20, 21, 24, 39, 40, 41):
            for page in range(1, (count + 19) // 20 + 2):
                visible = max(0, min(20, count-(page-1)*20))
                lua.execute(f'merchant({count},{page});slotVisibility({visible})')

    def test_buyback_hides_empty_slots_and_old_merchant_tail(self):
        lua = self.runtime()
        for count in (0, 1, 3, 11, 12):
            lua.execute(f'merchant(40,1);buyback({count});slotVisibility({count})')
        lua.execute('assert(nativeBuybackCalls==5 and nativeMerchantCalls==5)')

    def test_tab_switching_and_restock_can_show_slots_again(self):
        lua = self.runtime()
        lua.execute('merchant(24,2);slotVisibility(4);buyback(2);slotVisibility(2);merchant(40,2);slotVisibility(20)')
        lua.execute('merchant(21,2);slotVisibility(1);merchant(40,2);slotVisibility(20)')

    def test_hidden_parent_does_not_block_local_slot_layout(self):
        lua = self.runtime()
        lua.execute('MerchantFrame:Hide();merchant(20,1);slotVisibility(20)')
        lua.execute("assert(MerchantItem1:IsShown() and not MerchantItem1:IsVisible());assert(#MerchantItem1.points>0)")
        lua.execute('MerchantFrame:Show();slotVisibility(20)')

    def test_layout_preserves_item_ids_and_existing_dimensions(self):
        lua = self.runtime()
        lua.execute('merchant(40,2);slotVisibility(20)')
        lua.execute('''
        assert(MERCHANT_ITEMS_PER_PAGE==20 and MerchantFrame.width==715)
        for i=1,20 do local f=_G['MerchantItem'..i];assert(f.itemId==20+i and f.height==37) end
        assert(MerchantItem11.points[1][2]==MerchantItem2)
        buyback(12);slotVisibility(12)
        for i=1,12 do local f=_G['MerchantItem'..i];assert(f.itemId==i and f.height==37) end
        ''')

    def test_arbitrary_native_visibility_masks_are_not_expanded(self):
        # Install the arbitrary decisions underneath the extension's actual
        # captured native callbacks, rather than computing a second page model.
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute('''
        function MerchantFrame_UpdateMerchantInfo()
          nativeMerchantCalls=nativeMerchantCalls+1
          for i=1,20 do
            local f=_G['MerchantItem'..i]
            if i==2 or i==7 or i==19 then f:Show() else f:Hide() end
          end
        end
        function MerchantFrame_UpdateBuybackInfo()
          nativeBuybackCalls=nativeBuybackCalls+1
          for i=1,12 do
            local f=_G['MerchantItem'..i]
            if i==3 or i==11 then f:Show() else f:Hide() end
          end
        end
        ''')
        lua.execute(ARGS.source.read_text(encoding='utf-8-sig'))
        lua.execute('''
        dispatch('ADDON_LOADED','pfUI_ExtendedMerchant')
        MerchantFrame_UpdateMerchantInfo()
        for i=1,20 do assert(_G['MerchantItem'..i]:IsShown()==(i==2 or i==7 or i==19)) end
        MerchantFrame_UpdateBuybackInfo()
        for i=1,20 do assert(_G['MerchantItem'..i]:IsShown()==(i==3 or i==11)) end
        assert(nativeMerchantCalls==1 and nativeBuybackCalls==1)
        ''')


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]] + REMAINING)
