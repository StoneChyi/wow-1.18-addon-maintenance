"""Execute complete ATSW recipe-update functions without loading or editing addons.

Synthetic recipe/API data and the real current XML row template provide the
boundary. The update loop and highlight/scroll functions are loaded verbatim.
Expected upstream regressions are evidence assertions, not deployment approval.
"""
import argparse
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument('--current', type=Path, default=ROOT / 'Interface/AddOns/AdvancedTradeSkillWindow2/AdvancedTradeSkillWindow2.lua')
parser.add_argument('--upstream', type=Path, help='New-package Lua file; no files are deployed or copied')
ARGS, REMAINING = parser.parse_known_args()
XML = ROOT / 'Interface/AddOns/AdvancedTradeSkillWindow2/AdvancedTradeSkillWindow2.xml'

MOCK = r'''
objects={};methods={};recipeData={};selected='Recipe';scroll=0;attributes=false;beast=false
measureReady=true;measureCalls=0;measured={};counts={};scrollUpdates={}
RecipesDataIsComplete=0;RecipesDataTries=0;profession='Alchemy'
ATSW_RowSig={};ATSW_RowWidthCache={};ATSW_RowWidthCount={}
ATSW_RECIPES_DISPLAYED=23;ATSW_TRADESKILL_HEIGHT=18
ATSW_POSSIBLE_BANK=1;ATSW_POSSIBLE_ALTS=2;ATSW_POSSIBLE_MERCHANT=3
ATSW_Options={ConsiderBank=true,ConsiderAlts=false,ConsiderMerchants=true,Unified=true}
ATSWTypeColor={header={R=1,G=1,B=1},optimal={R=1,G=.5,B=0},used={R=.5,G=.5,B=.5},trivial={R=.2,G=.8,B=.2}}
Color={GREY='|cff808080'};TRAINER_LIST_TP='TP %d';format=string.format
function object(kind,name,parent,template)
 local o=setmetatable({kind=kind,name=name,parent=parent,template=template,shown=false,
  width=0,height=18,points={},scripts={},calls={}}, {__index=methods})
 objects[#objects+1]=o;if name then _G[name]=o end;return o
end
function methods:GetName() return self.name end
function methods:GetObjectType() return self.kind end
function methods:SetWidth(v) assert(type(v)=='number' and v==v);self.width=v end
function methods:GetWidth() return self.width end
function methods:SetHeight(v) self.height=v end
function methods:GetHeight() return self.height end
function methods:SetPoint(a,b,c,x,y)
 if type(b)=='string' then b=_G[b] or b end
 local p={a,b,c,x or 0,y or 0}
 for i,old in ipairs(self.points) do if old[1]==a then self.points[i]=p;return end end
 self.points[#self.points+1]=p
end
function methods:GetPoint(i) if self.points[i or 1] then return unpack(self.points[i or 1],1,5) end end
function methods:Show() self.shown=true;self.calls.show=(self.calls.show or 0)+1 end
function methods:Hide() self.shown=false;self.calls.hide=(self.calls.hide or 0)+1 end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:SetTexture(value) self.texture=value end
function methods:GetTexture() return self.texture end
function methods:SetTexCoord(...) self.texcoord={...} end
function methods:SetVertexColor(...) self.vertex={...} end
function methods:SetDesaturated(value) self.desaturated=value end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:SetTextColor(...) self.textcolor={...} end
function methods:GetTextColor() return unpack(self.textcolor or {1,1,1}) end
function methods:LockHighlight() self.locked=true end
function methods:UnlockHighlight() self.locked=false end
function methods:GetText() return self.label and self.label.text or self.text end
function methods:GetFont() local font=self.label and self.label.font or self.font;return unpack(font) end
function methods:GetTextWidth()
 measureCalls=measureCalls+1
 local value=self.label.text
 local chars=0
 for char in string.gmatch(value,'[%z\1-\127\194-\244][\128-\191]*') do chars=chars+1 end
 local font=self.label.font
 local factor=font[1]=='Fallback.ttf' and .7 or .5
 local width=measureReady and chars*font[2]*factor or 0
 measured[self.name]=width
 return width
end
function SetVisible(o,v) if v then o:Show() else o:Hide() end end
function Profession() return profession end
function ScrollOffset() return scroll end
function RecipesSortedSize() return #recipeData end
function RecipeSorted(i) return recipeData[i] end
function RecipeSelected() return selected end
function IsBeastTraining() return beast end
function ATSW_ShowAttributes() return attributes end
function IsExpanded() return true end
function GetCategoryTexture() return 'Expanded' end
function GetLinkColorRGB(link) if link then return .2,.4,1 end end
function SubNameToString(name) return name and name~='' and ' ('..name..')' or '' end
function GetAttributes(recipe) return recipe.Attributes or recipe.Name end
function ConvertCooldown(value) return value and 'Cooldown '..value or nil end
function ATSW_HowManyItemsArePossibleToCreate(name,...)
 counts[#counts+1]={'inventory',name,...};return materials or 0
end
function ATSW_HowManyItemsArePossibleToCreateWithConsidering(name)
 counts[#counts+1]={'total',name};return totalMaterials or materials or 0
end
function FauxScrollFrame_Update(frame,total,visible,height,...)
 scrollUpdates[#scrollUpdates+1]={total,visible,height}
end
'''


def block(source, start, end):
    begin = source.index(start)
    return source[begin:source.index(end, begin)]


class Runtime:
    def __init__(self, path, width=145):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        install = self.lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
        install(self.lua.globals().methods, self.lua.globals().object)
        self.lua.execute('''
        local strictFont,strictText=methods.SetFont,methods.SetText
        function methods:SetFont(path,size,flags)
          return strictFont(self.label or self,path,size,flags)
        end
        function methods:SetText(value) return strictText(self.label or self,value) end
        ATSWFrame=object('Frame','ATSWFrame')
        ATSWListScrollFrame=object('Frame','ATSWListScrollFrame')
        ATSWHighlight=object('Frame','ATSWHighlight')
        ATSWHighlightTexture=object('Texture','ATSWHighlightTexture',ATSWHighlight)
        ''')
        template = ET.parse(XML).getroot().find("Button[@name='ATSWRecipeButtonTemplate']")
        assert template is not None and template.get('hidden') == 'true'
        text_template = template.find('ButtonText').get('inherits')
        assert text_template == template.find('NormalFont').get('inherits')
        self.lua.globals().ATSWListScrollFrame.width = width
        create = self.lua.globals().object
        for row in range(1, 24):
            name = f'ATSWRecipe{row}'
            button = create('Button', name, self.lua.globals().ATSWFrame, 'ATSWRecipeButtonTemplate')
            button.label = button.CreateFontString(button, name + 'Text', 'BACKGROUND', text_template)
            button.XOffset = 22
            button.SetPoint(button, 'TOP', self.lua.globals().ATSWFrame, 'TOP', 0, -77 - (row-1)*18)
            button.SetPoint(button, 'LEFT', self.lua.globals().ATSWFrame, 'LEFT', 22, 0)
            for node in template.findall('./Layers/Layer/FontString'):
                fs = button.CreateFontString(button, node.get('name').replace('$parent', name), 'BORDER', node.get('inherits'))
                fs.shown = node.get('hidden') != 'true'
            for suffix in ('Texture', 'QualityTexture', 'Highlight'):
                texture = create('Texture', name + suffix, button)
                node = (template.find('HighlightTexture') if suffix == 'Highlight'
                        else template.find(f"./Layers/Layer/Texture[@name='$parent{suffix}']"))
                size = node.find('Size')
                texture.width = float(size.get('x'))
                texture.height = float(size.get('y'))
                anchor = node.find('./Anchors/Anchor')
                offset = anchor.find('Offset')
                texture.SetPoint(texture, anchor.get('point'), button, anchor.get('point'), float(offset.get('x')), float(offset.get('y')))
        source = path.read_text(encoding='utf-8-sig')
        # Complete original functions; only external state/UI boundaries above
        # are synthetic. In particular no width-cache code is reimplemented.
        self.lua.execute(block(source, 'local function RemoveColorTags(', '\nfunction ATSW_HideRecipes()'))
        self.lua.execute(block(source, 'function ATSW_HideRecipes()', '\nfunction ATSW_UpdateTasks()'))
        self.lua.execute(block(source, 'function ATSW_SetHighlight(', '\nfunction ATSW_UpdateCreateButton()'))
        self.lua.execute(block(source, 'function ATSW_UpdateListScroll()', '\nfunction ATSW_UpdateTaskListScroll()'))
        self.execute("recipeData={{Name=string.rep('A',20),Type='optimal',Texture='Icon',Link='Item:1',Position=1}}")

    def execute(self, source):
        return self.lua.execute(source)

    def update(self, source=''):
        if source:
            self.execute(source)
        self.lua.globals().ATSW_UpdateRecipes()

    def eval(self, source):
        return self.lua.eval(source)

    def state(self, row=1):
        button = self.lua.globals()[f'ATSWRecipe{row}']
        font = button.label.font
        return {'name': button.Name, 'type': button.Type, 'link': button.Link,
                'position': button.Position, 'possible': button.Possible, 'text': button.Text,
                'shown': button.shown, 'width': button.width, 'text_width': button.label.width,
                'subtext': self.lua.globals()[f'ATSWRecipe{row}SubText'].text,
                'font': (font[1], font[2]),
                'clicks': tuple(button.clicks.values()), 'locked': button.locked}


class RecipeWidthCache(unittest.TestCase):
    def upstream_pair(self, width=145):
        if not ARGS.upstream:
            self.skipTest('Pass --upstream to execute actual new-package regression evidence')
        return Runtime(ARGS.current, width), Runtime(ARGS.upstream, width)

    def test_complete_current_function_template_layout_and_counts(self):
        current = Runtime(ARGS.current)
        current.update('''
        materials=3;totalMaterials=8;ATSW_Options.Unified=false;selected='Recipe   (Rank 2)'
        recipeData={{Name='Category',Type='header'},
          {Name='Recipe',SubName='Rank 2',Type='optimal',Texture='Icon',Link='Item:1',Position=8,Cooldown=15},
          {Name='Learned',Type='used',Texture='Icon2',Link='Item:2',Position=9,TrainingCost=5}}
        ''')
        current.execute('''
        assert(ATSWRecipe1:IsShown() and ATSWRecipe2:IsShown() and not ATSWRecipe4:IsShown())
        assert(ATSWRecipe1Texture:GetTexture()=='Expanded')
        assert(ATSWRecipe2.Name=='Recipe   (Rank 2)' and ATSWRecipe2.Position==8)
        assert(ATSWRecipe2SubText:GetText()=='Cooldown 15')
        assert(string.find(ATSWRecipe2.Text,'3/8',1,true))
        assert(ATSWRecipe3SubText:GetText()=='|cff808080TP 5|r')
        assert(#counts==4 and #scrollUpdates==1)
        assert(ATSWRecipe2.locked and ATSWHighlight:IsShown())
        assert(#ATSWRecipe1.clicks==1 and #ATSWRecipe2.clicks==2)
        for i=1,23 do assert(not _G['ATSWRecipe'..i..'SkillUpText']:IsShown()) end
        ''')
        if ARGS.upstream:
            upstream = Runtime(ARGS.upstream)
            upstream.update('''materials=3;totalMaterials=8;ATSW_Options.Unified=false;selected='Recipe   (Rank 2)';
            recipeData={{Name='Category',Type='header'},
              {Name='Recipe',SubName='Rank 2',Type='optimal',Texture='Icon',Link='Item:1',Position=8,Cooldown=15},
              {Name='Learned',Type='used',Texture='Icon2',Link='Item:2',Position=9,TrainingCost=5}}''')
            for row in (1, 2, 3):
                self.assertEqual(current.state(row), upstream.state(row))
            self.assertEqual(current.eval('#counts'), upstream.eval('#counts'))

    def test_expected_upstream_same_plain_font_10_to_12_collision(self):
        current, upstream = self.upstream_pair()
        for runtime in (current, upstream):
            runtime.update('attributes=true')
            runtime.update('attributes=false')
        self.assertEqual(current.state()['font'][1:], (12,))
        self.assertEqual(current.state()['text_width'], 100)
        self.assertEqual(upstream.state()['text_width'], 0)
        self.assertEqual(current.eval('measureCalls'), 2)
        self.assertEqual(upstream.eval('measureCalls'), 1)
        print('EXPECTED upstream 10->12 collision: measured 100 then stale 100; current measures 120; clipping current=100/upstream=0')

    def test_expected_upstream_actual_font_fallback_changes_width(self):
        current, upstream = self.upstream_pair(width=180)
        for runtime in (current, upstream):
            runtime.update()
            runtime.execute("ATSWRecipe1.label:SetFont('Fallback.ttf',14);failedFontPaths['Fonts\\\\FRIZQT__.ttf']=true;ATSW_HideRecipes()")
            runtime.update()
        self.assertEqual(current.state()['font'], ('Fallback.ttf', 14))
        self.assertEqual(upstream.state()['font'], ('Fallback.ttf', 14))
        self.assertAlmostEqual(current.eval("measured.ATSWRecipe1"), 196)
        self.assertEqual(current.state()['text_width'], 135)
        self.assertEqual(upstream.state()['text_width'], 0)
        print('EXPECTED upstream loaded-font collision: synthetic fallback width196; stale cache120; clipping current=135/upstream=0')

    def test_expected_upstream_zero_width_is_reused_after_font_ready(self):
        current, upstream = self.upstream_pair()
        for runtime in (current, upstream):
            runtime.update('measureReady=false')
            runtime.update('measureReady=true;ATSW_HideRecipes()')
        self.assertEqual(current.state()['text_width'], 100)
        self.assertEqual(upstream.state()['text_width'], 0)
        self.assertEqual(upstream.eval("ATSW_RowWidthCache[1][string.rep('A',20)]"), 0)
        self.assertEqual(upstream.eval('measureCalls'), 1)
        print('EXPECTED upstream not-ready collision: cached0 remains0; current remeasures120')

    def test_upstream_hide_keeps_width_cache_and_bound_is_24(self):
        _, upstream = self.upstream_pair()
        upstream.update()
        upstream.execute('beforeCache=ATSW_RowWidthCache[1];ATSW_HideRecipes();assert(ATSW_RowWidthCache[1]==beforeCache)')
        for number in range(70):
            upstream.update(f"recipeData[1].Name='Recipe {number}'")
            self.assertLessEqual(upstream.eval('ATSW_RowWidthCount[1]'), 24)
        upstream.execute('''
        local n=0;for _ in pairs(ATSW_RowWidthCache[1]) do n=n+1 end
        assert(n==ATSW_RowWidthCount[1] and n<=24)
        ''')
        print('UPSTREAM cache survives HideRecipes; observed entry limit24 (70 row-reuse texts)')


if __name__ == '__main__':
    print('Read-only function execution; synthetic metrics. Expected upstream defects are NOT deployment approval.', flush=True)
    unittest.main(argv=[sys.argv[0]] + REMAINING, verbosity=2)
