from pathlib import Path
import sys

sys.path.insert(0, 'E:/1.18/addons_tmp/bcs-test-runtime')
from lupa.lua51 import LuaRuntime

root = Path('E:/1.18/Interface/AddOns/pfUI')
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval('function(s) local f, err = loadstring(s); assert(f, err); return true end')
for relative in ['modules/unitxp.lua', 'modules/gui.lua', 'api/config.lua', 'env/translations_zhCN.lua']:
    compile_lua((root / relative).read_text(encoding='utf-8'))
print('PASS: Lua syntax for all four changed files')

source = (root / 'modules/unitxp.lua').read_text(encoding='utf-8')
start = source.index('  local function CreateIndependentIndicators()')
end = source.index('  local function GetMouseoverDistanceColor', start)
lua.execute('''
local function region()
  local r = { shown = true, width = 0, height = 0, pointCalls = 0 }
  function r:SetWidth(v) self.width = v end
  function r:SetHeight(v) self.height = v end
  function r:GetWidth() return self.width end
  function r:GetHeight() return self.height > 0 and self.height or 18 end
  function r:SetPoint(p, parent, relative, x, y)
    self.point = {p, parent, relative, x or 0, y or 0}
    self.pointCalls = self.pointCalls + 1
  end
  function r:ClearAllPoints() self.point = nil end
  function r:SetFont(...) end
  function r:SetTexture(...) self.texture = {...} end
  function r:SetTextColor(...) self.color = {...} end
  function r:SetVertexColor(...) self.color = {...} end
  function r:SetText(s) self.text = s end
  function r:GetText() return self.text end
  function r:Show() self.shown = true end
  function r:Hide() self.shown = false end
  function r:IsShown() return self.shown end
  function r:SetScript(name, callback) self[name] = callback end
  function r:CreateTexture(...) return region() end
  function r:CreateFontString(...) return region() end
  return r
end
function CreateFrame(...) return region() end
pfUI = {uf = {target = {}}, movables = {}, media = {['img:circleraid'] = 'circle'}, font_default = 'font'}
C = {unitframes = {distance_indicator = '1'}}
cachedConfig = {font_size = 13, pet_font_size = 13, pet_offset_y = -10,
  status_size = 15, show_outsight_icon = true, use_gradient = true, show_prefix = true,
  play_sound = false, pet_mode = 0, distance_indicator_update_interval = .1,
  face_color = {1,.3,.3}, back_color = {0,1,0}, deadzone_color = {1,1,0},
  outsight_color = {.66,.66,.66}, pet_color = {0,1,0,1}}
thresholds = {{5,.3,.5,1},{8,.4,.7,1},{20,.4,.9,1},{30,0,1,0},{999,1,0,0}}
lastConfigRefresh = 0
CONFIG_REFRESH_INTERVAL = 2
function updateCachedConfig() end
function UpdateMovable(...) end
function UnitClass(...) return 'HUNTER', 'HUNTER' end
now = 0
function GetTime() return now end
function UnitExists(unit) return unit == 'target' and active.exists or unit == 'pet' and active.pet end
function UnitCanAttack(...) return active.attackable end
function UnitIsDeadOrGhost(unit) return unit == 'target' and active.dead or unit ~= 'target' and active.selfDead end
function UnitAffectingCombat(...) return false end
function UnitBuff(...) return nil end
function GetReferenceUnit() return active.ref or 'player' end
function UnitXP(command, first, second, meter)
  if command == 'distanceBetween' then
    if second == 'pet' then return active.petDistance end
    if meter == 'meleeAutoAttack' then
      if active.meleeError then error('range failure') end
      return active.melee
    end
    if active.distanceError then error('distance failure') end
    return active.distance
  elseif command == 'inSight' then
    if active.sightError then error('sight failure') end
    return active.sight
  elseif command == 'behind' then
    if first == 'target' then
      if active.facingError then error('facing failure') end
      facingReference = second
      return active.targetBehind
    end
    if active.behindError then error('rear position failure') end
    behindReference = first
    return active.behind
  end
  error('Unexpected API call')
end
''')
lua.execute(source[start:end] + '\nassert(CreateIndependentIndicators())')
g = lua.globals()
frame = g.pfUI.distanceIndicator
colors = {
    'green': (77 / 255, 218 / 255, 128 / 255),
    'orange': (1, 181 / 255, 46 / 255),
    'red': (240 / 255, 100 / 255, 108 / 255),
    'gray': (.6, .6, .6),
}
defaults = dict(exists=True, attackable=True, distance=3.2, melee=0, sight=True,
                behind=True, targetBehind=False, pet=False)
cases = [
    ('ready', {}, 'green', 'green'),
    ('target front', {'behind': False}, 'green', 'orange'),
    ('player turned away', {'targetBehind': True}, 'green', 'orange'),
    ('occluded', {'sight': False}, 'red', 'orange'),
    ('out of melee range', {'melee': .01, 'distance': 12.4}, 'green', 'red'),
    ('out of range and occluded', {'melee': 9, 'sight': False}, 'red', 'red'),
    ('unknown sight', {'sight': None}, 'gray', 'gray'),
    ('sight error', {'sightError': True}, 'gray', 'gray'),
    ('unknown rear position', {'behind': None}, 'green', 'gray'),
    ('rear position error', {'behindError': True}, 'green', 'gray'),
    ('unknown facing', {'targetBehind': None}, 'green', 'gray'),
    ('facing error', {'facingError': True}, 'green', 'gray'),
    ('unknown range', {'melee': None}, 'green', 'gray'),
    ('range error', {'meleeError': True}, 'green', 'gray'),
    ('invalid range', {'melee': -1}, 'green', 'gray'),
    ('friendly target', {'attackable': False}, 'green', 'gray'),
    ('dead target', {'dead': True}, 'green', 'gray'),
    ('dead player', {'selfDead': True}, 'green', 'gray'),
    ('pet reference', {'ref': 'pet'}, 'green', 'green'),
]

def color_of(texture):
    return tuple(texture.color[i] for i in range(1, 4))

for name, overrides, left, right in cases:
    g.active = lua.table_from(defaults | overrides)
    g.now += 1
    g.this = frame
    frame.OnUpdate()
    assert frame.icon.IsShown(frame.icon) and frame.backIcon.IsShown(frame.backIcon), name
    assert color_of(frame.icon) == colors[left], (name, 'left', color_of(frame.icon))
    assert color_of(frame.backIcon) == colors[right], (name, 'right', color_of(frame.backIcon))
    expected_text = (.4, .9, 1) if overrides.get('distance', 3.2) == 12.4 else (.3, .5, 1)
    assert color_of(frame.text) == expected_text, (name, 'distance color')
    assert '\n' not in frame.text.text, (name, 'redundant prefix')
    assert frame.text.point[4] == 0 and frame.petText.point[4] == 0, (name, 'center alignment')
    if name == 'pet reference':
        assert g.facingReference == 'pet' and g.behindReference == 'pet'
print(f'PASS: {len(cases)} live update scenarios, including independent distance color and facing direction')

for name, overrides in [('target cleared', {'exists': False}), ('distance missing', {'distance': None}),
                        ('distance error', {'distanceError': True}), ('invalid distance', {'distance': -1})]:
    g.active = lua.table_from(defaults | overrides)
    g.now += 1
    frame.OnUpdate()
    assert not frame.icon.IsShown(frame.icon) and not frame.backIcon.IsShown(frame.backIcon), name
    assert frame.text.text == '', name
print('PASS: both markers clear when target or distance is unavailable')

g.active = lua.table_from(defaults | {'pet': True, 'petDistance': 21.5})
g.cachedConfig.pet_mode = 1
g.cachedConfig.status_size = 22
g.cachedConfig.pet_offset_y = -24
g.now += 1
frame.OnUpdate()
assert frame.icon.width == 22 and frame.icon.height == 22
assert frame.backIcon.width == 22 and frame.backIcon.height == 22
assert frame.icon.point[4] == -6 and frame.backIcon.point[4] == 6
assert frame.petText.text == '21.5' and frame.petText.IsShown(frame.petText)
assert frame.petText.point[4] == 0 and frame.petText.point[5] == -24
print('PASS: live size changes and centered pet distance')

g.cachedConfig.show_outsight_icon = False
g.active = lua.table_from(defaults | {'sight': False})
g.now += 1
frame.OnUpdate()
assert not frame.icon.IsShown(frame.icon) and not frame.backIcon.IsShown(frame.backIcon)
assert color_of(frame.text) == (.66, .66, .66)
g.cachedConfig.show_outsight_icon = True
g.cachedConfig.use_gradient = False
g.now += 1
frame.OnUpdate()
assert color_of(frame.text) == (1, 1, 1)
assert color_of(frame.icon) == colors['red'] and color_of(frame.backIcon) == colors['orange']
print('PASS: marker toggle, legacy text-only mode and gradient toggle')
