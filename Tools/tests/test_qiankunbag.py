"""Production core/model/view contracts. Native renderer and game actions need client acceptance."""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/QianKunBag'


def runtime(prefix=''):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'Tools/tests/qiankunbag_wow112_mock.lua').read_text(encoding='utf-8'))
    installer = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    installer(lua.globals().methods, lua.globals().newObject)
    lua.execute('installFrames()')
    if prefix:
        lua.execute(prefix)
    for name in ('Core.lua', 'Categories.lua', 'Model.lua', 'View.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8'))
    lua.execute('Q=QianKunBag')
    return lua


CASES = [
    ('lazy isolated login', "Q:OnEvent('ADDON_LOADED','QianKunBag'); assert(Q.ready and not Q.window and count('info')==0 and not Q.events:GetScript('OnUpdate')); assert(OpenBackpack==originalOpen and ToggleBackpack==originalToggle and OpenAllBags==originalAll and BagshuiData.untouched and Bagshui.sentinel)"),
    ('open before login cache', "open(); assert(Q:IsOpen() and Q.total==6 and Q.filled==4 and Q.stats.layouts==1 and Q.stats.created==6 and Q.pending==0)"),
    ('default classifications', "open(); assert(Q.slots['0:1'].category=='consume' and Q.slots['0:2'].category=='equipment' and Q.slots['1:1'].category=='materials' and Q.slots['0:3'].category=='empty')"),
    ('warm reopen reuses state and geometry', "open(); local r=Q.slots['0:1']; local n=Q.stats.painted; local p=count('point'); local c=Q.stats.classified; Q:Toggle(); open(); assert(Q.slots['0:1']==r and Q.stats.painted==n and Q.stats.classified==c and Q.stats.layouts==1 and Q.stats.created==6 and count('point')==p)"),
    ('idle sleeps without reads', "open(); tick(); assert(not Q.events:GetScript('OnUpdate')); local n=count('info'); for i=1,100 do if Q.events:GetScript('OnUpdate') then script(Q.events,'OnUpdate',0.016) end end; assert(count('info')==n)"),
    ('bag events coalesce', "open(); local n=count('info'); for i=1,20 do Q:OnEvent('BAG_UPDATE',1) end; tick(); assert(count('info')==n+2)"),
    ('bank events ignored', "open(); tick(); Q:OnEvent('BAG_UPDATE',-1); Q:OnEvent('BAG_UPDATE',5); Q:OnEvent('BAG_UPDATE',-2); tick(); assert(Q.total==6 and Q.stats.bags==5 and not next(Q.dirty))"),
    ('hidden changes defer scans until open', "open(); Q:Toggle(); local n=count('info'); bags[0][1].count=8; Q:OnEvent('BAG_UPDATE',0); assert(not Q.running and count('info')==n); open(); assert(Q.slots['0:1'].count==8)"),
    ('only changed slot repainted', "open(); local n=Q.stats.painted; local c=Q.stats.classified; bags[0][1].count=8; Q:MarkBag(0); tick(); assert(Q.stats.painted==n+1 and Q.stats.classified==c and Q.stats.layouts==1 and Q.layoutNeeded and Q.buttons['0:1'].qCount.text=='8')"),
    ('lock change does not classify or lay out', "open(); local c=Q.stats.classified; local p=Q.stats.painted; bags[0][1].locked=1; Q:OnEvent('ITEM_LOCK_CHANGED'); tick(); assert(Q.stats.classified==c and Q.stats.painted==p+1 and Q.buttons['0:1'].desaturated==1 and not Q.layoutNeeded); bags[0][1].locked=nil; Q:MarkBag(0); tick(); assert(Q.buttons['0:1'].desaturated==nil)"),
    ('move and merge preserve physical buttons', "open(); local a=Q.buttons['0:1']; local point=a.point; bags[0][3]=item(100,2); bags[0][1]=nil; Q:MarkBag(0); tick(); assert(a==Q.buttons['0:1'] and a.point==point and not a.qRecord.occupied and Q.buttons['0:3'].qRecord.id==100 and Q.filled==4)") ,
    ('native click receives real bag and slot', "open(); script(Q.buttons['1:1'],'OnClick','RightButton'); assert(calls.use[1][1]==1 and calls.use[1][2]==1); script(Q.buttons['0:1'],'OnClick','LeftButton'); assert(calls.pickup[1][1]==0 and calls.pickup[1][2]==1)"),
    ('native split keeps ownership stable', "open(); shift=true; script(Q.buttons['0:1'],'OnClick','LeftButton'); assert(StackSplitFrame.owner==Q.buttons['0:1']); Q:Command('sort'); assert(Q.stats.layouts==1 and StackSplitFrame:IsShown()); Q:Toggle(); assert(not StackSplitFrame:IsShown())"),
    ('native control and drag', "open(); control=true; script(Q.buttons['0:2'],'OnClick','LeftButton'); assert(count('dressUp')==1); script(Q.buttons['1:1'],'OnDragStart'); assert(calls.pickup[1][1]==1); cursor=true; script(Q.buttons['0:3'],'OnReceiveDrag'); assert(calls.pickup[2][1]==0 and calls.pickup[2][2]==3)"),
    ('open with item already on cursor', "cursor=true; open(); assert(Q.hasLayout and Q.buttons['0:3']:IsVisible()); script(Q.buttons['0:3'],'OnReceiveDrag'); assert(count('pickup')==1)"),
    ('growth waits for cursor then becomes usable', "open(); cursor=true; bagSizes[1]=3; Q:MarkBag(1); tick(); assert(Q.geometryPending and not Q.buttons['1:3']:IsShown()); cursor=nil; tick(); assert(not Q.geometryPending and Q.buttons['1:3']:IsVisible() and Q.total==7)"),
    ('shrink hides invalid slots and updates totals', "open(); bagSizes[1]=0; Q:MarkBag(1); tick(); assert(Q.total==4 and Q.filled==3 and not Q.slots['1:1'] and not Q.buttons['1:1']:IsShown() and Q.buttons['1:1'].qRecord==nil)"),
    ('missing metadata is occupied and retried', "info[100].missing=true; open(); assert(Q.slots['0:1'].occupied and not Q.slots['0:1'].meta and Q.filled==4 and Q.pending==1 and Q.retryAt); info[100].missing=nil; tick(1); tick(); assert(Q.slots['0:1'].category=='consume' and Q.pending==0)"),
    ('retry bounded and hidden work stops', "info[100].missing=true; open(); for i=1,20 do tick(3) end; assert(Q.retryCount==5 and not Q.retryAt and not Q.running); Q:Toggle(); local n=count('info'); tick(10); assert(count('info')==n); info[100].missing=nil; open(); assert(Q.pending==0)"),
    ('texture without link never becomes empty', "bags[0][1].noLink=true; open(); assert(Q.slots['0:1'].occupied and Q.pending==1 and Q.buttons['0:1'].qTexture=='icon100')"),
    ('full item variant cache keys', "bags[0][3]=item(200,1,nil,9); open(); assert(Q.slots['0:2'].meta~=Q.slots['0:3'].meta)"),
    ('same item shares immutable metadata', "bags[0][3]=item(100,8); open(); assert(Q.slots['0:1'].meta==Q.slots['0:3'].meta and Q.slots['0:1'].count==2 and Q.slots['0:3'].count==8)"),
    ('inactive metadata evicted', "open(); local key=Q.slots['0:1'].meta.key; bags[0][1]=nil; Q:MarkBag(0); tick(); assert(Q.metadata[key]==nil and Q.filled==3)"),
    ('charge counts are not stack counts', "bags[0][1].count=-5; open(); local b=Q.buttons['0:1']; assert(b.qCount.text=='5' and b.count==1 and b.qRecord.charges==5); shift=true; script(b,'OnClick','LeftButton'); assert(not StackSplitFrame:IsShown())"),
    ('cooldown event only reads cooldowns', "open(); local n=count('info'); local c=Q.stats.classified; bags[0][1].start=10; bags[0][1].duration=30; bags[0][1].enabled=1; Q:OnEvent('BAG_UPDATE_COOLDOWN'); tick(); assert(count('info')==n and Q.stats.classified==c and Q.buttons['0:1'].qCooldown.timer[2]==30)"),
    ('literal search preserves geometry', "open(); local l=Q.stats.layouts; Q.search='['; Q:ApplySearch(); assert(Q.buttons['0:1'].alpha==0.22 and Q.stats.layouts==l); Q.search='100'; Q:ApplySearch(); assert(Q.buttons['0:1'].alpha==1 and Q.buttons['0:2'].alpha==0.22); Q.search='装备'; Q:ApplySearch(); assert(Q.buttons['0:2'].alpha==1)"),
    ('manual assignment and automatic restore', "open(); Q:SetOverride(100,'quest'); assert(Q.slots['0:1'].category=='quest' and Q.slots['0:1'].reason=='手动指定' and Q.stats.layouts==1); Q:Command('sort'); assert(Q.stats.layouts==2); Q:SetOverride(100,nil); assert(Q.slots['0:1'].category=='consume')"),
    ('invalid assignment is rejected', "open(); Q:SetOverride(100,'doesNotExist'); Q:SetOverride(100,'empty'); Q:SetOverride(-1,'quest'); assert(Q.db.overrides[100]==nil and Q.slots['0:1'].category=='consume')"),
    ('assignment popup executes selected category', "open(); alt=true; script(Q.buttons['0:1'],'OnClick','RightButton'); assert(Q.popup:IsShown() and count('nativeClick')==0); script(Q.popup.rows[1],'OnClick','LeftButton'); assert(Q.db.overrides[100]=='quest' and not Q.popup:IsShown())"),
    ('display order independent of rule priority', "open(); assert(Q:SetGroupOrder('equipment,quest')); assert(Q.categoryOrder[1].id=='equipment' and Q.rules[1].id=='quest' and Q.stats.layouts==1); assert(not Q:SetGroupOrder('equipment,equipment')); assert(Q.db.groupOrder[1]=='equipment')"),
    ('count-dependent custom rule invalidation', "table.insert(Q.categoryDefinitions,1,{id='bulk',name='大堆',minCount=3}); open(); assert(Q.slots['0:1'].category=='consume'); bags[0][1].count=5; Q:MarkBag(0); tick(); assert(Q.slots['0:1'].category=='bulk')"),
    ('literal rule name and explicit exclusions', "table.insert(Q.categoryDefinitions,1,{id='literal',name='字面',nameContains='[',exclude={200}}); info[100].name='[药水]'; open(); assert(Q.slots['0:1'].category=='literal')"),
    ('hover has one central callback and proper context', "open(); for _,b in pairs(Q.buttons) do assert(not b:GetScript('OnUpdate')) end; script(Q.buttons['0:1'],'OnEnter'); local owner={}; this=owner; tick(1.1); assert(this==owner and calls.cursorUpdate[1][1]==Q.buttons['0:1'] and table.getn(GameTooltip.lines)==3); script(Q.buttons['0:1'],'OnLeave'); tick(); assert(not Q.running)"),
    ('hover error restores this', "open(); local original={}; this=original; CursorUpdate=function() error('cursor failure') end; local ok=pcall(function() Q:WithButton(Q.buttons['0:1'],CursorUpdate) end); assert(not ok and this==original)"),
    ('strict fonts and failed file fallback', "failedFontPaths['Fonts\\FZXHLJW.TTF']=true; local f=newObject('FontString'); assert(not f:SetFont('Fonts\\FZXHLJW.TTF',12)); local ok=pcall(function() f:SetText('') end); assert(not ok); open(); Q:OpenAssignment(Q.buttons['0:1']); Q:Toggle(); open(); assert(Q:IsOpen())"),
    ('empty profession slot exposes real container', "open(); Q:Tooltip(Q.buttons['1:2']); assert(string.find(GameTooltip.lines[1],'专业包',1,true))"),
    ('events arriving during scan retained', "open(); local original=GetContainerItemInfo; local fired=false; GetContainerItemInfo=function(b,s) if not fired then fired=true; Q:MarkBag(1) end; return original(b,s) end; Q:MarkBag(0); tick(); assert(Q.dirty[1]); tick(); assert(not next(Q.dirty))"),
    ('configuration survives new runtime', "QianKunBagDB={columns=8,overrides={[100]='quest'},groupOrder={'equipment'}}; open(); assert(Q.db.columns==8 and Q.slots['0:1'].category=='quest' and Q.categoryOrder[1].id=='equipment'); Q:Command('columns 99'); assert(Q.db.columns==8); Q:Command('columns 6'); assert(Q.db.columns==6)"),
    ('diagnostic command needs no UI', "Q:Command('stats'); assert(not Q.window and not Q.running and table.getn(messages)==1)"),
    ('count and border above cooldown', "open(); local b=Q.buttons['0:2']; assert(b.qOverlay:GetFrameLevel()>b.qCooldown:GetFrameLevel() and b.qBorder.parent==b.qOverlay and b.qCount.parent==b.qOverlay)"),
    ('100 warm reopens do not allocate UI or reclassify', "open(); local c=Q.stats.classified; local p=Q.stats.painted; for i=1,100 do Q:Toggle(); open(); tick() end; assert(Q.stats.created==6 and Q.stats.layouts==1 and Q.stats.classified==c and Q.stats.painted==p)"),
    ('replacement cache stays bounded', "open(); for id=701,800 do info[id]={name='item'..id,quality=1,itemType='杂物',stack=1}; bags[0][1]=item(id); Q:MarkBag(0); tick() end; local n=0; for _ in pairs(Q.metadata) do n=n+1 end; assert(n==4 and Q.stats.created==6 and Q.filled==4)"),
    ('144 slots and 108 occupied retain fast warm path', "for b=0,3 do bagSizes[b]=36; for s=1,36 do bags[b][s]=s<=27 and item(100,s) or nil end end; bagSizes[4]=0; open(); assert(Q.total==144 and Q.filled==108 and Q.stats.created==144); local c=Q.stats.classified; local p=Q.stats.painted; for i=1,50 do Q:Toggle(); open(); tick() end; assert(Q.stats.created==144 and Q.stats.classified==c and Q.stats.painted==p and Q.stats.layouts==1)"),
    ('display sorting never moves physical items', "open(); Q:Command('sort'); Q:Command('columns 8'); Q:SetGroupOrder('empty,quest'); Q:Command('sort'); assert(count('pickup')==0 and count('use')==0 and count('nativeClick')==0)"),
    ('assignment search result updates in place', "open(); Q.search='任务'; Q:ApplySearch(); assert(Q.buttons['0:1'].qAlpha==0.22); Q:SetOverride(100,'quest'); assert(Q.buttons['0:1'].qAlpha==1 and Q.stats.layouts==1)"),
    ('stale slot cannot assign the previous item', "open(); bags[0][1]=item(500); Q:OpenAssignment(Q.buttons['0:1']); assert(not Q.popup and Q.dirty[0]); tick(); Q:OpenAssignment(Q.buttons['0:1']); assert(Q.popup.itemID==500)"),
    ('empty trailing slot shrink updates layout immediately', "open(); local l=Q.stats.layouts; bagSizes[1]=1; Q:MarkBag(1); Q:Refresh(false); assert(Q.total==5 and Q.stats.layouts==l+1 and not Q.geometryPending)"),
    ('no timer never presents stale timing', "open(); debugprofilestop=nil; Q:MarkBag(0); tick(); Q:Command('stats'); assert(Q.lastMs==nil and string.find(messages[table.getn(messages)],'不可计时',1,true))"),
    ('new inventory event renews exhausted retry budget', "info[100].missing=true; open(); for i=1,20 do tick(3) end; assert(Q.retryCount==5 and not Q.retryAt); Q:OnEvent('BAG_UPDATE',0); tick(); assert(Q.retryCount==0 and Q.retryAt); info[100].missing=nil; tick(3); tick(); assert(Q.pending==0)"),
]


def main():
    for label, program in CASES:
        lua = runtime()
        try:
            lua.execute(program)
        except Exception as exc:
            raise AssertionError(label) from exc
        print('PASS:', label)
    toc = (ADDON / 'QianKunBag.toc').read_text(encoding='utf-8')
    assert '## Interface: 11200' in toc and '## SavedVariablesPerCharacter: QianKunBagDB' in toc
    paths = [line for line in toc.splitlines() if line and not line.startswith('#')]
    assert paths == ['Core.lua', 'Categories.lua', 'Model.lua', 'View.lua', 'Bindings.xml']
    for path in paths:
        assert (ADDON / path).is_file()
    root = ET.parse(ADDON / 'Bindings.xml').getroot()
    binding = root.find('Binding')
    assert binding.attrib['name'] == 'QIANKUNBAG_TOGGLE' and 'QianKunBag:Toggle()' in binding.text
    for name in paths:
        if name.endswith('.lua'):
            text = (ADDON / name).read_text(encoding='utf-8')
            assert not re.search(r'\b(?:GetCursorInfo|C_Container|hooksecurefunc|SetBinding|loadstring)\s*\(', text)
            assert not re.search(r'\b(?:string\.match|table\.unpack|select)\s*\(', text)
            assert not re.search(r'(?m)^\s*(?:function\s+)?(?:OpenBackpack|ToggleBackpack|OpenAllBags)\s*[=(]', text)
    print(f'PASS: {len(CASES)} behavior groups; TOC/bindings and compatibility guards; client acceptance pending')


if __name__ == '__main__':
    main()
