-- ======================== Lua 全局工具本地化（性能优化）===============================
local pairs = pairs
local string_gsub = string.gsub
local GameTooltip = GameTooltip
local CreateFrame = CreateFrame
local getglobal = getglobal
local math_ceil = math.ceil
local string_len = string.len
local string_sub = string.sub
local math_floor = math.floor
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local table_getn = table.getn

-- 全局表初始化
if not PTURTLE_Combat then
    PTURTLE_Combat = {}
end
PTURTLE_Combat.config = PTURTLE_Combat.config or {}

local addon = PTURTLE_Combat

-- 初始化核心属性
addon.panel = nil
addon.miniBtn = nil
addon.db = nil
addon.subPanel = nil
addon.fixedPosIndicator = nil 

-- Lua5.0 字符串去空格
local function trim(s)
    return (string_gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- 通用按钮Tooltip设置函数（减少重复代码）
local function SetButtonTooltip(btn, title, description, anchor)
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn, anchor or "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(title)
        if description then
            GameTooltip:AddLine(description, 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end


function addon:ShowMissingDependencyDialog(dependencyName, message)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetWidth(400)
    f:SetHeight(150)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    -- 创建背景
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0.1, 0.1, 0.1, 1)
    bg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)

    f:SetScript("OnDragStart", function()
        f:StartMoving()
    end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
    end)

    -- 标题
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("|cffff0000PlayTurtle 依赖缺失|r")

    -- 内容
    local content = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content:SetPoint("TOP", title, "BOTTOM", 0, -8)
    content:SetJustifyH("CENTER")
    content:SetJustifyV("TOP")
    content:SetWidth(360)
    content:SetHeight(100)  -- 增加高度以显示完整文本

    if message then
        content:SetText(message)
    else
        content:SetText("未检测到 " .. dependencyName .. "\n插件无法正常运行\n请安装后重新加载")
    end

    -- 按钮
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetWidth(100)
    btn:SetHeight(25)
    btn:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
    btn:SetText("确定")
    btn:SetScript("OnClick", function()
        f:Hide()
    end)

    f:Show()
end
-- 初始化配置
function addon:InitDB()
    -- -确保个人存档数据库存在（首次进入游戏时）
    if not PTURTLE_Combat_CharDB then
        PTURTLE_Combat_CharDB = {}
    end
    
    if not PTURTLE_Combat_DB then
        PTURTLE_Combat_DB = {}
        PTURTLE_Combat_DB.panelPos = {}
        PTURTLE_Combat_DB.panelPos.x = 0
        PTURTLE_Combat_DB.panelPos.y = 0
        PTURTLE_Combat_DB.panelVisible = false
        PTURTLE_Combat_DB.btnAngle = 45

        for i = 1, 6 do
            if i == 1 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 120  -- 一阶缩放默认 120
            elseif i == 2 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 30  -- 二阶缩放默认 30
            elseif i == 3 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 3  -- 停留时间默认 3 (0.3 秒)
            elseif i == 4 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 0  -- 锚点X偏移默认 0
            elseif i == 5 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 0  -- 锚点Y偏移默认 0
            elseif i == 6 then
                PTURTLE_Combat_DB["leftSlider"..i.."Value"] = PTURTLE_Combat_DB["leftSlider"..i.."Value"] or 100  -- X轴偏移（暴击随机）默认 100
            end
            
            -- 右列滑块默认值
            if i == 1 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 22  -- 淡出速度默认 2.2 秒
            elseif i == 2 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 100  -- 浮动速度默认 100
            elseif i == 3 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 50  -- 字符大小默认 50
            elseif i == 4 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 100  -- X 分布默认 100
            elseif i == 5 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 80  -- Y 分布默认 80
            elseif i == 6 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 10  -- 行距（动画A）默认 10
            elseif i == 7 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 8  -- 存活时间（动画A）默认 0.8 秒
            elseif i == 8 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or -10  -- （全局）字符间距默认 -10
            elseif i == 9 then
                PTURTLE_Combat_DB["rightSlider"..i.."Value"] = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 1  -- （全局）字体样式默认 1
            end
        end
        
        -- 初始化抖动强度和频率（使用独立变量，不与X轴偏移共用）
        PTURTLE_Combat_DB.critShakeIntensityValue = PTURTLE_Combat_DB.critShakeIntensityValue or 10  -- 抖动强度默认 1.0
        PTURTLE_Combat_DB.leftSlider7Value = PTURTLE_Combat_DB.leftSlider7Value or 10  -- 抖动频率默认 10
        
        -- 确保奏乐开关存在（兼容旧存档）
        PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED = PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED or 1
        PTURTLE_Combat_DB.rightSlider9Value = PTURTLE_Combat_DB.rightSlider9Value or 1  -- 字体样式默认 1
        PTURTLE_Combat_DB.maxAniSlots = PTURTLE_Combat_DB.maxAniSlots or 50  -- 伤害动画槽位数量默认 50（回头是岸模式）
        PTURTLE_Combat_DB.maxReceivedSlots = PTURTLE_Combat_DB.maxReceivedSlots or 30  -- 受伤/受治疗/输出治疗动画槽位数量默认 30（回头是岸模式）
        PTURTLE_Combat_DB.fixedPosEnabled = PTURTLE_Combat_DB.fixedPosEnabled or false  -- 固定位置开关：优先读存档，新用户默认关闭
        PTURTLE_Combat_DB.fixedPosX = 0
        PTURTLE_Combat_DB.fixedPosY = 150
        PTURTLE_Combat_DB.petQueueXOffset = PTURTLE_Combat_DB.petQueueXOffset or 0  -- 宠物队列X偏移默认0
        PTURTLE_Combat_DB.receivedMoveSpeed = PTURTLE_Combat_DB.receivedMoveSpeed or 110  -- 队列系统速度默认110
        PTURTLE_Combat_DB.aoeCounterX = PTURTLE_Combat_DB.aoeCounterX or 0  -- AOE计数器 X 位置
        PTURTLE_Combat_DB.aoeCounterY = PTURTLE_Combat_DB.aoeCounterY or 200  -- AOE计数器 Y 位置
        -- -保存屏幕宽高，用于检测分辨率变化
        PTURTLE_Combat_DB.screenWidth = PTURTLE_Combat_DB.screenWidth or UIParent:GetWidth()
        PTURTLE_Combat_DB.screenHeight = PTURTLE_Combat_DB.screenHeight or UIParent:GetHeight()
        PTURTLE_Combat_DB.collectSummonerInfo = PTURTLE_Combat_DB.collectSummonerInfo or 0  -- 召唤物信息收集：默认关闭
        PTURTLE_Combat_DB.showSpellIcon = PTURTLE_Combat_DB.showSpellIcon or 1  -- 技能图标功能：优先读存档，新用户默认开启
        if PTURTLE_Combat_DB.damageThreshold == nil then PTURTLE_Combat_DB.damageThreshold = 1 end  -- 伤害阈值（-允许0值，默认1）
        PTURTLE_Combat_DB.CRIT_SHAKE_ENABLED = PTURTLE_Combat_DB.CRIT_SHAKE_ENABLED or 1  -- 暴击震动功能开关（默认开启）
        
        -- 初始化非暴击动画模式（默认 A）
        PTURTLE_Combat_DB.normalAnimMode = PTURTLE_Combat_DB.normalAnimMode or "A"  -- A=向上淡出, B=抛物线, C=自定义
        
        -- 初始化受到治疗和受到伤害开关
        PTURTLE_Combat_DB.receivedHealEnabled = PTURTLE_Combat_DB.receivedHealEnabled or 0  -- 受到治疗显示开关（默认关闭）
        PTURTLE_Combat_DB.receivedDamageEnabled = PTURTLE_Combat_DB.receivedDamageEnabled or 0  -- 受到伤害显示开关（默认关闭）
        
        -- 初始化受到治疗和受到伤害的位置
        PTURTLE_Combat_DB.receivedHealX = PTURTLE_Combat_DB.receivedHealX or -18  -- 受到治疗 X 位置默认 -18
        PTURTLE_Combat_DB.receivedHealY = PTURTLE_Combat_DB.receivedHealY or -88   -- 受到治疗 Y 位置默认 -88
        PTURTLE_Combat_DB.receivedDamageX = PTURTLE_Combat_DB.receivedDamageX or 2  -- 受到伤害 X 位置默认 2
        PTURTLE_Combat_DB.receivedDamageY = PTURTLE_Combat_DB.receivedDamageY or -58  -- 受到伤害 Y 位置默认 -58
        
        -- - 新增：输出治疗的位置和开关
        PTURTLE_Combat_DB.outHealEnabled = PTURTLE_Combat_DB.outHealEnabled or 0  -- 输出治疗显示开关（默认关闭）
        PTURTLE_Combat_DB.outHealX = PTURTLE_Combat_DB.outHealX or 306  -- 输出治疗 X 位置默认 306
        PTURTLE_Combat_DB.outHealY = PTURTLE_Combat_DB.outHealY or 135   -- 输出治疗 Y 位置默认 135
        
        -- - 初始化三个框架的位置和大小（相对于屏幕中心）
        PTURTLE_Combat_DB.damageFrameX = PTURTLE_Combat_DB.damageFrameX or -262    -- 受伤框架 X 位置
        PTURTLE_Combat_DB.damageFrameY = PTURTLE_Combat_DB.damageFrameY or -43     -- 受伤框架 Y 位置
        PTURTLE_Combat_DB.damageFrameWidth = PTURTLE_Combat_DB.damageFrameWidth or 48   -- 受伤框架宽度
        PTURTLE_Combat_DB.damageFrameHeight = PTURTLE_Combat_DB.damageFrameHeight or 292 -- 受伤框架高度
        
        PTURTLE_Combat_DB.receivedHealFrameX = PTURTLE_Combat_DB.receivedHealFrameX or 244   -- 受治疗框架 X 位置
        PTURTLE_Combat_DB.receivedHealFrameY = PTURTLE_Combat_DB.receivedHealFrameY or -50   -- 受治疗框架 Y 位置
        PTURTLE_Combat_DB.receivedHealFrameWidth = PTURTLE_Combat_DB.receivedHealFrameWidth or 41   -- 受治疗框架宽度
        PTURTLE_Combat_DB.receivedHealFrameHeight = PTURTLE_Combat_DB.receivedHealFrameHeight or 304 -- 受治疗框架高度
        
        PTURTLE_Combat_DB.outputHealFrameX = PTURTLE_Combat_DB.outputHealFrameX or 151  -- 输出治疗框架 X 位置
        PTURTLE_Combat_DB.outputHealFrameY = PTURTLE_Combat_DB.outputHealFrameY or 261  -- 输出治疗框架 Y 位置
        PTURTLE_Combat_DB.outputHealFrameWidth = PTURTLE_Combat_DB.outputHealFrameWidth or 236   -- 输出治疗框架宽度
        PTURTLE_Combat_DB.outputHealFrameHeight = PTURTLE_Combat_DB.outputHealFrameHeight or 273 -- 输出治疗框架高度
        
        -- 队列框架配置
        PTURTLE_Combat_DB.dotDamageFrameX = PTURTLE_Combat_DB.dotDamageFrameX or -569    -- 队列框架 X 位置
        PTURTLE_Combat_DB.dotDamageFrameY = PTURTLE_Combat_DB.dotDamageFrameY or 169     -- 队列框架 Y 位置
        PTURTLE_Combat_DB.dotDamageFrameWidth = PTURTLE_Combat_DB.dotDamageFrameWidth or 38   -- 队列框架宽度
        PTURTLE_Combat_DB.dotDamageFrameHeight = PTURTLE_Combat_DB.dotDamageFrameHeight or 400 -- 队列框架高度
        PTURTLE_Combat_DB.dotDamageHandleX = PTURTLE_Combat_DB.dotDamageHandleX or -5    -- 队列框架活动块 X
        PTURTLE_Combat_DB.dotDamageHandleY = PTURTLE_Combat_DB.dotDamageHandleY or -188   -- 队列框架活动块 Y
        
        -- - 初始化三个框架的活动块（蓝色手柄）位置
        PTURTLE_Combat_DB.damageHandleX = PTURTLE_Combat_DB.damageHandleX or 8    -- 受伤框架活动块 X
        PTURTLE_Combat_DB.damageHandleY = PTURTLE_Combat_DB.damageHandleY or -127   -- 受伤框架活动块 Y
        PTURTLE_Combat_DB.receivedHealHandleX = PTURTLE_Combat_DB.receivedHealHandleX or 2  -- 受治疗框架活动块 X
        PTURTLE_Combat_DB.receivedHealHandleY = PTURTLE_Combat_DB.receivedHealHandleY or -136 -- 受治疗框架活动块 Y
        PTURTLE_Combat_DB.outputHealHandleX = PTURTLE_Combat_DB.outputHealHandleX or -211  -- 输出治疗框架活动块 X
        PTURTLE_Combat_DB.outputHealHandleY = PTURTLE_Combat_DB.outputHealHandleY or -154 -- 输出治疗框架活动块 Y
        
        -- 初始化伤害颜色配置（带 Alpha）
        -- 注意：必须使用 [0]-[7] 索引，与 Display.lua 的 SchoolData 一致
        PTURTLE_Combat_DB.damageColors = {
            [0] = {r=1.0, g=1.0, b=1.0, a=1.0},  -- 物理（纯白）
            [1] = {r=1.0, g=0.85, b=0.4, a=1.0},  -- 神圣（橙黄色）
            [2] = {r=1.0, g=0.28, b=0.0, a=1.0},  -- 火焰（深红色）
            [3] = {r=0.44, g=1.0, b=0.43, a=1.0},  -- 自然（浅绿色）
            [4] = {r=0.3, g=0.54, b=1.0, a=1.0},  -- 冰霜（蓝色）
            [5] = {r=0.77, g=0.28, b=1.0, a=1.0},  -- 暗影（紫罗兰色）
            [6] = {r=0.0, g=0.8, b=1.0, a=1.0},  -- 奥术（天蓝色）
            [7] = {r=1.0, g=0.9, b=0.0, a=1.0},  -- 技能物理（深黄色）
        }
        
        -- 初始化宠物普攻伤害颜色（默认白色）
        PTURTLE_Combat_DB.petAutoAttackColor = {r=1.0, g=1.0, b=1.0, a=1.0}
        
        -- 初始化普攻技能图标开关（默认开启）
        PTURTLE_Combat_DB.autoAttackIconEnabled = PTURTLE_Combat_DB.autoAttackIconEnabled or 1
        
        -- 初始化非暴击数字不显示技能图标开关（默认开启，即非暴击也显示图标）
        PTURTLE_Combat_DB.hideIconForNonCrit = PTURTLE_Combat_DB.hideIconForNonCrit or 1
        
        -- 确保全局数据库存在（关键修复）
        if not PTURTLE_Combat_DB then
            PTURTLE_Combat_DB = {}
        end
        
        -- 核心优化：使用统一的配置同步函数（替代手动同步代码）
        addon:SyncConfigFromDB()
        -- 初始化法术监控开关（默认关闭）- 全局配置
        PTURTLE_Combat_DB.spellMonitorEnabled = PTURTLE_Combat_DB.spellMonitorEnabled or 0  -- 默认 0=关闭
        
        -- 初始化 BUFF 监控开关（默认关闭）- 全局配置
        PTURTLE_Combat_DB.buffMonitorEnabled = PTURTLE_Combat_DB.buffMonitorEnabled or 0  -- 默认 0=关闭
        
        -- 初始化自动应答开关（默认开启）
        PTURTLE_Combat_DB.autoReplyEnabled = PTURTLE_Combat_DB.autoReplyEnabled or 1
        
        -- 初始化目标连线开关（默认关闭）
        PTURTLE_Combat_DB.targetLineEnabled = PTURTLE_Combat_DB.targetLineEnabled or 0
        
        -- 初始化个人存档数据库（角色独立的监控列表和开关）
        if not PTURTLE_Combat_CharDB then
            PTURTLE_Combat_CharDB = {}
            -- 初始化法术列表（使用表结构，以法术 ID 为键）- 个人存档
            PTURTLE_Combat_CharDB.monitoredSpells = {}
            -- 初始化 BUFF 列表（个人存档）
            PTURTLE_Combat_CharDB.monitoredBuffs = {}
        end
        
        -- 初始化法术监控开关（个人存档，默认关闭）- 从 SavedVariables 读取
        PTURTLE_Combat_CharDB.spellMonitorEnabled = PTURTLE_Combat_CharDB.spellMonitorEnabled or 0
        -- 初始化 BUFF 监控开关（个人存档，默认关闭）- 从 SavedVariables 读取
        PTURTLE_Combat_CharDB.buffMonitorEnabled = PTURTLE_Combat_CharDB.buffMonitorEnabled or 0
    else
        -- -确保已存在的数据库也有默认值
        PTURTLE_Combat_DB.panelVisible = PTURTLE_Combat_DB.panelVisible or false  -- 面板可见性默认关闭
        PTURTLE_Combat_DB.rightSlider1Value = PTURTLE_Combat_DB.rightSlider1Value or 22  -- 淡出速度默认 2.2 秒
        PTURTLE_Combat_DB.rightSlider2Value = PTURTLE_Combat_DB.rightSlider2Value or 60  -- 浮动速度默认 60
        PTURTLE_Combat_DB.rightSlider3Value = PTURTLE_Combat_DB.rightSlider3Value or 50  -- 字符大小默认 50
        PTURTLE_Combat_DB.rightSlider6Value = PTURTLE_Combat_DB.rightSlider6Value or 10  -- 行距（动画A）默认 10
        PTURTLE_Combat_DB.rightSlider7Value = PTURTLE_Combat_DB.rightSlider7Value or 12  -- 存活时间（动画A）默认 1.2 秒
        PTURTLE_Combat_DB.rightSlider8Value = PTURTLE_Combat_DB.rightSlider8Value or -10  -- 字符间距默认 -10
        PTURTLE_Combat_DB.rightSlider9Value = PTURTLE_Combat_DB.rightSlider9Value or 1  -- 字体样式默认 1
        
        -- 确保奏乐开关存在（兼容旧存档）
        PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED = PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED or 1
            
        -- 兼容已有数据库，补充颜色配置和 Alpha 值
        if not PTURTLE_Combat_DB.damageColors then
            PTURTLE_Combat_DB.damageColors = {
                [0] = {r=1.0, g=1.0, b=1.0, a=1.0},
                [1] = {r=1.0, g=0.85, b=0.4, a=1.0},
                [2] = {r=1.0, g=0.28, b=0.0, a=1.0},
                [3] = {r=0.44, g=1.0, b=0.43, a=1.0},
                [4] = {r=0.3, g=0.54, b=1.0, a=1.0},
                [5] = {r=0.77, g=0.28, b=1.0, a=1.0},
                [6] = {r=0.0, g=0.8, b=1.0, a=1.0},
                [7] = {r=1.0, g=0.9, b=0.0, a=1.0},
            }
        else
            for i = 0,7 do
                if PTURTLE_Combat_DB.damageColors[i] then
                    PTURTLE_Combat_DB.damageColors[i].a = PTURTLE_Combat_DB.damageColors[i].a or 1.0
                end
            end
        end
        
        -- 兼容旧存档：补充宠物普攻伤害颜色默认值（白色）
        if not PTURTLE_Combat_DB.petAutoAttackColor then
            PTURTLE_Combat_DB.petAutoAttackColor = {r=1.0, g=1.0, b=1.0, a=1.0}
        end
            
        -- 补充自动应答开关默认值（开启）
        PTURTLE_Combat_DB.autoReplyEnabled = PTURTLE_Combat_DB.autoReplyEnabled or 1
        
        -- 补充目标连线开关默认值（关闭）
        PTURTLE_Combat_DB.targetLineEnabled = PTURTLE_Combat_DB.targetLineEnabled or 0
        
        -- 确保个人存档数据库存在（关键修复）
        if not PTURTLE_Combat_CharDB then
            PTURTLE_Combat_CharDB = {}
        end
        
        -- 确保个人存档的监控列表存在（兼容旧版本）
        if not PTURTLE_Combat_CharDB.monitoredSpells then
            PTURTLE_Combat_CharDB.monitoredSpells = {}
        end
        if not PTURTLE_Combat_CharDB.monitoredBuffs then
            PTURTLE_Combat_CharDB.monitoredBuffs = {}
        end
        
        -- 确保个人存档的监控开关存在（兼容旧版本）
        PTURTLE_Combat_CharDB.spellMonitorEnabled = PTURTLE_Combat_CharDB.spellMonitorEnabled or 0
        PTURTLE_Combat_CharDB.buffMonitorEnabled = PTURTLE_Combat_CharDB.buffMonitorEnabled or 0
        
        -- -确保所有必需字段都存在（兼容旧存档）
        PTURTLE_Combat_DB.panelPos = PTURTLE_Combat_DB.panelPos or {}
        PTURTLE_Combat_DB.panelPos.x = PTURTLE_Combat_DB.panelPos.x or 0
        PTURTLE_Combat_DB.panelPos.y = PTURTLE_Combat_DB.panelPos.y or 0
        
        -- 框架位置和大小（兼容旧存档）
        PTURTLE_Combat_DB.damageFrameX = PTURTLE_Combat_DB.damageFrameX or -262
        PTURTLE_Combat_DB.damageFrameY = PTURTLE_Combat_DB.damageFrameY or -43
        PTURTLE_Combat_DB.damageFrameWidth = PTURTLE_Combat_DB.damageFrameWidth or 48
        PTURTLE_Combat_DB.damageFrameHeight = PTURTLE_Combat_DB.damageFrameHeight or 292
        
        PTURTLE_Combat_DB.receivedHealFrameX = PTURTLE_Combat_DB.receivedHealFrameX or 244
        PTURTLE_Combat_DB.receivedHealFrameY = PTURTLE_Combat_DB.receivedHealFrameY or -50
        PTURTLE_Combat_DB.receivedHealFrameWidth = PTURTLE_Combat_DB.receivedHealFrameWidth or 41
        PTURTLE_Combat_DB.receivedHealFrameHeight = PTURTLE_Combat_DB.receivedHealFrameHeight or 304
        
        PTURTLE_Combat_DB.outputHealFrameX = PTURTLE_Combat_DB.outputHealFrameX or 151
        PTURTLE_Combat_DB.outputHealFrameY = PTURTLE_Combat_DB.outputHealFrameY or 261
        PTURTLE_Combat_DB.outputHealFrameWidth = PTURTLE_Combat_DB.outputHealFrameWidth or 236
        PTURTLE_Combat_DB.outputHealFrameHeight = PTURTLE_Combat_DB.outputHealFrameHeight or 273
        
        -- 手柄位置（兼容旧存档）
        PTURTLE_Combat_DB.damageHandleX = PTURTLE_Combat_DB.damageHandleX or 8
        PTURTLE_Combat_DB.damageHandleY = PTURTLE_Combat_DB.damageHandleY or -127
        PTURTLE_Combat_DB.receivedHealHandleX = PTURTLE_Combat_DB.receivedHealHandleX or 2
        PTURTLE_Combat_DB.receivedHealHandleY = PTURTLE_Combat_DB.receivedHealHandleY or -136
        PTURTLE_Combat_DB.outputHealHandleX = PTURTLE_Combat_DB.outputHealHandleX or -211
        PTURTLE_Combat_DB.outputHealHandleY = PTURTLE_Combat_DB.outputHealHandleY or -154
        
        PTURTLE_Combat_DB.showSpellIcon = PTURTLE_Combat_DB.showSpellIcon or 1  -- 技能图标功能
        if PTURTLE_Combat_DB.damageThreshold == nil then PTURTLE_Combat_DB.damageThreshold = 1 end  -- 伤害阈值（-允许0值，默认1）
        PTURTLE_Combat_DB.CRIT_SHAKE_ENABLED = PTURTLE_Combat_DB.CRIT_SHAKE_ENABLED or 1  -- 暴击震动
        PTURTLE_Combat_DB.normalAnimMode = PTURTLE_Combat_DB.normalAnimMode or "A"  -- 非暴击动画模式
        PTURTLE_Combat_DB.receivedHealEnabled = PTURTLE_Combat_DB.receivedHealEnabled or 0  -- 受到治疗显示
        PTURTLE_Combat_DB.receivedDamageEnabled = PTURTLE_Combat_DB.receivedDamageEnabled or 0  -- 受到伤害显示
        PTURTLE_Combat_DB.outHealEnabled = PTURTLE_Combat_DB.outHealEnabled or 0  -- 输出治疗显示
        PTURTLE_Combat_DB.collectSummonerInfo = PTURTLE_Combat_DB.collectSummonerInfo or 0  -- 召唤物信息收集
        PTURTLE_Combat_DB.aoeCounterX = PTURTLE_Combat_DB.aoeCounterX or 0  -- AOE计数器 X 位置（兼容旧存档）
        PTURTLE_Combat_DB.aoeCounterY = PTURTLE_Combat_DB.aoeCounterY or 200  -- AOE计数器 Y 位置（兼容旧存档）
        
        -- 补充连线红点大小默认值
        PTURTLE_Combat_DB.targetLineDotSize = PTURTLE_Combat_DB.targetLineDotSize or 2
    end
    -- -设置 addon.db 引用（指向 PTURTLE_Combat_DB，用于滑块等组件访问）
    addon.db = PTURTLE_Combat_DB
    
    -- -移除屏幕分辨率检测和缩放逻辑，严格参考受伤框架的保存方法
    
    -- 确保个人存档数据库存在（关键修复）
    if not PTURTLE_Combat_CharDB then
        PTURTLE_Combat_CharDB = {}
        PTURTLE_Combat_CharDB.monitoredSpells = {}
        PTURTLE_Combat_CharDB.monitoredBuffs = {}
        PTURTLE_Combat_CharDB.spellMonitorEnabled = 0
        PTURTLE_Combat_CharDB.buffMonitorEnabled = 0
    end
    
    -- 个人监控列表引用（关键修改）
    addon.spellsDB = PTURTLE_Combat_CharDB.monitoredSpells or {}
    addon.buffsDB = PTURTLE_Combat_CharDB.monitoredBuffs or {}

    -- 从 SavedVariables 读取配置（左侧滑块）
    addon.Config.UserSettings.critScaleStart = (self.db.leftSlider1Value or 120) / 10
    addon.Config.UserSettings.critScaleEnd = (self.db.leftSlider2Value or 30) / 10
    addon.Config.UserSettings.critHoldTime = (self.db.leftSlider3Value or 3) / 10  -- 停留时间默认 0.3 秒
    addon.Config.UserSettings.critAnchorX = self.db.leftSlider4Value or 0  -- 锚点X偏移默认 0
    addon.Config.UserSettings.critAnchorY = self.db.leftSlider5Value or 0  -- 锚点Y偏移默认 0
    addon.Config.UserSettings.critRandomX = self.db.leftSlider6Value or 100  -- X轴偏移（暴击随机）默认 100
    
    -- 从 SavedVariables 读取配置（右侧滑块）
    addon.Config.UserSettings.normalFadeDuration = (self.db.rightSlider1Value or 22) / 10  -- 淡出速度默认 2.2 秒
    addon.Config.UserSettings.normalMoveRandom = self.db.rightSlider2Value or 60  -- 浮动速度默认 60（非暴击伤害）
    addon.Config.UserSettings.receivedMoveSpeed = PTURTLE_Combat_DB.receivedMoveSpeed or 110  -- ✅ 队列系统速度默认 110
    addon.Config.UserSettings.queueSpacing = PTURTLE_Combat_DB.queueSpacing or 0  -- ✅ 队列行距默认 0
    addon.Config.UserSettings.queueFontSize = PTURTLE_Combat_DB.queueFontSize or 40  -- ✅ 队列字符大小默认 40
    addon.Config.UserSettings.queueCritScale = PTURTLE_Combat_DB.queueCritScale or 2.0  -- ✅ 队列暴击缩放默认 2.0
    addon.Config.UserSettings.queueCritShakeEnabled = PTURTLE_Combat_DB.queueCritShakeEnabled or 0  -- ✅ 队列暴击震动默认关闭
    addon.Config.UserSettings.baseFontSize = self.db.rightSlider3Value or 50  -- 字符大小默认 50
    addon.Config.UserSettings.normalRandomX = self.db.rightSlider4Value or 80  -- X 分布默认 80
    addon.Config.UserSettings.normalRandomY = self.db.rightSlider5Value or 50  -- Y 分布默认 50
    addon.Config.UserSettings.animASpacing = self.db.rightSlider6Value or 10  -- 行距（动画A）默认 10
    addon.Config.UserSettings.animALifetime = (self.db.rightSlider7Value or 12) / 10  -- 存活时间（动画A）默认 1.2 秒
    addon.Config.UserSettings.charSpacing = self.db.rightSlider8Value or -10  -- 字符间距默认 -10
    addon.Config.UserSettings.digitTextureStyle = self.db.rightSlider9Value or 1  -- 字体样式默认 1
    
    -- -根据存档状态动态注册/注销 DAMAGE_SHIELD_SELF 事件
    if addon.eventFrame then
        if addon.db.reflectionAnimEnabled == 1 then
            addon.eventFrame:RegisterEvent("DAMAGE_SHIELD_SELF")
        else
            addon.eventFrame:UnregisterEvent("DAMAGE_SHIELD_SELF")
        end
    end
end

-- 创建主面板
function addon:CreatePanel()
    if self.panel then return end

    local f = CreateFrame("Frame", "PTURTLE_Combat_Panel", UIParent)
    f:SetWidth(500)
    f:SetHeight(400)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(1)
    f:SetMovable(1)
    f:RegisterForDrag("LeftButton")

    -- -安全检查存档数据
    if self.db and self.db.panelPos and (self.db.panelPos.x ~= 0 or self.db.panelPos.y ~= 0) then
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.panelPos.x, self.db.panelPos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f:SetScript("OnDragStart", function()
        f:StartMoving()
    end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local x, y = f:GetLeft(), f:GetBottom()
        addon.db.panelPos.x = x
        addon.db.panelPos.y = y
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetText("PlayTurtle 控制面板（/PT）")
    title:SetTextColor(1, 1, 1)
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        addon.db.panelVisible = false
        -- 同步
        PTURTLE_Combat_DB.panelVisible = false
        
        -- -面板隐藏时，同时隐藏固定位置指示器
        if addon.fixedPosIndicator then
            addon.fixedPosIndicator:Hide()
        end
        -- -面板隐藏时，AOE计数器设置为透明而不是隐藏，并禁用鼠标
        if addon.aoeCounterFrame then
            addon.aoeCounterFrame:SetAlpha(0)
            addon.aoeCounterFrame:EnableMouse(false)  -- -面板关闭时禁用鼠标
        end
        
        -- 关闭主面板时停止预览模式
        addon:StopPreviewMode()

        if addon.DamageFrame then
            addon.DamageFrame:SetBackdrop(nil)
            addon.DamageFrame:EnableMouse(false)
        end
        if addon.ReceivedHealFrame then
            addon.ReceivedHealFrame:SetBackdrop(nil)
            addon.ReceivedHealFrame:EnableMouse(false)
        end
        if addon.OutputHealFrame then
            addon.OutputHealFrame:SetBackdrop(nil)
            addon.OutputHealFrame:EnableMouse(false)
        end
        -- -队列框架跟随主面板隐藏
        if addon.DOTFrame then
            addon.DOTFrame:SetBackdrop(nil)
            addon.DOTFrame:EnableMouse(false)
        end
        if addon.ReceivedUI then
            if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Hide() end
            if addon.ReceivedUI.startPointDamage then addon.ReceivedUI.startPointDamage:Hide() end
            if addon.ReceivedUI.endPointDamage then addon.ReceivedUI.endPointDamage:Hide() end
            if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Hide() end
            if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Hide() end
            if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Hide() end
            if addon.ReceivedUI.startPointHeal then addon.ReceivedUI.startPointHeal:Hide() end
            if addon.ReceivedUI.endPointHeal then addon.ReceivedUI.endPointHeal:Hide() end
            if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Hide() end
            if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Hide() end
            if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Hide() end
            if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Hide() end
            if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Hide() end
            if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Hide() end
            if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Hide() end
            -- -隐藏 DOT 框架 UI 元素
            if addon.ReceivedUI.labelDOT then addon.ReceivedUI.labelDOT:Hide() end
            if addon.ReceivedUI.startPointDOT then addon.ReceivedUI.startPointDOT:Hide() end
            if addon.ReceivedUI.endPointDOT then addon.ReceivedUI.endPointDOT:Hide() end
            if addon.ReceivedUI.resizeDOT then addon.ReceivedUI.resizeDOT:Hide() end
            if addon.ReceivedUI.handleDOT then addon.ReceivedUI.handleDOT:Hide() end
            -- -隐藏队列框架时，同时隐藏AOE计数器
            if addon.aoeCounterFrame then addon.aoeCounterFrame:Hide() end
        end
    end)
    f.closeBtn = closeBtn

    local btnWidth = 120
    local btnHeight = 24
    local btnSpacing = 15
    local leftColOffsetX = 40  -- 左侧功能按钮X偏移
    local leftColOffsetY = -40

    local btn1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn1:SetWidth(60)  -- 固定宽度，与文字同宽
    btn1:SetHeight(btnHeight)
    btn1:SetPoint("TOPLEFT", f, "TOPLEFT", leftColOffsetX, leftColOffsetY)

    local function updateBtn1Text()
        btn1:SetText(addon.db.showSpellIcon == 1 and "图标关" or "图标开")
    end
    updateBtn1Text()

    btn1:SetScript("OnClick", function()
        addon.db.showSpellIcon = 1 - addon.db.showSpellIcon
        updateBtn1Text()
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 技能图标："..(addon.db.showSpellIcon==1 and "开启" or "关闭"), 1, 1, 1)
    end)
    SetButtonTooltip(btn1, "显示技能图标", "在伤害数字左侧显示技能图标")
    f.btn1 = btn1

    -- 普攻技能图标开关按钮（放在图标关按钮的右侧）
    local autoAttackToggleBtn = CreateFrame("Button", nil, f)
    autoAttackToggleBtn:SetWidth(24)
    autoAttackToggleBtn:SetHeight(24)
    autoAttackToggleBtn:SetPoint("LEFT", btn1, "RIGHT", 5, 0)
    
    -- 设置按钮背景
    autoAttackToggleBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local autoAttackBtnText = autoAttackToggleBtn:CreateFontString(nil, "OVERLAY")
    autoAttackBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    autoAttackBtnText:SetPoint("CENTER", autoAttackToggleBtn, "CENTER", 0, 0)
    
    -- 更新按钮状态函数
    local function updateAutoAttackToggleBtn()
        local isEnabled = addon.db and addon.db.autoAttackIconEnabled or 1
        if isEnabled == 1 then
            -- 开启状态：绿色边框，显示 T
            autoAttackToggleBtn:SetBackdropBorderColor(0, 1, 0, 1)
            autoAttackToggleBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            autoAttackBtnText:SetText("T")
            autoAttackBtnText:SetTextColor(0, 1, 0, 1)
        else
            -- 关闭状态：红色边框，显示 X
            autoAttackToggleBtn:SetBackdropBorderColor(1, 0, 0, 1)
            autoAttackToggleBtn:SetBackdropColor(0.3, 0, 0, 0.5)
            autoAttackBtnText:SetText("X")
            autoAttackBtnText:SetTextColor(1, 0, 0, 1)
        end
    end
    
    -- 初始化按钮状态
    updateAutoAttackToggleBtn()
    
    -- 点击切换
    autoAttackToggleBtn:SetScript("OnClick", function()
        local current = addon.db and addon.db.autoAttackIconEnabled or 1
        addon.db.autoAttackIconEnabled = (current == 1) and 0 or 1
        updateAutoAttackToggleBtn()
    end)
    
    -- Tooltip
    SetButtonTooltip(autoAttackToggleBtn, "普攻图标", "控制普攻是否显示技能图标（包括自动射击）")

    -- 非暴击数字不显示技能图标开关按钮（放在普攻开关按钮的右侧）
    local hideIconNonCritBtn = CreateFrame("Button", nil, f)
    hideIconNonCritBtn:SetWidth(24)
    hideIconNonCritBtn:SetHeight(24)
    hideIconNonCritBtn:SetPoint("LEFT", autoAttackToggleBtn, "RIGHT", 5, 0)
    
    -- 设置按钮背景
    hideIconNonCritBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local hideIconNonCritText = hideIconNonCritBtn:CreateFontString(nil, "OVERLAY")
    hideIconNonCritText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    hideIconNonCritText:SetPoint("CENTER", hideIconNonCritBtn, "CENTER", 0, 0)
    
    -- 更新按钮状态函数
    local function updateHideIconNonCritBtn()
        local isEnabled = addon.db and addon.db.hideIconForNonCrit or 1
        if isEnabled == 1 then
            -- 开启状态：绿色边框，显示 T
            hideIconNonCritBtn:SetBackdropBorderColor(0, 1, 0, 1)
            hideIconNonCritBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            hideIconNonCritText:SetText("T")
            hideIconNonCritText:SetTextColor(0, 1, 0, 1)
        else
            -- 关闭状态：红色边框，显示 X
            hideIconNonCritBtn:SetBackdropBorderColor(1, 0, 0, 1)
            hideIconNonCritBtn:SetBackdropColor(0.3, 0, 0, 0.5)
            hideIconNonCritText:SetText("X")
            hideIconNonCritText:SetTextColor(1, 0, 0, 1)
        end
    end
    
    -- 初始化按钮状态
    updateHideIconNonCritBtn()
    
    -- 点击切换
    hideIconNonCritBtn:SetScript("OnClick", function()
        local current = addon.db and addon.db.hideIconForNonCrit or 1
        addon.db.hideIconForNonCrit = (current == 1) and 0 or 1
        updateHideIconNonCritBtn()
    end)
    
    -- Tooltip
    hideIconNonCritBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(hideIconNonCritBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("非暴击图标", 1, 1, 1)
        GameTooltip:AddLine("当前状态: " .. ((addon.db.hideIconForNonCrit or 1) == 1 and "开启" or "关闭"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("开启时非暴击显示图标，关闭时隐藏", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    hideIconNonCritBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local btn2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn2:SetWidth(btnWidth)
    btn2:SetHeight(btnHeight)
    btn2:SetPoint("TOPLEFT", btn1, "BOTTOMLEFT", 0, -btnSpacing)
    -- 根据配置设置初始文本
    if PTURTLE_Combat_DB and PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED == 0 then
        btn2:SetText("开启奏乐")
    else
        btn2:SetText("关闭奏乐")
    end
    btn2:SetScript("OnClick", function()
        -- 切换奏乐功能开关
        if addon.Config.BOSS_MUSIC_ENABLED == 1 then
            addon.Config.BOSS_MUSIC_ENABLED = 0
            PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED = 0  -- 保存到 SavedVariables
            btn2:SetText("开启奏乐")
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已关闭奏乐功能", 1, 1, 1)
        else
            addon.Config.BOSS_MUSIC_ENABLED = 1
            PTURTLE_Combat_DB.BOSS_MUSIC_ENABLED = 1  -- 保存到 SavedVariables
            btn2:SetText("关闭奏乐")
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已开启奏乐功能", 1, 1, 1)
        end
    end)
    btn2:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn2,"ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("奏乐开关")
        GameTooltip:AddLine("团队下 BOSS 死亡时奏乐", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    btn2:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.btn2 = btn2

    -- ✅ -将震动按钮改为 BC 按钮样式（受暴击震动）
    local beCritShakeBtn = CreateFrame("Button", nil, f)
    beCritShakeBtn:SetWidth(35)  -- BC按钮宽度
    beCritShakeBtn:SetHeight(24)
    beCritShakeBtn:SetPoint("TOPLEFT", btn2, "BOTTOMLEFT", 0, -btnSpacing)
    
    -- 设置按钮背景（与 C 按钮相同）
    beCritShakeBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local beCritShakeBtnText = beCritShakeBtn:CreateFontString(nil, "OVERLAY")
    beCritShakeBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    beCritShakeBtnText:SetPoint("CENTER", beCritShakeBtn, "CENTER", 0, 0)
    
    -- 初始化默认值（默认开启）
    PTURTLE_Combat_DB.beCritShakeEnabled = PTURTLE_Combat_DB.beCritShakeEnabled or 1
    addon.db.beCritShakeEnabled = PTURTLE_Combat_DB.beCritShakeEnabled
    
    -- 更新按钮状态函数
    local function updateBeCritShakeBtn()
        if addon.db.beCritShakeEnabled == 1 then
            -- 开启状态：绿色边框，显示 BC
            beCritShakeBtn:SetBackdropBorderColor(0, 1, 0, 1)
            beCritShakeBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            beCritShakeBtnText:SetText("BC")
            beCritShakeBtnText:SetTextColor(0, 1, 0, 1)
        else
            -- 关闭状态：红色边框，显示 X
            beCritShakeBtn:SetBackdropBorderColor(1, 0, 0, 1)
            beCritShakeBtn:SetBackdropColor(0.3, 0, 0, 0.5)
            beCritShakeBtnText:SetText("X")
            beCritShakeBtnText:SetTextColor(1, 0, 0, 1)
        end
    end
    
    -- 初始化按钮状态
    updateBeCritShakeBtn()
    
    -- BC 按钮点击事件：切换受暴击震动开关
    beCritShakeBtn:SetScript("OnClick", function()
        addon.db.beCritShakeEnabled = (addon.db.beCritShakeEnabled == 1) and 0 or 1
        PTURTLE_Combat_DB.beCritShakeEnabled = addon.db.beCritShakeEnabled
        updateBeCritShakeBtn()
        
        if addon.db.beCritShakeEnabled == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受暴击震动：开启", 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受暴击震动：关闭", 1, 1, 1)
        end
    end)
    
    beCritShakeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(beCritShakeBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("受暴击震动开关", 1, 1, 1)
        GameTooltip:AddLine("控制受到暴击时是否震动", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("当前：" .. (addon.db.beCritShakeEnabled == 1 and "开启" or "关闭"), 1, 1, 0.5)
        if not PTURTLE_Combat.hasUnitXP then
            GameTooltip:AddLine("|cffff0000需要 UnitXP_SP3.dll 支持|r", 1, 0, 0)
        end
        GameTooltip:Show()
    end)
    beCritShakeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.beCritShakeBtn = beCritShakeBtn
    
    -- C 按钮：控制造成暴击是否震动（在 BC 按钮右侧）
    local critShakeBtn = CreateFrame("Button", nil, f)
    critShakeBtn:SetWidth(24)  -- 与 BC 按钮相同
    critShakeBtn:SetHeight(24)
    critShakeBtn:SetPoint("LEFT", beCritShakeBtn, "RIGHT", 4, 0) 
    
    -- 设置按钮背景（与普攻图标开关相同）
    critShakeBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local critShakeBtnText = critShakeBtn:CreateFontString(nil, "OVERLAY")
    critShakeBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    critShakeBtnText:SetPoint("CENTER", critShakeBtn, "CENTER", 0, 0)
    
    -- 初始化默认值（默认关闭）
    PTURTLE_Combat_DB.critShakeEnabled = PTURTLE_Combat_DB.critShakeEnabled or 0
    addon.db.critShakeEnabled = PTURTLE_Combat_DB.critShakeEnabled
    
    -- 更新按钮状态函数（与普攻图标开关相同）
    local function updateCritShakeBtn()
        if addon.db.critShakeEnabled == 1 then
            -- 开启状态：绿色边框，显示 C
            critShakeBtn:SetBackdropBorderColor(0, 1, 0, 1)
            critShakeBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            critShakeBtnText:SetText("C")
            critShakeBtnText:SetTextColor(0, 1, 0, 1)
        else
            -- 关闭状态：红色边框，显示 X
            critShakeBtn:SetBackdropBorderColor(1, 0, 0, 1)
            critShakeBtn:SetBackdropColor(0.3, 0, 0, 0.5)
            critShakeBtnText:SetText("X")
            critShakeBtnText:SetTextColor(1, 0, 0, 1)
        end
    end
    
    -- 初始化按钮状态
    updateCritShakeBtn()
    
    -- C 按钮点击事件：切换暴击震动开关
    critShakeBtn:SetScript("OnClick", function()
        addon.db.critShakeEnabled = (addon.db.critShakeEnabled == 1) and 0 or 1
        PTURTLE_Combat_DB.critShakeEnabled = addon.db.critShakeEnabled
        updateCritShakeBtn()  -- 更新按钮状态
        
        -- 同步到 UserSettings，确保 Display.lua 也能读到最新状态
        if addon.SyncConfigFromDB then
            addon:SyncConfigFromDB()
        end
        
        if addon.db.critShakeEnabled == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 暴击震动：开启", 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 暴击震动：关闭", 1, 1, 1)
        end
    end)
    
    critShakeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(critShakeBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("暴击震动开关", 1, 1, 1)
        GameTooltip:AddLine("控制造成伤害暴击时是否震动", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("当前：" .. (addon.db.critShakeEnabled == 1 and "开启" or "关闭"), 1, 1, 0.5)
        GameTooltip:Show()
    end)
    critShakeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.critShakeBtn = critShakeBtn
    
    -- 震动检查间隔输入框（在 C 按钮右侧）
    local shakeIntervalEdit = addon:CreateEditBox(f, {
        width = 50,  -- 增加宽度以显示更多数字
        height = 24,  -- 高度与按钮对齐
        anchorFrom = "LEFT",
        anchorTo = critShakeBtn,
        anchorRelPoint = "RIGHT",
        offsetX = 5, 
        offsetY = 0,
        fontSize = 12,
        fontFlags = "OUTLINE",
        textColor = {1, 1, 1, 1},
        numeric = true,
        maxLetters = 4,  -- 允许最多4位数字（9999ms）
        hasBorder = true,
        edgeSize = 12,
        borderColorR = 0.6,
        borderColorG = 0.6,
        borderColorB = 0.6,
        placeholder = "ms",
        tooltipTitle = "震动检查间隔",
        tooltipDesc = "设置震动检查的时间间隔（毫秒）\n1秒 = 1000毫秒\n默认值：1000ms",
        onEditFocusLost = function()
            local value = tonumber(this:GetText())
            if value and value > 0 then
                addon.db.shakeCheckInterval = value
                PTURTLE_Combat_DB.shakeCheckInterval = value
                DEFAULT_CHAT_FRAME:AddMessage(string.format("[PlayTurtle] 震动检查间隔：%d ms", value), 1, 1, 1)
            else
                -- 恢复默认值
                this:SetText(tostring(addon.db.shakeCheckInterval or 1000))
            end
        end
    })
    
    -- ESC键清除焦点
    shakeIntervalEdit:SetScript("OnEscapePressed", function()
        shakeIntervalEdit:ClearFocus()
    end)
    
    -- 初始化默认值
    PTURTLE_Combat_DB.shakeCheckInterval = PTURTLE_Combat_DB.shakeCheckInterval or 1000
    addon.db.shakeCheckInterval = PTURTLE_Combat_DB.shakeCheckInterval
    shakeIntervalEdit:SetText(tostring(addon.db.shakeCheckInterval))
    f.shakeIntervalEdit = shakeIntervalEdit

    local btn4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn4:SetWidth(btnWidth)
    btn4:SetHeight(btnHeight)
    btn4:SetPoint("TOPLEFT", beCritShakeBtn, "BOTTOMLEFT", 0, -btnSpacing)
    -- 自动应答按钮
    local function updateAutoReplyBtn()
        if addon.db.autoReplyEnabled == 1 then
            btn4:SetText("关闭自动应答")
        else
            btn4:SetText("开启自动应答")
        end
    end
    updateAutoReplyBtn()
    btn4:SetScript("OnClick", function()
        if f.spellInput then f.spellInput:ClearFocus() end
        if f.shoutInput then f.shoutInput:ClearFocus() end
        if f.thresholdEdit then f.thresholdEdit:ClearFocus() end
        if f.receivedDamageInput then f.receivedDamageInput:ClearFocus() end
        if f.lineDistanceInput then f.lineDistanceInput:ClearFocus() end
        if f.shakeIntervalEdit then f.shakeIntervalEdit:ClearFocus() end
        -- 切换状态：0 变 1，1 变 0
        addon.db.autoReplyEnabled = (addon.db.autoReplyEnabled == 1 or addon.db.autoReplyEnabled == true) and 0 or 1
        updateAutoReplyBtn()
        
        -- 确保保存到 SavedVariables
        PTURTLE_Combat_DB.autoReplyEnabled = addon.db.autoReplyEnabled
        
        if addon.db.autoReplyEnabled == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 自动应答已启用", 1, 1, 1)
            addon:StartAutoReply()
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 自动应答已禁用", 1, 1, 1)
            addon:StopAutoReply()
        end
    end)
    btn4:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn4,"ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("自动应答")
        GameTooltip:AddLine("骷髅级boss战中自动回复密语",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    btn4:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.btn4 = btn4
    
    --  目标连线开关按钮（在自动应答按钮下方）
    local btn5 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn5:SetWidth(btnWidth)
    btn5:SetHeight(btnHeight)
    btn5:SetPoint("TOPLEFT", btn4, "BOTTOMLEFT", 0, -btnSpacing)
    
    -- 初始化默认值（关闭）
    PTURTLE_Combat_DB.targetLineEnabled = PTURTLE_Combat_DB.targetLineEnabled or 0
    addon.db.targetLineEnabled = PTURTLE_Combat_DB.targetLineEnabled
    
    -- 检查 UnitXP 依赖，如果没有则禁用按钮
    if not PTURTLE_Combat.hasUnitXP then
        btn5:Disable()
        btn5:SetText("需要 UnitXP")
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] |cffff0000警告：目标连线功能需要 UnitXP_SP3.dll|r", 1, 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请安装 UnitXP 模组后重新登录以使用此功能", 1, 0.8, 0)
    end
    
    local function UpdateTargetLineBtn()
        -- 检查是否有 UnitXP (UnitXP_X 也包含基础 UnitXP 的所有 API)
        if not PTURTLE_Combat.hasUnitXP then
            btn5:SetText("需要 UnitXP")
            return
        end
        if addon.db.targetLineEnabled == 1 then
            btn5:SetText("关闭目标连线")
        else
            btn5:SetText("开启目标连线")
        end
    end
    UpdateTargetLineBtn()
    
    btn5:SetScript("OnClick", function()
        if f.spellInput then f.spellInput:ClearFocus() end
        if f.shoutInput then f.shoutInput:ClearFocus() end
        if f.thresholdEdit then f.thresholdEdit:ClearFocus() end
        if f.receivedDamageInput then f.receivedDamageInput:ClearFocus() end
        if f.lineDistanceInput then f.lineDistanceInput:ClearFocus() end
        if f.shakeIntervalEdit then f.shakeIntervalEdit:ClearFocus() end
        
        --  检查 UnitXP 依赖 (UnitXP_X 也满足条件)
        if not PTURTLE_Combat.hasUnitXP then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] |cffff0000目标连线需要 UnitXP 支持|r", 1, 0, 0)
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请安装 UnitXP 模组以使用此功能", 1, 0.8, 0)
            return
        end
        
        -- 切换状态
        addon.db.targetLineEnabled = (addon.db.targetLineEnabled == 1 or addon.db.targetLineEnabled == true) and 0 or 1
        UpdateTargetLineBtn()
        
        -- 保存到 SavedVariables
        PTURTLE_Combat_DB.targetLineEnabled = addon.db.targetLineEnabled
        
        if addon.db.targetLineEnabled == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 目标连线已启用", 0, 1, 0)
            -- 重置累积器，让 OnUpdate 立即执行一次
            if GlobalTimer then
                GlobalTimer.lineAccumulator = GlobalTimer.LINE_STEP
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 目标连线已禁用", 1, 0, 0)
            -- 隐藏所有连线点
            if HideAllDots then
                HideAllDots()
            end
        end
    end)
    
    btn5:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn5, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("目标连线")
        GameTooltip:AddLine("在屏幕上显示红点连线", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("从屏幕中心延伸到当前目标", 0.8, 0.8, 0.8)
        if not PTURTLE_Combat.hasUnitXP then
            GameTooltip:AddLine("|cffff0000需要 UnitXP_SP3.dll 支持|r", 1, 0, 0)
        end
        GameTooltip:Show()
    end)
    btn5:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.btn5 = btn5

    -- ===================== 目标连线距离控制输入框 =====================
    
    -- 距离输入框（锚定在 btn5 下方）
    local lineDistanceInput = CreateFrame("EditBox", nil, f)
    lineDistanceInput:SetWidth(40)  -- 缩小宽度
    lineDistanceInput:SetHeight(20)  -- 缩小高度
    lineDistanceInput:SetPoint("TOPLEFT", btn5, "BOTTOMLEFT", 0, -2)  -- 更靠近按钮
    lineDistanceInput:SetFontObject(GameFontNormalSmall)
    lineDistanceInput:SetAutoFocus(false)
    lineDistanceInput:SetMaxLetters(2)  -- 最多 2 位字符（20-41）
    lineDistanceInput:SetJustifyH("CENTER")
    lineDistanceInput:SetTextColor(1, 1, 1, 1)
    lineDistanceInput:EnableMouse(true)
    
    -- 只允许输入数字（失去焦点时验证并限制范围）
    lineDistanceInput:SetScript("OnEditFocusLost", function()
        local text = lineDistanceInput:GetText()
        -- 移除所有非数字字符
        local cleanText = string.gsub(text, "[^0-9]", "")
        
        -- 如果为空，设置默认值 41
        if cleanText == "" then
            lineDistanceInput:SetText("41")
            addon.db.targetLineDistance = 41
            PTURTLE_Combat_DB.targetLineDistance = 41
            return
        end
        
        local value = tonumber(cleanText)
        -- 限制范围 20-41
        if value < 20 then
            value = 20
        elseif value > 41 then
            value = 41
        end
        
        lineDistanceInput:SetText(tostring(value))
        addon.db.targetLineDistance = value
        PTURTLE_Combat_DB.targetLineDistance = value
    end)
    
    -- 添加回车键确认功能
    lineDistanceInput:SetScript("OnEnterPressed", function()
        lineDistanceInput:ClearFocus()  -- 触发 OnEditFocusLost 进行验证和保存
    end)
    
    lineDistanceInput:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            lineDistanceInput:SetFocus()
        end
    end)
    
    -- 创建背景文字（作为占位符背景）
    local lineDistanceBg = lineDistanceInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    lineDistanceBg:SetAllPoints(lineDistanceInput)
    lineDistanceBg:SetJustifyH("CENTER")
    lineDistanceBg:SetText("max")
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    lineDistanceInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            lineDistanceBg:Show()
        else
            lineDistanceBg:Hide()
        end
        
        -- 如果 Tooltip 正在显示，更新当前值
        if GameTooltip:IsOwned(lineDistanceInput) then
            local currentValue = tonumber(this:GetText()) or (addon.db.targetLineDistance or 41)
            GameTooltip:SetText("连线距离设置")
            GameTooltip:AddLine("控制目标连线的最大显示距离", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("当前值：%d 码（范围 20-41）", currentValue), 1, 1, 0)
            GameTooltip:Show()
        end
    end)
    
    -- 设置输入框边框
    lineDistanceInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    lineDistanceInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- 添加 ESC 键清除焦点功能
    lineDistanceInput:SetScript("OnEscapePressed", function()
        lineDistanceInput:ClearFocus()
    end)
    
    -- 添加 Tooltip 提示
    lineDistanceInput:SetScript("OnEnter", function()
        GameTooltip:SetOwner(lineDistanceInput, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("连线距离设置")
        GameTooltip:AddLine("控制目标连线的最大显示距离", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(string.format("当前值：%d 码（范围 20-41）", addon.db.targetLineDistance or 41), 1, 1, 0)
        GameTooltip:Show()
    end)
    lineDistanceInput:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 初始化默认值
    addon.db.targetLineDistance = PTURTLE_Combat_DB.targetLineDistance or 41
    if addon.db.targetLineDistance < 20 then
        addon.db.targetLineDistance = 20
    elseif addon.db.targetLineDistance > 41 then
        addon.db.targetLineDistance = 41
    end
    lineDistanceInput:SetText(tostring(addon.db.targetLineDistance))
    
    f.lineDistanceInput = lineDistanceInput

    -- ===================== 连线红点大小控制输入框 =====================
    
    -- 红点大小输入框（锚定在 lineDistanceInput 右侧）
    local dotSizeInput = CreateFrame("EditBox", nil, f)
    dotSizeInput:SetWidth(40)  -- 缩小宽度
    dotSizeInput:SetHeight(20)  -- 缩小高度
    dotSizeInput:SetPoint("LEFT", lineDistanceInput, "RIGHT", 40, 0)  -- 在距离输入框右侧
    dotSizeInput:SetFontObject(GameFontNormalSmall)
    dotSizeInput:SetAutoFocus(false)
    dotSizeInput:SetMaxLetters(1)  -- 最多 1 位字符（2-4）
    dotSizeInput:SetJustifyH("CENTER")
    dotSizeInput:SetTextColor(1, 1, 1, 1)
    dotSizeInput:EnableMouse(true)
    
    -- 只允许输入数字（失去焦点时验证并限制范围）
    dotSizeInput:SetScript("OnEditFocusLost", function()
        local text = dotSizeInput:GetText()
        -- 移除所有非数字字符
        local cleanText = string.gsub(text, "[^0-9]", "")
        
        -- 转换为数字
        local value = tonumber(cleanText)
        
        -- 如果不是2、3或4，则清空输入框并使用默认值2
        if value ~= 2 and value ~= 3 and value ~= 4 then
            dotSizeInput:SetText("")  -- 清空输入框
            addon.db.targetLineDotSize = 2
            PTURTLE_Combat_DB.targetLineDotSize = 2
            return
        end
        
        dotSizeInput:SetText(tostring(value))
        addon.db.targetLineDotSize = value
        PTURTLE_Combat_DB.targetLineDotSize = value
        
        -- 重新初始化连线池以应用新的大小
        if addon.ResetLinePool and addon.InitLinePool then
            addon:ResetLinePool()  -- 清空现有池子
            addon:InitLinePool()   -- 用新大小重新创建
        end
    end)
    
    -- 添加回车键确认功能
    dotSizeInput:SetScript("OnEnterPressed", function()
        dotSizeInput:ClearFocus()  -- 触发 OnEditFocusLost 进行验证和保存
    end)
    
    dotSizeInput:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            dotSizeInput:SetFocus()
        end
    end)
    
    -- 创建背景文字（作为占位符背景）
    local dotSizeBg = dotSizeInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    dotSizeBg:SetAllPoints(dotSizeInput)
    dotSizeBg:SetJustifyH("CENTER")
    dotSizeBg:SetText("size")
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    dotSizeInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            dotSizeBg:Show()
        else
            dotSizeBg:Hide()
        end
        
        -- 如果 Tooltip 正在显示，更新当前值
        if GameTooltip:IsOwned(dotSizeInput) then
            local currentValue = tonumber(this:GetText())
            if not currentValue then
                if addon.db.targetLineDotSize and type(addon.db.targetLineDotSize) == "number" then
                    currentValue = addon.db.targetLineDotSize
                else
                    currentValue = 2
                end
            end
            GameTooltip:SetText("连线红点大小")
            GameTooltip:AddLine("控制连线中间红点的大小", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format("当前值：%d 像素（范围 2-4）", currentValue), 1, 1, 0)
            GameTooltip:Show()
        end
    end)
    
    -- 设置输入框边框
    dotSizeInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    dotSizeInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- 添加 ESC 键清除焦点功能
    dotSizeInput:SetScript("OnEscapePressed", function()
        dotSizeInput:ClearFocus()
    end)
    
    -- 添加 Tooltip 提示
    dotSizeInput:SetScript("OnEnter", function()
        GameTooltip:SetOwner(dotSizeInput, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("连线红点大小")
        GameTooltip:AddLine("控制连线中间红点的大小", 0.8, 0.8, 0.8)
        
        -- 安全获取当前值
        local currentValue = 2
        if addon.db.targetLineDotSize then
            if type(addon.db.targetLineDotSize) == "number" then
                currentValue = addon.db.targetLineDotSize
            elseif type(addon.db.targetLineDotSize) == "string" then
                currentValue = tonumber(addon.db.targetLineDotSize) or 2
            end
        end
        
        GameTooltip:AddLine(string.format("当前值：%d 像素（范围 2-4）", currentValue), 1, 1, 0)
        GameTooltip:Show()
    end)
    dotSizeInput:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 初始化默认值
    local defaultDotSize = 2
    if PTURTLE_Combat_DB.targetLineDotSize then
        if type(PTURTLE_Combat_DB.targetLineDotSize) == "number" then
            defaultDotSize = PTURTLE_Combat_DB.targetLineDotSize
        elseif type(PTURTLE_Combat_DB.targetLineDotSize) == "string" then
            defaultDotSize = tonumber(PTURTLE_Combat_DB.targetLineDotSize) or 2
        end
    end
    
    addon.db.targetLineDotSize = defaultDotSize
    -- 只接受2、3、4，其他值使用默认值2
    if addon.db.targetLineDotSize ~= 2 and addon.db.targetLineDotSize ~= 3 and addon.db.targetLineDotSize ~= 4 then
        addon.db.targetLineDotSize = 2
    end
    dotSizeInput:SetText(tostring(addon.db.targetLineDotSize))
    
    f.dotSizeInput = dotSizeInput

    local textBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    textBtn:SetWidth(btnWidth)
    textBtn:SetHeight(btnHeight)
    textBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -leftColOffsetX, leftColOffsetY)
    textBtn:SetText("文字设置")
    textBtn:SetScript("OnClick", function()
        if not addon.subPanel then addon:CreateSubPanel() end
        f:Hide()
        addon.subPanel:ClearAllPoints()
        addon.subPanel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", f:GetLeft(), f:GetBottom())
        addon.subPanel:Show()
        
        -- 如果不在战斗中且队列模式关闭，启动预览模式
        if not addon.playerInCombat and (addon.db.dotQueueEnabled ~= 1) then
            addon:StartPreviewMode()
        end
    end)
    textBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(textBtn,"ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("文字设置")
        GameTooltip:AddLine("打开文字调整面板",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    textBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.textBtn = textBtn

    -- ========== 中间区域：战斗动画控制开关 ==========
    local middleColOffsetX = 180  -- 中间列X偏移
    local checkboxSpacing = 15    -- 勾选框行间距（与左列btnSpacing保持一致）
    local checkboxStartY = -40    -- 起始Y位置（与左右列对齐）

    -- 初始化配置（如果不存在）
    PTURTLE_Combat_DB.damageAnimEnabled = PTURTLE_Combat_DB.damageAnimEnabled or 0  -- 受伤动画开关（默认关闭）
    PTURTLE_Combat_DB.receivedHealAnimEnabled = PTURTLE_Combat_DB.receivedHealAnimEnabled or 0  -- 受治疗动画开关（默认关闭）
    PTURTLE_Combat_DB.outputHealAnimEnabled = PTURTLE_Combat_DB.outputHealAnimEnabled or 1
    PTURTLE_Combat_DB.reflectionAnimEnabled = PTURTLE_Combat_DB.reflectionAnimEnabled or 1  -- 反弹动画开关
    PTURTLE_Combat_DB.energizeAnimEnabled = PTURTLE_Combat_DB.energizeAnimEnabled or 0  -- 能量回复动画开关（默认关闭）
    PTURTLE_Combat_DB.showPlusSign = PTURTLE_Combat_DB.showPlusSign or 0  -- + 号显示开关（默认关闭）
    PTURTLE_Combat_DB.showMinusSign = PTURTLE_Combat_DB.showMinusSign or 0  -- - 号显示开关（默认关闭）
    addon.db.damageAnimEnabled = PTURTLE_Combat_DB.damageAnimEnabled
    addon.db.receivedHealAnimEnabled = PTURTLE_Combat_DB.receivedHealAnimEnabled
    addon.db.outputHealAnimEnabled = PTURTLE_Combat_DB.outputHealAnimEnabled
    addon.db.reflectionAnimEnabled = PTURTLE_Combat_DB.reflectionAnimEnabled
    addon.db.energizeAnimEnabled = PTURTLE_Combat_DB.energizeAnimEnabled
    addon.db.showPlusSign = PTURTLE_Combat_DB.showPlusSign
    addon.db.showMinusSign = PTURTLE_Combat_DB.showMinusSign


    -- 第1行：受伤动画开关
    local damageCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    damageCheckbox:SetWidth(24)
    damageCheckbox:SetHeight(24)
    damageCheckbox:SetPoint("TOPLEFT", f, "TOPLEFT", middleColOffsetX, checkboxStartY)
    damageCheckbox:SetChecked(addon.db.damageAnimEnabled == 1)
    
    local damageCheckboxText = damageCheckbox:CreateFontString(nil, "OVERLAY")
    damageCheckboxText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    damageCheckboxText:SetPoint("LEFT", damageCheckbox, "RIGHT", 5, 0)
    damageCheckboxText:SetText("受伤开")
    damageCheckboxText:SetTextColor(1, 0.2, 0.2)
    
    damageCheckbox:SetScript("OnClick", function()
        addon.db.damageAnimEnabled = damageCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.damageAnimEnabled = addon.db.damageAnimEnabled
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受伤动画：" .. (addon.db.damageAnimEnabled == 1 and "开启" or "关闭"), 1, 1, 1)
    end)
    damageCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(damageCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("受伤动画开关", 1, 1, 1)
        GameTooltip:AddLine("控制受到伤害时的数字动画显示", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    damageCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.damageCheckbox = damageCheckbox

    -- 受伤显示按钮
    local damageShowBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    damageShowBtn:SetWidth(60)
    damageShowBtn:SetHeight(20)
    damageShowBtn:SetPoint("LEFT", damageCheckboxText, "RIGHT", 10, 0)
    damageShowBtn:SetText("编辑")
    
    -- - 不保存状态，每次重载UI都默认隐藏
    local damageUIVisible = false
    
    -- - 初始化时隐藏框架（保持框架显示以维持锚点，只隐藏背景和子元素）
    if addon.DamageFrame then
        addon.DamageFrame:SetBackdrop(nil)
    end
    if addon.ReceivedUI then
        if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Hide() end
        if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Hide() end
        if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Hide() end
    end
    
    damageShowBtn:SetScript("OnClick", function()
        if addon.DamageFrame and addon.ReceivedUI then
            if damageUIVisible then
                -- 隐藏所有UI元素
                if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Hide() end
                if addon.ReceivedUI.startPointDamage then addon.ReceivedUI.startPointDamage:Hide() end
                if addon.ReceivedUI.endPointDamage then addon.ReceivedUI.endPointDamage:Hide() end
                if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Hide() end
                if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Hide() end
                addon.DamageFrame:SetBackdrop(nil)
                addon.DamageFrame:EnableMouse(false)  -- - 禁用鼠标交互
                damageUIVisible = false
                
                -- -如果所有框体都隐藏了，停止预览模式
                local allHidden = true
                if addon.ReceivedUI and addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown() then
                    allHidden = false
                end
                if allHidden then
                    addon:StopPreviewMode()
                end
            else
                -- 恢复所有UI元素
                if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Show() end
                if addon.ReceivedUI.startPointDamage then addon.ReceivedUI.startPointDamage:Show() end
                if addon.ReceivedUI.endPointDamage then addon.ReceivedUI.endPointDamage:Show() end
                if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Show() end
                if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Show() end
                addon.DamageFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = 1, tileSize = 16, edgeSize = 16,
                    insets = { left=4, right=4, top=4, bottom=4 }
                })
                addon.DamageFrame:SetBackdropColor(0, 0, 0, 0.7)
                addon.DamageFrame:SetBackdropBorderColor(1, 0.2, 0.2, 1)
                addon.DamageFrame:EnableMouse(true)  -- - 启用鼠标交互
                damageUIVisible = true
                
                -- -受伤框体不需要启动预览模式，由 OnUpdate 自动检测
            end
        end
    end)
    damageShowBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(damageShowBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("显示/隐藏受伤框架", 1, 1, 1)
        GameTooltip:AddLine("用于调整滑块位置", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    damageShowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.damageShowBtn = damageShowBtn

    -- 第2行：受治疗动画开关
    local receivedHealCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    receivedHealCheckbox:SetWidth(24)
    receivedHealCheckbox:SetHeight(24)
    receivedHealCheckbox:SetPoint("TOPLEFT", damageCheckbox, "BOTTOMLEFT", 0, -checkboxSpacing)
    receivedHealCheckbox:SetChecked(addon.db.receivedHealAnimEnabled == 1)
    
    local receivedHealCheckboxText = receivedHealCheckbox:CreateFontString(nil, "OVERLAY")
    receivedHealCheckboxText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    receivedHealCheckboxText:SetPoint("LEFT", receivedHealCheckbox, "RIGHT", 5, 0)
    receivedHealCheckboxText:SetText("受疗开")
    receivedHealCheckboxText:SetTextColor(0.2, 1, 0.2)
    
    receivedHealCheckbox:SetScript("OnClick", function()
        addon.db.receivedHealAnimEnabled = receivedHealCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.receivedHealAnimEnabled = addon.db.receivedHealAnimEnabled
        
        -- 动态注册/注销 SPELL_HEAL_ON_SELF 和 SPELL_ENERGIZE_ON_SELF 事件
        if addon.eventFrame then
            if addon.db.receivedHealAnimEnabled == 1 then
                addon.eventFrame:RegisterEvent("SPELL_HEAL_ON_SELF")
                addon.eventFrame:RegisterEvent("SPELL_ENERGIZE_ON_SELF")
            else
                addon.eventFrame:UnregisterEvent("SPELL_HEAL_ON_SELF")
                addon.eventFrame:UnregisterEvent("SPELL_ENERGIZE_ON_SELF")
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受治疗/能量动画：" .. (addon.db.receivedHealAnimEnabled == 1 and "开启" or "关闭"), 1, 1, 1)
    end)
    receivedHealCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(receivedHealCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("受治疗动画开关", 1, 1, 1)
        GameTooltip:AddLine("控制受到治疗/能量的数字动画显示", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    receivedHealCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.receivedHealCheckbox = receivedHealCheckbox

    -- 受治疗显示按钮
    local receivedHealShowBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    receivedHealShowBtn:SetWidth(60)
    receivedHealShowBtn:SetHeight(20)
    receivedHealShowBtn:SetPoint("LEFT", receivedHealCheckboxText, "RIGHT", 10, 0)
    receivedHealShowBtn:SetText("编辑")
    
    -- - 不保存状态，每次重载UI都默认隐藏
    local receivedHealUIVisible = false
    
    -- - 初始化时隐藏框架（保持框架显示以维持锚点，只隐藏背景和子元素）
    if addon.ReceivedHealFrame then
        addon.ReceivedHealFrame:SetBackdrop(nil)
    end
    if addon.ReceivedUI then
        if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Hide() end
        if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Hide() end
        if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Hide() end
    end
    
    receivedHealShowBtn:SetScript("OnClick", function()
        if addon.ReceivedHealFrame and addon.ReceivedUI then
            if receivedHealUIVisible then
                -- 隐藏所有UI元素
                if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Hide() end
                if addon.ReceivedUI.startPointHeal then addon.ReceivedUI.startPointHeal:Hide() end
                if addon.ReceivedUI.endPointHeal then addon.ReceivedUI.endPointHeal:Hide() end
                if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Hide() end
                if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Hide() end
                addon.ReceivedHealFrame:SetBackdrop(nil)
                addon.ReceivedHealFrame:EnableMouse(false)  -- - 禁用鼠标交互
                receivedHealUIVisible = false
                
                -- -如果所有框体都隐藏了，停止预览模式
                local allHidden = true
                if addon.ReceivedUI and addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown() then
                    allHidden = false
                end
                if allHidden then
                    addon:StopPreviewMode()
                end
            else
                -- 恢复所有UI元素
                if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Show() end
                if addon.ReceivedUI.startPointHeal then addon.ReceivedUI.startPointHeal:Show() end
                if addon.ReceivedUI.endPointHeal then addon.ReceivedUI.endPointHeal:Show() end
                if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Show() end
                if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Show() end
                addon.ReceivedHealFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = 1, tileSize = 16, edgeSize = 16,
                    insets = { left=4, right=4, top=4, bottom=4 }
                })
                addon.ReceivedHealFrame:SetBackdropColor(0, 0, 0, 0.7)
                addon.ReceivedHealFrame:SetBackdropBorderColor(0.2, 1, 0.2, 1)  -- - 绿色边框（受到治疗）
                addon.ReceivedHealFrame:EnableMouse(true)  -- - 启用鼠标交互
                receivedHealUIVisible = true
                
                -- -受治疗框体不需要启动预览模式，由 OnUpdate 自动检测
            end
        end
    end)
    receivedHealShowBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(receivedHealShowBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("显示/隐藏受治疗框架", 1, 1, 1)
        GameTooltip:AddLine("用于调整滑块位置", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    receivedHealShowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.receivedHealShowBtn = receivedHealShowBtn

    -- DOT 框架显示按钮（紫色边框）
    local dotShowBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    dotShowBtn:SetWidth(60)  -- 与其他编辑按钮保持一致
    dotShowBtn:SetHeight(20)  -- 与其他编辑按钮保持一致
    -- 注意：energizeCheckboxText 在后面定义，这里先占位，稍后在 energizeCheckbox 定义后重新设置锚点
    dotShowBtn:SetPoint("LEFT", receivedHealShowBtn, "RIGHT", 10, 0)  -- 临时锚点
    dotShowBtn:SetText("编辑")
    
    -- 不保存状态，每次重载UI都默认隐藏（通过 alpha 控制可见度）
    local dotUIVisible = false
    
    -- 初始化时隐藏框架元素（使用 Hide）
    if addon.ReceivedUI then
        if addon.ReceivedUI.labelDOT then addon.ReceivedUI.labelDOT:Hide() end
        if addon.ReceivedUI.startPointDOT then addon.ReceivedUI.startPointDOT:Hide() end
        if addon.ReceivedUI.endPointDOT then addon.ReceivedUI.endPointDOT:Hide() end
        if addon.ReceivedUI.resizeDOT then addon.ReceivedUI.resizeDOT:Hide() end
        -- DOT 框架不需要路径手柄，保持隐藏
        if addon.ReceivedUI.handleDOT then addon.ReceivedUI.handleDOT:Hide() end
    end
    
    dotShowBtn:SetScript("OnClick", function()
        -- 核心修复：只有队列模式开启时才能编辑伤害队列框架
        if not (addon.db and addon.db.dotQueueEnabled == 1) then
            return  -- 队列模式关闭时，按钮不可点击
        end
        
        if addon.DOTFrame and addon.ReceivedUI then
            if dotUIVisible then
                -- 隐藏所有UI元素（使用 Hide）
                if addon.ReceivedUI.labelDOT then addon.ReceivedUI.labelDOT:Hide() end
                if addon.ReceivedUI.startPointDOT then addon.ReceivedUI.startPointDOT:Hide() end
                if addon.ReceivedUI.endPointDOT then addon.ReceivedUI.endPointDOT:Hide() end
                if addon.ReceivedUI.resizeDOT then addon.ReceivedUI.resizeDOT:Hide() end
                if addon.ReceivedUI.handleDOT then addon.ReceivedUI.handleDOT:Hide() end
                -- -隐藏队列框架时，同时隐藏AOE计数器
                if addon.aoeCounterFrame then addon.aoeCounterFrame:Hide() end
                addon.DOTFrame:SetBackdrop(nil)
                addon.DOTFrame:EnableMouse(false)
                dotUIVisible = false
                
                -- -如果所有框体都隐藏了，停止预览模式
                local allHidden = true
                if addon.ReceivedUI and addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelDOT and addon.ReceivedUI.labelDOT:IsShown() then
                    allHidden = false
                end
                if allHidden then
                    addon:StopPreviewMode()
                end
            else
                -- 显示所有UI元素（使用 Show）
                if addon.ReceivedUI.labelDOT then addon.ReceivedUI.labelDOT:Show() end
                if addon.ReceivedUI.startPointDOT then addon.ReceivedUI.startPointDOT:Show() end
                if addon.ReceivedUI.endPointDOT then addon.ReceivedUI.endPointDOT:Show() end
                if addon.ReceivedUI.resizeDOT then addon.ReceivedUI.resizeDOT:Show() end
                if addon.ReceivedUI.handleDOT then addon.ReceivedUI.handleDOT:Show() end
                -- -显示队列框架时，同时显示AOE计数器并设置测试数字999
                if addon.aoeCounterFrame then
                    addon:ShowAOECounterTestDisplay()
                end
                addon.DOTFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = 1, tileSize = 16, edgeSize = 16,
                    insets = { left=4, right=4, top=4, bottom=4 }
                })
                addon.DOTFrame:SetBackdropColor(0, 0, 0, 0.7)
                addon.DOTFrame:SetBackdropBorderColor(0.8, 0.2, 0.8, 1)  -- 紫色边框（DOT）
                addon.DOTFrame:EnableMouse(true)
                dotUIVisible = true
            end
        end
    end)
    dotShowBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(dotShowBtn, "ANCHOR_BOTTOMRIGHT")
        if addon.db and addon.db.dotQueueEnabled == 1 then
            -- 队列模式开启：显示正常提示
            GameTooltip:SetText("显示/隐藏伤害队列框架", 1, 1, 1)
            GameTooltip:AddLine("用于调整队列框架位置", 0.8, 0.8, 0.8)
        else
            -- 队列模式关闭：显示红色警告提示
            GameTooltip:SetText("显示/隐藏伤害队列框架", 1, 0.3, 0.3)  -- 红色标题
            GameTooltip:AddLine("必须打开队列模式才可开启编辑", 1, 0.3, 0.3)  -- 红色文字
        end
        GameTooltip:Show()
    end)
    dotShowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.dotShowBtn = dotShowBtn

    -- 第3行：输出治疗动画开关
    local outputHealCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    outputHealCheckbox:SetWidth(24)
    outputHealCheckbox:SetHeight(24)
    outputHealCheckbox:SetPoint("TOPLEFT", receivedHealCheckbox, "BOTTOMLEFT", 0, -checkboxSpacing)
    outputHealCheckbox:SetChecked(addon.db.outputHealAnimEnabled == 1)
    
    local outputHealCheckboxText = outputHealCheckbox:CreateFontString(nil, "OVERLAY")
    outputHealCheckboxText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    outputHealCheckboxText:SetPoint("LEFT", outputHealCheckbox, "RIGHT", 5, 0)
    outputHealCheckboxText:SetText("治疗开")
    outputHealCheckboxText:SetTextColor(0.2, 0.6, 1)
    
    outputHealCheckbox:SetScript("OnClick", function()
        addon.db.outputHealAnimEnabled = outputHealCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.outputHealAnimEnabled = addon.db.outputHealAnimEnabled
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 输出治疗动画：" .. (addon.db.outputHealAnimEnabled == 1 and "开启（队列模式）" or "关闭（淡出模式）"), 1, 1, 1)
    end)
    outputHealCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(outputHealCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("输出治疗动画开关", 1, 1, 1)
        GameTooltip:AddLine("控制输出治疗时的数字动画显示", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    outputHealCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.outputHealCheckbox = outputHealCheckbox

    -- 输出治疗显示按钮
    local outputHealShowBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    outputHealShowBtn:SetWidth(60)
    outputHealShowBtn:SetHeight(20)
    outputHealShowBtn:SetPoint("LEFT", outputHealCheckboxText, "RIGHT", 10, 0)
    outputHealShowBtn:SetText("编辑")
    
    -- - 不保存状态，每次重载UI都默认隐藏
    local outputHealUIVisible = false
    
    -- - 初始化时隐藏框架（保持框架显示以维持锚点，只隐藏背景和子元素）
    if addon.OutputHealFrame then
        addon.OutputHealFrame:SetBackdrop(nil)
    end
    if addon.ReceivedUI then
        if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Hide() end
        if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Hide() end
        if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Hide() end
        if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Hide() end
        if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Hide() end
    end
    
    outputHealShowBtn:SetScript("OnClick", function()
        if addon.OutputHealFrame and addon.ReceivedUI then
            if outputHealUIVisible then
                -- 隐藏所有UI元素
                if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Hide() end
                if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Hide() end
                if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Hide() end
                if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Hide() end
                if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Hide() end
                addon.OutputHealFrame:SetBackdrop(nil)
                addon.OutputHealFrame:EnableMouse(false)  -- - 禁用鼠标交互
                outputHealUIVisible = false
                
                -- -如果所有框体都隐藏了，停止预览模式
                local allHidden = true
                if addon.ReceivedUI and addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown() then
                    allHidden = false
                end
                if addon.ReceivedUI and addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown() then
                    allHidden = false
                end
                if allHidden then
                    addon:StopPreviewMode()
                end
            else
                -- 恢复所有UI元素
                if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Show() end
                if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Show() end
                if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Show() end
                if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Show() end
                if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Show() end
                addon.OutputHealFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = 1, tileSize = 16, edgeSize = 16,
                    insets = { left=4, right=4, top=4, bottom=4 }
                })
                addon.OutputHealFrame:SetBackdropColor(0, 0, 0, 0.7)
                addon.OutputHealFrame:SetBackdropBorderColor(0.2, 0.6, 1, 1)
                addon.OutputHealFrame:EnableMouse(true)  -- - 启用鼠标交互
                outputHealUIVisible = true
                
                -- -输出治疗框体不需要启动预览模式，由 OnUpdate 自动检测
            end
        end
    end)
    outputHealShowBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(outputHealShowBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("显示/隐藏输出治疗框架", 1, 1, 1)
        GameTooltip:AddLine("用于调整滑块位置", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    outputHealShowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.outputHealShowBtn = outputHealShowBtn

    local energizeCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    energizeCheckbox:SetWidth(24)
    energizeCheckbox:SetHeight(24)
    energizeCheckbox:SetPoint("TOPLEFT", outputHealCheckbox, "BOTTOMLEFT", 0, -checkboxSpacing)  
    energizeCheckbox:SetChecked(addon.db.dotQueueEnabled == 1)  -- -使用独立的dotQueueEnabled变量
    
    local energizeCheckboxText = energizeCheckbox:CreateFontString(nil, "OVERLAY")
    energizeCheckboxText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    energizeCheckboxText:SetPoint("LEFT", energizeCheckbox, "RIGHT", 5, 0)
    energizeCheckboxText:SetText("队列模式")
    energizeCheckboxText:SetTextColor(0.8, 0.2, 0.8)  -- 紫色文字表示队列模式
    
    energizeCheckbox:SetScript("OnClick", function()
        addon.db.dotQueueEnabled = energizeCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.dotQueueEnabled = addon.db.dotQueueEnabled
        
        -- 核心优化：重置动画槽位父级，避免每次调用都设置父级
        if addon.ResetAniPoolParent then
            addon:ResetAniPoolParent()
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 队列模式：" .. (addon.db.dotQueueEnabled == 1 and "开启（所有伤害进入队列）" or "关闭（优先姓名板）"), 1, 1, 1)
    end)
    energizeCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(energizeCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("队列模式开关", 1, 1, 1)
        GameTooltip:AddLine("开启：所有伤害无视姓名板，全部在队列框架中排队显示", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("关闭：伤害优先显示在姓名板上，其次回退固定位置", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    energizeCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.energizeCheckbox = energizeCheckbox
    
    -- -将 DOT 编辑按钮重新锚定到 DOT 勾选框右侧，固定位置
    if dotShowBtn then
        dotShowBtn:ClearAllPoints()
        dotShowBtn:SetPoint("LEFT", energizeCheckbox, "RIGHT", 62, 0)  -- 锚定到 DOT 勾选框右侧，固定间距62像素（原60+2）
    end

    -- 反伤动画开关 - 放在 DOT 下方
    local reflectionCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    reflectionCheckbox:SetWidth(24)
    reflectionCheckbox:SetHeight(24)
    reflectionCheckbox:SetPoint("TOPLEFT", energizeCheckbox, "BOTTOMLEFT", 0, -checkboxSpacing)  -- 放在 DOT 下方
    reflectionCheckbox:SetChecked(addon.db.reflectionAnimEnabled == 1)
    
    local reflectionCheckboxText = reflectionCheckbox:CreateFontString(nil, "OVERLAY")
    reflectionCheckboxText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    reflectionCheckboxText:SetPoint("LEFT", reflectionCheckbox, "RIGHT", 5, 0)
    reflectionCheckboxText:SetText("反伤开")
    reflectionCheckboxText:SetTextColor(1, 1, 1)  -- 白色文字
    
    reflectionCheckbox:SetScript("OnClick", function()
        addon.db.reflectionAnimEnabled = reflectionCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.reflectionAnimEnabled = addon.db.reflectionAnimEnabled
        
        -- 动态注册/注销 DAMAGE_SHIELD_SELF 事件
        if addon.eventFrame then
            if addon.db.reflectionAnimEnabled == 1 then
                addon.eventFrame:RegisterEvent("DAMAGE_SHIELD_SELF")
            else
                addon.eventFrame:UnregisterEvent("DAMAGE_SHIELD_SELF")
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 反伤动画：" .. (addon.db.reflectionAnimEnabled == 1 and "开启" or "关闭"), 1, 1, 1)
    end)
    reflectionCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(reflectionCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("反伤动画开关", 1, 1, 1)
        GameTooltip:AddLine("控制反伤盾等反伤事件的数字动画显示", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    reflectionCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.reflectionCheckbox = reflectionCheckbox

    --  -将 +/- 拆分为两个独立开关
    -- + 号显示开关（控制受治疗/输出治疗的 + 符号）
    -- - 号显示开关（控制受伤的 - 符号）
    local minusCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    minusCheckbox:SetWidth(24)
    minusCheckbox:SetHeight(24)
    minusCheckbox:SetPoint("LEFT", reflectionCheckbox, "RIGHT", 50, 0)  -- 放在反伤开按钮右侧
    minusCheckbox:SetChecked(addon.db.showMinusSign == 1)
    
    local minusCheckboxText = minusCheckbox:CreateFontString(nil, "OVERLAY")
    minusCheckboxText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")  -- 放大字体
    minusCheckboxText:SetPoint("LEFT", minusCheckbox, "RIGHT", 5, 0)
    minusCheckboxText:SetText("-")
    minusCheckboxText:SetTextColor(1, 0, 0)  -- 红色
    
    minusCheckbox:SetScript("OnClick", function()
        addon.db.showMinusSign = minusCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.showMinusSign = addon.db.showMinusSign
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] - 号显示：" .. (addon.db.showMinusSign == 1 and "开启" or "关闭"), 1, 1, 1)
    end)
    minusCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minusCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("- 号显示开关", 1, 1, 1)
        GameTooltip:AddLine("控制受伤的 - 符号显示（红色）", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    minusCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.minusCheckbox = minusCheckbox
    
    -- + 号显示开关（控制受治疗、输出治疗的 + 符号）
    local plusCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    plusCheckbox:SetWidth(24)
    plusCheckbox:SetHeight(24)
    plusCheckbox:SetPoint("TOPLEFT", minusCheckbox, "BOTTOMLEFT", 0, -checkboxSpacing)  -- 放在 - 号的下方
    plusCheckbox:SetChecked(addon.db.showPlusSign == 1)
    
    local plusCheckboxText = plusCheckbox:CreateFontString(nil, "OVERLAY")
    plusCheckboxText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")  -- 放大字体
    plusCheckboxText:SetPoint("LEFT", plusCheckbox, "RIGHT", 5, 0)
    plusCheckboxText:SetText("+")
    plusCheckboxText:SetTextColor(0, 1, 0)  -- 绿色
    
    plusCheckbox:SetScript("OnClick", function()
        addon.db.showPlusSign = plusCheckbox:GetChecked() and 1 or 0
        PTURTLE_Combat_DB.showPlusSign = addon.db.showPlusSign
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] + 号显示：" .. (addon.db.showPlusSign == 1 and "开启" or "关闭"), 1, 1, 1)
    end)
    plusCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(plusCheckbox, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("+ 号显示开关", 1, 1, 1)
        GameTooltip:AddLine("控制受治疗、输出治疗的 + 符号显示（绿色）", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    plusCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.plusCheckbox = plusCheckbox

    local fixedPosBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    fixedPosBtn:SetWidth(btnWidth)
    fixedPosBtn:SetHeight(btnHeight)
    fixedPosBtn:SetPoint("TOPRIGHT", textBtn, "BOTTOMRIGHT",0,-btnSpacing)
    
    -- -更新按钮文字
    local function updateFixedBtn()
        local isEnabled = (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true)
        local btnText = isEnabled and "固定位置开" or "固定位置关"
        fixedPosBtn:SetText(btnText)
    end
    updateFixedBtn()
    fixedPosBtn:SetScript("OnClick", function()
        if f.spellInput then f.spellInput:ClearFocus() end
        if f.shoutInput then f.shoutInput:ClearFocus() end
        if f.thresholdEdit then f.thresholdEdit:ClearFocus() end
        if f.receivedDamageInput then f.receivedDamageInput:ClearFocus() end
        if f.lineDistanceInput then f.lineDistanceInput:ClearFocus() end
        -- -切换开关状态（处理 0/1 和 false/true 两种情况）
        local currentEnabled = (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true)
        addon.db.fixedPosEnabled = currentEnabled and 0 or 1
        -- 同步到 PTURTLE_Combat_DB（SavedVariables）
        PTURTLE_Combat_DB.fixedPosEnabled = addon.db.fixedPosEnabled
        updateFixedBtn()
        if addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true then
            -- 启用固定位置时，显示指示器（如果面板打开）
            if addon.fixedPosIndicator and addon.db.panelVisible then
                addon.fixedPosIndicator:Show()
            end
        else
            -- 禁用固定位置时，隐藏玩家指示器
            if addon.fixedPosIndicator then 
                addon.fixedPosIndicator:Hide() 
            end
        end
    end)
    fixedPosBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(fixedPosBtn,"ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("固定位置")
        GameTooltip:AddLine("伤害数字固定显示位置",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    fixedPosBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.fixedPosBtn = fixedPosBtn

    -- -列表类型选择按钮（技能过滤表 / 合并AOE表）
    local listTypeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    listTypeBtn:SetWidth(90)
    listTypeBtn:SetHeight(btnHeight)
    listTypeBtn:SetPoint("TOPRIGHT", fixedPosBtn, "BOTTOMRIGHT", 0, -btnSpacing)
    listTypeBtn:SetText("技能过滤表")  -- 默认显示
    
    -- 当前选择的类型
    addon._currentListType = addon._currentListType or "filter"
    
    listTypeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")  -- 注册左右键
    listTypeBtn:SetScript("OnClick", function()
        if f.spellInput then f.spellInput:ClearFocus() end
        if f.shoutInput then f.shoutInput:ClearFocus() end
        if f.thresholdEdit then f.thresholdEdit:ClearFocus() end
        if f.receivedDamageInput then f.receivedDamageInput:ClearFocus() end
        if f.lineDistanceInput then f.lineDistanceInput:ClearFocus() end
        if f.shakeIntervalEdit then f.shakeIntervalEdit:ClearFocus() end
        
        -- arg1 是按键类型："LeftButton" 或 "RightButton"
        if arg1 == "RightButton" then
            -- 右键：切换表类型
            if addon._currentListType == "filter" then
                addon._currentListType = "aoe"
                listTypeBtn:SetText("合并AOE表")
            else
                addon._currentListType = "filter"
                listTypeBtn:SetText("技能过滤表")
            end
        else
            -- 左键：输出当前表
            if addon._currentListType == "filter" then
                -- 显示当前技能过滤表
                DEFAULT_CHAT_FRAME:AddMessage("\n=== [PlayTurtle] 技能过滤表 ===", 1, 1, 0)
                if addon.skillFilterList and next(addon.skillFilterList) then
                    local count = 0
                    for spellId, _ in pairs(addon.skillFilterList) do
                        count = count + 1
                        local spellName = GetSpellRecField(tonumber(spellId), "name") or "未知法术"
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] ID: %s - %s", count, spellId, spellName), 0.8, 0.8, 0.8)
                    end
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  总计：%d 个法术", count), 1, 1, 1)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  (空列表)", 0.6, 0.6, 0.6)
                end
                DEFAULT_CHAT_FRAME:AddMessage("==========================\n", 1, 1, 0)
            else
                -- 显示当前合并AOE表
                DEFAULT_CHAT_FRAME:AddMessage("\n=== [PlayTurtle] 合并AOE表 ===", 1, 1, 0)
                if addon.AOESkillsByID and next(addon.AOESkillsByID) then
                    local count = 0
                    for spellId, _ in pairs(addon.AOESkillsByID) do
                        count = count + 1
                        local spellName = GetSpellRecField(tonumber(spellId), "name") or "未知法术"
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] ID: %s - %s", count, spellId, spellName), 0.8, 0.8, 0.8)
                    end
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  总计：%d 个法术", count), 1, 1, 1)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  (空列表)", 0.6, 0.6, 0.6)
                end
                DEFAULT_CHAT_FRAME:AddMessage("==========================\n", 1, 1, 0)
            end
        end
    end)
    
    listTypeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(listTypeBtn, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("列表类型切换", 1, 1, 1)
        GameTooltip:AddLine("左键：输出当前表内容", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("右键：切换技能过滤表/合并AOE表", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("当前：" .. (addon._currentListType == "filter" and "技能过滤表" or "合并AOE表"), 1, 1, 0.5)
        GameTooltip:Show()
    end)
    listTypeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.listTypeBtn = listTypeBtn
    
    -- -召唤物信息收集开关按钮（在列表类型按钮左侧）
    local summonerToggleBtn = CreateFrame("Button", nil, f)
    summonerToggleBtn:SetWidth(25)
    summonerToggleBtn:SetHeight(btnHeight)
    summonerToggleBtn:SetPoint("RIGHT", listTypeBtn, "LEFT", -5, 0)
    
    -- 设置按钮背景
    summonerToggleBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local summonerToggleText = summonerToggleBtn:CreateFontString(nil, "OVERLAY")
    summonerToggleText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    summonerToggleText:SetPoint("CENTER", summonerToggleBtn, "CENTER", 0, 0)
    
    -- 更新按钮状态函数
    local function updateSummonerToggle()
        local isEnabled = addon.db and addon.db.collectSummonerInfo or 0
        if isEnabled == 1 then
            -- 开启状态：绿色边框，显示 S（Summoner）
            summonerToggleBtn:SetBackdropBorderColor(0, 1, 0, 1)
            summonerToggleBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            summonerToggleText:SetText("S")
            summonerToggleText:SetTextColor(0, 1, 0, 1)
        else
            -- 关闭状态：红色边框，显示 X
            summonerToggleBtn:SetBackdropBorderColor(1, 0, 0, 1)
            summonerToggleBtn:SetBackdropColor(0.3, 0, 0, 0.5)
            summonerToggleText:SetText("X")
            summonerToggleText:SetTextColor(1, 0, 0, 1)
        end
    end
    
    -- 初始化按钮状态
    updateSummonerToggle()
    
    -- 点击切换
    summonerToggleBtn:SetScript("OnClick", function()
        local current = addon.db and addon.db.collectSummonerInfo or 0
        
        addon.db.collectSummonerInfo = (current == 1) and 0 or 1
        -- 同步到 SavedVariables
        PTURTLE_Combat_DB.collectSummonerInfo = addon.db.collectSummonerInfo
        updateSummonerToggle()
    end)
    
    -- Tooltip
    summonerToggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(summonerToggleBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("召唤物信息收集开关", 1, 1, 1)
        local status = (addon.db.collectSummonerInfo or 0) == 1 and "开启" or "关闭"
        GameTooltip:AddLine("当前状态: " .. status, 0.8, 0.8, 0.8)
        GameTooltip:AddLine("控制是否收集玩家召唤物的战斗信息", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("该开关会增加性能消耗，非必要不建议开启", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    summonerToggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- -受到伤害法术 ID 输入框（替代原来的按钮）
    local receivedDamageInput = CreateFrame("EditBox", nil, f)
    receivedDamageInput:SetWidth(btnWidth - 50)  -- 留出空间给 +/- 按钮
    receivedDamageInput:SetHeight(btnHeight)
    receivedDamageInput:SetPoint("TOPLEFT", listTypeBtn, "BOTTOMLEFT", -30, -btnSpacing)
    receivedDamageInput:SetAutoFocus(false)
    receivedDamageInput:SetNumeric(true)
    receivedDamageInput:SetJustifyH("CENTER")
    receivedDamageInput:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    
    -- 设置输入框边框（与伤害阈值输入框保持一致）
    receivedDamageInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    receivedDamageInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
    
    -- 创建背景文字（标题作为占位符）
    local receivedDamageInputBg = receivedDamageInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    receivedDamageInputBg:SetAllPoints(receivedDamageInput)
    receivedDamageInputBg:SetJustifyH("CENTER")
    receivedDamageInputBg:SetText("技能ID")
    receivedDamageInputBg:SetTextColor(0.5, 0.5, 0.5)  -- 灰色文字
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    receivedDamageInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            receivedDamageInputBg:Show()
        else
            receivedDamageInputBg:Hide()
        end
    end)
    
    -- 添加 Tooltip 说明用法
    receivedDamageInput:SetScript("OnEnter", function()
        GameTooltip:SetOwner(receivedDamageInput, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("技能 ID 输入", 1, 1, 1)
        GameTooltip:AddLine("输入法术ID后按回车键添加到列表", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("当前列表：" .. (addon._currentListType == "filter" and "技能过滤表" or "合并AOE表"), 1, 1, 0.5)
        GameTooltip:AddLine("右键点击列表类型按钮可切换列表", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("", 1, 1, 1)
        GameTooltip:AddLine("使用方法：", 1, 0.8, 0.2)
        GameTooltip:AddLine("1. 输入法术ID", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("2. 按回车键添加", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("3. 点击右侧 - 按钮删除", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    receivedDamageInput:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    f.receivedDamageInput = receivedDamageInput
    
    -- 添加 ESC 键清除焦点功能
    receivedDamageInput:SetScript("OnEscapePressed", function()
        receivedDamageInput:ClearFocus()
    end)
    
    -- -回车键添加技能到当前列表
    receivedDamageInput:SetScript("OnEnterPressed", function()
        local spellIdStr = trim(receivedDamageInput:GetText())
        
        if spellIdStr == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入法术 ID！", 1, 1, 1)
            return
        end
        
        -- -将字符串ID转换为数字类型，确保表键类型一致
        local spellId = tonumber(spellIdStr)
        if not spellId then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 无效的法术 ID！", 1, 1, 1)
            return
        end
        
        -- 根据当前选择的表类型进行操作
        local currentType = addon._currentListType or "filter"
        
        if currentType == "filter" then
            -- 技能过滤表
            if addon.skillFilterList[spellId] then
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 已在过滤列表中！", 1, 1, 1)
                receivedDamageInput:SetText("")
                return
            end
            
            addon.skillFilterList[spellId] = true
            -- 保存到个人存档
            if PTURTLE_Combat_CharDB then
                PTURTLE_Combat_CharDB.skillFilterList = addon.skillFilterList
            end
            local spellName = GetSpellRecField(spellId, "name") or "未知法术"
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已添加到过滤列表：ID="..spellId.." - "..spellName, 1, 1, 1)
        else
            -- 合并AOE表
            if addon.AOESkillsByID[spellId] then
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 已在AOE列表中！", 1, 1, 1)
                receivedDamageInput:SetText("")
                return
            end
            
            addon.AOESkillsByID[spellId] = true
            -- 保存到个人存档
            if PTURTLE_Combat_CharDB then
                PTURTLE_Combat_CharDB.AOESkillsByID = addon.AOESkillsByID
            end
            local spellName = GetSpellRecField(spellId, "name") or "未知法术"
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已添加到AOE列表：ID="..spellId.." - "..spellName, 1, 1, 1)
        end
        
        receivedDamageInput:SetText("")
        receivedDamageInput:ClearFocus()
    end)
    
    -- -减号按钮（删除技能）
    local minusBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    minusBtn:SetWidth(20)
    minusBtn:SetHeight(btnHeight)
    minusBtn:SetPoint("LEFT", receivedDamageInput, "RIGHT", 25, 0)  -- 右移20像素（从5改为25）
    minusBtn:SetText("-")
    
    f.receivedDamageInput = receivedDamageInput
    f.receivedDamageMinusBtn = minusBtn
    
    minusBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(minusBtn, "ANCHOR_TOPRIGHT")
        local currentType = addon._currentListType or "filter"
        if currentType == "filter" then
            GameTooltip:SetText("从技能过滤表中删除", 1, 1, 1)
        else
            GameTooltip:SetText("从合并AOE表中删除", 1, 1, 1)
        end
        GameTooltip:AddLine("输入法术ID后点击删除", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    minusBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- -- 按钮点击事件（从当前列表中删除）
    minusBtn:SetScript("OnClick", function()
        if f.receivedDamageInput then f.receivedDamageInput:ClearFocus() end
        local spellIdStr = trim(receivedDamageInput:GetText())
        
        if spellIdStr == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入法术 ID！", 1, 1, 1)
            return
        end
        
        -- -将字符串ID转换为数字类型
        local spellId = tonumber(spellIdStr)
        if not spellId then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 无效的法术 ID！", 1, 1, 1)
            return
        end
        
        -- 根据当前选择的表类型进行操作
        local currentType = addon._currentListType or "filter"
        
        if currentType == "filter" then
            -- 技能过滤表
            if not addon.skillFilterList[spellId] then
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 不在过滤列表中！", 1, 1, 1)
                receivedDamageInput:SetText("")
                return
            end
            
            addon.skillFilterList[spellId] = nil
            -- 保存到个人存档
            if PTURTLE_Combat_CharDB then
                PTURTLE_Combat_CharDB.skillFilterList = addon.skillFilterList
            end
            local spellName = GetSpellRecField(spellId, "name") or "未知法术"
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已从过滤列表删除：ID="..spellId.." - "..spellName, 1, 1, 1)
        else
            -- 合并AOE表
            if not addon.AOESkillsByID[spellId] then
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 不在AOE列表中！", 1, 1, 1)
                receivedDamageInput:SetText("")
                return
            end
            
            addon.AOESkillsByID[spellId] = nil
            -- 保存到个人存档
            if PTURTLE_Combat_CharDB then
                PTURTLE_Combat_CharDB.AOESkillsByID = addon.AOESkillsByID
            end
            local spellName = GetSpellRecField(spellId, "name") or "未知法术"
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已从AOE列表删除：ID="..spellId.." - "..spellName, 1, 1, 1)
        end
        
        receivedDamageInput:SetText("")
        receivedDamageInput:ClearFocus()
    end)
    
    local thresholdEdit = CreateFrame("EditBox", nil, f)
    thresholdEdit:SetWidth(btnWidth)
    thresholdEdit:SetHeight(btnHeight)
    -- -锚点改为定位到受到治疗按钮下方（跳过两行），保持原有位置
    thresholdEdit:SetPoint("TOP", listTypeBtn, "BOTTOM", -15, -btnSpacing * 2 - btnHeight)
    thresholdEdit:SetAutoFocus(false)
    thresholdEdit:SetNumeric(true)
    thresholdEdit:SetJustifyH("CENTER")
    thresholdEdit:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
    
    -- 设置输入框边框
    thresholdEdit:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    thresholdEdit:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
    
    -- 创建背景文字（标题作为占位符）
    local thresholdEditBg = thresholdEdit:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    thresholdEditBg:SetAllPoints(thresholdEdit)
    thresholdEditBg:SetJustifyH("CENTER")
    thresholdEditBg:SetText("伤害阈值")
    thresholdEditBg:SetTextColor(0.5, 0.5, 0.5)  -- 灰色文字
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    thresholdEdit:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            thresholdEditBg:Show()
        else
            thresholdEditBg:Hide()
        end
    end)
    
    -- 设置初始值（会触发 OnTextChanged）
    -- 默认值为 5
    local thresholdValue = addon.db.damageThreshold or 5
    thresholdEdit:SetText(tostring(thresholdValue))
    thresholdEdit:SetScript("OnEnterPressed", function()
        local text = thresholdEdit:GetText()
        local v = tonumber(text)
        -- 如果为空或 nil，则保存为 0
        if not v then
            v = 0
        end
        addon.db.damageThreshold = v
        if v > 0 then
            thresholdEdit:SetText(tostring(v))
        else
            thresholdEdit:SetText("")  -- 显示为空（代表 0）
        end
        thresholdEdit:ClearFocus()
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 伤害阈值："..v, 1, 1, 1)
    end)
    thresholdEdit:SetScript("OnEnter", function()
        GameTooltip:SetOwner(thresholdEdit,"ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("伤害阈值")
        GameTooltip:AddLine("低于此值不显示",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    thresholdEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 添加 ESC 键清除焦点功能
    thresholdEdit:SetScript("OnEscapePressed", function()
        thresholdEdit:ClearFocus()
    end)
    f.thresholdEdit = thresholdEdit
    
    
    -- ===================== BUFF 监控模块（BUFF 列表） =====================
    local buffModuleBottomOffset = 120  -- 距离面板底部的间距
    -- Lua5.0 兼容的坐标计算
    local buffModuleTitleY = - (400 - buffModuleBottomOffset - 40)
    local buffInputLabelY = - (400 - buffModuleBottomOffset - 20)
    local buffBtnY = - (400 - buffModuleBottomOffset) + 10 - 20  -- 额外下移 10px，再上移 20px
        
    -- BUFF 输入框（左对齐）
    local buffInput = CreateFrame("EditBox", nil, f)
    buffInput:SetWidth(50)  -- 增加 5 像素
    buffInput:SetHeight(24)  -- 统一高度为 24
    buffInput:SetPoint("TOPLEFT", f, "TOPLEFT", leftColOffsetX, buffInputLabelY)  -- 固定在面板上的位置
    buffInput:SetFontObject(GameFontNormalSmall)
    buffInput:SetAutoFocus(false)
    buffInput:SetMaxLetters(5)  -- 最多 5 位字符
    buffInput:SetJustifyH("CENTER")  -- 居中对齐文本
    buffInput:SetTextColor(1, 1, 1, 1)  -- 白色文本
    buffInput:EnableMouse(true)  -- 启用鼠标点击
    
    -- 只允许输入数字（失去焦点时验证）
    buffInput:SetScript("OnEditFocusLost", function()
        local text = buffInput:GetText()
        -- 移除所有非数字字符
        local cleanText = string.gsub(text, "[^0-9]", "")
        buffInput:SetText(cleanText)
    end)
    
    buffInput:SetScript("OnMouseDown", function(_, button)
        -- 只有左键点击才获得焦点
        if button == "LeftButton" then
            buffInput:SetFocus()
        end
    end)
        
    -- 创建背景文字（作为占位符背景）
    local buffInputBg = buffInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    buffInputBg:SetAllPoints(buffInput)
    buffInputBg:SetJustifyH("CENTER")
    buffInputBg:SetText("BUFF ID")
        
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    buffInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            buffInputBg:Show()
        else
            buffInputBg:Hide()
        end
    end)
        
    -- 设置输入框边框（不使用背景纹理）
    buffInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    buffInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
        
    -- 添加 ESC 键清除焦点功能
    buffInput:SetScript("OnEscapePressed", function()
        buffInput:ClearFocus()
    end)
        
    -- BUFF 输入标签（放到输入框上方，锚定在输入框上）
    local buffInputLabel = f:CreateFontString(nil, "OVERLAY")
    buffInputLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    buffInputLabel:SetTextColor(1, 1, 1)
    buffInputLabel:SetPoint("BOTTOM", buffInput, "TOP", 0, 3)  -- 增加 3px 间距
    buffInputLabel:SetText("BUFF 监控：")
        
    -- 添加提示文字（标题右侧，灰色）
    local buffHintLabel = f:CreateFontString(nil, "OVERLAY")
    buffHintLabel:SetFont(STANDARD_TEXT_FONT, 10)
    buffHintLabel:SetTextColor(0.6, 0.6, 0.6)
    buffHintLabel:SetPoint("LEFT", buffInputLabel, "RIGHT", 5, 0)  -- 距离标题 5px
    buffHintLabel:SetText("（#代替技能名）")
        
    -- & 符号标签（第二个）
    local buffAndSymbol = f:CreateFontString(nil, "OVERLAY")
    buffAndSymbol:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    buffAndSymbol:SetTextColor(1, 1, 1)
    buffAndSymbol:SetPoint("LEFT", buffInput, "RIGHT", 5, 0)
    buffAndSymbol:SetText("&")
        
    -- 第二个喊话输入框（左对齐）
    local buffShoutInput = CreateFrame("EditBox", nil, f)
    buffShoutInput:SetWidth(200)  -- 增加 5 像素
    buffShoutInput:SetHeight(24)  -- 统一高度为 24
    buffShoutInput:SetPoint("LEFT", buffAndSymbol, "RIGHT", 5, 0)
    buffShoutInput:SetFontObject(GameFontNormalSmall)
    buffShoutInput:SetAutoFocus(false)
    buffShoutInput:SetMaxLetters(0)  -- 不限制字符数量
    buffShoutInput:SetJustifyH("CENTER")  -- 居中对齐文本
    buffShoutInput:SetTextColor(1, 1, 1, 1)  -- 白色文本
    buffShoutInput:EnableMouse(true)  -- 启用鼠标点击
    buffShoutInput:SetScript("OnMouseDown", function(self, button)
        -- 只有左键点击才获得焦点
        if button == "LeftButton" then
            buffShoutInput:SetFocus()
        end
    end)
        
    -- 创建背景文字（作为占位符背景）
    local buffShoutInputBg = buffShoutInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    buffShoutInputBg:SetAllPoints(buffShoutInput)
    buffShoutInputBg:SetJustifyH("CENTER")
    buffShoutInputBg:SetText("（可选）喊话")
        
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    buffShoutInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            buffShoutInputBg:Show()
        else
            buffShoutInputBg:Hide()
        end
    end)
        
    -- 设置输入框边框（不使用背景纹理）
    buffShoutInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    buffShoutInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
        
    -- 添加 ESC 键清除焦点功能
    buffShoutInput:SetScript("OnEscapePressed", function()
        buffShoutInput:ClearFocus()
    end)
    
    -- & 符号标签（第三个，用于音乐下拉菜单前）
    local buffAndSymbol2 = f:CreateFontString(nil, "OVERLAY")
    buffAndSymbol2:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    buffAndSymbol2:SetTextColor(1, 1, 1)
    buffAndSymbol2:SetPoint("LEFT", buffShoutInput, "RIGHT", 5, 0)
    buffAndSymbol2:SetText("&")
    
    -- ===================== BUFF 监控音乐播放下拉菜单 =====================
    -- 创建下拉框
    local buffSoundDropDown = CreateFrame("Frame", "PlayTurtleBuffSoundDropDown", f, "UIDropDownMenuTemplate")
    buffSoundDropDown:SetPoint("LEFT", buffAndSymbol2, "RIGHT", -9, 0)
    UIDropDownMenu_SetWidth(100, buffSoundDropDown)
        
    -- 设置下拉菜单文字
    UIDropDownMenu_SetText("(可选) 音乐", buffSoundDropDown)
    local buffSoundText = _G[buffSoundDropDown:GetName() .. "Text"]
    if buffSoundText then
        buffSoundText:SetTextColor(1, 1, 1, 1)  -- 白色文字  
    end
    
    -- 去掉下拉框的背景纹理
    buffSoundDropDown:SetBackdrop(nil)
    
    -- 让整个下拉框可点击
    buffSoundDropDown:EnableMouse(true)
    buffSoundDropDown:SetScript("OnMouseDown", function()
        if this:IsMouseEnabled() then

            if ToggleDropDownMenu then
                ToggleDropDownMenu(1, nil, this, this:GetName(), 0, 0)
            else
                -- 重新初始化并显示
                UIDropDownMenu_Initialize(this, InitializeBuffDropDown)
                ShowUIDropDownMenu(this)
            end
        end
    end)
        
-- BUFF 监控开关复选框
local buffMonitorCheck = CreateFrame("CheckButton", "PlayTurtle_BuffMonitorCheck", f, "UICheckButtonTemplate")
buffMonitorCheck:SetPoint("TOPLEFT", buffInput, "BOTTOMLEFT", -2, 0)

-- 读取配置
local buffEnabled = (PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.buffMonitorEnabled == 1)
buffMonitorCheck:SetChecked(buffEnabled)

-- 封装事件注册/注销逻辑（核心修复）
local function UpdateBuffMonitorEvent(enabled)
    if addon.eventFrame then
        if enabled then
            addon.eventFrame:RegisterEvent("BUFF_ADDED_SELF")
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] BUFF 监控：已自动启用", 1, 1, 1)
        else
            addon.eventFrame:UnregisterEvent("BUFF_ADDED_SELF")
        end
    end
end

-- 初始化时自动执行一次（关键！）
UpdateBuffMonitorEvent(buffEnabled)

-- 点击时执行
buffMonitorCheck:SetScript("OnClick", function()
    local enable = buffMonitorCheck:GetChecked()
    PTURTLE_Combat_CharDB.buffMonitorEnabled = enable and 1 or 0
    UpdateBuffMonitorEvent(enable)
    
    if enable then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] BUFF 监控已启用", 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] BUFF 监控已禁用", 1, 1, 1)
    end
end)
    
    -- BUFF 监控标签
    local buffMonitorLabel = f:CreateFontString(nil, "OVERLAY")
    buffMonitorLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    buffMonitorLabel:SetTextColor(1, 1, 1)
    buffMonitorLabel:SetPoint("LEFT", buffMonitorCheck, "RIGHT", 0, 0)
    buffMonitorLabel:SetText("启用")
    
    -- 添加法术按钮（左对齐，放在输入框下方）
    local addBuffBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBuffBtn:SetWidth(24)
    addBuffBtn:SetHeight(24)  -- 统一高度为 24
    addBuffBtn:SetPoint("LEFT", buffMonitorCheck, "RIGHT", 45, 0)  -- 锚定于复选框右侧
    addBuffBtn:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    addBuffBtn:SetText("+")
        
    -- 删除法术按钮（左对齐）
    local removeBuffBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    removeBuffBtn:SetWidth(24)
    removeBuffBtn:SetHeight(24)  -- 统一高度为 24
    removeBuffBtn:SetPoint("LEFT", addBuffBtn, "RIGHT", 10, 0)
    removeBuffBtn:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    removeBuffBtn:SetText("-")
        
-- 显示当前监控BUFF列表按钮（左对齐）
local showBuffsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
showBuffsBtn:SetWidth(80)
showBuffsBtn:SetHeight(24)  -- 统一高度为 24
showBuffsBtn:SetPoint("LEFT", removeBuffBtn, "RIGHT", 60, 0)
showBuffsBtn:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
showBuffsBtn:SetText("BUFF列表")

-- ===================== 【新增】右侧切换按钮（同样大小） =====================
local toggleMonitorBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
toggleMonitorBtn:SetWidth(120)      
toggleMonitorBtn:SetHeight(24)
toggleMonitorBtn:SetPoint("LEFT", showBuffsBtn, "RIGHT", 25, 0) 
toggleMonitorBtn:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")

-- 初始化：从个人角色存档读取状态（true=监控DEBUFF，false=监控BUFF）
if PTURTLE_Combat_CharDB.monitorDebuffMode == nil then
    PTURTLE_Combat_CharDB.monitorDebuffMode = false -- 默认监控BUFF
end

-- 更新按钮文字
local function UpdateToggleBtnText()
    if PTURTLE_Combat_CharDB.monitorDebuffMode then
        toggleMonitorBtn:SetText("切换BUFF监控")
    else
        toggleMonitorBtn:SetText("切换DEBUFF监控")
    end
end
UpdateToggleBtnText()

-- 点击切换状态（同时更新事件注册）
toggleMonitorBtn:SetScript("OnClick", function()
    -- 切换状态
    PTURTLE_Combat_CharDB.monitorDebuffMode = not PTURTLE_Combat_CharDB.monitorDebuffMode
    
    -- 动态切换 BUFF/DEBUFF 事件（二选一）
    if addon.eventFrame then
        if PTURTLE_Combat_CharDB.monitorDebuffMode then
            -- 切换到 DEBUFF 监控：注销 BUFF 事件，注册 DEBUFF 事件
            addon.eventFrame:UnregisterEvent("BUFF_ADDED_SELF")
            addon.eventFrame:RegisterEvent("DEBUFF_ADDED_SELF")
        else
            -- 切换到 BUFF 监控：注销 DEBUFF 事件，注册 BUFF 事件
            addon.eventFrame:UnregisterEvent("DEBUFF_ADDED_SELF")
            addon.eventFrame:RegisterEvent("BUFF_ADDED_SELF")
        end
    end
    
    -- 更新文字
    UpdateToggleBtnText()
    
    -- 提示
    if PTURTLE_Combat_CharDB.monitorDebuffMode then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已切换至：DEBUFF 监控模式", 1, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已切换至：BUFF 监控模式", 1, 1, 0)
    end
end)

-- 提示
toggleMonitorBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(toggleMonitorBtn, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText("监控类型切换")
    GameTooltip:AddLine("在 BUFF / DEBUFF 监控之间切换", 0.8,0.8,0.8)
    GameTooltip:Show()
end)
toggleMonitorBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
    -- BUFF 按钮点击逻辑（Lua5.0 兼容版）
    addBuffBtn:SetScript("OnClick", function()
        buffInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        buffShoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
        local buffId = trim(buffInput:GetText())
        if buffId == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入法术 ID！", 1, 1, 1)
            return
        end
                
        -- 检查是否已存在
        if addon.buffsDB[buffId] then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] BUFF ID ["..buffId.."] 已存在！", 1, 1, 1)
            buffInput:SetText("")
            return
        end
                
        -- 获取喊话内容和音乐（为空则存 nil）
        local shoutText = trim(buffShoutInput:GetText())
        local music = buffSoundDropDown._selectedSound
                    
        -- 只有非空才存储，否则为 nil（key 已经是字符串，无需 tostring）
        addon.buffsDB[buffId] = {
            shout = (shoutText ~= "") and shoutText or nil,
            music = (music and music ~= "") and music or nil
        }
                
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已添加监控法术 ID："..buffId, 1, 1, 1)
        buffInput:SetText("")
        buffShoutInput:SetText("")
        buffSoundDropDown._selectedSound = nil
        UIDropDownMenu_SetText("(可选) 音乐", buffSoundDropDown)
        local soundText = _G[buffSoundDropDown:GetName() .. "Text"]
        if soundText then
            soundText:SetTextColor(1, 1, 1, 1)
        end
        buffInput:ClearFocus()  -- 清除焦点
    end)
        
    removeBuffBtn:SetScript("OnClick", function()
        buffInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        buffShoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
        local buffId = trim(buffInput:GetText())
        if buffId == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入要删除的法术 ID！", 1, 1, 1)
            return
        end
                
        -- 按法术 ID 删除
        if addon.buffsDB[buffId] then
            addon.buffsDB[buffId] = nil
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已删除监控法术 ID："..buffId, 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] BUFF ID ["..buffId.."] 不存在！", 1, 1, 1)
        end
        buffInput:SetText("")
        buffInput:ClearFocus()  -- 清除焦点
    end)
        
    showBuffsBtn:SetScript("OnClick", function()
        buffInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        buffShoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
             
        -- 统计表大小
        local count = 0
        for buffId, data in pairs(addon.buffsDB) do
            count = count + 1
        end
            
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 当前无监控法术！", 1, 1, 1)
            return
        end
            
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 监控法术列表：", 1, 1, 1)
        local index = 1
        for buffId, data in pairs(addon.buffsDB) do
            -- 通过 GetSpellRecField 直接获取技能名
            local buffName = GetSpellRecField(tonumber(buffId), "name") or "未知技能"
            
            -- 处理喊话内容（无喊话则显示"无"）
            local shoutStr = data.shout or "无"
            
            -- 处理音乐名称（去掉后缀，只显示文件名）
            local musicStr = "无"
            if data.music then
                -- 去掉 .mp3 后缀
                musicStr = string.gsub(data.music, "%.mp3$", "")
            end
            
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. |cFFFFD700%s|r (ID: %s) | 喊话：%s | 音乐：%s", index, buffName, buffId, shoutStr, musicStr), 1, 1, 1)
            index = index + 1
        end
    end)
        
    -- 鼠标提示（Lua5.0 兼容）
    addBuffBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addBuffBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("添加法术")
        GameTooltip:AddLine("将法术添加到监控列表", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    addBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
    removeBuffBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeBuffBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("删除法术")
        GameTooltip:AddLine("从监控列表移除法术", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    removeBuffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
    showBuffsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(showBuffsBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("法术列表")
        GameTooltip:AddLine("显示所有监控的法术", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    showBuffsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
    -- ===================== 法术管理模块（移至面板最底部 + 左对齐功能按钮） =====================
    local spellModuleBottomOffset = 40  -- 距离面板底部的间距
    -- Lua5.0兼容的坐标计算
    local spellModuleTitleY = - (400 - spellModuleBottomOffset - 40)
    local spellInputLabelY = - (400 - spellModuleBottomOffset - 20)
    local spellBtnY = - (400 - spellModuleBottomOffset)
    
    -- 法术模块标题（已移除）
    
    -- 法术输入框（左对齐）
    local spellInput = CreateFrame("EditBox", nil, f)
    spellInput:SetWidth(50)  -- 增加 5 像素（原 45 → 现 50）
    spellInput:SetHeight(24)  -- 统一高度为 24
    spellInput:SetPoint("TOPLEFT", f, "TOPLEFT", leftColOffsetX, spellInputLabelY)  -- 固定在面板上的位置
    spellInput:SetFontObject(GameFontNormalSmall)
    spellInput:SetAutoFocus(false)
    spellInput:SetMaxLetters(5)  -- 最多 5 位字符
    spellInput:SetJustifyH("CENTER")  -- 居中对齐文本
    spellInput:SetTextColor(1, 1, 1, 1)  -- 白色文本
    spellInput:EnableMouse(true)  -- 启用鼠标点击
    
    -- 只允许输入数字（失去焦点时验证）
    spellInput:SetScript("OnEditFocusLost", function()
        local text = spellInput:GetText()
        -- 移除所有非数字字符
        local cleanText = string.gsub(text, "[^0-9]", "")
        spellInput:SetText(cleanText)
    end)
    
    spellInput:SetScript("OnMouseDown", function(_, button)
        -- 只有左键点击才获得焦点
        if button == "LeftButton" then
            spellInput:SetFocus()
        end
    end)
    
    -- 创建背景文字（作为占位符背景）
    local spellInputBg = spellInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    spellInputBg:SetAllPoints(spellInput)
    spellInputBg:SetJustifyH("CENTER")
    spellInputBg:SetText("法术 ID")
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    spellInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            spellInputBg:Show()
        else
            spellInputBg:Hide()
        end
    end)
    
    -- 设置输入框边框（不使用背景纹理）
    spellInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    spellInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
    
    -- 添加 ESC 键清除焦点功能
    spellInput:SetScript("OnEscapePressed", function()
        spellInput:ClearFocus()
    end)
    
    -- 法术输入标签（放到法术输入框上方，锚定在输入框上）
    local spellInputLabel = f:CreateFontString(nil, "OVERLAY")
    spellInputLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    spellInputLabel:SetTextColor(1, 1, 1)
    spellInputLabel:SetPoint("BOTTOM", spellInput, "TOP", 0, 3)  -- 增加 3px 间距
    spellInputLabel:SetText("法术监控：")
    
    -- 添加提示文字（标题右侧，灰色）
    local spellHintLabel = f:CreateFontString(nil, "OVERLAY")
    spellHintLabel:SetFont(STANDARD_TEXT_FONT, 10)
    spellHintLabel:SetTextColor(0.6, 0.6, 0.6)
    spellHintLabel:SetPoint("LEFT", spellInputLabel, "RIGHT", 5, 0)  -- 距离标题 5px
    spellHintLabel:SetText("（喊话中使用@代替目标名，#代替技能名）")
    
    -- & 符号标签
    local andSymbol = f:CreateFontString(nil, "OVERLAY")
    andSymbol:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    andSymbol:SetTextColor(1, 1, 1)
    andSymbol:SetPoint("LEFT", spellInput, "RIGHT", 5, 0)
    andSymbol:SetText("&")
    
    -- 第二个喊话输入框（左对齐）
    local shoutInput = CreateFrame("EditBox", nil, f)
    shoutInput:SetWidth(200)  -- 增加 5 像素（原 45 → 现 50）
    shoutInput:SetHeight(24)  -- 统一高度为 24
    shoutInput:SetPoint("LEFT", andSymbol, "RIGHT", 5, 0)
    shoutInput:SetFontObject(GameFontNormalSmall)
    shoutInput:SetAutoFocus(false)
    shoutInput:SetMaxLetters(0)  -- 不限制字符数量
    shoutInput:SetJustifyH("CENTER")  -- 居中对齐文本
    shoutInput:SetTextColor(1, 1, 1, 1)  -- 白色文本
    shoutInput:EnableMouse(true)  -- 启用鼠标点击
    shoutInput:SetScript("OnMouseDown", function(self, button)
        -- 只有左键点击才获得焦点
        if button == "LeftButton" then
            shoutInput:SetFocus()
        end
    end)
    
    -- 创建背景文字（作为占位符背景）
    local shoutInputBg = shoutInput:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    shoutInputBg:SetAllPoints(shoutInput)
    shoutInputBg:SetJustifyH("CENTER")
    shoutInputBg:SetText("（可选）喊话")
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    shoutInput:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            shoutInputBg:Show()
        else
            shoutInputBg:Hide()
        end
    end)
    
    -- 设置输入框边框（不使用背景纹理）
    shoutInput:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    shoutInput:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)  -- 灰色边框
    
    -- 添加 ESC 键清除焦点功能
    shoutInput:SetScript("OnEscapePressed", function()
        shoutInput:ClearFocus()
    end)
    
    -- & 符号标签（第二个）
    local andSymbol2 = f:CreateFontString(nil, "OVERLAY")
    andSymbol2:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    andSymbol2:SetTextColor(1, 1, 1)
    andSymbol2:SetPoint("LEFT", shoutInput, "RIGHT", 5, 0)
    andSymbol2:SetText("&")
    
    -- ===================== 音乐播放下拉菜单（参考 DoiteAuras 实现） =====================
    -- 硬编码音乐文件列表（S_1 到 S_13，实际存在于 Sound/ 文件夹）
    local SOUND_FILES = {
        "S_1.mp3", "S_2.mp3", "S_3.mp3", "S_4.mp3", "S_5.mp3",
        "S_6.mp3", "S_7.mp3", "S_8.mp3", "S_9.mp3", "S_10.mp3",
        "S_11.mp3", "S_12.mp3", "S_13.mp3"
    }
    
    -- 创建下拉框
    local soundDropDown = CreateFrame("Frame", "PlayTurtleSoundDropDown", f, "UIDropDownMenuTemplate")
    soundDropDown:SetPoint("LEFT", andSymbol2, "RIGHT", -9, 0)  -- 再向左移动 5px，更靠近&符号
    UIDropDownMenu_SetWidth(100, soundDropDown)
        
    -- 设置下拉菜单文字
    UIDropDownMenu_SetText("(可选) 音乐", soundDropDown)
    local soundText = _G[soundDropDown:GetName() .. "Text"]
    if soundText then
        soundText:SetTextColor(1, 1, 1, 1)  -- 白色文字  
    end
    
    -- 去掉下拉框的背景纹理
    soundDropDown:SetBackdrop(nil)
    
    -- 让整个下拉框可点击（包括文字区域）
    soundDropDown:EnableMouse(true)
    soundDropDown:SetScript("OnMouseDown", function()
        if this:IsMouseEnabled() then

            if ToggleDropDownMenu then
                ToggleDropDownMenu(1, nil, this, this:GetName(), 0, 0)
            else
                -- 重新初始化并显示
                UIDropDownMenu_Initialize(this, InitializeDropDown)
                ShowUIDropDownMenu(this)
            end
        end
    end)
    
    -- 初始化下拉菜单
    local function InitializeDropDown(frame, level, menuList)
        level = level or 1
        local perPage = 10  -- 每页显示数量
        local total = table_getn(SOUND_FILES)
        local maxPage = math_ceil(total / perPage)
        local page = soundDropDown._soundPage or 1
        
        -- 不选择选项（清空选择）
        local infoClear = UIDropDownMenu_CreateInfo()
        infoClear.text = "|cffff8080 不选择|r"
        infoClear.notCheckable = true
        infoClear.justifyH = "CENTER"  -- 居中对齐
        infoClear.width = 100  -- 设置菜单项宽度
        infoClear.func = function()
            soundDropDown._selectedSound = nil
            UIDropDownMenu_SetSelectedValue(soundDropDown, nil)
            UIDropDownMenu_SetText("(可选) 音乐", soundDropDown)
            local soundText = _G[soundDropDown:GetName() .. "Text"]
            if soundText then
                soundText:SetTextColor(1, 1, 1, 1)  -- 白色文字
            end
            if CloseDropDownMenus then CloseDropDownMenus() end
        end
        UIDropDownMenu_AddButton(infoClear, level)
        
        -- 分隔线
        local infoSeparator = UIDropDownMenu_CreateInfo()
        infoSeparator.isTitle = true
        infoSeparator.text = "---"
        UIDropDownMenu_AddButton(infoSeparator, level)
        
        -- 上一页
        if page > 1 then
            local infoPrev = UIDropDownMenu_CreateInfo()
            infoPrev.text = "|cffffd000<< 上一页|r"
            infoPrev.notCheckable = true
            infoPrev.justifyH = "CENTER"  -- 居中对齐
            infoPrev.width = 100  -- 设置菜单项宽度
            infoPrev.func = function()
                soundDropDown._soundPage = page - 1

                if not soundDropDown._reopenFrame then
                    local f = CreateFrame("Frame", nil, UIParent)
                    soundDropDown._reopenFrame = f
                    f:Hide()
                    f:SetScript("OnUpdate", function()
                        this:Hide()
                        ToggleDropDownMenu(1, nil, soundDropDown, soundDropDown:GetName(), 0, 0)
                    end)
                end
                soundDropDown._reopenFrame:Show()
            end
            UIDropDownMenu_AddButton(infoPrev, level)
        end
        
        -- 当前页条目
        local startIndex = (page - 1) * perPage + 1
        local endIndex = math.min(startIndex + perPage - 1, total)
        
        local i = startIndex
        while i <= endIndex do
            local fname = SOUND_FILES[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = fname
            info.value = fname
            info.checked = (soundDropDown._selectedSound == fname)
            info.width = 100  -- 设置菜单项宽度
            info.func = function(button)
                local picked = (button and button.value) or fname
                soundDropDown._selectedSound = picked
                UIDropDownMenu_SetSelectedValue(soundDropDown, picked)
                UIDropDownMenu_SetText(picked, soundDropDown)
                -- 播放音乐
                if PlaySoundFile and picked and picked ~= "" then
                    local path = "Interface\\AddOns\\PlayTurtle\\Sound\\" .. picked
                    pcall(PlaySoundFile, path, "Master")
                    DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 正在播放：" .. picked, 1, 1, 1)
                end
                if CloseDropDownMenus then CloseDropDownMenus() end
            end
            UIDropDownMenu_AddButton(info, level)
            i = i + 1
        end
            
        -- 下一页
        if page < maxPage then
            local infoNext = UIDropDownMenu_CreateInfo()
            infoNext.text = "|cffffd000>> 下一页|r"
            infoNext.notCheckable = true
            infoNext.justifyH = "CENTER"  -- 居中对齐
            infoNext.width = 100  -- 设置菜单项宽度
            infoNext.func = function()
                soundDropDown._soundPage = page + 1
                -- 参考 DoiteAuras：延迟刷新下拉菜单
                if not soundDropDown._reopenFrame then
                    local f = CreateFrame("Frame", nil, UIParent)
                    soundDropDown._reopenFrame = f
                    f:Hide()
                    f:SetScript("OnUpdate", function()
                        this:Hide()
                        ToggleDropDownMenu(1, nil, soundDropDown, soundDropDown:GetName(), 0, 0)
                    end)
                end
                soundDropDown._reopenFrame:Show()
            end
            UIDropDownMenu_AddButton(infoNext, level)
        end
    end
    
    UIDropDownMenu_Initialize(soundDropDown, InitializeDropDown)
        
    -- ===================== BUFF 监控下拉菜单初始化（复用音乐列表） =====================
    local function InitializeBuffDropDown(frame, level, menuList)
        level = level or 1
        local perPage = 10  -- 每页显示数量
        local total = table_getn(SOUND_FILES)  -- 复用同一个音乐列表
        local maxPage = math_ceil(total / perPage)
        local page = buffSoundDropDown._soundPage or 1
            
        -- 不选择选项（清空选择）
        local infoClear = UIDropDownMenu_CreateInfo()
        infoClear.text = "|cffff8080 不选择|r"
        infoClear.notCheckable = true
        infoClear.justifyH = "CENTER"  -- 居中对齐
        infoClear.width = 100  -- 设置菜单项宽度
        infoClear.func = function()
            buffSoundDropDown._selectedSound = nil
            UIDropDownMenu_SetSelectedValue(buffSoundDropDown, nil)
            UIDropDownMenu_SetText("(可选) 音乐", buffSoundDropDown)
            local buffSoundText = _G[buffSoundDropDown:GetName() .. "Text"]
            if buffSoundText then
                buffSoundText:SetTextColor(1, 1, 1, 1)  -- 白色文字
            end
            if CloseDropDownMenus then CloseDropDownMenus() end
        end
        UIDropDownMenu_AddButton(infoClear, level)
            
        -- 分隔线
        local infoSeparator = UIDropDownMenu_CreateInfo()
        infoSeparator.isTitle = true
        infoSeparator.text = "---"
        UIDropDownMenu_AddButton(infoSeparator, level)
            
        -- 上一页
        if page > 1 then
            local infoPrev = UIDropDownMenu_CreateInfo()
            infoPrev.text = "|cffffd000<< 上一页|r"
            infoPrev.notCheckable = true
            infoPrev.justifyH = "CENTER"  -- 居中对齐
            infoPrev.width = 100  -- 设置菜单项宽度
            infoPrev.func = function()
                buffSoundDropDown._soundPage = page - 1
                -- 参考 DoiteAuras：延迟刷新下拉菜单
                if not buffSoundDropDown._reopenFrame then
                    local f = CreateFrame("Frame", nil, UIParent)
                    buffSoundDropDown._reopenFrame = f
                    f:Hide()
                    f:SetScript("OnUpdate", function()
                        this:Hide()
                        ToggleDropDownMenu(1, nil, buffSoundDropDown, buffSoundDropDown:GetName(), 0, 0)
                    end)
                end
                buffSoundDropDown._reopenFrame:Show()
            end
            UIDropDownMenu_AddButton(infoPrev, level)
        end
            
        -- 当前页条目
        local startIndex = (page - 1) * perPage + 1
        local endIndex = math.min(startIndex + perPage - 1, total)
            
        local i = startIndex
        while i <= endIndex do
            local fname = SOUND_FILES[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = fname
            info.value = fname
            info.checked = (buffSoundDropDown._selectedSound == fname)
            info.width = 100  -- 设置菜单项宽度
            info.func = function(button)
                local picked = (button and button.value) or fname
                buffSoundDropDown._selectedSound = picked
                UIDropDownMenu_SetSelectedValue(buffSoundDropDown, picked)
                UIDropDownMenu_SetText(picked, buffSoundDropDown)
                -- 播放音乐
                if PlaySoundFile and picked and picked ~= "" then
                    local path = "Interface\\AddOns\\PlayTurtle\\Sound\\" .. picked
                    pcall(PlaySoundFile, path, "Master")
                    DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 正在播放：" .. picked, 1, 1, 1)
                end
                if CloseDropDownMenus then CloseDropDownMenus() end
            end
            UIDropDownMenu_AddButton(info, level)
            i = i + 1
        end
        
        -- 下一页
        if page < maxPage then
            local infoNext = UIDropDownMenu_CreateInfo()
            infoNext.text = "|cffffd000>> 下一页|r"
            infoNext.notCheckable = true
            infoNext.justifyH = "CENTER"  -- 居中对齐
            infoNext.width = 100  -- 设置菜单项宽度
            infoNext.func = function()
                buffSoundDropDown._soundPage = page + 1
                -- 延迟刷新下拉菜单
                if not buffSoundDropDown._reopenFrame then
                    local f = CreateFrame("Frame", nil, UIParent)
                    buffSoundDropDown._reopenFrame = f
                    f:Hide()
                    f:SetScript("OnUpdate", function()
                        this:Hide()
                        ToggleDropDownMenu(1, nil, buffSoundDropDown, buffSoundDropDown:GetName(), 0, 0)
                    end)
                end
                buffSoundDropDown._reopenFrame:Show()
            end
            UIDropDownMenu_AddButton(infoNext, level)
        end
    end
    
    -- 强制文本左对齐
    local buffSoundText = getglobal("PlayTurtleBuffSoundDropDownText") or nil
    local buffSoundMiddle = getglobal("PlayTurtleBuffSoundDropDownMiddle") or nil
    if buffSoundText then
        buffSoundText:ClearAllPoints()
        if buffSoundMiddle then
            buffSoundText:SetPoint("LEFT", buffSoundMiddle, "LEFT", 10, 2)
        else
            buffSoundText:SetPoint("LEFT", buffSoundDropDown, "LEFT", 10, 2)
        end
        buffSoundText:SetJustifyH("LEFT")
    end
    
    -- 初始化
    UIDropDownMenu_Initialize(buffSoundDropDown, InitializeBuffDropDown)
    
    -- 强制文本左对齐
    local soundText = getglobal("PlayTurtleSoundDropDownText") or nil
    local soundMiddle = getglobal("PlayTurtleSoundDropDownMiddle") or nil
    if soundText then
        soundText:ClearAllPoints()
        if soundMiddle then
            soundText:SetPoint("LEFT", soundMiddle, "LEFT", 10, 2)
        else
            soundText:SetPoint("LEFT", soundDropDown, "LEFT", 10, 2)
        end
        soundText:SetJustifyH("LEFT")
    end
    
    -- 法术监控开关复选框
local spellMonitorCheck = CreateFrame("CheckButton", "PlayTurtle_SpellMonitorCheck", f, "UICheckButtonTemplate")
spellMonitorCheck:SetPoint("TOPLEFT", spellInput, "BOTTOMLEFT", -2, 1)

-- 读取配置
local spellEnabled = (PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.spellMonitorEnabled == 1)
spellMonitorCheck:SetChecked(spellEnabled)

-- 封装事件注册/注销逻辑（核心修复）
local function UpdateSpellMonitorEvent(enabled)
    if addon.eventFrame then
        if enabled then
            addon.eventFrame:RegisterEvent("SPELL_GO_SELF")
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术监控：已自动启用", 1, 1, 1)
        else
            addon.eventFrame:UnregisterEvent("SPELL_GO_SELF")
        end
    end
end

-- 初始化时自动执行一次（关键！）
UpdateSpellMonitorEvent(spellEnabled)

-- 点击时执行
spellMonitorCheck:SetScript("OnClick", function()
    local enable = spellMonitorCheck:GetChecked()
    PTURTLE_Combat_CharDB.spellMonitorEnabled = enable and 1 or 0
    UpdateSpellMonitorEvent(enable)
    
    if enable then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术监控已启用", 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术监控已禁用", 1, 1, 1)
    end
end)
    
    -- ===================== 技能/BUFF 查询输入框 =====================
    local spellQueryEdit = CreateFrame("EditBox", nil, f)
    spellQueryEdit:SetWidth(btnWidth)
    spellQueryEdit:SetHeight(btnHeight)
    spellQueryEdit:SetPoint("LEFT", spellMonitorCheck, "RIGHT", 268, 0)  -- 锚定在法术监控复选框右侧
    spellQueryEdit:SetAutoFocus(false)
    spellQueryEdit:SetJustifyH("CENTER")
    spellQueryEdit:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    
    -- 创建背景文字（标题作为占位符）
    local spellQueryEditBg = spellQueryEdit:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
    spellQueryEditBg:SetAllPoints(spellQueryEdit)
    spellQueryEditBg:SetJustifyH("CENTER")
    spellQueryEditBg:SetText("技能ID查询")
    spellQueryEditBg:SetTextColor(0.5, 0.5, 0.5)
    
    -- 设置输入框边框
    spellQueryEdit:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    spellQueryEdit:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- 监听输入框内容变化，控制背景文字显示/隐藏
    spellQueryEdit:SetScript("OnTextChanged", function()
        if this:GetText() == "" then
            spellQueryEditBg:Show()
        else
            spellQueryEditBg:Hide()
        end
    end)
    
    -- 设置初始值（空）
    spellQueryEdit:SetText("")
    
    -- 监听回车键事件
    spellQueryEdit:SetScript("OnEnterPressed", function()
        local text = spellQueryEdit:GetText()
        if not text or text == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入技能名称", 1, 0.5, 0.5)
            spellQueryEdit:SetText("")
            spellQueryEdit:ClearFocus()
            return
        end
        
        local spellId = nil
        -- 需要反向查找：遍历表找到所有匹配的中文名
        if addon.SpellIdToNameCache then
            local matchedIds = {}
            for cachedId, cachedName in pairs(addon.SpellIdToNameCache) do
                if cachedName == text then
                    table.insert(matchedIds, tonumber(cachedId))
                end
            end
            
            -- 如果找到匹配的技能，输出所有同名技能的 ID
            local count = table.getn(matchedIds)
            if count > 0 then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("[PlayTurtle] |cFFFFD700%s|r 找到 %d 个匹配技能：", text, count), 1, 1, 1)
                for i, id in ipairs(matchedIds) do
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] ID: |cFF00FF00%d|r", i, id), 0.8, 0.8, 0.8)
                end
                spellQueryEdit:SetText("")
                spellQueryEdit:ClearFocus()
                return
            end
        end
        
        -- 如果缓存中没有，使用原生 API 查询
        if not spellId then
            spellId = GetSpellIdForName(text)
        end
        
        -- 验证 spellId 有效性（0 或 nil 都表示未找到）
        if spellId and spellId > 0 then
            -- 找到技能，直接显示 ID（名称通过输入框已确认）
            DEFAULT_CHAT_FRAME:AddMessage(string.format("[PlayTurtle] |cFFFFD700%s|r (ID: |cFF00FF00%d|r)", text, spellId), 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 支持查询本职业技能或战斗中显示过技能图标的技能", 1, 0.5, 0.5)
        end
        spellQueryEdit:SetText("")
        spellQueryEdit:ClearFocus()
    end)
    spellQueryEdit:SetScript("OnEnter", function()
        GameTooltip:SetOwner(spellQueryEdit,"ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText("技能ID查询")
        GameTooltip:AddLine("输入技能名称",0.8,0.8,0.8)
        GameTooltip:AddLine("支持本职业技能或战斗中显示过的技能",0.6,0.6,0.6)
        GameTooltip:Show()
    end)
    spellQueryEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 添加 ESC 键清除焦点功能
    spellQueryEdit:SetScript("OnEscapePressed", function()
        spellQueryEdit:ClearFocus()
    end)
    
    f.spellQueryEdit = spellQueryEdit
    
    -- 法术监控标签
    local spellMonitorLabel = f:CreateFontString(nil, "OVERLAY")
    spellMonitorLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    spellMonitorLabel:SetTextColor(1, 1, 1)
    spellMonitorLabel:SetPoint("LEFT", spellMonitorCheck, "RIGHT", 0, 0)
    spellMonitorLabel:SetText("启用")
    
    -- 添加法术按钮（左对齐）
    local addSpellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addSpellBtn:SetWidth(24)
    addSpellBtn:SetHeight(24)  -- 统一高度为 24
    addSpellBtn:SetPoint("LEFT", spellMonitorCheck, "RIGHT", 45, 0)  -- 锚定于复选框右侧
    addSpellBtn:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    addSpellBtn:SetText("+")
    
    -- 删除法术按钮（左对齐）
    local removeSpellBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    removeSpellBtn:SetWidth(24)
    removeSpellBtn:SetHeight(24)  -- 统一高度为 24
    removeSpellBtn:SetPoint("LEFT", addSpellBtn, "RIGHT", 10, 0)
    removeSpellBtn:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    removeSpellBtn:SetText("-")
    
    -- 显示当前监控法术列表按钮（左对齐）
    local showSpellsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    showSpellsBtn:SetWidth(80)
    showSpellsBtn:SetHeight(24)  -- 统一高度为 24
    showSpellsBtn:SetPoint("LEFT", removeSpellBtn, "RIGHT", 60, 0)
    showSpellsBtn:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    showSpellsBtn:SetText("法术列表")
    
    -- 法术按钮点击逻辑（Lua5.0 兼容版）
    addSpellBtn:SetScript("OnClick", function()
        spellInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        shoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
        local spellId = trim(spellInput:GetText())
        if spellId == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入法术 ID！", 1, 1, 1)
            return
        end
            
        -- 检查是否已存在
        if addon.spellsDB[spellId] then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 已存在！", 1, 1, 1)
            spellInput:SetText("")
            return
        end
            
        -- 获取喊话内容和音乐（为空则存 nil）
        local shoutText = trim(shoutInput:GetText())
        local music = soundDropDown._selectedSound
                
        -- 只有非空才存储，否则为 nil（key 已经是字符串，无需 tostring）
        addon.spellsDB[spellId] = {
            shout = (shoutText ~= "") and shoutText or nil,
            music = (music and music ~= "") and music or nil
        }
            
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已添加监控法术 ID："..spellId, 1, 1, 1)
        spellInput:SetText("")
        shoutInput:SetText("")
        soundDropDown._selectedSound = nil
        UIDropDownMenu_SetText("(可选) 音乐", soundDropDown)
        local soundText = _G[soundDropDown:GetName() .. "Text"]
        if soundText then
            soundText:SetTextColor(1, 1, 1, 1)
        end
        spellInput:ClearFocus()  -- 清除焦点
    end)
    
    removeSpellBtn:SetScript("OnClick", function()
        spellInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        shoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
        local spellId = trim(spellInput:GetText())
        if spellId == "" then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 请输入要删除的法术 ID！", 1, 1, 1)
            return
        end
            
        -- 按法术 ID 删除
        if addon.spellsDB[spellId] then
            addon.spellsDB[spellId] = nil
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已删除监控法术 ID："..spellId, 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 法术 ID ["..spellId.."] 不存在！", 1, 1, 1)
        end
        spellInput:SetText("")
        spellInput:ClearFocus()  -- 清除焦点
    end)
    
    showSpellsBtn:SetScript("OnClick", function()
        spellInput:ClearFocus()  -- 清除法术 ID 输入框焦点
        shoutInput:ClearFocus()  -- 清除喊话输入框焦点
        thresholdEdit:ClearFocus()  -- 清除伤害阈值输入框焦点
        
        -- 统计表大小
        local count = 0
        for spellId, data in pairs(addon.spellsDB) do
            count = count + 1
        end
        
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 当前无监控法术！", 1, 1, 1)
            return
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 监控法术列表：", 1, 1, 1)
        local index = 1
        for spellId, data in pairs(addon.spellsDB) do
            -- 通过 GetSpellRecField 直接获取技能名
            local spellName = GetSpellRecField(tonumber(spellId), "name") or "未知技能"
            
            -- 处理喊话内容（无喊话则显示"无"）
            local shoutStr = data.shout or "无"
            
            -- 处理音乐名称（去掉后缀，只显示文件名）
            local musicStr = "无"
            if data.music then
                -- 去掉 .mp3 后缀
                musicStr = string.gsub(data.music, "%.mp3$", "")
            end
            
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. |cFFFFD700%s|r (ID: %s) | 喊话：%s | 音乐：%s", index, spellName, spellId, shoutStr, musicStr), 1, 1, 1)
            index = index + 1
        end
    end)
    
    -- 鼠标提示（Lua5.0兼容）
    addSpellBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addSpellBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("添加法术")
        GameTooltip:AddLine("将法术添加到监控列表", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    addSpellBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    removeSpellBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(removeSpellBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("删除法术")
        GameTooltip:AddLine("从监控列表移除法术", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    removeSpellBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    showSpellsBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(showSpellsBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("法术列表")
        GameTooltip:AddLine("查看当前监控的所有法术", 0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    showSpellsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 保存引用
    f.spellInputLabel = spellInputLabel
    f.spellInput = spellInput
    f.shoutInput = shoutInput
    f.andSymbol = andSymbol
    f.andSymbol2 = andSymbol2
    f.soundDropDown = soundDropDown
    f.addSpellBtn = addSpellBtn
    f.removeSpellBtn = removeSpellBtn
    f.showSpellsBtn = showSpellsBtn

    -- 默认隐藏面板
    f:Hide()

    self.panel = f
    self:CreateFixedPositionIndicator()
end

-- 固定位置指示器
function addon:CreateFixedPositionIndicator()
    if self.fixedPosIndicator then return end
    
    -- -指示器独立于主面板，父级为 UIParent
    local parent = UIParent
    local indicator = CreateFrame("Frame","PlayTurtle_FixedPosIndicator",parent)
    indicator:SetWidth(100)
    indicator:SetHeight(30)
    -- -使用addon.db确保正确读取存档位置
    local x = addon.db and addon.db.fixedPosX or 0
    local y = addon.db and addon.db.fixedPosY or 150
    
    -- -先清除所有锚点，再设置新锚点，避免累积误差
    indicator:ClearAllPoints()
    indicator:SetPoint("CENTER",parent,"CENTER",x,y)
        
    -- 设置与主 UI 一致的背景和边框
    indicator:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    indicator:SetBackdropColor(0, 0, 0, 0.9)
    indicator:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    indicator:SetFrameStrata("MEDIUM")
    indicator:SetMovable(true)
    indicator:RegisterForDrag("LeftButton")
    indicator:EnableMouse(true)

    indicator:SetScript("OnDragStart",function() indicator:StartMoving() end)
    indicator:SetScript("OnDragStop",function()
        indicator:StopMovingOrSizing()
        -- -严格参考受伤框架的保存方法
        local cx,cy = indicator:GetCenter()
        local parentCenterX, parentCenterY = parent:GetCenter()
        addon.db.fixedPosX = cx - parentCenterX
        addon.db.fixedPosY = cy - parentCenterY
    end)
    
    -- -移除OnUpdate中的实时保存逻辑，避免累积误差
    -- OnUpdate不再保存位置，只在拖动停止时保存一次

    local title = indicator:CreateFontString(nil,"OVERLAY")
    title:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
    title:SetPoint("CENTER",0,0)
    title:SetText("固定显示位置")
    title:SetTextColor(0,1,0)
    indicator.title = title

    -- -创建3个数字纹理用于显示AOE合并数量
    indicator.aoeCountTextures = {}
    local digitWidth = 16  -- 每个数字的宽度
    local digitHeight = 20 -- 每个数字的高度
    local spacing = 2      -- 数字之间的间距
    local totalWidth = digitWidth * 3 + spacing * 2
    local startX = -totalWidth / 2 + digitWidth / 2  -- 从左侧开始
    
    for i = 1, 3 do
        local tex = indicator:CreateTexture(nil, "OVERLAY")
        tex:SetWidth(digitWidth)
        tex:SetHeight(digitHeight)
        tex:SetPoint("CENTER", indicator, "CENTER", startX + (i - 1) * (digitWidth + spacing), 0)
        tex:SetTexture("Interface\\AddOns\\PlayTurtle\\img\\num1.blp")  -- 默认使用数字1
        tex:SetTexCoord(0, 1, 0, 1)
        tex:Hide()  -- 初始隐藏
        indicator.aoeCountTextures[i] = tex
    end

    indicator:SetScript("OnEnter",function()
        GameTooltip:SetOwner(indicator,"ANCHOR_CURSOR")
        GameTooltip:SetText("固定显示位置")
        GameTooltip:AddLine("拖动调整位置",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    indicator:SetScript("OnLeave",function() GameTooltip:Hide() end)

    -- -初始化时总是隐藏指示器，等待用户主动打开面板
    indicator:Hide()

    self.fixedPosIndicator = indicator
    addon.fixedPosIndicator = indicator
    
    -- -创建宠物固定位置指示器
    self:CreatePetFixedPositionIndicator()
end

-- -更新固定位置指示器上的AOE合并数量显示
function addon:UpdateAOECountOnIndicator(count)
    if not self.aoeCounterFrame or not self.aoeCounterFrame.textures then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] AOE计数器框体未创建", 1, 0, 0)
        return
    end
    
    local counterFrame = self.aoeCounterFrame
    local textures = counterFrame.textures
    
    -- 如果数量为0或nil，隐藏计数器
    if not count or count <= 0 then
        for i = 1, 3 do
            textures[i]:Hide()
        end
        counterFrame:Hide()
        return
    end
    
    -- 将数字转换为字符串，最多3位
    local countStr = tostring(math.min(count, 999))
    local len = string_len(countStr)
    
    -- 显示对应位数的数字
    for i = 1, 3 do
        if i <= len then
            -- 获取当前位的数字字符
            local digitChar = string_sub(countStr, i, i)
            local digitNum = tonumber(digitChar)
            
            if digitNum and digitNum >= 0 and digitNum <= 9 then
                -- -使用digitUVs设置正确的纹理坐标
                local uv = {
                    [0] = {0/4, 1/4, 0/3, 1/3}, [1] = {1/4, 2/4, 0/3, 1/3},
                    [2] = {2/4, 3/4, 0/3, 1/3}, [3] = {3/4, 4/4, 0/3, 1/3},
                    [4] = {0/4, 1/4, 1/3, 2/3}, [5] = {1/4, 2/4, 1/3, 2/3},
                    [6] = {2/4, 3/4, 1/3, 2/3}, [7] = {3/4, 4/4, 1/3, 2/3},
                    [8] = {0/4, 1/4, 2/3, 3/3}, [9] = {1/4, 2/4, 2/3, 3/3}
                }
                textures[i]:SetTexCoord(uv[digitNum][1], uv[digitNum][2], uv[digitNum][3], uv[digitNum][4])
                textures[i]:Show()
            else
                textures[i]:Hide()
            end
        else
            -- 超出位数的隐藏
            textures[i]:Hide()
        end
    end
    
    -- -AOE伤害产生时，直接显示计数器（不检查DOT框架状态）
    counterFrame:Show()
    counterFrame:SetAlpha(1)  -- 重置Alpha为1，由父框架控制最终透明度
    
    -- -AOE显示时禁用鼠标，防止干扰操作
    counterFrame:EnableMouse(false)
    
    -- -使用全局定时器模拟2秒后隐藏
    -- 记录开始时间
    counterFrame.hideStartTime = GetTime()
    counterFrame.shouldHide = true
end

-- -在主面板打开时显示测试数字999
function addon:ShowAOECounterTestDisplay()
    if not self.aoeCounterFrame or not self.aoeCounterFrame.textures then
        return
    end
    
    local counterFrame = self.aoeCounterFrame
    local textures = counterFrame.textures
    
    -- 显示999
    local testStr = "999"
    for i = 1, 3 do
        local digitNum = tonumber(string_sub(testStr, i, i))
        if digitNum and digitNum >= 0 and digitNum <= 9 then
            local uv = {
                [0] = {0/4, 1/4, 0/3, 1/3}, [1] = {1/4, 2/4, 0/3, 1/3},
                [2] = {2/4, 3/4, 0/3, 1/3}, [3] = {3/4, 4/4, 0/3, 1/3},
                [4] = {0/4, 1/4, 1/3, 2/3}, [5] = {1/4, 2/4, 1/3, 2/3},
                [6] = {2/4, 3/4, 1/3, 2/3}, [7] = {3/4, 4/4, 1/3, 2/3},
                [8] = {0/4, 1/4, 2/3, 3/3}, [9] = {1/4, 2/4, 2/3, 3/3}
            }
            textures[i]:SetTexCoord(uv[digitNum][1], uv[digitNum][2], uv[digitNum][3], uv[digitNum][4])
            textures[i]:Show()
        end
    end
    
    -- -主面板打开时，仅在DOT框架可见时显示计数器
    if addon.ReceivedUI and addon.ReceivedUI.labelDOT and addon.ReceivedUI.labelDOT:IsShown() then
        counterFrame:Show()
        counterFrame:SetAlpha(1)  -- 重置Alpha为1，由父框架控制最终透明度
        
        -- -主面板打开时启用鼠标，允许拖动调整位置
        counterFrame:EnableMouse(true)
    else
        -- DOT框架不可见时，不显示计数器
        for i = 1, 3 do
            textures[i]:Hide()
        end
        counterFrame:Hide()
    end
end

-- -创建AOE计数器框体
function addon:CreateAOECounterFrame()
    if self.aoeCounterFrame then return end
    
    -- -AOE计数器作为DOT框架的子元素，父级为DOT框架
    local parent = addon.DOTFrame or UIParent
    
    local counterFrame = CreateFrame("Frame", "PlayTurtle_AOECounter", parent)
    counterFrame:SetWidth(80)  -- -放大宽度从60到80
    counterFrame:SetHeight(40)  -- -放大高度从30到40
    
    -- -锚定到 DOT 框架，从数据库读取偏移量
    counterFrame:ClearAllPoints()
    local offsetX = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetX or 0
    -- -默认偏移量应该是DOT框架高度的一半+10，让计数器显示在底部下方
    local defaultOffsetY = -(parent.GetHeight and parent:GetHeight() / 2 + 10 or 30)
    local offsetY = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetY or defaultOffsetY
    counterFrame:SetPoint("CENTER", parent, "CENTER", offsetX, offsetY)
    
    -- -去除背景和边框，只显示数字
    counterFrame:SetBackdrop(nil)
    
    -- -设置更高的FrameLevel，确保在DOT框架之上
    counterFrame:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0) + 10)
    
    counterFrame:SetMovable(true)
    counterFrame:RegisterForDrag("LeftButton")
    counterFrame:EnableMouse(true)
    counterFrame:Hide()  -- 初始隐藏
    
    -- 拖动脚本
    counterFrame:SetScript("OnDragStart", function()
        counterFrame:StartMoving()
    end)
    counterFrame:SetScript("OnDragStop", function()
        counterFrame:StopMovingOrSizing()
        -- -拖动停止后，计算并保存相对于DOT框架的偏移量
        if addon.DOTFrame then
            -- 获取AOE计数器和DOT框架的中心点
            local counterCenterX, counterCenterY = counterFrame:GetCenter()
            local dotCenterX, dotCenterY = addon.DOTFrame:GetCenter()
            
            if counterCenterX and counterCenterY and dotCenterX and dotCenterY then
                -- 计算相对偏移
                local offsetX = counterCenterX - dotCenterX
                local offsetY = counterCenterY - dotCenterY
                
                -- 保存到数据库
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.aoeCounterOffsetX = offsetX
                    PTURTLE_Combat_DB.aoeCounterOffsetY = offsetY
                end
                
                -- 重新锚定到DOT框架，使用保存的偏移量
                counterFrame:ClearAllPoints()
                counterFrame:SetPoint("CENTER", addon.DOTFrame, "CENTER", offsetX, offsetY)
            end
        end
    end)
    
    -- -移除OnUpdate中的实时保存逻辑，避免累积误差
    -- OnUpdate不再保存位置，只在拖动停止时保存一次
    
    -- 创建3个数字纹理用于显示AOE合并数量
    counterFrame.textures = {}
    local digitWidth = 22  -- -放大数字宽度从16到22
    local digitHeight = 28 -- -放大数字高度从20到28
    local spacing = -4     -- -数字之间重叠4像素，让数字更紧凑
    local totalWidth = digitWidth * 3 + spacing * 2
    local startX = -totalWidth / 2 + digitWidth / 2  -- 从左侧开始
    
    -- -使用num3.blp精灵图，并设置正确的纹理坐标
    for i = 1, 3 do
        local tex = counterFrame:CreateTexture(nil, "OVERLAY")
        tex:SetWidth(digitWidth)
        tex:SetHeight(digitHeight)
        tex:SetPoint("CENTER", counterFrame, "CENTER", startX + (i - 1) * (digitWidth + spacing), 0)
        tex:SetTexture("Interface\\AddOns\\PlayTurtle\\img\\num3.blp")  -- 固定使用num3精灵图
        -- -设置默认纹理坐标为数字0的位置
        tex:SetTexCoord(0/4, 1/4, 0/3, 1/3)
        tex:Hide()  -- 初始隐藏
        counterFrame.textures[i] = tex
    end
    
    -- Tooltip
    counterFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(counterFrame, "ANCHOR_CURSOR")
        GameTooltip:SetText("AOE合并计数器")
        GameTooltip:AddLine("显示AOE技能合并的伤害/治疗次数", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("锚定到DOT框架下方", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    counterFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.aoeCounterFrame = counterFrame
    addon.aoeCounterFrame = counterFrame
    
    -- -初始化时总是隐藏计数器，等待用户主动打开面板
    counterFrame:Hide()
end

-- -宠物固定位置指示器
function addon:CreatePetFixedPositionIndicator()
    if self.petFixedPosIndicator then return end
    
    -- -指示器独立于主面板，父级为 UIParent
    local parent = UIParent
    local indicator = CreateFrame("Frame","PlayTurtle_PetFixedPosIndicator",parent)
    indicator:SetWidth(100)
    indicator:SetHeight(30)
    -- -使用addon.db确保正确读取存档位置
    local x = addon.db and addon.db.fixedPosPetX or 0
    local y = addon.db and addon.db.fixedPosPetY or 150
    
    -- -先清除所有锚点，再设置新锚点，避免累积误差
    indicator:ClearAllPoints()
    indicator:SetPoint("CENTER",parent,"CENTER",x,y)
        
    -- 设置与主 UI 一致的背景和边框
    indicator:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    indicator:SetBackdropColor(0, 0, 0.5, 0.9)  -- 蓝色背景（宠物）
    indicator:SetBackdropBorderColor(0.5, 0.5, 1, 1)
    
    indicator:SetFrameStrata("MEDIUM")
    indicator:SetMovable(true)
    indicator:RegisterForDrag("LeftButton")
    indicator:EnableMouse(true)

    indicator:SetScript("OnDragStart",function() indicator:StartMoving() end)
    indicator:SetScript("OnDragStop",function()
        indicator:StopMovingOrSizing()
        -- -严格参考受伤框架的保存方法
        local cx,cy = indicator:GetCenter()
        local parentCenterX, parentCenterY = parent:GetCenter()
        addon.db.fixedPosPetX = cx - parentCenterX
        addon.db.fixedPosPetY = cy - parentCenterY
    end)
    
    -- -移除OnUpdate中的实时保存逻辑，避免累积误差
    -- OnUpdate不再保存位置，只在拖动停止时保存一次

    local title = indicator:CreateFontString(nil,"OVERLAY")
    title:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
    title:SetPoint("CENTER",0,0)
    title:SetText("宠物固定位置")
    title:SetTextColor(0.5,0.5,1)
    indicator.title = title

    indicator:SetScript("OnEnter",function()
        GameTooltip:SetOwner(indicator,"ANCHOR_CURSOR")
        GameTooltip:SetText("宠物固定显示位置")
        GameTooltip:AddLine("拖动调整位置",0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    indicator:SetScript("OnLeave",function() GameTooltip:Hide() end)

    -- -初始化时总是隐藏指示器，等待用户主动打开面板
    indicator:Hide()

    self.petFixedPosIndicator = indicator
    addon.petFixedPosIndicator = indicator
end

-- 创建受到治疗位置指示器
-- 文字设置子面板（两列布局 + 点击颜色框呼出选择器）
function addon:CreateSubPanel()
    if self.subPanel then return end
    local sub = CreateFrame("Frame","PTURTLE_Combat_SubPanel",UIParent)
    sub:SetWidth(500)
    sub:SetHeight(400)
    sub:SetFrameStrata("HIGH")
    sub:EnableMouse(1)
    sub:SetMovable(1)
    sub:RegisterForDrag("LeftButton")

    sub:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}
    })
    sub:SetBackdropColor(0,0,0,0.9)
    sub:SetBackdropBorderColor(0.5,0.5,0.5,1)

    local title = sub:CreateFontString(nil,"OVERLAY")
    title:SetFont(STANDARD_TEXT_FONT,14,"OUTLINE")
    title:SetPoint("TOP",sub,"TOP",0,-8)
    title:SetText("文字设置面板")
    title:SetTextColor(1,1,1)
    sub.title = title

    local closeBtn = CreateFrame("Button",nil,sub,"UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT",sub,"TOPRIGHT",-5,-5)
    closeBtn:SetScript("OnClick",function()
        sub:Hide()
        if addon.panel then 
            addon.panel:Show()
            
            -- -面板显示时，根据开关状态显示固定位置指示器
            if (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true) and addon.fixedPosIndicator then
                addon.fixedPosIndicator:Show()
            end
            if (addon.db.fixedPosPetEnabled == 1 or addon.db.fixedPosPetEnabled == true) and addon.petFixedPosIndicator then
                addon.petFixedPosIndicator:Show()
            end
        end
        
        -- 关闭文字设置面板时停止预览模式
        addon:StopPreviewMode()
    end)
    sub.closeBtn = closeBtn

    sub:SetScript("OnDragStart",function() sub:StartMoving() end)
    sub:SetScript("OnDragStop",function() sub:StopMovingOrSizing() end)

    -- -左侧受伤/受疗/输出治疗队列控制面板按钮（竖向）
    local expandBtn = CreateFrame("Button", nil, sub)
    expandBtn:SetWidth(20)
    expandBtn:SetHeight(sub:GetHeight())  -- 与面板同高
    expandBtn:SetPoint("LEFT", sub, "LEFT", 0, 0)
    
    -- 设置按钮背景
    expandBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    expandBtn:SetBackdropColor(0.2, 0.2, 0.3, 0.8)
    expandBtn:SetBackdropBorderColor(0.5, 0.5, 0.8, 1)
    
    -- 创建左箭头图标（使用 WoW 支持的符号）
    local arrowText = expandBtn:CreateFontString(nil, "OVERLAY")
    arrowText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    arrowText:SetPoint("CENTER", expandBtn, "CENTER", 0, 0)
    arrowText:SetText("<")
    arrowText:SetTextColor(1, 1, 1, 1)
    
    -- 点击展开/收起子菜单
    expandBtn:SetScript("OnClick", function()
        if not sub.expandedMenu then
            -- 创建受伤/受疗/输出治疗队列控制面板（直接挂在文字设置面板上）
            local menu = CreateFrame("Frame", nil, sub)
            menu:SetWidth(250)  -- 宽度为面板的一半
            menu:SetHeight(sub:GetHeight())
            menu:SetPoint("RIGHT", sub, "LEFT", -2, 0)  -- 在面板左侧
            
            menu:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            menu:SetBackdropColor(0.1, 0.1, 0.2, 0.95)
            menu:SetBackdropBorderColor(0.4, 0.4, 0.7, 1)
            
            local menuTitle = menu:CreateFontString(nil, "OVERLAY")
            menuTitle:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
            menuTitle:SetPoint("TOP", menu, "TOP", 0, -5)
            menuTitle:SetText("受伤/受疗/输出治疗队列控制")
            menuTitle:SetTextColor(1, 0.8, 0.4)
            
            sub.expandedMenu = menu
            menu:Show()
            
            -- ✅ 添加贝塞尔曲线速率滑块（受伤/受治疗/输出治疗专用）
            local bezierSlider = CreateFrame("Slider", "PT_BezierSpeedSlider", menu, "OptionsSliderTemplate")
            bezierSlider:SetWidth(170)  -- ✅ 参考其他滑块宽度
            bezierSlider:SetHeight(20)  -- ✅ 参考其他滑块高度
            bezierSlider:SetPoint("TOP", menuTitle, "BOTTOM", -30, -15)
            bezierSlider:SetMinMaxValues(50, 220)  -- ✅ 区间 50-220
            bezierSlider:SetValueStep(1)  -- ✅ 步进 1
            bezierSlider:SetValue(addon.Config.UserSettings.receivedMoveSpeed or 110)  -- ✅ 默认值 110
            
            -- 设置滑块文本
            getglobal(bezierSlider:GetName() .. "Low"):SetText("50")
            getglobal(bezierSlider:GetName() .. "High"):SetText("220")
            local sliderText = getglobal(bezierSlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local bezierTitle = menu:CreateFontString(nil, "OVERLAY")
            bezierTitle:SetFont(STANDARD_TEXT_FONT, 12)
            bezierTitle:SetPoint("BOTTOM", bezierSlider, "TOP", 0, 1)
            bezierTitle:SetText("队列系统速度")
            
            -- 创建当前值显示
            local bezierValueText = menu:CreateFontString(nil, "OVERLAY")
            bezierValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            bezierValueText:SetPoint("LEFT", bezierSlider, "RIGHT", 10, 0)
            bezierValueText:SetTextColor(1, 1, 0.5)
            bezierValueText:SetText(tostring(math.floor(bezierSlider:GetValue())))
            
            -- 滑块拖动事件
            bezierSlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())  -- ✅ Lua 5.0 使用 this:GetValue()
                addon.Config.UserSettings.receivedMoveSpeed = value  -- ✅ 使用独立变量
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.receivedMoveSpeed = value  -- ✅ 保存到存档
                end
                bezierValueText:SetText(tostring(value))
            end)
            
            -- Tooltip
            bezierSlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(bezierSlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("队列系统速度", 1, 1, 1)
                GameTooltip:AddLine("控制所有队列的移动速率", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("影响队列布局和推开逻辑的间距计算", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("数值越大，动画越快", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            bezierSlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.bezierSlider = bezierSlider
            menu.bezierValueText = bezierValueText
            
            -- ✅ 添加队列行距滑块（控制额外行距）
            local spacingSlider = CreateFrame("Slider", "PT_QueueSpacingSlider", menu, "OptionsSliderTemplate")
            spacingSlider:SetWidth(170)
            spacingSlider:SetHeight(20)
            spacingSlider:SetPoint("TOP", bezierSlider, "BOTTOM", 0, -15)
            spacingSlider:SetMinMaxValues(-10, 10)  -- 区间 -10 到 +10
            spacingSlider:SetValueStep(1)  -- 步进 1
            spacingSlider:SetValue(addon.Config.UserSettings.queueSpacing or 0)  -- 默认值 0
            
            -- 设置滑块文本
            getglobal(spacingSlider:GetName() .. "Low"):SetText("-10")
            getglobal(spacingSlider:GetName() .. "High"):SetText("10")
            local sliderText = getglobal(spacingSlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local spacingTitle = menu:CreateFontString(nil, "OVERLAY")
            spacingTitle:SetFont(STANDARD_TEXT_FONT, 12)
            spacingTitle:SetPoint("BOTTOM", spacingSlider, "TOP", 0, 1)
            spacingTitle:SetText("队列行距")
            
            -- 创建当前值显示
            local spacingValueText = menu:CreateFontString(nil, "OVERLAY")
            spacingValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            spacingValueText:SetPoint("LEFT", spacingSlider, "RIGHT", 10, 0)
            spacingValueText:SetTextColor(1, 1, 0.5)
            spacingValueText:SetText(tostring(math.floor(spacingSlider:GetValue())))
            
            -- 滑块拖动事件
            spacingSlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())
                addon.Config.UserSettings.queueSpacing = value
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.queueSpacing = value
                end
                spacingValueText:SetText(tostring(value))
            end)
            
            -- Tooltip
            spacingSlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(spacingSlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("队列行距", 1, 1, 1)
                GameTooltip:AddLine("控制队列中数字之间的额外间距", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("正值增加间距，负值减少间距", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("影响队列布局和推开逻辑", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            spacingSlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.spacingSlider = spacingSlider
            menu.spacingValueText = spacingValueText
            
            -- ✅ 添加队列字符大小滑块（独立控制队列系统字符大小）
            local queueFontSizeSlider = CreateFrame("Slider", "PT_QueueFontSizeSlider", menu, "OptionsSliderTemplate")
            queueFontSizeSlider:SetWidth(170)
            queueFontSizeSlider:SetHeight(20)
            queueFontSizeSlider:SetPoint("TOP", spacingSlider, "BOTTOM", 0, -15)
            queueFontSizeSlider:SetMinMaxValues(30, 60)  -- 区间 30-60
            queueFontSizeSlider:SetValueStep(1)  -- 步进 1
            queueFontSizeSlider:SetValue(addon.Config.UserSettings.queueFontSize or 40)  -- 默认值 40
            
            -- 设置滑块文本
            getglobal(queueFontSizeSlider:GetName() .. "Low"):SetText("30")
            getglobal(queueFontSizeSlider:GetName() .. "High"):SetText("60")
            local sliderText = getglobal(queueFontSizeSlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local queueFontSizeTitle = menu:CreateFontString(nil, "OVERLAY")
            queueFontSizeTitle:SetFont(STANDARD_TEXT_FONT, 12)
            queueFontSizeTitle:SetPoint("BOTTOM", queueFontSizeSlider, "TOP", 0, 1)
            queueFontSizeTitle:SetText("队列字符大小")
            
            -- 创建当前值显示
            local queueFontSizeValueText = menu:CreateFontString(nil, "OVERLAY")
            queueFontSizeValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            queueFontSizeValueText:SetPoint("LEFT", queueFontSizeSlider, "RIGHT", 10, 0)
            queueFontSizeValueText:SetTextColor(1, 1, 0.5)
            queueFontSizeValueText:SetText(tostring(math.floor(queueFontSizeSlider:GetValue())))
            
            -- 滑块拖动事件
            queueFontSizeSlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())
                addon.Config.UserSettings.queueFontSize = value
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.queueFontSize = value
                end
                queueFontSizeValueText:SetText(tostring(value))
            end)
            
            -- Tooltip
            queueFontSizeSlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(queueFontSizeSlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("队列字符大小", 1, 1, 1)
                GameTooltip:AddLine("独立控制队列系统的字符大小", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("影响受伤/受疗/输出治疗队列的数字大小", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("不影响造成伤害队列的字符大小", 0.8, 0.6, 0.6)
                GameTooltip:Show()
            end)
            queueFontSizeSlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.queueFontSizeSlider = queueFontSizeSlider
            menu.queueFontSizeValueText = queueFontSizeValueText
            
            -- ✅ 添加队列暴击缩放滑块（控制DOT队列暴击放大倍数）
            local queueCritScaleSlider = CreateFrame("Slider", "PT_QueueCritScaleSlider", menu, "OptionsSliderTemplate")
            queueCritScaleSlider:SetWidth(170)
            queueCritScaleSlider:SetHeight(20)
            queueCritScaleSlider:SetPoint("TOP", queueFontSizeSlider, "BOTTOM", 0, -15)
            queueCritScaleSlider:SetMinMaxValues(1.5, 3.0)  -- 区间 1.5-3.0
            queueCritScaleSlider:SetValueStep(0.1)  -- 步进 0.1
            queueCritScaleSlider:SetValue(addon.Config.UserSettings.queueCritScale or 2.0)  -- 默认值 2.0
            
            -- 设置滑块文本
            getglobal(queueCritScaleSlider:GetName() .. "Low"):SetText("1.5")
            getglobal(queueCritScaleSlider:GetName() .. "High"):SetText("3.0")
            local sliderText = getglobal(queueCritScaleSlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local queueCritScaleTitle = menu:CreateFontString(nil, "OVERLAY")
            queueCritScaleTitle:SetFont(STANDARD_TEXT_FONT, 12)
            queueCritScaleTitle:SetPoint("BOTTOM", queueCritScaleSlider, "TOP", 0, 1)
            queueCritScaleTitle:SetText("队列暴击缩放")
            
            -- 创建当前值显示
            local queueCritScaleValueText = menu:CreateFontString(nil, "OVERLAY")
            queueCritScaleValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            queueCritScaleValueText:SetPoint("LEFT", queueCritScaleSlider, "RIGHT", 10, 0)
            queueCritScaleValueText:SetTextColor(1, 1, 0.5)
            queueCritScaleValueText:SetText(string.format("%.1f", queueCritScaleSlider:GetValue()))
            
            -- 滑块拖动事件
            queueCritScaleSlider:SetScript("OnValueChanged", function()
                local value = this:GetValue()
                addon.Config.UserSettings.queueCritScale = value
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.queueCritScale = value
                end
                queueCritScaleValueText:SetText(string.format("%.1f", value))
            end)
            
            -- Tooltip
            queueCritScaleSlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(queueCritScaleSlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("队列暴击缩放", 1, 1, 1)
                GameTooltip:AddLine("控制队列暴击时的最大放大倍数", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("范围: 1.5倍 - 3.0倍", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("不影响非暴击伤害的缩放", 0.8, 0.6, 0.6)
                GameTooltip:Show()
            end)
            queueCritScaleSlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.queueCritScaleSlider = queueCritScaleSlider
            menu.queueCritScaleValueText = queueCritScaleValueText
            
            -- ✅ 添加宠物队列X偏移滑块（放在暴击伤害震动标题上方）
            local petQueueXSlider = CreateFrame("Slider", "PT_PetQueueXSlider", menu, "OptionsSliderTemplate")
            petQueueXSlider:SetWidth(170)
            petQueueXSlider:SetHeight(20)
            petQueueXSlider:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 10, 145)  -- 在暴击伤害震动标题(80)上方65像素
            petQueueXSlider:SetMinMaxValues(-200, 200)  -- -200~200
            petQueueXSlider:SetValueStep(1)
            petQueueXSlider:SetValue(PTURTLE_Combat_DB and PTURTLE_Combat_DB.petQueueXOffset or 0)  -- 默认0
            
            getglobal(petQueueXSlider:GetName().."Low"):SetText("-200")
            getglobal(petQueueXSlider:GetName().."High"):SetText("200")
            local sliderText = getglobal(petQueueXSlider:GetName().."Text")
            sliderText:SetText("")
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local petQueueXTitle = menu:CreateFontString(nil, "OVERLAY")
            petQueueXTitle:SetFont(STANDARD_TEXT_FONT, 12)
            petQueueXTitle:SetPoint("BOTTOM", petQueueXSlider, "TOP", 0, 1)
            petQueueXTitle:SetText("宠物伤害X偏移")
            
            local petQueueXValueText = menu:CreateFontString(nil, "OVERLAY")
            petQueueXValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            petQueueXValueText:SetPoint("LEFT", petQueueXSlider, "RIGHT", 10, 0)
            petQueueXValueText:SetTextColor(1, 1, 1)
            petQueueXValueText:SetText(tostring(math.floor(petQueueXSlider:GetValue())))
            
            petQueueXSlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())
                this.valText:SetText(tostring(value))
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.petQueueXOffset = value
                end
                if addon.Config and addon.Config.UserSettings then
                    addon.Config.UserSettings.petQueueXOffset = value
                end
            end)
            petQueueXSlider.valText = petQueueXValueText
            
            petQueueXSlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("宠物队列X偏移", 1, 1, 1)
                GameTooltip:AddLine("控制宠物在队列模式中的X轴偏移（-200~200像素）", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("仅用于动画A队列、受伤/受疗队列", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            petQueueXSlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.petQueueXTitle = petQueueXTitle
            menu.petQueueXSlider = petQueueXSlider
            menu.petQueueXValueText = petQueueXValueText
            
            -- ✅ 添加暴击伤害震动标题和勾选框
            local shakeTitle = menu:CreateFontString(nil, "OVERLAY")
            shakeTitle:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
            shakeTitle:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 10, 80)
            shakeTitle:SetText("暴击伤害震动")
            shakeTitle:SetTextColor(1, 0.8, 0.4)
            
            local shakeCheckbox = CreateFrame("CheckButton", "PT_CritShakeCheckbox", menu, "UICheckButtonTemplate")
            shakeCheckbox:SetWidth(24)
            shakeCheckbox:SetHeight(24)
            shakeCheckbox:SetPoint("LEFT", shakeTitle, "RIGHT", 5, 0)
            shakeCheckbox:SetChecked(PTURTLE_Combat_DB and PTURTLE_Combat_DB.critNumberShakeEnabled or 0)
            
            shakeCheckbox:SetScript("OnClick", function()
                local isChecked = this:GetChecked() and 1 or 0
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.critNumberShakeEnabled = isChecked
                end
                addon:SyncConfigFromDB()
            end)
            
            shakeCheckbox:SetScript("OnEnter", function()
                GameTooltip:SetOwner(shakeCheckbox, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("启用暴击伤害震动", 1, 1, 1)
                GameTooltip:AddLine("勾选后暴击数字会产生震动效果", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            shakeCheckbox:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            --  添加队列暴击震动勾选框（在暴击伤害震动右侧）
            local queueShakeCheckbox = CreateFrame("CheckButton", "PT_QueueCritShakeCheckbox", menu, "UICheckButtonTemplate")
            queueShakeCheckbox:SetWidth(24)
            queueShakeCheckbox:SetHeight(24)
            queueShakeCheckbox:SetPoint("LEFT", shakeCheckbox, "RIGHT", 0, 0)
            queueShakeCheckbox:SetChecked(PTURTLE_Combat_DB and PTURTLE_Combat_DB.queueCritShakeEnabled or 0)
            
            queueShakeCheckbox:SetScript("OnClick", function()
                local isChecked = this:GetChecked() and 1 or 0
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.queueCritShakeEnabled = isChecked
                end
                addon:SyncConfigFromDB()
            end)
            
            queueShakeCheckbox:SetScript("OnEnter", function()
                GameTooltip:SetOwner(queueShakeCheckbox, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("启用队列暴击震动", 1, 1, 1)
                GameTooltip:AddLine("勾选后受伤/受疗/输出治疗队列的暴击数字会产生震动效果", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("不影响非暴击伤害", 0.8, 0.6, 0.6)
                GameTooltip:Show()
            end)
            queueShakeCheckbox:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            local queueShakeTitle = menu:CreateFontString(nil, "OVERLAY")
            queueShakeTitle:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
            queueShakeTitle:SetPoint("LEFT", queueShakeCheckbox, "RIGHT", 5, 0)
            queueShakeTitle:SetText("队列暴击震动")
            queueShakeTitle:SetTextColor(1, 0.8, 0.4)
            
            menu.shakeTitle = shakeTitle
            menu.shakeCheckbox = shakeCheckbox
            
            -- ✅ 添加暴击抖动强度滑块
            local shakeIntensitySlider = CreateFrame("Slider", "PT_CritShakeIntensitySlider", menu, "OptionsSliderTemplate")
            shakeIntensitySlider:SetWidth(170)
            shakeIntensitySlider:SetHeight(20)
            shakeIntensitySlider:SetPoint("TOPLEFT", shakeTitle, "BOTTOMLEFT", 0, -15)
            shakeIntensitySlider:SetMinMaxValues(10, 50)  -- 1.0-5.0，步进0.1（实际值除以10）
            shakeIntensitySlider:SetValueStep(1)
            shakeIntensitySlider:SetValue(PTURTLE_Combat_DB and PTURTLE_Combat_DB.critShakeIntensityValue or 10)  -- 默认1.0
            
            getglobal(shakeIntensitySlider:GetName() .. "Low"):SetText("1.0")
            getglobal(shakeIntensitySlider:GetName() .. "High"):SetText("5.0")
            local sliderText = getglobal(shakeIntensitySlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local shakeIntensityTitle = menu:CreateFontString(nil, "OVERLAY")
            shakeIntensityTitle:SetFont(STANDARD_TEXT_FONT, 12)
            shakeIntensityTitle:SetPoint("BOTTOM", shakeIntensitySlider, "TOP", 0, 1)
            shakeIntensityTitle:SetText("暴击伤害抖动强度")
            
            local intensityValueText = menu:CreateFontString(nil, "OVERLAY")
            intensityValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            intensityValueText:SetPoint("LEFT", shakeIntensitySlider, "RIGHT", 10, 0)
            intensityValueText:SetTextColor(1, 1, 0.5)
            intensityValueText:SetText(string.format("%.1f", shakeIntensitySlider:GetValue() / 10))  -- 显示为1位小数
            
            shakeIntensitySlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.critShakeIntensityValue = value
                end
                intensityValueText:SetText(string.format("%.1f", value / 10))  -- 显示为1位小数
                addon:SyncConfigFromDB()
            end)
            
            shakeIntensitySlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(shakeIntensitySlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("暴击伤害抖动强度", 1, 1, 1)
                GameTooltip:AddLine("控制暴击数字抖动的最大偏移量（像素）", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            shakeIntensitySlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            -- ✅ 添加暴击抖动频率滑块
            local shakeFrequencySlider = CreateFrame("Slider", "PT_CritShakeFrequencySlider", menu, "OptionsSliderTemplate")
            shakeFrequencySlider:SetWidth(170)
            shakeFrequencySlider:SetHeight(20)
            shakeFrequencySlider:SetPoint("TOPLEFT", shakeTitle, "BOTTOMLEFT", 0, -50)
            shakeFrequencySlider:SetMinMaxValues(5, 15)
            shakeFrequencySlider:SetValueStep(1)
            shakeFrequencySlider:SetValue(PTURTLE_Combat_DB and PTURTLE_Combat_DB.leftSlider7Value or 10)
            
            getglobal(shakeFrequencySlider:GetName() .. "Low"):SetText("5")
            getglobal(shakeFrequencySlider:GetName() .. "High"):SetText("15")
            local sliderText = getglobal(shakeFrequencySlider:GetName() .. "Text")
            sliderText:SetText("")  -- ✅ 清空模板自带的Text
            sliderText:Hide()  -- ✅ 隐藏模板自带的Text
            
            -- ✅ 创建独立标题（参考OptionsSliderTemplate样式）
            local shakeFrequencyTitle = menu:CreateFontString(nil, "OVERLAY")
            shakeFrequencyTitle:SetFont(STANDARD_TEXT_FONT, 12)
            shakeFrequencyTitle:SetPoint("BOTTOM", shakeFrequencySlider, "TOP", 0, 1)
            shakeFrequencyTitle:SetText("暴击伤害抖动频率")
            
            local frequencyValueText = menu:CreateFontString(nil, "OVERLAY")
            frequencyValueText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            frequencyValueText:SetPoint("LEFT", shakeFrequencySlider, "RIGHT", 10, 0)
            frequencyValueText:SetTextColor(1, 1, 0.5)
            frequencyValueText:SetText(tostring(math.floor(shakeFrequencySlider:GetValue())))
            
            shakeFrequencySlider:SetScript("OnValueChanged", function()
                local value = math.floor(this:GetValue())
                if PTURTLE_Combat_DB then
                    PTURTLE_Combat_DB.leftSlider7Value = value
                end
                frequencyValueText:SetText(tostring(value))
                addon:SyncConfigFromDB()
            end)
            
            shakeFrequencySlider:SetScript("OnEnter", function()
                GameTooltip:SetOwner(shakeFrequencySlider, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("暴击伤害抖动频率", 1, 1, 1)
                GameTooltip:AddLine("控制暴击数字每秒抖动的次数（Hz）", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            shakeFrequencySlider:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            menu.shakeIntensitySlider = shakeIntensitySlider
            menu.shakeFrequencySlider = shakeFrequencySlider
            
            -- 旋转箭头（向右）
            arrowText:SetText(">")
        else
            -- 隐藏受伤/受疗/输出治疗队列控制面板
            sub.expandedMenu:Hide()
            sub.expandedMenu = nil
            
            -- 恢复箭头（向左）
            arrowText:SetText("<")
        end
    end)
    
    -- Tooltip
    expandBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(expandBtn, "ANCHOR_LEFT")
        GameTooltip:SetText("受伤/受疗/输出治疗队列控制", 1, 1, 1)
        GameTooltip:AddLine("点击展开/收起左侧控制面板", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    expandBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    sub.expandBtn = expandBtn

    local sliderWidth = 170
    local sliderHeight = 20
    local colOffsetX = 25
    local colOffsetY = -20
    local sliderSpacing = 18

    local leftTitles = {"一阶缩放","二阶缩放","停留时间","锚点X偏移","锚点Y偏移","X轴偏移"}
    local rightTitles = {"淡出速度","浮动速度（含队列模式）","字符大小（含队列模式）","X 分布","Y 分布","行距 [A]（含队列模式）","存活时间 [A]","（全局）字符间距","（全局）字体样式"}

    local leftCol = sub:CreateFontString(nil,"OVERLAY")
    leftCol:SetFont(STANDARD_TEXT_FONT,16,"OUTLINE")
    leftCol:SetTextColor(1,0.8,0)
    leftCol:SetPoint("TOPLEFT",sub,"TOPLEFT",colOffsetX+25,colOffsetY-6)
    leftCol:SetText("造成暴击控制")

    local rightCol = sub:CreateFontString(nil,"OVERLAY")
    rightCol:SetFont(STANDARD_TEXT_FONT,16,"OUTLINE")
    rightCol:SetTextColor(0.8,1,0.8)
    rightCol:SetPoint("TOPRIGHT",sub,"TOPRIGHT",-colOffsetX-25,colOffsetY-6)
    rightCol:SetText("造成非暴击控制")
    
    -- -非暴击动画切换按钮（类似宠物固定开关样式）
    local animToggleBtn = CreateFrame("Button", "PT_NormalAnimToggle", sub)
    animToggleBtn:SetWidth(25)
    animToggleBtn:SetHeight(22)
    animToggleBtn:SetPoint("RIGHT", rightCol, "LEFT", -8, 0)  -- 在标题左侧
    
    -- 设置按钮背景
    animToggleBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local animToggleText = animToggleBtn:CreateFontString(nil, "OVERLAY")
    animToggleText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    animToggleText:SetPoint("CENTER", animToggleBtn, "CENTER", 0, 0)
    
    -- 从存档读取当前动画模式（默认 A）
    local currentAnimMode = addon.db and addon.db.normalAnimMode or "A"
    
    -- 更新按钮状态函数
    local function updateAnimToggle()
        if currentAnimMode == "A" then
            -- A模式：向上淡出（蓝色）
            animToggleBtn:SetBackdropBorderColor(0.3, 0.6, 1, 1)
            animToggleBtn:SetBackdropColor(0, 0.2, 0.4, 0.5)
            animToggleText:SetText("A")
            animToggleText:SetTextColor(0.5, 0.8, 1, 1)
        elseif currentAnimMode == "B" then
            -- B模式：抛物线（绿色）
            animToggleBtn:SetBackdropBorderColor(0, 1, 0, 1)
            animToggleBtn:SetBackdropColor(0, 0.3, 0, 0.5)
            animToggleText:SetText("B")
            animToggleText:SetTextColor(0, 1, 0, 1)
        else
            -- C模式：回力(不是鞋)（黄色）
            animToggleBtn:SetBackdropBorderColor(1, 0.8, 0, 1)
            animToggleBtn:SetBackdropColor(0.4, 0.3, 0, 0.5)
            animToggleText:SetText("C")
            animToggleText:SetTextColor(1, 0.9, 0.2, 1)
        end
    end
    
    -- 初始化按钮状态
    updateAnimToggle()
    
    -- 点击切换动画模式：A -> B -> C -> A
    animToggleBtn:SetScript("OnClick", function()
        if currentAnimMode == "A" then
            currentAnimMode = "B"
        elseif currentAnimMode == "B" then
            currentAnimMode = "C"
        else
            currentAnimMode = "A"
        end
        
        -- 保存到存档
        if not addon.db then addon.db = {} end
        addon.db.normalAnimMode = currentAnimMode
        PTURTLE_Combat_DB.normalAnimMode = currentAnimMode
        
        -- 更新按钮状态
        updateAnimToggle()
        
        -- 提示用户
        DEFAULT_CHAT_FRAME:AddMessage(string.format("[PlayTurtle] 非暴击动画切换为：%s 模式", currentAnimMode), 0, 1, 0)
    end)
    
    -- Tooltip 说明
    animToggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(animToggleBtn, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("非暴击动画模式", 1, 1, 0.2)
        
        -- 根据当前模式显示对应的说明
        if currentAnimMode == "A" then
            GameTooltip:AddLine("当前模式：A - 向上淡出", 1, 0.8, 0.4)
            GameTooltip:AddLine("• 简单向上移动并淡出", 1, 0.9, 0.7)
            GameTooltip:AddLine("• 有队列系统，防重叠", 1, 0.9, 0.7)
        elseif currentAnimMode == "B" then
            GameTooltip:AddLine("当前模式：B - 抛物线", 0.6, 1, 0.6)
            GameTooltip:AddLine("• 接受力反馈", 0.8, 1, 0.8)
            GameTooltip:AddLine("• 伤害越高，抛得越远越高", 0.8, 1, 0.8)
        elseif currentAnimMode == "C" then
            GameTooltip:AddLine("当前模式：C - 回力(不是鞋)", 0.6, 0.6, 1)
            GameTooltip:AddLine("• 接受力反馈", 0.8, 0.8, 1)
            GameTooltip:AddLine("• 抛物线飞出后回到起点", 0.8, 0.8, 1)
        end
        
        GameTooltip:AddLine("点击切换动画模式", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    animToggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 左侧滑块：暴击控制（修复版：X/Y分布读写存档）
for i=1,6 do
    local s = CreateFrame("Slider","PlayTurtle_LeftSlider"..i,sub,"OptionsSliderTemplate")
    s:SetWidth(sliderWidth)
    s:SetHeight(sliderHeight)
    if i==1 then
        s:SetPoint("TOPLEFT",leftCol,"BOTTOMLEFT",0,-22)
    else
        s:SetPoint("TOPLEFT",getglobal("PlayTurtle_LeftSlider"..(i-1)),"BOTTOMLEFT",0,-sliderSpacing)
    end

    -- 1. 范围与步进（优化版）
    if i==1 then
        s:SetMinMaxValues(60, 150)  -- 一阶缩放范围 60-150
        s:SetValueStep(1)
    elseif i==2 then
        s:SetMinMaxValues(20, 60)  -- 二阶缩放范围 20-60
        s:SetValueStep(1)
    elseif i==3 then
        s:SetMinMaxValues(1, 8)
        s:SetValueStep(1)
    elseif i==4 then -- 锚点X偏移
        s:SetMinMaxValues(-200, 200)   -- 锚点X偏移范围 -200 到 200
        s:SetValueStep(1)
    elseif i==5 then -- 锚点Y偏移
        s:SetMinMaxValues(-200, 200)   -- 锚点Y偏移范围 -200 到 200
        s:SetValueStep(1)
    elseif i==6 then -- X轴偏移（暴击随机）
        s:SetMinMaxValues(0, 200)      -- X轴偏移范围 0 到 200
        s:SetValueStep(1)
    end

    -- -从存档读取初始值（优先读 PTURTLE_Combat_DB）
    local savedValue = PTURTLE_Combat_DB and PTURTLE_Combat_DB["leftSlider"..i.."Value"]
    local defaultValue
    if i==1 then 
        defaultValue = 120  -- 一阶缩放默认 120
    elseif i==2 then 
        defaultValue = 30  -- 二阶缩放默认 30
    elseif i==3 then 
        defaultValue = 3   -- 停留时间默认 3
    elseif i==4 then 
        defaultValue = 0   -- 锚点X偏移默认 0
    elseif i==5 then 
        defaultValue = 0   -- 锚点Y偏移默认 0
    elseif i==6 then 
        defaultValue = 100 -- X轴偏移（暴击随机）默认 100
    end
    local initValue = savedValue or defaultValue
    s:SetValue(initValue)

    -- 3. 滑块文本（保持不变）
    local t = getglobal(s:GetName().."Text")
    t:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
    t:SetTextColor(1,1,1)
    t:SetText(leftTitles[i])

    getglobal(s:GetName().."Low"):SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    getglobal(s:GetName().."High"):SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")

    -- 4. 显示当前值（保持不变）
    local val = s:CreateFontString(nil,"OVERLAY")
    val:SetPoint("RIGHT",s,"LEFT",-5,0)
    val:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    val:SetTextColor(1,1,1)
    val:SetText(tostring(initValue))
    s.val = val
    s.idx = i

    -- -值变化时同步到存档与配置
    s:SetScript("OnValueChanged",function()
        local vv = math_floor(this:GetValue())
        this.val:SetText(tostring(vv))
        local idx = this.idx
    
        -- 直接写入 PTURTLE_Combat_DB（addon.db 是同一引用，无需重复赋值）
        PTURTLE_Combat_DB["leftSlider"..idx.."Value"] = vv
            
        -- 使用统一的配置同步函数
        addon:SyncConfigFromDB()
    end)
        
    -- -添加 Tooltip 说明
    s:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
        local sliderIdx = this.idx  -- -使用保存的索引而非循环变量 i
        GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
        if sliderIdx == 1 then
            GameTooltip:SetText("一阶缩放", 1, 1, 1)
            GameTooltip:AddLine("暴击数字最大放大倍数", 0.8, 0.8, 0.8)
        elseif sliderIdx == 2 then
            GameTooltip:SetText("二阶缩放", 1, 1, 1)
            GameTooltip:AddLine("暴击数字最终缩小倍数", 0.8, 0.8, 0.8)
        elseif sliderIdx == 3 then
            GameTooltip:SetText("停留时间", 1, 1, 1)
            GameTooltip:AddLine("暴击数字在最大缩放处的停留时长", 0.8, 0.8, 0.8)
        elseif sliderIdx == 4 then
            GameTooltip:SetText("锚点X偏移", 1, 1, 1)
            GameTooltip:AddLine("暴击动画出生点的X轴偏移（-200到200）", 0.8, 0.8, 0.8)
        elseif sliderIdx == 5 then
            GameTooltip:SetText("锚点Y偏移", 1, 1, 1)
            GameTooltip:AddLine("暴击动画出生点的Y轴偏移（-200到200）", 0.8, 0.8, 0.8)
        elseif sliderIdx == 6 then
            GameTooltip:SetText("X轴偏移", 1, 1, 1)
            GameTooltip:AddLine("暴击数字的随机X轴分布范围（0到200）", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    s:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
  -- ===================== 伤害类型颜色选择器（两列布局+点击颜色框呼出） =====================
    -- 8 种伤害类型基础配置（带 Alpha 值）
    local damageTypes = {
        {name="普攻", key=0, default={r=1.0, g=1.0, b=1.0, a=1.0}},
        {name="神圣", key=1, default={r=1.0, g=0.85, b=0.4, a=1.0}},
        {name="火焰", key=2, default={r=1.0, g=0.28, b=0.0, a=1.0}},
        {name="自然", key=3, default={r=0.44, g=1.0, b=0.43, a=1.0}},
        {name="冰霜", key=4, default={r=0.3, g=0.54, b=1.0, a=1.0}},
        {name="暗影", key=5, default={r=0.77, g=0.28, b=1.0, a=1.0}},
        {name="奥术", key=6, default={r=0.0, g=0.8, b=1.0, a=1.0}},
        {name="物理", key=7, default={r=1.0, g=0.9, b=0.0, a=1.0}},
    }
    
    -- 创建颜色选择器（点击颜色框呼出，文字仅作说明）
    local function createColorPickerItem(parent, typeInfo, posX, posY)
        -- 从配置中读取颜色，如果不存在则使用默认值
        local savedColor = addon.db and addon.db.damageColors and addon.db.damageColors[typeInfo.key]
        local initialColor = savedColor or typeInfo.default
        
        -- 文字标签（不可点击，仅说明）
        local label = parent:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        label:SetTextColor(1,1,1)
        label:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", posX, posY)
        label:SetText(typeInfo.name)

        -- 颜色显示框（可点击，呼出选择器）
        local colorBox = CreateFrame("Button", nil, parent)
        colorBox:SetWidth(16)
        colorBox:SetHeight(16)
        colorBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        colorBox:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
        colorBox:SetBackdropColor(initialColor.r, initialColor.g, initialColor.b, initialColor.a)
        colorBox:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        colorBox:GetHighlightTexture():SetBlendMode("ADD")

        -- 创建独立的颜色对象（包含Alpha）
        local color = {
            r = initialColor.r,
            g = initialColor.g,
            b = initialColor.b,
            a = initialColor.a or 1.0
        }

        -- 点击颜色框打开选择器（核心修改）
        colorBox:SetScript("OnClick", function()
            local r, g, b = color.r, color.g, color.b
            
            -- 存储原始颜色和类型信息到全局ColorPickerFrame
            ColorPickerFrame.originalR = r
            ColorPickerFrame.originalG = g
            ColorPickerFrame.originalB = b
            ColorPickerFrame.originalA = color.a or 1.0
            ColorPickerFrame.colorObj = color
            ColorPickerFrame.colorBox = colorBox
            ColorPickerFrame.damageKey = typeInfo.key
            ColorPickerFrame.damageName = typeInfo.name
            
            -- 启用Alpha通道
            ColorPickerFrame.hasOpacity = 1
            ColorPickerFrame.opacity = 1 - (color.a or 1.0)
            
            -- 设置初始颜色
            ColorPickerFrame:SetColorRGB(r, g, b)
            
            -- 选择器确认回调
            ColorPickerFrame.func = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local alpha = 1 - ColorPickerFrame.opacity
                local key = ColorPickerFrame.damageKey
                local name = ColorPickerFrame.damageName
                
                -- 更新颜色对象和显示框
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = newR, newG, newB, alpha
                colorBox:SetBackdropColor(newR, newG, newB, alpha)
                
                -- 保存到数据库
                addon.db.damageColors[key] = {
                    r = newR,
                    g = newG,
                    b = newB,
                    a = alpha
                }
            end
            
            -- 选择器取消回调
            ColorPickerFrame.cancelFunc = function()
                local originalR = ColorPickerFrame.originalR
                local originalG = ColorPickerFrame.originalG
                local originalB = ColorPickerFrame.originalB
                local originalA = ColorPickerFrame.originalA
                local key = ColorPickerFrame.damageKey
                
                -- 恢复原始颜色
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = originalR, originalG, originalB, originalA
                colorBox:SetBackdropColor(originalR, originalG, originalB, originalA)
                
                -- 恢复数据库值
                addon.db.damageColors[key] = {
                    r = originalR,
                    g = originalG,
                    b = originalB,
                    a = originalA
                }
            end
            
            -- 设置层级并显示
            ColorPickerFrame:SetFrameStrata("TOOLTIP")
            ColorPickerFrame:Raise()
            ColorPickerFrame:Show()
        end)
        
        -- 鼠标提示（悬停在颜色框上显示）
        colorBox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(typeInfo.name.."伤害颜色", 1,1,1)
            GameTooltip:AddLine("点击色块修改颜色", 0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        colorBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return colorBox
    end
    
    -- 创建特殊取色器：受到普攻伤害默认颜色
    local function createReceivedAutoAttackColorPicker(parent, posX, posY)
        -- 从配置中读取颜色，如果不存在则使用默认白色
        local savedColor = addon.db and addon.db.receivedAutoAttackColor
        local initialColor = savedColor or {r=1.0, g=1.0, b=1.0, a=1.0}
        
        -- 文字标签
        local label = parent:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        label:SetTextColor(1,1,1)
        label:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", posX, posY)
        label:SetText("受伤")

        -- 颜色显示框（可点击，呼出选择器）
        local colorBox = CreateFrame("Button", nil, parent)
        colorBox:SetWidth(16)
        colorBox:SetHeight(16)
        colorBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        colorBox:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
        colorBox:SetBackdropColor(initialColor.r, initialColor.g, initialColor.b, initialColor.a)
        colorBox:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        colorBox:GetHighlightTexture():SetBlendMode("ADD")

        -- 创建独立的颜色对象（包含Alpha）
        local color = {
            r = initialColor.r,
            g = initialColor.g,
            b = initialColor.b,
            a = initialColor.a or 1.0
        }

        -- 点击颜色框打开选择器
        colorBox:SetScript("OnClick", function()
            local r, g, b = color.r, color.g, color.b
            
            -- 存储原始颜色到全局ColorPickerFrame
            ColorPickerFrame.originalR = r
            ColorPickerFrame.originalG = g
            ColorPickerFrame.originalB = b
            ColorPickerFrame.originalA = color.a or 1.0
            ColorPickerFrame.colorObj = color
            ColorPickerFrame.colorBox = colorBox
            
            -- 启用Alpha通道
            ColorPickerFrame.hasOpacity = 1
            ColorPickerFrame.opacity = 1 - (color.a or 1.0)
            
            -- 设置初始颜色
            ColorPickerFrame:SetColorRGB(r, g, b)
            
            -- 选择器确认回调
            ColorPickerFrame.func = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local alpha = 1 - ColorPickerFrame.opacity
                
                -- 更新颜色对象和显示框
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = newR, newG, newB, alpha
                colorBox:SetBackdropColor(newR, newG, newB, alpha)
                
                -- 保存到数据库
                if not addon.db then addon.db = {} end
                addon.db.receivedAutoAttackColor = {
                    r = newR,
                    g = newG,
                    b = newB,
                    a = alpha
                }
            end
            
            -- 选择器取消回调
            ColorPickerFrame.cancelFunc = function()
                local originalR = ColorPickerFrame.originalR
                local originalG = ColorPickerFrame.originalG
                local originalB = ColorPickerFrame.originalB
                local originalA = ColorPickerFrame.originalA
                
                -- 恢复原始颜色
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = originalR, originalG, originalB, originalA
                colorBox:SetBackdropColor(originalR, originalG, originalB, originalA)
                
                -- 恢复数据库值
                if not addon.db then addon.db = {} end
                addon.db.receivedAutoAttackColor = {
                    r = originalR,
                    g = originalG,
                    b = originalB,
                    a = originalA
                }
            end
            
            -- 设置层级并显示
            ColorPickerFrame:SetFrameStrata("TOOLTIP")
            ColorPickerFrame:Raise()
            ColorPickerFrame:Show()
        end)
        
        -- 鼠标提示
        colorBox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText("受到普攻伤害颜色", 1,1,1)
            GameTooltip:AddLine("当受到普通攻击时，使用此颜色", 0.8,0.8,0.8)
            GameTooltip:AddLine("默认白色，点击色块修改颜色", 0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        colorBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return colorBox
    end

    -- 创建特殊取色器：宠物普攻伤害默认颜色
    local function createPetAutoAttackColorPicker(parent, posX, posY)
        -- 从配置中读取颜色，如果不存在则使用默认白色
        local savedColor = addon.db and addon.db.petAutoAttackColor
        local initialColor = savedColor or {r=1.0, g=1.0, b=1.0, a=1.0}

        -- 文字标签
        local label = parent:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        label:SetTextColor(1,1,1)
        label:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", posX, posY)
        label:SetText("宠普")

        -- 颜色显示框（可点击，呼出选择器）
        local colorBox = CreateFrame("Button", nil, parent)
        colorBox:SetWidth(16)
        colorBox:SetHeight(16)
        colorBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        colorBox:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
        colorBox:SetBackdropColor(initialColor.r, initialColor.g, initialColor.b, initialColor.a)
        colorBox:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        colorBox:GetHighlightTexture():SetBlendMode("ADD")

        -- 创建独立的颜色对象（包含Alpha）
        local color = {
            r = initialColor.r,
            g = initialColor.g,
            b = initialColor.b,
            a = initialColor.a or 1.0
        }

        -- 点击颜色框打开选择器
        colorBox:SetScript("OnClick", function()
            local r, g, b = color.r, color.g, color.b

            -- 存储原始颜色到全局ColorPickerFrame
            ColorPickerFrame.originalR = r
            ColorPickerFrame.originalG = g
            ColorPickerFrame.originalB = b
            ColorPickerFrame.originalA = color.a or 1.0
            ColorPickerFrame.colorObj = color
            ColorPickerFrame.colorBox = colorBox

            -- 启用Alpha通道
            ColorPickerFrame.hasOpacity = 1
            ColorPickerFrame.opacity = 1 - (color.a or 1.0)

            -- 设置初始颜色
            ColorPickerFrame:SetColorRGB(r, g, b)

            -- 选择器确认回调
            ColorPickerFrame.func = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local alpha = 1 - ColorPickerFrame.opacity

                -- 更新颜色对象和显示框
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = newR, newG, newB, alpha
                colorBox:SetBackdropColor(newR, newG, newB, alpha)

                -- 保存到数据库
                if not addon.db then addon.db = {} end
                addon.db.petAutoAttackColor = {
                    r = newR,
                    g = newG,
                    b = newB,
                    a = alpha
                }
            end

            -- 选择器取消回调
            ColorPickerFrame.cancelFunc = function()
                local originalR = ColorPickerFrame.originalR
                local originalG = ColorPickerFrame.originalG
                local originalB = ColorPickerFrame.originalB
                local originalA = ColorPickerFrame.originalA

                -- 恢复原始颜色
                local color = ColorPickerFrame.colorObj
                local colorBox = ColorPickerFrame.colorBox
                color.r, color.g, color.b, color.a = originalR, originalG, originalB, originalA
                colorBox:SetBackdropColor(originalR, originalG, originalB, originalA)

                -- 恢复数据库值
                if not addon.db then addon.db = {} end
                addon.db.petAutoAttackColor = {
                    r = originalR,
                    g = originalG,
                    b = originalB,
                    a = originalA
                }
            end

            -- 设置层级并显示
            ColorPickerFrame:SetFrameStrata("TOOLTIP")
            ColorPickerFrame:Raise()
            ColorPickerFrame:Show()
        end)

        -- 鼠标提示
        colorBox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText("宠物普攻伤害颜色", 1,1,1)
            GameTooltip:AddLine("当宠物进行普通攻击时，使用此颜色", 0.8,0.8,0.8)
            GameTooltip:AddLine("默认白色，点击色块修改颜色", 0.8,0.8,0.8)
            GameTooltip:Show()
        end)
        colorBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return colorBox
    end

    local leftColItems = {1,2,3,4}   -- damageTypes[1]=物理 (key=0)，[2]=神圣 (key=1)，[3]=火焰 (key=2)，[4]=自然 (key=3)
    local rightColItems = {5,6,7,8}  -- damageTypes[5]=冰霜 (key=4)，[6]=暗影 (key=5)，[7]=奥术 (key=6)，[8]=技能物理 (key=7)
    local leftColX = 30  -- 左列X偏移（向右偏移30像素）
    local rightColX = 110  -- 右列X偏移（向右偏移110像素）
    local thirdColX = 190  -- 第三列X偏移（受到普攻默认颜色）
    local rowSpacing = 30
    local startY = 15  -- 起始Y坐标（距离底部15像素，整体下移5像素）

    -- 创建左列颜色选择器
    for i, idx in ipairs(leftColItems) do
        createColorPickerItem(sub, damageTypes[idx], leftColX, startY + rowSpacing * (i-1))
    end

    -- 创建右列颜色选择器
    for i, idx in ipairs(rightColItems) do
        createColorPickerItem(sub, damageTypes[idx], rightColX, startY + rowSpacing * (i-1))
    end

    -- 创建第三列：宠物普攻颜色（放在第一行）
    createPetAutoAttackColorPicker(sub, thirdColX, startY)

    -- 创建第三列：受到普攻伤害默认颜色（放在宠普色盘下方一行）
    createReceivedAutoAttackColorPicker(sub, thirdColX, startY + rowSpacing)

    -- 右侧滑块逻辑
    for i=1,9 do
        local s = CreateFrame("Slider","PlayTurtle_RightSlider"..i,sub,"OptionsSliderTemplate")
        s:SetWidth(sliderWidth)
        s:SetHeight(sliderHeight)
        if i==1 then
            s:SetPoint("TOPRIGHT",rightCol,"BOTTOMRIGHT",0,-22)
        else
            s:SetPoint("TOPRIGHT",getglobal("PlayTurtle_RightSlider"..(i-1)),"BOTTOMRIGHT",0,-sliderSpacing)
        end
        local mi,ma = 0,100
        local v = 50
        if i==1 then
                mi,ma = 18,30  -- 淡出速度：18-30 (1.8-3.0 秒)，步进 1
                -- -从存档读取，默认值改为22
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 22
            elseif i==2 then
                mi,ma = 60,200  -- 浮动速度：60-200，步进 1（最低60）
                -- -从存档读取，默认值100
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 100
            elseif i==3 then
                mi,ma = 30,120  -- 字符大小：30-120，步进 1
                -- -从存档读取，默认值50
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 50
            elseif i==4 then
                mi,ma = 10,150  -- X 分布：10-150，步进 1（最低10）
                -- -从存档读取
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 100
            elseif i==5 then
                mi,ma = 10,150  -- Y 分布：10-150，步进 1（最低10）
                -- -从存档读取，默认值80
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 80
            elseif i==6 then
                mi,ma = -5,20  -- 行距（动画A）：-5~20，步进 1
                -- -从存档读取，默认值10
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 10
            elseif i==7 then
                mi,ma = 5,22  -- 存活时间（动画A）：0.5-2.2秒，步进 1（实际值除以10）
                -- -从存档读取，默认12（1.2秒）
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 12
            elseif i==8 then
                mi,ma = -20,20  -- （全局）字符间距：-20~20，步进 1
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or -10
            elseif i==9 then
                mi,ma = 1,10  -- （全局）字体样式：1-10，步进 1
                v = PTURTLE_Combat_DB["rightSlider"..i.."Value"] or 1
            else
                mi,ma = 0,100
                v = 50
            end
        s:SetMinMaxValues(mi,ma)
        s:SetValue(v)
        if i == 7 then
            s:SetValueStep(1)  -- 存活时间滑块：步进1（显示时除以10，即0.1秒）
        else
            s:SetValueStep(1)
        end
        
        -- -滑块初始化后，立即同步到 UserSettings（因为 SetValue 不会触发 OnValueChanged）
        if i == 1 then
            addon.Config.UserSettings.normalFadeDuration = v / 10
        elseif i == 2 then
            addon.Config.UserSettings.normalMoveRandom = v
        elseif i == 3 then
            addon.Config.UserSettings.baseFontSize = v
        elseif i == 4 then
            addon.Config.UserSettings.normalRandomX = v
        elseif i == 5 then
            addon.Config.UserSettings.normalRandomY = v
        elseif i == 6 then
            addon.Config.UserSettings.animASpacing = v
        elseif i == 7 then
            addon.Config.UserSettings.animALifetime = v / 10  -- 存活时间（动画A），除以10转换为秒
        elseif i == 8 then
            addon.Config.UserSettings.charSpacing = v
        elseif i == 9 then
            addon.Config.UserSettings.digitTextureStyle = v
        end

        local t = getglobal(s:GetName().."Text")
        t:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
        t:SetTextColor(1,1,1)
        t:SetText(rightTitles[i])

        getglobal(s:GetName().."Low"):SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
        getglobal(s:GetName().."High"):SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")

        local val = s:CreateFontString(nil,"OVERLAY")
        val:SetPoint("RIGHT",s,"LEFT",-5,0)
        val:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
        val:SetTextColor(1,1,1)
        -- -存活时间滑块显示为秒数（除以10）
        if i == 7 then
            val:SetText(string.format("%.1f", v / 10))
        else
            val:SetText(tostring(v))
        end
        s.val = val
        s.idx = i

        s:SetScript("OnValueChanged",function()
            local vv = math_floor(this:GetValue())
            -- -存活时间滑块显示为秒数（除以10）
            if this.idx == 7 then
                this.val:SetText(string.format("%.1f", vv / 10))
            else
                this.val:SetText(tostring(vv))
            end
            local idx = this.idx
            
            -- 直接写入 PTURTLE_Combat_DB（所有滑块值都保存）
            PTURTLE_Combat_DB["rightSlider"..idx.."Value"] = vv
            
            -- 使用统一的配置同步函数
            addon:SyncConfigFromDB()
            
            -- 特殊处理：字符大小改变时刷新所有槽位
            if idx == 3 and addon.RefreshAllSlotsFontSize then
                addon.RefreshAllSlotsFontSize()
            end
            
            -- -字符大小改变时，清理队列待释放队列，确保新数字使用新间距
            if idx == 3 and addon.ClearQueuePendingList then
                addon:ClearQueuePendingList()
            end
            
            -- 特殊处理：字体样式改变时重新加载纹理
            if idx == 9 and addon.ReloadDigitTexture then
                addon.ReloadDigitTexture()
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已切换字体样式：num"..vv..".blp", 1, 1, 1)
            end
        end)
        
        -- 6. 添加 Tooltip 说明
        s:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
            local sliderIdx = this.idx
            if sliderIdx == 1 then
                GameTooltip:SetText("淡出速度 |cFF5080FF[A]|r |cFF00FF00[B]|r |cFFFF9000[C]|r", 1, 1, 1)
                GameTooltip:AddLine("控制数字淡出的速率（0.5-2.5秒）", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("数值越大，淡出越慢、越柔和", 0.8, 0.8, 0.8)
            elseif sliderIdx == 2 then
                GameTooltip:SetText("浮动速度（含队列模式） |cFF5080FF[A]|r |cFF00FF00[B]|r |cFFFF9000[C]|r", 1, 1, 1)
                GameTooltip:AddLine("所有非暴击伤害的移动速度百分比", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("同时控制队列框架中数字的浮动速度", 0.8, 0.8, 0.8)
            elseif sliderIdx == 3 then
                GameTooltip:SetText("字符大小（含队列模式） |cFF5080FF[A]|r |cFF00FF00[B]|r |cFFFF9000[C]|r", 1, 1, 1)
                GameTooltip:AddLine("动画ABC非暴击数字的基础字符大小（30-120）", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("同时控制队列框架中数字的字符大小", 0.8, 0.8, 0.8)
            elseif sliderIdx == 4 then
                GameTooltip:SetText("X 分布 |cFF00FF00[B]|r |cFFFF9000[C]|r", 1, 1, 1)
                GameTooltip:AddLine("动画BC非暴击数字在 X 轴的随机分布范围", 0.8, 0.8, 0.8)
            elseif sliderIdx == 5 then
                GameTooltip:SetText("Y 分布 |cFF00FF00[B]|r |cFFFF9000[C]|r", 1, 1, 1)
                GameTooltip:AddLine("动画BC非暴击数字在 Y 轴的随机分布范围", 0.8, 0.8, 0.8)
            elseif sliderIdx == 6 then
                GameTooltip:SetText("行距 [A]（含队列模式）", 1, 1, 1)
                GameTooltip:AddLine("动画A队列中数字之间的行距（-5~20像素）", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("同时控制队列框架中数字的行距", 0.8, 0.8, 0.8)
            elseif sliderIdx == 7 then
                GameTooltip:SetText("存活时间 |cFF5080FF[A]|r", 1, 1, 1)
                GameTooltip:AddLine("控制动画A数字的存活时长（0.5-2.2秒）", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("数值越大，数字显示时间越长", 0.8, 0.8, 0.8)
            elseif sliderIdx == 8 then
                GameTooltip:SetText("（全局）字符间距", 1, 1, 1)
                GameTooltip:AddLine("所有伤害数字字符之间的间距", 0.8, 0.8, 0.8)
            elseif sliderIdx == 9 then
                GameTooltip:SetText("（全局）字体样式", 1, 1, 1)
                GameTooltip:AddLine("伤害数字使用的字体样式（1-10）", 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    sub:Hide()
    self.subPanel = sub
end

-- 小地图按钮（纯香草魔兽适配）
function addon:CreateMiniButton()
    if self.miniBtn then 
        return 
    end

    local btn = CreateFrame("Button", "PTURTLE_Combat_MiniBtn", Minimap)
    btn:SetWidth(32)
    btn:SetHeight(32)
    btn:SetFrameStrata("MEDIUM")
    btn:EnableMouse(1)
    btn:SetMovable(1)
    btn:RegisterForDrag("LeftButton")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    bg:SetTexCoord(0.5,1, 0.5,1)
    bg:SetWidth(24)
    bg:SetHeight(24)
    bg:SetPoint("CENTER",0,0)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\inv_pet_speedy")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER",0,0)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    hl:SetWidth(24)
    hl:SetHeight(24)
    hl:SetPoint("CENTER",0,0)

    -- 点击逻辑：统一开关面板
    btn:SetScript("OnClick", function()
        if not addon.panel then
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 错误：面板未创建", 1, 0, 0)
            return
        end
        
        if addon.panel:IsVisible() or (addon.subPanel and addon.subPanel:IsVisible()) then
            addon.panel:Hide()
            if addon.subPanel then addon.subPanel:Hide() end
            if PTURTLE_Combat_DB then
                PTURTLE_Combat_DB.panelVisible = false
            end
            
            -- -面板隐藏时，同时隐藏固定位置指示器
            if addon.fixedPosIndicator then
                addon.fixedPosIndicator:Hide()
            end
            if addon.petFixedPosIndicator then
                addon.petFixedPosIndicator:Hide()
            end
            
            -- 关闭面板时停止预览模式
            addon:StopPreviewMode()
            if addon.receivedPanelPreviewMode then
                addon.receivedPanelPreviewMode = false
                addon.GlobalTimer.receivedPreviewAccumulator = nil
            end
            -- -关闭面板时停止 DOT 预览模式
            if addon.dotPanelPreviewMode then
                addon.dotPanelPreviewMode = false
                addon.GlobalTimer.dotPreviewAccumulator = nil
            end
            
            -- 关闭受伤/受治疗/输出治疗编辑框架
            if addon.DamageFrame then
                addon.DamageFrame:SetBackdrop(nil)
                addon.DamageFrame:EnableMouse(false)
            end
            if addon.ReceivedHealFrame then
                addon.ReceivedHealFrame:SetBackdrop(nil)
                addon.ReceivedHealFrame:EnableMouse(false)
            end
            if addon.OutputHealFrame then
                addon.OutputHealFrame:SetBackdrop(nil)
                addon.OutputHealFrame:EnableMouse(false)
            end
            if addon.ReceivedUI then
                if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Hide() end
                if addon.ReceivedUI.startPointDamage then addon.ReceivedUI.startPointDamage:Hide() end
                if addon.ReceivedUI.endPointDamage then addon.ReceivedUI.endPointDamage:Hide() end
                if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Hide() end
                if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Hide() end
                
                if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Hide() end
                if addon.ReceivedUI.startPointHeal then addon.ReceivedUI.startPointHeal:Hide() end
                if addon.ReceivedUI.endPointHeal then addon.ReceivedUI.endPointHeal:Hide() end
                if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Hide() end
                if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Hide() end
                
                if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Hide() end
                if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Hide() end
                if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Hide() end
                if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Hide() end
                if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Hide() end
            end
        else
            if addon.panel then
                addon.panel:Show()
            end
            if PTURTLE_Combat_DB then
                PTURTLE_Combat_DB.panelVisible = true
            end
            
            -- -面板显示时，根据开关状态显示固定位置指示器
            if (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true) and addon.fixedPosIndicator then
                addon.fixedPosIndicator:Show()
            end
            if (addon.db.fixedPosPetEnabled == 1 or addon.db.fixedPosPetEnabled == true) and addon.petFixedPosIndicator then
                addon.petFixedPosIndicator:Show()
            end
        end
    end)

    btn:SetScript("OnDragStart", function()
        btn.drag = true
        btn:SetScript("OnUpdate", function()
            if not btn.drag then return end
            local mx, my = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local sx, sy = Minimap:GetCenter()
            mx = mx/scale
            my = my/scale
            local a = math.deg(math.atan2(my-sy, mx-sx))
            if a<0 then a=a+360 end
            -- 保存到 PTURTLE_Combat_DB
            if PTURTLE_Combat_DB then
                PTURTLE_Combat_DB.btnAngle = a
            end
            local r = 80
            local rad = math.rad(a)
            local x = math.cos(rad)*r
            local y = math.sin(rad)*r
            btn:ClearAllPoints()
            btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
        end)
    end)

    btn:SetScript("OnDragStop", function()
        btn.drag = nil
        btn:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function()
        if GameTooltip then
            GameTooltip:SetOwner(this,"ANCHOR_LEFT")
            GameTooltip:SetText("PlayTurtle 设置")
            GameTooltip:AddLine("点击打开/关闭面板",0.8,0.8,0.8)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    addon:UpdateMiniBtnPos(btn)
    addon.miniBtn = btn
end

function addon:UpdateMiniBtnPos(btn)
    local b = btn or addon.miniBtn
    if not b then return end
    
    -- 优先使用 PTURTLE_Combat_DB，如果没有则使用默认值
    local angle = 45  -- 默认角度
    if PTURTLE_Combat_DB and PTURTLE_Combat_DB.btnAngle then
        angle = PTURTLE_Combat_DB.btnAngle
    end
    
    local a = angle
    local r = 80
    local rad = math.rad(a)
    local x = math.cos(rad)*r
    local y = math.sin(rad)*r
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- 初始化
function addon:Init()
    
    addon:InitDB()
    -- addon.db 已在 InitDB 中设置，无需重复
    
    addon:CreateMiniButton()
    
    -- -使用 pcall 捕获 CreatePanel 错误
    local success, err = pcall(function()
        addon:CreatePanel()
    end)
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] CreatePanel 错误: " .. tostring(err), 1, 0, 0)
    end
    
    -- -在 SavedVariables 加载完成后重新注册监控事件
    if addon.eventFrame then
        -- 先注销旧事件
        addon.eventFrame:UnregisterEvent("BUFF_ADDED_SELF")
        addon.eventFrame:UnregisterEvent("SPELL_GO_SELF")
        addon.eventFrame:UnregisterEvent("DEBUFF_ADDED_SELF")
        
        -- 根据开关重新注册
        if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.buffMonitorEnabled == 1 then
            addon.eventFrame:RegisterEvent("BUFF_ADDED_SELF")
        end
        if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.spellMonitorEnabled == 1 then
            addon.eventFrame:RegisterEvent("SPELL_GO_SELF")
        end
        -- 根据 Debuff 监控模式注册事件（从个人存档读取）
        if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.monitorDebuffMode then
            addon.eventFrame:RegisterEvent("DEBUFF_ADDED_SELF")
        end
    end

end

-- ======================== 模式选择框体 ================================
-- 创建性能模式选择对话框
function addon:CreateModeChoiceDialog()
    -- 如果已存在，先隐藏再显示以触发 OnShow 事件
    if addon.modeChoiceDialog then
        addon.modeChoiceDialog:Hide()
        addon.modeChoiceDialog:Show()
        return
    end
    
    -- 创建主框体
    local dialog = CreateFrame("Frame", "PT_ModeChoiceDialog", UIParent)
    dialog:SetWidth(300)
    dialog:SetHeight(180)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- 设置背景
    dialog:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dialog:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    dialog:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- 标题
    local title = dialog:CreateFontString(nil, "OVERLAY")
    title:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    title:SetPoint("TOP", dialog, "TOP", 0, -15)
    title:SetText("性能模式选择")
    title:SetTextColor(1, 1, 0.2)
    
    -- 说明文字
    local desc = dialog:CreateFontString(nil, "OVERLAY")
    desc:SetFont(STANDARD_TEXT_FONT, 12)
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("选择动画槽位数量配置")
    desc:SetTextColor(0.9, 0.9, 0.9)
    
    -- 回头是岸按钮（节省性能模式）
    local btnConservative = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btnConservative:SetHeight(40)
    btnConservative:SetPoint("TOP", desc, "BOTTOM", -60, -15)  -- 向左偏移60像素
    
    local btnConservativeText = btnConservative:GetFontString()
    if btnConservativeText then
        btnConservativeText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")  -- 放大字体到16
    end
    btnConservative:SetText("回头是岸")
    
    -- -按钮宽度自适应文本
    btnConservative:SetWidth(btnConservativeText:GetStringWidth() + 40)  -- 文本宽度 + 左右各20像素边距
    
    btnConservative:SetScript("OnClick", function()
        addon:SetPerformanceMode("conservative")
        -- 不在这里隐藏，让 StaticPopup 确认后自动隐藏
    end)
    
    btnConservative:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btnConservative, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("回头是岸 - 节省性能模式", 1, 1, 0.2)
        GameTooltip:AddLine("输出伤害：50 个动画槽位", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("受伤/受治疗/输出治疗：共用 30 个槽位", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("适合低配置电脑或追求流畅体验", 0.6, 1, 0.6)
        GameTooltip:AddLine("总槽位数：50 + 30 = 80", 0.7, 0.7, 1)
        GameTooltip:Show()
    end)
    btnConservative:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 一意孤行按钮（狂野模式）
    local btnAggressive = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btnAggressive:SetHeight(40)
    btnAggressive:SetPoint("LEFT", btnConservative, "RIGHT", 20, 0)  -- 在回头是岸按钮右侧，间距20像素
    
    local btnAggressiveText = btnAggressive:GetFontString()
    if btnAggressiveText then
        btnAggressiveText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")  -- 放大字体到16
    end
    btnAggressive:SetText("一意孤行")
    
    -- -按钮宽度自适应文本
    btnAggressive:SetWidth(btnAggressiveText:GetStringWidth() + 40)  -- 文本宽度 + 左右各20像素边距
    
    btnAggressive:SetScript("OnClick", function()
        addon:SetPerformanceMode("aggressive")
        -- 不在这里隐藏，让 StaticPopup 确认后自动隐藏
    end)
    
    btnAggressive:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btnAggressive, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("一意孤行 - 极致爽感模式", 1, 0.3, 0.3)
        GameTooltip:AddLine("输出伤害：100 个动画槽位", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("受伤/受治疗/输出治疗：50 个槽位", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("适合高配置电脑，享受满屏数字的快感", 1, 0.6, 0.6)
        GameTooltip:AddLine("总槽位数：100 + 50 = 150", 0.7, 0.7, 1)
        GameTooltip:AddLine("注意：可能会影响游戏性能", 1, 0.5, 0.5)
        GameTooltip:Show()
    end)
    btnAggressive:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 关闭按钮
    local btnClose = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btnClose:SetWidth(80)
    btnClose:SetHeight(25)
    btnClose:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 8)
    btnClose:SetText("取消")
    
    btnClose:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- 保存引用
    addon.modeChoiceDialog = dialog
    
    -- 显示对话框
    dialog:Show()
end

-- 设置性能模式
function addon:SetPerformanceMode(mode)
    local damageSlots
    local receivedSlots
    local modeName
    
    if mode == "conservative" then
        damageSlots = 50  -- 回头是岸模式：伤害动画50个槽位
        receivedSlots = 30  -- 回头是岸模式：受伤/受治疗/输出治疗30个槽位
        modeName = "回头是岸"
    elseif mode == "aggressive" then
        damageSlots = 100  -- 一意孤行模式：伤害动画100个槽位
        receivedSlots = 50  -- 一意孤行模式：受伤/受治疗/输出治疗50个槽位
        modeName = "一意孤行"
    else
        return
    end
    
    -- 显示确认对话框
    StaticPopupDialogs["PLAYTURTLE_MODE_CHANGE"] = {
        text = "切换到「" .. modeName .. "」模式将动态调整槽位数量。\n\n是否立即切换？",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            -- 更新系统参数（同时更新伤害和受伤/治疗的槽位数量）
            addon.Config.SystemParams.MAX_ANI_SLOTS = damageSlots
            addon.Config.SystemParams.MAX_RECEIVED_SLOTS = receivedSlots
            PTURTLE_Combat_DB.maxAniSlots = damageSlots
            PTURTLE_Combat_DB.maxReceivedSlots = receivedSlots
            
            -- -动态调整槽位池大小，无需重载 UI
            if addon.ResizeDamagePool then
                addon:ResizeDamagePool(damageSlots)
            end
            if addon.ResizeReceivedPool then
                addon:ResizeReceivedPool(receivedSlots)
            end
            
            -- -根据模式播放不同的音乐
            if mode == "conservative" then
                -- 回头是岸模式：播放 S_9.mp3
                if PlaySoundFile then
                    local musicPath = "Interface\\AddOns\\PlayTurtle\\Sound\\S_9.mp3"
                    pcall(PlaySoundFile, musicPath, "Master")
                end
            elseif mode == "aggressive" then
                -- 一意孤行模式：播放 S_10.mp3
                if PlaySoundFile then
                    local musicPath = "Interface\\AddOns\\PlayTurtle\\Sound\\S_10.mp3"
                    pcall(PlaySoundFile, musicPath, "Master")
                end
            end
            
            -- 保存到存档
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已切换至「" .. modeName .. "」模式", 1, 1, 0.2)
            
            -- 隐藏模式选择对话框
            if addon.modeChoiceDialog then
                addon.modeChoiceDialog:Hide()
            end
        end,
        OnCancel = function()
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 已取消模式切换", 1, 0.6, 0.6)
            
            -- 隐藏模式选择对话框
            if addon.modeChoiceDialog then
                addon.modeChoiceDialog:Hide()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    StaticPopup_Show("PLAYTURTLE_MODE_CHANGE")
end

-- 启动（自动初始化）
--UI:Init()