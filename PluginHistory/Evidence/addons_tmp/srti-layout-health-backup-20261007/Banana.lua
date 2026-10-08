local YELLOW = "|c00f7f26c"
local ORANGE = "|c00f69218"
local WHITE = "|c00e7e4d9"
local MAGENTA = "|c00cb32dd"
local GREEN = "|c000fb20a"
local LGREEN = "|c00c0ffc0"
local BLUE = "|c00007aff"
local LBLUE = "|c008cb0c5"
local RED = "|c00d7422e"

local FORMAT_PRINT = LGREEN.."["..GREEN.."SRTI"..LGREEN.."] %s"..FONT_COLOR_CODE_CLOSE

-- Bindings（改的是显示名；Bindings.xml 里的 name 属性才是绑定 ID，不能动）
BINDING_HEADER_BANANA_PLUGINNAME = "SRTI 标记助手"
BINDING_NAME_BANANA_TARGET_SYMBOL1 = "定位标记 1（"..RAID_TARGET_1.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL2 = "定位标记 2（"..RAID_TARGET_2.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL3 = "定位标记 3（"..RAID_TARGET_3.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL4 = "定位标记 4（"..RAID_TARGET_4.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL5 = "定位标记 5（"..RAID_TARGET_5.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL6 = "定位标记 6（"..RAID_TARGET_6.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL7 = "定位标记 7（"..RAID_TARGET_7.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL8 = "定位标记 8（"..RAID_TARGET_8.."）"
BINDING_NAME_BANANA_TARGET_SYMBOL9 = "定位标记 9（猎人印记）"

-- Saved Variables
BANANA_CONFIG = {}
BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
BANANA_CONFIG.BUTTON_LAYOUT = 1
BANANA_CONFIG.BUTTON_SCALE = 100
BANANA_CONFIG.DISABLE_SOUND = 1
BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
BANANA_CONFIG.GREY_OUT_DEATH = 1
BANANA_CONFIG.POS = {}
BANANA_CONFIG.SHOW_IN_RAID = 1
BANANA_CONFIG.SHOW_IN_PARTY = 1
BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
BANANA_CONFIG.SHOW_EXTRA_INFO = nil
BANANA_CONFIG.FLIP = 0
BANANA_CONFIG.DETACH = 0
BANANA_CONFIG.ENABLED = 1

-- Slash Command：/srti 无参数开关设置面板，带数字参数（1-9）反向寻标
SLASH_SRTI1 = "/srti"

local function Banana_Slash(arg)
	if ( arg == "debug" ) then
		Banana_DebugButtons()
	elseif ( tonumber(arg) ) then
		Banana_TargetCommand(arg)
	else
		Banana_Toggle()
	end
end

local raidTargetIconTexCoords = {}
raidTargetIconTexCoords[1] = { ULx = 0, 	ULy = 0 	}
raidTargetIconTexCoords[2] = { ULx = 0.25,  ULy = 0 	}
raidTargetIconTexCoords[3] = { ULx = 0.5, 	ULy = 0 	}
raidTargetIconTexCoords[4] = { ULx = 0.75, 	ULy = 0 	}
raidTargetIconTexCoords[5] = { ULx = 0, 	ULy = 0.25 	}
raidTargetIconTexCoords[6] = { ULx = 0.25, 	ULy = 0.25 	}
raidTargetIconTexCoords[7] = { ULx = 0.5, 	ULy = 0.25 	}
raidTargetIconTexCoords[8] = { ULx = 0.75, 	ULy = 0.25 	}

local huntersMark = "Interface\\Icons\\Ability_Hunter_SniperShot"
local superwow = SetAutoloot and true or false
local shaguPlates = nil
local icons = {}

-- 前向声明：存/标按钮（Banana_SetEnabled 等定义在前处引用，必须提前声明，否则引用的是全局 nil）
local SRTI_SaveBtn
local SRTI_SaveBtnTex

local function Banana_Print(msg)
	local strx = string.format(FORMAT_PRINT, tostring(msg))
	DEFAULT_CHAT_FRAME:AddMessage(strx)
end

local function Banana_Error(msg)
	if BANANA_CONFIG.DISABLE_ERROR_TEXT ~= 1 then
		local strx = string.format(FORMAT_PRINT, tostring(msg))
		DEFAULT_CHAT_FRAME:AddMessage(strx)
	end
end

local function InGroupOrRaid()
	return ((GetNumPartyMembers() + GetNumRaidMembers()) > 0)
end

-- 诊断：/srti debug —— 逐格打印按钮类型、勾选状态与全部 region（排查底纹/纹理残留用）
function Banana_DebugButtons()
	for i = 1, 9 do
		local b = icons[i] and icons[i].FrameButton
		if ( b ) then
			local info = "按钮"..i.." "..tostring(b:GetName())
			local ok, t = pcall(function() return b:GetObjectType() end)
			if ( ok ) then info = info.." 类型="..tostring(t) end
			ok, t = pcall(function() return b:GetChecked() end)
			if ( ok ) then info = info.." 勾选="..tostring(t) end
			ok, t = pcall(function() return b:GetCheckedTexture() end)
			if ( ok ) then info = info.." 勾选纹理="..tostring(t) end
			Banana_Print(info)
			ok, t = pcall(function() return b:GetRegions() end)
			if ( ok and t ) then
				for k, r in ipairs(t) do
					if ( r ) then
						local rn, rt, vis = "无名", "?", "?"
						pcall(function() if r.GetName then rn = tostring(r:GetName()) end end)
						pcall(function() if r.GetTexture then rt = tostring(r:GetTexture()) end end)
						pcall(function() vis = tostring(r:IsShown()) end)
						Banana_Print("    region"..k.." 名称="..rn.." 贴图="..rt.." 显示="..vis)
					end
				end
			end
		end
	end
end

function Banana_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	SlashCmdList["SRTI"] = Banana_Slash
end

function Banana_OnEvent()
	if ( event == "ADDON_LOADED" ) and arg1 == "SimpleRaidTargetIcons" then
		this:UnregisterEvent("ADDON_LOADED")
		SRTI_ApplyToolDefaults()
		for i = 1, 9 do
			icons[i] = {}
			icons[i].FrameIcon = getglobal("RaidTargetFrame"..i.."ButtonIcon")
			icons[i].FrameButton = getglobal("RaidTargetFrame"..i.."Button")
			icons[i].FrameFlash = getglobal("RaidTargetFrame"..i.."ButtonFlash")
			icons[i].FrameHotKey = getglobal("RaidTargetFrame"..i.."ButtonHotKey")
			icons[i].FrameName = getglobal("RaidTargetFrame"..i.."ButtonName")
			icons[i].FrameCount = getglobal("RaidTargetFrame"..i.."ButtonCount")
			icons[i].FrameMobName = getglobal("RaidTargetFrame"..i.."ButtonMobName")
			icons[i].FrameTargetSymbol = getglobal("RaidTargetFrame"..i.."ButtonTargetSymbol")
			icons[i].Count = 0
			icons[i].Target = nil
			icons[i].Info = nil
			icons[i].Debuff = nil
			icons[i].MovingButton = 1
			icons[i].IsDeath = nil
			icons[i].MyTarget = nil
			icons[i].Players = {}
			for j = 1, 40 do
				icons[i].Players[j] = { Name = "", Color = { r = .0, g = .0, b = .0 }}
			end
		end
		Banana_Print("标记条已加载。输入 /srti 打开设置面板。")
		Banana_Print("左键定位标记单位 / 右键或 Ctrl+左键标记当前目标")
		Banana_Print("Ctrl + 右键拖动按钮 / Alt + 左键清除全部标记")

		if not BANANA_CONFIG.SHOW_EXTRA_INFO then
			UIDropDownMenu_Initialize(BananaConfigFrameComboBoxLayout, Banana_ComboBoxLayout_Initialize)
			Banana_Default()
			BananaConfigFrame:Show()
		else
			Banana_UpdateScale()
			Banana_Layout()
			Banana_ReloadFramePositions()
		UIDropDownMenu_Initialize(BananaConfigFrameComboBoxLayout, Banana_ComboBoxLayout_Initialize)
		Banana_UpdateDialogFromVariables()
	end
	SRTI_InitSaveBtn()
	SRTI_InitTools()
	end
end


-- 总开关：关闭时停掉 OnUpdate 定时器并隐藏全部按钮，做到零常驻开销
function Banana_SetEnabled(on)
	BANANA_CONFIG.ENABLED = on and 1 or 0
	if ( BANANA_CONFIG.ENABLED == 1 ) then
		BananaFrame:SetScript("OnUpdate", Banana_OnUpdate)
		Banana_UpdateStatus()
	else
		BananaFrame:SetScript("OnUpdate", nil)
		for i = 1, 9 do
			local b = getglobal("RaidTargetFrame"..i.."Button")
			if ( b ) then b:Hide() end
		end
		if SRTI_SaveBtn then SRTI_SaveBtn:Hide() end
	end
	SRTI_UpdateTools()
end

local attempts = 0
function Banana_OnUpdate()
	if BANANA_CONFIG.ENABLED ~= 1 then return end
	if (this.tick or 0.2) > GetTime() then
		return
	else
		this.tick = GetTime() + 0.2
	end
	Banana_UpdateStatus()
    Banana_CtRaMainTankUpdate()
	if attempts > 0 then
		Banana_SetSymbol("player", 0)
		attempts = attempts - 1
	end
end

-- 图标统一改用 SRTI 自带贴图（1..8 标记 + 9 猎人印记），风格一致
local SRTI_TEX = {
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\star",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\nipple",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\diamond",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\triangle",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\moon",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\square",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\cross",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\skull",
	"Interface\\AddOns\\SimpleRaidTargetIcons\\img\\huntermark",
};

local function Banana_TexCoord(icon,index)
	local tex = SRTI_TEX[index]
	if ( tex ) then
		icon:SetTexture(tex)
		icon:SetTexCoord(0, 1, 0, 1)
	end
end

function Banana_RaidTargetButtonOnLoad()
	local index = this:GetID()
	local icon = getglobal(this:GetName().."Icon")
    Banana_TexCoord(icon,index)
end

function Banana_ButtonOnClick(mouseButton)
	local index = this:GetID()
	-- Alt+左键：清除全部标记（必须先判，否则会被下面的左键分支吃掉）
	if (IsAltKeyDown()) and mouseButton == "LeftButton" then
		Banana_ClearAllSymbols()
		return
	end
	-- Ctrl+左键（原有）与右键（新增的快捷标记）：给当前目标打/取消该标记
	if ( IsControlKeyDown() and mouseButton == "LeftButton" ) or ( (not IsControlKeyDown()) and (not IsAltKeyDown()) and mouseButton == "RightButton" ) then
		if not UnitExists("target") then
			Banana_TargetRaidSymbol(index)
			if not UnitExists("target") then
				Banana_Error("未选中目标。")
				Banana_PlayError()
				return
			end
		end

		local oldindex = (Banana_GetSymbol("target") or 0)
		if oldindex == index then
			Banana_SetSymbol("target", 0)
			Banana_PlayRemove1()
		else
			Banana_SetSymbol("target", index)
		end
		Banana_UpdateStatus()
		return
	end
	-- 左键：选中带该标记的单位（原有反向寻标）
	if (not IsControlKeyDown()) and (not IsAltKeyDown()) and mouseButton == "LeftButton" then
		Banana_TargetRaidSymbol(index)
		return
	end
	if (IsControlKeyDown()) and mouseButton == "RightButton" then
		--moving
		return
	end
	Banana_Print("左键定位标记单位 / 右键或 Ctrl+左键标记当前目标")
	Banana_Print("Ctrl + 右键拖动按钮 / Alt + 左键清除全部标记")
end

local movingButton = nil

function Banana_ButtonOnMouseDown(mouseButton)
	if IsControlKeyDown() and mouseButton == "RightButton" then
		local index = this:GetID()
		if not movingButton then
			if getglobal("RaidTargetFrame"..icons[index].MovingButton.."Button"):IsMovable() then
				movingButton = index
				getglobal("RaidTargetFrame"..icons[index].MovingButton.."Button"):StartMoving()
			end
		end
	end
	if (not IsControlKeyDown()) and mouseButton == "RightButton" then
		Banana_UpdateStatus()
	end
end

function Banana_ButtonOnMouseUp()
	if movingButton then
		getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"):StopMovingOrSizing()
		getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"):SetUserPlaced(false)
		Banana_SaveFramePos(getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"))
		movingButton = nil
	end
end

function Banana_ButtonOnEnter()
	if ( GetCVar("UberTooltips") == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, this)
	else
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	end
	local index = this:GetID()
	if (icons[index].Target) then
		GameTooltip:AddLine(icons[index].Target)
		local unit = icons[index].Unit
		if unit and UnitExists(unit) and Banana_GetSymbol(unit) == index then
			local maximum = UnitHealthMax(unit) or 0
			if maximum > 0 then
				local current = UnitIsDead(unit) and 0 or (UnitHealth(unit) or 0)
				GameTooltip:AddLine("生命：" .. current .. " / " .. maximum .. "（" .. math.floor(current / maximum * 100 + .5) .. "%）", .7, 1, .7)
			end
		end
		if icons[index].Count > 0 then
			GameTooltip:AddLine(icons[index].Count.." 个玩家",0.5,0.5,0.5)
			for player = 1,icons[index].Count,1 do
				if icons[index].Players[player].Name ~= "" then
					GameTooltip:AddLine(icons[index].Players[player].Name,icons[index].Players[player].Color.r,icons[index].Players[player].Color.g,icons[index].Players[player].Color.b)
				end
			end
		end
		GameTooltip:AddLine("/srti 打开设置面板",0.5,0.5,0.5)
		GameTooltip:Show()
	else
		GameTooltip:SetText("未使用\n左键：定位此标记单位\n右键 / Ctrl + 左键：标记当前目标\nAlt + 左键：清除所有标记\nCtrl + 右键：拖动按钮\n/srti 打开设置面板")
	end
end

function Banana_TargetRaidSymbol(index)
	if superwow then
		if Banana_TargetRaidSymbolUnit("mark"..index, index) then
			return
		end
	end
	for i = 1, 40 do
		if Banana_TargetRaidSymbolUnit("raid"..i, index) then
			return
		end
	end
	for i = 1, 4 do
		if Banana_TargetRaidSymbolUnit("party"..i, index) then
			return
		end
	end
	if Banana_TargetRaidSymbolUnit("player", index) then
		return
	end
	------------------------
	local parentcount = WorldFrame:GetNumChildren()
    -- 保证查询次数足够
    if parentcount < 20 then
        parentcount = 20
    end
    for i = 1, parentcount, 1 do
        TargetNearestEnemy(true)
        if Banana_TargetRaidSymbolUnit("target", index) then
            return;
        end
    end
	------------------------
	if Banana_ScanNameplates(index) then
		return
	end
	
	Banana_PlayError()
	Banana_Error("附近没有带此标记的单位。")
	Banana_UpdateStatus()
end

function Banana_TargetRaidSymbolUnit(unit, index)
	if UnitExists(unit) then
	    if ( Banana_GetSymbol(unit) == index ) then
			TargetUnit(unit)
			Banana_UpdateStatus()
			return 1
	    end

		if UnitExists(unit.."target") then
		    if ( Banana_GetSymbol(unit.."target") == index ) then
				TargetUnit(unit.."target")
				Banana_Error("目标："..(UnitName(unit.."target") or "未知"))
				return 1
		    end
		end
	end
    return nil
end

local function Banana_Reset()
	for index = 1, 9 do
		icons[index].Count = 0
    	icons[index].Target = nil
		icons[index].Unit = nil
    	icons[index].TargetSymbol = nil
		for k in pairs(icons[index].Players) do
			icons[index].Players[k].Name = ""
			icons[index].Players[k].Color.r = .0
			icons[index].Players[k].Color.g = .0
			icons[index].Players[k].Color.b = .0
		end
		icons[index].Debuff = nil
		icons[index].IsDeath = nil
		icons[index].MyTarget = nil
  	end
end

local function Banana_DebuffCheck(sUnitname, sBuffname)
	local iIterator = 1
	while (true) do
		local debuffTexture, debuffApplications, debuffDispelType = UnitDebuff(sUnitname, iIterator)
		if not debuffTexture then
			return ""
		end
		if debuffTexture == sBuffname then
			return sBuffname
		end
		iIterator = iIterator + 1
	end
end

local function Banana_HideButton(frame)
    if BananaConfigFrame:IsVisible() then
        frame:Show()
        frame:SetAlpha(0.16)
    else
        frame:Hide()
        frame:SetAlpha(1)
    end
end

-- 界面写入脏检查：只缓存幂等的文本/勾选/透明度/贴图。
-- 显隐(Show/Hide)不缓存 —— 这些按钮由暴雪原生 RaidTargetFrame 共用，显隐可能被外部改动。
local btnCache = {}
for i = 1, 9 do btnCache[i] = {} end
local btnCacheSig

local function cacheNe(prev, key, val)
	if prev[key] ~= val then
		prev[key] = val
		return true
	end
	return false
end

function Banana_UpdateStatus()
	-- 总开关/配置/面板显隐变化时让缓存整体失效，保证设置改动立即生效
	local sig = table.concat({
		tostring(BANANA_CONFIG.ENABLED or 0),
		tostring(BananaConfigFrame:IsVisible() and 1 or 0),
		tostring(BANANA_CONFIG.SHOW_IN_RAID or 0),
		tostring(BANANA_CONFIG.SHOW_IN_PARTY or 0),
		tostring(BANANA_CONFIG.SHOW_OUT_OF_GROUP or 0),
		tostring(BANANA_CONFIG.GREY_OUT_DEATH or 0),
		tostring(BANANA_CONFIG.HIDE_UNUSED_BUTTONS or 0),
		tostring(BANANA_CONFIG.SHOW_EXTRA_INFO or 0),
	}, ":")
	if sig ~= btnCacheSig then
		btnCacheSig = sig
		for i = 1, 9 do btnCache[i] = {} end
	end
	if BANANA_CONFIG.ENABLED ~= 1 then return end
	local raid = GetNumRaidMembers() > 0
	local party = GetNumPartyMembers() > 0
	local visible = (raid and BANANA_CONFIG.SHOW_IN_RAID == 1)
		or (not raid and party and BANANA_CONFIG.SHOW_IN_PARTY == 1)
		or (not raid and not party and BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1)
	if visible then
		Banana_Reset()
		if raid then Banana_ScanPlayers("raid", 40) else Banana_ScanPlayers("party", 5) end
		Banana_ScanLocalUnits()
		Banana_ScanNpcs()
		Banana_UpdateButtons()
	else
		for index = 1, 9 do
			local cur = icons[index]
			if cur then
				cur.Target = nil
				cur.Unit = nil
				SRTI_UpdateHealth(index, cur)
			end
			Banana_HideButton(getglobal("RaidTargetFrame"..index.."Button"))
		end
	end
	SRTI_UpdateTools()
end

function Banana_ScanPlayers(prefix,count)
  	for i = 1, count do
        local loopmember = prefix..i
        if loopmember == "party5" then
            loopmember = "player"
        end
        if UnitExists(loopmember) then
			local loopmembersymbol = (Banana_GetSymbol(loopmember) or 0)
            if loopmembersymbol ~= 0 then
                Banana_UpdateTargetSymbol(loopmember,loopmembersymbol)
		    	icons[loopmembersymbol].Target = UnitName(loopmember)
				
                -- loopmember has aggro?
                if UnitIsUnit(loopmember,loopmember.."targettarget") then
					icons[loopmembersymbol].Aggro = true
				end
				Banana_UpdateStatusScanTarget(loopmember,i,loopmembersymbol)
            end

            local loopmembertarget = loopmember.."target"
     
            if UnitExists(loopmembertarget) then
                local symbol = (Banana_GetSymbol(loopmembertarget) or 0)
                if symbol ~= 0 then
                    local _, englishClass = UnitClass(loopmember)
                    Banana_UpdateTargetSymbol(loopmembertarget,symbol)
                    icons[symbol].Target = UnitName(loopmembertarget)
                    icons[symbol].Count = icons[symbol].Count + 1
                    icons[symbol].Players[icons[symbol].Count].Name = UnitName(loopmember)
                    icons[symbol].Players[icons[symbol].Count].Color.r = RAID_CLASS_COLORS[englishClass].r
                    icons[symbol].Players[icons[symbol].Count].Color.g = RAID_CLASS_COLORS[englishClass].g
                    icons[symbol].Players[icons[symbol].Count].Color.b = RAID_CLASS_COLORS[englishClass].b
					Banana_UpdateStatusScanTarget(loopmembertarget,i,symbol)
                end
            end
        end
    end
end

function Banana_ScanLocalUnits()
	-- Also cover one's target/mouseover while in a raid, and marked pets.
	local units = {"player", "target", "mouseover", "pet"}
	local prefix, count = "party", GetNumPartyMembers()
	if GetNumRaidMembers() > 0 then prefix, count = "raid", GetNumRaidMembers() end
	for i = 1, count do table.insert(units, prefix..i.."pet") end
	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			local index = Banana_GetSymbol(unit) or 0
			if icons[index] then
				icons[index].Target = UnitName(unit)
				Banana_UpdateStatusScanTarget(unit, 0, index)
			end
		end
	end
end

function Banana_ScanNpcs()
	if not superwow then return end
	for i = 1, 8 do
		local unit = "mark" .. i
		if UnitExists(unit) and GetRaidTargetIndex(unit) == i then
			icons[i].Target = UnitName(unit)
			icons[i].Unit = unit
			icons[i].IsDeath = UnitIsDead(unit) and 1 or 0
		end
	end
end

function Banana_UpdateTargetSymbol(unit,symbol)
    local target = unit.."target"
    if not icons[symbol].TargetSymbol  then
        if not UnitExists(target) then
            icons[symbol].TargetSymbol = 0
        else
            local tts = Banana_GetSymbol(target) or 0
            icons[symbol].TargetSymbol = tts
        end
    end
end

function Banana_UpdateStatusScanTarget(targettype,i,index)
	icons[index].Unit = targettype
	if not icons[index].Debuff then
		icons[index].Debuff = Banana_DebuffCheck(targettype, "Interface\\Icons\\Spell_Shadow_GatherShadows")
	end

	if not icons[index].IsDeath then
		if UnitIsDead(targettype) then
			icons[index].IsDeath = 1
		else
			icons[index].IsDeath = 0
		end
	end

	if not icons[index].MyTarget then
		if UnitIsUnit(targettype, "target") then
			icons[index].MyTarget = 1
		else
			icons[index].MyTarget = 0
		end
	end
end

function Banana_UpdateButtons()
	for index = 1, 9 do
		local button = getglobal("RaidTargetFrame"..index.."Button")
		local flash = getglobal("RaidTargetFrame"..index.."ButtonFlash")
		local count = getglobal("RaidTargetFrame"..index.."ButtonCount")
		local cur = icons[index]
		local prev = btnCache[index]
		SRTI_UpdateHealth(index, cur)

		if ( cur.Target ) then
			local txt = tostring(cur.Count)
			if cacheNe(prev, "count", txt) then
				count:SetText(txt)
			end
			-- 计数：标记单位被多少人盯着（0 也照常显示，右下角那个 0 是有用的）
			count:Show()
			button:Show()

			if cur.Debuff and cur.Debuff ~= "" then
				if cacheNe(prev, "flashTex", cur.Debuff) then
					flash:ClearAllPoints()
					flash:SetPoint("TOPLEFT",button,"TOPLEFT")
					flash:SetWidth(18)
					flash:SetHeight(18)
					flash:SetTexture(cur.Debuff)
				end
				flash:Show()
			else
				flash:Hide()
			end
		else
			flash:Hide()
			count:Hide()
		end

		-- 不再向按钮下发 checked：1.12 的 CheckButton 一进入 checked 状态，就会把 checked 纹理
		-- （UI-QuickslotRed，整块纯红方底）铺到图标上方 —— 这正是那块红底纹。MyTarget 这个状态
		-- 没有任何逻辑消费者（点击处理不读 GetChecked，只有设置面板的复选框才用），所以直接不下发。

		if cur.IsDeath == 1 and BANANA_CONFIG.GREY_OUT_DEATH == 1 then
			if cacheNe(prev, "alpha", 0.33) then
				cur.FrameButton:SetAlpha(0.33)
			end
		else
			if BANANA_CONFIG.HIDE_UNUSED_BUTTONS == 1 and (not cur.Target) then
				-- 半透明占位，不 Hide：位置仍可见，也仍可点击寻标
				cur.FrameButton:Show()
				if cacheNe(prev, "alpha", 0.4) then
					cur.FrameButton:SetAlpha(0.4)
				end
			else
				if cacheNe(prev, "alpha", 1) then
					cur.FrameButton:SetAlpha(1)
				end
				cur.FrameButton:Show()
			end
		end

		if cur.Target and BANANA_CONFIG.SHOW_EXTRA_INFO == 1 and BANANA_CONFIG.SHOW_SHORT_NAME ~= 1 then
			if cacheNe(prev, "mobName", cur.Target) then
				cur.FrameMobName:SetText(cur.Target)
			end
			cur.FrameMobName:Show()
			if cur.TargetSymbol and cur.TargetSymbol ~= 0 then
				if cacheNe(prev, "tSym", cur.TargetSymbol) then
					Banana_TexCoord(cur.FrameTargetSymbol, cur.TargetSymbol)
				end
				cur.FrameTargetSymbol:Show()
			else
				cur.FrameTargetSymbol:Hide()
			end
		else
			if cacheNe(prev, "mobName", "") then
				cur.FrameMobName:SetText()
			end
			cur.FrameMobName:Hide()
			cur.FrameTargetSymbol:Hide()
		end
  	end
end

function Banana_ComboBoxLayout_Initialize()
	local info = {}

	info.text = BANANA_LAYOUT1
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 1
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT2
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 2
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT3
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 3
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT4
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 4
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT5
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 5
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)
end

function Banana_ComboBoxLayout_OnClick()
	UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, this:GetID())
	if BANANA_CONFIG.BUTTON_LAYOUT ~= this:GetID() then
		BANANA_CONFIG.BUTTON_LAYOUT = this:GetID()
		Banana_Layout()
	end
end

-- 缩放百分比显示在 10%/200% 中间（BananaConfig.xml 的 Label4，原为装饰"|"，已清空）
-- 不依赖 xml FontString 全局注册（1.12 不可靠，曾导致兜底小字发灰）：
-- 直接在 Label4 Frame 上建 FontString，GameFontNormal = 12px 黄字带黑影，与两边标签同款
function BananaConfig_UpdateScaleLabel()
	local holder = getglobal("BananaConfigFrameLabel4")
	if not holder then return end
	local t = getglobal("BananaConfigFrameScaleText")
	if not t then
		t = holder:CreateFontString("BananaConfigFrameScaleText", "OVERLAY", "GameFontNormal")
		t:SetAllPoints(holder)
		t:SetJustifyH("CENTER")
	end
	t:SetText(BANANA_CONFIG.BUTTON_SCALE .. " %")
end

function BananaConfig_ValueChangedResize()
	BANANA_CONFIG.BUTTON_SCALE = this:GetValue()
	Banana_UpdateScale()
	BananaConfig_UpdateScaleLabel()
end

function Banana_UpdateScale()
	Banana_UpdateFrameScale(RaidTargetFrame1Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame2Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame3Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame4Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame5Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame6Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame7Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame8Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame9Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	-- 存/标按钮跟随标记条一起缩放
	if SRTI_SaveBtn then
		Banana_UpdateFrameScale(SRTI_SaveBtn, BANANA_CONFIG.BUTTON_SCALE / 100)
	end
	SRTI_LayoutTools()
end

function Banana_UpdateFrameScale(frame,scale)
	if frame:IsMovable() then
		frame:ClearAllPoints()
		Banana_SaveFramePos(frame)
		frame:SetScale(scale)
		Banana_LoadFramePos(frame)
	else
		frame:SetScale(scale)
	end
end

function BananaConfig_ValueChangedShowInRaid()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_IN_RAID = 1
	else
		BANANA_CONFIG.SHOW_IN_RAID = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowInParty()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_IN_PARTY = 1
	else
		BANANA_CONFIG.SHOW_IN_PARTY = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowOutOfGroup()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
	else
		BANANA_CONFIG.SHOW_OUT_OF_GROUP = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedDisableSound()
	if this:GetChecked() then
		BANANA_CONFIG.DISABLE_SOUND = 1
	else
		BANANA_CONFIG.DISABLE_SOUND = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedDisableErrorText()
	if this:GetChecked() then
		BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
	else
		BANANA_CONFIG.DISABLE_ERROR_TEXT = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedGreyOutDeath()
	if this:GetChecked() then
		BANANA_CONFIG.GREY_OUT_DEATH = 1
	else
		BANANA_CONFIG.GREY_OUT_DEATH = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowExtraInfo()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_EXTRA_INFO = 1
	else
		BANANA_CONFIG.SHOW_EXTRA_INFO = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedHideUnused()
	if this:GetChecked() then
		BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 1
	else
		BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
	end
	Banana_UpdateStatus()
	SRTI_UpdateSaveBtnAlpha()
end

function BananaConfig_ValueChangedEnabled()
	if this:GetChecked() then
		Banana_SetEnabled(true)
	else
		Banana_SetEnabled(false)
	end
end

function Banana_Toggle()
	if BananaConfigFrame:IsVisible() then
		BananaConfigFrame:Hide()
	else
		BananaConfigFrame:Show()
	end
end

function Banana_TargetCommand(arg)
	arg = tonumber(arg)
	if arg == nil or arg == "" or arg > 9 or arg < 1 then
		Banana_Error("/srtitarget 编号（1=星形 2=圆圈 3=菱形 4=三角 5=月亮 6=方块 7=十字 8=骷髅 9=猎人印记）")
		return
	end
	Banana_TargetRaidSymbol(arg)
end

function Banana_Default()
	SRTI_ApplyToolDefaults(true)
	BANANA_CONFIG.SHOW_IN_RAID = 1
	BANANA_CONFIG.ENABLED = 1
	BANANA_CONFIG.SHOW_IN_PARTY = 1
	BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
	BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
	BANANA_CONFIG.BUTTON_LAYOUT = 3
	BANANA_CONFIG.BUTTON_SCALE = 100
	BANANA_CONFIG.DISABLE_SOUND = 1
	BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
	BANANA_CONFIG.GREY_OUT_DEATH = 1
	BANANA_CONFIG.SHOW_EXTRA_INFO = 0
	BANANA_CONFIG.FLIP = 0
	BANANA_CONFIG.DETACH = 0
	Banana_UpdateDialogFromVariables()

	Banana_UpdateScale()
	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame9Button:ClearAllPoints()
	Banana_Layout()

	local starty = -GetScreenHeight() / 5
	local startx = GetScreenWidth() / 5
	local ofsx = -70
	local ofsy = 70

	BANANA_CONFIG.POS = {
		["RaidTargetFrame1Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (0 * ofsy),
		},
		["RaidTargetFrame2Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (1 * ofsy),
		},
		["RaidTargetFrame3Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (2 * ofsy),
		},
		["RaidTargetFrame4Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (3 * ofsy),
		},
		["RaidTargetFrame5Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (0 * ofsy),
		},
		["RaidTargetFrame6Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (1 * ofsy),
		},
		["RaidTargetFrame7Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (2 * ofsy),
		},
		["RaidTargetFrame8Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (3 * ofsy),
		},
		["RaidTargetFrame9Button"] = {
			["x"] = startx - (0.5 * ofsx),
			["y"] = starty - (4 * ofsy),
		},
	}
	Banana_ReloadFramePositions()
end

function Banana_CtRaMainTankUpdate()
	-- 未安装 CT_RaidAssist 时直接退出：原先每轮白做 10 次字符串拼接 + 10 次全局查表
	if ( not CT_RATarget ) then return end
    Banana_CtRaMainTankUpdateByIndex(1)
    Banana_CtRaMainTankUpdateByIndex(2)
    Banana_CtRaMainTankUpdateByIndex(3)
    Banana_CtRaMainTankUpdateByIndex(4)
    Banana_CtRaMainTankUpdateByIndex(5)
    Banana_CtRaMainTankUpdateByIndex(6)
    Banana_CtRaMainTankUpdateByIndex(7)
    Banana_CtRaMainTankUpdateByIndex(8)
    Banana_CtRaMainTankUpdateByIndex(9)
    Banana_CtRaMainTankUpdateByIndex(10)
end

function Banana_CtRaMainTankUpdateByIndex(mtindex)
    local ctraframe = "CT_RAMTGroupMember"..mtindex.."CastFrame"
    if getglobal(ctraframe) == nil then
        return
    end

    local frameName = "BananaMt"..mtindex
    local texName = "BananaMt"..mtindex.."Symbol"

    local f
	if getglobal(frameName) == nil then
		f = CreateFrame("Frame", frameName, getglobal(ctraframe), "BananaMtSymbolTemplate")
		f:SetFrameStrata("BACKGROUND")
        f:SetPoint("RIGHT", ctraframe, "LEFT", 0, 0)
        f:Hide()
    else
        f = getglobal(frameName)
    end

    local tex = getglobal(texName)

    if CT_RATarget then
        if CT_RATarget.MainTanks then
            if CT_RATarget.MainTanks[mtindex] then
                if CT_RATarget.MainTanks[mtindex][1] then
                    if UnitExists("raid"..CT_RATarget.MainTanks[mtindex][1].."target") then
                        local idx = (Banana_GetSymbol("raid"..CT_RATarget.MainTanks[mtindex][1].."target") or 0)
                        if idx ~= 0 then
                            Banana_TexCoord(tex,idx)
                            f:Show()
                            return
                        end
                    end
                end
            end
        end
    end
    f:Hide()
end

function Banana_ClearAllSymbols()
    Banana_PlayRemoveAll()
	for i = 1, 8 do
    	Banana_SetSymbol("player", i)
	end
	attempts = 10
end

function Banana_SaveFramePos(frame)
	if frame then
		if frame:GetLeft() and frame:GetBottom() then
			local framePos = {}
			framePos.x = frame:GetLeft() * frame:GetScale()
			framePos.y = frame:GetTop() * frame:GetScale() - GetScreenHeight()
			if not BANANA_CONFIG.POS then
				BANANA_CONFIG.POS = {}
			end
			BANANA_CONFIG.POS[frame:GetName()] = framePos
		end
	end
end

function Banana_LoadFramePos(frame)
	if frame then
		if frame:IsMovable() then
			if BANANA_CONFIG.POS then
				local framePos = BANANA_CONFIG.POS[frame:GetName()]
				if framePos then
					frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", framePos.x / frame:GetScale(), framePos.y / frame:GetScale())
				end
			end
		end
	end
end

function Banana_ReloadFramePositions()
	Banana_LoadFramePos(RaidTargetFrame1Button)
	Banana_LoadFramePos(RaidTargetFrame2Button)
	Banana_LoadFramePos(RaidTargetFrame3Button)
	Banana_LoadFramePos(RaidTargetFrame4Button)
	Banana_LoadFramePos(RaidTargetFrame5Button)
	Banana_LoadFramePos(RaidTargetFrame6Button)
	Banana_LoadFramePos(RaidTargetFrame7Button)
	Banana_LoadFramePos(RaidTargetFrame8Button)
	Banana_LoadFramePos(RaidTargetFrame9Button)
end

local movingConfig = false
function Banana_HeaderMouseDown()
	if not movingConfig then
		movingConfig = true
		BananaConfigFrame:StartMoving()
	end
end

function Banana_HeaderMouseUp()
	if movingConfig then
		movingConfig = false
		BananaConfigFrame:StopMovingOrSizing()
	end
end

function Banana_UpdateDialogFromVariables()
	SRTI_UpdateToolOptions()
    UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, BANANA_CONFIG.BUTTON_LAYOUT)
    BananaConfigFrameCheckButtonShowInRaid:SetChecked(BANANA_CONFIG.SHOW_IN_RAID == 1)
    BananaConfigFrameCheckButtonEnabled:SetChecked(BANANA_CONFIG.ENABLED == 1)
    Banana_SetEnabled(BANANA_CONFIG.ENABLED == 1)
    if ( superwow ) then
        BananaConfigFrameLabelSuperWoWHint:SetText("已检测到 SuperWoW 模组")
        BananaConfigFrameLabelSuperWoWHint:SetTextColor(0.4, 0.9, 0.4)
    else
        BananaConfigFrameLabelSuperWoWHint:SetText("未检测到 SuperWoW，单人标记与寻标不可用")
        BananaConfigFrameLabelSuperWoWHint:SetTextColor(1, 0.25, 0.25)
    end
    BananaConfigFrameCheckButtonShowInParty:SetChecked(BANANA_CONFIG.SHOW_IN_PARTY == 1)
    BananaConfigFrameCheckButtonShowOutOfGroup:SetChecked(BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1)
    BananaConfigFrameCheckButtonHideUnused:SetChecked(BANANA_CONFIG.HIDE_UNUSED_BUTTONS == 1)
	BananaConfigFrameCheckButtonDisableSound:SetChecked(BANANA_CONFIG.DISABLE_SOUND == 1)
	BananaConfigFrameCheckButtonDisableErrorText:SetChecked(BANANA_CONFIG.DISABLE_ERROR_TEXT == 1)
	BananaConfigFrameCheckButtonGreyOutDeath:SetChecked(BANANA_CONFIG.GREY_OUT_DEATH == 1)
    BananaConfigFrameCheckButtonShowExtraInfo:SetChecked(BANANA_CONFIG.SHOW_EXTRA_INFO == 1)
	BananaConfigFrameResizeSlider:SetValue(BANANA_CONFIG.BUTTON_SCALE)
	BananaConfig_UpdateScaleLabel()
end

function Banana_PlayError()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\SimpleRaidTargetIcons\\Sound\\BananaNo.mp3")
	end
end
function Banana_PlayRemove1()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\SimpleRaidTargetIcons\\Sound\\BananaPlop1.mp3")
	end
end

function Banana_PlayRemoveAll()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\SimpleRaidTargetIcons\\Sound\\BananaPlop8.mp3")
	end
end

function Banana_PlaySetSymbol()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\SimpleRaidTargetIcons\\Sound\\BananaSetSymbol.mp3")
	end
end

-- 印记扫描限频：找猎人印记得遍历单位身上的 16 个 debuff 槽，40 人团每轮上百次调用。
-- 印记持续 120 秒，每秒刷新一次足够，其余轮次直接命中缓存。
local huntersMarkCache = {}
local huntersMarkCacheExpire = 0

function Banana_InvalidateSymbolCache()
	huntersMarkCache = {}
	huntersMarkCacheExpire = 0
end

function Banana_GetSymbol(unit)
	local result = GetRaidTargetIndex(unit)
	if (not result) or (result == 0) then
		local now = GetTime()
		if now > huntersMarkCacheExpire then
			huntersMarkCache = {}
			huntersMarkCacheExpire = now + 1
		end
		result = huntersMarkCache[unit]
		if result == nil then
			result = 0
			for i = 1, 16 do
				if UnitDebuff(unit, i) == huntersMark then
					result = 9
					break
				end
			end
			huntersMarkCache[unit] = result
		end
	end
	return result
end

function Banana_SetSymbol(unit, index)
	Banana_InvalidateSymbolCache()
	if index <= 8 then
		if superwow and not InGroupOrRaid() then
			SetRaidTarget(unit, index, 1)
		else
			SetRaidTarget(unit, index)
		end
		if index ~= 0 then
			Banana_PlaySetSymbol()
		end
	elseif index == 9 then
		local spell = nil
		local searchid = 1
		local tex
		repeat
			tex = GetSpellTexture(searchid, BOOKTYPE_SPELL)
			if tex == huntersMark then
				spell, _ = GetSpellName(searchid, BOOKTYPE_SPELL)
			end
			searchid = searchid + 1
		until spell ~= nil or tex == nil

		if spell == nil then
			Banana_Error("技能书里找不到猎人印记。")
			Banana_PlayError()
			return
		end
		CastSpellByName(spell)
		Banana_PlaySetSymbol()
	end
end

function Banana_IsNameplate(frame)
	if frame:GetObjectType() ~= "Button" then return nil end
	if not frame:IsShown() then return nil end
	local child = frame:GetChildren()
	if not child then return nil end
	if not child:GetObjectType() == "StatusBar" then return nil end

		if frame:GetNumChildren() == 2 then
			if not shaguPlates then shaguPlates = true end
			return true
		end

	local region = frame:GetRegions()
	if not region then return nil end
	if not region:GetObjectType() == "Texture" then return nil end
	if not region:GetTexture() then return nil end

	return true
end

function Banana_ScanNameplates(index)
	if index == 9 then return nil end
	local button = raidTargetIconTexCoords[index]
	if not button then return nil end

	local bULx = button.ULx
	local bULy = button.ULy
	local frames = { WorldFrame:GetChildren() }

	for _, nameplate in ipairs(frames) do
    	if Banana_IsNameplate(nameplate) then
			if shaguPlates then
				local baseplate, shaguplate = nameplate:GetChildren()
				if shaguplate.raidicon:IsShown() then
					local ULx,ULy = shaguplate.raidicon:GetTexCoord()
					if ULx == bULx and ULy == bULy then
						nameplate:Click()
						Banana_UpdateStatus()
						return true
					end
				end
			else
				local _, _, _, _, _ , raidicon = nameplate:GetRegions()
				if raidicon:IsShown() and raidicon:GetObjectType() then
					if raidicon:GetTexture() then
						local ULx,ULy = raidicon:GetTexCoord()

						if ULx == bULx and ULy == bULy then
							nameplate:Click()
							Banana_UpdateStatus()
							return true
						end
					end
				end
			end
		end
	end

	return nil
end

function Banana_Layout()
	if BANANA_CONFIG.BUTTON_LAYOUT ~= 5 then
		BananaConfigFrameFlip:Enable()
		BananaConfigFrameDetach:Enable()
		BananaConfigFrameFlipText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		BananaConfigFrameDetachText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	else
		BananaConfigFrameFlip:Disable()
		BananaConfigFrameDetach:Disable()
		BananaConfigFrameFlipText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		BananaConfigFrameDetachText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	end
	if BANANA_CONFIG.BUTTON_LAYOUT == 1 then
		Banana_Layout1()
	elseif BANANA_CONFIG.BUTTON_LAYOUT == 2 then
		Banana_Layout2()
	elseif BANANA_CONFIG.BUTTON_LAYOUT == 3 then
		Banana_Layout3()
	elseif BANANA_CONFIG.BUTTON_LAYOUT == 4 then
		Banana_Layout4()
	else
		Banana_Layout5()
	end
	SRTI_PositionSaveBtn()
end

function Banana_Layout1()
	local left, right = "LEFT", "RIGHT"
	local padding = 4
	if BANANA_CONFIG.FLIP == 1 then
		left, right = "RIGHT", "LEFT"
		padding = -padding
	end
	RaidTargetFrame1Button:SetMovable(true)
	RaidTargetFrame2Button:SetMovable(false)
	RaidTargetFrame3Button:SetMovable(false)
	RaidTargetFrame4Button:SetMovable(false)
	RaidTargetFrame5Button:SetMovable(false)
	RaidTargetFrame6Button:SetMovable(false)
	RaidTargetFrame7Button:SetMovable(false)
	RaidTargetFrame8Button:SetMovable(false)
	RaidTargetFrame9Button:SetMovable(true)

	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame3Button:SetPoint(left, RaidTargetFrame2Button, right, padding, 0)
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame5Button:SetPoint(left, RaidTargetFrame4Button, right, padding, 0)
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame7Button:SetPoint(left, RaidTargetFrame6Button, right, padding, 0)
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
	RaidTargetFrame9Button:ClearAllPoints()

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout2()
	local left, right = "LEFT", "RIGHT"
	local top, bottom = "TOP", "BOTTOM"
	local padding = 4
	local rowPadding = SRTI_ToolRowSpacing()
	if BANANA_CONFIG.FLIP == 1 then
		left, right = "RIGHT", "LEFT"
		top, bottom = "BOTTOM", "TOP"
		padding = -padding
		rowPadding = -rowPadding
	end
	RaidTargetFrame1Button:SetMovable(true)
	RaidTargetFrame2Button:SetMovable(false)
	RaidTargetFrame3Button:SetMovable(false)
	RaidTargetFrame4Button:SetMovable(false)
	RaidTargetFrame5Button:SetMovable(false)
	RaidTargetFrame6Button:SetMovable(false)
	RaidTargetFrame7Button:SetMovable(false)
	RaidTargetFrame8Button:SetMovable(false)
	RaidTargetFrame9Button:SetMovable(true)

	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame3Button:SetPoint(left, RaidTargetFrame2Button, right, padding, 0)
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, -rowPadding)
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame7Button:SetPoint(left, RaidTargetFrame6Button, right, padding, 0)
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
	RaidTargetFrame9Button:ClearAllPoints()

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout3()
	local left, right = "LEFT", "RIGHT"
	local top, bottom = "TOP", "BOTTOM"
	local padding = 4
	local rowPadding = SRTI_ToolRowSpacing()
	if BANANA_CONFIG.FLIP == 1 then
		left, right = "RIGHT", "LEFT"
		top, bottom = "BOTTOM", "TOP"
		padding = -padding
		rowPadding = -rowPadding
	end
	RaidTargetFrame1Button:SetMovable(true)
	RaidTargetFrame2Button:SetMovable(false)
	RaidTargetFrame3Button:SetMovable(false)
	RaidTargetFrame4Button:SetMovable(false)
	RaidTargetFrame5Button:SetMovable(false)
	RaidTargetFrame6Button:SetMovable(false)
	RaidTargetFrame7Button:SetMovable(false)
	RaidTargetFrame8Button:SetMovable(false)
	RaidTargetFrame9Button:SetMovable(true)

	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame3Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, -rowPadding)
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame3Button, bottom, 0, -rowPadding)
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame7Button:SetPoint(top, RaidTargetFrame5Button, bottom, 0, -rowPadding)
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
	RaidTargetFrame9Button:ClearAllPoints()

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, rowPadding)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout4()
	local top, bottom = "TOP", "BOTTOM"
	local padding = -SRTI_ToolRowSpacing()
	if BANANA_CONFIG.FLIP == 1 then
		top, bottom = "BOTTOM", "TOP"
		padding = -padding
	end
	RaidTargetFrame1Button:SetMovable(true)
	RaidTargetFrame2Button:SetMovable(false)
	RaidTargetFrame3Button:SetMovable(false)
	RaidTargetFrame4Button:SetMovable(false)
	RaidTargetFrame5Button:SetMovable(false)
	RaidTargetFrame6Button:SetMovable(false)
	RaidTargetFrame7Button:SetMovable(false)
	RaidTargetFrame8Button:SetMovable(false)
	RaidTargetFrame9Button:SetMovable(true)

	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame2Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, padding)
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame3Button:SetPoint(top, RaidTargetFrame2Button, bottom, 0, padding)
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame4Button:SetPoint(top, RaidTargetFrame3Button, bottom, 0, padding)
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame4Button, bottom, 0, padding)
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame6Button:SetPoint(top, RaidTargetFrame5Button, bottom, 0, padding)
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame7Button:SetPoint(top, RaidTargetFrame6Button, bottom, 0, padding)
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame8Button:SetPoint(top, RaidTargetFrame7Button, bottom, 0, padding)
	RaidTargetFrame9Button:ClearAllPoints()

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, -padding)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout5()
	RaidTargetFrame1Button:SetMovable(true)
	RaidTargetFrame2Button:SetMovable(true)
	RaidTargetFrame3Button:SetMovable(true)
	RaidTargetFrame4Button:SetMovable(true)
	RaidTargetFrame5Button:SetMovable(true)
	RaidTargetFrame6Button:SetMovable(true)
	RaidTargetFrame7Button:SetMovable(true)
	RaidTargetFrame8Button:SetMovable(true)
	RaidTargetFrame9Button:SetMovable(true)

	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame9Button:ClearAllPoints()

	icons[1].MovingButton = 1
	icons[2].MovingButton = 2
	icons[3].MovingButton = 3
	icons[4].MovingButton = 4
	icons[5].MovingButton = 5
	icons[6].MovingButton = 6
	icons[7].MovingButton = 7
	icons[8].MovingButton = 8
	icons[9].MovingButton = 9

	Banana_ReloadFramePositions()
end

function BananaConfig_FlipToggle()
	if BANANA_CONFIG.FLIP ~= 1 then
		BANANA_CONFIG.FLIP = 1
	else
		BANANA_CONFIG.FLIP = 0
	end
	Banana_Layout()
end

function BananaConfig_DetachToggle()
	if BANANA_CONFIG.DETACH ~= 1 then
		BANANA_CONFIG.DETACH = 1
	else
		BANANA_CONFIG.DETACH = 0
	end
	Banana_Layout()
end

-- ===================== SRTI 标记保存/还原（B 方案）=====================
-- 自己标、自己存，进本一键还原；全副本按 GetRealZoneText() 分桶。
-- 依赖 SuperWoW：存靠 mark1..8 枚举场上已标怪取 GUID，还原靠 GUID-as-unit 直接 SetRaidTarget。
-- 按钮挂团队标记条末尾（RaidTargetFrame8Button 之后），跟随 Banana_Layout 的方向/FLIP。
-- 左键：有记录还原 / 无记录保存；右键：始终覆盖保存（改标记后重新存）。
-- 注意：SRTI_SaveBtn 已在文件顶部前向声明，这里不能再 local（否则遮蔽前向声明）

SRTI_SaveBtn = nil

local function SRTI_Zone()
	return GetRealZoneText()
end

local function SRTI_HasRecord(zone)
	local pack = SRTI_MARKS[zone or SRTI_Zone()]
	return pack and next(pack) and true or false
end

local function SRTI_SaveMarks()
	if not superwow then
		Banana_Error("保存标记需 SuperWoW 模组（用于枚举场上已标记单位）。")
		Banana_PlayError()
		return
	end
	local zone = SRTI_Zone()
	local pack = {}
	local n = 0
	for i = 1, 8 do
		local u = "mark" .. i
		if UnitExists(u) then
			local _, g = UnitExists(u)
			if UnitGUID then g = UnitGUID(u) or g end
			if g then
				pack[g] = i
				n = n + 1
			end
		end
	end
	if n == 0 then
		-- 场上没怪可扫时保留旧记录，防止误清空存档
		Banana_Print("当前场上没有已标记的怪，未保存（原记录保留）。")
	else
		-- 整表替换：右键保存 = 清空旧记录 + 重新保存当前标记
		SRTI_MARKS[zone] = pack
		Banana_Print("已覆盖保存 " .. n .. " 个标记到副本：" .. zone)
	end
	SRTI_RefreshSaveBtn()
end

local function SRTI_RestoreMarks()
	if not superwow then
		Banana_Error("还原标记需 SuperWoW 模组（用于按 GUID 直接标记单位）。")
		Banana_PlayError()
		return
	end
	local zone = SRTI_Zone()
	local pack = SRTI_MARKS[zone]
	if not pack or not next(pack) then
		Banana_Error("本副本 [" .. zone .. "] 没有保存的标记记录。")
		Banana_PlayError()
		return
	end
	local total = 0
	local done = 0
	for _ in pairs(pack) do total = total + 1 end
	for g, m in pairs(pack) do
		if UnitExists(g) then
			Banana_SetSymbol(g, m)
			done = done + 1
		end
	end
	Banana_Print("已还原 " .. done .. " 个标记（共 " .. total .. " 个记录，未在场上的已跳过）。")
end

-- 全局函数：SRTI_SaveMarks（定义在前）要调用它，local 会导致保存后按钮不刷新
function SRTI_RefreshSaveBtn()
	if not SRTI_SaveBtn then return end
	if SRTI_HasRecord() then
		SRTI_SaveBtnTex:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\srti_mark.tga")
		if superwow then
			SRTI_SaveBtnTex:SetVertexColor(0.29, 0.87, 0.50)
		else
			SRTI_SaveBtnTex:SetVertexColor(0.6, 0.6, 0.6)
		end
	else
		SRTI_SaveBtnTex:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\srti_save.tga")
		SRTI_SaveBtnTex:SetVertexColor(0.97, 0.95, 0.42)
	end
	SRTI_UpdateSaveBtnAlpha()
end

-- 勾选"隐藏未使用的按钮"时与标记图标一样保持 0.4 半透明占位
function SRTI_UpdateSaveBtnAlpha()
	if not SRTI_SaveBtn then return end
	if BANANA_CONFIG.HIDE_UNUSED_BUTTONS == 1 then
		SRTI_SaveBtn:SetAlpha(0.4)
	else
		SRTI_SaveBtn:SetAlpha(1)
	end
end

-- 全局函数：Banana_Layout（定义在前）末尾要调用它，local 会导致引用 nil
function SRTI_PositionSaveBtn()
	SRTI_LayoutTools()
end

local function SRTI_OnClick()
	if arg1 == "RightButton" then
		SRTI_SaveMarks()
	elseif SRTI_HasRecord() then
		SRTI_RestoreMarks()
	else
		SRTI_SaveMarks()
	end
end

-- 全局函数：Banana_OnEvent（定义在前）要调用它，local 会导致引用 nil —— 此前整套功能因此从未生效
function SRTI_InitSaveBtn()
	if SRTI_SaveBtn then return end
	SRTI_MARKS = SRTI_MARKS or {}
	SRTI_SaveBtn = CreateFrame("Button", "SRTI_SaveBtn", RaidTargetFrame)
	SRTI_SaveBtn:SetWidth(36)
	SRTI_SaveBtn:SetHeight(36)
	-- 单字贴图化：32x32 白字 TGA（与标记图标同几何 @ (2,-2)），运行时 SetVertexColor 染色
	SRTI_SaveBtnTex = SRTI_SaveBtn:CreateTexture("SRTI_SaveBtnTex", "BACKGROUND")
	SRTI_SaveBtnTex:SetPoint("TOPLEFT", SRTI_SaveBtn, "TOPLEFT", 2, -2)
	SRTI_SaveBtnTex:SetWidth(32)
	SRTI_SaveBtnTex:SetHeight(32)
	SRTI_SaveBtnTex:SetTexture("Interface\\AddOns\\SimpleRaidTargetIcons\\img\\srti_save.tga")
	SRTI_SaveBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	SRTI_SaveBtn:SetScript("OnClick", SRTI_OnClick)
	SRTI_SaveBtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(SRTI_SaveBtn, "ANCHOR_RIGHT")
		GameTooltip:AddLine("SRTI 标记保存/还原")
		GameTooltip:AddLine("左键：有记录则还原，无记录则保存", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("右键：覆盖保存当前场上标记", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	SRTI_SaveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	SRTI_SaveBtn:RegisterEvent("VARIABLES_LOADED")
	SRTI_SaveBtn:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	SRTI_SaveBtn:RegisterEvent("PLAYER_ENTERING_WORLD")
	SRTI_SaveBtn:SetScript("OnEvent", function() SRTI_RefreshSaveBtn() end)
	SRTI_PositionSaveBtn()
	SRTI_RefreshSaveBtn()
	-- 创建晚于 Banana_OnEvent 里的 Banana_UpdateScale()，需立即补一次缩放对齐标记条
	Banana_UpdateScale()
end
