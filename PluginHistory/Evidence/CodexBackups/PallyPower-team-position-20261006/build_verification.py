from pathlib import Path

work=Path(__file__).parent
support=Path(r'C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work')
source=(support/'pallypower-solo-position/verify.py').read_text(encoding='utf-8')
source=source.replace("work=Path(__file__).parent; root=", "work=Path(__file__).parent; support=Path(r'C:\\Users\\Administrator\\Documents\\Codex\\2026-10-05\\nik\\work'); root=")
source=source.replace('work.parent/', 'support/')
source=source.replace("{'work':work}", "{'work':support/'team-position'}")
start=source.index('# Regression reproduction with the previous installed extension')
end=source.index('def position(g):',start)
source=source[:start]+source[end:]
source=source.replace('def setup(saved=None, parent_scale=1):','def setup(saved=None, parent_scale=1, fire_login=True):')
source=source.replace('    lua.execute(\'event="PLAYER_LOGIN"; PallyPowerExtensionEvents.scripts.OnEvent()\')', '    if fire_login: lua.execute(\'event="PLAYER_LOGIN"; PallyPowerExtensionEvents.scripts.OnEvent()\')')
source+='''

# Reproduce the reported group-position loss against the previous installed source.
patched_read=read
def read_previous(name):
    path=work/'original'/name
    return path.read_text(encoding='utf-8-sig') if path.exists() else patched_read(name)
read=read_previous
lua=setup(); g=lua.globals(); bar=g.PallyPowerBuffBar
g.this=g.PallyPowerBuffBarTitle; g.arg1='LeftButton'
g.PallyPowerBuffBar_MouseDown('LeftButton')
bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',331,762)
g.PallyPowerBuffBar_MouseUp('LeftButton')
assert g.PP_PerUser.barPositionX is None and g.PP_PerUser.barPositionY is None
restored=setup(g.Snapshot(g.PP_PerUser)); rb=restored.globals().PallyPowerBuffBar
assert (rb.GetLeft(rb),rb.GetTop(rb))!=(331,762)
read=patched_read
print('PASS: previous installed source reproduces group-frame position loss after a fresh runtime.')

def bar_position(g):
    bar=g.PallyPowerBuffBar
    ratio=bar.GetEffectiveScale(bar)/g.UIParent.GetEffectiveScale(g.UIParent)
    return (bar.GetLeft(bar)*ratio,bar.GetTop(bar)*ratio)

cases=0
for parent_scale,scale,locked in itertools.product([.64,.8,1],[.5,1,2],[0,1]):
    lua=setup('{scalebar='+str(scale)+',barBackgroundAlpha=.32,alwaysBuffBar=1}',parent_scale)
    g=lua.globals(); bar=g.PallyPowerBuffBar
    # Title and blank-area native mouse-up routes both save, without opening distribution.
    for anchor,x,y in [(g.PallyPowerBuffBarTitle,335,773),(bar,351,728)]:
        g.this=anchor; g.arg1='LeftButton'; g.PallyPowerBuffBar_MouseDown('LeftButton')
        assert bar.moving
        bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',x/scale,y/scale)
        anchor.scripts.OnMouseUp()
        assert not bar.moving and not g.PallyPowerFrame.shown
        same(bar_position(g),(x,y)); same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(x,y))
    for new_scale in [1.4,.7,1.9]:
        g.PallyPower.FrameToScale=bar; g.PallyPower_ScaleFrame(new_scale); g.PallyPower.FrameToScale=None
        same(bar_position(g),(351,728)); assert math.isclose(g.PP_PerUser.scalebar,new_scale)
    # Dynamic height changes must keep the top-left stationary.
    for height in [64,302,370,98]:
        bar.SetHeight(bar,height); same(bar_position(g),(351,728))
    g.PP_PerUser.barLocked=locked; g.PallyPower_ApplyBuffBarAppearance()
    snapshot=g.Snapshot(g.PP_PerUser)
    loaded=setup(snapshot,parent_scale); lg=loaded.globals(); lb=lg.PallyPowerBuffBar
    same(bar_position(lg),(351,728)); assert math.isclose(lb.scale,bar.scale)
    assert lb.movable==bool(not locked) and lg.PP_PerUser.barLocked==locked
    assert lg.PP_PerUser.barBackgroundAlpha==.32 and lg.PP_PerUser.alwaysBuffBar==1
    for ev in ['PLAYER_ENTERING_WORLD','PLAYER_LOGIN','RAID_ROSTER_UPDATE','PARTY_MEMBERS_CHANGED']:
        lg.event=ev; lg.PallyPowerExtensionEvents.scripts.OnEvent(); same(bar_position(lg),(351,728))
    lg.now=110; lg.PallyPower_UpdateUI(); same(bar_position(lg),(351,728))
    # Skin callbacks and settings controls must never change frame location.
    lg.PallyPower_OptionsFrame.Show(lg.PallyPower_OptionsFrame)
    lg.PallyPowerBuffBarTransparency.SetValue(lg.PallyPowerBuffBarTransparency,70)
    loaded.execute(read('pfUI-addonskinner/skins/PallyPower.lua')); lg.pfUI.addonskinner.callback()
    same(bar_position(lg),(351,728))
    # Locked resize remains blocked, and later entering-world cannot reset a new drag.
    lg.PallyPower.FrameToScale=lb; before_scale=lb.scale
    if locked:
        lg.PallyPower_ScaleFrame(2.5); assert lb.scale==before_scale
        lg.PallyPower.FrameToScale=None; lg.PallyPowerBuffBar_MouseDown('LeftButton'); assert not lb.moving
    else:
        lg.PallyPower.FrameToScale=None; lg.this=lb; lg.arg1='LeftButton'
        lg.PallyPowerBuffBar_MouseDown('LeftButton')
        lb.ClearAllPoints(lb); lb.SetPoint(lb,'TOPLEFT',lg.UIParent,'BOTTOMLEFT',457/lb.scale,659/lb.scale)
        lg.event='PLAYER_ENTERING_WORLD'; lg.PallyPowerExtensionEvents.scripts.OnEvent()
        same(bar_position(lg),(457,659)); lg.PallyPowerBuffBar_MouseUp('LeftButton')
        same((lg.PP_PerUser.barPositionX,lg.PP_PerUser.barPositionY),(457,659))
    cases+=1

for action in ['hide','lock','logout']:
    lua=setup(); g=lua.globals(); bar=g.PallyPowerBuffBar
    g.PallyPowerBuffBar_MouseDown('LeftButton')
    bar.ClearAllPoints(bar); bar.SetPoint(bar,'TOPLEFT',g.UIParent,'BOTTOMLEFT',482,698)
    if action=='hide': bar.scripts.OnHide()
    elif action=='lock': g.PP_PerUser.barLocked=1; g.PallyPower_ApplyBuffBarAppearance()
    else: g.event='PLAYER_LOGOUT'; g.PallyPowerExtensionEvents.scripts.OnEvent()
    assert not bar.moving and not bar.isMoving
    same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(482,698))
    loaded=setup(g.Snapshot(g.PP_PerUser)); same(bar_position(loaded.globals()),(482,698))

# Startup hides before restoration cannot overwrite a saved position; event order is safe.
for core_first in [True,False]:
    lua=setup('{barPositionX=318,barPositionY=748,scalebar=1.6}',.8,False); g=lua.globals()
    g.PallyPowerBuffBar.scripts.OnHide()
    same((g.PP_PerUser.barPositionX,g.PP_PerUser.barPositionY),(318,748))
    if core_first: g.PallyPower_UpdateUI()
    g.event='PLAYER_LOGIN'; g.PallyPowerExtensionEvents.scripts.OnEvent()
    if not core_first: g.PallyPower_UpdateUI()
    same(bar_position(g),(318,748))
for saved in ['{}','{barPositionX="bad",barPositionY=100}',
              '{barPositionX=300}', '{barPositionX=0/0,barPositionY=100}',
              '{barPositionX=math.huge,barPositionY=100}']:
    lua=setup(saved); assert lua.globals().PallyPowerBuffBar.point is None
lua=setup('{barPositionX=0,barPositionY=0}'); same(bar_position(lua.globals()),(0,0))

# Group and solo coordinates are stored independently across logout/relogin.
lua=setup('{barPositionX=234,barPositionY=634,soloPositionX=478,soloPositionY=878,scalebar=.8,scalesolo=1.4}')
g=lua.globals(); g.event='PLAYER_LOGOUT'; g.PallyPowerExtensionEvents.scripts.OnEvent()
loaded=setup(g.Snapshot(g.PP_PerUser)); lg=loaded.globals()
same(bar_position(lg),(234,634)); same(position(lg),(478,878))
assert lg.PallyPowerExtensionEvents.scripts.OnUpdate is None
print(f'PASS: {cases} group-frame reload/relogin cases across UI scales, own scales and locks; title/blank drag saves; resize and roster-height changes retain position; settings/skin preserve location; interrupted drags and login order safe; invalid/old saves and independent solo coordinates retained. No added per-frame work.')
'''
(work/'verify.py').write_text(source,encoding='utf-8')
print('Built team-position regressions and existing feature checks.')
