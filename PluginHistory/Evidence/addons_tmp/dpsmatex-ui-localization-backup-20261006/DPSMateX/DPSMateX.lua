-- Global Variables
DPSMateX = {}
local DPSMateX = DPSMateX

local SendChatMessage = SendChatMessage

DPSMateX.VERSION = 132
DPSMateX.LOCALE = GetLocale()
DPSMateX.SYNCVERSION = DPSMateX.VERSION..DPSMateX.LOCALE
DPSMateXParser = CreateFrame("Frame", "DPSMateXParser", UIParent)
DPSMateX.Parser = DPSMateXParser
DPSMateX.L = {}

DPSMateXDB = CreateFrame("Frame", "DPSMateXDB", UIParent)
DPSMateX.DB = DPSMateXDB
DPSMateX.DB:RegisterEvent("VARIABLES_LOADED")
DPSMateX.DB:RegisterEvent("PLAYER_LOGIN")
DPSMateX.DB:RegisterEvent("PLAYER_REGEN_DISABLED")
DPSMateX.DB:RegisterEvent("PLAYER_REGEN_ENABLED")
DPSMateX.DB:RegisterEvent("PLAYER_AURAS_CHANGED")
DPSMateX.DB:RegisterEvent("PLAYER_TARGET_CHANGED")
DPSMateX.DB:RegisterEvent("UNIT_PET")
DPSMateX.DB:RegisterEvent("PLAYER_PET_CHANGED")
DPSMateX.DB:RegisterEvent("PET_STABLE_CLOSED")
DPSMateX.DB:RegisterEvent("ZONE_CHANGED_NEW_AREA")

DPSMateX.DB.loaded = false
DPSMateX.DB.has_superwow = SetAutoloot and true or false

DPSMateX.DB.has_nampower = nil
if GetNampowerVersion then
	local nv_major, nv_minor = GetNampowerVersion()
	if nv_major < 3 or (nv_major == 3 and nv_minor < 4) then
		DPSMateX.DB.has_nampower = nil
	else
		DPSMateX.DB.has_nampower = true
	end
end

DPSMateX.Temp = {}
DPSMateX.DBCache = {}

DPSMateXOptions = CreateFrame("Frame", "DPSMateXOptions", UIParent)
DPSMateX.Options = DPSMateXOptions

DPSMateXSync = CreateFrame("Frame", "DPSMateXSync", UIParent)
DPSMateX.Sync = DPSMateXSync

DPSMateX.Modules = {}

-- Events
DPSMateX.Options:RegisterEvent("PARTY_MEMBERS_CHANGED")
DPSMateX.Options:RegisterEvent("RAID_ROSTER_UPDATE")
DPSMateX.Options:RegisterEvent("PLAYER_ENTERING_WORLD")
DPSMateX.Options:SetScript("OnEvent", function() this[event]() end)
DPSMateX.Options:SetScript("OnUpdate", function() this:OnUpdate() end)

DPSMateX.Registered = nil
DPSMateX.RegistredModules = {}
DPSMateX.EnabledModules = {}
DPSMateX.ModuleNames = {}
DPSMateX.Key = 1
DPSMateX.DelayMsg = {}
DPSMateX.BabbleSpellX = BabbleSpellX
DPSMateX.BabbleBoss = BabbleBoss
DPSMateX.MaxRows = 80
DPSMateX.turtle_wow = (GetItemInfo(5000) == DPSMateX.L["Character Name Change"]) and  true

-- Local Variables
local _G = getglobal
local classcolor = {
	rogue = {r=1.0, g=0.96, b=0.41},
	priest = {r=1,g=1,b=1},
	druid = {r=1,g=0.49,b=0.04},
	warrior = {r=0.78,g=0.61,b=0.43},
	warlock = {r=0.58,g=0.51,b=0.79},
	mage = {r=0.41,g=0.8,b=0.94},
	hunter = {r=0.67,g=0.83,b=0.45},
	paladin = {r=0.96,g=0.55,b=0.73},
	shaman = {r=0,g=0.44,b=0.87},
}
local t = {}
local tinsert = table.insert
local strgsub = string.gsub
local func = function(c) tinsert(t, c) end
local strformat = string.format
local strgfind = string.gfind
local pairs = pairs
local strlen = string.len
local strsub = string.sub
local tonumber = tonumber
local getn = table.getn
local setn = table.setn
local tconcat = table.concat
local strfind = string.find

-- Begin functions

function DPSMateX:OnLoad()
	SLASH_DPSMateX1 = "/dps"
	SlashCmdList["DPSMateX"] = function(msg) DPSMateX:SlashCMDHandler(msg) end

	DPSMateX:InitializeFrames()
	DPSMateX.Options:InitializeConfigMenu()
	DPSMateX:ApplyModules()
end

function DPSMateX:SlashCMDHandler(msg)
	if (msg) then
		local cmd = msg
		if cmd == "lock" then
			DPSMateX.Options:Lock()
		elseif cmd == "unlock" then
			DPSMateX.Options:Unlock()
		elseif cmd == "config" then
			DPSMateX_ConfigMenu:Show()
		elseif cmd == "showAll" then
			for _, val in DPSMateX.Settings["windows"] do DPSMateX.Options:Show(getglobal("DPSMateX_"..val["name"])) end
		elseif cmd == "hideAll" then
			for _, val in DPSMateX.Settings["windows"] do DPSMateX.Options:Hide(getglobal("DPSMateX_"..val["name"])) end
		elseif strsub(cmd, 1, 4) == "show" then
			local frame = _G("DPSMateX_"..strsub(cmd, 6))
			if frame then
				DPSMateX.Options:Show(frame)
			else
				DPSMateX:SendMessage(DPSMateX.L["framesavailable"])
				for _, val in pairs(DPSMateX.Settings["windows"]) do
					DPSMateX:SendMessage("|c3ffddd80- "..val["name"].."|r")
				end
			end
		elseif strsub(cmd, 1, 4) == "hide" then
			local frame = _G("DPSMateX_"..strsub(cmd, 6))
			if frame then
				DPSMateX.Options:Hide(frame)
			else
				DPSMateX:SendMessage(DPSMateX.L["framesavailable"])
				for _, val in pairs(DPSMateX.Settings["windows"]) do
					DPSMateX:SendMessage("|c3ffddd80- "..val["name"].."|r")
				end
			end
		else
			DPSMateX:SendMessage(DPSMateX.L["slashabout"])
			DPSMateX:SendMessage(DPSMateX.L["slashusage"])
			DPSMateX:SendMessage(DPSMateX.L["slashlock"])
			DPSMateX:SendMessage(DPSMateX.L["slashunlock"])
			DPSMateX:SendMessage(DPSMateX.L["slashshowAll"])
			DPSMateX:SendMessage(DPSMateX.L["slashhideAll"])
			DPSMateX:SendMessage(DPSMateX.L["slashshow"])
			DPSMateX:SendMessage(DPSMateX.L["slashhide"])
			DPSMateX:SendMessage(DPSMateX.L["slashconfig"])
		end
	end
end

function DPSMateX:InitializeFrames()
	if not DPSMateX.Settings["windows"][1] then return end
	for k, val in pairs(DPSMateX.Settings["windows"]) do
		if not _G("DPSMateX_"..val["name"]) then
			local f=CreateFrame("Frame", "DPSMateX_"..val["name"], UIParent, "DPSMateX_Statusframe")
			f.Key=k
		end
		local frame = _G("DPSMateX_"..val["name"])
		frame.fborder = _G("DPSMateX_"..val["name"].."_Border")
		DPSMateX.Settings["windows"][k]["hidden"] = false

		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total_Name"):SetText(self.L["total"])

		if (val["position"] and val["position"][1]) then
			frame:ClearAllPoints()
			frame:SetPoint(val["position"][1], UIParent, val["position"][1], val["position"][2], val["position"][3])
		end
		if (val["savsize"] and val["savsize"][1]) then
			frame:SetWidth(val["savsize"][1])
			frame:SetHeight(val["savsize"][2])
		end

		DPSMateX.Options:ToggleDrewDrop(1, DPSMateX.DB:GetOptionsTrue(1, k), frame)
		DPSMateX.Options:ToggleDrewDrop(2, DPSMateX.DB:GetOptionsTrue(2, k), frame)

		frame.fborder:SetAlpha(val["borderopacity"] or 0)
		frame.fborder:SetFrameStrata(DPSMateX.Options.stratas[val["borderstrata"] or 1])
		frame.fborder:SetBackdrop({
								  bgFile = "",
								  edgeFile = DPSMateX.Options.bordertextures[val["bordertexture"] or "UI-Tooltip-Border"], tile = true, tileSize = 12, edgeSize = 10,
								  insets = { left = 5, right = 5, top = 3, bottom = 1 }
								})
		frame.fborder:SetBackdropBorderColor(val["contentbordercolor"][1], val["contentbordercolor"][2], val["contentbordercolor"][3])

		local head = _G("DPSMateX_"..val["name"].."_Head")
		head.font = _G("DPSMateX_"..val["name"].."_Head_Font")
		head.bg = _G("DPSMateX_"..val["name"].."_Head_Background")
		head.sync = _G("DPSMateX_"..val["name"].."_Head_Sync")

		if DPSMateX.Settings["sync"] then
			head.sync:GetNormalTexture():SetVertexColor(0.67,0.83,0.45,1)
		else
			head.sync:GetNormalTexture():SetVertexColor(1,0,0,1)
		end
		head.sync:Hide()
		
		frame:SetResizable(not DPSMateX.Settings["lock"])
		if DPSMateX.Settings["lock"] then
			_G("DPSMateX_"..val["name"].."_Resize"):Hide()
			_G("DPSMateX_"..val["name"].."_ResizeLU"):Hide()
		else
			_G("DPSMateX_"..val["name"].."_Resize"):Show()
			_G("DPSMateX_"..val["name"].."_ResizeLU"):Show()
		end
		if not val["titlebar"] then
			head:Hide()
		end
		frame:SetAlpha(val["opacity"])
		head.font:SetTextColor(val["titlebarfontcolor"][1],val["titlebarfontcolor"][2],val["titlebarfontcolor"][3])
		head.bg:SetTexture(DPSMateX.Options.statusbars[val["titlebartexture"]])
		head.bg:SetVertexColor(val["titlebarbgcolor"][1], val["titlebarbgcolor"][2], val["titlebarbgcolor"][3])
		head.bg:SetAlpha(val["titlebaropacity"] or 1)
		head.font:SetFont(DPSMateX.Options.fonts[val["titlebarfont"]], val["titlebarfontsize"], DPSMateX.Options.fontflags[val["titlebarfontflag"]])
		head:SetHeight(val["titlebarheight"])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Background"):SetTexture(DPSMateX.Options.bgtexture[val["contentbgtexture"]])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Background"):SetVertexColor(val["contentbgcolor"][1], val["contentbgcolor"][2], val["contentbgcolor"][3])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Background"):SetAlpha(val["bgopacity"] or 1)
		frame:SetScale(val["scale"])
		_G("DPSMateX_"..val["name"].."_Head_Enable"):SetChecked(DPSMateX.Settings["enable"])

		-- Styles // Bars
		local child = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child")
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetPoint("TOPLEFT", child, "TOPLEFT")
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetPoint("TOPRIGHT", child, "TOPRIGHT")
		if DPSMateX.Settings["showtotals"] then
			_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetHeight(val["barheight"])
		else
			_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetHeight(0.00001)
		end
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetStatusBarTexture(DPSMateX.Options.statusbars[val["bartexture"]])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"):SetStatusBarColor(1,1,1,val["totopacity"] or 1)
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total_BG"):SetTexture(DPSMateX.Options.statusbars[val["bartexture"]])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total_BG"):SetAlpha(val["totopacity"] or 1)
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total_Name"):SetFont(DPSMateX.Options.fonts[val["barfont"]], val["barfontsize"], DPSMateX.Options.fontflags[val["barfontflag"]])
		_G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total_Value"):SetFont(DPSMateX.Options.fonts[val["barfont"]], val["barfontsize"], DPSMateX.Options.fontflags[val["barfontflag"]])
		for i=1, DPSMateX.MaxRows do
			local bar = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..i)
			bar.name = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name")
			bar.value = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value")
			bar.icon = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Icon")
			bar.bg = _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_BG")

			-- Postition
			bar:SetPoint("TOPLEFT", child, "TOPLEFT")
			bar:SetPoint("TOPRIGHT", child, "TOPRIGHT")
			if i>1 then
				bar:SetPoint("TOPLEFT", _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_StatusBar"..(i-1)), "BOTTOMLEFT", 0, -1*val["barspacing"])
			else
				if DPSMateX.Settings["showtotals"] then
					bar:SetPoint("TOPLEFT", _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"), "BOTTOMLEFT", 0, -1*val["barspacing"])
				else
					bar:SetPoint("TOPLEFT", _G("DPSMateX_"..val["name"].."_ScrollFrame_Child_Total"), "BOTTOMLEFT", 0, -1)
				end
			end
			if val["classicons"] then
				bar.name:ClearAllPoints()
				bar.name:SetPoint("TOPLEFT", bar, "TOPLEFT", val["barheight"], 0)
				bar.name:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
				bar.icon:SetWidth(val["barheight"])
				bar.icon:SetHeight(val["barheight"])
				bar.icon:Show()
			end

			-- Styles
			bar.name:SetFont(DPSMateX.Options.fonts[val["barfont"]], val["barfontsize"], DPSMateX.Options.fontflags[val["barfontflag"]])
			bar.name:SetTextColor(val["barfontcolor"][1],val["barfontcolor"][2],val["barfontcolor"][3])
			bar.value:SetFont(DPSMateX.Options.fonts[val["barfont"]], val["barfontsize"], DPSMateX.Options.fontflags[val["barfontflag"]])
			bar.value:SetTextColor(val["barfontcolor"][1],val["barfontcolor"][2],val["barfontcolor"][3])
			bar:SetStatusBarTexture(DPSMateX.Options.statusbars[val["bartexture"]])
			bar.bg:SetTexture(DPSMateX.Options.statusbars[val["bartexture"]])
			bar:SetHeight(val["barheight"])
			if val["barbg"] then
				bar.bg:SetVertexColor(val["bgbarcolor"][1],val["bgbarcolor"][2],val["bgbarcolor"][3], 0)
			else
				bar.bg:SetVertexColor(val["bgbarcolor"][1],val["bgbarcolor"][2],val["bgbarcolor"][3], 0.5)
			end
		end
		DPSMateX.Options:SelectRealtime(frame, val["realtime"])
	end
	DPSMateX.Options:ToggleTitleBarButtonState()
	DPSMateX.Options:HideWhenSolo()
	if not DPSMateX.Settings["enable"] then
		self:Disable()
	else
		self:Enable()
	end

	-- Report delay button
	DPSMateX_Report_Delay:SetChecked(DPSMateX.Settings["reportdelay"])

	DPSMateX_PopUp:SetToplevel(true)
	DPSMateX_Vote:SetToplevel(true)
	DPSMateX_Logout:SetToplevel(true)
	DPSMateX_Report:SetToplevel(true)
	DPSMateX_ConfigMenu:SetToplevel(true)
end

function DPSMateX:ProbZero(val)
	if (val==0) then
		return 1;
	end
	return val;
end

function DPSMateX:TMax(t)
	local max = 0
	for _,val in pairs(t) do
		if val>max then
			max=val
		end
	end
	return max
end

function DPSMateX:TableLength(t)
	local count = 0
	if (t) then
		count = getn(t)
		if count==0 then
			for _,_ in pairs(t) do
				count = count + 1
			end
		end
	end
	return count
end

function DPSMateX:TContains(t, value)
	if (t) then
		for cat, val in pairs(t) do
			if val == value or cat==value then
				return true
			end
		end
	end
	return false
end

function DPSMateX:GetKeyByVal(t, value)
	for cat, val in pairs(t) do
		if val == value then
			return cat
		end
	end
end

local type = type
function DPSMateX:GetKeyByValInTT(t, x, y)
	for cat, val in pairs(t) do
		if (type(val) == "table") then
			if (x==val[y]) then
				return cat
			end
		end
	end
end
function DPSMateX:DeepCopy(into, from)
	if from then
		for key, val in pairs(from) do
			if( type(val) == "table" ) then
				if( not into[key] ) then into[key] = {} end
				DPSMateX:DeepCopy(into[key], val)
			else
				into[key] = val
			end
		end
		
		if (getn(from)) then
			table.setn(into, getn(from))		
		end
	end
	return into
end

function DPSMateX:CopyTable(t)
	local s={}
	for cat, val in pairs(t) do
		s[cat] = val
	end
	return s
end

--temp table pool
DPSMateX.Pool = {}
local MAX_POOL_SIZE = 640
local free_tables = {}
local pool_count = 0

function DPSMateX.Pool.get()
    if pool_count > 0 then
        local t = free_tables[pool_count]
        free_tables[pool_count] = nil
        pool_count = pool_count - 1
		--print("DPSMateX: table get! ".. pool_count)
        return t
    else
		--print("DPSMateX: new table created!")
        return {}
    end
end

function DPSMateX.Pool.release(t)
    for k,v in pairs(t) do
		if type(v) == "table" then
			DPSMateX.Pool.release(v)
        end
        t[k] = nil
    end
	
	if getn(t) ~= 0 then
		setn(t, 0)
	end

    if pool_count < MAX_POOL_SIZE then
        pool_count = pool_count + 1
        free_tables[pool_count] = t
		--print("DPSMateX: table released! ".. pool_count)
	else
		--print("DPSMateX: pool is full!")
    end
end

for i = 1, MAX_POOL_SIZE do
    DPSMateX.Pool.release({})
end

function DPSMateX.Pool.size()
    return getn(free_tables)
end

function DPSMateX.Pool.clear()
    for i = pool_count, 1, -1 do
        free_tables[i] = nil
    end
    pool_count = 0
end

function DPSMateX:WipeTable(t)
	if not t then return {} end
	
	if type(t) ~= "table" then
		error(format("bad argument #1 to 'wipe' (table expected, got %s)", t and type(t) or "no value"), 2)
	end

	for k in pairs(t) do
		t[k] = nil
	end

	if getn(t) ~= 0 then
		setn(t, 0)
	end

	return t
end

function DPSMateX:WipeInPool(t)
	if not t then return {} end

	for k,v in pairs(t) do
		if type(v) == "table" then
			DPSMateX.Pool.release(v)
		end
		t[k] = nil
	end

	if getn(t) ~= 0 then
		setn(t, 0)
	end

	return t
end

function DPSMateX:BuildUserId()
	DPSMateX.UserId = {}
	DPSMateX.userlen = 0
	for cat, val in DPSMateX.CacheUser do
		if val[1] > DPSMateX.userlen then DPSMateX.userlen = val[1] end
		DPSMateX.UserId[val[1]] = cat
	end
end

function DPSMateX:GetUserById(id)
	return DPSMateX.UserId[id]
end

function DPSMateX:BuildAbilityId()
	DPSMateX.AbilityId = {}
	DPSMateX.abilitylen = 0
	for cat, val in DPSMateX.CacheAbility do
		if val[1] > DPSMateX.abilitylen then DPSMateX.abilitylen = val[1] end
		DPSMateX.AbilityId[val[1]] = cat
	end
end

function DPSMateX:GetAbilityById(id)
	return DPSMateX.AbilityId[id]
end

function DPSMateX:PetFilter(cat, petsMasterSeen)
	local name = DPSMateX:GetUserById(cat)
	local userInfo = DPSMateX.CacheUser[name]
	local go = nil
	
	if userInfo then
		if userInfo[4] then
			if not DPSMateX.Settings["mergepets"] then
				go = 1
			else
				if userInfo[6] and not (petsMasterSeen and petsMasterSeen[userInfo[6]]) then
					cat = userInfo[6]
					name = DPSMateX:GetUserById(cat)
					if petsMasterSeen then petsMasterSeen[cat] = true end
					go = 1
				end
			end
		else
			-- players not seen
			if petsMasterSeen and not petsMasterSeen[cat] then
				petsMasterSeen[cat] = true
				go = 1
			end
		end
	end

	return name, cat, go
end

function DPSMateX:GetMaxValue(arr, key)
	local max = 0
	for _, val in arr do
		if val[key]>max then
			max=val[key]
		end
	end
	return max
end

function DPSMateX:GetMinValue(arr, key)
	local min
	for _, val in arr do
		if not min or val[key]<min then
			min = val[key]
		end
	end
	return min or 0
end

function DPSMateX:ScaleDown(arr, start)
	local t = {}
	for cat, val in arr do
		t[cat] = {(val[1]-start+1), val[2]}
	end
	return t
end

function DPSMateX:SetStatusBarValue(no_reset)
	if not DPSMateX.DB.loaded or not DPSMateX.Settings["windows"][1] or DPSMateX.Options.TestMode then return end
	local arr, cbt, ecbt, user, val, perc, strt, statusbar, r, g, b, img, len
	for k,c in pairs(DPSMateX.Settings.windows) do
		arr, cbt, ecbt = self:GetMode(k)
		user, val, perc, strt = self:GetSettingValues(arr,cbt,k,ecbt,no_reset)
		if DPSMateX.Settings["showtotals"] then
			_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_Total_Value"):SetText(strt[1]..strt[2])
		end
		if not c["cbtdisplay"] then
			_G("DPSMateX_"..c["name"].."_Head_Font"):SetText(self.Options.Options[1]["args"][c["CurMode"]].name.." ["..self.Options:FormatTime(cbt).."]"..((self.Encounters and self.Encounters.ready and self.Encounters:Scope(k)) and (" · "..self.Encounters:ScopeName(k)) or ""))
		end
		len = 0
		for i=1, DPSMateX.MaxRows do
			statusbar = _G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i)
			if user[i] then
				r,g,b,img = self:GetClassColor(user[i])
				statusbar:SetStatusBarColor(r,g,b, 1)

				if c["ranks"] then 
					_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"):SetText(i..". "..user[i])
				else
					_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"):SetText(user[i])
				end
				_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value"):SetText(val[i])
				_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
				statusbar:SetValue(perc[i])

				statusbar.user = user[i]
				statusbar:Show()
				len = len + 1
			else
				statusbar:Hide()
			end
		end
		_G("DPSMateX_"..c["name"].."_ScrollFrame_Child"):SetHeight((len+1)*(c["barheight"]+c["barspacing"]))
		_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_Total"):Show()
		if len == 0 then
			_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_Total"):Hide()
		end
	end
end

function DPSMateX:strrev(str)
	local res, len = {}, strlen(str)
	for i=0, len-1 do
		res[i] = strsub(str, len-i, len-i)
	end
	return tconcat(res);
end

function DPSMateX:Commas(n,k)
	if DPSMateX.Settings["windows"][k]["numberformat"] == 3 then
		n = strformat("%.0f", n)
		for left, num, right in strgfind(n, '([^%d]*%d)(%d+)') do
			return left and left..self:strrev(strgsub(self:strrev(num), '(%d%d%d)','%1,'))
		end
	end
	return n;
end

function DPSMateX:FormatNumbers(dmg,total,sort,k)
	local oldd, oldt, olds = dmg, total, sort
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 then
		if dmg>10000 then
			dmg = strformat("%.0f", (dmg/1000))
		end
		if total>10000 then
			total = strformat("%.0f", (total/1000))
		end
		if sort>10000 then
			sort = strformat("%.0f", (sort/1000))
		end
	elseif DPSMateX.Settings["windows"][k]["numberformat"] == 4 then
		if dmg>10000 then
			dmg = strformat("%.1f", (dmg/1000))
		end
		if total>10000 then
			total = strformat("%.1f", (total/1000))
		end
		if sort>10000 then
			sort = strformat("%.1f", (sort/1000))
		end
	end
	return dmg, total, sort, oldd, oldt, olds
end

function DPSMateX:ApplyFilter(key, name)
	if not key or not name or not DPSMateX.CacheUser[name] then return true end
	local class = DPSMateX.CacheUser[name][2] or "warrior"
	local path = DPSMateX.Settings["windows"][key]
	if path["grouponly"] then
		if not DPSMateX.Parser.TargetParty[name] then
			return false
		end
	end

	if path["filterpeople"] ~= "" then
		-- Certain people
		t = {}
		strgsub(path["filterpeople"], "(.-),", func)
		for cat, val in pairs(t) do
			if name == val then
				return true
			end
		end
	end

	-- classes
	for cat, val in pairs(path["filterclasses"]) do
		if not val then
			if cat == class then
				return false
			end
		end
	end
	return true
end

function DPSMateX:GetSettingValues(arr, cbt, k, ecbt, no_reset)
	k = k or 1
	return self.RegistredModules[DPSMateX.Settings["windows"][k]["CurMode"]]:GetSettingValues(arr, cbt, k, ecbt, no_reset)
end

function DPSMateX:EvalTable(module, user, key, cbt, ecbt)
	local a,b,c,d = module:EvalTable(user, key, cbt, ecbt)
	local ta, tb, tc, td = a, b, c, d
	
	if type(a) == "table" then
		ta = {}
		DPSMateX:DeepCopy(ta, a)
	end
	if type(b) == "table" then
		tb = {}
		DPSMateX:DeepCopy(tb, b)
	end
	if type(c) == "table" then
		tc = {}
		DPSMateX:DeepCopy(tc, c)
	end
	if type(d) == "table" then
		td = {}
		DPSMateX:DeepCopy(td, d)
	end
	return ta, tb, tc, td
end

function DPSMateX:GetClassColor(class)
	if not classcolor[class] then
		if class and DPSMateX.CacheUser[class] then
			class = DPSMateX.CacheUser[class][2] or "warrior"
		else
			class = "warrior"
		end
	end
	if classcolor[class]==nil then class="warrior" end
	return classcolor[class].r, classcolor[class].g, classcolor[class].b, class
end

-- Remove only amount/time samples. Parent totals and event histories have other uses.
function DPSMateX:ReleaseDetailTimelines()
	if self.Settings.compactDetailsVersion == 1 then return end
	local function clear(node, depth)
		if type(node) ~= "table" then return end
		if depth == 0 then
			if type(node.i) == "table" then node.i = nil end
			return
		end
		for key, value in pairs(node) do
			if key ~= "i" and type(value) == "table" then clear(value, depth-1) end
		end
	end
	local schemas = {
		{"DamageDone", "DMGDone", 2}, {"DamageTaken", "DMGTaken", 3},
		{"EDD", "EDDone", 3}, {"EDT", "EDTaken", 3},
		{"THealing", "THealing", 2}, {"EHealing", "EHealing", 2},
		{"Overhealing", "OHealing", 2}, {"HealingTaken", "THealingTaken", 3},
		{"EHealingTaken", "EHealingTaken", 3}, {"OverhealingTaken", "OHealingTaken", 3},
	}
	for _, schema in ipairs(schemas) do
		for _, data in pairs(self.DBCache[schema[1]] or {}) do clear(data, schema[3]) end
		for _, data in pairs(self.DPSMateXHistory[schema[2]] or {}) do clear(data, schema[3]) end
	end
	self.Settings.compactDetailsVersion = 1
end

function DPSMateX:GetMode(k)
	k = k or 1
	self:NormalizeEncounterScope(k)
	local Handler = DPSMateX.RegistredModules[DPSMateX.Settings["windows"][k]["CurMode"]]
	if Handler.Insights and DPSMateX.Insights then
		return DPSMateX.Insights:GetMode(k, Handler.Kind)
	end
	if self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then
		return self.Encounters:GetCore(k, Handler.Hist)
	end
	local result = {
		total={
			Handler.DB[1], 
			math.max(DPSMateX.CombatTime["total"], 1.5),
			DPSMateX.CombatTime["effective"][1]
		},
		currentfight={
			Handler.DB[2], 
			math.max(DPSMateX.CombatTime["current"], 1.5),
			DPSMateX.CombatTime["effective"][2]
		}
	}
	local num
	for cat, val in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				num = tonumber(strsub(cat, 8))
				if DPSMateX.DPSMateXHistory[Handler.Hist][num] then
					return DPSMateX.DPSMateXHistory[Handler.Hist][num], DPSMateX.CombatTime["segments"][num][1], DPSMateX.CombatTime["segments"][num][2]
				else
					return {}, 0, 0
				end
			else
				return result[cat][1], result[cat][2], result[cat][3]
			end
		end
	end
end

function DPSMateX:GetModeByArr(arr, k, Hist)
	k = k or 1
	self:NormalizeEncounterScope(k)
	if self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then return self.Encounters:GetCoreByArr(arr,k) end
	local result = {total={arr[1], DPSMateX.CombatTime["total"], DPSMateX.CombatTime["effective"][1]}, currentfight={arr[2], DPSMateX.CombatTime["current"], DPSMateX.CombatTime["effective"][2]}}
	local num
	for cat, val in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				num = tonumber(strsub(cat, 8))
				if DPSMateX.DPSMateXHistory[Hist or arr.Hist][num] then
					return DPSMateX.DPSMateXHistory[Hist or arr.Hist][num], DPSMateX.CombatTime["segments"][num][1], DPSMateX.CombatTime["segments"][num][2]
				else
					return {}, 0, 0
				end
			else
				return result[cat][1], result[cat][2], result[cat][3]
			end
		end
	end
end

function DPSMateX:GetModeName(k)
	k = k or 1
	self:NormalizeEncounterScope(k)
	if self.Encounters and self.Encounters.ready and self.Encounters:Scope(k) then return self.Encounters:ScopeName(k) end
	local result = {total="Total", currentfight="Current fight"}
	local num
	for cat, val in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				num = tonumber(strsub(cat, 8))
				return DPSMateX.DPSMateXHistory["names"][num]
			else
				return result[cat]
			end
		end
	end
end

function DPSMateX:NormalizeEncounterScope(k)
    local options=self.Settings.windows[k].options[2]
    if not options.bossall and not options.trashall then return end
    if self.Encounters and self.Encounters.ready then self.Encounters:Normalize(k)
    else
        for key in pairs(options) do options[key]=false end
        options.currentfight=true
        local module=self.RegistredModules[self.Settings.windows[k].CurMode]
        if module then module.acceptNewValues=module.acceptNewValues or {};module.acceptNewValues[k]=true end
    end
end

function DPSMateX:GetSelectedEffectiveTime(k)
    local rows,duration,effective=self:GetMode(k)
    return type(effective)=="table" and effective or {}
end

local nampower_events = {
	"AUTO_ATTACK_SELF",
	"AUTO_ATTACK_OTHER",
	"SPELL_DAMAGE_EVENT_SELF",
	"SPELL_DAMAGE_EVENT_OTHER",
	--"SPELL_ENERGIZE_BY_SELF",
	--"SPELL_ENERGIZE_BY_OTHER",
	"SPELL_MISS_SELF",
	"SPELL_MISS_OTHER",
	"BUFF_ADDED_SELF",
	"BUFF_ADDED_OTHER",
	"DEBUFF_ADDED_SELF",
	"DEBUFF_ADDED_OTHER",
	"BUFF_REMOVED_SELF",
	"BUFF_REMOVED_OTHER",
	"DEBUFF_REMOVED_SELF",
	"DEBUFF_REMOVED_OTHER",
	"AURA_CAST_ON_SELF",
	"AURA_CAST_ON_OTHER",
	"SPELL_HEAL_BY_SELF",
	"SPELL_HEAL_BY_OTHER",
	"AUTO_ATTACK_SELF",
	"AUTO_ATTACK_OTHER",
	"ENVIRONMENTAL_DMG_SELF",
	"ENVIRONMENTAL_DMG_OTHER",
	"DAMAGE_SHIELD_SELF",
	"DAMAGE_SHIELD_OTHER",
	"SPELL_DISPEL_BY_SELF",
	"SPELL_DISPEL_BY_OTHER",
	--"SPELL_FAILED_SELF",
	"SPELL_FAILED_OTHER",
	"SPELL_GO_SELF",
	"SPELL_GO_OTHER",
	"SPELL_START_SELF",
	"SPELL_START_OTHER",
	"UNIT_DIED",
	--for extra hit proc
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
}

function DPSMateX:Disable()
	if self.Registered then
		self.Parser:UnregisterAllEvents()
		--self.Sync:UnregisterEvent("CHAT_MSG_ADDON")

		if DPSMateX.DB.has_nampower then
			for _, val in pairs(nampower_events) do
				DPSMateX.DB:UnregisterEvent(val)
			end
		end
	
		if not DPSMateX.DB.has_nampower then
			self.Parser:RegisterRawEvent(nil)
			self.Parser:UnregisterEvent("UNIT_CASTEVENT")
			self.Parser:UnregisterEvent("RAW_COMBATLOG")
		end
		
		self.Registered = false
	end
end

function DPSMateX:Enable()
	if not self.Registered then
		DPSMateX.DB:AdjustCVars()
		
		self.Parser:UnregisterAllEvents()
		--self.Sync:RegisterEvent("CHAT_MSG_ADDON")
		if not DPSMateX.DB.has_nampower then
			for _, val in pairs(self.RegistredModules) do
				if val.Events then
					for _, event in pairs(val.Events) do
						if 
							not strfind(event, "_DAMAGE$") 
							and not strfind(event, "_HITS$")
							and not strfind(event, "_MISSES$")
							and not strfind(event, "AURA_GONE")
							and not strfind(event, "BREAK_AURA")
							and not strfind(event, "_BUFF")
							and not strfind(event, "_DEATH$")
							and not strfind(event, "DAMAGESHIELDS")
						then
							if self.DB.has_superwow then
								self.Parser:RegisterRawEvent(event)
							else
								self.Parser:RegisterEvent(event)
							end
						end
					end
				end
			end
		
			self.Parser:RegisterEvent("UNIT_CASTEVENT")
			self.Parser:RegisterEvent("RAW_COMBATLOG")
		else
			for _, val in pairs(nampower_events) do
				DPSMateX.DB:RegisterEvent(val)
			end		
		end

		self.Registered = true
	end
end

function DPSMateX:Broadcast(ctype, who, what, with, value, failtype)
	if DPSMateX.Settings["broadcasting"] then
		if IsRaidLeader() or IsRaidOfficer() then
			if strsub(who, 1, 2) == "0x" then who = UnitName(who) end --guid
			local ch = "RAID"
			if DPSMateX.Settings["bcrw"] then
				ch = "RAID_WARNING"
			end
			if not UnitInRaid("player") then
				ch = "PARTY"
			end

			if DPSMateX.Settings["bccd"] and ctype == 1 then
				SendChatMessage(self.L["bccdo"](who, what), ch, nil, nil)
				return
			elseif DPSMateX.Settings["bccd"] and ctype == 6 then
				SendChatMessage(self.L["bccdt"](who, what), ch, nil, nil)
				return
			elseif DPSMateX.Settings["bcress"] and ctype == 2 then
				SendChatMessage(self.L["bcress"](who, what), ch, nil, nil)
				return
			elseif DPSMateX.Settings["bckb"] and ctype == 4 then
				SendChatMessage(self.L["bckb"](who, what, with, value), ch, nil, nil)
				return
			elseif DPSMateX.Settings["bcfail"] and ctype == 3 then
				if failtype == 1 then
					SendChatMessage(self.L["bcfailo"](what, who, value, with), ch, nil, nil)
				elseif failtype == 3 then
					SendChatMessage(self.L["bcfailt"](who, with), ch, nil, nil)
				else
					SendChatMessage(self.L["bcfailth"](who, value, with, what), ch, nil, nil)
				end
				return
			end
		end
	end
end

function DPSMateX:SendMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080"..self.L["name"].."|r: "..msg)
end

function DPSMateX:Register(prefix, table, name)
	self.ModuleNames[name] = prefix
	self.RegistredModules[prefix] = table
	self.EnabledModules[prefix] = nil
	self:CheckModules()
end

function DPSMateX:CheckModules()
	DPSMateX.HasDispelModules = DPSMateX.EnabledModules["decurses"] or DPSMateX.EnabledModules["curepoison"] or DPSMateX.EnabledModules["liftmagic"] or DPSMateX.EnabledModules["curedisease"] or DPSMateX.EnabledModules["dispels"]
	DPSMateX.HasHealingModules = DPSMateX.HasHealingModules or {}
	DPSMateX.HasHealingModules[0] = DPSMateX.EnabledModules["healingtaken"] or DPSMateX.EnabledModules["healing"]
	DPSMateX.HasHealingModules[1] = DPSMateX.EnabledModules["effectivehealingtaken"] or DPSMateX.EnabledModules["effectivehealing"] or DPSMateX.EnabledModules["healingandabsorbs"]
	DPSMateX.HasHealingModules[2] = DPSMateX.EnabledModules["OHealingTaken"] or DPSMateX.EnabledModules["overhealing"]
end

function DPSMateX:ApplyModules()
	for k,v in self.RegistredModules do 
		if DPSMateX:TContains(DPSMateX.Settings["enabledmodes"], k) then
			self.EnabledModules[k] = v
		end
	end
	self:CheckModules()
end

function DPSMateX:EnableModule(prefix)
	self.EnabledModules[prefix] = true
	self:CheckModules()
end

function DPSMateX:DisableModule(prefix)
	self.EnabledModules[prefix] = nil
	self:CheckModules()
end

function DPSMateX:GetAEnabledModule()
	for prefix,enabled in self.EnabledModules do
		if enabled then 
			return prefix
		end
	end
end

function DPSMateX.DB:ResetDB(forceReset, allReset)
	if forceReset then
		if DPSMateX.Encounters then DPSMateX.Encounters:Reset() end
		if DPSMateX.Insights then DPSMateX.Insights:Reset() end
		DPSMateXHistory = nil
		
		if allReset then
			DPSMateXAbility = nil
			DPSMateXUser = nil
			DPSMateX.UserMap = nil
			DPSMateX.UserId = nil
			DPSMateX.AbilityId = nil
		end

		DPSMateXDamageDone = nil
		DPSMateXDamageTaken = nil
		DPSMateXEDD = nil
		DPSMateXEDT = nil
		DPSMateXTHealing = nil
		DPSMateXEHealing = nil
		DPSMateXOverhealing = nil
		DPSMateXHealingTaken = nil
		DPSMateXEHealingTaken = nil
		DPSMateXOverhealingTaken = nil
		DPSMateXAbsorbs = nil
		DPSMateXDispels = nil
		DPSMateXDeaths = nil
		DPSMateXInterrupts = nil
		DPSMateXAurasGained = nil
		DPSMateXThreat = nil
		DPSMateXFails = nil
		DPSMateXCCBreaker = nil
	
		DPSMateXCombatTime = nil
		DPSMateXStats = nil
	end
	
	DPSMateXUserOffHand = nil
end

function DPSMateX.DB:ResetTempTable()
	DPSMateX.DB.LockNLoad = {}
	DPSMateX.DB.NextSwing = {}
	DPSMateX.DB.NextSwingEDD = {}
	DPSMateX.Temp.ActiveMob = {}
	DPSMateX.Temp.Await = {}
	DPSMateX.Temp.broken = {}
	DPSMateX.Temp.DispelTotemCasts = {}
	--DPSMateX.Temp.AwaitHotDispelT = {}
	DPSMateX.Temp.DispelCasts = {}
	DPSMateX.Temp.ActiveHotDispel = {}
	DPSMateX.Temp.DebuffDispelled = {}
	DPSMateX.Temp.AwaitKick = {}
 	DPSMateX.Temp.AfflictedStun = {}
 	DPSMateX.Temp.AwaitBuff = {}
	DPSMateX.Temp.ActiveCC = {}
end

function DPSMateX.DB:AssoicateModuleDB(Module, db)
	if Module then 
		Module.DB = db 
	end
end

function DPSMateX.DB:InitDB()
	DPSMateX.DB:ResetTempTable()

	if DPSMateXSettings == nil then
		DPSMateXSettings = {
			windows = {
				[1] = {
					name = "DPSMateX",
					options = {
						[1] = {
							damage = true
						},
						[2] = {
							total = true
						}
					},
					CurMode = "damage",
					hidden = false,
					scale = 1,
					barfont = "FRIZQT",
					barfontsize = 13,
					barfontflag = "Outline",
					bartexture = "Minimalist",
					barspacing = 1,
					barheight = 17,
					classicons = true,
					ranks = true,
					titlebar = true,
					titlebarfont = "FRIZQT",
					titlebarfontflag = "None",
					titlebarfontsize = 12,
					titlebarheight = 17,
					titlebarreport = true,
					titlebarreset = true,
					titlebarsegments = true,
					titlebarconfig = true,
					titlebarsync = true,
					titlebarenable = true,
					titlebarfilter = true,
					titlebartexture = "Minimalist",
					titlebarbgcolor = {0.1568627450980392,0.1725490196078431,0.1647058823529412},
					titlebarfontcolor = {1.0,0.82,0.0},
					barfontcolor = {1.0,1.0,1.0},
					contentbgtexture = "UI-Tooltip-Background",
					contentbgcolor = {0.01568627450980392,0,1},
					bgbarcolor = {1,1,1},
					numberformat = 1,
					opacity = 1,
					bgopacity = 0,
					titlebaropacity = 1,
					filterclasses = {
						warrior = true,
						rogue = true,
						priest = true,
						hunter = true,
						mage = true,
						warlock = true,
						paladin = true,
						shaman = true,
						druid = true,
					},
					filterpeople = "",
					grouponly = true,
					realtime = false,
					cbtdisplay = false,
					barbg = false,
					totopacity = 1.0,
					borderopacity = 1.0,
					contentbordercolor = {0,0,0},
					borderstrata = 1,
					bordertexture = "UI-Tooltip-Border",
					position = {"CENTER",0,0},
					savsize = {150,100},
				}
			},
			lock = false,
			sync = true,
			enable = true,
			dataresetsworld = 2,
			dataresetsjoinparty = 2,
			dataresetsleaveparty = 2,
			dataresetspartyamount = 2,
			dataresetssync = 3,
			dataresetslogout = 2,
			showminimapbutton = true,
			MinimapButtonPosition = 336,
			showtotals = true,
			hidewhensolo = false,
			hideincombat = false,
			hideinpvp = false,
			disablewhilehidden = false,
			datasegments = 8,
			mergepets = true,
			columnsdps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsdmg = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsdmgtaken = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsdtps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsedd = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsedt = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnshealing = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnshealingtaken = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnshps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsohps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsoverhealing = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsohealingtaken = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsehealing = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsehealingtaken = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsehps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsabsorbs = {
				[1] = true,
				[2] = true,
				[3] = false,
				[4] = false
			},
			columnsabsorbstaken = {
				[1] = true,
				[2] = true,
				[3] = false,
				[4] = false
			},
			columnshab = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsdeaths = {
				[1] = true,
				[2] = true,
			},
			columnsinterrupts = {
				[1] = true,
				[2] = true,
			},
			columnsdispels = {
				[1] = true,
				[2] = true,
			},
			columnsdispelsreceived = {
				[1] = true,
				[2] = true,
			},
			columnsdecurses = {
				[1] = true,
				[2] = true,
			},
			columnsdecursesreceived = {
				[1] = true,
				[2] = true,
			},
			columnsdisease = {
				[1] = true,
				[2] = true,
			},
			columnsdiseasereceived = {
				[1] = true,
				[2] = true,
			},
			columnspoison = {
				[1] = true,
				[2] = true,
			},
			columnspoisonreceived = {
				[1] = true,
				[2] = true,
			},
			columnsmagic = {
				[1] = true,
				[2] = true,
			},
			columnsmagicreceived = {
				[1] = true,
				[2] = true,
			},
			columnsaurasgained = {
				[1] = true,
				[2] = true,
			},
			columnsauraslost = {
				[1] = true,
				[2] = true,
			},
			columnsaurauptime = {
				[1] = true,
				[2] = true,
			},
			columnsprocs = {
				[1] = true,
				[2] = true,
			},
			columnscasts = {
				[1] = true,
				[2] = true,
			},
			columnssunderarmor = {
				[1] = true,
				[2] = true,
			},
			columnsthreat = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnstps = {
				[1] = false,
				[2] = true,
				[3] = true,
				[4] = false
			},
			columnsfails = {
				[1] = true,
				[2] = true,
			},
			columnsccbreaker = {
				[1] = true,
				[2] = true,
			},
			columnsfriendlyfire = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			columnsfriendlyfiretaken = {
				[1] = true,
				[2] = false,
				[3] = true,
				[4] = false
			},
			showtooltips = true,
			informativetooltips = true,
			subviewrows = 4,
			tooltipanchor = 5,
			onlybossfights = true,
			--hiddenmodes = {},
			broadcasting = false,
			bccd = false,
			bcress = false,
			bckb = false,
			bcfail = false,
			bcrw = false,
			targetscale=0.58,
			hideonlogin = false,
			reportdelay = false
		}
	end
	DPSMateX.Settings = DPSMateXSettings

	if not DPSMateX.Settings["enabledmodes"] then
		DPSMateX.Settings["hiddenmodes"] = nil
		DPSMateX.Settings["enabledmodes"] = {
			["damage"] = true,
			["effectivehealing"] = true,
			["healing"] = true,
		}
	end

	if DPSMateXHistory == nil then 
		DPSMateXHistory = {
			names = {},
			DMGDone = {},
			DMGTaken = {},
			EDDone = {},
			EDTaken = {},
			THealing = {},
			EHealing = {},
			OHealing = {},
			EHealingTaken = {},
			THealingTaken = {},
			OHealingTaken = {},
			Absorbs = {},
			Deaths = {},
			Interrupts = {},
			Dispels = {},
			Auras = {},
			Threat = {},
			Fail = {},
			CCBreaker = {}
		}
	end

	if DPSMateXAbility == nil then DPSMateXAbility = {} end
	if DPSMateXUser == nil then DPSMateXUser = {} end
	if DPSMateX.UserMap == nil then DPSMateX.UserMap = {} end
	if DPSMateXDamageDone == nil then DPSMateXDamageDone = {[1]={},[2]={}} end
	if DPSMateXDamageTaken == nil then DPSMateXDamageTaken = {[1]={},[2]={}} end
	if DPSMateXEDD == nil then DPSMateXEDD = {[1]={},[2]={}} end
	if DPSMateXEDT == nil then DPSMateXEDT = {[1]={},[2]={}} end
	if DPSMateXTHealing == nil then DPSMateXTHealing = {[1]={},[2]={}} end
	if DPSMateXEHealing == nil then DPSMateXEHealing = {[1]={},[2]={}} end
	if DPSMateXOverhealing == nil then DPSMateXOverhealing = {[1]={},[2]={}} end
	if DPSMateXHealingTaken == nil then DPSMateXHealingTaken = {[1]={},[2]={}} end
	if DPSMateXEHealingTaken == nil then DPSMateXEHealingTaken = {[1]={},[2]={}} end
	if DPSMateXOverhealingTaken == nil then DPSMateXOverhealingTaken = {[1]={},[2]={}} end
	if DPSMateXAbsorbs == nil then DPSMateXAbsorbs = {[1]={},[2]={}} end
	if DPSMateXDispels == nil then DPSMateXDispels = {[1]={},[2]={}} end
	if DPSMateXDeaths == nil then DPSMateXDeaths = {[1]={},[2]={}} end
	if DPSMateXInterrupts == nil then DPSMateXInterrupts = {[1]={},[2]={}} end
	if DPSMateXAurasGained == nil then DPSMateXAurasGained = {[1]={},[2]={}} end
	if DPSMateXThreat == nil then DPSMateXThreat = {[1]={},[2]={}} end
	if DPSMateXFails == nil then DPSMateXFails = {[1]={},[2]={}} end
	if DPSMateXCCBreaker == nil then DPSMateXCCBreaker = {[1]={},[2]={}} end
	if DPSMateXStats == nil then DPSMateXStats = {} end

	if DPSMateXCombatTime == nil then
		DPSMateXCombatTime = {
			total = 0.0001,
			current = 0.0001,
			segments = {},
			effective = {
				[1] = {},
				[2] = {}
			},
		}
	end
	
	if DPSMateXUserOffHand == nil then DPSMateXUserOffHand = {} end
	
	DPSMateX.DPSMateXHistory = DPSMateXHistory

	DPSMateX.CacheAbility = DPSMateXAbility
	DPSMateX.CacheUser = DPSMateXUser
	
	DPSMateX.DBCache.DamageDone = DPSMateXDamageDone
	DPSMateX.DBCache.DamageTaken = DPSMateXDamageTaken
	DPSMateX.DBCache.EDD = DPSMateXEDD
	DPSMateX.DBCache.EDT = DPSMateXEDT
	DPSMateX.DBCache.THealing = DPSMateXTHealing
	DPSMateX.DBCache.EHealing = DPSMateXEHealing
	DPSMateX.DBCache.Overhealing = DPSMateXOverhealing
	DPSMateX.DBCache.HealingTaken = DPSMateXHealingTaken
	DPSMateX.DBCache.EHealingTaken = DPSMateXEHealingTaken
	DPSMateX.DBCache.OverhealingTaken = DPSMateXOverhealingTaken
	DPSMateX.DBCache.Absorbs = DPSMateXAbsorbs
	DPSMateX.DBCache.Dispels = DPSMateXDispels
	DPSMateX.DBCache.Deaths = DPSMateXDeaths
	DPSMateX.DBCache.Interrupts = DPSMateXInterrupts
	DPSMateX.DBCache.AurasGained = DPSMateXAurasGained
	DPSMateX.DBCache.Threat = DPSMateXThreat
	DPSMateX.DBCache.Fails = DPSMateXFails
	DPSMateX.DBCache.CCBreaker = DPSMateXCCBreaker

	DPSMateX:ReleaseDetailTimelines()
	DPSMateX.CombatTime = DPSMateXCombatTime
	DPSMateX.OffHandAttacking = DPSMateXUserOffHand
	DPSMateX.Stats = DPSMateXStats

	DPSMateX:BuildUserId()
	DPSMateX:BuildAbilityId()

	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.DPS, DPSMateX.DBCache.DamageDone)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Damage, DPSMateX.DBCache.DamageDone)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.DamageTaken, DPSMateX.DBCache.DamageTaken)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.DTPS, DPSMateX.DBCache.DamageTaken)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.EDD, DPSMateX.DBCache.EDD)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.EDT, DPSMateX.DBCache.EDT)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.FriendlyFire, DPSMateX.DBCache.EDT)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.FriendlyFireTaken, DPSMateX.DBCache.EDT)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Healing, DPSMateX.DBCache.THealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.HPS, DPSMateX.DBCache.THealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Overhealing, DPSMateX.DBCache.Overhealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.EffectiveHealing, DPSMateX.DBCache.EHealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.EffectiveHPS, DPSMateX.DBCache.EHealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.HealingTaken, DPSMateX.DBCache.HealingTaken)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.EffectiveHealingTaken, DPSMateX.DBCache.EHealingTaken)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Absorbs, DPSMateX.DBCache.Absorbs)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.AbsorbsTaken, DPSMateX.DBCache.Absorbs)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.HealingAndAbsorbs, DPSMateX.DBCache.Absorbs)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Deaths, DPSMateX.DBCache.Deaths)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Dispels, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.DispelsReceived, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Decurses, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.DecursesReceived, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.CureDisease, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.CureDiseaseReceived, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.CurePoison, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.CurePoisonReceived, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.LiftMagic, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.LiftMagicReceived, DPSMateX.DBCache.Dispels)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Interrupts, DPSMateX.DBCache.Interrupts)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.AurasGained, DPSMateX.DBCache.AurasGained)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.AurasLost, DPSMateX.DBCache.AurasGained)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.AurasUptimers, DPSMateX.DBCache.AurasGained)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Procs, DPSMateX.DBCache.AurasGained)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Casts, DPSMateX.DBCache.EDT)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.SunderArmor, DPSMateX.DBCache.EDT)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Threat, DPSMateX.DBCache.Threat)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.TPS, DPSMateX.DBCache.Threat)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Fails, DPSMateX.DBCache.Fails)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.CCBreaker, DPSMateX.DBCache.CCBreaker)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.OHPS, DPSMateX.DBCache.Overhealing)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.OHealingTaken, DPSMateX.DBCache.OverhealingTaken)
	DPSMateX.DB:AssoicateModuleDB(DPSMateX.Modules.Activity, DPSMateX.CombatTime)
	if DPSMateX.Insights then
		DPSMateX.Insights:Initialize()
		if self:IsCombatActive() then DPSMateX.Insights:StartCombat() end
	end
	if DPSMateX.Encounters then DPSMateX.Encounters:Initialize() end
end

function DPSMateX.DB:ResetCurrentFight()
	if DPSMateX.Encounters then DPSMateX.Encounters:BeforeReset() end
	if DPSMateX.Insights then DPSMateX.Insights:ResetCurrent() end
	DPSMateX.DBCache.DamageDone[2] = DPSMateX.WipeTable(DPSMateX.DBCache.DamageDone[2])
	DPSMateX.DBCache.DamageTaken[2] = DPSMateX.WipeTable(DPSMateX.DBCache.DamageTaken[2])
	DPSMateX.DBCache.EDD[2] = DPSMateX.WipeTable(DPSMateX.DBCache.EDD[2])
	DPSMateX.DBCache.EDT[2] = DPSMateX.WipeTable(DPSMateX.DBCache.EDT[2])
	DPSMateX.DBCache.THealing[2] = DPSMateX.WipeTable(DPSMateX.DBCache.THealing[2])
	DPSMateX.DBCache.EHealing[2] = DPSMateX.WipeTable(DPSMateX.DBCache.EHealing[2])
	DPSMateX.DBCache.Overhealing[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Overhealing[2])
	DPSMateX.DBCache.HealingTaken[2] = DPSMateX.WipeTable(DPSMateX.DBCache.HealingTaken[2])
	DPSMateX.DBCache.EHealingTaken[2] = DPSMateX.WipeTable(DPSMateX.DBCache.EHealingTaken[2])
	DPSMateX.DBCache.OverhealingTaken[2] = DPSMateX.WipeTable(DPSMateX.DBCache.OverhealingTaken[2])
	DPSMateX.DBCache.Absorbs[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Absorbs[2])
	DPSMateX.DBCache.Dispels[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Dispels[2])
	DPSMateX.DBCache.Deaths[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Deaths[2])
	DPSMateX.DBCache.Interrupts[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Interrupts[2])
	DPSMateX.DBCache.AurasGained[2] = DPSMateX.WipeTable(DPSMateX.DBCache.AurasGained[2])
	DPSMateX.DBCache.Threat[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Threat[2])
	DPSMateX.DBCache.Fails[2] = DPSMateX.WipeTable(DPSMateX.DBCache.Fails[2])
	DPSMateX.DBCache.CCBreaker[2] = DPSMateX.WipeTable(DPSMateX.DBCache.CCBreaker[2])
	DPSMateX.CombatTime["current"] = 0.0001
	DPSMateX.CombatTime["effective"][2] = DPSMateX.WipeTable(DPSMateX.CombatTime["effective"][2])
end

function DPSMateX.DB:LoadExtraIcons()
	if DPSMateX.DB.has_nampower then
		DPSMateX.BabbleSpellX.SpellIcons = {}
		
		for i=1, 999999 do
			--nampower api
			local name = GetSpellNameAndRankForId(i)
			local iconId = GetSpellRecField(i,"spellIconID")
			
			if iconId then 
				local icon = GetSpellIconTexture(i)
				if name ~= "" and icon and icon ~= "" and not DPSMateX.BabbleSpellX.SpellIcons[name] then
					local short_icon = strgsub(icon, "^Interface\\Icons\\?", "")
					if short_icon ~= "Temp" then
						DPSMateX.BabbleSpellX.SpellIcons[name] = short_icon
					end
					DPSMateX.BabbleSpellX.SpellMax = i
				end
			end
		end
		DPSMateXSpellIcons = DPSMateX.BabbleSpellX.SpellIcons
	end
end

DPSMateX.DB:ResetDB(true, true)
DPSMateX.DB:InitDB()
