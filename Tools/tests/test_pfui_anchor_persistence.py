"""Check real pfUI anchor selection, drag saving and reload without text UI."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

api = (ROOT / 'Interface/AddOns/pfUI/api/api.lua').read_text(encoding='utf-8')
unlock = (ROOT / 'Interface/AddOns/pfUI/modules/unlock.lua').read_text(encoding='utf-8')
actionbar = (ROOT / 'Interface/AddOns/pfUI/modules/actionbar.lua').read_text(encoding='utf-8')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.compile(unlock)
lua.execute(r'''
pfUI = {api = {}, movables = {}, unlock = {selection = {}, dock = {anchor = {}}}}
C = {position = {}, global = {offscreen = '1'}}
pfUI_config = C
function round(x, precision)
  local factor = 10^(precision or 0)
  return math.floor(x*factor+.5)/factor
end
function GetScreenWidth() return 1600 end
function GetScreenHeight() return 900 end
UIParent = {GetName = function() return 'UIParent' end}
local methods = {}
function methods:GetName() return self.name end
function methods:GetScale() return self.scale end
function methods:SetScale(value) self.scale = value end
function methods:GetParent() return UIParent end
function methods:SetParent(parent) assert(parent == UIParent or parent == 'UIParent') end
function methods:GetNumPoints() return self.point and 1 or 0 end
function methods:GetPoint() return unpack(self.point or {}) end
function methods:ClearAllPoints() self.point = nil end
function methods:GetLeft() return self.left end
function methods:GetRight() return self.left + self.width end
function methods:GetTop() return self.bottom + self.height end
function methods:GetBottom() return self.bottom end
function methods:GetCenter() return self.left+self.width/2, self.bottom+self.height/2 end
function methods:SetPoint(anchor, parent, relative, x, y)
  if type(parent) == 'number' then x, y = parent, relative; relative, parent = anchor, UIParent end
  assert(parent == UIParent and relative == anchor and type(x) == 'number' and type(y) == 'number')
  local ax = string.find(anchor, 'LEFT') and 0 or string.find(anchor, 'RIGHT') and 1 or .5
  local ay = string.find(anchor, 'BOTTOM') and 0 or string.find(anchor, 'TOP') and 1 or .5
  self.left = ax*(1600/self.scale-self.width)+x
  self.bottom = ay*(900/self.scale-self.height)+y
  self.point = {anchor, parent, relative, x, y}
end
function methods:StopMovingOrSizing() end
function frame(name, scale)
  local value = setmetatable({name = name, scale = scale or 1, width = 200, height = 30}, {__index = methods})
  value.drag = {}
  value:SetPoint('BOTTOM', UIParent, 'BOTTOM', -80, 150)
  return value
end
spanframe = {ClearAllPoints = function() end, SetPoint = function() end, GetScale = function() return 1 end}
function spanframe:GetCenter()
  local left, right, bottom, top
  for _, frame in ipairs(pfUI.unlock.selection) do
    left = math.min(left or math.huge, frame:GetLeft())
    right = math.max(right or -math.huge, frame:GetRight())
    bottom = math.min(bottom or math.huge, frame:GetBottom())
    top = math.max(top or -math.huge, frame:GetTop())
  end
  return (left+right)/2, (bottom+top)/2
end
this = {backdrop = {SetBackdropBorderColor = function() end}}
function SnapFinish() end
function CreateBackdrop() end
function UpdateDockValues() end
function UIDropDownMenu_SetSelectedID() end
function UIDropDownMenu_SetText() end
''')


def between(source, start, end):
    return source[source.index(start):source.index(end, source.index(start))]


lua.execute(between(api, 'function pfUI.api.LoadMovable(', '-- [ CreateShareListDialog ]') + '''
LoadMovable = pfUI.api.LoadMovable
SaveMovable = pfUI.api.SaveMovable
UpdateMovable = pfUI.api.UpdateMovable
''')
lua.execute(between(api, 'function pfUI.api.GetBestAnchor(', '-- [ GetStringColor ]') + '''
GetBestAnchor = pfUI.api.GetBestAnchor
ConvertFrameAnchor = pfUI.api.ConvertFrameAnchor
''')
lua.execute(between(unlock, '  local function SavePosition(', '  local function DrawGrid(') +
            between(unlock, '  local function DraggerOnDragStop()', '  local function DraggerOnClick()') +
            '\nSaveFramePosition = SavePosition; DragStop = DraggerOnDragStop')
lua.globals().SavePosition = lua.globals().SaveFramePosition
dropdown = between(unlock, '      info.func = function()', '      UIDropDownMenu_AddButton(info)')
lua.execute('function SelectAnchor(frame, value)\n' +
            'local info, id, text = {}, 1, value\n' +
            'pfUI.unlock.dock.parent = {frame = frame}\n' + dropdown + '\ninfo.func()\nend')

lua.execute(r'''
local anchors = {'TOPLEFT', 'TOP', 'TOPRIGHT', 'RIGHT', 'BOTTOMRIGHT', 'BOTTOM', 'BOTTOMLEFT', 'LEFT', 'CENTER'}
local names = {'pfActionBarStances', 'pfActionBarPet', 'pfActionBarMain', 'pfActionMonitorFrame', 'pfPlayer'}
local cases = 0
for _, name in ipairs(names) do
  for _, anchor in ipairs(anchors) do
    C.position = {}
    local f = frame(name, .9)
    local left, bottom = f:GetLeft(), f:GetBottom()
    SelectAnchor(f, anchor)
    assert(C.position[name].anchor == anchor and C.position[name].anchor_manual == anchor)
    assert(math.abs(f:GetLeft()-left) < 1 and math.abs(f:GetBottom()-bottom) < 1)
    -- Resizing the stance bar follows the manually chosen edge.
    local fixedX = select(4, f:GetPoint())
    f.width = 300
    LoadMovable(f)
    assert(f:GetPoint() == anchor and select(4, f:GetPoint()) == fixedX)
    -- Drag to the bottom middle: automatic selection would choose BOTTOM.
    f:SetPoint('BOTTOM', UIParent, 'BOTTOM', -80, 150)
    pfUI.unlock.selection = {f}
    this.frame, this.fname = f, name
    DragStop()
    assert(C.position[name].anchor == anchor and f:GetPoint() == anchor, 'manual anchor overwritten by drag')
    -- Start a new frame with defaults and restore the saved configuration.
    local fresh = frame(name, .9)
    UpdateMovable(fresh)
    assert(fresh:GetPoint() == anchor)
    -- Pet bar default changes also use LoadMovable(init=true).
    fresh:ClearAllPoints()
    fresh:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 10)
    UpdateMovable(fresh, true)
    assert(fresh:GetPoint() == anchor and C.position[name].anchor == anchor)
    cases = cases+1
  end
end
print('PASS: '..cases..' frame/anchor combinations preserve manual selection through drag, resize and reload')
-- Unconfigured and old entries retain automatic drag anchors.
for _, old in ipairs({false, true}) do
  C.position = {}
  local f = frame('pfActionBarStances')
  if old then SaveMovable(f) end
  pfUI.unlock.selection = {f}
  this.frame, this.fname = f, f.name
  DragStop()
  assert(C.position[f.name].anchor == 'BOTTOM' and not C.position[f.name].anchor_manual)
end
-- Group dragging respects each member's independent manual choice.
C.position = {}
local a, b, c = frame('pfActionBarStances'), frame('pfActionBarPet'), frame('pfActionBarMain')
SelectAnchor(a, 'BOTTOMLEFT'); SelectAnchor(b, 'TOPRIGHT')
pfUI.unlock.selection = {a, b, c}
this.frame, this.fname = a, a.name
DragStop()
assert(C.position[a.name].anchor == 'BOTTOMLEFT')
assert(C.position[b.name].anchor == 'TOPRIGHT')
assert(C.position[c.name].anchor == 'BOTTOM')
-- Existing reset handlers delete the whole entry, including the manual choice.
C.position[a.name] = nil
pfUI.unlock.selection = {a}
DragStop()
assert(C.position[a.name].anchor == 'BOTTOM' and not C.position[a.name].anchor_manual)
print('PASS: automatic anchors, old configs, mixed group drag and reset remain functional')
''')
assert 'pfUI_config["position"][frame:GetName()] = nil' in unlock
assert actionbar.count('UpdateMovable(bars[11], true)') == 2
print('PASS: Lua 5.1 syntax and existing reset/pet-bar restore paths; no FontStrings created')
