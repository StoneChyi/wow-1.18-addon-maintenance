"""Exercise the complete independent resource-bar module with strict 1.12 UI APIs.

The shared FontString contract rejects SetText before a valid font exists and
can fail configured SetFont calls. All resource values and time are controlled;
these tests do not validate the actual game renderer or server events.
"""
from pathlib import Path
import argparse
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime, LuaError

parser = argparse.ArgumentParser()
parser.add_argument("--addons", type=Path, default=ROOT / "Interface/AddOns")
ARGS, REMAINING = parser.parse_known_args()

MOCK = r'''
objects={};methods={};clock=100;fps=60;resource=6000;maximum=6000;powerType=0
combat=false;classToken='MAGE';sharedPhase=nil
baseMana=4300;baseManaMax=6000;playerExists=true
reads={mana=0,maxmana=0,power=0,field=0,exists=0,phase=0,combat=0};movables={}
function object(kind,name,parent,template)
  local o=setmetatable({kind=kind,name=name,parent=parent,template=template,children={},regions={},
    scripts={},events={},shown=true,alpha=1,scale=1,width=100,height=20,calls={},points={}}, {__index=methods})
  if name then _G[name]=o end
  if parent then
    if kind=='Texture' or kind=='FontString' then table.insert(parent.regions,o)
    else table.insert(parent.children,o) end
  end
  table.insert(objects,o);return o
end
local function called(o,k) o.calls[k]=(o.calls[k] or 0)+1 end
function CreateFrame(kind,name,parent,template) return object(kind,name,parent,template) end
function methods:GetName() return self.name end
function methods:GetObjectType() return self.kind end
function methods:GetParent() return self.parent end
function methods:SetParent(parent) self.parent=parent end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() return unpack(self.regions) end
function methods:SetScript(k,fn)
  assert(k=='OnUpdate' or k=='OnEvent' or k=='OnShow' or k=='OnHide'
    or k=='OnMouseDown' or k=='OnMouseUp' or k=='OnDragStart' or k=='OnDragStop',
    'unsupported 1.12 script slot: '..tostring(k))
  self.scripts[k]=fn
end
function methods:GetScript(k) return self.scripts[k] end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:CreateTexture(name,layer)
  local t=object('Texture',name,self);t.layer=layer;return t
end
function methods:SetPoint(...)
  called(self,'point');local args={...};assert(type(args[1])=='string','SetPoint anchor')
  if type(args[2])=='number' then
    args={args[1],self.parent,args[1],args[2],args[3]}
  end
  self.point=args
  for i,p in ipairs(self.points) do if p[1]==args[1] then self.points[i]=args;return end end
  table.insert(self.points,args)
end
function methods:GetPoint(index)
  local point=self.points[index or 1];if point then return unpack(point,1,5) end
end
function methods:GetNumPoints() return #self.points end
function methods:ClearAllPoints() called(self,'clearpoints');self.points={};self.point=nil end
function methods:SetAllPoints(f) called(self,'allpoints');self.allpoints=f or self.parent end
function methods:SetWidth(v) assert(type(v)=='number' and v>=0,'width');called(self,'width');self.width=v end
function methods:SetHeight(v) assert(type(v)=='number' and v>=0,'height');called(self,'height');self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(v) called(self,'scale');self.scale=v end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:SetAlpha(v) assert(type(v)=='number');called(self,'alpha');self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:SetFrameStrata(v) called(self,'strata');self.strata=v end
function methods:GetFrameStrata() return self.strata or 'MEDIUM' end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetTexture(...) called(self,'texture');self.texture={...} end
function methods:GetTexture() return self.texture and self.texture[1] end
function methods:SetVertexColor(...) called(self,'color');self.color={...} end
function methods:SetTextColor(...) called(self,'textcolor');self.textcolor={...} end
function methods:SetJustifyH(v) self.justifyH=v end
function methods:SetJustifyV(v) self.justifyV=v end
function methods:SetBlendMode(v) self.blend=v end
function methods:SetTexCoord(...) self.texcoords={...} end
function methods:GetText() return self.text end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:SetBackdropBorderColor(...) self.border={...} end
function methods:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function methods:SetValue(v) self.value=v end
function methods:SetStatusBarTexture(v) self.statusTexture=v end
function methods:SetStatusBarColor(...) self.statusColor={...} end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetMovable(v) self.movable=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:RegisterForDrag(...) self.dragButtons={...} end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function runScript(o,k,...)
  local oldThis,oldArg=this,arg1;this=o;arg1=select(1,...)
  -- The 1.12 client supplies this/arg1 globals, without callback arguments.
  if o.scripts[k] then o.scripts[k]() end
  this,arg1=oldThis,oldArg
end
function methods:Show()
  local was=self.shown;self.shown=true;called(self,'show')
  if not was then runScript(self,'OnShow') end
end
function methods:Hide()
  local was=self.shown;self.shown=false;called(self,'hide')
  if was then runScript(self,'OnHide') end
end
function HookScript(f,k,fn)
  local prev=f:GetScript(k)
  f:SetScript(k,function(...) if prev then prev(...) end;fn(...) end)
end
function UpdateMovable(f,init)
  table.insert(movables,f:GetName())
  assert(f:GetName()=='pfEnergyBar','resource bar touched another movable')
  pfUI.api.UpdateMovable(f,init)
end
function getglobal(k) return _G[k] end
function GetTime() return clock end
function GetFramerate() return fps end
function UnitMana() reads.mana=reads.mana+1;return resource end
function UnitManaMax() reads.maxmana=reads.maxmana+1;return maximum end
function UnitPowerType() reads.power=reads.power+1;return powerType end
function UnitExists(u) reads.exists=reads.exists+1;if playerExists then return 1,'PlayerGUID' end end
function UnitClass() return classToken,classToken end
function GetLocale() return 'enUS' end
function UnitAffectingCombat() reads.combat=reads.combat+1;return combat end
function GetUnitField(guid,key)
  assert(guid=='PlayerGUID','wrong GUID');reads.field=reads.field+1
  if key=='power1' then return baseMana elseif key=='maxPower1' then return baseManaMax end
  error('unexpected resource field: '..tostring(key))
end
function GetBorderSize() return 1,1 end
function GetTalentInfo() error('independent bar must not derive a private energy model') end
function UnitStat() error('independent bar must not derive a private energy model') end
UIParent=object('Frame','UIParent');UIParent.width=1920;UIParent.height=1080
pfUI={font_default='Configured.ttf',uf={},energytick={},unlock=object('Frame','Unlock'),
  RegisterModule=function(self,name,versions,fn) self.loadedName=name;fn() end}
pfUI.unlock.shown=false
function pfUI.energytick:EnergyProgress() reads.phase=reads.phase+1;return sharedPhase end
pfUI.uf.player=object('Frame','pfPlayer');pfUI.uf.player.height=40
pfUI.combopoints={points={},UpdateConfig=function() comboRefreshes=(comboRefreshes or 0)+1 end}
pfCombo1=object('Frame','pfCombo1');pfUI.combopoints.points[1]=pfCombo1
pfUI.distanceIndicator=object('Frame','pfDistanceIndicator')
pfTargetThreat=object('Frame','pfTargetThreat')
C={position={pfCombo1={xpos=22,ypos=333},pfDistanceIndicator={xpos=44,ypos=555},
  pfTargetThreat={xpos=66,ypos=777},pfPlayer={xpos=100,ypos=200}},unitframes={}}
for _,f in ipairs({pfCombo1,pfUI.distanceIndicator,pfTargetThreat,pfUI.uf.player}) do
  f:SetPoint('BOTTOM',UIParent,'BOTTOM',12,34);f.calls={}
end
originalComboUpdate=pfUI.combopoints.UpdateConfig
SlashCmdList={};DEFAULT_CHAT_FRAME={AddMessage=function() end};pfUI_locale={enUS={class={}}}
function step(dt)
  clock=clock+dt
  -- A callback may create children, but those start ticking next frame.
  local n=table.getn(objects)
  for i=1,n do local o=objects[i]
    if o.scripts.OnUpdate and o:IsVisible() then runScript(o,'OnUpdate',dt) end
  end
end
function advance(seconds,rate)
  fps=rate or fps;local dt=1/fps
  local count=math.floor(seconds/dt+.000001)
  for i=1,count do step(dt) end
  local rest=seconds-count*dt;if rest>.000001 then step(rest) end
end
function dispatchEvent(name,unit)
  for _,o in ipairs(objects) do if o.events[name] and o.scripts.OnEvent then
    local old=event;_G.event=name;runScript(o,'OnEvent',unit);_G.event=old
  end end
end
function otherFramesUnchanged()
  assert(C.position.pfCombo1.xpos==22 and C.position.pfCombo1.ypos==333)
  assert(C.position.pfDistanceIndicator.xpos==44 and C.position.pfDistanceIndicator.ypos==555)
  assert(C.position.pfTargetThreat.xpos==66 and C.position.pfTargetThreat.ypos==777)
  assert(C.position.pfPlayer.xpos==100 and C.position.pfPlayer.ypos==200)
  for _,f in ipairs({pfCombo1,pfUI.distanceIndicator,pfTargetThreat,pfUI.uf.player}) do
    assert(not f.calls.point and not f.calls.clearpoints and not f.calls.scale,'another frame moved')
  end
  assert(pfUI.combopoints.UpdateConfig==originalComboUpdate,'combo function wrapped')
  for _,name in ipairs(movables) do assert(name=='pfEnergyBar') end
end
'''

DEFAULTS = {
    "comboenergyshow": "0", "comboenergywidth": "200", "comboenergyheight": "12",
    "comboenergyoffx": "0", "comboenergyoffy": "278", "comboenergyshowtext": "1",
    "comboenergyfontsize": "12", "comboenergytextformat": "0",
    "comboenergytextalign": "center", "comboenergyshowtick": "1",
    "comboenergyallpower": "1", "comboenergyautocolor": "1",
    "comboenergyborder": "1", "comboenergysmooth": "1",
    "comboenergyauthide": "0", "comboenergyhidetime": "0.3",
    "comboenergyhidecombat": "1", "comboenergyhidefull": "0",
    "comboenergydruidmana": "0", "comboenergydruidmanaheight": "6",
    "comboenergytexture": "solid", "comboenergycolor": "1,1,0,1",
    "comboenergybgcolor": "0,0,0,0.4", "comboenergytextcolor": "1,1,1,1",
    "manacolor": "0.5,0.5,1,1", "ragecolor": "1,0,0,1", "energycolor": "1,1,0,1",
    # If copied upstream layout code accidentally returns, this enables its
    # side effects and makes the preservation assertions fail immediately.
    "bottomalign": "1", "comboenergyshift": "20",
}


class Harness:
    def __init__(self, enabled=False, failed_font=False, druid=False, config=None):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        install = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        install(self.lua.globals().methods, self.lua.globals().object)
        self.lua.execute('''
        local strictSetText=methods.SetText
        function methods:SetText(v)
          strictSetText(self,v);self.calls.text=(self.calls.text or 0)+1
        end
        ''')
        cfg = dict(DEFAULTS)
        cfg["comboenergyshow"] = "1" if enabled else "0"
        cfg.update(config or {})
        for k, v in cfg.items():
            self.lua.globals().C.unitframes[k] = v
        if failed_font:
            self.lua.execute("failedFontPaths['Configured.ttf']=true")
        if druid:
            self.lua.execute("classToken='DRUID';powerType=3;resource=40;maximum=100")
        self.lua.execute("pfUI.api={};pfUI.movables={};pfUI_config=C;C.global={offscreen='0'}")
        api = (ARGS.addons / "pfUI/api/api.lua").read_text(encoding="utf-8-sig")
        # Load the current personal implementation verbatim: caching defaults
        # and restoring saved anchors are part of this integration contract.
        self.lua.execute(api[api.index("function pfUI.api.LoadMovable("):api.index("-- [ Save Movable ]")])
        self.lua.execute("LoadMovable=pfUI.api.LoadMovable")
        self.lua.execute(api[api.index("function pfUI.api.UpdateMovable("):api.index("-- [ CreateShareListDialog ]")])
        self.lua.execute((ARGS.addons / "pfUI/modules/energybar.lua").read_text(encoding="utf-8-sig"))

    @property
    def module(self):
        return self.lua.globals().pfUI.energybar

    @property
    def frame(self):
        return self.lua.globals().pfEnergyBar

    def execute(self, code):
        return self.lua.execute(code)

    def eval(self, code):
        return self.lua.eval(code)

    def advance(self, seconds, fps=60):
        self.lua.globals().advance(seconds, fps)

    def update(self, **config):
        for k, v in config.items():
            self.lua.globals().C.unitframes[k] = v
        self.module.UpdateConfig(self.module)

    def unchanged(self):
        self.execute("otherFramesUnchanged()")

    def fill(self):
        return self.frame.fill

    def main_text(self):
        return self.frame.text

    def tick(self):
        return self.frame.tick

    def mana_frame(self):
        return self.frame.manaBar


class EnergyBar(unittest.TestCase):
    def test_text_line_boxes_are_vertically_centered_at_all_alignments(self):
        h = Harness(enabled=True, druid=True, config={"comboenergydruidmana": "1"})
        for height in (6, 12, 18, 32):
            for size in (8, 12, 20):
                for align in ("left", "center", "right"):
                    h.update(comboenergyheight=str(height), comboenergyfontsize=str(size),
                             comboenergydruidmanaheight=str(height), comboenergytextalign=align)
                    h.advance(.15)
                    for text, owner in ((h.main_text(), h.frame),
                                        (h.mana_frame().text, h.mana_frame())):
                        self.assertEqual(text.justifyV, "MIDDLE")
                        self.assertEqual(text.justifyH, align.upper())
                        self.assertEqual(text.point[5], 0)
                        self.assertTrue(h.lua.eval('function(a,b) return a==b end')(text.point[2], owner))
                        self.assertAlmostEqual(text.GetWidth(text), owner.GetWidth(owner) - 10)
                        self.assertGreaterEqual(text.GetHeight(text), max(height, size + 4))
                        self.assertIsNotNone(text.font)
                    self.assertIsNone(h.frame.textshadow, "duplicate half-pixel text shadow remains")
        h.unchanged()

    def test_automatic_resource_colors_ignore_the_avatar_pastel_theme(self):
        h = Harness(enabled=True)
        colors = {0: (0, 0, 1), 1: (1, 0, 0), 2: (1, .5, .25),
                  3: (1, 1, 0), 4: (0, 1, 1)}
        old_mana = h.eval("C.unitframes.manacolor")
        for power, expected in colors.items():
            h.execute(f"powerType={power};resource=40;maximum=100")
            h.advance(.05)
            self.assertEqual(tuple(h.fill().texture[i] for i in (1, 2, 3)), expected)
            self.assertEqual(h.fill().texture[4], 1)
        self.assertEqual(h.eval("C.unitframes.manacolor"), old_mana)
        h.update(comboenergytexture="Media/Bar.tga")
        for power, expected in colors.items():
            h.execute(f"powerType={power}")
            h.advance(.05)
            self.assertEqual(tuple(h.fill().color[i] for i in (1, 2, 3)), expected)
        h.unchanged()

    def test_native_palette_and_druid_mana_color_preserve_manual_main_color(self):
        h = Harness(enabled=True, druid=True, config={"comboenergydruidmana": "1"})
        h.execute("ManaBarColor={[0]={r=.125,g=.25,b=.875},[3]={r=.9,g=.8,b=.1}}")
        h.update(comboenergytexture="Media/Bar.tga")
        h.advance(.15)
        self.assertEqual(tuple(h.fill().color[i] for i in (1, 2, 3)), (.9, .8, .1))
        self.assertEqual(tuple(h.mana_frame().fill.color[i] for i in (1, 2, 3)), (.125, .25, .875))
        h.update(comboenergyautocolor="0", comboenergycolor="0.2,0.4,0.6,0.7")
        h.advance(.15)
        self.assertEqual(tuple(h.fill().color[i] for i in (1, 2, 3, 4)), (.2, .4, .6, .7))
        self.assertEqual(tuple(h.mana_frame().fill.color[i] for i in (1, 2, 3)), (.125, .25, .875))
        h.execute("PowerBarColor=ManaBarColor;ManaBarColor=nil")
        h.update(comboenergyautocolor="1")
        h.advance(.15)
        self.assertEqual(tuple(h.fill().color[i] for i in (1, 2, 3)), (.9, .8, .1))
        h.unchanged()

    def test_font_mock_rejects_uninitialized_text(self):
        h = Harness()
        with self.assertRaises(LuaError):
            h.execute("object('FontString'):SetText('uninitialized')")

    def test_default_disabled_does_not_read_resources_or_write_positions(self):
        h = Harness()
        h.advance(2, 120)
        h.execute("""
        for k,v in pairs(reads) do assert(v==0,'disabled resource read: '..k) end
        assert(pfEnergyBar==nil and #movables==0)
        for _,o in ipairs(objects) do assert(not o.scripts.OnUpdate,'disabled driver remains attached') end
        otherFramesUnchanged()
        """)
        h.module.UpdateConfig(h.module)
        h.module.RefreshLayout(h.module)
        h.execute("for k,v in pairs(reads) do assert(v==0,'disabled refresh read: '..k) end")

    def test_enable_disable_reuse_unlock_only_manages_own_frame(self):
        h = Harness()
        h.update(comboenergyshow="1")
        frame = h.frame
        self.assertIsNotNone(frame)
        h.advance(.05)
        h.execute("pfUI.unlock:Show()")
        h.advance(.05)
        h.module.RefreshLayout(h.module)
        h.execute("pfUI.unlock:Hide()")
        h.advance(.05)
        h.unchanged()
        h.update(comboenergyshow="0")
        h.execute("for _,o in ipairs(objects) do assert(not o.scripts.OnUpdate,'disabled driver remains attached') end")
        reads = h.eval("reads.mana+reads.maxmana+reads.power+reads.field+reads.exists+reads.phase")
        h.advance(.5)
        self.assertEqual(h.eval("reads.mana+reads.maxmana+reads.power+reads.field+reads.exists+reads.phase"), reads)
        self.assertFalse(h.frame.IsShown(h.frame))
        h.execute("objectCount=#objects")
        h.update(comboenergyshow="1")
        h.advance(.05)
        self.assertEqual(h.eval("#objects"), h.eval("objectCount"))
        h.unchanged()

    def test_config_refresh_changes_own_geometry_and_text(self):
        h = Harness(enabled=True)
        h.advance(.05)
        h.update(comboenergywidth="280", comboenergyheight="18", comboenergyfontsize="15",
                 comboenergytextformat="1", comboenergytextalign="right", comboenergytexture="Media/Bar.tga")
        h.advance(.05)
        self.assertEqual(h.frame.GetWidth(h.frame), 280)
        self.assertEqual(h.frame.GetHeight(h.frame), 18)
        self.assertEqual(h.main_text().GetText(h.main_text()), "6000/6000")
        self.assertEqual(h.main_text().font[2], 15)
        self.assertEqual(h.main_text().point[1], "RIGHT")
        self.assertEqual(h.fill().GetTexture(h.fill()), "Media/Bar.tga")
        h.unchanged()

    def test_width_fallback_and_saved_position_do_not_follow_combo_layout(self):
        h = Harness()
        h.execute("C.position.pfEnergyBar={xpos=310,ypos=420};pfCombo1.width=777")
        for width in ("0", "-9", "invalid"):
            h.update(comboenergyshow="1", comboenergywidth=width,
                     comboenergyoffx="999", comboenergyoffy="888")
            h.advance(.05)
            self.assertEqual(h.frame.GetWidth(h.frame), 214.5)
            h.execute("""
            local anchor,parent,relative,x,y=pfEnergyBar:GetPoint()
            assert(anchor=='TOPLEFT' and x==310 and y==420,'saved anchor lost')
            assert(pfEnergyBar.posdata.pos[1][1]=='BOTTOM','reset default missing')
            assert(pfEnergyBar.posdata.pos[1][4]==999 and pfEnergyBar.posdata.pos[1][5]==888)
            assert(C.position.pfEnergyBar.xpos==310 and C.position.pfEnergyBar.ypos==420)
            otherFramesUnchanged()
            """)
        h.execute("C.position.pfEnergyBar=nil;LoadMovable(pfEnergyBar)")
        h.execute("local anchor,_,_,x,y=pfEnergyBar:GetPoint();assert(anchor=='BOTTOM' and x==999 and y==888)")

    def test_live_default_offset_changes_and_saved_position_reset(self):
        h = Harness(enabled=True)
        h.execute("local a,p,r,x,y=pfEnergyBar:GetPoint();assert(a=='BOTTOM' and p==UIParent and r=='BOTTOM' and x==0 and y==278)")
        h.update(comboenergyoffx="15", comboenergyoffy="298")
        h.execute("""
        local a,p,r,x,y=pfEnergyBar:GetPoint()
        assert(a=='BOTTOM' and p==UIParent and r=='BOTTOM' and x==15 and y==298,'GUI offset reverted by posdata')
        C.position.pfEnergyBar={anchor='TOPLEFT',xpos=50,ypos=60,scale=.9,parent='UIParent'}
        """)
        h.update(comboenergyoffx="20", comboenergyoffy="308")
        h.execute("""
        local a,_,_,x,y=pfEnergyBar:GetPoint();assert(a=='TOPLEFT' and x==50 and y==60)
        assert(pfEnergyBar:GetScale()==.9)
        C.position.pfEnergyBar=nil
        LoadMovable(pfEnergyBar)
        local a,p,r,x,y=pfEnergyBar:GetPoint()
        assert(a=='BOTTOM' and p==UIParent and r=='BOTTOM' and x==20 and y==308,'reset default lost')
        otherFramesUnchanged()
        """)

    def test_shared_energy_phase_accepts_zero_and_has_no_private_fallback(self):
        h = Harness(enabled=True)
        h.execute("powerType=3;resource=40;maximum=100;sharedPhase=nil;combat=true")
        h.advance(3)
        self.assertFalse(h.tick().IsShown(h.tick()))
        self.assertGreater(h.eval("reads.phase"), 0)
        h.execute("sharedPhase=0")
        h.advance(.05)
        self.assertTrue(h.tick().IsShown(h.tick()))
        h.execute("sharedPhase=.5")
        h.advance(.05)
        self.assertTrue(h.tick().IsShown(h.tick()))
        self.assertAlmostEqual(h.frame.spark.point[4], 92, places=3)
        for phase in ("-1", "2", "0/0", "'0.5'"):
            h.execute(f"sharedPhase={phase}")
            h.advance(.05)
            self.assertFalse(h.tick().IsShown(h.tick()))
        h.execute("pfUI.energytick.EnergyProgress=function() error('provider unavailable') end")
        h.advance(.05)
        self.assertFalse(h.tick().IsShown(h.tick()))
        h.execute("pfUI.energytick.EnergyProgress=function() reads.phase=reads.phase+1;return sharedPhase end")
        for ptype in (0, 1):
            h.execute(f"powerType={ptype};sharedPhase=.5;phaseBefore=reads.phase")
            h.advance(.2)
            self.assertFalse(h.tick().IsShown(h.tick()))
            self.assertEqual(h.eval("reads.phase"), h.eval("phaseBefore"))
        h.execute("powerType=3;pfUI.energytick=nil")
        h.advance(3)
        self.assertFalse(h.tick().IsShown(h.tick()))

    def test_6000_to_5400_smooths_quickly_and_text_uses_actual_resource(self):
        h = Harness(enabled=True)
        h.advance(.05)
        h.execute("resource=5400")
        h.advance(.033334)
        self.assertEqual(h.main_text().GetText(h.main_text()), "5400")
        h.advance(.05)
        self.assertGreaterEqual(h.fill().GetWidth(h.fill()), 180)
        self.assertLess(h.fill().GetWidth(h.fill()), 200)
        h.advance(.15)
        self.assertAlmostEqual(h.fill().GetWidth(h.fill()), 180, places=3)

    def test_real_energytick_events_supply_shared_phase_with_avatar_spark_disabled(self):
        h = Harness(enabled=True, druid=True)
        h.execute("""
        C.unitframes.player={energy='0',manatick='0',pheight='10',pwidth='-1',width='200'}
        pfUI.uf.player.power={bar=CreateFrame('Frame',nil,pfUI.uf.player)}
        pfUI.uf.player.UpdateConfig=function(self)
          assert(self==pfUI.uf.player);playerConfigUpdates=(playerConfigUpdates or 0)+1
        end
        """)
        # Load the complete current calibrator, replacing the stub provider.
        h.execute((ARGS.addons / "pfUI/modules/energytick.lua").read_text(encoding="utf-8-sig"))
        h.execute("""
        pfUI.uf.player.UpdateConfig()
        assert(playerConfigUpdates==1,'existing player configuration hook lost')
        dispatchEvent('PLAYER_ENTERING_WORLD')
        assert(pfUI.energytick:EnergyProgress()==nil,'uncalibrated phase invented')
        assert(not pfUI.energytick:IsShown(),'avatar energy option ignored')
        """)
        h.advance(.1)
        self.assertFalse(h.tick().IsShown(h.tick()))
        h.execute("""
        resource=60
        dispatchEvent('UNIT_ENERGY','player')
        sharedAnchor=pfUI.energytick.anchorMS
        assert(sharedAnchor==GetTime()*1000,'natural +20 failed to calibrate')
        assert(not pfUI.energytick:IsShown(),'calibration unexpectedly enabled avatar spark')
        """)
        h.advance(.2)
        self.assertTrue(h.tick().IsShown(h.tick()))
        phase = h.eval("pfUI.energytick:EnergyProgress()")
        self.assertGreater(phase, 0)
        self.assertAlmostEqual(h.frame.spark.point[4], 200 * phase - 8, places=5)
        h.execute("""
        phaseBeforeInstant=pfUI.energytick:EnergyProgress()
        resource=100
        dispatchEvent('UNIT_ENERGY','player')
        assert(pfUI.energytick.anchorMS==sharedAnchor,'instant +40 moved shared anchor')
        assert(pfUI.energytick:EnergyProgress()==phaseBeforeInstant,'instant +40 reset phase')
        assert(reads.phase==0,'stub provider was still used')
        """)
        h.advance(.2)
        phase = h.eval("pfUI.energytick:EnergyProgress()")
        self.assertAlmostEqual(h.frame.spark.point[4], 200 * phase - 8, places=5)
        h.execute("""
        powerType=0;resource=4300;maximum=6000
        dispatchEvent('UNIT_DISPLAYPOWER','player')
        dispatchEvent('UNIT_MANA','player')
        assert(pfUI.energytick.mode=='MANA' and pfUI.energytick:EnergyProgress()==nil)
        """)
        h.advance(.05)
        self.assertFalse(h.tick().IsShown(h.tick()))
        h.unchanged()

    def test_shape_and_maximum_switch_reset_displayed_value(self):
        h = Harness(enabled=True)
        h.advance(.05)
        h.execute("resource=5400")
        h.advance(.033334)
        h.execute("powerType=3;resource=40;maximum=100")
        h.advance(.033334)
        self.assertAlmostEqual(h.fill().GetWidth(h.fill()), 80, places=3)
        self.assertEqual(h.main_text().GetText(h.main_text()), "40")
        h.execute("resource=50;maximum=200")
        h.advance(.033334)
        self.assertAlmostEqual(h.fill().GetWidth(h.fill()), 50, places=3)

    def test_main_and_mana_font_failure_keep_valid_fallbacks(self):
        h = Harness(enabled=True, failed_font=True, druid=True,
                    config={"comboenergydruidmana": "1"})
        h.advance(.15)
        self.assertTrue(h.mana_frame().IsShown(h.mana_frame()))
        self.assertEqual(h.mana_frame().text.GetText(h.mana_frame().text), "4300")
        self.assertAlmostEqual(h.mana_frame().fill.GetWidth(h.mana_frame().fill), 200 * 4300 / 6000, places=3)
        h.execute("""
        for _,o in ipairs(objects) do if o.kind=='FontString' then
          assert(o.font,'uninitialized font');o:SetText('');o:Hide();o:SetText('hidden');o:Show();o:SetText('reused')
        end end
        """)
        h.update(comboenergyshowtext="0")
        h.advance(.15)
        h.update(comboenergyshowtext="1")
        h.advance(.15)

    def test_druid_mana_hidden_when_unavailable_or_not_shapeshifted(self):
        h = Harness(enabled=True, druid=True, config={"comboenergydruidmana": "1"})
        h.advance(.15)
        self.assertTrue(h.mana_frame().IsShown(h.mana_frame()))
        h.execute("savedGetUnitField=GetUnitField;GetUnitField=function() error('field unavailable') end")
        h.advance(.2)
        self.assertFalse(h.mana_frame().IsShown(h.mana_frame()))
        h.execute("GetUnitField=savedGetUnitField;baseManaMax=0")
        h.advance(.2)
        self.assertFalse(h.mana_frame().IsShown(h.mana_frame()))
        h.execute("baseManaMax=6000")
        h.advance(.2)
        self.assertTrue(h.mana_frame().IsShown(h.mana_frame()))
        h.execute("GetUnitField=nil")
        h.advance(.2)
        self.assertFalse(h.mana_frame().IsShown(h.mana_frame()))
        h.execute("powerType=0;resource=4300;maximum=6000")
        h.advance(.15)
        self.assertFalse(h.mana_frame().IsShown(h.mana_frame()))
        absent = Harness(druid=True, config={"comboenergydruidmana": "1"})
        absent.execute("GetUnitField=nil")
        absent.update(comboenergyshow="1")
        absent.advance(.2)
        self.assertFalse(absent.mana_frame().IsShown(absent.mana_frame()))

    def test_combat_option_full_resource_and_hide_delay(self):
        h = Harness(enabled=True, config={"comboenergyauthide": "1", "comboenergyhidefull": "1"})
        h.execute("combat=true")
        h.advance(1)
        self.assertAlmostEqual(h.frame.GetAlpha(h.frame), 1)
        h.update(comboenergyhidecombat="0")
        h.advance(.2)
        self.assertGreater(h.frame.GetAlpha(h.frame), .95)
        h.advance(.5)
        self.assertLess(h.frame.GetAlpha(h.frame), .01)
        h.update(comboenergyhidefull="0")
        h.advance(.4)
        self.assertGreater(h.frame.GetAlpha(h.frame), .95)
        h.update(comboenergyhidefull="1")
        h.advance(1)
        self.assertLess(h.frame.GetAlpha(h.frame), .01)
        h.execute("pfUI.unlock:Show()")
        h.advance(.05)
        self.assertEqual(h.frame.GetAlpha(h.frame), 1)
        h.execute("pfUI.unlock:Hide()")
        h.update(comboenergyauthide="0")
        h.advance(1)
        self.assertEqual(h.frame.GetAlpha(h.frame), 1)

    def test_optional_all_power_tick_text_and_smoothing_switches(self):
        h = Harness(enabled=True, config={"comboenergyallpower": "0"})
        h.advance(.1)
        self.assertFalse(h.frame.IsShown(h.frame))
        h.execute("powerType=3;resource=40;maximum=100;sharedPhase=.5")
        h.advance(.05)
        self.assertTrue(h.frame.IsShown(h.frame))
        h.update(comboenergyshowtick="0", comboenergyshowtext="0", comboenergysmooth="0")
        h.advance(.05)
        self.assertFalse(h.tick().IsShown(h.tick()))
        self.assertFalse(h.main_text().IsShown(h.main_text()))
        self.assertEqual(h.main_text().GetText(h.main_text()), "")
        h.execute("resource=20")
        h.advance(.033334)
        self.assertAlmostEqual(h.fill().GetWidth(h.fill()), 40, places=3)
        h.update(comboenergyshowtext="1", comboenergytextformat="2")
        h.advance(.05)
        self.assertEqual(h.main_text().GetText(h.main_text()), "20%")

    def test_fade_duration_is_consistent_at_30_60_120_fps(self):
        samples = []
        for rate in (30, 60, 120):
            h = Harness(enabled=True, config={"comboenergyauthide": "1", "comboenergyhidefull": "1",
                                             "comboenergyhidetime": "0.2"})
            h.advance(.32, rate)
            middle = h.frame.GetAlpha(h.frame)
            h.advance(.25, rate)
            self.assertLess(h.frame.GetAlpha(h.frame), .01)
            samples.append(middle)
        self.assertLess(max(samples) - min(samples), .18)
        self.assertTrue(all(.1 < value < .9 for value in samples), samples)

    def test_resource_sampling_and_stable_text_are_throttled(self):
        h = Harness(enabled=True, druid=True, config={"comboenergydruidmana": "1"})
        h.advance(.25, 120)
        h.execute("manaBefore=reads.mana;fieldBefore=reads.field;writesBefore=0;for _,o in ipairs(objects) do writesBefore=writesBefore+(o.calls.text or 0) end")
        h.advance(1, 120)
        self.assertLessEqual(h.eval("reads.mana-manaBefore"), 52)
        # Two scalar fields per .1 s collection, with one boundary allowance.
        self.assertLessEqual(h.eval("reads.field-fieldBefore"), 22)
        self.assertEqual(h.eval("(function() local n=0;for _,o in ipairs(objects) do n=n+(o.calls.text or 0) end;return n end)()"), h.eval("writesBefore"))


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]] + REMAINING, verbosity=2)
