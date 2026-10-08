from pathlib import Path
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = Path(r'E:\1.18\Interface\AddOns\PlayerLinkEnhance')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
local Object = {}; Object.__index = Object
function Object:GetName() return self.name end
function Object:GetID() return self.id end
function Object:GetParent() return self.parent end
function Object:GetWidth() return self.width or 128 end
function Object:GetHeight() return self.height or 16 end
function Object:SetWidth(v) self.width=v end
function Object:SetHeight(v) self.height=v end
function Object:ClearAllPoints() self.points={} end
function Object:SetPoint(...) table.insert(self.points, {...}) end
function Object:GetPoint(i) return unpack(self.points[i or 1]) end
function Object:GetNumPoints() return #self.points end
function Object:GetHitRectInsets() return unpack(self.hit or {0,0,0,0}) end
function Object:SetHitRectInsets(...) self.hit={...} end
function Object:SetTexture(...) local args={...};self.texture=type(args[1])=='string' and args[1] or nil; self.fill=args end
function Object:GetTexture() return self.texture end
function Object:SetBlendMode(v) self.blend=v end
function Object:GetBlendMode() return self.blend or 'ADD' end
function Object:GetVertexColor() return unpack(self.color or {1,1,1,1}) end
function Object:SetVertexColor(...) self.color={...} end
function Object:GetBackdropColor() return unpack(self.bg or {.1,.1,.1,.8}) end
function Object:SetBackdropColor(...) self.bg={...} end
function Object:GetScript(event) return self.scripts[event] end
function Object:SetScript(event,fn) self.scripts[event]=fn end
function Object:Fire(event)
 local prev=this; this=self
 if self.scripts[event] then self.scripts[event]() end
 this=prev
end
function Object:Show() if not self.shown then self.shown=true; self:Fire('OnShow') end end
function Object:Hide() if self.shown then self.shown=false; self:Fire('OnHide') end end
function Object:CreateTexture() return CreateFrame('Texture',nil,self) end
function CreateFrame(kind,name,parent)
 local obj=setmetatable({name=name,parent=parent,points={},scripts={},shown=false},Object)
 if name then _G[name]=obj end
 return obj
end
function getglobal(name) return _G[name] end
UIDROPDOWNMENU_MAXLEVELS=3; UIDROPDOWNMENU_MENU_LEVEL=1
StaticPopupDialogs={}; UnitPopupButtons={}; UnitPopupMenus={}; SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(self,message) lastDiagnostic=message end}
UnitPopupMenus.SELF={'LOOT_METHOD','RAID_TARGET_ICON','LEAVE','CANCEL'}
UnitPopupMenus.PET={'PET_ABANDON','PET_PAPERDOLL','CANCEL'}
UnitPopupMenus.RAID={'RAID_REMOVE','CANCEL'}
UnitPopupMenus.RAID_TARGET_ICON={'RAID_TARGET_1','RAID_TARGET_NONE'}
UNKNOWN='未知'; ADD_FRIEND='添加好友'; IGNORE='屏蔽'; WHO='查询'
function TEXT(v) return v end
function hooksecurefunc(name, fn)
 local old=_G[name]; _G[name]=function(...) if old then old(...) end; fn(...) end
end
function UnitPopup_HideButtons() end
actions={}; party={'Alice','Bob'}; raid={}; leader=true; officer=false
function UnitName(unit)
 if unit=='player' then return 'Me' end
 if unit=='target' then return targetName or 'Alice' end
 return party[tonumber(string.match(unit or '', '^party(%d+)$'))]
end
function GetNumRaidMembers() return #raid end
function GetNumPartyMembers() return #party end
function GetRaidRosterInfo(i) if raid[i] then return raid[i].name,raid[i].rank end end
function IsPartyLeader() return leader end
function IsRaidLeader() return leader end
function IsRaidOfficer() return officer end
function AddIgnore(name) table.insert(actions,{'ignore',name}) end
function UninviteFromRaid(index) table.insert(actions,{'raidremove',raid[index].name}) end
function UninviteFromParty(unit) table.insert(actions,{'partyremove',UnitName(unit)}) end
function LeaveParty() table.insert(actions,{'leave'}) end
function PlaySound() end
function SetItemRef() end
function UnitPopup_OnClick()
 table.insert(actions,{this.value, getglobal(UIDROPDOWNMENU_INIT_MENU).name})
end
function StaticPopup_Show(which,text)
 popup=CreateFrame('Frame','TestPopup'); popup.which=which; popup.text=text
 return popup
end
function AcceptPopup()
 local previous=this;this=CreateFrame('Button',nil,popup)
 StaticPopupDialogs[popup.which].OnAccept(popup.data);this=previous
end
function CancelPopup()
 local previous=this;this=popup;StaticPopupDialogs[popup.which].OnHide(popup.data);this=previous
end
function CloseDropDownMenus()
 for i=1,3 do getglobal('DropDownList'..i):Hide() end
end
for level=1,3 do
 local list=CreateFrame('Button','DropDownList'..level); list.id=level
 list.numButtons=0; list.maxWidth=0
 list:SetScript('OnShow', function()
   for i=1,this.numButtons do getglobal(this:GetName()..'Button'..i):SetWidth(this.maxWidth) end
   this:SetWidth(this.maxWidth+15)
 end)
 local bg=CreateFrame('Frame',list:GetName()..'MenuBackdrop',list)
 bg.backdrop=CreateFrame('Frame',nil,bg)
 CreateFrame('Frame',list:GetName()..'Backdrop',list)
 for i=1,32 do
   local b=CreateFrame('Button',list:GetName()..'Button'..i,list); b.id=i
   CreateFrame('FontString',b:GetName()..'NormalText',b)
   local highlight=CreateFrame('Texture',b:GetName()..'Highlight',b)
   highlight:SetTexture('original-highlight')
 end
end
function UIDropDownMenu_AddButton(info,level)
 local list=getglobal('DropDownList'..(level or 1)); list.numButtons=list.numButtons+1
 local b=getglobal(list:GetName()..'Button'..list.numButtons)
 b.value=info.value; b.func=info.func; b.text=info.text; b.disabled=info.disabled or info.isTitle
 b.icon=info.icon; b.checked=info.checked; b.hasArrow=info.hasArrow
 b.textColor={info.textR,info.textG,info.textB}
 b.fontSize=info.textHeight or 12
 b:ClearAllPoints();b:SetPoint('TOPLEFT',list,'TOPLEFT',15,-15-16*(b.id-1))
 local t=getglobal(b:GetName()..'NormalText');t:ClearAllPoints();t:SetPoint('LEFT',b,'LEFT',0,0)
 list.maxWidth=math.max(list.maxWidth,100+#(info.text or '')*2)
 list:SetHeight(list.numButtons*16+30);b:Show()
end
function UnitPopup_ShowMenu(dropdown,which,unit,name,userData)
 if forceError then error('other addon failure') end
 dropdown.name=name or UnitName(unit); dropdown.unit=unit; dropdown.which=which
 UIDropDownMenu_AddButton({text=dropdown.name,isTitle=1,notCheckable=1},UIDROPDOWNMENU_MENU_LEVEL)
 for _,value in ipairs(UnitPopupMenus[which]) do
   if not hidden or not hidden[value] then
     local info={text=(UnitPopupButtons[value] or {}).text or value,value=value,
       func=UnitPopup_OnClick,notCheckable=1,disabled=value=='TRADE',hasArrow=value=='RAID_TARGET_ICON'}
     if which=='RAID_TARGET_ICON' then info.icon='raid-icon';info.checked=1;info.notCheckable=nil end
     UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL)
   end
 end
end
dropdown=CreateFrame('Frame','TargetFrameDropDown')
UIDROPDOWNMENU_INIT_MENU='TargetFrameDropDown'
function Open(which,level)
 level=level or 1;UIDROPDOWNMENU_MENU_LEVEL=level
 local list=getglobal('DropDownList'..level);list:Hide();list.numButtons=0;list.maxWidth=0
 UnitPopup_ShowMenu(dropdown,which,'target');list:Show()
 return list
end
function Find(value,level)
 local list=getglobal('DropDownList'..(level or 1))
 for i=1,list.numButtons do local b=getglobal(list:GetName()..'Button'..i);if b.value==value then return b end end
end
function Click(value,level)
 local prev=this;this=Find(value,level);this.func();this=prev
end
''')

# Use the original XML Script and Frame OnLoad sequence, with no new TOC file.
lua.execute(ROOT.joinpath('PlayerLinkEnhance.lua').read_text(encoding='utf-8-sig'))
lua.execute('PlayerLinkEnhance_OnLoad()')
# Cached TOCs may still attempt to execute the old entry; it must be harmless.
lua.execute(ROOT.joinpath('SaferMenu.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
assert(PLE_SAFER_MENU_LOADED=='1.8.3-compact')
SlashCmdList.PLEMENU();assert(string.find(lastDiagnostic,'已加载'))
table.insert(UnitPopupMenus.PLAYER,1,'PF_SET_FOCUS')
table.insert(UnitPopupMenus.PLAYER,2,'OTHER_ADDON_ACTION')
local list=Open('PLAYER')
assert(DropDownList1Button2.value=='INSPECT','inspect must be the first action')
local inspect,invite=Find('INSPECT'),Find('INVITE')
assert(inspect.text=='观察装备' and invite.text=='邀请入队')
assert(inspect:GetHeight()==20 and invite:GetHeight()==20)
assert(invite:GetPoint(1) ~= nil and inspect.id+1 < invite.id,'inspect/invite must not be adjacent')
assert(inspect.textColor[3]==1 and invite.textColor[2]==1)
assert(Find('PF_SET_FOCUS') and Find('OTHER_ADDON_ACTION'),'preserve addon actions')
assert(Find('RAID_TARGET_ICON').hasArrow,'preserve marker submenu')
assert(Find('TRADE').disabled,'preserve disabled buttons')
assert(DropDownList1Button1.disabled,'title stays nonclickable')
for i=2,list.numButtons do
 local prev=getglobal(list:GetName()..'Button'..(i-1));local b=getglobal(list:GetName()..'Button'..i)
 assert(-b.points[1][5] >= -prev.points[1][5]+prev:GetHeight()+1,'no overlapping hit areas')
end
assert(inspect:GetWidth()==list:GetWidth()-16,'full-width hit area')
assert(list:GetWidth()<240 and list:GetHeight()<550,'compact size')
assert(DropDownList1MenuBackdrop.backdrop.bg[4]==.85,'translucent pfUI background')
Click('INSPECT');Click('INVITE')
assert(actions[1][1]=='INSPECT' and actions[2][1]=='INVITE','keep original dispatch')
assert(actions[1][2]=='Alice' and actions[2][2]=='Alice')
local height=list:GetHeight();list:Hide();list:Show()
assert(inspect:GetHeight()==16,'restore shared pool on hide')
-- Generic dropdowns must keep their original geometry, font and texture.
list:Hide();list.numButtons=0;list.maxWidth=0
UIDropDownMenu_AddButton({text='Settings',value='GENERIC'})
list:Show()
assert(DropDownList1Button1:GetHeight()==16 and DropDownList1Button1.fontSize==12)
assert(DropDownList1Button1Highlight:GetTexture()=='original-highlight')
assert(DropDownList1MenuBackdrop.backdrop.bg[4]==.8)
-- Do not execute on the initial click; use the captured name on acceptance.
actions={};targetName='Alice';Open('PLAYER');Click('ADD_IGNORE');CancelPopup()
assert(#actions==0 and popup.data==nil,'cancel discards pending action')
Open('PLAYER');Click('ADD_IGNORE')
assert(#actions==0 and string.find(popup.text,'Alice'))
targetName='Bob';Open('PLAYER');AcceptPopup()
assert(#actions==1 and actions[1][2]=='Alice','confirmation cannot follow a changed target')
-- Re-resolve raid indices if the roster has reordered during confirmation.
actions={};raid={{name='Alice',rank=0},{name='Bob',rank=0}};targetName='Alice'
Open('PLAYER');Click('REMOVE');raid={{name='Bob',rank=0},{name='Alice',rank=0}};AcceptPopup()
assert(#actions==1 and actions[1][2]=='Alice')
actions={};Open('PLAYER');Click('REMOVE');leader=false;officer=false;AcceptPopup()
assert(#actions==0,'recheck permissions')
leader=true;Open('PLAYER');Click('REMOVE');raid={{name='Bob',rank=0}};AcceptPopup()
assert(#actions==0,'departed member cannot cause removal of another player')
-- Party token reuse must also resolve by name.
raid={};party={'Alice','Bob'};Open('PARTY');Click('UNINVITE');party={'Bob','Alice'};AcceptPopup()
assert(actions[1][2]=='Alice')
actions={};Open('SELF');Click('LEAVE');party={'Charlie'};AcceptPopup();assert(#actions==0)
-- Icons and checked state in second-level menus remain native.
local child=Open('RAID_TARGET_ICON',2)
assert(Find('RAID_TARGET_1',2).icon=='raid-icon' and Find('RAID_TARGET_1',2).checked==1)
child:Hide();assert(Find('RAID_TARGET_1',2):GetHeight()==16)
-- If another addon errors during construction, later dropdowns stay normal.
forceError=true;local ok=pcall(Open,'PLAYER');assert(not ok);forceError=false
DropDownList1.numButtons=0;DropDownList1.maxWidth=0
UIDropDownMenu_AddButton({text='Settings',value='GENERIC'})
assert(DropDownList1Button1.fontSize==12)
-- A sparse visible menu still separates inspect and invite by an empty group gap.
hidden={};for _,value in ipairs(UnitPopupMenus.PLAYER) do
 if value~='INSPECT' and value~='INVITE' and value~='CANCEL' then hidden[value]=true end
end
local sparse=Open('PLAYER');inspect,invite=Find('INSPECT'),Find('INVITE')
assert(-invite.points[1][5] - (-inspect.points[1][5]+20) >= 5)
local originalHeight=sparse:GetHeight();sparse:Fire('OnShow')
assert(sparse:GetHeight()==originalHeight,'OnShow layout must be idempotent')
''')
ET.parse(ROOT / 'PlayerLinkEnhance.xml')
toc = (ROOT / 'PlayerLinkEnhance.toc').read_text(encoding='utf-8-sig')
assert 'PlayerLinkEnhance.xml' in toc and '\nSaferMenu.lua' not in toc
assert not (ROOT / 'PlayerLinkEnhance.toc').read_bytes().replace(b'\r\n',b'').count(b'\n')
assert not (ROOT / 'PlayerLinkEnhance.lua').read_bytes().replace(b'\r\n',b'').count(b'\n')
print('PASS: grouping, inspect/invite separation and dispatch, shared dropdown restoration,')
print('confirmation cancellation/target changes, roster changes/permissions, marker submenu, error recovery.')
