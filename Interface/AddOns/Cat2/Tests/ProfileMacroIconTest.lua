-- 从项目根目录使用 Lua 5.1（含 Lua 5.0 arg 兼容）运行；不加入游戏 TOC。
local checks = 0
local function check(condition, message)
    assert(condition, message)
    checks = checks + 1
end
local state = { actions = {}, macros = {}, updates = 0, uses = 0, places = 0, edits = 0 }
local carrier = "/run if Cat2 and Cat2.ProfileMacroUnbound then Cat2.ProfileMacroUnbound() end"
state.macros[1] = { name = "Cat2Icon", texture = "carrier", body = carrier }
state.actions[7] = { name = "Cat2Icon", texture = "carrier", kind = "macro" }
state.actions[8] = { name = "OtherMacro", texture = "other", kind = "macro" }
local function region(value)
    return {
        value = value, writes = 0,
        SetText = function(self, text) self.value = text; self.writes = self.writes + 1 end,
        GetText = function(self) return self.value end,
        SetTexture = function(self, text) self.value = text; self.writes = self.writes + 1 end,
        GetTexture = function(self) return self.value end,
        SetAllPoints = function() end,
    }
end
function getglobal(name) return _G[name] end
function CreateFrame()
    local frame = { scripts = {} }
    function frame:RegisterEvent() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:Hide() self.visible = false end
    function frame:Show() self.visible = true end
    function frame:CreateTexture() return region() end
    function frame:SetWidth() end
    function frame:SetHeight() end
    function frame:SetFrameStrata(strata) if strata == "TOOLTIP" then state.preview = self end end
    function frame:SetFrameLevel() end
    function frame:EnableMouse() end
    function frame:ClearAllPoints() end
    function frame:SetPoint() end
    if not state.frame then state.frame = frame end
    return frame
end
UIParent = { GetEffectiveScale = function() return 1 end }
local function backgroundFrame(frame)
    frame.scripts = { OnMouseDown = function(...)
        state.backgroundClicks = (state.backgroundClicks or 0) + 1
        state.backgroundArgs = arg
        return "background", nil, "tail"
    end }
    function frame:GetScript(name) return self.scripts[name] end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    return frame
end
backgroundFrame(UIParent)
WorldFrame = backgroundFrame({})
function GetCursorPosition() return 100, 100 end
function GetNumMacros() return 0, 1 end
function GetMacroInfo(index)
    local macro = state.macros[index]
    if macro then return macro.name, macro.texture, macro.body end
end
function GetMacroIndexByName(name)
    for index, macro in pairs(state.macros) do if macro.name == name then return index end end
    return 0
end
function EditMacro(index, name, icon, body)
    state.edits = state.edits + 1
    if body then state.macros[index].body = body end
end
function CreateMacro() error("Existing carrier must be reused") end
function GetActionText(slot)
    local action = state.actions[slot]
    return action and action.name, "extension-type", 123
end
function GetActionTexture(slot)
    local action = state.actions[slot]
    return action and action.texture, "extension-texture"
end
function UseAction(slot, checkCursor, onSelf)
    state.uses = state.uses + 1
    state.lastUse = { slot, checkCursor, onSelf }
    return "used", nil, "tail"
end
function PickupAction(slot)
    if not state.locked then state.cursor, state.actions[slot] = state.actions[slot], nil end
    return "picked", nil, "tail"
end
function PlaceAction(slot)
    state.places = state.places + 1
    if not state.locked and state.cursor then
        state.actions[slot], state.cursor = state.cursor, state.actions[slot]
    end
    return "placed", nil, "tail"
end
function PickupMacro(index)
    local macro = state.macros[index]
    state.cursor = { name = macro.name, texture = macro.texture, kind = "macro" }
end
function PickupSpell(...)
    state.pickupArgs = arg
    state.cursor = { texture = "spell", kind = "spell" }
    return "spell", nil, "tail"
end
PickupContainerItem = PickupSpell
PickupInventoryItem = PickupSpell
function ClearCursor() state.cursor = nil end
function CursorHasSpell() return state.cursor and state.cursor.kind == "spell" end
function CursorHasItem() return state.cursor and state.cursor.kind == "item" end
if CAT2_TEST_MODERN_CURSOR then
    function GetCursorInfo() return state.cursor and state.cursor.kind end
end
ActionButton1 = { slot = 7 }
ActionButton1Name, ActionButton1Icon = region("Cat2Icon"), region("carrier")
ActionButton2 = { slot = 8 }
ActionButton2Name, ActionButton2Icon = region("OtherMacro"), region("other")
function ActionButton_GetPagedID(button) return button.slot end
function ActionButton_Update(...)
    state.updates = state.updates + 1
    state.updateArgs = arg
    return "updated", nil, "tail"
end
function ActionButton_OnClick(button)
    state.clicks = (state.clicks or 0) + 1
    if button == "RightButton" then return UseAction(this.slot, 1) end
end
GameTooltip = { lines = {} }
function GameTooltip:SetAction(slot)
    state.tooltipCalls = (state.tooltipCalls or 0) + 1
    self.lines = { "original:" .. tostring(GetActionText(slot)), "Other addon information" }
    return "tooltip", nil, "tail"
end
function GameTooltip:AddLine(text) table.insert(self.lines, text) end
function GameTooltip:Show() self.visible = true end
function GameTooltip:Hide() self.visible = false end
DEFAULT_CHAT_FRAME = { AddMessage = function(self, message) state.notice = message end }
Cat2CharacterDB = { ui = { profileMacroIcons = {
    carrierName = "Cat2Icon", carrierIndex = 1,
    slots = { [7] = { profileId = 1, carrier = "Cat2Icon" } },
} } }
Cat2 = {
    UI = {},
    RuntimeConfigurations = { activeProfileId = 2, profiles = {
        [1] = { id = 1, name = "OtherMacro", steps = { { icons = { "profile-one" } } } },
        [2] = { id = 2, name = "Second", steps = { { icons = { "profile-two" } } } },
    } },
    EnsureConfigurationDataLoaded = function() end,
    GetCardPrimaryIcon = function(step) return step.icons[1] end,
    ExecuteConfiguration = function(name) state.executed = name; return true, 1, 0 end,
}
local originalText, originalTexture = GetActionText, GetActionTexture
dofile("Cat2/UI/ProfileMacroIcon.lua")
local function tick() state.frame.scripts.OnUpdate() end
local function fire(name) event = name; state.frame.scripts.OnEvent(); event = nil end
fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
tick()
check(GetActionText == originalText, "Global macro identity changed")
local name, kind, id = GetActionText(7)
check(name == "Cat2Icon" and kind == "extension-type" and id == 123, "Macro identity / extension returns lost")
check(ActionButton1Name:GetText() == "OtherMacro", "Native configuration name missing")
check(ActionButton1Icon:GetTexture() == "profile-one", "Native configuration icon missing")
check(ActionButton2Name.writes == 0 and ActionButton2Icon.writes == 0 and state.updates == 0, "Ordinary button refreshed")
local labelWrites, iconWrites = ActionButton1Name.writes, ActionButton1Icon.writes
Cat2.UI.RefreshProfileMacroIcon()
tick()
check(ActionButton1Name.writes == labelWrites and ActionButton1Icon.writes == iconWrites, "Unchanged configuration display was rewritten")
local texture, extra = GetActionTexture(8)
check(texture == "other" and extra == "extension-texture", "Ordinary texture chain changed")
check(GetActionTexture(7) == "profile-one", "Third-party icon queries regressed")
local a, b, c = GameTooltip:SetAction(7)
check(a == "tooltip" and b == nil and c == "tail", "Tooltip return values lost")
check(GameTooltip.lines[1] == "original:Cat2Icon" and GameTooltip.lines[2] == "Other addon information", "Other tooltip information erased")
check(table.getn(GameTooltip.lines) == 4, "Configuration tooltip information missing")
GameTooltip:SetAction(8)
check(table.getn(GameTooltip.lines) == 2, "Ordinary tooltip changed")
local scanner = { lines = {}, SetAction = GameTooltip.SetAction }
scanner:SetAction(7)
check(table.getn(scanner.lines) == 2 and scanner.lines[1] == "original:Cat2Icon", "Scanner tooltip polluted")
this = ActionButton2
a, b, c = ActionButton_Update("argument", nil, "tail")
check(a == "updated" and b == nil and c == "tail" and state.updateArgs.n == 3, "Native update call contract changed")
check(ActionButton2Name.writes == 0 and ActionButton2Icon.writes == 0, "Unbound native update modified")
this = nil
Cat2.RuntimeConfigurations.profiles[1].name = "Renamed"
Cat2.UI.RefreshProfileMacroIcon()
tick()
check(ActionButton1Name:GetText() == "Renamed" and state.updates == 1, "Rename triggered whole-bar update")
UseAction(7)
check(state.executed == "Renamed" and Cat2.RuntimeConfigurations.activeProfileId == 2, "Stable-ID execution changed active profile")
PickupSpell("spell", nil, "book", "extra")
check(state.pickupArgs.n == 4 and state.pickupArgs[4] == "extra", "Pickup arguments truncated")
local placesBefore = state.places
a, b, c = UseAction(8, 1, true)
check(state.places == placesBefore and state.uses == 1 and a == "used" and c == "tail", "Ordinary cursor use bypassed original chain")
ClearCursor()
state.locked = true
PickupAction(7)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7] ~= nil, "Failed pickup lost binding")
state.locked = false
a, b, c = PickupAction(7)
check(a == "picked" and b == nil and c == "tail", "Pickup return values lost")
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7] == nil, "Moved binding remained in source")
a, b, c = PlaceAction(9)
check(a == "placed" and b == nil and c == "tail", "Place return values lost")
check(Cat2CharacterDB.ui.profileMacroIcons.slots[9].profileId == 1, "Moved binding did not follow cursor")
tick()
check(ActionButton1Name:GetText() == "" and ActionButton1Icon:GetTexture() == nil, "Source appearance not cleared")
local editsBefore = state.edits
Cat2.UI.PickupProfileMacroIcon(2)
state.locked = true
PlaceAction(8)
state.locked = false
PlaceAction(9)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[9].profileId == 2, "Incoming profile was not installed")
PlaceAction(7)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7].profileId == 1, "Outgoing profile was not preserved in swap")
check(state.edits == editsBefore, "Dragging rewrote shared macro icon")
tick()
this = ActionButton1
Cat2.UI.PickupProfileMacroIcon(2)
ActionButton_OnClick("LeftButton")
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7].profileId == 2, "Native click did not place profile")
ClearCursor()
this = nil
PickupSpell("spell")
state.locked = true
PlaceAction(7)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7].profileId == 2, "Failed replacement lost binding")
state.locked = false
UseAction(7, 1)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[7] == nil, "Ordinary action did not replace profile")
PlaceAction(10)
check(Cat2CharacterDB.ui.profileMacroIcons.slots[10].profileId == 2, "Replaced profile cursor lost")
ClearCursor()
ActionButton1Name:SetText("Other addon label")
ActionButton1Icon:SetTexture("Other addon icon")
tick()
check(ActionButton1Name:GetText() == "Other addon label" and ActionButton1Icon:GetTexture() == "Other addon icon", "Restoration overwrote another addon's display")
ActionButton1.slot = 10
ActionButton1.isBonus, ActionButton1.inTransition = true, true
fire("ACTIONBAR_PAGE_CHANGED")
tick()
check(ActionButton1Name:GetText() == "Other addon label", "Bonus bar animation appearance was overwritten")
ActionButton1.inTransition = nil
fire("UPDATE_BONUS_ACTIONBAR")
tick()
check(ActionButton1Name:GetText() == "Second", "Paged slot binding not displayed")
check(ActionButton1.texture == "profile-two", "Bonus bar cached texture not updated")
ActionButton1.slot = 8
fire("UPDATE_BONUS_ACTIONBAR")
tick()
check(ActionButton1Name:GetText() == "OtherMacro" and ActionButton1Icon:GetTexture() == "other", "Page restoration failed")
-- 右键取消必须早于原按钮的 UseAction；覆盖已有动作后不能再次交换回去。
this = ActionButton1
Cat2.UI.PickupProfileMacroIcon(2)
local cancelPlaces, cancelExecuted = state.places, state.executed
ActionButton_OnClick("RightButton")
check(state.cursor == nil and state.places == cancelPlaces and state.executed == cancelExecuted, "Right-click placed or executed held profile")
for _, displacedKind in ipairs({ "spell", "item", "macro" }) do
    state.actions[8] = { kind = displacedKind, texture = "displaced", name = displacedKind == "macro" and "OtherMacro" or nil }
    Cat2CharacterDB.ui.profileMacroIcons.slots[8] = nil
    Cat2.UI.PickupProfileMacroIcon(2)
    ActionButton_OnClick("LeftButton")
    check(state.cursor and state.cursor.kind == displacedKind, "Occupied slot did not preserve displaced action")
    cancelPlaces = state.places
    ActionButton_OnClick("RightButton")
    check(state.cursor == nil and state.places == cancelPlaces, "Right-click swapped displaced action back")
    check(Cat2CharacterDB.ui.profileMacroIcons.slots[8].profileId == 2 and state.actions[8].name == "Cat2Icon", "Cancel removed placed profile")
end
state.actions[8] = { kind = "spell", texture = "displaced" }
Cat2CharacterDB.ui.profileMacroIcons.slots[8] = nil
Cat2.UI.PickupProfileMacroIcon(2)
ActionButton_OnClick("LeftButton")
PlaceAction(11)
check(state.cursor == nil and state.actions[11].kind == "spell", "Displaced action could not be placed elsewhere")
local clicksBefore = state.clicks or 0
ActionButton_OnClick("RightButton")
check(state.clicks == clicksBefore + 1, "Finished swap still intercepted ordinary right-click")
ClearCursor()
this = nil
-- 两个配置互换后，场景左右键取消；包括原生已清游标但没有 HIDEGRID 的情况。
for _, background in ipairs({ WorldFrame, UIParent }) do
    for _, button in ipairs({ "LeftButton", "RightButton" }) do
        for _, nativeCleared in ipairs({ false, true }) do
            state.actions[12] = { name = "Cat2Icon", texture = "carrier", kind = "macro" }
            Cat2CharacterDB.ui.profileMacroIcons.slots[12] = { profileId = 1, carrier = "Cat2Icon" }
            Cat2.UI.PickupProfileMacroIcon(2)
            PlaceAction(12)
            check(state.preview.visible and state.preview.profileId == 1, "Swapped profile preview missing")
            if nativeCleared then state.cursor = nil end
            -- 1.12 使用全局 arg1，不向脚本传参。
            arg1 = button
            local first, middle, last = background:GetScript("OnMouseDown")()
            arg1 = nil
            check(first == "background" and middle == nil and last == "tail", "Background script return chain changed")
            check(state.cursor == nil and not state.preview.visible, "Background cancellation left cursor or ghost preview")
            check(Cat2CharacterDB.ui.profileMacroIcons.slots[12].profileId == 2, "Cancellation lost installed profile")
            PlaceAction(13)
            check(state.actions[13] == nil and Cat2CharacterDB.ui.profileMacroIcons.slots[13] == nil, "Cancelled swap left stale profile binding")
        end
    end
end
PickupSpell("ordinary")
WorldFrame:GetScript("OnMouseDown")("LeftButton", nil, "extension")
check(state.cursor and state.cursor.kind == "spell" and state.backgroundArgs.n == 3, "Ordinary background cursor or script arguments changed")
ClearCursor()
Cat2.RuntimeConfigurations.profiles[2] = nil
state.executed = nil
UseAction(10)
check(state.executed == nil and state.notice ~= nil, "Deleted profile executed")
-- 配置更改及动作条事件没有再触发整套原生刷新。
check(state.updates == 1, "Cat2 triggered unrelated native refreshes")
return checks
