"""StatCompare talent sessions: legacy UI/font contract and optional real client parser.

The optional native file stays outside Git. Passing these simulations does not
establish live server transport, client rendering or actual resource use.
"""
from pathlib import Path
import argparse
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / 'Interface/AddOns/StatCompare/SCInspectTalents.lua'
NATIVE = ROOT / 'PluginHistory/staging/statcompare-inspect-research/patch-9.mpq-InspectTalentsFrame.lua'
FONT = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')

BASE = r'''
objects, sends, notices, delivered = {}, {}, {}, {}
clock, renders, nativeEvents, nativeInspect, nativeShows = 0, 0, 0, 0, 0
targetName, targetClass, targetKey = 'Alpha', 'WARRIOR', 'guid-A'
targetValid, targetInspectable, talentLoaded, control = true, true, true, false
local methods = {}
local function invoke(obj, script, ...)
 local oldThis,oldEvent,oldArg1=this,event,arg1
 this=obj;arg1=select(1,...)
 local f=obj.scripts[script]
 if f then f() end
 this,event,arg1=oldThis,oldEvent,oldArg1
end
local function visible(obj)
 return obj.shown and (not obj.parent or visible(obj.parent))
end
local function updateVisibility()
 for _,obj in ipairs(objects) do
  local now=visible(obj)
  if now~=obj.wasVisible then
   obj.wasVisible=now
   invoke(obj,now and 'OnShow' or 'OnHide')
  end
 end
end
function NewObject(kind,name,parent)
 local obj=setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=false,wasVisible=false},{__index=methods})
 table.insert(objects,obj);if name then _G[name]=obj end;return obj
end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:Show() self.shown=true;updateVisibility() end
function methods:Hide() self.shown=false;updateVisibility() end
function methods:IsShown() return self.shown end
function methods:IsVisible() return visible(self) end
function methods:GetID() return self.id end
function methods:SetPoint(...) self.point={...} end
function methods:SetWidth(width) self.width=width end
function methods:SetTextColor(...) self.color={...} end
InstallFonts(methods,NewObject)
function CreateFrame(kind,name,parent) return NewObject(kind,name,parent) end
InspectFrame=CreateFrame('Frame','InspectFrame');InspectFrame.id=0
InspectPaperDollFrame=CreateFrame('Frame','InspectPaperDollFrame',InspectFrame);InspectPaperDollFrame.id=1
InspectHonorFrame=CreateFrame('Frame','InspectHonorFrame',InspectFrame);InspectHonorFrame.id=2
InspectArenaFrame=CreateFrame('Frame','InspectArenaFrame',InspectFrame);InspectArenaFrame.id=3
InspectTalentsFrame=CreateFrame('Frame','InspectTalentsFrame',InspectFrame);InspectTalentsFrame.id=4
TWTalentFrame=CreateFrame('Frame','TWTalentFrame',InspectTalentsFrame)
INSPECTFRAME_SUBFRAMES={'InspectPaperDollFrame','InspectHonorFrame','InspectArenaFrame','InspectTalentsFrame'}
function PanelTemplates_SetTab(frame,id) frame.selectedTab=id end
function InspectFrame_ShowSubFrame(name)
 for _,n in ipairs(INSPECTFRAME_SUBFRAMES) do if n==name then _G[n]:Show() else _G[n]:Hide() end end
end
function HideUIPanel(frame) frame:Hide() end
function GetTime() return clock end
function UnitExists(unit)
 if not targetValid then return nil end
 return 1,targetKey
end
function UnitName(unit) return targetValid and targetName or nil end
function UnitClass(unit) return targetClass,targetClass end
function UnitIsPlayer(unit) return targetValid end
function UnitIsUnit(a,b) return targetValid and (a=='target' or a=='mouseover') and b=='target' end
function CanInspect(unit) return targetValid and targetInspectable end
function IsControlKeyDown() return control end
function IsAddOnLoaded(name) return name~='Blizzard_TalentUI' or talentLoaded end
function LoadAddOn(name) if loadFailure then return nil,'MISSING' end;talentLoaded=true;return 1 end
function SendAddonMessage(prefix,message,channel,recipient)
 if sendFailure then error('send failure') end
 table.insert(sends,{prefix,message,channel,recipient});return 'sent',recipient
end
SavedSend=SendAddonMessage
DEFAULT_CHAT_FRAME={AddMessage=function(self,text) table.insert(notices,text) end}
UNKNOWNOBJECT='Unknown'
strfind=string.find;format=string.format
function explode(message,separator)
 local out={};for field in string.gmatch(message..separator,'(.-)'..separator) do table.insert(out,field) end;return out
end
Turtle_TalentsData={}
for _,class in ipairs({'WARRIOR','MAGE','PALADIN'}) do
 Turtle_TalentsData[class]={}
 for tree=1,3 do
  local tab={name=class..'-tree'..tree,background='background'}
  for i=1,2 do tab[i]={name=class..'-node'..i,icon='spell',desc={'rank-one','rank-two','rank-three','rank-four','rank-five'}} end
  Turtle_TalentsData[class][tree]=tab
 end
end
function GetNumTalentTabs() return 3 end
function GetNumTalents(tree) return 2 end
function GetTalentTabInfo(tree) return 'own-tree','icon',2 end
function GetTalentInfo(tree,i) return 'own-node','icon',i,i,1,5,nil,1 end
function GetTalentPrereqs(tree,i) return nil,nil,nil end
TOOLTIP_TALENT_RANK='%d/%d'
function Tick(seconds)
 clock=clock+seconds
 for _,obj in ipairs(objects) do if obj.scripts.OnUpdate then invoke(obj,'OnUpdate',seconds) end end
end
function ActiveUpdates()
 local n=0;for _,obj in ipairs(objects) do if obj.scripts.OnUpdate then n=n+1 end end;return n
end
function Requests()
 local n=0;for _,s in ipairs(sends) do if s[2]=='INSTalentShow' then n=n+1 end end;return n
end
function FireTarget(name,class,key)
 targetName,targetClass,targetKey=name,class,key
 local old=event;event='PLAYER_TARGET_CHANGED';invoke(InspectFrame,'OnEvent');event=old
end
function OpenTarget(name,class,key)
 InspectTalentsFrame:Hide();InspectFrame:Hide()
 targetName,targetClass,targetKey=name or 'Alpha',class or 'WARRIOR',key or 'guid-A'
 InspectFrame.unit='target';InspectFrame:Show();SCInspectTalents.Open()
end
function Tab(tree,points,count) return 'INSTalentTabInfo;'..tree..';tree;'..(points or 3)..';'..(count or 2) end
function Info(tree,i,rank)
 return 'INSTalentInfo;'..tree..';'..i..';node;'..i..';'..i..';'..(rank or i)..';5;1;-1;-1;-1'
end
function Feed(message,sender) InspectTalentsFrame_HandleMessage(message,sender or targetName) end
function Complete(sender)
 for tree=1,3 do Feed(Tab(tree),sender);for i=1,2 do Feed(Info(tree,i),sender) end end
 Feed('INSTalentEND;',sender)
end
'''

# Small independently written behavioral contract, used only when no extracted
# client parser is available. Real-client runs read their source from --native.
FALLBACK = r'''
local state={class='',{},{},{}}
local owner=''
function NativeState() return state,owner end
function NativeRead(t,i) local n=state[t][i];return '', '', n.tier,n.column,n.rank,n.maximum end
function NativeTab(t) return '', '',state[t].pointsSpent end
function InspectTalentsFrame_OnShow()
 if owner==targetName then TWTalentFrame:Show();return end
 state.class=targetClass
 for t=1,3 do state[t]={pointsSpent=0,numTalents=0} end
 SendAddonMessage('TW_CHAT_MSG_WHISPER<'..targetName..'>','INSTalentShow','GUILD')
end
function InspectTalentsFrame_HandleMessage(message,sender)
 local f=explode(message,';')
 if message=='INSTalentShow' then SendAddonMessage('peer','peer-response','GUILD');return end
 if f[1]=='INSTalentTabInfo' then
  local t=tonumber(f[2]);state[t].pointsSpent=tonumber(f[4]);state[t].numTalents=tonumber(f[5])
 elseif f[1]=='INSTalentInfo' then
  local t,i=tonumber(f[2]),tonumber(f[3]);state[t][i]={tier=tonumber(f[5]),column=tonumber(f[6]),rank=tonumber(f[7]),maximum=tonumber(f[8])}
 elseif message=='INSTalentEND;' then
  owner=targetName;TWTalentFrame:Hide();TWTalentFrame:Show()
 end
end
'''

HARNESS = r'''
local rawShow,rawMessage=InspectTalentsFrame_OnShow,InspectTalentsFrame_HandleMessage
RawNativeShow,RawNativeMessage=rawShow,rawMessage
InspectTalentsFrame_OnShow=function()
 nativeShows=nativeShows+1
 if extraSend then SendAddonMessage('OTHER','SIDE','WHISPER','SideTarget') end
 if initFailure then error('native init failed') end
 return rawShow()
end
InspectTalentsFrame_HandleMessage=function(message,sender)
 table.insert(delivered,{message,sender});return rawMessage(message,sender)
end
InspectTalentsFrame:SetScript('OnShow',function() InspectTalentsFrame_OnShow() end)
InspectFrame:SetScript('OnEvent',function()
 nativeEvents=nativeEvents+1
 if event=='PLAYER_TARGET_CHANGED' or event=='PARTY_MEMBERS_CHANGED' then nativeInspect=nativeInspect+1 end
end)
InspectFrame:SetScript('OnHide',function() InspectFrame.unit=nil end)
TWTalentFrame:SetScript('OnShow',function()
 local state,owner=NativeState()
 assert(state.class==targetClass,'native cache class does not match displayed player')
 assert(owner==targetName,'native cache owner does not match displayed player')
 for tree=1,3 do
  local total=0;assert(state[tree].numTalents==2,'native renderer received incomplete tree')
  for i=1,2 do local _,_,tier,column,rank,maximum=NativeRead(tree,i);assert(tier and column and rank and maximum);total=total+rank end
  local _,_,points=NativeTab(tree);assert(points==total,'native point total mismatch')
 end
 renders=renders+1
end)
'''


def native_chunk(path):
    if path and path.is_file():
        text = path.read_text(encoding='utf-8-sig')
        marker = 'TWTalent.TALENT_BRANCH_ARRAY = {}'
        if marker not in text:
            raise AssertionError('Unrecognized native parser boundary')
        return text.split(marker, 1)[0] + '''
function NativeState() return inspectCom.SPEC,loadedFor end
function NativeRead(t,i) return TWTalent.GetTalentInfo(t,i) end
function NativeTab(t) return TWTalent.GetTalentTabInfo(t) end
''', 'actual extracted client parser'
    return FALLBACK, 'independent native contract (no game source available)'


def world(native, enabled=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().InstallFonts = lua.execute(FONT)
    lua.execute(BASE)
    lua.execute(native)
    lua.execute(HARNESS)
    lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
    if enabled:
        lua.execute('SCInspectTalents.SetEnabled(true)')
    return lua


def main():
    from test_statcompare_shared_roles import main as shared_main
    shared_main()


if __name__ == '__main__':
    main()
