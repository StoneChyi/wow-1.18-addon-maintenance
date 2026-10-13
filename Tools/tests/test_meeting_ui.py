"""Full Meeting UI construction, category scope, font failures and interaction regression.

Executes production files against a strict 1.12-style mock. Not an in-game acceptance test.
"""
from pathlib import Path
import sys
import json

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
ADDON=ROOT/'Interface/AddOns/Meeting'

MOCK=r'''
objects={}; timers={}; sent={}; whispers={}; clock=100
UISpecialFrames={}; SlashCmdList={}; STANDARD_TEXT_FONT='missing.ttf'
MARKED_AFK_MESSAGE='%s'; DEFAULT_AFK_MESSAGE='AFK'; LEVEL='等级'; BOOKTYPE_SPELL='spell'
RAID_CLASS_COLORS={WARRIOR={r=.78,g=.61,b=.43}}; DEFAULT_CHAT_FRAME={AddMessage=function() end}
function UnitClass() return '战士','WARRIOR' end
function UnitName(unit) return unit=='player' and 'Self' or nil end
function UnitLevel() return 60 end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return 0 end
function IsPartyLeader() return 0 end
function IsRaidLeader() return 0 end
function time() return clock end
function GetTime() return clock end
function GetCursorPosition() return 0,0 end
function GetSpellName() return nil end
function GetChannelName() return 1,'世界' end
function SendChatMessage(...) table.insert(sent,{...}) end
function SendWho() error('unexpected network lookup') end
function ChatFrame_OpenChat(message) table.insert(whispers,message) end
function GetDifficultyColor() return {r=1,g=1,b=1} end
function PlaySoundFile() end
function getglobal(name) return _G[name] end
function setglobal(name,value) _G[name]=value end
tinsert=table.insert; floor=math.floor; format=string.format
bit={lshift=function(a,b) return a*2^b end,bor=function(...) local n=0;for _,v in ipairs({...})do n=n+v end;return n end,
    band=function(a,b) local n,p=0,1;while a>0 and b>0 do if a%2==1 and b%2==1 then n=n+p end;a=math.floor(a/2);b=math.floor(b/2);p=p*2 end;return n end}
local methods={};methods.__index=methods
function CreateFrame(kind,name,parent,template)
    local w=setmetatable({kind=kind,name=name,parent=parent,template=template,shown=true,enabled=true,scripts={},points={}},methods)
    table.insert(objects,w)
    if name then assert(not _G[name] or name=='Meeting'); if name~='Meeting' then _G[name]=w end end
    return w
end
UIParent=CreateFrame('Frame','UIParent');UIParent.width=1200;UIParent.height=800
local installFontContract=...
installFontContract(methods,CreateFrame)
failedFontPaths['missing.ttf']=true
local fontObject=methods.SetFontObject
function methods:SetFontObject(value) return fontObject(self,value=='ChatFontNormal' and 'GameFontNormal' or value) end
function methods:GetText() return self.text or '' end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetEffectiveScale() return 1 end
function methods:SetPoint(point,relative,relativePoint,x,y)
    if type(relative)=='number' then x,y,relative,relativePoint=relative,relativePoint,self.parent,point end
    assert(type(point)=='string')
    assert(relative==nil or type(relative)=='table')
    assert(relativePoint==nil or type(relativePoint)=='string')
    table.insert(self.points,{point,relative,relativePoint,x or 0,y or 0})
end
function methods:ClearAllPoints() self.points={} end
function methods:SetAllPoints(parent) self.allPoints=parent or self.parent end
function methods:SetScript(name,fn) assert(type(fn)=='function' or fn==nil);self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
function methods:Fire(name,...)
    local prevThis,prevArg=this,arg1;this=self;arg1=select(1,...)
    if self.scripts[name] then self.scripts[name](...) end
    this=prevThis;arg1=prevArg
end
function methods:Show() local changed=not self.shown;self.shown=true;if changed then self:Fire('OnShow') end end
function methods:Hide() local changed=self.shown;self.shown=false;if changed then self:Fire('OnHide') end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:IsEnabled() return self.enabled and 1 or nil end
cursorReads=0
function GetCursorPosition() cursorReads=cursorReads+1;return 500,500 end
function methods:GetTop() return 700 end
function methods:GetBottom() return 100 end
function methods:GetLeft() return 100 end
function methods:GetRight() return 900 end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetFocus() self:Fire('OnEditFocusGained') end
function methods:ClearFocus() self:Fire('OnEditFocusLost') end
function methods:CreateTexture(name) return CreateFrame('Texture',name,self) end
function methods:GetRegions() return end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
for name,field in pairs({SetWidth='width',SetHeight='height',SetBackdrop='backdrop',SetFrameStrata='strata',SetFrameLevel='level',
    SetMaxBytes='maxBytes',SetAutoFocus='autoFocus',SetMultiLine='multiLine',SetMovable='movable',SetAlpha='alpha',SetValue='value'}) do
    methods[name]=function(self,value) self[field]=value end
end
for _,name in ipairs({'SetBackdropColor','SetBackdropBorderColor','SetTextColor','SetTexture','SetTexCoord','SetVertexColor',
    'SetJustifyH','SetJustifyV','SetNormalTexture','SetPushedTexture','SetHighlightTexture','SetDisabledTexture',
    'RegisterForDrag','EnableMouse','EnableMouseWheel','HighlightText','SetOwner','AddLine'}) do
    methods[name]=function(self,...) self[name..'Args']={...} end
end
function FauxScrollFrame_Update(frame,num,display,step)
    frame.total=num;frame.display=display;frame.step=step;frame.offset=frame.offset or 0
    if num<=display then frame.offset=0 end
end
function FauxScrollFrame_GetOffset(frame) return frame.offset or 0 end
function FauxScrollFrame_SetOffset(frame,offset) frame.offset=offset end
function FauxScrollFrame_OnVerticalScroll(step,update) this.offset=math.floor(arg1/step+.5);update() end
GameTooltip=CreateFrame('Tooltip')
menu={registrations={}}
function menu:Register(frame,...)
    local t={...};self.registrations[frame]=t
end
function menu:FeedAceOptionsTable(options) self.options=options end
function menu:Open(frame)
    self.open=frame;local t=self.registrations[frame]
    for i=1,#t,2 do if t[i]=='children' then t[i+1]() end end
end
function menu:Close()
    local t=self.open and self.registrations[self.open]
    if t then for i=1,#t,2 do if t[i]=='onClose' then t[i+1]() end end end
    self.open=nil
end
function AceLibrary(name) assert(name=='Dewdrop-2.0');return menu end
C_Timer={}
local function timer(interval,fn,count)
    local t={interval=interval,fn=fn,count=count};function t:Cancel() self.cancelled=true end;table.insert(timers,t);return t
end
function C_Timer.NewTicker(...) return timer(...) end
function C_Timer.NewTimer(...) return timer(...) end
function C_Timer.After(...) return timer(...) end
function findText(value)
    for _,w in ipairs(objects) do if w.text==value then return w end end
    error('missing label: '..value)
end
function clickText(value)
    local label=findText(value);local b=label.kind=='FontString' and label.parent or label
    assert(b:IsEnabled()==1); b:Fire('OnClick','LeftButton');return b
end
'''

def world(failed_all_fonts=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    contract=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text('utf-8-sig'))
    lua.execute(MOCK,contract)
    if failed_all_fonts:
        lua.execute("failedFontPaths['Fonts\\\\FRIZQT__.TTF']=true")
    for name in ['Util.lua','Init.lua','RaidChat.lua','GUI.lua','Message.lua','Meeting.lua','Float.lua','Creator.lua','Browser.lua']:
        lua.execute((ADDON/name).read_text('utf-8-sig'))
    return lua

lua=world(); groups=0
def check(code):
    global groups
    lua.execute(code);groups+=1

check('''
    local n=0
    for _,cat in ipairs(Meeting.Categories) do if not cat.hide then n=n+1;assert(cat.key=='RAID' or cat.key=='BOSS') end end
    assert(n==2 and #timers==1, 'only the existing expiry ticker remains at startup')
    assert(Meeting.MainFrame.height==458 and Meeting.MainFrame.SetBackdropColorArgs[4]==.96)
    for _,w in ipairs(objects) do
        if w.kind=='FontString' then assert(w.font,'font must exist even when STANDARD_TEXT_FONT failed') end
    end
    local b=Meeting.GUI.CreateButton({text='failed-font button',width=120,height=24})
    assert(b.label.font and b:GetText()=='failed-font button')
    b:Disable(); assert(b.label.SetTextColorArgs[1]==.5)
    b:Enable(); assert(b.label.SetTextColorArgs[1]==.94)
    assert(not b:SetFont('missing.ttf',14));b:SetText('retained fallback')
''')

check('''
    local watcher
    for _,w in ipairs(objects) do if w.name=='Meeting' then watcher=w end end
    assert(watcher and not watcher:GetScript('OnUpdate'))
    Meeting.MainFrame:Show();assert(watcher:GetScript('OnUpdate'))
    watcher:Fire('OnUpdate',.01)
    local reads=cursorReads
    for i=1,9 do watcher:Fire('OnUpdate',.01) end
    assert(cursorReads==reads, 'hover geometry must be throttled')
    watcher:Fire('OnUpdate',.02);assert(cursorReads==reads+1)
    Meeting.MainFrame:Hide();assert(not watcher:GetScript('OnUpdate') and not Meeting.isHover)
''')

failed_world=world(failed_all_fonts=True)
failed_world.execute('''
    for _,w in ipairs(objects) do if w.kind=='FontString' then assert(w.font and w.text~=nil) end end
    local b=Meeting.GUI.CreateButton({text='both fonts failed',width=160,height=24})
    assert(b.label.font and b:GetText()=='both fonts failed')
''')
groups+=1

check('''
    Meeting.MainFrame:Show();Meeting.BrowserFrame:Show()
    MeetingBworserSelectButton:Fire('OnClick','LeftButton')
    local args=menu.options.args
    assert(args.RAID and args.BOSS and args.ALL and args.DONE)
    assert(not args.DUNGENO and not args.QUEST and not args.PVP and not args.OTHER)
    Meeting.searchInfo.text='保留搜索词'
    args.RAID.args.ALL.set();assert(Meeting.searchInfo.codes.RAID and Meeting.searchInfo.text=='保留搜索词')
    assert(MeetingBworserSelectButton:GetText()=='全部团本')
    args.RAID.args.MC.set(false)
    assert(not Meeting.searchInfo.codes.RAID and not Meeting.searchInfo.codes.MC and Meeting.searchInfo.codes.BWL)
    args.ALL.set();assert(not next(Meeting.searchInfo.codes) and Meeting.searchInfo.text=='保留搜索词')
    Meeting.searchInfo.text=''
    MeetingCreatorSelectButton:Fire('OnClick','LeftButton')
    assert(menu.options.args.RAID and menu.options.args.BOSS and not menu.options.args.QUEST)
''')

check('''
    Meeting.CheckLFTChannel=function() end
    Meeting.CheckPlayerHCMode=function() end
    local before=#sent
    MEETING_DB.activity={code='RaidQuest',comment='旧任务',lastTime=clock}
    for _,w in ipairs(objects) do
        if w.events and w.events.PLAYER_ENTERING_WORLD then
            event='PLAYER_ENTERING_WORLD';w:Fire('OnEvent')
        end
    end
    assert(not MEETING_DB.activity and not Meeting.createInfo.code)
    assert(#sent==before+1, 'only the original version announcement is sent; old task is not restored')
    for _,t in ipairs(timers) do assert(t.interval~=1, 'no fake sixty-second sync animation') end
''')

check('''
    Meeting:OnCreate('Quest','RaidQuest','团队任务','60','1','1','0')
    Meeting:OnCreate('Dungeon','SCH','通灵','60','1','1','0')
    assert(not Meeting:FindActivity('Quest') and not Meeting:FindActivity('Dungeon'))
    local before=#sent
    Meeting.Message.CreateActivity('RaidQuest','任务')
    assert(#sent==before, 'retired categories cannot be published')
    Meeting.Message.OnRecvFormChat('world','Chat','艾萨拉风景真好')
    Meeting.Message.OnRecvFormChat('world','Quest','任务来人')
    assert(not Meeting:FindActivity('Chat') and not Meeting:FindActivity('Quest'))
    Meeting.Message.OnRecvFormChat('world','Raid','BWL来奶')
    Meeting.Message.OnRecvFormChat('world','Boss','蓝龙来输出')
    Meeting.Message.OnRecvFormChat('world','Green','绿龙开组')
    assert(Meeting:FindActivity('Raid').raidChat.codes.BWL)
    assert(Meeting:FindActivity('Boss').raidChat.codes.Azuregos)
    assert(Meeting:FindActivity('Green').raidChat.codes['?GREEN'])
    Meeting.searchInfo.codes={BOSS=true};Meeting.BrowserFrame:UpdateList(true)
    assert(MeetingActivityListFrame.total==2)
    Meeting.searchInfo.codes={RAID=true};Meeting.BrowserFrame:UpdateList(true)
    assert(MeetingActivityListFrame.total==1)
    Meeting.searchInfo.codes={};Meeting.BrowserFrame:UpdateList(true)
    assert(MeetingActivityListFrame.total==3)
    local row=MeetingActivityListFrame.pool[1]
    row.requestButton:Fire('OnClick','LeftButton')
    assert(whispers[#whispers]=='/w Green')
    row:Fire('OnDoubleClick');assert(whispers[#whispers]=='/w Green')
''')

check('''
    local frame=MeetingActivityListFrame
    assert(frame.step==28 and frame.display==10 and #frame.pool==10)
    local row=frame.pool[1]
    assert(row.nameFrame.width+row.hcFrame.width+row.membersFrame.width+row.leaderFrame.width+row.commentFrame.width+62==746)
    assert(row.requestButton.width==54 and row.requestButton.height==22)
    assert(row.commentFrame.height==20 and row.nameFrame.height==20)
    assert(row.SetBackdropColorArgs[4]==1)
    row:Fire('OnEnter');assert(row.SetBackdropColorArgs[1]==.15)
    row:Fire('OnLeave');assert(row.SetBackdropColorArgs[1]==row.baseColor.r)
    local objectsBefore=#objects
    for i=1,100 do Meeting.BrowserFrame:UpdateList(true) end
    assert(#objects==objectsBefore, 'refresh reuses the existing rows and text')
    frame.offset=90;Meeting.BrowserFrame:UpdateList(true)
    assert(frame.offset==0 and frame.pool[1]:IsShown(), 'filter result shrink must not leave a blank page')
    for i=1,13 do Meeting.Message.OnRecvFormChat('world','Scroll'..i,'MC开组') end
    local bar=CreateFrame('Slider','MeetingActivityListFrameScrollBar',frame)
    frame.offset=90;Meeting.BrowserFrame:UpdateList(true)
    assert(frame.offset==6 and bar.value==168, 'offset and thumb are clamped when result still exceeds one page')
    for i=1,13 do Meeting:OnClose('Scroll'..i) end
    Meeting.searchInfo.text='不存在的名字';Meeting.BrowserFrame:UpdateList(true)
    assert(frame.total==0 and findText('暂无符合条件的招募\\n可切换活动筛选，或清空搜索'):IsShown())
    Meeting.searchInfo.text='';Meeting.BrowserFrame:UpdateList(true)
''')

check('''
    local input
    for _,w in ipairs(objects) do if w.kind=='EditBox' and w.maxBytes==50 then input=w end end
    input:SetFocus();input:SetText('bwl');input:Fire('OnTextChanged')
    local timer=Meeting.searchInfo.timer
    Meeting.BrowserFrame:UpdateList(true);assert(input:GetText()=='bwl' and input:HasFocus())
    input:Fire('OnEnterPressed');assert(Meeting.searchInfo.text=='bwl' and not input:HasFocus() and timer.cancelled)
    clickText('清空');assert(Meeting.searchInfo.text=='' and input:GetText()=='')
''')

bosses=lua.eval('Meeting.RaidChat.bossCatalog')
for definition in bosses.values():
    for alias in definition['aliases'].values():
        result=lua.eval('Meeting.RaidChat.Parse')(alias+' 来2奶')
        assert result and result['status']=='recruit' and set(result['codes'].keys())=={definition['code']},alias
        groups+=1
for message in ['蓝龙鳞片来老板','绿龙宝宝出售','艾萨拉来人做任务','世界BOSS在哪里','蓝龙昨天开组','绿龙还缺奶吗']:
    result=lua.eval('Meeting.RaidChat.Parse')(message)
    assert not result or result['status']=='ignore',message
    groups+=1

for path in ADDON.glob('*.lua'):
    lua.eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')(path.read_text('utf-8-sig'),str(path))
print(f'PASS: {groups} full Meeting UI/scope checks; failed-font construction, actual browse/create menus, filtering, reuse, search and boss aliases; game unverified')

if '--snapshot' in sys.argv:
    # Geometry/style capture for a separate visual QA renderer, not a game screenshot.
    lua.execute("Meeting.searchInfo.codes={};Meeting.searchInfo.text='';Meeting.BrowserFrame:UpdateList(true)")
    out=[]
    for index,w in lua.globals().objects.items():
        points=[]
        for _,point in w['points'].items():
            relative=point[2]
            relative_id=next((i for i,obj in lua.globals().objects.items() if lua.eval('rawequal')(obj,relative)),None) if relative else None
            points.append([point[1],relative_id,point[3],point[4],point[5]])
        parent=w['parent']
        parent_id=next((i for i,obj in lua.globals().objects.items() if lua.eval('rawequal')(obj,parent)),None) if parent else None
        def array(field): return list(w[field].values()) if w[field] else None
        out.append(dict(id=index,kind=w['kind'],name=w['name'],parent=parent_id,shown=w['shown'],width=w['width'],height=w['height'],
            text=w['text'],font=array('font'),points=points,bg=array('SetBackdropColorArgs'),color=array('SetTextColorArgs'),
            justify=array('SetJustifyHArgs')))
    target=ROOT/'PluginHistory/staging/meeting-ui-snapshot.json'
    target.write_text(json.dumps(out,ensure_ascii=False),encoding='utf-8')
    print('Mock layout snapshot:',target)
