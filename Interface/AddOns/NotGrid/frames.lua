-----------------------
-- 创建框架
-----------------------
local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

function NotGrid:CreateFrames()
    self.Container = self:CreateContainerFrame()
    for i = 1, 40 do
        self.UnitFrames["raid" .. i] = self:CreateUnitFrame("raid" .. i, i)
    end
    for i = 1, 40 do
        self.UnitFrames["raidpet" .. i] = self:CreateUnitFrame("raidpet" .. i)
    end
    for i = 1, 4 do
        self.UnitFrames["party" .. i] = self:CreateUnitFrame("party" .. i)
    end
    for i = 1, 4 do
        self.UnitFrames["partypet" .. i] = self:CreateUnitFrame("partypet" .. i)
    end
    self.UnitFrames["player"] = self:CreateUnitFrame("player")
    self.UnitFrames["pet"] = self:CreateUnitFrame("pet")
    for i = 1, 10 do
        self.PartyIndexFrames["partyindex" .. i] = self:CreatePartyIndexFrame("partyindex" .. i)
    end
end

function NotGrid:CreateContainerFrame()
    local f = CreateFrame("Frame", "NotGridContainer", UIParent)
    f:SetWidth(1)
    f:SetHeight(1)
    -- f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", tile = true, tileSize = 16, edgeSize = 10})
    f:SetMovable(true)
    f:SetPoint("CENTER", 40, -40)
    return f
end

function NotGrid:CreatePartyIndexFrame(partyindex)
    local f = CreateFrame("Frame", "$parent" .. partyindex, self.Container)
    f.TextString = f:CreateFontString("partyindex", "OVERLAY")
    local index = tonumber(string.match(partyindex, "%d+"))
    f.index = index
    return f
end

function NotGrid:ToggleFrameShowHide()
    local f = getglobal("NotGridContainer")
    if f:IsVisible() then
        f:Hide()
    else
        f:Show()
    end
end

function NotGrid:CreateUnitFrame(unitid, raidindex)
    local f = CreateFrame("Button", "$parent" .. unitid, self.Container)
    f.unit = unitid
    f.lastseen = GetTime()      -- 在创建时设置最后可见时间，避免默认显示为超出距离的透明度
    if raidindex then
        f.raidindex = raidindex -- 团队索引
    end
    if string.find(unitid, "pet") then
        f.pet = true -- 标记为宠物框架
    end

    f.border = CreateFrame("Frame", "$parentborder", f) -- 单独创建边框框架以便更好地自定义外观
    f.border.middleart = f.border:CreateTexture("NGArtworkMiddle", "ARTWORK")

    f.healthbar = CreateFrame("StatusBar", "$parenthealthbar", f)
    f.healthbar.bgtex = f.healthbar:CreateTexture("$parentbgtex", "BACKGROUND")

    -- 团队标记图标
    f.healthbar.raidmarker = f.healthbar:CreateTexture("$parentraidmarker", "OVERLAY")

    f.powerbar = CreateFrame("StatusBar", "$parenthealthbar", f)
    f.powerbar.bgtex = f.powerbar:CreateTexture("$parentbgtex", "BACKGROUND")

    f.incres = CreateFrame("Frame", "$parentresicon", f.healthbar)
    f.incres.bgtex = f.incres:CreateTexture("$parentbgtex", "BACKGROUND")

    f.incheal = CreateFrame("Frame", "$parenthealcommbar", f.healthbar) -- 使用Frame而非StatusBar来避免低透明度时背景穿透

    -- 将文本创建在incheal上，但相对血条定位，这样就不会被incheal覆盖
    f.namehealthtext = f.incheal:CreateFontString("$parentnamehealthtext", "OVERLAY")
    f.healcommtext = f.incheal:CreateFontString("$parenthealcommtext", "OVERLAY")

    f.leader = CreateFrame("Frame", "$parentleader", f)
    f.leader.icon = f.leader:CreateTexture("leaderIcon", "OVERLAY")

    -- 职责图标（坦克/治疗/输出）
    f.dungeon_role = CreateFrame("Frame", "$parentdungeonrole", f)
    f.dungeon_role.icon = f.dungeon_role:CreateTexture("dungeonroleIcon", "OVERLAY")

    -- 创建8个追踪图标（Buff/Debuff监控）
    for i = 1, 8 do
        local iconName = f.healthbar:GetName() .. "trackingicon" .. i
        f.healthbar["trackingicon" .. i] = CreateFrame("Button", iconName, f.healthbar)
        local iconFrame = f.healthbar["trackingicon" .. i]

        -- 在按钮上创建纹理
        iconFrame.texture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconFrame.texture:SetAllPoints()
        iconFrame.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

        -- 鼠标悬停显示Buff/Debuff详情
        iconFrame:SetScript("OnEnter", function()
            if this.buffIndex and this.unit then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if this.isDebuff then
                    GameTooltip:SetUnitDebuff(this.unit, this.buffIndex)
                else
                    GameTooltip:SetUnitBuff(this.unit, this.buffIndex)
                end
                GameTooltip:Show()
            end
        end)

        iconFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        iconFrame:Hide()
    end

    -- 注册点击、拖动等脚本
    f:RegisterForClicks("LeftButtonDown", "RightButtonDown", "MiddleButtonDown", "Button4Down", "Button5Down")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnClick", function()
        if Clique then
            if not Clique:OnClick(arg1, this.unit) then
                self:ClickHandle(arg1) -- 如果Clique未处理，则调用默认点击处理
            end
        else
            self:ClickHandle(arg1)
        end
    end)
    f:SetScript("OnEnter", function()
        if UnitAffectingCombat("player") and self.o.disablemouseoverincombat then return end

        -- Nampower 环境下显式设置 mouseover，确保工具提示能正确获取单位
        if self.hasNampower then
            SetMouseoverUnit(this.unit)
        end

        UnitFrame_OnEnter()
    end)
    f:SetScript("OnLeave", function()
        UnitFrame_OnLeave()
    end)

    f:SetScript("OnDragStart", function()
        if self.o.draggable then
            self.Container:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function()
        if self.o.draggable then
            self.Container:StopMovingOrSizing()
            local _, _, _, x, y = self.Container:GetPoint()
            self.o.containeroffx = math.floor(x)
            self.o.containeroffy = math.floor(y)
        end
    end)

    -- 注册单位相关事件
    f:RegisterEvent("UNIT_NAME_UPDATE")
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    -- 生命值
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    -- 法力/怒气/能量等
    f:RegisterEvent("UNIT_MANA")
    f:RegisterEvent("UNIT_RAGE")
    f:RegisterEvent("UNIT_FOCUS")
    f:RegisterEvent("UNIT_ENERGY")
    f:RegisterEvent("UNIT_HAPPINESS")
    f:RegisterEvent("UNIT_MAXMANA")
    f:RegisterEvent("UNIT_MAXRAGE")
    f:RegisterEvent("UNIT_MAXFOCUS")
    f:RegisterEvent("UNIT_MAXENERGY")
    f:RegisterEvent("UNIT_MAXHAPPINESS")
    f:RegisterEvent("UNIT_DISPLAYPOWER")
    -- 光环
    f:RegisterEvent("UNIT_AURA")
    -- 玩家目标改变时刷新边框高亮
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    -- 团队标记更新
    f:RegisterEvent("RAID_TARGET_UPDATE")
    -- Banzai/HealComm等事件已在core的OnEnable中统一注册

    f:SetScript("OnEvent", function()
        if arg1 and arg1 == this.unit then -- 只有与当前框架单位相关的事件才处理
            if event == "UNIT_AURA" then
                self:UNIT_AURA(this.unit)
            else
                self:UNIT_MAIN(this.unit)
                self:UNIT_BORDER(this.unit)
            end
        elseif event == "PLAYER_TARGET_CHANGED" then -- 所有单位的边框都需要更新
            self:UNIT_BORDER(this.unit)
        elseif event == "RAID_TARGET_UPDATE" then -- 更新此单位的团队标记
            self:UpdateRaidMarkers()
        end
    end)

    return f
end

-----------------------
-- 配置框架外观
-----------------------

function NotGrid:ConfigPartyIndexFrames()
    local o = self.o
    for key, f in self.PartyIndexFrames do
        f.TextString:SetFont(o.unitfont, o.unitnamehealthtextsize, "OUTLINE")
        if f.index == 10 then
            f.TextString:SetText(L["Pet"])                       -- 宠物分组标签
        elseif f.index == 9 then
            f.TextString:SetText(L["Your Group"])                -- 自己所在的小队
        else
            f.TextString:SetText(string.format(L["Party"].." %d", f.index)) -- 小队编号
        end
        f:Hide()
    end
end

function NotGrid:ClearIndexFramePoint()
    for key, f in self.PartyIndexFrames do
        f:ClearAllPoints()
        f:Hide()
    end
end

function NotGrid:ConfigUnitFrames()
    local o = self.o
    for _, f in self.UnitFrames do
        local width, height
        -- 根据能量条位置计算框架总尺寸
        if o.showpowerbar and o.powerposition <= 2 then
            width = o.unitwidth
            height = o.unitheight + o.powersize + 1
        elseif o.showpowerbar and o.powerposition >= 3 then
            width = o.unitwidth + o.powersize + 1
            height = o.unitheight
        else
            width = o.unitwidth
            height = o.unitheight
        end
        f:SetWidth(width)
        f:SetHeight(height)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = true, tileSize = 16 })
        f:SetBackdropColor(unpack(o.unitbgcolor))

        -- 边框样式
        if o.borderartwork then
            f.border:SetWidth(width + o.unitborder)
            f.border:SetHeight(height + o.unitborder)
            f.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
        else
            f.border:SetWidth(width + o.unitborder * 2)
            f.border:SetHeight(height + o.unitborder * 2)
            f.border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = o.unitborder })
        end
        f.border:SetBackdropBorderColor(unpack(o.unitbordercolor))
        f.border:SetPoint("CENTER", 0, 0)
        f.border:SetFrameLevel(f:GetFrameLevel() + 2)
        f.border.middleart:SetTexture("Interface/TargetingFrame/UI-TargetingFrame")
        if o.powerposition <= 2 then
            f.border.middleart:SetTexCoord((58 / 256) + (1 / 256 / 2), (82 / 256) + (1 / 256 / 2),
                (39 / 128) + (1 / 128 / 2),
                (44 / 128) + (1 / 128 / 2))
            f.border.middleart:SetVertexColor(unpack(o.unitbordercolor))
        else
            f.border.middleart:SetTexCoord((26 / 256) + (1 / 256 / 2), (32 / 256) + (1 / 256 / 2),
                (27 / 128) + (1 / 128 / 2),
                (34 / 128) + (1 / 128 / 2))
            f.border.middleart:SetVertexColor(unpack(o.unitbordercolor))
        end

        -- 血条
        f.healthbar:SetWidth(o.unitwidth)
        f.healthbar:SetHeight(o.unitheight)
        if o.unithealthorientation == 1 then
            f.healthbar:SetOrientation("VERTICAL")
        else
            f.healthbar:SetOrientation("HORIZONTAL")
        end

        local dir = "Interface\\AddOns\\NotGrid\\media\\"
        f.healthbar:SetStatusBarTexture(dir .. o.unithealthbartexture)
        f.healthbar:SetStatusBarColor(unpack(o.unithealthbarcolor))
        f.healthbar.bgtex:SetTexture(dir .. o.unithealthbarbgtexture)
        f.healthbar.bgtex:SetVertexColor(unpack(o.unithealthbarbgcolor))
        f.healthbar.bgtex:SetAllPoints()

        -- 调整血条和能量条的定位
        f.healthbar:ClearAllPoints()
        f.powerbar:ClearAllPoints()
        f.border.middleart:ClearAllPoints()
        if o.showpowerbar then
            if o.powerposition <= 2 then -- 能量条在顶部或底部
                if o.powerposition == 1 then
                    f.healthbar:SetPoint("BOTTOM", 0, 0)
                    f.powerbar:SetPoint("TOP", 0, 0)
                    f.border.middleart:SetPoint("BOTTOM", f.powerbar, 0, -4)
                else
                    f.healthbar:SetPoint("TOP", 0, 0)
                    f.powerbar:SetPoint("BOTTOM", 0, 0)
                    f.border.middleart:SetPoint("TOP", f.powerbar, 0, 4)
                end
                f.powerbar:SetWidth(o.unitwidth)
                f.powerbar:SetHeight(o.powersize)
                f.powerbar:SetOrientation("HORIZONTAL")
                f.border.middleart:SetWidth(width)
                f.border.middleart:SetHeight(6)
            elseif o.powerposition >= 3 then -- 能量条在左侧或右侧
                if o.powerposition == 3 then
                    f.healthbar:SetPoint("LEFT", 0, 0)
                    f.powerbar:SetPoint("RIGHT", 0, 0)
                    f.border.middleart:SetPoint("LEFT", f.powerbar, -4, 0)
                else
                    f.healthbar:SetPoint("RIGHT", 0, 0)
                    f.powerbar:SetPoint("LEFT", 0, 0)
                    f.border.middleart:SetPoint("RIGHT", f.powerbar, 4, 0)
                end
                f.powerbar:SetWidth(o.powersize)
                f.powerbar:SetHeight(o.unitheight)
                f.powerbar:SetOrientation("VERTICAL")
                f.border.middleart:SetWidth(6)
                f.border.middleart:SetHeight(height)
            end
            f.powerbar:Show()
            if o.borderartwork then
                f.border.middleart:Show()
            else
                f.border.middleart:Hide()
            end
        else
            f.healthbar:SetPoint("CENTER", 0, 0)
            f.powerbar:Hide()
            f.border.middleart:Hide()
        end
        f.powerbar:SetStatusBarTexture(dir .. o.unithealthbartexture)
        f.powerbar.bgtex:SetTexture(dir .. o.unithealthbartexture)
        f.powerbar.bgtex:SetVertexColor(unpack(o.unitpowerbarbgcolor))
        f.powerbar.bgtex:SetAllPoints()

        -- 复活图标
        f.incres:SetWidth(o.unitheight)
        f.incres:SetHeight(o.unitheight)
        f.incres:ClearAllPoints()
        f.incres:SetPoint("CENTER", 0, 0)
        f.incres.bgtex:SetTexture("Interface\\AddOns\\NotGrid\\media\\res")
        f.incres.bgtex:SetAllPoints()
        f.incres:Hide()

        -- 治疗预估条
        f.incheal:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", tile = true, tileSize = 16, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
        f.incheal:SetBackdropColor(0, 0, 0, 0)
        f.incheal:SetBackdropBorderColor(0, 0, 0, 0) -- 初始透明
        f.incheal:SetWidth(o.unitwidth)
        f.incheal:SetHeight(o.unitheight)

        -- 团队领袖图标
        f.leader:SetWidth(10)
        f.leader:SetHeight(10)
        f.leader:ClearAllPoints()
        f.leader:SetPoint("TOPLEFT", 0, 0)
        f.leader.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        f.leader.icon:SetAllPoints()
        f.leader:Hide()

        -- 职责图标
        f.dungeon_role:SetWidth(o.dungeonrolesize)
        f.dungeon_role:SetHeight(o.dungeonrolesize)
        f.dungeon_role:ClearAllPoints()
        f.dungeon_role:SetPoint("TOPRIGHT", o.dungeonroleoffx, o.dungeonroleoffy)
        f.dungeon_role:SetFrameLevel(f:GetFrameLevel() + 3)
        f.dungeon_role.icon:SetTexture("Interface\\AddOns\\NotGrid\\media\\ui-lfg-icon-portraitroles")
        f.dungeon_role.icon:SetAllPoints()
        f.dungeon_role:Hide()

        -- 团队标记图标（星星、月亮等）
        f.healthbar.raidmarker:SetWidth(16)
        f.healthbar.raidmarker:SetHeight(14)
        f.healthbar.raidmarker:SetAlpha(0.5)
        f.healthbar.raidmarker:SetPoint("TOPRIGHT", f.healthbar, "TOPRIGHT", 0, 0)

        -- 姓名/血量和治疗预估文本
        for _, fsname in { "namehealthtext", "healcommtext" } do
            local fs = f[fsname]
            fs:SetShadowColor(0, 0, 0, 0.8)
            fs:SetShadowOffset(1, -1)
            fs:ClearAllPoints()
            if fsname == "namehealthtext" then
                if not o.colorunitnamehealthbyclass then
                    fs:SetTextColor(unpack(o.unitnamehealthtextcolor))
                end
                fs:SetFont(o.unitfont, o.unitnamehealthtextsize, "OUTLINE")
                fs:SetPoint("CENTER", f.healthbar, "CENTER", o.unitnamehealthoffx, o.unitnamehealthoffy)
            elseif fsname == "healcommtext" then
                fs:SetTextColor(unpack(o.unithealcommtextcolor))
                fs:SetFont(o.unitfont, o.unithealcommtextsize, "OUTLINE")
                fs:SetPoint("CENTER", f.healthbar, "CENTER", o.unithealcommtextoffx, o.unithealcommtextoffy)
                if not o.showhealcommtext then
                    fs:Hide()
                end
            end
        end

        -- 追踪图标大小和位置（只调整不重新创建）
        for i, point in { "TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT" } do
            local iconFrame = f.healthbar["trackingicon" .. i]
            -- 只调整大小
            iconFrame:SetWidth(o.unittrackingiconsize)
            iconFrame:SetHeight(o.unittrackingiconsize)
            -- 重新设置位置
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint(point, 0, 0)
        end
    end
end

-----------------------
-- 排列框架位置
-----------------------
function NotGrid:PositionPartyIndexFrames(index, SubGroupCount, TotalUnits, TotalGroups, powermodx, powermody)
    local o = self.o
    if not o.ShowPartyIndex then return end
    local v = self.PartyIndexFrames["partyindex" .. index]
    if v.index == index and SubGroupCount == 0 then
        v.TextString:ClearAllPoints()
        if o.growthdirection == 1 then
            v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalGroups,
                o.unitheight + o.unitnamehealthoffy)
        elseif o.growthdirection == 2 then
            v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                -(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalGroups,
                o.unitheight + o.unitnamehealthoffy)
        elseif o.growthdirection == 3 then
            v.TextString:SetPoint("CENTER", "NotGridContainer", "CENTER", -o.unitwidth,
                -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalGroups)
        elseif o.growthdirection == 4 then
            v.TextString:SetPoint("CENTER", "NotGridContainer", "CENTER", -o.unitwidth,
                (o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalGroups)
        elseif o.growthdirection == 5 then
            v.TextString:SetPoint("CENTER", "NotGridContainer", "CENTER", -o.unitwidth,
                -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalUnits)
        elseif o.growthdirection == 6 then
            v.TextString:SetPoint("CENTER", "NotGridContainer", "CENTER", -o.unitwidth,
                (o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalUnits)
        elseif o.growthdirection == 7 then
            v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalUnits,
                o.unitheight + o.unitnamehealthoffy)
        elseif o.growthdirection == 8 then
            v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                -(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalUnits,
                o.unitheight + o.unitnamehealthoffy)
        elseif o.growthdirection == 9 then
            if (TotalGroups < 4) then
                v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                    (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalGroups,
                    o.unitheight + o.unitnamehealthoffy)
            elseif (TotalGroups < 8) then
                v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                    (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4),
                    -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * 5.2 + o.unitnamehealthoffy)
            elseif (TotalGroups == 8) then
                v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                    (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4),
                    o.unitheight + o.unitnamehealthoffy)
            elseif (TotalGroups == 9) then
                v.TextString:SetPoint("BOTTOM", "NotGridContainer", "TOP",
                    (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4 - 1),
                    -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * 5.2 + o.unitnamehealthoffy)
            end
        end
        v:Show()
    end
end

function NotGrid:PositionFrames()
    local partycount = GetNumPartyMembers()
    local raidcount = GetNumRaidMembers()

    local SubGroupCounts = self.Compost:Acquire(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    local TotalGroups = 0
    local TotalUnits = 0
    local o = self.o

    local powermodx = 0
    local powermody = 0
    if o.showpowerbar then
        if o.powerposition <= 2 then
            powermody = o.powersize + 1
        else
            powermodx = o.powersize + 1
        end
    end

    -- 确保容器不会太靠左（防止超出屏幕）
    local tmpwidth = 40 + math.ceil(o.unitwidth / 2);
    if o.growthdirection == 3 or o.growthdirection == 4 then
        if o.containeroffx < tmpwidth then
            o.containeroffx = tmpwidth
        end
    else
        if o.containeroffx < 40 then
            o.containeroffx = 40
        end
    end

    -- 收集宠物框架，稍后单独排列
    local petFrames = {}

    for i = 1, 10 do
        for key, f in self.UnitFrames do
            if UnitExists(f.unit) or o.configmode then
                -- 团队中隐藏自己的 pet 框架，防止重复
                if f.unit == "pet" and GetNumRaidMembers() > 0 and o.showpets then
                    f:Hide()
                else
					local subgroup = nil
					if f.raidindex then
						if o.configmode then
							subgroup = (math.ceil(math.abs(f.raidindex / 5)))
						else
							_, _, subgroup = GetRaidRosterInfo(f.raidindex)
						end
					elseif (string.find(f.unit, "party%d") or (f.unit == "player")) and ((raidcount > 0 and o.showpartyinraid) or (raidcount == 0 and partycount > 0 and o.showinparty and not o.configmode) or (raidcount == 0 and partycount == 0 and o.showwhilesolo and not o.configmode) or (o.configmode and o.showpartyinraid)) then
						subgroup = 9
					elseif (string.find(f.unit, "raidpet%d") or f.unit == "pet") and raidcount > 0 and o.showpets then
						subgroup = 10
					elseif (string.find(f.unit, "partypet%d") or f.unit == "pet") and (
						(raidcount > 0 and o.showpartyinraid and o.showpets) or
						(raidcount == 0 and partycount > 0 and o.showinparty and o.showpets and not o.configmode) or
						(raidcount == 0 and partycount == 0 and o.showwhilesolo and o.showpets and not o.configmode) or
						(o.configmode and o.showpartyinraid and o.showpets)
					) then
						subgroup = 10
					else
						f:Hide()
					end

					if subgroup == i then
						-- 宠物组先收集，最后统一排列
						if i == 10 then
							table.insert(petFrames, f)
						else
							f:ClearAllPoints()
							-- 根据生长方向排列普通成员
							if o.growthdirection == 1 then
								f:SetPoint("CENTER", (o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) *
									TotalGroups, -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) *
									SubGroupCounts[i])
							elseif o.growthdirection == 2 then
								f:SetPoint("CENTER", -(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) *
									TotalGroups, -(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) *
									SubGroupCounts[i])
							elseif o.growthdirection == 3 then
								f:SetPoint("CENTER",
									(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * SubGroupCounts[i],
									-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalGroups)
							elseif o.growthdirection == 4 then
								f:SetPoint("CENTER",
									(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * SubGroupCounts[i],
									(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalGroups)
							elseif o.growthdirection == 5 then
								f:SetPoint("CENTER", 0,
									-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalUnits)
							elseif o.growthdirection == 6 then
								f:SetPoint("CENTER", 0,
									(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * TotalUnits)
							elseif o.growthdirection == 7 then
								f:SetPoint("CENTER",
									(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalUnits, 0)
							elseif o.growthdirection == 8 then
								f:SetPoint("CENTER",
									-(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalUnits, 0)
							elseif o.growthdirection == 9 then
								if (TotalGroups < 4) then
									f:SetPoint("CENTER",
										(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * TotalGroups,
										-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * SubGroupCounts[i])
								elseif (TotalGroups < 8) then
									f:SetPoint("CENTER",
										(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4),
										-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) *
										(5.8 + SubGroupCounts[i]))
								elseif (TotalGroups == 8) then
									f:SetPoint("CENTER",
										(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4),
										-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * SubGroupCounts[i])
								elseif (TotalGroups == 9) then
									f:SetPoint("CENTER",
										(o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right) * (TotalGroups - 4 - 1),
										-(o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom) * (5.8 + SubGroupCounts[i]))
								end
							end
							self:PositionPartyIndexFrames(i, SubGroupCounts[i], TotalUnits, TotalGroups, powermodx, powermody)
							f:Show()
							TotalUnits = TotalUnits + 1
							SubGroupCounts[i] = SubGroupCounts[i] + 1
						end
					end
				end
            else
                f:Hide()
            end
        end

        -- 宠物组不增加 TotalGroups，避免影响普通组的布局
        if i ~= 10 and SubGroupCounts[i] > 0 then
            TotalGroups = TotalGroups + 1
        end
    end

    -- 宠物排列：先沿组内方向排列，满5个后换行/换列，方向与小队/团队一致
    if petFrames and table.getn(petFrames) > 0 then
        local maxPerLine = 5
        local stepX = o.unitwidth + powermodx + o.unitborder * 2 + o.space_left_and_right
        local stepY = o.unitheight + powermody + o.unitborder * 2 + o.space_top_and_bottom

        local primaryX, primaryY, secondaryX, secondaryY

        -- 主方向 = 组内排列方向，副方向 = 组间排列方向（或换行/换列方向）
        if o.growthdirection == 1 then          -- 小组左→右，组内上→下
            primaryX, primaryY = 0, -stepY
            secondaryX, secondaryY = stepX, 0
        elseif o.growthdirection == 2 then      -- 小组右→左，组内上→下
            primaryX, primaryY = 0, -stepY
            secondaryX, secondaryY = -stepX, 0
        elseif o.growthdirection == 3 then      -- 小组上→下，组内左→右
            primaryX, primaryY = stepX, 0
            secondaryX, secondaryY = 0, -stepY
        elseif o.growthdirection == 4 then      -- 小组下→上，组内左→右
            primaryX, primaryY = stepX, 0
            secondaryX, secondaryY = 0, stepY
        elseif o.growthdirection == 5 then      -- 单列向下
            primaryX, primaryY = 0, -stepY
            secondaryX, secondaryY = stepX, 0
        elseif o.growthdirection == 6 then      -- 单列向上
            primaryX, primaryY = 0, stepY
            secondaryX, secondaryY = stepX, 0
        elseif o.growthdirection == 7 then      -- 单行向右
            primaryX, primaryY = stepX, 0
            secondaryX, secondaryY = 0, -stepY
        elseif o.growthdirection == 8 then      -- 单行向左
            primaryX, primaryY = -stepX, 0
            secondaryX, secondaryY = 0, -stepY
        else                                    -- 包括方向9，默认同方向1
            primaryX, primaryY = 0, -stepY
            secondaryX, secondaryY = stepX, 0
        end

        -- 宠物组起始点（接在普通单位后面）
        local originX, originY
        if o.growthdirection == 1 then
            originX = TotalGroups * stepX
            originY = 0
        elseif o.growthdirection == 2 then
            originX = -TotalGroups * stepX
            originY = 0
        elseif o.growthdirection == 3 then
            originX = 0
            originY = -TotalGroups * stepY
        elseif o.growthdirection == 4 then
            originX = 0
            originY = TotalGroups * stepY
        elseif o.growthdirection == 5 then
            originX = 0
            originY = -TotalUnits * stepY
        elseif o.growthdirection == 6 then
            originX = 0
            originY = TotalUnits * stepY
        elseif o.growthdirection == 7 then
            originX = TotalUnits * stepX
            originY = 0
        elseif o.growthdirection == 8 then
            originX = -TotalUnits * stepX
            originY = 0
        else
            originX = TotalGroups * stepX
            originY = 0
        end

        local totalPets = table.getn(petFrames)
        for idx = 1, totalPets do
            local line = math.floor((idx - 1) / maxPerLine)   -- 第几次换行/换列
            local pos  = math.mod((idx - 1), maxPerLine)      -- 当前行/列内的位置

            local x = originX + pos * primaryX + line * secondaryX
            local y = originY + pos * primaryY + line * secondaryY

            local f = petFrames[idx]
            f:ClearAllPoints()
            f:SetPoint("CENTER", x, y)
            f:Show()
        end
    end

    -- 容器定位（如果不可拖动则使用配置的偏移量）
    if not o.draggable then
        self.Container:ClearAllPoints()
        self.Container:SetPoint(o.containerpoint, o.containeroffx, o.containeroffy)
    end

    self.Compost:Reclaim(SubGroupCounts)
end

-----------------------
-- 小地图按钮
-----------------------
function NotGrid:CreateMinimapButton()
    -- 创建按钮
    local button = CreateFrame("Button", "NotGridMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- 图标
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture("Interface\\AddOns\\NotGrid\\media\\battlenet-portrait")
    button.icon = icon
    
    -- 边框
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- 拖动功能
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    local function UpdatePosition()
        local angle = NotGridOptions.minimapAngle or 180
        local x = 80 * cos(angle)
        local y = 80 * sin(angle)
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        this:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            
            local angle = math.deg(math.atan2(py - my, px - mx))
            NotGridOptions.minimapAngle = angle

            UpdatePosition()
        end)
    end)
    
    button:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
        this:UnlockHighlight()
    end)
    
    -- 点击事件
    button:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            if NotGridOptionsMenu:IsVisible() then
                NotGridOptionsMenu:Hide()
            else
                NotGridOptionsMenu:Show()
            end
        elseif arg1 == "RightButton" then
            NotGrid:ToggleFrameShowHide()
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["Minimap Title"])               -- 需添加本地化键
        GameTooltip:AddLine(L["Minimap Left Click"], 1, 1, 1)  -- 需添加本地化键
        GameTooltip:AddLine(L["Minimap Right Click"], 1, 1, 1) -- 需添加本地化键
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- 初始位置
    UpdatePosition()
    button:Show()
    
    self.MinimapButton = button
end