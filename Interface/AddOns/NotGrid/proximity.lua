-- proximity.lua
local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

-- 检查 UnitXP 是否可用（自定义距离/视线API）
local hasUnitXP = pcall(UnitXP, "nop", "nop")

-- 各职业拥有的 40 码法术图标（用于距离判定）
local spells40yd = {
    ["PALADIN"] = {"Interface\\Icons\\Spell_Holy_FlashHeal", "Interface\\Icons\\Spell_Holy_HolyBolt"},
    ["PRIEST"] = {"Interface\\Icons\\Spell_Holy_FlashHeal", "Interface\\Icons\\Spell_Holy_LesserHeal", "Interface\\Icons\\Spell_Holy_Heal", "Interface\\Icons\\Spell_Holy_GreaterHeal", "Interface\\Icons\\Spell_Holy_Renew"},
    ["DRUID"] = {"Interface\\Icons\\Spell_Nature_HealingTouch", "Interface\\Icons\\Spell_Nature_ResistNature", "Interface\\Icons\\Spell_Nature_Rejuvenation"},
    ["SHAMAN"] = {"Interface\\Icons\\Spell_Nature_MagicImmunity", "Interface\\Icons\\Spell_Nature_HealingWaveLesser", "Interface\\Icons\\Spell_Nature_HealingWaveGreater"},
}

--------------------
-- UNIT_PROXIMITY --
--------------------
-- 周期性距离检查事件
function NotGrid:UNIT_PROXIMITY()
    for key,f in self.UnitFrames do
        local unitid = f.unit
        if UnitExists(unitid) and f:IsVisible() then
            local response = self:CheckProximity(unitid)
            if response == 1 then
                self:RangeToggle(f, 1)   -- 在范围内
            elseif response == 2 then
                self:RangeToggle(f, 2)   -- 超出范围但可见
            else
                self:RangeToggle(f, 3)   -- 其他情况
            end
        end
    end
end

----------------------------
-- 根据距离状态更新透明度
----------------------------
function NotGrid:RangeToggle(f, condition)
    if condition == 1 then
        f.lastseen = GetTime()
        f:SetAlpha(1)                -- 正常显示
    elseif condition == 2 then
        f:SetAlpha(self.o.ooralpha)  -- 超出范围半透明
    elseif (f.lastseen and (GetTime() - f.lastseen) > self.o.proximityleeway) then
        f:SetAlpha(self.o.ooralpha)  -- 超出宽容时间后半透明
    end
end

----------------
-- 距离主检测 --
----------------
function NotGrid:CheckProximity(unitid)
    if not UnitExists(unitid) then return end

    -- 优先使用 UnitXP（如果可用）
    if hasUnitXP then
        local dist = UnitXP("distanceBetween", "player", unitid)
        if dist then
            if dist < 40 then
                if self.o.requireSight then
                    local inSight = UnitXP("inSight", "player", unitid)
                    if inSight == true then
                        return 1            -- 在范围内且可见
                    elseif inSight == false then
                        return 2            -- 范围内但不可见
                    end
                    -- 如果 inSight 返回 nil，也视为在范围内
                    return 1
                else
                    return 1                -- 不需要视线检测，直接返回在范围内
                end
            else
                return 2                    -- 距离 >= 40
            end
        end
        -- 如果 UnitXP 查询失败，继续执行下面的旧方案
    end

    -- 旧方案（无 UnitXP 或 UnitXP 查询失败时的回退）
    if UnitIsVisible(unitid) then
        if UnitIsUnit(unitid, "player") then
            return 1
        elseif CheckInteractDistance(unitid, 3) then   -- 28码（交易距离）
            return 1
        elseif CheckInteractDistance(unitid, 2) then   -- 更短的交互距离
            return 1
        elseif CheckInteractDistance(unitid, 4) then   -- 28码
            return 1
        elseif SpellIsTargeting() then
            if SpellCanTargetUnit(unitid) then
                return 1
            else
                return 2
            end
        elseif UnitIsUnit(unitid, "target") and self.ProximityVars.spell40slot then
            if IsActionInRange(self.ProximityVars.spell40slot) == 1 then
                return 1
            else
                return 2
            end
        end
        -- 使用地图坐标计算距离（如果开启了地图距离并地图未打开）
        if self.o.usemapdistances and self.ProximityVars.mapFileName and not WorldMapFrame:IsVisible() then
            local distance = self:GetWorldDistance(unitid)
            if distance then
                if distance <= 40 then
                    return 1
                else
                    return 2
                end
            end
        end
    end

    -- 所有方法都无法判断，返回 nil
end

-------------------------
-- 地图距离计算
-------------------------
function NotGrid:GetWorldDistance(unitid)
    local px, py, ux, uy, distance
    local v = self.ProximityVars
    px, py = GetPlayerMapPosition("player")
    ux, uy = GetPlayerMapPosition(unitid)
    if v.mapFileName and v.MapSizes[v.mapFileName] and px ~= 0 and ux ~= 0 then
        local xdelta = (px - ux)*v.MapSizes[v.mapFileName].x
        local ydelta = (py - uy)*v.MapSizes[v.mapFileName].y
        distance = sqrt(xdelta^2 + ydelta^2)*(40/42.9)  -- 修正系数
    end
    return distance
end

-------------------------
-- 更新当前区域地图信息
-------------------------
function NotGrid:UpdateProximityMapVars()
    SetMapToCurrentZone()
    self.ProximityVars.mapFileName, _, _ = GetMapInfo()
end

-------------------------
-- 战斗事件处理（获得/失去buff等）
-------------------------
function NotGrid:CombatEventHandle()
    local combatlogrange = tonumber(GetCVar("CombatLogRangeFriendlyPlayers"))
    if combatlogrange <= 40 then
        local v = self.ProximityVars
        local capturestring = L.CombatEvents[event]
        local _, _, name = string.find(arg1, capturestring)
        for _,f in self.UnitFrames do
            if (name and f.name) and (name == f.name) then
                self:RangeToggle(f, 1)  -- 确认在范围内
            end
        end
    end
end

-------------------------
-- 查找玩家的40码法术槽位
-------------------------
function NotGrid:GetFortyYardSpell()
    local v = self.ProximityVars
    local _, class = UnitClass("player")
    if spells40yd[class] then
        local textures = spells40yd[class]
        local indices = getn(spells40yd[class])
        for i = 1, 120 do
            local ActionTexture = GetActionTexture(i)
            for j=1,indices do
                if ActionTexture == textures[j] and not GetActionText(i) then
                    v.spell40slot = i
                    return
                end
            end
        end
    end
    v.spell40slot = nil
end

---------------------
--  Clique 辅助函数 --
---------------------
function NotGrid:SpellCanTarget()
    for _,f in self.UnitFrames do
        local unitid = f.unit
        if UnitExists(unitid) and UnitIsVisible(unitid) and SpellIsTargeting() then
            if SpellCanTargetUnit(unitid) then
                self:RangeToggle(f, 1)
            else
                self:RangeToggle(f, 2)
            end
        end
    end
end