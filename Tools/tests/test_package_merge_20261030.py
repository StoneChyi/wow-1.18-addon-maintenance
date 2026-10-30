"""Oct 29 package increments against real Lua functions; never game acceptance.

Use --addons for the isolated candidate. Font writes use the shared strict
1.12 contract, including unsuccessful configured-font loading.
"""
from pathlib import Path
import argparse, sys, unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
argp=argparse.ArgumentParser();argp.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns')
args,remaining=argp.parse_known_args();ADDONS=args.addons

def read(rel):return (ADDONS/rel).read_bytes().decode('utf-8-sig').replace('\r\n','\n').replace('\r','\n')
def function(src,start,indent=''):
    a=src.index(start);return src[a:src.index('\n'+indent+'end',a)+len(indent)+4]

MOCK=r'''
methods={};objects={};clock=100;SlashCmdList={}
function object(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,children={},regions={},scripts={},events={},
 shown=true,width=100,height=20,scale=1,alpha=1,strata='MEDIUM',calls={}}, {__index=methods})
 if name then _G[name]=o end
 if parent then table.insert(parent.children,o) end
 table.insert(objects,o);return o
end
function CreateFrame(kind,name,parent) return object(kind,name,parent) end
function getglobal(name) return _G[name] end
function GetTime() return clock end
function methods:GetName() return self.name end
function methods:GetObjectType() return self.kind end
function methods:GetParent() return self.parent end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:CreateTexture(name,layer) return object('Texture',name,self) end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {'TOPLEFT',self.parent,'TOPLEFT',0,0}) end
function methods:ClearAllPoints() self.point=nil end
function methods:SetWidth(x) self.width=x end
function methods:SetHeight(x) self.height=x end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(x) self.calls.scale=(self.calls.scale or 0)+1;self.scale=x end
function methods:GetScale() return self.scale end
function methods:SetAlpha(x) self.calls.alpha=(self.calls.alpha or 0)+1;self.alpha=x end
function methods:GetAlpha() return self.alpha end
function methods:SetFrameStrata(x) self.calls.strata=(self.calls.strata or 0)+1;self.strata=x end
function methods:GetFrameStrata() return self.strata end
function methods:SetBackdropColor(...) self.calls.bg=(self.calls.bg or 0)+1;self.bg={...} end
function methods:GetBackdropColor() return unpack(self.bg or {0,0,0,1}) end
function methods:SetTextColor(...) self.color={...} end
function methods:GetText() return self.text end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetNormalTexture(x) self.calls.texture=(self.calls.texture or 0)+1;self.normal=self.normal or object('Texture') end
function methods:GetNormalTexture() return self.normal end
for _,k in ipairs({'SetAllPoints','SetFrameLevel','SetBackdrop','SetBackdropBorderColor','SetBlendMode',
 'SetTexture','SetVertexColor','SetJustifyH','SetJustifyV','EnableMouse','SetMovable','SetClampedToScreen',
 'RegisterForDrag','StartMoving','StopMovingOrSizing','SetTexCoord'}) do methods[k]=function() end end
UIParent=object('Frame','UIParent');DEFAULT_CHAT_FRAME=object('Frame');DEFAULT_CHAT_FRAME.lines={}
function DEFAULT_CHAT_FRAME:AddMessage(msg) table.insert(self.lines,msg) end
'''

def runtime(ui=False):
    r=LuaRuntime(unpack_returned_tuples=True)
    if ui:
        r.execute(MOCK)
        install=r.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf8'))
        install(r.globals().methods,r.globals().object)
    return r

class PackageMerge(unittest.TestCase):
    def test_bigwigs_cast_speed_rank_dedup(self):
        r=runtime();r.execute('BigWigs={};auras={};function UnitExists() return true end;function BigWigs:AuraIsPresent(u,id) return auras[id] end')
        r.execute(function(read('BigWigs/Core.lua'),'function BigWigs:GetCastTimeCoefficient('))
        for ids,expected in [([],1),([11719,1714],1.6),([11398,8692,5760],1.6),([11719,1714,11398,8692,5760],2.56)]:
            r.execute('auras={}');
            for i in ids:r.globals().auras[i]=True
            self.assertAlmostEqual(r.eval('BigWigs:GetCastTimeCoefficient("target")'),expected)

    def test_bigwigs_timeline_reset_and_short_tail(self):
        src=read('BigWigs/Plugins/VerticalBars.lua');r=runtime()
        r.execute('clock=100;function GetTime() return clock end')
        block='local timeline={};local DEFAULT_ICON="icon"\n'
        for name in ['SortTimeline','AddTimelineBar','RemoveTimelineBarByKey','RemoveTimelineBarsByModule']:
            block+=function(src,'local function '+name+'(')+'\n'
        block+='return {add=AddTimelineBar,remove=RemoveTimelineBarByKey,drop=RemoveTimelineBarsByModule,list=timeline}'
        r.globals().t=r.execute(block)
        r.execute('''
        t.add('A',2,'icon','a','Boss');t.remove('a',true);assert(#t.list==1)
        t.add('A',20,'icon','a','Boss');assert(#t.list==1 and t.list[1].endTime==120)
        t.remove('a',true);assert(#t.list==0)
        t.add('A',1,'icon','a','Boss');t.drop('Boss');assert(#t.list==0)
        t.add('A',-1);assert(#t.list==0)
        ''')

    def test_bigwigs_same_second_distinct_targets_keep_independent_keys(self):
        r=runtime()
        r.execute('''
        BigWigs={NewModule=function() return {} end};received={}
        function UnitName() return 'Self' end;function GetTime() return 100 end
        function GetNumRaidMembers() return 0 end;function GetNumPartyMembers() return 0 end
        ''')
        r.execute(read('BigWigs/Plugins/Comm.lua'))
        r.execute('''
        function BigWigsComm:TriggerEvent(kind,sync,rest) table.insert(received,{sync,rest}) end
        BigWigsComm:OnRegister()
        BigWigsComm:BigWigs_SendSync('AlchemistsFire30138Alice')
        BigWigsComm:BigWigs_SendSync('AlchemistsFire30138Bob');assert(#received==2)
        BigWigsComm:BigWigs_SendSync('FixedFire Alice')
        BigWigsComm:BigWigs_SendSync('FixedFire Bob');assert(#received==3)
        ''')
        self.assertIn('self:Sync(syncName.fire .. player)',read('BigWigs/Raids/BWL/Alchemists.lua'))
        self.assertNotIn('syncName.defiler_defiling .. " "',read('BigWigs/Raids/TMH/TimbermawTrash.lua'))

    def test_bigwigs_factory_font_failure_and_left_right(self):
        r=runtime(True);src=read('BigWigs/Plugins/VerticalBars.lua')
        r.execute('FONT="bad.ttf";failedFontPaths[FONT]=true;DEFAULT_ICON="icon";OVERLAY_TEX="glow"')
        factory=r.execute(function(src,'local function CreateIconFrame(')+'\nreturn CreateIconFrame')
        r.globals().factory=factory
        r.execute('''
        local owner={frames={anchor=object('Frame')},db={profile={iconSize=32}}}
        for _,side in ipairs({'left','right'}) do
          owner.db.profile.labelSide=side;local f=factory(owner)
          f.cooldown:SetText('2');f.text:SetText('Spell');f:Hide();f.text:SetText('')
          f:Show();f.cooldown:SetText('1');assert(f.cooldown.font and f.text.font)
          assert(f.text.point[1]==(side=='left' and 'RIGHT' or 'LEFT'))
        end
        ''')

    def test_bigwigs_lock_label_font_failure_and_reuse(self):
        r=runtime(True);src=read('BigWigs/Plugins/VerticalBars.lua')
        r.execute('''
        FONT='bad.ttf';WHITE='white';failedFontPaths[FONT]=true
        L=setmetatable({}, {__index=function(s,k) return k end})
        BigWigsVerticalBars={frames={},db={profile={iconSize=32,trackHeight=300,locked=true}}}
        function BigWigsVerticalBars:ApplyLayout() end
        function BigWigsVerticalBars:RestorePosition() end
        function BigWigsVerticalBars:RefreshShownState() end
        ''')
        r.execute(function(src,'function BigWigsVerticalBars:UpdateLockState('))
        r.execute(function(src,'function BigWigsVerticalBars:SetupFrames('))
        r.execute('''
        local b=BigWigsVerticalBars;b:SetupFrames();local f=b.frames.anchor.lockBtn.text
        assert(f.font and f.text=='Locked');b.db.profile.locked=false;b:UpdateLockState()
        assert(f.text=='Draggable');f:Hide();f:SetText('');f:Show();b:UpdateLockState()
        assert(f.text=='Draggable')
        ''')

    def test_cat_channel_guards_and_personal_consumable_threshold(self):
        r=runtime();r.execute('''
        cards={};channel=1;Cat2={GetChanneled=function() return channel end,
          RegisterCard=function(c) cards[c.id]=c end}
        ''')
        count=0
        for p in (ADDONS/'Cat2/Cards').rglob('*.lua'):
            src=p.read_text(encoding='utf-8-sig')
            if '-- 引导期间跳过，避免使用物品或爆发技能打断当前引导。' not in src:continue
            r.execute(src);count+=1
        self.assertGreaterEqual(count,15)
        r.execute('for _,c in pairs(cards) do assert(c.Execute({}, {})==false) end')
        r.execute('''
        channel=0;calls=0;enemies=1;Cat2.UnitXP=true
        function UnitXP(op) if op=='version' then return 1800000000 end end
        function Cat2.GetItemByNameCD() return true end
        function Cat2.ScanNearbyEnemies() return enemies end
        function Cat2.UseItemByName() calls=calls+1;return true end
        context={GetStepOption=function(s,step,key) if key=='itemName' then return 'Bomb' else return 3 end end}
        local c=cards.item_custom_cast_consumable_self;c.RefreshRuntimeData()
        assert(not c.Execute(context,{}) and calls==0)
        enemies=3;assert(c.Execute(context,{}) and calls==1)
        ''')

    def test_cat_new_cards_stance_rip_and_openers(self):
        r=runtime();r.execute('''
        cards={};casts={};stopped=0;Cat2={RegisterCard=function(c) cards[c.id]=c end,
          PlayerInformation={temporary={buff={},targetExists=true,power=40,targetCombo=1}}}
        function Cat2.Cast(s) table.insert(casts,s) end
        function Cat2.StopAttack() stopped=stopped+1 end
        function Cat2.GetRipDot() return rip end
        function Cat2.JumpTo(i) return i end
        function GetNumShapeshiftForms() return 1 end
        function GetShapeshiftFormInfo() return 'icon','Bear',active end
        context={GetStepOption=function(s,step,key) return ({stanceName='Bear',targetIndex=7,energyLimit=50})[key] end}
        ''')
        for p in ['Logic/FlowJumpStance.lua','Druid/FerociousBiteRip1.lua','Druid/StealthPounce.lua','Rogue/StealthAmbush.lua']:
            r.execute(read('Cat2/Cards/'+p))
        r.execute('''
        active=false;assert(not cards.logic_flow_jump_stance.Execute(context,{}))
        active=true;assert(cards.logic_flow_jump_stance.Execute(context,{})==7)
        rip=false;assert(not cards.druid_ferocious_bite_rip_1.Execute(context,{}))
        rip=true;assert(cards.druid_ferocious_bite_rip_1.Execute(context,{}))
        for _,id in ipairs({'druid_stealth_pounce','rogue_stealth_ambush'}) do
          Cat2.PlayerInformation.temporary.buff['潜行']=nil;assert(not cards[id].Execute(context))
          Cat2.PlayerInformation.temporary.buff['潜行']=true;assert(cards[id].Execute(context))
        end
        assert(stopped==2)
        ''')

    def test_auto_db_alias_fallback_and_player_input(self):
        r=runtime(True);src=read('Automatonex/Modules/AutoDB.lua')
        r.execute('Automaton_AutoDB={};SLASH_PFDB1="/db";count=0;historyFlag=true;DEFAULT_CHAT_FRAME.editBox={text="",GetText=function(s) return s.text end,SetText=function(s,t) s.text=t end}')
        for name in ['ResolveSlashHandler','ExecuteSlashCommand']:
            r.execute(function(src,'function Automaton_AutoDB:'+name+'('))
        r.execute('''
        SlashCmdList.PFDB=function(msg) count=count+1;last=msg end
        assert(Automaton_AutoDB:ExecuteSlashCommand('/db track taxi'))
        assert(count==1 and last=='track taxi' and DEFAULT_CHAT_FRAME.editBox.text=='')
        function ChatEdit_SendText(box,addHistory) historyFlag=addHistory;error('dispatch failure') end
        assert(not Automaton_AutoDB:ExecuteSlashCommand('/unknown'))
        assert(historyFlag==false and DEFAULT_CHAT_FRAME.editBox.text=='')
        DEFAULT_CHAT_FRAME.editBox.text='typing';historyFlag=true
        Automaton_AutoDB:ExecuteSlashCommand('/unknown');assert(DEFAULT_CHAT_FRAME.editBox.text=='typing' and historyFlag)
        ''')

    def test_unlock_spellbook_and_mail_armor_exclusion(self):
        r=runtime();src=read('Automatonex/Modules/Unlock.lua')
        r.execute('''
        Automaton={gratuity={NumLines=function() return 1 end,GetLine=function(s,i,right) return right and rightText or leftText end}}
        function GetSpellTabInfo(tab) if tab==1 then return 'Rogue','icon',0,2 end end
        function GetSpellName(i) if i==2 then return spellName end end
        ''')
        r.globals().find=r.execute('local LOCKPICK_NAMES={"开锁","Pick Lock"}\n'+function(src,'local function FindLockpickingSpellSlot(')+'\nreturn FindLockpickingSpellSlot')
        r.globals().locked=r.execute(function(src,'local function IsScannedItemLocked(')+'\nreturn IsScannedItemLocked')
        r.execute('''
        spellName='开锁';assert(find()==2);spellName='Pick Lock';assert(find()==2)
        spellName='Other';assert(find()==nil)
        leftText='锁甲';rightText=nil;assert(not locked())
        leftText='Box';rightText='已锁';assert(locked())
        ''')

    def test_onebag_text_texture_and_appearance_caches(self):
        r=runtime(True);src=read('OneBag/OneBag.lua')
        r.execute('''
        module={};textureCalls=0
        function SetItemButtonTexture() textureCalls=textureCalls+1 end
        OneBagChargesPollFrame=object('Frame');StackSplitFrame=object('Frame')
        ''')
        for name in ['function OneBag_SetSlotTexture(','function OneBag_SetSlotCount(','function module:OnBaseShow(']:
            r.execute(function(src,name))
        r.execute('''
        b=object('Button','Slot');local fs=b:CreateFontString('SlotCount','OVERLAY','GameFontNormalSmall')
        failedFontPaths['bad.ttf']=true;fs:SetFont('bad.ttf',12);fs:SetText('')
        OneBag_SetSlotCount(b,1,5);assert(fs.text=='x5' and fs.color[2]==.82)
        OneBag_SetSlotCount(b,3,nil);assert(fs.text=='3' and fs.color[2]==1)
        OneBag_SetSlotCount(b,1,nil);assert(not fs:IsShown());OneBag_SetSlotCount(b,1,2);assert(fs.text=='x2' and fs:IsShown())
        OneBag_SetSlotTexture(b,'icon');OneBag_SetSlotTexture(b,'icon');assert(textureCalls==1)
        OneBag_SetSlotTexture(b,nil);OneBag_SetSlotTexture(b,'icon');assert(textureCalls==3)
        module.frame=object('Frame');module.stratas={'LOW','MEDIUM','HIGH'}
        module.db={profile={scale=.8,alpha=.7,strata=1,colors={bground={r=.1,g=.2,b=.3,a=.8}}}}
        module:OnBaseShow();local f=module.frame;local calls=f.calls.strata
        module:OnBaseShow();assert(f.calls.strata==calls and f.calls.bg==1)
        f.strata='HIGH';f.alpha=.2;f.bg={0,0,0,0};module:OnBaseShow()
        assert(f.strata=='LOW' and f.alpha==.7 and f.bg[1]==.1)
        ''')

    def test_onebag_lock_timeout_and_red_recovery(self):
        r=runtime();src=read('OneBag/OneBag.lua')
        r.execute('''
        now=0;calls=0;function GetTime() return now end
        function SetItemButtonDesaturated(b,locked) calls=calls+1;b.grey=locked end
        function SetItemButtonTextureVertexColor(b,r,g,blue) b.red=r;b.green=g end
        OneCore={_unusableCache={bad=true}}
        ''')
        r.execute('local _slotLockSeen={};local STALE_LOCK_SECONDS=5;local UNUSABLE_TINT={r=1,g=.15,b=.15}\n'+function(src,'function OneBag_SetSlotShade('))
        r.execute('''
        b={};OneBag_SetSlotShade(b,true);OneBag_SetSlotShade(b,true);assert(calls==1 and b.grey)
        now=6;OneBag_SetSlotShade(b,true,'bad');assert(not b.grey and b.green==.15)
        b._obShadeState=nil;OneBag_SetSlotShade(b,false);assert(calls==3 and not b.grey)
        ''')

    def test_atsw_cache_expiry_options_profession_and_recursion(self):
        r=runtime();src=read('AdvancedTradeSkillWindow2/AdvancedTradeSkillWindow2.lua')
        r.execute('''
        ATSW_PossibleCache={};ATSW_PossibleGeneration=0;ATSW_PossibleTTL=.25
        ATSW_POSSIBLE_BANK=1;ATSW_POSSIBLE_ALTS=2;ATSW_POSSIBLE_MERCHANT=3;ATSW_POSSIBLE_NOTASK=4
        now=100;prof='Alchemy';calls=0;answer=4
        function Profession() return prof end;function GetTime() return now end
        function ATSW_CalcPossible() calls=calls+1;return answer end
        ''')

        r.execute(function(src,'function ATSW_PossibleInvalidate('));r.execute(function(src,'function ATSW_HowManyItemsArePossibleToCreate('))
        r.execute('''
        assert(ATSW_HowManyItemsArePossibleToCreate('Potion')==4);answer=8
        assert(ATSW_HowManyItemsArePossibleToCreate('Potion')==4 and calls==1)
        assert(ATSW_HowManyItemsArePossibleToCreate('Potion',ATSW_POSSIBLE_BANK)==8 and calls==2)
        prof='Other';assert(ATSW_HowManyItemsArePossibleToCreate('Potion')==8 and calls==3)
        ATSW_PossibleInvalidate();assert(ATSW_HowManyItemsArePossibleToCreate('Potion')==8 and calls==4)
        now=100.3;answer=0;assert(ATSW_HowManyItemsArePossibleToCreate('Potion')==0 and calls==5)
        ATSW_HowManyItemsArePossibleToCreate('Potion',{});assert(calls==6)
        ''')

    def test_skin_late_creation_reuse_and_failed_configured_font(self):
        r=runtime(True)
        r.execute('''
        C={global={font_size='13'}};pfUI={font_default='bad.ttf',api={},addonskinner={callbacks={}}}
        failedFontPaths['bad.ttf']=true
        function pfUI.addonskinner:RegisterSkin(name,fn) self.callbacks[name]=fn end
        function pfUI.addonskinner:UnregisterSkin() end
        function pfUI.api.CreateBackdrop(f) f.backdrop=object('Frame',nil,f) end
        function pfUI.api.StripTextures() end
        function pfUI.api.SkinButton() end
        function pfUI.api.SkinCloseButton() end
        function pfUI.api.SkinSlider() end
        function pfUI.api.SkinCheckbox(f) f.backdrop=object('Frame',nil,f) end
        StatCompareSelfFrame=object('Frame');StatCompareTargetFrame=object('Frame')
        StatCompareOptFrame=object('Frame','StatCompareOptFrame')
        SCOptTitle=StatCompareOptFrame:CreateFontString('SCOptTitle','OVERLAY','GameFontNormal')
        SCOptTitle:SetText('Title');StatCompareOptSubFrame1=object('Frame','StatCompareOptSubFrame1',StatCompareOptFrame)
        StatCompareOptSubFrame2=object('Frame','StatCompareOptSubFrame2',StatCompareOptFrame)
        checkbox=object('CheckButton','StatCompareTestCheck',StatCompareOptSubFrame1)
        SlashCmdList.DIMINFO=function()
          DimInfoOptions=object('Frame','DimInfoOptions')
          local titlebar=object('Frame',nil,DimInfoOptions);titlebar:SetHeight(30)
          local title=titlebar:CreateFontString(nil,'OVERLAY','GameFontNormal');title:SetText('Settings')
          table.insert(titlebar.regions,title)
          DimInfoOptionsContent=object('Frame','DimInfoOptionsContent',DimInfoOptions)
          local row=object('Frame',nil,DimInfoOptionsContent)
          local cb=object('CheckButton','DimInfoTestCheckbox',row)
          local close=object('Button',nil,DimInfoOptions)
          local label=object('Button',nil,DimInfoOptions);label.text='Apply';label:SetHeight(20)
        end
        ''')
        r.execute(read('pfUI-addonskinner/skins/StatCompare.lua'))
        r.execute(read('pfUI-addonskinner/skins/diminfo.lua'))
        r.execute('''
        pfUI.addonskinner.callbacks.StatCompare();pfUI.addonskinner.callbacks.StatCompare()
        assert(checkbox.pfStatCompareCheck and SCOptTitle.font)
        pfUI.addonskinner.callbacks.diminfo();assert(not PF_DIMINFO_SKIN_OK)
        SlashCmdList.DIMINFO('');assert(PF_DIMINFO_SKIN_OK and PF_DIMINFO_SKIN_ERR==nil)
        local f=DimInfoOptions;local hook=f.scripts.OnShow;hook();hook()
        for _,o in ipairs(objects) do if o.kind=='FontString' then o:SetText('');o:Hide();o:SetText('hidden');o:Show();o:SetText('reuse') end end
        assert(f.pfDiminfo)
        ''')

    def test_brainwasher_exact_match_and_delayed_diagnostic(self):
        r=runtime(True);src=read('BrainwasherPro/BrainwasherPro.lua')
        r.execute('''
        BrainwasherPro={};BrainwasherProDB={specs={[1]={name='A',t1=1,t2=0,t3=0},[2]={name='B',t1=1,t2=0,t3=0}}}
        points=0;score=1
        function GetTalentCounts() return points,0,0 end
        function FetchCurrentTalents() return {} end
        function ComputeSpecMatchScore(spec) return score end
        ''')
        r.globals().find=r.execute('''
        local gossipSlots={load={}};local lastNoMatchDiagKey
        local noMatchPendingKey,noMatchPendingSince=nil,0
        local expectedSpecSlot,expectedSpecUntil
        '''+function(src,'local function FindCurrentSpecName()')+'\nreturn FindCurrentSpecName')
        r.execute('''
        assert(find()==nil and #DEFAULT_CHAT_FRAME.lines==0)
        clock=101;assert(find()==nil and #DEFAULT_CHAT_FRAME.lines==0)
        clock=101.6;assert(find()==nil and #DEFAULT_CHAT_FRAME.lines==1)
        points=1;assert(find()==nil) -- two exact records: no guessed slot
        BrainwasherPro.activeSpecSlot=2;local name,slot=find();assert(name=='B' and slot==2)
        score=.9;assert(find()==nil) -- partial match must never switch
        ''')

    def test_pfui_unsupported_script_and_callback_chain(self):
        r=runtime();r.execute(function(read('pfUI/api/api.lua'),'function HookScript('))
        r.execute('''
        f={GetScript=function() error('unsupported slot') end};assert(not HookScript(f,'OnTooltipSetItem',function() end))
        count=0;f={GetScript=function() return function(a) count=count+a end end,
          SetScript=function(s,k,fn) s.fn=fn end}
        assert(HookScript(f,'OnShow',function(a) count=count+a*2 end));f.fn(3);assert(count==9)
        f.SetScript=function() error('unsupported write') end;assert(not HookScript(f,'bad',function() end))
        ''')

    def test_pizza_only_calibration_lines_and_filter_expiry(self):
        r=runtime(True);src=read('PizzaWorldBuffs/src/main.lua')
        r.execute('PWB_config={hideServerTime=true};PWB={serverTimeFilterUntil=120}')
        hook=r.execute(function(src,'local function hookServerTimeFilter(')+'\nreturn hookServerTimeFilter')
        hook(r.globals().DEFAULT_CHAT_FRAME);first=r.globals().DEFAULT_CHAT_FRAME.AddMessage
        hook(r.globals().DEFAULT_CHAT_FRAME)
        r.execute('''
        DEFAULT_CHAT_FRAME:AddMessage('Server Time: 30.10.2026 12:00:00')
        DEFAULT_CHAT_FRAME:AddMessage('|cffffffffServer Uptime: 5 days|r');assert(#DEFAULT_CHAT_FRAME.lines==0)
        DEFAULT_CHAT_FRAME:AddMessage('[Guild] User: Server Time: copied text');assert(#DEFAULT_CHAT_FRAME.lines==1)
        PWB_config.hideServerTime=false;DEFAULT_CHAT_FRAME:AddMessage('Server Time: visible');assert(#DEFAULT_CHAT_FRAME.lines==2)
        PWB_config.hideServerTime=true;clock=121;DEFAULT_CHAT_FRAME:AddMessage('Server Time: expired');assert(#DEFAULT_CHAT_FRAME.lines==3)
        ''')

    def test_dispel_class_color_persisted_and_fallback(self):
        r=runtime();src=read('GoubayuHeal/GoubayuHeal_Dispel.lua')
        r.execute('RAID_CLASS_COLORS={PRIEST={r=1,g=1,b=1},WARRIOR={r=.5,g=.4,b=.3}};function UnitExists(u) return u=="party1" end;function UnitClass() return "Warrior","WARRIOR" end')
        fn=r.execute(function(src,'local function Dispel_UnitClassColor(')+'\nreturn Dispel_UnitClassColor')
        self.assertEqual(fn(r.table(classFile='PRIEST',unit='invalid')),(1,1,1))
        self.assertEqual(fn(r.table(unit='party1')),(.5,.4,.3))
        self.assertEqual(fn(r.table(unit='invalid')),(.9,.9,.9))

    def test_shagu_chat_sanitize_preserves_colors_and_links(self):
        r=runtime();fn=r.execute(function(read('ShaguDPS/window.lua'),'        local function sanitizeChatEscapes(', '        ')+'\nreturn sanitizeChatEscapes')
        for value,expected in [('A|B','A||B'),('bad|q','bad||q'),('|cff00ff00OK|r','|cff00ff00OK|r'),('|Hitem:1|h[X]|h','|Hitem:1|h[X]|h'),('tail|','tail||')]:
            self.assertEqual(fn(value),expected)
        self.assertNotIn('settleTrioOnDeath',read('ShaguDPS/parser.lua'))
        self.assertIn('if not next(bossGUIDsThisFight)',read('ShaguDPS/parser.lua'))

    def test_shagu_absorb_display_migration_preserves_old_choices(self):
        src=read('ShaguDPS/settings.lua')
        a=src.index('    -- 根据 perCharConfig 选择配置来源')
        b=src.index('    -- 迁移旧版配置：为新增统计项补充默认启用状态',a)
        for old,choice,expected in [(0,None,0),(1,None,1),(1,0,0),(0,1,1)]:
            for scope in ['account','character']:
                r=runtime();r.execute('config={exclude_absorb=1,show_absorb=0}')
                source=r.table(exclude_absorb=old,perCharConfig=0 if scope=='account' else 1)
                if choice is not None:source.show_absorb=choice
                r.globals()['ShaguDPS_Config_Account' if scope=='account' else 'ShaguDPS_Config']=source
                r.execute(src[a:b]);self.assertEqual(r.globals().config.show_absorb,expected)

    def test_wushuang_minimap_restore_drag_and_unlaid_out(self):
        r=runtime(True);src=read('WushuangLoot/WushuangLoot.lua')
        a=src.index('local function UpdateMinimapButtonPosition()');b=src.index('WSLootMinimapButton:SetScript("OnClick"',a)
        r.execute('Minimap={GetCenter=function() return mx,my end};WSLootMinimapButton=object("Button");WushuangLootDB={mmAngle=90}')
        r.execute('local mmAngle=0\n'+src[a:b])
        r.execute('''
        local memory;for _,f in ipairs(objects) do if f.events.VARIABLES_LOADED then memory=f end end
        mx=0;my=0;memory.scripts.OnEvent();assert(WSLootMinimapButton.point==nil)
        mx=100;my=100;memory.scripts.OnEvent();assert(math.abs(WSLootMinimapButton.point[4]-100)<.001)
        assert(math.abs(WSLootMinimapButton.point[5]-180)<.001)
        WSLootMinimapButton.scripts.OnDragStop();assert(WushuangLootDB.mmAngle==90)
        ''')
        self.assertNotIn('SkinTick',src)
        self.assertIn('Version: 1.6',read('WushuangLoot/WushuangLoot.toc'))

if __name__=='__main__':unittest.main(argv=[sys.argv[0]]+remaining,verbosity=2)
