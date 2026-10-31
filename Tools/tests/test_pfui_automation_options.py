"""Native pfUI option adapter: real CreateConfig and real complex module options.
Offline WoW 1.12 UI simulation; this is not a live-game acceptance test.
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
MOCK=r'''
local install = ...
local methods={}
created=0
function obj(kind,name,parent)
 created=created+1
 return setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=true,width=440,height=22},{__index=methods})
end
function fire(o,event) local old=this;this=o;if o.scripts[event] then o.scripts[event]() end;this=old end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:GetParent() return self.parent end
function methods:SetParent(p) self.parent=p end
function methods:SetWidth(v) self.width=v end
function methods:GetWidth() return self.width end
function methods:SetHeight(v) self.height=v end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:GetLeft() return 0 end
function methods:GetRight() return 440 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:EnableMouse(v) self.mouse=v end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:IsEnabled() return self.enabled~=false end
function methods:UpdateScrollChildRect() self.range=math.max(0,parent:GetHeight()-100) end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return self.range or 0 end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:UpdateScrollState() end
function methods:ClearFocus() fire(self,'OnEditFocusLost') end
function methods:GetText() return self.text or '' end
function methods:GetStringHeight() return math.max(12,math.ceil(#(self.text or '')/math.max(1,(self.width or 400)/7))*12) end
function methods:GetStringWidth() return #(self.text or '')*7 end
function methods:GetFontString() return self.fontstring end
function methods:CreateTexture() return obj('Texture',nil,self) end
function methods:SetTexture(...) self.texture={...} end
function methods:Insert(text) self:SetText(self:GetText()..text) end
for _,name in ipairs({'SetAlpha','SetAllPoints','SetTextColor','SetJustifyH','SetJustifyV','SetTextInsets','SetBackdrop','SetBackdropBorderColor','SetNormalTexture','SetPushedTexture','SetHighlightTexture','SetAutoFocus','SetFrameStrata'}) do methods[name]=function() end end
install(methods,obj)
local fontCreate=methods.CreateFontString
function methods:CreateFontString(name,layer,template)
 return fontCreate(self,name,layer,template=='GameFontWhite' and 'GameFontNormal' or template)
end
function methods:SetFont() return nil end
function CreateFrame(kind,name,parent,template)
 local f=obj(kind,name,parent)
 if template=='UIPanelButtonTemplate' then f.fontstring=f:CreateFontString(nil,'OVERLAY','GameFontNormal') end
 return f
end
local baseText=methods.SetText
function methods:SetText(v)
 baseText(self,v)
 if self.fontstring then self.fontstring:SetText(v) end
end
function CreateBackdrop(frame) frame.backdrop=obj('Frame',nil,frame) end
function SkinButton() end
function EntryUpdate() end
function CreateDropDownButton(name,parent)
 local f=obj('Button',name,parent);f.text=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
 f.menuframe=obj('Frame',nil,f);f.button=obj('Button',nil,f)
 function f:HideMenu() self.menuframe:Hide() end
 function f:SetMenu(fn) self.menufunc=fn;self.menu=fn() end
 function f:UpdateMenu() self.menu=self.menufunc();self.text:SetText(self.menu[self.id] and self.menu[self.id].text or '') end
 function f:SetSelection(id) if id and self.menu[id] then self.id=id;self.text:SetText(self.menu[id].text) end end
 return f
end
function strsplit(sep,text)
 local out={};for part in string.gfind(text,'[^'..sep..']+') do table.insert(out,part) end;return unpack(out)
end
function strfind(...) return string.find(unpack(arg)) end
C={gui={reloadmarker='0'},global={font_size=12}}
pfUI_config=C
pfUI={gui=obj('Frame'),font_default='missing-font.ttf'}
function pfUI:RegisterModule(name,version,fn) fn() end
T=setmetatable({},{__index=function(_,k)return k end})
GameTooltip=obj('Frame');GameTooltip.SetOwner=function()end;GameTooltip.AddLine=function()end
ColorPickerFrame=obj('Frame')
function ColorPickerFrame:SetColorRGB(r,g,b) self.rgb={r,g,b} end
function ColorPickerFrame:GetColorRGB() return unpack(self.rgb) end
OpacitySliderFrame={GetValue=function()return opacity or 0 end}
function ShowUIPanel(f) f:Show() end
parent=obj('Frame',nil,obj('Frame'));parent.parent=parent:GetParent()
function rows() return parent.automationOptionsState.visible end
function rowNamed(name)
 for _,r in ipairs(rows()) do if r.option.name==name then return r end end
 error('missing row '..name)
end
function click(r) fire(r.input or r.button or r.color,'OnClick') end
function edit(r,text,event) r.input:SetText(text);fire(r.input,event or 'OnEnterPressed') end
function choose(r,value)
 r.input:UpdateMenu();for _,e in ipairs(r.input.menu) do if e.text==value then e.func();return end end
 error('missing choice '..value)
end
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)
 local m={name=name};self.modules[name]=m
 function m:RegisterOptions(opts) self._options=opts end
 function m:print() end
 return m
end
function Automaton:AcquireDBNamespace(name) self.dbs[name]=self.dbs[name] or {char={},profile={}};return self.dbs[name] end
function Automaton:RegisterDefaults(name,scope,defaults)
 local db=self:AcquireDBNamespace(name);for k,v in pairs(defaults) do if db[scope][k]==nil then db[scope][k]=v end end
end
function Automaton:SetDisabledAsDefault() end
function UnitName() return 'TestPlayer' end
function UnitClass() return 'Paladin','PALADIN' end
function AceLibrary()
 return {new=function()
  return setmetatable({RegisterTranslations=function(self,locale,fn) fn() end},{__index=function(_,key)return key end})
 end}
end
'''

def main():
 lua=LuaRuntime(unpack_returned_tuples=True)
 font=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
 lua.execute(MOCK,font)
 source=(ROOT/'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8-sig')
 start=source.index('    function CreateConfig(')
 end=source.index('    local TabFrameOnMouseDown',start)
 lua.execute('local searchDB={}\n'+source[start:end]+'\npfUI.gui.CreateConfig=CreateConfig; nativeSearchDB=searchDB')
 lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf-8-sig'))
 lua.execute(r'''
 R=pfUI.automationOptions
 values={enabled=false,message='before',number=10,color={.2,.3,.4,.5},pick='key:one'}
 sets=0;notices=0
 module={_options={
 enabled={type='toggle',name='Toggle',order=1,get=function()return values.enabled end,set=function(v)values.enabled=v;sets=sets+1 end},
 text={type='text',name='Text',order=2,get=function()return values.message end,set=function(v)values.message=v;sets=sets+1 end,onCreateEdit=function(e)captured=e end},
 number={type='range',name='Range',order=3,min=5,max=20,step=5,get=function()return values.number end,set=function(v)values.number=v;sets=sets+1 end},
 pick={type='text',name='Dropdown',order=4,passValue='pick',validate={['key:one']='One: exact',['key:two']='Two'},get=function(k)return values[k] end,set=function(k,v)values[k]=v end},
 color={type='color',name='Color',hasAlpha=true,order=5,get=function()return unpack(values.color)end,set=function(r,g,b,a)values.color={r,g,b,a}end},
 group={type='group',name='Group',order=6,args={blocked={type='toggle',name='Blocked',get=function()return false end,set=function()error('disabled callback ran')end}},disabled=true},
 hidden={type='toggle',name='Hidden',hidden=true},
 action={type='execute',name='Named action',buttonText='Do',order=7,func=function() values.action=values.message end},
 desc={type='description',name='Description wraps and uses pfUI typography',order=8}
 }}
 function redraw() notices=notices+1;R:Render(parent,module,redraw) end
 R:Render(parent,module,redraw)
 assert(captured==rowNamed('Text').input)
 rowNamed('Toggle').input:SetChecked(1);click(rowNamed('Toggle'));assert(values.enabled)
 fire(rowNamed('Toggle').input,'OnShow');assert(rowNamed('Toggle').input:GetChecked(),'native OnShow lost checked state')
 assert(not rowNamed('Blocked').input.mouse and not rowNamed('Blocked').input:IsEnabled());click(rowNamed('Blocked'))
 for _,r in ipairs(rows())do assert(r.option.name~='Hidden')end
 local r=rowNamed('Text');r.input:SetText('typing');assert(values.message=='before')
 fire(r.input,'OnEscapePressed');assert(values.message=='before' and r.input:GetText()=='before')
 local before=sets;edit(r,'confirmed');assert(values.message=='confirmed' and sets==before+1)
 edit(rowNamed('Text'),'blur','OnEditFocusLost');assert(values.message=='blur')
 edit(rowNamed('Range'),'23');assert(values.number==20)
 edit(rowNamed('Range'),'7');assert(values.number==5)
 before=sets;edit(rowNamed('Range'),'not-number');assert(sets==before and values.number==5)
 choose(rowNamed('Dropdown'),'Two');assert(values.pick=='key:two')
 choose(rowNamed('Dropdown'),'One: exact');assert(values.pick=='key:one')
 click(rowNamed('Color'));ColorPickerFrame:SetColorRGB(.8,.7,.6);opacity=.7;ColorPickerFrame.func()
 assert(values.color[1]==.8 and math.abs(values.color[4]-.3)<.00001)
 ColorPickerFrame.cancelFunc();assert(values.color[1]==.2 and values.color[4]==.5)
 R:Suspend(parent);assert(not ColorPickerFrame:IsShown(),"color popup leaked across pages");R:Render(parent,module,redraw)
 rowNamed('Text').input:SetText('before button');click(rowNamed('Named action'));assert(values.action=='before button')
 rowNamed('Text').input:SetText('before dropdown');choose(rowNamed('Dropdown'),'Two');assert(values.message=='before dropdown')
 rowNamed('Text').input:SetText('before toggle');rowNamed('Toggle').input:SetChecked(nil);click(rowNamed('Toggle'));assert(values.message=='before toggle')
 values.pick='unlisted';R:Render(parent,module,redraw);assert(rowNamed('Dropdown').input.text:GetText()=='unlisted' and rowNamed('Dropdown').input.id==nil)
 values.message='external';R:Render(parent,module,redraw);assert(values.message=='external' and rowNamed('Text').input:GetText()=='external','untouched stale control overwrote external edit')
 rowNamed('Text').input:SetText('draft on refresh');R:Render(parent,module,redraw);assert(values.message=='draft on refresh')
 rowNamed('Text').input:SetText('draft on hide');R:Suspend(parent);assert(values.message=='draft on hide');R:Render(parent,module,redraw)
 local dropdown=rowNamed('Dropdown');dropdown.input.menuframe:Show();fire(dropdown,'OnHide');assert(not dropdown.input.menuframe:IsShown())
 parent.parent.scroll=99999;R:Render(parent,module,redraw);assert(parent.parent.scroll==parent.parent.range,'scroll not clamped')
 local count=created
 for i=1,100 do R:Render(parent,module,redraw) end
 assert(created==count,'repeated rendering leaked frames')
 assert(next(nativeSearchDB)==nil,'dynamic controls leaked stale global search entries')
 R:Clear(parent);for _,bucket in pairs(parent.automationOptionsState.pool)do for _,r in ipairs(bucket)do assert(not r:IsShown())end end
 print('PASS: native controls, callbacks, commit/cancel, range, color, disabled/hidden, frame/search reuse')
 ''')
 for name in ('AutoNeed','AutoShout'):
  lua.execute((ROOT/f'Interface/AddOns/Automatonex/Modules/{name}.lua').read_text(encoding='utf-8-sig'))
 lua.execute(r'''
 local m=Automaton.modules.AutoNeed;m:OnInitialize()
 R:Render(parent,m)
 local dropdowns=0
 for _,r in ipairs(rows()) do
  if r.widget=='dropdown' then
   local opt=r.option;choose(r,'放弃');assert((opt.passValue and opt.get(opt.passValue) or opt.get())=='放弃');dropdowns=dropdowns+1
  end
 end
 assert(dropdowns==31,'AutoNeed selectors missing: '..dropdowns)
 print('PASS: real AutoNeed '..dropdowns..' selectors (including passValue)')
 local shout=Automaton.modules.AutoShout;shout:OnInitialize()
 shout.RestartTimer=function()end
 R:Render(parent,shout,function()R:Render(parent,shout)end)
 local message=rowNamed('Message');assert(shout._messageEdit==message.input)
 message.input:SetText('Hello ')
 click(rowNamed('物品1'))
 assert(shout.db.profile.messages.TestPlayer=='Hello {item1}','group insert lost captured edit')
 choose(rowNamed('Channel'),'Guild');assert(shout.db.profile.channel=='guild')
 edit(rowNamed('Interval'),'77');assert(shout.db.profile.intervals.TestPlayer==75)
 local count=created
 for i=1,50 do R:Render(parent,m);R:Render(parent,shout) end
 assert(created==count,'switching modules leaked frames')
 print('PASS: real AutoShout captured edit, group item insertion, mapped channel, interval; 100 module switches')
 ''')
if __name__=='__main__': main()
