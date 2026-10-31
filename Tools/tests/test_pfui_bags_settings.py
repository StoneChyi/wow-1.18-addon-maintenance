"""Execute the real Bags & Bank page and shared config control callbacks.

Offline UI contracts cannot verify mouse hit testing or visuals in the client.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
methods={}; objects={}
function newObject(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,scripts={},children={},enabled=true}, {__index=methods})
 table.insert(objects,o)
 if parent then table.insert(parent.children,o) end
 return o
end
function CreateFrame(kind,name,parent,template) return newObject(kind,name,parent) end
function methods:CreateTexture() return newObject('Texture',nil,self) end
function methods:GetParent() return self.parent end
function methods:SetParent(parent) self.parent=parent end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:Fire(event,button)
 local old,oldarg=this,arg1;this=self;arg1=button
 if self.scripts[event] then self.scripts[event]() end
 this=old;arg1=oldarg
end
function methods:Click()
 if not self.enabled then return end
 if self.kind=='CheckButton' then self.checked=not self.checked end
 self:Fire('OnClick','LeftButton')
end
function methods:SetChecked(value) self.checked=value and true or false end
function methods:GetChecked() return self.checked and 1 or nil end
function methods:IsEnabled() return self.enabled end
function methods:Disable() self.enabled=false end
function methods:Enable() self.enabled=true end
function methods:GetLeft() return 0 end
function methods:GetRight() return 440 end
function methods:Show() self:Fire('OnShow') end
function methods:SetHeight(value) self.height=value end
function methods:GetText() return self.text end
for _,name in ipairs({'SetWidth','SetPoint','SetAllPoints','Hide','SetTexture','SetTextColor',
 'SetNormalTexture','SetPushedTexture','SetHighlightTexture','SetJustifyH','SetAutoFocus',
 'SetTextInsets','SetBackdrop','SetAlpha','EnableMouse'}) do methods[name]=function() end end
function CreateBackdrop(frame) frame.backdrop=CreateFrame('Frame',nil,frame) end
function CreateDropDownButton(name,parent)
 local input=CreateFrame('Button',name,parent)
 input.menuframe=CreateFrame('Frame',nil,parent)
 input.SetMenu=function(self,fn) self.menu=fn() end
 input.SetSelection=function() end
 input.HideMenu=function(self) self.menuHidden=true end
 return input
end
function strsplit(delimiter,text)
 local parts={};string.gsub(text,'[^'..delimiter..']+',function(v) table.insert(parts,v) end)
 return unpack(parts)
end
EntryUpdate=function() end;searchDB={}
T=setmetatable({},{__index=function(_,key) return key end})
C={appearance={bags={borderlimit='1',borderonlygear='0',unusable='1',unusable_color='.9,.2,.2,1',
 movable='0',abovechat='0',hidechat='0',bagrowlength='10',bankrowlength='10',fulltext='1',icon_size='-1'}},
 global={font_size='12',autosell='1',autorepair='1',buyemall='1'},gui={reloadmarker='1'}}
pfUI_config=C;pfUI={expansion='vanilla',font_default='Missing.ttf',gui={}}
function CreateGUIEntry(parent,title,fn) populate=fn end
function Build()
 local root=CreateFrame('Frame');local content=CreateFrame('Frame',nil,root)
 content.parent=root;this=content;populate();return content
end
function Row(content,key)
 for _,row in ipairs(content.children) do if row.config==key then return row end end
 error('Missing row: '..key)
end
'''


class BagsSettingsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        contract = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        contract(self.lua.globals().methods, self.lua.globals().newObject)
        self.lua.execute("failedFontPaths['Missing.ttf']=true")
        source = (ROOT / "Interface/AddOns/pfUI/modules/gui.lua").read_text(encoding="utf-8")
        start = source.index("    function CreateConfig(")
        end = source.index("    local TabFrameOnMouseDown", start)
        self.lua.execute(source[start:end])
        start = source.index('    CreateGUIEntry(T["Bags & Bank"]')
        end = source.index('    CreateGUIEntry(T["Loot"]', start)
        self.lua.execute(source[start:end])
        self.lua.execute("content=Build()")

    def test_all_ten_boolean_options_use_checkboxes_and_persist_both_directions(self):
        self.lua.execute('''
        local keys={'borderlimit','borderonlygear','unusable','movable','abovechat','hidechat',
          'fulltext','autosell','autorepair','buyemall'}
        for _,key in ipairs(keys) do
          local row=Row(content,key);assert(row.input.kind=='CheckButton',key)
          local before=row.category[key]
          assert((row.input:GetChecked() and '1' or '0')==before,key)
          row.input:Click();assert(row.category[key]~=before,key)
          local recreated=Row(Build(),key)
          assert((recreated.input:GetChecked() and '1' or '0')==row.category[key],key)
          recreated.input:Click();assert(row.category[key]==before,key)
        end
        assert(pfUI.gui.settingChanged)
        ''')

    def test_caption_click_routes_once_and_right_click_does_not_change_setting(self):
        self.lua.execute('''
        local row=Row(content,'fulltext');row:Fire('OnMouseUp','LeftButton')
        assert(C.appearance.bags.fulltext=='0')
        row:Fire('OnMouseUp','RightButton');assert(C.appearance.bags.fulltext=='0')
        row:Fire('OnMouseUp','LeftButton');assert(C.appearance.bags.fulltext=='1')
        row.input:Disable();row:Fire('OnMouseUp','LeftButton');assert(C.appearance.bags.fulltext=='1')
        ''')

    def test_revisiting_page_resynchronizes_shared_merchant_choices(self):
        self.lua.execute('''
        for _,key in ipairs({'autosell','autorepair'}) do
          local input=Row(content,key).input
          C.global[key]='0';input:Show();assert(not input:GetChecked())
          input:Click();assert(C.global[key]=='1')
          C.global[key]='0';input:Show();assert(not input:GetChecked())
        end
        ''')

    def test_shared_update_callback_keeps_checkbox_context_once_per_click(self):
        self.lua.execute('''
        this=content;local count=0;local row
        row=CreateConfig(function() count=count+1;assert(this==row.input) end,
          'live',C.global,'autosell','checkbox')
        row:Fire('OnMouseUp','LeftButton');assert(count==1)
        row.input:Click();assert(count==2)
        row.input:Show();assert(count==2)
        ''')

    def test_configured_font_failure_preserves_valid_caption_fallback(self):
        self.lua.execute('''
        for _,row in ipairs(content.children) do
          assert(row.caption and row.caption.font)
          assert(row.caption.font[1]~='Missing.ttf')
        end
        local bare=newObject('FontString')
        assert(not pcall(function() bare:SetText('must fail') end))
        ''')

    def test_dynamic_rows_do_not_pollute_global_search(self):
        self.lua.execute('''
        local count=0;for _ in pairs(searchDB) do count=count+1 end
        this=content;content.automationDynamic=true
        CreateConfig(function() end,'dynamic',C.global,'autosell','checkbox')
        local after=0;for _ in pairs(searchDB) do after=after+1 end
        assert(count==after)
        ''')

    def test_numeric_and_color_controls_retain_their_types(self):
        self.lua.execute('''
        for _,key in ipairs({'bagrowlength','bankrowlength','icon_size'}) do
          assert(Row(content,key).input.kind=='EditBox')
        end
        assert(Row(content,'unusable_color').color.kind=='Button')
        ''')

    def test_dropdown_menu_cannot_remain_over_another_settings_page(self):
        self.lua.execute('''
        this=content;local row=CreateConfig(function() end,'choices',{choice='a'},'choice',
          'dropdown',{'a:First','b:Second'})
        assert(row.input.menuframe.parent==pfUI.gui)
        row.input:Fire('OnHide');assert(row.input.menuHidden)
        ''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
