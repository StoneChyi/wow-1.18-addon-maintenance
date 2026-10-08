-- ======================== Lua 全局工具本地化（性能优化）===============================
local pairs = pairs
local pcall = pcall
local GetTime = GetTime
local CreateFrame = CreateFrame
local table_insert = table.insert

--=============负责插件生命周期管理、模块初始化、事件注册/分发==================
local addon = PTURTLE_Combat

-- ====================== 战斗事件处理分发（局部函数）======================
local function OnCombatEvent(event,a1,a2,a3,a4,a5,a6,a7,a8)
    if event == "SPELL_DAMAGE_EVENT_SELF" then
        addon:ParseSpellDamage(a1,a2,a3,a4,a5,a6,a7,a8)
    elseif event == "SPELL_DAMAGE_EVENT_OTHER" then
        addon:ParseSpellDamage(a1,a2,a3,a4,a5,a6,a7,a8)
    elseif event == "AUTO_ATTACK_SELF" then
        addon:ParseAutoAttack(a1,a2,a3,a4,a5,a6,a7,a8)
    elseif event == "AUTO_ATTACK_OTHER" then
        addon:ParseAutoAttack(a1,a2,a3,a4,a5,a6,a7,a8)
    elseif event == "SPELL_MISS_SELF" then
        addon:ParseSpellMiss(a1,a2,a3,a4)
    elseif event == "SPELL_MISS_OTHER" then
        addon:ParseSpellMiss(a1,a2,a3,a4,a5,a6,a7,a8)
    elseif event == "SPELL_GO_SELF" then
        addon:ParseSpellGo(a1,a2,a3,a4)
    elseif event == "BUFF_ADDED_SELF" then
        addon:ParseBuffAdded(a1,a2,a3,a4)
    elseif event == "DEBUFF_ADDED_SELF" then
        addon:ParseBuffAdded(a1,a2,a3,a4)
    elseif event == "SPELL_HEAL_ON_SELF" then
        -- 受到治疗事件：arg1=目标GUID, arg2=施法者GUID, arg3=法术ID，arg4=治疗量, arg5=是否暴击, arg6=是否周期
        addon:ParseReceivedHeal(a1, a2, a3, a4, a5, a6)
    elseif event == "SPELL_HEAL_BY_SELF" then
        -- - 输出治疗事件：arg1=目标GUID, arg2=施法者GUID, arg3=法术ID, arg4=治疗量, arg5=是否暴击（1=暴击，0=非暴击）
        addon:ParseOutHeal(a1, a2, a3, a4, a5)
    elseif event == "SPELL_ENERGIZE_ON_SELF" then
        -- 能量回复事件：arg1=目标GUID, arg2=施法者GUID, arg3=法术ID, arg4=能量类型, arg5=回复量
        addon:ParseEnergize(a3, a4, a5)
    elseif event == "ENVIRONMENTAL_DMG_SELF" then
        -- 环境伤害事件：arg1=目标GUID, arg2=伤害类型, arg3=伤害量, arg4=吸收量, arg5=抵抗量
        addon:ParseEnvironmentalDamage(a2, a3)
    elseif event == "DAMAGE_SHIELD_OTHER" then
        -- 受到的反伤事件：arg1=拥有者GUID, arg2=受害者GUID(玩家), arg3=伤害量, arg4=法术分类
        addon:ParseDamageShield(a1, a2, a3, a4)
    elseif event == "DAMAGE_SHIELD_SELF" then
        -- 反伤盾对敌人造成的伤害：arg1=玩家GUID(拥有者), arg2=受害者GUID(敌人), arg3=伤害量, arg4=法术分类
        addon:ParseDamageShield(a1, a2, a3, a4)
    end
end

-- ====================== 姓名板插件检测与初始化 ======================
function addon:InitNameplates()
    -- 检测已安装的姓名板插件
    local hasPFUI = pfUI and pfUI.nameplates and pfUI.nameplates.OnCreate
    local hasShagu = ShaguPlates and ShaguPlates.nameplates and ShaguPlates.nameplates.OnCreate
    local hasShaguX = ShaguPlatesX and ShaguPlatesX.nameplates and ShaguPlatesX.nameplates.OnCreate
    local hasSimplePlates = SimplePlates and CreatePlates
    
    -- 适配 PFUI/Shagu/ShaguX/SimplePlates：启动重试 Hook
    if hasPFUI or hasShagu or hasShaguX or hasSimplePlates then
        if addon.StartFastHookTimer then
            addon.StartFastHookTimer()  -- 启动 Hook 重试定时器
        end
    else
        -- 没有任何兼容插件，启用原生扫描模式
        if addon.ScanNameplatesSimple then
            addon.ScanNameplatesSimple(true)
        end
    end
end

-- ====================== 自动应答功能管理 ======================
function addon:StartAutoReply()
    if not self.eventFrame then return end
    -- 动态注册密语事件
    self.eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
end

function addon:StopAutoReply()
    if not self.eventFrame then return end
    -- 动态注销密语事件
    self.eventFrame:UnregisterEvent("CHAT_MSG_WHISPER")
    -- 清空密语表
    self.whisperReplyTable = {}
end

-- 处理密语自动回复
function addon:HandleWhisperReply(sender, msg)
    -- 检查是否正在打 BigWigs 追踪的 BOSS
    if not addon.currentBigWigsBossName then
        -- 不在 BOSS 战斗，不回复
        return
    end
    
    -- 检查是否已回复过该玩家
    if self.whisperReplyTable[sender] then
        return  -- 不再重复回复
    end
    
    -- 构建 BOSS 战斗回复（使用 BigWigs 提供的 BOSS 名）
    local bossName = addon.currentBigWigsBossName
    local replyText = string.format("[PlayTurtle] 正在与 <%s> 战斗中！", bossName)
    
    -- 发送密语回复
    SendChatMessage(replyText, "WHISPER", nil, sender)
    -- 记录已回复的玩家
    self.whisperReplyTable[sender] = true
end

-- 处理 BOSS 死亡后的密语回复（使用 BigWigs Hook）
function addon:HandleBossDeathWhisper(bossName)
    if not self.eventFrame then return end
    
    -- 遍历密语表，给所有查询过的玩家发送击杀通知
    for playerName, _ in pairs(self.whisperReplyTable) do
        local replyText = string.format("[PlayTurtle] %s 正在给我擦皮鞋！", bossName or "BOSS")
        SendChatMessage(replyText, "WHISPER", nil, playerName)
    end
    
    -- 清空密语表
    self.whisperReplyTable = {}
end

-- 处理玩家死亡后的密语回复
function addon:HandlePlayerDeathWhisper()
    if not self.eventFrame then return end
    
    -- 遍历密语表，给所有查询过的玩家发送战死通知
    for playerName, _ in pairs(self.whisperReplyTable) do
        SendChatMessage("[PlayTurtle] 我要验牌！", "WHISPER", nil, playerName)
    end
    
    -- 清空密语表
    self.whisperReplyTable = {}
end

-- ====================== 总事件注册 ======================
function addon:RegisterEvents()
    local frame = CreateFrame("Frame", "PlayTurtle_EventFrame")
    self.eventFrame = frame  
    frame:RegisterEvent("SPELL_DAMAGE_EVENT_SELF")
    frame:RegisterEvent("SPELL_DAMAGE_EVENT_OTHER")
    frame:RegisterEvent("AUTO_ATTACK_SELF")
    frame:RegisterEvent("AUTO_ATTACK_OTHER")
    frame:RegisterEvent("SPELL_MISS_SELF")
    frame:RegisterEvent("SPELL_MISS_OTHER")
    frame:RegisterEvent("SPELL_HEAL_ON_SELF")  -- 新增：监听受到治疗
    frame:RegisterEvent("SPELL_HEAL_BY_SELF")  -- - 重新注册：监听自我治疗
    frame:RegisterEvent("ENVIRONMENTAL_DMG_SELF")  -- 新增：监听环境伤害
    frame:RegisterEvent("DAMAGE_SHIELD_OTHER")  -- 新增：监听受到的反伤
    frame:RegisterEvent("DAMAGE_SHIELD_SELF")  -- 新增：监听反伤盾对敌人的伤害
    frame:RegisterEvent("UNIT_PET_GUID")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("UNIT_DIED")
    -- 监听屏幕分辨率变化事件
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    -- 监听目标切换事件
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    -- - 监听 PLAYER_LOGIN 事件，确保 SavedVariables 已加载
    frame:RegisterEvent("PLAYER_LOGIN")
    
    -- 自动应答功能已禁用，不再注册密语事件
    -- if PTURTLE_Combat_DB and PTURTLE_Combat_DB.autoReplyEnabled == 1 then
    --     frame:RegisterEvent("CHAT_MSG_WHISPER")
    -- end
    frame:SetScript("OnEvent", function()
        local event = event
        local a1, a2, a3, a4, a5, a6, a7, a8 = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
        
        if event == "PLAYER_LOGIN" then
            -- 核心新增：保护存档
            if ProtectSavedVariables then
                ProtectSavedVariables()
            end
            
            -- 核心新增：在 PLAYER_LOGIN 后加载个人存档中的技能表
            -- 加载技能过滤表
            if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.skillFilterList then
                addon.skillFilterList = PTURTLE_Combat_CharDB.skillFilterList
            else
                addon.skillFilterList = {}
            end
            
            -- 加载AOE技能表
            if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.AOESkillsByID then
                addon.AOESkillsByID = PTURTLE_Combat_CharDB.AOESkillsByID
            else
                addon.AOESkillsByID = {}
            end
            
            -- 核心新增：统一同步配置（确保存档加载完成后立即同步）
            if addon.SyncConfigFromDB then
                addon:SyncConfigFromDB()
            end
            
            -- 在 PLAYER_LOGIN 时初始化 UI，确保 SavedVariables 已加载
            addon:Init()
            
            -- 在 PLAYER_LOGIN 时创建框架，确保 SavedVariables 已加载
            if addon.CreateReceivedUI then
                addon.CreateReceivedUI()
            end
            
            if addon.CreateAOECounterFrame then
                addon:CreateAOECounterFrame()
            end
            
            if addon.ReloadDigitTexture then
                addon.ReloadDigitTexture()
            end
            
            if addon.UpdateScreenCache then
                addon.UpdateScreenCache()  -- 缓存屏幕中心坐标
            end
            if addon.InitLinePool then
                addon.InitLinePool()  -- 初始化连线池
            end
            
            -- 检查 UnitXP API 是否存在，决定输出治疗淡出模式是否可用
            local unitXPAvailable = false
            if addon.hasUnitXP then
                -- 基础 UnitXP API 已检测到
                if addon.hasUnitXPX then
                    -- UnitXP_X (魔改版) 支持 screenPos
                    unitXPAvailable = true
                    DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 检测到 UnitXP_X (魔改版)，输出治疗淡出模式可用", 0, 1, 0)
                else
                    -- 普通 UnitXP，不支持 screenPos
                    DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 检测到普通 UnitXP，不支持屏幕坐标功能", 1, 0.8, 0)
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 未检测到 UnitXP，输出治疗淡出模式不可用", 1, 0.5, 0)
            end
            addon.unitXPAvailable = unitXPAvailable
            
            -- 根据受治疗/能量动画开关动态注册 SPELL_ENERGIZE_ON_SELF 事件
            if addon.db and addon.db.receivedHealAnimEnabled == 1 then
                frame:RegisterEvent("SPELL_ENERGIZE_ON_SELF")
            end
            
            -- Hook BigWigs Boss 死亡检测（已禁用）
            --[[
            if BigWigs then
                local originalRecvSync = BigWigs.BigWigs_RecvSync
                BigWigs.BigWigs_RecvSync = function(self, sync, moduleName, nick)
                    -- 使用 pcall 调用原始函数，确保不崩溃并保留返回值
                    local success, result = true, nil
                    if originalRecvSync then
                        success, result = pcall(originalRecvSync, self, sync, moduleName, nick)
                        if not success then
                            -- 原始函数出错，记录错误但不影响功能
                            if addon.db and addon.db.debugMode then
                                addon:Print("[BigWigs Hook] 原始 RecvSync 函数出错: " .. tostring(result))
                            end
                        end
                    end
                    
                    -- 获取模块对象
                    local module = moduleName and BigWigs:GetModule(moduleName)
                    
                    -- 监听 EnableModule 同步消息：BOSS 模块启用时保存 BOSS 名并标记 BOSS 战开始
                    if sync == "EnableModule" and module and module:IsBossModule() then
                        if module.translatedName then
                            addon.currentBigWigsBossName = module.translatedName
                            addon.inBigWigsBossFight = true  --  标记 BOSS 战开始
                        end
                    end
                    
                    -- 监听 BossDeath 同步消息：BOSS 击败时播放音乐并清除 BOSS 名和状态
                    if sync == "BossDeath" and module then
                        -- 只有真正的 Boss 模块才播放音乐
                        if module:IsBossModule() and BigWigs:IsModuleActive(module) then
                            if module.translatedName then
                                local bossName = module.translatedName
                                
                                -- 播放 BOSS 死亡音乐
                                local musicPath = "Interface\\AddOns\\PlayTurtle\\Sound\\Music\\MS_1.mp3"
                                if PlaySoundFile then
                                    pcall(PlaySoundFile, musicPath, "Master")
                                end
                                
                                -- 发送 BOSS 击杀密语通知
                                addon:HandleBossDeathWhisper(bossName)
                                
                                -- 清除 BOSS 名和状态（表示 BOSS 胜利）
                                addon.currentBigWigsBossName = nil
                                addon.inBigWigsBossFight = nil  -- 清除 BOSS 战状态
                            end
                        end
                    end
                    
                    -- 返回原始函数的结果
                    return result
                end
                addon:Print("[BigWigs Hook] 已成功 Hook BigWigs Boss 模块")
            else
                addon:Print("[BigWigs Hook] Hook BigWigs 失败")
            end
            --]]
            
            frame:UnregisterEvent("PLAYER_LOGIN")
        elseif event == "PLAYER_ENTERING_WORLD" then
            --  检测 nampower 模组（必须）
            local hasNampower = false
            if GetNampowerVersion then
                local success, version = pcall(GetNampowerVersion)
                if success and version then
                    hasNampower = true
                end
            end
            
            -- nampower 必须存在
            if not hasNampower then
                -- 构建详细的错误信息
                local errorMsg = "未检测到必需模组：\n- nampower.dll\n\n插件无法正常运行\n\n请安装 nampower.dll 后重新加载"
                
                -- 使用 addon 模块的提示框函数
                addon:ShowMissingDependencyDialog("nampower.dll", errorMsg)
                
                -- 注销所有事件
                frame:UnregisterEvent("SPELL_DAMAGE_EVENT_SELF")
                frame:UnregisterEvent("SPELL_DAMAGE_EVENT_OTHER")
                frame:UnregisterEvent("AUTO_ATTACK_SELF")
                frame:UnregisterEvent("AUTO_ATTACK_OTHER")
                frame:UnregisterEvent("SPELL_MISS_SELF")
                frame:UnregisterEvent("SPELL_MISS_OTHER")
                frame:UnregisterEvent("UNIT_PET_GUID")
                frame:UnregisterEvent("PARTY_MEMBERS_CHANGED")
                frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
                frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
                frame:UnregisterEvent("UNIT_DIED")
                frame:UnregisterEvent("CHAT_MSG_WHISPER")
                frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
                return
            end
            
            -- 姓名板插件检测与初始化
            addon:InitNameplates()
            addon:PreloadAllNumberStyles()
            addon:InitPlayerAndPetInfo() -- 初始化玩家和宠物信息
            addon:InitGroupType()  -- 初始化队伍状态
            addon:InitBlizzardDamageSetting()  -- 初始化暴雪伤害显示和必要的np设置
            
            -- 初始化玩家战斗状态
            if UnitAffectingCombat then
                addon.playerInCombat = UnitAffectingCombat("player") or false
            else
                addon.playerInCombat = false
            end
            
            -- 初始化玩家死亡状态
            if UnitIsDeadOrGhost("player") then
                addon.playerDeadOrNot = 1
            else
                addon.playerDeadOrNot = nil
            end       
            
            -- 启动自动扫描（安全检查）
            if addon.StartAutoScan then
                addon:StartAutoScan()
            end
            
            -- 初始化屏幕中心点缓存
            if UpdateScreenCache then
                UpdateScreenCache()
            end
            
            -- 注销 PLAYER_ENTERING_WORLD 事件，只执行一次
            frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        elseif event == "UNIT_PET_GUID" then
            addon:UpdatePetGUID()
        elseif event == "PARTY_MEMBERS_CHANGED" then
            -- 队伍成员变化（包括团队）时重新检测
            addon:InitGroupType()
        elseif event == "RAID_ROSTER_UPDATE" then
            -- 团队 roster 更新时也重新检测
            addon:InitGroupType()
        elseif event == "PLAYER_REGEN_ENABLED" then
            addon:OnPlayerRegenEnabled()
        elseif event == "PLAYER_REGEN_DISABLED" then
            addon:OnPlayerRegenDisabled()
        elseif event == "UNIT_DIED" then
            local diedGUID = a1
            addon:OnUnitDead(diedGUID)
        elseif event == "CHAT_MSG_WHISPER" then
            local sender = a2  
            local msg = a1     
            -- 检查自动应答开关
            if addon.db and addon.db.autoReplyEnabled then
                addon:HandleWhisperReply(sender, msg)
            end
        elseif event == "DISPLAY_SIZE_CHANGED" then
            -- 屏幕分辨率变化时更新缓存
            if UpdateScreenCache then
                UpdateScreenCache()
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- 目标切换时清空缓存的 GUID，让下次调用时重新获取
            if addon.ClearTargetGUIDCache then
                addon:ClearTargetGUIDCache()
            end
        else
            OnCombatEvent(event,a1,a2,a3,a4,a5,a6,a7,a8)
        end
    end)
end

addon:RegisterEvents()