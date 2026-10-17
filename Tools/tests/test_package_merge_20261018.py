"""Check Oct 16 merge behavior without game actions; --addons accepts staging.

Production Lua fragments/modules are executed with strict FontString and 1.12
event conventions. These checks are not real-client acceptance.
"""
from pathlib import Path
import argparse
import json
import re
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns')
    addons=parser.parse_args().addons
    def read(path):return (addons/path).read_text(encoding='utf-8-sig')
    checks=[]

    # The actual nameplate target fallback, with the upstream spawn-age gate.
    src=read('pfUI/modules/nameplates.lua')
    start=src.index('    local alphaEligible =')
    end=src.index('    -- Target plate castbar',start)
    lua=LuaRuntime(unpack_returned_tuples=True)
    gate=lua.eval('function(now,spawn,hasTarget,alpha,guid,targetGuid) '+
        'local nameplate={spawnT=spawn,cachedGuid=guid};local state={hasTarget=hasTarget};'+
        'local frame={GetAlpha=function() return alpha end};'+src[start:end]+' return target end')
    for now,spawn,has_target,alpha,guid,target_guid,expected in [
        (100,100,True,1,'A','B',False),(100.3,100,True,1,'A','B',False),
        (101,100,True,1,'A','B',True),(101,100,True,.6,'A','B',False),
        (100,100,True,.6,'A','A',True),(101,100,False,1,'A','B',False),
    ]:
        assert bool(gate(now,spawn,has_target,alpha,guid,target_guid))==expected
    checks.append('6 real nameplate target/spawn-age cases; matched GUID remains immediate')

    # Oil recognition comes from the actual production pattern list.
    source=read('CatPotion/Core.lua')
    start=source.index('{ item = "神圣巫师之油", patterns = {')
    end=source.index('} },',start)+4
    patterns=lua.eval('function() return '+source[start:end].rstrip(',')+' end')().patterns
    matches=lua.eval('function(patterns,text) for _,p in ipairs(patterns) do if string.find(text,p) then return true end end return false end')
    for text,expected in [('神圣巫师之油',True),('+60 法术伤害vs亡灵（60分钟）',True),
        ('+60 法术伤害 vs 亡灵(30 分钟)',True),('+60 法术伤害vs亡灵',False),
        ('+30 法术伤害vs亡灵（60分钟）',False)]:
        assert matches(patterns,text)==expected
    checks.append('5 actual sacred-oil patterns: timed enchant accepted; permanent weapon property rejected')

    # The shared strict mock rejects SetText on an uninitialized FontString and
    # a failed SetFont leaves an existing template fallback intact.
    fonts=LuaRuntime(unpack_returned_tuples=True)
    fonts.execute('''
      methods={}
      function object(kind,name,parent) return setmetatable({kind=kind},{__index=methods}) end
      function methods:SetTextColor() end
      function methods:Show() self.shown=true end
      function methods:Hide() self.shown=false end
      function methods:GetStringWidth() return #(self.text or '')*5 end
      function methods:GetWidth() return 40 end
      function methods:SetAlpha(v) self.alpha=v end
    ''')
    fonts.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))(fonts.globals().methods,fonts.globals().object)
    fonts.execute('''
      assert(not pcall(function() object('FontString'):SetText('bad') end))
      failedFontPaths['Fonts\\\\FRIZQT__.TTF']=true
      GoubayuHeal={UI={}}
    ''')
    gui=read('GoubayuHeal/GoubayuHeal_UI.lua')
    prefix=gui[:gui.index('-- 设置悬停提示')]
    make=fonts.execute(prefix+'\nreturn GoubayuHeal_UI_MakeFontString')
    parent=fonts.globals().object('Frame',None,None)
    fs=make(parent,'OVERLAY',12,1,1,1)
    fs.SetText(fs,'');fs.Hide(fs);fs.SetText(fs,'closed');fs.Show(fs);fs.SetText(fs,'reused')
    assert fs.font[1].endswith('FZXHLJW.TTF'), 'failed SetFont must retain built-in template'
    checks.append('actual Goubayu font factory: creation/empty/hidden/reuse with configured-font failure')

    # Run our existing timer pipeline with the added brightness changes. The
    # function still uses our shared/GCD cooldown API, charge label and priority.
    fonts.execute('''
      profile={minimized=false};addon={}
      function addon.ToBoolean(v) return v and true or false end
      function addon.GetWeaponEnchantCharges() return poisonCharges end
      function addon.GetCooldownInfo() return cooldown or 0,cooldownKind,unavailable end
      function addon.SecondsToText(v) return tostring(v) end
      function RefreshRowBackground() end
      function GetItemEffectTime() return effectTime or 0 end
      function GetInventoryItemLink() return 'weapon' end
    ''')
    window=read('CatPotion/Window.lua')
    a=window.index('    local function SetTimerText(')
    b=window.index('    local function RefreshRow(',a)
    refresh=fonts.execute(window[a:b]+'\nreturn RefreshRowStatus')
    new_row=fonts.eval('''function(count)
      local row=object('Frame');row.itemData={category='药剂',item='Test'};row.itemCount=count
      row.statusText=row:CreateFontString(nil,'OVERLAY','GameFontNormal')
      row.countText=row:CreateFontString(nil,'OVERLAY','GameFontNormal')
      row.chargeText=row:CreateFontString(nil,'OVERLAY','GameFontNormal')
      row.icon=object('Texture');return row
    end''')
    for effect,cooldown,kind,count,expected in [(60,30,'shared',0,1),(0,5,'shared',0,1),
        (0,1,'gcd',0,1),(0,0,None,0,.62),(0,0,None,2,1)]:
        fonts.globals().effectTime=effect;fonts.globals().cooldown=cooldown;fonts.globals().cooldownKind=kind
        row=new_row(count);refresh(row);assert row.alpha==expected
        if effect:assert row.statusText.text=='60'
        if kind=='shared' and not effect:assert '共享' in row.statusText.text
    fonts.globals().profile.minimized=True
    row=new_row(0);fonts.globals().effectTime=60;refresh(row);assert row.statusText.font is not None
    checks.append('6 actual personal timer/brightness cases: active buff priority, shared/GCD, empty inventory and font fallback')

    # Load the complete pre-heal module. No actual casting API is called.
    prediction=LuaRuntime(unpack_returned_tuples=True)
    prediction.execute('''
      GoubayuHeal={Config={predict_enabled=0},current_action_profile='A'}
      frames={};now=100
      function GetTime() return now end
      function GetNampowerVersion() return 1 end
      function UnitExists(unit) return unit=='Ally' end
      function UnitIsDeadOrGhost() return false end
      function CreateFrame()
        local f={events={},scripts={}}
        function f:RegisterEvent(e) self.events[e]=true end
        function f:SetScript(e,fn) self.scripts[e]=fn end
        table.insert(frames,f);return f
      end
    ''')
    prediction.execute(read('GoubayuHeal/GoubayuHeal_Predict.lua'))
    prediction.execute('''
      local p=GoubayuHeal.Predict
      assert(p.frame and p.updateFrame and p.frame.events.AUTO_ATTACK_OTHER)
      local frame=p.frame;GoubayuHeal.Predict_Init();assert(p.frame==frame and #frames==2)
      casts=0;p.CastPick=function() casts=casts+1;return true end
      p.Cleanup=function() end
      p.pending={unit='Ally',profile='A',startAt=99,dueTime=101}
      p.OnUpdate(.1);assert(casts==0 and p.pending==nil)
      GoubayuHeal.Config.predict_enabled=1
      p.pending={unit='Ally',profile='B',startAt=99,dueTime=101}
      p.OnUpdate(.1);assert(casts==0 and p.pending==nil)
      p.pending={unit='Ally',profile='A',startAt=99,dueTime=101}
      p.OnUpdate(.1);assert(casts==1 and p.pending==nil)
      GoubayuHeal.IsMoving=function() return true end
      p.pending={unit='Ally',profile='A',startAt=99,dueTime=101}
      p.OnUpdate(.1);assert(casts==1 and p.pending==nil)
    ''')
    toc=read('GoubayuHeal/GoubayuHeal.toc')
    assert toc.count('GoubayuHeal_Predict.lua')==1
    assert toc.index('GoubayuHeal.lua')<toc.index('GoubayuHeal_Predict.lua')<toc.index('GoubayuHeal_UI.lua')
    checks.append('complete pre-heal initialization, idempotence, TOC ordering and queued-cast cancellation on disable/profile switch/movement')

    def function_block(path,name):
        text=read(path);a=text.index('function '+name+'(')
        match=re.search(r'\n(?:local )?function ',text[a+1:])
        return text[a:] if not match else text[a:a+1+match.start()]
    casting=LuaRuntime(unpack_returned_tuples=True)
    casting.execute('''
      BOOKTYPE_SPELL='spell';SpellStatusV2={};FiveSecLib={};CastLib={}
      function CheckNampower() return nampower end
      nampower=true;L={['(%d+) Mana']='(%d+) Mana'}
      spellcache={GetSpellData=function(self,slot) assert(slot==7);return 'BookSpell','Rank 1',1234,'BookSpell(Rank 1)' end}
      function GetSpellRec(id) assert(id==1234,'spellbook slot passed as spell ID');return {name='BookSpell',manaCost=50} end
      function CastOriginal(self,...) self.capture={...} end
      function SpellStatusV2:LevelDebug() end
      function GetSpellName(slot,book) assert(slot==7);return 'BookSpell' end
      AceLibrary=setmetatable({HasInstance=function() return true end},{__call=function() return spellcache end})
      FiveSecLib.hooks={CastSpell=function(slot,book) assert(slot==7);originalCalls=(originalCalls or 0)+1 end}
      FiveSecLibTip={ClearLines=function() end,SetSpell=function() end}
      FiveSecLibTipTextLeft2={GetText=function() return '40 Mana' end}
    ''')
    casting.execute(function_block('!Libs/SpellStatusV2-2.0/SpellStatusV2-2.0.lua','SpellStatusV2:CastSpell'))
    casting.execute(function_block('!Libs/FiveSecLib-1.0/FiveSecLib-1.0.lua','FiveSecLib:CastSpell'))
    casting.execute('''
      SpellStatusV2:CastSpell(7,'spell')
      assert(SpellStatusV2.capture[2]==7 and SpellStatusV2.capture[5]==1234)
      FiveSecLib:CastSpell(7,'spell');assert(FiveSecLib.Mana==50 and originalCalls==1)
      FiveSecLib.Spell=nil;GetSpellRec=nil
      SpellStatusV2:CastSpell(7,'spell');assert(SpellStatusV2.capture[5]==1234)
      FiveSecLib:CastSpell(7,'spell');assert(tonumber(FiveSecLib.Mana)==40 and originalCalls==2)
      nampower=false;SpellStatusV2:CastSpell(7,'spell');assert(SpellStatusV2.capture[5]==1234)
      SpellStatusV2:CastSpell(7,'pet');assert(SpellStatusV2.capture[2]==7 and SpellStatusV2.capture[5]==nil)
      CastLib.SpellCast={'BookSpell'};CastLib.SpellCast_backup={};arg1='BookSpell'
      function CastLib:IsEventScheduled() return false end
      function CastLib:TriggerEvent(name,value) self.last=value end
      CastLibTip={ClearLines=function() end};CastLibTipTextLeft2={GetText=function() return '40 Mana' end}
    ''')
    casting.execute(function_block('!Libs/CastLib-1.0/CastLib-1.0.lua','CastLib:SPELLCAST_START'))
    casting.execute('''
      nampower=true;CastLib:SPELLCAST_START();assert(CastLib.Mana==40)
      function GetCurrentCastingInfo() return 1234 end
      function GetSpellRec(id) assert(id==1234);return {manaCost=50} end
      CastLib:SPELLCAST_START();assert(CastLib.Mana==50)
      nampower=false;CastLib:SPELLCAST_START();assert(CastLib.Mana==40)
    ''')
    checks.append('actual shared casting functions: spellbook slot 7 resolves to spell ID 1234, original hook arguments retained, pet/no-DLL/missing-API fallbacks')

    # Our local configuration/entry behavior must still exist in the same source.
    assert 'local DISPLAY_VERSION = "2026-10-01"' in read('CatPotion/Settings.lua')
    for marker in ['SwapProfileWindowEntries','GetProfileWindowEntries']:
        assert marker in read('CatPotion/Core.lua')
    for marker in ['GetCooldownInfo(item.item)','ui.CancelRowDrag','ui.UpdateDragPreview','local showSettings = window:GetWidth() >= 114']:
        assert marker in window
    legacy=[x.strip() for x in read('!Libs/!Libs.toc').splitlines() if x.strip()=='SpellStatus-1.0\\SpellStatus-1.0.lua']
    assert len(legacy)==1
    print(json.dumps({'ok':True,'runtime':'Lua 5.1','checks':checks,
        'scope':'production Lua in controlled environments; no real client or network actions'},ensure_ascii=False,indent=2))


if __name__=='__main__':main()
