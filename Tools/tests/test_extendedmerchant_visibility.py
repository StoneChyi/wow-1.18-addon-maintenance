"""Run the extension with actual local FrameXML, without publishing game source.

--framexml accepts an explicit local Lua file; otherwise read the client MPQs.
Without either input, results are explicitly labelled as a reduced contract
fixture, not actual FrameXML validation. UI/server APIs are simulated; every
FontString must have a valid font template. No real transactions are performed.
"""
import argparse
from functools import lru_cache
import hashlib
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
sys.path.insert(0, str(ROOT / 'Tools'))
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=ROOT / 'Interface/AddOns/pfUI_ExtendedMerchant/pfUI_ExtendedMerchant.lua')
parser.add_argument('--framexml', type=Path)
parser.add_argument('--client-root', type=Path, default=ROOT)
parser.add_argument('--require-native', action='store_true')
ARGS, REMAINING = parser.parse_known_args()

# Independently expressed reduced contract. Child item data/visibility and
# legacy parent 11/12 cleanup are deliberately separate. Never call this a
# substitute for executing the installed client's actual Lua.
REDUCED_FIXTURE = r'''
MERCHANT_ITEMS_PER_PAGE=10;BUYBACK_ITEMS_PER_PAGE=12
function MerchantFrame_UpdateMerchantInfo()
 for slot=1,MERCHANT_ITEMS_PER_PAGE do
  local key='MerchantItem'..slot;local child=_G[key..'ItemButton']
  local id=(MerchantFrame.page-1)*MERCHANT_ITEMS_PER_PAGE+slot
  local title,icon,cost,stack,remaining=GetMerchantItemInfo(id)
  _G[key..'Name']:SetText(title)
  SetItemButtonTexture(child,icon);SetItemButtonStock(child,remaining)
  if id<=GetMerchantNumItems() then child:SetID(id);child:Show();_G[key..'MoneyFrame']:Show()
  else child:Hide();_G[key..'MoneyFrame']:Hide() end
 end
 MerchantItem11:Hide();MerchantItem12:Hide()
end
function MerchantFrame_UpdateBuybackInfo()
 MerchantItem11:Show();MerchantItem12:Show()
 for slot=1,BUYBACK_ITEMS_PER_PAGE do
  local key='MerchantItem'..slot;local child=_G[key..'ItemButton']
  _G[key..'Name']:SetText(GetBuybackItemInfo(slot))
  if slot<=GetNumBuybackItems() then child:SetID(slot);child:Show();_G[key..'MoneyFrame']:Show()
  else child:Hide();_G[key..'MoneyFrame']:Hide() end
 end
end
function MerchantFrame_Update()
 if MerchantFrame.selectedTab==1 then MerchantFrame_UpdateMerchantInfo() else MerchantFrame_UpdateBuybackInfo() end
end
function MerchantNextPageButton_OnClick() MerchantFrame.page=MerchantFrame.page+1;MerchantFrame_Update() end
function MerchantPrevPageButton_OnClick() MerchantFrame.page=MerchantFrame.page-1;MerchantFrame_Update() end
function MerchantItemButton_OnClick()
 if MerchantFrame.selectedTab==1 then BuyMerchantItem(this:GetID()) else BuybackItem(this:GetID()) end
end
'''


@lru_cache(maxsize=1)
def native_input():
    if ARGS.framexml:
        data = ARGS.framexml.read_bytes()
        return data.decode('utf-8-sig'), str(ARGS.framexml), hashlib.sha256(data).hexdigest(), True
    try:
        from turtle_map_archive import Client
        client = Client(ARGS.client_root)
        try:
            data, origin = client.read(r'Interface\FrameXML\MerchantFrame.lua')
        finally:
            for archive in client.archives:
                archive.close()
        return data.decode('utf-8-sig'), origin, hashlib.sha256(data).hexdigest(), True
    except (FileNotFoundError, NotADirectoryError):
        if ARGS.require_native:
            raise RuntimeError('Actual local MerchantFrame.lua required; provide --framexml or --client-root')
        return REDUCED_FIXTURE, 'REDUCED FIXTURE (FrameXML unavailable)', None, False


MOCK = r'''
objects={};methods={};products=0;buybacks=0;missingMerchant={};missingBuyback={};stock={}
nativeMerchantCalls=0;nativeBuybackCalls=0;queries={merchant={},buyback={}};transactions={}
pfUI={skin={},hooks={},font_default='Configured.ttf'};pfUI_config={global={font_size=12}}
mod=math.fmod;ceil=math.ceil;floor=math.floor;format=string.format;getglobal=function(k) return _G[k] end
MERCHANT_PAGE_NUMBER='Page %d/%d';MERCHANT_BUYBACK='Buyback'
function object(kind,name,parent,template)
 local f=setmetatable({kind=kind,name=name,parent=parent,template=template,shown=true,shows=0,
  width=153,height=44,points={},regions={},scripts={},events={}}, {__index=methods})
 table.insert(objects,f);if name then _G[name]=f end
 if parent and (kind=='Texture' or kind=='FontString') then table.insert(parent.regions,f) end
 return f
end
function methods:Show() self.shown=true;self.shows=self.shows+1 end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetObjectType() return self.kind end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetID(v) self.id=v end
function methods:GetID() return self.id end
function methods:GetRegions() return unpack(self.regions) end
function methods:ClearAllPoints() self.points={} end
function methods:SetPoint(anchor,relative,relativePoint,x,y)
 if type(relative)=='number' then x,y,relative,relativePoint=relative,relativePoint,self.parent,anchor end
 local point={anchor,relative or self.parent,relativePoint or anchor,x or 0,y or 0}
 for i,p in ipairs(self.points) do if p[1]==anchor then self.points[i]=point;return end end
 table.insert(self.points,point)
end
function methods:GetPoint(i) if self.points[i or 1] then return unpack(self.points[i or 1],1,5) end end
function methods:SetAllPoints(f) self.allpoints=f or self.parent end
local anchors={TOPLEFT={0,0},TOPRIGHT={1,0},BOTTOMLEFT={0,-1},BOTTOMRIGHT={1,-1},CENTER={.5,-.5},TOP={.5,0},BOTTOM={.5,-1},LEFT={0,-.5},RIGHT={1,-.5}}
function rect(f,seen)
 if f.origin then return f.origin[1],f.origin[2] end
 seen=seen or {};assert(not seen[f],'anchor cycle');seen[f]=true
 if f.allpoints then return rect(f.allpoints,seen) end
 local p=f.points[1];if not p then return nil end
 local parent=type(p[2])=='string' and _G[p[2]] or p[2]
 local x,y=rect(parent,seen);if x==nil then return nil end
 local a=assert(anchors[p[1]]);local b=assert(anchors[p[3]])
 return x+b[1]*parent.width+p[4]-a[1]*f.width,y+b[2]*parent.height+p[5]-a[2]*f.height
end
function methods:GetLeft() local x=rect(self);return x end
function methods:GetTop() local _,y=rect(self);return y end
function methods:SetTexture(...) self.texture={...} end
function methods:SetTexCoord(...) self.texcoord={...} end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetHitRectInsets() end
function methods:DisableDrawLayer() end
function methods:GetNormalTexture() self.normal=self.normal or object('Texture',nil,self);return self.normal end
function methods:SetNormalTexture(value) self:GetNormalTexture():SetTexture(value) end
function methods:CreateTexture(name) return object('Texture',name,self) end
function methods:GetText() return self.text or '' end
function methods:IsOwned(owner) return self.owner==owner end
function fire(f,script,value)
 local oldThis,oldArg=this,arg1;this,arg1=f,value
 if f.scripts[script] then f.scripts[script]() end
 this,arg1=oldThis,oldArg
end
function CreateFrame(kind,name,parent,template)
 local f=object(kind,name,parent,template)
 if template=='MerchantItemTemplate' then
  f.width,f.height=153,44
  f:CreateFontString(name..'Name','OVERLAY','GameFontNormalSmall')
  local child=object('Button',name..'ItemButton',f);child.width,child.height=36,36
  object('Texture',name..'ItemButtonIconTexture',child)
  object('Frame',name..'MoneyFrame',f)
  child:SetScript('OnClick',function() MerchantItemButton_OnClick(arg1) end)
 end
 return f
end
function GetMerchantNumItems() return products end
function GetNumBuybackItems() return buybacks end
function GetMerchantItemInfo(index)
 table.insert(queries.merchant,index)
 if index<1 or index>products or missingMerchant[index] then return nil end
 return 'Product '..index,'Icon '..index,100*index,1,stock[index] or -1,true
end
function GetBuybackItemInfo(index)
 table.insert(queries.buyback,index)
 if index<1 or index>buybacks or missingBuyback[index] then return nil end
 return 'Buyback '..index,'BuybackIcon '..index,100*index,1,-1,true
end
function UnitName() return 'Synthetic Vendor' end
function SetPortraitTexture(f,unit) f.portrait=unit end
function SetItemButtonCount(f,v) f.quantity=v end
function SetItemButtonStock(f,v) f.stock=v end
function SetItemButtonTexture(f,v) f.icon=v end
function MoneyFrame_Update(name,v) _G[name].money=v end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
function PlaySound() end
function CanMerchantRepair() return false end
function BuyMerchantItem(id) table.insert(transactions,{'buy',id}) end
function BuybackItem(id) table.insert(transactions,{'buyback',id}) end
function SetItemButtonNameFrameVertexColor(f,...) f.nameColor={...} end
function SetItemButtonSlotVertexColor(f,...) f.slotColor={...} end
function SetItemButtonTextureVertexColor(f,...) f.iconColor={...} end
function SetItemButtonNormalTextureVertexColor(f,...) f.normalColor={...} end
function GetBorderSize() return 1,1 end
function GetPerfectPixel() return 1 end
function StripTextures(f) for _,r in ipairs(f.regions) do if r.kind=='Texture' then r:SetTexture(nil) end end end
function CreateBackdrop(f) f.backdrop=f.backdrop or object('Frame',nil,f) end
function CreateBackdropShadow() end
function EnableMovable() end
function SkinCloseButton() end
function SkinTab() end
function SkinButton() end
function SkinArrowButton() end
function pfUI:RegisterSkin(name,version,fn) self.skin[name]=fn;fn() end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
'''

BOOTSTRAP = r'''
local strictSetText=methods.SetText
function methods:SetText(v) strictSetText(self,v==nil and '' or v) end
UIParent=CreateFrame('Frame','UIParent');UIParent.origin={0,1080};UIParent.width=1920;UIParent.height=1080
MerchantFrame=CreateFrame('Frame','MerchantFrame',UIParent);MerchantFrame.origin={0,600};MerchantFrame.page=1;MerchantFrame.selectedTab=1
-- The real XML already defines twelve parents, not ten. Its template is
-- 153x44, initially shown; native 1.12 reserves 11/12 for the buyback tab.
for i=1,12 do CreateFrame('Frame','MerchantItem'..i,MerchantFrame,'MerchantItemTemplate') end
for _,name in ipairs({'MerchantNameText','MerchantPageText','MerchantBuyBackItemName'}) do
 MerchantFrame:CreateFontString(name,'OVERLAY','GameFontNormalSmall')
end
for _,name in ipairs({'MerchantFramePortrait','MerchantFrameCloseButton','MerchantFrameTab1','MerchantFrameTab2',
 'MerchantBuyBackItem','MerchantBuyBackItemItemButton','MerchantBuyBackItemMoneyFrame','MerchantPrevPageButton',
 'MerchantNextPageButton','MerchantRepairText','MerchantRepairAllButton','MerchantRepairItemButton','MerchantRepairAllIcon',
 'MerchantFrameBottomLeftBorder','MerchantFrameBottomRightBorder','BuybackFrameTopLeft','BuybackFrameTopRight',
 'BuybackFrameBotLeft','BuybackFrameBotRight','GameTooltip'}) do CreateFrame('Frame',name,MerchantFrame) end
local nativeMerchant=MerchantFrame_UpdateMerchantInfo
MerchantFrame_UpdateMerchantInfo=function(...) nativeMerchantCalls=nativeMerchantCalls+1;return nativeMerchant(...) end
local nativeBuyback=MerchantFrame_UpdateBuybackInfo
MerchantFrame_UpdateBuybackInfo=function(...) nativeBuybackCalls=nativeBuybackCalls+1;return nativeBuyback(...) end
function dispatch(name,arg)
 local oldThis,oldEvent,oldArg=this,event,arg1
 local n=#objects
 for i=1,n do local f=objects[i];if f.events[name] and f.scripts.OnEvent then
  this,event,arg1=f,name,arg;f.scripts.OnEvent()
 end end
 this,event,arg1=oldThis,oldEvent,oldArg
end
function merchant(count,page) products=count;MerchantFrame.page=page or 1;MerchantFrame.selectedTab=1;MerchantFrame_UpdateMerchantInfo() end
function buyback(count) buybacks=count;MerchantFrame.selectedTab=2;MerchantFrame_UpdateBuybackInfo() end
function slotVisibility(count)
 for i=1,20 do
  local parent=_G['MerchantItem'..i];local child=_G['MerchantItem'..i..'ItemButton'];local expected=i<=count
  assert(parent:IsShown()==expected,'parent slot '..i..' expected '..tostring(expected))
  assert(child:IsVisible()==(expected and MerchantFrame:IsVisible()),'child visibility '..i)
  if not expected then assert(not parent.bg:IsVisible(),'empty slot background visible '..i) end
 end
end
'''


class MerchantVisibility(unittest.TestCase):
    def runtime(self, source=None, standard_skin=True, native_child_hook=None):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        install = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
        install(lua.globals().methods, lua.globals().object)
        lua.execute(native_input()[0])
        lua.execute(BOOTSTRAP)
        compatibility = (ROOT / 'Interface/AddOns/pfUI/compat/vanilla.lua').read_text(encoding='utf-8-sig')
        lua.execute(compatibility[compatibility.index('function hooksecurefunc('):compatibility.index('do -- GetItemInfo')])
        # RequiredDeps loads pfUI's Merchant skin before this addon's files.
        # Extended skin registers immediately; the core wrapper installs only
        # on ADDON_LOADED, thus its final layout follows both skin hooks.
        if standard_skin:
            lua.execute((ROOT / 'Interface/AddOns/pfUI/skins/blizzard/merchant.lua').read_text(encoding='utf-8-sig'))
        if native_child_hook:
            lua.execute(native_child_hook)
        lua.execute(source if source is not None else ARGS.source.read_text(encoding='utf-8-sig'))
        lua.execute((ROOT / 'Interface/AddOns/pfUI_ExtendedMerchant/skin.lua').read_text(encoding='utf-8-sig'))
        lua.execute("dispatch('ADDON_LOADED','pfUI_ExtendedMerchant')")
        return lua

    def test_native_updates_children_then_hides_valid_parent_11_12(self):
        lua = self.runtime()
        lua.execute(native_input()[0])
        lua.execute('''
        products=20;MERCHANT_ITEMS_PER_PAGE=20;MerchantFrame_UpdateMerchantInfo()
        assert(not MerchantItem11:IsShown() and not MerchantItem12:IsShown())
        assert(MerchantItem11ItemButton:IsShown() and MerchantItem12ItemButton:IsShown())
        assert(MerchantItem11ItemButton:GetID()==11 and MerchantItem12ItemButton:GetID()==12)
        ''')

    def test_full_page_restores_valid_11_12_and_all_twenty_items(self):
        lua = self.runtime()
        lua.execute('merchant(20,1);slotVisibility(20);assert(nativeMerchantCalls==1)')

    def test_empty_partial_and_multiple_page_matrix(self):
        lua = self.runtime()
        for count in (0, 1, 9, 10, 11, 12, 13, 19, 20, 21, 24, 39, 40, 41):
            for page in range(1, (count + 19) // 20 + 2):
                visible = max(0, min(20, count - (page - 1) * 20))
                lua.execute(f'merchant({count},{page});slotVisibility({visible})')

    def test_real_native_paging_keeps_page_and_item_indices(self):
        lua = self.runtime()
        lua.execute('''
        merchant(21,1);slotVisibility(20)
        MerchantNextPageButton_OnClick();slotVisibility(1)
        assert(MerchantFrame.page==2 and MerchantItem1ItemButton:GetID()==21)
        assert(MerchantItem1Name:GetText()=='Product 21')
        MerchantPrevPageButton_OnClick();slotVisibility(20)
        assert(MerchantFrame.page==1 and MerchantItem11ItemButton:GetID()==11)
        ''')

    def test_buyback_hides_empty_slots_and_merchant_tail_then_restores_shop(self):
        lua = self.runtime()
        for count in (0, 1, 3, 11, 12):
            lua.execute(f'merchant(40,1);buyback({count});slotVisibility({count});merchant(40,2);slotVisibility(20)')
        lua.execute('assert(nativeBuybackCalls==5 and nativeMerchantCalls==10)')

    def test_missing_11_12_source_data_cannot_expose_shown_children(self):
        lua = self.runtime()
        lua.execute('''
        missingMerchant[11]=true;missingMerchant[12]=true;merchant(20,1)
        assert(not MerchantItem11:IsShown() and not MerchantItem12:IsShown())
        assert(MerchantItem11ItemButton:IsShown() and not MerchantItem11ItemButton:IsVisible())
        missingMerchant={};merchant(20,1);slotVisibility(20)
        missingBuyback[11]=true;missingBuyback[12]=true;buyback(12)
        assert(not MerchantItem11:IsShown() and not MerchantItem12:IsShown())
        missingBuyback={};buyback(12);slotVisibility(12)
        ''')

    def test_sold_out_items_keep_native_names_ids_and_transaction_entry(self):
        lua = self.runtime()
        lua.execute('''
        stock[11]=0;stock[12]=0;merchant(20,1);slotVisibility(20)
        assert(MerchantItem11ItemButton.stock==0 and MerchantItem11ItemButton.icon=='Icon 11')
        merchant(40,2);slotVisibility(20)
        assert(MerchantItem11Name:GetText()=='Product 31' and MerchantItem11ItemButton:GetID()==31)
        fire(MerchantItem11ItemButton,'OnClick','RightButton')
        assert(transactions[1][1]=='buy' and transactions[1][2]==31)
        buyback(12);slotVisibility(12);fire(MerchantItem12ItemButton,'OnClick','LeftButton')
        assert(transactions[2][1]=='buyback' and transactions[2][2]==12)
        ''')

    def test_hidden_window_retains_local_slot_state_and_geometry(self):
        lua = self.runtime()
        lua.execute('''
        MerchantFrame:Hide();merchant(20,1)
        assert(MerchantItem11:IsShown() and not MerchantItem11ItemButton:IsVisible())
        assert(MerchantItem11:GetTop()==MerchantItem1:GetTop())
        MerchantFrame:Show();slotVisibility(20)
        ''')

    def test_four_column_geometry_with_both_real_skins_and_without_standard_skin(self):
        for standard in (True, False):
            lua = self.runtime(standard_skin=standard)
            lua.execute('''
            merchant(20,1);slotVisibility(20)
            for row=0,4 do
              local a,b=_G['MerchantItem'..(1+row*2)],_G['MerchantItem'..(2+row*2)]
              local c,d=_G['MerchantItem'..(11+row*2)],_G['MerchantItem'..(12+row*2)]
              assert(a:GetTop()==b:GetTop() and a:GetTop()==c:GetTop() and a:GetTop()==d:GetTop(),'misaligned row '..row)
              assert(a:GetTop()==530-row*53,'unexpected row pitch')
              assert(a:GetLeft()==22 and b:GetLeft()==187 and c:GetLeft()==352 and d:GetLeft()==517,'wrong four-column positions')
            end
            ''')

    def test_data_validity_replaces_stale_parent_mask_without_exposing_empty_slots(self):
        # The old arbitrary-parent-mask premise was wrong: native 1.12 hides
        # valid 11/12. Valid data wins, but child-empty slots remain hidden.
        lua = self.runtime()
        lua.execute('''
        merchant(20,1);slotVisibility(20)
        MerchantItem1:Hide();MerchantItem11:Hide();MerchantItem20:Hide()
        merchant(20,1);slotVisibility(20)
        merchant(21,2);slotVisibility(1)
        MerchantItem20:Show();merchant(21,2);slotVisibility(1)
        ''')

    def test_layout_preserves_independent_child_visibility_decisions(self):
        lua = self.runtime(native_child_hook='''
        hooksecurefunc('MerchantFrame_UpdateMerchantInfo',function()
          for i=1,20 do local child=_G['MerchantItem'..i..'ItemButton']
            if i==2 or i==7 or i==19 then child:Show() else child:Hide() end
          end
        end)
        ''')
        lua.execute('''
        merchant(20,1)
        for i=1,20 do
          assert(_G['MerchantItem'..i]:IsShown(),'valid parent not restored '..i)
          assert(_G['MerchantItem'..i..'ItemButton']:IsVisible()==(i==2 or i==7 or i==19),'layout changed child state '..i)
        end
        ''')


if __name__ == '__main__':
    _, origin, sha, actual = native_input()
    print('FrameXML:', origin, 'SHA256:', sha or 'not applicable', flush=True)
    unittest.main(argv=[sys.argv[0]] + REMAINING, verbosity=2)
