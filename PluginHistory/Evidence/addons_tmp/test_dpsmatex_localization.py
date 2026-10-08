from pathlib import Path
import re,sys,copy,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).parent/'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

root=Path(r'E:/1.18/Interface/AddOns/DPSMateX')
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
objects={};locale="zhCN";UNIT_NAME_FONT="Fonts\\\\FZLBJW.TTF"
local F={}
function F:GetName() return self.name end
function F:GetParent() return self.parent end
function F:SetText(v) self.text=v end
function F:GetText() return self.text end
function F:SetPoint() end
function F:SetFont() end
function F:SetHeight() end
function F:SetWidth() end
function F:SetBackdropColor() end
function object(name,parent)
 local f=objects[name] or setmetatable({name=name,parent=parent},{__index=F});objects[name]=f;_G[name]=f;return f
end
function getglobal(name) assert(objects[name],"Missing real UI object: "..name);return objects[name] end
for i=1,32 do object("DropDownList1Button"..i.."NormalText") end
function GetLocale() return locale end
function AceLibrary() return {Close=function() end,GetOpenedParent=function() return UIParent end} end
function UIDropDownMenu_SetSelectedValue(f,v) f.selectedValue=v end
function UIDropDownMenu_SetText(label,f) f.selectedText=label end
buttons={};function UIDropDownMenu_AddButton(b) table.insert(buttons,b) end
function GetChannelName() return nil end
function UIDropDownMenu_Initialize() end
function CloseDropDownMenus() end
function Logout() end
DPSMateX={Options={},L={},Settings={windows={{name="Test",options={{},{}}}},tooltipanchor=1},Parser={TargetParty={}},CacheUser={}}
function DPSMateX:TContains(t,v) for _,x in pairs(t) do if x==v then return true end end;return false end
function DPSMateX:GetMode() return {},1,{} end
function DPSMateX:GetSettingValues() return {} end
''')
ui=list(root.rglob('*.xml'))
trees=[ET.parse(p).getroot() for p in ui]
templates={e.get('name'):e for tree in trees for e in tree if e.get('virtual')=='true'}
def register(e,parent='',seen=frozenset()):
    name=e.get('name','').replace('$parent',parent) or parent
    if e.get('name'):
        f=lua.globals().object(name,lua.globals().objects[parent] if parent else None)
        # Standard WoW templates generate these font strings and dropdown controls.
        if 'Button' in e.tag or e.tag.endswith('CheckButton') or e.tag.endswith('Slider'):
            lua.globals().object(name+'Text',f)
        if 'UIDropDownMenuTemplate' in e.get('inherits',''):
            lua.globals().object(name+'Text',f)
            lua.globals().object(name+'Button',f)
    for inherit in e.get('inherits','').split(','):
        inherit=inherit.strip()
        if inherit in templates and inherit not in seen:
            template=copy.deepcopy(templates[inherit]);template.attrib.pop("name",None);register(template,name,seen|{inherit})
    for child in e:register(child,name,seen)
lua.globals().object('UIParent',None)
for tree in trees:
    for e in tree:
        if e.get('virtual')!='true':register(e)
def adapt(s):
    return re.sub(r'for ([\w, ]+) in ([\w.\[\]"\(\)]+) do',lambda m:'for '+m[1]+' in pairs('+m[2]+') do' if not re.search(r'\b(?:pairs|ipairs|next)\(',m[2]) else m[0],s)
lua.execute((root/'enUS/enUS.lua').read_text(encoding='utf-8-sig'))
lua.execute(adapt((root/'DPSMateX_Options.lua').read_text(encoding='utf-8-sig')))
lua.execute((root/'DPSMateX_!zhCN/zhCN.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local D=DPSMateX
assert(DPSMateX_Details_DiagramLegend_Procs_Text==nil)
assert(DPSMateX_Details_LogDetails_Hit:GetText()=="命中")
assert(DPSMateX_Details_LogDetails_Crit:GetText()=="暴击")
assert(DPSMateX_Details_LogDetails_Average:GetText()=="平均")
assert(D.Options.Options[4].args.compare.name==D.L.comparewith)
assert(D.Options.Options[5].args.people.name==D.L.certainnames)
assert(D.Options:ChoiceLabel("Raid")=="团队")
assert(D.Options:ChoiceLabel("PetOwner")=="PetOwner")
local dropdown=DPSMateX_ConfigMenu_Tab_Bars_BarFontFlag
D.Options:SetDropdownValue(dropdown,"Outline")
assert(dropdown.selectedValue=="Outline" and dropdown.selectedText=="描边")
buttons={};D.Options:BarFontFlagsDropDown()
for _,b in ipairs(buttons) do assert(b.text~="None" and b.text~=b.value) end
buttons={};D.Options:ChannelDropDown()
for _,b in ipairs(buttons) do if b.value=="Raid" then assert(b.text=="团队") end end
UIParent.Key=1;UIParent.user="PlayerName"
local obj={user="PlayerName",GetParent=function() return UIParent end}
UIParent.parent=UIParent;sort=table.sort
object("UIParent_Head_Font"):SetText("造成伤害 [当前]")
D.Options:InializePlayerDewDrop(obj)
assert(D.Options.Options[4].args.player.name=="PlayerName")
assert(D.Options.Options[4].args.details.name==D.L.opendetails)
assert(D.Options.Options[4].args.report.args.a1.name=="团队")
locale="enUS";assert(D.Options:ChoiceLabel("Raid")=="Raid")
''')
print('PASS: full Chinese locale load, detail labels, settings choices, internal values and player menus')
