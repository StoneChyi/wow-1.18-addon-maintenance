-- YGB OT：pfUI 界面适配与配置、显示、计时修复。
YGB_OTAlarm = YGB_OTAlarm or {}

-- 样式内置主文件，兼容游戏缓存旧 TOC、不加载新增文件的情况。
-- 按需使用当前 pfUI 的背景、边框和字体；未启用 pfUI 时也保留平面样式。
local flat = {
    bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",
    tile=false,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}
}
local function Place(widget,parent,x,y,width,height)
    widget:ClearAllPoints();widget:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    if width then widget:SetWidth(width) end
    if height then widget:SetHeight(height) end
end
local function Font(region,size)
    local face = pfUI and pfUI.font_default
    if type(face) ~= "string" or face == "" then face = "Fonts\\ARIALN.TTF" end
    region:SetFont(face,size or 12,"OUTLINE")
end
local function Backdrop(frame,api)
    frame:SetBackdrop(flat)
    frame:SetBackdropColor(.06,.06,.06,.9)
    frame:SetBackdropBorderColor(.25,.25,.25,1)
    if api and api.CreateBackdrop then api.CreateBackdrop(frame,nil,true,.9) end
end
function YGB_OTAlarm:LayoutPanel()
    local p=self.panel
    if not p or p.ygbLayout then return end
    p:SetWidth(460);p:SetHeight(490);p:SetFrameStrata("DIALOG")
    if p.SetClampedToScreen then p:SetClampedToScreen(true) end
    Place(p.title,p,18,-14);Font(p.title,14);p.title:SetText("YGB OT 仇恨提醒")
    p.title:SetTextColor(1,.82,0)
    Place(p.version,p,340,-17);p.version:SetText("v2.1")
    Place(p.closeButton,p,427,-12,18,18)
    p.closeButton:SetText("×")
    for _,script in ipairs({"OnDragStart","OnDragStop","OnMouseDown","OnMouseUp"}) do p:SetScript(script,nil) end
    p.header=p.header or CreateFrame("Frame",nil,p)
    Place(p.header,p,0,0,410,34);p.header:EnableMouse(true);p.header:RegisterForDrag("LeftButton")
    p.header:SetScript("OnDragStart",function() p:StartMoving() end)
    p.header:SetScript("OnDragStop",function() p:StopMovingOrSizing() end)
    p.ygbSections=p.ygbSections or {}
    local function Section(title,y)
        local section=p.ygbSections[title] or {}
        p.ygbSections[title]=section
        local label=section.label or p:CreateFontString(nil,"OVERLAY")
        section.label=label
        Place(label,p,18,y);Font(label,12);label:SetTextColor(1,.82,0);label:SetText(title)
        local line=section.line or p:CreateTexture(nil,"ARTWORK")
        section.line=line
        Place(line,p,18,y-21,424,1);line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(.25,.25,.25,1)
    end
    Section("报警设置",-44);Section("显示设置",-221);Section("尺寸设置",-313)
    for _,tuple in ipairs({{"threshold",-79},{"barLength",-347},{"barHeight",-380},{"barScale",-413}}) do
        local key,y=tuple[1],tuple[2]
        Place(p[key.."Label"],p,18,y)
        Place(p[key.."Slider"],p,148,y+2,230,12)
        Place(p[key.."Value"],p,394,y)
        p[key.."Slider"]:EnableMouseWheel(true)
        local slider=p[key.."Slider"]
        slider:SetScript("OnMouseWheel",function()
            local low,high=slider:GetMinMaxValues()
            local step=key=="barScale" and .1 or 1
            slider:SetValue(math.max(low,math.min(high,slider:GetValue()+arg1*step)))
        end)
        for _,region in ipairs({slider:GetRegions()}) do
            if region:GetObjectType()=="FontString" then region:Hide() end
        end
    end
    p.sliderBackground:Hide();p.barLengthSliderBackground:Hide()
    p.barHeightSliderBackground:Hide();p.barScaleSliderBackground:Hide()
    for _,key in ipairs({"yell","sound"}) do
        local y=key=="yell" and -114 or -151
        Place(p[key.."Checkbox"],p,18,y,20,20)
        Place(p[key.."Label"],p,44,y-4)
        Place(p[key.."EditBox"],p,148,y+2,key=="yell" and 237 or 190,24)
    end
    Place(p.yellButton,p,398,-114,45,22);p.yellButton:SetText("保存")
    Place(p.soundButton,p,345,-151,45,22)
    Place(p.soundSetButton,p,398,-151,45,22);p.soundSetButton:SetText("保存")
    p.channelsLabel=p.channelsLabel or p:CreateFontString(nil,"OVERLAY")
    Font(p.channelsLabel,12)
    Place(p.channelsLabel,p,18,-191);p.channelsLabel:SetText("喊话频道")
    for i,key in ipairs({"say","yellChannel","guild","raid"}) do
        Place(p[key.."Checkbox"],p,148+(i-1)*75,-186,20,20)
        Place(p[key.."Label"],p,172+(i-1)*75,-190)
    end
    for _,tuple in ipairs({{"threatBar",18,-252},{"coverBar",164,-252},{"distanceBar",308,-252},
        {"lockThreatBar",18,-283},{"combatOnly",164,-283},{"debug",308,-283}}) do
        local key,x,y=unpack(tuple)
        Place(p[key.."Checkbox"],p,x,y,20,20)
        Place(p[key.."Label"],p,x+26,y-4)
    end
    p.combatOnlyLabel:SetText("仅战斗时显示")
    p.debugLabel:SetText("调试信息")
    p.guildLabel:SetText("公会")
    Place(p.resetPositionButton,p,260,-449,182,25)
    p.resetPositionButton:SetText("重置位置与尺寸")
    p.opacityButton=p.opacityButton or CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
    Place(p.opacityButton,p,18,-449,182,25);p.opacityButton:SetText("透明度设置")
    p.opacityButton:SetScript("OnClick",function() YGB_OTAlarm:ShowOpacitySettings() end)
    p:SetScript("OnShow",function() YGB_OTAlarm:ApplyStyle() end)
    -- 只有整套布局成功后才标记完成；中途失败时允许重试。
    p.ygbLayout=true
end
-- 独立透明度窗口，不改变主设置面板或监控条的位置。
function YGB_OTAlarm:ShowOpacitySettings()
    if not self.loaded then return end
    local panel=self.opacityPanel
    if not panel then
        panel=CreateFrame("Frame","YGB_OTAlarm_OpacitySettings",UIParent)
        self.opacityPanel=panel
        panel:SetWidth(350);panel:SetHeight(235);panel:SetFrameStrata("DIALOG")
        panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
        if panel.SetClampedToScreen then panel:SetClampedToScreen(true) end
        panel:SetMovable(true);panel:EnableMouse(true)
        Backdrop(panel,pfUI and pfUI.api)
        local header=CreateFrame("Frame",nil,panel)
        Place(header,panel,0,0,310,32);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
        header:SetScript("OnDragStart",function() panel:StartMoving() end)
        header:SetScript("OnDragStop",function() panel:StopMovingOrSizing() end)
        local title=panel:CreateFontString(nil,"OVERLAY")
        Font(title,13);Place(title,panel,16,-12);title:SetTextColor(1,.82,0);title:SetText("监控条 - 背景透明度设置")
        local close=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
        Place(close,panel,316,-10,18,18);close:SetText("×")
        if pfUI and pfUI.api and pfUI.api.SkinButton then pfUI.api.SkinButton(close) end
        close:SetScript("OnClick",function() panel:Hide() end)
        panel.sliders={}
        for i,choice in ipairs({{"threatBackgroundAlpha","仇恨条"},{"coverBackgroundAlpha","遮挡条"},{"distanceBackgroundAlpha","距离条"}}) do
            local key,label=choice[1],choice[2]
            local y=-58-(i-1)*47
            local text=panel:CreateFontString(nil,"OVERLAY")
            Font(text,12);Place(text,panel,16,y);text:SetText(label)
            local valueText=panel:CreateFontString(nil,"OVERLAY")
            Font(valueText,12);Place(valueText,panel,293,y);valueText:SetText("0%")
            local slider=CreateFrame("Slider","YGB_OTAlarm_"..key.."Slider",panel,"OptionsSliderTemplate")
            Place(slider,panel,97,y+1,184,12)
            slider:SetMinMaxValues(0,100);slider:SetValueStep(1);slider:SetOrientation("HORIZONTAL")
            for _,region in ipairs({slider:GetRegions()}) do
                if region:GetObjectType()=="FontString" then region:Hide() end
            end
            if pfUI and pfUI.api and pfUI.api.SkinSlider then pfUI.api.SkinSlider(slider) end
            slider:SetScript("OnValueChanged",function()
                local value=math.floor(slider:GetValue()+.5)
                valueText:SetText(value.."%")
                if panel.restoring then return end
                YGB_OTAlarm[key]=1-value/100
                YGB_OTAlarmDB[key]=YGB_OTAlarm[key]
                YGB_OTAlarm:ApplyBackgroundOpacity()
            end)
            slider:EnableMouseWheel(true)
            slider:SetScript("OnMouseWheel",function()
                slider:SetValue(math.max(0,math.min(100,slider:GetValue()+arg1)))
            end)
            panel.sliders[key]=slider
        end
        local hint=panel:CreateFontString(nil,"OVERLAY")
        Font(hint,11);Place(hint,panel,16,-205);hint:SetTextColor(.65,.65,.65)
        hint:SetText("0% 保持原样，100% 完全透明")
        panel:Hide()
    end
    panel.restoring=true
    for key,slider in pairs(panel.sliders) do slider:SetValue(math.floor((1-self[key])*100+.5)) end
    panel.restoring=false
    panel:Show()
end

function YGB_OTAlarm:ApplyStyle()
    local api=pfUI and pfUI.api
    local mode=api and api.CreateBackdrop and "pfUI" or "flat"
    if self.panel then
        self:LayoutPanel()
        local p=self.panel
        if p.ygbStyle~=mode then
            Backdrop(p,api)
            for _,region in ipairs({p:GetRegions()}) do
                if region:GetObjectType()=="FontString" and region~=p.title then Font(region,12) end
            end
            for _,key in ipairs({"closeButton","yellButton","soundButton","soundSetButton","resetPositionButton","opacityButton"}) do
                local button=p[key]
                if api and api.SkinButton then api.SkinButton(button) else Backdrop(button,nil) end
            end
            for _,key in ipairs({"yellCheckbox","soundCheckbox","sayCheckbox","yellChannelCheckbox","guildCheckbox","raidCheckbox",
                "threatBarCheckbox","coverBarCheckbox","distanceBarCheckbox","lockThreatBarCheckbox","combatOnlyCheckbox","debugCheckbox"}) do
                if api and api.SkinCheckbox then api.SkinCheckbox(p[key],20) end
            end
            for _,key in ipairs({"thresholdSlider","barLengthSlider","barHeightSlider","barScaleSlider"}) do
                if api and api.SkinSlider then api.SkinSlider(p[key]) else Backdrop(p[key],nil) end
            end
            for _,key in ipairs({"yellEditBox","soundEditBox"}) do
                Backdrop(p[key],api);Font(p[key],12);p[key]:SetTextInsets(6,6,0,0)
            end
            p.ygbStyle=mode
        end
    end
    for _,bar in ipairs({self.threatBar,self.secondThreatBar,self.distanceBar}) do
        if bar.ygbStyle~=mode then
            Backdrop(bar,api)
            bar.ygbBackdropColor={bar:GetBackdropColor()}
            for _,region in ipairs({bar:GetRegions()}) do
                if region:GetObjectType()=="FontString" then Font(region,11) end
            end
            bar.ygbStyle=mode
        end
    end
    local texture=pfUI and pfUI.media and pfUI.media["img:bar"] or "Interface\\Buttons\\WHITE8X8"
    if self.threatBar then self.threatBar.barTexture:SetTexture(texture) end
    if self.distanceBar then
        self.distanceBar.fillBar:SetTexture(texture)
        self.distanceBar.centerText:ClearAllPoints()
        self.distanceBar.centerText:SetPoint("CENTER",self.distanceBar,"CENTER",0,0)
        self.distanceBar.centerText2:ClearAllPoints()
        self.distanceBar.centerText2:SetPoint("TOP",self.distanceBar,"BOTTOM",0,-16)
        for _,tick in ipairs(self.distanceBar.scales) do Font(tick.text,9) end
    end
    self:ApplyBackgroundOpacity()
end

-- 定义全局backdrop变量，用于文本输入框等UI元素
local backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
}

-- SavedVariables 只在 ADDON_LOADED 后合并；明确保留 false 和 0。
local booleanDefaults = {
    showThreatBar=true, showCoverBar=true, showDistanceBar=false,
    lockThreatBar=false, combatOnly=false, debugMode=false,
    enableYell=false, enableSound=true
}
local function Enabled(value, default)
    if value == nil then return default end
    return value == true or value == 1
end
local function Number(value, default, low, high)
    value = tonumber(value)
    if not value or value ~= value then value = default end
    return math.max(low, math.min(high, value))
end
local function SoundPath(value)
    if type(value) ~= "string" or value == "" then value = "超过仇恨阈值" end
    value = string.gsub(value, "/", "\\")
    -- 旧版曾保存作者电脑的绝对路径；只保留游戏相对路径。
    local index = string.find(string.lower(value), "interface\\addons\\", 1, true)
    if index then value = string.sub(value, index) else
        value = "Interface\\AddOns\\YGB_OTAlarm\\"..string.gsub(value, ".*\\", "")
    end
    if not string.find(string.lower(value), "%.ogg$") then value = value..".ogg" end
    return value
end
function YGB_OTAlarm:LoadSettings()
    if type(YGB_OTAlarmDB) ~= "table" then YGB_OTAlarmDB = {} end
    local db = YGB_OTAlarmDB
    for field, default in pairs(booleanDefaults) do
        db[field] = Enabled(db[field], default)
        self[field] = db[field]
    end
    db.threshold = math.floor(Number(db.threshold, 80, 10, 100)+0.5)
    db.barLength = math.floor(Number(db.barLength, 200, 100, 500)+0.5)
    db.barHeight = math.floor(Number(db.barHeight, 20, 10, 50)+0.5)
    db.barScale = math.floor(Number(db.barScale, 1, 0.5, 2)*100+0.5)/100
    for _,field in ipairs({"threatBackgroundAlpha","coverBackgroundAlpha","distanceBackgroundAlpha"}) do
        db[field]=Number(db[field],1,0,1)
        self[field]=db[field]
    end
    db.yellMessage = type(db.yellMessage)=="string" and db.yellMessage or ""
    db.soundFile = SoundPath(db.soundFile)
    if type(db.channelSettings) ~= "table" then db.channelSettings = {} end
    for _, channel in ipairs({"SAY", "YELL", "GUILD", "RAID"}) do
        db.channelSettings[channel] = Enabled(db.channelSettings[channel], channel=="YELL")
    end
    local points = {TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,CENTER=true,
        TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    if type(db.threatBarPosition) ~= "table" then db.threatBarPosition = {} end
    local pos = db.threatBarPosition
    if not points[pos.point] then pos.point = "TOP" end
    if not points[pos.relativePoint] then pos.relativePoint = pos.point end
    if type(pos.relativeTo) ~= "string" or not _G[pos.relativeTo] then pos.relativeTo = "UIParent" end
    pos.x = Number(pos.x, 0, -10000, 10000)
    pos.y = Number(pos.y, -100, -10000, 10000)
    db.showDeadDistance = Enabled(db.showDeadDistance, false)
    db.pp = math.floor(Number(db.pp, 1, 1, 3)+0.5)
    for _, field in ipairs({"threshold","barLength","barHeight","barScale","yellMessage","soundFile","channelSettings"}) do
        self[field] = db[field]
    end
end
function YGB_OTAlarm:QueryUnitXP(command, a, b, c)
    if type(UnitXP) ~= "function" then return nil end
    local ok, result = pcall(UnitXP, command, a, b, c)
    if ok then return result end
    return nil
end
function YGB_OTAlarm:SetBarBackgroundColor(bar,r,g,b,a)
    bar.ygbBackgroundColor={r,g,b,a}
    bar.barBackground:SetVertexColor(r,g,b,a*(bar.ygbBackgroundOpacity or 1))
end
function YGB_OTAlarm:ApplyBackgroundOpacity()
    local bars={self.threatBar,self.secondThreatBar,self.distanceBar}
    local fields={"threatBackgroundAlpha","coverBackgroundAlpha","distanceBackgroundAlpha"}
    for i,bar in ipairs(bars) do
        local opacity=self[fields[i]] or 1
        bar.ygbBackgroundOpacity=opacity
        local backdropColor=bar.ygbBackdropColor
        if backdropColor then
            bar:SetBackdropColor(backdropColor[1],backdropColor[2],backdropColor[3],backdropColor[4]*opacity)
        end
        local color=bar.ygbBackgroundColor
        if color and bar.barBackground then
            bar.barBackground:SetVertexColor(color[1],color[2],color[3],color[4]*opacity)
        end
    end
end
function YGB_OTAlarm:UpdateVisibility()
    local visible = self.showThreatBar and (not self.combatOnly or UnitAffectingCombat("player"))
    local frames = {self.threatBar, self.secondThreatBar, self.distanceBar}
    local choices = {true, self.showCoverBar, self.showDistanceBar}
    for i, frame in ipairs(frames) do
        if visible and choices[i] then frame:Show() else frame:Hide() end
        frame:EnableMouse(not self.lockThreatBar)
    end
    if self.distanceBar and self.threatBar then
        self.distanceBar:ClearAllPoints()
        self.distanceBar:SetPoint("TOP", self.showCoverBar and self.secondThreatBar or self.threatBar, "BOTTOM", 0, -3)
    end
    self:ApplyBackgroundOpacity()
end
function YGB_OTAlarm:UpdateGeometry()
    if not self.threatBar then return end
    local width, height, scale = self.barLength, self.barHeight, self.barScale
    self.threatBar:SetWidth(width); self.threatBar:SetHeight(height); self.threatBar:SetScale(scale)
    self.secondThreatBar:SetWidth(width); self.secondThreatBar:SetHeight(math.max(16,height/2)); self.secondThreatBar:SetScale(scale)
    self.distanceBar:SetWidth(width); self.distanceBar:SetHeight(math.max(18,height/2+5)); self.distanceBar:SetScale(scale)
    local inside = math.max(0,width-10)
    self.threatBar.thresholdLine:ClearAllPoints()
    self.threatBar.thresholdLine:SetPoint("TOPLEFT",self.threatBar,"TOPLEFT",5+self.threshold/100*inside,-3)
    self.threatBar.thresholdLine:SetPoint("BOTTOMLEFT",self.threatBar,"BOTTOMLEFT",5+self.threshold/100*inside,3)
    self.threatBar.thresholdText:SetText(self.threshold.."%")
    self.threatBar.barTexture:SetWidth(math.min(100,self.displayPercent or 0)/100*inside)
    for i, tick in ipairs(self.distanceBar.scales or {}) do
        local value = ({0,8,30,35,41,45})[i]
        tick.line:ClearAllPoints(); tick.text:ClearAllPoints()
        tick.line:SetPoint("TOPLEFT",self.distanceBar,"TOPLEFT",5+value/45*inside,-3)
        tick.line:SetPoint("BOTTOMLEFT",self.distanceBar,"BOTTOMLEFT",5+value/45*inside,3)
        tick.text:SetPoint("TOPLEFT",self.distanceBar,"BOTTOMLEFT",5+value/45*inside-5,-2)
        if width>=160 or i==1 or i==6 then tick.text:Show() else tick.text:Hide() end
    end
end
function YGB_OTAlarm:SyncPanel()
    local panel = self.panel
    if not panel then return end
    local fields = {yellCheckbox="enableYell",soundCheckbox="enableSound",threatBarCheckbox="showThreatBar",
        coverBarCheckbox="showCoverBar",distanceBarCheckbox="showDistanceBar",lockThreatBarCheckbox="lockThreatBar",
        combatOnlyCheckbox="combatOnly",debugCheckbox="debugMode"}
    for widget, field in pairs(fields) do panel[widget]:SetChecked(self[field]) end
    for widget, channel in pairs({sayCheckbox="SAY",yellChannelCheckbox="YELL",guildCheckbox="GUILD",raidCheckbox="RAID"}) do
        panel[widget]:SetChecked(self.channelSettings[channel])
    end
    panel.yellEditBox:SetText(self.yellMessage)
    panel.soundEditBox:SetText(string.gsub(string.gsub(self.soundFile,".*\\",""),"%.ogg$",""))
    panel.thresholdSlider:SetValue(self.threshold)
    panel.barLengthSlider:SetValue(self.barLength)
    panel.barHeightSlider:SetValue(self.barHeight)
    panel.barScaleSlider:SetValue(self.barScale)
end
local function ThreatValue(entry)
    if type(entry)=="table" then entry=entry.perc end
    if type(entry)~="number" and type(entry)~="string" then return nil end
    local value=tonumber(entry)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return math.max(0,value)
end
function YGB_OTAlarm:ReadThreat()
    if not UnitExists("target") or type(TWT)~="table" or type(TWT.threats)~="table" then return nil end
    local player=UnitName("player")
    local mine=ThreatValue(TWT.threats[player])
    local top, topValue, second, secondValue=nil,-1,nil,0
    for name, entry in pairs(TWT.threats) do
        local value=ThreatValue(entry)
        if name~="-Pull Aggro at-" and value then
            if value>topValue or (value==topValue and name==player) then top,topValue=name,value end
            if name~=player and value>secondValue then second,secondValue=name,value end
        end
    end
    if not top then return nil end
    local _,guid=UnitExists("target")
    if type(UnitGUID)=="function" then guid=UnitGUID("target") or guid end
    return mine or 0,top==player,second,secondValue,guid or UnitName("target")
end
function YGB_OTAlarm:UpdateThreat()
    if not self.threatBar then return end
    local mine, highest, second, secondValue, key=self:ReadThreat()
    local text,percent="无目标",0
    if UnitExists("target") then
        local name=UnitName("target") or "目标"
        if mine==nil then text=name.." - 无仇恨数据"
        elseif highest then
            if second then text=second.." - "..string.format("%.0f",secondValue).."%";percent=secondValue
            else text=name.." - 无第二仇恨" end
        else text=name.." - "..string.format("%.0f",mine).."%";percent=mine end
    end
    self.displayPercent=percent
    local fraction=math.min(100,percent)/100
    local r,g=math.min(1,fraction*2),math.min(1,(1-fraction)*2)
    self.threatBar.barTexture:SetWidth(fraction*math.max(0,self.threatBar:GetWidth()-10))
    self.threatBar.barTexture:SetVertexColor(r,g,0,percent>0 and .9 or 0)
    self.threatBar.barText:SetText(text)
    self:ApplyBackgroundOpacity()
    if self.debugMode and GetTime()-(self.lastDebug or 0)>=2 then
        self.lastDebug=GetTime()
        DEFAULT_CHAT_FRAME:AddMessage("[YGB OT] "..text)
    end
    if mine==nil or not UnitAffectingCombat("player") or not key or mine<self.threshold then return end
    if UnitIsDead and UnitIsDead("target") then return end
    if UnitCanAttack and not UnitCanAttack("player","target") then return end
    if (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")) then return end
    if self.enableYell and self.yellMessage~="" and not self.yelledTargets[key] then
        local sent=false
        for _,channel in ipairs({"SAY","YELL","GUILD","RAID"}) do
            if self.channelSettings[channel] then SendChatMessage(self.yellMessage,channel);sent=true end
        end
        if sent then self.yelledTargets[key]=true end
    end
    if self.enableSound and self.soundFile~="" and not self.soundedTargets[key] then
        PlaySoundFile(self.soundFile)
        self.soundedTargets[key]=true
    end
end
-- 仇恨与报警同一份数据，固定 0.2 秒刷新，不创建/修改其他插件的缓存或姓名板。
local function CreateThreatChecker()
    local frame=CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:SetScript("OnEvent",function()
        if event=="PLAYER_REGEN_ENABLED" then
            YGB_OTAlarm.yelledTargets={}; YGB_OTAlarm.soundedTargets={}
        end
        YGB_OTAlarm:UpdateVisibility()
        -- 换目标后等所有插件完成同一事件处理再读取 TWT。
        frame.nextCheck=0
    end)
    frame:SetScript("OnUpdate",function()
        if not YGB_OTAlarm.loaded then return end
        local now=GetTime()
        if now<(frame.nextCheck or 0) then return end
        frame.nextCheck=now+.2
        YGB_OTAlarm:UpdateThreat()
    end)
    return frame
end

-- 基本常量定义
local PANEL_WIDTH = 400
local PANEL_HEIGHT = 425
local PANEL_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
}

-- 创建设置面板函数
function YGB_OTAlarm:CreateEmptyPanel()
    -- 只创建一次面板
    if not self.panel then
        if not self.loaded then return end

        -- 创建基本框架，没有任何额外元素
        self.panel = CreateFrame("Frame", "YGB_OTAlarm_EmptyFrame", UIParent)
        self.panel:SetWidth(PANEL_WIDTH)
        self.panel:SetHeight(PANEL_HEIGHT)
        self.panel:SetPoint("CENTER", UIParent, "CENTER")
        self.panel:SetBackdrop(PANEL_BACKDROP)
        self.panel:SetMovable(true)
        self.panel:EnableMouse(true)
        
        local panel = self.panel

        -- 添加标题文字
        self.panel.title = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.title:SetPoint("TOP", self.panel, "TOP", 0, -10)
        self.panel.title:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.title:SetTextColor(1, 1, 1, 1)
        self.panel.title:SetText("烟锅巴原创-OT报警器")
        
        -- 添加版本号显示
        self.panel.version = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.version:SetPoint("LEFT", self.panel.title, "RIGHT", 10, 0)
        self.panel.version:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.version:SetTextColor(1, 1, 1, 1)
        -- 直接使用硬编码的版本号，因为GetAddOnMetadata在WoW 1.12中可能不存在
        self.panel.version:SetText("v2.1 2026-02-16")
        
        -- 添加关闭按钮
        self.panel.closeButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.closeButton:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", -10, -10)
        self.panel.closeButton:SetWidth(20)
        self.panel.closeButton:SetHeight(20)
        self.panel.closeButton:SetText("X")
        self.panel.closeButton:SetScript("OnClick", function() 
            panel:Hide()
        end)
        
        -- 添加报警阈值滑动组件
        -- 报警阈值文字
        self.panel.thresholdLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.thresholdLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -40)
        self.panel.thresholdLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.thresholdLabel:SetTextColor(1, 1, 1, 1)
        self.panel.thresholdLabel:SetText("报警阈值：")
        
        -- 滑动条背景
        self.panel.sliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.sliderBackground:SetPoint("LEFT", self.panel.thresholdLabel, "RIGHT", 10, 0)
        self.panel.sliderBackground:SetWidth(160)
        self.panel.sliderBackground:SetHeight(16)
        self.panel.sliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.thresholdSlider = CreateFrame("Slider", "YGB_OTAlarm_thresholdSlider", self.panel, "OptionsSliderTemplate")
        self.panel.thresholdSlider:SetPoint("LEFT", self.panel.thresholdLabel, "RIGHT", 10, 0)
        self.panel.thresholdSlider:SetWidth(160)
        self.panel.thresholdSlider:SetMinMaxValues(10, 100)
        self.panel.thresholdSlider:SetValue(YGB_OTAlarmDB.threshold or 80)  -- 直接使用YGB_OTAlarmDB的值
        self.panel.thresholdSlider:SetValueStep(1)
        self.panel.thresholdSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.thresholdValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.thresholdValue:SetPoint("LEFT", self.panel.thresholdSlider, "RIGHT", 10, 0)
        self.panel.thresholdValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.thresholdValue:SetTextColor(1, 1, 1, 1)
        self.panel.thresholdValue:SetText((YGB_OTAlarmDB.threshold or 80) .. "%")  -- 直接使用YGB_OTAlarmDB的值
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.thresholdSlider:SetScript("OnValueChanged", function()
            local value = math.floor(this:GetValue()+0.5)
            panel.thresholdValue:SetText(value .. "%")
            YGB_OTAlarm.threshold = value
            YGB_OTAlarmDB.threshold = value
            YGB_OTAlarm:UpdateGeometry()
        end)
        
        -- 添加变身道具输入框

        
        -- 添加喊话内容输入框
        -- 喊话内容标签
        -- 喊话复选框
        self.panel.yellCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.yellCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -70)
        self.panel.yellCheckbox:SetWidth(20)
        self.panel.yellCheckbox:SetHeight(20)
        self.panel.yellCheckbox:SetChecked(YGB_OTAlarm.enableYell)
        self.panel.yellCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.enableYell = checked
            YGB_OTAlarmDB.enableYell = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 喊话内容标签
        self.panel.yellLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.yellLabel:SetPoint("LEFT", self.panel.yellCheckbox, "RIGHT", 5, 0)
        self.panel.yellLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.yellLabel:SetTextColor(1, 1, 1, 1)
        self.panel.yellLabel:SetText("喊话内容：")
        
        -- 喊话文本输入框
        self.panel.yellEditBox = CreateFrame("EditBox", nil, self.panel)
        self.panel.yellEditBox:SetPoint("LEFT", self.panel.yellLabel, "RIGHT", 5, 0)
        self.panel.yellEditBox:SetWidth(160)
        self.panel.yellEditBox:SetHeight(25)
        self.panel.yellEditBox:SetAutoFocus(false)
        self.panel.yellEditBox:SetMaxLetters(100)
        self.panel.yellEditBox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.yellEditBox:SetTextColor(1, 1, 1)
        self.panel.yellEditBox:SetTextInsets(5, 5, 5, 5)
        self.panel.yellEditBox:SetParent(self.panel)
        self.panel.yellEditBox:SetBackdrop(backdrop)
        self.panel.yellEditBox:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        self.panel.yellEditBox:SetBackdropBorderColor(1, 1, 1, 1)
        self.panel.yellEditBox:SetFrameLevel(self.panel:GetFrameLevel() + 1)
        self.panel.yellEditBox:SetScript("OnEscapePressed", function() self.panel.yellEditBox:ClearFocus() end)
        self.panel.yellEditBox:SetScript("OnEnterPressed", function() self.panel.yellEditBox:ClearFocus() end)
        self.panel.yellEditBox:SetText(YGB_OTAlarmDB.yellMessage or "")  -- 直接使用YGB_OTAlarmDB的值
        
        -- 喊话设置按钮
        self.panel.yellButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.yellButton:SetPoint("LEFT", self.panel.yellEditBox, "RIGHT", 5, 0)
        self.panel.yellButton:SetWidth(60)
        self.panel.yellButton:SetHeight(20)
        self.panel.yellButton:SetText("设置")
        self.panel.yellButton:SetScript("OnClick", function() 
            local yellMessage = this:GetParent().yellEditBox:GetText()
            if yellMessage then
                -- 保存设置到持久化数据
                YGB_OTAlarm.yellMessage = yellMessage
                YGB_OTAlarmDB.yellMessage = yellMessage
                local threshold = YGB_OTAlarm.threshold or 80
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00当仇恨阈值超过" .. threshold .. "%，则喊话：" .. (yellMessage ~= "" and yellMessage or "无") .. "！\124r")
            end
        end)
        
        -- 语音报警功能
        -- 语音报警复选框
        self.panel.soundCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.soundCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -95)
        self.panel.soundCheckbox:SetWidth(20)
        self.panel.soundCheckbox:SetHeight(20)
        self.panel.soundCheckbox:SetChecked(YGB_OTAlarm.enableSound)
        self.panel.soundCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.enableSound = checked
            YGB_OTAlarmDB.enableSound = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 语音报警标签
        self.panel.soundLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.soundLabel:SetPoint("LEFT", self.panel.soundCheckbox, "RIGHT", 5, 0)
        self.panel.soundLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.soundLabel:SetTextColor(1, 1, 1, 1)
        self.panel.soundLabel:SetText("语音报警：")
        
        -- 语音报警文本输入框
        self.panel.soundEditBox = CreateFrame("EditBox", nil, self.panel)
        self.panel.soundEditBox:SetPoint("LEFT", self.panel.soundLabel, "RIGHT", 5, 0)
        self.panel.soundEditBox:SetWidth(160)
        self.panel.soundEditBox:SetHeight(25)
        self.panel.soundEditBox:SetAutoFocus(false)
        self.panel.soundEditBox:SetMaxLetters(100)
        self.panel.soundEditBox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.soundEditBox:SetTextColor(1, 1, 1)
        self.panel.soundEditBox:SetTextInsets(5, 5, 5, 5)
        self.panel.soundEditBox:SetParent(self.panel)
        -- 从完整路径中提取文件名（去除路径和扩展名）
        local defaultSoundFile = "超过仇恨阈值"
        if YGB_OTAlarmDB.soundFile then
            -- 提取文件名（去除路径）
            local filename = string.gsub(YGB_OTAlarmDB.soundFile, ".*\\", "")
            -- 去除扩展名
            filename = string.gsub(filename, "%.ogg$", "")
            defaultSoundFile = filename
        end
        self.panel.soundEditBox:SetText(defaultSoundFile)
        -- 修改背景纹理
        self.panel.soundEditBox:SetBackdrop(backdrop)
        self.panel.soundEditBox:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        self.panel.soundEditBox:SetBackdropBorderColor(1, 1, 1, 1)
        self.panel.soundEditBox:SetFrameLevel(self.panel:GetFrameLevel() + 1)
        self.panel.soundEditBox:SetScript("OnEscapePressed", function() self.panel.soundEditBox:ClearFocus() end)
        self.panel.soundEditBox:SetScript("OnEnterPressed", function() self.panel.soundEditBox:ClearFocus() end)
        
        -- 语音报警测试按钮
        self.panel.soundButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.soundButton:SetPoint("LEFT", self.panel.soundEditBox, "RIGHT", 5, 0)
        self.panel.soundButton:SetWidth(60)
        self.panel.soundButton:SetHeight(20)
        self.panel.soundButton:SetText("测试")
        self.panel.soundButton:SetScript("OnClick", function() 
            local soundName = this:GetParent().soundEditBox:GetText()
            if soundName then
                -- 构建完整的文件路径
                local soundFile = SoundPath(soundName)
                -- 测试播放音频
                PlaySoundFile(soundFile)
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00测试播放音频文件：" .. soundFile .. "！\124r")
            end
        end)
        
        -- 语音报警设置按钮
        self.panel.soundSetButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.soundSetButton:SetPoint("LEFT", self.panel.soundButton, "RIGHT", 5, 0)
        self.panel.soundSetButton:SetWidth(60)
        self.panel.soundSetButton:SetHeight(20)
        self.panel.soundSetButton:SetText("设置")
        self.panel.soundSetButton:SetScript("OnClick", function() 
            local soundName = this:GetParent().soundEditBox:GetText()
            if soundName then
                -- 构建完整的文件路径
                local soundFile = SoundPath(soundName)
                -- 保存设置到持久化数据
                YGB_OTAlarm.soundFile = soundFile
                YGB_OTAlarmDB.soundFile = soundFile
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00语音报警文件已设置为：" .. soundFile .. "！\124r")
            end
        end)
        
        -- 频道选择复选框（移到语音报警复选框下方）
        -- 说频道复选框
        self.panel.sayCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.sayCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -125)
        self.panel.sayCheckbox:SetWidth(20)
        self.panel.sayCheckbox:SetHeight(20)
        self.panel.sayCheckbox:SetChecked(YGB_OTAlarm.channelSettings.SAY)
        self.panel.sayCheckbox:SetScript("OnClick", function()
            YGB_OTAlarmDB.channelSettings.SAY = this:GetChecked() and true or false
            YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
        end)
        
        -- 说频道标签
        self.panel.sayLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.sayLabel:SetPoint("LEFT", self.panel.sayCheckbox, "RIGHT", 5, 0)
        self.panel.sayLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.sayLabel:SetTextColor(1, 1, 1, 1)
        self.panel.sayLabel:SetText("说")
        
        -- 喊频道复选框
        self.panel.yellChannelCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.yellChannelCheckbox:SetPoint("LEFT", self.panel.sayLabel, "RIGHT", 20, 0)
        self.panel.yellChannelCheckbox:SetWidth(20)
        self.panel.yellChannelCheckbox:SetHeight(20)
        self.panel.yellChannelCheckbox:SetChecked(YGB_OTAlarm.channelSettings.YELL)
        self.panel.yellChannelCheckbox:SetScript("OnClick", function()
            YGB_OTAlarmDB.channelSettings.YELL = this:GetChecked() and true or false
            YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
        end)
        
        -- 喊频道标签
        self.panel.yellChannelLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.yellChannelLabel:SetPoint("LEFT", self.panel.yellChannelCheckbox, "RIGHT", 5, 0)
        self.panel.yellChannelLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.yellChannelLabel:SetTextColor(1, 1, 1, 1)
        self.panel.yellChannelLabel:SetText("喊")
        
        -- 工会频道复选框
        self.panel.guildCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.guildCheckbox:SetPoint("LEFT", self.panel.yellChannelLabel, "RIGHT", 20, 0)
        self.panel.guildCheckbox:SetWidth(20)
        self.panel.guildCheckbox:SetHeight(20)
        self.panel.guildCheckbox:SetChecked(YGB_OTAlarm.channelSettings.GUILD)
        self.panel.guildCheckbox:SetScript("OnClick", function()
            YGB_OTAlarmDB.channelSettings.GUILD = this:GetChecked() and true or false
            YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
        end)
        
        -- 工会频道标签
        self.panel.guildLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.guildLabel:SetPoint("LEFT", self.panel.guildCheckbox, "RIGHT", 5, 0)
        self.panel.guildLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.guildLabel:SetTextColor(1, 1, 1, 1)
        self.panel.guildLabel:SetText("工会")
        
        -- 团队频道复选框
        self.panel.raidCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.raidCheckbox:SetPoint("LEFT", self.panel.guildLabel, "RIGHT", 20, 0)
        self.panel.raidCheckbox:SetWidth(20)
        self.panel.raidCheckbox:SetHeight(20)
        self.panel.raidCheckbox:SetChecked(YGB_OTAlarm.channelSettings.RAID)
        self.panel.raidCheckbox:SetScript("OnClick", function()
            YGB_OTAlarmDB.channelSettings.RAID = this:GetChecked() and true or false
            YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
        end)
        
        -- 团队频道标签
        self.panel.raidLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.raidLabel:SetPoint("LEFT", self.panel.raidCheckbox, "RIGHT", 5, 0)
        self.panel.raidLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.raidLabel:SetTextColor(1, 1, 1, 1)
        self.panel.raidLabel:SetText("团队")

        -- 仇恨条复选框
        self.panel.threatBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.threatBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -155)
        self.panel.threatBarCheckbox:SetWidth(20)
        self.panel.threatBarCheckbox:SetHeight(20)
        self.panel.threatBarCheckbox:SetChecked(YGB_OTAlarm.showThreatBar)
        
        -- 仇恨条复选框标签
        self.panel.threatBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.threatBarLabel:SetPoint("LEFT", self.panel.threatBarCheckbox, "RIGHT", 5, 0)
        self.panel.threatBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.threatBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.threatBarLabel:SetText("显示仇恨条")
        
        -- 仇恨条复选框点击事件
        self.panel.threatBarCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.showThreatBar = checked
            YGB_OTAlarmDB.showThreatBar = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 显示遮挡条复选框
        self.panel.coverBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.coverBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -180)
        self.panel.coverBarCheckbox:SetWidth(20)
        self.panel.coverBarCheckbox:SetHeight(20)
        self.panel.coverBarCheckbox:SetChecked(YGB_OTAlarm.showCoverBar)
        
        -- 显示遮挡条复选框标签
        self.panel.coverBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.coverBarLabel:SetPoint("LEFT", self.panel.coverBarCheckbox, "RIGHT", 5, 0)
        self.panel.coverBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.coverBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.coverBarLabel:SetText("显示遮挡条")
        
        -- 显示遮挡条复选框点击事件
        self.panel.coverBarCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.showCoverBar = checked
            YGB_OTAlarmDB.showCoverBar = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 显示距离条复选框
        self.panel.distanceBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.distanceBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -205)
        self.panel.distanceBarCheckbox:SetWidth(20)
        self.panel.distanceBarCheckbox:SetHeight(20)
        self.panel.distanceBarCheckbox:SetChecked(YGB_OTAlarm.showDistanceBar)
        
        -- 显示距离条复选框标签
        self.panel.distanceBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.distanceBarLabel:SetPoint("LEFT", self.panel.distanceBarCheckbox, "RIGHT", 5, 0)
        self.panel.distanceBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.distanceBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.distanceBarLabel:SetText("显示距离条")
        
        -- 显示距离条复选框点击事件
        self.panel.distanceBarCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.showDistanceBar = checked
            YGB_OTAlarmDB.showDistanceBar = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 锁定仇恨条复选框
        self.panel.lockThreatBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.lockThreatBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -230)
        self.panel.lockThreatBarCheckbox:SetWidth(20)
        self.panel.lockThreatBarCheckbox:SetHeight(20)
        self.panel.lockThreatBarCheckbox:SetChecked(YGB_OTAlarm.lockThreatBar)
        
        -- 锁定仇恨条复选框标签
        self.panel.lockThreatBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.lockThreatBarLabel:SetPoint("LEFT", self.panel.lockThreatBarCheckbox, "RIGHT", 5, 0)
        self.panel.lockThreatBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.lockThreatBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.lockThreatBarLabel:SetText("锁定仇恨条")
        
        -- 锁定仇恨条复选框点击事件
        self.panel.lockThreatBarCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.lockThreatBar = checked
            YGB_OTAlarmDB.lockThreatBar = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 战斗显示复选框
        self.panel.combatOnlyCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.combatOnlyCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -255)
        self.panel.combatOnlyCheckbox:SetWidth(20)
        self.panel.combatOnlyCheckbox:SetHeight(20)
        self.panel.combatOnlyCheckbox:SetChecked(YGB_OTAlarm.combatOnly)
        
        -- 战斗显示复选框标签
        self.panel.combatOnlyLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.combatOnlyLabel:SetPoint("LEFT", self.panel.combatOnlyCheckbox, "RIGHT", 5, 0)
        self.panel.combatOnlyLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.combatOnlyLabel:SetTextColor(1, 1, 1, 1)
        self.panel.combatOnlyLabel:SetText("战斗显示|脱战隐藏")
        
        -- 战斗显示复选框点击事件
        self.panel.combatOnlyCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.combatOnly = checked
            YGB_OTAlarmDB.combatOnly = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 仇恨条长度滑动组件
        self.panel.barLengthLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barLengthLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -280)
        self.panel.barLengthLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barLengthLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barLengthLabel:SetText("仇恨条长度：")
        
        -- 滑动条背景
        self.panel.barLengthSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barLengthSliderBackground:SetPoint("LEFT", self.panel.barLengthLabel, "RIGHT", 10, 0)
        self.panel.barLengthSliderBackground:SetWidth(160)
        self.panel.barLengthSliderBackground:SetHeight(16)
        self.panel.barLengthSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barLengthSlider = CreateFrame("Slider", "YGB_OTAlarm_barLengthSlider", self.panel, "OptionsSliderTemplate")
        self.panel.barLengthSlider:SetPoint("LEFT", self.panel.barLengthLabel, "RIGHT", 10, 0)
        self.panel.barLengthSlider:SetWidth(160)
        self.panel.barLengthSlider:SetMinMaxValues(100, 500)
        self.panel.barLengthSlider:SetValue(YGB_OTAlarmDB.barLength or 200)
        self.panel.barLengthSlider:SetValueStep(1)
        self.panel.barLengthSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barLengthValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barLengthValue:SetPoint("LEFT", self.panel.barLengthSlider, "RIGHT", 10, 0)
        self.panel.barLengthValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barLengthValue:SetTextColor(1, 1, 1, 1)
        self.panel.barLengthValue:SetText((YGB_OTAlarmDB.barLength or 200) .. "px")
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barLengthSlider:SetScript("OnValueChanged", function()
            local value = math.floor(this:GetValue()+0.5)
            panel.barLengthValue:SetText(value .. "px")
            YGB_OTAlarm.barLength = value
            YGB_OTAlarmDB.barLength = value
            YGB_OTAlarm:UpdateGeometry()
        end)
        
        -- 仇恨条高度滑动组件
        self.panel.barHeightLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barHeightLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -305)
        self.panel.barHeightLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barHeightLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barHeightLabel:SetText("仇恨条高度：")
        
        -- 滑动条背景
        self.panel.barHeightSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barHeightSliderBackground:SetPoint("LEFT", self.panel.barHeightLabel, "RIGHT", 10, 0)
        self.panel.barHeightSliderBackground:SetWidth(160)
        self.panel.barHeightSliderBackground:SetHeight(16)
        self.panel.barHeightSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barHeightSlider = CreateFrame("Slider", "YGB_OTAlarm_barHeightSlider", self.panel, "OptionsSliderTemplate")
        self.panel.barHeightSlider:SetPoint("LEFT", self.panel.barHeightLabel, "RIGHT", 10, 0)
        self.panel.barHeightSlider:SetWidth(160)
        self.panel.barHeightSlider:SetMinMaxValues(10, 50)
        self.panel.barHeightSlider:SetValue(YGB_OTAlarmDB.barHeight or 20)
        self.panel.barHeightSlider:SetValueStep(1)
        self.panel.barHeightSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barHeightValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barHeightValue:SetPoint("LEFT", self.panel.barHeightSlider, "RIGHT", 10, 0)
        self.panel.barHeightValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barHeightValue:SetTextColor(1, 1, 1, 1)
        self.panel.barHeightValue:SetText((YGB_OTAlarmDB.barHeight or 20) .. "px")
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barHeightSlider:SetScript("OnValueChanged", function()
            local value = math.floor(this:GetValue()+0.5)
            panel.barHeightValue:SetText(value .. "px")
            YGB_OTAlarm.barHeight = value
            YGB_OTAlarmDB.barHeight = value
            YGB_OTAlarm:UpdateGeometry()
        end)
        
        -- 仇恨条缩放滑动组件
        self.panel.barScaleLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barScaleLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -330)
        self.panel.barScaleLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barScaleLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barScaleLabel:SetText("仇恨条缩放：")
        
        -- 滑动条背景
        self.panel.barScaleSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barScaleSliderBackground:SetPoint("LEFT", self.panel.barScaleLabel, "RIGHT", 10, 0)
        self.panel.barScaleSliderBackground:SetWidth(160)
        self.panel.barScaleSliderBackground:SetHeight(16)
        self.panel.barScaleSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barScaleSlider = CreateFrame("Slider", "YGB_OTAlarm_barScaleSlider", self.panel, "OptionsSliderTemplate")
        self.panel.barScaleSlider:SetPoint("LEFT", self.panel.barScaleLabel, "RIGHT", 10, 0)
        self.panel.barScaleSlider:SetWidth(160)
        self.panel.barScaleSlider:SetMinMaxValues(0.5, 2)
        self.panel.barScaleSlider:SetValue(YGB_OTAlarmDB.barScale or 1)
        self.panel.barScaleSlider:SetValueStep(0.1)
        self.panel.barScaleSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barScaleValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barScaleValue:SetPoint("LEFT", self.panel.barScaleSlider, "RIGHT", 10, 0)
        self.panel.barScaleValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barScaleValue:SetTextColor(1, 1, 1, 1)
        self.panel.barScaleValue:SetText(string.format("%.1f", YGB_OTAlarmDB.barScale or 1))
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barScaleSlider:SetScript("OnValueChanged", function()
            local value = math.floor(this:GetValue()*100+0.5)/100
            panel.barScaleValue:SetText(string.format("%.2f", value))
            YGB_OTAlarm.barScale = value
            YGB_OTAlarmDB.barScale = value
            YGB_OTAlarm:UpdateGeometry()
        end)
        
        -- 调试模式复选框
        self.panel.debugCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.debugCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -355)
        self.panel.debugCheckbox:SetWidth(20)
        self.panel.debugCheckbox:SetHeight(20)
        self.panel.debugCheckbox:SetChecked(YGB_OTAlarm.debugMode)
        
        -- 调试模式复选框标签
        self.panel.debugLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.debugLabel:SetPoint("LEFT", self.panel.debugCheckbox, "RIGHT", 5, 0)
        self.panel.debugLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.debugLabel:SetTextColor(1, 1, 1, 1)
        self.panel.debugLabel:SetText("显示调试信息")
        
        -- 调试模式复选框点击事件
        self.panel.debugCheckbox:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            YGB_OTAlarm.debugMode = checked
            YGB_OTAlarmDB.debugMode = checked
            YGB_OTAlarm:UpdateVisibility()
        end)
        
        -- 复位仇恨条位置按钮
        self.panel.resetPositionButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.resetPositionButton:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -380)
        self.panel.resetPositionButton:SetWidth(120)
        self.panel.resetPositionButton:SetHeight(25)
        self.panel.resetPositionButton:SetText("复位仇恨条位置")
        self.panel.resetPositionButton:SetScript("OnClick", function()
            YGB_OTAlarmDB.threatBarPosition = {point="TOP",relativeTo="UIParent",relativePoint="TOP",x=0,y=-100}
            YGB_OTAlarm.barLength=200;YGB_OTAlarm.barHeight=20;YGB_OTAlarm.barScale=1
            YGB_OTAlarmDB.barLength=200;YGB_OTAlarmDB.barHeight=20;YGB_OTAlarmDB.barScale=1
            local bar=YGB_OTAlarm.threatBar
            bar:ClearAllPoints();bar:SetPoint("TOP",UIParent,"TOP",0,-100)
            YGB_OTAlarm:SyncPanel()
            YGB_OTAlarm:UpdateGeometry()
            YGB_OTAlarm:UpdateVisibility()
        end)
        self:ApplyStyle()

        -- 默认隐藏
        self.panel:Hide()
    end
end

-- 命令处理函数 - 只处理显示命令
function YGB_OTAlarm_SlashCommand()
    -- 如果面板不存在，先创建
    if not YGB_OTAlarm.panel then
        YGB_OTAlarm:CreateEmptyPanel()
    end
    
    -- 显示面板
    if YGB_OTAlarm.panel then
        YGB_OTAlarm.panel:Show()
        DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00设置面板已显示\124r")
    end
end

-- 插件加载逻辑已直接内联到事件处理器中，不再需要单独的加载函数

-- 创建小地图按钮函数
function YGB_OTAlarm:CreateMinimapButton()
    -- 检查是否已经创建了小地图按钮
    if self.minimapButton then return end
    
    -- 创建小地图按钮框架
    local minimapButton = CreateFrame("Button", "YGB_OTAlarm_MinimapButton", Minimap)
    minimapButton:SetWidth(24)
    minimapButton:SetHeight(24)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetToplevel(true)
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    
    -- 设置按钮纹理
    minimapButton:SetNormalTexture("Interface\\AddOns\\YGB_OTAlarm\\images\\minimap_icon")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:SetPushedTexture("Interface\\AddOns\\YGB_OTAlarm\\images\\minimap_icon")
    minimapButton:GetPushedTexture():SetDesaturated(true)
    
    -- 设置按钮位置
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (15 * cos(0)), (15 * sin(0)) - 52)
    
    -- 保存按钮引用
    self.minimapButton = minimapButton
    
    -- 实现按钮点击事件
    minimapButton:SetScript("OnClick", function() 
        -- 切换插件配置面板显示/隐藏
        if not YGB_OTAlarm.panel then
            YGB_OTAlarm:CreateEmptyPanel()
        end
        if YGB_OTAlarm.panel then
            if YGB_OTAlarm.panel:IsVisible() then
                YGB_OTAlarm.panel:Hide()
            else
                YGB_OTAlarm.panel:Show()
            end
        end
    end)
    
    -- 实现按钮拖拽功能
    minimapButton:SetScript("OnDragStart", function() 
        this:StartMoving() 
    end)
    
    minimapButton:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing() 
        -- 保存按钮位置
        local x, y = this:GetLeft() - Minimap:GetLeft(), this:GetTop() - Minimap:GetTop()
        if not YGB_OTAlarmDB then YGB_OTAlarmDB = {} end
        if not YGB_OTAlarmDB.minimap then YGB_OTAlarmDB.minimap = {} end
        YGB_OTAlarmDB.minimap.x = x
        YGB_OTAlarmDB.minimap.y = y
    end)
    
    -- 实现鼠标悬停效果
    minimapButton:SetScript("OnEnter", function() 
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("YGB OT报警器")
        GameTooltip:AddLine("点击显示/隐藏设置面板", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("拖拽可移动按钮位置", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    minimapButton:SetScript("OnLeave", function() 
        GameTooltip:Hide()
    end)
    
    -- 尝试加载保存的按钮位置
    if YGB_OTAlarmDB and YGB_OTAlarmDB.minimap and YGB_OTAlarmDB.minimap.x and YGB_OTAlarmDB.minimap.y then
        minimapButton:ClearAllPoints()
        minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", YGB_OTAlarmDB.minimap.x, YGB_OTAlarmDB.minimap.y)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00YGB_OTAlarm: 小地图按钮已创建|r")
end

-- 直接在文件级别注册命令行 - 这种方式在WoW 1.12中更可靠
SLASH_YGBOTALARM1 = "/ygbot"
SlashCmdList["YGBOTALARM"] = YGB_OTAlarm_SlashCommand

-- 注册ADDON_LOADED事件，确保插件加载时初始化
local addonLoadFrame = CreateFrame("Frame")
addonLoadFrame:RegisterEvent("ADDON_LOADED")
addonLoadFrame:SetScript("OnEvent", function() 
    if event == "ADDON_LOADED" and arg1 == "YGB_OTAlarm" then
        -- 调用插件加载函数
        YGB_OTAlarm_OnLoad()
        -- 取消注册事件，只执行一次
        this:UnregisterEvent("ADDON_LOADED")
    end
end)

-- 进入世界时补齐皮肤加载顺序，并重新确认战斗显隐。
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" and YGB_OTAlarm.loaded then
        YGB_OTAlarm:CreateMinimapButton()
        YGB_OTAlarm:ApplyStyle()
        YGB_OTAlarm:UpdateGeometry()
        YGB_OTAlarm:UpdateVisibility()
    end
end)

local function CreateThreatBar()
    -- 打印调试信息，确认创建仇恨条时使用的参数
    if YGB_OTAlarm.debugMode then DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 创建仇恨条，使用的参数：长度=" .. (YGB_OTAlarmDB.barLength or 200) .. ", 高度=" .. (YGB_OTAlarmDB.barHeight or 20) .. ", 缩放=" .. (YGB_OTAlarmDB.barScale or 1) .. "\124r") end
    
    local threatBarFrame = CreateFrame("Frame", "YGB_OTAlarm_ThreatBar", UIParent)
    -- 使用保存的仇恨条长度或默认值
    local barLength = YGB_OTAlarmDB.barLength or 200
    threatBarFrame:SetWidth(barLength)
    if YGB_OTAlarm.debugMode then DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条宽度为：" .. barLength .. "\124r") end
    
    -- 使用保存的仇恨条高度或默认值
    local barHeight = YGB_OTAlarmDB.barHeight or 20
    threatBarFrame:SetHeight(barHeight)
    if YGB_OTAlarm.debugMode then DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条高度为：" .. barHeight .. "\124r") end
    
    -- 使用保存的仇恨条位置或默认值
    local pos = YGB_OTAlarmDB.threatBarPosition or {
        point = "TOP",
        relativeTo = "UIParent",
        relativePoint = "TOP",
        x = 0,
        y = -100
    }
    -- 确保relativeTo是有效的
    local relativeTo = pos.relativeTo
    if not relativeTo or relativeTo == "" then
        relativeTo = "UIParent"
    end
    -- 设置仇恨条位置
    threatBarFrame:SetPoint(pos.point, relativeTo, pos.relativePoint, pos.x, pos.y)
    if YGB_OTAlarm.debugMode then DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条位置为：" .. pos.point .. ", " .. relativeTo .. ", " .. pos.relativePoint .. ", " .. pos.x .. ", " .. pos.y .. "\124r") end
    
    -- 使用保存的仇恨条缩放或默认值
    local barScale = YGB_OTAlarmDB.barScale or 1
    -- 限制缩放值精度到小数点后2位
    barScale = math.floor(barScale * 100) / 100
    threatBarFrame:SetScale(barScale)
    if YGB_OTAlarm.debugMode then DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条缩放为：" .. barScale .. "\124r") end
    
    -- 设置背景
    local backdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8, -- 减小边框粗细 [烟锅巴：2026-02-12 12:30:00]
        insets = {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2
        }
    }
    threatBarFrame:SetBackdrop(backdrop)
    threatBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    
    -- 使其可拖动
    threatBarFrame:SetMovable(true)
    if threatBarFrame.SetClampedToScreen then threatBarFrame:SetClampedToScreen(true) end
    -- 根据保存的设置决定是否启用鼠标事件
    if YGB_OTAlarmDB.lockThreatBar then
        threatBarFrame:EnableMouse(false)
    else
        threatBarFrame:EnableMouse(true)
    end
    threatBarFrame:RegisterForDrag("LeftButton")
    
    local threatBar = threatBarFrame
    threatBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            threatBar.isMoving = true
        end
    end)
    threatBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
    end)
    
    -- 仇恨条背景
    local barBackground = threatBarFrame:CreateTexture(nil, "BACKGROUND")
    barBackground:SetPoint("TOPLEFT", threatBarFrame, "TOPLEFT", 5, -3)
    barBackground:SetPoint("BOTTOMRIGHT", threatBarFrame, "BOTTOMRIGHT", -5, 3)
    barBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    barBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 仇恨条
    local threatTexture = threatBarFrame:CreateTexture(nil, "ARTWORK")
    threatTexture:SetPoint("TOPLEFT", barBackground, "TOPLEFT")
    threatTexture:SetPoint("BOTTOMLEFT", barBackground, "BOTTOMLEFT")
    threatTexture:SetWidth(0)
    threatTexture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    threatTexture:SetVertexColor(0, 1, 0, 1) -- 初始为绿色
    
    -- 阈值刻度线
    local thresholdLine = threatBarFrame:CreateTexture(nil, "ARTWORK")
    local threshold = YGB_OTAlarm.threshold or 80
    local thresholdX = 5 + threshold / 100 * math.max(0, barLength - 10)
    thresholdLine:SetPoint("TOPLEFT", threatBarFrame, "TOPLEFT", thresholdX, -3)
    thresholdLine:SetPoint("BOTTOMLEFT", threatBarFrame, "BOTTOMLEFT", thresholdX, 3)
    thresholdLine:SetWidth(2) -- 加粗刻度线
    thresholdLine:SetTexture(1, 1, 0, 1) -- 黄色
    
    -- 阈值文本
    local thresholdText = threatBarFrame:CreateFontString(nil, "OVERLAY")
    thresholdText:SetPoint("BOTTOM", thresholdLine, "TOP", 0, 12) -- 上移12像素，显示在仇恨条上方
    thresholdText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE") -- 增大字体大小
    thresholdText:SetTextColor(1, 1, 0, 1) -- 黄色文字
    thresholdText:SetText(threshold .. "%")
    
    -- 仇恨值文本
    local threatText = threatBarFrame:CreateFontString(nil, "OVERLAY")
    threatText:SetPoint("CENTER", barBackground, "CENTER")
    threatText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    threatText:SetTextColor(1, 1, 1, 1)
    threatText:SetText("无目标")
    
    -- 存储引用
    threatBarFrame.barBackground = barBackground
    threatBarFrame.ygbBackgroundColor = {.1,.1,.1,.8}
    threatBarFrame.barTexture = threatTexture
    threatBarFrame.barText = threatText
    threatBarFrame.thresholdLine = thresholdLine
    threatBarFrame.thresholdText = thresholdText
    
    -- 默认隐藏
    threatBarFrame:Hide()
    
    -- 在仇恨条下方创建一个一模一样的框架 [烟锅巴：2026-02-12 12:30:01]
    local secondThreatBarFrame = CreateFrame("Frame", "YGB_OTAlarm_SecondThreatBar", UIParent)
    -- 使用相同的宽度，但高度缩小一半
    secondThreatBarFrame:SetWidth(barLength)
    secondThreatBarFrame:SetHeight(math.max(16, barHeight / 2))
    -- 设置位置在第一个框架下方，紧挨在一起
    secondThreatBarFrame:SetPoint("TOP", threatBarFrame, "BOTTOM", 0, -3)
    secondThreatBarFrame:SetScale(barScale)
    -- 使用相同的背景
    secondThreatBarFrame:SetBackdrop(backdrop)
    secondThreatBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    -- 使其可拖动（与第一个框架同步）
    secondThreatBarFrame:SetMovable(true)
    if YGB_OTAlarmDB.lockThreatBar then
        secondThreatBarFrame:EnableMouse(false)
    else
        secondThreatBarFrame:EnableMouse(true)
    end
    secondThreatBarFrame:RegisterForDrag("LeftButton")
    -- 第二个框架的拖动脚本（与第一个框架同步）
    local secondThreatBar = secondThreatBarFrame
    secondThreatBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            threatBar.isMoving = true
            secondThreatBar.isMoving = true
        end
    end)
    secondThreatBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        secondThreatBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        secondThreatBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
        -- 第二个框架的位置会自动跟随第一个框架
    end)
    
    -- 第二个框架的背景（简化，只保留基本背景）
    local secondBarBackground = secondThreatBarFrame:CreateTexture(nil, "BACKGROUND")
    secondBarBackground:SetPoint("TOPLEFT", secondThreatBarFrame, "TOPLEFT", 5, -3)
    secondBarBackground:SetPoint("BOTTOMRIGHT", secondThreatBarFrame, "BOTTOMRIGHT", -5, 3)
    secondBarBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    secondBarBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 第二个框架的中心文本
    local secondCenterText = secondThreatBarFrame:CreateFontString(nil, "OVERLAY")
    secondCenterText:SetPoint("CENTER", secondBarBackground, "CENTER")
    secondCenterText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    secondCenterText:SetTextColor(1, 1, 1, 1)
    secondCenterText:SetText("")
    
    -- 存储第二个框架的引用
    secondThreatBarFrame.barBackground = secondBarBackground
    secondThreatBarFrame.ygbBackgroundColor = {.1,.1,.1,.8}
    secondThreatBarFrame.centerText = secondCenterText
    
    -- 在遮挡条下方创建一个距离框架 [烟锅巴：2026-02-13 10:00:00]
    local distanceBarFrame = CreateFrame("Frame", "YGB_OTAlarm_DistanceBar", UIParent)
    -- 使用相同的宽度，高度增加5像素
    local distanceBarWidth = barLength
    distanceBarFrame:SetWidth(distanceBarWidth)
    distanceBarFrame:SetHeight(math.max(18, barHeight / 2 + 5))
    -- 设置位置在遮挡条下方，紧挨在一起
    distanceBarFrame:SetPoint("TOP", secondThreatBarFrame, "BOTTOM", 0, 0)
    distanceBarFrame:SetScale(barScale)
    -- 使用相同的背景
    distanceBarFrame:SetBackdrop(backdrop)
    distanceBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    -- 使其可拖动（与第一个框架同步）
    distanceBarFrame:SetMovable(true)
    if YGB_OTAlarmDB.lockThreatBar then
        distanceBarFrame:EnableMouse(false)
    else
        distanceBarFrame:EnableMouse(true)
    end
    distanceBarFrame:RegisterForDrag("LeftButton")
    -- 距离框架的拖动脚本（与第一个框架同步）
    local distanceBar = distanceBarFrame
    distanceBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            threatBar.isMoving = true
            secondThreatBar.isMoving = true
            distanceBar.isMoving = true
        end
    end)
    distanceBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        secondThreatBar:StopMovingOrSizing() 
        distanceBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        secondThreatBar.isMoving = false
        distanceBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
    end)
    
    -- 距离框架的背景（简化，只保留基本背景）
    local distanceBarBackground = distanceBarFrame:CreateTexture(nil, "BACKGROUND")
    distanceBarBackground:SetPoint("TOPLEFT", distanceBarFrame, "TOPLEFT", 5, -3)
    distanceBarBackground:SetPoint("BOTTOMRIGHT", distanceBarFrame, "BOTTOMRIGHT", -5, 3)
    distanceBarBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    distanceBarBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 距离填充条
    local distanceFillBar = distanceBarFrame:CreateTexture(nil, "ARTWORK")
    distanceFillBar:SetPoint("TOPLEFT", distanceBarFrame, "TOPLEFT", 5, -3)
    distanceFillBar:SetPoint("BOTTOMLEFT", distanceBarFrame, "BOTTOMLEFT", 5, 3)
    distanceFillBar:SetWidth(0)
    distanceFillBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    distanceFillBar:SetVertexColor(0, 0.8, 0, 0.8)
    
    -- 添加刻度
    local maxDistance = 45
    local scalePositions = {
        {0, "0", {1, 1, 1}},
        {8, "绿色", {0, 0.8, 0}},
        {30, "黄色", {0.8, 0.8, 0}},
        {35, "橙色", {0.8, 0.4, 0}},
        {41, "紫色", {0.8, 0, 0.8}},
        {45, "45", {1, 0, 0}}
    }
    
    distanceBarFrame.scales = {}
    for _, scaleInfo in ipairs(scalePositions) do
        local distance = scaleInfo[1]
        local label = scaleInfo[2]
        local color = scaleInfo[3]
        
        -- 计算刻度位置
        local scaleX = 5 + (distance / maxDistance) * (barLength - 10)
        
        -- 创建刻度线
        local scaleLine = distanceBarFrame:CreateTexture(nil, "OVERLAY")
        scaleLine:SetPoint("TOP", distanceBarFrame, "TOP", scaleX - (barLength / 2), -5)
        scaleLine:SetPoint("BOTTOM", distanceBarFrame, "BOTTOM", scaleX - (barLength / 2), 5)
        scaleLine:SetWidth(1)
        scaleLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        scaleLine:SetVertexColor(unpack(color))
        
        -- 创建刻度标签
        local scaleText = distanceBarFrame:CreateFontString(nil, "OVERLAY")
        scaleText:SetPoint("TOP", distanceBarFrame, "BOTTOM", scaleX - (barLength / 2), 0)
        scaleText:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        scaleText:SetTextColor(unpack(color))
        scaleText:SetText(distance)
        
        table.insert(distanceBarFrame.scales, {line = scaleLine, text = scaleText})
    end
    
    -- 距离框架的中心文本（显示在距离条下方）
    local distanceCenterText = distanceBarFrame:CreateFontString(nil, "OVERLAY")
    distanceCenterText:SetPoint("TOP", distanceBarFrame, "BOTTOM", 0, -5)
    distanceCenterText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    distanceCenterText:SetTextColor(1, 1, 1, 1)
    distanceCenterText:SetText("")
    
    -- 距离框架的第二个文本标签（用于显示猎人的人宠距离，显示在距离条下方）
    local distanceCenterText2 = distanceBarFrame:CreateFontString(nil, "OVERLAY")
    distanceCenterText2:SetPoint("TOP", distanceCenterText, "BOTTOM", 0, -2)
    distanceCenterText2:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
    distanceCenterText2:SetTextColor(1, 1, 1, 1)
    distanceCenterText2:SetText("")
    
    -- 存储距离框架的引用
    distanceBarFrame.barBackground = distanceBarBackground
    distanceBarFrame.ygbBackgroundColor = {.1,.1,.1,.8}
    distanceBarFrame.fillBar = distanceFillBar
    distanceBarFrame.centerText = distanceCenterText
    distanceBarFrame.centerText2 = distanceCenterText2
    distanceBarFrame.maxDistance = maxDistance
    
    -- 存储距离框架的全局引用
    YGB_OTAlarm.distanceBar = distanceBarFrame
    
    -- 默认隐藏距离框架
    distanceBarFrame:Hide()
    
    -- 视野检测相关变量
    local LOS_CHECK_INTERVAL = 0.3       -- 视野检测间隔（秒）[烟锅巴：2026-02-12 12:30:02]
    local losCheckTimer = 0               -- 视野检测计时器
    
    -- 距离检测相关变量
    local DISTANCE_CHECK_INTERVAL = 0.1   -- 距离检测间隔（秒）[烟锅巴：2026-02-13 10:00:01]
    local distanceCheckTimer = 0          -- 距离检测计时器
    
    -- 创建视野检测函数
    local function CheckLOS()
        if not UnitExists("target") then
            -- 没有目标，清空第二个框架
            if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.secondThreatBar.barBackground and YGB_OTAlarm.secondThreatBar.centerText then
                YGB_OTAlarm:SetBarBackgroundColor(YGB_OTAlarm.secondThreatBar,0.1, 0.1, 0.1, 0.8)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("")
            end
            return
        end
        
        -- 检查视野
        local hasLOS = YGB_OTAlarm:QueryUnitXP("inSight", "player", "target", "chains")
        
        -- 更新第二个框架的颜色和文字
        if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.secondThreatBar.barBackground and YGB_OTAlarm.secondThreatBar.centerText then
            if hasLOS == nil then
                YGB_OTAlarm:SetBarBackgroundColor(YGB_OTAlarm.secondThreatBar,.1,.1,.1,.6)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("视野未知")
            elseif hasLOS == true or hasLOS == 1 then
                -- 视野未遮挡，显示绿色和"未遮挡"
                YGB_OTAlarm:SetBarBackgroundColor(YGB_OTAlarm.secondThreatBar,.05, .2, .08, .65)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("未遮挡")
            else
                -- 视野被遮挡，显示红色和"被遮挡"
                YGB_OTAlarm:SetBarBackgroundColor(YGB_OTAlarm.secondThreatBar,.25, .05, .05, .65)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("被遮挡")
            end
        end
    end
    
    -- 创建距离检测函数 [烟锅巴：2026-02-13 10:00:02]
    local function CheckDistance()
        local unit = "player"
        local text = ""
        local r, g, b = 0.1, 0.1, 0.1
        local distance = 0
        local maxDistance = 45
        
        if not UnitExists("target") or UnitIsUnit(unit, "target") then
            text = ""
        else
            if (UnitHealth("target") or 0) == 0 and YGB_OTAlarmDB.showDeadDistance == false then
                text = ""
            else
                distance = tonumber(YGB_OTAlarm:QueryUnitXP("distanceBetween", unit, "target"))
                
                if not distance or distance ~= distance or distance < 0 or distance == math.huge then
                    distance = 0
                    text = ""
                else
                    if distance == 0 then
                        text = "0"
                    else
                        local fDistance = string.format("%.1f", distance)
                        text = fDistance
                    end
                    
                    -- 根据距离设置颜色
                    if distance < 8 then
                        r, g, b = 0, 0.8, 0 -- 绿色
                    elseif distance < 30 then
                        r, g, b = 0.8, 0.8, 0 -- 黄色
                    elseif distance < 35 then
                        r, g, b = 0.8, 0.4, 0 -- 橙色
                    elseif distance < 41 then
                        r, g, b = 0.8, 0, 0.8 -- 紫色
                    else
                        r, g, b = 0.8, 0, 0 -- 红色
                    end
                end
            end
        end
        
        -- 更新距离框架的颜色、文字和填充条
        if YGB_OTAlarm.distanceBar then
            -- 更新填充条长度
            if YGB_OTAlarm.distanceBar.fillBar then
                local barLength = YGB_OTAlarm.distanceBar:GetWidth() - 10
                -- 确保distance不为nil
                local safeDistance = distance or 0
                -- 当距离为0时，填充条宽度也应该为0
                local fillWidth = 0
                local displayR, displayG, displayB = r, g, b
                if safeDistance > 0 then
                    fillWidth = math.min((safeDistance / maxDistance) * barLength, barLength)
                else
                    -- 当距离为0时，使用默认颜色（灰色）
                    displayR, displayG, displayB = 0.1, 0.1, 0.1
                end
                YGB_OTAlarm.distanceBar.fillBar:SetWidth(fillWidth)
                YGB_OTAlarm.distanceBar.fillBar:SetVertexColor(displayR, displayG, displayB, 0.8)
            end
            
            -- 更新文本
            if YGB_OTAlarm.distanceBar.centerText then
                YGB_OTAlarm.distanceBar.centerText:SetText(text)
            end
        end
        
        -- 确保距离条宽度与仇恨条一致
        if YGB_OTAlarm.distanceBar and YGB_OTAlarm.threatBar then
            local threatBarWidth = YGB_OTAlarm.threatBar:GetWidth()
            local threatBarScale = YGB_OTAlarm.threatBar:GetScale()
            
            -- 确保宽度一致
            if YGB_OTAlarm.distanceBar:GetWidth() ~= threatBarWidth then
                YGB_OTAlarm.distanceBar:SetWidth(threatBarWidth)
                -- 同时更新遮挡条宽度，确保三者一致
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetWidth(threatBarWidth)
                end
            end
            
            -- 确保缩放比例一致
            if YGB_OTAlarm.distanceBar:GetScale() ~= threatBarScale then
                YGB_OTAlarm.distanceBar:SetScale(threatBarScale)
                -- 同时更新遮挡条缩放，确保三者一致
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetScale(threatBarScale)
                end
            end
        end
        
        -- 猎人的人宠距离显示
        local unitClass = UnitClass("player")
        if (unitClass == "猎人" or string.lower(unitClass) == "hunter") and YGB_OTAlarm.distanceBar and YGB_OTAlarm.distanceBar.centerText2 then
            if UnitExists("pet") and (YGB_OTAlarmDB.pp == 2 or (unit == "pet" and YGB_OTAlarmDB.pp == 3)) then
                if not (unit == "pet" and UnitIsUnit("target", "player")) and not (unit == "player" and UnitIsUnit("target", "pet")) then
                    local petDistance = tonumber(YGB_OTAlarm:QueryUnitXP("distanceBetween", "player", "pet"))
                    local ppDistance = petDistance and petDistance == petDistance and petDistance >= 0 and string.format("%.1f", petDistance)
                    if ppDistance then
                        YGB_OTAlarm.distanceBar.centerText2:SetText(ppDistance)
                        local defaultColor = YGB_OTAlarmDB.fontColorPp or {0, 1, 0}
                        YGB_OTAlarm.distanceBar.centerText2:SetTextColor(unpack(defaultColor))
                    else
                        YGB_OTAlarm.distanceBar.centerText2:SetText("")
                    end
                else
                    YGB_OTAlarm.distanceBar.centerText2:SetText("")
                end
            else
                YGB_OTAlarm.distanceBar.centerText2:SetText("")
            end
        end
    end
    
    -- GetTime 节流不依赖全局 arg1，兼容客户端计时补丁。
    threatBarFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if YGB_OTAlarm.showCoverBar and now-losCheckTimer >= LOS_CHECK_INTERVAL then
            losCheckTimer = now
            CheckLOS()
        end
        if YGB_OTAlarm.showDistanceBar and now-distanceCheckTimer >= DISTANCE_CHECK_INTERVAL then
            distanceCheckTimer = now
            CheckDistance()
        end
    end)

    -- 默认隐藏第二个框架
    secondThreatBarFrame:Hide()
    
    -- 存储第二个框架的引用到YGB_OTAlarm表中
    YGB_OTAlarm.secondThreatBar = secondThreatBarFrame
    
    -- 根据设置决定是否显示距离条
    if YGB_OTAlarm.showDistanceBar then
        YGB_OTAlarm.distanceBar:Show()
    else
        YGB_OTAlarm.distanceBar:Hide()
    end
    
    return threatBarFrame
end

-- SavedVariables 已就绪时才建立界面，避免先创建默认位置再覆盖角色数据。
function YGB_OTAlarm_OnLoad()
    if YGB_OTAlarm.loaded then return end
    YGB_OTAlarm:LoadSettings()
    YGB_OTAlarm.yelledTargets = {}
    YGB_OTAlarm.soundedTargets = {}
    YGB_OTAlarm.loaded = true
    YGB_OTAlarm.threatBar = CreateThreatBar()
    -- 先完成核心几何与显隐，外观步骤不能阻断首次刻度定位。
    YGB_OTAlarm:UpdateGeometry()
    YGB_OTAlarm:UpdateVisibility()
    YGB_OTAlarm:ApplyStyle()
    DEFAULT_CHAT_FRAME:AddMessage("|cffabd473YGB OT|r 已加载，输入 /ygbot 打开设置。")
end
YGB_OTAlarm.threatChecker = CreateThreatChecker()
