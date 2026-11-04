"""Selected Nov 3 package changes against actual Lua; offline checks only."""
from pathlib import Path
import argparse, ast, importlib.util, sys, unittest, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
parser=argparse.ArgumentParser();parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns');args,left=parser.parse_known_args();ADDONS=args.addons

def read(path):return (ADDONS/path).read_bytes().decode('utf-8-sig').replace('\r\n','\n')
def function(src,start,indent=''):
 a=src.index(start);return src[a:src.index('\n'+indent+'end',a)+len(indent)+4]
def ui():
 node=ast.parse((ROOT/'Tools/tests/test_package_merge_20261030.py').read_text(encoding='utf-8'))
 mock=next(ast.literal_eval(n.value) for n in node.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='MOCK' for t in n.targets))
 l=LuaRuntime(unpack_returned_tuples=True);l.execute(mock)
 install=l.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'));install(l.globals().methods,l.globals().object)
 l.execute('''
 function methods:RegisterForClicks(...) self.clicks={...} end
 function methods:GetFrameLevel() return self.level or 5 end
 function methods:SetFrameLevel(v) self.level=v end
 function methods:GetAlpha() return self.alpha or 1 end
 function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
 function methods:Hide() local was=self.shown;self.shown=false;if was and self.scripts.OnHide then self.scripts.OnHide() end end
 function methods:Show() self.shown=true end
 function methods:SetFocus() self.focus=true end
 function methods:ClearFocus() self.focus=false end
 for _,k in ipairs({'SetAutoFocus','SetTextInsets','SetMaxLetters','EnableKeyboard','HighlightText','SetNumeric','SetMultiLine','SetJustifyH','SetJustifyV'}) do methods[k]=function() end end
 function fire(o,e,a) this=o;event=e;arg1=a;if o.scripts.OnEvent then o.scripts.OnEvent() end end
 function tick(o,t) clock=t;this=o;arg1=.1;if o.scripts.OnUpdate then o.scripts.OnUpdate() end end
 function up(fn,target,seen)
  seen=seen or {};if seen[fn] then return end;seen[fn]=true
  for i=1,100 do local name,v=debug.getupvalue(fn,i);if not name then break end
   if name==target then return v end
   if type(v)=='function' then local f=up(v,target,seen);if f~=nil then return f end end
  end
 end
 UISpecialFrames={}
 ''');return l

class MergeChecks(unittest.TestCase):
 def test_bigwigs_three_dragon_events_and_immediate_cooldown(self):
  for name in ['Firemaw','Ebonroc','Flamegor']:
   with self.subTest(boss=name):
    l=ui();l.execute("""
 L=setmetatable({}, {__index=function(t,k) return k end});function L:RegisterTranslations(locale,fn) if locale=='zhCN' then for k,v in pairs(fn()) do self[k]=v end end end
 boss={};BigWigs={ModuleDeclaration=function() return boss,L end};function AceLibrary() return setmetatable({}, {__index=function(t,k) return k end}) end
 calls={};bars={};messages={};function boss:Sync(s) table.insert(calls,s) end;function boss:CancelDelayedMessage() end;function boss:RemoveBar() end;function boss:Bar(n,t) table.insert(bars,{n,t}) end;function boss:DelayedMessage(t) table.insert(messages,t) end;function boss:DelayedBar() error('cooldown must start immediately') end
 """)
    l.execute(read('BigWigs/Raids/BWL/'+name+'.lua'));l.execute("boss:Event(L.trigger_wingBuffet..'。');assert(#calls==1);boss:WingBuffet();assert(#bars==2 and bars[2][2]==30 and messages[1]==28);boss:WingBuffet();assert(#bars==4)")
 def test_bigwigs_background_and_placeholder_are_independent(self):
  l=ui();l.execute("""BigWigsVerticalBars={db={profile={enabled=true,bgVisible=true}},frames={anchor={pathBG=object('Texture')}}};PLACEHOLDER_BAR_PATTERNS={'^target '};added=0;function AddTimelineBar() added=added+1 end;function BigWigsVerticalBars:RefreshShownState() end""")
  src=read('BigWigs/Plugins/VerticalBars.lua')
  for name in ['ApplyBackgroundVisibility','BigWigs_StartBar']:l.execute(function(src,'function BigWigsVerticalBars:'+name+'('))
  l.execute("""local b=BigWigsVerticalBars;b:ApplyBackgroundVisibility();assert(b.frames.anchor.pathBG.alpha==1);b.db.profile.bgVisible=false;b:ApplyBackgroundVisibility();assert(b.frames.anchor.pathBG.alpha==.05);b:BigWigs_StartBar('boss','Target Andorov',3600,'icon');assert(added==0);b:BigWigs_StartBar('boss','Wing Buffet',30,'icon');assert(added==1)""")
 def test_combo_saved_options_migrate_without_reopening_explicit_false(self):
  l=self.cards();l.execute(read('Cat2/Cards/Logic/FlowJumpComboPoints.lua'))
  src=read('Cat2/Core/Persistence.lua');a=src.index('local function FindCard(');b=src.index('function Cat2.LoadConfigurationData()',a)
  l.execute('local removedCardIds,legacyCardIds,legacyCardOptionValues={},{},{}\n'+src[a:b]+'\nrestore=RestoreStep')
  l.execute("""
 for value=0,5 do local row=restore({id='logic_flow_jump_combo_points',optionValues={comboPoints=value}});for i=1,5 do assert(row.optionValues['comboPoints'..i]==(i==value)) end end
 local row=restore({id='logic_flow_jump_combo_points',optionValues={comboPoints=5,comboPoints5=false}});assert(row.optionValues.comboPoints5==false)
 """)
 def raid(self,setup=''):
  l=ui();l.execute('''
 roster={'Self','NewHealer'};reported=2
 function UnitName() return 'Self' end
 function GetNumRaidMembers() return reported end
 function GetRaidRosterInfo(i) if roster[i] then return roster[i],0,1,60,'牧师','PRIEST',nil,true end end
 function UnitClass() return '牧师','PRIEST' end
 RCBA_AssignDB={list={Fortitude={[1]='OldHealer',Nums=1,Names={'OldHealer'}}},roster={'Self','OldHealer'}}
 RCBA_TaskDB={tasks={'keep-task'}}
 ''');l.execute(setup);l.execute(read('RaidCheck/RaidCheckBuffAssign.lua'));return l
 def test_raid_excludes_self_waits_and_resets_once(self):
  l=self.raid();l.execute('''
 clock=0;fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED');assert(not RCBA_CheckNewRaid())
 tick(RCBA_AssignSaveFrame,1.9);assert(RCBA_AssignDB.list.Fortitude[1]=='OldHealer')
 tick(RCBA_AssignSaveFrame,2.1);assert(RCBA_AssignDB.list.Fortitude[1]~='OldHealer')
 assert(RCBA_TaskDB.tasks[1]=='keep-task' and #DEFAULT_CHAT_FRAME.lines==1)
 tick(RCBA_AssignSaveFrame,5);assert(#DEFAULT_CHAT_FRAME.lines==1)
 assert(RCBA_AssignDB.roster[1]=='Self' and RCBA_AssignDB.roster[2]=='NewHealer')
 ''')
 def test_raid_preserves_same_group_and_partial_rosters(self):
  for setup in ["roster={'Self','OldHealer','NewHealer'};reported=3", "roster={'Self'};reported=2", "roster={'Self'};reported=1", "reported=0;roster={}"]:
   with self.subTest(setup=setup):
    l=self.raid(setup);l.execute("clock=0;fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED');tick(RCBA_AssignSaveFrame,3);tick(RCBA_AssignSaveFrame,6);assert(RCBA_AssignDB.list.Fortitude[1]=='OldHealer' and #DEFAULT_CHAT_FRAME.lines==0)")
 def test_raid_changing_roster_restarts_confirmation_and_manual_clear(self):
  l=self.raid();l.execute('''
 clock=0;fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED')
 clock=1;roster[2]='Another';fire(RCBA_AssignSaveFrame,'RAID_ROSTER_UPDATE')
 tick(RCBA_AssignSaveFrame,2.2);assert(#DEFAULT_CHAT_FRAME.lines==0)
 RCBA_ClearAssign();tick(RCBA_AssignSaveFrame,5);assert(#DEFAULT_CHAT_FRAME.lines==0)
 assert(RCBA_TaskDB.tasks[1]=='keep-task')
 ''')
 def test_raid_saved_variable_lifecycle_and_legacy_baseline(self):
  l=self.raid();l.execute("clock=0;tick(RCBA_AssignSaveFrame,3);assert(RCBA_AssignDB.list.Fortitude[1]=='OldHealer');RCBA_AssignDB.roster=nil;fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED');tick(RCBA_AssignSaveFrame,6);assert(#DEFAULT_CHAT_FRAME.lines==0 and RCBA_AssignDB.list.Fortitude[1]=='OldHealer' and RCBA_AssignDB.roster[2]=='NewHealer')")
  l=self.raid('RCBA_AssignDB=nil');l.execute("clock=0;tick(RCBA_AssignSaveFrame,3);assert(RCBA_AssignDB==nil);fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED');tick(RCBA_AssignSaveFrame,6);assert(type(RCBA_AssignDB.list)=='table')")
  l=self.raid("RCBA_AssignDB.roster={'Self'}");l.execute("clock=0;fire(RCBA_AssignSaveFrame,'VARIABLES_LOADED');tick(RCBA_AssignSaveFrame,5);assert(#DEFAULT_CHAT_FRAME.lines==0)")
 def test_skin_font_failures_absence_and_reuse(self):
  for absent in [True,False]:
   for fail in [False,True]:
    with self.subTest(absent=absent,fail=fail):
     l=ui();l.execute('''
 pfUI_config={global={font_size='12'}};pfUI={font_default='candidate-font',addonskinner={}}
 local env={StripTextures=function() end,CreateBackdrop=function(f) f.backdrop=object('Frame',nil,f) end,CreateBackdropShadow=function() end,SkinButton=function() end,SkinCloseButton=function() end,SkinScrollbar=function() end}
 function pfUI:GetEnvironment() return env end
 function pfUI.addonskinner:RegisterSkin(n,fn) skinFn=fn end
 ''')
     if not absent:l.execute("ABP_ExportFrame=object('Frame','ABP_ExportFrame',UIParent)")
     if fail:l.execute("failedFontPaths['candidate-font']=true")
     l.execute(read('pfUI-addonskinner/skins/ActionBarProfiles.lua'));l.execute('skinFn();local n=#objects;for i=1,30 do skinFn() end;assert(#objects==n)')
     if not absent:l.execute("ABP_PfTitle:SetText('');ABP_PfTitle:Hide();ABP_PfTitle:SetText('title');ABP_PfTitle:Show();assert(ABP_PfTitle.font)")
 def cards(self):
  l=ui();l.execute('''Cat2={UI={ApplyFlatBackdrop=function() end,ShowMainWindowDim=function() end,HideMainWindowDim=function() end},PlayerInformation={temporary={}}};''');l.execute(read('Cat2/Core/CardRegistry.lua'));return l
 def test_flow_cards_strict_thresholds_and_combo_selection(self):
  l=self.cards()
  for name in ['FlowJumpSelfHealthBelow','FlowJumpSelfHealthPercentBelow','FlowJumpComboPoints']:l.execute(read('Cat2/Cards/Logic/'+name+'.lua'))
  l.execute('''
 local b=Cat2.CardRegistry.ById
 local p={health=3000,percentHealth=50,targetExists=true,targetCombo=5};local opts={};local c={playerInformation={temporary=p},GetStepOption=function(self,s,k) return opts[k] end}
 local hp=b.logic_flow_jump_self_health_below;assert(not hp.Execute(c,{}));p.health=2999;opts.targetIndex=12;assert(Cat2.IsJumpResult(hp.Execute(c,{})))
 local pct=b.logic_flow_jump_self_health_percent_below;assert(not pct.Execute(c,{}));p.percentHealth=49.9;assert(Cat2.IsJumpResult(pct.Execute(c,{})))
 local combo=b.logic_flow_jump_combo_points;assert(not combo.Execute(c,{}));opts.comboPoints5=true;assert(Cat2.IsJumpResult(combo.Execute(c,{})));p.targetCombo=1;assert(not combo.Execute(c,{}));opts.comboPoints1=true;assert(Cat2.IsJumpResult(combo.Execute(c,{})));p.targetExists=false;assert(not combo.Execute(c,{}))
 ''')
 def test_checkbox_defaults_false_exclusivity_and_ui_cancel_save_font_failure(self):
  l=self.cards();l.globals().failedFontPaths['Fonts\\FRIZQT__.TTF']=True
  l.execute(read('Cat2/UI/Notice.lua'));l.execute('''
 failedFontPaths["Fonts\\FRIZQT__.TTF"]=true
 step={id='test',name='test',optionSchema={{key='a',type='boolean',default=true,exclusiveGroup='g'},{key='b',type='boolean',default=false,exclusiveGroup='g'}},optionValues={}}
 assert(Cat2.ResolveStepOption(step,'a') and not Cat2.ResolveStepOption(step,'b'))
 saved=nil;Cat2.UI.ShowCardOptionEditor(step,function(v) saved=v end)
 local rows=up(Cat2.UI.ShowCardOptionEditor,'cardOptionsRows');local window=up(Cat2.UI.ShowCardOptionEditor,'cardOptionsWindow')
 assert(rows[1].checkboxText.font and rows[2].checkboxText.font)
 rows[2].checkbox.scripts.OnClick();assert(step.optionValues.a==nil and step.optionValues.b==nil and saved==nil)
 window.submit();assert(saved.a==false and saved.b==true)
 Cat2.UI.ShowCardOptionEditor(step,function(v) saved=v end);local n=#objects
 rows[1].checkbox.scripts.OnClick();rows[1].checkboxReset.scripts.OnClick();window.submit();assert(saved.a==nil and saved.b==nil)
 saved=nil;Cat2.UI.ShowCardOptionEditor(step,function(v) saved=v end);rows[1].checkbox.scripts.OnClick()
 for _,o in ipairs(objects) do if o.kind=='FontString' and o.text=='取消' and o.parent.parent==window then o.parent.scripts.OnClick();break end end
 assert(saved==nil and step.optionValues.a==nil)
 Cat2.UI.ShowCardOptionEditor(step,function() end);assert(#objects==n)
 ''')
 def test_warlock_integer_and_fractional_duration_patterns(self):
  for duration in ['18','18.5']:
   l=self.cards();l.execute("duration="+repr(duration)+";Cat2.IsTalentLearned=function() return 0 end;Cat2.Match=string.match;Cat2.GetSpellTooltip=function() return '腐蚀目标，在'..duration..'秒内造成伤害；使其在'..duration..'秒内；持续'..duration..'秒；降低'..duration..'秒；在'..duration..'秒内' end;setmetatable(Cat2,{__index=function(t,k) if string.sub(k,1,3)=='Set' then return function(v) actual=v end end end})")
   for name in ['Corruption','CurseOfAgony','SiphonLife']:
    l.execute(read('Cat2/Cards/Warlock/'+name+'.lua'));l.execute('actual=nil;Cat2.CardRegistry.Cards[#Cat2.CardRegistry.Cards].RefreshRuntimeData()');self.assertEqual(l.globals().actual,float(duration))
 def test_monitor_xml_dispatch_once_and_respects_personal_guards(self):
  l=ui();l.execute('''C={bars={monitorenable='1',monitordisplayonly='0',keydown='0',altself='1',animmode='keypress'}};pfUI={hoverbind=object('Frame')};pfUI.hoverbind:Hide();ChatFrameEditBox=object('Frame');ChatFrameEditBox:Hide();mon={buttons={}};for i=1,32 do mon.buttons[i]={slot=i,highlight=object('Texture'),animation=object('Frame')} end;calls={};function HasAction(s) return s>0 end;function UseAction(s,a,selfcast) table.insert(calls,{s,selfcast}) end;function IsAltKeyDown() return true end;function MouseIsOver() return false end''')
  l.execute(function(read('pfUI/modules/actionbar.lua'),'    _G.pfUIActionMonitorButton = function(idx)','    '))
  nodes=[n for n in ET.parse(ADDONS/'pfUI/Bindings.xml').getroot() if n.attrib.get('name','').startswith('PFMONITORBUTTON')];self.assertEqual(len(nodes),32)
  for mode in ['0','1']:
   l.globals().C.bars.keydown=mode
   for idx,n in enumerate(nodes,1):
    l.execute('calls={}');l.globals().keystate='down';l.execute(n.text);l.globals().keystate='up';l.execute(n.text);l.execute('assert(#calls==1 and calls[1][1]=='+str(idx)+' and calls[1][2]==true)')
  for block,unblock in [("C.bars.monitordisplayonly='1'","C.bars.monitordisplayonly='0'"),("ChatFrameEditBox:Show()","ChatFrameEditBox:Hide()"),("pfUI.hoverbind:Show()","pfUI.hoverbind:Hide()"),("mon.dragButton={}","mon.dragButton=nil"),("C.bars.monitorenable='0'","C.bars.monitorenable='1'")]:
   l.execute('calls={};'+block);l.globals().keystate='down';l.execute(nodes[0].text);l.globals().keystate='up';l.execute(nodes[0].text);l.execute('assert(#calls==0);'+unblock)
 def test_white_black_lists_and_matching_preserve_legacy_default(self):
  l=ui();l.execute('''C={buffs={separatebuffs='1',filter='whitelist',whitelist='123',blacklist='',separatelist='狂热',sepdebufflist='',sepmatch='smart'}};pfUI={api={GetPlayerBuffSpellId=function() return 999 end},buff={}};FilterGroupAll={mode='filter',wl='whitelist',bl='blacklist'};getn=table.getn;strlower=string.lower;strfind=string.find;function pfUI.buff:GetBuffId(b) return b.id end;function pfUI.buff:GetBuffName(b) return b.name end''')
  src=read('pfUI/modules/buff.lua')
  for name in ['GetAuraFilter','AuraVisible','SepMatchMode','SepEntryLabel','ParseSepEntries','SepEntryMatch','SepIndex','TargetSepIndex']:l.execute(function(src,'  function pfUI.buff:'+name+'(','  '))
  l.execute('''
 assert(pfUI.buff:AuraVisible({id=123}) and not pfUI.buff:AuraVisible({id=999}))
 C.buffs.filter='blacklist';C.buffs.blacklist='123';assert(not pfUI.buff:AuraVisible({id=123}) and pfUI.buff:AuraVisible({id=999}))
 C.buffs.filter='';C.buffs.blacklist='';C.buffs.whitelist='';assert(pfUI.buff:AuraVisible({id=999}))
 C.buffs.sepmatch=nil;assert(pfUI.buff:SepMatchMode()=='smart')
 assert(pfUI.buff:SepIndex({name='狂热梦想'},'b'))
 C.buffs.sepmatch='exact';assert(not pfUI.buff:SepIndex({name='狂热梦想'},'b'));assert(pfUI.buff:SepIndex({name='狂热'},'b'))
 C.buffs.separatelist='*狂热';assert(pfUI.buff:SepIndex({name='狂热梦想'},'b'))
 C.buffs.separatelist='=狂热';assert(not pfUI.buff:SepIndex({name='狂热梦想'},'b'))
 ''')
 def test_sell_database_survives_saved_replacement_and_no_merchant_scan(self):
  l=ui();l.execute('Stubby={RegisterFunctionHook=function() end}');l.execute(read('S_ItemTip/SellValue.lua'));l.execute(read('S_ItemTip/Database.lua'));l.execute('''
 this=object('Frame');SellValue_OnLoad();assert(SellValues[22505]==104517)
 local initial=SellValues;event='PLAYER_ENTERING_WORLD';SellValue_OnEvent();assert(SellValues==initial)
 SellValues={[22505]=88};event='VARIABLES_LOADED';SellValue_OnEvent();assert(SellValues[22505]==104517 and SellValues~=initial)
 initial=SellValues;event='MERCHANT_SHOW';SellValue_OnEvent();assert(SellValues==initial and SellValue_MerchantScan==nil)
 ''')
 def test_count_tooltip_full_capacity_and_total(self):
  for initial in [2,29,30]:
   with self.subTest(initial=initial):
    l=ui();l.execute("""function GetRealmName() return 'Realm' end;function UnitName() return 'Self' end;function GetMouseFocus() return nil end;GameTooltip=object('GameTooltip','GameTooltip',UIParent);GameTooltip.lines=0;function methods:NumLines() return self.lines or 0 end;function methods:AddLine(s) assert(self.lines<30);self.lines=self.lines+1 end;doubles={};function methods:AddDoubleLine(s,n) assert(self.lines<30);self.lines=self.lines+1;table.insert(doubles,{s,n}) end;GameTooltipTextLeft1=object('FontString');GameTooltipTextLeft1:SetFontObject(GameFontNormal);GameTooltipTextLeft1:SetText('Item');GameTooltipTextLeft2=object('FontString');GameTooltipTextLeft2:SetFontObject(GameFontNormal);GameTooltipTextLeft2:SetText('not-quest');S_CountDB={['Realm-A']={bags={Item=2}},['Realm-B']={bank={Item=3}}}""")
    l.execute(read('S_ItemTip/ItemCount.lua'));l.globals().GameTooltip.lines=initial;l.execute("S_ItemTipCountFrame.scripts.OnShow();assert(GameTooltip.lines<=30)")
    if initial==2:l.execute("assert(doubles[#doubles][1]=='合计' and doubles[#doubles][2]==5)")
    else:l.execute('assert(#doubles=='+str(30-initial)+')')
 def test_personal_score_line_full_capacity_and_owned_refresh(self):
  spec=importlib.util.spec_from_file_location('score_suite',ROOT/'Tools/tests/test_s_itemtip_merge.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
  l=mod.Suite(ADDONS/'S_ItemTip').runtime();l.execute('''
 function methods:ClearLines() for i=1,(self.lines or 0) do local f=_G[self.name..'TextLeft'..i];if f then f:SetText('') end end;self.lines=0 end
 GameTooltip:ClearLines();for i=1,30 do GameTooltip:AddLine('line'..i) end
 GameTooltip:SetUnit('player');assert(GameTooltip:NumLines()==30 and GameTooltipTextLeft30:GetText()=='line30')
 GameTooltip:ClearLines();GameTooltip:SetUnit('player');local n=GameTooltip:NumLines();assert(n>0)
 for i=n+1,30 do GameTooltip:AddLine('line'..i) end
 inventories.player[1]=101;dispatch(ItemSocre,'UNIT_INVENTORY_CHANGED','player');assert(GameTooltip:NumLines()==30)
 ''')
 def test_abp_sorted_menus_keep_personal_restore_guards(self):
  l=ui();l.execute('''StaticPopupDialogs={};SAVE='save';CANCEL='cancel';function UnitName() return 'Self' end;function GetCVar() return 'Realm' end;function UIDropDownMenu_Initialize() end;function ABPButton_UpdatePosition() end;function cos() return 0 end;function sin() return 0 end;ActionBarProfiles_IconFrame=object('Frame');Minimap=object('Frame');menus={};function UIDropDownMenu_AddButton(v) table.insert(menus,v) end''');l.execute(read('ActionBarProfiles/ActionBarProfiles.lua'));l.execute('''
 ABP_ButtonPosition=0;event='VARIABLES_LOADED';ABP_OnEvent();ABP_Layout['Self of Realm']={Z={},A={},M={}}
 this=object('Frame');for _,which in ipairs({'Save menu','Delete menu','root'}) do UIDROPDOWNMENU_MENU_VALUE=which;menus={};ABP_DropDownMenu_OnLoad();assert(menus[2].text=='A' and menus[3].text=='M' and menus[4].text=='Z') end
 ''')

if __name__=='__main__':unittest.main(argv=[sys.argv[0]]+left,verbosity=2)
