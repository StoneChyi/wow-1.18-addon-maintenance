--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

CleveRoids.Hooks = CleveRoids.Hooks or {}

local Extension = CleveRoids.RegisterExtension("Grid")
Extension.RegisterEvent("ADDON_LOADED", "OnLoad")

function Extension.OnEnter(unit)
    CleveRoids.SetMouseoverFrom("grid", unit)
end

function Extension.OnLeave()
    CleveRoids.ClearMouseoverFrom("grid")
    CleveRoids.ClearMouseoverFrom("native")
end

function Extension.OnLoad()
    -- 修复：Grid 按字母序在本插件之前加载，其 ADDON_LOADED 事件已错过（原 arg1 守卫永不通过）；
    -- InitializeExtensions 调用本函数时也不带参数，改用 IsAddOnLoaded 判断 by 武藤纯子酱 2026.8.31
    -- 修复：OnLoad 由 ADDON_LOADED 或 InitializeExtensions 触发，两者全局 arg1 均非 nil
    -- （InitializeExtensions 在 CRM 的 ADDON_LOADED 处理器内调用，arg1=当前插件名），
    -- 原 arg1~=nil 守卫会让 IsAddOnLoaded 兜底永不执行 → 改为无条件 IsAddOnLoaded
    -- by 武藤纯子酱 2026.9.11
    if not (IsAddOnLoaded and IsAddOnLoaded("Grid")) then return end
    -- 修复：GridFrame 链路（frameClass/prototype）缺中间守卫，Grid 版本差异时报错 by 武藤纯子酱 2026.9.9
    if not (GridFrame and GridFrame.frameClass and GridFrame.frameClass.prototype) then return end
    -- 去重：OnLoad 会随每次 ADDON_LOADED 触发（IsAddOnLoaded 恒真），避免重复包装 by 武藤纯子酱 2026.9.11
    if Extension.__cr_hooked then return end

    CleveRoids.Hooks.Grid = { CreateFrames = GridFrame.frameClass.prototype.CreateFrames}
    GridFrame.frameClass.prototype.CreateFrames = CleveRoids.GrdCreateFrames
    Extension.__cr_hooked = true
end

-- Taken from GridFrame.lua and added OnEnter and OnLeave scripts
function CleveRoids:GrdCreateFrames()
	-- create frame
	--self.frame = CreateFrame("Button", nil, UIParent)
	local f = self.frame

	f:SetScript("OnEnter", function()
        Extension.OnEnter(self.unit)
    end)
	f:SetScript("OnLeave", function()
        Extension.OnLeave()
    end)

	-- f:Hide()
	f:EnableMouse(true)
	f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
	f:SetWidth(GridFrame:GetFrameSize())
	f:SetHeight(GridFrame:GetFrameSize())

	-- only use SetScript pre-TBC
	-- 修复：Grid/GridFrame_OnClick/GridFrame_OnAttributeChanged 全局可能不存在，加守卫
	-- by 武藤纯子酱 2026.9.11
	if Grid and Grid.isTBC then
		f:SetAttribute("type1", "target")
	else
		f:SetScript("OnClick", function () if GridFrame_OnClick then GridFrame_OnClick(f, arg1) end end)
		if GridFrame_OnAttributeChanged then
			f:SetScript("OnAttributeChanged", GridFrame_OnAttributeChanged)
		end
	end

	-- create border
	f:SetBackdrop({
		bgFile = "Interface\\Addons\\Grid\\white16x16", tile = true, tileSize = 16,
		edgeFile = "Interface\\Addons\\Grid\\white16x16", edgeSize = 1,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	f:SetBackdropBorderColor(0,0,0,0)
	f:SetBackdropColor(0,0,0,1)

	-- create bar BG (which users will think is the real bar, as it is the one that has a shiny color)
	-- this is necessary as there's no other way to implement status bars that grow in the other direction than normal
	f.BarBG = f:CreateTexture()
	f.BarBG:SetTexture("Interface\\Addons\\Grid\\gradient32x32")
	f.BarBG:SetPoint("CENTER", f, "CENTER")
	f.BarBG:SetWidth(GridFrame:GetFrameSize()-4)
	f.BarBG:SetHeight(GridFrame:GetFrameSize()-4)

	-- create bar
	f.Bar = CreateFrame("StatusBar", nil, f)
	f.Bar:SetStatusBarTexture("Interface\\Addons\\Grid\\gradient32x32")
	f.Bar:SetOrientation("VERTICAL")
	f.Bar:SetMinMaxValues(0,100)
	f.Bar:SetValue(100)
	f.Bar:SetStatusBarColor(0,0,0,0.8)
	f.Bar:SetPoint("CENTER", f, "CENTER")
	f.Bar:SetFrameLevel(4)
	f.Bar:SetWidth(GridFrame:GetFrameSize()-4)
	f.Bar:SetHeight(GridFrame:GetFrameSize()-4)

	-- create center text
	f.Text = f.Bar:CreateFontString(nil, "ARTWORK")
	f.Text:SetFontObject(GameFontHighlightSmall)
	f.Text:SetFont(STANDARD_TEXT_FONT,8)
	f.Text:SetJustifyH("CENTER")
	f.Text:SetJustifyV("CENTER")
	f.Text:SetPoint("CENTER", f, "CENTER")

	-- create icon
	f.Icon = f.Bar:CreateTexture("Icon", "OVERLAY")
	f.Icon:SetWidth(16)
	f.Icon:SetHeight(16)
	f.Icon:SetPoint("CENTER", f, "CENTER")
	f.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	f.Icon:SetTexture(1,1,1,0) --"Interface\\Icons\\INV_Misc_Orb_02"

	-- set texture
	f:SetNormalTexture(1,1,1,0)
	f:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

	self.frame = f

	-- set up click casting
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[self.frame] = true
end

_G["CleveRoids"] = CleveRoids
