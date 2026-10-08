from pathlib import Path
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).parent / "bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

root = Path(r"E:\1.18\Interface\AddOns\WIM")
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(s, name) local f, err = loadstring(s, name); assert(f, err); return f end")
for path in root.glob("*.lua"):
    compile_lua(path.read_text(encoding="utf-8-sig"), str(path))
scripts = {}
for path in root.glob("*.xml"):
    tree = ET.parse(path)
    for element in tree.iter():
        if element.tag.endswith("Scripts"):
            for script in element:
                compile_lua("return function()\n" + (script.text or "") + "\nend", str(path))
    if path.name == "WIM.xml":
        for element in tree.iter():
            if element.attrib.get("name") == "$parentMsgBox":
                scripts = {s.tag.split("}")[-1]: s.text for s in list(element)[-1]}

lua.execute(r'''
frames = {}
combat, shifted, resting = false, false, false
local Frame = {}
Frame.__index = Frame
function Frame:GetName() return self.name end
function Frame:GetParent() return self.parent end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsShown()) end
function Frame:SetScript(event, callback) self.scripts[event] = callback end
function Frame:GetScript(event) return self.scripts[event] end
function Frame:Fire(event)
    local saved = this
    this = self
    local callback = self:GetScript(event)
    if callback then callback() end
    this = saved
end
function Frame:Show() if not self.shown then self.shown = true; self:Fire("OnShow") end end
function Frame:Hide()
    if not self.shown then return end
    self.shown = false
    self:Fire("OnHide")
    for _, child in pairs(frames) do
        if child.parent == self then child:Fire("OnHide") end
    end
end
function Frame:SetFocus()
    if focused == self then return end
    if focused then focused:ClearFocus() end
    focused = self
    self:Fire("OnEditFocusGained")
end
function Frame:ClearFocus()
    if focused ~= self then return end
    focused = nil
    self:Fire("OnEditFocusLost")
end
function Frame:Raise() self.raised = true end
function Frame:GetText() return self.text or "" end
function Frame:SetText(text) self.text = text end
function Frame:AddHistoryLine(text) self.history = text end
function Frame:AddMessage(text) self.message = text end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({name=name, parent=parent, shown=true, scripts={}}, Frame)
    table.insert(frames, frame)
    if name then _G[name] = frame end
    return frame
end
function GetMouseFocus() return mouse end
function IsShiftKeyDown() return shifted end
function UnitAffectingCombat() return combat end
function UnitName() return "Player" end
function IsResting() return resting end
function getglobal(name) return _G[name] end
function time() return 123 end
strsub = string.sub
''')
lua.execute((root / "WIM.lua").read_text(encoding="utf-8-sig"))
for event, code in scripts.items():
    lua.globals()["edit_" + event] = compile_lua("return function()\n" + code + "\nend", event)()
lua.execute(r'''
WIM_UpdateScrollBars = function() end
WIM_Icon_DropDown_Update = function() end
WIM_PlaySoundWisp = function() end
WIM_AddToHistory = function() end
WIM_RecentListAdd = function() end
WIM_getTimeStamp = function() return "" end
WIM_ConvertURLtoLinks = function(text) return text end
WIM_MarkContactListDirty = function() end
UpdateUnreadBubble = function() end
RefreshUnread = function(user) WIM_contact_Unread[user] = 0 end
WIM_HistoryFrame = CreateFrame("Frame")
WIM_HistoryFrame:Hide()
WIM_IconItems = {Alice=true, Bob=true}
WIM_contact_Unread = {}
boxFrame = CreateFrame("Frame")
world = CreateFrame("Frame", "WorldFrame")
mouse = world
function AddConversation(name)
    local win = CreateFrame("Frame", "WIM_msgFrame"..name)
    win.theUser = name
    win:Hide()
    local edit = CreateFrame("EditBox", win:GetName().."MsgBox", win)
    for event, callback in pairs({OnEnterPressed=edit_OnEnterPressed,
        OnEscapePressed=edit_OnEscapePressed, OnEditFocusGained=edit_OnEditFocusGained,
        OnEditFocusLost=edit_OnEditFocusLost, OnHide=edit_OnHide}) do
        edit:SetScript(event, callback)
    end
    CreateFrame("Frame", win:GetName().."ScrollingMessageFrame", win)
    WIM_Windows[name] = {frame=win:GetName(), is_visible=false}
    return win, edit
end
alice, aliceEdit = AddConversation("Alice")
bob, bobEdit = AddConversation("Bob")
function SendChatMessage(text, channel, language, target)
    sent = {text=text, target=target}
    -- Simulate the synchronous outgoing whisper event during Enter.
    WIM_PostMessage(target, text, 2, "Player", text)
end
function Tick()
    for _, frame in ipairs(frames) do
        if frame:IsShown() and frame:GetScript("OnUpdate") then frame:Fire("OnUpdate") end
    end
end

-- Upgrade existing saved settings, then preserve subsequent user changes.
WIM_Data.autoFocus, WIM_Data.keepFocus, WIM_Data.keepFocusRested = true, false, true
WIM_ApplyInputFocusDefaults()
assert(not WIM_Data.autoFocus and WIM_Data.keepFocus and not WIM_Data.keepFocusRested)
WIM_Data.autoFocus = true
WIM_ApplyInputFocusDefaults()
assert(WIM_Data.autoFocus)

-- Even with auto focus explicitly enabled, incoming combat popups cannot capture keys.
combat = true
WIM_PostMessage("Alice", "incoming", 1, "Alice", "incoming")
assert(alice:IsShown() and focused == nil and WIM_EditBoxInFocus == nil)

-- Manual contact selection and repeated sends work during combat.
WIM_PostMessage("Alice")
assert(focused == aliceEdit)
for _, text in ipairs({"one", "two"}) do
    aliceEdit:SetText(text)
    aliceEdit:Fire("OnEnterPressed")
    assert(sent.text == text and sent.target == "Alice")
    assert(aliceEdit:GetText() == "" and focused == aliceEdit)
end

-- Single-window incoming messages preserve the active conversation and draft.
aliceEdit:SetText("unfinished")
WIM_PostMessage("Bob", "incoming", 1, "Bob", "incoming")
assert(alice:IsShown() and not bob:IsShown() and WIM_NowShowWindow == "Alice")
assert(focused == aliceEdit and aliceEdit:GetText() == "unfinished")
assert(WIM_contact_Unread.Bob == 1)

-- Mouse hooks preserve original handlers and game event context, then restore them.
local original = function()
    assert(this == world and arg1 == "LeftButton")
    clicked = true
    return "original", nil, "tail"
end
aliceEdit:ClearFocus()
world:SetScript("OnMouseDown", original)
aliceEdit:SetFocus()
this, arg1 = world, "LeftButton"
local first, middle, last = world:GetScript("OnMouseDown")()
assert(clicked and first == "original" and middle == nil and last == "tail")
assert(focused == nil and WIM_EditBoxInFocus == nil)
assert(world:GetScript("OnMouseDown") == original)

-- Merely hovering outside does not stop typing. Shift-click can still insert links.
aliceEdit:SetFocus()
Tick()
assert(focused == aliceEdit)
shifted = true
world:GetScript("OnMouseDown")()
assert(focused == aliceEdit)
shifted = false

-- Clicking another UI control releases input without swallowing its action.
other = CreateFrame("Button")
other:SetScript("OnMouseDown", function() otherClicked = true end)
mouse = other
Tick()
other:GetScript("OnMouseDown")()
assert(otherClicked and focused == nil and WIM_EditBoxInFocus == nil)

-- Closing the active window clears input tracking; Escape is also an exit.
WIM_PostMessage("Alice", nil, 5)
assert(focused == aliceEdit)
alice:Hide()
assert(focused == nil and WIM_EditBoxInFocus == nil)
WIM_PostMessage("Alice", nil, 5)
aliceEdit:Fire("OnEscapePressed")
assert(focused == nil and WIM_EditBoxInFocus == nil)

-- Multi-window popups can display but cannot interrupt an existing input session.
WIM_Data.multiWindow = true
combat = false
WIM_PostMessage("Alice", nil, 5)
bob:Hide()
WIM_PostMessage("Bob", "new", 1, "Bob", "new")
assert(bob:IsShown() and focused == aliceEdit)

-- Optional out-of-combat auto-focus still works when no one is typing.
aliceEdit:ClearFocus()
bob:Hide()
WIM_PostMessage("Bob", "new", 1, "Bob", "new")
assert(focused == bobEdit)
''')
print("PASS: WIM Lua and XML script syntax; migration, combat popups, continuous sends, draft protection, outside clicks, Shift links, closing, Escape, and multi-window focus.")
