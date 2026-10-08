from pathlib import Path
import sys,ast,itertools,json

work=Path(__file__).parent
root=Path(r'E:\1.18\Interface\AddOns')
previous=Path(r'C:\Users\Administrator\Documents\Codex\2026-10-05\nik\work')
sys.path.insert(0,str(previous/'cat-ret-tests/deps'))
from lupa.lua51 import LuaRuntime

def read(name):
    path=work/'patched'/name
    return (path if path.exists() else root/name).read_text(encoding='utf-8')

def assigned_string(path,name):
    tree=ast.parse(path.read_text(encoding='utf-8'))
    node=next(n.value for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id==name for t in n.targets))
    return eval(compile(ast.Expression(node),str(path),'eval'),{'work':previous/'cat-tank-rotation'})

mock=assigned_string(previous/'cat-paladin-unified/verify.py','mock')
world=assigned_string(previous/'cat-tank-rotation/verify.py','world')
library=read('Cat/CatLib.lua')
cooldowns=library[library.index('function MPSpellReady(name)'):library.index('-- 获取技能是否存在',library.index('function MPSpellReady(name)'))]
noqueue=library[library.index('function MPCastWithoutNampower('):library.index('-- 施法的替代宏，针对Nampower的施法队列',library.index('function MPCastWithoutNampower('))]

engine='''
realGCD=2; displayedMana=nil; delayedSealRemoval=false; commands={}; cvars={NP_QueueCastTimeSpells='1',NP_QueueInstantSpells='1'}
local oldObject=NewObject
function NewObject(...)
    local object=oldObject(unpack(arg))
    function object:GetBackdropColor() return 0.1,0.1,0.2,0.75 end
    function object:SetHighlightTexture(path) self.highlightTexture=self.highlightTexture or self:CreateTexture(nil,'HIGHLIGHT'); self.highlightTexture:SetTexture(path) end
    function object:GetHighlightTexture() return self.highlightTexture end
    function object:SetPushedTexture(path) self.pushedTexture=self.pushedTexture or self:CreateTexture(nil,'ARTWORK'); self.pushedTexture:SetTexture(path) end
    function object:GetPushedTexture() return self.pushedTexture end
    return object
end
function UnitMana() return displayedMana or mana end
local spellNames={}; local spellIDs={}
function MPGetSpellID(name)
    if ready[name]==nil then return 0 end
    if not spellIDs[name] then local id=table.getn(spellNames)+1; spellNames[id]=name; spellIDs[name]=id end
    return spellIDs[name]
end
function GetSpellCooldown(id)
    local name=spellNames[id]
    if not name then return 0,0 end
    if name=='审判' and judgeCooldown>0 then return now,judgeCooldown end
    if not ready[name] then return now,8 end
    if name~='审判' and realGCD<1.5 then return now-realGCD,1.5 end
    return 0,0
end
function GetCVar(name) return cvars[name] end
function SetCVar(name,value) cvars[name]=tostring(value) end
function MPGetShape() return false end
function MPEquipItemByName() end
function UnitAttackSpeed() return 2 end
function MPGetMainHandLeft() return 0 end
function MPMsg() end
function CastSpellByName(spell)
    table.insert(casts,spell)
    table.insert(commands,{spell=spell,queue=cvars.NP_QueueInstantSpells})
    if failed[spell] then return end
    local name=string.gsub(spell,'%(.+%)','')
    if name~='审判' and realGCD<1.5 then return end
    local cost=string.find(name,'圣印') and SealCost(name,string.find(spell,'等级 1') and '等级 1' or nil) or name=='审判' and 76 or 120
    if mana<cost then return end
    table.insert(successes,spell)
    mana=mana-cost
    if string.find(name,'圣印') then ClearSeals(); buffs[name]=true; realGCD=0; gcd=0
    elseif name=='审判' then
        for _,v in ipairs({'智慧','光明','十字军','公正'}) do if buffs[v..'圣印'] then targetBuffs[v..'审判']=true end end
        if not delayedSealRemoval then ClearSeals() end
        ready[name]=false; judgeCooldown=8
        gcd=0 -- The addon clock can restart after SPELLCAST_STOP even for judgement.
        Feedback(name)
    elseif name=='神圣打击' or name=='十字军打击' then ready['十字军打击']=false; realGCD=0; gcd=0
    else ready[name]=false; realGCD=0; gcd=0 end
end
function NextPress()
    realGCD=2; gcd=2; now=now+2
    if mode=='TANK' then Press() else PressRet() end
end
function PressRet() casts={}; successes={}; MPPaladinCJSpell() end
function UnitXP() return distanceNumber or 5 end
local createFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
    local frame=createFrame(kind,name,parent,template)
    if template=='UIDropDownMenuTemplate' then
        for _,part in ipairs({'Left','Middle','Right'}) do frame:CreateTexture(name..part..'Texture','ARTWORK') end
        frame:CreateFontString(name..'Text','OVERLAY')
    end
    return frame
end
function UIDropDownMenu_Initialize() end
function UIDropDownMenu_SetSelectedID() end
function UIDropDownMenu_AddButton() end
'''

def boot(mode='TANK',opening_done=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(mock+world+engine)
    lua.execute(read('Cat/CatEvent-Paladin.lua'))
    lua.execute('ActualMPSeal=MPSeal; function MPSeal(name) return buffs[name]==true end')
    lua.execute(cooldowns+noqueue)
    lua.execute(read('Cat/PaladinCJ.lua'))
    lua.execute(read('Cat/PaladinTank.lua'))
    lua.execute(read('Cat/UI/CatUI-PaladinSeal.lua'))
    lua.execute(read('Cat/UI/CatUI-Base.lua'))
    lua.execute(read('Cat/UI/Settings-Common.lua'))
    lua.execute(read('Cat/UI/Settings-PaladinTank.lua'))
    lua.execute(read('Cat/UI/Settings-PaladinCJ.lua'))
    g=lua.globals(); g.MPInitPaladinTankSettings(); g.MPInitPaladinCJSettings(); g.MPCatPaladinSealInit()
    g.mode=mode
    lua.execute("MPPaladinSealSaved.Seal=4; MPPaladinSealSaved.Justice=-1; MPPaladinSealSaved.Consecration=0; MPPaladinTankSaved[1].RacialTraits=0; MPPaladinCJSaved[1].RacialTraits=0")
    if opening_done:
        lua.execute("buffs['正义圣印']=true; Press(); realGCD=2; gcd=2; now=110; mana=2000; ready['审判']=true; judgeCooldown=0; buffs={['正义之怒']=true}; casts={}; successes={}; commands={}")
    return lua

def names(g): return list(g.casts.values())
def press(g): g.Press() if g.mode=='TANK' else g.PressRet()
def active(g,seal): return g.buffs[seal] is True

manifest=json.loads((work/'manifest.json').read_text(encoding='utf-8'))
compiler=LuaRuntime().eval('function(s) local f,e=loadstring(s); assert(f,e) end')
for name in manifest: compiler(read(name))
cases=0

# Actual full macros: damage judgement plus replacement seal in one key, even with delayed aura removal.
for mode,choice,delay,np in itertools.product(['TANK','RET'],[4,5],[False,True],[False,True]):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Seal=choice; g.delayedSealRemoval=delay; g.MP_Nampower=np
    seal='正义圣印' if choice==4 else '命令圣印'; g.buffs[seal]=True
    press(g)
    assert names(g)==['审判',seal],(mode,choice,delay,np,names(g))
    assert active(g,seal) and g.realGCD==0 and g.MPPaladinSealSaved.Seal==choice
    if np:
        assert all(command.queue=='0' for command in g.commands.values())
        assert g.cvars.NP_QueueInstantSpells=='1'
    cases+=1

# Each panel judgement restores each selected output seal; None leaves no automatic replacement.
choices={1:'智慧圣印',2:'光明圣印',3:'十字军圣印',4:'正义圣印',5:'命令圣印',6:'公正圣印',-1:None}
prefixes={1:'智慧',2:'光明',3:'十字军',4:'公正'}
for mode,judgement,choice in itertools.product(['TANK','RET'],prefixes,choices):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Seal=choice; g.MPPaladinSealSaved.Justice=judgement
    g.buffs[prefixes[judgement]+'圣印']=True
    press(g)
    expected=['审判']+([choices[choice]] if choices[choice] else [])
    assert names(g)==expected,(mode,judgement,choice,names(g))
    assert g.MPPaladinSealSaved.Seal==choice and g.MPPaladinSealSaved.Justice==judgement
    cases+=1

# Real GCD remains enforced: judge is allowed during it, seal completes before a ready strike on the next key.
for mode,choice in itertools.product(['TANK','RET'],[4,5]):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Seal=choice; seal=choices[choice]; g.buffs[seal]=True
    g.realGCD=.4; g.gcd=.4
    press(g); assert names(g)==['审判'] and not active(g,seal),(mode,names(g))
    g.ready['十字军打击']=True; g.NextPress()
    assert names(g)==[seal] and active(g,seal),(mode,names(g))
    cases+=1

# An earlier main strike genuinely starts GCD; queued replacement gets first priority after that GCD.
for mode in ['TANK','RET']:
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.buffs['正义圣印']=True; g.ready['十字军打击']=True
    press(g)
    assert names(g)[-1]=='审判' and len(names(g))==2,(mode,names(g))
    g.ready['十字军打击']=True; g.NextPress()
    assert names(g)==['正义圣印'],(mode,names(g))
    cases+=1

# Stale addon GCD timer does not suppress reseal when the spell cooldown is actually ready.
for mode in ['TANK','RET']:
    lua=boot(mode,opening_done=True); g=lua.globals(); g.buffs['正义圣印']=True
    g.gcd=0; g.realGCD=2; press(g)
    assert names(g)==['审判','正义圣印'],(mode,names(g))
    cases+=1

# Conservative post-judgement mana budget, correct rank choice and insufficient mana.
for mode,value,display_stale in itertools.product(['TANK','RET'],[75,76,95,96,169,170,245,246,300],[False,True]):
    lua=boot(mode,opening_done=True); g=lua.globals(); g.mana=value; g.buffs['正义圣印']=True
    if display_stale: g.displayedMana=value
    press(g)
    expected=[] if value<76 else ['审判']
    remaining=value-76
    if remaining>=20:
        expected+=['正义圣印(等级 1)' if remaining<170 else '正义圣印']
    assert names(g)==expected,(mode,value,display_stale,names(g),expected)
    cases+=1

# No repeated utility seal preparation while judgement is on cooldown.
for mode,choice in itertools.product(['TANK','RET'],prefixes):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Justice=choice; g.ready['审判']=False; g.judgeCooldown=8
    press(g)
    assert names(g)==['正义圣印'],(mode,choice,names(g))
    cases+=1

# Reported combat sequence: first Righteousness, then reserve the refreshed judgement for Wisdom.
for feedback in [False,True]:
    lua=boot('TANK'); g=lua.globals(); g.combatFeedback=feedback
    g.MPPaladinSealSaved.Justice=1; g.buffs['正义圣印']=True
    g.Press(); assert names(g)==['审判','正义圣印']
    g.ready['十字军打击']=True; g.NextPress()
    assert names(g)[0] in ['神圣打击','十字军打击']
    g.realGCD=2; g.gcd=2; g.now+=8; g.ready['审判']=True; g.judgeCooldown=0
    g.ready['十字军打击']=True; g.Press()
    assert names(g)==['智慧圣印'],(feedback,names(g))
    # Wisdom is already applied; judgement can fire while its seal GCD is still active.
    g.now+=.2; g.realGCD=.2; g.gcd=.2; g.Press()
    assert names(g)==['审判'] and g.targetBuffs['智慧审判'] is True
    g.ready['十字军打击']=True; g.NextPress()
    assert names(g)==['正义圣印'] and g.MPPaladinSealSaved.Justice==1
    cases+=1

# If preparation is blocked, neither existing Righteousness nor Command may steal Wisdom's cooldown.
for mode,choice,blocked in itertools.product(['TANK','RET'],[4,5],['GCD','spell']):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Justice=1; g.MPPaladinSealSaved.Seal=choice; g.buffs[choices[choice]]=True
    if blocked=='GCD': g.realGCD=.5; g.gcd=.5
    else: g.ready['智慧圣印']=False
    press(g); assert '审判' not in names(g),(mode,choice,blocked,names(g))
    assert g.ready['审判'] and g.judgeCooldown==0
    cases+=1

# A completed utility judgement or the configured health cutoff still permits ordinary damage judgements.
for mode,condition in itertools.product(['TANK','RET'],['present','health']):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.MPPaladinSealSaved.Justice=1; g.buffs['正义圣印']=True
    if condition=='present': g.targetBuffs['智慧审判']=True
    else: g.hp=4000
    press(g); assert names(g)==['审判','正义圣印'],(mode,condition,names(g))
    cases+=1

# Pending seal requests follow manual panel choice, macro switches and never live past four seconds.
for mode,steering in itertools.product(['TANK','RET'],['manual','switch','timeout']):
    lua=boot(mode,opening_done=True); g=lua.globals()
    g.buffs['正义圣印']=True; g.realGCD=.4; g.gcd=.4; press(g)
    assert names(g)==['审判']
    if steering=='manual': g.MPPaladinSealSaved.Seal=5
    elif steering=='switch': g.mode='RET' if mode=='TANK' else 'TANK'
    else: g.now+=5
    g.ready['十字军打击']=True; g.NextPress()
    assert names(g)[0] in ['神圣打击','十字军打击'],(mode,steering,names(g))
    if steering=='manual': assert g.MPPaladinSealSaved.Seal==5
    cases+=1

# Opening confirmation without cast events must work even when same-key replacement restored the seal.
lua=boot(); g=lua.globals(); g.combatFeedback=False; g.buffs['正义圣印']=True
g.Press(); assert names(g)==['审判','正义圣印']
g.ready['神圣之盾']=True; g.NextPress(); assert names(g)[0]=='神圣之盾'
cases+=1

# Tank low-mana mode restores Wisdom, preserving shared selection and saved profiles.
lua=boot('TANK',opening_done=True); g=lua.globals()
g.MPPaladinSealSaved.Justice=2; g.mana=500; g.MPPaladinTankSaved[1].AutoWisdom=1
g.buffs['光明圣印']=True; g.buffs['智慧圣印']=True
g.Press(); assert names(g)==['审判','智慧圣印'] and g.MPCatPaladinTankRecoveryActive
assert g.MPPaladinSealSaved.Seal==4
cases+=1

# Failed opening does not mark the opener complete; true distance, health and target gates remain.
lua=boot(); g=lua.globals(); g.failed['审判']=True; g.buffs['正义圣印']=True
g.Press(); g.failed['审判']=False; g.NextPress(); assert names(g)==['审判','正义圣印']
cases+=1
for mode,guard in itertools.product(['TANK','RET'],['dead','enemy','range','UnitXP','health']):
    lua=boot(mode,opening_done=True); g=lua.globals(); g.buffs['智慧圣印']=True; g.MPPaladinSealSaved.Justice=1
    g.MPPaladinSealSaved.Seal=-1
    if guard=='dead': g.dead=True
    elif guard=='enemy': g.enemy=False
    elif guard=='range': g.range=0
    elif guard=='UnitXP': g.MP_UnitXP=True; g.distanceNumber=12
    else: g.hp=4000
    press(g)
    assert '审判' not in names(g),(mode,guard,names(g))
    cases+=1

# Existing high-consecration priority and the fifth RET frenzy strategy remain intact.
lua=boot(); g=lua.globals(); g.MPPaladinSealSaved.Consecration=1; g.MPPaladinSealSaved.ConsecrationPriority=3
g.buffs['正义圣印']=True; g.ready['奉献']=True; g.Press()
assert names(g)[0].startswith('奉献')
cases+=1
for layer,age,expected in [(0,0,'十字军打击'),(2,5,'十字军打击'),(3,5,'神圣打击'),(3,21,'十字军打击')]:
    lua=boot('RET',opening_done=True); g=lua.globals()
    g.MPPaladinCJSaved[1].Strike_Value=5; g.ready['十字军打击']=True; g.ready['审判']=False
    g.MPPaladinFrenzyLayer=layer; g.MPPaladinFrenzyDuration=g.now-age; g.MPPaladinSealSaved.Seal=-1
    press(g); assert names(g)==[expected],(layer,age,names(g))
    cases+=1

print(f'PASS: Lua 5.1; {cases} full tank/RET macro cases, real spell cooldowns, same-key reseal, mana/ranks, Nampower, utility choices, opener, recovery and preserved priorities.')
