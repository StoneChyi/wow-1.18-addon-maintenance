"""Execute fused addon behavior offline; native auction scheduling is tested in Lua 5.0 separately."""
from pathlib import Path
import argparse,sys,unittest,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_catalog import runtime
from test_package_merge_20261104 import ui,function
parser=argparse.ArgumentParser();parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns');args,left=parser.parse_known_args();ADDONS=args.addons
def read(p):return (ADDONS/p).read_text(encoding='utf-8-sig').replace('\r\n','\n')
def module(name,setup=''):
 l=runtime();l.execute('''
 clock=0;scheduled={};cancelled={};sent={}
 function GetTime()return clock end
 function Automaton:print()end
 function GetContainerItemLink(bag,slot)return '|Hitem:'..bag..':'..slot..'|h[BagItem]|h'end
 function GetItemInfo(id)return 'Item'..id,'item:'..id..':0:0:0',1 end
 function GetItemQualityColor()return 1,1,1,'|cffffffff'end
 function SendChatMessage(...)table.insert(sent,{...})end
 function UnitAffectingCombat()return combat end
 nativeFrames={};local create=CreateFrame
 function CreateFrame(...)local frame=create(...);table.insert(nativeFrames,frame);return frame end
 local methods=getmetatable(UIParent).__index
 function methods:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
 ''');l.execute(setup);l.execute(read('Automatonex/Modules/'+name+'.lua'))
 l.execute('''
 m=Automaton.modules['''+repr(name)+''']
 function m:ScheduleRepeatingEvent(callback,delay)local id=#scheduled+1;scheduled[id]={callback=callback,delay=delay};return id end
 function m:CancelScheduledEvent(id)cancelled[id]=true end
 function m:UnregisterAllEvents()self.events={}end
 function m:Print()end
 m:OnInitialize()
 ''');return l
class Fusion(unittest.TestCase):
 def test_shout_preserves_all_characters_and_bag_slots(self):
  l=module('AutoShout',"""
 Automaton.dbs.AutoShout={char={},profile={shoutEnabled=true,messages={TestPlayer='中文{item1}',Other='Other character'},intervals={TestPlayer=17,Other=25},channel='guild',inCombat=true,items={{container=2,slot=3},{container=0,slot=5}},autoReplyEnabled=true,autoReplyMessages={default='legacy reply'}}}
 """);l.execute('''
 assert(m.db.char.shouts[1].message=='中文{item1}' and m.db.char.shouts[1].interval==17)
 assert(m.db.char.shouts[1].enabled and m.db.char.shouts[1].inCombat)
 assert(m.db.profile.messages.Other=='Other character' and #m.db.profile.items==2)
 assert(m.db.profile.items[1].mode=='slot')
 m:DoShout(1);assert(sent[1][1]=='中文|Hitem:2:3|h[BagItem]|h' and sent[1][2]=='GUILD')
 assert(m:MatchReplyPair('a long whisper with more than fourteen bytes')=='legacy reply')
 m.db.char.shouts[1].message='new choice';m:OnInitialize();assert(m.db.char.shouts[1].message=='new choice')
 m.db.char={};function UnitName()return 'Other'end
 ''')
  # Reload chunk to model next login's captured player identity with the same profile.
  l.execute(read('Automatonex/Modules/AutoShout.lua'));l.execute('m=Automaton.modules.AutoShout;m:OnInitialize();assert(m.db.char.shouts[1].message=="Other character" and m.db.char.shouts[1].interval==25)')
 def test_shout_three_group_migration_and_explicit_false(self):
  l=module('AutoShout',"""Automaton.dbs.AutoShout={char={},profile={shouts={{enabled=false,messages={TestPlayer='first'},intervals={TestPlayer=20},channel='say',inCombat=false},{enabled=true,messages={TestPlayer='second'},intervals={TestPlayer=30},channel='guild',inCombat=true},{enabled=true,messages={TestPlayer='third'},intervals={TestPlayer=40},channel='party'}}}}""")
  l.execute("assert(#m.db.char.shouts==3 and not m.db.char.shouts[1].enabled and m.db.char.shouts[2].message=='second' and m.db.char.shouts[3].message=='third')")
 def test_shout_specific_and_blank_rules_combat_and_id_mode(self):
  l=module('AutoShout');l.execute('''
 m.db.profile.autoReplyPairs.TestPlayer={{passphrase='',message='fallback'},{passphrase='暗号很长也可以',message='specific {item1}'}}
 m.db.profile.items[1]={mode='id',itemID=123};m.db.profile.autoReplyEnabled=true
 assert(m:MatchReplyPair(' 暗号很长也可以 ')=='specific {item1}')
 combat=true;m:CHAT_MSG_WHISPER('暗号很长也可以','Sender');assert(#sent==0)
 combat=false;m:CHAT_MSG_WHISPER('暗号很长也可以','Sender');assert(string.find(sent[1][1],'|Hitem:123:0:0:0',1,true))
 m:CHAT_MSG_WHISPER('any longer unrelated message','Sender');assert(sent[2][1]=='fallback')
 ''')
 def test_shout_list_editing_defers_and_keeps_index_callbacks(self):
  l=module('AutoShout');l.execute('''
 m:AddItem();m:AddItem();assert(#m.db.profile.items==3)
 fire(m.optionsDriver,'OnUpdate');assert(not m.optionsDriver.scripts.OnUpdate)
 m._options.item2.args.container.set(4);m._options.item3.args.container.set(2)
 assert(m.db.profile.items[2].container==4 and m.db.profile.items[3].container==2)
 m._options.item2.args.mode.set('slot');assert(m.db.profile.items[2].mode=='slot')
 m:AddShout();m:AddShout();fire(m.optionsDriver,'OnUpdate');assert(#m.db.char.shouts==3)
 m.db.char.shouts[2].message='second';m:MoveShout(2,1);assert(m.db.char.shouts[3].message=='second')
 m:RemoveShout(3);assert(#m.db.char.shouts==2)
 ''')
 def test_shout_disable_cancels_cleanup_and_all_timers(self):
  l=module('AutoShout');l.execute('''
 m.db.char.shouts[1].enabled=true;m:OnEnable();local cleanup=m.silentCleanupTimer;local cache=m.itemCacheTimer
 m:OnDisable();assert(cancelled[cleanup] and cancelled[cache] and m.silentCleanupTimer==nil)
 m:OnEnable();assert(m.silentCleanupTimer~=cleanup)
 ''')
 def test_shout_utf8_cursor_insert_saves_and_focus_hooks_stay_bounded(self):
  l=module('AutoShout');l.execute('''
 local edit=obj('EditBox');edit.cursor=3;edit.text='中文'
 function edit:GetCursorPosition()return self.cursor end
 function edit:SetCursorPosition(pos)self.cursor=pos end
 function edit:HasFocus()return true end
 local lost=0;edit:SetScript('OnEditFocusLost',function()lost=lost+1 end)
 for i=1,30 do m._options.shout1.args.message.onCreateEdit(edit)end
 fire(edit,'OnEditFocusGained');fire(edit,'OnEditFocusLost');assert(lost==1)
 m:InsertItemToken(1);assert(edit:GetText()=='中{item1}文' and m.db.char.shouts[1].message==edit:GetText())
 ''')
 def test_login_actions_are_off_and_delays_ordered_on_112(self):
  l=module('AutoCmd');l.execute('''
 assert(C_Timer==nil and m.db.profile.disabled==true)
 calls={};function m:ExecuteAndReport(cmd)table.insert(calls,{cmd,clock})end
 m.db.char.commands={{cmd='first',on=true,delay=3},{cmd='second',on=true,delay=0},{cmd='third',on=false,delay=0}}
 m.db.profile.loginDelay=5;m.db.profile.interval=1;m:RunAll(false);assert(#calls==0)
 ''')
  # Find scheduler by its actual OnUpdate; world watcher has no update handler.
  l.execute('''
 local scheduler
 for _,o in ipairs(nativeFrames)do if o.scripts and o.scripts.OnUpdate then scheduler=o end end
 assert(scheduler)
 clock=7.9;fire(scheduler,'OnUpdate');assert(#calls==0)
 clock=8;fire(scheduler,'OnUpdate');assert(#calls==1 and calls[1][1]=='first')
 clock=9;fire(scheduler,'OnUpdate');assert(#calls==2 and calls[2][1]=='second' and not scheduler:IsShown())
 m:RunAll(true);m:OnDisable();clock=100;fire(scheduler,'OnUpdate');assert(#calls==2)
 ''')
 def test_login_handlers_do_not_retry_failure_and_late_registration_works(self):
  l=module('AutoCmd');l.execute('''
 assert(m:ResolveSlashHandler('/late')==nil)
 SLASH_LATE1='/late';local calls=0;SlashCmdList.LATE=function()calls=calls+1;error('after side effect')end
 local ok=m:ExecuteCommand('/late test');assert(not ok and calls==1)
 local box={text='draft',GetText=function(self)return self.text end,SetText=function(self,s)self.text=s end}
 DEFAULT_CHAT_FRAME.editBox=box;assert(not m:SendViaChat('/cast Test') and box.text=='draft')
 ''')
 def test_media_migration_nested_profiles_cycles_and_path_spellings(self):
  l=LuaRuntime();l.execute('pfUI={};pfUI_config={};pfUI_profiles={};pfUI_addon_profiles={}')
  l.execute(function(read('pfUI/api/config.lua'),'function pfUI:MigrateMediaPaths('))
  l.execute(r'''
 local root={texture='Interface\\AddOns\\pfUI-CustomMedia\\bars\\pfUI-F.tga',child={texture='INTERFACE/ADDONS/PFUI-CUSTOMMEDIA/BARS/pfUI-Z.tga'},plain='solid'}
 root.cycle=root;pfUI:MigrateMediaPaths(root)
 assert(root.texture=='Interface\\AddOns\\pfUI\\img\\bars\\pfUI-F.tga')
 assert(root.child.texture=='Interface\\AddOns\\pfUI\\img\\bars\\pfUI-Z.tga' and root.plain=='solid' and root.cycle==root)
 pfUI:MigrateMediaPaths(root);assert(root.plain=='solid')
 ''')
 def test_media_preview_font_fallback_reuses_swatches_and_applies(self):
  l=ui();l.execute('''
 C={unitframes={player={bartexture='old',pbartexture='old'},target={bartexture='old'}},appearance={border={color='.4,.4,.4,1'},castbar={}},nameplates={},panel={xp={}},tooltip={statusbar={}}};pfUI_config=C
 pfUI={gui={UpdaterFunctions={player=function()refreshed=true end},Reload=function()reloaded=true end}}
 function pfUI:RegisterModule(name,version,callback)callback()end
 function pfUI.gui.CreateGUIEntry(title,parent,fn)page=fn end
 function pfUI.gui.CreateConfig(...)end
 function strsplit(sep,s)return '.4','.4','.4','1'end
 ''');l.execute(read('pfUI/modules/custommedia.lua'));l.execute('''
 this=object('Frame');this.objectCount=0;local content=this;page();assert(#content.mediaSwatches==26)
 local first=content.mediaSwatches[1];assert(first.label:GetText()=='pfUI-A')
 this=first;first.scripts.OnClick();assert(refreshed and string.find(C.unitframes.player.bartexture,'pfUI\\\\img\\\\bars',1,true))
 this=content;page();assert(content.mediaSwatches[1]==first and #content.mediaSwatches==26)
 ''')
 def test_tmog_saved_config_migrates_once_and_refills_after_injection(self):
  l=LuaRuntime();l.execute("Tmog={L=setmetatable({},{__index=function(_,k)return k end})};function UnitClass()return 'Paladin','PALADIN'end;function UnitRace()return 'Human','Human'end;function UnitSex()return 2 end;function GetAddOnMetadata()return '5.0.3'end")
  l.execute(read('Tmog/Constants.lua'));l.execute('''
 TmogConfig=nil;TMOG_LOCKED=true;TMOG_POSITION={321,123};Tmog.InitializeConfig()
 assert(TmogConfig.locked and TmogConfig.buttonX==321 and TmogConfig.collected and TmogConfig.notCollected)
 TmogConfig.buttonX=456;TmogConfig.locked=false;Tmog.InitializeConfig();assert(TmogConfig.buttonX==456 and not TmogConfig.locked)
 TmogConfig={onlyUsable=true,buttonX=88,locked=false};Tmog.InitializeConfig();assert(TmogConfig.onlyUsable and TmogConfig.buttonX==88 and not TmogConfig.locked)
 ''')
 def outfits(self):
  l=ui();l.execute('''
 Tmog={L=setmetatable({},{__index=function(_,k)return k end}),OrderLink={1,5,16,17},CurrentGear={[1]=123,[5]=456},currentTab='ITEMS'}
 TMOG_PLAYER_OUTFITS={};function Tmog.CacheItem()end;function Tmog.strtrim(s)return string.gsub(s,'^%s*(.-)%s*$','%1')end
 function Tmog.UpdateOutfitButtons()end
 DropDownList1=object('Frame');DropDownList1Button1=object('Button');function SetItemRef()end
 floor=math.floor;mod=math.mod
 ''');l.execute(read('Tmog/Outfits.lua'));l.execute('function Tmog.UpdateOutfitButtons()end');return l
 def test_tmog_legacy_and_chat_link_roundtrips_save_rename_delete(self):
  l=self.outfits();l.execute('''
 Tmog.currentOutfit='Test';Tmog.SaveOutfit();assert(#TMOG_PLAYER_OUTFITS==1 and TMOG_PLAYER_OUTFITS[1][1]==123)
 local code=Tmog.GetOutfitLink('Test');local decoded=Tmog.ValidateOutfitCode(code);assert(decoded[1]==123 and decoded[5]==456)
 local old=Tmog.ValidateOutfitCode('T.O.L.1:123;5:456;');assert(old[1]==123 and old[5]==456)
 assert(not Tmog.ValidateOutfitCode('T.O.L.') and not Tmog.ParseOutfitLink('outfit:malformed'))
 Tmog.RenameOutfit('Test','Renamed');assert(Tmog.currentOutfit=='Renamed' and TMOG_PLAYER_OUTFITS[1].name=='Renamed')
 TmogDeleteOutfitButton=object('Button');Tmog.DeleteOutfit('Renamed');assert(#TMOG_PLAYER_OUTFITS==0)
 ''')
 def test_tmog_all_xml_fontstrings_have_templates(self):
  for p in (ADDONS/'Tmog').glob('*.xml'):
   for node in ET.parse(p).iter('FontString'):self.assertTrue(node.get('inherits'),(p,node.attrib))
 def test_tmog_personal_skin_tracks_renamed_previews_and_selection(self):
  l=ui();l.execute('''
 C={};pfUI_config={appearance={border={color='.4,.4,.4,1'}}}
 pfUI={api={GetStringColor=function()return .4,.4,.4,1 end,GetBorderSize=function()return 1,1 end,
 CreateBackdrop=function()end,SkinButton=function()end},addonskinner={RegisterSkin=function(self,name,fn)skin=fn end}}
 Tmog={PreviewFrames={},currentTab='ITEMS',currentSlot=1,CurrentGear={[1]=123},ItemDisplayGroup={}}
 TmogFrameTab1=object('Button');TmogFrameTab2=object('Button')
 TmogFramePreview1=object('Frame','TmogFramePreview1');local preview=TmogFramePreview1;preview.itemID=123
 TmogFramePreview1Button=object('Button','TmogFramePreview1Button');local button=TmogFramePreview1Button
 function button:LockHighlight()self.locked=true end;function button:UnlockHighlight()self.locked=false end
 function button:GetID()return 1 end
 function preview:SetBackdropBorderColor(r,g,b,a)self.color={r,g,b,a}end
 Tmog.PreviewFrames[1]=preview
 function Tmog.UpdatePreviews(arg)TmogFramePreview1Button:LockHighlight();return arg end
 function Tmog.SwitchTab(tab)Tmog.currentTab=tab end;function Tmog.Search()end
 ''');l.execute(read('pfUI-addonskinner/skins/Tmog.lua'));l.execute('''
 skin();assert(Tmog.pfDrawWrapped and TmogFramePreview1Button.pfTmogSelectionWrapped)
 assert(TmogFrameTab1.pfTmogTab and TmogFrameTab2.pfTmogTab)
 assert(TmogFramePreview1.color[1]==1)
 local first=Tmog.UpdatePreviews;skin();assert(first==Tmog.UpdatePreviews)
 assert(Tmog.UpdatePreviews('result')=='result' and TmogFramePreview1.color[1]==1)
 TmogFramePreview1Button:UnlockHighlight();assert(TmogFramePreview1.color[1]==.4)
 ''')
 def test_freedom_filter_default_independent_and_optional_gates(self):
  l=LuaRuntime();l.execute('''
 GoubayuHeal={Config={dispel_enabled=0,dispel_filters={Snare=0}}};DispelUsable={Snare={name='Freedom'}};DispelPrio={};visited=0
 function GoubayuHeal.Dispel_BuildPrio()visited=visited+1 end
 setmetatable(DispelPrio,{__call=function()visited=visited+1;return nil end})
 ''');l.execute(function(read('GoubayuHeal/GoubayuHeal_Dispel.lua'),'function GoubayuHeal.Dispel_Freedom('))
  l.execute('''
 GoubayuHeal.Dispel_Freedom();assert(visited==1)
 GoubayuHeal.Config.dispel_freedom_filters=1;GoubayuHeal.Dispel_Freedom();assert(visited==1)
 GoubayuHeal.Config.dispel_enabled=1;GoubayuHeal.Dispel_Freedom();assert(visited==1)
 GoubayuHeal.Config.dispel_filters.Snare=1;GoubayuHeal.Dispel_Freedom();assert(visited==2)
 ''')
 def test_statcompare_event_policy_and_adaptive_default(self):
  l=LuaRuntime();l.execute('''
 renders=0;function UnitExists()return true end;function UnitName()return 'Self'end
 portrait={Show=function()end,GetTexture=function()return 'texture'end};function getglobal()return portrait end
 function SetPortraitTexture()renders=renders+1 end
 function CreateFrame()return {SetScript=function(self,k,f)self[k]=f end}end
 frame={GetName=function()return 'Self'end,IsShown=function()return true end}
 ''');l.execute(function(read('StatCompare/StatCompare.lua'),'function StatCompare_RefreshPortrait('));l.execute('''
 StatCompare_RefreshPortrait(frame,'player');assert(frame.portraitUpdateFrame.OnUpdate and renders==1)
 StatCompare_RefreshPortrait(frame,'player');assert(renders==1)
 frame.scPortraitDirty=true;StatCompare_PortraitMode='events';StatCompare_RefreshPortrait(frame,'player');assert(renders==2 and not frame.portraitUpdateFrame.OnUpdate)
 frame.scPortraitDirty=true;StatCompare_PortraitMode='adaptive';StatCompare_RefreshPortrait(frame,'player');assert(frame.portraitUpdateFrame.OnUpdate)
 ''')
  l.execute("DEFAULT_CHAT_FRAME={AddMessage=function()end};StatCompareSelfFrame=frame;StatCompareTargetFrame=nil")
  l.execute(function(read('StatCompare/StatCompare.lua'),'function STATCOMPARE_SlashCmdHandler('))
  l.execute("STATCOMPARE_SlashCmdHandler('portrait events');assert(not frame.portraitUpdateFrame.OnUpdate);STATCOMPARE_SlashCmdHandler('portrait adaptive');assert(frame.portraitUpdateFrame.OnUpdate)")
if __name__=='__main__':unittest.main(argv=[sys.argv[0]]+left,verbosity=2)
