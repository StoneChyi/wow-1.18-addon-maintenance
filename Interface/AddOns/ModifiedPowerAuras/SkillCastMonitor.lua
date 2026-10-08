-- 法术施放监控 - 通用版
-- 专为WoW 1.12设计 - 只监控通用法术事件
-- 仅使用Lua 5.0原生支持的基础语法
-- 支持与MPOWA插件集成

-- 单例模式检查 - 防止多个实例同时运行
if _G["SkillCastMonitor_Singleton"] then
    DEFAULT_CHAT_FRAME:AddMessage("[SCM] 警告: 已经存在一个技能监控实例，跳过初始化", 1, 1, 0)
    return
end
_G["SkillCastMonitor_Singleton"] = true

-- 创建全局事件帧
SkillCastMonitor = CreateFrame("Frame", "SkillCastMonitor")

-- 全局状态变量
SkillCastMonitorEnabled = 0
SkillCastMonitorDebugAllEvents = 0 -- 是否监控所有事件
SkillCastMonitorShowArgs = 0 -- 是否显示参数详情
SkillCastMonitorShowStartEndDebug = 0 -- 是否显示法术开始/结束的调试信息

-- MPOWA集成相关变量 - 这些变量将在MPOWA插件中使用
SkillCastMonitorEvents = {
    -- 最近触发的事件
    lastEvent = nil,
    -- 最近的法术名称
    lastSpellName = nil,
    -- 事件计时器
    eventTimer = 0,
    -- 事件持续时间（秒）
    eventDuration = 5,
    -- 触发标记
    spellCastStart = false,
    spellCastSucceeded = false,
    spellCastFailed = false,
    spellMissed = false,
    -- 推送记录
    lastPushed = nil,
    lastPushedSpellName = nil,
    lastPushTime = nil,
    swingMissed = false,
    -- 事件节流控制
    lastEventTime = 0,
    eventThrottleInterval = 0.5 -- 500ms节流间隔，防止短时间内重复触发
}

-- 优化的打印函数，避免重复打印
function SkillCastMonitor_Print(msg, r, g, b)
    if not r then r = 1 end
    if not g then g = 1 end
    if not b then b = 1 end
    
    -- 只使用DEFAULT_CHAT_FRAME，避免重复输出
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("[SCM] " .. msg, r, g, b)
    end
end

-- 重置事件状态
function SkillCastMonitor_ResetEvents()
    SkillCastMonitorEvents.spellCastStart = false
    SkillCastMonitorEvents.spellCastSucceeded = false
    SkillCastMonitorEvents.spellCastFailed = false
    SkillCastMonitorEvents.spellMissed = false
    SkillCastMonitorEvents.swingMissed = false
end

-- 更新MPOWA事件状态
function SkillCastMonitor_UpdateMPOWAEvent(eventName, spellName)
    -- 在作用域开始处声明所有局部变量（Lua 5.0要求）
    local currentEvent = eventName
    local fullAuraName = "SpellEvent_" .. eventName
    local simpleAuraName = spellName
    local eventOnlyAuraName = eventName
    
    -- 确保SkillCastMonitorEvents存在
    if not SkillCastMonitorEvents then
        SkillCastMonitorEvents = {}
    end
    
    -- 记录事件信息
    SkillCastMonitorEvents.lastEvent = eventName
    SkillCastMonitorEvents.lastSpellName = spellName
    SkillCastMonitorEvents.eventTimer = GetTime()
    
    -- 重置所有事件标记
    SkillCastMonitor_ResetEvents()
    
    -- 设置对应的事件标记
    if currentEvent == "SPELLCAST_START" then
        SkillCastMonitorEvents.spellCastStart = true
    elseif currentEvent == "SPELLCAST_SUCCEEDED" then
        SkillCastMonitorEvents.spellCastSucceeded = true
        -- 为成功施放的法术添加额外的调试信息
        if SkillCastMonitorEnabled == 1 then
            SkillCastMonitor_Print("已设置spellCastSucceeded=true，法术名: " .. (spellName or "未知"), 0, 1, 0)
        end
    elseif currentEvent == "SPELLCAST_STOP" then
        -- 这里可以添加额外逻辑来判断是否是失败的施放
    elseif currentEvent == "SPELL_MISSED" or currentEvent == "SPELL_PERIODIC_MISSED" then
        SkillCastMonitorEvents.spellMissed = true
        SkillCastMonitorEvents.spellCastFailed = true
    elseif currentEvent == "SWING_MISSED" then
        SkillCastMonitorEvents.swingMissed = true
        SkillCastMonitorEvents.spellCastFailed = true
    elseif currentEvent == "UNIT_SPELLCAST_FAILED" then
        SkillCastMonitorEvents.spellCastFailed = true
    elseif currentEvent == "UNIT_SPELLCAST_INTERRUPTED" then
        SkillCastMonitorEvents.spellCastInterrupted = true
    end
    
    -- 更新事件名称变量的值
    -- 1. 完整格式：如果有法术名称则添加
    if spellName then
        fullAuraName = fullAuraName .. "_" .. spellName
    end
    
    -- 2. 用户要求的格式：法术名_事件类型（开始/结束/成功）
    if spellName then
        if eventName == "SPELLCAST_START" then
            simpleAuraName = spellName .. "_开始"
        elseif eventName == "SPELLCAST_STOP" then
            simpleAuraName = spellName .. "_成功"

        elseif eventName == "UNIT_SPELLCAST_FAILED" then
            simpleAuraName = spellName .. "_失败"
        elseif eventName == "UNIT_SPELLCAST_INTERRUPTED" then
            simpleAuraName = spellName .. "_被打断"
        elseif eventName == "SPELL_MISSED" or eventName == "SPELL_PERIODIC_MISSED" then
            simpleAuraName = spellName .. "_抵抗"
        end
    end
    
    -- 调用MPOWA的Push函数（如果存在）
    if MPOWA and MPOWA.Push then
        -- 推送原始事件名称，确保与用户配置兼容
        
        -- 记录最后推送的事件
        SkillCastMonitorEvents.lastPushed = fullAuraName
        
        -- 法术成功或失败时推送，确保图标持续显示
    if (eventName == "SPELLCAST_SUCCEEDED" or eventName == "UNIT_SPELLCAST_FAILED") and simpleAuraName then
            -- 记录最后推送的事件和时间
            SkillCastMonitorEvents.lastPushed = simpleAuraName
            SkillCastMonitorEvents.lastPushedSpellName = spellName  -- 存储原始法术名
            SkillCastMonitorEvents.lastPushTime = GetTime()
            
            if SkillCastMonitorEnabled == 1 then
                if eventName == "SPELLCAST_SUCCEEDED" then
                    SkillCastMonitor_Print("法术成功时推送: " .. simpleAuraName, 0, 1, 1)
                else
                    SkillCastMonitor_Print("法术失败时推送: " .. simpleAuraName, 1, 0, 0)
                end
            end
            
            -- 不再清除旧光环，让光环保持显示
            -- 注释掉Remove调用以避免清理光环
            
            -- 推送事件，设置更长的持续时间（0表示永久）
            MPOWA:Push(simpleAuraName, "player", 0, false) -- 0表示不自动消失
            
            -- 手动激活MPOWA的active状态
            for cat, val in pairs(MPOWA.auras[simpleAuraName] or MPOWA.auras[spellName] or {}) do
                if MPOWA.SAVE[val] then
                    MPOWA.active[val] = 1  -- 强制激活光环
                    if MPOWA.FShow then
                        MPOWA:FShow(val)  -- 直接显示光环
                    end
                end
            end
            
            -- 移除自动清理光环的计时器，让光环持续显示
            -- 清理可能存在的旧计时器
            if SkillCastMonitorEvents.clearTimer then
                SkillCastMonitorEvents.clearTimer:Hide()
                SkillCastMonitorEvents.clearTimer = nil
            end
            
            -- 不再创建自动清理计时器，让光环持续显示
        end
    else
        -- 当MPOWA不存在或没有Push函数时显示警告
        if SkillCastMonitorEnabled == 1 then
            SkillCastMonitor_Print("警告: MPOWA或MPOWA.Push函数不存在", 1, 0, 0)
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 警告：无法连接到MPOWA插件，请确保MPOWA已启用并处于最新版本。", 1, 0, 0)
        end
    end
    
    -- 尝试多种方式触发光环更新检查
    if MPOWA then
        -- 强制更新所有光环状态
        if MPOWA.PushAll then
            if SkillCastMonitorEnabled == 1 then
                SkillCastMonitor_Print("触发MPOWA所有光环更新检查(PushAll)", 0, 1, 1)
            end
            MPOWA:PushAll()
        end
        
        if MPOWA.UpdateAll then
            if SkillCastMonitorEnabled == 1 then
                SkillCastMonitor_Print("触发MPOWA所有光环更新检查(UpdateAll)", 0, 1, 1)
            end
            MPOWA:UpdateAll()
        end
        
        if MPOWA.Refresh then
            if SkillCastMonitorEnabled == 1 then
                SkillCastMonitor_Print("触发MPOWA刷新(Refresh)", 0, 1, 1)
            end
            MPOWA:Refresh()
        end
        
        -- 额外的调试信息
        if SkillCastMonitorEnabled == 1 then
            -- 只在启用开始/结束调试信息时显示
            if (eventName == "SPELLCAST_START" or eventName == "SPELLCAST_STOP") and SkillCastMonitorShowStartEndDebug == 1 then
                local formattedAuraName = ""
                if spellName then
                    if eventName == "SPELLCAST_START" then
                        formattedAuraName = spellName .. "_开始"
                    elseif eventName == "SPELLCAST_STOP" then
                        formattedAuraName = spellName .. "_成功"
                    elseif eventName == "SPELLCAST_SUCCEEDED" then
                        formattedAuraName = spellName .. "_成功"
                    else
                        formattedAuraName = spellName
                    end
                end
                DEFAULT_CHAT_FRAME:AddMessage("[SCM-MPOWA] 推送完成，事件: " .. eventName .. (spellName and "，法术: " .. spellName or ""), 0, 1, 1)
                DEFAULT_CHAT_FRAME:AddMessage("[SCM-MPOWA] MPOWA配置提示：光环名称设置为: " .. formattedAuraName, 0, 1, 0)
            elseif eventName ~= "SPELLCAST_START" and eventName ~= "SPELLCAST_STOP" then
                -- 其他事件保持原有逻辑
                local formattedAuraName = ""
                if spellName then
                    if eventName == "SPELLCAST_SUCCEEDED" then
                        formattedAuraName = spellName .. "_成功"
                    else
                        formattedAuraName = spellName
                    end
                end
                DEFAULT_CHAT_FRAME:AddMessage("[SCM-MPOWA] 推送完成，事件: " .. eventName .. (spellName and "，法术: " .. spellName or ""), 0, 1, 1)
                DEFAULT_CHAT_FRAME:AddMessage("[SCM-MPOWA] MPOWA配置提示：光环名称设置为: " .. formattedAuraName, 0, 1, 0)
            end
        end
    end
end

-- 事件处理函数 - 通用版，不检测特定技能
function SkillCastMonitor_OnEvent()
    -- 在函数作用域最开始声明所有局部变量（Lua 5.0要求）
    local currentEvent = event  -- 直接使用全局event变量
    local currentTime = GetTime()
    local isMonitorEnabled = (SkillCastMonitorEnabled == 1)
    local spellName = nil  -- 声明法术名称变量，稍后在各事件处理中赋值
    
    -- 事件节流控制，防止短时间内重复处理相同事件
    -- 现在所有事件都受节流控制，包括SPELLCAST_SUCCEEDED
    if SkillCastMonitorEvents.lastEventTime > 0 and 
       currentTime - SkillCastMonitorEvents.lastEventTime < SkillCastMonitorEvents.eventThrottleInterval and
       currentEvent == SkillCastMonitorEvents.lastEvent then
        -- 事件太频繁且相同，跳过处理
        if SkillCastMonitorDebugAllEvents == 1 then
            DEFAULT_CHAT_FRAME:AddMessage("[SCM] 节流：跳过重复事件 " .. currentEvent, 1, 1, 0)
        end
        return
    end
    
    -- 更新最后事件时间和类型
    SkillCastMonitorEvents.lastEventTime = currentTime
    SkillCastMonitorEvents.lastEvent = currentEvent
    
    -- 无论是否启用，都显示所有事件（如果开启了全部事件监控）
    if SkillCastMonitorDebugAllEvents == 1 and currentEvent then
        DEFAULT_CHAT_FRAME:AddMessage("[SCM-DEBUG] 捕获事件: " .. currentEvent, 0.5, 0.5, 0.5)
    end
    
    -- 处理直接法术施放事件
    if currentEvent == "SPELLCAST_START" then
        -- 只在启用时显示详细信息
        if isMonitorEnabled then
            SkillCastMonitor_Print("检测到法术开始施放", 1, 1, 0)
        end
        
        -- 尝试获取法术名称
        spellName = arg1
        if spellName then
            -- 只在启用时显示详细信息
            if isMonitorEnabled then
                SkillCastMonitor_Print("法术名称: " .. spellName, 0, 1, 1)
            end
            -- 无论是否启用，都更新MPOWA事件状态
            -- 使用带后缀的法术名直接推送
            local auraNameToPush = spellName
            if currentEvent == "SPELLCAST_START" then
                auraNameToPush = spellName .. "_开始"
                -- 记录推送状态
                SkillCastMonitorEvents.lastPushed = auraNameToPush
                SkillCastMonitorEvents.lastPushedSpellName = spellName  -- 存储原始法术名
                SkillCastMonitorEvents.lastPushTime = GetTime()
                
                if isMonitorEnabled and SkillCastMonitorShowStartEndDebug == 1 then
                    SkillCastMonitor_Print("法术开始时推送光环: " .. auraNameToPush, 0, 1, 1)
                end
                
                -- 直接推送MPOWA
                if MPOWA and MPOWA.Push then
                    -- 不再清除旧光环，让光环保持显示
                    -- 注释掉Remove调用以避免清理光环
                    
                    -- 推送事件，设置更长的持续时间
                    MPOWA:Push(auraNameToPush, "player", 0, false)
                    
                    -- 手动激活MPOWA的active状态
                    for cat, val in pairs(MPOWA.auras[auraNameToPush] or MPOWA.auras[spellName] or {}) do
                        if MPOWA.SAVE[val] then
                            MPOWA.active[val] = 1  -- 强制激活光环
                            if MPOWA.FShow then
                                MPOWA:FShow(val)
                            end
                        end
                    end
                end
            end
            SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
        else
            -- 只在启用时显示详细信息
            if isMonitorEnabled then
                SkillCastMonitor_Print("未找到法术名称", 1, 0, 0)
                -- 只在开启参数显示时才显示参数详情
                if SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SPELLCAST_START")
                end
            end
            -- 无论是否启用，都更新MPOWA事件状态（无法术名称）
            SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
        end
        elseif currentEvent == "SPELLCAST_STOP" then
            -- 关键修改：当检测到法术停止施放时，也尝试推送光环
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到法术停止施放", 0, 1, 0)
            end
            
            -- 尝试获取法术名称
            spellName = arg1
            if not spellName and SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                spellName = SkillCastMonitorEvents.lastSpellName
                if isMonitorEnabled then
                    SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 0, 1, 1)
                end
            elseif spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("法术名称: " .. spellName, 0, 1, 1)
                end
            else
                if isMonitorEnabled then
                    SkillCastMonitor_Print("未找到法术名称", 1, 0, 0)
                    -- 只在开启参数显示时才显示参数详情
                    if SkillCastMonitorShowArgs == 1 then
                        SkillCastMonitor_ShowArgs("SPELLCAST_STOP")
                    end
                end
            end
            
            -- 关键修改：在法术停止施放时，如果有法术名称且距离法术开始时间较短，则推送光环
            if spellName and SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName == spellName then
                -- 记录推送状态
                -- 使用带后缀的法术名作为推送名称
                local auraNameToPush = spellName
                if currentEvent == "SPELLCAST_STOP" then
                    auraNameToPush = spellName .. "_成功"
                end
                
                SkillCastMonitorEvents.lastPushed = auraNameToPush
                SkillCastMonitorEvents.lastPushedSpellName = spellName  -- 存储原始法术名
                SkillCastMonitorEvents.lastPushTime = GetTime()
                
                if isMonitorEnabled and SkillCastMonitorShowStartEndDebug == 1 then
                        SkillCastMonitor_Print("法术停止时推送光环: " .. auraNameToPush, 0, 1, 1)
                        -- 添加与其他事件相同格式的MPOWA配置提示
                        DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. auraNameToPush, 0, 1, 0)
                    end
                
                -- 推送光环，使用与SPELLCAST_SUCCEEDED相同的逻辑
                if MPOWA and MPOWA.Push then
                    -- 添加调试信息
                    if isMonitorEnabled and SkillCastMonitorShowArgs == 1 then
                        SkillCastMonitor_Print("[调试] MPOWA存在，准备推送", 1, 1, 0)
                        if MPOWA.auras and MPOWA.auras[spellName] then
                            SkillCastMonitor_Print("[调试] MPOWA中存在光环配置: " .. spellName, 1, 1, 0)
                        else
                            SkillCastMonitor_Print("[调试] MPOWA中不存在光环配置: " .. spellName, 1, 0, 1)
                        end
                    end
                    
                    -- 不再清除旧光环，让光环保持显示
                    -- 注释掉Remove调用以避免清理光环
                    
                    -- 确保MPOWA的必要表存在
                    if not MPOWA.pushed then
                        MPOWA.pushed = {}
                    end
                    if not MPOWA.activeTimer then
                        MPOWA.activeTimer = {}
                    end
                    
                    -- 推送事件，设置更长的持续时间
                    MPOWA:Push(auraNameToPush, "player", 0, false)  -- 0表示不自动消失
                    
                    -- 手动激活MPOWA的active状态（这可能是关键）
                    -- 同时检查原始法术名和带后缀的法术名
                    for cat, val in pairs(MPOWA.auras[auraNameToPush] or MPOWA.auras[spellName] or {}) do
                        if MPOWA.SAVE[val] then
                            MPOWA.active[val] = 1  -- 强制激活光环
                            if MPOWA.FShow then
                                MPOWA:FShow(val)  -- 直接显示光环
                            end
                            if isMonitorEnabled and SkillCastMonitorShowArgs == 1 then
                                SkillCastMonitor_Print("[调试] 手动激活光环ID: " .. tostring(val), 1, 1, 0)
                            end
                        end
                    end
                    
                    -- 移除自动清理光环的计时器，让光环持续显示
                    -- 清理可能存在的旧计时器
                    if SkillCastMonitorEvents.clearTimer then
                        SkillCastMonitorEvents.clearTimer:Hide()
                        SkillCastMonitorEvents.clearTimer = nil
                    end
                    
                    -- 不再创建自动清理计时器，让光环持续显示
                end
            end
        elseif currentEvent == "SPELLCAST_SUCCEEDED" then
            -- 关键事件：确保被处理，不受监控开关限制
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到法术施放成功", 0, 1, 0)
            end
            
            -- 尝试获取法术名称
            spellName = arg1
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("法术名称: " .. spellName, 0, 1, 1)
                    -- 高亮显示法术成功施放
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] *** 法术施放成功: " .. spellName .. " ***", 1, 0, 0)
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. "_成功", 0, 1, 0)
                end
                -- 强制更新事件状态，不受监控开关限制
                SkillCastMonitorEvents.spellCastSucceeded = true
                SkillCastMonitorEvents.lastSpellName = spellName
                SkillCastMonitorEvents.eventTimer = GetTime()
                -- 更新MPOWA事件状态，不受监控开关限制
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                -- 尝试使用最近的法术名称
                if SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                    spellName = SkillCastMonitorEvents.lastSpellName
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 0, 1, 1)
                    end
                    -- 强制更新事件状态，不受监控开关限制
                    SkillCastMonitorEvents.spellCastSucceeded = true
                    SkillCastMonitorEvents.lastSpellName = spellName
                    SkillCastMonitorEvents.eventTimer = GetTime()
                    -- 使用最近的法术名称更新MPOWA事件，不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
                else
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("未找到法术名称", 1, 0, 0)
                        -- 只在开启参数显示时才显示参数详情
                        if SkillCastMonitorShowArgs == 1 then
                            SkillCastMonitor_ShowArgs("SPELLCAST_SUCCEEDED")
                        end
                    end
                    -- 更新MPOWA事件状态（无法术名称），不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
                end
            end
        elseif currentEvent == "SPELLCAST_CHANNEL_START" then
            -- 处理引导法术开始
            if isMonitorEnabled then
                SkillCastMonitor_Print("检测到引导法术开始", 1, 1, 0)
            end
            
            local spellName = arg1
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("引导法术名称: " .. spellName, 0, 1, 1)
                    -- 添加MPOWA配置提示
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. "_引导开始", 0, 1, 0)
                end
                -- 更新MPOWA事件状态
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                if isMonitorEnabled and SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SPELLCAST_CHANNEL_START")
                end
                -- 更新MPOWA事件状态（无法术名称）
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
            end
        elseif currentEvent == "SPELLCAST_CHANNEL_STOP" then
            -- 处理引导法术结束
            if isMonitorEnabled then
                SkillCastMonitor_Print("检测到引导法术结束", 1, 1, 0)
            end
            
            local spellName = arg1
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("引导法术名称: " .. spellName, 0, 1, 1)
                    -- 添加MPOWA配置提示
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. "_引导结束", 0, 1, 0)
                end
                -- 更新MPOWA事件状态
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                if isMonitorEnabled and SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SPELLCAST_CHANNEL_STOP")
                end
                -- 更新MPOWA事件状态（无法术名称）
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
            end
        elseif currentEvent == "UNIT_SPELLCAST_FAILED" then
            -- 关键事件：确保被处理，不受监控开关限制
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到法术施放失败", 1, 0, 0)
            end
            
            -- 尝试获取法术名称（对于UNIT_SPELLCAST_FAILED，法术名在arg2位置）
            spellName = arg2
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("法术名称: " .. spellName, 1, 0, 0)
                    -- 高亮显示法术失败施放
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] *** 法术施放失败: " .. spellName .. " ***", 1, 0, 0)
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. "_失败", 0, 1, 0)
                end
                -- 强制更新事件状态，不受监控开关限制
                SkillCastMonitorEvents.spellCastFailed = true
                SkillCastMonitorEvents.lastSpellName = spellName
                SkillCastMonitorEvents.eventTimer = GetTime()
                -- 更新MPOWA事件状态，不受监控开关限制
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                -- 尝试使用最近的法术名称
                if SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                    spellName = SkillCastMonitorEvents.lastSpellName
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 1, 0, 0)
                    end
                    -- 强制更新事件状态，不受监控开关限制
                    SkillCastMonitorEvents.spellCastFailed = true
                    SkillCastMonitorEvents.lastSpellName = spellName
                    SkillCastMonitorEvents.eventTimer = GetTime()
                    -- 使用最近的法术名称更新MPOWA事件，不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
                else
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("未找到法术名称", 1, 0, 0)
                    end
                    -- 更新MPOWA事件状态（无法术名称），不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
                end
            end
        elseif currentEvent == "UNIT_SPELLCAST_INTERRUPTED" then
            -- 关键事件：确保被处理，不受监控开关限制
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到法术被打断", 1, 0, 0)
            end
            
            -- 尝试获取法术名称（对于UNIT_SPELLCAST_INTERRUPTED，法术名在arg2位置）
            spellName = arg2
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("法术名称: " .. spellName, 1, 0, 0)
                    -- 高亮显示法术被打断
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] *** 法术被打断: " .. spellName .. " ***", 1, 0, 0)
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. "_被打断", 0, 1, 0)
                end
                -- 强制更新事件状态，不受监控开关限制
                SkillCastMonitorEvents.spellCastFailed = true
                SkillCastMonitorEvents.spellCastInterrupted = true
                SkillCastMonitorEvents.lastSpellName = spellName
                SkillCastMonitorEvents.eventTimer = GetTime()
                -- 更新MPOWA事件状态，不受监控开关限制
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                -- 尝试使用最近的法术名称
                if SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                    spellName = SkillCastMonitorEvents.lastSpellName
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 1, 0, 0)
                    end
                    -- 强制更新事件状态，不受监控开关限制
                    SkillCastMonitorEvents.spellCastFailed = true
                    SkillCastMonitorEvents.spellCastInterrupted = true
                    SkillCastMonitorEvents.lastSpellName = spellName
                    SkillCastMonitorEvents.eventTimer = GetTime()
                    -- 使用最近的法术名称更新MPOWA事件，不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
                else
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("未找到法术名称", 1, 0, 0)
                    end
                    -- 更新MPOWA事件状态（无法术名称），不受监控开关限制
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
                end
            end
        elseif currentEvent == "PLAYER_ENTERING_WORLD" then
            if isMonitorEnabled then
                SkillCastMonitor_Print("玩家进入世界，监控已启动", 0, 1, 0)
            end
        -- 未命中事件监控
        elseif currentEvent == "SWING_MISSED" then
            if isMonitorEnabled then
                SkillCastMonitor_Print("检测到近战攻击未命中！", 1, 0.5, 0)
                if SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SWING_MISSED")
                end
                -- 尝试获取攻击来源和目标信息
                local sourceName = arg2
                local missType = arg3
                if sourceName then
                    SkillCastMonitor_Print("攻击来源: " .. sourceName, 1, 1, 1)
                end
                if missType then
                    SkillCastMonitor_Print("未命中类型: " .. missType, 1, 0, 0)
                    -- 添加MPOWA配置提示
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: 近战_" .. missType, 0, 1, 0)
                end
            end
            -- 更新MPOWA事件状态
            SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
        elseif currentEvent == "SPELL_MISSED" then
            -- 关键事件：确保被处理，不受监控开关限制
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到法术未命中！", 1, 0, 1)
                -- 详细调试信息
                SkillCastMonitor_Print("事件详情 - 目标: " .. (arg1 or "未知") .. ", 源: " .. (arg2 or "未知"), 1, 0.5, 0)
                
                if SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SPELL_MISSED")
                end
            end
            
            -- 尝试获取法术名称和未命中类型
            local spellName = arg12
            local missType = arg4
            
            -- 调试：显示未命中类型详细信息
            if isMonitorEnabled and missType then
                local missTypeDesc = missType
                if missType == "IMMUNE" then missTypeDesc = "免疫" 
                elseif missType == "RESIST" then missTypeDesc = "抵抗" 
                elseif missType == "DODGE" then missTypeDesc = "躲闪" 
                elseif missType == "PARRY" then missTypeDesc = "招架" 
                elseif missType == "BLOCK" then missTypeDesc = "格挡" 
                elseif missType == "EVADE" then missTypeDesc = "闪避" 
                elseif missType == "MISS" then missTypeDesc = "未命中" 
                elseif missType == "REFLECT" then missTypeDesc = "反射" end
                SkillCastMonitor_Print("未命中详细类型: " .. missType .. " (" .. missTypeDesc .. ")", 1, 0, 1)
            end
            
            -- 强制更新事件状态，不受监控开关限制
            SkillCastMonitorEvents.spellMissed = true
            SkillCastMonitorEvents.spellCastFailed = true
            
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("未命中法术: " .. spellName, 1, 0, 1)
                    -- 高亮显示法术未命中
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] *** 法术未命中 ***", 1, 0, 0)
                end
                -- MPOWA配置提示不受监控开关限制，根据实际未命中类型动态设置
                local missSuffix = "_未命中"
                if missType == "RESIST" then missSuffix = "_抵抗" 
                elseif missType == "IMMUNE" then missSuffix = "_免疫" 
                elseif missType == "DODGE" then missSuffix = "_躲闪" 
                elseif missType == "PARRY" then missSuffix = "_招架" 
                elseif missType == "BLOCK" then missSuffix = "_格挡" 
                elseif missType == "EVADE" then missSuffix = "_闪避" 
                elseif missType == "MISS" then missSuffix = "_未命中" 
                elseif missType == "REFLECT" then missSuffix = "_反射" end
                DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. missSuffix, 0, 1, 0)
                -- 无论是否启用，都更新MPOWA事件状态
                SkillCastMonitorEvents.lastSpellName = spellName
                SkillCastMonitorEvents.eventTimer = GetTime()
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                -- 尝试使用最近的法术名称
                if SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                    spellName = SkillCastMonitorEvents.lastSpellName
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 1, 0, 1)
                    end
                    -- 无论是否启用，都更新MPOWA事件状态
                    SkillCastMonitorEvents.lastSpellName = spellName
                    SkillCastMonitorEvents.eventTimer = GetTime()
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
                else
                    -- 更新MPOWA事件状态（无法术名称）
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
                end
            end
            
            if isMonitorEnabled and missType then
                SkillCastMonitor_Print("未命中类型: " .. missType, 1, 0, 0)
            end
        elseif currentEvent == "SPELL_PERIODIC_MISSED" then
            -- 关键事件：确保被处理，不受监控开关限制
            if isMonitorEnabled then
                SkillCastMonitor_Print("[关键] 检测到周期性法术未命中！", 1, 0, 1)
                -- 详细调试信息
                SkillCastMonitor_Print("周期性事件详情 - 目标: " .. (arg1 or "未知") .. ", 源: " .. (arg2 or "未知"), 1, 0.5, 0)
                
                if SkillCastMonitorShowArgs == 1 then
                    SkillCastMonitor_ShowArgs("SPELL_PERIODIC_MISSED")
                end
            end
            
            -- 尝试获取法术名称和未命中类型
            local spellName = arg12
            local missType = arg4
            
            -- 调试：显示未命中类型详细信息
            if isMonitorEnabled and missType then
                local missTypeDesc = missType
                if missType == "IMMUNE" then missTypeDesc = "免疫" 
                elseif missType == "RESIST" then missTypeDesc = "抵抗" 
                elseif missType == "DODGE" then missTypeDesc = "躲闪" 
                elseif missType == "PARRY" then missTypeDesc = "招架" 
                elseif missType == "BLOCK" then missTypeDesc = "格挡" 
                elseif missType == "EVADE" then missTypeDesc = "闪避" 
                elseif missType == "MISS" then missTypeDesc = "未命中" 
                elseif missType == "REFLECT" then missTypeDesc = "反射" end
                SkillCastMonitor_Print("周期性法术未命中类型: " .. missType .. " (" .. missTypeDesc .. ")", 1, 0, 1)
            end
            
            -- 无论是否启用，都设置失败标志
            SkillCastMonitorEvents.spellMissed = true
            SkillCastMonitorEvents.spellCastFailed = true
            
            if spellName then
                if isMonitorEnabled then
                    SkillCastMonitor_Print("未命中周期性法术: " .. spellName, 1, 0, 1)
                    -- 高亮显示周期性法术未命中
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] *** 周期性法术未命中 ***", 1, 0, 0)
                end
                -- MPOWA配置提示不受监控开关限制，根据实际未命中类型动态设置
                local missSuffix = "_未命中"
                if missType == "RESIST" then missSuffix = "_抵抗" 
                elseif missType == "IMMUNE" then missSuffix = "_免疫" 
                elseif missType == "DODGE" then missSuffix = "_躲闪" 
                elseif missType == "PARRY" then missSuffix = "_招架" 
                elseif missType == "BLOCK" then missSuffix = "_格挡" 
                elseif missType == "EVADE" then missSuffix = "_闪避" 
                elseif missType == "MISS" then missSuffix = "_未命中" 
                elseif missType == "REFLECT" then missSuffix = "_反射" end
                DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. missSuffix, 0, 1, 0)
                -- 无论是否启用，都更新MPOWA事件状态
                SkillCastMonitorEvents.lastSpellName = spellName
                SkillCastMonitorEvents.eventTimer = GetTime()
                SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
            else
                -- 尝试使用最近的法术名称
                if SkillCastMonitorEvents and SkillCastMonitorEvents.lastSpellName then
                    spellName = SkillCastMonitorEvents.lastSpellName
                    if isMonitorEnabled then
                        SkillCastMonitor_Print("使用最近的法术名称: " .. spellName, 1, 0, 1)
                    end
                    -- 无论是否启用，都更新MPOWA事件状态
                    SkillCastMonitorEvents.lastSpellName = spellName
                    SkillCastMonitorEvents.eventTimer = GetTime()
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, spellName)
                else
                    -- 更新MPOWA事件状态（无法术名称）
                    SkillCastMonitor_UpdateMPOWAEvent(currentEvent, nil)
                end
            end
            
            if isMonitorEnabled and missType then
                SkillCastMonitor_Print("未命中类型: " .. missType, 1, 0, 0)
            end
        elseif currentEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
            -- 处理战斗日志事件，捕获所有战斗相关信息
            -- 无论监控是否启用，都处理法术未命中/抵抗事件的MPOWA配置提示
            local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags = arg1, arg2, arg3, arg4, arg5, arg6, arg7
            local destGUID, destName, destFlags, destRaidFlags = arg8, arg9, arg10, arg11
            
            -- 无论监控是否启用，都处理法术未命中事件的配置提示
            if eventType == "SPELL_MISSED" or eventType == "SPELL_PERIODIC_MISSED" then
                local spellId, spellName, spellSchool = arg12, arg13, arg14
                local missType = arg15
                
                if spellName and missType then
                    -- 根据实际未命中类型动态设置后缀
                    local missSuffix = "_未命中"
                    if missType == "RESIST" then missSuffix = "_抵抗" 
                    elseif missType == "IMMUNE" then missSuffix = "_免疫" 
                    elseif missType == "DODGE" then missSuffix = "_躲闪" 
                    elseif missType == "PARRY" then missSuffix = "_招架" 
                    elseif missType == "BLOCK" then missSuffix = "_格挡" 
                    elseif missType == "EVADE" then missSuffix = "_闪避" 
                    elseif missType == "MISS" then missSuffix = "_未命中" 
                    elseif missType == "REFLECT" then missSuffix = "_反射" end
                    
                    -- 不受监控开关限制，始终显示MPOWA配置提示
                    DEFAULT_CHAT_FRAME:AddMessage("[SCM] MPOWA配置提示：光环名称设置为: " .. spellName .. missSuffix, 0, 1, 0)
                end
            end
            
            if isMonitorEnabled then
                -- 解析战斗日志参数
                local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags = arg1, arg2, arg3, arg4, arg5, arg6, arg7
                local destGUID, destName, destFlags, destRaidFlags = arg8, arg9, arg10, arg11
                
                -- 特别关注法术未命中和抵抗事件
                if eventType == "SPELL_MISSED" or eventType == "SPELL_PERIODIC_MISSED" then
                    local spellId, spellName, spellSchool = arg12, arg13, arg14
                    local missType = arg15
                    local amountMissed = arg16
                    
                    -- 显示详细的战斗日志信息
                    SkillCastMonitor_Print("[战斗日志] 法术未命中 - 事件类型: " .. eventType .. ", 法术: " .. (spellName or "未知") .. ", 目标: " .. (destName or "未知"), 1, 0, 1)
                    
                    if missType then
                        local missTypeDesc = missType
                        if missType == "IMMUNE" then missTypeDesc = "免疫" 
                        elseif missType == "RESIST" then missTypeDesc = "抵抗" 
                        elseif missType == "DODGE" then missTypeDesc = "躲闪" 
                        elseif missType == "PARRY" then missTypeDesc = "招架" 
                        elseif missType == "BLOCK" then missTypeDesc = "格挡" 
                        elseif missType == "EVADE" then missTypeDesc = "闪避" 
                        elseif missType == "MISS" then missTypeDesc = "未命中" 
                        elseif missType == "REFLECT" then missTypeDesc = "反射" end
                        
                        SkillCastMonitor_Print("[战斗日志] 未命中类型: " .. missType .. " (" .. missTypeDesc .. "), 抵抗数值: " .. (amountMissed or "未知"), 1, 0, 0)
                    end
                    
                    -- 更新MPOWA事件状态
                    if spellName then
                        SkillCastMonitor_UpdateMPOWAEvent(eventType, spellName)
                    end
                end
                
                -- 仅在调试所有事件时显示其他战斗日志信息
                if SkillCastMonitorDebugAllEvents == 1 then
                    SkillCastMonitor_Print("[战斗日志] 事件类型: " .. eventType .. ", 源: " .. (sourceName or "未知") .. ", 目标: " .. (destName or "未知"), 0.5, 0.5, 0.5)
                end
            end
        end
    end


-- 辅助函数：显示所有参数
function SkillCastMonitor_ShowArgs(eventName)
    -- 只在监控启用时显示参数信息
    if SkillCastMonitorEnabled == 1 then
        SkillCastMonitor_Print(eventName .. "参数:", 1, 1, 0)
        local argIndex = 1
        while argIndex <= 10 do
            local argValue = getglobal("arg"..argIndex)
            if argValue then
                SkillCastMonitor_Print("arg"..argIndex.."= " .. argValue, 0, 1, 1)
            else
                SkillCastMonitor_Print("arg"..argIndex.."=nil", 1, 0, 0)
            end
            argIndex = argIndex + 1
        end
    end
end

-- 安全地设置事件脚本
if SkillCastMonitor and SkillCastMonitor.SetScript then
    SkillCastMonitor:SetScript("OnEvent", SkillCastMonitor_OnEvent)
    -- 移除事件自动重置逻辑，让光环保持显示
    SkillCastMonitor:SetScript("OnUpdate", function() 
        -- 保留空的OnUpdate脚本以避免错误，但不再自动重置事件
    end)
else
    print("[SCM] 错误: 无法设置事件脚本！")
end

-- 安全地注册事件
if SkillCastMonitor and SkillCastMonitor.RegisterEvent then
    -- 先取消所有可能的事件注册，防止重复
    SkillCastMonitor:UnregisterAllEvents()
    
    -- 注册直接法术施放事件
    SkillCastMonitor:RegisterEvent("SPELLCAST_START")
    SkillCastMonitor:RegisterEvent("SPELLCAST_STOP")
    SkillCastMonitor:RegisterEvent("SPELLCAST_SUCCEEDED")
    
    -- 添加引导法术事件
    SkillCastMonitor:RegisterEvent("SPELLCAST_CHANNEL_START")
    SkillCastMonitor:RegisterEvent("SPELLCAST_CHANNEL_STOP")
    
    -- 注册其他重要事件
    SkillCastMonitor:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- 注册未命中事件监控
    SkillCastMonitor:RegisterEvent("SWING_MISSED")
    SkillCastMonitor:RegisterEvent("SPELL_MISSED")
    SkillCastMonitor:RegisterEvent("SPELL_PERIODIC_MISSED")
    
    -- 添加战斗日志事件监控，捕获所有战斗相关事件
    SkillCastMonitor:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- 注册法术失败和被打断事件监控
    SkillCastMonitor:RegisterEvent("UNIT_SPELLCAST_FAILED")
    SkillCastMonitor:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    
    DEFAULT_CHAT_FRAME:AddMessage("[SCM] 通用法术监控事件注册完成", 0, 1, 0)
else
    DEFAULT_CHAT_FRAME:AddMessage("[SCM] 错误: 无法注册事件！", 1, 0, 0)
end

-- 命令处理函数
function SkillCastMonitor_Command(cmd)
    local cmd_lower = cmd
    if cmd_lower then
        cmd_lower = strlower(cmd_lower)
    else
        cmd_lower = ""
    end
    
    if cmd_lower == "on" then
        SkillCastMonitorEnabled = 1
        SkillCastMonitor_Print("监控已开启", 0, 1, 0)
    elseif cmd_lower == "off" then
        SkillCastMonitorEnabled = 0
        SkillCastMonitor_Print("监控已关闭", 1, 0, 0)
    elseif cmd_lower == "test" then
        SkillCastMonitor_Print("测试功能正常！", 0, 1, 0)
        
        local testPlayer = UnitName("player")
        if not testPlayer then
            testPlayer = "测试玩家"
        end
        SkillCastMonitor_Print("模拟: " .. testPlayer .. " 施放了一个法术", 0, 1, 1)
        
        -- 简化测试提示
        SkillCastMonitor_Print("*** 法术施放成功！ ***", 1, 0, 0)
        
        -- 测试MPOWA集成
        if MPOWA then
            SkillCastMonitor_Print("正在测试MPOWA集成...", 0, 1, 1)
            SkillCastMonitor_UpdateMPOWAEvent("SPELLCAST_START", "测试法术")
            SkillCastMonitor_Print("MPOWA事件推送成功", 0, 1, 1)
        else
            SkillCastMonitor_Print("MPOWA插件未加载", 1, 1, 0)
        end
    elseif cmd_lower == "allevents" then
        -- 切换所有事件监控
        if SkillCastMonitorDebugAllEvents == 0 then
            SkillCastMonitorDebugAllEvents = 1
            SkillCastMonitor_Print("已开启所有事件监控", 0, 1, 1)
        else
            SkillCastMonitorDebugAllEvents = 0
            SkillCastMonitor_Print("已关闭所有事件监控", 1, 0.5, 0)
        end
    elseif cmd_lower == "args" then
        -- 切换参数显示
        if SkillCastMonitorShowArgs == 0 then
            SkillCastMonitorShowArgs = 1
            SkillCastMonitor_Print("已开启参数详情显示", 0, 1, 1)
        else
            SkillCastMonitorShowArgs = 0
            SkillCastMonitor_Print("已关闭参数详情显示", 1, 0.5, 0)
        end
    elseif cmd_lower == "startenddebug" then
        -- 切换法术开始/结束调试信息显示
        if SkillCastMonitorShowStartEndDebug == 0 then
            SkillCastMonitorShowStartEndDebug = 1
            SkillCastMonitor_Print("已开启法术开始/结束调试信息显示", 0, 1, 1)
        else
            SkillCastMonitorShowStartEndDebug = 0
            SkillCastMonitor_Print("已关闭法术开始/结束调试信息显示", 1, 0.5, 0)
        end
    elseif cmd_lower == "mpowa" then
        -- MPOWA集成帮助
        DEFAULT_CHAT_FRAME:AddMessage("====== MPOWA集成说明 ======", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("1. 在MPOWA中创建新光环", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("2. 光环名称设置为法术名称，例如:", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("   - 圣光闪现", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("   - 治疗术", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("3. 请确保只使用法术名称本身作为光环名称，不要添加任何前缀或后缀。", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("4. 事件状态变量可在自定义函数中使用:", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("   - SkillCastMonitorEvents.spellCastStart", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("   - SkillCastMonitorEvents.spellCastSucceeded", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("   - SkillCastMonitorEvents.spellMissed", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("=======================", 0, 1, 1)
    else
        -- 帮助信息
        DEFAULT_CHAT_FRAME:AddMessage("====== 法术施放监控帮助 ======", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm on - 开启监控", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm off - 关闭监控", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm test - 测试功能", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm allevents - 开关所有事件监控", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm args - 开关参数详情显示", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm startenddebug - 开关法术开始/结束调试信息", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("/scm mpowa - 显示MPOWA集成帮助", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("=======================", 0, 1, 0)
    end
end



-- 注册命令
SLASH_SCM1 = "/scm"
SlashCmdList["SCM"] = SkillCastMonitor_Command

-- 初始化信息
DEFAULT_CHAT_FRAME:AddMessage("====== 法术施放监控 - 通用版 ======", 0, 1, 0)
DEFAULT_CHAT_FRAME:AddMessage("Lua 5.0兼容版已加载", 0, 1, 0)
DEFAULT_CHAT_FRAME:AddMessage("使用/scm命令进行操作", 0, 1, 0)
DEFAULT_CHAT_FRAME:AddMessage("监控事件: SPELLCAST_*系列 + 引导法术事件 + 未命中事件", 0, 1, 1)
DEFAULT_CHAT_FRAME:AddMessage("参数显示默认关闭，使用/scm args开启", 0, 1, 1)
DEFAULT_CHAT_FRAME:AddMessage("已启用MPOWA插件集成", 0, 1, 1)
DEFAULT_CHAT_FRAME:AddMessage("=======================", 0, 1, 0)