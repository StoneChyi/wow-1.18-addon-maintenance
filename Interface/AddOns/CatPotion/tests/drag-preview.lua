-- Run from Interface/AddOns. Verify cursor following without moving real rows,
-- scale conversion, mouse transparency, icon identity and drag cleanup.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
local ui = addon.Windows[db.activeProfileId]
local profile = db.profiles[db.activeProfileId]
local shift, rootScale, sourceScale, cursorX, cursorY = false, 0.75, 1.2, 384, 216
local mouseRow, now, uses, assertions = nil, 1000, 0, 0
GetTime = function() return now end
GetScreenWidth = function() return 1600 end
GetScreenHeight = function() return 900 end
GetCursorPosition = function() return cursorX, cursorY end
IsShiftKeyDown = function() return shift and 1 or nil end
MouseIsOver = function(row) return mouseRow == row and 1 or nil end
GetMouseFocus = function() return mouseRow end
UIParent.GetEffectiveScale = function() return rootScale end
ui.window.GetEffectiveScale = function() return rootScale * sourceScale end
addon.GetBuffTime = function() return 0 end
addon.UseItem = function() uses = uses + 1 end
profile.selected = { mongoose = 1, majorHealing = 1 }
profile.weaponSlots, profile.windowOrder = {}, {}
profile.windowVisible = 1
ui.RefreshPotionRows()
ui.window:Show()
local source, target = ui.rows[1], ui.rows[2]
for _, row in ipairs(ui.rows) do
    row.icon.SetAlpha = function(self, value) self.testAlpha = value end
    row.icon.GetTexture = function(self) return rawget(self, "testTexture") end
end
source.icon.testTexture = "Interface\\Icons\\BagTexture"
local baseCreate = CreateFrame
CreateFrame = function(...)
    local frame = baseCreate(...)
    frame.GetEffectiveScale = function(self) return rootScale * self:GetScale() end
    frame.EnableMouse = function(self, enabled) self.mouseEnabled = enabled end
    frame.SetFrameStrata = function(self, strata) self.strata = strata end
    local basePoint, baseTexture = frame.SetPoint, frame.CreateTexture
    frame.SetPoint = function(self, ...)
        self.pointWrites = (rawget(self, "pointWrites") or 0) + 1
        basePoint(self, ...)
    end
    frame.CreateTexture = function(self, ...)
        local texture = baseTexture(self, ...)
        texture.SetTexture = function(self, value) self.testTexture = value end
        return texture
    end
    return frame
end
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function Near(actual, expected, label)
    assert(math.abs(actual - expected) < 0.001, label)
    assertions = assertions + 1
end
local function Start(row)
    this = row
    row.scripts.OnDragStart()
end
local function Tick()
    this = ui.dragPreview
    ui.dragPreview.scripts.OnUpdate()
end
local function Stop(row, destination)
    mouseRow, this = destination, row
    row.scripts.OnDragStop()
end
local function CheckPosition(label)
    local preview = ui.dragPreview
    local scale = preview:GetEffectiveScale()
    Equal(preview.point[1], "CENTER", label .. " follows icon center")
    Equal(preview.point[2], UIParent, label .. " screen anchor")
    Near(preview.point[4] * scale, cursorX, label .. " horizontal physical cursor coordinate")
    Near(preview.point[5] * scale, cursorY, label .. " vertical physical cursor coordinate")
end
Start(source)
Equal(ui.dragPreview, nil, "ordinary drag does not allocate preview")
shift = true
local sourcePoint, targetPoint, windowPoint = source.point, target.point, ui.window.point
Start(source)
local preview = ui.dragPreview
Equal(preview:IsVisible(), true, "Shift drag shows preview immediately")
Equal(preview.strata, "TOOLTIP", "preview above potion windows")
Equal(preview.mouseEnabled, false, "preview cannot intercept drop target")
Equal(preview:GetWidth(), 38, "icon preview width")
Equal(preview:GetHeight(), 38, "icon preview height")
Equal(preview.icon.testTexture, source.icon.testTexture, "uses currently displayed bag texture")
Equal(source.icon.testAlpha, 0.35, "source icon dims while dragged")
Near(preview:GetEffectiveScale(), rootScale * sourceScale, "preview matches source window scale")
CheckPosition("initial drag")
cursorX, cursorY = 900, 580
Tick()
CheckPosition("moved cursor")
Equal(source.point, sourcePoint, "cursor update does not move source row")
Equal(target.point, targetPoint, "cursor update does not move destination row")
Equal(ui.window.point, windowPoint, "cursor update does not move main window")
local pointWrites = preview.pointWrites
Tick()
Equal(preview.pointWrites, pointWrites, "stationary cursor does not rewrite native anchor")
shift = false
cursorX, cursorY = 880, 520
Tick()
CheckPosition("modifier released during drag")
this, arg1 = source, "LeftButton"
source.scripts.OnClick()
Equal(uses, 0, "click during drag cannot consume item")
Stop(source, target)
Equal(preview:IsVisible(), false, "successful drop hides preview")
Equal(preview.scripts.OnUpdate, nil, "successful drop stops animation updates")
Equal(source.icon.testAlpha, 1, "successful drop restores source icon")
Equal(table.concat(profile.windowOrder, ","), "majorHealing,mongoose", "drop still swaps positions")

shift = true
sourceScale = 0.5
profile.minimized = 1
-- The actual row data is still unchanged until the deferred layout, so select
-- the second row to verify preview reuse with another item/static texture.
Start(target)
Equal(ui.dragPreview, preview, "preview frame reused for next drag")
Equal(preview.icon.testTexture, addon.GetItemTexture(target.itemData), "missing bag texture uses correct static icon")
Near(preview:GetEffectiveScale(), rootScale * 0.5, "compact small window scale inherited")
CheckPosition("small compact drag")
cursorX, cursorY = 0, 0
Tick()
CheckPosition("screen corner")
Stop(target, nil)
Equal(preview:IsVisible(), false, "outside drop hides preview")
Equal(preview.scripts.OnUpdate, nil, "outside drop stops animation")
Equal(target.icon.testAlpha, 1, "cancel restores source icon")
Equal(table.concat(profile.windowOrder, ","), "majorHealing,mongoose", "outside drop preserves order")

Start(source)
this = ui.window
ui.window.scripts.OnHide()
Equal(preview:IsVisible(), false, "window hide clears root-parented preview")
Equal(preview.scripts.OnUpdate, nil, "window hide stops animation")
Equal(source.icon.testAlpha, 1, "window hide restores source icon")
Start(source)
ui.window:Hide() -- Defensive update cleanup even if a hide callback was missed.
Tick()
Equal(preview:IsVisible(), false, "hidden source window cannot leave floating icon")
Equal(ui.dragSourceKey, nil, "hidden source cancels drag")
ui.window:Show()
Start(source)
ui.Dispose()
Equal(preview:IsVisible(), false, "deleted/disposed window clears preview")
Equal(preview.scripts.OnUpdate, nil, "disposed window stops animation")
Equal(source.icon.testAlpha, 1, "disposed window restores original icon")
Equal(uses, 0, "preview never sends item use requests")
print("PASS: " .. assertions .. " cursor drag preview assertions")
