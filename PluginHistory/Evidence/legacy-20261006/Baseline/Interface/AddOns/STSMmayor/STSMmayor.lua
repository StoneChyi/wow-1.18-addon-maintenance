-- STSMmayor 自动盾牌换装插件
-- 魔兽世界1.12版本

-- 初始化Gratuity-2.0库
local gratuity = AceLibrary("Gratuity-2.0")
local DURABILITY_TEMPLATE = DURABILITY_TEMPLATE or "耐久度 (%d+) / (%d+)"

-- 插件状态
STSMmayor_Enabled = false

-- 上次的盾牌耐久度，用于避免重复预警
local lastShieldDurability = -1

-- 定时器相关设置
local BAG_CHECK_INTERVAL = 20 -- 背包检查间隔（秒）
local DURABILITY_CHECK_INTERVAL = 1 -- 耐久度检查间隔（秒）
local AUTO_SWAP_THRESHOLD = 15 -- 自动换盾耐久阈值（点数）
local REPAIR_WARNING_THRESHOLD = 20 -- 修理警告耐久阈值（点数）
local lastBagCheckTime = 0 -- 上次检查背包的时间
local lastDurabilityCheckTime = 0 -- 上次检查耐久度的时间
local bagCheckTimer = nil -- 定时器对象
local durabilityCheckTimer = nil -- 耐久度检查定时器
local hadBrokenShield = false -- 上次检查时是否有破损盾牌
local lowDurabilityWarningShown = false -- 跟踪是否已显示低耐久警告

-- 防无限循环机制
local EQUIP_COOLDOWN = 3 -- 换盾冷却时间（秒）
local lastEquipAttempt = 0 -- 上次尝试换盾的时间

-- 耐久度监控窗口相关变量
local durabilityFrame = nil -- 耐久度监控窗口
local durabilityText = nil -- 耐久度文本显示
local closeButton = nil -- 关闭按钮
local equipButton = nil -- 换盾按钮
local repairButton = nil -- 修理按钮
local autoSwapCheckButton = nil -- 自动换盾开关
local autoSwapCheckText = nil -- 自动换盾开关文本
local isDurabilityFrameVisible = false -- 窗口是否可见
local equipFailed = false -- 记录上次换装是否失败
local STSMmayor_AutoSwapEnabled = true -- 自动换盾开关，默认开启
local STSMmayor_AutoRepairEnabled = false -- 自动修理开关，默认关闭
local STSMmayor_RobotDetectionEnabled = false -- 机器人检测开关，默认关闭
local AUTO_REPAIR_THRESHOLD = 30 -- 自动修理耐久阈值（百分比）

-- 聊天消息颜色
local CHAT_COLOR = "|cff40ff40" -- 绿色
local ERROR_COLOR = "|cffff4040" -- 红色
local WARNING_COLOR = "|cffffff00" -- 黄色（预警用）
local REPAIR_WARNING_COLOR = "|cffff8040" -- 橙色（修理警告用）

-- 修理机器人状态显示文本
local repairBotText = nil

-- ===== 修理机器人检测（事件驱动，参考crazytarget插件）=====
-- 原理：SuperWOW模组会让 UNIT_FLAGS/UNIT_FACTION/UNIT_HEALTH 等单位事件对
-- 周围所有单位触发，arg1 直接是单位GUID（"0x..."开头），可直接用
-- UnitName(GUID)/UnitCanAttack("player", GUID)/UnitIsVisible(GUID) 查询，
-- 全程不需要 TargetByName 切换目标，也没有轮询扫描。
-- 机器人被召唤/进入视野的瞬间事件即触发；20秒定时器只负责轻量校验GUID是否还在。
local repairBotGUID = nil        -- 事件发现并缓存的修理机器人GUID
local lastBotProbeTime = 0       -- 上次TargetByName兜底探测的时间
local BOT_PROBE_INTERVAL = 60    -- 兜底探测最小间隔（秒），且仅脱战时执行
local repairBotEventsOn = false  -- 事件是否已注册（开关关闭时反注册，零开销）

-- 名字是否为修理机器人（中英文子串匹配）
local function STSMmayor_IsRepairBotName(name)
    if not name then return false end
    local lower = strlower(name)
    return strfind(lower, "修理机器人") ~= nil or strfind(lower, "repair bot") ~= nil
end

-- 判定某个单位（unit token 或 SuperWOW GUID）是否为修理机器人
local function STSMmayor_UnitIsRepairBot(unit)
    if not unit then return false end
    local ok, name = pcall(UnitName, unit)
    if not ok or not STSMmayor_IsRepairBotName(name) then
        return false
    end
    -- 修理机器人是友方NPC：不可被玩家攻击（SuperWOW下GUID也可直接查）
    local okAttack, canAttack = pcall(UnitCanAttack, "player", unit)
    if okAttack and canAttack then
        return false
    end
    return true
end

-- 机器人检测事件框（默认不注册任何事件，开启检测时才注册）
local repairBotEventFrame = CreateFrame("Frame")
repairBotEventFrame:SetScript("OnEvent", function()
    if not STSMmayor_RobotDetectionEnabled then return end

    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then
        -- 当前目标/鼠标指向是机器人时立即记录（无SuperWOW也能用，不切目标）
        local unit = (event == "PLAYER_TARGET_CHANGED") and "target" or "mouseover"
        if STSMmayor_UnitIsRepairBot(unit) then
            local _, guid = pcall(UnitExists, unit)
            if guid then repairBotGUID = guid end
            STSMmayor_UpdateRepairBotStatus()
        end
        return
    end

    -- SuperWOW：单位事件的arg1是周围单位的GUID（"0x"开头）；
    -- 原版客户端arg1是"player"/"target"等token，不在此处理
    local guid = arg1
    if type(guid) == "string" and string.sub(guid, 1, 2) == "0x" then
        if STSMmayor_UnitIsRepairBot(guid) then
            repairBotGUID = guid
            STSMmayor_UpdateRepairBotStatus()
        end
    end
end)

-- 开关机器人检测事件注册（关闭时反注册，零开销）
function STSMmayor_SetRepairBotEvents(enable)
    if enable and not repairBotEventsOn then
        repairBotEventFrame:RegisterEvent("UNIT_FLAGS")
        repairBotEventFrame:RegisterEvent("UNIT_FACTION")
        repairBotEventFrame:RegisterEvent("UNIT_HEALTH")
        repairBotEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        repairBotEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        repairBotEventsOn = true
    elseif not enable and repairBotEventsOn then
        repairBotEventFrame:UnregisterAllEvents()
        repairBotEventsOn = false
    end
end

-- 检测周围是否存在修理机器人
-- 优先级：事件缓存GUID → 当前目标/鼠标指向 → 脱战时低频TargetByName兜底
function STSMmayor_CheckForRepairBot()
    -- 1) 事件缓存的GUID：仍可见且名字匹配 → 存在
    if repairBotGUID then
        local okVis, visible = pcall(UnitIsVisible, repairBotGUID)
        if okVis and visible then
            local okName, name = pcall(UnitName, repairBotGUID)
            if okName and STSMmayor_IsRepairBotName(name) then
                return true
            end
        end
        -- GUID失效（离开视野/换图/机器人消失），清缓存等事件重新发现
        repairBotGUID = nil
    end

    -- 2) 当前目标/鼠标指向是否就是修理机器人（不切换目标，无SuperWOW也可用）
    if STSMmayor_UnitIsRepairBot("target") then
        local _, guid = pcall(UnitExists, "target")
        if guid then repairBotGUID = guid end
        return true
    end
    if STSMmayor_UnitIsRepairBot("mouseover") then
        local _, guid = pcall(UnitExists, "mouseover")
        if guid then repairBotGUID = guid end
        return true
    end

    -- 3) 兜底：事件漏报时（如开启检测时机器人已站在身边）补检。
    --    仅脱战执行（打怪时绝不切换目标），且60秒最多一次；探测到GUID后缓存，后续不再探测。
    if not UnitAffectingCombat("player") and (GetTime() - lastBotProbeTime) >= BOT_PROBE_INTERVAL then
        lastBotProbeTime = GetTime()

        local foundRepairBot = false
        local probedBotGUID = nil
        local originalTarget = nil

        -- 保存当前目标
        if UnitExists("target") then
            originalTarget = UnitName("target")
        end

        -- 尝试中文名称
        TargetByName("修理机器人75B型", true)
        if UnitExists("target") and STSMmayor_UnitIsRepairBot("target") then
            foundRepairBot = true
            local _, guid = pcall(UnitExists, "target")
            probedBotGUID = guid
        end

        -- 如果没找到，尝试英文名称
        if not foundRepairBot then
            TargetByName("Repair Bot 75A", true)
            if UnitExists("target") and STSMmayor_UnitIsRepairBot("target") then
                foundRepairBot = true
                local _, guid = pcall(UnitExists, "target")
                probedBotGUID = guid
            end
        end

        -- 恢复原始目标
        if originalTarget then
            TargetByName(originalTarget, true)
        else
            -- 如果之前没有目标，清除当前目标
            ClearTarget()
        end

        if foundRepairBot then
            -- GUID为"0x"开头才缓存（无SuperWOW时UnitExists不返回GUID，保持每60秒兜底）
            if type(probedBotGUID) == "string" and string.sub(probedBotGUID, 1, 2) == "0x" then
                repairBotGUID = probedBotGUID
            end
            return true
        end
    end

    return false
end

-- 更新修理机器人状态显示
function STSMmayor_UpdateRepairBotStatus()
    if not durabilityFrame then
        return
    end

    -- 如果机器人检测开关关闭，不执行检测
    if not STSMmayor_RobotDetectionEnabled then
        if repairBotText then
            repairBotText:Hide()
        end
        return
    end

    -- 创建修理机器人状态显示文本
    if not repairBotText then
        repairBotText = durabilityFrame:CreateFontString(nil, "OVERLAY")
        repairBotText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
        repairBotText:SetPoint("TOP", durabilityFrame, "TOP", 0, 20) -- 在框体正上方
        repairBotText:SetText("")
        repairBotText:SetWidth(300) -- 设置宽度以容纳文本
        repairBotText:SetJustifyH("CENTER") -- 居中对齐
    end

    -- 检查修理机器人状态
    local hasRepairBot = STSMmayor_CheckForRepairBot()

    -- 更新文本和颜色
    if hasRepairBot then
        repairBotText:SetTextColor(0, 1, 0, 1) -- 绿色
        repairBotText:SetText("监测到周围已召唤修理机器人")
    else
        repairBotText:SetTextColor(1, 0, 0, 1) -- 红色
        repairBotText:SetText("警告：未监测到召唤修理机器人")
    end

    -- 显示文本
    repairBotText:Show()
end

-- 检查是否为盾牌物品
function STSMmayor_IsOffHandItem(itemLink)
    if not itemLink then
        return false
    end
    
    -- 从物品链接中提取物品ID
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    if not itemID then
        return false
    end
    
    -- 获取物品信息
    local success, itemInfo = pcall(function()
        return {GetItemInfo(tonumber(itemID))}
    end)
    
    if not success or not itemInfo or table.getn(itemInfo) < 8 then
        return false
    end
    
    local equipLoc = itemInfo[8] -- WoW 1.12中字段8是装备位置字符串
    
    -- 只检查盾牌类型
    return equipLoc == "INVTYPE_SHIELD"
end

-- 创建耐久度监控窗口
function STSMmayor_CreateDurabilityFrame()
    -- 创建主窗口（兼容1.12）
    durabilityFrame = CreateFrame("Frame", "STSMmayorDurabilityFrame", UIParent)
    durabilityFrame:SetWidth(380) -- 增加宽度以容纳新布局
    durabilityFrame:SetHeight(65) -- 减少高度
    -- 设置位置：X轴中心，Y轴靠下1/4处
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    durabilityFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenWidth / 2, screenHeight / 4)
    
    -- 恢复背景设置（1.12兼容版本）
    durabilityFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16
    })
    durabilityFrame:SetBackdropColor(0, 0, 0, 0.7)
    
    -- 恢复移动功能（1.12兼容版本）
    durabilityFrame:SetMovable(true)
    durabilityFrame:EnableMouse(true)
    durabilityFrame:RegisterForDrag("LeftButton")
    durabilityFrame:SetScript("OnDragStart", function()
        durabilityFrame:StartMoving()
    end)
    durabilityFrame:SetScript("OnDragStop", function()
        durabilityFrame:StopMovingOrSizing()
    end)
    durabilityFrame:Hide() -- 初始隐藏
    
    -- 创建关闭按钮（右侧第一个）
closeButton = CreateFrame("Button", nil, durabilityFrame)
closeButton:SetWidth(30)
closeButton:SetHeight(30)
closeButton:SetPoint("RIGHT", durabilityFrame, "RIGHT", -120, 5) -- 向左移动一大截，向上移动
closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
closeButton:SetScript("OnClick", function()
    STSMmayor_HideDurabilityFrame()
end)

-- 创建换盾按钮（右侧第二个）
equipButton = CreateFrame("Button", nil, durabilityFrame)
equipButton:SetWidth(40) -- 稍微宽一点以容纳"换"字
equipButton:SetHeight(30)
equipButton:SetPoint("RIGHT", durabilityFrame, "RIGHT", -80, 5) -- 向左移动一大截，向上移动

-- 设置换盾按钮样式（红色背景，类似关闭按钮）
equipButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
equipButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
equipButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
equipButton:SetScript("OnClick", function()
    STSMmayor_ManualEquip()
end)

-- 添加换盾按钮鼠标悬停提示
 equipButton:SetScript("OnEnter", function()
     GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
     GameTooltip:SetText("手动换盾 (/STSMC)", 1, 1, 1, 1)
     GameTooltip:Show()
 end)
 equipButton:SetScript("OnLeave", function()
     GameTooltip:Hide()
 end)

-- 添加按钮文本
local equipButtonText = equipButton:CreateFontString(nil, "OVERLAY")
equipButtonText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
equipButtonText:SetPoint("CENTER", equipButton, "CENTER")
equipButtonText:SetText("换")
equipButtonText:SetTextColor(1, 1, 1) -- 白色文字

-- 创建修理按钮（右侧第三个）
repairButton = CreateFrame("Button", nil, durabilityFrame)
repairButton:SetWidth(40) -- 与换盾按钮相同宽度
repairButton:SetHeight(30)
repairButton:SetPoint("RIGHT", durabilityFrame, "RIGHT", -42, 5) -- 向左移动一大截，向上移动，再向左2像素

-- 设置修理按钮样式（类似换盾按钮）
repairButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
repairButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
repairButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
repairButton:SetDisabledTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up") -- 禁用时使用正常纹理，避免红色

repairButton:SetScript("OnClick", function()
    STSMmayor_AutoRepair()
end)

-- 添加修理按钮文本
local repairButtonText = repairButton:CreateFontString(nil, "OVERLAY")
repairButtonText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
repairButtonText:SetPoint("CENTER", repairButton, "CENTER")
repairButtonText:SetText("修")
repairButtonText:SetTextColor(1, 1, 1) -- 白色文字

-- 创建捡拾按钮（右侧第四个）
pickupButton = CreateFrame("Button", nil, durabilityFrame)
pickupButton:SetWidth(40) -- 与修理按钮相同宽度
pickupButton:SetHeight(30)
pickupButton:SetPoint("RIGHT", durabilityFrame, "RIGHT", -5, 5) -- 向左移动一大截，向上移动

-- 设置捡拾按钮样式（类似换盾按钮）
pickupButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
pickupButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
pickupButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
pickupButton:SetDisabledTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up") -- 禁用时使用正常纹理，避免红色

pickupButton:SetScript("OnClick", function()
    STSMmayor_AutoPickup()
end)

-- 添加捡拾按钮文本
local pickupButtonText = pickupButton:CreateFontString(nil, "OVERLAY")
pickupButtonText:SetFont("Fonts/FRIZQT__.TTF", 14, "OUTLINE")
pickupButtonText:SetPoint("CENTER", pickupButton, "CENTER")
pickupButtonText:SetText("拾")
pickupButtonText:SetTextColor(1, 1, 1) -- 白色文字

-- 检查拾取模组状态并更新按钮（同时支持Interact与无双拾取两种模组）
-- 绑定规则：
--   仅检测到Interact：修=Interact(1)，拾=Interact(0)（与旧版一致）
--   仅检测到无双拾取：修、拾 均绑定 /无双交互
--   两个模组都检测到：拾=Interact(0)，修=/无双交互
--   两个模组都没检测到：两个按钮禁用（灰字+空点击）
function STSMmayor_UpdateInteractButtons()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()

    if hasInteract or hasWushuang then
        -- 至少检测到一个拾取模组，启用按钮
        repairButton:Enable()
        pickupButton:Enable()
        repairButtonText:SetTextColor(1, 1, 1) -- 白色文字
        pickupButtonText:SetTextColor(1, 1, 1) -- 白色文字

        -- 重新设置纹理为正常状态
        repairButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
        pickupButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")

        -- 修按钮：装了无双拾取就用无双交互，否则用Interact
        local repairTip = "一键修理 (/STSMF)"
        if hasWushuang then
            repairTip = "一键修理 (/STSMF) - 无双交互"
        end

        -- 拾按钮：装了Interact就用Interact（两个都装时拾按钮归Interact），仅装无双时用无双交互
        local pickupTip = "一键拾取 (/STSML)"
        if not hasInteract and hasWushuang then
            pickupTip = "一键拾取 (/STSML) - 无双交互"
        end

        -- 修理按钮悬停提示
        repairButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(repairTip, 1, 1, 1, 1)
            GameTooltip:Show()
        end)
        repairButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- 拾取按钮悬停提示
        pickupButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(pickupTip, 1, 1, 1, 1)
            GameTooltip:Show()
        end)
        pickupButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- 恢复按钮点击功能（具体路由由STSMmayor_AutoRepair/STSMmayor_AutoPickup按模组状态决定）
        repairButton:SetScript("OnClick", function()
            STSMmayor_AutoRepair()
        end)
        pickupButton:SetScript("OnClick", function()
            STSMmayor_AutoPickup()
        end)
    else
        -- 两个拾取模组都未加载，手动模拟禁用状态（不使用 Disable() 避免红色）
        -- 使用 Enable() 保持按钮状态，通过脚本模拟禁用
        repairButton:Enable()
        pickupButton:Enable()
        repairButtonText:SetTextColor(0.5, 0.5, 0.5) -- 灰色文字
        pickupButtonText:SetTextColor(0.5, 0.5, 0.5) -- 灰色文字

        -- 保持纹理为正常状态，避免红色
        repairButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
        pickupButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")

        -- 添加鼠标悬停提示
        repairButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("未检测到任何拾取模组", 1, 0, 0, 1)
            GameTooltip:Show()
        end)
        repairButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        pickupButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("未检测到任何拾取模组", 1, 0, 0, 1)
            GameTooltip:Show()
        end)
        pickupButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- 禁用点击功能（通过空函数）
        repairButton:SetScript("OnClick", function()
            -- 空函数，模拟禁用
        end)
        pickupButton:SetScript("OnClick", function()
            -- 空函数，模拟禁用
        end)
    end

    -- 同步右下角模组状态提示文字（任一模组已加载即隐藏）
    if autoRepairInteractHint then
        if hasInteract or hasWushuang then
            autoRepairInteractHint:Hide()
        else
            autoRepairInteractHint:Show()
        end
    end
end

-- 初始更新按钮状态
STSMmayor_UpdateInteractButtons()
    
    -- 创建耐久度文本显示（左侧）
    durabilityText = durabilityFrame:CreateFontString(nil, "OVERLAY")
    durabilityText:SetFont("Fonts/FRIZQT__.TTF", 18, "OUTLINE") -- 更大的字体
    durabilityText:SetPoint("LEFT", durabilityFrame, "LEFT", 15, 5) -- 左侧位置，下移减少间距
    durabilityText:SetText("未装备盾牌")
    durabilityText:SetTextColor(1, 1, 1, 1) -- 默认白色
    
    -- 创建自动换盾开关（盾牌耐久文字下方左侧）
autoSwapCheckButton = CreateFrame("CheckButton", nil, durabilityFrame, "UICheckButtonTemplate")
autoSwapCheckButton:SetWidth(20)
autoSwapCheckButton:SetHeight(20)
autoSwapCheckButton:SetPoint("TOP", durabilityText, "BOTTOM", -70, -5) -- 在盾牌耐久文字下方，向左移动30像素
autoSwapCheckButton:SetScript("OnClick", function()
    STSMmayor_AutoSwapEnabled = not STSMmayor_AutoSwapEnabled
    autoSwapCheckButton:SetChecked(STSMmayor_AutoSwapEnabled)
    
    if STSMmayor_AutoSwapEnabled then
        STSMmayor_Print(CHAT_COLOR .. "自动换盾已开启")
        -- 立即检查当前盾牌耐久并触发换盾逻辑
        local slotID = GetInventorySlotInfo("SecondaryHandSlot")
        if slotID then
            local itemLink = GetInventoryItemLink("player", slotID)
            if itemLink and STSMmayor_IsOffHandItem(itemLink) then
                local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                if durability and maxDurability and durability <= AUTO_SWAP_THRESHOLD then
                    STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 检测到盾牌耐久过低（" .. durability .. "点），立即自动更换...")
                    equipFailed = true -- 标记换装失败状态，需要重检
                    lastShieldDurability = durability -- 更新上次耐久度记录
                    
                    -- 尝试自动换盾
                    local swapSuccess = STSMmayor_AutoEquipShield()
                    if not swapSuccess then
                        STSMmayor_Print(ERROR_COLOR .. "✗ 自动换盾失败，请手动检查背包中的盾牌")
                    end
                else
                    STSMmayor_Print(CHAT_COLOR .. "当前盾牌耐久正常，无需更换")
                end
            else
                STSMmayor_Print(WARNING_COLOR .. "未检测到盾牌装备")
            end
        end
    else
        STSMmayor_Print(WARNING_COLOR .. "自动换盾已关闭")
    end
end)
autoSwapCheckButton:SetChecked(STSMmayor_AutoSwapEnabled) -- 默认打钩

-- 创建自动换盾文本
autoSwapText = durabilityFrame:CreateFontString(nil, "OVERLAY")
autoSwapText:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
autoSwapText:SetPoint("LEFT", autoSwapCheckButton, "RIGHT", 5, 0)
autoSwapText:SetText("自动换盾")

-- 创建自动修理开关（盾牌耐久文字下方右侧）
autoRepairCheckButton = CreateFrame("CheckButton", nil, durabilityFrame, "UICheckButtonTemplate")
autoRepairCheckButton:SetWidth(20)
autoRepairCheckButton:SetHeight(20)
autoRepairCheckButton:SetPoint("LEFT", autoSwapCheckButton, "RIGHT", 70, 0) -- 在自动换盾右侧，减少间距
autoRepairCheckButton:SetScript("OnClick", function()
    STSMmayor_AutoRepairEnabled = not STSMmayor_AutoRepairEnabled
    autoRepairCheckButton:SetChecked(STSMmayor_AutoRepairEnabled)
    
    if STSMmayor_AutoRepairEnabled then
        STSMmayor_Print(CHAT_COLOR .. "自动修理已开启")
        -- 立即触发一次修理效果
        STSMmayor_AutoRepair()
    else
        STSMmayor_Print(WARNING_COLOR .. "自动修理已关闭")
    end
end)
autoRepairCheckButton:SetChecked(STSMmayor_AutoRepairEnabled) -- 默认关闭

-- 创建自动修理文本
autoRepairText = durabilityFrame:CreateFontString(nil, "OVERLAY")
autoRepairText:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
autoRepairText:SetPoint("LEFT", autoRepairCheckButton, "RIGHT", 5, 0)
autoRepairText:SetText("自动修理")

-- 创建机器人检测开关（盾牌耐久文字下方右侧）
robotDetectionCheckButton = CreateFrame("CheckButton", nil, durabilityFrame, "UICheckButtonTemplate")
robotDetectionCheckButton:SetWidth(20)
robotDetectionCheckButton:SetHeight(20)
robotDetectionCheckButton:SetPoint("LEFT", autoRepairCheckButton, "RIGHT", 70, 0) -- 在自动修理右侧
robotDetectionCheckButton:SetScript("OnClick", function()
    STSMmayor_RobotDetectionEnabled = not STSMmayor_RobotDetectionEnabled
    robotDetectionCheckButton:SetChecked(STSMmayor_RobotDetectionEnabled)

    if STSMmayor_RobotDetectionEnabled then
        STSMmayor_Print(CHAT_COLOR .. "机器人检测已开启")
        -- 注册SuperWOW单位事件（事件驱动检测，不切换目标）
        STSMmayor_SetRepairBotEvents(true)
        -- 重置兜底探测计时：开启瞬间若脱战立即探测一次（事件漏报时补检）
        lastBotProbeTime = 0
        -- 立即检查修理机器人状态
        STSMmayor_UpdateRepairBotStatus()
    else
        STSMmayor_Print(WARNING_COLOR .. "机器人检测已关闭")
        -- 反注册事件，零开销
        STSMmayor_SetRepairBotEvents(false)
        repairBotGUID = nil
        -- 隐藏修理机器人状态文本
        if repairBotText then
            repairBotText:Hide()
        end
    end
end)
robotDetectionCheckButton:SetChecked(STSMmayor_RobotDetectionEnabled) -- 默认关闭

-- 创建机器人检测文本
robotDetectionText = durabilityFrame:CreateFontString(nil, "OVERLAY")
robotDetectionText:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
robotDetectionText:SetPoint("LEFT", robotDetectionCheckButton, "RIGHT", 5, 0)
robotDetectionText:SetText("机器人检测")

-- 创建拾取模组加载状态提示文字（Interact与无双拾取均未加载时显示）
autoRepairInteractHint = durabilityFrame:CreateFontString(nil, "OVERLAY")
autoRepairInteractHint:SetFont("Fonts/FRIZQT__.TTF", 10, "OUTLINE")
autoRepairInteractHint:SetPoint("BOTTOMRIGHT", durabilityFrame, "BOTTOMRIGHT", -5, 5) -- 移动到右下角
autoRepairInteractHint:SetTextColor(1, 0, 0) -- 设置为红色
autoRepairInteractHint:SetText("-未加载拾取模组")
-- 初始检查并设置提示可见性（Interact与无双拾取任一加载即隐藏）
if STSMmayor_IsInteractLoaded() or STSMmayor_IsWushuangLoaded() then
    autoRepairInteractHint:Hide()
else
    autoRepairInteractHint:Show()
end
    return durabilityFrame
end

-- 更新耐久度显示
function STSMmayor_UpdateDurabilityDisplay()
    if not durabilityFrame or not durabilityText then
        return
    end
    
    -- 检查副手装备
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            if STSMmayor_IsOffHandItem(itemLink) then
                -- 获取耐久度信息（使用兼容函数）
                local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                if durability and maxDurability and maxDurability > 0 then
                    local durabilityPercent = math.floor((durability / maxDurability) * 100)
                    local r, g, b = 1, 1, 1 -- 默认白色
                    
                    -- 根据耐久度设置颜色
                    if durabilityPercent < 30 then
                        r, g, b = 1, 0, 0 -- 红色
                    elseif durabilityPercent < 60 then
                        r, g, b = 1, 0.5, 0 -- 橙色
                    elseif durabilityPercent < 75 then
                        r, g, b = 1, 1, 0 -- 黄色
                    else
                        r, g, b = 0, 1, 0 -- 绿色
                    end
                    
                    durabilityText:SetTextColor(r, g, b)
                    durabilityText:SetText("盾牌: " .. durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)")
                    
                    -- 检查是否需要自动修理（耐久低于30%）
                    if STSMmayor_AutoRepairEnabled and durabilityPercent < AUTO_REPAIR_THRESHOLD then
                        STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 检测到盾牌耐久过低（" .. durabilityPercent .. "%），自动执行修理...")
                        STSMmayor_AutoRepair()
                    end
                else
                    durabilityText:SetTextColor(1, 1, 1) -- 白色
                    durabilityText:SetText("盾牌: 未知耐久")
                end
            else
                durabilityText:SetTextColor(1, 1, 0) -- 黄色
                durabilityText:SetText("非盾牌物品")
            end
        else
            durabilityText:SetTextColor(1, 1, 0) -- 黄色
            durabilityText:SetText("未装备盾牌")
        end
    else
        durabilityText:SetTextColor(1, 0, 0) -- 红色
        durabilityText:SetText("错误")
    end
end

-- 显示耐久度监控窗口
function STSMmayor_ShowDurabilityFrame()
    if not durabilityFrame then
        STSMmayor_CreateDurabilityFrame()
    end

    durabilityFrame:Show()
    isDurabilityFrameVisible = true
    STSMmayor_UpdateDurabilityDisplay() -- 恢复更新显示
    STSMmayor_UpdateInteractButtons() -- 重新检测拾取模组（Interact/无双拾取可能晚于窗口创建加载）
end

-- 隐藏耐久度监控窗口
function STSMmayor_HideDurabilityFrame()
    if durabilityFrame then
        durabilityFrame:Hide()
    end
    isDurabilityFrameVisible = false
end

-- 切换耐久度监控窗口的显示状态
function STSMmayor_ToggleDurabilityFrame()
    if isDurabilityFrameVisible then
        STSMmayor_HideDurabilityFrame()
    else
        STSMmayor_ShowDurabilityFrame()
    end
end

-- 事件注册
local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY") -- 专门检测耐久度变化的事件

-- 创建定期检查耐久度的定时器
local durabilityChecker = CreateFrame("Frame")
durabilityChecker:SetScript("OnUpdate", function()
    -- 只在插件启用时执行检查
    if not STSMmayor_Enabled then
        return
    end
    
    local elapsed = arg1
    local currentTime = GetTime()
    if currentTime - lastDurabilityCheckTime >= DURABILITY_CHECK_INTERVAL then
        lastDurabilityCheckTime = currentTime
        -- 定期检查耐久度并更新显示
        STSMmayor_UpdateDurabilityDisplay()
        STSMmayor_CheckShield()
    end
end)

-- 事件处理函数
f:SetScript("OnEvent", function(self, event, arg1)
    if (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "UPDATE_INVENTORY_DURABILITY" then
        -- 当物品栏变化或耐久度变化时检查
        STSMmayor_UpdateDurabilityDisplay() -- 更新耐久度显示
        if STSMmayor_Enabled then
            STSMmayor_CheckShield()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- 初始化时检查一次
        STSMmayor_UpdateDurabilityDisplay()
        if STSMmayor_Enabled then
            STSMmayor_CheckShield()
        end
        -- 登录时延迟检查地点，因为地图数据可能还没有完全加载
        local checkFrame = CreateFrame("Frame")
        local elapsed = 0
        checkFrame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed >= 2 then -- 延迟2秒检查，确保地图数据已加载
                checkFrame:SetScript("OnUpdate", nil)
                -- 检查地点，如果在目标区域则自动开启插件
                if STSMmayor_IsInTargetZone() and not STSMmayor_Enabled then
                    STSMmayor_Enabled = true
                    STSMmayor_Print("常用命令：")
                    STSMmayor_Print("  /STSM - 开启/关闭插件")
                    STSMmayor_Print("  /STSMC - 手动换盾")
                    STSMmayor_Print("  /STSMF - 自动修理（需要Interact或无双拾取模组）")
                    STSMmayor_Print("  /STSML - 自动拾取（需要Interact或无双拾取模组）")
                    STSMmayor_Print("  /STSMSHOW - 显示耐久度监控窗口")
                    STSMmayor_Print("  /STSMHIDE - 隐藏耐久度监控窗口")
                    STSMmayor_Print("  /STSMcheck - 检查背包中的破损盾牌")
                    STSMmayor_Print("报告镇长！自动换修盾插件已成功开启")
                    STSMmayor_PrintLootStatus()
                      STSMmayor_GenerateShieldReport() -- 显示盾牌状态
                      STSMmayor_ShowDurabilityFrame() -- 显示耐久度监控窗口
                      STSMmayor_CheckShield() -- 立即检查一次盾牌状态
                      STSMmayor_StartBagCheckTimer() -- 启动背包检查定时器
                end
            end
        end)
    end
end)

-- 获取背包物品耐久度的函数（使用Gratuity-2.0库提高性能）
function STSMmayor_GetContainerItemDurability(bag, slot)
    if not gratuity then
        return nil, nil
    end
    
    -- 使用Gratuity库获取背包物品的tooltip信息
    gratuity:SetBagItem(bag, slot)
    
    -- 使用FindDeformat方法查找耐久度信息（支持多语言）
    local durability, maxDurability = gratuity:FindDeformat(DURABILITY_TEMPLATE)
    if durability and maxDurability then
        return tonumber(durability), tonumber(maxDurability)
    end
    
    -- 备用方案：如果FindDeformat失败，尝试手动扫描
    for i = 1, gratuity:NumLines() do
        local tooltipText = gratuity:GetLine(i)
        if tooltipText then
            -- 查找耐久度格式 "耐久度 XX / XX"
            local _, _, current, max = string.find(tooltipText, "耐久度 (%d+) / (%d+)")
            if current and max then
                return tonumber(current), tonumber(max)
            end
            
            -- 也查找英文格式 "Durability XX / XX"
            local _, _, current2, max2 = string.find(tooltipText, "Durability (%d+) / (%d+)")
            if current2 and max2 then
                return tonumber(current2), tonumber(max2)
            end
        end
    end
    
    return nil, nil
end

-- 获取装备耐久度的函数（使用Gratuity-2.0库提高性能）
function STSMmayor_GetInventoryDurability(slotID)
    if not gratuity then
        return nil, nil
    end
    
    -- 使用Gratuity库获取装备物品的tooltip信息
    gratuity:SetInventoryItem("player", slotID)
    
    -- 使用FindDeformat方法查找耐久度信息（支持多语言）
    local durability, maxDurability = gratuity:FindDeformat(DURABILITY_TEMPLATE)
    if durability and maxDurability then
        return tonumber(durability), tonumber(maxDurability)
    end
    
    -- 备用方案：如果FindDeformat失败，尝试手动扫描
    for i = 1, gratuity:NumLines() do
        local tooltipText = gratuity:GetLine(i)
        if tooltipText then
            -- 查找耐久度格式 "耐久度 XX / XX"
            local _, _, current, max = string.find(tooltipText, "耐久度 (%d+) / (%d+)")
            if current and max then
                return tonumber(current), tonumber(max)
            end
            
            -- 也查找英文格式 "Durability XX / XX"
            local _, _, current2, max2 = string.find(tooltipText, "Durability (%d+) / (%d+)")
            if current2 and max2 then
                return tonumber(current2), tonumber(max2)
            end
        end
    end
    
    return nil, nil
end

-- 检查盾牌耐久度
function STSMmayor_CheckShield()
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    local itemLink = GetInventoryItemLink("player", slotID)
    
    if not itemLink then
        -- 如果没有装备，重置上次耐久度
        lastShieldDurability = -1
        return
    end
    
    -- 检查是否是盾牌
    if STSMmayor_IsOffHandItem(itemLink) then
        -- 获取耐久度信息（使用兼容函数）
        local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
        
        if durability and maxDurability and maxDurability > 0 then
            local durabilityPercent = durability / maxDurability
            
            -- 只在耐久度发生变化时输出信息，避免刷屏
            if durability ~= lastShieldDurability then
                
                -- 检查是否需要换盾（耐久度小于等于自动换盾阈值）
                if durability <= AUTO_SWAP_THRESHOLD then
                    if STSMmayor_AutoSwapEnabled then
                        STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 盾牌耐久过低（" .. durability .. "点），自动更换中...")
                        lastShieldDurability = durability
                        equipFailed = true -- 标记换装失败状态，需要重检
                        
                        -- 尝试自动换盾
                        local swapSuccess = STSMmayor_AutoEquipShield()
                        if not swapSuccess then
                            STSMmayor_Print(ERROR_COLOR .. "✗ 自动换盾失败，请手动检查背包中的盾牌")
                        end
                    else
                        STSMmayor_Print(WARNING_COLOR .. "⚠ 盾牌耐久过低（" .. durability .. "点），请尽快手动更换盾牌或修理")
                    end
                elseif durability <= REPAIR_WARNING_THRESHOLD then -- 耐久度在阈值之间时警告
                    STSMmayor_Print(WARNING_COLOR .. "⚠ 盾牌耐久偏低（" .. durability .. "点），请注意准备更换")
                elseif durability < 10 then -- 保留原有的低耐久警告
                    STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 盾牌耐久度仅剩 " .. durability .. " 点！")
                end
                
                lastShieldDurability = durability
            end
        else
            if lastShieldDurability ~= 0 then
                STSMmayor_Print(WARNING_COLOR .. "无法获取盾牌耐久度信息")
                lastShieldDurability = 0
            end
        end
    else
        if lastShieldDurability ~= -2 then
            STSMmayor_Print(WARNING_COLOR .. "副手装备的不是盾牌")
            lastShieldDurability = -2
        end
    end
end

-- 自动换盾功能
function STSMmayor_AutoEquipShield()
    -- 防止频繁换装
    local currentTime = GetTime()
    if currentTime - lastEquipAttempt < EQUIP_COOLDOWN then
        STSMmayor_Print(WARNING_COLOR .. "换装冷却中，请稍后再试...")
        return
    end
    lastEquipAttempt = currentTime
    
    STSMmayor_Print(CHAT_COLOR .. "开始寻找可替换的盾牌...")
    
    -- 扫描背包前8个格子寻找耐久度最好的盾牌（从左到右，跳过耐久为0的）
    local bestShield = nil
    local bestDurabilityPercent = 0
    local bestBag, bestSlot = nil, nil
    local shieldCandidates = {}
    
    for bag = 0, 0 do -- 只检查背包0号包
        local success, numSlots = pcall(GetContainerNumSlots, bag)
        if success and numSlots then
            for slot = 1, math.min(8, numSlots) do -- 从左到右检查前8个格子
                local success2, itemLink = pcall(GetContainerItemLink, bag, slot)
                if success2 and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                    -- 检查这个盾牌的耐久度
                    local _, _, itemID = string.find(itemLink, "item:(%d+):")
                    if itemID then
                        local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                        local durabilityPercent = 0
                        
                        if durability and maxDurability and maxDurability > 0 then
                            durabilityPercent = durability / maxDurability
                            
                            -- 跳过耐久度低于自动换盾阈值的盾牌
                            if durability < AUTO_SWAP_THRESHOLD then
                                STSMmayor_Print(REPAIR_WARNING_COLOR .. "跳过第" .. slot .. "格低耐久盾牌：" .. itemLink .. "（" .. durability .. "点）")
                            else
                                table.insert(shieldCandidates, {
                                    link = itemLink,
                                    bag = bag,
                                    slot = slot,
                                    durabilityPercent = durabilityPercent,
                                    durability = durability or 0,
                                    maxDurability = maxDurability or 1
                                })
                                
                                -- 选择耐久度最高的盾牌（如果耐久度相同，选择更靠左的）
                                if durabilityPercent > bestDurabilityPercent then
                                    bestDurabilityPercent = durabilityPercent
                                    bestShield = itemLink
                                    bestBag = bag
                                    bestSlot = slot
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 显示找到的盾牌候选
    if table.getn(shieldCandidates) > 0 then
        STSMmayor_Print(CHAT_COLOR .. "找到 " .. table.getn(shieldCandidates) .. " 个候选盾牌：")
        for i, candidate in ipairs(shieldCandidates) do
            local status = ""
            if candidate.durabilityPercent > 0.75 then
                status = CHAT_COLOR .. "(优秀)"
            elseif candidate.durabilityPercent > 0.5 then
                status = WARNING_COLOR .. "(良好)"
            elseif candidate.durabilityPercent > 0.25 then
                status = REPAIR_WARNING_COLOR .. "(较差)"
            else
                status = ERROR_COLOR .. "(破损)"
            end
            
            STSMmayor_Print("  背包第" .. candidate.slot .. "格: " .. candidate.link .. " " .. status .. 
                          " 耐久:" .. candidate.durability .. "/" .. candidate.maxDurability .. 
                          " (" .. math.floor(candidate.durabilityPercent * 100) .. "%)")
        end
    end
    
    -- 装备最好的盾牌
    if bestShield and bestDurabilityPercent > 0 then -- 只要耐久度大于0就可以换
        STSMmayor_Print(CHAT_COLOR .. "选择最佳盾牌：" .. bestShield .. " (耐久度：" .. math.floor(bestDurabilityPercent * 100) .. "%)")
        
        -- 装备盾牌
        PickupContainerItem(bestBag, bestSlot)
        PickupInventoryItem(GetInventorySlotInfo("SecondaryHandSlot"))
        
        STSMmayor_Print(CHAT_COLOR .. "自动换盾完成！")
        equipFailed = false -- 重置失败标记
        return true
    else
        STSMmayor_Print(WARNING_COLOR .. "背包中没有找到可用的盾牌（耐久度需≥15点）")
        STSMmayor_Print(WARNING_COLOR .. "请将可用的盾牌放置到背包前8个格子中")
        equipFailed = true -- 标记换装失败
        return false
    end
end

-- 生成并显示盾牌状态报告
function STSMmayor_GenerateShieldReport()
    -- 检查当前副手装备
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            if STSMmayor_IsOffHandItem(itemLink) then
                -- 显示耐久度信息（使用兼容函数）
                local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                if durability and maxDurability and maxDurability > 0 then
                    local durabilityPercent = math.floor((durability / maxDurability) * 100)
                    STSMmayor_Print(CHAT_COLOR .. "当前副手：" .. itemLink .. " 耐久：" .. durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)")
                else
                    STSMmayor_Print(CHAT_COLOR .. "当前副手：" .. itemLink .. " 耐久：未知")
                end
            else
                STSMmayor_Print(WARNING_COLOR .. "当前副手未装备盾牌")
            end
        else
            STSMmayor_Print(WARNING_COLOR .. "当前副手未装备盾牌")
        end
    else
        STSMmayor_Print(ERROR_COLOR .. "无法获取副手槽位信息")
    end
    
    -- 扫描背包前8个格子中的盾牌物品
    local shieldCount = 0
    for bag = 0, 0 do -- 只检查背包0号包
        local success, numSlots = pcall(GetContainerNumSlots, bag)
        if success and numSlots then
            for slot = 1, math.min(8, numSlots) do -- 只检查前8个格子
                local success2, itemLink = pcall(GetContainerItemLink, bag, slot)
                if success2 and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                    shieldCount = shieldCount + 1
                    -- 获取耐久度
                    local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                    local durabilityText = ""
                    if durability and maxDurability and maxDurability > 0 then
                        local durabilityPercent = math.floor((durability / maxDurability) * 100)
                        durabilityText = " 耐久：" .. durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)"
                    else
                        durabilityText = " 耐久：未知"
                    end
                    STSMmayor_Print(CHAT_COLOR .. "背包第" .. slot .. "格：" .. itemLink .. durabilityText)
                end
            end
        end
    end
    
    if shieldCount == 0 then
        STSMmayor_Print(WARNING_COLOR .. "背包前8格未找到盾牌，请将可用盾牌放置到前8个格子中")
    end
end

-- 检查并重试换装（如果之前失败）
function STSMmayor_CheckAndRetryEquip()
    if not equipFailed then
        return -- 如果上次没有失败，不需要重试
    end
    
    -- 首先检查当前副手装备的耐久度（这是重要的检查）
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink and STSMmayor_IsOffHandItem(itemLink) then
            local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
            if durability and maxDurability then
                if durability > AUTO_SWAP_THRESHOLD then
                    equipFailed = false -- 盾牌确实有耐久，重置失败标记
                    STSMmayor_Print(CHAT_COLOR .. "当前盾牌已修复，无需更换")
                    return
                else
                    -- 当前盾牌耐久仍低于阈值，需要继续尝试换装
                    STSMmayor_Print(REPAIR_WARNING_COLOR .. "当前盾牌耐久仍为" .. durability .. "点，继续寻找替换...")
                end
            else
                -- 无法获取耐久信息，假设仍有问题
                STSMmayor_Print(WARNING_COLOR .. "无法检测当前盾牌耐久度，继续监控...")
            end
        else
            -- 副手不是盾牌或未装备，需要换装
            STSMmayor_Print(WARNING_COLOR .. "副手未装备盾牌，尝试换装...")
        end
    else
        -- 无法获取副手信息
        STSMmayor_Print(ERROR_COLOR .. "无法获取副手信息，继续监控...")
        return
    end
    
    -- 只有确认当前盾牌有问题时才尝试重新换装
    STSMmayor_Print(CHAT_COLOR .. "检查背包中是否有可用的盾牌...")
    local success = STSMmayor_AutoEquipShield()
    if success then
        equipFailed = false -- 换装成功，重置失败标记
    else
        STSMmayor_Print(WARNING_COLOR .. "请将可用的盾牌放置到背包前8个格子中，系统将自动检测")
    end
end

-- 检查背包中的装备耐久度
function STSMmayor_CheckBagForBrokenShields()
    local hasBrokenShield = false
    local brokenShields = {}
    
    -- 检查背包前8个格子
    for bag = 0, 0 do -- 只检查背包，不检查银行包
        for slot = 1, 8 do -- 只检查前8个格子
            local success, itemLink = pcall(GetContainerItemLink, bag, slot)
            if success and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                -- 检查这个盾牌的耐久度
                local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                if durability and maxDurability and durability < AUTO_SWAP_THRESHOLD then
                    -- 获取物品名称
                    local _, _, itemID = string.find(itemLink, "item:(%d+):")
                    local itemName = "未知盾牌"
                    if itemID then
                        local success2, itemInfo = pcall(function()
                            return {GetItemInfo(tonumber(itemID))}
                        end)
                        if success2 and itemInfo and itemInfo[1] then
                            itemName = itemInfo[1]
                        end
                    end
                    
                    -- 记录破损盾牌信息
                    table.insert(brokenShields, {
                        slot = slot,
                        name = itemName,
                        durability = durability,
                        itemID = itemID
                    })
                    
                    hasBrokenShield = true
                end
            end
        end
    end
    
    -- 只在第一次检测到破损盾牌时显示警告
    if hasBrokenShield and not hadBrokenShield then
        STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 警告：背包中发现破损盾牌，请及时修理！")
        -- 显示详细的破损盾牌列表
        for _, shield in ipairs(brokenShields) do
            if shield.durability == 0 then
                STSMmayor_Print(REPAIR_WARNING_COLOR .. "  背包第" .. shield.slot .. "格：" .. shield.name .. " 已破损（耐久度为0）")
            else
                STSMmayor_Print(REPAIR_WARNING_COLOR .. "  背包第" .. shield.slot .. "格：" .. shield.name .. " 耐久过低（" .. shield.durability .. "点）")
            end
        end
    end
    
    -- 检测盾牌修复情况
    if hadBrokenShield and not hasBrokenShield then
        STSMmayor_Print(CHAT_COLOR .. "背包中的破损盾牌已全部修复！")
    end
    
    -- 更新破损盾牌状态
    hadBrokenShield = hasBrokenShield
    
    -- 同时检查身上盾牌是否需要更换（如果之前更换失败）
    STSMmayor_CheckAndRetryEquip()
    
    return hasBrokenShield
end

-- 打印消息
function STSMmayor_Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_COLOR .. "[STSMmayor] " .. message)
end

-- 打印两个拾取模组（Interact / 无双拾取）的载入情况
function STSMmayor_PrintLootStatus()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()
    local function modTag(ok)
        if ok then
            return "|cff00ff00已加载|r"
        else
            return "|cffff4040未加载|r"
        end
    end
    STSMmayor_Print("拾取模组检测：Interact " .. modTag(hasInteract) .. CHAT_COLOR
        .. "，无双拾取 " .. modTag(hasWushuang))
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(WARNING_COLOR .. "两个拾取模组均未加载，拾/修按钮不可用，请安装Interact或无双拾取")
    end
end

-- 检测是否在目标区域（斯坦索姆、东瘟疫之地或东墙大门）
function STSMmayor_IsInTargetZone()
    local zoneName = GetRealZoneText() or GetZoneText() or ""
    local subZoneName = GetSubZoneText() or ""
    
    -- 检查是否在斯坦索姆、东瘟疫之地或东墙大门（支持中英文名称）
    local lowerZone = strlower(zoneName)
    local lowerSubZone = strlower(subZoneName)
    
    local result = strfind(lowerZone, "斯坦索姆") or strfind(lowerSubZone, "斯坦索姆") or 
                   strfind(lowerZone, "stratholme") or strfind(lowerSubZone, "stratholme") or
                   strfind(lowerZone, "东瘟疫之地") or strfind(lowerSubZone, "东瘟疫之地") or
                   strfind(lowerZone, "eastern plaguelands") or strfind(lowerSubZone, "eastern plaguelands") or
                   strfind(lowerZone, "东墙大门") or strfind(lowerSubZone, "东墙大门") or
                   strfind(lowerZone, "eastern wall") or strfind(lowerSubZone, "eastern wall")
    
    return result
end

-- 手动换装命令
function STSMmayor_ManualEquip()
    if not STSMmayor_Enabled then
        STSMmayor_Print(ERROR_COLOR .. "插件当前处于关闭状态，请先使用/STSM命令开启插件")
        return
    end
    
    STSMmayor_Print("手动执行盾牌换装...")
    local success = STSMmayor_AutoEquipShield()
    
    -- 换装后延迟刷新信息
    if success then
        -- 延迟1秒后刷新显示，确保装备信息已更新
        local refreshFrame = CreateFrame("Frame")
        refreshFrame:SetScript("OnUpdate", function()
            local elapsed = arg1
            this.elapsed = (this.elapsed or 0) + elapsed
            if this.elapsed >= 1 then
                STSMmayor_UpdateDurabilityDisplay()
                STSMmayor_CheckShield()
                this:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- 检测Interact模组是否加载
function STSMmayor_IsInteractLoaded()
    -- 使用更精确的检测方法，参考dimino插件中的实现
    return type(Interact) == "function" or (Interact and (type(Interact.Version) == "function" or Interact.Version ~= nil))
end

-- 检测无双拾取模组是否加载
-- 参考diminfo插件Loaddll.lua：wsloot.dll注入后会注册全局WSLoot表
function STSMmayor_IsWushuangLoaded()
    if type(WSLoot) == "table" then
        return true
    end
    -- WSLoot表由wsloot.dll在首次调用UnitXP时注册（与无双交互插件EnsureRegistered逻辑一致）
    -- 主动触发一次，避免DLL已注入但表尚未注册时误判
    if type(UnitXP) == "function" then
        pcall(UnitXP, "player")
    end
    return type(WSLoot) == "table"
end

-- 执行一次无双拾取交互（等价于在聊天框输入 /无双交互 命令）
function STSMmayor_DoWushuangInteract()
    -- 优先走无双交互插件的斜杠命令处理器（内部含DLL注册检测与分类掩码同步，与手动输入/无双交互完全一致）
    if type(SlashCmdList) == "table" and type(SlashCmdList.WSLoot) == "function" then
        SlashCmdList.WSLoot()
        return true
    end
    -- 兜底：未安装无双交互插件但wsloot.dll已注册WSLoot表时，直接调用DLL
    if type(WSLoot) ~= "table" and type(UnitXP) == "function" then
        pcall(UnitXP, "player")
    end
    if type(WSLoot) == "table" and type(WSLoot.Loot) == "function" then
        WSLoot.Loot()
        return true
    end
    return false
end

-- 自动修理功能
function STSMmayor_AutoRepair()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()

    -- 两个拾取模组都未检测到时才报错
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动修理功能无效")
        return false
    end

    -- 修按钮路由：装了无双拾取（无论是否同时装了Interact）都用/无双交互与商人交互修理；
    -- 仅装Interact时沿用旧逻辑 Interact(1)
    if hasWushuang and STSMmayor_DoWushuangInteract() then
        STSMmayor_Print(CHAT_COLOR .. "正在执行自动修理（无双交互）...")
        return true
    end

    if hasInteract then
        Interact(1)
        STSMmayor_Print(CHAT_COLOR .. "正在执行自动修理...")
        return true
    end

    STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动修理功能无效")
    return false
end

-- 自动拾取功能
function STSMmayor_AutoPickup()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()

    -- 两个拾取模组都未检测到时才报错
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动拾取功能无效")
        return false
    end

    -- 拾按钮路由：只要装了Interact就用Interact(0)（两个模组都装时拾按钮归Interact）；
    -- 仅装无双拾取时才用/无双交互
    if hasInteract then
        Interact(0)
        STSMmayor_Print(CHAT_COLOR .. "正在执行自动拾取...")
        return true
    end

    if hasWushuang and STSMmayor_DoWushuangInteract() then
        STSMmayor_Print(CHAT_COLOR .. "正在执行自动拾取（无双交互）...")
        return true
    end

    STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动拾取功能无效")
    return false
end

-- 命令处理
SLASH_STSM1 = "/STSM"
SLASH_STSMC1 = "/STSMC"
SLASH_STSMSHOW1 = "/STSMSHOW"
SLASH_STSMHIDE1 = "/STSMHIDE"

-- 修理命令
SLASH_STSMF1 = "/STSMF"

-- 拾取命令
SLASH_STSML1 = "/STSML"

-- 检查命令
SLASH_STSMcheck1 = "/STSMcheck"

SlashCmdList["STSMSHOW"] = function(msg)
    STSMmayor_ShowDurabilityFrame()
end

SlashCmdList["STSMHIDE"] = function(msg)
    STSMmayor_HideDurabilityFrame()
end

-- 开始背包检查定时器
function STSMmayor_StartBagCheckTimer()
    if bagCheckTimer then
        return
    end
    
    bagCheckTimer = CreateFrame("Frame")
    bagCheckTimer:SetScript("OnUpdate", function()
        local elapsed = arg1
        lastBagCheckTime = lastBagCheckTime + elapsed
        if lastBagCheckTime >= BAG_CHECK_INTERVAL then
            lastBagCheckTime = 0
            STSMmayor_CheckBagForBrokenShields()
            
            -- 添加自动修理检查
            if STSMmayor_AutoRepairEnabled then
                local slotID = GetInventorySlotInfo("SecondaryHandSlot")
                if slotID then
                    local itemLink = GetInventoryItemLink("player", slotID)
                    if itemLink and STSMmayor_IsOffHandItem(itemLink) then
                        local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                        if durability and maxDurability and maxDurability > 0 then
                            local durabilityPercent = math.floor((durability / maxDurability) * 100)
                            if durabilityPercent < AUTO_REPAIR_THRESHOLD then
                                STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 定时检查发现盾牌耐久过低（" .. durabilityPercent .. "%），自动执行修理...")
                                STSMmayor_AutoRepair()
                            end
                        end
                    end
                end
            end
            
            -- 检查修理机器人状态
            STSMmayor_UpdateRepairBotStatus()

            -- 刷新拾取模组按钮状态（无双DLL可能在窗口打开后才连接成功，复用20秒定时器，不新增OnUpdate）
            STSMmayor_UpdateInteractButtons()
        end
    end)
end

-- 停止背包检查定时器
function STSMmayor_StopBagCheckTimer()
    if bagCheckTimer then
        bagCheckTimer:Hide()
        bagCheckTimer:SetScript("OnUpdate", nil)
        bagCheckTimer = nil
    end
    lastBagCheckTime = 0
end

SlashCmdList["STSM"] = function(msg)
    STSMmayor_Enabled = not STSMmayor_Enabled
    if STSMmayor_Enabled then
        STSMmayor_Print(CHAT_COLOR .. "常用命令：")
        STSMmayor_Print(CHAT_COLOR .. "  /STSM - 开启/关闭插件")
        STSMmayor_Print(CHAT_COLOR .. "  /STSMC - 手动换盾")
        STSMmayor_Print(CHAT_COLOR .. "  /STSMF - 自动修理（需要Interact或无双拾取模组）")
        STSMmayor_Print(CHAT_COLOR .. "  /STSML - 自动拾取（需要Interact或无双拾取模组）")
        STSMmayor_Print(CHAT_COLOR .. "  /STSMSHOW - 显示耐久度监控窗口")
        STSMmayor_Print(CHAT_COLOR .. "  /STSMHIDE - 隐藏耐久度监控窗口")
        STSMmayor_Print(CHAT_COLOR .. "  /STSMcheck - 检查背包中的破损盾牌")
        STSMmayor_Print("报告镇长！自动换修盾插件已成功开启")
        STSMmayor_PrintLootStatus()
        STSMmayor_GenerateShieldReport() -- 显示盾牌状态
        STSMmayor_ShowDurabilityFrame() -- 显示耐久度监控窗口
        STSMmayor_CheckShield() -- 立即检查一次盾牌状态
        STSMmayor_StartBagCheckTimer() -- 启动背包检查定时器
    else
        STSMmayor_Print("镇长再见~自动换修盾插件已关闭")
        STSMmayor_HideDurabilityFrame() -- 关闭时隐藏窗口
        STSMmayor_StopBagCheckTimer() -- 停止背包检查定时器
    end
end

SlashCmdList["STSMC"] = function(msg)
    STSMmayor_ManualEquip()
end

SlashCmdList["STSMF"] = function()
    STSMmayor_AutoRepair()
end

SlashCmdList["STSML"] = function()
    STSMmayor_AutoPickup()
end

SlashCmdList["STSMcheck"] = function()
    STSMmayor_CheckBagForBrokenShields()
end

-- 初始化
STSMmayor_Print("插件已加载，使用/STSM命令开启/关闭，/STSMC命令手动换装，/STSMF命令自动修理，/STSML命令自动拾取")

-- 插件加载后延迟检查地点，因为地图数据可能还没有完全加载
local initFrame = CreateFrame("Frame")
local initElapsed = 0
initFrame:SetScript("OnUpdate", function()
    initElapsed = initElapsed + arg1
    if initElapsed >= 3 then -- 延迟3秒检查，确保地图数据已加载
        initFrame:SetScript("OnUpdate", nil)
        -- 检查地点，如果在目标区域则自动开启插件
        if STSMmayor_IsInTargetZone() and not STSMmayor_Enabled then
            STSMmayor_Enabled = true
            STSMmayor_Print("常用命令：")
            STSMmayor_Print("  /STSM - 开启/关闭插件")
            STSMmayor_Print("  /STSMC - 手动换盾")
            STSMmayor_Print("  /STSMF - 自动修理（需要Interact或无双拾取模组）")
            STSMmayor_Print("  /STSML - 自动拾取（需要Interact或无双拾取模组）")
            STSMmayor_Print("  /STSMSHOW - 显示耐久度监控窗口")
            STSMmayor_Print("  /STSMHIDE - 隐藏耐久度监控窗口")
            STSMmayor_Print("  /STSMcheck - 检查背包中的破损盾牌")
            STSMmayor_Print("报告镇长！自动换修盾插件已成功开启")
            STSMmayor_PrintLootStatus()
            STSMmayor_GenerateShieldReport() -- 显示盾牌状态
            STSMmayor_ShowDurabilityFrame() -- 显示耐久度监控窗口
            STSMmayor_CheckShield() -- 立即检查一次盾牌状态
            STSMmayor_StartBagCheckTimer() -- 启动背包检查定时器
        end
    end
end)