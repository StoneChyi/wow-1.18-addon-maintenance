from pathlib import Path
import hashlib,json

work=Path(__file__).parent
root=Path(r'E:\1.18\Interface\AddOns')
files=['Cat/CatEvent-Paladin.lua','Cat/PaladinTank.lua','Cat/PaladinCJ.lua']

shared='''
-- 审判不占公共冷却：同一次宏按键尝试补印，真有公共冷却时留给后续按键优先处理。
function MPCatPaladinCanJudge()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then return false end
    if not MPSpellReady("审判") or UnitMana("player") < 76 then return false end
    if type(IsSpellInRange) == "function" and IsSpellInRange("审判", "target") == 0 then return false end
    if MP_UnitXP and type(UnitXP) == "function" then
        local distance = UnitXP("distanceBetween", "player", "target")
        if distance and distance > 10 then return false end
    end
    return true
end

function MPCatPaladinCanPrepareSeal(name, threshold, mana)
    -- 法术本身的冷却包含真实公共冷却，不用可能被审判事件误计时的 MPGetGCD。
    if not MPSpellReady(name) then return false end
    local rank = mana < threshold and "等级 1" or nil
    local tooltipRank = rank
    if not tooltipRank and type(MPGetHighestRankOfSpell) == "function" then
        local highest = MPGetHighestRankOfSpell(name)
        if highest and highest > 0 then tooltipRank = "等级 " .. highest end
    end
    local key = name .. (tooltipRank or "最高等级")
    if not sealCostCache[key] then
        local cost
        if type(MPGetSpellTooltip) == "function" then
            local text = MPGetSpellTooltip(name, tooltipRank)
            if type(text) == "string" then
                local _, _, value = string.find(text, "(%d+)%s*法力")
                if not value then _, _, value = string.find(text, "(%d+)%s*[Mm]ana") end
                cost = tonumber(value)
            end
        end
        sealCostCache[key] = cost or (threshold > 0 and threshold or 170)
    end
    return mana >= sealCostCache[key]
end

function MPCatPaladinFinishReseal(owner, choice, prepare)
    if not pendingReseal then return false end
    if pendingReseal.owner ~= owner or pendingReseal.choice ~= choice or GetTime() - pendingReseal.time > 4 then
        pendingReseal = nil
        return false
    end
    if prepare(UnitMana("player")) then
        pendingReseal = nil
        return true
    end
    return false
end

function MPCatPaladinJudgeAndReseal(owner, choice, prepare)
    if not MPCatPaladinCanJudge() then return false end
    local remaining = math.max(0, UnitMana("player") - 76)
    pendingReseal = nil
    if choice and choice >= 1 and choice <= 6 then
        pendingReseal = { owner = owner, choice = choice, time = GetTime() }
    end
    -- 直接按顺序发出请求；圣印也不进 Nampower 队列，避免覆盖前一条审判。
    MPCastWithoutNampower("审判")
    if pendingReseal and prepare(remaining) then pendingReseal = nil end
    return true
end
'''

def seal_helpers(tank):
    choice='tankState.recovering and 1 or MPPaladinSealSaved.Seal' if tank else 'MPPaladinSealSaved.Seal'
    legacy='' if tank else '''
    if choice == 0 then
        local saved = MPPaladinCJSaved[MPPaladinCJConfig]
        if saved.Seal_Value == 2 then return 4 end
        if saved.Seal_Value == 3 then return 5 end
        if MPPaladinSealCommand == 0 or MPPaladinSealJustice ~= 0 then return 4 end
        return 5
    end'''
    owner='"TANK:" .. MPPaladinTankConfig' if tank else '"RET:" .. MPPaladinCJConfig'
    return '''local function SelectedSealChoice()
    local choice = '''+choice+legacy+'''
    return choice
end

local function PrepareSelectedSeal(manaBudget)
    local choice = SelectedSealChoice()
    local names = { [1] = "智慧圣印", [2] = "光明圣印", [3] = "十字军圣印", [4] = "正义圣印", [5] = "命令圣印", [6] = "公正圣印" }
    local name = names[choice]
    if not name then return false end
    Mana = math.min(UnitMana("player"), manaBudget)
    local threshold = (choice == 2 or choice == 5) and 178 or choice == 3 and 136 or choice == 6 and 0 or 170
    if not MPCatPaladinCanPrepareSeal(name, threshold, Mana) then return false end
    if choice == 1 then SealWisdom()
    elseif choice == 2 then SealRight()
    elseif choice == 3 then SealCrusader()
    elseif choice == 4 then SealJustice()
    elseif choice == 5 then SealCommand()
    else MPCastWithoutNampower(name) end
    return true
end

local function JudgeAndRestoreSeal()
    return MPCatPaladinJudgeAndReseal('''+owner+''', SelectedSealChoice(), PrepareSelectedSeal)
end

'''

manifest={}
for name in files:
    source=root/name
    original=work/'original'/name
    if not original.exists():
        original.parent.mkdir(parents=True,exist_ok=True)
        original.write_bytes(source.read_bytes())
    before=original.read_bytes()
    text=before.decode('utf-8').replace('\r\n','\n')
    def replace(old,new):
        global text
        assert text.count(old)==1,(name,old[:90],text.count(old))
        text=text.replace(old,new)
    if name.endswith('CatEvent-Paladin.lua'):
        replace('local function OnEvent()', '''local pendingReseal
local sealCostCache = {}
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")

local function OnEvent()
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_DEAD" or event == "PLAYER_ENTERING_WORLD" then pendingReseal = nil end
    if event == "SPELLS_CHANGED" or event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then sealCostCache = {} end''')
        text+='\n'+shared
    elif name.endswith('PaladinTank.lua'):
        # Use the same non-queued seal casts as RET when chaining after judgement.
        start=text.index('-- 正义圣印\nlocal function SealJustice()')
        end=text.index('-- 神圣打击\nlocal function HolyStrike()',start)
        text=text[:start]+text[start:end].replace('CastSpellByName(', 'MPCastWithoutNampower(')+text[end:]
        replace('return MPGetGCD() > 1.4 and MPSpellReady(name) and Mana >= PreparingSealCost(name, threshold)', 'return MPSpellReady(name) and Mana >= PreparingSealCost(name, threshold)')
        start=text.index('local function CanJudge()')
        end=text.index('\nlocal function CanCompleteOpening()',start)
        text=text[:start]+'''local function CanJudge()
    return MPCatPaladinCanJudge()
end
'''+text[end:]
        replace(' and not MPSeal("正义圣印") then\n            tankState.openingDone', ' then\n            tankState.openingDone')
        replace('-- 无 SuperWoW 时可由审判冷却及圣印消耗交叉确认；公共冷却不足以确认。', '-- 无 SuperWoW 时由审判自身冷却确认；补印已在同键完成时也能确认起手。')
        replace('local function TryOpeningJudgement()',seal_helpers(True)+'local function TryOpeningJudgement()')
        assert text.count('        CastSpellByName("审判")\n        return true')==2
        text=text.replace('        CastSpellByName("审判")\n        return true', '        return JudgeAndRestoreSeal()')
        replace('    CastSpellByName("审判")\n    return true','    return JudgeAndRestoreSeal()')
        replace('local function CastPanelJudgement()', '''local function PanelJudgementNeeded()
    local names = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = names[MPPaladinSealSaved.Justice]
    return prefix and HostileTarget() and UnitHealth("target") > MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP
        and not MPBuff(prefix .. "审判", "target")
end

local function CastPanelJudgement()''')
        replace('if THP <= MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP or not CanJudge() then return false end', 'if not PanelJudgementNeeded() or not CanJudge() then return false end')
        start=text.index('    if not MPSeal(name) then',text.index('local function CastSelectedSeal()'))
        end=text.index('    if not tankState.recovering',start)
        text=text[:start]+'''    if not MPSeal(name) then return PrepareSelectedSeal(UnitMana("player")) end
'''+text[end:]
        replace('if not tankState.recovering and (choice == 4 or choice == 5) and CanJudge() then', 'if not tankState.recovering and not PanelJudgementNeeded() and (choice == 4 or choice == 5) and CanJudge() then')
        replace('    if TryOpeningJudgement() then return end', '''    if TryOpeningJudgement() then return end

    -- 起手完成后，待补的辅助审判先于主攻技能和普通伤害审判。
    if CastPanelJudgement() then return end''')
        replace('        if CastPanelJudgement() then return end\n', '')
        marker='    -- 战斗前准备面板选择的正义圣印；回蓝切换在耗蓝输出前执行。'
        replace(marker,'''    -- 真正被公共冷却推迟的补印，下一次可施法按键先补印，避免再次被打击抢走。
    if MPCatPaladinFinishReseal("TANK:" .. MPPaladinTankConfig, SelectedSealChoice(), PrepareSelectedSeal) then return end

'''+marker)
    else:
        replace('local JudgmentDelay = 0','')
        panel_judgement='''local function PanelJudgementNeeded()
    local names = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = names[MPPaladinSealSaved.Justice]
    return prefix and UnitHealth("target") > MPPaladinCJSaved[MPPaladinCJConfig].JudgementOutHP
        and not MPBuff(prefix .. "审判", "target")
end

local function CastPanelJudgement()
    local choice = MPPaladinSealSaved.Justice
    if not PanelJudgementNeeded() or not MPCatPaladinCanJudge() then return false end
    local prefixes = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = prefixes[choice]
    if not prefix or MPBuff(prefix .. "审判", "target") then return false end
    local name = prefix .. "圣印"
    if not MPSeal(name) then
        Mana = UnitMana("player")
        local threshold = choice == 3 and 136 or choice == 4 and 0 or choice == 2 and 178 or 170
        if not MPCatPaladinCanPrepareSeal(name, threshold, Mana) then return false end
        if choice == 1 then SealWisdom()
        elseif choice == 2 then SealRight()
        elseif choice == 3 then SealCrusader()
        else MPCastWithoutNampower(name) end
        return true
    end
    return JudgeAndRestoreSeal()
end

'''
        replace('function MPPaladinCJSpell()',seal_helpers(False)+panel_judgement+'function MPPaladinCJSpell()')
        marker='\tif MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Priority==3 then'
        replace(marker,'''    -- 审判后尚未补印时，先完成补印，再执行主攻技能。
    if MPCatPaladinFinishReseal("RET:" .. MPPaladinCJConfig, SelectedSealChoice(), PrepareSelectedSeal) then return end

'''+marker)
        # A utility seal is prepared only when judgement can actually be used.
        start=text.index('\t\t-- 通过小窗参数 - 审判')
        end=text.index('\t\t-- 通过小窗参数 - 圣印',start)
        text=text[:start]+'''        -- 辅助审判冷却时继续正常输出，不反复切换圣印或空等。

'''+text[end:]
        assert text.count('if SP and Mana>=76 and GCD>1.4 then')==3
        text=text.replace('if SP and Mana>=76 and GCD>1.4 then','if not PanelJudgementNeeded() and MPCatPaladinCanJudge() then')
        assert text.count('then CastSpellByName("审判") return end')==3
        text=text.replace('then CastSpellByName("审判") return end','then JudgeAndRestoreSeal() return end')
        replace('\t-- 主攻技能策略', '''    -- 辅助审判就绪时先准备/释放，不能让正义或命令消耗它的冷却。
    if CastPanelJudgement() then return end

\t-- 主攻技能策略''')
    after=text.replace('\n','\r\n').encode('utf-8')
    patched=work/'patched'/name
    patched.parent.mkdir(parents=True,exist_ok=True); patched.write_bytes(after)
    manifest[name]={'before':hashlib.sha256(before).hexdigest(),'after':hashlib.sha256(after).hexdigest()}
(work/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Prepared three Lua files; original backups and hashes preserved.')
