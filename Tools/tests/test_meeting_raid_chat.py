"""Raid recruitment rules, actual Meeting message/lifecycle/filter integration (Lua 5.1).

No game acceptance claim. The new parser uses the Lua 5.0 API subset and no client API.
Existing row labels are exercised with the shared strict FontString contract.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/Meeting'
groups = 0

MOCK = r'''
clock = 100; browserUpdates = 0; floatUpdates = 0; creatorUpdates = 0; sends = 0
function time() return clock end
function GetTime() return clock end
function UnitClass() return '战士', 'WARRIOR' end
function UnitName() return 'Self' end
RAID_CLASS_COLORS = { WARRIOR = {r=1,g=1,b=1} }
bit={lshift=function(a,b) return a*2^b end, bor=function(...) local n=0; for _,v in ipairs({...}) do n=n+v end; return n end}
MARKED_AFK_MESSAGE = '%s'; DEFAULT_AFK_MESSAGE = 'AFK'; SlashCmdList = {}
function SendChatMessage() sends=sends+1 end
function SendAddonMessage() sends=sends+1 end
function SendWho() error('recognition must not request /who') end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return 0 end
function IsPartyLeader() return 0 end
frames={}
local methods = {}
methods.__index = methods
function methods:RegisterEvent(name) self.events=self.events or {}; self.events[name]=true end
function methods:SetScript(name, fn) self.scripts=self.scripts or {}; self.scripts[name]=fn end
function methods:IsShown() return self.shown~=false end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetTextColor() end
function methods:SetJustifyH() end
function methods:HasFocus() return true end
function CreateFrame(kind,name,parent)
    local frame=setmetatable({kind=kind,name=name,parent=parent},methods)
    table.insert(frames,frame); return frame
end
function GetChannelName() return 1,'世界' end
UIParent=CreateFrame('Frame','UIParent')
installFontContract = ...
installFontContract(methods, CreateFrame)
failedFontPaths['missing.ttf']=true
local bad=CreateFrame('FontString')
assert(not bad:SetFont('missing.ttf',12)); assert(not pcall(function() bad:SetText('invalid') end))
bad:SetFontObject('GameFontNormal'); bad:SetText('fallback')
function textWidget() return UIParent:CreateFontString(nil,'OVERLAY','GameFontNormal') end
C_Timer={tickers={}}
function C_Timer.NewTicker(interval,fn,count) table.insert(C_Timer.tickers,{interval=interval,fn=fn}); return {Cancel=function() end} end
function C_Timer.NewTimer() error('unexpected timer') end
function C_Timer.After() error('unexpected deferred work') end
'''

def world(browser=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    font_contract = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute(MOCK, font_contract)
    for name in ('Init.lua', 'RaidChat.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute('''
        Meeting.searchInfo={codes={},code='',category='',text=''}
        Meeting.MainFrame=CreateFrame('Frame')
        Meeting.BrowserFrame={UpdateList=function() browserUpdates=browserUpdates+1 end}
        Meeting.CreatorFrame={UpdateActivity=function() creatorUpdates=creatorUpdates+1 end,
            UpdateList=function() creatorUpdates=creatorUpdates+1 end}
        Meeting.FloatFrame={Update=function() floatUpdates=floatUpdates+1 end}
        Meeting.GUI={Theme={Green={},Red={}},SetBackground=function() end}
        Meeting.GUI.CreateText=function(config) local w=textWidget(); w:SetText(config.text or ''); return w end
        string.escapemarkup=function(s) return s end
    ''')
    browser_source = (ADDON / 'Browser.lua').read_text(encoding='utf-8-sig')
    lua.execute(browser_source[browser_source.index('local matchs = {}'):browser_source.index('-- Filter callbacks')])
    lua.execute((ADDON / 'Message.lua').read_text(encoding='utf-8-sig'))
    meeting = (ADDON / 'Meeting.lua').read_text(encoding='utf-8-sig')
    # Exclude unrelated main-window construction; run actual event/lifecycle/expiry code.
    lua.execute(meeting[:meeting.index('local mainFrame = Meeting.GUI.CreateFrame(')]
                + meeting[meeting.index('function Meeting:FindActivity('):])
    if browser:
        source = (ADDON / 'Browser.lua').read_text(encoding='utf-8-sig')
        start = source.index('local function ReloadCell(')
        end = source.index('function Meeting.BrowserFrame:UpdateActivity(')
        lua.execute('''
            Meeting.BrowserFrame=CreateFrame('Frame')
            local refreshButton={}
            local searchInput=textWidget()
            local resultText=textWidget()
            local emptyText=textWidget()
            local activityListFrame={}
            function activityListFrame:Reload(n,callback)
                rendered={}
                for i=1,n do
                    local f={nameFrame=textWidget(),hcFrame=textWidget(),leaderFrame=textWidget(),
                        membersFrame=textWidget(),commentFrame=textWidget(),statusFrame=textWidget(),requestButton=textWidget()}
                    callback(f,i); table.insert(rendered,f)
                end
            end
        ''' + source[start:end])
    return lua

lua = world()
parse = lua.eval('Meeting.RaidChat.Parse')

def expect(message, codes=(), status=None):
    global groups
    actual = parse(message)
    result = set(actual['codes'].keys()) if actual else set()
    actual_status = actual['status'] if actual else None
    wanted = status if status is not None else ('recruit' if codes else None)
    assert result == set(codes) and (wanted is None or actual_status == wanted), (message, result, actual_status, codes, wanted)
    if not codes and status is None:
        assert actual_status in (None, 'ignore'), (message, actual_status)
    groups += 1

catalog = lua.eval('Meeting.RaidChat.catalog')
assert {d['code'] for d in catalog.values()} == {'MC','ONY','BWL','AQ40','NAXX','ZUG','AQ20','TH','LKH','ES','TOK'}
alias_count = 0
for definition in catalog.values():
    for alias in definition['aliases'].values():
        expect(alias + ' 来2奶', [definition['code']])
        alias_count += 1

for message, codes in [
    ('BWL来2奶1T，装备M', ['BWL']), ('MC许愿团开组，缺治疗', ['MC']),
    ('TAQ 39=1 奶', ['AQ40']), ('MC39=1', ['MC']), ('ZG 19 = 1', ['ZUG']),
    ('卡下9=1奶', ['LKH']), ('BWL缺奶，有没有来的', ['BWL']),
    ('MC+BWL连打 缺治疗', ['MC','BWL']), ('MC/BWL/黑龙 开组', ['MC','BWL','ONY']),
    ('来2奶 MC+BWL', ['MC','BWL']), ('MC，缺2奶', ['MC']),
    ('BWL许愿团，缺治疗', ['BWL']), ('MC太难了，BWL缺奶', ['BWL']),
    ('昨天MC灭了，今天BWL开组', ['BWL']), ('昨天MC灭了今天BWL缺奶', ['BWL']),
    ('BWL开组，昨天MC灭了', ['BWL']),
    ('KLZ许愿团缺奶', ['?KARA']), ('安其拉开组来奶', ['?AQ']),
    ('KLZ40来2奶', ['TOK']), ('卡拉赞上层开组', ['TOK']),
    ('安其拉废墟开组', ['AQ20']), ('AQ40+AQ20 缺奶', ['AQ40','AQ20']),
    ('木喉要塞来治疗', ['TH']), ('翡翠圣殿来2奶', ['ES']),
    ('LF2M healers BWL', ['BWL']), ('LFM Molten Core need tank', ['MC']),
    ("Tower of Karazhan need 2 healers", ['TOK']),
    ('BWL许愿团装备M', ['BWL']), ('NAXX金团 私聊', ['NAXX']),
    ('MC 来 2 个 奶', ['MC']), ('BWL招奶骑', ['BWL']),
    ('|cff00ff00BWL|r开组 |cffa335ee|Hitem:1:0:0:0|h[MC装备]|h|r', ['BWL']),
    ('MC+|cffa335ee|Hitem:1:0:0:0|h[黑翼]|h|r 开组', ['MC']),
    ('MC＋BWL 39＝1', ['MC','BWL']),
    ('MCG团装备M', ['MC']), ('BWLxy团来奶', ['BWL']),
    ('MC不缺奶来输出', ['MC']), ('BWL不缺奶，来输出', ['BWL']),
    ('BWL来2N', ['BWL']), ('BWL来1T', ['BWL']),
    ('NAXX今晚7.20-11点开组来2奶', ['NAXX']),
    ('NAXX今晚活动时间7.20-11点 开组来2奶', ['NAXX']),
    ('公会团NAXX现缺1奶', ['NAXX']),
    ('NAXX固定团活动时间20-23 收人，今晚临时缺1奶', ['NAXX']),
    ('固定团 NAXX每周收人，NAXX39=1来奶', ['NAXX']),
    ('公会招募固定成员NAXX，BWL现缺1奶', ['BWL']),
    ('Guild recruiting NAXX, BWL LF2M healers', ['BWL']),
    ('周二NAXX开组来奶', ['NAXX']),
    ('蓝龙现缺治疗', ['Azuregos']),
]:
    expect(message, codes)

for message in [
    'BWL真难打，昨天又灭了', 'MC这个装备哪里掉？', 'BWL还缺奶吗', 'BWL招人吗',
    '奶骑求组BWL', 'BWL找团', '求带MC', 'MC有人开吗', '有没有团打BWL',
    '出售黑翼掉落装备', '黑翼公会招人', 'MC代打来老板', 'BWL不缺奶',
    'MC不开团', '昨天MC开团打了四小时', 'BWL几点开团', 'MC规则是什么',
    'BWL许愿团', 'MC装备M', 'MC 0=40', 'MC 40=0', 'MC 39=9',
    'testmc来奶', 'mctest来奶', 'naxxtest开组', '卡拉赞墓穴来奶', 'KLZ墓穴来奶',
    '风暴废墟来奶', '风暴要塞开组', '黑龙鳞片来老板', '翡翠梦境来人做任务',
    '木喉声望来人', '木喉要塞声望来人', '木喉隧道开组',
    '|cffa335ee|Hitem:1:0:0:0|h[黑翼之巢]|h|r 来奶',
    '|Hquest:1:60|h[卡拉赞之塔]|h 来人', 'MC 来tshirt', 'BWL LFG healer',
    'BWL tomorrow?', '',
    'MC开团吗', 'BWL开组么', 'MC缺奶不', 'BWL不招人', 'MC不要奶',
    'Is BWL recruiting healers?', 'Any MC need healers?', 'BWL looking for a group',
    'MC满了吗', '昨天MC满了', '如果MC满了', '听说BWL满了',
    '《某团》 NAXX 双许+4团 收人 需要靠谱法师 术士 牧师 萨满 奶骑 活动时间7.20-11点 开荒包含计暗抗 公平公正 私心太重勿扰',
    'NAXX双许+4团 收人，需要靠谱法师，活动时间7.20-11点',
    'NAXX双许+4团 收人。活动时间19:20-23:00',
    'NAXX公会收人，缺治疗，活动时间20-23',
    'NAXX固定团招募法师', 'BWL长期招募治疗', 'MC长期缺奶',
    '卡上固定成员招募 每周活动', 'TAQ每晚活动，需要奶骑',
    'NAXX每周二四活动，来法师', 'NAXX周二周四收人',
    'NAXX週二週四收人 固定團', 'Guild recruiting NAXX healers weekly',
    'NAXX週二週四收人',
    'NAXX招募公会固定成员', '世界BOSS公会收人 每周活动',
    '|cffa335ee|Hitem:1:0:0:0|h[现缺1奶39=1]|h|r NAXX固定团每周收人',
]:
    expect(message)
expect('MC满了', ['MC'], 'closed')
expect('KLZ停止招募', ['?KARA'], 'closed')
assert parse(None) is None and parse('BWL开组' * 2000) is None
groups += 1

lua.execute('''
    local ad='NAXX 双许+4团 收人 需要靠谱法师 术士 牧师 萨满 奶骑 活动时间7.20-11点'
    local result=Meeting.RaidChat.Parse(ad)
    assert(result.status=='ignore' and result.reason=='long_term_recruitment')
    Meeting.Message.OnRecvFormChat('world','LongTermOnly',ad)
    assert(not Meeting:FindActivity('LongTermOnly'))
    Meeting.Message.OnRecvFormChat('world','ActivePug','NAXX现缺1奶')
    local item=Meeting:FindActivity('ActivePug');local updated=item.updated;local redraws=browserUpdates
    clock=clock+10
    Meeting.Message.OnRecvFormChat('world','ActivePug',ad)
    assert(item.comment=='NAXX现缺1奶' and item.updated==updated and browserUpdates==redraws)
    Meeting.Message.OnRecvFormChat('world','ActivePug','NAXX固定团每周收人，临时缺1奶')
    assert(item.comment~='NAXX现缺1奶' and item.updated==clock and item.raidChat.codes.NAXX)
    Meeting:OnClose('ActivePug')
''')
groups += 1

lua.execute('''
    assert(#Meeting.RaidChat.catalog==11)
    local selected={codes={BWL=true},code='',category='',text=''}
    local both=Meeting.RaidChat.Parse('MC+BWL开组')
    assert(Meeting.RaidChat.MatchesSearch(both,selected,'WORLD'))
    selected.codes={AQ20=true, BWL=true}; assert(Meeting.RaidChat.MatchesSearch(both,selected,'WORLD'))
    selected.codes={}; selected.category='RAID'; assert(Meeting.RaidChat.MatchesSearch(both,selected,'WORLD'))
    selected.code='LKH'; assert(not Meeting.RaidChat.MatchesSearch(Meeting.RaidChat.Parse('KLZ开组'),selected,'WORLD'))
    selected.code=''; selected.category='DUNGENO'; assert(not Meeting.RaidChat.MatchesSearch(both,selected,'WORLD'))
    assert(Meeting.RaidChat.Label(both,true)=='MC/BWL')
    assert(Meeting.RaidChat.Label(Meeting.RaidChat.Parse('MC+BWL+黑龙开组'),true)=='MC/ONY等3本')
''')
groups += 1

lua.execute('''
    Meeting.searchInfo={codes={},code='',category=''}
    for _,frame in ipairs(frames) do
        if frame.events and frame.events.CHAT_MSG_CHANNEL then
            event='CHAT_MSG_CHANNEL'; arg1='BWL开组缺奶'; arg2='WorldLeader'; arg4='1. 世界'
            this=frame; frame.scripts.OnEvent()
        end
    end
    assert(Meeting:FindActivity('WorldLeader').raidChat.codes.BWL)
    Meeting.Message.OnRecvFormChat(nil,'Bad','MC开组')
    Meeting.Message.OnRecvFormChat('world','','MC开组')
    Meeting.Message.OnRecvFormChat('world','Bad',nil)
    assert(not Meeting:FindActivity('Bad'))
''')
groups += 1

lua.execute('''
    Meeting.searchInfo={codes={ES=true},code='',category=''}
    Meeting.Message.OnRecvFormChat('world','Boundary','test来奶')
    assert(not Meeting:FindActivity('Boundary'), 'rejected raid abbreviation must not leak through legacy selected keywords')
    local matches=SetMathcKeyWords(true); assert(#matches==0)
    Meeting.searchInfo={codes={},code='MC',category='RAID'}
    matches=SetMathcKeyWords(true); assert(#matches==0)
''')
groups += 1

lua.execute('''
    Meeting.searchInfo.codes={AQ20=true} -- intake must not depend on the visible filter
    local original=Meeting.RaidChat.Parse; parseCalls=0
    Meeting.RaidChat.Parse=function(msg) parseCalls=parseCalls+1; return original(msg) end
    Meeting.Message.OnRecvFormChat('world','Leader','BWL开组缺奶')
    local item=Meeting:FindActivity('Leader')
    assert(item and item.code=='WORLD' and item:IsChat() and item.raidChat.codes.BWL)
    local updates=browserUpdates
    for i=1,1000 do clock=clock+.01; Meeting.Message.OnRecvFormChat('world','Leader','BWL开组缺奶') end
    assert(parseCalls==1 and browserUpdates==updates and item.updated==clock)
    local updated=item.updated
    Meeting.Message.OnRecvFormChat('world','Leader','BWL满了吗')
    Meeting.Message.OnRecvFormChat('world','Leader','昨天BWL满了')
    Meeting.Message.OnRecvFormChat('world','Leader','BWL真难打')
    Meeting.Message.OnRecvFormChat('world','Leader','有人做任务吗')
    assert(item.comment=='BWL开组缺奶' and item.updated==updated)
    Meeting.Message.OnRecvFormChat('world','Leader','BWL满了')
    assert(not Meeting:FindActivity('Leader'))
    assert(sends==0)
''')
groups += 1

lua.execute('''
    Meeting.Message.OnRecvFormChat('world','Combo','MC+BWL开组')
    Meeting.Message.OnRecvFormChat('world','Combo','MC满了')
    local item=Meeting:FindActivity('Combo'); assert(item and item.raidChat.codes.BWL and not item.raidChat.codes.MC)
    Meeting.Message.OnRecvFormChat('world','Combo','MC+BWL开组')
    assert(item.raidChat.codes.MC, 'repeat of old full advert must restore current parsed codes')
    Meeting.Message.OnRecvFormChat('world','Combo','BWL满了')
    assert(item.raidChat.codes.MC and not item.raidChat.codes.BWL)
    Meeting.Message.OnRecvFormChat('world','Combo','MC满了')
    assert(not Meeting:FindActivity('Combo'))
''')
groups += 1

lua.execute('''
    Meeting.Message.OnRecvFormChat('world','Explicit','BWL开组')
    Meeting:OnCreate('Explicit','MC','LFT activity','60','1','20','0')
    local item=Meeting:FindActivity('Explicit'); assert(not item:IsChat() and not item.raidChat)
    Meeting.Message.OnRecvFormChat('world','Explicit','MC满了')
    assert(Meeting:FindActivity('Explicit')==item)
    Meeting.blockWords={'屏蔽'}
    Meeting.Message.OnRecvFormChat('world','Blocked','MC开组 屏蔽')
    assert(not Meeting:FindActivity('Blocked'))
    Meeting.blockWords={}
    Meeting.searchInfo={codes={},code='',category=''}
    Meeting.Message.OnRecvFormChat('world','Dungeon','通灵来奶')
    assert(not Meeting:FindActivity('Dungeon'), 'only raids and world bosses are retained')
    Meeting.Message.OnRecvFormChat('hardcore','Hardcore','MC开组')
    assert(Meeting:FindActivity('Hardcore').isHC and Meeting:FindActivity('Hardcore').code=='HARDCORE')
    local tick=C_Timer.tickers[1]; assert(tick.interval==5)
    clock=clock+61; tick.fn()
    assert(not Meeting:FindActivity('Hardcore'))
    assert(Meeting:FindActivity('Explicit'), 'structured activity retains its own 120s expiry')
    assert(sends==0 and #C_Timer.tickers==1)
''')
groups += 1

ui = world(browser=True)
ui.execute('''
    Meeting.Message.OnRecvFormChat('world','Combo','MC+BWL开组')
    Meeting.Message.OnRecvFormChat('world','Unknown','KLZ开组')
    Meeting.searchInfo={codes={},code='',category='RAID',text=''}
    Meeting.BrowserFrame:UpdateList(); assert(#rendered==2)
    assert(rendered[1].nameFrame.text=='卡拉赞·待确认')
    assert(rendered[2].nameFrame.text=='MC/BWL' and rendered[2].isChat)
    assert(rendered[2].requestButton.text=='密语' and rendered[2].leader=='Combo')
    Meeting.searchInfo.codes={BWL=true,AQ20=true}
    Meeting.BrowserFrame:UpdateList(); assert(#rendered==1 and rendered[1].id=='Combo')
    Meeting.searchInfo.codes={}; Meeting.searchInfo.code='LKH'
    Meeting.BrowserFrame:UpdateList(); assert(#rendered==0)
    Meeting.searchInfo.code=''; Meeting.searchInfo.text='黑翼'
    Meeting.BrowserFrame:UpdateList(); assert(#rendered==1 and rendered[1].id=='Combo')
    Meeting.MainFrame:Hide(); Meeting.searchInfo.text=''; rendered={}
    Meeting.Message.OnRecvFormChat('world','New','NAXX开组')
    assert(#rendered==0 and Meeting:FindActivity('New'))
    Meeting.MainFrame:Show(); Meeting.BrowserFrame:UpdateList(); assert(#rendered==3)
''')
groups += 1

# Compile every Lua file and confirm TOC resolution, BOM, and unchanged newline styles.
compiler = lua.eval('function(s,name) local fn,err=loadstring(s,name); assert(fn,err) end')
for file in ADDON.glob('*.lua'):
    compiler(file.read_text(encoding='utf-8-sig'), str(file))
toc = (ADDON / 'Meeting.toc').read_bytes()
assert toc.startswith(b'\xef\xbb\xbf') and toc.count(b'\n') == toc.count(b'\r\n')
for line in toc.decode('utf-8-sig').splitlines():
    if line.strip() and not line.startswith('#'):
        assert (ADDON / line.replace('\\', '/')).is_file(), line
for name in ('Init.lua','Message.lua','Meeting.lua','Browser.lua'):
    assert b'\r' not in (ADDON / name).read_bytes(), name
groups += 1
print(f'PASS: {groups} Meeting raid checks; {alias_count} aliases across 11 raids; '
      'actual intake/lifecycle/browser integration, strict existing fonts, Lua syntax and TOC; no game verification')
if '--benchmark' in sys.argv:
    elapsed = lua.eval('''function()
        local messages={'MC开组来奶','BWL昨天灭了','普通聊天交易附魔','卡拉赞墓穴来奶'}
        local started=os.clock()
        for i=1,4000 do Meeting.RaidChat.Parse(messages[i%4+1]) end
        return os.clock()-started
    end''')()
    print(f'Synthetic Lua recognition: 4000 messages, {elapsed:.3f} CPU seconds; not in-game profiling')
