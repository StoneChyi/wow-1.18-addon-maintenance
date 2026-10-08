-- 团队方案、施法条外观与个人小祝福。没有新增 OnUpdate 或周期团队扫描。
local rows, choices, presetButtons = {}, {}, {}
local selectedName, selectedClass, page = nil, nil, 1
local members = {}
local pending = {} -- 等待客户端 buff 更新的短暂去重；不写入职业祝福计时。
local smallIcons = {
    [0]="Spell_Holy_SealOfWisdom", [1]="Spell_Holy_FistOfJustice",
    [2]="Spell_Holy_SealOfSalvation", [3]="Spell_Holy_PrayerOfHealing02",
    [4]="Spell_Magic_MageArmor", [5]="Spell_Nature_LightningShield"
}
local shortNames = {[0]="智慧",[1]="力量",[2]="拯救",[3]="光明",[4]="王者",[5]="庇护"}
local presets = {
    {key="mightwisdom",label="力量回蓝",map={[0]=1,[1]=1,[2]=0,[3]=0,[4]=0,[5]=1,[6]=0,[7]=0,[8]=0,[9]=1}},
    {key="salvationwisdom",label="拯救回蓝",map={[0]=2,[1]=2,[2]=0,[3]=0,[4]=0,[5]=2,[6]=2,[7]=2,[8]=0,[9]=2}},
    {key="might",label="全力量",buff=1}, {key="wisdom",label="全智慧",buff=0},
    {key="salvation",label="全拯救",buff=2}, {key="kings",label="全王者",buff=4},
    {key="light",label="全光明",buff=3}, {key="sanctuary",label="全庇护",buff=5}
}

local function Settings()
    if type(PP_PerUser.personalBlessings) ~= "table" then PP_PerUser.personalBlessings = {} end
    local alpha = PP_PerUser.barBackgroundAlpha
    if type(alpha) ~= "number" or alpha ~= alpha then alpha = 0.5 end
    PP_PerUser.barBackgroundAlpha = math.max(0, math.min(1, alpha))
    PP_PerUser.barLocked = PP_PerUser.barLocked == 1 and 1 or 0
    PP_PerUser.alwaysBuffBar = PP_PerUser.alwaysBuffBar == 1 and 1 or 0
    PP_PerUser.soloLocked = PP_PerUser.soloLocked == 1 and 1 or 0
    PP_PerUser.chatfeedback = nil
    if PP_PerUser.screenfeedback == nil then PP_PerUser.screenfeedback = 1 end
    return PP_PerUser
end

-- 每次用户操作才读取实时名单。姓名是持久标识，raidN 仅在施法时解析。
local function Roster(classID)
    local list = {}
    local function Add(unit, pet)
        local name = UnitName(unit)
        if not name then return end
        local cid = PallyPower_GetClassID(UnitClass(unit))
        if classID == nil or cid == classID then
            if cid >= 0 then table.insert(list, {name=name,unit=unit,classID=cid}) end
        end
        if (classID == nil or classID == 9) and cid == 5 and UnitName(pet) then
            table.insert(list, {name=UnitName(pet),unit=pet,classID=9})
        end
    end
    local count = GetNumRaidMembers()
    if count > 0 then
        for i=1,count do Add("raid"..i,"raidpet"..i) end
    else
        Add("player","pet")
        for i=1,GetNumPartyMembers() do Add("party"..i,"partypet"..i) end
    end
    return list
end

function PallyPower_PersonalBlessing(classID, name)
    local all = PP_PerUser.personalBlessings
    local item = type(all) == "table" and all[name]
    if type(item) == "table" and item.classID == classID and type(item.buffID) == "number"
       and item.buffID >= 0 and item.buffID <= 5 and math.floor(item.buffID) == item.buffID then
        return item.buffID
    end
end

function PallyPower_SetPersonalBlessing(classID, name, buffID)
    if type(name) ~= "string" or name == "" or classID == 9 then return false end
    local saved = Settings()
    if buffID == nil then saved.personalBlessings[name] = nil
    else
        if type(buffID) ~= "number" or buffID < 0 or buffID > 5 or math.floor(buffID) ~= buffID then return false end
        saved.personalBlessings[name] = {classID=classID,buffID=buffID}
    end
    pending[name] = nil
    PallyPower_UpdateUI()
    return true
end

function PallyPower_ApplyPreset(key)
    local preset
    for _, item in ipairs(presets) do if item.key == key then preset = item break end end
    if not preset then return end
    local name = UnitName("player")
    local _, class = UnitClass("player")
    if class ~= "PALADIN" then return end
    local skills = AllPallys[name] or {}
    local assign = PallyPower_Assignments[name] or {}
    PallyPower_Assignments[name] = assign
    local seen, changed, missing = {}, 0, 0
    for _, member in ipairs(Roster()) do
        local cid = member.classID
        if not seen[cid] then
            seen[cid] = true
            local buff = preset.map and preset.map[cid] or preset.buff
            if buff ~= nil and skills[buff] then
                if assign[cid] ~= buff then
                    assign[cid] = buff
                    LastCast[buff..cid] = nil
                    changed = changed + 1
                    -- 沿用原插件的职业分配协议，由用户点击时同步。
                    PallyPower_SendMessage("ASSIGN "..name.." "..cid.." "..buff)
                end
            elseif buff ~= nil then missing = missing + 1 end
        end
    end
    PallyPower_UpdateUI()
    local message = "已设置我的方案："..preset.label
    if missing > 0 then message = message.."（"..missing.."个职业所需祝福未学会，保留原分配）" end
    PallyPower_ShowFeedback(message,0.5,1,0.5)
    return changed, missing
end

local function HasBlessing(unit, buffID)
    local small, greater = "Interface\\Icons\\"..smallIcons[buffID], BuffIcon[buffID]
    for i=1,32 do
        local texture = UnitBuff(unit,i,true)
        if not texture then break end
        if texture == small or texture == greater then return true end
    end
    return false
end

local function Eligible(unit)
    return UnitName(unit) and not UnitIsDeadOrGhost(unit)
        and (not UnitIsConnected or UnitIsConnected(unit))
end

-- 不清空玩家目标；先选定明确的友方单位，再直接施法并恢复原目标。
-- 小祝福单独计时，不能把职业大祝福的 30 分钟倒计时重置为 10 分钟。
function PallyPower_CastPersonalBlessing(classID, name, buffID)
    if buffID == nil then
        buffID = PallyPower_PersonalBlessing(classID,name)
        local assign = PallyPower_Assignments[UnitName("player")]
        if buffID == nil and assign then buffID = assign[classID] end
    end
    if not smallIcons[buffID] then return false end
    local skills = AllPallys[UnitName("player")]
    local skill = skills and skills[PallyPower_LesserBlessingMap[buffID]]
    if not skill or not skill.id then
        PallyPower_ShowFeedback("尚未学会该小祝福："..shortNames[buffID],1,0.2,0.2)
        return false
    end
    local unit
    for _, member in ipairs(Roster(classID)) do if member.name == name then unit = member.unit break end end
    if not unit or not Eligible(unit) then
        PallyPower_ShowFeedback("团员不在当前队伍、已离线或已死亡："..name,1,0.2,0.2)
        return false
    end
    local hadTarget = UnitExists("target")
    local sameTarget = hadTarget and UnitIsUnit("target",unit)
    if not sameTarget then TargetUnit(unit) end
    CastSpell(skill.id,BOOKTYPE_SPELL)
    -- 正常会直接施放；若仍有法术指针，再尝试明确的单位。
    if SpellIsTargeting() then
        if SpellCanTargetUnit(unit) then SpellTargetUnit(unit) else SpellStopTargeting() end
    end
    if not sameTarget then
        if hadTarget then TargetLastTarget() else ClearTarget() end
    end
    pending[name] = {buffID=buffID,expires=GetTime()+1.5}
    PP_NextScan = math.min(PP_NextScan or 1,1)
    PallyPower_ShowFeedback("尝试给 "..name.." 施放小"..shortNames[buffID].."祝福",0.5,1,0.5)
    return true
end

local function Pending(name,buffID)
    local value = pending[name]
    if value and value.expires <= GetTime() then pending[name] = nil return false end
    return value and value.buffID == buffID
end

local function CastClassSmall(btn)
    local list = Roster(btn.classID)
    -- 个人不同祝福优先；普通职业小祝福不得覆盖已设置的个人例外。
    for _, member in ipairs(list) do
        local buff = PallyPower_PersonalBlessing(btn.classID,member.name)
        if buff ~= nil and Eligible(member.unit) and not HasBlessing(member.unit,buff) and not Pending(member.name,buff) then
            if PallyPower_CastPersonalBlessing(btn.classID,member.name,buff) then return end
        end
    end
    for _, member in ipairs(list) do
        if PallyPower_PersonalBlessing(btn.classID,member.name) == nil and Eligible(member.unit)
           and not HasBlessing(member.unit,btn.buffID) and not Pending(member.name,btn.buffID) then
            if PallyPower_CastPersonalBlessing(btn.classID,member.name,btn.buffID) then return end
        end
    end
    PallyPower_ShowFeedback("该职业的小祝福已齐全，或当前没有可补的团员",0.8,0.8,0.3)
end

-- 团队施法框按 UIParent 坐标存档；固定左上角避免人数改变高度时偏移。
-- 与单人宝珠分别保存，只在用户操作和登录/退出事件中处理位置。
local barPositionRestored=false
local function ValidCoordinate(value)
    return type(value)=="number" and value==value and math.abs(value)<10000000000
end
local function BuffBarPosition()
    local bar=PallyPowerBuffBar
    local x,y=bar:GetLeft(),bar:GetTop()
    if not ValidCoordinate(x) or not ValidCoordinate(y) then return end
    local ratio=bar:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*ratio,y*ratio
end
local function SetBuffBarPosition(x,y)
    local bar=PallyPowerBuffBar
    local ratio=UIParent:GetEffectiveScale()/bar:GetEffectiveScale()
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x*ratio,y*ratio)
end
local function SaveBuffBarPosition()
    if not barPositionRestored then return end
    local x,y=BuffBarPosition()
    if x==nil then return end
    SetBuffBarPosition(x,y)
    local saved=Settings()
    saved.barPositionX=x; saved.barPositionY=y
end
local function RestoreBuffBarPosition()
    if barPositionRestored then return end
    local saved=Settings()
    if ValidCoordinate(saved.scalebar) and saved.scalebar>0 then
        PallyPowerBuffBar:SetScale(saved.scalebar)
    end
    if ValidCoordinate(saved.barPositionX) and ValidCoordinate(saved.barPositionY) then
        SetBuffBarPosition(saved.barPositionX,saved.barPositionY)
    end
    barPositionRestored=true
end

function PallyPower_ApplyBuffBarAppearance()
    local saved = Settings()
    local bar = PallyPowerBuffBar
    if bar.GetBackdrop and not bar:GetBackdrop() then
        bar:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    end
    local locked = saved.barLocked == 1
    bar.isLocked = saved.barLocked
    bar:SetMovable(not locked)
    if locked then
        local wasMoving=bar.isMoving
        bar:StopMovingOrSizing(); bar.isMoving = false
        if wasMoving then SaveBuffBarPosition() end
        if PallyPower.FrameToScale == bar then
            PallyPower_ScalingFrame:Hide(); PallyPower.FrameToScale = nil
        end
    end
    bar:SetBackdropColor(0,0,0,saved.barBackgroundAlpha)
    if bar.backdrop_shadow then bar.backdrop_shadow:SetAlpha(saved.barBackgroundAlpha) end
    for i=1,10 do
        local button = getglobal("PallyPowerBuffBarBuff"..i)
        if button then
            button:SetBackdropColor(button.ppStatusR or 0,button.ppStatusG or 0,button.ppStatusB or 0,saved.barBackgroundAlpha)
        end
    end
    local grip = getglobal("PallyPowerBuffBarResizeButton")
    if grip then grip:EnableMouse(not locked); if locked then grip:Hide() else grip:Show() end end
end

-- 使用 UIParent 坐标保存宝珠位置，兼容界面比例和宝珠自身缩放。
-- 只在拖动结束、缩放、隐藏或退出时保存；不增加逐帧工作。
local soloPositionRestored = false
local function SoloPosition()
    local bar=PallyPowerSoloBar
    if not bar then return end
    local x,y=bar:GetLeft(),bar:GetTop()
    if not ValidCoordinate(x) or not ValidCoordinate(y) then return end
    local ratio=bar:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*ratio,y*ratio
end
local function SaveSoloPosition()
    if not soloPositionRestored then return end
    local x,y=SoloPosition()
    if x==nil then return end
    local saved=Settings()
    saved.soloPositionX=x; saved.soloPositionY=y
end
local function SetSoloPosition(x,y)
    local bar=PallyPowerSoloBar
    local ratio=UIParent:GetEffectiveScale()/bar:GetEffectiveScale()
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x*ratio,y*ratio)
end
local function RestoreSoloPosition()
    if soloPositionRestored or not PallyPowerSoloBar then return end
    local saved=Settings()
    if ValidCoordinate(saved.scalesolo) and saved.scalesolo>0 then
        PallyPowerSoloBar:SetScale(saved.scalesolo)
    end
    if ValidCoordinate(saved.soloPositionX) and ValidCoordinate(saved.soloPositionY) then
        SetSoloPosition(saved.soloPositionX,saved.soloPositionY)
    end
    soloPositionRestored=true
end
local soloOldMouseUp=PallyPowerSoloBar_MouseUp
function PallyPowerSoloBar_MouseUp(button)
    local wasMoving=PallyPowerSoloBar.isMoving
    soloOldMouseUp(button)
    if wasMoving then SaveSoloPosition() end
end
local soloOldHide=PallyPowerSoloBar:GetScript("OnHide")
PallyPowerSoloBar:SetScript("OnHide",function()
    PallyPowerSoloBar:StopMovingOrSizing(); PallyPowerSoloBar.isMoving=false
    SaveSoloPosition()
    if soloOldHide then soloOldHide() end
end)

function PallyPower_ApplySoloLock()
    local saved=Settings()
    local bar=PallyPowerSoloBar
    if not bar then return end
    local locked=saved.soloLocked==1
    bar.isLocked=saved.soloLocked
    bar:SetMovable(not locked)
    if locked then
        local wasMoving=bar.isMoving
        bar:StopMovingOrSizing(); bar.isMoving=false
        if wasMoving then SaveSoloPosition() end
        if PallyPower.FrameToScale==bar then
            PallyPower_ScalingFrame:Hide(); PallyPower.FrameToScale=nil
        end
    end
end
local soloOldWheel=PallyPowerSoloBar_OnMouseWheel
function PallyPowerSoloBar_OnMouseWheel(delta)
    if PP_PerUser.soloLocked==1 then return end
    soloOldWheel(delta)
end

local function Label(parent,text,x,y)
    local font = parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    font:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y); font:SetText(text)
    return font
end
local function Button(parent,name,text,x,y,width,callback)
    local b = CreateFrame("Button",name,parent,"UIPanelButtonTemplate")
    b:SetWidth(width); b:SetHeight(24); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(text); b:SetScript("OnClick",callback)
    return b
end

-- 二级团员菜单与三级小祝福菜单。仅在点击或名单变更时更新。
local function Menu(name,width)
    local frame=CreateFrame("Frame",name,UIParent)
    frame:SetWidth(width); frame:SetScale(1); frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=8,insets={left=3,right=3,top=3,bottom=3}})
    frame:SetBackdropColor(0.05,0.05,0.1,0.95); frame:Hide()
    return frame
end
local memberMenu=Menu("PallyPowerMemberMenu",205)
local blessingMenu=Menu("PallyPowerBlessingMenu",230)
memberMenu:SetFrameLevel(100); blessingMenu:SetFrameLevel(101)
local memberTitle=Label(memberMenu,"",9,-8)
local blessingTitle=Label(blessingMenu,"",9,-8)
local memberAnchor
local function PlaceMenu(menu,anchor)
    local base=UIParent:GetEffectiveScale()
    local ratio=anchor:GetEffectiveScale()/base
    local scale=menu:GetEffectiveScale()/base
    local width,height=menu:GetWidth()*scale,menu:GetHeight()*scale
    local screenWidth,screenHeight=UIParent:GetWidth(),UIParent:GetHeight()
    local x=(anchor:GetRight() or 0)*ratio+4
    local y=(anchor:GetTop() or screenHeight)*ratio
    if x+width > screenWidth-4 then x=(anchor:GetLeft() or 0)*ratio-width-4 end
    x=math.max(4,math.min(x,screenWidth-width-4))
    y=math.max(height+4,math.min(y,screenHeight-4))
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
end
function PallyPower_ClosePersonalMenus()
    blessingMenu:Hide(); memberMenu:Hide()
    selectedName=nil; selectedClass=nil; memberAnchor=nil
end
memberMenu:SetScript("OnHide",function() blessingMenu:Hide() end)
local close=CreateFrame("Button",nil,memberMenu,"UIPanelCloseButton")
close:SetWidth(24); close:SetHeight(24); close:SetPoint("TOPRIGHT",memberMenu,"TOPRIGHT",0,0)
close:SetScript("OnClick",PallyPower_ClosePersonalMenus)

local function MenuButton(parent,name,y,width)
    local b=CreateFrame("Button",name,parent)
    b:SetWidth(width); b:SetHeight(24); b:SetPoint("TOPLEFT",parent,"TOPLEFT",7,y)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b.text=Label(b,"",5,-6)
    return b
end
local function OpenBlessings(row)
    local name=selectedName
    blessingTitle:SetText(name.." - 小祝福")
    local chosen=PallyPower_PersonalBlessing(selectedClass,name)
    local skills=AllPallys[UnitName("player")] or {}
    for id,b in pairs(choices) do
        local learned=skills[PallyPower_LesserBlessingMap[id]]
        b.text:SetText("小"..shortNames[id].."祝福"..(learned and "" or "（未学会）"))
        local brightness=learned and (chosen==id and 1 or 0.6) or 0.25
        b.icon:SetVertexColor(brightness,brightness,brightness)
        b.text:SetTextColor(learned and 1 or 0.5,learned and 1 or 0.5,learned and 1 or 0.5)
    end
    PlaceMenu(blessingMenu,row); blessingMenu:Show()
end
local function RefreshMembers()
    members=Roster(selectedClass)
    table.sort(members,function(a,b) return a.name < b.name end)
    local count=table.getn(members)
    local pages=math.max(1,math.ceil(count/10))
    page=math.max(1,math.min(pages,page))
    local visible=math.min(10,math.max(0,count-(page-1)*10))
    memberMenu:SetHeight(35+visible*24+28)
    memberTitle:SetText((PallyPower_ClassID[selectedClass] or "职业").." - 团员")
    for i=1,10 do
        local row,member=rows[i],members[(page-1)*10+i]
        if member then
            row.memberName=member.name; row.text:SetText(member.name)
            local buff=PallyPower_PersonalBlessing(selectedClass,member.name)
            row.icon:SetTexture("Interface\\Icons\\"..(buff~=nil and smallIcons[buff] or "Spell_Nature_WispSplode"))
            row.icon:SetVertexColor(buff~=nil and 1 or 0.35,buff~=nil and 1 or 0.35,buff~=nil and 1 or 0.35)
            row:Show()
        else row.memberName=nil; row:Hide() end
    end
    PallyPowerMemberPage:SetText(page.."/"..pages)
    PlaceMenu(memberMenu,memberAnchor)
end
for i=1,10 do
    local row=MenuButton(memberMenu,"PallyPowerMemberRow"..i,-30-(i-1)*24,191)
    row.text:SetWidth(146); row.text:SetJustifyH("LEFT")
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetWidth(20); row.icon:SetHeight(20)
    row.icon:SetPoint("RIGHT",row,"RIGHT",-3,0)
    row:SetScript("OnClick",function()
        selectedName=this.memberName
        if selectedName then OpenBlessings(this) end
    end)
    rows[i]=row
end
local previous=Button(memberMenu,"PallyPowerMemberPrevious","上一页",7,0,65,function()
    blessingMenu:Hide(); page=page-1; RefreshMembers()
end)
previous:ClearAllPoints(); previous:SetPoint("BOTTOMLEFT",memberMenu,"BOTTOMLEFT",7,4)
local next=Button(memberMenu,"PallyPowerMemberNext","下一页",133,0,65,function()
    blessingMenu:Hide(); page=page+1; RefreshMembers()
end)
next:ClearAllPoints(); next:SetPoint("BOTTOMRIGHT",memberMenu,"BOTTOMRIGHT",-7,4)
PallyPowerMemberPage=memberMenu:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
PallyPowerMemberPage:SetPoint("BOTTOM",memberMenu,"BOTTOM",0,10)
blessingMenu:SetHeight(228)
local order={1,0,2,3,4,5}
for i,id in ipairs(order) do
    local buffID=id
    local b=MenuButton(blessingMenu,"PallyPowerSmallChoice"..id,-30-(i-1)*24,216)
    b.text:ClearAllPoints(); b.text:SetPoint("LEFT",b,"LEFT",30,0)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(20); b.icon:SetHeight(20)
    b.icon:SetPoint("LEFT",b,"LEFT",3,0); b.icon:SetTexture("Interface\\Icons\\"..smallIcons[id])
    b:SetScript("OnClick",function()
        local name,classID=selectedName,selectedClass
        if not name then return end
        local skills=AllPallys[UnitName("player")]
        if not skills or not skills[PallyPower_LesserBlessingMap[buffID]] then
            PallyPower_ShowFeedback("尚未学会该小祝福："..shortNames[buffID],1,0.2,0.2)
            return
        end
        if PallyPower_SetPersonalBlessing(classID,name,buffID) then
            PallyPower_CastPersonalBlessing(classID,name,buffID)
            PallyPower_ClosePersonalMenus()
        end
    end)
    choices[id]=b
end
local follow=MenuButton(blessingMenu,"PallyPowerSmallFollow",-174,216)
follow.text:SetText("跟随职业（取消个人分配）")
follow:SetScript("OnClick",function()
    if selectedName then PallyPower_SetPersonalBlessing(selectedClass,selectedName,nil) end
    PallyPower_ClosePersonalMenus()
end)
local cast=MenuButton(blessingMenu,"PallyPowerSmallCast",-198,216)
cast.text:SetText("施放当前分配的小祝福")
cast:SetScript("OnClick",function()
    if selectedName then PallyPower_CastPersonalBlessing(selectedClass,selectedName) end
    PallyPower_ClosePersonalMenus()
end)

function PallyPower_OpenPersonalBlessings(classID,anchor)
    if classID==9 then PallyPower_ShowFeedback("宠物仍按职业祝福分配",1,0.8,0.3) return end
    anchor=anchor or PallyPowerBuffBar
    if memberMenu:IsVisible() and selectedClass==classID and memberAnchor==anchor then
        PallyPower_ClosePersonalMenus(); return
    end
    Settings(); blessingMenu:Hide(); selectedName=nil; selectedClass=classID; page=1
    memberAnchor=anchor; RefreshMembers(); memberMenu:Show()
end
local oldBarHide=PallyPowerBuffBar:GetScript("OnHide")
PallyPowerBuffBar:SetScript("OnHide",function()
    PallyPower_ClosePersonalMenus()
    PallyPowerBuffBar:StopMovingOrSizing(); PallyPowerBuffBar.isMoving=false
    SaveBuffBarPosition()
    if oldBarHide then oldBarHide() end
end)

-- 方案只改变自己的职业分配；其他骑士与个人例外均保留。
local presetLabel = PallyPowerFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
presetLabel:SetPoint("BOTTOMLEFT",PallyPowerFrame,"BOTTOMLEFT",10,98); presetLabel:SetText("我的一键祝福方案")
for i, preset in ipairs(presets) do
    local key = preset.key
    local b = CreateFrame("Button","PallyPowerPreset"..key,PallyPowerFrame,"UIPanelButtonTemplate")
    b:SetWidth(108); b:SetHeight(24)
    b:SetPoint("BOTTOMLEFT",PallyPowerFrame,"BOTTOMLEFT",10+math.mod(i-1,4)*114,64-math.floor((i-1)/4)*28)
    b:SetText(preset.label); b:SetScript("OnClick",function() PallyPower_ApplyPreset(key) end)
    table.insert(presetButtons,b)
end

-- 设置窗口可独立拖动；滑条、输入框和复选框不触发窗口拖动。
PallyPower_OptionsFrame:SetMovable(true)
PallyPower_OptionsFrame:SetFrameStrata("DIALOG")
if PallyPower_OptionsFrame.SetClampedToScreen then PallyPower_OptionsFrame:SetClampedToScreen(true) end
local optionsDrag = CreateFrame("Frame","PallyPowerOptionsDragHandle",PallyPower_OptionsFrame)
optionsDrag:SetPoint("TOPLEFT",PallyPower_OptionsFrame,"TOPLEFT",0,0)
optionsDrag:SetWidth(PallyPower_OptionsFrame:GetWidth()-36); optionsDrag:SetHeight(30)
optionsDrag:SetFrameLevel(PallyPower_OptionsFrame:GetFrameLevel()+1)
optionsDrag:EnableMouse(true); optionsDrag:RegisterForDrag("LeftButton")
optionsDrag:SetScript("OnDragStart",function() PallyPower_OptionsFrame:StartMoving() end)
optionsDrag:SetScript("OnDragStop",function() PallyPower_OptionsFrame:StopMovingOrSizing() end)
local optionsOldHide = PallyPower_OptionsFrame:GetScript("OnHide")
PallyPower_OptionsFrame:SetScript("OnHide",function()
    PallyPower_OptionsFrame:StopMovingOrSizing()
    if optionsOldHide then optionsOldHide() end
end)

-- 祝福分配窗口的选项按钮、团队施法框标题或空白区域右键均可打开选项。
-- 职业行仍保留右键补个人小祝福、中键设置个人祝福的操作。
PallyPowerFrameOptions:Show()
function PallyPower_Options(button)
    local fromOptions=this==PallyPowerFrameOptions and (button==nil or button=="LeftButton")
    local fromBar=button=="RightButton" and (this==PallyPowerBuffBar or this==PallyPowerBuffBarTitle)
    if not fromOptions and not fromBar then return false end
    PallyPower_ClosePersonalMenus()
    PallyPowerFrame:Hide()
    PallyPower_OptionsFrame:Show()
    return true
end

PallyPower_OptionsFrame:SetHeight(478)
Label(PallyPower_OptionsFrame,"团队施法框背景透明度",20,-307)
local slider = CreateFrame("Slider","PallyPowerBuffBarTransparency",PallyPower_OptionsFrame,"OptionsSliderTemplate")
slider:SetWidth(245); slider:SetHeight(16); slider:SetPoint("TOPLEFT",PallyPower_OptionsFrame,"TOPLEFT",25,-346)
slider:SetMinMaxValues(0,100); slider:SetValueStep(1)
getglobal(slider:GetName().."Low"):SetText("不透明")
getglobal(slider:GetName().."High"):SetText("全透明")
local sliderText = getglobal(slider:GetName().."Text")
local restoring = false
slider:SetScript("OnValueChanged",function()
    if restoring then return end
    local value = math.floor(slider:GetValue()+0.5)
    Settings().barBackgroundAlpha = 1-value/100
    sliderText:SetText(value.."%")
    PallyPower_ApplyBuffBarAppearance()
end)
local lock = CreateFrame("CheckButton","PallyPowerBuffBarLock",PallyPower_OptionsFrame,"UICheckButtonTemplate")
lock:SetPoint("TOPLEFT",PallyPower_OptionsFrame,"TOPLEFT",15,-377)
Label(lock,"锁定团队施法框（禁止移动、缩放）",30,-7)
lock:SetScript("OnClick",function()
    Settings().barLocked = this:GetChecked() and 1 or 0
    PallyPower_ApplyBuffBarAppearance()
end)
local alwaysBar=CreateFrame("CheckButton","PallyPowerAlwaysBuffBar",PallyPower_OptionsFrame,"UICheckButtonTemplate")
alwaysBar:SetPoint("TOPLEFT",PallyPower_OptionsFrame,"TOPLEFT",15,-407)
Label(alwaysBar,"始终显示团队祝福框",30,-7)
alwaysBar:SetScript("OnClick",function()
    Settings().alwaysBuffBar=this:GetChecked() and 1 or 0
    PallyPower_UpdateUI()
end)
local soloLock=CreateFrame("CheckButton","PallyPowerSoloLock",PallyPower_OptionsFrame,"UICheckButtonTemplate")
soloLock:SetPoint("TOPLEFT",PallyPower_OptionsFrame,"TOPLEFT",15,-437)
Label(soloLock,"锁定单人宝珠（禁止移动、缩放）",30,-7)
soloLock:SetScript("OnClick",function()
    Settings().soloLocked=this:GetChecked() and 1 or 0
    PallyPower_ApplySoloLock()
end)
local oldShow = PallyPower_OptionsFrame:GetScript("OnShow")
PallyPower_OptionsFrame:SetScript("OnShow",function()
    if oldShow then oldShow() end
    local saved=Settings(); restoring=true
    slider:SetValue(math.floor((1-saved.barBackgroundAlpha)*100+0.5)); restoring=false
    sliderText:SetText(math.floor((1-saved.barBackgroundAlpha)*100+0.5).."%")
    lock:SetChecked(saved.barLocked==1)
    alwaysBar:SetChecked(saved.alwaysBuffBar==1)
    soloLock:SetChecked(saved.soloLocked==1)
end)

local oldClick = PallyPowerBuffButton_OnClick
function PallyPowerBuffButton_OnClick(btn,mousebtn)
    local _,class=UnitClass("player")
    if class ~= "PALADIN" or btn.classID == nil or btn.buffID == nil then return end
    if mousebtn == "MiddleButton" then PallyPower_OpenPersonalBlessings(btn.classID,btn) return end
    if mousebtn == "RightButton" or TenMinBlessing == true then CastClassSmall(btn) return end
    oldClick(btn,mousebtn)
end
local oldEnter = PallyPowerBuffButton_OnEnter
function PallyPowerBuffButton_OnEnter(btn)
    oldEnter(btn)
    GameTooltip:AddLine("中键：选择团员，设置个人小祝福",0.4,1,0.7)
    GameTooltip:AddLine("右键：优先补个人小祝福；左键：职业祝福",0.4,1,0.7)
    GameTooltip:Show()
end
local oldGrid = PallyPowerGrid_Update
function PallyPowerGrid_Update()
    oldGrid()
    if PallyPowerFrame:IsVisible() then PallyPowerFrame:SetHeight(PallyPowerFrame:GetHeight()+82) end
end
local oldMouseDown = PallyPowerBuffBar_MouseDown
local oldMouseUp = PallyPowerBuffBar_MouseUp
local barPressedButton
function PallyPowerBuffBar_MouseDown(button)
    barPressedButton = button
    if button ~= "LeftButton" then return end
    if PP_PerUser.barLocked == 1 then
        PallyPowerBuffBar.startPosX=PallyPowerBuffBar:GetLeft()
        PallyPowerBuffBar.startPosY=PallyPowerBuffBar:GetTop()
        return
    end
    oldMouseDown(button)
end
function PallyPowerBuffBar_MouseUp(button)
    local pressed = button or arg1 or barPressedButton
    barPressedButton = nil
    if pressed == "RightButton" then
        PallyPower_Options(pressed)
    elseif pressed == "LeftButton" then
        local wasMoving=PallyPowerBuffBar.isMoving
        oldMouseUp()
        if wasMoving then SaveBuffBarPosition() end
    end
end
PallyPowerBuffBar:SetScript("OnMouseDown",function() PallyPowerBuffBar_MouseDown(arg1) end)
PallyPowerBuffBar:SetScript("OnMouseUp",function() PallyPowerBuffBar_MouseUp(arg1) end)
-- XML 中旧标题回调未传鼠标键，替换为明确传入事件参数。
PallyPowerBuffBarTitle:SetScript("OnMouseUp",function() PallyPowerBuffBar_MouseUp(arg1) end)

local oldStart = PallyPower_StartScaling
function PallyPower_StartScaling(button)
    if this:GetParent() == PallyPowerBuffBar and PP_PerUser.barLocked == 1 then return end
    if this:GetParent() == PallyPowerSoloBar and PP_PerUser.soloLocked == 1 then return end
    oldStart(button)
end
local oldScale = PallyPower_ScaleFrame
function PallyPower_ScaleFrame(scale)
    if not PallyPower.FrameToScale then return end
    if PallyPower.FrameToScale == PallyPowerBuffBar then
        if PP_PerUser.barLocked == 1 then return end
        if not ValidCoordinate(scale) or scale<=0 then return end
        local x,y=BuffBarPosition()
        if x==nil then return end
        PallyPowerBuffBar:SetScale(scale)
        SetBuffBarPosition(x,y)
        Settings().scalebar=scale
        SaveBuffBarPosition()
        return
    end
    if PallyPower.FrameToScale == PallyPowerSoloBar then
        if PP_PerUser.soloLocked == 1 then return end
        if not ValidCoordinate(scale) or scale<=0 then return end
        local x,y=SoloPosition()
        if x==nil then return end
        PallyPowerSoloBar:SetScale(scale)
        SetSoloPosition(x,y)
        Settings().scalesolo=scale
        SaveSoloPosition()
        return
    end
    oldScale(scale)
end
local oldScalingUpdate = PallyPower_ScalingFrame_OnUpdate
function PallyPower_ScalingFrame_OnUpdate(elapsed)
    if not PallyPower.FrameToScale then return end
    oldScalingUpdate(elapsed)
end

-- 两个框可能同时调用原 OnUpdate。按 GetTime 差值计算一次真实经过时间，
-- 防止重复递减扫描计时，也避免性能补丁对全局 arg1 的影响。
local lastTick
local oldUpdate = PallyPower_OnUpdate
function PallyPower_OnUpdate(ignored)
    local now=GetTime()
    local elapsed=lastTick and (now-lastTick) or 0
    lastTick=now
    if elapsed <= 0 then return end
    oldUpdate(elapsed)
end

local events = CreateFrame("Frame","PallyPowerExtensionEvents")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("RAID_ROSTER_UPDATE"); events:RegisterEvent("PARTY_MEMBERS_CHANGED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent",function()
    if event == "PLAYER_LOGOUT" then
        PallyPowerBuffBar:StopMovingOrSizing(); PallyPowerBuffBar.isMoving=false
        SaveBuffBarPosition()
        PallyPowerSoloBar:StopMovingOrSizing(); PallyPowerSoloBar.isMoving=false
        SaveSoloPosition()
        return
    end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Settings(); RestoreBuffBarPosition(); RestoreSoloPosition(); PallyPower_ApplyBuffBarAppearance(); PallyPower_ApplySoloLock()
        if type(PP_PerUser.scanfreq) ~= "number" or PP_PerUser.scanfreq <= 0 then PP_PerUser.scanfreq=3 end
        if type(PP_PerUser.scanperframe) ~= "number" or PP_PerUser.scanperframe < 1 then PP_PerUser.scanperframe=1 end
    end
    -- 成员增减或换组必须废弃未完成扫描；不在事件里扫描全团 buff。
    PP_ScanInfo=nil; PP_NextScan=0
    if PallyPowerMemberMenu:IsVisible() then PallyPower_ClosePersonalMenus() end
end)
