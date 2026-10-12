-- Run from the repository root with Lua 5.1. No FontStrings are created.
local function read(path)
  local file = assert(io.open(path, "rb"))
  local source = string.gsub(file:read("*a"), "\r\n", "\n")
  file:close()
  return source
end
local actionbar = read("Interface/AddOns/pfUI/modules/actionbar.lua")
local api = read("Interface/AddOns/pfUI/api/api.lua")
local env = setmetatable({}, { __index = _G })
local function execute(source)
  local chunk = assert(loadstring(source))
  setfenv(chunk, env)
  return chunk()
end
local frameMethods = {}
function frameMethods:SetBackdrop(value) self.spec = value end
function frameMethods:GetBackdrop() return self.spec end
function frameMethods:SetBackdropColor(...) self.fill = {...} end
function frameMethods:SetBackdropBorderColor(...) self.edge = {...} end
function frameMethods:SetFrameLevel(value) self.level = value end
function frameMethods:GetFrameLevel() return self.level or 3 end
function frameMethods:SetFrameStrata(value) self.strata = value end
function frameMethods:SetPoint(...) self.point = {...} end
function frameMethods:SetAllPoints(value) self.anchor = value end
function frameMethods:SetHitRectInsets(...) self.hitRect = {...} end
function frameMethods:Show() self.shown = true end
function frameMethods:Hide() self.shown = false end
function frameMethods:IsVisible()
  return self.shown and (not self.parent or self.parent:IsVisible())
end
env.CreateFrame = function(kind, name, parent)
  assert(kind == "Frame")
  return setmetatable({ parent = parent, shown = true }, { __index = frameMethods })
end
env.C = { appearance = { border = { force_blizz = "0" } }, bars = {} }
env.pfUI_config = { appearance = { border = {
  background = "0.1,0.2,0.3,0.8", color = "0.2,0.2,0.2,1",
  shadow = "1", shadow_intensity = "0.7",
} } }
env.pfUI = { api = {}, backdrop = {}, backdrop_thin = {},
  backdrop_blizz_full = {}, backdrop_blizz_border = {}, backdrop_shadow = {} }
env.pfUI.api.GetStringColor = function(value)
  local values = {}
  for number in string.gfind(value, "[^,]+") do
    values[table.getn(values) + 1] = tonumber(number)
  end
  return unpack(values)
end
env.GetBorderSize = function() return 1, 1 end
env.GetPerfectPixel = function() return 1 end
-- Use the real backdrop helper, including alpha handling and Blizzard edge frames.
execute(assert(string.match(api,
  '(local backdrop, b, level, rawborder, border, br, bg, bb, ba, er, eg, eb, ea.-)\n%-%- %[ Bar Layout Options %]')))
env.CreateBackdrop = env.pfUI.api.CreateBackdrop
execute(assert(string.match(actionbar,
  '(local function MonitorSetBorder%(b%).-)\n    %-%- 单按钮')) ..
  '\nMonitorBorder = MonitorSetBorder')
env.MonitorSetBorder = env.MonitorBorder
local buttonSetup = assert(string.match(actionbar,
  '(CreateBackdrop%(b, 2[^\n]*\n      MonitorSetBorder%(b%))'))
local backgroundToggle = assert(string.match(actionbar,
  '(if C.bars.monitorbackdrop == "1" then.-)\n\n      %-%- 消耗品数量'))
for _, style in ipairs({ "0", "1" }) do
  env.C.appearance.border.force_blizz = style
  for _, border in ipairs({ "0", "1" }) do
    env.C.bars.monitorborder = border
    env.mon = env.CreateFrame("Frame")
    env.b = env.CreateFrame("Frame", nil, env.mon)
    execute(buttonSetup)
    assert(env.b.backdrop.fill[4] == 0, "monitor button still has a background")
    assert(env.b.backdrop.edge[4] == tonumber(border))
    if style == "1" then
      assert(env.b.backdrop_border.edge[4] == tonumber(border))
    end
    -- Cold start with the background disabled creates no container backdrop.
    env.C.bars.monitorbackdrop = "0"
    execute(backgroundToggle)
    assert(not env.mon.backdrop and env.b.backdrop:IsVisible())
    for cycle = 1, 3 do
      env.C.bars.monitorbackdrop = "1"
      execute(backgroundToggle)
      assert(env.mon.backdrop:IsVisible() and env.mon.backdrop.fill[4] == 0.8)
      assert(env.mon.backdrop_shadow:IsVisible())
      env.C.bars.monitorbackdrop = "0"
      execute(backgroundToggle)
      assert(not env.mon.backdrop:IsVisible())
      assert(not env.mon.backdrop_shadow:IsVisible())
      assert(env.b.backdrop:IsVisible() and env.b.backdrop.fill[4] == 0)
      env.b.monOutOfRange = true
      env.MonitorBorder(env.b)
      assert(env.b.backdrop.fill[4] == 0 and env.b.backdrop.edge[4] == tonumber(border))
      if border == "1" then assert(env.b.backdrop.edge[1] == 1) end
    end
  end
  local ordinary = env.CreateFrame("Frame")
  env.CreateBackdrop(ordinary, 2)
  assert(ordinary.backdrop.fill[4] == 0.8, "ordinary actionbar backgrounds changed")
end
print("PASS: transparent monitor buttons in both styles, independent borders, cold start, repeated background/shadow toggles and ordinary backdrop preservation")
