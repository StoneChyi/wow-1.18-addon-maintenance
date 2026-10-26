"""EavesDrop settings/skin regression checks with the strict 1.12 font contract.

Loads the actual options.lua and ui.lua. No game process, saved settings, or DLLs
are loaded or modified. The ignored Lua 5.1 runtime is shared with other tests.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

STUB = r'''
local installFontContract = ...
objects={}; names={}; UISpecialFrames={}; active=true; historyState={reading=false}
local methods={}
function object(kind,name,parent)
 local obj=setmetatable({kind=kind,name=name,parent=parent,width=200,height=200,
  shown=true,alpha=1,scripts={},points={},textColor={1,1,1,1}}, {__index=methods})
 table.insert(objects,obj)
 if name then _G[name]=obj; names[name]=obj end
 return obj
end
function CreateFrame(kind,name,parent) return object(kind,name,parent) end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:GetParent() return self.parent end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) table.insert(self.points,{...}) end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetMovable(v) self.movable=v end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetClampedToScreen(v) self.clamped=v end
function methods:RegisterForDrag(...) self.drag={...} end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end
function methods:Hide() self.shown=false end
function methods:Show() self.shown=true end
function methods:IsShown() return self.shown end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:SetBackdropBorderColor(...) self.border={...} end
function methods:SetTextColor(...) self.textColor={...} end
function methods:GetTextColor() return unpack(self.textColor) end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:SetJustifyH(v) self.justify=v end
function methods:SetOrientation(v) self.orientation=v end
function methods:SetThumbTexture(v) self.thumb=object('Texture',nil,self); self.thumb.path=v end
function methods:GetThumbTexture() return self.thumb end
function methods:SetVertexColor(...) self.vertex={...} end
function methods:SetTexCoord(...) self.texcoords={...} end
function methods:SetNormalTexture(v) self.normal=v end
function methods:SetPushedTexture(v) self.pushed=v end
function methods:SetHighlightTexture(v) self.highlight=v end
function methods:GetNormalTexture() return type(self.normal)=='table' and self.normal or nil end
function methods:GetPushedTexture() return type(self.pushed)=='table' and self.pushed or nil end
function methods:GetFontString() return self.captionObject end
function methods:SetAutoFocus(v) self.autofocus=v end
function methods:SetTextInsets(...) self.insets={...} end
function methods:ClearFocus() self.focused=false end
function methods:GetText() return self.text or '' end
function methods:SetMinMaxValues(low,high) self.low,self.high=low,high end
function methods:SetValueStep(v) self.step=v end
function methods:GetValue() return self.value or 0 end
function methods:SetValue(v)
 self.value=v
 if self.scripts.OnValueChanged then invoke(self,'OnValueChanged') end
end
function methods:SetOwner(...) self.owner={...} end
function invoke(obj,script)
 local old=this; this=obj
 if obj.scripts[script] then obj.scripts[script]() end
 this=old
end
installFontContract(methods,object)
UIParent=object('Frame','UIParent')
GameTooltip=object('GameTooltip','GameTooltip',UIParent)
function getglobal(name) return _G[name] end
local L=setmetatable({}, {__index=function(t,k)return k end})
AceLibrary=setmetatable({HasInstance=function()return true end}, {__call=function(_,name)
 return {new=function()return L end,Open=function()legacyOpened=true end}
end})
EavesDrop={}
function EavesDrop:IsActive() return active end
function EavesDrop:ToggleActive(v) active=v; if v then EavesDropFrame:Show() else EavesDropFrame:Hide() end end
function EavesDrop:UpdateEvents() self.eventUpdates=(self.eventUpdates or 0)+1 end
function EavesDrop:UpdateScrollButtons() end
function EavesDrop:PerformDisplayOptions() self.displayUpdates=(self.displayUpdates or 0)+1 end
function EavesDrop:RefreshCombatSources() self.sourceRefresh=(self.sourceRefresh or 0)+1 end
function EavesDrop:ResizeHistory() self.resize=(self.resize or 0)+1 end
function EavesDrop:RefreshProfile() self.profileRefresh=(self.profileRefresh or 0)+1 end
function EavesDrop:GetProfile() return self.currentProfile or 'Default' end
function EavesDrop:SetProfile(name) self.currentProfile=name end
function EavesDrop:Reset() self.resets=(self.resets or 0)+1 end
function EavesDrop:ScrollToBottom() historyState.reading=false; self:UpdateReadIndicator(0,false) end
function EavesDrop:GetHistoryState() return historyState end
function EavesDrop:GetCombatSourceStatus() return '增强：伤害/治疗；文字：其他' end
for _,name in ipairs({'EavesDropFrame','EavesDropHistoryFrame','EavesDropTab',
 'EavesDropHistoryButton','EavesDropHistoryFrameOutgoingHit','EavesDropHistoryFrameOutgoingHeal',
 'EavesDropHistoryFrameIncomingHit','EavesDropHistoryFrameIncomingHeal','EavesDropHistoryFrameReset',
 'EavesDropHistoryFrameClose','EavesDropFrameUpButton','EavesDropFrameDownButton'}) do
 object('Button',name,UIParent)
end
for _,name in ipairs({'EavesDropTopBar','EavesDropBottomBar','EavesDropHistoryTopBar',
 'EavesDropHistoryBottomBar','EavesDropTabLeft','EavesDropTabMiddle','EavesDropTabRight'}) do
 object('Texture',name,EavesDropFrame)
end
for _,name in ipairs({'EavesDropTabText','EavesDropFramePlayerText','EavesDropFrameTargetText',
 'EavesDropHistoryFrameSkillText','EavesDropHistoryFrameAmountCritText','EavesDropHistoryFrameAmountNormalText'}) do
 local t=object('FontString',name,EavesDropFrame); t:SetFontObject(GameFontNormal)
end
for i=1,20 do
 local t=object('FontString','EavesDropEvent'..i..'EventText',EavesDropFrame)
 t:SetFontObject(GameFontNormal)
end
for i=1,10 do for _,suffix in ipairs({'_Skill','_Hit','_Crit'}) do
 local t=object('FontString','EavesDropHistoryEvent'..i..suffix,EavesDropHistoryFrame)
 t:SetFontObject(GameFontNormal)
end end
ColorPickerFrame=object('Frame','ColorPickerFrame',UIParent)
OpacitySliderFrame=object('Slider','OpacitySliderFrame',UIParent)
function ColorPickerFrame:SetColorRGB(r,g,b) self.rgb={r,g,b}; if self.func then self.func() end end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb or {1,1,1}) end
'''

CHECKS = r'''
EavesDrop:SetupOptions()
EavesDrop.db={profile=EavesDrop:GetDefaultConfig()}
EavesDrop.db.profile.SETTINGALPHA=.95
EavesDrop.db.profile.HISTORYLIMIT=512
EavesDrop:OpenSettings()
local panel=EavesDropSettingsFrame
assert(panel:IsShown() and panel:GetWidth()==610 and panel:GetHeight()==540)
assert(EavesDropFrame.bg[4]==EavesDrop.db.profile.FRAME.a)
local originalObjects=table.getn(objects)
local originalColor={.2,.4,.6,.8}
EavesDropFramePlayerText:SetTextColor(unpack(originalColor))
-- Visit all pages (and overflow pages): hidden/reused controls must also have fonts.
for pass=1,2 do
 for tab=1,5 do
  invoke(panel.nav[tab],'OnClick')
  for n=1,4 do
   for _,row in ipairs(panel.rows) do
    if row:IsShown() then
     assert(row.label.font)
     if row.option.type=='color' then invoke(row.action,'OnClick'); assert(ColorPickerFrame:IsShown()); ColorPickerFrame.cancelFunc() end
    end
   end
   invoke(panel.next,'OnClick')
  end
 end
end
assert(table.getn(objects)==originalObjects,'settings recreates controls while paging')
assert(EavesDropFramePlayerText.textColor[1]==.2,'skin reset existing text colors')
print('PASS all settings pages, pagination, color cancellation, reuse and existing text colors')

-- Monitor switch is intentionally usable even while the monitor itself is off.
invoke(panel.enabled,'OnClick'); assert(not active and not EavesDropFrame:IsShown())
panel:Hide(); EavesDrop:OpenSettings(); assert(panel:IsShown() and not active)
invoke(panel.enabled,'OnClick'); assert(active and EavesDropFrame:IsShown())
print('PASS disabled monitor can reopen settings and re-enable')

-- Alpha affects only backgrounds, never the entire settings frame or its text.
for _,alpha in ipairs({0,.35,1}) do
 EavesDrop.db.profile.FRAME.a=alpha; EavesDrop.db.profile.SETTINGALPHA=alpha
 EavesDrop:ApplySkin()
 assert(EavesDropFrame.bg[4]==alpha and EavesDropHistoryFrame.bg[4]==alpha and panel.bg[4]==alpha)
 assert(panel:GetAlpha()==1 and panel.title:GetAlpha()==1 and panel.enabled:GetAlpha()==1)
end
invoke(panel.nav[1],'OnClick')
panel.rows[1].slider:SetValue(.4)
assert(math.abs(EavesDrop.db.profile.FRAME.a-.4)<.00001)
panel.rows[2].slider:SetValue(.25)
assert(math.abs(EavesDrop.db.profile.SETTINGALPHA-.25)<.00001)
print('PASS transparency endpoints and live sliders preserve control opacity')

historyState.reading=true
EavesDrop:UpdateReadIndicator(0,false)
assert(EavesDrop.readIndicator:IsShown(),'empty-unseen reading indicator was hidden')
EavesDrop:UpdateReadIndicator(129,true)
assert(string.find(EavesDrop.readIndicator.caption.text,'129'))
invoke(EavesDrop.readIndicator,'OnClick')
assert(not historyState.reading and not EavesDrop.readIndicator:IsShown())
print('PASS reading snapshot indicator and return-to-latest action')

invoke(panel.nav[4],'OnClick')
invoke(panel.rows[1].action,'OnClick')
assert(EavesDrop.db.profile.DATASOURCE=='legacy' and EavesDrop.sourceRefresh==1)
panel.rows[2].slider:SetValue(1024)
assert(EavesDrop.db.profile.HISTORYLIMIT==1024 and EavesDrop.resize==1)
invoke(panel.nav[5],'OnClick')
panel.rows[1].edit:SetText('  Healer  '); invoke(panel.rows[1].apply,'OnClick')
assert(EavesDrop.currentProfile=='Healer' and EavesDrop.profileRefresh==1)
invoke(panel.rows[3].action,'OnClick'); assert(not EavesDrop.resets)
invoke(panel.rows[3].action,'OnClick'); assert(EavesDrop.resets==1)
print('PASS source/capacity callbacks, trimmed profile name, reset confirmation')
'''


def scenario(mode):
    lua = LuaRuntime(unpack_returned_tuples=True)
    install = lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
    lua.execute(STUB, install)
    if mode != "no-pfui":
        lua.execute(r'''
pfUI={font_default='MissingCustomFont.ttf',api={}}
function pfUI.api.CreateBackdrop(frame,inset,legacy,alpha)
 assert(inset==1 and legacy==true,'wrong 1.12 pfUI backdrop signature')
 frame.pfSkinCalls=(frame.pfSkinCalls or 0)+1
end
''')
        if mode == "failed-font":
            lua.execute("failedFontPaths['MissingCustomFont.ttf']=true")
        elif mode == "failed-api":
            lua.execute("function pfUI.api.CreateBackdrop() error('unavailable skin API') end")
    lua.execute((ROOT / "Interface/AddOns/EavesDrop/options.lua").read_text(encoding="utf-8-sig"))
    lua.execute((ROOT / "Interface/AddOns/EavesDrop/ui.lua").read_text(encoding="utf-8-sig"))
    lua.execute(CHECKS)
    lua.execute(r'''
for _,obj in ipairs(objects) do
 if obj.kind=='FontString' then
  assert(obj.font and obj.font[1],'uninitialized visible/hidden FontString')
  if failedFontPaths['MissingCustomFont.ttf'] then assert(obj.font[1]~='MissingCustomFont.ttf') end
 end
end
''')
    print(f"PASS strict font lifecycle: {mode}", flush=True)


if __name__ == "__main__":
    for mode in ("no-pfui", "with-pfui", "failed-font", "failed-api"):
        scenario(mode)
    print("EavesDrop UI: 4 runtime configurations passed (game verification still required).")
