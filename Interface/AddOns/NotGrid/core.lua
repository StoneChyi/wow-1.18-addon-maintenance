-- core.lua
local L = AceLibrary("AceLocale-2.2"):new("NotGrid")
NotGrid = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")
NotGridOptions = {} -- 插件完全初始化后，WoW会自动填充其保存变量（如果有）

-- 职业角色图标纹理坐标（Tank/Healer/DPS）
local ROLE_TEX_COORDS = {
    TANK = {0, 19/64, 22/64, 41/64},      -- 坦克（盾牌）
    HEALER = {20/64, 39/64, 1/64, 20/64}, -- 治疗（十字）
    DAMAGER = {20/64, 39/64, 22/64, 41/64} -- DPS（剑）
}

-- 仇恨数据：当前目标仇恨 + 多目标仇恨 + 坦克标记
NotGrid.ThreatData = {}        -- { [玩家名] = { threat, perc, tank, time } }
NotGrid.MultiThreatData = {}   -- { [玩家名] = { [怪物名] = 仇恨百分比 } }
NotGrid.TankNames = {}         -- { [玩家名] = true }

-- 兼容性包装：获取单位的LFG角色
local function GetUnitLFGRole(unit)
    -- 检查团队中的主坦克/主助攻设置
    local index = NotGrid.raid_indexes and NotGrid.raid_indexes[unit]
    if index then
        local role = select(10, GetRaidRosterInfo(index))
        if role == "MAINTANK" then
            return "TANK"
        elseif role == "MAINASSIST" then
            return "DAMAGER"
        end
    end

    -- 检查小队中的主坦克/主助攻
    if GetPartyAssignment then
        if GetPartyAssignment("MAINTANK", unit) then
            return "TANK"
        elseif GetPartyAssignment("MAINASSIST", unit) then
            return "DAMAGER"
        end
    end

    return nil
end

function NotGrid:IsLeader(playerName)
    -- 检查是否有团队管理权限
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == playerName and (rank == 2 or rank == 1) then
                return true
            end
        end
    elseif GetNumPartyMembers() > 0 then
        if IsPartyLeader() then
            return true
        end
    end
    return false
end

function NotGrid:CanSetRole(unitid)
    local playerName = UnitName("player")
    local targetName = UnitName(unitid)

    if playerName == targetName then
        return true
    end

    local result = self:IsLeader(playerName)

    return result
end

function NotGrid:OnInitialize()
    self.HealComm = AceLibrary("HealComm-1.0")
    self.Gratuity = AceLibrary("Gratuity-2.0")
    self.RosterLib = AceLibrary("RosterLib-2.0")
    self.Compost = AceLibrary("Compost-2.0")

    local ok, banzai = pcall(AceLibrary, "Banzai-1.0")
    if ok then self.Banzai = banzai else self.Banzai = nil end

    self.UnitFrames = {}
    self.PartyIndexFrames = {}
    self.ManualRoles = {}
    self.raid_indexes = {}
    self.IdenticalUnits = {}
    self.ProximityVars = {}
    self:GetFortyYardSpell()
    self:GetMapSizes()
    self:CreateFrames()
    self:CreateMinimapButton()

    self:InitTWTThreatSystem()

    -- 检测 Nampower 环境
    self:DetectNampower()
end

function NotGrid:DetectNampower()
    if GetNampowerVersion then
        self.hasNampower = true
        self:RegisterNampowerCastEvent()
    else
        self.hasNampower = false
    end
end

-- 注册 Nampower 施法事件
function NotGrid:RegisterNampowerCastEvent()
    if not self.hasNampower then return end

    -- 创建事件监听框架（如果尚未创建）
    if not self.NampowerEventFrame then
        self.NampowerEventFrame = CreateFrame("Frame")
        self.NampowerEventFrame:RegisterEvent("SPELL_CAST_EVENT")
        self.NampowerEventFrame:SetScript("OnEvent", function()
            local success, spellId, castType, targetGuid = arg1, arg2, arg3, arg4
            -- 只处理成功施法，且是治疗法术（通过 HealComm 已知法术列表判断）
            if success == 1 and self.HealComm and self.HealComm.Spells then
                local spellName = GetSpellRecField(spellId, "name")
                if spellName and self.HealComm.Spells[spellName] then
                    -- 延迟执行，确保服务器已同步
                    self:ScheduleEvent("NotGrid_SpellCanTarget", function()
                        self:SpellCanTarget()
                    end, 0.05)
                end
            end
        end)
    end
end

-- ==================================================
-- 初始化乌龟服TWT仇恨系统（多目标支持）
-- ==================================================
function NotGrid:InitTWTThreatSystem()
    self.ThreatFrame = CreateFrame("Frame")
    self.ThreatFrame:RegisterEvent("CHAT_MSG_ADDON")

    self.ThreatFrame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            if arg1 and string.find(arg1, "TWT") and arg2 then
                -- 处理复合数据包：TWTv4...#TMTv1...
                local v4part, tmPart = arg2, nil
                local sep = string.find(arg2, "#", 1, true)
                if sep then
                    v4part = string.sub(arg2, 1, sep-1)
                    local rest = string.sub(arg2, sep+1)
                    if string.find(rest, "TMTv1=", 1, true) then
                        tmPart = rest
                    end
                end
                if v4part and string.find(v4part, "TWTv4=") then
                    NotGrid:ParseThreatV4(v4part)
                end
                if tmPart then
                    NotGrid:ParseTankMode(tmPart)
                end
                NotGrid:UpdateAllThreatBorders()
            end
        end
    end)

    -- 周期性请求多目标仇恨（坦克模式协议）
    self:ScheduleRepeatingEvent("NotGrid_RequestMultiThreat", function()
        self:RequestMultiThreat()
    end, 0.5)
end

function NotGrid:RequestMultiThreat()
    if not self.o.trackaggro then return end
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then return end
    if not UnitExists("target") or UnitIsPlayer("target") or UnitIsDead("target") then return end

    local channel = (GetNumRaidMembers() > 0) and "RAID" or "PARTY"
    -- 发送坦克模式请求（TWT_UDTSv4_TM），让队友回复多目标数据
    SendAddonMessage("TWT", "TWT_UDTSv4_TM_limit=10", channel)
end

-- ==================================================
-- 解析 TWTv4 当前目标仇恨数据
-- ==================================================
function NotGrid:ParseThreatV4(data)
    local prefix = "TWTv4="
    local start = string.find(data, prefix, 1, true)
    if not start then return end
    local content = string.sub(data, start + string.len(prefix))
    if not content or content == "" then return end

    local currentTime = GetTime()
    local newThreat = {}
    local tanks = {}

    for playerData in string.gmatch(content, "([^;]+)") do
        local parts = {}
        for p in string.gmatch(playerData, "([^:]+)") do
            table.insert(parts, p)
        end
        if table.getn(parts) >= 5 then
            local name = parts[1]
            local tank = parts[2] == "1"
            local threatValue = tonumber(parts[3]) or 0
            local perc = tonumber(parts[5]) or 0

            if name and threatValue > 0 then
                newThreat[name] = {
                    threat = threatValue,
                    perc = perc,
                    tank = tank,
                    time = currentTime
                }
                if tank then
                    tanks[name] = true
                end
            end
        end
    end

    self.ThreatData = newThreat
    self.TankNames = tanks
end

-- ==================================================
-- 解析 TMTv1 多目标仇恨数据（坦克模式附加）
-- ==================================================
function NotGrid:ParseTankMode(data)
    local prefix = "TMTv1="
    local start = string.find(data, prefix, 1, true)
    if not start then return end
    local content = string.sub(data, start + string.len(prefix))
    if not content or content == "" then return end

    local newMulti = {}

    for entry in string.gmatch(content, "([^;]+)") do
        local creature, guid, name, percStr = string.match(entry, "([^:]+):([^:]+):([^:]+):(.+)")
        if creature and name then
            local perc = tonumber(percStr) or 0
            if not newMulti[name] then
                newMulti[name] = {}
            end
            newMulti[name][creature] = perc
        end
    end

    self.MultiThreatData = newMulti
end

-- ==================================================
-- 清理过期仇恨数据（超过 5 秒未更新则移除）
-- ==================================================
function NotGrid:CleanThreatData()
    local currentTime = GetTime()
    local hasChanges = false

    for name, data in pairs(self.ThreatData) do
        if currentTime - data.time > 5 then
            self.ThreatData[name] = nil
            hasChanges = true
        end
    end

    if hasChanges then
        -- 多目标数据也一并清空（因为没有独立的过期机制）
        self.MultiThreatData = {}
        self.TankNames = {}
        self:UpdateAllThreatBorders()
    end
end

-- ==================================================
-- 获取单位在当前目标上的仇恨百分比
-- ==================================================
function NotGrid:GetUnitThreatPercent(unitid)
    if not unitid or not UnitExists(unitid) then return nil end
    local name = UnitName(unitid)
    if not name then return nil end

    local data = self.ThreatData[name]
    if not data then return nil end
    if GetTime() - data.time > 5 then
        self.ThreatData[name] = nil
        return nil
    end

    return data.perc
end

-- ==================================================
-- 获取主坦克（标记为坦克且威胁最高）的威胁百分比
-- ==================================================
function NotGrid:GetMainTankThreatPercent()
    local maxPerc = 0
    for name, data in pairs(self.ThreatData) do
        if data.tank and data.perc > maxPerc then
            maxPerc = data.perc
        end
    end
    return maxPerc > 0 and maxPerc or nil
end

-- ==================================================
-- 跨目标威胁警告（基于 TMTv1 数据）
-- ==================================================
function NotGrid:IsMultiTargetThreatWarning(unitid)
    local name = UnitName(unitid)
    if not name then return false end

    local multi = self.MultiThreatData[name]
    if not multi then return false end

    for creature, perc in pairs(multi) do
        -- 规则1：在任何怪物上达到 100% 且该玩家不是坦克 → 严重 OT
        if perc >= 100 and not self.TankNames[name] then
            return true
        end
        -- 规则2：超过自定义阈值（默认90）且不是坦克 → 即将 OT
        local threshold = self.o.multiAggroThreshold or 90
        if perc >= threshold and not self.TankNames[name] then
            return true
        end
    end
    return false
end

-- ==================================================
-- 综合威胁警告（当前目标 + 跨目标）
-- ==================================================
function NotGrid:IsThreatWarning(unitid)
    -- 优先判断当前目标仇恨
    local perc = self:GetUnitThreatPercent(unitid)
    if perc then
        if perc >= 100 then return true end
        local tankPerc = self:GetMainTankThreatPercent()
        if tankPerc and tankPerc > 0 and perc >= tankPerc * 0.8 then
            return true
        end
    end

    -- 再检查跨目标仇恨
    if self:IsMultiTargetThreatWarning(unitid) then
        return true
    end

    return false
end

-- ==================================================
-- 更新所有单位的边框状态
-- ==================================================
function NotGrid:UpdateAllThreatBorders()
    for unitid, _ in pairs(self.UnitFrames) do
        if UnitExists(unitid) then
            self:UNIT_BORDER(unitid)
        end
    end
end

function NotGrid:OnEnable()
    self.o = NotGridOptions
    self:SetDefaultOptions()
    self:DoDropDown()
    self:ConfigUnitFrames()
    self:ConfigPartyIndexFrames()
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "GetFortyYardSpell")
    for key in L.CombatEvents do
        self:RegisterEvent(key, "CombatEventHandle")
    end
    if Clique and self.o.cliquehook then
        Clique.CastSpell = NotGrid.CastHandle
    end
    self:UpdateLeaderIcon()
    self:UpdateDungeonRoleIcons()
    if self.Banzai then
        self:RegisterEvent("Banzai_UnitGainedAggro", "UNIT_BORDER")
        self:RegisterEvent("Banzai_UnitLostAggro", "UNIT_BORDER")
    end
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA","UpdateProximityMapVars")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED","BlizzFrameHandler")
    self:RegisterEvent("RAID_ROSTER_UPDATE","BlizzFrameHandler")
    self:RegisterEvent("UNIT_PET","BlizzFrameHandler")
    self:RegisterEvent("RosterLib_RosterChanged")
    self:RegisterEvent("RosterLib_UnitChanged")
    self:RegisterEvent("HealComm_Healupdate","HealCommHandler")
    self:RegisterEvent("HealComm_Ressupdate","HealCommHandler")
    self:RegisterEvent("NG_UNIT_PROXIMITY","UNIT_PROXIMITY")
    self:ScheduleRepeatingEvent("NG_UNIT_PROXIMITY", self.o.proximityrate)
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidMarkers")
    self:RegisterEvent("PARTY_LEADER_CHANGED","UpdateLeaderIcon")
    self.wasInParty = (GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)
    table.insert(UISpecialFrames, "NotGridOptionsMenu")
    self:ScheduleRepeatingEvent("NG_CLEAN_THREAT", function()
        NotGrid:CleanThreatData()
    end, 2.0)
    -- 如果 Nampower 不可用，钩住 CastSpellByName 作为回退
    if not self.hasNampower then
        self:HookCastSpellByName()
    end
end

function NotGrid:HookCastSpellByName()
    if self._castSpellHooked then return end
    self._origCastSpellByName = CastSpellByName
    CastSpellByName = function(spell, target)
        if target then
            self._origCastSpellByName(spell, target)
        else
            self._origCastSpellByName(spell)
        end
        self:ScheduleEvent("NotGrid_SpellCanTarget", function()
            self:SpellCanTarget()
        end, 0.05)
    end
    self._castSpellHooked = true
end

-- ==================================================
-- UNIT_MAIN 函数
-- ==================================================
function NotGrid:UNIT_MAIN(unitid)
    local o = self.o
    local f = self.UnitFrames[unitid]
    if o.configmode then
        unitid = "player"
    end

    if f and UnitExists(unitid) then
        local name = UnitName(unitid)
        local shortname = string.sub(name, 1, o.namelength)
        local _,class = UnitClass(unitid)
        local powertype = UnitPowerType(unitid)
        local pcolor = ManaBarColor[powertype]
        local color = {}

        if o.configmode then
            local c = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
            local id = string.sub(f.unit, -1)
            id = tonumber(id)
            if id == 0 then id = 1 end
            if id == 1 then
                pcolor = ManaBarColor[1]
            elseif id == 4 then
                pcolor = ManaBarColor[3]
            else
                pcolor = ManaBarColor[0]
            end
            class = c[id]
        end

        if f.pet and o.usepetcolor then
            color.r,color.g,color.b = unpack(o.petcolor)
        elseif class and class == "SHAMAN" and o.useshamancolor then
            color = {r=0.14,g=0.35,b=1}
        elseif class then
            color = RAID_CLASS_COLORS[class]
        else
            color = {r=1,g=0,b=1}
        end

        f.name = name

        if o.colorunithealthbarbyclass then
            f.healthbar:SetStatusBarColor(color.r, color.g, color.b, o.unithealthbarcolor[4])
        end
        if o.colorunitnamehealthbyclass then
            f.namehealthtext:SetTextColor(color.r, color.g, color.b, o.unitnamehealthtextcolor[4])
        end
        if o.colorunithealthbarbgbyclass then
            f.healthbar.bgtex:SetVertexColor(color.r, color.g, color.b)
        end

        f.powerbar:SetStatusBarColor(pcolor.r, pcolor.g, pcolor.b)
        if o.colorpowerbarbgbytype then
            f.powerbar.bgtex:SetVertexColor(pcolor.r, pcolor.g, pcolor.b)
        end

        if UnitIsConnected(unitid) then
            local healamount, currhealth, maxhealth, deficit, healtext, currpower, maxpower
            if o.configmode then
                currhealth = UnitHealth(unitid)/2
                maxhealth = UnitHealthMax(unitid)
                deficit = maxhealth - currhealth
                currpower = UnitManaMax(unitid)/2
                maxpower = UnitManaMax(unitid)
                healamount = maxhealth/4
            else
                currhealth = UnitHealth(unitid)
                maxhealth = UnitHealthMax(unitid)
                deficit = maxhealth - currhealth
                currpower = UnitMana(unitid)
                maxpower = UnitManaMax(unitid)
                healamount = self.HealComm:getHeal(name)
            end

            local isDead = UnitIsDead(unitid)
            local isGhost = UnitIsGhost(unitid) or currhealth <= 0
            -- Do not redraw incoming heals after UnitHealthZero clears a dead unit.
            if isDead or isGhost then healamount = 0 end

            if healamount > 999 then
                healtext = string.format("+%.1fk", healamount/1000.0)
            else
                healtext = string.format("+%d", healamount)
            end

            f.healthbar:SetMinMaxValues(0, maxhealth)
            f.healthbar:SetValue(currhealth)

            f.powerbar:SetMinMaxValues(0, maxpower)
            f.powerbar:SetValue(currpower)

            if isDead then
                self:UnitHealthZero(f, L["Dead"], shortname)
            elseif isGhost then
                self:UnitHealthZero(f, L["Ghost"], shortname)
            elseif currhealth/maxhealth*100 <= self.o.healththreshhold then
                local deficittext
                if deficit > 999 then
                    deficittext = string.format("-%.1fk", deficit/1000.0)
                else
                    deficittext = string.format("-%d", deficit)
                end
                f.namehealthtext:SetText(deficittext)
            else
                f.namehealthtext:SetText(shortname)
            end

            if healamount > 0 and o.showhealcommbar then
                self:SetIncHealFrame(f, healamount, currhealth, maxhealth)
            else
                f.incheal:SetBackdropColor(0,0,0,0)
            end
            if healamount > 0 and o.showhealcommtext then
                f.healcommtext:SetText(healtext)
                f.healcommtext:Show()
            else
                f.healcommtext:Hide()
            end

            if self.HealComm:UnitisResurrecting(name) then
                f.incres:Show()
            else
                f.incres:Hide()
            end
        else
            self:UnitHealthZero(f, L["Offline"], shortname)
        end
    end
end

function NotGrid:UnitHealthZero(f, state, shortname)
    f.namehealthtext:SetText(shortname.."\n" .. state)
    f.incheal:SetBackdropColor(0,0,0,0)
    f.healthbar:SetMinMaxValues(0, 1)
    f.healthbar:SetValue(0)
    f.powerbar:SetMinMaxValues(0, 1)
    f.powerbar:SetValue(0)
    f.healcommtext:Hide()
end

function NotGrid:SetIncHealFrame(f, healamount, currhealth, maxhealth)
    if maxhealth <= 0 or currhealth <= 0 or currhealth >= maxhealth or healamount <= 0 then
        f.incheal:SetBackdropColor(0,0,0,0)
        return
    end
    local o = self.o
    if o.unithealthorientation == 1 then
        local modifier = maxhealth/o.unitheight
        local healheight = healamount/modifier
        local currheight = currhealth/modifier
        local maxheight = o.unitheight-currheight
        if healheight >= maxheight then healheight = maxheight end
        f.incheal:SetHeight(healheight)
        f.incheal:ClearAllPoints()
        f.incheal:SetPoint("BOTTOM",0,currheight)
    else
        local modifier = maxhealth/o.unitwidth
        local healwidth = healamount/modifier
        local currwidth = currhealth/modifier
        local maxwidth = o.unitwidth-currwidth
        if healwidth >= maxwidth then healwidth = maxwidth end
        f.incheal:SetWidth(healwidth)
        f.incheal:ClearAllPoints()
        f.incheal:SetPoint("LEFT",currwidth,0)
    end
    local color = o.unithealcommbarcolor
    f.incheal:SetBackdropColor(color[1],color[2],color[3],color[4])
end

-- ==================================================
-- UNIT_AURA 函数 (Nampower 优化)
-- ==================================================
function NotGrid:UNIT_AURA(unitid)
    local o = self.o
    local f = self.UnitFrames[unitid]
    local auratable = self.Compost:Acquire()
    local auratexture = self.Compost:Acquire()
    local typeTexture = {
        [L["Magic"]] = "Interface\\Icons\\Spell_Holy_DispelMagic",
        [L["Poison"]] = "Interface\\Icons\\Spell_Nature_NullifyPoison",
        [L["Curse"]] = "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth",
        [L["Disease"]] = "Interface\\Icons\\Spell_Nature_NullifyDisease",
    }

    if f and UnitExists(unitid) then
        if self.hasNampower then
            -- Nampower 环境
            local auraTable = GetUnitField(unitid, "aura")
            if auraTable then
                for i = 1, 48 do
                    local spellId = auraTable[i]
                    if spellId and spellId ~= 0 then
                        local isDebuff = (i > 32)
                        local spellName = self:GetCachedSpellName(spellId)

                        -- 如果开启了“只显示可驱散 Debuff”，则跳过所有非 Debuff 的光环
                        local shouldAddThisAura = true
                        if o.showOnlyDispellableDebuffs and not isDebuff then
                            shouldAddThisAura = false
                        end

                        if shouldAddThisAura and spellName then
                            auratable[spellName] = true
                            local texture = self:GetCachedSpellIcon(spellId)
                            auratexture[spellName] = {texture = texture, index = i, isDebuff = isDebuff}
                        end

                        if isDebuff then
                            local dispelType = self:GetCachedDispelType(spellId)
                            if dispelType then
                                local spelltype = self:GetDispelTypeString(dispelType)
                                if spelltype then
                                    local DebuffType = {
                                        ["Magic"] = L["Magic"],
                                        ["Poison"] = L["Poison"],
                                        ["Curse"] = L["Curse"],
                                        ["Disease"] = L["Disease"],
                                    }
                                    local localizedType = DebuffType[spelltype]
                                    if localizedType then
                                        local shouldShowType = true
                                        if o.showOnlyDispellableDebuffs then
                                            shouldShowType = self:IsDebuffDispellableByPlayer(spelltype)
                                        end
                                        if shouldShowType and not auratable[localizedType] then
                                            auratable[localizedType] = true
                                            local icon = auratexture[spellName] and auratexture[spellName].texture or typeTexture[localizedType]
                                            auratexture[localizedType] = {texture = icon, index = i, isDebuff = true}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            -- 原始回退逻辑

            -- 处理 Buff 时，如果开启了过滤，直接跳过整个 UnitBuff 遍历
            local bi = 1
            while UnitBuff(unitid, bi) do
                local texture = UnitBuff(unitid, bi)
                self.Gratuity:SetUnitBuff(unitid, bi)
                local buffname = self.Gratuity:GetLine(1)
                if buffname then
                    -- 只有当没有开启“只显示可驱散”选项时，才添加 Buff
                    if not o.showOnlyDispellableDebuffs then
                        auratable[buffname] = true
                        auratexture[buffname] = {texture = texture, index = bi, isDebuff = false}
                    end
                end
                bi = bi + 1
            end

            -- Debuff 的处理保持原样（已经根据选项过滤）
            local di = 1
            while UnitDebuff(unitid, di) do
                local texture = UnitDebuff(unitid, di)
                self.Gratuity:SetUnitDebuff(unitid, di)
                local debuffname = self.Gratuity:GetLine(1)
                local _, _, spelltype = UnitDebuff(unitid, di)
                local shouldShowDebuff = true
                if o.showOnlyDispellableDebuffs and spelltype then
                    shouldShowDebuff = self:IsDebuffDispellableByPlayer(spelltype)
                end
                if shouldShowDebuff and debuffname then
                    auratable[debuffname] = true
                    auratexture[debuffname] = {texture = texture, index = di, isDebuff = true}
                end
                if spelltype then
                    local DebuffType = {
                        ["Magic"] = L["Magic"],
                        ["Poison"] = L["Poison"],
                        ["Curse"] = L["Curse"],
                        ["Disease"] = L["Disease"],
                    }
                    local localizedType = DebuffType[spelltype]
                    if localizedType then
                        local shouldShowType = true
                        if o.showOnlyDispellableDebuffs then
                            shouldShowType = self:IsDebuffDispellableByPlayer(spelltype)
                        end
                        if shouldShowType and not auratable[localizedType] then
                            auratable[localizedType] = true
                            auratexture[localizedType] = {texture = (texture or typeTexture[localizedType]), index = di, isDebuff = true}
                        end
                    end
                end
                di = di + 1
            end
        end

        -- 追踪图标处理（两种模式通用）
        for i = 1, 8 do
            local iconFrame = f.healthbar["trackingicon" .. i]
            local found = false
            for _, text in ipairs(self.o["trackingicon" .. i]) do
                if auratable[text] then
                    found = true
                    local auraInfo = auratexture[text]
                    if self.o.showTrackingAsColors then
                        iconFrame.texture:SetTexture("Interface\\Buttons\\WHITE8X8")  -- 白色方块纹理
                        iconFrame.texture:SetVertexColor(unpack(self.o["trackingicon"..i.."color"]))
                    else
                        iconFrame.texture:SetTexture(auraInfo.texture)
                        iconFrame.texture:SetVertexColor(1, 1, 1, 1)  -- 确保图标模式下无颜色叠加
                    end
                    iconFrame.buffIndex = auraInfo.index
                    iconFrame.isDebuff = auraInfo.isDebuff
                    iconFrame.unit = unitid
                    break
                end
            end
            if found then
                if self.o["trackingicon" .. i .. "invert"] then
                    iconFrame:Hide()
                else
                    iconFrame:Show()
                end
            else
                if self.o["trackingicon" .. i .. "invert"] then
                    iconFrame:Show()
                else
                    iconFrame:Hide()
                end
            end
        end
    end

    self.Compost:Reclaim(auratable)
    self.Compost:Reclaim(auratexture)
end

-- 获取法术名的缓存版本
function NotGrid:GetCachedSpellName(spellId)
    if not self.spellNameCache then
        self.spellNameCache = {}
    end
    if not self.spellNameCache[spellId] then
        self.spellNameCache[spellId] = GetSpellRecField(spellId, "name") or ""
    end
    return self.spellNameCache[spellId]
end

-- 缓存法术图标纹理
function NotGrid:GetCachedSpellIcon(spellId)
    if not self.spellIconCache then
        self.spellIconCache = {}
    end
    if self.spellIconCache[spellId] == nil then
        local iconID = GetSpellRecField(spellId, "spellIconID")
        self.spellIconCache[spellId] = iconID and GetSpellIconTexture(iconID) or nil
    end
    return self.spellIconCache[spellId]
end

-- 缓存驱散类型编号（不转字符串）
function NotGrid:GetCachedDispelType(spellId)
    if not self.spellDispelCache then
        self.spellDispelCache = {}
    end
    if self.spellDispelCache[spellId] == nil then
        self.spellDispelCache[spellId] = GetSpellRecField(spellId, "dispel") or 0
    end
    return self.spellDispelCache[spellId]
end

-- 将驱散类型编号转换为原界面使用的字符串
function NotGrid:GetDispelTypeString(dispelType)
    if dispelType == 1 then return "Magic"
    elseif dispelType == 2 then return "Curse"
    elseif dispelType == 3 then return "Disease"
    elseif dispelType == 4 then return "Poison"
    else return nil
    end
end

-- 检查玩家是否能驱散某种类型的 debuff
function NotGrid:IsDebuffDispellableByPlayer(dispelType)
    local _, class = UnitClass("player")
    if not class or not dispelType then return false end
    class = string.lower(class)
    if class == "priest" then
        return (dispelType == "Magic" or dispelType == "Disease")
    elseif class == "paladin" then
        return (dispelType == "Magic" or dispelType == "Disease" or dispelType == "Poison")
    elseif class == "shaman" then
        return (dispelType == "Poison" or dispelType == "Disease")
    elseif class == "druid" then
        return (dispelType == "Curse" or dispelType == "Poison")
    elseif class == "mage" then
        return (dispelType == "Curse")
    else
        return false
    end
end

-- ==================================================
-- UNIT_BORDER 函数
-- ==================================================
function NotGrid:UNIT_BORDER(unitid)
    local o = self.o
    local f = self.UnitFrames[unitid]
    if f and UnitExists(unitid) then
        local name = UnitName(unitid)
        local targetname = UnitName("target")
        local currmana = UnitMana(unitid)
        local maxmana = UnitManaMax(unitid)

        if o.tracktarget and targetname and targetname == name then
            f.border:SetBackdropBorderColor(unpack(o.targetcolor))
            f.border.middleart:SetVertexColor(unpack(o.targetcolor))
        elseif o.trackaggro then
            local threatWarning = self:IsThreatWarning(unitid)
            if not threatWarning and self.Banzai then
                threatWarning = self.Banzai:GetUnitAggroByUnitId(unitid)
            end

            if threatWarning then
                f.border:SetBackdropBorderColor(unpack(o.aggrowarningcolor))
                f.border.middleart:SetVertexColor(unpack(o.aggrowarningcolor))
            elseif o.trackmana and UnitPowerType(unitid) == 0 and currmana/maxmana*100 < o.manathreshhold and not UnitIsDeadOrGhost(unitid) then
                f.border:SetBackdropBorderColor(unpack(o.manawarningcolor))
                f.border.middleart:SetVertexColor(unpack(o.manawarningcolor))
            else
                f.border:SetBackdropBorderColor(unpack(o.unitbordercolor))
                f.border.middleart:SetVertexColor(unpack(o.unitbordercolor))
            end
        else
            if o.trackmana and UnitPowerType(unitid) == 0 and currmana/maxmana*100 < o.manathreshhold and not UnitIsDeadOrGhost(unitid) then
                f.border:SetBackdropBorderColor(unpack(o.manawarningcolor))
                f.border.middleart:SetVertexColor(unpack(o.manawarningcolor))
            else
                f.border:SetBackdropBorderColor(unpack(o.unitbordercolor))
                f.border.middleart:SetVertexColor(unpack(o.unitbordercolor))
            end
        end
    end
end

-------------------
-- 单位点击处理 --
-------------------
function NotGrid:UnitPopup_Initialize(dropdownMenu)
    local unit = dropdownMenu.unit
    local name = dropdownMenu.name
    local unitName = UnitName(unit)
    local level = UIDROPDOWNMENU_MENU_LEVEL or 1

    if unit == "player" then
        UnitPopup_ShowMenu(dropdownMenu, "SELF", "player")
    else
        if GetNumRaidMembers() > 0 then
            UnitPopup_ShowMenu(dropdownMenu, "PARTY", unit, name, string.sub(unit, 5))
        else
            UnitPopup_ShowMenu(dropdownMenu, "PARTY", unit, name, string.sub(unit, 6))
        end
    end

    if level == 1 then
        local canSetRole = self:CanSetRole(unit)
        if not canSetRole then return end

        local info = {}
        info.text = ""
        info.isTitle = nil
        info.notCheckable = 1
        info.disabled = 1
        UIDropDownMenu_AddButton(info, level)

        if NotGrid:IsLeader(UnitName("player")) then
            info = {}
            info.text = "  " .. L["Initiate Role Check"]
            info.func = function()
                if GetNumRaidMembers() > 0 then
                    SendAddonMessage("NotGrid", "ROLESELECT", "RAID")
                elseif GetNumPartyMembers() > 0 then
                    SendAddonMessage("NotGrid", "ROLESELECT", "PARTY")
                end
            end
            info.notCheckable = 1
            UIDropDownMenu_AddButton(info, level)
        end

        info = {}
        info.text = ""
        info.isTitle = nil
        info.notCheckable = 1
        info.disabled = 1
        UIDropDownMenu_AddButton(info, level)

        info = {}
        info.text = L["Set Role"]
        info.isTitle = 1
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info, level)

        local function SetRole(role)
            self.ManualRoles[unitName] = role
            self.o.manualroles[unitName] = role
            self:UpdateDungeonRoleIcons()

            local message = "ROLE:" .. unitName .. ":" .. role
            if GetNumRaidMembers() > 0 then
                SendAddonMessage("NotGrid", message, "RAID")
            elseif GetNumPartyMembers() > 0 then
                SendAddonMessage("NotGrid", message, "PARTY")
            end
        end

        local _, class = UnitClass(unit)
        if not class then return end
        class = string.lower(class)

        if not (class == 'priest' or class == 'mage' or class == 'warlock' or class == 'hunter' or class == 'rogue') then
            info = {}
            info.text = "  " .. L["Tank"]
            info.func = function() SetRole("TANK") end
            info.checked = (self.ManualRoles[unitName] == "TANK")
            UIDropDownMenu_AddButton(info, level)
        end

        if not (class == 'warrior' or class == 'mage' or class == 'warlock' or class == 'hunter' or class == 'rogue') then
            info = {}
            info.text = " |cff00ff00" .. L["Healer"] .. "|r"
            info.func = function() SetRole("HEALER") end
            info.checked = (self.ManualRoles[unitName] == "HEALER")
            UIDropDownMenu_AddButton(info, level)
        end

        info = {}
        info.text = " |cfff40000" .. L["Damage"] .. "|r"
        info.func = function() SetRole("DAMAGER") end
        info.checked = (self.ManualRoles[unitName] == "DAMAGER")
        UIDropDownMenu_AddButton(info, level)
    end
end

function NotGrid:ClickHandle(button)
    if button == "RightButton" and SpellIsTargeting() then
        SpellStopTargeting()
        return
    end

    if button == "LeftButton" then
        if SpellIsTargeting() then
            SpellTargetUnit(this.unit)
        elseif CursorHasItem() then
            DropItemOnUnit(this.unit)
        else
            TargetUnit(this.unit)
        end
    else
        local name = UnitName(this.unit)
        local id = string.sub(this.unit,5)
        local unit = this.unit
        local menuFrame = FriendsDropDown
        menuFrame.displayMode = "MENU"

        menuFrame.unit = unit
        menuFrame.name = name

        menuFrame.initialize = function()
            self:UnitPopup_Initialize(_G[UIDROPDOWNMENU_OPEN_MENU])
        end

        ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
    end
end

---------------------
-- 鼠标悬停模拟 --
---------------------
SLASH_NOTGRIDCAST1 = "/ngcast"
function SlashCmdList.NOTGRIDCAST(spell, editbox)
    local unitid = GetMouseFocus().unit
    if LazySpell and unitid then
        if LazySpell.ValidateSpell then
            spell = LazySpell:ValidateSpell(spell, unitid)
        else
            local lsSpell,lsRank = LazySpell:ExtractSpell(spell)
            if NotGrid.HealComm.Spells[lsSpell] and lsRank == 1 then
                local lsRank = LazySpell:CalculateRank(lsSpell, unitid)
                spell = lsSpell.."(等级 "..lsRank..")"
            end
        end
    end
    NotGrid:CastHandle(spell,unitid)
end

---------------------
-- 施法挂钩 --
---------------------
function NotGrid:CastHandle(spell, unitid)
    if unitid == "target" then
        CastSpellByName(spell)
        if SpellIsTargeting() then
            SpellStopTargeting()
        end
        return
    end
    local LastTarget = UnitName("target")
    ClearTarget()
    CastSpellByName(spell)
    NotGrid:SpellCanTarget()
    if unitid and UnitExists(unitid) and SpellIsTargeting() and SpellCanTargetUnit(unitid) then
        SpellTargetUnit(unitid)
    elseif SpellCanTargetUnit("mouseover") then
        SpellTargetUnit("mouseover")
    end
    if SpellIsTargeting() then
        SpellStopTargeting()
    end
    if LastTarget then
        TargetLastTarget()
    end
end

----------------------------------
-- 治疗通讯
----------------------------------
function NotGrid:HealCommHandler(name)
    local unitid = self.RosterLib:GetUnitIDFromName(name)
    self:UNIT_MAIN(unitid)
    if self.IdenticalUnits[unitid] then
        self:UNIT_MAIN(self.IdenticalUnits[unitid])
    end
end

----------------------------------
-- 名册
----------------------------------
function NotGrid:RosterLib_RosterChanged(updatedUnits)
    self:UpdateRaidIndexes()

    for _,val in updatedUnits do
        if not (val.unitid and string.find(val.unitid, "raidpet")) and not (val.oldunitid and string.find(val.oldunitid, "raidpet")) then
            self:GetIdenticalUnits()
            self:ClearIndexFramePoint()
            self:PositionFrames()
            break
        end
    end
end

function NotGrid:UpdateRaidIndexes()
    wipe(self.raid_indexes)
    for i = 1, GetNumRaidMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) then
            self.raid_indexes[unit] = i
        end
    end
end

function NotGrid:GetIdenticalUnits()
    if GetNumRaidMembers() > 0 then
        self.Compost:Reclaim(self.IdenticalUnits)
        self.IdenticalUnits = self.Compost:Acquire()
        local playername = UnitName("player")
        for i=1,40 do
            if UnitExists("raid"..i) then
                local raidid = "raid"..i
                local raidname = UnitName(raidid)
                if playername == raidname then
                    self.IdenticalUnits[raidid] = "player"
                    self.IdenticalUnits["player"] = raidid
                end
                for i=1,4 do
                    if UnitExists("party"..i) then
                        local partyid = "party"..i
                        local partyname = UnitName(partyid)
                        if partyname == raidname then
                            self.IdenticalUnits[raidid] = partyid
                            self.IdenticalUnits[partyid] = raidid
                        end
                    end
                end
            end
        end
    elseif next(self.IdenticalUnits) then
        self.Compost:Reclaim(self.IdenticalUnits)
        self.IdenticalUnits = self.Compost:Acquire()
    end
end

function NotGrid:RosterLib_UnitChanged(unitid, name, class, subgroup, rank, oldname, oldunitid, oldclass, uldsubgroup, oldrank)
    if unitid and self.UnitFrames[unitid] then
        self:UNIT_MAIN(unitid)
        self:UNIT_BORDER(unitid)
        self:UNIT_AURA(unitid)
        if self.IdenticalUnits[unitid] then
            self:UNIT_MAIN(self.IdenticalUnits[unitid])
            self:UNIT_BORDER(self.IdenticalUnits[unitid])
            self:UNIT_AURA(self.IdenticalUnits[unitid])
        end
    end
    if rank ~= oldrank then
        self:UpdateLeaderIcon()
    end
    self:UpdateDungeonRoleIcons()
end

----------------------------------
-- 暴雪事件
----------------------------------
function NotGrid:PLAYER_ENTERING_WORLD()
    if self.o.versionchecking then
        if GetNumRaidMembers() > 0 then
            SendAddonMessage("NotGrid", self.o.version, "RAID")
        elseif GetNumPartyMembers() > 0 then
            SendAddonMessage("NotGrid", self.o.version, "PARTY")
        end
    end
    self:UpdateProximityMapVars()
    self:BlizzFrameHandler()
end

function NotGrid:CHAT_MSG_ADDON()
    if arg1 == "NotGrid" then
        if self.o.versionchecking and tonumber(arg2) then
            if tonumber(arg2) > self.o.version and not self.versionalreadyshown then
                DEFAULT_CHAT_FRAME:AddMessage("|cff0ccca6NotGrid:|r A newer version may be available.")
                self.versionalreadyshown = true
            end
        elseif string.find(arg2, "ROLE:") then
            local _, _, name, role = string.find(arg2, "ROLE:(.+):(.+)")
            if name then
                local hasPermission = false

                if arg4 == UnitName("player") then
                    hasPermission = true
                elseif arg4 == name then
                    hasPermission = true
                else
                    if GetNumRaidMembers() > 0 then
                        for i = 1, GetNumRaidMembers() do
                            local raidName, rank = GetRaidRosterInfo(i)
                            if raidName == arg4 and (rank == 2 or rank == 1) then
                                hasPermission = true
                                break
                            end
                        end
                    elseif GetNumPartyMembers() > 0 then
                        for i = 1, GetNumPartyMembers() do
                            if UnitName("party"..i) == arg4 and UnitIsPartyLeader("party"..i) then
                                hasPermission = true
                                break
                            end
                        end
                        if UnitName("player") == arg4 and IsPartyLeader() then
                            hasPermission = true
                        end
                    end
                end

                if hasPermission then
                    if role == "nil" then
                        self.ManualRoles[name] = nil
                        self.o.manualroles[name] = nil
                    elseif role == "TANK" or role == "HEALER" or role == "DAMAGER" then
                        self.ManualRoles[name] = role
                        self.o.manualroles[name] = role
                    end
                    self:UpdateDungeonRoleIcons()
                end
            end
        elseif string.find(arg2, "ROLESELECT") then
            if self.o.showdungeonrole then
                if not NotGridRoleSelectionFrame then
                    self:CreateRoleSelectionWindow()
                end
                NotGridRoleSelectionFrame:ShowWithCountdown()
            end
        end
    end
end

function NotGrid:BlizzFrameHandler()
    for i=1,GetNumPartyMembers() do
        if (GetNumRaidMembers() > 0) then
            if self.o.showblizzframesInRaid then
                _G["PartyMemberFrame"..i]:Show();
            else
                _G["PartyMemberFrame"..i]:Hide();
            end
        else
            if self.o.showblizzframesInParty then
                _G["PartyMemberFrame"..i]:Show();
            else
                _G["PartyMemberFrame"..i]:Hide();
            end
        end
    end
    self:UpdateLeaderIcon()
    self:UpdateDungeonRoleIcons()
    self:HandlePartyChange()
    self:UpdateRaidMarkers()
end

local leaderUnit = nil

function NotGrid:UpdateLeaderIcon()
    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    if raidCount > 0 then
        for i=1, raidCount do
            local name, rank = GetRaidRosterInfo(i)
            local f = getglobal("NotGridContainerraid"..i.."leader")
            if rank == 2 then
                f:Show()
            else
                f:Hide()
            end
        end
    else
        if partyCount > 0 then
            if leaderUnit then
                getglobal("NotGridContainerplayerleader"):Hide()
                for i=1, partyCount do
                    getglobal("NotGridContainerparty"..i.."leader"):Hide()
                end
                getglobal("NotGridContainer"..leaderUnit.."leader"):Show()
            else
                local f = getglobal("NotGridContainerplayerleader")
                if IsPartyLeader() then
                    f:Show()
                else
                    f:Hide()
                end
                for i=1, partyCount do
                    f = getglobal("NotGridContainerparty"..i.."leader")
                    if UnitIsPartyLeader("Party"..i) then
                        f:Show()
                    else
                        f:Hide()
                    end
                end
            end
        end
    end
end

function NotGrid:CHAT_MSG_SYSTEM()
    if GetNumRaidMembers() > 0 or (string.find(arg1,"离开了队伍") and GetNumPartyMembers() == 0) then
        leaderUnit = nil
        return
    end
    if not string.find(arg1, "现在是队长") then return end
    leaderName = string.gsub(arg1,"现在是队长", "")
    if leaderName == "你" then
        leaderUnit = "player"
    else
        for i=1,GetNumPartyMembers() do
            if UnitName("party"..i) == leaderName then
                leaderUnit = "party"..i
            end
        end
    end
    self:UpdateLeaderIcon()
end

function NotGrid:UpdateRaidMarkers()
    for unitid, f in pairs(self.UnitFrames) do
        if UnitExists(unitid) then
            local markerIndex = GetRaidTargetIndex(unitid)
            if markerIndex then
                local markerTexture = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
                local markerTexCoord = {
                    [1] = {0, 0.25, 0, 0.25},
                    [2] = {0.25, 0.5, 0, 0.25},
                    [3] = {0.5, 0.75, 0, 0.25},
                    [4] = {0.75, 1, 0, 0.25},
                    [5] = {0, 0.25, 0.25, 0.5},
                    [6] = {0.25, 0.5, 0.25, 0.5},
                    [7] = {0.5, 0.75, 0.25, 0.5},
                    [8] = {0.75, 1, 0.25, 0.5}
                }
                local texCoord = markerTexCoord[markerIndex] or {0, 0, 0, 0}
                f.healthbar.raidmarker:SetTexture(markerTexture)
                f.healthbar.raidmarker:SetTexCoord(unpack(texCoord))
                f.healthbar.raidmarker:SetAlpha(0.8)
                f.healthbar.raidmarker:Show()
            else
                f.healthbar.raidmarker:Hide()
            end
        end
    end
end

function NotGrid:GetUnitRole(unitid)
    local name = UnitName(unitid)

    if name and self.ManualRoles and self.ManualRoles[name] then
        return self.ManualRoles[name]
    end

    local lfgRole = GetUnitLFGRole(unitid)
    if lfgRole then
        return lfgRole
    end

    return nil
end

function NotGrid:UpdateDungeonRoleIcons()
    local o = self.o
    if not o then return end

    if not o.showdungeonrole then
        for unitid, f in pairs(self.UnitFrames) do
            if f.dungeon_role then f.dungeon_role:Hide() end
        end
        return
    end

    for unitid, f in pairs(self.UnitFrames) do
        if f and f.dungeon_role then
            if UnitExists(unitid) then
                local role = self:GetUnitRole(unitid)
                if role then
                    local coords = ROLE_TEX_COORDS[role]
                    if coords then
                        f.dungeon_role.icon:SetTexCoord(unpack(coords))
                        f.dungeon_role:Show()
                    else
                        f.dungeon_role:Hide()
                    end
                else
                    f.dungeon_role:Hide()
                end
            else
                f.dungeon_role:Hide()
            end
        end
    end
end

function NotGrid:EnableAutohide(frame, timeout)
    if not frame then return end

    frame.hover = frame.hover or CreateFrame("Frame", frame:GetName() .. "Autohide", frame)
    frame.hover:SetParent(frame)
    frame.hover:SetAllPoints(frame)
    frame.hover.parent = frame
    frame.hover:Show()

    local timeout = timeout
    frame.hover:SetScript("OnUpdate", function()
        if MouseIsOver(this, 50, -50, -50, 50) then
            this.activeTo = GetTime() + timeout
            this.parent:SetAlpha(1)
        elseif this.activeTo then
            if this.activeTo < GetTime() and this.parent:GetAlpha() > 0 then
                this.parent:SetAlpha(this.parent:GetAlpha() - 0.1)
            end
        else
            this.activeTo = GetTime() + timeout
        end
    end)
end

function checkRoleCompatibility(role)
    -- 该提示尚未本地化，保留英文
    local ROLE_BAD_TOOLTIP = 'Your class may not be suitable for this role.'
    local _, class = UnitClass("player")
    if not class then return end
    class = string.lower(class)
    if role == 'TANK' and (class == 'priest' or class == 'mage' or class == 'warlock' or class == 'hunter' or class == 'rogue') then
        GameTooltip:AddLine(ROLE_BAD_TOOLTIP, 1, 0, 0);
    end
    if role == 'HEALER' and (class == 'warrior' or class == 'mage' or class == 'warlock' or class == 'hunter' or class == 'rogue') then
        GameTooltip:AddLine(ROLE_BAD_TOOLTIP, 1, 0, 0);
    end
end

-- 创建职责选择窗口
function NotGrid:CreateRoleSelectionWindow()
    local f = CreateFrame("Frame", "NotGridRoleSelectionFrame", UIParent)
    f:SetWidth(300)
    f:SetHeight(200)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -15)
    f.title:SetText(L["Choose Your Role"])

    f.countdown = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.countdown:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.countdown:SetText(string.format(L["Time Remaining: %d sec"], 20))

    f.buttonContainer = CreateFrame("Frame", nil, f)
    f.buttonContainer:SetWidth(250)
    f.buttonContainer:SetHeight(80)
    f.buttonContainer:SetPoint("CENTER", f, "CENTER", 0, 0)

    local roles = {
        {text = L["Tank"], role = "TANK", texCoord = {0, 19/64, 22/64, 41/64}, path = "Interface\\AddOns\\NotGrid\\media\\tank", tooltip = L["Role: Tank."]},
        {text = L["Healer"], role = "HEALER", texCoord = {20/64, 39/64, 1/64, 20/64}, path = "Interface\\AddOns\\NotGrid\\media\\healer", tooltip = L["Role: Healer."]},
        {text = L["Damage"], role = "DAMAGER", texCoord = {20/64, 39/64, 22/64, 41/64}, path = "Interface\\AddOns\\NotGrid\\media\\damage", tooltip = L["Role: Damage."]}
    }

    f.roleButtons = {}
    f.checkButtons = {}

    for i, roleInfo in ipairs(roles) do
        local container = CreateFrame("Frame", nil, f.buttonContainer)
        container:SetWidth(70)
        container:SetHeight(70)
        container:SetPoint("LEFT", f.buttonContainer, "LEFT", (i-1)*80 + 5, 0)

        local btn = CreateFrame("Button", nil, container)
        btn:SetWidth(60)
        btn:SetHeight(60)
        btn:SetPoint("CENTER", container, "CENTER", 0, 0)
        btn:SetID(i)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetTexture(roleInfo.path)
        btn.icon:SetAllPoints()

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("BOTTOM", btn, "BOTTOM", 0, -15)
        btn.text:SetText(roleInfo.text)

        btn:SetScript("OnEnter", function()
            if f.selectedRole ~= this:GetID() then
                GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
                GameTooltip:SetText(roles[this:GetID()].tooltip)
                checkRoleCompatibility(roles[this:GetID()].role)
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", function()
            if f.selectedRole ~= this:GetID() then
                GameTooltip:Hide()
            end
        end)

        btn:SetScript("OnClick", function()
            container:SelectRole(this:GetID())
        end)

        local checkBtn = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        checkBtn:SetWidth(20)
        checkBtn:SetHeight(20)
        checkBtn:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
        checkBtn:SetID(i)
        checkBtn:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkBtn:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        checkBtn:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        checkBtn:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checkBtn:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")

        checkBtn:SetScript("OnClick", function()
            container:SelectRole(this:GetID())
        end)

        container.SelectRole = function(self, roleIndex)
            f:SelectRole(roleIndex)
        end

        btn.roleIndex = i
        checkBtn.roleIndex = i
        container.roleIndex = i

        f.roleButtons[i] = btn
        f.checkButtons[i] = checkBtn
    end

    f.confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.confirmBtn:SetWidth(80)
    f.confirmBtn:SetHeight(25)
    f.confirmBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    f.confirmBtn:SetText(L["Confirm"])
    f.confirmBtn:SetScript("OnClick", function()
        f:ConfirmSelection()
    end)

    f.cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.cancelBtn:SetWidth(80)
    f.cancelBtn:SetHeight(25)
    f.cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    f.cancelBtn:SetText(L["Cancel"])
    f.cancelBtn:SetScript("OnClick", function()
        f:CancelSelection()
    end)

    f.SelectRole = function(self, index)
        f.selectedRole = index

        for i, checkBtn in ipairs(f.checkButtons) do
            if i == index then
                checkBtn:SetChecked(true)
            else
                checkBtn:SetChecked(false)
            end
        end
    end

    f.ConfirmSelection = function(self)
        if self.selectedRole then
            local playerName = UnitName("player")
            local roles = {"TANK", "HEALER", "DAMAGER"}
            local selectedRole = roles[self.selectedRole]

            local message = "ROLE:" .. playerName .. ":" .. selectedRole

            if GetNumRaidMembers() > 0 then
                SendAddonMessage("NotGrid", message, "RAID")
            elseif GetNumPartyMembers() > 0 then
                SendAddonMessage("NotGrid", message, "PARTY")
            end

            NotGrid.ManualRoles[playerName] = selectedRole
            NotGrid.o.manualroles[playerName] = selectedRole
            NotGrid:UpdateDungeonRoleIcons()
        end
        self:Hide()
        NotGrid:CancelScheduledEvent("RoleSelectionCountdown")
    end

    f.CancelSelection = function(self)
        self:Hide()
        NotGrid:CancelScheduledEvent("RoleSelectionCountdown")
    end

    f.ShowWithCountdown = function(self)
        self:Show()
        self.timeLeft = 20
        local playerName = UnitName("player")
        local _, class = UnitClass("player")

        local available = {}
        if class == "WARRIOR" then
            available.TANK = true
            available.DAMAGER = true
        elseif class == "PRIEST" then
            available.HEALER = true
            available.DAMAGER = true
        elseif class == "DRUID" then
            available.TANK = true
            available.HEALER = true
            available.DAMAGER = true
        elseif class == "PALADIN" then
            available.TANK = true
            available.HEALER = true
            available.DAMAGER = true
        elseif class == "SHAMAN" then
            available.HEALER = true
            available.DAMAGER = true
        elseif class == "MAGE" or class == "WARLOCK" or class == "ROGUE" or class == "HUNTER" then
            available.DAMAGER = true
        else
            available.DAMAGER = true
        end

        local roles = {"TANK", "HEALER", "DAMAGER"}
        local idxAvailable = {}
        for i, r in ipairs(roles) do idxAvailable[i] = available[r] end

        local currRole = NotGrid.ManualRoles[playerName]
        if currRole and not available[currRole] then
            NotGrid.ManualRoles[playerName] = nil
            NotGrid.o.manualroles[playerName] = nil
            local nilMsg = "ROLE:" .. playerName .. ":nil"
            if GetNumRaidMembers() > 0 then
                SendAddonMessage("NotGrid", nilMsg, "RAID")
            elseif GetNumPartyMembers() > 0 then
                SendAddonMessage("NotGrid", nilMsg, "PARTY")
            end
            NotGrid:UpdateDungeonRoleIcons()
        end

        self.selectedRole = nil
        for i = 1, 3 do
            local btn   = self.roleButtons[i]
            local check = self.checkButtons[i]
            if idxAvailable[i] then
                btn.icon:SetVertexColor(1, 1, 1)
                btn:EnableMouse(true)
                btn:Enable()
                check:Enable()
                check:SetAlpha(1)
            else
                btn.icon:SetVertexColor(0.35, 0.35, 0.35)
                btn:Disable()
                check:Disable()
                check:SetAlpha(0.4)
                check:SetChecked(false)
            end
            check:SetChecked(false)
        end

        NotGrid:CancelScheduledEvent("RoleSelectionCountdown")
        self.countdown:SetText(string.format(L["Time Remaining: %d sec"], 20))
        NotGrid:ScheduleRepeatingEvent("RoleSelectionCountdown", function()
            self.timeLeft = self.timeLeft - 1
            if self.timeLeft > 0 then
                self.countdown:SetText(string.format(L["Time Remaining: %d sec"], self.timeLeft))
            else
                self:CancelSelection()
            end
        end, 1)
    end

    f:Hide()
    return f
end

--------------------------------------------------
-- 设置职责
--------------------------------------------------
function NotGrid:SyncRoleToRaid(name, role)
    local message = "ROLE:" .. name .. ":" .. role
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("NotGrid", message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage("NotGrid", message, "PARTY")
    end
end

--------------------------------------------------
-- 清除所有手动职责
--------------------------------------------------
function NotGrid:ClearAllManualRoles()
    self.ManualRoles = {}
    if self.o and self.o.manualroles then
        self.o.manualroles = {}
    end
    self:UpdateDungeonRoleIcons()
end

--------------------------------------------------
-- 离队触发
--------------------------------------------------
function NotGrid:HandlePartyChange()
    local wasInParty = self.wasInParty or false
    local isInParty  = (GetNumPartyMembers()>0) or (GetNumRaidMembers()>0)

    if wasInParty and not isInParty then
        self:ClearAllManualRoles()
    elseif not wasInParty and isInParty then
        self:ScheduleEvent("ShowRoleSelection", function()
            if self.o.showdungeonrole then
                if not NotGridRoleSelectionFrame then
                    self:CreateRoleSelectionWindow()
                end
                NotGridRoleSelectionFrame:ShowWithCountdown()
            end
        end, 1)
    end
    self.wasInParty = isInParty
end