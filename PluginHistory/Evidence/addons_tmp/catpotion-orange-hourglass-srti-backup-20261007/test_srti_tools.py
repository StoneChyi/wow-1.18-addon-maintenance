from pathlib import Path
import sys
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = Path(r'E:\1.18\Interface\AddOns\SimpleRaidTargetIcons')

MOCK = r'''
local Object = {}; Object.__index = Object
frameObjects={}
function Object:GetName() return self.name end
function Object:GetID() return self.id end
function Object:SetID(v) self.id=v end
function Object:GetObjectType() return self.kind end
function Object:GetParent() return self.parent end
function Object:SetWidth(v) self.width=v end
function Object:SetHeight(v) self.height=v end
function Object:GetWidth() return self.width or 0 end
function Object:GetHeight() return self.height or 0 end
function Object:SetPoint(...) table.insert(self.points,{...}) end
function Object:ClearAllPoints() self.points={} end
function Object:SetAllPoints() end
function Object:SetScale(v) self.scale=v end
function Object:GetScale() return self.scale or 1 end
function Object:SetAlpha(v) self.alpha=v end
function Object:SetText(v) self.text=v or '' end
function Object:GetText() return self.text end
function Object:SetFont(...) end
function Object:SetJustifyH(...) end
function Object:SetTextColor(...) self.color={...} end
function Object:GetStringWidth()
 local s=self.text or ''; local count=0; local i=1
 while i<=string.len(s) do
  local b=string.byte(s,i)
  if b<128 then count=count+5; i=i+1
  elseif b<224 then count=count+9; i=i+2
  elseif b<240 then count=count+9; i=i+3
  else count=count+9; i=i+4 end
 end
 return count
end
function Object:SetTexture(v) assert(v~=nil, 'nil texture'); self.texture=v end
function Object:SetTexCoord(...) self.coords={...} end
function Object:SetVertexColor(...) self.color={...} end
function Object:SetStatusBarTexture(v) self.texture=v end
function Object:SetStatusBarColor(...) self.color={...} end
function Object:SetMinMaxValues(a,b) self.minimum=a; self.maximum=b end
function Object:SetValue(v) self.value=v end
function Object:GetValue() return self.value end
function Object:SetChecked(v) self.checked=v end
function Object:GetChecked() return self.checked end
function Object:SetMovable(v) self.movable=v end
function Object:IsMovable() return self.movable end
function Object:SetUserPlaced(...) end
function Object:StartMoving() end
function Object:StopMovingOrSizing() end
function Object:GetLeft() return 200 end
function Object:GetTop() return 400 end
function Object:GetBottom() return 364 end
function Object:SetScript(event, fn)
 if event=='OnClick' then assert(self.kind=='Button' or self.kind=='CheckButton', 'invalid script') end
 self.scripts[event]=fn
end
function Object:GetScript(event) return self.scripts[event] end
function Object:RegisterEvent(...) end
function Object:UnregisterEvent(...) end
function Object:RegisterForClicks(...) end
function Object:EnableMouse(...) end
function Object:Enable() self.disabled=false end
function Object:Disable() self.disabled=true end
function Object:SetBackdrop(...) end
function Object:SetBackdropColor(...) end
function Object:SetBackdropBorderColor(...) end
function Object:RegisterForDrag(...) end
function Object:SetHighlightTexture(...) end
function Object:Fire(script, arg)
 local oldThis,oldArg=this,arg1; this=self; arg1=arg
 if self.scripts[script] then self.scripts[script]() end
 this=oldThis; arg1=oldArg
end
function Object:Show()
 local old=self.shown; self.shown=true
 if not old then self:Fire('OnShow') end
end
function Object:Hide()
 local old=self.shown; self.shown=false
 if old then self:Fire('OnHide') end
end
function Object:IsShown() return self.shown end
function Object:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Object:CreateTexture(name) return CreateFrame('Texture',name,self) end
function Object:CreateFontString(name) return CreateFrame('FontString',name,self) end
function CreateFrame(kind,name,parent,template)
 local obj=setmetatable({kind=kind,name=name,parent=parent,scripts={},points={},shown=true,scale=1},Object)
 if name then _G[name]=obj end
 table.insert(frameObjects,obj)
 if template=='OptionsCheckButtonTemplate' then CreateFrame('FontString',name..'Text',obj) end
 return obj
end
function getglobal(name) return _G[name] end
UIParent=CreateFrame('Frame','UIParent'); BananaFrame=CreateFrame('Frame','BananaFrame')
BananaConfigFrame=CreateFrame('Frame','BananaConfigFrame',UIParent); BananaConfigFrame:Hide()
RaidTargetFrame=CreateFrame('Frame','RaidTargetFrame',UIParent)
local controls={'ComboBoxLayout','CheckButtonShowInRaid','CheckButtonEnabled','LabelSuperWoWHint',
 'CheckButtonShowInParty','CheckButtonShowOutOfGroup','CheckButtonHideUnused','CheckButtonDisableSound',
 'CheckButtonDisableErrorText','CheckButtonGreyOutDeath','CheckButtonShowExtraInfo','ResizeSlider',
 'Label4','Flip','FlipText','Detach','DetachText'}
for _,name in ipairs(controls) do CreateFrame('CheckButton','BananaConfigFrame'..name,BananaConfigFrame) end
for i=1,9 do
 local button=CreateFrame('Button','RaidTargetFrame'..i..'Button',UIParent); button.id=i
 for _,suffix in ipairs({'Icon','Flash','HotKey','Name','Count','MobName','TargetSymbol'}) do
  CreateFrame('FontString',button.name..suffix,button)
 end
end
units={}; time=10; partyCount=0; raidCount=0; inInstance=false; combat=false
raidLeader=true; partyLeader=true; raidOfficer=false; messages={}; announcements={}
function UnitExists(unit) if units[unit] then return 1,units[unit].guid end end
function UnitName(unit) return units[unit] and units[unit].name end
function UnitHealth(unit) return units[unit] and units[unit].hp or 0 end
function UnitHealthMax(unit) return units[unit] and units[unit].max or 0 end
function UnitIsDead(unit) return units[unit] and units[unit].dead end
function UnitIsGhost(unit) return units[unit] and units[unit].ghost end
function UnitClass(unit) return 'Warrior','WARRIOR' end
function UnitIsUnit(a,b) return a==b and units[a]~=nil end
function UnitDebuff(unit,i) if i==1 and units[unit] then return units[unit].debuff end end
function GetRaidTargetIndex(unit) return units[unit] and units[unit].mark end
function UnitAffectingCombat(unit) return combat end
function IsInInstance() return inInstance end
function IsRaidLeader() return raidLeader end
function IsRaidOfficer() return raidOfficer end
function IsPartyLeader() return partyLeader end
function GetNumPartyMembers() return partyCount end
function GetNumRaidMembers() return raidCount end
function GetTime() return time end
function GetRealZoneText() return 'Test Dungeon' end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function UIDropDownMenu_Initialize(...) end
function UIDropDownMenu_SetSelectedID(...) end
function UIDropDownMenu_AddButton(...) end
function PlaySoundFile(...) end
function ResetInstances() resets=(resets or 0)+1 end
function DoReadyCheck() ready=(ready or 0)+1 end
function SendChatMessage(text,channel) table.insert(announcements,{text,channel}) end
function StaticPopup_Show(which) popup=which end
function SetRaidTarget(unit,index) table.insert(messages, 'mark:'..unit..':'..index) end
DEFAULT_CHAT_FRAME={AddMessage=function(self,text) table.insert(messages,text) end}
GameTooltip=CreateFrame('Frame','GameTooltip')
function GameTooltip:SetOwner(...) end
function GameTooltip:AddLine(...) end
function GameTooltip_SetDefaultAnchor(...) end
function GetCVar() return '1' end
RAID_CLASS_COLORS={WARRIOR={r=1,g=.5,b=0}}
NORMAL_FONT_COLOR={r=1,g=1,b=1}; GRAY_FONT_COLOR={r=.5,g=.5,b=.5}
STANDARD_TEXT_FONT='font'; FONT_COLOR_CODE_CLOSE='|r'; ACCEPT='Accept'; CANCEL='Cancel'
for i=1,8 do _G['RAID_TARGET_'..i]='Mark'..i end
SlashCmdList={}; StaticPopupDialogs={}
'''

def world(superwow=True, enabled=1, missing_option=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if superwow:
        lua.execute('SetAutoloot=function() end')
    for name in ('IconTextures.lua', 'Banana.lua', 'RaidTools.lua', 'Localization.lua'):
        lua.execute((ROOT / name).read_text(encoding='utf-8-sig'))
    lua.execute(f'''BANANA_CONFIG.ENABLED={enabled}; BANANA_CONFIG.SHOW_EXTRA_INFO=0
        BANANA_CONFIG.BUTTON_LAYOUT=1
        event='ADDON_LOADED'; arg1='SimpleRaidTargetIcons'; this=BananaFrame
        Banana_OnEvent()''')
    return lua

def check(lua, code):
    lua.execute(code)

# Parse every addon Lua chunk and XML; load order includes RaidTools before XML callbacks.
syntax = LuaRuntime()
for path in ROOT.glob('*.lua'):
    syntax.execute('assert(loadstring(...))', path.read_text(encoding='utf-8-sig'))
syntax.execute('assert(loadstring(...))', (ROOT.parent / 'S_ChatBar/ChatBar.lua').read_text(encoding='utf-8-sig'))
for path in ROOT.glob('*.xml'):
    ET.parse(path)
toc = (ROOT / 'SimpleRaidTargetIcons.toc').read_text(encoding='utf-8-sig')
assert toc.index('RaidTools.lua') < toc.index('Banana.xml')
assert toc.index('IconTextures.lua') < toc.index('SimpleRaidTargetIcons.lua')

lua = world()
check(lua, r'''
assert(SRTI_SaveBtn:IsShown()); assert(SRTI_ResetButton:IsShown())
for index=1,9 do
 local icon=getglobal('RaidTargetFrame'..index..'ButtonIcon')
 SRTI_SetIconTexture(icon,index)
 assert(icon.texture=='Interface\\AddOns\\SimpleRaidTargetIcons\\img\\srti_icons_borderless')
 assert(icon.coords[1]<icon.coords[2] and icon.coords[3]<icon.coords[4])
 assert(icon.coords[1]>=0 and icon.coords[2]<=1 and icon.coords[3]>=0 and icon.coords[4]<=1)
 assert(math.abs((icon.coords[2]-icon.coords[1])-(icon.coords[4]-icon.coords[3]))<.0001)
 assert(icon.coords[2]-icon.coords[1]>.2 and icon.coords[2]-icon.coords[1]<.34)
end
assert(BANANA_CONFIG.SHOW_SHORT_NAME==0)
units.mark1={name='这是一个非常长的标记目标姓名',hp=500,max=1000,mark=1,guid='guid1'}
Banana_UpdateStatus()
assert(SRTI_Health1:IsShown()); assert(SRTI_Health1.value==500)
assert(SRTI_Health1.text:GetText()=='50%'); assert(not SRTI_Health1.name:IsShown())
BANANA_CONFIG.SHOW_SHORT_NAME=1; Banana_UpdateStatus()
assert(SRTI_Health1.name:IsShown()); assert(SRTI_Health1.name:GetStringWidth()<=SRTI_Health1:GetWidth())
assert(string.sub(SRTI_Health1.name:GetText(),-2)=='..')
units.mark1.hp=250; Banana_UpdateStatus(); assert(SRTI_Health1.value==250)
units.mark1.dead=true; Banana_UpdateStatus()
assert(SRTI_Health1.value==0); assert(SRTI_Health1.text:GetText()=='死亡')
units.mark1=nil; Banana_UpdateStatus()
assert(not SRTI_Health1:IsShown()); assert(not SRTI_Health1.name:IsShown())
units.mark2={name='B',hp=400,max=800,mark=2}; Banana_UpdateStatus()
BANANA_CONFIG.SHOW_HEALTH=0; Banana_UpdateStatus()
assert(not SRTI_Health2:IsShown()); assert(SRTI_Health2.name:IsShown())
BANANA_CONFIG.SHOW_HEALTH=1; BANANA_CONFIG.SHOW_HEALTH_PERCENT=0; Banana_UpdateStatus()
assert(SRTI_Health2:IsShown()); assert(not SRTI_Health2.text:IsShown())
units.mark2.max=0; Banana_UpdateStatus(); assert(not SRTI_Health2:IsShown())
units.mark2.max=800
BANANA_CONFIG.SHOW_SAVE_BUTTON=0; SRTI_LayoutTools(); assert(not SRTI_SaveBtn:IsShown())
assert(SRTI_ClearButton.points[1][2]==RaidTargetFrame8Button)
Banana_SetEnabled(false)
assert(BananaFrame:GetScript('OnUpdate')==nil)
assert(not SRTI_ResetButton:IsShown()); assert(not RaidTargetFrame2Button:IsShown())
Banana_SetEnabled(true); assert(not SRTI_SaveBtn:IsShown())
BANANA_CONFIG.SHOW_OUT_OF_GROUP=0; Banana_UpdateStatus()
assert(not SRTI_ResetButton:IsShown()); assert(not RaidTargetFrame2Button:IsShown())
BananaConfigFrame:Show(); assert(not SRTI_ResetButton:IsShown())
BananaConfigFrame:Hide(); assert(not RaidTargetFrame2Button:IsShown())
BANANA_CONFIG.SHOW_OUT_OF_GROUP=1; Banana_UpdateStatus()
for layout=1,5 do
 for flip=0,1 do
  BANANA_CONFIG.BUTTON_LAYOUT=layout; BANANA_CONFIG.FLIP=flip
  Banana_Layout()
  assert(SRTI_ResetButton.points[1][4]==4)
  if layout==4 then assert(math.abs(RaidTargetFrame2Button.points[1][5])>=27) end
 end
end
for _,scale in ipairs({50,100,200}) do
 BANANA_CONFIG.BUTTON_SCALE=scale; Banana_UpdateScale()
 assert(SRTI_ResetButton.scale==scale/100); assert(SRTI_SaveBtn.scale==scale/100)
end
SRTI_Option_SHOW_SAVE_BUTTON.checked=true; SRTI_Option_SHOW_SAVE_BUTTON:Fire('OnClick')
assert(BANANA_CONFIG.SHOW_SAVE_BUTTON==1); assert(SRTI_SaveBtn:IsShown())
Banana_Default(); assert(BANANA_CONFIG.SHOW_SHORT_NAME==0); assert(BANANA_CONFIG.SHOW_SAVE_BUTTON==1)
''')

# Without SuperWoW, never retarget to measure health; current target, group targets and pets work.
# The new display keeps the true fill immediate while briefly highlighting recent damage.
lua = world()
check(lua, r'''
units.mark1={name='Damage target',hp=1000,max=1000,mark=1,guid='damage1'}
Banana_UpdateStatus()
assert(SRTI_Health1:GetWidth()==44); assert(SRTI_Health1:GetHeight()==12)
assert(RaidTargetFrame1Button:GetWidth()==48)
assert(SRTI_Health1.texture=='Interface\\Buttons\\WHITE8X8')
assert(SRTI_Health1.text.points[1][1]=='BOTTOM')
assert(not SRTI_Health1.damage:IsShown())
units.mark1.hp=500; Banana_UpdateStatus()
assert(SRTI_Health1.value==500)
assert(SRTI_Health1.damage:IsShown()); assert(SRTI_Health1.damage:GetWidth()==22)
assert(SRTI_Health1:GetScript('OnUpdate'))
time=10.2; SRTI_Health1:Fire('OnUpdate',.2)
assert(SRTI_Health1.damage:GetWidth()==22)
time=10.6; SRTI_Health1:Fire('OnUpdate',.1)
assert(SRTI_Health1.damage:GetWidth()<22); assert(SRTI_Health1.damage:GetWidth()>0)
time=11; SRTI_Health1:Fire('OnUpdate',.4)
assert(not SRTI_Health1.damage:IsShown()); assert(not SRTI_Health1:GetScript('OnUpdate'))
units.mark1.hp=200; Banana_UpdateStatus(); assert(SRTI_Health1.damage:IsShown())
assert(SRTI_Health1.color[1]==.95)
units.mark1.hp=600; Banana_UpdateStatus()
assert(not SRTI_Health1.damage:IsShown()); assert(SRTI_Health1.color[2]==.9)
units.mark1.hp=300; Banana_UpdateStatus(); assert(SRTI_Health1.damage:IsShown())
units.mark1.guid='newTarget'; units.mark1.hp=100; Banana_UpdateStatus()
assert(not SRTI_Health1.damage:IsShown())
units.mark1.hp=80; Banana_UpdateStatus(); assert(SRTI_Health1.damage:IsShown())
units.mark1.max=2000; Banana_UpdateStatus(); assert(not SRTI_Health1.damage:IsShown())
units.mark1.hp=40; Banana_UpdateStatus(); assert(SRTI_Health1.damage:IsShown())
units.mark1=nil; Banana_UpdateStatus()
assert(not SRTI_Health1:IsShown()); assert(not SRTI_Health1:GetScript('OnUpdate'))
for _,width in ipairs({36,44,52}) do
 BANANA_CONFIG.HEALTH_BAR_WIDTH=width
 units.mark2={name='一个很长很长很长的中文名称',hp=500,max=1000,mark=2}
 BANANA_CONFIG.SHOW_SHORT_NAME=1
 Banana_Layout(); Banana_UpdateStatus()
 assert(SRTI_Health2:GetWidth()==width); assert(RaidTargetFrame2Button:GetWidth()==width+4)
 assert(SRTI_Health2.name:GetStringWidth()<=width)
 assert(SRTI_Health2.ticks[1].points[1][4]==width/4)
 assert(SRTI_ToolRowSpacing()>=41)
end
BANANA_CONFIG.SHOW_HEALTH_PERCENT=0; Banana_Layout(); Banana_UpdateStatus()
assert(SRTI_Health2.points[1][5]==-2); assert(not SRTI_Health2.text:IsShown())
BANANA_CONFIG.SHOW_HEALTH=0; Banana_Layout(); Banana_UpdateStatus()
assert(RaidTargetFrame2Button:GetWidth()==36); assert(not SRTI_Health2:IsShown())
assert(SRTI_Health2.name:GetStringWidth()<=32)
SRTI_HealthWidth:Fire('OnClick'); assert(BANANA_CONFIG.HEALTH_BAR_WIDTH==36)
SRTI_HealthWidth:Fire('OnClick'); assert(BANANA_CONFIG.HEALTH_BAR_WIDTH==44)
SRTI_HealthWidth:Fire('OnClick'); assert(BANANA_CONFIG.HEALTH_BAR_WIDTH==52)
''')

# Physical left/right selections survive reversed layouts, hidden tools and the hunter toggle.
lua = world()
check(lua, r'''
for layout=1,5 do
 for flip=0,1 do
  BANANA_CONFIG.BUTTON_LAYOUT=layout; BANANA_CONFIG.FLIP=flip
  SRTI_AllToolsLEFT:Fire('OnClick')
  for _,button in ipairs({SRTI_ReadyButton,SRTI_CountdownButton,SRTI_SaveBtn,SRTI_ClearButton,SRTI_ResetButton,SRTI_SettingsButton}) do
   assert(button.points[1][1]=='RIGHT'); assert(button.points[1][3]=='LEFT'); assert(button.points[1][4]==-4)
  end
  SRTI_AllToolsRIGHT:Fire('OnClick')
  for _,button in ipairs({SRTI_ReadyButton,SRTI_CountdownButton,SRTI_SaveBtn,SRTI_ClearButton,SRTI_ResetButton,SRTI_SettingsButton}) do
   assert(button.points[1][1]=='LEFT'); assert(button.points[1][3]=='RIGHT'); assert(button.points[1][4]==4)
  end
 end
end
BANANA_CONFIG.BUTTON_LAYOUT=1; BANANA_CONFIG.FLIP=0
BANANA_CONFIG.POS.RaidTargetFrame1Button={x=123,y=-456}
SRTI_Side_READY_BUTTON_SIDE:Fire('OnClick')
assert(BANANA_CONFIG.READY_BUTTON_SIDE=='LEFT')
assert(SRTI_ReadyButton.points[1][2]==RaidTargetFrame9Button)
assert(RaidTargetFrame1Button.points[1][4]==123)
assert(RaidTargetFrame1Button.points[1][5]==-456)
SRTI_Option_SHOW_HUNTER_BUTTON.checked=false; SRTI_Option_SHOW_HUNTER_BUTTON:Fire('OnClick')
assert(not RaidTargetFrame9Button:IsShown())
assert(SRTI_ReadyButton.points[1][2]==RaidTargetFrame1Button)
units.target={name='Hunter target',hp=30,max=100,debuff='Interface\\Icons\\Ability_Hunter_SniperShot'}
Banana_InvalidateSymbolCache(); Banana_UpdateStatus()
assert(not SRTI_Health9:IsShown()); assert(not RaidTargetFrame9Button:IsShown())
BananaConfigFrame:Show(); assert(not RaidTargetFrame9Button:IsShown())
BANANA_CONFIG.SHOW_OUT_OF_GROUP=0; Banana_UpdateStatus(); assert(not RaidTargetFrame9Button:IsShown())
BANANA_CONFIG.SHOW_OUT_OF_GROUP=1; BananaConfigFrame:Hide()
SRTI_Option_SHOW_HUNTER_BUTTON.checked=true; SRTI_Option_SHOW_HUNTER_BUTTON:Fire('OnClick')
assert(RaidTargetFrame9Button:IsShown()); assert(SRTI_Health9:IsShown())
assert(SRTI_ReadyButton.points[1][2]==RaidTargetFrame9Button)
SRTI_AllToolsRIGHT:Fire('OnClick')
BANANA_CONFIG.SHOW_COUNTDOWN_BUTTON=0; BANANA_CONFIG.SHOW_SAVE_BUTTON=0
Banana_Layout()
assert(SRTI_ClearButton.points[1][2]==SRTI_ReadyButton)
BANANA_CONFIG.SHOW_HUNTER_BUTTON=0; BANANA_CONFIG.RESET_BUTTON_SIDE='LEFT'
SRTI_ApplyToolDefaults()
assert(BANANA_CONFIG.SHOW_HUNTER_BUTTON==0); assert(BANANA_CONFIG.RESET_BUTTON_SIDE=='LEFT')
Banana_Default()
assert(BANANA_CONFIG.SHOW_HUNTER_BUTTON==1); assert(BANANA_CONFIG.RESET_BUTTON_SIDE=='RIGHT')
''')

lua = world(False)
check(lua, r'''
units.target={name='Target',hp=65,max=100,mark=3}; Banana_UpdateStatus()
assert(SRTI_Health3:IsShown()); assert(SRTI_Health3.value==65)
units.target=nil; partyCount=1
units.party1={name='Player'}; units.party1target={name='Enemy',hp=80,max=100,mark=4}
units.party1pet={name='Pet',hp=90,max=100,mark=5}; Banana_UpdateStatus()
assert(SRTI_Health4:IsShown()); assert(SRTI_Health5:IsShown())
raidCount=1; units.target={name='Own target in raid',hp=30,max=100,mark=6}
Banana_UpdateStatus(); assert(SRTI_Health6:IsShown())
units.target={name='Hunter target',hp=30,max=100,debuff='Interface\\Icons\\Ability_Hunter_SniperShot'}
Banana_InvalidateSymbolCache(); Banana_UpdateStatus(); assert(SRTI_Health9:IsShown())
''')

# Saved off state must survive startup; migration fills only missing keys.
lua = world(enabled=0)
check(lua, 'assert(not SRTI_SaveBtn:IsShown()); assert(not SRTI_ResetButton:IsShown()); assert(BananaFrame:GetScript("OnUpdate")==nil)')

# Recheck reset conditions at the popup acceptance, and drive the timer with elapsed time.
lua = world()
check(lua, r'''
SRTI_ResetButton:Fire('OnClick','LeftButton'); assert(popup=='SRTI_RESET_INSTANCES')
StaticPopupDialogs[popup].OnAccept(); assert(resets==1)
combat=true; StaticPopupDialogs[popup].OnAccept(); assert(resets==1); combat=false
inInstance=true; popup=nil; SRTI_ResetButton:Fire('OnClick','LeftButton'); assert(popup==nil); inInstance=false
partyCount=1; partyLeader=false; SRTI_ResetButton:Fire('OnClick','LeftButton'); assert(popup==nil)
SRTI_ReadyButton:Fire('OnClick','LeftButton'); assert(ready==nil)
partyLeader=true; SRTI_ReadyButton:Fire('OnClick','LeftButton'); assert(ready==1)
SRTI_CountdownButton:Fire('OnClick','LeftButton'); assert(table.getn(announcements)==1)
time=11.1
for _,frame in ipairs(frameObjects) do
 if frame.untilTime then frame:Fire('OnUpdate'); break end
end
assert(announcements[2][1]=='4 秒')
SRTI_CountdownButton:Fire('OnClick','RightButton'); assert(announcements[3][1]=='倒数已取消。')
SRTI_CountdownButton:Fire('OnClick','LeftButton')
time=16.2
for _,frame in ipairs(frameObjects) do
 if frame.untilTime then frame:Fire('OnUpdate'); assert(not frame.untilTime); assert(frame:GetScript('OnUpdate')==nil); break end
end
assert(announcements[5][1]=='开怪！')
SRTI_CountdownButton:Fire('OnClick','LeftButton'); Banana_SetEnabled(false)
for _,frame in ipairs(frameObjects) do assert(not frame.untilTime) end
Banana_SetEnabled(true)
units.mark1={name='Saved',hp=20,max=100,mark=1,guid='guid1'}
assert(UnitGUID==nil)
SRTI_SaveBtn:Fire('OnClick','RightButton'); assert(SRTI_MARKS['Test Dungeon'].guid1==1)
units.mark1=nil; SRTI_SaveBtn:Fire('OnClick','RightButton')
assert(SRTI_MARKS['Test Dungeon'].guid1==1)
units.guid1={name='Saved',hp=20,max=100,mark=1}
SRTI_SaveBtn:Fire('OnClick','LeftButton')
assert(messages[table.getn(messages)-1]=='mark:guid1:1')
''')

# The chatbar entry exists and has a nil-only migration for old per-character profiles.
chat = (ROOT.parent / 'S_ChatBar/ChatBar.lua').read_text(encoding='utf-8-sig')
assert 'S_ChatBarDB.buttons.SimpleRaidTargetIcons == nil' in chat
assert 'CreateChatButton("SimpleRaidTargetIcons", "标"' in chat
assert 'CreateChatButton("AutoMarker", "自"' in chat

# Execute the whole chatbar with an old profile and exercise its new entry.
lua = world()
lua.execute(r'''
ChatFrame3=CreateFrame('Frame','ChatFrame3',UIParent)
C_Timer={After=function(delay,callback) callback() end}
function IsAddOnLoaded(name) return name=='SimpleRaidTargetIcons' end
function GetBuildInfo() return '1.12.1','7000' end
function print(...) end
S_ChatBarDB={buttons={Say=true,AutoMarker=false},displayMode='text'}
''')
lua.execute(chat)
check(lua, r'''
chatbar:Fire('OnEvent')
assert(S_ChatBarDB.buttons.SimpleRaidTargetIcons==true)
assert(ChannelSimpleRaidTargetIcons:IsShown())
assert(ChannelSimpleRaidTargetIcons.text:GetText()=='标')
BananaConfigFrame:Hide(); ChannelSimpleRaidTargetIcons:Fire('OnClick','LeftButton')
assert(BananaConfigFrame:IsShown())
ChannelSimpleRaidTargetIcons:Fire('OnClick','LeftButton'); assert(not BananaConfigFrame:IsShown())
S_ChatBarDB.buttons.SimpleRaidTargetIcons=false; chatbar:Fire('OnEvent')
assert(not ChannelSimpleRaidTargetIcons:IsShown())
SlashCmdList.SCBMODE(); assert(ChannelSimpleRaidTargetIcons.text:IsShown()==false)
assert(ChannelSimpleRaidTargetIcons.t:IsShown())
Banana_Toggle=nil; ChannelSimpleRaidTargetIcons:Fire('OnClick','LeftButton')
assert(string.find(messages[table.getn(messages)],'SimpleRaidTargetIcons'))
''')
print('PASS: Lua/XML, startup, health/death/disappearance, damage hold/decay/reset, width/spacing/name clipping, per-tool and bulk sides across five layouts, hunter visibility and docking, dragged position preservation, group/scale/permissions/countdown/save/restore/chatbar regressions.')
