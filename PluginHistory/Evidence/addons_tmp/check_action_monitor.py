from pathlib import Path
import re
import sys

sys.path.insert(0, 'E:/1.18/addons_tmp/bcs-test-runtime')
from lupa.lua51 import LuaRuntime

root = Path('E:/1.18/Interface/AddOns/pfUI')
lua = LuaRuntime(unpack_returned_tuples=True)
for relative in ['modules/actionbar.lua', 'modules/gui.lua', 'api/config.lua', 'env/translations_zhCN.lua']:
    lua.compile((root / relative).read_text(encoding='utf-8'))
print('PASS: Lua syntax for all four changed files')

lua.execute(r'''
getn = table.getn
T = setmetatable({}, {__index = function(_, key) return key end})
now, shift, alt, used = 0, false, false, {}
function invoke(frame, eventName, button)
  local oldThis, oldArg = this, arg1
  this, arg1 = frame, button
  if frame.scripts[eventName] then frame.scripts[eventName]() end
  this, arg1 = oldThis, oldArg
end
local function region(name, parent)
  local r = {name = name, parent = parent, shown = true, scripts = {}, alpha = 1, width = 36, height = 36}
  function r:GetName() return self.name end
  function r:GetParent() return self.parent end
  function r:SetScript(name, callback) self.scripts[name] = callback end
  function r:GetScript(name) return self.scripts[name] end
  function r:Show() self.shown = true end
  function r:Hide()
    local shown = self.shown
    self.shown = false
    if shown then invoke(self, 'OnHide') end
  end
  function r:IsShown() return self.shown end
  function r:SetAlpha(value) self.alpha = value end
  function r:GetAlpha() return self.alpha end
  function r:SetWidth(value) self.width = value end
  function r:SetHeight(value) self.height = value end
  function r:GetWidth() return self.width end
  function r:GetHeight() return self.height end
  function r:SetPoint(...) self.point = {...} end
  function r:ClearAllPoints() self.point = nil end
  function r:SetAllPoints(frame) self.allPoints = frame end
  function r:SetTexture(value) self.texture = value end
  function r:SetText(value) self.text = value end
  function r:GetText() return self.text or '' end
  function r:SetChecked(value) self.checked = value end
  function r:SetVertexColor(...) self.color = {...} end
  function r:SetTextColor(...) self.color = {...} end
  function r:SetBackdropBorderColor(...) self.borderColor = {...} end
  function r:RegisterForClicks(...) self.clicks = {...} end
  function r:RegisterForDrag(...) self.drags = {...} end
  function r:RegisterEvent(name) self.events = self.events or {}; self.events[name] = true end
  function r:GetEffectiveScale() return .8 end
  function r:CreateTexture(...) return region(nil, self) end
  function r:CreateFontString(...) return region(nil, self) end
  for _, name in ipairs({'SetFont','SetTexCoord','SetJustifyH','SetJustifyV',
    'SetBackdrop','SetFrameStrata','EnableMouse','SetNonSpaceWrap'}) do
    r[name] = function() end
  end
  return r
end
function CreateFrame(kind, name, parent) return region(name, parent) end
UIParent = region('UIParent')
GameTooltip = region('GameTooltip')
GameTooltip.lines, GameTooltip.showCalls = {}, 0
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end
function GameTooltip:SetAction(slot) self.action = slot end
function GameTooltip:Show() self.shown = true; self.showCalls = self.showCalls + 1 end
function GameTooltip_SetDefaultAnchor(tooltip, button) tooltip.owner = button end
function CreateBackdrop(frame) frame.backdrop = region(nil, frame) end
function UpdateMovable() end
function RemoveMovable() end
function GetTime() return now end
function GetCursorPosition() return 400, 240 end
function MouseIsOver(frame) return hovered == frame end
function IsShiftKeyDown() return shift end
function IsAltKeyDown() return alt end
function IsControlKeyDown() return false end
function HasAction() return true end
function GetActionTexture(slot) return 'texture-' .. slot end
function IsUsableAction() return true, false end
function ActionHasRange() return true end
function IsActionInRange() return 1 end
function IsCurrentAction() return false end
function IsAutoRepeatAction() return false end
function IsConsumableAction() return false end
function GetActionCooldown() return 0, 0, 1 end
function CooldownFrame_SetTimer() end
function GetActionText() return '' end
function GetBindingKey() return nil end
function GetBindingText() return '' end
function UseAction(slot, _, selfcast) table.insert(used, {slot, selfcast}) end
function PickupAction() error('Sorting must not pick up a native action') end
function PlaceAction() error('Sorting must not move a native action') end
function UnitClass() return 'Rogue', 'ROGUE' end
function strsplit(separator, text)
  local result = {}
  for value in string.gmatch(text, '[^' .. separator .. ']+') do table.insert(result, value) end
  return unpack(result)
end
talents = {{5, 0}, {0, 3}, {0, 0}}
function GetNumTalentTabs() return talents and #talents or 0 end
function GetNumTalents(tab) return #talents[tab] end
function GetTalentInfo(tab, index) return 'Talent ' .. tab .. '-' .. index, nil, nil, nil, talents[tab][index] end
pfUI = {bars = {}, media = {font = 'font'}, font_unit = 'font', api = {}}
pfUI.api.CreateBackdrop = CreateBackdrop
pfUI.api.CreateBackdropShadow = function() end
pfUI.api.SetAllPointsOffset = function() end
pfUI.api.EnableAutohide = function(frame) frame.hover = frame.hover or region(nil, frame) end
pfUI.api.DisableAutohide = function(frame) frame:SetAlpha(1) end
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
SlashCmdList, backdrop_highlight, button_animations = {}, {}, {}
COOLDOWN_FRAME_TYPE = 'Frame'
C = {bars = {keydown = '0', rightself = '1', altself = '1', glowrange = '1',
  showoom = '1', showna = '1', animmode = 'none', animation = 'none', cd_size = '12',
  macro_size = '10', macro_color = '1,1,1,1', bind_size = '10', bind_color = '1,1,1,1'}}
''')
g = lua.globals()
config = (root / 'api/config.lua').read_text(encoding='utf-8')
for key, value in re.findall(r'UpdateConfig\("bars",\s*nil,\s*"(monitor\w+)",\s*"([^"]*)"\)', config):
    g.C.bars[key] = value
g.C.bars.monitorprofiles = lua.table()
g.C.bars.monitorlist = '1;5;61;7;9'
g.C.bars.monitorenable = '1'
source = (root / 'modules/actionbar.lua').read_text(encoding='utf-8')
start = source.index('  pfUI.bars.MONITOR_COUNT = 32')
end = source.index('  -- 优化的配置更新函数', start)
monitor_source = source[start:end]
lua.execute(monitor_source)
lua.execute(r'''
mon = pfUI.bars.monitor
function tick(frame, seconds)
  now = now + (seconds or 1)
  invoke(frame, 'OnUpdate')
end
function resetList(list)
  shift, alt = false, false
  C.bars.monitorlist, C.bars.monitorenable, C.bars.monitorlock = list, '1', '0'
  pfUI.bars:UpdateMonitorConfig()
  tick(mon)
end
function drag(from, to, releaseShift)
  local b = mon.buttons[from]
  shift = true
  invoke(b, 'OnMouseDown', 'LeftButton')
  if C.bars.keydown == '1' then invoke(b, 'OnClick', 'LeftButton') end
  invoke(b, 'OnDragStart', 'LeftButton')
  hovered = to and mon.buttons[to] or nil
  if releaseShift then shift = false end
  tick(mon, .1)
  invoke(b, 'OnDragStop', 'LeftButton')
  invoke(b, 'OnClick', 'LeftButton')
  if to then invoke(mon.buttons[to], 'OnClick', 'LeftButton') end
  shift = false
end
resetList('1;5;61;7;9')
assert(C.bars.monitorprofiles.default.settings.monitorlist == '1;5;61;7;9')
assert(C.bars.monitorprofiles.default.settings.monitorenable == '1')
assert(C.bars.monitorprofile == 'default')
print('PASS: legacy list, order and settings migrate to the default profile')

local button = mon.buttons[1]
C.bars.monitorhidetooltip = '0'
invoke(button, 'OnEnter')
assert(GameTooltip:IsShown() and GameTooltip.action == 1)
assert(button.highlight:IsShown() and #GameTooltip.lines == 3)
C.bars.monitorhidetooltip = '1'
pfUI.bars:UpdateMonitorConfig()
assert(not GameTooltip:IsShown())
local shows = GameTooltip.showCalls
invoke(button, 'OnEnter')
assert(not GameTooltip:IsShown() and GameTooltip.showCalls == shows)
assert(button.highlight:IsShown())
C.bars.monitorhidetooltip = '0'
invoke(button, 'OnEnter')
assert(GameTooltip:IsShown())
invoke(button, 'OnLeave')
assert(not GameTooltip:IsShown() and not button.highlight:IsShown())
print('PASS: tooltip toggle hides immediately, preserves hover feedback and can be restored')

for _, keydown in ipairs({'0', '1'}) do
  C.bars.keydown = keydown
  resetList('1;5;61;7;9')
  local uses = #used
  drag(1, 4, true)
  assert(C.bars.monitorlist == '5;61;7;1;9')
  assert(C.bars.monitorprofiles.default.settings.monitorlist == C.bars.monitorlist)
  assert(mon.buttons[1].slot == 5 and mon.buttons[4].slot == 1)
  assert(mon.buttons[1].uid == 1 and mon.buttons[4].uid == 4)
  drag(5, 2)
  assert(C.bars.monitorlist == '5;9;61;7;1')
  assert(#used == uses and not mon.dragPreview:IsShown() and not mon.dragHighlight:IsShown())
  assert(mon.buttons[5]:GetAlpha() == 1)
  drag(2, nil)
  assert(C.bars.monitorlist == '5;9;61;7;1' and #used == uses)
  drag(2, 2)
  assert(C.bars.monitorlist == '5;9;61;7;1' and #used == uses)
  shift = false
  invoke(mon.buttons[1], 'OnMouseDown', 'LeftButton')
  invoke(mon.buttons[1], 'OnClick', 'LeftButton')
  assert(#used == uses + 1 and used[#used][1] == 5)
  invoke(mon.buttons[2], 'OnMouseDown', 'RightButton')
  invoke(mon.buttons[2], 'OnClick', 'RightButton')
  assert(used[#used][1] == 9 and used[#used][2] == true)
end
print('PASS: insertion sorting both ways, cancelled drops and normal/self-cast clicks in both click modes')

resetList('1;5;61;7;9')
C.bars.monitorrowsize = '2'
pfUI.bars:UpdateMonitorConfig()
tick(mon)
drag(1, 5)
assert(C.bars.monitorlist == '5;61;7;9;1')
assert(mon.buttons[5].point[5] < mon.buttons[1].point[5])
local b = mon.buttons[1]
shift = true
invoke(b, 'OnMouseDown', 'LeftButton')
invoke(b, 'OnDragStart', 'LeftButton')
assert(mon.dragButton == b and b:GetAlpha() == .35)
hovered = mon.buttons[2]
mon.dirty = true
tick(mon, .1)
assert(mon.dragButton == b and mon.dirty and b.slot == 5)
assert(mon.dragHighlight:IsShown() and mon.dragHighlight.allPoints == mon.buttons[2])
assert(mon.dragPreview.point[4] == 500 and mon.dragPreview.point[5] == 300)
C.bars.monitorlist = '3;4'
invoke(b, 'OnDragStop')
tick(mon)
assert(C.bars.monitorlist == '3;4' and b:GetAlpha() == 1)
shift = true
invoke(b, 'OnDragStart')
mon:Hide()
assert(mon.dragButton == nil and not mon.dragPreview:IsShown() and b:GetAlpha() == 1)
resetList('3;4')
C.bars.monitorlock = '1'
shift = true
invoke(b, 'OnMouseDown', 'LeftButton')
invoke(b, 'OnDragStart')
assert(mon.dragButton == nil)
local uses = #used
invoke(b, 'OnClick', 'LeftButton')
assert(#used == uses + 1)
print('PASS: multiple rows, scaled drag preview, refresh deferral, external list edits, hiding and lock behavior')

resetList('1;5;61')
C.bars.monitorsize, C.bars.monitorhidetooltip = '36', '0'
pfUI.bars:UpdateMonitorConfig()
assert(pfUI.bars:CreateMonitorProfile('  Combat  '))
local combat = C.bars.monitorprofile
assert(combat ~= 'default' and C.bars.monitorprofiles[combat].name == 'Combat')
assert(C.bars.monitorlist == '1;5;61')
assert(not pfUI.bars:CreateMonitorProfile('Combat'))
assert(not pfUI.bars:CreateMonitorProfile('   '))
C.bars.monitorlist, C.bars.monitorsize, C.bars.monitorhidetooltip = '9;12', '48', '1'
pfUI.bars:UpdateMonitorConfig()
C.bars.monitorprofile = 'default'
pfUI.bars:UpdateMonitorConfig()
assert(C.bars.monitorlist == '1;5;61' and C.bars.monitorsize == '36' and C.bars.monitorhidetooltip == '0')
C.bars.monitorprofile = combat
pfUI.bars:UpdateMonitorConfig()
assert(C.bars.monitorlist == '9;12' and C.bars.monitorsize == '48' and C.bars.monitorhidetooltip == '1')
assert(mon.buttons[1]:GetWidth() == 36) -- refresh is deferred to the next update
tick(mon)
assert(mon.buttons[1]:GetWidth() == 48 and mon.buttons[1].slot == 9)
assert(pfUI.bars:BindMonitorTalent())
local combatTalent = C.bars.monitorprofiles[combat].talent
assert(C.bars.monitorprofiles[combat].talentLabel == '5/3/0')
assert(pfUI.bars:CreateMonitorProfile('Stealth'))
local stealth = C.bars.monitorprofile
C.bars.monitorlist, C.bars.monitorhide, C.bars.monitorenable = '31;33;35', '1', '0'
pfUI.bars:UpdateMonitorConfig()
talents = {{0, 0}, {0, 0}, {5, 3}}
assert(pfUI.bars:BindMonitorTalent())
local stealthTalent = C.bars.monitorprofiles[stealth].talent
assert(stealthTalent ~= combatTalent)
C.bars.monitorautotalent = '1'
pfUI.bars:UpdateMonitorConfig()
local listener = pfUI.bars.monitorKeybindListener
assert(not mon:IsShown() and listener:IsShown())
talents = {{5, 0}, {0, 3}, {0, 0}}
tick(listener, 1.1)
assert(C.bars.monitorprofile == stealth)
tick(listener, 1.1)
assert(C.bars.monitorprofile == combat and C.bars.monitorlist == '9;12' and mon:IsShown())
local function talentEvent(name)
  event = name
  invoke(listener, 'OnEvent')
end
talents = {{0, 0}, {0, 0}, {5, 3}}
talentEvent('CHARACTER_POINTS_CHANGED')
tick(listener, .5)
talents = {{0, 0}, {0, 0}, {0, 0}}
talentEvent('SPELLS_CHANGED')
tick(listener, .5)
talents = {{0, 0}, {0, 0}, {5, 3}}
talentEvent('PLAYER_TALENT_UPDATE')
tick(listener, 1.1)
assert(C.bars.monitorprofile == combat)
tick(listener, 1.1)
assert(C.bars.monitorprofile == stealth and C.bars.monitorlist == '31;33;35' and not mon:IsShown())
talents = {{0, 5}, {3, 0}, {0, 0}} -- same totals as combat, different ranks
talentEvent('CHARACTER_POINTS_CHANGED')
tick(listener, 1.1); tick(listener, 1.1)
assert(C.bars.monitorprofile == stealth)
C.bars.monitorautotalent = '0'
talents = {{5, 0}, {0, 3}, {0, 0}}
talentEvent('PLAYER_TALENT_UPDATE')
tick(listener, 3)
assert(C.bars.monitorprofile == stealth)
print('PASS: independent profiles, exact talent matching, event debounce, unmatched builds and disabled/hidden monitor switching')

assert(pfUI.bars:BindMonitorTalent())
assert(C.bars.monitorprofiles[combat].talent == nil and C.bars.monitorprofiles[stealth].talent == combatTalent)
assert(pfUI.bars:BindMonitorTalent(true))
assert(C.bars.monitorprofiles[stealth].talent == nil)
talents = nil
assert(not pfUI.bars:BindMonitorTalent())
talents = {{5, 0}, {0, 3}, {0, 0}}
assert(pfUI.bars:DeleteMonitorProfile())
assert(C.bars.monitorprofiles[stealth] == nil and C.bars.monitorprofile == 'default')
assert(not pfUI.bars:DeleteMonitorProfile())
C.bars.monitorprofile = 'missing'
pfUI.bars:UpdateMonitorConfig()
assert(C.bars.monitorprofile == 'default' and C.bars.monitorlist == '1;5;61')
C.bars.monitorprofile = combat
pfUI.bars:UpdateMonitorConfig()
pfUI.bars.monitor = nil
''')
lua.execute(monitor_source)
lua.execute(r'''
mon = pfUI.bars.monitor
pfUI.bars:UpdateMonitorConfig()
tick(mon)
assert(C.bars.monitorprofile ~= 'default' and C.bars.monitorlist == '9;12')
assert(C.bars.monitorsize == '48' and C.bars.monitorhidetooltip == '1')
print('PASS: unique talent ownership, unbinding, unavailable talents, profile deletion, fallback and reload persistence')
''')

# Exercise the actual settings page, including live control synchronization.
gui = (root / 'modules/gui.lua').read_text(encoding='utf-8')
start = gui.index('    CreateGUIEntry(T["Actionbar"], T["Action Monitor"], function()')
end = gui.index('    CreateGUIEntry(T["Actionbar"], T["Gryphons"]', start)
lua.execute(r'''
guiEntries = {}
page = CreateFrame('Frame', 'MonitorSettings', UIParent)
function CreateGUIEntry(_, _, populate)
  local previous = this
  this = page
  populate()
  this = previous
end
function CreateConfig(callback, caption, category, key, widget, values, skip, named, dataType)
  local entry = CreateFrame('Frame', nil, page)
  entry.config, entry.category, entry.callback = key, category, callback
  entry.widget, entry.values, entry.dataType = widget, values, dataType
  entry.input = CreateFrame('Frame', nil, entry)
  entry.input:SetText(category and category[key] or '')
  if widget == 'checkbox' then entry.input:SetChecked(category[key] == '1') end
  function entry.input:UpdateMenu()
    self.menu = values()
    for i, option in ipairs(self.menu) do
      if string.match(option, '^([^:]+)') == category[key] then self.current = i end
    end
  end
  function entry.input:SetSelection(index) self.selection = index end
  if widget == 'dropdown' then entry.input:UpdateMenu() end
  guiEntries[key or caption] = entry
  return entry
end
''')
lua.execute(gui[start:end])
lua.execute(r'''
assert(guiEntries.monitorhidetooltip.widget == 'checkbox')
assert(guiEntries.monitorautotalent.widget == 'checkbox')
assert(guiEntries.monitorlist.dataType == 'string')
tick(page)
C.bars.monitorprofile = 'default'
guiEntries.monitorprofile.callback()
tick(page)
assert(guiEntries.monitorlist.input:GetText() == '1;5;61')
assert(guiEntries.monitorsize.input:GetText() == '36')
assert(not guiEntries.monitorhidetooltip.input.checked)
local profiles = pfUI.bars:GetMonitorProfiles()
local combat
for _, value in ipairs(profiles) do
  if string.find(value, ':Combat', 1, true) then combat = string.match(value, '^([^:]+)') end
end
assert(combat)
C.bars.monitorprofile = combat
guiEntries.monitorprofile.callback()
tick(page)
assert(guiEntries.monitorlist.input:GetText() == '9;12')
assert(guiEntries.monitorsize.input:GetText() == '48')
assert(guiEntries.monitorhidetooltip.input.checked)
assert(guiEntries.monitorprofile.input.menu[guiEntries.monitorprofile.input.selection] == combat .. ':Combat')
assert(pfUI.bars:BindMonitorTalent())
tick(page)
assert(string.find(guiEntries.monitorprofile.input.menu[guiEntries.monitorprofile.input.selection], '[5/3/0]', 1, true))
print('PASS: actual GUI wiring, list editing type, profile selection, talent labels and live settings synchronization')
''')

print('No live game actions were executed; native action pickup/placement is forbidden by the mock.')
