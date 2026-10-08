SAYSAPPED_CHANNEL = "SAY";
SAYSAPPED_MESSAGE = ">> "..UnitName("player").." << 中了奥术超载！注意远离！";

-- 创建提醒框体
local notificationFrame = CreateFrame("Frame", "ArcaneOverloadAlertNotificationFrame", UIParent)
notificationFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
notificationFrame:SetWidth(0.001)
notificationFrame:SetHeight(0.001)
notificationFrame.str = notificationFrame:CreateFontString(nil, "OVERLAY")
notificationFrame.str:SetFontObject("GameFontHighlightLarge")
local font, fontSize, fontFlags = GameFontNormalHuge:GetFont()
notificationFrame.str:SetFont(font, 100, fontFlags)
notificationFrame.str:SetTextColor(1, 0, 0)
notificationFrame.str:SetWidth(GetScreenWidth() / 2)
notificationFrame.str:SetJustifyH("CENTER")
notificationFrame.str:SetPoint("CENTER",notificationFrame,"CENTER", 0, 50)
-- notificationFrame:SetHeight(200)

function SaySapped_OnLoad()
    this:RegisterEvent("PLAYER_AURAS_CHANGED");
    this:RegisterEvent('PLAYER_ENTER_COMBAT')
    this.saidSap = false;
    this.cur_moon = nil
    this.lastSpeakTime = {}
end

notificationFrame:SetScript("OnUpdate", function()
    if notificationFrame.str.hideTime and GetTime() > notificationFrame.str.hideTime then
        notificationFrame.str:SetText("")
        notificationFrame.str.hideTime = nil
    end
end)

notificationFrame.showmsg = function(msg, duration)
    PlaySoundFile("Interface\\AddOns\\BigWigs\\Sounds\\RunAway.ogg")
    notificationFrame.str:SetText(msg)
    if duration then
        notificationFrame.str.hideTime = GetTime() + duration
    end
end
notificationFrame.hidemsg = function()
    notificationFrame.str:SetText("")
    notificationFrame.str.hideTime = nil
end

local tooltipMap = {
    ["鲜血虹吸"]={notify="你中了鲜血虹吸！",SAY=">> "..UnitName("player").." << 中了鲜血虹吸！法师小德立刻驱散！"},
    ["暴风雪"]={notify="暴风雪！快躲开！",},
    ["引导魔能光束"]={notify="奥术雨！快躲开！！！"},
    ["不稳定魔法"]={notify="地上光圈跑开，留一个人踩！"},
    ["奥术监牢"]={notify="奥术监牢，注意保命",SAY=">> "..UnitName("player").." << 被锁，救人"},
    ["奥术超载"]={notify="奥术超载！注意远离！",SAY=">> "..UnitName("player").." << 中了奥术超载！远离大团！"},
    ["麦迪文的腐化"]={notify="腐化！注意跑开！",SAY=">> "..UnitName("player").." << 中了腐化！注意跑开！"},
    ["魅惑之心"]={notify="心控！有徽记的自己解！"},
    ["黑暗屈从"]={notify="黑暗屈从，快找皇后！",SAY=">> "..UnitName("player").." << 中了黑暗屈从！"},
}

function SaySapped_OnEvent(event)

    if event == PLAYER_ENTER_COMBAT then
        this.cur_moon = nil
    end

    if event == PLAYER_AURAS_CHANGED then
        local i = 1;
        while UnitDebuff("player",i) do
            SaySappedTooltipTextLeft1:SetText("");
            SaySappedTooltip:SetUnitDebuff("player",i);
            local tooltipName = SaySappedTooltipTextLeft1:GetText();

            if tooltipMap[tooltipName] then
                for k, v in pairs(tooltipMap[tooltipName]) do
                    if k == 'notify' then
                        notificationFrame.showmsg(v, 3)
                    else
                        local lastTime = this.lastSpeakTime[tooltipName]
                        local currentTime = GetTime()
                        if not lastTime or currentTime - lastTime > 3 then
                            SendChatMessage(v, 'SAY')
                            this.lastSpeakTime[tooltipName] = currentTime
                        end
                    end
                end
            end

            if tooltipName == '红月' or tooltipName == '蓝月' then
                if not this.cur_moon then
                    this.cur_moon = tooltipName
                else
                    if this.cur_moon ~= tooltipName then
                        this.cur_moon = tooltipName
                        local msg = '我变成了'.. this.cur_moon .. ', 我要走到对面找到同类！'
                        local lastTime = this.lastSpeakTime[tooltipName]
                        local currentTime = GetTime()
                        if not lastTime or currentTime - lastTime > 3 then
                            SendChatMessage(msg, 'SAY')
                            this.lastSpeakTime[tooltipName] = currentTime
                        end
                        notificationFrame.showmsg(msg, 3)
                    end
                end
            end

            i = i+1;
        end
    end
end