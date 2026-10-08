-- MPowa智能战斗助手模块
local MPowa = _G.MPowa
if not MPowa then return end

local CombatAssistant = {
    -- 配置参数
    config = {
        maxTargets = 5,          -- 最大监控目标数
        targetRange = 40,        -- 目标监控范围
        updateInterval = 0.2,    -- 更新间隔
        iconSize = 60,           -- 图标大小
        basePos = {x=0, y=-200}  -- 基础位置（屏幕中下）
    },
    
    -- 运行时数据
    targets = {},             -- 监控目标列表
    skillQueue = {},          -- 技能优先级队列
    lastUpdate = 0,           -- 上次更新时间
    frames = {}               -- 显示框架
}

-- 初始化战斗助手
function CombatAssistant:Init()
    self:CreateDisplayFrames()
    MPowa:RegisterUpdateFunc(function(elapsed) self:OnUpdate(elapsed) end)
    self:RegisterEvents()
    print("|cff00ff00MPowa战斗助手已加载|r - 自动监控目标并提示最优技能")
end

-- 创建显示框架
function CombatAssistant:CreateDisplayFrames()
    -- 创建主框架
    self.mainFrame = CreateFrame("Frame", "MPowa_CombatAssistant", UIParent)
    self.mainFrame:SetSize(self.config.iconSize * self.config.maxTargets, self.config.iconSize)
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", self.config.basePos.x, self.config.basePos.y)
    
    -- 创建目标图标框架
    for i = 1, self.config.maxTargets do
        local frame = CreateFrame("Frame", "MPowa_TargetFrame"..i, self.mainFrame)
        frame:SetSize(self.config.iconSize, self.config.iconSize)
        frame:SetPoint("LEFT", (i-1)*self.config.iconSize, 0)
        
        -- 目标头像
        frame.portrait = frame:CreateTexture(nil, "BACKGROUND")
        frame.portrait:SetAllPoints(frame)
        frame.portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        
        -- 生命值条
        frame.healthBar = CreateFrame("StatusBar", nil, frame)
        frame.healthBar:SetHeight(5)
        frame.healthBar:SetPoint("BOTTOMLEFT", 0, 0)
        frame.healthBar:SetPoint("BOTTOMRIGHT", 0, 0)
        frame.healthBar:SetStatusBarTexture("Interface\\AddOns\\MPowa\\Textures\\bar")
        frame.healthBar:SetStatusBarColor(0, 1, 0)
        
        -- 技能提示图标
        frame.skillIcon = frame:CreateTexture(nil, "OVERLAY")
        frame.skillIcon:SetSize(self.config.iconSize/2, self.config.iconSize/2)
        frame.skillIcon:SetPoint("TOPRIGHT", 0, 0)
        
        -- 闪烁动画
        frame.anim = frame:CreateAnimationGroup()
        local fade = frame.anim:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0.5)
        fade:SetDuration(0.3)
        fade:SetSmoothing("IN_OUT")
        fade:SetLooping("BOUNCE")
        
        frame:Hide()
        table.insert(self.frames, frame)
    end
end

-- 注册事件
function CombatAssistant:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- 脱离战斗
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- 进入战斗
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:StartCombat()
        else
            self:EndCombat()
        end
    end)
end

-- 开始战斗监控
function CombatAssistant:StartCombat()
    self.mainFrame:Show()
    self:UpdateTargets()
end

-- 结束战斗监控
function CombatAssistant:EndCombat()
    self.targets = {}
    self.skillQueue = {}
    for _, frame in ipairs(self.frames) do
        frame:Hide()
    end
end

-- 更新目标列表
function CombatAssistant:UpdateTargets()
    local newTargets = {}
    
    -- 扫描范围内的敌对目标
    for i = 1, 40 do  -- 最多扫描40个目标
        local unit = "nameplate"..i  -- 使用姓名板单位
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local distance = sqrt((GetPlayerMapPosition("player") - GetPlayerMapPosition(unit))^2) or 0
            if distance <= self.config.targetRange then
                table.insert(newTargets, {
                    unit = unit,
                    name = UnitName(unit),
                    health = UnitHealth(unit),
                    maxHealth = UnitHealthMax(unit),
                    distance = distance,
                    debuffs = self:GetUnitDebuffs(unit)
                })
            end
        end
    end
    
    -- 按优先级排序（血量低 > 距离近）
    table.sort(newTargets, function(a, b)
        if a.health/a.maxHealth ~= b.health/b.maxHealth then
            return a.health/a.maxHealth < b.health/b.maxHealth
        end
        return a.distance < b.distance
    end)
    
    -- 截取前N个目标
    self.targets = {}
    for i = 1, math.min(table.getn(newTargets), self.config.maxTargets) do
        self.targets[i] = newTargets[i]
    end
end

-- 获取单位身上的debuff
function CombatAssistant:GetUnitDebuffs(unit)
    local debuffs = {}
    for i = 1, 16 do
        local name, _, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if name then
            debuffs[name] = {
                duration = duration,
                expiration = expirationTime
            }
        end
    end
    return debuffs
end

-- 计算最优技能
function CombatAssistant_CalculateBestSkill(target)
    -- 假设这是乌龟服中惩戒骑士的技能列表
    local skills = {
        {name = "神圣打击", priority = 5, range = 5, cd = GetSpellCooldown(1)},
        {name = "愤怒之锤", priority = 4, range = 30, cd = GetSpellCooldown(2)},
        {name = "正义壁垒", priority = 6, range = 0, cd = GetSpellCooldown(3),
         condition = function() return UnitHealth("player") < UnitHealthMax("player") * 0.5 end} -- 当生命值低于50%时使用
    }

    -- 筛选可用技能
    local available = {}
    for _, skill in ipairs(skills) do
        local inRange = IsSpellInRange(skill.name, target.unit) == 1 or skill.range == 0
        local offCD = skill.cd == 0
        local conditionMet = not skill.condition or skill.condition()

        if inRange and offCD and conditionMet then
            table.insert(available, skill)
        end
    end

    -- 返回最高优先级技能
    if table.getn(available) > 0 then
        table.sort(available, function(a, b) return a.priority > b.priority end)
        return available[1]
    end
    return nil
end



-- 更新显示
function CombatAssistant:UpdateDisplay()
    -- 隐藏所有框架
    for _, frame in ipairs(self.frames) do
        frame:Hide()
    end
    
    -- 更新目标显示
    for i, target in ipairs(self.targets) do
        local frame = self.frames[i]
        if frame then
            -- 更新头像
            SetPortraitTexture(frame.portrait, target.unit)
            
            -- 更新血条
            frame.healthBar:SetMinMaxValues(0, target.maxHealth)
            frame.healthBar:SetValue(target.health)
            
            -- 更新技能提示
            local bestSkill = CombatAssistant_CalculateBestSkill(target)
            if bestSkill then
                local _, _, icon = GetSpellInfo(bestSkill.name)
                frame.skillIcon:SetTexture(icon)
                
                -- 高优先级技能闪烁提示
                if bestSkill.priority >= 6 then
                    frame.anim:Play()
                else
                    frame.anim:Stop()
                    frame.skillIcon:SetAlpha(1)
                end
            else
                frame.skillIcon:SetTexture(nil)
                frame.anim:Stop()
            end
            
            frame:Show()
        end
    end
end

-- 主更新循环
function CombatAssistant:OnUpdate(elapsed)
    self.lastUpdate = self.lastUpdate + elapsed
    if self.lastUpdate >= self.config.updateInterval then
        self.lastUpdate = 0
        
        -- 战斗中才更新
        if UnitAffectingCombat("player") then
            self:UpdateTargets()
            self:UpdateDisplay()
        end
    end
end

-- 添加到MPowa插件
MPowa.CombatAssistant = CombatAssistant

-- 注册加载事件
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
    MPowa.CombatAssistant:Init()
    loadFrame:UnregisterAllEvents()
end)
    