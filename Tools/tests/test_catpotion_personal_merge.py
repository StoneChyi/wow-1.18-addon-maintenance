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
        'header-layout','header-lock','engineering-wormholes','consumable-cooldowns','instant-ground','auto-use','auto-use-settings']
    for suite in suites:
        lua=LuaRuntime(unpack_returned_tuples=True)
        def dofile(relative):
            if relative=='../../Tools/tests/wow112_fontstring_mock.lua':
                install=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
                return lua.eval(r"""function(install)
                  return function(methods,newObject)
                    install(methods,newObject)
                    assert(not pcall(function() newObject('FontString'):SetText('uninitialized') end))
                    failedFontPaths['Fonts\\FRIZQT__.TTF']=true
                    assert(not newObject('FontString'):SetFont('Fonts\\FRIZQT__.TTF',12))
                  end
                end""")(install)
            path=addons/relative
            if not path.is_file():path=ROOT/'Interface/AddOns'/relative
            assert path.resolve().is_relative_to(addons) or path.resolve().is_relative_to(ROOT/'Interface/AddOns')
            source=path.read_text(encoding='utf-8-sig')
            if relative=='S_ChatBar/ChatBar.lua':
                # Unchanged integration dependency uses its available global font.
                # Keep SetText strict; all modified CatPotion paths reject FRIZ.
                previous=lua.globals().failedFontPaths[r'Fonts\FRIZQT__.TTF']
                lua.globals().failedFontPaths[r'Fonts\FRIZQT__.TTF']=False
                lua.globals().STANDARD_TEXT_FONT=r'Fonts\FRIZQT__.TTF'
                try:return lua.execute(source)
                finally:lua.globals().failedFontPaths[r'Fonts\FRIZQT__.TTF']=previous
            return lua.execute(source)
        lua.globals().dofile=dofile
        dofile('CatPotion/tests/'+suite+'.lua')
        print('PASS suite:',suite)
    print(f'PASS: {len(suites)} personal CatPotion suites, strict FontString templates and failed SetFont paths; controlled UI only')


if __name__=='__main__':main()
