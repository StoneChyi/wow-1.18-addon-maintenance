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
  local text = self:GetText():gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('||', '|')
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
