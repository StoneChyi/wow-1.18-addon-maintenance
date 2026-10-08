from pathlib import Path
import hashlib, json, zipfile

work=Path(__file__).parent
root=Path(r'E:\1.18\Interface\AddOns')
name='PallyPower/PallyPower-Extensions.lua'
before=(root/name).read_bytes()
source=before.decode('utf-8-sig').replace('\r\n','\n')

valid='''local function ValidCoordinate(value)
    return type(value)=="number" and value==value and math.abs(value)<10000000000
end
'''
assert source.count(valid)==1
source=source.replace(valid,'',1)
team='''-- 团队施法框按 UIParent 坐标存档；固定左上角避免人数改变高度时偏移。
-- 与单人宝珠分别保存，只在用户操作和登录/退出事件中处理位置。
local barPositionRestored=false
'''+valid+'''local function BuffBarPosition()
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

'''
marker='function PallyPower_ApplyBuffBarAppearance()'
assert source.count(marker)==1
source=source.replace(marker,team+marker,1)
old='''    if locked then
        bar:StopMovingOrSizing(); bar.isMoving = false
        if PallyPower.FrameToScale == bar then'''
new='''    if locked then
        local wasMoving=bar.isMoving
        bar:StopMovingOrSizing(); bar.isMoving = false
        if wasMoving then SaveBuffBarPosition() end
        if PallyPower.FrameToScale == bar then'''
assert source.count(old)==1
source=source.replace(old,new,1)
old='''PallyPowerBuffBar:SetScript("OnHide",function()
    PallyPower_ClosePersonalMenus()
    if oldBarHide then oldBarHide() end'''
new='''PallyPowerBuffBar:SetScript("OnHide",function()
    PallyPower_ClosePersonalMenus()
    PallyPowerBuffBar:StopMovingOrSizing(); PallyPowerBuffBar.isMoving=false
    SaveBuffBarPosition()
    if oldBarHide then oldBarHide() end'''
assert source.count(old)==1
source=source.replace(old,new,1)
old='''    elseif pressed == "LeftButton" then
        oldMouseUp()
    end'''
new='''    elseif pressed == "LeftButton" then
        local wasMoving=PallyPowerBuffBar.isMoving
        oldMouseUp()
        if wasMoving then SaveBuffBarPosition() end
    end'''
assert source.count(old)==1
source=source.replace(old,new,1)
old='''    if PallyPower.FrameToScale == PallyPowerBuffBar and PP_PerUser.barLocked == 1 then return end
    if PallyPower.FrameToScale == PallyPowerSoloBar then'''
new='''    if PallyPower.FrameToScale == PallyPowerBuffBar then
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
    if PallyPower.FrameToScale == PallyPowerSoloBar then'''
assert source.count(old)==1
source=source.replace(old,new,1)
old='''    if event == "PLAYER_LOGOUT" then
        PallyPowerSoloBar:StopMovingOrSizing(); PallyPowerSoloBar.isMoving=false'''
new='''    if event == "PLAYER_LOGOUT" then
        PallyPowerBuffBar:StopMovingOrSizing(); PallyPowerBuffBar.isMoving=false
        SaveBuffBarPosition()
        PallyPowerSoloBar:StopMovingOrSizing(); PallyPowerSoloBar.isMoving=false'''
assert source.count(old)==1
source=source.replace(old,new,1)
old='Settings(); RestoreSoloPosition(); PallyPower_ApplyBuffBarAppearance(); PallyPower_ApplySoloLock()'
assert source.count(old)==1
source=source.replace(old,'Settings(); RestoreBuffBarPosition(); RestoreSoloPosition(); PallyPower_ApplyBuffBarAppearance(); PallyPower_ApplySoloLock()',1)
after=source.replace('\n','\r\n').encode('utf-8')
manifest={name:{'before':hashlib.sha256(before).hexdigest(),'after':hashlib.sha256(after).hexdigest()}}
for folder,data in [('original',before),('patched',after)]:
    target=work/folder/name
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
(work/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for filename,data in [('PallyPower-before.zip',before),('PallyPower-fixed.zip',after)]:
    with zipfile.ZipFile(work/filename,'w',zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(name,data)
        archive.writestr('manifest.json',json.dumps(manifest,indent=2))
print('Prepared team-position repair and backup; installed source unchanged.')
