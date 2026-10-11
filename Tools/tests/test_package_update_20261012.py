"""Exercise merged chat/BW behavior, repaired mail amounts and imported fonts.

Executes production Lua in Lua 5.1 with controlled 1.12 API signatures.
This is not an in-game acceptance test. Pass --addons for a staged candidate.
"""
from pathlib import Path
import argparse
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime


def function_block(source, name):
    start = source.index('function ' + name + '(')
    following = re.search(r'\n(?:local )?function ', source[start + 1:])
    return source[start:] if not following else source[start:start + 1 + following.start()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--addons', type=Path, default=ROOT / 'Interface/AddOns')
    args = parser.parse_args()
    addons = args.addons
    checks = []

    def read(path):
        return (addons / path).read_text(encoding='utf-8-sig')

    # Run the actual complete BigWigs module, with localization and communication
    # endpoints controlled; then connect the real merged chat button function.
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
      events={}; sounds={}; warnings={}; prints={}; checks=0; toggles=0
      raidCount=40; leader=true; officer=false
      function IsRaidLeader() return leader end
      function IsRaidOfficer() return officer end
      function GetNumRaidMembers() return raidCount end
      function PlaySoundFile(path) table.insert(sounds,path) end
      function SendChatMessage(text,channel) table.insert(warnings,{text,channel}) end
      function RCBA_BuffCheckAndReport() checks=checks+1 end
      function RCBA_Toggle() toggles=toggles+1 end
      function setglobal(k,v) _G[k]=v end
      DEFAULT_CHAT_FRAME={AddMessage=function(self,s) table.insert(prints,s) end}
      SlashCmdList={}
      local locale={}
      function locale:RegisterTranslations(lang,func)
        if lang=='enUS' or lang=='zhCN' then
          for k,v in pairs(func()) do self[k]=(v==true) and k or v end
        end
      end
      function locale:new() return self end
      function AceLibrary() return locale end
      BigWigs={}
      function BigWigs:NewModule()
        return {
          Sync=function(self,s) table.insert(events,s) end,
          Print=function(self,s) table.insert(prints,s) end,
          Message=function(self,...) self.message={...} end,
          RegisterEvent=function() end,ThrottleSync=function() end,
        }
      end
    ''')
    lua.execute(read('BigWigs/Plugins/Pulltimer.lua'))
    lua.execute(function_block(read('S_ChatBar/ChatBar.lua'), 'RaidCheck_OnClick'))
    lua.execute('''
      BigWigsPulltimer:OnEnable()
      assert(SLASH_BWBUFF_SHORTHAND1=='/bwbuff')
      arg1='MiddleButton'; RaidCheck_OnClick()
      assert(events[1]=='BufftimerSync' and #warnings==1 and checks==1 and #sounds==0)
      assert(warnings[1][2]=='RAID_WARNING')
      leader=false;officer=true;RaidCheck_OnClick()
      assert(#events==2 and #warnings==2 and checks==2)
      leader=false;officer=false;RaidCheck_OnClick()
      assert(#events==2 and #warnings==2 and #sounds==1 and checks==3)
      local before=#events;SlashCmdList.BWBUFF_SHORTHAND()
      assert(#events==before and #prints==1)
      leader=true;raidCount=0;RaidCheck_OnClick()
      assert(#events==2 and #sounds==2 and checks==4)
      local saved=BigWigsPulltimer;BigWigsPulltimer=nil;raidCount=40;RaidCheck_OnClick()
      assert(#sounds==3 and checks==5)
      BigWigsPulltimer=saved;RCBA_BuffCheckAndReport=nil;RaidCheck_OnClick()
      assert(#events==3 and #prints==2)
      arg1='RightButton';RaidCheck_OnClick();assert(toggles==1 and #events==3)
      RC_MainFrame={shown=false,IsShown=function(self) return self.shown end,
        Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end}
      arg1='LeftButton';RaidCheck_OnClick();assert(RC_MainFrame.shown)
      RaidCheck_OnClick();assert(not RC_MainFrame.shown)
      saved:BigWigs_RecvSync('BufftimerSync','','TestLeader')
      assert(saved.message[4]=='goforbuff')
      assert(string.find(saved.message[1],'TestLeader',1,true))
    ''')
    checks.append('merged chat and complete BigWigs module: leader/officer/member/solo/missing dependencies/left/right/sync')

    # The actual money parser, including every unit combination and first-amount
    # selection. No mail API or deletion/return action is executed.
    lua.execute('TurtleMail={};getn=table.getn')
    lua.execute(function_block(read('TurtleMail/TurtleMail.lua'), 'TurtleMail.parse_body_money').split('TurtleMail.api =')[0])
    amounts = [
        (None, None), ('', None), ('无金额', None), ('12金34银56铜', 123456),
        ('12金34银', 123400), ('12金56铜', 120056), ('12银34铜', 1234),
        ('12金', 120000), ('12银', 1200), ('34铜', 34), ('0铜', 0),
        ('0金0银1铜', 1), ('成交价：2金 3银 4铜。', 20304),
        ('价格：12银34铜；另一笔：2金', 1234), ('先付34铜，后付12银', 34),
        ('先付2金，再付5金6银7铜', 20000), ('共1金\n2银\t3铜', 10203),
        ('100000金99银99铜', 1000009999),
    ]
    for body, expected in amounts:
        actual = lua.globals().TurtleMail.parse_body_money(body)
        assert actual == expected, (body, actual, expected)
    checks.append(f'TurtleMail real amount parser: {len(amounts)} cases')

    # Strict fonts: missing templates must fail SetText, and failed SetFont must
    # preserve the built-in font used by the imported Label/Icon widgets.
    fonts = LuaRuntime(unpack_returned_tuples=True)
    fonts.execute('''
      methods={}
      function object(kind,name,parent)
        local o=setmetatable({kind=kind,name=name,parent=parent,width=100,height=20}, {__index=methods})
        if name then _G[name]=o end;return o
      end
      function methods:GetWidth() return self.width end
      function methods:GetHeight() return self.height end
      function methods:SetWidth(v) self.width=v end
      function methods:SetHeight(v) self.height=v end
      function methods:SetTexture(v) self.texture=v end
      function methods:GetTexture() return self.texture end
      function methods:GetText() return self.text end
      function methods:Show() self.shown=true end
      function methods:Hide() self.shown=false end
      function methods:IsShown() return self.shown end
      for _,n in ipairs({'SetJustifyH','SetJustifyV','ClearAllPoints','SetPoint',
        'SetVertexColor','SetTextColor','SetTexCoord','SetAllPoints','SetBlendMode','EnableMouse',
        'SetScript','Enable','Disable'}) do methods[n]=function() end end
      function methods:CreateTexture(name) return object('Texture',name,self) end
      function CreateFrame(kind,name,parent) return object(kind,name,parent) end
      UIParent=object('Frame','UIParent')
    ''')
    fonts.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))(fonts.globals().methods, fonts.globals().object)
    fonts.execute('''
      GameFontHighlight=GameFontNormal
      local createFontString=methods.CreateFontString
      function methods:CreateFontString(name,layer,template)
        if template=='GameFontHighlight' then template='GameFontNormal' end
        return createFontString(self,name,layer,template)
      end
      function GameFontHighlightSmall:GetFont() return unpack(self.font) end
      gui={constructors={}}
      function gui:GetWidgetVersion() return nil end
      function gui:RegisterWidgetType(name,fn) self.constructors[name]=fn end
      function gui:RegisterAsWidget(w)
        function w:SetWidth(v) self.frame:SetWidth(v) end
        function w:SetHeight(v) self.frame:SetHeight(v) end
        return w
      end
      function LibStub() return gui end
      assert(not pcall(function() object('FontString'):SetText('invalid') end))
      failedFontPaths['Missing.ttf']=true
    ''')
    for name in ['Label', 'Icon']:
        fonts.execute(read(f'!Libs/Ace3/AceGUI-3.0/widgets/AceGUIWidget-{name}.lua'))
    fonts.execute('''
      local label=gui.constructors.Label();label:OnAcquire();label:SetText('hello')
      label:SetFont('Missing.ttf',12);label:SetText('fallback');assert(label.label.font)
      label:OnAcquire();label:SetText('reused');assert(label.label.text=='reused')
      local icon=gui.constructors.Icon();icon:OnAcquire();icon:SetLabel('hello')
      icon.label:SetFont('Missing.ttf',12);icon:SetLabel('fallback')
      icon:SetLabel('');icon:OnAcquire();icon:SetLabel('reused');assert(icon.label.font)
    ''')
    # Audit every imported widget CreateFontString site, including the two sites
    # that initialize via SetFontObject instead of a constructor template.
    font_sites = 0
    for path in (addons / '!Libs/Ace3/AceGUI-3.0/widgets').glob('*.lua'):
        source = path.read_text(encoding='utf-8-sig')
        for match in re.finditer(r'local (\w+) = [^\n]*:CreateFontString\(([^\n]*)\)', source):
            variable, arguments = match.groups()
            after = source[match.end():].splitlines()[:4]
            assert re.search(r'"GameFont\w+"', arguments) or any(variable + ':SetFontObject(' in line for line in after), (path, variable)
            font_sites += 1
    checks.append(f'font preconditions: {font_sites} imported widget sites audited; Label/Icon creation/reuse/empty/failed-font checks passed')

    # Load the real added libraries in their TOC order. No fallback library
    # implementations are injected, so missing/incorrect dependencies fail.
    libraries = LuaRuntime(unpack_returned_tuples=True)
    libraries.execute('''
      function GetLocale() return 'zhCN' end
      function GetRealmName() return 'TestRealm' end
      function UnitName() return 'TestPlayer' end
      function UnitClass() return '牧师','PRIEST' end
      function UnitRace() return '人类','Human' end
      function UnitFactionGroup() return 'Alliance' end
      function IsLoggedIn() return false end
      function geterrorhandler() return error end
      function getglobal(k) return _G[k] end
      function setglobal(k,v) _G[k]=v end
      function CreateFrame(kind,name,parent,template)
        local f={scripts={},events={}}
        function f:SetScript(event,fn) self.scripts[event]=fn end
        function f:RegisterEvent(event) self.events[event]=true end
        function f:UnregisterEvent(event) self.events[event]=nil end
        function f:GetScript(event) return self.scripts[event] end
        function f:HasScript(event)
          return event=='OnShow' or event=='OnHide' or event=='OnEvent' or event=='OnUpdate'
            or event=='OnEnter' or event=='OnLeave'
        end
        if name then _G[name]=f end
        return f
      end
      UIParent=CreateFrame('Frame');Minimap=CreateFrame('Frame')
      -- Existing 1.12 FrameXML handlers; initialization only wraps them.
      for _,name in ipairs({'BankFrameItemButtonGeneric_OnClick','ContainerFrameItemButton_OnClick',
        'KeyRingItemButton_OnClick','LootFrameItem_OnClick','SetItemRef','MerchantItemButton_OnClick',
        'PaperDollItemSlotButton_OnClick','QuestItem_OnClick','QuestRewardItem_OnClick',
        'QuestLogTitleButton_OnClick','QuestLogRewardItem_OnClick','SpellButton_OnClick'}) do
        _G[name]=function() end
      end
    ''')
    for path in [
        '!Libs/!MyLib/libs/LibStub.lua',
        '!Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua',
        '!Libs/Ace3/AceCore-3.0.lua', '!Libs/Ace3/AceHook-3.0.lua',
        '!Libs/Ace3/AceLocale-3.0/AceLocale-3.0.lua',
        '!Libs/Ace3/AceAddon-3.0/AceAddon-3.0.lua',
        '!Libs/Ace3/AceDB-3.0/AceDB-3.0.lua',
        '!Libs/Ace3/AceGUI-3.0/AceGUI-3.0.lua',
        '!Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua',
        '!Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua',
    ]:
        libraries.execute(read(path))
    widgets_xml = read('!Libs/Ace3/AceGUI-3.0/widgets/widgets.xml')
    widget_paths = re.findall(r'<Script file="([^"]+)"', widgets_xml)
    for path in widget_paths:
        libraries.execute(read('!Libs/Ace3/AceGUI-3.0/widgets/' + path))
    libraries.execute('''
      assert(LibStub('AceGUI-3.0'):GetWidgetVersion('Label'))
      assert(LibStub('AceGUI-3.0'):GetWidgetVersion('InteractiveLabel'))
      assert(LibStub('LibDBIcon-1.0'))
      local obj=LibStub('LibDataBroker-1.1'):NewDataObject('Test',{text='ready'})
      assert(obj.text=='ready');obj.text='changed';assert(obj.text=='changed')
    ''')
    checks.append(f'real Ace3/LDB/DBIcon initialization and {len(widget_paths)} widget registrations; LDB attribute update')

    toc = read('!Libs/!Libs.toc')
    assert 'SpellStatus-1.0\\SpellStatus-1.0.lua' in toc
    assert 'SpellStatusV2-2.0\\SpellStatusV2-2.0.lua' in toc
    status = LuaRuntime(unpack_returned_tuples=True)
    status.execute('''
      registry={};messages={};format=string.format
      function GetTime() return 10 end
      local dependency={}
      function dependency:embed(lib)
        lib.LevelDebug=function() end
        lib.Hook=function(self,name) self.hooked=self.hooked or {};self.hooked[name]=true end
        lib.RegisterEvent=function(self,name) self.registered=self.registered or {};self.registered[name]=true end
        lib.TriggerEvent=function(self,...) table.insert(messages,{...}) end
      end
      AceLibrary=setmetatable({}, {__call=function(self,name)
        return registry[name] or dependency
      end})
      function AceLibrary:IsNewVersion() return true end
      function AceLibrary:HasInstance() return true end
      function AceLibrary:Register(lib,name,version,activate)
        registry[name]=lib;activate(lib)
      end
    ''')
    status.execute(read('!Libs/SpellStatus-1.0/SpellStatus-1.0.lua'))
    status.execute(read('!Libs/SpellStatusV2-2.0/SpellStatusV2-2.0.lua'))
    status.execute('''
      local names={'SpellStatus-1.0','SpellStatusV2-2.0'}
      for _,name in ipairs(names) do
        local lib=registry[name];assert(lib and lib.hooked.UseAction)
        assert(lib.registered.SPELLCAST_STOP)
        lib.vars.ActiveId=123;lib.vars.ActiveName='TestSpell';lib.vars.Preparing=true
        assert(lib:IsActiveSpell(123,'TestSpell'))
        lib:SPELLCAST_STOP()
        assert(not lib:IsCastingOrChanneling())
      end
      assert(#messages==2)
      assert(messages[1][1]=='SpellStatus_SpellCastInstant')
      assert(messages[2][1]=='SpellStatusV2_SpellCastInstant')
    ''')
    checks.append('legacy SpellStatus and V2 both initialized; distinct instant-cast event namespaces and legacy getters retained for BigWigs')

    print(json.dumps({'ok': True, 'runtime': 'Lua 5.1', 'checks': checks,
        'scope': 'controlled behavior and font preconditions; no real game acceptance'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
