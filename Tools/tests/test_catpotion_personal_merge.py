"""Run preserved CatPotion regression suites with strict font preconditions.

Uses the existing personal test fixtures and real production files; supports a
staged --addons tree. No game or account settings are read or modified.
"""
from pathlib import Path
import argparse
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns')
    addons=parser.parse_args().addons.resolve()
    suites=['weapon-charges','weapon-macro','profile-layout','multiple-windows',
        'window-order','drag-preview','shortcut-picker','profile-menu-edges',
        'header-layout','engineering-wormholes','consumable-cooldowns']
    for suite in suites:
        lua=LuaRuntime(unpack_returned_tuples=True)
        def dofile(relative):
            path=addons/relative
            if not path.is_file():path=ROOT/'Interface/AddOns'/relative
            assert path.resolve().is_relative_to(addons) or path.resolve().is_relative_to(ROOT/'Interface/AddOns')
            source=path.read_text(encoding='utf-8-sig')
            if relative=='CatPotion/tests/weapon-charges.lua':
                replacements=[
                    ('local function NewFrame()', 'local function NewFrame(kind)'),
                    ('local frame = { scripts = {},', 'local frame = { kind = kind or "Frame", scripts = {},'),
                    ('function frame:CreateFontString() return NewFrame() end', '''function frame:CreateFontString(name,layer,template)
                      local fs=NewFrame('FontString')
                      if template then
                        assert(template=='GameFontNormal' or template=='GameFontNormalSmall' or template=='GameFontHighlight')
                        fs.font={'builtin',12}
                      end
                      return fs
                    end
                    function frame:SetFont(path,size,flags)
                      if rejectConfiguredFonts then return nil end
                      if type(path)~='string' or type(size)~='number' or size<=0 then return nil end
                      self.font={path,size,flags};return 1
                    end
                    function frame:SetFontObject(font)
                      assert(font and font.font,'invalid font object');self.font=font.font
                    end
                    function frame:GetFont()
                      local f=rawget(self,'font');if f then return unpack(f) end
                    end'''),
                    ('function frame:SetText(value) self.text = value end', '''function frame:SetText(value)
                      assert(self.kind~='FontString' or rawget(self,'font'),'SetText(): Font not set')
                      self.text=value
                    end'''),
                    ('local frame = NewFrame()\n    if name then', 'local frame = NewFrame(kind)\n    if name then'),
                    ('UIParent = NewFrame()', '''UIParent = NewFrame()
                    assert(not pcall(function() NewFrame('FontString'):SetText('bad') end))
                    rejectConfiguredFonts=true'''),
                ]
                for old,new in replacements:
                    assert source.count(old)==1,(suite,old)
                    source=source.replace(old,new,1)
            if relative=='S_ChatBar/ChatBar.lua':
                # This unchanged integration dependency uses an explicitly
                # available font in this scenario; keep SetText strict. Failed
                # font paths are exercised throughout the modified CatPotion UI.
                previous=lua.globals().rejectConfiguredFonts
                lua.globals().rejectConfiguredFonts=False
                lua.globals().STANDARD_TEXT_FONT=r'Fonts\FRIZQT__.TTF'
                try:return lua.execute(source)
                finally:lua.globals().rejectConfiguredFonts=previous
            return lua.execute(source)
        lua.globals().dofile=dofile
        dofile('CatPotion/tests/'+suite+'.lua')
        print('PASS suite:',suite)
    print('PASS: 11 personal CatPotion suites, strict FontString templates and failed SetFont paths; controlled UI only')


if __name__=='__main__':main()
