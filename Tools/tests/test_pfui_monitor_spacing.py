"""Exercise pfUI's actual monitor layout in screen pixels, without constructing text UI."""
from pathlib import Path
import itertools
import math
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

source = (ROOT / 'Interface/AddOns/pfUI/modules/actionbar.lua').read_text(encoding='utf-8')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.compile(source)
start = source.index('    local function MonitorPixelSize()')
end = source.index('    -- 轻刷：', start)
update_start = source.index('    mon:SetScript("OnUpdate", function()', end)
update_end = source.index('\n    end)', update_start)
update = source[update_start:update_end].split('function()', 1)[1]
lua.execute(r'''
getn = table.getn
frameScale, resolution, now = .825, '2560x1440', 0
C = {bars = {monitorenable = '1', monitorglow = '0'}}
pfUI = {bars = {MONITOR_COUNT = 32}}
local function frame()
  return {
    shown = true, pointCalls = 0,
    IsShown = function(self) return self.shown end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
    ClearAllPoints = function(self) self.point = nil end,
    SetPoint = function(self, point, parent, relative, x, y)
      assert(point == 'TOPLEFT' and relative == 'TOPLEFT' and parent == mon)
      assert(type(x) == 'number' and type(y) == 'number')
      self.point = {x, y}; self.pointCalls = self.pointCalls + 1
    end,
    SetWidth = function(self, width) assert(width > 0); self.width = width end,
    SetHeight = function(self, height) assert(height > 0); self.height = height end,
    GetEffectiveScale = function() return frameScale end,
  }
end
mon = frame()
mon.buttons, mon.slotset = {}, {}
for i = 1, 32 do mon.buttons[i] = frame() end
function GetCVar(name) assert(name == 'gxResolution'); return resolution end
function GetTime() return now end
function MonitorListToTable() return slots end
function MonitorUpdateButton() end
timerCalls, keyCalls = 0, 0
function MonitorTimers() timerCalls = timerCalls + 1 end
function MonitorPollKeys() keyCalls = keyCalls + 1 end
function MonitorUpdateDrag() end
this = mon
''')
api = lua.execute(source[start:end] + '\nreturn {refresh = MonitorRefresh, pixel = MonitorPixelSize, update = function()' + update + '\nend}')
g = lua.globals()


def configure(size=21, spacing=1, rows=8, count=8, scale=.825, height=1440):
    g.C.bars.monitorsize = str(size)
    g.C.bars.monitorspacing = str(spacing)
    g.C.bars.monitorrowsize = str(rows)
    g.frameScale = scale
    g.resolution = f'2560x{height}'
    g.slots = lua.table_from(list(range(1, count + 1)))
    api.refresh()
    return 768 / height / scale


def close(actual, expected):
    assert math.isclose(actual, expected, abs_tol=1e-7), (actual, expected)


def raster(value):
    # The shared fractional origin must not affect relative widths/gaps.
    return math.floor(value + .5 + 1e-7)


def verify(size, spacing, rows, count, scale, height):
    pixel = configure(size, spacing, rows, count, scale, height)
    size_px = max(1, math.floor(size / pixel + .5))
    gap_px = max(1, math.floor(spacing / pixel + .5)) if spacing > 0 else 0
    pad_px = max(1, math.floor(2 / pixel + .5))
    cols, nrows = min(count, rows) or 1, math.ceil(count / rows) or 1
    close(g.mon.width / pixel, cols * size_px + (cols - 1) * gap_px + 2 * pad_px)
    close(g.mon.height / pixel, nrows * size_px + (nrows - 1) * gap_px + 2 * pad_px)
    for i in range(1, 33):
        button = g.mon.buttons[i]
        assert button.shown == (i <= count)
        if i > count:
            assert button.slot is None
            continue
        assert button.slot == i
        x, y = button.point[1] / pixel, -button.point[2] / pixel
        close(button.width / pixel, size_px)
        close(button.height / pixel, size_px)
        close(x, ((i - 1) % rows) * (size_px + gap_px) + pad_px)
        close(y, ((i - 1) // rows) * (size_px + gap_px) + pad_px)
        for phase in [0, .17, .49, .51, .93]:
            close(raster(x + phase + button.width / pixel) - raster(x + phase), size_px)
            if (i - 1) % rows:
                previous = g.mon.buttons[i - 1]
                right = (previous.point[1] + previous.width) / pixel
                assert raster(x + phase) - raster(right + phase) == gap_px
            if i > rows:
                previous = g.mon.buttons[i - rows]
                bottom = (-previous.point[2] + previous.height) / pixel
                assert raster(y + phase) - raster(bottom + phase) == gap_px


# Screenshot settings: 21 units, gap 1, frame scale 1.1, UI scale .75, 1440p.
pixel = 768 / 1440 / .825
old_gaps = [raster((i * 22 + 2) / pixel + .74) - raster(((i - 1) * 22 + 2 + 21) / pixel + .74)
            for i in range(1, 8)]
assert len(set(old_gaps)) > 1, old_gaps
verify(21, 1, 8, 8, .825, 1440)
print('PASS: screenshot setup reproduces old mixed pixel gaps and now renders identical gaps')

cases = 0
for values in itertools.product([21, 36, 21.3], [0, .05, 1, 1.25], [1, 5, 8],
                                [0, 1, 8, 32], [.5, .75, .825, 1, 1.1, 1.375], [1080, 1440, 2160]):
    verify(*values)
    cases += 1
print(f'PASS: {cases} combinations of size, spacing, rows, count, scale and resolution; fractional-position phases checked')

configure()
calls = g.mon.buttons[1].pointCalls
g.mon.dirty = False
g.now += 1
api.update()
assert g.mon.buttons[1].pointCalls == calls
g.frameScale = .9
g.now += 1
api.update()
assert g.mon.buttons[1].pointCalls == calls + 1
close(g.mon.buttons[1].width / api.pixel(), round(g.mon.buttons[1].width / api.pixel()))
g.resolution = '1920x1080'
g.now += 1
api.update()
assert g.mon.buttons[1].pointCalls == calls + 2
g.mon.dragButton = g.mon.buttons[1]
g.frameScale = 1.3
g.now += 1
api.update()
assert g.mon.buttons[1].pointCalls == calls + 2 and g.mon.dirty
g.mon.dragButton = None
g.now += 1
api.update()
assert g.mon.buttons[1].pointCalls == calls + 3 and not g.mon.dirty
assert g.timerCalls == 5 and g.keyCalls == 5
print('PASS: live scaling/resolution refresh, idle layout caching and drag refresh deferral')

g.resolution = 'invalid'
close(api.pixel(), 1 / g.frameScale)
g.resolution = '1920x0'
close(api.pixel(), 1 / g.frameScale)
print('PASS: invalid resolution fallback; no FontStrings or unsupported UI APIs mocked')
