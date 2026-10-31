"""Regression harness for pfUI chatcopy; requires lupa (Lua 5.1 backend)."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'CodexReports/chatcopy-test-deps'))
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[2]
source = (root / 'Interface/AddOns/pfUI/modules/chatcopy.lua').read_text(encoding='utf-8-sig')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('assert(loadstring(...))', source)
lua.execute(r'''
frames = {}
local methods = {}
function fire(frame, script, value)
  local oldThis, oldArg = this, arg1
  this, arg1 = frame, value
  if frame.scripts[script] then frame.scripts[script]() end
  this, arg1 = oldThis, oldArg
end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterAllEvents() self.events = {} end
function methods:SetWidth(v) self.width = v end
function methods:SetHeight(v) self.height = v end
function methods:GetWidth() return self.width or 640 end
function methods:GetHeight() return self.height or 332 end
function methods:GetLeft() return 0 end
function methods:GetTop() return 500 + (self.scrollParent and self.scrollParent.scroll or 0) end
function methods:GetBottom() return self:GetTop() - self:GetHeight() end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) self.level = v end
function methods:SetFontObject(v)
  if type(v) == 'string' then v = _G[v] end
  assert(type(v) == 'table' and v.font, 'invalid font object')
  self.font, self.size = v.font, v.size
end
function methods:SetFont(font, size, flags)
  if rejectConfiguredFonts or type(font) ~= 'string' or type(size) ~= 'number' or size <= 0 then return nil end
  self.font, self.size, self.flags = font, size, flags; return 1
end
function methods:GetFont() return self.font or 'test-font', self.size or 14, self.flags end
function methods:SetText(v)
  assert(self.kind ~= 'FontString' or self.font, 'SetText(): Font not set')
  self.text = v
end
function methods:GetText() return self.text or '' end
function methods:GetStringWidth()
  -- A client renders escaped pipes literally before interpreting markup.
  -- Protect them here too, or measuring ||c11223344 would give zero width
  -- to real visible characters and invalidate the drag-coordinate oracle.
  local text = self:GetText():gsub('||', '\1'):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('\1', '|')
  local width = 0
  for c in text:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    width = width + (#c > 1 and 14 or c == ' ' and 4 or 7)
  end
  return width
end
function methods:SetAlpha(v) self.alpha = v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:Show()
  local was = self.shown
  self.shown = true
  if was == false then fire(self, 'OnShow') end
end
function methods:Hide()
  local was = self.shown
  self.shown = false
  if was ~= false then fire(self, 'OnHide') end
end
function methods:IsShown() return self.shown ~= false end
methods.IsVisible = methods.IsShown
function methods:GetID() return self.id or 1 end
function methods:GetName() return self.name end
function methods:SetScrollChild(child) self.child = child; child.scrollParent = self end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(v) self.scroll = v end
function methods:GetVerticalScrollRange() return math.max(0, (self.child and self.child:GetHeight() or 0)-332) end
function methods:Scroll(v) self.scroll = math.max(0, math.min(self:GetVerticalScrollRange(), (self.scroll or 0)-v)) end
function methods:SetFocus() self.focus = true end
function methods:ClearFocus() self.focus = false end
function methods:HighlightText(a, b) self.highlight = {a, b} end
function methods:AddMessage(s) self.messages = self.messages or {}; table.insert(self.messages, s) end
local noop = function() end
for _, name in ipairs({'SetPoint','ClearAllPoints','SetAllPoints','SetJustifyH','SetJustifyV',
  'SetTextColor','SetTexture','SetBackdropColor','SetBackdropBorderColor','SetFrameStrata',
  'SetClampedToScreen','EnableMouse','SetMovable','RegisterForDrag','EnableMouseWheel',
  'SetMultiLine','SetAutoFocus','SetMaxLetters','RegisterForClicks','UpdateScrollState',
  'UpdateScrollChildRect'}) do methods[name] = noop end
function CreateFrame(kind, name, parent)
  local f = setmetatable({kind=kind, name=name, parent=parent, scripts={}, events={}, shown=true}, {__index=methods})
  table.insert(frames, f)
  if name then _G[name] = f end
  return f
end
function methods:CreateFontString(name, layer, template)
  local f = CreateFrame('FontString', name, self)
  if template then f:SetFontObject(template) end
  return f
end
function methods:CreateTexture() return CreateFrame('Texture', nil, self) end
CreateScrollFrame = function(name, parent) return CreateFrame('ScrollFrame', name, parent) end
CreateBackdrop = function(frame) frame.backdrop = CreateFrame('Backdrop', nil, frame) end
UIParent = CreateFrame('Frame', 'UIParent')
ChatFontNormal = {font='test-font', size=14}
GameFontNormal = ChatFontNormal;GameFontNormalSmall = ChatFontNormal
assert(not pcall(function() CreateFrame('FontString'):SetText('invalid') end))
rejectConfiguredFonts=true -- exercise unavailable configured-font paths
ChatFrame1 = CreateFrame('ChatFrame', 'ChatFrame1', UIParent)
ChatFrame1.id = 1
ChatFrame2 = CreateFrame('ChatFrame', 'ChatFrame2', UIParent)
ChatFrame2.id = 2
NUM_CHAT_WINDOWS = 2
DEFAULT_CHAT_FRAME = ChatFrame1
SELECTED_CHAT_FRAME = ChatFrame1
SlashCmdList = {}
T = setmetatable({}, {__index=function(_, key) return key end})
pfUI = {api={}, RegisterModule=function(_, name, version, fn) fn() end}
pfUI_config = {chat={text={}}}
function strsplit() return nil end
date = function() return '12:34:56' end
GetLocale = function() return 'zhCN' end
GetChatWindowInfo = function(id) return 'Chat '..id end
GetNumRaidMembers = function() return raidCount or 0 end
IsShiftKeyDown = function() return shiftDown or false end
GetCursorPosition = function() return cursorX or 0, cursorY or 500 end
function dispatch(name, message, sender)
  for _, f in ipairs(frames) do
    if f.events[name] then
      event, arg1, arg2, this = name, message, sender, f
      f.scripts.OnEvent()
    end
  end
end
''')
lua.execute(source.replace('pcall(Fill)', 'Fill()'))
lua.execute(r'''
dispatch('PLAYER_ENTERING_WORLD')
raidCount = 20
pfUI_cache.chatcopy.time = '0'
pfUI_cache.chatcopy.class = '0'
ChatFrame1:AddMessage('团队指挥YY：123 456，进语音集合', 1, 1, 1)
ChatFrame1:AddMessage('|cff00ff00这是一条中文消息：只复制中间这部分|r', 1, 1, 1)
ChatFrame1:AddMessage(string.rep('长消息 abc 123 ', 20), 1, 1, 1)
SlashCmdList.PFCHATCOPY('show')
local w = pfChatCopyWindow
assert(w and w.lineCount == 3, tostring(w and w.lineCount))
assert(w.mirror == true, 'visible mirror must stay active')
local realRange = w.scroll.GetVerticalScrollRange
w.scroll.GetVerticalScrollRange = function() return 999 end
SlashCmdList.PFCHATCOPY('show')
assert(w.scroll:GetVerticalScroll() == 0, 'opening must not use a stale scroll range')
w.scroll.GetVerticalScrollRange = realRange

assert(table.concat(w.characters) == '团队指挥YY：123 456，进语音集合\n这是一条中文消息：只复制中间这部分\n'..string.rep('长消息 abc 123 ', 20))
assert(#w.rows > 3, 'long message must wrap')
for _, row in ipairs(w.rows) do assert(row.x[#row.x] <= 566) end
local rows = #w.rows
fire(w, 'OnUpdate')
fire(w, 'OnUpdate')
assert(#w.rows == rows)
local row = w.rows[2]
w.scroll:SetVerticalScroll(0)
cursorX, cursorY = row.x[11], w.content:GetTop()-row.y-3
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
cursorX = row.x[17]
fire(w, 'OnUpdate', 0.04)
fire(w.hits[2], 'OnMouseUp', 'LeftButton')
assert(w:SelectedText() == '复制中间这部', w:SelectedText())
assert(w.edit:GetText() == '复制中间这部')
assert(w.edit.focus and w.edit.alpha == 0 and w.fsFrame:IsShown())
local direct
SetClipboardText = function(text) direct = text end
fire(w.btnCopySel, 'OnClick')
assert(direct == '复制中间这部')
cursorX, cursorY = row.x[17], w.content:GetTop()-row.y-3
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
local first = w.rows[1]
cursorX, cursorY = 0, w.content:GetTop()-first.y-3
fire(w, 'OnUpdate', 0.04)
fire(w.hits[2], 'OnMouseUp', 'LeftButton')
assert(string.find(w:SelectedText(), '\n') ~= nil)
assert(w.fsFrame:IsShown())
fire(w.btnClearSel, 'OnClick')
cursorX, cursorY = 0, w.content:GetTop()-first.y-3
fire(w.hits[1], 'OnMouseDown', 'LeftButton')
fire(w.hits[1], 'OnMouseUp', 'LeftButton')
assert(not w:SelectedText(), 'single click must not select a complete message')
assert(not w.edit.focus and w.textStart == nil)
direct = 'unchanged'
fire(w.btnCopySel, 'OnClick')
assert(direct == 'unchanged', 'copy without a drag must not copy a message')
shiftDown = true
cursorX, cursorY = row.x[11], w.content:GetTop()-row.y-3
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
fire(w.hits[2], 'OnMouseUp', 'LeftButton')
assert(not w:SelectedText(), 'Shift-click without a text anchor must not select whole messages')
shiftDown = false
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
cursorX = row.x[14]
fire(w, 'OnUpdate', 0.04)
fire(w.hits[2], 'OnMouseUp', 'LeftButton')
assert(w:SelectedText() == '复制中')
shiftDown = true
cursorX = row.x[17]
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
fire(w.hits[2], 'OnMouseUp', 'LeftButton')
assert(w:SelectedText() == '复制中间这部', 'Shift-click should extend the character selection')
shiftDown = false
fire(w.btnClearSel, 'OnClick')
assert(not w.edit.focus and w.textStart == nil)
fire(w.btnCopy, 'OnClick')
assert(direct == w:Text(), 'explicit Copy All button should still work')
local cases = {
  {'YY123456', '123456'}, {'yy：123 456', '123456'}, {'YY频道号: 001 234', '001234'},
  {'来YY语音频道：987 654 集合', '987654'}, {'YY 123　456', '123456'},
  {'YY: 12\t34 56', '123456'}, {'YY:123 123 123', '123123123'}, {'yy等会再说，123456', nil},
  {'happyYY12345', nil}, {'YY 晚上8点集合', nil}, {'YY123456，40人集合', '123456'},
  {'先yy聊天，然后 YY=654 321', '654321'},
}
for _, case in ipairs(cases) do
  raidCount = 0; dispatch('RAID_ROSTER_UPDATE'); raidCount = 20
  dispatch('CHAT_MSG_RAID', case[1], '团长')
  assert(w.btnYY.label:GetText() == (case[2] and 'YY: '..case[2] or 'No raid YY'), case[1]..' -> '..w.btnYY.label:GetText())
end
dispatch('CHAT_MSG_RAID_WARNING', 'YY:123 456', '团长')
dispatch('CHAT_MSG_CHANNEL', 'YY:999999', '广告')
assert(w.btnYY.label:GetText() == 'YY: 123456')
fire(w.btnYY, 'OnClick')
assert(direct == '123456')
SetClipboardText = nil
SlashCmdList.PFYY()
assert(w.edit:GetText() == '123456' and w.edit.focus)
assert(w.edit.alpha == 0 and w.fsFrame:IsShown())
raidCount = 0; dispatch('RAID_ROSTER_UPDATE')
assert(w.btnYY.label:GetText() == 'No raid YY')
SELECTED_CHAT_FRAME = ChatFrame2
SlashCmdList.PFCHATCOPY('show')
assert(w.lineCount == 0 and w:Text() == '' and not w:SelectedText())
assert(w.edit:GetText() == '')
-- Preserve hyperlink labels, literal pipes, emoji and explicit newlines without copying markup.
ChatFrame2:AddMessage('|Hplayer:小明|h[小明]|h: a||b 😀\n下一行')
SlashCmdList.PFCHATCOPY('show')
assert(table.concat(w.characters) == '[小明]: a|b 😀\n下一行')
local cached = w.hits[1].textLayout
assert(cached and #cached.rows == 2)
dispatch('CHAT_MSG_RAID_LEADER', 'YY频道：001 234', '队长')
assert(w.btnYY.label:GetText() == 'YY: 001234')
-- A font that is not ready on the first frame must not poison the layout cache.
local normalWidth = w.measure.GetStringWidth
w.measure.GetStringWidth = function() return 0 end
ChatFrame2:AddMessage('首帧字体测试')
SlashCmdList.PFCHATCOPY('show')
assert(w.hits[2].textLayout == nil)
w.measure.GetStringWidth = normalWidth
SlashCmdList.PFCHATCOPY('show')
assert(w.hits[2].textLayout ~= nil)
local last = w.rows[#w.rows]
cursorX, cursorY = 0, w.content:GetTop()-last.y-3
fire(w.hits[2], 'OnMouseDown', 'LeftButton')
fire(w.hits[2], 'OnDragStart')
cursorX = last.x[3]
fire(w.hits[2], 'OnDragStop')
assert(w:SelectedText() == '首帧')
assert(not w.drag and w.edit.focus)
''')
print('PASS: Lua syntax; UTF-8, reverse and cross-message drag; wrapping/cache; clicks never select a message; Shift-click extends text; Copy All; clipboard/Ctrl+C; 12 YY formats; channel isolation/raid cleanup; empty windows; hyperlink/pipe/emoji/newline handling; first-frame font recovery; captured drag release')

# These scenarios run the complete existing module and its real controls.
# Expected display strings are independent fixtures, not calls to Strip or
# Characters. The font mock still rejects uninitialized text and configured
# SetFont remains forced to fail throughout all scenarios.
lua.execute(r'''
local w=pfChatCopyWindow
local scenarios={}
local function Scenario(name,fn)
  fn()
  table.insert(scenarios,name)
end
local function RGB(enabled)
  pfUI.api.rgbhex=enabled and function(r,g,b)
    return string.format('|cff%02x%02x%02x',math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5))
  end or nil
end
local function OpenLines(format,messages,rgbMode)
  SELECTED_CHAT_FRAME=ChatFrame2
  -- Capture holds this original table in a closure: clear it in place.
  while #ChatFrame2.pfHistory>0 do table.remove(ChatFrame2.pfHistory) end
  pfUI_cache.chatcopy.time='0';pfUI_cache.chatcopy.class='0'
  RGB(rgbMode>0)
  for _,message in ipairs(messages) do
    if rgbMode==2 then ChatFrame2:AddMessage(message,.8,.7,.6)
    else ChatFrame2:AddMessage(message) end
  end
  SlashCmdList.PFCHATCOPY('format '..format)
  SlashCmdList.PFCHATCOPY('show')
  assert(w.mirror and w.fsFrame:IsShown(),'real visible text mirror disappeared')
  assert(rejectConfiguredFonts,'configured-font failure coverage disabled')
end
local function Visible() return table.concat(w.characters) end
local function CopyAll(expected)
  local direct
  SetClipboardText=function(text) direct=text end
  fire(w.btnCopy,'OnClick')
  assert(direct==expected,'direct Copy All mismatch: '..tostring(direct))
  SetClipboardText=nil
  fire(w.btnCopy,'OnClick')
  assert(w.edit:GetText()==expected,'Ctrl+C Copy All mismatch')
  assert(w.edit.focus and w.edit.alpha==0 and w.fsFrame:IsShown(),'Ctrl+C fallback changed visible selection mode')
end
local function Utf8(value)
  local out={}
  for char in string.gmatch(value,'[%z\1-\127\194-\244][\128-\191]*') do table.insert(out,char) end
  return out
end
local function CursorBoundary(boundary)
  for _,row in ipairs(w.rows) do
    if boundary>=row.first-1 and boundary<=row.last then
      local cell=boundary-(row.first-1)+1
      cursorX=row.x[cell]
      cursorY=w.content:GetTop()-row.y-3
      return row.owner
    end
  end
  error('missing real layout boundary '..boundary)
end
local function Drag(first,last,expected)
  w.scroll:SetVerticalScroll(0)
  local owner=CursorBoundary(first-1)
  fire(owner,'OnMouseDown','LeftButton')
  CursorBoundary(last)
  fire(w,'OnUpdate',.04)
  owner=CursorBoundary(last)
  fire(owner,'OnMouseUp','LeftButton')
  assert(w:SelectedText()==expected,'precise character drag mismatch: '..tostring(w:SelectedText()))
  assert(w.edit:GetText()==expected,'drag Ctrl+C buffer mismatch')
  assert(w.edit.focus and w.edit.alpha==0 and w.fsFrame:IsShown())
  local direct
  SetClipboardText=function(text) direct=text end
  fire(w.btnCopySel,'OnClick')
  assert(direct==expected,'direct selected-copy mismatch')
  SetClipboardText=nil
  fire(w.btnCopySel,'OnClick')
  assert(w.edit:GetText()==expected and w.edit.focus,'selected Ctrl+C fallback mismatch')
end

Scenario('literal pipe markers stay visible and export once',function()
  local encoded='字面 ||c11223344 ||r ||Hplayer:假人||h[假名]||h ||T假贴图||t 普通|||| 单独| 结束'
  local expected='字面 |c11223344 |r |Hplayer:假人|h[假名]|h |T假贴图|t 普通|| 单独| 结束'
  for mode=0,2 do
    OpenLines('plain',{encoded},mode)
    assert(Visible()==expected,'literal markers lost from actual visible characters (RGB mode '..mode..'): '..Visible())
    assert(w:Text()==expected,'plain export differs from actual displayed text')
    assert(w.lineText[1]==string.gsub(expected,'|','||'),'lineText must remain display-safe')
    CopyAll(expected)
  end
end)

Scenario('real colors links textures preserve UTF8 labels and newlines',function()
  local encoded='|cffaabbcc中文😀|r |Hitem:123:0:0:0|h[治疗药水]|h |Hplayer:小明|h[小明]|h |TInterface\\Icons\\INV_Misc:16|t末尾\n第二行🙂'
  local expected='中文😀 [治疗药水] [小明] 末尾\n第二行🙂'
  for mode=0,2 do
    OpenLines('plain',{encoded},mode)
    assert(Visible()==expected,'real markup not removed while preserving its labels')
    assert(w:Text()==expected)
    CopyAll(expected)
  end
end)

Scenario('channel reset parity preserves escaped pipes in both formats',function()
  local encoded='真|r 双||r 四||||r 三|||r 终'
  local expected='真 双|r 四||r 三| 终'
  for mode=0,2 do
    for _,format in ipairs({'all','plain'}) do
      OpenLines(format,{encoded},mode)
      assert(Visible()==expected,'channel capture damaged literal reset pipes ('..format..' RGB '..mode..'): '..Visible())
      if format=='plain' then assert(w:Text()==expected);CopyAll(expected) end
    end
  end
end)

Scenario('all plain all roundtrip retains original rich history',function()
  local encoded='|cff00ff00颜色|r ||c11223344 ||r |||| |Hitem:55|h[物品]|h\n中文😀'
  local expected='颜色 |c11223344 |r || [物品]\n中文😀'
  for mode=0,2 do
    OpenLines('all',{encoded},mode)
    local original=w:Text();local originalHistory=ChatFrame2.pfHistory[1].txt
    assert(Visible()==expected)
    CopyAll(original)
    SlashCmdList.PFCHATCOPY('format plain')
    assert(Visible()==expected and w:Text()==expected)
    CopyAll(expected)
    SlashCmdList.PFCHATCOPY('format all')
    assert(Visible()==expected and w:Text()==original,'rich format was changed by roundtrip')
    assert(ChatFrame2.pfHistory[1].txt==originalHistory,'format conversion modified captured history')
    CopyAll(original)
  end
end)

Scenario('long cross-line character selection copies literal markers exactly',function()
  local encoded1='|cff00ff00起点|r：'..string.rep('中文||c11223344😀||r ',20)..'\n中间|Hplayer:小明|h[角色]|h'
  local encoded2='尾段：||T字面贴图||t 与 |TInterface\\Icons\\INV_Misc:16|t终点'
  local expected='起点：'..string.rep('中文|c11223344😀|r ',20)..'\n中间[角色]\n尾段：|T字面贴图|t 与 终点'
  local characters=Utf8(expected)
  local first,last=4,#characters-3
  local subset=table.concat(characters,'',first,last)
  for mode=0,2 do
    for _,format in ipairs({'all','plain'}) do
      OpenLines(format,{encoded1,encoded2},mode)
      assert(Visible()==expected,'long visible text differs before selection')
      assert(#w.rows>5,'long fixture must exercise wrapped visual lines')
      Drag(first,last,subset)
      assert(string.find(subset,'\n',1,true) and string.find(subset,'|c11223344',1,true),'fixture lost intended boundaries')
      if format=='plain' then assert(w:Text()==expected);CopyAll(expected) end
    end
  end
end)

local yyCases={
 {'YY123456','123456'},{'yy：123 456','123456'},{'YY频道号: 001 234','001234'},
 {'来YY语音频道：987 654 集合','987654'},{'YY 123　456','123456'},
 {'YY: 12\t34 56','123456'},{'YY:123 123 123','123123123'},{'yy等会再说，123456',nil},
 {'happyYY12345',nil},{'YY 晚上8点集合',nil},{'YY123456，40人集合','123456'},
 {'先yy聊天，然后 YY=654 321','654321'},
}
for _,format in ipairs({'all','plain'}) do
  Scenario('YY formats source isolation and raid cleanup in '..format,function()
    OpenLines(format,{'团队资料'},2)
    for _,case in ipairs(yyCases) do
      raidCount=0;dispatch('RAID_ROSTER_UPDATE');raidCount=20
      dispatch('CHAT_MSG_RAID',case[1],'团长')
      assert(w.btnYY.label:GetText()==(case[2] and 'YY: '..case[2] or 'No raid YY'),format..' YY '..case[1])
    end
    dispatch('CHAT_MSG_RAID_LEADER','YY:001 234','队长')
    dispatch('CHAT_MSG_CHANNEL','YY:999999','广告')
    dispatch('CHAT_MSG_GUILD','YY:888888','广告')
    assert(w.btnYY.label:GetText()=='YY: 001234','non-raid source overwrote YY')
    local copied
    SetClipboardText=function(text) copied=text end
    fire(w.btnYY,'OnClick');assert(copied=='001234')
    SetClipboardText=nil;SlashCmdList.PFYY()
    assert(w.edit:GetText()=='001234' and w.edit.focus and w.edit.alpha==0)
    raidCount=0;dispatch('RAID_ROSTER_UPDATE')
    assert(w.btnYY.label:GetText()=='No raid YY')
    copied='unchanged';SetClipboardText=function(text) copied=text end
    SlashCmdList.PFYY();assert(copied=='unchanged','leaving raid retained a stale YY target')
    SetClipboardText=nil
  end)
end
assert(#scenarios==7)
print('PASS: 7 complete-window plain/all scenarios; literal-pipe/reset RGB matrix; real markup labels; roundtrip; long UTF8/emoji/wrapped/cross-message drag; direct and Ctrl+C copy; 24 YY format checks plus source isolation and raid cleanup')
''')

# The second maintenance step only checks the fallback EditBox buffer. These
# are per-instance engine faults; no clipboard contents are read or modified.
lua.execute(r'''
local w=pfChatCopyWindow
local rawSetText,rawGetText=w.edit.SetText,w.edit.GetText
local rawMeta=getmetatable(w.edit)
local incomplete='Copy buffer incomplete: select less text and retry'
local differs='Copy buffer differs: select again and retry'
local scenarios={}
local function Restore()
  setmetatable(w.edit,rawMeta)
  w.edit.SetText=nil;w.edit.GetText=nil
  SetClipboardText=nil
end
local function Scenario(name,fn)
  Restore();fn();Restore();table.insert(scenarios,name)
end
local function Warning(key)
  assert(string.find(w.count:GetText(),key,1,true),'missing integrity warning '..key..': '..w.count:GetText())
end
local function NoWarning()
  assert(not string.find(w.count:GetText(),'Copy buffer',1,true),'stale or false integrity warning: '..w.count:GetText())
end
local function OpenText(text)
  Restore()
  SELECTED_CHAT_FRAME=ChatFrame2
  while #ChatFrame2.pfHistory>0 do table.remove(ChatFrame2.pfHistory) end
  pfUI_cache.chatcopy.time='0';pfUI_cache.chatcopy.class='0'
  ChatFrame2:AddMessage(text)
  SlashCmdList.PFCHATCOPY('format plain');SlashCmdList.PFCHATCOPY('show')
  assert(w:Text()==text and table.concat(w.characters)==text,'integrity fixture display differs before copy')
end
local function Truncate(bytes)
  w.edit.SetText=function(self,text) rawSetText(self,string.sub(text,1,bytes)) end
end
local function FallbackState(original)
  assert(w.copyOriginal==original,'complete original was lost to fallback buffer')
  assert(w.edit.focus and w.edit.alpha==0 and w.fsFrame:IsShown(),'fallback focus/visible mirror changed')
  assert(w.edit.highlight and w.edit.highlight[1]==0,'fallback text was not selected')
end
local longText='起点中文🙂 '..string.rep('长复制内容 abc 0123456789 ',200)..'\n末行中文完成'

Scenario('Copy All detects strict prefix and interrupted UTF8 bytes',function()
  local text='A中文🙂 '..longText
  OpenText(text)
  for _,limit in ipairs({0,5,12,math.floor(string.len(text)/2)}) do
    Truncate(limit)
    fire(w.btnCopy,'OnClick')
    Warning(incomplete);FallbackState(text)
    assert(rawGetText(w.edit)==string.sub(text,1,limit),'engine truncation fixture did not apply')
    assert(w:Text()==text and table.concat(w.characters)==text,'truncation altered visible history')
  end
  Restore();fire(w.btnCopy,'OnClick');NoWarning();FallbackState(text)
  assert(rawGetText(w.edit)==text and string.find(w.count:GetText(),'Selected: press Ctrl+C',1,true))
end)

Scenario('nonprefix equal shorter and longer readbacks are differences',function()
  local text='完整中文 buffer 123456'
  OpenText(text)
  for _,replacement in ipairs({string.rep('X',string.len(text)),text..'extra','not-a-prefix'}) do
    w.edit.GetText=function() return replacement end
    fire(w.btnCopy,'OnClick')
    Warning(differs);FallbackState(text)
    assert(not string.find(w.count:GetText(),incomplete,1,true),'different data misclassified as a prefix')
  end
  Restore();fire(w.btnCopy,'OnClick');NoWarning();FallbackState(text)
end)

Scenario('long complete and CRLF CR normalization are accepted',function()
  OpenText(longText)
  fire(w.btnCopy,'OnClick');NoWarning();FallbackState(longText)
  assert(rawGetText(w.edit)==longText and string.len(longText)>4096,'long complete fixture is too short')
  local variants={
    {'第一行\r\n第二行\r第三行\n结束','第一行\n第二行\n第三行\n结束'},
    {'第一行\n第二行\n结束','第一行\r\n第二行\r结束'},
  }
  for _,pair in ipairs(variants) do
    OpenText(pair[1]);w.edit.GetText=function() return pair[2] end
    fire(w.btnCopy,'OnClick');NoWarning();FallbackState(pair[1])
  end
end)

Scenario('missing throwing and nonstring GetText never claim truncation',function()
  local text='完整待复制中文'
  for _,mode in ipairs({'missing','throw','number','nil'}) do
    OpenText(text)
    if mode=='missing' then
      setmetatable(w.edit,{__index=function(frame,key)
        if key=='GetText' then return nil end
        return rawMeta.__index[key]
      end})
    elseif mode=='throw' then w.edit.GetText=function() error('readback unavailable') end
    elseif mode=='number' then w.edit.GetText=function() return 17 end
    else w.edit.GetText=function() return nil end end
    fire(w.btnCopy,'OnClick');NoWarning();FallbackState(text)
    assert(string.find(w.count:GetText(),'Selected: press Ctrl+C',1,true),'unknown readback suppressed normal guidance')
  end
end)

Scenario('direct clipboard success bypasses buffer and errors fall back',function()
  local text='直接复制中文🙂'
  OpenText(text);w.edit:ClearFocus()
  local writes,reads,received=0,0
  w.edit.SetText=function() writes=writes+1;error('direct copy touched fallback SetText') end
  w.edit.GetText=function() reads=reads+1;error('direct copy touched fallback GetText') end
  SetClipboardText=function(value) received=value end
  fire(w.btnCopy,'OnClick')
  assert(received==text and writes==0 and reads==0 and not w.edit.focus,'direct clipboard lost priority')
  NoWarning();assert(string.find(w.count:GetText(),'Copied',1,true))
  -- Preserve existing pcall semantics: an API returning false without throwing
  -- is still treated as a completed API call, with no buffer fallback.
  SetClipboardText=function(value) received=value;return false end
  fire(w.btnCopy,'OnClick');assert(writes==0 and reads==0);NoWarning()
  Restore();local attempts=0;Truncate(3)
  SetClipboardText=function() attempts=attempts+1;error('clipboard extension unavailable') end
  fire(w.btnCopy,'OnClick')
  assert(attempts==1);Warning(incomplete);FallbackState(text)
end)

local function CursorBoundary(boundary)
  for _,row in ipairs(w.rows) do
    if boundary>=row.first-1 and boundary<=row.last then
      cursorX=row.x[boundary-row.first+2]
      cursorY=w.content:GetTop()-row.y-3
      return row.owner
    end
  end
  error('missing drag boundary '..boundary)
end
local function Drag(first,last)
  w.scroll:SetVerticalScroll(0)
  local owner=CursorBoundary(first-1)
  fire(owner,'OnMouseDown','LeftButton');CursorBoundary(last)
  fire(w,'OnUpdate',.04);owner=CursorBoundary(last)
  fire(owner,'OnMouseUp','LeftButton')
end
Scenario('drag and selected-copy preserve original and never autocopy',function()
  OpenText(longText)
  local characters={}
  for char in string.gmatch(longText,'[%z\1-\127\194-\244][\128-\191]*') do table.insert(characters,char) end
  local first,last=4,#characters-2
  local selected=table.concat(characters,'',first,last)
  local calls=0
  SetClipboardText=function() calls=calls+1 end
  Truncate(5);Drag(first,last)
  assert(calls==0,'mouse drag unexpectedly copied to the system clipboard')
  assert(w:SelectedText()==selected and w:Text()==longText)
  Warning(incomplete);FallbackState(selected)
  local direct
  SetClipboardText=function(text) direct=text end
  fire(w.btnCopySel,'OnClick');assert(direct==selected);NoWarning()
  Restore();w.edit.GetText=function() return 'changed selection' end
  fire(w.btnCopySel,'OnClick');Warning(differs);FallbackState(selected)
  Restore();fire(w.btnCopySel,'OnClick');NoWarning();FallbackState(selected)
  assert(rawGetText(w.edit)==selected)
  -- A fresh, fully accepted drag replaces the earlier warning naturally.
  Drag(first,last);NoWarning();FallbackState(selected)
  assert(string.find(w.count:GetText(),'Text selected: Ctrl+C or Copy Selected',1,true))
end)

Scenario('YY button and slash use same fallback checks and recover',function()
  OpenText('YY完整性检查')
  raidCount=20;dispatch('CHAT_MSG_RAID','YY频道：001 234 567','团长')
  assert(w.btnYY.label:GetText()=='YY: 001234567')
  Truncate(3);fire(w.btnYY,'OnClick');Warning(incomplete);FallbackState('001234567')
  Restore();w.edit.GetText=function() return 'X01234567' end
  SlashCmdList.PFYY();Warning(differs);FallbackState('001234567')
  Restore();SlashCmdList.PFYY();NoWarning();FallbackState('001234567')
  assert(rawGetText(w.edit)=='001234567')
  local copied
  SetClipboardText=function(text) copied=text end
  fire(w.btnYY,'OnClick');assert(copied=='001234567');NoWarning()
  raidCount=0;dispatch('RAID_ROSTER_UPDATE');Restore()
end)

assert(#scenarios==7)
print('PASS: 7 fallback-buffer integrity scenarios; UTF8-byte prefix truncation; differing readback; newline normalization; missing/throwing/nonstring GetText; full long text; clipboard priority/error fallback; precise drag/selected/YY original retention, focus and warning recovery')
''')
