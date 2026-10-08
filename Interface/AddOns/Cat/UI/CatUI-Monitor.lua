-- 定义插件名称
local ADDON_NAME = "CatUI"

-- 创建主框架
CatDebugWindow = CreateFrame("Frame", ADDON_NAME.."Frame", UIParent)
CatDebugWindow:Hide()

-- 设置窗口基本属性
CatDebugWindow:SetWidth(240)
CatDebugWindow:SetHeight(560)
CatDebugWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CatDebugWindow:SetFrameLevel(1)

-- 创建Tooltip风格的背景和边框
CatDebugWindow:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CatDebugWindow:SetBackdropColor(0.1, 0.1, 0.2, 0.7)
--CatDebugWindow:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.1)
CatDebugWindow:SetScale(0.8)

-- 使窗口可移动
CatDebugWindow:EnableMouse(true)
CatDebugWindow:SetMovable(true)
CatDebugWindow:RegisterForDrag("LeftButton")
CatDebugWindow:SetScript("OnDragStart", function()
    CatDebugWindow:StartMoving()
end)
CatDebugWindow:SetScript("OnDragStop", function()
    CatDebugWindow:StopMovingOrSizing()
end)

-- 添加标题文字
local title = CatDebugWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", CatDebugWindow, "TOPLEFT", 10, -10)
title:SetText(MPLanguage.UI_MonitorTitle)

-- 添加标准关闭按钮（精确对齐标题行）
local closeButton = CreateFrame("Button", nil, CatDebugWindow, "UIPanelCloseButton")
closeButton:SetWidth(32)
closeButton:SetHeight(32)
closeButton:SetPoint("TOPRIGHT", CatDebugWindow, "TOPRIGHT", -5, -2)  -- Y坐标调整为-10，与标题完全对齐
-- 设置点击事件
closeButton:SetScript("OnClick", function(self)
    MPPublicSaved.DebugWindowDisplay = 0
    CatDebugWindow:Hide()
    DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor..MPLanguage.UI_MonitorClosed)
end)

-- 添加分隔线
local divider = CatDebugWindow:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
divider:SetTexCoord(0.81, 0.94, 0.5, 1)
divider:SetVertexColor(0.5, 0.5, 0.5)
divider:SetWidth(230)
divider:SetHeight(4)
divider:SetPoint("TOP", CatDebugWindow, "TOP", 0, -30)

-- 添加文本内容区域
MPUIcontentText = CatDebugWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
MPUIcontentText:SetPoint("TOPLEFT", CatDebugWindow, "TOPLEFT", 15, -40)
MPUIcontentText:SetWidth(250)
MPUIcontentText:SetTextColor(1.0, 1.0, 1.0)
MPUIcontentText:SetJustifyH("LEFT")
MPUIcontentText:SetText("  ")

-- 添加提示内容区域
local TipText = CatDebugWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TipText:SetPoint("BOTTOM", CatDebugWindow, "BOTTOM", 0, 9)
TipText:SetWidth(250)
TipText:SetTextColor(0.6, 0.6, 0.6)
TipText:SetJustifyH("CENTER")
TipText:SetText(MPLanguage.UI_Mon_Version..MPCatAddonVer.." ]")


--

function MPRefreshInfoUI()
    -- 窗口未打开不刷新属性
    if not CatDebugWindow:IsVisible() then
        return
    end

    local Text
    local _, englishClass = UnitClass("player")


    -- 通用属性
    Text = MPtextSystemInfo .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_GeneralParams.." - |r\n"


    local t = UnitExists("target")


    if t and MP_UnitXP then
        if MPCheckBehind(1) then
            Text = Text .. "\n"..MPLanguage.UI_Mon_TargetFacing.." |cFF6dff7b"..MPLanguage.UI_Mon_Behind.."|r"
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_TargetFacing.." |cFFff5c36"..MPLanguage.UI_Mon_Front.."|r"
        end

        if UnitIsVisible("target") then
            Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDistance.." ".. string.format("%.2f", UnitXP("distanceBetween", "player", "target"))
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDistance.." "..MPLanguage.UI_Mon_OutOfVisibleRange
        end

    elseif not MP_UnitXP then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetFacing.." |cFF888888.."..MPLanguage.UI_Mon_NoUnitXP.."|r"
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDistance.." |cFF888888"..MPLanguage.UI_Mon_NoUnitXP.."|r"
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetFacing.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDistance.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end


    if t and MPTargetBleed then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetBleed.." |cFF6dff7b"..MPLanguage.UI_Mon_CanBleed.."|r"
    elseif t and not MPTargetBleed then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetBleed.." |cFFff5c36"..MPLanguage.UI_Mon_CannotBleed.."|r"
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetBleed.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end

    if t and MPIsDrain() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDrain.." |cFF6dff7b"..MPLanguage.UI_Mon_CanDrain.."|r"
    elseif t and not MPIsDrain() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDrain.." |cFFff5c36"..MPLanguage.UI_Mon_CannotDrain.."|r"
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetDrain.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end

    if t and MPIsPosion() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetPosion.." |cFF6dff7b"..MPLanguage.UI_Mon_CanPosion.."|r"
    elseif t and not MPIsPosion() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetPosion.." |cFFff5c36"..MPLanguage.UI_Mon_CannotPosion.."|r"
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetPosion.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end

    if t and MPIsBossTarget() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetType.." |cFF6dff7bBOSS|r"
    elseif t and not MPIsBossTarget() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetType.." "..MPLanguage.UI_Mon_Normal
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetType.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end

    if t then
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetArmor.." "..UnitArmor("target")
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_TargetArmor.." |cFF888888"..MPLanguage.UI_Mon_NoTarget.."|r"
    end

    if not MP_SuperWoW then
        Text = Text .. "\n"..MPLanguage.UI_Mon_MeleeEnemies.." |cFF888888"..MPLanguage.UI_Mon_NoSuperWoW.."|r"
    else
        local a,b = MPScanNearbyEnemiesCount()
        Text = Text .. "\n"..MPLanguage.UI_Mon_MeleeEnemies.." "..a.."  |cFF888888("..MPLanguage.UI_Mon_ActiveTargets..b..")|r"
    end

    if MPIsMoving() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_MovementState.." |cFF6dff7b"..MPLanguage.UI_Mon_Moving.."|r"
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_MovementState.." |cFF888888"..MPLanguage.UI_Mon_Stationary.."|r"
    end

    if MPGetGCD() < MPGCDMax() then
        Text = Text .. "\n"..MPLanguage.UI_Mon_GCD.." "..string.format("%.1f", MPGCDMax()-MPGetGCD())
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_GCD.." |cFF888888"..MPLanguage.UI_Mon_CooldownReady.."|r"
    end

    Text = Text .. "\n"..MPLanguage.UI_Mon_MainHand.." "..string.format("%.1f",  MPGetMainHandLeft())

    if englishClass == "DRUID" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_EnergyRestore.." "..string.format("%.1f", MPGetRestoredEnergy() )
    end

    Text = Text .. "\n"


    -- 职业参数

    if englishClass == "WARRIOR" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Warrior
    elseif englishClass == "ROGUE" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Rogue
    elseif englishClass == "MAGE" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Mage
    elseif englishClass == "HUNTER" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Hunter
    elseif englishClass == "PRIEST" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Priest
    elseif englishClass == "WARLOCK" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Warlock
    elseif englishClass == "DRUID" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Druid
    elseif englishClass == "PALADIN" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Paladin
    elseif englishClass == "SHAMAN" then
        Text = Text .. "\n"..MPLanguage.UI_Mon_Class..MPLanguage.UI_Shaman
    else
        Text = Text .. "\n"..MPLanguage.UI_Mon_UnknownClass
    end

    if MPPlayerLevel >= 60 then
        Text = Text .. "   "..MPLanguage.UI_Mon_Level ..MPPlayerLevel .. "\n"
    else
        Text = Text .. "   |cFFff5c36"..MPLanguage.UI_Mon_Level ..MPPlayerLevel .. " "..MPLanguage.UI_Mon_NotSupported.."|r\n"
    end

    local a,guid=UnitExists("target")


    -- 德鲁伊
    if englishClass == "DRUID" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 重整技能 检查
        if MPGetSpellID(MPLanguage.Reform)==0 then
            Text = Text .. "\n|cFFEE1111"..MPLanguage.UI_Mon_ReformNotLearned.."|r"
        end

        -- 血袭
        if MPGetRavageDot() then
            if MP_SuperWoW or MP_Nampower4 then
                local check = MPGetRavageCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.Ravage.."… "..string.format("%.1f", MPDruidRavageDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.Ravage.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRavageDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Ravage.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Ravage.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRavageDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 扫击
        if MPGetRakeDot() then
            if MP_SuperWoW or MP_Nampower4 then
                local check = MPGetRateCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.Rake.."… "..string.format("%.1f", MPDruidRakeDuration-(GetTime()-check[guid])).."  "..MPLanguage.UI_Mon_Tick.." "..string.format("%.1f",MPDruidRateJumpTimer-GetTime())
                else
                    Text = Text .. "\n"..MPLanguage.Rake.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRakeDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Rake.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r".."  "..MPLanguage.UI_Mon_Tick.." "..string.format("%.1f",MPDruidRateJumpTimer-GetTime())
            end
        else
            Text = Text .. "\n"..MPLanguage.Rake.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRakeDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 撕扯
        if MPGetRipDot() then
            if MP_SuperWoW or MP_Nampower4 then
                local check = MPGetRipCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.Rip.."… "..string.format("%.1f", MPDruidRipDuration-(GetTime()-check[guid])).."  "..MPLanguage.UI_Mon_Tick.." "..string.format("%.1f",MPDruidRipJumpTimer-GetTime())
                else
                    Text = Text .. "\n"..MPLanguage.Rip.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRipDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Rip.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r".."  "..MPLanguage.UI_Mon_Tick.." "..string.format("%.1f",MPDruidRipJumpTimer-GetTime())
            end
        else
            Text = Text .. "\n"..MPLanguage.Rip.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidRipDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 猛虎之怒
        if MPMHTimer then
            if GetTime()-MPMHTimer<18 then
                Text = Text .. "\n"..MPLanguage.TigerFury.."… "..string.format("%.1f", 18-(GetTime()-MPMHTimer) ).."  "..MPLanguage.UI_Mon_Tick.." "..string.format("%.1f",MPDruidTigerFuryTimer-GetTime())
            else
                Text = Text .. "\n"..MPLanguage.TigerFury.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.TigerFury.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 阿莎曼之怒 
        if MPGetDruidAshamane() then
            Text = Text .. "\n"..MPLanguage.AshamanesRage.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
        elseif MPDruidPrimalFury>0 then
            Text = Text .. "\n"..MPLanguage.AshamanesRage.."… |cFF6dff7b"..MPDruidPrimalFury.."|r"
        else
            Text = Text .. "\n"..MPLanguage.AshamanesRage.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end


        -- 月火
        if MPGetMoonfireDot() then
            if MP_SuperWoW or MP_Nampower4 then
                local check = MPGetMoonfireCheck()
                if check[guid] then 
                    Text = Text .. "\n"..MPLanguage.Moonfire.."… "..string.format("%.1f", MPDruidMoonfireDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.Moonfire.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidMoonfireDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Moonfire.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Moonfire.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidMoonfireDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 虫群
        if MPGetInsectSwarmDot() then
            if MP_SuperWoW or MP_Nampower4 then
                local check = MPGetInsectSwarmCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.InsectSwarm.."… "..string.format("%.1f", MPDruidInsectSwarmDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.InsectSwarm.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidInsectSwarmDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.InsectSwarm.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.InsectSwarm.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPDruidInsectSwarmDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 日蚀
        if MPGetSolar()>0.0 then
            Text = Text .. "\n"..MPLanguage.SolarEclipse.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r "..string.format("%.1f", MPGetSolar())
        else
            Text = Text .. "\n"..MPLanguage.SolarEclipse.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 月蚀
        if MPGetLunar()>0.0 then
            Text = Text .. "\n"..MPLanguage.LunarEclipse.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r "..string.format("%.1f", MPGetLunar())
        else
            Text = Text .. "\n"..MPLanguage.LunarEclipse.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end


    -- 圣骑士
    elseif englishClass == "PALADIN" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        if not MP_SuperWoW then

            -- 智慧圣印
            if MPSeal("智慧圣印") then
                Text = Text .. "\n"..MPLanguage.SealOfWisdom.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.SealOfWisdom.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 十字军圣印
            if MPSeal("十字军圣印") then
                Text = Text .. "\n"..MPLanguage.SealOfTheCrusader.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.SealOfTheCrusader.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 正义圣印
            if MPSeal("正义圣印") then
                Text = Text .. "\n"..MPLanguage.SealOfRighteousness.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.SealOfRighteousness.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 命令圣印
            if MPSeal("命令圣印") then
                Text = Text .. "\n"..MPLanguage.SealOfCommand.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.SealOfCommand.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 光明圣印
            if MPSeal("光明圣印") then
                Text = Text .. "\n"..MPLanguage.SealOfLight.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.SealOfLight.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

        else

            -- 智慧圣印
            if GetTime()-MPPaladinSealWisdomDuration<30 then
                Text = Text .. "\n"..MPLanguage.SealOfWisdom.."… "..string.format("%.1f", 30-(GetTime()-MPPaladinSealWisdomDuration))
            else
                Text = Text .. "\n"..MPLanguage.SealOfWisdom.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 十字军圣印
            if GetTime()-MPPaladinSealCrusaderDuration<30 then
                Text = Text .. "\n"..MPLanguage.SealOfTheCrusader.."… "..string.format("%.1f", 30-(GetTime()-MPPaladinSealCrusaderDuration))
            else
                Text = Text .. "\n"..MPLanguage.SealOfTheCrusader.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 正义圣印
            if GetTime()-MPPaladinSealJusticeDuration<30 then
                Text = Text .. "\n"..MPLanguage.SealOfRighteousness.."… "..string.format("%.1f", 30-(GetTime()-MPPaladinSealJusticeDuration))
            else
                Text = Text .. "\n"..MPLanguage.SealOfRighteousness.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 命令圣印
            if GetTime()-MPPaladinSealCommandDuration<30 then
                Text = Text .. "\n"..MPLanguage.SealOfCommand.."… "..string.format("%.1f", 30-(GetTime()-MPPaladinSealCommandDuration))
            else
                Text = Text .. "\n"..MPLanguage.SealOfCommand.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

            -- 光明圣印
            if GetTime()-MPPaladinSealRightDuration<30 then
                Text = Text .. "\n"..MPLanguage.SealOfLight.."… "..string.format("%.1f", 30-(GetTime()-MPPaladinSealRightDuration))
            else
                Text = Text .. "\n"..MPLanguage.SealOfLight.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end

        end

        -- 神圣威能
        if GetTime()-MPPaladinHolyStrikeDuration<20 then
            Text = Text .. "\n"..MPLanguage.UI_Mon_HolyPower.." "..string.format("%.1f", 20-(GetTime()-MPPaladinHolyStrikeDuration))
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_HolyPower.." |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 狂热
        if MPGetCrusaderStrike() then
            Text = Text .. "\n"..MPLanguage.Zealotry.."… ".." ("..MPPaladinFrenzyLayer..MPLanguage.UI_Mon_Layer..") "..string.format("%.1f", 30-(GetTime()-MPPaladinFrenzyDuration))
        else
            Text = Text .. "\n"..MPLanguage.Zealotry.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end



    -- 战士
    elseif englishClass == "WARRIOR" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 战斗怒吼
        if MPBuff("战斗怒吼") then
            Text = Text .. "\n"..MPLanguage.BattleShout.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            if MPGetBattleShout()>0 then
                Text = Text .. " ("..MPLanguage.UI_Mon_Estimate.." "..string.format("%.1f", MPGetBattleShout())..MPLanguage.UI_Mon_Seconds
            end
        else
            if MPGetBattleShout()>0 then
                Text = Text .. "\n"..MPLanguage.BattleShout.."… |cFF6dff7b"..MPLanguage.UI_Mon_GuessActive.."|r ("..MPLanguage.UI_Mon_Estimate.." "..string.format("%.1f", MPGetBattleShout())..MPLanguage.UI_Mon_Seconds
            else
                Text = Text .. "\n"..MPLanguage.BattleShout.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end
        end

        -- 压制
        if MPWarriorOverpower() then
            Text = Text .. "\n"..MPLanguage.Overpower.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
        else
            Text = Text .. "\n"..MPLanguage.Overpower.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 复仇
        if MPWarriorCounterAttack() then
            Text = Text .. "\n"..MPLanguage.Revenge.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
        else
            Text = Text .. "\n"..MPLanguage.Revenge.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 撕裂
        if MP_SuperWoW then
            if MPWarriorRend() and a then
                Text = Text .. "\n"..MPLanguage.Rend.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            else
                Text = Text .. "\n"..MPLanguage.Rend.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Rend.."… |cFF888888"..MPLanguage.UI_Mon_NoSuperWoW.."|r"
        end

        -- 英勇/顺劈阈值
        Text = Text .. "\n"..MPLanguage.UI_Mon_HeroicRageThresh.."… "..MPWarrorYYNQ





    -- 盗贼
    elseif englishClass == "ROGUE" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 突袭
        if MPRogueSurpriseStrike() then
            Text = Text .. "\n"..MPLanguage.SurpriseStrike.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
        else
            Text = Text .. "\n"..MPLanguage.SurpriseStrike.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 切割
        if MPGetRogueSlice() then
            if MP_SuperWoW then
                Text = Text .. "\n"..MPLanguage.SliceAndDice.."… "..string.format("%.1f", (MPRogueSliceDuration-(GetTime()-MPSliceTimer)))
            else
                Text = Text .. "\n"..MPLanguage.SliceAndDice.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.SliceAndDice.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 割裂
        if MPGetRogueBloody() then
            if MP_SuperWoW then
                Text = Text .. "\n"..MPLanguage.Rupture.."… "..string.format("%.1f", (MPRogueBloodyDuration-(GetTime()-MPBloodyTimer)))
            else
                Text = Text .. "\n"..MPLanguage.Rupture.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Rupture.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 毒伤
        if MPGetRogueEnvenom() then
            if MP_SuperWoW then
                Text = Text .. "\n"..MPLanguage.Envenom.."… "..string.format("%.1f", (MPRogueEnvenomDuration-(GetTime()-MPEnvenomTimer)))
            else
                Text = Text .. "\n"..MPLanguage.Envenom.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Envenom.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 破甲
        if MPGetExposeArmorDot() then
            if MP_SuperWoW then
                local check = MPGetExposeArmorCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.ExposeArmor.."… "..string.format("%.1f", (30-(GetTime()-check[guid])) ).." ("..MPExposeArmorCombo..MPLanguage.UI_Mon_Combo..")"
                end
            else
                Text = Text .. "\n"..MPLanguage.ExposeArmor.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.ExposeArmor.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end






    -- 萨满
    elseif englishClass == "SHAMAN" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        local x, y = GetPlayerMapPosition("player")

        -- 大地图腾
        if MPEarthTotem() then
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_EarthTotem.."… ("..MPEarthTotemName..") "..string.format("%.1f", (MPEarthTotemDuration-(GetTime()-MPEarthTotemTimer)))
            --Text = Text .. "\n大地图腾距离… "..string.format("%.1f",  MPCalculateTotemDistance(x,y, MPEarthTotemX, MPEarthTotemY))
        else
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_EarthTotem.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            --Text = Text .. "\n大地图腾距离… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 火焰图腾
        if MPFireTotem() then
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_FireTotem.."… ("..MPFireTotemName..") "..string.format("%.1f", (MPFireTotemDuration-(GetTime()-MPFireTotemTimer)))
            --Text = Text .. "\n火焰图腾距离… "..string.format("%.1f",  MPCalculateTotemDistance(x,y, MPFireTotemX, MPFireTotemY))
        else
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_FireTotem.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            --Text = Text .. "\n火焰图腾距离… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 水之图腾
        if MPWaterTotem() then
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_WaterTotem.."… ("..MPWaterTotemName..") "..string.format("%.1f", (MPWaterTotemDuration-(GetTime()-MPWaterTotemTimer)))
            --Text = Text .. "\n水之图腾距离… "..string.format("%.1f",  MPCalculateTotemDistance(x,y, MPWaterTotemX, MPWaterTotemY))
        else
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_WaterTotem.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            --Text = Text .. "\n水之图腾距离… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 空气图腾
        if MPAirTotem() then
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_AirTotem.."… ("..MPAirTotemName..") "..string.format("%.1f", (MPAirTotemDuration-(GetTime()-MPAirTotemTimer)))
            --Text = Text .. "\n空气图腾距离… "..string.format("%.1f",  MPCalculateTotemDistance(x,y, MPAirTotemX, MPAirTotemY))
        else
            Text = Text .. "\n"..MPLanguage.UI_Set_Sham_AirTotem.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
            --Text = Text .. "\n空气图腾距离… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 烈焰震击
        if MPGetFlameShockDot() then
            if MP_SuperWoW then
                local check = MPGetFlameShockCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.CL_FlameShockName.."… "..string.format("%.1f", MPShamanFlameShockDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.CL_FlameShockName.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.CL_FlameShockName.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.CL_FlameShockName.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end





    -- 术士
    elseif englishClass == "WARLOCK" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 痛苦诅咒
        if MPGetCurseAgonyDot() then
            if MP_SuperWoW then
                local check = MPGetCurseAgonyCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.CurseOfAgony.."… "..string.format("%.1f", MPCurseAgonyDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.CurseOfAgony.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPCurseAgonyDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.CurseOfAgony.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.CurseOfAgony.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPCurseAgonyDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 腐蚀术
        if MPGetCorruptionDot() then
            if MP_SuperWoW then
                local check = MPGetCorruptionCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.Corruption.."… "..string.format("%.1f", MPWarlockCorruptionDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.Corruption.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockCorruptionDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Corruption.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Corruption.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockCorruptionDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 生命虹吸
        if MPGetSiphonLifeDot() then
            if MP_SuperWoW then
                local check = MPGetSiphonLifeCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.SiphonLife.."… "..string.format("%.1f", MPWarlockSiphonLifeDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.SiphonLife.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockSiphonLifeDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.SiphonLife.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.SiphonLife.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockSiphonLifeDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 献祭
        if MPGetImmolateDot() then
            if MP_SuperWoW then
                local check = MPGetImmolateCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.Immolate.."… "..string.format("%.1f", MPWarlockImmolateDuration-(GetTime()-check[guid]))
                else
                    Text = Text .. "\n"..MPLanguage.Immolate.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockImmolateDuration..MPLanguage.UI_Mon_Seconds.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.Immolate.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.Immolate.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPWarlockImmolateDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end


        -- 引导技能
        if MPGetWarlockChanneled()>0 then
            Text = Text .. "\n"..MPLanguage.UI_Mon_Channeled.." |cFF6dff7b"..string.format("%.1f", MPGetWarlockChanneled()).."|r"
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_Channeled.." |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 释放潜力
        if MPGetPotential() then
            Text = Text .. "\n"..MPLanguage.UnleashPotential.."… "..MPGetPotentialLayer()..MPLanguage.UI_Mon_Layer.." |cFF6dff7b"..string.format("%.1f", 20-(GetTime()-MPGetPotentialTimer())).."|r"
        else
            Text = Text .. "\n"..MPLanguage.UnleashPotential.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 大诅咒
        Text = Text .. "\n"..MPLanguage.UI_Mon_Curse.." "
        local count = 0

        -- 鲁莽诅咒
        if MPBuff("鲁莽诅咒","target") then
            Text = Text .. "|cFF6dff7b"..MPLanguage.CurseOfRecklessness.."|r"
            count = 1
        end

        -- 元素诅咒
        if MPBuff("元素诅咒","target") then
            Text = Text .. "|cFF6dff7b"..MPLanguage.CurseOfTheElements.."|r"
            count = 1
        end

        -- 暗影诅咒
        if MPBuff("暗影诅咒","target") then
            Text = Text .. "|cFF6dff7b"..MPLanguage.CurseOfShadow.."|r"
            count = 1
        end

        -- 语言诅咒
        if MPBuff("语言诅咒","target") then
            Text = Text .. "|cFF6dff7b"..MPLanguage.CurseOfTongues.."|r"
            count = 1
        end

        if count==0 then
            Text = Text .. "|cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end



    -- 法师
    elseif englishClass == "MAGE" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 奥术涌动
        if MPGetMageArcaneSurge() then
            Text = Text .. "\n"..MPLanguage.ArcaneSurge.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
        else
            Text = Text .. "\n"..MPLanguage.ArcaneSurge.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 法术连击
        local fslj = 0
        fslj = MPGetBuffApplications("Interface\\Icons\\Ability_Mage_Firestarter")
        if fslj>0 then
            Text = Text .. "\n"..MPLanguage.SpellCombo.."… |cFF6dff7b"..fslj.."|r"
        else
            Text = Text .. "\n"..MPLanguage.SpellCombo.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 火焰易伤
        local yishang = 0
        yishang = MPGetDebuffApplications("Interface\\Icons\\Spell_Fire_SoulBurn", "target")
        if yishang>0 then
            if MP_SuperWoW then
                local check = MPGetScorchCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.FireVulnerability.."… |cFF6dff7b"..yishang.."|r ("..string.format("%.1f", 30-(GetTime()-check[guid]))..")"
                else
                    Text = Text .. "\n"..MPLanguage.FireVulnerability.."… |cFF6dff7b"..yishang.."|r"
                end
            else
                Text = Text .. "\n"..MPLanguage.FireVulnerability.."… |cFF6dff7b"..yishang.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.FireVulnerability.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 引导
        if GetMageArcaneMissiles()>0 then
            Text = Text .. "\n"..MPLanguage.UI_Mon_Channeled.." |cFF6dff7b"..string.format("%.1f", GetMageArcaneMissiles()).."|r"
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_Channeled.." |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end





    -- 牧师
    elseif englishClass == "PRIEST" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 暗言术：痛
        if MPGetPainDot() then
            if MP_SuperWoW then
                local check = MPGetPainCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.ShadowWordPain.."… "..string.format("%.1f", MPPainDuration-(GetTime()-check[guid]))
                end
            else
                Text = Text .. "\n"..MPLanguage.ShadowWordPain.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.ShadowWordPain.."… |cFF888888"..MPLanguage.UI_Mon_InactiveDuration..MPPainDuration..MPLanguage.UI_Mon_Seconds.."|r"
        end

        -- 精神鞭笞
        if MPGetPriestChanneled()>0 then
            Text = Text .. "\n"..MPLanguage.MindFlay.."… |cFF6dff7b"..string.format("%.1f", MPGetPriestChanneled()).."|r"
        else
            Text = Text .. "\n"..MPLanguage.MindFlay.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 鞭笞阶段
        if MPGetPriestMindFlayCount() > 0 then
            Text = Text .. "\n"..MPLanguage.UI_Mon_MindFlayPhase.." |cFF6dff7b"..MPGetPriestMindFlayCount().."|r"
        else
            Text = Text .. "\n"..MPLanguage.UI_Mon_MindFlayPhase.." |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 吸血鬼的拥抱
        if MPGetVampiricDot() then
            if MP_SuperWoW then
                local check = MPGetVampiricCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.VampiricEmbrace.."… "..string.format("%.1f", 60-(GetTime()-check[guid]))
                end
            else
                Text = Text .. "\n"..MPLanguage.VampiricEmbrace.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.VampiricEmbrace.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 神圣之火
        if MPGetHolyFireDot() then
            if MP_SuperWoW then
                Text = Text .. "\n"..MPLanguage.HolyFire.."… "..string.format("%.1f", MPGetHolyFireCheck(guid))
            else
                Text = Text .. "\n"..MPLanguage.HolyFire.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.HolyFire.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end



    -- 猎人
    elseif englishClass == "HUNTER" then
        Text = Text .. "\n|cFFAAAAAA - "..MPLanguage.UI_Mon_DynamicStatus.." - |r\n"

        -- 自动射击
        Text = Text .. "\n"..MPLanguage.AutoShot.."… "..string.format("%.1f", MPGetHunterShotLeft())..""

        -- 毒蛇钉刺
        if MPGetSerpentStingDot() then
            if MP_SuperWoW then
                local check = MPGetSerpentStingCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.SerpentSting.."… "..string.format("%.1f", 15-(GetTime()-check[guid]))
                end
            else
                Text = Text .. "\n"..MPLanguage.SerpentSting.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.SerpentSting.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 蝰蛇钉刺
        if MPGetViperStingDot() then
            if MP_SuperWoW then
                local check = MPGetViperStingCheck()
                if check[guid] then
                    Text = Text .. "\n"..MPLanguage.ViperSting.."… "..string.format("%.1f", 8-(GetTime()-check[guid]))
                end
            else
                Text = Text .. "\n"..MPLanguage.ViperSting.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r"
            end
        else
            Text = Text .. "\n"..MPLanguage.ViperSting.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end

        -- 割伤
        if MPGetHunterGoreAllow() then
            Text = Text .. "\n"..MPLanguage.Lacerate.."… |cFF6dff7b"..MPLanguage.UI_Mon_Active.."|r "..string.format("%.1f", MPHunterGoreTimer-GetTime())
        else
            Text = Text .. "\n"..MPLanguage.Lacerate.."… |cFF888888"..MPLanguage.UI_Mon_Inactive.."|r"
        end



    else
        Text = Text .. "\n|cFF888888"..MPLanguage.UI_Mon_NoMatchingMacro.."|r"
    end


    MPUIcontentText:SetText(Text)
end




