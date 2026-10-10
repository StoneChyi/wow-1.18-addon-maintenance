"""Cat judgement-panel strike control: real Lua 5.1 UI and rotation regressions."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
for path in [ROOT / 'addons_tmp/bcs-test-runtime', Path.home() / 'Documents/Codex/2026-10-05/nik/work/cat-ret-tests/deps']:
    sys.path.insert(0, str(path))
from lupa.lua51 import LuaRuntime

STUB = r'''
local installFontContract = ...
local methods = {}
objects = {}
local noop = function() end
function NewObject(kind, name, parent, layer)
    local o = {kind=kind,name=name,parent=parent,layer=layer,alpha=1,shown=true,children={},regions={},scripts={}}
    setmetatable(o, {__index=function(t,k)
        if methods[k] then return methods[k] end
        if string.find(k,'^Set') or string.find(k,'^Enable') or string.find(k,'^Register')
           or string.find(k,'^Start') or string.find(k,'^Stop') or string.find(k,'^Clear') then return noop end
    end})
    table.insert(objects,o)
    if name then _G[name]=o end
    if parent and kind~='Texture' and kind~='FontString' then table.insert(parent.children,o) end
    return o
end
function methods:GetObjectType() return self.kind end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:GetChildren() return unpack(self.children) end
function methods:GetRegions() return unpack(self.regions) end
function methods:GetPoint() if self.point then return unpack(self.point) end end
function methods:SetPoint(...) self.point={unpack(arg)} end
function methods:SetWidth(value) self.width=value end
function methods:SetHeight(value) self.height=value end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetAlpha(value) self.alpha=value end
function methods:GetAlpha() return self.alpha end
function methods:SetScale(value) self.scale=value end
function methods:GetScale() return self.scale end
function methods:Show()
    local wasShown=self.shown
    self.shown=true
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow() end
end
function methods:Hide() self.shown=false end
function methods:IsVisible() return self.shown end
function methods:SetTexture(value) self.texture=value end
function methods:GetTexture() return self.texture end
function methods:SetDrawLayer(value) self.layer=value end
function methods:SetVertexColor(r,g,b) self.color={r,g,b} end
function methods:SetTexCoord(...) self.texcoord={unpack(arg)} end
function methods:SetScript(name,callback) self.scripts[name]=callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:GetCheckedTexture() return nil end
function methods:SetText(text) self.textvalue=text end
function methods:GetText() return self.text end
function methods:SetChecked(value) self.checked=value==true or value==1 end
function methods:GetChecked() if self.checked then return 1 end end
function methods:SetMinMaxValues(low,high) self.low=low; self.high=high end
function methods:SetValue(value)
    self.value=math.max(self.low,math.min(self.high,value))
    if self.scripts.OnValueChanged then
        local oldThis,oldArg=this,arg1
        this=self; arg1=self.value
        self.scripts.OnValueChanged()
        this=oldThis; arg1=oldArg
    end
end
function methods:GetValue() return self.value end
function methods:CreateTexture(name,layer)
    local t=NewObject('Texture',name,self,layer); table.insert(self.regions,t); return t
end
function methods:CreateFontString(name,layer)
    local t=NewObject('FontString',name,self,layer); table.insert(self.regions,t); return t
end
installFontContract(methods, NewObject)
local createText=methods.CreateFontString
function methods:CreateFontString(name,layer,template)
    if template=='GameFontNormalSmall' then template='GameFontNormal' end
    local f=createText(self,name,layer,template)
    table.insert(self.regions,f)
    return f
end
function methods:SetHighlightTexture(path)
    self.highlightTexture=self:CreateTexture(nil,'HIGHLIGHT'); self.highlightTexture:SetTexture(path)
end
function methods:GetHighlightTexture() return self.highlightTexture end
function methods:SetPushedTexture(path)
    self.pushedTexture=self:CreateTexture(nil,'ARTWORK'); self.pushedTexture:SetTexture(path)
end
function methods:GetPushedTexture() return self.pushedTexture end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:GetBackdropColor() return unpack(self.bg or {0.1,0.1,0.2,0.7}) end
function methods:SetTextColor(...) self.textColor={...} end
function methods:GetEffectiveScale() return (self.scale or 1)*(self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetLeft() return self.point and (self.point[4] or 0) or 0 end
function methods:GetTop() return self.point and (self.point[5] or 0) or 0 end
function methods:ClearAllPoints() self.point=nil end
function methods:AddLine(text) self.lines=self.lines or {};table.insert(self.lines,text) end
function methods:AddMessage() end
function CreateFrame(kind,name,parent,template)
    local f=NewObject(kind,name,parent)
    if template=='UIDropDownMenuTemplate' then
        for _,part in ipairs({'Left','Middle','Right'}) do f:CreateTexture(name..part..'Texture','ARTWORK') end
        f:CreateFontString(name..'Text','OVERLAY','GameFontNormal')
    end
    if template=='UIPanelCloseButton' then f.width=32; f.height=32 end
    if template=='OptionsSliderTemplate' then
        for _,suffix in ipairs({'Low','High','Text'}) do f:CreateFontString(name..suffix,'OVERLAY','GameFontNormal') end
    end
    return f
end
UIParent=CreateFrame('Frame','UIParent')
MPPublicSaved={PaladinSealDisplay=1}
pfUI_config={global={font_size=12},appearance={border={color='1,1,1,1'}}}
RAID_CLASS_COLORS={PALADIN={r=1,g=.5,b=.5}}
function UnitClass() return 'Paladin','PALADIN' end
function GetStringColor() return 1,1,1,1 end
function MouseIsOver() return false end
function SetAllPointsOffset(icon,parent,offset) icon.offset=offset end
function SetHighlight(button) button.highlight=true end
pfUI={font_default='Default',api={},addonskinner={}}
function pfUI.api.CreateBackdrop(frame,inset,legacy,alpha)
    frame.backdropApplied=true
    if not frame.backdrop then frame.backdrop=CreateFrame('Frame',nil,frame) end
end
function pfUI.api.StripTextures(frame)
    for _,r in ipairs(frame.regions) do if r.kind=='Texture' then r:SetTexture(nil) end end
end
function pfUI.api.SkinCloseButton(button) button.closeSkinned=true end
function pfUI.api.SkinCheckbox(button) button.checkboxSkinned=true end
function pfUI.api.SkinSlider(slider) slider.sliderSkinned=true end
function pfUI:GetEnvironment() return self.api end
function pfUI.addonskinner:RegisterSkin(name,callback) self.callback=callback end

GameTooltip=CreateFrame('GameTooltip','GameTooltip')
DEFAULT_CHAT_FRAME=CreateFrame('Frame','DEFAULT_CHAT_FRAME')
MPLanguage=setmetatable({},{__index=function(t,k) return k end})
MPTipsColor=''; MPPaladinCJConfig=1
function UIDropDownMenu_Initialize(f,callback) f.initialize=callback end
function UIDropDownMenu_SetWidth(w,f) f.width=w end
function UIDropDownMenu_SetText(s,f) f.dropdownText=s end
function UIDropDownMenu_SetSelectedID(f,id) f.selected=id end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton() end
function UIDropDownMenu_JustifyText() end
function invoke(o,kind,value)
    local oldThis,oldArg=this,arg1
    this=o;arg1=value;o.scripts[kind]();this=oldThis;arg1=oldArg
end
function Snapshot(t)
    if type(t)=='string' then return string.format('%q',t) end
    if type(t)~='table' then return tostring(t) end
    local parts={}
    for k,v in pairs(t) do table.insert(parts,'['..Snapshot(k)..']='..Snapshot(v)) end
    table.sort(parts);return '{'..table.concat(parts,',')..'}'
end
'''
FONT = ROOT / 'Tools/tests/wow112_fontstring_mock.lua'
ADDON = ROOT / 'Interface/AddOns/Cat'
FILES = ['UI/CatUI-Base.lua', 'UI/Settings-Common.lua', 'UI/CatUI-PaladinSeal.lua', 'UI/Settings-PaladinCJ.lua']

def setup(failed_font=False, saved=None):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB,lua.execute(FONT.read_text(encoding='utf-8')))
    if failed_font:
        lua.execute(r"failedFontPaths['Fonts\\FRIZQT__.TTF']=true")
    if saved:
        lua.execute(saved)
    for file in FILES:
        lua.execute((ADDON/file).read_text(encoding='utf-8-sig'))
    lua.execute("button=_G['CatUI-PaladinSealStrikeButton']; slider=_G['Settings-PaladinCJSlider_Strike']")
    return lua

if __name__ == '__main__':
    for file in FILES+['PaladinCJ.lua']:
        LuaRuntime().eval('function(s) local f,e=loadstring(s);assert(f,e) end')((ADDON/file).read_text(encoding='utf-8-sig'))
    for failed_font in [False,True]:
        lua=setup(failed_font)
        if failed_font:
            lua.execute(r"assert(failedFontPaths['Fonts\\FRIZQT__.TTF']);assert(button.text.font[1]=='Fonts\\FZXHLJW.TTF')")
        lua.execute("""
        assert(button.text.font and button.icon.color[1]==0.3)
        local naked=UIParent:CreateFontString(nil,'OVERLAY')
        assert(not pcall(function() naked:SetText('must fail') end))
        MPInitPaladinCJSettings(); MPCatPaladinSealInit()
        CatUISettingsPaladinCJ:Show()
        assert(_G['CatUI-PaladinSealConsecrationButton'].point[5]==-40)
        assert(button.point[5]==-90 and button.point[4]==285)
        assert(button.width==36 and button.height==36 and button.MPCatBorderlessIcon)
        check=slider.parent
        MPResetPaladinCJSettings(1); MPInitPaladinCJSettings()
        MPPaladinSealSaved.Justice=1; MPPaladinSealSaved.Seal=2
        MPCatPaladinSealInit()
        local tankBefore=Snapshot(MPPaladinTankSaved or {})
        local otherBefore=Snapshot(MPPaladinCJSaved[2])..Snapshot(MPPaladinCJSaved[3])
        local textures={}
        for _,mode in ipairs({4,5,0,1,2,3}) do
            invoke(button,'OnClick','LeftButton')
            local s=MPPaladinCJSaved[1]
            assert(s.Strike==(mode==0 and 0 or 1))
            if mode~=0 then assert(s.Strike_Value==mode) end
            assert((check:GetChecked()==1)==(mode~=0))
            assert(slider.value==s.Strike_Value)
            assert(button.icon.color[1]==(mode==0 and 0.3 or 1))
            assert(not textures[button.icon.texture]);textures[button.icon.texture]=true
            invoke(button,'OnEnter');assert(GameTooltip.text=='惩戒输出 - 配置 1')
            invoke(button,'OnLeave')
            for _,alpha in ipairs({0,30,70}) do
                _G['CatUI-PaladinSealTransparency']:SetValue(alpha)
                assert(button.icon.color[1]==(mode==0 and 0.3 or 1))
            end
        end
        for _,mode in ipairs({2,1,0,5,4,3}) do
            invoke(button,'OnClick','RightButton')
            assert(MPPaladinCJSaved[1].Strike==(mode==0 and 0 or 1))
            if mode~=0 then assert(MPPaladinCJSaved[1].Strike_Value==mode) end
        end
        assert(otherBefore==Snapshot(MPPaladinCJSaved[2])..Snapshot(MPPaladinCJSaved[3]))
        assert(tankBefore==Snapshot(MPPaladinTankSaved or {}))
        assert(MPPaladinSealSaved.Justice==1 and MPPaladinSealSaved.Seal==2)
        slider:SetValue(5); assert(string.find(button.text:GetText(),'三层'))
        check:SetChecked(false);invoke(check,'OnClick');assert(button.icon.color[1]==0.3)
        check:SetChecked(true);invoke(check,'OnClick');assert(button.icon.color[1]==1)
        CatUISettingsPaladinCJ:Show()
        invoke(_G['Settings-PaladinCJradio2'],'OnClick')
        invoke(button,'OnClick','LeftButton')
        assert(MPPaladinCJSaved[2].Strike_Value==4 and MPPaladinCJSaved[1].Strike_Value==5)
        CatUISettingsPaladinCJ:Hide()
        MPCatPaladinApplyControl('RET',3)
        invoke(button,'OnClick','RightButton')
        assert(MPPaladinCJSaved[3].Strike_Value==2 and MPPaladinCJSaved[2].Strike_Value==4)
        _G['CatUI-PaladinSealScale']:SetValue(110)
        assert(MPPaladinCJSaved[3].Strike_Value==2)
        """)
        lua.execute((ROOT/'Interface/AddOns/pfUI-addonskinner/skins/Cat.lua').read_text(encoding='utf-8'))
        lua.execute("pfUI.addonskinner.callback();assert(CatPaladinSeal.pfCatSkinned);assert(button.MPCatBorderlessIcon and button.icon.color[1]==1)")
        saved=lua.eval("'MPPaladinCJSaved='..Snapshot(MPPaladinCJSaved)..';MPPaladinSealSaved='..Snapshot(MPPaladinSealSaved)..';MPPaladinCJConfig=3'")
        restored=setup(failed_font,saved)
        restored.execute("MPCatPaladinSealInit();MPInitPaladinCJSettings();assert(MPPaladinCJSaved[3].Strike_Value==2);assert(string.find(button.text:GetText(),'均衡'))")
    lua=setup()
    lua.execute("MPPlayerClass='PALADIN';MPInitPaladinCJSettings();MPCatPaladinSealInit()")
    lua.execute((ADDON/'PaladinCJ.lua').read_text(encoding='utf-8-sig'))
    lua.execute("""
    casts={};clock=10
    function UnitExists() return true end
    function UnitMana() return 1000 end
    function UnitManaMax() return 1000 end
    function UnitHealth() return 10000 end
    function UnitHealthMax() return 10000 end
    function UnitCreatureType() return '亡灵' end
    function MPGetGCD() return 2 end
    function MPSpellReady(name) return name=='驱邪术' end
    function MPSpellReadyOffset() return true end
    function MPGetShape() return false end
    function MPAutoSwitchTarget() end
    function MPStartAttack() end
    function MPBuff() return false end
    function MPSeal() return true end
    function MPCatPaladinFinishReseal() return false end
    function MPGetTargetDistance() return true end
    function MPGetCrusaderStrike() return true end
    function GetTime() return clock end
    function CastSpellByName(name) table.insert(casts,name) end
    MPPaladinSealSaved.Justice=0;MPPaladinSealSaved.Seal=1
    MPPaladinSealSaved.Consecration=0
    local s=MPPaladinCJSaved[1]
    s.Pick=0;s.Power=0;s.Relic=0;s.Exorcism=0;s.Repentance=0;s.HammerWrath=0
    MPPaladinFrenzyLayer=3;MPPaladinFrenzyDuration=0
    local expected={'神圣打击','神圣打击','十字军打击','十字军打击','神圣打击'}
    for mode=1,5 do
        s.Strike=1;s.Strike_Value=mode;casts={};MPPaladinCJSpell()
        assert(#casts==1 and casts[1]==expected[mode])
        s.Strike=0;casts={};MPPaladinCJSpell();assert(#casts==0)
    end
    s.Strike=1;s.Strike_Value=5;clock=20
    casts={};MPPaladinCJSpell();assert(casts[1]=='十字军打击')
    s.Strike=0;MPPaladinSealSaved.Consecration=1;MPPaladinSealSaved.Consecration_Priority=2
    casts={};MPPaladinCJSpell();assert(#casts==1 and casts[1]=='奉献')
    MPPaladinSealSaved.Consecration_Priority=1
    casts={};MPPaladinCJSpell();assert(#casts==1 and casts[1]=='奉献')
    MPPaladinSealSaved.Consecration=0;s.Exorcism=1
    casts={};MPPaladinCJSpell();assert(#casts==1 and casts[1]=='驱邪术')
    """)
    print('PASS: actual Retribution macro honors enable/disable for all five modes; three-stack refresh; disabled strikes do not block medium/low Consecration or Exorcism')
    print('PASS: Lua syntax; six-mode cycles, icons, alignment, bidirectional settings, three-profile isolation, appearance, pfUI callback, reload, strict fonts and failed SetFont fallback')
