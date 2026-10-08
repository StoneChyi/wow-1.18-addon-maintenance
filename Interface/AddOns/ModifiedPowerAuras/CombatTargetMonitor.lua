-- 战斗敌对目标监控模块 - 适配ModifiedPowerAuras插件
local MA = _G.ModifiedPowerAuras
if not MA then return end

local CombatTargetMonitor = {
    -- 配置参数
    config = {
        maxTargets = 8,             -- 最大监控目标数
        scanRange = 40,             -- 扫描范围（码）
        updateInterval = 0.5,       -- 更新间隔（秒）
        iconSize = 40,              -- 技能图标大小
        targetFrameWidth = 120,     -- 目标框架宽度
        position = {x = -300, y = 0} -- 显示位置（屏幕中心偏左）
    },
    
    -- 运行时数据
    activeTargets = {},          -- 活跃目标列表
    targetFrames = {},           -- 目标显示框架
    lastUpdate = 0,              -- 上次更新时间
    spellDB = {},                -- 技能数据库
    mainFrame = nil              -- 主框架
}

-- 初始化模块
function CombatTargetMonitor:Init()
    self:BuildSpellDatabase()
    self:CreateMainFrame()
    self:RegisterEvents()
    MA:RegisterUpdateFunc(function(elapsed) self:OnUpdate(elapsed) end)
    MA:Print("|cff00ff00战斗目标监控模块已加载|r - 监控40码内敌对目标技能CD")
end

-- 构建技能数据库（各职业关键技能）
function CombatTargetMonitor:BuildSpellDatabase()
    -- 格式: [技能ID] = {name = "技能名", priority = 优先级, icon = "图标路径"}
    self.spellDB = {
        -- 战士
        [12292] = {name = "破胆怒吼", priority = 9, icon = "Interface\\Icons\\Ability_Warrior_IntimidatingShout"},
        [1719] = {name = "拦截", priority = 8, icon = "Interface\\Icons\\Ability_Warrior_Charge"},
        [18499] = {name = "狂暴之怒", priority = 7, icon = "Interface\\Icons\\Ability_Warrior_BerserkerRage"},
        
        -- 法师
        [45438] = {name = "寒冰屏障", priority = 10, icon = "Interface\\Icons\\Spell_Frost_FrostWard"},
        [122] = {name = "冰霜新星", priority = 9, icon = "Interface\\Icons\\Spell_Frost_FrostNova"},
        [11426] = {name = "冰锥术", priority = 8, icon = "Interface\\Icons\\Spell_Frost_FrostBolt02"},
        
        -- 牧师
        [10890] = {name = "心灵控制", priority = 10, icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate"},
        [528] = {name = "驱散魔法", priority = 7, icon = "Interface\\Icons\\Spell_Holy_DispelMagic"},
        [6346] = {name = "恐惧术", priority = 9, icon = "Interface\\Icons\\Spell_Shadow_PsychicScream"},
        
        -- 盗贼
        [2983] = {name = "消失", priority = 10, icon = "Interface\\Icons\\Ability_Stealth"},
        [1856] = {name = "凿击", priority = 8, icon = "Interface\\Icons\\Ability_BackStab"},
        [1766] = {name = "肾击", priority = 9, icon = "Interface\\Icons\\Ability_Kick"},
        
        -- 猎人
        [34490] = {name = "威慑", priority = 9, icon = "Interface\\Icons\\Ability_Hunter_Evade"},
        [14311] = {name = "冰冻陷阱", priority = 8, icon = "Interface\\Icons\\Ability_Hunter_FreezingTrap"},
        
        -- 德鲁伊
        [22812] = {name = "树皮术", priority = 8, icon = "Interface\\Icons\\Spell_Nature_Barkskin"},
        [5211] = {name = "纠缠根须", priority = 9, icon = "Interface\\Icons\\Spell_Nature_EntanglingRoots"},
        
        -- 圣骑士
        [642] = {name = "复仇之怒", priority = 8, icon = "Interface\\Icons\\Spell_Holy_BlessingOfMight"},
        [1022] = {name = "保护祝福", priority = 10, icon = "Interface\\Icons\\Spell_Holy_SealOfProtection"},
        
        -- 萨满
        [8177] = {name = "根基图腾", priority = 9, icon = "Interface\\Icons\\Spell_Nature_GroundingTotem"},
        [16166] = {name = "风怒图腾", priority = 7, icon = "Interface\\Icons\\Spell_Nature_Windfury"},
        
        -- 术士
        [710] = {name = "放逐术", priority = 9, icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges"},
        [6215] = {name = "恐惧嚎叫", priority = 8, icon = "Interface\\Icons\\Spell_Shadow_HowlOfTerror"}
    }
end

-- 创建主框架
function CombatTargetMonitor:CreateMainFrame()
    self.mainFrame = CreateFrame("Frame", "MA_CombatMonitor", UIParent)
    self.mainFrame:SetSize(self.config.targetFrameWidth, self.config.iconSize * self.config.maxTargets)
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", self.config.position.x, self.config.position.y)
    self.mainFrame:Hide()
    
    -- 创建目标框架
    for i = 1, self.config.maxTargets do
        local frame = self:CreateTargetFrame(i)
        table.insert(self.targetFrames, frame)
    end
end

-- 创建单个目标框架
function CombatTargetMonitor:CreateTargetFrame(index)
    local frame = CreateFrame("Frame", "MA_TargetFrame"..index, self.mainFrame)
    frame:SetSize(self.config.targetFrameWidth, self.config.iconSize)
    frame:SetPoint("TOP", 0, -(index-1)*self.config.iconSize)
    frame:Hide()
    
    -- 背景
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- 目标姓名
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.nameText:SetPoint("LEFT", 5, 0)
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:SetTextColor(1, 0.1, 0.1)  -- 敌对目标红色
    
    -- 职业图标
    frame.classIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.classIcon:SetSize(self.config.iconSize*0.8, self.config.iconSize*0.8)
    frame.classIcon:SetPoint("RIGHT", -5, 0)
    
    -- 技能图标槽位（每个目标显示3个关键技能）
    frame.spellIcons = {}
    for i = 1, 3 do
        local iconFrame = CreateFrame("Frame", nil, frame)
        iconFrame:SetSize(self.config.iconSize, self.config.iconSize)
        iconFrame:SetPoint("RIGHT", frame.classIcon, "LEFT", -(i-1)*(self.config.iconSize + 5), 0)
        
        -- 技能图标
        iconFrame.texture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconFrame.texture:SetAllPoints(iconFrame)
        
        -- CD遮罩
        iconFrame.cooldown = iconFrame:CreateTexture(nil, "OVERLAY")
        iconFrame.cooldown:SetColorTexture(0, 0, 0, 0.7)
        iconFrame.cooldown:SetPoint("TOPLEFT")
        iconFrame.cooldown:SetPoint("TOPRIGHT")
        iconFrame.cooldown:SetPoint("BOTTOMLEFT")
        
        -- 倒计时文本
        iconFrame.text = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        iconFrame.text:SetAllPoints(iconFrame)
        iconFrame.text:SetTextColor(1, 1, 1)
        
        iconFrame:Hide()
        table.insert(frame.spellIcons, iconFrame)
    end
    
    return frame
end

-- 注册事件
function CombatTargetMonitor:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- 脱离战斗
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- 进入战斗
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- 战斗日志事件
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            self.mainFrame:Show()
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.mainFrame:Hide()
            self.activeTargets = {}
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self:ProcessCombatLog(...)
        end
    end)
end

-- 处理战斗日志事件（检测技能使用）
function CombatTargetMonitor:ProcessCombatLog(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID = ...
    local spellId = select(12, ...)
    
    -- 只关注敌对目标使用的技能
    if eventType == "SPELL_CAST_SUCCESS" and self:IsHostile(sourceGUID) then
        local spellInfo = self.spellDB[spellId]
        if spellInfo then
            -- 获取技能CD（实际应从数据库获取，这里简化为固定值）
            local cdDuration = self:GetSpellCDDuration(spellId)
            if cdDuration then
                self:UpdateSpellCD(sourceGUID, spellId, cdDuration)
            end
        end
    end
end

-- 扫描更新目标列表
function CombatTargetMonitor:ScanTargets()
    local newTargets = {}
    
    -- 扫描姓名板目标
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
            -- 计算距离
            local distance = self:GetDistanceToUnit(unit)
            if distance and distance <= self.config.scanRange then
                table.insert(newTargets, {
                    guid = UnitGUID(unit),
                    name = UnitName(unit),
                    class = self:GetUnitClass(unit),
                    distance = distance,
                    spells = self.activeTargets[UnitGUID(unit)] and self.activeTargets[UnitGUID(unit)].spells or {}
                })
            end
        end
    end
    
    -- 按距离排序（最近的在前）
    table.sort(newTargets, function(a, b) return a.distance < b.distance end)
    
    -- 截取前N个目标
    self.activeTargets = {}
    for i = 1, math.min(table.getn(newTargets), self.config.maxTargets) do
        self.activeTargets[newTargets[i].guid] = newTargets[i]
    end
end

-- 更新技能CD
function CombatTargetMonitor:UpdateSpellCD(guid, spellId, duration)
    if not self.activeTargets[guid] then return end
    
    local endTime = GetTime() + duration
    self.activeTargets[guid].spells[spellId] = {
        endTime = endTime,
        duration = duration,
        info = self.spellDB[spellId]
    }
end

-- 更新显示
function CombatTargetMonitor:UpdateDisplay()
    -- 隐藏所有框架
    for _, frame in ipairs(self.targetFrames) do
        frame:Hide()
        for _, icon in ipairs(frame.spellIcons) do
            icon:Hide()
        end
    end
    
    -- 转换为数组并排序
    local targets = {}
    for _, target in pairs(self.activeTargets) do
        table.insert(targets, target)
    end
    table.sort(targets, function(a, b) return a.distance < b.distance end)
    
    -- 更新每个目标框架
    for i, target in ipairs(targets) do
        if i > self.config.maxTargets then break end
        
        local frame = self.targetFrames[i]
        frame.nameText:SetText(target.name)
        
        -- 设置职业图标
        local classIcon = self:GetClassIcon(target.class)
        if classIcon then
            frame.classIcon:SetTexture(classIcon)
        end
        
        -- 整理并排序技能（按优先级和剩余时间）
        local activeSpells = {}
        for spellId, data in pairs(target.spells) do
            local remaining = data.endTime - GetTime()
            if remaining > 0 then
                table.insert(activeSpells, {
                    id = spellId,
                    remaining = remaining,
                    duration = data.duration,
                    info = data.info
                })
            end
        end
        
        -- 按优先级排序，高优先级在前
        table.sort(activeSpells, function(a, b) 
            if a.info.priority ~= b.info.priority then
                return a.info.priority > b.info.priority
            end
            return a.remaining < b.remaining
        end)
        
        -- 更新技能图标
        for j, spell in ipairs(activeSpells) do
            if j > 3 then break end  -- 只显示前3个技能
            
            local iconFrame = frame.spellIcons[j]
            iconFrame.texture:SetTexture(spell.info.icon)
            
            -- 更新CD遮罩
            local progress = spell.remaining / spell.duration
            iconFrame.cooldown:SetHeight(iconFrame:GetHeight() * progress)
            
            -- 更新倒计时文本
            iconFrame.text:SetText(math.floor(spell.remaining) .. "s")
            
            iconFrame:Show()
        end
        
        frame:Show()
    end
end

-- 主更新循环
function CombatTargetMonitor:OnUpdate(elapsed)
    self.lastUpdate = self.lastUpdate + elapsed
    if self.lastUpdate >= self.config.updateInterval then
        self.lastUpdate = 0
        
        -- 战斗中才更新
        if UnitAffectingCombat("player") then
            self:ScanTargets()
            self:UpdateDisplay()
        end
    end
end

-- 辅助函数：获取单位距离
function CombatTargetMonitor:GetDistanceToUnit(unit)
    if not UnitExists(unit) then return nil end
    return select(2, UnitDistanceSq(unit)) and sqrt(UnitDistanceSq(unit)) or nil
end

-- 辅助函数：判断是否为敌对目标
function CombatTargetMonitor:IsHostile(guid)
    for _, target in pairs(self.activeTargets) do
        if target.guid == guid then
            return true
        end
    end
    return false
end

-- 辅助函数：获取单位职业
function CombatTargetMonitor:GetUnitClass(unit)
    local classToken = select(2, UnitClass(unit))
    return classToken
end

-- 辅助函数：获取职业图标
function CombatTargetMonitor:GetClassIcon(classToken)
    if not classToken then return nil end
    return "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
end

-- 辅助函数：获取技能CD时长（简化版，实际应从数据库获取）
function CombatTargetMonitor:GetSpellCDDuration(spellId)
    -- 实际应用中应根据技能ID和天赋返回准确CD
    local cdMap = {
        [45438] = 300,  -- 寒冰屏障
        [2983] = 120,   -- 消失
        [1022] = 300,   -- 保护祝福
        [10890] = 300,  -- 心灵控制
        [642] = 180     -- 复仇之怒
    }
    -- 未指定的技能默认30秒CD
    return cdMap[spellId] or 30
end

-- 注册到ModifiedPowerAuras插件
MA.CombatTargetMonitor = CombatTargetMonitor
MA:RegisterLoadFunc(function() CombatTargetMonitor:Init() end)
    