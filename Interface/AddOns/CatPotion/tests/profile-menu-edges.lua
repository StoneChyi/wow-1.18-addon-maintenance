-- Run from Interface/AddOns. Exercise actual dropdown positioning and pagination.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
local ui = addon.Windows[db.defaultProfileId]
local rootScale, profileScale = 1, 1
local anchorX, anchorY = 400, 500
local screenWidth, screenHeight = 800, 600
local assertions = 0
UIParent.GetEffectiveScale = function() return rootScale end
-- Vanilla anchor-sized getters can already include scale; edge coordinates
-- remain in the frame's own coordinate system. Test both getter models.
local anchorSizedRoot = true
UIParent.GetWidth = function() return screenWidth * (anchorSizedRoot and rootScale or 1) end
UIParent.GetHeight = function() return screenHeight * (anchorSizedRoot and rootScale or 1) end
UIParent.GetLeft = function() return 0 end
UIParent.GetRight = function() return screenWidth end
UIParent.GetBottom = function() return 0 end
UIParent.GetTop = function() return screenHeight end
ui.window.GetEffectiveScale = function() return rootScale * profileScale end
ui.profileSwitchButton.GetEffectiveScale = function() return rootScale * profileScale end
ui.profileSwitchButton.GetCenter = function() return anchorX / profileScale, anchorY / profileScale end
ui.profileMenu.GetEffectiveScale = function() return rootScale * profileScale * ui.profileMenu:GetScale() end
local function Check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end
local function Bounds()
    local menu = ui.profileMenu
    local point = menu.point
    local scale = menu:GetEffectiveScale()
    local width, height = menu:GetWidth() * scale, menu:GetHeight() * scale
    local left, bottom
    if point[1] == "BOTTOMLEFT" and point[2] == UIParent then
        left, bottom = point[4] * scale, point[5] * scale
    else
        -- Original fixed anchor: right-align below the switch, even outside screen.
        left = anchorX * rootScale + 11 * rootScale * profileScale - width
        bottom = anchorY * rootScale - 11 * rootScale * profileScale - 4 * scale - height
    end
    return left, bottom, left + width, bottom + height
end
local function OpenAndCheck(message)
    ui.profileMenu:Hide()
    this = ui.profileSwitchButton
    this.scripts.OnClick()
    Check(ui.profileMenu:IsVisible(), message .. ": menu opens")
    local left, bottom, right, top = Bounds()
    local margin = 8 * rootScale
    Check(left >= margin - 0.01, message .. ": left edge visible")
    Check(bottom >= margin - 0.01, message .. ": bottom edge visible")
    Check(right <= screenWidth * rootScale - margin + 0.01, message .. ": right edge visible")
    Check(top <= screenHeight * rootScale - margin + 0.01, message .. ": top edge visible")
    return left, bottom, right, top
end
for i = #db.profileOrder + 1, 12 do addon.CreateProfile("边缘菜单测试" .. i) end
anchorX, anchorY = 20, 500
OpenAndCheck("left edge")
anchorX, anchorY = 400, 20
local left, bottom = OpenAndCheck("bottom edge")
Check(bottom > anchorY * rootScale, "bottom edge menu opens upwards")
anchorX, anchorY = 790, 590
OpenAndCheck("top right corner")
anchorX, anchorY = 790, 20
OpenAndCheck("bottom right corner")
anchorX, anchorY = 20, 20
OpenAndCheck("bottom left corner")
anchorX, anchorY = 400, 500
left, bottom = OpenAndCheck("middle")
Check(bottom < anchorY * rootScale, "middle menu opens downwards")
for _, scale in ipairs({ 0.5, 0.8, 1.5 }) do
    rootScale, profileScale = 0.75, scale
    anchorX, anchorY = 790, 20
    OpenAndCheck("scaled corner " .. scale)
end

-- In free space the menu must stay attached, not merely remain on screen.
-- Both legacy anchor-sized and explicit-size roots must yield the same result.
screenWidth, screenHeight, anchorX, anchorY = 1200, 800, 1100, 600
for _, sizeModel in ipairs({ true, false }) do
    anchorSizedRoot = sizeModel
    for _, scale in ipairs({ 0.6, 0.75, 1, 1.25 }) do
        rootScale = scale
        for _, windowScale in ipairs({ 0.5, 0.7, 1, 1.5 }) do
            profileScale = windowScale
            local x, y, right, top = OpenAndCheck("attached root " .. scale .. " window " .. windowScale)
            local buttonRight = (anchorX + 11 * profileScale) * rootScale
            local buttonBottom = (anchorY - 11 * profileScale) * rootScale
            Check(math.abs(right - buttonRight) < 0.01, "menu remains right-aligned with triangle")
            Check(math.abs(top - (buttonBottom - 4 * ui.profileMenu:GetEffectiveScale())) < 0.01,
                "menu retains four-unit gap below triangle")
        end
    end
end
-- Paging and reopening must not detach the menu or move the main window.
local windowPoint = ui.window.point
local _, _, expectedRight, expectedTop = Bounds()
this = ui.profileMenuNext
this.scripts.OnClick()
local _, _, pagedRight, pagedTop = Bounds()
Check(math.abs(pagedRight - expectedRight) < 0.01 and math.abs(pagedTop - expectedTop) < 0.01,
    "paging preserves attachment")
OpenAndCheck("reopened menu")
local _, _, reopenedRight, reopenedTop = Bounds()
Check(math.abs(reopenedRight - expectedRight) < 0.01 and math.abs(reopenedTop - expectedTop) < 0.01,
    "reopening preserves attachment")
Check(ui.window.point == windowPoint, "opening and paging never re-anchor main window")

-- Missing or degenerate root geometry must not write an invalid position.
local menuPoint = ui.profileMenu.point
UIParent.GetTop = function() return nil end
ui.RefreshProfileMenu()
Check(ui.profileMenu.point == menuPoint, "missing geometry preserves last menu anchor")
UIParent.GetTop = function() return 0 end
ui.RefreshProfileMenu()
Check(ui.profileMenu.point == menuPoint, "zero height preserves last menu anchor")
UIParent.GetTop = function() return screenHeight end
UIParent.GetRight = function() return -1 end
ui.RefreshProfileMenu()
Check(ui.profileMenu.point == menuPoint, "negative width preserves last menu anchor")
UIParent.GetRight = function() return screenWidth end

-- Small viewport must still expose every profile through scrolling and buttons.
rootScale, profileScale = 1, 1.5
screenWidth, screenHeight = 240, 150
anchorX, anchorY = 230, 20
OpenAndCheck("small viewport")
Check(ui.profileMenuNext:IsVisible(), "small viewport pagination visible")
local visited = {}
for i = 1, #db.profileOrder do
    for _, entry in ipairs(ui.profileMenuEntries) do
        if entry:IsVisible() then visited[entry.targetProfileId] = true end
    end
    this = ui.profileMenuNext
    this.scripts.OnClick()
    local x, y, right, top = Bounds()
    Check(y >= 8 and top <= screenHeight - 8 + 0.01, "paging preserves screen position")
end
for _, id in ipairs(db.profileOrder) do Check(visited[id], "every profile reachable: " .. id) end
ui.profileMenuOffset = 0
ui.RefreshProfileMenu()
this, arg1 = ui.profileMenu, -1
this.scripts.OnMouseWheel()
Check(ui.profileMenuOffset == 1, "mouse wheel still scrolls profiles")
print("PASS: " .. assertions .. " dropdown edge, scale and pagination assertions")
