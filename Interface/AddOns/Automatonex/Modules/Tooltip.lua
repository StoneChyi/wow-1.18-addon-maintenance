assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Tooltip = Automaton:NewModule("Tooltip")
Automaton_Tooltip.modulename = "鼠标提示增强"
Automaton_Tooltip.moduledesc = "鼠标提示增强功能"
Automaton_Tooltip.options = {
    header1 = {
        type = "header",
        name = "物品信息",
        order = 10,
    },
    showitemid = {
        type = 'toggle',
        name = "显示物品ID",
        desc = "显示物品ID",
        order = 11,
        get = function() return Automaton_Tooltip.db.profile.showitemid end,
        set = function(v) Automaton_Tooltip.db.profile.showitemid = v end,
    },
    header2 = {
        type = "header",
        name = "目标信息",
        order = 20,
    },
    showResistance = {
        type = "toggle",
        name = "目标护甲和抗性",
        desc = "鼠标提示显示目标的护甲和抗性",
        order = 21,
        get = function() return Automaton_Tooltip.db.profile.showResistance end,
        set = function(v) Automaton_Tooltip.db.profile.showResistance = v end,
    },
    showDamageAndSpeed = {
        type = "toggle",
        name = "目标伤害和攻速",
        desc = "鼠标提示显示目标的伤害范围和攻击速度",
        order = 22,
        get = function() return Automaton_Tooltip.db.profile.showDamageAndSpeed end,
        set = function(v) Automaton_Tooltip.db.profile.showDamageAndSpeed = v end,
    },
    showgather = {
        type = "toggle",
        name = "采集等级",
        desc = "在鼠标放到矿或草药上时，鼠标提示中显示采集需要的技能等级。",
        order = 12,
        get = function() return Automaton_Tooltip.db.profile.showgather end,
        set = function(v) Automaton_Tooltip.db.profile.showgather = v end,
    },
    showReputation = {  
        type = "toggle",
        name = "显示目标声望",
        desc = "鼠标提示显示目标的声望信息",
        order = 23,
        get = function() return Automaton_Tooltip.db.profile.showReputation end,
        set = function(v) Automaton_Tooltip.db.profile.showReputation = v end,
    },
    showWishInfo = {  
        type = "toggle",
        name = "显示玩家许愿信息",
        desc = "鼠标提示显示目标玩家的许愿物品及分数",
        order = 24,
        get = function() return Automaton_Tooltip.db.profile.showWishInfo end,
        set = function(v) Automaton_Tooltip.db.profile.showWishInfo = v end,
    },
    showImpression = {  
        type = "toggle",
        name = "显示玩家印象",
        desc = "鼠标提示显示目标玩家的印象信息",
        order = 25,
        get = function() return Automaton_Tooltip.db.profile.showImpression end,
        set = function(v) Automaton_Tooltip.db.profile.showImpression = v end,
    },
    showspellid = {
        type = 'toggle',
        name = "显示法术ID",
        desc = "在法术、BUFF、DEBUFF提示中显示法术ID（需要superwow）",
        order = 13,
        get = function() return Automaton_Tooltip.db.profile.showspellid end,
        set = function(v) Automaton_Tooltip.db.profile.showspellid = v end,
    },
    headerpet = {
        type = "header",
        name = "宠物信息（自己的宠物）",
        order = 26,
    },
    showPetHappiness = {
        type = "toggle",
        name = "宠物快乐度",
        desc = "鼠标提示显示自己宠物的快乐度（不高兴/满足/快乐 及对应伤害加成）",
        order = 27,
        get = function() return Automaton_Tooltip.db.profile.showPetHappiness end,
        set = function(v) Automaton_Tooltip.db.profile.showPetHappiness = v end,
    },
    showPetFood = {
        type = "toggle",
        name = "宠物食物需求",
        desc = "鼠标提示显示自己宠物能吃的食物类型",
        order = 28,
        get = function() return Automaton_Tooltip.db.profile.showPetFood end,
        set = function(v) Automaton_Tooltip.db.profile.showPetFood = v end,
    },
    showPetExp = {
        type = "toggle",
        name = "宠物经验",
        desc = "鼠标提示显示自己宠物的当前经验（宠物满级60级时不显示）",
        order = 29,
        get = function() return Automaton_Tooltip.db.profile.showPetExp end,
        set = function(v) Automaton_Tooltip.db.profile.showPetExp = v end,
    },
    header3 = {
        type = "header",
        name = "界面行为",
        order = 30,
    },
    cursorScale = {
        type = 'range',
        name = "鼠标大小",
        desc = "设置鼠标光标大小 (1.0 - 4.0)（需要bigcursor模组）",
        order = 31,
        min = 1,
        max = 4,
        step = 0.1,
        get = function() return Automaton_Tooltip.db.profile.cursorScale end,
        set = function(v)
            Automaton_Tooltip.db.profile.cursorScale = v
            if SetCursorScale then
                SetCursorScale(v)
            end
        end,
    },
    hideInCombat = {
        type = "toggle",
        name = "战斗中隐藏提示",
        desc = "战斗中自动隐藏鼠标提示（按住Shift可临时显示）",
        order = 32,
        get = function() return Automaton_Tooltip.db.profile.hideInCombat end,
        set = function(v) Automaton_Tooltip.db.profile.hideInCombat = v end,
    },
    showFrameName = {
        type = "toggle",
        name = "框架显示",
        desc = "鼠标指向框架时在聊天框显示框架名称（无名对象也显示；不依赖提示框，插件按钮均可检测）",
        order = 33,
        get = function() return Automaton_Tooltip.db.profile.showFrameName end,
        set = function(v)
            Automaton_Tooltip.db.profile.showFrameName = v
            Automaton_Tooltip:UpdateFrameWatcher()
        end,
    },
}

------------------------------
--      战斗隐藏提示相关变量      --
------------------------------
local inCombat = 0

------------------------------
--      Initialization      --
------------------------------
function Automaton_Tooltip:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("Automaton_Tooltip")
    Automaton:RegisterDefaults("Automaton_Tooltip", "profile", {
        disabled = false,
        showitemid = true,
        showResistance = false,
        showDamageAndSpeed = true,
        showgather = true,
        showReputation = true,
        showImpression = true,
        showspellid = false,
        showPetHappiness = true,
        showPetFood = true,
        showPetExp = true,
        cursorScale = 1.0,  -- 默认光标大小
        hideInCombat = false, -- 战斗隐藏提示默认关闭
        forceUnitTooltip = true,
        showFrameName = false, -- 框架显示默认关闭
    })
    Automaton:SetDisabledAsDefault(self, "Automaton_Tooltip")
    self:RegisterOptions(self.options)
    if not self.f then
        self.f = CreateFrame("Frame", "tipFormat", GameTooltip)
    end
    
    -- 初始化Gratuity库用于获取法术信息
    if not self.gratuity then
        self.gratuity = AceLibrary:HasInstance("Gratuity-2.0") and AceLibrary("Gratuity-2.0") or nil
    end

    -- 初始化战斗隐藏提示相关
    -- Event and rendering ownership is installed only when the module is enabled.
end

------------------------------
--      战斗隐藏提示核心逻辑      --
------------------------------
function Automaton_Tooltip:ShouldHideTooltip()
    return self.active and self.db.profile.hideInCombat and inCombat == 1 and not IsShiftKeyDown()
end
function Automaton_Tooltip:HideTooltipIfNeeded()
    if self:ShouldHideTooltip() then GameTooltip:Hide();return true end
end
function Automaton_Tooltip:PLAYER_REGEN_DISABLED() inCombat=1;self:HideTooltipIfNeeded() end
function Automaton_Tooltip:PLAYER_REGEN_ENABLED() inCombat=0 end
function Automaton_Tooltip:MODIFIER_STATE_CHANGED()
    if inCombat==1 and self.db.profile.hideInCombat and (arg1=="LSHIFT" or arg1=="RSHIFT") then
        if not IsShiftKeyDown() then GameTooltip:Hide()
        elseif UnitExists("mouseover") then GameTooltip:SetUnit("mouseover") end
    end
end
function Automaton_Tooltip:OnEnable()
    self.active = true
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    if UnitAffectingCombat and UnitAffectingCombat("player") then inCombat=1 else inCombat=0 end
    if not self.pfUIManaged then self:InstallStandaloneHooks() end
    if SetCursorScale then SetCursorScale(self.db.profile.cursorScale or 1) end
    self:UpdateFrameWatcher()
end
function Automaton_Tooltip:OnDisable()
    self.active = nil
    self:UnregisterAllEvents()
    if self.frameWatcher then self.frameWatcher:Hide();self.frameWatcher.lastFocus=nil end
    if SetCursorScale then SetCursorScale(1) end
end
function Automaton_Tooltip:SetPfUIManaged(enabled)
    self.pfUIManaged = enabled and true or nil
    if self.f then self.f:Hide() end
    if not enabled and self.active then self:InstallStandaloneHooks() end
end

-- 检查物品是否在愿望列表中
function Automaton_Tooltip:IsItemInWishList(itemId)
    -- 检查AtlasLoot愿望列表是否存在
    if not AtlasLootCharDB or not AtlasLootCharDB["WishList"] then
        return false
    end
    
    -- 将itemId转换为数字进行比较
    itemId = tonumber(itemId)
    if not itemId then return false end
    
    -- 遍历愿望列表检查物品
    for _, wishItem in ipairs(AtlasLootCharDB["WishList"]) do
        local wishItemId = tonumber(wishItem[1])
        if wishItemId and wishItemId == itemId then
            return true
        end
    end
    
    return false
end

-- 框架显示：轮询 GetMouseFocus()，焦点变化时在聊天框输出框架名称
-- 等价于宏 /run local f = GetMouseFocus() if f and f.GetName then local n = f:GetName() print(n or "无名对象") end
-- 不依赖 tooltip 是否弹出（很多插件按钮不触发提示框），无名对象也照常显示
function Automaton_Tooltip:PrintFrameName(f)
    if not f then return end
    local n
    if f.GetName then n = f:GetName() end
    if not n or n == "" then
        n = "无名对象"
        if f.GetObjectType then n = n .. "(" .. f:GetObjectType() .. ")" end
    end
    -- 世界层框架不输出（鼠标悬停世界/空白时的焦点，输出纯噪音）
    if n == "WorldFrame" or n == "UIParent" then return end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff框架: |r|cffffffff" .. n .. "|r")
    end
end

function Automaton_Tooltip:UpdateFrameWatcher()
    if self.active and self.db.profile.showFrameName then
        if not self.frameWatcher then
            self.frameWatcher = CreateFrame("Frame", "AutomatonTooltipFrameWatcher", UIParent)
            self.frameWatcher.elapsed = 0
            self.frameWatcher:SetScript("OnUpdate", function()
                local elapsed = type(arg1) == "number" and arg1 or 0
                this.elapsed = this.elapsed + elapsed
                if this.elapsed < 0.2 then return end
                this.elapsed = 0
                local f = GetMouseFocus()
                if f == this.lastFocus then return end
                this.lastFocus = f
                Automaton_Tooltip:PrintFrameName(f)
            end)
        end
        self.frameWatcher.lastFocus = nil
        self.frameWatcher.elapsed = 0
        self.frameWatcher:Show()
    else
        if self.frameWatcher then
            self.frameWatcher.lastFocus = nil
            self.frameWatcher:Hide()
        end
    end
end

-- 取单位实际抗性（优先取修正后数值，兼容只返回单值的客户端，nil 归 0）
local function zGetUnitResist(unit, index)
    local base, modified = UnitResistance(unit, index)
    return (modified or base) or 0
end

-- 显示抗性和护甲的函数
function Automaton_Tooltip:ShowMouseoverResist(unit)
    -- 检查单位是否敌对或中立
    local reaction = UnitReaction("player", unit)
    local isHostileOrNeutral = reaction and (reaction <= 4) -- 4及以下为中立或敌对

    -- 1=神圣 2=火焰 3=自然 4=冰霜 5=暗影 6=奥术
    local GetFire = zGetUnitResist(unit, 2)
    local GetFrost = zGetUnitResist(unit, 4)
    local GetNature = zGetUnitResist(unit, 3)
    local GetArcane = zGetUnitResist(unit, 6)
    local GetHoly = zGetUnitResist(unit, 1)
    local GetShadow = zGetUnitResist(unit, 5)
    local GetArmor = UnitArmor(unit) or 0
    --火抗、冰抗
    if GetFire ~= 0 and GetFrost == 0 then
        GameTooltip:AddLine("|cffFF0000火抗" .. GetFire)
    elseif GetFire == 0 and GetFrost ~= 0 then
        GameTooltip:AddLine("|cff4AE8F5冰抗" .. GetFrost)
    elseif GetFire ~= 0 and GetFrost ~= 0 then
        GameTooltip:AddLine("|cffFF0000火抗" .. GetFire .. " " .. "|cff4AE8F5冰抗" .. GetFrost)
    end
    --自抗、奥抗
    if GetNature ~= 0 and GetArcane == 0 then
        GameTooltip:AddLine("|cff00FF00自抗" .. GetNature)
    elseif GetNature == 0 and GetArcane ~= 0 then
        GameTooltip:AddLine("|cffF241FF奥抗" .. GetArcane)
    elseif GetNature ~= 0 and GetArcane ~= 0 then
        GameTooltip:AddLine("|cff00FF00自抗" .. GetNature .. " " .. "|cffF241FF奥抗" .. GetArcane)
    end
    --圣抗、暗抗
    if GetHoly ~= 0 and GetShadow == 0 then
        GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly)
    elseif GetHoly == 0 and GetShadow ~= 0 then
        GameTooltip:AddLine("|cff87248F暗抗" .. GetShadow)
    elseif GetHoly ~= 0 and GetShadow ~= 0 then
        GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly .. " " .. "|cff87248F暗抗" .. GetShadow)
    end
    --护甲 - 只显示敌方和中立单位的
    if GetArmor ~= 0 and isHostileOrNeutral then
        GameTooltip:AddLine("护甲" .. GetArmor)
    end
end

-- 新增独立的显示伤害和攻速函数
function Automaton_Tooltip:ShowMouseoverDamageAndSpeed(unit)
    -- 检查单位是否敌对或中立
    local reaction = UnitReaction("player", unit)
    local isHostileOrNeutral = reaction and (reaction <= 4) -- 4及以下为中立或敌对

    -- 只对敌对/中立的非玩家单位显示伤害和攻速
    if isHostileOrNeutral and not UnitIsPlayer(unit) then
        local minDmg, maxDmg = UnitDamage(unit)
        local attackSpeed = UnitAttackSpeed(unit)
        if minDmg and maxDmg then
            GameTooltip:AddLine(string.format("伤害范围: %.0f - %.0f", minDmg, maxDmg))
        end
        if attackSpeed then
            GameTooltip:AddLine(string.format("攻击速度: %.2f", attackSpeed))
        end
    end
end

-- 获取单位声望信息
local function zGetUnitFaction(unit)
    local id = UnitReaction(unit, "player")
    if not id then return "" end
    if id > 6 then
        -- 从tooltip中提取阵营标签
        local label
        for i = GameTooltip:NumLines(), 1, -1 do
            label = getglobal("GameTooltipTextLeft"..i):GetText()
            if label and label ~= PVP_ENABLED then break end
        end
        -- 匹配阵营信息以获取精确声望等级
        local name, standingId, isHeader
        for i = 1, GetNumFactions() do
            name, _, standingId, _, _, _, _,_, isHeader = GetFactionInfo(i)
            if not isHeader and name == label then
                id = standingId
                break
            end
        end
    end
    -- 格式化声望文本（带颜色）
    local ret = GetText("FACTION_STANDING_LABEL"..id, UnitSex("player"))
    if id == 5 then ret = format("|cff33CC33%s|r", ret)
    elseif id == 6 then ret = format("|cff33CCCC%s|r", ret)
    elseif id == 7 then ret = format("|cffFF6633%s|r", ret)
    elseif id == 8 then ret = format("|cffDD33DD%s|r", ret) end
    return ret
end

-- 处理物品第一行文本的函数
local function FirstLineText(text)
    if not text then return end
    local result
    if strfind(text, "Mailbox") then
        result = "邮箱"
    elseif strfind(text, "Grave of ") then
        local _, _, name, level = strfind(text, "Grave of (.+) %(level (%d+)%)")
        if name and level then
            result = format("%s 的坟墓(等级 %s)", name, level)
        end
    elseif Automaton.t.obj[text] then
        result = Automaton.t.obj[text]
    elseif Automaton.t.herbmini[text] then
        result = text
    elseif strfind(text, "需要") then
        result = text
    end
    return result
end

-- 显示物品的函数
function Automaton_Tooltip:ShowObj()
    if not self.db.profile.showgather then return end
    local lines = {}
    local text, r, g, b, a, strex
    for i = 1, GameTooltip:NumLines() do
        text = FirstLineText(getglobal('GameTooltipTextLeft' .. i):GetText())
        if not text then break end
        r, g, b, a = getglobal('GameTooltipTextLeft' .. i):GetTextColor()
        lines[i] = { text = text, r = r, g = g, b = b, a = a }
    end

    if getn(lines) > 0 then
        GameTooltip:ClearLines()
        for i, val in pairs(lines) do
            if i == 1 then
                strex = Automaton.t.herbmini[val.text] or ""
                GameTooltip:SetText(val.text)
            else
                if self.db.profile.showgather and strex then
                    GameTooltip:AddLine(val.text .. strex, val.r, val.g, val.b, val.a)
                else
                    GameTooltip:AddLine(val.text, val.r, val.g, val.b, val.a)
                end
            end
        end
        GameTooltip:Show()
    end
end

-- 宠物信息（仅自己的宠物）：快乐度 / 食物需求 / 经验
function Automaton_Tooltip:ShowPetInfo(unit)
    if not UnitExists(unit) or not UnitIsUnit(unit, "pet") then return end

    local profile = self.db.profile

    -- 快乐度（GetPetHappiness 仅猎人宠物返回有效值，术士宠物等返回 nil 自动跳过）
    if profile.showPetHappiness and GetPetHappiness then
        local happiness = GetPetHappiness()
        if happiness then
            local labels = {
                [1] = "|cffff3333不高兴 (伤害75%)|r",
                [2] = "|cffffff00满足 (伤害100%)|r",
                [3] = "|cff33ff33快乐 (伤害125%)|r",
            }
            GameTooltip:AddLine("快乐度: " .. (labels[happiness] or tostring(happiness)))
        end
    end

    -- 食物需求（客户端返回的已是本地化字符串，如：肉、鱼、水果）
    if profile.showPetFood and GetPetFoodTypes then
        local foods = { GetPetFoodTypes() }
        if foods and table.getn(foods) > 0 then
            GameTooltip:AddLine("食物需求: |cff66ccff" .. table.concat(foods, "、") .. "|r")
        end
    end

    -- 经验（宠物满级 60 级时不显示）
    if profile.showPetExp then
        local level = UnitLevel("pet")
        if level and level ~= 60 then
            -- 1.12 宠物经验必须用 GetPetExperience()（UnitXP("pet") 本客户端不可靠，返回 nil/0）
            local cur, max
            if GetPetExperience then
                cur, max = GetPetExperience()
            end
            if not cur or not max then
                cur, max = UnitXP("pet"), UnitXPMax("pet")
            end
            if cur and max and max > 0 then
                GameTooltip:AddLine(string.format("经验: %d/%d (%d%%)", cur, max, floor(cur / max * 100)))
            end
        end
    end
end

-- 核心增强函数：在单位提示上添加所有配置的额外信息
function Automaton_Tooltip:EnhanceUnitTooltip(unit)
    self = self or Automaton_Tooltip
    if not unit or not UnitExists(unit) then return end

    -- 抗性
    if self.db.profile.showResistance then
        self:ShowMouseoverResist(unit)
    end

    -- 伤害和攻速
    if self.db.profile.showDamageAndSpeed then
        self:ShowMouseoverDamageAndSpeed(unit)
    end

    -- 宠物信息（仅自己的宠物：快乐度/食物需求/经验）
    if self.db.profile.showPetHappiness or self.db.profile.showPetFood or self.db.profile.showPetExp then
        self:ShowPetInfo(unit)
    end

    -- 声望（仅非玩家单位）
    if self.db.profile.showReputation and not UnitIsPlayer(unit) and not (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
        local repText = zGetUnitFaction(unit)
        if repText and repText ~= "" then
            GameTooltip:AddLine("" .. repText)
        end
    end

    -- 许愿信息
    if self.db.profile.showWishInfo and UnitIsPlayer(unit) then
        local name = UnitName(unit)
        if getXyInfo then
            local info = getXyInfo(name)
            -- 构建当前在团/在队成员表，用于统计许愿人数时过滤已退团团员（与XyTracker的XYLISTbyPlayer保持一致）
            local currentMembers = {}
            local totalRaidMembers = GetNumRaidMembers()
            if totalRaidMembers and totalRaidMembers > 0 then
                for mi = 1, totalRaidMembers do
                    local raidName = GetRaidRosterInfo(mi)
                    if raidName then
                        currentMembers[raidName] = true
                    end
                end
            else
                local playerName = UnitName("player")
                if playerName then
                    currentMembers[playerName] = true
                end
            end
            if info and info["xy"] and info["xy"] ~= "" and info["xy"] ~= "---未许愿---" then
                local xy = info["xy"]
                local dkp = info["dkp"] or 0

                -- 为每个物品添加许愿人数标记（如果人数 > 1）
                local newXy = xy
                if XyArray and type(XyArray) == "table" then
                    newXy = string.gsub(xy, "(|c%x+|Hitem:(%d+):.-|h%[(.-)%]|h|r)", function(link, itemId, itemName)
                        -- 统计许愿该物品的人数
                        local count = 0
                        for i = 1, getn(XyArray) do
                            local other = XyArray[i]
                            local otherName = other["name"]
                            if otherName and currentMembers[otherName] then
                                local otherXy = other["xy"] or ""
                                if otherXy ~= "---未许愿---" and otherXy ~= "" then
                                    if string.find(otherXy, "|Hitem:" .. itemId .. ":") then
                                        count = count + 1
                                    end
                                end
                            end
                        end
                        if count > 1 then
                            return link .. " |cffffffffx" .. count .. "|r"
                        else
                            return link
                        end
                    end)
                end

                GameTooltip:AddLine(string.format("|cffFFFF00许愿:|r %s |cffFFFF00分数:|r %d", newXy, dkp))
            end
        end
    end

    -- 印象
    if self.db.profile.showImpression and UnitIsPlayer(unit) then
        local playerName = UnitName(unit)
        if SpiritSenseRecData then
            local impression = SpiritSenseRecData[playerName]
            if impression then
                local impressionText
                if type(impression) == "table" then
                    impressionText = table.concat(impression, ", ")
                else
                    impressionText = tostring(impression)
                end
                GameTooltip:AddLine(string.format("印象: %s", impressionText))
            end
        end
    end

    GameTooltip:Show()
end

function Automaton_Tooltip:FormatItemTooltip(tooltip)
    local self = Automaton_Tooltip
    if not tooltip.itemLink then return end

    tooltip.itemCount = IsShiftKeyDown() and tooltip.itemCount or 1
    local _, _, itemId = strfind(tooltip.itemLink, "item:(%d+)")
    if not itemId then return end

    local showing = false

    --显示物品ID
    if self.db.profile.showitemid then
        tooltip:AddDoubleLine("物品ID：", itemId)
        showing = true
    end

    -- 检查是否在愿望列表中
    if self:IsItemInWishList(tonumber(itemId)) then
        tooltip:AddLine("|cff00FF00✓ 我的愿望|r")
        showing = true
    end

    if showing then
        tooltip:Show();
    end
    return showing
end

-- Standalone fallback is installed once. Wrappers remain inert when pfUI owns
-- content, so re-enabling never multiplies hooks or unhooks another addon.
function Automaton_Tooltip:InstallStandaloneHooks()
    if self.standaloneInstalled then return end
    self.standaloneInstalled = true
    local provider = self
    local tip = GameTooltip
    local function Pack(...) return arg end
    local function UnpackRange(values, first, last)
      if first <= last then return values[first], UnpackRange(values, first+1, last) end
    end
    local readers = {
      SetHyperlink=function(a) return a end,
      SetBagItem=function(a,b) return GetContainerItemLink(a,b) end,
      SetInventoryItem=function(a,b) return GetInventoryItemLink(a,b) end,
      SetQuestItem=function(a,b) return GetQuestItemLink(a,b) end,
      SetQuestLogItem=function(a,b) return GetQuestLogItemLink(a,b) end,
      SetLootItem=function(a) return GetLootSlotLink(a) end,
    }
    local methods={"SetUnit","SetHyperlink","SetBagItem","SetInventoryItem","SetQuestItem","SetQuestLogItem","SetLootItem",
      "SetAction","SetLootRollItem","SetMerchantItem","SetPetAction","SetShapeshift","SetSpell","SetTrackingSpell",
      "SetTradeSkillItem","SetTradePlayerItem","SetTradeTargetItem","SetPlayerBuff","SetPlayerDebuff","SetUnitBuff","SetUnitDebuff"}
    local function Install(method)
      local original=tip[method]
      if type(original)~="function" then return end
      tip[method]=function(...)
        if not provider.active or provider.pfUIManaged or provider.setting then return original(UnpackRange(arg,1,arg.n)) end
        if provider:HideTooltipIfNeeded() then return end
        provider.setting=true
        tip.itemLink=nil
        if readers[method] then tip.itemLink=readers[method](arg[2],arg[3]) end
        local result=Pack(pcall(original,UnpackRange(arg,1,arg.n)))
        provider.setting=nil
        if not result[1] then error(result[2]) end
        local data=pfUI and pfUI.api and pfUI.api.libtooltip
        if data then tip.itemLink=data:GetItemLink() end
        if method=="SetUnit" then provider:EnhanceUnitTooltip(arg[2])
        elseif tip.itemLink then provider:FormatItemTooltip(tip)
        else provider:AddSpellID(method,arg[2],arg[3]) end
        return UnpackRange(result,2,result.n)
      end
    end
    for _,method in ipairs(methods) do Install(method) end
    local oldShow=tip:GetScript("OnShow")
    tip:SetScript("OnShow",function()
      if oldShow then oldShow() end
      if provider.active and not provider.pfUIManaged and not provider.setting then
        if provider:HideTooltipIfNeeded() then return end
        if not UnitExists("mouseover") then provider:ShowObj() end
      end
    end)
end
function Automaton_Tooltip:AddSpellID(method,a,b)
    if not self.db.profile.showspellid then return end
    local id
    if method=="SetPlayerBuff" and GetPlayerBuffID then id=GetPlayerBuffID(a)
    elseif method=="SetPlayerDebuff" then local _,_,_,spell=UnitDebuff("player",a);id=spell
    elseif method=="SetUnitBuff" then local _,_,_,_,_,_,spell=UnitBuff(a,b);id=spell
    elseif method=="SetUnitDebuff" then local _,_,_,_,_,_,spell=UnitDebuff(a,b);id=spell end
    if id then GameTooltip:AddDoubleLine("法术ID：",id);GameTooltip:Show() end
end
