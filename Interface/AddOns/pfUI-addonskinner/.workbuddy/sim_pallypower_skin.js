// 离线仿真：skins/PallyPower.lua 的运行时验证（fengari, Lua 5.3 VM + WoW API 桩）
// 用法: node sim_pallypower_skin.js
// 产物: sim_pallypower_report.txt（stdout 不回显，结果落地文件）
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const TARGET = path.join(__dirname, '..', 'skins', 'PallyPower.lua');
const REPORT = path.join(__dirname, 'sim_pallypower_report.txt');

// ---------- Lua 桩：WoW API + pfUI.api（记录调用） ----------
const STUB = String.raw`
OUT = {}
print = function(s) table.insert(OUT, tostring(s)) end

BACKDROPS = {}
BUTTONS = {}
CHECKBOXES = {}
SHADOWS = {}
FRAMES = {}
TRIG = nil
RAID_CLASS_COLORS = { PALADIN = { r = 1, g = 0.5, b = 0.2 } }
UnitClass = function() return "player", "PALADIN" end
IsAddOnLoaded = function() return true end
getglobal = function(n) return _G[n] end

function mkregion(name)
  local r = {}
  r._name = name
  r._tex = "ORIG"
  r._vc = nil
  r.GetName = function(self) return self._name end
  r.SetTexture = function(self, t) self._tex = t end
  r.GetTexture = function(self) return self._tex end
  r.SetVertexColor = function(self, a, b, c, d) self._vc = { a, b, c, d } end
  r.SetTexCoord = function(self) end
  r.Hide = function(self) end
  r.Show = function(self) end
  return r
end

function mkfs(name)
  local f = {}
  f._name = name
  f._fam = "GameFont"
  f._size = 12
  f._col = nil
  f.GetName = function(self) return self._name end
  f.GetFont = function(self) return self._fam, self._size end
  f.SetFont = function(self, fam, size, fl) self._fam = fam; self._size = size; self._flags = fl end
  f.SetTextColor = function(self, r, g, b, a) self._col = { r, g, b, a } end
  return f
end

function mkframe(name, kind)
  local f = {}
  f._name = name
  f._kind = kind or "Frame"
  f._regions = {}
  f._ntex = nil
  f._ntexRegion = nil
  f._bd = "ORIG"
  f._scripts = {}
  f._events = {}
  f.GetName = function(self) return self._name end
  f.GetObjectType = function(self) return self._kind end
  f.SetBackdrop = function(self, bd) self._bd = bd end
  f.GetBackdrop = function(self) return self._bd end
  f.SetBackdropColor = function(self, r, g, b, a) self._bdc = { r, g, b, a } end
  f.SetBackdropBorderColor = function(self, r, g, b, a) self._bdbc = { r, g, b, a } end
  f.GetRegions = function(self) return table.unpack(self._regions) end
  f.CreateTexture = function(self, n) local t = mkregion(n); table.insert(self._regions, t); return t end
  f.CreateFontString = function(self) local t = mkfs(nil); return t end
  f.SetWidth = function(self, w) self._w = w end
  f.SetHeight = function(self, h) self._h = h end
  f.SetNormalTexture = function(self, t)
    self._ntex = t
    self._ntexRegion = mkregion(name and (name .. "NT") or nil)
    self._ntexRegion:SetTexture(t)
  end
  f.GetNormalTexture = function(self) return self._ntexRegion end
  f.SetPushedTexture = function(self, t) self._ptex = t end
  f.SetHighlightTexture = function(self, t) self._htex = t end
  f.SetDisabledTexture = function(self, t) self._dtex = t end
  f.SetTextInsets = function(self, l, r, t2, b) self._insets = { l, r, t2, b } end
  f.SetTextColor = function(self, r, g, b, a) self._tcol = { r, g, b, a } end
  f.RegisterEvent = function(self, e) self._events[e] = true end
  f.UnregisterAllEvents = function(self) self._events = {} end
  f.SetScript = function(self, sn, fn) self._scripts[sn] = fn end
  f.GetScript = function(self, sn) return self._scripts[sn] end
  table.insert(FRAMES, f)
  if name then rawset(_G, name, f) end
  return f
end

CreateFrame = function(kind, name)
  local f = mkframe(name, kind)
  TRIG = f
  return f
end

pfUI = { media = {}, font_default = "pfui-font" }
pfUI.media["img:close"] = "pfui-close-tex"
pfUI.addonskinner = {
  REGISTERED = {},
  RegisterSkin = function(self, name, fn) self.REGISTERED[name] = fn end,
}
pfUI.api = {}
function pfUI.api.CreateBackdrop(f, inset, legacy, transp)
  if not f then return end
  table.insert(BACKDROPS, { name = f:GetName(), legacy = legacy and 1 or 0, transp = transp })
  f:SetBackdrop("PFUI")
  return f
end
function pfUI.api.CreateBackdropShadow(f)
  if not f then return end
  table.insert(SHADOWS, f:GetName())
end
function pfUI.api.SkinButton(b, cr, cg, cb)
  if not b then return end
  table.insert(BUTTONS, { name = b:GetName(), cr = cr, cg = cg, cb = cb })
  pfUI.api.CreateBackdrop(b, nil, true)
  b:SetNormalTexture("")
  b:SetHighlightTexture("")
  b:SetPushedTexture("")
  b:SetDisabledTexture("")
end
function pfUI.api.SkinCheckbox(cb, size)
  if not cb then return end
  table.insert(CHECKBOXES, cb:GetName())
  if size then cb:SetWidth(size); cb:SetHeight(size) end
  pfUI.api.CreateBackdrop(cb)
end
function pfUI.api.StripTextures(f) end
`;

// ---------- Lua：PallyPower 对象树（按 XML 结构） ----------
const TREE = String.raw`
mkframe("PallyPowerFrame", "Frame")
rawset(_G, "PallyPowerFrameTitleText", mkfs("PallyPowerFrameTitleText"))
mkframe("PallyPowerFrameRefresh", "Button")
mkframe("PallyPowerFrameClear", "Button")
mkframe("PallyPowerFrameOptions", "Button")
mkframe("PallyPowerFrameCloseButton", "Button")
for p = 1, 12 do
  for c = 0, 9 do
    mkframe("PallyPowerFramePlayer" .. p .. "Class" .. c, "Button")
  end
end
mkframe("TenMinBlessingMainChk", "CheckButton")

mkframe("PallyPowerBuffBar", "Frame")
rawset(_G, "PallyPowerBuffBarTitleText", mkfs("PallyPowerBuffBarTitleText"))
for i = 1, 10 do
  mkframe("PallyPowerBuffBarBuff" .. i, "Button")
end

mkframe("PallyPower_OptionsFrame", "Frame")
rawset(_G, "PallyPower_OptionsFrameTitle", mkfs("PallyPower_OptionsFrameTitle"))
mkframe("PallyPower_OptionsFrameCloseButton", "Button")
for i = 1, 2 do
  local eb = mkframe("PallyPower_OptionsFrameScan" .. i, "EditBox")
  table.insert(eb._regions, mkregion("PallyPower_OptionsFrameScan" .. i .. "Left"))
  table.insert(eb._regions, mkregion("PallyPower_OptionsFrameScan" .. i .. "Middle"))
  table.insert(eb._regions, mkregion("PallyPower_OptionsFrameScan" .. i .. "Right"))
  table.insert(eb._regions, mkregion(nil))  -- HighlightText：无名字，不得被清
end
mkframe("PallyPower_OptionsFrameFeedback", "CheckButton")
mkframe("PallyPower_OptionsFrameSmart", "CheckButton")
mkframe("TenMinBlessingChk", "CheckButton")
mkframe("PallyPower_OptionsFrameSolo", "CheckButton")
mkframe("PallyPower_OptionsFrameSoloForce", "CheckButton")
`;

// ---------- Lua：主路径断言 ----------
const TESTS = String.raw`
local PASS, FAIL = 0, 0
local function check(msg, got, want)
  if got == want then PASS = PASS + 1
  else
    FAIL = FAIL + 1
    table.insert(OUT, "FAIL: " .. msg .. "  got=" .. tostring(got) .. " want=" .. tostring(want))
  end
end
local function findBd(name)
  for _, b in ipairs(BACKDROPS) do if b.name == name then return b end end
  return nil
end
local function countBd(name)
  local n = 0
  for _, b in ipairs(BACKDROPS) do if b.name == name then n = n + 1 end end
  return n
end

check("RegisterSkin 登记成功", pfUI.addonskinner.REGISTERED["PallyPower"] ~= nil, true)

local trig = TRIG
event = "ADDON_LOADED"; arg1 = "PallyPower"
trig._scripts.OnEvent()

check("FLAG_RAN == 1", _G.FLAG_RAN, 1)
check("FLAG_OK == true", _G.FLAG_OK, true)
check("trig 注销事件", next(trig._events) == nil, true)

-- 主面板
local mb = findBd("PallyPowerFrame")
check("主面板已建底板", mb ~= nil, true)
check("主面板非 legacy", mb and mb.legacy, 0)
check("主面板 transp=0.75", mb and mb.transp, 0.75)
check("主面板底板替换为 pfUI", _G.PallyPowerFrame._bd, "PFUI")
check("主面板标题换 pfUI 字体", _G.PallyPowerFrameTitleText._fam, "pfui-font")
check("主面板标题保留原字号", _G.PallyPowerFrameTitleText._size, 12)
check("主面板标题金色", _G.PallyPowerFrameTitleText._col[2], 0.82)
check("3 个动作按钮已建底板", countBd("PallyPowerFrameRefresh") + countBd("PallyPowerFrameClear") + countBd("PallyPowerFrameOptions"), 3)
check("关闭按钮红 X 纹理", _G.PallyPowerFrameCloseButton._ntexRegion._tex, "pfui-close-tex")
check("关闭按钮顶点色红", _G.PallyPowerFrameCloseButton._ntexRegion._vc[1], 1)
check("关闭按钮尺寸 15", _G.PallyPowerFrameCloseButton._w, 15)

-- 120 个 grid 格子全部 legacy 底板
local gridOK = true
for p = 1, 12 do
  for c = 0, 9 do
    local b = findBd("PallyPowerFramePlayer" .. p .. "Class" .. c)
    if not b or b.legacy ~= 1 then gridOK = false end
  end
end
check("120 个格子全部 legacy", gridOK, true)

-- buff 条
local bb = findBd("PallyPowerBuffBar")
check("buff 条 legacy 底板", bb and bb.legacy, 1)
check("buff 条标题颜色未动", _G.PallyPowerBuffBarTitleText._col, nil)
local buffN = 0
for _, b in ipairs(BACKDROPS) do
  if string.find(b.name or "", "^PallyPowerBuffBarBuff%d+$") then buffN = buffN + 1 end
end
check("10 个 buff 按钮", buffN, 10)
_G.PallyPowerBuffBarBuff1:SetBackdropColor(1, 0, 0, 0.5)
check("buff 按钮状态色机制可用", _G.PallyPowerBuffBarBuff1._bdc[1], 1)

-- 设置窗
local ob = findBd("PallyPower_OptionsFrame")
check("设置窗非 legacy 且 0.9", ob and (ob.legacy == 0 and ob.transp == 0.9), true)
check("设置窗标题金色", _G.PallyPower_OptionsFrameTitle._col[2], 0.82)
local eb1 = _G.PallyPower_OptionsFrameScan1
check("Scan1 Left 纹理已清", eb1._regions[1]._tex, "")
check("Scan1 Middle 纹理已清", eb1._regions[2]._tex, "")
check("Scan1 Right 纹理已清", eb1._regions[3]._tex, "")
check("Scan1 HighlightText 未动", eb1._regions[4]._tex, "ORIG")
check("Scan1 legacy 底板", findBd("PallyPower_OptionsFrameScan1").legacy, 1)
check("Scan1 边距已设", eb1._insets[1], 5)
check("6 个复选框", #CHECKBOXES, 6)
check("主面板小祝福勾选框已美化", CHECKBOXES[1], "TenMinBlessingMainChk")
check("设置窗小祝福勾选框已美化", CHECKBOXES[4], "TenMinBlessingChk")
check("设置窗 Solo/SoloForce 已美化", CHECKBOXES[5] .. "," .. CHECKBOXES[6], "PallyPower_OptionsFrameSolo,PallyPower_OptionsFrameSoloForce")

-- 总量：1(主) + 1(条) + 1(设置) + 120 + 10 + 2(输入框) + 3(动作) + 2(关闭) + 6(复选框) = 146
check("CreateBackdrop 共 146 次", table.getn and table.getn(BACKDROPS) or #BACKDROPS, 146)
check("阴影共 3 处", table.getn and table.getn(SHADOWS) or #SHADOWS, 3)

table.insert(OUT, "PASS=" .. PASS .. " FAIL=" .. FAIL)
RESULT = table.concat(OUT, string.char(10))
`;

// ---------- Lua：GUI 禁用负例断言 ----------
const TESTS_DISABLED = String.raw`
local PASS, FAIL = 0, 0
local function check(msg, got, want)
  if got == want then PASS = PASS + 1
  else
    FAIL = FAIL + 1
    table.insert(OUT, "FAIL: " .. msg .. "  got=" .. tostring(got) .. " want=" .. tostring(want))
  end
end

local trig = TRIG
event = "ADDON_LOADED"; arg1 = "PallyPower"
trig._scripts.OnEvent()

check("禁用时 FLAG_RAN 仍为 1", _G.FLAG_RAN, 1)
check("禁用时 FLAG_OK 保持 false", _G.FLAG_OK, false)
check("禁用时零次 CreateBackdrop", #BACKDROPS, 0)
check("禁用时零次 SkinButton", #BUTTONS, 0)
check("禁用时零次 SkinCheckbox", #CHECKBOXES, 0)

table.insert(OUT, "PASS=" .. PASS .. " FAIL=" .. FAIL)
RESULT = table.concat(OUT, string.char(10))
`;

function runCase(label, cfgLua, testsLua) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const lines = [];
  const steps = [
    ['stub', STUB],
    ['cfg', cfgLua],
    ['tree', TREE],
    ['skin', fs.readFileSync(TARGET, 'utf8')],
    ['tests', testsLua],
  ];
  for (const [name, code] of steps) {
    const st = lauxlib.luaL_dostring(L, to_luastring(code));
    if (st !== lua.LUA_OK) {
      lines.push('!! ' + label + ' step ' + name + ': ' + lua.lua_tojsstring(L, -1));
      return lines.join('\n');
    }
  }
  lua.lua_getglobal(L, to_luastring('RESULT'));
  lines.push('=== ' + label + ' ===');
  lines.push(lua.lua_tojsstring(L, -1));
  return lines.join('\n');
}

const out = [
  runCase('MAIN PATH (C={})', 'C = {}', TESTS),
  '',
  runCase('DISABLED PATH', 'C = { addonskinner = { disabled = { PallyPower = "1" } } }', TESTS_DISABLED),
].join('\n');

fs.writeFileSync(REPORT, out, 'utf8');
console.log(out);
