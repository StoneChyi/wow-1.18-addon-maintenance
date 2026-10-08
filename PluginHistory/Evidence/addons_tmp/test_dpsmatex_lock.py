from pathlib import Path
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

addon = Path(r'E:\1.18\Interface\AddOns\DPSMateX')
lua = LuaRuntime(unpack_returned_tuples=True)
for name in ('DPSMateX.lua', 'DPSMateX_Options.lua'):
    source = (addon / name).read_text(encoding='utf-8-sig')
    lua.execute('assert(loadstring(...))', source)

lua.execute('''
objects = {}
function getglobal(name) return objects[name] end
DPSMateX = {Settings = {lock = false, windows = {{name = "Main"}, {name = "Second"}}}, Options = {}, L = {}}
function DPSMateX:SendMessage() end
local Frame = {}
Frame.__index = Frame
function Frame:SetResizable(value) self.resizable = value end
function Frame:StartSizing(corner)
    assert(self.resizable, "Attempt to resize a locked frame")
    self.sizing = corner or "BOTTOMRIGHT"
end
function Frame:StopMovingOrSizing() self.sizing = nil; self.moving = false end
function Frame:GetPoint()
    assert(not self.sizing and not self.moving, "Position saved before drag stopped")
    return "CENTER", nil, "CENTER", 10, 20
end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
for key, window in ipairs(DPSMateX.Settings.windows) do
    local name = "DPSMateX_" .. window.name
    local frame = setmetatable({Key = key, width = 150, height = 100, resizable = true}, Frame)
    objects[name] = frame
    for _, suffix in ipairs({"_Resize", "_ResizeLU"}) do
        local handle = {visible = true, parent = frame}
        function handle:Hide() self.visible = false end
        function handle:Show() self.visible = true end
        function handle:GetParent() return self.parent end
        objects[name .. suffix] = handle
    end
end
''')

options = (addon / 'DPSMateX_Options.lua').read_text(encoding='utf-8-sig')
layout = options[options.index('function DPSMateX.Options:LayoutTitleBar'):options.index('function DPSMateX.Options:ToggleTitleBarButtonState')]
lua.execute('local _G = getglobal\n' + layout)
actions = options[options.index('function DPSMateX.Options:Lock()'):options.index('function DPSMateX.Options:Hide(frame)')]
# Vanilla Lua 5.0 permits iterating a table directly; adapt only the harness for Lua 5.1.
actions = actions.replace('for key, val in DPSMateX.Settings["windows"] do', 'for key, val in pairs(DPSMateX.Settings["windows"]) do')
lua.execute('local _G = getglobal\n' + actions)

core = (addon / 'DPSMateX.lua').read_text(encoding='utf-8-sig')
start = core.index('\t\tframe:SetResizable(not DPSMateX.Settings["lock"])')
end = core.index('\t\tif not val["titlebar"] then', start)
lua.execute('local _G = getglobal\nfunction initializeLockState(frame, val)\n' + core[start:end] + '\nend')

ns = {'ui': 'http://www.blizzard.com/wow/ui/'}
tree = ET.parse(addon / 'DPSMateX_Frame.xml')
for suffix in ('_Resize', '_ResizeLU'):
    button = next(b for b in tree.findall('.//ui:Button', ns) if b.get('name') == '$parent' + suffix)
    for event in ('OnMouseDown', 'OnMouseUp'):
        code = button.find('ui:Scripts/ui:' + event, ns).text
        lua.globals()['handler' + suffix + event] = lua.eval('function()\n' + code + '\nend')

lua.execute('''
local first = objects.DPSMateX_Main
local second = objects.DPSMateX_Second
for _, suffix in ipairs({"_Resize", "_ResizeLU"}) do
    this = objects["DPSMateX_Main" .. suffix]
    _G["handler" .. suffix .. "OnMouseDown"]()
    assert(first.sizing)
    first.width = 210; first.height = 130
    _G["handler" .. suffix .. "OnMouseUp"]()
    assert(not first.sizing)
    assert(DPSMateX.Settings.windows[1].savsize[1] == 210)
    assert(DPSMateX.Settings.windows[1].savsize[2] == 130)
end
this = objects.DPSMateX_Main_ResizeLU
handler_ResizeLUOnMouseDown()
second.moving = true
DPSMateX.Options:Lock()
assert(DPSMateX.Settings.lock)
for _, window in ipairs(DPSMateX.Settings.windows) do
    local name = "DPSMateX_" .. window.name
    local frame = objects[name]
    assert(not frame.resizable and not frame.sizing and not frame.moving)
    assert(window.position[1] == "CENTER")
    assert(window.savsize[1] == frame.width and window.savsize[2] == frame.height)
    for _, suffix in ipairs({"_Resize", "_ResizeLU"}) do
        this = objects[name .. suffix]
        assert(not this.visible)
        _G["handler" .. suffix .. "OnMouseDown"]()
        _G["handler" .. suffix .. "OnMouseUp"]()
        assert(not frame.sizing)
    end
end
DPSMateX.Options:Unlock()
assert(not DPSMateX.Settings.lock)
for _, window in ipairs(DPSMateX.Settings.windows) do
    local name = "DPSMateX_" .. window.name
    assert(objects[name].resizable)
    assert(objects[name .. "_Resize"].visible and objects[name .. "_ResizeLU"].visible)
end
for _, locked in ipairs({true, false, true, false}) do
    DPSMateX.Settings.lock = locked
    for _, window in ipairs(DPSMateX.Settings.windows) do
        local name = "DPSMateX_" .. window.name
        initializeLockState(objects[name], window)
        assert(objects[name].resizable == not locked)
        assert(objects[name .. "_Resize"].visible == not locked)
        assert(objects[name .. "_ResizeLU"].visible == not locked)
    end
end
''')
print('PASS: Lua syntax, both resize handles, multi-window lock/unlock, lock during drag, saved geometry, initialization with persisted lock state.')
