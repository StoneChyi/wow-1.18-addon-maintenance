local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Options.fonts = {
	["FRIZQT"] = UNIT_NAME_FONT,
	["ARIALN"] = "Fonts\\ARIALN.TTF",
	["MORPHEUS"] = "Fonts\\MORPHEUS.TTF",
    ["SKURRI"] = "Fonts\\SKURRI.TTF",
    ["FZBWJW"] = "Fonts\\FZBWJW.TTF",
    ["FZJZJW"] = "Fonts\\FZJZJW.TTF",
    ["FZLBJW"] = "Fonts\\FZLBJW.TTF",
    ["FZXHJW"] = "Fonts\\FZXHJW.TTF",
    ["FZXHLJW"] = "Fonts\\FZXHLJW.TTF",
	--[[
	--latin fonts
	["visitor2"] = "Interface\\AddOns\\DPSMateX\\fonts\\visitor2.TTF",
	["Accidental Presidency"] = "Interface\\AddOns\\DPSMateX\\fonts\\Accidental Presidency.TTF",
	["Enigma__2"] = "Interface\\AddOns\\DPSMateX\\fonts\\Enigma__2.TTF",
	["VeraSe"] = "Interface\\AddOns\\DPSMateX\\fonts\\VeraSe.TTF",
	["AlteHaas"] = "Interface\\AddOns\\DPSMateX\\fonts\\AlteHaas.TTF",
	["CaviarDreams"] = "Interface\\AddOns\\DPSMateX\\fonts\\CaviarDreams.TTF",
	["Expressway"] = "Interface\\AddOns\\DPSMateX\\fonts\\Expressway.TTF",
	["ExpresswayBold"] = "Interface\\AddOns\\DPSMateX\\fonts\\ExpresswayBold.TTF",
	["Roboto"] = "Interface\\AddOns\\DPSMateX\\fonts\\Roboto.TTF",
	["The Bad Times"] = "Interface\\AddOns\\DPSMateX\\fonts\\The Bad Times.TTF",
	--cn fonts
	["Vegur"] = "Interface\\AddOns\\DPSMateX\\fonts\\Vegur.TTF",
	["Mandarin1"] = "Interface\\AddOns\\DPSMateX\\fonts\\Mandarin1.TTF",
	["Mandarin2"] = "Interface\\AddOns\\DPSMateX\\fonts\\Mandarin2.TTF",
	]]
}
DPSMateX.Options.fontflags = {
	["None"] = "NONE",
	["Outline"] = "OUTLINE",
	["Monochrome"] = "MONOCHROME",
	["Outlined monochrome"] = "OUTLINE, MONOCHROME",
	["Tick outlined"] = "THICKOUTLINE",
}
DPSMateX.Options.statusbars = {
	["Aluminium"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Aluminium", 
	["Armory"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Armory", 
	["BantoBar"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\BantoBar", 
	["Glaze2"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Glaze2", 
	["Gloss"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Gloss", 
	["Graphite"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Graphite", 
	["Grid"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Grid", 
	["Healbot"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Healbot", 
	["LiteStep"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\LiteStep", 
	["Minimalist"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Minimalist", 
	["normTex"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\normTex", 
	["Otravi"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Otravi", 
	["Outline"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Outline", 
	["Perl"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Perl", 
	["Round"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Round", 
	["Smooth"] = "Interface\\AddOns\\DPSMateX\\images\\statusbar\\Smooth", 
}
DPSMateX.Options.bgtexture = {
	["Solid Background"] = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	["UI-Tooltip-Background"] = "Interface\\Tooltips\\UI-Tooltip-Background",
}
DPSMateX.Options.stratas = {
	[1] = "BACKGROUND",
	[2] = "LOW",
	[3] = "HIGH",
}
DPSMateX.Options.bordertextures = {
	["UI-Tooltip-Border"] = "Interface\\Tooltips\\UI-Tooltip-Border",
}
DPSMateX.Options.Dewdrop = AceLibrary("DPSDewdrop-2.0")
DPSMateX.Options.graph = AceLibrary("DPSGraph-1.0")
DPSMateX.Options.Options = {
	[1] = {
		type = 'group',
		args = {
		},
		handler = DPSMateX.Options,
	},
	[2] = {
		type = 'group',
		args = {
			total = {
				order = 10,
				type = 'toggle',
				name = DPSMateX.L["total"],
				desc = DPSMateX.L["totalmode"],
				get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["total"] end,
				set = function() DPSMateX.Options:ToggleDrewDrop(2, "total", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
			},
			currentFight = {
				order = 20,
				type = 'toggle',
				name = DPSMateX.L["mcurrent"],
				desc = DPSMateX.L["currentmode"],
				get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["currentfight"] end,
				set = function() DPSMateX.Options:ToggleDrewDrop(2, "currentfight", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
			},
		},
		handler = DPSMateX.Options,
	},
	[3] = {
		type = 'group',
		args = {
			test = {
				order = 5,
				type = 'toggle',
				name = DPSMateX.L["testmode"],
				desc = DPSMateX.L["testmodedesc"],
				get = function() return DPSMateX.Options.TestMode end,
				set = function() DPSMateX.Options:ActivateTestMode(); DPSMateX.Options.Dewdrop:Close() end,
			},
			report = {
				order = 10,
				type = 'execute',
				name = DPSMateX.L["report"],
				desc = DPSMateX.L["reportsegment"],
				func = function() DPSMateX_Report:Show(); DPSMateX.Options.Dewdrop:Close() end,
			},
			reset = {
				order = 11,
				type = 'execute',
				name = DPSMateX.L["reset"],
				desc = DPSMateX.L["resetdesc"],
				func = function() DPSMateX_PopUp:Show(); DPSMateX.Options.Dewdrop:Close() end,
			},
			realtime = {
				order = 12,
				type = 'group',
				name = DPSMateX.L["mrealtime"],
				desc = DPSMateX.L["mrealtimedesc"],
				args = {
					damage = {
						order = 1,
						type = 'execute',
						name = DPSMateX.L["damagedone"],
						desc = DPSMateX.L["realtimedmgdone"],
						func = function() DPSMateX.Options:SelectRealtime(DPSMateX.Options.Dewdrop:GetOpenedParent(), "damage") end
					},
					dmgt = {
						order = 2,
						type = 'execute',
						name = DPSMateX.L["damagetaken"],
						desc = DPSMateX.L["realtimedmgtaken"],
						func = function() DPSMateX.Options:SelectRealtime(DPSMateX.Options.Dewdrop:GetOpenedParent(), "dmgt") end
					},
					heal = {
						order = 3,
						type = 'execute',
						name = DPSMateX.L["healing"],
						desc = DPSMateX.L["realtimehealing"],
						func = function() DPSMateX.Options:SelectRealtime(DPSMateX.Options.Dewdrop:GetOpenedParent(), "heal") end
					},
					eheal = {
						order = 4,
						type = 'execute',
						name = DPSMateX.L["effectivehealing"],
						desc = DPSMateX.L["realtimeehealing"],
						func = function() DPSMateX.Options:SelectRealtime(DPSMateX.Options.Dewdrop:GetOpenedParent(), "eheal") end
					}
				}
			},
			blank1 = {
				order = 20,
				type = 'header',
			},
			startnewsegment = {
				order = 25,
				type = 'execute',
				name = DPSMateX.L["newsegment"],
				desc = DPSMateX.L["newsegmentdesc"],
				func = function() DPSMateX.Options:NewSegment("New segment"); DPSMateX.Options.Dewdrop:Close() end,
			},
			deletesegment = {
				order = 30,
				type = 'group',
				name = DPSMateX.L["removesegment"],
				desc = DPSMateX.L["removesegmentdesc"],
				args = {},
			},
			blank2 = {
				order = 31,
				type = 'header',
			},
			showAll  = {
				order = 32,
				type = 'execute',
				name = DPSMateX.L["showAll"],
				desc = DPSMateX.L["showAllDesc"],
				func = function() for _, val in DPSMateX.Settings["windows"] do DPSMateX.Options:Show(getglobal("DPSMateX_"..val["name"])) end; DPSMateX.Options.Dewdrop:Close() end,
			},
			hideAll  = {
				order = 33,
				type = 'execute',
				name = DPSMateX.L["hideAll"],
				desc = DPSMateX.L["hideAllDesc"],
				func = function() for _, val in DPSMateX.Settings["windows"] do DPSMateX.Options:Hide(getglobal("DPSMateX_"..val["name"])) end; DPSMateX.Options.Dewdrop:Close() end,
			},
			showwindow = {
				order = 36,
				type = 'group',
				name = DPSMateX.L["showwindow"],
				desc = DPSMateX.L["showwindowdesc"],
				args = {},
			},
			hidewindow = {
				order = 37,
				type = 'group',
				name = DPSMateX.L["hidewindow"],
				desc = DPSMateX.L["hidewindowdesc"],
				args = {},
			},
			blank3 = {
				order = 38,
				type = 'header',
			},
			lock = {
				order = 40,
				type = 'toggle',
				name = DPSMateX.L["lock"],
				desc = DPSMateX.L["lockdesc"],
				get = function() return DPSMateX.Settings["lock"] end,
				set = function() DPSMateX.Options:Lock(); DPSMateX.Options.Dewdrop:Close() end,
			},
			unlock = {
				order = 50,
				type = 'toggle',
				name = DPSMateX.L["unlock"],
				desc = DPSMateX.L["unlock"],
				get = function() return not DPSMateX.Settings["lock"] end,
				set = function() DPSMateX.Options:Unlock(); DPSMateX.Options.Dewdrop:Close() end,
			},
			configure = {
				order = 80,
				type = 'execute',
				name = DPSMateX.L["config"],
				desc = DPSMateX.L["config"],
				func = function() DPSMateX_ConfigMenu:Show(); DPSMateX.Options.Dewdrop:Close() end,
			},
			close = {
				order = 90,
				type = 'execute',
				name = DPSMateX.L["close"],
				desc = DPSMateX.L["close"],
				func = function() DPSMateX.Options.Dewdrop:Close() end,
			},
		},
		handler = DPSMateX.Options,
	},
	[4] = {
		type = 'group',
		args = {
			report = {
				order = 10,
				type = 'group',
				name = DPSMateX.L["report"],
				desc = DPSMateX.L["reportdesc"],
				args = {
					whisper = {
						order = 10,
						type = "text",
						name = DPSMateX.L["whisper"],
						desc = DPSMateX.L["whisperdesc"],
						get = function() return "" end,
						set = function(name) DPSMateX.Options:ReportUserDetails(DPSMateX.Options.Dewdrop:GetOpenedParent(), DPSMateX.L["whisper"], name); DPSMateX.Options.Dewdrop:Close() end,
						usage = "<name>",
					},
				},
			},
			compare = {
				order = 20,
				type = 'group',
				name = DPSMateX.L["comparewith"],
				desc = DPSMateX.L["comparewithdesc"],
				args = {
				
				},
			}
		},
		handler = DPSMateX.Options,
	},
	[5] = {
		type = 'group',
		args = {
			classes = {
				order = 10,
				type = 'group',
				name = DPSMateX.L["classes"],
				desc = DPSMateX.L["classesdesc"],
				args = {
					warrior = {
						order = 10,
						type = 'toggle',
						name = DPSMateX.L["warrior"],
						desc = DPSMateX.L["warriordesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["warrior"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "warrior") end,
					},
					rogue = {
						order = 20,
						type = 'toggle',
						name = DPSMateX.L["rogue"],
						desc = DPSMateX.L["roguedesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["rogue"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "rogue") end,
					},
					priest = {
						order = 30,
						type = 'toggle',
						name = DPSMateX.L["priest"],
						desc = DPSMateX.L["priestdesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["priest"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "priest") end,
					},
					hunter = {
						order = 40,
						type = 'toggle',
						name = DPSMateX.L["hunter"],
						desc = DPSMateX.L["hunterdesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["hunter"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "hunter") end,
					},
					druid = {
						order = 50,
						type = 'toggle',
						name = DPSMateX.L["druid"],
						desc = DPSMateX.L["druiddesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["druid"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "druid") end,
					},
					mage = {
						order = 60,
						type = 'toggle',
						name = DPSMateX.L["mage"],
						desc = DPSMateX.L["magedesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["mage"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "mage") end,
					},
					warlock = {
						order = 70,
						type = 'toggle',
						name = DPSMateX.L["warlock"],
						desc = DPSMateX.L["warlockdesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["warlock"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "warlock") end,
					},
					paladin = {
						order = 80,
						type = 'toggle',
						name = DPSMateX.L["paladin"],
						desc = DPSMateX.L["paladindesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["paladin"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "paladin") end,
					},
					shaman = {
						order = 90,
						type = 'toggle',
						name = DPSMateX.L["shaman"],
						desc = DPSMateX.L["shamandesc"],
						get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["shaman"] end,
						set = function() DPSMateX.Options:ToggleFilterClass(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "shaman") end,
					},
				},
			},
			people = {
				order = 20,
				type = 'text',
				name = DPSMateX.L["certainnames"],
				desc = DPSMateX.L["certainnamesdesc"],
				get = function() if DPSMateX.Options.Dewdrop:GetOpenedParent() then return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterpeople"] else return "" end end,
				set = function(names) DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["filterpeople"] = names;DPSMateX:SetStatusBarValue();DPSMateX.Options.Dewdrop:Close() end,
				usage = "<names>",
			},
			group = {
				order = 30,
				type = "toggle",
				name = DPSMateX.L["grouponly"],
				desc = DPSMateX.L["grouponlydesc"],
				get = function() return DPSMateX.Settings["windows"][(DPSMateX.Options.Dewdrop:GetOpenedParent() or DPSMateX).Key or 1]["grouponly"] end,
				set = function() DPSMateX.DB:OnGroupUpdate();DPSMateX.Options:SimpleToggle(DPSMateX.Options.Dewdrop:GetOpenedParent().Key, "grouponly");DPSMateX.Options.Dewdrop:Close() end,
			}
		},
		handler = DPSMateX.Options,
	},
}
DPSMateX.Options.TestMode = false

-- Local Variables
local LastPopUp = 0
local TimeToNextPopUp = 1
local PartyNum, LastPartyNum = 0, 0
local SelectedChannel = DPSMateX.L["raid"]

local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind
local pairs = pairs
local strfind = string.find
local strsub = string.sub
local tonumber = tonumber
-- Begin Functions

function DPSMateX.Options:SelectRealtime(obj, kind)
	if kind then
		local key = obj.Key or 1
		DPSMateX.Settings["windows"][key]["realtime"] = kind
		if not _G(obj:GetName().."_RealTime") then
			local f = CreateFrame("Frame", obj:GetName().."_RealTime", obj, "DPSMateX_RealTime")
			local g = DPSMateX.Options.graph:CreateGraphRealtime(f:GetName().."_Graph",f,"BOTTOMRIGHT","BOTTOMRIGHT",-5,5,190,150)
			g:SetAutoScale(true)
			g:SetGridSpacing(1.0,10.0)
			g:SetYMax(120)
			g:SetXAxis(-11,-1)
			g:SetFilterRadius(1)
			g:SetBarColors({0.2,0.0,0.0,0.4},{1.0,0.0,0.0,1.0})
			g:SetScript("OnUpdate",function() 
				if DPSMateX.DB.loaded and DPSMateX.Settings["windows"][key]["realtime"] then
					g:OnUpdate(g)
					g:AddTimeData(DPSMateX.DB:GetAlpha(key)) 
				end
			end)
			f:Show()
			g:Show()
			DPSMateX.DB:HookGraphEvents()
		else
			 _G(obj:GetName().."_RealTime"):Show()
		end
		DPSMateX.Options.Dewdrop:Close()
	end
end

sss = {}
function DPSMateX.Options:InitializeConfigMenu()
	-- Inialize Extra Buttons
	tinsert(sss, debugstack())
	for cat, val in pairs(DPSMateX.Settings["windows"]) do
		local f = CreateFrame("Button", "DPSMateX_ConfigMenu_Menu_Button"..(9+cat), DPSMateX_ConfigMenu_Menu, "DPSMateX_Template_WindowButton")
		f.Key = cat
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+cat).."Text"):SetText(val["name"])
		if cat>1 then
			f:SetPoint("TOP", _G("DPSMateX_ConfigMenu_Menu_Button"..(8+cat)), "BOTTOM")
			_G("DPSMateX_ConfigMenu_Menu_Button"..(8+cat)).after = f
		else
			f:SetPoint("TOP", DPSMateX_ConfigMenu_Menu_Button1, "BOTTOM")
		end
		f.after = DPSMateX_ConfigMenu_Menu_Button2
		DPSMateX_ConfigMenu.num = 9+cat
		f.func = function()
			_G(this:GetParent():GetParent():GetName()..this:GetParent().selected):Hide()
			_G(this:GetParent():GetParent():GetName().."_Tab_Window"):Show()
			this:GetParent().selected = "_Tab_Window"
		end
	end
	
	local TL = DPSMateX:TableLength(DPSMateX.Settings["windows"])
	if TL>=1 then
		DPSMateX_ConfigMenu_Menu_Button2:ClearAllPoints()
		DPSMateX_ConfigMenu_Menu_Button2:SetPoint("TOP", _G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL)), "BOTTOM")
	end
		
	-- Tab Window
	DPSMateX_ConfigMenu_Tab_Window_Lock:SetChecked(DPSMateX.Settings["lock"])
	
	-- Tab Bars
	if not DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex then
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex = DPSMateX_ConfigMenu_Tab_Bars_BarTexture:CreateTexture("BG", "ARTWORK")
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex:SetWidth(110)
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex:SetHeight(15)
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex:SetPoint("TOPLEFT", DPSMateX_ConfigMenu_Tab_Bars_BarTexture, "TOPLEFT", 23, -7)
	end
	
	-- Tab Title bar
	if not DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex then
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex = DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture:CreateTexture("BG", "ARTWORK")
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetWidth(110)
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetHeight(15)
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetPoint("TOPLEFT", DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture, "TOPLEFT", 23, -7)
	end
	
	-- Tab General Options
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Minimap:SetChecked(DPSMateX.Settings["showminimapbutton"])

	DPSMateX_ConfigMenu_Tab_GeneralOptions_Total:SetChecked(DPSMateX.Settings["showtotals"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_BossFights:SetChecked(DPSMateX.Settings["onlybossfights"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Solo:SetChecked(DPSMateX.Settings["hidewhensolo"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Combat:SetChecked(DPSMateX.Settings["hideincombat"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Login:SetChecked(DPSMateX.Settings["hideonlogin"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_PVP:SetChecked(DPSMateX.Settings["hideinpvp"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Disable:SetChecked(DPSMateX.Settings["disablewhilehidden"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_MergePets:SetChecked(DPSMateX.Settings["mergepets"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Collectgarbage:SetChecked(DPSMateX.Settings["collectgarbage"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_Segments:SetValue(DPSMateX.Settings["datasegments"])
	DPSMateX_ConfigMenu_Tab_GeneralOptions_TargetScale:SetValue(DPSMateX.Settings["targetscale"])
	
	-- Tab Columns
	for i=1, 4 do
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DPS_Check"..i):SetChecked(DPSMateX.Settings["columnsdps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Damage_Check"..i):SetChecked(DPSMateX.Settings["columnsdmg"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DamageTaken_Check"..i):SetChecked(DPSMateX.Settings["columnsdmgtaken"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DTPS_Check"..i):SetChecked(DPSMateX.Settings["columnsdtps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EDD_Check"..i):SetChecked(DPSMateX.Settings["columnsedd"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EDT_Check"..i):SetChecked(DPSMateX.Settings["columnsedt"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Healing_Check"..i):SetChecked(DPSMateX.Settings["columnshealing"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_HealingTaken_Check"..i):SetChecked(DPSMateX.Settings["columnshealingtaken"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_HPS_Check"..i):SetChecked(DPSMateX.Settings["columnshps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Overhealing_Check"..i):SetChecked(DPSMateX.Settings["columnsoverhealing"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EffectiveHealing_Check"..i):SetChecked(DPSMateX.Settings["columnsehealing"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EffectiveHealingTaken_Check"..i):SetChecked(DPSMateX.Settings["columnsehealingtaken"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EffectiveHPS_Check"..i):SetChecked(DPSMateX.Settings["columnsehps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_EffectiveHPS_Check"..i):SetChecked(DPSMateX.Settings["columnsehps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_HAB_Check"..i):SetChecked(DPSMateX.Settings["columnshab"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_FriendlyFire_Check"..i):SetChecked(DPSMateX.Settings["columnsfriendlyfire"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Threat_Check"..i):SetChecked(DPSMateX.Settings["columnsthreat"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_TPS_Check"..i):SetChecked(DPSMateX.Settings["columnstps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Absorbs_Check"..i):SetChecked(DPSMateX.Settings["columnsabsorbs"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_AbsorbsTaken_Check"..i):SetChecked(DPSMateX.Settings["columnsabsorbstaken"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_OHealingTaken_Check"..i):SetChecked(DPSMateX.Settings["columnsohealingtaken"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_OHPS_Check"..i):SetChecked(DPSMateX.Settings["columnsohps"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_FriendlyFireTaken_Check"..i):SetChecked(DPSMateX.Settings["columnsfriendlyfiretaken"][i])
	end
	for i=1, 2 do
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Deaths_Check"..i):SetChecked(DPSMateX.Settings["columnsdeaths"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Interrupts_Check"..i):SetChecked(DPSMateX.Settings["columnsinterrupts"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Dispels_Check"..i):SetChecked(DPSMateX.Settings["columnsdispels"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DispelsReceived_Check"..i):SetChecked(DPSMateX.Settings["columnsdispelsreceived"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Decurses_Check"..i):SetChecked(DPSMateX.Settings["columnsdecurses"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DecursesReceived_Check"..i):SetChecked(DPSMateX.Settings["columnsdecursesreceived"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Disease_Check"..i):SetChecked(DPSMateX.Settings["columnsdisease"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_DiseaseReceived_Check"..i):SetChecked(DPSMateX.Settings["columnsdiseasereceived"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Poison_Check"..i):SetChecked(DPSMateX.Settings["columnspoison"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_PoisonReceived_Check"..i):SetChecked(DPSMateX.Settings["columnspoisonreceived"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Magic_Check"..i):SetChecked(DPSMateX.Settings["columnsmagic"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_MagicReceived_Check"..i):SetChecked(DPSMateX.Settings["columnsmagicreceived"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_AurasGained_Check"..i):SetChecked(DPSMateX.Settings["columnsaurasgained"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_AurasLost_Check"..i):SetChecked(DPSMateX.Settings["columnsauraslost"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_AuraUptime_Check"..i):SetChecked(DPSMateX.Settings["columnsaurauptime"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Procs_Check"..i):SetChecked(DPSMateX.Settings["columnsprocs"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Casts_Check"..i):SetChecked(DPSMateX.Settings["columnscasts"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_SunderArmor_Check"..i):SetChecked(DPSMateX.Settings["columnssunderarmor"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_Fails_Check"..i):SetChecked(DPSMateX.Settings["columnsfails"][i])
		_G("DPSMateX_ConfigMenu_Tab_Columns_Child_CCBreaker_Check"..i):SetChecked(DPSMateX.Settings["columnsccbreaker"][i])
	end
	
	-- Tab Tooltips
	DPSMateX_ConfigMenu_Tab_Tooltips_Tooltips:SetChecked(DPSMateX.Settings["showtooltips"])
	DPSMateX_ConfigMenu_Tab_Tooltips_InformativeTooltips:SetChecked(DPSMateX.Settings["informativetooltips"])
	DPSMateX_ConfigMenu_Tab_Tooltips_Rows:SetValue(DPSMateX.Settings["subviewrows"])
	
	-- Tab Broadcasting
	DPSMateX_ConfigMenu_Tab_Broadcasting_Enable:SetChecked(DPSMateX.Settings["broadcasting"])
	DPSMateX_ConfigMenu_Tab_Broadcasting_Cooldowns:SetChecked(DPSMateX.Settings["bccd"])
	DPSMateX_ConfigMenu_Tab_Broadcasting_Ress:SetChecked(DPSMateX.Settings["bcress"])
	DPSMateX_ConfigMenu_Tab_Broadcasting_KillingBlows:SetChecked(DPSMateX.Settings["bckb"])
	DPSMateX_ConfigMenu_Tab_Broadcasting_Fails:SetChecked(DPSMateX.Settings["bcfail"])
	DPSMateX_ConfigMenu_Tab_Broadcasting_RaidWarning:SetChecked(DPSMateX.Settings["bcrw"])
	
	-- Mode menu
	for num,v in DPSMateX.ModuleNames do
		if not DPSMateX:TContains(DPSMateX.Settings["enabledmodes"], v) then
			DPSMateX.Options.Options[1]["args"][v] = nil
		end
	end
end

DPSMateX.Options.OldLogout = Logout
function DPSMateX.Options:Logout()
	if DPSMateX.Settings["sync"] then
		if UnitInRaid("player") then
			DPSMateX:SendMessage(DPSMateX.L["syncreseterror"])
		else
			DPSMateX.Options:PopUpAccept(true, true)
		end
	else
		DPSMateX.Options:PopUpAccept(true, true)
	end
	--self:SumGraphData()
	DPSMateX.Options.OldLogout()
end
Logout = function() 
	if DPSMateX.Settings["dataresetslogout"] == 3 then
		DPSMateX_Logout:Show() 
	elseif DPSMateX.Settings["dataresetslogout"] == 2 then
		--DPSMateX.Options:SumGraphData()
		DPSMateX.Options.OldLogout()
	else
		DPSMateX.Options:Logout()
	end
end

function DPSMateX.Options:ToggleVisibility()
	for _, val in DPSMateX.Settings["windows"] do
		if val["hidden"] then
			getglobal("DPSMateX_"..val["name"]):Show()
			val["hidden"] = false
		else
			getglobal("DPSMateX_"..val["name"]):Hide()
			val["hidden"] = true
		end
	end
end

function DPSMateX.Options:ActivateTestMode()
	if self.TestMode then
		self.TestMode = false
		DPSMateX:SetStatusBarValue()
	else
		self.TestMode = true
		for k,c in DPSMateX.Settings.windows do
			if DPSMateX.Settings["showtotals"] then
				_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_Total_Name"):SetText("Total")
				_G("DPSMateX_"..c["name"].."_ScrollFrame_Child_Total_Value"):SetText("3000000")
			end
			for i=1, DPSMateX.MaxRows do
				local statusbar, name, value, texture, p = _G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i), _G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"), _G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value"), _G("DPSMateX_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Icon"), ""
				_G("DPSMateX_"..c["name"].."_ScrollFrame_Child"):SetHeight((i+1)*(c["barheight"]+c["barspacing"]))
				
				statusbar:SetStatusBarColor(0.78,0.61,0.43, 1)
				
				if c["ranks"] then p=i..". " else p="" end
				name:SetText(p.."Test "..i)
				value:SetText("100000")
				texture:SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\warrior")
				statusbar:SetValue(100)
				
				statusbar.user = nil
				statusbar:Show()
			end
		end
	end
end

function DPSMateX.Options:ToggleFilterClass(key, class)
	if DPSMateX.Settings["windows"][key]["filterclasses"][class] then
		DPSMateX.Settings["windows"][key]["filterclasses"][class] = false
	else
		DPSMateX.Settings["windows"][key]["filterclasses"][class] = true
	end
	DPSMateX:SetStatusBarValue()
end

function DPSMateX.Options:SimpleToggle(key, opt)
	if DPSMateX.Settings["windows"][key][opt] then
		DPSMateX.Settings["windows"][key][opt] = false
	else
		DPSMateX.Settings["windows"][key][opt] = true
	end
	DPSMateX:SetStatusBarValue()
end

function DPSMateX.Options:RosterUpdate()
	this:HideWhenSolo()
	if this:IsInParty() then
		if LastPartyNum == 0 then
			if DPSMateX.Settings["dataresetsjoinparty"] == 3 then
				if (GetTime()-LastPopUp) > TimeToNextPopUp then
					this:ShowResetPopUp()
					LastPopUp = GetTime()
				end
			elseif DPSMateX.Settings["dataresetsjoinparty"] == 1 then
				this:PopUpAccept(true, true)
			end
		elseif LastPartyNum ~= PartyNum	then
			if DPSMateX.Settings["dataresetspartyamount"] == 3 then
				if (GetTime()-LastPopUp) > TimeToNextPopUp then
					this:ShowResetPopUp()
					LastPopUp = GetTime()
				end
			elseif DPSMateX.Settings["dataresetspartyamount"] == 1 then
				this:PopUpAccept(true)
			end
		end
	else
		if LastPartyNum > PartyNum then
			if DPSMateX.Settings["dataresetsleaveparty"] == 3 then
				if (GetTime()-LastPopUp) > TimeToNextPopUp then
					this:ShowResetPopUp()
					LastPopUp = GetTime()
				end
			elseif DPSMateX.Settings["dataresetsleaveparty"] == 1 then
				this:PopUpAccept(true)
			end
		end
	end
	DPSMateX.DB:OnGroupUpdate()
end

DPSMateX.Options.PARTY_MEMBERS_CHANGED = function()
	this:RosterUpdate()
end

DPSMateX.Options.RAID_ROSTER_UPDATE = function()
	this:RosterUpdate()
end

DPSMateX.Options.PLAYER_ENTERING_WORLD = function()
	local player = UnitName("player")
	_, DPSMateX.Parser.playerclass = UnitClass("player")
	DPSMateX.DB:BuildUser(player, strlower(DPSMateX.Parser.playerclass))

	DPSMateX.Parser.playername = player
	DPSMateX.Parser.player = player
	if DPSMateX.DB.has_nampower then _,DPSMateX.Parser.player = GetUnitGUID("player") end

	if DPSMateX.Settings["dataresetsworld"] == 3 then
		if (GetTime()-LastPopUp) > TimeToNextPopUp then
			DPSMateX.Options:ShowResetPopUp()
			LastPopUp = GetTime()
		end
	elseif DPSMateX.Settings["dataresetsworld"] == 1 and not DPSMateX.Options:IsInParty() then
		DPSMateX.Options:PopUpAccept(true)
	end

	DPSMateX.Options:HideInPvP()
	
	if DPSMateX.Settings["hideonlogin"] then
		for _, val in pairs(DPSMateX.Settings["windows"]) do
			DPSMateX.Options:Hide(_G("DPSMateX_"..val["name"]))
		end
	end
	
	local frames = {"", "_Absorbs", "_AbsorbsTaken", "_Auras", "_Casts", "_SunderArmor", "_CCBreaker", "_CureDisease", "_CureDiseaseReceived", "_CurePoison", "_CurePoisonReceived", "_DamageTaken", "_DamageTakenTotal", "_DamageTotal", "_Deaths", "_Decurses", "_DecursesReceived", "_Dispels", "_DispelsReceived", "_EDD", "_EDT", "_EHealing", "_EHealingTaken", "_Fails", "_FF", "_FFT", "_Healing", "_HealingTaken", "_Interrupts", "_LiftMagic", "_LiftMagicReceived", "_OHealingTaken", "_Overhealing", "_Procs", "_AbsorbsTakenTotal", "_AbsorbsTotal", "_AurasTotal", "_CastsTotal", "_SunderArmorTotal", "_CCBreakerTotal", "_CureDisease_Total", "_CurePoison_Total", "_Deaths_Total", "_Decurses_Total", "_Dispels_Total", "_EDDTotal", "_EDTTotal", "_EHealingTakenTotal", "_EHealingTotal", "_FailsTotal", "_FFTotal", "_FFTTotal", "_HABTotal", "_HealingTakenTotal", "_HealingTotal", "_Interrupts_Total", "_LiftMagic_Total", "_OverhealingTakenTotal", "_OverhealingTotal", "_ProcsTotal"}
	for cat, val in pairs(frames) do
		if _G("DPSMateX_Details"..val) then
			_G("DPSMateX_Details"..val):SetFrameStrata("DIALOG")
		end
	end
	
	DPSMateX:OnLoad()
	DPSMateX.Options:InitializeSegments()
	DPSMateX.Options:InitializeHideShowWindow()

	DPSMateX.Parser:OnLoad()
	DPSMateX.DB:OnLoad()
	DPSMateX.Sync:OnLoad()

	DPSMateX.DB:OnGroupUpdate()

	DPSMateX.DB.loaded = true
	DPSMateX.DB.NeedUpdate = true
	
	DPSMateX:SetStatusBarValue()
end

function DPSMateX.Options:ShowResetPopUp()
	if DPSMateX.Settings["sync"] then
		if IsPartyLeader() or IsRaidOfficer() or IsRaidLeader() then
			DPSMateX_PopUp:Show()
		end
	else
		DPSMateX_PopUp:Show()
	end
end

function DPSMateX.Options:IsInBattleground()
	for i=1, 4 do
		local status, mapName, instanceID, lowestlevel, highestlevel, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if status == "active" then
			return true
		end
	end
	return false
end

function DPSMateX.Options:HideInPvP()
	for _, val in pairs(DPSMateX.Settings["windows"]) do
		local frame = _G("DPSMateX_"..val["name"])
		if DPSMateX.Options:IsInBattleground() and DPSMateX.Settings["hideinpvp"] then
			if frame then frame:Hide() end
			if DPSMateX.Settings["disablewhilehidden"] then
				DPSMateX:Disable()
			end
		end
	end
	DPSMateX.Options:HideWhenSolo()
end

function DPSMateX.Options:HideWhenSolo()
	for _, val in pairs(DPSMateX.Settings["windows"]) do
		local frame = _G("DPSMateX_"..val["name"])
		if DPSMateX.Settings["hidewhensolo"] and not DPSMateX.Options:IsInBattleground() then
			if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
				if frame then frame:Hide() end
				if DPSMateX.Settings["disablewhilehidden"] then
					DPSMateX:Disable()
				end
			else
				if not val["hidden"] then
					frame:Show()
				end
				DPSMateX:Enable()
			end
		end
	end
end

function DPSMateX.Options:IsInParty()
	LastPartyNum = PartyNum
	if UnitInRaid("player") then
		PartyNum = GetNumRaidMembers()
		return true
	elseif GetNumPartyMembers() > 0 then
		PartyNum = GetNumPartyMembers()
		return true
	else
		PartyNum = 0
		return false
	end
end

function DPSMateX.Options:PopUpAccept(bool, bypass, thorough)
	if DPSMate and DPSMate.Options then DPSMate.Options:PopUpAccept(bool, bypass, thorough) end
	
	DPSMateX_PopUp:Hide()
	if (GetNumPartyMembers()>0 or UnitInRaid("player")) and not bypass and DPSMateX.Settings["sync"] and bool then
		if IsPartyLeader() or IsRaidOfficer() or IsRaidLeader() then
			DPSMateX.Sync:StartVote()
		else
			DPSMateX:SendMessage(DPSMateX.L["resetnotofficererror"])
			return
		end
	else
		if bool then
			DPSMateX.DB:ResetDB(true, thorough)
			DPSMateX.DB:InitDB()

			if thorough then
				DPSMateX.DB:OnGroupUpdate()
			end
			
			DPSMateX.DB:CollectBuffs()
		else
			DPSMateX.DB:ResetCurrentFight()
		end
		
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
		
		-- Hackfix to fix the hunter issue where the player is not shown if pet damage is merged
		--DPSMateX.DB:DamageDone(UnitName("player"), "Init", 0, 0, 0, 0, 0, 0, 0, 0, 0) 
		DPSMateX.Options:InitializeSegments()
		DPSMateX:SetStatusBarValue()
	end
end

function DPSMateX.Options:OpenMenu(b, obj)
	for _, val in pairs(DPSMateX.Settings.windows) do
		if DPSMateX.Options.Dewdrop:IsOpen(_G("DPSMateX_"..val["name"])) then
			DPSMateX.Options.Dewdrop:Close()
			return
		end
		if DPSMateX.Options.Dewdrop:IsRegistered(_G("DPSMateX_"..val["name"])) then DPSMateX.Options.Dewdrop:Unregister(_G("DPSMateX_"..val["name"])) end
	end
	DPSMateX.Options.Dewdrop:Register(obj,
		'children', function() 
			DPSMateX.Options.Dewdrop:FeedAceOptionsTable(DPSMateX.Options.Options[b]) 
		end,
		'cursorX', true,
		'cursorY', true,
		'dontHook', true
	)
	DPSMateX.Options.Dewdrop:Open(obj)
end
	
function DPSMateX.Options:ToggleDrewDrop(i, obj, pa, no_sbv)
	if not DPSMateX.Settings["windows"][1] then return end

	if i == 1 then --toggle mode (damage, healing, etc)
		--check and uncheck DPSMateX_ConfigMenu_Tab_GeneralOptions_Total
		for cat, _ in pairs(DPSMateX.Settings["windows"][pa.Key]["options"][i]) do
			DPSMateX.Settings["windows"][pa.Key]["options"][i][cat] = false
		end
		DPSMateX.Settings["windows"][pa.Key]["options"][i][obj] = true

		if not DPSMateX.Options.Options[1]["args"][obj] then
			obj = "damage"
		end
		_G(pa:GetName().."_Head_Font"):SetText(DPSMateX.Options.Options[i]["args"][obj].name)
		DPSMateX.Settings["windows"][pa.Key]["CurMode"] = obj
	else --toggle data segments
		DPSMateX.Options:ToggleSegment(pa.Key, obj)
	end

	DPSMateX.Options.Dewdrop:Close()
	if DPSMateX.DB.loaded and not no_sbv then DPSMateX:SetStatusBarValue() end
	return true
end

function DPSMateX.Options:UpdateDetails(obj, bool, objname)
	if objname then
		obj = _G(objname)
	end
	local key = obj:GetParent():GetParent():GetParent().Key
	if obj.user then
		DPSMateX.RegistredModules[DPSMateX.Settings["windows"][key]["CurMode"]]:OpenDetails(obj, key, bool)
	else
		DPSMateX:SendMessage(DPSMateX.L["findusererror"])
	end
end

function DPSMateX.Options:UpdateTotalDetails(obj)
	local key = obj:GetParent():GetParent():GetParent().Key
	DPSMateX.RegistredModules[DPSMateX.Settings["windows"][key]["CurMode"]]:OpenTotalDetails(obj, key)
end

function DPSMateX.Options:DropDownStyleReset()
	for i=1, 20 do
		local button = _G("DropDownList1Button"..i)
		_G("DropDownList1Button"..i.."NormalText"):SetFont(STANDARD_TEXT_FONT, UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT)
		button:SetScript("OnEnter", function()
			 if ( this.hasArrow ) then
			  ToggleDropDownMenu(this:GetParent():GetID() + 1, this.value);
			else
			  --CloseDropDownMenus(this:GetParent():GetID() + 1);
			end
			getglobal(this:GetName().."Highlight"):Show();
			UIDropDownMenu_StopCounting(this:GetParent());
			if ( this.tooltipTitle ) then
			  GameTooltip_AddNewbieTip(this.tooltipTitle, 1.0, 1.0, 1.0, this.tooltipText, 1);
			end
		end)
		_G("DropDownList1Backdrop"):SetBackdrop({ 
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, 
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
		if button.tex then
			button.tex:Hide()
		end
	end
end

function DPSMateX.Options:UpdateConfigModes(obj, o, p) 
	local line, lineplusoffset
	local TL = DPSMateX:TableLength(DPSMateX.ModuleNames)
	local path, t = obj:GetName().."_Button", {}
	if p then
		for cat, val in DPSMateX.ModuleNames do
			if val ~= "damage" then
				if DPSMateX:TContains(DPSMateX.Settings["enabledmodes"], val) then
					tinsert(t, 1, cat)
					if not DPSMateX.EnabledModules[val] then
						DPSMateX:EnableModule(val)
					end
				end
			end
		end
	else
		for cat, val in DPSMateX.ModuleNames do
			if val ~= "damage" then
				if not DPSMateX:TContains(DPSMateX.Settings["enabledmodes"], val) then
					tinsert(t, 1, cat)
					if DPSMateX.EnabledModules[val] then
						DPSMateX:DisableModule(val)
						for k,v in DPSMateX.Settings["windows"] do
							if DPSMateX.Settings["windows"][k]["CurMode"] == val then
								local frame = _G("DPSMateX_"..v["name"])
								DPSMateX.Options:ToggleDrewDrop(1, "damage", frame, true)
							end
						end
					end
				end
			end
		end
		if DPSMateX.DB.loaded then DPSMateX:SetStatusBarValue() end
	end
	local TL = DPSMateX:TableLength(t)
	obj.offset = (obj.offset or 0) - o 
	if obj.offset > (TL-15) then obj.offset = (TL-15) end
	if obj.offset < 0 then obj.offset = 0 end
	for line=1, 15 do
		lineplusoffset = line + obj.offset
		if t[lineplusoffset] then
			_G(path..line.."Text"):SetText(t[lineplusoffset])
			_G(path..line):Show()
		else
			_G(path..line):Hide()
		end
		_G(path..line.."Texture"):Hide()
		_G(path..line.."Text"):SetTextColor(1,1,1,1)
		_G(path..line).selected = false
	end
end
--[[
DPSMateX.Options.ShowMenu = UnitPopup_ShowMenu
function UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	DPSMateX.Options:DropDownStyleReset()
	DPSMateX.Options.ShowMenu(dropdownMenu, which, unit, name, userData)
end
--]]
DPSMateX.Options.UIDDI = UIDropDownMenu_Initialize
function UIDropDownMenu_Initialize(frame, initFunction, displayMode, level)
	if string.find(frame:GetName(), "DPSMateX_ConfigMenu") then
		DPSMateX.Options:DropDownStyleReset()
	end
	DPSMateX.Options.UIDDI(frame, initFunction, displayMode, level)
end

DPSMateX.Options.UICDD = CloseDropDownMenus
function CloseDropDownMenus(num)
	for i=1, 20 do
		local button = _G("DropDownList1Button"..i)
		if button.tex then
			button.tex:Hide()
		end
	end
	DPSMateX.Options.UICDD(num)
end

function DPSMateX.Options:ChannelDropDown()
	local channel, i = DPSMateX.L["reportchannel"], 1
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_Report_Channel, this.value)
    end
	
	-- Adding dynamic channel
	for i=0,25 do
		local id, name = GetChannelName(i);
		if name then
			if not DPSMateX:TContains(channel, name) then
				tinsert(channel, name)
			end
		end
	end
	
	-- Initializing channel
	for cat, val in pairs(channel) do
		UIDropDownMenu_AddButton{
			text = val,
			value = val,
			func = on_click,
		}
	end
	
	UIDropDownMenu_SetSelectedValue(DPSMateX_Report_Channel, SelectedChannel)
end

function DPSMateX.Options:WindowDropDown()
	DPSMateX_ConfigMenu.Selected = "None"
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(_G(UIDROPDOWNMENU_OPEN_MENU), this.value)
		if UIDROPDOWNMENU_OPEN_MENU == "DPSMateX_ConfigMenu_Tab_Window_Remove" then
			DPSMateX_ConfigMenu.Selected = this.value
		end
    end
	
	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}

	for _, val in pairs(DPSMateX.Settings["windows"]) do
		UIDropDownMenu_AddButton{
			text = val["name"],
			value = val["name"],
			func = on_click,
		}
	end
	
	if not DPSMateX_ConfigMenu.vis then
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Window_Remove, "None")
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Window_ConfigFrom, "None")
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Window_ConfigTo, "None")
	end
	DPSMateX_ConfigMenu.vis = true
end

function DPSMateX.Options:BarFontDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Bars_BarFont, this.value)
		DPSMateX_ConfigMenu_Tab_Bars_BarFontText:SetFont(DPSMateX.Options.fonts[this.value], 12)
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"] = this.value
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_Name"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_Value"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		for i=1, DPSMateX.MaxRows do
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"):SetFont(DPSMateX.Options.fonts[this.value], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value"):SetFont(DPSMateX.Options.fonts[this.value], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		end
    end
	
	for name, path in pairs(DPSMateX.Options.fonts) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(path, 16)
		i=i+1
	end
end

function DPSMateX.Options:BarFontFlagsDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Bars_BarFontFlag, this.value)
		DPSMateX_ConfigMenu_Tab_Bars_BarFontFlagText:SetFont(DPSMateX.Options.fonts["FRIZQT"], 12, DPSMateX.Options.fontflags[this.value])
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"] = this.value
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_Name"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_Value"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		for i=1, DPSMateX.MaxRows do
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfont"]], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["barfontflag"]])
		end
    end
	
	for name, flag in pairs(DPSMateX.Options.fontflags) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(DPSMateX.Options.fonts["FRIZQT"], 12, flag)
		i=i+1
	end
end

function DPSMateX.Options:BarTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Bars_BarTexture, this.value)
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["bartexture"] = this.value
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex:SetTexture(DPSMateX.Options.statusbars[this.value])
		DPSMateX_ConfigMenu_Tab_Bars_BarTexture.tex:Show()
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total"):SetStatusBarTexture(DPSMateX.Options.statusbars[this.value])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_BG"):SetTexture(DPSMateX.Options.statusbars[this.value])
		for i=1, DPSMateX.MaxRows do
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i):SetStatusBarTexture(DPSMateX.Options.statusbars[this.value])
			_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_BG"):SetTexture(DPSMateX.Options.statusbars[this.value])
		end
	end
	
	for name, path in pairs(DPSMateX.Options.statusbars) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		if not button.tex then
			button.tex = button:CreateTexture("BG", "BACKGROUND")
			button.tex:SetTexture(path)
			button.tex:SetWidth(100)
			button.tex:SetHeight(20)
			button.tex:SetPoint("TOPLEFT", button, "TOPLEFT")
		end
		button.tex:Show()
		i=i+1
	end
end

function DPSMateX.Options:TitleBarTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture, this.value)
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebartexture"] = this.value
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetTexture(DPSMateX.Options.statusbars[this.value])
		DPSMateX_ConfigMenu_Tab_TitleBar_BarTexture.tex:Show()
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Head_Background"):SetTexture(DPSMateX.Options.statusbars[this.value])
    end
	
	for name, path in pairs(DPSMateX.Options.statusbars) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		if not button.tex then
			button.tex = button:CreateTexture("BG", "BACKGROUND")
			button.tex:SetTexture(path)
			button.tex:SetWidth(100)
			button.tex:SetHeight(20)
			button.tex:SetPoint("TOPLEFT", button, "TOPLEFT")
		end
		button.tex:Show()
		i=i+1
	end
end

function DPSMateX.Options:TitleBarFontDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_TitleBar_BarFont, this.value)
		DPSMateX_ConfigMenu_Tab_TitleBar_BarFontText:SetFont(DPSMateX.Options.fonts[this.value], 12)
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebarfont"] = this.value
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Head_Font"):SetFont(DPSMateX.Options.fonts[this.value], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebarfontsize"], DPSMateX.Options.fontflags[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebarfontflag"]])
    end
	
	for name, path in pairs(DPSMateX.Options.fonts) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(path, 16)
		i=i+1
	end
end

function DPSMateX.Options:TitleBarFontFlagsDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_TitleBar_BarFontFlag, this.value)
		DPSMateX_ConfigMenu_Tab_TitleBar_BarFontFlagText:SetFont(DPSMateX.Options.fonts["FRIZQT"], 12, DPSMateX.Options.fontflags[this.value])
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebarfontflag"] = this.value
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Head_Font"):SetFont(DPSMateX.Options.fonts[DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["titlebarfont"]], 12, DPSMateX.Options.fontflags[this.value])
    end
	
	for name, flag in pairs(DPSMateX.Options.fontflags) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(DPSMateX.Options.fonts["FRIZQT"], 12, flag)
		i=i+1
	end
end

function DPSMateX.Options:ContentBGTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Content_BGDropDown, this.value)
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgtexture"] = this.value
		_G("DPSMateX_ConfigMenu_Tab_Content_BGDropDown_Texture"):SetBackdrop({ 
			bgFile = DPSMateX.Options.bgtexture[this.value], 
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 12, edgeSize = 12, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		_G("DPSMateX_ConfigMenu_Tab_Content_BGDropDown_Texture"):SetBackdropColor(DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][1], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][2], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][3])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Background"):SetTexture(DPSMateX.Options.bgtexture[this.value])
    end
	
	for name, path in pairs(DPSMateX.Options.bgtexture) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		button.path = path
		button.i = i
		button:SetScript("OnEnter", function()
			_G(this:GetName().."Highlight"):Show()
			_G("DropDownList1Backdrop"):SetBackdrop({ 
				bgFile = this.path, 
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, 
				insets = { left = 11, right = 12, top = 12, bottom = 11 }
			})
			_G("DropDownList1Backdrop"):SetBackdropColor(DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][1], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][2], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbgcolor"][3])
		end)
		i=i+1
	end
end

function DPSMateX.Options:SelectDataResets(obj, case)
	local vars = {["DPSMateX_ConfigMenu_Tab_DataResets_EnteringWorld"] = "dataresetsworld", ["DPSMateX_ConfigMenu_Tab_DataResets_PartyMemberChanged"] = "dataresetspartyamount", ["DPSMateX_ConfigMenu_Tab_DataResets_JoinParty"] = "dataresetsjoinparty", ["DPSMateX_ConfigMenu_Tab_DataResets_LeaveParty"] = "dataresetsleaveparty", ["DPSMateX_ConfigMenu_Tab_DataResets_Sync"] = "dataresetssync", ["DPSMateX_ConfigMenu_Tab_DataResets_Logout"] = "dataresetslogout"}
	DPSMateX.Settings[vars[obj:GetName()]] = case
	UIDropDownMenu_SetSelectedValue(obj, case)
end

function DPSMateX.Options:DataResetsDropDown()
	local btns = {DPSMateX.L["yes"], DPSMateX.L["no"], DPSMateX.L["ask"]}
	
	local function on_click()
		DPSMateX.Options:SelectDataResets(_G(UIDROPDOWNMENU_OPEN_MENU), this.value)
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
	
	if not DPSMateX_ConfigMenu.visBars8 then
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_EnteringWorld, DPSMateX.Settings["dataresetsworld"])
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_JoinParty, DPSMateX.Settings["dataresetsjoinparty"])
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_PartyMemberChanged, DPSMateX.Settings["dataresetspartyamount"])
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_LeaveParty, DPSMateX.Settings["dataresetsleaveparty"])
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_Sync, DPSMateX.Settings["dataresetssync"])
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_DataResets_Logout, DPSMateX.Settings["dataresetslogout"])
	end
	DPSMateX_ConfigMenu.visBars8 = true
end

function DPSMateX.Options:NumberFormatDropDown()
	local btns = {DPSMateX.L["normal"], DPSMateX.L["condensed"], DPSMateX.L["commas"], DPSMateX.L["semicondensed"]}
	
	local function on_click()
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["numberformat"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Content_NumberFormat, DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["numberformat"])
		DPSMateX:SetStatusBarValue()
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
end

function DPSMateX.Options:BorderStrataDropDown()
	local btns = {"Background", "Low", "High"}
	
	local function on_click()
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["borderstrata"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Content_BorderStrata, DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["borderstrata"])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Border"):SetFrameStrata(DPSMateX.Options.stratas[this.value])
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
end

function DPSMateX.Options:BorderTextureDropDown()
	local function on_click()
		DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["bordertexture"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Content_BorderTexture, DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["bordertexture"])
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Border"):SetBackdrop({ 
																												  bgFile = "", 
																												  edgeFile = DPSMateX.Options.bordertextures[this.value], tile = true, tileSize = 12, edgeSize = 10, 
																												  insets = { left = 5, right = 5, top = 3, bottom = 1 }
																												})
		_G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["name"].."_Border"):SetBackdropBorderColor(DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbordercolor"][1], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbordercolor"][2], DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key]["contentbordercolor"][3])
	end
	
	for val, _ in pairs(DPSMateX.Options.bordertextures) do
		UIDropDownMenu_AddButton{
			text = val,
			value = val,
			func = on_click,
		}
	end
end

function DPSMateX.Options:TooltipPositionDropDown()
	local btns = {DPSMateX.L["default"], DPSMateX.L["topright"], DPSMateX.L["topleft"], DPSMateX.L["left"], DPSMateX.L["top"]}
	
	local function on_click()
		DPSMateX.Settings["tooltipanchor"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Tooltips_Position, DPSMateX.Settings["tooltipanchor"])
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
	
	if not DPSMateX_ConfigMenu.visBars10 then
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Tooltips_Position, DPSMateX.Settings["tooltipanchor"])
	end
	DPSMateX_ConfigMenu.visBars10 = true
end

function DPSMateX.Options:Report()
	local channel = UIDropDownMenu_GetSelectedValue(DPSMateX_Report_Channel)
	SelectedChannel = channel
	local arr, cbt, ecbt = DPSMateX:GetMode(DPSMateX_Report.PaKey)
	local chn, index, name, value, b = nil, nil, nil, nil, nil
	name, value, b = DPSMateX:GetSettingValues(arr, cbt, DPSMateX_Report.PaKey, ecbt)
	if (channel == DPSMateX.L["whisper"]) then
		chn = "WHISPER"; index = DPSMateX_Report_Editbox:GetText();
	elseif DPSMateX:TContains(DPSMateX.L["gchannel"], channel) then
		chn = strupper(channel)
	else
		chn = "CHANNEL"; index = GetChannelName(channel)
	end

	ChatThrottleLib:SendChatMessage("BULK", "DPSMateXChat", DPSMateX.L["name"].." - "..DPSMateX.L["reportfor"]..DPSMateX:GetModeName(DPSMateX_Report.PaKey or 1).." - ".._G("DPSMateX_"..DPSMateX.Settings["windows"][DPSMateX_Report.PaKey or 1]["name"].."_Head_Font"):GetText().." - "..b[1].."-"..b[2], chn, nil, index)
	for i=1, DPSMateX_Report_Lines:GetValue() do
		if (not value[i] or value[i] == 0) then break end
		if DPSMateX.Settings["reportdelay"] then
			tinsert(DPSMateX.DelayMsg, {i..". "..name[i].." -"..value[i], chn, index})
		else
			ChatThrottleLib:SendChatMessage("BULK", "DPSMateXChat", i..". "..name[i].." -"..value[i], chn, nil, index)
		end
	end
	DPSMateX_Report:Hide()
end

local SendChatMessage = SendChatMessage
local type = type

local AbilityModes = {"damage", "dps", "healing", "hps", "OHPS", "overhealing", "effectivehealing", "effectivehps", "deaths", "interrupts", "dispels", "decurses", "curedisease", "curepoison", "liftmagic", "aurasgained", "auraslost", "aurasuptime", "procs", "casts", "sunderarmor", "ccbreaker", "healingandabsorbs"}
function DPSMateX.Options:ReportUserDetails(obj, channel, name)
	local Key, user = obj:GetParent():GetParent():GetParent().Key, obj.user
	local _, cbt, ecbt = DPSMateX:GetMode(Key)
	local a,b,c
	if DPSMateX.Settings["windows"][Key]["CurMode"] == "deaths" then
		a,b,c = DPSMateX.RegistredModules[DPSMateX.Settings["windows"][Key]["CurMode"]]:EvalTable(DPSMateX.CacheUser[user], Key)
	else
		a,b,c = DPSMateX.RegistredModules[DPSMateX.Settings["windows"][Key]["CurMode"]]:EvalTable(DPSMateX.CacheUser[user], Key, cbt, ecbt)
	end
	local chn, index
	if (channel == DPSMateX.L["whisper"]) then
		chn = "WHISPER"; index = name;
	elseif DPSMateX:TContains(DPSMateX.L["gchannel"], channel) then
		chn = strupper(channel)
	else
		chn = "CHANNEL"; index = GetChannelName(channel)
	end
	local bb = ""
	if not b and not a then
		return
	end
	if b~=0 then
		bb = " - "..strformat("%.2f", b)
	end
	SendChatMessage(DPSMateX.L["name"].." - "..DPSMateX.L["reportof"].." "..user.."'s ".._G("DPSMateX_"..DPSMateX.Settings["windows"][Key]["name"].."_Head_Font"):GetText().." - "..DPSMateX:GetModeName(Key)..bb, chn, nil, index)
	for i=1, 10 do
		if (not a[i]) then break end
		
		local ablity = a[i]
		if type(ablity) == "table" then ablity = ablity[1] end

		local p
		if type(c[i])=="table" then p = strformat("%.2f", c[i][1]).." ("..strformat("%.2f", 100*c[i][1]/b).."%)" else p = strformat("%.2f", c[i]).." ("..strformat("%.2f", 100*c[i]/b).."%)" end
		if DPSMateX.Settings["windows"][Key]["CurMode"] == "aurasuptime" then p = strformat("%.2f%%", c[i]) end
		if DPSMateX.Settings["windows"][Key]["CurMode"] == "deaths" then
			local ctype = " (HIT)"
			if c[i][3]==1 then ctype=" (CRIT)" elseif c[i][3]==2 then ctype=" (CRUSH)" end
			if c[i][2]==1 then
				if DPSMateX.Settings["reportdelay"] then
					tinsert(DPSMateX.DelayMsg, {i..". |cFF8cff80"..DPSMateX:GetAbilityById(ablity).." => ".."+"..c[i][1]..ctype.."|r", chn, index})
				else
					SendChatMessage(i..". |cFF8cff80"..DPSMateX:GetAbilityById(ablity).." => ".."+"..c[i][1]..ctype.."|r", chn, nil, index)
				end
			else
				if DPSMateX.Settings["reportdelay"] then
					tinsert(DPSMateX.DelayMsg, {i..". |cFFFF8080"..DPSMateX:GetAbilityById(ablity).." => ".."-"..c[i][1]..ctype.."|r", chn, index})
				else
					SendChatMessage(i..". |cFFFF8080"..DPSMateX:GetAbilityById(ablity).." => ".."-"..c[i][1]..ctype.."|r", chn, nil, index)
				end
			end
		else
			if DPSMateX.Settings["windows"][Key]["CurMode"] == "fails" then
				if DPSMateX.Settings["reportdelay"] then
					tinsert(DPSMateX.DelayMsg, {i..". "..DPSMateX.Modules.Fails:Type(ablity).." - "..p, chn, index})
				else
					SendChatMessage(i..". "..DPSMateX.Modules.Fails:Type(ablity).." - "..p, chn, nil, index)
				end
			else
				if DPSMateX:TContains(AbilityModes, DPSMateX.Settings["windows"][Key]["CurMode"]) or DPSMateX.RegistredModules[DPSMateX.Settings["windows"][Key]["CurMode"]].Insights then
					if DPSMateX.Settings["reportdelay"] then
						tinsert(DPSMateX.DelayMsg, {i..". "..DPSMateX:GetAbilityById(ablity).." - "..p, chn, index})
					else
						SendChatMessage(i..". "..DPSMateX:GetAbilityById(ablity).." - "..p, chn, nil, index)
					end
				else
					if DPSMateX.Settings["reportdelay"] then
						tinsert(DPSMateX.DelayMsg, {i..". "..DPSMateX:GetUserById(ablity).." - "..p, chn, index})
					else
						SendChatMessage(i..". "..DPSMateX:GetUserById(ablity).." - "..p, chn, nil, index)
					end
				end
			end
		end
	end
end

local hexClassColor = {
	warrior = "C79C6E",
	rogue = "FFF569",
	priest = "FFFFFF",
	druid = "FF7D0A",
	warlock = "9482C9",
	mage = "69CCF0",
	hunter = "ABD473",
	paladin = "F58CBA",
	shaman = "0070DE",
}

local CompareExcept = {
	[DPSMateX.L["enemydamagedone"]] = true,
	[DPSMateX.L["enemydamagetaken"]] = true
}
function DPSMateX.Options:InializePlayerDewDrop(obj)
	local channel, i = DPSMateX.L["gchannel"], 1
	local path = DPSMateX.Options.Options[4]["args"]["report"]["args"]
	-- Name
	DPSMateX.Options.Options[4]["args"]["player"] = {
		order = 1,
		type = "header",
		name = obj.user,
	}
	DPSMateX.Options.Options[4]["args"]["details"] = {
		order = 2,
		type = "execute",
		name = DPSMateX.L["opendetails"],
		desc = DPSMateX.L["opendetails"],
		func = function() DPSMateX.Options:UpdateDetails(obj); DPSMateX.Options.Dewdrop:Close() end,
	}
	
	-- Report channel
	for i=0, 25 do
		local id, name = GetChannelName(i);
		if name then
			if not DPSMateX:TContains(channel, name) then
				tinsert(channel, name)
			end
		end
	end
	
	for cat, val in channel do
		path["a"..cat] = {
			order = 10*cat+10,
			type = "execute",
			name = val,
			desc = DPSMateX.L["reportdetails"],
			func = loadstring('DPSMateX.Options:ReportUserDetails(DPSMateX.Options.Dewdrop:GetOpenedParent(), "'..val..'"); DPSMateX.Options.Dewdrop:Close()'),
		}
	end
	
	-- Compare with player
	DPSMateX.Options.Options[4]["args"]["compare"]["args"] = {}
	path = DPSMateX.Options.Options[4]["args"]["compare"]["args"]
	local Key = obj:GetParent():GetParent():GetParent().Key
	local db,cbt, ecbt = DPSMateX:GetMode(Key)
	local temp = ''
	local a = DPSMateX:GetSettingValues(db, cbt, Key, ecbt)
	for cat, name in a do
		if name and name ~= obj.user then
			if DPSMateX.Settings["windows"][Key]["grouponly"] then
				if DPSMateX.Parser.TargetParty[name] then
					if temp=='' then
						temp = '"'..name..'"'
					else
						temp = temp..',"'..name..'"'
					end
				end
			else
				if temp=='' then
					temp = '"'..name..'"'
				else
					temp = temp..',"'..name..'"'
				end
			end
		end
	end
	-- No clue what is wrong here. Fuck it
	temp = assert(loadstring('return {'..temp..'}')) ();
	sort(temp)
	
	local mode = _G(obj:GetParent():GetParent():GetParent():GetName().."_Head_Font"):GetText()
	for mo, ti in strgfind(mode, "(.+) %[(.+)%]") do
		mode = mo
	end
	
	for cat, val in temp do
		if cat>100 then break end
		if not strfind(val, "%s") or CompareExcept[mode] then
			path["Arg"..cat] = {
				order = 1,
				type = "execute",
				name = "|cFF"..hexClassColor[DPSMateX.CacheUser[val][2] or "warrior"]..val.."|r",
				desc = DPSMateX.L["opendetails"],
				func = loadstring('DPSMateX.Options:UpdateDetails(nil, "'..val..'", "'..obj:GetName()..'"); DPSMateX.Options.Dewdrop:Close()'),
			}
		end
	end
end

function DPSMateX.Options:FormatTime(time)
	if time>60 then
		local rest = ceil(mod(time, 60))
		if rest<10 then
			rest = "0"..rest
		end
		return floor(time/60)..":"..rest.."m"
	else
		return strformat("%.2f", time).."s"
	end
end

DPSMateX.debug = nil
function DPSMateX.Options:NewSegment(segname)
	local max = 0
	local a = ""
	-- Get name of this session
	for c, v in pairs(DPSMateX.DBCache.EDT[2]) do
		local CV = 0
		for cat, val in pairs(v) do
			if cat~="i" then
				CV = CV+val["i"]
			end
		end
		if max<CV then
			max = CV
			a = c
		end
	end
	local extra = ""
	if a or segname~=nil then
		local name = segname
		if not segname then
			name = DPSMateX:GetUserById(a)
			name = name or DPSMateX.L["unknown"]
			extra = " - CBT: "..self:FormatTime(DPSMateX.CombatTime["current"])
		end
		if name ~= DPSMateX.L["unknown"] or (name == DPSMateX.L["unknown"]) then
			local bossname = DPSMateX.BabbleBoss:Contains(name)
			if bossname and type(bossname) == "string" then name = bossname end

			if DPSMateX.Settings["onlybossfights"] then
				if bossname then
					DPSMateX.Options:CreateSegment(name..extra)
				end
			else
				DPSMateX.Options:CreateSegment(name..extra)
			end
		end
		
		DPSMateX.DB:ResetCurrentFight()
		
		DPSMateX:SetStatusBarValue()
	end
end

function DPSMateX.Options:CreateSegment(name)
	-- Need to add a new check
	local modes = {
		["DMGDone"] = DPSMateX.DBCache.DamageDone[2],
		["DMGTaken"] = DPSMateX.DBCache.DamageTaken[2],
		["EDDone"] = DPSMateX.DBCache.EDD[2],
		["EDTaken"] = DPSMateX.DBCache.EDT[2],
		["THealing"] = DPSMateX.DBCache.THealing[2],
		["EHealing"] = DPSMateX.DBCache.EHealing[2],
		["OHealing"] =  DPSMateX.DBCache.Overhealing[2],
		["EHealingTaken"] = DPSMateX.DBCache.EHealingTaken[2],
		["THealingTaken"] = DPSMateX.DBCache.HealingTaken[2],
		["Absorbs"] = DPSMateX.DBCache.Absorbs[2],
		["Deaths"] = DPSMateX.DBCache.Deaths[2],
		["Interrupts"] = DPSMateX.DBCache.Interrupts[2],
		["Dispels"] = DPSMateX.DBCache.Dispels[2],
		["Auras"] = DPSMateX.DBCache.AurasGained[2],
	}
	
	local segmentLabel = name.." - "..GameTime_GetTime()
	if DPSMateX.Insights then DPSMateX.Insights:SaveSegment(segmentLabel) end
	tinsert(DPSMateX.DPSMateXHistory["names"], 1, segmentLabel)
	for cat, val in pairs(modes) do
		tinsert(DPSMateX.DPSMateXHistory[cat], 1, DPSMateX:CopyTable(val))
		if DPSMateX:TableLength(DPSMateX.DPSMateXHistory[cat])>DPSMateX.Settings["datasegments"] then
			for i=DPSMateX.Settings["datasegments"]+1, DPSMateX:TableLength(DPSMateX.DPSMateXHistory[cat]) do
				tremove(DPSMateX.DPSMateXHistory[cat], i)
			end
			tremove(DPSMateX.DPSMateXHistory[cat], DPSMateX.Settings["datasegments"]+1)
		end
		if DPSMateX:TableLength(DPSMateX.CombatTime["segments"])>DPSMateX.Settings["datasegments"] then
			for i=DPSMateX.Settings["datasegments"]+1, DPSMateX:TableLength(DPSMateX.CombatTime["segments"]) do
				tremove(DPSMateX.CombatTime["segments"], i)
			end
		end
	end
	tinsert(DPSMateX.CombatTime["segments"], 1, {[1]=DPSMateX.CombatTime["current"], [2]=DPSMateX.CombatTime["effective"][2]})
	DPSMateX.Options:InitializeSegments()
end

function DPSMateX.Options:InitializeSegments()
	local i=1
	DPSMateX.Options.Options[2]["args"] = {
		total = {
			order = 10,
			type = 'toggle',
			name = DPSMateX.L["total"],
			desc = DPSMateX.L["totalmode"],
			get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["total"] end,
			set = function() DPSMateX.Options:ToggleDrewDrop(2, "total", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
		},
		currentFight = {
			order = 20,
			type = 'toggle',
			name = DPSMateX.L["mcurrent"],
			desc = DPSMateX.L["currentmode"],
			get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["currentfight"] end,
			set = function() DPSMateX.Options:ToggleDrewDrop(2, "currentfight", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
		},
	}
	DPSMateX.Options.Options[3]["args"]["deletesegment"]["args"] = {}
	for cat, val in pairs(DPSMateX.DPSMateXHistory["DMGDone"]) do
		if not val then break end
		DPSMateX.Options.Options[2]["args"]["segment"..i] = {
			order = 20+i*10,
			type = 'toggle',
			name = i..". "..DPSMateX.DPSMateXHistory["names"][i],
			desc = DPSMateX.L["fdetailsfor"]..DPSMateX.DPSMateXHistory["names"][i],
			get = loadstring('return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["segment'..i..'"];'),
			set = loadstring('DPSMateX.Options:ToggleDrewDrop(2, "segment'..i..'", DPSMateX.Options.Dewdrop:GetOpenedParent());'),
		}
		DPSMateX.Options.Options[3]["args"]["deletesegment"]["args"]["segment"..i] = {
			order = i*10,
			type = 'execute',
			name = i..". "..DPSMateX.DPSMateXHistory["names"][i],
			desc = DPSMateX.L["removesegmentof"]..DPSMateX.DPSMateXHistory["names"][i],
			func = loadstring('DPSMateX.Options:RemoveSegment('..i..');'),
		}
		i=i+1
	end
	
	for k, val in pairs(DPSMateX.Settings["windows"]) do
		local obj
		
		for cat, checked in pairs(val["options"][2]) do
			if strfind(cat, "segment") then
				if DPSMateX.DPSMateXHistory["DMGDone"][tonumber(strsub(cat, 8))] then
					if checked then obj = cat break end
				end
			else
				if checked then obj = cat break end
			end
		end
		
		if not obj then 
			DPSMateX.Options:ToggleSegment(k, "total")
			DPSMateX:SetStatusBarValue()
		 end
	end
end

function DPSMateX.Options:ToggleSegment(k, obj)
	for cat, _ in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		DPSMateX.Settings["windows"][k]["options"][2][cat] = false
	end
	DPSMateX.Settings["windows"][k]["options"][2][obj] = true

	local module = DPSMateX.RegistredModules[DPSMateX.Settings["windows"][k]["CurMode"]]
	if module then 
		module.acceptNewValues = module.acceptNewValues or {}
		module.acceptNewValues[k] = (obj == "total" or obj == "currentfight")
	end
end

function DPSMateX.Options:OnVerticalScroll(obj, arg1, pre, spec)
	pre = pre or 20
	local maxScroll = _G(obj:GetName().."_Child"):GetHeight()-100
	if spec then maxScroll = maxScroll + 100 end
	local Scroll = obj:GetVerticalScroll()
	local toScroll = (Scroll - (pre*arg1))
	if toScroll < 0 or maxScroll < 0 then
		obj:SetVerticalScroll(0)
	elseif toScroll > maxScroll then
		obj:SetVerticalScroll(maxScroll)
	else
		obj:SetVerticalScroll(toScroll)
	end
end

function DPSMateX.Options:CreateWindow()
	local na = string.gsub(DPSMateX_ConfigMenu_Tab_Window_Editbox:GetText(), "%s", "")
	if (na and not DPSMateX:GetKeyByValInTT(DPSMateX.Settings["windows"], na, "name") and na~="") then
		tinsert(DPSMateX.Settings["windows"], {
			name = na,
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
		})
		local TL = DPSMateX:TableLength(DPSMateX.Settings["windows"])
		if not _G("DPSMateX_"..na) then
			local fr=CreateFrame("Frame", "DPSMateX_"..na, UIParent, "DPSMateX_Statusframe")
			fr.Key=TL
		end
		_G("DPSMateX_"..na):Show()
		if not _G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL)) then
			local f = CreateFrame("Button", "DPSMateX_ConfigMenu_Menu_Button"..(9+TL), DPSMateX_ConfigMenu_Menu, "DPSMateX_Template_WindowButton")
			f.Key = TL
		end
		local frame = _G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL))
		frame:Show()
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL).."Text"):SetText(na)
		if TL>1 then
			frame:SetPoint("TOP", _G("DPSMateX_ConfigMenu_Menu_Button"..(8+TL)), "BOTTOM")
			_G("DPSMateX_ConfigMenu_Menu_Button"..(8+TL)).after = frame
		else
			frame:SetPoint("TOP", DPSMateX_ConfigMenu_Menu_Button1, "BOTTOM")
		end
		frame.after = DPSMateX_ConfigMenu_Menu_Button2
		DPSMateX_ConfigMenu.num = 9+TL
		frame.func = function()
			_G(this:GetParent():GetParent():GetName()..this:GetParent().selected):Hide()
			_G(this:GetParent():GetParent():GetName().."_Tab_Window"):Show()
			this:GetParent().selected = "_Tab_Window"
		end
		DPSMateX_ConfigMenu_Menu_Button2:ClearAllPoints()
		DPSMateX_ConfigMenu_Menu_Button2:SetPoint("TOP", frame, "BOTTOM")
		DPSMateX:InitializeFrames()
		_G("DPSMateX_"..na.."_Head_Font"):SetText(DPSMateX.L["damage"])
		_G("DPSMateX_"..na.."_ScrollFrame_Child"):SetWidth(150)
		_G("DPSMateX_"..na.."_ScrollFrame"):SetHeight(84)
		DPSMateX:SetStatusBarValue()
	end
end

function DPSMateX.Options:RemoveWindow()
	local frame = _G("DPSMateX_"..DPSMateX_ConfigMenu.Selected)
	if frame then
		frame:Hide()
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key)):Hide()
		tremove(DPSMateX.Settings["windows"], frame.Key)
		local TL = DPSMateX:TableLength(DPSMateX.Settings["windows"])
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL)).after = DPSMateX_ConfigMenu_Menu_Button2
		DPSMateX_ConfigMenu_Menu_Button2:ClearAllPoints()
		DPSMateX_ConfigMenu_Menu_Button2:SetPoint("TOP", _G("DPSMateX_ConfigMenu_Menu_Button"..(9+TL)), "BOTTOM")
		UIDropDownMenu_SetSelectedValue(DPSMateX_ConfigMenu_Tab_Window_Remove, "None")
		DPSMateX_ConfigMenu_Menu_Button1.selected = true
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key)).selected = false
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key).."Texture"):Hide()
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key).."Text"):SetTextColor(1,0.82,0,1)
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key).."_Button1"):Hide()
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key).."_Button2"):Hide()
		_G("DPSMateX_ConfigMenu_Menu_Button"..(9+frame.Key).."_Button3"):Hide()
		DPSMateX_ConfigMenu_Menu_Button1Texture:Show()
	end
end

function DPSMateX.Options:CopyConfiguration()
	local fromName = _G("DPSMateX_ConfigMenu_Tab_Window_ConfigFromText"):GetText()
	local toName = _G("DPSMateX_ConfigMenu_Tab_Window_ConfigToText"):GetText()
	if fromName~="None" and toName~="None" then
		local fromKey = _G("DPSMateX_"..fromName).Key
		local toKey = _G("DPSMateX_"..toName).Key
		for cat, val in pairs(DPSMateX.Settings["windows"][fromKey]) do
			if cat~="name" and cat~="options" then
				DPSMateX.Settings["windows"][toKey][cat] = val
			end
		end
		DPSMateX:InitializeFrames()
	end
end

function DPSMateX.Options:Lock()
	DPSMateX.Settings.lock = true
	for _,val in pairs(DPSMateX.Settings["windows"]) do
		local frame = _G("DPSMateX_"..val["name"])
		frame:StopMovingOrSizing()
		frame:SetResizable(false)
		_G("DPSMateX_"..val["name"].."_Resize"):Hide()
		_G("DPSMateX_"..val["name"].."_ResizeLU"):Hide()
	end
	-- Saving positions to prevent a potential crash
	local point, _, _, xOfs, yOfs;
	for key, val in DPSMateX.Settings["windows"] do
		if _G("DPSMateX_"..val["name"]) then
			point, _, _, xOfs, yOfs = _G("DPSMateX_"..val["name"]):GetPoint()
			DPSMateX.Settings["windows"][key]["position"] = {}
			DPSMateX.Settings["windows"][key]["position"][1] = point
			DPSMateX.Settings["windows"][key]["position"][2] = xOfs
			DPSMateX.Settings["windows"][key]["position"][3] = yOfs
			DPSMateX.Settings["windows"][key]["savsize"] = {}
			DPSMateX.Settings["windows"][key]["savsize"][1] = _G("DPSMateX_"..val["name"]):GetWidth()
			DPSMateX.Settings["windows"][key]["savsize"][2] = _G("DPSMateX_"..val["name"]):GetHeight()
		end
	end
	DPSMateX:SendMessage(DPSMateX.L["lockedallw"])
end

function DPSMateX.Options:Unlock()
	DPSMateX.Settings.lock = false
	for _,val in pairs(DPSMateX.Settings["windows"]) do
		_G("DPSMateX_"..val["name"]):SetResizable(true)
		_G("DPSMateX_"..val["name"].."_Resize"):Show()
		_G("DPSMateX_"..val["name"].."_ResizeLU"):Show()
	end
	DPSMateX:SendMessage(DPSMateX.L["unlockedallw"])
end

function DPSMateX.Options:Hide(frame)
	if frame then
		DPSMateX.Settings["windows"][frame.Key]["hidden"] = true
		frame:Hide() 
	end
end

function DPSMateX.Options:Show(frame)
	DPSMateX.Settings["windows"][frame.Key]["hidden"] = false
	frame:Show()
end

function DPSMateX.Options:RemoveSegment(i)
	if DPSMateX.Insights then DPSMateX.Insights:RemoveSegment(i) end
	for cat, val in DPSMateX.DPSMateXHistory do
		tremove(DPSMateX.DPSMateXHistory[cat], i)
	end
	DPSMateX.Options:InitializeSegments()
	DPSMateX.Options.Dewdrop:Close()
end

function DPSMateX.Options:ToggleTitleBarButtonState()
	--local buttons = {"Config", "Reset", "Segments", "Filter", "Report", "Sync", "Enable"}
	local buttons = {"Config", "Reset", "Segments", "Filter", "Report", "Enable"}
	for _, val in pairs(DPSMateX.Settings["windows"]) do
		local parent, i = _G("DPSMateX_"..val["name"].."_Head"), 0
		for _, name in pairs(buttons) do
			local button = _G("DPSMateX_"..val["name"].."_Head_"..name)
			if val["titlebar"..strlower(name)] then
				button:ClearAllPoints()
				button:SetPoint("RIGHT", parent, "RIGHT", -i*15-2, 0)
				button:Show()
				i=i+1
			else
				button:Hide()
			end
		end
	end
end

function DPSMateX.Options:ToggleState()
	if DPSMateX.Settings["enable"] then
		DPSMateX.Settings["sync"] = false
		DPSMateX.Settings["enable"] = false
		DPSMateX:Disable()
		for cat, val in DPSMateX.Settings["windows"] do
			_G("DPSMateX_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(1,0,0,1)
			_G("DPSMateX_"..val["name"].."_Head_Enable"):SetChecked(false)
		end
	else
		DPSMateX.Settings["enable"] = true
		DPSMateX:Enable()
		for cat, val in DPSMateX.Settings["windows"] do
			_G("DPSMateX_"..val["name"].."_Head_Enable"):SetChecked(true)
		end
	end
	--for convinience
	if DPSMate and DPSMate.Options then DPSMate.Options:ToggleState() end
end

function DPSMateX.Options:SetColor()
	local r,g,b = ColorPickerFrame:GetColorRGB()
	local swatch,frame
	swatch = _G(ColorPickerFrame.obj:GetName().."NormalTexture")
	frame = _G(ColorPickerFrame.obj:GetName().."_SwatchBg")
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b
	
	DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key][ColorPickerFrame.var] = {r,g,b}
	
	ColorPickerFrame.rfunc()
end

function DPSMateX.Options:CancelColor()
	local r = ColorPickerFrame.previousValues.r
	local g = ColorPickerFrame.previousValues.g
	local b = ColorPickerFrame.previousValues.b
	local swatch,frame
	swatch = _G(ColorPickerFrame.obj:GetName().."NormalTexture")
	frame = _G(ColorPickerFrame.obj:GetName().."_SwatchBg")
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b
	
	DPSMateX.Settings["windows"][DPSMateX_ConfigMenu_Menu.Key][ColorPickerFrame.var] = {r,g,b}
	
	ColorPickerFrame.rfunc()
end

function DPSMateX.Options:OpenColorPicker(obj, var, func)
	CloseMenus()
	
	button = _G(obj:GetName().."_SwatchBg")
	
	ColorPickerFrame.obj = obj
	ColorPickerFrame.var = var
	ColorPickerFrame.rfunc = func
	
	ColorPickerFrame.func = DPSMateX.Options.SetColor
	ColorPickerFrame:SetColorRGB(button.r, button.g, button.b)
	ColorPickerFrame.previousValues = {r = button.r, g = button.g, b = button.b, opacity = button.opacity}
	ColorPickerFrame.cancelFunc = DPSMateX.Options.CancelColor

	ColorPickerFrame:SetPoint("TOPLEFT", obj, "TOPRIGHT", 0, 0)
	
	ColorPickerFrame:SetFrameStrata("TOOLTIP")
	
	ColorPickerFrame:Show()
end

function DPSMateX.Options:ShowTooltip()
	if not this.user then return end
	if DPSMateX.Settings["showtooltips"] then
		DPSMateX_Details.PaKey = this:GetParent():GetParent():GetParent().Key
		if DPSMateX.Settings["tooltipanchor"] == 1 then
			GameTooltip:SetOwner(UIParent, "BOTTOMRIGHT")
		elseif DPSMateX.Settings["tooltipanchor"] == 2 then
			GameTooltip:SetOwner(this:GetParent():GetParent():GetParent(), "RIGHT")
		elseif DPSMateX.Settings["tooltipanchor"] == 3 then
			GameTooltip:SetOwner(this:GetParent():GetParent():GetParent(), "LEFT")
		elseif DPSMateX.Settings["tooltipanchor"] == 4 then
			GameTooltip:SetOwner(this:GetParent():GetParent():GetParent(), "TOP")
		elseif DPSMateX.Settings["tooltipanchor"] == 5 then
			GameTooltip:SetOwner(this:GetParent():GetParent():GetParent(), "TOPRIGHT")
		end
		local _, cbt = DPSMateX:GetMode(DPSMateX_Details.PaKey)
		GameTooltip:AddLine(this.user.." ["..self:FormatTime(cbt).."]", 1,0.82,0,1)
		DPSMateX.RegistredModules[DPSMateX.Settings["windows"][DPSMateX_Details.PaKey]["CurMode"]]:ShowTooltip(this.user, DPSMateX_Details.PaKey)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(DPSMateX.L["leftclickopend"], 0,1,0,1)
		GameTooltip:AddLine(DPSMateX.L["rightclickopenm"], 0,1,0,1)
		GameTooltip:Show()
	end
end

function DPSMateX.Options:InitializeHideShowWindow()
	local i = 1
	DPSMateX.Options.Options[3]["args"]["hidewindow"]["args"] = {}
	DPSMateX.Options.Options[3]["args"]["showwindow"]["args"] = {}
	for _,val in pairs(DPSMateX.Settings["windows"]) do
		DPSMateX.Options.Options[3]["args"]["hidewindow"]["args"][val["name"]] = {
			order = i*10,
			type = 'execute',
			name = val["name"],
			desc = DPSMateX.L["hide"].." "..val["name"],
			func = loadstring('DPSMateX.Options:Hide(getglobal("DPSMateX_'..val["name"]..'")); DPSMateX.Options.Dewdrop:Close();'),
		}
		DPSMateX.Options.Options[3]["args"]["showwindow"]["args"][val["name"]] = {
			order = i*10,
			type = 'execute',
			name = val["name"],
			desc = DPSMateX.L["show"].." "..val["name"],
			func = loadstring('DPSMateX.Options:Show(getglobal("DPSMateX_'..val["name"]..'")); DPSMateX.Options.Dewdrop:Close();'),
		}
		i=i+1
	end
end

function DPSMateX.Options:CheckButton(name, id)
	DPSMateX.Settings[name] = DPSMateX.Settings[name] or {}
	if DPSMateX.Settings[name][id] then
		DPSMateX.Settings[name][id] = false
	else
		DPSMateX.Settings[name][id] = true
	end
	DPSMateX:SetStatusBarValue()
end

function DPSMateX.Options:ToggleSync()
	if DPSMateX.Settings["sync"] then
		DPSMateX.Settings["sync"] = false
		for _, val in pairs(DPSMateX.Settings["windows"]) do
			_G("DPSMateX_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(1,0,0,1)
		end
	else
		DPSMateX.Settings["sync"] = true
		DPSMateX.Settings["enable"] = true
		for _, val in pairs(DPSMateX.Settings["windows"]) do
			_G("DPSMateX_"..val["name"].."_Head_Enable"):SetChecked(true)
			_G("DPSMateX_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(0.67,0.83,0.45,1)
		end
	end
	DPSMateX.Sync.synckey = ""
end

local reportdelay = 0.5
local reportuptime = 0
function DPSMateX.Options:OnUpdate()
	reportuptime = reportuptime + arg1
	if reportuptime>reportdelay then
		reportuptime = 0
		if DPSMateX.Settings["reportdelay"] and DPSMateX.DelayMsg[1] then
			SendChatMessage(DPSMateX.DelayMsg[1][1], DPSMateX.DelayMsg[1][2], nil, DPSMateX.DelayMsg[1][3])
			tremove(DPSMateX.DelayMsg, 1)
		end
	end
end

function DPSMateX.Options:MinimapButtonSetPosition(v)
	if(v < 0) then
		v = v + 360;
	end
	DPSMateX.Options.MinimapButtonPosition = v;
	DPSMateX.Settings["MinimapButtonPosition"] = v
	DPSMateX.Options:MinimapButtonUpdatePosition();
end

function DPSMateX.Options:MinimapButtonBeingDragged()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()
	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70
	DPSMateX.Options:MinimapButtonSetPosition(math.deg(math.atan2(ypos,xpos)));
end

function DPSMateX.Options:MinimapButton_Init()
	if DPSMateX.Settings["showminimapbutton"] then
		DPSMateXMinimapButtonFrame:Show();
	else
		DPSMateXMinimapButtonFrame:Hide();
	end
end

function DPSMateX.Options:MinimapButtonUpdatePosition()
	DPSMateX.Options.MinimapButtonRadius = 78
	DPSMateX.Options.MinimapButtonPosition = DPSMateX.Options.MinimapButtonPosition or DPSMateX.Settings["MinimapButtonPosition"] or 336
	DPSMateXMinimapButtonFrame:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		54 - (DPSMateX.Options.MinimapButtonRadius * cos(DPSMateX.Options.MinimapButtonPosition)),
		(DPSMateX.Options.MinimapButtonRadius * sin(DPSMateX.Options.MinimapButtonPosition)) - 55
	);
end
