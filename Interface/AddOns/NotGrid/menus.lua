-- menus.lua
local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

--------------------
-- 单位下拉菜单
--------------------

local hasUnitXP = UnitXP ~= nil

-- 创建配置菜单界面
function NotGrid:DoDropDown()
    self:InitializeMenu()
    self:InitializeSlider()
    self:InitializeEditBox()
    self:InitializePositionBox()
end

-- 菜单数组定义（顺序即显示顺序，分组标题仅作视觉区分）
local menuarray = {
    -- ========== 基础设置 ==========
    {text = L["Config Mode"],      toggle = "configmode"},

    {text = "",},   -- 空行

    {text = L["Position"],         position = { xkey = "containeroffx", ykey = "containeroffy" } },
    {text = L["Draggable"],         toggle = "draggable",
     conflict = { smartcenter = true, containeroffx = true },
     tooltip = L["draggable_tooltip"] },

    {text = "",},

    -- ========== 框架尺寸与外观 ==========
    {text = L["Unit Width"],        slider = { key = "unitwidth", minval = 1, maxval = 100 } },
    {text = L["Unit Height"],       slider = { key = "unitheight", minval = 1, maxval = 100 } },
    {text = L["Unit Border"],       slider = { key = "unitborder", minval = 1, maxval = 20 },
     color = { key = "unitbordercolor" } },
    {text = L["Border Artwork"],     toggle = "borderartwork" },
    {text = L["Space between left and right"], slider = { key = "space_left_and_right", minval = -2, maxval = 20 } },
    {text = L["Space between top and bottom"], slider = { key = "space_top_and_bottom", minval = -2, maxval = 20 } },
    {text = L["Font"],              editbox = { key = "unitfont" } },
    {text = L["Texture"],           slider = { key = "unithealthbartexture", minval = 1, maxval = 6 } },
    {text = L["Background"],        color = { key = "unitbgcolor" } },

    -- ========== 姓名文本 ==========
    {text = L["Name Size"],         slider = { key = "unitnamehealthtextsize", minval = 1, maxval = 20 } },
    {text = L["Name Length"],       slider = { key = "namelength", minval = 1, maxval = 18 } },
    {text = L["Name Position"],     position = { xkey = "unitnamehealthoffx", ykey = "unitnamehealthoffy" } },
    {text = L["Name Color"],        toggle = "colorunitnamehealthbyclass",
     color = { key = "unitnamehealthtextcolor" },
     tooltip = L["classcolor_tooltip"] },

    -- ========== 生命条 ==========
    {text = L["Health Color"],      toggle = "colorunithealthbarbyclass",
     color = { key = "unithealthbarcolor" },
     tooltip = L["classcolor_tooltip"] },
    {text = L["Health Background"], editbox = { key = "unithealthbarbgtexture" },
     toggle = "colorunithealthbarbgbyclass",
     color = { key = "unithealthbarbgcolor" },
     tooltip = L["classcolor_tooltip"] },
    {text = L["Health Orientation"],slider = { key = "unithealthorientation", minval = 1, maxval = 2 } },
    {text = L["Health Threshold"],  slider = { key = "healththreshhold", minval = 1, maxval = 100 },
     tooltip = L["healththreshold_tooltip"] },

    {text = "",},

    -- ========== 能量/法力条 ==========
    {text = L["Show Power Bar"],    toggle = "showpowerbar" },
    {text = L["Power Background"],  toggle = "colorpowerbarbgbytype",
     tooltip = L["powercolor_tooltip"],
     color = { key = "unitpowerbarbgcolor" } },
    {text = L["Power Position"],    slider = { key = "powerposition", minval = 1, maxval = 4 } },
    {text = L["Power Size"],        slider = { key = "powersize", minval = 1, maxval = 50 } },

    {text = "",},

    -- ========== 图标监控 ==========
    {text = "|cffffff00" .. L["Icon Monitor Header"] .. "|r"},
    {text = L["Show Only Dispelleable Debuffs"], toggle = "showOnlyDispellableDebuffs",
     tooltip = L["Show Only Dispelleable Debuffs Tooltip"] },
    {text = L["Show tracking as color blocks"], toggle = "showTrackingAsColors",
     tooltip = L["Show tracking as color blocks tooltip"] },
    {text = L["Icon Size"],         slider = { key = "unittrackingiconsize", minval = 1, maxval = 30 } },
    {text = L["Top Left Icon"],     toggle = "trackingicon1invert",
     editbox = { key = "trackingicon1" },
     color = { key = "trackingicon1color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Top Icon"],          toggle = "trackingicon2invert",
     editbox = { key = "trackingicon2" },
     color = { key = "trackingicon2color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Top Right Icon"],    toggle = "trackingicon3invert",
     editbox = { key = "trackingicon3" },
     color = { key = "trackingicon3color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Right Icon"],        toggle = "trackingicon4invert",
     editbox = { key = "trackingicon4" },
     color = { key = "trackingicon4color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Bottom Right Icon"], toggle = "trackingicon5invert",
     editbox = { key = "trackingicon5" },
     color = { key = "trackingicon5color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Bottom Icon"],       toggle = "trackingicon6invert",
     editbox = { key = "trackingicon6" },
     color = { key = "trackingicon6color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Bottom Left Icon"],  toggle = "trackingicon7invert",
     editbox = { key = "trackingicon7" },
     color = { key = "trackingicon7color" },
     tooltip = L["icon_tooltip"] },
    {text = L["Left Icon"],         toggle = "trackingicon8invert",
     editbox = { key = "trackingicon8" },
     color = { key = "trackingicon8color" },
     tooltip = L["icon_tooltip"] },

    {text = "",},

    -- ========== 治疗预估 ==========
    {text = L["Healcomm Bar"],      toggle = "showhealcommbar",
     color = { key = "unithealcommbarcolor" } },
    {text = L["Healcomm Text"],     toggle = "showhealcommtext",
     slider = { key = "unithealcommtextsize", minval = 1, maxval = 20 },
     color = { key = "unithealcommtextcolor" } },
    {text = L["Healcomm Text Position"], position = { xkey = "unithealcommtextoffx", ykey = "unithealcommtextoffy" } },

    {text = "",},

    -- ========== 高亮与警告 ==========
    {text = L["Highlight Target"],  toggle = "tracktarget",
     color = { key = "targetcolor" } },
    {text = L["Aggro Warning"],     toggle = "trackaggro",
     color = { key = "aggrowarningcolor" } },
    {text = L["Mana Warning"],      toggle = "trackmana",
     slider = { key = "manathreshhold", minval = 1, maxval = 100 },
     tooltip = L["manathreshhold_tooltip"],
     color = { key = "manawarningcolor" } },

    {text = "",},

    -- ========== 距离与刷新 ==========
    {text = L["Use Map Proximity"], toggle = "usemapdistances" },
    {text = L["Proximity Rate"],    slider = { key = "proximityrate", minval = 0.5, maxval = 5, stepvalue = 0.5 },
     tooltip = L["proximityrate_tooltip"] },
    {text = L["Proximity Leeway"],  slider = { key = "proximityleeway", minval = 0, maxval = 30 },
     tooltip = L["proximityleeway_tooltip"] },

    {text = "",},

    -- ========== 布局 ==========
    {text = L["Smart Center"],      toggle = "smartcenter",
     tooltip = L["smartcenter_tooltip"] },
    {text = L["Growth Direction"],  slider = { key = "growthdirection", minval = 1, maxval = 9 } },

    {text = "",},
    -- ========== 团队框架显示设置 ==========
    {text = "|cffffff00" .. L["Raid Frame Header"] .. "|r"},
    {text = L["Show the party's index"], toggle = "ShowPartyIndex" },
    {text = L["Show While Solo"],        toggle = "showwhilesolo" },
    {text = L["Show In Party"],          toggle = "showinparty" },
    {text = L["Show Party In Raid"],     toggle = "showpartyinraid" },
    {text = L["Show Pets"],              toggle = "showpets",
     tooltip = L["pet_tooltip"] },
    {text = L["Show Dungeon Role"],      toggle = "showdungeonrole",
     tooltip = L["Show Dungeon Role Tooltip"] },
    {text = L["Dungeon Role Size"],      slider = { key = "dungeonrolesize", minval = 8, maxval = 30 } },
    {text = L["Dungeon Role Position"],  position = { xkey = "dungeonroleoffx", ykey = "dungeonroleoffy" } },
    {text = L["Set Member Role"],        button = "OpenRoleSettings",
     tooltip = L["Set Member Role Tooltip"] },
    {text = L["Custom Pet Color"],       toggle = "usepetcolor",
     color = { key = "petcolor" } },
    {text = L["TBC Shaman Color"],       toggle = "useshamancolor" },
    {text = L["Require line of sight"],  toggle = "requireSight",
     tooltip = L["Require line of sight tooltip"],
     requiresUnitXP = true },

    {text = "",},
    -- ========== 暴雪框架设置 ==========
    {text = "|cffffff00" .. L["Blizzard Frames Header"] .. "|r"},
    {text = L["Show Blizz Frames In Party"], toggle = "showblizzframesInParty" },
    {text = L["Show Blizz Frames In Raid"],  toggle = "showblizzframesInRaid" },
    {text = L["Disable Tooltip In Combat"],  toggle = "disablemouseoverincombat" },

    {text = "",},

    -- ========== 其他 ==========
    {text = L["Version Checking"], toggle = "versionchecking" },
    {text = L["Clique Hook"],      toggle = "cliquehook",
     reloadui = true,
     tooltip = L["cliquehook_tooltip"] },
}

-- 菜单常量
local buttonheight = 16
local numdisplay = 30

--------------
-- 创建下拉菜单面板
--------------

function NotGrid:InitializeMenu()
    local f = CreateFrame("Button","NotGridOptionsMenu",UIParent)
    f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:SetBackdropColor(0,0,0)
    f:SetWidth(190)
    f:SetHeight(buttonheight*(numdisplay+3)) -- +3 是为了从顶部留出间距
    f:SetPoint("CENTER",UIParent)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:EnableMouseWheel()
    f.offset = 0 -- 滚动偏移
    f.fs = f:CreateFontString('$parentTitle', "ARTWORK", "GameFontNormalLarge")
    f.fs:SetText("NotGrid".." v"..NotGridOptions.version)
    f.fs:SetPoint("TOPLEFT",12,-12)
    if NotGridOptions["showmenuhint"] then
        f.fs:SetText(L["Scroll Me!"])
    end
    f:SetScript("OnMouseWheel", function()
        if f.offset >= 5 and NotGridOptions["showmenuhint"] then
            f.fs:SetText("NotGrid")
            NotGridOptions["showmenuhint"] = false -- 提示过一次就不再显示
        end
        self:ScrollHandler()
    end)
    f:SetScript("OnShow", function()
        self:ScrollHandler() -- 显示时刷新滚动位置
    end)
    f:SetScript("OnDragStart", function()
        NotGridOptionsMenu:StartMoving()
    end)
    f:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    f:Hide()
    local fx = CreateFrame("Button","$parentXbutton",f,"UIPanelCloseButton")
    fx:SetPoint("TOPRIGHT",0,0)

    -- 重置按钮
    local reset = CreateFrame("Button","$parentresetbutton",f,"OptionsButtonTemplate")
    reset:SetPoint("TOPRIGHT",fx,"BOTTOMRIGHT",-5,0)
    SetSize(reset,50,20)
    reset:SetText(L["Reset"])
    reset:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["Reset to defaults (will reload UI)"])
    end)
    reset:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
    reset:SetScript("OnClick",function()
        NotGrid:ResetDefaultOptions()
    end)
    
    -- 根据menuarray创建所有按钮
    for key,val in menuarray do
        local fb = CreateFrame("Button", "$parentbutton"..key, f)
        fb:SetWidth(140)
        fb:SetHeight(buttonheight)
        fb:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight","ADD")
        --
        fb.fs = fb:CreateFontString('$parenttext', "ARTWORK", "GameFontHighlightSmall")
        fb.fs:SetText(val.text)
        fb.fs:SetPoint("LEFT",0,0)
        --
        fb.toggle = val.toggle
        fb.button = val.button
        fb.slider = val.slider
        fb.editbox = val.editbox
        fb.tooltip = val.tooltip
        fb.reloadui = val.reloadui
        fb.position = val.position
        fb.conflict = val.conflict
        --
        -- 如果是开关，添加勾选框
        if val.toggle then
            fb.chk = CreateFrame("Frame","$parentCheckmark",fb)
            fb.chk:SetWidth(20)
            fb.chk:SetHeight(20)
            fb.chk.tex = fb.chk:CreateTexture()
            if NotGridOptions[fb.toggle] then
                fb.chk.tex:SetTexture("Interface/Buttons/UI-CheckBox-Check")
            else
                fb.chk.tex:SetTexture("Interface/Buttons/UI-CheckBox-Check-Disabled")
            end
            fb.chk.tex:SetAllPoints()
            fb.chk:SetPoint("RIGHT",fb,"LEFT",0,0)
        end
        -- 如果有颜色设置，添加颜色预览块
        if val.color then
            fb.clr = CreateFrame("Button","$parentButton",fb)
            fb.clr.color = val.color
            fb.clr:SetWidth(14)
            fb.clr:SetHeight(14)
            fb.clr:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
            fb.clr:SetBackdropBorderColor(1,1,1,0.8)
            fb.clr.tex = fb.clr:CreateTexture("$parentTexture")
            fb.clr.tex:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
            fb.clr.tex:SetVertexColor(unpack(NotGridOptions[val.color.key]))
            fb.clr.tex:SetAllPoints()
            fb.clr:SetPoint("LEFT",fb,"RIGHT",0,0)
            fb.clr:SetScript("OnClick", function()
                self:ClickColor()
            end)
        end

        fb:SetScript("OnClick", function()
            -- 处理按钮型菜单项（如打开角色设置窗口）
            if this.button then
                if this.button == "OpenRoleSettings" then
                    NotGrid:OpenRoleSettingsWindow()
                end
                return
            end
            if this.toggle then
                if NotGridOptions[this.toggle] == true then
                    NotGridOptions[this.toggle] = false
                    fb.chk.tex:SetTexture("Interface/Buttons/UI-CheckBox-Check-Disabled")
                    if this.toggle == "borderartwork" then
                        NotGrid.o.unitbordercolor = {0,0,0,0.8}
                        NotGrid.o.space_left_and_right = 2
                        NotGrid.o.space_top_and_bottom = 2
                        NotGrid.o.unitborder = 2
                    end
                else
                    NotGridOptions[this.toggle] = true
                    fb.chk.tex:SetTexture("Interface/Buttons/UI-CheckBox-Check")
                    if this.toggle == "borderartwork" then
                        NotGrid.o.unitbordercolor = {0.8,0.8,0.8,1}
                        NotGrid.o.space_left_and_right = -10
                        NotGrid.o.space_top_and_bottom = -10
                        NotGrid.o.unitborder = 10
                    end
                end
                NotGridOptionChange()
                NotGridMenuConflictHandler()
            end
            if this.reloadui then
                ReloadUI()
            end
        end)
        fb:SetScript("OnEnter", function()
            if this.slider and this.editbox then
                -- 两者都有时同时显示（实际上不会出现）
            elseif this.editbox then
                NotGridMenuEditBox.key = this.editbox.key
                if type(NotGridOptions[this.editbox.key]) == "table" then -- 追踪图标列表
                    NotGridMenuEditBox:SetText(table.concat(NotGridOptions[this.editbox.key],"/"))
                    NotGridMenuEditBox.istable = true
                else
                    NotGridMenuEditBox:SetText(NotGridOptions[this.editbox.key])
                    NotGridMenuEditBox.istable = false
                end
                NotGridMenuEditBoxContainer:ClearAllPoints()
                NotGridMenuEditBoxContainer:SetPoint("TOPRIGHT",this,"TOPLEFT",-20,0)
                NotGridMenuEditBoxContainer:Show()
                NotGridMenuSliderContainer:Hide()
                NotGridMenuPositionBoxContainer:Hide()
            elseif this.slider then
                NotGridMenuSlider.key = this.slider.key
                NotGridMenuSlider:SetMinMaxValues(this.slider.minval, this.slider.maxval)
                NotGridMenuSlider:SetValue(NotGridOptions[this.slider.key])
                NotGridMenuSlider.currval:SetText(NotGridOptions[this.slider.key])
                if this.slider.stepvalue then
                    NotGridMenuSlider:SetValueStep(this.slider.stepvalue)
                else
                    NotGridMenuSlider:SetValueStep(1)
                end
                if this.slider.tooltip then
                    NotGridMenuSlider.tooltip = this.slider.tooltip
                end
                NotGridMenuSliderContainer:ClearAllPoints()
                NotGridMenuSliderContainer:SetPoint("TOPRIGHT",this,"TOPLEFT",-20,0)
                NotGridMenuSliderContainer:Show()
                NotGridMenuEditBoxContainer:Hide()
                NotGridMenuPositionBoxContainer:Hide()
            elseif this.position then
                NotGridMenuPositionBoxLeftButton.key = this.position.xkey
                NotGridMenuPositionBoxRightButton.key = this.position.xkey
                NotGridMenuPositionBoxUpButton.key = this.position.ykey
                NotGridMenuPositionBoxDownButton.key = this.position.ykey
                NotGridMenuPositionBoxXeditbox.key = this.position.xkey
                NotGridMenuPositionBoxYeditbox.key = this.position.ykey
                NotGridMenuPositionBoxXeditbox:SetText(NotGridOptions[this.position.xkey])
                NotGridMenuPositionBoxYeditbox:SetText(NotGridOptions[this.position.ykey])
                NotGridMenuPositionBoxContainer:ClearAllPoints()
                NotGridMenuPositionBoxContainer:SetPoint("TOPRIGHT",this,"TOPLEFT",-20,0)
                NotGridMenuPositionBoxContainer:Show()
                NotGridMenuSliderContainer:Hide()
                NotGridMenuEditBoxContainer:Hide()
            else
                NotGridMenuSliderContainer:Hide()
                NotGridMenuEditBoxContainer:Hide()
                NotGridMenuPositionBoxContainer:Hide()
            end
            if this.tooltip then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(this.tooltip, nil, nil, nil, nil, 1)
            end
        end)
        fb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        -- 空行或不可用项禁用
        if val.text == "" then
            fb:Disable()
        end
        if val.requiresUnitXP and not hasUnitXP then
            fb:Hide()
            fb:Disable()
        end
    end
    NotGridMenuConflictHandler()
end

------------
-- 滑块控件
------------

function NotGrid:InitializeSlider()
    local f = CreateFrame("Frame","NotGridMenuSliderContainer",NotGridOptionsMenu) -- 滑块容器
    f:SetWidth(160)
    f:SetHeight(50)
    f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:SetBackdropColor(0,0,0,1)
    f:SetPoint("CENTER",UIParent,"CENTER",-100,0)
    f:Hide()

    f.s = CreateFrame('Slider', 'NotGridMenuSlider', f, 'OptionsSliderTemplate') -- 滑块
    f.s:SetPoint("CENTER",0,0)
    f.s:SetValueStep(1)

    f.s:SetScript("OnValueChanged", function()
        if GetMouseFocus() == this then -- 仅当用户操作时更新
            NotGridOptions[this.key] = arg1
            this.currval:SetText(arg1)
            NotGridOptionChange()
        end
        if this.key == "proximityrate" then
            NotGrid:CancelAllScheduledEvents()
            NotGrid:ScheduleRepeatingEvent("NG_UNIT_PROXIMITY", NotGrid.o.proximityrate)
        end
    end)

    f.s.currval = f.s:CreateFontString('$parentcurrval', "ARTWORK", "GameFontHighlightSmall")
    f.s.currval:SetPoint("TOP",0,8)
    f.s.currval:SetText("50")
    f.s:SetScript("OnEnter", function()
        if this.tooltip then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.tooltip, nil, nil, nil, nil, 1)
        end
    end)
    f.s:SetScript("OnHide", function()
        if this.tooltip then
            this.tooltip = nil
        end
    end)
end

-------------
-- 编辑框控件
-------------

function NotGrid:InitializeEditBox()
    local f = CreateFrame("Frame", "NotGridMenuEditBoxContainer",NotGridOptionsMenu)
    f:SetWidth(350)
    f:SetHeight(50)
    f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:SetBackdropColor(0,0,0,1)
    f:SetPoint("CENTER",UIParent,"CENTER",-100,0)
    f:Hide()

    f.e = CreateFrame("EditBox", "NotGridMenuEditBox", f, "InputBoxTemplate")
    f.e:SetFontObject("GameFontHighlight")
    f.e:SetWidth(320)
    f.e:SetHeight(40)
    f.e:SetAutoFocus(false)
    f.e:SetPoint("CENTER",0,0)
    f.e:SetText("")
    f.e:EnableKeyboard()
    f.e:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        if this.istable then
            NotGridOptions[this.key] = {} -- 清空旧表，重新构建
            for text in string.gfind(this:GetText(), "([^/]+)") do -- 用 / 分隔
                table.insert(NotGridOptions[this.key], text)
            end
        else
            NotGridOptions[this.key] = this:GetText()
        end
        NotGridOptionChange()
    end)
    f.e:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        if this.istable then
            this:SetText(table.concat(NotGridOptions[this.key],"/"))
        else
            this:SetText(NotGridOptions[this.key])
        end
    end)
end

----------------------
-- 位置调整控件
----------------------

function NotGrid:InitializePositionBox()
    local f = CreateFrame("Frame", "NotGridMenuPositionBoxContainer",NotGridOptionsMenu)
    f:SetWidth(200)
    f:SetHeight(100)
    f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:SetBackdropColor(0,0,0,1)
    f:SetPoint("CENTER",UIParent,"CENTER",-100,0)
    f:Hide()

    f.upb = CreateFrame("Button", "NotGridMenuPositionBoxUpButton", f, "UIPanelButtonTemplate")
    f.upb:SetPoint("CENTER",0,30)
    f.upb:SetText("^")

    f.downb = CreateFrame("Button", "NotGridMenuPositionBoxDownButton", f, "UIPanelButtonTemplate")
    f.downb:SetPoint("CENTER",0,-30)
    f.downb:SetText("v")

    f.leftb = CreateFrame("Button", "NotGridMenuPositionBoxLeftButton", f, "UIPanelButtonTemplate")
    f.leftb:SetPoint("CENTER",-80,0)
    f.leftb:SetText("<")

    f.rightb = CreateFrame("Button", "NotGridMenuPositionBoxRightButton", f, "UIPanelButtonTemplate")
    f.rightb:SetPoint("CENTER",80,0)
    f.rightb:SetText(">")

    for k,v in {up = f.upb, down = f.downb, left = f.leftb, right = f.rightb} do
        v.direction = k
        v:SetWidth(20)
        v:SetHeight(20)
        v:SetScript("OnClick", function(self, button, down)
            if this.direction == "up" or this.direction == "right" then
                NotGridOptions[this.key] = NotGridOptions[this.key]+NotGrid:GetAdjustment()
            else
                NotGridOptions[this.key] = NotGridOptions[this.key]-NotGrid:GetAdjustment()
            end
            if this.direction == "up" or this.direction == "down" then
                NotGridMenuPositionBoxYeditbox:SetText(NotGridOptions[this.key])
            else
                NotGridMenuPositionBoxXeditbox:SetText(NotGridOptions[this.key])
            end
            NotGridOptionChange()
        end)
        v:SetScript("OnEnter", function()
            if this.direction == "down" then
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
            else
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            end
            if this.direction == "right" or this.direction == "left" then
                GameTooltip:SetText(L["Position Tooltip Horizontal"], nil, nil, nil, nil, 1)
            else
                GameTooltip:SetText(L["Position Tooltip Vertical"], nil, nil, nil, nil, 1)
            end
        end)
        v:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    f.ex = CreateFrame("EditBox", "NotGridMenuPositionBoxXeditbox", f, "InputBoxTemplate")
    f.ex:SetFontObject("GameFontHighlight")
    f.ex:SetWidth(50)
    f.ex:SetHeight(40)
    f.ex:SetAutoFocus(false)
    f.ex:SetPoint("CENTER",-30,0)
    f.ex:SetText("xx")
    f.ex:EnableKeyboard()
    f.ex:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        NotGridOptions[this.key] = tonumber(this:GetText())
        NotGridOptions[NotGridMenuPositionBoxYeditbox.key] = tonumber(NotGridMenuPositionBoxYeditbox:GetText())
        NotGridOptionChange()
    end)
    f.ex:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(NotGridOptions[this.key])
    end)

    f.ey = CreateFrame("EditBox", "NotGridMenuPositionBoxYeditbox", f, "InputBoxTemplate")
    f.ey:SetFontObject("GameFontHighlight")
    f.ey:SetWidth(50)
    f.ey:SetHeight(40)
    f.ey:SetAutoFocus(false)
    f.ey:SetPoint("CENTER",30,0)
    f.ey:SetText("yy")
    f.ey:EnableKeyboard()
    f.ey:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        NotGridOptions[this.key] = tonumber(this:GetText())
        NotGridOptions[NotGridMenuPositionBoxXeditbox.key] = tonumber(NotGridMenuPositionBoxXeditbox:GetText())
        NotGridOptionChange()
    end)
    f.ey:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(NotGridOptions[this.key])
    end)
end

function NotGrid:GetAdjustment(direction)
    local adjustment
    if IsShiftKeyDown() and IsControlKeyDown() then
        adjustment = 100
    elseif IsShiftKeyDown() then
        adjustment = 10
    else
        adjustment = 1
    end
    return adjustment
end

-----------------
-- 颜色选择功能
-----------------

local workingcolorswatch -- 临时存储颜色预览帧
local workingcolorkey   -- 临时存储颜色键
function NotGrid:ClickColor()
    workingcolorswatch = this.tex
    workingcolorkey = this.color.key
    local r, g, b, a = unpack(NotGridOptions[workingcolorkey])
    ColorPickerFrame.previousValues = {r, g, b, a}
    ColorPickerFrame.func = self.ColorPickerHandler
    ColorPickerFrame.opacityFunc = self.ColorPickerHandler
    ColorPickerFrame.cancelFunc = NotGrid_SetColor -- 取消时使用此函数恢复
    if a then
        ColorPickerFrame.opacity = 1-a
        ColorPickerFrame.hasOpacity = true
    else
        ColorPickerFrame.hasOpacity = false
    end
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
end

function NotGrid:ColorPickerHandler()
    local a = 1 - OpacitySliderFrame:GetValue()
    local r,g,b = ColorPickerFrame:GetColorRGB()
    if ColorPickerFrame.hasOpacity then
        NotGrid_SetColor({r,g,b,a})
    else
        NotGrid_SetColor({r,g,b})
    end
end

function NotGrid_SetColor(vals) -- 设置颜色并更新
    workingcolorswatch:SetVertexColor(unpack(vals))
    NotGridOptions[workingcolorkey] = vals
    NotGridOptionChange()
end

--------------------
-- 滚动处理
--------------------

function NotGrid:ScrollHandler() -- arg1 为滚动方向，-1 向上，1 向下
    if type(arg1) == "string" or not arg1 then arg1 = 0 end
    local menucount = getn(menuarray)
    local offset = NotGridOptionsMenu.offset
    offset = offset - arg1
    if offset < 0 then offset = 0 end
    if offset > menucount-numdisplay then offset = menucount-numdisplay end
    for key,_ in menuarray do
        local f = _G["NotGridOptionsMenubutton"..key]
        if (key > offset) and (key <= offset+numdisplay) then
            f:SetPoint("TOP","NotGridOptionsMenu","TOP",0,-buttonheight*(key+1-offset))
            f:Show()
        else
            f:Hide()
            if f.slider then NotGridMenuSliderContainer:Hide() end
            if f.editbox then NotGridMenuEditBoxContainer:Hide() end
        end
    end
    NotGridOptionsMenu.offset = offset
end

----------------------
-- 配置冲突处理
----------------------

function NotGridMenuConflictHandler()
    for key,val in menuarray do
        if val.conflict then
            for ckey,cval in menuarray do
                if (cval.toggle and val.conflict[cval.toggle]) or (cval.position and val.conflict[cval.position.xkey]) then
                    local b = _G["NotGridOptionsMenubutton"..ckey]
                    if NotGridOptions[val.toggle] then -- 如果冲突开关打开，禁用相关选项
                        b:Disable()
                        b:SetDisabledTexture("Interface/Buttons/UI-Listbox-Highlight2","ADD")
                        b:SetAlpha(0.5)
                        if cval.toggle then
                            NotGridOptions[cval.toggle] = false
                            b.chk.tex:SetTexture("Interface/Buttons/UI-CheckBox-Check-Disabled")
                        end
                    else
                        b:Enable()
                        b:SetDisabledTexture("","ADD")
                        b:SetAlpha(1)
                    end
                end
            end
        end
    end
end

-------------------------
-- 通用配置更新
-------------------------

function NotGridOptionChange()
    NotGrid:ConfigUnitFrames()
    for unitid,_ in NotGrid.UnitFrames do
        NotGrid:UNIT_MAIN(unitid)
        NotGrid:UNIT_BORDER(unitid)
        NotGrid:UNIT_AURA(unitid)
    end
    NotGrid:ClearIndexFramePoint()
    NotGrid:PositionFrames()
    NotGrid:BlizzFrameHandler()
end


-------------------------
-- 角色设置窗口
-------------------------

function NotGrid:OpenRoleSettingsWindow()
    if not NotGridRoleSettingsFrame then
        self:CreateRoleSettingsWindow()
    end
    NotGridRoleSettingsFrame:Show()
    self:UpdateRoleSettingsList()
end

function NotGrid:CreateRoleSettingsWindow()
    local f = CreateFrame("Frame", "NotGridRoleSettingsFrame", UIParent)
    f:SetWidth(300)
    f:SetHeight(400)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:SetBackdropColor(0,0,0,0.9)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- 标题
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -10)
    f.title:SetText(L["Set Member Role"])
    
    -- 关闭按钮
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    
    -- 滚动区域
    f.scroll = CreateFrame("ScrollFrame", "NotGridRoleSettingsScroll", f, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
    f.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)
    
    f.scrollchild = CreateFrame("Frame", nil, f.scroll)
    f.scrollchild:SetWidth(250)
    f.scrollchild:SetHeight(1)
    f.scroll:SetScrollChild(f.scrollchild)
    
    f:Hide()
end

function NotGrid:UpdateRoleSettingsList()
    local f = NotGridRoleSettingsFrame
    if not f then return end
    
    -- 清除旧按钮
    if f.buttons then
        for _, btn in ipairs(f.buttons) do
            btn:Hide()
        end
    end
    f.buttons = {}
    
    local yoffset = 0
    local buttonHeight = 30
    local addedNames = {}  -- 用于去重
    
    -- 遍历所有团队成员
    for unitid, frame in pairs(self.UnitFrames) do
        if UnitExists(unitid) then
            local name = UnitName(unitid)
            local _, class = UnitClass(unitid)
            
            -- 去重：避免同一玩家重复出现
            if name and class and not addedNames[name] then
                addedNames[name] = true
                
                -- 创建成员按钮行
                local btn = CreateFrame("Frame", nil, f.scrollchild)
                btn:SetWidth(250)
                btn:SetHeight(buttonHeight)
                btn:SetPoint("TOPLEFT", f.scrollchild, "TOPLEFT", 0, -yoffset)
                
                -- 名字
                btn.name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.name:SetPoint("LEFT", btn, "LEFT", 5, 0)
                btn.name:SetText(name)
                btn.name:SetTextColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
                
                -- 坦克按钮
                btn.tank = CreateFrame("Button", nil, btn)
                btn.tank:SetWidth(25)
                btn.tank:SetHeight(25)
                btn.tank:SetPoint("RIGHT", btn, "RIGHT", -75, 0)
                btn.tank:SetNormalTexture("Interface\\AddOns\\NotGrid\\media\\ui-lfg-icon-portraitroles")
                btn.tank:GetNormalTexture():SetTexCoord(0, 19/64, 22/64, 41/64)
                btn.tank:SetScript("OnClick", function()
                    NotGrid.ManualRoles[name] = "TANK"
                    NotGrid.o.manualroles[name] = "TANK"
                    NotGrid:SyncRoleToRaid(name, "TANK")
                    NotGrid:UpdateDungeonRoleIcons()
                    NotGrid:UpdateRoleSettingsList()
                end)
                
                -- 治疗按钮
                btn.healer = CreateFrame("Button", nil, btn)
                btn.healer:SetWidth(25)
                btn.healer:SetHeight(25)
                btn.healer:SetPoint("RIGHT", btn, "RIGHT", -45, 0)
                btn.healer:SetNormalTexture("Interface\\AddOns\\NotGrid\\media\\ui-lfg-icon-portraitroles")
                btn.healer:GetNormalTexture():SetTexCoord(20/64, 39/64, 1/64, 20/64)
                btn.healer:SetScript("OnClick", function()
                    NotGrid.ManualRoles[name] = "HEALER"
                    NotGrid.o.manualroles[name] = "HEALER"
                    NotGrid:SyncRoleToRaid(name, "HEALER")
                    NotGrid:UpdateDungeonRoleIcons()
                    NotGrid:UpdateRoleSettingsList()
                end)
                
                -- DPS按钮
                btn.dps = CreateFrame("Button", nil, btn)
                btn.dps:SetWidth(25)
                btn.dps:SetHeight(25)
                btn.dps:SetPoint("RIGHT", btn, "RIGHT", -15, 0)
                btn.dps:SetNormalTexture("Interface\\AddOns\\NotGrid\\media\\ui-lfg-icon-portraitroles")
                btn.dps:GetNormalTexture():SetTexCoord(20/64, 39/64, 22/64, 41/64)
                btn.dps:SetScript("OnClick", function()
                    NotGrid.ManualRoles[name] = "DAMAGER"
                    NotGrid.o.manualroles[name] = "DAMAGER"
                    NotGrid:SyncRoleToRaid(name, "DAMAGER")
                    NotGrid:UpdateDungeonRoleIcons()
                    NotGrid:UpdateRoleSettingsList()
                end)
                
                -- 高亮当前选择
                local currentRole = NotGrid.ManualRoles[name] or NotGrid:GetUnitRole(unitid)
                if currentRole == "TANK" then
                    btn.tank:SetAlpha(1)
                    btn.healer:SetAlpha(0.3)
                    btn.dps:SetAlpha(0.3)
                elseif currentRole == "HEALER" then
                    btn.tank:SetAlpha(0.3)
                    btn.healer:SetAlpha(1)
                    btn.dps:SetAlpha(0.3)
                else
                    btn.tank:SetAlpha(0.3)
                    btn.healer:SetAlpha(0.3)
                    btn.dps:SetAlpha(1)
                end
                
                table.insert(f.buttons, btn)
                yoffset = yoffset + buttonHeight
            end
        end
    end
    
    f.scrollchild:SetHeight(yoffset)
end